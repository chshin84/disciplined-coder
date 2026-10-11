| 요청 | 조건 | 유효 실행 | 형식 오류 | 기대 분할 일치 | 판정 |
|---|---|---|---|---|---|
| bond-tool | new | 5 | 0 | 4 | 통과 |
| bond-tool | current | 5 | 0 | 5 | 비교 |
| report-quality | new | 5 | 0 | 4 | 통과 |
| report-quality | current | 5 | 0 | 5 | 비교 |
| auth-migration | new | 5 | 0 | 0 | 미달 |
| auth-migration | current | 5 | 0 | 5 | 비교 |
| order-processing | new | 5 | 0 | 5 | 통과 |
| order-processing | current | 5 | 0 | 0 | 비교 |
| two-jobs | new | 5 | 0 | 2 | 미달 |
| two-jobs | current | 5 | 0 | 5 | 비교 |
| npb | new | 5 | 0 | 3 | 미달 |
| npb | current | 5 | 0 | 0 | 비교 |

NOT ADOPT

실행 방식: `run_measure.py` 가 저장소 밖 임시 폴더에서 `claude -p --tools "" --setting-sources ""` 로 60회를 실행했다. 60회 모두 `num_turns` 1 이고 오류가 없었으며(`runs.log`), 형식 오류로 다시 실행한 회차는 없다.

미달 원인(현재 세션이 `tables` 를 읽고 적음):
- auth-migration 5회 모두와 two-jobs 3회, bond-tool·report-quality 1회씩은 소유 쪽이 정하고 사용 쪽은 받기만 하는 한 방향 관계(인증 인터페이스, 자격증명 형식, 검색 색인, 할인 방식)를 "아직 정해지지 않아 지금 고정할 수 없다"고 판정해 합쳤다. 이 관계는 순서로 둘 한 방향 설계 의존이다.
- npb 2회(1·4회)는 엔진 일별 상태를 공유 항목으로 열거하지 않아 rules·runner 를 합치지 않았다.

판정 오차: 실행마다 성공 확률이 독립이라고 가정하면, 한 실행에서 기대 분할을 낼 확률이 0.6인 규칙도 5회 중 4회 이상을 낼 확률이 약 34%이고, 0.9인 규칙도 4회 미만에 그칠 확률이 약 8%다.
