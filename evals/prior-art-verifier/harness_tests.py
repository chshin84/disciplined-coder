"""run_tests.sh 가 이름으로 부르는 단위 검사다. 인자로 받은 검사 하나를 실행하고, 실패하면 1 로 끝난다."""
import os
import sys

sys.path.insert(0, os.path.dirname(os.path.abspath(__file__)))
import run  # noqa: E402


def test_build_cmd_tools():
    cmds = {s: run.build_cmd(s, "m", "low", "p") for s in ("baseline-cite", "extract", "judge", "map", "baseline-map")}
    need = ["--effort", "--model", "--setting-sources", "--strict-mcp-config", "--disable-slash-commands",
            "--no-session-persistence"]
    assert all(all(n in c for n in need) for c in cmds.values())

    def tools(c, v):
        return c[c.index("--tools") + 1] == v and c[c.index("--allowedTools") + 1] == v
    assert tools(cmds["baseline-cite"], "WebFetch,Read") and tools(cmds["extract"], "WebFetch,Read")
    assert tools(cmds["judge"], "Read") and tools(cmds["map"], "Read") and tools(cmds["baseline-map"], "Read")
    assert tools(run.build_cmd("refetch-def", "m", "low", "p"), "WebFetch,Read") and tools(run.build_cmd("rejudge-def", "m", "low", "p"), "Read")


def test_parse_output_fenced():
    assert run.parse_output('앞 글\n```json\n{"a": 1}\n```') == {"a": 1}


def test_prompt_sha_changes_key():
    assert run.make_key("judge", "m", "low", "c", 1, "u", "주장 하나") != run.make_key("judge", "m", "low", "c", 1, "u", "주장 둘")


# --- score.py 검사. 가짜 자료: direction 참 d1, 오류 d2. 지도 대조 칸 넷.
def _cases():
    return {"items": [
        {"id": "d1", "category": "direction", "url": "u1", "claim": {"ref": "d1", "text": "t"}, "truth": True, "check_note": "n"},
        {"id": "d2", "category": "direction", "url": "u1", "claim": {"ref": "d2", "text": "t"}, "truth": False, "check_note": "n"},
        {"id": "a1", "category": "access", "url": "u2", "claim": {"ref": "a1", "text": "t"}, "truth": True, "check_note": "n"},
        {"id": "a2", "category": "access", "url": "u3", "claim": {"ref": "a2", "text": "t"}, "truth": False, "check_note": "n"}],
        "map_cases": [{"id": "map-1", "input": {}, "truth": [
            {"row": "A", "column": "outcome", "grounded": False}, {"row": "A", "column": "x", "grounded": True}]}]}


def _fix(cases, runs, frozen=None):
    """가짜 실행 줄에 현재 프롬프트로 계산한 key 를 넣는다."""
    import score
    for r in runs:
        r["key"] = score.expected_key(cases, r, frozen or {})
    return runs


def _run(stage, model, effort, unit, judgments, repeat=1, category="direction", cost=0.01, cells=None):
    out = {"cells": cells} if cells is not None else {"judgments": judgments}
    return {"key": f"{stage}{model}{effort}{unit}{repeat}", "stage": stage, "model": model, "effort": effort,
            "category": category, "repeat": repeat, "unit": unit, "output": out, "cost_usd": cost, "error": ""}


def test_missing_judgment_is_failure():
    import score
    runs = [_run("judge", "h", "low", "u1", [{"ref": "d1", "match": "일치"}])]
    fz = {("u1", "d1"): {"quote": "q"}, ("u1", "d2"): {"quote": "q"}}
    s = score.score(_cases(), _fix(_cases(), runs, fz), "judge", "direction", frozen=fz)
    r = s["h/low"][0]
    assert r["failures"] == 1 and r["missed_errors"] == 0 and r["rejected_truths"] == 0


def test_no_quote_excluded():
    import score
    runs = [_run("judge", "h", "low", "u1", [{"ref": "d1", "match": "일치"}])]
    fz = {("u1", "d1"): {"quote": "q"}, ("u1", "d2"): {"quote": ""}}
    s = score.score(_cases(), _fix(_cases(), runs, fz), "judge", "direction", frozen=fz)
    r = s["h/low"][0]
    assert r["failures"] == 0 and r["excluded"] == ["d2"]


def test_unverifiable_counts_as_rejection():
    import score
    runs = [_run("baseline-cite", "o", "medium", "u1", [{"ref": "d1", "verdict": "unverifiable"}, {"ref": "d2", "verdict": "unsupported"}])]
    r = score.score(_cases(), _fix(_cases(), runs), "baseline-cite", "direction")["o/medium"][0]
    assert r["rejected_truths"] == 1 and r["missed_errors"] == 0


def _S(m, r, f=0, c=1.0):
    return {"missed_errors": m, "rejected_truths": r, "failures": f, "excluded": [], "cost_usd": c}


