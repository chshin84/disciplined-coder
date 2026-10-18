# 에이전트원칙 개편 spec 리뷰 — 2026-10-18

대상은 `docs/superpowers/specs/2026-10-18-principles-positive-restructure-design.md` 다. 경로가 `docs/superpowers/specs` 아래이므로 spec 으로 판정했다. 렌즈를 한 번씩만 실행했다. 렌즈별 원본은 같은 이름의 폴더에 있다.

## 선행연구 렌즈의 판정

이 spec 은 아직 해본 적 없는 방식(원칙 전체의 긍정형 재작성과 실패 평가 세트)을 시도하므로 발동 기준에 해당한다. 다만 같은 날 같은 설계 구상을 대상으로 사용자가 직접 청한 선행연구 렌즈 6개를 이미 실행했고, 그 결과가 이 spec 의 근거다. 그 기록은 `2026-10-18-principles-positive-restructure-prior-art.md` 다. 그래서 이 차수에서 새로 제안하지 않았다.

## 합친 지적 목록

| 지적 | 잡은 렌즈 |
|---|---|
| 금지어 목록의 원본은 이 저장소 루트의 마크다운이다. 2026-10-06 에 JSON 대신 마크다운으로 두고 옛 저장소를 지우기로 정했다. spec 은 외부 저장소의 JSON 을 원본으로 보고 단계 4 를 그 저장소에 의존시킨다 | adversarial, consistency, 빌더 점검 |
| domain-korean 「지시문의 형태」는 금지어를 이름으로 대고 대체어를 함께 주는 형태를 실측으로 채택했다. 지시형 트랙에 금지어를 적지 않는다는 결정과 부딪친다 | consistency |
| 금지어 표를 파싱하는 훅·스크립트·시험과 표 밖 지시의 행선지가 영향 파일과 설계에 없다 | consistency, 빌더 점검 |
| 선행연구 기록 파일이 spec 작성 시점에 없었다 | grounding, adversarial, 빌더 점검 |
| 평가 세트의 원료인 사례 단위 자료가 저장소에 없고, 분석 메모는 세션 scratchpad 에만 있다. 과제에 사용자 메시지가 들어가는데 보관 방식이 없다 | adversarial, 빌더 점검 |
| 평가 세트의 실행 환경(원칙을 바꿔 끼우는 방법, 여러 턴 재생), 총 실행량, 판정 기준값, 동률 처리, 비교 기준선(개편 전 원칙 고정)이 없다 | adversarial, consistency, 빌더 점검 |
| 판정 모델로 쓸 수 있는 모델이 정해지지 않았다 | adversarial, 빌더 점검 |
| 극성 짝 실험이 어느 판정에도 쓰이지 않는다. 평가 세트 규모와 단계별 측정이 과설계일 수 있다 | adversarial |
| 후보 조항과 채택 판정이 같은 사례를 쓴다. 개발용과 보류용 구분이 없다 | adversarial |
| 단계 1 에 적용 조건 문구 변경이 섞이고, 단계 2 와 단계 3 이 이유 결합에서 겹친다 | adversarial |
| CLAUDE.md 의 클린룸 시험 교체가 비가역이고 교체 시점이 없다. test_docs_drift.sh 822-829행과 「삭제한 조항」 연결도 다루지 않는다 | adversarial, consistency |
| 불변 조건 초안의 `REVERSIBLE` 범위가 확인 과잉을 그대로 남긴다 | adversarial |
| 불변 조건 초안의 다른 세션 항목이 메모리 규칙(읽기 포함)보다 좁다 | adversarial, consistency |
| 충돌 쌍 목록과 충돌 제거 단계가 없다. 같은 상황에 함께 발동하는 쌍은 적용 조건 분리로 풀리지 않는다 | adversarial |
| 첫 문단 문장 삭제가 '해당 층을 모두 적용'까지 지운다. IHEval 은 역할 사이 지시 계층을 측정한 자료다 | adversarial |
| review-specs 의 '다시 리뷰는 매번 묻는다'와 review-docs 의 질문 규칙이 새 결정 규칙과 충돌하고, 렌즈 재실행 금지의 소유자 dispatching-lenses 가 범위 밖이다 | consistency |
| `LENS-ALLOWED`, 하네스 우선 문장, 「균형」 문단의 새 위치가 없다 | grounding, consistency |
| '지시문을 긍정 명령으로 쓰는 규칙'이 후보 목록에 없이 목차에 들어 있다 | consistency, 빌더 점검 |
| 한 ID 를 두 층이나 두 형식으로 나눌 때의 ID 규칙이 없다 | consistency |
| `TITLES` 의 대화 답 제외를 출력지시의 규정으로 잘못 적었다 | grounding |
| 배제 압력의 원인에서 `SECRETS` 와 웹 렌즈 승인이 빠졌다 | grounding |
| 영향 파일에 `skills/domain-pruning`, CLAUDE.md 30행이 없다 | grounding, consistency |
| 분량을 줄 수로만 기록한다 | adversarial |
| 병합 방식(단계마다 main 에 병합하는지)이 없다 | adversarial(notes), 빌더 점검 |
| 문체: 여러 문장짜리 불릿, 개수 예고, 문서를 주체로 쓴 문장, 풀지 않은 이름, 명사 조각 | fit |

## 커버리지 공백

`aggregating-lenses` 기준으로 아무도 보지 않은 관점은 없었다. 원칙 재작성의 대상인 조항 문안 자체는 아직 쓰이지 않았으므로 리뷰 대상이 아니었다.
