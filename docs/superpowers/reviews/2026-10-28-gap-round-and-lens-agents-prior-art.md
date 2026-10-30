# 공백 라운드와 렌즈 에이전트 분리 — 선행연구 기록

## 발동과 승인

사용자가 2026-10-28 대화에서 선행연구 공백 라운드의 쓸모와, 렌즈를 플러그인 에이전트 정의로 옮긴 구조가 활용성을 높이는지 과도한 분해인지를 물었다. 이어서 "이러한 구성이나, 선행연구를 위한 에이전트는 사람들이 많이 논의하고 있을것 같은데. 선행조사좀 해줘"라고 직접 요청했다. 오케스트레이터가 아래 프로토콜을 보였고, 사용자는 같은 날 "이대로 실행"을 골랐다.

계기는 같은 대화의 대조 결과다. 공백 판단 절이 있는 선행연구 기록 다섯 건(2026-10-20 generation-constraints, 2026-10-23 harness-gaps, 2026-10-24 review-checklist, 2026-10-27 spec-review-novelty, 2026-10-27 tone-manner)에서 공백 라운드를 실행한 건은 없었다.

## 프로토콜

- 연구 질문: (1) 다중 에이전트 조사 시스템에서 첫 탐색 뒤 공백만 재탐색하는 추가 라운드는 비용 대비 근거를 늘리는가, 그리고 어떤 공백 유형에서 효과가 있는가. (2) LLM 리뷰 역할을 도구와 모델이 고정된 서브에이전트 정의로 분리하는 방식은 프롬프트 템플릿 방식보다 비용·재현성·사용성에서 나은가, 그리고 분해가 과해지는 기준은 무엇인가.
- 상황: 결정 근거 탐색.
- 모드: survey.
- 대조 대상(결정 후보안): 질문 (1)은 A1 현행(매번 묻고 1회까지), A2 탐색 부족형 공백에만 권함, A3 삭제. 질문 (2)는 B1 현행(정의 분리와 실행 규칙 파일), B2 실행 규칙 축소(MODE 기본값을 정의로 옮김), B3 과거 방식(범용 서브에이전트에 프롬프트 전달).
- intended_use: 사용자가 공백 라운드 절차와 렌즈 실행 구조를 바꿀지 정한다. 기준은 작업당 비용(토큰·시간·사용자 질문 수) 대비 반영되는 근거와 지적, 그리고 사람이 구조를 한 번에 이해할 수 있는지다.
- constraints: 공백 라운드 1회 상한의 근거(Anthropic deep-research 스킬), 2026-10-25 렌즈 전환 조사·런타임 시험 기록, 공백 라운드 실행 0건(다섯 건 중), 렌즈 1회 약 10만 토큰은 이미 확인한 자료다.

| ID | 범위 | 포함 | 제외 |
|---|---|---|---|
| sq1 | 반복 탐색에서 추가 라운드의 한계 효용과 중단 기준 | deep research agent 평가, iterative retrieval, search saturation·stopping rule, information foraging | 단일 RAG 질의 최적화 |
| sq2 | 공백 유형(자료 부재와 탐색 부족)을 구분해 재탐색 여부를 정하는 방법 | systematic review 의 검색 중단 규칙, coverage 추정, gap detection | 문헌 관리 도구 사용법 |
| sq3 | 역할별 서브에이전트 분리의 효과와 비용 | 맥락 격리, 도구 제한, 역할 특화, 토큰 비용 측정 | 강화학습 기반 다중 에이전트 |
| sq4 | 다중 에이전트·프롬프트 구조의 과도한 분해 실패와 판단 기준 | multi-agent failure taxonomy, coordination overhead, single agent 와 multi agent 비교 | 사람 조직 설계 연구 |

- 질의 금지 목록: 제품·기능 이름 범주(이 저장소의 플러그인 이름과 한글 별칭 3개, 렌즈·스킬·에이전트 이름 17개, 내부 용어 1개), 회사 이름 범주 3개, 사람 식별자 범주 3개, 조항 ID 범주 49개(공개 일반 용어인 YAGNI 는 뺐다).
- 둘러보기: 실행한다(기본값).
- 공백 라운드: 첫 탐색 뒤 탐색 부족형 공백(partial·연구자 실패)이 있을 때만 권하고, 포화형 공백은 보고에 적는다.
- 탐색 모드 연구자 수: 4. 통상값 2를 넘는 이유는 하위 질문 네 개의 분야(정보검색, 체계적 문헌고찰, 에이전트 설계, 실패 분석)가 달라 묶으면 검색어가 흐려지기 때문이다.
- principles_path: D:\projects\disciplined-coder\agent-principles.md

## 둘러보기

둘러보기(r0)를 실행했다. `search_status` 는 `ok`, 질의 경계 위반은 없다. 원본은 같은 이름의 폴더의 `search-r0.json`·`researcher-scout-r0.json` 에 있다.

## 두 번째 승인(하위 질문 변경)

둘러보기 결과로 오케스트레이터가 아래 칸을 바꿔 보였고, 사용자는 2026-10-28 "변경안으로 실행"을 골랐다.

