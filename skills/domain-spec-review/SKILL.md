---
name: domain-spec-review
description: Claude가 brainstorming/writing-plans로 만든 spec·plan(메타 산출물)을 독립 리뷰어들(reviewer-grounding·consistency·adversarial)로 검증하고 meta-aggregate로 accept/regenerate/escalate 라우팅하는 호출자. superpowers spec/plan 작성 시 훅이 강제. 제품 런타임 콜이 아니라 Claude 자신의 설계 문서 리뷰다.
---
# domain-spec-review — spec/plan 독립 리뷰 호출자

> **이건 제품 코드 청사진이 아니다.** 런타임 검증(`domain-llm-runtime`)은 *제품이 LLM을 호출할 때*
> 제품 코드가 구현한다. 이 스킬은 *Claude가 설계 문서(spec/plan)를 만들 때* **메인 세션이 직접
> 서브에이전트를 디스패치**해 돌리는 CC 워크플로다. superpowers의 self-review를 대체하지 않고 뒤에
> 레이어를 더한다.

## 왜
brainstorming·writing-plans의 self-review는 작성자가 자기 글을 보는 것이라 확증 편향에 약하다. 고위험
설계는 자기가 안 쓴 신선한 리뷰어가 편향을 깬다.

## 강제 (훅) — 건너뛸 수 없음
superpowers 기본 경로(`docs/superpowers/{specs,plans}/*.md`)에 spec/plan이 쓰이면:
- **PostToolUse**가 즉시 감지해 이 스킬 수행을 지시한다(비블로킹).
- **Stop**이 미리뷰 spec/plan이 남은 채 턴이 끝나는 것을 차단한다(하드 게이트).
- 완료 후 문서 **마지막 줄**에 마커를 남기면 해제: `<!-- spec-review: passed -->` (escalate면 `escalated`).
  **날짜·개수는 안 박는다** — 마커는 게이트 계약 토큰이지 상태가 아니다("문서에 상태 금지"). 기존 dated
  마커도 인식한다(prefix 매칭, 하위호환). terminal(passed/escalated)만 마커다 — pending은 마커가 아니다.
- 끄려면 env `DISCIPLINED_CODER_REVIEW_GATE=off`를 설정한다(전역 훅 — `hooks/hooks.json`).

## 절차 (공통 방법 — `agent-principles.md` "검증 레이어 절" 참조)

### 1) PREP (TDD의 "기대 먼저" — 즉흥 금지)
디스패치 전에 메인이 렌즈별로 준비한다.
- **주입 지식**: 원문(spec/plan 경로) + 관련 배경 — 해당 원칙, 선행 결정·이전 spec, **검증할 구체 사실**,
  관련 파일 경로. (`reviewer-grounding`의 "출처"가 바로 이 주입 지식이다.)
- **타깃 체크리스트**: 그 렌즈가 무엇을 볼지 미리 명세한다.

### 2) 디스패치 — 리뷰어를 각각 별도 서브에이전트로
**리뷰어당 읽기 전용 서브에이전트 하나씩** 띄운다(Edit/Write 없는 에이전트 — 구조적 거짓 방지, 그리고
한 에이전트가 모든 렌즈를 몰아 보는 것을 막아 독립성을 강제). 각자 원문 + 주입 지식을 받아 자기
JSON을 돌려준다.

**리뷰어가 메모리 계층을 받는다고 가정하지 마라.** 에이전트 종류에 따라 원칙 정본이 실리지 않는다
(실측 표는 `docs/DESIGN-NOTES.md`). 그래서 넷을 지킨다.
- **정본 경로를 프롬프트에 넣어 리뷰어가 직접 읽게 한다.** 읽기 전용 에이전트도 Read는 갖는다.
- **그 경로는 실행 시점에 도출한다.** 스킬 본문에 절대 경로를 박지 않는다 — 홈 해석이 어긋나는 환경과
  Codex에서 빗나간다. 레포 안에서 도는 워크플로는 레포 정본을, 설치본으로 도는 호출은 관리 디렉터리의
  사본을 가리킨다.
- **리턴 JSON에 `principles_applied`(읽고 적용한 원칙 ID 목록)를 요구한다.** 읽었다는 흔적을 산출물에
  남겨 관측 가능하게 만든다.
- **그 값이 비어 있으면 리뷰 보고에 적는다.** 자동 재시도는 걸지 않는다 — 읽지 않고 채우는 것을 막을 수
  없으므로 재시도는 "비어 있지 않은 배열"로만 수렴한다.
- `reviewer-grounding` — 외부 사실·비용·API·환경 주장의 근거, 근거 없는 단정·환각.
- `reviewer-consistency` — 내부 모순, spec↔plan 커버리지 공백, 이름·타입 드리프트, 스코프.
- `reviewer-adversarial` — 실패 모드·과설계·비가역(기능 추가 제안 금지 가드).

### 3) 메타 집계 — `meta-aggregate` 재사용
심각도 정렬·출처 태깅·상충 감지(코드 로직 — LLM 불필요)를 거쳐 decision을 내린다. spec/plan 리뷰에서는 메인 세션이
`meta-aggregate`의 좁은 절차를 직접 수행한다(제품 코드 없음). 단일 작성자: 리뷰어는 JSON 리턴만,
메인이 취합·반영·마커 기록.

## 라우팅 → 반영 → 재작업
- **accept**(critical 0): major·minor는 부분 수정(부분 수정이 기본 — `SURGICAL`) → 마커(passed).
- **regenerate**(critical ≥1): 지적된 섹션만 재작성 → 그 섹션만 재리뷰. 상한 1회, 잔존 시 escalate.
- **escalate**(상충·방향성·사용자 부재): 🔴 사용자에게 surface + 마커(escalated). 게이트 해제
  (사람 결정 대기). 자동 루프 금지.

## 한계 (정직히 — FAIL-LOUD)
훅은 마커 존재만 검사한다 — 리뷰 없이 마커만 달면 못 막는다. 구조적 완화(읽기 전용 리뷰어 JSON 리턴)는
있으나 완벽 강제는 불가하다. 탐지 밖(커스텀 경로·비-git)에선 FAIL-OPEN(작업 불능 방지).
