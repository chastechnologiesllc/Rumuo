"""
services/intelligence/training.py — ED-13 §1 training examples.

MUST NOT: weight unverified examples equally with verified_successful ones.
MUST NOT: derive outcome_quality=verified_successful from user_signals volume alone.
A path is verified_successful only via the same evidence/review mechanisms ED-04 defines.
"""
from __future__ import annotations

import uuid
from datetime import datetime
from typing import Optional

from sqlalchemy import select
from sqlalchemy.ext.asyncio import AsyncSession

from core.enums import TrainingOutcomeQuality
from core.models import TrainingExample, ReviewQueue, Evidence


# Weight per outcome_quality — verified_successful carries strongest signal (ED-13 §1.1)
QUALITY_WEIGHTS: dict[str, float] = {
    TrainingOutcomeQuality.VERIFIED_SUCCESSFUL.value: 1.0,
    TrainingOutcomeQuality.EVIDENCE_SUPPORTED.value:  0.75,
    TrainingOutcomeQuality.PLAUSIBLE.value:            0.4,
    TrainingOutcomeQuality.UNVERIFIED.value:           0.1,
}


async def record_example(
    session: AsyncSession,
    question_type: str,
    context: dict,
    concepts: list[uuid.UUID],
    resource_path: list[uuid.UUID],
    outcome_quality: str,
    provenance_evidence_id: Optional[uuid.UUID] = None,
) -> TrainingExample:
    """Record a training example.

    outcome_quality='verified_successful' requires a provenance_evidence_id
    linking to an Evidence row with claim_status='platform_verified',
    OR a resolved review_queue row with resolution='approved'.
    Callers MUST NOT pass verified_successful without one of those — this
    function enforces the constraint.
    """
    if outcome_quality == TrainingOutcomeQuality.VERIFIED_SUCCESSFUL.value:
        if provenance_evidence_id is None:
            raise ValueError(
                "outcome_quality='verified_successful' requires provenance_evidence_id. "
                "ED-13 §1.1: verified_successful needs the same evidence gate as ED-04. "
                "Do not derive it from engagement volume alone."
            )
        # Verify the evidence row is platform_verified
        ev_result = await session.execute(
            select(Evidence).where(Evidence.evidence_id == provenance_evidence_id)
        )
        ev = ev_result.scalar_one_or_none()
        if ev is None or ev.claim_status != "platform_verified":
            raise ValueError(
                f"Evidence {provenance_evidence_id} is not platform_verified. "
                "Cannot record a verified_successful training example without it."
            )

    example = TrainingExample(
        question_type=question_type,
        context=context,
        concepts=concepts,
        resource_path=resource_path,
        outcome_quality=outcome_quality,
        provenance=provenance_evidence_id,
        created_at=datetime.utcnow(),
    )
    session.add(example)
    await session.flush()
    return example


async def get_weighted_examples(
    session: AsyncSession,
    question_type: Optional[str] = None,
    min_quality: str = TrainingOutcomeQuality.PLAUSIBLE.value,
    limit: int = 100,
) -> list[tuple[TrainingExample, float]]:
    """Return examples with their quality weights, ordered strongest-first.

    MUST NOT return unverified and verified_successful examples with equal weight —
    the weight tuple is what enforces ED-13 §1.1's stronger-signal requirement.
    """
    min_weight = QUALITY_WEIGHTS.get(min_quality, 0.1)

    stmt = select(TrainingExample)
    if question_type:
        stmt = stmt.where(TrainingExample.question_type == question_type)
    stmt = stmt.limit(limit * 3)   # over-fetch to allow weight filtering

    result = await session.execute(stmt)
    examples = result.scalars().all()

    weighted = [
        (ex, QUALITY_WEIGHTS.get(ex.outcome_quality, 0.0))
        for ex in examples
        if QUALITY_WEIGHTS.get(ex.outcome_quality, 0.0) >= min_weight
    ]
    weighted.sort(key=lambda x: x[1], reverse=True)
    return weighted[:limit]
