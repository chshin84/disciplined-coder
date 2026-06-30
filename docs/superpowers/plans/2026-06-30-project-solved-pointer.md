# 프로젝트 오답노트 포인터 (project-solved) Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** disciplined-coder에 프로젝트별 오답노트(`docs/solved_problems.md`) + 자기완결 `./CLAUDE.md` 포인터 + `/add-pointer` 커맨드 + 발견·복구 넛지를 더한다(스코프 라우팅의 프로젝트 층).

**Architecture:** scaffold가 `~/.claude/CLAUDE.md`에 쓰는 BEGIN/END 관리블록 주입 로직을 공유 헬퍼(`_managed_block.sh`)로 추출(scaffold·codex-scaffold의 실측 중복 제거)하고, 그 헬퍼를 `/add-pointer`가 재사용해 프로젝트 `./CLAUDE.md`에 포인터를 주입한다. 자동 계층(scaffold·훅)은 프로젝트에 쓰지 않고, 사용자가 명시 호출한 `/add-pointer`만 프로젝트에 쓴다(옵트인). 어긋남은 기존 `doc_review_posttooluse.sh`에 통합한 넛지로 표면화(자동 수정 없음).

**Tech Stack:** Bash(POSIX sh 호환), awk. 테스트는 레포 관례대로 `scripts/test_*.sh`(계약 FAIL=0, 매직넘버 없이 불변식).

**참조 spec:** `docs/superpowers/specs/2026-06-30-project-solved-pointer-design.md`

---

## File Structure

- **Create** `scripts/_managed_block.sh` — 공유 주입 헬퍼(`managed_block_inject`). 책임: CLAUDE.md류에 BEGIN/END 관리블록 멱등 주입.
- **Create** `scripts/add-pointer.sh` — `/add-pointer` 실행 스크립트. 책임: `docs/solved_problems.md` 생성(없으면) + `./CLAUDE.md` 포인터 주입.
- **Create** `commands/add-pointer.md` — 커맨드 정의(스크립트 호출 + 보고).
- **Modify** `scripts/scaffold.sh` — 인라인 주입 → 헬퍼 호출; solved 템플릿 문구 화해.
- **Modify** `scripts/codex-scaffold.sh` — 동일.
- **Modify** `hooks/doc_review_posttooluse.sh` — 프로젝트 루트 CLAUDE.md 발견·복구 넛지 분기.
- **Modify** `agent-principles.md` — §다 듀얼 recall 한 줄.
- **Modify** `skills/domain-docs/SKILL.md` — solved 행 스코프 축 + 승격=재기술 명시.
- **Modify** `README.md` — footprint 단정 3곳 동기화.
- **Modify** `scripts/test_scaffold.sh` — add-pointer·헬퍼 회귀 케이스.
- **Modify** `scripts/test_hooks.sh` — 넛지 케이스.

각 작업 후 커밋. 작업 순서는 의존 순(헬퍼 추출 먼저 — blast-radius를 계약 테스트로 가드).

---

### Task 1: 공유 주입 헬퍼 추출 (회귀 0 가드)

scaffold·codex-scaffold의 중복 주입 로직을 헬퍼로 빼고 둘이 호출하게 한다. 신규 동작은 없으므로 **기존 계약 테스트가 회귀 가드**다(실패 테스트를 새로 쓰지 않고, 기존 FAIL=0 유지가 성공 기준).

**Files:**
- Create: `scripts/_managed_block.sh`
- Modify: `scripts/scaffold.sh` (현재 주입 블록: `touch "$UC"` ~ `} >> "$UC"`)
- Modify: `scripts/codex-scaffold.sh` (현재 주입 블록: `touch "$AG"` ~ `} >> "$AG"`)
- Test(기존): `scripts/test_scaffold.sh`, `scripts/test_codex_scaffold.sh`

- [ ] **Step 1: 기존 계약이 green인지 baseline 확인**

Run: `bash scripts/test_scaffold.sh | tail -1`
Expected: `PASS=34 FAIL=0`

- [ ] **Step 2: 헬퍼 작성**

Create `scripts/_managed_block.sh`:

