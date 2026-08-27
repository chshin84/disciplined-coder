#!/usr/bin/env bash
# Stop: 미리뷰 spec/plan이 남으면 종료 차단(하드 게이트). 루프가드: stop_hook_active.
# 탐지: git 신규(미추적·추가) spec/plan + HEAD 커밋이 추가한 spec/plan 중 마지막 줄이 terminal
# 마커가 아닌 것(Fix C — 같은 턴 커밋 우회 차단). 기존 파일 수정은 제외(Fix A).
# 순수 bash(jq 비의존). git/디렉터리 없으면 FAIL-OPEN(작업불능 방지 — 알려진 한계).
set -euo pipefail
[ "${DISCIPLINED_CODER_REVIEW_GATE:-on}" = "off" ] && exit 0
HOOKDIR="$(cd "$(dirname "$0")" && pwd)"
. "$HOOKDIR/_spec_marker.sh"    # terminal 마커 판정(SSOT) 공유
. "$HOOKDIR/_json_escape.sh"    # JSON 문자열 이스케이프(SSOT) 공유
INPUT="$(cat)"
case "$INPUT" in *'"stop_hook_active":true'*|*'"stop_hook_active": true'*) exit 0 ;; esac  # 루프가드
command -v git >/dev/null 2>&1 || exit 0
cwd="$(printf '%s' "$INPUT" | sed -n 's/.*"cwd"[[:space:]]*:[[:space:]]*"\([^"]*\)".*/\1/p' | head -n1)"
cwd="$(printf '%s' "$cwd" | tr -s '\\' '/')"
if [ -n "$cwd" ]; then cd "$cwd" 2>/dev/null || exit 0; fi
git rev-parse --is-inside-work-tree >/dev/null 2>&1 || exit 0
# 레포 루트로 옮긴 뒤에 찾는다. 아래 두 탐색이 모두 레포 루트 기준 경로를 쓰기 때문이다 —
# git status 의 pathspec(`docs/superpowers/...`)은 현재 폴더 기준이고, diff-tree 가 돌려주는
# 경로와 `[ -f "$f" ]` 도 루트 기준이다. 그래서 세션의 작업 폴더가 하위 폴더이면(예: myrepo/backend)
# 미리뷰 spec 을 하나도 못 찾고 아무 메시지 없이 통과시켰다 — 게이트가 꺼진 것을 알아챌 방법이
# 없는 조용한 실패다(`FAIL-LOUD`).
_root="$(git rev-parse --show-toplevel 2>/dev/null || true)"
[ -n "$_root" ] || exit 0
cd "$_root" 2>/dev/null || exit 0

# 경로는 배열에 모은다 — 공백으로 이어 붙이면 NUL 종료로 얻은 안전성이 그 자리에서 무너진다.
unreviewed=()
# -z: NUL 종료 + 따옴표/이스케이프 없는 raw 경로(공백·비ASCII 안전). --no-renames: 리네임을
# del+add 로 분해해 'old -> new' 합침 레코드를 없앤다. 각 레코드는 'XY ' 3글자 프리픽스 + 경로.
while IFS= read -r -d '' entry; do
  f="${entry:3}"
  [ -n "$f" ] || continue
  # Fix A: 신규(미추적 ??·추가 A)만 하드게이트 — 기존 spec 수정(상태 strip 등)엔 안 건다(넛지는 PostToolUse가).
  case "${entry:0:2}" in '??'|A*) ;; *) continue ;; esac
  path_is_specplan "$f" || continue
  [ -f "$f" ] || continue
  marker_is_terminal "$f" || unreviewed+=("$f")
done < <(git status -z --porcelain --untracked-files=all --no-renames -- docs/superpowers/specs docs/superpowers/plans 2>/dev/null)

# Fix C: 같은 턴 커밋 우회 차단 — HEAD 커밋이 추가(A)한 spec/plan도 검사한다.
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
disciplined-coder domain-spec-review(PREP+독립 렌즈, 렌즈 구성은 그 스킬이 정한다)를 수행하고, 개선보다 앞서 문서 마지막 줄에 spec-review 마커를 먼저 남기고(passed 또는 escalated, HTML 주석) 그다음 개선을 반영한 뒤 종료하라."
  printf '{"decision":"block","reason":"%s"}\n' "$(escape_for_json "$reason")"
fi
exit 0
