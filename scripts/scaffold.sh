#!/usr/bin/env bash
# Idempotent. SessionStart마다 실행. 없는 것만 만들고, 관리 영역은 항상 재생성.
# 디시플린 + 어드바이저 인덱스 주입 + 프로젝트 이슈 로그 스캐폴드 + CLAUDE.md @import 배선.
# 주의: 관리 영역(BEGIN/END 블록)은 항상 CLAUDE.md 끝에 위치한다.
#       사용자 콘텐츠는 블록 위에 둘 것 — 블록 뒤 내용은 다음 실행 때 블록 앞으로 재배치된다.
set -euo pipefail

ROOT="${CLAUDE_PROJECT_DIR:-$PWD}"
PLUGIN_ROOT="${CLAUDE_PLUGIN_ROOT:-$(cd "$(dirname "$0")/.." && pwd)}"

SOLVED="$ROOT/solved_problems.md"
UNSOLVED="$ROOT/unsolved_problems.md"
CLAUDE_MD="$ROOT/CLAUDE.md"

created=""

# 1) 플러그인 정본 파일들을 프로젝트로 복사(매 세션 갱신 = SSOT에서 도출).
#    src==dst(같은 파일)면 생략 — 문자열 + inode(-ef) 양쪽 판정(cp self-truncate 방지).
copy_from_plugin() {  # $1 = filename
  local src="$PLUGIN_ROOT/$1" dst="$ROOT/$1"
  if [ -f "$src" ]; then
    if [ "$src" = "$dst" ] || { [ -e "$dst" ] && [ "$src" -ef "$dst" ]; }; then
      : # same file — skip copy
    else
      cp "$src" "$dst"
    fi
  else
    echo "[disciplined-coder] WARNING: source not found at $src" >&2
  fi
}
PLUGIN_FILES="coding-principles.md advisors-index.md"
for f in $PLUGIN_FILES; do copy_from_plugin "$f"; done

# 2) 이슈 로그 생성(없을 때만)
if [ ! -f "$SOLVED" ]; then
  cat > "$SOLVED" <<'EOF'
# 해결된 문제 로그 (solved_problems)

작업 중 발견·해결된 문제 기록. 각 항목: 문제 → 원인 → 해결.
일반화 가능한 항목은 디시플린(coding-principles.md)으로 승격하고 여기서는 제거(SSOT).
(미해결·대기 항목은 `unsolved_problems.md`.)
등록·이동은 메인 세션이 수행한다(생애주기 규약: coding-principles.md "절차").
EOF
  created="$created solved_problems.md"
fi

if [ ! -f "$UNSOLVED" ]; then
  cat > "$UNSOLVED" <<'EOF'
# 미해결 / 대기 문제 (unsolved_problems)

> ⚠️ 모든 에이전트 지침(이 파일은 CLAUDE.md @import로 모든 서브에이전트 컨텍스트에 로드됨):
> 아래 **🔴 항목은 사용자 결정 대기** 상태다. 어떤 에이전트도 🔴 항목을 **자율적으로 구현·수정하지 마라.**
> 참고만 하고, 필요하면 메인 세션에 결정 요청을 올려라.

발견됐으나 안 끝난 것 + 사용자 결정이 필요한 것. (해결되면 `solved_problems.md`로 이동.)
등록은 검증/리뷰 종료 시, solved 이동은 테스트 통과 시 — 메인 세션이 수행(coding-principles.md "절차").
범례: 🔴 사용자 결정 필요(에이전트 자율 구현 금지) · 🟡 방향 정해짐·구현 대기 · 🔵 향후/선택.

## 🔴 결정 필요

## 🟡 구현 대기

## 🔵 향후 / 선택
EOF
  created="$created unsolved_problems.md"
fi

# 3) CLAUDE.md 관리 영역 재생성(멱등). CRLF 내성: 마커 비교 시 trailing \r 제거.
touch "$CLAUDE_MD"
BEGIN_MARK="# BEGIN disciplined-coder (managed — do not edit)"
END_MARK="# END disciplined-coder (managed — do not edit)"

if grep -qF "$BEGIN_MARK" "$CLAUDE_MD" && grep -qF "$END_MARK" "$CLAUDE_MD"; then
  awk -v b="$BEGIN_MARK" -v e="$END_MARK" '
    { l=$0; sub(/\r$/,"",l) }
    l==b {skip=1}
    skip==0 {print}
    l==e {skip=0}
  ' "$CLAUDE_MD" > "$CLAUDE_MD.tmp"
elif grep -qF "$BEGIN_MARK" "$CLAUDE_MD"; then
  echo "[disciplined-coder] WARNING: CLAUDE.md has BEGIN marker but no END — skipping strip to avoid data loss" >&2
  cp "$CLAUDE_MD" "$CLAUDE_MD.tmp"
else
  cp "$CLAUDE_MD" "$CLAUDE_MD.tmp"
fi

awk '{ l=$0; sub(/\r$/,"",l); if (l ~ /[^ \t]/) last=NR; line[NR]=$0 } END { for (i=1;i<=last;i++) print line[i] }' "$CLAUDE_MD.tmp" > "$CLAUDE_MD" && rm -f "$CLAUDE_MD.tmp"

{
  if [ -s "$CLAUDE_MD" ]; then printf '\n'; fi
  printf '%s\n' "$BEGIN_MARK"
  for f in coding-principles.md advisors-index.md solved_problems.md unsolved_problems.md; do
    if [ -f "$ROOT/$f" ]; then printf '@%s\n' "$f"; fi
  done
  printf '%s\n' "$END_MARK"
} >> "$CLAUDE_MD"

# 4) 첫 세션 도달 보강: 디시플린 + 인덱스를 stdout으로 출력(SessionStart additionalContext).
for f in $PLUGIN_FILES; do
  if [ -f "$ROOT/$f" ]; then cat "$ROOT/$f"; fi
done

# 5) 생성 보고
if [ -n "$created" ]; then
  echo "[disciplined-coder] scaffolded:$created"
fi
exit 0
