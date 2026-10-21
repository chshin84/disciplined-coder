# 조항 결정점 설계 spec 리뷰 기록(2026-10-20)

대상은 `docs/superpowers/specs/2026-10-20-clause-decision-point-design.md` 다. 파일이 `docs/superpowers/specs` 아래에 있으므로 spec 으로 판정했다. 렌즈 원본은 같은 이름의 폴더에 `lens-grounding-1.json`·`lens-consistency-1.json`·`lens-adversarial-1.json`·`lens-fit-1.json` 으로 있다.

렌즈를 한 번씩만 실행했다.

## 선행연구 에이전트

제안하지 않았다. 같은 날 사용자의 직접 요청으로 이 spec 의 핵심 메커니즘(생성 제약)에 대한 선행연구를 이미 실행했기 때문이다(`2026-10-20-generation-constraints-prior-art.md`).

## 리뷰 중 바뀐 대상

렌즈가 실행되는 동안 사용자가 대화 답 기계 검사를 빼고 파일만 검사하기로 정했다(2026-10-20). 렌즈는 그 전 문안(Stop 훅과 UserPromptSubmit 훅의 다음 턴 넛지)을 보았다. 아래 목록에서 그 문안에만 해당하는 지적은 「바뀐 문안 대상」으로 표시했다.

## 지적 목록

