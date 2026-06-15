#!/usr/bin/env bash
# Stop: 미리뷰 spec/plan이 남으면 종료 차단(하드 게이트). 루프가드: stop_hook_active.
# 탐지: git 변경분(미추적 디렉터리 포함 -uall) 중 마지막 줄이 terminal 마커가 아닌 spec/plan.
# 순수 bash(jq 비의존). git/디렉터리 없으면 FAIL-OPEN(작업불능 방지 — 알려진 한계).
set -euo pipefail
[ "${DISCIPLINED_CODER_REVIEW_GATE:-on}" = "off" ] && exit 0
INPUT="$(cat)"
case "$INPUT" in *'"stop_hook_active":true'*|*'"stop_hook_active": true'*) exit 0 ;; esac  # 루프가드
command -v git >/dev/null 2>&1 || exit 0
cwd="$(printf '%s' "$INPUT" | sed -n 's/.*"cwd"[[:space:]]*:[[:space:]]*"\([^"]*\)".*/\1/p' | head -n1)"
cwd="$(printf '%s' "$cwd" | tr -s '\\' '/')"
if [ -n "$cwd" ]; then cd "$cwd" 2>/dev/null || exit 0; fi
git rev-parse --is-inside-work-tree >/dev/null 2>&1 || exit 0

marker_ok() {  # $1=파일 → 마지막 비공백 줄이 terminal 마커면 0
  local last
  last="$(grep -v '^[[:space:]]*$' "$1" 2>/dev/null | tail -n 1 || true)"
  case "$last" in
    *'<!-- spec-review: passed'*|*'<!-- spec-review: escalated'*) return 0 ;;
    *) return 1 ;;
  esac
}

unreviewed=""
while IFS= read -r f; do
  [ -n "$f" ] || continue
  case "$f" in
    *docs/superpowers/specs/*.md|*docs/superpowers/plans/*.md) ;;
    *) continue ;;
  esac
  [ -f "$f" ] || continue
  marker_ok "$f" || unreviewed="$unreviewed $f"
done < <(git status --porcelain --untracked-files=all -- docs/superpowers/specs docs/superpowers/plans 2>/dev/null | cut -c4-)

if [ -n "$unreviewed" ]; then
  reason="미리뷰 spec/plan:$unreviewed — disciplined-coder domain-spec-review(3렌즈+PREP)를 수행하고 문서 마지막 줄에 spec-review 마커(passed 또는 escalated, HTML 주석)를 남긴 뒤 종료하라."
  esc="$(printf '%s' "$reason" | sed 's/\\/\\\\/g; s/"/\\"/g')"
  printf '{"decision":"block","reason":"%s"}\n' "$esc"
fi
exit 0
