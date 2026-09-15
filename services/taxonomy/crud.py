"""
services/taxonomy/crud.py — taxonomy_nodes and questions CRUD (ED-03).

Rule (LD-03 §3): services/ranking/ and services/ingestion/ call this interface —
they never query taxonomy_nodes or questions directly.

ED-03 §2: taxonomy nodes are data, not code. This module reads from the DB only;
adding new nodes is done via seed scripts / migrations, not via application code paths.
"""
from typing import Optional
import uuid

from sqlalchemy import select
from sqlalchemy.ext.asyncio import AsyncSession

from core.models import TaxonomyNode, Question, Relationship


# ── Taxonomy lookup ───────────────────────────────────────────────────────────
async def get_node(session: AsyncSession, taxonomy_id: uuid.UUID) -> Optional[TaxonomyNode]:
    result = await session.execute(
        select(TaxonomyNode).where(TaxonomyNode.taxonomy_id == taxonomy_id)
    )
    return result.scalar_one_or_none()


async def get_subtree(
    session: AsyncSession,
    root_id: uuid.UUID,
    max_depth: int = 3,
) -> list[TaxonomyNode]:
    """Return a node and all its descendants up to max_depth levels deep."""
    all_nodes = []
    current_level = [root_id]

    for _ in range(max_depth + 1):
        if not current_level:
            break
        result = await session.execute(
            select(TaxonomyNode).where(
                TaxonomyNode.taxonomy_id.in_(current_level)
            )
        )
        nodes = list(result.scalars().all())
        all_nodes.extend(nodes)
        current_level = [n.taxonomy_id for n in nodes
                         if n.taxonomy_id != root_id or _ == 0]
        # Get children of this level
        child_result = await session.execute(
            select(TaxonomyNode).where(
                TaxonomyNode.parent_id.in_([n.taxonomy_id for n in nodes])
            )
        )
        children = list(child_result.scalars().all())
        current_level = [c.taxonomy_id for c in children]
        all_nodes.extend(children)
        if not children:
            break

    # Deduplicate
    seen = set()
    unique = []
    for n in all_nodes:
        if n.taxonomy_id not in seen:
            seen.add(n.taxonomy_id)
            unique.append(n)
    return unique


async def find_nodes_by_name(
    session: AsyncSession,
    name: str,
    world_anchor: Optional[str] = None,
) -> list[TaxonomyNode]:
    """Case-insensitive partial match on name, optionally filtered by world_anchor."""
    stmt = select(TaxonomyNode).where(
        TaxonomyNode.name.ilike(f"%{name}%")
    )
    if world_anchor:
        stmt = stmt.where(TaxonomyNode.world_anchor == world_anchor)
    result = await session.execute(stmt)
    return list(result.scalars().all())


async def get_world_roots(
    session: AsyncSession,
    world_anchor: str,
) -> list[TaxonomyNode]:
    """Return all level-0 nodes for a given world_anchor (profession/skill/business)."""
    result = await session.execute(
        select(TaxonomyNode).where(
            TaxonomyNode.world_anchor == world_anchor,
            TaxonomyNode.level == 0,
        )
    )
    return list(result.scalars().all())


async def get_children(
    session: AsyncSession,
    parent_id: uuid.UUID,
) -> list[TaxonomyNode]:
    result = await session.execute(
        select(TaxonomyNode).where(TaxonomyNode.parent_id == parent_id)
        .order_by(TaxonomyNode.name)
    )
    return list(result.scalars().all())


# ── Questions lookup ──────────────────────────────────────────────────────────
async def get_question_by_intent(
    session: AsyncSession,
    normalized_intent: str,
) -> Optional[Question]:
    """Look up the canonical question row by its normalized_intent (the dedup key)."""
    result = await session.execute(
        select(Question).where(Question.normalized_intent == normalized_intent)
    )
    return result.scalar_one_or_none()


async def find_questions(
    session: AsyncSession,
    query: str,
    limit: int = 10,
) -> list[Question]:
    """Search questions by text (case-insensitive partial match)."""
    result = await session.execute(
        select(Question)
        .where(Question.question_text.ilike(f"%{query}%"))
        .limit(limit)
    )
    return list(result.scalars().all())


async def get_resources_for_question(
    session: AsyncSession,
    question_id: uuid.UUID,
    trust_states: tuple[str, ...] = ("ai_assessed", "evidence_supported", "verified",
                                     "authoritative_official"),
    limit: int = 20,
) -> list[uuid.UUID]:
    """Return resource_ids linked to a question via supports_question relationship.

    Filtered by trust_states — only servable resources (LD-02 §0).
    """
    from core.models import Resource
    result = await session.execute(
        select(Relationship.subject_id)
        .join(Resource, Resource.resource_id == Relationship.subject_id)
        .where(
            Relationship.subject_type == "resource",
            Relationship.relation == "supports_question",
            Relationship.object_type == "question",
            Relationship.object_id == question_id,
            Resource.trust_state.in_(trust_states),
        )
        .limit(limit)
    )
    return [row[0] for row in result.all()]


async def ensure_question(
    session: AsyncSession,
    question_text: str,
    normalized_intent: str,
    linked_topic_ids: Optional[list[uuid.UUID]] = None,
) -> Question:
    """Get or create a question row by normalized_intent (ED-01 §1.4 dedup rule).

    One question row per intent, no matter how many resources answer it.
    """
    existing = await get_question_by_intent(session, normalized_intent)
    if existing:
        return existing

    question = Question(
        question_text=question_text,
        normalized_intent=normalized_intent,
        linked_topic_ids=linked_topic_ids or [],
    )
    session.add(question)
    await session.flush()
    return question
