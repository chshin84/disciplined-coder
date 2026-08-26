#!/usr/bin/env bash
# 문서의 렌즈 열거가 진실과 어긋나지 않는지 검증. 계약: FAIL=0 (매직넘버 금지 — 개수는 테스트가 센다).
#
# 두 불변식을 단언한다. 어느 쪽도 개수를 박지 않고 두 집합의 일치를 본다.
#   전체 열거   — DESIGN-NOTES 저장소 구성 트리의 렌즈 나열 == skills/reviewer-* 디렉터리 집합
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

# 캐시 1 — DESIGN-NOTES 트리 주석의 렌즈 나열. 괄호 안을 슬래시로 가른다.
# 이 트리는 README에 있었으나 개발자용 내부 근거라 DESIGN-NOTES로 옮겼다(domain-docs의 README 독자 분리).
TREE_LINE="$(grep -F 'skills/reviewer-*/SKILL.md' "$NOTES" || true)"
TREE="$(printf '%s' "$TREE_LINE" | sed -n 's/.*(\([^)]*\)).*/\1/p' | tr '/' '\n' | sed 's/^ *//; s/ *$//' | grep -v '^$' | sort || true)"

# 캐시 2 — spec 리뷰 구성을 적은 줄. 앵커를 못 찾으면 조용히 통과하지 않고 터뜨린다.
# 이 줄이 README에 있든 DESIGN-NOTES에 있든 뜻은 같다 — 어디에 적혔는지가 아니라 적힌 렌즈 집합이
# 실제와 어긋나지 않는지를 본다. 그래서 문서를 재배치해도 검사가 따라오도록 둘에서 함께 찾는다.
SPEC_SET_LINE="$(grep -hF 'domain-spec-review' "$README" "$NOTES" | grep -F 'meta-aggregate' || true)"
NOTES_SET_LINE="$(grep -F '독립 렌즈' "$NOTES" || true)"

