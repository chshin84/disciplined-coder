#!/usr/bin/env bash
# 문서의 렌즈 열거가 진실과 어긋나지 않는지 검증. 계약: FAIL=0 (매직넘버 금지 — 개수는 테스트가 센다).
#
# 아래 불변식을 단언한다. 개수를 박지 않고 두 집합의 일치를 본다.
#   카테고리 표 — lens-review 「카테고리와 렌즈」 표의 에이전트 ⊆ agents/lens-*.md 집합
# 권위 있는 출처는 에이전트 정의 디렉터리이고 산문의 열거는 그 캐시다. 렌즈 출력 칸은
# scripts/test_lens_contract.sh 가 계약 파일과 정의의 출력 예시로 본다.
#
# 앵커는 산문 문장이 아니라 안정된 열쇠다. 규칙이 있는지는 조항 ID(`ASK-OPTIONS` 같은 것)와 절 제목으로,
# 소유는 그 절 안의 소유 선언으로, 포인터는 소유자 이름과 절 이름이 한 줄에 함께 있는지로 본다.
# 함수는 scripts/_doc_keys.sh 에 있다. 문장 끝이나 낱말을 고쳐도 열쇠가 그대로면 통과하고, ID·제목·
# 포인터가 사라지거나 이름이 바뀌면 실패한다. 복제 금지 검사는 되도록 구조(사본 쪽에 그 절 제목이나
# 소유 선언이 없다)로 보고, 구조로 못 적는 것만 가장 짧은 고유 조각을 남겼다. 그런 곳에는 그 자리에
# '짧은 조각' 이라고 적어 두었다. 렌즈 프롬프트처럼 제목이 없는 한 줄 페이로드도 짧은 조각으로 본다.
# `# 핵심 계약:` 표시가 달린 검사는 v2 정리에서 지우지 않는다.
set -euo pipefail
HERE="$(cd "$(dirname "$0")/.." && pwd)"
. "$HERE/scripts/_doc_keys.sh"   # doc_sec·has_sec·sec_has·sec_has_id·owns_sec·points_to
# 픽스처는 모두 이 뿌리 아래에 만들고 끝나면 통째로 지운다. mktemp 가 TMPDIR 을 따르므로 아래의
# mktemp 호출과 이 검사가 부르는 스크립트의 임시 파일이 모두 여기로 온다.
TEST_TMP="$(mktemp -d)"; trap 'rm -rf "$TEST_TMP"' EXIT; export TMPDIR="$TEST_TMP"
README="$HERE/README.md"
CALLER="$HERE/skills/lens-review/SKILL.md"
. "$HERE/scripts/_test_check.sh"
. "$HERE/scripts/_json_valid.sh"
. "$HERE/hooks/_banned_words.sh"
# 금지어 원본 표를 한 번 읽어 둔다. 상시 보기 검사와 그 보기를 쓰는 뒤 검사가 같은 결과를 본다.
BW="$(mktemp -d)"
banned_parse "$HERE/korean-banned-words.md" "$BW/pairs" "$BW/toks" "$BW/excl" "$BW/scopes"
VIEW="$BW/view.md"; banned_view "$HERE/korean-banned-words.md" > "$VIEW" || true

# 진실 — 렌즈 에이전트 정의에서 짧은 이름을 도출한다.
ALL="$(for f in "$HERE"/agents/lens-*.md; do [ -f "$f" ] || continue; basename "$f" .md | sed 's/^lens-//'; done | sort)"

echo "[lens-review — 리뷰 스킬 셋을 하나로 합친 스킬]"
# 렌즈 실행·spec 리뷰·문서 검진을 맡던 스킬 셋(합계 27,043자)을 한 스킬로 합쳤다(spec 2026-11-13-v2-rebuild-design
# 「스킬」). 본문은 frontmatter 를 뺀 글자 수로 센다.
LR="$CALLER"
MDOCS="$HERE/skills/managing-docs/SKILL.md"
body_chars() { awk 'NR==1 && /^---\r?$/ { f=1; next } f==1 && /^---\r?$/ { f=2; next } f!=1' "$1" | LC_ALL=C.UTF-8 wc -m | tr -d ' '; }
check "lens-review 본문이 8,000자 이하다" "[ -f \"\$LR\" ] && [ \"\$(body_chars \"\$LR\")\" -le 8000 ]"
check "lens-review 가 세 진입점 절을 가진다" "has_sec \"\$LR\" '직접 요청' && has_sec \"\$LR\" '설계 문서' && has_sec \"\$LR\" '전달 문서'"
# 1차 디펜스가 근거 없이 지적을 기각하면 리뷰가 무력해지므로, 기각마다 반박한 원문 위치를 적는 칸을 둔다.
check "lens-review 기록 형식에 기각 근거 칸이 있다" "sec_has \"\$LR\" '기록' '| 기각 근거 |'"
check "managing-docs 에 기록 파일 이름 규칙 절이 있다" "owns_sec \"\$MDOCS\" '기록 파일 이름 규칙' && sec_has \"\$MDOCS\" '기록 파일 이름 규칙' '-review-2.md'"
SPEC_INSTR="$( . "$HERE/hooks/_spec_marker.sh"; printf '%s' "${SPEC_REVIEW_INSTRUCTION:-}" )"
check "spec 리뷰 지시문이 lens-review 를 가리킨다" "grep -qF 'lens-review' <<<\"\$SPEC_INSTR\""
LR_MISS=""
while IFS= read -r n; do
  [ -n "$n" ] || continue
  [ -f "$HERE/agents/$n.md" ] || LR_MISS="$LR_MISS $n"
done <<EOF
$( [ -f "$LR" ] && doc_sec "$LR" '카테고리와 렌즈' | grep -oE '`lens-[a-z-]+`' | tr -d '`' | sort -u )
EOF
check "lens-review 카테고리 표의 렌즈가 모두 실재한다" "[ -f \"\$LR\" ] && [ -z \"\$LR_MISS\" ]"
# 렌즈에 기준으로 넘기는 파일(CRITERIA)이 없으면 렌즈가 기준 없이 판정한다. 경로는 저장소 뿌리나 스킬 폴더 기준이다.
CR_MISS=""
while IFS= read -r p; do
  [ -n "$p" ] || continue
  [ -f "$HERE/$p" ] || [ -f "$(dirname "$LR")/$p" ] || CR_MISS="$CR_MISS $p"
done <<EOF
$( [ -f "$LR" ] && doc_sec "$LR" '카테고리와 렌즈' | grep -oE '`[A-Za-z0-9_./-]+\.md`' | tr -d '`' | sort -u )
EOF
[ -n "$CR_MISS" ] && echo "    없는 기준 파일:$CR_MISS"
check "lens-review 가 기준으로 넘기는 파일이 모두 실재한다" "[ -f \"\$LR\" ] && [ -z \"\$CR_MISS\" ]"
# 대조 렌즈는 문서 타입 표를 받았을 때만 doc_type 을 판정한다. doc 모드에 표를 넘기지 않으면 판정이 늘 비어 있다.
check "lens-review 가 대조 렌즈에 문서 타입 표를 넘긴다" "sec_has \"\$LR\" '카테고리와 렌즈' 'skills/managing-docs/SKILL.md'"
# 렌즈를 넷으로 줄인 결정은 옛 렌즈의 단독 발견을 놓치는지 측정하지 않았다. 비교 결과를 기록 칸으로 모은다.
check "lens-review 기록에 옛 렌즈 비교 칸이 있다" "sec_has \"\$LR\" '기록' '옛 렌즈 비교'"
# 다른 프로젝트에서 문체 공격 항목을 넘길 수 있게 스캐폴드가 PC 전역 폴더에 사본을 둔다.
check "스캐폴드 사본 목록에 문체 공격 항목이 있다" "( . \"\$HERE/scripts/_scaffold_common.sh\"; grep -qF 'skills/lens-review/references/style-attacks.md=' <<<\"\$SCAFFOLD_REFS\" )"

