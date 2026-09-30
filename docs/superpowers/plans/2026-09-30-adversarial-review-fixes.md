# 적대적 리뷰 반영 Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** 2026-09-30 적대적 렌즈 리뷰(이음새·훅·스크립트·완성도 네 호출)에서 확정한 결함을 고쳐, 도구 호출과 답마다 드는 프로세스를 줄이고 조용한 실패와 규칙·실물 불일치를 없앤다.

**Architecture:** 훅 입력 파싱을 `_hook_input.sh` 한 곳으로 모으고, Stop 훅 둘을 진입 스크립트 하나(`stop_gates.sh`)로 합친다. SessionStart 는 matcher 를 셋으로 나눠 갱신 확인을 startup 에만 두고, 스캐폴드는 바뀐 것이 없으면 전역 파일을 다시 쓰지 않는다. 스킬 문서는 렌즈 결과 계약(`target`·원본 번호)과 감사의 에이전트 상한을 실물 스크립트에 맞춘다.

**Tech Stack:** bash(Git Bash·Linux), awk, 파이썬(JSON 처리 전용, `scripts/_json_valid.sh` 의 `json_run`), GitHub Actions.

**Spec:** 별도 spec 없음. 근거는 2026-09-30 대화의 사용자 결정 12개와, 같은 대화에서 "질문 없이 고칠 항목"으로 알린 뒤 사용자가 "진행해"로 승인한 목록이다. 둘 다 아래 「Global Constraints」에 옮긴다. 리뷰 기록은 `docs/superpowers/reviews/2026-09-30-adversarial-review-fixes-review.md` 이다.

**용어:** L1·L2 는 `nested-orchestration` 의 층이다. L1 은 사람과 대화하는 메인 오케스트레이터이고, L2 는 워크트리마다 하나씩 실행되어 사람과 대화하지 못하는 서브오케스트레이터다.

## Global Constraints

사용자 결정 12개는 아래와 같다.

- **PYTHONUTF8** — 자동 설정을 유지한다. `skills/domain-plugin/SKILL.md` 「환경 변수」 항목에 이 예외를 적는다.
- **autoUpdate** — 명시적으로 `false` 이면 갱신 확인을 하지 않고 아무것도 출력하지 않는다.
- **Stop 훅** — 둘을 한 프로세스로 합치고 git status 는 한 번만 실행한다. README 와 domain-plugin 의 "답마다 실행되는 훅" 규칙을 "대화 기록을 파싱하는 Stop 훅은 금지, git 상태만 보는 가벼운 게이트는 허용"으로 정정한다.
- **제거 절차** — 다루지 않는다.
- **배포 대상** — 본인과 사내 한국어 사용자다. README 에 그 한 줄만 추가하고 라이선스·사내 저장소 안내·금지어 목록 적재는 그대로 둔다.
- **파이썬 부재** — 금지어 검사가 조용히 통과하는 동작은 유지하고, 주석과 README 에 명시한다.
- **훅 구조** — 중복만 제거한다. 훅 파일과 hooks.json 의 PreToolUse·PostToolUse 연결은 그대로 둔다.
- **규칙 넛지** — 현재 방식을 유지하고 SessionStart matcher 에 `compact` 를 추가한다.
- **갱신 확인 시점** — startup 에서만 실행하고, claude CLI 두 명령에 시간 상한과 잠금을 둔다.
- **감사 상한** — 레포 감사는 문서 여러 개를 한 호출에 묶어 한 단계의 에이전트를 10개 이하로 맞춘다.
- **L2 리뷰** — L2 는 plan 리뷰 뒤 다시 리뷰를 묻지 않고 생략하며, L1 이 병합 전에 plan 마커를 확인한다.
- **YAGNI 정리** — `aggregating-lenses` 의 상충 감지 단계, `lens-readability` 의 '목적이 둘' 예외, `MANAGED_TAG` 외부 설정을 제거한다.

승인된 "질문 없이 고칠 항목"은 아래와 같다.

- **target 칸과 원본 번호** — `aggregating-lenses` 계약에 `target` 칸을 추가하고, 원본 파일 번호의 뜻을 대상 순번으로 정정한다.
- **CI 결과 전달** — 동기화 워크플로의 테스트 실패 목록을 PR 본문에 넣는다.
- **전역 파일 쓰기** — 관리블록이 같으면 다시 쓰지 않고, 원칙 사본은 원자적으로 바꾸며, autoUpdate 사본은 시각을 붙인 이름으로 남긴다.
- **레지스트리 조회** — 프로세스 환경에 PYTHONUTF8 이 있으면 생략한다.
- **경고 통로** — 사용자가 조치할 경고를 stderr 에서 stdout 으로 옮긴다.
- **실패 경로** — UNC 경로 앞머리, 맥의 빈 배열, 항진 단언 한 건을 고친다.
- **문서 불일치** — 규칙 넛지의 근거 경로, README 넛지 설명, `review-specs` 외부 의존 목록, `review-llm-calls` 포인터, 중복 문장을 정리한다.
- **테스트 정리** — `check()` 를 공유 파일로 옮긴다.
- **spec 게이트 범위** — 이 세션이 시작되기 전에 만든 미추적 초안은 차단하지 않는다(에이전트원칙 `FOCUSED`). 세션 시작 표시가 없으면 지금처럼 전부 본다.

실행 전반의 제약은 아래와 같다.

- **에이전트원칙 본문** — `agent-principles.md` 는 고치지 않는다. 프로젝트 CLAUDE.md 가 문구 변경에 클린룸 소거 시험을 요구하기 때문이다. 근거 파일의 절대경로는 규칙 넛지가 알린다.
- **커밋** — 사용자가 요청할 때만 한다. 이 plan 에 커밋 단계가 없는 이유다.
- **완료 조건** — 모든 태스크의 마지막 단계는 저장소 CLAUDE.md 「변경 뒤 실행」의 전체 테스트를 실행해 `ALL PASS` 를 확인하는 것이다. 개수를 숫자로 적지 않는다.
- **단계 순서** — 파일을 지우는 단계는 그 파일을 가리키던 호출자와 배선을 모두 바꾼 뒤에 둔다. 중간에 끊겨도 없는 파일을 부르는 훅이 남지 않게 하기 위해서다.
- **Task 10 승인** — Task 10 은 plan 리뷰에서 나온 추가 변경이다. 2026-09-30 에 사용자가 다섯 단계 모두를 승인했다.

## Review Focus

- **세션 ID 가 없는 Stop 입력** — spec 게이트가 세션 시작 표시를 찾지 못하면 지금처럼 미추적 spec 전부를 차단해야 한다. Task 2 에 단언을 둔다.
- **두 Stop 검사가 함께 걸리는 턴** — 차단 사유와 금지어 알림에 따옴표·개행이 섞여도 응답이 유효한 JSON 한 줄이어야 한다. Task 2 에 단언을 둔다.
- **금지어 검사가 실패하는 턴** — 금지어 쪽이 실패해도 spec 차단은 나가야 한다. Task 2 에 단언을 둔다.
- **끊긴 창이 남긴 갱신 잠금** — 10분이 지난 잠금은 치우고, 그 실행은 물러나며 다음 실행이 갱신해야 한다. Task 4 에 단언을 둔다.
- **내용이 같은 전역 CLAUDE.md** — 두 번째 스캐폴드는 파일을 다시 쓰지 않아야 한다(수정 시각이 그대로). Task 5 에 단언을 둔다.

---

### Task 1: 훅 입력 파싱 정리

**Files:**
- Modify: `hooks/_hook_input.sh:1-5,22-28`
- Modify: `hooks/_extract_bash_targets.sh` (실행 스크립트 → source 하는 라이브러리)
- Delete: `hooks/_extract_command.sh`
- Modify: `hooks/python3_guard_pretooluse.sh:12,43`
- Modify: `hooks/doc_review_posttooluse.sh:20`
- Modify: `hooks/doc_word_posttooluse.sh:15,32`
- Modify: `hooks/rules_nudge_sessionstart.sh:10`
- Test: `scripts/test_hooks.sh`

**Interfaces:**
- Produces: `bash_write_targets "$CMD"` — 명령 문자열을 받아 쓰기 대상 경로를 한 줄에 하나 출력한다. `_hook_input.sh` 다음에 `_extract_bash_targets.sh` 를 source 해야 쓸 수 있다.
- Produces: 입력이 작은 훅(Bash 전용·SessionStart·Stop)의 입력 읽기 한 줄 `IFS= read -r -d '' INPUT || true`. Write·Edit 를 받는 훅은 `INPUT="$(cat)"` 을 유지한다.
- Consumes: `_hook_input.sh` 의 `hook_command`(CMD 설정), `bash_cmd_writes`.

- [ ] **Step 1: 실패하는 테스트를 쓴다**

`scripts/test_hooks.sh` 의 `[extract]` 블록 끝에 추가한다.

```bash
check "UNC 경로의 앞머리 두 슬래시를 보존한다" "[ \"\$(extract '$(J '\\\\\\\\srv\\\\share\\\\a.md')')\" = '//srv/share/a.md' ]"
# 입력이 작은 훅만 read 로 읽는다. read 는 파이프를 한 바이트씩 읽어 큰 Write 입력에서 cat 보다 느리다
# (2026-09-30 실측: 2KB 4ms 대 31ms, 50KB 62ms 대 30ms, 200KB 274ms 대 31ms).
for small in python3_guard_pretooluse.sh doc_word_posttooluse.sh rules_nudge_sessionstart.sh; do
  check "$small 은 stdin 을 read 로 읽는다" "! grep -qF 'INPUT=\"\$(cat)\"' '$HERE/hooks/$small' && grep -qF \"IFS= read -r -d ''\" '$HERE/hooks/$small'"
done
check "Write 를 받는 훅은 cat 을 유지한다" "grep -qF 'INPUT=\"\$(cat)\"' '$HERE/hooks/doc_word_pretooluse.sh'"
check "명령 파서는 하나다"                     "[ ! -e \"\$HERE/hooks/_extract_command.sh\" ]"
```

같은 파일 239-242행의 `ebt` 를 라이브러리 호출로 바꾼다.

```bash
EBT="$HERE/hooks/_extract_bash_targets.sh"
ebt() { ( . "$HERE/hooks/_hook_input.sh"; . "$EBT"; bash_write_targets "$1" ) | tr '\n' ' '; }
```

463행 `XCMD="$HERE/hooks/_extract_command.sh"` 를 아래 도우미로 바꾸고, 그 블록에서 `bash "$XCMD"` 를 호출하던 단언은 `xcmd '<JSON>'` 으로 바꾼다.

```bash
xcmd() { ( INPUT="$1"; . "$HERE/hooks/_hook_input.sh"; hook_command; printf '%s' "$CMD" ); }
```

- [ ] **Step 2: 테스트가 실패하는지 확인한다**

Run: `bash scripts/test_hooks.sh 2>&1 | grep -E 'FAIL:' | head -20`
Expected: `UNC 경로…`, `… read 로 읽는다` 세 건, `명령 파서는 하나다`, 그리고 `ebt` 를 쓰는 단언들이 FAIL.

- [ ] **Step 3: slash_norm 이 UNC 앞머리를 보존하게 고친다**

`hooks/_hook_input.sh` 의 `slash_norm` 을 아래로 바꾼다.

```bash
slash_norm() {  # $1=변수 이름. 역슬래시를 슬래시로 바꾸고 이어진 슬래시를 하나로 줄인다(tr -s '\\' '/').
  # 지역 변수 이름을 호출자와 겹치지 않게 짓는다. 겹치면 printf -v 가 호출자가 아니라 여기 것을 고친다.
  # UNC(//server/share)는 앞머리 두 슬래시가 경로의 일부다. 하나로 줄이면 Git Bash 가 다른 경로로 풀어
  # 있는 파일을 없는 파일로 판정한다. 그래서 앞머리만 한 글자 되살린다.
  local _sn_v="${!1}" _sn_one='/' _sn_two='//' _sn_lead=''
  _sn_v="${_sn_v//\\//}"
  [[ $_sn_v == //* ]] && _sn_lead='/'
  while [[ $_sn_v == *"$_sn_two"* ]]; do _sn_v="${_sn_v//"$_sn_two"/$_sn_one}"; done
  printf -v "$1" '%s' "$_sn_lead$_sn_v"
}
```

