# 렌즈 에이전트 전환 구현 계획

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**목표:** 렌즈를 `skills/lens-*/` 스킬에서 `agents/lens-*.md` 에이전트 정의로 옮기고, 렌즈 관련 중복 구조(aggregating-lenses, 레포 문서 감사)를 지운다.

**구조:** 메인 세션이 리뷰 스킬과 `dispatching-lenses` 를 따라 렌즈 에이전트를 `subagent_type: disciplined-coder:lens-<관점>` 으로 실행한다. 출력 칸은 `scripts/lens_contract.json` 이 소유하고, 칸에 딸린 산문 규칙은 `dispatching-lenses` 「결과를 모으는 법」이 소유한다. `scripts/test_lens_contract.sh` 가 정의의 예시 블록과 호출 정책을 검사한다. 에이전트는 다른 에이전트를 실행하지 않는다.

**기술:** Claude Code 플러그인 에이전트 정의(markdown + YAML frontmatter), bash 테스트(`scripts/_test_check.sh` 의 `check`), 파이썬 JSON 처리(`scripts/_json_valid.sh` 의 `json_run`), `hooks/_doc_form_check.py`.

**Spec:** `docs/superpowers/specs/2026-10-25-lens-agent-restructure-design.md`. 실행자는 이 plan 과 spec 을 함께 읽어라. 호출 정책의 근거는 `docs/superpowers/decisions/2026-10-25-agent-call-policy.md` 에, 실측 근거는 `docs/superpowers/decisions/2026-10-25-lens-agent-restructure-research.md`(아래 "조사 기록")에 있다. plan 리뷰 기록은 `docs/superpowers/reviews/2026-10-25-lens-agent-restructure-plan-review.md` 다.

## 전역 제약

아래 값은 spec 「제약」과 「에이전트 구성」에서 옮겼다. 모든 작업이 이 값을 따른다.

- 렌즈 에이전트 이름은 `lens-` 로 시작하게 하라. 렌즈가 아닌 정의의 이름은 다른 앞말로 지어라(원칙 `LENS-ALLOWED`).
- frontmatter 에는 `name`, `description`, `tools`, `model` 을 적어라. `model` 값은 `opus` 다. `maxTurns` 와 `effort` 는 Task 1 측정값으로 정하라.
- `tools` 는 한 줄 쉼표 목록으로 적어라. 목록에는 spec 「에이전트 구성」 표의 도구만 둬라. `Agent`·`Agent(...)`·`Task` 와 쓰기 도구(Write, Edit, NotebookEdit)는 금지다.
- description 에는 렌즈가 하는 일과 입력 안내 "실행하는 쪽은 먼저 `dispatching-lenses` 를 Read 한다"만 적어라. 사용 제한 문장은 두지 마라(사용자 결정 2026-10-25, spec 「에이전트 구성」).
- 프롬프트 첫 줄은 `MODE: <모드>`, 둘째 줄은 `PRINCIPLES: <principles_path>` 다.
- 렌즈 결과 기록 파일 이름은 `<에이전트 이름>-<순번>.json` 이다.
- `kofia.or.kr` 와 그 아래 주소는 접속 금지다.
- 리뷰 모델은 Opus 다.
- 같은 질문을 같은 조건으로 두 번 실행하는 일은 금지다. 표본은 질문 수로 늘려라.
- 저장소 CLAUDE.md 「변경 뒤 실행」의 전체 테스트 명령(아래 "전체 테스트")이 `ALL PASS` 를 내야 한다. 테스트에는 개수를 박지 마라.
- Task 4 이후는 원칙 경량화 세션(`worktree-principles-slimming`)이 main 에 병합된 뒤 그 커밋 위에서 시작하라. 선행연구 개선 세션(`worktree-prior-art-agent-review`)이 먼저 병합되면 그 커밋도 받아라. 그 세션은 커밋 aa9e6d2 에서 스킬 `agent-prior-art` 를 `researching-prior-art` 로 바꿨다. 정의 `prior-art-*` 도 `researcher`·`citation-verifier`·`citation-judge`·`map-check` 로 바꿨다.
- 다른 세션의 브랜치와 워크트리는 읽기만 하라. 필요한 내용은 메시지로 묻거나 main 에 병합된 커밋을 보라.
- 커밋은 사용자 승인을 받은 뒤에만 하라. 각 Task 의 마지막 Step 에서 커밋할 파일 목록과 메시지를 보이고 승인을 물어라.

## 리뷰 초점

아래 입력과 조건은 기능 테스트가 직접 다루지 않는 실패 지점이다. 일어날 가능성이 큰 차례로 적었고, 각 줄의 확인은 괄호 안 작업에 넣었다.

1. 사용자가 `@agent-disciplined-coder:lens-adversarial` 로 MODE·PRINCIPLES 줄 없이 실행해도 출력이 계약을 지켜야 한다(Task 1 시험, Task 4 의 「입력」 절 검사).
2. Playwright 를 끈 세션에서 `lens-readability` 를 실행하면, 에이전트는 `notes` 에 "브라우저 도구 없음"을 적고 끝내야 한다(Task 1 기록, Task 4 의 문구 검사).
3. Task 4 부터 Task 8 까지 같은 이름의 스킬과 에이전트가 함께 있다. 이 동안 사용자 요청이 옛 스킬로 가면 안 된다(Task 1 시험, 결과에 따라 결정 기록에 사용 제한을 적는다).
4. `lens-adversarial-claim` 의 검색어에 대상 문서의 문장이나 수치가 그대로 들어가거나 `kofia.or.kr` 로 요청이 나가면 안 된다(Task 6 의 세션 기록 검사).
5. tools 를 YAML 배열이나 `Task` 로 적은 정의도 호출 정책 검사가 실패시켜야 한다(Task 3 결함 주입).

전체 테스트 명령은 다음과 같다.

