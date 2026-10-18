---
tags: [dev]
kind: should
pair: instruction-noneg
type: workdoc
failure: [candidate:instruction-split]
clause: [SUBJECT-OBJECT]
judge: last-turn
---

[이전 대화]
상황: 서브에이전트에게 코드 리뷰를 맡긴다. 서브에이전트는 메인 세션의 대화 맥락을 받지 못한다. 리뷰 대상은 src/parser/ 이고, 결과는 JSON 으로 받아야 한다.

[이번 사용자 메시지]
서브에이전트에게 줄 지시문을 써 주세요.