머리 주석 5행 뒤에 두 줄을 추가한다.

```bash
# 입력이 작은 훅(Bash 전용·SessionStart·Stop)은 stdin 을 `IFS= read -r -d '' INPUT || true` 로 읽는다.
# Write·Edit 를 받는 훅은 `$(cat)` 을 유지한다 — read 는 한 바이트씩 읽어 큰 content 에서 cat 보다 느리다.
```

- [ ] **Step 4: `_extract_bash_targets.sh` 를 라이브러리로 바꾸고 호출자를 함께 바꾼다**

라이브러리 변환과 호출자 교체를 한 단계에서 한다. 사이에 끊기면 호출자가 함수 정의만 있는 파일을 실행해 출력 없이 성공한다.

`_extract_bash_targets.sh` 에서 세 곳을 고친다. 19행 끝 문장 "이 파일을 부르는 훅 둘이 같은 판정으로 먼저 거른다." 를 "이 파일을 source 하는 훅 둘이 같은 판정으로 먼저 거르고 bash_write_targets 를 부른다. 실행 스크립트로 두면 호출마다 bash 와 파서가 한 벌 더 뜬다." 로 바꾼다. 20-26행(`set -euo pipefail` 부터 `bash_cmd_writes "$CMD" || exit 0` 까지)과 27행 빈 줄을 지운다. 28행 `printf '%s' "$CMD" | LC_ALL=C awk '` 를 `BASH_TARGETS_AWK='` 로 바꾼다. 29-76행 awk 본문은 그대로 둔다(작은따옴표가 없고 `\x27` 로 적혀 있어 작은따옴표 문자열에 그대로 들어간다). 77행 `'` 뒤에 아래를 추가한다.

```bash
bash_write_targets() {  # $1=명령 → 쓰기 대상 경로를 한 줄에 하나 낸다
  printf '%s' "$1" | LC_ALL=C awk "$BASH_TARGETS_AWK"
}
```

`hooks/doc_review_posttooluse.sh` 20행을 바꾼다.

```bash
  . "$DIR/_extract_bash_targets.sh"
  TARGETS="$(bash_write_targets "$CMD" || true)"
```

`hooks/doc_word_posttooluse.sh` 32행을 바꾼다.

```bash
. "$HOOKDIR/_extract_bash_targets.sh"
TARGETS="$(bash_write_targets "$CMD" 2>/dev/null || true)"
```

`hooks/python3_guard_pretooluse.sh` 43행을 바꾼다.

```bash
. "$DIR/_hook_input.sh"   # 명령 꺼내기(hook_command) 공유 — 파서를 한 곳에 둔다
hook_command
```

- [ ] **Step 5: 입력이 작은 훅의 stdin 읽기를 바꾼다**

`hooks/python3_guard_pretooluse.sh` 12행, `hooks/doc_word_posttooluse.sh` 15행, `hooks/rules_nudge_sessionstart.sh` 10행의 `INPUT="$(cat)"` 를 아래로 바꾼다. `set -e` 아래에서 `read` 는 EOF 에 1을 돌려주므로 `|| true` 가 필요하다.

```bash
IFS= read -r -d '' INPUT || true
```

- [ ] **Step 6: 쓰이지 않게 된 파서를 지운다**

`grep -rn '_extract_command' hooks scripts skills README.md CLAUDE.md` 로 남은 참조를 찾아 주석이면 `_hook_input.sh 의 hook_command` 로 바꾼다. 참조가 주석만 남은 것을 확인한 뒤 `hooks/_extract_command.sh` 를 지운다.

- [ ] **Step 7: 전체 테스트를 실행한다**

Run: 저장소 CLAUDE.md 「변경 뒤 실행」의 명령
Expected: `ALL PASS`

---

### Task 2: Stop 훅 둘을 한 프로세스로 합치고 세션 밖 초안을 제외한다

**Files:**
- Create: `hooks/stop_gates.sh`
- Delete: `hooks/spec_review_stop.sh`, `hooks/doc_word_stop.sh`
- Modify: `hooks/_stop_preamble.sh:2-3,19-26`
- Modify: `hooks/rules_nudge_sessionstart.sh` (세션 시작 표시 쓰기)
- Modify: `hooks/hooks.json` (Stop)
- Modify: `README.md` (hook 표의 Stop 행, 「끄는 법」, 「차단되었을 때 푸는 법」의 Stop 하드 게이트)
- Test: `scripts/test_hooks.sh`, `scripts/test_docs_drift.sh:105`

**Interfaces:**
- Produces: `hooks/stop_gates.sh` 안의 함수 `spec_gate_check`(결과 `SPEC_BLOCK_REASON`)와 `doc_word_gate_check`(결과 `DOC_WORD_MSG`). 둘 다 전역 배열 `STATUS`(`git status -z --porcelain --untracked-files=all --no-renames` 레코드)를 읽는다.
- Produces: 세션 시작 표시 파일 `${TMPDIR:-/tmp}/disciplined-coder/session-start-<영숫자·-·_ 만 남긴 session_id>`. SessionStart 의 source 가 `startup` 일 때만 만든다.

- [ ] **Step 1: 실패하는 테스트를 쓴다**

`scripts/test_hooks.sh` 9행과 345행의 대상을 바꾼다.

```bash
STOP="$HERE/hooks/stop_gates.sh"
DWSTOP="$HERE/hooks/stop_gates.sh"
```

`[stop 겹]` 블록에서 `s.md` 를 만드는 줄은 spec 게이트가 끼지 않도록 마커를 붙인다.

```bash
printf '이 문서는 자리를 짚는다.\n<!-- spec-review: passed -->\n' > "$SR/docs/superpowers/specs/s.md"
```

같은 블록의 `이 저장소 자신 → 무출력` 단언은 금지 표현의 저장소 제외를 보는 단언이므로 spec 검사를 끄고 부른다. 그러지 않으면 이 저장소 작업 트리에 미리뷰 plan 이 있을 때 결과가 갈린다.

```bash
check "이 저장소 자신 → 무출력"        "[ -z \"\$(JSTOP '$HERE' | DISCIPLINED_CODER_REVIEW_GATE=off bash '$DWSTOP')\" ]"
```

`[stop]` 블록 끝에 추가한다.

```bash
# 세션이 시작되기 전에 만든 초안은 이 세션의 일이 아니다(FOCUSED). 표시가 없으면 지금처럼 전부 본다.
G4="$(mktemp -d)"; ( cd "$G4" && git init -q && git config user.email t@t && git config user.name t )
mkdir -p "$G4/docs/superpowers/specs"; printf 'old draft\n' > "$G4/docs/superpowers/specs/old.md"
touch -d '2000-01-01' "$G4/docs/superpowers/specs/old.md"
mkdir -p "$TMPDIR/disciplined-coder"; : > "$TMPDIR/disciplined-coder/session-start-s9"
check "세션 전 초안은 막지 않는다"          "[ -z \"\$(stop '{\"cwd\":\"$G4\",\"session_id\":\"s9\"}')\" ]"
check "세션 표시가 없으면 전부 본다"        "stop '{\"cwd\":\"$G4\",\"session_id\":\"s10\"}' | grep -q '\"block\"'"
check "세션 ID 가 없으면 전부 본다"         "stop '{\"cwd\":\"$G4\"}' | grep -q '\"block\"'"
printf 'new draft\n' > "$G4/docs/superpowers/specs/new.md"
check "세션 중 새 초안은 막는다"            "stop '{\"cwd\":\"$G4\",\"session_id\":\"s9\"}' | grep -q '\"block\"'"
# 두 검사가 한 턴에 함께 걸리면 한 응답에 둘 다 담는다.
printf '이 "문서"는 자리를\n짚는다.\n' > "$G4/report.md"
BOTH="$(stop "{\"cwd\":\"$G4\",\"session_id\":\"s9\"}")"
check "두 검사가 한 응답에 담긴다"          "printf '%s' \"\$BOTH\" | grep -q '\"block\"' && printf '%s' \"\$BOTH\" | grep -q systemMessage"
check "합친 응답이 유효한 JSON"             "printf '%s' \"\$BOTH\" | json_valid_stdin"
OFFS="$(DISCIPLINED_CODER_REVIEW_GATE=off stop "{\"cwd\":\"$G4\"}")"
check "REVIEW_GATE=off 는 spec 차단을 끈다"      "! printf '%s' \"\$OFFS\" | grep -q '\"block\"'"
check "REVIEW_GATE=off 여도 금지어 알림은 남는다" "printf '%s' \"\$OFFS\" | grep -q systemMessage"
# 금지어 쪽이 실패해도 spec 차단은 나가야 한다. 훅 사본 옆 목록을 읽을 수 없게 만들어 banned_parse 를 실패시킨다.
FAILW="$(mktemp -d)"; cp -r "$HERE/hooks" "$FAILW/hooks"; cp "$HERE/korean-banned-words.md" "$FAILW/"; chmod a-r "$FAILW/korean-banned-words.md"
check "금지어 검사가 실패해도 spec 차단은 나간다" "printf '{\"cwd\":\"%s\",\"session_id\":\"s9\"}' '$G4' | bash '$FAILW/hooks/stop_gates.sh' | grep -q '\"block\"'"
chmod u+r "$FAILW/korean-banned-words.md"
```

윈도우 NTFS 에서는 `chmod a-r` 이 읽기를 막지 않을 수 있다. 실행자는 마지막 단언이 실제로 금지어 실패 경로를 밟는지 `bash -x` 로 한 번 확인하고, 밟지 않으면 `banned_parse` 를 실패시키는 다른 입력(예: 목록 파일 내용을 표 머리가 없는 한 줄로 바꾼다)으로 바꾼다. 어느 입력을 썼는지 테스트 주석에 적는다.

`[rules-nudge-sessionstart]` 블록 끝에 추가한다.

```bash
JSU() { printf '{"session_id":"%s","hook_event_name":"SessionStart","source":"%s"}' "$1" "$2"; }
printf '%s' "$(JSU st1 startup)" | bash "$CSTA"
check "startup 이면 세션 시작 표시를 남긴다"   "[ -f \"\$TMPDIR/disciplined-coder/session-start-st1\" ]"
touch -d '2000-01-01' "$TMPDIR/disciplined-coder/session-start-st1"
printf '%s' "$(JSU st1 startup)" | bash "$CSTA"
check "있는 표시는 다시 쓰지 않는다"          "[ ! \"\$TMPDIR/disciplined-coder/session-start-st1\" -nt \"\$HERE/README.md\" ]"
printf '%s' "$(JSU st2 resume)" | bash "$CSTA"
check "resume 에서는 표시를 새로 만들지 않는다" "[ ! -e \"\$TMPDIR/disciplined-coder/session-start-st2\" ]"
```

`[hooks 배선]` 블록에 추가한다.

```bash
check "Stop 은 훅 하나만 실행한다" "[ \"\$(json_run 'import json,sys; print(sum(len(g[\"hooks\"]) for g in json.load(sys.stdin)[\"hooks\"][\"Stop\"]))' < '$HJ')\" = 1 ]"
check "stop_gates.sh 는 stdin 을 read 로 읽는다" "grep -qF \"IFS= read -r -d ''\" '$HERE/hooks/stop_gates.sh'"
```

`scripts/test_docs_drift.sh` 105행을 바꾼다.

```bash
STOPH="$HERE/hooks/stop_gates.sh"
```

- [ ] **Step 2: 테스트가 실패하는지 확인한다**

Run: `bash scripts/test_hooks.sh 2>&1 | grep 'FAIL:' | head -30`
Expected: `stop_gates.sh` 가 없어 `[stop]`·`[stop 겹]`·`[차단 사유의 셸·JSON 안전]` 단언과 새 단언이 FAIL.

- [ ] **Step 3: `_stop_preamble.sh` 의 git 호출을 하나로 줄인다**

19-26행을 아래로 바꾼다. `--show-toplevel` 하나가 저장소 여부와 루트를 함께 알려 준다. 성공한 경우에도 git 이 stderr 에 경고를 낼 수 있으므로 출력의 마지막 줄만 경로로 쓴다.

