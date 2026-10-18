# 에이전트원칙 개편 spec 2차 리뷰 — 2026-10-18

대상은 `docs/superpowers/specs/2026-10-18-principles-positive-restructure-design.md` 다. 1차 리뷰(`2026-10-18-principles-positive-restructure-review.md`)를 반영한 뒤 사용자가 바뀐 절만 다시 리뷰하기로 정했다. 그래서 메인 세션은 consistency 렌즈와 adversarial 렌즈만 한 번씩 실행했다. 대상 절은 「결정」, 「목차 구조」, 「금지어 2트랙」, 「검증과 단계」, 「저장소 규칙의 변경」, 「영향을 받는 파일」이다. 렌즈별 원본은 같은 이름의 폴더에 있다.

## 합친 지적 목록

| 지적 | 잡은 렌즈 |
|---|---|
| 극성 짝 실험 문장이 판단 조항을 금지형으로 남길 길을 열어 사용자 결정(판단 조항은 결정 규칙)과 부딪친다. 같은 문장의 '이유와 함께'가 단계 2 의 '이유는 아직 붙이지 않는다'와도 부딪친다 | consistency |
| 보류용 과제를 한 번만 쓴다는 결정과 후보마다 보류용으로 채택을 판정한다는 문장이 부딪친다 | consistency |
| 새 조항 후보 하나의 추가에 클린룸 소거 시험을 쓰는지 실패 평가 세트만 쓰는지 두 문장이 다르게 정한다 | consistency |
| 커밋하지 않은 수정이 있는 추적 파일의 덮어쓰기가 `REVERSIBLE` 의 불변 조건과 판단 조항 양쪽에 해당한다 | consistency |
| 다른 세션 변경과의 대조 방법이 없어, 직접 읽으면 불변 조건 셋째와 같은 행동이 된다 | consistency |
| `docs/domain-korean.md` 「지시문의 형태」의 실측(0건 대 3건)을 다른 비교로 옮겨 적었고, 대체어만 준 조건의 결과와 형태 채택 사유를 빠뜨렸다 | consistency |
| 상황 칸의 열 위치가 없고, 같은 파서를 쓰는 `hooks/stop_gates.sh` 와 파서 시험 `scripts/test_hooks.sh` 가 영향 파일에 없다 | consistency |
| 관리 폴더 파일 목록과 위생 화이트리스트를 소유하는 `scripts/_scaffold_common.sh` 와 지시형 트랙 파일의 이름이 없다 | consistency, adversarial |
| README 의 금지 표현 목록 적재 설명(3·41·80행)을 고치는 작업이 없다 | consistency |
| 첫 문단 문장 변경이 어느 단계에서 실행되는지 없다 | consistency |
| 이유 한 줄을 '목적 문장'·'목적 한 줄'로도 부르고, '목적 문장'이 다른 대상도 가리킨다 | consistency |
| 임시 설정 폴더에서도 SessionStart 의 scaffold.sh 가 설치된 플러그인의 원칙으로 사본을 덮어써, 개편안을 싣는 방법이 성립하지 않는다 | adversarial |
| 평가 세션의 스킬은 설치된 플러그인 버전에서 실려, 단계 2 의 스킬 변경이 측정되지 않는다 | adversarial |
| 여러 턴 재생에서 앞 턴의 Claude 응답을 고정하는지 생성하는지 정하지 않았다 | adversarial |
| 도구가 켜진 평가 세션이 실제 저장소에서 푸시하거나 파일을 덮어쓸 수 있다 | adversarial |
| 원자료가 세션 기록 한 파일에만 있고, 세션 기록 정리 기한(`cleanupPeriodDays`, 기본 30일) 안에 과제를 만든다는 순서가 없다 | adversarial |
| 기준 원칙의 커밋이 고정되지 않았고, 병합 전 main 을 가져온 뒤의 문안이 측정되지 않는다 | adversarial |
| 단계 1 은 적용 조건 문장을 바꾸지 않는다고 하지만 목차 표는 `REVISE-ORDER` 의 범위를 바꾸고 `NO-RAW-OUTPUT` 을 나눈다 | adversarial, consistency(notes) |
| `NO-RAW-OUTPUT` 을 나눌 때 「균형」 문단이 새 ID 를 가리키지 않게 된다 | adversarial |
| 단계를 되돌린 뒤 다음 단계를 어느 원칙 위에서 진행하는지 없다 | adversarial |
| 다른 플러그인이 금지 표현 목록을 싣는 상황을 다루지 않는다 | adversarial |
| CLAUDE.md 에 넣을 회귀 시험 문장에 평가 세트 경로와 실행 명령이 없다 | adversarial |
| 단계별 확인 기준에 판정 기준값과 동률 처리가 여전히 없다 | adversarial(notes) |
| 임시 설정 폴더의 인증, 사용자 전역 CLAUDE.md 와 메모리의 복사, 자동 갱신 여부가 정해지지 않았다 | adversarial(notes), consistency(notes) |

## 커버리지 공백

이번 차수는 바뀐 절만 대상으로 삼았으므로 grounding·fit 렌즈를 실행하지 않았다. 「선행연구에서 확인한 기준」의 점화 항목은 대상 절 밖이지만, consistency 렌즈가 「금지어 2트랙」과 함께 지적했다.