# 지운 스킬 이름을 가리키는 문서가 남으면 열리지 않는 스킬을 찾는다. 살아 있는 문서는 실리는 지시문과
# 실행 코드(원칙·스킬·에이전트·훅·스크립트·워크플로·커맨드·설정)와 참고서다. 공통 제외 목록은
# REMOVED_REF_EXCLUDES 가 소유하고, 참고서의 「v1 조항 근거」 절은 v1 의 근거를 보관하므로 뺀다. 이 검사
# 파일은 찾을 이름을 적고 있어 뺀다. evals/ 의 평가 과제와 docs/html-reports/ 는 그때의 입력과 결과다.
REMOVED_SKILLS_RE='dispatching-lenses|review-specs|review-docs'
ref_excluded() {  # $1=레포 상대 경로 → 공통 제외 목록에 들면 참
  local e
  for e in "${REMOVED_REF_EXCLUDES[@]}"; do
    case "$e" in
      */) [[ $1 == "$e"* ]] && return 0 ;;
      *) # shellcheck disable=SC2053
         [[ $1 == $e ]] && return 0 ;;
    esac
  done
  return 1
}
removed_name_hits() {  # $1=파일 → 지운 이름이 든 줄 번호(「v1 조항 근거」 절 제외)
  awk '{ sub(/\r$/, "") } /^## v1 조항 근거/ { s=1; next } s && /^## / { s=0 } !s { print NR ":" $0 }' "$1" \
    | grep -E "$REMOVED_SKILLS_RE" | cut -d: -f1 | tr '\n' ' ' || true
}
RN_FX="$TEST_TMP/removed-names.md"
printf '%s\n' '`review-docs` 를 따른다' '## v1 조항 근거' '`dispatching-lenses` 의 근거' '## 다음' '`review-specs`' > "$RN_FX"
check "지운 이름 검사가 v1 절 밖의 줄만 잡는다" "[ \"\$(removed_name_hits \"\$RN_FX\")\" = '1 5 ' ]"
RN_BAD=""
while IFS= read -r f; do
  [ -f "$HERE/$f" ] || continue
  case "$f" in scripts/test_docs_drift.sh) continue ;; esac
  ref_excluded "$f" && continue
  h="$(removed_name_hits "$HERE/$f")"
  [ -n "$h" ] && RN_BAD="$RN_BAD [$f: $h]"
done <<EOF
$(cd "$HERE" && git ls-files --cached --others --exclude-standard -- agent-principles.md korean-banned-words.md skills agents hooks scripts workflows commands .claude/settings.json 'docs/domain-*.md')
EOF
[ -n "$RN_BAD" ] && printf '    지운 스킬 이름이 남은 곳:%s\n' "$RN_BAD"
check "지운 스킬 이름(dispatching-lenses·review-specs·review-docs)을 가리키는 살아 있는 문서가 없다" "[ -z \"\$RN_BAD\" ]"

RUNTIME="$HERE/skills/review-llm-calls/SKILL.md"
echo "[런타임 — 등급이 아니라 type 으로 행동을 정한다]"
check "조립 절이 type 값으로 accept·escalate 를 가른다" "sec_has_id \"\$RUNTIME\" '조립' type && sec_has_id \"\$RUNTIME\" '조립' accept && sec_has_id \"\$RUNTIME\" '조립' escalate"

echo "[이름은 명사구, 주장은 첫 문장 — 에이전트원칙과 가독성 렌즈]"
CANON="$HERE/agent-principles.md"
# 문서 타입과 수명, 읽기 위한 문서의 제목 규칙은 스킬 managing-docs 가 소유한다. 타입마다 무엇이
# 강제하는지는 프로젝트마다 다르므로 그 칸만 저장소 CLAUDE.md 가 갖는다.
MDOCS="$HERE/skills/managing-docs/SKILL.md"
TYPE_TBL="$HERE/CLAUDE.md"
# 에이전트원칙이 지시를 소유하고 두 참고서가 같은 조항 ID 로 근거를 단다. 「행동」 절의 조항은
# docs/domain-discipline.md 에, 「출력」 절의 조항은 docs/domain-korean.md 에 정확히 `### \`ID\`` 인
# 제목 줄이 있어야 한다. 제목 뒤에 설명이 붙은 절(` (v1)`·`(원칙에서 내림)`)은 세지 않는다.
# 방향은 원칙 → 참고서 하나다. v1 은 반대 방향과 문장 복제 금지도 봤는데, v2 에서 참고서가 v1 조항
# 근거를 계속 보관하므로 반대 방향 검사를 지웠다(spec 2026-11-13-v2-rebuild-design 「버리는 검사」).
WK="$HERE/docs/domain-korean.md"
DC_WK="$HERE/docs/domain-discipline.md"
clause_ref_missing() {  # $1=에이전트원칙 → 근거 절이 없는 ID 를 공백으로 이은 글
  local sec ref id miss=""
  for sec in 행동 출력; do
    if [ "$sec" = 행동 ]; then ref="$DC_WK"; else ref="$WK"; fi
    for id in $(awk -v s="## $sec" '{ sub(/\r$/, "") } $0 == s { f=1; next } /^## / { f=0 } f' "$1" \
                | grep -oE '^- \*\*`[A-Z][A-Z0-9-]*`\*\*' | grep -oE '[A-Z][A-Z0-9-]+' || true); do
      grep -qxF "### \`$id\`" "$ref" || miss="$miss $id"
    done
  done
  printf '%s' "${miss# }"
}
REF_MISS="$(clause_ref_missing "$CANON")"
[ -n "$REF_MISS" ] && printf '    참고서에 근거 절이 없는 조항: %s\n' "$REF_MISS"
check "참고서가 원칙의 모든 조항 ID 로 근거를 단다" "[ -z \"\$REF_MISS\" ]"
# 자기시험 — 「행동」 절에 가짜 조항을 넣은 사본에서 그 ID 가 나와야 한다. 안 나오면 검사가 무의미하다.
CANON_FAKE="$(mktemp)"; awk '{ print } $0 == "## 행동" { print ""; print "- **`FAKE-ID`** — x" }' "$CANON" > "$CANON_FAKE"
check "근거 검사가 가짜 조항을 잡는다" "[[ \" \$(clause_ref_missing '$CANON_FAKE') \" == *' FAKE-ID '* ]]"
check "에이전트원칙이 그 상세를 가리킨다"            "grep -qF 'domain-korean' \"$CANON\""
check "에이전트원칙이 그 참고서를 가리킨다"   "grep -qF 'domain-discipline' \"$CANON\""

echo "[소유 표] 소유는 하나뿐이고 나머지는 가리킨다"
# 소유 선언을 데이터 파일에 적지 않고 문서에서 도출한다. 자기 소유를 밝히는 문장은
# 「이 <무엇>은 여기가 소유한다」 한 꼴이고, 그 문장이 놓인 절 제목이 소유 표의 키다. 다른 절을
# 가리키는 문장은 이 꼴을 쓰지 않으므로 포인터가 소유자로 잡히지 않는다.
# 전에는 「렌즈에게 에이전트원칙을 알리는 법」 하나에만 이 검사가 걸렸고 가리킬 문서 셋도 손으로 적혀
# 있었다. 넷째 문서가 복제하면 검사가 지나쳤다. 이제 소유자도 대상도 도출한다.
# 살아 있는 문서 목록은 아래 두 구획(소유 표·대구 한도)이 함께 쓴다. 한 번만 뽑는다.
# 앞으로도 읽히고 고쳐질 문서만이다. 스펙과 계획과 지난 기록과 인수인계는 그때의 판단을 남긴 것이라 뺀다.
# evals/ 아래 평가 과제는 일부러 위반을 담은 시험 자료라 뺀다. 머리 12줄에 superseded 가 있으면 대체된
# 설계 문서라 뺀다. 목록을 손으로 적지 않고 git 색인에서 도출한다.
LIVE_DOCS="$(cd "$HERE" && git ls-files '*.md' | LC_ALL=C awk '
  /^docs\/superpowers\// || /^evals\// || /(^|\/)HANDOFF-[^\/]*$/ { next }
  {
    f = $0; hit = 0
    for (i = 0; i < 12 && (getline line < f) > 0; i++) if (tolower(line) ~ /superseded/) { hit = 1; break }
    close(f)
    if (!hit) print f
  }')"
OWN_DOCS="$LIVE_DOCS"
# 문서마다 awk·grep 을 따로 띄우지 않고 awk 한 번으로 모든 문서를 읽는다. 문서 경로는 레포 상대다.
OWN_TSV="$(cd "$HERE" && awk '
    FNR == 1 { title = "" }
    /^#{1,3} / { title=$0; sub(/^#+ /, "", title) }
    /여기가 소유한다/ { if (title != "") print title "\t" FILENAME }' $OWN_DOCS | sort || true)"
