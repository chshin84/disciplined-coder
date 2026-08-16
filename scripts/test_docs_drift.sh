#!/usr/bin/env bash
# 문서의 렌즈 열거가 진실과 어긋나지 않는지 검증. 계약: FAIL=0 (매직넘버 금지 — 개수는 테스트가 센다).
#
# 두 불변식을 단언한다. 어느 쪽도 개수를 박지 않고 두 집합의 일치를 본다.
#   전체 열거   — README의 렌즈 나열 == skills/reviewer-* 디렉터리 집합
#   집계 태깅   — meta-aggregate가 source 값으로 적은 렌즈 == 같은 디렉터리 집합
#   디스패치 셋 — README·DESIGN-NOTES가 spec 리뷰 구성을 적은 줄에 이름이 있다
#                 == domain-spec-review가 디스패치 목록에 적은 렌즈다
# 두 번째의 권위 있는 출처는 호출자 스킬이고 산문의 열거는 그 캐시다(SSOT).
#
# 인지한 대가: 앵커가 산문 문구라 표현을 고치면 내용이 멀쩡해도 붉어진다. 조용히 통과하는 것보다
# 낫다고 보아 그대로 둔다(FAIL-LOUD). 붉어지면 앵커를 새 문구로 맞추면 된다.
set -euo pipefail
HERE="$(cd "$(dirname "$0")/.." && pwd)"
README="$HERE/README.md"
NOTES="$HERE/docs/DESIGN-NOTES.md"
CALLER="$HERE/skills/domain-spec-review/SKILL.md"
AGG="$HERE/skills/meta-aggregate/SKILL.md"
pass=0; fail=0
check() { if eval "$2"; then echo "  PASS: $1"; pass=$((pass+1)); else echo "  FAIL: $1"; fail=$((fail+1)); fi; }

# 진실 1 — 실제 렌즈 디렉터리에서 짧은 이름을 도출한다.
ALL="$(for d in "$HERE"/skills/reviewer-*/; do basename "$d" | sed 's/^reviewer-//'; done | sort)"

# 진실 2 — 호출자가 디스패치 목록에 적은 렌즈. 목록 항목은 "- `reviewer-이름` — 설명" 꼴이다.
DISPATCH="$(grep -oE '^- `reviewer-[a-z-]+`' "$CALLER" | sed 's/^- `reviewer-//; s/`$//' | sort)"

# 캐시 1 — README 트리 주석의 렌즈 나열. 괄호 안을 슬래시로 가른다.
TREE_LINE="$(grep -F 'skills/reviewer-*/SKILL.md' "$README" || true)"
TREE="$(printf '%s' "$TREE_LINE" | sed -n 's/.*(\([^)]*\)).*/\1/p' | tr '/' '\n' | sed 's/^ *//; s/ *$//' | grep -v '^$' | sort || true)"

# 캐시 2 — spec 리뷰 구성을 적은 줄. 앵커를 못 찾으면 조용히 통과하지 않고 터뜨린다.
README_SET_LINE="$(grep -F 'domain-spec-review' "$README" | grep -F 'meta-aggregate' || true)"
NOTES_SET_LINE="$(grep -F '독립 렌즈' "$NOTES" || true)"

