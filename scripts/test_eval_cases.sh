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

echo "----"; echo "PASS=$pass FAIL=$fail"; [ "$fail" -eq 0 ]
