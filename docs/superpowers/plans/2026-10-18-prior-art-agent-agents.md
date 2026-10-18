# 선행연구 에이전트 agents 워크스트림 Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** 구현자는 오케스트레이터 스킬 `agent-prior-art`, 연구자·검증자 정의, 발동 넛지를 만들고, `lens-prior-art`를 전제로 한 문장을 모두 처리한 뒤 옛 렌즈를 지운다. 발동 넛지는 사용자 메시지가 선행연구를 요청하면 `agent-prior-art`를 열라고 알리는 UserPromptSubmit 훅이며 차단하지 않는다.

**Architecture:** 이 저장소의 산출물은 마크다운 스킬·에이전트 정의와 bash 훅이며, 계약은 `scripts/test_*.sh`의 `check` 단언이 지킨다. 태스크 경계는 하부 명세 「구현 순서의 제약」을 따르므로 커밋마다 저장소 전체 검사가 `ALL PASS`다.

**Tech Stack:** bash(Git Bash 포함), 파이썬(`scripts/_json_valid.sh`의 `json_run`), 마크다운, Claude Code 플러그인 구성(`agents/`, `skills/`, `hooks/hooks.json`).

**Spec:** 하부 명세는 `docs/superpowers/specs/2026-10-18-prior-art-agent-specagents-design.md`이고, 큰 명세는 `docs/superpowers/specs/2026-10-18-prior-art-agent-design.md`다. 큰 명세에서는 「출력 스키마」「공유 결정」「경계」「다시 나눈 분할」「결정 기록」을 함께 따른다. 둘이 다르면 큰 명세의 계약 표와 계약 코드 `scripts/prior_art_contract.json`을 따른다. 아래 태스크의 '하부 명세'와 '큰 명세'는 모두 이 두 파일을 가리킨다.

## Global Constraints

- **작업 위치** — 모든 명령은 워크트리 `D:\projects\Structure\disciplined-coder\.claude\worktrees\ws-prior-art-agent-agents`(Git Bash 경로 `/d/projects/Structure/disciplined-coder/.claude/worktrees/ws-prior-art-agent-agents`)에서 실행한다.
- **수정 허용 경로** — 구현자는 큰 명세 「다시 나눈 분할」 「수정 허용 경로」의 `agents` 행에 든 파일만 고친다. 하부 명세·큰 명세·`scripts/prior_art_contract.json`·`scripts/test_prior_art_contract.sh`를 고쳐야 하면 고치지 않고, 구현자를 실행한 서브 세션(이하 컨트롤러)에게 알린다.
- **커밋마다 전체 검사** — 커밋 직전에 CLAUDE.md 「변경 뒤 실행」의 한 줄 명령을 실행해 `ALL PASS`를 확인한다. 이 브랜치에는 `workflows/`가 없으므로 계약 테스트의 `SKIP: workflow` 줄은 정상이다.
- **실패 확인 명령** — 새 단언이나 바꾼 단언이 구현 전에 실패하는지는 그 단언이 든 묶음에 대해 `bash <스크립트> 2>&1 | awk -v h='<묶음 머리>' '$0==h{f=1;next} /^\[/{f=0} f' | grep '^  FAIL:'`로 실패 줄을 뽑아 확인한다. 줄 수 창(`grep -A<n>`)은 쓰지 않는다.
- **새 .md 등록** — 새 `.md`를 만들면 검사를 실행하기 전에 `git add`한다. `scripts/audit_targets.sh`가 `git ls-files`로 감사 대상을 도출하기 때문이다.
- **문서 대조 방식** — 단언은 `scripts/_test_check.sh`의 `check`로 쓴다. 문서는 `scripts/_doc_keys.sh`의 `has_sec`·`sec_has`·`owns_sec`·`points_to`·`doc_sec`로 절 제목·포인터·소유 선언을 대조하고, 문장 전체를 단언에 박지 않는다.
- **기존 문서 검사** — 새 문서와 고친 문서는 기존 묶음 「첫 문장」, 「대구 한도」, 「소유 표」를 통과해야 한다. 「첫 문장」은 모든 `##`·`###` 절의 첫 줄이 산문인지 본다. 「대구 한도」는 `가 아니라`·`이 아니라`가 글 한 편에 한 번까지인지 보며, 스킬의 「레퍼런스 프롬프트」 절과 백틱 안은 세지 않는다. 에이전트 정의의 본문은 이 예외를 받지 않는다. 「소유 표」는 「X」를 담은 줄이 X 소유자의 이름도 담는지 본다.
- **옛 이름** — `skills/agent-prior-art/SKILL.md` 본문에 `lens-prior-art`와 `lens-derived`를 쓰지 않는다. 옛 이름은 `description:` 줄에만 둔다.
- **문체** — 문서는 한국어 문어체로 쓴다. 구현자는 에이전트원칙 `<워크트리>\agent-principles.md`와 `<워크트리>\docs\domain-korean.md`를 먼저 읽는다. 금지 낱말 검사는 하지 않는다(사용자 결정).
- **선행연구 금지** — 구현자는 선행연구와 웹 탐색을 실행하지 않는다. 이 개발이 병합되기 전에는 선행연구 에이전트가 없다.
- **커밋 메시지** — 한국어 한 줄 요약 뒤에 꼬리줄 `Co-Authored-By: Claude Opus 5.5 (1M context) <noreply@anthropic.com>`을 둔다. 태스크의 커밋 블록이 그 형태를 따른다. push 와 병합은 하지 않는다.

## Review Focus

