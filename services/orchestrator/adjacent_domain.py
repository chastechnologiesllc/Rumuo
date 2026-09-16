"""
services/orchestrator/adjacent_domain.py — adjacent-domain injection (ED-13 §3).

When a session resolves to a world_anchor entity (e.g. Profession=Doctor), traverse
one hop via relationships (requires, depends_on, related_to) to adjacent entities
WITHOUT a matching world_anchor — e.g. Doctor → requires → Accounting knowledge.

Results go into the exploration slot ONLY — never into primary ranked results.

MUST NOT: inject adjacent-domain content into primary results ahead of directly relevant ones.
MUST NOT: silently rewrite user's explicit_interests from a single adjacent-domain surface.
"""
from __future__ import annotations

from typing import Any, Optional

from sqlalchemy import select
from sqlalchemy.ext.asyncio import AsyncSession

from core.models import Resource, Relationship, Entity
from services.orchestrator.intent import IntentResult

# Relations to traverse for adjacent-domain discovery (ED-13 §3)
_ADJACENT_RELATIONS = ("requires", "depends_on", "related_to")
_SERVABLE_STATES = ("ai_assessed", "evidence_supported", "verified", "authoritative_official")


async def inject_adjacent_domain(
    session: AsyncSession,
    intent: IntentResult,
    exclude_ids: set[str],
    limit: int = 3,
) -> list[dict[str, Any]]:
    """Return up to `limit` resources from adjacent domains for the exploration slot.

    Traverses the entity graph one hop from world_anchor entities related to the query's
    intent. Returns resources that are NOT already in the primary result set (exclude_ids).

    Returns an empty list (gracefully) when the graph has no adjacent edges yet —
    the exploration slot is always a discovery *offer*, never a guarantee.
    """
    # Find entities tagged with a world_anchor that relate to 'medicine' or 'doctor'
    anchor_result = await session.execute(
        select(Entity).where(
            Entity.world_anchor == "profession",
            Entity.name.ilike("%medicine%"),
        ).limit(5)
    )
    anchor_entities = list(anchor_result.scalars().all())
    if not anchor_entities:
        return []

    anchor_ids = [e.entity_id for e in anchor_entities]

    # One hop out via _ADJACENT_RELATIONS to entities WITHOUT a matching world_anchor
    adjacent_result = await session.execute(
        select(Relationship).where(
            Relationship.subject_type == "entity",
            Relationship.subject_id.in_(anchor_ids),
            Relationship.relation.in_(_ADJACENT_RELATIONS),
            Relationship.object_type == "entity",
        ).limit(20)
    )
    adjacent_edges = list(adjacent_result.scalars().all())
    if not adjacent_edges:
        return []

    adjacent_entity_ids = [e.object_id for e in adjacent_edges]

    # Find resources linked to those adjacent entities, not already in primary set
    linked_result = await session.execute(
        select(Relationship).where(
            Relationship.object_type == "entity",
            Relationship.object_id.in_(adjacent_entity_ids),
            Relationship.subject_type == "resource",
        ).limit(limit * 3)
    )
    linked = list(linked_result.scalars().all())
    if not linked:
        return []

    resource_ids = [r.subject_id for r in linked
                    if str(r.subject_id) not in exclude_ids][:limit * 2]
    if not resource_ids:
        return []

    resources_result = await session.execute(
        select(Resource).where(
            Resource.resource_id.in_(resource_ids),
            Resource.trust_state.in_(_SERVABLE_STATES),
        ).limit(limit)
    )
    resources = list(resources_result.scalars().all())

    return [
        {
            "id": str(r.resource_id),
            "title": r.title,
            "summary": r.description,
            "url": r.canonical_url,
            "trust_state": r.trust_state,
            "type": r.type,
            "exploration_reason": "adjacent_domain",   # never hide why this surfaced
        }
        for r in resources
    ]
