#!/usr/bin/env bash
# 문서의 렌즈 열거가 진실과 어긋나지 않는지 검증. 계약: FAIL=0 (매직넘버 금지 — 개수는 테스트가 센다).
#
# 아래 불변식을 단언한다. 개수를 박지 않고 두 집합의 일치를 본다.
#   집계 태깅   — aggregating-lenses가 source 값으로 적은 렌즈 == 같은 디렉터리 집합
# 권위 있는 출처는 디렉터리이고 산문의 열거는 그 캐시다.
#
# 앵커는 산문 문장이 아니라 안정된 열쇠다. 규칙이 있는지는 조항 ID(`ASK-OPTIONS` 같은 것)와 절 제목으로,
# 소유는 그 절 안의 소유 선언으로, 포인터는 소유자 이름과 절 이름이 한 줄에 함께 있는지로 본다.
# 함수는 scripts/_doc_keys.sh 에 있다. 문장 끝이나 낱말을 고쳐도 열쇠가 그대로면 통과하고, ID·제목·
# 포인터가 사라지거나 이름이 바뀌면 실패한다. 복제 금지 검사는 되도록 구조(사본 쪽에 그 절 제목이나
# 소유 선언이 없다)로 보고, 구조로 못 적는 것만 가장 짧은 고유 조각을 남겼다. 그런 곳에는 그 자리에
# '짧은 조각' 이라고 적어 두었다. 렌즈 프롬프트처럼 제목이 없는 한 줄 페이로드도 짧은 조각으로 본다.
set -euo pipefail
HERE="$(cd "$(dirname "$0")/.." && pwd)"
. "$HERE/scripts/_doc_keys.sh"   # doc_sec·has_sec·sec_has·sec_has_id·owns_sec·has_clause·points_to
# 픽스처는 모두 이 뿌리 아래에 만들고 끝나면 통째로 지운다. mktemp 가 TMPDIR 을 따르므로 아래의
# mktemp 호출과 이 검사가 부르는 스크립트의 임시 파일이 모두 여기로 온다.
TEST_TMP="$(mktemp -d)"; trap 'rm -rf "$TEST_TMP"' EXIT; export TMPDIR="$TEST_TMP"
README="$HERE/README.md"
CALLER="$HERE/skills/review-specs/SKILL.md"
AGG="$HERE/skills/aggregating-lenses/SKILL.md"
DISP="$HERE/skills/dispatching-lenses/SKILL.md"
pass=0; fail=0
check() { if eval "$2"; then echo "  PASS: $1"; pass=$((pass+1)); else echo "  FAIL: $1"; fail=$((fail+1)); fi; }

# 진실 — 실제 렌즈 디렉터리에서 짧은 이름을 도출한다.
ALL="$(for d in "$HERE"/skills/lens-*/; do [ -d "$d" ] || continue; basename "$d" | sed 's/^lens-//'; done | sort)"