# 앵커 자가시험 — 목록이 비면 아래 단언이 모두 근거 없이 통과한다.
check "알려진 소유자가 표에 있다" "printf '%s' \"\$OWN_TSV\" | grep -qF '통합과 1차 디펜스'"
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
    :  # 경로가 실재하는지는 「문서가 가리킨 경로가 실재한다」가 본다
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

echo "[대체된 설계 문서에 superseded 표시]"
OLDSPEC="$HERE/docs/superpowers/specs/2026-08-16-review-layer-redesign-design.md"
# 핵심 계약: superseded 표시 — 결함 주입: 대체된 spec 하나의 표시를 지운다
check "옛 spec 에 superseded 표시가 있다"   "grep -qF 'superseded' \"\$OLDSPEC\""
OLDNESTED="$HERE/docs/superpowers/specs/2026-07-05-nested-orchestration-design.md"
check "옛 nested 설계에 superseded 표시가 있다"   "grep -qF 'superseded' \"\$OLDNESTED\""

# 경로 고정 검사는 이미 표시가 달린 옛 spec 을 지키고, 아래 검사는 spec 머리의 `supersedes:` 줄이
# 가리키는 문서를 데이터로 읽어 지킨다. 줄 첫머리가 `supersedes:` 인 줄만 읽으므로 `> **상태:**`·
# `> 대체 예정:` 줄은 읽지 않는다.
superseded_missing() {  # $1=specs 폴더 → 줄마다 "<spec 파일 이름> → <대상 파일 이름>"
  local f t
  for f in "$1"/*.md; do
    [ -f "$f" ] || continue
    head -12 "$f" | tr -d '\r' | grep -E '^>?[[:space:]]*supersedes:' | grep -oE '`[^`]+\.md`' | tr -d '`' \
      | while IFS= read -r t; do
          if [ ! -f "$1/$t" ] || ! head -12 "$1/$t" | tr -d '\r' | grep -qi 'superseded'; then
            printf '%s → %s\n' "$(basename "$f")" "$t"
          fi
        done || true
  done
  return 0
}
echo "[supersedes 줄이 가리키는 문서에 superseded 표시]"
SUP_FX="$(mktemp -d)"
printf '> supersedes: `old.md`, `gone.md`\n' > "$SUP_FX/new.md"
printf '# old\n' > "$SUP_FX/old.md"
check "supersedes 줄을 읽는 검사가 표시 없는 대상과 없는 파일을 잡는다" "[ \"\$(superseded_missing \"\$SUP_FX\" | wc -l | tr -d ' ')\" = 2 ]"
check "표시를 단 대상은 넘긴다" "printf '> **superseded**\n' > \"\$SUP_FX/old.md\" && [ \"\$(superseded_missing \"\$SUP_FX\")\" = 'new.md → gone.md' ]"
check "supersedes 줄이 가리키는 문서마다 superseded 표시가 있다" "[ -z \"\$(superseded_missing \"\$HERE/docs/superpowers/specs\")\" ]"

# --- 프로젝트 파일에 손대는 예외: 코드 주석 한 곳만 조건을 적는다 ---
# 전에는 README가 조건의 원본이었고 스캐폴드가 그 절을 가리켰다. 조건은 코드가 실제로 하는 일이라
# 코드 옆 주석을 원본으로 두고, 머리 주석이 그 태그를 가리킨다. 가리키는 태그가 실재하는지도 본다.
echo "[프로젝트 파일 예외 — 스캐폴드 주석 한 곳만 조건을 적는다]"
SCAF="$HERE/scripts/scaffold.sh"
EXC_TAG="$(sed -n '1,6p' "$SCAF" | grep -oE '\[[a-z-]+\]' | head -1 || true)"
check "스캐폴드 머리 주석이 예외 태그를 가리킨다" "[ -n \"\$EXC_TAG\" ]"
check "그 태그의 주석이 본문에 실재한다"        "sed -n '7,\$p' \"\$SCAF\" | grep -qF -- \"# \$EXC_TAG\""
# CLAUDE.md는 이제 조건을 되풀이하지 않고 README를 가리키기만 한다. 가리키는 문장이 살아 있는지 본다.
check "CLAUDE.md가 README를 가리킨다"          "sec_has \"$HERE/CLAUDE.md\" '에이전트원칙을 고칠 때' 'README'"


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

# --- 문서가 가리키는 경로와 「」 절이 실재한다 ---
# 2026-10-26 결함 주입에서 지운 skills/lens-fit/SKILL.md 로 가는 링크를 되살려도 어느 검사도 실패하지
# 않았고, README 의 절 이름이 바뀐 뒤에도 그 절을 가리킨 「」 참조가 아무 신호 없이 남았다. v2 에서 스킬을
# 합치고 지우면서 끊긴 참조가 더 늘 수 있어, 살아 있는 문서 전부의 경로와 「」 참조를 본다(spec 「보조 계약」).
# 공통 제외 목록은 REMOVED_REF_EXCLUDES 가 소유하고, 참고서의 「v1 조항 근거」 절은 v1 의 기록이라 뺀다.
#
# 「」 참조는 레포 전체의 제목 집합과 맞춘다. 문서끼리 「」로 절을 가리키는 것이 이 레포의 관례라 한 파일
# 안으로 좁히면 정당한 상호 참조가 실패한다. 이름 뒤에 설명절(` (`·` —`)을 다는 제목이 많아 이름 부분만
# 맞춘다. 평가 과제의 프롬프트(evals/principles/cases)는 문서가 아닌 시험 입력이라 제목 집합에서 뺀다.
# 「」 참조를 보는 문서는 실리는 지시문(원칙·금지어 목록·스킬·에이전트)이다. 참고서는 지운 절과 문서 밖 자료의
# 이름을 「」로 적은 이력 문장이 많아 경로만 본다.
# 제목 집합을 파이프로 넘기지 않고 here-string 으로 넘긴다. `printf | grep -q` 는 pipefail 과 맞물려
# grep 이 먼저 끝나면 찾았는데도 실패로 계상된다.
echo "[문서가 가리키는 경로와 「」 절이 실재한다]"
# 제목 집합은 git 이 추적하거나 추적할 문서(.gitignore 밖)에서만 뽑는다. 작업 폴더에 남은 임시 문서의 제목이
# 섞이면 지운 절을 가리킨 참조가 그 임시 문서 덕에 통과한다.
HEADINGS="$(cd "$HERE" && git ls-files -z --cached --others --exclude-standard -- '*.md' ':!:evals/principles/cases/*' \
  | xargs -0 cat 2>/dev/null | grep -E '^#+ '| sed 's/^#\+ *//' | LC_ALL=C.UTF-8 sed 's/ *[—(].*$//' | sed 's/ *$//' | grep -v '^$' | sort -u)"
sec_refs() {  # $1=파일 → 「」 참조 이름(코드 블록과 「v1 조항 근거」 절 밖, 설명절을 뗀 이름)
  awk '{ sub(/\r$/, "") } /^```/ { fence = !fence; next } !fence && /^## / { v1 = (index($0, "## v1 조항 근거") == 1) } !fence && !v1' "$1" \
    | LC_ALL=C.UTF-8 grep -oE '「[^」]*」' | LC_ALL=C.UTF-8 sed 's/^「//; s/」$//; s/ *[—(].*$//; s/ *$//' | sort -u || true
}
missing_secs() {  # $1=파일 → 제목 집합에 없는 「」 참조
  local sec
  while IFS= read -r sec; do
    [ -n "$sec" ] || continue
    grep -qxF -- "$sec" <<<"$HEADINGS" || printf '%s\n' "$sec"
  done <<<"$(sec_refs "$1")"
}
SR_FX="$TEST_TMP/secrefs.md"
printf '%s\n' '「없는 절」' '```' '「코드 속」' '```' '## v1 조항 근거' '「옛 절」' '## 다음' '「v1 조항 근거」' > "$SR_FX"
check "절 참조 검사가 코드 블록과 v1 절 밖의 없는 절만 잡는다" "[ \"\$(missing_secs \"\$SR_FX\" | tr '\n' ' ')\" = '없는 절 ' ]"
SEC_BAD=""; SEC_N=0
while IFS= read -r f; do
  [ -f "$HERE/$f" ] || continue
  ref_excluded "$f" && continue
  SEC_N=$((SEC_N+1))
  m="$(missing_secs "$HERE/$f" | tr '\n' '|')"
  [ -n "$m" ] && SEC_BAD="$SEC_BAD [$f: $m]"
done <<EOF
$(cd "$HERE" && git ls-files --cached --others --exclude-standard -- agent-principles.md korean-banned-words.md 'skills/*.md' 'agents/*.md')
EOF
[ -n "$SEC_BAD" ] && printf '    없는 절을 가리키는 곳:%s\n' "$SEC_BAD"
_json_python || true
DP() { PYTHONUTF8=1 "${_JSON_PY:-python}" -I "$HERE/scripts/_doc_paths.py" "$@" </dev/null 2>&1 || echo "RUN-ERROR"; }
DPOUT="$(DP "$HERE" "${REMOVED_REF_EXCLUDES[@]}")"
grep -v '^CHECKED ' <<<"$DPOUT" | sed 's/^/    깨진 경로: /' || true
check "경로 후보와 절 참조를 하나 이상 확인했다" "grep -qE '^CHECKED [1-9]' <<<\"\$DPOUT\" && [ \"\$SEC_N\" -gt 0 ]"
check "문서가 가리키는 경로와 「」 절이 실재한다" "[ -z \"\$SEC_BAD\" ] && [ \"\$(grep -vc '^CHECKED ' <<<\"\$DPOUT\" || true)\" = 0 ]"
DPFX="$TEST_TMP/docpaths"; mkdir -p "$DPFX/skills/x" "$DPFX/agents"; : > "$DPFX/agents/researcher.md"
printf '%s\n' '[fit](../lens-fit/SKILL.md)' '`agents/prior-art-*.md`' '`agents/research*.md`' '옛 `skills/lens-fit/SKILL.md` 는 지웠다' '## v1 조항 근거' '`evals/gone/x.md`' > "$DPFX/skills/x/SKILL.md"
DPFXOUT="$(DP "$DPFX")"
check "지운 스킬로 가는 링크를 잡는다" "grep -qF 'lens-fit/SKILL.md' <<<\"\$DPFXOUT\""
check "일치하는 파일이 없는 별표 경로를 잡는다" "grep -qF 'prior-art-*' <<<\"\$DPFXOUT\""
check "일치하는 별표 경로와 이력 줄과 v1 절은 넘긴다" "[ \"\$(grep -vc '^CHECKED ' <<<\"\$DPFXOUT\" || true)\" = 2 ]"

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
# 렌즈 이름은 에이전트 정의에서 도출한다 — 여기 손으로 적으면 그 목록이 먼저 낡는다.
LENS_RE="$(printf '%s' "$ALL" | tr '\n' '|' | sed 's/|$//')"
COUNT_SCAN="$HERE/agents/lens-*.md $HERE/skills/domain-readme/SKILL.md $CALLER $CANON $HERE/README.md"
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
# 글자가 아니라 동작으로 잰다. 앞 판본은 `bad="$bad $t"` 라는 글자를 봤기 때문에, 같은 계약을
# 지키는 다른 구현(동시 실행)으로 바꾸자 계약이 아니라 구현이 깨졌다고 알렸다. 여기서는 그 줄을
# CLAUDE.md에서 뽑아 픽스처에 대고 실제로 돌린다 — 실패한 스크립트를 이름으로 지목하는지, 전부
# 통과하면 통과라고 하는지 둘 다 본다.
RUNCMD="$(grep -F -- 'for t in scripts/test_*.sh' "$CMD" | head -1 | sed 's/^[[:space:]]*`//; s/`[[:space:]]*$//')"
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
# CI도 같은 명령을 돈다. CLAUDE.md와 달리 CI는 CLAUDE.md를 읽을 수 없어 형태를 다시 적을 수밖에 없으니,
# 적어도 그 형태가 CLAUDE.md의 명령과 같은 실패 처리를 하는지 붙든다. `set -e`에 맨 `bash "$t"`면 첫 실패에서
# 멈춰 뒤 스크립트가 아예 안 돌고, 무엇이 더 깨졌는지 한 회차로는 알 수 없다.
CI="$HERE/.github/workflows/ci.yml"
check "CI가 계약 테스트를 돈다"               "grep -qF -- 'for t in scripts/test_*.sh' \"\$CI\""


# --- 새로 만든 스킬이 진입로에 등재된다 ---
# 스킬을 만들면서 그것을 가리키는 자리를 함께 만들지 않으면, 상황에서 출발한 세션이 그 스킬에 닿지
# 못한다(실제로 레포 문서 감사 스킬이 에이전트원칙의 두 표 어디에도 없었다). 그래서 스킬 디렉터리에서 이름을
# 도출해 에이전트원칙이나 도메인 목차가 그 이름을 한 번은 부르는지 본다.
echo "[스킬 등재 — 진입로에서 이름이 불린다]"
for d in "$HERE"/skills/*/; do
  sk="$(basename "$d")"
  # 진입로는 둘이다 — 에이전트원칙이 이름을 부르거나, 다른 스킬이 부른다. 렌즈는 agents/ 에 있고 test_lens_contract.sh 가 본다.
  # 자기 SKILL.md 안의 언급은 세지 않는다. 자기가 자기를 부르는 것은 도달이 아니다.
  named=0
  grep -qF -- "$sk" "$HERE/agent-principles.md" && named=1
  if [ "$named" = 0 ]; then
    for o in "$HERE"/skills/*/SKILL.md; do
      case "$o" in */"$sk"/SKILL.md) continue ;; esac
      grep -qF -- "$sk" "$o" && { named=1; break; }
    done
  fi
  check "$sk 을 에이전트원칙이나 다른 스킬이 부른다" "[ '$named' = 1 ]"
done

# description 값은 YAML 평문 스칼라다. ': ' 나 ' #' 이 들어가면 frontmatter 파싱이 깨져 그 스킬이 목록에서
# 조용히 사라진다. 규칙은 domain-plugin 「frontmatter」가 소유하고 여기서 기계로 붙든다.
echo "[frontmatter 안전 — description 값에 ': ' 와 ' #' 이 없다]"
FMN=0
for f in "$HERE"/skills/*/SKILL.md "$HERE"/commands/*.md "$HERE"/agents/*.md; do
  [ -f "$f" ] || continue
  FMN=$((FMN+1))
  DESC="$(grep -m1 '^description:' "$f" | sed 's/^description:[[:space:]]*//')"
  check "$(basename "$(dirname "$f")")/$(basename "$f") 의 description 이 YAML 평문으로 안전하다" "! printf '%s' \"\$DESC\" | grep -qE ': | #'"
done
check "frontmatter 를 하나 이상 훑었다" "[ '$FMN' -gt 0 ]"
# 호출 정책의 규칙은 domain-plugin 이 소유하고, 검사는 test_lens_contract.sh 「호출 정책」 묶음이 한다.
check "domain-plugin 이 에이전트 호출 정책을 둔다" "has_sec \"\$HERE/skills/domain-plugin/SKILL.md\" '에이전트 호출 정책'"

# --- 제목 규칙의 기준 문서를 대조 렌즈에 넘긴다 ---
# 문서와 슬라이드의 제목 규칙(TITLE-LAYERS·TITLE-CLAIM)은 managing-docs 의 reading-docs.md 에 있다. v2 에서는
# 형식 계약을 대조 렌즈(lens-grounding)가 보므로, lens-review 가 그 파일을 기준으로 넘기는지 붙든다.
echo "[규칙 출처] lens-review 가 reading-docs.md 를 대조 기준으로 넘긴다"
check "카테고리 표가 그 파일을 가리킨다" "sec_has \"\$LR\" '카테고리와 렌즈' 'reading-docs.md'"

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
check "두 문안이 같다"                         "[ '$MKCMP' = 'SAME' ]"

# --- 금지 표현 목록과 근거 ---
# 목록 파일이 원본이고 근거는 docs/ 의 근거 파일에 있다. 이 저장소 자신의 문서를 검사에서 빼는 사유는
# hooks/_spec_marker.sh 의 path_in_own_repo 주석이 소유한다.
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
# 금지 표현 목록과 근거 파일은 뺀다. 목록은 표의 분류 설명이, 근거 파일은 고쳐 쓰지 않는 사용자 원문
# 인용이 대구를 쓴다. 한도에 맞추려면 그 설명이나 원문을 바꿔야 한다. evals/ 는
# 살아 있는 문서 목록이 이미 뺀다.
ANTI_DOCS="$(printf '%s\n' "$LIVE_DOCS" | grep -v -e '^korean-banned-words.md$' -e '^docs/korean-banned-words-evidence.md$')"
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
# 핵심 계약: 기록 봉인 — 결함 주입: 결정 기록 하나를 태그 없이 지운다
check "기록 폴더에 기록이 하나 이상 있다" "ls \"\$HERE/\$RVDIR\"/*.md >/dev/null 2>&1"
RV_TREE="$(cd "$HERE" && git status --porcelain --untracked-files=all -- "$RVDIR" 2>/dev/null | grep -vE '^(\?\?|A ) ' || true)"
[ -n "$RV_TREE" ] && printf '    작업 트리에서 고치거나 지운 기록:
%s
' "$RV_TREE" | sed 's/^/      /'
check "작업 트리에 고치거나 지운 기록이 없다" "[ -z \"\$RV_TREE\" ]"
# 결정 기록(decisions/)도 기록 타입이다. 2026-10-26 00:22(cfb0228)까지는 같은 결정 기록에 시험 결과를 이어 적었으므로
# 그 뒤의 이력만 본다.
DCDIR="docs/superpowers/decisions"
DC_TREE="$(cd "$HERE" && git status --porcelain --untracked-files=all -- "$DCDIR" 2>/dev/null | grep -vE '^(\?\?|A ) ' || true)"
DC_HIST="$(cd "$HERE" && git log --since="2026-10-26 00:30:00 +0900" --diff-filter=M --format= --name-only -- "$DCDIR" 2>/dev/null || true)"
check "작업 트리와 이력에 고친 결정 기록이 없다" "[ -z \"\$DC_TREE\$DC_HIST\" ]"
RV_HIST="$(cd "$HERE" && git log --since=2026-09-02 --diff-filter=M --numstat --format= -- "$RVDIR" 2>/dev/null   | awk -F'	' 'NF==3 && !($1=="0" && $2=="0") { print $3 }' || true)"
[ -n "$RV_HIST" ] && printf '    규칙 뒤 이력에서 고친 기록:
%s
' "$RV_HIST" | sed 's/^/      /'
check "규칙이 들어온 뒤 이력에 고친 기록이 없다" "[ -z \"\$RV_HIST\" ]"
# 지우기는 다룬 작업이 병합된 뒤 보존 태그(archive/*)를 단 커밋 위에서만 한다(managing-docs 「문서 타입과 수명」).
# 지운 커밋의 부모를 archive 태그가 가리켜야 한다 — 원문이 태그로 남아야 봉인의 목적이 지켜진다.
# 이 규칙은 2026-10-06에 들어왔다. 그 전의 지우기(빈 파일 정리, 기능 제거 때의 plan)는 옛 규칙 아래에서 처리했다.
RV_DEL="$(cd "$HERE" && for c in $(git log --since="2026-10-06 00:00:00 +0900" --diff-filter=D --format=%H -- "$RVDIR" docs/superpowers/plans docs/superpowers/decisions 2>/dev/null); do
  git tag --points-at "$c^" 2>/dev/null | grep -q '^archive/' || echo "$c"; done)"
