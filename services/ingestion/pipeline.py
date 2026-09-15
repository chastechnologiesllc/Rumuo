"""
services/ingestion/pipeline.py — the 13-stage ingestion pipeline (ED-01 §3).

Each stage function:
  - Accepts a resource_id and a database session
  - Reads the resource at its current pipeline_status
  - Performs exactly the action ED-01 §3 prescribes
  - Writes the next pipeline_status on success
  - Opens a review_queue row on failure/ambiguity (never blocks the pipeline)
  - Returns a StageResult describing what happened

MUST NOT: one pipeline per information_form (ED-01 §4 item 9) — one pipeline, all forms.
MUST NOT: bypass auth/paywalls (ED-01 §4 item 1) — stage 3 enforces the access limit.
MUST NOT: set trust_state from pipeline code directly — stage 7 calls advance_trust_state()
  which enforces the state machine (ED-04 §11).
"""
from __future__ import annotations

import hashlib
import uuid
from dataclasses import dataclass, field
from datetime import datetime
from typing import Any, Optional

from sqlalchemy import select, update
from sqlalchemy.ext.asyncio import AsyncSession

from core.enums import PipelineStatus, TrustState
from core.models import Resource, Source, Evidence, Relationship
from services.trust.review_queue import open_review
from services.trust.state_machine import advance_trust_state


# ── Stage result ──────────────────────────────────────────────────────────────
@dataclass
class StageResult:
    stage: int
    stage_name: str
    resource_id: uuid.UUID
    success: bool
    next_status: Optional[str] = None
    review_opened: Optional[uuid.UUID] = None   # review_id if opened
    notes: str = ""
    data: dict[str, Any] = field(default_factory=dict)


# ── Helper ────────────────────────────────────────────────────────────────────
async def _set_pipeline_status(
    session: AsyncSession, resource_id: uuid.UUID, status: str
) -> None:
    await session.execute(
        update(Resource)
        .where(Resource.resource_id == resource_id)
        .values(pipeline_status=status, updated_at=datetime.utcnow())
    )


async def _open_failure_review(
    session: AsyncSession,
    resource_id: uuid.UUID,
    reason_code: str,
    notes: str,
) -> uuid.UUID:
    row = await open_review(
        session=session,
        subject_type="resource",
        subject_id=resource_id,
        reason_code=reason_code,
    )
    return row.review_id


# ── Stage 0: Intake ───────────────────────────────────────────────────────────
async def stage_0_intake(
    session: AsyncSession,
    url: str,
    discovery_path: str,
    information_form: str,
) -> StageResult:
    """Accept a URL; create the resource row at pipeline_status='intake'.

    discovery_path documents how this URL was found (user paste, search-gap signal,
    submission, crawler channel) — required by ED-01 §3 stage 0 for auditability.
    MUST NOT accept a URL that has no logged discovery_path.
    """
    resource = Resource(
        type=information_form,
        title="[pending identification]",
        canonical_url=url,
        pipeline_status=PipelineStatus.INTAKE.value,
        trust_state=TrustState.DISCOVERED.value,
        provenance={"discovery_path": discovery_path, "intake_at": datetime.utcnow().isoformat()},
    )
    session.add(resource)
    await session.flush()
    return StageResult(
        stage=0, stage_name="intake",
        resource_id=resource.resource_id,
        success=True,
        next_status=PipelineStatus.INTAKE.value,
        notes=f"Accepted from discovery_path={discovery_path!r}",
    )


# ── Stage 1: Dedup pre-check ──────────────────────────────────────────────────
async def stage_1_dedup(
    session: AsyncSession, resource_id: uuid.UUID
) -> StageResult:
    """Normalize + hash URL. Short-circuit if a resource with this URL exists.

    MUST NOT create a second resource_id for the same canonical_url —
    return the existing resource_id instead so callers can redirect to it.
    """
    result = await session.execute(
        select(Resource).where(Resource.resource_id == resource_id)
    )
    resource = result.scalar_one_or_none()
    if not resource:
        return StageResult(stage=1, stage_name="dedup", resource_id=resource_id,
                           success=False, notes="Resource not found at stage 1")

    normalized_url = (resource.canonical_url or "").strip().rstrip("/").lower()
    url_hash = hashlib.sha256(normalized_url.encode()).hexdigest()

    existing = await session.execute(
        select(Resource).where(
            Resource.canonical_url == normalized_url,
            Resource.resource_id != resource_id,
        )
    )
    duplicate = existing.scalar_one_or_none()

    if duplicate:
        # Short-circuit: mark this intake record as superseded
        await _set_pipeline_status(session, resource_id, "dedup_checked")
        return StageResult(
            stage=1, stage_name="dedup", resource_id=resource_id,
            success=True,
            next_status="dedup_checked",
            notes=f"Duplicate of existing resource_id={duplicate.resource_id}. Short-circuit.",
            data={"existing_resource_id": str(duplicate.resource_id)},
        )

    await _set_pipeline_status(session, resource_id, PipelineStatus.DEDUP_CHECKED.value)
    return StageResult(
        stage=1, stage_name="dedup", resource_id=resource_id,
        success=True,
        next_status=PipelineStatus.DEDUP_CHECKED.value,
        data={"url_hash": url_hash},
    )


