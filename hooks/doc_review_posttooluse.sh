#!/usr/bin/env bash
# PostToolUse(Write|Edit|Bash): 두 가지를 알린다. 둘 다 비블로킹 경고이고 쓰기를 거부하지 않는다.
#   문서 형식 경고 — 쓴 .md 의 라벨 불릿·개수 예고·제목 개수(판정은 _doc_form_check.py).
#     스위치는 DISCIPLINED_CODER_REPLY_CHECK 다.
#   검진 넛지 — 산출물(.pptx·.xlsx·.docx·.pdf·.hwp·.hwpx)과 그 폴더의 마크다운 작성/수정. spec/plan 은 자체
#     하드 게이트가 맡아 뺀다. 스위치는 DISCIPLINED_CODER_REVIEW_GATE 다.
# 한 훅에 둔 까닭은 대상 뽑기를 한 번만 하려는 것이다. 이 PC 는 프로세스 하나 띄우는 값이 크다.
# 경로는 도구에 따라 한 곳에서 뽑는다. Write·Edit 은 훅 입력의 file_path 이고, Bash 는
# _extract_bash_targets.sh 가 명령줄에서 뽑은 쓰기 대상이다. Bash 를 넣는 이유는 셸로 고치면 이
# 훅이 안 돌기 때문이다. jq 비의존.
set -euo pipefail
INPUT="$(cat)"
DIR="${BASH_SOURCE[0]%/*}"; [ "$DIR" != "${BASH_SOURCE[0]}" ] || DIR=.
. "$DIR/_hook_input.sh"    # 훅 입력 읽기와 쓰기 구문 판정 공유

# 무엇도 하기 전에 거른다. Bash 까지 보게 되면서 이 훅이 모든 셸 호출에 걸리므로, 평상시 값이
# 곧 이 줄이다. Bash 는 명령만 꺼내 쓰기 구문이 있을 때만 대상 뽑기를 부른다(판정은 형제 훅과
# 같은 bash_cmd_writes). 그 밖의 도구는 file_path 만 본다.
json_str tool_name TOOL
if [ "$TOOL" = "Bash" ]; then
  hook_command
  bash_cmd_writes "$CMD" || exit 0
  . "$DIR/_extract_bash_targets.sh"
  TARGETS="$(bash_write_targets "$CMD" || true)"
else
  hook_file_paths
  TARGETS="$FILE_PATHS"
fi
[ -n "$TARGETS" ] || exit 0

. "$DIR/_spec_marker.sh"   # 경로 술어(path_is_specplan·path_is_review_record) 공유
. "$DIR/_json_escape.sh"   # JSON 문자열 이스케이프 공유

# 문서 형식 경고. 대상 파일을 모아 검사기를 한 번만 실행한다. 파이썬이 없거나 검사기가 실패하면
# 알림 없이 넘어간다 — 경고가 빠질 뿐 쓰기에는 영향이 없다.
form=""
if [ "${DISCIPLINED_CODER_REPLY_CHECK:-on}" != "off" ]; then
  set --
  while IFS= read -r FILE; do
    [ -n "$FILE" ] || continue
    path_is_form_target "$FILE" || continue
    [ -f "$FILE" ] || continue
    set -- "$@" "$FILE"
  done <<EOF
$TARGETS
EOF
  if [ "$#" -gt 0 ]; then
    . "$DIR/../scripts/_json_valid.sh"   # 파이썬 인터프리터 고르기
    _json_python || true   # 치환 밖에서 먼저 골라 _JSON_PY 를 남긴다(_json_valid.sh 주석)
    form="$(printf '%s' "$INPUT" | json_run 'import runpy,sys; p=sys.argv[1]; sys.argv=[p]+sys.argv[2:]; runpy.run_path(p, run_name="__main__")' "$DIR/_doc_form_check.py" --hook "$@" 2>/dev/null || true)"
  fi
fi

