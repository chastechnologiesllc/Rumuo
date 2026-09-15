"""
core/enums.py — single source of truth for every enum used across services/.

RULE (LD-03 §2): no service redefines these. Import from here. A schema change
starts in this file, not in whichever service happens to touch it first.

Every enum below is transcribed exactly from its owning ED — do not "clean up"
a value's spelling or casing. The ED text is the contract.
"""

from enum import Enum


# ── ED-01 §2.1 — used by both resources.trust_state and sources.verification_status ──
class TrustState(str, Enum):
    DISCOVERED = "discovered"
    IDENTIFIED = "identified"
    INDEXED = "indexed"
    AI_ASSESSED = "ai_assessed"
    EVIDENCE_SUPPORTED = "evidence_supported"
    VERIFIED = "verified"
    AUTHORITATIVE_OFFICIAL = "authoritative_official"
    OUTDATED = "outdated"
    DISPUTED = "disputed"
    RESTRICTED = "restricted"
    UNDER_REVIEW = "under_review"


# ── ED-01 §2.2 ──
class AccessStatus(str, Enum):
    PUBLIC = "public"
    LOGIN_REQUIRED = "login_required"
    PAID = "paid"
    RESTRICTED = "restricted"
    DOWNLOADABLE = "downloadable"
    STREAMABLE = "streamable"
    REMOVED = "removed"


# ── ED-01 §2.3 — pipeline stage status, distinct from TrustState despite similar names.
# See LD-02 §2's note: pipeline_status=verified (stage 7 complete) != trust_state=verified. ──
class PipelineStatus(str, Enum):
    INTAKE = "intake"
    DEDUP_CHECKED = "dedup_checked"
    IDENTIFIED = "identified"
    ACCESS_EVALUATED = "access_evaluated"
    NORMALIZED = "normalized"
    EXTRACTED = "extracted"
    CLASSIFIED = "classified"
    VERIFIED = "verified"
    CANONICALIZED = "canonicalized"
    CONNECTED = "connected"
    INDEXED = "indexed"
    MONITORING = "monitoring"


# ── ED-01 §2.4, amended by ED-03 §3 (v1.1) and ED-11 §2.1/§4.1 (v1.2, pending patch) ──
class Relation(str, Enum):
    # Canonicalization (Doc 5 §8)
    SAME_RESOURCE = "same_resource"
    RELATED_RESOURCE_DERIVATIVE = "related_resource_derivative"
    RELATED_RESOURCE_SUMMARY = "related_resource_summary"
    RELATED_RESOURCE_TRANSLATION = "related_resource_translation"
    RELATED_RESOURCE_COMMENTARY = "related_resource_commentary"
    NEW_VERSION_OF = "new_version_of"
    DIFFERENT_SOURCE = "different_source"
    # Knowledge (Doc 5 §4, Doc 8 §5 — five values added in ED-01 v1.1)
    COVERS_TOPIC = "covers_topic"
    CREATED_BY = "created_by"
    PUBLISHED_BY = "published_by"
    SUPPORTS_QUESTION = "supports_question"
    CONTRADICTS = "contradicts"
    RELATED_TO = "related_to"
    BELONGS_TO = "belongs_to"
    REQUIRES = "requires"
    TEACHES = "teaches"
    LOCATED_IN = "located_in"
    REGULATED_BY = "regulated_by"
    DEPENDS_ON = "depends_on"
    PART_OF = "part_of"
    VALID_IN = "valid_in"
    UPDATED_BY = "updated_by"
    OPERATES_IN = "operates_in"
    USED_IN = "used_in"
    PRACTICES = "practices"
    OPERATES = "operates"
    SOLVES = "solves"
    ANSWERS = "answers"
    COMPETES_WITH = "competes_with"
    # ED-11 §2.1 / §4.1 — pending ED-01 v1.2 patch, needed for this pilot's cross-language
    # and cross-jurisdiction linking. Implemented here now; flag in ED-01's own file per
    # LD-00/ED-00 v2's "amendment required, not silently applied" rule.
    EQUIVALENT_CONCEPT = "equivalent_concept"
    REGIONAL_VARIANT_OF = "regional_variant_of"


