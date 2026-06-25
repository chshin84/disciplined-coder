#!/usr/bin/env bash
# PostToolUse(Write|Edit | Codex apply_patch): spec/plan 작성 감지 → 미리뷰면 3렌즈+PREP 리뷰 지시(비블로킹).
# 마커: 마지막 비공백 줄의 terminal HTML 주석(passed|escalated)만 인정. 경로는 _extract_path.sh(다중 순회).
set -euo pipefail
[ "${DISCIPLINED_CODER_REVIEW_GATE:-on}" = "off" ] && exit 0
DIR="$(cd "$(dirname "$0")" && pwd)"
INPUT="$(cat)"
match=""
while IFS= read -r FILE; do
  [ -n "$FILE" ] || continue
  case "$FILE" in
    */docs/superpowers/specs/*.md|*/docs/superpowers/plans/*.md) ;;
    *) continue ;;
  esac
  if [ -f "$FILE" ]; then
    last="$(grep -v '^[[:space:]]*$' "$FILE" 2>/dev/null | tail -n 1 || true)"
    case "$last" in
      *'<!-- spec-review: passed'*|*'<!-- spec-review: escalated'*) continue ;;
    esac
  fi
  match="$FILE"; break
done <<EOF
$(printf '%s' "$INPUT" | bash "$DIR/_extract_path.sh")
EOF
[ -n "$match" ] || exit 0
base="$(basename "$match")"
msg="📋 spec/plan(${base}) 작성됨 — 진행 전 반드시 disciplined-coder domain-spec-review 스킬로 3렌즈+PREP 독립 리뷰를 수행하고, 완료 시 문서 마지막 줄에 spec-review passed 마커(HTML 주석)를 남겨라."
esc="$(printf '%s' "$msg" | sed 's/\\/\\\\/g; s/"/\\"/g')"
printf '{"hookSpecificOutput":{"hookEventName":"PostToolUse","additionalContext":"%s"}}\n' "$esc"
exit 0