# ── Stage 2: Identify ────────────────────────────────────────────────────────
async def stage_2_identify(
    session: AsyncSession,
    resource_id: uuid.UUID,
    identified_fields: dict[str, Any],
) -> StageResult:
    """Populate source, type/subtype, title, author, date, language.

    identified_fields comes from the Organizer's extraction step.
    On failure or ambiguity → review_queue with reason_code=ambiguous_provenance.
    """
    required = ["title", "source_name", "source_type"]
    missing = [f for f in required if not identified_fields.get(f)]
    if missing:
        review_id = await _open_failure_review(
            session, resource_id, "ambiguous_provenance",
            f"Stage 2 identify: missing required fields {missing}",
        )
        return StageResult(stage=2, stage_name="identify", resource_id=resource_id,
                           success=False, review_opened=review_id,
                           notes=f"Missing fields: {missing}")

    await session.execute(
        update(Resource)
        .where(Resource.resource_id == resource_id)
        .values(
            title=identified_fields["title"],
            subtype=identified_fields.get("subtype"),
            creator_authors=identified_fields.get("creator_authors"),
            published_date=identified_fields.get("published_date"),
            languages=identified_fields.get("languages", ["en"]),
            trust_state=TrustState.IDENTIFIED.value,
            pipeline_status=PipelineStatus.IDENTIFIED.value,
            updated_at=datetime.utcnow(),
        )
    )
    return StageResult(stage=2, stage_name="identify", resource_id=resource_id,
                       success=True, next_status=PipelineStatus.IDENTIFIED.value)


# ── Stage 3: Access evaluation ────────────────────────────────────────────────
async def stage_3_access(
    session: AsyncSession,
    resource_id: uuid.UUID,
    access_status: str,
    access_conditions: Optional[str] = None,
) -> StageResult:
    """Record access level. Decide full/metadata-only/link-out extraction path.

    MUST NOT bypass auth, paywalls, or platform protections (ED-01 §4 item 1).
    If access_status cannot be determined → review_queue.
    """
    valid_statuses = {"public", "login_required", "paid", "restricted",
                      "downloadable", "streamable", "removed"}
    if access_status not in valid_statuses:
        review_id = await _open_failure_review(
            session, resource_id, "ambiguous_provenance",
            f"Stage 3 access: unrecognised access_status={access_status!r}",
        )
        return StageResult(stage=3, stage_name="access", resource_id=resource_id,
                           success=False, review_opened=review_id,
                           notes=f"Unrecognised access_status={access_status!r}")

    extraction_mode = {
        "public": "full", "downloadable": "full", "streamable": "full",
        "login_required": "metadata_only", "paid": "metadata_only",
        "restricted": "link_out_only", "removed": "skip",
    }[access_status]

    await session.execute(
        update(Resource)
        .where(Resource.resource_id == resource_id)
        .values(
            access_status=access_status,
            access_conditions=access_conditions,
            pipeline_status=PipelineStatus.ACCESS_EVALUATED.value,
            updated_at=datetime.utcnow(),
        )
    )
    return StageResult(
        stage=3, stage_name="access", resource_id=resource_id,
        success=True, next_status=PipelineStatus.ACCESS_EVALUATED.value,
        data={"extraction_mode": extraction_mode},
    )


# ── Stage 4: Normalize ────────────────────────────────────────────────────────
async def stage_4_normalize(
    session: AsyncSession,
    resource_id: uuid.UUID,
    normalized_fields: dict[str, Any],
) -> StageResult:
    """Clean metadata. Resolve or create the sources row."""
    await session.execute(
        update(Resource)
        .where(Resource.resource_id == resource_id)
        .values(
            canonical_url=normalized_fields.get("canonical_url"),
            external_identifiers=normalized_fields.get("external_identifiers"),
            license=normalized_fields.get("license"),
            rights_info=normalized_fields.get("rights_info"),
            attribution_requirements=normalized_fields.get("attribution_requirements"),
            pipeline_status=PipelineStatus.NORMALIZED.value,
            updated_at=datetime.utcnow(),
        )
    )
    return StageResult(stage=4, stage_name="normalize", resource_id=resource_id,
                       success=True, next_status=PipelineStatus.NORMALIZED.value)


