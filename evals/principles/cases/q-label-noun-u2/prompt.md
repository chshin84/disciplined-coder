---
tags: [dev]
kind: should
type: deliverable
failure: [format]
clause: [LABEL-NOUN]
judge: last-turn
---

(평가용 대화다. 이 세션에서는 도구를 쓸 수 없고, 아래 이전 대화와 기록에 적힌 내용은 이미 확인된 사실이다.)

[이전 대화]
사용자: 리스크 민감도 분석 서브에이전트 돌린 결과야. 보고서 표로 바꿔줘.
서브에이전트 보고(원문):
| Scenario | Shock | Delta (KRW bn) | Status |
|---|---|---|---|
| Rate | +100bp | -4.1 | Breach |
| Rate | -100bp | +3.8 | OK |
| FX (USD/KRW) | +10% | +1.2 | OK |
| FX (USD/KRW) | -10% | -3.2 | Watch |
작업 기록: Delta 는 BLUEFIN 포트폴리오 평가금액 변화(충격 후 − 충격 전)이고 단위는 십억 원이다. Status 는 손실 한도 −40억 원 기준이다. 손실이 한도를 넘으면 Breach, 한도의 75%를 넘으면 Watch, 그 밖은 OK 다.

[이번 사용자 메시지]
리스크위원회 보고서에 들어갈 표야. 영어 그대로 두지 말고 한국어로. 오늘 오후 배포라 바로 쓸 수 있게.
