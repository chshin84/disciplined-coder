# 메타 산출물 독립 리뷰 (meta-artifact independent review) — 설계

> 상태: **REVIEWED** (v2). DRAFT(v1)를 3렌즈 독립 리뷰(correctness/consistency/adversarial)에 돌려
> 발견을 반영해 재작성. 이 문서 자체가 이 기능의 첫 dogfooding 사례다.
> 작성: 2026-06-14. 대상: disciplined-coder 플러그인 자체.
>
> **리뷰가 바꾼 것(요약)**: v1의 3렌즈·메타집계·regenerate 루프·차용 리스크공식은 과설계(YAGNI)·SSOT 위반·
> 비용미상한으로 지적됨 → **MVP=독립 리뷰어 1회**로 축소, 나머지는 명시적 보류. 아래 §8 "리뷰 반영 로그" 참조.

## 1. 문제 (왜)

disciplined-coder의 본질 = "**LLM 콜 하나를 그대로 믿지 말고, 위험에 비례한 검증 레이어를 붙여라**".
그런데 Claude가 `brainstorming`/`writing-plans`로 만드는 **spec·plan도 LLM 산출물**인데 검증이 빈약하다:

- `brainstorming` 체크리스트 9단계 중 **7번이 self-review**(작성자가 자기 글을 봄) → 확증 편향에 약함.
- `writing-plans` Self-Review는 **"This is a checklist you run yourself — not a subagent dispatch"**.
  → 단, 이는 *self-review 단계*를 서브에 넘기지 말라는 것이지, 독립 리뷰 자체의 금지가 아니다.
  실제 superpowers엔 `skills/brainstorming/spec-document-reviewer-prompt.md`(**독립 리뷰어 1렌즈 템플릿**)가
  *별도로* 존재한다 — 다만 어디서도 호출되지 않는 **고아**다. (직접 확인: grep 무참조.)

즉 superpowers는 "self-review 후 **독립 리뷰**"라는 방향 자체는 열어뒀고(고아 템플릿이 증거), 우리는 그걸
**충돌 없이 배선**하면 된다. 실측(dogfooding): 독립 신선 에이전트가 self-review로는 못 잡는 사실 오류
(예: 리전별 비용·distance 정의·에뮬레이터 인덱스 — *타 세션 일화, 검증 불가*)를 잡았다.

## 2. 목표 / 비목표

**목표**
- Claude가 만든 **고위험 spec/plan**에 **독립(별도 컨텍스트) 리뷰어 1회**를 위험 비례로 적용.
- superpowers self-review **뒤에 레이어를 추가**(대체·수정 아님). superpowers 스킬은 건드리지 않는다.
- 결과를 `advisor-meta`의 실제 결정(accept / regenerate / escalate)으로 처리.

**비목표 (YAGNI — 지금 안 한다)**
- 다렌즈(3렌즈)·메타 집계·자동 regenerate 루프 → **보류**(§7). MVP는 리뷰어 1회.
- 모든 spec/plan 블랭킷 리뷰 → 안 한다. 기본은 현행 self-review, 고위험만 독립 리뷰.
- 결정론 PostToolUse 훅 → **보류**(feasibility 미검증, §7·E1).
- 제품 런타임 LLM 검증(`advisor-correctness/fit`) 대체 아님 — 그건 제품 코드 청사진, 이건 **Claude의 메타 산출물** 검증(별개 축).

## 3. 분류·네이밍 (확정)

- 스킬명: **`advisor-spec-review`** (advisor 계열과 일관). 본문 첫 줄에 "**제품 런타임 콜이 아니라
  Claude의 설계 문서(spec/plan) 리뷰 절차**"임을 명시해 기존 advisor(제품 청사진)와 구분.
- `domains-index`에는 **노출하지 않는다**(이미 advisor-* 참고 경로가 있음 — SSOT·과노출 방지).
- 호출 주체: **메인 세션만**(서브에이전트는 리뷰어로 *불려갈* 뿐, 스스로 이 스킬을 호출하지 않음).

## 4. 설계 (MVP)

### 4.1 위험 게이트 (블랭킷 방지 — 기준 객관화)
domain-llm-runtime과 **같은 "위험 비례" 철학**을 따르되, 메타 산출물용 **별도 루브릭**(복제 아님):
- 객관 기준으로 채점(주관 "판단" 최소화):
  - 아키텍처/구조 결정을 새로 내림 +1
  - 마이그레이션·삭제 등 **비가역** 작업 포함 +1
  - **검증 안 된 외부 사실**을 단정(구체 비용·SLA·API 시그니처·리전 등) +1
  - 공개 인터페이스/계약 **변경** +1
  - 문서가 3개 이상 독립 서브시스템을 다룸 +1
- **0–1**: self-review만(현행, 변경 없음). **2+**: 독립 리뷰어 1회.
- (4–5의 다렌즈 강화는 §7 보류 — 통증 측정 후.)

