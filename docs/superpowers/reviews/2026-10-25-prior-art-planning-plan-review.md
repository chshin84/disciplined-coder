# 2026-10-25 선행연구 계획 수립 개선 plan 리뷰

## 대상과 실행

- 대상: `docs/superpowers/plans/2026-10-25-prior-art-planning.md` (경로가 `plans/` 아래이므로 plan 으로 판정했다)
- 렌즈: `lens-grounding`, `lens-consistency`, `lens-adversarial`, `lens-fit`. 렌즈를 한 번씩만 실행했다.
- 원본: 같은 이름 폴더의 `lens-*.json`. 저장 용량을 줄이려고 원본 보고의 칸 일부를 줄여 저장했고, 각 파일의 `note_on_storage`에 그 사실을 적었다.
- 선행연구 에이전트: plan 이므로 제안하지 않았다.

## 병합한 지적

| 번호 | 렌즈 | 지적 |
|---|---|---|
| 1 | grounding, consistency | Task 2 단언이 eval 이름공간에 없는 `args`를 참조해 항상 실패한다 |
| 2 | grounding, consistency | `mkin`이 args 를 `args_c.json`에서만 읽어 round 0·빈 constraints·빈 subquestions 입력을 만들 방법이 없다 |
| 3 | grounding | 응답표 서술에 `@mode`와 `responses` 감싸기가 없다 |
| 4 | grounding | SKILL.md 예시 블록을 대조하는 검사가 없는데 Architecture 가 묶여 있다고 적었다 |
| 5 | grounding, consistency, adversarial, fit | `workflow_harness.mjs`를 Modify 로 적었으나 고칠 곳이 없고, SCOUT_SCHEMA 상수 목록 검사가 없다 |
| 6 | grounding, consistency, adversarial | 빈 constraints 확인이 종합 블록에 없다. adversarial 은 그 단언 자체가 중복이라 빼라고 했다 |
| 7 | grounding | Task 2 Step 2 가 test_prior_art_contract.sh 의 새 짝의 실패를 확인하지 않는다 |
| 8 | consistency | Task 5 Step 2 가 SKILL.md 에서 '단독 근거'를 기대하지만 넣는 Task 가 없다 |
| 9 | consistency | spec 확인 7 의 '축이 다른 행 포함' 확인이 없다 |
| 10 | consistency, adversarial | SKILL.md 「에이전트에게 보내는 프롬프트」·「출력 스키마」에 둘러보기 입출력을 넣는 단계가 없다 |
| 11 | consistency | survey 지시문의 constraints 재탐색 금지가 명시되지 않았다 |
| 12 | consistency | review-docs 의 r<n> 정의 문장을 고치지 않아 r0 의 뜻이 정의되지 않는다 |
| 13 | adversarial | 금지어 위반 검색어가 원본 파일에 원문으로 저장되고 커밋·봉인된다 |
| 14 | adversarial | SCOUT_SCHEMA 에 additionalProperties: false 가 없어 검증되지 않은 사례 칸이 반환값에 남을 수 있다 |
| 15 | adversarial | 둘러보기 출처가 constraints 의 '이미 확인한 자료'로 옮겨져 검증 밖으로 빠질 수 있고, 그 규칙을 확인하지 않는다 |
| 16 | adversarial | 둘러보기 호출을 parallel 로 감쌀지 정하지 않아 예외 경로에서 `scout: null` 계약이 깨질 수 있다 |
| 17 | fit | 도구 호출 상한 10 에 근거가 없다 |
| 18 | fit | INSTRUCTION-FORM·NO-MID-MOD·COUNT-EARNS·BULLET-SCOPE·ONE-IDEA·TERM-ONE·FULL-SENTENCE 위반 |

둘 이상의 렌즈가 함께 잡은 지적은 1·2·5·6·10 번이다.

## 커버리지 공백

어느 렌즈도 런타임 `agent()`가 실패할 때 예외를 던지는지 `null`을 돌려주는지 확인하지 못했다. spec 「확인 방법」 8(다음 실사용 실행에서의 확인)을 남기는 단계는 plan 에 없다.
