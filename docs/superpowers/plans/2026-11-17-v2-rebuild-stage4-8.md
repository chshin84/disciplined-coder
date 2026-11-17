# v2 재건축 4~8단계 Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** v2 원칙(3단계 채택, 커밋 219f32fa) 위에 훅·스킬·에이전트·시험 도구·문서를 spec 대로 새로 쓰고 로컬 main 에 병합한다.

**Architecture:** 단계마다 한 태스크 이상, 태스크마다 커밋한다. 훅(4단계) → 리뷰 스킬과 렌즈(5단계) → 나머지 스킬·워크플로(5단계) → 시험 도구 이관(6단계) → 문서와 기록(7단계) → 로컬 병합(8단계) 순서다. 각 태스크는 그 대상의 보조 계약 검사를 함께 쓴다.

**Tech Stack:** bash, Python 3, Node(워크플로 시험), Claude Code 플러그인 구조.

**Spec:** `docs/superpowers/specs/2026-11-13-v2-rebuild-design.md` (「뼈대 지도」, 「구성 요소별 새 계약」, 「시험 체계」, 「저장소 CLAUDE.md 교체안」, 「이행 순서」 4~8행). 0~3단계 plan 은 `docs/superpowers/plans/2026-11-13-v2-rebuild-stage0-3.md`.

## Global Constraints

- 브랜치는 `v2-rebuild`. push 하지 않는다(사용자가 말할 때까지 보류). 다른 브랜치·워크트리·저장소를 git 으로 바꾸지 않는다.
- 테스트는 하나씩 차례로 실행한다(PC 메모리 부족 전례). 동시 서브에이전트는 4개, `claude -p` 동시 실행은 2개까지(2026-11-16 메모리 부족으로 예약 작업이 두 번 중단된 뒤 정했다).
- 원칙 작업의 생성·판정과 서브에이전트는 Opus 5.5 만 쓴다.
- 각 태스크 끝 검증 명령은 `for t in scripts/test_*.sh; do bash "$t" >/dev/null 2>&1 || echo "BAD $t"; done; claude plugin validate ./` 이고, 기대 출력은 `BAD` 줄 없음과 `Validation passed` 다. 단계 끝 FAIL=0 은 그 단계까지 쓴 검사에 적용한다(spec 보조 계약).
- 새 검사는 `scripts/_test_check.sh` 의 `check "<검사 이름>" '<참이면 통과하는 셸 식>'` 형식으로 쓴다. plan 의 검사 이름을 그대로 쓰고, 셸 식은 실행자가 정한다. 「실패를 확인한다」 단계의 Expected 는 그 태스크에서 새로 쓴 검사 이름이 모두 `FAIL:` 로 나오는 것이다.
- 지운 이름·경로를 찾는 검사의 공통 제외 목록은 `docs/superpowers/`(spec·plan·기록), 참고서의 「v1 조항 근거」 절, `HANDOFF-*.md`, `reply-edit/`, `trial_reply_edit.py` 이고, Task 7 전까지는 `README.md`·저장소 `CLAUDE.md` 도 뺀다. 목록은 `scripts/_doc_keys.sh` 의 배열 하나에 둔다.
- 각 태스크는 자기가 지운 대상을 검사하던 옛 검사(`test_docs_drift.sh`·`_doc_keys.sh`·`_doc_paths.py` 포함)를 같은 태스크에서 지운다.
- 실리는 지시문(훅이 Claude 에게 보내는 글, 스킬·에이전트 description)에 금지어가 백틱 밖에 없다.
- 대화 원문·답·판정은 저장소에 넣지 않고 `%USERPROFILE%\.dc-eval\` 에 둔다. 저장소에는 실행 코드·판정 지시·턴 ID 만 둔다.
- `kofia.or.kr` 접속 금지 규칙은 웹을 쓰는 에이전트 정의에 둔다.
- `trial_reply_edit.py`·`reply-edit/`·`HANDOFF-nested-orchestration-first-run.md` 는 손대지 않는다.
- 삭제하는 파일은 태그 `archive/v1-final` 에 남아 있으므로 추가 보존 태그 없이 지운다. 리뷰·결정 기록은 지우지 않는다.

## spec 과 다른 점

- **리뷰 구조(2026-11-17 사용자 지시와 그 뒤 재설계):** spec 은 spec·plan 게이트에서 적대 렌즈와 근거 렌즈 두 개를 실행한다고 정했다. 사용자는 "카테고리별로 적대를 만들고, 메인 세션에서 통합 후 1차 디펜스 하고, 반영"하라고 지시했고, 이어서 기존 렌즈 구분이 검토 내용(근거·형식)과 접근 방식(적대)을 섞었다고 지적했다. 그래서 렌즈를 접근 방식과 컨텍스트 분리 필요로 다시 나눠 일곱 개에서 네 개로 줄인다. 이름은 바꾸지 않는다.
  - `lens-grounding`(대조, 드라이): 주장과 형식을 출처·코드·형식 계약(`reading-docs.md` 의 제목 규칙 포함)과 맞춰 보고 다른 점만 낸다. 옛 `lens-fit` 의 형식 계약과 문서 타입 판정(`doc_type`)을 흡수한다. 옛 `domain-pruning` 의 "근거 렌즈와 형식 렌즈를 합치지 않는다" 결정(입력이 출처와 계약으로 다르다)은 이 재설계로 대체한다. 두 입력은 `CRITERIA` 줄에 함께 넘기고, 런타임 출력 검토도 출력 종류와 무관하게 이 렌즈 하나를 쓴다.
  - `lens-adversarial`(설계 결함, 적대): 실패 모드·과설계·되돌릴 수 없는 위험과 옛 `lens-consistency` 의 내부 모순·커버리지 공백·이름 드리프트·스코프(산출물 공백 포함)를 본다.
  - `lens-rebuttal`(반대 근거, 적대): 웹 검색·웹 조회 권한은 렌즈 중 이 렌즈에만 둔다.
  - `lens-readability`(독자, 적대): 대상과 목적 한 줄과 문체 공격 항목만 받고 출처·대화는 받지 않는다. 맥락 없이 읽다 막히는 곳과 AI 티 문체를 공격하고, 렌더링 산출물이면 화면을 열어 배치·겹침·잘림·대비·분량을 본다(옛 `lens-visual` 흡수). 화면은 대조할 출처가 없는 목적 기반 판정이라 독자 렌즈가 맡는다. 브라우저 도구는 호출자가 준 `http://localhost` 주소에만 쓴다.
  - 네 개로 나눈 기준은 한 렌즈에 합치면 판정이 오염되는 조건이다. 적대 자세가 대조 판정에 섞이는 조건, 출처를 읽은 렌즈는 맥락 없는 독자를 흉내 낼 수 없는 조건, 웹 권한을 필요한 렌즈에만 두는 조건이다.
  - spec·plan 은 대조·설계 결함, 전달 문서는 대조·독자를 쓰고, 사용자가 반박을 요청하면 반대 근거를 추가한다. 메인 세션이 통합한 뒤 적대 렌즈의 지적에는 **1차 디펜스**(원문·코드·사용자 원문으로 반박을 시도해 받쳐지지 않는 지적을 거름)를 한다. 대조 렌즈의 지적은 반박을 시도하지 않고, 인용 위치가 실제로 그렇게 적혀 있는지와 지적한 결과가 그 근거에서 따라 나오는지만 확인한다. 기각마다 근거 위치를 기록하고, 사용자 보고에 기각 수를 적어 작성자 편향을 감시한다.
  - 통합 렌즈가 옛 렌즈의 단독 발견을 놓치는지는 측정하지 않았다. spec 「미결 쟁점」 4행과 같이 v2 이후 첫 전달 문서·spec 2~3건에서 옛 `lens-fit`·`lens-visual`·`lens-consistency` 정의(태그 `archive/v1-final`)를 한 번씩 실행해 비교한다.
  - 재현 시험 판정자는 렌즈가 아니라 드라이 측정 도구로 둔다(Task 6).
  - 이 재설계는 Task 2 커밋 뒤에 정했으므로, `lens-review` 의 렌즈 표·입력 형식·디펜스 구분은 Task 3 이 렌즈 정의와 한 커밋에서 고친다.
