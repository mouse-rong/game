# 쥐 키우기

작고 소중한 픽셀 쥐를 돌보는 웹 게임이에요. GitHub Pages로 배포되고, 계정별 진행상황은 Supabase에 저장돼요.

## 파일

| 파일 | 역할 |
| --- | --- |
| `index.html` | 게임 전체. 패치할 때는 이 파일만 바꿔서 푸시하면 돼요. |
| `config.js` | Supabase 연결 설정(URL · 공개 키). 한 번 채워 두면 패치해도 그대로 유지돼요. |
| `supabase/setup.sql` | Supabase에 한 번 실행하는 테이블 · 함수 설정. |

## Supabase 연결 (처음 한 번)

1. [supabase.com](https://supabase.com)에서 프로젝트를 만들어요.
2. 대시보드 **SQL Editor**에 `supabase/setup.sql` 내용을 붙여 넣고 **Run** 해요. 여러 번 실행해도 괜찮아요.
3. **Project Settings → API Keys**(또는 Data API)에서 아래 두 값을 복사해 `config.js`에 넣어요.
   - Project URL → `supabaseUrl`
   - anon / publishable 키 → `supabaseAnonKey`
   - `service_role` · secret 키는 절대 넣지 마세요.
4. 커밋하고 푸시하면 GitHub Pages에 반영돼요. 로그인 화면에 "☁ 진행상황이 계정별로 서버에 자동 저장돼서…"가 보이면 연결된 거예요.

연결이 안 되면 로그인 화면에 이유가 표시되고, 그동안은 이 브라우저에만 저장돼요.

## 저장 방식

- 아이디 · 비밀번호는 개인 식별용이에요(이메일 인증 없음). 비밀번호는 브라우저에서 해시로 바꿔 보내고, 서버는 그 값을 다시 bcrypt로 보관해요.
- 테이블은 브라우저에서 직접 읽거나 쓸 수 없고, `jwi_signup` · `jwi_login` · `jwi_save` 함수가 비밀번호를 확인한 뒤에만 접근해요.
- 진행상황은 바뀔 때마다 브라우저에 바로 저장되고, 서버에는 2초쯤 모아서 저장돼요. 계정당 케이지(주인 + 쥐) 최대 3개.

## 패치할 때

`index.html`만 바꿔서 `main`에 푸시하면 GitHub Pages가 다시 배포해요. 사용자 진행상황은 Supabase에 그대로 있고, 예전 저장 데이터는 게임이 불러올 때 새 구조로 자동 변환돼요(`prepState`). 새 기능에서 저장 구조를 바꿀 때도 `prepState`에 기본값을 넣어 주면 기존 사용자 데이터가 깨지지 않아요.
