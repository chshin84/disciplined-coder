# 상시 로드 레일 정리 (1단계 — 코드) 구현 계획

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** 관리블록이 매 실행마다 잔해를 쌓는 결함을 없애고, 정본이 `@import`와 stdout 양쪽으로 두 번 실리던 것을 한 경로로 줄이며, 더 이상 필요 없어진 `/add-pointer`를 제거한다.

**Architecture:** `@import`를 정본 전달의 단일 레일로 삼는다(압축 후에도 매 요청 다시 실리기 때문이다). `managed_block_inject`의 strip 대상을 **마커 줄로만** 한정해 본문을 절대 지우지 않게 하고, 닫는 마커가 없는 여는 마커는 그 줄만 지운 뒤 경고한다. `scaffold.sh`의 stdout 정본 덤프는 블록을 방금 만든 세션에서만 켠다.

**Tech Stack:** POSIX sh 위의 bash, awk, grep. 테스트는 레포 자체 스위트(`scripts/test_*.sh`)이며 계약은 `FAIL=0`이다.

## Global Constraints

- 계약은 세 스위트 모두 `FAIL=0`이다 — `bash scripts/test_scaffold.sh`, `bash scripts/test_hooks.sh`, `bash scripts/test_codex_scaffold.sh`. 테스트 기대 개수를 코드에 박지 않는다.
- `managed_block_inject`는 `scaffold.sh`와 `codex-scaffold.sh`가 공유한다. **본문 줄은 어떤 경우에도 삭제하지 않는다** — codex 경로에서 본문이 정본 전문이라 빈 줄까지 삭제 대상이 되기 때문이다.
- 관리 블록 마커 문자열은 정확히 이 값이다. `# BEGIN disciplined-coder (managed — do not edit)` / `# END disciplined-coder (managed — do not edit)` / `# (disciplined-coder: orphan BEGIN neutralized — END missing)`. 대시는 em dash(—)다.
- 고아 경고 문구에 `BEGIN but no END` 문자열을 반드시 포함한다 — `test_scaffold.sh` case7이 그 부분 문자열을 검사한다.
- 문자열 비교에 `grep -x`(줄 전체 일치)를 쓰지 않는다. CRLF 파일에서 줄 끝 CR 때문에 영원히 거짓이 된다.
- 사람이 읽는 문서(`README.md`, 훅이 CLI에 띄우는 메시지)는 한국어로 유지한다.
- 모든 스크립트는 `set -euo pipefail` 아래에서 돈다. 정상 경로가 0이 아닌 값을 리턴하는 함수는 반드시 `if`로 감싼다.

---

### Task 1: `managed_block_inject`의 strip 규칙을 마커 줄로 한정한다

**Files:**
- Modify: `scripts/_managed_block.sh:1-30` (함수 전체)
- Test: `scripts/test_scaffold.sh` (새 케이스 16 추가)

**Interfaces:**
- Consumes: 없음 (이 태스크가 첫 변경이다)
- Produces: `MANAGED_ORPHAN` 모듈 상수(문자열), 그리고 동작이 바뀐 `managed_block_inject <file> <begin> <end>` (본문은 stdin, 반환값은 기존과 같이 성공 시 0)

- [ ] **Step 1: 실패하는 테스트를 쓴다**

`scripts/test_scaffold.sh`의 케이스 15 블록 바로 뒤, `echo "----"` 줄 앞에 붙인다.

