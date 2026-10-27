# 조절 축 문체 규칙 — plan 리뷰 기록

## 대상과 실행

대상은 `docs/superpowers/plans/2026-10-27-tone-manner.md` 이다. 경로가 `docs/superpowers/plans` 아래이므로 plan 으로 구분했다. 렌즈는 `lens-grounding`(spec), `lens-consistency`(plan), `lens-adversarial`(design), `lens-fit`(auto)을 한 번씩만 실행했다. 원본은 같은 이름의 폴더에 있고, 오케스트레이터가 렌즈의 hand-back 메시지에서 옮기며 일부 칸을 요약했다.

선행연구 스킬은 plan 이므로 제안하지 않았다.

## 둘 이상의 렌즈가 함께 지적한 항목

- `scripts/test_eval_clause.sh` 는 없고 형식 검사는 `scripts/test_eval_cases.sh` 다(grounding, adversarial). 오케스트레이터도 파일 목록으로 확인했다.
- 새 단위에 `base` 파일이 없어 `current.md` 가 `7a2d26d` 와 대조된다(grounding, consistency, adversarial). 오케스트레이터가 `git diff --stat 7a2d26d HEAD -- agent-principles.md` 로 181줄 차이를 확인했다.
- 새 조항은 조항 없음 조건과 비교해 넣을지 정해야 하는데 plan 은 진단으로만 썼다(grounding, consistency).
- 진단이 현행 조건과 비교하지 않고 원인을 단정한다(grounding, adversarial).
- 동률 분기에 `followup: true` 와 추가 짝의 단계가 없다(grounding, consistency, adversarial).
- 산출물 질문 `q-tone-axis-1`·`2` 가 `type: chat` 이다(grounding, consistency, adversarial).
- spec 이 정한 묶음 시험·단발 시험의 한계 기록이 없다(consistency, adversarial).
- 시험 비용 제안과 진단 실행 확인 단계가 없다(grounding, consistency).

## 커버리지 공백

`VOCAB-PREF` 구조 예 추가, 기존 시험 단위의 처분, 렌즈의 `notes` 기록 지시가 plan 에 없다(consistency). `ASK-OPTIONS` 와 `KO-SYNTAX` 머리 문장 변경이 ids 에 없어 시험되지 않는다(adversarial).

## 걸러 낸 지적

시험 비용 제안과 진단 실행 확인 단계가 없다는 지적은 걸렀다. 사용자가 2026-10-27 에 "시험 + 원칙 없음 진단"을 선택 도구로 골랐으므로 plan 에는 승인 사실만 적는다.

## 처분

`🔴` 는 없다. 지적은 모두 고친다. 판정 기준 점검은 시험 전으로 옮기고, 겨눈 질문과 회귀 질문의 위반을 나눠 판정한다. `ASK-OPTIONS`·`VOCAB-PREF` 를 ids 에 넣어 시험 범위에 포함하며, 그래서 질문 수와 비용이 늘어난다. `docs/domain-discipline.md` 의 세 줄은 측정 기록이므로 고치지 않는다(grounding). 측정 문단은 `test_docs_drift.sh` 의 "근거가 있는 조항은 원칙에 있어야 한다" 검사 때문에 원칙 반영과 같은 커밋에 넣는다.

렌즈를 한 번씩만 실행했다.
