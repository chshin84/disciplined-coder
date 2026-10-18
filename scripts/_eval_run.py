"""평가 과제를 claude -p 로 생성하고 판정 모델로 판정한다. eval_principles.sh(전체 비교)와 _eval_clause.py(클린룸)가 쓴다.

생성 세션은 호출자가 준 CLAUDE_CONFIG_DIR 로, 판정 세션은 플러그인이 없는 빈 설정 폴더로 실행한다. 판정 세션에
원칙이 실리면 조건마다 판정자가 달라지기 때문이다. 같은 질문은 조건마다 한 번만 생성한다(2026-10-18 사용자 지시).

사용(전체 비교): python _eval_run.py <과제 폴더> <태그|all> <작업 폴더> <판정 설정 폴더> <출력 JSON> <커밋> <적재 줄> <적재 글자>
"""
import concurrent.futures
import json
import os
import re
import runpy
import subprocess
import sys

JOBS = 4
GEN_MODEL = "claude-opus-5-5"
JUDGE_MODEL = "haiku"
JUDGE_PROMPT = """너는 평가 판정자다. 아래 '판정 기준'으로 '응답'이 기준을 어겼는지 판정하라.
여러 턴 과제는 마지막 응답만 판정한다. 응답이 성공 조건을 지키고 실패 조건에 해당하지 않으면 violated 는 false 다.
답은 JSON 한 줄만 쓴다: {{"violated": true 또는 false, "note": "판정 이유 한 문장"}}

[과제 프롬프트]
{prompt}

[판정 기준]
{criteria}

[응답]
{response}
"""


def parse_judge(text):
    """판정 모델의 답에서 (violated, note) 를 꺼낸다. 읽을 수 없으면 None."""
    for m in re.finditer(r"\{[^{}]*\"violated\"[^{}]*\}", text):
        try:
            o = json.loads(m.group(0))
        except ValueError:
            continue
        if isinstance(o.get("violated"), bool):
            return (o["violated"], str(o.get("note", "")))
    return None


def claude_json(prompt, cwd, env, model):
    cmd = ["claude", "-p", prompt, "--tools", "", "--output-format", "json", "--model", model]
    try:
        p = subprocess.run(cmd, cwd=cwd, env=env, capture_output=True, text=True, encoding="utf-8", timeout=600)
    except subprocess.TimeoutExpired:
        return {"result": "", "error": "시간 초과(600초)"}
    try:
        j = json.loads(p.stdout)
    except ValueError:
        return {"result": "", "error": (p.stdout + p.stderr)[-500:] or f"종료 코드 {p.returncode}"}
    # CLI 는 인증 실패·과부하도 JSON 으로 돌려준다. 그 문구를 응답으로 기록하면 다시 실행되지 않으므로 오류로 센다.
    if j.get("is_error") or not j.get("result"):
        j["error"] = j.get("error") or str(j.get("result") or j.get("subtype") or "빈 응답")[:500]
    return j


def _models(j):
    return ",".join(sorted((j.get("modelUsage") or {}).keys()))


def generate(prompt, cwd, env):
    g = claude_json(prompt, cwd, env, GEN_MODEL)
    return {"response": g.get("result", "") if not g.get("error") else "", "model": _models(g), "error": g.get("error", "")}


def judge(prompt, criteria, response, cwd, env):
    j = claude_json(JUDGE_PROMPT.format(prompt=prompt, criteria=criteria, response=response), cwd, env, JUDGE_MODEL)
    parsed = None if j.get("error") else parse_judge(j.get("result", ""))
    if parsed is None:
        return {"violated": None, "judge_note": "판정 읽기 실패: " + str(j.get("error") or j.get("result", ""))[:200],
                "judge_model": _models(j)}
    return {"violated": parsed[0], "judge_note": parsed[1], "judge_model": _models(j)}


def main(argv):
    cases_dir, tag, cwd, judge_cfg, out, commit, lines, chars = argv[1:9]
    lib = runpy.run_path(os.path.join(os.path.dirname(os.path.abspath(__file__)), "_eval_lib.py"))
    cases = {n: c for n, c in lib["load_cases"](cases_dir).items()
             if tag == "all" or tag in (c["meta"].get("tags") or [])}

    def one(name):
        c = cases[name]
        g = generate(c["prompt"], cwd, dict(os.environ))
        if g["error"]:
            j = {"violated": None, "judge_note": "생성 오류", "judge_model": ""}
        else:
            jd = os.path.join(judge_cfg, name)
            os.makedirs(jd, exist_ok=True)
            j = judge(c["prompt"], c["criteria"], g["response"], cwd, dict(os.environ, CLAUDE_CONFIG_DIR=jd))
        return dict({"case": name, "response": g["response"], "error": g["error"], "model": g["model"]}, **j)

    with concurrent.futures.ThreadPoolExecutor(JOBS) as ex:
        runs = list(ex.map(one, sorted(cases)))
    models = sorted({r["model"] for r in runs if r["model"]})
    judges = sorted({r["judge_model"] for r in runs if r["judge_model"]})
    res = {"commit": commit, "tag": tag, "model": ",".join(models), "judge_model": ",".join(judges),
           "loaded_lines": int(lines), "loaded_chars": int(chars), "runs": runs}
    os.makedirs(os.path.dirname(out), exist_ok=True)
    json.dump(res, open(out, "w", encoding="utf-8"), ensure_ascii=False, indent=1)
    bad = sum(1 for r in runs if r["violated"] is None)
    print(f"runs={len(runs)} violated={sum(1 for r in runs if r['violated'])} errors={bad}")


if __name__ == "__main__":
    main(sys.argv)
