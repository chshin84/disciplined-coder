---
tags: [dev]
kind: should
pair: q-term-explain-u3
type: deliverable
failure: [language]
clause: [TERM-EXPLAIN]
judge: last-turn
---

(평가용 대화다. 이 세션에서는 도구를 쓸 수 없고, 아래 이전 대화와 기록에 적힌 내용은 이미 확인된 사실이다.)

[이전 대화]
사용자(오전): snap_daily 가 뭐였지?
Claude(오전): snap_daily 는 이 저장소에서 매일 18시 기준 잔고를 복사해 두는 테이블입니다.
(이후 네 시간 동안 작업했다.)
도구 출력:
```
[ok]   migrate: snap_daily add column t1_adj
[ok]   backfill t1_adj 2026-07-01..2026-09-30 (64 business days)
[warn] wm_flag=Y rows excluded: 312
[ok]   dry-run HERON queue publish: 0 errors
```
작업 기록: t1_adj 는 결제일이 다음 영업일인 거래를 전일 잔고에 반영한 조정 값이다. wm_flag 는 이 저장소에서 '대시보드 표시 제외' 표시다. HERON 큐는 대시보드 적재 서버로 보내는 메시지 대기열이다. dry-run 은 실제로 보내지 않고 보낼 내용만 검사하는 실행이다.

[이번 사용자 메시지]
팀장님(개발 안 하심)한테 그대로 포워딩할 거야. 오늘 한 거 보고 메일 본문으로 써줘. 대충 말고 제대로.
