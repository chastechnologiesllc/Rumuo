# Migration authoring checklist — read before writing 001_initial_schema.sql

**Why this file exists instead of a finished migration:** the exact field-by-field
schema lives in the ED documents themselves (docs/02_Engineering_Directives/). This
repo skeleton ships verified enums (core/enums.py, transcribed word-for-word from
the ED text) but does NOT ship a fabricated CREATE TABLE for every table — writing
DDL from partial memory of a spec is exactly the kind of silent-drift risk LD-03 §7
exists to prevent ("the ED text is the contract"). Write the migration by reading
each cited section directly, not from this checklist's paraphrase of it.

## Tables to create, and where their exact fields live

| Table | Exact fields specified in |
|---|---|
| `resources` | ED-01 §1.1 |
| `sources` | ED-01 §1.2 |
| `questions` | ED-01 §1.4 (seeded per ED-03 §4, LD-01 §4) |
| `entities` | ED-01 §1.3 |
| `relationships` | ED-01 §1.6, amended ED-03 §6 (confidence_state) |
| `taxonomy_nodes` | ED-03 §2 |
| `coverage_gaps` | ED-02 §3 |
| `authority_weights` | ED-04 §2, §7 |
| `review_queue` | ED-04 §9 |
| `freshness_policies` | ED-04 §6 |
| `information_forms` | ED-12 §1.1 |
| `training_examples` | ED-13 §1.1 |
| `model_registry` | ED-13 §5.1 |
| `learning_loop_events` | ED-12 §2.1 |
| `global_expansion_metrics` | ED-11 §6 |

## Rules while writing it

- Every enum column references `core/enums.py` — do not inline a different value set.
- `resources.type` is a FK into `information_forms.form_id` (ED-12 §1.1), not a bare
  ENUM — this is the one deliberate deviation from a literal reading of ED-01 §1.1,
  and it's specified that way for exactly this reason in ED-12 §1.
- Name this file `001_initial_schema.sql` when written, then follow the
  `YYYYMMDDHHMM_description.sql` convention (LD-03 §7) for every migration after it.
- Never edit a merged migration — write a new one (LD-03 §8 item 5).