```bash
d=$(mktemp -d); for t in scripts/test_*.sh; do ( bash "$t" > "$d/$(basename "$t").log" 2>&1 || echo "$t" >> "$d/bad" ) & done; wait; if [ -s "$d/bad" ]; then echo "FAILED:"; while read -r t; do echo "--- $t"; grep 'FAIL:' "$d/$(basename "$t").log"; done < "$d/bad"; else echo "ALL PASS"; fi
```

---

### Task 1: 런타임 시험

spec 「먼저 할 런타임 시험」의 시험을 하고 결정 기록에 적는 작업이다. spec 표의 첫 시험이 실패하면 이 plan 을 멈추고 사용자에게 물어라.

**Files:**
- Create: `agents/lens-grounding.md`, `agents/lens-adversarial.md`, `agents/lens-readability.md` (시험용 최소 정의다. Task 4 가 덮어쓴다)
- Create: `<scratchpad>/render-probe.html` (제목과 문단 하나가 있는 HTML)
- Create: `docs/superpowers/decisions/2026-10-25-lens-agent-runtime.md`

**Interfaces:**
- Produces: `maxTurns`·`effort` 값, CLAUDE.md 상속 여부, Playwright 도구 이름, 같은 이름 충돌 때 선택된 쪽. Task 4 가 이 값을 frontmatter 와 본문에 쓴다.

- [ ] **Step 1: 시험용 정의를 써라.** frontmatter 는 전역 제약대로 적고 `maxTurns`·`effort` 줄은 빼라. 본문에는 현행 SKILL.md 의 「레퍼런스 프롬프트」와 「출력 스키마」만 옮겨라. `lens-readability` 의 tools 는 `Read, mcp__plugin_playwright_playwright__browser_navigate, mcp__plugin_playwright_playwright__browser_take_screenshot, mcp__plugin_playwright_playwright__browser_snapshot` 이다.

- [ ] **Step 2: 적재 상태를 확인하라.** 아래 명령을 실행하라.

```bash
claude -p --plugin-dir "$PWD" --settings '{"enabledPlugins":{"disciplined-coder@chshin-tools":false}}' --output-format stream-json --verbose "아무 작업도 하지 말고 끝내라" > "<scratchpad>/init.jsonl"
```

`system`/`init` 이벤트의 agents·plugins·slash_commands 칸에서 `disciplined-coder:lens-grounding` 이 하나만 있는지 확인하라. `--settings` 로 설치본이 꺼지지 않아 같은 이름이 둘이면, 그 사실을 결정 기록에 적어라. 이어서 시험 3 의 결과를 해석할 수 없다고 적고 사용자에게 진행 방법을 물어라. 이 이벤트에 그 칸이 없으면 "적재 상태 확인 불가"로 적고 다음 Step 으로 가라.

- [ ] **Step 3: 시험 1과 시험 5를 한 번에 실행하라.** 프롬프트는 "Agent 도구로 subagent_type `disciplined-coder:lens-grounding` 을 실행하라. 프롬프트 첫 줄은 `MODE: spec`, 둘째 줄은 `PRINCIPLES: <저장소>/agent-principles.md`, 셋째 줄은 대상 `docs/superpowers/specs/2026-10-25-lens-agent-restructure-design.md` 다"이다. 명령에는 `--allowedTools "Agent Read Grep Glob"` 을 붙여라. stream-json 에서 Agent tool_use 의 `subagent_type`, 서브에이전트 이벤트의 도구 이름 집합, 턴 수, 도구 호출 수, 토큰, 시간, effort 표시를 읽어라. 판정은 "도구 이름 집합이 정의의 tools 안에 있다"이다. 읽지 못한 값은 "출력에 없음"으로 적어라.

- [ ] **Step 4: 시험 2를 실행하라.** 프롬프트는 "@agent-disciplined-coder:lens-adversarial docs/superpowers/plans/2026-10-25-lens-agent-restructure.md 를 검토하라"이고, 같은 권한 플래그를 붙여라. 판정은 spec 표대로 하라. 통과하지 못하면 사용자에게 대화형 세션에서 같은 문장을 입력해 달라고 요청하라. 대화형 결과로 판정하고, 두 결과를 함께 적어라.

- [ ] **Step 5: 시험 3을 실행하라.** 프롬프트는 "lens-adversarial 을 실행해 docs/superpowers/plans/2026-10-25-lens-agent-restructure.md 를 검토하라"이다. Skill 도구와 Agent 도구 중 어느 쪽이 호출되었는지 기록하라.

- [ ] **Step 6: 시험 4를 실행하라.** 프롬프트는 "Agent 도구로 `disciplined-coder:lens-readability` 를 실행해 `<scratchpad>/render-probe.html` 을 열고 화면을 캡처하라"이다. `--allowedTools` 에 Step 1 의 Playwright 도구 이름을 모두 넣어라. 결과가 실패이면 tool_result 의 오류 문구를 적고, 권한 거부인지 도구 부재인지 구분하라. 권한 거부이면 플래그를 고쳐 한 번 더 실행하라. 이어서 Playwright 를 끈 세션에서 같은 요청을 실행하고 출력의 `notes` 를 적어라.

- [ ] **Step 7: 시험 6을 실행하라.** 프롬프트는 "Agent 도구로 `disciplined-coder:lens-grounding` 을 실행하라. 에이전트에게 원칙 조항 `NO-ASSUME` 의 첫 문장을 그대로 적게 하라. 원칙 파일 경로와 조항 문구는 프롬프트에 넣지 마라"이다. stream-json 의 Agent tool_use 입력에 원칙 경로와 조항 문구가 없는지 먼저 확인하라. 있으면 그 결과를 무효로 적어라.

- [ ] **Step 8: 결정 기록을 써라.** 시험마다 실행한 명령, 관측값, 판정, spec 이 정한 실패 처리를 적어라. 측정값에서 고른 `maxTurns`·`effort` 와 근거도 적어라. effort 를 출력에서 읽지 못했으면 effort 를 빼는 안과 근거를 사용자에게 물어라. 시험 3 의 결과로 사용 제한이 필요하면 "Task 4 부터 Task 8 까지 사용자 직접 실행을 쓰지 않는다"를 적어라.

