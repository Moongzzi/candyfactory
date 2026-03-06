## Supabase 미니게임 API 세팅 (game2~game5)

현재 앱은 Supabase Auth가 아니라 `nickname` 기반 세션(`SessionStore`)으로 동작하므로,
RPC 함수가 `auth.uid()`를 강제하면 `Not authenticated(400)`가 발생합니다.

아래 SQL은 현재 앱 구조에 맞게 `p_meta.nickname`으로 유저를 식별해
`start_game`/`finish_game`를 동작시키는 설정입니다.

### 1) game_log 테이블 준비

```sql
create extension if not exists pgcrypto;

create table if not exists public.game_log (
  id uuid primary key default gen_random_uuid(),
  user_id uuid not null,
  game_code text not null,
  started_at timestamptz not null default now(),
  ended_at timestamptz,
  candies_delta integer not null default 0,
  meta jsonb not null default '{}'::jsonb,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now()
);

create index if not exists idx_game_log_user_id on public.game_log(user_id);
create index if not exists idx_game_log_started_at on public.game_log(started_at desc);
```

`game_log.user_id`가 Supabase Auth의 `users.id`를 참조하고 있으면,
현재 프로젝트(`user_profile.id` 기반 로그인)에서 아래 오류가 발생합니다.

- `violates foreign key constraint "game_log_user_id_fkey"`

이 경우 FK를 `user_profile(id)`로 재설정하세요.

```sql
-- 현재 game_log 외래키 확인
select conname, pg_get_constraintdef(oid) as definition
from pg_constraint
where conrelid = 'public.game_log'::regclass
  and contype = 'f';

-- users 참조 FK 제거
alter table public.game_log
drop constraint if exists game_log_user_id_fkey;

-- user_profile 참조 FK 추가
alter table public.game_log
add constraint game_log_user_id_fkey
foreign key (user_id)
references public.user_profile(id)
on update cascade
on delete cascade;
```

### 2) start_game RPC 재정의

```sql
create or replace function public.start_game(
  p_game_code text,
  p_meta jsonb default '{}'::jsonb
)
returns uuid
language plpgsql
security definer
set search_path = public
as $$
declare
  v_nickname text;
  v_user_id uuid;
  v_log_id uuid;
begin
  v_nickname := nullif(trim(coalesce(p_meta->>'nickname', '')), '');

  if v_nickname is null then
    raise exception 'nickname is required in p_meta';
  end if;

  select id into v_user_id
  from public.user_profile
  where nickname = v_nickname
  limit 1;

  if v_user_id is null then
    raise exception 'user_profile not found for nickname: %', v_nickname;
  end if;

  insert into public.game_log (
    user_id,
    game_code,
    started_at,
    candies_delta,
    meta
  ) values (
    v_user_id,
    p_game_code,
    now(),
    0,
    coalesce(p_meta, '{}'::jsonb)
  )
  returning id into v_log_id;

  return v_log_id;
end;
$$;
```

### 3) finish_game RPC 재정의

```sql
create or replace function public.finish_game(
  p_log_id uuid,
  p_candies_delta integer,
  p_meta jsonb default '{}'::jsonb
)
returns void
language plpgsql
security definer
set search_path = public
as $$
declare
  v_user_id uuid;
  v_delta integer;
begin
  update public.game_log
  set
    ended_at = now(),
    candies_delta = greatest(coalesce(p_candies_delta, 0), 0),
    meta = coalesce(public.game_log.meta, '{}'::jsonb) || coalesce(p_meta, '{}'::jsonb),
    updated_at = now()
  where id = p_log_id
  returning user_id, candies_delta into v_user_id, v_delta;

  if v_user_id is null then
    raise exception 'game_log not found: %', p_log_id;
  end if;

  update public.user_profile
  set
    total_candies = coalesce(total_candies, 0) + v_delta,
    updated_at = now()
  where id = v_user_id;
end;
$$;
```

### 4) 실행 권한 부여

```sql
revoke all on function public.start_game(text, jsonb) from public;
revoke all on function public.finish_game(uuid, integer, jsonb) from public;

grant execute on function public.start_game(text, jsonb) to anon, authenticated;
grant execute on function public.finish_game(uuid, integer, jsonb) to anon, authenticated;
```

### 5) (선택) game_log 조회 정책

RPC만 사용할 경우 필수는 아니지만, 대시보드/REST 조회가 필요하면 추가하세요.

```sql
alter table public.game_log enable row level security;

drop policy if exists "anon_read_game_log" on public.game_log;
create policy "anon_read_game_log"
on public.game_log
for select
to anon
using (true);
```

### 6) 동작 테스트

```sql
-- 시작
select public.start_game('game2', '{"nickname":"옥"}'::jsonb);

-- 종료 (위 결과 log_id 사용)
select public.finish_game(
  '00000000-0000-0000-0000-000000000000'::uuid,
  15,
  '{"score":15}'::jsonb
);
```

정상 동작 시:
- `game_log`에 시작/종료 로그 기록
- `user_profile.total_candies`가 `p_candies_delta`만큼 증가
