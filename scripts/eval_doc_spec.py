"""문서 명세(DOC-SPEC)의 효과를 시험한다. 쓰기 전에 조건이 잡히는지, 조건이 맞는지, 첫 초안이 조건대로 나오는지를 본다.
과제와 정답 6하는 evals/doc-spec/tasks.json 프리셋에 있고, 정답은 판정자에게만 준다. 임시 설정 폴더에서만 실행하고 끝나면 지운다.
사용: python scripts/eval_doc_spec.py <결과 폴더> <키 파일> [과제 id...]   (과제 id 를 주면 그 과제만 실행한다)
      python scripts/eval_doc_spec.py <결과 폴더> <키 파일> --rejudge      (저장한 초안의 판정만 다시 한다)
"""
import concurrent.futures as cf, json, os, re, shutil, subprocess, sys, tempfile

REPO = os.path.dirname(os.path.dirname(os.path.abspath(__file__))).replace("\\", "/")
GEN, JUDGE = "claude-opus-5-5", "claude-sonnet-5-5"
MARK = re.compile(r"`@문서 명세`\s*```.*?```\s*", re.S)


def setup(tmp, name, spec):
    root = f"{tmp}/{name}"
    cfg, work, store = f"{root}/cfg", f"{root}/work", f"{root}/doc-specs"
    for d in (cfg, work, store):
        os.makedirs(d)
    p = open(f"{REPO}/agent-principles.md", encoding="utf-8").read()
    shutil.copytree(f"{REPO}/skills/managing-docs", f"{cfg}/skills/managing-docs")
    rp = f"{cfg}/skills/managing-docs/references/reading-docs.md"
    s = open(rp, encoding="utf-8").read().replace("\r\n", "\n")
    s = s.replace("`~/.claude/disciplined-coder-doc-specs/`", f"`{store}/`")
    s = re.sub(r" `~` 는 USERPROFILE 이다\(Git Bash 의 `\$HOME` 은 다를 수 있다\)\.", "", s)
    if not spec:
        s = s[:s.index("## `DOC-SPEC`")] + s[s.index("## `TITLES`"):]
        s = s.replace("대화 안 초안에는 `DOC-SPEC` 과 `TITLES` 만", "대화 안 초안에는 `TITLES` 만")
        p = p.replace("`reading-docs.md` 의 `DOC-SPEC` 을 따르라", "`reading-docs.md` 를 따르라")
    open(rp, "w", encoding="utf-8", newline="\n").write(s)
    open(f"{cfg}/CLAUDE.md", "w", encoding="utf-8", newline="\n").write(p)
    return cfg, work, store


def session(prompt, cfg, cwd, key):
    env = {k: v for k, v in os.environ.items() if k not in ("CLAUDE_HOME_DIR", "CLAUDECODE", "CLAUDE_CODE_ENTRYPOINT")}
    env.update(CLAUDE_CONFIG_DIR=cfg, ANTHROPIC_API_KEY=key)
    r = subprocess.run(["claude", "-p", prompt, "--model", GEN, "--output-format", "stream-json", "--verbose",
                        "--allowedTools", "Skill Read Write Edit Bash Glob Grep"],
                       cwd=cwd, env=env, capture_output=True, text=True, encoding="utf-8", timeout=1500)
    tools, final = [], ""
    for line in r.stdout.splitlines():
        try:
            ev = json.loads(line)
        except ValueError:
            continue
        if ev.get("type") == "assistant":
            tools += [{"name": b["name"], "input": b["input"]} for b in ev["message"]["content"] if b.get("type") == "tool_use"]
        elif ev.get("type") == "result":
            final = ev.get("result", "")
    return {"tools": tools, "final": final, "stderr": r.stderr[-300:]}


def docx_text(path):
    import docx
    d = docx.Document(path)
    return "\n".join([x.text for x in d.paragraphs] + [c.text for t in d.tables for row in t.rows for c in row.cells])


def touches(tool, store):
    return store in json.dumps(tool["input"], ensure_ascii=False).replace("\\\\", "/")


def analyze(task, res, store, work):
    """도구 기록에서 순서와 첫 초안을 뽑는다."""
    spec_at = body_at = draft = None
    for n, t in enumerate(res["tools"]):
        cmd = t["input"].get("command", "") if t["name"] == "Bash" else ""
        if t["name"] not in ("Write", "Bash"):
            continue
        if touches(t, store):
            if spec_at is None and (t["name"] == "Write" or ">" in cmd or "write" in cmd):
                spec_at = n
            continue
        if t["name"] == "Write":
            body_at = n if body_at is None else body_at
            if draft is None and t["input"].get("file_path", "").endswith(".md"):
                draft = t["input"].get("content", "")
        elif body_at is None and "docx" in cmd and "save" in cmd:
            body_at = n
    out = {"read_reading_docs": any("reading-docs" in json.dumps(t["input"], ensure_ascii=False) for t in res["tools"]),
           "opened_skill": any(t["name"] == "Skill" for t in res["tools"]), "spec_at": spec_at, "body_at": body_at,
           "marker_in_draft": bool(draft and "@문서 명세" in draft), "tool_names": [t["name"] for t in res["tools"]]}
    if task["kind"] == "file":
        fp = f"{work}/{task['out']}"
        final_doc = docx_text(fp) if os.path.isfile(fp) else None
        out["marker_in_final"] = bool(final_doc and "@문서 명세" in final_doc)
        out["draft_source"] = "first_md" if draft else ("final_docx" if final_doc else "none")
        text = draft or final_doc or ""
    else:
        out["draft_source"] = "chat"
        text = res["final"]
    out["draft"] = MARK.sub("", text)
    return out


