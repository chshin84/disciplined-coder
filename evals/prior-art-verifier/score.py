"""선행연구 검증자 시험의 집계기다. runs.jsonl 을 카테고리·설정별 성적으로 세고 채택 규칙을 적용한다.

오류 통과: 오류 항목을 통과시킨 건수. 참 기각: 참 항목을 기각한 건수. 세는 법은 plan 「용어」를 따른다.
"""
import argparse
import json
import os
import sys

sys.path.insert(0, os.path.dirname(os.path.abspath(__file__)))
import run  # noqa: E402

HERE = os.path.dirname(os.path.abspath(__file__))
EXTRACT_CATS = ("access", "exists", "quote")
JUDGE_CATS = ("numbers_conditions", "direction", "scope")
MODEL_ORDER = ("claude-haiku-5-5", "claude-sonnet-5-5", "claude-opus-5-5")
EFFORT_ORDER = ("low", "medium", "high", "xhigh")


def _empty():
    return {"missed_errors": 0, "rejected_truths": 0, "failures": 0, "excluded": [], "cost_usd": 0.0}


def _rejected(stage, j):
    """판정 하나가 기각 신호인지. 판정이 없으면 None."""
    if j is None:
        return None
    if stage == "baseline-cite":
        return j.get("verdict") in ("unsupported", "unverifiable")
    if stage == "extract":
        return j.get("access") == "실패" or j.get("exists") == "불일치" or not j.get("quote")
    if stage == "judge":
        m = j.get("match")
        return None if m not in ("일치", "불일치") else m == "불일치"
    return None


def score(cases, runs, stage, category, frozen=None):
    """설정(model/effort)마다 repeat 순서의 Score 목록을 낸다. frozen 은 판정 단계의 (unit, ref) -> 추출 판정이다."""
    frozen = frozen or {}
    latest = {}
    for r in runs:
        if r.get("stage") != stage or r.get("error"):
            continue
        if stage == "judge" and r.get("category") != category:
            continue
        latest[(r["model"], r["effort"], r["repeat"], r["unit"])] = r
    configs = sorted({(m, e, rep) for m, e, rep, _ in latest})
    out = {}
    for m, e, rep in configs:
        s = _empty()
        for (m2, e2, rep2, _), r in latest.items():
            if (m2, e2, rep2) == (m, e, rep) and r.get("cost_usd") is not None:
                s["cost_usd"] += r["cost_usd"]
        if stage in ("map", "baseline-map"):
            for mc in cases["map_cases"]:
                r = latest.get((m, e, rep, mc["id"]))
                cells = {(c.get("row"), c.get("column")): c.get("grounded") for c in ((r or {}).get("output") or {}).get("cells", [])}
                for t in mc["truth"]:
                    g = cells.get((t["row"], t["column"]))
                    if g is None:
                        s["failures"] += 1
                    elif g and not t["grounded"]:
                        s["missed_errors"] += 1
                    elif not g and t["grounded"]:
                        s["rejected_truths"] += 1
        else:
            for x in cases["items"]:
                if x["category"] != category:
                    continue
                if stage == "judge" and not run.judge_source(x, frozen).get("quote"):
                    s["excluded"].append(x["id"])
                    continue
                r = latest.get((m, e, rep, x["url"]))
                js = {j.get("ref"): j for j in ((r or {}).get("output") or {}).get("judgments", [])}
                rej = _rejected(stage, js.get(x["id"]))
                if rej is None:
                    s["failures"] += 1
                elif x["truth"] and rej:
                    s["rejected_truths"] += 1
                elif not x["truth"] and not rej:
                    s["missed_errors"] += 1
        out.setdefault(f"{m}/{e}", []).append(s)
    return out


def baseline_of(scores):
    """기준선 실행들에서 나쁜 쪽 값과 흔들림을 낸다."""
    base = _empty()
    noise = {}
    for k in ("missed_errors", "rejected_truths", "failures"):
        vals = [s[k] for s in scores]
        base[k] = max(vals)
        if k != "failures":
            noise[k] = max(vals) - min(vals)
    base["cost_usd"] = sum(s["cost_usd"] for s in scores) / len(scores)
    return base, noise


def _passes(runs, base, noise):
    return all(s["failures"] == 0 and s["missed_errors"] <= base["missed_errors"] + noise["missed_errors"]
               and s["rejected_truths"] <= base["rejected_truths"] + noise["rejected_truths"] for s in runs)


def _order(key, cost):
    m, e = key.split("/")
    mi = MODEL_ORDER.index(m) if m in MODEL_ORDER else len(MODEL_ORDER)
    ei = EFFORT_ORDER.index(e) if e in EFFORT_ORDER else len(EFFORT_ORDER)
    return (cost, mi, ei)


def _cost(runs):
    return sum(s["cost_usd"] for s in runs) / len(runs)