[ -n "$RV_DEL" ] && printf '    보존 태그 없이 기록이나 plan 을 지운 커밋:
%s
' "$RV_DEL" | sed 's/^/      /'
check "기록과 plan 은 보존 태그를 단 뒤에만 지웠다" "[ -z \"\$RV_DEL\" ]"

# --- 봉인: 기록은 만든 직후에 읽기 전용이 된다 ---
# 읽기 전용 속성은 git이 옮기지 않아 새 클론에서는 풀려 있다. 그래서 SessionStart 훅이 세션마다 다시
# 봉인한다. 인자 없는 갈래는 픽스처 저장소에서 검사한다 — 레포 자신에서 돌리면 스크립트가 아무것도
# 처리하지 않아도 작업 트리 상태만으로 초록이 되고, 검사가 레포의 파일 속성을 바꾼다.
echo "[봉인 — 기록은 읽기 전용이 된다]"
SEAL="$HERE/scripts/seal_reviews.sh"
SEAL_T="$(mktemp -d)"; printf 'a\n' > "$SEAL_T/one.md"; printf 'b\n' > "$SEAL_T/two.json"
bash "$SEAL" "$SEAL_T/one.md" "$SEAL_T/two.json" >/dev/null 2>&1 || true
# 핵심 계약: 기록 봉인 — 결함 주입: 결정 기록 하나를 태그 없이 지운다
check "인자로 준 파일이 읽기 전용이 된다"     "[ ! -w '$SEAL_T/one.md' ] && [ ! -w '$SEAL_T/two.json' ]"
bash "$SEAL" "$SEAL_T/one.md" "$SEAL_T/two.json" >/dev/null 2>&1 || true
check "인자 있는 봉인을 두 번 돌려도 같다"     "[ ! -w '$SEAL_T/one.md' ] && [ ! -w '$SEAL_T/two.json' ]"
SEAL_G="$(mktemp -d)"; mkdir -p "$SEAL_G/docs/superpowers/reviews/r1" "$SEAL_G/docs/superpowers/decisions"
( cd "$SEAL_G" && git init -q && git config user.email t@t && git config user.name t \
  && printf 'x\n' > docs/superpowers/reviews/r1.md && printf '{}\n' > docs/superpowers/reviews/r1/run.json \
  && printf 'd\n' > docs/superpowers/decisions/d1.md \
  && printf 'later\n' > docs/superpowers/reviews/untracked.md && git add docs/superpowers/reviews/r1.md docs/superpowers/reviews/r1/run.json docs/superpowers/decisions/d1.md && git commit -qm seed )
