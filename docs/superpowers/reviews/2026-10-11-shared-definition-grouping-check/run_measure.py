# run_measure.py: 조건(current·new) × 요청 여섯 × 회차를 도구 없는 claude -p 로 저장소 밖 임시 폴더에서 실행하고 응답 원문을 runs/ 에 남긴다.
# 사용: python -I -X utf8 run_measure.py [회차 목록, 기본 1~5] [--only 조건__요청 ...]
import json, os, subprocess, sys, tempfile
from concurrent.futures import ThreadPoolExecutor
D = os.path.dirname(os.path.abspath(__file__))
RUNS = os.path.join(D, "runs"); os.makedirs(RUNS, exist_ok=True)
lists = json.load(open(os.path.join(D, "lists.json"), encoding="utf-8"))
rules = {c: open(os.path.join(D, f"rule-{c}.md"), encoding="utf-8").read() for c in ("current", "new")}
HEAD = ("어떤 도구도 쓰지 말고 이 메시지만으로 답하라. 너는 개발을 서브 세션에 나눠 맡기려는 현재 세션이다. "
        "아래 「묶는 단위」 규칙만 따라 하위 프로젝트 목록을 워크스트림으로 묶어라. 규칙에 없는 기준은 쓰지 마라. "
        "규칙이 만들라는 표를 모두 만들고, 마지막에 분할을 적어라. partition 에는 목록의 id 를 그대로 한 번씩만 써라. "
        '결과는 JSON {"tables": "<표를 마크다운으로>", "partition": [["<id>", ...], ...]} 하나로만 돌려줘라.')
args = sys.argv[1:]
only = args[args.index("--only") + 1:] if "--only" in args else None
nums = [int(a) for a in (args[:args.index("--only")] if only is not None else args)] or [1, 2, 3, 4, 5]
jobs = [(c, r, n) for c in ("current", "new") for r in lists for n in nums if only is None or f"{c}__{r}" in only]
work = tempfile.mkdtemp(prefix="measure-")
def run(job):
    c, r, n = job
    prompt = HEAD + "\n\n규칙:\n" + rules[c] + "\n목록:\n" + json.dumps(lists[r], ensure_ascii=False)
    p = subprocess.run(["claude", "-p", "--tools", "", "--setting-sources", "", "--no-session-persistence",
                        "--output-format", "json"], input=prompt.encode("utf-8"), capture_output=True, cwd=work, timeout=900)
    try:
        d = json.loads(p.stdout.decode("utf-8"))
    except json.JSONDecodeError:
        d = {"result": p.stdout.decode("utf-8", "replace"), "num_turns": None, "is_error": True}
    open(os.path.join(RUNS, f"{c}__{r}__{n}.txt"), "w", encoding="utf-8").write(d.get("result") or "")
    return {"run": f"{c}__{r}__{n}", "num_turns": d.get("num_turns"), "is_error": d.get("is_error"),
            "models": list(d.get("modelUsage", {}).keys())}
with ThreadPoolExecutor(max_workers=10) as ex:
    metas = list(ex.map(run, jobs))
with open(os.path.join(D, "runs.log"), "a", encoding="utf-8") as f:
    for m in metas: f.write(json.dumps(m, ensure_ascii=False) + "\n")
bad = [m["run"] for m in metas if m["num_turns"] != 1 or m["is_error"]]
print(len(metas), "runs;", "num_turns!=1 or error:", bad or "none")
