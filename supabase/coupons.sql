-- 쥐 키우기 · 쿠폰 관리
-- Supabase 대시보드 > SQL Editor 에서 필요한 부분만 고쳐서 Run 해요.
-- (또는 Table Editor > jwi_coupons 에서 줄을 직접 추가 · 수정해도 돼요)
--
-- 보상 키: seed=호박씨, apple=사과 조각, snack=간식, pea=완두콩, mounjiro=마운찌로,
--          potion=쥑닥쥑닥 물약, salon=찍찍 살롱 이용권, doll=애착 쥐의 애착 쥐
-- 시간은 한국 시간 기준으로 적으면 돼요 (+09).

-- ▶ 쿠폰 추가 (같은 코드가 있으면 내용만 바꿔요)
insert into public.jwi_coupons (code, rewards, starts_at, ends_at, max_uses, note)
values (
  'WELCOME2026',                                   -- 코드 (대문자)
  '{"seed": 3, "apple": 2, "snack": 5}',            -- 보상
  '2026-11-12 00:00+09',                            -- 시작
  '2026-12-31 23:59+09',                            -- 끝 (기한 없으면 null)
  null,                                             -- 선착순 수량 (무제한이면 null)
  '쥐 키우기에 온 걸 환영해요!'                       -- 사용했을 때 보여 줄 한마디
)
on conflict (code) do update set
  rewards = excluded.rewards, starts_at = excluded.starts_at, ends_at = excluded.ends_at,
  max_uses = excluded.max_uses, note = excluded.note;

-- ▶ 쿠폰 목록 · 사용 현황
-- select c.code, c.rewards, c.starts_at, c.ends_at, c.max_uses,
--        (select count(*) from public.jwi_coupon_uses u where u.code = c.code) as used
-- from public.jwi_coupons c order by c.created_at desc;

-- ▶ 쿠폰 바로 끝내기
-- update public.jwi_coupons set ends_at = now() where code = 'WELCOME2026';

-- ▶ 쿠폰 지우기 (사용 기록도 함께 지워져요)
-- delete from public.jwi_coupons where code = 'WELCOME2026';
