"""선행연구 검증자 시험의 실행기다. 단계와 설정마다 claude -p 를 실행하고 결과를 runs.jsonl 에 한 줄씩 남긴다.

오류 줄도 남기고, 같은 key 는 오류 없는 줄이 있으면 건너뛴다. 같은 key 가 두 번 오류로 끝나면 멈춘다.
같은 결과 파일에 여러 셸이 쓰지 않도록 잠금 파일을 둔다.
"""
import argparse
import concurrent.futures
import functools
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
# xhigh 는 Haiku high 가 기준선에 못 미칠 때 Sonnet 보다 먼저 시험한다(2026-10-21 사용자 결정).
EFFORTS = ("low", "medium", "high", "xhigh")
CITE_TOOLS = "WebFetch,Read"
LOCAL_TOOLS = "Read"
MODES = {"baseline-cite": "cite", "baseline-map": "map", "extract": "extract", "judge": "judge", "map": "map",
         "extract-def": "extract", "judge-def": "judge", "refetch-def": "refetch", "rejudge-def": "judge",
         "escalate-def": "judge", "map-def": "map"}
# -def 단계는 에이전트 정의 본문을 system 프롬프트로 넣고, 사용자 메시지는 워크플로의 prompt() 와 같게 만든다.
DEF_AGENTS = {"extract-def": "prior-art-verifier.md", "judge-def": "prior-art-judge.md",
              "refetch-def": "prior-art-verifier.md", "rejudge-def": "prior-art-judge.md",
              "escalate-def": "prior-art-judge-escalation.md", "map-def": "prior-art-mapcheck.md"}
JUDGE_CELLS = ("numbers_conditions", "direction", "scope")
MATCHES = ("일치", "불일치", "판정 불가", "정보 부족")
# -def 단계가 앞 단계 출력을 고를 때 쓰는 설정이다. 확정 구성의 추출·판정 설정과 같다.
UPSTREAM = "claude-haiku-5-5/high"


def build_cmd(stage, model, effort, prompt, system=None):
    tools = CITE_TOOLS if stage in ("baseline-cite", "extract", "extract-def", "refetch-def") else LOCAL_TOOLS
    exe = shlex.split(os.environ.get("DC_EVAL_CLAUDE", "claude"), posix=False)
    cmd = exe + ["-p", prompt, "--output-format", "json", "--model", model, "--effort", effort,
                 "--tools", tools, "--allowedTools", tools, "--setting-sources", "", "--strict-mcp-config",
                 "--disable-slash-commands", "--no-session-persistence"]
    return cmd + (["--system-prompt", system] if system else [])


@functools.lru_cache(maxsize=None)
def def_system(stage):
    """에이전트 정의 파일에서 frontmatter 를 뗀 본문이다."""
    with open(os.path.join(ROOT, "agents", DEF_AGENTS[stage]), encoding="utf-8") as f:
        text = f.read()
    if text.startswith("---"):
        text = text[text.index("\n---", 3) + 4:]
    return text.lstrip("\n")


def def_prompt(stage, payload):
    """워크플로 prompt() 와 같은 사용자 메시지다. JSON.stringify(input, null, 2) 와 같은 들여쓰기를 쓴다."""
    body = json.dumps(payload, ensure_ascii=False, indent=2)
    return f"MODE: {MODES[stage]}\nPRINCIPLES: {PRINCIPLES}\n```json\n{body}\n```"


def _by_ref(refs, output, ok=lambda j: True):
    """워크플로 judgmentsByRef 와 같다. 판정이 배열이 아니거나 한 ref 라도 없거나 ok 를 못 넘으면 None."""
    js = output.get("judgments") if isinstance(output, dict) else None
    if not isinstance(js, list):
        return None
    found = {}
    for ref in refs:
        j = next((x for x in js if isinstance(x, dict) and x.get("ref") == ref), None)
        if j is None or not ok(j):
            return None
        found[ref] = j
    return found


def _passes_extract(e):
    return isinstance(e, dict) and e.get("access") == "성공" and e.get("exists") == "일치" and str(e.get("quote") or "").strip() != ""


def _judgment_of(output, ref):
    """워크플로 judgmentOf 와 같다. 출력이 없거나 그 ref 의 판정이 없으면 None."""
    js = output.get("judgments") if isinstance(output, dict) else None
    if not isinstance(js, list):
        return None
    return next((x for x in js if isinstance(x, dict) and x.get("ref") == ref), None)


def _cells_ok(j):
    return all(j.get(k) in MATCHES for k in JUDGE_CELLS)


