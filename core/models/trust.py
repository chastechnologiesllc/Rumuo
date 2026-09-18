"""
core/models/trust.py — ED-04 §2/§6/§9 and ED-12 §1.1 trust layer tables.
"""
import uuid
from datetime import datetime

from sqlalchemy import TIMESTAMP, CheckConstraint, Column, Float, Index, Text, UniqueConstraint
from sqlalchemy.dialects.postgresql import UUID
from sqlalchemy.orm import relationship

from core.db import Base


class InformationForm(Base):
    """ED-12 §1.1 — registry of information forms.

    form_id is TEXT PK so a new form is a data change, not a schema change.
    resources.type FKs here — not a literal ENUM — per ED-12 §1.1.
    MUST NOT remove or repurpose a form_id once any resources row references it;
    mark deprecated instead (ED-12 §1.2 identity guarantee).
    """
    __tablename__ = "information_forms"

    form_id        = Column(Text, primary_key=True)
    display_name   = Column(Text, nullable=False)
    status         = Column(Text, nullable=False, default="active")   # information_form_status
    introduced_at  = Column(Text, nullable=False)                     # DATE stored as text for simplicity
    pipeline_notes = Column(Text)

    resources = relationship("Resource", back_populates="information_form",
                             foreign_keys="Resource.type",
                             primaryjoin="InformationForm.form_id == Resource.type")


class AuthorityWeight(Base):
    """ED-04 §2, §7 — (claim_type, source_type, jurisdiction) → weight lookup.

    Authority is contextual, not a fixed source property (Doc 9 §7).
    Jurisdiction is a required dimension of the lookup key (ED-04 §7) —
    MUST NOT apply one universal ranking regardless of jurisdiction.
    Initial seed values are in db/seeds/medicine_nigeria/authority_weights.yaml.
    """
    __tablename__ = "authority_weights"

    weight_id    = Column(UUID(as_uuid=True), primary_key=True, default=uuid.uuid4)
    claim_type   = Column(Text, nullable=False)
    source_type  = Column(Text, nullable=False)
    jurisdiction = Column(Text, nullable=False, default="GLOBAL")
    weight       = Column(Float, nullable=False)

    __table_args__ = (
        CheckConstraint("weight >= 0 AND weight <= 1", name="weight_range"),
        UniqueConstraint("claim_type", "source_type", "jurisdiction", name="authority_weights_unique"),
    )


class FreshnessPolicy(Base):
    """ED-04 §6 — domain-type freshness cadences (Doc 9 §13).

    resources.freshness_cadence_override (ED-01 §1.1) takes precedence per resource;
    absent an override the resource's domain classification uses this table.
    """
    __tablename__ = "freshness_policies"

    policy_id       = Column(UUID(as_uuid=True), primary_key=True, default=uuid.uuid4)
    domain_type     = Column(Text, nullable=False, unique=True)
    default_cadence = Column(Text)    # INTERVAL stored as text: '90 days', '30 days', etc.
    rationale       = Column(Text)


class ReviewQueue(Base):
    """ED-04 §9 — the single shared human-checkpoint table.

    Every ED that needs a human-in-the-loop hook writes here rather than
    defining its own checkpoint mechanism.

    For Medicine: every resource MUST get a sensitive_domain row at pipeline
    stage 7 (LD-02 §2 hard rule — no exceptions, no shortcuts).

    State machine:
      open → in_review (reviewer picks it up)
      in_review → resolved (reviewer submits resolution)
      Only a resolved row with resolution='approved' can unlock trust_state=verified
      or trust_state=authoritative_official (ED-04 §11).
    """
    __tablename__ = "review_queue"

    review_id    = Column(UUID(as_uuid=True), primary_key=True, default=uuid.uuid4)
    subject_type = Column(Text, nullable=False)
    subject_id   = Column(UUID(as_uuid=True), nullable=False)
    reason_code  = Column(Text, nullable=False)   # review_reason_code enum
    status       = Column(Text, nullable=False, default="open")
    assigned_to  = Column(UUID(as_uuid=True))
    resolution   = Column(Text)
    created_at   = Column(TIMESTAMP(timezone=True), nullable=False, default=datetime.utcnow)
    resolved_at  = Column(TIMESTAMP(timezone=True))

    __table_args__ = (
        Index("review_queue_status_reason_idx", "status", "reason_code"),
        Index("review_queue_subject_idx", "subject_type", "subject_id"),
    )