- **문체 카테고리 기준:** spec 은 `lens-readability` 를 사용자 판정 기준점 5개로만 본다고 정했다. 2026-11-17 다른 세션이 전달한 사용자 원문 AI 티 목록(저장소 밖 `%USERPROFILE%\.dc-eval\wants\ai-tells-2026-11-17.md`, 사용자 지시로 반영)을 공격 항목으로 더하고, 기준점 5개와 과잉 지적 반례를 디펜스 기준으로 쓴다. 저장소에는 항목 이름과 짧은 설명만 두고 긴 원문 인용은 넣지 않는다. 사용자가 반박을 요청한 주장(보고서·제안서의 결론)은 반박 카테고리(`lens-rebuttal`)를 더 쓴다.
- **동시 실행과 테스트 실행 방식:** spec 은 재현 생성 동시 3개와 「변경 뒤 실행」의 동시 실행 명령을 정했다. 2026-11-16 PC 메모리 부족으로 예약 작업이 두 번 중단되어, 생성은 동시 2개(기본값), 테스트는 차례 실행으로 바꾼다.
- **이관 원본:** spec 은 `replay5.py`·`gen_reading_v4.py`·`diff\sbs.py` 를 옮긴다고 적었다. 3단계에서 그 후속판 `replay6.py`(재개 방식·리비전 기록·원자적 쓰기)와 `gen_reading_v5.py`(점수 먼저·판독 복사)를 만들어 썼으므로 후속판을 옮긴다. `sbs.py` 의 좌우 비교 기능은 `gen_reading_v5.py` 에 포함되어 있다.
- **좌우 비교 출력:** spec 은 아티팩트가 아닌 로컬 HTML 이라고 정했다. 2026-11-14 사용자가 집에서 판독 페이지를 아티팩트로 요청했으므로, 기본은 로컬 HTML 로 두고 사용자가 요청하면 아티팩트로 올린다.
- **원칙 문장:** 3단계 뒤 원칙을 두 차례 고쳤다(완료 기준 확인, 반대 사례 점검 열한 곳). 채택 근거는 `docs/domain-discipline.md` 「v2 상시 지시 검증」.
- **`_eval_env.sh` 의 인증·설정 지문:** spec 「뼈대 지도」는 `_eval_env.sh` 를 인증과 설정 지문으로 유지한다고 적었다. 재현 시험(Task 6)은 API 키 대신 로그인 토큰으로 `claude -p` 를 실행해 그 함수들을 쓰지 않으므로, Task 6 에서 지우고 상위 경로의 CLAUDE.md 를 찾는 `ancestor_claude` 만 남겼다.