```bash
  gitout="$(git rev-parse --show-toplevel 2>&1)" || {
    case "$gitout" in *'not a git repository'*|*'must be run in a work tree'*) exit 0 ;; esac
    printf '{"systemMessage":"%s"}\n' "$(escape_for_json "disciplined-coder: git 을 읽지 못해 $1 — ${gitout%%$'\n'*}")"
    exit 0
  }
  # 성공해도 git 이 stderr 에 경고 줄을 낼 수 있다. 경로는 마지막 줄이다.
  root="${gitout##*$'\n'}"
  [ -n "$root" ] || exit 0
  cd "$root" 2>/dev/null || exit 0
```

2-3행 머리 주석의 "Stop 훅 둘(spec_review_stop.sh·doc_word_stop.sh)의 공통 머리" 를 "Stop 진입 스크립트(stop_gates.sh)의 머리" 로 바꾼다. 13행 `local cwd gitout root` 는 그대로 둔다.

- [ ] **Step 4: `stop_gates.sh` 를 만든다**

두 검사를 함수로 한 파일에 둔다. 소비자가 이 파일 하나뿐이라 따로 라이브러리로 나누지 않는다(`YAGNI`).

```bash
#!/usr/bin/env bash
# Stop: 턴 끝의 검사 둘을 한 프로세스로 실행한다. 미리뷰 spec·plan 을 차단하는 하드 게이트와, 커밋되지
# 않은 산출물 문서의 금지 표현을 사용자에게 알리는 검사다. 따로 실행하면 답마다 bash 둘과 git 일곱 번이
# 들었다. 여기서는 bash 하나와 git 세 번(rev-parse·status·diff-tree)으로 끝낸다. 루프가드: stop_hook_active.
# jq 비의존. git 이 없거나 저장소가 아니면 FAIL-OPEN(작업불능 방지 — 알려진 한계).
set -euo pipefail
HOOKDIR="${BASH_SOURCE[0]%/*}"; [ "$HOOKDIR" != "${BASH_SOURCE[0]}" ] || HOOKDIR=.
. "$HOOKDIR/_hook_input.sh"     # 훅 입력 읽기(json_str·slash_norm) 공유
. "$HOOKDIR/_spec_marker.sh"    # 마커 판정과 경로 술어 공유
. "$HOOKDIR/_json_escape.sh"    # JSON 문자열 이스케이프 공유
. "$HOOKDIR/_stop_preamble.sh"  # 루프가드·cwd·저장소 루트 이동 공유
IFS= read -r -d '' INPUT || true

# spec·plan 하드 게이트. 탐지: git 신규(미추적·추가) spec/plan + HEAD 커밋이 추가한 spec/plan 중 마지막
# 줄이 terminal 마커가 아닌 것(HEAD 쪽은 같은 턴에 커밋해 게이트를 비켜 가는 것을 막는다). 기존 파일
# 수정은 제외한다. 이 세션이 시작되기 전에 만든 미추적 초안은 보지 않는다(에이전트원칙 FOCUSED). 버려 둔
# 초안 하나가 그 작업 트리의 모든 세션을 턴마다 차단하던 것을 막는다. 시작 시각은 SessionStart(startup)
# 에서 rules_nudge_sessionstart.sh 가 남긴 표시 파일의 수정 시각이고, 표시가 없으면 전부 본다.
# HEAD 커밋 쪽에는 이 거르기를 두지 않는다 — 커밋은 이 턴의 일이다.
spec_gate_check() {  # → SPEC_BLOCK_REASON
  local entry f u dup sid since="" list=""
  local -a unreviewed=()
  SPEC_BLOCK_REASON=""
  json_str session_id sid; sid="${sid//[^A-Za-z0-9_-]/}"
  if [ -n "$sid" ] && [ -f "${TMPDIR:-/tmp}/disciplined-coder/session-start-$sid" ]; then
    since="${TMPDIR:-/tmp}/disciplined-coder/session-start-$sid"
  fi
  for entry in ${STATUS+"${STATUS[@]}"}; do
    f="${entry:3}"; [ -n "$f" ] || continue
    # 신규(미추적 ??·추가 A)만 하드게이트 — 기존 spec 수정(상태 strip 등)엔 안 건다(넛지는 PostToolUse가).
    case "${entry:0:2}" in '??'|A*) ;; *) continue ;; esac
    path_is_specplan "$f" || continue
    [ -f "$f" ] || continue
    if [ -n "$since" ] && [ ! "$f" -nt "$since" ]; then continue; fi
    marker_is_terminal "$f" || unreviewed+=("$f")
  done
  # 경계는 직전 커밋 하나다. 과거 이력을 소급 차단하지 않는다(훅 도입 전 무마커 레거시가 있는 레포에서
  # 상시 차단 → 게이트 영구 off 라는 더 나쁜 드리프트를 피한다). 루트 커밋·머지 커밋·다중 커밋 우회는
  # 알려진 한계다.
  while IFS= read -r -d '' f; do
    [ -n "$f" ] || continue
    path_is_specplan "$f" || continue
    [ -f "$f" ] || continue
    dup=0; for u in ${unreviewed+"${unreviewed[@]}"}; do [ "$u" = "$f" ] && { dup=1; break; }; done
    [ "$dup" = 1 ] && continue
    marker_is_terminal "$f" || unreviewed+=("$f")
  done < <(git diff-tree -z --no-commit-id --name-only --diff-filter=A -r HEAD 2>/dev/null || true)
  [ "${#unreviewed[@]}" -gt 0 ] || return 0
  for u in "${unreviewed[@]}"; do list="$list
  - $u"; done
  SPEC_BLOCK_REASON="미리뷰 spec/plan:$list
${SPEC_REVIEW_INSTRUCTION} 반영을 마친 뒤 종료하라."
}

# 금지 표현 알림. 앞의 두 겹(Write·Edit 를 막는 Pre 훅, 셸 대상을 보는 Post 훅)은 도구를 보므로 명령줄에
# 대상이 안 나타나면 못 본다. 여기는 git 이 바뀌었다고 말하는 파일을 무엇이 바꿨는지와 무관하게 본다.
# 막지 않는다. 턴이 끝나는 것을 막으면 고치지 못하는 상황에서 빠져나갈 길이 없다. 막지 않으면 Claude 에게
# 닿는 통로가 없으므로 알림은 사용자에게 하는 말로 쓴다. 같은 세션에 같은 알림은 한 번만 낸다 — 커밋되지
# 않은 옛 파일 하나 때문에 같은 알림이 30시간 동안 137번 뜬 세션이 있었다(2026-09-27).
# 이 검사가 실패해도 spec 차단은 나가야 하므로 실패하는 곳마다 return 0 으로 물러난다.
# 파이썬이 없으면 banned_report 가 빈 결과를 내어 알림 없이 끝난다(2026-09-30 사용자 결정).
doc_word_gate_check() {  # → DOC_WORD_MSG
  local entry f files="" one report="" sid sum seen_dir work
  DOC_WORD_MSG=""
  for entry in ${STATUS+"${STATUS[@]}"}; do
    f="${entry:3}"; [ -n "$f" ] || continue
    path_is_banned_target "$f" || continue   # 제외 규칙은 _spec_marker.sh 가 소유한다.
    [ -f "$f" ] || continue
    files="${files}${f}
"
  done
  [ -n "$files" ] || return 0
  . "$HOOKDIR/_banned_words.sh" || return 0            # 표 파싱과 본문 맞추기 공유
  . "$HOOKDIR/../scripts/_json_valid.sh" || return 0   # 파이썬 인터프리터 고르기
  work="$(mktemp -d 2>/dev/null)" || return 0
  if ! banned_parse "$HOOKDIR/../korean-banned-words.md" "$work/pairs" "$work/toks" "$work/excl" 2>/dev/null \
     || [ ! -s "$work/toks" ]; then
    rm -rf "$work"; return 0
  fi
  while IFS= read -r f; do
    [ -n "$f" ] || continue
    LC_ALL=C grep -qFf "$work/toks" "$f" || continue   # 빠른 거르기 — 파이썬을 아낀다
    one="$(banned_report "$work/pairs" "$f" "$work/excl" || true)"
    [ -n "$one" ] || continue
    report="${report}${f}
${one}
"
  done <<EOF
$files
EOF
  rm -rf "$work"
  [ -n "$report" ] || return 0
  json_str session_id sid
  sid="${sid//[^A-Za-z0-9_-]/}"
  if [ -n "$sid" ]; then
    seen_dir="${TMPDIR:-/tmp}/disciplined-coder-doc-word"
    mkdir -p "$seen_dir" 2>/dev/null || true
    sum="$(printf '%s' "$report" | cksum)"; sum="${sum%% *}"
    if [ -f "$seen_dir/$sid" ] && [ "$(cat "$seen_dir/$sid" 2>/dev/null)" = "$sum" ]; then return 0; fi
    printf '%s' "$sum" > "$seen_dir/$sid" 2>/dev/null || true
  fi
  DOC_WORD_MSG="disciplined-coder: 커밋되지 않은 산출물 문서에 「금지 표현」 목록의 말이 남아 있다. 아래는 파일마다 검출한 말과 그 대체어다. 어느 도구가 고쳤는지와 무관하게 git 이 바뀌었다고 알린 파일을 본 결과이고, 코드 블록과 백틱 안은 검사하지 않았다. 이 알림은 사용자에게만 보이므로 고치려면 Claude 에게 요청한다.

$report"
}

SPEC_ON=1; [ "${DISCIPLINED_CODER_REVIEW_GATE:-on}" = "off" ] && SPEC_ON=0
WORD_ON=1; [ "${DISCIPLINED_CODER_REPLY_CHECK:-on}" = "off" ] && WORD_ON=0
# 목록이 없다는 사실은 Pre 훅이 Write·Edit 로 .md 를 쓸 때만 알린다(알려진 한계).
[ -f "$HOOKDIR/../korean-banned-words.md" ] || WORD_ON=0
[ "$SPEC_ON$WORD_ON" = "00" ] && exit 0

stop_enter_repo "턴 끝 검사(spec 리뷰 게이트·금지 표현)를 하지 못했다"

# -z: NUL 종료 raw 경로(공백·비ASCII 안전). --no-renames: 리네임을 del+add 로 분해한다. 두 검사가 같은
# 목록을 쓰므로 한 번만 부른다.
STATUS=()
while IFS= read -r -d '' e; do STATUS+=("$e"); done \
  < <(git status -z --porcelain --untracked-files=all --no-renames 2>/dev/null || true)

reason=""; msg=""
if [ "$SPEC_ON" = 1 ]; then spec_gate_check; reason="$SPEC_BLOCK_REASON"; fi
if [ "$WORD_ON" = 1 ]; then doc_word_gate_check || true; msg="$DOC_WORD_MSG"; fi

if [ -n "$reason" ] && [ -n "$msg" ]; then
  printf '{"decision":"block","reason":"%s","systemMessage":"%s"}\n' "$(escape_for_json "$reason")" "$(escape_for_json "$msg")"
elif [ -n "$reason" ]; then
  printf '{"decision":"block","reason":"%s"}\n' "$(escape_for_json "$reason")"
elif [ -n "$msg" ]; then
  printf '{"systemMessage":"%s"}\n' "$(escape_for_json "$msg")"
fi
exit 0
```

`for entry in ${STATUS+"${STATUS[@]}"}` 는 경로에 공백이 있어도 원소 단위로 돈다. 따옴표 확장이 원소를 보존하기 때문이다.

- [ ] **Step 5: 세션 시작 표시를 startup 에만 남긴다**

`hooks/rules_nudge_sessionstart.sh` 19행 뒤에 추가한다. resume·compact 에서 만들지 않는 이유는, 표시가 사라진 재개 세션이 재개 시각으로 표시를 새로 만들면 중단 전에 쓴 초안이 게이트에서 빠지기 때문이다. 표시가 없으면 게이트가 전부 보므로 그쪽이 안전하다.

```bash
# spec 게이트(stop_gates.sh)가 쓰는 세션 시작 표시. startup 에서만, 없을 때만 만든다.
json_str source src
ssid="${sid//[^A-Za-z0-9_-]/}"
if [ "$src" = "startup" ] && [ -n "$ssid" ] && [ ! -e "$mdir/session-start-$ssid" ]; then
  mkdir -p "$mdir" 2>/dev/null && : > "$mdir/session-start-$ssid" 2>/dev/null || true
fi
```