def test_zero_noise():
    import score
    base, noise = score.baseline_of([_S(0, 0), _S(0, 0)])
    assert noise == {"missed_errors": 0, "rejected_truths": 0}
    assert score.select({"claude-haiku-5-5/low": [_S(1, 0, c=0.1)]}, base, noise) is None


def test_noise_tolerance():
    import score
    base, noise = score.baseline_of([_S(0, 0), _S(1, 0)])
    assert base["missed_errors"] == 1 and noise["missed_errors"] == 1
    assert score.select({"claude-haiku-5-5/low": [_S(2, 0, c=0.1)]}, base, noise) == "claude-haiku-5-5/low"


def test_failures_block_selection():
    import score
    base, noise = score.baseline_of([_S(0, 0), _S(0, 0)])
    assert score.select({"claude-haiku-5-5/low": [_S(0, 0, f=1, c=0.1)]}, base, noise) is None


def test_select_extract_single():
    import score
    z = score.baseline_of([_S(0, 0), _S(0, 0)])
    per = {"access": {"claude-haiku-5-5/low": [_S(0, 0, c=0.1)], "claude-sonnet-5-5/low": [_S(0, 0, c=0.5)]},
           "exists": {"claude-haiku-5-5/low": [_S(1, 0, c=0.1)], "claude-sonnet-5-5/low": [_S(0, 0, c=0.5)]},
           "quote": {"claude-haiku-5-5/low": [_S(0, 0, c=0.1)], "claude-sonnet-5-5/low": [_S(0, 0, c=0.5)]}}
    assert score.select_extract(per, {c: z for c in per}) == "claude-sonnet-5-5/low"


def test_map_scoring():
    import score
    cells = [{"row": "A", "column": "outcome", "grounded": True}, {"row": "A", "column": "x", "grounded": True}]
    r = score.score(_cases(), _fix(_cases(), [_run("map", "h", "low", "map-1", None, category="", cells=cells)]), "map", "map")["h/low"][0]
    assert r["missed_errors"] == 1 and r["rejected_truths"] == 0



def test_xhigh_effort_allowed():
    import score
    assert "xhigh" in run.EFFORTS
    assert score._order("claude-haiku-5-5/xhigh", 0) > score._order("claude-haiku-5-5/high", 0)
    assert score._order("claude-haiku-5-5/xhigh", 0) < score._order("claude-sonnet-5-5/low", 0)



def test_judge_borrows_true_quote():
    """오류 항목에 자기 구절이 없으면 같은 출처·같은 카테고리의 짝 참 항목(-tN ↔ -fN) 구절로 판정한다."""
    import score
    cases = {"items": [
        {"id": "dir-t1", "category": "direction", "url": "u1", "claim": {"ref": "dir-t1", "text": "a"}, "truth": True, "check_note": "n"},
        {"id": "dir-f1", "category": "direction", "url": "u1", "claim": {"ref": "dir-f1", "text": "b"}, "truth": False, "check_note": "n"}],
        "map_cases": []}
    frozen = {("u1", "dir-t1"): {"quote": "Q", "context": "C"}, ("u1", "dir-f1"): {"quote": "", "context": ""}}
    us = run.units(cases, "judge", "direction", frozen)
    refs = {c["ref"]: c for _, p in us for c in p["claims"]}
    assert refs["dir-f1"]["quote"] == "Q" and refs["dir-f1"]["text"] == "b"
    runs = [_run("judge", "h", "low", "u1", [{"ref": "dir-t1", "match": "일치"}, {"ref": "dir-f1", "match": "일치"}])]
    r = score.score(cases, _fix(cases, runs, frozen), "judge", "direction", frozen=frozen)["h/low"][0]
    assert r["excluded"] == [] and r["missed_errors"] == 1



def test_stale_prompt_ignored():
    """현재 프롬프트로 계산한 key 와 다른 줄(옛 프롬프트의 결과)은 집계에 쓰지 않는다."""
    import score
    runs = [_run("baseline-cite", "o", "medium", "u1", [{"ref": "d1", "verdict": "supported"}, {"ref": "d2", "verdict": "unsupported"}])]
    runs[0]["key"] = "stale0000000000"
    assert score.score(_cases(), runs, "baseline-cite", "direction") == {}


def test_true_without_quote_counts_as_rejection():
    """구절이 없는 참 항목은 실제 파이프라인에서 unsupported 이므로 판정 단계에서도 참 기각으로 센다."""
    import score
    fz = {("u1", "d1"): {"quote": ""}, ("u1", "d2"): {"quote": "q"}}
    runs = _fix(_cases(), [_run("judge", "h", "low", "u1", [{"ref": "d2", "match": "불일치"}])], fz)
    r = score.score(_cases(), runs, "judge", "direction", frozen=fz)["h/low"][0]
    assert r["rejected_truths"] == 1 and r["failures"] == 0 and r["excluded"] == []