## Review Focus

- **지운 훅을 가리키는 설정:** `hooks.json` 이나 다른 스크립트가 지운 훅 파일을 가리키면 세션마다 오류가 난다(Task 1 `test_hooks.sh` 의 경로 실재 검사).
- **지운 스킬 이름을 가리키는 문서:** `review-specs`·`review-docs`·`dispatching-lenses` 를 가리키는 곳이 50곳을 넘는다(inv3). 하나라도 남으면 열리지 않는 스킬을 찾는다(Task 2 스킬 이름 검사, Task 4 경로 실재 검사).
- **디펜스가 모든 지적을 거름:** 1차 디펜스가 근거 없이 지적을 기각하면 리뷰가 무력해진다. 기각마다 반박 근거(원문 위치)를 기록에 남기게 한다(Task 2 검사 `lens-review 기록 형식에 기각 근거 칸이 있다`).
- **재현 도구 이관 뒤 값 불일치:** 저장소로 옮긴 판정 집계가 저장소 밖 도구와 다른 값을 내면 이후 시험이 어긋난다(Task 6 재계산 대조).
- **병합 뒤 PC 사본:** 로컬 main 병합만으로는 PC 사본이 바뀌지 않는다(push 뒤 자동 갱신). 병합 단계에서 push 하지 않는다(Task 8).

---

### Task 1: 훅 정리 (4단계)

**Files:**
- Delete: `hooks/prior_art_nudge_userpromptsubmit.sh`, `hooks/rules_nudge_pretooluse.sh`, `hooks/doc_format_pretooluse.sh`, `hooks/doc_review_posttooluse.sh`, `hooks/_doc_form_check.py`, `hooks/doc_word_pretooluse.sh`, `hooks/nested_judgment_pretooluse.sh`, `scripts/test_doc_form.sh`
- Rename: `hooks/rules_nudge_sessionstart.sh` → `hooks/spec_gate_sessionstart.sh`(세션 시작 표시만, 출력 없음)
- Modify: `hooks/hooks.json`(연결 8개: SessionStart scaffold·update_check·spec_gate, PreToolUse readonly, PostToolUse spec_review·doc_word, UserPromptSubmit reply_reminder, Stop stop_gates), `hooks/doc_word_posttooluse.sh`(Write·Edit·Bash 뒤 다른 프로젝트 산출물의 금지어를 Claude 에게 알림, 거부 없음), `hooks/stop_gates.sh`(금지어 알림 제거, 마커 게이트만), `hooks/spec_review_posttooluse.sh`·`hooks/_spec_marker.sh`(리뷰 지시문: "`$REVIEW_SKILL` 의 설계 문서 절차로 리뷰하라(변수 값은 Task 2 전까지 현행 스킬 이름, Task 2 에서 `lens-review`). 사용자가 상시 요청한 절차이므로 승인을 묻지 말고 실행하라. 처분을 끝내고 마지막 줄에 spec-review 마커를 남겨라"), `hooks/reply_reminder_userpromptsubmit.sh`(끄는 변수 삭제), `scripts/test_hooks.sh`

**Interfaces:**
- Produces: 훅 계약은 spec 「구성 요소별 새 계약」 훅 표 그대로. `_spec_marker.sh` 의 리뷰 지시문 안 스킬 이름은 변수 하나(`REVIEW_SKILL`)로 두고 Task 2 가 그 값을 `lens-review` 로 바꾼다.

