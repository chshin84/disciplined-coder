# 대응표 — `domain-spec-review` · `nested-orchestration`

원문의 각 항목이 새 문서 어디로 갔는지, 지웠다면 왜 지웠는지 남긴다.
'지움' 항목과 빈칸이 사람이 검토할 대상이다.

세 번째 칸의 값은 `옮김`, `합침`, `**지움**`, `신설` 중 하나이며 지움에는 반드시 근거를 붙인다.

**지움은 없다.** 두 파일 모두 원문의 모든 구성 요소가 새 문서에 살아 있다. 신설도 없다 — 원문에
없던 내용을 더하지 않았다. 합침은 `nested-orchestration`의 `## 재구현 금지` 불릿 셋뿐이며, 셋 다
`X: Y` 꼴의 이름표 나열이라 완결된 문장으로 고쳐 쓰면서 한 불릿 안의 두세 포인터를 한 문장으로
묶었다(포인터 자체는 하나도 빠지지 않았다).

**절 참조 다섯을 새 이름으로 바꿨다.** `domain-spec-review`의 `절차 가` 하나가 `Verification Layer`가
되었고, `nested-orchestration`의 `§마` 둘(frontmatter와 인용 블록)이 `Parallel Orchestration`,
`§가` 하나가 `Verification Layer`, `§다` 하나가 `Solved Log`가 되었다. 세 이름 모두
`agent-principles.md`에 `### ` 제목으로 실재하는지 대조해 확인했다.

**식별자는 하나도 바꾸지 않았다.** 경로(`docs/superpowers/{specs,plans}/*.md`·`hooks/hooks.json`·
`report-<workstream>.md`), 마커 문자열(`<!-- spec-review: passed -->`·`escalated`), 환경변수
(`DISCIPLINED_CODER_REVIEW_GATE=off`), 명령(`git diff --name-only base..branch`), 결정 값
(`accept`·`regenerate`·`escalate`), 상태 값(`BLOCKED`), 수치(재생성 상한 1회, 약 40k 토큰), 원칙 ID
(`TDD`·`SURGICAL`·`FAIL-LOUD`·`SSOT`)가 재작성 전후로 동일하다. `domain-spec-review`가 부르는 렌즈
셋의 이름은 `skills/reviewer-grounding`·`reviewer-consistency`·`reviewer-adversarial`의 실제
`name:` 값과, 인용하는 심각도·출처 개념은 `meta-aggregate`의 실제 출력 스키마와 대조해 맞췄다.

**테스트가 지키는 두 소제목의 새 이름은 이렇다.** `구간 소유권`은 `Ownership boundary`가 되었고
`산출 계약`은 `Output contract`가 되었다. `scripts/test_scaffold.sh`의 `check` 둘이 이 두 문자열을
찾도록 함께 고쳤다.

리뷰가 뮤테이션으로 확인한 결과 `Output contract`는 정상 작동했지만 `Ownership boundary`는 무력했다.
그 문자열이 L2 템플릿 블록(`Ownership boundary (strictly observed)`)과 가드레일 항목
(`Ownership boundary enforcement`) 두 곳에 나와서, 템플릿 블록만 지워도 가드레일 쪽이 남아 초록으로
통과했기 때문이다. 같은 약점이 한국어 원문 시절에도 있었다(`구간 소유권`이 같은 두 자리에 있었다).
가드가 L2 템플릿 블록만 물도록 `Ownership boundary (strictly observed)` 전체를 찾게 좁혔다.

## domain-spec-review

