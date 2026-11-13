-- 쥐 키우기 · Supabase 서버 저장 설정
-- Supabase 대시보드 > SQL Editor 에 통째로 붙여 넣고 Run 하면 돼요. 여러 번 실행해도 괜찮아요.
--
-- 구조
--   jwi_accounts : 계정 (아이디 + 비밀번호 해시를 한 번 더 bcrypt로 보관)
--   jwi_saves    : 계정별 진행상황 (케이지 최대 3개를 JSON 하나로)
-- 두 테이블은 브라우저에서 직접 읽고 쓸 수 없고(RLS + 권한 회수),
-- 함수(가입 · 로그인 · 저장)로만 접근해요. 함수가 비밀번호를 확인한 뒤에만 읽고 써요.

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

-- 가입 함수(jwi_signup)는 0차 지인 코드 확인이 들어간 supabase/invite.sql 에 있어요.
-- 이 파일을 실행한 다음 invite.sql 도 꼭 실행해 주세요.

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

revoke all on function public.jwi_login(text, text)        from public;
revoke all on function public.jwi_save(text, text, jsonb)  from public;
grant execute on function public.jwi_login(text, text)        to anon, authenticated;
grant execute on function public.jwi_save(text, text, jsonb)  to anon, authenticated;

-- =====================================================================
-- 쿠폰 (2026-11-12 추가)
--   jwi_coupons     : 쿠폰 코드 · 보상 · 기간 (쿠폰 추가/수정은 supabase/coupons.sql 참고)
--   jwi_coupon_uses : 어느 계정의 어느 케이지가 어떤 쿠폰을 썼는지 (케이지마다 쿠폰 1번)
--   보상 예: {"seed": 3, "apple": 2, "snack": 5, "potion": 1}
--     seed=호박씨, apple=사과 조각, snack=간식, pea=완두콩, mounjiro=마운찌로,
--     potion=쥑닥쥑닥 물약, salon=찍찍 살롱 이용권, doll=애착 쥐의 애착 쥐
-- =====================================================================
create table if not exists public.jwi_coupons (
  code        text primary key,               -- 영문 대문자만 (A-Z, 2~32자)
  rewards     jsonb not null,
  starts_at   timestamptz not null default now(),
  ends_at     timestamptz,                    -- 비우면 기한 없음
  max_uses    int,                            -- 전체 선착순 수량 (비우면 무제한)
  note        text,                           -- 사용하면 보여 줄 한마디 (선택)
  created_at  timestamptz not null default now(),
  constraint jwi_coupons_code_format check (code ~ '^[A-Z]{2,32}$')
);
-- 쿠폰 코드 규칙: 영문 대문자만 — 여러 번 실행해도 괜찮아요
alter table public.jwi_coupons drop constraint if exists jwi_coupons_code_upper;
alter table public.jwi_coupons drop constraint if exists jwi_coupons_code_format;
alter table public.jwi_coupons add constraint jwi_coupons_code_format check (code ~ '^[A-Z]{2,32}$');
create table if not exists public.jwi_coupon_uses (
  code     text not null references public.jwi_coupons(code) on delete cascade,
  key      text not null references public.jwi_accounts(key) on delete cascade,
  cage     text not null default '',          -- 케이지 고유 번호
  used_at  timestamptz not null default now(),
  primary key (code, key, cage)
);
-- 예전(계정당 1번) 구조에서 케이지별 구조로 바꾸기 — 여러 번 실행해도 괜찮아요
alter table public.jwi_coupon_uses add column if not exists cage text not null default '';
alter table public.jwi_coupon_uses drop constraint if exists jwi_coupon_uses_pkey;
alter table public.jwi_coupon_uses add primary key (code, key, cage);
alter table public.jwi_coupons     enable row level security;
alter table public.jwi_coupon_uses enable row level security;
revoke all on public.jwi_coupons, public.jwi_coupon_uses from anon, authenticated;

-- 쿠폰 사용: { ok: true, rewards, note } 또는 { ok: false, reason }
--   reason: auth | not_found | not_started | expired | used | sold_out
--   케이지마다 1번 (한 계정의 케이지는 최대 3개라, 한 계정에서 같은 쿠폰은 최대 3번)
drop function if exists public.jwi_redeem(text, text, text);
create or replace function public.jwi_redeem(p_key text, p_h text, p_code text, p_cage text)
returns json
language plpgsql
security definer
set search_path = public, extensions
as $$
declare
  a jwi_accounts%rowtype;
  c jwi_coupons%rowtype;
  v_code text := upper(regexp_replace(coalesce(p_code, ''), '\s', '', 'g'));
  n int;
begin
  select * into a from jwi_accounts where key = p_key;
  if not found or a.pw <> crypt(p_h, a.pw) then
    return json_build_object('ok', false, 'reason', 'auth');
  end if;
  select * into c from jwi_coupons where code = v_code for update;
  if not found then
    return json_build_object('ok', false, 'reason', 'not_found');
  end if;
  if now() < c.starts_at then
    return json_build_object('ok', false, 'reason', 'not_started', 'starts_at', c.starts_at);
  end if;
  if c.ends_at is not null and now() > c.ends_at then
    return json_build_object('ok', false, 'reason', 'expired', 'ends_at', c.ends_at);
  end if;
  if p_cage is null or char_length(p_cage) not between 1 and 64 then
    raise exception 'invalid_input';
  end if;
  if v_code !~ '^[A-Z]{2,32}$' then
    return json_build_object('ok', false, 'reason', 'not_found');
  end if;
  if exists (select 1 from jwi_coupon_uses where code = v_code and key = p_key and cage = p_cage)
     or (select count(*) from jwi_coupon_uses where code = v_code and key = p_key) >= 3 then
    return json_build_object('ok', false, 'reason', 'used');
  end if;
  if c.max_uses is not null then
    select count(*) into n from jwi_coupon_uses where code = v_code;
    if n >= c.max_uses then
      return json_build_object('ok', false, 'reason', 'sold_out');
    end if;
  end if;
  insert into jwi_coupon_uses(code, key, cage) values (v_code, p_key, p_cage);
  return json_build_object('ok', true, 'code', v_code, 'rewards', c.rewards, 'note', c.note);
end;
$$;
revoke all on function public.jwi_redeem(text, text, text, text) from public;
grant execute on function public.jwi_redeem(text, text, text, text) to anon, authenticated;
