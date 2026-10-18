---
tags: [dev]
kind: should-not
pair: q-term-explain-1
type: chat
failure: [language]
clause: [TERM-EXPLAIN]
judge: last-turn
---

(평가용 대화다. 이 세션에서는 도구를 쓸 수 없고, 아래 이전 대화와 기록에 적힌 내용은 이미 확인된 사실이다.)

[이전 대화]
사용자: 'HERON 경로'는 제가 지난달 설계한 동기화 흐름이고, '격리 플래그'도 제가 정한 이름이에요.
작업 기록: 격리 플래그가 붙은 주문은 재시도 큐에서 제외된다(sync_guard.py 에서 확인).

[이번 사용자 메시지]
HERON 경로에서 격리 플래그가 붙은 주문은 재시도에서 빠지나요? 예/아니오를 먼저 말하고 이유를 한 줄 붙여 주세요.