```bash
# --- 케이스 16: 손상된 관리영역 자기 치유 (실측 ~/.claude/CLAUDE.md 모양 재현) ---
# 고아 무해화 주석이 여는 마커 자리를 대신한 반복 블록 + 짝 없는 END + 사용자 줄.
# 계약: 관리영역 1개, 고아 주석 0, 짝 없는 마커 0, 사용자 줄 보존, 본문 줄은 삭제 대상 아님.
H16="$(mktemp -d)"; P16="$(mktemp -d)"; mkdir -p "$H16/.claude"
{ printf '\n\n'
  printf '# END disciplined-coder (managed — do not edit)\n\n'
  printf '@disciplined-coder/agent-principles.md\n'
  printf '# END disciplined-coder (managed — do not edit)\n\n'
  printf '# (disciplined-coder: orphan BEGIN neutralized — END missing)\n'
  printf '@disciplined-coder/agent-principles.md\n'
  printf '# END disciplined-coder (managed — do not edit)\n\n'
  printf 'MY OWN GLOBAL NOTE\n'
  printf '# BEGIN disciplined-coder (managed — do not edit)\n'
  printf '@disciplined-coder/agent-principles.md\n'
  printf '# END disciplined-coder (managed — do not edit)\n'
} > "$H16/.claude/CLAUDE.md"
run "$H16" "$P16" >/dev/null
UC16="$H16/.claude/CLAUDE.md"
echo "[case16] corrupted region self-heals"
check "one BEGIN after heal"          "[ \$(grep -cF '# BEGIN disciplined-coder' '$UC16') -eq 1 ]"
check "one END after heal"            "[ \$(grep -cF '# END disciplined-coder' '$UC16') -eq 1 ]"
check "no orphan marker left"         "! grep -qF 'orphan BEGIN neutralized' '$UC16'"
check "user note preserved"           "grep -qxF 'MY OWN GLOBAL NOTE' '$UC16'"
run "$H16" "$P16" >/dev/null
check "still one BEGIN (idempotent)"  "[ \$(grep -cF '# BEGIN disciplined-coder' '$UC16') -eq 1 ]"
check "user note still there"         "grep -qxF 'MY OWN GLOBAL NOTE' '$UC16'"

# --- 케이스 17: 고아 여는 마커 뒤 본문은 한 줄도 지우지 않는다 (빈 줄 포함) ---
H17="$(mktemp -d)"; P17="$(mktemp -d)"; mkdir -p "$H17/.claude"
{ printf 'head note\n'
  printf '# BEGIN disciplined-coder (managed — do not edit)\n'
  printf 'para one\n'
  printf '\n'
  printf 'para two\n'
} > "$H17/.claude/CLAUDE.md"
ERR17="$(run "$H17" "$P17" 2>&1 >/dev/null)" || true
UC17="$H17/.claude/CLAUDE.md"
echo "[case17] orphan opener drops only its own line"
check "orphan: head preserved"        "grep -qxF 'head note' '$UC17'"
check "orphan: para one preserved"    "grep -qxF 'para one' '$UC17'"
check "orphan: para two preserved"    "grep -qxF 'para two' '$UC17'"
check "orphan: blank line preserved"  "[ \$(grep -c '^\$' '$UC17') -ge 1 ]"
check "orphan: warns BEGIN w/o END"   "printf '%s' \"\$ERR17\" | grep -qF 'BEGIN but no END'"
check "orphan: marker line gone"      "[ \$(grep -cF '# BEGIN disciplined-coder' '$UC17') -eq 1 ]"
```

- [ ] **Step 2: 실패를 확인한다**

Run: `bash scripts/test_scaffold.sh 2>&1 | tail -30`
Expected: `case16`의 `one BEGIN after heal`과 `no orphan marker left`가 FAIL, `case17`의 `para two preserved`는 PASS(현행 코드가 이미 비파괴다). 마지막 줄 `PASS=... FAIL=...`에서 `FAIL`이 0보다 크다.

- [ ] **Step 3: 함수를 다시 쓴다**

`scripts/_managed_block.sh` 전체를 아래로 바꾼다.

