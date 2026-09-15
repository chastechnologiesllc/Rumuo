"""
services/trust/review_console/main.py — Reviewer's queue-working tool.

FastAPI app served separately from experience_api (different port / process).
Authenticates via REVIEWER_TOKEN env var — replace with proper auth before
going to production with multiple reviewers.

Exposes:
  GET  /queue                     — open reviews (filterable by reason_code)
  GET  /queue/{review_id}         — single review + subject record preview
  POST /queue/{review_id}/assign  — claim a review
  POST /queue/{review_id}/resolve — submit a resolution
"""
import os
import uuid
from contextlib import asynccontextmanager
from typing import Optional

from fastapi import Depends, FastAPI, Header, HTTPException, status
from fastapi.middleware.cors import CORSMiddleware
from pydantic import BaseModel
from sqlalchemy import select

from core.db import get_session, init_db
from core.models import Resource, ReviewQueue
from services.trust.review_queue import (
    assign_review,
    get_open_reviews,
    get_review,
    resolve_review,
)
from services.trust.state_machine import advance_trust_state


# ── Lifespan ──────────────────────────────────────────────────────────────────
@asynccontextmanager
async def lifespan(_app: FastAPI):
    init_db()
    yield


app = FastAPI(
    title="Rumuo Review Console",
    version="0.1.0",
    description="Internal tool for working the review_queue (ED-04 §9).",
    lifespan=lifespan,
)

app.add_middleware(
    CORSMiddleware,
    allow_origins=["*"],
    allow_methods=["GET", "POST"],
    allow_headers=["*"],
)


# ── Auth ──────────────────────────────────────────────────────────────────────
def require_reviewer(x_reviewer_token: str = Header(...)):
    expected = os.environ.get("REVIEWER_TOKEN", "")
    if not expected:
        raise HTTPException(
            status_code=status.HTTP_500_INTERNAL_SERVER_ERROR,
            detail="REVIEWER_TOKEN not configured — cannot authenticate.",
        )
    if x_reviewer_token != expected:
        raise HTTPException(
            status_code=status.HTTP_401_UNAUTHORIZED,
            detail="Invalid reviewer token.",
        )
    return x_reviewer_token


# ── Schemas ───────────────────────────────────────────────────────────────────
class ReviewRow(BaseModel):
    review_id: uuid.UUID
    subject_type: str
    subject_id: uuid.UUID
    reason_code: str
    status: str
    assigned_to: Optional[uuid.UUID]
    resolution: Optional[str]
    created_at: str
    resolved_at: Optional[str]

    class Config:
        from_attributes = True


class AssignPayload(BaseModel):
    reviewer_id: uuid.UUID


class ResolvePayload(BaseModel):
    resolution: str
    advance_trust_to: Optional[str] = None   # e.g. 'verified' — optional


# ── Routes ────────────────────────────────────────────────────────────────────
@app.get("/queue", response_model=list[ReviewRow])
async def list_open_reviews(
    reason_code: Optional[str] = None,
    limit: int = 50,
    offset: int = 0,
    _auth=Depends(require_reviewer),
):
    """Return open review rows, newest-first. Filter by reason_code if supplied."""
    async with get_session() as session:
        rows = await get_open_reviews(
            session, reason_code=reason_code, limit=limit, offset=offset
        )
        return [
            ReviewRow(
                review_id=r.review_id,
                subject_type=r.subject_type,
                subject_id=r.subject_id,
                reason_code=r.reason_code,
                status=r.status,
                assigned_to=r.assigned_to,
                resolution=r.resolution,
                created_at=r.created_at.isoformat(),
                resolved_at=r.resolved_at.isoformat() if r.resolved_at else None,
            )
            for r in rows
        ]


@app.get("/queue/{review_id}")
async def get_review_detail(
    review_id: uuid.UUID,
    _auth=Depends(require_reviewer),
):
    """Return a single review row plus a preview of the subject resource."""
    async with get_session() as session:
        row = await get_review(session, review_id)
        if row is None:
            raise HTTPException(status_code=404, detail="Review not found")

        subject_preview = None
        if row.subject_type == "resource":
            res = await session.execute(
                select(Resource).where(Resource.resource_id == row.subject_id)
            )
            r = res.scalar_one_or_none()
            if r:
                subject_preview = {
                    "resource_id": str(r.resource_id),
                    "title": r.title,
                    "type": r.type,
                    "trust_state": r.trust_state,
                    "pipeline_status": r.pipeline_status,
                    "canonical_url": r.canonical_url,
                    "description": r.description,
                    "trust_dimensions": r.trust_dimensions,
                    "field_confidence": r.field_confidence,
                }

        return {
            "review": ReviewRow(
                review_id=row.review_id,
                subject_type=row.subject_type,
                subject_id=row.subject_id,
                reason_code=row.reason_code,
                status=row.status,
                assigned_to=row.assigned_to,
                resolution=row.resolution,
                created_at=row.created_at.isoformat(),
                resolved_at=row.resolved_at.isoformat() if row.resolved_at else None,
            ),
            "subject_preview": subject_preview,
        }


@app.post("/queue/{review_id}/assign")
async def claim_review(
    review_id: uuid.UUID,
    payload: AssignPayload,
    _auth=Depends(require_reviewer),
):
    async with get_session() as session:
        row = await assign_review(session, review_id, payload.reviewer_id)
        if row is None:
            raise HTTPException(status_code=404, detail="Review not found")
        return {"status": "assigned", "review_id": str(review_id)}


@app.post("/queue/{review_id}/resolve")
async def submit_resolution(
    review_id: uuid.UUID,
    payload: ResolvePayload,
    _auth=Depends(require_reviewer),
):
    """Resolve a review. Optionally advance the subject resource's trust_state.

    If advance_trust_to is supplied, calls state_machine.advance_trust_state()
    after resolving the review. The state machine will reject invalid transitions.

    MUST NOT: supply advance_trust_to='verified' unless resolution='approved'.
    The state machine enforces this independently but the console surfaces it.
    """
    async with get_session() as session:
        row = await resolve_review(session, review_id, payload.resolution)
        if row is None:
            raise HTTPException(status_code=404, detail="Review not found")

        trust_result = None
        if payload.advance_trust_to and row.subject_type == "resource":
            trust_result = await advance_trust_state(
                session,
                resource_id=row.subject_id,
                target_state=payload.advance_trust_to,
                actor="human_reviewer",
                evidence=f"review_queue/{review_id} resolved: {payload.resolution}",
            )

        return {
            "status": "resolved",
            "review_id": str(review_id),
            "resolution": payload.resolution,
            "trust_advance": (
                {
                    "success": trust_result.success,
                    "from": trust_result.from_state,
                    "to": trust_result.to_state,
                    "error": trust_result.error,
                }
                if trust_result
                else None
            ),
        }
