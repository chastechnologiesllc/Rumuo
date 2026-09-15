"""
services/trust/review_queue.py — review_queue CRUD.

LD-02 §2 hard rule: every Medicine resource MUST get a sensitive_domain
review_queue row opened at pipeline stage 7. No exceptions.
"This one's obviously fine" is not a valid reason to skip it.
"""
import uuid
from datetime import datetime
from typing import Optional

from sqlalchemy import select, update
from sqlalchemy.ext.asyncio import AsyncSession

from core.models import ReviewQueue


# ---------------------------------------------------------------------------
# Open a review row
# ---------------------------------------------------------------------------
async def open_review(
    session: AsyncSession,
    *,
    subject_type: str,
    subject_id: uuid.UUID,
    reason_code: str,
    assigned_to: Optional[uuid.UUID] = None,
) -> ReviewQueue:
    """Create an open review_queue row.

    Called by:
    - pipeline stage 7 (for every Medicine resource — sensitive_domain)
    - pipeline stages 2, 3, 6, 8 on failure (ED-01 §3 failure conditions)
    - ED-04 §4 (user report/comment signal alleging factual error → user_flagged)
    - ED-04 §5 (contradiction detected between evidence_supported/verified sources)
    """
    row = ReviewQueue(
        subject_type=subject_type,
        subject_id=subject_id,
        reason_code=reason_code,
        status="open",
        assigned_to=assigned_to,
        created_at=datetime.utcnow(),
    )
    session.add(row)
    await session.flush()   # get the PK without committing
    return row


async def open_sensitive_domain_review(
    session: AsyncSession,
    resource_id: uuid.UUID,
) -> ReviewQueue:
    """Shorthand for the Medicine pipeline stage-7 mandatory opener.

    LD-02 §2: "Every Medicine resource gets a sensitive_domain review_queue
    row opened at pipeline stage 7 — no exceptions."
    """
    return await open_review(
        session=session,
        subject_type="resource",
        subject_id=resource_id,
        reason_code="sensitive_domain",
    )


# ---------------------------------------------------------------------------
# Fetch
# ---------------------------------------------------------------------------
async def get_open_reviews(
    session: AsyncSession,
    *,
    reason_code: Optional[str] = None,
    limit: int = 50,
    offset: int = 0,
) -> list[ReviewQueue]:
    """Return open (and optionally reason-filtered) review rows."""
    stmt = (
        select(ReviewQueue)
        .where(ReviewQueue.status == "open")
        .order_by(ReviewQueue.created_at.asc())
        .limit(limit)
        .offset(offset)
    )
    if reason_code:
        stmt = stmt.where(ReviewQueue.reason_code == reason_code)
    result = await session.execute(stmt)
    return list(result.scalars().all())


async def get_review(
    session: AsyncSession, review_id: uuid.UUID
) -> Optional[ReviewQueue]:
    result = await session.execute(
        select(ReviewQueue).where(ReviewQueue.review_id == review_id)
    )
    return result.scalar_one_or_none()


# ---------------------------------------------------------------------------
# Assign
# ---------------------------------------------------------------------------
async def assign_review(
    session: AsyncSession,
    review_id: uuid.UUID,
    reviewer_id: uuid.UUID,
) -> Optional[ReviewQueue]:
    """Move a review to in_review and assign it to a reviewer."""
    row = await get_review(session, review_id)
    if row is None:
        return None
    if row.status != "open":
        raise ValueError(
            f"Review {review_id} is {row.status!r}, not 'open' — cannot assign."
        )
    await session.execute(
        update(ReviewQueue)
        .where(ReviewQueue.review_id == review_id)
        .values(status="in_review", assigned_to=reviewer_id)
    )
    return row


# ---------------------------------------------------------------------------
# Resolve
# ---------------------------------------------------------------------------
async def resolve_review(
    session: AsyncSession,
    review_id: uuid.UUID,
    resolution: str,
) -> Optional[ReviewQueue]:
    """Close a review row with a resolution string.

    The resolution string is plain text from the reviewer.
    Only resolution='approved' unlocks trust_state=verified (ED-04 §11) —
    the state_machine.py checks for this; this function just stores the string.

    MUST NOT: auto-edit resources or relationships as a side effect.
    After this function, the caller is responsible for calling
    state_machine.advance_trust_state() if advancing to verified.
    """
    row = await get_review(session, review_id)
    if row is None:
        return None
    if row.status not in ("open", "in_review"):
        raise ValueError(
            f"Review {review_id} is already {row.status!r} — cannot resolve again."
        )
    await session.execute(
        update(ReviewQueue)
        .where(ReviewQueue.review_id == review_id)
        .values(
            status="resolved",
            resolution=resolution,
            resolved_at=datetime.utcnow(),
        )
    )
    return row
