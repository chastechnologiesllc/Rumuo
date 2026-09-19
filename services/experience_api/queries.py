"""
Database queries for the public experience API.

The live Supabase project exposes the compact ``resources`` registry used by
Flutter: id, title, summary, url, content_type, subcategory_id, publisher,
region, license, trust_state, provenance_url, and verification timestamps.
This module deliberately uses SQLAlchemy text queries so the API remains
compatible with that production schema while the broader ingestion ORM is
migrated independently.
"""
from typing import Optional, Tuple

from sqlalchemy import text
from sqlalchemy.ext.asyncio import AsyncSession

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
    """Fetch servable resources from the live Supabase resource registry.

    Country filtering keeps globally relevant material visible to every
    country while including records explicitly tagged for the requested
    country. The current compact schema has no language column, so language is
    accepted for API compatibility and intentionally does not filter results.
    """
    trust_params = []
    params: dict[str, object] = {"limit": limit, "offset": offset}
    for index, state in enumerate(trust_states):
        key = f"trust_state_{index}"
        trust_params.append(f":{key}")
        params[key] = state
    conditions = [
        "r.deleted_at IS NULL",
        f"r.trust_state IN ({', '.join(trust_params)})",
    ]

    if form_id:
        # The compact production schema stores this as content_type.
        conditions.append("r.content_type = :form_id")
        params["form_id"] = form_id
    if subtype:
        # For compact records, subcategory_id is the stable Flutter-facing
        # selector. Accept the mapped subtype as a fallback for future rows.
        conditions.append("(r.subcategory_id = :subcategory OR r.content_type = :subtype)")
        params["subcategory"] = _subcategory_for(form_id, subtype)
        params["subtype"] = subtype
    if country:
        conditions.append("(lower(coalesce(r.region, 'global')) IN ('global', lower(:country)) )")
        params["country"] = country

    where_sql = " AND ".join(conditions)
    search_sql = ""
    if query and query.strip():
        search_sql = " AND (r.title ILIKE :query OR coalesce(r.summary, '') ILIKE :query)"
        params["query"] = f"%{query.strip()}%"

    exact_sql = f"""
        SELECT r.id, r.title, r.summary, r.url, r.content_type,
               r.publisher, r.region, r.license, r.trust_state,
               r.provenance_url, r.verified_at, r.updated_at,
               NULL::jsonb AS trust_dimensions,
               NULL::jsonb AS field_confidence
        FROM public.resources AS r
        WHERE {where_sql}{search_sql}
        ORDER BY r.trust_state ASC, r.updated_at DESC NULLS LAST
        LIMIT :limit OFFSET :offset
    """

    exact_rows = []
    if query and query.strip():
        result = await session.execute(text(exact_sql), params)
        exact_rows = result.mappings().all()

    exact_ids = {str(row["id"]) for row in exact_rows}
    remaining = limit - len(exact_rows)
    ranked_rows = []
    if remaining > 0:
        ranked_params = dict(params)
        ranked_params["limit"] = remaining + len(exact_ids)
        ranked_params["offset"] = 0 if query and query.strip() else offset
        ranked_sql = f"""
            SELECT r.id, r.title, r.summary, r.url, r.content_type,
                   r.publisher, r.region, r.license, r.trust_state,
                   r.provenance_url, r.verified_at, r.updated_at,
                   NULL::jsonb AS trust_dimensions,
                   NULL::jsonb AS field_confidence
            FROM public.resources AS r
            WHERE {where_sql}
            ORDER BY r.trust_state ASC, r.updated_at DESC NULLS LAST
            LIMIT :limit OFFSET :offset
        """
        result = await session.execute(text(ranked_sql), ranked_params)
        for row in result.mappings().all():
            if str(row["id"]) not in exact_ids:
                ranked_rows.append(row)
                if len(ranked_rows) >= remaining:
                    break

    return (
        [_to_record(row) for row in [*exact_rows, *ranked_rows]],
        len(exact_rows),
    )


def _subcategory_for(form_id: Optional[str], subtype: str) -> str:
    """Return the Flutter slug used by the compact resources table."""
    if form_id == "video":
        return f"videos_{subtype}s" if subtype != "long_form" else "videos_long_form"
    if form_id == "shorts":
        return f"shorts_{subtype}s"
    if form_id == "audio":
        return f"audio_{subtype}s"
    if form_id == "written":
        return f"written_{subtype}s"
    if form_id == "structured_interactive":
        return f"structured_{subtype}s"
    return subtype


def _to_record(row) -> ResourceRecord:
    verified_at = row["verified_at"]
    return ResourceRecord(
        id=str(row["id"]),
        title=row["title"],
        summary=row["summary"],
        url=row["url"],
        content_type=row["content_type"] or "resource",
        publisher=row["publisher"] or "Unknown publisher",
        region=row["region"] or "global",
        license=row["license"],
        trust_state=row["trust_state"] or "discovered",
        provenance_url=row["provenance_url"],
        verified_at=verified_at.isoformat() if hasattr(verified_at, "isoformat") else verified_at,
        trust_dimensions=row["trust_dimensions"],
        field_confidence=row["field_confidence"],
        type=row["content_type"],
    )