- **이스케이프된 따옴표가 든 사용자 메시지** — 훅 입력에서 주제어 앞에 `\"`가 있어도 넛지가 떠야 한다. Task 5 의 알림 단언에 든 `\"이 방법\"의 선행연구를 찾아 줘` 픽스처가 이 조건을 고정한다.
- **`prompt` 키가 없는 입력과 값이 빈 입력** — 넛지는 아무것도 내지 않고 종료 코드 0 으로 끝나야 한다. Task 5 의 `{}`·빈 표준 입력·`"prompt":""` 단언이 이 조건을 고정한다.
- **오류로 끝나는 훅** — 알림 조건에 맞지 않는 메시지에서도 훅은 0 으로 끝나야 한다. Claude Code 가 UserPromptSubmit 훅의 오류를 메시지마다 보이기 때문이다. Task 5 의 침묵 단언과 끄기 단언이 출력과 종료 코드를 함께 본다.
- **스킬과 정의의 출력 형식 블록이 갈라지는 상황** — 계약 테스트는 정의만 보므로 스킬 쪽 블록이 낡아도 실패하지 않는다. 구현자는 Task 6 Step 3 에서 자료 이름마다 블록을 글자로 비교한다.
- **「발동과 기록」을 가리키며 소유자 이름을 빠뜨린 줄** — 소유 선언을 둔 뒤 다른 문서가 같은 줄에 `agent-prior-art` 없이 「발동과 기록」만 적으면 기존 「소유 표」 묶음이 실패한다. 줄을 약 100자에서 바꾸는 `docs/domain-discipline.md`가 가장 걸리기 쉽다. 커밋마다 실행하는 전체 검사가 이 조건을 본다.

## File Structure

| 파일 | 할 일 | 태스크 |
|---|---|---|
| `skills/agent-prior-art/SKILL.md` | 새로 만든다 | Task 1 |
| `agents/prior-art-researcher.md` | 새로 만든다 | Task 1 |
| `agents/prior-art-verifier.md` | 새로 만든다 | Task 1 |
| `skills/domain-plugin/SKILL.md` | frontmatter·이름 부류·컴포넌트 위치에 에이전트 정의와 `agent-`·`workflows/`를 추가한다 | Task 1 |
| `skills/review-specs/SKILL.md` | 첫 포인터(23·41·63·64행)를 Task 1 에서 만들고, 나머지 참조를 Task 3 에서 처리한다 | Task 1, Task 3 |
| `scripts/test_docs_drift.sh` | 묶음 `[선행연구 에이전트]`와 frontmatter 순회 대상을 추가하고 226·846-849행을 바꾼다 | Task 1, Task 3, Task 4 |
| `skills/lens-prior-art/` | 옮긴 문장을 대조한 뒤 디렉터리를 지운다 | Task 2 |
| `skills/aggregating-lenses/SKILL.md`, `skills/dispatching-lenses/SKILL.md`, `skills/lens-fit/SKILL.md`, `scripts/test_audit.sh` | 옛 렌즈의 열거·칸·문장·주석을 지운다 | Task 2 |
| `skills/review-docs/SKILL.md` | 선행연구 문장과 원본 파일 이름 규칙을 고친다 | Task 3 |
| `skills/nested-orchestration/references/sub-session-protocol.md`, `skills/nested-orchestration/SKILL.md`, `skills/audit-repo-docs/SKILL.md` | 선행연구 에이전트 문장을 추가하거나 바꾼다 | Task 3 |
| `agent-principles.md`, `docs/domain-discipline.md` | 예시 괄호를 지우고 삭제 사실을 적는다 | Task 4 |
| `hooks/prior_art_nudge_userpromptsubmit.sh`, `hooks/hooks.json`, `README.md`, `scripts/test_hooks.sh` | 발동 넛지와 그 연결·문서·검사를 만든다 | Task 5 |

---

### Task 1: 오케스트레이터 스킬과 두 에이전트 정의

**Files:**
- Create: `skills/agent-prior-art/SKILL.md`, `agents/prior-art-researcher.md`, `agents/prior-art-verifier.md`
- Modify: `skills/review-specs/SKILL.md:23,41,63-64`, `skills/domain-plugin/SKILL.md:14,16,17`, `scripts/test_docs_drift.sh`(「frontmatter 안전」 순회 609행 부근, 새 묶음은 파일 끝 요약 줄 앞)

**Interfaces:**
- Consumes: 하부 명세, 큰 명세, 계약 코드 `scripts/prior_art_contract.json`의 `researcher`·`synthesis`·`verifier`·`map`, 옛 렌즈 원문 `git show 7a2d26d:skills/lens-prior-art/SKILL.md`.
- Produces: 스킬 절 제목 「오케스트레이터 절차」「발동과 기록」「상황별 전략」「실행할 때 지킬 상한」「판정 규약」「출력 스키마」「인용 확인」「레퍼런스 프롬프트」. 뒤 태스크의 포인터가 이 이름을 쓴다. 등록 이름은 `disciplined-coder:prior-art-researcher`와 `disciplined-coder:prior-art-verifier`다. `scripts/test_docs_drift.sh`의 변수 `AP`(스킬 경로)도 이 태스크가 만든다.

- [ ] **Step 1: 묶음 `[선행연구 에이전트]`의 실패하는 단언을 쓴다**

`scripts/test_docs_drift.sh` 끝의 `echo "----"` 앞에 아래 묶음을 둔다. 근거 문서의 삭제 표시 단언은 Task 4 가 추가한다. 도구와 턴 단언은 frontmatter 만 잘라 본다.

