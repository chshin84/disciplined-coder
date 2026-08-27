# ultracode 검증 토글(ultracode-review) 구현 계획

> **되돌린 작업의 계획이다(superseded).** 여기서 구현한 ultracode 검증 토글은 뜯어냈고 지금은
> 설정할 수 없다. 아래 태스크를 실행하지 마라 — 그대로 따라가면 제거한 토글을 되살리게 되고,
> 지금은 `scripts/_scaffold_common.sh`의 정리 목록이 같은 이름의 상태 파일을 매 세션 지우므로
> 스캐폴드가 만든 파일을 다음 세션 스캐폴드가 지우는 상태로 들어간다. 바로 아래
> "For agentic workers" 줄이 이 계획을 태스크 단위로 구현하라고 하지만, 그 지시는 이 표시로
> 효력을 잃는다. 설계는 `docs/superpowers/specs/2026-07-03-ultracode-review-toggle-design.md`에
> 있고 같은 표시가 달려 있다.

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** spec(`docs/superpowers/specs/2026-07-03-ultracode-review-toggle-design.md`, 3렌즈 리뷰 passed)대로 §가 트리거 표에 멀티에이전트 워크플로 행을 추가하고, `required`/`discretion`(기본) PC 전역 토글을 issue-mode 레일 미러로 구현한다. 이름은 사용자가 `ultracode-review`로 확정했다.

**Architecture:** 새 메커니즘은 없다 — 판정 함수는 `_scaffold_common.sh`(SSOT), 토글 스크립트·커맨드는 issue-mode 쌍의 미러, 주입은 scaffold stdout이다. spec의 확정 사항을 그대로 옮긴다: 출력 변수는 `ucr_` 접두로 분리(mode_line 덮어쓰기 풋건 방지), 주입 순서는 issue-mode 라인 바로 뒤 고정, codex-scaffold에는 추가하지 않음(무동작 주입 — 비대칭을 주석으로 명시하고 테스트가 부재를 계약으로 확인).

**Tech Stack:** 순수 bash, 기존 테스트 하니스(FAIL=0), 마크다운.

**전제 지식(레포 관례):** FAIL=0 계약·매직 넘버 금지, 한국어 conventional commit + 트레일러(`Co-Authored-By: Claude Fable 5 <noreply@anthropic.com>` / `Claude-Session: https://claude.ai/code/session_01GHD9UvKFd3nLLTiryd1m77`), Git Bash 실행, 전체 검증은 테스트 3종 + `claude plugin validate ./`(version 경고 1건은 의도된 상태).

---

## 파일 구조

| 파일 | 이 계획에서 |
|---|---|
| `scripts/_scaffold_common.sh` | `SCAFFOLD_WHITELIST`에 `ultracode-review` 추가 + `scaffold_resolve_ultracode_review()` 신설(Task 1) |
| `scripts/scaffold.sh` | 2c 판정 호출 + ucr 라인 주입(issue-mode 라인 바로 뒤)(Task 1) |
| `scripts/codex-scaffold.sh` | 의도적 비대칭 주석 한 줄(Task 1) |
| `scripts/ultracode-review.sh` | 신규 — issue-mode.sh 미러(Task 2) |
| `commands/ultracode-review.md` | 신규 — issue-mode.md 미러(Task 2) |
| `agent-principles.md` | §가 표에 워크플로 행 추가(Task 3) |
| `docs/DESIGN-NOTES.md` | required 강제 한계 한 줄(Task 3) |
| `README.md` | 커맨드 절에 `/ultracode-review` 한 줄(Task 2 — 커맨드 파일과 같은 커밋, 케이스 13 green 유지) |
| `scripts/test_scaffold.sh` | 케이스 14(토글)·케이스 15(정본 행 가드) 추가(Task 1~3의 red) |
| `scripts/test_codex_scaffold.sh` | 미러 부재 계약 체크 추가(Task 1) |
| `docs/superpowers/specs/2026-07-03-ultracode-review-toggle-design.md` | 잔재 모순 한 문장 정합화(Task 1 — "codex 테스트에도 모드 미러 체크"는 미러 제거 결정 이전 문구) |

---

