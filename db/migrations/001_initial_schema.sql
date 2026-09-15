-- 001_initial_schema.sql
-- Authored against: ED-01 §1–§2, ED-02 §3, ED-03 §2, ED-04 §2/§6/§9,
--                   ED-11 §6, ED-12 §1.1/§2.1, ED-13 §1.1/§5.1
-- MUST NOT: edit this file after merge. Write a new migration per LD-03 §7.
-- MUST: every enum value below matches core/enums.py exactly. The ED text is the contract.
-- MUST NOT: inline taxonomy or seed data here — see db/seeds/ instead.

BEGIN;

-- ── Extension ────────────────────────────────────────────────────────────────
CREATE EXTENSION IF NOT EXISTS pgcrypto;

-- ── Enums — exact spelling per core/enums.py and their owning EDs ──────────

-- ED-01 §2.1: used by resources.trust_state, sources.verification_status,
--             relationships.confidence_state (ED-03 §6 / ED-01 v1.1)
CREATE TYPE trust_state AS ENUM (
    'discovered', 'identified', 'indexed', 'ai_assessed', 'evidence_supported',
    'verified', 'authoritative_official', 'outdated', 'disputed', 'restricted', 'under_review'
);

-- ED-01 §2.2
CREATE TYPE access_status AS ENUM (
    'public', 'login_required', 'paid', 'restricted', 'downloadable', 'streamable', 'removed'
);

-- ED-01 §2.3 — pipeline_status is DISTINCT from trust_state despite overlapping names.
-- pipeline_status=verified means stage 7 complete; trust_state=verified requires a
-- resolved review_queue row. See LD-02 §2 for this exact disambiguation.
CREATE TYPE pipeline_status AS ENUM (
    'intake', 'dedup_checked', 'identified', 'access_evaluated', 'normalized',
    'extracted', 'classified', 'verified', 'canonicalized', 'connected', 'indexed', 'monitoring'
);

-- ED-01 §2.4 + ED-03 §3 (five added values in v1.1) + ED-11 §2.1/§4.1
CREATE TYPE relation AS ENUM (
    -- Canonicalization (Doc 5 §8)
    'same_resource', 'related_resource_derivative', 'related_resource_summary',
    'related_resource_translation', 'related_resource_commentary',
    'new_version_of', 'different_source',
    -- Knowledge (Doc 5 §4, Doc 8 §5; last five added ED-01 v1.1)
    'covers_topic', 'created_by', 'published_by', 'supports_question', 'contradicts',
    'related_to', 'belongs_to', 'requires', 'teaches', 'located_in', 'regulated_by',
    'depends_on', 'part_of', 'valid_in', 'updated_by', 'operates_in', 'used_in',
    'practices', 'operates', 'solves', 'answers', 'competes_with',
    -- ED-11 §2.1 / §4.1 — pending ED-01 v1.2 patch; implemented now per LD-00 guidance
    'equivalent_concept', 'regional_variant_of'
);

-- ED-01 §2.5
CREATE TYPE source_type AS ENUM (
    'institution', 'publisher', 'platform', 'creator', 'individual', 'organization'
);

-- ED-01 §2.6
CREATE TYPE entity_type AS ENUM (
    'person', 'organization', 'profession', 'skill', 'business',
    'place', 'technology', 'concept'
);

-- ED-12 §1.1
CREATE TYPE information_form_status AS ENUM ('active', 'candidate', 'deprecated');

-- ED-04 §9
CREATE TYPE review_reason_code AS ENUM (
    'high_value_source', 'ambiguous_provenance', 'sensitive_domain',
    'low_ai_confidence', 'user_flagged', 'canonicalization_ambiguous', 'contradiction_detected'
);

CREATE TYPE review_status AS ENUM ('open', 'in_review', 'resolved');

-- ED-01 §1.7
CREATE TYPE signal_type AS ENUM (
    'open', 'save', 'complete', 'dismiss', 'search',
    'not_useful', 'report', 'comment', 'solved_problem'
);

-- ED-01 §1.5
CREATE TYPE evidence_pointer_type AS ENUM (
    'transcript_segment', 'article_section', 'page', 'table', 'dataset_field', 'other'
);

CREATE TYPE claim_status AS ENUM ('resource_claim', 'platform_verified');

-- ED-01 §1.6
CREATE TYPE created_by_type AS ENUM ('human', 'ai');

-- ED-13 §5.1
CREATE TYPE model_role AS ENUM (
    'classification', 'embedding', 'extraction', 'orchestration', 'synthesis'
);

CREATE TYPE model_status AS ENUM ('candidate', 'active', 'deprecated');

