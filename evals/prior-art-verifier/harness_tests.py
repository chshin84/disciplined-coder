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


def _run(stage, model, effort, unit, judgments, repeat=1, category="direction", cost=0.01, cells=None):
    out = {"cells": cells} if cells is not None else {"judgments": judgments}
    return {"key": f"{stage}{model}{effort}{unit}{repeat}", "stage": stage, "model": model, "effort": effort,
            "category": category, "repeat": repeat, "unit": unit, "output": out, "cost_usd": cost, "error": ""}


def test_missing_judgment_is_failure():
    import score
    runs = [_run("judge", "h", "low", "u1", [{"ref": "d1", "match": "일치"}])]
    s = score.score(_cases(), runs, "judge", "direction", frozen={("u1", "d1"): {"quote": "q"}, ("u1", "d2"): {"quote": "q"}})
    r = s["h/low"][0]
    assert r["failures"] == 1 and r["missed_errors"] == 0 and r["rejected_truths"] == 0


def test_no_quote_excluded():
    import score
    runs = [_run("judge", "h", "low", "u1", [{"ref": "d1", "match": "일치"}])]
    s = score.score(_cases(), runs, "judge", "direction", frozen={("u1", "d1"): {"quote": "q"}, ("u1", "d2"): {"quote": ""}})
    r = s["h/low"][0]
    assert r["failures"] == 0 and r["excluded"] == ["d2"]


def test_unverifiable_counts_as_rejection():
    import score
    runs = [_run("baseline-cite", "o", "medium", "u1", [{"ref": "d1", "verdict": "unverifiable"}, {"ref": "d2", "verdict": "unsupported"}])]
    r = score.score(_cases(), runs, "baseline-cite", "direction")["o/medium"][0]
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
    r = score.score(_cases(), [_run("map", "h", "low", "map-1", None, category="", cells=cells)], "map", "map")["h/low"][0]
    assert r["missed_errors"] == 1 and r["rejected_truths"] == 0


if __name__ == "__main__":
    try:
        globals()[sys.argv[1]]()
    except AssertionError:
        sys.exit(1)