```bash
#!/usr/bin/env bash
# 공유: CLAUDE.md류 파일에 BEGIN/END 관리블록을 멱등 주입한다.
# Usage: managed_block_inject <target_file> <begin_mark> <end_mark>   (본문은 stdin)
# - 기존 BEGIN..END 영역 strip(CRLF 내성) → 사용자 내용 보존 → 말미 공백 정규화 → 새 블록 append.
# - BEGIN만 있고 END 없음 = WARN + strip 생략(비파괴).
managed_block_inject() {
  local uc="$1" begin="$2" end="$3" body
  body="$(cat)"
  touch "$uc"
  if grep -qF "$begin" "$uc" && grep -qF "$end" "$uc"; then
    awk -v b="$begin" -v e="$end" '{ l=$0; sub(/\r$/,"",l) } l==b{skip=1} skip==0{print} l==e{skip=0}' "$uc" > "$uc.tmp"
  elif grep -qF "$begin" "$uc"; then
    echo "[disciplined-coder] WARNING: $uc has BEGIN but no END — skipping strip" >&2
    cp "$uc" "$uc.tmp"
  else
    cp "$uc" "$uc.tmp"
  fi
  awk '{ l=$0; sub(/\r$/,"",l); if (l ~ /[^ \t]/) last=NR; line[NR]=$0 } END { for (i=1;i<=last;i++) print line[i] }' "$uc.tmp" > "$uc" && rm -f "$uc.tmp"
  {
    if [ -s "$uc" ]; then printf '\n'; fi
    printf '%s\n' "$begin"
    printf '%s\n' "$body"
    printf '%s\n' "$end"
  } >> "$uc"
}
```

- [ ] **Step 3: scaffold.sh가 헬퍼를 호출하도록 교체**

`scripts/scaffold.sh`에서 `# 3) ~/.claude/CLAUDE.md 관리블록 재생성` 아래의 `touch "$UC"` ~ `} >> "$UC"` 전체를 아래로 치환:

```bash
# 3) ~/.claude/CLAUDE.md 관리블록 재생성(멱등, CRLF 내성). 상대 @import(= ~/.claude 기준).
. "$PLUGIN_ROOT/scripts/_managed_block.sh"
BEGIN_MARK="# BEGIN disciplined-coder (managed — do not edit)"
END_MARK="# END disciplined-coder (managed — do not edit)"
# 스킬(domain-*/reviewer-*)은 플러그인에서 온디맨드 — 복사/주입 안 함.
managed_block_inject "$UC" "$BEGIN_MARK" "$END_MARK" <<'EOF'
@disciplined-coder/agent-principles.md
@disciplined-coder/domains-index.md
@disciplined-coder/solved_problems.md
EOF
```

- [ ] **Step 4: codex-scaffold.sh가 헬퍼를 호출하도록 교체**

`scripts/codex-scaffold.sh`에서 `# 3) ~/.codex/AGENTS.md 관리블록 재생성` 아래의 `touch "$AG"` ~ `} >> "$AG"` 전체를 아래로 치환(본문은 동적 — 정본 인라인이라 파이프로 stdin 주입):

```bash
# 3) ~/.codex/AGENTS.md 관리블록 재생성(멱등, CRLF 내성). @import 미지원 → 정본 본문 인라인.
. "$PLUGIN_ROOT/scripts/_managed_block.sh"
BEGIN_MARK="# BEGIN disciplined-coder (managed — do not edit)"
END_MARK="# END disciplined-coder (managed — do not edit)"
{
  for f in agent-principles.md domains-index.md; do
    if [ -f "$KDIR/$f" ]; then cat "$KDIR/$f"; printf '\n'; fi
  done
} | managed_block_inject "$AG" "$BEGIN_MARK" "$END_MARK"
```

- [ ] **Step 5: 회귀 0 확인 (가드)**

Run: `bash scripts/test_scaffold.sh | tail -1 && bash scripts/test_codex_scaffold.sh | tail -1`
Expected: `PASS=34 FAIL=0` / `PASS=17 FAIL=3` (codex의 FAIL=3은 이 PC python3 부재 — 기존과 동일, 신규 회귀 0). byte-drift로 다른 체크가 깨지면 헬퍼 출력이 원본과 어긋난 것이니 본문 주입 형태를 원본과 일치시켜 고친다.