| ID | 범위 | 포함 | 제외 |
|---|---|---|---|
| sq1 | 반복 탐색에서 추가 라운드의 한계 효용과 중단 기준, 중단 신호별(고정 상한, 반복별 정보 이득, LLM 자기 판정) 효과 비교 | deep research agent 평가, iterative retrieval, search saturation·stopping rule, information foraging | 단일 RAG 질의 최적화 |
| sq2 | 공백 유형(자료 부재와 탐색 부족)을 구분해 재탐색 여부를 정하는 방법 | systematic review 의 검색 중단 규칙, coverage 추정, gap detection, 근거 충분성 판정과 확인 불가 시 판정 보류, capture-recapture 누락 추정 | 문헌 관리 도구 사용법 |
| sq5 | LLM 리뷰를 전문 리뷰어 여럿으로 나눌 때 리뷰어 수에 따른 한계 효용과 오탐, 같은 리뷰어 재실행과 다른 리뷰어 추가의 차이 | multi-agent code review, specialized reviewer agents, LLM-as-judge ensemble, 재실행 변동 | 사람 코드 리뷰만 다룬 연구 |

- 탐색 모드 연구자 수: 5. sq5 는 렌즈 구조 판단에 쓸 외부 기준선이라 다른 하위 질문과 묶지 않는다.
- sq3·sq4 는 바꾸지 않았다.

## 첫 탐색 결과

원본은 같은 이름의 폴더의 `search-r1.json`, `researcher-sq1-r1.json`~`researcher-sq5-r1.json`, `verifier-r1.json`, `synthesis-r1.json`, `map-check-r1.json` 에 있다. 검색어에 금지 낱말이 없어 가린 칸은 없다.

| 하위 질문 | 찾은 사례 | 통과 | `search_status` | `verification_status` | `saturation` |
|---|---|---|---|---|---|
| sq1 | 9 | 3 | ok | partial | 값 없음 |
| sq2 | 9 | 4 | ok | partial | 2 |
| sq3 | 11 | 0 | ok | partial | 3 |
| sq4 | 10 | 5 | ok | partial | 1 |
| sq5 | 10 | 3 | ok | partial | 3 |

- `overall_status`: not-ok. 그래서 오케스트레이터는 결과를 판정에 쓰지 않고 보고에만 적는다.
- 통과(15건): sq1#case#0, sq1#case#2, sq1#case#4, sq2#issue#0, sq2#case#1, sq2#case#4, sq2#case#7, sq4#issue#0, sq4#case#1, sq4#case#4, sq4#case#6, sq4#case#7, sq5#issue#0, sq5#issue#1, sq5#case#1.
- 탈락(15건): 사유는 `verifier-r1.json` 에 있다.
- 판정 불가: 없음.
- 검증 실패: URL 16개(목록은 `search-r1.json` 의 `verify_failed`).
- 질의 경계 위반: 0건. 지도 대조: 근거 없는 칸 0개. 검증에 보낸 URL 37개, 에이전트 68개, 서브에이전트 토큰 3,134,143, 실행 시간 약 17분.

## 공백 라운드

실행하지 않았다(2026-10-28 사용자 결정). 오케스트레이터가 검증 실패 URL 16개의 단계 출력을 확인했고, 16개 모두 추출은 `access` 성공·`exists` 일치였다. 실패 원인은 보충 뒤 재판정에도 `정보 부족`이 남은 것이었다. 연구자가 한 주장에 수치·조건·구조를 함께 넣어 원문 여러 문장에 흩어진 요소를 한 구절로 받칠 수 없었다. 재탐색은 판정 방식을 바꾸지 않으므로 오케스트레이터는 실행하지 않는 안을 권했다. 이 관찰로 오케스트레이터가 프로토콜에 적은 신호 중 '검증 실패 다수'는 탐색 부족의 신호가 아니라고 보고했다.

## 인용 확인

오케스트레이터가 보고의 결론 문장에 쓰는 인용을 직접 열어 확인했다.

| 참조 | URL | 확인한 구절 |
|---|---|---|
| sq1#case#4 | https://arxiv.org/abs/2606.09748 | "a single round of process-level feedback yields substantial gains", "these gains do not compound over subsequent turns, as agents regress on up to 24% of previously satisfied criteria", self-reflection 은 "incorporate and regress on rubric criteria at nearly equal rates, yielding negligible net improvement" |
| sq4#case#7 | https://code.claude.com/docs/en/sub-agents | "Define a custom subagent when you keep spawning the same kind of worker with the same instructions.", "Enforce constraints by limiting which tools a subagent can use", 설명 합계 15,000 토큰 초과 시 시작 경고 |
| sq5#case#1 | https://arxiv.org/abs/2605.29800 | "the 9 judges effectively provide only about 2 independent votes' worth of information" |
| sq4#case#1 | https://arxiv.org/abs/2505.18286 | "the benefits of MAS over SAS diminish as LLM capabilities improve" |
| sq4#case#6 | https://arxiv.org/html/2502.08788v3 | "MAD often fail to outperform simple single-agent baselines such as Chain-of-Thought and Self-Consistency" |
| sq4#issue#0 | https://www.claude.com/blog/building-multi-agent-systems-when-and-how-to-use-them | "improved prompting on a single agent achieved equivalent results" |
| sq5#issue#0 | https://arxiv.org/html/2511.16708v3 | 에이전트 1~4개 평균 정확도 32.8%·47.7%·61.2%·72.4%, 한계 이득 +14.9pp·+13.5pp·+11.2pp. 코드 검증 29개 표본 |
| sq5#issue#1 | https://snyk.io/blog/snyk-vulnbench-js-1-0-llm-security-review-repeatability/ | "80 of 161 unique-unmatched findings appeared in only one of five identical repetitions, while only 22 appeared in all five." |

sq4#issue#0 의 같은 글에 있는 "multi-agent implementations typically use 3-10x more tokens than single-agent approaches for equivalent tasks" 는 다른 URL 표기(sq3#case#1)로 검증 실패에 든 주장이다. 오케스트레이터가 원문에서 구절을 확인했으나 판정에는 쓰지 않고 보고에 그 사실을 적는다.
