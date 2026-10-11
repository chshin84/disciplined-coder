#!/usr/bin/env bash
# PreToolUse(Write): 프로젝트 안의 새 spec 을 처음 쓰려 하면 세션마다 경로당 한 번 거부하고, 사유로
# nested-orchestration 판단을 지시한다. 같은 경로를 다시 쓰면 통과한다.
# 판단 시점을 spec 승인 뒤로만 두었을 때, 순서(plan 분할)가 판단보다 먼저 정해지고 판단은 사용자가
# 지적한 뒤에야 일어났다(2026-10-11 NP-bond-agg 세션). brainstorming 의 끝은 도구 호출로 드러나지 않으므로
# 그 직후의 사건인 새 spec Write 를 본다. 지시를 덧붙이는 additionalContext 는 도구 결과와 함께 도착해
# Write 뒤에 읽히므로, 판단을 Write 앞에 두려면 거부해야 한다.
# 서브에이전트(agent_id 가 오는 호출)는 보지 않는다. nested 서브 세션이 하부 명세를 쓸 때 다시 나누지 않게 한다.
# session_id 가 없으면 재시도를 셀 수 없어 거부하지 않는다 — 거부하면 그 spec 을 영영 못 쓴다.
# 셸로 쓴 spec 은 보지 않는다(알려진 한계).
set -euo pipefail
[ "${DISCIPLINED_CODER_REVIEW_GATE:-on}" = "off" ] && exit 0
DIR="${BASH_SOURCE[0]%/*}"; [ "$DIR" != "${BASH_SOURCE[0]}" ] || DIR=.
. "$DIR/_hook_input.sh"    # 훅 입력 읽기(json_str·hook_file_paths·slash_norm) 공유
. "$DIR/_spec_marker.sh"   # 경로 술어(path_in_project) 공유
INPUT="$(cat)"
json_str agent_id aid
[ -z "$aid" ] || exit 0
json_str session_id sid
sid="${sid//[^A-Za-z0-9_-]/}"
[ -n "$sid" ] || exit 0
hook_file_paths
match=""
while IFS= read -r FILE; do
  [ -n "$FILE" ] || continue
  case "$FILE" in *docs/superpowers/specs/*.md) ;; *) continue ;; esac
  [ -e "$FILE" ] && continue          # 있는 spec 을 고치는 것은 판단 시점이 아니다
  path_in_project "$FILE" || continue
  match="$FILE"; break
done <<EOF
$FILE_PATHS
EOF
[ -n "$match" ] || exit 0
mdir="${TMPDIR:-/tmp}/disciplined-coder"
key="${match//[^A-Za-z0-9]/_}"
# 파일 이름 길이 한도 때문에 뒤쪽만 남긴다. ${key: -120} 은 120자보다 짧으면 빈 문자열이 되므로 길 때만 자른다.
[ "${#key}" -le 120 ] || key="${key: -120}"
marker="$mdir/nested-judged-$sid-$key"
[ -e "$marker" ] && exit 0
mkdir -p "$mdir" && : > "$marker"
. "$DIR/_json_escape.sh"   # JSON 문자열 이스케이프 공유
reason="새 spec(${match##*/})을 쓰기 전에 disciplined-coder nested-orchestration 스킬을 열어 서브 세션에 나눠 맡길지 그 스킬의 기준으로 판단하고, 판단과 근거를 사용자에게 알려라. 맡기기로 하면 그 스킬이 정한 큰 명세로 쓰고, 맡기지 않으면 같은 Write 를 다시 실행하라. 이 거부는 이 세션에서 이 경로에 한 번뿐이다."
esc="$(escape_for_json "$reason")"
printf '{"hookSpecificOutput":{"hookEventName":"PreToolUse","permissionDecision":"deny","permissionDecisionReason":"%s"}}\n' "$esc"
exit 0