match=""
[ "${DISCIPLINED_CODER_REVIEW_GATE:-on}" = "off" ] || while IFS= read -r FILE; do
  [ -n "$FILE" ] || continue
  # 거는 대상은 남에게 나가는 산출물과 그 재료다. 사람이 읽을 파일 형식이거나, 그런 파일이
  # 이미 있는 폴더의 마크다운이다. 저장소에 커밋되는 작업 문서에는 걸지 않는다 — 한 줄만 고쳐도
  # 뜨던 것이 잦아 실제로는 아무도 안 보게 됐다.
  #
  # 폴더에 아직 산출물이 없을 때 처음 쓰는 마크다운은 기계로 못 가린다. 그것이 산출물 재료인지는
  # 대화 맥락에만 있으므로 review-docs 가 그 판단을 사람과 모델에게 맡긴다. 여기서 추측하지 않는다.
  case "$FILE" in
    # .html 은 보고서와 웹 화면을 확장자로 가릴 수 없어 넣지 않는다. 고칠 때마다 뜨면 아무도 안 본다.
    *.pptx|*.xlsx|*.docx|*.pdf|*.hwp|*.hwpx) match="$FILE"; break ;;
    *.md) ;;
    *) continue ;;
  esac
  # 그 경로에 파일이 실제로 있는지 먼저 본다. 셸 명령에서 뽑은 대상은 `cd` 를 반영하지 않아
  # 폴더가 빠지거나 다른 폴더 기준일 수 있고, 그러면 아래 `dirname` 이 훅이 도는 세션 폴더로
  # 풀려 엉뚱한 폴더의 산출물을 보고 넛지를 낸다. 존재 확인은 파일을 쓰지 않는 명령도 함께 거른다.
  [ -f "$FILE" ] || continue
  if path_is_specplan "$FILE"; then continue; fi          # spec/plan은 자체 흐름(하드 게이트)
  # 리뷰 기록은 검진 대상이 아니다(판정은 _spec_marker.sh 의 path_is_review_record).
  if path_is_review_record "$FILE"; then continue; fi
  # 같은 폴더에 산출물이 있어야 이 마크다운이 그 재료다. 프로젝트 안팎은 묻지 않는다 — 산출물은
  # 저장소 밖 임시 폴더에 놓이는 것이 보통이라, 프로젝트 안으로 좁히면 정작 대상이 빠진다.
  # 메모리와 계획 파일에 넛지가 뜨던 문제는 이 조건이 대신 막는다. 그 폴더에는 산출물이 없다.
  case "$FILE" in */*) FDIR="${FILE%/*}" ;; *) FDIR=. ;; esac
  has_deliverable=0
  for cand in "$FDIR"/*.pptx "$FDIR"/*.xlsx "$FDIR"/*.docx "$FDIR"/*.pdf "$FDIR"/*.hwp "$FDIR"/*.hwpx; do
    if [ -e "$cand" ]; then has_deliverable=1; break; fi
  done
  [ "$has_deliverable" -eq 1 ] || continue
  match="$FILE"; break
done <<EOF
$TARGETS
EOF
[ -n "$match" ] || [ -n "$form" ] || exit 0

out=""
if [ -n "$form" ]; then
  out="disciplined-coder 문서 형식 경고다. 쓰기는 막지 않았다. 이번 도구 호출에서 쓴 줄은 전달 전에 고쳐라. 파일에 이미 있던 줄은 고쳐 쓰지 말고 사용자에게 알리기만 하라. 이름표가 (파일 전체)이면 파일 전체를 검사한 결과이고, (편집 문자열)이면 줄 번호는 편집한 문자열 안의 번호다. 라벨 불릿은 굵은 라벨 뒤에 문장이 둘 이상인 불릿이며, 산문 문단으로 바꿔라. 개수 예고는 목록 바로 앞 문장이 목록의 개수를 말하는 것이며, 그 개수를 지워라. 제목 개수는 제목에 붙은 개수이며, 제목에서 지우고 필요하면 본문 문장에 적어라. 코드 블록·백틱·인용 줄은 검사하지 않았다.
$form"
fi

# 렌즈 이름을 여기 박지 않는다 — 구성은 review-docs 가 소유하고, 여기 적으면 그 사본이
# 먼저 낡아 훅이 안내하는 렌즈와 문서가 정하는 렌즈가 조용히 갈라진다(spec 훅도 같은 이유로 위임한다).
if [ -n "$match" ]; then
  base="${match##*/}"
  msg="🔎 문서(${base}) 작성/수정됨 — 완료로 보고하기 전에 disciplined-coder review-docs 가 정하는 렌즈로 비자가 검진을 거쳐라. 자기 검토만으로 끝내지 말 것. 퇴고는 변환 전 마크다운 초안에서 하는 것이 순서이니, 초안 단계를 건너뛰었으면 그 사실을 사용자에게 알려라. 고칠 범위는 에이전트원칙을 따른다. 넛지일 뿐 차단은 아니다."
  out="${out:+$out
}$msg"
fi
esc="$(escape_for_json "$out")"
printf '{"hookSpecificOutput":{"hookEventName":"PostToolUse","additionalContext":"%s"}}\n' "$esc"
exit 0
