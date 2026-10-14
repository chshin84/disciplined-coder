# run_sep.py: 문서 조항을 「사람이 볼 문서」 절로 분리한 원칙 문안을 하이쿠(claude-haiku-5-5)로 클린룸 시험한다.
# 피험 모델과 채점기 모두 하이쿠다. 출력 조항은 원래 과제로, 문서 조항은 문서 작성 과제로 채점한다.
# 조건: ko-orig·en-orig(원래 문구), ko-strong·en-strong(채택한 강화 문구 전체, 통합),
#       ko-ind·en-ind(원래 문안에서 그 조항 한 줄만 강화, 개별), ko-strong-nosep(통합이되 문서 형식 조항을 분리하지 않음).
# 사용: python -I -X utf8 run_sep.py [--workers N]
import json, os, re, subprocess, sys, tempfile
from concurrent.futures import ThreadPoolExecutor
D = os.path.dirname(os.path.abspath(__file__))
OLD = os.path.join(D, "..", "2026-10-12-clause-strengthening-check", "clauses")
MODEL = "claude-haiku-5-5"
WORKERS = int(sys.argv[sys.argv.index("--workers") + 1]) if "--workers" in sys.argv else 24
OUTPUT = ["VOCAB-PREF", "SPECIFIC-NAME", "WRITTEN-ONLY", "NO-MIRROR", "NO-MID-MOD", "NO-STACK-MOD", "KEEP-CONNECT", "ANTI-LIMIT",
          "COMMA-CUT", "SUBJECT-OBJECT", "FULL-SENTENCE", "BOTTOM-LINE", "STATUS-FIRST", "ONE-IDEA", "TERM-EXPLAIN", "TERM-ONE",
          "NO-ANALOGY", "COUNT-EARNS"]
DOC = ["TITLE-LAYERS", "TITLE-CLAIM", "TITLE-PROOF", "LABEL-NOUN", "SECTION-HEAD", "BULLET-SCOPE", "ONE-ENDING", "NO-SQUEEZE",
       "EDIT-PRIORITY"]
# 이 두 조항의 과제는 대화 답이라, 같은 내용을 사람이 읽을 마크다운 문서로 쓰게 바꾼다.
TO_DOC = {"SECTION-HEAD", "BULLET-SCOPE"}
DOC_NOTE = "\n\n(이 내용은 팀원이 나중에 읽을 마크다운 문서 파일로 저장된다. 대화 답 대신 그 문서의 본문만 써라.)"
F = {k: open(os.path.join(D, k + ".md"), encoding="utf-8").read() for k in ("ko-orig", "ko-strong", "ko-strong-nosep", "en-orig", "en-strong")}
EN_LINES = json.load(open(os.path.join(D, "en-strong-lines.json"), encoding="utf-8"))
work = tempfile.mkdtemp(prefix="sep-")

def line(text, cid):
    m = re.search(r"^- \*\*`" + re.escape(cid) + r"`.*$", text, re.M)
    return m.group(0)

def principle(cid, cond):
    if cond == "ko-ind":
        return F["ko-orig"].replace(line(F["ko-orig"], cid), line(F["ko-strong"], cid))
    if cond == "en-ind":
        return F["en-orig"].replace(line(F["en-orig"], cid), EN_LINES[cid])
    return F[cond]

def claude(prompt):
    p = subprocess.run(["claude", "-p", "--model", MODEL, "--tools", "", "--setting-sources", "", "--no-session-persistence",
                        "--output-format", "json"], input=prompt.encode("utf-8"), capture_output=True, cwd=work, timeout=900)
    try:
        return json.loads(p.stdout.decode("utf-8")).get("result") or ""
    except json.JSONDecodeError:
        return ""

def tasks(cid):
    ts = json.load(open(os.path.join(OLD, cid, "tasks.json"), encoding="utf-8"))
    return [dict(t, prompt=t["prompt"] + DOC_NOTE) if cid in TO_DOC else t for t in ts]

def run(job):
    cid, cond, t = job
    out = os.path.join(D, "runs", cid, f"{cond}__{t['name']}.txt")
    if os.path.exists(out) and os.path.getsize(out) > 0:
        return
    os.makedirs(os.path.dirname(out), exist_ok=True)
    ans = claude("<system-reminder>\nContents of ~/.claude/CLAUDE.md (user's private global instructions for all projects):\n\n"
                 + principle(cid, cond) + "\n</system-reminder>\n\n" + t["prompt"])
    if ans and "hit your session limit" not in ans:
        open(out, "w", encoding="utf-8").write(ans)

def score(job):
    cid, cond, t = job
    ans_p = os.path.join(D, "runs", cid, f"{cond}__{t['name']}.txt")
    out = os.path.join(D, "scores", cid, f"{cond}__{t['name']}.json")
    if os.path.exists(out) or not os.path.exists(ans_p):
        return
    os.makedirs(os.path.dirname(out), exist_ok=True)
    rubric = open(os.path.join(OLD, cid, "rubric.md"), encoding="utf-8").read()
    r = claude("어떤 도구도 쓰지 말고 이 메시지만으로 답하라. 너는 채점자다. 아래 조항과 채점 기준만으로, 주어진 답이 이 조항을 어긴 횟수를 세라. "
               "채점 기준이 정한 판정 단위를 따르고, 확신이 없으면 세지 마라. "
               '결과는 JSON {"violations": 정수, "evidence": ["답의 해당 문장 일부", ...]} 하나로만 돌려줘라.\n\n'
               "조항:\n" + line(F["ko-orig"], cid) + "\n\n채점 기준:\n" + rubric + "\n\n과제 이름: " + t["name"]
               + "\n\n과제(사용자 요청과 맥락):\n" + t["prompt"] + "\n\n채점할 답:\n" + open(ans_p, encoding="utf-8").read())
    m = re.search(r"\{.*\}", r, re.S)
    try:
        v = json.loads(m.group(0)); int(v["violations"])
    except Exception:
        return
    json.dump(v, open(out, "w", encoding="utf-8"), ensure_ascii=False, indent=1)

CONDS = ["ko-orig", "ko-ind", "ko-strong", "ko-strong-nosep", "en-orig", "en-ind", "en-strong"]
def conds(cid):
    return [c for c in CONDS if not c.endswith("-ind") or cid in EN_LINES]
jobs = [(cid, c, t) for cid in OUTPUT + DOC for c in conds(cid) for t in tasks(cid)]
for f in (run, score):
    with ThreadPoolExecutor(WORKERS) as ex:
        list(ex.map(f, jobs))

def total(cid, c):
    sd = os.path.join(D, "scores", cid)
    fs = [x for x in os.listdir(sd) if x.startswith(c + "__")] if os.path.isdir(sd) else []
    return sum(json.load(open(os.path.join(sd, x), encoding="utf-8"))["violations"] for x in fs), len(fs)
with open(os.path.join(D, "results.tsv"), "w", encoding="utf-8") as f:
    f.write("group\tclause\t" + "\t".join(CONDS) + "\n")
    for g, ids in (("output", OUTPUT), ("doc", DOC)):
        for cid in ids:
            f.write(f"{g}\t{cid}\t" + "\t".join("%d/%d" % total(cid, c) if c in conds(cid) else "-" for c in CONDS) + "\n")
print(open(os.path.join(D, "results.tsv"), encoding="utf-8").read())