- [ ] **Step 6: 커밋**

```bash
git add scripts/_managed_block.sh scripts/scaffold.sh scripts/codex-scaffold.sh
git commit -m "refactor(scaffold): extract shared managed-block injector (dedup scaffold/codex)"
```

---

### Task 2: `/add-pointer` 커맨드 + 스크립트 + 포인터 블록

프로젝트에 `docs/solved_problems.md`(없으면)와 `./CLAUDE.md` 자기완결 포인터를 멱등 주입한다.

**Files:**
- Create: `scripts/add-pointer.sh`
- Create: `commands/add-pointer.md`
- Test: `scripts/test_scaffold.sh` (신규 케이스 추가)

- [ ] **Step 1: 실패 테스트 작성**

`scripts/test_scaffold.sh`의 `echo "----"; echo "PASS=$pass FAIL=$fail"` 줄 **앞에** 추가:

```bash
# --- 케이스 11: /add-pointer (프로젝트 오답노트 + 포인터) ---
AP="$HERE/scripts/add-pointer.sh"
PA="$(mktemp -d)"   # 가짜 프로젝트
ERR11="$(CLAUDE_PROJECT_DIR="$PA" bash "$AP" 2>&1)" || true
echo "[case11] add-pointer creates log + pointer (idempotent)"
check "log created in docs/"            "[ -f '$PA/docs/solved_problems.md' ]"
check "CLAUDE.md created with pointer"   "grep -qF 'docs/solved_problems.md' '$PA/CLAUDE.md'"
check "pointer has recall instruction"   "grep -qF '먼저 확인' '$PA/CLAUDE.md'"
check "pointer has single-writer rule"   "grep -qF '메인 세션' '$PA/CLAUDE.md'"
check "pointer in managed region"        "[ \$(grep -cF '# BEGIN disciplined-coder' '$PA/CLAUDE.md') -eq 1 ]"
# 멱등: 2회차에도 블록 1개·로그 1개
printf '\n- 내 프로젝트 교훈\n' >> "$PA/docs/solved_problems.md"
CLAUDE_PROJECT_DIR="$PA" bash "$AP" >/dev/null 2>&1
check "idempotent: one managed region"   "[ \$(grep -cF '# BEGIN disciplined-coder' '$PA/CLAUDE.md') -eq 1 ]"
check "idempotent: log append preserved"  "grep -qF '내 프로젝트 교훈' '$PA/docs/solved_problems.md'"
# 기존 ./CLAUDE.md 내용 보존
PB="$(mktemp -d)"; printf 'my project note\n' > "$PB/CLAUDE.md"
CLAUDE_PROJECT_DIR="$PB" bash "$AP" >/dev/null 2>&1
check "existing CLAUDE.md preserved"     "grep -qxF 'my project note' '$PB/CLAUDE.md'"
# 반쯤 깨진 블록(BEGIN만) → 정상화(복구)
PC="$(mktemp -d)"; mkdir -p "$PC/docs"; : > "$PC/docs/solved_problems.md"
printf 'note\n# BEGIN disciplined-coder (managed — do not edit)\nstale\n' > "$PC/CLAUDE.md"
CLAUDE_PROJECT_DIR="$PC" bash "$AP" >/dev/null 2>&1
check "half-broken block normalized"     "[ \$(grep -cF '# END disciplined-coder' '$PC/CLAUDE.md') -ge 1 ]"
```

- [ ] **Step 2: 테스트 실패 확인**

Run: `bash scripts/test_scaffold.sh | tail -3`
Expected: FAIL ≥1 ("add-pointer.sh" 부재로 케이스 11 실패)

- [ ] **Step 3: add-pointer.sh 작성**

Create `scripts/add-pointer.sh`:

