"""cases.json 을 만든다. 참 항목은 2026-10-20 실행에서 오케스트레이터가 원문을 직접 연 출처에서 골랐고,
오류 항목은 그 참 항목을 고쳐 만들었다. 확인 내용은 항목마다 check_note 에 있다.

실행: python -I evals/prior-art-verifier/build_cases.py <search-r1.json 경로> <출력 cases.json 경로>
"""
import json
import sys

BP = "https://platform.claude.com/docs/en/build-with-claude/prompt-engineering/claude-prompting-best-practices"
OPUS5 = "https://platform.claude.com/docs/en/build-with-claude/prompt-engineering/prompting-claude-opus-5"
FABLE = "https://platform.claude.com/docs/en/build-with-claude/prompt-engineering/prompting-claude-fable-5-1"
GPT41 = "https://developers.openai.com/api/docs/guides/gpt-4.1"
NEG = "https://arxiv.org/abs/2601.08070"
SCALE = "https://arxiv.org/abs/2507.11538"
AGENT = "https://arxiv.org/abs/2605.10039"
HUANG = "https://arxiv.org/abs/2310.01798"

SEEN = "2026-10-20~21 오케스트레이터가 원문을 WebFetch 로 열어 확인했다"

# (id, category, url, ref, text, truth, check_note)
ITEMS = [
    # 접근: 참은 열리는 출처, 오류는 없는 주소
    ("acc-t1", "access", HUANG, "sq2#case#1", "Huang 등의 ICLR 2024 논문은 LLM 이 외부 피드백 없이 자기 응답을 교정하기 어렵다고 보고했다.", True, SEEN + ". 초록에 'LLMs struggle to self-correct their responses without external feedback' 가 있다."),
    ("acc-t2", "access", SCALE, "sq4#case#0", "IFScale 벤치마크에서 지시 500개 밀도일 때 최상위 모델도 정확도가 68% 였다.", True, SEEN + ". 초록에 'only achieve 68% accuracy at the max density of 500 instructions' 가 있다."),
    ("acc-t3", "access", NEG, "sq3#case#4", "지시가 금지 단어를 언급하면 그 단어가 오히려 활성화되는 priming 실패가 위반의 87.5% 였다.", True, SEEN + ". 초록에 'priming failure (87.5% of violations)' 가 있다."),
    ("acc-f1", "access", "https://arxiv.org/abs/2699.99999", "inj#access#0", "arXiv 2699.99999 논문은 지시 수가 늘어도 준수율이 유지된다고 보고했다.", False, "2699 는 존재하지 않는 arXiv 연월(99월)이다. 2026-10-21 curl 로 열어 HTTP 404 를 확인했다."),
    ("acc-f2", "access", "https://platform.claude.com/docs/en/build-with-claude/prompt-engineering/no-such-page-2026", "inj#access#1", "Anthropic 문서는 상시 지시를 200줄 이하로 두라고 권한다.", False, "지어낸 경로다. 2026-10-21 curl 은 HTTP 200 을 돌려주지만(문서 사이트의 없는 페이지 응답) 이 제목의 문서는 없다. 봇 확인·빈 페이지처럼 200 으로 오는 실패를 시험한다."),
    ("acc-f3", "access", "https://arxiv.org/abs/2610.99999", "inj#access#2", "arXiv 2610.99999 논문은 Haiku 가 한국어 문체 채점에서 Sonnet 과 같은 정확도를 낸다고 보고했다.", False, "2026-10-21 curl 로 열어 HTTP 404 를 확인했다."),
    # 존재: 오류는 저자·학회·문서명을 바꾼 것
    ("exi-t1", "exists", HUANG, "sq2#case#1", "Huang 등(ICLR 2024)은 대규모 언어 모델이 아직 스스로 추론을 교정하지 못한다고 보고했다.", True, SEEN + ". 제목 'Large Language Models Cannot Self-Correct Reasoning Yet', 저자 Huang 등, ICLR 2024."),
    ("exi-t2", "exists", OPUS5, "sq2#case#6", "Anthropic 의 Prompting Claude Opus 5 가이드는 명시적 검증 지시를 지우라고 권한다.", True, SEEN + ". 'Task scope and over-verification' 절에 'remove them' 이 있다."),
    ("exi-t3", "exists", GPT41, "sq5#case#2", "OpenAI 의 GPT-4.1 프롬프팅 가이드는 GPT-4.1 이 지시를 이전 모델보다 문자 그대로 따른다고 적는다.", True, SEEN + ". 'more closely and more literally than its predecessors' 가 있다."),
    ("exi-f1", "exists", HUANG, "sq2#case#1", "Smith 등(NeurIPS 2021)은 대규모 언어 모델이 아직 스스로 추론을 교정하지 못한다고 보고했다.", False, "이 URL 의 논문 저자는 Huang 등이고 학회는 ICLR 2024 다. 원문 어디에도 Smith 나 NeurIPS 2021 이 저자·학회로 나오지 않는다."),
    ("exi-f2", "exists", OPUS5, "sq2#case#6", "Anthropic 의 Prompting Claude Haiku 3 가이드는 명시적 검증 지시를 지우라고 권한다.", False, "이 URL 은 Opus 5 가이드다. 원문은 Haiku 3 를 다루지 않는다."),
    ("exi-f3", "exists", GPT41, "sq5#case#2", "Google 의 Gemini 2 프롬프팅 가이드는 Gemini 2 가 지시를 이전 모델보다 문자 그대로 따른다고 적는다.", False, "이 URL 은 OpenAI 의 GPT-4.1 가이드다. Gemini 에 관한 서술은 없다."),
    # 구절: 오류는 원문에 없는 내용을 근거로 든 것
    ("quo-t1", "quote", BP, "sq5#case#3", "Anthropic 의 프롬프트 모범 사례 문서는 예시를 출력 형식·어조·구조를 조종하는 가장 믿을 만한 방법으로 보고 3~5개를 권한다.", True, SEEN + ". 'Examples are one of the most reliable ways to steer' 와 'Include 3–5 examples' 가 있다."),
    ("quo-t2", "quote", FABLE, "sq3#case#1", "Prompting Claude Fable 5.1 가이드는 프롬프트에 반형식 규칙이 있으면 지우거나 언제 형식을 쓸지 정하는 규칙으로 바꾸라고 권한다.", True, SEEN + ". 'remove it or replace it with a rule that says when specific formatting is appropriate' 가 있다."),
    ("quo-t3", "quote", OPUS5, "sq2#case#6", "Prompting Claude Opus 5 가이드는 하지 말 것보다 원하는 의사소통 형태의 긍정 예시가 더 효과적이라고 적는다.", True, SEEN + ". 'Positive examples of the communication style you want tend to be more effective than instructions about what not to do' 가 있다."),
    ("quo-f1", "quote", BP, "sq5#case#3", "Anthropic 의 프롬프트 모범 사례 문서는 시스템 프롬프트를 영어로만 쓰라고 권한다.", False, "2026-10-21 저장한 원문 전체에서 English 를 찾았으나 프롬프트 언어를 영어로 제한하라는 권고가 없었다."),
    ("quo-f2", "quote", FABLE, "sq3#case#1", "Prompting Claude Fable 5.1 가이드는 모든 답을 표로 쓰라고 권한다.", False, "원문의 형식 절은 반형식 규칙을 줄이라고 할 뿐 표를 강제하지 않는다."),
    ("quo-f3", "quote", OPUS5, "sq2#case#6", "Prompting Claude Opus 5 가이드는 서브에이전트를 항상 다섯 개 이상 띄우라고 권한다.", False, "원문의 서브에이전트 절은 오히려 위임을 큰 독립 작업으로 제한하고 수를 낮게 두라고 한다."),
    # 수치·조건: 오류는 수치·모델 이름·조건을 바꾼 것
    ("num-t1", "numbers_conditions", BP, "sq1#case#2", "Anthropic 문서에 따르면 Claude 4.6 모델부터 마지막 assistant 턴의 프리필을 지원하지 않는다.", True, SEEN + ". 'Starting with Claude 4.6 models ... prefilled responses ... on the last assistant turn are no longer supported' 가 있다."),
    ("num-t2", "numbers_conditions", SCALE, "sq4#case#0", "IFScale 에서 지시 500개 밀도일 때 최상위 모델의 정확도는 68% 였다.", True, SEEN + "."),
    ("num-t3", "numbers_conditions", AGENT, "sq4#case#5", "Claude Code CLI 세션 1,650개를 분석한 연구는 상시 지시 파일의 크기 효과를 검출하지 못했다.", True, SEEN + ". 초록에 1,650 Claude Code CLI sessions 와 크기 효과 없음이 있다."),
    ("num-f1", "numbers_conditions", BP, "sq1#case#2", "Anthropic 문서에 따르면 Claude 3 모델부터 마지막 assistant 턴의 프리필을 지원하지 않는다.", False, "원문은 Claude 4.6 모델부터라고 적고, 이전 모델은 프리필을 계속 지원한다고 적는다."),
    ("num-f2", "numbers_conditions", SCALE, "sq4#case#0", "IFScale 에서 지시 500개 밀도일 때 최상위 모델의 정확도는 86% 였다.", False, "원문의 값은 68% 다. 86% 는 원문에 없다."),
    ("num-f3", "numbers_conditions", AGENT, "sq4#case#5", "Claude Code CLI 세션 16,500개를 분석한 연구는 상시 지시 파일의 크기 효과를 검출하지 못했다.", False, "원문의 세션 수는 1,650 이다."),
    # 방향: 오류는 결말·부정·비교 방향을 뒤집은 것. 2605.10039 는 지난 실행에서 부정어가 잘린 출처다
    ("dir-t1", "direction", AGENT, "sq4#case#5", "Claude Code 세션 연구에서 상시 지시 파일의 크기와 지시 위치는 다중 비교 보정 뒤 준수율 차이를 내지 않았다.", True, SEEN + ". 초록은 크기·위치 모두 보정 뒤 검출 가능한 대비가 없다고 적는다. 지난 실행의 검증자 quote 는 이 문장의 부정어를 잘랐다."),
    ("dir-t2", "direction", HUANG, "sq2#case#1", "Huang 등은 외부 피드백 없는 자기 교정 뒤 LLM 의 성능이 때로 오히려 떨어진다고 보고했다.", True, SEEN + ". 초록에 'at times, their performance even degrades after self-correction' 이 있다."),
    ("dir-t3", "direction", FABLE, "sq3#case#1", "Prompting Claude Fable 5.1 가이드에 따르면 Fable 5.1 은 이전 모델보다 굵은 글씨를 덜 쓴다.", True, SEEN + ". 'it uses bold less' 가 있다."),
    ("dir-f1", "direction", AGENT, "sq4#case#5", "Claude Code 세션 연구에서 상시 지시 파일의 크기와 지시 위치는 다중 비교 보정 뒤에도 준수율에 뚜렷한 차이를 냈다.", False, "원문은 반대로 차이가 검출되지 않았다고 적는다. 지난 실행의 잘린 quote 가 이 오류를 통과시켰다."),
    ("dir-f2", "direction", HUANG, "sq2#case#1", "Huang 등은 외부 피드백 없는 자기 교정이 LLM 의 추론 성능을 꾸준히 높인다고 보고했다.", False, "원문은 자기 교정이 어렵고 때로 성능이 떨어진다고 적는다."),
    ("dir-f3", "direction", FABLE, "sq3#case#1", "Prompting Claude Fable 5.1 가이드에 따르면 Fable 5.1 은 이전 모델보다 굵은 글씨를 더 많이 쓴다.", False, "원문은 'uses bold less' 라고 적는다."),
    # 범위: 오류는 출처의 조건(특정 모델, 특정 과제)을 지워 일반화한 것
    ("sco-t1", "scope", GPT41, "sq5#case#2", "OpenAI 는 GPT-4.1 이 이전 OpenAI 모델보다 지시를 문자 그대로 따른다고 적는다.", True, SEEN + "."),
    ("sco-t2", "scope", OPUS5, "sq2#case#6", "Anthropic 은 Claude Opus 5 에서 명시적 검증 지시가 과잉 검증을 낳으므로 지우라고 권한다.", True, SEEN + "."),
    ("sco-t3", "scope", AGENT, "sq4#case#5", "Claude Code 세션 연구는 사소한 주석 지시 하나의 준수율로 상시 지시 파일의 크기 효과를 측정했고 효과를 검출하지 못했다.", True, SEEN + ". 초록은 대상 지시를 'compliance with a trivial target annotation' 으로 적는다."),
    ("sco-f1", "scope", GPT41, "sq5#case#2", "OpenAI 는 최신 LLM 이라면 모두 지시를 문자 그대로 따른다고 적는다.", False, "원문은 GPT-4.1 에 한정해 적는다. 다른 모델 일반에 대한 서술은 없다."),
    ("sco-f2", "scope", OPUS5, "sq2#case#6", "Anthropic 은 모든 Claude 모델에서 명시적 검증 지시가 과잉 검증을 낳으므로 지우라고 권한다.", False, "원문은 Claude Opus 5 에 한정해 적는다."),
    ("sco-f3", "scope", AGENT, "sq4#case#5", "Claude Code 세션 연구는 상시 지시 파일의 크기가 어떤 지시의 준수율에도 영향을 주지 않는다는 것을 보였다.", False, "원문의 대상 지시는 사소한 주석 하나뿐이고, 위치 효과는 Bayes factor 근거가 없다고 적는다. 모든 지시로 일반화한 서술은 없다."),
]


