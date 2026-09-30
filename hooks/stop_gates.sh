#!/usr/bin/env bash
# Stop: 턴 끝의 검사 둘을 한 프로세스로 실행한다. 미리뷰 spec·plan 을 차단하는 하드 게이트와, 커밋되지
# 않은 산출물 문서의 금지 표현을 사용자에게 알리는 검사다. 따로 실행하면 답마다 bash 둘과 git 일곱 번이
# 들었다. 여기서는 bash 하나와 git 세 번(rev-parse·status·diff-tree)으로 끝낸다. 루프가드: stop_hook_active.
# jq 비의존. git 이 없거나 저장소가 아니면 FAIL-OPEN(작업불능 방지 — 알려진 한계).
set -euo pipefail
HOOKDIR="${BASH_SOURCE[0]%/*}"; [ "$HOOKDIR" != "${BASH_SOURCE[0]}" ] || HOOKDIR=.
. "$HOOKDIR/_hook_input.sh"     # 훅 입력 읽기(json_str·slash_norm) 공유
. "$HOOKDIR/_spec_marker.sh"    # 마커 판정과 경로 술어 공유
. "$HOOKDIR/_json_escape.sh"    # JSON 문자열 이스케이프 공유
. "$HOOKDIR/_stop_preamble.sh"  # 루프가드·cwd·저장소 루트 이동 공유
IFS= read -r -d '' INPUT || true

# spec·plan 하드 게이트. 탐지: git 신규(미추적·추가) spec/plan + HEAD 커밋이 추가한 spec/plan 중 마지막
# 줄이 terminal 마커가 아닌 것(HEAD 쪽은 같은 턴에 커밋해 게이트를 비켜 가는 것을 막는다). 기존 파일
# 수정은 제외한다. 이 세션이 시작되기 전에 만든 미추적 초안은 보지 않는다(에이전트원칙 FOCUSED). 버려 둔
# 초안 하나가 그 작업 트리의 모든 세션을 턴마다 차단하던 것을 막는다. 시작 시각은 SessionStart(startup)
# 에서 rules_nudge_sessionstart.sh 가 남긴 표시 파일의 수정 시각이고, 표시가 없으면 전부 본다.
# HEAD 커밋 쪽에는 이 거르기를 두지 않는다 — 커밋은 이 턴의 일이다.
spec_gate_check() {  # → SPEC_BLOCK_REASON
  local entry f u dup sid since="" list=""
  local -a unreviewed=()
  SPEC_BLOCK_REASON=""
  json_str session_id sid; sid="${sid//[^A-Za-z0-9_-]/}"
  if [ -n "$sid" ] && [ -f "${TMPDIR:-/tmp}/disciplined-coder/session-start-$sid" ]; then
    since="${TMPDIR:-/tmp}/disciplined-coder/session-start-$sid"
  fi
  for entry in ${STATUS+"${STATUS[@]}"}; do
    f="${entry:3}"; [ -n "$f" ] || continue
    # 신규(미추적 ??·추가 A)만 하드게이트 — 기존 spec 수정(상태 strip 등)엔 안 건다(넛지는 PostToolUse가).
    case "${entry:0:2}" in '??'|A*) ;; *) continue ;; esac
    path_is_specplan "$f" || continue
    [ -f "$f" ] || continue
    if [ -n "$since" ] && [ ! "$f" -nt "$since" ]; then continue; fi
    marker_is_terminal "$f" || unreviewed+=("$f")
  done
  # 경계는 직전 커밋 하나다. 과거 이력을 소급 차단하지 않는다(훅 도입 전 무마커 레거시가 있는 레포에서
  # 상시 차단 → 게이트 영구 off 라는 더 나쁜 드리프트를 피한다). 루트 커밋·머지 커밋·다중 커밋 우회는
  # 알려진 한계다.
  while IFS= read -r -d '' f; do
    [ -n "$f" ] || continue
    path_is_specplan "$f" || continue
    [ -f "$f" ] || continue
    dup=0; for u in ${unreviewed+"${unreviewed[@]}"}; do [ "$u" = "$f" ] && { dup=1; break; }; done
    [ "$dup" = 1 ] && continue
    marker_is_terminal "$f" || unreviewed+=("$f")
  done < <(git diff-tree -z --no-commit-id --name-only --diff-filter=A -r HEAD 2>/dev/null || true)
  [ "${#unreviewed[@]}" -gt 0 ] || return 0
  for u in "${unreviewed[@]}"; do list="$list
  - $u"; done
  SPEC_BLOCK_REASON="미리뷰 spec/plan:$list
${SPEC_REVIEW_INSTRUCTION} 반영을 마친 뒤 종료하라."
}

