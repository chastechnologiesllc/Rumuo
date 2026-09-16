"""
services/intelligence/model_lifecycle.py — ED-13 §5.1 model registry.

Manages candidate → active → deprecated lifecycle.

MUST NOT: promote to active for orchestration/synthesis without the evidence gate.
MUST NOT: let a model swap alter trust_state transition logic (ED-04 §11).
MUST NOT: erase historical provenance when a model is deprecated (ED-13 §5.2).
"""
from __future__ import annotations

import uuid
from datetime import datetime
from typing import Optional

from sqlalchemy import select, update
from sqlalchemy.ext.asyncio import AsyncSession

from core.models import ModelRegistry


async def register_candidate(
    session: AsyncSession,
    provider: str,
    version: str,
    role: str,
    evaluation_metrics: Optional[dict] = None,
) -> ModelRegistry:
    """Register a new model at status='candidate'."""
    model = ModelRegistry(
        provider=provider,
        version=version,
        role=role,
        status="candidate",
        evaluation_metrics=evaluation_metrics or {},
    )
    session.add(model)
    await session.flush()
    return model


async def promote_to_active(
    session: AsyncSession,
    model_id: uuid.UUID,
    promoted_by: str,
    evidence_summary: str,
) -> ModelRegistry:
    """Promote a candidate to active.

    For roles 'orchestration' or 'synthesis': requires evidence_summary to be
    non-empty (the evidence-before-confidence gate — ED-13 §5.2).
    MUST NOT self-certify — promotion of these roles escalates to founder (ED-13 §9).
    """
    result = await session.execute(
        select(ModelRegistry).where(ModelRegistry.model_id == model_id)
    )
    model = result.scalar_one_or_none()
    if model is None:
        raise ValueError(f"model_id={model_id} not found")
    if model.status != "candidate":
        raise ValueError(f"Model is {model.status!r}, not 'candidate' — cannot promote.")

    # Evidence gate for high-trust roles (ED-13 §5.2)
    if model.role in ("orchestration", "synthesis") and not evidence_summary.strip():
        raise ValueError(
            f"Cannot promote role={model.role!r} to active without evidence_summary. "
            "ED-13 §5.2: evidence-before-confidence gate. "
            "This promotion requires founder sign-off (ED-13 §9)."
        )

    await session.execute(
        update(ModelRegistry)
        .where(ModelRegistry.model_id == model_id)
        .values(
            status="active",
            promoted_at=datetime.utcnow(),
            evaluation_metrics={
                **(model.evaluation_metrics or {}),
                "promoted_by": promoted_by,
                "evidence_summary": evidence_summary,
                "promoted_at": datetime.utcnow().isoformat(),
            },
        )
    )
    return model


async def deprecate_model(
    session: AsyncSession,
    model_id: uuid.UUID,
    reason: str,
) -> None:
    """Deprecate a model. Historical provenance records are NOT erased (ED-13 §5.2).

    Deprecating a model changes what serves NEW requests — it does NOT
    retroactively change field_confidence tags or classification results
    already written against resources processed by this model.
    """
    await session.execute(
        update(ModelRegistry)
        .where(ModelRegistry.model_id == model_id)
        .values(
            status="deprecated",
            deprecated_at=datetime.utcnow(),
            evaluation_metrics=ModelRegistry.evaluation_metrics.op("||")(
                {"deprecation_reason": reason,
                 "deprecated_at": datetime.utcnow().isoformat(),
                 "provenance_note": (
                     "Resources classified by this model retain their original "
                     "field_confidence=ai_inferred tags — deprecation does not "
                     "erase historical provenance (ED-13 §5.2)."
                 )}
            ),
        )
    )


async def get_active_model(
    session: AsyncSession,
    role: str,
) -> Optional[ModelRegistry]:
    """Return the currently active model for a given role."""
    result = await session.execute(
        select(ModelRegistry).where(
            ModelRegistry.role == role,
            ModelRegistry.status == "active",
        ).order_by(ModelRegistry.promoted_at.desc()).limit(1)
    )
    return result.scalar_one_or_none()
