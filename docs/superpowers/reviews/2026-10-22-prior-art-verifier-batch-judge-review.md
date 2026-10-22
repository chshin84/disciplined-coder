# 선행연구 검증자 Opus 일괄 판정 plan 리뷰 기록(2026-10-22)

대상은 `docs/superpowers/plans/2026-10-22-prior-art-verifier-batch-judge.md` 다. 파일이 `docs/superpowers/plans` 아래에 있으므로 plan 으로 판정했다. 함께 바뀐 spec `docs/superpowers/specs/2026-10-20-prior-art-verifier-tiering-design.md` 의 「Opus 일괄 판정」 절은 따로 실행하지 않았다. 렌즈마다 근거로 넘겼고, lens-fit 과 lens-consistency 는 그 절도 대상으로 보았다. 렌즈 원본은 같은 이름의 폴더에 있다.

렌즈 lens-fit·lens-adversarial·lens-grounding·lens-consistency 를 한 번씩만 실행했다. 선행연구 에이전트는 제안하지 않았다. 대상이 plan 이고, 함께 바뀐 spec 절은 기존 설계의 수정이며 그 효과를 plan 의 재측정이 확인하기 때문이다.

## 지적 목록

| 번호 | 렌즈 | 지적 | 함께 잡은 렌즈 |
|---|---|---|---|
| 1 | adversarial | 일괄 출력이 주장 수에 비례해 커지는데 출력 길이 한계·주장 수 상한·분할 규칙이 없다. 출력이 잘리면 그 호출의 모든 URL 이 검증 실패다 | — |
| 2 | adversarial | 시험의 일괄 크기(주장 36~39개)가 운영(URL 40개 이상)과 달라 판정 누락 수가 운영을 대표하지 못한다. 측정한 일괄 크기를 기록할 지시가 없다 | — |
| 3 | adversarial | run.py 가 오류 줄을 다시 실행해 덮으므로, 일괄 호출 실패의 빈도가 측정과 결정 기록에 남지 않는다 | — |
| 4 | adversarial·consistency | 일괄 출력에서 주장 하나가 빠지면 그 URL 전체가 검증 실패다. 다른 실패는 주장 단위인데 이것만 URL 단위다 | — |
| 5 | consistency | 재판정 무응답의 처리를 spec 의 두 절이 다르게 정한다(주장 단위와 일괄 호출의 모든 URL). plan 안에서도 두 문장이 다르고, 일괄 재판정 실패 검사가 없다 | — |
| 6 | grounding·adversarial | 예상 비용($0.5~0.8, 판정 $0.2~0.3)에 근거가 없다. 상향 실측을 가격표로 늘리면 판정만 약 $0.6~0.9 이고 실행 한 번에 $1 을 넘는다 | adversarial 6번 |
| 7 | grounding | "호출 사이의 캐시는 거의 맞지 않았다" 는 과장이다. 판정 호출 26건 모두 입력의 약 20~40% 를 캐시에서 읽었다. 동시 실행이 원인인지는 확인하지 않았다 | — |
| 8 | grounding | 고정 입력 "약 1만 5천~2만 토큰" 은 실측(약 2.05만)보다 작다 | — |
| 9 | grounding | 하네스의 앞 단계 설정이 하나(Haiku high)뿐이라 Opus 판정 줄을 찾지 못한다. 단계별 앞 단계 설정을 바꾸는 수정이 없다 | — |
| 10 | adversarial | 시험 입력의 ref(`sco-f1` 등)가 정답을 드러내고, 일괄 입력은 모든 URL 의 ref 를 한 입력에 모은다 | — |
| 11 | adversarial | 판정 불가 기각 수를 참·오류로 나누지 않아, 오류 통과 감소가 탐지 때문인지 판정 불가 때문인지 구분되지 않는다 | — |
| 12 | adversarial | URL 사이의 구절 섞임을 정의 문장 하나로만 다루고, 내용 수준의 섞임을 확인하는 단계가 없다 | — |
| 13 | consistency | spec 「에이전트와 단계」 의 Verify 서술이 URL 마다 판정하는 흐름으로 남아 있다 | — |
| 14 | consistency | spec 「반환값과 계약」·「바뀌는 파일」·「채택 규칙」 이 없어진 상향 판정 에이전트를 아직 적는다 | — |
| 15 | consistency | 워크플로의 `nextStep`·`routeClaim`·`escalateClaims`·`ESCALATION` 상수를 지울 대상으로 지목하지 않았고, 판정 불가를 기각으로 바꾸는 위치도 정하지 않았다 | — |
| 16 | consistency | run.py 의 `next_step`·`route_claim`·`_escalate_claims` 사본을 새 규칙에 맞추라는 지시가 없다 | — |
| 17 | consistency·grounding | `report-v3` 와 그 시험의 처분, 그리고 `report-v4` 의 `--prev-replay`(앞 재측정 results-v3 와의 비교)가 정해지지 않았다 | grounding 5번 |
| 18 | consistency | `test_prior_art_contract.sh` 의 상향 정의 검사를 지우라는 지시가 없다 | — |
| 19 | consistency | `evals/prior-art-verifier/README.md` 에 바꿀 내용이 없다 | — |
| 20 | consistency | label 이 URL 없는 `judge`·`rejudge` 가 되어 SKILL.md 의 stages null 구별 규칙(URL 별 label)이 쓸 수 없게 된다 | — |
| 21 | consistency | 결정 기록 7 의 항목에 「틀리게 확신함」 이 없다 | — |
| 22 | grounding | score.py 가 판정·재판정 비용을 Haiku 설정으로 집계해, Opus 판정 비용을 세려면 단계 설정 상수를 바꿔야 한다 | — |
| 23 | fit | 할 일을 평서문으로 적은 문장이 Task 1 Step 1·Step 3, Global Constraints, Task 2 Step 3 에 섞였다 | — |
| 24 | fit | Task 2 Step 3·Step 5 의 Run 칸에 그대로 실행할 명령이 없다 | — |
| 25 | fit | Task 2 Step 2 의 Expected 에 구현 행동이 섞였다 | — |
| 26 | fit | Global Constraints 의 제약 일부가 서술어 없는 조각이다 | — |
| 27 | fit | 병합 조건을 이름 대신 개수로 가리켰다 | — |

## 커버리지 공백

어느 렌즈도 Claude Code CLI 2.1.305 에서 Opus 5.5 응답 하나의 출력 토큰 상한을 확인하지 않았다. 지적 1번의 위험 크기가 이 값에 달려 있다. 워크플로의 `agent()` 호출이 실패 시 재시도하는지도 확인하지 않았다.

<!-- spec-review: escalated -->
