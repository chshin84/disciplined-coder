#!/usr/bin/env bash
# 문서의 렌즈 열거가 진실과 어긋나지 않는지 검증. 계약: FAIL=0 (매직넘버 금지 — 개수는 테스트가 센다).
#
# 두 불변식을 단언한다. 어느 쪽도 개수를 박지 않고 두 집합의 일치를 본다.
#   집계 태깅   — meta-aggregate가 source 값으로 적은 렌즈 == 같은 디렉터리 집합
# 두 번째의 권위 있는 출처는 호출자 스킬이고 산문의 열거는 그 캐시다(SSOT).
#
# 인지한 대가: 앵커가 산문 문구라 표현을 고치면 내용이 멀쩡해도 실패한다. 조용히 통과하는 것보다
# 낫다고 보아 그대로 둔다(FAIL-LOUD). 실패하면 앵커를 새 문구로 맞추면 된다.
set -euo pipefail
HERE="$(cd "$(dirname "$0")/.." && pwd)"
README="$HERE/README.md"
CALLER="$HERE/skills/domain-spec-review/SKILL.md"
AGG="$HERE/skills/meta-aggregate/SKILL.md"
pass=0; fail=0
check() { if eval "$2"; then echo "  PASS: $1"; pass=$((pass+1)); else echo "  FAIL: $1"; fail=$((fail+1)); fi; }

# 진실 1 — 실제 렌즈 디렉터리에서 짧은 이름을 도출한다.
ALL="$(for d in "$HERE"/skills/lens-*/; do [ -d "$d" ] || continue; basename "$d" | sed 's/^lens-//'; done | sort)"

# 진실 2 — 호출자가 디스패치 목록에 적은 렌즈. 목록 항목은 "- `lens-이름` — 설명" 꼴이다.
DISPATCH="$(grep -oE '^- `lens-[a-z-]+`' "$CALLER" | sed 's/^- `lens-//; s/`$//' | sort)"



