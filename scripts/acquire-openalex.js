const { Pool } = require('pg');

const TARGET = Number(process.env.TARGET_COUNT || 20000);
const PAGE_SIZE = 200;
const CONCURRENCY = Number(process.env.CHECK_CONCURRENCY || 20);
const API = 'https://api.openalex.org/works';
const pool = new Pool({ connectionString: process.env.DATABASE_URL, max: 4, ssl: { rejectUnauthorized: false } });

function normalizeUrl(raw) {
  if (!raw) return null;
  try {
    const url = new URL(raw);
    if (!['http:', 'https:'].includes(url.protocol)) return null;
    url.hash = '';
    url.search = '';
    url.hostname = url.hostname.toLowerCase();
    if (url.pathname.length > 1) url.pathname = url.pathname.replace(/\/+$/, '');
    return url.toString();
  } catch { return null; }
}

function domainOf(url) { return new URL(url).hostname.replace(/^www\./, ''); }
function titleOf(work) { return (work.title || '').trim().slice(0, 500); }
function abstractOf(work) {
  const inverted = work.abstract_inverted_index || {};
  return Object.entries(inverted).sort((a, b) => Math.min(...a[1]) - Math.min(...b[1])).map(([word]) => word).join(' ').slice(0, 2000) || null;
}
function sourceUrl(work) {
  return normalizeUrl(work.primary_location?.landing_page_url || work.primary_location?.pdf_url || work.doi || null);
}

async function reachable(url) {
  try {
    const response = await fetch(url, { method: 'HEAD', redirect: 'follow', signal: AbortSignal.timeout(10000) });
    return { ok: response.status >= 200 && response.status < 400, status: response.status, finalUrl: normalizeUrl(response.url) || url };
  } catch {
    try {
      const response = await fetch(url, { method: 'GET', redirect: 'follow', headers: { Range: 'bytes=0-1024' }, signal: AbortSignal.timeout(10000) });
      return { ok: response.status >= 200 && response.status < 400, status: response.status, finalUrl: normalizeUrl(response.url) || url };
    } catch { return { ok: false, status: 0, finalUrl: url }; }
  }
}

async function insertBatch(client, rows) {
  if (!rows.length) return;
  const values = [];
  const placeholders = rows.map((row, i) => {
    const offset = i * 12;
    values.push(row.url, domainOf(row.url), row.title, row.description, 'research', 'computer_science', row.publisher, 'openalex', 'en', row.origin, true, row.url);
    return `($${offset + 1},$${offset + 2},$${offset + 3},$${offset + 4},$${offset + 5},$${offset + 6},$${offset + 7},$${offset + 8},$${offset + 9},$${offset + 10},$${offset + 11},$${offset + 12})`;
  });
  await client.query(`insert into sources(canonical_url,domain,title,description,source_type,subject,publisher,discovered_from,language_code,origin_jurisdiction,global_relevance,provenance_url) values ${placeholders.join(',')} on conflict(canonical_url) do nothing`, values);
}

async function run() {
  if (!process.env.DATABASE_URL) throw new Error('DATABASE_URL is required');
  const client = await pool.connect();
  let cursor = '*'; let discovered = 0; let inserted = 0; let rejected = 0; const seen = new Set();
  try {
    const job = await client.query("insert into acquisition_jobs(subject,jurisdiction_code,language_code,query,status,target_count,source_policy) values ('computer_science','GLOBAL','en','OpenAlex global Computer Science works','running',$1,'Candidates are normalized, deduplicated, reachability-checked, and stored as discovered/reachable. Publication requires separate evidence review.') returning id", [TARGET]);
    const jobId = job.rows[0].id;
    while (discovered < TARGET) {
      const url = `${API}?filter=concepts.id:C41008148&per-page=${PAGE_SIZE}&cursor=${encodeURIComponent(cursor)}&mailto=research@rumuo.app`;
      const page = await (await fetch(url, { signal: AbortSignal.timeout(30000) })).json();
      const works = page.results || [];
      if (!works.length) break;
      const candidates = works.map((work) => ({ work, url: sourceUrl(work) })).filter((item) => item.url && !seen.has(item.url) && titleOf(item.work));
      candidates.forEach((item) => seen.add(item.url));
      for (let i = 0; i < candidates.length; i += CONCURRENCY) {
        const checked = await Promise.all(candidates.slice(i, i + CONCURRENCY).map(async ({ work, url: originalUrl }) => {
          const result = await reachable(originalUrl);
          if (!result.ok) return null;
          return { url: result.finalUrl, title: titleOf(work), description: abstractOf(work), publisher: work.host_venue?.publisher || work.primary_location?.source?.display_name || null, origin: 'GLOBAL' };
        }));
        const rows = checked.filter(Boolean);
        await insertBatch(client, rows);
        discovered += rows.length;
        inserted += rows.length;
        rejected += checked.length - rows.length;
        process.stdout.write(`progress job=${jobId} discovered=${discovered} inserted=${inserted} rejected=${rejected}\n`);
        if (discovered >= TARGET) break;
      }
      cursor = page.meta?.next_cursor;
      if (!cursor) break;
    }
    await client.query('update acquisition_jobs set status=$1, discovered_count=$2, verified_count=0, rejected_count=$3, completed_at=now() where id=$4', ['completed', inserted, rejected, jobId]);
    console.log(JSON.stringify({ jobId, target: TARGET, discovered: inserted, rejected, published: 0 }));
  } finally { client.release(); await pool.end(); }
}
run().catch((error) => { console.error(error); process.exit(1); });
