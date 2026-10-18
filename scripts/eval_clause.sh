#!/usr/bin/env bash
# 조항별 클린룸 시험을 실행해 evals/principles/results/clauses/{gen,judge}.jsonl 에 덧붙인다.
# 사용: eval_clause.sh [<단위 이름>...]   (인자가 없으면 evals/principles/clauses/ 의 모든 단위)
# 시험 단위와 판정 규칙은 spec 「조항별 클린룸 시험」, 키와 기록 형식은 scripts/_eval_clause.py 머리가 정한다.
# 생성 키가 기록에 있는 질문은 다시 생성하지 않는다(같은 질문 반복 금지, 2026-10-18 사용자 지시).
# 위치는 EVAL_CASES·EVAL_CLAUSES·EVAL_RESULTS 로 바꿀 수 있다(smoke 가 픽스처를 넘긴다).
set -euo pipefail
HERE="$(cd "$(dirname "$0")/.." && pwd)"
. "$HERE/scripts/_resolve_home.sh"
. "$HERE/scripts/_json_valid.sh"
. "$HERE/scripts/_eval_env.sh"
CASES="${EVAL_CASES:-$HERE/evals/principles/cases}"
CLAUSES="${EVAL_CLAUSES:-$HERE/evals/principles/clauses}"
RESULTS="${EVAL_RESULTS:-$HERE/evals/principles/results/clauses}"
unset CLAUDE_HOME_DIR CLAUDE_CONFIG_DIR
REAL="$(resolve_home claude)"
eval_load_key || exit 2
mkdir -p "$RESULTS"
LOCK="$RESULTS/.lock"
# 두 실행이 같은 기록으로 계획을 세우면 같은 질문을 둘 다 생성한다.
( set -o noclobber; echo $$ > "$LOCK" ) 2>/dev/null || { echo "ERROR: $LOCK 이 있다. 다른 실행이 끝났는지 확인하고 지워라." >&2; exit 2; }
FP0="$(eval_fingerprint "$REAL")"
T="$(eval_tmpdir)" || { rm -f "$LOCK"; exit 2; }
cleanup() {
  local rc=$?
  rm -f "$LOCK"
  rm -rf "$T" 2>/dev/null || echo "WARNING: 임시 폴더 $T 를 지우지 못했다." >&2
  if [ "$FP0" != "$(eval_fingerprint "$REAL")" ]; then
    echo "ERROR: 실제 설정 파일의 지문이 바뀌었다. 되돌리지 않았다. 바뀐 파일:" >&2
    diff <(printf '%s\n' "$FP0") <(eval_fingerprint "$REAL") >&2 || true
    rc=1
  fi
  exit "$rc"
}
trap cleanup EXIT INT TERM
json_run 'import runpy,sys; p=sys.argv[1]; sys.argv=[p]+sys.argv[2:]; runpy.run_path(p, run_name="__main__")' \
  "$HERE/scripts/_eval_clause.py" run "$CASES" "$CLAUSES" "$RESULTS" "$T" "$@"
