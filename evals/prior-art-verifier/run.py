"""선행연구 검증자 시험의 실행기다. 단계와 설정마다 claude -p 를 실행하고 결과를 runs.jsonl 에 한 줄씩 남긴다.

오류 줄도 남기고, 같은 key 는 오류 없는 줄이 있으면 건너뛴다. 같은 key 가 두 번 오류로 끝나면 멈춘다.
같은 결과 파일에 여러 셸이 쓰지 않도록 잠금 파일을 둔다.
"""
import argparse
import concurrent.futures
import hashlib
import json
import os
import shlex
import subprocess
import sys
import tempfile

HERE = os.path.dirname(os.path.abspath(__file__))
ROOT = os.path.dirname(os.path.dirname(HERE))
PRINCIPLES = os.path.join(ROOT, "agent-principles.md")
JOBS = 4
TIMEOUT = 900
MAX_ATTEMPTS = 2
CITE_TOOLS = "WebFetch,Read"
LOCAL_TOOLS = "Read"
MODES = {"baseline-cite": "cite", "baseline-map": "map", "extract": "extract", "judge": "judge", "map": "map"}


def build_cmd(stage, model, effort, prompt):
    tools = CITE_TOOLS if stage in ("baseline-cite", "extract") else LOCAL_TOOLS
    exe = shlex.split(os.environ.get("DC_EVAL_CLAUDE", "claude"), posix=False)
    return exe + ["-p", prompt, "--output-format", "json", "--model", model, "--effort", effort,
                  "--tools", tools, "--allowedTools", tools, "--setting-sources", "", "--strict-mcp-config",
                  "--disable-slash-commands", "--no-session-persistence"]


def parse_output(text):
    """답에서 첫 JSON 객체를 꺼낸다. 앞뒤 설명 글과 코드 펜스는 무시한다. 읽지 못하면 None."""
    dec = json.JSONDecoder()
    i = text.find("{")
    while i != -1:
        try:
            obj, _ = dec.raw_decode(text, i)
            if isinstance(obj, dict):
                return obj
        except ValueError:
            pass
        i = text.find("{", i + 1)
    return None


def make_key(stage, model, effort, category, repeat, unit, prompt):
    sha = hashlib.sha256(prompt.encode("utf-8")).hexdigest()
    raw = json.dumps([stage, model, effort, category, repeat, unit, sha], ensure_ascii=False)
    return hashlib.sha256(raw.encode("utf-8")).hexdigest()[:16]


def build_prompt(stage, category, payload):
    name = f"judge-{category}.md" if stage == "judge" else f"{stage}.md"
    with open(os.path.join(HERE, "prompts", name), encoding="utf-8") as f:
        template = f.read()
    head = f"MODE: {MODES[stage]}\nPRINCIPLES: {PRINCIPLES}\n```json\n{json.dumps(payload, ensure_ascii=False, indent=2)}\n```\n"
    return head + "\n" + template


def read_runs(path):
    out = []
    if os.path.exists(path):
        with open(path, encoding="utf-8") as f:
            for line in f:
                line = line.strip()
                if line:
                    out.append(json.loads(line))
    return out


def load_extract(path):
    """고정한 추출 출력에서 (unit, ref) -> 판정을 만든다."""
    m = {}
    for r in read_runs(path):
        if r.get("stage") != "extract" or r.get("error") or not r.get("output"):
            continue
        for j in r["output"].get("judgments", []):
            m[(r["unit"], j.get("ref"))] = j
    return m


def units(cases, stage, category, extract):
    """(unit, payload) 목록을 만든다. cite 계열은 URL 마다, map 계열은 지도 대조 자료마다 하나다."""
    if stage in ("baseline-map", "map"):
        return [(m["id"], m["input"]) for m in cases["map_cases"]]
    by_url = {}
    for x in cases["items"]:
        if stage == "judge":
            if x["category"] != category:
                continue
            e = extract.get((x["url"], x["id"]))
            if not e or not e.get("quote"):
                continue
            by_url.setdefault(x["url"], []).append(
                {"ref": x["id"], "text": x["claim"]["text"], "quote": e["quote"], "context": e.get("context", "")})
        else:
            by_url.setdefault(x["url"], []).append({"ref": x["id"], "text": x["claim"]["text"]})
    if stage == "judge":
        return [(u, {"claims": c}) for u, c in by_url.items()]
    return [(u, {"url": u, "claims": c}) for u, c in by_url.items()]


def _win(path):
    """Git Bash 형식 경로(/d/x)를 윈도우 형식(D:/x)으로 바꾼다."""
    if os.name == "nt" and len(path) > 2 and path[0] == "/" and path[2] == "/":
        return path[1].upper() + ":" + path[2:]
    return path


def eval_cwd():
    """scripts/_eval_env.sh 의 eval_tmpdir 과 같은 규칙으로 실행 폴더를 만든다.
    파이썬에서 부른 bash 가 WSL 일 수 있어 셸 함수를 부르지 않고 같은 규칙을 여기서 따른다."""
    root = _win(os.environ.get("EVAL_TMP", "/d/dc-eval-tmp"))
    os.makedirs(root, exist_ok=True)
    path = tempfile.mkdtemp(prefix="run-", dir=root)
    d = os.path.dirname(os.path.abspath(path))
    while True:
        hit = os.path.join(d, "CLAUDE.md")
        if os.path.exists(hit):
            os.rmdir(path)
            sys.exit(f"평가 폴더 {root} 의 상위 경로에 {hit} 가 있어 평가 세션에 실린다. EVAL_TMP 를 다른 곳으로 지정하라.")
        parent = os.path.dirname(d)
        if parent == d:
            return path
        d = parent


