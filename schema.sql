-- Clinician AI Habits Check: anonymous, opt-in responses.
-- The public page may INSERT only. Nobody can read rows through the public API; David reads them in the Supabase dashboard.

create table public.responses (
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

comment on table public.responses is 'Anonymous opt-in quiz responses. No identifiers, no timestamps finer than month.';

alter table public.responses enable row level security;

-- Public visitors may add a row and nothing else. The month is always set by the database, never by the visitor.
revoke all on public.responses from anon, authenticated;
grant insert (answers, levels, role, main_tool, framework_version) on public.responses to anon;

create policy "anonymous insert only"
  on public.responses for insert
  to anon
  with check (true);

-- Aggregate view for David (dashboard / SQL editor only; not exposed to anon).
create view public.responses_summary with (security_invoker = true) as
select month,
       count(*) as n,
       round(avg(levels[1]), 2) as d1_delegation,
       round(avg(levels[2]), 2) as d2_description,
       round(avg(levels[3]), 2) as d3_discernment,
       round(avg(levels[4]), 2) as d4_iteration,
       round(avg(levels[5]), 2) as d5_workflow,
       round(avg(levels[6]), 2) as d6_safety
from public.responses
group by month
order by month;

revoke all on public.responses_summary from anon, authenticated;

-- Anonymous counters: one row per quiz start or completion (added October 2026).
create table public.events (
  id     bigint generated always as identity primary key,
  month  date not null default (date_trunc('month', now() at time zone 'utc'))::date,
  event  text not null,
  constraint event_values check (event in ('start','complete'))
);
alter table public.events enable row level security;
revoke all on public.events from anon, authenticated;
grant insert (event) on public.events to anon;
create policy "anonymous insert only" on public.events for insert to anon with check (true);

-- Monthly funnel for David: started, completed, opted in.
create view public.funnel_summary with (security_invoker = true) as
select m.month,
       coalesce(sum((e.event = 'start')::int), 0)    as started,
       coalesce(sum((e.event = 'complete')::int), 0) as completed,
       (select count(*) from public.responses r where r.month = m.month) as opted_in
from (select month from public.events union select month from public.responses) m
left join public.events e on e.month = m.month
group by m.month
order by m.month;
revoke all on public.funnel_summary from anon, authenticated;