# 캐시 — aggregating-lenses 리뷰 산출물 계약의 렌즈 이름 열거. 출력 스키마의 `source`는 이 값을
# 그대로 옮기는 자리라 열거를 두지 않는다. 이름 열거가 한 문서에 하나만 남게 여기서 뽑는다.
AGG_LINE="$(grep -F '"lens": "lens-' "$AGG" | head -1 || true)"
AGGSET="$(printf '%s' "$AGG_LINE" | sed 's/.*"lens"[[:space:]]*:[[:space:]]*"\([^"]*\)".*/\1/' | tr '|' '\n' | sed 's/^ *//; s/ *$//; s/^lens-//' | grep -v '^$' | sort || true)"

# 캐시 — aggregating-lenses가 「공통 계약의 예외」로 적은 렌즈 이름 열거. 손으로 목록을 베끼지
# 않고 aggregating-lenses 의 그 절에서 뽑는다. 그 절이 없어지거나 이름이 바뀌면 EXC_LENSES가 비어 아래 단언이
# 예외 없이 다섯 렌즈 전부에게 강도 그대로의 대조를 요구한다.
EXC_LENSES="$(awk '/^## 공통 계약의 예외/{f=1; next} /^## /{f=0} f' "$AGG" | grep -oE '`lens-[a-z-]+`' | tr -d '`' | sort -u || true)"
is_exc() { printf '%s\n' "$EXC_LENSES" | grep -qxF "$1"; }

echo "[앵커가 실제로 잡히는가 — 못 잡으면 아래 단언이 무의미해진다]"
check "렌즈 디렉터리가 하나 이상 있다"          "[ -n \"\$ALL\" ]"

echo "[집계 태깅 == 실제 디렉터리]"
# aggregating-lenses의 출력 스키마가 이슈의 출처를 렌즈 이름으로 태깅한다. 그 열거도 렌즈가 늘면 낡는다.
check "aggregating-lenses lens 줄을 찾았다"          "[ -n \"\$AGG_LINE\" ]"
check "aggregating-lenses 에 source 열거가 없다"     "! grep -qE '\"source\"[[:space:]]*:[[:space:]]*\"[a-z-]+\\|' \"\$AGG\""
check "aggregating-lenses가 렌즈 전부를 태깅한다"    "[ \"\$AGGSET\" = \"\$ALL\" ]"
if [ "$AGGSET" != "$ALL" ]; then
  echo "    디렉터리      : $(printf '%s' "$ALL" | tr '\n' ' ')"
  echo "    aggregating-lenses: $(printf '%s' "$AGGSET" | tr '\n' ' ')"
fi


echo "[산출물 계약 — aggregating-lenses가 소유한다]"
check "계약이 consequence 를 필수로 적는다"     "grep -qF 'consequence' \"\$AGG\""
check "계약이 evidence 를 필수로 적는다"        "grep -qF 'evidence' \"\$AGG\""
check "계약이 read 필드를 정의한다"             "grep -qF '\"read\"' \"\$AGG\""
check "계약 절이 소유를 밝히고 빈 issues 를 다룬다" "owns_sec \"\$AGG\" '리뷰 산출물 계약' && sec_has_id \"\$AGG\" '리뷰 산출물 계약' issues"
check "계약에 등급 라벨이 없다"                 "! grep -qF 'severity' \"\$AGG\""
check "처분 절이 spec 리뷰를 따로 다룬다"       "sec_has_id \"\$AGG\" '처분' review-specs"

check "aggregating-lenses 에서 공통 계약 예외 렌즈를 뽑았다" "[ -n \"\$EXC_LENSES\" ]"

echo "[렌즈 계약 — 등급 없음, 근거 필수]"
for d in "$HERE"/skills/lens-*/; do
  n="$(basename "$d")"; f="$d/SKILL.md"
  check "$n 에 등급 라벨이 없다"          "! grep -qF 'severity' \"$f\""
  if is_exc "$n"; then
    # 예외 렌즈가 계약에서 빼는 칸은 aggregating-lenses 의 예외 항목이 "빠지는 칸: `x`·`y`" 로 적는다. 목록을 여기
    # 손으로 베끼지 않고 거기서 뽑아 그 렌즈의 출력 스키마 줄에 없는지 본다. 예외마다 빠지는 칸이
    # 다르므로 "consequence 가 없다" 하나로 뭉뚱그리면 그 칸을 담는 예외에서 거짓이 된다.
    EXC_BULLET="$(awk '/^## 공통 계약의 예외/{f=1; next} /^## /{f=0} f' "$AGG" | grep -F "\`$n\`" | grep -oE '빠지는 칸: .*$' || true)"
    check "$n 예외가 빠지는 칸을 적는다" "[ -n \"\$EXC_BULLET\" ]"
    SCHEMA_LINE="$(grep -F '"lens": "' "$f" | head -1 || true)"
    EXC_BAD=""
    while IFS= read -r k; do
      [ -n "$k" ] || continue
      if printf '%s' "$SCHEMA_LINE" | grep -qF "\"$k\""; then EXC_BAD="$EXC_BAD $k"; fi
    done <<EOF
$(printf '%s' "$EXC_BULLET" | grep -oE '`[a-z_]+`' | tr -d '`')
EOF
    check "$n 스키마에 빠지는 칸이 없다" "[ -z \"\$EXC_BAD\" ]"
  else
    check "$n 이 consequence 를 요구한다"   "grep -qF 'consequence' \"$f\""
  fi
  check "$n 이 read 를 요구한다"          "grep -qF '\"read\"' \"$f\""
  # 짧은 조각 — 프롬프트 한 줄은 제목이 없는 페이로드라 열쇠를 둘 곳이 없다.
  check "$n 프롬프트가 빈손을 정상으로 적는다" "grep -m1 '^- system:' \"$f\" | grep -qF '빈 목록'"
  check "$n 에 읽기 범위 절이 있다"       "has_sec \"$f\" '읽기 범위'"
done

echo "[spec 리뷰 — 처분은 호출자가 정한다]"
# 처분 절이 🔴 진입 기준을 조항 ID 로 걸고, 🔴 을 예외로 두는 기본값(고치기)을 적는다.
check "🔴 진입 기준이 처분 절에 조항 ID 로 있다" "sec_has_id \"\$CALLER\" '처분' REVERSIBLE"
check "처분 절이 🔴 를 예외로 다룬다"          "sec_has_id \"\$CALLER\" '처분' '🔴'"
check "작업 순서 절이 마커 순서를 다룬다"      "sec_has \"\$CALLER\" '작업 순서와 다시 리뷰' '마커'"

RUNTIME="$HERE/skills/review-llm-calls/SKILL.md"
echo "[런타임 — 등급이 아니라 type 으로 행동을 정한다]"
check "런타임 파일을 찾았다"                "[ -f \"\$RUNTIME\" ]"
check "조립 절이 type 값으로 accept·escalate 를 가른다" "sec_has_id \"\$RUNTIME\" '조립' type && sec_has_id \"\$RUNTIME\" '조립' accept && sec_has_id \"\$RUNTIME\" '조립' escalate"

PTU="$HERE/hooks/spec_review_posttooluse.sh"
STOPH="$HERE/hooks/spec_review_stop.sh"
SPECM="$HERE/hooks/_spec_marker.sh"
echo "[훅 안내문 — 마커를 개선보다 먼저, 문안은 한 곳에]"
check "공유 안내문이 마커 선기록을 지시한다"     "grep -qF '마커를 먼저 남기고' \"\$SPECM\""
check "PostToolUse 훅이 공유 안내문을 쓴다"       "grep -qF 'SPEC_REVIEW_INSTRUCTION' \"\$PTU\""
check "Stop 훅이 공유 안내문을 쓴다"              "grep -qF 'SPEC_REVIEW_INSTRUCTION' \"\$STOPH\""
check "훅이 안내문을 따로 베끼지 않는다"          "! grep -qF '마커를 먼저 남기고' \"\$PTU\" \"\$STOPH\""

echo "[리뷰 절차 — 렌즈를 한 번씩 실행하고 결과를 한데 모은다]"
DOCS="$HERE/skills/review-docs/SKILL.md"
RUNTIME2="$HERE/skills/review-llm-calls/SKILL.md"
READMEF="$HERE/README.md"
check "spec 리뷰에 회차 규칙 절이 없다"        "! has_sec \"\$CALLER\" '한 번만 실행하는 렌즈의 규율'"
check "spec 리뷰가 회차 규칙 소유자를 가리킨다" "points_to \"\$CALLER\" 'dispatching-lenses' '「한 번만 실행하는 렌즈의 규율」'"
check "렌즈별 결과를 한데 모으는 집계 절이 남는다" "sec_has_id \"\$CALLER\" '3) 메타 집계' aggregating-lenses"
check "소유자가 회차 규칙을 소유한다"          "owns_sec \"\$DISP\" '한 번만 실행하는 렌즈의 규율'"
check "런타임 조립 절이 회차 규칙을 가리키고 서브에이전트 규율 밖이라고 적는다" "points_to \"\$RUNTIME2\" 'dispatching-lenses' '「한 번만 실행하는 렌즈의 규율」' && sec_has \"\$RUNTIME2\" '조립' '서브에이전트 규율'"
check "실행하는 방법 절이 회차 규칙 절로 넘긴다" "sec_has \"\$DISP\" '실행하는 방법' '「한 번만 실행하는 렌즈의 규율」'"

echo "[이름은 명사구, 주장은 첫 문장 — 에이전트원칙과 가독성 렌즈]"
CANON="$HERE/agent-principles.md"
READ2="$HERE/skills/lens-readability/SKILL.md"
# 문서 타입과 수명과 수정 규율은 에이전트원칙이 소유한다. 문서를 만지는 모든 세션에 걸리는 규칙이라
# 스킬로 두면 여는 판단을 매번 해야 했고, 안 열었을 때의 누락이 조용했다. 타입마다 무엇이
# 강제하는지는 프로젝트마다 다르므로 그 칸만 저장소 CLAUDE.md 가 갖는다.
TYPE_TBL="$HERE/CLAUDE.md"
# 상세는 domain-korean 이 소유하고 에이전트원칙은 조항만 담는다. 양쪽을 함께 붙든다.
WK="$HERE/skills/lens-readability/domain-korean.md"
check "상세 스킬이 있다"                     "[ -f \"$WK\" ]"
# 에이전트원칙이 지시를 갖고 스킬이 같은 ID 로 근거를 단다. 예전에는 같은 문장이 양쪽에 있는지를 봤는데,
# 그 검사가 우리가 없애려던 중복을 오히려 요구했다. 이제 ID 로 잇고, 지시 문장이 스킬에 그대로
# 있으면 실패한다.
KO_IDS="$(awk '/^### `PLAIN-KO`/{f=1} f&&/^## /{exit} f' "$CANON" | grep -oE '^- \*\*`[A-Z-]+`\*\*' | grep -oE '[A-Z][A-Z-]+')"
check "에이전트원칙에서 한국어 조항 ID 를 뽑았다"    "[ -n \"\$KO_IDS\" ]"
KO_MISS=""
KO_DUP=""
for kid in $KO_IDS; do
  grep -qF "\`$kid\`" "$WK" || KO_MISS="$KO_MISS $kid"
  ko_sent="$(grep -F "**\`$kid\`**" "$CANON" | sed 's/^.*\*\* — //')"
  if [ -n "$ko_sent" ]; then
    if grep -qF "$ko_sent" "$WK"; then KO_DUP="$KO_DUP $kid"; fi
  fi
done
[ -n "$KO_MISS" ] && printf '    스킬에 근거가 없는 조항:%s\n' "$KO_MISS"
[ -n "$KO_DUP" ] && printf '    스킬이 지시를 그대로 옮겨 적은 조항:%s\n' "$KO_DUP"
check "스킬이 모든 조항 ID 로 근거를 단다"   "[ -z \"\$KO_MISS\" ]"
check "스킬이 지시 문장을 다시 적지 않는다"  "[ -z \"\$KO_DUP\" ]"
check "에이전트원칙이 그 상세를 가리킨다"            "grep -qF 'domain-korean' \"$CANON\""

# 한국어 절 밖의 조항도 같은 방식으로 붙든다. 에이전트원칙이 지시를 소유하고 참고서가 같은 ID 로
# 근거를 단다. 잇는 장치가 한국어 절에만 있으면 나머지 조항은 근거 없이 늘어날 수 있다.
# ID 목록은 에이전트원칙에서 뽑되 한국어 절의 것만 뺀다. 절을 추가하거나 이름을 바꿔도 따라온다.
DC_WK="$HERE/skills/lens-fit/domain-discipline.md"
check "원칙 참고서가 있다"                   "[ -f \"$DC_WK\" ]"
ALL_IDS="$(grep -oE '^- \*\*`[A-Z][A-Z0-9-]*`' "$CANON" | grep -oE '[A-Z][A-Z0-9-]+' | sort -u)"
DC_IDS="$(printf '%s
' "$ALL_IDS" | grep -vxF "$KO_IDS" || true)"
check "한국어 절 밖 조항 ID 를 뽑았다"        "[ -n \"\$DC_IDS\" ]"
DC_MISS=""
DC_DUP=""
for did in $DC_IDS; do
  grep -qE "^### \`$did\`" "$DC_WK" || DC_MISS="$DC_MISS $did"
  dc_sent="$(grep -F "**\`$did\`" "$CANON" | sed 's/^.*\*\* — //')"
  if [ -n "$dc_sent" ]; then
    if grep -qF "$dc_sent" "$DC_WK"; then DC_DUP="$DC_DUP $did"; fi
  fi
done
[ -n "$DC_MISS" ] && printf '    참고서에 근거가 없는 조항:%s
' "$DC_MISS"
[ -n "$DC_DUP" ] && printf '    참고서가 지시를 그대로 옮겨 적은 조항:%s
' "$DC_DUP"
check "참고서가 모든 조항 ID 로 근거를 단다"  "[ -z \"\$DC_MISS\" ]"
check "참고서가 지시 문장을 다시 적지 않는다" "[ -z \"\$DC_DUP\" ]"
check "에이전트원칙이 그 참고서를 가리킨다"   "grep -qF 'domain-discipline' \"$CANON\""
check "에이전트원칙에 대상 이름 조항이 있다"   "has_clause \"\$CANON\" SPECIFIC-NAME"
check "가독성 렌즈 관찰 목록에 이름 형태 축이 있다" "sec_has \"\$READ2\" '관찰 목록' '**이름 형태**'"
check "가독성 렌즈 관찰 목록에 형태 섞임 축이 있다" "sec_has \"\$READ2\" '관찰 목록' '**형태 섞임**'"
# 짧은 조각 — 프롬프트 한 줄은 제목이 없는 페이로드다.
check "가독성 렌즈 프롬프트가 명사구로 고쳐 주게 한다" "grep -m1 '^- system:' \"\$READ2\" | grep -qF '명사구'"
check "가독성 렌즈가 직접인용을 손대지 않는 요소로 둔다" "sec_has \"\$READ2\" '손대지 않는 요소' '**직접인용**'"
check "그 가드가 프롬프트에도 실린다"       "grep -m1 '^- system:' \"\$READ2\" | grep -qF '직접인용'"

echo "[검진 개시 — 묻는 자리와 건너뛰는 자리]"
# 「언제 여는지」 절의 불릿 라벨 셋이 묻는 종류·생략하는 종류·생략 통지를 가른다.
check "검진을 여는 때를 정하는 절이 있다"    "has_sec \"\$DOCS\" '언제 여는지'"
check "그 절이 묻기·생략·통지 라벨을 갖는다" "sec_has \"\$DOCS\" '언제 여는지' '**계약·규칙·동작 변경**' && sec_has \"\$DOCS\" '언제 여는지' '**표현 다듬기**' && sec_has \"\$DOCS\" '언제 여는지' '**생략한 차수의 통지**'"

echo "[한 번만 실행하므로 지킬 것 — 소유자와 여섯 렌즈 프롬프트]"
# 소유 선언은 「소유 표」 블록이 정한 꼴을 쓰고, 그 절이 소유 표에서 빠지면 거기서도 함께 실패한다.
check "dispatching-lenses가 그 규칙의 소유자다" "owns_sec \"\$DISP\" '한 번만 실행하는 렌즈의 규율'"
# 중첩 금지와 이어 묻기(notes)와 3층 예외(nested-orchestration)를 그 절이 함께 갖는다.
check "중첩 금지를 적는다"                    "sec_has \"\$DISP\" '한 번만 실행하는 렌즈의 규율' '서브에이전트'"
check "이어 묻기를 notes 로 적는다"           "sec_has_id \"\$DISP\" '한 번만 실행하는 렌즈의 규율' notes"
check "3층 오케스트레이션 예외를 적는다"      "sec_has_id \"\$DISP\" '한 번만 실행하는 렌즈의 규율' nested-orchestration"
for L in "$HERE"/skills/lens-*/SKILL.md; do
  NAME="$(basename "$(dirname "$L")")"
  # 짧은 조각 — 프롬프트 한 줄은 제목이 없는 페이로드다.
  check "$NAME 프롬프트가 중첩을 금지한다"    "grep -F -- '- system:' \"$L\" | grep -qF '서브에이전트를 새로'"
  check "$NAME 프롬프트가 여러 관점을 시킨다"  "grep -F -- '- system:' \"$L\" | grep -qF '항목마다'"
done

echo "[렌즈끼리 볼 것을 나눠 주지 않는다 — 소유자 하나, 호출자는 가리킨다]"
# 디스패치 규율이라 dispatching-lenses 가 규칙과 근거를 「실행하는 방법」 절에서 진다. 전에는 세 파일
# 모두에 같은 문구를 요구해 검사가 베끼기를 강제했다. 호출자에는 소유자를 가리키는 포인터와 근거
# 사본이 없는지만 본다.
# 사본 검사는 구조로 못 적는다 — 호출자가 규칙 문장을 옮겨 적어도 제목이나 소유 선언은 생기지 않는다.
# 그래서 짧은 조각 둘을 남긴다. 규칙 쪽은 포인터 문장('나눠 주지 않는 규칙')과 겹치지 않는 종결형이다.
SPLIT_RULE='나눠 주지 않는다'
SPLIT_WHY='빼 주는 것이'
check "소유자 절이 그 규칙을 소유한다"        "owns_sec \"\$DISP\" '실행하는 방법' && sec_has \"\$DISP\" '실행하는 방법' \"\$SPLIT_RULE\" && sec_has \"\$DISP\" '실행하는 방법' \"\$SPLIT_WHY\""
for f in "$CALLER" "$RUNTIME2"; do
  fn="$(basename "$(dirname "$f")")"
  check "$fn 이 소유자를 가리킨다"          "points_to '$f' '\`dispatching-lenses\`' '「실행하는 방법」'"
  check "$fn 에 규칙 절과 근거 사본이 없다" "! has_sec '$f' '실행하는 방법' && ! grep -qF -- \"\$SPLIT_RULE\" '$f' && ! grep -qF -- \"\$SPLIT_WHY\" '$f'"
done

echo "[dispatching-lenses — 소유자가 하나다]"
# 렌즈 운용 규율이 문서 검진 절차와 나뉘어 있던 동안 소유자가 둘이었다. 규율은 이 스킬이 지고
# review-docs 는 검진 절차만 진다. 절 제목과 실행하는 방법 문장이 양쪽에 함께 있으면 다시 갈린다.
check "review-docs 에 렌즈 운용 절 제목이 없다"        "! grep -qE '^## (렌즈에게 에이전트원칙을 알리는 법|판단 앞에 기계 검사를 둔다|한 번만 실행하는 렌즈의 규율)$' \"\$DOCS\""
# 실행하는 방법의 내용은 결과를 aggregating-lenses 「하는 일」로 모으는 것이다. review-docs 가 그 절을
# 다시 가리키면 방법을 베낀 것이고, 소유자 이름만 대면 넘긴 것이다.
check "review-docs 가 실행하는 방법을 소유자로 넘긴다"    "! has_sec \"\$DOCS\" '실행하는 방법' && ! grep -qF '「하는 일」' \"\$DOCS\" && grep -qF -- '\`dispatching-lenses\`' \"\$DOCS\""
check "소유자가 실행하는 방법을 적는다"             "sec_has \"\$DISP\" '실행하는 방법' 'source' && points_to \"\$DISP\" '\`aggregating-lenses\`' '「하는 일」'"
DISP_MISS=""
while IFS= read -r n; do
  [ -n "$n" ] || continue
  if [ ! -d "$HERE/skills/$n" ]; then DISP_MISS="$DISP_MISS $n"; fi
done <<EOF
$(awk '/^## 예외 목록/{f=1;next} /^## /{f=0} f' "$DISP" | grep -oE '`lens-[a-z-]+`' | tr -d '`' | sort -u)
EOF
check "예외 목록의 렌즈가 모두 실재한다"          "[ -z \"\$DISP_MISS\" ]"

echo "[따르는 문서 — 이름과 문턱 사본]"
# 렌즈 스키마의 lens 값은 디렉터리 이름과 같은 한 문자열이다. 짧은 이름이 남으면 기록 파일 이름과
# findings 의 lens 칸이 갈린다.
LENS_BAD=""
while IFS= read -r d; do
  [ -n "$d" ] || continue
  ln="$(basename "$d")"
  if ! grep -qF "\"lens\": \"$ln\"" "$d/SKILL.md"; then LENS_BAD="$LENS_BAD $ln"; fi
done <<EOF
$(ls -d "$HERE"/skills/lens-*)
EOF
check "렌즈 스키마의 lens 값이 디렉터리 이름과 같다" "[ -z \"\$LENS_BAD\" ]"
# 짧은 조각 — 옛 문턱 문장이 되살아나는 것을 막는 사본 검사다. 렌즈 파일에는 원래 그 절이 없어 구조로 못 적는다.
check "렌즈 파일에 문턱 첫 문장이 안 남았다"          "! grep -qF '넷을 진다' \"\$HERE\"/skills/lens-*/SKILL.md"

echo "[기록 — 자리와 담을 것]"
# 기록에 무엇을 담고 빼는지는 review-docs 「기록」과 review-specs 「리뷰 기록」 절이 정한다. 절 안의
# 문장마다 붙들던 단언은 절과 그 안의 식별자로 합쳤다.
check "spec 리뷰가 리뷰 기록 절에서 이름 규칙 소유자를 가리킨다" "has_sec \"\$CALLER\" '리뷰 기록' && points_to \"\$CALLER\" '\`review-docs\`' '「기록 파일 이름 규칙」'"
check "문서 검진 기록의 자리를 적는다"       "grep -qF 'docs/superpowers/reviews/' \"\$DOCS\""
check "문서 검진 기록 절이 종류 check 를 적는다" "sec_has_id \"\$DOCS\" '기록' check"
# 이름 규칙은 review-docs 가 소유한다. 호출자에게 같은 문구를 요구하면 검사가 복제를 강제한다.
check "기록 이름 규칙 절이 차수 꼴을 적는다"   "sec_has \"\$DOCS\" '기록 파일 이름 규칙' '-review-2.md'"
check "에이전트원칙은 그 규칙을 더 안 적는다"        "! grep -qF '<렌즈 스킬 이름>-<실행 횟수>.json' \"\$CANON\""
check "에이전트원칙이 기록 이름의 소유자를 가리킨다" "sec_has_id \"\$CANON\" '문서 타입과 수명' review-docs && sec_has \"\$CANON\" '문서 타입과 수명' '소유'"
check "원본을 같은 이름 폴더에 둔다"          "sec_has \"\$CALLER\" '리뷰 기록' '**같은 이름의 폴더**'"
check "런타임이 기록 제외 이유를 조항 ID 로 적는다" "sec_has_id \"\$RUNTIME2\" '조립' SECRETS"

echo "[합치기와 다시 리뷰]"
check "합치기 절이 있다"                      "has_sec \"\$CALLER\" '합치기'"
check "기능적 변화면 다시 리뷰한다고 적는다"  "sec_has \"\$CALLER\" '작업 순서와 다시 리뷰' '**기능적 변화**'"
check "다시 리뷰를 물을 때 ASK-OPTIONS 를 따른다" "sec_has_id \"\$CALLER\" '작업 순서와 다시 리뷰' ASK-OPTIONS"
check "🔴 반영도 다시 리뷰 절이 다룬다"      "sec_has_id \"\$CALLER\" '작업 순서와 다시 리뷰' '🔴'"
check "문서 검진이 재검진 금지를 소유자로 넘긴다" "points_to \"\$DOCS\" '\`dispatching-lenses\`' '「한 번만 실행하는 렌즈의 규율」'"
check "런타임이 재리뷰 금지를 소유자로 넘긴다" "points_to \"\$RUNTIME2\" '\`dispatching-lenses\`' '「한 번만 실행하는 렌즈의 규율」'"
check "재검진 금지는 dispatching-lenses 가 소유하고 spec 리뷰의 반복 절을 가리킨다" "points_to \"\$DISP\" '\`review-specs\`' '「작업 순서와 다시 리뷰」'"

# --- 렌즈 스키마 사본이 공통 계약과 어긋나지 않는다 ---
# 여섯 렌즈의 「출력 스키마」 블록은 공통 계약을 그 렌즈의 값으로 채워 보인 사본이다. 사본이므로
# 손으로 맞추면 갈라진다 — 실제로 `evidence`의 뜻풀이에서 근거 형태 둘이 사라진 채 오래 남았다.
# 그래서 앵커를 테스트에 박지 않고 aggregating-lenses 에서 뽑아 온다. 그 문안이 바뀌면 이 검사가 함께 따라간다.
MA="$HERE/skills/aggregating-lenses/SKILL.md"
CONTRACT_EV="$(grep -o '"evidence": "[^"]*"' "$MA" | head -1 | sed 's/^"evidence": "//; s/"$//')"
CONTRACT_CONSEQ="$(grep -o '"consequence": "[^"]*"' "$MA" | head -1 | sed 's/^"consequence": "//; s/"$//')"
echo "[렌즈 스키마 사본]"
check "aggregating-lenses 에서 evidence 뜻풀이를 뽑았다"   "[ -n \"\$CONTRACT_EV\" ]"
check "aggregating-lenses 에서 consequence 뜻풀이를 뽑았다" "[ -n \"\$CONTRACT_CONSEQ\" ]"
for L in "$HERE"/skills/lens-*/SKILL.md; do
  n="$(basename "$(dirname "$L")")"
  if is_exc "$n"; then
    check "$n: 공통 계약 예외라 스키마 사본 대조에서 빠진다" "grep -qF '$n' \"\$AGG\""
  else
    # 계약이 "렌즈 파일에는 자기 type 폐쇄 집합만 정의하고 나머지는 여기를 참조한다"고 정하므로
    # 뜻풀이를 담고 있으면 실패한다. 전에는 반대로 담고 있어야 통과해서 검사가 베끼기를 강제했다.
    # 「레퍼런스 프롬프트」 절은 예외다 — 그 문장은 에이전트원칙이 안 실리는 서브에이전트에 그대로 실어
    # 보내는 페이로드라 복제가 아니다. 그래서 그 절을 떼어 낸 나머지에서만 본다.
    NOPROMPT="$(awk '/^## 레퍼런스 프롬프트/{f=1;next} f&&/^## /{f=0} !f' "$L")"
    check "$n: consequence 뜻풀이를 베끼지 않는다" "! printf '%s' \"\$NOPROMPT\" | grep -qF -- \"\$CONTRACT_CONSEQ\""
    check "$n: evidence 뜻풀이를 베끼지 않는다"    "! printf '%s' \"\$NOPROMPT\" | grep -qF -- \"\$CONTRACT_EV\""
    check "$n: 출력 스키마가 계약 소유자를 가리킨다" "points_to '$L' '\`aggregating-lenses\`' '리뷰 산출물 계약'"
    if grep -qF -- '"counterpart_file"' "$L"; then
      check "$n: file 칸을 이름으로 적는다"      "grep -qF -- '\"file\":' '$L'"
      check "$n: principle 칸을 이름으로 적는다" "grep -qF -- '\"principle\":' '$L'"
    fi
  fi
  # 조건부 필드를 렌즈가 다시 규정하면 필수 여부가 두 곳에서 갈린다 — 가리키기만 해야 한다.
  # 짧은 조각 — 규칙 문장을 옮겨 적어도 렌즈 파일에 제목이나 소유 선언이 생기지 않아 구조로 못 적는다.
  check "$n: principles_applied 규칙을 되풀이하지 않는다" "! grep -qF '런타임 구현에' '$L'"
done
# 렌즈가 계약에 없는 칸을 더할 수 있고, 그 목록은 aggregating-lenses 의 「렌즈가 추가하는 칸」 절이 소유한다.
# 목록을 여기 손으로 적지 않고 그 절에서 뽑아, 렌즈가 쓰는 덧붙임 칸이 다 올라 있는지 본다.
EXTRA_LISTED="$(awk '/^## 렌즈가 추가하는 칸/{f=1;next} f&&/^## /{exit} f' "$MA" | grep -oE '`[a-z_]+`' | tr -d '`' | sort -u)"
check "aggregating-lenses 에서 덧붙이는 칸 목록을 뽑았다" "[ -n \"\$EXTRA_LISTED\" ]"
# 뽑아 놓고 대조를 안 하면 목록이 낡아도 초록이다. 실제로 그랬고 lens-fit 의 doc_type 이 빠져
# 있었다. 렌즈 파일이 자기 덧붙임 칸이라 밝힌 이름을 뽑아 위 목록에 다 있는지 본다.
EXTRA_BAD=""
for xf in "$HERE"/skills/lens-*/SKILL.md; do
  xn="$(basename "$(dirname "$xf")")"
  while IFS= read -r xk; do
    [ -n "$xk" ] || continue
    printf '%s
' "$EXTRA_LISTED" | grep -qx -- "$xk" || EXTRA_BAD="$EXTRA_BAD [$xn:$xk]"
  done <<INNER
$(LC_ALL=C.UTF-8 grep -oE '`[a-z_]+`[^`]{0,14}이 렌즈가 추가하는 칸' "$xf" | grep -oE '^`[a-z_]+`' | tr -d '`' | sort -u)
INNER
done
[ -n "$EXTRA_BAD" ] && printf '    aggregating-lenses 목록에 안 오른 덧붙임 칸:%s
' "$EXTRA_BAD"
check "렌즈가 추가하는 칸이 모두 aggregating-lenses 목록에 있다" "[ -z \"\$EXTRA_BAD\" ]"
check "aggregating-lenses 가 principles_applied 규칙을 소유한다" "owns_sec \"\$MA\" '리뷰 산출물 계약' && sec_has_id \"\$MA\" '리뷰 산출물 계약' principles_applied"
check "aggregating-lenses 가 file 칸을 필수로 적는다"      "grep -qF -- '\"file\":' \"\$MA\""
check "aggregating-lenses 가 principle 칸을 필수로 적는다" "grep -qF -- '\"principle\":' \"\$MA\""

echo "[렌즈에게 에이전트원칙을 알리는 법 — dispatching-lenses 한 곳만 규율을 적는다]"
# 전에 여러 문서가 각자 적었다가 하나에서 둘이 빠져 갈라졌다. 소유자를 하나로 두고
# 나머지는 가리키기만 하게 묶는다. 앵커는 소유자의 절 제목이라 제목을 고치면 실패한다.
OWNER_DOC="$HERE/skills/dispatching-lenses/SKILL.md"
OWNER_SEC='렌즈에게 에이전트원칙을 알리는 법'
# 규율 넷을 알아보는 짧은 조각. 소유자에만 있어야 한다. 사본 쪽에 제목이나 소유 선언 없이 불릿만
# 옮겨 적으면 구조로는 안 잡히므로 조각을 남긴다.
RULE_MARKS=('Read는 보유한다' '비어 있지 않은 배열' '홈 해석이')
check "소유자 절이 소유를 밝히고 principles_applied 를 요구한다" "owns_sec \"\$OWNER_DOC\" \"\$OWNER_SEC\" && sec_has_id \"\$OWNER_DOC\" \"\$OWNER_SEC\" principles_applied"
check "소유자가 규율 조각을 모두 적는다" "sec_has \"\$OWNER_DOC\" \"\$OWNER_SEC\" '${RULE_MARKS[0]}' && sec_has \"\$OWNER_DOC\" \"\$OWNER_SEC\" '${RULE_MARKS[1]}' && sec_has \"\$OWNER_DOC\" \"\$OWNER_SEC\" '${RULE_MARKS[2]}'"
# 가리키기만 해야 하는 문서들. 그 절을 두거나 규율 조각을 다시 적으면 실패한다.
for D in "$HERE"/skills/review-specs/SKILL.md "$HERE"/skills/nested-orchestration/SKILL.md "$HERE"/skills/review-docs/SKILL.md; do
  # 스킬 문서는 파일 이름이 모두 SKILL.md라 부모 디렉터리로 부른다 — 안 그러면 어느 문서가 실패했는지
  # 알 수 없다(`NAME-ITEMS`).
  dn="$(basename "$D")"; [ "$dn" = "SKILL.md" ] && dn="$(basename "$(dirname "$D")")"
  check "$dn 이 소유자를 가리킨다"        "points_to '$D' 'dispatching-lenses' \"\$OWNER_SEC\""
  check "$dn 에 그 절이 없다"             "! has_sec '$D' \"\$OWNER_SEC\""
  check "$dn 이 규율 조각을 베끼지 않는다" "! grep -qF -- '${RULE_MARKS[0]}' '$D' && ! grep -qF -- '${RULE_MARKS[1]}' '$D' && ! grep -qF -- '${RULE_MARKS[2]}' '$D'"
done

echo "[소유 표] 소유는 하나뿐이고 나머지는 가리킨다"
# 소유 선언을 데이터 파일에 적지 않고 문서에서 도출한다. 자기 소유를 밝히는 문장은
# 「이 <무엇>은 여기가 소유한다」 한 꼴이고, 그 문장이 놓인 절 제목이 소유 표의 키다. 다른 절을
# 가리키는 문장은 이 꼴을 쓰지 않으므로 포인터가 소유자로 잡히지 않는다.
# 전에는 「렌즈에게 에이전트원칙을 알리는 법」 하나에만 이 검사가 걸렸고 가리킬 문서 셋도 손으로 적혀
# 있었다. 넷째 문서가 복제하면 검사가 지나쳤다. 이제 소유자도 대상도 도출한다.
# 감사 대상 목록은 아래 세 구획(소유 표·첫 문장·대구 한도)이 함께 쓴다. 한 번만 뽑는다.
AUDIT_DOCS="$(cd "$HERE" && bash scripts/audit_targets.sh)"
OWN_DOCS="$AUDIT_DOCS"
check "소유 검사 대상 문서를 모았다" "[ -n \"\$OWN_DOCS\" ]"
# 문서마다 awk·grep 을 따로 띄우지 않고 awk 한 번으로 모든 문서를 읽는다. 문서 경로는 레포 상대다.
OWN_TSV="$(cd "$HERE" && awk '
    FNR == 1 { title = "" }
    /^#{1,3} / { title=$0; sub(/^#+ /, "", title) }
    /여기가 소유한다/ { if (title != "") print title "\t" FILENAME }' $OWN_DOCS | sort || true)"
check "소유 선언을 뽑았다" "[ -n \"\$OWN_TSV\" ]"
# 앵커 자가시험 — 목록이 비면 아래 단언이 모두 근거 없이 통과한다.
check "알려진 소유자가 표에 있다" "printf '%s' \"\$OWN_TSV\" | grep -qF '한 번만 실행하는 렌즈의 규율'"
OWN_DUP="$(printf '%s' "$OWN_TSV" | cut -f1 | sort | uniq -d || true)"
[ -n "$OWN_DUP" ] && printf '    둘 이상이 소유한 절:%s\n' "$(printf '%s' "$OWN_DUP" | tr '\n' ' ')"
check "같은 절을 둘 이상이 소유하지 않는다" "[ -z \"\$OWN_DUP\" ]"
# 소유 표를 먼저 읽고 문서를 한 번씩 훑는다. 소유자의 이름은 스킬이면 폴더 이름, 아니면 파일 이름이다.
# 제목이 괄호를 달면 가리키는 쪽은 괄호 앞까지만 적으므로 그 앞부분으로도 찾는다.
# 파일이 아니라 그 줄을 본다. 파일 단위로 보면 소유자를 다른 데서 한 번 부른 문서가 이 줄에서
# 포인터를 빠뜨려도 통과한다. 절마다 문서 하나에 한 번만 적고, 출력은 소유 표 순서를 따른다.
OWN_BAD="$( [ -n "$OWN_TSV" ] || exit 0; cd "$HERE" && printf '%s\n' "$OWN_TSV" | LC_ALL=C awk -F'\t' '
  NR == FNR {
    if ($1 == "") next
    n++; T[n] = $1; O[n] = $2; nm = $2
    if (nm ~ /^skills\/.*\/SKILL\.md$/) sub(/\/SKILL\.md$/, "", nm)
    sub(/.*\//, "", nm); N[n] = nm
    S[n] = T[n]; p = index(T[n], " ("); if (p) S[n] = substr(T[n], 1, p - 1)
    next
  }
  {
    for (i = 1; i <= n; i++) {
      if (FILENAME == O[i] || ((FILENAME, i) in done)) continue
      if (!index($0, "「" T[i] "」") && !(S[i] != T[i] && index($0, "「" S[i] "」"))) continue
      if (index($0, N[i])) continue
      done[FILENAME, i] = 1; B[i] = B[i] " [" FILENAME "→「" T[i] "」]"
    }
  }
  END { for (i = 1; i <= n; i++) printf "%s", B[i] }' - $OWN_DOCS )"
# 소유자로 불리는데 스스로 선언하지 않은 절을 잡는다. 그런 절은 소유 표에 안 올라 위 단언 둘이
# 아예 안 본다 — 조용히 빠지는 것을 막는다. 제목이 괄호를 달고 갈리므로 참조가 제목의
# 앞부분과 맞으면 같은 절로 본다.
OWN_TITLES="$(printf '%s' "$OWN_TSV" | cut -f1)"
OWN_UNDECL=""
while IFS= read -r rtitle; do
  [ -n "$rtitle" ] || continue
  [[ $OWN_TITLES == *"$rtitle"* ]] || OWN_UNDECL="$OWN_UNDECL [「$rtitle」]"
done <<EOF
$(cd "$HERE" && LC_ALL=C.UTF-8 grep -ohE '「[^」]+」[^「]{0,20}소유한다' $OWN_DOCS | sed 's/」.*//; s/^「//' | sort -u)
EOF
[ -n "$OWN_UNDECL" ] && printf '    소유자로 불리는데 선언이 없는 절:%s\n' "$OWN_UNDECL"
check "소유자로 불리는 절이 스스로 선언한다" "[ -z \"\$OWN_UNDECL\" ]"
[ -n "$OWN_BAD" ] && printf '    소유자를 안 가리키고 절 이름만 담은 곳:%s\n' "$OWN_BAD"
check "절 이름을 담은 문서가 소유자를 가리킨다" "[ -z \"\$OWN_BAD\" ]"

echo "[첫 문장] 소제목 아래 첫 줄이 산문이다"
# LABEL-NOUN 의 헤드 메시지가 "제목 바로 아래 첫 줄에 그 단위의 결론을 문장으로 쓴다"고 정한다.
# 빈 줄을 건너뛴 첫 줄이 불릿·표·코드블록·인용·번호목록이면 결론 문장이 아니다. 그 줄이 산문인데
# 결론이 아닌 것은 기계가 못 가르므로 여기서 잡는 것은 구조로 드러나는 위반뿐이다.
# 예외 목록은 domain-korean 의 「첫 문장 규칙의 예외」 표에서 뽑는다 — 이름을 하나 더하면 저절로
# 따라온다. 예외는 렌즈 파일 안에서만 걸리고, 제목이 괄호를 달고 갈리므로 앞부분으로 맞댄다.
# LABEL-NOUN 은 「원칙」 절의 규칙이라 영어 제목에도 적용한다.
HF_WK="$HERE/skills/lens-readability/domain-korean.md"
# 제목 단계는 보지 않는다. 그 표가 어느 절 아래로 들어가도 이름만 같으면 따라온다.
HF_EXC="$(awk '/^#{3,4} 첫 문장 규칙의 예외/{f=1;next} f&&/^#{2,4} /{exit} f' "$HF_WK" | grep -oE '^[|] `[^`]+`' | sed 's/^[|] `//; s/`$//')"
check "첫 문장 예외를 domain-korean 에서 뽑았다" "[ -n \"\$HF_EXC\" ]"
HF_DOCS="$AUDIT_DOCS"
check "검사 대상 문서를 모았다(첫 문장)" "[ -n \"\$HF_DOCS\" ]"
HF_BAD=""
for hf in $HF_DOCS; do
  hf_lens=0; case "$hf" in skills/lens-*/SKILL.md) hf_lens=1 ;; esac
  hit="$(awk -v isLens="$hf_lens" -v exc="$HF_EXC" '
    BEGIN { n=split(exc, E, "\n") }
    /^#{2,3} / {
      title=$0; sub(/^#+ /, "", title)
      first=""
      while ((getline line) > 0) { if (line ~ /^[ \t]*$/) continue; first=line; break }
      if (first == "") next
      if (isLens) { for (i=1;i<=n;i++) if (E[i] != "" && index(title, E[i]) == 1) next }
      if (first ~ /^[-*+] / || first ~ /^\|/ || first ~ /^```/ || first ~ /^> / || first ~ /^[0-9]+\. /) print title
    }' "$HERE/$hf")"
  [ -n "$hit" ] && HF_BAD="$HF_BAD [$hf: $(printf '%s' "$hit" | tr '\n' ',')]"
done
[ -n "$HF_BAD" ] && printf '    첫 줄이 산문이 아닌 소제목:%s\n' "$HF_BAD"
check "소제목 아래 첫 줄이 모두 산문이다" "[ -z \"\$HF_BAD\" ]"

echo "[문서 타입 표] 강제하는 장치 칸이 실물을 가리킨다"
# 표가 장치를 이름으로만 적으면 실물이 없어도 그 행은 갖춰진 것처럼 읽힌다. 칸을 표가 사는 곳에서
# 뽑아 백틱 경로면 그 파일이 있는지 보고, 「없다」로 열리면 뒤에 이유가 붙었는지 본다. 둘 다 아니면
# 실패한다 — 이름만 적고 넘어가는 길을 막는다. 행을 하나 더해도 저절로 따라온다.
TYPE_CELLS="$(awk '/^## 문서 타입마다 무엇이 강제하나/{f=1;next} f&&/^## /{exit} f&&/^\| \*\*/{n=split($0,a,"|"); print a[n-1]}' "$TYPE_TBL")"
check "문서 타입 표에서 장치 칸을 뽑았다" "[ -n \"\$TYPE_CELLS\" ]"
TYPE_BAD=""
while IFS= read -r cell; do
  [ -n "$cell" ] || continue
  # 백틱이 없는 칸이 정상이므로(사유 있는 「없다」) grep 실패를 오류로 삼지 않는다.
  tpath="$(printf '%s' "$cell" | grep -oE '`[^`]+`' | tr -d '`' | head -1 || true)"
  if [ -n "$tpath" ]; then
    [ -e "$HERE/$tpath" ] || TYPE_BAD="$TYPE_BAD [실물없음:$tpath]"
  elif printf '%s' "$cell" | LC_ALL=C.UTF-8 grep -qE '없다\. .+'; then
    :
  else
    TYPE_BAD="$TYPE_BAD [경로도사유도없음]"
  fi
done <<EOF
$TYPE_CELLS
EOF
[ -n "$TYPE_BAD" ] && printf '    어긋난 칸:%s
' "$TYPE_BAD"
check "장치 칸이 모두 실물 경로이거나 사유 있는 「없다」다" "[ -z \"\$TYPE_BAD\" ]"
# 핸드오프 행이 가리키는 린트가 그 파일 안에 실제로 있는지 본다. 파일 존재만 보면 경로가 맞아도
# 린트가 없을 수 있다.
check "핸드오프 린트가 세션 시작 스크립트에 있다" "grep -qF 'handoff-keep-until' '$HERE/scripts/scaffold.sh'"

echo "[대체된 설계 문서에 superseded 표시]"
OLDSPEC="$HERE/docs/superpowers/specs/2026-08-16-review-layer-redesign-design.md"
OLDPLAN="$HERE/docs/superpowers/plans/2026-08-16-review-layer-redesign.md"
check "옛 spec 에 superseded 표시가 있다"   "grep -qF 'superseded' \"\$OLDSPEC\""
check "옛 plan 에 superseded 표시가 있다"   "grep -qF 'superseded' \"\$OLDPLAN\""

# 제거된 기능의 설계 문서에도 표시를 요구한다. 목록을 손으로 적지 않고 스캐폴드의 정리 대상
# (SCAFFOLD_STALE)에서 도출한다 — 그 목록이 "이 레포가 뜯어낸 기능"의 원본이라, 기능을 하나 더
# 걷어내면 그 설계 문서에 표시가 없다는 것이 여기서 실패한다. 표시가 없으면 그 문서는 지금도
# 실행할 계획으로 읽히고, plan 은 첫머리에서 스스로 태스크 단위 실행을 지시한다.
STALE_NAMES="$(sed -n 's/^SCAFFOLD_STALE="\(.*\)"$/\1/p' "$HERE/scripts/_scaffold_common.sh" | head -1)"
check "제거된 기능 목록을 도출했다" "[ -n \"\$STALE_NAMES\" ]"
SN=0
for n in $STALE_NAMES; do
  # 파일 이름은 그대로 기능 이름이 아니다 — 첫 구분자 앞의 어간(solved_problems.md → solved)으로 훑는다.
  case "$n" in *.md) n="${n%%[_.-]*}" ;; esac
  for D in "$HERE"/docs/superpowers/specs/*"$n"*.md "$HERE"/docs/superpowers/plans/*"$n"*.md; do
    [ -f "$D" ] || continue
    SN=$((SN+1))
    check "$(basename "$D") 에 superseded 표시가 있다" "head -12 '$D' | grep -qF 'superseded'"
  done
done
check "제거된 기능의 설계 문서를 하나 이상 훑었다" "[ '$SN' -gt 0 ]"

# 영문 재작성 대응표는 그 재작성이 되돌려져 지금 구조와 안 맞는다. 표시가 없으면 에이전트원칙이 영문인
# 것처럼 읽힌다. 파일 목록은 디렉터리에서 도출한다 — 표가 늘어도 사람이 목록을 맞출 필요가 없다.
RWDIR="$HERE/docs/superpowers/rewrite-map"
RWN=0
for RW in "$RWDIR"/*.md; do
  [ -f "$RW" ] || continue
  RWN=$((RWN+1))
  check "$(basename "$RW") 에 superseded 표시가 있다" "head -8 '$RW' | grep -qF 'superseded'"
  check "$(basename "$RW") 가 되돌려졌다고 말한다"     "head -8 '$RW' | grep -qF '되돌려졌다'"
done
check "대응표를 하나 이상 훑었다"           "[ '$RWN' -gt 0 ]"

# --- 프로젝트 파일에 손대는 예외: README 한 곳만 조건을 적는다 ---
# 전에는 README가 스스로 원본이라고 선언해 놓고 스캐폴드 둘이 조건을 각각 다시
# 적었다. 예외가 늘거나 조건이 바뀌면 사람이 네 곳을 손으로 맞춰야 하고, 그러면 반드시 갈라진다.
# 가리키는 절 이름도 함께 확인한다 — 전에 README 절 이름이 바뀌었는데 가리키는 쪽만 옛 이름으로 남았다.
echo "[프로젝트 파일 예외 — README 한 곳만 조건을 적는다]"
# 문서를 한 줄로 펴서 본다 — 전에는 원본 문서에서 줄이 바뀌자 같은 문장인데도 검사가 실패했다.
flat() { tr '
' ' ' < "$1" | tr -s ' '; }
# 소유자에는 있어야 하고 사본에는 없어야 하는 조건 조각이다. 두 검사가 같은 목록을 본다.
# 짧은 조각 — 사본은 스크립트 주석이라 제목이나 소유 선언이 없어 구조로 못 적는다.
EXC_MARKS=('기능이 없어졌으면')
EXC_OWN_SEC='프로젝트 폴더에 생기는 파일'
check "README가 예외 절을 두고 그 조건을 스스로 정한다" "has_sec \"\$README\" \"\$EXC_OWN_SEC\" && sec_has \"\$README\" \"\$EXC_OWN_SEC\" '여기가 정한다'"
for m in "${EXC_MARKS[@]}"; do
  check "README가 조건을 적는다: $m"    "sec_has \"\$README\" \"\$EXC_OWN_SEC\" '$m'"
done
# 이 뽑아내기는 반드시 UTF-8 로케일에서 돈다. 바이트로 보면 [^」] 가 한글 음절의 이음 바이트까지
# 걸러 내 「프로젝트 폴더에 생기는 파일」 같은 이름이 통째로 안 잡힌다(실제로 그 함정을 밟았다).
# 괄호를 떼는 것도 tr 로 하지 않는다 — tr 은 바이트를 지워 같은 이음 바이트를 가진 한글을 망가뜨린다.
EXC_SEC="$(LC_ALL=C.UTF-8 grep -oE '「[^」]*」' "$HERE/scripts/scaffold.sh" | sed 's/^「//; s/」$//' | grep -F '프로젝트 폴더' | head -1 || true)"
check "스캐폴드가 README 절을 가리킨다" "[ -n \"\$EXC_SEC\" ]"
check "그 절이 README에 실재한다"            "[ -n \"\$EXC_SEC\" ] && grep -qF \"## \$EXC_SEC\" \"\$README\""
# CLAUDE.md는 이제 조건을 되풀이하지 않고 README를 가리키기만 한다. 가리키는 문장이 살아 있는지 본다.
check "CLAUDE.md가 README를 가리킨다"          "sec_has \"$HERE/CLAUDE.md\" '에이전트원칙을 고칠 때' 'README'"

for D in "$HERE/scripts/scaffold.sh"; do
  dn="$(basename "$D")"
  check "$dn 이 README 절을 가리킨다"   "grep -qF -- '프로젝트 폴더에 생기는 파일' '$D'"
  for m in "${EXC_MARKS[@]}"; do
    check "$dn 이 조건을 베끼지 않는다: $m" "! flat '$D' | grep -qF -- '$m'"
  done
done

# --- 설치 확인 명령은 훅 전용 변수에 기대지 않는다 ---
# README의 확인 명령이 CLAUDE_PLUGIN_ROOT를 썼다. 그 변수는 훅과 커맨드가 실행될 때만 채워지고
# 사용자 셸에서는 비어 있어, 설치가 멀쩡한 사람도 경로를 못 얻고 실패로 오진했다. 커맨드 문서는
# 세션이 대신 실행하므로 해당하지 않는다 — 사용자가 직접 치는 README만 확인한다.
echo "[설치 확인 명령 — 사용자 셸에서 그대로 돈다]"
check "README가 훅 전용 변수를 안 쓴다"   "! grep -qF -- 'CLAUDE_PLUGIN_ROOT' \"\$README\""
# 전에는 이 자리를 grep 'disciplined-coder' 한 줄로 재다가, README 첫 줄 제목에서 이미 걸려
# 확인 명령을 통째로 지워도 초록인 검사가 됐다. 그래서 후보 이름을 _resolve_home.sh 에서 도출해 대조한다 —
# resolve_home이 보는 환경변수(테스트 전용 *_HOME_DIR 제외)가 README 명령에도 다 있어야 한다.
HOMESH="$HERE/scripts/_resolve_home.sh"
HOME_CANDS="$(grep -oE '\$\{(CLAUDE_CONFIG_DIR|USERPROFILE|HOME):-\}' "$HOMESH" | sed 's/^\${//; s/:-}$//' | sort -u)"
check "_resolve_home.sh 에서 홈 후보 이름을 뽑아냈다" "[ -n \"\$HOME_CANDS\" ]"
while IFS= read -r v; do
  [ -n "$v" ] || continue
  check "README 확인 명령이 후보를 훑는다: $v" "grep -qE -- '[\$][{]?$v' \"\$README\""
done <<EOF
$HOME_CANDS
EOF
check "README가 셋업 여부를 함께 찍는다"   "grep -qF -- 'd/disciplined-coder' \"\$README\""

# --- 「」로 가리킨 절이 실재한다 ---
# 「이렇게 보이면 성공이다」가 README에서 이름이 바뀐 뒤에도 아무 신호 없이 남았고, 렌즈가 자기
# 절을 다른 이름으로 불렀다. 그래서 「」 참조를 레포 전체의 제목 집합과 맞댄다.
#
# 자기 파일만 훑지 않는 이유는 문서끼리 「」로 절을 가리키는 것이 이 레포의 관례이기 때문이다.
# 한 파일 안으로 좁히면 정당한 상호 참조가 실패하고, 고치는 압력이 그 참조를 지우는 쪽으로 간다.
# 제목 전체 일치를 요구하지 않는 이유도 같다 — 이 레포는 이름 뒤에 설명절을 다는 쪽이 다수라,
# 전체 일치로 재면 이름은 그대로인데 설명절을 붙이는 순간 실패한다. 이름 부분만 맞대면 원래
# 잡으려던 것(가리키는 이름이 어디에도 없다)은 그대로 잡힌다.
echo "[「」로 가리킨 절이 레포 어딘가에 실재한다]"
HEADINGS="$(find "$HERE" -name '*.md' -not -path '*/.git/*' -exec grep -hE '^#+ ' {} + \
  | sed 's/^#\+ *//' | sed 's/ *[—(].*$//' | sed 's/ *$//' | grep -v '^$' | sort -u)"
check "레포 제목 집합을 모았다" "[ -n \"\$HEADINGS\" ]"
BN=0
for SRC in "$HERE/skills/lens-readability/SKILL.md" "$CALLER" "$CANON"; do
  sn="$(basename "$(dirname "$SRC")")/$(basename "$SRC")"
  while IFS= read -r sec; do
    [ -n "$sec" ] || continue
    BN=$((BN+1))
    # 파이프 대신 here-string 으로 넘긴다. `printf | grep -q` 는 이 스크립트의 pipefail 과 맞물려
    # 뒤집힌 실패를 낸다 — grep -q 는 찾는 즉시 빠져나가고, 그러면 아직 쓰고 있던 printf 가 EPIPE 를
    # 받아 파이프라인 전체가 실패로 계상된다. 제목이 있어서 실패하는 것이라 로컬에서는 통과하고
    # CI 에서만 붉게 뜬다. 제목 집합이 32KB 를 넘긴 뒤로 grep 의 첫 읽기가 전부를 못 담아 갈렸다.
    check "$sn 이 가리킨 절이 있다: $sec" "grep -qxF -- '$sec' <<<\"\$HEADINGS\""
  done <<EOF
$(LC_ALL=C.UTF-8 grep -oE '「[^」]*」' "$SRC" | sed 's/^「//; s/」$//; s/ *[—(].*$//; s/ *$//' | sort -u)
EOF
done
check "「」 참조를 하나 이상 찾았다" "[ '$BN' -gt 0 ]"

# --- spec 리뷰 마커: 코드의 리터럴이 산문 둘에 그대로 있다 ---
# 코드가 스스로 "쌍 계약"이라 부르며 사람에게 손으로 맞추라고 지시하던 자리다. 사람이 맞추는
# 대신 코드에서 뽑아 대조한다 — 마커를 바꾸면 산문이 안 따라온 것이 여기서 실패한다.
echo "[spec 리뷰 마커 == 코드의 리터럴]"
MARKER="$HERE/hooks/_spec_marker.sh"
MARK_OK="$(grep -oE 'spec-review: passed' "$MARKER" | head -1 || true)"
MARK_ESC="$(grep -oE 'spec-review: escalated' "$MARKER" | head -1 || true)"
check "코드에서 통과 마커를 뽑아냈다"     "[ -n \"\$MARK_OK\" ]"
check "코드에서 에스컬레이트 마커를 뽑아냈다" "[ -n \"\$MARK_ESC\" ]"
# 둘 다 뽑은 값으로 대조한다. 전에는 에스컬레이트만 손으로 적은 'escalated' 리터럴로 재다가,
# 마커 형태가 바뀌어도 낱말만 남아 있으면 통과하는 반쪽 대조가 됐다 — 절반만 기계화한 것이
# 원래의 손 유지보다 오히려 조용했다.
# README도 같은 리터럴을 적으므로 함께 대조한다 — 한 파일만 대조하면 나머지는 조용히 낡는다.
for D in "$CALLER" "$README"; do
  dn="$(basename "$D")"
  check "$dn 이 통과 마커를 코드와 같이 적는다"       "grep -qF -- '$MARK_OK' '$D'"
  check "$dn 이 에스컬레이트 마커를 코드와 같이 적는다" "grep -qF -- '$MARK_ESC' '$D'"
done
# 끄기 변수 이름도 코드에서 뽑아 산문과 맞댄다.
GATE_VAR="$(grep -oE 'DISCIPLINED_CODER_[A-Z_]+' "$STOPH" | head -1 || true)"
check "코드에서 끄기 변수 이름을 뽑아냈다" "[ -n \"\$GATE_VAR\" ]"
for D in "$CALLER" "$README"; do
  check "$(basename "$D") 이 끄기 변수 이름을 코드와 같이 적는다" "grep -qF -- '$GATE_VAR' '$D'"
done

# --- 렌즈 전체 개수를 산문에 박지 않는다 ---
# 렌즈를 하나 더하면 디렉터리와 source 열거는 위 검사가 잡아 주지만 산문에 박힌 수는 초록인 채
# 옛 값으로 남는다.
#
# 처음에는 훑는 범위를 사고가 났던 파일 둘로만 잡았다가, 정작 살아 있는 '두 렌즈'·'세 렌즈'·
# '렌즈 셋'을 하나도 못 보는 초록 검사가 됐다. 그래서 범위를 렌즈를 셀 만한 문서 전부로 넓히고
# 수사가 앞선 것과 뒤선 것을 함께 잡는다.
#
# **개수를 적으려면 그 개수의 이름을 같은 줄에 함께 적는다.** 이름이 없는 개수만 금지한다.
# '여섯 렌즈는 이 스키마로 돌려준다'는 렌즈가 늘면 조용히 틀린 값이 되지만, '`grounding`·
# `consistency`·`adversarial` 렌즈 셋을 띄운다'는 이름이 함께 있어 어긋나면 눈에 띄고 위의 집합
# 대조 검사들이 그 이름을 지킨다. 전체 개수와 묶음 크기를 정규식으로 가를 수는 없지만, 이름을
# 함께 적었는지는 잴 수 있고 그 기준이 실제로 낡는 자리를 정확히 짚는다.
echo "[이름 없는 렌즈 개수를 산문에 박지 않는다]"
# '한'은 뺀다 — '유일한 렌즈'의 '한'이 수사로 잡히고, 한국어는 낱말 경계를 정규식으로 못 가른다.
# 어차피 '한 렌즈'는 렌즈가 늘어도 안 낡는 표현이라 금지할 값이 없다.
NUM='(두|세|네|다섯|여섯|일곱|여덟|아홉|열)'
NUMB='(둘|셋|넷|다섯|여섯|일곱|여덟|아홉|열)'
# 렌즈 이름은 디렉터리에서 도출한다 — 여기 손으로 적으면 그 목록이 먼저 낡는다.
LENS_RE="$(printf '%s' "$ALL" | tr '\n' '|' | sed 's/|$//')"
COUNT_SCAN="$AGG $HERE/skills/lens-*/SKILL.md $HERE/skills/review-docs/SKILL.md $HERE/skills/domain-readme/SKILL.md $DISP $CALLER $CANON $HERE/README.md"
# shellcheck disable=SC2086
NUMHIT="$(LC_ALL=C.UTF-8 grep -nE "$NUM[ ]?렌즈|렌즈[ ]?$NUMB|다른 $NUMB[ ]?(렌즈|은|는)|$NUMB[ ]?곳에" $COUNT_SCAN 2>/dev/null \
  | grep -v '개수를 산문에\|이름을 같은 줄에' \
  | LC_ALL=C.UTF-8 grep -vE "$LENS_RE" || true)"
check "개수를 적은 자리마다 이름이 함께 있다" "[ -z \"\$NUMHIT\" ]"
[ -n "$NUMHIT" ] && printf '    이름 없이 개수만 박힌 자리:\n%s\n' "$NUMHIT"

# --- 테스트 실행 명령: 앞 스크립트의 실패를 삼키지 않는다 ---
# CLAUDE.md가 실행 명령의 원본이다. 그 줄이 지워지거나 `for t in ...; do bash "$t"; done` 으로
# 되돌아가면 마지막 하나의 종료 코드만 남아 앞선 FAIL이 묻히고, 감사는 잘못된 FAIL=0을 보고한다.
echo "[테스트 실행 명령 — 앞 스크립트의 실패가 안 묻힌다]"
CMD="$HERE/CLAUDE.md"
# 게이트는 새로 쓸 때만 걸린다. 조건을 빼고 적으면 이미 커밋된 spec 을 고칠 때도 막히는 것처럼
# 읽힌다. '새로' 없이 그 문장이 나오면 실패한다.
check "CLAUDE.md 가 새로 쓸 때만 게이트라고 적는다" "! grep -qE '(^|[^로 ])쓰면 Stop 게이트가' \"\$CMD\""
check "CLAUDE.md가 실행 명령을 적는다"       "grep -qF -- 'for t in scripts/test_*.sh' \"\$CMD\""
# 글자가 아니라 동작으로 잰다. 앞 판본은 `bad="$bad $t"` 라는 글자를 봤기 때문에, 같은 계약을
# 지키는 다른 구현(동시 실행)으로 바꾸자 계약이 아니라 구현이 깨졌다고 알렸다. 여기서는 그 줄을
# CLAUDE.md에서 뽑아 픽스처에 대고 실제로 돌린다 — 실패한 스크립트를 이름으로 지목하는지, 전부
# 통과하면 통과라고 하는지 둘 다 본다.
RUNCMD="$(grep -F -- 'for t in scripts/test_*.sh' "$CMD" | head -1 | sed 's/^[[:space:]]*`//; s/`[[:space:]]*$//')"
check "실행 명령 한 줄을 뽑아냈다"           "[ -n \"\$RUNCMD\" ]"
# 이름을 aaa로 두어 정렬상 맨 앞에 오게 한다 — 묻히는 것은 언제나 '앞' 스크립트의 실패다.
FXB="$(mktemp -d)"; mkdir -p "$FXB/scripts"
printf '#!/usr/bin/env bash\necho "  FAIL: 일부러 심은 회귀"\nexit 1\n' > "$FXB/scripts/test_aaa_bad.sh"
printf '#!/usr/bin/env bash\necho "  PASS: ok"\n' > "$FXB/scripts/test_zzz_ok.sh"
FXBOUT="$(cd "$FXB" && bash -c "$RUNCMD" 2>&1 || true)"
check "앞 스크립트가 실패하면 이름을 지목한다" "printf '%s' \"\$FXBOUT\" | grep -qF 'test_aaa_bad.sh'"
check "실패했는데 ALL PASS라고 하지 않는다"   "! printf '%s' \"\$FXBOUT\" | grep -qF 'ALL PASS'"
FXG="$(mktemp -d)"; mkdir -p "$FXG/scripts"
printf '#!/usr/bin/env bash\necho "  PASS: ok"\n' > "$FXG/scripts/test_zzz_ok.sh"
FXGOUT="$(cd "$FXG" && bash -c "$RUNCMD" 2>&1 || true)"
check "전부 통과하면 ALL PASS라고 한다"       "printf '%s' \"\$FXGOUT\" | grep -qF 'ALL PASS'"
check "모은 결과를 마지막에 알린다"           "grep -qF -- 'FAILED:' \"\$CMD\""
# CI도 같은 명령을 돈다. CLAUDE.md와 달리 CI는 CLAUDE.md를 읽을 수 없어 형태를 다시 적을 수밖에 없으니,
# 적어도 그 형태가 CLAUDE.md의 명령과 같은 실패 처리를 하는지 붙든다. `set -e`에 맨 `bash "$t"`면 첫 실패에서
# 멈춰 뒤 스크립트가 아예 안 돌고, 무엇이 더 깨졌는지 한 회차로는 알 수 없다.
CI="$HERE/.github/workflows/ci.yml"
check "CI가 계약 테스트를 돈다"               "grep -qF -- 'for t in scripts/test_*.sh' \"\$CI\""
check "CI도 실패를 모으는 형태다"             "grep -qF -- 'bad=\"\$bad \$t\"' \"\$CI\""
check "CI도 모은 결과를 마지막에 알린다"       "grep -qF -- 'FAILED:' \"\$CI\""


# --- 렌즈: 본문 체크리스트의 축이 복사용 프롬프트에도 다 실린다 ---
# 실제로 도는 것은 프롬프트다. 본문에만 적힌 축은 그대로 복사한 세션에 닿지 않아 그 축이 통째로
# 안 돌고, 출력 스키마의 해당 `type` 값이 한 번도 안 쓰인 채 남는다.
# 전에는 그때 눈에 띈 문구 셋을 grep 으로 붙들었는데, 그 모양은 새로 갈라지는 축을 못 잡았다(실제로
# 세 렌즈가 갈린 채 검사를 통과했다). 그래서 본문에서 축 이름을 뽑아 프롬프트와 대조한다.
echo "[렌즈 — 본문 축이 프롬프트에도 실린다]"
for L in "$HERE"/skills/lens-*/SKILL.md; do
  LN="$(basename "$(dirname "$L")")"
  AXES="$(awk '/^## 체크리스트/{f=1;next} f&&/^## /{exit} f&&/^- \*\*/{print}' "$L" \
          | sed 's/^- \*\*//; s/\*\*.*$//')"
  [ -z "$AXES" ] && continue
  check "$LN: 프롬프트 줄이 있다" "[ -n \"\$(grep -m1 '^- system:' '$L')\" ]"
  while IFS= read -r ax; do
    [ -z "$ax" ] && continue
    check "$LN: 프롬프트가 축을 부른다: $ax" "grep -m1 '^- system:' '$L' | grep -qF -- '$ax'"
  done <<AXEOF
$AXES
AXEOF
done

# --- 새로 만든 스킬이 진입로에 등재된다 ---
# 스킬을 만들면서 그것을 가리키는 자리를 함께 만들지 않으면, 상황에서 출발한 세션이 그 스킬에 닿지
# 못한다(실제로 audit-repo-docs 이 에이전트원칙의 두 표 어디에도 없었다). 그래서 스킬 디렉터리에서 이름을
# 도출해 에이전트원칙이나 도메인 목차가 그 이름을 한 번은 부르는지 본다.
echo "[스킬 등재 — 진입로에서 이름이 불린다]"
for d in "$HERE"/skills/*/; do
  sk="$(basename "$d")"
  # 진입로는 셋이다 — 에이전트원칙이 이름을 부르거나, 다른 스킬이 부르거나, 렌즈면 에이전트원칙의 묶음 표기에 든다.
  # 자기 SKILL.md 안의 언급은 세지 않는다. 자기가 자기를 부르는 것은 도달이 아니다.
  named=0
  grep -qF -- "$sk" "$HERE/agent-principles.md" && named=1
  if [ "$named" = 0 ]; then
    for o in "$HERE"/skills/*/SKILL.md; do
      case "$o" in */"$sk"/SKILL.md) continue ;; esac
      grep -qF -- "$sk" "$o" && { named=1; break; }
    done
  fi
  case "$sk" in lens-*) grep -qF -- 'lens-*' "$HERE/agent-principles.md" && named=1 ;; esac
  check "$sk 을 에이전트원칙이나 다른 스킬이 부른다" "[ '$named' = 1 ]"
  check "$sk 이 언제 여는지 자기 설명에 적는다" "grep -m1 '^description:' '$d/SKILL.md' | grep -qE '때|연다|쓴다|한다'"
done

# description 값은 YAML 평문 스칼라다. ': ' 나 ' #' 이 들어가면 frontmatter 파싱이 깨져 그 스킬이 목록에서
# 조용히 사라진다. 규칙은 domain-plugin 「frontmatter」가 소유하고 여기서 기계로 붙든다.
echo "[frontmatter 안전 — description 값에 ': ' 와 ' #' 이 없다]"
FMN=0
for f in "$HERE"/skills/*/SKILL.md "$HERE"/commands/*.md; do
  [ -f "$f" ] || continue
  FMN=$((FMN+1))
  DESC="$(grep -m1 '^description:' "$f" | sed 's/^description:[[:space:]]*//')"
  check "$(basename "$(dirname "$f")")/$(basename "$f") 의 description 이 YAML 평문으로 안전하다" "! printf '%s' \"\$DESC\" | grep -qE ': | #'"
done
check "frontmatter 를 하나 이상 훑었다" "[ '$FMN' -gt 0 ]"

# --- 이독성 규칙의 출처가 세 문서에 걸쳐 이어져 있다 ---
# 에이전트원칙은 조항만 담고, domain-korean 이 상세를 담으며, lens-readability 가 그것을 열어 대조한다.
# 전에 에이전트원칙을 줄이면서 조항을 스킬로 통째로 내렸더니 렌즈가 가리키는 근거가 에이전트원칙에서 사라졌는데,
# 검사가 새 자리를 따라가 버려 끊긴 것을 못 잡았다. 그래서 셋을 한 줄로 함께 붙든다.
echo "[규칙 출처] 에이전트원칙 → domain-korean → lens-readability 가 이어져 있다"
RDB_L="$HERE/skills/lens-readability/SKILL.md"
check "에이전트원칙에 한국어 조항이 있다"       "has_clause \"$CANON\" ONE-ENDING"
check "에이전트원칙이 상세 소유자를 가리킨다"    "grep -qF 'domain-korean' \"$CANON\""
check "렌즈가 기준 문서를 가리킨다"      "grep -qF 'domain-korean' \"$RDB_L\""
check "렌즈 프롬프트도 그 파일을 읽힌다" "grep -m1 '^- system:' \"$RDB_L\" | grep -qF 'domain-korean'"
check "기준 문서가 자기 구실을 밝힌다"   "grep -qF 'lens-readability' \"$WK\""

# --- 관리 디렉터리 파일 목록은 한 곳에서만 정한다 ---
# _scaffold_common.sh 가 "여기만 고친다"고 선언해 놓고 두 스캐폴드가 파일 이름을 각자 다시 적던
# 자리다. 목록이 늘면 사람이 다섯 곳을 손으로 맞춰야 하고, 그러면 반드시 갈라진다.
echo "[관리 파일 목록 == 한 곳]"
SC_FILES="$(grep -oE '^SCAFFOLD_FILES="[^"]*"' "$HERE/scripts/_scaffold_common.sh" | sed 's/^SCAFFOLD_FILES="//; s/"$//')"
check "SCAFFOLD_FILES 를 뽑아냈다" "[ -n \"\$SC_FILES\" ]"
for scf in $SC_FILES; do
  check "스캐폴드가 '$scf' 를 하드코딩하지 않는다" \
    "! grep -qE 'for f in .*$scf' '$HERE/scripts/scaffold.sh'"
done
# 부정 단언의 짝이다 — 부정만 두면 스캐폴드에서 루프가 통째로 사라져도 통과한다.
check "scaffold.sh 가 SCAFFOLD_FILES 를 쓴다"       "grep -qF 'for f in \$SCAFFOLD_FILES' '$HERE/scripts/scaffold.sh'"
check "화이트리스트가 그 목록에서 도출된다"          "grep -qF 'SCAFFOLD_WHITELIST=\"\$SCAFFOLD_FILES' '$HERE/scripts/_scaffold_common.sh'"

# --- 마켓플레이스 문안이 매니페스트에서 갈라지지 않는다 ---
# 마켓플레이스 카드는 설치 전 사용자가 보는 첫 문안이다. 같은 사실을 두 파일이 각자 적으면 반드시
# 갈라지므로, 플러그인 매니페스트를 원본으로
# 두고 마켓플레이스 항목이 그것과 글자 그대로 같은지 확인한다.
# 두 파일을 JSON으로 파싱해 읽는다 — 쉼표 하나가 어긋나 있으면 여기서 실패한다.
echo "[매니페스트] 마켓플레이스 항목이 플러그인 매니페스트와 같은 문안을 쓴다"
JSONPROG='
import json,io,sys
mk=json.load(io.open(sys.argv[1],encoding="utf-8"))
pl=json.load(io.open(sys.argv[2],encoding="utf-8"))
ent=[p for p in mk["plugins"] if p.get("name")==pl["name"]]
print("MISSING" if not ent else ("SAME" if ent[0].get("description")==pl.get("description") else "DIFF"))
'
. "$HERE/scripts/_json_valid.sh"   # 인터프리터 고르기는 한 곳(json_run)이 한다
MKCMP="$(json_run "$JSONPROG" "$HERE/.claude-plugin/marketplace.json" "$HERE/.claude-plugin/plugin.json" 2>&1)" || MKCMP="PARSE-ERROR"
check "두 매니페스트가 JSON으로 파싱된다"     "[ '$MKCMP' != 'PARSE-ERROR' ]"
check "마켓플레이스에 이 플러그인 항목이 있다" "[ '$MKCMP' != 'MISSING' ]"
check "두 문안이 같다"                         "[ '$MKCMP' = 'SAME' ]"

# --- README가 잠금 상수를 베껴 적지 않는다 ---
# 전에는 대기 시간 두 값을 README가 숫자로 적어, 상수가 바뀌면 알려 주는 것 없이 틀린 값이 됐다.
# 값을 적지 말고 상수가 사는 자리를 가리키게 한다.
echo "[README] 잠금 시간을 값으로 적지 않고 상수 자리를 가리킨다"
check "README가 잠금 시간을 베끼지 않는다" "! grep -qE '잠금(은|이)? *[0-9]+초' '$HERE/README.md'"
check "README가 상수 자리를 가리킨다"      "grep -qF '_managed_block.sh' '$HERE/README.md'"

# --- 렌즈에게 에이전트원칙을 알리는 법: dispatching-lenses 한 곳만 내용을 갖는다 ---
# 다른 스킬은 그 절을 가리키기만 한다. 그 절 제목을 두거나 첫 항목의 조각이 나타나면 베낀 것이다.
# 짧은 조각 — dispatching-lenses 본문이 "첫 항목 문장이 다른 스킬에 나타나지 않는지"를 이 검사가 본다고
# 적으므로, 제목 검사만으로 바꾸면 그 문장이 거짓이 된다. 첫 항목에서 고유한 조각만 남긴다.
echo "[렌즈에게 에이전트원칙을 알리는 법] 다른 스킬이 내용을 베끼지 않는다"
TELL_SENT='렌즈가 직접 읽게'
check "dispatching-lenses 의 그 절이 첫 항목을 갖는다" "sec_has \"$DISP\" '렌즈에게 에이전트원칙을 알리는 법' '$TELL_SENT'"
for f in "$HERE"/skills/*/SKILL.md; do
  case "$f" in */dispatching-lenses/*) continue ;; esac
  check "$(basename "$(dirname "$f")") 이 베끼지 않는다" "! has_sec '$f' '렌즈에게 에이전트원칙을 알리는 법' && ! grep -qF -- '$TELL_SENT' '$f'"
done

# --- 금지 표현 목록은 생성물이다 ---
# 원본은 KiwoomAX/korean-banned-words 의 JSON 이고 그 저장소의 render.py 가 만들어 dist/ 에 올린 것을
# 워크플로가 받아 온다. 이 저장소 자신의 문서를 검사에서 빼는 사유는 hooks/_spec_marker.sh 의
# path_in_own_repo 주석이 소유한다.
BANSRC="$HERE/korean-banned-words.md"
echo "[금지 표현] 목록은 생성물이다"
# 내용이 원본과 같은지는 네트워크가 필요해 여기서 못 본다. .github/workflows/banned-words-sync.yml
# 이 하루 한 번 다시 만들어 diff 로 대조한다. 여기서는 손으로 고쳐도 되는 파일처럼 보이지
# 않게 하는 표시와 만드는 수단이 실재하는지만 본다.
check "목록 파일이 있다"               "[ -f \"\$BANSRC\" ]"
# 짧은 조각 — 다른 저장소가 만드는 생성물이라 이 저장소가 열쇠를 정할 수 없다.
check "목록이 생성물이라고 밝힌다"     "grep -qF '생성물' \"\$BANSRC\""
check "목록이 원본 저장소를 가리킨다"  "grep -qF 'KiwoomAX/korean-banned-words' \"\$BANSRC\""
check "받아오는 워크플로가 있다"       "[ -f '$HERE/.github/workflows/banned-words-sync.yml' ]"
check "워크플로가 원본 dist 를 받는다" "grep -qF 'korean-banned-words/main/dist/korean-banned-words.md' '$HERE/.github/workflows/banned-words-sync.yml'"

# 사람 글 스물넷에서 0건인데 AI 글 스물넷에서
# 스물일곱 건 나온 신호라 한도를 두었는데, 세는 곳이 없어 문서 여덟이 넘긴 채로 있었다.
# 세는 대상에서 빼는 것이 넷이고 이유가 서로 다르다. frontmatter 의 description 은 본문이 아니고,
# 「레퍼런스 프롬프트」 절은 서브에이전트로 실어 보내는 페이로드이며, 백틱 안은 규칙이 자기 형태를
# 이름으로 부르는 곳이고, 양쪽이 따옴표로 묶인 짝은 다른 조항이 드는 예시다.
# 문자 부류를 안 쓰고 (가|이) 로 가르는 것은, 로케일이 UTF-8 이 아니면 gawk 가 부류를 바이트로
# 읽어 한글 한 자가 세 바이트로 흩어지기 때문이다. 갈라 적으면 로케일과 무관하게 맞는다.
ANTI_SQ="'"
anti_count() {  # $1=파일 경로 → 이 문서에 남은 대구의 개수
  LC_ALL=C.UTF-8 awk -v sq="$ANTI_SQ" '
    NR==1 && $0=="---" { fm=1; next }
    fm==1 && $0=="---" { fm=2; next }
    fm==1 { next }
    /^## 레퍼런스 프롬프트/ { sk=1; next }
    sk==1 && /^## / { sk=0 }
    sk==1 { next }
    {
      line=$0
      gsub(/`[^`]*`/, "", line)
      gsub(sq "[^" sq "]*" sq "(가|이) 아니라 " sq "[^" sq "]*" sq, "", line)
      c += gsub(/(가|이) 아니라/, "", line)
    }
    END { print c+0 }
  ' "$1"
}
echo "[대구 한도] 글 한 편에 한 번까지"
# 금지 표현 목록은 뺀다. 원본 저장소가 만든 생성물이라 여기서 고칠 수 없고, 그 표의 분류 설명이
# 대구를 쓴다. 고칠 수 없는 파일을 세면 검사가 영영 빨간 채로 남아 다른 위반을 가린다.
ANTI_DOCS="$(printf '%s\n' "$AUDIT_DOCS" | grep -v '^korean-banned-words.md$')"
check "검사 대상 문서를 모았다" "[ -n \"\$ANTI_DOCS\" ]"
# 세는 것이 실제로 세는지 먼저 본다. 이 자기시험이 없으면 세는 함수가 늘 0 을 내도 초록이 된다.
ANTI_TMP="$(mktemp -d)"
printf 'A가 아니라 B다.
C이 아니라 D다.
' > "$ANTI_TMP/two.md"
check "둘이 든 문서를 둘로 센다" "[ \"\$(anti_count \"\$ANTI_TMP/two.md\")\" = 2 ]"
# 제외 넷이 각각 빠지는지 본다. 하나라도 안 빠지면 정상인 문장이 계속 잡힌다.
printf -- '---
description: X가 아니라 Y
---
본문에 `A가 아니라 B` 리터럴.
예시는 %s버릴 것%s이 아니라 %s버릴 연구%s다.
## 레퍼런스 프롬프트
- system: "P가 아니라 Q로 하라"
' "$ANTI_SQ" "$ANTI_SQ" "$ANTI_SQ" "$ANTI_SQ" > "$ANTI_TMP/skip.md"
check "제외 넷은 세지 않는다" "[ \"\$(anti_count \"\$ANTI_TMP/skip.md\")\" = 0 ]"
ANTI_BAD=""
for f in $ANTI_DOCS; do
  anti_n="$(anti_count "$HERE/$f")"
  [ "$anti_n" -gt 1 ] && ANTI_BAD="$ANTI_BAD [$f:$anti_n]"
done
[ -n "$ANTI_BAD" ] && printf '    한도를 넘긴 문서:%s
' "$ANTI_BAD"
check "한도를 넘긴 문서가 없다" "[ -z \"\$ANTI_BAD\" ]"
rm -rf "$ANTI_TMP"

# --- 리뷰·감사 기록은 찍은 뒤 고치지 않는다 ---
# 기록은 그 회차에 무엇을 보았는지의 증거라, 뒤에 고치면 회차 사이 대조가 무너진다. 그래서 새 기록을
# 더하는 것만 허용하고 있는 기록의 수정과 삭제는 거부한다. 경계 날짜는 이 규칙이 들어온 날이다 —
# 그 전의 수정 하나(0ce107c)는 규칙이 없던 때의 일이라 소급하지 않는다.
# 이력 검사는 줄이 하나도 오가지 않은 변경을 빼고 센다. 내용이 없는 파일은 그 회차에 무엇을 보았는지를
# 담고 있지 않아 지워도 회차 사이 대조가 무너지지 않는다. 실제로 기록 폴더에 새어 든 빈 파일 하나를
# 지운 커밋(c87c8e8)이 이 가드에 걸렸다. 진짜 기록의 수정은 반드시 줄을 옮기므로 그대로 걸린다.
# 작업 트리 검사는 이 예외를 두지 않는다. 커밋 전에는 되돌릴 수 있어 지금 알리는 값이 더 크다.
echo "[리뷰 기록은 찍은 뒤 고치지 않는다]"
RVDIR="docs/superpowers/reviews"
check "기록 폴더에 기록이 하나 이상 있다" "ls \"\$HERE/\$RVDIR\"/*.md >/dev/null 2>&1"
RV_TREE="$(cd "$HERE" && git status --porcelain --untracked-files=all -- "$RVDIR" 2>/dev/null | grep -vE '^(\?\?|A ) ' || true)"
[ -n "$RV_TREE" ] && printf '    작업 트리에서 고치거나 지운 기록:
%s
' "$RV_TREE" | sed 's/^/      /'
check "작업 트리에 고치거나 지운 기록이 없다" "[ -z \"\$RV_TREE\" ]"
RV_HIST="$(cd "$HERE" && git log --since=2026-09-02 --diff-filter=MD --numstat --format= -- "$RVDIR" 2>/dev/null \
  | awk -F'\t' 'NF==3 && !($1=="0" && $2=="0") { print $3 }' || true)"
[ -n "$RV_HIST" ] && printf '    규칙 뒤 이력에서 고치거나 지운 기록:
%s
' "$RV_HIST" | sed 's/^/      /'
check "규칙이 들어온 뒤 이력에 고치거나 지운 기록이 없다" "[ -z \"\$RV_HIST\" ]"

# --- 봉인: 기록은 만든 직후에 읽기 전용이 된다 ---
# 읽기 전용 속성은 git이 옮기지 않아 새 클론에서는 풀려 있다. 그래서 SessionStart 훅이 세션마다 다시
# 봉인한다. 인자 없는 갈래는 픽스처 저장소에서 검사한다 — 레포 자신에서 돌리면 스크립트가 아무것도
# 처리하지 않아도 작업 트리 상태만으로 초록이 되고, 검사가 레포의 파일 속성을 바꾼다.
echo "[봉인 — 기록은 읽기 전용이 된다]"
SEAL="$HERE/scripts/seal_reviews.sh"
check "봉인 스크립트가 있다"                 "[ -f '$SEAL' ]"
SEAL_T="$(mktemp -d)"; printf 'a\n' > "$SEAL_T/one.md"; printf 'b\n' > "$SEAL_T/two.json"
bash "$SEAL" "$SEAL_T/one.md" "$SEAL_T/two.json" >/dev/null 2>&1 || true
check "인자로 준 파일이 읽기 전용이 된다"     "[ ! -w '$SEAL_T/one.md' ] && [ ! -w '$SEAL_T/two.json' ]"
bash "$SEAL" "$SEAL_T/one.md" "$SEAL_T/two.json" >/dev/null 2>&1 || true
check "인자 있는 봉인을 두 번 돌려도 같다"     "[ ! -w '$SEAL_T/one.md' ] && [ ! -w '$SEAL_T/two.json' ]"
SEAL_G="$(mktemp -d)"; mkdir -p "$SEAL_G/docs/superpowers/reviews/r1"
( cd "$SEAL_G" && git init -q && git config user.email t@t && git config user.name t \
  && printf 'x\n' > docs/superpowers/reviews/r1.md && printf '{}\n' > docs/superpowers/reviews/r1/run.json \
  && printf 'later\n' > docs/superpowers/reviews/untracked.md && git add docs/superpowers/reviews/r1.md docs/superpowers/reviews/r1/run.json && git commit -qm seed )
bash "$SEAL" --root "$SEAL_G" >/dev/null 2>&1 || true
bash "$SEAL" --root "$SEAL_G" >/dev/null 2>&1 || true
check "인자 없는 봉인이 HEAD 의 기록을 전부 읽기 전용으로 만든다" "[ ! -w '$SEAL_G/docs/superpowers/reviews/r1.md' ] && [ ! -w '$SEAL_G/docs/superpowers/reviews/r1/run.json' ]"
check "HEAD 에 없는 파일은 건드리지 않는다"     "[ -w '$SEAL_G/docs/superpowers/reviews/untracked.md' ]"
check "이 레포의 SessionStart 가 봉인을 건다"  "grep -qF 'seal_reviews.sh' '$HERE/.claude/settings.json'"

# ===== 에이전트원칙과 README와 스킬 문서의 문구 계약 =====
# 스캐폴드를 실행하지 않고 문서끼리의 계약만 본다.

# --- readme-commands-drift: README 커맨드 절 ↔ commands/ 디렉터리 드리프트 가드 (열거는 사용 절 한 곳) ---
# 파일 전체가 아니라 '### 커맨드' 절만 검사한다 — 커맨드명이 다른 문단에 등장해
# 목록 누락이 vacuous 통과하는 것을 막는다.
CMD_SECTION="$(awk '/^## 커맨드/{f=1} f&&/^## /&&!/^## 커맨드/{exit} f' "$HERE/README.md")"
echo "[readme-commands-drift] README commands section covers commands/ dir"
for c in "$HERE"/commands/*.md; do
  n="/$(basename "$c" .md)"
  check "README commands section lists $n" "printf '%s' \"\$CMD_SECTION\" | grep -qF -- '$n'"
done

# --- workflow-verification: 「검증」 절이 렌즈와 기록을 요구한다(에이전트원칙 계약 가드) ---
# 파일 전역 grep이 아니라 「검증」 절만 뽑아 그 안에서 검사한다(다른 절·다른 파일의 문자열로
# vacuous 통과하지 않게 한다).
WF_BLOCK="$(awk '/^## 검증/{f=1} f&&/^## /&&!/^## 검증/{exit} f' "$HERE/agent-principles.md")"
echo "[workflow-verification] 검증 절이 렌즈와 기록을 요구한다"
check "검증 절이 잡힌다"           "[ -n \"\$WF_BLOCK\" ]"
check "렌즈 호출자를 가리킨다"     "printf '%s' \"\$WF_BLOCK\" | grep -qF 'lens-*'"
check "검증 기록은 호출자 스킬이 요구한다" "has_sec \"$HERE/skills/review-specs/SKILL.md\" '리뷰 기록' && grep -qF 'docs/superpowers/reviews/' \"$HERE/skills/review-docs/SKILL.md\""

# --- parallel-orchestration-nudge: 병렬 오케스트레이션 넛지(에이전트원칙 계약 가드) ---
# 병렬 오케스트레이션 헤딩부터 다음 '### ' 또는 '## '까지의 블록만 뽑아 그 안에서 검사한다
# (vacuous 통과 방지).
PO_BLOCK="$(awk '/^## 병렬 오케스트레이션/{f=1} f&&/^## /&&!/^## 병렬 오케스트레이션/{exit} f' "$HERE/agent-principles.md")"
echo "[parallel-orchestration-nudge] principles 병렬 오케스트레이션 nested-orchestration nudge"
check "병렬 오케스트레이션 heading exists"      "printf '%s' \"\$PO_BLOCK\" | grep -qF '## 병렬 오케스트레이션'"
check "병렬 오케스트레이션 points to skill" "printf '%s' \"\$PO_BLOCK\" | grep -qF 'nested-orchestration'"
check "그 절에 서브오케스트레이터 조항이 있다" "printf '%s' \"\$PO_BLOCK\" | grep -qF '**\`SUB-ORCHESTRATE\`'"

# --- nested-orchestration-skill: nested-orchestration 스킬 존재 + 핵심 절(에이전트원칙 계약 가드) ---
# 단일 목적 파일이라 파일 전역 존재 검사로 충분하다(섹션 경합 없음 — Global Constraint 참조).
NO_SKILL="$HERE/skills/nested-orchestration/SKILL.md"
echo "[nested-orchestration-skill] nested-orchestration skill present + structured"
check "skill file exists"             "[ -f '$NO_SKILL' ]"
check "frontmatter name correct"      "grep -qE '^name: *nested-orchestration' '$NO_SKILL'"
check "has routing (2층 위임)"         "grep -qF 'dispatching-parallel-agents' '$NO_SKILL'"
check "has L2 template ownership blk"  "sec_has '$NO_SKILL' 'L2 디스패치 템플릿' '**구간 소유권'"
check "has output contract blk"        "sec_has '$NO_SKILL' 'L2 디스패치 템플릿' '**산출 계약'"
check "points to SDD (no reimpl)"      "grep -qF 'subagent-driven-development' '$NO_SKILL'"

# --- canon-sections: 절차 절을 번호가 아니라 이름으로 부른다 (NAME-ITEMS) ---
# 번호는 항목을 지우거나 끼워 넣는 순간 가리키는 대상이 달라져 조용히 어긋난다. 제목에 이미 이름이
# 있으므로 그 이름으로 부르고, 옛 서수 제목이 되살아나지 않는지 함께 본다.
CANON="$HERE/agent-principles.md"
echo "[canon-sections] procedure sections are named, not numbered"
# 절 이름의 실재는 아래 [canon-realign] 의 절 목록 검사가 본다.
# 한글 탐지는 반드시 UTF-8 로케일에서 한다. 기본 C 로케일의 grep은 대괄호 범위를 바이트로 대조해
# 한글을 문자 단위로 매치하지 못하고, 그러면 옛 서수 제목이 되살아나도 이 검사가 잡지 못한다.
check "canon: no ordinal sections left"    "! LC_ALL=C.UTF-8 grep -qE '^### [가나다라마]\.' '$CANON'"

# --- canon-realign: 에이전트원칙이 원칙을 호명하지 않고 갈래는 걸리는 대상으로 이름 붙는다 ---
# 접기(3fced53) 뒤에 에이전트원칙이 원칙 전부를 갖는다. 갈래마다 원칙을 이름으로 다시 부르던 문장 셋은
# 「원칙」 절이 이미 선언한 것을 부분집합으로 되풀이해 빠진 것이 안 걸린다는 뜻으로 읽혔다.
# 이름이 범위를 좁게 말하던 절 하나만 「한국어 지시사항」로 바꾸고 나머지 여덟은 그대로 둔다.
echo "[canon-realign] the canon owns every principle; only procedures and per-artifact rules stay skills"
# 제목 검사는 줄 전체를 앵커로 잡는다. `grep -F '## Think Before Acting'` 은 `### Think Before Acting` 을
# 부분 문자열로 맞혀 절이 안 올라가도 초록이 된다.
for sec in "원칙" "한국어 지시사항" "문서를 쓰고 관리할 때" "코딩할 때" "검증" "미해결의 처분" "병렬 오케스트레이션"; do
  check "canon: section '$sec' present"              "grep -qE '^## $sec\$' '$CANON'"
done
check "canon: tradeoff line stays"                   "grep -qF '**균형:**' '$CANON'"
check "karpathy source is credited in the reference" "grep -qF 'andrej-karpathy-skills' '$HERE/skills/lens-fit/domain-discipline.md'"
# 문장이 아니라 조항 ID 로 본다. 약한 기준과 번호 붙인 단계는 같은 `CHECKABLE` 조항이라 하나로 합쳤다.
check "canon: subagent fleet rule stays"             "has_clause '$CANON' NO-FLEET"
check "canon: measure-the-state rule stays"          "has_clause '$CANON' NO-ASSUME"
check "canon: impossible-case rule stays"            "has_clause '$CANON' YAGNI"
check "canon: pre-existing-dead-code rule stays"     "has_clause '$CANON' REPORT-DEAD"
check "canon: checkable-task rule stays"             "has_clause '$CANON' CHECKABLE"
# 조항 ID 목록은 근거를 적는 두 참고서의 `### \`ID\`` 제목에서 도출한다(「삭제한 조항」 절은 뺀다).
# 에이전트원칙에서 읽어 오면 단언의 출처가 단언 대상 자신이 되어 조항이 떨어져도 그 결손을 정답으로
# 굳히고, 목록을 여기 손으로 적으면 조항을 더할 때 이쪽이 낡는다. 방향은 참고서 → 에이전트원칙이다.
ref_clause_ids() {
  local f
  for f in "$HERE/skills/lens-fit/domain-discipline.md" "$HERE/skills/lens-readability/domain-korean.md"; do
    awk '{ sub(/\r$/, "") } /^## 삭제한 조항/ { exit } /^### `[A-Z0-9-]+`$/ { gsub(/^### `|`$/, ""); print }' "$f"
  done
}
missing_clause_ids() {  # $1=에이전트원칙 → 참고서에 근거가 있는데 원칙에 없는 ID
  local id miss=""
  for id in $(ref_clause_ids); do grep -qF "**\`$id\`" "$1" || miss="$miss $id"; done
  printf '%s' "$miss"
}
REF_IDS="$(ref_clause_ids)"
check "canon: clause IDs derived from the references" "[ -n \"\$REF_IDS\" ]"
MISS_IDS="$(missing_clause_ids "$CANON")"
check "canon: every clause with a rationale in the references is in agent-principles (reference → principles)" "[ -z \"\$MISS_IDS\" ]"
[ -n "$MISS_IDS" ] && echo "    참고서에 근거가 있는데 에이전트원칙에 없는 조항(참고서 → 에이전트원칙 방향):$MISS_IDS"
# 도출 검사가 결손을 실제로 잡는지 임시 사본에서 본다. 조항 하나를 지운 사본이 통과하면 검사가 무의미하다.
CANON_CUT="$(mktemp)"; grep -vF '**`YAGNI`' "$CANON" > "$CANON_CUT"
check "canon: derived check catches a removed clause" "[ \"\$(missing_clause_ids '$CANON_CUT')\" = ' YAGNI' ]"
# 한국어 절은 두 층이다. 묶는 이름은 `###` 제목이고 원자 지시는 그 아래 굵은 ID 다. 층을 갈라
# 검사해야 이름만 남고 지시가 빠지거나 그 반대인 상태를 잡는다. 원자 지시 층은 위의 도출 검사가 본다.
for g in PLAIN-KO KO-SYNTAX PROSE-FORM READ-FLOW UNPACK REVISE-ORDER; do
  check "canon: korean group $g present"             "grep -qE '^### \`$g\`' '$CANON'"
done
# 조항을 더하려면 CLAUDE.md 가 정한 클린룸 소거 시험을 거쳐야 한다. 시험으로 지운 조항 ID 가
# 그 시험 없이 에이전트원칙에 되돌아오면 실패한다. 지운 근거는 두 참고서의 「삭제한 조항」 절에 있다.
REVIVED_IDS=""
for id in ASK-FORK MEASURE-FIRST SIMPLE SURGICAL TDD ASK-CONTEXT NO-DOC-STATE HANDOFF-CONSUME SINO-KEEP VOCAB-FREQ REWRITE-NOT-ADD FAIL-LOUD EXPLICIT SSOT NAME-UNRESOLVED TRACE-REQUEST KEEP-STYLE IDEMPOTENT LOCAL-FIRST FACT-VS-JUDGE MEMO-DEFER LOANWORD-KEEP LEXICAL-CHAIN; do
  grep -qF "**\`$id\`" "$CANON" && REVIVED_IDS="$REVIVED_IDS $id"
done
check "canon: 지운 조항 ID 가 클린룸 시험 없이 되살아나지 않는다" "[ -z \"\$REVIVED_IDS\" ]"
# 접으면서 새로 선 스킬 둘이 실재하고 이름이 디렉터리와 맞는다.
for sk in review-docs domain-readme; do
  check "skill $sk exists"                           "[ -f '$HERE/skills/$sk/SKILL.md' ]"
  check "skill $sk frontmatter name"                 "grep -qF 'name: $sk' '$HERE/skills/$sk/SKILL.md'"
done

# --- standing-consent: 렌즈 호출에 대한 상시 허가가 에이전트원칙에 있다 ---
# 세션 기본 지침이 "사용자가 요청하지 않으면 서브에이전트를 부르지 마라"로 들어오는 환경이 있다.
# 그 문구는 조건부라 사용자 지침으로 상시 허가를 남기면 열린다. 에이전트원칙은 @import로 실리므로 이 한
# 문장이 있으면 검진이 돈다.
# 파일 전역 grep이 아니라 「검증」 절만 뽑아 그 안에서 본다 — 허가 문장과 범위를 좁히는 문장이
# 서로 떨어져 나가도 각각 어딘가에 남아 있으면 통과해 버리는 항진을 막는다(이 파일의 다른 절과 같은 방식).
# 절을 뽑는 계산과 "검증 절이 잡힌다" 단언은 위 [workflow-verification] 의 WF_BLOCK 을 그대로 쓴다.
# 백틱이 든 패턴은 작은따옴표 변수에 담아 grep -qF -- 로 넘긴다 — 큰따옴표 안에 두면 eval을 지나며
# 명령 치환으로 실행되어, 검사가 엉뚱한 문자열을 찾으면서도 초록으로 남는다.
# 문장이 아니라 조항 ID 로 본다. 허가 범위는 그 조항 줄이 `lens-*` 를 부르는지로 본다.
CONSENT='**`LENS-ALLOWED`'
SC_LINE="$(grep -F -- "$CONSENT" "$CANON" || true)"
echo "[standing-consent] lens calls carry the user's standing consent"
check "canon: 상시 허가 조항"              "printf '%s' \"\$WF_BLOCK\" | grep -qF -- \"\$CONSENT\""
check "canon: 허가 범위 한정"              "grep -qF -- '\`lens-*\`' <<<\"\$SC_LINE\""
# 선행연구 렌즈는 이름을 대서 예외로 못 박아야 한다. 이름이 lens-*라 허가에 들면서 동시에 웹에
# 나가는 유일한 렌즈라, 뭉뚱그린 말로 제외하면 같은 렌즈를 열고 닫는 문장이 된다. 그 상태에서는
# 렌즈를 범위 밖으로 판단해 조용히 건너뛰게 되고, '막히면 알린다'는 안전장치도 발동하지 않는다.
check "canon: 선행연구 렌즈를 이름으로 예외" "printf '%s' \"\$WF_BLOCK\" | grep -qF -- 'lens-prior-art'"
check "canon: 뭉뚱그린 심층조사 표현 없음"   "! printf '%s' \"\$WF_BLOCK\" | grep -qF -- '심층조사'"

# --- question-tool: 갈림길은 질문 도구로 묻는다 (상시 로드 규칙) ---
# 이 규칙이 리뷰 스킬 한 곳에만 있으면 그 스킬을 열지 않은 세션에는 닿지 않는다. 실제로 문서 검진
# 세션이 다시 돌릴지를 평문으로 물어 선택 대화창이 뜨지 않았다. 묻는 방식은 특정 절차의 성질이 아니라
# 소통 규칙이므로 상시 로드되는 항목에 두고, 리뷰 스킬은 그것을 가리키기만 한다.
SR="$HERE/skills/review-specs/SKILL.md"
echo "[question-tool] the fork-in-the-road question rule is always loaded"
# 언제 묻는지와 어떻게 묻는지를 `ASK-OPTIONS` 하나가 정한다(2026-09-24 에 `ASK-CONTEXT` 를 합쳤다).
# 조항 안의 세 문장(정해지지 않으면 묻는다·하나씩 묻는다·대목적을 되짚는다)을 조항 ID 하나로 합쳤다.
check "canon: 묻는 조항이 원칙 절에 있다"    "sec_has '$CANON' '원칙' '**\`ASK-OPTIONS\`'"
check "spec-review: 규칙을 재정의 말고 인용" "sec_has_id '$SR' '작업 순서와 다시 리뷰' ASK-OPTIONS && ! grep -qF '**\`ASK-OPTIONS\`' '$SR'"

# --- section-refs: 옛 절 참조가 남지 않았다 (git 추적 파일, 스펙 아카이브 제외) ---
# 절을 한글 순서 기호로 가리키던 옛 참조는 어디에도 남으면 안 된다. 이름이 바뀌었기 때문이다.
# 이 검사도 위와 같은 로케일 함정을 밟으므로 반드시 UTF-8 로케일에서 돌린다.
# 이 주석 자체가 검색 패턴과 겹치지 않게 쓴다 — 겹치면 검사가 스스로를 잡아 영원히 FAIL한다.
echo "[section-refs] no dangling ordinal references"
STALE="$(cd "$HERE" && export LC_ALL=C.UTF-8 && git ls-files -z | xargs -0 grep -l '§[가나다라마]\|절차 [가나다라마]' 2>/dev/null | grep -v '^docs/superpowers/' || true)"
check "refs: none dangling"                "[ -z \"\$STALE\" ]"

# 서브에이전트에 에이전트원칙이 실린다고 가정하지 않는다는 문장은 `LENS-ALLOWED` 조항 안에 있다.
check "canon: 실린다고 가정하지 않는 조항이 검증 절에 있다" "sec_has '$CANON' '검증' '**\`LENS-ALLOWED\`'"

# --- lens-contract: 읽기 전용 렌즈를 띄우는 호출자 셋이 같은 계약에 닿는다 ---
# 전에는 셋이 규율 넷을 각자 적고 이 검사가 그 사본들을 맞춰 세웠다. 사본이라 갈라졌다 — 한 곳에서
# 재시도 금지 항목만 빠져 그 경로가 금지된 재시도를 허용한 채 오래 남았고, DESIGN-NOTES 쪽은 넷 중
# 둘만 갖고 있었다. 지금은 `dispatching-lenses`가 규율을 소유하고 나머지는 가리키기만 한다.
# 소유자가 규율을 갖는지와 다른 문서가 베끼지 않는지는 `test_docs_drift.sh`가 본다. 여기서는 호출자
# 셋이 그 소유자에 닿는지와 런타임 중립만 본다.
echo "[lens-contract] callers reach the canon-path rules and stay runtime-neutral"
for s in review-specs review-docs nested-orchestration; do
  F="$HERE/skills/$s/SKILL.md"
  check "$s: 규율 소유자에 닿는다"          "grep -qF 'dispatching-lenses' '$F'"
  # 런타임 중립: 특정 에이전트 종류 이름과 관리 디렉터리 절대 경로를 박지 않는다.
  check "$s: Claude 전용 종류 이름 없음"    "! grep -qF 'Explore' '$F'"
  check "$s: 관리 디렉터리 절대경로 없음"   "! grep -qF '~/.claude/disciplined-coder/' '$F'"
done
# 렌즈 목록은 손으로 적지 않고 디렉터리에서 도출한다 — 렌즈를 더해도 사람이 목록을 맞출 필요가 없다.
for D in "$HERE"/skills/lens-*/; do
  l="$(basename "$D" | sed 's/^lens-//')"
  F="$D/SKILL.md"
  check "lens-$l: SKILL.md 존재"        "[ -f '$F' ]"
  check "lens-$l: principles_applied"   "grep -qF 'principles_applied' '$F'"
  # 렌즈는 이 필드가 언제 필요한지를 스스로 규정하지 않고 aggregating-lenses 로 넘긴다. 예전에는 일곱 파일이
  # 같은 문단을 복제해 지켰는데, 그 사이 aggregating-lenses 의 스키마 블록이 이 필드를 무조건 필수로 보이게 적어
  # 필수 여부가 두 곳에서 갈렸다. 지금은 aggregating-lenses 한 곳만 규정하고 렌즈는 가리키기만 한다.
  # principles_applied 를 부르는 줄이 소유자 이름과 계약 절 이름을 함께 가리키는지 본다.
  check "lens-$l: 규칙을 aggregating-lenses 로 넘긴다" "grep -qF -- '\`aggregating-lenses\`' <<<\"\$(grep -F -- '\`principles_applied\`' '$F' | grep -F -- '리뷰 산출물 계약')\""
done
check "aggregating-lenses: 출력 스키마 절이 principles_applied 를 따로 다룬다" "sec_has_id '$HERE/skills/aggregating-lenses/SKILL.md' '출력 스키마' principles_applied"

# --- 매니페스트 version 계약 ---
# Claude 매니페스트는 version을 비워 커밋 SHA 기반 자동 업데이트를 유지한다(domain-plugin).
# 값을 넣으면 버전 문자열 비교로 전환돼 값을 올리지 않는 한 새 커밋이 배포되지 않는다. 한 번 넣었다
# 되돌린 이력이 있어 사람 기억에 맡기지 않고 테스트로 고정한다.
check "Claude 매니페스트에 version 없음"  "! grep -qE '\"version\"[[:space:]]*:' '$HERE/.claude-plugin/plugin.json'"

echo "----"; echo "PASS=$pass FAIL=$fail"; [ "$fail" -eq 0 ]