-- ED-12 §2.1
CREATE TYPE loop_stage AS ENUM (
    'gap_detected', 'acquisition_triggered', 'resource_indexed', 'resource_served'
);

-- ED-02 §3
CREATE TYPE gap_resolution_status AS ENUM (
    'open', 'external_discovery_triggered', 'resolved', 'unresolvable'
);

-- ED-13 §1.1
CREATE TYPE training_outcome_quality AS ENUM (
    'verified_successful', 'evidence_supported', 'plausible', 'unverified'
);


-- ── information_forms (ED-12 §1.1) ──────────────────────────────────────────
-- Created first because resources.type FKs here (not a literal ENUM).
-- form_id is TEXT so a new form is a data change, not a schema change.
CREATE TABLE information_forms (
    form_id        TEXT PRIMARY KEY,
    display_name   TEXT NOT NULL,
    status         information_form_status NOT NULL DEFAULT 'active',
    introduced_at  DATE NOT NULL,
    pipeline_notes TEXT
);


-- ── sources (ED-01 §1.2) ────────────────────────────────────────────────────
CREATE TABLE sources (
    source_id                UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    name                     TEXT NOT NULL,
    type                     source_type NOT NULL,
    official_domains         TEXT[],
    authority_area           TEXT,
    geographic_scope         TEXT,
    languages                TEXT[],
    publication_history      JSONB,
    known_access_paths       JSONB,
    verification_status      trust_state NOT NULL DEFAULT 'discovered',
    org_people_relationships JSONB,
    created_at               TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    updated_at               TIMESTAMPTZ NOT NULL DEFAULT NOW()
);


-- ── entities (ED-01 §1.3) ───────────────────────────────────────────────────
-- world_anchor is only set when the entity IS one of the three worlds,
-- not merely related to one (Doc 8 §2).
CREATE TABLE entities (
    entity_id    UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    entity_type  entity_type NOT NULL,
    name         TEXT NOT NULL,
    world_anchor TEXT CHECK (world_anchor IN ('profession', 'skill', 'business')),
    metadata     JSONB
);


-- ── topics (ED-01 §1.4) ─────────────────────────────────────────────────────
CREATE TABLE topics (
    topic_id        UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    name            TEXT NOT NULL,
    parent_topic_id UUID REFERENCES topics(topic_id)
);


-- ── questions (ED-01 §1.4) ──────────────────────────────────────────────────
-- A question is a node; many resources point to the same question.
-- Dedup by normalized_intent before creating a new row (ED-01 §1.4).
CREATE TABLE questions (
    question_id       UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    question_text     TEXT NOT NULL,
    normalized_intent TEXT NOT NULL UNIQUE,
    linked_topic_ids  UUID[]
);


