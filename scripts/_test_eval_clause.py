"""_eval_clause.py 와 _eval_lib.py 의 클린룸 함수를 픽스처로 시험한다. 소비자는 test_eval_cases.sh 다.
한 줄에 'OK <이름>' 이나 'NG <이름>' 을 내고, 끝까지 실행되면 마지막 줄에 'DONE' 을 낸다.

사용: python _test_eval_clause.py <scripts 폴더> <임시 폴더>
"""
import os
import runpy
import sys

scripts, tmp = sys.argv[1], sys.argv[2]
cl = runpy.run_path(os.path.join(scripts, "_eval_clause.py"))
lib = runpy.run_path(os.path.join(scripts, "_eval_lib.py"))


def say(name, ok):
    print(("OK " if ok else "NG ") + name)


def case(body, tags=("dev",), clause=(), kind="should", typ="chat", followup=False, criteria="c"):
    meta = {"tags": list(tags), "kind": kind, "type": typ, "failure": ["format"], "clause": list(clause)}
    if followup:
        meta["followup"] = "true"
    return {"meta": meta, "prompt": body, "criteria": criteria}


# make_cfg
d1, d2 = os.path.join(tmp, "cfg1"), os.path.join(tmp, "cfg2")
cl["make_cfg"](d1, "조항 문안")
cl["make_cfg"](d2, "")
say("make_cfg 는 문안이 있으면 CLAUDE.md 하나만 쓴다",
    os.listdir(d1) == ["CLAUDE.md"] and open(os.path.join(d1, "CLAUDE.md"), encoding="utf-8").read() == "조항 문안")
say("make_cfg 는 문안이 비면 아무것도 쓰지 않는다", os.listdir(d2) == [])

# 키
a, b = case("같은 본문", clause=["X"]), case("같은 본문", clause=["Y"], kind="should-not")
gk = cl["gen_key"]
say("gen_key 는 머리만 다른 과제에 같은 값을 낸다", gk(a, "t") == gk(b, "t"))
say("gen_key 는 본문이 다르면 다른 값을 낸다", gk(a, "t") != gk(case("다른 본문"), "t"))
say("gen_key 는 조건 문안이 다르면 다른 값을 낸다", gk(a, "t") != gk(a, "u"))
say("판정 기준만 바꾸면 judge_key 만 달라진다",
    cl["judge_key"](gk(a, "t"), "c1") != cl["judge_key"](gk(a, "t"), "c2"))
say("판정 모델을 바꾸면 judge_key 가 달라진다",
    cl["judge_key"](gk(a, "t"), "c1", "m1") != cl["judge_key"](gk(a, "t"), "c1", "m2"))

# 작업 계획
cases = {"a1": case("본문1", clause=["X-ONE"]), "a2": case("본문2", clause=["Y-THREE"]),
         "h1": case("본문3", tags=("holdout",), clause=["X-ONE"])}
units = {"X-ONE": {"ids": ["X-ONE"], "current": "cur", "new": "newx"},
         "Y-TWO": {"ids": ["Y-TWO", "Y-THREE"], "current": None, "new": "newy"}}
g, j = cl["plan_jobs"](cases, units, set(), set())
got = {(x[1], x[3]) for x in g}
say("plan_jobs 는 문구 변경에 current·new, 새 조항에 none·new 를 낸다",
    got == {("a1", "cur"), ("a1", "newx"), ("a2", ""), ("a2", "newy")})
say("plan_jobs 는 ids 의 다른 ID 를 태그한 과제도 질문으로 쓴다", ("a2", "newy") in got)
say("plan_jobs 는 보류용 과제를 쓰지 않는다", all(x[1] != "h1" for x in g))
done = {gk(cases["a1"], "cur")}
g2, j2 = cl["plan_jobs"](cases, units, done, set())
say("기록된 생성은 다시 계획하지 않는다", ("a1", "cur") not in {(x[1], x[3]) for x in g2} and len(g2) == 3)
say("판정이 없는 기록된 생성은 판정만 계획한다", [x[1] for x in j2] == [gk(cases["a1"], "cur")])
units2 = {"X-ONE": units["X-ONE"], "X-DUP": {"ids": ["X-ONE"], "current": "cur", "new": "newz"}}
g3, _ = cl["plan_jobs"](cases, units2, set(), set())
say("같은 질문과 같은 조건은 단위가 달라도 한 번만 계획한다", sorted(x[3] for x in g3) == ["cur", "newx", "newz"])


# 보고
def verdict(unit, viol, extra_cases=None, resp=None):
    """viol: {(과제, 조건 문안): 위반 또는 None(판정 없음)}"""
    cs = dict(extra_cases or {})
    gens, judges = {}, {}
    for (c, t), v in viol.items():
        k = gk(cs[c], t)
        gens[k] = {"key": k, "case": c, "response": (resp or {}).get((c, t), "응답")}
        if v is not None:
            jk = cl["judge_key"](k, cs[c]["criteria"])
            judges[jk] = {"key": jk, "gen_key": k, "violated": v}
    return cl["report_unit"](cs, unit, gens, judges, lambda texts: sum(x.count("판") for x in texts))


