# 쥐 키우기 — 작업 지침 (Claude용)

이 저장소를 고치는 Claude 세션은 아래 규칙을 항상 따른다.

## 배포는 언제나 두 군데에 함께

게임을 바꾸면 **GitHub와 claude.ai 아티팩트 둘 다** 같은 버전으로 반영한다. 한쪽만 올리지 않는다.

1. `index.html`을 고친다.
2. 문법 확인: `node -e "const s=require('fs').readFileSync('index.html','utf8');for(const x of s.matchAll(/<script>([\s\S]*?)<\/script>/g))new Function(x[1])"`
3. 바뀐 내용을 브라우저(Playwright)로 직접 확인한다.
4. 버전 올리기: `index.html`의 `APP_VERSION`과 `version.json`의 `v`를 같은 새 값(UTC `YYYYMMDDHHMM`)으로 바꾼다. 이미 게임을 연 사용자에게 새로고침 안내가 뜬다.
5. 사용자에게 보이는 변화면 `PATCH_NOTES` 맨 위 날짜 항목에 한 줄 추가한다.
6. **GitHub**: `main`에 커밋하고 푸시한다 (`git fetch origin main` 후 `git push origin main`). GitHub Pages가 자동 배포한다.
7. **아티팩트**: https://claude.ai/code/artifact/f3a4048f-5d99-439c-8000-acb3dfd24479 에 같은 `index.html`을 다시 게시한다.
   - 함께 올릴 파일: `version.json`, `fonts/dongle-bold.woff2`, 그리고 **빈 설정의 `config.js`** (`window.JWI_CONFIG = {};`).
   - 아티팩트에서는 Supabase 접속이 막혀 있어서, 빈 설정이어야 아티팩트 자체 저장소(db)로 저장된다. 저장소의 `config.js`(Supabase 키)를 그대로 올리지 않는다.
   - `capabilities`는 넘기지 않는다(기존 `db` 유지).

## 배포 후 확인 (매번)

- `git rev-parse HEAD`와 `origin/main`이 같은지.
- 아티팩트를 다시 읽어서(`Artifact` read) 지금 `index.html`이 그대로 들어 있는지, `APP_VERSION`이 같은지.
- 둘 중 하나라도 다르면 바로 다시 올리고 사용자에게 알린다.

## 지켜야 할 것

- `config.js`에는 Supabase 공개(publishable) 키만 넣는다. service_role/secret 키는 절대 넣지 않는다.
- 저장 구조를 바꾸면 `prepState`에 기본값을 넣어 기존 사용자 데이터가 깨지지 않게 한다.
- 쿠폰 코드는 게임 코드에 넣지 않는다(Supabase `jwi_coupons` 표에서 관리, `supabase/coupons.sql` 참고).
- 0차 지인 코드도 게임 코드에 평문으로 넣지 않는다. 서버는 Supabase `jwi_invites` 표로 확인하고(`supabase/invite.sql`), 아티팩트처럼 서버가 없을 때만 `index.html`의 `INVITE_H`(`'jwi-invite:'+코드`의 SHA-256)로 확인한다. 코드를 바꾸면 둘 다 바꾼다.