-- ── resources (ED-01 §1.1 + ED-12 §1.1 FK amendment) ───────────────────────
-- resource_id is permanent — never re-issued, never derived from canonical_url.
-- canonical_url is nullable: identity survives URL loss (Doc 5 §3).
-- type is FK → information_forms.form_id, not a literal ENUM (ED-12 §1.1).
CREATE TABLE resources (
    resource_id                UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    type                       TEXT NOT NULL REFERENCES information_forms(form_id),
    subtype                    TEXT,
    canonical_url              TEXT,
    external_identifiers       JSONB,
    title                      TEXT NOT NULL,
    description                TEXT,
    creator_authors            JSONB,
    source_id                  UUID REFERENCES sources(source_id),
    published_date             DATE,
    updated_date               DATE,
    languages                  TEXT[],
    access_status              access_status NOT NULL DEFAULT 'public',
    access_conditions          TEXT,
    license                    TEXT,
    rights_info                TEXT,
    attribution_requirements   TEXT,
    provenance                 JSONB,
    trust_state                trust_state NOT NULL DEFAULT 'discovered',
    -- ED-04 §1 / ED-01 v1.1: {authority, evidence, relevance, freshness,
    --   context, consistency, verification} — never collapsed into one number.
    trust_dimensions           JSONB,
    -- ED-04 §3: per-field-group confidence tags; ai_inferred fields MUST NOT
    --   be rendered with the same weight as human_verified ones.
    field_confidence           JSONB,
    freshness_last_checked     TIMESTAMPTZ,
    freshness_cadence_override INTERVAL,
    context                    JSONB,
    pipeline_status            pipeline_status NOT NULL DEFAULT 'intake',
    created_at                 TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    updated_at                 TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

CREATE INDEX resources_type_trust_idx     ON resources(type, trust_state);
CREATE INDEX resources_pipeline_idx       ON resources(pipeline_status);
CREATE INDEX resources_source_id_idx      ON resources(source_id);
CREATE INDEX resources_canonical_url_idx  ON resources(canonical_url)
    WHERE canonical_url IS NOT NULL;


-- ── evidence (ED-01 §1.5) ───────────────────────────────────────────────────
CREATE TABLE evidence (
    evidence_id   UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    resource_id   UUID NOT NULL REFERENCES resources(resource_id),
    pointer_type  evidence_pointer_type NOT NULL,
    pointer_value JSONB,
    claim_text    TEXT NOT NULL,
    claim_status  claim_status NOT NULL DEFAULT 'resource_claim'
);

CREATE INDEX evidence_resource_id_idx ON evidence(resource_id);


-- ── relationships (ED-01 §1.6 + ED-01 v1.1 confidence_state from ED-03 §6) ─
-- confidence_state reuses trust_state enum; typically ai_assessed for AI-inferred
-- edges, evidence_supported / verified for confirmed ones.
CREATE TABLE relationships (
    relationship_id  UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    subject_type     TEXT NOT NULL,
    subject_id       UUID NOT NULL,
    relation         relation NOT NULL,
    object_type      TEXT NOT NULL,
    object_id        UUID NOT NULL,
    confidence       FLOAT,
    confidence_state trust_state NOT NULL DEFAULT 'ai_assessed',
    created_by       created_by_type NOT NULL DEFAULT 'ai',
    created_at       TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

CREATE INDEX relationships_subject_idx ON relationships(subject_type, subject_id);
CREATE INDEX relationships_object_idx  ON relationships(object_type, object_id);
CREATE INDEX relationships_relation_idx ON relationships(relation);


-- ── user_signals (ED-01 §1.7) ───────────────────────────────────────────────
-- MUST NOT: any aggregate of this table writes to resources.trust_state.
-- These signals feed ranking/orchestration only (Doc 9 §9–10).
CREATE TABLE user_signals (
    signal_id   UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    user_id     UUID NOT NULL,
    resource_id UUID NOT NULL REFERENCES resources(resource_id),
    signal_type signal_type NOT NULL,
    payload     JSONB,
    created_at  TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

CREATE INDEX user_signals_resource_id_idx ON user_signals(resource_id);
CREATE INDEX user_signals_user_id_idx     ON user_signals(user_id);


-- ── taxonomy_nodes (ED-03 §2) ───────────────────────────────────────────────
-- New taxonomy nodes are data (loaded from db/seeds/), not code changes.
CREATE TABLE taxonomy_nodes (
    taxonomy_id  UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    world_anchor TEXT NOT NULL CHECK (world_anchor IN ('profession', 'skill', 'business')),
    parent_id    UUID REFERENCES taxonomy_nodes(taxonomy_id),
    name         TEXT NOT NULL,
    level        INT NOT NULL
);

CREATE INDEX taxonomy_nodes_world_anchor_idx ON taxonomy_nodes(world_anchor);
CREATE INDEX taxonomy_nodes_parent_id_idx    ON taxonomy_nodes(parent_id);


-- ── coverage_gaps (ED-02 §3) ────────────────────────────────────────────────
CREATE TABLE coverage_gaps (
    gap_id                UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    query_text            TEXT NOT NULL,
    knowledge_universe_id TEXT NOT NULL,
    detected_at           TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    resolution_status     gap_resolution_status NOT NULL DEFAULT 'open'
);

CREATE INDEX coverage_gaps_universe_status_idx
    ON coverage_gaps(knowledge_universe_id, resolution_status);


-- ── authority_weights (ED-04 §2, §7) ────────────────────────────────────────
-- (claim_type, source_type, jurisdiction) → weight.
-- Jurisdiction is a required lookup key — not just claim type (ED-04 §7).
CREATE TABLE authority_weights (
    weight_id    UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    claim_type   TEXT NOT NULL,
    source_type  source_type NOT NULL,
    jurisdiction TEXT NOT NULL DEFAULT 'GLOBAL',
    weight       FLOAT NOT NULL CHECK (weight >= 0 AND weight <= 1),
    UNIQUE (claim_type, source_type, jurisdiction)
);


-- ── freshness_policies (ED-04 §6) ───────────────────────────────────────────
-- resources.freshness_cadence_override (ED-01 §1.1) overrides per-resource;
-- absent an override, the resource's domain classification looks up here.
CREATE TABLE freshness_policies (
    policy_id       UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    domain_type     TEXT NOT NULL UNIQUE,
    default_cadence INTERVAL,
    rationale       TEXT
);


-- ── review_queue (ED-04 §9) ─────────────────────────────────────────────────
-- Every ED that needs a human-in-the-loop hook writes to this single table.
-- Every Medicine resource MUST get a sensitive_domain row at pipeline stage 7
-- (LD-02 §2 — no exceptions, no "this one's obviously fine" shortcuts).
CREATE TABLE review_queue (
    review_id    UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    subject_type TEXT NOT NULL,
    subject_id   UUID NOT NULL,
    reason_code  review_reason_code NOT NULL,
    status       review_status NOT NULL DEFAULT 'open',
    assigned_to  UUID,
    resolution   TEXT,
    created_at   TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    resolved_at  TIMESTAMPTZ
);

CREATE INDEX review_queue_status_reason_idx ON review_queue(status, reason_code);
CREATE INDEX review_queue_subject_idx       ON review_queue(subject_type, subject_id);


-- ── training_examples (ED-13 §1.1) ──────────────────────────────────────────
-- MUST NOT weight unverified examples equally with verified_successful ones.
-- outcome_quality = verified_successful requires the same evidence/review
-- mechanism as ED-04 §11 — not just engagement volume (ED-13 §1.1 MUST NOT).
CREATE TABLE training_examples (
    example_id      UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    question_type   TEXT,
    context         JSONB,
    concepts        UUID[],
    resource_path   UUID[],
    outcome_quality training_outcome_quality NOT NULL DEFAULT 'unverified',
    provenance      UUID REFERENCES evidence(evidence_id),
    created_at      TIMESTAMPTZ NOT NULL DEFAULT NOW()
);


-- ── model_registry (ED-13 §5.1) ─────────────────────────────────────────────
-- MUST NOT: candidate → active promotion for orchestration/synthesis without
-- passing ED-04 §3's evidence-before-confidence gate.
CREATE TABLE model_registry (
    model_id           UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    provider           TEXT NOT NULL,
    version            TEXT NOT NULL,
    role               model_role NOT NULL,
    status             model_status NOT NULL DEFAULT 'candidate',
    evaluation_metrics JSONB,
    promoted_at        TIMESTAMPTZ,
    deprecated_at      TIMESTAMPTZ
);


-- ── learning_loop_events (ED-12 §2.1) ───────────────────────────────────────
-- Derived/reporting table only — proves the loop actually closes (gap → resource
-- served), never feeds back into trust_state or ranking directly.
CREATE TABLE learning_loop_events (
    event_id        UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    loop_stage      loop_stage NOT NULL,
    coverage_gap_id UUID NOT NULL REFERENCES coverage_gaps(gap_id),
    resource_id     UUID REFERENCES resources(resource_id),
    occurred_at     TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

CREATE INDEX learning_loop_events_gap_id_idx ON learning_loop_events(coverage_gap_id);


-- ── global_expansion_metrics (ED-11 §6) ─────────────────────────────────────
-- Reporting table computed from sources / coverage_gaps / ranking logs.
-- No write path into resources or trust_state (Doc 9 §9 engagement-isn't-truth rule).
CREATE TABLE global_expansion_metrics (
    metric_id                     UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    jurisdiction                  TEXT NOT NULL,
    language                      TEXT NOT NULL,
    period_start                  DATE NOT NULL,
    period_end                    DATE NOT NULL,
    active_sources_count          INT NOT NULL DEFAULT 0,
    coverage_gaps_open            INT NOT NULL DEFAULT 0,
    coverage_gaps_resolved        INT NOT NULL DEFAULT 0,
    avg_local_applicability_score FLOAT,
    query_volume                  INT NOT NULL DEFAULT 0,
    UNIQUE (jurisdiction, language, period_start, period_end)
);


-- ── Seed: information_forms — 5 initial rows (ED-12 §1.1) ───────────────────
-- form_id values must match InformationFormSeed in core/enums.py exactly.
INSERT INTO information_forms (form_id, display_name, status, introduced_at) VALUES
    ('video',                  'Video',                 'active', '2026-09-15'),
    ('shorts',                 'Shorts',                'active', '2026-09-15'),
    ('audio',                  'Audio',                 'active', '2026-09-15'),
    ('written',                'Written',               'active', '2026-09-15'),
    ('structured_interactive', 'Structured/Interactive','active', '2026-09-15');


-- ── Seed: freshness_policies (ED-04 §6 table) ───────────────────────────────
INSERT INTO freshness_policies (domain_type, default_cadence, rationale) VALUES
    ('foundational_knowledge', NULL,          'Durable concepts do not expire'),
    ('regulation',             '90 days',     'Rules change; track versions. Re-check on schedule.'),
    ('market_statistics',      '30 days',     'Numbers go stale fast'),
    ('medical_guidelines',     '60 days',     'Safety-relevant, revised periodically (Doc 9 §13)');


COMMIT;
