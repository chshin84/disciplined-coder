#!/usr/bin/env bash
# 선행연구 검증자 설정 선택 시험 하네스의 검사다. 일회성 하네스라 scripts/test_*.sh 일괄 실행에 넣지 않는다.
# 계약: FAIL=0.
set -euo pipefail
HERE="$(cd "$(dirname "$0")" && pwd)"
command -v cygpath >/dev/null && HERE="$(cygpath -m "$HERE")"
ROOT="$(cd "$HERE/../.." && pwd)"
. "$ROOT/scripts/_test_check.sh"
. "$ROOT/scripts/_json_valid.sh"
_json_python
PY="$_JSON_PY"
export PYTHONUTF8=1
FX="$(mktemp -d)"; trap 'rm -rf "$FX"' EXIT
CASES="$HERE/cases.json"

echo "== 시험 자료"
check "cases.json 이 JSON 으로 읽힌다" "$PY -I -c 'import json,sys; json.load(open(sys.argv[1],encoding=\"utf-8\"))' '$CASES'"
check "check_cases.py 가 통과한다" "$PY -I '$HERE/check_cases.py' '$CASES' >/dev/null"
broken() {  # broken <이름> <파이썬 변형식>: cases 를 고친 사본을 만든다
  $PY -I -c "
import json,sys
d=json.load(open(sys.argv[1],encoding='utf-8'))
$2
json.dump(d,open(sys.argv[2],'w',encoding='utf-8'),ensure_ascii=False)" "$CASES" "$FX/$1.json"
}
broken drop_error "i=[k for k,x in enumerate(d['items']) if x['truth'] is False][0]; d['items'].pop(i)" 2>/dev/null || true
broken empty_note "d['items'][0]['check_note']=''" 2>/dev/null || true
broken no_2605 "d['items']=[x for x in d['items'] if x['url']!='https://arxiv.org/abs/2605.10039']" 2>/dev/null || true
for b in drop_error empty_note no_2605; do
  check "고장 낸 사본($b)을 check_cases.py 가 거부한다" "[ -f '$FX/$b.json' ] && ! $PY -I '$HERE/check_cases.py' '$FX/$b.json' >/dev/null"
done

echo "== 실행기"
export DC_EVAL_CLAUDE="$PY -I $HERE/fake_claude.py"
export EVAL_TMP="$FX/evaltmp"
RUN="$PY -I $HERE/run.py"
mini="$FX/mini.json"
$PY -I -c "
import json,sys
d=json.load(open(sys.argv[1],encoding='utf-8'))
d['items']=[x for x in d['items'] if x['id'] in ('num-t1','num-f1')]
json.dump(d,open(sys.argv[2],'w',encoding='utf-8'),ensure_ascii=False)" "$CASES" "$mini"
for t in test_build_cmd_tools test_parse_output_fenced test_prompt_sha_changes_key; do
  check "$t" "$PY -I '$HERE/harness_tests.py' $t"
done
out="$FX/err.jsonl"
FAKE_MODE=error $RUN --cases "$mini" --stage extract --model m --effort low --out "$out" >/dev/null 2>&1 || true
rc=0; FAKE_MODE=error $RUN --cases "$mini" --stage extract --model m --effort low --out "$out" >/dev/null 2>&1 || rc=$?
check "test_error_retry_cap" "[ $rc -ne 0 ] && grep -q '\"attempt\": 2' '$out'"
ok="$FX/ok.jsonl"
$RUN --cases "$mini" --stage extract --model m --effort low --out "$ok" >/dev/null 2>&1 || true
n1=$(wc -l < "$ok" 2>/dev/null || echo 0)
$RUN --cases "$mini" --stage extract --model m --effort low --out "$ok" >/dev/null 2>&1 || true
n2=$(wc -l < "$ok" 2>/dev/null || echo 0)
check "test_cached_skip" "[ $n1 -ge 1 ] && [ $n1 -eq $n2 ] && grep -q '\"error\": \"\"' '$ok'"
mm="$FX/mm.jsonl"
FAKE_MODE=mismatch $RUN --cases "$mini" --stage extract --model m --effort low --out "$mm" >/dev/null 2>&1 || true
check "test_model_mismatch_flagged" "grep -q '모델 불일치' '$mm'"

echo "PASS=$pass FAIL=$fail"
[ "$fail" -eq 0 ]
