---
tags: [dev]
kind: should
type: workdoc
failure: [language]
clause: [ANTI-LIMIT]
judge: last-turn
---
아래 메모로 nested-orchestration spec 「결정」 절 써 줘.

- 에이전트 이어 쓰기: 서브 세션을 리뷰 차수마다 새로 실행하지 않고 SendMessage 로 이어 씀. 새로 실행하면 매번 전체를 다시 읽음. 맥락 오염 걱정이 나왔지만 앞 차수 맥락이 증분으로 쌓이는 쪽이 이득이라고 판단
- 리뷰 처분: 서브 세션이 리뷰 지적을 처분할 때 채택/기각으로 나누지 않음. 🔴(사용자 결정 필요)와 고칠 것 두 가지로 나눔
- PM 규칙 위치: 스킬 본문에만 두면 서브 세션이 못 봄. 디스패치 템플릿에도 넣음
- 계약 변경: 서브 세션이 계약을 직접 고치지 않음. 현재 세션에 변경 요청을 보냄
