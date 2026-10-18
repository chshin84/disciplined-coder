# 에이전트원칙 행동·출력 재편 plan 리뷰 1차

대상은 `docs/superpowers/plans/2026-10-18-principles-action-output-split.md` 이다. 경로가 `plans` 아래라 plan 으로 판정했다. 렌즈를 한 번씩만 실행했다. 실행한 렌즈는 `lens-grounding`·`lens-consistency`·`lens-adversarial`·`lens-fit` 이고, 원본은 같은 이름의 폴더에 있다. plan 이므로 선행연구 에이전트는 제안하지 않았다.

## 합친 지적

| 지적 | 잡은 렌즈 |
|---|---|
| hook 메시지에 절 이름을 둘 적으면 `test_hooks.sh` 가 실패하고, 그 파일이 plan 에 없다 | grounding, consistency |
| Task 1 Step 2 의 Expected 가 실제 FAIL 과 다르다 | grounding, consistency |
| `EDIT-PRIORITY` 근거를 옮기라면서 domain-korean 의 같은 절에 적으라고 하고, 비게 되는 `REVISE-ORDER` 절과 lens-readability 포인터의 처분이 없다 | consistency, adversarial |
| domain-korean 224행의 현재 진술과 「고칠 순서」가 고칠 대상에서 빠졌다 | consistency |
| Task 2 Step 1 의 Expected 가 실제 grep 결과와 다르다(evals README 는 낫표 없는 라벨) | grounding |
| Task 3 Step 2 가 이유 줄만 찾아 spec 의 완성 문장 확인을 덮지 못하고, 찾을 문자열이 정해지지 않았다 | grounding, consistency, fit |
| '클린룸 시험 없이 넣었다'와 되돌릴 계기의 확인 단계가 없다 | grounding, consistency |
| Task 3 의 검증 단계가 Task 1 산출물을 검증하며, 수정 뒤 커밋 단계가 없고 Files 블록이 실제와 다르다 | consistency, fit |
| Task 3 Step 3 이 spec 이 현행 유지로 정한 조항의 문구 수정을 허용한다 | adversarial |
| Step 2 뒤 검사 스크립트를 더 고칠 수 있어 계약이 약해질 수 있다 | adversarial |
| 고친 검사가 새 원칙에서 결함을 잡는지 확인하지 않는다 | adversarial |
| 묶음 검사 `^#{3,4}` 가 현행보다 느슨하다 | adversarial |
| 근거 절 이동의 손실·중복을 검사가 잡지 못한다 | adversarial |
| 작업 브랜치·push·병합 시점·되돌림이 없고, 원칙 사본이 autoUpdate 로 퍼진다 | adversarial |
| Task 1 Step 5 가 `test_docs_drift.sh` 하나만 실행한다 | adversarial |
| Review Focus 의 `doc_sec` 줄에 대응하는 단계가 없다 | fit |
| Task 1 Step 4 가 여러 변경을 한 단계로 묶었다 | fit |
| Task 3 Step 1 의 인라인 코드 백틱이 충돌한다 | fit |
| 할 일이 평서형이고 제약이 평서형 부정문이다(`INSTRUCTION-FORM`) | fit |
| '세 세션'을 이름 없이 개수로 가리키고, 절 이름·절 제목·층 이름을 섞어 쓴다 | fit |
| `git add skills/` 가 무관한 변경을 담을 수 있다 | grounding |

## 커버리지 공백

아무 렌즈도 보지 않은 관점은 없다.
