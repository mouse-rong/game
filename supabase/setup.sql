-- 쥐 키우기 · Supabase 서버 저장 설정
-- Supabase 대시보드 > SQL Editor 에 통째로 붙여 넣고 Run 하면 돼요. 여러 번 실행해도 괜찮아요.
--
-- 구조
--   jwi_accounts : 계정 (아이디 + 비밀번호 해시를 한 번 더 bcrypt로 보관)
--   jwi_saves    : 계정별 진행상황 (케이지 최대 3개를 JSON 하나로)
-- 두 테이블은 브라우저에서 직접 읽고 쓸 수 없고(RLS + 권한 회수),
-- 아래 함수 3개(가입 · 로그인 · 저장)로만 접근해요. 함수가 비밀번호를 확인한 뒤에만 읽고 써요.

create extension if not exists pgcrypto with schema extensions;

create table if not exists public.jwi_accounts (
  key         text primary key,                 -- 'u' + 소문자 아이디의 UTF-8 hex
  display_id  text not null,                    -- 화면에 보이는 아이디
  pw          text not null,                    -- bcrypt(브라우저에서 만든 해시)
  created_at  timestamptz not null default now()
);

create table if not exists public.jwi_saves (
  key         text primary key references public.jwi_accounts(key) on delete cascade,
  data        jsonb not null,                   -- { at, cur, slots: [케이지 JSON 문자열 …], v }
  updated_at  timestamptz not null default now()
);

alter table public.jwi_accounts enable row level security;
alter table public.jwi_saves    enable row level security;
revoke all on public.jwi_accounts, public.jwi_saves from anon, authenticated;

-- 가입: 이미 있는 아이디면 false
create or replace function public.jwi_signup(p_key text, p_id text, p_h text)
returns boolean
language plpgsql
security definer
set search_path = public, extensions
as $$
begin
  if p_key !~ '^u[0-9a-f]{2,128}$'
     or char_length(p_id) not between 2 and 16
     or char_length(p_h) not between 16 and 128 then
    raise exception 'invalid_input';
  end if;
  insert into jwi_accounts(key, display_id, pw)
  values (p_key, p_id, crypt(p_h, gen_salt('bf')));
  return true;
exception when unique_violation then
  return false;
end;
$$;

-- 로그인: 맞으면 { id, save }, 틀리거나 없으면 null
create or replace function public.jwi_login(p_key text, p_h text)
returns json
language plpgsql
security definer
set search_path = public, extensions
as $$
declare
  a jwi_accounts%rowtype;
  s jsonb;
begin
  select * into a from jwi_accounts where key = p_key;
  if not found or a.pw <> crypt(p_h, a.pw) then
    return null;
  end if;
  select data into s from jwi_saves where key = p_key;
  return json_build_object('id', a.display_id, 'save', s);
end;
$$;

-- 저장: 비밀번호가 맞을 때만 덮어쓰기
create or replace function public.jwi_save(p_key text, p_h text, p_data jsonb)
returns boolean
language plpgsql
security definer
set search_path = public, extensions
as $$
declare
  a jwi_accounts%rowtype;
begin
  if octet_length(p_data::text) > 600000 then
    raise exception 'too_large';
  end if;
  select * into a from jwi_accounts where key = p_key;
  if not found or a.pw <> crypt(p_h, a.pw) then
    return false;
  end if;
  insert into jwi_saves(key, data, updated_at)
  values (p_key, p_data, now())
  on conflict (key) do update set data = excluded.data, updated_at = now();
  return true;
end;
$$;

revoke all on function public.jwi_signup(text, text, text) from public;
revoke all on function public.jwi_login(text, text)        from public;
revoke all on function public.jwi_save(text, text, jsonb)  from public;
grant execute on function public.jwi_signup(text, text, text) to anon, authenticated;
grant execute on function public.jwi_login(text, text)        to anon, authenticated;
grant execute on function public.jwi_save(text, text, jsonb)  to anon, authenticated;
