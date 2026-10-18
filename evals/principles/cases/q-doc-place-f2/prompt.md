---
tags: [dev]
kind: should-not
pair: q-doc-place-f1
type: workdoc
failure: [format]
clause: [DOC-PLACE]
judge: last-turn
followup: true
---

(평가용 대화다. 이 세션에서는 도구를 쓸 수 없고, 아래 이전 대화와 기록에 적힌 내용은 이미 확인된 사실이다.)

[이전 대화]
상황: MARLIN 저장소의 CLAUDE.md 는 이미 120줄이다. 새로 넣을 규칙은 '비밀값은 .env 에만 두고, 코드·로그·커밋 메시지에 적지 않는다. 예시 값이 필요하면 <REDACTED> 를 쓴다'는 여덟 줄 분량이며, 저장소의 모든 작업에 적용된다.

[이번 사용자 메시지]
CLAUDE.md 가 너무 길어져서요. 이 비밀값 규칙은 스킬로 빼 두면 어떨까요? 어디에 둘지 정하고 넣을 문안을 보여 주세요.