2-8행 머리 주석 끝에 "spec 게이트가 쓰는 세션 시작 표시도 여기서 남긴다. startup 에서만, 이미 있으면 다시 쓰지 않는다." 를 추가한다.

- [ ] **Step 6: 배선과 README 를 바꾼다**

`hooks/hooks.json` 의 Stop 을 아래로 바꾼다.

```json
    "Stop": [
      {
        "hooks": [
          { "type": "command", "command": "bash \"${CLAUDE_PLUGIN_ROOT}/hooks/stop_gates.sh\"" }
        ]
      }
    ]
```

`README.md` 의 세 곳을 고친다.

- **hook 표** — Stop 두 행을 한 행으로 합친다: `| Stop | \`hooks/stop_gates.sh\` | 이 세션에 새로 생긴 미리뷰 spec·plan이 남은 채 턴이 끝나는 것을 차단하고, 커밋되지 않은 산출물 \`.md\`에 금지 표현이 남으면 사용자에게 알린다 | 차단 |`
- **끄는 법** — `DISCIPLINED_CODER_REVIEW_GATE=off` 불릿의 `spec_review_stop.sh` 를 "`stop_gates.sh`의 spec 검사"로, `DISCIPLINED_CODER_REPLY_CHECK=off` 불릿의 `doc_word_stop.sh` 를 "`stop_gates.sh`의 금지 표현 검사"로 바꾼다.
- **Stop 하드 게이트** — 「차단되었을 때 푸는 법」 첫 불릿의 첫 문장을 "`docs/superpowers/specs/`나 `docs/superpowers/plans/`에 이 세션이 시작된 뒤 새 `.md`가 생긴 채 턴을 끝내려 하면 차단하고 `review-specs` 수행을 지시한다. 세션이 시작되기 전부터 있던 미추적 초안은 차단하지 않는다."로 바꾼다.

- [ ] **Step 7: 쓰이지 않게 된 Stop 스크립트를 지운다**

`grep -rn 'spec_review_stop\|doc_word_stop' hooks scripts skills README.md CLAUDE.md` 로 남은 참조를 찾아 `stop_gates.sh` 로 바꾼다. `docs/` 아래 기록과 spec 은 고치지 않는다. 참조가 없어진 것을 확인한 뒤 `hooks/spec_review_stop.sh` 와 `hooks/doc_word_stop.sh` 를 지운다.

- [ ] **Step 8: 전체 테스트를 실행한다**

Run: 저장소 CLAUDE.md 「변경 뒤 실행」의 명령
Expected: `ALL PASS`

---

### Task 3: SessionStart matcher 를 나누고 규칙 넛지를 보강한다

**Files:**
- Modify: `hooks/hooks.json` (SessionStart)
- Modify: `hooks/rules_nudge_pretooluse.sh:52-63`
- Modify: `hooks/update_check_sessionstart.sh:2`, `hooks/rules_nudge_sessionstart.sh:2`
- Modify: `README.md` (hook 표의 update_check·rules_nudge 세 행)
- Test: `scripts/test_hooks.sh` (`[hooks 배선]`·`[rules-nudge-pre]`)

**Interfaces:**
- Produces: SessionStart 세 그룹 — scaffold `startup|resume|clear`, update_check `startup`(timeout 150초), rules_nudge_sessionstart `startup|resume|clear|compact`.

- [ ] **Step 1: 실패하는 테스트를 쓴다**

`[hooks 배선]` 블록에 추가한다.

```bash
ssm() { json_run 'import json,sys; d=json.load(sys.stdin)["hooks"]["SessionStart"]; print([g.get("matcher","") for g in d for h in g["hooks"] if sys.argv[1] in h["command"]][0])' "$1" < "$HJ"; }
check "갱신 확인은 startup 에서만 실행한다"   "[ \"\$(ssm update_check_sessionstart.sh)\" = 'startup' ]"
check "넛지 표시는 compact 에도 지운다"       "ssm rules_nudge_sessionstart.sh | grep -qw compact"
check "스캐폴드는 compact 에 실행하지 않는다" "! ssm scaffold.sh | grep -qw compact"
```

`[rules-nudge-pre]` 블록의 `NUDGE_WK=` 줄 뒤에 추가한다.

```bash
NUDGE_DD="$(printf '%s' "$NUDGE_OUT" | sed -n 's/.*조항마다의 근거는 \(.*\) 에 있다\. 에이전트원칙의 사본은.*/\1/p')"
check "넛지에서 조항 근거 경로가 뽑힌다"   "[ -n \"\$NUDGE_DD\" ]"
check "그 근거 경로에 파일이 실재한다"     "[ -f \"\$NUDGE_DD\" ]"
```

- [ ] **Step 2: 테스트가 실패하는지 확인한다**

Run: `bash scripts/test_hooks.sh 2>&1 | grep 'FAIL:'`
Expected: `갱신 확인은 startup…`, `넛지 표시는 compact…`, `넛지에서 조항 근거 경로가 뽑힌다`, `그 근거 경로에 파일이 실재한다` 넷이 FAIL. `스캐폴드는 compact…` 는 지금도 통과한다.

- [ ] **Step 3: hooks.json SessionStart 를 세 그룹으로 나눈다**

```json
    "SessionStart": [
      {
        "matcher": "startup|resume|clear",
        "hooks": [
          { "type": "command", "command": "bash \"${CLAUDE_PLUGIN_ROOT}/scripts/scaffold.sh\"" }
        ]
      },
      {
        "matcher": "startup",
        "hooks": [
          { "type": "command", "command": "bash \"${CLAUDE_PLUGIN_ROOT}/hooks/update_check_sessionstart.sh\"", "timeout": 150 }
        ]
      },
      {
        "matcher": "startup|resume|clear|compact",
        "hooks": [
          { "type": "command", "command": "bash \"${CLAUDE_PLUGIN_ROOT}/hooks/rules_nudge_sessionstart.sh\"" }
        ]
      }
    ],
```

`timeout` 150초는 Task 4 의 claude CLI 두 명령 상한(각 60초)과 원격 조회(2초)를 합친 값보다 크게 잡은 값이다. `hooks/update_check_sessionstart.sh` 2행의 `SessionStart(startup|resume|clear)` 를 `SessionStart(startup)` 로, `hooks/rules_nudge_sessionstart.sh` 2행의 `SessionStart(startup|resume|clear)` 를 `SessionStart(startup|resume|clear|compact)` 로 바꾼다.

- [ ] **Step 4: 넛지에 domain-discipline.md 경로를 추가한다**

`hooks/rules_nudge_pretooluse.sh` 55행을 아래 세 줄로 바꾼다.

```bash
PLUGIN_DIR="$(cd "$DIR/.." 2>/dev/null && pwd)"
WK_PATH="$PLUGIN_DIR/skills/lens-readability/domain-korean.md"
DD_PATH="$PLUGIN_DIR/skills/lens-fit/domain-discipline.md"
```

60행 `fi` 뒤에 추가한다.

```bash
if [ -f "$DD_PATH" ]; then ddwhere="조항마다의 근거는 $DD_PATH 에 있다."; else ddwhere=""; fi
```

63행을 아래로 바꾼다. `$ddwhere` 는 `$where` 앞에 둔다. 뒤에 두면 기존 테스트의 `NUDGE_WK` 추출식이 탐욕 매칭으로 마지막 "에 있다." 까지 잡아 경로가 깨지고, `NUDGE_CANON` 추출식은 원칙 문장 바로 뒤에 "한국어"가 오기를 요구한다.

```bash
msg="🧑‍💻 이 세션의 첫 도구 호출이다 — $ddwhere $where $wkwhere 서브에이전트에는 에이전트원칙이 안 실리므로 그 경로를 프롬프트에 직접 넣어라. 레포 안에서 실행되는 워크플로는 이 사본 대신 그 레포의 에이전트원칙을 넣는다 — 상세는 disciplined-coder dispatching-lenses 가 소유한다. 넛지일 뿐 차단은 아니다."
```

52-54행 주석 끝에 "에이전트원칙 3행은 두 근거 파일을 저장소 상대 경로로 가리켜 다른 프로젝트에서는 열리지 않는다. 그 절대경로를 여기서 알린다." 를 추가한다.

- [ ] **Step 5: README 표를 고친다**

- **update_check 행** — "하는 일" 끝에 "새로 켤 때(startup)만 확인한다. 자동 갱신을 꺼 두었으면 아무것도 하지 않는다" 를 추가한다.
- **rules_nudge_pretooluse 행** — "세션의 첫 파일 편집 전에" 를 "세션의 첫 Write·Edit·Bash 호출 전에" 로, "원칙 사본과 `domain-korean.md`의 절대경로" 를 "원칙 사본과 `domain-korean.md`와 `domain-discipline.md`의 절대경로" 로 바꾼다.
- **rules_nudge_sessionstart 행** — "하는 일" 끝에 "대화가 압축(compact)된 뒤에도 지운다. startup 에서는 spec 게이트가 쓰는 세션 시작 표시도 남긴다" 를 추가한다.

- [ ] **Step 6: 전체 테스트와 매니페스트 검사를 실행한다**

Run: 저장소 CLAUDE.md 「변경 뒤 실행」의 명령, 그다음 `claude plugin validate ./`
Expected: `ALL PASS`, validate 는 `version` 경고 하나.

---

### Task 4: 갱신 확인이 autoUpdate:false 를 존중하고 상한과 잠금을 갖게 한다

**Files:**
- Modify: `scripts/_ensure_current.sh:16,27,33-54,92-108`
- Modify: `README.md` (「세션 시작에 바꾸는 전역 설정」의 플러그인 갱신 불릿)
- Test: `scripts/test_scaffold.sh` (`[install-current]` 블록들)

**Interfaces:**
- Consumes: `~/.claude/plugins/known_marketplaces.json` 의 `<마켓 이름>.autoUpdate`, `~/.claude/settings.json` 의 `extraKnownMarketplaces.<마켓 이름>.autoUpdate`.
- Produces: 잠금 폴더 `~/.claude/disciplined-coder/update.lock`(갱신 명령이 도는 동안만 있다).

- [ ] **Step 1: 실패하는 테스트를 쓴다**

`scripts/test_scaffold.sh` 의 install-current 블록들 뒤에 추가한다. `uc_fixture` 는 237-255행 그대로 쓴다. 변수 이름은 기존 `H<숫자>` 와 겹치지 않게 `HAU` 로 시작한다.

```bash
HAU1="$(mktemp -d)"; uc_fixture "$HAU1" "$A40" 0 "$B40" > /dev/null
printf '{ "chshin-tools": { "autoUpdate": false, "source": { "source": "github", "repo": "chshin84/disciplined-coder" } } }\n' > "$HAU1/.claude/plugins/known_marketplaces.json"
OUTAU1="$(run_uc "$HAU1")"
echo "[install-current] autoUpdate 를 false 로 두면 확인도 알림도 하지 않는다"
check "갱신을 실행하지 않는다"   "[ ! -f '$HAU1/args.txt' ]"
check "원격도 읽지 않는다"       "[ ! -f '$HAU1/curl-args.txt' ]"
check "아무것도 출력하지 않는다" "[ -z \"\$OUTAU1\" ]"

HAU2="$(mktemp -d)"; uc_fixture "$HAU2" "$A40" 0 "$B40" > /dev/null
mkdir -p "$HAU2/.claude/disciplined-coder/update.lock"
run_uc "$HAU2" > /dev/null
echo "[install-current] 다른 창이 갱신 중이면 이 창은 갱신하지 않는다"
check "잠금이 있으면 갱신을 실행하지 않는다"     "[ ! -f '$HAU2/args.txt' ]"
touch -d '2000-01-01' "$HAU2/.claude/disciplined-coder/update.lock"
run_uc "$HAU2" > /dev/null
check "10분 지난 잠금은 치우고 그 실행은 물러난다" "[ ! -f '$HAU2/args.txt' ] && [ ! -e '$HAU2/.claude/disciplined-coder/update.lock' ]"
run_uc "$HAU2" > /dev/null
check "다음 실행이 갱신한다"                     "[ -f '$HAU2/args.txt' ]"
check "끝나면 잠금을 푼다"                       "[ ! -e '$HAU2/.claude/disciplined-coder/update.lock' ]"

HAU3="$(mktemp -d)"; uc_fixture "$HAU3" "$A40" 124 "$B40" > /dev/null
OUTAU3="$(run_uc "$HAU3")"
echo "[install-current] 시간 초과도 같은 커밋으로는 다시 시도하지 않는다"
check "시간 초과를 알린다"                     "printf '%s' \"\$OUTAU3\" | grep -qF '60초'"
check "update.stuck 을 남긴다"                 "[ -f '$HAU3/.claude/disciplined-coder/update.stuck' ]"
```

