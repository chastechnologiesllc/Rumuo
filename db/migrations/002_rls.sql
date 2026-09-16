-- 002_rls.sql
-- Row Level Security rules for Rumuo.
-- Applied after 001_initial_schema.sql.
-- Per LD-03 §9: RLS must be in place before any external traffic.
-- MUST NOT: edit after merge — write 003_ for changes.

BEGIN;

-- ── resources: public read for servable trust states ─────────────────────────
ALTER TABLE resources ENABLE ROW LEVEL SECURITY;
CREATE POLICY resources_public_read ON resources
    FOR SELECT USING (
        trust_state IN (
            'ai_assessed', 'evidence_supported', 'verified', 'authoritative_official'
        )
    );

-- ── sources: public read ──────────────────────────────────────────────────────
ALTER TABLE sources ENABLE ROW LEVEL SECURITY;
CREATE POLICY sources_public_read ON sources FOR SELECT USING (true);

-- ── user_signals: users own only their own rows ───────────────────────────────
-- auth.uid() is Supabase's built-in; replace with your own auth scheme if needed.
ALTER TABLE user_signals ENABLE ROW LEVEL SECURITY;
CREATE POLICY user_signals_own_rows ON user_signals
    FOR ALL USING (user_id = auth.uid());

-- ── review_queue: reviewers-only (service-role key bypasses RLS for backend) ─
-- Public JWT users cannot read or write review_queue rows at all.
-- The review console uses the Supabase service-role key, which bypasses RLS.
ALTER TABLE review_queue ENABLE ROW LEVEL SECURITY;
CREATE POLICY review_queue_no_public_access ON review_queue
    FOR ALL USING (false);   -- deny all public access; service-role bypasses this

-- ── relationships, evidence, taxonomy_nodes: public read ─────────────────────
ALTER TABLE relationships ENABLE ROW LEVEL SECURITY;
CREATE POLICY relationships_public_read ON relationships FOR SELECT USING (true);

ALTER TABLE evidence ENABLE ROW LEVEL SECURITY;
CREATE POLICY evidence_public_read ON evidence FOR SELECT USING (true);

ALTER TABLE taxonomy_nodes ENABLE ROW LEVEL SECURITY;
CREATE POLICY taxonomy_nodes_public_read ON taxonomy_nodes FOR SELECT USING (true);

ALTER TABLE questions ENABLE ROW LEVEL SECURITY;
CREATE POLICY questions_public_read ON questions FOR SELECT USING (true);

ALTER TABLE information_forms ENABLE ROW LEVEL SECURITY;
CREATE POLICY information_forms_public_read ON information_forms FOR SELECT USING (true);

ALTER TABLE authority_weights ENABLE ROW LEVEL SECURITY;
CREATE POLICY authority_weights_public_read ON authority_weights FOR SELECT USING (true);

-- ── Backend-write tables: no public access (service-role only) ───────────────
ALTER TABLE coverage_gaps ENABLE ROW LEVEL SECURITY;
CREATE POLICY coverage_gaps_no_public ON coverage_gaps FOR ALL USING (false);

ALTER TABLE learning_loop_events ENABLE ROW LEVEL SECURITY;
CREATE POLICY learning_loop_events_no_public ON learning_loop_events FOR ALL USING (false);

ALTER TABLE training_examples ENABLE ROW LEVEL SECURITY;
CREATE POLICY training_examples_no_public ON training_examples FOR ALL USING (false);

ALTER TABLE model_registry ENABLE ROW LEVEL SECURITY;
CREATE POLICY model_registry_no_public ON model_registry FOR ALL USING (false);

COMMIT;