# 캐시 3 — meta-aggregate가 집계 항목의 출처를 태깅하는 렌즈 이름 열거.
AGG_LINE="$(grep -F '"source"' "$AGG" || true)"
AGGSET="$(printf '%s' "$AGG_LINE" | sed -n 's/.*"source"[[:space:]]*:[[:space:]]*"\([^"]*\)".*/\1/p' | tr '|' '\n' | sed 's/^ *//; s/ *$//' | grep -v '^$' | sort || true)"

echo "[앵커가 실제로 잡히는가 — 못 잡으면 아래 단언이 헛돈다]"
check "렌즈 디렉터리가 하나 이상 있다"          "[ -n \"\$ALL\" ]"
check "호출자 디스패치 목록을 읽어냈다"          "[ -n \"\$DISPATCH\" ]"
check "DESIGN-NOTES 트리 주석 줄을 찾았다"       "[ -n \"\$TREE_LINE\" ]"
check "DESIGN-NOTES 트리 주석에서 이름을 뽑아냈다" "[ -n \"\$TREE\" ]"
check "spec 리뷰 구성 줄을 찾았다"              "[ -n \"\$SPEC_SET_LINE\" ]"
check "DESIGN-NOTES 독립 렌즈 줄을 찾았다"       "[ -n \"\$NOTES_SET_LINE\" ]"

echo "[전체 열거 == 실제 디렉터리]"
check "DESIGN-NOTES 트리 주석이 렌즈 전부를 적는다" "[ \"\$TREE\" = \"\$ALL\" ]"
if [ "$TREE" != "$ALL" ]; then
  echo "    디렉터리    : $(printf '%s' "$ALL" | tr '\n' ' ')"
  echo "    DESIGN-NOTES: $(printf '%s' "$TREE" | tr '\n' ' ')"
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
  for pair in "spec리뷰 구성 줄:$SPEC_SET_LINE" "DESIGN-NOTES 독립 렌즈 줄:$NOTES_SET_LINE"; do
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

echo "[리뷰 절차 — 렌즈를 한 번씩 띄우고 결과를 한데 모은다]"
DOCS="$HERE/skills/domain-docs/SKILL.md"
RUNTIME2="$HERE/skills/domain-llm-runtime/SKILL.md"
READMEF="$HERE/README.md"
check "spec 리뷰가 렌즈를 한 번씩만 띄운다"   "grep -qF '렌즈마다 한 번씩만 띄운다' \"\$CALLER\""
check "옛 2회 표집 규정이 남아 있지 않다"     "! grep -qF '2회씩' \"\$CALLER\""
check "렌즈별 결과를 한데 모으는 것은 남는다" "grep -qF '한데 모아 관리하는 것은 그대로다' \"\$CALLER\""
check "문서 검진은 한 번씩만 띄운다"          "grep -qF '렌즈는 한 번씩만 띄운다' \"\$DOCS\""
check "런타임은 한 번씩만 부른다"             "grep -qF '리뷰어는 한 번씩만 부른다' \"\$RUNTIME2\""
check "런타임이 회차 수를 다시 정하지 않는다" "grep -qF '여기서 다시 정하지 않는다' \"$RUNTIME2\""
check "문서 검진도 다시 정하지 않는다"        "grep -qF '여기서 다시 정하지 않는다' \"$DOCS\""

echo "[이름은 명사구, 주장은 첫 문장 — 정본과 가독성 렌즈]"
CANON="$HERE/agent-principles.md"
READ2="$HERE/skills/reviewer-readability/SKILL.md"
check "정본이 이름 자리를 명사구로 정한다"   "grep -qF '이름을 붙이는 곳은 명사구로 쓰고 주장은 본문으로 내린다' \"\$CANON\""
check "정본이 말끝 통일을 정한다"            "grep -qF '한 표·한 목록·한 다이어그램·한 차트 안에서는 말끝을 하나로 맞춘다' \"\$CANON\""
check "정본이 넓은 말 대신 좁은 말을 시킨다" "grep -qF '넓은 말보다 좁은 말을 쓴다' \"\$CANON\""
check "정본이 결과를 구체로 적게 한다"       "grep -qF '결과는 무엇이 어떻게 되는지까지 적는다' \"\$CANON\""
check "가독성 렌즈가 이름 형태를 본다"       "grep -qF '이름 형태' \"\$READ2\""
check "가독성 렌즈가 형태 섞임을 본다"       "grep -qF '형태 섞임' \"\$READ2\""
check "가독성 렌즈 프롬프트가 고쳐 주게 한다" "grep -qF '명사구로 고쳐 주고' \"\$READ2\""

echo "[검진 개시 — 묻는 자리와 건너뛰는 자리]"
check "검진을 열기 전에 제시한다"            "grep -qF '검진을 열기 전에 사용자에게 제시한다' \"\$DOCS\""
check "계약이 바뀌면 묻는다"                  "grep -qF '계약·규칙·동작 변경' \"\$DOCS\""
check "표현만 다듬었으면 건너뛴다"            "grep -qF '골랐을 뿐이면 건너뛴다' \"\$DOCS\""
check "건너뛰면 알린다"                       "grep -qF '건너뛰었다고 한 줄 알린다' \"\$DOCS\""

echo "[한 번만 띄우므로 지킬 것 — 소유자와 여섯 렌즈 프롬프트]"
check "domain-docs가 그 규칙의 소유자다"      "grep -qF '한 번만 띄우는 리뷰어의 규율 (여기가 소유자)' \"\$DOCS\""
check "중첩 금지를 적는다"                    "grep -qF '리뷰어는 서브에이전트를 새로 열지 않는다' \"\$DOCS\""
check "이어 묻기를 적는다"                    "grep -qF '대화 턴을' \"\$DOCS\""
check "3층 오케스트레이션 예외를 적는다"      "grep -qF '3층 오케스트레이션은 이 금지의 예외다' \"\$DOCS\""
for L in "$HERE"/skills/reviewer-*/SKILL.md; do
  NAME="$(basename "$(dirname "$L")")"
  check "$NAME 프롬프트가 중첩을 금지한다"    "grep -F -- '- system:' \"$L\" | grep -qF '서브에이전트를 새로 열지 마라'"
  check "$NAME 프롬프트가 여러 각도를 시킨다"  "grep -F -- '- system:' \"$L\" | grep -qF '항목마다 따로 훑고'"
done

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
check "물을 때 질문 도구로 띄운다"           "grep -qF '질문 도구로 선택지를 띄운다' \"\$CALLER\""
# 이 문장이 README에 있든 DESIGN-NOTES에 있든 뜻은 같다 — "재리뷰가 자동으로 돌지 않는다"가
# 사용자용 문서에 적혀 있는지를 본다. 문서를 재배치해도 따라오도록 둘에서 함께 찾는다.
check "사용자용 문서도 묻는다고 적는다"      "grep -qF '다시 리뷰할지 사용자에게 묻는다' \"\$READMEF\" \"\$NOTES\""
check "🔴 반영도 다시 리뷰 대상이다"          "grep -qF '를 반영한 것도 대상이다' \"\$CALLER\""
check "무엇이 남았는지 문서에 안 적는다"      "grep -qF '문서에 적지 않는다' \"\$CALLER\""
check "문서 검진에 재검진 반복이 없다"        "grep -qF '다시 검진하지는 않는다' \"\$DOCS\""
check "런타임에 다시 리뷰 반복이 없다"        "grep -qF '다시 리뷰하지는 않는다' \"\$RUNTIME2\""

# --- 렌즈 스키마 사본이 공통 계약과 어긋나지 않는다 ---
# 여섯 렌즈의 「출력 스키마」 블록은 공통 계약을 그 렌즈의 값으로 채워 보인 사본이다. 사본이므로
# 손으로 맞추면 갈라진다 — 실제로 `evidence`의 뜻풀이에서 근거 형태 둘이 사라진 채 오래 남았다.
# 그래서 앵커를 테스트에 박지 않고 정본에서 뽑아 온다. 정본 문안이 바뀌면 이 검사가 함께 따라간다.
MA="$HERE/skills/meta-aggregate/SKILL.md"
CONTRACT_EV="$(grep -o '"evidence": "[^"]*"' "$MA" | head -1 | sed 's/^"evidence": "//; s/"$//')"
CONTRACT_EV_TAIL="${CONTRACT_EV#*— }"
CONTRACT_CONSEQ="$(grep -o '"consequence": "[^"]*"' "$MA" | head -1 | sed 's/^"consequence": "//; s/"$//')"
echo "[렌즈 스키마 사본]"
check "정본에서 evidence 뜻풀이를 뽑았다"   "[ -n \"\$CONTRACT_EV_TAIL\" ] && [ \"\$CONTRACT_EV_TAIL\" != \"\$CONTRACT_EV\" ]"
check "정본에서 consequence 뜻풀이를 뽑았다" "[ -n \"\$CONTRACT_CONSEQ\" ]"
for L in "$HERE"/skills/reviewer-*/SKILL.md; do
  n="$(basename "$(dirname "$L")")"
  check "$n: evidence 가 정본의 근거 형태를 담는다"    "grep -qF -- \"\$CONTRACT_EV_TAIL\" '$L'"
  check "$n: consequence 뜻풀이가 정본과 같다"         "grep -qF -- \"\$CONTRACT_CONSEQ\" '$L'"
  # 조건부 필드를 렌즈가 다시 규정하면 필수 여부가 두 곳에서 갈린다 — 가리키기만 해야 한다.
  check "$n: principles_applied 규칙을 되풀이하지 않는다" "! grep -qF '제품 런타임 구현에는 요구하지 않는다' '$L'"
done
check "정본이 principles_applied 규칙을 소유한다" "grep -qF '제품 런타임 구현에는 요구하지 않는다' \"\$MA\""

echo "[리뷰어에게 정본을 알리는 법 — domain-docs 한 곳만 규율을 적는다]"
# 전에 네 문서가 각자 적었다가 DESIGN-NOTES 쪽만 둘이 빠져 갈라졌다. 소유자를 하나로 두고
# 나머지는 가리키기만 하게 묶는다. 앵커는 소유자의 절 제목이라 제목을 고치면 붉어진다(FAIL-LOUD).
OWNER_DOC="$HERE/skills/domain-docs/SKILL.md"
OWNER_ANCHOR='## 리뷰어에게 정본을 알리는 법 (여기가 소유자)'
# 규율 넷을 알아보는 문구. 소유자에만 있어야 한다.
RULE_MARKS=('읽기 전용 에이전트도 Read는 갖는다' '비어 있지 않은 배열' '홈 해석이 어긋나는 환경과')
check "소유자 절이 있다" "grep -qF -- \"\$OWNER_ANCHOR\" \"\$OWNER_DOC\""
for m in "${RULE_MARKS[@]}"; do
  check "소유자가 규율을 적는다: $m" "grep -qF -- '$m' \"\$OWNER_DOC\""
done
# 가리키기만 해야 하는 문서들. 규율 문구를 다시 적으면 붉어진다.
for D in "$HERE"/skills/domain-spec-review/SKILL.md "$HERE"/skills/nested-orchestration/SKILL.md "$NOTES"; do
  # 스킬 문서는 파일 이름이 모두 SKILL.md라 부모 디렉터리로 부른다 — 안 그러면 어느 문서가 붉어졌는지
  # 알 수 없다(`NAME-ITEMS`).
  dn="$(basename "$D")"; [ "$dn" = "SKILL.md" ] && dn="$(basename "$(dirname "$D")")"
  check "$dn 이 소유자를 가리킨다"        "grep -qF '리뷰어에게 정본을 알리는 법' '$D'"
  for m in "${RULE_MARKS[@]}"; do
    check "$dn 이 규율을 베끼지 않는다: $m" "! grep -qF -- '$m' '$D'"
  done
done

echo "[대체된 설계 문서에 superseded 표시]"
OLDSPEC="$HERE/docs/superpowers/specs/2026-08-16-review-layer-redesign-design.md"
OLDPLAN="$HERE/docs/superpowers/plans/2026-08-16-review-layer-redesign.md"
check "옛 spec 에 superseded 표시가 있다"   "grep -qF 'superseded' \"\$OLDSPEC\""
check "옛 plan 에 superseded 표시가 있다"   "grep -qF 'superseded' \"\$OLDPLAN\""

# --- recall: 오답노트를 꺼내 쓰는 진입로가 둘이라는 것을 정본이 말한다 ---
# 이 절의 문구를 지키는 계약이 하나도 없었다. 문장을 다듬다 되돌려도 어떤 신호도 안 뜨는
# 상태였고, 이 레포는 정본 산문을 다듬다 계약 테스트를 깬 전례가 있다.
CANON="$HERE/agent-principles.md"
check "recall: 시작할 때 진입로"   "grep -qF -- '지금 하려는 작업에 걸리는 지시사항 줄' \"\$CANON\""
check "recall: 증상 진입로"        "grep -qF -- '이미 증상이 난 뒤에는' \"\$CANON\""
check "recall: 두 계층을 다 본다"  "grep -qF -- 'PC solved와 프로젝트 solved 둘 다' \"\$CANON\""
check "recall: 본문 수정은 묻는다" "grep -qF -- '고치거나 지우기 전에 사용자에게 묻는다' \"\$CANON\""
check "recall: 색인도 함께"        "grep -qF -- '색인 줄도 같은 걸음에서 함께' \"\$CANON\""
check "recall: 고아 줄은 지운다"   "grep -qF -- '가리키는 본문이 없으면' \"\$CANON\""
check "recall: 고아 본문은 채운다" "grep -qF -- '색인 줄이 없으면' \"\$CANON\""

echo "----"; echo "PASS=$pass FAIL=$fail"; [ "$fail" -eq 0 ]