bash "$SEAL" --root "$SEAL_G" >/dev/null 2>&1 || true
bash "$SEAL" --root "$SEAL_G" >/dev/null 2>&1 || true
check "인자 없는 봉인이 HEAD 의 기록을 전부 읽기 전용으로 만든다" "[ ! -w '$SEAL_G/docs/superpowers/reviews/r1.md' ] && [ ! -w '$SEAL_G/docs/superpowers/reviews/r1/run.json' ]"
check "인자 없는 봉인이 결정 기록도 읽기 전용으로 만든다" "[ ! -w '$SEAL_G/docs/superpowers/decisions/d1.md' ]"
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

# --- canon-realign: 참고서가 빌려 온 원칙의 출처를 밝힌다 ---
echo "[canon-realign] the reference credits the borrowed principles"
check "karpathy source is credited in the reference" "grep -qF 'andrej-karpathy-skills' '$HERE/docs/domain-discipline.md'"

# --- standing-consent: 선행연구 스킬의 승인 규칙 ---
# 선행연구 스킬은 이름이 `lens-*` 형태가 아니어서 렌즈 허가에 들지 않고, 승인 규칙은 자기 절이 소유한다.
AP="$HERE/skills/researching-prior-art/SKILL.md"
echo "[standing-consent] the prior-art skill owns its approval rule"
check "선행연구 스킬이 승인 규칙을 소유한다" "owns_sec \"\$AP\" '발동과 기록'"

# --- lens-contract: 렌즈를 실행하는 스킬이 런타임 중립을 지킨다 ---
# 렌즈 실행 규율은 `lens-review` 가 소유한다. 여기서는 그 스킬과 서브 세션 절차가 특정 에이전트 종류 이름과
# 관리 디렉터리 절대 경로를 박지 않는지만 본다.
echo "[lens-contract] lens callers stay runtime-neutral"
for s in lens-review nested-orchestration; do
  F="$HERE/skills/$s/SKILL.md"
  # 런타임 중립: 특정 에이전트 종류 이름과 관리 디렉터리 절대 경로를 박지 않는다.
  check "$s: Claude 전용 종류 이름 없음"    "! grep -qF 'Explore' '$F'"
  check "$s: 관리 디렉터리 절대경로 없음"   "! grep -qF '~/.claude/disciplined-coder/' '$F'"
done
NO_REF="$HERE/skills/nested-orchestration/references/sub-session-protocol.md"
check "nested-orchestration 프로토콜: Claude 전용 종류 이름 없음"  "! grep -qF 'Explore' '$NO_REF'"
check "nested-orchestration 프로토콜: 관리 디렉터리 절대경로 없음" "! grep -qF '~/.claude/disciplined-coder/' '$NO_REF'"