U = {"ids": ["Z"], "current": "C", "new": "N"}
NU = {"ids": ["Z"], "current": None, "new": "N"}
q = {"q1": case("p1", clause=["Z"]), "q2": case("p2", clause=["Z"], kind="should-not")}
qf = dict(q, q3=case("p3", clause=["Z"], followup=True))
say("판정 기록이 빠지면 미완이다", verdict(U, {("q1", "C"): True, ("q1", "N"): None, ("q2", "C"): False, ("q2", "N"): False}, q)["verdict"] == "미완")
say("새위반이 적으면 채택이다", verdict(U, {("q1", "C"): True, ("q1", "N"): False, ("q2", "C"): False, ("q2", "N"): False}, q)["verdict"] == "채택")
say("새위반이 많으면 기각이다", verdict(U, {("q1", "C"): False, ("q1", "N"): True, ("q2", "C"): False, ("q2", "N"): False}, q)["verdict"] == "기각")
say("같고 추가 질문이 없으면 동률이다", verdict(U, {("q1", "C"): True, ("q1", "N"): True, ("q2", "C"): False, ("q2", "N"): False}, q)["verdict"] == "동률")
say("같고 추가 질문이 있으면 채택(차이없음)이다", verdict(U, {("q1", "C"): False, ("q1", "N"): False, ("q2", "C"): False, ("q2", "N"): False, ("q3", "C"): False, ("q3", "N"): False}, qf)["verdict"] == "채택(차이없음)")
say("새 조항은 none 위반이 0 이면 넣지않음이다", verdict(NU, {("q1", ""): False, ("q1", "N"): False, ("q2", ""): False, ("q2", "N"): False}, q)["verdict"] == "넣지않음")
say("새 조항은 새위반이 적으면 넣음이다", verdict(NU, {("q1", ""): True, ("q1", "N"): False, ("q2", ""): False, ("q2", "N"): False}, q)["verdict"] == "넣음")
say("새 조항은 새위반이 많으면 기각이다", verdict(NU, {("q1", ""): True, ("q1", "N"): True, ("q2", ""): False, ("q2", "N"): True}, q)["verdict"] == "기각")
say("새 조항이 같고 추가 질문이 없으면 동률이다", verdict(NU, {("q1", ""): True, ("q1", "N"): True, ("q2", ""): False, ("q2", "N"): False}, q)["verdict"] == "동률")
say("새 조항이 같고 추가 질문이 있으면 넣지않음이다", verdict(NU, {("q1", ""): True, ("q1", "N"): True, ("q2", ""): False, ("q2", "N"): False, ("q3", ""): False, ("q3", "N"): False}, qf)["verdict"] == "넣지않음")
qt = {"q1": case("p1", clause=["Z"]), "q2": case("p2", clause=["Z"], kind="should-not", typ="tool")}
r = verdict(U, {("q1", "C"): False, ("q1", "N"): False, ("q2", "C"): False, ("q2", "N"): False}, qt,
            resp={("q1", "N"): "판 하나", ("q2", "N"): "판 판 판"})
say("금지어 수는 대화 답만 센다", r["banned_new"] == 1 and r["banned_cmp"] == 0)

# pair 선택 필드
fc = {"n1": {"meta": {"tags": ["dev"], "kind": "should", "type": "chat", "failure": ["format"], "clause": ["Z"]}, "prompt": "p", "criteria": "c"}}
say("pair 가 없는 과제는 필드 검사를 통과한다", lib["check_fields"](fc) == [])
fc["n1"]["meta"]["pair"] = "없는과제"
say("없는 과제를 가리키는 pair 는 실패한다", lib["check_pairs"](fc) != [])
# 단위별 기준 커밋과 시스템 프롬프트
ev = runpy.run_path(os.path.join(scripts, "_eval_run.py"))
qs3 = {f"b{i}": case(f"본문{i}", clause=["B-ONE"], kind=("should" if i else "should-not")) for i in range(3)}
bases = {"7a2d26d": "기본 줄\n", "abc1234": "기본 줄\n새 기준에만 있는 줄\n"}
ub = {"B-ONE": {"ids": ["B-ONE"], "current": "새 기준에만 있는 줄", "new": "n", "base": "abc1234", "system": None}}
say("base 가 있는 단위의 current.md 줄이 그 커밋 원칙에 있으면 오류가 없다", cl["check_units"](qs3, ub, bases) == [])
un = {"B-ONE": dict(ub["B-ONE"], base=None)}
e = cl["check_units"](qs3, un, bases)
say("base 가 없는 단위의 current.md 줄이 7a2d26d 에 없으면 오류 한 줄이다", len(e) == 1 and "기준 원칙" in e[0])
c1 = case("본문")
say("system.md 가 없는 단위의 gen_key 는 지금 식과 같다",
    gk(c1, "t") == cl["_sha"]("본문") + "-" + cl["_sha"]("t") and gk(c1, "t", None) == gk(c1, "t"))
say("system.md 가 있는 단위의 gen_key 는 다르다", gk(c1, "t", "S") != gk(c1, "t") and gk(c1, "t", "S") != gk(c1, "t", "T"))
cmd = ev["claude_cmd"]("p", "m", "시스템 문안")
say("system.md 가 있는 단위의 생성 명령에 --append-system-prompt 와 내용이 들어 있다",
    "--append-system-prompt" in cmd and cmd[cmd.index("--append-system-prompt") + 1] == "시스템 문안")
say("system 이 없으면 생성 명령에 --append-system-prompt 가 없다", "--append-system-prompt" not in ev["claude_cmd"]("p", "m"))
us = {"S-ONE": {"ids": ["S-ONE"], "current": None, "new": "n", "system": "SYS"}}
gs, _ = cl["plan_jobs"]({"s1": case("본문", clause=["S-ONE"])}, us, set(), set())
say("plan_jobs 는 system 을 키와 작업에 반영한다", all(x[0] == gk(case("본문"), x[3], "SYS") and x[4] == "SYS" for x in gs) and len(gs) == 2)
print("DONE")
