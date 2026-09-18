"""
tests/pipeline_e2e/test_ed01_dod.py — ED-01 §5 Definition of Done checks.

These tests verify the hard structural requirements from ED-01 §5:
- All tables exist with correct fields
- resource_id survives URL changes
- access_status and trust_state are independently settable
- user_signals aggregate CANNOT write to resources.trust_state
- review_queue receives items at pipeline failure points

Run with: pytest tests/pipeline_e2e/test_ed01_dod.py -v
Requires DATABASE_URL pointing to a test database with migrations applied.
"""
import pytest
from sqlalchemy import select, update

from core.db import get_session, init_db
from core.models import Resource, Evidence, ReviewQueue, UserSignal
from services.trust.state_machine import advance_trust_state
from services.trust.review_queue import open_review


# ── Setup ─────────────────────────────────────────────────────────────────────
@pytest.fixture(scope="session", autouse=True)
def setup_db():
    init_db()


# ── ED-01 §5 item 1: all tables exist ────────────────────────────────────────
@pytest.mark.asyncio
async def test_core_tables_queryable():
    """All 18 tables from the schema checklist must be queryable."""
    from core.models import (
        Resource, Source, Entity, Topic, Question, Relationship, UserSignal, InformationForm, AuthorityWeight,
        FreshnessPolicy, ReviewQueue, TaxonomyNode, TrainingExample,
        ModelRegistry, CoverageGap, LearningLoopEvent, GlobalExpansionMetric,
    )
    async with get_session() as session:
        for model in [
            Resource, Source, Entity, Topic, Question, Evidence,
            Relationship, UserSignal, InformationForm, AuthorityWeight,
            FreshnessPolicy, ReviewQueue, TaxonomyNode, TrainingExample,
            ModelRegistry, CoverageGap, LearningLoopEvent, GlobalExpansionMetric,
        ]:
            result = await session.execute(select(model).limit(1))
            # Just confirming the query runs — no exception = table exists
            assert result is not None, f"Table {model.__tablename__} not queryable"


# ── ED-01 §5 item 3: resource_id survives URL change ─────────────────────────
@pytest.mark.asyncio
async def test_resource_id_survives_url_change():
    """MUST NOT derive resource identity from canonical_url (Doc 5 §3)."""
    async with get_session() as session:
        resource = Resource(
            type="video",
            title="URL change test resource",
            trust_state="discovered",
            pipeline_status="intake",
            canonical_url="https://example.com/original",
        )
        session.add(resource)
        await session.flush()
        original_id = resource.resource_id

        # Change the URL — resource_id must not change
        await session.execute(
            update(Resource)
            .where(Resource.resource_id == original_id)
            .values(canonical_url="https://example.com/new-location")
        )

        result = await session.execute(
            select(Resource).where(Resource.resource_id == original_id)
        )
        fetched = result.scalar_one()
        assert fetched.resource_id == original_id
        assert fetched.canonical_url == "https://example.com/new-location"


# ── ED-01 §5 item 4: access_status and trust_state are independent ───────────
@pytest.mark.asyncio
async def test_access_status_independent_of_trust_state():
    """access_status=restricted must be settable without changing trust_state."""
    async with get_session() as session:
        resource = Resource(
            type="written",
            title="Access independence test",
            trust_state="ai_assessed",
            pipeline_status="indexed",
            access_status="public",
        )
        session.add(resource)
        await session.flush()

        # Restrict access — trust_state must remain ai_assessed
        await session.execute(
            update(Resource)
            .where(Resource.resource_id == resource.resource_id)
            .values(access_status="restricted")
        )

        result = await session.execute(
            select(Resource).where(Resource.resource_id == resource.resource_id)
        )
        fetched = result.scalar_one()
        assert fetched.access_status == "restricted"
        assert fetched.trust_state == "ai_assessed", (
            "Changing access_status must not change trust_state"
        )


# ── ED-01 §5 item 7: user_signals aggregate cannot write to trust_state ───────
def test_user_signals_have_no_trust_state_column():
    """The UserSignal model must have no trust_state or trust_dimensions column.

    This is the structural enforcement of Doc 9 §9: engagement signals feed
    ranking only, never trust logic.
    """
    signal_columns = {c.key for c in UserSignal.__table__.columns}
    assert "trust_state" not in signal_columns
    assert "trust_dimensions" not in signal_columns


# ── ED-04 §11: invalid trust transitions are rejected ─────────────────────────
@pytest.mark.asyncio
async def test_direct_jump_to_verified_is_rejected():
    """discovered → verified in one jump MUST be rejected (ED-04 §11)."""
    async with get_session() as session:
        resource = Resource(
            type="audio",
            title="Trust jump test",
            trust_state="discovered",
            pipeline_status="intake",
        )
        session.add(resource)
        await session.flush()

        result = await advance_trust_state(
            session,
            resource_id=resource.resource_id,
            target_state="verified",
        )
        assert result.success is False, (
            "Direct jump from discovered to verified must be rejected"
        )
        assert "invalid transition" in result.error.lower()


# ── ED-04 §9: review_queue receives items ─────────────────────────────────────
@pytest.mark.asyncio
async def test_review_queue_open_and_query():
    """A review_queue row can be opened and queried."""
    async with get_session() as session:
        resource = Resource(
            type="structured_interactive",
            title="Review queue test resource",
            trust_state="ai_assessed",
            pipeline_status="indexed",
        )
        session.add(resource)
        await session.flush()

        review = await open_review(
            session,
            subject_type="resource",
            subject_id=resource.resource_id,
            reason_code="sensitive_domain",
        )

        result = await session.execute(
            select(ReviewQueue).where(ReviewQueue.review_id == review.review_id)
        )
        fetched = result.scalar_one()
        assert fetched.status == "open"
        assert fetched.reason_code == "sensitive_domain"
        assert fetched.subject_id == resource.resource_id