def test_judge_respects_frozen_exists():
    """추출에서 존재 불일치나 접근 실패인 참 항목은 판정이 일치여도 참 기각이다."""
    import score
    fz = {("u1", "d1"): {"quote": "q", "exists": "불일치", "access": "성공"}, ("u1", "d2"): {"quote": "q"}}
    runs = _fix(_cases(), [_run("judge", "h", "low", "u1", [{"ref": "d1", "match": "일치"}, {"ref": "d2", "match": "불일치"}])], fz)
    r = score.score(_cases(), runs, "judge", "direction", frozen=fz)["h/low"][0]
    assert r["rejected_truths"] == 1


def test_map_missing_cells_fail():
    """입력 근거 지도의 판정 대상 칸(case, outcome, 각 축의 prior)을 출력이 빠뜨리면 실패로 센다."""
    import score
    cases = {"items": [], "map_cases": [{"id": "map-1", "input": {"evidence_map": [
        {"case": "A", "outcome": "실패", "axes": {"purpose": {"prior": "p"}}}], "passed": []},
        "truth": [{"row": "A", "column": "outcome", "grounded": True}]}]}
    cells = [{"row": "A", "column": "outcome", "grounded": True}]
    runs = _fix(cases, [_run("map", "h", "low", "map-1", None, category="", cells=cells)])
    r = score.score(cases, runs, "map", "map")["h/low"][0]
    assert r["failures"] == 2


# --- 구성 전체 재측정(-def 단계, replay.py, report-v4) 검사.
def _harn_run(inp):
    import subprocess
    import json
    p = subprocess.run(["node", os.path.join(run.ROOT, "scripts", "workflow_harness.mjs"), "run"],
                       input=json.dumps(inp, ensure_ascii=False), capture_output=True, text=True, encoding="utf-8")
    assert p.returncode == 0, p.stderr
    return json.loads(p.stdout)


H, OP = "claude-haiku-5-5", "claude-opus-5-5"
HH, OM = H + "/high", OP + "/medium"
ROW_B = {"case": "사례 B", "url": "https://b", "outcome": "실패",
         "axes": {k: {"prior": f"{k} 서술", "same": True, "note": ""} for k in ("purpose", "mechanism", "evaluation", "target")}}


def _case_b_text():
    """워크플로 groupByUrl 이 근거 지도 행으로 만드는 주장 문장(JSON.stringify)과 같은 글이다."""
    import json
    prior = {k: ROW_B["axes"][k]["prior"] for k in ("purpose", "mechanism", "evaluation", "target")}
    return json.dumps({"case": ROW_B["case"], "outcome": ROW_B["outcome"], "prior": prior}, ensure_ascii=False, separators=(",", ":"))


def _def_case():
    """URL 둘에 주장 셋이 걸린 재측정 자료다. id 는 워크플로가 만드는 ref 와 같게 둔다."""
    return {"items": [
        {"id": "S1#issue#0", "category": "direction", "url": "https://a", "claim": {"ref": "x", "text": "주장 A"}, "truth": True, "check_note": "n"},
        {"id": "S1#issue#1", "category": "scope", "url": "https://a", "claim": {"ref": "y", "text": "주장 \"B\""}, "truth": False, "check_note": "n"},
        {"id": "S1#case#0", "category": "direction", "url": "https://b", "claim": {"ref": "z", "text": _case_b_text()}, "truth": True, "check_note": "n"}],
        "map_cases": []}


def _def_row(stage, model, effort, unit, output, repeat=1, usage=None):
    return {"key": "", "stage": stage, "model": model, "effort": effort, "category": "",
            "repeat": repeat, "unit": unit, "output": output, "cost_usd": 0.01, "usage": usage, "error": ""}


def _keyed(cases, rows):
    """가짜 -def 줄에 run.py 가 그 차례에 계산했을 key 를 앞 줄부터 차례로 넣는다. 그 차례에 없는 unit 이면 None 이다."""
    done = []
    for r in rows:
        us = dict(run.def_units(cases, r["stage"], done, r["repeat"]))
        r["key"] = (run.def_key(r["stage"], f"{r['model']}/{r['effort']}", r["repeat"], r["unit"], us[r["unit"]])
                    if r["unit"] in us else None)
        done.append(r)
    return rows


def _jd(ref, url, nc="일치", d="일치", sc="일치", missing=None, unsure=None, reason="r"):
    return {"url": url, "ref": ref, "numbers_conditions": nc, "direction": d, "scope": sc,
            "missing": missing or {}, "unsure_reasons": unsure or {}, "reason": reason}