```bash
echo "[선행연구 에이전트]"
AP="$HERE/skills/agent-prior-art/SKILL.md"
RDEF="$HERE/agents/prior-art-researcher.md"
VDEF="$HERE/agents/prior-art-verifier.md"
fm() { awk 'NR==1&&/^---$/{f=1;next} f&&/^---$/{exit} f' "$1" 2>/dev/null; }
for s in '오케스트레이터 절차' '발동과 기록' '상황별 전략' '실행할 때 지킬 상한' '판정 규약' '출력 스키마' '인용 확인' '레퍼런스 프롬프트'; do
  check "agent-prior-art 에 절이 있다: $s" "has_sec \"\$AP\" '$s'"
done
check "spec 리뷰가 발동과 기록을 가리킨다" "points_to \"\$CALLER\" '\`agent-prior-art\`' '「발동과 기록」'"
check "연구자 정의의 도구가 구성과 같다" "grep -qx 'tools: WebSearch, WebFetch, Read, Grep, Glob' <<<\"\$(fm \"\$RDEF\")\""
check "검증자 정의의 도구가 구성과 같다" "grep -qx 'tools: WebFetch, Read' <<<\"\$(fm \"\$VDEF\")\""
check "두 정의의 턴 상한이 20 이다" "grep -qx 'maxTurns: 20' <<<\"\$(fm \"\$RDEF\")\" && grep -qx 'maxTurns: 20' <<<\"\$(fm \"\$VDEF\")\""
RP="$( [ -f "$AP" ] && doc_sec "$AP" '레퍼런스 프롬프트' | grep -m1 '^- system: "' | sed 's/^- system: "//; s/"$//' || true)"
check "연구자 정의가 레퍼런스 프롬프트 본문을 그대로 싣는다" "[ -n \"\$RP\" ] && grep -qF -- \"\$RP\" \"\$RDEF\""
```

같은 파일 「frontmatter 안전」 묶음의 순회 `for f in "$HERE"/skills/*/SKILL.md "$HERE"/commands/*.md`에 `"$HERE"/agents/*.md`를 추가한다. 그 순회는 `[ -f "$f" ] || continue`로 빈 glob 을 건너뛴다.

- [ ] **Step 2: 묶음이 실패하는지 확인한다**

Run: `bash scripts/test_docs_drift.sh 2>&1 | awk -v h='[선행연구 에이전트]' '$0==h{f=1;next} /^\[/{f=0} f' | grep '^  FAIL:'`
Expected: 묶음의 모든 단언이 `  FAIL:` 줄로 나온다. 절 단언은 스킬이 없어서, 포인터 단언은 `review-specs`가 아직 가리키지 않아서, 나머지는 정의가 없어서 실패한다.

- [ ] **Step 3: 스킬 `skills/agent-prior-art/SKILL.md`를 쓴다**

frontmatter 의 `name:`은 `agent-prior-art`다. `description:` 값은 하부 명세 「스킬의 frontmatter」 인용 블록의 초안을 한 줄 그대로 옮긴다. 제목 줄은 `# agent-prior-art — 선행연구 에이전트`이고, 그 아래에 이 스킬이 하는 일을 산문 한두 문장으로 적는다. 그다음 Step 1 의 `for s in` 목록에 든 절 이름을 그 순서대로 `##` 절로 둔다.

절마다 무엇을 옮기고 무엇을 다르게 적는지는 하부 명세 「스킬의 절과 옮길 원본」 표와, 그 표가 가리키는 절(「절차의 연결」「발동과 기록의 소유와 주제어」「판정 규약을 옮기는 규칙」「출력 스키마를 옮기는 규칙」「레퍼런스 프롬프트의 요건」)이 정한다. 그 표 위 문단의 규칙도 따른다. 리서치 근거, 리뷰 경위, "빌더는 …" 지시는 옮기지 않고, 값의 출처가 사용자 결정이나 외부 자료이면 그 사실을 한 문장으로 남긴다. 아래 문단들은 그 절들이 구현자에게 남긴 선택을 정한다.

「오케스트레이터 절차」에서는 큰 명세 「원본 파일 규칙」의 표를 싣지 않고, "`review-docs`의 「기록 파일 이름 규칙」"을 가리키는 문장으로 대신한다. 반환값을 읽는 규칙은 큰 명세 계약 표의 `result` 행에서 옮긴다. 실패한 연구자와 검증자는 `output: null`이다. 탈락·판정 불가의 사유는 같은 `ref`의 `verifiers[].output.judgments[]`에 있다. 검증 실패의 사유는 같은 `url`의 `verifiers[].output`에 있다. `synthesis: null`의 두 사정은 `passed`에 `#case#` 항목이 있는지로 구별한다. 다른 spec 의 절 이름(`specworkflow` 「…」)은 스킬에 쓰지 않고, 번호 목록 단계 앞에 산문 첫 줄을 둔다.

「발동과 기록」의 첫 문단에는 "이 규칙은 여기가 소유한다."를 둔다. 주제어 목록은 옮기지 않고 "넛지가 알리는 조건과 낱말 목록은 `hooks/prior_art_nudge_userpromptsubmit.sh`가 정한다"는 문장을 둔다.

「출력 스키마」에는 `researcher`, `synthesis`, `verifier`, `map` 자료를 각각 `<!-- output: <자료 이름> -->` 한 줄과 바로 뒤의 ```` ```json ```` 울타리 블록으로 싣는다. 블록은 `JSON.parse`로 읽히는 예시 하나이며, 열거는 옛 블록처럼 `"ok|no-results|failed|not-attempted"` 같은 문자열 값으로 둔다. `researcher` 블록은 옛 렌즈 블록을 하부 명세 「출력 스키마를 옮기는 규칙」대로 바꾼 것이다. 그 블록의 최상위에는 `mode`·`subquestion_id`·`queries`·`saturation`을 둔다. 이슈 원소에는 `prior_claim`을 둔다. `evidence_map`에는 행 하나를 두고, 그 행의 키는 `case`·`url`·`axes`·`outcome`·`kind`·`source_level`·`route`·`adoption`이다. `axes`의 `purpose`·`mechanism`·`evaluation`·`target`은 각각 `{ "prior", "same", "note" }`다. `synthesis`·`verifier`·`map` 블록의 키는 큰 명세 「키 이름과 바깥 형식」 표의 형식을 그대로 쓴다. 이 블록들은 Step 4·5 의 정의 블록과 글자가 같다.

「레퍼런스 프롬프트」에는 산문 한 문장 뒤에 `- system: "<본문>"` 한 줄을 둔다. 본문은 옛 렌즈 system 문장으로 시작하고, 하부 명세 「레퍼런스 프롬프트의 요건」의 지시 가운데 옛 문장에 없는 것을 뒤에 덧붙인다. 본문 안에서는 줄을 바꾸지 않고 큰따옴표와 `가 아니라`·`이 아니라`를 쓰지 않는다. 연구자 정의 본문은 「대구 한도」 예외를 받지 않기 때문이다.

Run: `git add skills/agent-prior-art && bash scripts/test_docs_drift.sh 2>&1 | grep -E 'FAIL: .*(agent-prior-art 에 절|첫 줄|한도|소유|frontmatter)'`
Expected: 절 단언 줄이 나오지 않는다. 「첫 문장」·「대구 한도」·「소유 표」·frontmatter 단언에도 이 스킬 때문에 생긴 FAIL 이 없다.

- [ ] **Step 4: 연구자 정의 `agents/prior-art-researcher.md`를 쓴다**

frontmatter 는 하부 명세 「연구자와 검증자 정의」 표의 `prior-art-researcher` 열을 따른다. 줄은 `name: prior-art-researcher`, `description: <문장>`, `tools: WebSearch, WebFetch, Read, Grep, Glob`, `maxTurns: 20`이고 `model`은 두지 않는다. `description`은 다른 대화에서 메인 세션이 이 에이전트를 스스로 고르지 않게 쓰며, `: `와 ` #`이 없고 워크플로 이름 `disciplined-coder:prior-art-search`를 담는다.