```bash
#!/usr/bin/env bash
# /add-pointer (kind=solved, 무인자 기본). 옵트인 — 프로젝트 폴더에 쓰는 유일한 동작.
# docs/solved_problems.md(없으면) + ./CLAUDE.md 자기완결 포인터(멱등 관리블록).
set -euo pipefail
HERE="$(cd "$(dirname "$0")" && pwd)"
PROJ="${CLAUDE_PROJECT_DIR:-$PWD}"
. "$HERE/_managed_block.sh"

LOG="$PROJ/docs/solved_problems.md"
UC="$PROJ/CLAUDE.md"
created=""

mkdir -p "$PROJ/docs"
if [ ! -f "$LOG" ]; then
  cat > "$LOG" <<'EOF'
# 해결된 문제 로그 (solved_problems) — 이 프로젝트 · append-only 오답노트

이 레포에서 완결한 문제의 교훈 — 차후 비슷한 작업에서 recall해 참고한다. 각 항목: 증상/문제 → 교훈.
**완결 후 등록하는 기록이라 '상태'가 아니다**(append-only, 과거를 지우지 않는다). 메인 세션만 append.
이 프로젝트에 한정된 교훈만 둔다 — 머신 전역은 PC solved, 보편은 디시플린 원칙으로(스코프 라우팅).
EOF
  created="$created docs/solved_problems.md"
fi

BEGIN_MARK="# BEGIN disciplined-coder (managed — do not edit)"
END_MARK="# END disciplined-coder (managed — do not edit)"
managed_block_inject "$UC" "$BEGIN_MARK" "$END_MARK" <<'EOF'
## 오답노트 (solved_problems)
디버깅·이슈 처리·중요한 결정을 시작하기 전에 `docs/solved_problems.md`를 **먼저 확인**한다 —
이 프로젝트에서 해결한 문제의 증상→교훈 기록이다. 문제를 완결하면 **메인 세션이** 거기에
append한다(서브에이전트는 직접 쓰지 말고 리턴으로 보고).
EOF

if [ -n "$created" ]; then echo "[disciplined-coder] project solved initialized:$created (+ ./CLAUDE.md 포인터)"; else echo "[disciplined-coder] ./CLAUDE.md 포인터 갱신(멱등). 로그 보존."; fi
exit 0
```

- [ ] **Step 4: 테스트 통과 확인**

Run: `bash scripts/test_scaffold.sh | tail -2`
Expected: `PASS=<더 커짐> FAIL=0`

- [ ] **Step 5: 커맨드 정의 작성**

Create `commands/add-pointer.md`:

```markdown
---
description: 이 프로젝트에 오답노트(docs/solved_problems.md)와 자기완결 ./CLAUDE.md 포인터를 멱등 추가한다(옵트인).
---
`bash "${CLAUDE_PLUGIN_ROOT}/scripts/add-pointer.sh"`를 실행하고, 새로 생성된 파일과 갱신된 포인터를 한 줄로 보고하라. 프로젝트 폴더에만 쓰며 멱등이다(여러 번 안전).
```

- [ ] **Step 6: 커밋**

```bash
git add scripts/add-pointer.sh commands/add-pointer.md scripts/test_scaffold.sh
git commit -m "feat(add-pointer): project solved log + self-contained CLAUDE.md pointer"
```

---

### Task 3: 발견·복구 넛지 (기존 doc_review 훅에 통합)

별도 훅을 더하지 않고 `doc_review_posttooluse.sh`에 프로젝트 루트 CLAUDE.md 분기를 더한다(이중 넛지 회피, OFF 토글 존중).

**Files:**
- Modify: `hooks/doc_review_posttooluse.sh`
- Test: `scripts/test_hooks.sh` (신규 케이스)

- [ ] **Step 1: 실패 테스트 작성**

`scripts/test_hooks.sh`의 최종 `echo "----"; echo "PASS=$pass FAIL=$fail"` **앞에** 추가. 아래 코드는 자체 `in_claudemd()`로 입력 JSON을 만들어 훅을 `bash "$DR"`로 직접 호출하고, 레포의 기존 `check` 헬퍼로 단언한다(기존 케이스와 동일 패턴):

