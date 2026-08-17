---
description: 지금까지 해결한 문제와 그때 얻은 교훈을 모아 둔 기록을 그대로 보여준다(PC 전역 solved_problems.md).
---

먼저 관리 디렉터리를 도출하라 — 경로를 짐작하지 말고 아래를 실행해 받은 값을 쓴다.

`bash -c '. "${CLAUDE_PLUGIN_ROOT}/scripts/_resolve_home.sh" && resolve_home claude'`

그 값 아래의 `disciplined-coder/solved_problems.md`를 Read해서 내용을 그대로 보여줘라. 인자는 없다.
파일이 없으면 "scaffold가 아직 실행되지 않았다 — 새 세션을 열거나 `/setup-discipline`을 실행하라"고
한 줄로 안내하라.

경로를 도출하는 이유는 홈이 갈리는 PC가 있기 때문이다. 도메인 PC는 네트워크 홈 리다이렉트로 bash의
`$HOME`이 `USERPROFILE`과 어긋날 수 있고, 그때 `~/.claude`를 그대로 읽으면 scaffold가 쓴 곳과 다른
곳을 보게 된다. 그러면 멀쩡히 설치된 상태에서 "아직 실행되지 않았다"가 뜬다.
