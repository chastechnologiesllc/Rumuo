"""
core/models/training.py — ED-13 §1.1 training_examples and §5.1 model_registry.
"""
import uuid
from datetime import datetime

from sqlalchemy import ARRAY, Column, ForeignKey, Text
from sqlalchemy.dialects.postgresql import JSONB, TIMESTAMPTZ, UUID
from sqlalchemy.orm import relationship

from core.db import Base


class TrainingExample(Base):
    """ED-13 §1.1 — curated successful information paths for pattern learning.

    MUST NOT weight 'unverified' examples equally with 'verified_successful' ones.
    outcome_quality='verified_successful' requires the same evidence/review gate as
    ED-04 §11 — NOT just engagement volume (engagement-is-not-truth, Doc 9 §9-10).
    """
    __tablename__ = "training_examples"

    example_id      = Column(UUID(as_uuid=True), primary_key=True, default=uuid.uuid4)
    question_type   = Column(Text)
    context         = Column(JSONB)
    concepts        = Column(ARRAY(UUID(as_uuid=True)))
    resource_path   = Column(ARRAY(UUID(as_uuid=True)))
    outcome_quality = Column(Text, nullable=False, default="unverified")
    provenance      = Column(UUID(as_uuid=True), ForeignKey("evidence.evidence_id"))
    created_at      = Column(TIMESTAMPTZ, nullable=False, default=datetime.utcnow)


class ModelRegistry(Base):
    """ED-13 §5.1 — AI model lifecycle tracking.

    MUST NOT promote a candidate model to active for orchestration/synthesis
    without passing ED-04 §3's evidence-before-confidence gate.
    MUST NOT let a model swap alter trust_state transition logic (ED-04 §11)
    or pipeline_status progression (ED-01 §3) as a side effect.
    """
    __tablename__ = "model_registry"

    model_id           = Column(UUID(as_uuid=True), primary_key=True, default=uuid.uuid4)
    provider           = Column(Text, nullable=False)
    version            = Column(Text, nullable=False)
    role               = Column(Text, nullable=False)   # model_role enum
    status             = Column(Text, nullable=False, default="candidate")
    evaluation_metrics = Column(JSONB)
    promoted_at        = Column(TIMESTAMPTZ)
    deprecated_at      = Column(TIMESTAMPTZ)
