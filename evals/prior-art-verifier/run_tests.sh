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

echo "== 재측정 자료"
V2="$HERE/cases-v2.json"
check "cases-v2.json 이 check_cases.py 를 통과한다" "[ -f '$V2' ] && $PY -I '$HERE/check_cases.py' '$V2' >/dev/null"
check "hard_kind 마다 참 항목과 오류 항목이 1건씩 있다" "[ -f '$V2' ] && $PY -I -c '
import json,sys,collections
d=json.load(open(sys.argv[1],encoding=\"utf-8\"))
c=collections.Counter((x[\"hard_kind\"],x[\"truth\"]) for x in d[\"items\"] if \"hard_kind\" in x)
ks=[\"context\",\"conditions\",\"table\",\"korean\",\"fake-200\"]
sys.exit(0 if all(c[(k,t)]==1 for k in ks for t in (True,False)) and len(c)==10 else 1)' '$V2'"
check "num-t3 가 오류 항목이고 check_note 에 정정 이유가 있다" "[ -f '$V2' ] && $PY -I -c '
import json,sys
d=json.load(open(sys.argv[1],encoding=\"utf-8\"))
x=[i for i in d[\"items\"] if i[\"id\"]==\"num-t3\"][0]
n=x[\"check_note\"]
sys.exit(0 if x[\"truth\"] is False and \"다중 비교 보정 뒤\" in n and \"결정 기록 2\" in n else 1)' '$V2'"
V3="$HERE/cases-v3.json"
check "cases-v3.json 이 check_cases.py 를 통과한다" "[ -f '$V3' ] && $PY -I '$HERE/check_cases.py' '$V3' >/dev/null"
check "quo-t1·quo-t3·hard-f200-t1 이 오류 항목이고 check_note 에 정정 이유와 완화 표현이 있다" "[ -f '$V3' ] && $PY -I -c '
import json,sys
d=json.load(open(sys.argv[1],encoding=\"utf-8\"))
m={i[\"id\"]:i for i in d[\"items\"]}
want={\"quo-t1\":\"one of the most reliable\",\"quo-t3\":\"tend to be more effective\",\"hard-f200-t1\":\"sometimes useful\"}
ok=all(m[k][\"truth\"] is False and \"완화 표현\" in m[k][\"check_note\"] and \"2026-10-21 사용자 결정\" in m[k][\"check_note\"] and w in m[k][\"check_note\"] for k,w in want.items())
sys.exit(0 if ok else 1)' '$V3'"
check "v3 에서 hard_kind 마다 참 항목과 오류 항목이 1건씩 있다" "[ -f '$V3' ] && $PY -I -c '
import json,sys,collections
d=json.load(open(sys.argv[1],encoding=\"utf-8\"))
c=collections.Counter((x[\"hard_kind\"],x[\"truth\"]) for x in d[\"items\"] if \"hard_kind\" in x)
ks=[\"context\",\"conditions\",\"table\",\"korean\",\"fake-200\"]
sys.exit(0 if all(c[(k,t)]==1 for k in ks for t in (True,False)) and len(c)==10 else 1)' '$V3'"
check "v3 의 id 가 v2 의 id 를 모두 유지한다" "[ -f '$V3' ] && $PY -I -c '
import json,sys
a={x[\"id\"] for x in json.load(open(sys.argv[1],encoding=\"utf-8\"))[\"items\"]}
b={x[\"id\"] for x in json.load(open(sys.argv[2],encoding=\"utf-8\"))[\"items\"]}
sys.exit(0 if a<=b else 1)' '$V2' '$V3'"
hk="$FX/hk.json"
$PY -I -c "
import json,sys
d=json.load(open(sys.argv[1],encoding='utf-8'))
d['items'][0]['hard_kind']='context'
json.dump(d,open(sys.argv[2],'w',encoding='utf-8'),ensure_ascii=False)" "$CASES" "$hk"
check "카테고리와 맞지 않는 hard_kind 를 check_cases.py 가 거부한다" "! $PY -I '$HERE/check_cases.py' '$hk' >/dev/null"

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

echo "== 집계기"
for t in test_missing_judgment_is_failure test_no_quote_excluded test_unverifiable_counts_as_rejection test_zero_noise test_noise_tolerance test_failures_block_selection test_select_extract_single test_map_scoring test_xhigh_effort_allowed test_judge_borrows_true_quote test_stale_prompt_ignored test_true_without_quote_counts_as_rejection test_judge_respects_frozen_exists test_map_missing_cells_fail; do
  check "$t" "$PY -I '$HERE/harness_tests.py' $t 2>/dev/null"
done
echo "== 구성 전체 재측정"
for t in test_def_prompt_matches_workflow test_escalate_input_uses_rejudge test_replay_uses_workflow_merge test_replay_passes_refetch_and_rejudge test_def_output_ignores_other_keys test_report_v3_uses_given_cases_and_baseline test_report_v3_lists_remaining_unsure test_confident_wrong_counted test_merge_condition_item_level; do
  check "$t" "$PY -I '$HERE/harness_tests.py' $t 2>/dev/null"
done
echo "PASS=$pass FAIL=$fail"
[ "$fail" -eq 0 ]
