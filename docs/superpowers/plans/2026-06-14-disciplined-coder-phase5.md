# disciplined-coder Phase 5 (PC-레벨 전환) Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: superpowers:subagent-driven-development. Steps use checkbox (`- [ ]`).

**Goal:** 지식 전달을 **프로젝트-레벨 → PC-레벨**로 전환한다. principles/domains-index/solved/unsolved를 `~/.claude/disciplined-coder/`에 두고, `~/.claude/CLAUDE.md` 관리블록이 @import한다. **프로젝트 폴더·프로젝트 CLAUDE.md는 전혀 안 건드린다(footprint 0).** 스킬은 복사 안 함(플러그인에서 온디맨드).

**Architecture:** SessionStart hook이 (프로젝트가 아니라) **사용자 홈의 `~/.claude/`** 를 셋업한다. `@import`는 고정 경로가 필요하므로 정적 파일(principles/domains-index/solved)만 PC 한 곳에 복사/생성하고 `~/.claude/CLAUDE.md`에서 상대경로로 @import(`@disciplined-coder/...`). 스킬은 Claude Code가 플러그인 캐시에서 동적 발견하므로 손대지 않는다. 테스트는 `CLAUDE_HOME_DIR` 오버라이드로 임시 홈에서 검증(실제 ~/.claude 미오염).

**참조:** 직전 대화(PC-레벨 결정, 프로젝트 footprint 0, 스킬 비복사). §3-1(서브에이전트는 ~/.claude/CLAUDE.md 포함 메모리 계층 로드).

**핵심 사실:** ~/.claude/CLAUDE.md는 메모리 계층의 유저 글로벌 파일 → 모든 프로젝트 + 모든 서브에이전트(Explore/Plan 제외)에 로드. 거기 @import하면 PC 전역 도달.

---

## File Structure (Phase 5)
- **Modify** `scripts/scaffold.sh` — PC-레벨로 전면 재작성(아래 Step 1 전체 내용).
- **Modify** `scripts/test_scaffold.sh` — `CLAUDE_HOME_DIR` 임시 홈 기반으로 재작성.
- **Delete** (repo dogfood 산물) `solved_problems.md`, `unsolved_problems.md`.
- **Modify** `CLAUDE.md` — 관리블록 제거(이제 PC-레벨이 적용), 개발 노트 헤더만 유지.
- **Modify** `README.md` — PC-레벨 모델로 설명 갱신.
- **Keep** `coding-principles.md`, `domains-index.md` (플러그인 SSOT, repo 루트 유지), `skills/*`(미변경).

---

## Task 1: scaffold.sh PC-레벨 재작성 + test 재작성 (TDD)

**Files:** `scripts/scaffold.sh`, `scripts/test_scaffold.sh`