- [ ] **Step 1:** `test_hooks.sh` 에 검사를 쓴다: `hooks.json 명령 경로가 모두 실재한다`, `hooks.json 연결 수가 남는 훅 목록과 같다`(목록은 테스트 안 배열 하나, 개수 숫자를 따로 박지 않는다), `훅이 Claude 에게 보내는 글에 백틱 밖 금지어가 없다`(spec_review·stop_gates·doc_word·update_check 출력 픽스처), `끄는 환경 변수가 없다`(`DISCIPLINED_CODER_.*=off` 문자열이 hooks/ 에 없다), `doc_word 는 거부하지 않는다`(출력에 `"decision": "block"`·`permissionDecision` 이 없다).
- [ ] **Step 2:** Run: `bash scripts/test_hooks.sh 2>&1 | grep FAIL` Expected: Step 1 검사 이름이 `FAIL:` 로 나온다.
- [ ] **Step 3:** 위 Files 대로 삭제·이름 변경·수정한다. 삭제한 훅만 쓰던 공유 함수 술어는 `_spec_marker.sh` 에서 빼고, 지운 훅을 대상으로 하던 옛 검사도 지운다.
- [ ] **Step 4:** `grep -rn` 으로 지운 훅 파일 이름을 가리키는 곳을 찾아(README·CLAUDE.md 제외, 7단계 대상) 스크립트·테스트에서 고친다.
- [ ] **Step 5:** Global Constraints 검증 명령. Expected: `BAD` 줄 없음, `Validation passed`.
- [ ] **Step 6:** 커밋 `훅을 여덟 개 연결로 줄이고 남는 훅 계약을 검사한다`.

### Task 2: `lens-review` 스킬 신설과 리뷰 스킬 셋 삭제 (5단계)

**Files:**
- Create: `skills/lens-review/SKILL.md`(본문 8,000자 이하)
- Delete: `skills/dispatching-lenses/`, `skills/review-specs/`, `skills/review-docs/`
- Modify: 세 스킬 이름을 가리키는 스킬·에이전트·스크립트·테스트(README·저장소 CLAUDE.md·기록은 Task 7 또는 손대지 않음)

**Interfaces:**
- Consumes: Task 1 의 리뷰 지시문(`lens-review` 이름).
- Produces: 리뷰 기록 이름 규칙(옛 `review-docs` 의 「기록 파일 이름 규칙」 절을 이 태스크에서 `skills/managing-docs/SKILL.md` 로 옮긴다), 렌즈에 넘기는 입력 형식(`MODE` 줄, 대상 경로, 카테고리 기준 경로). Task 3 렌즈 정의가 이 형식을 읽는다.

- [ ] **Step 1:** `test_docs_drift.sh` 에 검사를 쓴다: `lens-review 본문이 8,000자 이하다`, `지운 스킬 이름(dispatching-lenses·review-specs·review-docs)을 가리키는 살아 있는 문서가 없다`(기록·spec·plan·참고서 「v1 조항 근거」 제외), `lens-review 가 세 진입점 절을 가진다`(절 제목: 직접 요청, 설계 문서, 전달 문서), `lens-review 기록 형식에 기각 근거 칸이 있다`, `managing-docs 에 기록 파일 이름 규칙 절이 있다`, `spec 리뷰 지시문이 lens-review 를 가리킨다`.
- [ ] **Step 2:** Run: `bash scripts/test_docs_drift.sh 2>&1 | grep FAIL` Expected: Step 1 검사 이름이 `FAIL:` 로 나온다.
- [ ] **Step 3:** 스킬을 쓴다. 내용은 spec 「스킬」 표의 `lens-review` 계약과 「spec 과 다른 점」 리뷰 구조를 따른다. 절차는 (1) 대상 종류로 카테고리 렌즈를 고른다, (2) 렌즈마다 한 번 실행한다(동시 4개 이하), (3) 메인 세션이 같은 지적을 합친다, (4) 1차 디펜스: 적대 렌즈의 지적마다 원문·코드·사용자 원문으로 반박을 시도하고, 반박이 받쳐지면 기각하며 기각 근거(위치)를 기록에 남긴다. 대조 렌즈의 지적은 인용 위치와 귀결만 확인한다(이 구분은 Task 3 에서 넣는다). 사용자 보고에 기각 수를 적는다, (5) 남은 지적은 Claude 가 반영하고 가치 판단·되돌릴 수 없는 항목만 사용자에게 올린다, (6) spec·plan 은 마지막 줄에 마커를 남긴다, (7) 다시 리뷰는 설계를 틀리게 만드는 지적이 남았을 때 바뀐 절만 한다. 선행연구는 발동 기준(아직 해 본 적 없고 되는지 미지수)에 들면 묻지 않고 실행한다. 사용자가 렌즈를 요청하면 묻지 않고 실행한다. 전달 문서는 사용자 요청이나 외부 공개 직전에만 검진하고 사용자가 지정한 형식·발신 주체·문장은 고치지 않는다. 기록 위치·이름은 `managing-docs` 를 가리킨다.
- [ ] **Step 4:** `review-docs` 의 기록 이름 규칙 절을 `managing-docs` 로 옮기고, `_spec_marker.sh` 의 `REVIEW_SKILL` 을 `lens-review` 로 바꾼 뒤 세 스킬을 지운다. Step 1 의 이름 검사가 가리키는 곳(`.claude/settings.json`·`hooks/` 포함)을 고치고, 지운 스킬을 대상으로 하던 옛 검사를 지운다.
- [ ] **Step 5:** Global Constraints 검증 명령. Expected: `BAD` 줄 없음, `Validation passed`.
- [ ] **Step 6:** 커밋 `리뷰 스킬 셋을 카테고리 적대 리뷰와 1차 디펜스를 맡는 lens-review 하나로 합친다`.