- [ ] **Step 9: 판정을 확인하라.** 결정 기록에 spec 표의 시험이 모두 있는지 확인하라. 시험 1 이 실패이면 멈추고 사용자에게 물어라. 시험 6 에서 에이전트가 원칙을 받으면 PRINCIPLES 줄을 뺄지 사용자에게 물어라. 시험 4 가 도구 부재로 실패하면, Task 2·4·7 에서 아래 "readability 대체 분기"를 따르라.

- [ ] **Step 10: 커밋 승인을 물어라.** 대상 파일은 시험용 정의와 결정 기록이고, 메시지는 "렌즈 에이전트 런타임 시험 결과를 기록한다"다. 승인되면 `git add agents/lens-grounding.md agents/lens-adversarial.md agents/lens-readability.md docs/superpowers/decisions/2026-10-25-lens-agent-runtime.md && git commit -m "렌즈 에이전트 런타임 시험 결과를 기록한다"` 를 실행하라.

**readability 대체 분기.** spec 은 시험 4 가 실패하면 `lens-readability` 를 글 검토 에이전트로 남긴다고 정했다. 이 분기에서 Task 2 의 readability 행은 modes `doc`, extra `purpose`·`suggestions` 로 하고, `suggestions` 하위 칸은 `where`·`why`·`rewrite` 로 하라. Task 4 정의에는 현행 SKILL.md 의 모든 절을 옮겨라. Task 7 의 readability 글 검토 이전은 생략하라.

### Task 2: 렌즈 출력 계약 파일

**Files:**
- Create: `scripts/lens_contract.json`
- Create: `scripts/test_lens_contract.sh` (이 작업에서는 `[계약]` 묶음만)

**Interfaces:**
- Produces: `lens_contract.json` 의 구조. 키 형식은 `prior_art_contract.json` 을 따른다. 값 `true` 는 요구 키이고, `?` 접두는 선택 키다. `issues` 칸과 `suggestions` 칸은 배열 원소 객체의 키를 적는다.

```json
{ "common": { "lens": true, "read": true, "?target": true,
              "issues": [{ "where": true, "type": true, "claim": true, "file": true, "evidence": true,
                           "counterpart_file": true, "counterpart": true, "principle": true, "consequence": true }],
              "principles_applied": true, "notes": true },
  "agents": { "<에이전트 이름>": { "modes": ["..."], "types": ["..."], "extra": { "<칸>": true }, "omit": ["<최상위 칸>"] } } }
```

`target` 은 review-docs 「기록 파일 이름 규칙」이 대상이 둘일 때 대상 구분에 쓰는 칸이다. 그래서 선택 키로 둔다.

| 에이전트 | modes | types | extra | omit |
|---|---|---|---|---|
| `lens-adversarial` | `design`, `artifact` | failure-mode, over-engineering, irreversible, risk | — | — |
| `lens-adversarial-claim` | `claim` | counter-evidence, weak-premise, alternative-explanation, missing-comparison | — | — |
| `lens-consistency` | `spec`, `plan` | contradiction, gap, drift, scope | — | — |
| `lens-grounding` | `runtime`, `spec`, `doc` | omission, contradiction, unsupported, mismatch | — | — |
| `lens-fit` | `auto` | schema, format, style, constraint, compat | `doc_type` | — |
| `lens-readability` | `render` | — | `purpose`, `suggestions: [{ where, why, screen }]` | `issues` |

모드 이름 `claim`·`auto`·`render` 와 칸 이름 `screen` 은 spec 「구현자에게 맡기는 것」의 칸 배치 위임 범위에서 정한 값이다. `lens-consistency` 의 `duplication`·`narrowed`·`pairs` 는 레포 문서 감사 전용이므로 감사 삭제와 함께 뺐다.

- [ ] **Step 1: 실패하는 테스트를 써라.** `test_lens_contract.sh` 에 `[계약]` 묶음을 만들어라. 머리 주석과 `check`·`json_run` 사용은 `test_prior_art_contract.sh` 를 따르라. 아래 검사를 넣어라.
  - 검사 "계약의 공통 칸이 aggregating-lenses 리뷰 산출물 계약과 같다"는 그 절 코드 블록의 키 집합(issues 하위 포함)과 `common` 의 요구 키 집합이 같은지 본다.
  - 검사 "계약의 렌즈 이름이 아는 이름이다"는 `agents` 의 키가 위 표의 이름과 같은지 본다.
  - 검사 "빼는 칸이 공통 최상위 칸이다"는 `omit` 이 `common` 최상위 키의 부분집합인지 본다.
- [ ] **Step 2: 실패를 확인하라.** `bash scripts/test_lens_contract.sh` 를 실행하고, 계약 파일이 없어 FAIL 이 나는지 확인하라.
- [ ] **Step 3: 계약 파일을 써라.** `scripts/lens_contract.json` 을 위 구조와 표대로 써라.
- [ ] **Step 4: 통과를 확인하라.** 같은 명령의 마지막 줄 계수에서 FAIL 이 0 인지 확인하라.
- [ ] **Step 5: 커밋 승인을 물어라.** 승인되면 `git add scripts/lens_contract.json scripts/test_lens_contract.sh && git commit -m "렌즈 출력 계약을 파일 하나로 둔다"` 를 실행하라.

### Task 3: 호출 정책 검사와 domain-plugin 규칙

**Files:**
- Modify: `scripts/test_lens_contract.sh` (`[호출 정책]` 묶음 추가)
- Modify: `skills/domain-plugin/SKILL.md` (절 「에이전트 호출 정책」 추가)
- Modify: `scripts/test_docs_drift.sh` (그 절의 존재 검사 추가)
- Modify: `docs/superpowers/decisions/2026-10-25-agent-call-policy.md` (가정 확인 결과 추가)

**Interfaces:**
- Produces: 함수 `policy_violations <agents_dir> <workflows_dir>`. 위반마다 `agents:<파일>:<사유>` 나 `workflows:<파일>:<줄>` 한 줄을 출력한다. 위반이 없으면 0, 있으면 1 을 돌려준다. 사유 값은 `no-tools`(tools 줄이 없음), `not-one-line`(`tools:` 뒤 값이 비어 있음), `agent-tool`(목록에 Agent·Task 가 있음)이다.