def _to_judge_claim(c, e):
    """워크플로 toJudgeClaim 과 같다. 추출(또는 보충) 판정의 reason 은 넣지 않는다."""
    return {"ref": c["ref"], "text": c["text"], "quote": e.get("quote"),
            "context": "" if e.get("context") is None else e["context"],
            "source_note": "" if e.get("exists_note") is None else e["exists_note"]}


def _judge_claims(claims, ex_out):
    """워크플로 judgeClaims 와 같다."""
    ex = _by_ref([c["ref"] for c in claims], ex_out)
    if ex is None:
        return []
    return [_to_judge_claim(c, ex[c["ref"]]) for c in claims if _passes_extract(ex[c["ref"]])]


def next_step(j):
    """워크플로 nextStep 과 같다."""
    cells = [j.get(k) for k in JUDGE_CELLS]
    if "불일치" in cells:
        return "unsupported"
    if "정보 부족" in cells:
        return "refetch"
    if "판정 불가" in cells:
        return "escalate"
    return "supported"


def route_claim(j, rf, rj):
    """워크플로 routeClaim 과 같다. (차례, 그 차례를 정한 단계) 를 낸다."""
    first = next_step(j)
    if first != "refetch":
        return first, "judge"
    if rf is None or not _passes_extract(rf):
        return "verify_failed", "refetch"
    if rj is None or not _cells_ok(rj):
        return "verify_failed", "rejudge"
    second = next_step(rj)
    return ("verify_failed" if second == "refetch" else second), "rejudge"


def _refetch_claims(claims, ju_out):
    """워크플로 refetchClaims 와 같다."""
    ju = _by_ref([c["ref"] for c in claims], ju_out, _cells_ok)
    if ju is None:
        return []
    return [{"ref": c["ref"], "text": c["text"],
             "missing": {} if ju[c["ref"]].get("missing") is None else ju[c["ref"]]["missing"]}
            for c in claims if next_step(ju[c["ref"]]) == "refetch"]


def _rejudge_claims(claims, rf_out):
    """워크플로 rejudgeClaims 와 같다."""
    return [_to_judge_claim(c, _judgment_of(rf_out, c["ref"])) for c in claims
            if _passes_extract(_judgment_of(rf_out, c["ref"]))]


def _escalate_claims(claims, ju_out, rf_out, rj_input, rj_out):
    """워크플로 escalateClaims 와 같다. 재판정을 거친 주장은 재판정 입력을 쓴다."""
    ju = _by_ref([c["ref"] for c in claims], ju_out, _cells_ok)
    if ju is None:
        return []
    out = []
    for c in claims:
        step, frm = route_claim(ju[c["ref"]], _judgment_of(rf_out, c["ref"]), _judgment_of(rj_out, c["ref"]))
        if step == "escalate":
            out.append(next(x for x in rj_input if x["ref"] == c["ref"]) if frm == "rejudge" else c)
    return out


def _url_claims(cases):
    by_url = {}
    for x in cases["items"]:
        by_url.setdefault(x["url"], []).append({"ref": x["id"], "text": x["claim"]["text"]})
    return by_url


def def_payload(cases, stage, runs, repeat, upstream, unit):
    """-def 단계의 unit 하나의 입력이다. 앞 단계 출력은 같은 차례의 upstream 설정 출력을 def_output 으로 고르고,
    워크플로의 단계 차례(추출, 판정, 보충, 재판정, 상향 판정)로 입력을 만든다. 보낼 주장이 없으면 None."""
    if stage == "map-def":
        m = next((m for m in cases["map_cases"] if m["id"] == unit), None)
        return None if m is None else {"evidence_map": m["input"]["evidence_map"], "passed": m["input"]["passed"]}
    claims = _url_claims(cases).get(unit)
    if not claims:
        return None
    if stage == "extract-def":
        return {"url": unit, "claims": claims}

    def up(s):
        return def_output(cases, runs, s, upstream, repeat, unit, upstream)
    out = _judge_claims(claims, up("extract-def"))
    if stage != "judge-def":
        jc, ju = out, up("judge-def")
        out = rc = _refetch_claims(jc, ju)
        if stage != "refetch-def":
            rf = up("refetch-def") if rc else None
            out = rj_in = _rejudge_claims(rc, rf)
            if stage != "rejudge-def":
                rj = up("rejudge-def") if rj_in else None
                out = _escalate_claims(jc, ju, rf, rj_in, rj)
    return {"url": unit, "claims": out} if out else None