### Task 3: 렌즈 에이전트 정리 (5단계)

**Files:**
- Delete: `agents/lens-consistency.md`, `agents/lens-fit.md`, `agents/lens-visual.md`, `agents/map-check.md`
- Modify:
  - `agents/lens-adversarial.md`: 「spec 과 다른 점」의 설계 결함 범위.
  - `agents/lens-grounding.md`: 옛 `lens-fit` 의 형식 계약 판정과 `doc_type`(null 이면 빈 지적을 판정으로 쓰지 않는 규칙 포함)을 옮긴다. 출처와 다른 점만 내고 추정 지적은 내지 않는다. 웹 도구는 두지 않는다.
  - `agents/lens-readability.md`: 기준 문서 읽기 절·축 위치 입력·관찰 목록·"항목을 묶거나 줄이지 마라" 규칙을 지우고, 「입력」 절에 대상·목적·`style-attacks.md` 만 받는다고 적는다. 옛 `lens-visual` 의 화면 관찰과 `purpose`·화면 `suggestions`, 브라우저 도구, 브라우저 도구가 없을 때의 처리를 옮기고 `kofia.or.kr` 금지를 둔다.
  - `agents/lens-rebuttal.md`, `agents/researcher.md`, `agents/citation-verifier.md`, `agents/citation-judge.md`: `PRINCIPLES` 줄 제거와 웹 규칙 확인.
  - `scripts/lens_contract.json`: 지운 렌즈 넷과 `principles_applied` 삭제. `lens-adversarial` types 에 `contradiction`·`gap`·`drift`·`scope` 추가, `lens-grounding` 에 형식 지적 type 과 `doc_type` 추가, `lens-readability` 에 화면 `suggestions` 추가.
  - `skills/lens-review/SKILL.md`: 렌즈 표를 네 렌즈로, 입력 형식의 `CRITERIA`(대조는 출처와 형식 계약, 독자는 `style-attacks.md`), 디펜스를 적대 렌즈에만 하고 대조 렌즈는 위치와 귀결만 확인, 사용자 보고에 기각 수를 적는다. 독자 렌즈의 `suggestions` 도 디펜스 대상이며 기각 수에 넣는다.
  - `skills/domain-pruning/SKILL.md`(`doc_type` 출처, "두 렌즈의 통합" 결정), `skills/review-llm-calls/SKILL.md`(출력 종류별 배정표), `skills/researching-prior-art/SKILL.md`(지도 대조 단계·`map_check` 반환 칸 서술), 그 밖에 지운 렌즈 이름을 가리키는 스킬·스크립트.
  - `scripts/test_lens_contract.sh` 와 지운 렌즈를 대상으로 하던 옛 검사.
- Create: `skills/lens-review/references/style-attacks.md`(문체 공격 항목: 직역투, 어울리지 않는 고유어, 평소 안 쓰는 말, 뜻 없는 단위·차수, 대명사처럼 쓰는 말, 얼버무림, 비유, 내부 맥락·용어, 장황함·묻지 않은 답, 톤 없는 정보 교환체, 형식. 항목마다 한두 줄 설명. 과잉 지적 반례 절: 전체가 자연스러우면 통과, 흔한 업무 표현은 직역투로 보지 않음. 원문 인용은 넣지 않는다)

**Interfaces:**
- Consumes: Task 2 의 렌즈 입력 형식.
- Produces: 렌즈 정의는 `PRINCIPLES` 줄과 `principles_applied` 가 없고 Task 2 의 입력 형식(`MODE`·`TARGET`·`CRITERIA`)을 읽는다. 적대 렌즈 셋(설계 결함·반대 근거·독자)은 적대 자세로, 대조 렌즈는 드라이하게 지적하며, 모든 지적은 원문 위치와 근거를 낸다(디펜스가 대조할 수 있게).

