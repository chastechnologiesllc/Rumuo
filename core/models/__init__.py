"""
core/models — ORM models for every table in the schema.

RULE (LD-03 §2): services import from here, never redefine their own.
RULE: every field, type, and constraint here mirrors 001_initial_schema.sql
      which was written directly from the cited ED sections.
"""
from .resources import Resource, Source, Entity, Topic, Question, Evidence, Relationship, UserSignal
from .trust import InformationForm, AuthorityWeight, FreshnessPolicy, ReviewQueue
from .taxonomy import TaxonomyNode
from .training import TrainingExample, ModelRegistry
from .metrics import CoverageGap, LearningLoopEvent, GlobalExpansionMetric

__all__ = [
    "Resource", "Source", "Entity", "Topic", "Question", "Evidence",
    "Relationship", "UserSignal",
    "InformationForm", "AuthorityWeight", "FreshnessPolicy", "ReviewQueue",
    "TaxonomyNode",
    "TrainingExample", "ModelRegistry",
    "CoverageGap", "LearningLoopEvent", "GlobalExpansionMetric",
]
