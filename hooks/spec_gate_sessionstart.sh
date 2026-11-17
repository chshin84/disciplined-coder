#!/usr/bin/env bash
# SessionStart(startup|resume|clear): spec 게이트(stop_gates.sh)가 쓰는 세션 시작 표시를 남긴다. 출력은 없다.
# 표시 파일에는 그 시점에 이미 있던 신규(미추적·추가) spec·plan 경로를 저장소 뿌리 기준으로 한 줄에 하나 적는다.
# Stop 훅은 이 목록에 있는 초안을 이 세션의 작업이 아닌 것으로 보고 차단하지 않는다. 버려 둔 초안 하나가
# 그 작업 트리의 모든 세션을 턴마다 차단하지 않게 하기 위해서다. 수정 시각으로 가르지 않는다 — 다른 곳에서
# 복사해 온 새 초안은 수정 시각이 오래되어 게이트를 비켜 갔다.
# 이 session_id 의 표시가 없을 때만 만든다. resume·clear 뒤에도 표시가 없으면 만들고, 있으면 다시 쓰지 않는다
# (다시 쓰면 세션 중에 만든 초안이 목록에 들어가 게이트를 비켜 간다).
# 7일 지난 표시는 여기서 지운다. 세션마다 하나씩 쌓이기 때문이다.
set -euo pipefail
IFS= read -r -d '' INPUT || true
DIR="${BASH_SOURCE[0]%/*}"; [ "$DIR" != "${BASH_SOURCE[0]}" ] || DIR=.
. "$DIR/_hook_input.sh"
. "$DIR/_spec_marker.sh"   # SPECPLAN_DIRS·path_is_specplan 공유
json_str session_id sid
hook_cwd
ssid="${sid//[^A-Za-z0-9_-]/}"
mdir="${TMPDIR:-/tmp}/disciplined-coder"
mkdir -p "$mdir" 2>/dev/null || exit 0
find "$mdir" -maxdepth 1 -name 'session-start-*' -mtime +7 -exec rm -f {} + 2>/dev/null || true
[ -n "$ssid" ] || exit 0
marker="$mdir/session-start-$ssid"
[ -e "$marker" ] && exit 0
list=""
root="$(git -C "${HOOK_CWD:-.}" rev-parse --show-toplevel 2>/dev/null || true)"
root="${root##*$'\n'}"
if [ -n "$root" ]; then
  # 경로는 NUL 로 끝나는 원문 그대로 받는다(공백·한글 안전). 차단 대상과 같은 신규만 적는다.
  while IFS= read -r -d '' e; do
    case "${e:0:2}" in '??'|A*) ;; *) continue ;; esac
    f="${e:3}"
    path_is_specplan "$f" && list+="$f"$'\n'
  done < <(git -C "$root" status -z --porcelain --untracked-files=all --no-renames -- $SPECPLAN_DIRS 2>/dev/null || true)
fi
printf '%s' "$list" > "$marker" 2>/dev/null || true
exit 0
