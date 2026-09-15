# infra/supabase/

## First-time setup

1. Create a new Supabase project at https://app.supabase.com
2. Go to **Project → Settings → Database → Connection string → URI**
   and copy it into `.env` as `DATABASE_URL`.
3. Run the migration from the Supabase SQL editor or via psql:

   ```bash
   psql "$DATABASE_URL" < db/migrations/001_initial_schema.sql
   ```

4. Confirm all 18 tables exist:

   ```sql
   SELECT table_name FROM information_schema.tables
   WHERE table_schema = 'public'
   ORDER BY table_name;
   ```

5. Seed the Medicine/Nigeria pilot data (requires founder sign-off on LD-01 §3 first):

   ```bash
   python scripts/seed_medicine_nigeria.py --confirm
   ```

## Row Level Security (RLS)

RLS is **disabled** in this first build. Before any external traffic:
- Enable RLS on `user_signals` (user data)
- Enable RLS on `review_queue` (reviewer-only access)
- The `resources` and `sources` tables are read-public for the experience API

This is a noted open item — escalate to founder before production launch.
