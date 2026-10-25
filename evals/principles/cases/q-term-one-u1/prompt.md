---
tags: [dev]
kind: should
pair: q-term-one-u3
type: deliverable
failure: [language]
clause: [TERM-ONE]
judge: last-turn
---

(평가용 대화다. 이 세션에서는 도구를 쓸 수 없고, 아래 이전 대화와 기록에 적힌 내용은 이미 확인된 사실이다.)

[이전 대화]
사용자: 다음 주부터 휴가라 후임한테 마감 작업 넘겨야 함.
Claude: 이 세션에서는 매일 23시에 실행되는 마감 작업을 '일마감 배치'로 부르겠습니다. 스케줄러에 등록된 작업 이름은 close_job 입니다.
사용자: ㅇㅋ. 근데 EOD 잡이 요즘 자주 늦게 끝나. 일마감 끝나야 대시보드 적재가 시작되는데.
서브에이전트 보고(원문): "close_job (a.k.a. the nightly batch) ran 23:00-01:40 on average over the last 10 days. EOD step 3 (NAV calculation) is the bottleneck at 70% of total runtime. The nightly run depends on HERON feed arrival."
사용자: 그리고 야간 배치 실패하면 당직이 수동 재실행해. 마감 배치 로그는 /logs/close 에 있어.

[이번 사용자 메시지]
후임용 인수인계 문서 써줘. 무슨 일 하는 건지, 언제 실행되는지, 뭐가 느린지, 실패하면 어떻게 하는지. 문단으로.
