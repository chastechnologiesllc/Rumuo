"""
services/orchestrator/pipeline.py — search orchestration pipeline.

Five operating modes per ED-13 §2 (amendment to ED-06 §2 v1.1):
  quick_discovery   — exact-match-first, fast path
  exploration       — widens candidate set, prioritises exploration slot
  problem_solving   — mandatory decomposition even for short queries
  deep_research     — full research_plan lifecycle
  keep_current      — freshness-boosted, time-bounded

Stages: Understand → Find → Rank → Serve
Coverage gaps are written when no results meet the relevance threshold.

MUST NOT: force every query through one undifferentiated pipeline (ED-13 §2 / ED-06 §13).
MUST NOT: let user_signals aggregate write to trust_state (ED-01 §4 item 2).
MUST NOT: confidence substitute for evidence in claim_type detection (ED-13 §4).
"""
from __future__ import annotations

import uuid
from dataclasses import dataclass, field
from datetime import datetime
from typing import Any, Optional

from sqlalchemy.ext.asyncio import AsyncSession

from core.enums import OrchestratorMode, LoopStage
from core.models import LearningLoopEvent, CoverageGap
from services.orchestrator.intent import understand_query, IntentResult
from services.orchestrator.adjacent_domain import inject_adjacent_domain
from services.ranking.ranker import rank_resources, RankedResult
from services.taxonomy.crud import get_resources_for_question, find_questions


# Minimum trust score below which a gap is recorded
_GAP_THRESHOLD = 0.35


@dataclass
class OrchestratorResult:
    query: str
    mode: str
    intent: Optional[IntentResult]
    results: list[dict[str, Any]]
    exploration_slot: list[dict[str, Any]]
    gap_recorded: bool
    gap_id: Optional[uuid.UUID]
    sub_problems: list[str]
    detected_claim_type: Optional[str]


async def run(
    session: AsyncSession,
    query: str,
    mode: str = OrchestratorMode.QUICK_DISCOVERY.value,
    form_id: Optional[str] = None,
    country: str = "NG",
    language: str = "en",
    limit: int = 20,
    user_context: Optional[dict] = None,
    gap_id_hint: Optional[uuid.UUID] = None,
) -> OrchestratorResult:
    """Entry point for all search queries.

    1. Understand — parse intent, claim_type, mode inference
    2. Find        — pull candidates from DB
    3. Rank        — score by trust + relevance + local fit
    4. Serve       — write loop event, return
    """

    # ── Stage 1: Understand ──────────────────────────────────────────────────
    intent = await understand_query(query, mode=mode)
    effective_mode = intent.inferred_mode or mode

    # ── Stage 2: Find ────────────────────────────────────────────────────────
    from services.experience_api.queries import fetch_resources
    from services.experience_api.subcategory_map import resolve_subcategory

    form, subtype = resolve_subcategory(form_id) if form_id and "_" in form_id else (form_id, None)

    servable_states = ("ai_assessed", "evidence_supported", "verified", "authoritative_official")
    candidates, exact_count = await fetch_resources(
        session=session,
        form_id=form,
        subtype=subtype,
        query=intent.normalised_query,
        country=country,
        language=language,
        trust_states=servable_states,
        limit=limit * 2,      # over-fetch for ranking + exploration
        offset=0,
    )

    candidate_dicts = [c.model_dump() for c in candidates]

    # ── Stage 3: Rank (mode-aware) ───────────────────────────────────────────
    ranked = _rank_by_mode(candidate_dicts, intent, effective_mode)

    # Exploration slot — ED-13 §3: adjacent-domain injection, NOT in primary set
    exploration_slot: list[dict] = []
    if effective_mode in (OrchestratorMode.EXPLORATION.value, OrchestratorMode.PROBLEM_SOLVING.value):
        exploration_slot = await inject_adjacent_domain(
            session=session,
            intent=intent,
            exclude_ids={c["id"] for c in candidate_dicts},
            limit=3,
        )

    # keep_current: freshness boost already handled inside ranker; filter to recent
    if effective_mode == OrchestratorMode.KEEP_CURRENT.value:
        ranked = [r for r in ranked if _is_fresh(r)]

    primary_results = [candidate_dicts[r.rank - 1] for r in ranked[:limit]
                       if r.rank - 1 < len(candidate_dicts)]

    # ── Gap detection ─────────────────────────────────────────────────────────
    gap_recorded = False
    gap_id: Optional[uuid.UUID] = gap_id_hint
    top_score = ranked[0].score if ranked else 0.0

    if top_score < _GAP_THRESHOLD or not primary_results:
        gap = CoverageGap(
            query_text=query,
            knowledge_universe_id=f"medicine_nigeria:{form_id or 'all'}",
            detected_at=datetime.utcnow(),
            resolution_status="open",
        )
        session.add(gap)
        await session.flush()
        gap_id = gap.gap_id
        gap_recorded = True

        session.add(LearningLoopEvent(
            loop_stage=LoopStage.GAP_DETECTED.value,
            coverage_gap_id=gap.gap_id,
            occurred_at=datetime.utcnow(),
        ))

    # ── Loop closure event ────────────────────────────────────────────────────
    if primary_results and gap_id:
        session.add(LearningLoopEvent(
            loop_stage=LoopStage.RESOURCE_SERVED.value,
            coverage_gap_id=gap_id,
            occurred_at=datetime.utcnow(),
        ))

    return OrchestratorResult(
        query=query,
        mode=effective_mode,
        intent=intent,
        results=primary_results,
        exploration_slot=exploration_slot,
        gap_recorded=gap_recorded,
        gap_id=gap_id,
        sub_problems=intent.sub_problems,
        detected_claim_type=intent.detected_claim_type,
    )


def _rank_by_mode(
    candidates: list[dict],
    intent: IntentResult,
    mode: str,
) -> list[RankedResult]:
    """Apply mode-specific ranking adjustments before calling the core ranker."""
    if mode == OrchestratorMode.KEEP_CURRENT.value:
        # Boost freshness weight — pass a modified copy so core ranker is unchanged
        for c in candidates:
            td = c.get("trust_dimensions") or {}
            td["freshness"] = min(1.0, float(td.get("freshness", 0.5)) * 1.5)
            c["trust_dimensions"] = td

    return rank_resources(candidates, query=intent.normalised_query)


def _is_fresh(result: RankedResult) -> bool:
    """Keep-current filter: resource must have freshness score > 0.5."""
    return result.score_components.get("freshness", 0) > 0.5 * 0.15