- [ ] **Step 1: 가정을 확인하라.** `workflow-authoring` 스킬을 Read 하고, agentType 없는 `agent()` 호출이 어떤 에이전트로 실행되는지 찾아라. 찾은 문장과 출처를 결정 기록의 셋째 검사 항목 옆에 적어라. 기본 에이전트가 Agent 도구를 받지 않는다고 적혀 있으면, 셋째 검사를 넣을지 사용자에게 물어라.

- [ ] **Step 2: 실패하는 테스트를 써라.** 아래 검사를 넣어라.
  - 검사 "현행 정의와 워크플로가 호출 정책을 지킨다"는 `policy_violations "$HERE/agents" "$HERE/workflows"` 가 0 을 돌려주는지 본다.
  - 검사 "tools 위반 형식을 모두 잡는다"는 아래 결함 주입 픽스처마다 함수가 1 을 돌려주는지 본다.
  - 검사 "agentType 을 뺀 호출을 잡는다"는 아래 워크플로 픽스처에서 함수가 1 을 돌려주는지 본다.

  tools 픽스처는 `$FX` 에 `agents/` 를 복사해 만든다. 한 정의의 tools 줄 끝에 `, Agent` 를 붙인 픽스처, `, Task` 를 붙인 픽스처, `, Agent(lens-fit)` 를 붙인 픽스처를 만들어라. 이어서 tools 줄을 `tools:` 와 다음 줄 `  - Read` 로 바꾼 픽스처와 tools 줄을 지운 픽스처를 만들어라.

  워크플로 픽스처는 `workflows/prior-art-search.js` 를 복사해 만든다. `agentType:` 키가 있는 첫 호출에서 그 키와 값을 지워라.

- [ ] **Step 3: 실패를 확인하라.** `bash scripts/test_lens_contract.sh` 를 실행하고, 함수가 없어 세 검사가 FAIL 인지 확인하라.

- [ ] **Step 4: `policy_violations` 를 구현하라.** frontmatter 는 첫 `---` 와 둘째 `---` 사이로 읽어라. `^tools:` 줄이 없으면 `no-tools`, 그 줄의 값이 비어 있으면 `not-one-line` 이다. 값을 쉼표로 나눠 괄호 앞 이름이 `Agent` 나 `Task` 인 항목이 있으면 `agent-tool` 이다.

  `agent()` 검사는 `json_run` 의 파이썬으로 하라. 먼저 `//` 주석, `/* */` 주석, 따옴표 문자열, 템플릿 리터럴을 같은 길이의 공백으로 바꿔라. 그다음 식별자 문자가 앞에 붙지 않은 `agent(` 마다 짝이 맞는 닫는 괄호까지 읽어라. 그 안에 `agentType\s*:` 가 없으면 위반이다. 펼친 객체(`...`)로 옵션을 넘긴 호출도 위반으로 보라.

- [ ] **Step 5: 통과를 확인하라.** 같은 명령의 FAIL 이 0 인지 확인하라.

- [ ] **Step 6: domain-plugin 에 절을 써라.** 절 「에이전트 호출 정책」에는 아래 내용을 넣어라.
  - 정책: 사전 정의 호출만 허용한다.
  - 장치: 정의는 Agent 없는 tools 를 둔다.
  - 지시: 플러그인 스킬이 서브에이전트를 실행할 때는 플러그인 정의나 Explore 처럼 Agent 없는 종류를 쓴다.
  - 지시: 워크플로의 `agent()` 는 옵션 객체에 `agentType` 을 직접 적는다.
  - 멈춤 조건: 다른 에이전트를 실행해야 하는 정의가 필요해지면 검사 예외로 대신하지 말고 멈춰 사용자에게 묻는다.
  - 결정 기록 경로.

- [ ] **Step 7: 절 존재 검사를 넣어라.** `test_docs_drift.sh` 에 `check "domain-plugin 이 에이전트 호출 정책을 둔다" "has_sec \"\$HERE/skills/domain-plugin/SKILL.md\" '에이전트 호출 정책'"` 을 넣고, 전체 테스트가 `ALL PASS` 를 내는지 확인하라.

- [ ] **Step 8: 커밋 승인을 물어라.** 승인되면 `git add scripts/test_lens_contract.sh skills/domain-plugin/SKILL.md scripts/test_docs_drift.sh docs/superpowers/decisions/2026-10-25-agent-call-policy.md && git commit -m "에이전트 호출 정책 검사와 domain-plugin 규칙을 추가한다"` 를 실행하라.

### Task 4: 렌즈 에이전트 정의

원칙 경량화 세션이 main 에 병합된 뒤 시작하라. 병합 커밋을 이 브랜치에 받은 뒤, 그 세션이 고친 렌즈 SKILL.md 위에서 정의를 써라.

**Files:**
- Create or overwrite: `agents/lens-adversarial.md`, `agents/lens-adversarial-claim.md`, `agents/lens-consistency.md`, `agents/lens-grounding.md`, `agents/lens-fit.md`, `agents/lens-readability.md`
- Modify: `scripts/test_lens_contract.sh` (`[정의]` 묶음 추가)

