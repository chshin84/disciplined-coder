"""시험 자료 cases.json 의 형식을 검사한다. 위반을 한 줄씩 내고, 위반이 있으면 1 로 끝난다."""
import collections
import json
import sys

CATEGORIES = ("access", "exists", "quote", "numbers_conditions", "direction", "scope")
HARD_KINDS = {"context": "direction", "conditions": "numbers_conditions", "table": "numbers_conditions", "korean": "direction", "fake-200": "access"}
PROBE_URL = "https://arxiv.org/abs/2605.10039"


def violations(d):
    out = []
    items = d.get("items", [])
    counts = collections.Counter()
    for x in items:
        if x.get("category") not in CATEGORIES:
            out.append(f"{x.get('id')}: 알 수 없는 카테고리 {x.get('category')}")
        counts[(x.get("category"), x.get("truth"))] += 1
        if "hard_kind" in x and HARD_KINDS.get(x["hard_kind"]) != x.get("category"):
            out.append(f"{x.get('id')}: hard_kind {x['hard_kind']} 가 표에 없거나 카테고리 {x.get('category')} 와 맞지 않는다")
        if not str(x.get("check_note", "")).strip():
            out.append(f"{x.get('id')}: check_note 가 비었다")
    for c in CATEGORIES:
        if counts[(c, True)] != counts[(c, False)] or counts[(c, True)] == 0:
            out.append(f"{c}: 참 {counts[(c, True)]}건, 오류 {counts[(c, False)]}건으로 수가 다르거나 없다")
    for m in d.get("map_cases", []):
        t = [c["grounded"] for c in m.get("truth", [])]
        if not t or t.count(True) != t.count(False):
            out.append(f"{m.get('id')}: 근거 있는 칸과 없는 칸의 수가 다르다")
    if not d.get("map_cases"):
        out.append("map_cases 가 없다")
    ids = [x.get("id") for x in items] + [m.get("id") for m in d.get("map_cases", [])]
    for i, n in collections.Counter(ids).items():
        if n > 1:
            out.append(f"{i}: id 가 겹친다")
    if not any(x.get("url") == PROBE_URL and x.get("category") == "direction" and x.get("truth") is True for x in items):
        out.append(f"{PROBE_URL} 의 direction 참 항목이 없다")
    return out


if __name__ == "__main__":
    sys.stdout.reconfigure(encoding="utf-8")
    v = violations(json.load(open(sys.argv[1], encoding="utf-8")))
    for line in v:
        print(line)
    sys.exit(1 if v else 0)
