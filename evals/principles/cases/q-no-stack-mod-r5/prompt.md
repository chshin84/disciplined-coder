---
tags: [dev]
kind: should
type: workdoc
failure: [language]
clause: [NO-STACK-MOD]
judge: last-turn
---
조항 재작성 spec 「기계 검사」 절에 라벨 불릿 검출 규칙 설명 한 문단 써 줘. 훅 이름은 doc_form_check.

- 검출 대상: 불릿. 줄 머리가 굵은 글씨(**…**) 라벨로 시작함. 라벨 뒤 본문이 문장 두 개 이상
- 근거: BULLET-SCOPE 는 설명이 두 문장 넘으면 문단으로 쓰라고 함. 모델은 라벨 붙은 불릿에 설명을 몰아넣는 습관이 있음
- 코드 블록, 백틱, 인용 줄은 안 봄
- 검출되면 쓰기는 안 막고 경고만. 경고 문구: 산문 문단으로 바꿔라