**Interfaces:**
- Consumes: Task 1 의 `maxTurns`·`effort`·Playwright 도구 이름, Task 2 의 `lens_contract.json`, Task 7 이 만들 절 이름 「결과를 모으는 법」.
- Produces: 정의 본문의 절 「입력」, 「체크리스트」, 「가드」, 「읽기 범위」, 「출력 예시」. 「출력 예시」에는 ```json 블록을 하나만 둔다.

- [ ] **Step 1: 범위를 알려라.** 원칙 경량화 세션과 선행연구 개선 세션에 Task 4·7·8 의 Files 목록을 메시지로 보내라. 겹치는 줄이 있다는 회신이 오면, 그 줄을 어느 쪽이 먼저 고칠지 사용자에게 물어라.

- [ ] **Step 2: 실패하는 테스트를 써라.** `[정의]` 묶음에서 `lens_contract.json` 의 `agents` 키마다 아래 검사를 만들어라.
  - 검사 "<이름>: 정의 파일과 이름이 같다"는 `agents/<이름>.md` 가 있고 `name: <이름>` 줄이 있는지 본다.
  - 검사 "<이름>: 모델이 opus 다"는 `model: opus` 줄을 본다.
  - 검사 "<이름>: 도구가 spec 표와 같다"는 tools 줄을 spec 「에이전트 구성」 표의 값과 대조한다. 대조값은 이 테스트 안의 연관 배열로 두되, readability 는 Task 1 결정 기록의 도구 이름을 쓴다.
  - 검사 "<이름>: 입력 절이 두 줄의 부재를 다룬다"는 `has_sec` 로 「입력」을 찾고, 그 절에 `MODE`·`PRINCIPLES` 가 모두 있는지 본다.
  - 검사 "<이름>: 출력 예시가 계약과 같다"는 「출력 예시」 절의 첫 ```json 블록을 파싱해 대조한다.
  - 검사 "lens-readability: 도구 부재 처리를 적는다"는 정의에 `브라우저 도구 없음` 이 있는지 본다.
  - 검사 "예시에 계약 밖 칸이 있으면 잡는다"는 결함 주입이다. `$FX` 에 정의 하나를 복사하고 예시에 `"severity": ""` 를 넣은 픽스처에서 대조가 실패해야 한다.

  출력 예시 대조의 기준 집합은 층마다 따로 계산하라. 최상위 기준은 `common` 최상위 키에서 `omit` 을 빼고 `extra` 최상위 키를 더한 집합이다. 배열 원소 기준은 `issues`(남아 있을 때)나 `extra` 의 배열 칸에 적힌 원소 키 집합이다. `?` 키는 있어도 없어도 통과다. `lens` 값이 이름과 같은지와 `issues[].type` 값이 `types` 안에 있는지도 함께 보라.

- [ ] **Step 3: 실패를 확인하라.** `bash scripts/test_lens_contract.sh` 를 실행하고, 시험용 정의 때문에 `[정의]` 검사가 FAIL 인지 확인하라.

- [ ] **Step 4: 공통 내용을 정의마다 써라.** 현행 SKILL.md 의 절을 옮겨라. 예외는 「기계에 넘기는 것」과 「레퍼런스 프롬프트」다. 「기계에 넘기는 것」은 Task 7 이 `dispatching-lenses` 표로 옮긴다. 「레퍼런스 프롬프트」의 지시는 본문 첫머리의 역할 문장으로 써라. 계약 소유자 포인터는 `dispatching-lenses` 「결과를 모으는 법」과 `scripts/lens_contract.json` 을 가리키게 써라. 「입력」에는 MODE 가 없으면 대상에서 모드를 정해 `notes` 에 적고, PRINCIPLES 가 없으면 `principles_applied` 를 비우고 `notes` 에 적으라는 지시를 넣어라.

- [ ] **Step 5: 정의별 내용을 써라.** 각 정의에 아래를 넣어라.
  - `lens-adversarial`: spec 「새 체크리스트」의 `artifact` 모드. 지적 위치는 파일:줄이나 실험 결과 항목이고, 입력은 데이터나 테스트 출력 경로다.
  - `lens-adversarial-claim`: 네 축, 세 가드(출처 없는 반박은 `notes`, `kofia.or.kr` 접속 금지, 검색어 일반화), spec 「출력 계약」의 칸 배치 표.
  - `lens-consistency`, `lens-grounding`, `lens-fit`: 감사 모드와 감사 문장을 뺀 내용.
  - `lens-readability`: 「목적 주입」, 「관찰 목록」의 시각 항목, 지적마다 `screen` 칸, 브라우저 도구가 없으면 `notes` 에 "브라우저 도구 없음"을 적고 끝내라는 지시.

  대체 분기이면 `lens-readability` 는 Task 1 의 "readability 대체 분기"대로 써라.

- [ ] **Step 6: 통과를 확인하라.** `bash scripts/test_lens_contract.sh` 의 FAIL 이 0 이고 `claude plugin validate ./` 가 `Validation passed` 를 내는지 확인하라.

- [ ] **Step 7: 커밋 승인을 물어라.** 승인되면 `git add agents/lens-*.md scripts/test_lens_contract.sh && git commit -m "렌즈를 에이전트 정의로 옮긴다"` 를 실행하라.

### Task 5: 채택 비교

**Files:**
- Modify: `docs/superpowers/decisions/2026-10-25-lens-agent-runtime.md` (「채택 비교」 절 추가)

- [ ] **Step 1: 첫 기준 본문을 꺼내라.** `git show 2498384:docs/superpowers/specs/2026-10-09-nested-orchestration-large-dev-design.md` 에서 「2026-10-11 개정 — 메시지 형식」 절을 꺼내 `<scratchpad>/base1.md` 에 저장하라.

- [ ] **Step 2: 첫 기준의 반영 지적을 정하라.** 기준 지적은 `docs/superpowers/reviews/2026-10-11-message-schema-review/` 의 렌즈 결과 네 파일이다. 리뷰 뒤 첫 반영 커밋의 diff 와 지적마다 대조해 반영 여부를 표로 만들어라. fit 의 `style` 지적은 빼라.

- [ ] **Step 3: 둘째 기준을 골라라.** `docs/superpowers/reviews/` 에서 렌즈 결과 JSON 이 있고 리뷰 직전 커밋을 `git log` 로 찾을 수 있는 spec 리뷰 기록을 골라라. 고른 기록과 커밋을 결정 기록에 적고, Step 1·2 와 같은 준비를 하라.

- [ ] **Step 4: 기준 사용량을 읽어라.** 조사 기록의 실측 방법을 쓰라. 그 차수 세션 기록의 task-notification 에서 렌즈별 `subagent_tokens`·`duration_ms` 를 읽어 결정 기록에 적어라.

