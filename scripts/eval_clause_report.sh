#!/usr/bin/env bash
# 조항별 클린룸 시험의 판정을 단위마다 한 줄로 낸다. 모델을 호출하지 않는다.
# 사용: eval_clause_report.sh [<단위 이름>...]
# 판정 규칙은 scripts/_eval_clause.py 의 report_unit 이 정한다. 금지어 수는 대화 답(type: chat)만 센다.
set -euo pipefail
HERE="$(cd "$(dirname "$0")/.." && pwd)"
. "$HERE/scripts/_json_valid.sh"
. "$HERE/hooks/_banned_words.sh"
CASES="${EVAL_CASES:-$HERE/evals/principles/cases}"
CLAUSES="${EVAL_CLAUSES:-$HERE/evals/principles/clauses}"
RESULTS="${EVAL_RESULTS:-$HERE/evals/principles/results/clauses}"
BANNED="${EVAL_BANNED:-$HERE/korean-banned-words.md}"
W="$(mktemp -d)"; trap 'rm -rf "$W"' EXIT
banned_parse "$BANNED" "$W/pairs" "$W/toks" "$W/excl"
json_run 'import runpy,sys; p=sys.argv[1]; sys.argv=[p]+sys.argv[2:]; runpy.run_path(p, run_name="__main__")' \
  "$HERE/scripts/_eval_clause.py" report "$CASES" "$CLAUSES" "$RESULTS" "$W/pairs" "$W/excl" "$@"
