#!/usr/bin/env bash
# PostToolUse(Write|Edit): 문서(.md, spec/plan 제외) 작성/수정 감지 → 비자가 검진 넛지(비블로킹, 게이트 아님).
# 사람 흉내: 발행 전 남의 눈으로 본다. 셀프 퇴고만으로 끝내지 않는다. 발행물이라 파일 마커 미사용.
# 순수 bash(jq 비의존). 백슬래시 경로 정규화.
set -euo pipefail
[ "${DISCIPLINED_CODER_REVIEW_GATE:-on}" = "off" ] && exit 0
INPUT="$(cat)"
FILE="$(printf '%s' "$INPUT" | sed -n 's/.*"file_path"[[:space:]]*:[[:space:]]*"\([^"]*\)".*/\1/p' | head -n1)"
[ -n "$FILE" ] || exit 0
FILE="$(printf '%s' "$FILE" | tr -s '\\' '/')"     # 백슬래시→슬래시 정규화
case "$FILE" in *.md) ;; *) exit 0 ;; esac          # 문서(.md)만
case "$FILE" in
  */docs/superpowers/specs/*|*/docs/superpowers/plans/*) exit 0 ;;  # spec/plan은 자체 흐름(하드 게이트)
esac
base="$(basename "$FILE")"
msg="🔎 문서(${base}) 작성/수정됨 — done 하기 전에 reviewer-grounding(사실·정확)+reviewer-fit(양식·계약) 렌즈로 비자가 검진을 거쳐라. 셀프 퇴고만으로 끝내지 말 것. 넛지일 뿐 차단은 아니다."
esc="$(printf '%s' "$msg" | sed 's/\\/\\\\/g; s/"/\\"/g')"
printf '{"hookSpecificOutput":{"hookEventName":"PostToolUse","additionalContext":"%s"}}\n' "$esc"
exit 0
