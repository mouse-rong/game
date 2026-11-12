// 쥐 키우기 · 서버 저장(Supabase) 연결 설정
// Supabase 대시보드 > Project Settings > API Keys(또는 Data API)에서 복사해 넣어요.
// - supabaseUrl     : Project URL           예) https://abcdefghijkl.supabase.co
// - supabaseAnonKey : anon / publishable 키 예) eyJhbGciOi...  또는  sb_publishable_...
// 이 두 값은 브라우저에 공개돼도 되는 값이에요. service_role / secret 키는 절대 넣지 마세요.
// 비워 두면 서버 저장 없이 이 브라우저에만 저장돼요.
// 게임 패치는 index.html만 바꾸면 되고, 이 파일과 진행상황은 그대로 유지돼요.
window.JWI_CONFIG = {
  supabaseUrl: '',
  supabaseAnonKey: ''
};
