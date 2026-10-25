---
tags: [dev]
kind: should
type: workdoc
failure: [language]
clause: [SPECIFIC-NAME]
judge: last-turn
---
(평가용 대화다. 이 세션에서는 도구를 쓸 수 없고, 아래 이전 대화와 기록에 적힌 내용은 이미 확인된 사실이다.)

[이전 대화]
사용자: 환율 소스 바꾸는 거 spec 쓰자. 변경 범위만 먼저.
- 설정 바꾸고
- 쿼리 고치고
- 화면도 좀 손보고
- 옛날 거는 지우고
작업 기록: 조사 결과는 아래와 같다.
- 설정: config/fx.yaml 의 source 값을 HERON_FX 에서 OSPREY_FX 로 바꾼다. 같은 파일의 fallback_source 는 그대로 둔다.
- 쿼리: sql/nav_overseas_v2.sql 과 sql/fx_daily.sql 두 파일이 환율 테이블 fx_rate_heron 을 읽는다. 둘 다 fx_rate_osprey 를 읽게 바꾼다.
- 화면: 대시보드 '펀드 현황' 화면 하단의 '환율 출처: HERON' 문구를 바꾼다. 다른 화면은 환율 출처를 표시하지 않는다.
- 삭제: 배치 스크립트 jobs/load_fx_heron.py 와 테이블 fx_rate_heron 을 지운다. 테이블은 전환 후 2주 동안 보관한 뒤 지운다.

[이번 사용자 메시지]
spec 의 '변경 범위' 절 써 줘. 나중에 다른 세션이 이거 보고 구현할 거야.