def def_key(cases, runs, stage, config, repeat, unit, upstream=UPSTREAM):
    """그 단계·설정·차례·unit 을 지금 실행하면 run.py 가 줄에 적을 key 다. 보낼 입력이 없으면 None."""
    payload = def_payload(cases, stage, runs, repeat, upstream, unit)
    if payload is None:
        return None
    model, effort = config.split("/")
    return make_key(stage, model, effort, "", repeat, unit, def_prompt(stage, payload) + def_system(stage))


def def_output(cases, runs, stage, config, repeat, unit, upstream=UPSTREAM):
    """def_key 와 key 가 같은 줄 중 오류 없는 마지막 줄의 출력이다. 정의나 입력이 다른 옛 줄은 고르지 않는다."""
    key = def_key(cases, runs, stage, config, repeat, unit, upstream)
    out = None
    for r in runs:
        if key is not None and r.get("key") == key and not r.get("error") and r.get("output") is not None:
            out = r["output"]
    return out


def def_units(cases, stage, runs, repeat, upstream, hard_only):
    """-def 단계의 (unit, payload) 목록이다. hard_only 이면 항목이 모두 어려운 항목인 URL 만 남긴다."""
    if stage == "map-def":
        names = [m["id"] for m in cases["map_cases"]]
    else:
        hard = {}
        for x in cases["items"]:
            hard[x["url"]] = hard.get(x["url"], True) and "hard_kind" in x
        names = [u for u in _url_claims(cases) if not hard_only or hard[u]]
    out = []
    for u in names:
        p = def_payload(cases, stage, runs, repeat, upstream, u)
        if p is not None:
            out.append((u, p))
    return out


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


def judge_source(item, extract):
    """판정 단계에 넘길 추출 판정을 고른다. 자기 구절이 없는 오류 항목(-fN)은 같은 출처의 짝 참 항목(-tN) 구절을 쓴다.
    추출 단계가 오류 주장의 구절을 찾지 못하면 판정 에이전트의 오류 탐지를 잴 수 없어서다(2026-10-21 판정)."""
    own = extract.get((item["url"], item["id"])) or {}
    if own.get("quote") or item["truth"] or "-f" not in item["id"]:
        return own
    return extract.get((item["url"], item["id"].replace("-f", "-t"))) or own


def units(cases, stage, category, extract):
    """(unit, payload) 목록을 만든다. cite 계열은 URL 마다, map 계열은 지도 대조 자료마다 하나다."""
    if stage in ("baseline-map", "map"):
        return [(m["id"], m["input"]) for m in cases["map_cases"]]
    by_url = {}
    for x in cases["items"]:
        if stage == "judge":
            if x["category"] != category:
                continue
            e = judge_source(x, extract)
            if not e.get("quote"):
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
        p = subprocess.run(build_cmd(job["stage"], job["model"], job["effort"], job["prompt"], job.get("system")),
                           cwd=cwd, env=env,
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
    ap.add_argument("--effort", required=True, choices=EFFORTS)
    ap.add_argument("--category", default="")
    ap.add_argument("--extract-from", default="")
    ap.add_argument("--repeat", type=int, default=1)
    ap.add_argument("--cases", default=os.path.join(HERE, "cases.json"))
    ap.add_argument("--out", default=os.path.join(HERE, "results", "runs.jsonl"))
    ap.add_argument("--upstream", default=UPSTREAM, help="-def 단계가 앞 단계 출력을 고를 설정(모델/수준)")
    ap.add_argument("--hard-only", action="store_true", help="-def 단계에서 어려운 항목만 있는 URL 만 실행한다")
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
    is_def = a.stage in DEF_AGENTS
    system = def_system(a.stage) if is_def else None
    for rep in range(1, a.repeat + 1):
        if is_def:
            us = def_units(cases, a.stage, past, rep, a.upstream, a.hard_only)
        else:
            us = units(cases, a.stage, a.category, extract)
        for unit, payload in us:
            prompt = def_prompt(a.stage, payload) if is_def else build_prompt(a.stage, a.category, payload)
            # -def 단계는 정의 본문이 바뀌면 다른 실행이므로 key 에 system 프롬프트도 넣는다. 분류 칸은 def_key 처럼 비운다.
            key = make_key(a.stage, a.model, a.effort, "" if is_def else a.category, rep, unit, prompt + (system or ""))
            if key in done:
                continue
            jobs.append({"key": key, "stage": a.stage, "model": a.model, "effort": a.effort, "category": a.category,
                         "repeat": rep, "unit": unit, "prompt": prompt, "system": system,
                         "attempt": attempts.get(key, 0) + 1})
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