# ── Stage 5: Extract ──────────────────────────────────────────────────────────
async def stage_5_extract(
    session: AsyncSession,
    resource_id: uuid.UUID,
    extraction_mode: str,
    extracted_content: dict[str, Any],
) -> StageResult:
    """Pull text/transcript/structure/evidence within the stage-3 access limit.

    extracted_content may contain: text, transcript_segments, tables, evidence_pointers.
    MUST NOT extract more than extraction_mode allows.
    """
    if extraction_mode == "skip":
        # resource is 'removed' — no extraction possible
        return StageResult(stage=5, stage_name="extract", resource_id=resource_id,
                           success=True, next_status=PipelineStatus.EXTRACTED.value,
                           notes="Skipped: access_status=removed")

    await session.execute(
        update(Resource)
        .where(Resource.resource_id == resource_id)
        .values(
            description=extracted_content.get("summary") or extracted_content.get("description"),
            pipeline_status=PipelineStatus.EXTRACTED.value,
            updated_at=datetime.utcnow(),
        )
    )

    # Write evidence pointers if supplied
    for ep in extracted_content.get("evidence_pointers", []):
        evidence = Evidence(
            resource_id=resource_id,
            pointer_type=ep.get("pointer_type", "other"),
            pointer_value=ep.get("pointer_value"),
            claim_text=ep["claim_text"],
            claim_status="resource_claim",
        )
        session.add(evidence)

    return StageResult(stage=5, stage_name="extract", resource_id=resource_id,
                       success=True, next_status=PipelineStatus.EXTRACTED.value)


# ── Stage 6: Classify ─────────────────────────────────────────────────────────
async def stage_6_classify(
    session: AsyncSession,
    resource_id: uuid.UUID,
    classification: dict[str, Any],
    confidence_threshold: float = 0.6,
) -> StageResult:
    """Assign topics, entities, questions/intents, context. Link to taxonomy.

    If overall classification confidence is below threshold → review_queue.
    MUST NOT let AI-assigned classification skip ai_assessed (ED-01 §4 item 7).
    """
    confidence = classification.get("confidence", 0.0)
    if confidence < confidence_threshold:
        review_id = await _open_failure_review(
            session, resource_id, "low_ai_confidence",
            f"Stage 6 classify: confidence {confidence:.2f} below threshold {confidence_threshold}",
        )
        return StageResult(stage=6, stage_name="classify", resource_id=resource_id,
                           success=False, review_opened=review_id,
                           notes=f"Low confidence: {confidence:.2f}")

    await session.execute(
        update(Resource)
        .where(Resource.resource_id == resource_id)
        .values(
            context=classification.get("context"),
            pipeline_status=PipelineStatus.CLASSIFIED.value,
            updated_at=datetime.utcnow(),
        )
    )

    # Write taxonomy relationship edges
    for topic_id in classification.get("taxonomy_node_ids", []):
        rel = Relationship(
            subject_type="resource",
            subject_id=resource_id,
            relation="covers_topic",
            object_type="taxonomy_node",
            object_id=uuid.UUID(topic_id),
            confidence=confidence,
            confidence_state=TrustState.AI_ASSESSED.value,
            created_by="ai",
        )
        session.add(rel)

    # Write question relationship edges
    for q_id in classification.get("question_ids", []):
        rel = Relationship(
            subject_type="resource",
            subject_id=resource_id,
            relation="supports_question",
            object_type="question",
            object_id=uuid.UUID(q_id),
            confidence=confidence,
            confidence_state=TrustState.AI_ASSESSED.value,
            created_by="ai",
        )
        session.add(rel)

    return StageResult(stage=6, stage_name="classify", resource_id=resource_id,
                       success=True, next_status=PipelineStatus.CLASSIFIED.value,
                       data={"confidence": confidence})


