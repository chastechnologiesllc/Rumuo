# rumuo-platform

Python/FastAPI backend for the Rumuo platform.
First vertical pilot: **Medicine, Nigeria, targeting 100,000 indexed sources.**

**Authority:** Founder's Documents > Engineering Directives (EDs) > Execution Playbooks (LDs).
When anything here conflicts with an ED or LD, flag it — do not silently resolve it.

---

## First commands, in order

**Step 0 (required before anything else):** Read and follow `Rumuo_Coder_Kickoff_Prompt.md`.

```bash
# 1. Install dependencies
pip install -r requirements.txt

# 2. Set environment
cp .env.example .env
# → Fill in DATABASE_URL from Supabase dashboard

# 3. Apply the schema (once, against a fresh Supabase project)
psql "$DATABASE_URL" < db/migrations/001_initial_schema.sql

# 4. Confirm the 18 tables exist
#    (See infra/supabase/README.md)

# 5. Get founder sign-off on LD-01 §3 source allocation — HARD BLOCKER
#    before running step 6. Do not skip.

# 6. Seed Medicine/Nigeria pilot data (requires --confirm flag)
python scripts/seed_medicine_nigeria.py --confirm

# 7. Start the experience API (what the Flutter app calls)
uvicorn services.experience_api.main:app --port 8000 --reload

# 8. Start the review console (reviewer-only internal tool)
REVIEWER_TOKEN=... uvicorn services.trust.review_console.main:app --port 8001 --reload

# 9. Run the DoD test suite
pytest tests/pipeline_e2e/ -v
```

---

## Service map

| Service | Port | Owning ED | Purpose |
|---|---|---|---|
| `services/experience_api` | 8000 | ED-07 | Flutter app endpoint (`/api/resources`) |
| `services/trust/review_console` | 8001 | ED-04 §9 | Human reviewer queue tool |
| `services/ingestion` | — | ED-01 §3 | 13-stage ingestion pipeline (stub) |
| `services/taxonomy` | — | ED-03 | Taxonomy CRUD (stub) |
| `services/ranking` | — | ED-05/06 | Ranking and orchestration (stub) |
| `services/acquisition` | — | ED-02 | Source discovery (stub) |
| `agents/researcher` | — | LD-01 | Content acquisition (BLOCKED — see §5 below) |
| `agents/organizer` | — | LD-02 §3 | Review handoff and routing |

---

## Hard constraints (from kickoff prompt — violating any is a defect)

- Enum values exactly as spelled in `core/enums.py` — never rename or invent one.
- `ai_assessed` is a valid, fully automated resting state for Medicine. Do not block serving on it.
- Every Medicine resource gets a `sensitive_domain` `review_queue` row at pipeline stage 7 — no exceptions.
- Only a resolved `review_queue` row with `resolution='approved'` can move a resource to `verified`.
- Never touch `trust_state` transition edge logic as a side effect of unrelated work — always flag first.
- Never bypass authentication, paywalls, or platform access protections to acquire content.
- Taxonomy and seed data are YAML files (`db/seeds/`) — never hard-coded in application logic.
- The commercial service and ranking service never share a write path (ED-04 §12).
- **Do not begin any Researcher/acquisition activity — even a test run — until the founder has explicitly signed off on LD-01 §3 allocation.**

---

## What's been built (Session 1)

| Layer | File | Status |
|---|---|---|
| Schema | `db/migrations/001_initial_schema.sql` | ✅ 18 tables, all enums |
| Seeds | `db/seeds/medicine_nigeria/*.yaml` | ✅ copied from docs |
| Enums | `core/enums.py` | ✅ copied from docs skeleton |
| DB connection | `core/db.py` | ✅ |
| ORM models | `core/models/*.py` | ✅ all 18 tables |
| Trust state machine | `services/trust/state_machine.py` | ✅ ED-04 §11 edges |
| Review queue CRUD | `services/trust/review_queue.py` | ✅ |
| Review console | `services/trust/review_console/main.py` | ✅ FastAPI |
| Experience API | `services/experience_api/main.py` | ✅ FastAPI |
| Subcategory map | `services/experience_api/subcategory_map.py` | ✅ Flutter slug → form_id |
| API schemas | `services/experience_api/schemas.py` | ✅ aligned with Flutter |
| API queries | `services/experience_api/queries.py` | ✅ exact-match-first |
| Organizer agent | `agents/organizer/review_handoff.py` | ✅ |
| Seed script | `scripts/seed_medicine_nigeria.py` | ✅ |
| DoD tests | `tests/pipeline_e2e/test_ed01_dod.py` | ✅ |
| DoD tests | `tests/pipeline_e2e/test_ld02_dod.py` | ✅ |

## What comes next (Session 2)

1. `services/ingestion/pipeline.py` — wire the 13 pipeline stages (ED-01 §3)
2. `services/taxonomy/crud.py` — taxonomy lookup and traversal
3. Flutter app config update — point `RUMUO_API_BASE_URL` to the new FastAPI endpoint
4. Supabase RLS rules for `user_signals` and `review_queue`
5. `agents/researcher/` stubs — **only after founder signs off on LD-01 §3**
