# nested-orchestration 계약 표 개정 리뷰 기록(2026-10-11, 2차)

대상은 1차 리뷰를 반영해 다시 쓴 `docs/superpowers/specs/2026-10-09-nested-orchestration-large-dev-design.md`의 「2026-10-11 개정 — 계약 표」 절이고, 짝 문서는 `skills/nested-orchestration/SKILL.md`다. 대상이 `docs/superpowers/specs` 아래에 있으므로 경로로 spec 이라 판정했다. 사용자가 다시 리뷰를 골라 렌즈 넷(grounding, consistency, adversarial, fit)을 대상 하나에 한 번씩 실행했다. 렌즈를 한 번씩만 실행했다. 선행연구 렌즈는 1차 기록과 같은 이유로 제안하지 않았다.

## 합친 지적 목록

| 지적 | 렌즈 원본 | 공동 |
|---|---|---|
| 소비자가 제공자보다 먼저 시험 병합되면 소비자 모듈이 import 할 때 제공자 모듈이 없어 계약 테스트가 생략되지 않고 실패한다 | adversarial A1 | 아니오 |
| 생략 여부 확인의 방법과 「가드레일」 「시험 병합」의 단계가 없어, 경로를 계약과 다르게 둔 구현이 생략으로 통과한다 | adversarial A2, consistency 1, fit notes | 예 |
| 공개 함수 모듈 파일을 누가 처음 만드는지 정하지 않았다 | consistency 2, fit 12 | 예 |
| 대역 구현이 필요한지 정하는 주체와 시점이 없고, 소비자가 따로 대역을 만들 수 있다 | adversarial A3 | 아니오 |
| 대역 구현의 단위·의미를 계약 표와 대조하는 단계가 없다 | adversarial A4 | 아니오 |
| 파일 계약의 단위 대조 방법과 제공자 미병합 때의 처리가 없다 | adversarial A5 | 아니오 |
| 의미 칸이 「결정 기록」의 관례를 가리키므로, 그 관례를 고치면 계약 변경 절차 없이 계약 의미가 바뀐다 | adversarial A6 | 아니오 |
| 넓어진 의미 칸이 자유 서술이 되어 승인 대조의 기준이 없다 | adversarial A7 | 아니오 |
| 적용 범위가 spec 에만 있고 스킬 본문에 없다 | adversarial A8 | 아니오 |
| spec 「결정」에 모듈 위치 규칙과 제공자 확인 대상 두 종류가 없다 | consistency 3 | 아니오 |
| 대역 구현과 그 위치를 여러 이름으로 부르고 풀이가 없다 | consistency 4, fit 8 | 예 |
| 공유 관례의 범위가 spec(시간·결측)과 SKILL.md(같은 관례)에서 다르다 | consistency 5, adversarial notes | 예 |
| 계약 표가 가리키는 관례가 큰 명세 리뷰 시점에 「결정 기록」에 있어야 한다는 순서가 없다 | consistency 6 | 아니오 |
| '이 출처들'에 Contract-Coding 을 함께 묶어 사람 조직 대상이라고 적었다 | grounding 1 | 아니오 |
| 제공자 확인 규칙만 넣는 안의 기각이 저장소 기록에 없다 | grounding 2 | 아니오 |
| 의미 칸 확장의 근거 지적이 다른 브랜치 기록에만 있고 spec 이 가리키지 않는다 | grounding 3, fit 7 | 예 |
| 다음 큰 개발의 측정 지시가 설계 문서에만 있다 | fit 1 | 아니오 |
| 문체: 불릿 항목의 여러 문장, 목록 말끝, N2 표 풀이 위치, 기록을 주체로 씀, 개수 예고와 서수, 수식어 중첩, 표 셀 말끝, '현재 세션'·'설계 문서'의 다른 대상 사용, 공용 설정 이름 혼용 | fit 2~6, 9~11, 13 | 아니오 |

## 커버리지 공백

네 렌즈 모두 결과를 돌려주었다. consistency 렌즈는 1차 consistency 지적 여섯이 모두 해소되었다고 적었다. adversarial 렌즈는 A1 이 실제로 생기는지가 「흐름」의 의존 해석에 달려 있고, 그 해석은 「묶는 단위」를 고치는 다른 세션의 범위라고 적었다.
