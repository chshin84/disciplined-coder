# spec 리뷰 — 렌즈 그룹 재분류 (2026-10-03)

대상은 `docs/superpowers/specs/2026-10-03-lens-groups-design.md`(커밋 `4e51892`)이고, 경로가 `docs/superpowers/specs` 아래라 spec으로 판정했다. 렌즈는 `lens-grounding`, `lens-consistency`, `lens-adversarial`, `lens-fit`을 대상 하나에 하나씩 따로 실행했고, 쓰기 도구가 없는 에이전트 종류로 실행했다. 렌즈별 원본은 같은 이름의 폴더에 있다.

렌즈를 한 번씩만 실행했다.

## 선행연구 렌즈

제안하지 않았다. 이 spec은 이미 있는 렌즈 배정 규칙을 재편하는 설계이고, 그것이 되는지가 미지수인 새 일을 하려는 설계가 아니다.

## 합친 목록

근거로 든 파일과 줄을 열어 확인했고 거른 지적은 없다. 같은 지적을 여러 렌즈가 잡았으면 렌즈 칸에 모두 적는다.

| 지적 | 렌즈 |
|---|---|
| 「예외 목록」을 가리키는 `lens-consistency` 26행, `dispatching-lenses` 38·59행, `audit-repo-docs` 118행이 변경 목록에 없다 | grounding, consistency, adversarial |
| `review-docs` 42행이 공개 문서에 readability를 묻지 않고 실행하게 해 새 절과 충돌한다 | grounding, consistency, adversarial |
| `audit-repo-docs` description과 7·54·67행, `dispatching-lenses` description이 배정표와 예외 목록을 전제한 채 남는다 | grounding, consistency, adversarial |
| `review-docs`에서 실행한 선행연구의 인용 검증과 처분과 기록을 정한 곳이 없다 | grounding, adversarial |
| `lens-prior-art` 본문 첫 문단의 인용 문구가 실제와 다르다 | grounding |
| adversarial을 따로 실행하는 근거는 「예외 목록」이 아니라 `audit-repo-docs` 77행에 있다 | grounding |
| 선행연구 기록 수(7)가 저장소와 맞지 않는다 | grounding |
| 렌즈별 실행·지적 표의 세는 법이 없어 재현되지 않고, 결론에 쓰이지도 않는다 | grounding, fit |
| 옛 포인터 grep이 무관한 `test_docs_drift.sh` 413행과 새 검사 자신의 문자열에 걸려 늘 실패한다 | consistency |
| `audit-repo-docs`의 줄인 절에 새 이름이 없다 | consistency |
| '묶음'이 그룹 입력, 묶어 실행하는 방식, 짝 묶음 세 뜻으로 쓰인다 | consistency, fit |
| spec 리뷰에서 묶음 전체 그룹의 입력이 spec과 plan을 합친 하나인지 대상마다인지 정해지지 않았다 | consistency |
| 레포 감사의 consistency 입력이 그룹표의 '저장소 전체'와 다르다 | consistency |
| 필요할 때 그룹의 '따로 실행'이 무슨 뜻인지, 감사에서 에이전트 상한 안에 어떻게 드는지 정해지지 않았다 | consistency, adversarial |
| 그룹표의 '세 호출자 모두'가 렌즈 단위로는 거짓이고, 기각 이유가 채택안에도 해당한다 | consistency, adversarial |
| readability 발동 기준이 `lens-readability` 자신의 대상 문구와 `review-docs` 13행과 다르다 | consistency |
| `audit-repo-docs` readability 항목이 발동 기준의 조건 하나만 옮겼다 | consistency |
| '호출자' 정의가 `dispatching-lenses` 「호출자 목록」과 다르고, 사용자에게 묻지 못하는 L2를 다루지 않는다 | consistency |
| `review-docs`에서 검진 전 질문과 결과 전달 때의 제안이 겹쳐 질문이 둘 이상이 된다 | adversarial |
| 결과 전달 때 제안하면 기록이 이미 쓰였거나 봉인된 뒤라 승인 결과와 승인 여부를 남길 곳이 없다 | adversarial |
| `audit-repo-docs` 단계 표에 필요할 때 렌즈를 제안하는 단계가 없다 | adversarial |
| 그룹 정의의 '자세가 같은'이 표의 두 행과 맞지 않는다 | adversarial |
| 배정이 바뀐 뒤 첫 감사 차수의 발견 수 급증과 차수 대조 단절을 적지 않았다 | adversarial |
| 목록 앞에 개수를 예고하거나 이름 뒤에 맨 개수를 붙인 문장이 여럿이다 | fit |
| '차수'와 '짝'을 풀이하지 않았다 | fit |
| `A가 아니라 B` 대구가 두 번 나온다 | fit |
| 문장 중간에 긴 관형절이 있다 | fit |
| 여러 문장으로 된 불릿 항목이 있다 | fit |

## 커버리지 공백

렌즈 넷이 모두 결과를 돌려주었고 `principles_applied`가 빈 렌즈는 없다. 렌즈가 확인하지 못했다고 적은 것은 셋이다. `scripts/test_audit.sh`와 `scripts/test_docs_drift.sh` 밖의 검사 스크립트가 옛 절 이름에 기대는지, `claude plugin validate`의 결과, 다른 세션이 같은 스킬을 고치는지다.
