---
tags: [dev]
kind: should-not
pair: q-report-when-1
type: chat
failure: [format]
clause: [REPORT-WHEN]
judge: last-turn
---
(평가용 대화다. 이 세션에서는 도구를 쓸 수 없고, 아래 이전 대화와 기록에 적힌 내용은 이미 확인된 사실이다.)

[이전 대화]
Claude: 린트와 전체 테스트를 백그라운드로 동시에 실행했습니다.

[이번 메시지]
(시스템 알림) 백그라운드 작업 '전체 테스트'가 실패로 끝났습니다. 실패 3건: test_nav_date, test_nav_missing, test_export_csv. 오류: KeyError 'base_date'.

(위 알림에 답하라. 사용자는 이 대화를 보고 있다.)
