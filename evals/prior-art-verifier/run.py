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
         "extract-def": "extract", "judge-def": "judge", "refetch-def": "refetch", "rejudge-def": "judge", "map-def": "map"}
# -def 단계는 에이전트 정의 본문을 system 프롬프트로 넣고, 사용자 메시지는 워크플로의 prompt() 와 같게 만든다.
DEF_AGENTS = {"extract-def": "citation-verifier.md", "judge-def": "citation-judge.md",
              "refetch-def": "citation-verifier.md", "rejudge-def": "citation-judge.md", "map-def": "map-check.md"}
JUDGE_CELLS = ("numbers_conditions", "direction", "scope")
MATCHES = ("일치", "불일치", "판정 불가", "정보 부족")
# -def 단계가 앞 단계 출력을 고를 때 쓰는 단계마다의 설정이다. 확정 구성(spec 「Opus 일괄 판정」)과 같다.
UPSTREAM = {"extract-def": "claude-haiku-5-5/high", "judge-def": "claude-opus-5-5/medium",
            "refetch-def": "claude-haiku-5-5/high", "rejudge-def": "claude-opus-5-5/medium"}
# 판정·재판정은 묶음마다 한 줄이다(unit batch:<n>). 묶음 크기는 워크플로 BATCH_SIZE 와 같다.
BATCH_STAGES = ("judge-def", "rejudge-def")
BATCH_SIZE = 20


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
    """워크플로 nextStep 과 같다. 판정 불가는 기각이다."""
    cells = [j.get(k) for k in JUDGE_CELLS]
    if "불일치" in cells:
        return "unsupported"
    if "정보 부족" in cells:
        return "refetch"
    if "판정 불가" in cells:
        return "unsupported"
    return "supported"


def route_claim(j, rf, rj):
    """워크플로 routeClaim 과 같다. (차례, 그 차례를 정한 판정) 을 낸다. 검증 실패면 판정은 None 이다."""
    first = next_step(j)
    if first != "refetch":
        return first, j
    if rf is None or not _passes_extract(rf):
        return "verify_failed", None
    if rj is None or not _cells_ok(rj):
        return "verify_failed", None
    second = next_step(rj)
    return ("verify_failed" if second == "refetch" else second), rj


def _judged_refs(refs, output):
    """워크플로 judgedRefs 와 같다. 판정이 빠진 ref 는 결과에 없고, 있는 판정 중 하나라도 칸이 빠지면 None."""
    js = output.get("judgments") if isinstance(output, dict) else None
    if not isinstance(js, list):
        return None
    found = {}
    for ref in refs:
        j = next((x for x in js if isinstance(x, dict) and x.get("ref") == ref), None)
        if j is None:
            continue
        if not _cells_ok(j):
            return None
        found[ref] = j
    return found


def _refetch_claims(claims, ju_out):
    """워크플로 refetchClaims 와 같다."""
    ju = _judged_refs([c["ref"] for c in claims], ju_out)
    if ju is None:
        return []
    return [{"ref": c["ref"], "text": c["text"],
             "missing": {} if ju[c["ref"]].get("missing") is None else ju[c["ref"]]["missing"]}
            for c in claims if c["ref"] in ju and next_step(ju[c["ref"]]) == "refetch"]


def _rejudge_claims(claims, rf_out):
    """워크플로 rejudgeClaims 와 같다."""
    return [_to_judge_claim(c, _judgment_of(rf_out, c["ref"])) for c in claims
            if _judgment_of(rf_out, c["ref"]) is not None and _passes_extract(_judgment_of(rf_out, c["ref"]))]


def batch_claims(claims_by_url, size=BATCH_SIZE):
    """워크플로 batchClaims 와 같다. 키 차례대로 앞 묶음부터 채우고 앞 묶음으로 되돌아가지 않는다(next-fit)."""
    batches, cur, count = [], None, 0
    for url, claims in claims_by_url.items():
        if not claims:
            continue
        if cur is None or count + len(claims) > size:
            cur, count = {"items": []}, 0
            batches.append(cur)
        cur["items"].append({"url": url, "claims": claims})
        count += len(claims)
    return batches


def split_by_url(outputs, batches):
    """워크플로 splitByUrl 과 같다. outputs[i] 는 batches[i] 의 출력(ref 를 되돌린 것)이고, 없으면 None 이다.
    입력에 없던 URL 이나 ref 의 판정은 버리고, 같은 (url, ref) 의 판정이 둘 이상이면 그 ref 의 판정을 모두 버린다."""
    out = {}
    for b, o in zip(batches, outputs):
        ok = isinstance(o, dict) and isinstance(o.get("judgments"), list)
        for it in b["items"]:
            if not ok:
                out[it["url"]] = None
                continue
            refs = [c["ref"] for c in it["claims"]]
            mine = [j for j in o["judgments"] if isinstance(j, dict) and j.get("url") == it["url"] and j.get("ref") in refs]
            out[it["url"]] = {"judgments": [j for j in mine if sum(1 for x in mine if x.get("ref") == j.get("ref")) == 1],
                              "principles_applied": [] if o.get("principles_applied") is None else o["principles_applied"]}
    return out


