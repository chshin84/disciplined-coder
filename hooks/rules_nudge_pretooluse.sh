#!/usr/bin/env bash
# PreToolUse(Write|Edit|Bash): 이 세션이 파일을 처음 건드리려 하면 규칙 스킬 둘을 열라고 한 번 알린다
# (비블로킹, 게이트 아님). 편집 뒤가 아니라 편집 전에 알려야 규칙을 읽고 고칠 수 있다 — 새 문서 넛지가
# PreToolUse 인 것과 같은 이유다.
#
# 코드인지 문서인지 가르지 않는다. 셸 명령의 대상은 실행해 봐야 정해지므로(`sed -i "$f"` 의 $f)
# 편집 전에 확실히 가르는 방법이 없고, 추측으로 가르면 틀린 쪽을 가리키거나 조용히 안 걸린다.
# 두 스킬을 합쳐도 짧으니 둘 다 알리고 어느 쪽인지는 세션이 판단한다.
#
# 세션 키는 훅 입력의 공통 필드 session_id 에 agent_id(서브에이전트 안의 훅 호출에만 온다)를 이은 것이다.
# 그래서 서브에이전트는 부모의 표시 파일과 무관하게 자기 넛지를 한 번 받는다.
# 필드의 정본: https://code.claude.com/docs/en/hooks
set -euo pipefail
[ "${DISCIPLINED_CODER_REVIEW_GATE:-on}" = "off" ] && exit 0
DIR="$(cd "$(dirname "$0")" && pwd)"
. "$DIR/_json_escape.sh"   # JSON 문자열 이스케이프 공유(SSOT)
INPUT="$(cat)"

# stdin JSON 의 최상위 문자열 필드 하나를 뽑는다. 없으면 빈 문자열.
json_str() {
  printf '%s' "$INPUT" | grep -o "\"$1\"[[:space:]]*:[[:space:]]*\"[^\"]*\"" | head -1 | sed 's/.*:[[:space:]]*"\([^"]*\)"$/\1/' || true
}
sid="$(json_str session_id)"
aid="$(json_str agent_id)"
if [ -n "$sid" ]; then
  key="$sid${aid:+-$aid}"
  mdir="${TMPDIR:-/tmp}/disciplined-coder"
  marker="$mdir/rules-nudge-$key"
  [ -e "$marker" ] && exit 0
  mkdir -p "$mdir" && : > "$marker"
fi
# session_id 가 없으면 계약이 깨진 것이다. 표시 파일 없이 매번 알린다 — 조용히 빠지지 않는다(FAIL-LOUD).

# 스킬의 절 이름을 여기 박지 않는다 — 훅은 스킬을 가리키기만 하고 내용을 베끼지 않는다(문서 넛지와 같은 규칙).
msg="🧑‍💻 이 세션에서 파일을 처음 건드린다 — 규칙은 정본 agent-principles.md 가 상시로 싣고, 한국어 문장 규칙의 상세는 disciplined-coder domain-korean 이 갖는다. 서브에이전트에는 정본이 안 실리므로 그 경로를 프롬프트에 직접 넣어라. 넛지일 뿐 차단은 아니다."
esc="$(escape_for_json "$msg")"
printf '{"hookSpecificOutput":{"hookEventName":"PreToolUse","additionalContext":"%s"}}\n' "$esc"
exit 0
