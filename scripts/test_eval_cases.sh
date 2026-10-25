#!/usr/bin/env bash
# 에이전트원칙 실패 평가 세트(evals/principles/cases)의 형식과 비밀 패턴을 본다.
# 개수와 비율은 검사하지 않는다 — 과제를 하나 더하거나 빼도 깨지지 않게, 구성은 README 「과제 구성」에만 적는다.
set -euo pipefail
HERE="$(cd "$(dirname "$0")/.." && pwd)"
. "$HERE/scripts/_test_check.sh"
. "$HERE/scripts/_json_valid.sh"
CASES="$HERE/evals/principles/cases"
# 경로는 인자로 넘긴다. Git Bash 는 인자의 /d/… 만 D:/… 로 바꾸고 프로그램 문자열 안의 경로는 그대로 둔다.
lib() { json_run 'import runpy,sys; p=sys.argv[1]; sys.argv=["_eval_lib"]+sys.argv[2:]; runpy.run_path(p, run_name="__main__")' "$HERE/scripts/_eval_lib.py" "$@" 2>&1 || true; }

echo "[과제 머리 — 필드와 태그]"
check "과제가 하나 이상 있다" "[ -n \"\$(ls -d '$CASES'/*/ 2>/dev/null)\" ]"
FIELDS="$(lib fields "$CASES")"
[ -n "$FIELDS" ] && printf '%s\n' "$FIELDS" | sed 's/^/    /'
check "모든 과제에 필드가 있고 tags 가 dev·holdout 중 하나다" "[ -z \"\$FIELDS\" ]"

echo "[짝 — pair 가 있는 과제를 가리키고 kind 가 다르다]"
PAIRS="$(lib pairs "$CASES")"
[ -n "$PAIRS" ] && printf '%s\n' "$PAIRS" | sed 's/^/    /'
check "모든 짝이 맞다" "[ -z \"\$PAIRS\" ]"

echo "[비밀 패턴 — 키·메일·PC 경로가 없다]"
SECRET="$(lib secrets "$CASES")"
[ -n "$SECRET" ] && printf '%s\n' "$SECRET" | sed 's/^/    /'
check "비밀 패턴이 없다" "[ -z \"\$SECRET\" ]"

# 단위 폴더마다 base 파일의 커밋 해시를 한 줄씩 낸다. 끝 줄바꿈이 없는 파일끼리 붙지 않게 파일마다 읽는다.
unit_bases() { for f in "$1"/*/base; do [ -f "$f" ] && { tr -d '\r\n ' < "$f"; echo; }; done | sort -u; }
echo "[시험 단위 — 현행 문안, 변경안, 질문 수]"
CLAUSES="$HERE/evals/principles/clauses"
UB="$(mktemp -d)"
for h in 7a2d26d $(unit_bases "$CLAUSES"); do git -C "$HERE" show "$h":agent-principles.md > "$UB/$h.md" 2>/dev/null || rm -f "$UB/$h.md"; done
UNITS="$(json_run 'import runpy,sys; p=sys.argv[1]; sys.argv=[p]+sys.argv[2:]; runpy.run_path(p, run_name="__main__")' "$HERE/scripts/_eval_clause.py" check "$CASES" "$CLAUSES" "$UB" 2>&1 || true)"
rm -rf "$UB"
[ -n "$UNITS" ] && printf '%s\n' "$UNITS" | sed 's/^/    /'
check "시험 단위 폴더가 하나 이상 있다" "[ -n \"\$(ls -d '$CLAUSES'/*/ 2>/dev/null)\" ]"
check "current.md 는 기준 원칙의 줄이고, new.md 가 있고, 단위마다 개발용 질문이 3개 이상이며 두 kind 가 모두 있다" "[ -z \"\$UNITS\" ]"
UBL="$(mktemp)"; git -C "$HERE" show 7a2d26d:korean-banned-words.md > "$UBL"
check "BANNED-LIST 의 current.md 가 기준 커밋의 목록 파일과 같다" "cmp -s '$UBL' '$CLAUSES/BANNED-LIST/current.md'"
rm -f "$UBL"

