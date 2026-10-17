# 2026-10-18 spec 리뷰 3차 — 선행연구 에이전트

대상은 2차 리뷰를 반영한 `docs/superpowers/specs/2026-10-18-prior-art-agent-design.md`다. 경로로 spec 이라고 판정했다. 렌즈를 한 번씩만 실행했다. 렌즈마다 general-purpose 서브에이전트 하나를 썼고, 읽기 전용은 프롬프트로만 지시했다. 고친 파일을 보고한 렌즈는 없다. PREP 은 2차 반영판(`lens-prior-art` 삭제, `agent-prior-art` 신설)을 기준으로 새로 채웠고, 대화에서 사용자가 정한 결정을 렌즈에 주입했다.

## 선행연구 에이전트의 제안

제안하지 않았다. 1·2차와 같은 이유로, 같은 날 실행한 선행연구 차수를 근거로 쓴다.

## 하네스 표시

`lens-consistency`의 출력에 하네스가 "settings-json" 패턴 표시를 붙였다. 해당 문자열은 README 「끄는 법」의 `~/.claude/settings.json` 언급을 렌즈가 인용한 것이며, 렌즈에게 지시하는 문장은 아니었다.

## 합친 지적 목록

| 지적 | 잡은 렌즈 |
|---|---|
| 렌즈 그룹 공통 규칙(직접 요청을 승인으로 보기, 판정 기록, 서브 세션 처리)이 소유자를 잃고, review-specs·review-docs 의 위임 문장이 남는다 | adversarial, consistency, grounding |
| nested-orchestration 서브 세션 프로토콜이 '렌즈 그룹 판정'만 다루고 변경 목록에 없다 | grounding |
| review-specs·review-docs·aggregating-lenses·dispatching-lenses 에 변경 목록 밖의 `lens-prior-art` 전제 문장이 남는다(상한 포인터, 「가드」 포인터, 예외 문장, 자세 정의, `search_status` 조용한 통과 문장, 🔴 조건) | adversarial, consistency, grounding |
| 「인용 확인」과 review-specs 「웹에 나가는 렌즈의 인용 검증」이 서로를 범위의 소유자로 가리킨다 | consistency, grounding |
| `test_docs_drift.sh`의 review-docs 인용 검증 포인터 검사가 변경 목록에 없다 | consistency, grounding |
| 병합 전 시험이 설치된 main 캐시로 실행되어 브랜치의 구성을 싣지 못한다 | adversarial |
| 기준선에 검증자가 없어 '통과 사례 수'의 분모가 정의되지 않고 실행 짝이 없다 | adversarial, consistency |
| 기준선 프롬프트의 출처 커밋이 고정되지 않았다 | adversarial |
| 세션당 1회 넛지가 같은 세션의 두 번째 요청과 압축 뒤를 놓치고, 옛 이름 호출 경로와 표현 목록이 없다 | adversarial |
| 검증자가 쌍 단위로 수와 턴 상한 없이 실행된다(URL 단위로 줄이는 단순화안) | adversarial |
| survey 상황의 인용 확인이 결론 인용 전부라 분담의 목적이 이루어지지 않는다 | adversarial |
| 세션이 탐색 도중 끊긴 뒤의 처리가 없다 | adversarial |
| `synthesis`·`map-check`와 워크플로 반환값의 원본 이름에 실행 차례가 없다 | consistency |
| `verification_status`와 `search_status` 값 집합이 출력 스키마에 없다 | consistency |
| Haiku 비교의 '오판 수'가 정의되지 않았다 | consistency |
| 지도 대조 출력에 `principles_applied`가 없고 빈 값 처리가 없다 | consistency |
| 용어 표의 체크리스트에 기준선이, 질의 경계에 미공개 제품명이 빠졌고, 연구자 정의가 종합 모드와 맞지 않는다 | consistency |
| README 「끄는 법」의 '두 변수' 문장이 남는다 | consistency |
| 출력의 `lens` 칸 값과 `lens-derived` 열거가 지울 이름을 전제로 남는다 | fit |
| `maxTurns`가 도구 호출을 세지 않는다는 단정에 출처가 없다 | grounding |
| 같은 모델 렌즈 두 개의 일치를 선행 사례 부재의 보강 근거로 썼다 | grounding |
| 가드 인용 문장이 원문 글자와 다르다 | grounding |
| 문장 중간 관형절, 다섯 문장 단락, 여러 문장 불릿, 쉼표 둘, '정의 둘', `🔴`·PREP 미풀이, 주체 생략 | fit |

## 커버리지 공백

렌즈 네 개가 모두 실행되었다. `lens-fit`의 `doc_type`은 '설계' 행으로 채워졌다.
