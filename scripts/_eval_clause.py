"""조항별 클린룸 시험의 계획·실행·보고. 소비자는 eval_clause.sh, eval_clause_report.sh, _test_eval_clause.py 다.

시험 단위는 evals/principles/clauses/<단위 이름>/ 폴더 하나다. ids 파일이 있으면 그 줄들이, 없으면 폴더 이름이
단위의 조항 ID 다. current.md 가 있으면 문구 변경(current·new 비교), 없으면 새 조항(none·new 비교)이다.
같은 질문을 같은 조건으로 두 번 생성하지 않도록 생성은 생성 키로, 판정은 판정 키로 기록한다(2026-10-18 사용자 지시).

사용: python _eval_clause.py run <과제> <단위> <결과> <임시> [단위 이름...]
      python _eval_clause.py report <과제> <단위> <결과> <pairs> <excl> [단위 이름...]
"""
import concurrent.futures
import hashlib
import json
import os
import runpy
import sys

HERE = os.path.dirname(os.path.abspath(__file__))


def _sha(s):
    return hashlib.sha256(s.encode("utf-8")).hexdigest()[:16]


def make_cfg(path, text):
    os.makedirs(path, exist_ok=True)
    if text:
        open(os.path.join(path, "CLAUDE.md"), "w", encoding="utf-8", newline="\n").write(text)


def gen_key(case, cond_text):
    """생성 모델이 받는 것(과제 본문과 조건 문안)만으로 키를 만든다. 과제 머리를 바꿔도 키는 같다."""
    return _sha(case["prompt"]) + "-" + _sha(cond_text)


def judge_key(gk, criteria):
    return gk + "-" + _sha(criteria)


def load_units(root, names=None):
    units = {}
    for n in sorted(os.listdir(root)):
        d = os.path.join(root, n)
        if not os.path.isdir(d) or (names and n not in names):
            continue
        rd = lambda f: open(os.path.join(d, f), encoding="utf-8").read() if os.path.isfile(os.path.join(d, f)) else None
        ids = [x.strip() for x in (rd("ids") or n).splitlines() if x.strip()]
        units[n] = {"ids": ids, "current": rd("current.md"), "new": rd("new.md") or ""}
    missing = set(names or []) - set(units)
    if missing:
        raise SystemExit("없는 단위: " + " ".join(sorted(missing)))
    return units


def questions(cases, unit):
    return sorted(n for n, c in cases.items()
                  if "dev" in (c["meta"].get("tags") or []) and set(c["meta"].get("clause") or []) & set(unit["ids"]))


def conditions(unit):
    """(조건 이름, 문안). 첫째가 비교 조건이다."""
    cmp = ("current", unit["current"]) if unit["current"] is not None else ("none", "")
    return [cmp, ("new", unit["new"])]


def plan_jobs(cases, units, done_gen, done_judge):
    gen_jobs, judge_jobs, seen = [], [], set()
    for u in units.values():
        for q in questions(cases, u):
            for cond, text in conditions(u):
                gk = gen_key(cases[q], text)
                if gk in seen:
                    continue
                seen.add(gk)
                if gk not in done_gen:
                    gen_jobs.append((gk, q, cond, text))
                elif judge_key(gk, cases[q]["criteria"]) not in done_judge:
                    judge_jobs.append((judge_key(gk, cases[q]["criteria"]), gk, q))
    return gen_jobs, judge_jobs


def read_jsonl(path):
    out = {}
    if not os.path.isfile(path):
        return out
    for i, line in enumerate(open(path, encoding="utf-8"), 1):
        if not line.strip():
            continue
        try:
            r = json.loads(line)
        except ValueError:
            raise SystemExit(f"ERROR: {path} 의 {i}번째 줄을 읽을 수 없다. 기록을 고치기 전에는 실행하지 않는다.")
        out[r["key"]] = r
    return out


def report_unit(cases, unit, gens, judges, count):
    qs = questions(cases, unit)
    (cmp, ctext), (_, ntext) = conditions(unit)
    tot = {"c": 0, "n": 0}
    chat = {"c": [], "n": []}
    complete = True
    for q in qs:
        for side, text in (("c", ctext), ("n", ntext)):
            gk = gen_key(cases[q], text)
            j = judges.get(judge_key(gk, cases[q]["criteria"]))
            if gk not in gens or j is None:
                complete = False
                continue
            tot[side] += 1 if j["violated"] else 0
            if cases[q]["meta"].get("type") == "chat":
                chat[side].append(gens[gk]["response"])
    followup = any(str(cases[q]["meta"].get("followup", "")).lower() == "true" for q in qs)
    c, n = tot["c"], tot["n"]
    if not complete:
        v = "미완"
    elif cmp == "current":
        v = "채택" if n < c else "기각" if n > c else ("채택(차이없음)" if followup else "동률")
    else:
        v = "넣지않음" if c == 0 else "넣음" if n < c else "기각" if n > c else ("넣지않음" if followup else "동률")
    return {"n_questions": len(qs), "cmp": cmp, "cmp_viol": c, "new_viol": n,
            "banned_cmp": count(chat["c"]), "banned_new": count(chat["n"]), "verdict": v}


