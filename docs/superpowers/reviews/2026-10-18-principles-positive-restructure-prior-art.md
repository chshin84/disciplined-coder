# 에이전트원칙 개편의 선행연구 대조 — 2026-10-18

대상은 `docs/superpowers/specs/2026-10-18-principles-positive-restructure-design.md` 를 쓰기 전의 설계 구상이다. 렌즈에 넘긴 원문은 "약 55개 조항을 상황→행동→멈출 조건→이유 형식의 긍정형으로 다시 쓰고, 목차를 출력 종류별 층으로 나누고, 조항 충돌에 우선순위를 두고, 소거 시험으로 효과를 확인한다"였다.

## 렌즈를 붙인 경위

- **제안과 승인** — 사용자가 "이러한 기준들을 선행연구렌즈로 찾아봐라"라고 직접 요청했다. `dispatching-lenses` 「렌즈 그룹」에 따라 직접 요청을 승인으로 보았다.
- **규모** — 하위 질문 5개에 이중화 1개를 더해 렌즈 6개로 정했고, 사용자가 선택 도구로 "6개"를 승인했다. 사용자는 같은 날 상한을 통상 2, 최대 20 으로 정했으나 `lens-prior-art` 스킬 파일에는 아직 반영되지 않았다(다른 세션이 맡은 선행연구 에이전트 개발에 포함).
- **spec·plan 구분** — spec 을 쓰기 전의 구상을 대상으로 했으므로 spec 리뷰 절차의 발동 기준 판정은 하지 않았다.

## 하위 질문과 렌즈

| 원본 | 하위 질문 | search_status |
|---|---|---|
| `lens-prior-art-1.json` | 긍정형·금지형 지시(학술 논문 경로) | ok |
| `lens-prior-art-2.json` | 긍정형·금지형 지시(벤더·실무 문서 경로, 1 의 이중화) | ok |
| `lens-prior-art-3.json` | 지시 한 개의 구성 요소(요구사항 표준, 규정 작성 지침) | ok |
| `lens-prior-art-4.json` | 지시 사이의 충돌과 우선순위 | ok |
| `lens-prior-art-5.json` | 적용 범위로 나눈 층 | ok |
| `lens-prior-art-6.json` | 원칙의 효과 검증 | ok |

렌즈를 한 번씩만 실행했다.

## 발견 목록

판정에 쓸 수 있는 발견이 있으므로 발견은 모두 사용자 처분 대상이다. 사용자는 아래 발견을 보고 2026-10-18 에 다섯 가지를 정했고, 그 결정은 spec 「결정」 절에 있다.

| 렌즈 | 유형 | 요지 |
|---|---|---|
| 1 | weak-baseline | 조항 유무 시험만으로는 극성(금지형→긍정형)의 효과를 구분하지 못한다. 극성 쌍 비교가 기준선이다 |
| 1 | known-failure | 금지 대상의 이름을 적는 것 자체가 그 대상을 점화한다. 대체 대상을 함께 줘도 위반이 남는다 |
| 1 | known-failure | 금지 지시 뒤 맥락이 길수록 반동이 커진다 |
| 2 | refuted-premise | 지시와 이유를 분리한 현행 설계는 Anthropic 지침과 상충한다 |
| 2 | refuted-premise | '조항 사이 우열 없음'은 벤더 지침과 상충한다 |
| 2 | refuted-premise | '모든 조항을 긍정형으로'는 벤더 지침보다 넓다. 절대 금지는 불변 조건에만 둔다 |
| 2 | known-failure | 작동 중인 지시 묶음을 한 번에 다시 쓰면 무엇이 효과를 냈는지 구분하지 못한다 |
| 2 | known-failure | 조항마다 네 요소를 붙이면 분량이 늘어 지시를 놓친다 |
| 2 | weak-baseline | 현행 원칙 전체의 사전 측정과 삭제만 한 조건이 비교되지 않았다 |
| 3 | refuted-premise | 금지 자체가 목적인 지시는 금지문과 이유로 남기는 것이 선행 관행이다 |
| 3 | known-failure | 지시 밀도가 늘면 뒤쪽 지시가 먼저 누락된다 |
| 3 | crowded | 조건-응답 문형은 EARS 가, 이유 속성은 INCOSE 지침이 표준화했다. 조건 종류 구분을 참조하지 않았다 |
| 4 | refuted-premise | '하네스보다 우선하라' 문장은 현행 원칙 첫 줄에 이미 있다 |
| 4 | known-failure | 프롬프트로 우선순위를 밝히는 방법은 효과가 작거나 없다 |
| 4 | known-failure | 우선 등급이 많을수록 정확도가 떨어진다 |
| 4 | weak-baseline | 충돌 제거와 분량 축소라는 기준선과 비교하지 않았다 |
| 4 | crowded | 권한 등급과 덮어쓸 수 있는 기본값 체계가 벤더 표준 문서에 있다 |
| 5 | known-failure | 적용 조건을 모델이 스스로 판정하게 하면 규칙을 건너뛴다 |
| 5 | weak-baseline | 파일 단위 조건부 로드와 비교하지 않았다 |
| 6 | known-failure | 조건마다 1회 실행과 과제 3~5개로는 분산이 판정을 흔든다 |
| 6 | known-failure | 같은 계열 판정자에는 자기 선호·순서 편향이 있다 |
| 6 | known-failure | 조항 단독 측정은 결합 조건(충돌·우회)을 대표하지 못한다 |
| 6 | weak-baseline | 전체 프롬프트 A/B 와 실패 재현 회귀 세트와 비교하지 않았다 |
| 6 | known-failure | 위반만 세면 과잉 발동이 드러나지 않는다 |
| 6 | known-failure | 형식 변경만으로 성능이 크게 달라져 단일 문안 비교가 흔들린다 |