### Task 1: 판정 함수·주입·codex 비대칭 (테스트 먼저)

**Files:**
- Test: `scripts/test_scaffold.sh`(케이스 14 전반부), `scripts/test_codex_scaffold.sh`(부재 체크)
- Modify: `scripts/_scaffold_common.sh`, `scripts/scaffold.sh`, `scripts/codex-scaffold.sh`, spec 문서(잔재 한 문장)

- [ ] **Step 1: 실패하는 테스트를 추가한다 — test_scaffold.sh 케이스 14(scaffold 거동부)**

케이스 13 블록 뒤, 마지막 `echo "----"` 앞에 추가한다:

```bash
# --- 케이스 14: ultracode 검증 모드 (ultracode-review) — spec 2026-07-03 ---
UR="$HERE/scripts/ultracode-review.sh"
H14="$(mktemp -d)"; P14="$(mktemp -d)"; K14="$H14/.claude/disciplined-coder"
echo "[case14] ultracode-review default + inject + toggle"
# 14a) 부재 → discretion 결정론 생성 + 모드 주입 + 첫설치 안내 + issue-mode와 공존(변수 분리)
OUT14a="$(run "$H14" "$P14")"
check "ultracode-review created = discretion" "[ \"\$(cat '$K14/ultracode-review')\" = discretion ]"
check "ucr mode line injected (discretion)"   "printf '%s' \"\$OUT14a\" | grep -qF '검증 모드: discretion'"
check "ucr first-install note injected"       "printf '%s' \"\$OUT14a\" | grep -qF 'ultracode 검증 모드를 discretion'"
check "both toggles injected (issue-mode too)" "printf '%s' \"\$OUT14a\" | grep -qF '처분 모드: surface'"
# 14b) 2회차 → 안내 미반복 + 위생 무경고(화이트리스트)
ERR14b="$(run "$H14" "$P14" 2>&1 >/dev/null)" || true
OUT14b="$(run "$H14" "$P14")"
check "ucr note not repeated"                 "! printf '%s' \"\$OUT14b\" | grep -qF 'ultracode 검증 모드를 discretion'"
check "ucr file not hygiene-flagged"          "! printf '%s' \"\$ERR14b\" | grep -qF '비관리 파일'"
# 14c) required → required 주입
printf 'required\n' > "$K14/ultracode-review"
OUT14c="$(run "$H14" "$P14")"
check "required mode injected"                "printf '%s' \"\$OUT14c\" | grep -qF '검증 모드: required'"
# 14d) 불명값 → discretion 폴백 + 경고
printf 'zzz\n' > "$K14/ultracode-review"
ERR14d="$(run "$H14" "$P14" 2>&1 >/dev/null)" || true
OUT14d="$(run "$H14" "$P14")"
check "ucr unknown value warns"               "printf '%s' \"\$ERR14d\" | grep -qF '불명값'"
check "ucr unknown falls back to discretion"  "printf '%s' \"\$OUT14d\" | grep -qF '검증 모드: discretion'"
```

- [ ] **Step 2: 실패하는 테스트를 추가한다 — test_codex_scaffold.sh 미러 부재 계약**

케이스 8 블록 끝(`check "subdir surfaced to stderr" ...` 뒤)에 추가한다:

```bash
# 의도적 비대칭(spec 2026-07-03): Codex에는 Workflow 도구가 없어 ultracode-review를 미러하지 않는다.
check "ultracode-review not mirrored to codex" "[ ! -f '$K/ultracode-review' ]"
```

- [ ] **Step 3: red를 확인한다**

Run: `bash scripts/test_scaffold.sh 2>&1 | grep -E "case14|ucr|ultracode|FAIL="; bash scripts/test_codex_scaffold.sh 2>&1 | tail -2`
Expected: 케이스 14 체크들이 FAIL(파일·주입 미구현), codex 부재 체크는 PASS(아직 아무도 안 만드니 당연히 부재 — 이 체크는 회귀 가드다). test_scaffold FAIL>0.

- [ ] **Step 4: 판정 함수를 _scaffold_common.sh에 추가한다**

