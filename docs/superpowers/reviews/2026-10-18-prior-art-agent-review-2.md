# 2026-10-18 spec 리뷰 2차 — 선행연구 에이전트

대상은 1차 리뷰를 반영한 `docs/superpowers/specs/2026-10-18-prior-art-agent-design.md`다. 경로로 spec 이라고 판정했다. 렌즈를 한 번씩만 실행했다. 렌즈마다 general-purpose 서브에이전트 하나를 썼고, 읽기 전용은 프롬프트로만 지시했다. 고친 파일을 보고한 렌즈는 없다. PREP 은 1차 반영판을 기준으로 새로 채웠다.

## 선행연구 렌즈의 제안

제안하지 않았다. 1차와 같은 이유로, 같은 날 실행한 선행연구 차수(`docs/superpowers/reviews/2026-10-18-prior-art-agent-prior-art.md`)를 근거로 쓴다.

## 합친 지적 목록

| 지적 | 잡은 렌즈 |
|---|---|
| Jev 문단이 Kim 등을 '제공사가 다르면 상관이 줄어든다'의 근거로 들었으나, 초록은 "even with distinct architectures and providers" 오류 상관이 높다고 적는다 | grounding |
| Kim 등의 "larger and more accurate models have highly correlated errors"를 비교급(클수록 높다)으로 옮겼다 | grounding |
| `maxTurns`는 턴을 세고 도구 호출을 세지 않는데, 도구 호출 20회 상한에 '맞춘' 값이라고 적었다 | grounding |
| 선행연구 기록이 미검증으로 적은 인용(cookbook 도구 호출 예산, deep-research 문구)을 근거로 쓰면서 재확인 사실을 적지 않았다 | grounding |
| 「읽기 범위」에는 대조 대상 문장이 없고 그 문장은 도입 단락에 있다 | grounding, consistency |
| aggregating-lenses 인용 문장의 글자가 원문과 다르다 | grounding |
| review-specs 의 단계 상한 미루기 문장, PREP 의 '렌즈와 동시에', 절차 머리의 '서브에이전트 상한으로 센다'가 변경 목록에 없다 | grounding, consistency |
| 검증자 수에 상한이 없고, 같은 URL 을 인용마다 따로 검증한다 | adversarial |
| 속도 제한·에이전트 실패가 `unverifiable`에 섞여 `search_status`가 `ok`로 남을 수 있다 | adversarial |
| 기록을 4단계에서만 써서 1단계 확인이 성립하지 않고, 단계 사이에 세션이 끊기면 원본이 남지 않는다 | adversarial, consistency |
| 원본 파일 규칙이 검증자 여러 출력, 지도 대조 출력, 공백 라운드 재실행을 구분하지 못하고 review-docs 의 순번 뜻과 충돌한다 | adversarial, consistency, fit |
| Haiku 시험이 서로 다른 인용 집합을 비교한다 | adversarial |
| 기준선 출력에 `queries`가 없어 질의 경계 위반을 셀 수 없다 | adversarial |
| 병합 전 게이트의 엇갈림 판정, 채택 기준의 합성 규칙, 실행마다 사용자 승인 턴이 정해지지 않았다 | adversarial, consistency |
| 발동 넛지 시험이 오탐·미탐을 실제로 유발하는 입력을 쓰지 않는다 | adversarial |
| 발동 넛지가 매 메시지 훅이 되는데 세션당 반복, 요청형 표현, 끄는 변수, 실행 시간 측정이 없다 | adversarial, consistency |
| 프로토콜 항목, 근거 지도 칸, 검증자 지도 대조 출력, 종합 주체가 절마다 다르거나 정의되지 않았다 | consistency |
| 상한 규칙을 기존 절과 새 절 두 곳이 정한다 | consistency |
| `kind`에 `standard`를 추가하면서 출력 스키마를 유지한다고 적었다 | consistency |
| `workflows/`가 domain-plugin 컴포넌트 위치에 없다 | consistency |
| `lens-` 접두사 스킬이 실행 절차를 소유하는 것이 domain-plugin 이름 규칙과 다르다 | consistency |
| 연구자·검증자 호출이 `LENS-ALLOWED`의 `lens-*` 허가 범위 밖이다 | consistency |
| 연구자 프롬프트를 '사본'과 '사본에 모드 추가'로 다르게 정의했다 | consistency |
| 검증자 `maxTurns` 10 은 출처가 없다 | fit |
| 표 안의 빈 줄로 README 행이 표에서 떨어졌다 | fit, consistency |
| 문장 중간 관형절, 다섯 문장 단락, 개수 예고, 여러 문장 불릿, '이 세션'·'메인 세션' 혼용, 질의 경계·기시감 등 미정의, 리뷰·절을 주어로 쓴 문장 | fit |

## 커버리지 공백

렌즈 네 개가 모두 실행되었다. `lens-fit`의 `doc_type`은 '설계' 행으로 채워졌다. 2차 렌즈는 사용자 결정(키워드 넛지, 이중화 없음, 단계당 상한 예외, 인용 검증 분담, 병합 전 게이트)을 대화 기록으로 확인하지 못했다고 적었다. 이 결정의 원문은 이 세션의 대화에 있다.
