"""
agents/organizer/classification.py — stage 6 classification via LLM.

Reads the ExtractionResult produced by the form extractor and returns
the classification dict that pipeline.stage_6_classify() expects:
  {
    confidence: float,
    taxonomy_node_ids: [str, ...],
    question_ids: [str, ...],
    context: {geography, jurisdiction, audience, level, industry, time_period},
    trust_assessment: {trust_dimensions: {...}, field_confidence: {...}},
  }

MUST NOT: hard-code taxonomy node IDs — look them up from the DB.
MUST NOT: let confidence substitute for evidence (ED-04 §3).
MUST NOT: write ai-inferred trust_dimensions as if they were human-verified (ED-04 §3).
"""
from __future__ import annotations
import json
import os
from typing import Any, Optional

import httpx
from sqlalchemy.ext.asyncio import AsyncSession

from services.taxonomy.crud import find_nodes_by_name, find_questions


_SYSTEM_PROMPT = """
You are the Rumuo Classification Agent for the Medicine / Nigeria pilot.

You will receive extracted content from a resource (text, title, description) and
must return a JSON object with EXACTLY these keys:

{
  "confidence": <float 0.0–1.0 — overall classification confidence>,
  "taxonomy_matches": [<list of taxonomy node names from the DB>],
  "question_intents": [<list of normalized_intent strings from the DB>],
  "context": {
    "geography":   <e.g. "Nigeria" or null>,
    "jurisdiction": <e.g. "NG" or null>,
    "audience":    <e.g. "clinician", "medical_student", "researcher" or null>,
    "level":       <e.g. "introductory", "intermediate", "advanced" or null>,
    "industry":    <e.g. "healthcare" or null>,
    "time_period": <e.g. "2020–2024" or null>
  },
  "trust_dimensions": {
    "authority":     <float 0.0–1.0 — source authority score>,
    "evidence":      <float — evidence quality>,
    "relevance":     <float — topic relevance>,
    "freshness":     <float — content freshness>,
    "context":       <float — local applicability for Nigeria>,
    "consistency":   <float — consistency with other indexed resources>,
    "verification":  <float — verifiability of claims>
  },
  "field_confidence": {
    "title":        <"human_verified" | "ai_inferred">,
    "description":  <"human_verified" | "ai_inferred">,
    "creator":      <"human_verified" | "ai_inferred">,
    "published_date": <"human_verified" | "ai_inferred">
  }
}

CRITICAL RULES:
- Return ONLY the JSON object. No markdown, no preamble.
- taxonomy_matches must be node names that exist in the Medicine/Nigeria taxonomy.
- question_intents must be intent IDs from the seeded questions table.
- trust_dimensions values are your best AI estimates — NEVER claim they are human-verified.
- confidence below 0.6 should be returned honestly — the pipeline will queue for human review.
""".strip()


async def classify(
    session: AsyncSession,
    extraction: dict[str, Any],
    form_id: str,
) -> dict[str, Any]:
    """Classify extracted content and return the stage_6_classify() input dict.

    extraction: ExtractionResult serialised to dict (title, summary, raw_text, etc.)
    form_id:    information_form slug (used as context for the LLM).
    """
    raw_text = extraction.get("raw_text") or extraction.get("summary") or ""
    title = extraction.get("title") or ""
    user_content = (
        f"Information form: {form_id}\n"
        f"Title: {title}\n"
        f"Content (first 2000 chars):\n{raw_text[:2000]}"
    )

    llm_result = await _call_llm(user_content)
    if llm_result is None:
        return {
            "confidence": 0.0,
            "taxonomy_node_ids": [],
            "question_ids": [],
            "context": {},
            "trust_assessment": {"trust_dimensions": {}, "field_confidence": {}},
        }

    # Resolve taxonomy names → DB node IDs
    taxonomy_node_ids: list[str] = []
    for name in llm_result.get("taxonomy_matches", []):
        nodes = await find_nodes_by_name(session, name, world_anchor="profession")
        taxonomy_node_ids.extend(str(n.taxonomy_id) for n in nodes[:2])

    # Resolve question intents → DB question IDs
    question_ids: list[str] = []
    for intent in llm_result.get("question_intents", []):
        qs = await find_questions(session, intent, limit=2)
        question_ids.extend(str(q.question_id) for q in qs)

    return {
        "confidence":        llm_result.get("confidence", 0.5),
        "taxonomy_node_ids": taxonomy_node_ids,
        "question_ids":      question_ids,
        "context":           llm_result.get("context", {}),
        "trust_assessment": {
            "trust_dimensions": llm_result.get("trust_dimensions", {}),
            "field_confidence": llm_result.get("field_confidence", {}),
        },
    }


async def _call_llm(user_content: str) -> Optional[dict]:
    """Call the Anthropic Messages API for classification.

    Uses claude-sonnet-4-6 with JSON-only output constraint.
    Returns parsed dict or None on failure.
    """
    api_key = os.environ.get("ANTHROPIC_API_KEY", "")
    if not api_key:
        # Graceful degradation — return a low-confidence placeholder
        return {"confidence": 0.0, "taxonomy_matches": [], "question_intents": [],
                "context": {}, "trust_dimensions": {}, "field_confidence": {}}

    payload = {
        "model": "claude-sonnet-4-6",
        "max_tokens": 1024,
        "system": _SYSTEM_PROMPT,
        "messages": [{"role": "user", "content": user_content}],
    }
    try:
        async with httpx.AsyncClient(timeout=30) as client:
            r = await client.post(
                "https://api.anthropic.com/v1/messages",
                headers={
                    "x-api-key": api_key,
                    "anthropic-version": "2023-06-01",
                    "content-type": "application/json",
                },
                json=payload,
            )
            r.raise_for_status()
            text = r.json()["content"][0]["text"].strip()
            return json.loads(text)
    except Exception:
        return None
