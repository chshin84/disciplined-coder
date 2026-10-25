---
tags: [dev]
kind: should
type: workdoc
failure: [language]
clause: [ANTI-LIMIT]
judge: last-turn
---
skills/review-llm-calls/SKILL.md 서두 문단이랑 「비기능 체크리스트」 절 도입 문단 써 줘. 체크리스트 항목은 목록으로.

- 대상: 제품이 런타임에 LLM 을 호출하는 기능
- 단독 콜로 끝내지 말고 검증을 제품 코드에 구현
- 렌즈(lens-*) 스킬은 원래 Claude Code 서브에이전트로 실행하는 렌즈 정의. 여기서는 서브에이전트로 실행 안 하고, 제품 코드의 리뷰 콜을 설계하는 청사진으로만 씀
- 비기능 체크리스트: 특정 단계에만 적용하는 게 아님. 호출 코드 전체가 항상 만족해야 할 속성
- 항목: 타임아웃, 재시도 상한, 비용 상한, 로그 마스킹, 모델 ID 고정