```bash
#!/usr/bin/env bash
# 공유: CLAUDE.md류 파일에 BEGIN/END 관리블록을 멱등 주입한다.
# Usage: managed_block_inject <target_file> <begin_mark> <end_mark>   (본문은 stdin)
# strip 대상은 '마커 줄'로만 한정한다 — 본문 줄은 어떤 경우에도 지우지 않는다.
#   (1) 완결 영역(여는 마커..닫는 마커)은 본문째 전부 제거. 여러 개면 모두.
#       여는 마커는 begin 또는 과거 실행이 남긴 고아 무해화 주석(자리를 바꾼 BEGIN)이다.
#   (2) 닫는 마커가 없는 여는 마커는 '그 줄만' 제거하고 경고. 뒤 내용은 사용자 것일 수 있어 보존.
#   (3) 영역 밖에 남은 짝 없는 닫는 마커도 제거.
# 본문 줄을 지우지 않는 이유: 이 함수는 codex-scaffold.sh에서 정본 전문을 본문으로 받는다.
#   본문에 빈 줄이 포함되므로 '본문과 같은 줄 제거'는 사용자 AGENTS.md의 빈 줄을 전멸시킨다.
# 표준 관리블록 마커(SSOT). 소비자(scaffold·codex-scaffold)는 begin/end를 인자로 넘긴다.
MANAGED_BEGIN="# BEGIN disciplined-coder (managed — do not edit)"
MANAGED_END="# END disciplined-coder (managed — do not edit)"
# 고아 주석은 마커 집합의 파생값이라 인자를 늘리지 않고 함수가 모듈 상수를 직접 읽는다(비대칭 의도).
# 새로 쓰지는 않는다 — (2)가 마커 줄을 지우므로 다음 실행에 고아가 남지 않는다. 읽기 전용 하위호환.
MANAGED_ORPHAN="# (disciplined-coder: orphan BEGIN neutralized — END missing)"
managed_block_inject() {
  local uc="$1" begin="$2" end="$3" body
  body="$(cat)"
  touch "$uc"
  awk -v b="$begin" -v e="$end" -v o="$MANAGED_ORPHAN" -v f="$uc" '
    { line[NR]=$0; l=$0; sub(/\r$/,"",l); norm[NR]=l }
    END {
      n=NR
      for (i=1;i<=n;i++) del[i]=0
      i=1
      while (i<=n) {
        if (norm[i]==b || norm[i]==o) {
          j=i+1; found=0
          while (j<=n) {
            if (norm[j]==e) { found=j; break }
            if (norm[j]==b || norm[j]==o) { break }
            j++
          }
          if (found) { for (k=i;k<=found;k++) del[k]=1; i=found+1 }
          else { del[i]=1; orphan=1; i++ }
        } else if (norm[i]==e) { del[i]=1; i++ }
        else { i++ }
      }
      for (i=1;i<=n;i++) if (!del[i]) print line[i]
      if (orphan) print "[disciplined-coder] WARNING: " f " has BEGIN but no END — orphan marker line dropped (content preserved)" > "/dev/stderr"
    }
  ' "$uc" > "$uc.tmp"
  awk '{ l=$0; sub(/\r$/,"",l); if (l ~ /[^ \t]/) last=NR; line[NR]=$0 } END { for (i=1;i<=last;i++) print line[i] }' "$uc.tmp" > "$uc.norm" && mv "$uc.norm" "$uc" && rm -f "$uc.tmp"
  {
    if [ -s "$uc" ]; then printf '\n'; fi
    printf '%s\n' "$begin"
    printf '%s\n' "$body"
    printf '%s\n' "$end"
  } >> "$uc"
}
```

- [ ] **Step 4: 테스트가 통과하는지 확인한다**

Run: `bash scripts/test_scaffold.sh 2>&1 | tail -5`
Expected: 마지막 줄이 `PASS=<n> FAIL=0`이다. case7·case7b·case6·case11이 여전히 PASS여야 한다.

awk의 `> "/dev/stderr"`가 이 환경에서 안 되면 `orphan: warns BEGIN w/o END`가 FAIL한다. 그때는 awk가 표식만 남기게 바꾼다 — `END` 블록의 마지막 줄을 `if (orphan) print "ORPHAN" > (f ".orphan")`로 바꾸고, awk 호출 직후 셸에서 처리한다.

```bash
  if [ -f "$uc.orphan" ]; then
    echo "[disciplined-coder] WARNING: $uc has BEGIN but no END — orphan marker line dropped (content preserved)" >&2
    rm -f "$uc.orphan"
  fi
```

- [ ] **Step 5: codex 스위트 회귀를 확인한다**

