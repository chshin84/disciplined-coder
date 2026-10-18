# 2026-10-18 spec 리뷰 — 선행연구 에이전트

대상은 `docs/superpowers/specs/2026-10-18-prior-art-agent-design.md`다. 경로가 `docs/superpowers/specs` 아래이므로 spec 으로 판정했다. 렌즈를 한 번씩만 실행했다. 렌즈마다 general-purpose 서브에이전트 하나를 썼고, 읽기 전용은 프롬프트로만 지시했다. 고친 파일을 보고한 렌즈는 없다.

## 선행연구 렌즈의 제안

제안하지 않았다. 이 spec 은 아직 해본 적 없는 것을 해내려 하므로 발동 기준에는 해당한다. 그러나 같은 날 사용자의 직접 요청으로 이 spec 의 바탕이 된 설계 구상을 대상으로 선행연구 렌즈를 이미 실행했다(`docs/superpowers/reviews/2026-10-18-prior-art-agent-prior-art.md`). 그 차수의 결과를 이 차수의 근거로 쓴다.

## 렌즈 외 점검

superpowers brainstorming 의 빌더 점검(이 spec 만 보고 plan 을 쓸 수 있는지 묻는 서브에이전트)을 같은 시점에 실행했다. 빌더 점검은 렌즈가 아니므로 원본을 이 폴더에 두지 않는다. 남긴 질문은 「메인 세션이 정한 항목」의 확정 여부, `review-specs` 경로에 여러 턴 흐름 전체를 적용하는지, 통상 2와 하위 질문 수가 부딪힐 때의 규칙, 시험 계획을 병합 전 게이트로 두는지와 기준선의 정의, 근거 기록 파일의 부재였다.

## 합친 지적 목록

| 지적 | 잡은 렌즈 |
|---|---|
| 인용 URL 응답 확인과 인용 지지 검증을 워크플로 안으로 옮기면서, 그 확인을 호출자가 한다고 정한 현행 문장(review-specs 「웹에 나가는 렌즈의 인용 검증」, aggregating-lenses 「공통 계약의 예외」, lens-prior-art 「기계에 넘기는 것」)을 변경 목록에 넣지 않았다 | grounding, consistency |
| 질의 경계 검사를 '기계 검사'라 부르면서 LLM 검사 에이전트에 맡겼다. 결정론으로 할 수 있고, URL 응답은 검증자의 판정 불가 범주와 겹친다 | adversarial, consistency |
| 검사 에이전트와 합성 대조 에이전트의 정의·도구·입출력이 구성 표와 용어 표에 없다 | grounding, consistency |
| 상한이 연구자만 세서 검증자를 포함한 총 에이전트 수에 상한이 없고, 현행 스킬은 서브에이전트 전체를 센다 | adversarial, consistency |
| 통상 2를 기본값이라 하면서 상황 표의 기본값은 3~5와 3~10이다 | consistency |
| review-specs 의 '렌즈와 동시에 실행', '통상과 최대한 중 고른다' 문장이 새 흐름과 부딪히는데 변경 목록에 없다 | consistency |
| 발동 누락의 대책이 description 문구 추가뿐인데, 실패한 요청 문구는 현행 description 에 이미 있다. 시험 측정값에 발동 여부도 없다 | adversarial |
| 종합 워크플로가 근거 지도를 만들지 않는 contrast 상황에도 실행되고, 순차 호출 두 번이라 별도 워크플로가 필요하지 않다 | adversarial |
| 근거가 이중화의 이득을 작게 예측하는데 이중화 절차와 시험 조건을 넣었다 | adversarial |
| 워크플로가 꺼졌거나 실행 중 실패했을 때의 경로를 빌더에게 넘겼다 | adversarial |
| 사실 확인 경로에는 검증자와 데이터 흐름 강제가 없다 | consistency |
| 결정 근거 탐색과 사실 확인에는 네 축 대조의 대상 설계가 없다 | consistency |
| 시험 계획에 판정 규칙·반복 횟수·판정자·기준선 정의가 없고 토큰이 채택 기준에 없다 | adversarial, consistency |
| 도구 호출 상한의 강제 수단과 근거 확인이 없고, 공백 라운드 최대 2회는 근거가 없다 | adversarial, fit |
| 렌즈별 원본 순번 규칙(review-docs)이 연구자 여럿과 검증자 출력을 담지 못한다 | consistency |
| 기록 내용 규칙(review-specs 「prior-art 기록에 적을 것」)에 프로토콜 전문이 없다 | consistency |
| 탐색 결과 전체의 `search_status`를 합치는 규칙이 없다 | consistency |
| 오케스트레이터의 직접 확인을 '현행 유지'라 했지만 범위와 대상이 현행보다 좁다 | consistency |
| 새 절 이름이 정해지지 않아 포인터 대상이 없다 | consistency |
| README 에 구성 요소를 열거하는 절이 없고 CLAUDE.md 는 열거하지 않는다고 정한다 | consistency |
| dispatching-lenses 「호출자 목록」과 「렌즈 그룹」의 실행 호출자에 lens-prior-art 가 없다 | consistency |
| 연구자 정의에 에이전트원칙 경로를 넘기는 칸이 없고, 레퍼런스 프롬프트의 원본이 두 곳이 된다 | consistency |
| 근거 기록 파일이 저장소에 없다(렌즈 실행 시점 기준) | grounding |
| test_audit.sh 는 lens-prior-art 이름을 검사하지 않고, 이름을 가리키는 파일 목록에서 에이전트원칙 등이 빠졌다 | grounding |
| 플러그인 `agents/`와 agentType 실행 전제에 출처가 없고, 등록 이름은 `disciplined-coder:` 이름공간을 받는다 | grounding |
| 60% 수치에서 '한 리더보드 데이터셋에서'라는 조건이 빠졌다 | grounding |
| 사용자 결정이 필요한 항목을 문서에 모아 두었다(TELL-NOW) | fit |
| 문서 주어, 여러 문장 불릿, 개수 예고, '것', 오케스트레이터와 메인 세션의 혼용, 빌더·검사 에이전트 미정의, 말끝 불일치, 문장 중간 관형절, 대구 반복 | fit, consistency |

## 커버리지 공백

렌즈 네 개가 모두 실행되어 `aggregating-lenses`가 표시할 미실행 렌즈는 없다. `lens-fit`의 `doc_type`은 '설계' 행으로 채워졌다. TITLES 묶음을 spec 에 적용할지는 계약에서 정해지지 않아 `lens-fit`이 판정하지 않았다.
