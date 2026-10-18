#!/usr/bin/env bash
# 평가 결과를 비교한다. 사용: eval_compare.sh <라벨>  또는  eval_compare.sh <라벨 A> <라벨 B>
# 라벨 하나면 위반 합계·금지어 횟수·세션 적재 분량을 한 줄로, 둘이면 B 를 A 와 비교한 판정과 행별 위반 수를 낸다.
# 과제·결과·금지어 표의 위치는 EVAL_CASES·EVAL_RESULTS·EVAL_BANNED 로 바꿀 수 있다(시험이 픽스처를 넘긴다).
set -euo pipefail
HERE="$(cd "$(dirname "$0")/.." && pwd)"
. "$HERE/scripts/_json_valid.sh"
. "$HERE/hooks/_banned_words.sh"
CASES="${EVAL_CASES:-$HERE/evals/principles/cases}"
RESULTS="${EVAL_RESULTS:-$HERE/evals/principles/results}"
BANNED="${EVAL_BANNED:-$HERE/korean-banned-words.md}"
[ "$#" -ge 1 ] && [ "$#" -le 2 ] || { echo "사용: eval_compare.sh <라벨> [<라벨 B>]" >&2; exit 2; }
W="$(mktemp -d)"; trap 'rm -rf "$W"' EXIT
banned_parse "$BANNED" "$W/pairs" "$W/toks" "$W/excl"
json_run 'import runpy,sys; p=sys.argv[1]; sys.argv=["_eval_lib"]+sys.argv[2:]; runpy.run_path(p, run_name="__main__")' \
  "$HERE/scripts/_eval_lib.py" compare "$CASES" "$RESULTS" "$W/pairs" "$W/excl" "$@"
