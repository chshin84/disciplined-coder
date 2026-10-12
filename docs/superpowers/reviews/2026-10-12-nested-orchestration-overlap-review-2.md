# nested-orchestration 명세 단계 개정 리뷰 기록(2026-10-12, 2차)

대상은 `docs/superpowers/specs/2026-10-09-nested-orchestration-large-dev-design.md`의 「2026-10-12 개정 — 명세 단계와 다시 나누기」 절이다. 1차 리뷰 뒤 사용자가 구조를 바꾸어 절을 다시 썼고, 사용자가 선행연구를 포함한 다시 리뷰를 골랐다. 현재 세션은 `lens-grounding`, `lens-consistency`, `lens-adversarial`, `lens-fit`을 대상 하나에 하나씩 실행했다. 렌즈를 한 번씩만 실행했다. 원본은 같은 이름의 폴더에 있다.

## 선행연구 렌즈

사용자가 이 차수에 선행연구 렌즈를 직접 골랐다(통상). 결과는 `2026-10-12-nested-orchestration-overlap-prior-art-2.md`에 따로 있다.

## 합친 지적

| 지적 | 잡은 렌즈 |
|---|---|
| 「진행 위치」가 「겹침 판정」 유무 하나로 단계를 갈라, 3단계 뒤 4단계 전 상태와 spec 브랜치를 지운 뒤 상태를 도출하지 못하고, 겹침이 없으면 절이 생기지 않을 수 있다 | grounding, consistency, adversarial |
| 4단계에서 만드는 실제 분할과 계약 표에 리뷰와 사용자 승인이 없고, 허용 경로·순환·제공자 행 확인이 걸릴 시점이 없다 | consistency, adversarial |
| 1단계에 임시 워크스트림을 나누는 규칙과 명세 단계 진입 판정의 입력이 없다 | consistency, adversarial |
| 명세 서브 세션의 답하지 않는 `AWAITING_APPROVAL`이 재시작 복구 규칙과 부딪힌다 | consistency, adversarial |
| 하부 명세를 지우는 「문서 수명」이 에이전트원칙의 spec 수명과 부딪히고, spec 브랜치 삭제 시점이 단계에 묶여 있지 않으며 명세 워크트리 정리가 없다 | grounding, consistency, adversarial |
| 흐름 6단계의 "지금과 같다"가 `계약 의미 확정:` 예외와 마무리 일괄 반영과 부딪힌다 | grounding, consistency |
| 완전체 명세의 절(임시 워크스트림 단위)과 구현 서브 세션의 '자기 절'(새 워크스트림 단위)을 잇는 규칙이 없다 | adversarial |
| 경계를 넘는 자료를 두 하부 명세가 다르게 정했을 때 값을 고르는 규칙이 없고, '다르면 따로 둠'과 섞인다 | adversarial |
| 임시 id 와 새 id 가 같으면 리포트가 같은 파일이 된다 | consistency, adversarial |
| 명세 단계 리포트의 `스스로 판정한 모호함` '예' 줄을 읽고 묻는 시점이 없다 | consistency, adversarial |
| 디스패치 직전의 「결정 기록」 커밋은 필요 없다 | adversarial |
| 실패 처리의 '현재 세션이 직접 쓰기' 선택지가 맡기면 직접 쓰지 않는다는 규칙과 부딪힌다 | consistency, adversarial |
| 완전체 명세가 Read 상한(25k 토큰)을 넘을 위험을 적지 않았다 | adversarial |
| 명세 단계 토큰과 `BASE-UPDATED` 수를 남길 곳이 없다 | consistency, adversarial |
| 「다시 나누기」 두 문단이 기다림 여부와 소유 없는 결정의 구현 주체에서 부딪힌다 | consistency |
| 다른 저장소의 독립 작업을 '지금처럼' 맡기면 하부 명세 승인 경로가 남는데 `APPROVE`를 없앤다 | grounding |
| 고칠 목록에서 「계약 코드」, 「FAILED와 CANCELED」, 「언제 쓰는가」 첫 문단, 「측정」, 공유 가정 규칙, 프로토콜 `REVISE`·`CONTRACT-CHANGED`·`RESTART` 행과 상향 공통 필드, 리포트 `명세 이탈`, `review-specs` 131행이 빠졌다 | grounding, consistency |
| 확인 방법이 고칠 곳 일부만 덮고 한 항목은 이미 참이다 | consistency |
| '열여덟 가지'가 1차 기록의 합친 지적 행 수와 다르다 | grounding, consistency |
| 「바꾼 이유」가 공유 가정 전파를 '구현 중'으로 적었으나 현행은 하부 명세 승인 때다 | grounding |
| 「검증하지 않은 가정」이 1차 선행연구의 미발견 대상을 채택안으로 옮겨 적었다 | grounding |
| 문체: 다섯 문장 넘는 단락, 판단 주체, 관형절 끼움, '남은 것', 자리표시자 표기 불일치 | fit |

## 커버리지 공백

배정된 렌즈 넷이 모두 결과를 돌려주었다. 표시할 공백은 없다.
