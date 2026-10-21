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


# --- 구성 전체 재측정(-def 단계, replay.py, report-v2·report-v3) 검사.
def _harn_run(inp):
    import subprocess
    import json
    p = subprocess.run(["node", os.path.join(run.ROOT, "scripts", "workflow_harness.mjs"), "run"],
                       input=json.dumps(inp, ensure_ascii=False), capture_output=True, text=True, encoding="utf-8")
    assert p.returncode == 0, p.stderr
    return json.loads(p.stdout)


def _def_case():
    """주장 둘이 한 URL 에 걸린 재측정 자료다. ref 는 워크플로가 만드는 이름과 같게 둔다."""
    return {"items": [
        {"id": "S1#issue#0", "category": "direction", "url": "https://a", "claim": {"ref": "x", "text": "주장 A"}, "truth": True, "check_note": "n"},
        {"id": "S1#issue#1", "category": "scope", "url": "https://a", "claim": {"ref": "y", "text": "주장 \"B\""}, "truth": False, "check_note": "n"}],
        "map_cases": []}


def _def_row(stage, model, effort, unit, output, repeat=1):
    return {"key": "", "stage": stage, "model": model, "effort": effort, "category": "",
            "repeat": repeat, "unit": unit, "output": output, "cost_usd": 0.01, "error": ""}


def _keyed(cases, rows):
    """가짜 -def 줄에 run.py 가 그 차례에 계산했을 key 를 앞 줄부터 차례로 넣는다."""
    done = []
    for r in rows:
        r["key"] = run.def_key(cases, done, r["stage"], f"{r['model']}/{r['effort']}", r["repeat"], r["unit"])
        done.append(r)
    return rows


H, OP = "claude-haiku-5-5", "claude-opus-5-5"
EXTRACT_OUT = {"url": "https://a", "principles_applied": [], "judgments": [
    {"ref": "S1#issue#0", "access": "성공", "exists": "일치", "exists_note": "n0", "quote": "q0", "context": "c0", "reason": "r"},
    {"ref": "S1#issue#1", "access": "성공", "exists": "일치", "quote": "q1", "reason": "r"}]}
# 주장 0 은 정보 부족이라 보충·재판정을 거쳐 판정 불가로 상향되고, 주장 1 은 처음 판정에서 바로 상향된다.
JUDGE_OUT = {"principles_applied": [], "judgments": [
    {"ref": "S1#issue#0", "numbers_conditions": "정보 부족", "direction": "일치", "scope": "일치",
     "missing": {"numbers_conditions": "세션 수"}, "unsure_reasons": {}, "reason": "r"},
    {"ref": "S1#issue#1", "numbers_conditions": "일치", "direction": "판정 불가", "scope": "일치", "missing": {},
     "unsure_reasons": {"direction": "언어 해석"}, "reason": "r"}]}
REFETCH_OUT = {"url": "https://a", "principles_applied": [], "judgments": [
    {"ref": "S1#issue#0", "access": "성공", "exists": "일치", "exists_note": "n0b", "quote": "q0b", "context": "c0b", "reason": "r"}]}
REJUDGE_OUT = {"principles_applied": [], "judgments": [
    {"ref": "S1#issue#0", "numbers_conditions": "일치", "direction": "판정 불가", "scope": "일치", "missing": {},
     "unsure_reasons": {"direction": "조건 얽힘"}, "reason": "r"}]}
ESC_OUT = {"principles_applied": [], "judgments": [
    {"ref": "S1#issue#0", "numbers_conditions": "일치", "direction": "일치", "scope": "일치", "missing": {}, "unsure_reasons": {}, "reason": "r"},
    {"ref": "S1#issue#1", "numbers_conditions": "일치", "direction": "불일치", "scope": "일치", "missing": {}, "unsure_reasons": {}, "reason": "r"}]}


def _pipeline_rows():
    import copy
    return copy.deepcopy([
        _def_row("extract-def", H, "high", "https://a", EXTRACT_OUT), _def_row("judge-def", H, "high", "https://a", JUDGE_OUT),
        _def_row("refetch-def", H, "high", "https://a", REFETCH_OUT), _def_row("rejudge-def", H, "high", "https://a", REJUDGE_OUT),
        _def_row("escalate-def", OP, "medium", "https://a", ESC_OUT)])


