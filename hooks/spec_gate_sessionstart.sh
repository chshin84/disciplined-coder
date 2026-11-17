#!/usr/bin/env bash
# SessionStart(startup): spec 게이트(stop_gates.sh)가 쓰는 세션 시작 표시를 남긴다. 출력은 없다.
# Stop 훅은 이 표시의 수정 시각보다 먼저 만든 미추적 spec·plan 초안을 이 세션의 작업이 아닌 것으로 보고
# 차단하지 않는다. startup 에서만, 표시가 없을 때만 만든다. 다시 쓰면 세션 중에 만든 초안이 표시보다
# 오래된 것으로 보여 게이트를 비켜 간다.
set -euo pipefail
IFS= read -r -d '' INPUT || true
DIR="${BASH_SOURCE[0]%/*}"; [ "$DIR" != "${BASH_SOURCE[0]}" ] || DIR=.
. "$DIR/_hook_input.sh"
json_str session_id sid
json_str source src
ssid="${sid//[^A-Za-z0-9_-]/}"
mdir="${TMPDIR:-/tmp}/disciplined-coder"
if [ "$src" = "startup" ] && [ -n "$ssid" ] && [ ! -e "$mdir/session-start-$ssid" ]; then
  mkdir -p "$mdir" 2>/dev/null && : > "$mdir/session-start-$ssid" 2>/dev/null || true
fi
exit 0
