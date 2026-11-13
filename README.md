# 쥐 키우기

작고 소중한 픽셀 쥐를 돌보는 웹 게임이에요. GitHub Pages로 배포되고, 계정별 진행상황은 Supabase에 저장돼요.

## 파일

| 파일 | 역할 |
| --- | --- |
| `index.html` | 게임 전체. 패치할 때는 이 파일만 바꿔서 푸시하면 돼요. |
| `config.js` | Supabase 연결 설정(URL · 공개 키). 한 번 채워 두면 패치해도 그대로 유지돼요. |
| `supabase/setup.sql` | Supabase에 실행하는 테이블 · 함수 설정(계정 · 저장 · 쿠폰). 여러 번 실행해도 괜찮아요. |
| `supabase/invite.sql` | 0차 지인 코드(가입할 때 꼭 입력) 표와 가입 함수. `setup.sql` 다음에 실행해요. |
| `supabase/coupons.sql` | 쿠폰 추가 · 확인 · 종료 · 삭제용 SQL 모음. |
| `fonts/dongle-bold.woff2` | 보조 글꼴(동글 Bold, 한글 11,172자). 기본 글꼴 주아에 없는 '쮝' 같은 글자만 이걸로 보여요. 라이선스는 `fonts/OFL-Dongle.txt`(SIL OFL 1.1). |

## Supabase 연결 (처음 한 번)

1. [supabase.com](https://supabase.com)에서 프로젝트를 만들어요.
2. 대시보드 **SQL Editor**에 `supabase/setup.sql` 내용을 붙여 넣고 **Run** 해요. 여러 번 실행해도 괜찮아요. 이어서 `supabase/invite.sql`도 같은 방법으로 실행해요(가입 함수와 0차 지인 코드).
3. **Project Settings → API Keys**(또는 Data API)에서 아래 두 값을 복사해 `config.js`에 넣어요.
   - Project URL → `supabaseUrl`
   - anon / publishable 키 → `supabaseAnonKey`
   - `service_role` · secret 키는 절대 넣지 마세요.
4. 커밋하고 푸시하면 GitHub Pages에 반영돼요. 로그인 화면에 "☁ 진행상황이 계정별로 서버에 자동 저장돼서…"가 보이면 연결된 거예요.

연결이 안 되면 로그인 화면에 이유가 표시되고, 그동안은 이 브라우저에만 저장돼요.

## 쿠폰 관리

쿠폰은 Supabase의 `jwi_coupons` 표에 있어요. 게임 코드에는 쿠폰 코드가 들어 있지 않아서 소스를 봐도 알 수 없고, 쿠폰을 추가할 때 다시 배포할 필요도 없어요.

- **추가 · 수정:** SQL Editor에서 `supabase/coupons.sql`의 코드 · 보상 · 기간을 고쳐서 Run. 또는 Table Editor > `jwi_coupons`에서 줄을 직접 추가.
- **보상 키:** `seed`(호박씨) · `apple`(사과 조각) · `snack`(간식) · `pea`(완두콩) · `mounjiro`(마운찌로) · `potion`(쥑닥쥑닥 물약) · `salon`(찍찍 살롱 이용권) · `doll`(애착 쥐의 애착 쥐)
- **규칙:** 케이지마다 한 번(계정당 최대 3번), `starts_at` ~ `ends_at` 사이에만, `max_uses`가 있으면 선착순. 코드는 영문 대문자만(A-Z, 2~32자)이고, 게임 입력칸도 영문 대문자만 받아요.
- **사용 현황:** `jwi_coupon_uses` 표 또는 `coupons.sql`의 목록 쿼리.

## 저장 방식

- 아이디 · 비밀번호는 개인 식별용이에요(이메일 인증 없음). 비밀번호는 브라우저에서 해시로 바꿔 보내고, 서버는 그 값을 다시 bcrypt로 보관해요.
- 테이블은 브라우저에서 직접 읽거나 쓸 수 없고, `jwi_signup` · `jwi_login` · `jwi_save` 함수가 비밀번호를 확인한 뒤에만 접근해요.
- 진행상황은 바뀔 때마다 브라우저에 바로 저장되고, 서버에는 2초쯤 모아서 저장돼요. 계정당 케이지(주인 + 쥐) 최대 3개.

## 패치할 때

배포할 때마다 `index.html`의 `APP_VERSION`과 `version.json`의 `v`를 같은 새 값(예: `202611121140`)으로 올려요. 이미 게임을 열어 둔 사용자에게 "새 업데이트가 있어요 · 새로고침" 안내가 떠요.

`index.html` 안의 `PATCH_NOTES` 맨 위에 날짜(`YYYY-MM-DD`)와 내용을 추가하면 게임의 **패치노트** 메뉴에 보이고, 아직 안 본 사용자에게는 메뉴에 NEW 표시가 떠요.


`index.html`만 바꿔서 `main`에 푸시하면 GitHub Pages가 다시 배포해요. 사용자 진행상황은 Supabase에 그대로 있고, 예전 저장 데이터는 게임이 불러올 때 새 구조로 자동 변환돼요(`prepState`). 새 기능에서 저장 구조를 바꿀 때도 `prepState`에 기본값을 넣어 주면 기존 사용자 데이터가 깨지지 않아요.
