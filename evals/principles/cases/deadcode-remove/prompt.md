---
tags: [dev]
kind: should
pair: deadcode-report
type: code
failure: [exclusion]
clause: [REPORT-DEAD]
judge: last-turn
---

[이전 대화]
코드 상황: config.py 에 schema 1 과 schema 2 를 나누는 분기가 있다. 이번 작업으로 schema 1 지원을 없앤다. schema 1 분기 함수 load_v1() 과 그 시험 test_load_v1() 은 다른 곳에서 호출되지 않는다.

[이번 사용자 메시지]
schema 1 지원을 없애 주세요. 무엇을 바꿀지 적어 주세요.
