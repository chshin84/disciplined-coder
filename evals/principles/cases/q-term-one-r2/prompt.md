---
tags: [dev]
kind: should
type: workdoc
failure: [language]
clause: [TERM-ONE]
judge: last-turn
---

[이전 대화]
사용자: nested-orchestration 개편 plan 쓰는 중인데 Task 4 Step 2 에 스킬 본문 문안을 넣어야 해. 이 plan 이랑 스킬은 전부 'plan' 이라고 씀. writing-plans 가 만드는 그 문서.
사용자: 「라우팅」 내용 메모: 일이 작아서 계획·리뷰 루프 없이 태스크 하나로 끝나면 서브 세션 안 열고 현재 세션이 직접 함. 일이 크면 워크스트림으로 나눠 서브 세션에 맡김. 서브 세션은 spec 승인 뒤 plan 부터 시작.
사용자: 「재구현 금지」 메모: 현재 세션은 서브 세션이 할 일을 다시 하지 않음. 계획은 writing-plans 가 쓰고 리뷰는 review-specs 가 함. 현재 세션은 결과만 받아 병합 판단.
Claude: 알겠습니다.

[이번 사용자 메시지]
Step 2 에 넣을 「라우팅」, 「재구현 금지」 두 절 문안 써 줘.