def _renamed(out, names):
    """판정 출력의 ref 를 names 대로 바꾼 사본이다. 워크플로 응답(항목 id)과 run.py 줄(중립 번호)을 같은 판정으로 만든다."""
    import copy
    o = copy.deepcopy(out)
    for j in o["judgments"]:
        j["ref"] = names.get(j["ref"], j["ref"])
    return o


EXTRACT_OUT = {"url": "https://a", "principles_applied": [], "judgments": [
    {"ref": "S1#issue#0", "access": "성공", "exists": "일치", "exists_note": "n0", "quote": "q0", "context": "c0", "reason": "r"},
    {"ref": "S1#issue#1", "access": "성공", "exists": "일치", "quote": "q1", "reason": "r"}]}
B_EXTRACT = {"url": "https://b", "principles_applied": [], "judgments": [
    {"ref": "S1#case#0", "access": "성공", "exists": "일치", "exists_note": "nb", "quote": "qb", "context": "", "reason": "r"}]}
# 주장 0 은 정보 부족이라 보충·재판정을 거쳐 일치가 되고, 주장 1 은 판정 불가라 기각되고, 주장 2 는 바로 일치다.
JUDGE_WF = {"principles_applied": [], "judgments": [
    _jd("S1#issue#0", "https://a", nc="정보 부족", missing={"numbers_conditions": "세션 수"}),
    _jd("S1#issue#1", "https://a", d="판정 불가", unsure={"direction": "언어 해석"}),
    _jd("S1#case#0", "https://b")]}
NEUTRAL = {"S1#issue#0": "c1", "S1#issue#1": "c2", "S1#case#0": "c3"}
JUDGE_ROW = _renamed(JUDGE_WF, NEUTRAL)
REFETCH_OUT = {"url": "https://a", "principles_applied": [], "judgments": [
    {"ref": "S1#issue#0", "access": "성공", "exists": "일치", "exists_note": "n0b", "quote": "q0b", "context": "c0b", "reason": "r"}]}
REJUDGE_WF = {"principles_applied": [], "judgments": [_jd("S1#issue#0", "https://a")]}
REJUDGE_ROW = _renamed(REJUDGE_WF, {"S1#issue#0": "c1"})


def _pipeline_rows(judge=JUDGE_ROW, judge_config=(OP, "medium")):
    import copy
    return copy.deepcopy([
        _def_row("extract-def", H, "high", "https://a", EXTRACT_OUT), _def_row("extract-def", H, "high", "https://b", B_EXTRACT),
        _def_row("judge-def", judge_config[0], judge_config[1], "batch:1", judge, usage={"output_tokens": 1234}),
        _def_row("refetch-def", H, "high", "https://a", REFETCH_OUT),
        _def_row("rejudge-def", OP, "medium", "batch:1", REJUDGE_ROW, usage={"output_tokens": 300})])


def _agent_body(agent_type):
    """agentType 이 가리키는 정의 파일에서 frontmatter 를 뗀 본문이다. 운영의 system 프롬프트에 들어가는 지시문이다."""
    with open(os.path.join(run.ROOT, "agents", agent_type.split(":")[1] + ".md"), encoding="utf-8") as f:
        text = f.read()
    return text[text.index("\n---", 3) + 4:].lstrip("\n")


def test_def_prompt_matches_workflow():
    """harn run 이 기록한 extract:·judge:<n>·refetch:·rejudge:<n>·map-check 호출이 run.py -def 단계와 같다.
    사용자 메시지는 프롬프트로, system 프롬프트는 agentType 의 정의 본문으로 대조한다. 묶음 단계는 중립 번호로 바꾸기 전의 묶음을 대조한다."""
    args = {"question": "Q?", "situation": "S", "target": "T", "mode": "survey", "round": 1,
            "subquestions": [{"id": "S1", "scope": "a", "include": [], "exclude": []}], "forbidden_terms": [],
            "researcher_count": 1, "researcher_count_basis": "x", "principles_path": run.PRINCIPLES}
    synthesis = {"evidence_map": [ROW_B], "conclusions": [], "principles_applied": []}
    responses = {"research:S1": {"search_status": "ok", "queries": ["q"], "issues": [
        {"prior_claim": "주장 A", "citations": [{"url": "https://a"}]},
        {"prior_claim": "주장 \"B\"", "citations": [{"url": "https://a"}]}], "evidence_map": [ROW_B]},
        "extract:https://a": EXTRACT_OUT, "extract:https://b": B_EXTRACT, "judge:1": JUDGE_WF,
        "refetch:https://a": REFETCH_OUT, "rejudge:1": REJUDGE_WF, "synthesize": synthesis,
        "map-check": {"cells": [], "principles_applied": []}}
    calls = {c["label"]: c for c in _harn_run({"args": args, "responses": responses})["calls"]}
    assert "judge:2" not in calls and "rejudge:2" not in calls
    cases = _def_case()
    cases["map_cases"] = [{"id": "map-1", "input": {"evidence_map": [ROW_B], "passed": [{"ref": "S1#case#0", "row": ROW_B}]}, "truth": []}]
    runs = _keyed(cases, _pipeline_rows())
    pipe = run.pipeline(cases, runs, 1)
    pairs = {("extract-def", "https://a"): "extract:https://a", ("extract-def", "https://b"): "extract:https://b",
             ("judge-def", "batch:1"): "judge:1", ("refetch-def", "https://a"): "refetch:https://a",
             ("rejudge-def", "batch:1"): "rejudge:1", ("map-def", "map-1"): "map-check"}
    for (stage, unit), label in pairs.items():
        us = dict(run.def_units(cases, stage, runs, 1))
        system = run.def_system(stage)
        if stage in run.BATCH_STAGES:
            orig = pipe["batches"][stage][int(unit.split(":")[1]) - 1]
            assert run.def_prompt(stage, orig) == calls[label]["prompt"], stage
            assert us[unit] == run.neutral_payload(orig)[0], stage
        else:
            assert run.def_prompt(stage, us[unit]) == calls[label]["prompt"], stage
        assert system == _agent_body(calls[label]["agentType"]), stage
        user = run.def_prompt(stage, us[unit])
        cmd = run.build_cmd(stage, "m", "high", user, system)
        assert cmd[cmd.index("-p") + 1] == user and cmd[cmd.index("--system-prompt") + 1] == system, stage


