---
tags: [dev]
kind: should
type: workdoc
failure: [language]
clause: [COMMA-CUT]
judge: last-turn
---

[이전 대화]
사용자: 선행연구 워크플로 spec 의 「맡는 일과 전제」 절에 런타임 제약 문단 써야 해.
사용자: 사실: 워크플로 런타임은 스크립트를 중간부터 다시 실행할 때 같은 결과가 나와야 해서 결정적이어야 함. 그래서 스크립트는 현재 시각과 난수를 안 씀. 디스크에 파일도 안 씀. 실행 기록은 반환값으로만 넘기고, 파일로 남기는 건 호출한 오케스트레이터가 함.
사용자: 같은 절에 순수 함수 `groupByUrl` 설명도 하나. 입력 행마다 `url` 하나를 키로 묶음. 결과 `items` 의 원소는 `urls`(그 행의 url 하나), `text`(`JSON.stringify({ case, axes, outcome })`), `row`(행 전체).
Claude: 네.

[이번 사용자 메시지]
런타임 제약 문단이랑 groupByUrl 의 items 설명 써 줘.
