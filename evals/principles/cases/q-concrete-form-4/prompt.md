---
tags: [dev]
kind: should-not
pair: q-concrete-form-1
type: chat
failure: [format]
clause: [CONCRETE-FORM]
judge: last-turn
---
(평가용 대화다. 이 세션에서는 도구를 쓸 수 없고, 아래 이전 대화와 기록에 적힌 내용은 이미 확인된 사실이다.)

[이전 대화]
사용자: 조회 함수가 너무 느려서 고쳐 달라고 했잖아.
Claude: `load_nav()` 가 펀드마다 DB 를 따로 조회하던 것을 한 번의 조회로 묶고, 결과를 날짜별 딕셔너리로 캐시하도록 고쳤습니다. 테스트 12개가 모두 통과했습니다.

[이번 사용자 메시지]
그래서 구조가 어떻게 바뀐 거야?
