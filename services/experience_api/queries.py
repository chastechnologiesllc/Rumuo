"""
services/experience_api/queries.py — DB queries for the experience API.

Implements ED-07 §2: exact-match results surface before ranked results.
An "exact match" is defined as a resource whose title or description contains
the query string as a whole word (to_tsvector / plainto_tsquery).
"""
from typing import Optional, Tuple
from sqlalchemy import and_, or_, select, text
from sqlalchemy.ext.asyncio import AsyncSession

from core.models import Resource, Source
from services.experience_api.schemas import ResourceRecord


async def fetch_resources(
    *,
    session: AsyncSession,
    form_id: Optional[str],
    subtype: Optional[str],
    query: Optional[str],
    country: Optional[str],
    language: Optional[str],
    trust_states: Tuple[str, ...],
    limit: int,
    offset: int,
) -> Tuple[list[ResourceRecord], int]:
    """Fetch resources for the experience API, exact matches first.

    Returns (records, exact_count) where exact_count is the number of
    exact-match results at the front of the list.
    """
    # Build base filter conditions
    conditions = [Resource.trust_state.in_(trust_states)]

    if form_id:
        conditions.append(Resource.type == form_id)

    if subtype:
        conditions.append(Resource.subtype == subtype)

    # ── Exact-match query (ED-07 §2) ─────────────────────────────────────
    exact_records: list[ResourceRecord] = []
    if query:
        exact_stmt = (
            select(Resource, Source.name.label("source_name"))
            .outerjoin(Source, Resource.source_id == Source.source_id)
            .where(
                and_(
                    *conditions,
                    or_(
                        Resource.title.ilike(f"%{query}%"),
                        Resource.description.ilike(f"%{query}%"),
                    ),
                )
            )
            .order_by(Resource.trust_state.asc(), Resource.updated_at.desc())
            .limit(limit)
            .offset(offset)
        )
        result = await session.execute(exact_stmt)
        for row in result.all():
            resource, source_name = row
            exact_records.append(_to_record(resource, source_name))

    # ── Ranked / browsed results (fallback when no query, or to pad) ──────
    ranked_records: list[ResourceRecord] = []
    exact_ids = {r.id for r in exact_records}
    remaining = limit - len(exact_records)

    if remaining > 0:
        browse_stmt = (
            select(Resource, Source.name.label("source_name"))
            .outerjoin(Source, Resource.source_id == Source.source_id)
            .where(and_(*conditions))
            .order_by(Resource.trust_state.asc(), Resource.updated_at.desc())
            .limit(remaining + len(exact_ids))   # over-fetch to account for dedup
            .offset(offset if not query else 0)
        )
        result = await session.execute(browse_stmt)
        for row in result.all():
            resource, source_name = row
            rid = str(resource.resource_id)
            if rid not in exact_ids:
                ranked_records.append(_to_record(resource, source_name))
                if len(ranked_records) >= remaining:
                    break

    all_records = exact_records + ranked_records
    return all_records, len(exact_records)


def _to_record(resource: Resource, source_name: Optional[str]) -> ResourceRecord:
    """Map a Resource ORM object to the API response shape."""
    provenance_url = None
    if resource.provenance and isinstance(resource.provenance, dict):
        provenance_url = resource.provenance.get("url")

    context = resource.context or {}
    region = context.get("geography") or "global"

    return ResourceRecord(
        id=str(resource.resource_id),
        title=resource.title,
        summary=resource.description,
        url=resource.canonical_url,
        content_type=resource.subtype or "resource",
        publisher=source_name or "Unknown publisher",
        region=region,
        license=resource.license,
        trust_state=resource.trust_state,
        provenance_url=provenance_url,
        verified_at=(
            resource.freshness_last_checked.isoformat()
            if resource.freshness_last_checked
            else None
        ),
        trust_dimensions=resource.trust_dimensions,
        field_confidence=resource.field_confidence,
        type=resource.type,
    )