def test_batches_match_workflow():
    """run.py 의 묶음이 같은 입력에서 워크플로 batchClaims 와 같다. 판정 단계의 묶음도 같은 규칙(크기 20)으로 만든다."""
    import replay

    def cl(u, n):
        return [{"ref": f"{u}-{i}", "text": "t", "quote": "q", "context": "", "source_note": ""} for i in range(n)]
    cbu = {"u1": cl("u1", 8), "u2": cl("u2", 9), "u3": cl("u3", 8), "u4": [], "u5": cl("u5", 21), "u6": cl("u6", 3)}
    got = run.batch_claims(cbu, 20)
    assert got == replay.harn("batchClaims", [cbu, 20])
    assert [[it["url"] for it in b["items"]] for b in got] == [["u1", "u2"], ["u3"], ["u5"], ["u6"]]
    # 판정 단계: URL 셋에 주장 12·9·3 개면 묶음은 [12], [9, 3] 이다.
    items, ext = [], {}
    for u, n in (("https://p", 12), ("https://q", 9), ("https://r", 3)):
        for i in range(n):
            items.append({"id": f"{u[-1]}{i}", "category": "direction", "url": u, "claim": {"ref": "x", "text": f"주장 {i}"},
                          "truth": True, "check_note": "n"})
        ext[u] = {"url": u, "principles_applied": [], "judgments": [
            {"ref": f"{u[-1]}{i}", "access": "성공", "exists": "일치", "quote": "q", "context": "", "reason": "r"} for i in range(n)]}
    cases = {"items": items, "map_cases": []}
    runs = _keyed(cases, [_def_row("extract-def", H, "high", u, o) for u, o in ext.items()])
    pipe = run.pipeline(cases, runs, 1)
    judge_in = {u: run._judge_claims([{"ref": x["id"], "text": x["claim"]["text"]} for x in items if x["url"] == u], o)
                for u, o in ext.items()}
    assert pipe["batches"]["judge-def"] == replay.harn("batchClaims", [judge_in, run.BATCH_SIZE])
    assert [[len(it["claims"]) for it in b["items"]] for b in pipe["batches"]["judge-def"]] == [[12], [9, 3]]
    assert [u for u, _ in run.def_units(cases, "judge-def", runs, 1)] == ["batch:1", "batch:2"]


def test_upstream_config_per_stage():
    """앞 단계 출력은 단계마다 정한 설정의 줄에서 고른다. refetch-def 와 replay 는 Opus medium 판정 줄을 찾는다."""
    import replay
    cases = _def_case()
    assert run.UPSTREAM["judge-def"] == OM and run.UPSTREAM["rejudge-def"] == OM
    assert run.UPSTREAM["extract-def"] == HH and run.UPSTREAM["refetch-def"] == HH
    runs = _keyed(cases, _pipeline_rows()[:3])
    assert [u for u, _ in run.def_units(cases, "refetch-def", runs, 1)] == ["https://a"]
    rows = {r["id"]: r for r in replay.replay(cases, _keyed(cases, _pipeline_rows()), 1)}
    assert rows["S1#issue#0"]["judge_raw"] is not None and rows["S1#issue#0"]["rejudge_raw"] is not None
    # 판정 줄이 Haiku high 이면 고르지 않는다. 보충 대상이 없고, 판정 묶음의 출력이 없으므로 그 URL 들이 검증 실패다.
    other = _keyed(cases, _pipeline_rows(judge_config=(H, "high"))[:3])
    assert run.def_units(cases, "refetch-def", other, 1) == []
    rows = {r["id"]: r for r in replay.replay(cases, other, 1)}
    assert all(r["judge_raw"] is None and r["verdict"] == "verify_failed" for r in rows.values())


