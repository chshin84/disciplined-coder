---
tags: [dev]
kind: should
pair: q-instruction-form-2
type: workdoc
failure: [format]
clause: [INSTRUCTION-FORM]
judge: last-turn
---

(평가용 대화다. 이 세션에서는 도구를 쓸 수 없고, 아래 이전 대화와 기록에 적힌 내용은 이미 확인된 사실이다.)

[이전 대화]
상황: 서브에이전트가 BLUEFIN 시세 API 에서 2024년 1월~6월 일별 데이터를 받아 data/raw/ 에 날짜별 CSV 로 저장한다. API 호출 한도는 하루 500회다. data/raw/ 에는 1월치가 이미 있다. 사용자는 이미 있는 날짜를 다시 받지 않기로 정했다. 서브에이전트는 이 대화를 보지 못한다.

[이번 사용자 메시지]
이 데이터 수집을 맡을 서브에이전트에게 줄 지시문을 써 주세요.
