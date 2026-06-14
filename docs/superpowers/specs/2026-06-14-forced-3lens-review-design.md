# spec/plan 강제 3렌즈 독립 리뷰 — 설계

> 상태: **REVIEWED (v2)**. DRAFT(v1)를 3렌즈 독립 리뷰에 돌려(전원 revise) 반영 재작성. 이 기능을 자기 자신에 dogfood.
> 작성: 2026-06-14. 대상: disciplined-coder 플러그인. 선행: `advisor-spec-review`(MVP 1렌즈, 596a91a).
>
> **선행 결정 번복 명시(중요)**: 직전 MVP는 "다렌즈는 MEASURE-FIRST로 보류, 결정론 훅도 보류(E1)"였다.
> **사용자가 이를 의도적으로 번복**했다("3렌즈 확장하자 … 강제로 훅을 걸든 뭘 하든 꼭 수행"). 근거: 사용자는
> *설계 오류를 놓치는 비용 > 리뷰 토큰 비용*으로 판단. 비용은 **spec/plan을 쓸 때만**(드물고 고가치 시점) 발생하므로
> 활동 비례. 단 훅 feasibility는 이번에 **실측 완료**(아래 §2) — v1의 "미검증 보류(E1)"는 해소됨.

## 1. 문제 / 목표
`advisor-spec-review`(MVP)는 메인 세션이 *절차로* 호출 → 작성자(Claude) 판단으로 건너뛸 수 있다.
사용자 요구: superpowers `brainstorming`/`writing-plans`가 **spec/plan을 쓴 직후, 강제로 3렌즈 독립 리뷰
→ 반영 → (부분)재작업**까지 잇는다. "꼭 수행"이 핵심.

**목표**: 탐지 가능 범위에서 리뷰를 *건너뛸 수 없게*(즉시 감지 + 턴 종료 하드 게이트), 3렌즈+메타 집계, 반영→부분 재작업, 완료 마커로 해제. superpowers 미수정.
**비목표**: 임의 문서 전체 아님(`docs/superpowers/{specs,plans}/*.md`만). 리뷰어가 코드 수정 안 함(지적만).

## 2. 실측된 CC 훅 동작 (MEASURE-FIRST — 공식 문서 기준)
- **PostToolUse**: `Write`/`Edit` 직후 발동, stdin JSON에 `tool_input.file_path` 포함 → 스크립트가 경로 매칭 가능. **블로킹 불가**(이미 쓰임) → 신호용. 출력은 **`hookSpecificOutput.additionalContext`(중첩)** 로 컨텍스트 주입(Claude가 무시 가능 — 약한 강제).
- **Stop**: 턴 종료 시 발동, **matcher 없음**. **top-level `{"decision":"block","reason":"…"}`** 로 종료를 막고 reason을 Claude에 피드백(강한 강제). 입력에 **`stop_hook_active`** 불리언 — 이미 Stop 훅이 block한 상태면 true(루프 가드).
  > ⚠️ v1의 "8회 연속 block 자동 해제"는 **공식 근거 불충분**(독립 factual 리뷰가 지적) → **의존하지 않는다**. 루프 방지는 `stop_hook_active` + 마커로 한다.
- **플러그인 hooks.json**: 이벤트 추가 시 플러그인 enabled인 모든 프로젝트에 적용(전역). → §6 비용·OFF 스위치로 완화.

## 3. 설계

### 3.1 완료 마커 (상태의 1차 진실 — 문서 마지막 줄)
리뷰+반영이 **terminal로 끝났을 때만** 메인이 문서 **마지막 비공백 줄**에 마커를 추가:
```
<!-- spec-review: passed lenses=3 date=YYYY-MM-DD -->        (또는)
<!-- spec-review: escalated lenses=3 date=YYYY-MM-DD -->
```
- **탐지는 마지막 비공백 줄만** 검사(`tail`+정규식). 이유: 본문 예시·설명에 'spec-review:' 문자열이 있어도 **거짓 매칭 불가**(adversarial 리뷰가 잡은 자기파괴 버그 해소). 정규식은 `<!-- spec-review: (passed|escalated)` — **terminal만**(pending은 마커가 아니다 → 거짓 해제 불가).
- `passed`·`escalated` 둘 다 게이트 해제(escalate=사람 결정 대기, 무한대기 방지).
- **거짓 리뷰 한계(정직히, FAIL-LOUD)**: 훅은 마커 *존재*만 검사 — Claude가 리뷰 없이 마커만 달면 못 막는다. 구조적 완화(§3.5 read-only 리뷰어 JSON 리턴)는 있으나 **완벽 강제 불가**. 또한 *이 마커 시스템을 문서화하는 메타-spec*이 마지막 줄에 예시 마커를 두면 자기-통과 가능(희귀 엣지 — 인정).