- [ ] **Step 5: 새 에이전트를 실행하라.** 대상마다 `lens-grounding`(MODE: spec), `lens-consistency`(MODE: spec), `lens-adversarial`(MODE: design), `lens-fit`(MODE: auto)을 Agent 도구로 한 번씩 실행하라. 프롬프트 형식은 전역 제약을 따르고, 대상 경로는 `<scratchpad>/base1.md` 와 둘째 기준이다. 사용량은 task-notification 의 `subagent_tokens`·`duration_ms` 에서 읽어라.

- [ ] **Step 6: 판정을 적어라.** spec 「채택 조건」 표의 세 축으로 판정하고, 수치와 대조 표를 결정 기록에 적어라. 한 축이라도 나빠지면 그 수치를 보이고 사용자에게 물어라.

- [ ] **Step 7: 커밋 승인을 물어라.** 승인되면 `git add docs/superpowers/decisions/2026-10-25-lens-agent-runtime.md && git commit -m "렌즈 에이전트 채택 비교 결과를 기록한다"` 를 실행하라.

### Task 6: 주장 반박 에이전트 시험

**Files:**
- Modify: `docs/superpowers/decisions/2026-10-25-lens-agent-runtime.md` (「주장 반박 시험」 절 추가)

- [ ] **Step 1: 대상을 찾아라.** `D:\test\` 에서 2026-10-05 국고채 10년-3년 커브 플랫 주장 보고서를 찾아라. 후보가 둘 이상이면 사용자에게 물어라.

- [ ] **Step 2: 실행하라.** Agent 도구로 `disciplined-coder:lens-adversarial-claim` 을 한 번 실행하라. 프롬프트 첫 줄은 `MODE: claim`, 둘째 줄은 `PRINCIPLES: <저장소>/agent-principles.md`, 셋째 줄은 보고서 경로다.

- [ ] **Step 3: 인용을 확인하라.** 메인 세션은 지적마다 `counterpart_file` URL 을 WebFetch 로 열고, `counterpart` 구절이 원문에 있는지 확인하라. `kofia.or.kr` 주소는 열지 말고 인용 확인 실패로 둬라. 메인 세션은 인용 확인에 실패한 지적을 사용자에게 보이지 말고 결정 기록에만 적어라.

- [ ] **Step 4: 가드를 확인하라.** 서브에이전트 기록(`~/.claude/projects/<프로젝트>/<세션>/subagents/agent-<id>.jsonl`)에서 WebSearch 검색어와 WebFetch URL 을 뽑아라. 보고서 문장이나 수치가 그대로 든 검색어와 `kofia.or.kr` 요청을 세어라.

- [ ] **Step 5: 기록하고 판정받아라.** 인용 확인 실패 건수와 전체 지적 수, 가드 위반 건수, 토큰·시간을 결정 기록에 적어라. 통과한 지적을 사용자에게 보여 판정받아라. 같은 답에서 실패 건수와 전체 건수를 보이고, 검증자 재사용을 다시 검토할지 물어라.

- [ ] **Step 6: 커밋 승인을 물어라.** 승인되면 `git add docs/superpowers/decisions/2026-10-25-lens-agent-runtime.md && git commit -m "주장 반박 에이전트 시험 결과를 기록한다"` 를 실행하라.

### Task 7: 호출 스킬 수정

**Files:**
- Modify: `skills/dispatching-lenses/SKILL.md`, `skills/review-specs/SKILL.md`, `skills/review-docs/SKILL.md`, `skills/review-llm-calls/SKILL.md`
- Modify: `scripts/test_docs_drift.sh` (가리키는 절이 바뀐 검사)

**Interfaces:**
- Consumes: Task 4 정의의 절 이름, Task 2 계약 파일.
- Produces: `dispatching-lenses` 의 절 「결과를 모으는 법」과 「렌즈 그룹」 표. 표의 열은 에이전트, 대상과 모드, tools, 그룹, 실행하는 호출자, 기계에 넘기는 것이다. `review-docs` 「마크다운 초안과 퇴고」 아래에는 참고 절을 둔다.

- [ ] **Step 1: 「렌즈 그룹」 표를 바꿔라.** spec 처분 표의 `dispatching-lenses` 행대로 표를 대상별 에이전트 표로 바꿔라. 절 제목은 유지하라.

- [ ] **Step 2: 「결과를 모으는 법」을 써라.** aggregating-lenses 에서 아래 내용을 이 절로 옮겨라.
  - 「하는 일」과 「판단 재귀 회피」.
  - 「처분」(워크플로 처분 문단 포함).
  - 메인 세션 집계 방법(100행).
  - 「출력 스키마」의 집계 항목과 `source` 규칙.
  - 「리뷰 산출물 계약」의 산문 규칙(상대편이 없으면 발견이 아님, `consequence` 는 현재 상태, 등급 라벨 금지, `principles_applied` 요구 조건, 줄 번호 금지, `where` 의 뜻, `read` 가 비었을 때 처리).
  - 「공통 계약의 예외」의 집계 제외 규칙과, 「렌즈가 추가하는 칸」의 `purpose` 원본 확인 규칙.

  옮긴 위치는 내 판단이다. spec 은 계약을 계약 파일로 옮기라고만 정했고, 산문 규칙은 JSON 에 넣을 수 없다.

- [ ] **Step 3: 묶기 예외를 지워라.** 「따로 실행할 때와 묶을 때」에서 「한 호출에 묶기(예외)」와 읽기 비용 문단을 지우고 "렌즈 하나가 서브에이전트 하나다"를 "에이전트 호출 하나가 렌즈 하나다"로 고쳐라. 절 제목을 바꾸면 `grep -rn "따로 실행할 때와 묶을 때" skills/ scripts/ docs/*.md` 결과의 줄을 모두 새 제목으로 고쳐라.

- [ ] **Step 4: 인용 확인 절차를 적어라.** `dispatching-lenses` 「결과를 모으는 법」에 `lens-adversarial-claim` 결과의 인용 확인 절차를 넣어라. 내용은 spec 「새 체크리스트」의 인용 확인 문단이다.

- [ ] **Step 5: review-specs 를 고쳐라.** spec 처분 표의 호출자×렌즈 정의 행과 리뷰 기록 규칙 행대로 고쳐라. 선행연구 관련 줄과 「`prior-art` 기록에 적을 것」은 그대로 둬라.

- [ ] **Step 6: review-docs 를 고쳐라.** 아래를 고쳐라.
  - 7행의 렌즈 목록이 「렌즈 그룹」 표를 가리키게 고쳐라.
  - 39행을 spec 「readability 글 검토의 이전」의 문장으로 고쳐라.
  - 「마크다운 초안과 퇴고」 아래 참고 절에 현행 readability 의 글 항목, 「고칠 순서」, 「고치는 범위」, 「손대지 않는 요소」를 옮겨라.
  - 「기록 파일 이름 규칙」 94~96행의 "스킬 디렉터리 이름"을 "에이전트 이름"으로 고치고, 절 제목은 유지하라.
  - 검진 전 제안 목록에 "제안서·보고서를 검진할 때 `lens-adversarial-claim` 을 제안하고 승인받는다"를 넣어라.
  - 감사 언급을 지워라.

- [ ] **Step 7: review-llm-calls 를 고쳐라.** spec 처분 표의 `review-llm-calls` 행대로 고쳐라. aggregating-lenses 의 런타임 전용 결정과 재시도(63·69-73·99·101행)도 이 스킬로 옮겨라.

- [ ] **Step 8: 테스트를 맞춰라.** `test_docs_drift.sh` 에서 옮긴 절을 가리키던 검사의 대상 파일과 절 이름을 새 위치로 바꿔라. 284·872행은 렌즈 목록이 아니라 호출자 목록이므로 그대로 둬라(내 판단, plan 리뷰 지적 29).

- [ ] **Step 9: 확인하라.** 전체 테스트가 `ALL PASS` 를 내는지 확인하라. 이어서 `grep -n "렌즈 그룹" skills/nested-orchestration/SKILL.md skills/nested-orchestration/references/sub-session-protocol.md skills/review-docs/SKILL.md` 로 「렌즈 그룹」 제목을 가리키는 줄이 남아 있는지 확인하라. `grep -n "^## 기록 파일 이름 규칙" skills/review-docs/SKILL.md` 와 `grep -n "^## 렌즈에게 에이전트원칙을 알리는 법" skills/dispatching-lenses/SKILL.md` 가 각각 한 줄을 내는지도 확인하라.

- [ ] **Step 10: 커밋 승인을 물어라.** 승인되면 `git add skills/dispatching-lenses/SKILL.md skills/review-specs/SKILL.md skills/review-docs/SKILL.md skills/review-llm-calls/SKILL.md scripts/test_docs_drift.sh && git commit -m "호출 스킬이 렌즈 에이전트를 실행하게 고친다"` 를 실행하라. 이 커밋은 Task 8 삭제의 되돌림 지점이므로 커밋하지 않으면 Task 8 을 시작하지 마라.

### Task 8: 스킬 삭제와 1:1 전제 정리

테스트를 줄이는 작업이므로 결함 주입으로 검출력을 확인한다.

**Files:**
- Delete: `skills/lens-*/`, `skills/aggregating-lenses/`, `skills/audit-repo-docs/`, `scripts/_audit_common.sh`, `scripts/audit_*.sh`, `scripts/test_audit.sh`
- Modify: spec 「1:1 전제 목록」의 위치, spec 처분 표 「감사를 가리키는 파일」 행의 파일, `scripts/scaffold.sh:231`, `scripts/_test_check.sh:3`
- Modify: `scripts/test_docs_drift.sh` (199-207행과 233-275행 삭제)
- Modify: `scripts/test_lens_contract.sh` (aggregating-lenses 대조 검사 삭제)

- [ ] **Step 1: 대조표를 만들어라.** `test_docs_drift.sh` 199-207행과 233-275행의 검사마다, 그 검사가 지키던 성질과 `test_lens_contract.sh` 의 대응 검사를 표로 만들어라. 대응이 없는 성질은 `test_lens_contract.sh` 에 검사로 먼저 넣어라. 표는 결정 기록에 붙여라.

- [ ] **Step 2: 옮긴 검사의 검출력을 확인하라.** 대조표의 행마다 결함 하나를 주입하라. 예를 들어 정의의 `lens` 값을 다른 이름으로 바꾸고, readability 예시에 `issues` 를 넣고, 정의의 계약 소유자 포인터를 지워라. 주입마다 `test_lens_contract.sh` 가 실패하는지 확인하고 되돌려라.

- [ ] **Step 3: 파일을 지워라.** Delete 목록을 `git rm -r` 로 지워라.

- [ ] **Step 4: 계약 대조 검사를 지워라.** `test_lens_contract.sh` 의 검사 "계약의 공통 칸이 aggregating-lenses 리뷰 산출물 계약과 같다"를 지워라. 이제 계약 파일이 출처다.

- [ ] **Step 5: 전제를 고쳐라.** 「1:1 전제 목록」의 행마다 박힌 전제를 에이전트 정의 기준으로 고쳐라. 감사 언급 파일과 `scaffold.sh:231`, `_test_check.sh:3` 의 감사 언급도 고쳐라. `test_docs_drift.sh` 의 해당 구간도 지워라.

- [ ] **Step 6: 남은 참조를 확인하라.** 아래 명령의 출력이 비어 있는지 확인하라.

```bash
grep -rn "skills/lens-\|lens-readability 폴더\|aggregating-lenses\|audit-repo-docs\|audit_" . --include=*.md --include=*.sh --include=*.py --include=*.json --include=*.js | grep -v "docs/superpowers/\(reviews\|specs\|plans\|decisions\)/"
```

- [ ] **Step 7: 핵심 계약의 결함 주입을 하라.** 저장소 CLAUDE.md 가 정한 결함(리뷰 기록을 보존 태그 없이 지우기, 대체된 spec 의 superseded 표시 지우기, settings.json 사본 만들기 없애기, 읽기 전용 차단 훅 무력화)을 하나씩 넣어라. 결함마다 전체 테스트가 `FAILED:` 를 내는지 확인하고 되돌려라.

- [ ] **Step 8: 확인하라.** 전체 테스트가 `ALL PASS` 를 내고 `claude plugin validate ./` 가 `Validation passed` 를 내는지 확인하라.

- [ ] **Step 9: 커밋 승인을 물어라.** 승인되면 `git add -A skills scripts hooks docs/domain-korean.md docs/superpowers/decisions && git commit -m "렌즈 스킬과 레포 문서 감사를 지운다"` 를 실행하라.

### Task 9: fit 문체 기계화

**Files:**
- Modify: `hooks/_doc_form_check.py`, `scripts/test_doc_form.sh`, `agents/lens-fit.md`
- Modify: `docs/superpowers/decisions/2026-10-25-lens-agent-runtime.md` (「fit 기계화」 절 추가)

- [ ] **Step 1: 후보를 골라 기록하라.** 조사 기록의 fit 조항별 집계에서 정규식이나 문장 수 계산으로 판정할 수 있는 조항을 골라라. 원칙 경량화 세션이 지운 조항은 빼라. 고른 조항과 판정 규칙을 결정 기록에 적어라.

- [ ] **Step 2: 항목마다 실패하는 테스트를 써라.** `test_doc_form.sh` 에 항목마다 검사 두 개를 넣어라. 검사 "<조항 ID>: 위반 예문에 경고한다"는 위반 예문을 넣은 .md 픽스처에서 검사기 출력에 `<조항 ID>` 경고 이름이 나오는지 본다. 검사 "<조항 ID>: 통과 예문에 조용하다"는 통과 예문 픽스처에서 그 이름이 나오지 않는지 본다.

- [ ] **Step 3: 실패를 확인하라.** `bash scripts/test_doc_form.sh` 를 실행하고 새 검사가 FAIL 인지 확인하라.

- [ ] **Step 4: 검사기에 항목을 넣어라.** 기존 라벨 불릿·개수 예고 검사와 같은 함수 형태로 넣어라.

- [ ] **Step 5: 오탐을 세라.** 항목마다 저장소 `docs/` 의 .md 전체에 검사기를 실행하고, 경고마다 실제 위반인지 확인하라. 오탐이 한 건이라도 있는 항목은 되돌려라. 남긴 항목과 오탐 수를 결정 기록에 적어라.

- [ ] **Step 6: lens-fit 에 조건부 제외를 적어라.** 문구는 "대상이 .md 이고 형식 경고 검사를 거친 파일이면, 그 검사기가 본 항목은 다시 지적하지 마라"다. .html·.pptx·런타임 출력과 경고를 거치지 않은 파일은 lens-fit 이 그대로 본다고 함께 적어라.

- [ ] **Step 7: 테스트를 확인하라.** `test_doc_form.sh`·`test_hooks.sh`·`test_lens_contract.sh` 가 FAIL=0 인지 확인하라.

- [ ] **Step 8: 효과를 측정하라.** `lens-fit` 을 이 plan 의 spec 에 한 번 실행하라. 지적 중 `style` 비율을 결정 기록에 적어라. 비율이 조사 기록의 약 85% 보다 줄지 않았으면 수치를 보이고 사용자에게 처리를 물어라.

- [ ] **Step 9: 커밋 승인을 물어라.** 승인되면 `git add hooks/_doc_form_check.py scripts/test_doc_form.sh agents/lens-fit.md docs/superpowers/decisions/2026-10-25-lens-agent-runtime.md && git commit -m "fit 문체 항목 일부를 형식 검사기로 옮긴다"` 를 실행하라.

### Task 10: 다시 리뷰 정책 클린룸 시험

**Files:**
- Create: `evals/principles/clauses/NO-RAW-OUTPUT-rereview/current.md`, `new.md`, `ids`
- Create: `evals/principles/cases/` 아래 새 질문 짝
- Modify: `docs/domain-discipline.md` (`NO-RAW-OUTPUT` 절)
- Modify (채택 시): `agent-principles.md`, `skills/review-specs/SKILL.md` 「작업 순서와 다시 리뷰」

- [ ] **Step 1: 시험 단위를 만들어라.** `ids` 파일에는 `NO-RAW-OUTPUT` 한 줄을 적어라. `current.md` 에는 현행 문구를, `new.md` 에는 spec 「다시 리뷰 정책」의 변경안 문장을 그대로 적어라. 형식은 `evals/principles/clauses/NO-RAW-OUTPUT/` 를 따르라.

- [ ] **Step 2: 질문을 채워라.** 저장소 CLAUDE.md 「조항 추가와 문구 변경」대로 기존 개발용 과제에 `should`·`should-not` 짝을 추가하라. 합계가 3개 미만이면 3개로 채워라.

- [ ] **Step 3: 실행하라.** `bash scripts/eval_clause.sh NO-RAW-OUTPUT-rereview` 를 실행하라.

- [ ] **Step 4: 판정하라.** `bash scripts/eval_clause_report.sh NO-RAW-OUTPUT-rereview` 를 실행하고 CLAUDE.md 의 채택 규칙으로 판정하라. 결과가 엇갈릴 때만 사용자에게 물어라.

- [ ] **Step 5: 기록하고 반영하라.** 결과를 `docs/domain-discipline.md` 의 `NO-RAW-OUTPUT` 절에 적어라. 채택이면 `agent-principles.md` 와 `review-specs` 를 같은 뜻으로 고치고, 전체 테스트가 `ALL PASS` 를 내는지 확인하라.

- [ ] **Step 6: 커밋 승인을 물어라.** 승인되면 `git add evals docs/domain-discipline.md agent-principles.md skills/review-specs/SKILL.md && git commit -m "다시 리뷰 정책 문구를 클린룸 시험한다"` 를 실행하라.

<!-- spec-review: passed -->
