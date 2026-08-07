-- Fatcamp — Supabase schema
-- Paste the whole file into the Supabase SQL editor and run it once.
--
-- Privacy boundary, which is the important part of this file:
--   lifters   private. You can only ever read your own row.
--   sessions  private. Your training log never leaves your own rows.
--   standings public to signed-in users, but ONLY handle / region / totals.
--             It is written exclusively by a trigger, never by the client, so
--             nobody can post a number they did not earn through sessions.
--
-- The publishable key in the app is meant to be public. These policies are the
-- actual security boundary, not the key.

-- ---------------------------------------------------------------- extensions
create extension if not exists pgcrypto;

-- -------------------------------------------------------------------- tables
create table if not exists public.lifters (
  id         uuid primary key references auth.users on delete cascade,
  handle     text not null unique
             check (handle ~ '^[A-Za-z0-9_]{3,20}$'),
  region     text check (region is null or length(region) <= 40),
  country    text check (country is null or length(country) <= 2),
  created_at timestamptz not null default now()
);

create table if not exists public.sessions (
  id        uuid primary key default gen_random_uuid(),
  lifter    uuid not null references public.lifters on delete cascade,
  done_at   timestamptz not null,
  xp        int  not null check (xp >= 0 and xp <= 20000),
  title     text check (title is null or length(title) <= 60),
  coverage  int  check (coverage between 0 and 100),
  minutes   int  check (minutes between 0 and 600),
  effort    int  check (effort between 1 and 4),
  created_at timestamptz not null default now(),
  unique (lifter, done_at)
);
create index if not exists sessions_lifter_done on public.sessions (lifter, done_at desc);

create table if not exists public.standings (
  lifter     uuid primary key references public.lifters on delete cascade,
  handle     text not null,
  region     text,
  country    text,
  total_xp   bigint not null default 0,
  week_xp    bigint not null default 0,
  streak     int    not null default 0,
  sessions   int    not null default 0,
  updated_at timestamptz not null default now()
);
create index if not exists standings_total on public.standings (total_xp desc);
create index if not exists standings_country on public.standings (country, total_xp desc);
create index if not exists standings_region  on public.standings (region,  total_xp desc);

-- ------------------------------------------------------- standings recompute
-- Totals are derived from sessions, never accepted from the client.
create or replace function public.refresh_standing(p_lifter uuid)
returns void
language plpgsql
security definer
set search_path = public
as $$
declare
  v_total  bigint;
  v_week   bigint;
  v_count  int;
  v_streak int := 0;
  v_prev   date;
  v_day    date;
begin
  select coalesce(sum(xp),0), count(*) into v_total, v_count
    from public.sessions where lifter = p_lifter;

  select coalesce(sum(xp),0) into v_week
    from public.sessions
   where lifter = p_lifter and done_at >= now() - interval '7 days';

  -- streak: distinct training days walking back, allowing one rest day between
  for v_day in
    select distinct (done_at at time zone 'UTC')::date d
      from public.sessions where lifter = p_lifter order by d desc
  loop
    if v_prev is null then
      if v_day < (now() at time zone 'UTC')::date - 2 then exit; end if;
      v_streak := 1;
    elsif v_prev - v_day <= 2 then
      v_streak := v_streak + 1;
    else
      exit;
    end if;
    v_prev := v_day;
  end loop;

  insert into public.standings (lifter, handle, region, country, total_xp, week_xp, streak, sessions, updated_at)
  select p_lifter, l.handle, l.region, l.country, v_total, v_week, v_streak, v_count, now()
    from public.lifters l where l.id = p_lifter
  on conflict (lifter) do update
    set handle = excluded.handle, region = excluded.region, country = excluded.country,
        total_xp = excluded.total_xp, week_xp = excluded.week_xp,
        streak = excluded.streak, sessions = excluded.sessions, updated_at = now();
end;
$$;

create or replace function public.on_session_change()
returns trigger language plpgsql security definer set search_path = public as $$
begin
  perform public.refresh_standing(coalesce(new.lifter, old.lifter));
  return coalesce(new, old);
end; $$;

drop trigger if exists sessions_touch_standing on public.sessions;
create trigger sessions_touch_standing
after insert or update or delete on public.sessions
for each row execute function public.on_session_change();

create or replace function public.on_lifter_change()
returns trigger language plpgsql security definer set search_path = public as $$
begin
  perform public.refresh_standing(new.id);
  return new;
end; $$;

drop trigger if exists lifters_touch_standing on public.lifters;
create trigger lifters_touch_standing
after insert or update on public.lifters
for each row execute function public.on_lifter_change();

-- ------------------------------------------------------------- your position
create or replace function public.my_rank(p_scope text default 'global')
returns int language sql stable security definer set search_path = public as $$
  with me as (select total_xp, region, country from public.standings where lifter = auth.uid())
  select case when not exists (select 1 from me) then 0 else
    (select count(*) + 1 from public.standings s, me
      where s.total_xp > me.total_xp
        and ( p_scope = 'global'
           or (p_scope = 'country' and s.country is not distinct from me.country)
           or (p_scope = 'region'  and s.region  is not distinct from me.region)))
  end;
$$;

-- --------------------------------------------------------------------- RLS
alter table public.lifters   enable row level security;
alter table public.sessions  enable row level security;
alter table public.standings enable row level security;

drop policy if exists lifters_own_read   on public.lifters;
drop policy if exists lifters_own_write  on public.lifters;
drop policy if exists lifters_own_update on public.lifters;
create policy lifters_own_read   on public.lifters for select using (auth.uid() = id);
create policy lifters_own_write  on public.lifters for insert with check (auth.uid() = id);
create policy lifters_own_update on public.lifters for update using (auth.uid() = id) with check (auth.uid() = id);

drop policy if exists sessions_own_read   on public.sessions;
drop policy if exists sessions_own_write  on public.sessions;
drop policy if exists sessions_own_delete on public.sessions;
create policy sessions_own_read   on public.sessions for select using (auth.uid() = lifter);
create policy sessions_own_write  on public.sessions for insert with check (auth.uid() = lifter);
create policy sessions_own_delete on public.sessions for delete using (auth.uid() = lifter);

-- The leaderboard. Readable by signed-in users; no client write policy at all,
-- so the only way in is through the trigger.
drop policy if exists standings_read on public.standings;
create policy standings_read on public.standings
  for select to authenticated using (true);

grant usage on schema public to anon, authenticated;
grant select, insert, update on public.lifters  to authenticated;
grant select, insert, delete on public.sessions to authenticated;
grant select on public.standings to authenticated;
grant execute on function public.my_rank(text) to authenticated;
