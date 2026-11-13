-- 쥐 키우기 · 0차 지인 코드 (계정 만들 때 꼭 입력)
-- Supabase 대시보드 > SQL Editor 에 붙여 넣고 Run 하면 돼요. 여러 번 실행해도 괜찮아요.
-- 코드는 게임 코드(index.html)가 아니라 이 표(jwi_invites)에서 관리해요. 대소문자는 가리지 않아요.

create table if not exists public.jwi_invites (
  code        text primary key,                 -- 소문자로 저장
  active      boolean not null default true,    -- false로 바꾸면 그 코드로는 더 못 만들어요
  note        text,
  created_at  timestamptz not null default now()
);
alter table public.jwi_invites enable row level security;
revoke all on public.jwi_invites from anon, authenticated;

-- 어떤 코드로 가입했는지 기록
alter table public.jwi_accounts add column if not exists invite text;

-- ▶ 코드 추가 (있으면 다시 켜기)
insert into public.jwi_invites (code, note) values ('여기에_코드', '0차 지인 코드')   -- 실제 코드는 저장소에 적지 않아요
on conflict (code) do update set active = true;

-- 가입: 지인 코드가 틀리면 'bad_invite' 오류, 이미 있는 아이디면 false
create or replace function public.jwi_signup(p_key text, p_id text, p_h text, p_invite text)
returns boolean
language plpgsql
security definer
set search_path = public, extensions
as $$
declare v_code text := lower(btrim(coalesce(p_invite, '')));
begin
  if p_key !~ '^u[0-9a-f]{2,128}$'
     or char_length(p_id) not between 2 and 16
     or char_length(p_h) not between 16 and 128 then
    raise exception 'invalid_input';
  end if;
  if not exists (select 1 from jwi_invites where code = v_code and active) then
    raise exception 'bad_invite';
  end if;
  insert into jwi_accounts(key, display_id, pw, invite)
  values (p_key, p_id, crypt(p_h, gen_salt('bf')), v_code);
  return true;
exception when unique_violation then
  return false;
end;
$$;

revoke all on function public.jwi_signup(text, text, text, text) from public;
grant execute on function public.jwi_signup(text, text, text, text) to anon, authenticated;

-- 지인 코드 없이 가입하던 예전 함수는 없애요 (코드를 건너뛰지 못하게)
drop function if exists public.jwi_signup(text, text, text);

-- ▶ 코드 목록 · 코드별 가입자 수
-- select i.code, i.active, (select count(*) from public.jwi_accounts a where a.invite = i.code) as signups
-- from public.jwi_invites i order by i.created_at;

-- ▶ 코드 끄기
-- update public.jwi_invites set active = false where code = '여기에_코드';
