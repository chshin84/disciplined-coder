---
name: advisor-spec-review
description: Claude가 brainstorming/writing-plans로 만든 spec·plan(메타 산출물)을 3렌즈 독립 리뷰어로 검증하고 accept/regenerate/escalate로 라우팅하는 절차. superpowers spec/plan 작성 시 훅이 강제(PostToolUse 감지 + Stop 게이트). 제품 런타임 콜이 아니라 Claude 자신의 설계 문서 리뷰다.
---
# spec/plan 독립 리뷰 어드바이저 (advisor-spec-review)

> **이건 제품 코드 청사진이 아니다.** 다른 advisor-*(correctness/fit/meta)는 *제품이 런타임에 LLM을 호출할 때* 제품 코드가 구현할 검증 레이어다.
> 이 스킬은 *Claude가 설계 문서(spec/plan)를 만들 때* **메인 세션이 직접 서브에이전트를 디스패치**해 돌리는 CC 워크플로다. superpowers의 self-review를 **대체하지 않고 뒤에 레이어를 더한다**.

## 왜
brainstorming·writing-plans의 self-review는 **작성자가 자기 글을 보는 것**이라 확증 편향에 약하다(writing-plans는 self-review를 "not a subagent dispatch"라 못박지만 독립 리뷰 자체를 금하진 않는다). 고위험 설계는 **자기가 안 쓴 신선한 리뷰어**가 편향을 깬다.

## 강제 (훅) — 건너뛸 수 없음
superpowers 기본 경로(`docs/superpowers/{specs,plans}/*.md`)에 spec/plan이 쓰이면:
- **PostToolUse**가 즉시 감지해 이 스킬 수행을 지시(비블로킹).
- **Stop**이 미리뷰 spec/plan이 남은 채 턴이 끝나는 것을 차단(하드 게이트).
- 완료 후 문서 **마지막 줄**에 마커를 남기면 해제: `<!-- spec-review: passed lenses=3 date=YYYY-MM-DD -->` (escalate면 `escalated`). **terminal(passed/escalated)만 마커** — pending은 마커가 아니다.
- 끄기: env `DISCIPLINED_CODER_REVIEW_GATE=off`. (전역 훅 — `hooks/hooks.json`.)

## 리뷰 절차

### 1) PREP (TDD의 "기대 먼저" — 즉흥 금지)
디스패치 *전에* 메인이 렌즈별로 준비한다:
- **주입 지식**: 원문(spec/plan 경로) + 관련 백그라운드 — `coding-principles` 해당 원칙, 선행 결정/이전 spec, **검증할 구체 사실**, 관련 파일 경로. (단일 작성자 원칙의 "메인이 dispatch에 관련 항목을 실어 전달"을 정형화.)
- **타깃 체크리스트**: 그 렌즈가 *무엇을* 볼지 미리 명세.
→ 리뷰가 즉흥이 아니라 **준비된 명세에 대한 검증**(미스↓, 일관성↑).

### 2) 디스패치 — 3렌즈 (고정, 병렬, read-only)
독립 **read-only 서브에이전트**(Edit/Write 없는 에이전트 — 구조적 거짓방지). 각 렌즈가 원문+백그라운드를 주입받아 자기 내러티브로 파고들어 **사각이 다르다**(실증: 세 렌즈가 각각 다른 critical을 단독 검출).
- **factual/grounding**: 외부 사실·비용·API·환경 주장의 근거; 근거 없는 단정·환각.
- **consistency/coverage**: 내부 모순, spec↔plan 커버리지 공백, 타입·이름 드리프트, 스코프.
- **adversarial/YAGNI**: 실패 모드·과설계·비가역·자기모순. 가드: "기능 추가 제안 금지(YAGNI 리뷰가 기능 늘리면 자가당착), 근거 필수."

출력 스키마(JSON, advisor-correctness 계열):
```
{ "lens": "...", "issues": [ { "severity": "critical|major|minor", "type": "...", "where": "...", "detail": "..." } ], "verdict": "ok|revise", "notes": "" }
```

### 3) 메타 집계 (advisor-meta 재사용 — 재기술 안 함)
severity 정렬·출처 태깅·상충 감지(코드 로직, LLM 불필요) → decision. 단일 작성자: 리뷰어는 JSON 리턴만, 메인이 취합·반영·마커 기록.

## 라우팅 → 반영 → 재작업
- **accept**(critical 0): major/minor **부분 수정**(부분수정이 기본 — `NON-DESTRUCTIVE`) → 마커(passed).
- **regenerate**(critical ≥1): 지적된 **섹션만** 재작성 → 그 섹션만 재리뷰. **상한 1회**, 잔존 시 escalate.
- **escalate**(상충/방향성/사용자 부재): 🔴 `unsolved_problems.md` 등록 + 마커(escalated). 게이트 해제(사람 결정 대기). **자동 루프 금지**.

## 한계 (정직히 — FAIL-LOUD)
훅은 마커 *존재*만 검사 — 리뷰 없이 마커만 달면 못 막는다. 구조적 완화(read-only 리뷰어 JSON 리턴)는 있으나 완벽 강제 불가. 탐지 밖(커스텀 경로·비-git)에선 FAIL-OPEN(작업불능 방지).
