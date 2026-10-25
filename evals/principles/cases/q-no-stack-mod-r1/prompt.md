---
tags: [dev]
kind: should
type: workdoc
failure: [language]
clause: [NO-STACK-MOD]
judge: last-turn
---
nested-orchestration 스킬 고치는 spec 머리말 첫 문단 써 줘. 오늘이 2026-10-09고 파일은 docs/superpowers/specs/2026-10-09-nested-orchestration-large-dev-design.md 야.

메모:
- 대상: 큰 개발. 기능이 여러 개 섞여 있음. 한 세션이 다 하면 맥락이 넘침
- 바꾸는 것: 현재 세션(사용자랑 대화하는 세션)은 PM 역할만. 큰 명세·계약·통합만 맡음
- 워크스트림마다 서브 세션 하나가 하부 명세 → plan → 구현까지 맡음
- 출발점: 사용자가 gm-dashboard 세션(D:\test\gm_dashboard, 2026-10-07)에 붙여 넣은 「큰 개발의 명세 분할 지시문」
- 지시문 초안과 선행연구는 docs/대화전문-2026-10-06_07.md 156행 이후
