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