def _agent_body(agent_type):
    """agentType 이 가리키는 정의 파일에서 frontmatter 를 뗀 본문이다. 운영의 system 프롬프트에 들어가는 지시문이다."""
    with open(os.path.join(run.ROOT, "agents", agent_type.split(":")[1] + ".md"), encoding="utf-8") as f:
        text = f.read()
    return text[text.index("\n---", 3) + 4:].lstrip("\n")


def test_def_prompt_matches_workflow():
    """harn run 이 기록한 extract:·judge:·refetch:·rejudge:·escalate:·map-check 호출이 run.py -def 단계와 같다.
    사용자 메시지는 프롬프트로, system 프롬프트는 agentType 의 정의 본문으로 대조한다."""
    row = {"case": "사례 B", "url": "https://b", "outcome": "실패",
           "axes": {k: {"prior": f"{k} 서술", "same": True, "note": ""} for k in ("purpose", "mechanism", "evaluation", "target")}}
    args = {"question": "Q?", "situation": "S", "target": "T", "mode": "survey", "round": 1,
            "subquestions": [{"id": "S1", "scope": "a", "include": [], "exclude": []}], "forbidden_terms": [],
            "researcher_count": 1, "researcher_count_basis": "x", "principles_path": run.PRINCIPLES}
    b_ok = {"url": "https://b", "principles_applied": [], "judgments": [
        {"ref": "S1#case#0", "access": "성공", "exists": "일치", "exists_note": "nb", "quote": "qb", "context": "", "reason": "r"}]}
    b_judge = {"principles_applied": [], "judgments": [
        {"ref": "S1#case#0", "numbers_conditions": "일치", "direction": "일치", "scope": "일치", "missing": {}, "unsure_reasons": {}, "reason": "r"}]}
    synthesis = {"evidence_map": [row], "conclusions": [], "principles_applied": []}
    map_out = {"cells": [], "principles_applied": []}
    responses = {"research:S1": {"search_status": "ok", "queries": ["q"], "issues": [
        {"prior_claim": "주장 A", "citations": [{"url": "https://a"}]},
        {"prior_claim": "주장 \"B\"", "citations": [{"url": "https://a"}]}], "evidence_map": [row]},
        "extract:https://a": EXTRACT_OUT, "judge:https://a": JUDGE_OUT, "refetch:https://a": REFETCH_OUT,
        "rejudge:https://a": REJUDGE_OUT, "escalate:https://a": ESC_OUT,
        "extract:https://b": b_ok, "judge:https://b": b_judge, "synthesize": synthesis, "map-check": map_out}
    calls = {c["label"]: c for c in _harn_run({"args": args, "responses": responses})["calls"]}
    cases = _def_case()
    cases["map_cases"] = [{"id": "map-1", "input": {"evidence_map": [row], "passed": [{"ref": "S1#case#0", "row": row}]}, "truth": []}]
    runs = _keyed(cases, _pipeline_rows())
    pairs = {"extract-def": "extract:https://a", "judge-def": "judge:https://a", "refetch-def": "refetch:https://a",
             "rejudge-def": "rejudge:https://a", "escalate-def": "escalate:https://a", "map-def": "map-check"}
    for stage, label in pairs.items():
        unit = "map-1" if stage == "map-def" else "https://a"
        us = dict(run.def_units(cases, stage, runs, 1, H + "/high", False))
        user, system = run.def_prompt(stage, us[unit]), run.def_system(stage)
        assert user == calls[label]["prompt"], stage
        assert system == _agent_body(calls[label]["agentType"]), stage
        cmd = run.build_cmd(stage, "m", "high", user, system)
        assert cmd[cmd.index("-p") + 1] == user and cmd[cmd.index("--system-prompt") + 1] == system, stage


def test_escalate_input_uses_rejudge():
    """재판정을 거친 주장의 상향 입력은 재판정 입력과 같고, 거치지 않은 주장은 처음 판정 입력과 같다."""
    cases = _def_case()
    runs = _keyed(cases, _pipeline_rows())

    def claims(stage):
        return {c["ref"]: c for c in dict(run.def_units(cases, stage, runs, 1, H + "/high", False))["https://a"]["claims"]}
    esc, rj, ju = claims("escalate-def"), claims("rejudge-def"), claims("judge-def")
    assert esc["S1#issue#0"] == rj["S1#issue#0"] and esc["S1#issue#0"]["quote"] == "q0b" and esc["S1#issue#0"]["source_note"] == "n0b"
    assert esc["S1#issue#1"] == ju["S1#issue#1"] and ju["S1#issue#1"]["source_note"] == ""
    assert ju["S1#issue#0"]["source_note"] == "n0"


