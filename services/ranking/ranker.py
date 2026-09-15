"""
services/ranking/ranker.py — resource ranking (ED-05).

Ranking inputs: trust_dimensions, relevance signals, freshness, user signals.
MUST NOT: share a write path with services/commercial/ (ED-04 §12).
MUST NOT: use user_signals aggregate to modify trust_state directly (ED-01 §4 item 2).
MUST NOT: allow authority_weights for commercial sources to exceed verified research (ED-05 §4).

This is a stub implementation. Full implementation in Phase B per LD-04.
"""
from __future__ import annotations
from dataclasses import dataclass
from typing import Any, Optional
import uuid


@dataclass
class RankedResult:
    resource_id: uuid.UUID
    score: float
    rank: int
    score_components: dict[str, float]   # keeps multi-dimensional score visible, not collapsed


def rank_resources(
    candidates: list[dict[str, Any]],
    query: Optional[str] = None,
    user_context: Optional[dict] = None,
) -> list[RankedResult]:
    """Score and rank a list of resource dicts from the experience API query layer.

    Each candidate dict must have: resource_id, trust_state, trust_dimensions, context.

    Scoring weights (Phase A defaults — tune per ED-05 §3 evaluation):
      authority  : 0.30
      relevance  : 0.25
      evidence   : 0.20
      freshness  : 0.15
      local_fit  : 0.10   (context.geography match for Nigeria)

    MUST NOT collapse trust_dimensions into a single score and discard the components.
    The score_components dict is stored alongside the final score so it is auditable.
    """
    _TRUST_BOOST = {
        "authoritative_official": 1.0,
        "verified":               0.9,
        "evidence_supported":     0.75,
        "ai_assessed":            0.5,
    }

    results = []
    for c in candidates:
        td = c.get("trust_dimensions") or {}
        ctx = (c.get("context") or {})
        ts_boost = _TRUST_BOOST.get(c.get("trust_state", ""), 0.4)

        components = {
            "trust_state_boost": ts_boost,
            "authority":   float(td.get("authority",  0.5)) * 0.30,
            "relevance":   float(td.get("relevance",  0.5)) * 0.25,
            "evidence":    float(td.get("evidence",   0.5)) * 0.20,
            "freshness":   float(td.get("freshness",  0.5)) * 0.15,
            "local_fit":   (1.0 if ctx.get("geography") == "Nigeria" else 0.5) * 0.10,
        }
        score = ts_boost * sum(components[k] for k in components if k != "trust_state_boost")

        results.append(RankedResult(
            resource_id=uuid.UUID(str(c["resource_id"])),
            score=round(score, 4),
            rank=0,
            score_components=components,
        ))

    results.sort(key=lambda r: r.score, reverse=True)
    for i, r in enumerate(results):
        r.rank = i + 1
    return results
