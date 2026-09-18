"""
services/trust/state_machine.py — ED-04 §11 trust_state transition edges.

This module is the ONLY place allowed to advance resources.trust_state or
sources.verification_status. All other code calls advance_trust_state().

MUST NOT: allow direct jumps from discovered/ai_assessed to verified or
authoritative_official — every intermediate requirement must be satisfied
in order (Doc 9 §18, ED-04 §11 hard rule).

MUST NOT: modify this file as a side effect of unrelated work — any change
to transition edge logic is a flagged, escalated change per the kickoff
hard constraints.
"""
from dataclasses import dataclass
from typing import Optional
import uuid
from datetime import datetime

from sqlalchemy import select, update
from sqlalchemy.ext.asyncio import AsyncSession

from core.enums import TrustState
from core.models import Resource, ReviewQueue


# ---------------------------------------------------------------------------
# Allowed transitions (ED-04 §11)
# From → {To: requirement_description}
# ---------------------------------------------------------------------------
ALLOWED_TRANSITIONS: dict[str, dict[str, str]] = {
    TrustState.DISCOVERED.value: {
        TrustState.IDENTIFIED.value:
            "ED-01 pipeline stage 2 (Identify) completes",
    },
    TrustState.IDENTIFIED.value: {
        TrustState.INDEXED.value:
            "Intermediate index step",
        TrustState.AI_ASSESSED.value:
            "ED-01 pipeline stage 7 default outcome — must not jump to verified",
    },
    TrustState.INDEXED.value: {
        TrustState.AI_ASSESSED.value:
            "AI assessment completes at stage 7",
    },
    TrustState.AI_ASSESSED.value: {
        TrustState.EVIDENCE_SUPPORTED.value:
            "At least one evidence row with claim_status='platform_verified' exists",
        # Regression or flag paths
        TrustState.UNDER_REVIEW.value:
            "A review_queue row opened against this resource",
        TrustState.DISPUTED.value:
            "ED-04 §5 contradiction rule fires (two evidence_supported/verified sources disagree)",
        TrustState.OUTDATED.value:
            "freshness_policies cadence elapsed without re-verification",
        TrustState.RESTRICTED.value:
            "access_status change — never a trust judgment (ED-01 §2.2)",
    },
    TrustState.EVIDENCE_SUPPORTED.value: {
        TrustState.VERIFIED.value:
            "A review_queue row resolved with resolution='approved'",
        TrustState.UNDER_REVIEW.value:
            "A review_queue row opened",
        TrustState.DISPUTED.value:
            "Contradiction rule fires",
        TrustState.OUTDATED.value:
            "Freshness cadence elapsed",
        TrustState.RESTRICTED.value:
            "Access status change",
    },
    TrustState.VERIFIED.value: {
        TrustState.AUTHORITATIVE_OFFICIAL.value:
            "source.verification_status = authoritative_official (ED-04 §11)",
        TrustState.UNDER_REVIEW.value:
            "A review_queue row opened",
        TrustState.DISPUTED.value:
            "Contradiction rule fires",
        TrustState.OUTDATED.value:
            "Freshness cadence elapsed",
        TrustState.RESTRICTED.value:
            "Access status change",
    },
    # Terminal / regression states can open a review
    TrustState.DISPUTED.value: {
        TrustState.UNDER_REVIEW.value: "Review opened to resolve dispute",
    },
    TrustState.OUTDATED.value: {
        TrustState.VERIFIED.value:
            "Re-entered pipeline at stage 7 (ED-04 §10); review_queue row resolved",
    },
    TrustState.UNDER_REVIEW.value: {
        TrustState.AI_ASSESSED.value:
            "Review closed without escalation — returns to base AI-assessed state",
        TrustState.VERIFIED.value:
            "review_queue row resolved with resolution='approved'",
        TrustState.DISPUTED.value:
            "Review confirmed contradiction",
        TrustState.RESTRICTED.value:
            "Review determined access restriction",
    },
}


@dataclass
class TransitionResult:
    success: bool
    from_state: str
    to_state: str
    reason: Optional[str] = None
    error: Optional[str] = None


async def advance_trust_state(
    session: AsyncSession,
    resource_id: uuid.UUID,
    target_state: str,
    actor: str = "system",
    evidence: Optional[str] = None,
) -> TransitionResult:
    """Attempt to advance a resource's trust_state to target_state.

    Validates the transition against ALLOWED_TRANSITIONS.
    Logs the attempt regardless of outcome (for the audit trail).

    Returns a TransitionResult — never raises on invalid transitions,
    so callers can handle them explicitly.
    """
    result = await session.execute(
        select(Resource).where(Resource.resource_id == resource_id)
    )
    resource: Optional[Resource] = result.scalar_one_or_none()

    if resource is None:
        return TransitionResult(
            success=False, from_state="unknown", to_state=target_state,
            error=f"Resource {resource_id} not found",
        )

    current = resource.trust_state
    allowed_targets = ALLOWED_TRANSITIONS.get(current, {})

    if target_state not in allowed_targets:
        return TransitionResult(
            success=False, from_state=current, to_state=target_state,
            error=(
                f"Invalid transition {current!r} → {target_state!r}. "
                f"Allowed from {current!r}: {list(allowed_targets.keys()) or 'none'}. "
                "This is a hard rule (ED-04 §11) — do not bypass."
            ),
        )

    # Guard: verified / authoritative_official require a resolved review_queue row
    if target_state in (TrustState.VERIFIED.value, TrustState.AUTHORITATIVE_OFFICIAL.value):
        resolved = await session.execute(
            select(ReviewQueue).where(
                ReviewQueue.subject_type == "resource",
                ReviewQueue.subject_id == resource_id,
                ReviewQueue.status == "resolved",
                ReviewQueue.resolution == "approved",
            )
        )
        if resolved.scalar_one_or_none() is None:
            return TransitionResult(
                success=False, from_state=current, to_state=target_state,
                error=(
                    f"Cannot advance to {target_state!r}: no resolved review_queue row "
                    "with resolution='approved' exists for this resource. "
                    "ED-04 §11 / LD-02 §2 — this gate cannot be skipped."
                ),
            )

    await session.execute(
        update(Resource)
        .where(Resource.resource_id == resource_id)
        .values(trust_state=target_state, updated_at=datetime.utcnow())
    )

    return TransitionResult(
        success=True, from_state=current, to_state=target_state,
        reason=allowed_targets[target_state],
    )