def select(scores, baseline, noise):
    ok = [k for k, v in scores.items() if _passes(v, baseline, noise)]
    return min(ok, key=lambda k: _order(k, _cost(scores[k]))) if ok else None


def select_extract(per_category, baselines):
    """접근·존재·구절 모두에서 채택 조건을 채운 설정 중 비용이 가장 낮은 설정을 낸다."""
    cats = list(per_category)
    keys = set.intersection(*(set(per_category[c]) for c in cats)) if cats else set()
    ok = [k for k in keys if all(_passes(per_category[c][k], *baselines[c]) for c in cats)]
    return min(ok, key=lambda k: _order(k, max(_cost(per_category[c][k]) for c in cats))) if ok else None


def read_runs(path):
    if not os.path.exists(path):
        return []
    with open(path, encoding="utf-8") as f:
        return [json.loads(l) for l in f if l.strip()]


def load_frozen(path):
    m = {}
    for r in read_runs(path):
        if r.get("stage") == "extract" and not r.get("error") and r.get("output"):
            for j in r["output"].get("judgments", []):
                m[(r["unit"], j.get("ref"))] = j
    return m


def _table(title, scores, base, noise, chosen):
    lines = [f"### {title}", "", f"기준선(나쁜 쪽): 오류 통과 {base['missed_errors']}, 참 기각 {base['rejected_truths']}, "
             f"실패 {base['failures']}, 실행당 비용 ${base['cost_usd']:.4f}. 흔들림: {noise}", "",
             "| 설정 | 오류 통과 | 참 기각 | 실패 | 비용(USD) | 제외 |", "|---|---|---|---|---|---|"]
    for k in sorted(scores, key=lambda k: _order(k, 0)):
        for s in scores[k]:
            lines.append(f"| {k} | {s['missed_errors']} | {s['rejected_truths']} | {s['failures']} | {s['cost_usd']:.4f} | {', '.join(s['excluded'])} |")
    lines += ["", f"고른 설정: {chosen or '없음(기준선을 넘은 설정이 없다)'}", ""]
    return lines


def report(runs_path, cases_path, frozen_path, out_path):
    cases = json.load(open(cases_path, encoding="utf-8"))
    runs = read_runs(runs_path)
    frozen = load_frozen(frozen_path)
    lines = ["# 선행연구 검증자 설정 선택 시험 결과", ""]
    baselines = {}
    for c in EXTRACT_CATS + JUDGE_CATS:
        b = score(cases, runs, "baseline-cite", c).get("claude-opus-5-5/medium")
        if b:
            baselines[c] = baseline_of(b)
    bm = score(cases, runs, "baseline-map", "map").get("claude-opus-5-5/medium")
    if bm:
        baselines["map"] = baseline_of(bm)
    lines.append("## 추출 단계")
    per = {c: score(cases, runs, "extract", c) for c in EXTRACT_CATS}
    if all(c in baselines for c in EXTRACT_CATS) and any(per.values()):
        chosen = select_extract(per, baselines)
        for c in EXTRACT_CATS:
            lines += _table(c, per[c], *baselines[c], chosen)
        lines.append(f"추출 단계에서 고른 하나의 설정: {chosen or '없음'}")
    else:
        lines.append("기준선이나 추출 실행이 아직 없다.")
    lines += ["", "## 판정 단계"]
    for c in JUDGE_CATS:
        s = score(cases, runs, "judge", c, frozen)
        if s and c in baselines:
            lines += _table(c, s, *baselines[c], select(s, *baselines[c]))
    lines += ["", "## 지도 대조"]
    s = score(cases, runs, "map", "map")
    if s and "map" in baselines:
        lines += _table("map", s, *baselines["map"], select(s, *baselines["map"]))
    errs = [r for r in runs if r.get("error")]
    lines += ["", "## 실행 기록", "", f"전체 {len(runs)}줄, 오류 줄 {len(errs)}개, 시간 초과 {sum('시간 초과' in r['error'] for r in errs)}개.",
              f"모델 불일치 줄: {sum('모델 불일치' in r['error'] for r in errs)}개.", "",
              "실행 조건은 README.md 「실행 조건」에 있다."]
    with open(out_path, "w", encoding="utf-8") as f:
        f.write("\n".join(lines) + "\n")


if __name__ == "__main__":
    sys.stdout.reconfigure(encoding="utf-8")
    ap = argparse.ArgumentParser()
    ap.add_argument("cmd", choices=["report"])
    ap.add_argument("--runs", default=os.path.join(HERE, "results", "runs.jsonl"))
    ap.add_argument("--cases", default=os.path.join(HERE, "cases.json"))
    ap.add_argument("--frozen", default=os.path.join(HERE, "results", "extract-frozen.jsonl"))
    ap.add_argument("--out", default=os.path.join(HERE, "results", "report.md"))
    a = ap.parse_args()
    report(a.runs, a.cases, a.frozen, a.out)
    print(a.out)