# 금지 표현 알림. 앞의 두 겹(Write·Edit 를 막는 Pre 훅, 셸 대상을 보는 Post 훅)은 도구를 보므로 명령줄에
# 대상이 안 나타나면 못 본다. 여기는 git 이 바뀌었다고 말하는 파일을 무엇이 바꿨는지와 무관하게 본다.
# 막지 않는다. 턴이 끝나는 것을 막으면 고치지 못하는 상황에서 빠져나갈 길이 없다. 막지 않으면 Claude 에게
# 닿는 통로가 없으므로 알림은 사용자에게 하는 말로 쓴다. 같은 세션에 같은 알림은 한 번만 낸다 — 커밋되지
# 않은 옛 파일 하나 때문에 같은 알림이 30시간 동안 137번 뜬 세션이 있었다(2026-09-27).
# 이 검사가 실패해도 spec 차단은 나가야 하므로 실패하는 곳마다 return 0 으로 물러난다.
# 파이썬이 없으면 banned_report 가 빈 결과를 내어 알림 없이 끝난다(2026-09-30 사용자 결정).
doc_word_gate_check() {  # → DOC_WORD_MSG
  local entry f files="" one report="" sid sum seen_dir work
  DOC_WORD_MSG=""
  for entry in ${STATUS+"${STATUS[@]}"}; do
    f="${entry:3}"; [ -n "$f" ] || continue
    path_is_banned_target "$f" || continue   # 제외 규칙은 _spec_marker.sh 가 소유한다.
    [ -f "$f" ] || continue
    files="${files}${f}
"
  done
  [ -n "$files" ] || return 0
  . "$HOOKDIR/_banned_words.sh" || return 0            # 표 파싱과 본문 맞추기 공유
  . "$HOOKDIR/../scripts/_json_valid.sh" || return 0   # 파이썬 인터프리터 고르기
  work="$(mktemp -d 2>/dev/null)" || return 0
  if ! banned_parse "$HOOKDIR/../korean-banned-words.md" "$work/pairs" "$work/toks" "$work/excl" 2>/dev/null \
     || [ ! -s "$work/toks" ]; then
    rm -rf "$work"; return 0
  fi
  while IFS= read -r f; do
    [ -n "$f" ] || continue
    LC_ALL=C grep -qFf "$work/toks" "$f" || continue   # 빠른 거르기 — 파이썬을 아낀다
    one="$(banned_report "$work/pairs" "$f" "$work/excl" || true)"
    [ -n "$one" ] || continue
    report="${report}${f}
${one}
"
  done <<EOF
$files
EOF
  rm -rf "$work"
  [ -n "$report" ] || return 0
  json_str session_id sid
  sid="${sid//[^A-Za-z0-9_-]/}"
  if [ -n "$sid" ]; then
    seen_dir="${TMPDIR:-/tmp}/disciplined-coder-doc-word"
    mkdir -p "$seen_dir" 2>/dev/null || true
    sum="$(printf '%s' "$report" | cksum)"; sum="${sum%% *}"
    if [ -f "$seen_dir/$sid" ] && [ "$(cat "$seen_dir/$sid" 2>/dev/null)" = "$sum" ]; then return 0; fi
    printf '%s' "$sum" > "$seen_dir/$sid" 2>/dev/null || true
  fi
  DOC_WORD_MSG="disciplined-coder: 커밋되지 않은 산출물 문서에 「금지 표현」 목록의 말이 남아 있다. 아래는 파일마다 검출한 말과 그 대체어다. 어느 도구가 고쳤는지와 무관하게 git 이 바뀌었다고 알린 파일을 본 결과이고, 코드 블록과 백틱 안은 검사하지 않았다. 이 알림은 사용자에게만 보이므로 고치려면 Claude 에게 요청한다.

$report"
}

SPEC_ON=1; [ "${DISCIPLINED_CODER_REVIEW_GATE:-on}" = "off" ] && SPEC_ON=0
WORD_ON=1; [ "${DISCIPLINED_CODER_REPLY_CHECK:-on}" = "off" ] && WORD_ON=0
# 목록이 없다는 사실은 Pre 훅이 Write·Edit 로 .md 를 쓸 때만 알린다(알려진 한계).
[ -f "$HOOKDIR/../korean-banned-words.md" ] || WORD_ON=0
[ "$SPEC_ON$WORD_ON" = "00" ] && exit 0

stop_enter_repo "턴 끝 검사(spec 리뷰 게이트·금지 표현)를 하지 못했다"

# -z: NUL 종료 raw 경로(공백·비ASCII 안전). --no-renames: 리네임을 del+add 로 분해한다. 두 검사가 같은
# 목록을 쓰므로 한 번만 부른다.
STATUS=()
while IFS= read -r -d '' e; do STATUS+=("$e"); done \
  < <(git status -z --porcelain --untracked-files=all --no-renames 2>/dev/null || true)

reason=""; msg=""
if [ "$SPEC_ON" = 1 ]; then spec_gate_check; reason="$SPEC_BLOCK_REASON"; fi
if [ "$WORD_ON" = 1 ]; then doc_word_gate_check || true; msg="$DOC_WORD_MSG"; fi

if [ -n "$reason" ] && [ -n "$msg" ]; then
  printf '{"decision":"block","reason":"%s","systemMessage":"%s"}\n' "$(escape_for_json "$reason")" "$(escape_for_json "$msg")"
elif [ -n "$reason" ]; then
  printf '{"decision":"block","reason":"%s"}\n' "$(escape_for_json "$reason")"
elif [ -n "$msg" ]; then
  printf '{"systemMessage":"%s"}\n' "$(escape_for_json "$msg")"
fi
exit 0
