# Vercel Setup Guide — Rumuo API

You've deployed the project from GitHub. It needs three things configured
in the Vercel dashboard before it works. This takes about 5 minutes.

---

## Step 1 — Set environment variables

**Vercel dashboard → your Rumuo project → Settings → Environment Variables**

Add these five variables. Set each one for **Production**, **Preview**, and **Development**.

| Variable | Value |
|---|---|
| `DATABASE_URL` | See below |
| `SERVERLESS` | `1` |
| `ANTHROPIC_API_KEY` | `sk-ant-api03-...` (from console.anthropic.com) |
| `REVIEWER_TOKEN` | Any strong secret string you choose (for the review console) |
| `DB_ECHO` | `false` |

### Getting DATABASE_URL

1. Go to **supabase.com → Project `awopxbiehutbghxylfzv` → Settings → Database**
2. Scroll to **Connection string**
3. Select the **Transaction pooler** tab (NOT the direct connection tab)
4. Copy the URI — it looks like:
   `postgresql://postgres.awopxbiehutbghxylfzv:[YOUR-PASSWORD]@aws-0-eu-west-1.pooler.supabase.com:6543/postgres`
5. Change `postgresql://` to `postgresql+asyncpg://` at the start
6. Final value:
   `postgresql+asyncpg://postgres.awopxbiehutbghxylfzv:[YOUR-PASSWORD]@aws-0-eu-west-1.pooler.supabase.com:6543/postgres`

**Why transaction pooler (port 6543)?** Vercel functions are serverless — they spin up fresh
for every request. The direct connection (port 5432) doesn't work at scale in serverless;
the transaction pooler handles connection management properly.

---

## Step 2 — Check build & output settings

**Vercel dashboard → your Rumuo project → Settings → General → Build & Output Settings**

Leave all settings as **blank / default**. Vercel reads `vercel.json` from the repo root
and configures itself automatically. Do NOT set a custom build command or output directory.

If it shows a framework preset (e.g. "Other" or "Node.js") — that's fine, leave it.

---

## Step 3 — Redeploy

After setting env vars:

**Vercel dashboard → your Rumuo project → Deployments → (latest) → ··· → Redeploy**

The build takes about 60–90 seconds. When it goes green, verify:

```bash
curl https://YOUR-PROJECT.vercel.app/health
# → {"status": "ok", "service": "rumuo-api"}

curl "https://YOUR-PROJECT.vercel.app/api/resources?country=NG&limit=5"
# → {"data": [], "meta": {...}}   ← empty until Phase A acquisition runs

curl https://YOUR-PROJECT.vercel.app/review/health \
  -H "X-Reviewer-Token: YOUR_REVIEWER_TOKEN"
# → {"status": "ok", "service": "rumuo-review"}
```

---

## Step 4 — Wire the Flutter app

In your Flutter build command, add one `--dart-define` flag pointing at your Vercel URL:

```bash
# Development
flutter run \
  --dart-define=RUMUO_API_BASE_URL=https://YOUR-PROJECT.vercel.app/api/resources

# Release APK
flutter build apk --release \
  --dart-define=RUMUO_API_BASE_URL=https://YOUR-PROJECT.vercel.app/api/resources

# Web (GitHub Pages)
flutter build web --release \
  --base-href "/Rumuo/" \
  --dart-define=RUMUO_API_BASE_URL=https://YOUR-PROJECT.vercel.app/api/resources
```

No Flutter source code changes needed — `AppConfig.resourceApiBaseUrl` already reads
from `--dart-define`.

---

## If the build fails

The most common causes and fixes:

| Error | Fix |
|---|---|
| `ModuleNotFoundError: No module named 'services'` | Root directory is wrong — check Vercel project Settings → General → Root Directory is blank (not `frontend/`) |
| `Runtime Error: DATABASE_URL not set` | Env vars weren't set or weren't redeployed after setting them |
| Build timeout | `requirements.txt` is being fully installed — normal on first deploy, subsequent deploys cache it |
| `500` on `/api/resources` | Check runtime logs in Vercel dashboard → Logs tab for the specific Python error |

---

## What's live in Supabase (project `awopxbiehutbghxylfzv` · eu-west-1)

All tables, RLS, and seed data are already applied:
- ✅ 18 tables with RLS enabled
- ✅ 48 taxonomy nodes (Medicine/Nigeria tree)
- ✅ 6 seed questions
- ✅ 30 authority weights (jurisdiction=Nigeria)
- ✅ 5 information forms (video, shorts, audio, written, structured_interactive)
- ✅ 4 freshness policies
- ✅ 1 standing test training example

The API will return `data: []` (empty) until Phase A acquisition runs. That's correct —
the infrastructure is ready; it just needs content indexed through the 13-stage pipeline.
