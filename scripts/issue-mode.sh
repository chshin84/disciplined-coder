#!/usr/bin/env bash
# /issue-mode — 오답노트 미해결 처분 모드 토글(PC 전역, 자기 홈 config). 인자 없으면 현재 모드 표시.
# surface(기본·메모리+surface) ↔ issues(must-keep을 GitHub Issues 등 외부 트래커에 위임).
set -euo pipefail

# 홈 해석 — scaffold.sh와 같은 공유 헬퍼(SSOT). 손복제 제거로 드리프트 방지.
. "$(dirname "$0")/_resolve_home.sh"
CLAUDE_HOME="$(resolve_home claude)"
KDIR="$CLAUDE_HOME/disciplined-coder"
MODE_FILE="$KDIR/issue-mode"

arg="${1:-}"

if [ -z "$arg" ]; then
  cur="surface"
  if [ -f "$MODE_FILE" ]; then cur="$(tr -d ' \t\r\n' < "$MODE_FILE" 2>/dev/null || printf surface)"; fi
  case "$cur" in surface|issues) ;; *) cur="surface (불명 config 폴백)" ;; esac
  echo "현재 오답노트 처분 모드: $cur"
  echo "변경: /issue-mode surface  |  /issue-mode issues"
  exit 0
fi

case "$arg" in
  surface|issues)
    mkdir -p "$KDIR"            # scaffold 선행을 가정하지 않음(자기완결)
    printf '%s\n' "$arg" > "$MODE_FILE"
    echo "[disciplined-coder] 오답노트 처분 모드 = $arg (다음 세션부터 적용)"
    ;;
  *)
    echo "[disciplined-coder] 잘못된 인자 '$arg' — surface|issues 만 허용" >&2
    echo "사용법: /issue-mode [surface|issues]" >&2
    exit 2
    ;;
esac
exit 0