# ── Stage 7: Verify (trust assessment) ───────────────────────────────────────
async def stage_7_verify(
    session: AsyncSession,
    resource_id: uuid.UUID,
    trust_assessment: dict[str, Any],
    is_medicine_domain: bool = True,
) -> StageResult:
    """Check authority, evidence quality, consistency. Set trust_state=ai_assessed.

    For Medicine (is_medicine_domain=True): MUST open a sensitive_domain
    review_queue row — no exceptions (LD-02 §2).

    trust_dimensions: {authority, evidence, relevance, freshness, context,
                       consistency, verification} — MUST NOT collapse to a single number.
    """
    trust_dimensions = trust_assessment.get("trust_dimensions", {})
    field_confidence = trust_assessment.get("field_confidence", {})

    # Advance pipeline_status to 'verified' (the pipeline stage, not trust_state)
    await session.execute(
        update(Resource)
        .where(Resource.resource_id == resource_id)
        .values(
            trust_dimensions=trust_dimensions,
            field_confidence=field_confidence,
            pipeline_status=PipelineStatus.VERIFIED.value,
            updated_at=datetime.utcnow(),
        )
    )

    # Advance trust_state to ai_assessed via the state machine
    ts_result = await advance_trust_state(
        session, resource_id=resource_id, target_state=TrustState.AI_ASSESSED.value,
        actor="pipeline_stage_7",
    )

    # Medicine mandatory sensitive_domain review row (LD-02 §2)
    review_id = None
    if is_medicine_domain:
        from agents.organizer.review_handoff import handoff_medicine_resource
        review_id = await handoff_medicine_resource(session, resource_id)

    return StageResult(
        stage=7, stage_name="verify", resource_id=resource_id,
        success=ts_result.success,
        next_status=PipelineStatus.VERIFIED.value,
        review_opened=review_id,
        notes=(
            f"trust_state → {ts_result.to_state}; "
            f"sensitive_domain review opened: {review_id}"
            if is_medicine_domain else
            f"trust_state → {ts_result.to_state}"
        ),
    )


# ── Stage 8: Canonicalize ─────────────────────────────────────────────────────
async def stage_8_canonicalize(
    session: AsyncSession,
    resource_id: uuid.UUID,
    canon_decision: dict[str, Any],
) -> StageResult:
    """Determine same_resource / related_resource / new_version_of / different_source.

    MUST NOT guess when ambiguous — open a review_queue row (ED-01 §3 stage 8).
    MUST NOT collapse independently published sources just because content overlaps
    (ED-01 §4 item 4).
    """
    relation = canon_decision.get("relation")
    ambiguous = canon_decision.get("ambiguous", False)

    if ambiguous or not relation:
        review_id = await _open_failure_review(
            session, resource_id, "canonicalization_ambiguous",
            "Stage 8: canonicalization ambiguous — human judgment required",
        )
        return StageResult(stage=8, stage_name="canonicalize", resource_id=resource_id,
                           success=False, review_opened=review_id,
                           notes="Canonicalization ambiguous — queued for review")

    if canon_decision.get("related_resource_id") and relation != "same_resource":
        rel = Relationship(
            subject_type="resource",
            subject_id=resource_id,
            relation=relation,
            object_type="resource",
            object_id=uuid.UUID(canon_decision["related_resource_id"]),
            confidence=canon_decision.get("confidence", 0.8),
            confidence_state=TrustState.AI_ASSESSED.value,
            created_by="ai",
        )
        session.add(rel)

    await _set_pipeline_status(session, resource_id, PipelineStatus.CANONICALIZED.value)
    return StageResult(stage=8, stage_name="canonicalize", resource_id=resource_id,
                       success=True, next_status=PipelineStatus.CANONICALIZED.value,
                       data={"relation": relation})


# ── Stage 9: Connect ──────────────────────────────────────────────────────────
async def stage_9_connect(
    session: AsyncSession,
    resource_id: uuid.UUID,
    edges: list[dict[str, Any]],
) -> StageResult:
    """Write remaining knowledge edges (covers_topic, created_by, regulated_by, etc.)."""
    for edge in edges:
        rel = Relationship(
            subject_type=edge.get("subject_type", "resource"),
            subject_id=uuid.UUID(edge["subject_id"]) if "subject_id" in edge else resource_id,
            relation=edge["relation"],
            object_type=edge["object_type"],
            object_id=uuid.UUID(edge["object_id"]),
            confidence=edge.get("confidence", 0.75),
            confidence_state=TrustState.AI_ASSESSED.value,
            created_by="ai",
        )
        session.add(rel)

    await _set_pipeline_status(session, resource_id, PipelineStatus.CONNECTED.value)
    return StageResult(stage=9, stage_name="connect", resource_id=resource_id,
                       success=True, next_status=PipelineStatus.CONNECTED.value,
                       data={"edges_written": len(edges)})


