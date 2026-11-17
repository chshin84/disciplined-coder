"""_replay.py 와 _judge.py 를 픽스처로 시험한다. 소비자는 test_replay.sh 다.
claude 실행은 가짜 함수로 바꾸므로 생성·판정 비용이 들지 않는다. 결과 폴더와 임시 폴더는 인자로 받은 임시 폴더
아래에 둔다(DC_EVAL_HOME·EVAL_TMP). 한 줄에 'OK <이름>' 이나 'NG <이름>' 을 내고, 끝까지 실행되면 마지막 줄에
'DONE' 을 낸다. 모듈을 읽지 못하면 검사마다 NG 를 낸다.

사용: python _test_replay.py <scripts 폴더> <임시 폴더>
"""
import contextlib
import datetime
import io
import json
import os
import sys
import traceback

scripts, tmp = sys.argv[1], sys.argv[2]
DC = os.path.join(tmp, "dc-eval")
ETMP = os.path.join(tmp, "eval-tmp")
os.environ.update(DC_EVAL_HOME=DC, EVAL_TMP=ETMP, MEM_MIN_GB="0", PAR="1")
sys.path.insert(0, scripts)

NAMES = {
    "model": "생성·판정 모델이 claude-opus-5-5 가 아니면 중단한다",
    "skip": "같은 턴·조건 답이 있으면 다시 생성하지 않는다",
    "cls": "판정 분류 경계",
    "cfg": "생성 설정 폴더가 실제 ~/.claude 와 분리된다",
    "bg": "생성 환경에 백그라운드 대기 상한 0 이 들어간다",
    "parse": "판정 응답 JSON 을 읽는다",
    "backup": "원본이 없으면 세션 사본을 읽는다",
    "office": "평일 업무 시간에는 --now 없이 생성하지 않는다",
    "banned": "금지어는 횟수로 세고 제외어는 뺀다",
}


def say(key, ok):
    print(("OK " if ok else "NG ") + NAMES[key], flush=True)


try:
    import _replay as R  # noqa: E402
    import _judge as J  # noqa: E402
except Exception:
    traceback.print_exc(limit=1, file=sys.stdout)
    for k in NAMES:
        say(k, False)
    print("DONE")
    sys.exit(0)


def jl(path, rows):
    os.makedirs(os.path.dirname(path), exist_ok=True)
    with open(path, "w", encoding="utf-8") as f:
        for r in rows:
            f.write(json.dumps(r, ensure_ascii=False) + "\n")


# 세션 픽스처: 질문 하나 → 답 하나 → 질문 둘(재현할 메시지) → 옛 답 → 지적. 원본 경로에는 파일이 없고 사본만 있다.
SESS = [
    {"type": "user", "uuid": "u1", "parentUuid": None, "message": {"role": "user", "content": "첫 질문"}},
    {"type": "assistant", "uuid": "a1", "parentUuid": "u1", "message": {"role": "assistant", "content": [{"type": "text", "text": "첫 답"}]}},
    {"type": "user", "uuid": "u2", "parentUuid": "a1", "message": {"role": "user", "content": "두 번째 질문"}},
    {"type": "assistant", "uuid": "a2", "parentUuid": "u2", "message": {"role": "assistant", "content": [{"type": "text", "text": "옛 답"}]}},
    {"type": "user", "uuid": "u3", "parentUuid": "a2", "message": {"role": "user", "content": "지적"}},
]
ORIG = os.path.join(tmp, "orig", "proj-x", "s1.jsonl").replace("\\", "/")
jl(os.path.join(DC, "replay", "sessions-backup", "proj-x", "s1.jsonl"), SESS)
TURN = {"idx": 1, "kind": "지적", "session_file": ORIG, "correction_uuid": "u3", "cwd": tmp, "ts": "2026-11-01T00:00:00Z",
        "user": "지적", "why": "요지", "decision_point": "전제 사용", "clauses": "[]"}
jl(os.path.join(DC, "replay", "turns", "turns-fx.jsonl"), [TURN])
LIST = os.path.join(tmp, "turns-fx.txt")
open(LIST, "w", encoding="utf-8").write("1\n")

CALLS = []


def fake(models, result="새 답"):
    def call(args, prompt, cwd, env, timeout):
        CALLS.append({"args": args, "cwd": cwd, "env": env})
        return json.dumps({"result": result, "is_error": False, "modelUsage": {m: {} for m in models}, "num_turns": 1})
    return call


R.token = lambda: "fixture-token"


def check(key, fn):
    try:
        say(key, bool(fn()))
    except Exception:
        traceback.print_exc(limit=2, file=sys.stdout)
        say(key, False)


