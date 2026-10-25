---
tags: [dev]
kind: should
type: workdoc
failure: [language]
clause: [COMMA-CUT]
judge: last-turn
---

[이전 대화]
사용자: 큰 개발 설계 문서 「결정」 절에 두 항목 추가.
사용자: (1) HARD-GATE 예외. brainstorming 의 HARD-GATE 는 사람이 spec 을 승인하고 plan 을 검토하고 실행 방식을 고르게 함. 서브 세션에는 사람이 없으니까 spec 승인은 현재 세션 승인으로, plan 검토는 review-specs 렌즈 리뷰로 대신하고, 실행 방식은 SDD 로 고정.
사용자: (2) 문서 수명과 진행 위치. 진행 상태는 문서에 안 적고 git 에서 도출. 통합 브랜치에 병합된 워크스트림 브랜치는 끝난 것, 병합 안 된 브랜치는 진행 중, 큰 명세 목록엔 있는데 브랜치가 없으면 시작 전.
Claude: 확인했습니다.

[이번 사용자 메시지]
「HARD-GATE 예외」, 「문서 수명과 진행 위치」 두 문단 써 줘.