Run: `bash scripts/test_codex_scaffold.sh 2>&1 | tail -5`
Expected: 마지막 줄이 `PASS=<n> FAIL=0`이다. 이 함수를 공유하는 두 번째 소비자의 회귀 가드다.

- [ ] **Step 6: 커밋한다**

```bash
git add scripts/_managed_block.sh scripts/test_scaffold.sh
git commit -m "fix(managed-block): strip 대상을 마커 줄로 한정해 잔해 누적을 없앤다"
```

---

### Task 2: 정본 stdout 덤프를 첫 설치 세션으로 한정한다

**Files:**
- Modify: `scripts/scaffold.sh:44-59`
- Test: `scripts/test_scaffold.sh` (새 케이스 18 추가)

**Interfaces:**
- Consumes: Task 1의 `managed_block_inject`
- Produces: `scaffold.sh` 안의 지역 변수 `had_import` (0 또는 1). 다른 파일이 쓰지 않는다.

- [ ] **Step 1: 실패하는 테스트를 쓴다**

케이스 17 블록 뒤에 붙인다.

```bash
# --- 케이스 18: 정본 stdout 덤프는 첫 설치 세션에만 (이중 주입 회귀 가드) ---
H18="$(mktemp -d)"; P18="$(mktemp -d)"
OUT18a="$(run "$H18" "$P18")"
OUT18b="$(run "$H18" "$P18")"
echo "[case18] canon dumped on first run only"
check "1st run dumps principles"      "printf '%s' \"\$OUT18a\" | grep -qF '디시플린'"
check "1st run dumps solved"          "printf '%s' \"\$OUT18a\" | grep -qF '해결된 문제 로그 (solved_problems)'"
check "2nd run omits principles"      "! printf '%s' \"\$OUT18b\" | grep -qF '디시플린'"
check "2nd run omits solved"          "! printf '%s' \"\$OUT18b\" | grep -qF '해결된 문제 로그 (solved_problems)'"
check "2nd run keeps issue mode line" "printf '%s' \"\$OUT18b\" | grep -qF '처분 모드:'"
check "2nd run keeps ucr mode line"   "printf '%s' \"\$OUT18b\" | grep -qF '검증 모드:'"

# --- 케이스 19: CRLF 관리영역에서도 재주입하지 않는다 (had_import의 CR 내성) ---
H19="$(mktemp -d)"; P19="$(mktemp -d)"; mkdir -p "$H19/.claude"
printf '# BEGIN disciplined-coder (managed — do not edit)\r\n@disciplined-coder/agent-principles.md\r\n@disciplined-coder/domains-index.md\r\n@disciplined-coder/solved_problems.md\r\n# END disciplined-coder (managed — do not edit)\r\n' > "$H19/.claude/CLAUDE.md"
OUT19="$(run "$H19" "$P19")"
echo "[case19] CRLF import line still counts as present"
check "CRLF: no canon re-dump"        "! printf '%s' \"\$OUT19\" | grep -qF '디시플린'"
check "CRLF: mode line still sent"    "printf '%s' \"\$OUT19\" | grep -qF '처분 모드:'"
```

- [ ] **Step 2: 실패를 확인한다**

Run: `bash scripts/test_scaffold.sh 2>&1 | grep -A8 'case18'`
Expected: `2nd run omits principles`와 `2nd run omits solved`가 FAIL이다. 현행 코드는 매 실행 덤프하기 때문이다.

- [ ] **Step 3: `scaffold.sh`를 고친다**

44행부터 59행까지를 아래로 바꾼다.

