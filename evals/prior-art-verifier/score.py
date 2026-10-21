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


def expected_key(cases, r, frozen):
    """그 실행 줄을 지금의 프롬프트·자료로 다시 만들었을 때의 key. 그 unit 이 지금 자료에 없으면 None."""
    payload = dict(run.units(cases, r["stage"], r.get("category", ""), frozen)).get(r["unit"])
    if payload is None:
        return None
    prompt = run.build_prompt(r["stage"], r.get("category", ""), payload)
    return run.make_key(r["stage"], r["model"], r["effort"], r.get("category", ""), r["repeat"], r["unit"], prompt)


def _map_required(mc):
    """지도 대조에서 출력이 반드시 표시해야 하는 칸: 행마다 case, outcome, 각 축의 prior."""
    req = set()
    for row in mc["input"].get("evidence_map", []):
        req |= {(row["case"], "case"), (row["case"], "outcome")}
        req |= {(row["case"], f"axes.{k}.prior") for k in (row.get("axes") or {})}
    return req


def score(cases, runs, stage, category, frozen=None):
    """설정(model/effort)마다 repeat 순서의 Score 목록을 낸다. frozen 은 판정 단계의 (unit, ref) -> 추출 판정이다.
    지금의 프롬프트·자료로 계산한 key 와 같은 줄만 쓴다. 옛 프롬프트의 결과가 섞이지 않게 하기 위해서다."""
    frozen = frozen or {}
    latest = {}
    for r in runs:
        if r.get("stage") != stage or r.get("error"):
            continue
        if stage == "judge" and r.get("category") != category:
            continue
        if r.get("key") != expected_key(cases, r, frozen):
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
                truth = {(t["row"], t["column"]): t["grounded"] for t in mc["truth"]}
                for cell in _map_required(mc) | set(truth):
                    g = cells.get(cell)
                    if g not in (True, False):
                        s["failures"] += 1
                    elif cell in truth and g and truth[cell] is False:
                        s["missed_errors"] += 1
                    elif cell in truth and not g and truth[cell] is True:
                        s["rejected_truths"] += 1
        else:
            for x in cases["items"]:
                if x["category"] != category:
                    continue
                if stage == "judge":
                    src = run.judge_source(x, frozen)
                    upstream = not src.get("quote") or src.get("access") == "실패" or src.get("exists") == "불일치"
                    if upstream:
                        # 추출에서 이미 기각된 항목이다. 참 항목이면 참 기각이고, 오류 항목이면 맞게 걸러진 것이다.
                        if x["truth"]:
                            s["rejected_truths"] += 1
                        else:
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


# --- 구성 전체 재측정(report-v2). 용어는 docs/superpowers/plans/2026-10-21-prior-art-verifier-tiering-implement.md 「용어」를 따른다.
V2 = os.path.join(HERE, "results-v2")
OPUS, HAIKU_HIGH, SONNET_HIGH = "claude-opus-5-5/medium", "claude-haiku-5-5/high", "claude-sonnet-5-5/high"
REPEATS = (1, 2)
# 새 구성 한 번의 비용을 이루는 단계와 설정이다.
NEW_STAGES = (("extract-def", HAIKU_HIGH), ("judge-def", HAIKU_HIGH), ("escalate-def", SONNET_HIGH), ("map-def", HAIKU_HIGH))
BASE_STAGES = (("baseline-cite", OPUS), ("baseline-map", OPUS))


def correct(truth, verdict):
    """맞힘: 참 항목은 supported, 오류 항목은 supported 가 아닌 값이 정답이다. 판정이 없으면 틀림이다."""
    if verdict is None:
        return False
    return (verdict == "supported") == bool(truth)


