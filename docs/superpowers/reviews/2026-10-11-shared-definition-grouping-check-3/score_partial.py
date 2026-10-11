# score_partial.py: 최종 리뷰 뒤 바뀐 문안을 세 요청(order-processing, npb, auth-migration)에서만 채점한다. 기준은 요청마다 유효 실행 5회 중 기대 분할 4회 이상이다.
import json, os
D = os.path.dirname(os.path.abspath(__file__))
exp = json.load(open(os.path.join(D, "expected-amended.json"), encoding="utf-8"))
lists = json.load(open(os.path.join(D, "lists.json"), encoding="utf-8"))
REQS = ["order-processing", "npb", "auth-migration"]
def norm(p): return sorted(sorted(g) for g in p)
lines = ["| 요청 | 유효 실행 | 기대 분할 일치 | 판정 |", "|---|---|---|---|"]; adopt = True
for r in REQS:
    v = h = 0
    for n in range(1, 6):
        f = os.path.join(D, "runs", f"new__{r}__{n}.txt")
        if not os.path.exists(f): continue
        t = open(f, encoding="utf-8").read(); a, b = t.find("{"), t.rfind("}")
        try: part = json.loads(t[a:b + 1])["partition"]
        except Exception: continue
        if sorted(i for g in part for i in g) != sorted(x["id"] for x in lists[r]["subprojects"]): continue
        v += 1; h += norm(part) == norm(exp[r]["partition"])
    ok = v == 5 and h >= 4; adopt = adopt and ok
    lines.append(f"| {r} | {v} | {h} | {'통과' if ok else '미달'} |")
lines += ["", "ADOPT" if adopt else "NOT ADOPT"]
open(os.path.join(D, "result.md"), "w", encoding="utf-8").write("\n".join(lines) + "\n"); print("\n".join(lines))
