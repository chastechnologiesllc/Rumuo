const { Pool } = require('pg');

let pool;
function getPool() {
  if (!process.env.DATABASE_URL) return null;
  pool ??= new Pool({ connectionString: process.env.DATABASE_URL, max: 3, ssl: { rejectUnauthorized: false } });
  return pool;
}

const fallback = [
  { id: 'cs50x-harvard', title: 'CS50x: Introduction to Computer Science', summary: 'Harvard’s introductory computer science course covering algorithms, data structures, software engineering, and web programming.', url: 'https://cs50.harvard.edu/x/', content_type: 'course', publisher: 'Harvard University', region: 'global', license: 'Free to audit', trust_state: 'verified', provenance_url: 'https://cs50.harvard.edu/x/', verified_at: '2026-09-14T00:00:00.000Z', origin_jurisdiction: 'US', language_code: 'en', global_relevance: true },
  { id: 'mit-ocw-6001', title: 'Structure and Interpretation of Computer Programs', summary: 'MIT OpenCourseWare materials on programming, abstraction, data, and computational problem solving.', url: 'https://ocw.mit.edu/courses/6-001-structure-and-interpretation-of-computer-programs-fall-2005/', content_type: 'course', publisher: 'MIT OpenCourseWare', region: 'global', license: 'Open course materials', trust_state: 'verified', provenance_url: 'https://ocw.mit.edu/courses/6-001-structure-and-interpretation-of-computer-programs-fall-2005/', verified_at: '2026-09-14T00:00:00.000Z', origin_jurisdiction: 'US', language_code: 'en', global_relevance: true },
  { id: 'openstax-cs', title: 'OpenStax Computer Science', summary: 'Open educational computer science materials and textbooks.', url: 'https://openstax.org/subjects/computer-science', content_type: 'directory', publisher: 'OpenStax', region: 'global', license: 'Open educational resources', trust_state: 'verified', provenance_url: 'https://openstax.org/subjects/computer-science', verified_at: '2026-09-14T00:00:00.000Z', origin_jurisdiction: 'US', language_code: 'en', global_relevance: true },
];

module.exports = async (req, res) => {
  if (req.method === 'OPTIONS') return res.status(204).end();
  if (req.method !== 'GET') return res.status(405).json({ error: 'method_not_allowed' });
  const { subcategory, q, country, language } = req.query || {};
  const query = String(q || '').trim().toLowerCase();
  try {
    const db = getPool();
    let rows;
    if (db) {
      const values = [];
      const clauses = ["subject = 'computer_science'", "trust_state = 'verified'", "pipeline_status = 'published'", 'deleted_at is null'];
      if (country) { values.push(String(country).toUpperCase()); clauses.push(`(origin_jurisdiction = $${values.length} or global_relevance = true)`); }
      if (language) { values.push(String(language).toLowerCase()); clauses.push(`language_code = $${values.length}`); }
      if (query) { values.push(`%${query}%`); clauses.push(`(lower(title) like $${values.length} or lower(coalesce(description, '')) like $${values.length} or lower(coalesce(publisher, '')) like $${values.length})`); }
      const result = await db.query(`select id::text, title, description as summary, canonical_url as url, source_type as content_type, publisher, coalesce(origin_jurisdiction, 'GLOBAL') as origin_jurisdiction, language_code, global_relevance, 'global' as region, null as license, trust_state, provenance_url, verified_at from sources where ${clauses.join(' and ')} order by global_relevance desc, verified_at desc nulls last, title asc limit 100`, values);
      rows = result.rows;
    } else {
      rows = fallback.filter((r) => (!country || r.origin_jurisdiction === String(country).toUpperCase() || r.global_relevance) && (!language || r.language_code === String(language).toLowerCase()) && (!query || `${r.title} ${r.summary} ${r.publisher}`.toLowerCase().includes(query)));
    }
    return res.status(200).json({ data: rows, meta: { source: db ? 'database' : 'unconfigured', exact_first: true, trust_filter: 'verified', global_sourcing: true, country_filter: country || null, language_filter: language || null } });
  } catch (error) {
    console.error('resource_query_failed', error);
    return res.status(503).json({ error: 'resource_query_failed' });
  }
};