def test_neutral_refs_roundtrip():
    """판정·재판정 입력에는 항목 id 가 없고 ref 는 c1, c2 … 다. 판정 출력은 채점 때 항목 id 로 되돌아온다."""
    import json
    import replay
    cases = {"items": [
        {"id": "dir-t1", "category": "direction", "url": "u1", "claim": {"ref": "x", "text": "참 주장"}, "truth": True, "check_note": "n"},
        {"id": "dir-f1", "category": "direction", "url": "u1", "claim": {"ref": "y", "text": "오류 주장"}, "truth": False, "check_note": "n"}],
        "map_cases": []}
    ext = {"url": "u1", "principles_applied": [], "judgments": [
        {"ref": i, "access": "성공", "exists": "일치", "quote": "q", "context": "", "reason": "r"} for i in ("dir-t1", "dir-f1")]}
    rows = [_def_row("extract-def", H, "high", "u1", ext)]
    payload = dict(run.def_units(cases, "judge-def", _keyed(cases, rows), 1))["batch:1"]
    text = json.dumps(payload, ensure_ascii=False)
    assert "dir-t1" not in text and "dir-f1" not in text
    assert [c["ref"] for it in payload["items"] for c in it["claims"]] == ["c1", "c2"]
    rows.append(_def_row("judge-def", OP, "medium", "batch:1", {"principles_applied": [], "judgments": [
        _jd("c1", "u1"), _jd("c2", "u1", d="불일치")]}))
    got = {r["id"]: r for r in replay.replay(cases, _keyed(cases, rows), 1)}
    assert got["dir-t1"]["judge_raw"]["ref"] == "dir-t1" and got["dir-t1"]["verdict"] == "supported"
    assert got["dir-f1"]["judge_raw"]["ref"] == "dir-f1" and got["dir-f1"]["verdict"] == "unsupported"
    # 재판정 입력도 중립 번호다.
    cases = _def_case()
    rj = dict(run.def_units(cases, "rejudge-def", _keyed(cases, _pipeline_rows()), 1))["batch:1"]
    assert "S1#" not in json.dumps(rj, ensure_ascii=False) and rj["items"][0]["claims"][0]["ref"] == "c1"


def test_replay_splits_batch():
    """replay 가 묶음 출력을 URL 별로 나눠 mergeStages 에 넘긴다. 빠진 주장만 검증 실패이고, 입력에 없던 판정은 버린다."""
    import replay
    cases = _def_case()
    out = {"principles_applied": [], "judgments": [JUDGE_ROW["judgments"][0], JUDGE_ROW["judgments"][2],
                                                   _jd("c3", "https://zzz", d="불일치"), _jd("c9", "https://a", d="불일치")]}
    rows = {r["id"]: r for r in replay.replay(cases, _keyed(cases, _pipeline_rows(judge=out)), 1)}
    assert rows["S1#issue#1"]["verdict"] == "verify_failed" and rows["S1#issue#1"]["judge_sent"] is True
    assert rows["S1#issue#1"]["judge_raw"] is None and rows["S1#issue#1"]["judge_batch"] == "batch:1"
    assert rows["S1#issue#0"]["verdict"] == "supported" and rows["S1#case#0"]["verdict"] == "supported"
    # 같은 (url, ref) 의 판정이 둘이면 그 주장만 검증 실패다.
    dup = {"principles_applied": [], "judgments": JUDGE_ROW["judgments"] + [_jd("c3", "https://b", d="불일치")]}
    rows = {r["id"]: r for r in replay.replay(cases, _keyed(cases, _pipeline_rows(judge=dup)), 1)}
    assert rows["S1#case#0"]["verdict"] == "verify_failed" and rows["S1#issue#0"]["verdict"] == "supported"
    # 판정 묶음 줄이 없으면 그 묶음의 URL 이 모두 검증 실패다.
    rs = [r for r in _pipeline_rows() if r["stage"] != "judge-def"]
    rows = {r["id"]: r for r in replay.replay(cases, _keyed(cases, rs), 1)}
    assert all(r["verdict"] == "verify_failed" for r in rows.values())
    # 재판정 묶음 줄이 없으면 보충한 주장만 검증 실패다.
    rows = {r["id"]: r for r in replay.replay(cases, _keyed(cases, _pipeline_rows()[:4]), 1)}
    assert rows["S1#issue#0"]["verdict"] == "verify_failed" and rows["S1#issue#0"]["rejudge_sent"] is True
    assert rows["S1#issue#1"]["verdict"] == "unsupported" and rows["S1#case#0"]["verdict"] == "supported"


