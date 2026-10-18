# 2026-10-18 plan 리뷰 — 선행연구 에이전트 계약 코드

대상은 `docs/superpowers/plans/2026-10-18-prior-art-agent-contract.md`다. 경로가 `docs/superpowers/plans` 아래라 plan 으로 판정했다. 짝 spec 은 큰 명세 `docs/superpowers/specs/2026-10-18-prior-art-agent-design.md`의 「다시 나눈 분할」이다. 렌즈를 한 번씩만 실행했다. 렌즈마다 general-purpose 서브에이전트 하나를 썼고, 읽기 전용은 프롬프트로만 지시했다. 고친 파일을 보고한 렌즈는 없다.

## 선행연구 에이전트의 제안

제안하지 않았다. 대상이 plan 이라 `review-specs`가 제안을 두지 않는다.

## 합친 지적 목록

| 지적 | 잡은 렌즈 |
|---|---|
| `!` 부정 단언은 함수 없음·node 없음·경로 오류에서도 PASS 하고, Step 3 의 '모두 FAIL' 기대가 성립하지 않는다 | adversarial, consistency, grounding, fit |
| node 존재 확인과 CI 가정이 없다 | adversarial, grounding |
| 요약 줄과 실패 시 0 이 아닌 종료 코드를 지시하지 않았다 | grounding |
| 스키마나 예시 한쪽만 넘기는 호출 방법이 없고, 시험 도구 실패를 생략으로 오인할 수 있다 | adversarial, consistency, fit |
| 정의 파일이 있는데 블록 추출이 실패할 때의 판정이 정해지지 않았다 | consistency, fit |
| 빈 배열 예시와 `items` 없는 스키마의 판정이 없다 | adversarial |
| 스키마의 `required`를 대조하지 않는다 | adversarial, consistency |
| 계약 코드에 자료가 없거나 요구 키가 0 개일 때 통과한다 | adversarial |
| 두 정의 중 하나만 없어도 `agents` 전체를 생략한다 | adversarial |
| `researcher` 루트 키, `result`·`args` 원소 키, `synthesis` 원소, 선택 키 표기가 정해지지 않았다 | consistency |
| 생략 분기 제거가 plan 에 연결되지 않았다 | adversarial, consistency |
| JSON 처리기를 node 로 하나 더 들인다(저장소는 `json_run` 하나) | adversarial, consistency |
| 파일 경로를 node 스크립트 문자열에 넣으면 Windows 에서 경로 변환을 받지 않는다 | adversarial |
| `args`·`result` 자기 대조는 대조 상대가 없다 | adversarial |
| 시험 도구 적재 방식에서 최상위 `const`를 `schemas()`가 돌려주면 TDZ 오류가 난다(근본 수정은 `workflow` 쪽) | adversarial |
| Consumes 칸이 시험 도구 의존을 적지 않았다 | fit |
| 여덟 문장 단락, 쉼표 둘, 주체가 '시험 병합', '큰 명세' 미풀이, '시험' 용어 혼용 | fit |

## 커버리지 공백

렌즈 네 개가 모두 실행되었다. `lens-fit`의 `doc_type`은 '설계' 행으로 채워졌다.
