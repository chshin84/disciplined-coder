---
tags: [dev]
kind: should
type: workdoc
failure: [language]
clause: [NO-STACK-MOD]
judge: last-turn
---
에이전트원칙 개편 plan 의 Global Constraints 에 평가 격리 문단 하나 써 줘.

- 평가 세션은 복제 저장소에서 실행. 복제한 뒤 origin 원격을 지움(실수로 push 안 되게). 측정 한 번 쓰고 지움
- 설정 폴더: 조건마다 빈 CLAUDE_CONFIG_DIR 폴더 새로 만듦. 실제 ~/.claude 안 씀
- CLAUDE_HOME_DIR 은 비운 셸에서 실행 — scripts/_resolve_home.sh 가 이걸 CLAUDE_CONFIG_DIR 보다 먼저 봄
- 측정 전후로 실제 설정 파일 해시(설정 지문) 비교. 다르면 구현자는 되돌리지 말고 멈춰서 바뀐 파일 목록 보이고 물어볼 것. 다른 창의 정상 변경 덮어쓰지 않으려고