- [ ] **Step 2: 테스트가 실패하는지 확인한다**

Run: `bash scripts/test_scaffold.sh 2>&1 | grep 'FAIL:'`
Expected: 위 단언 가운데 autoUpdate·잠금·`60초` 단언이 FAIL.

- [ ] **Step 3: 파이썬 프로그램이 autoUpdate 를 함께 읽게 한다**

`scripts/_ensure_current.sh` 33-51행 `prog` 를 아래로 바꾼다. 어느 한쪽이라도 명시적으로 `false` 이면 끈 것으로 본다. Claude Code 가 두 곳 중 어느 쪽을 우선하는지는 문서로 확인하지 못했으므로 가정이다. 둘 다 존중하는 쪽이 domain-plugin 「사용자 결정 존중」에 맞는다.

```python
import json,sys,io,os
d=json.load(io.open(sys.argv[1],encoding="utf-8")).get("plugins",{})
for k,v in d.items():
    if k.startswith("disciplined-coder@"):
        mk=k.split("@",1)[1]
        for e in v:
            s=e.get("gitCommitSha")
            if s:
                url=ref=au=""
                if os.path.isfile(sys.argv[2]):
                    m=json.load(io.open(sys.argv[2],encoding="utf-8")).get(mk,{})
                    if m.get("autoUpdate") is False: au="off"
                    src=m.get("source",{})
                    ref=src.get("ref","")
                    if src.get("source")=="github" and src.get("repo"):
                        url="https://github.com/"+src["repo"]+".git"
                    elif str(src.get("url","")).startswith("https://"):
                        url=src["url"]
                if os.path.isfile(sys.argv[3]):
                    x=json.load(io.open(sys.argv[3],encoding="utf-8")).get("extraKnownMarketplaces",{})
                    if isinstance(x,dict) and isinstance(x.get(mk),dict) and x[mk].get("autoUpdate") is False: au="off"
                print("|".join([k,s,url,ref,au])); sys.exit(0)
sys.exit(1)
```

52-54행을 아래로 바꾼다.

```bash
  out="$(json_run "$prog" "$inst" "$home/plugins/known_marketplaces.json" "$home/settings.json" 2>/dev/null)" || return 0
  IFS='|' read -r id sha url ref au <<< "$out"
  [ -n "$id" ] && [ -n "$sha" ] || return 0
  # 사용자가 자동 갱신을 꺼 두었으면 확인도 알림도 하지 않는다(2026-09-30 사용자 결정).
  [ "$au" = "off" ] && return 0
```

27행 `local` 목록 끝에 ` au lock tmo` 를 추가한다. 16행 뒤에 아래 세 줄을 추가한다.

```bash
# - 배포처나 설정에서 autoUpdate 를 false 로 두었으면 아무것도 하지 않는다.
# - 두 갱신 명령에는 60초 상한과 잠금을 둔다. 시간 초과도 다른 실패와 같이 update.stuck 에 적는다 —
#   늘 멈추는 망에서 startup 마다 최대 120초를 기다리지 않게 한다.
```

- [ ] **Step 4: 갱신 명령에 잠금과 시간 상한을 둔다**

92-108행 `else` 갈래(갱신 시도)를 아래로 바꾼다.

```bash
    else
      # 창 둘이 동시에 열리면 한 창만 옮긴다. 잠금은 폴더 만들기로 잡는다. 10분이 지난 잠금은 끊긴 창이
      # 남긴 것으로 보고 치우되, 치운 창은 그 실행에서 물러난다. 치우고 곧바로 잡으면 그 사이에 다른 창이
      # 끼어들어 둘 다 잡을 수 있다(_managed_block.sh 71-73행과 같은 이유). 다음 세션이 잡는다.
      lock="$kdir/update.lock"
      if [ -d "$lock" ] && [ -n "$(find "$lock" -maxdepth 0 -mmin +10 2>/dev/null)" ]; then
        rmdir "$lock" 2>/dev/null || true
        return 0
      fi
      mkdir "$lock" 2>/dev/null || return 0
      # 두 명령에 60초 상한을 둔다. GNU timeout 만 쓴다 — 윈도우 System32 의 timeout.exe 는 뜻이 다른
      # 명령이고 --version 을 모른다. GNU timeout 이 없으면(맥 기본) 상한 없이 실행한다.
      tmo=""; timeout --version >/dev/null 2>&1 && tmo="timeout 60"
      # 로컬 사본이 옛 커밋이면 plugin update 가 옮길 새 버전이 없으므로 사본부터 원격에 맞춘다.
      rc=0
      $tmo "$bin" plugin marketplace update "$name" >/dev/null 2>&1 || rc=$?
      [ "$rc" -eq 0 ] && { $tmo "$bin" plugin update "$id" >/dev/null 2>&1 || rc=$?; }
      rmdir "$lock" 2>/dev/null || true
      if [ "$rc" -eq 0 ]; then
        restart=1
        rm -f "$kdir/update.stuck"
        printf '%s\n' "$head" > "$kdir/update.seen"
        notes="${notes:+$notes
}설치본을 원격에 맞춰 옮겼다(${sha:0:7} → ${head:0:7}). 클로드 코드는 켤 때 플러그인을 읽으므로 이 세션은 옛 버전으로 실행된다."
      else
        printf '%s\n' "$head" > "$kdir/update.stuck"
        if [ "$rc" -eq 124 ]; then
          notes="${notes:+$notes
}설치본이 원격보다 뒤처졌는데 갱신 명령이 60초 안에 끝나지 않아 멈췄다(${sha:0:7} → ${head:0:7}). 원격에 새 커밋이 생기기 전에는 다시 시도하지 않는다. 직접 실행하라: $bin plugin marketplace update $name && $bin plugin update $id"
        else
          notes="${notes:+$notes
}설치본이 원격보다 뒤처졌는데 옮기지 못했다(${sha:0:7} → ${head:0:7}, 종료 코드 $rc). 직접 실행하라: $bin plugin marketplace update $name && $bin plugin update $id"
        fi
      fi
    fi
```

`$tmo` 는 따옴표 없이 두어 `timeout 60` 두 낱말로 펼쳐지게 한다. 테스트의 claude 스텁은 `exit 124` 로 시간 초과를 흉내 낸다.

- [ ] **Step 5: README 의 갱신 설명을 고친다**

「세션 시작에 바꾸는 전역 설정」의 플러그인 갱신 불릿 첫머리에 "마켓플레이스나 설정에서 `autoUpdate`를 `false`로 두었으면 확인하지 않는다." 를 추가하고, "뒤처졌으면 `claude plugin marketplace update`와 `claude plugin update`를 차례로 실행하고" 뒤에 "(각 60초 상한, 창 여럿이 동시에 열리면 한 창만)" 을 추가한다.

- [ ] **Step 6: 전체 테스트를 실행한다**

Run: 저장소 CLAUDE.md 「변경 뒤 실행」의 명령
Expected: `ALL PASS`

---

### Task 5: 스캐폴드가 바뀐 것이 없으면 전역 파일을 다시 쓰지 않게 한다

**Files:**
- Modify: `scripts/_managed_block.sh:10-20,178-198`
- Modify: `scripts/scaffold.sh:27-39,51-64,68,169-170`
- Modify: `scripts/_ensure_autoupdate.sh:7,69`
- Modify: `README.md` (「세션 시작에 바꾸는 전역 설정」 머리 문단)
- Test: `scripts/test_scaffold.sh`

**Interfaces:**
- Produces: `managed_block_inject` 리턴의 뜻은 그대로다(0=넣었거나 이미 같다, 1=락 실패, 2=변환 실패).
- Produces: autoUpdate 사본 이름 `<파일>.<YYYYmmdd-HHMMSS>.bak`.

- [ ] **Step 1: 실패하는 테스트를 쓴다**

`[fresh-pc]` 블록 끝에 추가한다.

```bash
touch -d '2000-01-01' "$UC"; REF5="$(mktemp)"; touch -d '2001-01-01' "$REF5"
run "$H1" "$P1" > /dev/null
check "같은 블록이면 전역 CLAUDE.md 를 다시 쓰지 않는다" "[ ! '$UC' -nt '$REF5' ]"
touch -d '2000-01-01' "$K/agent-principles.md"
run "$H1" "$P1" > /dev/null
check "같은 원칙 사본은 다시 복사하지 않는다"            "[ ! '$K/agent-principles.md' -nt '$REF5' ]"
```

stderr 만 받던 경고 단언을 stdout 으로 옮긴다. 353행 `ERR7=`, 421행 `ERR10=`, 479행 `ERR19=` 의 `2>&1 >/dev/null` 을 `2>/dev/null` 로 바꾼다. 셋 다 경고가 이제 stdout 으로 나오기 때문이다. `grep -n '2>&1 >/dev/null' scripts/test_scaffold.sh` 로 같은 형태가 더 있는지 확인하고, 그 단언이 Step 7 이 옮기는 경고(비관리 파일·구 관리파일·고아 마커·락)를 보는 것이면 같이 바꾼다.

`[marketplace-autoupdate]` 픽스처의 `settings.json.bak` 단언을 찾아(`grep -n 'json.bak' scripts/test_scaffold.sh`) 시각 붙은 이름의 글롭으로 바꾼다. 없어야 한다는 단언은 `! ls '<폴더>'/settings.json.*.bak >/dev/null 2>&1` 로, 있어야 한다는 단언은 `ls '<폴더>'/settings.json.*.bak >/dev/null 2>&1` 로 쓴다.

- [ ] **Step 2: 테스트가 실패하는지 확인한다**

Run: `bash scripts/test_scaffold.sh 2>&1 | grep 'FAIL:'`
Expected: 새 단언 둘, stdout 으로 옮긴 ERR7·ERR10·ERR19 단언, `.bak` 글롭 단언이 FAIL.

- [ ] **Step 3: managed_block_inject 가 같으면 물러나고 한 번에 교체하게 한다**

`scripts/_managed_block.sh` 178-198행 함수를 아래로 바꾼다.

```bash
managed_block_inject() {
  local uc="$1" begin="$2" end="$3" body tmp norm lock tok cur rest
  body="$(cat)"
  [ -e "$uc" ] || : > "$uc"
  # 같은 블록이 하나만 들어 있고 고아 주석도 없으면 손대지 않는다. 매 세션 다시 쓰면 그 사이에
  # 시작하는 다른 창이 블록 없는 파일을 읽을 수 있고, 락과 임시 파일에 프로세스 열 개 남짓이 든다.
  cur="$(<"$uc")"
  if [[ $cur == *"$begin"$'\n'"$body"$'\n'"$end"* ]] && [[ $cur != *"$MANAGED_ORPHAN"* ]]; then
    rest="${cur#*"$begin"}"
    [[ $rest == *"$begin"* ]] || return 0
  fi

  lock="$uc.lock"
  tok="$(managed_block_lock "$lock")" || return 1
  tmp="$(mktemp "$uc.XXXXXX")"; norm="$(mktemp "$uc.XXXXXX")"
  # 중간에 죽어도 임시 파일과 락을 남기지 않는다.
  trap 'rm -f "$tmp" "$norm"; managed_block_unlock "$lock" "$tok"' RETURN
  # 걷어내기와 같은 이유로 두 변환의 종료 코드를 각각 본다.
  awk -v b="$begin" -v e="$end" -v o="$MANAGED_ORPHAN" -v f="$uc" -v tag="$MANAGED_TAG" "$MANAGED_STRIP_AWK" "$uc" > "$tmp" || return 2
  awk "$MANAGED_TRIM_AWK" "$tmp" > "$norm" || return 2
  # 완성본을 임시 파일에 다 만든 뒤 한 번에 옮긴다. 옮긴 뒤 덧붙이면 그 사이에 블록 없는 파일이 놓인다.
  {
    if [ -s "$norm" ]; then printf '\n'; fi
    printf '%s\n' "$begin"
    printf '%s\n' "$body"
    printf '%s\n' "$end"
  } >> "$norm" || return 2
  mv "$norm" "$uc" || return 2
}
```

