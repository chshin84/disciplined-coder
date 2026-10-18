---
tags: [dev]
kind: should
pair: q-bottom-line-2
type: chat
failure: [format]
clause: [BOTTOM-LINE]
judge: last-turn
---

(평가용 대화다. 이 세션에서는 도구를 쓸 수 없고, 아래 이전 대화와 기록에 적힌 내용은 이미 확인된 사실이다.)

[이전 대화]
작업 기록: 캐시 만료 시간(TTL) 변경 부하 시험 결과다. TTL 5분일 때 DB 최고 초당 쿼리는 1,200, TTL 1분으로 바꾼 시험에서는 3,100이었다. 이 DB 의 안정 처리 한계는 초당 4,000이다. 시험 중 오류율 변화는 없었다.

[이번 사용자 메시지]
TTL을 1분으로 줄여도 DB가 버틸까요?