본문은 공통 단락, `explore` 모드 단락, `synthesize` 모드 단락, 출력 형식 블록(`researcher`·`synthesis`)이다. 공통 단락은 하부 명세 126행, `explore`·`synthesize` 단락은 130행을 따른다. `explore` 단락은 Step 3 의 프롬프트 본문 한 줄을 그대로 포함한다. 모든 `##` 절의 첫 줄은 산문이다.

Run: `git add agents/prior-art-researcher.md && grep -c '^<!-- output: \(researcher\|synthesis\) -->$' agents/prior-art-researcher.md`
Expected: `2`.

- [ ] **Step 5: 검증자 정의 `agents/prior-art-verifier.md`를 쓴다**

frontmatter 는 `name: prior-art-verifier`, `description: <문장>`, `tools: WebFetch, Read`, `maxTurns: 20`이다. `description`의 요건은 Step 4 와 같다. 본문은 공통 단락, `cite` 모드 단락, `map` 모드 단락, 출력 형식 블록(`verifier`·`map`)이다. 공통 단락은 하부 명세 126행, `cite` 단락은 132행, `map` 단락은 134행을 따른다. `cite` 단락은 판정 기준 문장 "옮긴 구절이 주장의 주어와 수치와 조건을 모두 포함하면 supported"를 그대로 싣는다. Step 4 와 Step 5 의 두 파일은 같은 커밋에 넣는다(하나만 있으면 계약 테스트가 FAIL 이다).

Run: `git add agents/prior-art-verifier.md && bash scripts/test_prior_art_contract.sh | tail -8`
Expected: `SKIP: workflow`, `PASS: 에이전트 정의 두 파일이 있다`, 예시 네 개의 `PASS` 줄, `FAIL=0`이 나온다.

- [ ] **Step 6: 첫 포인터와 `domain-plugin`을 고친다**

하부 명세 「참조 처리 목록」의 `review-specs` 23행·41행·63-64행 행과 `domain-plugin` 14·16·17행 행을 적용한다. 41행은 절 이름을 「선행연구 에이전트의 제안과 승인」으로 바꾸고 "승인받으면 렌즈와 동시에 실행한다"를 지운다.

Run: `grep -c '선행연구 에이전트의 제안과 승인' skills/review-specs/SKILL.md; grep -c 'agents/\*\.md\|agent-prior-art\|workflows/' skills/domain-plugin/SKILL.md`
Expected: 첫 수는 `3`(23·41·63행)이고 둘째 수는 1 이상이다.

- [ ] **Step 7: 묶음이 통과하는지 확인한다**

Run: `bash scripts/test_docs_drift.sh 2>&1 | awk -v h='[선행연구 에이전트]' '$0==h{f=1;next} /^\[/{f=0} f' | grep -c '^  FAIL:'`
Expected: `0`.

- [ ] **Step 8: 전체 검사를 실행하고 커밋한다**

Run: CLAUDE.md 「변경 뒤 실행」 한 줄 명령. Expected: `ALL PASS`.

```bash
git add skills/agent-prior-art agents skills/review-specs/SKILL.md skills/domain-plugin/SKILL.md scripts/test_docs_drift.sh
git commit -m "선행연구 에이전트 스킬과 연구자·검증자 정의를 만든다" -m "Co-Authored-By: Claude Opus 5.5 (1M context) <noreply@anthropic.com>"
```

### Task 2: 옮긴 문장 대조와 옛 렌즈 삭제

**Files:**
- Delete: `skills/lens-prior-art/`
- Modify: `skills/aggregating-lenses/SKILL.md:22,53,56,84-87,95`, `skills/dispatching-lenses/SKILL.md:73,75,88,100`, `skills/lens-fit/SKILL.md:38`, `scripts/test_audit.sh:211`. Step 1 의 대조에서 허용 밖 차이가 나오면 `skills/agent-prior-art/SKILL.md`도 고친다.

**Interfaces:**
- Consumes: 하부 명세, Task 1 의 스킬 「판정 규약」「출력 스키마」「레퍼런스 프롬프트」.
- Produces: 렌즈 디렉터리 집합에서 `lens-prior-art`가 빠진 상태다. 기존 「집계 태깅 == 실제 디렉터리」와 렌즈 그룹 표 대조가 이 집합을 쓴다. 옛 렌즈 40행의 소유 문장이 사라지므로 Task 3 이 `review-specs` 137행 절 제목을 바꿀 수 있다.

- [ ] **Step 1: 옮긴 문장을 원문과 대조한다**