`scaffold_resolve_issue_mode()` 함수 아래에 추가하고, 6행 `SCAFFOLD_WHITELIST`에 `ultracode-review`를 덧붙인다(`"agent-principles.md domains-index.md solved_problems.md issue-mode ultracode-review"`):

```bash
# ultracode 검증 모드: 부재면 discretion 생성(+1회 안내), 읽어서 ucr_mode_line/ucr_mode_note를 셋한다.
# issue-mode의 mode_line/mode_note와 변수를 공유하지 않는다 — 공유하면 나중 resolve가 먼저 값을
# 덮어써 첫 토글의 라인·안내가 조용히 유실된다(spec 2026-07-03).
scaffold_resolve_ultracode_review() {  # $1=KDIR  → sets: ucr_mode_line, ucr_mode_note
  local kdir="$1" mode_file mode
  mode_file="$kdir/ultracode-review"
  ucr_mode_note=""
  if [ ! -f "$mode_file" ]; then
    printf 'discretion\n' > "$mode_file"
    ucr_mode_note="🔵 disciplined-coder: ultracode 검증 모드를 discretion(기본)으로 시작했다 — 워크플로 렌즈 검증을 강제하려면 /ultracode-review required."
  fi
  mode="$(tr -d ' \t\r\n' < "$mode_file" 2>/dev/null || printf discretion)"
  if [ "$mode" = "required" ]; then
    ucr_mode_line="ultracode(멀티에이전트 워크플로) 검증 모드: required — 워크플로에 reviewer-* 렌즈 검증 단계를 반드시 포함한다"
  elif [ "$mode" = "discretion" ]; then
    ucr_mode_line="ultracode(멀티에이전트 워크플로) 검증 모드: discretion(기본) — 리스크에 비례해 판단하되 보고서에 검증 내역을 명시한다"
  else
    echo "[disciplined-coder] WARNING: ultracode-review 불명값 '$mode' — discretion으로 폴백" >&2
    ucr_mode_line="ultracode(멀티에이전트 워크플로) 검증 모드: discretion(기본) — 리스크에 비례해 판단하되 보고서에 검증 내역을 명시한다 (불명 config 폴백)"
  fi
}
```

- [ ] **Step 5: scaffold.sh에 판정 호출과 주입을 추가한다**

2b) 블록(`scaffold_resolve_issue_mode "$KDIR"`) 바로 아래에:

```bash
# 2c) ultracode 검증 모드: 판정 정본은 _scaffold_common.sh — ucr_mode_line/ucr_mode_note를 셋한다.
scaffold_resolve_ultracode_review "$KDIR"
```

4) 섹션의 `if [ -n "$mode_note" ]; then printf '%s\n' "$mode_note"; fi` 바로 아래에 추가한다.
(spec의 "issue-mode 라인 바로 뒤"를 여기서는 "issue-mode의 line+조건부 note 블록 바로 뒤"로 구현한다 —
ucr 라인을 mode_line과 mode_note 사이에 끼우면 issue-mode의 라인·안내가 갈라지기 때문이다):

```bash
printf '%s\n' "$ucr_mode_line"
if [ -n "$ucr_mode_note" ]; then printf '%s\n' "$ucr_mode_note"; fi
```

- [ ] **Step 6: codex-scaffold.sh에 의도적 비대칭 주석을 추가한다**

2b) 블록(`scaffold_resolve_issue_mode "$KDIR"`) 바로 아래에 주석만 추가한다:

```bash
# (의도적 비대칭) ultracode 검증 모드는 여기서 다루지 않는다 — Codex에는 Workflow 도구가 없어
# 주입이 무동작이다. 공유 화이트리스트 덕에 파일이 생겨도 위생 오탐은 없다(spec 2026-07-03).
```

- [ ] **Step 7: spec의 잔재 모순 한 문장을 정합화한다**

`docs/superpowers/specs/2026-07-03-ultracode-review-toggle-design.md`에서 교체한다(미러 제거 결정 이전에 쓰인 문장):

교체 전: `set/show/reject/자기완결. codex 테스트에도 모드 미러 체크를 추가한다.`
교체 후: `set/show/reject/자기완결. codex 테스트에는 미러 부재(파일 미생성)를 계약으로 확인한다(미러 제거 결정과 정합).`

