# 조항 측정·문서 정리·병합 plan 리뷰 기록(2026-10-21)

대상은 `docs/superpowers/plans/2026-10-21-clause-measurement-and-merge.md` 다. 파일이 `docs/superpowers/plans` 아래에 있으므로 plan 으로 판정했다. 렌즈 원본은 같은 이름의 폴더에 있다.

렌즈를 한 번씩만 실행했다. plan 이므로 선행연구 에이전트는 제안하지 않았다.

## 지적 목록

| 번호 | 렌즈 | 지적 | 함께 잡은 렌즈 |
|---|---|---|---|
| 1 | grounding·consistency·adversarial | 기존 dev 과제에 `followup: true` 인 `q-<단위>-f1`·`f2` 가 이미 있어, 위반 수가 같으면 `report_unit` 이 `동률` 대신 `채택(차이없음)` 을 낸다. 그래서 `p12` 승격 경로가 거의 발동하지 않는다 | 셋 |
| 2 | adversarial | 그 결과 `p12` 과제 이식과 `pool` 태그 대부분이 쓰이지 않는다 | — |
| 3 | grounding | `p12` 과제가 모두 `kind: should` 라 CLAUDE.md 의 짝 구성과 다르다 | — |
| 4 | grounding·consistency·adversarial | `c20-smoke` 를 과제 하나로 실행할 수단이 없고, 이식한 과제는 `pool` 이라 실행되지 않는다 | 셋 |
| 5 | grounding·consistency·adversarial | `c20-midmod-named` 의 `ids` 를 두 문장이 다르게 정해, 같은 조항의 단위끼리 과제 집합이 달라질 수 있다 | 셋 |
| 6 | adversarial | `TERM-EXPLAIN` 과제는 그 조항이 실리지 않은 채 생성되어 잡음만 더한다. `c20-checkable` 의 `BULLET-SCOPE` 과제도 같다 | — |
| 7 | adversarial·consistency | 세 변경안이 같은 현행 표본을 공유하고 셋 중 최소를 고르므로 채택 쪽으로 치우친다. 원칙에 옮기기 전에 사용자 확인이 없다 | 둘 |
| 8 | grounding·adversarial | `c20-concise-priority` 의 두 조건에 우선할 조항이 실리지 않고, "두 줄" 규칙과도 어긋난다 | 둘 |
| 9 | grounding·adversarial·fit·consistency | Concise 원문을 실행 세션의 시스템 프롬프트에서 옮기라고 했으나 서브에이전트에는 그 절이 없을 수 있다. `concise.md` 와 `system.md` 가 같은 문구를 중복한다 | 넷 |
| 10 | adversarial | `system.md` 가 없을 때 생성 키가 지금과 같아야 한다는 조건이 없어, 기존 생성 560건이 재생성될 수 있다 | — |
| 11 | adversarial·grounding | 과제 승격과 `criteria.md` 수정이 같은 조항 ID 의 다른 단위를 `미완` 으로 만든다 | 둘 |
| 12 | grounding·consistency·adversarial | `c20-edit-priority` 변형 과제의 폴더·머리가 Files 에 없고, 원래 과제와 섞이며, 천장 효과와 판정 기준 충돌이 있다 | 셋 |
| 13 | consistency | spec 의 T3 이 후보 표의 `SECRETS` 행까지 덮는지 plan 이 밝히지 않는다 | — |
| 14 | consistency | Task 5 와 측정 Task 가 `docs/domain-korean.md` 를 함께 고치고, 측정 기록이 쌓일 `docs/domain-discipline.md` 는 정리 확인 범위 밖이다 | — |
| 15 | consistency | Task 5 와 Task 6 이 `skills/review-docs/SKILL.md` 의 같은 문단을 고치고, README 의 같은 용어는 범위 밖이다 | — |
| 16 | adversarial | 렌즈 SKILL.md 의 「체크리스트」를 산문으로 바꾸면 드리프트 검사의 축 대조가 조용히 사라진다 | — |
| 17 | adversarial | Task 5 에 front matter 발동 낱말과 지시 문장 보존 지시가 없다 | — |
| 18 | adversarial | 세션에 실리는 원칙과 훅은 GitHub 마켓플레이스의 main 에서 온다. 로컬 병합만으로는 바뀌지 않고, push 는 Global Constraints 가 금지한다 | — |
| 19 | adversarial | 병합 전 main 해시 기록과 되돌리는 방법이 없다 | — |
| 20 | consistency | 병합 뒤 이 브랜치의 리뷰 기록 처분이 없다 | — |
| 21 | consistency | spec 「바뀌는 파일」 표와 plan 의 과제 배정이 다르다 | — |
| 22 | grounding | Task 5 의 라벨 불릿 집계 121건은 HANDOFF 파일 4건을 포함한 값이고 목록 기준으로는 117건이다 | — |
| 23 | grounding | 후보 원문 블록은 YAGNI 괄호를 이미 뺀 가공본인데, 블록 아래에서 다시 빼라고 지시한다 | — |
| 24 | grounding | 8b4a05a 후보 문안에는 현행 조항 줄의 이유 문장이 없어, 비교에 문안 변경과 이유 문장 삭제가 섞인다 | — |
| 25 | fit | Step 제목과 본문의 할 일이 평서문이고, 불릿이 여러 문장이며, 개수로 가리키고, '생성 키'를 풀지 않았다 | — |

## 커버리지 공백

어느 렌즈도 `criteria.md` 본문을 열어 `TERM-EXPLAIN`·`BULLET-SCOPE` 과제가 실제로 무엇을 세는지 확인하지 않았다.
