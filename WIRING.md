# WIRING.md — Rumuo Production Setup

Two Vercel projects deployed. One Supabase project already seeded.
Everything is live once you set the environment variables below.

---

## Deployed URLs

| Project | Purpose | URL |
|---|---|---|
| `rumuo-api` | Experience API (Flutter calls this) | `https://rumuo-api-ch-as-technologies-llc.vercel.app` |
| `rumuo-review` | Reviewer queue console (internal) | `https://rumuo-review-ch-as-technologies-llc.vercel.app` |

---

## Step 1 — Set environment variables in Vercel

Open your Vercel dashboard → each project → Settings → Environment Variables.

### rumuo-api (experience API)

| Variable | Value | Where to get it |
|---|---|---|
| `DATABASE_URL` | `postgresql+asyncpg://postgres.awopxbiehutbghxylfzv:[PASSWORD]@aws-0-eu-west-1.pooler.supabase.com:6543/postgres` | Supabase dashboard → Settings → Database → **Transaction pooler** connection string (port 6543, NOT 5432) |
| `SERVERLESS` | `1` | Fixed value |
| `ANTHROPIC_API_KEY` | `sk-ant-...` | console.anthropic.com |
| `DB_ECHO` | `false` | Fixed value |

### rumuo-review (review console)

| Variable | Value | Where to get it |
|---|---|---|
| `DATABASE_URL` | Same as above | Same Supabase project |
| `SERVERLESS` | `1` | Fixed value |
| `REVIEWER_TOKEN` | Any strong secret string | You choose — share only with reviewers |

After setting env vars → redeploy each project (Vercel dashboard → Deployments → Redeploy).

---

## Step 2 — Verify the API is live

```bash
curl https://rumuo-api-ch-as-technologies-llc.vercel.app/health
# → {"status": "ok", "service": "rumuo-api"}

curl "https://rumuo-api-ch-as-technologies-llc.vercel.app/api/resources?country=NG"
# → {"data": [], "meta": {...}}  ← empty until resources are indexed
```

---

## Step 3 — Build the Flutter app pointing to the live API

In your Flutter build command, add `--dart-define`:

```bash
# Android debug
flutter run --dart-define=RUMUO_API_BASE_URL=https://rumuo-api-ch-as-technologies-llc.vercel.app/api/resources

# Android release APK
flutter build apk --release \
  --dart-define=RUMUO_API_BASE_URL=https://rumuo-api-ch-as-technologies-llc.vercel.app/api/resources

# Web
flutter build web --release \
  --dart-define=RUMUO_API_BASE_URL=https://rumuo-api-ch-as-technologies-llc.vercel.app/api/resources
```

No Flutter source code changes needed — `AppConfig.resourceApiBaseUrl` already reads from `--dart-define`.

---

## Step 4 — Verify the review console

```bash
curl https://rumuo-review-ch-as-technologies-llc.vercel.app/health
# → {"status": "ok", "service": "rumuo-review"}

curl https://rumuo-review-ch-as-technologies-llc.vercel.app/queue \
  -H "X-Reviewer-Token: YOUR_REVIEWER_TOKEN"
# → [] (empty until Medicine resources are indexed and reach stage 7)
```

---

## Step 5 — Set a custom domain (optional, recommended)

In Vercel dashboard → Project → Settings → Domains:
- `api.rumuo.com` → point to `rumuo-api`
- `review.rumuo.com` → point to `rumuo-review`

Then update the Flutter `--dart-define` to use the custom domain.

---

## What's already live in Supabase

| Table | Rows |
|---|---|
| `taxonomy_nodes` | 48 (Medicine/Nigeria tree) |
| `questions` | 6 (seed questions incl. standing test) |
| `authority_weights` | 30 (jurisdiction=Nigeria) |
| `information_forms` | 5 (video, shorts, audio, written, structured_interactive) |
| `freshness_policies` | 4 (domain cadences) |
| `training_examples` | 1 (Doctor/Nigeria standing test) |
| `resources` | 0 — Phase A acquisition starts here |

RLS is enabled. The experience API uses the Supabase **transaction pooler** (port 6543),
which is required for serverless functions. Do not use the direct connection (port 5432)
for the Vercel functions.

---

## Unblocking Phase A acquisition

Once the API is verified working end-to-end:
1. Founder confirms `agents/researcher/config/medicine_nigeria.yaml` §3 allocation ← **still the hard blocker**
2. Set `ACQUISITION_ACTIVE=1` in `.env` (local only — never in Vercel)
3. Run: `python scripts/seed_medicine_nigeria.py --confirm`
4. Run the researcher agent locally against Phase A institution sources
5. Resources will appear in the API once they complete the 13-stage pipeline

---

## Supabase project reference

- Project: `Rumuo`
- Project ID: `awopxbiehutbghxylfzv`
- Region: `eu-west-1`
- URL: `https://awopxbiehutbghxylfzv.supabase.co`
- Migrations applied: `initial_schema` (18 tables), `rls_policies` (RLS on all tables)
