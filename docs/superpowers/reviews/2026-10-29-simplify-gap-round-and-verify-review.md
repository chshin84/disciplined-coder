# 공백 라운드·검증 분류·렌즈 MODE 줄 단순화 — spec 리뷰 기록

대상은 `docs/superpowers/specs/2026-10-29-simplify-gap-round-and-verify-design.md` 다. 파일이 `docs/superpowers/specs` 아래에 있어 spec 으로 구분했다. 메인 세션은 렌즈를 한 번씩만 실행했다. 실행한 렌즈는 `lens-grounding`(spec), `lens-consistency`(spec), `lens-adversarial`(design), `lens-fit`(auto)이다. 원본은 같은 이름의 폴더에 있다.

## 선행연구 제안

메인 세션은 선행연구 스킬을 제안하지 않았다. 이 spec 은 기존 절차의 규칙을 줄이는 정리이고, 같은 주제의 선행연구를 2026-10-28 에 이미 실행했기 때문이다(`2026-10-28-gap-round-and-lens-agents-prior-art.md`).

## 둘 이상의 렌즈가 함께 지적한 항목

- D1 이 기각한 주장의 품질 저하가 상태 값으로 드러나지 않는다(adversarial 2, grounding 2). 기각된 주장 중 확인 부족으로 기각된 건을 반박된 건과 구별하는 규칙이 없다.
- D1 의 효과를 다음 실행에서 무엇으로 판정할지 정하지 않았다(adversarial 3, consistency 4, fit 9).
- D2 의 턴 상한 신호는 워크플로가 읽지 않으므로 관측할 수 없다(adversarial 4, consistency 7).
- D3 의 근거와 범위가 맞지 않는다. 런타임 시험 3 은 모드가 둘인 렌즈의 사례이고(grounding 3), 규칙이 렌즈마다 모드 수를 알아야 하는 조건부 규칙이 되며(adversarial 7), dispatching-lenses 170행도 MODE 줄을 채우라고 지시한다(consistency 2).

## 렌즈 하나만 지적한 주요 항목

- grounding 1: D1 은 2026-10-22 사용자 결정(2026-10-20 spec 「Opus 일괄 판정」, "원문에 근거가 있는데 추출 검증자가 찾지 못했을 수 있다")을 뒤집으면서 그 결정을 적지 않았다.
- consistency 1: D1 이후에도 보충 출력의 존재 불일치·구절 없음은 검증 실패로 남아, 처음 추출의 같은 결과(기각)와 처리가 다르다.
- consistency 3: D2 는 묻는 조건만 정하고 실행 대상을 정하지 않았다.
- adversarial 5·6: D2 신호는 통과 0건인 하위 질문을 놓친다. 사용자 요청 때만 실행하는 안이 더 단순하다.
- grounding 4: 근거 둘째 항목의 사용자 지시 인용에 출처가 없다.
- fit 1~9: 불릿 안의 여러 문장, 명사구 말끝, 관형절, '것'·'곳', 주체 누락, 가정 표시 누락.

## 커버리지 공백

렌즈 네 개 모두 `principles_applied` 를 적었다. adversarial 은 `test_lens_contract.sh` 를 읽지 않았다고 적었고, consistency 가 그 파일을 읽었다.

## 걸러 낸 지적

- consistency 6(D3 확인 방법이 변경 전 문서도 통과시킨다): 메인 세션이 D3 를 빼기로 처분하면 대상이 사라지므로 처분 목록에 넣지 않았다.
- fit 의 축 충돌 메모: spec 은 `TONE-AXIS` 의 작업 지시서 산문 고정을 따르므로 렌즈 판정대로 둔다.

## 처분 구분

- `🔴` D1: 2026-10-22 사용자 결정을 뒤집는 결정이고, 고치는 방향이 여럿이다(기각과 별도 집계, 검증 실패로 두되 `partial` 에서 제외, 현행 유지). 사용자 가치판단이 필요하다.
- 고칠 항목: D2(턴 상한 신호 삭제, 실행 대상 명시, 근거 출처), D3(근거가 성립하지 않아 결정에서 빼고 「하지 않는 것」으로 옮김), fit 문체 지적 전부.