# ── ED-01 §2.5 ──
class SourceType(str, Enum):
    INSTITUTION = "institution"
    PUBLISHER = "publisher"
    PLATFORM = "platform"
    CREATOR = "creator"
    INDIVIDUAL = "individual"
    ORGANIZATION = "organization"


# ── ED-01 §2.6 ──
class EntityType(str, Enum):
    PERSON = "person"
    ORGANIZATION = "organization"
    PROFESSION = "profession"
    SKILL = "skill"
    BUSINESS = "business"
    PLACE = "place"
    TECHNOLOGY = "technology"
    CONCEPT = "concept"


# ── ED-01 §1.1 — the five information forms. See ED-12 §1: this becomes a registry
# table (information_forms), not a closed enum, precisely so a sixth form never
# requires touching this file. This enum exists only to seed that table's first
# five rows — do not reference it directly from service code; query the registry. ──
class InformationFormSeed(str, Enum):
    VIDEO = "video"
    SHORTS = "shorts"
    AUDIO = "audio"
    WRITTEN = "written"
    STRUCTURED_INTERACTIVE = "structured_interactive"


class InformationFormStatus(str, Enum):
    """ED-12 §1.1"""
    ACTIVE = "active"
    CANDIDATE = "candidate"
    DEPRECATED = "deprecated"


# ── ED-04 §9 — review_queue.reason_code ──
class ReviewReasonCode(str, Enum):
    HIGH_VALUE_SOURCE = "high_value_source"
    AMBIGUOUS_PROVENANCE = "ambiguous_provenance"
    SENSITIVE_DOMAIN = "sensitive_domain"  # every Medicine resource, per ED-01 §6 + LD-02 §2
    LOW_AI_CONFIDENCE = "low_ai_confidence"
    USER_FLAGGED = "user_flagged"
    CANONICALIZATION_AMBIGUOUS = "canonicalization_ambiguous"
    CONTRADICTION_DETECTED = "contradiction_detected"


class ReviewStatus(str, Enum):
    """ED-04 §9"""
    OPEN = "open"
    IN_REVIEW = "in_review"
    RESOLVED = "resolved"


# ── ED-13 §1.1 — training_examples.outcome_quality. Deliberately reuses the shape
# of TrustState rather than inventing a parallel scale (ED-13 §1.1 note). ──
class TrainingOutcomeQuality(str, Enum):
    VERIFIED_SUCCESSFUL = "verified_successful"
    EVIDENCE_SUPPORTED = "evidence_supported"
    PLAUSIBLE = "plausible"
    UNVERIFIED = "unverified"


# ── ED-13 §5.1 — model_registry ──
class ModelRole(str, Enum):
    CLASSIFICATION = "classification"
    EMBEDDING = "embedding"
    EXTRACTION = "extraction"
    ORCHESTRATION = "orchestration"
    SYNTHESIS = "synthesis"


class ModelStatus(str, Enum):
    CANDIDATE = "candidate"
    ACTIVE = "active"
    DEPRECATED = "deprecated"


# ── ED-13 §2 — orchestrator_mode. Amendment to ED-06 §2 (v1.1, pending patch). ──
class OrchestratorMode(str, Enum):
    QUICK_DISCOVERY = "quick_discovery"
    EXPLORATION = "exploration"
    PROBLEM_SOLVING = "problem_solving"
    DEEP_RESEARCH = "deep_research"
    KEEP_CURRENT = "keep_current"


# ── ED-12 §2.1 — learning_loop_events.loop_stage ──
class LoopStage(str, Enum):
    GAP_DETECTED = "gap_detected"
    ACQUISITION_TRIGGERED = "acquisition_triggered"
    RESOURCE_INDEXED = "resource_indexed"
    RESOURCE_SERVED = "resource_served"


# ── ED-02 §3 — coverage_gaps.resolution_status ──
class GapResolutionStatus(str, Enum):
    OPEN = "open"
    EXTERNAL_DISCOVERY_TRIGGERED = "external_discovery_triggered"
    RESOLVED = "resolved"
    UNRESOLVABLE = "unresolvable"