CRLF 로 저장된 파일은 `$'\n'` 비교가 맞지 않아 다시 쓰는 갈래로 간다. 다시 쓰면 LF 로 정리되므로 다음 세션부터는 물러난다.

- [ ] **Step 4: MANAGED_TAG 를 상수로 고정한다**

`scripts/_managed_block.sh` 10-14행을 읽고, `MANAGED_TAG="${MANAGED_TAG:-disciplined-coder}"` 를 `MANAGED_TAG="disciplined-coder"` 로 바꾼다. "이 파일을 사본으로 가져가는 쪽은 source 앞뒤에 이 값만 세우면 되고 함수 시그니처는 그대로다." 와 그다음 줄 "여기서 경로나 판정을 만들지 마라 — 그러면 사본 쪽에서 조용히 다른 동작이 된다." 를 지운다. 고친 뒤 `grep -rn 'MANAGED_TAG=' scripts hooks skills README.md` 로 정의 파일 밖에서 값을 바꾸는 곳이 없는지 확인한다.

- [ ] **Step 5: 원칙 사본 복사를 같으면 생략하고 원자적으로 바꾼다**

`scripts/scaffold.sh` 58-60행을 아래로 바꾼다. 55-57행 주석 뒤에 "같으면 다시 쓰지 않는다. cp 는 대상을 비운 뒤 쓰므로 그 순간 다른 창이 @import 로 읽으면 반쪽 파일이 실린다. 그래서 옆 이름에 복사한 뒤 mv 로 한 번에 바꾼다. 복사가 실패해도 뒤 단계(관리블록·자동 갱신·핸드오프 린트)는 이어서 실행한다." 를 추가한다.

```bash
    if [ "$src" = "$dst" ] || { [ -e "$dst" ] && [ "$src" -ef "$dst" ]; }; then :
    elif [ -f "$dst" ] && [ "$(<"$src")" = "$(<"$dst")" ]; then :
    else
      tmpc="$dst.dc-new.$$"
      if cp "$src" "$tmpc" 2>/dev/null && mv "$tmpc" "$dst" 2>/dev/null; then :; else
        rm -f "$tmpc" 2>/dev/null || true
        echo "[disciplined-coder] ERROR: 에이전트원칙 복사 실패 — $src → $dst (이전 사본이 있으면 그것이 그대로 쓰인다). 나머지 셋업은 계속한다."
      fi
    fi
```

`grep -n '복사 실패' scripts/test_scaffold.sh` 로 복사 실패의 `exit 1` 을 단언하는 테스트가 있는지 확인한다. 있으면 종료 코드 0 과 ERROR 문구 출력을 단언하도록 바꾼다.

- [ ] **Step 6: 프로세스 환경에 PYTHONUTF8 이 있으면 레지스트리를 읽지 않는다**

`scripts/scaffold.sh` 32행(`esac`) 뒤에 추가한다.

```bash
  # 프로세스 환경에 값이 이미 있으면 레지스트리를 읽지 않는다. 레지스트리를 보는 이유는 넣은 직후
  # 세션에 프로세스 환경이 비어 있는 것 하나라, 값이 있으면 결론이 같고 프로세스 넷(reg·awk·tr·tail)만 든다.
  case "${PYTHONUTF8:-}" in
    1) printf 'on'; return 0 ;;
    0) printf 'off'; return 0 ;;
  esac
```

- [ ] **Step 7: 사용자가 조치할 경고를 stdout 으로 옮긴다**

`scripts/scaffold.sh` 68행과 169-170행을 아래로 바꾼다. `_scaffold_common.sh` 12-14행이 적듯 SessionStart 의 stderr 는 사용자에게 보이지 않는다. stdout 은 Claude 의 맥락에 들어가므로 Claude 가 전할 수 있다.

```bash
scaffold_hygiene "$KDIR" 2>&1
```

```bash
printf '%s\n' '@disciplined-coder/agent-principles.md' '@disciplined-coder/korean-banned-words.md' \
  | managed_block_inject "$UC" "$MANAGED_BEGIN" "$MANAGED_END" 2>&1 || inject_rc=$?
```

- [ ] **Step 8: autoUpdate 사본이 사용자 파일을 덮지 않게 한다**

`scripts/_ensure_autoupdate.sh` 69행을 아래로 바꾸고, 7행 주석의 "사본(.bak)을 남기고" 를 "시각을 붙인 사본(<파일>.<시각>.bak)을 남기고" 로 고친다. 사용자가 만든 `settings.json.bak` 을 덮지 않기 위해서다.

```bash
  cp "$f" "$f.$(date +%Y%m%d-%H%M%S).bak" || { rm -rf "$tmp"; return 5; }
```

임시 파일 이름(`.dc-tmp`)은 그대로 둔다. 이 경로는 키가 없을 때 한 번만 실행되고, 테스트 HE 픽스처가 그 이름으로 쓰기 실패를 재현한다.

README 「세션 시작에 바꾸는 전역 설정」 머리 문단의 "전역 설정을 바꾸기 전에 남긴 사본(`.bak`)" 을 "전역 설정을 바꾸기 전에 남긴 사본(`<파일>.<시각>.bak`)" 으로 바꾼다.

- [ ] **Step 9: 전체 테스트를 실행한다**

Run: 저장소 CLAUDE.md 「변경 뒤 실행」의 명령
Expected: `ALL PASS`

---

### Task 6: 스크립트·CI·테스트 정리

**Files:**
- Modify: `scripts/seal_reviews.sh:23`
- Modify: `.github/workflows/banned-words-sync.yml:47-69`
- Modify: `scripts/test_docs_drift.sh:465-467`
- Create: `scripts/_test_check.sh`
- Modify: `scripts/test_assertions.sh:11-12`, `scripts/test_audit.sh:9-10`, `scripts/test_docs_drift.sh:24-25`, `scripts/test_hooks.sh:12-13`, `scripts/test_scaffold.sh:10-11`
- Test: `scripts/test_audit.sh`

**Interfaces:**
- Produces: `scripts/_test_check.sh` — `pass`·`fail` 계수기와 `check <이름> <식>`.

- [ ] **Step 1: 봉인 스크립트의 빈 목록 테스트를 쓴다**

`scripts/test_audit.sh` 끝의 요약 줄 앞에 추가한다. bash 4.4 이상에서는 고치기 전에도 통과하므로 이 단언은 회귀 방지용이다(macOS 기본 bash 3.2 에서만 실패를 재현한다).

```bash
echo "[seal_reviews.sh — 봉인할 기록이 없어도 끝난다]"
SE="$(mktemp -d)"; git -C "$SE" init -q
set +e; SEOUT="$(bash "$HERE/scripts/seal_reviews.sh" --root "$SE" 2>&1)"; SERC=$?; set -e
check "빈 저장소에서 0 으로 끝난다" "[ '$SERC' -eq 0 ]"
check "봉인 개수 0 을 알린다"        "[ \"\$SEOUT\" = 'sealed: 0' ]"
```

- [ ] **Step 2: seal_reviews.sh 를 고친다**

23행(`fi`) 뒤에 추가한다.

```bash
# 목록이 비면 여기서 끝낸다. set -u 아래 빈 배열 펼치기는 bash 4.4 미만(맥 기본 3.2)에서 unbound 로 죽는다.
if [ "${#files[@]}" -eq 0 ]; then echo "sealed: 0"; exit 0; fi
```

- [ ] **Step 3: CI 가 테스트 실패를 PR 본문에 넣게 한다**

`banned-words-sync.yml` 「계약 테스트」 단계를 아래로 바꾼다. 실패 목록을 단계 출력으로 내고, 테스트는 저장소 CLAUDE.md 「변경 뒤 실행」처럼 동시에 실행한다. `continue-on-error` 는 지운다 — 이 단계는 언제나 0 으로 끝난다.

```yaml
      - name: 계약 테스트
        id: tests
        if: steps.diff.outputs.changed == 'yes'
        run: |
          d="$(mktemp -d)"
          for t in scripts/test_*.sh; do ( bash "$t" > "$d/$(basename "$t").log" 2>&1 || echo "$t" >> "$d/bad" ) & done
          wait
          if [ -s "$d/bad" ]; then
            {
              echo 'result<<RESULT_EOF'
              echo '계약 테스트가 실패했다.'
              while read -r t; do echo "- $t"; grep 'FAIL:' "$d/$(basename "$t").log" | head -20 | sed 's/^/  /'; done < "$d/bad"
              echo 'RESULT_EOF'
            } >> "$GITHUB_OUTPUT"
          else
            echo 'result=계약 테스트가 모두 통과했다.' >> "$GITHUB_OUTPUT"
          fi
```

「PR 을 연다」 단계의 `body` 마지막 문단 뒤에 빈 줄과 `${{ steps.tests.outputs.result }}` 를 추가한다. 47-48행 주석 뒤에 "`GITHUB_TOKEN` 으로 연 PR 에는 다른 워크플로가 실행되지 않으므로 결과는 본문으로만 전달된다." 를 한 줄 추가한다.

검증: `json_run 'import sys,yaml; yaml.safe_load(open(sys.argv[1],encoding="utf-8"))' .github/workflows/banned-words-sync.yml`. PyYAML 이 없어 실패하면 들여쓰기를 눈으로 확인하고 그 사실을 보고한다.

- [ ] **Step 4: 항진 단언을 지운다**

`scripts/test_docs_drift.sh` 465-467행(핸드오프 린트 문자열 grep 과 그 주석 두 줄)을 지운다. 같은 사실은 `test_scaffold.sh` 의 `handoff-lint` 블록이 동작으로 검사한다. 지운 뒤 그 줄이 속한 `echo "[` 블록에 단언이 남는지 `bash scripts/test_assertions.sh` 로 확인한다.

- [ ] **Step 5: 단언 함수를 공유 파일로 옮긴다**

`scripts/_test_check.sh` 를 만든다.

```bash
#!/usr/bin/env bash
# 공유: 계약 테스트의 단언 함수와 계수기. 소비자는 scripts/test_*.sh 다. 다섯 파일이 같은 정의를
# 베껴 두면 한쪽만 고쳐져 갈라진다(_audit_common.sh 와 같은 이유).
pass=0; fail=0
check() { if eval "$2"; then echo "  PASS: $1"; pass=$((pass+1)); else echo "  FAIL: $1"; fail=$((fail+1)); fi; }
```

Files 목록의 다섯 테스트에서 `pass=0; fail=0` 줄과 `check() {…}` 줄을 지우고 그 자리에 `. "$HERE/scripts/_test_check.sh"` 를 둔다. 각 파일에서 `HERE` 가 그 줄보다 앞에 정의되어 있는지 확인한다.

- [ ] **Step 6: 전체 테스트를 실행한다**

Run: 저장소 CLAUDE.md 「변경 뒤 실행」의 명령
Expected: `ALL PASS`

---

### Task 7: 스킬 문서의 이음새를 실물에 맞춘다

**Files:**
- Modify: `skills/aggregating-lenses/SKILL.md`, `skills/audit-repo-docs/SKILL.md`, `skills/review-docs/SKILL.md`, `skills/review-specs/SKILL.md`, `skills/nested-orchestration/SKILL.md`, `skills/dispatching-lenses/SKILL.md`, `skills/lens-readability/SKILL.md`, `skills/review-llm-calls/SKILL.md`
- Modify: `scripts/audit_verify.sh` (원본 이름 주석)
- Test: `scripts/test_audit.sh:179`, `scripts/test_docs_drift.sh:261`