- [ ] **Step 8: 케이스 14 scaffold 거동부의 green을 확인한다**

Run: `bash scripts/test_scaffold.sh 2>&1 | tail -2 && bash scripts/test_codex_scaffold.sh 2>&1 | tail -2`
Expected: 둘 다 FAIL=0.

- [ ] **Step 9: 커밋한다**

```bash
git add scripts/_scaffold_common.sh scripts/scaffold.sh scripts/codex-scaffold.sh scripts/test_scaffold.sh scripts/test_codex_scaffold.sh docs/superpowers/specs/2026-07-03-ultracode-review-toggle-design.md
git commit -m "feat(ultracode-review): 검증 모드 판정·주입을 scaffold에 추가한다

required/discretion(기본) 모드를 _scaffold_common.sh 판정 함수(SSOT)로
두고 scaffold stdout으로 주입한다. 출력 변수는 ucr_ 접두로 issue-mode와
분리(덮어쓰기 풋건 방지), codex에는 의도적 비대칭(Workflow 도구 부재 —
무동작 주입 제거)을 주석·테스트 계약으로 명시한다. spec의 미러 잔재
문장도 정합화했다.

Co-Authored-By: Claude Fable 5 <noreply@anthropic.com>
Claude-Session: https://claude.ai/code/session_01GHD9UvKFd3nLLTiryd1m77"
```

---

### Task 2: 토글 스크립트와 커맨드 (테스트 먼저)

**Files:**
- Test: `scripts/test_scaffold.sh`(케이스 14 커맨드 계약부)
- Create: `scripts/ultracode-review.sh`, `commands/ultracode-review.md`

- [ ] **Step 1: 실패하는 테스트를 추가한다 — 케이스 14 뒤에 커맨드 계약부**

케이스 14 블록 끝(14d 체크 뒤)에 추가한다:

```bash
# 14e) /ultracode-review set/show/reject/자기완결 — issue-mode 12e 미러
HC14="$(mktemp -d)/cfg"
CLAUDE_HOME_DIR="$HC14" bash "$UR" required >/dev/null
check "/ultracode-review required writes"     "[ \"\$(cat '$HC14/disciplined-coder/ultracode-review')\" = required ]"
check "/ultracode-review (no arg) shows mode" "CLAUDE_HOME_DIR='$HC14' bash '$UR' | grep -qF required"
CLAUDE_HOME_DIR="$HC14" bash "$UR" discretion >/dev/null
check "/ultracode-review discretion writes"   "[ \"\$(cat '$HC14/disciplined-coder/ultracode-review')\" = discretion ]"
set +e; CLAUDE_HOME_DIR="$HC14" bash "$UR" bogus >/dev/null 2>&1; rc14=$?; set -e
check "/ultracode-review rejects invalid arg" "[ $rc14 -ne 0 ]"
HF14="$(mktemp -d)/fresh"
CLAUDE_HOME_DIR="$HF14" bash "$UR" required >/dev/null
check "/ultracode-review self-contained mkdir" "[ -f '$HF14/disciplined-coder/ultracode-review' ]"
```

- [ ] **Step 2: red를 확인한다**

Run: `bash scripts/test_scaffold.sh 2>&1 | grep -E "ultracode-review (required|discretion|rejects|\(no arg\))|FAIL="`
Expected: 14e 체크들이 FAIL(스크립트 부재), FAIL>0.

- [ ] **Step 3: scripts/ultracode-review.sh를 작성한다 (issue-mode.sh 미러)**

