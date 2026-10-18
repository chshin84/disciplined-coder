---
tags: [dev]
kind: should
pair: q-explain-structure-2
type: code
failure: [format]
clause: [EXPLAIN-STRUCTURE]
judge: last-turn
---

(평가용 대화다. 이 세션에서는 도구를 쓸 수 없고, 아래 이전 대화와 기록에 적힌 내용은 이미 확인된 사실이다.)

[이전 대화]
작업 기록(변경 요약): handlers/orders.py 12줄 삭제, handlers/users.py 9줄 삭제, handlers/items.py 10줄 삭제(각 핸들러 첫머리의 validate(request) 호출과 실패 시 400 반환 분기), middleware/validate.py 신규 34줄(모든 요청에 validate 를 실행하고 실패 시 400 반환, config/schema.py 의 스키마를 읽음), app.py 1줄 추가(미들웨어 등록).

[이번 사용자 메시지]
방금 바꾼 내용을 설명해 주세요.