def run_one(job, cwd):
    env = {k: v for k, v in os.environ.items() if k not in ("CLAUDE_CODE_EFFORT_LEVEL", "CLAUDE_CODE_SUBAGENT_MODEL")}
    rec = {k: job[k] for k in ("key", "stage", "model", "effort", "category", "repeat", "unit", "attempt")}
    rec.update({"output": None, "cost_usd": None, "usage": None, "models_used": "", "error": ""})
    try:
        p = subprocess.run(build_cmd(job["stage"], job["model"], job["effort"], job["prompt"]), cwd=cwd, env=env,
                           capture_output=True, text=True, encoding="utf-8", timeout=TIMEOUT)
    except subprocess.TimeoutExpired:
        rec["error"] = f"시간 초과({TIMEOUT}초)"
        return rec
    try:
        j = json.loads(p.stdout)
    except ValueError:
        rec["error"] = ((p.stdout or "") + (p.stderr or ""))[-500:] or f"종료 코드 {p.returncode}"
        return rec
    rec["cost_usd"] = j.get("total_cost_usd")
    rec["usage"] = j.get("usage")
    rec["models_used"] = ",".join(sorted((j.get("modelUsage") or {}).keys()))
    if j.get("is_error") or not j.get("result"):
        rec["error"] = str(j.get("result") or j.get("subtype") or "빈 응답")[:500]
        return rec
    if not any(m.startswith(job["model"]) for m in rec["models_used"].split(",") if m):
        rec["error"] = f"모델 불일치: 요청 {job['model']}, 기록 {rec['models_used']}"
        return rec
    rec["output"] = parse_output(j["result"])
    if rec["output"] is None:
        rec["error"] = "출력 JSON 을 읽지 못했다: " + j["result"][:200]
    return rec


def main(argv=None):
    ap = argparse.ArgumentParser()
    ap.add_argument("--stage", required=True, choices=sorted(MODES))
    ap.add_argument("--model", required=True)
    ap.add_argument("--effort", required=True, choices=["low", "medium", "high"])
    ap.add_argument("--category", default="")
    ap.add_argument("--extract-from", default="")
    ap.add_argument("--repeat", type=int, default=1)
    ap.add_argument("--cases", default=os.path.join(HERE, "cases.json"))
    ap.add_argument("--out", default=os.path.join(HERE, "results", "runs.jsonl"))
    a = ap.parse_args(argv)
    if a.stage == "judge" and not (a.category and a.extract_from):
        sys.exit("judge 단계에는 --category 와 --extract-from 이 필요하다")
    os.makedirs(os.path.dirname(os.path.abspath(a.out)), exist_ok=True)
    lock = a.out + ".lock"
    try:
        fd = os.open(lock, os.O_CREAT | os.O_EXCL | os.O_WRONLY)
    except FileExistsError:
        sys.exit(f"다른 실행이 {a.out} 에 쓰고 있다({lock}). 끝난 뒤 다시 실행하라.")
    os.close(fd)
    try:
        return _run(a)
    finally:
        os.remove(lock)


def _run(a):
    with open(a.cases, encoding="utf-8") as f:
        cases = json.load(f)
    extract = load_extract(a.extract_from) if a.stage == "judge" else {}
    past = read_runs(a.out)
    done = {r["key"] for r in past if not r.get("error")}
    attempts = {}
    for r in past:
        if r.get("error"):
            attempts[r["key"]] = max(attempts.get(r["key"], 0), r.get("attempt", 1))
    jobs = []
    for rep in range(1, a.repeat + 1):
        for unit, payload in units(cases, a.stage, a.category, extract):
            prompt = build_prompt(a.stage, a.category, payload)
            key = make_key(a.stage, a.model, a.effort, a.category, rep, unit, prompt)
            if key in done:
                continue
            jobs.append({"key": key, "stage": a.stage, "model": a.model, "effort": a.effort, "category": a.category,
                         "repeat": rep, "unit": unit, "prompt": prompt, "attempt": attempts.get(key, 0) + 1})
    if not jobs:
        print("실행할 것이 없다(모두 결과가 있다).")
        return 0
    cwd = eval_cwd()
    capped, errors = [], 0
    with concurrent.futures.ThreadPoolExecutor(JOBS) as ex, open(a.out, "a", encoding="utf-8") as out:
        futs = [ex.submit(run_one, j, cwd) for j in jobs]
        for fu in concurrent.futures.as_completed(futs):
            rec = fu.result()
            out.write(json.dumps(rec, ensure_ascii=False) + "\n")
            out.flush()
            if rec["error"]:
                errors += 1
                if rec["attempt"] >= MAX_ATTEMPTS:
                    capped.append(rec)
    print(f"실행 {len(jobs)}건, 오류 {errors}건")
    if capped:
        for r in capped:
            print(f"멈춤: {r['unit']} 가 같은 설정에서 {r['attempt']}번 오류로 끝났다: {r['error'][:200]}")
        return 4
    if errors:
        print("오류 줄은 한 번 더 실행하면 다시 시도한다.")
    return 0


if __name__ == "__main__":
    sys.stdout.reconfigure(encoding="utf-8")
    sys.exit(main())
