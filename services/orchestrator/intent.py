"""
services/orchestrator/intent.py — Understand stage.

Outputs per ED-13 §4:
  detected_claim_type  — feeds authority_weights lookup (closes the loop with ED-04 §2)
  intent_state         — the normalised information need
  inferred_mode        — which of the five OrchestratorMode values fits this query
  sub_problems         — decomposed sub-questions (mandatory for problem_solving mode)
  normalised_query     — cleaned query string for downstream retrieval

MUST NOT: default unclassified claim_type to highest-authority source type (ED-13 §4).
MUST NOT: confidence substitute for evidence in claim_type assignment (ED-04 §3).
"""
from __future__ import annotations

import json
import os
from dataclasses import dataclass, field
from typing import Optional

import httpx

from core.enums import OrchestratorMode

# ── Claim types that authority_weights already uses ───────────────────────────
CLAIM_TYPES = (
    "current_legal_requirement",
    "professional_standard",
    "research_finding",
    "lived_operational_knowledge",
    "unclassified",       # ED-13 §4: neutral treatment, not boosted
)

_SYSTEM = """
You are the Rumuo Understand stage for Medicine queries in Nigeria.

Given a user query, return ONLY a JSON object with these keys:

{
  "normalised_query":     "<cleaned query, max 200 chars>",
  "detected_claim_type":  "<one of: current_legal_requirement | professional_standard | research_finding | lived_operational_knowledge | unclassified>",
  "intent_state":         "<one-sentence description of the underlying information need>",
  "inferred_mode":        "<one of: quick_discovery | exploration | problem_solving | deep_research | keep_current>",
  "sub_problems":         ["<sub-question 1>", "<sub-question 2>"]
}

Rules:
- detected_claim_type = unclassified when uncertain. Never default to the highest-authority type.
- sub_problems is empty [] for quick_discovery; mandatory (≥2 items) for problem_solving/deep_research.
- Return ONLY the JSON object. No markdown, no preamble.
""".strip()


@dataclass
class IntentResult:
    normalised_query: str
    detected_claim_type: str = "unclassified"
    intent_state: str = ""
    inferred_mode: Optional[str] = None
    sub_problems: list[str] = field(default_factory=list)
    raw_llm_response: Optional[dict] = None


async def understand_query(
    query: str,
    mode: str = OrchestratorMode.QUICK_DISCOVERY.value,
) -> IntentResult:
    """Parse a query through the Understand stage.

    Falls back to a minimal IntentResult if the LLM is unavailable,
    so the pipeline never hard-fails at this stage.
    """
    api_key = os.environ.get("ANTHROPIC_API_KEY", "")
    if not api_key:
        return _fallback(query, mode)

    payload = {
        "model": "claude-sonnet-4-6",
        "max_tokens": 512,
        "system": _SYSTEM,
        "messages": [{"role": "user", "content": query}],
    }
    try:
        async with httpx.AsyncClient(timeout=20) as c:
            r = await c.post(
                "https://api.anthropic.com/v1/messages",
                headers={
                    "x-api-key": api_key,
                    "anthropic-version": "2023-06-01",
                    "content-type": "application/json",
                },
                json=payload,
            )
            r.raise_for_status()
            raw = json.loads(r.json()["content"][0]["text"].strip())
    except Exception:
        return _fallback(query, mode)

    claim_type = raw.get("detected_claim_type", "unclassified")
    if claim_type not in CLAIM_TYPES:
        claim_type = "unclassified"

    inferred = raw.get("inferred_mode", mode)
    if inferred not in {m.value for m in OrchestratorMode}:
        inferred = mode

    return IntentResult(
        normalised_query=raw.get("normalised_query", query)[:200],
        detected_claim_type=claim_type,
        intent_state=raw.get("intent_state", ""),
        inferred_mode=inferred,
        sub_problems=raw.get("sub_problems", []),
        raw_llm_response=raw,
    )


def _fallback(query: str, mode: str) -> IntentResult:
    """Minimal result when LLM is unavailable — pipeline continues."""
    return IntentResult(
        normalised_query=query[:200],
        detected_claim_type="unclassified",
        inferred_mode=mode,
    )