```bash
# 3) ~/.claude/CLAUDE.md 관리블록 재생성(멱등, CRLF 내성). 상대 @import(= ~/.claude 기준).
. "$(dirname "$0")/_managed_block.sh"
# 마커는 _managed_block.sh의 MANAGED_BEGIN/END(SSOT)를 쓴다.
# 스킬(domain-*/reviewer-*)은 플러그인에서 온디맨드 — 복사/주입 안 함.
# 첫 설치 판정은 반드시 주입 '전에' 한다 — 주입 후엔 항상 존재해 판정이 무의미해진다.
# -x(줄 전체 일치)를 쓰지 않는 이유: CRLF 파일에서 줄 끝 CR 때문에 영원히 거짓이 되어
# 이중 주입이 조용히 되살아난다(이 레포는 CRLF를 실재 문제로 이미 다룬다).
had_import=0
if [ -f "$UC" ] && grep -qF '@disciplined-coder/agent-principles.md' "$UC"; then had_import=1; fi
managed_block_inject "$UC" "$MANAGED_BEGIN" "$MANAGED_END" <<'EOF'
@disciplined-coder/agent-principles.md
@disciplined-coder/domains-index.md
@disciplined-coder/solved_problems.md
EOF

# 4) 첫 세션 도달 보강: CLAUDE.md는 이 훅보다 먼저 로드되므로, 블록을 방금 만든 세션은
#    @import만으로 정본에 닿지 못한다. 그 세션에만 stdout(additionalContext)으로 보강한다.
#    이후 세션은 @import 한 경로로만 로드한다 — 같은 내용을 두 번 싣지 않는다.
if [ "$had_import" -eq 0 ]; then
  for f in agent-principles.md domains-index.md solved_problems.md; do
    if [ -f "$KDIR/$f" ]; then cat "$KDIR/$f"; fi
  done
fi
# 토글 모드 라인은 @import 대상 파일에 없는 휘발성 상태라 매 세션 보낸다(조건 밖).
printf '%s\n' "$mode_line"
if [ -n "$mode_note" ]; then printf '%s\n' "$mode_note"; fi
printf '%s\n' "$ucr_mode_line"
if [ -n "$ucr_mode_note" ]; then printf '%s\n' "$ucr_mode_note"; fi
```

- [ ] **Step 4: 테스트가 통과하는지 확인한다**

Run: `bash scripts/test_scaffold.sh 2>&1 | tail -5`
Expected: 마지막 줄이 `PASS=<n> FAIL=0`이다. case1의 `stdout has principle marker`와 `stdout has solved marker`는 첫 실행이라 계속 PASS여야 한다.

- [ ] **Step 5: 커밋한다**

```bash
git add scripts/scaffold.sh scripts/test_scaffold.sh
git commit -m "fix(scaffold): 정본 stdout 덤프를 첫 설치 세션으로 한정해 이중 주입을 없앤다"
```

---

### Task 3: `/add-pointer`와 그 넛지를 제거한다

**Files:**
- Delete: `scripts/add-pointer.sh`, `commands/add-pointer.md`
- Modify: `hooks/doc_review_posttooluse.sh:21-39`
- Modify: `scripts/test_hooks.sh:130-151`
- Modify: `scripts/test_scaffold.sh` (케이스 11 삭제)
- Modify: `README.md` (5·8·15·57·66행)
- Modify: `scripts/_managed_block.sh` (소비자 열거 주석)

**Interfaces:**
- Consumes: Task 1과 Task 2의 결과 (테스트 스위트가 이미 초록이어야 한다)
- Produces: 없음. 순수 제거다.

- [ ] **Step 1: 훅에서 오답노트 넛지를 뺀다**

`hooks/doc_review_posttooluse.sh`의 21행부터 39행까지(주석 `# 프로젝트 루트 CLAUDE.md면...`부터 그 `fi`까지)를 통째로 지운다. 지운 자리에 아래 주석 한 줄을 남긴다.

```bash
# (제거됨) 오답노트 발견·복구 넛지 — /add-pointer 폐지와 함께 뺐다. 빈 템플릿을 미리 만들라는
# 권유였는데, 빈 파일은 recall이 발화해도 얻는 교훈이 0이다. 이제 교훈이 생긴 시점에 만든다.
```

이렇게 하면 프로젝트 루트 `CLAUDE.md`를 고쳐도 41행의 generic 검진 넛지가 나온다. 의도한 동작이다.

- [ ] **Step 2: 훅 테스트에서 해당 블록을 뺀다**

`scripts/test_hooks.sh`의 130행 `echo "[project-solved nudge]"`부터 151행까지를 지운다. 그 자리에 아래를 넣어 제거를 계약으로 고정한다.

