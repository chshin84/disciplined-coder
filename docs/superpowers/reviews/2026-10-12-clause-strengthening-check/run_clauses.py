# run_clauses.py: 조항마다 원래 문구(orig)와 강화 문구(strong 또는 strong2)로 과제 10개를 도구 없는 claude -p 로 실행하고,
# 조건을 가린 채점기로 위반 수를 센다. 이미 있는 답과 점수는 다시 만들지 않으므로 중단 뒤 다시 실행하면 이어서 한다.
# 사용: python -I -X utf8 run_clauses.py [--variant strong|strong2|combined|top|half] [--tasks N] [--workers N] [조항ID...]
# combined 는 저장소의 agent-principles.md 전체(채택한 강화 문구를 모두 실은 문안)를, top 은 principle-top.md(위반이 5건 이상 준 조항만 강화한 문안)를, half 는 principle-half.md(원래 문구에서 과제 절반 이상이 위반한 조항만 강화한 문안)를 싣는다.
import json, os, re, subprocess, sys, tempfile
from concurrent.futures import ThreadPoolExecutor
D = os.path.dirname(os.path.abspath(__file__))
C = os.path.join(D, "clauses")
args = sys.argv[1:]
def opt(name, default):
    if name in args:
        i = args.index(name); v = args[i + 1]; del args[i:i + 2]; return v
    return default
VARIANT = opt("--variant", "strong")
WORKERS = int(opt("--workers", "16"))
NTASKS = int(opt("--tasks", "10"))
COMBINED = os.path.normpath(os.path.join(D, "..", "..", "..", "..", "agent-principles.md"))
base = open(os.path.join(D, "principle-base.md"), encoding="utf-8").read().replace("\r\n", "\n")
ids = [i for i in (args or sorted(os.listdir(C)))
       if all(os.path.exists(os.path.join(C, i, f)) for f in ("tasks.json", "rubric.md"))
       and (VARIANT in ("combined", "top", "half") or os.path.exists(os.path.join(C, i, f"{VARIANT}.txt")))]
work = tempfile.mkdtemp(prefix="clause-")

def clause_line(text, cid):
    m = re.search(r"^- \*\*`" + re.escape(cid) + r"`.*$", text, re.M)
    return m.group(0) if m else None

def principle(cid, cond):
    if cond == "orig":
        return base
    if cond == "combined":
        return open(COMBINED, encoding="utf-8").read()
    if cond in ("top", "half"):
        return open(os.path.join(D, f"principle-{cond}.md"), encoding="utf-8").read()
    new = open(os.path.join(C, cid, f"{cond}.txt"), encoding="utf-8").read().strip().replace("\n", " ")
    old = clause_line(base, cid)
    assert old and new.startswith(f"- **`{cid}`"), cid
    return base.replace(old, new)

def claude(prompt):
    p = subprocess.run(["claude", "-p", "--tools", "", "--setting-sources", "", "--no-session-persistence",
                        "--output-format", "json"], input=prompt.encode("utf-8"), capture_output=True, cwd=work, timeout=900)
    try:
        return json.loads(p.stdout.decode("utf-8")).get("result") or ""
    except json.JSONDecodeError:
        return ""

def run(job):
    cid, cond, t = job
    out = os.path.join(C, cid, "runs", f"{cond}__{t['name']}.txt")
    if os.path.exists(out) and os.path.getsize(out) > 0:
        return
    os.makedirs(os.path.dirname(out), exist_ok=True)
    prompt = ("<system-reminder>\nContents of ~/.claude/CLAUDE.md (user's private global instructions for all projects):\n\n"
              + principle(cid, cond) + "\n</system-reminder>\n\n" + t["prompt"])
    ans = claude(prompt)
    # 사용량 한도에 걸리면 claude -p 가 안내 문구를 결과로 돌려준다. 답으로 저장하지 않는다.
    if ans and "hit your session limit" not in ans:
        open(out, "w", encoding="utf-8").write(ans)

def score(job):
    cid, cond, t = job
    ans_p = os.path.join(C, cid, "runs", f"{cond}__{t['name']}.txt")
    out = os.path.join(C, cid, "scores", f"{cond}__{t['name']}.json")
    if os.path.exists(out) or not os.path.exists(ans_p):
        return
    os.makedirs(os.path.dirname(out), exist_ok=True)
    rubric = open(os.path.join(C, cid, "rubric.md"), encoding="utf-8").read()
    prompt = ("어떤 도구도 쓰지 말고 이 메시지만으로 답하라. 너는 채점자다. 아래 조항과 채점 기준만으로, 주어진 답이 이 조항을 어긴 횟수를 세라. "
              "채점 기준이 정한 판정 단위를 따르고, 확신이 없으면 세지 마라. "
              '결과는 JSON {"violations": 정수, "evidence": ["답의 해당 문장 일부", ...]} 하나로만 돌려줘라.\n\n'
              "조항:\n" + clause_line(base, cid) + "\n\n채점 기준:\n" + rubric
              + "\n\n과제 이름: " + t["name"] + "\n\n과제(사용자 요청과 맥락):\n" + t["prompt"] + "\n\n채점할 답:\n" + open(ans_p, encoding="utf-8").read())
    r = claude(prompt)
    m = re.search(r"\{.*\}", r, re.S)
    try:
        v = json.loads(m.group(0))
        int(v["violations"])
    except Exception:
        return
    json.dump(v, open(out, "w", encoding="utf-8"), ensure_ascii=False, indent=1)

jobs = []
for cid in ids:
    tasks = json.load(open(os.path.join(C, cid, "tasks.json"), encoding="utf-8"))
    for cond in ("orig", VARIANT):
        for t in tasks[:NTASKS]:
            jobs.append((cid, cond, t))
with ThreadPoolExecutor(max_workers=WORKERS) as ex:
    list(ex.map(run, jobs))
with ThreadPoolExecutor(max_workers=WORKERS) as ex:
    list(ex.map(score, jobs))

rows = []
for cid in ids:
    tot = {}; n = {}
    for cond in ("orig", VARIANT):
        sd = os.path.join(C, cid, "scores")
        names = {t["name"] for t in json.load(open(os.path.join(C, cid, "tasks.json"), encoding="utf-8"))[:NTASKS]}
        fs = [f for f in os.listdir(sd) if f.startswith(cond + "__") and f[len(cond) + 2:-5] in names] if os.path.isdir(sd) else []
        tot[cond] = sum(json.load(open(os.path.join(sd, f), encoding="utf-8"))["violations"] for f in fs)
        n[cond] = len(fs)
    rows.append((cid, tot["orig"], n["orig"], tot[VARIANT], n[VARIANT]))
with open(os.path.join(D, f"results-{VARIANT}.tsv"), "w", encoding="utf-8") as f:
    f.write(f"clause\torig\torig_n\t{VARIANT}\t{VARIANT}_n\n")
    for r in rows:
        f.write("\t".join(map(str, r)) + "\n")
for r in rows:
    print(f"{r[0]:18s} orig={r[1]:3d}({r[2]}) {VARIANT}={r[3]:3d}({r[4]})")
