"""
core/models/resources.py — ED-01 §1.1–§1.7 tables.

Field names, types, and nullability mirror 001_initial_schema.sql exactly.
Enums that appear as Postgres types are stored as TEXT here and validated
at the service layer via core/enums.py — SQLAlchemy PG ENUM types would
couple migrations to models, which LD-03 §7 explicitly discourages.
"""
import uuid
from datetime import datetime

from sqlalchemy import TIMESTAMP
from sqlalchemy import (
    ARRAY, CheckConstraint, Column, Date, Enum as SAEnum, Float, ForeignKey,
    Index, Interval, Text,
)
from sqlalchemy.dialects.postgresql import JSONB, UUID
from sqlalchemy.orm import relationship

from core.db import Base
from core.enums import AccessStatus, PipelineStatus, TrustState


def _enum_values(enum_cls):
    return [member.value for member in enum_cls]


class Source(Base):
    """ED-01 §1.2 — publisher / institution / platform registry."""
    __tablename__ = "sources"

    source_id                = Column(UUID(as_uuid=True), primary_key=True, default=uuid.uuid4)
    name                     = Column(Text, nullable=False)
    type                     = Column(Text, nullable=False)           # source_type enum
    official_domains         = Column(ARRAY(Text))
    authority_area           = Column(Text)
    geographic_scope         = Column(Text)
    languages                = Column(ARRAY(Text))
    publication_history      = Column(JSONB)
    known_access_paths       = Column(JSONB)
    verification_status      = Column(SAEnum(TrustState, name="trust_state", values_callable=_enum_values, create_type=False), nullable=False, default=TrustState.DISCOVERED)
    org_people_relationships = Column(JSONB)
    created_at               = Column(TIMESTAMP(timezone=True), nullable=False, default=datetime.utcnow)
    updated_at               = Column(TIMESTAMP(timezone=True), nullable=False, default=datetime.utcnow,
                                      onupdate=datetime.utcnow)

    resources = relationship("Resource", back_populates="source")


class Entity(Base):
    """ED-01 §1.3 — persons, orgs, professions, skills, businesses, places, technologies, concepts.

    world_anchor is only set when this entity IS one of the three foundational worlds
    (profession / skill / business), not merely related to one (Doc 8 §2).
    """
    __tablename__ = "entities"

    entity_id    = Column(UUID(as_uuid=True), primary_key=True, default=uuid.uuid4)
    entity_type  = Column(Text, nullable=False)   # entity_type enum
    name         = Column(Text, nullable=False)
    world_anchor = Column(Text, CheckConstraint("world_anchor IN ('profession', 'skill', 'business')"))
    metadata_json = Column("metadata", JSONB)


class Topic(Base):
    """ED-01 §1.4 — topic hierarchy (self-referencing)."""
    __tablename__ = "topics"

    topic_id        = Column(UUID(as_uuid=True), primary_key=True, default=uuid.uuid4)
    name            = Column(Text, nullable=False)
    parent_topic_id = Column(UUID(as_uuid=True), ForeignKey("topics.topic_id"))

    children = relationship("Topic")


class Question(Base):
    """ED-01 §1.4 — questions are nodes; many resources point to the same question.

    Dedup by normalized_intent before creating a new row (UNIQUE constraint enforces this).
    """
    __tablename__ = "questions"

    question_id       = Column(UUID(as_uuid=True), primary_key=True, default=uuid.uuid4)
    question_text     = Column(Text, nullable=False)
    normalized_intent = Column(Text, nullable=False, unique=True)
    linked_topic_ids  = Column(ARRAY(UUID(as_uuid=True)))


