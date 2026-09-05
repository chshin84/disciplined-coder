#!/usr/bin/env bash
# PreToolUse(Write|Edit): 새 문서(.md, spec/plan 제외) 생성 감지 → 정본의 문서 규칙 제안(비블로킹).
# 경로는 _extract_path.sh가 추출(다중 경로 순회). 순수 bash.
set -euo pipefail
[ "${DISCIPLINED_CODER_REVIEW_GATE:-on}" = "off" ] && exit 0
DIR="$(cd "$(dirname "$0")" && pwd)"
. "$DIR/_spec_marker.sh"   # 경로 술어(path_is_specplan·path_in_project) 공유(SSOT)
. "$DIR/_json_escape.sh"   # JSON 문자열 이스케이프 공유(SSOT)
INPUT="$(cat)"
match=""
while IFS= read -r FILE; do
  [ -n "$FILE" ] || continue
  case "$FILE" in *.md) ;; *) continue ;; esac          # 문서(.md)만
  if path_is_specplan "$FILE"; then continue; fi          # spec/plan은 자체 흐름(하드 게이트)
  case "$FILE" in *docs/superpowers/reviews/*.md) continue ;; esac   # 리뷰 기록은 양식이 검진 절이 정한다
  [ -e "$FILE" ] && continue                             # 생성 때만 제안(편집은 양식 이미 정해짐)
  path_in_project "$FILE" || continue                    # 프로젝트 밖 문서(메모리·계획 파일)에는 걸지 않는다
  match="$FILE"; break
done <<EOF
$(printf '%s' "$INPUT" | bash "$DIR/_extract_path.sh")
EOF
[ -n "$match" ] || exit 0
msg="📝 새 문서 작성 — 쓰기 전에 정본의 '문서를 쓰고 관리할 때' 절에서 이 문서의 타입과 수명을 가리고, 결론을 앞에 두고 내용을 배치하라. README 라면 disciplined-coder domain-readme 를 함께 열어라."
esc="$(escape_for_json "$msg")"
printf '{"hookSpecificOutput":{"hookEventName":"PreToolUse","additionalContext":"%s"}}\n' "$esc"
exit 0