# 캐시 3 — meta-aggregate가 집계 항목의 출처를 태깅하는 렌즈 이름 열거.
AGG_LINE="$(grep -F '"source"' "$AGG" || true)"
AGGSET="$(printf '%s' "$AGG_LINE" | sed -n 's/.*"source"[[:space:]]*:[[:space:]]*"\([^"]*\)".*/\1/p' | tr '|' '\n' | sed 's/^ *//; s/ *$//' | grep -v '^$' | sort || true)"

echo "[앵커가 실제로 잡히는가 — 못 잡으면 아래 단언이 헛돈다]"
check "렌즈 디렉터리가 하나 이상 있다"          "[ -n \"\$ALL\" ]"
check "호출자 디스패치 목록을 읽어냈다"          "[ -n \"\$DISPATCH\" ]"
check "README 트리 주석 줄을 찾았다"             "[ -n \"\$TREE_LINE\" ]"
check "README 트리 주석에서 이름을 뽑아냈다"     "[ -n \"\$TREE\" ]"
check "README spec 리뷰 구성 줄을 찾았다"        "[ -n \"\$README_SET_LINE\" ]"
check "DESIGN-NOTES 독립 렌즈 줄을 찾았다"       "[ -n \"\$NOTES_SET_LINE\" ]"

echo "[전체 열거 == 실제 디렉터리]"
check "README 트리 주석이 렌즈 전부를 적는다"    "[ \"\$TREE\" = \"\$ALL\" ]"
if [ "$TREE" != "$ALL" ]; then
  echo "    디렉터리: $(printf '%s' "$ALL" | tr '\n' ' ')"
  echo "    README  : $(printf '%s' "$TREE" | tr '\n' ' ')"
fi

echo "[집계 태깅 == 실제 디렉터리]"
# meta-aggregate의 출력 스키마가 이슈의 출처를 렌즈 이름으로 태깅한다. 그 열거도 렌즈가 늘면 낡는다.
check "meta-aggregate source 줄을 찾았다"        "[ -n \"\$AGG_LINE\" ]"
check "meta-aggregate가 렌즈 전부를 태깅한다"    "[ \"\$AGGSET\" = \"\$ALL\" ]"
if [ "$AGGSET" != "$ALL" ]; then
  echo "    디렉터리      : $(printf '%s' "$ALL" | tr '\n' ' ')"
  echo "    meta-aggregate: $(printf '%s' "$AGGSET" | tr '\n' ' ')"
fi

echo "[산문의 spec 리뷰 셋 == 호출자의 디스패치 셋]"
# 렌즈마다 '디스패치되는가'와 '그 줄에 이름이 있는가'가 같아야 한다.
for name in $ALL; do
  if printf '%s\n' "$DISPATCH" | grep -qx "$name"; then want=1; else want=0; fi
  for pair in "README:$README_SET_LINE" "DESIGN-NOTES:$NOTES_SET_LINE"; do
    doc="${pair%%:*}"; line="${pair#*:}"
    if printf '%s' "$line" | grep -qE "(^|[^a-z-])$name([^a-z-]|$)"; then got=1; else got=0; fi
    if [ "$want" -eq 1 ]; then
      check "$doc 가 디스패치되는 $name 를 적는다"        "[ $got -eq 1 ]"
    else
      check "$doc 가 디스패치 안 되는 $name 를 안 적는다" "[ $got -eq 0 ]"
    fi
  done
done

echo "[산출물 계약 — meta-aggregate가 소유한다]"
check "계약이 consequence 를 필수로 적는다"     "grep -qF 'consequence' \"\$AGG\""
check "계약이 evidence 를 필수로 적는다"        "grep -qF 'evidence' \"\$AGG\""
check "계약이 read 필드를 정의한다"             "grep -qF '\"read\"' \"\$AGG\""
check "계약이 빈손을 정상으로 적는다"           "grep -qF '빈 배열인 것은 정상' \"\$AGG\""
check "계약에 등급 라벨이 없다"                 "! grep -qF 'severity' \"\$AGG\""
check "spec 리뷰에 결정 단계가 없음을 적는다"   "grep -qF 'spec 리뷰에서는 결정 단계가 없다' \"\$AGG\""

echo "[렌즈 계약 — 등급 없음, 근거 필수]"
for d in "$HERE"/skills/reviewer-*/; do
  n="$(basename "$d")"; f="$d/SKILL.md"
  check "$n 에 등급 라벨이 없다"          "! grep -qF 'severity' \"$f\""
  check "$n 이 consequence 를 요구한다"   "grep -qF 'consequence' \"$f\""
  check "$n 이 read 를 요구한다"          "grep -qF '\"read\"' \"$f\""
  check "$n 이 빈손을 정상으로 적는다"    "grep -qF '빈 목록이 정상' \"$f\""
  check "$n 이 읽기 범위를 적는다"        "grep -qF '읽기 범위' \"$f\""
done

echo "[spec 리뷰 — 처분은 호출자가 정한다]"
check "재작성 라우팅이 남아 있지 않다"        "! grep -qF 'regenerate' \"\$CALLER\""
check "🔴 진입 기준을 적는다"                 "grep -qF '되돌리기 어려운 결정인가' \"\$CALLER\""
check "기본값이 고치기임을 적는다"            "grep -qF '기본값이 고치기' \"\$CALLER\""
check "마커를 개선보다 먼저 남기라고 적는다"  "grep -qF '마커를 먼저 남긴다' \"\$CALLER\""

RUNTIME="$HERE/skills/domain-llm-runtime/SKILL.md"
echo "[런타임 — 등급이 아니라 type 으로 행동을 정한다]"
check "런타임 파일을 찾았다"                "[ -f \"\$RUNTIME\" ]"
check "등급 기반 재생성이 남아 있지 않다"    "! grep -qF 'critical만 regenerate' \"\$RUNTIME\""
check "type 기반 처분 표를 적는다"          "grep -qF '값으로 행동을 정하는 표' \"\$RUNTIME\""

PTU="$HERE/hooks/spec_review_posttooluse.sh"
STOPH="$HERE/hooks/spec_review_stop.sh"
echo "[훅 안내문 — 마커를 개선보다 먼저]"
check "PostToolUse 안내문이 마커 선기록을 지시한다" "grep -qF '마커를 먼저 남기고' \"\$PTU\""
check "Stop 안내문이 마커 선기록을 지시한다"        "grep -qF '마커를 먼저 남기고' \"\$STOPH\""

echo "[리뷰 절차 — 2회 표집과 그 적용 범위]"
DOCS="$HERE/skills/domain-docs/SKILL.md"
RUNTIME2="$HERE/skills/domain-llm-runtime/SKILL.md"
READMEF="$HERE/README.md"
check "렌즈를 2회씩 띄운다고 적는다"         "grep -qF '2회씩' \"\$CALLER\""
check "2회 규칙의 적용 범위를 적는다"        "grep -qF 'spec·plan 리뷰에만 적용된다' \"\$CALLER\""
check "문서 검진은 한 번씩만 띄운다"          "grep -qF '렌즈는 한 번씩만 띄운다' \"\$DOCS\""
check "런타임은 한 번씩만 부른다"             "grep -qF '리뷰어는 한 번씩만 부른다' \"\$RUNTIME2\""

echo "[렌즈끼리 볼 것을 나눠 주지 않는다 — 세 호출자 모두]"
check "spec 리뷰가 나눠 주지 않는다"          "grep -qF '렌즈끼리 볼 것을 나눠 주지 않는다' \"\$CALLER\""
check "문서 검진이 나눠 주지 않는다"          "grep -qF '렌즈끼리 볼 것을 나눠 주지 않는다' \"\$DOCS\""
check "런타임이 나눠 주지 않는다"             "grep -qF '렌즈끼리 볼 것을 나눠 주지 않는다' \"\$RUNTIME2\""

echo "[기록 — 자리와 담을 것]"
check "spec 리뷰 기록의 자리를 적는다"       "grep -qF 'docs/superpowers/reviews/' \"\$CALLER\""
check "문서 검진 기록의 자리를 적는다"       "grep -qF 'docs/superpowers/reviews/' \"\$DOCS\""
check "문서 검진 기록의 이름을 적는다"       "grep -qF '-check.md' \"\$DOCS\""
check "문서 검진은 처리 결과를 함께 적는다"   "grep -qF '무엇을 고쳤고 무엇을 넘겼는지' \"\$DOCS\""
check "spec 리뷰 기록은 처리 결과를 뺀다"    "grep -qF '어떻게 처리했는지는 담지 않는다' \"\$CALLER\""
check "대신 근거를 설계 문서 본문에 적는다"   "grep -qF '근거를 검토 대상 문서 본문에 적는다' \"\$CALLER\""
check "기록 파일 이름에 회차가 들어간다"      "grep -qF '-review-2.md' \"\$CALLER\""
check "원본을 받는 즉시 저장한다"            "grep -qF '받는 즉시' \"\$CALLER\""
check "원본을 같은 이름 폴더에 둔다"          "grep -qF '같은 이름의 폴더' \"\$CALLER\""
check "런타임이 기록 제외 이유를 적는다"      "grep -qF '사용자 입력이 로그로' \"\$RUNTIME2\""

echo "[합치기와 다시 리뷰]"
check "합칠 때 세 기준으로 거른다"           "grep -qF '근거가 서 있는지만 묻는다' \"\$CALLER\""
check "기능적 변화면 다시 리뷰한다고 적는다"  "grep -qF '기능적 변화' \"\$CALLER\""
check "다시 리뷰는 매번 사용자에게 묻는다"    "grep -qF '다시 리뷰는 매번 사용자에게 묻는다' \"\$CALLER\""
check "README 도 사용자에게 묻는다고 적는다"  "grep -qF '다시 리뷰할지 사용자에게 묻는다' \"\$READMEF\""
check "🔴 반영도 다시 리뷰 대상이다"          "grep -qF '를 반영한 것도 대상이다' \"\$CALLER\""
check "무엇이 남았는지 문서에 안 적는다"      "grep -qF '문서에 적지 않는다' \"\$CALLER\""
check "문서 검진에 재검진 반복이 없다"        "grep -qF '다시 검진하지는 않는다' \"\$DOCS\""
check "런타임에 다시 리뷰 반복이 없다"        "grep -qF '다시 리뷰하지는 않는다' \"\$RUNTIME2\""

echo "[대체된 설계 문서에 superseded 표시]"
OLDSPEC="$HERE/docs/superpowers/specs/2026-08-16-review-layer-redesign-design.md"
OLDPLAN="$HERE/docs/superpowers/plans/2026-08-16-review-layer-redesign.md"
check "옛 spec 에 superseded 표시가 있다"   "grep -qF 'superseded' \"\$OLDSPEC\""
check "옛 plan 에 superseded 표시가 있다"   "grep -qF 'superseded' \"\$OLDPLAN\""

echo "----"; echo "PASS=$pass FAIL=$fail"; [ "$fail" -eq 0 ]