### 3.2 탐지 = git 변경분 + 마지막 줄 마커
- 대상: **git status에 변경(수정/신규)으로 잡힌** `docs/superpowers/{specs,plans}/*.md` 중, **마지막 비공백 줄이 terminal 마커가 아닌** 파일 = 미리뷰. (이미 커밋된 레거시는 git status에 안 잡혀 무시 — idempotent. 미커밋 미리뷰 spec이 있으면 리뷰하는 게 맞다.)
- **롤아웃 self-deadlock 방지(adversarial 지적)**: 훅 배선 전에 이 레포의 기존 미커밋 spec/plan을 먼저 커밋(클린 트리)하거나, 구현 중에는 OFF 스위치를 둔다. git 없으면 §6 폴백.

### 3.3 PostToolUse 훅 (즉시 감지·신호)
- matcher `Write|Edit`. 스크립트: `tool_input.file_path`가 specs/plans 경로 **아니면 즉시 exit 0(0-cost)**. 맞고 **마커 없음** → `additionalContext` 주입: "spec/plan(<파일>) 작성됨 — 진행 전 반드시 `advisor-spec-review`(3렌즈)를 수행하라." 마커 있으면 무출력(재작업 편집이 무한 재트리거 안 됨).

### 3.4 Stop 훅 (건너뛰기 불가 하드 게이트)
- **`stop_hook_active`가 true면 즉시 통과**(루프 가드 — 이미 게이트가 돌아 Claude가 작업 중).
- 0-cost 조기탈출: specs/plans 디렉터리 없거나 OFF 스위치(아래)면 즉시 exit 0.
- 아니면 §3.2로 미리뷰 파일 탐지 → 있으면 `{"decision":"block","reason":"미리뷰: <목록>. advisor-spec-review(3렌즈) 수행 후 frontmatter 마커를 남기고 종료하라."}`.
- **FAIL-LOUD**: 루프 가드로 통과시켰는데 여전히 미리뷰면(=Claude가 마커 없이 빠져나감) 그 사실을 reason/로그로 드러낸다(조용한 무효화 금지).

### 3.5 리뷰 = advisor-spec-review 3렌즈 + PREP (사용자 확정)
**3렌즈 고정**(사용자 결정 — 과설계 아님): 각 독립 렌즈가 원문+백그라운드를 주입받아 *자기 내러티브*로 파고들어 사각이 다르다. 실증: 이 기능의 spec·plan 리뷰에서 factual/consistency/adversarial가 **각각 다른 critical**을 단독으로 잡음(한 렌즈면 ≥2개 누락).

- **PREP (TDD의 "기대 먼저" — 신규)**: 리뷰어 디스패치 *전에* 메인이 렌즈별로 준비한다:
  (1) **주입 지식** = 원문(spec/plan) + 관련 백그라운드(coding-principles 해당 원칙, 선행 결정, *검증할 구체 사실*, 관련 파일 경로).
  (2) **타깃 체크리스트** = 그 렌즈가 *무엇을* 볼지 미리 명세.
  → 리뷰가 즉흥이 아니라 **준비된 명세에 대한 검증**이 됨(미스↓, 일관성↑ — 즉흥 정확성 의존 안티패턴 제거). 단일 작성자 원칙의 "메인이 dispatch에 관련 항목을 실어 전달"을 정형화한 것.
- **디스패치**: 독립 **read-only 서브에이전트**(Edit/Write 없는 에이전트 — 구조적 거짓방지) 3렌즈 **병렬**: factual/grounding, consistency/coverage, adversarial/YAGNI. adversarial 가드: "기능 추가 제안 금지(YAGNI 리뷰가 기능 늘리면 자가당착), 근거 필수."
- **메타 집계**(advisor-meta 재사용 — 여기 재기술 안 함): severity 정렬·출처 태깅·상충 감지(코드 로직, LLM 불필요) → decision.
- 단일 작성자: 리뷰어는 JSON 리턴만, 메인이 취합·반영·마커 기록(`coding-principles` "단일 작성자 + 보고" 준수 — 참조).

### 3.6 라우팅 → 반영 → 재작업 (advisor-meta enum)
- **accept**(critical 0): major/minor **부분 수정** → 마커(status=passed, decision=accept).
- **regenerate**(critical ≥1): 해당 **섹션만** 재작성 → 그 섹션만 재리뷰. **상한 1회**, 잔존 시 escalate.
- **escalate**(상충/방향성/사용자 부재): 🔴 unsolved 등록 + 마커(status=escalated). 게이트 해제(사람 결정 대기).

## 4. 변경 파일
- **신규** `hooks/spec_review_posttooluse.sh`, `hooks/spec_review_stop.sh`; `hooks/hooks.json`에 PostToolUse(matcher `Write|Edit`)·Stop(matcher 없음) 추가.
- **수정** `skills/advisor-spec-review/SKILL.md` — 1→3렌즈+메타, frontmatter 마커 규약, 훅 강제·해제 흐름.
- **수정** `coding-principles.md`·`README.md` — 강제 트리거·3렌즈로 갱신(중복 아닌 참조 지향, SSOT).
- **신규/수정** `scripts/test_hooks.sh`(또는 test_scaffold 확장) — 훅 스크립트 **불변식** 검증(매직넘버 금지, 계약 FAIL=0).
- **이슈 로그**: 🟡 결정론 훅 → solved 이동(구현·실측됨).

