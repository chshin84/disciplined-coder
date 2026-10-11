# nested-orchestration 계약 표와 조율 형식 선행연구 대조 기록(2026-10-11)

사용자가 NP-bond-agg 큰 개발 세션을 근거로 nested-orchestration 에서 정형화할 항목을 검토하라고 직접 요청했다. 그래서 현재 세션은 `lens-prior-art` 를 통상 상한(서브에이전트 둘)으로 실행했다. 렌즈 하나는 계약·인터페이스를, 다른 하나는 분할 기준과 조율 프로토콜을 맡았다. 두 렌즈 모두 `search_status` 가 `ok` 였다. 렌즈 원본은 같은 이름의 폴더(`lens-prior-art-1.json`은 계약·인터페이스, `lens-prior-art-2.json`은 분할·조율)에 있고, 아래는 현재 세션이 옮긴 요지다.

## 관찰 대상

NP-bond-agg 저장소 `dev/npb` 의 큰 명세(`docs/superpowers/specs/2026-10-11-npb-backtest-design.md`)와 그 3차·4차 리뷰 기록(`docs/superpowers/reviews/2026-10-11-npb-backtest-design-review-3*`, `-review-4*`)이다. 관찰 시점에 그 세션은 큰 명세 승인 뒤 계약 코드 plan 을 쓰고 있었고, 서브 세션은 아직 실행되지 않았다.

## 계약·인터페이스 렌즈의 지적

| 지적 | 유형 | 출처 |
|---|---|---|
| 계약 표의 이름·형식·단위·호출 방향 칸은 인터페이스 문서와 데이터 계약 표준 필드의 일부다. 제공자·소비자, 범위·열거값, 시간 의미, 필수·결측, 버전 칸이 없다 | crowded | NASA SWEHB 인터페이스 설계 기술(swehb.nasa.gov/x/rYCRC), Wikipedia 「Interface control document」, ODCS(DataHub 문서) |
| 설계 의존 행렬만 있고 자료 흐름 행렬(N2 chart)이 없어 소비자만 있고 제공자가 없는 자료를 구조로 검출하지 못한다 | known-failure | Wikipedia 「N2 chart」, Pact 문서 |
| 시간 의미(값이 정해지는 시점, 빈도, 채움) 칸이 없다 | known-failure | NASA SWEHB, datacontract 「service levels」, Glassnode 「point-in-time data」 |
| 스텁에서 구현으로 잇는 방식과 결과 객체의 열(사후조건)을 고정하라는 지시가 없다 | known-failure | Contract-Coding(arXiv 2604.13100, 프리프린트)이 보고한 빈 뼈대 파일, 호출되지 않는 구현, import 경로 불일치 |
| 리포트와 1층·2층 메시지에 스키마가 없다 | known-failure | MetaGPT(arXiv 2308.00352), SEMAP(arXiv 2510.12120, 프리프린트), A2A 명세 |
| 공용 파일을 한 주체가 단독 소유하면 병목이 된다 | known-failure | Aviator 블로그(측정 없음), Contract-Coding 의 전역 공유 지식 |

렌즈는 계약 필드를 늘리면 통합 실패가 줄어드는지 필드 단위로 측정한 연구를 찾지 못했다. SEMAP 과 Contract-Coding 모두 구성 요소별 ablation 이 없다.

## 분할·조율 렌즈의 지적

| 지적 | 유형 | 출처 |
|---|---|---|
| 스킬은 순환만 합치는 근거로 DSM 분할을 인용하지만, 분할은 활동 순서 DSM 의 기법이고 구성 요소 DSM 은 결합 강도 clustering 으로 분석한다. Parnas 는 공유 자료 구조와 그 접근 절차를 한 모듈에 두라고 권한다 | refuted-premise | Wikipedia 「Design structure matrix」, dsmweb 「Tearing a DSM」, Parnas(1972), Wahdan 등(ICORES 2016) |
| 설계 의존만 적고 검증 의존(완료 확인에 다른 워크스트림의 통합이 필요한 관계)을 적는 칸이 없다 | known-failure | RUP 「Plan System Integration」, MAST(arXiv 2503.13657), Pact can-i-deploy |
| 계약 변경을 한 번에 바꾸고 통지하며, 병행 변경(Parallel Change)과 비교하지 않았다 | weak-baseline | martinfowler.com 「ParallelChange」, Pact can-i-deploy |
| 상태 값 셋과 산문 리포트만 있고, `BLOCKED` 가 서로 다른 사유를 모두 덮으며 실패·거절·취소 값이 없다 | known-failure | MAST, A2A 명세 TaskState, MetaGPT |

MAST 는 통신 형식 표준화만으로는 에이전트 사이 불일치가 충분히 줄지 않는다고 적었다. socio-technical congruence 는 결과가 엇갈려 근거로 쓰지 않았다.

## 리뷰 지적과 제안 칸의 대응

현재 세션은 NP-bond-agg 3차·4차 리뷰의 adversarial·consistency 지적 47건을 칸 하나씩에 대응시켰다. 그 칸이 있었으면 큰 명세 작성 때 빈 칸으로 드러났을 지적만 대응시켰다. 문체(fit)와 출처(grounding) 지적은 계약 칸과 무관하여 뺐다.

| 칸 | 3차 | 4차 | 합계 |
|---|---|---|---|
| 제공자 → 소비자(함수 입력 포함) | A1 A3 A4 C1 C3 C4 C5 C7 C9 C15 | A5 C1 C6 C7 C8 C9 | 16 |
| 결과 열·산출 파일 | C6 C14 | A7 C4 C5 | 5 |
| 시간 의미 | A2 A6 | A2 A4 | 4 |
| 소유자(공용 파일) | C10 C11 | A9 | 3 |
| 열거값(키) | 없음 | A10 C2 | 2 |
| 결측 의미 | 없음 | A3 | 1 |
| 연결 방식 | 없음 | A1 | 1 |
| 버전·변경 | A10 | 없음 | 1 |
| 대응 없음 | A5 A7 A8 A9 A11 C2 C8 C12 C13 | A6 A8 A11 C3 C10 | 14 |

대응 없음의 내역은 분할 문제(3차 A7·A8·C2), 검증 의존(4차 A11·C10), 도메인 공유 정의(3차 A5·C8, 4차 C3), 통합 확인 강도(3차 A9, 4차 A6), 재현 검사 승인 기준(4차 A8), 설정 누락(3차 A11), 이름 드리프트(3차 C12·C13)다. 이 대응은 현재 세션의 판단이며, 칸이 있었으면 공백이 실제로 막혔으리라는 효과는 측정하지 않았다.

## 처분

사용자는 근거가 있는 칸만 넣는 안을 골랐다. 버전 칸과 표준 필드 전부를 넣는 안은 대응 지적이 0~1건이라 넣지 않았다. 상태 값과 메시지 형식은 NP-bond-agg 의 서브 세션 단계를 관찰한 뒤 정하기로 미뤘다. 분할 기준과 검증 의존은 같은 날 다른 세션(disciplined-coder-f0)이 맡기로 두 세션이 합의했다. 그래서 분할·조율 렌즈의 앞 두 지적은 그 세션에 메시지로 전했다.
