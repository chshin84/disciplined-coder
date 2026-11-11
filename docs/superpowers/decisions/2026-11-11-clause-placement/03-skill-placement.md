# 3번 단계 스킬 배치 판정

spec `docs/superpowers/specs/2026-11-11-clause-placement-design.md` 「판정 순서」 3번 단계의 결정 기록이다. 1번 단계 기록(`01-decision-points.md`)이 특정 작업에만 적용된다고 표시한 조항을 후보로 보았다.

## 판정 기준

Claude 는 위임 기간의 결정 기준(spec 「기준선」)으로 후보마다 점수를 매겼다. 열림은 조항을 옮길 스킬이 그 작업에서 실제로 열리는지를 본다. 실질가치는 원칙에서 빼면 평시 컨텍스트가 줄어드는지, 되돌리기 쉬움은 커밋 하나로 원래대로 돌아가는지를 본다.

spec 은 열림 시험을 요구한다. Claude 는 훅이 스킬을 결정론으로 여는 후보에는 모델 실행 대신 훅 시험(`scripts/test_hooks.sh`)을 열림 근거로 썼다. 훅이 열지 않는 후보는 상주에 남겼다. 모델 실행 열림 시험은 비용이 크고, 훅 경로가 없는 후보는 시험해도 description 의존이 남기 때문이다.

## 후보별 판정

| 조항 | 옮길 스킬 | 열림 근거 | 판정 |
|---|---|---|---|
| `NO-RAW-OUTPUT` | `review-specs` | spec·plan 쓰기마다 PostToolUse 훅이 이 스킬을 지시하고, Stop 훅이 리뷰 없는 종료를 한 번 차단함 | 상주. 훅이 열지 않는 경로가 있음(「열림 점수 재검토」) |
| `SUB-ORCHESTRATE` | `nested-orchestration` | 새 spec 의 첫 Write 를 훅(`nested_judgment_pretooluse.sh`)이 거부하고 판단 기준을 알림 | 상주. 훅이 열지 않는 경로가 있음(「열림 점수 재검토」) |
| `LENS-ALLOWED` | `dispatching-lenses` | 렌즈를 실행하는 모든 경로(`review-specs`, `review-docs`, 사용자 직접 요청)가 이 스킬을 거침 | 상주. 훅이 열지 않는 경로가 있음(「열림 점수 재검토」) |
| `DELEGATED-SCORE` | 없음 | 위임 발언을 감지해 여는 훅이 없음 | 상주. 4번 단계로 넘김 |
| `REPORT-SCOPE` | `nested-orchestration` | 사용자가 다른 세션에 맡긴 일은 이 스킬이 열리지 않는 세션에서도 생김 | 상주. 4번 단계로 넘김 |
| `TONE-AXIS` | `managing-docs`(산출물 부분만) | 대화 답 부분은 모든 답에 적용됨. 조항을 나누면 문구가 바뀜 | 상주. 지적 10회라 5번 단계로 넘김 |
| `INSTRUCTION-FORM` | `dispatching-lenses`·`nested-orchestration` | CLAUDE.md·메모리·서브에이전트 프롬프트 쓰기는 두 스킬 밖에서도 생김 | 상주. 4번 단계로 넘김 |
| 「문서 관리」 절 머리 | `managing-docs` | 1번 단계가 삭제 후보로 표시함 | 7번 단계의 삭제 확인으로 넘김 |

## 점수

| 조항 | 열림(0~2) | 실질가치(0~2) | 되돌리기 쉬움(0~2) | 합계 |
|---|---|---|---|---|
| `NO-RAW-OUTPUT` | 1 | 1 | 2 | 4 |
| `SUB-ORCHESTRATE` | 1 | 1 | 2 | 4 |
| `LENS-ALLOWED` | 1 | 1 | 2 | 4 |
| `DELEGATED-SCORE` | 0 | 1 | 2 | 3 |
| `REPORT-SCOPE` | 0 | 1 | 2 | 3 |
| `TONE-AXIS` | 1 | 1 | 2 | 4 |
| `INSTRUCTION-FORM` | 1 | 1 | 2 | 4 |

합계 5인 조항만 스킬로 옮긴다. 열림이 2가 아니면 옮긴 뒤 조용한 누락이 생길 수 있어서, 열림 2를 필수 조건으로 두었다. 그래서 이 단계에서 스킬로 옮기는 조항은 없다.

## 열림 점수 재검토

Claude 는 처음에 세 조항의 열림을 2로 매겼다가, 5번 단계 집계 중 조항 문구를 훅 경로와 대조하고 1로 고쳤다. 고친 이유는 조항마다 아래와 같다.

- `NO-RAW-OUTPUT` 은 spec·plan 쓰기뿐 아니라 "기능을 바꿔 고치면" 에도 적용된다. 훅은 spec·plan 쓰기만 감지하므로 기능 수정 경로에서는 `review-specs` 가 열리지 않는다.
- `SUB-ORCHESTRATE` 는 "설계 문서가 있든 없든" 적용된다. 훅은 새 spec 의 첫 Write 만 거부하므로 설계 문서 없이 큰 개발을 시작하는 경로에서는 `nested-orchestration` 이 열리지 않는다.
- `LENS-ALLOWED` 는 렌즈를 실행할지 정하는 순간에 하네스 기본 지침("요청하지 않으면 서브에이전트를 호출하지 마라")을 넘기는 허가다. 그 결정은 `dispatching-lenses` 를 열기 전에 일어나므로, 허가를 스킬 안에 두면 렌즈를 실행하지 않기로 정한 세션은 허가를 읽지 못한다.

10번 단계의 입력인 지적 턴에는 이 세 조항의 지적이 없다(2번 단계 집계). 그래서 옮긴 뒤의 누락을 이번 시험으로 확인할 방법도 없다. 원칙 파일에서 빠지는 글자는 세 조항을 합쳐 약 1,500자이고, 이 절감은 확인할 수 없는 누락 위험보다 작다고 Claude 는 판단했다.
