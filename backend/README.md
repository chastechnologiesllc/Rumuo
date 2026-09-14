# Rumuo backend foundation

This backend is a small Vercel serverless API for the first production content slice: **Computer Science**. It deliberately returns only records with `trust_state = verified` and preserves source provenance, publisher, region, license, and verification time in every response.

## API

`GET /api/resources?subcategory=videos_long_form&q=algorithm`

Response shape:

```json
{"data": [{"id":"...","title":"...","url":"...","trust_state":"verified","provenance_url":"..."}],"meta":{"exact_first":true,"trust_filter":"verified"}}
```

Without `DATABASE_URL`, the function uses the three explicitly seeded, verified records in `api/resources.js`; it does not generate or invent content. With `DATABASE_URL`, it reads from Postgres and the fallback is not used for successful database queries.

## Database

Apply `database/001_resources.sql` to the production Postgres database. Set `DATABASE_URL` in Vercel project environment variables. The schema includes soft deletion (`deleted_at`), provenance, verification timestamps, and an explicit trust-state transition field so privacy and governance are structural rather than UI-only.

## Deployment

From the repository root:

```bash
npm install
npx vercel --prod
```

For Git-based deployment, link the repository to a Vercel project with the root directory set to `/`. The GitHub Flutter workflow remains the client build/deploy path; Vercel serves this API under the same repository.
