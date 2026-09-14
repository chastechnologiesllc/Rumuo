create extension if not exists pgcrypto;

create table if not exists jurisdictions (
  code text primary key,
  name text not null,
  region text,
  active boolean not null default true
);
create table if not exists languages (
  code text primary key,
  name text not null,
  native_name text,
  active boolean not null default true
);
create table if not exists sources (
  id uuid primary key default gen_random_uuid(),
  canonical_url text not null unique,
  domain text not null,
  title text not null,
  description text,
  source_type text not null,
  subject text not null,
  publisher text,
  discovered_from text,
  language_code text not null references languages(code),
  origin_jurisdiction text references jurisdictions(code),
  global_relevance boolean not null default false,
  local_applicability_score numeric(5,4),
  trust_state text not null default 'discovered' check (trust_state in ('discovered','reachable','ai_assessed','human_review','verified','rejected','deprecated')),
  pipeline_status text not null default 'discovered' check (pipeline_status in ('discovered','normalized','fetched','extracted','classified','assessed','reviewed','published','failed')),
  provenance_url text not null,
  first_seen_at timestamptz not null default now(),
  last_checked_at timestamptz,
  verified_at timestamptz,
  deleted_at timestamptz
);
create index if not exists sources_subject_state_idx on sources(subject, trust_state, pipeline_status);
create index if not exists sources_jurisdiction_language_idx on sources(origin_jurisdiction, language_code, global_relevance);
create index if not exists sources_domain_idx on sources(domain);

create table if not exists source_jurisdictions (
  source_id uuid not null references sources(id) on delete cascade,
  jurisdiction_code text not null references jurisdictions(code),
  applicability_score numeric(5,4),
  applicability_basis text,
  primary key (source_id, jurisdiction_code)
);
create table if not exists source_languages (
  source_id uuid not null references sources(id) on delete cascade,
  language_code text not null references languages(code),
  relation_type text not null default 'original' check (relation_type in ('original','translation','equivalent_concept')),
  primary key (source_id, language_code)
);
create table if not exists verification_events (
  id uuid primary key default gen_random_uuid(),
  source_id uuid not null references sources(id) on delete cascade,
  event_type text not null check (event_type in ('discovered','reachable','metadata_checked','content_checked','human_reviewed','rejected','deprecated')),
  actor_type text not null check (actor_type in ('system','ai','human')),
  evidence_url text,
  evidence_hash text,
  notes text,
  created_at timestamptz not null default now()
);
create index if not exists verification_events_source_idx on verification_events(source_id, created_at desc);
create table if not exists acquisition_jobs (
  id uuid primary key default gen_random_uuid(),
  subject text not null,
  jurisdiction_code text references jurisdictions(code),
  language_code text references languages(code),
  query text not null,
  status text not null default 'queued' check (status in ('queued','running','paused','completed','failed')),
  discovered_count integer not null default 0,
  verified_count integer not null default 0,
  rejected_count integer not null default 0,
  created_at timestamptz not null default now(),
  completed_at timestamptz
);
create table if not exists coverage_gaps (
  id uuid primary key default gen_random_uuid(),
  query_text text not null,
  knowledge_universe_id text not null,
  jurisdiction_code text references jurisdictions(code),
  language_code text references languages(code),
  priority numeric(5,4) not null default 0,
  status text not null default 'open' check (status in ('open','in_progress','resolved','deferred')),
  created_at timestamptz not null default now(),
  resolved_at timestamptz
);
create table if not exists global_expansion_metrics (
  id uuid primary key default gen_random_uuid(),
  jurisdiction_code text not null references jurisdictions(code),
  language_code text not null references languages(code),
  period_start date not null,
  period_end date not null,
  active_sources_count integer not null default 0,
  coverage_gaps_open integer not null default 0,
  coverage_gaps_resolved integer not null default 0,
  avg_local_applicability_score numeric(5,4),
  query_volume integer not null default 0,
  unique (jurisdiction_code, language_code, period_start, period_end)
);

insert into jurisdictions(code,name,region) values ('NG','Nigeria','West Africa'), ('GLOBAL','Global','Global') on conflict do nothing;
insert into languages(code,name,native_name) values ('en','English','English') on conflict do nothing;

insert into sources (canonical_url, domain, title, description, source_type, subject, publisher, discovered_from, language_code, origin_jurisdiction, global_relevance, trust_state, pipeline_status, provenance_url, verified_at)
values
('https://cs50.harvard.edu/x/','cs50.harvard.edu','CS50x: Introduction to Computer Science','Open introductory computer science course covering algorithms, data structures, software engineering, and web programming.','course','computer_science','Harvard University','founder_seed','en','US',true,'verified','published','https://cs50.harvard.edu/x/',now()),
('https://ocw.mit.edu/courses/6-001-structure-and-interpretation-of-computer-programs-fall-2005/','ocw.mit.edu','Structure and Interpretation of Computer Programs','MIT OpenCourseWare course materials on programming, abstraction, data, and computational problem solving.','course','computer_science','MIT OpenCourseWare','founder_seed','en','US',true,'verified','published','https://ocw.mit.edu/courses/6-001-structure-and-interpretation-of-computer-programs-fall-2005',now()),
('https://openstax.org/subjects/computer-science','openstax.org','OpenStax Computer Science','Open educational computer science materials and textbooks.','directory','computer_science','OpenStax','founder_seed','en','US',true,'verified','published','https://openstax.org/subjects/computer-science',now())
on conflict (canonical_url) do update set trust_state='verified', pipeline_status='published', verified_at=excluded.verified_at, deleted_at=null;
