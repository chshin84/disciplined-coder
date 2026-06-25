#!/usr/bin/env bash
# PreToolUse(Write|Edit | Codex apply_patch): 새 문서(.md, spec/plan 제외) 생성 감지 → domain-docs 양식 제안(비블로킹).
# 경로는 _extract_path.sh가 양 런타임 입력에서 추출(다중 경로 순회). 순수 bash.
set -euo pipefail
[ "${DISCIPLINED_CODER_REVIEW_GATE:-on}" = "off" ] && exit 0
DIR="$(cd "$(dirname "$0")" && pwd)"
INPUT="$(cat)"
match=""
while IFS= read -r FILE; do
  [ -n "$FILE" ] || continue
  case "$FILE" in *.md) ;; *) continue ;; esac          # 문서(.md)만
  case "$FILE" in */docs/superpowers/specs/*|*/docs/superpowers/plans/*) continue ;; esac  # spec/plan은 자체 흐름
  [ -e "$FILE" ] && continue                             # 생성 때만 제안(편집은 양식 이미 정해짐)
  match="$FILE"; break
done <<EOF
$(printf '%s' "$INPUT" | bash "$DIR/_extract_path.sh")
EOF
[ -n "$match" ] || exit 0
msg="📝 새 문서 작성 — 쓰기 전에 domain-docs '글 유형별 적용'에서 목적에 맞는 양식을 고르고(README·버그리포트·작업보고·기술블로그), 결론/요약을 앞에 두고 내용을 양식대로 배치하라."
esc="$(printf '%s' "$msg" | sed 's/\\/\\\\/g; s/"/\\"/g')"
printf '{"hookSpecificOutput":{"hookEventName":"PreToolUse","additionalContext":"%s"}}\n' "$esc"
exit 0
