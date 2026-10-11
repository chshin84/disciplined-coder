# 기대 분할 정정 기록

2차 측정 뒤 two-jobs 의 새 규칙 실행 5회가 모두 faqindex 와 faqsearch 를 합쳤다. 현재 세션은 판정 이유(색인의 형태소 분석·구조와 검색 질의 분석이 색인 의미를 함께 정해야 한다)가 실제 결합이라고 보고, 결과를 본 뒤 정답을 고치면 측정이 유리해지는 편향이 생긴다는 점과 함께 사용자에게 알렸다. 2026-10-11 에 사용자가 two-jobs 의 기대 분할을 `[["logarchive"],["logretention"],["faqindex","faqsearch"]]` 로 정정하는 안을 골랐다. 나머지 다섯 요청의 기대 분할과 실행 출력은 바꾸지 않았고, `score_amended.py` 가 `expected-amended.json` 으로 다시 채점했다.