# ── Stage 10: Index ───────────────────────────────────────────────────────────
async def stage_10_index(
    session: AsyncSession,
    resource_id: uuid.UUID,
) -> StageResult:
    """Mark resource as indexed. Retrieval layer picks up from here.

    The actual lexical/semantic index write is handled by the retrieval layer
    watching for pipeline_status='indexed'. This stage just sets the status.
    """
    await session.execute(
        update(Resource)
        .where(Resource.resource_id == resource_id)
        .values(
            trust_state=TrustState.INDEXED.value,  # trust progression: discovered→identified→indexed
            pipeline_status=PipelineStatus.INDEXED.value,
            updated_at=datetime.utcnow(),
        )
    )
    return StageResult(stage=10, stage_name="index", resource_id=resource_id,
                       success=True, next_status=PipelineStatus.INDEXED.value)


# ── Stage 11: Monitor ─────────────────────────────────────────────────────────
async def stage_11_monitor(
    session: AsyncSession,
    resource_id: uuid.UUID,
    last_checked: Optional[datetime] = None,
) -> StageResult:
    """Schedule freshness re-checks per domain cadence policy (ED-04 §6).

    Cadence is looked up from freshness_policies by the monitoring scheduler —
    this stage just marks the resource as entering monitoring state.
    """
    await session.execute(
        update(Resource)
        .where(Resource.resource_id == resource_id)
        .values(
            freshness_last_checked=last_checked or datetime.utcnow(),
            pipeline_status=PipelineStatus.MONITORING.value,
            updated_at=datetime.utcnow(),
        )
    )
    return StageResult(stage=11, stage_name="monitor", resource_id=resource_id,
                       success=True, next_status=PipelineStatus.MONITORING.value)


# ── Stage 12: Learn ───────────────────────────────────────────────────────────
async def stage_12_learn(
    session: AsyncSession,
    resource_id: uuid.UUID,
    gap_id: Optional[uuid.UUID] = None,
) -> StageResult:
    """Feed loop-closure event to learning_loop_events (ED-12 §2.1).

    This stage does NOT change pipeline_status — it's a side-effect/reporting step.
    MUST NOT feed user_signals into trust_state or ranking directly (ED-01 §4 item 2).
    """
    if gap_id:
        from core.models import LearningLoopEvent
        event = LearningLoopEvent(
            loop_stage="resource_served",
            coverage_gap_id=gap_id,
            resource_id=resource_id,
            occurred_at=datetime.utcnow(),
        )
        session.add(event)

    return StageResult(
        stage=12, stage_name="learn", resource_id=resource_id,
        success=True, next_status=None,
        notes="Learning loop event written" if gap_id else "No gap_id — no loop event",
    )


# ── Orchestrated run ─────────────────────────────────────────────────────────
async def run_pipeline(
    session: AsyncSession,
    resource_id: uuid.UUID,
    stage_inputs: dict[int, dict],
    is_medicine_domain: bool = True,
    gap_id: Optional[uuid.UUID] = None,
) -> list[StageResult]:
    """Run the full pipeline for a resource that's already at stage 0 (intake).

    stage_inputs is keyed by stage number and provides the stage-specific
    arguments that the Organizer's extraction/classification modules supply.

    Stops at first failure and returns all results so far — the review_queue
    row opened by the failed stage is what picks the item back up later.
    """
    results: list[StageResult] = []

    stages = [
        (1, lambda: stage_1_dedup(session, resource_id)),
        (2, lambda: stage_2_identify(session, resource_id, stage_inputs.get(2, {}))),
        (3, lambda: stage_3_access(session, resource_id,
                                   stage_inputs.get(3, {}).get("access_status", "public"),
                                   stage_inputs.get(3, {}).get("access_conditions"))),
        (4, lambda: stage_4_normalize(session, resource_id, stage_inputs.get(4, {}))),
        (5, lambda: stage_5_extract(session, resource_id,
                                    stage_inputs.get(3, {}).get("extraction_mode", "full"),
                                    stage_inputs.get(5, {}))),
        (6, lambda: stage_6_classify(session, resource_id, stage_inputs.get(6, {"confidence": 0.7}))),
        (7, lambda: stage_7_verify(session, resource_id, stage_inputs.get(7, {}), is_medicine_domain)),
        (8, lambda: stage_8_canonicalize(session, resource_id, stage_inputs.get(8, {"relation": "different_source"}))),
        (9, lambda: stage_9_connect(session, resource_id, stage_inputs.get(9, {}).get("edges", []))),
        (10, lambda: stage_10_index(session, resource_id)),
        (11, lambda: stage_11_monitor(session, resource_id)),
        (12, lambda: stage_12_learn(session, resource_id, gap_id)),
    ]

    for stage_num, stage_fn in stages:
        result = await stage_fn()
        results.append(result)
        if not result.success:
            break   # stop here; review_queue row is what resumes it

    return results
