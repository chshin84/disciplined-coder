# nested-orchestration 설계 「2026-10-11 개정 — 묶는 단위」 리뷰 기록

대상은 `docs/superpowers/specs/2026-10-09-nested-orchestration-large-dev-design.md`의 「2026-10-11 개정 — 묶는 단위」 절(브랜치 `shared-definition-grouping`, 커밋 7008056 뒤 제목만 바꾼 상태)이다. 현재 세션은 경로가 `docs/superpowers/specs` 아래이므로 spec 으로 판정했다. 실행한 렌즈는 `lens-grounding`, `lens-consistency`, `lens-adversarial`, `lens-fit` 이고 원본은 같은 이름의 폴더에 있다. 원본은 렌즈 보고에서 근거 인용을 행 번호 위주로 줄여 옮겼다.

렌즈를 한 번씩만 실행했다.

현재 세션은 `lens-prior-art`를 제안하지 않았다. 개정의 근거가 같은 날 두 차례 선행연구 대조를 거쳤기 때문이다. 하나는 `2026-10-10-decomposition-criteria-prior-art.md`이고, 다른 하나는 `disciplined-coder-4c` 세션의 분할·조율 렌즈다. 인용 원문 네 건도 현재 세션이 웹 페치로 확인했다.

## 합친 지적 목록

| 지적 | 렌즈 원본 | 공동 |
|---|---|---|
| 상호 검증 의존 쌍에서 병합 순서가 정해지지 않고 먼저 병합하는 쪽이 미검증으로 들어간다 | consistency 1, adversarial 7 | 예 |
| 이미 병합된 대상이 원인인 통합 확인 실패의 복귀 경로가 없다 | adversarial 8 | 아니오 |
| 공유 정의 표를 승인 근거에 넣는다는 문장이 없다 | consistency 10, adversarial 9 | 예 |
| 정의 주인이 없음·복수인 행과 읽기만 하는 하위 프로젝트의 합침 대상이 정해지지 않았다 | adversarial 5, consistency 5, fit 5, grounding 4 | 예 |
| Parnas 권고 1번은 읽기만 하는 하위 프로젝트를 합치는 근거가 되지 않는다 | grounding 4 | 아니오 |
| 주인 없음 떼어냄 행은 제공자 칸을 채울 수 없고 계약 표에 일반 의미 칸이 없다 | consistency 3·4, adversarial 6 | 예 |
| '공유 정의 표'와 큰 명세 「공유 정의」가 같은 이름으로 반대 범위를 가리킨다 | consistency 2 | 아니오 |
| 「공유 정의」의 관례가 「결정 기록」의 명명 관례와 겹친다 | consistency 6 | 아니오 |
| 의존 순서 항목에 검증 의존을 함께 적으면 시작 의존과 구분되지 않는다 | consistency 7 | 아니오 |
| 통합 확인을 병합 전 검사에 넣는데 「가드레일」이 바뀌는 파일에 없다 | consistency 9 | 아니오 |
| 승인 근거·포인터 문장·연결 문장의 위치가 바뀌는 파일에 없다 | consistency 10·12·13 | 아니오 |
| axiomatic design 문장의 처분이 없다 | consistency 11 | 아니오 |
| 설계 의존 표는 활동 선후 관계라 time-based DSM 이고 partitioning 이 맞다. clustering 근거와 충돌한다 | grounding 3 | 아니오 |
| NP-bond-agg 검증 의존 서술은 관찰이 아니라 큰 명세의 계획이다 | grounding 1 | 아니오 |
| NP-bond-agg 큰 명세는 기각한 첫째 대안을 실제로 채택했다 | grounding 2 | 아니오 |
| '묶음 규칙 비교 연구 없음'의 출처 기록이 없다 | grounding 5 | 아니오 |
| 채택 기준끼리 충돌한다(4/5 허용과 5회 동일 비율) | adversarial 1 | 아니오 |
| 표적 요청 기준이 과도한 합침을 잡지 못한다 | adversarial 2 | 아니오 |
| 나머지 요청의 기준값이 현행 규칙 결과라 결함을 정답으로 삼는다 | adversarial 3 | 아니오 |
| 측정 입력을 규칙 작성자가 만들어 정답 단서가 들어갈 수 있다 | adversarial 4 | 아니오 |
| 검증 의존 채택 기준을 묶는 단계 입력으로 판정할 수 없다 | consistency 8 | 아니오 |
| 확인 방법에 SKILL 변경 확인 기준이 없고 측정 기록 위치가 정해지지 않았다 | consistency 14·15, fit 20 | 예 |
| 문체: 한 문장 두 개념, 다섯 문장 이상 단락, 주체 생략, 문서를 주체로 씀, 관형절 중간 삽입, 개수 지칭, '쓰는'·'분할'·'통합 검증' 용어 혼용, '주인' 신조어, 채택 기준 산문 나열 | fit 1~19 | 아니오 |
| 절 제목 형식이 앞 개정 절과 다르다 | fit 21 | 아니오 |

## 커버리지 공백

`lens-grounding`만 NP-bond-agg 기록 줄을 열었다. `lens-adversarial`은 같은 줄을 자동 모드 분류기 거부로 열지 못했다. 4c 세션의 계약 표 칸 정의는 어느 렌즈도 원문을 읽지 않았고 배경 파일의 요약만 받았다. axiomatic design 이 순환만 합친다는 앞 절 주장은 어느 렌즈도 원문과 대조하지 않았다.
