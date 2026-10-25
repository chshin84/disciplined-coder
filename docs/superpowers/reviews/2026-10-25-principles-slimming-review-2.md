# 에이전트원칙 경량화 spec 리뷰 기록(2차)

대상은 `docs/superpowers/specs/2026-10-25-principles-slimming-design.md` 를 고쳐 쓴 판이다. 경로가 `docs/superpowers/specs` 아래이므로 spec 으로 구분했다. 렌즈 원본은 같은 이름의 폴더에 있다(`lens-grounding-1.json`, `lens-consistency-1.json`, `lens-adversarial-1.json`, `lens-fit-1.json`). 원본은 hand-back 에서 옮기면서 근거 칸을 줄였다.

렌즈를 한 번씩만 실행했다.

선행연구 에이전트는 제안하지 않았다. 이 spec 은 이미 있는 조항과 스킬을 다시 배치하는 일이고, 되는지 자체가 미지수인 새 시도가 아니기 때문이다.

## 합친 지적

| 번호 | 지적 | 잡은 렌즈 |
|---|---|---|
| 1 | 같은 규칙을 2026-09-21 커밋 54ee432 가 `domain-docs` 스킬에서 원칙으로 옮겼다. 스킬로 두면 여는 판단을 매번 해야 했고 열지 않았을 때 누락이 조용했다는 이유였다(`scripts/test_docs_drift.sh` 103~105행). spec 은 이 선행 결정을 뒤집으면서 언급하지 않는다 | grounding |
| 2 | 대상 사용자는 대부분 문서 작업을 하므로, 문서 작업마다 스킬 호출과 파일 두 개 읽기가 생기면 작업당 비용이 오히려 늘 수 있다(가정). spec 은 원칙 글자 수만 측정한다 | adversarial |
| 3 | 비목표는 `lens-*` 를 고치지 말라고 하나 의존 목록은 `lens-readability` 17행을 고치라고 한다. 같은 파일 107·110행도 원칙의 TITLES 를 기준으로 가리킨다 | grounding, consistency, adversarial, fit |
| 4 | 2단계 diff 확인이 같은 spec 이 요구한 문구 수정(`REVIEW-DELIVERABLE` 면제, 자기 지칭)과 상충하고 허용 차이가 없다 | consistency, fit |
| 5 | 옮길 본문 143·145·149행이 자기 위치나 원칙에 남는 「작업 지시서」를 가리키는데 처리 규칙이 `MD-FIRST` 하나뿐이다 | consistency, fit |
| 6 | '절 도입 문장'의 범위가 없다. 「출력」 아래 도입문은 적용 범위를 정하는 지시를 포함한다 | consistency, fit |
| 7 | 층 규칙 문단의 "원칙에는 모든 답과 작업에 적용되는 행동만 둔다"가 원칙에 남기는 조건부 조항과 상충한다 | consistency, adversarial |
| 8 | "설명이 유일한 신호"라는 문장이 같은 spec 의 원칙 포인터·훅 안내와 상충하고, 5단계가 설명의 효과를 따로 판정하지 못한다 | consistency, adversarial |
| 9 | 5단계는 스킬을 열었는지만 보고 `reading-docs.md` 를 읽었는지 보지 않는다. should-not 과제, 서브에이전트 과제, 시험 장소, 플러그인 버전이 없다. 실패하면 1~4단계를 되돌려야 하는 순서다 | adversarial, fit |
| 10 | 서브에이전트와 Skill 도구 없는 에이전트는 스킬 이름 포인터를 따를 수 없고 포인터에 경로가 없다 | adversarial |
| 11 | writing-html-reports 는 49행 외에 53·56·119행과 64~67·87·140행이 원칙의 TITLES 를 전제한다. 사용자가 다른 저장소 수정을 거절하거나 배포가 늦을 때의 처리가 없다 | grounding, adversarial |
| 12 | 의존 누락: `nested-orchestration` SKILL.md 162행, `doc_format_pretooluse.sh` 2·17행 주석, `rules_nudge_pretooluse.sh` 8행, `test_docs_drift.sh` 793~795·812·813행과 DC_IDS(133~151행), `audit_topics.sh`, `review-docs` 11행 '둘의 경로' | grounding, consistency |
| 13 | 3단계 확인이 훅 문구 변경을 판정하지 않고, 4단계 확인이 새 위치를 추가하는 변경(계약 추가, 근거 문서 줄, 되살림 검사, 저장소 밖 수정)을 판정하지 않는다 | consistency |
| 14 | 4단계 grep 허용 목록에 시험 조건 사본(`evals/principles/clauses/DELEGATED-SCORE/`, `c20-edit-priority/`)과 `rewrite-map/domain-docs.md` 가 없다 | fit |
| 15 | 병합 직후 열린 세션은 옛 스킬 목록으로 실행되는데 원칙 사본은 새 포인터로 덮어써질 수 있다(가정) | adversarial |
| 16 | 「1차 리뷰 뒤 바뀐 곳」이 지적 24(토큰 수 출처)와 지적 21·22 의 처분을 사실과 다르게 적었다 | grounding |
| 17 | 5단계와 「시험으로 정한 값」의 할 일을 평서문으로 적었다(`INSTRUCTION-FORM`). 「문서 관리」 줄 범위의 끝 행이 빈 줄이다 | fit, consistency |

## 걸러 낸 지적과 확인

지적 1 은 `git show 54ee432` 로 커밋 본문을 열어 확인했다. 지적 16 중 '27,837자는 바이트 수였다'는 `wc -c` 로 원본(HEAD)을 세어 27837 이 나와 사실로 확인했다. 그러나 그 정정을 지적 24 의 처분으로 적은 것은 기록과 다르다. 지적 2 와 15 는 렌즈가 가정이라고 밝힌 지적이다.

## 커버리지

네 렌즈 모두 지적을 냈다. 둘 이상의 렌즈가 함께 잡은 항목은 3, 4, 5, 6, 7, 8, 9, 11, 12 다. 선행 결정(지적 1)은 `lens-grounding` 하나만 잡았다.
