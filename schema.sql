-- Clinician AI Habits Check: database schema (Postgres schema `habits`).
-- Loaded on David's VPS with:  docker exec -i api-db psql -U postgres -d api < schema.sql
-- The `habits` schema and the `anon` / `authenticated` roles already exist there.
-- The live database already has these tables: this file is the record for future rebuilds.
-- It is NOT run against Supabase any more.
--
-- Clinician AI Habits Check: anonymous, opt-in responses.
-- The public page may INSERT only. Nobody can read rows through the public API; David reads them directly on the server.

create table habits.responses (
  id                bigint generated always as identity primary key,
  month             date not null default (date_trunc('month', now() at time zone 'utc'))::date,
  answers           smallint[] not null,
  levels            smallint[] not null,
  role              text,
  main_tool         text,
  framework_version text not null default 'v0.2',
  constraint answers_shape check (array_length(answers, 1) = 18 and 1 <= all(answers) and 4 >= all(answers)),
  constraint levels_shape  check (array_length(levels, 1) = 6  and 1 <= all(levels)  and 4 >= all(levels)),
  constraint role_values   check (role is null or role in ('gp','gp_trainee','nurse','pharmacist','paramedic_acp','practice_manager','admin','other')),
  constraint tool_values   check (main_tool is null or main_tool in ('chatgpt','copilot','gemini','claude','several','other')),
  constraint version_short check (length(framework_version) <= 10)
);

comment on table habits.responses is 'Anonymous opt-in quiz responses. No identifiers, no timestamps finer than month.';

alter table habits.responses enable row level security;

-- Public visitors may add a row and nothing else. The month is always set by the database, never by the visitor.
revoke all on habits.responses from anon, authenticated;
grant insert (answers, levels, role, main_tool, framework_version) on habits.responses to anon;

create policy "anonymous insert only"
  on habits.responses for insert
  to anon
  with check (true);

-- Aggregate view for David (dashboard / SQL editor only; not exposed to anon).
create view habits.responses_summary with (security_invoker = true) as
select month,
       count(*) as n,
       round(avg(levels[1]), 2) as d1_delegation,
       round(avg(levels[2]), 2) as d2_description,
       round(avg(levels[3]), 2) as d3_discernment,
       round(avg(levels[4]), 2) as d4_iteration,
       round(avg(levels[5]), 2) as d5_workflow,
       round(avg(levels[6]), 2) as d6_safety
from habits.responses
group by month
order by month;

revoke all on habits.responses_summary from anon, authenticated;

-- Anonymous counters: one row per quiz start or completion (added October 2026).
create table habits.events (
  id     bigint generated always as identity primary key,
  month  date not null default (date_trunc('month', now() at time zone 'utc'))::date,
  event  text not null,
  constraint event_values check (event in ('start','complete'))
);
alter table habits.events enable row level security;
revoke all on habits.events from anon, authenticated;
grant insert (event) on habits.events to anon;
create policy "anonymous insert only" on habits.events for insert to anon with check (true);

-- Monthly funnel for David: started, completed, opted in.
create view habits.funnel_summary with (security_invoker = true) as
select m.month,
       coalesce(sum((e.event = 'start')::int), 0)    as started,
       coalesce(sum((e.event = 'complete')::int), 0) as completed,
       (select count(*) from habits.responses r where r.month = m.month) as opted_in
from (select month from habits.events union select month from habits.responses) m
left join habits.events e on e.month = m.month
group by m.month
order by m.month;
revoke all on habits.funnel_summary from anon, authenticated;
