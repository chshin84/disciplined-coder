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


if __name__ == "__main__":
    try:
        globals()[sys.argv[1]]()
    except AssertionError:
        sys.exit(1)
