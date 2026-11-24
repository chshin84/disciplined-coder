---
description: 이 PC에 적용 중인 디시플린 에이전트원칙 사본(PC 전역 agent-principles.md)의 전문을 그대로 보여 준다.
---
먼저 설정 홈 경로를 구하라. 경로를 짐작하지 말고 아래 명령을 실행해 얻은 값을 쓰라. 홈 경로가 서로 다른 PC에서는 이 명령이 stdout에 경로 한 줄과 stderr에 안내 한 줄을 함께 낸다. stdout의 경로만 쓰라.

`bash -c '. "${CLAUDE_PLUGIN_ROOT}/scripts/_resolve_home.sh" && resolve_home claude'`

구한 경로 아래의 `disciplined-coder/agent-principles.md`를 Read로 읽어 내용을 그대로 보여 주라. 인자는 없다. 파일이 없으면 "원칙 사본이 없다. 새 세션을 열어라"라고 한 줄로 안내하라. 원인을 단정해 적지 마라. 셋업 미실행 말고도 복사 실패나 설정 홈 불일치로 사본이 없을 수 있다.

홈 경로가 서로 다른 PC가 있어 경로를 직접 구한다. 도메인 PC는 네트워크 홈 리다이렉트 때문에 bash의 `$HOME`이 `USERPROFILE`과 다를 수 있다. 이때 `~/.claude`를 바로 읽으면 scaffold가 기록한 위치와 다른 곳을 찾는다. 그 결과 정상 설치된 상태에서도 "원칙 사본이 없다"가 뜬다.
