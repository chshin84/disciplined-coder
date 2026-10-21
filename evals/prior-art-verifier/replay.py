"""-def 단계 출력으로 구성 전체의 최종 판정을 만든다. 합치기는 워크플로의 mergeStages 와 classify 를 시험 도구로 실행해 얻는다.

항목마다 { id, repeat, verdict, judge_raw, escalated } 를 쓴다. judge_raw 는 상향 전 판정 에이전트의 판정 원본이고,
escalated 는 상향 판정 출력에 그 항목의 판정이 있는지다.
"""
import argparse
import json
import os
import subprocess
import sys

sys.path.insert(0, os.path.dirname(os.path.abspath(__file__)))
import run  # noqa: E402

HARNESS = os.path.join(run.ROOT, "scripts", "workflow_harness.mjs")
ESCALATION = "claude-sonnet-5-5/high"
# classify 의 행선지 목록을 최종 verdict 로 옮긴다. rejected 에는 unsupported 만 들어온다(선행 서술 결측은 자료에 없다).
DEST = {"passed": "supported", "rejected": "unsupported", "unverifiable": "unverifiable"}


def harn(name, args):
    p = subprocess.run(["node", HARNESS, "fn", name], input=json.dumps(args, ensure_ascii=False),
                       capture_output=True, text=True, encoding="utf-8")
    if p.returncode != 0:
        raise RuntimeError(f"harn fn {name} 실패: {p.stderr}")
    return json.loads(p.stdout)


def replay(cases, runs, repeat, upstream=run.UPSTREAM, escalation=ESCALATION):
    refs_by_url = {}
    for x in cases["items"]:
        refs_by_url.setdefault(x["url"], []).append(x["id"])
    out = []
    for rep in range(1, repeat + 1):
        stage_out = {}
        for stage, config in (("extract-def", upstream), ("judge-def", upstream), ("escalate-def", escalation)):
            stage_out[stage] = {}
            for u in refs_by_url:
                o = run.latest_output(runs, stage, config, rep, u)
                if o is not None:
                    stage_out[stage][u] = o
        merged = harn("mergeStages", [refs_by_url, stage_out["extract-def"], stage_out["judge-def"], stage_out["escalate-def"]])
        items = [{"ref": x["id"], "urls": [x["url"]], "text": x["claim"]["text"]} for x in cases["items"]]
        verifiers = [{"url": u, "output": merged["outputs"][u]} for u in refs_by_url]
        cl = harn("classify", [items, verifiers])
        verdict = {}
        for dest, v in DEST.items():
            for e in cl[dest]:
                verdict[e["ref"]] = v
        for f in cl["verify_failed"]:
            for ref in f["refs"]:
                verdict[ref] = "verify_failed"
        for x in cases["items"]:
            ju = run._by_ref([x["id"]], stage_out["judge-def"].get(x["url"]))
            es = run._by_ref([x["id"]], stage_out["escalate-def"].get(x["url"]))
            out.append({"id": x["id"], "repeat": rep, "verdict": verdict.get(x["id"]),
                        "judge_raw": ju[x["id"]] if ju else None, "escalated": es is not None})
    return out


def main(argv=None):
    ap = argparse.ArgumentParser()
    ap.add_argument("--cases", required=True)
    ap.add_argument("--runs", required=True)
    ap.add_argument("--repeat", type=int, required=True)
    ap.add_argument("--out", required=True)
    a = ap.parse_args(argv)
    with open(a.cases, encoding="utf-8") as f:
        cases = json.load(f)
    rows = replay(cases, run.read_runs(a.runs), a.repeat)
    with open(a.out, "w", encoding="utf-8") as f:
        json.dump(rows, f, ensure_ascii=False, indent=1)
    print(f"{a.out}: {len(rows)}줄")
    return 0


if __name__ == "__main__":
    sys.stdout.reconfigure(encoding="utf-8")
    sys.exit(main())
