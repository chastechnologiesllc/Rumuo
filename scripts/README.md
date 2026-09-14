# Rumuo acquisition workers

`acquire-openalex.js` is the first global Computer Science acquisition worker. It uses the OpenAlex public works API to discover Computer Science works, normalizes canonical URLs, removes duplicates, checks reachability, and stores reachable candidates in `sources` with the default `discovered` trust state. It never marks candidates as verified or publishes them automatically.

Run it in a trusted server environment with the Supabase Postgres connection string:

```bash
DATABASE_URL='...' TARGET_COUNT=20000 node scripts/acquire-openalex.js
```

The worker is resumable at the database-job level and is intentionally separate from human/evidence review. The frontend API serves only `trust_state = verified` and `pipeline_status = published` records.
