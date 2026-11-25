---
description: 이 PC에 적용 중인 디시플린 에이전트원칙 사본(PC 전역 agent-principles.md)의 전문을 그대로 보여 준다.
---
먼저 경로를 짐작하지 말고 아래 명령으로 설정 홈을 구하라. 홈 경로가 다른 PC에서는 stdout 경로와 stderr 안내가 한 줄씩 나온다. stdout 경로만 써라.

`bash -c '. "${CLAUDE_PLUGIN_ROOT}/scripts/_resolve_home.sh" && resolve_home claude'`

인자는 없다. 구한 경로 아래의 `disciplined-coder/agent-principles.md`를 Read로 읽어 내용을 그대로 보여 주어라. 파일이 없으면 "원칙 사본이 없다. 새 세션을 열어라"라고 한 줄로 안내하라. 원인을 단정해 적지 마라. 셋업 미실행 외에 복사 실패와 설정 홈 불일치도 원인일 수 있다.

홈 경로가 서로 다른 PC 때문에 경로를 구한다. 도메인 PC는 네트워크 홈 리다이렉트로 bash의 `$HOME`과 `USERPROFILE`이 다를 수 있다. 이때 `~/.claude`를 그대로 읽으면 scaffold가 저장한 폴더가 아닌 경로를 보게 된다. 그러면 정상 설치된 상태에서도 "원칙 사본이 없다"가 나온다.
