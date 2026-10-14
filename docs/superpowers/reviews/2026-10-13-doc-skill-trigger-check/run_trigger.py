# run_trigger.py: 문서 전용 조항을 스킬(domain-writing)로 뺐을 때 모델이 문서를 쓰기 전에 그 스킬을 여는지 측정한다.
# 조건 line: 원칙에서 「남에게 전달하는 문서」 절을 지우고 "스킬을 열어라" 한 줄을 둔다. 조건 none: 그 절만 지운다.
# 두 조건 모두 스킬은 설치되어 있다. 첫 Write·Edit 전에 Skill 호출이 있었는지를 센다.
# 사용: python -I -X utf8 run_trigger.py [--model claude-haiku-5-5] [--reps N] [--workers N]
import json, os, re, subprocess, sys, tempfile
from concurrent.futures import ThreadPoolExecutor
D = os.path.dirname(os.path.abspath(__file__))
args = sys.argv[1:]
def opt(n, d):
    if n in args:
        i = args.index(n); v = args[i + 1]; del args[i:i + 2]; return v
    return d
MODEL = opt("--model", "claude-haiku-5-5"); REPS = int(opt("--reps", "2")); WORKERS = int(opt("--workers", "8"))
P = open(os.path.join(D, "..", "..", "..", "..", "agent-principles.md"), encoding="utf-8").read()
i = P.index("## 남에게 전달하는 문서"); j = P.index("## 문서를 쓰고 관리할 때")
docsec = P[i:j]
LINE = ("## 사람이 볼 문서\n\n사람이 볼 문서와 발표자료(README·설계 문서·보고서·회의록·인수인계·가이드·릴리스 노트 등)를 "
        "새로 쓰거나 고치기 전에 `disciplined-coder:domain-writing` 스킬을 열어라. 대화 답과 코드에는 적용하지 마라.\n\n")
PRIN = {"line": P[:i] + LINE + P[j:], "none": P[:i] + P[j:]}
plug = tempfile.mkdtemp(prefix="dcplug-")
os.makedirs(os.path.join(plug, ".claude-plugin")); os.makedirs(os.path.join(plug, "skills", "domain-writing"))
json.dump({"name": "disciplined-coder", "version": "0.0.0", "description": "test"}, open(os.path.join(plug, ".claude-plugin", "plugin.json"), "w"))
body = re.sub(r"^## 남에게 전달하는 문서\n", "", docsec)
open(os.path.join(plug, "skills", "domain-writing", "SKILL.md"), "w", encoding="utf-8").write(
    "---\nname: domain-writing\ndescription: 사람이 볼 문서와 발표자료(README·설계 문서·보고서·회의록·인수인계·가이드·릴리스 노트 등)를 새로 쓰거나 고치기 전에 연다. 제목 계층, 절 구성, 불릿 범위, 고칠 순서를 정한다. 대화 답과 코드에는 쓰지 않는다.\n---\n\n# 사람이 볼 문서\n" + body)
tasks = json.load(open(os.path.join(D, "tasks.json"), encoding="utf-8"))
OUT = os.path.join(D, "runs-" + MODEL); os.makedirs(OUT, exist_ok=True)

def run(job):
    cond, t, r = job
    out = os.path.join(OUT, f"{cond}__{t['name']}__{r}.json")
    if os.path.exists(out):
        return
    w = tempfile.mkdtemp(prefix="dcw-")
    for fn, c in t.get("files", {}).items():
        open(os.path.join(w, fn), "w", encoding="utf-8").write(c)
    prompt = ("<system-reminder>\nContents of ~/.claude/CLAUDE.md (user's private global instructions for all projects):\n\n"
              + PRIN[cond] + "\n</system-reminder>\n\n" + t["prompt"])
    p = subprocess.run(["claude", "-p", "--model", MODEL, "--setting-sources", "", "--no-session-persistence",
                        "--plugin-dir", plug, "--tools", "Skill,Read,Write,Edit", "--permission-mode", "acceptEdits",
                        "--output-format", "stream-json", "--verbose"],
                       input=prompt.encode("utf-8"), capture_output=True, cwd=w, timeout=900)
    seq = []
    for ln in p.stdout.decode("utf-8", "replace").splitlines():
        try:
            e = json.loads(ln)
        except json.JSONDecodeError:
            continue
        if e.get("type") == "assistant":
            for b in e["message"].get("content", []):
                if b.get("type") == "tool_use":
                    seq.append(b["name"] + (":" + str(b["input"].get("skill", "")) if b["name"] == "Skill" else ""))
        if e.get("type") == "result" and "limit" in str(e.get("result", "")) and not seq:
            return
    json.dump({"seq": seq}, open(out, "w", encoding="utf-8"), ensure_ascii=False)

jobs = [(c, t, r) for c in PRIN for t in tasks for r in range(REPS)]
with ThreadPoolExecutor(WORKERS) as ex:
    list(ex.map(run, jobs))
rows = []
for c in PRIN:
    for t in tasks:
        hit = pre = n = 0
        for r in range(REPS):
            f = os.path.join(OUT, f"{c}__{t['name']}__{r}.json")
            if not os.path.exists(f):
                continue
            seq = json.load(open(f, encoding="utf-8"))["seq"]; n += 1
            sk = [k for k, s in enumerate(seq) if "domain-writing" in s]
            wr = [k for k, s in enumerate(seq) if s in ("Write", "Edit")]
            hit += bool(sk); pre += bool(sk) and (not wr or sk[0] < wr[0])
        rows.append((c, t["name"], t["doc"], hit, pre, n))
with open(os.path.join(D, f"results-{MODEL}.tsv"), "w", encoding="utf-8") as f:
    f.write("cond\ttask\tdoc\tskill\tskill_before_write\tn\n")
    for r in rows:
        f.write("\t".join(map(str, r)) + "\n")
for r in rows:
    print(*r, sep="\t")