**Interfaces:**
- Produces: 렌즈 원본 파일 이름 `<렌즈 스킬 이름>-<순번>.json`. 순번은 같은 차수에서 같은 렌즈가 다룬 대상의 차례다.
- Produces: 렌즈 원본의 최상위 `target` 칸(그 원본이 다룬 문서의 레포 상대경로).

- [ ] **Step 1: 계약 문구 테스트를 먼저 바꾼다**

`scripts/test_audit.sh` 179행과 `scripts/test_docs_drift.sh` 261행의 `'<렌즈 스킬 이름>-<실행 횟수>.json'` 을 `'<렌즈 스킬 이름>-<순번>.json'` 으로 바꾼다. `test_audit.sh` 의 같은 블록에 추가한다.

```bash
check "target 칸을 집계 계약이 정의한다" "grep -qF '| \`target\` |' '$HERE/skills/aggregating-lenses/SKILL.md'"
```

`scripts/test_docs_drift.sh` 끝의 요약 줄 앞에 추가한다.

```bash
echo "[YAGNI 정리 — 쓰이지 않던 장치를 지웠다]"
check "집계에 상충 감지 단계가 없다"         "! grep -qF '**상충 감지**' '$HERE/skills/aggregating-lenses/SKILL.md'"
check "readability 에 목적 둘 예외가 없다"   "! grep -qF '목적이 둘이면' '$HERE/skills/lens-readability/SKILL.md'"
check "MANAGED_TAG 를 밖에서 바꿀 수 없다"   "grep -qxF 'MANAGED_TAG=\"disciplined-coder\"' '$HERE/scripts/_managed_block.sh'"
```

Run: `bash scripts/test_audit.sh 2>&1 | grep FAIL:; bash scripts/test_docs_drift.sh 2>&1 | grep FAIL:`
Expected: 새 단언과 바꾼 두 단언이 FAIL. `MANAGED_TAG` 단언은 Task 5 를 마쳤으면 통과한다.

- [ ] **Step 2: aggregating-lenses 를 고친다**

- **target 칸** — 「렌즈가 추가하는 칸」 표 끝에 행을 추가한다: `| \`target\` | 레포 감사의 문서별 원본 | 그 원본이 다룬 문서의 레포 상대경로다. \`scripts/audit_verify.sh\`가 필수로 검사하고 \`scripts/audit_statements.sh\`가 진술을 문서별로 모을 때 쓴다 |`
- **상충 감지 제거** — 「하는 일」의 `상충 감지` 불릿을 지운다. 절 첫 문장을 "렌즈들의 이슈를 한 목록으로 모으고 커버리지 공백을 표시하는 데서 멈춘다." 로 바꾼다. description 을 "렌즈를 둘 이상 실행한 뒤에 연다. 그 출력을 한 목록으로 모으고 아무도 안 본 렌즈를 지적하는 집계 단계." 로 바꾼다.
- **예외 절** — 「공통 계약의 예외」의 "「집계」·「상충 감지」·「커버리지 공백」 어디에도" 를 "「집계」·「커버리지 공백」 어디에도" 로 바꾼다.
- **처분 절** — 62행 "「하는 일」의 세 단계까지만 한다." 를 "「하는 일」의 두 단계까지만 한다." 로, 63행 "상충이나 커버리지 공백이 있으면 사람에게 올린다." 를 "커버리지 공백이 있으면 사람에게 올린다." 로, 64행 "결정 없이 병합과 상충 감지와 커버리지 공백 표시까지만 하고" 를 "결정 없이 병합과 커버리지 공백 표시까지만 하고" 로, 65행 "직접 위 세 단계를 따르고" 를 "직접 위 두 단계를 따르고" 로 바꾼다.
- **구현 형태 절** — 100행 "결정론적 파이썬 함수로 구현한다. 모호한 상충 판정만 선택적으로 LLM을 쓴다." 를 "결정론적 파이썬 함수로 구현한다." 로, 101행 "위 「하는 일」의 세 단계를" 을 "위 「하는 일」의 두 단계를" 로 바꾼다.

- [ ] **Step 3: 상충 감지를 가리키던 다른 곳을 고친다**

아래 문장들을 바꾼다. 모든 항목은 "A 를 B 로 바꾼다." 형태로 적는다.

- **dispatching-lenses** — 「실행하는 방법」의 "렌즈 결과는 `aggregating-lenses`의 「하는 일」 세 단계로 모은다. 한 목록으로 병합한 뒤 상충과 커버리지 공백을 표시하고 결정은 내지 않는다." 를 "렌즈 결과는 `aggregating-lenses`의 「하는 일」 두 단계로 모은다. 한 목록으로 병합한 뒤 커버리지 공백을 표시하고 결정은 내지 않는다." 로 바꾼다.
- **audit-repo-docs 집계 절** — "`aggregating-lenses`의 「하는 일」 세 단계로 상충과 커버리지 공백을 표시한다." 를 "`aggregating-lenses`의 「하는 일」 두 단계로 커버리지 공백을 표시한다." 로 바꾼다.
- **audit-repo-docs 통합 기록 절** — 요약문 목록의 "집계가 표시한 상충과 커버리지 공백" 을 "집계가 표시한 커버리지 공백" 으로 바꾼다.
- **review-specs 메타 집계 절** — "`aggregating-lenses`의 「하는 일」 세 단계를 그대로 따른다. 한 목록으로 모으고 상충을 감지하고 커버리지 공백을 표시하는 데서 멈춘다." 를 "`aggregating-lenses`의 「하는 일」 두 단계를 그대로 따른다. 한 목록으로 모으고 커버리지 공백을 표시하는 데서 멈춘다." 로 바꾼다.
- **review-specs 리뷰 기록 절** — "`aggregating-lenses`가 표시한 상충과 커버리지 공백" 을 "`aggregating-lenses`가 표시한 커버리지 공백" 으로 바꾼다.
- **review-docs 기록 절** — "둘 이상의 렌즈가 함께 잡은 것과 상충과 커버리지 공백을 적는다." 를 "둘 이상의 렌즈가 함께 잡은 것과 커버리지 공백을 적는다." 로 바꾼다.
- **review-llm-calls 조립 절** — "상충과 커버리지 공백은 렌즈가 둘 이상이라야 생기기 때문이다." 를 "커버리지 공백은 렌즈가 둘 이상이라야 의미가 있기 때문이다." 로 바꾼다.
- **nested-orchestration 흐름 절** — "다음 세 상황 중 하나라도 나오면 아래 BLOCKED로 L1에 올려 보낸다. 🔴가 나왔을 때, 렌즈끼리 같은 지점을 두고 반대로 판정했을 때, 리스크상 필요한 차원을 아무도 안 봤을 때다." 를 "다음 두 상황 중 하나라도 나오면 아래 BLOCKED로 L1에 올려 보낸다. 🔴가 나왔을 때와 리스크상 필요한 차원을 아무도 안 봤을 때다." 로 바꾼다.

그다음 `grep -rn '상충' skills README.md CLAUDE.md` 를 실행해 렌즈 집계의 상충 감지를 가리키는 문장이 더 남았는지 확인한다. 남았으면 같은 방식으로 고친다. 도메인 참고서와 일반 용어의 '상충'(규칙 사이의 불일치를 뜻하는 말)은 그대로 둔다.

- [ ] **Step 4: 원본 이름 규칙을 고친다**

`skills/review-docs/SKILL.md` 「기록 파일 이름 규칙」의 "렌즈별 원본은 요약문과 같은 이름의 폴더에 `<렌즈 스킬 이름>-<실행 횟수>.json`(예: `lens-grounding-1.json`)으로 둔다." 를 "렌즈별 원본은 요약문과 같은 이름의 폴더에 `<렌즈 스킬 이름>-<순번>.json`(예: `lens-grounding-1.json`)으로 둔다. 순번은 그 차수에서 같은 렌즈가 다룬 대상의 차례다. 렌즈는 한 대상에 한 번만 실행하므로 대상이 하나면 늘 1이고, spec 과 plan 을 함께 보면 1과 2다. 어느 대상인지는 원본의 `target` 칸이 진다." 로 바꾼다.

`scripts/audit_verify.sh` 의 주석 "`<렌즈 스킬 이름>-<실행 횟수>.json`" 을 "`<렌즈 스킬 이름>-<순번>.json`" 으로 바꾼다.

- [ ] **Step 5: audit-repo-docs 의 에이전트 상한을 적는다**

「단계」 표의 "문서마다 렌즈 호출 하나를 실행한다" 를 "문서를 묶어 렌즈 호출을 실행한다" 로 바꾼다. 「실행할 때 지킬 것」의 "문서마다 따로 판정하는 렌즈에는 문서 하나를 통째로 준다." 로 시작하는 문단을 아래로 바꾼다.

> 한 단계의 에이전트는 `dispatching-lenses`의 상한 10개를 넘지 않는다. 대상이 상한보다 많으면 문서 여러 개를 한 호출에 묶고, 묶음은 9개 이하로 둔다(적대적 렌즈 하나를 남긴다). 같은 문서 종류끼리 묶어 적용할 렌즈가 같게 한다. 묶은 호출에는 문서마다 결과를 나눠 돌려 달라고 요구한다(`{"results":[{"target": "...", "lens": "...", "issues": [...], "statements": [...]}]}`). 호출자는 돌려받은 결과를 문서와 렌즈마다 원본 파일 하나로 나눠 쓰고, 각 원본의 최상위에 `target`을 둔다. 문서는 자르지 않는다 — 묶어도 문서 하나는 통째로 준다. 이 규칙은 이 절차에서 `review-specs`의 "대상마다 따로 실행한다"를 대신한다.

- [ ] **Step 6: review-specs 의 외부 의존과 L2 예외를 적는다**

- **외부 의존** — 「절차」의 "이 문서 밖에서 가져올 것이 셋이다." 를 "이 문서 밖에서 가져올 것이 넷이다." 로 바꾸고, 같은 문단 끝 "집계 절차는 `aggregating-lenses`에 있다." 를 "집계 절차는 `aggregating-lenses`에, 기록 파일 이름과 `lens-fit`에 넘길 계약은 `review-docs`에 있다." 로 바꾼다.
- **L2 예외** — 「작업 순서와 다시 리뷰」의 "다시 리뷰는 매번 사용자에게 묻는다. 자동으로 실행되지 않는다. 물을 때는 `ASK-OPTIONS`대로 선택지가 있는 질문으로 묻는다." 문단 뒤에 문단을 추가한다: "사람과 대화할 수 없는 실행자(`nested-orchestration`의 L2)는 묻지 않고 다시 리뷰를 생략한다. 대신 반영한 것 가운데 기능적 변화가 있었던 항목을 리포트에 적어 L1 에 넘긴다."

- [ ] **Step 7: nested-orchestration 에 병합 전 마커 확인을 적는다**

- **흐름 절** — L2 항목의 "고칠 것까지 반영하며," 를 "고칠 것까지 반영하고 다시 리뷰는 묻지 않고 생략해 기능적 변화가 있었던 반영을 리포트에 적으며," 로 바꾼다.
- **가드레일 절** — 불릿을 추가한다: "**plan 리뷰 마커 확인** — L2 가 쓴 plan 에는 메인 세션의 Stop 게이트가 적용되지 않는다. L1 은 병합 전에 브랜치마다 `git diff --name-only --diff-filter=A base..branch -- docs/superpowers/plans` 로 추가된 plan 을 구하고, 각 파일 마지막 줄에 `spec-review` 마커가 있는지 확인한다. 없으면 병합하지 않고 알린다."
- **사람 대화 불가 절** — 잔존 위험 문단 끝에 "plan 리뷰가 빠지는 위험은 위 마커 확인이 병합 전에 잡는다." 를 추가한다.

- [ ] **Step 8: '목적이 둘' 예외와 중복 문장을 지운다**