def confident_wrong(judge_raw, truth):
    """틀리게 확신함: 판정 원본이 모든 칸에 일치·불일치를 냈는데, 그 칸들로 정한 판정이 정답과 반대다."""
    if not judge_raw:
        return False
    cells = [judge_raw.get(k) for k in run.JUDGE_CELLS]
    if not all(c in ("일치", "불일치") for c in cells):
        return False
    return all(c == "일치" for c in cells) != bool(truth)


def handed_over(judge_raw):
    """판정 불가로 넘김: 판정 원본이 한 칸 이상에 판정 불가를 냈다."""
    return bool(judge_raw) and any(judge_raw.get(k) == "판정 불가" for k in run.JUDGE_CELLS)


def merge_item_condition(base, new):
    """병합 조건 둘째. base·new 는 항목 -> 실행마다의 맞힘 목록이다. 기준선이 모든 실행에서 맞힌 항목만 비교한다."""
    failing = [k for k, v in base.items() if v and all(v) and not (new.get(k) and all(new[k]))]
    return not failing, failing


def _latest_rows(runs):
    """(stage, 설정, repeat, unit) 마다 오류 없는 마지막 줄이다."""
    m = {}
    for r in runs:
        if not r.get("error") and r.get("output") is not None:
            m[(r["stage"], f"{r['model']}/{r['effort']}", r["repeat"], r["unit"])] = r
    return m


def _stage_cost(rows, stage, config, rep):
    return sum(r.get("cost_usd") or 0 for (s, c, rp, _), r in rows.items() if (s, c, rp) == (stage, config, rep))


def _baseline_rows(cases, runs):
    """기준선 줄 중 지금의 프롬프트·자료로 만든 key 와 같은 줄만 남긴다."""
    ok = [r for r in runs if r.get("stage") in ("baseline-cite", "baseline-map") and r.get("key") == expected_key(cases, r, {})]
    return _latest_rows(ok)


def _map_cells(cases, rows, stage, config):
    """지도 대조 칸 -> 실행마다의 맞힘 목록과, 실행마다의 (오류 통과, 참 기각, 실패)."""
    cells, tallies = {}, []
    for rep in REPEATS:
        t = [0, 0, 0]
        for mc in cases["map_cases"]:
            r = rows.get((stage, config, rep, mc["id"]))
            got = {(c.get("row"), c.get("column")): c.get("grounded") for c in ((r or {}).get("output") or {}).get("cells", [])}
            truth = {(x["row"], x["column"]): x["grounded"] for x in mc["truth"]}
            for cell in _map_required(mc) | set(truth):
                g = got.get(cell)
                if g not in (True, False):
                    t[2] += 1
                if cell in truth:
                    cells.setdefault(f"{mc['id']}:{cell[0]}/{cell[1]}", []).append(g is truth[cell])
                    if truth[cell] is False and g is True:
                        t[0] += 1
                    elif truth[cell] is True and g is not True:
                        t[1] += 1
        tallies.append(tuple(t))
    return cells, tallies


def _reason_counts(rows, stage, config):
    """판정 불가 칸의 이유 유형 개수다. unsure_reasons 에 그 칸이 빠졌으면 '(이유 없음)' 으로 센다."""
    c = {}
    for (s, cf, _, _), r in rows.items():
        if (s, cf) != (stage, config):
            continue
        for j in (r["output"] or {}).get("judgments", []) or []:
            for k in run.JUDGE_CELLS:
                if j.get(k) == "판정 불가":
                    why = (j.get("unsure_reasons") or {}).get(k) or "(이유 없음)"
                    c[why] = c.get(why, 0) + 1
    return c


def _yn(v):
    return "예" if v else "아니오"