Run:
```bash
T="$(mktemp -d)"; . scripts/_doc_keys.sh
git show 7a2d26d:skills/lens-prior-art/SKILL.md > "$T/old.md"
for s in 체크리스트 가드; do doc_sec "$T/old.md" "$s" | tail -n +2; done > "$T/old_rules.txt"
doc_sec skills/agent-prior-art/SKILL.md '판정 규약' | tail -n +2 > "$T/new_rules.txt"
diff "$T/old_rules.txt" "$T/new_rules.txt"
OLD_SYS="$(grep -m1 '^- system: "' "$T/old.md" | sed 's/^- system: "//; s/"$//')"
[ -n "$OLD_SYS" ] && grep -m1 '^- system: "' skills/agent-prior-art/SKILL.md | grep -qF -- "- system: \"$OLD_SYS" && echo "system-prefix-same"
diff <(awk '/^## 출력 스키마/{f=1;next} f&&/^```$/{g=!g;next} g' "$T/old.md") <(awk '$0=="<!-- output: researcher -->"{f=1;next} f&&/^```json/{g=1;next} g&&/^```/{exit} g' skills/agent-prior-art/SKILL.md)
```
Expected: 첫 `diff`의 차이는 판정 규약 절의 첫 문장('이 설계'의 뜻), 가드 머리 문장 "이 가드는 이 렌즈에만 있다."의 삭제, `lens-derived`에서 `derived`로 바뀐 낱말, 가드 뒤 적용 문장뿐이다. 둘째 확인은 `system-prefix-same`을 낸다(옛 system 문장이 새 본문의 앞부분과 같다). 둘째 `diff`의 차이는 하부 명세 「출력 스키마를 옮기는 규칙」이 정한 칸 이름·열거·추가 칸·`principles_applied` 설명과 줄바꿈 형태뿐이다. 허용 밖 차이가 있으면 Step 2 로 가지 않고 스킬을 고친 뒤 이 단계를 다시 실행한다. 구현자는 세 `diff` 결과의 요약을 보고에 적는다.

- [ ] **Step 2: 옛 렌즈를 지우고 열거와 문장을 처리한다**

`git rm -r skills/lens-prior-art`를 실행하고, 하부 명세 「참조 처리 목록」의 `aggregating-lenses`·`dispatching-lenses`·`lens-fit`·`scripts/test_audit.sh:211` 행을 적용한다. `dispatching-lenses` 88행은 `lens-prior-art`를 다루는 뒤 두 문장만 지운다. `dispatching-lenses` 100행의 새 문장은 「발동과 기록」과 `agent-prior-art`를 같은 줄에 둔다.

Run: `git grep -n 'lens-prior-art' -- skills/aggregating-lenses skills/dispatching-lenses skills/lens-fit scripts/test_audit.sh; echo "exit=$?"`
Expected: `exit=1`.

- [ ] **Step 3: 렌즈 집합 대조가 통과하는지 확인한다**

Run: `bash scripts/test_docs_drift.sh 2>&1 | grep -E 'FAIL: .*(태깅|렌즈 그룹 표|실재하는 렌즈|소유)'`
Expected: 출력이 없다.

- [ ] **Step 4: 전체 검사를 실행하고 커밋한다**

Run: CLAUDE.md 「변경 뒤 실행」 한 줄 명령. Expected: `ALL PASS`.

```bash
git add -A skills/lens-prior-art skills/aggregating-lenses/SKILL.md skills/dispatching-lenses/SKILL.md skills/lens-fit/SKILL.md scripts/test_audit.sh skills/agent-prior-art/SKILL.md
git commit -m "옛 선행연구 렌즈를 지우고 렌즈 열거에서 뺀다" -m "Co-Authored-By: Claude Opus 5.5 (1M context) <noreply@anthropic.com>"
```

### Task 3: 호출자 문서의 참조 처리

**Files:**
- Modify: `skills/review-specs/SKILL.md`(절차 표 27행과 32·34·52·59·61·70·72·74·76·101·118·137-145행), `skills/review-docs/SKILL.md:34,38,40,50,62`, `skills/nested-orchestration/references/sub-session-protocol.md:56,60,114`, `skills/nested-orchestration/SKILL.md:228`, `skills/audit-repo-docs/SKILL.md:49`, `scripts/test_docs_drift.sh:226`

**Interfaces:**
- Consumes: 하부 명세, Task 1 의 절 이름 「발동과 기록」「인용 확인」「판정 규약」「실행할 때 지킬 상한」「오케스트레이터 절차」, Task 2 가 옛 렌즈를 지운 상태.
- Produces: `review-specs` 절 제목 「선행연구 결과의 처리」와, `review-docs` 「기록 파일 이름 규칙」의 `prior-art` 원본 이름 표다. 그 표의 이름은 `search-r<n>.json`, `researcher-<하위 질문 ID>-r<n>.json`, `verifier-r<n>.json`, `synthesis-r<n>.json`, `map-check-r<n>.json`이다. Task 1 의 스킬이 이 절을 가리킨다.

- [ ] **Step 1: 226행 단언을 새 포인터로 바꾼다**

`check "그 절이 선행연구 인용 검증을 spec 리뷰 절로 넘긴다" …`를 `check "그 절이 선행연구 인용 확인을 agent-prior-art 로 넘긴다" "points_to \"\$DOCS\" '\`agent-prior-art\`' '「인용 확인」'"`로 바꾼다.

- [ ] **Step 2: 그 단언이 실패하는지 확인한다**

Run: `bash scripts/test_docs_drift.sh 2>&1 | awk -v h='[합치기와 다시 리뷰]' '$0==h{f=1;next} /^\[/{f=0} f' | grep '^  FAIL:'`
Expected: `  FAIL: 그 절이 선행연구 인용 확인을 agent-prior-art 로 넘긴다` 한 줄만 나온다.

- [ ] **Step 3: 하부 명세 「참조 처리 목록」의 해당 행을 적용한다**

구현자는 Files 에 적은 줄마다 그 표의 처리 칸대로 고친다. `review-specs` 76행은 괄호를 지우고, "판정에 쓸 수 있는 발견은 워크플로 반환값 `passed`의 항목이다. `overall_status`가 `ok`가 아니면 그중 `ok`인 하위 질문의 항목만 쓴다"를 뒤에 둔다. `review-specs` 137-138행은 제목을 「선행연구 결과의 처리」로 바꾸고, "이 절차는 여기가 소유한다."는 남기며, 둘째 문장을 "선행연구 에이전트를 실행했을 때만 따른다."로 바꾼다.

`review-docs` 62행 문단 끝에는 위 Produces 의 원본 이름 표와 `r<n>`의 뜻(첫 탐색 1, 공백 라운드 2)을 둔다. 인용 판정 출력이 URL 별 판정 배열이며 판정마다 그 URL 을 인용한 하위 질문 ID 를 적는다는 문장도 함께 둔다. 고친 줄이 「X」를 담으면 같은 줄에 X 소유자의 이름(`agent-prior-art` 등)도 둔다.

Run: `git grep -n -E 'lens-prior-art|웹에 나가는 렌즈|선행연구 렌즈' -- skills/review-specs skills/review-docs skills/nested-orchestration skills/audit-repo-docs; echo "exit=$?"`
Expected: `exit=1`.

- [ ] **Step 4: 바꾼 단언이 통과하는지 확인한다**

Run: Step 2 의 명령. Expected: 출력이 없다.

- [ ] **Step 5: 전체 검사를 실행하고 커밋한다**

Run: CLAUDE.md 「변경 뒤 실행」 한 줄 명령. Expected: `ALL PASS`.

```bash
git add skills/review-specs/SKILL.md skills/review-docs/SKILL.md skills/nested-orchestration skills/audit-repo-docs/SKILL.md scripts/test_docs_drift.sh
git commit -m "리뷰·검진·중첩 절차가 선행연구를 agent-prior-art 로 가리킨다" -m "Co-Authored-By: Claude Opus 5.5 (1M context) <noreply@anthropic.com>"
```

### Task 4: 에이전트원칙과 근거 문서

**Files:**
- Modify: `agent-principles.md:132`, `docs/domain-discipline.md`(`NO-RAW-OUTPUT` 절 끝, `LENS-ALLOWED` 절 끝), `scripts/test_docs_drift.sh:846-849`와 묶음 `[선행연구 에이전트]`

**Interfaces:**
- Consumes: 하부 명세, Task 1 의 `AP` 변수와 스킬 「발동과 기록」의 소유 선언.
- Produces: 없음.

- [ ] **Step 1: 단언을 바꾸고 추가한다**

846-849행 단언을 `check "선행연구 에이전트가 승인 규칙을 소유한다" "owns_sec \"\$AP\" '발동과 기록'"`로 바꾼다. 846-848행 주석은 "선행연구 에이전트는 이름이 `lens-*` 형태가 아니어서 상시 허가에 들지 않고, 승인 규칙은 자기 절이 소유한다"는 이유로 고친다. `AP`의 정의는 Task 1 이 파일 끝 묶음에 두었으므로, 그 정의 줄을 이 단언 위로 옮긴다(`set -u` 아래에서 정의 전에 쓰면 스크립트가 멈춘다). 묶음 `[선행연구 에이전트]`에는 아래 단언을 추가한다.

```bash
DDISC="$HERE/docs/domain-discipline.md"
check "근거 문서의 NO-RAW-OUTPUT 절이 대체를 적는다" "sec_has \"\$DDISC\" '\`NO-RAW-OUTPUT\`' 'agent-prior-art'"
check "근거 문서의 LENS-ALLOWED 절이 대체를 적는다" "sec_has \"\$DDISC\" '\`LENS-ALLOWED\`' 'agent-prior-art'"
```

- [ ] **Step 2: 바꾸고 추가한 단언이 실패하는지 확인한다**

Run: `for h in '[standing-consent] lens calls carry the user'"'"'s standing consent' '[선행연구 에이전트]'; do bash scripts/test_docs_drift.sh 2>&1 | awk -v h="$h" '$0==h{f=1;next} /^\[/{f=0} f' | grep '^  FAIL:'; done`
Expected: `FAIL: 근거 문서의 NO-RAW-OUTPUT 절이 대체를 적는다`와 `FAIL: 근거 문서의 LENS-ALLOWED 절이 대체를 적는다`가 나온다. 소유 단언은 Task 1 이 소유 선언을 두었으므로 이미 PASS 다.

- [ ] **Step 3: 원칙과 근거 문서를 고친다**

하부 명세 「참조 처리 목록」의 `agent-principles.md:132`, `docs/domain-discipline.md:315`, `docs/domain-discipline.md:329·332·341` 행을 적용한다. 원칙은 예시 괄호만 지우고 규칙 문장은 그대로 둔다. 클린룸 시험은 사용자 결정으로 생략하며, 그 사실을 `LENS-ALLOWED` 절 끝 문단에 적는다. `docs/domain-discipline.md`에서 「발동과 기록」을 쓰는 줄에는 같은 줄에 `agent-prior-art`를 둔다. 그 파일은 약 100자에서 줄을 바꾸므로 줄을 나눌 때 두 낱말이 갈리지 않게 한다.

Run: `grep -n '「발동과 기록」' docs/domain-discipline.md | grep -vc 'agent-prior-art'`
Expected: `0`.

- [ ] **Step 4: 전체 검사를 실행하고 커밋한다**

Run: CLAUDE.md 「변경 뒤 실행」 한 줄 명령. Expected: `ALL PASS`.

```bash
git add agent-principles.md docs/domain-discipline.md scripts/test_docs_drift.sh
git commit -m "LENS-ALLOWED 의 옛 렌즈 예시를 지우고 근거 문서에 대체를 적는다" -m "Co-Authored-By: Claude Opus 5.5 (1M context) <noreply@anthropic.com>"
```

### Task 5: 발동 넛지

**Files:**
- Create: `hooks/prior_art_nudge_userpromptsubmit.sh`
- Modify: `hooks/hooks.json`, `README.md`(「하드 게이트와 넛지와 전역 설정 수정」 표와 「끄는 법」), `scripts/test_hooks.sh`(요약 줄 앞에 새 묶음)

**Interfaces:**
- Consumes: 하부 명세 「발동 넛지」, `hooks/_json_escape.sh`의 `escape_for_json <문자열>`.
- Produces: 훅 출력 `{"hookSpecificOutput":{"hookEventName":"UserPromptSubmit","additionalContext":"<알림>"}}` 한 줄과, 끄는 변수 `DISCIPLINED_CODER_PRIOR_ART_NUDGE`.

- [ ] **Step 1: 묶음 `[prior-art-nudge]`의 실패하는 단언을 쓴다**

침묵 단언과 끄기 단언도 `out="$(…)" &&` 형태로 써서 훅의 종료 코드를 함께 본다.

```bash
echo "[prior-art-nudge]"
PAN="$HERE/hooks/prior_art_nudge_userpromptsubmit.sh"
pan() { printf '{"session_id":"s","hook_event_name":"UserPromptSubmit","prompt":"%s"}' "$1" | bash "$PAN"; }
for m in '선행연구에 쓸 만한 에이전트 플러그인이 있나 찾아봐' \
         '에이전트원칙의 목차를 어떤 기준으로 배치해야 하는지 선행연구를 조사해 줘' \
         'docs/superpowers/specs/2026-10-09-nested-orchestration-large-dev-design.md 의 선행 사례를 찾아 줘' \
         '선행연구렌즈로 뒤져봐' 'lens-prior-art 로 찾아봐' '\"이 방법\"의 선행연구를 찾아 줘' 'Prior Art 있나'; do
  check "알린다: $m" "out=\"\$(pan '$m')\" && grep -qF 'agent-prior-art' <<<\"\$out\" && grep -qF '\"hookEventName\":\"UserPromptSubmit\"' <<<\"\$out\" && json_valid_stdin <<<\"\$out\""