def test_replay_uses_workflow_merge():
    """가짜 단계 출력으로 replay 가 mergeStages·classify 의 판정을 그대로 옮긴다."""
    import replay
    cases = _def_case()
    rows = {r["id"]: r for r in replay.replay(cases, _keyed(cases, _pipeline_rows()), 1)}
    assert rows["S1#issue#0"]["verdict"] == "supported" and rows["S1#issue#0"]["escalated"] is True
    assert rows["S1#issue#1"]["verdict"] == "unsupported" and rows["S1#issue#1"]["escalated"] is True
    assert rows["S1#issue#1"]["judge_raw"]["direction"] == "판정 불가"
    # 상향 판정도 판정 불가면 그 주장만 verify_failed 이고 다른 주장은 남는다.
    rs = _pipeline_rows()
    rs[4]["output"] = {"principles_applied": [], "judgments": [ESC_OUT["judgments"][0], dict(ESC_OUT["judgments"][1], direction="판정 불가")]}
    rows = {r["id"]: r for r in replay.replay(cases, _keyed(cases, rs), 1)}
    assert rows["S1#issue#1"]["verdict"] == "verify_failed" and rows["S1#issue#0"]["verdict"] == "supported"
    # 상향 판정 실행이 없으면 그 URL 전체가 검증 실패다.
    rows = {r["id"]: r for r in replay.replay(cases, _keyed(cases, _pipeline_rows()[:4]), 1)}
    assert rows["S1#issue#0"]["verdict"] == "verify_failed" and rows["S1#issue#1"]["verdict"] == "verify_failed"


def test_replay_passes_refetch_and_rejudge():
    """replay 가 보충·재판정 출력을 mergeStages 의 새 인자로 넘긴다. 빠지면 보충에 보낸 주장만 검증 실패다."""
    import replay
    cases = _def_case()
    rows = {r["id"]: r for r in replay.replay(cases, _keyed(cases, _pipeline_rows()), 1)}
    r0 = rows["S1#issue#0"]
    assert r0["refetch_sent"] is True and r0["refetch_raw"]["quote"] == "q0b" and r0["rejudge_raw"]["direction"] == "판정 불가"
    assert r0["escalate_raw"]["direction"] == "일치"
    assert rows["S1#issue#1"]["refetch_sent"] is False and rows["S1#issue#1"]["rejudge_raw"] is None
    # 보충 출력이 없으면 주장 0 만 verify_failed 이고, 주장 1 은 상향 판정대로 unsupported 다.
    rs = [r for r in _pipeline_rows() if r["stage"] not in ("refetch-def", "rejudge-def")]
    rs[-1]["output"] = {"principles_applied": [], "judgments": [ESC_OUT["judgments"][1]]}
    rows = {r["id"]: r for r in replay.replay(cases, _keyed(cases, rs), 1)}
    assert rows["S1#issue#0"]["verdict"] == "verify_failed" and rows["S1#issue#1"]["verdict"] == "unsupported"


def test_def_output_ignores_other_keys():
    """앞 단계 출력은 그 차례에 계산한 key 가 같은 줄만 쓴다. 정의나 입력이 다른 옛 줄은 섞이지 않는다."""
    cases = _def_case()
    rs = _keyed(cases, _pipeline_rows()[:2])
    rs[1]["key"] = "stale0000000000"
    assert run.def_output(cases, rs, "judge-def", H + "/high", 1, "https://a") is None
    assert run.def_output(cases, rs, "extract-def", H + "/high", 1, "https://a") == EXTRACT_OUT


def _write(path, obj, lines=False):
    import json
    with open(path, "w", encoding="utf-8") as f:
        if lines:
            f.write("".join(json.dumps(r, ensure_ascii=False) + "\n" for r in obj))
        else:
            json.dump(obj, f, ensure_ascii=False)


