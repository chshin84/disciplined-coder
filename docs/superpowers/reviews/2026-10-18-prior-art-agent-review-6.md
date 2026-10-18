# 2026-10-18 spec 리뷰 6차 — 선행연구 에이전트 다시 나눈 분할

대상은 큰 명세 `docs/superpowers/specs/2026-10-18-prior-art-agent-design.md`의 새 절 「다시 나눈 분할」이다. 경로로 spec 이라고 판정했다. 렌즈를 한 번씩만 실행했다. 렌즈마다 general-purpose 서브에이전트 하나를 썼고, 읽기 전용은 프롬프트로만 지시했다. 고친 파일을 보고한 렌즈는 없다.

## 선행연구 에이전트의 제안

제안하지 않았다. 새 절은 승인된 완전체 명세를 `nested-orchestration` 절차로 나눈 것이다.

## 합친 지적 목록

| 지적 | 잡은 렌즈 |
|---|---|
| 빈 `prior_claim`·`prior`를 `rejected`로 정했으나 하부 명세의 판정 규칙과 다르고, 구현 주체와 '비면'의 뜻이 없다 | adversarial, consistency, grounding |
| 스키마가 강제하지 않는 하위 칸(`citations`, `evidence_map`, `axes`와 축)이 빠지면 워크플로가 예외로 끝난다 | adversarial |
| 계약 테스트가 스키마 상수와 출력 형식 블록을 읽는 방법이 정해지지 않았다 | adversarial |
| 키 이름의 원본이 큰 명세 표와 계약 코드 두 곳으로 선언되었다 | adversarial |
| 계약 표에 `claims[].text` 형태, `{ ref, row }`, `researchers`·`verifiers` 원소 형식, 사유 위치의 행이 없다 | consistency |
| 종합·지도 대조 출력의 빈도가 생략 조건(0~1회)을 반영하지 않는다 | consistency, grounding, adversarial(notes) |
| 등록 이름 행이 두 제공 방향을 한 행에 묶고 소비자를 '통합 확인'으로만 적었다 | consistency, fit |
| 허용 경로에 고치지 않는 `skills/lens-readability/SKILL.md`가 들어 있다 | consistency, adversarial |
| 통합 확인에 통합 트리의 옛 이름 확인이 없고, 공통 제약이 새 id 로 적혀 있지 않다 | adversarial, fit |
| `workflows/`가 든 트리의 `claude plugin validate` 결과가 측정되지 않았다 | adversarial |
| 계약 코드의 생략 분기를 통합 뒤 어떻게 할지 적지 않았다 | adversarial |
| 승인 근거(공유 항목 표, 설계 의존 표, 예상 태스크)가 새 절에 없다 | fit |
| '자료 계약'과 '계약 테스트'가 스킬의 용어와 다르게 쓰였고, 「소유 표」가 산문이다 | fit |

## 커버리지 공백

렌즈 네 개가 모두 실행되었다. `lens-fit`의 `doc_type`은 '설계' 행으로 채워졌다.
