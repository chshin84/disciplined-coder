# run_measure.py: NO-RAW-OUTPUT 소유 문장의 클린룸 시험. 조건(current·new) × 과제 셋을 도구 없는 claude -p 로
# 저장소 밖 임시 폴더에서 실행하고 응답 원문을 runs/ 에 남긴다.
# 사용: python -I -X utf8 run_measure.py
import json, os, subprocess, tempfile
from concurrent.futures import ThreadPoolExecutor
D = os.path.dirname(os.path.abspath(__file__))
RUNS = os.path.join(D, "runs"); os.makedirs(RUNS, exist_ok=True)
principle = {c: open(os.path.join(D, f"principle-{c}.md"), encoding="utf-8").read() for c in ("current", "new")}
groups = open(os.path.join(D, "lens-groups.md"), encoding="utf-8").read()
tasks = {
    "spec": "방금 docs/superpowers/specs/ 에 새 spec 을 썼다. 결제 실패를 재시도하는 방식을 처음 도입하는 설계이고, 이 팀은 이런 방식을 해 본 적이 없다. 너는 사용자와 대화하는 메인 세션이다.",
    "guide": "고객에게 보낼 서비스 변경 안내서를 마크다운으로 다 썼다. 나중에 PDF 로 바꿔 보낸다. 읽는 사람은 고객이고, 고객은 이 글을 읽고 변경 일정에 맞춰 대비할 수 있어야 한다. 너는 사용자와 대화하는 메인 세션이다.",
    "subspec": "너는 큰 개발을 나눠 맡은 서브 세션이고 사용자와 대화할 수 없다. 방금 네 워크스트림의 하부 명세(spec)를 썼다. 하부 명세는 사내에서 처음 쓰는 캐시 무효화 방식을 도입한다.",
    "audit": "사용자가 이 저장소의 살아 있는 문서 전체(README, 스킬 문서 20여 개, 원칙 문서)를 점검해 달라고 했다. 너는 사용자와 대화하는 메인 세션이고 레포 감사 절차(audit-repo-docs)를 따른다.",
    "proposal": "경영진에게 보낼 제안서를 다 썼다. 사내 결재 절차를 새 방식(승인 단계를 줄이고 사후 감사로 바꾸는 방식)으로 바꾸자고 제안하고, 그 효과로 처리 기간이 절반으로 준다고 주장한다. 읽는 사람은 경영진이고, 경영진은 이 글을 읽고 도입 여부를 정할 수 있어야 한다. 너는 사용자와 대화하는 메인 세션이다.",
}
HEAD = ("어떤 도구도 쓰지 말고 이 메시지만으로 답하라. 아래 '원칙'과 '렌즈 그룹' 문서만 근거로 삼아라. "
        "상황의 산출물을 결과로 삼기 전에 어느 렌즈를 실행하고, 필요할 때 렌즈를 제안하는지 정하라. 실제로 실행하지는 마라. "
        '결과는 JSON {"lenses_to_run": ["..."], "proposals": [{"lens": "...", "action": "제안|제안 안 함|판정만 기록", "reason": "..."}], '
        '"authority": "이 결정의 근거로 삼은 문서와 절", "ambiguity": "규칙이 모호하거나 문서끼리 다르다고 느낀 점, 없으면 빈 문자열"} 하나로만 돌려줘라.')
import sys
only = sys.argv[1:]
jobs = [(c, t) for c in ("current", "new") for t in tasks if not only or t in only]
work = tempfile.mkdtemp(prefix="measure-")
def run(job):
    c, t = job
    prompt = HEAD + "\n\n상황:\n" + tasks[t] + "\n\n원칙:\n" + principle[c] + "\n\n렌즈 그룹:\n" + groups
    p = subprocess.run(["claude", "-p", "--tools", "", "--setting-sources", "", "--no-session-persistence",
                        "--output-format", "json"], input=prompt.encode("utf-8"), capture_output=True, cwd=work, timeout=900)
    try:
        d = json.loads(p.stdout.decode("utf-8"))
    except json.JSONDecodeError:
        d = {"result": p.stdout.decode("utf-8", "replace"), "num_turns": None, "is_error": True}
    open(os.path.join(RUNS, f"{c}__{t}.txt"), "w", encoding="utf-8").write(d.get("result") or "")
    return {"run": f"{c}__{t}", "num_turns": d.get("num_turns"), "is_error": d.get("is_error"),
            "models": list(d.get("modelUsage", {}).keys())}
with ThreadPoolExecutor(max_workers=6) as ex:
    metas = list(ex.map(run, jobs))
with open(os.path.join(D, "runs.log"), "a", encoding="utf-8") as f:
    for m in metas: f.write(json.dumps(m, ensure_ascii=False) + "\n")
print(json.dumps(metas, ensure_ascii=False))