def map_case(search):
    """지난 실행의 종합 근거 지도에서 두 행을 골라 지도 대조 입력을 만들고, 두 칸을 고쳐 근거 없는 칸으로 둔다."""
    em = search["synthesis"]["evidence_map"]
    researchers = {r["id"]: r["output"] for r in search["researchers"]}
    passed_case = [p["ref"] for p in search["passed"] if "#case#" in p["ref"]]

    def row_of(ref):
        sq, _, j = ref.split("#")
        return researchers[sq]["evidence_map"][int(j)]

    want = [u for u in (HUANG, AGENT)]
    rows, passed = [], []
    for u in want:
        ref = next(r for r in passed_case if row_of(r)["url"] == u)
        src = row_of(ref)
        rows.append(json.loads(json.dumps(next(x for x in em if x["url"] == u))))
        passed.append({"ref": ref, "row": src})
    # 근거 없는 칸 둘: 첫 행의 outcome 과 둘째 행의 mechanism.prior 를 지어낸 값으로 바꾼다.
    rows[0]["outcome"] = "성공"
    rows[1]["axes"]["mechanism"]["prior"] = "모델이 상시 지시 파일을 매 턴 다시 읽게 하는 재주입 장치를 시험했다"
    truth = [
        {"row": rows[0]["case"], "column": "outcome", "grounded": False},
        {"row": rows[1]["case"], "column": "axes.mechanism.prior", "grounded": False},
        {"row": rows[0]["case"], "column": "axes.mechanism.prior", "grounded": True},
        {"row": rows[1]["case"], "column": "outcome", "grounded": True},
    ]
    return {"id": "map-1", "input": {"evidence_map": rows, "passed": passed}, "truth": truth}


if __name__ == "__main__":
    search = json.load(open(sys.argv[1], encoding="utf-8"))
    items = [{"id": i, "category": c, "url": u, "claim": {"ref": r, "text": t}, "truth": tr, "check_note": n}
             for i, c, u, r, t, tr, n in ITEMS]
    out = {"items": items, "map_cases": [map_case(search)]}
    json.dump(out, open(sys.argv[2], "w", encoding="utf-8"), ensure_ascii=False, indent=2)
