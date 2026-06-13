#!/usr/bin/env bash
# Idempotent. Runs at every SessionStart; only creates what's missing.
# Scaffolds per-project issue logs and wires CLAUDE.md @imports.
set -euo pipefail

ROOT="${CLAUDE_PROJECT_DIR:-$PWD}"
SOLVED="$ROOT/solved_problems.md"
UNSOLVED="$ROOT/unsolved_problems.md"
CLAUDE_MD="$ROOT/CLAUDE.md"

created=()

if [ ! -f "$SOLVED" ]; then
  cat > "$SOLVED" <<'EOF'
# 해결된 문제 로그 (solved_problems)

작업 중 발견·해결된 문제 기록. 각 항목: 문제 → 원인 → 해결.
일반화 가능한 항목은 팀 플러그인(coding-discipline)으로 승격하고 여기서는 제거(SSOT).
(미해결·대기 항목은 `unsolved_problems.md`.)
EOF
  created+=("solved_problems.md")
fi

if [ ! -f "$UNSOLVED" ]; then
  cat > "$UNSOLVED" <<'EOF'
# 미해결 / 대기 문제 (unsolved_problems)

> ⚠️ 모든 에이전트 지침(이 파일은 CLAUDE.md @import로 모든 서브에이전트 컨텍스트에 로드됨):
> 아래 **🔴 항목은 사용자 결정 대기** 상태다. 어떤 에이전트도 🔴 항목을 **자율적으로 구현·수정하지 마라.**
> 참고만 하고, 필요하면 메인 세션에 결정 요청을 올려라. (CLAUDE.md는 가이드일 뿐 강제가 아니므로,
> 강제가 필요하면 PreToolUse hook로 막아라.)

발견됐으나 안 끝난 것 + 사용자 결정이 필요한 것. (해결되면 `solved_problems.md`로 이동.)
범례: 🔴 사용자 결정 필요(에이전트 자율 구현 금지) · 🟡 방향 정해짐·구현 대기 · 🔵 향후/선택.

## 🔴 결정 필요

## 🟡 구현 대기

## 🔵 향후 / 선택
EOF
  created+=("unsolved_problems.md")
fi

# Wire CLAUDE.md imports as ONE atomic block, keyed off a whole-line sentinel.
# Whole-line match (grep -qxF, note -x) avoids false positives from prose that
# merely mentions "@solved_problems.md" somewhere in CLAUDE.md.
touch "$CLAUDE_MD"
SENTINEL="## 프로젝트 이슈 로그 (자동 주입)"
if ! grep -qxF "$SENTINEL" "$CLAUDE_MD"; then
  printf '\n%s\n@solved_problems.md\n@unsolved_problems.md\n' "$SENTINEL" >> "$CLAUDE_MD"
fi

if [ ${#created[@]} -gt 0 ]; then
  echo "[disciplined-coder] scaffolded: ${created[*]} (+ CLAUDE.md imports wired)"
fi
exit 0
