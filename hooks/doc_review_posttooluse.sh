#!/usr/bin/env bash
# PostToolUse(Write|Edit|Bash): 산출물(.pptx·.xlsx·.docx·.pdf)과 그 폴더의 마크다운 작성/수정
# 감지 → 비자가 검진 넛지(비블로킹, 게이트 아님). spec/plan 은 자체 하드 게이트가 맡아 뺀다.
# 경로는 둘에서 뽑는다. Write·Edit 은 _extract_path.sh 의 file_path 이고, Bash 는
# _extract_bash_targets.sh 가 명령줄에서 뽑은 쓰기 대상이다. 두 입력에 상대 필드가 없어
# 그냥 이어 붙여도 섞이지 않는다. Bash 를 넣는 이유는 셸로 고치면 이 훅이 안 돌기 때문이다 —
# 2026-09-21 에 한 세션이 sed -i 로 문서 열한 개를 고치는 동안 넛지가 한 번도 안 떴다. 순수 bash.
set -euo pipefail
[ "${DISCIPLINED_CODER_REVIEW_GATE:-on}" = "off" ] && exit 0
INPUT="$(cat)"

# 무엇도 하기 전에 거른다. Bash 까지 보게 되면서 이 훅이 모든 셸 호출에 걸리므로, 평상시 값이
# 곧 이 줄이다. file_path 가 있으면 Write·Edit 이라 그대로 가고, 없으면 쓰기 구문이 있을 때만
# 간다. 둘 다 아니면 헬퍼를 싣지도 대상 뽑기를 부르지도 않는다 — 그 셋이 프로세스 값의 전부다.
case "$INPUT" in
  *'"file_path"'*) ;;
  *sed*|*tee*|*cp\ *|*mv\ *|*'>'*) ;;
  *) exit 0 ;;
esac

DIR="$(cd "$(dirname "$0")" && pwd)"
. "$DIR/_spec_marker.sh"   # 경로 술어(path_is_specplan·path_in_project) 공유(SSOT)
. "$DIR/_json_escape.sh"   # JSON 문자열 이스케이프 공유(SSOT)
match=""
while IFS= read -r FILE; do
  [ -n "$FILE" ] || continue
  # 거는 대상은 남에게 나가는 산출물과 그 재료다. 사람이 읽을 파일 형식이거나, 그런 파일이
  # 이미 있는 폴더의 마크다운이다. 저장소에 커밋되는 작업 문서에는 걸지 않는다 — 한 줄만 고쳐도
  # 뜨던 것이 잦아 실제로는 아무도 안 보게 됐다.
  #
  # 폴더에 아직 산출물이 없을 때 처음 쓰는 마크다운은 기계로 못 가린다. 그것이 산출물 재료인지는
  # 대화 맥락에만 있으므로 review-docs 가 그 판단을 사람과 모델에게 맡긴다. 여기서 추측하지 않는다.
  case "$FILE" in
    *.pptx|*.xlsx|*.docx|*.pdf) match="$FILE"; break ;;
    *.md) ;;
    *) continue ;;
  esac
  if path_is_specplan "$FILE"; then continue; fi          # spec/plan은 자체 흐름(하드 게이트)
  # 리뷰 기록은 검진 대상이 아니다. 넛지가 뜨면 기록에 대한 기록을 또 써야 하는 순환이 생기고,
  # 그 순환을 매번 무시하다 보면 진짜 문서에서도 이 넛지를 흘려보내게 된다.
  # 오답노트도 같은 부류다 — 정본이 문제를 완결할 때마다 교훈을 적으라고 요구하는데 그때마다
  # 검진을 묻는 걸음이 붙는다. 형식은 스캐폴드가 강제하고 사람이 처음부터 끝까지 읽는 글도 아니라
  # 문체 검진에서 얻을 것이 거의 없다. 색인과 본문 파일을 함께 뺀다.
  case "$FILE" in
    *docs/superpowers/reviews/*.md) continue ;;
    *solved_problems.md|*solved_problems/*.md) continue ;;
  esac
  # 같은 폴더에 산출물이 있어야 이 마크다운이 그 재료다. 프로젝트 안팎은 묻지 않는다 — 산출물은
  # 저장소 밖 임시 폴더에 놓이는 것이 보통이라, 프로젝트 안으로 좁히면 정작 대상이 빠진다.
  # 메모리와 계획 파일에 넛지가 뜨던 문제는 이 조건이 대신 막는다. 그 폴더에는 산출물이 없다.
  FDIR="$(dirname "$FILE")"
  has_deliverable=0
  # if 로 쓴다. `[ -e x ] && …` 는 조건이 거짓일 때 목록 전체가 1 로 끝나고, set -e 아래에서는
  # 그것이 훅을 그 자리에서 죽인다. 넛지가 조용히 사라지는 것이 그렇게 생긴다.
  for cand in "$FDIR"/*.pptx "$FDIR"/*.xlsx "$FDIR"/*.docx "$FDIR"/*.pdf; do
    if [ -e "$cand" ]; then has_deliverable=1; break; fi
  done
  [ "$has_deliverable" -eq 1 ] || continue
  match="$FILE"; break
done <<EOF
$(printf '%s' "$INPUT" | bash "$DIR/_extract_path.sh"; printf '%s' "$INPUT" | bash "$DIR/_extract_bash_targets.sh")
EOF
[ -n "$match" ] || exit 0
base="$(basename "$match")"

# (제거됨) 오답노트 발견·복구 넛지 — /add-pointer 폐지와 함께 뺐다. 빈 템플릿을 미리 만들라는
# 권유였는데, 빈 파일은 recall이 발화해도 얻는 교훈이 0이다. 이제 교훈이 생긴 시점에 만든다.

# 렌즈 이름을 여기 박지 않는다 — 구성은 review-docs 가 SSOT이고, 여기 적으면 그 사본이
# 먼저 낡아 훅이 안내하는 렌즈와 문서가 정하는 렌즈가 조용히 갈라진다(spec 훅도 같은 이유로 위임한다).
msg="🔎 문서(${base}) 작성/수정됨 — done 하기 전에 disciplined-coder review-docs 가 정하는 렌즈로 비자가 검진을 거쳐라. 셀프 퇴고만으로 끝내지 말 것. 고칠 범위는 정본을 따른다. 넛지일 뿐 차단은 아니다."
esc="$(escape_for_json "$msg")"
printf '{"hookSpecificOutput":{"hookEventName":"PostToolUse","additionalContext":"%s"}}\n' "$esc"
exit 0
