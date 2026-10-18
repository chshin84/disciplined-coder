# 에이전트원칙 행동·출력 재편 spec 리뷰 1차

대상은 `docs/superpowers/specs/2026-10-18-principles-action-output-split-design.md` 이다. 경로가 `specs` 아래라 spec 으로 판정했다. 렌즈를 한 번씩만 실행했다. 실행한 렌즈는 `lens-grounding`·`lens-consistency`·`lens-adversarial`·`lens-fit` 이고, 원본은 같은 이름의 폴더에 있다. brainstorming 의 빌더 확인도 같은 차수에 실행했다.

선행연구 에이전트는 제안하지 않았다. 이 spec 은 있는 원칙을 재편하는 작업이고, 될지 자체가 미지수인 일을 하지 않기 때문이다.

## 합친 지적

| 지적 | 잡은 렌즈 |
|---|---|
| 한국어 조항 ID 의 범위와 근거 참고서 위치가 정해지지 않아 `KO_IDS` 구간이 파일 끝까지 늘어난다 | grounding, consistency, adversarial, 빌더 확인 |
| 유지할 검사 계약에 `SUB-ORCHESTRATE`·nested-orchestration 검사가 빠졌다 | grounding, consistency |
| 「문서 타입과 수명」 제목의 존속과 단계가 정해지지 않았다 | grounding, consistency, fit |
| 옛 절 이름 검색의 예외(이력 문장, `evals/`, rewrite-map)가 정해지지 않았다 | grounding, consistency, 빌더 확인 |
| spec·plan 이 출력의 어느 하위 층에도 속하지 않고, 「출력」 머리 적용 조건이 하위 층보다 좁다 | consistency, adversarial, fit, 빌더 확인 |
| 사후 검사(`EDIT-PRIORITY`)가 spec·plan·CLAUDE.md·스킬에서 빠진다 | adversarial |
| `ASK-OPTIONS`·`DELEGATED-SCORE` 의 경계가 없다 | consistency, adversarial |
| `DELEGATED-SCORE` 가 하위 결정마다 점수표를 요구하고, 부재 판정을 에이전트가 한다 | consistency, adversarial, fit |
| `TOP-DOWN` 의 '알려라'와 `NO-RAW-OUTPUT` 의 '물어라'가 다르다. '층'·'층위'·'출처'가 정의되지 않았고 '흔들면'은 비유다 | consistency, adversarial, fit |
| `NO-RAW-OUTPUT` 의 차단 판정을 작성자가 하고, review-specs 의 '다시 리뷰는 매번 묻는다'와 상충하며, '바뀐 부분만'은 교차 모순을 놓친다 | adversarial, fit |
| `REPORT-WHEN` 이 완료 알림에서 자기 모순이고 `TELL-NOW`·`STATUS-FIRST` 와 겹친다 | consistency, adversarial, fit |
| `REPORT-SCOPE` 가 이 세션이 위임한 서브 세션의 일을 뺄 수 있다 | adversarial |
| `CONCRETE-FORM` 이 코드 변경에서 `EXPLAIN-STRUCTURE` 와 상충한다 | adversarial, fit |
| 파일로 쓴 작업 보고가 「읽기 위한 문서」와 「대화 답과 작업 보고」에 함께 들어간다 | consistency |
| 「행동」 머리에 출력 기준 문장이 있다 | consistency, fit |
| 언어 문단의 시점 문장이 spec 스스로 정한 기준(같은 지시가 실패했으면 더하지 않는다)과 상충한다 | adversarial |
| `VOCAB-PREF`·`EDIT-PRIORITY` 는 같은 날 시험 뒤 사용자가 현행 유지를 고른 조항이다 | fit |
| 판단 조항에 금지문을 쓰고, `KO-SYNTAX` 머리 문단이 평서형이다 | fit |
| `RUN-IT` 덧붙인 문장의 예외 표지, `REVERSIBLE` 이유의 범위, `COMMA-CUT`·`ANTI-LIMIT`·`NO-MID-MOD` 새 문안의 범위와 기준 | fit, adversarial |
| `TOP-DOWN` 이 superpowers 가 소유한 설계 절차와 겹친다 | adversarial |
| `SUB-ORCHESTRATE` 발동 조건에 크기 하한이 없다 | adversarial |
| `작은 변경` 의 '단계표'가 새 `CHECKABLE` 에 없다 | consistency |
| 근거 문단이 「조항 문구」에 있어 확인 방법대로 하면 원칙에 들어간다 | consistency |
| 확인 방법에 행동 효과 관찰과 되돌림 조건, 근거 기록과 메모리 질문의 확인이 없다 | consistency, adversarial |
| 「공통」의 일부 조항이 사후 확인형 문구로 남는다 | consistency |
| spec 본문: 개수 예고, 불릿 속 논증, 적용 조건의 주어 | fit |

## 커버리지 공백

`aggregating-lenses` 기준으로 아무 렌즈도 보지 않은 관점은 없다. 다만 커밋 메시지와 PR 본문이 출력의 어느 층에 속하는지는 어느 렌즈도 판정하지 않았다(consistency 가 확인 범위 밖으로 적었다).
