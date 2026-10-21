#!/usr/bin/env bash
# 선행연구 검증자 설정 선택 시험 하네스의 검사다. 일회성 하네스라 scripts/test_*.sh 일괄 실행에 넣지 않는다.
# 계약: FAIL=0.
set -euo pipefail
HERE="$(cd "$(dirname "$0")" && pwd)"
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

echo "PASS=$pass FAIL=$fail"
[ "$fail" -eq 0 ]