- [ ] **Step 1: `scripts/test_scaffold.sh` 전체 교체** (임시 홈 기반; 프로젝트 미오염 검증 포함):
```bash
#!/usr/bin/env bash
# scaffold.sh(PC-레벨) 검증. 계약: FAIL=0.
set -euo pipefail
HERE="$(cd "$(dirname "$0")/.." && pwd)"
SCAFFOLD="$HERE/scripts/scaffold.sh"

pass=0; fail=0
check() { if eval "$2"; then echo "  PASS: $1"; pass=$((pass+1)); else echo "  FAIL: $1"; fail=$((fail+1)); fi; }

run() {  # $1=HOME dir, $2=project dir  → echoes scaffold stdout
  CLAUDE_HOME_DIR="$1/.claude" CLAUDE_PROJECT_DIR="$2" CLAUDE_PLUGIN_ROOT="$HERE" bash "$SCAFFOLD"
}

# --- 케이스 1: 신규 PC ---
H1="$(mktemp -d)"; P1="$(mktemp -d)"
OUT="$(run "$H1" "$P1")"
K="$H1/.claude/disciplined-coder"; UC="$H1/.claude/CLAUDE.md"
echo "[case1] fresh PC"
check "principles in PC dir"          "[ -f '$K/coding-principles.md' ]"
check "domains-index in PC dir"       "[ -f '$K/domains-index.md' ]"
check "solved created in PC dir"      "[ -f '$K/solved_problems.md' ]"
check "unsolved created in PC dir"    "[ -f '$K/unsolved_problems.md' ]"
check "user CLAUDE.md imports principles" "grep -qxF '@disciplined-coder/coding-principles.md' '$UC'"
check "user CLAUDE.md imports domains"    "grep -qxF '@disciplined-coder/domains-index.md' '$UC'"
check "user CLAUDE.md imports solved"     "grep -qxF '@disciplined-coder/solved_problems.md' '$UC'"
check "user CLAUDE.md does NOT import unsolved" "! grep -qxF '@disciplined-coder/unsolved_problems.md' '$UC'"
check "managed region once"           "[ \$(grep -cF '# BEGIN disciplined-coder' '$UC') -eq 1 ]"
check "stdout has principle marker"   "printf '%s' \"\$OUT\" | grep -qF '코딩 디시플린'"

# --- 케이스 2: 프로젝트 폴더 무오염 ---
echo "[case2] project untouched"
check "no principles in project"      "[ ! -f '$P1/coding-principles.md' ]"
check "no solved in project"          "[ ! -f '$P1/solved_problems.md' ]"
check "no CLAUDE.md in project"       "[ ! -f '$P1/CLAUDE.md' ]"

# --- 케이스 3: 멱등성 (3회) ---
run "$H1" "$P1" >/dev/null; run "$H1" "$P1" >/dev/null
echo "[case3] idempotency"
check "still one region"              "[ \$(grep -cF '# BEGIN disciplined-coder' '$UC') -eq 1 ]"
check "principles import not dup"     "[ \$(grep -cxF '@disciplined-coder/coding-principles.md' '$UC') -eq 1 ]"

# --- 케이스 4: solved 누적 보존 ---
echo "[case4] solved preserved"
printf '\n- 기존 항목 보존 확인\n' >> "$K/solved_problems.md"
run "$H1" "$P1" >/dev/null
check "solved entry preserved"        "grep -qF '기존 항목 보존 확인' '$K/solved_problems.md'"

# --- 케이스 5: 기존 user CLAUDE.md 내용 보존 + 블랭크 비누적 ---
H5="$(mktemp -d)"; P5="$(mktemp -d)"
mkdir -p "$H5/.claude"; printf 'my personal global note\n' > "$H5/.claude/CLAUDE.md"
for _ in 1 2 3; do run "$H5" "$P5" >/dev/null; done
UC5="$H5/.claude/CLAUDE.md"
echo "[case5] preserve user content + no blank accumulation"
check "personal note preserved"      "grep -qxF 'my personal global note' '$UC5'"
check "one region after 3 runs"      "[ \$(grep -cF '# BEGIN disciplined-coder' '$UC5') -eq 1 ]"
check "blank lines bounded (<=1)"    "[ \$(grep -c '^\$' '$UC5') -le 1 ]"

# --- 케이스 6: CRLF 관리영역 인식 ---
H6="$(mktemp -d)"; P6="$(mktemp -d)"; mkdir -p "$H6/.claude"
printf 'note\r\n# BEGIN disciplined-coder (managed — do not edit)\r\n@disciplined-coder/coding-principles.md\r\n# END disciplined-coder (managed — do not edit)\r\n' > "$H6/.claude/CLAUDE.md"
run "$H6" "$P6" >/dev/null
echo "[case6] CRLF region recognized"
check "CRLF region not duplicated"   "[ \$(grep -cF '# BEGIN disciplined-coder' '$H6/.claude/CLAUDE.md') -eq 1 ]"

echo "----"; echo "PASS=$pass FAIL=$fail"; [ "$fail" -eq 0 ]
```

- [ ] **Step 2:** Run → FAIL(현재 scaffold는 프로젝트-레벨). Capture.