def neutral_payload(batch):
    """묶음의 ref 를 정답이 드러나지 않는 번호(c1, c2 …)로 바꾼 판정 입력과, 번호 -> 원래 ref 표다.
    시험 자료의 항목 id(acc-t1, quo-f1 같은 것)는 -t·-f 로 참·오류를 드러내기 때문이다(결정 기록 5 「ref 이름이 정답을 드러내는 한계」)."""
    back, items = {}, []
    for it in batch["items"]:
        claims = []
        for c in it["claims"]:
            n = f"c{len(back) + 1}"
            back[n] = c["ref"]
            claims.append(dict(c, ref=n))
        items.append({"url": it["url"], "claims": claims})
    return {"items": items}, back


def restore_refs(output, back):
    """판정 출력의 ref 를 원래 ref 로 되돌린 사본이다. 표에 없는 ref 는 None 이 되어 split_by_url 이 버린다."""
    if not isinstance(output, dict) or not isinstance(output.get("judgments"), list):
        return output
    js = [dict(j, ref=back.get(j.get("ref")) if isinstance(j.get("ref"), str) else None) if isinstance(j, dict) else j
          for j in output["judgments"]]
    return dict(output, judgments=js)


def _url_claims(cases):
    by_url = {}
    for x in cases["items"]:
        by_url.setdefault(x["url"], []).append({"ref": x["id"], "text": x["claim"]["text"]})
    return by_url


def def_key(stage, config, repeat, unit, payload):
    """그 단계·설정·차례·unit 을 그 입력으로 실행하면 run.py 가 줄에 적을 key 다."""
    model, effort = config.split("/")
    return make_key(stage, model, effort, "", repeat, unit, def_prompt(stage, payload) + def_system(stage))


def def_row(runs, stage, config, repeat, unit, payload):
    """def_key 와 key 가 같은 줄 중 오류 없는 마지막 줄이다. 정의나 입력이 다른 옛 줄은 고르지 않는다. 없으면 None."""
    key = def_key(stage, config, repeat, unit, payload)
    row = None
    for r in runs:
        if r.get("key") == key and not r.get("error") and r.get("output") is not None:
            row = r
    return row


def pipeline(cases, runs, repeat):
    """한 차례의 -def 단계를 워크플로의 차례(추출, 판정 묶음, 보충, 재판정 묶음)로 따라간다.
    앞 단계 출력은 UPSTREAM 의 단계별 설정 줄에서 고른다. 반환값의 키는 아래와 같다.
    units[stage]: 그 단계에 보낼 (unit, payload) 목록이다. 판정·재판정의 payload 는 중립 번호로 바꾼 입력이다.
    batches[stage]: 판정·재판정 묶음(원래 ref)이다. rows[stage][unit]: 고른 줄이다(없으면 키가 없다).
    outputs[stage]: URL 을 키로 둔 단계 출력이다. 판정·재판정은 split_by_url 의 값이고 ref 는 항목 id 로 되돌렸다."""
    p = {"units": {}, "batches": {}, "rows": {}, "outputs": {}}

    def per_url(stage, jobs):
        p["units"][stage] = [(u, {"url": u, "claims": c}) for u, c in jobs]
        p["rows"][stage], p["outputs"][stage] = {}, {}
        for u, payload in p["units"][stage]:
            r = def_row(runs, stage, UPSTREAM[stage], repeat, u, payload)
            if r is not None:
                p["rows"][stage][u] = r
                p["outputs"][stage][u] = r["output"]
        return p["outputs"][stage]

    def batched(stage, claims_by_url):
        batches = batch_claims(claims_by_url)
        p["batches"][stage], p["units"][stage], p["rows"][stage] = batches, [], {}
        outs = []
        for i, b in enumerate(batches):
            unit = f"batch:{i + 1}"
            payload, back = neutral_payload(b)
            p["units"][stage].append((unit, payload))
            r = def_row(runs, stage, UPSTREAM[stage], repeat, unit, payload)
            if r is not None:
                p["rows"][stage][unit] = r
            outs.append(None if r is None else restore_refs(r["output"], back))
        p["outputs"][stage] = split_by_url(outs, batches)
        return p["outputs"][stage]

    claims = _url_claims(cases)
    extract = per_url("extract-def", list(claims.items()))
    judge = batched("judge-def", {u: _judge_claims(c, extract.get(u)) for u, c in claims.items()})
    jobs = [(it["url"], _refetch_claims(it["claims"], judge.get(it["url"]))) for b in p["batches"]["judge-def"] for it in b["items"]]
    jobs = [(u, c) for u, c in jobs if c]
    refetch = per_url("refetch-def", jobs)
    batched("rejudge-def", {u: _rejudge_claims(c, refetch.get(u)) for u, c in jobs})
    return p


def def_units(cases, stage, runs, repeat):
    """-def 단계의 (unit, payload) 목록이다. 보낼 주장이 없는 unit 은 없다."""
    if stage == "map-def":
        return [(m["id"], {"evidence_map": m["input"]["evidence_map"], "passed": m["input"]["passed"]}) for m in cases["map_cases"]]
    return pipeline(cases, runs, repeat)["units"][stage]


def def_output(cases, runs, stage, config, repeat, unit):
    """그 차례·unit 의 입력으로 계산한 key 가 같은 줄의 출력이다. 판정·재판정은 중립 번호 그대로다. 없으면 None."""
    payload = dict(def_units(cases, stage, runs, repeat)).get(unit)
    r = None if payload is None else def_row(runs, stage, config, repeat, unit, payload)
    return None if r is None else r["output"]


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
            us = def_units(cases, a.stage, past, rep)
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
