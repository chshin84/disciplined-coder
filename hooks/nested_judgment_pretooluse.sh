#!/usr/bin/env bash
# PreToolUse(Write): 프로젝트 안의 새 spec 을 처음 쓰려 하면 세션마다 경로당 한 번 거부하고, 사유로
# 나눠 맡길지 판단하게 한다. 같은 경로를 다시 쓰면 통과한다.
# 판단 시점을 spec 승인 뒤로만 두었을 때, 순서(plan 분할)가 판단보다 먼저 정해지고 판단은 사용자가
# 지적한 뒤에야 일어났다(2026-10-11 NP-bond-agg 세션). brainstorming 의 끝은 도구 호출로 드러나지 않으므로
# 그 직후의 사건인 새 spec Write 를 본다. 지시를 덧붙이는 additionalContext 는 도구 결과와 함께 도착해
# Write 뒤에 읽히므로, 판단을 Write 앞에 두려면 거부해야 한다.
# 표시는 세션 단위가 아니라 경로 단위다. 세션 단위이면 작은 spec 을 먼저 쓴 세션이 뒤의 큰 개발 spec 을
# 판단 없이 쓴다. 맡기기로 한 뒤 큰 명세가 다른 경로로 가서 다시 거부되는 문제는, 사유에서 큰 명세를
# 거부된 이 경로에 쓰라고 지시해 피한다.
# 표시 키는 경로를 정규화(드라이브 표기 통일·슬래시 정리·소문자화)한 뒤 cksum 으로 만든다. 문자를 바꿔
# 키를 만들면 한글 이름만 다른 spec 이 같은 키가 되고, 파일 이름 길이 한도 때문에 잘라야 한다.
# 거부 사유에 맡기는 기준(nested-orchestration 「맡기는 기준」과 같은 뜻)을 넣는다. 기준에 들지 않는 작은
# spec 에서 큰 스킬을 열지 않고 한 문장으로 판단을 알린 뒤 다시 쓰게 하기 위해서다.
# 서브에이전트(agent_id 가 오는 호출)는 보지 않는다. nested 서브 세션이 하부 명세를 쓸 때 다시 나누지 않게 한다.
# session_id 가 없거나 표시 파일을 만들지 못하면 거부하지 않는다(fail-open) — 재시도를 셀 수 없어
# 거부하면 그 spec 을 영영 못 쓴다.
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
# /d/x 와 D:/x 가 같은 키가 되도록 Git Bash 에서는 윈도우 표기로 바꾼다. 윈도우 경로는 대소문자를 가리지 않는다.
norm="$match"
if ! _path_is_win "$norm" && command -v cygpath >/dev/null 2>&1; then norm="$(cygpath -m "$norm" 2>/dev/null || printf '%s' "$norm")"; fi
slash_norm norm
norm="${norm,,}"
key="$(printf '%s' "$norm" | cksum 2>/dev/null)" || exit 0
key="${key%% *}"
marker="$mdir/nested-judged-$sid-$key"
[ -e "$marker" ] && exit 0
{ mkdir -p "$mdir" && : > "$marker"; } 2>/dev/null || exit 0
. "$DIR/_json_escape.sh"   # JSON 문자열 이스케이프 공유
reason="새 spec(${match##*/})을 쓰기 전에 서브 세션에 나눠 맡길지 판단하라. 계약을 고정한 뒤 동시에 시작할 수 있는 워크스트림이 둘 이상이고 각각 태스크 다섯 이상으로 예상될 만큼 크거나, 서로 독립된 큰 작업이 둘 이상이면 disciplined-coder nested-orchestration 스킬을 열어 맡길지 판단하라. 어느 쪽에도 들지 않으면 스킬을 열지 말고 판단과 근거를 한 문장으로 사용자에게 알린 뒤 같은 Write 를 다시 실행하라. 맡기기로 하면 그 스킬이 정한 큰 명세를 지금 거부된 이 경로에 써라. 이 경로의 파일 이름에 든 주제를 개발 이름으로 삼는다. 이 경로에 대한 거부는 이 세션에서 한 번뿐이다."
esc="$(escape_for_json "$reason")"
printf '{"hookSpecificOutput":{"hookEventName":"PreToolUse","permissionDecision":"deny","permissionDecisionReason":"%s"}}\n' "$esc"
exit 0