# --- 매니페스트 version 계약 ---
# Claude 매니페스트는 version을 비워 커밋 SHA 기반 자동 업데이트를 유지한다(domain-plugin).
# 값을 넣으면 버전 문자열 비교로 전환돼 값을 올리지 않는 한 새 커밋이 배포되지 않는다. 한 번 넣었다
# 되돌린 이력이 있어 사람 기억에 맡기지 않고 테스트로 고정한다.
check "Claude 매니페스트에 version 없음"  "! grep -qE '\"version\"[[:space:]]*:' '$HERE/.claude-plugin/plugin.json'"

echo "[nested-message-format] nested-orchestration 메시지 이름은 프로토콜 파일의 표에서만 정의한다"
# 메시지 형식과 멈추는 기준은 서브 세션이 읽는 프로토콜 파일에 있고, SKILL.md 는 현재 세션의 절차만 둔다.
# 정의된 이름은 손으로 적지 않고 프로토콜 파일 「메시지 형식」 절의 표 첫 칸(머리줄·사유 코드)에서 뽑는다.
# 쓰인 이름은 두 파일에서 백틱으로 감싼 대문자 이름과 `BLOCKED <코드>` 의 코드다. 정의되지 않은 이름을
# 쓰면 실패한다 — 메시지를 지우거나 이름을 바꾸고 한쪽만 고친 상태를 잡는다.
NO_DOC="$HERE/skills/nested-orchestration/SKILL.md"
NO_PROTO="$HERE/skills/nested-orchestration/references/sub-session-protocol.md"
check "프로토콜 파일에 「메시지 형식」 절이 있다" "has_sec \"\$NO_PROTO\" '메시지 형식'"
check "프로토콜 파일에 「멈추는 기준」 절이 있다" "has_sec \"\$NO_PROTO\" '멈추는 기준'"
# 같은 규칙을 두 곳에 두지 않는다 — SKILL.md 에 그 절이 다시 생기면 실패한다.
check "SKILL.md 에 「메시지 형식」 절이 없다" "! has_sec \"\$NO_DOC\" '메시지 형식'"
check "SKILL.md 에 「멈추는 기준」 절이 없다" "! has_sec \"\$NO_DOC\" '멈추는 기준'"
nested_defined() {  # 프로토콜 파일 「메시지 형식」 표의 첫 칸 이름
  doc_sec "$NO_PROTO" '메시지 형식' | grep -oE '^\| `[A-Za-z_-]+' | sed 's/^| `//' | LC_ALL=C sort -u
}
nested_used() {  # $@=파일 → 메시지 자리에 쓰인 메시지 이름과 사유 코드
  # 백틱 안 대문자 이름은 원칙 ID·약어(`SDD`)와 구별되지 않으므로 메시지 자리에 놓인 이름만 본다. 메시지 자리는
  # `BLOCKED <코드>` 의 코드, 표 첫 칸의 소문자 사유 코드, SKILL.md 「BLOCKED 처리」 표의 마지막 칸(보낼 메시지)이다.
  local f
  for f in "$@"; do
    grep -oE '`BLOCKED [a-z-]+`|^\| `[a-z][a-z-]*`' "$f" | sed 's/^| //' | tr -d '`' | sed 's/^BLOCKED //' || true
    doc_sec "$f" 'BLOCKED 처리' | grep -E '^\|' | awk -F'|' 'NF > 3 { print $(NF-1) }' | grep -oE '`[A-Z][A-Z_]*(-[A-Z]+)*`' | tr -d '`' || true
  done | LC_ALL=C sort -u
}
nested_undefined() {  # $@=파일 → 정의되지 않은 이름
  comm -23 <(nested_used "$@") <(nested_defined)
}
NO_DEF="$(nested_defined)"
check "정의된 이름을 표에서 뽑았다" "grep -qx 'BLOCKED' <<<\"\$NO_DEF\" && grep -qx 'user-decision' <<<\"\$NO_DEF\""
NO_UNDEF="$(nested_undefined "$NO_DOC" "$NO_PROTO")"
[ -n "$NO_UNDEF" ] && echo "    정의되지 않은 메시지 이름:$(printf ' %s' $NO_UNDEF)"
check "두 파일이 쓰는 메시지 이름이 모두 표에 정의되어 있다" "[ -z \"\$NO_UNDEF\" ]"
# 결함 주입 — 정의되지 않은 이름을 넣은 사본에서 검사가 그 이름을 잡아야 한다.
# 가짜 행은 「BLOCKED 처리」 표 안에 넣어야 마지막 칸이 메시지 자리로 읽힌다. 메시지 자리 밖의 원칙 ID(`ROLES`)는 잡지 않는다.
NO_CUT="$(mktemp)"
awk '{ print } /^\| `dependency-add`/ { print "| `bogus-row`(유형) | 할 일 | 요청한 쪽에 `BOGUS-MESSAGE` |" }' "$NO_DOC" > "$NO_CUT"
printf '%s\n' '`BLOCKED bogus-code` 와 원칙 `ROLES`' >> "$NO_CUT"
check "도출 검사가 정의되지 않은 이름을 잡는다" "[ \"\$(nested_undefined '$NO_CUT' | tr '\n' ' ')\" = 'BOGUS-MESSAGE bogus-code bogus-row ' ]"
# SKILL.md 가 서브 세션에 넘기는 곳과 메시지를 처리하는 곳이 프로토콜 파일을 가리킨다.
check "SKILL.md 머리가 프로토콜 파일 경로를 적는다" "grep -qF 'references/sub-session-protocol.md' \"\$NO_DOC\""
for sec in '디스패치 템플릿' '받은 메시지 처리' '이어 쓰기와 재개'; do
  check "「$sec」이 프로토콜 파일을 가리킨다" "sec_has \"\$NO_DOC\" '$sec' '프로토콜 파일'"
done
# v2 리뷰는 등급을 매기지 않고 처분(반영·기각·사용자)만 낸다. 옛 등급 표시와 렌즈 그룹 칸, 지운 원칙 ID 가
# 남으면 서브 세션이 없는 값을 기다리며 멈추지 않는다.
OLD_REVIEW_HIT="$(grep -lE '🔴|렌즈 그룹 판정|LENS-ALLOWED' "$NO_DOC" "$NO_PROTO" "$HERE/skills/researching-prior-art/SKILL.md" 2>/dev/null || true)"
[ -n "$OLD_REVIEW_HIT" ] && echo "    옛 리뷰 등급·칸이 남은 곳: $(printf '%s ' $OLD_REVIEW_HIT)"
check "nested-orchestration 과 선행연구 스킬에 옛 리뷰 등급·렌즈 그룹 칸·LENS-ALLOWED 가 없다" "[ -z \"\$OLD_REVIEW_HIT\" ]"

echo "[선행연구 스킬]"
RDEF="$HERE/agents/researcher.md"
VDEF="$HERE/agents/citation-verifier.md"
fm() { awk 'NR==1&&/^---$/{f=1;next} f&&/^---$/{exit} f' "$1" 2>/dev/null; }
for s in '오케스트레이터 절차' '발동과 기록' '상황별 전략' '실행할 때 지킬 상한' '판정 규약' '출력 스키마' '인용 확인' '레퍼런스 프롬프트'; do
  check "researching-prior-art 에 절이 있다: $s" "has_sec \"\$AP\" '$s'"
done
check "spec 리뷰가 발동과 기록을 가리킨다" "points_to \"\$CALLER\" '\`researching-prior-art\`' '「발동과 기록」'"
check "연구자 정의의 도구가 구성과 같다" "grep -qx 'tools: WebSearch, WebFetch, Read, Grep, Glob' <<<\"\$(fm \"\$RDEF\")\""
check "연구자 정의의 턴 상한이 20 이다" "grep -qx 'maxTurns: 20' <<<\"\$(fm \"\$RDEF\")\""
# 검증자 정의는 추출·판정의 두 파일이다. 구성 값은 spec 「Opus 일괄 판정」이 정했고,
# 판정 정의의 모델과 노력 수준은 「Opus 일괄 판정」이 바꿨다.
JDEF="$HERE/agents/citation-judge.md"
check "researcher.md 의 description 이 호출 조건을 적는다" "grep -qF '호출 절차가 이름으로 지정할 때만 실행한다' <<<\"\$(grep -m1 '^description:' <<<\"\$(fm \"\$RDEF\")\")\""
for row in "VDEF|WebFetch, Read|claude-haiku-5-5|high" "JDEF|Read|claude-opus-5-5|medium"; do
  IFS='|' read -r def tools model effort <<<"$row"
  file="${!def}"; FMV="$(fm "$file" || true)"; base="$(basename "$file")"
  check "$base 의 도구가 구성과 같다" "grep -qx 'tools: $tools' <<<\"\$FMV\""
  check "$base 의 모델이 구성과 같다" "grep -qx 'model: $model' <<<\"\$FMV\""
  check "$base 의 노력 수준이 $effort 다" "grep -qx 'effort: $effort' <<<\"\$FMV\""
  check "$base 의 턴 상한이 20 이다" "grep -qx 'maxTurns: 20' <<<\"\$FMV\""
  check "$base 의 description 이 호출 조건을 적는다" "grep -qF '호출 절차가 이름으로 지정할 때만 실행한다' <<<\"\$(grep -m1 '^description:' <<<\"\$FMV\")\""