- [ ] **Step 1:** `test_lens_contract.sh` 에 검사를 쓴다: `계약 JSON 의 렌즈가 정의 파일과 같다`(렌즈 목록은 `agents/lens-*.md` 에서 도출), `렌즈 정의에 PRINCIPLES·principles_applied 가 없다`, `웹 주소를 여는 도구(WebSearch·WebFetch·browser_navigate)를 가진 에이전트 정의에 kofia.or.kr 금지가 있다`, `WebSearch·WebFetch 를 가진 렌즈는 lens-rebuttal 뿐이다`, `browser_navigate 를 가진 렌즈는 lens-readability 뿐이다`, `lens-readability 에 입력 절이 있다`(절 제목 「입력」), `지운 렌즈 이름(lens-consistency·lens-fit·lens-visual·map-check)을 가리키는 살아 있는 지시문이 없다`(범위는 `agents/`·`skills/`·`hooks/`·`workflows/`·`scripts/*.json`, 참고서와 테스트 픽스처는 범위 밖), `모든 에이전트 frontmatter 가 안전하다`(agents/*.md 전부, name·description 존재, description 에 백틱 밖 금지어 없음), `style-attacks.md 에 과잉 지적 반례 절이 있다`(절 제목), `lens-adversarial 계약 types 에 contradiction 이 있다`. 사내 정보 검색어 금지(`lens-rebuttal`)와 검색어 일반화(`researcher`·`citation-verifier`)는 이미 있으므로 기존 검사가 없으면 절 제목으로 판정하는 검사를 추가하되 Step 2 의 실패 대상에서 뺀다.
- [ ] **Step 2:** Run: `bash scripts/test_lens_contract.sh 2>&1 | grep FAIL` Expected: Step 1 의 새 검사 중 지금 참인 검사(사내 정보·검색어 일반화)를 뺀 이름이 `FAIL:` 로 나온다.
- [ ] **Step 3:** Files 대로 고친다. 렌즈별 계약은 spec 「에이전트」 표와 「spec 과 다른 점」 리뷰 구조. `workflows/prior-art-search.js` 와 `scripts/prior_art_contract.json` 의 `MapCheck`·`map-check` 를 지우고 `test_workflow.sh`·`test_prior_art_contract.sh` 를 맞춘다.
- [ ] **Step 4:** Global Constraints 검증 명령. Expected: `BAD` 줄 없음, `Validation passed`.
- [ ] **Step 5:** 커밋 `렌즈를 대조·설계 결함·반대 근거·독자 네 개로 정리하고 문체 공격 항목을 둔다`.

### Task 4: 나머지 스킬 정리와 `side-by-side` 신설 (5단계)

**Files:**
- Modify: `skills/managing-docs/`(측정된 규칙만, 기록 이름 규칙 받기, 렌즈 의무·가드 권유 삭제), `skills/domain-readme/`·`domain-plugin/`(v1 `FOCUSED` 규칙 소유)·`domain-pruning/`·`review-llm-calls/`(묻는 단계를 권장안 진행으로, 원칙 ID 인용 삭제), `skills/nested-orchestration/`(훅 진입 삭제, 판단 지점만), `skills/researching-prior-art/`(제안·수락 단계 삭제, 출력 스키마는 계약 코드를 가리킴), 모든 스킬 description(호출 조건만, 합계 2,002자보다 짧게)
- Create: `skills/side-by-side/SKILL.md`(판독 페이지 형식의 유일한 소유처. 저장소 CLAUDE.md 「판독 페이지」 절 내용을 옮긴다. 로컬 HTML 기본, 집 등 원격에서는 사용자가 요청하면 아티팩트)
- Test: `scripts/test_docs_drift.sh`

**Interfaces:**
- Consumes: Task 2 가 `managing-docs` 로 옮긴 기록 이름 규칙(이 태스크는 그 절을 지우지 않는다), Task 3 의 렌즈 이름.
- Produces: `side-by-side` 스킬 이름(Task 6 의 `side_by_side.py` 와 Task 7 의 CLAUDE.md 가 가리킨다).

- [ ] **Step 1:** 검사를 쓴다: `스킬 description 합계가 2,002자보다 작다`, `스킬 description 에 백틱 밖 금지어가 없다`, `스킬·에이전트가 v2 원칙에 없는 조항 ID 를 인용하지 않는다`(참고서 「v1 조항 근거」 예외), `문서가 가리키는 경로와 「」 절이 실재한다`(Global Constraints 공통 제외 목록 적용).
- [ ] **Step 2:** Run: `bash scripts/test_docs_drift.sh 2>&1 | grep FAIL` Expected: Step 1 검사 이름이 `FAIL:` 로 나온다.
- [ ] **Step 3a:** `managing-docs` 를 spec 「스킬」 표 계약대로 줄인다(측정된 규칙, 문서 타입·수명·위치, 제목 규칙, 마크다운 초안 규칙만).
- [ ] **Step 3b:** `domain-*`·`review-llm-calls`·`nested-orchestration`·`researching-prior-art` 를 spec 「스킬」 표 계약대로 고친다. `domain-plugin` 에 v1 `FOCUSED` 규칙(한 단위에 한 작업, 입력·출력만 보고 쓸 수 있게)을 넣는다.
- [ ] **Step 3c:** `side-by-side` 스킬을 쓰고, 모든 스킬 description 을 호출 조건만으로 줄인다.
- [ ] **Step 4:** Global Constraints 검증 명령. Expected: `BAD` 줄 없음, `Validation passed`.
- [ ] **Step 5:** 실제 요청 관찰: 임시 폴더를 `HOME`·`USERPROFILE`·`CLAUDE_CONFIG_DIR` 로 모두 지정해(실제 PC 사본을 덮어쓰지 않게) 현재 브랜치 플러그인을 설치한 뒤, 도구를 켠 `claude -p` 로 "이 spec 을 적대적으로 검토해 줘", "이걸 이미 누가 해봤는지 찾아 줘", "두 답을 좌우로 비교해 줘" 를 보낸다. 판정 기준은 출력 JSON 기록에 해당 스킬(`lens-review`·`researching-prior-art`·`side-by-side`)의 Skill 호출이 있는지다. 없으면 그 description 을 고쳐 한 번 더 보고, 두 번째도 없으면 결과를 태스크 보고에 적고 진행한다. 실행 뒤 실제 `~/.claude/disciplined-coder/agent-principles.md` 의 수정 시각이 바뀌지 않았는지 확인한다.
- [ ] **Step 6:** 커밋 `나머지 스킬을 권장안 진행으로 정리하고 좌우 비교 스킬을 둔다`.

### Task 5: (예비) 5단계 정리 확인

Task 2~4 리뷰에서 장부에 미뤄 둔 지적을 처리한다. 장부(`progress.md`)에 미룬 지적이 없으면 장부에 `Task 5: skipped (no parked findings)` 를 적고 넘어간다.

- [ ] **Step 1:** 장부에서 Task 2~4 의 미룬 지적 목록을 뽑는다.
- [ ] **Step 2:** 지적마다 고치고 Global Constraints 검증 명령을 실행한다. Expected: `BAD` 줄 없음, `Validation passed`.
- [ ] **Step 3:** 커밋 `5단계 리뷰에서 미룬 지적을 반영한다`.

### Task 6: 시험 도구 이관 (6단계)

**Files:**
- Create: `scripts/eval_replay.sh`, `scripts/eval_replay_report.sh`, `scripts/_replay.py`(저장소 밖 `replay6.py` 를 옮김: 메모리 대기 `MEM_MIN_GB` 기본 2.5, 동시 실행 `PAR` 기본 2, 토큰 만료 대기, 원본 세션 파일이 없으면 `%USERPROFILE%\.dc-eval\replay\sessions-backup\` 사본을 읽음), `scripts/_judge.py`(`judge_hidden.py`·`judge_pair.py` 를 옮김), `scripts/side_by_side.py`(`gen_reading_v5.py` 를 옮김), `scripts/backup_sessions.py`(턴 목록이 가리키는 원본 세션 파일을 `%USERPROFILE%\.dc-eval\replay\sessions-backup\` 에 복사, 이미 있으면 생략. `eval_replay.sh` 가 생성 전에 실행한다), `evals/replay/README.md`(조건 정의·판정 지시·절차), `evals/replay/turns-hidden1.txt`(턴 ID 만)
- Rename: `scripts/test_eval_cases.sh` → `scripts/test_replay.sh`
- Delete: `evals/principles/`, `scripts/eval_clause.sh`, `scripts/eval_clause_report.sh`, `scripts/_eval_clause.py`, `scripts/_test_eval_clause.py`, `scripts/_eval_run.py`, `scripts/_eval_lib.py`(쓰는 함수는 `_replay.py`·`_judge.py` 로 옮긴 뒤)

**Interfaces:**
- Produces: `bash scripts/eval_replay.sh <턴 목록> <조건 A> <조건 B>`, `bash scripts/eval_replay_report.sh <판정 폴더> <A> <B>`. 결과 폴더는 `%USERPROFILE%\.dc-eval\` 아래. 계약은 spec 「스크립트」 표.

- [ ] **Step 1:** `test_replay.sh` 에 검사를 쓴다: `evals/replay 에 비밀 패턴(키·메일·PC 사용자 경로)이 없다`, `evals/replay 에 대화 원문이 없다`(턴 ID 파일은 숫자 줄만), `생성·판정 모델이 claude-opus-5-5 가 아니면 중단한다`(픽스처), `같은 턴·조건 답이 있으면 다시 생성하지 않는다`(픽스처), `판정 분류 경계`(spec `_judge.py` 계약의 예: (1,1)개선, (1,0)개선, (0,0)같음, (2,-1)같음, (-1,0)악화), `생성 설정 폴더가 실제 ~/.claude 와 분리된다`(픽스처의 설정 경로가 임시 폴더 아래), `판정 응답 JSON 을 읽는다`(점수 없는 응답은 error 로 남김), `원본이 없으면 세션 사본을 읽는다`(픽스처).
- [ ] **Step 2:** Run: `bash scripts/test_replay.sh 2>&1 | grep FAIL` Expected: Step 1 검사 이름이 `FAIL:` 로 나온다.
- [ ] **Step 3:** 도구를 옮긴다. 비밀 값(API 키, 메일)은 코드에 넣지 않고 환경 변수와 `~/.dc-eval.env` 에서 읽는다.
- [ ] **Step 4:** 재계산 대조: `eval_replay_report.sh` 로 `%USERPROFILE%\.dc-eval\calib\hidden1` 의 판정을 다시 집계해 저장소 밖 `report_hidden.py` 출력(개선 58·악화 20·같음 28)과 같은지 본다. 생성은 다시 하지 않는다.
- [ ] **Step 5:** 옛 시험 파일을 지우고 가리키는 곳을 고친다.
- [ ] **Step 6:** Global Constraints 검증 명령. Expected: `BAD` 줄 없음, `Validation passed`.
- [ ] **Step 7:** 커밋 `재현 시험 도구를 저장소로 옮기고 옛 조항별 시험을 지운다`.

### Task 7: 문서와 기록 (7단계)

**Files:**
- Modify: 저장소 `CLAUDE.md`(spec 「저장소 CLAUDE.md 교체안」 그대로, 「판독 페이지」 절은 `side-by-side` 를 가리키는 한 줄), `README.md`(v2 기능, `domain-readme` 기준), `docs/superpowers/specs/2026-11-13-v2-rebuild-design.md`(머리 `대체 예정:` → `supersedes:`), 대상 spec 들의 머리(superseded 표시)
- Test: `scripts/test_docs_drift.sh`

**Interfaces:**
- Consumes: Task 1~6 이 남긴 훅·스킬·스크립트 이름. 공통 제외 목록에서 `README.md`·저장소 `CLAUDE.md` 를 이 태스크에서 뺀다.

- [ ] **Step 1:** 검사를 쓴다: `살아 있는 문서가 v1 에만 있던 조항 ID 를 인용하지 않는다`(원칙·참고서·기록·spec·plan 제외), `CLAUDE.md 「변경 뒤 실행」 명령이 앞의 실패를 묻지 않는다`(명령 문자열을 셸로 실행해 일부러 실패하는 가짜 테스트 하나를 넣은 임시 폴더에서 FAILED 가 나오는지).
- [ ] **Step 2:** Run: `bash scripts/test_docs_drift.sh 2>&1 | grep FAIL` Expected: Step 1 검사 이름이 `FAIL:` 로 나온다.
- [ ] **Step 3:** 공통 제외 목록에서 `README.md`·`CLAUDE.md` 를 빼고, 두 문서를 고친다. superseded 표시와 `supersedes:` 변경은 같은 커밋에 둔다.
- [ ] **Step 4:** 결함 주입 여섯 가지(spec 「테스트가 지킬 핵심 계약」 표)를 임시 클론에서 하나씩 넣는다. 0~3단계 plan Task 3 의 주입 스크립트를 쓰되, Step 3 뒤의 파일 내용으로 찾을 글(superseded 주입은 v2 spec 머리의 `supersedes:` 줄이 가리키는 문서의 `superseded` 줄)과 기대 검사 이름을 다시 정한다. 주입마다 기대 검사 이름이 `FAIL:` 로 나와야 하고, 치환이 일어나지 않으면 그 주입을 실패로 본다. 클론의 테스트는 `HOME`·`USERPROFILE` 을 임시 폴더로 둔다.
- [ ] **Step 5:** Global Constraints 검증 명령. Expected: `BAD` 줄 없음, `Validation passed`.
- [ ] **Step 6:** 커밋 `저장소 CLAUDE.md 와 README 를 v2 로 쓰고 대체된 spec 을 표시한다`.

### Task 8: 로컬 main 병합 (8단계)

**Interfaces:**
- Consumes: Task 1~7 커밋이 있는 `v2-rebuild`.

- [ ] **Step 1:** `v2-rebuild` 에서 전체 테스트와 validate 가 통과하는지 확인한다.
- [ ] **Step 2:** 로컬 main 으로 체크아웃해 `git merge --no-ff v2-rebuild` 한다. 충돌이 나면 멈추고 사용자에게 알린다.
- [ ] **Step 3:** 로컬 main 에서 Global Constraints 검증 명령. Expected: `BAD` 줄 없음, `Validation passed`. 실패하면 `git revert -m 1 HEAD` 로 병합을 되돌리고(spec 「되돌리는 방법」) 사용자에게 알린다.
- [ ] **Step 4:** push 하지 않는다. 사용자에게 병합 완료와 push(9단계)가 남았다고 보고한다.

<!-- spec-review: passed -->
