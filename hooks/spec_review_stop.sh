#!/usr/bin/env bash
# Stop: 미리뷰 spec/plan이 남으면 종료 차단(하드 게이트). 루프가드: stop_hook_active.
# 탐지: git 신규(미추적·추가) spec/plan + HEAD 커밋이 추가한 spec/plan 중 마지막 줄이 terminal
# 마커가 아닌 것(HEAD 쪽은 같은 턴에 커밋해 게이트를 비켜 가는 것을 막는다). 기존 파일 수정은 제외.
# jq 비의존. git/디렉터리 없으면 FAIL-OPEN(작업불능 방지 — 알려진 한계).
set -euo pipefail
[ "${DISCIPLINED_CODER_REVIEW_GATE:-on}" = "off" ] && exit 0
HOOKDIR="${BASH_SOURCE[0]%/*}"; [ "$HOOKDIR" != "${BASH_SOURCE[0]}" ] || HOOKDIR=.
. "$HOOKDIR/_hook_input.sh"     # 훅 입력 읽기(json_str·slash_norm) 공유
. "$HOOKDIR/_spec_marker.sh"    # terminal 마커 판정 공유
. "$HOOKDIR/_json_escape.sh"    # JSON 문자열 이스케이프 공유
. "$HOOKDIR/_stop_preamble.sh"  # 루프가드·cwd·저장소 루트 이동 공유
INPUT="$(cat)"
stop_enter_repo "spec 리뷰 게이트를 검사하지 못했다"

# 경로는 배열에 모은다 — 공백으로 이어 붙이면 NUL 종료로 얻은 안전성이 그 자리에서 무너진다.
unreviewed=()
# -z: NUL 종료 + 따옴표/이스케이프 없는 raw 경로(공백·비ASCII 안전). --no-renames: 리네임을
# del+add 로 분해해 'old -> new' 합침 레코드를 없앤다. 각 레코드는 'XY ' 3글자 프리픽스 + 경로.
while IFS= read -r -d '' entry; do
  f="${entry:3}"
  [ -n "$f" ] || continue
  # 신규(미추적 ??·추가 A)만 하드게이트 — 기존 spec 수정(상태 strip 등)엔 안 건다(넛지는 PostToolUse가).
  case "${entry:0:2}" in '??'|A*) ;; *) continue ;; esac
  path_is_specplan "$f" || continue
  [ -f "$f" ] || continue
  marker_is_terminal "$f" || unreviewed+=("$f")
done < <(git status -z --porcelain --untracked-files=all --no-renames -- $SPECPLAN_DIRS 2>/dev/null)

# 같은 턴 커밋 우회 차단 — HEAD 커밋이 추가(A)한 spec/plan도 검사한다.
# 경계는 직전 커밋 하나: 과거 이력을 소급 차단하지 않는다(훅 도입 전 무마커 레거시가 있는
# 레포에서 상시 차단 → 게이트 영구 off라는 더 나쁜 드리프트를 피한다). 루트 커밋(--root 미사용)
# ·머지 커밋(-m 미사용)·다중 커밋 우회는 알려진 한계(레거시 임포트 오차단 회피와 같은 근거).
while IFS= read -r -d '' f; do
  [ -n "$f" ] || continue
  path_is_specplan "$f" || continue
  [ -f "$f" ] || continue
  dup=0; for u in ${unreviewed+"${unreviewed[@]}"}; do [ "$u" = "$f" ] && { dup=1; break; }; done
  [ "$dup" = 1 ] && continue
  marker_is_terminal "$f" || unreviewed+=("$f")
done < <(git diff-tree -z --no-commit-id --name-only --diff-filter=A -r HEAD 2>/dev/null || true)

if [ "${#unreviewed[@]}" -gt 0 ]; then
  list=""; for u in "${unreviewed[@]}"; do list="$list
  - $u"; done
  reason="미리뷰 spec/plan:$list
${SPEC_REVIEW_INSTRUCTION} 반영을 마친 뒤 종료하라."
  printf '{"decision":"block","reason":"%s"}\n' "$(escape_for_json "$reason")"
fi
exit 0