```bash
echo "[project-solved nudge removed]"
PN="$(mktemp -d)"
in_claudemd() { printf '{"tool_name":"Write","tool_input":{"file_path":"%s/CLAUDE.md"}}' "$1"; }
OUT_GONE="$(in_claudemd "$PN" | CLAUDE_PROJECT_DIR="$PN" bash "$DREV" 2>&1)" || true
check "no add-pointer nudge anymore"  "! printf '%s' \"\$OUT_GONE\" | grep -qF 'add-pointer'"
check "generic nudge fires instead"   "printf '%s' \"\$OUT_GONE\" | grep -qF 'reviewer-grounding'"
check "hook writes no project file"   "[ ! -f '$PN/docs/solved_problems.md' ]"
```

- [ ] **Step 3: scaffold 테스트에서 케이스 11을 뺀다**

`scripts/test_scaffold.sh`의 124행 `# --- 케이스 11: /add-pointer ...`부터 144행 `check "half-broken block normalized" ...`까지를 지운다.

- [ ] **Step 4: 스크립트와 커맨드를 지운다**

```bash
git rm scripts/add-pointer.sh commands/add-pointer.md
```

- [ ] **Step 5: `_managed_block.sh`의 소비자 주석을 고친다**

```bash
# 표준 관리블록 마커(SSOT). 소비자(scaffold·codex-scaffold)는 begin/end를 인자로 넘긴다.
```

Task 1에서 이미 이 문구로 썼다면 확인만 하고 넘어간다.

- [ ] **Step 6: `README.md`에서 `/add-pointer`를 뺀다**

다섯 곳을 아래 문구로 정확히 바꾼다. 한국어를 유지한다.

**5행** — 끝의 괄호 문장을 지운다.

```markdown
**대상** — 팀 디시플린을 모든 프로젝트와 서브에이전트에 걸쳐 PC 전역으로 강제하되, 프로젝트 폴더는 (자동으로는) 더럽히고 싶지 않은 Claude Code 사용자.
```

**8행** — 예외 괄호를 지우고 새 규칙을 한 문장으로 붙인다.

```markdown
- **프로젝트 폴더 footprint zero (자동)** — 지식은 `~/.claude/CLAUDE.md` 관리블록이 `@import`로 주입한다. 어느 프로젝트를 열어도 작업 폴더엔 **자동으로는** 아무 파일도 안 생긴다. 그 레포에서 문제를 해결해 적을 교훈이 생기면 그때 `docs/solved_problems.md`를 만든다.
```

**15행** — 옵트인 괄호만 들어낸다. 나머지 문장은 그대로 둔다.

```markdown
모든 세션·서브에이전트가 같은 디시플린을 들고 일하게 하되, **자동 계층(scaffold·훅)은 프로젝트 폴더를 건드리지 않는다**. 그래서 지식을 프로젝트가 아니라 **PC-레벨**(`~/.claude/`)에 두고, `~/.claude/CLAUDE.md`의 관리블록이 그것을 `@import`한다. Claude Code 서브에이전트는 시작 시 이 메모리 계층을 함께 로드하므로, 한 곳에 배선하면 메인과 서브에이전트 모두에 도달한다(상세·예외는 [DESIGN-NOTES](docs/DESIGN-NOTES.md)).
```

**57행** — 끝의 예외 괄호를 지운다.

```markdown
이후 어느 프로젝트에서 열어도 메인 세션과 모든 서브에이전트가 원칙 + 도메인 목차 + 오답노트를 자동으로 보유한다. **자동 계층은 프로젝트 폴더를 건드리지 않는다.**
```

**66행** — 커맨드 목록에서 이 줄을 통째로 지운다. 앞뒤 줄(`/issue-mode`와 `/ultracode-review`)은 그대로 둔다.

```text
/add-pointer         # 이 프로젝트에 오답노트(docs/solved_problems.md) + CLAUDE.md 포인터 추가(옵트인)
```

`test_scaffold.sh` 케이스 13이 README의 `### 커맨드` 절과 `commands/` 디렉터리의 일치를 검사하므로, 이 줄을 남기면 커맨드 파일이 없는데 README에만 있어 FAIL한다.

