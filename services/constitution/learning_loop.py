"""
services/constitution/learning_loop.py — ED-12 §2 loop closure ledger.

Records loop_stage events and computes loop_closure_latency.
Enforces: MUST NOT report loop health from gap_detected volume alone (ED-12 §2.2).
"""
from __future__ import annotations

import uuid
from datetime import datetime, timedelta
from typing import Optional

from sqlalchemy import func, select
from sqlalchemy.ext.asyncio import AsyncSession

from core.enums import LoopStage
from core.models import LearningLoopEvent, CoverageGap


async def record_loop_event(
    session: AsyncSession,
    stage: str,
    gap_id: uuid.UUID,
    resource_id: Optional[uuid.UUID] = None,
) -> LearningLoopEvent:
    """Write a learning_loop_events row for the given stage."""
    event = LearningLoopEvent(
        loop_stage=stage,
        coverage_gap_id=gap_id,
        resource_id=resource_id,
        occurred_at=datetime.utcnow(),
    )
    session.add(event)
    await session.flush()
    return event


async def compute_closure_latency(
    session: AsyncSession,
    gap_id: uuid.UUID,
) -> Optional[timedelta]:
    """Compute gap_detected → resource_served latency for a single gap.

    Returns None when the loop has not yet closed (resource_served not yet recorded).
    """
    detected_result = await session.execute(
        select(LearningLoopEvent.occurred_at)
        .where(
            LearningLoopEvent.coverage_gap_id == gap_id,
            LearningLoopEvent.loop_stage == LoopStage.GAP_DETECTED.value,
        )
        .order_by(LearningLoopEvent.occurred_at.asc())
        .limit(1)
    )
    detected_at = detected_result.scalar_one_or_none()
    if detected_at is None:
        return None

    served_result = await session.execute(
        select(LearningLoopEvent.occurred_at)
        .where(
            LearningLoopEvent.coverage_gap_id == gap_id,
            LearningLoopEvent.loop_stage == LoopStage.RESOURCE_SERVED.value,
        )
        .order_by(LearningLoopEvent.occurred_at.asc())
        .limit(1)
    )
    served_at = served_result.scalar_one_or_none()
    if served_at is None:
        return None

    return served_at - detected_at


async def loop_health_report(
    session: AsyncSession,
    universe_id: str,
) -> dict:
    """ED-12 §2.2: report BOTH detection volume AND closure rate.

    MUST NOT return only detected count — that repeats the gap-counting
    without closure mistake §2.2 explicitly prohibits.
    """
    total_gaps = await session.execute(
        select(func.count())
        .select_from(CoverageGap)
        .where(CoverageGap.knowledge_universe_id == universe_id)
    )
    total = total_gaps.scalar()

    # Gaps that have at least one resource_served event
    closed_subquery = (
        select(LearningLoopEvent.coverage_gap_id)
        .where(LearningLoopEvent.loop_stage == LoopStage.RESOURCE_SERVED.value)
        .join(CoverageGap, CoverageGap.gap_id == LearningLoopEvent.coverage_gap_id)
        .where(CoverageGap.knowledge_universe_id == universe_id)
        .distinct()
        .scalar_subquery()
    )
    closed_count_result = await session.execute(
        select(func.count()).select_from(
            select(LearningLoopEvent.coverage_gap_id)
            .where(LearningLoopEvent.loop_stage == LoopStage.RESOURCE_SERVED.value)
            .join(CoverageGap, CoverageGap.gap_id == LearningLoopEvent.coverage_gap_id)
            .where(CoverageGap.knowledge_universe_id == universe_id)
            .distinct()
            .subquery()
        )
    )
    closed = closed_count_result.scalar() or 0

    open_loops = total - closed
    closure_rate = round(closed / total, 3) if total else 0.0

    return {
        "universe_id":   universe_id,
        "gaps_detected": total,
        "gaps_closed":   closed,
        "gaps_open":     open_loops,
        "closure_rate":  closure_rate,
        # ED-12 §2.2: explicitly flag if reporting would be misleading
        "health_warning": (
            "Loop is not closing — acquisition or indexing pipeline may be stalled."
            if total > 0 and closure_rate < 0.05 else None
        ),
    }