done
RP="$( [ -f "$AP" ] && doc_sec "$AP" '레퍼런스 프롬프트' | grep -m1 '^- system: "' | sed 's/^- system: "//; s/"$//' || true)"
check "연구자 정의가 레퍼런스 프롬프트 본문을 그대로 싣는다" "[ -n \"\$RP\" ] && grep -qF -- \"\$RP\" \"\$RDEF\""
# survey 와 scout 지시문도 레퍼런스 프롬프트 절의 줄과 연구자 정의가 같은 글자다.
for M in survey scout; do
  RPM="$( [ -f "$AP" ] && doc_sec "$AP" '레퍼런스 프롬프트' | grep -m1 "^- system ($M): \"" | sed "s/^- system ($M): \"//; s/\"\$//" || true)"
  check "연구자 정의가 레퍼런스 프롬프트의 $M 본문을 그대로 싣는다" "[ -n \"\$RPM\" ] && grep -qF -- \"\$RPM\" \"\$RDEF\""
done
DDISC="$HERE/docs/domain-discipline.md"
check "근거 문서의 NO-RAW-OUTPUT 절이 대체를 적는다" "sec_has \"\$DDISC\" '\`NO-RAW-OUTPUT\`' 'researching-prior-art'"
check "근거 문서의 LENS-ALLOWED 절이 대체를 적는다" "sec_has \"\$DDISC\" '\`LENS-ALLOWED\`' 'researching-prior-art'"

echo "[상시 보기 — 원본 표의 행이 모두 있다]"
VIEW_MISS="$(while read -r t; do grep -qF -- "\`$t\`" "$VIEW" || echo "$t"; done < "$BW/toks")"
check "상시 보기 행 수가 원본 표 행 수와 같다" "[ \"\$(grep -c '^- \`' \"\$VIEW\")\" = \"\$(wc -l < \"\$BW/pairs\" | tr -d ' ')\" ]"
check "원본 표의 금지어가 모두 상시 보기에 있다" "[ -z \"\$VIEW_MISS\" ]"

echo "[지시문 금지어 — 실리는 지시문에 금지어가 백틱 밖에 없다]"
# 모든 세션에 싣는 원칙 사본·상시 보기와 매 턴 리마인더가 대상이다. 모델이 지시문 낱말을 답에 그대로 옮기기 때문이다.
REMIND_TXT="$BW/remind.txt"
bash "$HERE/hooks/reply_reminder_userpromptsubmit.sh" </dev/null \
  | json_run 'import json,sys; sys.stdout.write(json.load(sys.stdin)["hookSpecificOutput"]["additionalContext"])' > "$REMIND_TXT" || true
IB_FX="$(mktemp -d)"
printf '결정 사항은 정할 일이 아니다.\n' > "$IB_FX/out.md"
printf '결정 사항은 `정할 일` 이 아니다.\n' > "$IB_FX/in.md"
check "백틱 밖 금지어를 잡는다"   "[ -n \"\$(banned_report \"\$BW/pairs\" \"\$IB_FX/out.md\" \"\$BW/excl\")\" ]"
check "백틱 안 금지어는 넘긴다"   "[ -z \"\$(banned_report \"\$BW/pairs\" \"\$IB_FX/in.md\" \"\$BW/excl\")\" ]"
check "원칙 사본에 금지어가 없다"   "[ -z \"\$(banned_report \"\$BW/pairs\" \"\$HERE/agent-principles.md\" \"\$BW/excl\")\" ]"
check "상시 보기에 금지어가 없다"   "[ -z \"\$(banned_report \"\$BW/pairs\" \"\$VIEW\" \"\$BW/excl\")\" ]"
check "리마인더에 금지어가 없다"    "[ -z \"\$(banned_report \"\$BW/pairs\" \"\$REMIND_TXT\" \"\$BW/excl\")\" ]"
# 2026-11-17 적대 점검에서 금융·법령·차트 설명 문장이 오검출되었다. 그 문장을 원본 표로 다시 검사해 제외어가 덮는지 본다.
# `판결 정본` 의 `정본` 은 법령 용어라 검사기가 아니라 상시 보기의 적용 제외 줄이 맡으므로 표본에 넣지 않는다.
FP_FX="$IB_FX/false-positive.md"
printf '%s\n' '실적이 컨센서스를 웃돌았다.' '수요가 전망치를 밑돌고 있다.' '투자자들이 채권으로 눈을 돌리고 있다.' '판관비가 늘었다.' \
  '대법원 판결이 나왔다.' '전담 조직을 두었다.' '부분 상환과 부분 체결을 처리했다.' '사업 영역을 넓혔다.' '영역형 차트를 쓴다.' \
  '소수점 이하 두 자리와 세 자리로 맞춘다.' '실행에 2시간 걸립니다.' '처리에 3일 걸린다.' '빨간색 막대는 상승일이다.' \
  '초록색 선은 이동평균이다.' '제목은 가운데 정렬이다.' '3개월에 한 번꼴로 점검한다.' '납입 회차별 이자를 계산한다.' \
  '재지급 대상자를 뽑는다.' '재지시를 받았다.' > "$FP_FX"
FP_HITS="$(banned_report "$BW/pairs" "$FP_FX" "$BW/excl")"
[ -n "$FP_HITS" ] && printf '    오검출:\n%s\n' "$FP_HITS"
check "적대 점검 오검출 표본에서 금지어를 검출하지 않는다" "[ -z \"\$FP_HITS\" ]"
check "상시 보기 머리에 적용 제외 줄이 있다" "grep -qF '법령·회계 용어에는 이 목록을 적용하지 마라' \"\$VIEW\""
# 한 글자 어간과 두루 쓰이는 낱말은 다른 뜻으로도 쓰이므로 상시 보기가 금지할 뜻을 함께 싣는다.
STEM_BAD="$(for w in 판 담 걸 자리 부분 영역; do grep -E "^- .*\`$w\`" "$VIEW" | grep -qF '뜻' || echo "$w"; done)"
check "한 글자 어간 행이 상시 보기에 금지할 뜻을 싣는다" "[ -z \"\$STEM_BAD\" ]"

echo "[상시 지시 — 리마인더의 묻는 조건과 분량]"
# 리마인더 셋째 줄은 원칙 `ROLES` 의 묻는 조건과 같은 낱말이어야 한다. 낱말이 갈라지면 두 지시 중 어느 쪽을 따를지 모델이 추정한다.
# 조건 목록은 원칙의 "그 결정이 … 중 하나인지" 문장에서 괄호를 걷고 쉼표로 나눠 뽑는다.
ASK_CONDS="$(grep -m1 -F '그 결정이 ' "$CANON" | sed 's/.*그 결정이 //; s/ 중 하나인지.*//; s/([^)]*)//g' | sed 's/, /\n/g' | sed 's/[[:space:]]*$//' || true)"
ASK_MISS="$(while IFS= read -r c; do [ -n "$c" ] && ! grep -qF -- "$c" "$REMIND_TXT" && echo "$c"; done <<<"$ASK_CONDS" || true)"
[ -n "$ASK_MISS" ] && printf '    리마인더에 없는 조건:\n%s\n' "$ASK_MISS"
check "원칙에서 묻는 조건 낱말을 여럿 뽑는다" "[ \"\$(grep -c . <<<\"\$ASK_CONDS\")\" -gt 1 ]"
check "리마인더에 원칙의 묻는 조건 낱말이 모두 있다" "[ -z \"\$ASK_MISS\" ]"
# 상한은 spec 2026-11-13-v2-rebuild-design 「완료 기준」의 값이다(리마인더는 줄바꿈 제외).
REMIND_N="$(tr -d '\n' < "$REMIND_TXT" | LC_ALL=C.UTF-8 wc -m | tr -d ' ')"
ALWAYS_N="$(cat "$CANON" "$VIEW" | LC_ALL=C.UTF-8 wc -m | tr -d ' ')"
echo "    리마인더 $REMIND_N 자, 원칙 사본과 상시 보기 합계 $ALWAYS_N 자"
check "리마인더가 217자 이하다" "[ -s \"\$REMIND_TXT\" ] && [ \"\$REMIND_N\" -le 217 ]"
check "원칙 사본과 상시 보기의 합이 9,600자 미만이다" "[ -s \"\$VIEW\" ] && [ \"\$ALWAYS_N\" -lt 9600 ]"

echo "[스킬 description — 호출 조건만 짧게]"
# description 은 모든 세션에 실리므로 짧을수록 다른 지시가 덜 밀린다. 기준은 v2 설계 때의 합계 2,002자다
# (spec 2026-11-13-v2-rebuild-design 「스킬」). 글자 수는 frontmatter 의 description 값으로 센다.
SK_DESC="$BW/skill-desc.txt"
for f in "$HERE"/skills/*/SKILL.md; do
  awk 'NR==1 && /^---\r?$/ { f=1; next } f && /^---\r?$/ { exit } f' "$f" | grep -m1 '^description:' | sed 's/^description:[[:space:]]*//; s/\r$//'
done > "$SK_DESC"
# 접힘·블록 형식(`description: >`·`|`)은 값이 다음 줄들로 넘어가 위의 한 줄 추출과 합계가 값을 놓친다.
FOLD_BAD=""
for f in "$HERE"/skills/*/SKILL.md "$HERE"/agents/*.md; do
  awk 'NR==1 && /^---\r?$/ { f=1; next } f && /^---\r?$/ { exit } f' "$f" | grep -qE '^description:[[:space:]]*[>|][-+0-9]*[[:space:]]*\r?$' \
    && FOLD_BAD="$FOLD_BAD ${f#"$HERE"/}"
done
[ -n "$FOLD_BAD" ] && echo "    접힘 형식 description:$FOLD_BAD"
check "스킬·에이전트 description 이 접힘·블록 형식이 아니다" "[ -z \"\$FOLD_BAD\" ]"
SK_DESC_N="$(tr -d '\n' < "$SK_DESC" | LC_ALL=C.UTF-8 wc -m | tr -d ' ')"
echo "    description 합계: $SK_DESC_N 자"
check "스킬 description 합계가 2,002자보다 작다" "[ -s \"\$SK_DESC\" ] && [ \"\$SK_DESC_N\" -lt 2002 ]"
SK_DESC_BW="$(banned_report "$BW/pairs" "$SK_DESC" "$BW/excl")"
[ -n "$SK_DESC_BW" ] && printf '    description 의 금지어:\n%s\n' "$SK_DESC_BW"
check "스킬 description 에 백틱 밖 금지어가 없다" "[ -s \"\$SK_DESC\" ] && [ -z \"\$SK_DESC_BW\" ]"

echo "[원칙 조항 ID — 스킬·에이전트는 v2 원칙에 있는 조항만 가리킨다]"
# v1 조항을 지운 뒤에도 스킬이 그 ID 를 부르면 읽는 쪽이 없는 규칙을 찾는다. 유효한 ID 는 저장소 뿌리의
# agent-principles.md 에서 뽑는다. 조항 ID 의 전체 집합은 참고서 두 파일이 적은 ID(v1·삭제 조항 포함)와 v1 원칙
# (태그 archive/v1-final)의 ID 다. 스킬이 `- **`ID`**` 형태로 스스로 정의한 규칙(managing-docs 의 문서 규칙)은
# 그 스킬이 소유한 규칙이라 원칙 인용으로 보지 않는다. 참고서의 「v1 조항 근거」 절은 범위 밖이지만 스킬이
# 같은 이름의 절을 두면 그 절도 뺀다.
V2_IDS="$(grep -oE '\*\*`[A-Z][A-Z0-9-]+`\*\*' "$CANON" | tr -d '*`' | sort -u)"
CLAUSE_UNIV="$( { cat "$HERE/docs/domain-discipline.md" "$HERE/docs/domain-korean.md" | grep -oE '`[A-Z][A-Z0-9]*(-[A-Z0-9]+)+`' | tr -d '`'
  (cd "$HERE" && git show archive/v1-final:agent-principles.md 2>/dev/null) | grep -oE '\*\*`[A-Z][A-Z0-9-]+`\*\*' | tr -d '*`'; } | sort -u || true)"