- [ ] **Step 7: 세 스위트를 모두 돌린다**

Run: `bash scripts/test_scaffold.sh 2>&1 | tail -3 && bash scripts/test_hooks.sh 2>&1 | tail -3 && bash scripts/test_codex_scaffold.sh 2>&1 | tail -3`
Expected: 세 줄 모두 `PASS=<n> FAIL=0`이다.

- [ ] **Step 8: 플러그인 매니페스트를 검증한다**

Run: `claude plugin validate ./`
Expected: 오류 없이 통과한다(non-strict). 커맨드 파일을 지웠으므로 매니페스트가 그것을 참조하지 않는지 확인하는 단계다.

- [ ] **Step 9: 커밋한다**

```bash
git add -A
git commit -m "refactor(add-pointer): 커맨드·넛지·테스트·README 항목을 제거한다"
```

---

### Task 4: 이 머신의 손상된 `~/.claude/CLAUDE.md`를 1회 정리한다

**Files:**
- Modify: `C:/Users/CHSHIN/.claude/CLAUDE.md` (레포 밖 · 커밋 대상 아님)

**Interfaces:**
- Consumes: Task 1과 Task 2가 커밋된 상태
- Produces: 없음

- [ ] **Step 1: 현재 상태를 기록한다**

Run: `cat "C:/Users/CHSHIN/.claude/CLAUDE.md"`
Expected: 짝 없는 END와 고아 주석과 반복 블록이 보인다. 사용자가 직접 쓴 줄이 있는지 눈으로 확인한다. 있으면 그 줄을 따로 적어 두고 Step 3에서 되살린다.

- [ ] **Step 2: 자기 치유를 돌린다**

Run: `CLAUDE_HOME_DIR="C:/Users/CHSHIN/.claude" CLAUDE_PROJECT_DIR="D:/projects/disciplined-coder" CLAUDE_PLUGIN_ROOT="D:/projects/disciplined-coder" bash scripts/scaffold.sh >/dev/null`
Expected: 고아 주석과 짝 없는 마커가 사라지고 관리 블록이 하나만 남는다.

- [ ] **Step 3: 남은 잔해 세 줄을 손으로 지운다**

Task 1의 규칙은 본문 줄을 지우지 않으므로, 여는 마커를 잃은 `@disciplined-coder/*.md` 세 줄이 관리 블록 밖에 남는다. 파일을 열어 **관리 블록 바깥**의 그 세 줄만 지운다. 관리 블록 안의 세 줄은 그대로 둔다.

- [ ] **Step 4: 결과를 확인한다**

Run: `cat "C:/Users/CHSHIN/.claude/CLAUDE.md"`
Expected: `# BEGIN`이 한 번, `# END`가 한 번, 그 사이에 `@import` 세 줄. 그 밖에는 아무것도 없다.

- [ ] **Step 5: 재실행해도 그대로인지 본다**

Run: `CLAUDE_HOME_DIR="C:/Users/CHSHIN/.claude" CLAUDE_PROJECT_DIR="D:/projects/disciplined-coder" CLAUDE_PLUGIN_ROOT="D:/projects/disciplined-coder" bash scripts/scaffold.sh >/dev/null && grep -c 'BEGIN disciplined-coder' "C:/Users/CHSHIN/.claude/CLAUDE.md"`
Expected: `1`이 출력된다.

커밋할 것이 없다. 레포 밖 파일이다.

---

## 완료 기준

- 세 스위트가 모두 `FAIL=0`이다.
- `claude plugin validate ./`가 통과한다.
- `~/.claude/CLAUDE.md`에 관리 블록이 정확히 하나이고 잔해가 없다.
- `scripts/add-pointer.sh`와 `commands/add-pointer.md`가 없고, `README.md`와 훅에 `/add-pointer` 언급이 남아 있지 않다. `grep -rn 'add-pointer' --include='*.md' --include='*.sh' .` 이 `docs/superpowers/` 밖에서 결과를 내지 않는다.

<!-- spec-review: passed -->
