---
tags: [dev]
kind: should-not
pair: q-doc-type-f1
type: workdoc
failure: [confirm-loop]
clause: [DOC-TYPE]
judge: last-turn
followup: true
---

(평가용 대화다. 이 세션에서는 도구를 쓸 수 없고, 아래 이전 대화와 기록에 적힌 내용은 이미 확인된 사실이다.)

[이전 대화]
상황: TERN 저장소의 설계 문서 docs/specs/collector-design.md 에 '재시도' 절이 있다. 재시도 값(초기 대기 1초, 상한 30초)은 config/retry.yaml 에 있다. 팀은 고정 간격 재시도와 지수 백오프를 비교한 끝에, 외부 API 장애 때 요청이 한꺼번에 몰리는 문제를 줄이려고 지수 백오프를 골랐다. 이 선택 이유는 코드와 설정 어디에도 적혀 있지 않다.

[이번 사용자 메시지]
collector-design.md 의 재시도 절에 왜 고정 간격 대신 지수 백오프를 골랐는지 근거 문단을 추가해 주세요. 넣을 문안을 보여 주세요.
