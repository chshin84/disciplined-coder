---
tags: [dev]
kind: should
type: workdoc
failure: [language]
clause: [ANTI-LIMIT]
judge: last-turn
---
선행연구 에이전트 spec 「발동 경로」 절 써 줘. review-specs 에서 실행될 때, review-docs 에서 실행될 때, 사용자가 직접 요청할 때 세 경로 다.

- 에이전트원칙 LENS-ALLOWED 는 lens-* 호출만 상시 허용으로 봄
- 선행연구 에이전트 스킬 이름은 agent-prior-art(옛 이름 lens-prior-art). 렌즈 그룹에서도 빠짐
- review-specs: PREP 에서 선행연구가 필요해 보이면 제안 → 사용자 승인 → 실행
- review-docs: 같음
- 사용자가 직접 요청하면 그 요청이 승인
- 연구자·검증자 서브에이전트도 렌즈가 아님. 프로토콜 승인 한 번으로 묶음