def test_replay_uses_workflow_merge():
    """가짜 단계 출력으로 replay 가 mergeStages·classify 의 판정을 그대로 옮긴다. 판정 불가는 기각이고 이유가 reason 에 남는다."""
    import replay
    cases = _def_case()
    rows = {r["id"]: r for r in replay.replay(cases, _keyed(cases, _pipeline_rows()), 1)}
    assert rows["S1#issue#0"]["verdict"] == "supported" and rows["S1#case#0"]["verdict"] == "supported"
    assert rows["S1#issue#1"]["verdict"] == "unsupported" and rows["S1#issue#1"]["judge_raw"]["direction"] == "판정 불가"
    assert "판정 불가: direction=언어 해석" in rows["S1#issue#1"]["reason"]
    assert all("escalate" not in k for r in rows.values() for k in r)


def test_replay_passes_refetch_and_rejudge():
    """replay 가 보충·재판정 출력을 mergeStages 에 넘긴다. 빠지면 보충에 보낸 주장만 검증 실패다."""
    import replay
    cases = _def_case()
    rows = {r["id"]: r for r in replay.replay(cases, _keyed(cases, _pipeline_rows()), 1)}
    r0 = rows["S1#issue#0"]
    assert r0["refetch_sent"] is True and r0["refetch_raw"]["quote"] == "q0b" and r0["rejudge_raw"]["direction"] == "일치"
    assert r0["rejudge_batch"] == "batch:1"
    assert rows["S1#issue#1"]["refetch_sent"] is False and rows["S1#issue#1"]["rejudge_raw"] is None
    rs = [r for r in _pipeline_rows() if r["stage"] not in ("refetch-def", "rejudge-def")]
    rows = {r["id"]: r for r in replay.replay(cases, _keyed(cases, rs), 1)}
    assert rows["S1#issue#0"]["verdict"] == "verify_failed" and rows["S1#issue#1"]["verdict"] == "unsupported"


def test_def_output_ignores_other_keys():
    """앞 단계 출력은 그 차례에 계산한 key 가 같은 줄만 쓴다. 정의나 입력이 다른 옛 줄은 섞이지 않는다."""
    cases = _def_case()
    rs = _keyed(cases, _pipeline_rows()[:3])
    assert run.def_output(cases, rs, "judge-def", OM, 1, "batch:1") == JUDGE_ROW
    rs[2]["key"] = "stale0000000000"
    assert run.def_output(cases, rs, "judge-def", OM, 1, "batch:1") is None
    assert run.def_output(cases, rs, "extract-def", HH, 1, "https://a") == EXTRACT_OUT


def _write(path, obj, lines=False):
    import json
    with open(path, "w", encoding="utf-8") as f:
        if lines:
            f.write("".join(json.dumps(r, ensure_ascii=False) + "\n" for r in obj))
        else:
            json.dump(obj, f, ensure_ascii=False)


def _v4_cases():
    return {"items": [
        {"id": "d1", "category": "direction", "url": "u1", "claim": {"ref": "d1", "text": "t1"}, "truth": True, "check_note": "n"},
        {"id": "d2", "category": "direction", "url": "u1", "claim": {"ref": "d2", "text": "t2"}, "truth": False, "check_note": "n"}],
        "map_cases": []}


def _v4_files(d, truth_d1=True, def_rows=None, replay_rows=None):
    """report-v4 의 입력 파일을 만든다. 기준선은 두 실행 모두 d1 supported·d2 unsupported 다."""
    import copy
    import score
    cases = _v4_cases()
    base = []
    for rep in (1, 2):
        r = _run("baseline-cite", "claude-opus-5-5", "medium", "u1",
                 [{"ref": "d1", "verdict": "supported"}, {"ref": "d2", "verdict": "unsupported"}], repeat=rep, cost=1.0)
        r["key"] = score.expected_key(cases, r, {})
        base.append(r)
    scored = copy.deepcopy(cases)
    scored["items"][0]["truth"] = truth_d1
    p = {k: os.path.join(d, k) for k in ("cases.json", "base-cases.json", "base.jsonl", "def.jsonl", "replay.json", "report.md")}
    _write(p["cases.json"], scored)
    _write(p["base-cases.json"], cases)
    _write(p["base.jsonl"], base, lines=True)
    _write(p["def.jsonl"], def_rows or [_def_row("judge-def", OP, "medium", "batch:1", {"judgments": []}, repeat=rep) for rep in (1, 2)],
           lines=True)
    _write(p["replay.json"], replay_rows or [
        {"id": "d1", "repeat": 1, "verdict": "supported"}, {"id": "d1", "repeat": 2, "verdict": "unsupported"},
        {"id": "d2", "repeat": 1, "verdict": "unsupported"}, {"id": "d2", "repeat": 2, "verdict": "unsupported"}])
    return p


