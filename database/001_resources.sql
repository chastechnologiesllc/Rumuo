create table if not exists resources (
  id text primary key,
  subject text not null,
  title text not null,
  summary text not null,
  url text not null,
  content_type text not null,
  subcategory_id text not null,
  publisher text not null,
  region text not null default 'global',
  license text,
  trust_state text not null check (trust_state in ('unreviewed','ai_assessed','verified','rejected','deprecated')),
  provenance_url text not null,
  verified_at timestamptz,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now(),
  deleted_at timestamptz
);
create index if not exists resources_subject_trust_idx on resources(subject, trust_state, subcategory_id);

insert into resources (id, subject, title, summary, url, content_type, subcategory_id, publisher, region, license, trust_state, provenance_url, verified_at)
values
('cs50x-harvard','computer_science','CS50x: Introduction to Computer Science','Harvard’s introductory computer science course covering algorithms, data structures, software engineering, and web programming.','https://cs50.harvard.edu/x/','course','videos_long_form','Harvard University','global','Free to audit','verified','https://cs50.harvard.edu/x/','2026-09-14T00:00:00Z'),
('mit-ocw-6001','computer_science','Structure and Interpretation of Computer Programs','MIT OpenCourseWare lecture materials on programming, abstraction, data, and computational problem solving.','https://ocw.mit.edu/courses/6-001-structure-and-interpretation-of-computer-programs-fall-2005/','course','written_papers','MIT OpenCourseWare','global','Open course materials','verified','https://ocw.mit.edu/courses/6-001-structure-and-interpretation-of-computer-programs-fall-2005/','2026-09-14T00:00:00Z'),
('openstax-cs','computer_science','Introduction to Computer Science','An open textbook-style introduction to the foundations and applications of computer science.','https://openstax.org/subjects/computer-science','book','written_books','OpenStax','global','Open educational resources','verified','https://openstax.org/subjects/computer-science','2026-09-14T00:00:00Z')
on conflict (id) do update set title=excluded.title, summary=excluded.summary, url=excluded.url, updated_at=now(), deleted_at=null;
