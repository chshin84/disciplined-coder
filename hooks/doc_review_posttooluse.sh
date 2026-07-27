#!/usr/bin/env bash
# PostToolUse(Write|Edit | Codex apply_patch): 문서(.md, spec/plan 제외) 작성/수정 감지 → 비자가 검진 넛지(비블로킹, 게이트 아님).
# 경로는 _extract_path.sh가 양 런타임 입력에서 추출(다중 순회). 순수 bash.
set -euo pipefail
[ "${DISCIPLINED_CODER_REVIEW_GATE:-on}" = "off" ] && exit 0
DIR="$(cd "$(dirname "$0")" && pwd)"
. "$DIR/_spec_marker.sh"   # 경로 술어(path_is_specplan) 공유(SSOT)
INPUT="$(cat)"
match=""
while IFS= read -r FILE; do
  [ -n "$FILE" ] || continue
  case "$FILE" in *.md) ;; *) continue ;; esac          # 문서(.md)만
  if path_is_specplan "$FILE"; then continue; fi          # spec/plan은 자체 흐름(하드 게이트)
  match="$FILE"; break
done <<EOF
$(printf '%s' "$INPUT" | bash "$DIR/_extract_path.sh")
EOF
[ -n "$match" ] || exit 0
base="$(basename "$match")"

# (제거됨) 오답노트 발견·복구 넛지 — /add-pointer 폐지와 함께 뺐다. 빈 템플릿을 미리 만들라는
# 권유였는데, 빈 파일은 recall이 발화해도 얻는 교훈이 0이다. 이제 교훈이 생긴 시점에 만든다.

msg="🔎 문서(${base}) 작성/수정됨 — done 하기 전에 reviewer-grounding(사실·정확)+reviewer-fit(양식·계약) 렌즈로 비자가 검진을 거쳐라. 셀프 퇴고만으로 끝내지 말 것. 넛지일 뿐 차단은 아니다."
esc="$(printf '%s' "$msg" | sed 's/\\/\\\\/g; s/"/\\"/g')"
printf '{"hookSpecificOutput":{"hookEventName":"PostToolUse","additionalContext":"%s"}}\n' "$esc"
exit 0
