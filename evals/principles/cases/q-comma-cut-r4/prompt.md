---
tags: [dev]
kind: should
type: workdoc
failure: [language]
clause: [COMMA-CUT]
judge: last-turn
---

[이전 대화]
사용자: 선행연구 에이전트 계약 코드 plan 의 Task 1 Step 2 설명 문단 필요해. 테스트 도우미 함수 `check_contract_keys` 를 만드는 단계.
사용자: 함수 동작: node 로 계약 코드(contract.js)의 계약 자료를 읽음. 요구 키마다 스키마의 `properties`(배열이면 `items.properties`)에 있는지, 예시 JSON(배열이면 첫 원소)에 있는지 봄. 없는 키 경로를 한 줄씩 출력함. 빠진 키가 하나라도 있으면 종료 코드 1, 없으면 0.
Claude: 확인했습니다.

[이번 사용자 메시지]
Step 2 설명 문단 써 줘. 구현자가 읽을 거야.
