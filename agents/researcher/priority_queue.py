"""
agents/researcher/priority_queue.py — acquisition prioritisation (ED-02 §4).

Reads open coverage_gaps and the medicine_nigeria.yaml config to build an
ordered work list for the channel connectors.

MUST NOT: begin any acquisition run without founder sign-off on the config
(kickoff hard constraint). The ACQUISITION_ACTIVE env var is the gate.
MUST NOT: acquire content that requires bypassing auth/paywalls (ED-01 §4 item 1).
"""
from __future__ import annotations
import os
import uuid
from dataclasses import dataclass
from pathlib import Path
from typing import Optional

import yaml
from sqlalchemy import select
from sqlalchemy.ext.asyncio import AsyncSession

from core.models import CoverageGap


CONFIG_PATH = Path(__file__).parent / "config" / "medicine_nigeria.yaml"


@dataclass
class AcquisitionTask:
    gap_id: uuid.UUID
    query_text: str
    universe_id: str
    priority: int               # lower = higher priority
    suggested_channel: str      # which channel connector to use
    source_type_hint: Optional[str] = None


def _load_config() -> dict:
    return yaml.safe_load(CONFIG_PATH.read_text())


def _channel_for_source_type(source_type: str, config: dict) -> str:
    for st in config.get("source_types", []):
        if st["type"] == source_type:
            channels = st.get("channels", [])
            return channels[0] if channels else "web_crawl"
    return "web_crawl"


async def build_work_list(
    session: AsyncSession,
    limit: int = 50,
) -> list[AcquisitionTask]:
    """Return a prioritised list of acquisition tasks from open coverage_gaps.

    MUST NOT run if ACQUISITION_ACTIVE != '1' (founder sign-off gate).
    """
    if os.environ.get("ACQUISITION_ACTIVE", "0") != "1":
        raise RuntimeError(
            "ACQUISITION_ACTIVE is not set to '1'. "
            "This is the founder sign-off gate (kickoff hard constraint §4). "
            "Set ACQUISITION_ACTIVE=1 in .env only after LD-01 §3 has been signed off."
        )

    config = _load_config()

    result = await session.execute(
        select(CoverageGap)
        .where(CoverageGap.resolution_status == "open")
        .order_by(CoverageGap.detected_at.asc())
        .limit(limit)
    )
    gaps = list(result.scalars().all())

    tasks: list[AcquisitionTask] = []
    for i, gap in enumerate(gaps):
        # Simple heuristic: institution gaps are highest priority (Phase A config)
        phase_a_types = ["institution", "publisher", "organization"]
        source_type = phase_a_types[i % len(phase_a_types)]
        channel = _channel_for_source_type(source_type, config)
        tasks.append(AcquisitionTask(
            gap_id=gap.gap_id,
            query_text=gap.query_text,
            universe_id=gap.knowledge_universe_id,
            priority=i,
            suggested_channel=channel,
            source_type_hint=source_type,
        ))

    return tasks


async def mark_gap_triggered(
    session: AsyncSession,
    gap_id: uuid.UUID,
) -> None:
    """Update the coverage_gap to 'external_discovery_triggered' after a task is dispatched."""
    from sqlalchemy import update
    from datetime import datetime
    await session.execute(
        update(CoverageGap)
        .where(CoverageGap.gap_id == gap_id)
        .values(resolution_status="external_discovery_triggered")
    )

    from core.models import LearningLoopEvent
    session.add(LearningLoopEvent(
        loop_stage="acquisition_triggered",
        coverage_gap_id=gap_id,
        occurred_at=datetime.utcnow(),
    ))
