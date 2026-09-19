"""
services/experience_api/main.py — the public-facing API the Flutter app calls.

Owning directive: ED-07.
Per LD-03 §3/§8: this service only writes to the tables ED-07 defines.
Other services do not query those tables directly — they call this service.

Endpoint:
  GET /api/resources?subcategory=<slug>&q=<query>&country=NG&language=en

Returned resources:
  - Filtered to trust_state IN (ai_assessed, evidence_supported, verified,
    authoritative_official) — all fully valid resting states for Medicine.
  - NOT filtered to verified-only: LD-02 §0 is explicit that ai_assessed is
    the default resting state for Medicine and must not block serving.
  - Ordered: exact-match results first, then ranked (ED-07 §2).
  - trust_state and provenance exposed so the Flutter client can display
    appropriate disclosure per ED-07 §4.
"""
from contextlib import asynccontextmanager
from typing import Optional

from fastapi import FastAPI, Query
from fastapi.responses import JSONResponse
from fastapi.middleware.cors import CORSMiddleware
from sqlalchemy import text

from core.db import get_session, init_db
from services.experience_api.queries import fetch_resources
from services.experience_api.schemas import ResourcesResponse
from services.experience_api.subcategory_map import resolve_subcategory


# ── Subcategory → (type, subtype) mapping ────────────────────────────────────
# Maps the Flutter app's subcategory slugs (from SubcategoryData in Dart)
# to (information_form.form_id, optional subtype filter).
# This mapping is the bridge between the existing Flutter client and the
# new backend. Do not hard-code form_id values here — import from the map.


# ── Lifespan ──────────────────────────────────────────────────────────────────
@asynccontextmanager
async def lifespan(_app: FastAPI):
    init_db()
    yield


app = FastAPI(
    title="Rumuo Experience API",
    version="0.1.0",
    description="Public-facing resource discovery API (ED-07).",
    lifespan=lifespan,
)

app.add_middleware(
    CORSMiddleware,
    allow_origins=["*"],
    allow_methods=["GET", "OPTIONS"],
    allow_headers=["Content-Type"],
)


# ── Servable trust states (LD-02 §0) ─────────────────────────────────────────
# ai_assessed is a valid, fully automated resting state for Medicine.
# MUST NOT block serving on human review to reach it.
SERVABLE_TRUST_STATES = (
    "ai_assessed",
    "evidence_supported",
    "verified",
    "authoritative_official",
)


# ── Routes ────────────────────────────────────────────────────────────────────
@app.get("/api/resources", response_model=ResourcesResponse)
async def get_resources(
    subcategory: Optional[str] = Query(None, description="Flutter subcategory slug"),
    q: Optional[str] = Query(None, description="Search query"),
    country: Optional[str] = Query("NG"),
    language: Optional[str] = Query("en"),
    limit: int = Query(20, ge=1, le=100),
    offset: int = Query(0, ge=0),
):
    """Serve resources for the Flutter experience layer.

    ED-07 §2: exact-match results surface first (meta.exact_first=True),
    then ranked results. The client renders them in this order.

    ED-07 §4: trust_state and provenance_url are returned on every record
    so the Flutter UI can show appropriate trust disclosure on demand.
    """
    form_id, subtype = resolve_subcategory(subcategory)

    async with get_session() as session:
        records, exact_count = await fetch_resources(
            session=session,
            form_id=form_id,
            subtype=subtype,
            query=q,
            country=country,
            language=language,
            trust_states=SERVABLE_TRUST_STATES,
            limit=limit,
            offset=offset,
        )

    return ResourcesResponse(
        data=records,
        meta={
            "exact_first": exact_count > 0,
            "exact_count": exact_count,
            "total_returned": len(records),
            "subcategory": subcategory,
            "query": q,
            "trust_filter": list(SERVABLE_TRUST_STATES),
        },
    )


@app.get("/health")
async def health():
    return {"status": "ok"}


@app.get("/health/db")
async def database_health():
    """Safely report whether Vercel can open a Postgres session.

    This intentionally returns only the exception class and a short message;
    credentials and the DATABASE_URL are never included in the response.
    """
    try:
        async with get_session() as session:
            await session.execute(text("select 1"))
        return {"status": "ok", "database": "reachable"}
    except Exception as exc:
        return JSONResponse(
            status_code=503,
            content={
                "status": "error",
                "database": "unreachable",
                "error_type": type(exc).__name__,
                "detail": str(exc)[:300],
            },
        )
