#!/usr/bin/env bash
# PreToolUse(Write|Edit): 새 문서(.md, spec/plan 제외) 생성 감지 → domain-docs 양식 제안 주입(비블로킹).
# 사람 흉내: 쓰기 전에 목적에 맞는 템플릿을 고른다. 이미 있으면(편집) 양식은 정해졌으니 침묵.
# 순수 bash(jq 비의존 — 대상 환경에 jq가 없을 수 있음). 백슬래시 경로 정규화.
set -euo pipefail
[ "${DISCIPLINED_CODER_REVIEW_GATE:-on}" = "off" ] && exit 0
INPUT="$(cat)"
FILE="$(printf '%s' "$INPUT" | sed -n 's/.*"file_path"[[:space:]]*:[[:space:]]*"\([^"]*\)".*/\1/p' | head -n1)"
[ -n "$FILE" ] || exit 0
FILE="$(printf '%s' "$FILE" | tr -s '\\' '/')"     # 백슬래시→슬래시 정규화
case "$FILE" in *.md) ;; *) exit 0 ;; esac          # 문서(.md)만
case "$FILE" in
  */docs/superpowers/specs/*|*/docs/superpowers/plans/*) exit 0 ;;  # spec/plan은 자체 흐름
esac
[ -e "$FILE" ] && exit 0                             # 생성 때만 제안(편집은 양식 이미 정해짐)
msg="📝 새 문서 작성 — 쓰기 전에 domain-docs '글 유형별 적용'에서 목적에 맞는 양식을 고르고(README·버그리포트·작업보고·기술블로그), 결론/요약을 앞에 두고 내용을 양식대로 배치하라."
esc="$(printf '%s' "$msg" | sed 's/\\/\\\\/g; s/"/\\"/g')"
printf '{"hookSpecificOutput":{"hookEventName":"PreToolUse","additionalContext":"%s"}}\n' "$esc"
exit 0