def _report_v4(p):
    import score
    score.report_v4(p["base.jsonl"], p["def.jsonl"], p["replay.json"], p["cases.json"], p["report.md"], p["base-cases.json"], None)
    with open(p["report.md"], encoding="utf-8") as f:
        return f.read()


def test_report_v4_uses_given_cases_and_baseline():
    """병합 조건을 인자로 준 자료와 기준선 파일로 계산한다."""
    import tempfile
    with tempfile.TemporaryDirectory() as d:
        text = _report_v4(_v4_files(d))
        assert "비용 조건을 충족했고, 항목 조건을 채우지 못했다" in text and "| d1 |" in text
    # 채점 자료에서 d1 이 오류 항목이면 기준선이 두 실행 모두 틀려 비교에서 빠지고 항목 조건을 채운다.
    with tempfile.TemporaryDirectory() as d:
        text = _report_v4(_v4_files(d, truth_d1=False))
        assert "항목 조건을 충족했다" in text and "빠진 항목·칸 1개(d1)" in text


def _section(text, title):
    s = text[text.index("## " + title):]
    nxt = s.find("\n## ", 1)
    return s if nxt == -1 else s[:nxt]


def test_report_v4_items():
    """판정 누락 수, 참·오류로 나눈 판정 불가 기각 수, 묶음별 크기와 출력 토큰이 보고에 있다."""
    import tempfile
    import replay
    cases = _v4_cases()
    ext = {"url": "u1", "principles_applied": [], "judgments": [
        {"ref": i, "access": "성공", "exists": "일치", "quote": "q", "context": "", "reason": "r"} for i in ("d1", "d2")]}
    # d1 은 범위 판정 불가로 기각되고(참 항목), d2 는 판정 출력에 없다(판정 누락).
    rows = _keyed(cases, [_def_row("extract-def", H, "high", "u1", ext),
                          _def_row("judge-def", OP, "medium", "batch:1", {"principles_applied": [], "judgments": [
                              _jd("c1", "u1", sc="판정 불가", unsure={"scope": "언어 해석"})]}, usage={"output_tokens": 1234})])
    rp = replay.replay(cases, rows, 2)
    with tempfile.TemporaryDirectory() as d:
        text = _report_v4(_v4_files(d, def_rows=rows, replay_rows=rp))
    for title in ("병합 조건", "기준선이 맞힌 항목 중 새 구성이 틀린 항목", "카테고리별 오류 통과와 참 기각", "판정 누락",
                  "판정 불가로 기각한 주장", "틀리게 확신함", "보충 비율과 결과", "묶음별 주장 수와 출력 토큰", "단계별 비용"):
        assert "## " + title in text, title
    assert "| 1 | 1 | 0 | d2 |" in _section(text, "판정 누락")
    assert "| 1 | 1 | 0 | d1 |" in _section(text, "판정 불가로 기각한 주장")
    assert "| judge-def | 1 | batch:1 | 1 | 2 | 1234 | 1 | 0 |" in _section(text, "묶음별 주장 수와 출력 토큰")
    # 틀린 항목 표는 실행마다 처음 판정 입력의 구절이 같은지 적는다. d1 은 실행 2 에 판정 입력이 없다.
    assert "| 실행 2 에 없음 |" in _section(text, "기준선이 맞힌 항목 중 새 구성이 틀린 항목")


def test_judge_quote_diff():
    """처음 판정 입력의 구절이 실행마다 같은지를 같음·다름·실행 k 에 없음으로 낸다."""
    import score
    assert score.quote_diff(["a", "a"]) == "같음" and score.quote_diff(["a", "b"]) == "다름"
    assert score.quote_diff(["a", None]) == "실행 2 에 없음"


def test_confident_wrong_counted():
    import score
    sure = {"numbers_conditions": "일치", "direction": "일치", "scope": "일치"}
    assert score.confident_wrong(sure, False) is True
    assert score.confident_wrong(sure, True) is False
    assert score.confident_wrong(dict(sure, scope="불일치"), True) is True
    assert score.confident_wrong(dict(sure, scope="판정 불가"), False) is False
    assert score.confident_wrong(None, False) is False


def test_merge_condition_item_level():
    import score
    base = {"a": [True, True], "b": [True, False], "c": [True, True]}
    ok, failing = score.merge_item_condition(base, {"a": [True, False], "b": [False, False], "c": [True, True]})
    assert ok is False and failing == ["a"]
    ok, failing = score.merge_item_condition(base, {"a": [True, True], "b": [False, False], "c": [True, True]})
    assert ok is True and failing == []


if __name__ == "__main__":
    try:
        globals()[sys.argv[1]]()
    except AssertionError:
        sys.exit(1)