JUDGE_PROMPT = """아래 초안을 기준으로만 판정하라. 초안을 고치지 마라.

[문서의 실제 조건]
{truth}

[작성자가 받은 자료]
{materials}

[기준]
{criteria}

[초안]
{draft}

기준을 모두 충족하면 hit 를 true, 하나라도 어기면 false 로 하라. JSON 한 줄로만 답하라: {{"hit": true, "note": "어긴 기준이나 판단 근거 한두 문장"}}"""

SPEC_PROMPT = """아래 문서 명세가 정답과 맞는지 항목별로 판정하라.

[정답]
{truth}

[명세]
{spec}

항목(누가·언제·어디서·무엇을·왜)마다 ok(뜻이 맞거나, 정답이 '미확인'인데 미확인·기본값으로 표시), wrong(뜻이 틀림), guess(단서 없는 값을 기본값·미확인 표시 없이 사실처럼 적음) 중 하나를 매겨라.
JSON 한 줄로만 답하라: {{"items": {{"누가": "ok", "언제": "ok", "어디서": "ok", "무엇을": "ok", "왜": "ok"}}, "note": "틀린 항목의 이유"}}"""


def judge(prompt, tmp, key):
    d = tempfile.mkdtemp(dir=tmp)
    env = dict(os.environ, CLAUDE_CONFIG_DIR=d, ANTHROPIC_API_KEY=key)
    r = subprocess.run(["claude", "-p", prompt, "--tools", "", "--model", JUDGE, "--output-format", "text"],
                       cwd=d, env=env, capture_output=True, text=True, encoding="utf-8", timeout=600)
    m = re.search(r"\{.*\}", r.stdout, re.S)
    try:
        return json.loads(m.group(0))
    except (AttributeError, ValueError):
        return {"error": r.stdout[:300] + r.stderr[:200]}


def judge_draft(task, draft, tmp, key):
    materials = {"요청": task["prompt"], **task["files"]}
    return judge(JUDGE_PROMPT.format(truth=json.dumps(task["truth"], ensure_ascii=False), criteria=task["draft"], draft=draft,
                                     materials=json.dumps(materials, ensure_ascii=False)), tmp, key)


def rejudge(task, cond, tmp, outdir, key):
    p = f"{outdir}/{task['id']}-{cond}.json"
    a = json.load(open(p, encoding="utf-8"))
    a["draft_judge"] = judge_draft(task, a["draft"], tmp, key)
    json.dump(a, open(p, "w", encoding="utf-8"), ensure_ascii=False, indent=1)
    return p


def run_task(task, cond, tmp, outdir, key):
    name = f"{task['id']}-{cond}"
    cfg, work, store = setup(tmp, name, cond == "spec")
    for rel, body in task["files"].items():
        os.makedirs(os.path.dirname(f"{work}/{rel}"), exist_ok=True)
        open(f"{work}/{rel}", "w", encoding="utf-8").write(body)
    res = session(task["prompt"], cfg, work, key)
    a = analyze(task, res, store, work)
    specs = [open(f"{store}/{f}", encoding="utf-8").read() for f in os.listdir(store)]
    a["spec_files"] = len(specs)
    truth = json.dumps(task["truth"], ensure_ascii=False)
    if specs and task["truth"]:
        a["spec_judge"] = judge(SPEC_PROMPT.format(truth=truth, spec=specs[0]), tmp, key)
    a["draft_judge"] = judge_draft(task, a["draft"], tmp, key)
    a.update(final=res["final"], stderr=res["stderr"], specs=specs)
    if cond == "spec" and task["id"] == "rfp":  # 같은 산출물을 새 세션에서 고칠 때 명세를 읽는지 본다
        r2 = session("proposal.docx 의 가격을 2억 1천만원으로 고치고, 그 이유로 서버 비용 절감을 한 문장 더해 주세요.", cfg, work, key)
        a["reuse"] = {"read_spec": any(touches(t, store) and t["name"] in ("Read", "Bash", "Glob", "Grep") for t in r2["tools"]),
                      "tools": [t["name"] for t in r2["tools"]], "final": r2["final"][:800]}
    json.dump(a, open(f"{outdir}/{name}.json", "w", encoding="utf-8"), ensure_ascii=False, indent=1)
    return name


def main():
    outdir, keyfile, *sel = sys.argv[1:]
    fn = rejudge if sel == ["--rejudge"] else run_task
    sel = [] if fn is rejudge else sel
    os.makedirs(outdir, exist_ok=True)
    key = [l.split("=", 1)[1].strip() for l in open(keyfile, encoding="utf-8") if l.startswith("ANTHROPIC_API_KEY=")][0]
    tasks = [t for t in json.load(open(f"{REPO}/evals/doc-spec/tasks.json", encoding="utf-8")) if not sel or t["id"] in sel]
    root = os.environ.get("EVAL_TMP", "D:/dc-eval-tmp")
    os.makedirs(root, exist_ok=True)
    tmp = tempfile.mkdtemp(prefix="docspec-", dir=root).replace("\\", "/")
    try:
        with cf.ThreadPoolExecutor(4) as ex:
            futs = {ex.submit(fn, t, c, tmp, outdir, key): (t["id"], c) for t in tasks for c in ("spec", "nospec")}
            for f in cf.as_completed(futs):
                try:
                    print("done", f.result(), flush=True)
                except Exception as e:
                    print("ERR", futs[f], repr(e)[:300], flush=True)
    finally:
        shutil.rmtree(tmp, ignore_errors=True)


if __name__ == "__main__":
    main()
