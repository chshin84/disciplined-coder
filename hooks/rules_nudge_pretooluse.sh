#!/usr/bin/env bash
# PreToolUse(Write|Edit|Bash): 이 세션의 첫 Write·Edit·Bash 호출에 규칙이 어디 있는지 한 번 알린다
# (비블로킹, 게이트 아님). 편집 뒤가 아니라 편집 전에 알려야 규칙을 읽고 고칠 수 있다 — 새 문서 넛지가
# PreToolUse 인 것과 같은 이유다.
#
# 코드인지 문서인지 가르지 않는다. 셸 명령의 대상은 실행해 봐야 정해지므로(`sed -i "$f"` 의 $f)
# 편집 전에 확실히 가르는 방법이 없고, 추측으로 가르면 틀린 쪽을 가리키거나 조용히 안 걸린다.
# 에이전트원칙이 코드 규칙과 문서 규칙을 모두 가지므로 가를 필요도 없다.
#
# 알리는 것은 관리 디렉터리 사본의 절대경로다. 상대 이름은 이 저장소 밖에서 안 열린다.
# 홈 해석의 소유자는 scripts/_resolve_home.sh 이므로 경로를 여기 박지 않고 그것으로 도출한다.
# 사본이 없으면 경로 대신 그 사실을 알린다 — 없는 파일을 열라고 시키지 않는다.
#
# 세션 키는 훅 입력의 공통 필드 session_id 에 agent_id(서브에이전트 안의 훅 호출에만 온다)를 이은 것이다.
# 그래서 서브에이전트는 부모의 표시 파일과 무관하게 자기 넛지를 한 번 받는다.
# 필드의 원본: https://code.claude.com/docs/en/hooks
set -euo pipefail
[ "${DISCIPLINED_CODER_REVIEW_GATE:-on}" = "off" ] && exit 0
INPUT="$(cat)"

# 표시 파일 확인을 맨 앞에 둔다. 이 훅은 Write·Edit·Bash 마다 도는데 알리는 것은 세션에 한 번뿐이라,
# 두 번째 호출부터는 경로 도출과 메시지 작성에 드는 프로세스를 띄우기 전에 여기서 끝나야 한다.
#
# 키를 뽑는 데 외부 명령을 쓰지 않는다. json_str 은 셸 파라미터 확장만 쓴다(_hook_input.sh).
DIR="${BASH_SOURCE[0]%/*}"; [ "$DIR" != "${BASH_SOURCE[0]}" ] || DIR=.
. "$DIR/_hook_input.sh"   # 훅 입력 읽기(json_str) 공유 — 세션 시작 훅과 같은 방식으로 키를 뽑는다
json_str session_id sid
json_str agent_id aid
if [ -n "$sid" ]; then
  key="$sid${aid:+-$aid}"
  mdir="${TMPDIR:-/tmp}/disciplined-coder"
  marker="$mdir/rules-nudge-$key"
  [ -e "$marker" ] && exit 0
  mkdir -p "$mdir" && : > "$marker"
fi
# session_id 가 없으면 계약이 깨진 것이다. 표시 파일 없이 매번 알린다 — 조용히 빠지지 않는다.

# 여기부터는 세션에 한 번만 지난다. 경로 도출과 나머지 헬퍼 소싱을 이 아래에 둔다.
. "$DIR/_json_escape.sh"   # JSON 문자열 이스케이프 공유
# 홈 해석은 scripts/_resolve_home.sh 가 소유한다. 그 파일이 없어도 넛지는 나가야 하므로
# source 실패를 삼키고 함수가 섰는지로 가른다 — 조용히 빠지지 않는다.
. "$DIR/../scripts/_resolve_home.sh" 2>/dev/null || true
CANON_PATH=""
if declare -f resolve_home >/dev/null 2>&1; then
  CANON_PATH="$(resolve_home claude 2>/dev/null)/disciplined-coder/agent-principles.md"
fi
if [ -n "$CANON_PATH" ] && [ -f "$CANON_PATH" ]; then
  where="에이전트원칙의 사본은 $CANON_PATH 에 있다."
else
  where="에이전트원칙의 사본을 못 찾았다 — disciplined-coder setup-discipline 을 돌려라."
fi
# 한국어 상세는 lens-readability 폴더에 놓인 참고서다. 스킬이 아니어서 이름으로 못 열고, 관리
# 디렉터리에 사본을 두지도 않는다. 그래서 에이전트원칙 사본과 경로가 달라 여기서 따로 도출한다.
# 없으면 그 사실을 알린다 — 없는 파일을 열라고 시키지 않는다.
WK_PATH="$(cd "$DIR/.." 2>/dev/null && pwd)/skills/lens-readability/domain-korean.md"
if [ -f "$WK_PATH" ]; then
  wkwhere="한국어 문장 규칙의 상세는 $WK_PATH 에 있다."
else
  wkwhere="한국어 문장 규칙의 상세를 담은 domain-korean.md 를 못 찾았다."
fi

# 스킬의 절 이름을 여기 박지 않는다 — 훅은 스킬을 가리키기만 하고 내용을 베끼지 않는다(문서 넛지와 같은 규칙).
msg="🧑‍💻 이 세션의 첫 도구 호출이다 — $where $wkwhere 서브에이전트에는 에이전트원칙이 안 실리므로 그 경로를 프롬프트에 직접 넣어라. 레포 안에서 도는 워크플로는 이 사본 대신 그 레포의 에이전트원칙을 넣는다 — 상세는 disciplined-coder dispatching-lenses 가 갖는다. 넛지일 뿐 차단은 아니다."
esc="$(escape_for_json "$msg")"
printf '{"hookSpecificOutput":{"hookEventName":"PreToolUse","additionalContext":"%s"}}\n' "$esc"
exit 0