```bash
#!/usr/bin/env bash
# /ultracode-review — ultracode(멀티에이전트 워크플로) 검증 모드 토글(PC 전역, 자기 홈 config). 인자 없으면 현재 모드 표시.
# discretion(기본 — 리스크 비례 재량, 보고서에 검증 내역 명시)과 required(워크플로에 reviewer-* 렌즈 검증 단계 필수).
set -euo pipefail

# 홈 해석 — scaffold.sh와 같은 공유 헬퍼(SSOT). 손복제 제거로 드리프트 방지.
. "$(dirname "$0")/_resolve_home.sh"
CLAUDE_HOME="$(resolve_home claude)"
KDIR="$CLAUDE_HOME/disciplined-coder"
MODE_FILE="$KDIR/ultracode-review"

arg="${1:-}"

if [ -z "$arg" ]; then
  cur="discretion"
  if [ -f "$MODE_FILE" ]; then cur="$(tr -d ' \t\r\n' < "$MODE_FILE" 2>/dev/null || printf discretion)"; fi
  case "$cur" in discretion|required) ;; *) cur="discretion (불명 config 폴백)" ;; esac
  echo "현재 ultracode 검증 모드: $cur"
  echo "변경: /ultracode-review discretion  |  /ultracode-review required"
  exit 0
fi

case "$arg" in
  discretion|required)
    mkdir -p "$KDIR"            # scaffold 선행을 가정하지 않음(자기완결)
    printf '%s\n' "$arg" > "$MODE_FILE"
    echo "[disciplined-coder] ultracode 검증 모드 = $arg (다음 세션부터 적용)"
    ;;
  *)
    echo "[disciplined-coder] 잘못된 인자 '$arg' — discretion|required 만 허용" >&2
    echo "사용법: /ultracode-review [discretion|required]" >&2
    exit 2
    ;;
esac
exit 0
```

- [ ] **Step 4: commands/ultracode-review.md를 작성한다**

```markdown
---
description: ultracode(멀티에이전트 워크플로) 검증 모드를 required(워크플로에 reviewer-* 렌즈 검증 단계 필수)와 discretion(기본 — 리스크 비례 재량, 보고서에 검증 내역 명시) 사이에서 토글한다. 인자가 없으면 현재 모드를 표시한다. PC 전역이며 다음 세션부터 적용된다.
---
`bash "${CLAUDE_PLUGIN_ROOT}/scripts/ultracode-review.sh" $ARGUMENTS`를 실행하고 결과를 한 줄로 보고하라. 인자는 `required` 또는 `discretion`(없으면 현재 모드를 표시한다).
```

- [ ] **Step 5: README 커맨드 절에 한 줄을 추가한다 — 케이스 13을 이 커밋 안에서 green으로 유지**

