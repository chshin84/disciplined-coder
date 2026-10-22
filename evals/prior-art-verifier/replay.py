"""-def 단계 출력으로 구성 전체의 최종 판정을 만든다. 합치기는 워크플로의 mergeStages 와 classify 를 시험 도구로 실행해 얻는다.

항목마다 { id, repeat, verdict, reason, judge_sent, judge_batch, judge_raw, refetch_sent, refetch_raw, rejudge_sent, rejudge_batch,
rejudge_raw } 를 쓴다. *_raw 는 단계마다 그 항목의 판정 원본(없으면 null, ref 는 항목 id)이고, *_sent 는 그 단계의 입력에
그 항목을 보냈는지, *_batch 는 그 항목을 넣은 묶음의 unit 이다. reason 은 합친 출력의 reason 이다.
단계 출력은 run.pipeline 이 단계마다 정한 설정(run.UPSTREAM)의 줄 중 key 가 같은 줄만 고른다.
"""
import argparse
import json
import os
import subprocess
import sys

sys.path.insert(0, os.path.dirname(os.path.abspath(__file__)))
import run  # noqa: E402

HARNESS = os.path.join(run.ROOT, "scripts", "workflow_harness.mjs")
# mergeStages 의 인자 차례와 같다.
STAGES = ("extract-def", "judge-def", "refetch-def", "rejudge-def")
# classify 의 행선지 목록을 최종 verdict 로 옮긴다. rejected 에는 unsupported 만 들어온다(선행 서술 결측은 자료에 없다).
DEST = {"passed": "supported", "rejected": "unsupported", "unverifiable": "unverifiable"}


def harn(name, args):
    p = subprocess.run(["node", HARNESS, "fn", name], input=json.dumps(args, ensure_ascii=False),
                       capture_output=True, text=True, encoding="utf-8")
    if p.returncode != 0:
        raise RuntimeError(f"harn fn {name} 실패: {p.stderr}")
    return json.loads(p.stdout)


def _batch_of(p, stage):
    """항목 id -> 그 단계에서 그 항목을 넣은 묶음의 unit 이다."""
    return {c["ref"]: f"batch:{i + 1}" for i, b in enumerate(p["batches"][stage]) for it in b["items"] for c in it["claims"]}


def replay(cases, runs, repeat):
    refs_by_url = {}
    for x in cases["items"]:
        refs_by_url.setdefault(x["url"], []).append(x["id"])
    out = []
    for rep in range(1, repeat + 1):
        p = run.pipeline(cases, runs, rep)
        merged = harn("mergeStages", [refs_by_url] + [p["outputs"][s] for s in STAGES])
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
        jb, rb = _batch_of(p, "judge-def"), _batch_of(p, "rejudge-def")
        refetched = {c["ref"] for _, pl in p["units"]["refetch-def"] for c in pl["claims"]}
        for x in cases["items"]:
            i, u = x["id"], x["url"]
            raw = {s: run._judgment_of(p["outputs"][s].get(u), i) for s in STAGES[1:]}
            mo = run._judgment_of(merged["outputs"].get(u), i)
            out.append({"id": i, "repeat": rep, "verdict": verdict.get(i), "reason": None if mo is None else mo.get("reason"),
                        "judge_sent": i in jb, "judge_batch": jb.get(i), "judge_raw": raw["judge-def"],
                        "refetch_sent": i in refetched, "refetch_raw": raw["refetch-def"],
                        "rejudge_sent": i in rb, "rejudge_batch": rb.get(i), "rejudge_raw": raw["rejudge-def"]})
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
