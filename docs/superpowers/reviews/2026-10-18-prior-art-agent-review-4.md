# 2026-10-18 spec 리뷰 4차 — 선행연구 에이전트 임시 분할

대상은 `nested-orchestration`의 임시 분할을 보강한 `docs/superpowers/specs/2026-10-18-prior-art-agent-design.md`다(통합 브랜치 `dev/prior-art-agent`의 통합용 워크트리). 경로로 spec 이라고 판정했다. 이번 차수에 새로 쓴 절은 「워크스트림 분할」과 「결정 기록」이고, 렌즈는 그 두 절과 그 절이 가리키는 본문을 보았다. 렌즈를 한 번씩만 실행했다. 렌즈마다 general-purpose 서브에이전트 하나를 썼고, 읽기 전용은 프롬프트로만 지시했다. 고친 파일을 보고한 렌즈는 없다.

## 선행연구 에이전트의 제안

제안하지 않았다. 이번 차수의 새 내용은 이 저장소의 `nested-orchestration` 절차를 적용한 분할이라, 아직 해본 적 없는 것을 해내려는 내용이 아니다.

## 합친 지적 목록

| 지적 | 잡은 렌즈 |
|---|---|
| 「스킬 등재」 검사 때문에 `specagents`가 `specrefs`에 검증 의존하며, 적힌 방향과 반대이거나 두 방향이 함께 있어 순환이 된다 | adversarial, consistency, grounding |
| 워크플로 `args`·반환값의 키 이름과 검증자·지도 대조 출력의 바깥 형식이 spec 본문에 없고 plan 초안에만 있어 떼어냄 판정이 성립하지 않는다 | consistency, grounding |
| 워크플로가 연구자·검증자에게 보내는 프롬프트의 모드 표기와 입력 배치가 공유 항목으로 고정되지 않았다 | adversarial |
| 연구자 프롬프트 대조 검사의 위치가 「구성」·「기존 파일과의 관계」와 「같은 파일」에서 다르다 | adversarial, consistency |
| `lens-prior-art` 삭제가 그 내용을 옮기는 워크스트림과 다른 워크스트림에 있다 | adversarial |
| `agentType` 실측을 맡은 주체가 없다 | adversarial |
| `specnudge`는 조율 비용이 산출물보다 크다 | adversarial |
| `skills/domain-plugin/SKILL.md`와 `sub-session-protocol.md`의 담당이 이름으로 정해지지 않았다 | consistency |
| '다섯에 못 미쳐' 문장이 `specrefs` 행(다섯 항목)과 상충한다 | consistency, fit |
| 설계 의존 표와 의존 순서 표가 표로 없다 | consistency, fit |
| 공통 제약 항목이 없다 | fit |
| 「시험 계획」의 'plan 의 마지막 단계' 문장이 분할과 상충한다 | consistency |
| 원본 파일 이름 규칙은 명명 관례라 공유 항목 행이 아니고, 본문 이름과도 다르다 | fit |
| `현재 세션`·`서브 세션` 등이 「용어」 표의 `설계 세션`·`빌더`와 다른 체계로 풀이 없이 쓰였다 | fit |
| 대상을 개수로 가리켰다 | fit |
| 실행하지 않을 plan 초안을 입력으로 지정하고 처분을 적지 않았다 | fit |
| 묶음 FAIL 수 세기가 요약 줄과 'FAIL-OPEN' 설명을 함께 센다 | adversarial, grounding |
| stdin 읽기 관례가 큰 입력 훅에 쓰지 않는 방식이다 | adversarial, grounding |
| 훅 이름·`set` 줄 관례에 예외 파일이 있다 | grounding |

## 커버리지 공백

렌즈 네 개가 모두 실행되었다. `lens-fit`의 `doc_type`은 '설계' 행으로 채워졌다.
