# 2026-10-18 spec 리뷰 — 선행연구 에이전트 탐색 워크플로 하부 명세

대상은 `docs/superpowers/specs/2026-10-18-prior-art-agent-specworkflow-design.md`다(브랜치 `spec/prior-art-agent/specworkflow`의 워크트리). 경로가 `docs/superpowers/specs` 아래이므로 명세 서브 세션이 spec 으로 판정했다. 짝 문서는 큰 명세 `docs/superpowers/specs/2026-10-18-prior-art-agent-design.md`다. 렌즈를 한 번씩만 실행했다. 렌즈마다 쓰기 도구가 없는 Explore 서브에이전트 하나를 썼고, 고친 파일을 보고한 렌즈는 없다.

## 선행연구 에이전트의 제안

제안하지 않았다. 이 하부 명세는 큰 명세가 이미 리서치를 마친 설계의 구현 명세이고, 명세 서브 세션은 사용자와 대화할 수 없다. 현재 세션의 디스패치 지시도 제안하지 말라고 정했다.

## 합친 지적 목록

| 지적 | 잡은 렌즈 |
|---|---|
| 순수 함수 `classify`가 `log()`를 불러 순수하지 않고, `fn` 명령에는 가짜 훅이 없다 | consistency, adversarial |
| 출력 스키마 상수의 규칙('읽는 칸만 required')과 표가 서로 다르다 | consistency |
| 판정을 빠뜨린 검증자를 `verify_failed`에 넣어 큰 명세의 검증 실패 정의를 넓힌다 | consistency |
| `supported`를 받은 항목이 `passed`와 `verify_failed`에 함께 들 수 있는데 분할로 적었다 | consistency, adversarial |
| 큰 명세 2단계의 '사유와 함께'에 대응하는 사유의 위치가 없다 | consistency |
| 종합 모드 입력의 `question`·`target` 출처와, 종합·지도 대조 입력의 키 집합 단언이 없다 | consistency |
| 순수 함수 본문의 규칙 여럿을 계약 테스트가 덮지 않는다 | consistency |
| `phase` 값, `null` 검증자의 `verifier_count` 계수, 종합 실패 때 지도 대조 생략에 단언이 없다 | consistency |
| 통과한 근거 지도 행을 네 이름으로 부른다 | consistency, fit |
| 가짜 `parallel`만 치명 예외를 구별해, 스크립트가 예외를 삼키거나 thunk 안 후처리가 던지면 `null`로 숨는다 | adversarial |
| 결과를 공유 배열에 모으면 시험 도구와 런타임의 차례가 다르다 | adversarial |
| 근거 지도 행의 빈 문자열 URL 이 묶음을 만든다 | adversarial |
| `path-shape`가 `HTTP/1.1`을 잡고, 괄호·쉼표가 붙은 경로와 맨 파일 이름을 놓친다 | adversarial |
| heredoc 구분자를 따옴표로 감싸라는 규칙이 없다 | adversarial |
| `[실패 행선지]`의 마지막 단언이 항진이다 | adversarial |
| 근거 지도 행의 주장 문장 형태가 `specagents`에 넘어가지 않는다 | adversarial |
| 시험 도구의 실행 모드(엄격 모드)가 정해지지 않았다 | adversarial |
| `meta` 구간의 끝 줄 정의가 두 가지로 읽힌다 | adversarial, consistency(notes) |
| `model` 옵션이 정의의 값을 덮어쓴다는 주장이 확인되지 않은 추론이다 | grounding |
| 동시 실행 한도가 `min(16, CPU 수 - 2)`인데 '기본 16'으로 적었다 | grounding |
| `agent()`의 `null`에는 사용자의 건너뛰기도 든다 | grounding |
| Git Bash 의 인자 경로 변환 주장에 출처나 가정 표시가 없다 | grounding, fit |
| 공용 유틸리티 목록에 없는 `json_run`을 이유 없이 쓴다 | grounding |
| 문서·행·절을 판단 주체로 쓴 문장이 있다 | fit |
| 표 열 안의 말끝이 섞였다(행선지 열, 조건 열, 반환값 이유 열, 스키마 표) | fit |
| 네 문장을 넘는 단락과 여러 문장 불릿이 있다 | fit |
| 연결어미 뒤 쉼표가 둘인 문장, 문장 중간 관형절, 겹친 수식어가 있다 | fit |
| 개수로 대상을 가리키거나 목록 앞에 개수를 예고한다 | fit |
| 같은 함수 묶음을 여러 이름으로 부른다 | fit |
| `specagents`를 풀지 않았다 | fit |

## 커버리지 공백

배정된 렌즈 네 개(`lens-grounding`, `lens-consistency`, `lens-adversarial`, `lens-fit`)가 모두 실행되었고, 모두 `principles_applied`를 채웠다. `lens-fit`의 `doc_type`은 '설계' 행으로 채워졌다. 렌즈가 더 확인할 것으로 남긴 항목은 런타임의 엄격 모드 여부, `label`의 길이 제한과 이어 실행 캐시 키, `agentType`과 `opts.model`을 함께 쓸 때의 모델, `meta.phases` 제목 일치를 런타임이 요구하는지다. 넷 모두 런타임 실측이 필요해 이 차수의 렌즈로는 볼 수 없었다.