done
for m in '선행연구 결과를 기록에 정리했다' '선행연구 단계는 끝났다' 'prior art 기록 파일 이름을 바꿨다' '이 함수를 고쳐봐'; do
  check "침묵한다: $m" "out=\"\$(pan '$m')\" && [ -z \"\$out\" ]"
done
check "끄면 침묵한다" "out=\"\$(DISCIPLINED_CODER_PRIOR_ART_NUDGE=off pan '선행연구렌즈로 뒤져봐')\" && [ -z \"\$out\" ]"
check "빈 객체 입력은 침묵하고 0 으로 끝난다" "out=\"\$(printf '{}' | bash \"\$PAN\")\" && [ -z \"\$out\" ]"
check "빈 표준 입력은 침묵하고 0 으로 끝난다" "out=\"\$(printf '' | bash \"\$PAN\")\" && [ -z \"\$out\" ]"
check "prompt 값이 빈 입력은 침묵하고 0 으로 끝난다" "out=\"\$(pan '')\" && [ -z \"\$out\" ]"
check "UserPromptSubmit 이 넛지를 연결한다" "json_run 'import json,sys; d=json.load(open(sys.argv[1],encoding=\"utf-8\")).get(\"hooks\",{}).get(\"UserPromptSubmit\",[]); sys.exit(0 if any(\"prior_art_nudge_userpromptsubmit.sh\" in h[\"command\"] for g in d for h in g[\"hooks\"]) else 1)' \"\$HERE/hooks/hooks.json\""
```

- [ ] **Step 2: 묶음이 실패하는지 확인한다**

Run: `bash scripts/test_hooks.sh 2>&1 | awk -v h='[prior-art-nudge]' '$0==h{f=1;next} /^\[/{f=0} f' | grep '^  FAIL:'`
Expected: 묶음의 모든 단언이 `  FAIL:` 줄로 나온다. 훅 파일이 없어 `bash "$PAN"`이 0 이 아닌 값으로 끝나므로 출력을 보는 단언과 종료 코드를 보는 단언이 함께 실패하고, 연결 단언은 `UserPromptSubmit` 키가 없어 실패한다.

- [ ] **Step 3: 훅을 쓴다**

구현자는 하부 명세 「발동 넛지」의 흐름 1~5 를 그대로 구현한다. 주제어는 `선행연구`·`prior art`·`선행 사례`·`누가 해봤`·`선행연구렌즈`·`lens-prior-art`이고, 요청형은 `찾아`·`뒤져`·`조사해`·`해봐`·`있나`·`없나`다. 두 목록은 이 파일에만 둔다. 머리 주석에는 이 파일이 낱말 목록의 원본이라는 사실과, 한글이 `\uXXXX`로 들어오면 맞지 않는다는 가정을 적는다. 알림 문구는 하부 명세의 요건을 따른다. 그 요건은 스킬을 열어 절차대로 진행하라는 지시, 손으로 짠 워크플로나 일반 리서치로 대신하지 말라는 지시, 요청이 아니면 무시하라는 문장, "넛지일 뿐 차단은 아니다"이며, 스킬의 절 이름은 넣지 않는다.

Run: `printf '{"prompt":"선행연구렌즈로 뒤져봐"}' | bash hooks/prior_art_nudge_userpromptsubmit.sh; echo "exit=$?"`
Expected: `{"hookSpecificOutput":{"hookEventName":"UserPromptSubmit","additionalContext":"…agent-prior-art…"}}` 한 줄과 `exit=0`이 나온다.

- [ ] **Step 4: 연결과 README 를 고친다**

`hooks/hooks.json`의 `"Stop"` 앞에 `"UserPromptSubmit": [{"hooks": [{"type": "command", "command": "bash \"${CLAUDE_PLUGIN_ROOT}/hooks/prior_art_nudge_userpromptsubmit.sh\""}]}]`를 둔다. `README.md`는 하부 명세 「발동 넛지」 마지막 문단대로 고친다. 그 문단은 표 행(SessionStart 행들 뒤), 「끄는 법」 불릿, "두 변수는"을 "세 변수는"으로 바꾸는 일을 정한다.

Run: `grep -c 'prior_art_nudge_userpromptsubmit.sh' README.md; grep -c '세 변수는' README.md`
Expected: 첫 수는 2 이상이고(표 행과 「끄는 법」 불릿) 둘째 수는 `1`이다.

- [ ] **Step 5: 묶음이 통과하는지 확인한다**

Run: `bash scripts/test_hooks.sh 2>&1 | awk -v h='[prior-art-nudge]' '$0==h{f=1;next} /^\[/{f=0} f' | grep -c '^  FAIL:'`
Expected: `0`.

- [ ] **Step 6: 실행 시간을 측정한다**

Run: `time (for i in $(seq 20); do printf '{"session_id":"s","prompt":"선행연구에 쓸 만한 에이전트 플러그인이 있나 찾아봐"}' | bash hooks/prior_art_nudge_userpromptsubmit.sh >/dev/null; done)`
Expected: 명령이 오류 없이 끝난다. 구현자는 한 번당 평균 시간(real 값을 20 으로 나눈 값)을 보고에 적는다.

- [ ] **Step 7: 전체 검사를 실행하고 커밋한다**

Run: CLAUDE.md 「변경 뒤 실행」 한 줄 명령. Expected: `ALL PASS`.

```bash
git add hooks/prior_art_nudge_userpromptsubmit.sh hooks/hooks.json README.md scripts/test_hooks.sh
git commit -m "선행연구 요청을 알리는 UserPromptSubmit 넛지를 만든다" -m "Co-Authored-By: Claude Opus 5.5 (1M context) <noreply@anthropic.com>"
```

### Task 6: 한 번 하는 확인과 플러그인 검증

**Files:**
- 이 태스크는 파일을 고치지 않는다. Step 5 에서 이번 변경 때문에 생긴 경고가 나오면 구현자는 고치지 않고 컨트롤러에게 알린다.

**Interfaces:**
- Consumes: Task 1~5 의 커밋.
- Produces: 컨트롤러가 리포트에 옮길 확인 결과. 구현자는 이 결과를 보고에 적는다.

- [ ] **Step 1: 옛 이름 완료 조건을 확인한다**

Run: `git grep -n --untracked 'lens-prior-art' -- . ':!docs/superpowers/reviews' ':!docs/superpowers/specs' ':!docs/superpowers/plans' ':!docs/domain-discipline.md' ':!skills/agent-prior-art/SKILL.md' ':!hooks/prior_art_nudge_userpromptsubmit.sh' ':!scripts/test_hooks.sh' ':!scripts/test_docs_drift.sh'; echo "exit=$?"`
Expected: `exit=1`. 2 이상은 명령 오류이므로 통과로 보지 않는다.

- [ ] **Step 2: 예외 파일 안의 범위를 확인한다**

Run: `[ -f skills/agent-prior-art/SKILL.md ] && grep -n 'lens-prior-art' skills/agent-prior-art/SKILL.md; grep -c 'lens-derived' skills/agent-prior-art/SKILL.md`
Expected: 첫 명령은 `description:` 줄 하나만 낸다. 둘째 명령은 `0`을 낸다.

- [ ] **Step 3: 출력 형식 블록을 스킬과 비교한다**

Run:
```bash
blk() { awk -v m="<!-- output: $1 -->" '$0==m{f=1;next} f&&/^```json/{g=1;next} g&&/^```/{exit} g' "$2"; }
for p in researcher:agents/prior-art-researcher.md synthesis:agents/prior-art-researcher.md verifier:agents/prior-art-verifier.md map:agents/prior-art-verifier.md; do
  n="${p%%:*}"; f="${p#*:}"
  [ -n "$(blk "$n" "$f")" ] && diff <(blk "$n" skills/agent-prior-art/SKILL.md) <(blk "$n" "$f") && echo "same: $n"