### 4.2 리뷰어 (MVP = 1회, 저환각 렌즈 병합)
독립 read-only 서브에이전트 **1명**에게 아래 두 축을 **한 번에** 검토시킨다(문서 1회 read = 토큰 절약):
- **factual/grounding**: 외부 사실·비용·API·환경 주장이 근거 있나; 근거 없는 단정.
- **consistency/coverage**: 내부 모순, spec↔plan 커버리지 공백, 타입·이름 드리프트, 스코프.
- (※ "adversarial/YAGNI" 렌즈는 환각 위험이 커 MVP 제외 — §7 보류.)

### 4.3 단일 작성자 + 보고 (재기술 아님 — 참조)
`coding-principles.md`의 **"단일 작성자 + 보고"** 절차를 그대로 따른다(여기 복제하지 않음):
리뷰어는 **read-only**(구조적으로 Edit/Write 없는 에이전트 사용 → FAIL-LOUD), 발견을 **JSON 리턴**으로만 보고,
메인이 취합·편집·로그. 출력 스키마는 `advisor-correctness`와 동일 계열.

### 4.4 라우팅 (advisor-meta 실제 enum 사용)
- **critical 0** → `accept`: major/minor는 **인라인 부분 수정**(부분수정이 기본 — 비파괴·타깃).
- **critical ≥1** → `regenerate`: 해당 **섹션만** 재작성(문서 전체 재작성 금지).
- **수렴 가드(중요)**: 1회 regenerate 후에도 critical 잔존, 또는 방향성·아키텍처 결함, 또는 사용자 부재로
  결정 불가 → 즉시 **`escalate`**(🔴 unsolved 등록, 자율 구현 금지). **자동 루프 금지**(비용·무한대기 방지).

### 4.5 비용 (명시)
- 리뷰어에 **검증에 필요한 문맥만** 전달(전체 레포 아님). 리뷰어 1회 + 메인 집계(코드 로직, LLM 불필요).
- regenerate는 최대 1회(§4.4 가드) → 콜 수 상한이 구조적으로 고정(리뷰 1 + 재리뷰 최대 1).

## 5. 변경 파일
- **신규** `skills/advisor-spec-review/SKILL.md` — 위 §3·§4를 절차로. 렌즈 프롬프트·JSON 스키마·라우팅·수렴가드.
- **수정** `coding-principles.md` "절차 — 계획 시점 절차"에 한 줄: 고위험 spec/plan은 `advisor-spec-review`로 독립 리뷰.
- **수정** `README.md` "구성"의 advisor 설명을 새 스킬 포함하도록 동기화(SSOT). 단 "4종(제품 런타임)"과 구분 표기.
- **등록** `unsolved_problems.md`(PC) — 결정론 훅을 🟡로(E1). 메인 세션이 기록.
- (수정 안 함: superpowers 스킬, domains-index.)

## 6. 검증 / 롤백
- `bash scripts/test_scaffold.sh` → **FAIL=0**(이 변경은 scaffold 동작 불변 → 회귀 없어야 함).
- `claude plugin validate ./` (non-strict).
- 스킬 자체 검증: 본 문서(v1→v2) 리뷰가 첫 수동 케이스 — 실제로 critical/major를 잡아 라우팅이 동작함을 보였다.
- **롤백(REVERSIBLE)**: 가역적. 되돌리려면 (1) 스킬 디렉터리 삭제, (2) coding-principles 한 줄 제거,
  (3) README 동기화 되돌리기. 절차가 "온디맨드 스킬 + 한 줄"이라 박힌 의존성 없음.

## 7. 보류 (측정 먼저 — MEASURE-FIRST)
지금 짓지 않고, 통증/비용을 실측한 뒤 재평가:
- **다렌즈(3렌즈)+메타 집계**: 리뷰어 1회로 부족하다는 실측이 쌓이면 도입. adversarial 렌즈는 환각 가드 설계 후.
- **결정론 PostToolUse 훅**: CC 플러그인 PostToolUse의 경로 매칭 가능 여부 미검증(E1) → unsolved 🟡.
- **자동 regenerate 루프(>1)**: 비용·수렴 데이터 확보 후.

## 8. 리뷰 반영 로그 (dogfooding 기록)
v1 DRAFT를 3 독립 렌즈에 돌린 결과(전원 verdict=revise)와 처리:
- F1 regenerate 수렴 미보장(critical) → §4.4 수렴 가드(1회 후 escalate, 루프 금지).
- F2 비용 상한 미명시(critical) → §4.5.
- F3 superpowers 충돌(critical) → 사실 해소: self-review 뒤 레이어 추가, 충돌 아님(§1).
- F4 리스크 공식 차용 왜곡·SSOT(major) → §4.1 "같은 철학, 별도 루브릭"으로 정정.
- F5 3렌즈 과설계(major) → MVP=리뷰어 1회(§4.2), 다렌즈 보류(§7).
- F6 accept-with-edits enum 부재(major) → §4.4 실제 enum.
- F7 단일작성자·렌즈 중복 기술(major) → §4.3 참조로 축소.
- F8 게이트 블랭킷화(major) → §4.1 기준 객관화.
- F9 롤백·호출주체·검증 누락(minor) → §3·§6.
- E1 결정론 훅 / E2 superpowers wrap 방향성 → 사용자 escalate(최종 보고).
