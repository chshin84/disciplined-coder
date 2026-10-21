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


if __name__ == "__main__":
    try:
        globals()[sys.argv[1]]()
    except AssertionError:
        sys.exit(1)