```bash
# --- 케이스: 프로젝트 CLAUDE.md 발견·복구 넛지 ---
DR="$HERE/hooks/doc_review_posttooluse.sh"
PN="$(mktemp -d)"   # 로그 없는 프로젝트
in_claudemd() { printf '{"tool_name":"Write","tool_input":{"file_path":"%s/CLAUDE.md"}}' "$1"; }
OUT_DISC="$(in_claudemd "$PN" | CLAUDE_PROJECT_DIR="$PN" bash "$DR" 2>&1)" || true
echo "[case] project CLAUDE.md nudges"
check "discovery nudge when no log"      "printf '%s' \"\$OUT_DISC\" | grep -qF 'add-pointer'"
check "single fire (no generic 🔎)"      "! printf '%s' \"\$OUT_DISC\" | grep -qF '🔎'"
check "hook writes no project file"       "[ ! -f '$PN/docs/solved_problems.md' ]"
# 로그+포인터 정상 → 무넛지(add-pointer 미언급)
PO="$(mktemp -d)"; mkdir -p "$PO/docs"; : > "$PO/docs/solved_problems.md"
printf '# BEGIN disciplined-coder (managed — do not edit)\nx\n# END disciplined-coder (managed — do not edit)\n' > "$PO/CLAUDE.md"
OUT_OK="$(in_claudemd "$PO" | CLAUDE_PROJECT_DIR="$PO" bash "$DR" 2>&1)" || true
check "no nudge when log+pointer ok"     "! printf '%s' \"\$OUT_OK\" | grep -qF 'add-pointer'"
# 로그 있고 포인터 없음 → 복구 넛지
PR="$(mktemp -d)"; mkdir -p "$PR/docs"; : > "$PR/docs/solved_problems.md"; printf 'note\n' > "$PR/CLAUDE.md"
OUT_REC="$(in_claudemd "$PR" | CLAUDE_PROJECT_DIR="$PR" bash "$DR" 2>&1)" || true
check "recovery nudge when pointer gone" "printf '%s' \"\$OUT_REC\" | grep -qF 'add-pointer'"
# 반깨짐(BEGIN만, END 없음) → 복구 넛지
PH="$(mktemp -d)"; mkdir -p "$PH/docs"; : > "$PH/docs/solved_problems.md"
printf '# BEGIN disciplined-coder (managed — do not edit)\nx\n' > "$PH/CLAUDE.md"
OUT_HALF="$(in_claudemd "$PH" | CLAUDE_PROJECT_DIR="$PH" bash "$DR" 2>&1)" || true
check "recovery nudge on half-broken"     "printf '%s' \"\$OUT_HALF\" | grep -qF 'add-pointer'"
# OFF 토글 → 침묵
OUT_OFF="$(in_claudemd "$PN" | CLAUDE_PROJECT_DIR="$PN" DISCIPLINED_CODER_REVIEW_GATE=off bash "$DR" 2>&1)" || true
check "off toggle silences nudge"        "! printf '%s' \"\$OUT_OFF\" | grep -qF 'add-pointer'"
# CLAUDE_PROJECT_DIR 미설정 → no-op(오작동 없음)
OUT_UNSET="$(in_claudemd "$PN" | bash "$DR" 2>&1)" || true
check "unset PROJECT_DIR no-op"          "! printf '%s' \"\$OUT_UNSET\" | grep -qF 'add-pointer'"
```

- [ ] **Step 2: 테스트 실패 확인**

Run: `bash scripts/test_hooks.sh | tail -3`
Expected: FAIL ≥1 (넛지 분기 부재)

- [ ] **Step 3: doc_review_posttooluse.sh에 분기 추가**

`hooks/doc_review_posttooluse.sh`는 line 5에서 OFF 토글을 이미 처리하고(`[ "${DISCIPLINED_CODER_REVIEW_GATE:-on}" = "off" ] && exit 0`), 매칭된 파일을 변수 `match`에, basename을 `base`에 담은 뒤 line 19~21에서 generic 검진 넛지를 JSON으로 emit한다. **`base="$(basename "$match")"` 다음 줄(현재 line 19 `msg=...` 앞)에** 아래 분기를 삽입한다 — 프로젝트 루트 CLAUDE.md면 generic 넛지를 **대체**(이중 넛지 회피):