| 원문 항목 | 새 문서 위치 | 처리와 근거 |
|---|---|---|
| frontmatter `name: domain-spec-review` | frontmatter `name` | 옮김 — 스킬 식별자라 그대로 둔다 |
| description — Claude가 `brainstorming`/`writing-plans`로 만든 spec·plan | description 첫 문장 | 옮김 — 작성 스킬 둘과 산출물 둘을 모두 남겼다 |
| description — (메타 산출물) | description 첫 문장 | 옮김 — 괄호 안의 성격 규정을 `the meta artifacts`로 남겼다 |
| description — 독립 리뷰어들(`reviewer-grounding`·`consistency`·`adversarial`)로 검증한다 | description 둘째 문장 | 옮김 — '독립'이라는 한정과 렌즈 셋의 이름을 모두 남겼고, 원문이 줄여 쓴 뒤 둘을 실제 파일의 `name:` 값인 `reviewer-consistency`·`reviewer-adversarial`로 폈다 |
| description — `meta-aggregate`로 accept/regenerate/escalate 라우팅한다 | description 둘째 문장 끝 | 옮김 — 집계 스킬 이름과 세 결정 값을 그대로 남겼다 |
| description — 호출자다 | description 첫 문장 첫머리 | 옮김 — 이 스킬이 렌즈가 아니라 호출자라는 자리를 남겼다 |
| description — superpowers spec/plan 작성 시 훅이 강제한다 | description 셋째 문장 | 옮김 — 강제의 조건(superpowers 경로에 spec이나 plan을 쓸 때)과 주체(훅)를 모두 남겼다 |
| description — 제품 런타임 콜이 아니라 Claude 자신의 설계 문서 리뷰다 | description 넷째 문장 | 옮김 — 부정과 긍정 두 항을 모두 남겼다. 이 스킬에서 가장 오해받기 쉬운 구분이다 |
| H1 `domain-spec-review — spec/plan 독립 리뷰 호출자` | H1 `domain-spec-review — independent review caller for specs and plans` | 옮김 — '독립'·'리뷰'·'호출자' 셋을 모두 남겼다 |
| 인용 블록 — 이건 제품 코드 청사진이 아니다 | 인용 블록 첫 문장 | 옮김 — 굵은 강조를 유지했다 |
| 인용 블록 — 런타임 검증(`domain-llm-runtime`)은 *제품이 LLM을 호출할 때* 제품 코드가 구현한다 | 인용 블록 둘째 문장 | 옮김 — 처음엔 `for the moment the product calls an LLM`이라 적었는데 그 영어 관용구는 '당분간'으로 읽혀 영구적 경계가 잠정적 단서로 뒤집혔다. 검진에서 드러나 `it applies when ...`으로 고쳐 조건절을 되살렸다 |
| 인용 블록 — 이 스킬은 *Claude가 설계 문서(spec/plan)를 만들 때* 메인 세션이 직접 서브에이전트를 디스패치해 돌리는 CC 워크플로다 | 인용 블록 셋째 문장 | 옮김 — 위 행과 같은 수정을 거쳤다. 조건절, 주체(메인 세션이 직접), 이탤릭 강조를 모두 남겼다 |
| 인용 블록 — superpowers의 self-review를 대체하지 않고 뒤에 레이어를 더한다 | 인용 블록 넷째 문장 | 옮김 — 부정(대체하지 않는다)과 긍정(뒤에 더한다) 두 항을 모두 남겼다 |
| `## 왜` 제목 | `## Why` | 옮김 |
| 왜 — `brainstorming`·`writing-plans`의 self-review는 작성자가 자기 글을 보는 것이다 | `## Why` 첫 문장 | 옮김 — 스킬 둘과 '작성자가 자기 글을'이라는 구조를 모두 남겼다 |
| 왜 — 그래서 확증 편향에 약하다 | `## Why` 첫 문장 끝 | 옮김 — 앞 문장의 귀결이라는 인과를 `which`로 남겼다 |
| 왜 — 고위험 설계는 자기가 안 쓴 신선한 리뷰어가 편향을 깬다 | `## Why` 둘째 문장 | 옮김 — 조건(고위험 설계), 리뷰어의 두 성질(자기가 안 썼다, 신선하다), 효과(편향을 깬다)를 모두 남겼다 |
| `## 강제 (훅) — 건너뛸 수 없음` 제목 | `## Enforcement (hooks) — not skippable` | 옮김 — '건너뛸 수 없음'이라는 단서를 남겼다 |
| 조건 — superpowers 기본 경로 `docs/superpowers/{specs,plans}/*.md`에 spec/plan이 쓰이면 | `## Enforcement` 도입 문장 | 옮김 — 경로 글롭을 그대로 두었다 |
| PostToolUse — 즉시 감지해 이 스킬 수행을 지시한다(비블로킹) | `## Enforcement` 첫 항목 | 옮김 — '즉시', 지시 내용, '비블로킹' 셋을 모두 남겼다 |
| Stop — 미리뷰 spec/plan이 남은 채 턴이 끝나는 것을 차단한다(하드 게이트) | `## Enforcement` 둘째 항목 | 옮김 — 차단 조건과 '하드 게이트'라는 격을 모두 남겼다. 앞의 비블로킹과 대비되는 자리라 흐리지 않았다 |
| 마커 — 완료 후 문서 마지막 줄에 남기면 해제된다 | `## Enforcement` 셋째 항목 | 옮김 — 시점(완료 후), 위치(마지막 줄), 효과(해제)를 모두 남겼다 |
| 마커 — `<!-- spec-review: passed -->`, escalate면 `escalated` | `## Enforcement` 셋째 항목 | 옮김 — 마커 문자열과 조건부 변형을 그대로 두었다 |
| 마커 — 날짜·개수는 안 박는다 | `## Enforcement` 셋째 항목 | 옮김 — 금지 대상 둘을 모두 남기고 굵은 강조도 유지했다 |
| 마커 — 게이트 계약 토큰이지 상태가 아니다("문서에 상태 금지") | `## Enforcement` 셋째 항목 | 옮김 — 긍정과 부정 두 항, 그리고 인용된 규범 문구까지 남겼다 |
| 마커 — 기존 dated 마커도 인식한다(prefix 매칭, 하위호환) | `## Enforcement` 셋째 항목 | 옮김 — 매칭 방식과 그 이유를 모두 남겼다. `hooks/_spec_marker.sh`가 이 규약을 쌍 계약으로 참조하므로 흐리면 안 되는 자리다 |
| 마커 — terminal(passed/escalated)만 마커다, pending은 마커가 아니다 | `## Enforcement` 셋째 항목 끝 | 옮김 — '만'이라는 한정과 pending 부정을 모두 남겼다 |
| 끄기 — env `DISCIPLINED_CODER_REVIEW_GATE=off`(전역 훅 — `hooks/hooks.json`) | `## Enforcement` 넷째 항목 | 옮김 — 환경변수 이름과 값, 훅의 범위와 파일 경로를 그대로 두었다 |
| `## 절차 (공통 방법 — agent-principles.md "절차 가" 참조)` 제목 | `## The procedure (the shared method — see the Verification Layer section of agent-principles.md)` | 옮김 — '공통 방법'이라는 단서를 남기고 절 참조를 새 이름 `Verification Layer`로 바꿨다 |
| `### 1) PREP (TDD의 "기대 먼저" — 즉흥 금지)` 제목 | `### 1) PREP (the "expectation first" of TDD — nothing improvised)` | 옮김 — 원칙 ID와 '즉흥 금지'를 모두 남겼다 |
| PREP — 디스패치 전에 메인이 렌즈별로 준비한다 | `### 1) PREP` 첫 문장 | 옮김 — 시점(디스패치 전)·주체(메인)·단위(렌즈별) 셋을 남겼다. 처음엔 `one set of inputs per lens`라 원문에 없는 목적어가 붙었는데, 검진에서 드러나 걷어냈다 |
| 주입 지식 — 원문(spec/plan 경로) + 관련 배경 | `### 1) PREP` 첫 항목 | 옮김 — 두 축을 모두 남겼다 |
| 주입 지식 — 해당 원칙, 선행 결정·이전 spec, 검증할 구체 사실, 관련 파일 경로 | `### 1) PREP` 첫 항목 | 옮김 — 배경 넷을 하나도 빼지 않고 나열했고, 굵게 강조된 '검증할 구체 사실'의 강조도 유지했다 |
| 주입 지식 — `reviewer-grounding`의 "출처"가 바로 이 주입 지식이다 | `### 1) PREP` 첫 항목 끝 | 옮김 — 렌즈 스킬의 용어와 이 스킬의 용어를 잇는 다리라 남겼다. `reviewer-grounding` 본문의 "source" 정의와 실제로 대조했다 |
| 타깃 체크리스트 — 그 렌즈가 무엇을 볼지 미리 명세한다 | `### 1) PREP` 둘째 항목 | 옮김 — '미리'를 `in advance`로 남겨 `TDD`의 기대 먼저와 이어지게 했다 |
| `### 2) 디스패치 — 리뷰어를 각각 별도 서브에이전트로` 제목 | `### 2) Dispatch — each reviewer as its own separate subagent` | 옮김 — '각각 별도'를 모두 남겼다 |
| 디스패치 — 리뷰어당 읽기 전용 서브에이전트 하나씩 | `### 2) Dispatch` 첫 문장 | 옮김 — 굵은 강조와 '하나씩'이라는 대응 관계를 유지했다 |
| 디스패치 — Edit/Write 없는 에이전트 | `### 2) Dispatch` 첫 문장 | 옮김 — 두 도구 이름을 모두 남겼다 |
| 디스패치 — 구조적 거짓 방지 | `### 2) Dispatch` 첫 문장 | 옮김 — 처음엔 '하지 않은 변경을 했다고 주장하는 것'이라는 특정 거짓으로 좁혔는데, 원문은 거짓 일반이라 검진에서 드러나 `rules out a false claim`으로 넓혔다 |
| 디스패치 — 한 에이전트가 모든 렌즈를 몰아 보는 것을 막아 독립성을 강제한다 | `### 2) Dispatch` 첫 문장 끝 | 옮김 — 막는 것과 그 결과 둘을 남겼다. 처음엔 `rather than hoped for`라는 원문에 없는 대비를 덧붙였는데, 검진에서 드러나 뺐다 |
| 디스패치 — 각자 원문 + 주입 지식을 받아 자기 JSON을 돌려준다 | `### 2) Dispatch` 둘째 문장 | 옮김 — 입력 둘과 '자기' JSON이라는 독립성 단서를 모두 남겼다 |
| 렌즈 — `reviewer-grounding`은 외부 사실·비용·API·환경 주장의 근거를 본다 | `### 2) Dispatch` 첫 항목 | 옮김 — 주장 넷을 하나도 빼지 않았다 |
| 렌즈 — `reviewer-grounding`은 근거 없는 단정·환각을 본다 | `### 2) Dispatch` 첫 항목 끝 | 옮김 — 두 항목을 모두 남겼다 |
| 렌즈 — `reviewer-consistency`는 내부 모순, spec↔plan 커버리지 공백, 이름·타입 드리프트, 스코프를 본다 | `### 2) Dispatch` 둘째 항목 | 옮김 — 넷을 그대로 나열했고, 렌즈 본문의 체크리스트와 대조해 일치를 확인했다 |
| 렌즈 — `reviewer-adversarial`은 실패 모드·과설계·비가역을 본다 | `### 2) Dispatch` 셋째 항목 | 옮김 — 셋을 그대로 나열했다 |
| 렌즈 — `reviewer-adversarial`에는 기능 추가 제안 금지 가드가 있다 | `### 2) Dispatch` 셋째 항목 끝 | 옮김 — 렌즈 본문이 굵게 강조하는 가드라 괄호로 남겼다 |
| `### 3) 메타 집계 — meta-aggregate 재사용` 제목 | `### 3) Meta aggregation — reuse meta-aggregate` | 옮김 — '재사용'을 남겨 여기서 새로 정의하지 않음을 유지했다 |
| 집계 — 심각도 정렬·출처 태깅·상충 감지를 거친다 | `### 3) Meta aggregation` 첫 문장 | 옮김 — 셋을 그대로 나열했고 `meta-aggregate` 본문의 `## What it does`와 대조했다 |
| 집계 — 코드 로직이라 LLM이 불필요하다 | `### 3) Meta aggregation` 첫 문장 | 옮김 — 근거와 결론을 모두 남겼다 |
| 집계 — decision을 내린다 | `### 3) Meta aggregation` 첫 문장 끝 | 옮김 |
| 집계 — spec/plan 리뷰에서는 메인 세션이 `meta-aggregate`의 좁은 절차를 직접 수행한다(제품 코드 없음) | `### 3) Meta aggregation` 둘째 문장 | 옮김 — 조건·주체·'좁은 절차'라는 한정·근거(제품 코드 없음)를 모두 남겼다 |
| 집계 — 단일 작성자: 리뷰어는 JSON 리턴만, 메인이 취합·반영·마커 기록 | `### 3) Meta aggregation` 셋째 문장 | 옮김 — '단일 작성자'라는 개념어와 '리턴만'의 한정, 메인이 하는 일 셋을 모두 남겼다 |
| `## 라우팅 → 반영 → 재작업` 제목 | `## Routing, then applying, then rework` | 옮김 — 세 단계를 순서대로 남겼고, 화살표는 `CLEAR-COMM`에 따라 문장으로 풀었다 |
| accept — critical 0일 때다 | `## Routing` 첫 항목 | 옮김 — 조건을 그대로 남겼다 |
| accept — major·minor는 부분 수정한다(부분 수정이 기본 — `SURGICAL`) | `## Routing` 첫 항목 | 옮김 — 대상 둘과 '기본'이라는 단서, 원칙 ID를 모두 남겼다 |
| accept — 마커(passed)를 남긴다 | `## Routing` 첫 항목 끝 | 옮김 |
| regenerate — critical ≥1일 때다 | `## Routing` 둘째 항목 | 옮김 — 경계를 그대로 남겼다 |
| regenerate — 지적된 섹션만 재작성하고 그 섹션만 재리뷰한다 | `## Routing` 둘째 항목 | 옮김 — 두 번 나오는 '만'을 둘 다 `only`로 남겼다 |
| regenerate — 상한 1회, 잔존 시 escalate | `## Routing` 둘째 항목 끝 | 옮김 — 수치와 잔존 조건을 모두 남겼다 |
| escalate — 상충·방향성·사용자 부재일 때다 | `## Routing` 셋째 항목 | 옮김 — 트리거 셋을 모두 남겼다 |
| escalate — 🔴를 사용자에게 surface하고 마커(escalated)를 남긴다 | `## Routing` 셋째 항목 | 옮김 — 🔴 기호를 그대로 두었다. 정본의 "🔴는 즉시 surface"와 이어지는 자리다 |
| escalate — 게이트가 해제된다(사람 결정 대기) | `## Routing` 셋째 항목 | 옮김 — 해제 사실과 그 이유를 모두 남겼다 |
| escalate — 자동 루프 금지 | `## Routing` 셋째 항목 끝 | 옮김 — `Never`로 예외 없음을 남겼다 |
| `## 한계 (정직히 — FAIL-LOUD)` 제목 | `## Limits (stated honestly — FAIL-LOUD)` | 옮김 — '정직히'와 원칙 ID를 모두 남겼다 |
| 한계 — 훅은 마커 존재만 검사한다 | `## Limits` 첫 문장 | 옮김 — '만'을 `only`로 남겼다 |
| 한계 — 리뷰 없이 마커만 달면 못 막는다 | `## Limits` 첫 문장 끝 | 옮김 — 이 스킬의 신뢰성을 지탱하는 자백이라 완곡하게 만들지 않았다. `attach the marker without running a review and nothing stops you`로 원문의 무방비함을 그대로 옮겼다 |
| 한계 — 구조적 완화(읽기 전용 리뷰어 JSON 리턴)는 있다 | `## Limits` 둘째 문장 | 옮김 — 완화가 무엇인지까지 괄호로 남겼다 |
| 한계 — 그러나 완벽 강제는 불가하다 | `## Limits` 둘째 문장 끝 | 옮김 — '있으나 불가하다'는 두 층위를 `but`으로 모두 남겼다 |
| 한계 — 탐지 밖(커스텀 경로·비-git)에선 FAIL-OPEN이다(작업 불능 방지) | `## Limits` 셋째 문장 | 옮김 — 예외 둘과 그 이유를 남겼다. 처음엔 `fails open`으로 소문자화해 제목의 `FAIL-LOUD`와 짝을 이루던 `FAIL-OPEN` 토큰이 사라졌는데, 검진에서 드러나 되살렸다 |

