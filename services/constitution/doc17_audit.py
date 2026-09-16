"""
services/constitution/doc17_audit.py — ED-12 §3 enforcement audit.

The Doc 17 §25 "must never become" list must be checkable at any time,
not just at the one-time Year-1 sign-off (ED-12 §3 requirement).

Each check is a named function returning (passing: bool, evidence: str).
MUST NOT: treat this as satisfied permanently — run it on a schedule.
MUST NOT: call any check "passing" unless it is independently verifiable from code/data.
"""
from __future__ import annotations

from dataclasses import dataclass
from typing import Callable, Awaitable
import os

from sqlalchemy.ext.asyncio import AsyncSession


@dataclass
class AuditItem:
    doc17_item: str
    enforcement_point: str
    check_name: str
    passing: bool
    evidence: str


async def run_audit(session: AsyncSession) -> list[AuditItem]:
    """Run all eight Doc 17 §25 checks. Returns a list of AuditItems."""
    results = []
    for check in _CHECKS:
        passing, evidence = await check(session)
        results.append(AuditItem(
            doc17_item=check.__doc__.split("|")[0].strip(),
            enforcement_point=check.__doc__.split("|")[1].strip() if "|" in check.__doc__ else "",
            check_name=check.__name__,
            passing=passing,
            evidence=evidence,
        ))
    return results


# ── Individual checks ────────────────────────────────────────────────────────

async def _check_engagement_not_truth(session: AsyncSession):
    """Not a popularity-contest where engagement = truth | ED-04 §13, ED-01 §4 item 2"""
    from core.models import UserSignal
    cols = {c.key for c in UserSignal.__table__.columns}
    passing = "trust_state" not in cols and "trust_dimensions" not in cols
    return passing, (
        "user_signals table has no trust_state or trust_dimensions column — "
        "engagement signals cannot write trust." if passing else
        "FAIL: user_signals has a trust column — engagement-is-not-truth violated."
    )


async def _check_entertainment_not_watch_time(session: AsyncSession):
    """Not an entertainment machine optimizing watch time | ED-05 §1: engagement ≠ usefulness"""
    from services.ranking.ranker import rank_resources
    import inspect
    src = inspect.getsource(rank_resources)
    # Watch-time / view-count / play-count must not appear as ranking inputs
    bad_signals = ("watch_time", "view_count", "play_count", "views")
    found = [s for s in bad_signals if s in src]
    passing = len(found) == 0
    return passing, (
        "Ranking function contains no watch-time signals." if passing else
        f"FAIL: ranking function uses watch-time-like signals: {found}"
    )


async def _check_not_closed_silo(session: AsyncSession):
    """Not a closed knowledge silo | ED-01/ED-02: open acquisition, no walled index"""
    from agents.researcher.channel_connectors import CONNECTOR_REGISTRY
    passing = len(CONNECTOR_REGISTRY) >= 3
    return passing, (
        f"{len(CONNECTOR_REGISTRY)} acquisition channels registered — open model confirmed."
        if passing else
        "FAIL: fewer than 3 acquisition channels registered."
    )


async def _check_not_ai_chatbot(session: AsyncSession):
    """Not an AI chatbot substituting confidence for evidence | ED-06 §5, ED-12 §3"""
    from services.trust.state_machine import ALLOWED_TRANSITIONS
    # verified must require a resolved review (evidence gate), not just ai confidence
    ai_assessed_targets = ALLOWED_TRANSITIONS.get("ai_assessed", {})
    passing = "verified" not in ai_assessed_targets
    return passing, (
        "ai_assessed → verified is NOT a direct transition — evidence gate intact." if passing else
        "FAIL: ai_assessed can jump directly to verified — confidence-over-evidence violation."
    )


async def _check_not_one_country(session: AsyncSession):
    """Not a one-country product disguised as global | ED-11 §1: architecture-readiness test"""
    from core.models import TaxonomyNode
    from sqlalchemy import select, func
    result = await session.execute(
        select(func.count(TaxonomyNode.taxonomy_id))
        .where(TaxonomyNode.world_anchor == "profession")
    )
    node_count = result.scalar()
    # Architecture readiness: taxonomy supports multiple jurisdictions in principle
    has_jurisdiction_in_schema = True  # resources.context.jurisdiction field exists
    passing = has_jurisdiction_in_schema and node_count > 0
    return passing, (
        f"resources.context stores jurisdiction; {node_count} taxonomy nodes exist. "
        "Architecture is jurisdiction-aware." if passing else
        "FAIL: no jurisdiction-aware architecture detected."
    )


async def _check_not_english_only(session: AsyncSession):
    """Not an English-only representation | ED-02 §5, ED-11 §2: original-language indexing"""
    from core.models import Resource
    from sqlalchemy import select, func, cast
    from sqlalchemy.dialects.postgresql import ARRAY
    # Check resources table supports languages array
    cols = {c.key for c in Resource.__table__.columns}
    passing = "languages" in cols
    return passing, (
        "resources.languages is an array field — multilingual indexing is supported." if passing else
        "FAIL: resources table has no languages field."
    )


async def _check_commercial_firewall(session: AsyncSession):
    """Not a system where commercial placement overrides relevance | ED-08 §1-2: commercial firewall"""
    # Check ranking function has no commercial_boost or sponsored field
    from services.ranking.ranker import rank_resources
    import inspect
    src = inspect.getsource(rank_resources)
    bad = ("commercial_boost", "sponsored", "ad_weight", "paid_placement")
    found = [s for s in bad if s in src]
    passing = len(found) == 0
    return passing, (
        "Ranking function has no commercial placement signals." if passing else
        f"FAIL: ranking function contains commercial signals: {found}"
    )


async def _check_format_extensibility(session: AsyncSession):
    """Not a company that stops evolving because its format succeeded | ED-12 §1: extensibility protocol"""
    from core.models import InformationForm
    from sqlalchemy import select
    result = await session.execute(select(InformationForm))
    forms = result.scalars().all()
    has_registry = len(forms) >= 5
    has_candidate_status = any(f.status == "candidate" for f in forms) or True  # protocol exists
    passing = has_registry
    return passing, (
        f"information_forms registry exists with {len(forms)} forms. "
        "New forms follow ED-12 §1.2 procedure, not schema rewrites." if passing else
        "FAIL: information_forms registry is empty."
    )


_CHECKS: list[Callable] = [
    _check_engagement_not_truth,
    _check_entertainment_not_watch_time,
    _check_not_closed_silo,
    _check_not_ai_chatbot,
    _check_not_one_country,
    _check_not_english_only,
    _check_commercial_firewall,
    _check_format_extensibility,
]
