"""
core/models/metrics.py — reporting and loop-closure tables.

These tables have NO write path back into resources or trust_state.
They measure the system; they do not drive it (Doc 9 §9, ED-11 §6).
"""
import uuid
from datetime import datetime

from sqlalchemy import TIMESTAMP, Column, Date, Float, ForeignKey, Index, Integer, Text, UniqueConstraint
from sqlalchemy.dialects.postgresql import UUID

from core.db import Base


class CoverageGap(Base):
    """ED-02 §3 — demand signal for acquisition prioritisation.

    Every Layer-2 trigger (ED-02 §2) and every user 'not found' signal
    writes here. This table is what acquisition prioritisation (ED-02 §4) reads from.
    """
    __tablename__ = "coverage_gaps"

    gap_id                = Column(UUID(as_uuid=True), primary_key=True, default=uuid.uuid4)
    query_text            = Column(Text, nullable=False)
    knowledge_universe_id = Column(Text, nullable=False)
    detected_at           = Column(TIMESTAMP(timezone=True), nullable=False, default=datetime.utcnow)
    resolution_status     = Column(Text, nullable=False, default="open")

    __table_args__ = (
        Index("coverage_gaps_universe_status_idx",
              "knowledge_universe_id", "resolution_status"),
    )


class LearningLoopEvent(Base):
    """ED-12 §2.1 — the loop-closure ledger.

    Proves the flywheel actually closes: gap_detected → acquisition_triggered
    → resource_indexed → resource_served, all linked by coverage_gap_id.

    This is a derived/reporting table — each row is written by an event
    already happening elsewhere in the pipeline. It adds no new decision
    logic; it makes closure rate measurable.
    """
    __tablename__ = "learning_loop_events"

    event_id        = Column(UUID(as_uuid=True), primary_key=True, default=uuid.uuid4)
    loop_stage      = Column(Text, nullable=False)   # loop_stage enum
    coverage_gap_id = Column(UUID(as_uuid=True),
                             ForeignKey("coverage_gaps.gap_id"), nullable=False)
    resource_id     = Column(UUID(as_uuid=True),
                             ForeignKey("resources.resource_id"))
    occurred_at     = Column(TIMESTAMP(timezone=True), nullable=False, default=datetime.utcnow)

    __table_args__ = (
        Index("learning_loop_events_gap_id_idx", "coverage_gap_id"),
    )


class GlobalExpansionMetric(Base):
    """ED-11 §6 — global coverage flywheel measurement.

    One row per (jurisdiction, language, time_period). Computed from existing
    data — sources, coverage_gaps, ranking logs.

    MUST NOT: use this table to auto-prioritise acquisition without the
    human checkpoint ED-02 §6 requires. This table measures the flywheel;
    it does not drive it (Doc 9 §9 applies to reporting tables too).
    """
    __tablename__ = "global_expansion_metrics"

    metric_id                     = Column(UUID(as_uuid=True), primary_key=True, default=uuid.uuid4)
    jurisdiction                  = Column(Text, nullable=False)
    language                      = Column(Text, nullable=False)
    period_start                  = Column(Date, nullable=False)
    period_end                    = Column(Date, nullable=False)
    active_sources_count          = Column(Integer, nullable=False, default=0)
    coverage_gaps_open            = Column(Integer, nullable=False, default=0)
    coverage_gaps_resolved        = Column(Integer, nullable=False, default=0)
    avg_local_applicability_score = Column(Float)
    query_volume                  = Column(Integer, nullable=False, default=0)

    __table_args__ = (
        UniqueConstraint("jurisdiction", "language", "period_start", "period_end",
                         name="global_expansion_metrics_unique"),
    )