# 캐시 3 — meta-aggregate가 집계 항목의 출처를 태깅하는 렌즈 이름 열거.
AGG_LINE="$(grep -F '"source"' "$AGG" || true)"
AGGSET="$(printf '%s' "$AGG_LINE" | sed -n 's/.*"source"[[:space:]]*:[[:space:]]*"\([^"]*\)".*/\1/p' | tr '|' '\n' | sed 's/^ *//; s/ *$//' | grep -v '^$' | sort || true)"

# 캐시 4 — meta-aggregate가 「공통 계약의 예외」로 적은 렌즈 이름 열거. 손으로 목록을 베끼지
# 않고 정본 절에서 뽑는다. 그 절이 없어지거나 이름이 바뀌면 EXC_LENSES가 비어 아래 단언이
# 예외 없이 다섯 렌즈 전부에게 강도 그대로의 대조를 요구한다.
EXC_LENSES="$(awk '/^## 공통 계약의 예외/{f=1; next} /^## /{f=0} f' "$AGG" | grep -oE '`lens-[a-z-]+`' | tr -d '`' | sort -u || true)"
is_exc() { printf '%s\n' "$EXC_LENSES" | grep -qxF "$1"; }

echo "[앵커가 실제로 잡히는가 — 못 잡으면 아래 단언이 무의미해진다]"
check "렌즈 디렉터리가 하나 이상 있다"          "[ -n \"\$ALL\" ]"
check "호출자 디스패치 목록을 읽어냈다"          "[ -n \"\$DISPATCH\" ]"


echo "[집계 태깅 == 실제 디렉터리]"
# meta-aggregate의 출력 스키마가 이슈의 출처를 렌즈 이름으로 태깅한다. 그 열거도 렌즈가 늘면 낡는다.
check "meta-aggregate source 줄을 찾았다"        "[ -n \"\$AGG_LINE\" ]"
check "meta-aggregate가 렌즈 전부를 태깅한다"    "[ \"\$AGGSET\" = \"\$ALL\" ]"
if [ "$AGGSET" != "$ALL" ]; then
  echo "    디렉터리      : $(printf '%s' "$ALL" | tr '\n' ' ')"
  echo "    meta-aggregate: $(printf '%s' "$AGGSET" | tr '\n' ' ')"
fi


echo "[산출물 계약 — meta-aggregate가 소유한다]"
check "계약이 consequence 를 필수로 적는다"     "grep -qF 'consequence' \"\$AGG\""
check "계약이 evidence 를 필수로 적는다"        "grep -qF 'evidence' \"\$AGG\""
check "계약이 read 필드를 정의한다"             "grep -qF '\"read\"' \"\$AGG\""
check "계약이 빈손을 정상으로 적는다"           "grep -qF '빈 배열인 것은 정상' \"\$AGG\""
check "계약에 등급 라벨이 없다"                 "! grep -qF 'severity' \"\$AGG\""
check "spec 리뷰에 결정 단계가 없음을 적는다"   "grep -qF 'spec 리뷰에서는 결정 단계가 없다' \"\$AGG\""

check "정본에서 공통 계약 예외 렌즈를 뽑았다" "[ -n \"\$EXC_LENSES\" ]"

echo "[렌즈 계약 — 등급 없음, 근거 필수]"
for d in "$HERE"/skills/lens-*/; do
  n="$(basename "$d")"; f="$d/SKILL.md"
  check "$n 에 등급 라벨이 없다"          "! grep -qF 'severity' \"$f\""
  if is_exc "$n"; then
    check "$n 은 공통 계약 예외라 consequence 를 요구하지 않는다" "! grep -qF 'consequence' \"$f\""
  else
    check "$n 이 consequence 를 요구한다"   "grep -qF 'consequence' \"$f\""
  fi
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
SPECM="$HERE/hooks/_spec_marker.sh"
echo "[훅 안내문 — 마커를 개선보다 먼저, 문안은 한 곳에]"
check "공유 안내문이 마커 선기록을 지시한다"     "grep -qF '마커를 먼저 남기고' \"\$SPECM\""
check "PostToolUse 훅이 공유 안내문을 쓴다"       "grep -qF 'SPEC_REVIEW_INSTRUCTION' \"\$PTU\""
check "Stop 훅이 공유 안내문을 쓴다"              "grep -qF 'SPEC_REVIEW_INSTRUCTION' \"\$STOPH\""
check "훅이 안내문을 따로 베끼지 않는다"          "! grep -qF '마커를 먼저 남기고' \"\$PTU\" \"\$STOPH\""

echo "[리뷰 절차 — 렌즈를 한 번씩 띄우고 결과를 한데 모은다]"
DOCS="$HERE/skills/domain-docs/SKILL.md"
RUNTIME2="$HERE/skills/domain-llm-runtime/SKILL.md"
READMEF="$HERE/README.md"
check "spec 리뷰가 회차 규칙을 다시 선언하지 않는다" "! grep -qF '렌즈마다 한 번씩만 띄운다' \"\$CALLER\""
check "spec 리뷰가 회차 규칙 소유자를 가리킨다" "grep -qF '한 번만 띄우는 렌즈의 규율' \"\$CALLER\""
check "옛 2회 표집 규정이 남아 있지 않다"     "! grep -qF '2회씩' \"\$CALLER\""
check "렌즈별 결과를 한데 모으는 것은 남는다" "grep -qF '한데 모아 관리하는 것은 그대로다' \"\$CALLER\""
check "문서 검진은 한 번씩만 띄운다"          "grep -qF '렌즈는 한 번씩만 띄운다' \"\$DOCS\""
check "런타임은 한 번씩만 부른다"             "grep -qF '렌즈는 한 번씩만 부른다' \"\$RUNTIME2\""
check "런타임이 회차 수를 다시 정하지 않는다" "grep -qF '여기서 다시 정하지 않는다' \"$RUNTIME2\""
check "문서 검진도 다시 정하지 않는다"        "grep -qF '여기서 다시 정하지 않는다' \"$DOCS\""

echo "[이름은 명사구, 주장은 첫 문장 — 정본과 가독성 렌즈]"
CANON="$HERE/agent-principles.md"
READ2="$HERE/skills/lens-readability/SKILL.md"
# 상세는 writing-korean 이 소유하고 정본은 조항만 담는다. 양쪽을 함께 붙든다.
WK="$HERE/skills/writing-korean/SKILL.md"
check "상세 스킬이 있다"                     "[ -f \"$WK\" ]"
check "상세가 이름 자리를 명사구로 정한다"   "grep -qF '이름을 붙이는 곳은 명사구로 쓰고 주장은 본문으로 내린다' \"$WK\""
check "상세가 말끝 통일을 정한다"            "grep -qF '한 표·한 목록·한 다이어그램·한 차트 안에서는 말끝을 하나로 맞춘다' \"$WK\""
check "상세가 넓은 말 대신 좁은 말을 시킨다" "grep -qF '넓은 말보다 좁은 말을 쓴다' \"$WK\""
check "정본이 그 상세를 가리킨다"            "grep -qF 'writing-korean' \"$CANON\""
check "정본이 대상을 정확히 가리키게 한다"   "grep -qF '대상의 이름을 그대로 쓴다' \"\$CANON\""
check "가독성 렌즈가 이름 형태를 본다"       "grep -qF '이름 형태' \"\$READ2\""
check "가독성 렌즈가 형태 섞임을 본다"       "grep -qF '형태 섞임' \"\$READ2\""
check "가독성 렌즈 프롬프트가 고쳐 주게 한다" "grep -qF '명사구로 고쳐 주고' \"\$READ2\""
check "가독성 렌즈가 직접인용을 지킨다"     "grep -qF '직접인용' \"$READ2\""
check "그 가드가 프롬프트에도 실린다"       "grep -qF '식별자·직접인용' \"$READ2\""

echo "[검진 개시 — 묻는 자리와 건너뛰는 자리]"
check "검진을 열기 전에 제시한다"            "grep -qF '검진을 열기 전에 사용자에게 제시한다' \"\$DOCS\""
check "계약이 바뀌면 묻는다"                  "grep -qF '계약·규칙·동작 변경' \"\$DOCS\""
check "표현만 다듬었으면 건너뛴다"            "grep -qF '골랐을 뿐이면 건너뛴다' \"\$DOCS\""
check "건너뛰면 알린다"                       "grep -qF '건너뛰었다고 한 줄 알린다' \"\$DOCS\""

echo "[한 번만 띄우므로 지킬 것 — 소유자와 여섯 렌즈 프롬프트]"
check "domain-docs가 그 규칙의 소유자다"      "grep -A1 -F '## 한 번만 띄우는 렌즈의 규율' \"\$DOCS\" | grep -qF '여기가 소유자다'"
check "중첩 금지를 적는다"                    "grep -qF '렌즈는 서브에이전트를 새로 열지 않는다' \"\$DOCS\""
check "이어 묻기를 적는다"                    "grep -qF '대화 턴을' \"\$DOCS\""
check "3층 오케스트레이션 예외를 적는다"      "grep -qF '3층 오케스트레이션은 이 금지의 예외다' \"\$DOCS\""
for L in "$HERE"/skills/lens-*/SKILL.md; do
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
check "문서 검진 기록은 처리 결과를 뺀다"    "grep -qF '무엇을 고쳤고 무엇을 넘겼는지는 적지 않는다' \"\$DOCS\""
check "spec 리뷰 기록은 처리 결과를 뺀다"    "grep -qF '어떻게 처리했는지는 담지 않는다' \"\$CALLER\""
check "대신 근거를 설계 문서 본문에 적는다"   "grep -qF '근거를 검토 대상 문서 본문에 적는다' \"\$CALLER\""
# 이름 규칙은 domain-docs 가 소유한다. 호출자에게 같은 문구를 요구하면 검사가 복제를 강제한다.
check "기록 이름 규칙을 소유자가 적는다"     "grep -qF '-review-2.md' \"\$DOCS\""
check "호출자는 그 규칙의 소유자를 가리킨다" "grep -qF 'domain-docs' \"\$CALLER\""
check "원본을 받는 즉시 저장한다"            "grep -qF '받는 즉시' \"\$CALLER\""
check "원본을 같은 이름 폴더에 둔다"          "grep -qF '같은 이름의 폴더' \"\$CALLER\""
check "런타임이 기록 제외 이유를 적는다"      "grep -qF '사용자 입력이 로그로' \"\$RUNTIME2\""

echo "[합치기와 다시 리뷰]"
check "합칠 때 세 기준으로 거른다"           "grep -qF '근거가 서 있는지만 묻는다' \"\$CALLER\""
check "기능적 변화면 다시 리뷰한다고 적는다"  "grep -qF '기능적 변화' \"\$CALLER\""
check "다시 리뷰는 매번 사용자에게 묻는다"    "grep -qF '다시 리뷰는 매번 사용자에게 묻는다' \"\$CALLER\""
check "물을 때 선택지 질문으로 묻는다"        "grep -qF '선택지가 있는 질문으로 묻는다' \"\$CALLER\""
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
for L in "$HERE"/skills/lens-*/SKILL.md; do
  n="$(basename "$(dirname "$L")")"
  if is_exc "$n"; then
    check "$n: 공통 계약 예외라 스키마 사본 대조에서 빠진다" "grep -qF '$n' \"\$AGG\""
  else
    check "$n: evidence 가 정본의 근거 형태를 담는다"    "grep -qF -- \"\$CONTRACT_EV_TAIL\" '$L'"
    check "$n: consequence 뜻풀이가 정본과 같다"         "grep -qF -- \"\$CONTRACT_CONSEQ\" '$L'"
  fi
  # 조건부 필드를 렌즈가 다시 규정하면 필수 여부가 두 곳에서 갈린다 — 가리키기만 해야 한다.
  check "$n: principles_applied 규칙을 되풀이하지 않는다" "! grep -qF '제품 런타임 구현에는 요구하지 않는다' '$L'"
done
check "정본이 principles_applied 규칙을 소유한다" "grep -qF '제품 런타임 구현에는 요구하지 않는다' \"\$MA\""

echo "[렌즈에게 정본을 알리는 법 — domain-docs 한 곳만 규율을 적는다]"
# 전에 여러 문서가 각자 적었다가 하나에서 둘이 빠져 갈라졌다. 소유자를 하나로 두고
# 나머지는 가리키기만 하게 묶는다. 앵커는 소유자의 절 제목이라 제목을 고치면 실패한다(FAIL-LOUD).
OWNER_DOC="$HERE/skills/domain-docs/SKILL.md"
OWNER_ANCHOR='## 렌즈에게 정본을 알리는 법'
# 규율 넷을 알아보는 문구. 소유자에만 있어야 한다.
RULE_MARKS=('읽기 전용 에이전트도 Read는 갖는다' '비어 있지 않은 배열' '홈 해석이 어긋나는 환경에서')
check "소유자 절이 있다" "grep -qF -- \"\$OWNER_ANCHOR\" \"\$OWNER_DOC\""
for m in "${RULE_MARKS[@]}"; do
  check "소유자가 규율을 적는다: $m" "grep -qF -- '$m' \"\$OWNER_DOC\""
done
# 가리키기만 해야 하는 문서들. 규율 문구를 다시 적으면 실패한다.
for D in "$HERE"/skills/domain-spec-review/SKILL.md "$HERE"/skills/nested-orchestration/SKILL.md; do
  # 스킬 문서는 파일 이름이 모두 SKILL.md라 부모 디렉터리로 부른다 — 안 그러면 어느 문서가 실패했는지
  # 알 수 없다(`NAME-ITEMS`).
  dn="$(basename "$D")"; [ "$dn" = "SKILL.md" ] && dn="$(basename "$(dirname "$D")")"
  check "$dn 이 소유자를 가리킨다"        "grep -qF '렌즈에게 정본을 알리는 법' '$D'"
  for m in "${RULE_MARKS[@]}"; do
    check "$dn 이 규율을 베끼지 않는다: $m" "! grep -qF -- '$m' '$D'"
  done
done

echo "[대체된 설계 문서에 superseded 표시]"
OLDSPEC="$HERE/docs/superpowers/specs/2026-08-16-review-layer-redesign-design.md"
OLDPLAN="$HERE/docs/superpowers/plans/2026-08-16-review-layer-redesign.md"
check "옛 spec 에 superseded 표시가 있다"   "grep -qF 'superseded' \"\$OLDSPEC\""
check "옛 plan 에 superseded 표시가 있다"   "grep -qF 'superseded' \"\$OLDPLAN\""

# 제거된 기능의 설계 문서에도 표시를 요구한다. 목록을 손으로 적지 않고 스캐폴드의 정리 대상
# (SCAFFOLD_STALE)에서 도출한다 — 그 목록이 "이 레포가 뜯어낸 기능"의 정본이라, 기능을 하나 더
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

# 영문 재작성 대응표는 그 재작성이 되돌려져 지금 구조와 안 맞는다. 표시가 없으면 정본이 영문인
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
# 전에는 README가 스스로 정본이라고 선언해 놓고 스캐폴드 둘이 조건을 각각 다시
# 적었다. 예외가 늘거나 조건이 바뀌면 사람이 네 곳을 손으로 맞춰야 하고, 그러면 반드시 갈라진다.
# 가리키는 절 이름도 함께 확인한다 — 전에 README 절 이름이 바뀌었는데 가리키는 쪽만 옛 이름으로 남았다.
echo "[프로젝트 파일 예외 — README 한 곳만 조건을 적는다]"
# 문서를 한 줄로 펴서 본다 — 전에는 정본에서 줄이 바뀌자 같은 문장인데도 검사가 실패했다.
flat() { tr '
' ' ' < "$1" | tr -s ' '; }
OWN_MARKS=('그 블록을 만든 기능이 없어졌으면')
COPY_MARKS=('그 블록을 만든 기능이 없어졌으면')
check "README가 예외를 열거한다"        "grep -qF -- '이 플러그인이 프로젝트 파일을 고치는 예외' \"\$README\""
check "README가 예외 조건을 소유한다"    "grep -qF -- '그 조건은 여기가 정한다' \"\$README\""
for m in "${OWN_MARKS[@]}"; do
  check "README가 조건을 적는다: $m"    "flat \"\$README\" | grep -qF -- '$m'"
done
# 이 뽑아내기는 반드시 UTF-8 로케일에서 돈다. 바이트로 보면 [^」] 가 한글 음절의 이음 바이트까지
# 걸러 내 「프로젝트 폴더에 생기는 파일」 같은 이름이 통째로 안 잡힌다(실제로 그 함정을 밟았다).
# 괄호를 떼는 것도 tr 로 하지 않는다 — tr 은 바이트를 지워 같은 이음 바이트를 가진 한글을 망가뜨린다.
EXC_SEC="$(LC_ALL=C.UTF-8 grep -oE '「[^」]*」' "$HERE/scripts/scaffold.sh" | sed 's/^「//; s/」$//' | grep -F '프로젝트 폴더' | head -1 || true)"
check "스캐폴드가 README 절을 가리킨다" "[ -n \"\$EXC_SEC\" ]"
check "그 절이 README에 실재한다"            "[ -n \"\$EXC_SEC\" ] && grep -qF \"## \$EXC_SEC\" \"\$README\""
# 정본은 이제 조건을 되풀이하지 않고 README를 가리키기만 한다. 가리키는 문장이 살아 있는지 본다.
check "정본이 README를 가리킨다"        "grep -qF -- 'README를 참고한다' \"$CANON\""

for D in "$HERE/scripts/scaffold.sh"; do
  dn="$(basename "$D")"
  check "$dn 이 README 절을 가리킨다"   "grep -qF -- '프로젝트 폴더에 생기는 파일' '$D'"
  for m in "${COPY_MARKS[@]}"; do
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
# 확인 명령을 통째로 지워도 초록인 검사가 됐다. 그래서 후보 이름을 정본에서 도출해 대조한다 —
# resolve_home이 보는 환경변수(테스트 전용 *_HOME_DIR 제외)가 README 명령에도 다 있어야 한다.
HOMESH="$HERE/scripts/_resolve_home.sh"
HOME_CANDS="$(grep -oE '\$\{(CLAUDE_CONFIG_DIR|USERPROFILE|HOME):-\}' "$HOMESH" | sed 's/^\${//; s/:-}$//' | sort -u)"
check "정본에서 홈 후보 이름을 뽑아냈다" "[ -n \"\$HOME_CANDS\" ]"
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
    check "$sn 이 가리킨 절이 있다: $sec" "printf '%s\n' \"\$HEADINGS\" | grep -qxF -- '$sec'"
  done <<EOF
$(LC_ALL=C.UTF-8 grep -oE '「[^」]*」' "$SRC" | sed 's/^「//; s/」$//; s/ *[—(].*$//; s/ *$//' | sort -u)
EOF
done
check "「」 참조를 하나 이상 찾았다" "[ '$BN' -gt 0 ]"

# (제거됨) 도메인 참고서 열거 == 실제 디렉터리 — 이 검사는 `docs/DESIGN-NOTES.md`의 트리 줄이
# 참고서를 열거하던 것을 붙들었고, 커밋 2f64d74가 그 문서를 지우면서 함께 걷혔다. 지금은 어느 문서도
# 도메인 참고서를 열거하지 않고 README가 `skills/` 디렉터리를 가리키기만 하므로 붙들 열거가 없다.
# 다시 열거하는 문서가 생기면 그때 이 가드를 되살린다.

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
# 옛 값으로 남는다. 이 레포가 오답노트에 적어 둔 매직 넘버 금지가 자기 문서에서 재현된 자리다.
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
COUNT_SCAN="$AGG $HERE/skills/lens-*/SKILL.md $HERE/skills/domain-docs/SKILL.md $CALLER $CANON $HERE/README.md"
# shellcheck disable=SC2086
NUMHIT="$(LC_ALL=C.UTF-8 grep -nE "$NUM[ ]?렌즈|렌즈[ ]?$NUMB|다른 $NUMB[ ]?(렌즈|은|는)|$NUMB[ ]?곳에" $COUNT_SCAN 2>/dev/null \
  | grep -v '개수를 산문에\|이름을 같은 줄에' \
  | LC_ALL=C.UTF-8 grep -vE "$LENS_RE" || true)"
check "개수를 적은 자리마다 이름이 함께 있다" "[ -z \"\$NUMHIT\" ]"
[ -n "$NUMHIT" ] && printf '    이름 없이 개수만 박힌 자리:\n%s\n' "$NUMHIT"

# --- 테스트 실행 명령: 앞 스크립트의 실패를 삼키지 않는다 ---
# CLAUDE.md가 실행 명령의 정본이다. 그 줄이 지워지거나 `for t in ...; do bash "$t"; done` 으로
# 되돌아가면 마지막 하나의 종료 코드만 남아 앞선 FAIL이 묻히고, 감사는 잘못된 FAIL=0을 보고한다.
echo "[테스트 실행 명령 — 앞 스크립트의 실패가 안 묻힌다]"
CMD="$HERE/CLAUDE.md"
check "CLAUDE.md가 실행 명령을 적는다"       "grep -qF -- 'for t in scripts/test_*.sh' \"\$CMD\""
check "실패를 모으는 형태다"                 "grep -qF -- 'bad=\"\$bad \$t\"' \"\$CMD\""
check "모은 결과를 마지막에 알린다"           "grep -qF -- 'FAILED:' \"\$CMD\""
# CI도 같은 명령을 돈다. CLAUDE.md와 달리 CI는 정본을 읽을 수 없어 형태를 다시 적을 수밖에 없으니,
# 적어도 그 형태가 정본과 같은 실패 처리를 하는지 붙든다. `set -e`에 맨 `bash "$t"`면 첫 실패에서
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
# 못한다(실제로 project-doc-audit 이 정본의 두 표 어디에도 없었다). 그래서 스킬 디렉터리에서 이름을
# 도출해 정본이나 도메인 목차가 그 이름을 한 번은 부르는지 본다.
echo "[스킬 등재 — 진입로에서 이름이 불린다]"
for d in "$HERE"/skills/*/; do
  sk="$(basename "$d")"
  # 진입로는 셋이다 — 정본이 이름을 부르거나, 다른 스킬이 부르거나, 렌즈면 정본의 묶음 표기에 든다.
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
  check "$sk 을 정본이나 다른 스킬이 부른다" "[ '$named' = 1 ]"
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
# 정본은 조항만 담고, writing-korean 이 상세를 담으며, lens-readability 가 그것을 열어 대조한다.
# 전에 정본을 줄이면서 조항을 스킬로 통째로 내렸더니 렌즈가 가리키는 근거가 정본에서 사라졌는데,
# 검사가 새 자리를 따라가 버려 끊긴 것을 못 잡았다. 그래서 셋을 한 줄로 함께 붙든다.
echo "[규칙 출처] 정본 → writing-korean → lens-readability 가 이어져 있다"
RDB_L="$HERE/skills/lens-readability/SKILL.md"
check "정본에 이름 자리 조항이 있다"     "grep -qF '이름을 붙이는 위치에만 명사구로 쓰고' \"$CANON\""
check "정본이 상세 소유자를 가리킨다"    "grep -qF 'writing-korean' \"$CANON\""
check "렌즈가 기준 문서를 가리킨다"      "grep -qF 'writing-korean' \"$RDB_L\""
check "렌즈 프롬프트도 그 파일을 읽힌다" "grep -m1 '^- system:' \"$RDB_L\" | grep -qF 'writing-korean'"
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
# 마켓플레이스 카드는 설치 전 사용자가 보는 첫 문안인데, 걷어낸 solved-log 스캐폴딩을 한동안 계속
# 광고했다. 같은 사실을 두 파일이 각자 적으면 반드시 갈라지므로, 플러그인 매니페스트를 정본으로
# 두고 마켓플레이스 항목이 그것과 글자 그대로 같은지 확인한다(`SSOT`).
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
# 값을 적지 말고 상수가 사는 자리를 가리키게 한다(`SSOT`).
echo "[README] 잠금 시간을 값으로 적지 않고 상수 자리를 가리킨다"
check "README가 잠금 시간을 베끼지 않는다" "! grep -qE '잠금(은|이)? *[0-9]+초' '$HERE/README.md'"
check "README가 상수 자리를 가리킨다"      "grep -qF '_managed_block.sh' '$HERE/README.md'"

# --- 렌즈에게 정본을 알리는 법: domain-docs 한 곳만 내용을 갖는다 ---
# 다른 스킬은 그 절을 가리키기만 한다. 첫 항목 문장이 다른 스킬에 나타나면 베낀 것이다.
echo "[렌즈에게 정본을 알리는 법] 다른 스킬이 내용을 베끼지 않는다"
TELL_SENT='정본 경로를 프롬프트에 넣어 렌즈가 직접 읽게 한다'
check "domain-docs 가 그 문장을 갖는다" "grep -qF -- '$TELL_SENT' \"$HERE/skills/domain-docs/SKILL.md\""
for f in "$HERE"/skills/*/SKILL.md; do
  case "$f" in */domain-docs/*) continue ;; esac
  check "$(basename "$(dirname "$f")") 이 베끼지 않는다" "! grep -qF -- '$TELL_SENT' '$f'"
done

# --- 금지 표현: 살아 있는 문서에 남지 않는다 ---
# 목록을 검사에 손으로 적지 않고 writing-korean 의 「금지 표현」 표에서 도출한다. 그 표가 정본이라
# 낱말을 더하면 이 검사가 함께 따라온다. 대상에서 빼는 것이 둘이고 이유가 서로 다르다 —
# writing-korean 자신은 그 낱말을 정의하는 정본이라 빼고, docs/superpowers/ 아래는 소비하고 지우는
# 문서(spec·plan·인수인계)와 그때 찍은 기록(리뷰·되돌린 대응표)이라 살아 있는 문서가 아니어서 뺀다.
# 뒤의 제외는 project-doc-audit 의 「대상 아님」과 같은 규정이다.
WK="$HERE/skills/writing-korean/SKILL.md"
BANLIST="$(awk '/^## 금지 표현/{f=1; next} f && /^## /{exit} f' "$WK" | grep -oE '^[|] `[^`]+`' | sed 's/^[|] `//; s/`$//')"
BAN_DOCS="$(cd "$HERE" && git ls-files '*.md' | grep -v '^docs/superpowers/' | grep -v '^skills/writing-korean/SKILL.md')"
echo "[금지 표현] 살아 있는 문서에 남지 않는다"
check "금지 목록을 정본에서 도출했다" "[ -n \"\$BANLIST\" ]"
check "검사 대상 문서를 모았다"       "[ -n \"\$BAN_DOCS\" ]"
# 앵커가 실제로 잡히는지 먼저 본다 — 목록이나 대상이 비면 아래 단언이 모두 근거 없이 통과한다.
BAN_SELFTEST="$(cd "$HERE" && grep -lF -- '금지 표현' skills/writing-korean/SKILL.md || true)"
check "정본에 금지 표현 절이 있다"     "[ -n \"\$BAN_SELFTEST\" ]"
BANHIT=""
while IFS= read -r w; do
  [ -n "$w" ] || continue
  hit=""
  for f in $BAN_DOCS; do
    if LC_ALL=C.UTF-8 grep -qF -- "$w" "$HERE/$f"; then hit="$hit $f"; fi
  done
  check "금지 표현 '$w' 이 없다" "[ -z '$hit' ]"
  [ -n "$hit" ] && BANHIT="$BANHIT
    $w:$hit"
done <<EOF
$BANLIST
EOF
[ -n "$BANHIT" ] && printf '    남은 금지 표현:%s
' "$BANHIT"

# --- 리뷰·감사 기록은 찍은 뒤 고치지 않는다 ---
# 기록은 그 회차에 무엇을 보았는지의 증거라, 뒤에 고치면 회차 사이 대조가 무너진다. 그래서 새 기록을
# 더하는 것만 허용하고 있는 기록의 수정과 삭제는 거부한다. 경계 날짜는 이 규칙이 들어온 날이다 —
# 그 전의 수정 하나(0ce107c)는 규칙이 없던 때의 일이라 소급하지 않는다.
echo "[리뷰 기록은 찍은 뒤 고치지 않는다]"
RVDIR="docs/superpowers/reviews"
check "기록 폴더에 기록이 하나 이상 있다" "ls \"\$HERE/\$RVDIR\"/*.md >/dev/null 2>&1"
RV_TREE="$(cd "$HERE" && git status --porcelain --untracked-files=all -- "$RVDIR" 2>/dev/null | grep -vE '^(\?\?|A ) ' || true)"
[ -n "$RV_TREE" ] && printf '    작업 트리에서 고치거나 지운 기록:
%s
' "$RV_TREE" | sed 's/^/      /'
check "작업 트리에 고치거나 지운 기록이 없다" "[ -z \"\$RV_TREE\" ]"
RV_HIST="$(cd "$HERE" && git log --since=2026-09-02 --diff-filter=MD --name-only --format= -- "$RVDIR" 2>/dev/null | grep -v '^$' || true)"
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

echo "----"; echo "PASS=$pass FAIL=$fail"; [ "$fail" -eq 0 ]