```bash
# 프로젝트 루트 CLAUDE.md면 오답노트 발견·복구 넛지로 대체(이중 넛지 회피). 그 외 .md는 아래 generic 넛지.
proj="${CLAUDE_PROJECT_DIR:-}"
if [ "$base" = "CLAUDE.md" ] && [ -n "$proj" ]; then
  # 양쪽 모두 슬래시 정규화 후 canonical 비교(Windows 백슬래시·드라이브케이스 흡수).
  # $match는 _extract_path가 이미 슬래시화하지만 $proj(CLAUDE_PROJECT_DIR)는 백슬래시일 수 있다.
  proj_n="$(printf '%s' "$proj" | tr '\\' '/')"
  mdir="$(cd "$(dirname "$match")" 2>/dev/null && pwd -P || true)"
  proot="$(cd "$proj_n" 2>/dev/null && pwd -P || true)"
  if [ -n "$mdir" ] && [ -n "$proot" ] && [ "$mdir" = "$proot" ]; then
    if [ ! -f "$proj_n/docs/solved_problems.md" ]; then
      ps="💡 이 프로젝트엔 오답노트가 없습니다 — /add-pointer 로 docs/solved_problems.md + 포인터를 추가하면 디버깅 시 recall됩니다(옵트인)."
    elif ! { grep -qF '# BEGIN disciplined-coder' "$match" && grep -qF '# END disciplined-coder' "$match"; } 2>/dev/null; then
      # BEGIN·END 둘 다 있어야 정상 — 하나라도 없으면(없음 or 반깨짐) 복구 넛지
      ps="💡 docs/solved_problems.md는 있는데 CLAUDE.md 포인터가 없습니다(또는 반쯤 깨짐) — /add-pointer 재실행으로 복구하세요."
    else
      exit 0   # 로그+온전한 포인터 → 무넛지
    fi
    esc="$(printf '%s' "$ps" | sed 's/\\/\\\\/g; s/"/\\"/g')"
    printf '{"hookSpecificOutput":{"hookEventName":"PostToolUse","additionalContext":"%s"}}\n' "$esc"
    exit 0
  fi
fi
```

(OFF 토글은 line 5에서 이미 처리되므로 별도 추가 불필요 — 분기가 자동 존중. **양쪽 경로를 슬래시 정규화**해야 Windows에서 `cd`가 깨지지 않는다[`$match`만 정규화하면 주 플랫폼에서 넛지가 조용히 안 뜬다]. **반깨짐**(BEGIN만)도 END 부재로 복구 넛지에 걸린다. `CLAUDE_PROJECT_DIR` 미설정이면 `[ -n "$proj" ]`에서 빠져 generic 넛지로 fall-through[프로젝트-solved 오작동 없음 — 단 literal silent는 아님].)

- [ ] **Step 4: 테스트 통과 확인**

Run: `bash scripts/test_hooks.sh | tail -2`
Expected: `PASS=<더 커짐> FAIL=0`

- [ ] **Step 5: 커밋**

```bash
git add hooks/doc_review_posttooluse.sh scripts/test_hooks.sh
git commit -m "feat(hooks): project-solved discovery/recovery nudge in doc_review (off-toggle, single-fire)"
```

---

### Task 4: §다 듀얼 recall

**Files:**
- Modify: `agent-principles.md` (§다, "꺼내 쓰기(recall)" 줄)

- [ ] **Step 1: §다 recall 줄 편집**

`agent-principles.md`의 `- **꺼내 쓰기(recall)**: 디버깅·구현을 시작하기 전에 solved에서 비슷한 증상을 먼저 찾는다.` 를 아래로 치환:

```markdown
- **꺼내 쓰기(recall)**: 디버깅·구현을 시작하기 전에 **PC solved + 프로젝트 solved(레포에 `docs/solved_problems.md` 포인터가 있으면) 둘 다**에서 비슷한 증상을 먼저 찾는다. 기록은 범위대로 한 집에(프로젝트 quirk→프로젝트 solved, 머신 전역→PC, 보편→원칙 / 스코프 라우팅).
```

- [ ] **Step 2: 듀얼 recall 문구 존재 + 회귀 0 + 커밋**

