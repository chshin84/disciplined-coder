#!/usr/bin/env bash
# PreToolUse(Write|Edit|Bash|PowerShell): 쓰기 대상 파일이 있고 쓰기 불가이면 거부하고 사유를 낸다.
# 대상은 Write·Edit 이면 입력의 file_path 이고, Bash·PowerShell 이면 명령의 쓰기 구문이 가리키는 파일이다
# (재지향·sed -i·tee·cp·mv 와 PowerShell 의 Set-Content 류·Copy-Item 류, 뽑는 규칙은 _extract_*_targets.sh).
# 상대 경로는 훅 입력의 cwd 기준으로 푼다. 경로·저장소·HEAD는 보지 않는다 — 읽기 전용이라는 속성은
# 그 파일을 만든 쪽의 의도라 어느 프로젝트에서든 같은 뜻이다. 끄는 스위치를 두지 않는다. 풀려면 속성을
# 풀면 되고 그 길은 셸이다(chmod 는 쓰기 구문이 아니라 이 훅이 거부하지 않는다). Write 는 훅 없이도
# EPERM 으로 중단되므로 이 훅의 몫은 왜 중단됐는지 말하는 것이다.
set -euo pipefail
DIR="${BASH_SOURCE[0]%/*}"; [ "$DIR" != "${BASH_SOURCE[0]}" ] || DIR=.
. "$DIR/_hook_input.sh"    # 훅 입력 읽기·쓰기 구문 판정·경로 풀기 공유
INPUT="$(cat)"
json_str tool_name TOOL
hook_cwd
case "$TOOL" in
  Bash)
    # 모든 셸 호출에 실행되므로 쓰기 구문이 없으면 프로세스를 띄우지 않고 끝낸다.
    hook_command
    bash_cmd_writes "$CMD" || exit 0
    . "$DIR/_extract_bash_targets.sh"
    TARGETS="$(bash_write_targets "$CMD" "$HOOK_CWD" 2>/dev/null || true)" ;;
  PowerShell)
    hook_command
    . "$DIR/_extract_ps_targets.sh"
    ps_cmd_writes "$CMD" || exit 0
    TARGETS="$(ps_write_targets "$CMD" "$HOOK_CWD" 2>/dev/null || true)" ;;
  *)
    hook_file_paths
    TARGETS="$(printf '%s' "$FILE_PATHS" | targets_resolve "$HOOK_CWD")" ;;
esac
match=""
while IFS= read -r FILE; do
  [ -n "$FILE" ] || continue
  [ -e "$FILE" ] || continue            # 없는 파일은 새로 만드는 것이라 거부할 속성이 없다
  [ -w "$FILE" ] && continue            # 쓸 수 있으면 훅의 작업이 아니다
  match="$FILE"; break
done <<EOF
$TARGETS
EOF
[ -n "$match" ] || exit 0
. "$DIR/_json_escape.sh"   # JSON 문자열 이스케이프 공유
reason="읽기 전용 파일은 고치지 않는다. 속성을 설정한 사람이나 도구에 의도가 있다 — 감사 기록이면 고치지 말고 새 기록을 추가한다. 파일: $match"
esc="$(escape_for_json "$reason")"
printf '{"hookSpecificOutput":{"hookEventName":"PreToolUse","permissionDecision":"deny","permissionDecisionReason":"%s"}}\n' "$esc"
exit 0
