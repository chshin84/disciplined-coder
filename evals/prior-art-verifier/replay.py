"""-def 단계 출력으로 구성 전체의 최종 판정을 만든다. 합치기는 워크플로의 mergeStages 와 classify 를 시험 도구로 실행해 얻는다.

항목마다 { id, repeat, verdict, judge_raw, refetch_sent, refetch_raw, rejudge_raw, escalate_sent, escalate_raw, escalated } 를 쓴다.
*_raw 는 단계마다 그 항목의 판정 원본(없으면 null)이고, *_sent 는 그 단계의 입력에 그 항목을 보냈는지,
escalated 는 상향 판정 출력에 그 항목의 판정이 있는지다. 단계 출력은 run.def_output 으로 key 가 같은 줄만 고른다.
"""
import argparse
import json
import os
import subprocess
import sys

sys.path.insert(0, os.path.dirname(os.path.abspath(__file__)))
import run  # noqa: E402

HARNESS = os.path.join(run.ROOT, "scripts", "workflow_harness.mjs")
ESCALATION = "claude-opus-5-5/medium"
# mergeStages 의 인자 차례와 같다.
STAGES = ("extract-def", "judge-def", "refetch-def", "rejudge-def", "escalate-def")
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
        for stage in STAGES:
            config = escalation if stage == "escalate-def" else upstream
            stage_out[stage] = {}
            for u in refs_by_url:
                o = run.def_output(cases, runs, stage, config, rep, u, upstream)
                if o is not None:
                    stage_out[stage][u] = o
        merged = harn("mergeStages", [refs_by_url] + [stage_out[s] for s in STAGES])
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
        sent = {}
        for stage in ("refetch-def", "escalate-def"):
            for u in refs_by_url:
                p = run.def_payload(cases, stage, runs, rep, upstream, u)
                sent.setdefault(stage, set()).update(c["ref"] for c in (p or {}).get("claims", []))
        for x in cases["items"]:
            raw = {s: run._judgment_of(stage_out[s].get(x["url"]), x["id"]) for s in STAGES[1:]}
            es = run._by_ref([x["id"]], stage_out["escalate-def"].get(x["url"]))
            out.append({"id": x["id"], "repeat": rep, "verdict": verdict.get(x["id"]),
                        "judge_raw": raw["judge-def"], "refetch_sent": x["id"] in sent["refetch-def"],
                        "refetch_raw": raw["refetch-def"], "rejudge_raw": raw["rejudge-def"],
                        "escalate_sent": x["id"] in sent["escalate-def"], "escalate_raw": raw["escalate-def"],
                        "escalated": es is not None})
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
