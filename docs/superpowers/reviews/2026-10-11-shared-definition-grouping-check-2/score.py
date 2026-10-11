# score.py: runs/ 의 응답 원문에서 JSON 을 꺼내 expected.json 과 대조하고 result.md 를 UTF-8 로 쓴다.
import json, glob, os
D = os.path.dirname(os.path.abspath(__file__))
exp = json.load(open(os.path.join(D, "expected.json"), encoding="utf-8"))
lists = json.load(open(os.path.join(D, "lists.json"), encoding="utf-8"))
REQS = ["bond-tool", "report-quality", "auth-migration", "order-processing", "two-jobs", "npb"]
def norm(p): return sorted(sorted(g) for g in p)
def parse(text):
    a, b = text.find("{"), text.rfind("}")
    if a < 0 or b < a: return None
    try: return json.loads(text[a:b + 1])
    except json.JSONDecodeError: return None
stats = {}
for f in sorted(glob.glob(os.path.join(D, "runs", "*.txt"))):
    name = os.path.basename(f)[:-4]
    if name.endswith(".format-error"): continue
    cond, req, _ = name.split("__")
    s = stats.setdefault((req, cond), {"valid": 0, "format": 0, "hit": 0})
    out = parse(open(f, encoding="utf-8").read())
    ids = {x["id"] for x in lists[req]["subprojects"]}
    part = out.get("partition") if isinstance(out, dict) else None
    flat = [i for g in part for i in g] if isinstance(part, list) and all(isinstance(g, list) for g in part) else None
    if flat is None or sorted(flat) != sorted(ids):
        s["format"] += 1; continue
    s["valid"] += 1
    s["hit"] += norm(part) == norm(exp[req]["partition"])
lines = ["| 요청 | 조건 | 유효 실행 | 형식 오류 | 기대 분할 일치 | 판정 |", "|---|---|---|---|---|---|"]
adopt = True
for req in REQS:
    for cond in ("new", "current"):
        s = stats.get((req, cond), {"valid": 0, "format": 0, "hit": 0})
        if cond == "new":
            verdict = "통과" if s["valid"] == 5 and s["hit"] >= 4 else "미달"
            adopt = adopt and verdict == "통과"
        else:
            verdict = "비교"
        lines.append(f"| {req} | {cond} | {s['valid']} | {s['format']} | {s['hit']} | {verdict} |")
lines.append(""); lines.append("ADOPT" if adopt else "NOT ADOPT")
open(os.path.join(D, "result.md"), "w", encoding="utf-8").write("\n".join(lines) + "\n")
print(lines[-1])
