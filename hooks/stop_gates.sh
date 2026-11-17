#!/usr/bin/env bash
# Stop: 이 세션이 만든 spec·plan 에 리뷰 마커가 없으면 턴 종료를 한 번 차단한다. 같은 턴 두 번째 종료는
# 루프가드(stop_hook_active)로 통과한다. git 은 rev-parse·status·diff-tree 세 번 실행한다.
# jq 비의존. git 이 없거나 저장소가 아니면 FAIL-OPEN(작업불능 방지 — 알려진 한계).
set -euo pipefail
HOOKDIR="${BASH_SOURCE[0]%/*}"; [ "$HOOKDIR" != "${BASH_SOURCE[0]}" ] || HOOKDIR=.
. "$HOOKDIR/_hook_input.sh"     # 훅 입력 읽기(json_str·slash_norm) 공유
. "$HOOKDIR/_spec_marker.sh"    # 마커 판정·경로 술어·리뷰 지시문 공유
. "$HOOKDIR/_json_escape.sh"    # JSON 문자열 이스케이프 공유
. "$HOOKDIR/_stop_preamble.sh"  # 루프가드·cwd·저장소 루트 이동 공유
IFS= read -r -d '' INPUT || true

# spec·plan 하드 게이트. 탐지: git 신규(미추적·추가) spec/plan + HEAD 커밋이 추가한 spec/plan 중 마지막
# 줄이 terminal 마커가 아닌 것(HEAD 쪽은 같은 턴에 커밋해 게이트를 비켜 가는 것을 막는다). 기존 파일
# 수정은 제외한다. 이 세션이 시작되기 전에 만든 미추적 초안은 보지 않는다(에이전트원칙 FOCUSED). 버려 둔
# 초안 하나가 그 작업 트리의 모든 세션을 턴마다 차단하던 것을 막는다. 시작 시각은 SessionStart(startup)
# 에서 spec_gate_sessionstart.sh 가 남긴 표시 파일의 수정 시각이고, 표시가 없으면 전부 본다.
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

stop_enter_repo "턴 끝 검사(spec 리뷰 게이트)를 하지 못했다"

# -z: NUL 종료 raw 경로(공백·비ASCII 안전). --no-renames: 리네임을 del+add 로 분해한다.
STATUS=()
while IFS= read -r -d '' e; do STATUS+=("$e"); done \
  < <(git status -z --porcelain --untracked-files=all --no-renames 2>/dev/null || true)

spec_gate_check
[ -n "$SPEC_BLOCK_REASON" ] && printf '{"decision":"block","reason":"%s"}\n' "$(escape_for_json "$SPEC_BLOCK_REASON")"
exit 0