케이스 13은 commands/*.md 각각이 README '### 커맨드' 절에 등재됐는지를 계약으로 검사하므로,
커맨드 파일 생성과 README 등재는 같은 커밋에 있어야 태스크 경계가 green이다. `/add-pointer` 줄 아래에:

```text
/ultracode-review [모드] # ultracode 워크플로 검증 모드 토글: discretion(기본)|required (없으면 현재 표시)
```

- [ ] **Step 6: green을 확인한다**

Run: `bash scripts/test_scaffold.sh 2>&1 | tail -2`
Expected: FAIL=0.

- [ ] **Step 7: 커밋한다**

```bash
git add scripts/ultracode-review.sh commands/ultracode-review.md README.md scripts/test_scaffold.sh
git commit -m "feat(ultracode-review): 토글 스크립트·커맨드·README 등재를 추가한다 (issue-mode 미러)

커맨드 파일과 README 커맨드 절 등재를 같은 커밋에 묶는다 — 케이스 13
계약(커맨드↔README 일치)이 태스크 경계에서 green을 유지하게.

Co-Authored-By: Claude Fable 5 <noreply@anthropic.com>
Claude-Session: https://claude.ai/code/session_01GHD9UvKFd3nLLTiryd1m77"
```

---

### Task 3: 정본 표 행·DESIGN-NOTES (테스트 먼저)

**Files:**
- Test: `scripts/test_scaffold.sh`(케이스 15)
- Modify: `agent-principles.md`(§가 표), `docs/DESIGN-NOTES.md`(한계 절)

- [ ] **Step 1: 실패하는 테스트를 추가한다 — 케이스 15(정본 행 계약 가드)**

케이스 14 블록 뒤에 추가한다:

```bash
# --- 케이스 15: §가 표에 워크플로 검증 행 존재(정본 계약 가드 — spec 검증 기준) ---
# 파일 전역 grep이 아니라 트리거 문자열이 있는 '그 행 한 줄'을 뽑아 검사한다 — 호출자 열(reviewer-*)과
# 강제 방식 열이 같은 행에 있음을 보장한다(다른 행·다른 파일의 문자열로 vacuous 통과 방지).
WF_ROW="$(grep -F '멀티에이전트 워크플로 작성·실행' "$HERE/agent-principles.md" || true)"
echo "[case15] principles table has workflow verification row"
check "row exists (trigger)"       "[ -n \"\$WF_ROW\" ]"
check "row caller = reviewer-*"    "printf '%s' \"\$WF_ROW\" | grep -qF 'reviewer-*'"
check "row enforcement = toggle"   "printf '%s' \"\$WF_ROW\" | grep -qF 'ultracode 검증 모드'"
```

- [ ] **Step 2: red를 확인한다**

Run: `bash scripts/test_scaffold.sh 2>&1 | grep -E "case15|row |FAIL="`
Expected: 케이스 15 두 체크 FAIL(정본 행 미추가). 케이스 13은 Task 2에서 이미 green이다.

- [ ] **Step 3: §가 표에 행을 추가한다**

`agent-principles.md` §가 표의 '문서 작성' 행 바로 아래에 추가한다:

```
| 멀티에이전트 워크플로 작성·실행(발견·결론을 산출하는 오케스트레이션) | 워크플로 에이전트의 발견·결론 | `reviewer-*` 렌즈 스킬 (워크플로 검증 단계가 SKILL.md에서 렌즈를 도출 — 즉석 재작성 금지) | 상시 로드 원칙 + ultracode 검증 모드(`/ultracode-review` 토글) |
```

- [ ] **Step 4: DESIGN-NOTES '한계 / 주의' 절에 한 줄을 추가한다**

```markdown
- **ultracode 검증 모드(required)는 주입 지시 기반**이라 훅 차단이 아니다 — 모드 라인은 메인 세션에만
  도달하고(@import 아님), 서브에이전트 작성 경로에서는 메인의 스펙 릴레이에 의존하며, 지시 무시를 막을
  수 없다. Workflow 도구의 훅 표면이 공식 문서화되면 넛지 훅 승급을 재검토한다(spec 2026-07-03).
```

- [ ] **Step 5: green + 전체 검증을 확인한다**

Run: `bash scripts/test_scaffold.sh 2>&1 | tail -2 && bash scripts/test_hooks.sh 2>&1 | tail -2 && bash scripts/test_codex_scaffold.sh 2>&1 | tail -2 && claude plugin validate ./ 2>&1 | tail -2`
Expected: 테스트 3종 FAIL=0, validate는 version 경고 1건과 함께 통과(의도된 상태).

- [ ] **Step 6: 커밋하고 push한다**

```bash
git add agent-principles.md docs/DESIGN-NOTES.md scripts/test_scaffold.sh
git commit -m "feat(ultracode-review): §가 표 행과 DESIGN-NOTES 한계를 배선한다

검증 레이어 트리거 표에 멀티에이전트 워크플로 행을 추가하고(케이스 15가
계약으로 가드), required 강제 한계의 지속 홈을 DESIGN-NOTES에 둔다.

Co-Authored-By: Claude Fable 5 <noreply@anthropic.com>
Claude-Session: https://claude.ai/code/session_01GHD9UvKFd3nLLTiryd1m77"
git push
```

- [ ] **Step 7: CI를 관찰하고 새 세션 수동 확인을 안내한다**

Run: `gh run watch --exit-status`
Expected: 성공. 마지막으로 spec의 수동 검증 1건 — 사용자가 새 세션을 열면 "ultracode(멀티에이전트 워크플로) 검증 모드: discretion(기본) — …" 라인이 주입되는지 확인한다(구현자는 이를 사용자에게 안내만 한다).

---

## 범위 밖
- required의 거동 효과 검증 — spec 검증 기준이 명시했듯 검증 가능한 것은 문자열 주입뿐이며, 위반 시 정의된 조치는 없다(한계는 spec R5·DESIGN-NOTES가 소유).
- B안 넛지 훅 — Workflow 훅 표면 문서화 시 재검토.

<!-- spec-review: passed -->
