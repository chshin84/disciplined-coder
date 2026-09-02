#!/usr/bin/env bash
# PostToolUse(Write|Edit): 문서(.md, spec/plan 제외) 작성/수정 감지 → 비자가 검진 넛지(비블로킹, 게이트 아님).
# 경로는 _extract_path.sh가 추출(다중 순회). 순수 bash.
set -euo pipefail
[ "${DISCIPLINED_CODER_REVIEW_GATE:-on}" = "off" ] && exit 0
DIR="$(cd "$(dirname "$0")" && pwd)"
. "$DIR/_spec_marker.sh"   # 경로 술어(path_is_specplan) 공유(SSOT)
. "$DIR/_json_escape.sh"   # JSON 문자열 이스케이프 공유(SSOT)
INPUT="$(cat)"
match=""
while IFS= read -r FILE; do
  [ -n "$FILE" ] || continue
  case "$FILE" in *.md) ;; *) continue ;; esac          # 문서(.md)만
  if path_is_specplan "$FILE"; then continue; fi          # spec/plan은 자체 흐름(하드 게이트)
  # 리뷰 기록은 검진 대상이 아니다. 넛지가 뜨면 기록에 대한 기록을 또 써야 하는 순환이 생기고,
  # 그 순환을 매번 무시하다 보면 진짜 문서에서도 이 넛지를 흘려보내게 된다.
  # 오답노트도 같은 부류다 — 정본이 문제를 완결할 때마다 교훈을 적으라고 요구하는데 그때마다
  # 검진을 묻는 걸음이 붙는다. 형식은 스캐폴드가 강제하고 사람이 처음부터 끝까지 읽는 글도 아니라
  # 문체 검진에서 얻을 것이 거의 없다. 색인과 본문 파일을 함께 뺀다.
  case "$FILE" in
    *docs/superpowers/reviews/*.md) continue ;;
  esac
  match="$FILE"; break
done <<EOF
$(printf '%s' "$INPUT" | bash "$DIR/_extract_path.sh")
EOF
[ -n "$match" ] || exit 0
base="$(basename "$match")"

# (제거됨) 오답노트 발견·복구 넛지 — /add-pointer 폐지와 함께 뺐다. 빈 템플릿을 미리 만들라는
# 권유였는데, 빈 파일은 recall이 발화해도 얻는 교훈이 0이다. 이제 교훈이 생긴 시점에 만든다.

# 렌즈 이름을 여기 박지 않는다 — 구성은 domain-docs의 문서 검진 절이 SSOT이고, 여기 적으면 그 사본이
# 먼저 낡아 훅이 안내하는 렌즈와 문서가 정하는 렌즈가 조용히 갈라진다(spec 훅도 같은 이유로 위임한다).
msg="🔎 문서(${base}) 작성/수정됨 — done 하기 전에 disciplined-coder domain-docs의 문서 검진 절이 정하는 렌즈로 비자가 검진을 거쳐라. 셀프 퇴고만으로 끝내지 말 것. 넛지일 뿐 차단은 아니다."
esc="$(escape_for_json "$msg")"
printf '{"hookSpecificOutput":{"hookEventName":"PostToolUse","additionalContext":"%s"}}\n' "$esc"
exit 0