done
```
Expected: `same: researcher`, `same: synthesis`, `same: verifier`, `same: map`가 나오고 `diff` 출력은 없다.

- [ ] **Step 4: 참조 grep 을 다시 실행한다**

Run: `git grep -n -E 'lens-prior-art|필요할 때 그룹|필요할 때 렌즈|선행연구 렌즈|웹에 나가|search_status|외부 탐색|사용자 승인이 필요한 렌즈|렌즈 그룹 판정' -- . ':!docs/superpowers'`
Expected: 남은 줄은 아래 종류뿐이다. 구현자는 이 밖의 줄이 나오면 컨트롤러에게 알린다.
- 하부 명세 「참조 처리 목록」 아래 문단이 그대로 두라고 정한 줄
- `lens-readability`에도 적용되어 '필요할 때 렌즈'를 쓰는 줄(`skills/audit-repo-docs/SKILL.md:16`, Task 3 이 고친 `skills/review-docs/SKILL.md` 34·50행)
- 완료 조건의 예외 파일에 든 줄
- 계약 코드·계약 테스트·새 스킬·두 정의의 `search_status`
- Task 3 이 고친 `렌즈 그룹 판정`·`사용자 승인이 필요한 렌즈` 문장

- [ ] **Step 5: 전체 검사와 플러그인 검증을 실행한다**

Run: CLAUDE.md 「변경 뒤 실행」 한 줄 명령과 `claude plugin validate ./`.
Expected: `ALL PASS`와 `Validation passed`가 나온다. 경고가 나오면 구현자는 경고 문구를 보고에 옮긴다.

<!-- spec-review: passed -->