Run: `grep -qF '프로젝트 solved' agent-principles.md && echo PRESENT`
Expected: `PRESENT` (듀얼 recall 문구가 실제로 추가됨)
Run: `bash scripts/test_scaffold.sh | tail -1`
Expected: `FAIL=0` (정본 복사 회귀 0)

```bash
git add agent-principles.md
git commit -m "docs(discipline): §다 dual recall (PC + project solved), scope routing"
```

---

### Task 5: solved 정합 — domain-docs 행 + scaffold 템플릿 화해

append-only('이동 없음')와 '승격'의 충돌을 "계층 내 불변 / 상위 재기술"로 명시하고, 두 scaffold 템플릿의 '제거' 문구를 고친다.

**Files:**
- Modify: `skills/domain-docs/SKILL.md` (solved/이슈 행)
- Modify: `scripts/scaffold.sh` (solved heredoc), `scripts/codex-scaffold.sh` (solved heredoc)

- [ ] **Step 1: domain-docs solved 행에 스코프 축 + 승격 주석**

`skills/domain-docs/SKILL.md`의 이슈(solved 오답노트) 행에 스코프 축을 접어 넣고, 표 아래(또는 행 detail)에 한 줄 추가:

```markdown
> solved는 **계층별**(프로젝트 `docs/solved_problems.md` · PC `~/.claude/...`)로 둔다(스코프 라우팅). append-only는 **한 계층 안에서** 불변이고, 더 넓게 쓰이는 교훈은 상위 계층에 **재기술**(승격)한다 — 바이트 이동이 아니라 더 일반적 표현으로 다시 쓰는 것.
```

- [ ] **Step 2: 두 scaffold의 solved 템플릿 문구 화해**

`scripts/scaffold.sh`와 `scripts/codex-scaffold.sh`의 solved heredoc에서 `일반화 가능한 항목은 디시플린(agent-principles.md)으로 승격하고 여기서는 제거(SSOT).` 를 아래로 치환(양쪽 동일):

```
일반화 가능한 항목은 디시플린(agent-principles.md)으로 **재기술해 승격**한다(원문은 append-only로 보존 — 이동이 아니라 상위 계층 재작성).
```

- [ ] **Step 3: 정합 문구 존재 + 회귀 0 + 커밋**

Run: `grep -qF '스코프 라우팅' skills/domain-docs/SKILL.md && grep -qF '재기술해 승격' scripts/scaffold.sh && grep -qF '재기술해 승격' scripts/codex-scaffold.sh && echo PRESENT`
Expected: `PRESENT` (스코프 축 + 두 템플릿 화해가 실제로 적용됨)
Run: `bash scripts/test_scaffold.sh | tail -1`
Expected: `FAIL=0`

```bash
git add skills/domain-docs/SKILL.md scripts/scaffold.sh scripts/codex-scaffold.sh
git commit -m "docs(solved): scope-axis + promotion=re-authoring (reconcile append-only)"
```

---

### Task 6: README footprint 절대 단정 전부 동기화

> 줄 번호를 박지 않는다(드리프트) — **grep으로 모든 footprint 절대 단정을 surface해 빠짐없이** 한정한다.
> 주의: `L95`("플러그인 루트 CLAUDE.md는 컨텍스트 미로드")는 footprint 단정이 **아니다**(손대지 말 것).

**Files:**
- Modify: `README.md` (footprint 절대 단정 전부 — 아래 grep이 식별)

- [ ] **Step 1: footprint 절대 단정 모두 surface**

Run: `grep -nE '프로젝트 폴더.*(안 생|건드리|더럽)|작업 폴더엔 아무 파일도' README.md`
Expected: footprint를 절대문으로 단정하는 모든 줄(현재 기준 L5 '더럽히고 싶지 않은', L8 Highlights '아무 파일도 안 생긴다', L15 '전혀 건드리지 않는다', L57 '전혀 건드리지 않는다' — **개수를 박지 말고 grep 결과 전부** 처리).

- [ ] **Step 2: surface된 각 단정에 옵트인 예외 한정 추가**

