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

echo "[비교 — 판정, 행별 위반 수, 금지어 횟수]"
# 픽스처로 본다. 저장소 과제와 측정 결과에 기대지 않는다.
T="$(mktemp -d)"; trap 'rm -rf "$T"' EXIT
mkdir -p "$T/cases/a1" "$T/cases/a2" "$T/cases/b1" "$T/results/fa" "$T/results/fb" "$T/results/fc"
printf -- '---\ntags: [dev]\nkind: should\npair: a2\ntype: chat\nfailure: [confirm-loop, conflict:a]\nclause: [X-ONE]\n---\n\np\n' > "$T/cases/a1/prompt.md"
printf -- '---\ntags: [dev]\nkind: should-not\npair: a1\ntype: chat\nfailure: [conflict:b]\nclause: [X-ONE]\n---\n\np\n' > "$T/cases/a2/prompt.md"
printf -- '---\ntags: [dev]\nkind: should\npair: b1\ntype: tool\nfailure: [language]\nclause: [Y-TWO]\n---\n\np\n' > "$T/cases/b1/prompt.md"
for c in a1 a2 b1; do echo c > "$T/cases/$c/criteria.md"; done
cat > "$T/banned.md" <<'BANEOF'
### 금지 표현

| 쓰지 않는 말 | 대신 쓰는 말 | 적용 대상 | 분류 | 제외 |
|---|---|---|---|---|
| `판` | 버전 | 문서와 답변 | 평소에 쓰지 않는 말 | `판정` |
BANEOF
# 위반: fa 는 a1 2·a2 1·b1 2 = 5, fb 는 a1 1·a2 0·b1 2 = 3, fc 는 fa 와 같은 5.
mkres() {  # $1=라벨, $2..=a1·a2·b1 의 회차별 위반(t/f) 아홉 개, 마지막 인자=a1 1회차 응답
  local l="$1"; shift; local v=("$@")
  json_run 'import json,sys
o,l,resp=sys.argv[1],sys.argv[2],sys.argv[12]
v=[x=="t" for x in sys.argv[3:12]]
runs=[]
for i,c in enumerate(["a1","a2","b1"]):
    for r in range(3):
        runs.append({"case":c,"run":r+1,"violated":v[i*3+r],"response":resp if (c=="a1" and r==0) else "응답","judge_note":""})
json.dump({"commit":"x","tag":"dev","model":"m","judge_model":"j","loaded_lines":10,"loaded_chars":100,"runs":runs},open(o,"w",encoding="utf-8"),ensure_ascii=False)' "$T/results/$l/result.json" "$l" "${v[@]}"
}
mkres fa t t f  t f f  t t f  "응답"
mkres fb t f f  f f f  t t f  "새 판을 낸다. 판정은 판에 따른다."
mkres fc t t f  t f f  t t f  "응답"
cmp() { EVAL_CASES="$T/cases" EVAL_RESULTS="$T/results" EVAL_BANNED="$T/banned.md" bash "$HERE/scripts/eval_compare.sh" "$@" 2>&1 || true; }
O_AB="$(cmp fa fb)"; O_BA="$(cmp fb fa)"; O_AC="$(cmp fa fc)"; O_B="$(cmp fb)"
check "적으면 개선이다"              "[ \"\$(printf '%s\n' \"\$O_AB\" | head -1)\" = 'A=5 B=3 판정=개선' ]"
check "많으면 악화다"                "[ \"\$(printf '%s\n' \"\$O_BA\" | head -1)\" = 'A=3 B=5 판정=악화' ]"
check "같으면 동률이다"              "[ \"\$(printf '%s\n' \"\$O_AC\" | head -1)\" = 'A=5 B=5 판정=동률' ]"
check "failure 행이 그 값의 위반을 센다" "printf '%s\n' \"\$O_AB\" | grep -qx 'failure confirm-loop A=2 B=1'"
check "kind 행이 그 값의 위반을 센다"    "printf '%s\n' \"\$O_AB\" | grep -qx 'kind should A=4 B=3'"
check "conflict:* 가 conflict 행에 합쳐진다" "printf '%s\n' \"\$O_AB\" | grep -qx 'failure conflict A=3 B=1'"
check "금지어는 횟수로 세고 제외어는 뺀다" "[ \"\$(printf '%s\n' \"\$O_AB\" | tail -1)\" = '금지어 A=0 B=2' ]"
check "라벨 하나면 요약 한 줄을 낸다"     "[ \"\$O_B\" = '라벨=fb 위반=3 금지어=2 적재줄=10 적재자=100' ]"

echo "[판정 응답 읽기 — 판정 모델의 답에서 위반 여부를 꺼낸다]"
judge() { json_run 'import runpy,sys; p=sys.argv[1]; m=runpy.run_path(p); print(m["parse_judge"](sys.argv[2]))' "$HERE/scripts/_eval_run.py" "$1" 2>&1 || true; }
check "JSON 만 있으면 그 값을 읽는다"     "[ \"\$(judge '{\"violated\": true, \"note\": \"x\"}')\" = \"(True, 'x')\" ]"
check "앞뒤 설명이 있어도 JSON 을 찾는다" "[ \"\$(judge '판정입니다. {\"violated\": false, \"note\": \"ok\"} 끝')\" = \"(False, 'ok')\" ]"
check "JSON 이 없으면 None 이다"         "[ \"\$(judge '모르겠습니다')\" = 'None' ]"

echo "----"; echo "PASS=$pass FAIL=$fail"; [ "$fail" -eq 0 ]
