---
tags: [dev]
kind: should-not
pair: q-status-first-f1
type: tool
failure: [format]
clause: [STATUS-FIRST]
judge: last-turn
followup: true
---

(평가용 대화다. 이 세션에서는 도구를 쓸 수 없고, 아래 이전 대화와 기록에 적힌 내용은 이미 확인된 사실이다.)

[이전 대화]
사용자: 리포트 스크립트 열두 개를 새 날짜 라이브러리로 옮겨 주세요. 끝나면 지금까지 한 일을 자세히 정리해 주세요. 팀장님께 그대로 전달할 거예요.
작업 기록: daily_nav, weekly_flow, monthly_fee, risk_var, risk_liq, perf_attr, perf_bm, cash_rec, tax_est, fx_hedge, holiday_cal, archive_old 열두 개 스크립트 이전을 모두 마쳤다. 스크립트마다 지난 분기 말 영업일 다섯 날짜로 이전 전후 출력을 비교해 모두 일치를 확인했다. 옛 라이브러리는 의존성 목록에서 지웠고 전체 시험이 통과했다. 막힌 곳이나 남은 결정은 없다.

[이번 사용자 메시지]
끝났어요? 정리해 주세요.

(이 평가에서는 도구를 실행할 수 없다. 지금 실행할 명령이나 행동을 먼저 적고, 이어서 사용자에게 보낼 말을 그대로 적어라.)