- [ ] **Step 3: `scripts/scaffold.sh` 전체 교체**:
```bash
#!/usr/bin/env bash
# Idempotent. SessionStart마다 실행. 지식을 PC(~/.claude/disciplined-coder)에 두고
# ~/.claude/CLAUDE.md 관리블록이 @import. 프로젝트 폴더는 건드리지 않는다.
set -euo pipefail

PLUGIN_ROOT="${CLAUDE_PLUGIN_ROOT:-$(cd "$(dirname "$0")/.." && pwd)}"
CLAUDE_HOME="${CLAUDE_HOME_DIR:-$HOME/.claude}"   # 테스트는 CLAUDE_HOME_DIR로 오버라이드
KDIR="$CLAUDE_HOME/disciplined-coder"
UC="$CLAUDE_HOME/CLAUDE.md"

mkdir -p "$KDIR"
created=""

# 1) 정본(static) 복사·갱신: principles, domains-index. src==dst면 생략.
for f in coding-principles.md domains-index.md; do
  src="$PLUGIN_ROOT/$f"; dst="$KDIR/$f"
  if [ -f "$src" ]; then
    if [ "$src" = "$dst" ] || { [ -e "$dst" ] && [ "$src" -ef "$dst" ]; }; then :; else cp "$src" "$dst"; fi
  else
    echo "[disciplined-coder] WARNING: source not found at $src" >&2
  fi
done

# 2) solved/unsolved 누적 파일: 없을 때만 생성.
if [ ! -f "$KDIR/solved_problems.md" ]; then
  cat > "$KDIR/solved_problems.md" <<'EOF'
# 해결된 문제 로그 (solved_problems) — PC 전역

작업 중 발견·해결된 문제. 각 항목: 문제 → 원인 → 해결. 등록·이동은 메인 세션이 수행.
일반화 가능한 항목은 디시플린(coding-principles.md)으로 승격하고 여기서는 제거(SSOT).
EOF
  created="$created solved_problems.md"
fi
if [ ! -f "$KDIR/unsolved_problems.md" ]; then
  cat > "$KDIR/unsolved_problems.md" <<'EOF'
# 미해결 / 대기 문제 (unsolved_problems) — PC 전역

> ⚠️ 🔴 항목은 사용자 결정 대기 — 어떤 에이전트도 자율 구현·수정 금지. 참고만.
등록은 검증/리뷰 종료 시, solved 이동은 테스트 통과 시 — 메인 세션이 수행.
범례: 🔴 결정 필요 · 🟡 구현 대기 · 🔵 향후.

## 🔴 결정 필요

## 🟡 구현 대기

## 🔵 향후 / 선택
EOF
  created="$created unsolved_problems.md"
fi

# 3) ~/.claude/CLAUDE.md 관리블록 재생성(멱등, CRLF 내성). 상대 @import(= ~/.claude 기준).
touch "$UC"
BEGIN_MARK="# BEGIN disciplined-coder (managed — do not edit)"
END_MARK="# END disciplined-coder (managed — do not edit)"
if grep -qF "$BEGIN_MARK" "$UC" && grep -qF "$END_MARK" "$UC"; then
  awk -v b="$BEGIN_MARK" -v e="$END_MARK" '{ l=$0; sub(/\r$/,"",l) } l==b{skip=1} skip==0{print} l==e{skip=0}' "$UC" > "$UC.tmp"
elif grep -qF "$BEGIN_MARK" "$UC"; then
  echo "[disciplined-coder] WARNING: ~/.claude/CLAUDE.md has BEGIN but no END — skipping strip" >&2
  cp "$UC" "$UC.tmp"
else
  cp "$UC" "$UC.tmp"
fi
awk '{ l=$0; sub(/\r$/,"",l); if (l ~ /[^ \t]/) last=NR; line[NR]=$0 } END { for (i=1;i<=last;i++) print line[i] }' "$UC.tmp" > "$UC" && rm -f "$UC.tmp"
{
  if [ -s "$UC" ]; then printf '\n'; fi
  printf '%s\n' "$BEGIN_MARK"
  # unsolved는 미주입(백로그). 스킬(domain-*/advisor-*)은 플러그인에서 온디맨드 — 복사/주입 안 함.
  printf '@disciplined-coder/coding-principles.md\n@disciplined-coder/domains-index.md\n@disciplined-coder/solved_problems.md\n'
  printf '%s\n' "$END_MARK"
} >> "$UC"

# 4) 첫 세션 도달 보강: principles + domains-index를 stdout으로.
for f in coding-principles.md domains-index.md; do
  if [ -f "$KDIR/$f" ]; then cat "$KDIR/$f"; fi
done

# 5) 보고
if [ -n "$created" ]; then echo "[disciplined-coder] PC knowledge initialized:$created (at $KDIR)"; fi
exit 0
```

- [ ] **Step 4:** `bash -n scripts/scaffold.sh` clean; `bash scripts/test_scaffold.sh` → **FAIL=0**.
- [ ] **Step 5:** Commit: `git add scripts/scaffold.sh scripts/test_scaffold.sh && git commit -m "feat(scaffold): PC-level delivery (~/.claude/disciplined-coder + ~/.claude/CLAUDE.md); project footprint zero"`

---

## Task 2: repo dogfood 산물 정리

**Files:** delete `solved_problems.md`, `unsolved_problems.md`; modify `CLAUDE.md`

