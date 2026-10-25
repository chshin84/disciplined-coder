---
tags: [dev]
kind: should
type: workdoc
failure: [language]
clause: [SPECIFIC-NAME]
judge: last-turn
---

[이전 대화]
사용자: 선행연구 에이전트 설계 문서에 「결정의 출처」 절 넣자. 누가 정했는지 묶어서 보여 주는 절.
사용자: 정리.
- 리서치(선행연구 대조)에서 나온 결정: 연구자 하나가 인용할 출처 약 100개 이하(cookbook "under about 100 sources"), 공백 라운드는 질문당 1회(deep-research 스킬), 검증자 판정 기준은 "옮긴 구절이 주어·수치·조건을 모두 포함하면 supported"
- 내가 2026-10-18 에 정한 결정: 탐색 연구자 수 통상 2개·최대 20개, 이 에이전트에는 dispatching-lenses 단계당 10개 상한을 적용하지 않음
- 메인 세션(설계 쓴 세션)이 정한 결정: maxTurns 20, 출력 스키마의 kind 열거에 standard 와 derived 추가
- 빌더(구현 세션)에게 맡긴 결정: maxTurns 가 도구 호출 수도 제한하는지 실측, 오케스트레이터 프롬프트 문구
Claude: 네. 절 하나에 굵은 라벨 네 개로 묶겠습니다.

[이번 사용자 메시지]
그 절 써 줘. 라벨 달고 항목은 불릿으로.
