const { Pool } = require('pg');

let pool;
function getPool() {
  if (!process.env.DATABASE_URL) return null;
  pool ??= new Pool({ connectionString: process.env.DATABASE_URL, max: 3, ssl: { rejectUnauthorized: false } });
  return pool;
}

const fallback = [
  {
    id: 'cs50x-harvard', title: 'CS50x: Introduction to Computer Science',
    summary: 'Harvard’s introductory computer science course covering algorithms, data structures, software engineering, and web programming.',
    url: 'https://cs50.harvard.edu/x/', content_type: 'course', subcategory_id: 'videos_long_form',
    publisher: 'Harvard University', region: 'global', license: 'Free to audit', trust_state: 'verified',
    provenance_url: 'https://cs50.harvard.edu/x/', verified_at: '2026-09-14T00:00:00.000Z'
  },
  {
    id: 'mit-ocw-6001', title: 'Structure and Interpretation of Computer Programs',
    summary: 'MIT OpenCourseWare lecture materials on programming, abstraction, data, and computational problem solving.',
    url: 'https://ocw.mit.edu/courses/6-001-structure-and-interpretation-of-computer-programs-fall-2005/', content_type: 'course', subcategory_id: 'written_papers',
    publisher: 'MIT OpenCourseWare', region: 'global', license: 'Open course materials', trust_state: 'verified',
    provenance_url: 'https://ocw.mit.edu/courses/6-001-structure-and-interpretation-of-computer-programs-fall-2005/', verified_at: '2026-09-14T00:00:00.000Z'
  },
  {
    id: 'openstax-cs', title: 'Introduction to Computer Science',
    summary: 'An open textbook-style introduction to the foundations and applications of computer science.',
    url: 'https://openstax.org/subjects/computer-science', content_type: 'book', subcategory_id: 'written_books',
    publisher: 'OpenStax', region: 'global', license: 'Open educational resources', trust_state: 'verified',
    provenance_url: 'https://openstax.org/subjects/computer-science', verified_at: '2026-09-14T00:00:00.000Z'
  }
];

module.exports = async (req, res) => {
  if (req.method !== 'GET') return res.status(405).json({ error: 'method_not_allowed' });
  const { subcategory, q } = req.query || {};
  const query = String(q || '').trim().toLowerCase();
  try {
    const db = getPool();
    let rows;
    if (db) {
      const values = [];
      const clauses = ["subject = 'computer_science'", "trust_state = 'verified'"];
      if (subcategory) { values.push(String(subcategory)); clauses.push(`subcategory_id = $${values.length}`); }
      if (query) { values.push(`%${query}%`); clauses.push(`(lower(title) like $${values.length} or lower(summary) like $${values.length})`); }
      const result = await db.query(`select id, title, summary, url, content_type, subcategory_id, publisher, region, license, trust_state, provenance_url, verified_at from resources where ${clauses.join(' and ')} order by verified_at desc, title asc limit 100`, values);
      rows = result.rows;
    } else {
      rows = fallback.filter((r) => (!subcategory || r.subcategory_id === subcategory) && (!query || `${r.title} ${r.summary}`.toLowerCase().includes(query)));
    }
    return res.status(200).json({ data: rows, meta: { source: db ? 'database' : 'unconfigured', exact_first: true, trust_filter: 'verified' } });
  } catch (error) {
    console.error('resource_query_failed', error);
    return res.status(503).json({ error: 'resource_query_failed' });
  }
};
