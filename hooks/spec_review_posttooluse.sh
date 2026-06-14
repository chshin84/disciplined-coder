#!/usr/bin/env bash
# PostToolUse(Write|Edit): spec/plan 작성 감지 → 미리뷰면 3렌즈+PREP 독립 리뷰 수행 지시 주입(비블로킹).
# 마커: 문서 마지막 비공백 줄의 terminal HTML 주석(passed|escalated)만 인정(본문 예시와 거짓매칭 불가).
# 순수 bash(jq 비의존 — 대상 환경에 jq가 없을 수 있음). 백슬래시 경로 정규화.
set -euo pipefail
[ "${DISCIPLINED_CODER_REVIEW_GATE:-on}" = "off" ] && exit 0
INPUT="$(cat)"
FILE="$(printf '%s' "$INPUT" | sed -n 's/.*"file_path"[[:space:]]*:[[:space:]]*"\([^"]*\)".*/\1/p' | head -n1)"
[ -n "$FILE" ] || exit 0
FILE="$(printf '%s' "$FILE" | tr -s '\\' '/')"     # 백슬래시→슬래시 정규화
case "$FILE" in
  */docs/superpowers/specs/*.md|*/docs/superpowers/plans/*.md) ;;
  *) exit 0 ;;                                       # 0-cost 조기탈출
esac
# 마지막 비공백 줄이 terminal 마커면 침묵(재작업 편집의 무한 재트리거 방지)
if [ -f "$FILE" ]; then
  last="$(grep -v '^[[:space:]]*$' "$FILE" 2>/dev/null | tail -n 1 || true)"
  case "$last" in
    *'<!-- spec-review: passed'*|*'<!-- spec-review: escalated'*) exit 0 ;;
  esac
fi
base="$(basename "$FILE")"
msg="📋 spec/plan(${base}) 작성됨 — 진행 전 반드시 disciplined-coder advisor-spec-review 스킬로 3렌즈+PREP 독립 리뷰를 수행하고, 완료 시 문서 마지막 줄에 spec-review passed 마커(HTML 주석)를 남겨라."
esc="$(printf '%s' "$msg" | sed 's/\\/\\\\/g; s/"/\\"/g')"
printf '{"hookSpecificOutput":{"hookEventName":"PostToolUse","additionalContext":"%s"}}\n' "$esc"
exit 0
