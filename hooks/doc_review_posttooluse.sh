#!/usr/bin/env bash
# PostToolUse(Write|Edit | Codex apply_patch): 문서(.md, spec/plan 제외) 작성/수정 감지 → 비자가 검진 넛지(비블로킹, 게이트 아님).
# 경로는 _extract_path.sh가 양 런타임 입력에서 추출(다중 순회). 순수 bash.
set -euo pipefail
[ "${DISCIPLINED_CODER_REVIEW_GATE:-on}" = "off" ] && exit 0
DIR="$(cd "$(dirname "$0")" && pwd)"
INPUT="$(cat)"
match=""
while IFS= read -r FILE; do
  [ -n "$FILE" ] || continue
  case "$FILE" in *.md) ;; *) continue ;; esac          # 문서(.md)만
  case "$FILE" in */docs/superpowers/specs/*|*/docs/superpowers/plans/*) continue ;; esac  # spec/plan은 하드 게이트
  match="$FILE"; break
done <<EOF
$(printf '%s' "$INPUT" | bash "$DIR/_extract_path.sh")
EOF
[ -n "$match" ] || exit 0
base="$(basename "$match")"

# 프로젝트 루트 CLAUDE.md면 오답노트 발견·복구 넛지로 대체(이중 넛지 회피). 그 외 .md는 아래 generic 넛지.
proj="${CLAUDE_PROJECT_DIR:-}"
if [ "$base" = "CLAUDE.md" ] && [ -n "$proj" ]; then
  proj_n="$(printf '%s' "$proj" | tr '\\' '/')"
  mdir="$(cd "$(dirname "$match")" 2>/dev/null && pwd -P || true)"
  proot="$(cd "$proj_n" 2>/dev/null && pwd -P || true)"
  if [ -n "$mdir" ] && [ -n "$proot" ] && [ "$mdir" = "$proot" ]; then
    if [ ! -f "$proj_n/docs/solved_problems.md" ]; then
      ps="💡 이 프로젝트엔 오답노트가 없습니다 — /add-pointer 로 docs/solved_problems.md + 포인터를 추가하면 디버깅 시 recall됩니다(옵트인)."
    elif ! { grep -qF '# BEGIN disciplined-coder' "$match" && grep -qF '# END disciplined-coder' "$match"; } 2>/dev/null; then
      ps="💡 docs/solved_problems.md는 있는데 CLAUDE.md 포인터가 없습니다(또는 반쯤 깨짐) — /add-pointer 재실행으로 복구하세요."
    else
      exit 0   # 로그+온전한 포인터 → 무넛지
    fi
    esc="$(printf '%s' "$ps" | sed 's/\\/\\\\/g; s/"/\\"/g')"
    printf '{"hookSpecificOutput":{"hookEventName":"PostToolUse","additionalContext":"%s"}}\n' "$esc"
    exit 0
  fi
fi

msg="🔎 문서(${base}) 작성/수정됨 — done 하기 전에 reviewer-grounding(사실·정확)+reviewer-fit(양식·계약) 렌즈로 비자가 검진을 거쳐라. 셀프 퇴고만으로 끝내지 말 것. 넛지일 뿐 차단은 아니다."
esc="$(printf '%s' "$msg" | sed 's/\\/\\\\/g; s/"/\\"/g')"
printf '{"hookSpecificOutput":{"hookEventName":"PostToolUse","additionalContext":"%s"}}\n' "$esc"
exit 0
