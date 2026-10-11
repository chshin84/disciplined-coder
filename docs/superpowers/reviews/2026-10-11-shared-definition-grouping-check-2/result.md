| 요청 | 조건 | 유효 실행 | 형식 오류 | 기대 분할 일치 | 판정 |
|---|---|---|---|---|---|
| bond-tool | new | 5 | 0 | 5 | 통과 |
| bond-tool | current | 5 | 0 | 5 | 비교 |
| report-quality | new | 5 | 0 | 5 | 통과 |
| report-quality | current | 5 | 0 | 5 | 비교 |
| auth-migration | new | 5 | 0 | 4 | 통과 |
| auth-migration | current | 5 | 0 | 5 | 비교 |
| order-processing | new | 5 | 0 | 5 | 통과 |
| order-processing | current | 5 | 0 | 0 | 비교 |
| two-jobs | new | 5 | 0 | 0 | 미달 |
| two-jobs | current | 5 | 0 | 5 | 비교 |
| npb | new | 5 | 0 | 4 | 통과 |
| npb | current | 5 | 0 | 0 | 비교 |

NOT ADOPT

재측정 배경: 1차 측정(`…-check/`)이 NOT ADOPT 였고, 사용자가 문안 수정과 재측정을 골랐다. 현재 세션은 판정에 '순서'(고정할 수 없지만 사용 하위 프로젝트가 의미를 받기만 하면 합치지 않고 설계 의존 1로 둠)를 넣었다. 입력 목록, 기대 분할, 현행 규칙 문안은 1차와 같다. 60회 모두 `num_turns` 1 이고 오류가 없었으며, 형식 오류로 다시 실행한 회차는 없다.

미달 원인(현재 세션이 `tables` 를 읽고 적음): two-jobs 5회 모두 faqindex 와 faqsearch 를 합쳤다. 판정 이유는 모두 색인의 형태소 분석·구조와 검색 질의 분석이 색인 의미를 함께 정해야 한다는 것이었다. auth-migration 은 1회만 adapter·newprovider 를 합쳤다.