## 5. 검증 (불변식 — 개수 박지 않음)
훅 스크립트 단위 테스트(셸, test_scaffold 패턴):
- 경로: specs/plans면 발동, 무관 경로면 0-cost 통과.
- 마커: frontmatter 마커 있으면 침묵/통과, 없으면 발동(**CRLF 내성** — test_scaffold §6 패턴 재사용).
- 루프 가드: `stop_hook_active=true` 입력이면 Stop 통과.
- OFF 스위치: 비활성 env면 0-cost 통과.
- 출력 스키마: PostToolUse=`hookSpecificOutput.additionalContext`, Stop=top-level `decision/reason`.
- 회귀: `bash scripts/test_scaffold.sh` FAIL=0 · `claude plugin validate ./`.
- dogfood: 이 spec + 후속 plan을 실제 3렌즈 리뷰에 통과시켜 마커 부여.

## 6. 위험 / 트레이드오프 (정직히)
- **전역 훅 비용·가역성(REVERSIBLE)**: Stop 훅은 enabled 모든 프로젝트 매 턴 발동. 완화: (1) specs/plans 없으면 **0-cost 조기탈출**, (2) **OFF 스위치** — env `DISCIPLINED_CODER_REVIEW_GATE=off`면 즉시 통과(문서화). (3) 전역 vs opt-in은 **사용자 escalate**(§8 E-A).
- **강제 vs FAIL-OPEN**: 탐지 가능 범위(기본 경로+git)에선 강제. 경계 밖(커스텀 경로·비-git)에선 PostToolUse 신호로 **degrade(FAIL-OPEN)** — 작업불능보다 낫다는 명시적 선택이며 **침묵이 아니라 알려진 한계**(가장 비정형 문서에서 강제가 가장 약함을 인정).
- **거짓 리뷰**: §3.1 — 구조적 완화(read-only 리뷰어 JSON 리턴) + 마커에 decision/lenses 기록. 완벽 강제 불가(인정).
- **무한루프**: 마커(쓰는 즉시 파일에서 읽힘 — 스테이징 경합 없음) + `stop_hook_active` + 조기탈출. 8-cap 미의존.
- **블랭킷 비용**: 3렌즈를 모든 spec/plan에 강제 = 토큰↑. 사용자 "꼭 수행" 선택 → 수용. 단 spec/plan 쓸 때만 발생(활동 비례). 위험점수로 렌즈 수 조절은 §7.

## 7. 향후 (보류)
- 위험 점수로 렌즈 수 동적 조절(비용 최적화).
- 마커 위조의 더 강한 구조 방어(리뷰 산출물 해시 등).

## 8. 사용자 결정 (escalate — 자율 못 정함)
- **E-A 전역 vs opt-in 훅**: 현 설계는 **전역 + 0-cost 조기탈출 + OFF 스위치**(자율 기본값). 그러나 "모든 프로젝트 매 턴" 영향은 사용자 결정 영역 → 보고에서 확인 요청. (대안: 프로젝트 opt-in.)
- **E-B 잔여 한계 수용**: 마커 위조(거짓 리뷰)를 100% 막지 못함 — 수용 가능한가, 더 강한 방어를 §7에서 당길까.

## 9. 리뷰 반영 로그 (dogfooding)
v1을 3렌즈에 돌린 결과(전원 revise)·처리:
- 8-cap 공식 근거 없음(critical/factual) → §2 의존 제거.
- 꼭수행 vs FAIL-OPEN(critical) → §6 명시적 한계로.
- 마커 accept/escalate 구분 불가(critical) → §3.1 enum 마커.
- 전역 훅 가역성(critical/adversarial) → §6 0-cost+OFF+§8 escalate.
- MVP 측정먼저 번복(critical) → 헤더에 사용자 의도 번복 명시.
- 스키마 혼동(major) → §2 구분. git 세션 모호성(major) → §3.2 마커 1차. 거짓방지 구조 유지(major) → §3.5 read-only.
- 미반영: 사용자 지시(3렌즈·강제) 자체는 유지(리뷰어는 이 맥락 미인지).

**v2.1 (plan 리뷰 + 사용자 입력 반영)**:
- 마커 자기매칭 버그(critical/adversarial) → §3.1 **마지막 줄 HTML 주석 + terminal만** 탐지.
- 마커 terminal-only 드리프트(critical/consistency) → §3.1 명시.
- 3렌즈 **고정 + PREP 단계 추가**(사용자 Q1·Q2) → §3.5. "3=YAGNI" 리뷰 판정은 사용자 의도 미인지에 따른 것 → 기각.
- self-deadlock(adversarial) → §3.2 롤아웃 시퀀싱.
---
<!-- spec-review: passed lenses=3 date=2026-06-14 -->

