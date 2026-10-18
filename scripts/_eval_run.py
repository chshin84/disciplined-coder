"""평가 과제를 claude -p 로 실행하고 판정 모델로 판정해 result.json 을 쓴다. eval_principles.sh 가 부른다.

생성 세션은 호출자가 준 CLAUDE_CONFIG_DIR(그 조건의 플러그인이 설치된 평가 설정 폴더)로, 판정 세션은
--judge-cfg(플러그인이 없는 빈 설정 폴더)로 실행한다. 판정 세션에 원칙이 실리면 조건마다 판정자가 달라지기 때문이다.

사용: python _eval_run.py <과제 폴더> <태그> <작업 폴더> <판정 설정 폴더> <출력 JSON> <커밋> <적재 줄> <적재 글자>
"""
import concurrent.futures
import json
import os
import re
import runpy
import subprocess
import sys

RUNS = 3
JOBS = 4
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


def claude_json(prompt, cwd, env, model=None):
    cmd = ["claude", "-p", prompt, "--tools", "", "--output-format", "json"]
    if model:
        cmd += ["--model", model]
    p = subprocess.run(cmd, cwd=cwd, env=env, capture_output=True, text=True, encoding="utf-8", timeout=600)
    try:
        return json.loads(p.stdout)
    except ValueError:
        return {"result": "", "error": (p.stdout + p.stderr)[-500:]}


def one(case, c, run, cwd, judge_env):
    g = claude_json(c["prompt"], cwd, dict(os.environ))
    response = g.get("result", "")
    model = ",".join(sorted((g.get("modelUsage") or {}).keys()))
    j = claude_json(JUDGE_PROMPT.format(prompt=c["prompt"], criteria=c["criteria"], response=response),
                    cwd, judge_env, JUDGE_MODEL)
    parsed = parse_judge(j.get("result", ""))
    if parsed is None:
        # 판정을 읽지 못한 회차는 위반으로 세지 않고 표시만 남긴다. 측정 기록에서 건수를 본다.
        violated, note = False, "판정 읽기 실패: " + j.get("result", j.get("error", ""))[:200]
    else:
        violated, note = parsed
    judge_model = ",".join(sorted((j.get("modelUsage") or {}).keys()))
    return {"case": case, "run": run, "violated": violated, "response": response, "judge_note": note,
            "error": g.get("error", ""), "model": model, "judge_model": judge_model}


def main(argv):
    cases_dir, tag, cwd, judge_cfg, out, commit, lines, chars = argv[1:9]
    lib = runpy.run_path(os.path.join(os.path.dirname(os.path.abspath(__file__)), "_eval_lib.py"))
    cases = {n: c for n, c in lib["load_cases"](cases_dir).items() if tag in (c["meta"].get("tags") or [])}
    judge_env = dict(os.environ, CLAUDE_CONFIG_DIR=judge_cfg)
    jobs = [(n, c, r) for n, c in sorted(cases.items()) for r in range(1, RUNS + 1)]
    with concurrent.futures.ThreadPoolExecutor(JOBS) as ex:
        runs = list(ex.map(lambda a: one(a[0], a[1], a[2], cwd, judge_env), jobs))
    models = sorted({r["model"] for r in runs if r["model"]})
    judges = sorted({r["judge_model"] for r in runs if r["judge_model"]})
    res = {"commit": commit, "tag": tag, "model": ",".join(models), "judge_model": ",".join(judges),
           "loaded_lines": int(lines), "loaded_chars": int(chars), "runs": runs}
    os.makedirs(os.path.dirname(out), exist_ok=True)
    json.dump(res, open(out, "w", encoding="utf-8"), ensure_ascii=False, indent=1)
    bad = sum(1 for r in runs if r["error"] or r["judge_note"].startswith("판정 읽기 실패"))
    print(f"runs={len(runs)} violated={sum(r['violated'] for r in runs)} errors={bad}")


if __name__ == "__main__":
    main(sys.argv)
