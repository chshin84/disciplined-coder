---
name: advisor-spec-review
description: Claude가 brainstorming/writing-plans로 만든 spec·plan(메타 산출물)을 고위험일 때 독립(별도 컨텍스트) 리뷰어로 검증하고 accept/regenerate/escalate로 라우팅하는 절차. 제품 런타임 콜이 아니라 Claude 자신의 설계 문서 리뷰다.
---
# spec/plan 독립 리뷰 어드바이저 (advisor-spec-review)

> **이건 제품 코드 청사진이 아니다.** 다른 advisor-*(correctness/fit/meta)는 *제품이 런타임에 LLM을 호출할 때*
> 제품 코드가 구현할 검증 레이어다. 이 스킬은 *Claude가 설계 문서(spec/plan)를 만들 때* **메인 세션이 직접
> 서브에이전트를 디스패치**해 돌리는 CC 워크플로다. superpowers의 self-review를 **대체하지 않고 뒤에 레이어를 더한다**.

## 왜
brainstorming의 self-review·writing-plans의 self-review는 **작성자가 자기 글을 보는 것**이라 확증 편향에 약하다
(writing-plans는 self-review 단계를 "not a subagent dispatch"라 못박지만, 독립 리뷰 자체를 금하진 않는다 —
superpowers에도 미배선 독립 리뷰어 템플릿이 있다). 고위험 설계는 **자기가 안 쓴 신선한 리뷰어**가 편향을 깬다.

## 언제 (위험 게이트 — 블랭킷 금지)
spec/plan을 쓴 직후 객관 기준으로 채점한다(같은 *위험 비례* 철학, domain-llm-runtime과는 **별도 루브릭**):
- 아키텍처/구조 결정을 새로 내림 **+1**
- 마이그레이션·삭제 등 **비가역** 작업 포함 **+1**
- **검증 안 된 외부 사실** 단정(구체 비용·SLA·API 시그니처·리전 등) **+1**
- 공개 인터페이스/계약 **변경** **+1**
- 3개 이상 독립 서브시스템을 다룸 **+1**

- **0–1**: self-review만(현행 superpowers, 추가 없음).
- **2+**: **독립 리뷰어 1회**(아래).

## 리뷰어 (MVP = 1회)
**read-only 서브에이전트 1명**(구조적으로 Edit/Write 없는 에이전트 — 예: Explore — 을 써서 로그 오염을 *구조로* 막는다,
`FAIL-LOUD`). 발견은 **JSON 리턴으로만** 보고하고 메인이 취합·편집한다(`coding-principles.md` "단일 작성자 + 보고" 준수 — 여기 재기술 안 함).

한 리뷰어가 두 축을 **함께** 본다(문서 1회 read = 토큰 절약):
- **factual/grounding**: 외부 사실·비용·API·환경 주장이 근거 있나; 근거 없는 단정·환각.
- **consistency/coverage**: 내부 모순, spec↔plan 커버리지 공백, 타입·이름 드리프트, 스코프 적정성.

> 다렌즈(3렌즈)·메타 집계는 리뷰어 1회로 부족하다는 **실측이 쌓이면** 도입(YAGNI·MEASURE-FIRST).
> "악마의 변호인(adversarial/YAGNI)" 렌즈는 환각으로 꼭 필요한 것을 "빼라"고 오판할 위험이 커, 가드 설계 전까지 제외.

### 리뷰어 디스패치 프롬프트 (언어 중립 골자)
- 역할: "너는 독립 설계 문서 검수자다. 고치지 말고 지적만. read-only — 어떤 파일도 쓰지 마라. 발견은 JSON 리턴으로만."
- 대상: spec/plan 파일 경로. 검증에 **필요한 문맥만** 함께 전달(전체 레포 아님 — 비용).
- 체크: 위 두 축. 근거 없으면 "근거 없음" 표시. 사실 주장은 **직접 읽어/검색해 확인**(근거를 대라).
- 캘리브레이션: 구현·계획에 실제 문제를 낳을 것만 critical/major. 스타일 취향 제외. 문제 없으면 issues:[]+ok.

### 출력 스키마 (JSON — advisor-correctness 계열)
```
{ "issues": [ { "severity": "critical|major|minor", "type": "factual|contradiction|coverage_gap|drift|scope|unsupported", "where": "섹션/인용", "detail": "무엇이 왜 + 올바른 사실/제안" } ], "verdict": "ok|revise", "notes": "검증 불가 항목 등" }
```

## 라우팅 (advisor-meta 결정 enum 사용 — 내용 재판단 금지, 구조만)
- **critical 0** → `accept`: major/minor는 **인라인 부분 수정**(부분수정이 기본 — `NON-DESTRUCTIVE`). 섹션 통째 재작성 금지.
- **critical ≥1** → `regenerate`: 지적된 **섹션만** 재작성 후, 그 섹션만 재리뷰.
- **수렴 가드(필수)**: 1회 regenerate 후에도 critical 잔존 · 방향성/아키텍처 결함 · 사용자 부재로 결정 불가 →
  즉시 **`escalate`**(🔴 `unsolved_problems.md` 등록, 자율 구현 금지). **자동 루프 금지**(비용·무한대기 방지 — 콜 수는 리뷰1+재리뷰1로 상한 고정).

## 비용
리뷰어 1회 + 메인 집계(코드 로직, LLM 불필요). 문맥 최소 전달. 결정론으로 잡히는 것(placeholder 스캔 등)은 코드/grep으로 먼저.