- [ ] **Step 1:** `git rm solved_problems.md unsolved_problems.md` (이건 과거 프로젝트-레벨 도그푸딩 산물 — PC-레벨에선 ~/.claude로 감). `coding-principles.md`·`domains-index.md`는 **유지**(플러그인 SSOT).

- [ ] **Step 2:** `CLAUDE.md`를 개발 노트만 남기고 관리블록 제거. 전체를 이걸로 교체:
```markdown
# disciplined-coder (개발 노트)

이 레포는 disciplined-coder 플러그인 자체다. 디시플린은 **PC-레벨**로 적용된다
(설치 후 SessionStart hook이 `~/.claude/disciplined-coder/` + `~/.claude/CLAUDE.md`를 셋업).
따라서 이 레포 루트엔 프로젝트-레벨 사본을 두지 않는다(coding-principles.md·domains-index.md는 플러그인 SSOT 원본).

- 디시플린 정본: `coding-principles.md` (SSOT, ID 글로서리·무순서). 도메인 목차: `domains-index.md`.
- scaffold 검증: `bash scripts/test_scaffold.sh` (계약 **FAIL=0**. 매직 넘버 금지 — `SSOT`).
- 변경 후: 위 테스트 + `claude plugin validate ./` (non-strict).
- 설계/계획: `docs/superpowers/`.
```

- [ ] **Step 3:** Commit: `git add -A && git commit -m "chore: drop project-level dogfood artifacts; CLAUDE.md is dev-note only (PC-level applies)"`

---

## Task 3: README + 실제 PC 셋업(도그푸딩) + 검증

**Files:** `README.md`; 실제 ~/.claude 셋업

- [ ] **Step 1:** `README.md` 갱신:
  - "무엇을 자동화하나"·"구성"·"동작"·"한계" 섹션에서 **"프로젝트 CLAUDE.md @import"** 서술을 **"PC-레벨(~/.claude/disciplined-coder + ~/.claude/CLAUDE.md)"** 로 교체. **"프로젝트 폴더엔 아무것도 안 생긴다"** 명시.
  - 스킬은 플러그인에서 온디맨드(복사 안 함) 명시.
  - 설치/사용 절차: 설치 후 새 세션 시작 시 hook이 ~/.claude를 셋업한다고.

- [ ] **Step 2 (검증 — 실제 홈 미오염):** 실제 `~/.claude`는 **건드리지 않는다.** 임시 홈으로 PC-레벨 동작을 확인:
```bash
T="$(mktemp -d)"; CLAUDE_HOME_DIR="$T/.claude" CLAUDE_PLUGIN_ROOT="$PWD" CLAUDE_PROJECT_DIR="$PWD" bash scripts/scaffold.sh >/dev/null 2>&1; echo exit=$?
ls "$T/.claude/disciplined-coder/"
sed -n '/# BEGIN disciplined-coder/,/# END disciplined-coder/p' "$T/.claude/CLAUDE.md"
echo "project untouched? $([ ! -f "$PWD/solved_problems.md" ] && echo yes)"
```
확인: 임시 홈에 4파일 + 관리블록(@disciplined-coder/... 3개), 이 레포 폴더엔 변화 없음.
> 실제 PC 셋업(진짜 `~/.claude` 수정)은 **플러그인 설치 후 다음 세션에 hook이 자동** 수행한다(또는 사용자가 원할 때 수동). 빌드 단계에서 사용자 글로벌 파일을 건드리지 않는다.

- [ ] **Step 3:** 검증: `bash scripts/test_scaffold.sh` → FAIL=0. `claude plugin validate ./`(non-strict) 통과.

- [ ] **Step 4:** Commit: `git add README.md && git commit -m "docs: PC-level model (project footprint zero); skills load on-demand from plugin"`

---

## Self-Review
- 지식 PC-레벨(~/.claude/disciplined-coder) + ~/.claude/CLAUDE.md 주입 → Task 1. ✓
- 프로젝트 footprint 0(테스트 case2로 보장) → Task 1. ✓
- 스킬 비복사(플러그인 온디맨드) → 설계상 미변경 + README 명시. ✓
- unsolved 미주입 유지 → Task 1 블록. ✓
- repo 자체도 프로젝트-레벨 산물 제거 → Task 2. ✓
- 테스트는 CLAUDE_HOME_DIR로 실제 홈 미오염 → Task 1. ✓
- 하드닝(CRLF/inode/blank/멱등) 유지 → Task 1. ✓
- 계약 FAIL=0(매직 넘버 금지). Placeholder 없음.