## 인용 검증

메인 세션이 원문을 열어 아래를 확인했다.

- OpenAI GPT-5.6 지침: "true invariants", "prefer decision rules", "Do not rewrite a working prompt stack all at once", "conflicting rules can create more instability than missing detail", "Remove one group of instructions … then rerun the same evals"
- Claude Code 모범 사례: "Would removing this cause Claude to make mistakes?", "Bloated CLAUDE.md files cause Claude to ignore your actual instructions!", "If you emphasize many lines, none of them stands out", "hooks are deterministic"
- Claude Code 메모리 문서: "target under 200 lines", import 가 "don't reduce its context cost", "Claude may pick one arbitrarily", "delivered as a user message after the system prompt"
- arXiv 2601.08070: 위반의 87.5% 가 점화 실패, n=40,000
- arXiv 2502.08745(IHEval): 우선순위 프롬프트가 "does not bring noticeable improvements", GPT-4o 70.0→67.2
- Anthropic 에이전트 평가 글: 실제 실패 20~50 과제, one-sided evals, multiple trials, 사람 보정
- Anthropic 헌법 발표문: 설명하라, 규칙의 경직 적용, high-stakes 의 규칙, 나열 순서 우선
- Anthropic 프롬프트 지침: 서식 제어 절의 "Tell Claude what to do instead of what not to do", 맥락 추가 절의 ellipses 예시(같은 날 앞선 확인)

확인하지 못해 결론에 쓰지 않은 것:

- 렌즈 6 이 인용한 Miller(arXiv 2411.00640)의 수치(969 문항, K=1→10)와 반복 표본 권고는 초록에서 확인되지 않았다. 반복 실행의 근거는 Anthropic 글로 대신했다.
- 렌즈 2 가 인용한 "Claude is smart enough to generalize from the explanation" 문장은 이번에 다시 확인하지 못했다.
- 렌즈 4 의 ManyIH-Bench(alphaxiv 요약 페이지)와 IFScale 의 모델별 수치, 렌즈 6 의 MT-Bench 순서 일관성 65.0% 는 원문 표를 대조하지 않았다.

## 결론에 영향을 주는 not_found 와 disclosures

- 같은 조항을 금지형과 긍정형으로 짝지어 위반률을 비교한 통제 실험은 학술(렌즈 1)과 벤더(렌즈 2) 경로 모두에서 찾지 못했다. 개편의 핵심 가설이 측정되지 않았다는 뜻이며, spec 은 실패 평가 세트로 직접 측정한다.
- '금지를 피하다 더 큰 잘못'이라는 대체 행동 실패 자체를 측정한 연구는 찾지 못했다(렌즈 1).
- 같은 등급의 지시 파일 안에서 조항끼리의 충돌 해소 규칙을 측정한 연구는 찾지 못했다(렌즈 4).
- 출력 종류(대화 답 대 산출물)를 조건으로 삼는 공식 규칙 메커니즘은 찾지 못했다(렌즈 5).
- 질의 경계 위반을 스스로 밝힌 렌즈는 없었다. 메인 세션은 렌즈 원본 JSON 을 받는 즉시 저장하지 못했고, 같은 세션 안에서 뒤늦게 `lens-prior-art-<순번>.json` 으로 저장했다.
