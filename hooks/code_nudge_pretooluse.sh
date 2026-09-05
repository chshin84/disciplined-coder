#!/usr/bin/env bash
# PreToolUse(Write|Edit): 문서가 아닌 프로젝트 안 파일에 세션의 첫 편집이 들어오면 domain-coding을 열라고
# 알린다(비블로킹, 게이트 아님). 편집 뒤가 아니라 편집 전에 알려야 규칙을 읽고 고칠 수 있다 — 새 문서 넛지가
# PreToolUse 인 것과 같은 이유다.
# 세션 키는 훅 입력의 공통 필드 session_id 에 agent_id(서브에이전트 안의 훅 호출에만 온다)를 이은 것이다.
# 그래서 서브에이전트는 부모의 표시 파일과 무관하게 자기 넛지를 한 번 받는다.
# 필드의 정본: https://code.claude.com/docs/en/hooks
# 경로는 _extract_path.sh 가 추출(다중 순회). 순수 bash.
set -euo pipefail
[ "${DISCIPLINED_CODER_REVIEW_GATE:-on}" = "off" ] && exit 0
DIR="$(cd "$(dirname "$0")" && pwd)"
. "$DIR/_spec_marker.sh"   # 경로 술어(path_in_project) 공유(SSOT)
. "$DIR/_json_escape.sh"   # JSON 문자열 이스케이프 공유(SSOT)
INPUT="$(cat)"
match=""
while IFS= read -r FILE; do
  [ -n "$FILE" ] || continue
  case "$FILE" in *.md) continue ;; esac                          # 문서는 문서 넛지가 맡는다
  case "$FILE" in *docs/superpowers/reviews/*) continue ;; esac    # 렌즈 원본 JSON 은 코드가 아니다
  path_in_project "$FILE" || continue                             # 프로젝트 밖(메모리·계획 파일)에는 걸지 않는다
  match="$FILE"; break
done <<EOF
$(printf '%s' "$INPUT" | bash "$DIR/_extract_path.sh")
EOF
[ -n "$match" ] || exit 0

# stdin JSON 의 최상위 문자열 필드 하나를 뽑는다. 없으면 빈 문자열.
json_str() {
  printf '%s' "$INPUT" | grep -o "\"$1\"[[:space:]]*:[[:space:]]*\"[^\"]*\"" | head -1 | sed 's/.*:[[:space:]]*"\([^"]*\)"$/\1/' || true
}
sid="$(json_str session_id)"
aid="$(json_str agent_id)"
if [ -n "$sid" ]; then
  key="$sid${aid:+-$aid}"
  mdir="${TMPDIR:-/tmp}/disciplined-coder"
  marker="$mdir/code-nudge-$key"
  [ -e "$marker" ] && exit 0
  mkdir -p "$mdir" && : > "$marker"
fi
# session_id 가 없으면 계약이 깨진 것이다. 표시 파일 없이 매번 알린다 — 조용히 빠지지 않는다(FAIL-LOUD).

base="$(basename "$match")"
# 스킬의 절 이름을 여기 박지 않는다 — 훅은 스킬을 가리키기만 하고 내용을 베끼지 않는다(문서 넛지와 같은 규칙).
msg="🧑‍💻 문서가 아닌 파일(${base})을 고치려 한다 — 고치기 전에 disciplined-coder domain-coding을 열어 코드 규칙을 읽어라. 넛지일 뿐 차단은 아니다."
esc="$(escape_for_json "$msg")"
printf '{"hookSpecificOutput":{"hookEventName":"PreToolUse","additionalContext":"%s"}}\n' "$esc"
exit 0