def _v3_files(d, truth_d1=True, replay_rows=None):
    """report-v3 의 입력 파일을 만든다. 기준선은 두 실행 모두 d1 supported·d2 unsupported 다."""
    import copy
    import score
    cases = {"items": [
        {"id": "d1", "category": "direction", "url": "u1", "claim": {"ref": "d1", "text": "t1"}, "truth": True, "check_note": "n"},
        {"id": "d2", "category": "direction", "url": "u1", "claim": {"ref": "d2", "text": "t2"}, "truth": False, "check_note": "n"}],
        "map_cases": []}
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
    _write(p["def.jsonl"], [_def_row("judge-def", H, "high", "u1", {"judgments": []}, repeat=rep) for rep in (1, 2)], lines=True)
    _write(p["replay.json"], replay_rows or [
        {"id": "d1", "repeat": 1, "verdict": "supported"}, {"id": "d1", "repeat": 2, "verdict": "unsupported"},
        {"id": "d2", "repeat": 1, "verdict": "unsupported"}, {"id": "d2", "repeat": 2, "verdict": "unsupported"}])
    return p


def _report_v3(p):
    import score
    score.report_v3(p["base.jsonl"], p["def.jsonl"], p["replay.json"], p["cases.json"], p["report.md"], p["base-cases.json"], None)
    with open(p["report.md"], encoding="utf-8") as f:
        return f.read()


def test_report_v3_uses_given_cases_and_baseline():
    """병합 조건을 인자로 준 자료와 기준선 파일로 계산한다."""
    import tempfile
    with tempfile.TemporaryDirectory() as d:
        text = _report_v3(_v3_files(d))
        assert "비용 조건을 충족했고, 항목 조건을 채우지 못했다" in text and "| d1 |" in text
    # 채점 자료에서 d1 이 오류 항목이면 기준선이 두 실행 모두 틀려 비교에서 빠지고 항목 조건을 채운다.
    with tempfile.TemporaryDirectory() as d:
        text = _report_v3(_v3_files(d, truth_d1=False))
        assert "항목 조건을 충족했다" in text and "빠진 항목·칸 1개(d1)" in text


def test_report_v3_lists_remaining_unsure():
    """재판정 뒤 남은 정보 부족과 상향 뒤 남은 판정 불가가 missing·이유 유형·사유 문장과 함께 보고에 있다."""
    import tempfile
    sure = {"numbers_conditions": "일치", "direction": "일치", "scope": "일치", "missing": {}, "unsure_reasons": {}}
    rows = [
        {"id": "d1", "repeat": 1, "verdict": "verify_failed", "refetch_sent": True, "escalate_sent": False,
         "judge_raw": dict(sure, numbers_conditions="정보 부족", missing={"numbers_conditions": "세션 수"}, reason="처음 사유"),
         "refetch_raw": {"access": "성공", "exists": "일치", "quote": "q"},
         "rejudge_raw": dict(sure, numbers_conditions="정보 부족", missing={"numbers_conditions": "세션 수"}, reason="세션 수가 구절에 없다"),
         "escalate_raw": None, "escalated": False},
        {"id": "d1", "repeat": 2, "verdict": "supported"},
        {"id": "d2", "repeat": 1, "verdict": "verify_failed", "refetch_sent": False, "escalate_sent": True,
         "judge_raw": dict(sure, direction="판정 불가", unsure_reasons={"direction": "조건 얽힘"}, reason="r"),
         "refetch_raw": None, "rejudge_raw": None,
         "escalate_raw": dict(sure, direction="판정 불가", unsure_reasons={"direction": "언어 해석"}, reason="구절이 두 뜻으로 읽힌다"),
         "escalated": True},
        {"id": "d2", "repeat": 2, "verdict": "unsupported"}]
    with tempfile.TemporaryDirectory() as d:
        text = _report_v3(_v3_files(d, replay_rows=rows))
    remain = text[text.index("## 남은 정보 부족과 판정 불가"):]
    remain = remain[:remain.index("\n## ", 1)]
    assert "| d1 | 1 | 재판정 | numbers_conditions | 정보 부족 | 세션 수 | 세션 수가 구절에 없다 |" in remain
    assert "| d2 | 1 | 상향 | direction | 판정 불가 | 언어 해석 | 구절이 두 뜻으로 읽힌다 |" in remain


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
