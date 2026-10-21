"""cases.json 을 만든다. 참 항목은 2026-10-20 실행에서 오케스트레이터가 원문을 직접 연 출처에서 골랐고,
오류 항목은 그 참 항목을 고쳐 만들었다. 확인 내용은 항목마다 check_note 에 있다.

실행: python -I evals/prior-art-verifier/build_cases.py <search-r1.json 경로> <출력 cases.json 경로> [--v2 <출력 cases-v2.json 경로>] [--v3 <출력 cases-v3.json 경로>]

--v2 는 재측정 자료 cases-v2.json 을 함께 만든다. cases.json 의 항목에서 num-t3 를 오류 항목으로 바꾸고,
수치·조건 참 항목 둘과 어려운 항목(hard_kind 마다 참 1건, 오류 1건)을 더한다. 어려운 항목의 출처는
2026-10-21 구현자가 원문을 WebFetch 로 직접 열어 확인했고, 확인 내용은 항목마다 check_note 에 있다.

--v3 는 cases-v2.json 에서 파생한 재측정 자료 cases-v3.json 을 만든다(--v2 와 함께 쓴다). id 는 바꾸지 않는다.
quo-t1·quo-t3·hard-f200-t1 은 원문의 완화 표현을 빼 범위를 넓힌 주장이라 인용 판정 기준에서 기각이 맞으므로
오류 항목으로 바꾼다(2026-10-21 사용자 결정, num-t3 와 같은 처리). 이어서 카테고리마다 참·오류 수를 맞추려고
quote 참 4건과 access 참 2건(fake-200 참 1건 포함)을 더한다. hard-f200-t1 은 실제 문서의 완화 표현 문제이므로
fake-200 이 아니게 되어 hard_kind 를 뗀다.
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


SEEN2 = "2026-10-21 구현자가 원문을 WebFetch 로 직접 열어 확인했다"
IFSCALE_HTML = "https://arxiv.org/html/2507.11538"
INSTR = "https://arxiv.org/abs/2601.13244"
WIKI = "https://ko.wikipedia.org/wiki/구글_딥마인드_챌린지_매치"
AWS_REAL = "https://docs.aws.amazon.com/bedrock/latest/userguide/prompt-engineering-guidelines.html"
AWS_FAKE = "https://docs.aws.amazon.com/bedrock/latest/userguide/prompt-instruction-limit-guidelines.html"

NUM_T3_NOTE = ("주장이 원문의 '다중 비교 보정 뒤' 조건을 빠뜨렸고, 1,650 과 결과가 서로 다른 문장에 있다(결정 기록 2). "
               "그래서 구절 하나가 주어·수치·조건을 모두 포함해야 하는 인용 판정 기준에서 기각이 맞다. 지난 시험에서 참으로 둔 라벨이 느슨했다.")

# v2 에서 추가하는 수치·조건 참 항목: num-t3 를 오류로 바꾼 만큼 참 두 건으로 4건씩 맞춘다
V2_NUM = [
    ("num-t4", "numbers_conditions", AGENT, "v2#num#0", "한 연구는 Claude Code CLI 세션 1,650개에서 사소한 대상 주석(trivial target annotation)의 준수 여부를 측정했다.", True, SEEN2 + ". 초록의 한 문장에 'measuring compliance with a trivial target annotation across 1,650 Claude Code CLI sessions' 가 있어 세션 수와 측정 대상이 한 문장으로 뒷받침된다."),
    ("num-t5", "numbers_conditions", SCALE, "v2#num#1", "IFScale 벤치마크는 7개 제공사의 모델 20개를 평가했다.", True, SEEN2 + ". 초록에 20 leading models, seven providers 가 있다(모델 20개, 제공사 7곳)."),
]

# 어려운 항목: hard_kind 마다 참 1건, 오류 1건. 마지막 칸이 hard_kind
V2_HARD = [
    ("hard-ctx-t1", "direction", INSTR, "v2#hard#0", "Munjal 등의 연구는 지시 튜닝의 이점이 모델 파라미터 수와 평가 설정에 크게 좌우되며 소형 모델에서는 큰 이득을 준다고 결론지었다.", True,
     SEEN2 + "(arxiv.org/abs 와 /html 두 번 조회해 같은 구절을 얻었다). 저자는 Prateek Munjal, Clement Christophe, Ronnie Rajan, Praveenkumar Kanithi 이며 첫 저자가 Munjal 이다. 이 논문의 초록은 기본 모델이 일관되게 앞선다는 쪽으로 읽힌다(base models consistently outperform instruction-tuned variants). 그러나 §5 결론에 'instruction tuning provides substantial gains for SLMs, while its impact on LLMs is mixed and often marginal' 와 'depend strongly on number of parameters and evaluation setting' 이 있다.", "context"),
    ("hard-ctx-f1", "direction", INSTR, "v2#hard#1", "Munjal 등의 연구는 모든 규모의 모델에서 기본 모델이 지시 튜닝 모델보다 수학 벤치마크 성적이 일관되게 높다고 보고했다.", False,
     SEEN2 + "(arxiv.org/abs 와 /html 두 번 조회해 같은 구절을 얻었다). 초록만 보면 맞아 보인다(base models consistently outperform instruction-tuned variants). 본문은 이를 뒷받침하지 않는다. §4.1 에 'LLaMA3-3B improves from 29.0% to 67.2%' 처럼 소형 모델의 큰 지시 튜닝 이득과 'At >70B scale, base models perform competitively (Math-500) and superior (GSM8K)' 가 있고, §5 결론은 'substantial gains for SLMs' 라고 적는다. 어느 구절도 모든 규모에서 기본 모델이 높다고 적지 않는다.", "context"),
    ("hard-cnd-t1", "numbers_conditions", INSTR, "v2#hard#2", "Math-500 벤치마크에서 LLaMA3-3B 의 정확도는 기본 모델 29.0% 에서 지시 튜닝 모델 67.2% 로 올랐다.", True,
     SEEN2 + ". §4.1 에 'LLaMA3-3B improves from 29.0% to 67.2%' 가 있고, 29.0% 가 기본 모델, 67.2% 가 지시 튜닝 모델, 벤치마크는 Math-500 이다(Table S2). 모델·벤치마크·방향 세 조건이 한 대목에 있다.", "conditions"),
    ("hard-cnd-f1", "numbers_conditions", INSTR, "v2#hard#3", "Math-500 벤치마크에서 지시 튜닝은 모델 규모와 무관하게 정확도를 29.0% 에서 67.2% 로 올렸다.", False,
     SEEN2 + ". 29.0% 에서 67.2% 는 LLaMA3-3B 한 모델의 값이다. 조건 하나(모델 규모)만 일반화했다. 같은 §4.1 의 'At >70B scale, base models perform competitively (Math-500)' 와 결론의 'impact on LLMs is mixed and often marginal' 이 규모와 무관한 상승을 뒷받침하지 않는다.", "conditions"),
    ("hard-tbl-t1", "numbers_conditions", IFSCALE_HTML, "v2#hard#4", "IFScale 부록 Table 1 에서 claude-3.5-haiku 의 지시 100개 밀도 정확도는 43.4% 다.", True,
     SEEN2 + ". 부록 Table 1(Full Results)의 claude-3.5-haiku 행, 열 100 의 Accuracy 가 43.4% 다. 두 번 조회해 같은 값을 얻었다. 이 값은 본문 문장에 없고 표에만 있다(본문은 같은 모델을 'steep performance drops' 로만 서술한다).", "table"),
    ("hard-tbl-f1", "numbers_conditions", IFSCALE_HTML, "v2#hard#5", "IFScale 부록 Table 1 에서 claude-3.5-haiku 의 지시 100개 밀도 정확도는 94.8% 다.", False,
     SEEN2 + ". 94.8% 는 같은 표의 claude-3.7-sonnet 행, 열 100 의 값이다(두 번 조회해 확인). claude-3.5-haiku 의 열 100 값은 43.4% 이고, 본문 어디에도 claude-3.5-haiku 의 100개 정확도로 94.8% 를 적지 않는다.", "table"),
    ("hard-kor-t1", "direction", WIKI, "v2#hard#6", "한국어 위키백과는 구글 딥마인드 챌린지 매치의 최종 결과를 알파고가 이세돌에게 4승 1패로 이긴 것으로 서술한다.", True,
     SEEN2 + ". 한국어 원문에 '최종 결과는 알파고가 4승 1패로 이세돌에게 승리하였다.' 가 있고, 대국표는 이세돌의 승리를 제4국(백, 180수 불계승)으로 적는다.", "korean"),
    ("hard-kor-f1", "direction", WIKI, "v2#hard#7", "한국어 위키백과는 구글 딥마인드 챌린지 매치의 최종 결과를 이세돌이 알파고에게 4승 1패로 이긴 것으로 서술한다.", False,
     SEEN2 + ". 결말을 뒤집은 주장이다. 원문의 최종 결과는 알파고의 4승 1패 승리이고, 이세돌의 승리는 제4국 한 판이다. 원문의 다른 구절에도 이세돌이 4승을 거뒀다는 서술이 없다.", "korean"),
    ("hard-f200-t1", "access", AWS_REAL, "v2#hard#8", "AWS 의 Amazon Bedrock 프롬프트 엔지니어링 문서는 몇 개의 예시를 주는 few-shot 프롬프팅이 모델 출력을 기대에 맞추는 데 유용하다고 적는다.", True,
     SEEN2 + ". 같은 사이트(docs.aws.amazon.com)의 실제 문서다. 제목 'Prompt engineering concepts', 본문에 'It is sometimes useful to provide a few examples to help LLMs better calibrate their output' 가 있다.", "fake-200"),
    ("hard-f200-f1", "access", AWS_FAKE, "v2#hard#9", "AWS 의 Amazon Bedrock 문서는 프롬프트에 지시가 20개를 넘으면 정확도가 급격히 떨어진다고 적는다.", False,
     SEEN2 + ". 지어낸 경로다. curl 은 302 로 /bedrock/latest/userguide/ 로 보낸 뒤 최종 HTTP 200(2,257바이트)을 돌려준다. WebFetch 는 본문 없이 'Amazon Bedrock' 한 줄만 반환하고, 오류·리디렉션 안내도 없다. 지시 한도에 관한 문서 내용이 전혀 없다. 200 으로 오지만 실제 문서가 없는 주소다.", "fake-200"),
]


def v2_items():
    """cases.json 항목에서 num-t3 를 오류로 바꾸고 재측정용 항목을 더한다."""
    out = []
    for i, c, u, r, t, tr, n in ITEMS:
        if i == "num-t3":
            tr, n = False, NUM_T3_NOTE
        out.append({"id": i, "category": c, "url": u, "claim": {"ref": r, "text": t}, "truth": tr, "check_note": n})
    for i, c, u, r, t, tr, n in V2_NUM:
        out.append({"id": i, "category": c, "url": u, "claim": {"ref": r, "text": t}, "truth": tr, "check_note": n})
    for i, c, u, r, t, tr, n, k in V2_HARD:
        out.append({"id": i, "category": c, "url": u, "claim": {"ref": r, "text": t}, "truth": tr, "check_note": n, "hard_kind": k})
    return out


SEEN3 = "2026-10-21 구현자가 원문을 WebFetch 로 직접 열어 확인했다"
V3_RELABEL = {
    "quo-t1": ("'one of the most reliable ways to steer'",
               "원문은 'Examples are one of the most reliable ways to steer Claude's output format, tone, and structure' 이고 '3–5 examples' 는 'for best results' 라는 조건이 붙는다. 주장은 'one of' 를 빼 '가장 믿을 만한 방법'으로 바꿨다"),
    "quo-t3": ("'tend to be more effective'",
               "원문은 'Positive examples of the communication style you want tend to be more effective than instructions about what not to do' 다. 주장은 'tend to' 를 빼 '더 효과적'이라고 단정했다"),
    "hard-f200-t1": ("'sometimes useful'",
                     "원문은 'It is sometimes useful to provide a few examples to help LLMs better calibrate their output' 다. 주장은 'sometimes' 를 빼 '유용하다'고 단정했다"),
}
OPUS5_NOTE = SEEN3 + ". Opus 5 가이드 원문에서 아래 구절을 찾았고, 한 구절이 주장의 모든 요소를 포함한다."
V3_NEW = [
    ("quo-t4", "quote", OPUS5, "v3#quo#0", "Prompting Claude Opus 5 가이드는 Opus 5 가 이전 모델보다 서브에이전트에 더 쉽게 위임한다고 적는다.", True,
     OPUS5_NOTE + " 'Claude Opus 5 delegates to subagents more readily than prior models.' 한 문장에 모델·행동·비교 대상이 모두 있고 완화 표현이 없다.", None),
    ("quo-t5", "quote", OPUS5, "v3#quo#1", "Prompting Claude Opus 5 가이드는 Opus 5 의 컨텍스트 윈도가 1M 토큰이고 이 크기가 기본값이자 최대값이라고 적는다.", True,
     OPUS5_NOTE + " 'Claude Opus 5 has a 1M token context window as both the default and the maximum' 한 문장에 크기·기본·최대가 모두 있다.", None),
    ("quo-t6", "quote", OPUS5, "v3#quo#2", "Prompting Claude Opus 5 가이드는 Opus 5 에서 사고 비활성화는 effort 가 high 이하일 때만 가능하고, xhigh 나 max 와 함께 요청하면 400 오류를 낸다고 적는다.", True,
     OPUS5_NOTE + " 'thinking can be disabled only at effort `high` or below. A request that combines `thinking: {\"type\": \"disabled\"}` with effort `xhigh` or `max` returns a 400 error.' 한 문단 안의 연속한 두 문장에 두 조건이 모두 있고 완화 표현이 없다.", None),
    ("quo-t7", "quote", OPUS5, "v3#quo#3", "Prompting Claude Opus 5 가이드는 Opus 5 가 사고를 끈 상태에서 도구 호출을 구조화된 tool_use 블록 대신 사용자에게 보이는 텍스트로 가끔 쓴다고 적는다.", True,
     OPUS5_NOTE + " 'With thinking disabled, the model occasionally writes a tool call into its user-facing text instead of emitting a structured `tool_use` block.' 한 문장에 조건·행동·빈도('occasionally')가 모두 있고 주장도 '가끔'으로 빈도를 보존했다.", None),
    ("acc-t4", "access", OPUS5, "v3#acc#0", "Prompting Claude Opus 5 가이드는 Opus 5 에서 low 와 medium effort 가 높은 설정보다 적은 토큰과 지연으로 강한 품질을 낸다고 적는다.", True,
     OPUS5_NOTE + " '`low` and `medium` effort produce strong quality at a fraction of the tokens and latency of higher settings.' 한 문장에 모든 요소가 있다. 열리는 출처의 참 항목이며 hard_kind 는 없다.", None),
    ("hard-f200-t2", "access", "https://docs.aws.amazon.com/bedrock/latest/userguide/what-is-bedrock.html", "v3#hard#0", "AWS 의 Amazon Bedrock 개요 문서는 Bedrock 을 주요 AI 기업의 파운데이션 모델에 안전한 엔터프라이즈급 접근을 제공하는 완전 관리형 서비스로 소개한다.", True,
     SEEN3 + ". hard-f200-f1 과 같은 사이트(docs.aws.amazon.com)의 실제 문서다. 제목 'Overview', 첫 문장 'Amazon Bedrock is a fully managed service that provides secure, enterprise-grade access to high-performing foundation models from leading AI companies' 한 문장에 주장의 모든 요소가 있고 완화 표현이 없다.", "fake-200"),
]


def v3_items():
    """v2 항목에서 완화 표현을 뺀 참 항목 셋을 오류로 바꾸고, 균형용 참 항목을 더한다."""
    out = []
    for x in v2_items():
        x = dict(x)
        if x["id"] in V3_RELABEL:
            hedge, detail = V3_RELABEL[x["id"]]
            x["truth"] = False
            x["check_note"] = f"{detail}. 주장이 원문의 완화 표현({hedge})을 빼 범위를 넓혔다. 인용 판정 기준에서 기각이 맞다(2026-10-21 사용자 결정). {SEEN3}."
            x.pop("hard_kind", None)
        out.append(x)
    for i, c, u, r, t, tr, n, k in V3_NEW:
        d = {"id": i, "category": c, "url": u, "claim": {"ref": r, "text": t}, "truth": tr, "check_note": n}
        if k:
            d["hard_kind"] = k
        out.append(d)
    return out


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
    if "--v2" in sys.argv:
        v2 = {"items": v2_items(), "map_cases": out["map_cases"]}
        json.dump(v2, open(sys.argv[sys.argv.index("--v2") + 1], "w", encoding="utf-8"), ensure_ascii=False, indent=2)
    if "--v3" in sys.argv:
        v3 = {"items": v3_items(), "map_cases": out["map_cases"]}
        json.dump(v3, open(sys.argv[sys.argv.index("--v3") + 1], "w", encoding="utf-8"), ensure_ascii=False, indent=2)