def _run(cases_dir, units_dir, results, tmp, names):
    lib = runpy.run_path(os.path.join(HERE, "_eval_lib.py"))
    ev = runpy.run_path(os.path.join(HERE, "_eval_run.py"))
    cases = lib["load_cases"](cases_dir)
    units = load_units(units_dir, names)
    os.makedirs(results, exist_ok=True)
    gp, jp = os.path.join(results, "gen.jsonl"), os.path.join(results, "judge.jsonl")
    gens, judges = read_jsonl(gp), read_jsonl(jp)
    gen_jobs, judge_jobs = plan_jobs(cases, units, set(gens), set(judges))
    cwd = os.path.join(tmp, "cwd")
    os.makedirs(cwd, exist_ok=True)

    def do_judge(gk, q, response):
        jk = judge_key(gk, cases[q]["criteria"])
        jd = os.path.join(tmp, "j-" + jk)
        make_cfg(jd, "")
        r = ev["judge"](cases[q]["prompt"], cases[q]["criteria"], response, cwd, dict(os.environ, CLAUDE_CONFIG_DIR=jd))
        if r["violated"] is None:
            return None, f"{q}: 판정 읽기 실패 {r['judge_note'][:120]}"
        return {"key": jk, "gen_key": gk, "case": q, "violated": r["violated"],
                "judge_note": r["judge_note"], "judge_model": r["judge_model"]}, None

    def gen_task(job):
        gk, q, cond, text = job
        gd = os.path.join(tmp, "g-" + gk)
        make_cfg(gd, text)
        g = ev["generate"](cases[q]["prompt"], cwd, dict(os.environ, CLAUDE_CONFIG_DIR=gd))
        if g["error"]:
            return None, None, [f"{q} {cond}: 생성 오류 {g['error'][:120]}"]
        grec = {"key": gk, "case": q, "cond": cond, "response": g["response"], "model": g["model"]}
        jrec, err = do_judge(gk, q, g["response"])
        return grec, jrec, [err] if err else []

    def judge_task(job):
        jk, gk, q = job
        jrec, err = do_judge(gk, q, gens[gk]["response"])
        return None, jrec, [err] if err else []

    errors, ng, nj = [], 0, 0
    with open(gp, "a", encoding="utf-8") as gf, open(jp, "a", encoding="utf-8") as jf, \
            concurrent.futures.ThreadPoolExecutor(ev["JOBS"]) as ex:
        futs = [ex.submit(gen_task, j) for j in gen_jobs] + [ex.submit(judge_task, j) for j in judge_jobs]
        for f in concurrent.futures.as_completed(futs):
            grec, jrec, errs = f.result()
            # 생성 기록을 판정 기록보다 먼저 쓴다. 판정이 실패해도 다음 실행은 판정만 다시 한다.
            if grec:
                gf.write(json.dumps(grec, ensure_ascii=False) + "\n"); gf.flush(); ng += 1
            if jrec:
                jf.write(json.dumps(jrec, ensure_ascii=False) + "\n"); jf.flush(); nj += 1
            errors += errs
    for e in errors:
        print("  " + e)
    print(f"생성={ng} 판정={nj} errors={len(errors)}")


def _report(cases_dir, units_dir, results, pairs, excl, names):
    lib = runpy.run_path(os.path.join(HERE, "_eval_lib.py"))
    cases = lib["load_cases"](cases_dir)
    units = load_units(units_dir, names)
    gens = read_jsonl(os.path.join(results, "gen.jsonl"))
    judges = read_jsonl(os.path.join(results, "judge.jsonl"))
    count = lambda texts: lib["banned_count"](texts, pairs, excl)
    for n, u in units.items():
        r = report_unit(cases, u, gens, judges, count)
        print(f"{n} 질문={r['n_questions']} 비교={r['cmp']} 비교위반={r['cmp_viol']} 새위반={r['new_viol']} "
              f"금지어 비교={r['banned_cmp']} 새={r['banned_new']} 판정={r['verdict']}")


def check_units(cases, units, baseline):
    """저장소 단위 폴더의 형식 오류를 낸다. baseline 은 기준 원칙 커밋의 agent-principles.md 내용이다."""
    errs = []
    for n, u in units.items():
        if not u["new"].strip():
            errs.append(f"{n}: new.md 가 없거나 비었다")
        if u["current"] is not None and n != "BANNED-LIST":
            for line in u["current"].splitlines():
                if line.strip() and line not in baseline:
                    errs.append(f"{n}: current.md 의 줄이 기준 원칙에 없다: {line[:40]}")
        qs = questions(cases, u)
        kinds = {cases[q]["meta"].get("kind") for q in qs}
        if len(qs) < 3 or kinds != {"should", "should-not"}:
            errs.append(f"{n}: 개발용 질문 {len(qs)}개, kind {sorted(k for k in kinds if k)}")
    return errs


if __name__ == "__main__":
    a = sys.argv
    if a[1] == "check":
        # check <과제> <단위> <기준 원칙 파일>
        lib = runpy.run_path(os.path.join(HERE, "_eval_lib.py"))
        for e in check_units(lib["load_cases"](a[2]), load_units(a[3]), open(a[4], encoding="utf-8").read()):
            print(e)
    elif a[1] == "run":
        _run(a[2], a[3], a[4], a[5], a[6:])
    elif a[1] == "report":
        _report(a[2], a[3], a[4], a[5], a[6], a[7:])
    else:
        raise SystemExit(f"모르는 명령 {a[1]}")