OUT = os.path.join(tmp, "answers")
os.makedirs(OUT, exist_ok=True)
REAL_CLAUDE = os.path.normcase(os.path.join(os.path.expanduser("~"), ".claude"))


def t_backup():
    return (os.path.normcase(R.session_path(TURN)) == os.path.normcase(os.path.join(DC, "replay", "sessions-backup", "proj-x", "s1.jsonl"))
            and R.conversation(R.session_path(TURN), "u3")[1] == "두 번째 질문")


def t_model():
    R.call_claude = fake(["claude-sonnet-x"])
    stopped = False
    try:
        R.run(TURN, OUT, "v1", "rev", "지시", "리마인더")
    except R.ModelError:
        stopped = True
    gen_ok = stopped and not os.path.exists(os.path.join(OUT, "v1-1.json"))
    R.call_claude = fake(["claude-opus-5-5", "claude-sonnet-x"])
    jstop = False
    try:
        J.ask("판정 질문")
    except R.ModelError:
        jstop = True
    return gen_ok and jstop


def t_cfg():
    CALLS.clear()
    R.call_claude = fake(["claude-opus-5-5"])
    R.run(TURN, OUT, "v1", "rev", "지시", "리마인더")
    env, cwd = CALLS[-1]["env"], CALLS[-1]["cwd"]
    cfg = os.path.normcase(os.path.abspath(env["CLAUDE_CONFIG_DIR"]))
    return (os.path.exists(os.path.join(OUT, "v1-1.json"))
            and cfg.startswith(os.path.normcase(os.path.abspath(ETMP)))
            and not cfg.startswith(REAL_CLAUDE)
            and os.path.normcase(os.path.abspath(cwd)).startswith(os.path.normcase(os.path.abspath(ETMP))))


def t_bg():
    return CALLS and CALLS[-1]["env"].get("CLAUDE_CODE_PRINT_BG_WAIT_CEILING_MS") == "0"


def t_skip():
    n = len(CALLS)
    r = R.run(TURN, OUT, "v1", "rev", "지시", "리마인더")
    return len(CALLS) == n and "skip" in r


def t_cls():
    want = {(1, 1): "개선", (1, 0): "개선", (0, 0): "같음", (2, -1): "같음", (-1, 0): "악화", (-1, -1): "악화", (1, -1): "같음"}
    return all(J.classify(*k) == v for k, v in want.items())


def t_parse():
    a = J.parse_reply('판정입니다. {"score": 1, "note": "x"} 끝')
    b = J.parse_reply("모르겠습니다")
    A = {"kind": "지적", "rev": "r1"}
    no_score = J.result(A, A, {"note": "점수 없음"}, {"score": 0})
    ok = J.result(A, A, {"score": 1}, {"score": -1})
    return (a.get("score") == 1 and "error" in b and "error" in no_score and "cls" not in no_score
            and ok.get("cls") == "개선" and ok.get("score") == 1)


def t_office():
    oh = R.office_hours
    hours = (oh(datetime.datetime(2026, 11, 17, 10, 0)) and oh(datetime.datetime(2026, 11, 17, 9, 0))
             and not oh(datetime.datetime(2026, 11, 17, 18, 0)) and not oh(datetime.datetime(2026, 11, 17, 8, 59))
             and not oh(datetime.datetime(2026, 11, 21, 10, 0)))
    R.now = lambda: datetime.datetime(2026, 11, 17, 10, 0)
    R.context = lambda cond: ("rev", "지시", "리마인더")
    R.call_claude = fake(["claude-opus-5-5"])
    out2 = os.path.join(tmp, "answers2")
    CALLS.clear()
    refused = jrefused = False
    with contextlib.redirect_stdout(io.StringIO()), contextlib.redirect_stderr(io.StringIO()):  # 안내 문구는 시험 출력에 내지 않는다
        try:
            R.main([out2, "v2.1", LIST])
        except SystemExit as e:
            refused = e.code not in (0, None)
        try:
            J.main(["judge", out2, os.path.join(tmp, "judge"), "v1", "v2.1", LIST])
        except SystemExit as e:
            jrefused = e.code not in (0, None)
        none_called = not CALLS
        rc = R.main([out2, "v2.1", LIST, "--now"])
    return hours and refused and jrefused and none_called and rc == 0 and os.path.exists(os.path.join(out2, "v2.1-1.json"))


def t_banned():
    rows, excls = [["판"]], [["판정"]]
    return J.count_banned("새 판을 낸다. 판정은 판에 따른다. `판` 은 세지 않는다.", rows, excls) == 2


check("backup", t_backup)
check("model", t_model)
check("cfg", t_cfg)
check("bg", t_bg)
check("skip", t_skip)
check("cls", t_cls)
check("parse", t_parse)
check("office", t_office)
check("banned", t_banned)
print("DONE")