- **dispatching-lenses 예외 목록** — `lens-readability` 불릿과 그 아래 문단("`lens-readability`의 예외는 그 렌즈가 적던 방침…")을 지우고, "위 규율의 예외는 넷이다." 를 "위 규율의 예외는 셋이다." 로 바꾼다.
- **lens-readability** — 35행 문단("목적이 둘이면 한 호출 안에서 둘을 차례로 본다. …")을 지운다.
- **dispatching-lenses 넷째 불릿** — 「렌즈에게 에이전트원칙을 알리는 법」의 "그 값이 비어 있으면 보고에 적는다. 자동 재시도는 적용하지 않는다. 읽지 않고 채우는 것을 차단할 수 없으므로 재시도는 \"비어 있지 않은 배열\"로만 수렴한다." 를 "그 값이 비었을 때 무엇을 하는지는 `aggregating-lenses`의 리뷰 산출물 계약이 정한다." 로 바꾼다. 절 머리의 "넷을 지킨다" 는 그대로 둔다(불릿 수는 넷 그대로다).
- **dispatching-lenses 호출자 목록** — "다만 그 문서가 「판단 앞에 기계 검사를 둔다」를 이름으로 가리킬 때는 소유자를 이 스킬로 적는다." 를 "다만 그 문서가 이 스킬의 절(「판단 앞에 기계 검사를 둔다」, 「한 번만 실행하는 렌즈의 규율」, 「실행하는 방법」)을 이름으로 가리킬 때는 소유자를 이 스킬로 적는다." 로 바꾼다. `review-llm-calls` 의 세 포인터는 `test_docs_drift.sh` 121·272행이 요구하므로 그대로 두고, 소유자 쪽 문장을 실물에 맞춘다.

- [ ] **Step 9: 전체 테스트를 실행한다**

Run: 저장소 CLAUDE.md 「변경 뒤 실행」의 명령
Expected: `ALL PASS`. `test_docs_drift.sh` 가 지운 문장이나 절 이름을 찾다가 실패하면, 그 검사가 가리키던 규칙이 이 태스크로 사라진 것인지 확인하고 검사를 새 문구에 맞춘다. 규칙이 남아 있는데 문구만 바뀐 것이면 검사를 조항 ID·절 제목 기준(`scripts/_doc_keys.sh`)으로 바꾼다.

---

### Task 8: README 와 규칙 문서의 나머지를 실물에 맞춘다

**Files:**
- Modify: `README.md` (머리말, 「설치」, 「하드 게이트와 넛지와 전역 설정 수정」 머리 문단)
- Modify: `skills/domain-plugin/SKILL.md:35,41`
- Modify: `hooks/doc_word_pretooluse.sh:40`, `hooks/doc_word_posttooluse.sh` (머리 주석)
- Test: 전체 테스트

**Interfaces:**
- Consumes: Task 2 의 `hooks/stop_gates.sh`(README 와 domain-plugin 이 가리킨다).
- Produces: 없음(문서만 바꾼다).

- [ ] **Step 1: README 를 고친다**

- **대상** — 머리말 둘째 문장 뒤에 추가한다: "본인과 사내 한국어 사용자를 위해 만든 플러그인이라, 한국어 금지 표현 목록을 모든 세션에 싣고 사내 저장소를 목록의 원본으로 가리킨다."
- **파이썬** — 「설치」의 "마켓플레이스 자동 갱신에는 파이썬이 필요하다." 를 "마켓플레이스 자동 갱신과 갱신 확인과 금지 표현 검사에는 파이썬이 필요하다. 파이썬이 없으면 이 셋은 알림 없이 건너뛴다." 로 바꾼다.
- **답마다 실행되는 훅** — 47행 "대화 답마다 실행되는 hook은 없다." 를 "턴이 끝날 때마다 `hooks/stop_gates.sh` 하나가 실행된다. git 상태만 보며 대화 기록은 읽지 않는다." 로 바꾼다.

- [ ] **Step 2: domain-plugin 규칙을 고친다**

- **35행 불릿** — 제목 "**답마다 실행되는 훅은 만들지 않는다**" 를 "**대화 기록을 파싱하는 Stop 훅은 만들지 않는다**" 로 바꾸고, 불릿 끝 "답에 적용하는 규칙은 에이전트원칙에 적어 지시로 맡긴다." 뒤에 "git 상태만 보는 가벼운 게이트는 이 금지에 들지 않되, 검사를 한 프로세스로 모으고 git status 는 한 번만 실행한다(`hooks/stop_gates.sh`)." 를 추가한다.
- **41행 불릿** — 끝에 추가한다: "예외가 하나 있다. `PYTHONUTF8`은 이 플러그인이 묻지 않고 넣는다(`scripts/scaffold.sh`의 `[utf8-set]`). 사내 PC 의 파이썬 기본 인코딩이 cp949 라 한국어가 깨지고, 값을 `0`으로 두면 넣지 않는 끄는 길이 있기 때문이다(2026-09-30 사용자 결정)."

- [ ] **Step 3: 파이썬 부재 동작을 주석에 적는다**

`hooks/doc_word_pretooluse.sh` 40행 주석 뒤와 `hooks/doc_word_posttooluse.sh` 머리 주석 끝에 각각 추가한다: "예외는 파이썬이 없을 때다. 본문을 추리는 단계가 파이썬이라 그때는 알림 없이 통과한다(2026-09-30 사용자 결정, README 「설치」에 적었다)." `stop_gates.sh` 의 같은 설명은 Task 2 에서 넣었다.

- [ ] **Step 4: 전체 테스트와 매니페스트 검사를 실행한다**

Run: 저장소 CLAUDE.md 「변경 뒤 실행」의 명령, 그다음 `claude plugin validate ./`
Expected: `ALL PASS`, validate 는 `version` 경고 하나.

---

### Task 9: 전체 검증과 측정

**Files:** 없음(확인만)

**Interfaces:**
- Consumes: Task 1~8 의 결과.
- Produces: 사용자 보고(측정 비교표와 뺀 항목).

- [ ] **Step 1: 전체 테스트와 매니페스트 검사**

Run: 저장소 CLAUDE.md 「변경 뒤 실행」의 명령과 `claude plugin validate ./`
Expected: `ALL PASS`, `version` 경고 하나.

- [ ] **Step 2: 훅 시간을 다시 측정한다**

이 plan 을 쓰기 전과 같은 조건(Git Bash, 3회 평균, 같은 작은 샘플 입력)으로 측정해 비교표를 보고에 적는다. 비교 대상은 Write 한 번의 PreToolUse·PostToolUse 훅 합계, Bash 한 번의 훅 합계, Stop(전: 543ms+447ms), SessionStart 의 scaffold(전: 2225ms)다. scaffold 는 두 번째 실행(블록이 이미 같은 상태)을 측정한다. 큰 Write 입력(300KB content)으로도 Write 훅 합계를 측정해, `cat` 을 유지한 훅이 역전 없이 그대로인지 확인한다.

- [ ] **Step 3: 지운 파일을 가리키는 곳이 없는지 확인한다**

Run: `grep -rn '_extract_command\|spec_review_stop\|doc_word_stop' --include='*.sh' --include='*.md' --include='*.json' . | grep -v '^./docs/'`
Expected: 출력 없음.

- [ ] **Step 4: 사용자에게 보고하고 커밋 여부를 묻는다**

변경한 구조(무엇이 무엇을 호출하게 되었는지), 측정 비교, 이 plan 에서 뺀 항목을 보고한다. 뺀 항목은 둘이다. 하나는 `test_scaffold.sh` 의 자동 갱신 픽스처를 함수 직접 호출로 바꾸는 일이다. 그 픽스처들은 scaffold 의 stdout 문구를 단언하므로 함수만 부르면 단언 대상이 사라진다. 다른 하나는 `review-llm-calls` 의 포인터 합치기다. `test_docs_drift.sh` 가 그 포인터를 요구하므로 소유자 쪽 문장을 고쳤다(Task 7 Step 8).

---

### Task 10: 리뷰에서 나온 추가 이음새 정정

이 태스크의 변경은 2026-09-30 대화의 결정 12개와 승인된 "질문 없이 고칠 항목"에 없었다. plan 리뷰에서 🔴로 올렸고, 사용자가 다섯 단계 모두를 승인했다.

**Files:**
- Modify: `skills/aggregating-lenses/SKILL.md`, `skills/audit-repo-docs/SKILL.md`, `skills/review-specs/SKILL.md`, `skills/lens-fit/SKILL.md`

**Interfaces:**
- Consumes: Task 7 의 `target` 칸과 원본 이름 규칙.
- Produces: 없음(문서만 바꾼다).

- [ ] **Step 1: 집계 항목에 파일 칸을 추가한다**

`aggregating-lenses` 「출력 스키마」의 `aggregated` 항목에 `"file": "..."`, `"counterpart_file": "..."`, `"counterpart": "..."` 를 추가한다. `review-specs` 「합치기」의 첫 질문("근거로 든 파일과 줄이 실제로 그렇게 적혀 있는가")이 집계본만으로 원문을 열 수 있게 된다.

- [ ] **Step 2: 커버리지 공백에 결과를 안 돌려준 렌즈를 넣는다**

`aggregating-lenses` 「하는 일」의 커버리지 공백 불릿을 "**커버리지 공백** — 배정된 렌즈가 결과 JSON 을 돌려주지 않았거나, 리스크에 비추어 봤어야 할 렌즈를 아무도 안 봤으면 그 사실을 표시한다. 배정이 고정된 호출자는 다시 호출하지 않고 기록에 적는다." 로 바꾼다.

- [ ] **Step 3: 감사가 끊긴 차수를 찾게 한다**

`audit-repo-docs` 「통합 기록」 마지막 문단 뒤에 추가한다: "차수를 시작하기 전에 `bash scripts/audit_prior_rounds.sh self-audit --stale`로 끊긴 차수를 찾는다. 나오면 그 폴더 이름을 사용자에게 알리고, 이어받을지 버릴지 묻는다(`ASK-OPTIONS`). 끊긴 폴더가 커밋되어 봉인되었으면 `completed`를 쓸 수 없으므로 이어받지 않고 새 차수를 연다."

- [ ] **Step 4: 감사가 lens-fit 에 계약 칸을 넘기게 하고 임시 문단을 거둔다**

`audit-repo-docs` 「실행할 때 지킬 것」의 "렌즈 프롬프트는 그 렌즈 `SKILL.md`의 레퍼런스 프롬프트를 그대로 쓴다." 뒤에 추가한다: "`lens-fit`에는 `review-docs`의 「`lens-fit`에 넘기는 계약」이 정한 경로를 계약 칸으로 넘긴다. 묶은 호출은 렌즈마다 턴을 나누고, 턴마다 그 렌즈의 레퍼런스 프롬프트 user 틀을 채워 보낸다. `statements` 요구는 첫 턴에 한 번 붙인다." 그러면 모든 호출자가 계약 칸으로 넘기므로, `lens-fit/SKILL.md` 9행 문단("프롬프트에 에이전트원칙 경로가 들어 있으면 계약 칸에 없더라도 …")은 그 문단 자신이 적은 조건에 따라 지운다. `grep -n '승격\|알림으로' skills/lens-fit/SKILL.md` 로 레퍼런스 프롬프트에 같은 지시가 남았는지 확인한다.

- [ ] **Step 5: 선행연구 결과의 기록 위치와 재개 절차를 적는다**

`review-specs` 에서 세 곳을 고친다.

- **선행연구 기록** — 「선행연구 렌즈의 제안과 승인」 끝에 추가한다: "승인받아 실행한 결과는 앞 리뷰 기록을 고치지 않고 `review-docs` 이름 규칙의 `prior-art` 종류로 별도 기록에 남긴다. 그 발견은 전부 `🔴`이므로 이미 `passed`로 남긴 마커는 `escalated`로 바꾼다." 「웹에 나가는 렌즈의 인용 검증」의 "**보고에 적을 것**" 을 "**`prior-art` 기록에 적을 것**" 으로 바꾼다.
- **절차 표 순서** — 「절차」 표에서 "선행연구 렌즈를 실행할지 제안한다" 행을 "마커를 남기고 그다음 고친다" 행 뒤로 옮긴다.
- **재개** — 「작업 순서와 다시 리뷰」 끝에 추가한다: "마커를 남긴 뒤 반영 중에 세션이 끊겼다가 재개하면 리뷰 기록의 병합 목록을 문서와 대조해 반영하지 않은 항목을 찾는다."

- [ ] **Step 6: 전체 테스트를 실행한다**

Run: 저장소 CLAUDE.md 「변경 뒤 실행」의 명령
Expected: `ALL PASS`

<!-- spec-review: escalated -->