echo "[금지어 횟수 — 같은 낱말은 두 번 세고 제외어는 뺀다]"
# 픽스처로 본다. 저장소 과제와 측정 결과에 기대지 않는다. 클린룸 보고의 금지어 수가 이 함수를 쓴다.
T="$(mktemp -d)"; trap 'rm -rf "$T"' EXIT
mkdir -p "$T/ub/a" "$T/ub/b"; printf abc1234 > "$T/ub/a/base"; printf def5678 > "$T/ub/b/base"
UBS="$(unit_bases "$T/ub" | tr '\n' ' ')"
check "끝 줄바꿈이 없는 base 파일 둘의 커밋을 따로 읽는다" "[ \"\$UBS\" = 'abc1234 def5678 ' ]"
cat > "$T/banned.md" <<'BANEOF'
## 금지 표현

| 쓰지 않는 말 | 대신 쓰는 말 | 제외 |
|---|---|---|
| `판` | 버전 | `판정` |
BANEOF
. "$HERE/hooks/_banned_words.sh"
banned_parse "$T/banned.md" "$T/pairs" "$T/toks" "$T/excl"
BC="$(json_run 'import runpy,sys; m=runpy.run_path(sys.argv[1]); print(m["banned_count"]([sys.argv[2]], sys.argv[3], sys.argv[4]))' "$HERE/scripts/_eval_lib.py" "새 판을 낸다. 판정은 판에 따른다." "$T/pairs" "$T/excl" 2>&1 || true)"
check "금지어는 횟수로 세고 제외어는 뺀다" "[ \"\$BC\" = 2 ]"

echo "[클린룸 — 설정 폴더, 키, 작업 계획, 보고, pair]"
mkdir -p "$T/clean"
CL="$(json_run 'import runpy,sys; p=sys.argv[1]; sys.argv=[p]+sys.argv[2:]; runpy.run_path(p, run_name="__main__")' "$HERE/scripts/_test_eval_clause.py" "$HERE/scripts" "$T/clean" 2>&1 || true)"
while IFS= read -r line; do
  case "$line" in "OK "*) check "${line#OK }" true ;; "NG "*) check "${line#NG }" false ;; esac
done <<< "$CL"
check "클린룸 시험 프로그램이 끝까지 실행된다" "printf '%s\n' \"\$CL\" | tail -1 | grep -qx DONE"
printf '%s\n' "$CL" | grep -v '^\(OK\|NG\) \|^DONE$' | sed 's/^/    /' || true

echo "[상위 경로 — 평가 폴더 위에 CLAUDE.md 가 있으면 찾는다]"
. "$HERE/scripts/_eval_env.sh" 2>/dev/null || ancestor_claude() { echo "(_eval_env.sh 없음)"; }
mkdir -p "$T/anc/.claude" "$T/anc/x/y" "$T/plain/x/y"; echo m > "$T/anc/.claude/CLAUDE.md"
A1="$(ancestor_claude "$T/anc/x/y" 2>&1 || true)"; A2="$(ancestor_claude "$T/plain/x/y" 2>&1 || true)"
check "상위의 .claude/CLAUDE.md 를 가장 가까운 것부터 낸다" "[ \"\$A1\" = \"\$T/anc/.claude/CLAUDE.md\" ]"
check "픽스처 안에 없으면 픽스처 경로를 내지 않는다" "case \"\$A2\" in \"\$T\"/*) false ;; *) true ;; esac"

echo "[판정 응답 읽기 — 판정 모델의 답에서 위반 여부를 꺼낸다]"
judge() { json_run 'import runpy,sys; p=sys.argv[1]; m=runpy.run_path(p); print(m["parse_judge"](sys.argv[2]))' "$HERE/scripts/_eval_run.py" "$1" 2>&1 || true; }
check "JSON 만 있으면 그 값을 읽는다"     "[ \"\$(judge '{\"violated\": true, \"note\": \"x\"}')\" = \"(True, 'x')\" ]"
check "앞뒤 설명이 있어도 JSON 을 찾는다" "[ \"\$(judge '판정입니다. {\"violated\": false, \"note\": \"ok\"} 끝')\" = \"(False, 'ok')\" ]"
check "JSON 이 없으면 None 이다"         "[ \"\$(judge '모르겠습니다')\" = 'None' ]"

echo "----"; echo "PASS=$pass FAIL=$fail"; [ "$fail" -eq 0 ]
