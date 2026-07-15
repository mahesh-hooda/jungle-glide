-- Run this once in Supabase: SQL Editor -> New query -> Run.
-- This database stores each player's best score, game count, and global rank.

create table if not exists public.player_best_scores (
  player_name text primary key check (player_name ~ '^[A-Za-z0-9 _-]{2,18}$'),
  best_score smallint not null check (best_score between 0 and 99),
  games_played integer not null default 0 check (games_played >= 0),
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now()
);

alter table public.player_best_scores enable row level security;

revoke all on table public.player_best_scores from anon, authenticated;
grant usage on schema public to anon;
grant select on table public.player_best_scores to anon;

drop policy if exists "Leaderboard is public" on public.player_best_scores;
create policy "Leaderboard is public"
  on public.player_best_scores for select to anon using (true);

create or replace function public.register_player(p_player_name text)
returns table (player_name text, best_score smallint, games_played integer)
language plpgsql
security definer
set search_path = public, pg_temp
as $$
declare
  clean_name text := btrim(p_player_name);
begin
  if clean_name !~ '^[A-Za-z0-9 _-]{2,18}$' then
    raise exception 'Player name must contain 2–18 letters, numbers, spaces, hyphens, or underscores.';
  end if;

  insert into public.player_best_scores (player_name, best_score, games_played)
  values (clean_name, 0, 0)
  on conflict (player_name) do nothing;

  if not found then
    raise exception 'That player name is already taken. Please choose another one.';
  end if;

  return query
    select scores.player_name, scores.best_score, scores.games_played
    from public.player_best_scores as scores
    where scores.player_name = clean_name;
end;
$$;

create or replace function public.submit_score(p_player_name text, p_score integer)
returns table (player_name text, best_score smallint, games_played integer, player_rank bigint)
language plpgsql
security definer
set search_path = public, pg_temp
as $$
declare
  clean_name text := btrim(p_player_name);
  safe_score smallint := least(greatest(coalesce(p_score, 0), 0), 99)::smallint;
begin
  if clean_name !~ '^[A-Za-z0-9 _-]{2,18}$' then
    raise exception 'Player name must contain 2–18 letters, numbers, spaces, hyphens, or underscores.';
  end if;

  update public.player_best_scores as scores
    set best_score = greatest(scores.best_score, safe_score),
        games_played = scores.games_played + 1,
        updated_at = now()
    where scores.player_name = clean_name;

  if not found then
    raise exception 'Player name is not registered.';
  end if;

  return query
    with ranked as (
      select scores.player_name, scores.best_score, scores.games_played,
             dense_rank() over (order by scores.best_score desc) as player_rank
      from public.player_best_scores as scores
    )
    select ranked.player_name, ranked.best_score, ranked.games_played, ranked.player_rank
    from ranked
    where ranked.player_name = clean_name;
end;
$$;

revoke all on function public.submit_score(text, integer) from public;
grant execute on function public.submit_score(text, integer) to anon;
revoke all on function public.register_player(text) from public;
grant execute on function public.register_player(text) to anon;