def report_v2(base_path, def_path, replay_path, cases_path, out_path):
    cases = json.load(open(cases_path, encoding="utf-8"))
    base_runs, def_runs = read_runs(base_path), read_runs(def_path)
    replayed = json.load(open(replay_path, encoding="utf-8"))
    brows, drows = _baseline_rows(cases, base_runs), _latest_rows(def_runs)
    items = {x["id"]: x for x in cases["items"]}

    base_v = {i: [] for i in items}
    for x in cases["items"]:
        for rep in REPEATS:
            r = brows.get(("baseline-cite", OPUS, rep, x["url"]))
            js = run._by_ref([x["id"]], (r or {}).get("output"))
            base_v[x["id"]].append(js[x["id"]].get("verdict") if js else None)
    new_v = {i: [None] * len(REPEATS) for i in items}
    raw = {i: [None] * len(REPEATS) for i in items}
    esc = {i: [False] * len(REPEATS) for i in items}
    for row in replayed:
        k = REPEATS.index(row["repeat"])
        new_v[row["id"]][k], raw[row["id"]][k], esc[row["id"]][k] = row["verdict"], row["judge_raw"], row["escalated"]
    base_ok = {i: [correct(items[i]["truth"], v) for v in vs] for i, vs in base_v.items()}
    new_ok = {i: [correct(items[i]["truth"], v) for v in vs] for i, vs in new_v.items()}
    bmap, bmap_t = _map_cells(cases, brows, "baseline-map", OPUS)
    nmap, nmap_t = _map_cells(cases, drows, "map-def", HAIKU_HIGH)
    base_ok.update(bmap)
    new_ok.update(nmap)

    base_cost = [sum(_stage_cost(brows, s, c, rep) for s, c in BASE_STAGES) for rep in REPEATS]
    new_cost = [sum(_stage_cost(drows, s, c, rep) for s, c in NEW_STAGES) for rep in REPEATS]
    cond1 = max(new_cost) < min(base_cost)
    cond2, failing = merge_item_condition(base_ok, new_ok)
    compared = [k for k, v in base_ok.items() if v and all(v)]

    L = ["# 선행연구 검증자 구성 전체 재측정 결과", "",
         "이 파일은 `python -I evals/prior-art-verifier/score.py report-v2` 가 만든다. 용어는 "
         "`docs/superpowers/plans/2026-10-21-prior-art-verifier-tiering-implement.md` 「용어」를 따른다.", "",
         "## 병합 조건", "",
         f"- 비용 조건(새 구성의 실행마다 비용이 기준선의 어느 실행보다 낮다): {'충족' if cond1 else '미충족'}. "
         f"새 구성 {', '.join(f'${c:.4f}' for c in new_cost)}, 기준선 {', '.join(f'${c:.4f}' for c in base_cost)}.",
         f"- 항목 조건(기준선이 두 실행 모두 맞힌 항목은 새 구성도 두 실행 모두 맞힌다): {'충족' if cond2 else '미충족'}. "
         f"비교한 항목·칸 {len(compared)}개, 기준선이 한 번 이상 틀려 빠진 항목·칸 {len(base_ok) - len(compared)}개"
         f"({', '.join(k for k in base_ok if k not in compared) or '없음'}).", "",
         "## 기준선이 맞힌 항목 중 새 구성이 틀린 항목", ""]
    if failing:
        L += ["| 항목 | 정답 | 기준선 판정 | 새 구성 판정 | 판정 원본(수치·조건/방향/범위) |", "|---|---|---|---|---|"]
        for k in failing:
            if k in items:
                cells = " ; ".join("/".join(str((j or {}).get(c)) for c in run.JUDGE_CELLS) if j else "없음" for j in raw[k])
                L.append(f"| {k} | {'참' if items[k]['truth'] else '오류'} | {', '.join(map(str, base_v[k]))} | "
                         f"{', '.join(map(str, new_v[k]))} | {cells} |")
            else:
                L.append(f"| {k} | 지도 대조 칸 | 맞힘 | {new_ok.get(k)} | 해당 없음 |")
    else:
        L.append("없다.")
    L += ["", "## 카테고리별 오류 통과와 참 기각", "",
          "칸의 값은 실행 1·2 의 \"오류 통과 / 참 기각\" 이다.", "",
          "| 카테고리 | 기준선 | 새 구성 |", "|---|---|---|"]
    cats = []
    for x in cases["items"]:
        if x["category"] not in cats:
            cats.append(x["category"])
    for c in cats:
        def tally(vs):
            return ", ".join(
                f"{sum(1 for i in items if items[i]['category'] == c and not items[i]['truth'] and vs[i][k] == 'supported')} / "
                f"{sum(1 for i in items if items[i]['category'] == c and items[i]['truth'] and vs[i][k] != 'supported')}"
                for k in range(len(REPEATS)))
        L.append(f"| {c} | {tally(base_v)} | {tally(new_v)} |")
    L.append(f"| map | {', '.join(f'{a} / {b}' for a, b, _ in bmap_t)} | {', '.join(f'{a} / {b}' for a, b, _ in nmap_t)} |")
    L += ["", f"지도 대조의 판정 대상 칸 누락(실패): 기준선 {[t[2] for t in bmap_t]}, 새 구성 {[t[2] for t in nmap_t]}.", ""]
    vf = [(i, REPEATS[k], raw[i][k]) for i in items for k in range(len(REPEATS)) if new_v[i][k] == "verify_failed"]
    L += ["## 새 구성의 검증 실패", ""]
    if vf:
        L += ["| 항목 | 실행 | 판정 원본(수치·조건/방향/범위) | 다른 칸에 불일치 |", "|---|---|---|---|"]
        for i, rep, j in vf:
            cells = "/".join(str((j or {}).get(c)) for c in run.JUDGE_CELLS) if j else "없음"
            L.append(f"| {i} | {rep} | {cells} | {_yn(j and '불일치' in [j.get(c) for c in run.JUDGE_CELLS])} |")
    else:
        L.append("없다.")

    L += ["", "## 어려운 항목", "",
          "| 항목 | 종류 | 정답 | 기준선 맞힘 | 새 구성 맞힘 | 판정 불가로 넘김 | 틀리게 확신함 |", "|---|---|---|---|---|---|---|"]
    hard = [x for x in cases["items"] if "hard_kind" in x]
    for x in hard:
        i = x["id"]
        L.append(f"| {i} | {x['hard_kind']} | {'참' if x['truth'] else '오류'} | {', '.join(map(_yn, base_ok[i]))} | "
                 f"{', '.join(map(_yn, new_ok[i]))} | {', '.join(_yn(handed_over(j)) for j in raw[i])} | "
                 f"{', '.join(_yn(confident_wrong(j, x['truth'])) for j in raw[i])} |")
    L += ["", "### 판정 에이전트 노력 수준별 비교(실행 1, 병합 판정에 쓰지 않는다)", "",
          "| 수준 | 판정한 어려운 항목 | 판정 불가로 넘김 | 틀리게 확신함 | 비용(USD) |", "|---|---|---|---|---|"]
    for eff in ("low", "medium", "high"):
        cfg = f"claude-haiku-5-5/{eff}"
        js = []
        for x in hard:
            r = drows.get(("judge-def", cfg, 1, x["url"]))
            got = run._by_ref([x["id"]], (r or {}).get("output"))
            if got:
                js.append((x, got[x["id"]]))
        cost = sum((drows.get(("judge-def", cfg, 1, u)) or {}).get("cost_usd") or 0 for u in {x["url"] for x in hard})
        L.append(f"| {eff} | {len(js)} | {', '.join(x['id'] for x, j in js if handed_over(j)) or '없음'} | "
                 f"{', '.join(x['id'] for x, j in js if confident_wrong(j, x['truth'])) or '없음'} | {cost:.4f} |")
    L += ["", "high 의 비용은 어려운 항목 URL 의 판정 실행만 합한 값이다.", "",
          "### 판정 불가 이유 유형", "", "| 단계·설정 | 이유 유형별 개수 |", "|---|---|"]
    for stage, cfg in (("judge-def", "claude-haiku-5-5/low"), ("judge-def", "claude-haiku-5-5/medium"),
                       ("judge-def", HAIKU_HIGH), ("escalate-def", SONNET_HIGH)):
        rc = _reason_counts(drows, stage, cfg)
        L.append(f"| {stage} {cfg} | {', '.join(f'{k} {v}' for k, v in sorted(rc.items())) or '없음'} |")

    L += ["", "## 상향 비율", "", "| 실행 | 판정한 주장 | 판정 불가로 넘김 | 상향 판정을 받음 | 비율 |", "|---|---|---|---|---|"]
    for k, rep in enumerate(REPEATS):
        judged = [i for i in items if raw[i][k]]
        handed = [i for i in judged if handed_over(raw[i][k])]
        got = [i for i in items if esc[i][k]]
        L.append(f"| {rep} | {len(judged)} | {len(handed)} ({', '.join(handed) or '없음'}) | {len(got)} | "
                 f"{(len(handed) / len(judged) if judged else 0):.1%} |")

    L += ["", "## 단계별 비용", "", "| 단계 | 설정 | 실행 1 | 실행 2 |", "|---|---|---|---|"]
    for s, c in BASE_STAGES:
        L.append(f"| {s} | {c} | " + " | ".join(f"{_stage_cost(brows, s, c, rep):.4f}" for rep in REPEATS) + " |")
    for s, c in NEW_STAGES:
        L.append(f"| {s} | {c} | " + " | ".join(f"{_stage_cost(drows, s, c, rep):.4f}" for rep in REPEATS) + " |")
    for eff in ("low", "medium"):
        c = f"claude-haiku-5-5/{eff}"
        L.append(f"| judge-def(어려운 항목만) | {c} | {_stage_cost(drows, 'judge-def', c, 1):.4f} | 실행하지 않음 |")
    allrows = base_runs + def_runs
    errs = [r for r in allrows if r.get("error")]
    L += ["", f"두 결과 파일의 전체 비용(오류 줄과 다시 실행한 줄 포함): ${sum(r.get('cost_usd') or 0 for r in allrows):.4f}.", "",
          "## 실행 기록", "",
          f"기준선 {len(base_runs)}줄, 새 구성 {len(def_runs)}줄, 오류 줄 {len(errs)}개, "
          f"시간 초과 {sum('시간 초과' in r['error'] for r in errs)}개, 모델 불일치 {sum('모델 불일치' in r['error'] for r in errs)}개.", "",
          "실행 조건은 README.md 「실행 조건」에 있다."]
    with open(out_path, "w", encoding="utf-8") as f:
        f.write("\n".join(L) + "\n")


if __name__ == "__main__":
    sys.stdout.reconfigure(encoding="utf-8")
    ap = argparse.ArgumentParser()
    ap.add_argument("cmd", choices=["report", "report-v2"])
    ap.add_argument("--runs")
    ap.add_argument("--def-runs", default=os.path.join(V2, "runs-def.jsonl"))
    ap.add_argument("--replay", default=os.path.join(V2, "replay.json"))
    ap.add_argument("--cases")
    ap.add_argument("--frozen", default=os.path.join(HERE, "results", "extract-frozen.jsonl"))
    ap.add_argument("--out")
    a = ap.parse_args()
    d = V2 if a.cmd == "report-v2" else os.path.join(HERE, "results")
    runs_path = a.runs or os.path.join(d, "runs.jsonl")
    cases_path = a.cases or os.path.join(HERE, "cases-v2.json" if a.cmd == "report-v2" else "cases.json")
    out = a.out or os.path.join(d, "report.md")
    if a.cmd == "report-v2":
        report_v2(runs_path, a.def_runs, a.replay, cases_path, out)
    else:
        report(runs_path, cases_path, a.frozen, out)
    print(out)