grep이 surface한 **모든** 줄을 "자동 계층(scaffold·훅)은 프로젝트 폴더를 건드리지 않는다 — 단, 사용자가 명시 실행한 `/add-pointer`만 옵트인으로 프로젝트에 쓴다(`docs/solved_problems.md` + `./CLAUDE.md` 포인터)." 취지로 한정한다. Highlights 불릿엔 `(예외: 옵트인 \`/add-pointer\`)`를 붙이고, 본문 단정들엔 같은 한정 한 절씩. **한 곳이라도 빠지면 새 거짓**이 되니 Step 1 grep 결과를 체크리스트로 빠짐없이.

- [ ] **Step 3: 신규 거짓 0 확인 + 커밋**

Run: `grep -nE '프로젝트 폴더.*(안 생|건드리|더럽)|작업 폴더엔 아무 파일도' README.md`
Expected: 모든 surface 줄에 `/add-pointer` 옵트인 한정이 붙어 있음(미한정 절대 단정 0).
Run: `claude plugin validate ./ | tail -2`
Expected: `Validation passed with warnings`(기존 경고 외 신규 0)

```bash
git add README.md
git commit -m "docs(readme): scope footprint-zero to automatic layer (opt-in /add-pointer exception)"
```

---

### Task 7: dogfood + 최종 스위트

이 레포 자신에 `/add-pointer`를 적용하고 전체 계약을 재확인한다.

**Files:**
- Create(생성물): `docs/solved_problems.md`, `CLAUDE.md`(관리블록 추가)

- [ ] **Step 1: 이 레포에 add-pointer 실행**

Run: `CLAUDE_PROJECT_DIR="$(pwd)" bash scripts/add-pointer.sh`
Expected: `docs/solved_problems.md` 생성 + 루트 `CLAUDE.md`에 포인터 블록 주입 보고.

- [ ] **Step 2: dogfood 산출 확인**

Run: `[ -f docs/solved_problems.md ] && grep -qF '# BEGIN disciplined-coder' CLAUDE.md && echo OK`
Expected: `OK`

- [ ] **Step 3: 전체 계약 스위트**

Run: `bash scripts/test_scaffold.sh | tail -1; bash scripts/test_hooks.sh | tail -1; bash scripts/test_codex_scaffold.sh | tail -1; claude plugin validate ./ | tail -1`
Expected: scaffold·hooks `FAIL=0`, codex `FAIL=3`(python 부재 — 기존), validate 통과.

- [ ] **Step 4: 커밋**

```bash
git add docs/solved_problems.md CLAUDE.md
git commit -m "chore(dogfood): apply /add-pointer to this repo (project solved log + pointer)"
```

---

## Self-Review (작성자 체크 — 작성 후)

- **Spec 커버리지**: 주입 프리미티브(Task1)·/add-pointer+포인터(Task2)·발견·복구 넛지(Task3)·§다 듀얼 recall(Task4)·solved 정합 domain-docs+템플릿(Task5)·README 동기화(Task6)·dogfood(Task7). spec 7 구성요소·성공기준 전부 대응.
- **시퀀싱**: 헬퍼 추출(Task1)을 가장 먼저, 기존 FAIL=0이 회귀 가드. /add-pointer(Task2)는 그 뒤 소비.
- **타입/이름 일관**: `managed_block_inject`(헬퍼) · `_managed_block.sh` · `add-pointer.sh` · `/add-pointer` 무인자 — 전 작업 일관. BEGIN/END 마커 문자열 동일.
- **플레이스홀더 0**: 모든 코드 step에 실제 코드/명령/기대출력. Task3 분기는 `doc_review_posttooluse.sh`의 실제 변수(`match`·`base`)·line 5 OFF 토글·line 19(`msg=`) 삽입 지점을 그대로 쓴다(3렌즈 grounding으로 검증됨).
- **codex byte 주의**: Task1의 codex 헬퍼 치환은 END 마커 직전 빈 줄 1개가 사라진다(원본 `printf '\n'` 잔여). `test_codex_scaffold`가 그 빈 줄을 검사하지 않아 회귀 0이나(무해), Claude scaffold와 달리 codex는 byte-동일이 아님을 인지(구현자가 놀라지 않게).