class Resource(Base):
    """ED-01 §1.1 — the primary indexed content record.

    resource_id is permanent — never re-issued, never derived from canonical_url (Doc 5 §3).
    canonical_url is nullable: identity survives URL loss.
    type is FK → information_forms.form_id (not a literal ENUM) per ED-12 §1.1.
    trust_dimensions stores {authority, evidence, relevance, freshness, context,
      consistency, verification} and MUST NOT be collapsed into one number (ED-04 §1).
    """
    __tablename__ = "resources"

    resource_id                = Column(UUID(as_uuid=True), primary_key=True, default=uuid.uuid4)
    type                       = Column(Text, ForeignKey("information_forms.form_id"), nullable=False)
    subtype                    = Column(Text)
    canonical_url              = Column(Text)
    external_identifiers       = Column(JSONB)
    title                      = Column(Text, nullable=False)
    description                = Column(Text)
    creator_authors            = Column(JSONB)
    source_id                  = Column(UUID(as_uuid=True), ForeignKey("sources.source_id"))
    published_date             = Column(Date)
    updated_date               = Column(Date)
    languages                  = Column(ARRAY(Text))
    access_status              = Column(SAEnum(AccessStatus, name="access_status", values_callable=_enum_values, create_type=False), nullable=False, default=AccessStatus.PUBLIC)
    access_conditions          = Column(Text)
    license                    = Column(Text)
    rights_info                = Column(Text)
    attribution_requirements   = Column(Text)
    provenance                 = Column(JSONB)
    trust_state                = Column(SAEnum(TrustState, name="trust_state", values_callable=_enum_values, create_type=False), nullable=False, default=TrustState.DISCOVERED)
    trust_dimensions           = Column(JSONB)
    field_confidence           = Column(JSONB)
    freshness_last_checked     = Column(TIMESTAMP(timezone=True))
    freshness_cadence_override = Column(Interval)
    context                    = Column(JSONB)
    pipeline_status            = Column(SAEnum(PipelineStatus, name="pipeline_status", values_callable=_enum_values, create_type=False), nullable=False, default=PipelineStatus.INTAKE)
    created_at                 = Column(TIMESTAMP(timezone=True), nullable=False, default=datetime.utcnow)
    updated_at                 = Column(TIMESTAMP(timezone=True), nullable=False, default=datetime.utcnow,
                                        onupdate=datetime.utcnow)

    source       = relationship("Source", back_populates="resources")
    information_form = relationship("InformationForm")
    evidence_set = relationship("Evidence", back_populates="resource")
    user_signals = relationship("UserSignal", back_populates="resource")

    __table_args__ = (
        Index("resources_type_trust_idx", "type", "trust_state"),
        Index("resources_pipeline_idx", "pipeline_status"),
        Index("resources_source_id_idx", "source_id"),
    )


class Evidence(Base):
    """ED-01 §1.5 — pointer into a resource's content; distinguishes source claim from platform fact."""
    __tablename__ = "evidence"

    evidence_id   = Column(UUID(as_uuid=True), primary_key=True, default=uuid.uuid4)
    resource_id   = Column(UUID(as_uuid=True), ForeignKey("resources.resource_id"), nullable=False)
    pointer_type  = Column(Text, nullable=False)   # evidence_pointer_type enum
    pointer_value = Column(JSONB)
    claim_text    = Column(Text, nullable=False)
    claim_status  = Column(Text, nullable=False, default="resource_claim")

    resource = relationship("Resource", back_populates="evidence_set")


class Relationship(Base):
    """ED-01 §1.6 + ED-01 v1.1 (ED-03 §6 confidence_state amendment).

    Polymorphic edges across resources / sources / entities / topics / questions.
    confidence_state reuses trust_state enum; ai_assessed is the default for AI-inferred edges.

    MUST NOT collapse a related_resource / different_source edge into same_resource
    just because content overlaps (Doc 5 §8).
    """
    __tablename__ = "relationships"

    relationship_id  = Column(UUID(as_uuid=True), primary_key=True, default=uuid.uuid4)
    subject_type     = Column(Text, nullable=False)
    subject_id       = Column(UUID(as_uuid=True), nullable=False)
    relation         = Column(Text, nullable=False)   # relation enum
    object_type      = Column(Text, nullable=False)
    object_id        = Column(UUID(as_uuid=True), nullable=False)
    confidence       = Column(Float)
    confidence_state = Column(SAEnum(TrustState, name="trust_state", values_callable=_enum_values, create_type=False), nullable=False, default=TrustState.AI_ASSESSED)
    created_by       = Column(Text, nullable=False, default="ai")
    created_at       = Column(TIMESTAMP(timezone=True), nullable=False, default=datetime.utcnow)

    __table_args__ = (
        Index("relationships_subject_idx", "subject_type", "subject_id"),
        Index("relationships_object_idx", "object_type", "object_id"),
        Index("relationships_relation_idx", "relation"),
    )


class UserSignal(Base):
    """ED-01 §1.7 — engagement signals.

    MUST NOT: any aggregate of this table writes to resources.trust_state (Doc 9 §9-10).
    These signals feed ranking/orchestration only — never the trust pipeline.
    """
    __tablename__ = "user_signals"

    signal_id   = Column(UUID(as_uuid=True), primary_key=True, default=uuid.uuid4)
    user_id     = Column(UUID(as_uuid=True), nullable=False)
    resource_id = Column(UUID(as_uuid=True), ForeignKey("resources.resource_id"), nullable=False)
    signal_type = Column(Text, nullable=False)   # signal_type enum
    payload     = Column(JSONB)
    created_at  = Column(TIMESTAMP(timezone=True), nullable=False, default=datetime.utcnow)

    resource = relationship("Resource", back_populates="user_signals")