## nested-orchestration

| 원문 항목 | 새 문서 위치 | 처리와 근거 |
|---|---|---|
| frontmatter `name: nested-orchestration` | frontmatter `name` | 옮김 — 스킬 식별자라 그대로 둔다 |
| description — 멀티태스크 플랜이 둘 이상일 때 | description 첫 문장 | 옮김 — 이 스킬이 켜지는 조건이라 '멀티태스크 플랜'과 '둘 이상'을 모두 남겼다 |
| description — 3층(오케스트레이터→서브오케스트레이터→워커·리뷰어)으로 병렬 실행하는 방법 | description 첫 문장 | 옮김 — 세 층의 이름을 순서대로 남겼고, 화살표는 `CLEAR-COMM`에 따라 문장으로 풀었다 |
| description — 스펙별 독립 워크트리 | description 둘째 문장 | 옮김 — '스펙별'과 '독립' 둘 다 남겼다 |
| description — 자율 L2 | description 둘째 문장 | 옮김 — 층 이름과 '자율'을 그대로 남겼다. '사람과 대화할 수 없다'는 자율의 정의는 본문 `## The flow` 2번이 소유하므로 `description`에 옮겨 적지 않았다(`SSOT`) |
| description — 기계적 소유권 강제 | description 둘째 문장 | 옮김 — '기계적'이라는 한정을 남겼다. 선언만이 아니라 탐지까지라는 뜻이다 |
| description — 무상태 재개 | description 둘째 문장 끝 | 옮김 |
| description — `agent-principles` §마가 트리거다 | description 셋째 문장 | 옮김 — 절 참조를 새 이름 `Parallel Orchestration`으로 바꿨다 |
| H1 `nested-orchestration — 3층 병렬 오케스트레이션 (방법 SSOT)` | H1 `nested-orchestration — three-tier parallel orchestration (the SSOT for the method)` | 옮김 — '방법 SSOT'라는 자리 규정을 남겼다 |
| 인용 블록 — `agent-principles.md` §마가 트리거 인덱스다 | 인용 블록 첫 문장 | 옮김 — 절 참조를 `Parallel Orchestration`으로 바꿨고 '트리거 인덱스'라는 역할 구분을 남겼다 |
| 인용 블록 — 여기가 *어떻게*의 SSOT다 | 인용 블록 둘째 문장 | 옮김 — 이탤릭 강조를 유지했다. 정본은 언제·무엇, 여기는 어떻게라는 분업이다 |
| 인용 블록 — 이 스킬은 기존 스킬을 재구현하지 않고 조합한다 | 인용 블록 셋째 문장 | 옮김 — 부정과 긍정 두 항을 모두 남겼다 |
| 인용 블록 — 각 메커니즘의 상세는 그 스킬을 연다 | 인용 블록 셋째 문장 끝 | 옮김 — 지시문으로 남겨 '가서 보라'가 사라지지 않게 했다 |
| `## 언제 쓰나 — 라우팅 결정 트리` 제목 | `## When to use it — the routing decision tree` | 옮김 — '결정 트리'라는 형태 단서를 남겼다 |
| 라우팅 — 독립적인 작업 단위가 2개 이상일 때 | `## When to use it` 도입 문장 | 옮김 — '독립적'과 '2개 이상'이라는 두 조건을 모두 남겼다 |
| 라우팅 — 각 단위가 단일 태스크(자기 계획·리뷰 루프가 없음)면 `dispatching-parallel-agents`(2층)로 간다 | `## When to use it` 첫 항목 | 옮김 — 단일 태스크의 정의(자기 계획·리뷰 루프가 없다)와 목적지 스킬 이름, 그리고 2층이라는 층수를 모두 남겼다. 이 분기를 잘못 읽으면 순수 오버헤드를 부르므로 조건을 흐리지 않았다 |
| 라우팅 — 여기서 끝이다 | `## When to use it` 첫 항목 끝 | 옮김 — `That is the end of it`으로 남겼다. 2층으로 갔으면 이 스킬을 더 읽지 말라는 종결 지시다 |
| 라우팅 — 각 단위가 멀티태스크 플랜(자기 계획·구현·리뷰 루프를 가진 덩어리)이면 이 스킬(3층)을 쓴다 | `## When to use it` 둘째 항목 | 옮김 — 멀티태스크 플랜의 정의를 이루는 루프 셋(계획·구현·리뷰)을 모두 남겼다. 단일 태스크 정의의 루프 둘과 다른 개수라 합치지 않았다 |
| 근거 — 3층이 값을 하는 이유는 이렇다(머리말) | `## When to use it` 근거 문단 머리말 | 옮김 — `Why the third tier earns its place`로 남겼다. 뒤의 대비를 여는 문장이라 지우면 근거 셋이 떠다닌다 |
| 근거 — 2층 워커는 한 태스크만 푼다 | `## When to use it` 근거 문단 | 옮김 — '만'을 `exactly one`으로 남겼다 |
| 근거 — 순차 SDD는 N개 루프를 한 컨텍스트에 쌓는다 | `## When to use it` 근거 문단 | 옮김 — 대비되는 두 대안 중 둘째다 |
| 근거 — 3층만이 N개 SDD 루프를 각자 격리 컨텍스트에서 동시에 돌린다 | `## When to use it` 근거 문단 | 옮김 — '만'·'각자 격리'·'동시에' 셋을 모두 남기고 굵은 강조도 유지했다 |
| 근거 — 그 격리와 동시성이 조율 층 하나를 얹는 값이다 | `## When to use it` 근거 문단 | 옮김 — 값을 이루는 두 항(격리, 동시성)과 그 대가(조율 층 하나)를 모두 남겼다 |
| 근거 — 단일 태스크에는 그 값이 없으니 붙이지 않는다 | `## When to use it` 근거 문단 끝 | 옮김 — 조건과 금지를 모두 남겼다. 라우팅의 반대편을 못 박는 문장이라 뺄 수 없다 |
| `## 흐름 — 파이프라인 3단계 (batch 아님)` 제목 | `## The flow — a three-stage pipeline (not a batch)` | 옮김 — 'batch 아님'이라는 부정을 남겼다. 한꺼번에 모아 돌리는 방식과의 대비가 이 절의 요지다 |
| 흐름 — 사람 병목은 주로 스펙 국면에 산다 | `## The flow` 도입 첫 문장 | 옮김 — '주로'라는 한정을 `mostly`로 남겼다 |
| 흐름 — 그러니 스펙을 하나씩 잠그고, 잠기는 즉시 팬아웃한다 | `## The flow` 도입 둘째 문장 | 옮김 — '하나씩'과 '즉시' 둘 다 남겼다 |
| L1 — 메인이며 사람과 함께 일한다 | `## The flow` 1번 | 옮김 — 층 이름과 사람과의 관계를 모두 남겼다 |
| L1 — 스펙을 하나씩 `brainstorming`으로 잠근다 | `## The flow` 1번 | 옮김 — 사용하는 스킬 이름을 그대로 두었다 |
| L1 — 잠기는 즉시 워크트리를 만든다(`using-git-worktrees`, 또는 `Agent`의 `isolation:'worktree'`) | `## The flow` 1번 | 옮김 — 두 수단을 모두 남겼다. 원문이 'A 또는 B'라 한쪽으로 합치지 않았다 |
| L1 — L2를 백그라운드로 디스패치한다 | `## The flow` 1번 | 옮김 — 굵은 강조를 유지했다 |
| L1 — 그 사이 L1은 다음 스펙을 계속 브레인스토밍한다 | `## The flow` 1번 끝 | 옮김 — 파이프라인이 batch와 갈리는 지점이라 남겼다 |
| L2 — 자율 서브오케스트레이터이며 사람 대화가 불가능하다 | `## The flow` 2번 | 옮김 — 두 성질을 모두 남겼다 |
| L2 — 잠긴 스펙으로 `writing-plans`(계획부터)를 실행한다 | `## The flow` 2번 | 옮김 — '계획부터'라는 시작점 단서를 `starting from the plan`으로 남겼다. 스펙은 이미 L1이 잠갔다는 뜻이다 |
| L2 — 이어서 `subagent-driven-development`(구현)를 자기 워크트리에서 실행한다 | `## The flow` 2번 | 옮김 — 스킬 이름·역할·장소를 모두 남겼다 |
| L2 — L2의 SDD 루프가 L3(구현자·리뷰어)를 띄운다 | `## The flow` 2번 | 옮김 — L3의 두 역할을 모두 남겼다 |
| L2 — 검증은 세 지점에 배선한다 | `## The flow` 2번 | 옮김 — 굵은 강조와 '세 지점'이라는 개수를 남겼고, 뒤에 실제로 셋을 열거했다 |
| L2 — 스펙 국면은 L1이 이미 `domain-spec-review`(훅 강제)로 마쳤다 | `## The flow` 2번 | 옮김 — 주체·시제(이미 마쳤다)·강제 방식을 모두 남겼다 |
| L2 — 플랜 국면은 L2가 자율로 `domain-spec-review`를 돌려 accept/regenerate까지 처리한다 | `## The flow` 2번 | 옮김 — '자율로'와 '까지'라는 범위 한정을 모두 남기고 굵은 강조도 유지했다 |
| L2 — 사람 대화 불가라 escalate 상황이면 아래 BLOCKED로 버블업한다 | `## The flow` 2번 | 옮김 — 근거(대화 불가)와 처리(BLOCKED로 버블업)를 모두 남겼다. accept/regenerate까지만 자율이라는 한계의 반대편이다 |
| L2 — 실행 국면은 SDD 태스크 리뷰어와 리스크 비례 `reviewer-*` 렌즈가 맡는다 | `## The flow` 2번 끝 | 옮김 — 담당 둘과 '리스크 비례'라는 조건을 모두 남겼다 |
| L1 통합 — L2들의 완료 통지를 받아 리포트를 취합한다 | `## The flow` 3번 | 옮김 — 트리거(완료 통지)와 작업(취합) 둘을 남겼다 |
| L1 통합 — 소유권을 기계로 검증한 뒤 병합하고 최종 브랜치 리뷰를 돌린다 | `## The flow` 3번 | 옮김 — 순서가 있는 세 작업을 모두 남겼다 |
| L1 통합 — 이 통합은 가벼운 일이 아니며 L1에서 벌어진다 | `## The flow` 3번 | 옮김 — 정직한 자백이라 남겼다 |
| L1 통합 — 병목은 제거가 아니라 축소된다 | `## The flow` 3번 | 옮김 — 부정과 긍정 두 항을 모두 남겼다. 이 스킬이 과장되지 않게 붙잡는 문장이다 |
| L1 통합 — 통합을 브레인스토밍이 다 끝난 뒤로 미뤄도 된다 | `## The flow` 3번 | 옮김 — 선택지 둘 중 첫째다 |
| L1 통합 — 규모가 크면 통합 자체를 별도 서브에이전트에 위임해도 된다 | `## The flow` 3번 끝 | 옮김 — 선택지 둘 중 둘째이며 조건(규모가 크면)도 남겼다 |
| `## L2 디스패치 템플릿 — 여섯 블록` 제목 | `## The L2 dispatch template — six blocks` | 옮김 — 개수를 남겼고 아래 목록도 여섯 개 그대로다 |
| 템플릿 — L2는 자기 부모(L1) 외 누구와도 대화할 수 없다 | `## The L2 dispatch template` 도입 | 옮김 — 예외(부모 L1)까지 남겼다 |
| 템플릿 — 프롬프트는 자기완결이어야 한다 | `## The L2 dispatch template` 도입 | 옮김 — 앞 문장의 귀결이라는 인과를 `therefore`로 남겼다 |
| 템플릿 — 용어 고정: L2=서브오케스트레이터, L3=구현자·리뷰어('워커'는 2층 용어) | `## The L2 dispatch template` 도입 끝 | 옮김 — 두 정의와 '워커'가 2층 용어라는 단서를 모두 남겼다. 등호는 `CLEAR-COMM`에 따라 문장으로 풀었다 |
| 블록 1 역할 선언 — 너는 자율 서브오케스트레이터다 | 블록 1 | 옮김 — 그대로 쓸 수 있는 프롬프트 문장이라 큰따옴표를 유지했다 |
| 블록 1 — 나(오케스트레이터)와 추가 왕복 없이 스펙을 완결하고 브랜치까지 만든다 | 블록 1 | 옮김 — '추가 왕복 없이'와 결과 둘(스펙 완결, 브랜치)을 모두 남겼다 |
| 블록 1 — 너는 격리된 git 워크트리에 있다 | 블록 1 끝 | 옮김 |
| 블록 2 임무 — 스펙 경로(SSOT임을 명시) | 블록 2 | 옮김 — 'SSOT임을 명시'라는 지시까지 남겼다 |
| 블록 2 — 산출물 열거 | 블록 2 끝 | 옮김 |
| 블록 3 `구간 소유권(엄수)` | 블록 3 `**Ownership boundary (strictly observed)**` | 옮김 — '엄수'를 `strictly observed`로 남겼다. **이 문자열을 `scripts/test_scaffold.sh`의 `has L2 template ownership blk` 검사가 계약으로 지킨다** |
| 블록 3 — 소유하는 파일·디렉터리 경로 | 블록 3 | 옮김 — 두 단위를 모두 남겼다 |
| 블록 3 — 타 워크스트림 소유 파일의 명시적 금지 | 블록 3 끝 | 옮김 — 굵은 강조를 유지했다. 선언 쪽 절반이며 탐지 쪽 절반은 가드레일 절에 있다 |
| 블록 4 `방식(TDD + 3층)` | 블록 4 `**The method (TDD plus three tiers)**` | 옮김 — 원칙 ID와 층수를 모두 남겼다 |
| 블록 4 — 구현자로 구현한다(같은 파일은 순차 편집·병렬 mutate 금지) | 블록 4 | 옮김 — 긍정 지시(순차 편집)와 금지(병렬 mutate)를 모두 남겼다 |
| 블록 4 — 프로젝트 테스트 규약을 따른다 | 블록 4 | 옮김 |
| 블록 4 — 읽기전용 리뷰어 서브에이전트가 diff를 읽고 findings를 반환한다 | 블록 4 | 옮김 — '읽기전용'의 굵은 강조와 입력(diff)·출력(findings)을 모두 남겼다 |
| 블록 4 — L2가 수정한다(리뷰어는 파일 불변) | 블록 4 | 옮김 — 수정 주체와 리뷰어 불변을 모두 남겼다 |
| 블록 4 — 리스크에 비례해 리뷰어를 고른다(§가) | 블록 4 | 옮김 — 절 참조를 새 이름 `Verification Layer`로 바꿨다 |
| 블록 4 — SDD 태스크 리뷰어, 필요하면 `reviewer-grounding`·`reviewer-adversarial` 렌즈 | 블록 4 끝 | 옮김 — 기본 하나와 조건부 둘을 구분해 남겼다. '필요하면'이라는 조건을 지우지 않았다 |
| 블록 5 주입 컨텍스트 — solved_problems에서 recall한 해당 도메인 gotcha들 | 블록 5 | 옮김 — 처음엔 `the solved logs`라 적어 파일 이름이 사라졌는데, 검진에서 드러나 `solved_problems`를 되살렸다 |
| 블록 5 — 반복 재발견 금지 | 블록 5 끝 | 옮김 — recall의 목적이라 남겼다 |
| 블록 6 `산출 계약(브랜치까지만 — 머지·배포·main push 금지)` | 블록 6 `**Output contract (up to the branch and no further — never merge, deploy, or push to main)**` | 옮김 — '까지만'과 금지 셋을 모두 남겼다. **이 문자열을 `scripts/test_scaffold.sh`의 `has output contract blk` 검사가 계약으로 지킨다** |
| 블록 6 — 상세는 리포트 파일에 쓴다 | 블록 6 | 옮김 — 굵은 강조를 유지했다 |
| 블록 6 — 리포트 내용은 변경 파일·테스트 최종 결과·발행 스키마 실제 모양·스펙 이탈·브랜치명이다 | 블록 6 | 옮김 — 다섯 항목을 하나도 빼지 않았다 |
| 블록 6 — L1으로 리턴하는 것은 상태·블로커·한 줄 요약과 리포트 경로뿐이다 | 블록 6 | 옮김 — '뿐'을 `nothing but`으로 남기고 네 항목을 그대로 나열했다. 컨텍스트 bloat를 막는 계약이다 |
| 블록 6 — 리포트는 제품 트리 밖의 워크스트림별 고유 경로에 쓴다(예: `report-<workstream>.md`) | 블록 6 | 옮김 — 조건 둘(제품 트리 밖, 워크스트림별 고유)과 예시 경로를 모두 남겼다 |
| 블록 6 — 병합될 브랜치에는 커밋하지 않는다 | 블록 6 | 옮김 — 굵은 강조를 유지했다 |
| 블록 6 — 고정 경로로 커밋하면 워크스트림끼리 병합 충돌이 난다(실측) | 블록 6 | 옮김 — 금지의 근거와 '실측'이라는 출처 표시를 모두 남겼다 |
| 블록 6 — 서브에이전트 `Write`가 `.md`를 훅으로 막을 수 있다 | 블록 6 | 옮김 — 조건부(막을 수 있다)를 단정으로 바꾸지 않았다 |
| 블록 6 — 그래서 리포트는 Bash로 스크래치에 기록한다(실측 gotcha) | 블록 6 끝 | 옮김 — 우회 수단과 출처 표시를 모두 남겼다 |
| `## 사람 대화 불가 — BLOCKED와 재개` 제목 | `## No human channel — BLOCKED and resumption` | 옮김 — 상태 이름 `BLOCKED`를 그대로 두었다 |
| BLOCKED — L2가 사람 결정(🔴)에 부딪히면 mid-run으로 surface하려 하지 않는다 | `## No human channel` 첫 항목 | 옮김 — 🔴의 뜻(사람 결정)과 금지를 모두 남겼다 |
| BLOCKED — 백그라운드라 즉시 채널이 없다 | `## No human channel` 첫 항목 | 옮김 — 금지의 근거라 남겼다 |
| BLOCKED — 그 지점에서 조기 종료하고 상태 `BLOCKED`와 질문을 리턴한다 | `## No human channel` 첫 항목 | 옮김 — 굵은 강조와 리턴 둘(상태, 질문)을 모두 남겼다 |
| BLOCKED — 지금까지 커밋은 브랜치에 남긴 채다 | `## No human channel` 첫 항목 | 옮김 — 무상태 재개가 성립하는 근거라 남겼다 |
| BLOCKED — 절대 추측으로 지나가지 않는다(§다의 "🔴 즉시 surface") | `## No human channel` 첫 항목 끝 | 옮김 — '절대'를 `never`로 남기고 절 참조를 `Solved Log`로 바꿨다 |
| 재개 — L1이 그 질문을 사용자에게 surface한다 | `## No human channel` 둘째 항목 | 옮김 |
| 재개 — 사용자가 답해도 L1은 정지된 L2를 되살리지 않는다 | `## No human channel` 둘째 항목 | 옮김 — 부정을 먼저 남겨 잘못된 기대를 끊었다 |
| 재개 — 답을 스펙에 접어 넣어(🔴 해소) 그 워크트리에 새 L2를 재디스패치한다 | `## No human channel` 둘째 항목 | 옮김 — 굵은 강조, 🔴 해소라는 괄호, '그 워크트리'라는 위치를 모두 남겼다 |
| 재개 — 새 L2는 기존 커밋 위에서 이어간다(무상태 재개) | `## No human channel` 둘째 항목 끝 | 옮김 — 개념어 '무상태 재개'가 이 동작에서 나온다는 연결을 남겼다 |
| 잔존 위험 — BLOCKED 버블업은 자율 LLM에 대한 프롬프트 넛지이지 하드 컨트롤이 아니다 | `## No human channel` 셋째 항목 | 옮김 — 긍정과 부정 두 항을 모두 남겼고 '정직히'라는 표지도 유지했다 |
| 잔존 위험 — L2가 🔴를 못 알아채고 추측하면 완결된 브랜치까지 가서야 L1이 본다 | `## No human channel` 셋째 항목 | 옮김 — 실패 경로를 완곡하게 만들지 않았다 |
| 잔존 위험 — 최종 방벽은 L1의 통합검증·최종 브랜치 리뷰다 | `## No human channel` 셋째 항목 끝 | 옮김 — 방벽 둘을 모두 남겼다 |
| `## 가드레일 (FAIL-LOUD)` 제목 | `## Guardrails (FAIL-LOUD)` | 옮김 — 원칙 ID를 그대로 두었다 |
| 소유권 강제 — 선언 + 기계적 탐지 | `## Guardrails` 첫 항목 제목 | 옮김 — 두 축을 모두 남겼다. 선언 쪽은 블록 3, 탐지 쪽은 여기다 |
| 소유권 강제 — L1은 취합 때 각 브랜치의 변경 파일 집합을 구한다(`git diff --name-only base..branch`) | `## Guardrails` 첫 항목 | 옮김 — 시점과 명령을 그대로 두었다 |
| 소유권 강제 — 두 집합의 교집합이 비면 안전, 비지 않으면 병합 전에 멈추고 surface한다 | `## Guardrails` 첫 항목 | 옮김 — 두 갈래를 모두 남기고 굵은 강조도 유지했다 |
| 소유권 강제 — 리포트 핸드오프는 브랜치 밖이라 이 집합은 제품 파일만 담는다 | `## Guardrails` 첫 항목 | 옮김 — 근거와 결론, 그리고 '만'을 모두 남겼다 |
| 소유권 강제 — 겹침이 "조용한 병합 충돌"이 아니라 병합 *이전*의 명시적 FAIL로 드러난다 | `## Guardrails` 첫 항목 끝 | 옮김 — 부정과 긍정 두 항, 그리고 '이전'의 이탤릭 강조를 모두 남겼다 |
| 크래시·행 복구 — L1은 디스패치한 워크스트림을 인플라이트로 들고 있다 | `## Guardrails` 둘째 항목 | 옮김 |
| 크래시·행 복구 — 완료 통지가 안 오는 L2는 CLI 드릴인(더블클릭)으로 생사를 확인한다 | `## Guardrails` 둘째 항목 | 옮김 — 조건과 수단을 모두 남겼다 |
| 크래시·행 복구 — 죽었으면 마지막 커밋 위에서 재디스패치한다 | `## Guardrails` 둘째 항목 | 옮김 — 조건부라는 것을 유지했다 |
| 크래시·행 복구 — 한계: 타임아웃·헬스체크 툴링이 없어 L1의 주의에 의존한다 | `## Guardrails` 둘째 항목 끝 | 옮김 — 없는 것 둘과 그 결과를 모두 남겼다 |
| 비용 — 항목 제목에 붙은 (정직히) 표지 | `## Guardrails` 셋째 항목 제목 | 옮김 — `(stated honestly)`로 남겼다. 이 스킬이 자기 비용을 자백하는 자리라는 표지라 뺄 수 없다 |
| 비용 — task 알맹이는 순차·병렬이 대체로 같다 | `## Guardrails` 셋째 항목 | 옮김 — '대체로'라는 한정을 `about the same`으로 남겼다 |
| 비용 — 그러나 병렬은 공짜가 아니다 | `## Guardrails` 셋째 항목 | 옮김 — 반전 접속을 유지했다 |
| 비용 — L2마다 컨텍스트 재확립(스펙 재독·gotcha 재recall·코드베이스 재독)이 든다 | `## Guardrails` 셋째 항목 | 옮김 — 재확립 항목 셋을 하나도 빼지 않았다 |
| 비용 — 에이전트 팬아웃까지 더해 N배 오버헤드다 | `## Guardrails` 셋째 항목 | 옮김 — 둘째 원인과 배수 표현을 모두 남겼다 |
| 비용 — 사는 것은 벽시계 단축과 컨텍스트 격리다 | `## Guardrails` 셋째 항목 | 옮김 — 얻는 것 둘을 모두 남겼다 |
| 비용 — 실측 참고: 사소한 워크스트림 하나당 약 40k 토큰(L3 포함) | `## Guardrails` 셋째 항목 끝 | 옮김 — 수치·단위·'사소한'이라는 조건·'L3 포함'이라는 범위를 모두 남겼다 |
| `## 관측성 — 무엇을 보고 무엇을 못 보나` 제목 | `## Observability — what you see and what you do not` | 옮김 — 두 물음을 모두 남겼다 |
| 관측성 — 수동 `Agent` 중첩은 `/workflows` 집계 대시보드에 뜨지 않는다 | `## Observability` 첫 문장 | 옮김 — '수동'이라는 한정과 대시보드 경로를 남겼다 |
| 관측성 — 그건 `Workflow` 툴 전용이다 | `## Observability` 첫 문장 끝 | 옮김 — 안 뜨는 이유라 남겼다 |
| 관측성 — 대신 CLI가 서브에이전트를 표시하고 더블클릭으로 각 L2의 라이브 세션에 드릴인된다 | `## Observability` 둘째 문장 | 옮김 — 보이는 것과 조작 방법을 모두 남겼다 |
| 관측성 — "각 L2가 지금 뭐 하나"는 이걸로 본다 | `## Observability` 둘째 문장 끝 | 옮김 — 인용된 물음을 그대로 두었다 |
| 관측성 — 못 보는 것은 집계뷰·메트릭, 워크트리 배정 표면 표시다 | `## Observability` 셋째 문장 | 옮김 — 못 보는 것 셋을 모두 남겼다. 처음엔 `What you do not get:`이라는 콜론 조각이었는데, 검진에서 드러나 완결된 문장으로 고쳤다(`CLEAR-COMM`) |
| 관측성 — 메인 컨텍스트 bloat는 위 리포트-파일 분리로 완화한다 | `## Observability` 넷째 문장 | 옮김 — 완화 수단이 앞 절에 있다는 참조까지 남겼다 |
| `## 재구현 금지 (SSOT 포인터)` 제목 | `## Do not reimplement (SSOT pointers)` | 옮김 |
| 포인터 — 아이디어에서 스펙까지는 `brainstorming`, 계획은 `writing-plans`, 실행 루프는 `subagent-driven-development` | `## Do not reimplement` 첫 항목 | 합침 — 포인터 셋을 한 문장으로 묶었다. 원문이 `X: Y` 꼴의 이름표 나열이라 `CLEAR-COMM`에 따라 완결된 문장으로 고치면서 한 불릿 안에서 합쳐졌고, 포인터 셋은 그대로 다 있다 |
| 포인터 — 병렬 디스패치 메커니즘은 `dispatching-parallel-agents`(단일태스크 경로이자 디스패치 기초) | `## Do not reimplement` 둘째 항목 | 합침 — 위 행과 같은 이유이며, 괄호 안의 두 역할(단일태스크 경로, 디스패치 기초)을 모두 남겼다 |
| 포인터 — 워크트리 격리는 `using-git-worktrees`, 리뷰 렌즈는 `reviewer-*` | `## Do not reimplement` 셋째 항목 | 합침 — 위 행과 같은 이유이며, 포인터 둘을 모두 남겼다 |
| `## 한계 (정직히)` 제목 | `## Limits (stated honestly)` | 옮김 — '정직히'를 남겼다 |
| 한계 — 3층은 조율 층을 얹으므로 멀티태스크 플랜에만 값을 한다(라우팅) | `## Limits` 첫 문장 | 옮김 — 근거·'만'이라는 한정·라우팅 참조를 모두 남겼다. 이 스킬의 핵심 분기를 닫는 문장이라 흐리지 않았다 |
| 한계 — BLOCKED 정직성·소유권 강제는 스파이크에서 검증됐다 | `## Limits` 둘째 문장 | 옮김 — 검증된 둘과 검증 수단(스파이크)을 남겼다 |
| 한계 — 크래시 복구와 대형 워크스트림은 아직 미검증이다 | `## Limits` 둘째 문장 끝 | 옮김 — 미검증 둘과 '아직'을 모두 남겼다. 검증된 것과 아닌 것의 대비가 이 문장의 값이다 |
| 한계 — 자율(L2 판단)을 관측·재현성(`Workflow` 결정론)보다 택한 결과다 | `## Limits` 셋째 문장 | 옮김 — 택한 것과 버린 것, 각각의 괄호 설명을 모두 남겼다 |
| 한계 — 그 대가(집계 UI 부재·추측 잔존 위험)를 감수한다 | `## Limits` 셋째 문장 끝 | 옮김 — 대가 둘을 모두 남겼다 |
| 비목표 — `Workflow` 결정론 버전을 만들지 않는다 | 마지막 문단 | 옮김 — 비목표 셋 중 첫째다 |
| 비목표 — 집계 UI 대시보드를 만들지 않는다 | 마지막 문단 | 옮김 — 비목표 셋 중 둘째다 |
| 비목표 — 영속되는 오케스트레이션 상태 문서를 만들지 않는다 | 마지막 문단 | 옮김 — 비목표 셋 중 셋째이며 굵은 강조도 유지했다 |
| 비목표 — 인플라이트 상태는 세션 대화 상태로만 든다(disciplined-coder 무상태 정체성) | 마지막 문단 | 옮김 — '만'과 정체성 근거를 모두 남겼다 |
| 비목표 — L4 이상 더 깊은 중첩도 다루지 않는다(3층 한정) | 마지막 문단 | 옮김 — 경계와 괄호 단서를 남겼다. 처음엔 `deeper than L4`라 적어 L4 자체가 범위 안으로 들어가 경계가 한 층 어긋났는데, 자기 검토에서 드러나 `at L4 or deeper`로 고쳤다 |
| 비목표 — 단일 태스크 병렬은 `dispatching-parallel-agents`가 SSOT다 | 마지막 문단 끝 | 옮김 — 라우팅의 반대편을 다시 못 박는 자리라 남겼다 |
