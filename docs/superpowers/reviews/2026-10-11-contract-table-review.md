# nested-orchestration 계약 표 개정 리뷰 기록(2026-10-11)

대상은 `docs/superpowers/specs/2026-10-09-nested-orchestration-large-dev-design.md`의 「2026-10-11 개정 — 계약 표」 절이고, 짝 문서는 그에 맞춰 고친 `skills/nested-orchestration/SKILL.md`다. 대상이 `docs/superpowers/specs` 아래에 있으므로 경로로 spec 이라 판정했다. 렌즈 넷(grounding, consistency, adversarial, fit)을 대상 하나에 한 번씩 실행했다. 렌즈를 한 번씩만 실행했다.

선행연구 렌즈는 이 차수에 따로 제안하지 않았다. 사용자가 같은 주제의 선행연구를 직접 요청해 이미 실행했고, 그 기록이 `docs/superpowers/reviews/2026-10-11-contract-table-prior-art.md`에 있기 때문이다. 그 발견은 사용자에게 전달했고, 사용자는 칸 안을 고르는 결정으로 처분했다.

## 합친 지적 목록

| 지적 | 렌즈 원본 | 공동 |
|---|---|---|
| 예외 스텁을 워크스트림 경로에 두면 첫 시험 병합의 계약 테스트가 아직 병합되지 않은 워크스트림의 스텁 때문에 실패한다 | consistency 1, adversarial A1 | 예 |
| import 만으로는 예외 스텁이 실행되지 않으므로 '스텁이 남으면 실패한다'는 단정이 계약 테스트가 함수를 호출할 때만 성립한다. NP-bond-agg 계약 plan 은 시그니처 대조와 미병합 모듈 건너뛰기를 쓴다 | grounding 5, fit 2, adversarial A2 | 예 |
| 예외 스텁은 소비자의 단위 테스트에 쓸 수 없고, 실제 사례는 현재 세션 경로의 합성 구현을 썼다 | adversarial A2 | 아니오 |
| 스텁 규칙은 함수 계약에만 성립하고 파일·CLI·HTTP 계약에는 없다 | adversarial A4 | 아니오 |
| 스텁 모듈과 타입 경로를 큰 명세 어디에 적는지 정하지 않았다 | consistency 4 | 아니오 |
| 32건에 기존 규칙 지적(3차 C10·C11)이 들어 있어 이번 개정에 대응하는 건수는 30건이다 | consistency 2, grounding 1 | 예 |
| SKILL.md 는 47건을 '계약을 다룬 지적'이라 불러 spec·기록과 모집단이 다르다 | consistency 3, grounding 2, fit 1 | 예 |
| '제공자가 없는 자료(16건)'는 대응표 행(제공자·소비자와 함수 입력)보다 좁다 | grounding 3 | 아니오 |
| SKILL.md 가 현재 세션의 분류를 측정된 사실처럼 단정한다. 수치는 spec 으로 옮기는 편이 낫다 | adversarial A8, fit 1 | 예 |
| 선행 근거의 표준별 필드 귀속과 '정확도·보안'이 저장소 기록에 없고, 채택 칸에 필수 여부 칸이 없다 | grounding 4 | 아니오 |
| 승인 항목이 이름·형식·단위는 계약 코드로, 시간·결측은 계약 표로 대조하게 해 원본이 둘이다 | consistency 5 | 아니오 |
| spec 「결정」에 승인 항목 변경과 타입 경로 규칙의 근거가 없다 | consistency 6 | 아니오 |
| 진행 중인 개발(NP-bond-agg)에 이 개정을 적용하는지 정하지 않았다 | adversarial A3 | 아니오 |
| 제공자 행 확인이 작성자 자기 확인이라 형식적으로 끝나도 드러나지 않는다 | adversarial A5 | 아니오 |
| 시간·결측 의미를 행마다 적으면 공유 정의와 중복되고 함수 행에는 채울 것이 없다 | adversarial A6 | 아니오 |
| 공용 로더가 워크스트림 설정 파일을 읽으면 BLOCKED 가 그대로 생긴다 | adversarial A7 | 아니오 |
| 제공자 확인 문장의 수식 범위가 두 가지로 읽힌다 | fit 3 | 아니오 |
| 항목 목록 불릿 하나만 서술문으로 끝난다 | fit 4 | 아니오 |
| spec 절에 결정·기각·비교의 주체가 없다 | fit 5 | 아니오 |
| spec 선행 근거 문장에 관형절이 끼어 있다 | fit 6 | 아니오 |
| 개정 절 사이의 우선 규칙이 새 절에 없다 | fit 7 | 아니오 |

## 커버리지 공백

네 렌즈 모두 결과를 돌려주었다. 범위 밖 관찰로 consistency 렌즈는 실행이 끝난 plan `docs/superpowers/plans/2026-10-09-nested-orchestration-large-dev.md`에 옛 칸 '호출 방향'이 남아 있다고 적었다.