SKILL_OWN_IDS="$(cat "$HERE"/skills/*/SKILL.md "$HERE"/skills/*/references/*.md 2>/dev/null | grep -oE '^- \*\*`[A-Z][A-Z0-9-]+`\*\*' | sed 's/^- \*\*`//; s/`\*\*$//' | sort -u || true)"
NON_V2_IDS="$(comm -23 <(printf '%s\n' "$CLAUSE_UNIV") <(printf '%s\n%s\n' "$V2_IDS" "$SKILL_OWN_IDS" | sort -u) | grep -v '^$' || true)"
non_v2_hits() {  # $1=파일 → v2 원칙에 없는 조항 ID(「v1 조항 근거」 절 밖)
  [ -n "$NON_V2_IDS" ] || return 0
  awk '{ sub(/\r$/, "") } /^## / { v1 = (index($0, "## v1 조항 근거") == 1) } !v1' "$1" \
    | grep -owE "$(printf '%s' "$NON_V2_IDS" | tr '\n' '|')" | sort -u | tr '\n' ' ' || true
}
check "조항 ID 집합에 v2 조항과 v1 조항이 함께 있다" "grep -qx 'ROLES' <<<\"\$V2_IDS\" && grep -qx 'ASK-OPTIONS' <<<\"\$NON_V2_IDS\" && ! grep -qx 'ROLES' <<<\"\$NON_V2_IDS\""
CID_FX="$TEST_TMP/clause-ids.md"
# FOCUSED 는 하이픈이 없어 참고서의 ID 정규식에는 안 잡히고 v1 원칙에서만 들어온다.
printf '%s\n' '`ASK-OPTIONS` 를 따른다' '`FOCUSED` 와 `ROLES` 와 `BASE-UPDATED`' '## v1 조항 근거' '`NO-ASSUME`' > "$CID_FX"
check "조항 ID 검사가 v1 절 밖의 v2 에 없는 조항만 잡는다" "[ \"\$(non_v2_hits \"\$CID_FX\")\" = 'ASK-OPTIONS FOCUSED ' ]"
# 스킬이 스스로 정의한 ID 는 원칙 인용에서 빠진다. 그 ID 가 v1 원칙 ID 와 겹치면 v1 조항 인용이 예외로 숨는다.
V1_IDS="$( (cd "$HERE" && git show archive/v1-final:agent-principles.md 2>/dev/null) | grep -oE '\*\*`[A-Z][A-Z0-9-]+`\*\*' | tr -d '*`' | sort -u || true)"
OWN_V1="$(comm -12 <(printf '%s\n' "$SKILL_OWN_IDS") <(printf '%s\n' "$V1_IDS") | grep -v '^$' || true)"
[ -n "$OWN_V1" ] && echo "    v1 원칙 ID 와 겹치는 스킬 정의 ID: $(printf '%s ' $OWN_V1)"
check "스킬이 정의한 ID 가 v1 원칙 ID 와 겹치지 않는다" "[ -n \"\$V1_IDS\" ] && [ -z \"\$OWN_V1\" ]"
CID_BAD=""
while IFS= read -r f; do
  [ -f "$HERE/$f" ] || continue
  h="$(non_v2_hits "$HERE/$f")"
  [ -n "$h" ] && CID_BAD="$CID_BAD [$f: $h]"
done <<EOF
$(cd "$HERE" && git ls-files --cached --others --exclude-standard -- 'skills/*.md' 'agents/*.md')
EOF
[ -n "$CID_BAD" ] && printf '    v2 원칙에 없는 조항 ID:%s\n' "$CID_BAD"
check "스킬·에이전트가 v2 원칙에 없는 조항 ID 를 인용하지 않는다" "[ -z \"\$CID_BAD\" ]"

echo "----"; echo "PASS=$pass FAIL=$fail"; [ "$fail" -eq 0 ]