| 번호 | 렌즈 | 지적 | 함께 잡은 렌즈 |
|---|---|---|---|
| 1 | grounding | 1→6·0→3·0→2 는 해당 조항을 강화한 시험이 아니라 다른 15개 조항만 강화한 half 조건에서 나왔다. 단독 강화에서는 YAGNI 1→0, ANTI-LIMIT 0→0, VOCAB-PREF 0→4·0→1 이었다. 2026-10-12 강화 문구는 8b4a05a 문안과 다르다 | — |
| 2 | grounding | "악화되지 않은 네 건"은 측정되지 않은 문안이다 | — |
| 3 | grounding | 8b4a05a 의 SECRETS 문안은 가린 값을 허용하는데 T8 은 가린 값을 금지하는 문안을 시험한다 | — |
| 4 | grounding | 8b4a05a 의 BULLET-SCOPE 문안은 굵은 라벨을 금지하지 않고 항목마다 붙이라고 지시한다 | consistency(15번 관련) |
| 5 | grounding | 2026-10-18 spec 은 BULLET-SCOPE·SECTION-HEAD 를 쓰는 순간에 판단할 수 있다고 보고 고치지 않았는데, 이 spec 은 그 판단을 언급하지 않고 뒤집는다 | — |
| 6 | grounding | 자기 판정의 한계 행이 Opus 5 가이드와 Self-Correction Bench 의 반대 근거를 빼고 2023년 논문 하나로 단정한다 | — |
| 7 | grounding | "최근 모델은 지시를 문자 그대로 따른다"의 근거는 GPT-4.1 가이드 하나다 | — |
| 8 | grounding·adversarial | 기존 훅은 Write·Edit 에 Pre 거부 훅, Bash 에 Post 훅이 있고 Bash 편집 검사는 이미 있다. 「Write·Edit 뒤 훅」과 「연결 방법은 구현 단계에서」는 실제 구조와 다르다 | adversarial 11번 |
| 9 | grounding·consistency | `path_is_banned_target`(`hooks/_spec_marker.sh`)은 spec·plan·메모리·이 저장소 문서를 빼므로 작업 지시서 층 대부분이 검사에서 빠진다 | consistency 1번 |
| 10 | grounding | Bash 편집이 Write·Edit 훅에 걸리지 않는 현상은 auto mode 에 한정되지 않는다 | — |
| 11 | consistency | 저장소에 2026-10-18 BANNED-LIST 측정이 있다. 금지어를 이름으로 댄 목록이 지시형 트랙보다 위반이 적었다(11건 대 16건, 대화 답 금지어 2회 대 32회). spec 의 기본 습관 규칙과 금지어 priming 측정 과제는 이 측정과 반대 방향이다 | — |
| 12 | consistency | 주의의 한계 규칙은 희석 측정에 기대는데 희석 확인은 생략되고, 예시를 붙이는 형태는 분량을 늘린다 | adversarial 6번 |
| 13 | consistency·adversarial | 목표는 모든 조항 변경에 클린룸 시험을 요구하는데 T1 의 NAME-ITEMS 삭제는 시험을 거치지 않는다 | adversarial 8번 |
| 14 | consistency | NAME-ITEMS 근거 절과 「삭제한 조항」은 `docs/domain-korean.md` 에 있는데 T1 은 `docs/domain-discipline.md` 를 가리킨다 | — |
| 15 | consistency | NAME-ITEMS 를 지우면 `evals/principles/clauses/NAME-ITEMS` 단위가 `check_units` 오류를 낸다 | — |
| 16 | consistency | 금지어 목록 행의 측정과 처분이 어느 과제에도 배정되지 않았다 | — |
| 17 | consistency | 대조 표 행의 과제 배정이 이름으로 정해지지 않았고, SUBJECT-OBJECT·NO-MID-MOD 는 두 과제에 걸린다 | — |
| 18 | consistency | 의존 순서 문단이 T4→T5, T6→EDIT-PRIORITY 측정 등을 빠뜨린다 | — |
| 19 | consistency | 두 번째 판정 모델과 Concise 조건에 필요한 시험 도구 변경을 맡은 과제가 없다 | — |
| 20 | consistency | T6 확인 방법이 본문의 일을 다 덮지 못한다(바뀐 문안 대상 일부 포함) | — |
| 21 | consistency | 바뀌는 파일이 한곳에 정해지지 않았고 README 훅 목록 갱신이 빠졌다 | — |
| 22 | consistency | "읽기 위한 문서"와 REVIEW-DELIVERABLE·스킬의 "남에게 전달할"이 함께 남고, T10 의 "병합" 대상이 정해지지 않았다 | — |
| 23 | consistency | score.md 경로를 worktree 기준으로 적었으나 worktree 에는 없다 | — |
| 24 | consistency | 지목형이 T4 에서 이기면 기본 습관 규칙과 채택 문안이 어긋난다 | grounding 4번 관련 |
| 25 | consistency·adversarial | 판정 불일치율과 두 번째 판정 모델은 결정에 쓰이지 않는데 비용을 늘린다. 훅 작업과 조항 시험이 한 plan 범위다 | adversarial 7번 |
| 26 | adversarial | 다음 턴 넛지가 금지 형태를 priming 할 수 있다(바뀐 문안 대상) | — |
| 27 | adversarial | Stop 훅의 JSON 파싱 비용이 모든 답에 붙는다(바뀐 문안 대상) | — |
| 28 | adversarial | 정규식이 코드 블록·인용·표 안의 문자열을 제외하는 규칙이 없다 | — |
| 29 | adversarial | 세션별 상태 파일의 정리 시점이 없다(바뀐 문안 대상) | — |
| 30 | adversarial | T4 의 승자가 측정 흔들림 안의 1~2건 차이로 정해지고 T5 가 그 형태를 여러 조항에 퍼뜨린다 | — |
| 31 | adversarial | 단독 시험에서만 확인했다는 가정을 채택 기록에 남기라는 문장이 없다 | — |
| 32 | adversarial | 새 훅을 끄는 방법이 없다. 기존 스위치 `DISCIPLINED_CODER_REPLY_CHECK` 를 따르는지 적지 않았다 | — |
| 33 | adversarial | 경고만 내는 검사가 실제로 수정으로 이어지는지 확인하지 않는다 | — |
| 34 | fit | 구현자가 지킬 금지 사항과 할 일이 평서문으로 적혀 있다(INSTRUCTION-FORM) | — |
| 35 | fit | 「의도」 마지막 문장의 쉼표 반복과 문서 주어(COMMA-CUT·ONE-IDEA·SUBJECT-OBJECT) | — |
| 36 | fit | 긴 관형절과 겹친 수식어(NO-MID-MOD·NO-STACK-MOD) | — |
| 37 | fit | 한 문장·한 셀에 여러 개념(ONE-IDEA) | — |
| 38 | fit | 표 열의 말끝 불일치(ONE-ENDING) | — |
| 39 | fit | 새로 지은 이름 "결정점"·"지목형"을 밝히지 않았다(VOCAB-PREF·TERM-EXPLAIN) | — |
| 40 | fit | 저장소 이름과 원어 용어를 풀지 않았다(TERM-EXPLAIN) | — |
| 41 | fit | 같은 시험을 다섯 이름으로, T4 비교 대상을 네 이름으로, 8b4a05a 를 커밋과 브랜치로 부른다(TERM-ONE) | — |
| 42 | fit | 개수 예고와 개수로 가리키기(COUNT-EARNS), '것'으로 가리키기(SPECIFIC-NAME), 주체 누락(SUBJECT-OBJECT) | — |

## 커버리지 공백

어느 렌즈도 T7(Concise 출력 스타일과 원칙의 우선권)의 처방 방향 자체는 보지 않았다. adversarial 렌즈는 범위 밖이라고 적었다. 실사용 답 24% 수치와 KW-doc-formats 사례는 파일 출처가 없어 grounding 렌즈가 대조하지 못했다.
