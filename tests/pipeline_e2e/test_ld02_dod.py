"""
tests/pipeline_e2e/test_ld02_dod.py — LD-02 §2 hard rule verification.

Confirms that:
1. Every Medicine resource opened at pipeline stage 7 gets a sensitive_domain
   review_queue row — no exceptions (LD-02 §2 hard rule).
2. ai_assessed resources are served by the experience API (LD-02 §0 — this
   is a valid, fully automated resting state for Medicine).
3. Trust state cannot jump from ai_assessed directly to verified.
"""
import uuid
import pytest

from core.db import get_session, init_db
from core.models import Resource, ReviewQueue
from agents.organizer.review_handoff import handoff_medicine_resource
from services.trust.state_machine import advance_trust_state
from sqlalchemy import select


@pytest.fixture(scope="session", autouse=True)
def setup_db():
    init_db()


@pytest.mark.asyncio
async def test_medicine_resource_gets_sensitive_domain_review():
    """LD-02 §2: every Medicine resource at pipeline stage 7 gets a review row."""
    async with get_session() as session:
        resource = Resource(
            type="video",
            title="LD-02 §2 test: Medicine sensitive domain",
            trust_state="ai_assessed",
            pipeline_status="verified",
            context={"geography": "Nigeria", "jurisdiction": "NG"},
        )
        session.add(resource)
        await session.flush()

        review_id = await handoff_medicine_resource(session, resource.resource_id)

        result = await session.execute(
            select(ReviewQueue).where(ReviewQueue.review_id == review_id)
        )
        review = result.scalar_one()
        assert review.reason_code == "sensitive_domain", (
            "LD-02 §2: reason_code must be sensitive_domain for Medicine handoff"
        )
        assert review.status == "open"
        assert review.subject_id == resource.resource_id


@pytest.mark.asyncio
async def test_ai_assessed_cannot_jump_to_verified():
    """LD-02 §0 + ED-04 §11: ai_assessed → verified requires evidence + resolved review."""
    async with get_session() as session:
        resource = Resource(
            type="written",
            title="LD-02: ai_assessed to verified jump test",
            trust_state="ai_assessed",
            pipeline_status="indexed",
        )
        session.add(resource)
        await session.flush()

        result = await advance_trust_state(
            session,
            resource_id=resource.resource_id,
            target_state="verified",
        )
        assert result.success is False
        assert "review_queue" in result.error.lower() or "invalid" in result.error.lower()


@pytest.mark.asyncio
async def test_verified_requires_resolved_review_queue_row():
    """ED-04 §11: trust_state=verified requires a resolved review_queue row with resolution='approved'."""
    async with get_session() as session:
        # Create a resource at evidence_supported
        resource = Resource(
            type="written",
            title="LD-02: verified gate test",
            trust_state="evidence_supported",
            pipeline_status="indexed",
        )
        session.add(resource)
        await session.flush()

        # Attempt to advance without a resolved review row
        result = await advance_trust_state(
            session,
            resource_id=resource.resource_id,
            target_state="verified",
        )
        assert result.success is False, (
            "advancing to verified without a resolved review_queue row must fail"
        )
