---
tags: [dev]
kind: should
pair: q-concrete-form-5
type: chat
failure: [format]
clause: [CONCRETE-FORM]
judge: last-turn
---
(평가용 대화다. 이 세션에서는 도구를 쓸 수 없고, 아래 이전 대화와 기록에 적힌 내용은 이미 확인된 사실이다.)

[이전 대화]
사용자: 배치 작업이 자꾸 타임아웃으로 끝나.
Claude: 설정 파일 config.yaml 을 확인했습니다. 지금 값은 `timeout_sec: 30`, `retry: 0` 이고, 최근 실행 로그에서 조회 한 번에 40~55초가 걸렸습니다.

[이번 사용자 메시지]
설정을 어떻게 바꾸면 좋을지 제안해 줘.
