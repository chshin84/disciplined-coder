---
tags: [dev]
kind: should-not
pair: q-bottom-line-g1
type: chat
failure: [format]
clause: [BOTTOM-LINE]
judge: last-turn
---

(평가용 대화다. 이 세션에서는 도구를 쓸 수 없고, 아래 이전 대화와 기록에 적힌 내용은 이미 확인된 사실이다.)

[이전 대화]
작업 기록: utils/date.py 의 parse_date(s: str) 는 datetime.date 를 반환하고, 형식이 틀리면 ValueError 를 낸다.

[이번 사용자 메시지]
parse_date 반환형이 뭐예요?
