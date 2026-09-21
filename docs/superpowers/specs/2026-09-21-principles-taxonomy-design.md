# 원칙 분류 재배치와 금지 표현 유예 해제 — 설계

작성일 2026-09-21. 대상은 `agent-principles.md` 와 이 저장소의 살아 있는 문서와 그 문서를 검사하는
훅과 스크립트다. 2026-09-21 렌즈 리뷰 뒤에 다시 썼다. 무엇이 왜 바뀌었는지는 「리뷰가 바꾼 것」에
적는다.

## 수정 대상

두 요구가 같은 파일을 수정하므로 한 설계로 묶는다. 첫째는 원칙 배치의 정렬이고 둘째는 금지 표현
유예의 해제다.

원칙 배치는 한 문서가 서로 다른 형식과 서로 다른 분류 축을 동시에 쓴다. 같은 구실을 하는 규칙이
어느 절에 놓였느냐에 따라 조항 ID를 받기도 하고 못 받기도 한다. ID가 없는 규칙은 다른 문서가
가리킬 수 없고 드리프트 검사도 붙들지 못한다.

금지 표현 유예는 2026-09-21에 사용자가 해제했다. 이 저장소의 문서는 그전까지 훅과 검사 양쪽에서
제외되어 있었다.

## 측정한 현재 상태

`agent-principles.md` 는 형식 다섯과 분류 축 둘을 동시에 쓰고, 살아 있는 문서에 금지 표현이 남아
있다.

### 원본의 형식

형식이 다섯이고 그중 둘만 조항 ID를 준다.

| 절 | 형식 | 조항 ID |
|---|---|---|
| 원칙 | 평평한 불릿 여덟 | 있다 |
| Karpathy guidelines | 영어 소제목 넷과 산문 불릿 | 없다 |
| 한국어로 쓸 때 | 묶음 ID 여섯 아래 조항 ID 스물넷의 2층 | 있다 |
| 문서를 쓰고 관리할 때 | 표 둘과 라벨 불릿 둘과 산문 | 없다 |
| 코딩할 때 | 평평한 불릿 셋 | 있다 |
| 검증 · 병렬 오케스트레이션 · 이 파일의 취급 | 산문 | 없다 |
| 미해결의 처분 | 라벨 불릿 셋 | 없다 |

### 원본의 분류 축

분류 축이 둘이다. 다른 절들은 언제 적용되는지로 나뉘는데 `## Karpathy guidelines` 만 어디서
왔는지로 나뉜다. 그 절은 스스로 산출물이면 코드든 문서든 답이든 모두 적용된다고 선언하므로 적용
범위가 `## 원칙` 과 같다.

### 중복 소유

중복 소유가 하나다. 리뷰 전에는 넷으로 적었으나 셋은 근거가 서지 않아 철회했다.

| 위치 | 상태 | 처분 |
|---|---|---|
| Karpathy `Simplicity First` 와 `FOCUSED` | 단순성 요구와 단위 책임이 다른 절에 나뉘어 ID가 한쪽에만 있다 | `YAGNI` 를 신설하고 `FOCUSED` 는 그대로 둔다 |

### 금지 표현 유예의 규모

유예 파일을 삭제한 직후 `scripts/test_docs_drift.sh` 가 PASS=430 FAIL=16 을 냈다. 실패 열여섯은
전부 유예 목록에 있던 낱말이고 그 밖의 실패는 없었다. `정본` 을 `에이전트원칙` 으로 바꾼 뒤 남은
것은 열다섯이다.

제외를 만드는 장치는 넷이다. `hooks/_spec_marker.sh` 의 `path_in_own_repo` 가 조상 폴더에
`agent-principles.md` 가 있으면 훅 셋을 건너뛰게 한다. `scripts/test_docs_drift.sh` 의 `BANLIST`
추출과 `banned_scan` 호출이 적용 대상 칸으로 행을 고른다. `BAN_LIVE` 가 경로로 세 파일을 뺀다.
`scripts/banned_words_waiver.txt` 가 낱말 열여섯을 뺐다.

훅은 적용 대상 칸을 읽지 않으므로 표의 모든 행을 적용한다. 이 저장소에서 `답변과 산출물` 행이
검출되지 않던 원인은 `path_in_own_repo` 하나다.

## 설계

분류 축과 형식을 통일하고 금지 표현 유예를 해제한다. 절 이름은 바꾸지 않는다.

### 분류 축의 통일

`## Karpathy guidelines` 절을 해체해 적용 범위가 같은 `## 원칙` 으로 흡수하고, 출처는 문서 머리에
한 줄로 남긴다. 나머지 절의 이름과 수는 그대로 둔다.

절 이름을 바꾸지 않는 근거가 둘이다. `scripts/test_scaffold.sh` 의 단언 열넷이 절 이름을 글자로
요구하고 awk 블록 추출 셋이 검증 절과 병렬 오케스트레이션 절의 제목을 앵커로 쓴다. 살아 있는 파일
열여섯이 절 이름을 인용하며 그중 `skills/lens-readability/SKILL.md` 는 서브에이전트 프롬프트
안에 절 이름을 넣어 두었다. 이름 변경의 연쇄가 재배치 자체보다 크다.

### 형식의 통일

ID가 없는 네 절에 조항 ID를 부여하고, 근거와 예시와 예외는 참고서로 내린다. 한국어 절이
`skills/lens-readability/domain-korean.md` 를 쓰는 방식을 그대로 확장한다.

참고서는 하나만 신설한다. 한국어 절은 조항 스물넷의 근거를 파일 하나에 두고 있으므로 같은 비율을
따른다. 위치도 그 관례를 따라 소비자 옆에 둔다.

| 참고서 | 소유하는 근거 |
|---|---|
| `skills/lens-fit/domain-discipline.md` | 원칙과 문서와 코딩과 작업 진행 조항의 근거와 문서 타입 표와 수정 규율 표 |

이 참고서가 다른 프로젝트에 도달하게 하려면 연결이 필요하다. 전역으로 복사되는 파일은
`scripts/_scaffold_common.sh` 의 `SCAFFOLD_FILES` 에 둘로 고정되어 있고, 경로를 프롬프트에 넣는
것은 `hooks/rules_nudge_pretooluse.sh` 가 `domain-korean.md` 하나만 이름으로 적는다. 그 훅에 새
참고서 경로를 추가한다.

### Karpathy 해체 매핑

Karpathy 절의 열네 줄을 새 조항 여덟에 대응시키고 둘은 기존 조항이 소유한다. 원문은 글자 그대로
옮긴다.

| 원문 | 새 조항 | 비고 |
|---|---|---|
| Don't assume the current state. Measure it in the actual code, data, and environment. | `NO-ASSUME` | 신설 |
| State your assumptions explicitly rather than hiding them. | `STATE-ASSUME` | 신설 |
| When measuring doesn't settle it, or several readings fit, stop and name what is unresolved. | `NAME-UNRESOLVED` | 신설 |
| Ask as a question with options; never pick silently. | `ASK-OPTIONS` | 신설 |
| Don't launch a fleet of subagents for what one call can do. | `NO-FLEET` | 신설 |
| Nothing beyond what was asked 외 네 줄 | `YAGNI` | 다섯 줄의 통합 |
| Every changed line must trace directly to the request. | `TRACE-REQUEST` | 신설 |
| Match the existing style, even if you would do it differently. | `KEEP-STYLE` | 신설 |
| Notice unrelated dead material? Say so — don't delete it. | `REPORT-DEAD` | 신설 |
| Remove what your own change made unused. Don't remove what was already unused. | `REPORT-DEAD` | 같은 조항의 둘째 문장 |
| Turn the task into something you can check. | `CHECKABLE` | 신설 |
| For multi-step work, state the plan as numbered steps, each with the check that verifies it. | `CHECKABLE` | 같은 조항의 둘째 문장 |
| Tradeoff 문단 | 없음 | 원칙 절 머리의 적용 범위 문장으로 옮긴다 |
| How to shape that question is UNPACK's to say. | 없음 | `ASK-CONTEXT` 가 이미 소유한다 |

`MEASURE-FIRST` 와 `SURGICAL` 은 쓰지 않는다. 2026-09-05에 이름까지 제거하기로 정했고
`scripts/test_scaffold.sh` 가 그 다섯 ID의 부재를 단언한다. 그 결정을 뒤집을 근거가 이번 지시에
없으므로 `NO-ASSUME` 과 `TRACE-REQUEST` 를 쓴다.

### ID가 없는 네 절의 분해

네 절을 조항 열넷으로 분해한다. 절 이름과 순서는 그대로 둔다.

| 새 조항 | 지시 | 출처 절 |
|---|---|---|
| `DOC-TYPE` | 문서를 수정하기 전에 타입과 수명과 수정 규율을 정한다 | 문서를 쓰고 관리할 때 |
| `NO-DOC-STATE` | 절차와 계약 문서에 진행 상태를 적지 않는다 | 문서를 쓰고 관리할 때 |
| `HANDOFF-CONSUME` | 핸드오프는 소비되면 곧바로 지운다 | 문서를 쓰고 관리할 때 |
| `MANAGED-BLOCK` | 자동 생성 구간을 마커로 감싸 멱등 재생성한다 | 문서를 쓰고 관리할 때 |
| `DOC-PLACE` | 항상 필요한 규칙은 `CLAUDE.md` 에 두고 필요할 때만 여는 규칙은 스킬로 만들며 경로 한정 규칙은 rules 에 둔다 | 문서를 쓰고 관리할 때 |
| `EDIT-DISCIPLINE` | 문서가 수정 규율을 선언하면 그 선언이 기계 강제의 계약이 된다 | 문서를 쓰고 관리할 때 |
| `NO-RAW-OUTPUT` | 한 번에 낸 출력을 검토 없이 결과로 삼지 않는다 | 검증 |
| `LENS-ALLOWED` | 렌즈 호출은 사용자가 상시 허용한 것으로 본다. 웹에 나가는 `lens-prior-art` 는 그때마다 승인을 받는다 | 검증 |
| `FACT-VS-JUDGE` | 훅은 계산으로 확인되는 사실만 기록한다. 완료는 판단이므로 근거와 함께 알린다 | 검증 |
| `NO-TODO-DOC` | 미해결을 할 일 목록 문서에 모으지 않는다 | 미해결의 처분 |
| `RESOLVE-NOW` | 지금 할 수 있으면 즉시 한다 | 미해결의 처분 |
| `MEMO-DEFER` | 미루지만 남겨야 하는 것은 메모리에 적고 알린다 | 미해결의 처분 |
| `TELL-NOW` | 사용자 결정이 필요한 것은 모아 두지 말고 즉시 알린다 | 미해결의 처분 |
| `SUB-ORCHESTRATE` | 독립된 큰 일이 둘 이상이면 일마다 서브오케스트레이터를 두어 동시에 진행한다 | 병렬 오케스트레이션 |

`DERIVE-FIRST` 는 신설하지 않는다. 도출과 참조는 `SSOT` 가 이미 소유한다.

조항 마크업은 한국어 절과 같은 형태를 쓴다. 묶음 ID는 두지 않는다. 절이 이미 묶음 구실을 하고
조항 수가 절마다 여섯 이하다.

### 금지 표현 유예 해제

기계 쪽 변경은 둘이다.

`hooks/_spec_marker.sh` 의 `path_in_own_repo` 호출을 훅 셋에서 제거한다. 목록 파일 자신
(`korean-banned-words.md`)은 생성물이므로 경로로 제외한다. `scripts/test_hooks.sh` 의 단언 셋과
픽스처가 이 제외의 존재를 요구하므로 함께 뒤집는다. 호출이 사라진 `path_in_own_repo` 는 다른
호출자가 없으므로 삭제한다.

`hooks/_banned_words.sh` 의 `banned_scan` 이 코드 블록과 백틱을 걷게 맞춘다. 이 변경은 이미
적용했다. 맞추지 않으면 검사 경로에서 인용을 백틱으로 살릴 수 없어, 제외를 해제한
`domain-korean.md` 의 사용자 인용문을 고치는 것 말고 방법이 없어진다.

적용 대상 칸의 필터는 그대로 둔다. `BANLIST` 추출과 `banned_scan` 호출의 인자를 유지한다. 목록은
`답변과 산출물` 을 저장소의 살아 있는 문서를 뺀 범위로 정의하므로, 필터를 없애는 것은 유예 해제가
아니라 외부가 정한 적용 범위를 이 저장소만 넓히는 변경에 해당한다.

`BAN_LIVE` 의 경로 제외는 `agent-principles.md` 와 `domain-korean.md` 에서 없앤다. 원칙을 정하는
문서가 스스로 그 원칙을 지키는지 보게 한다.

문서 쪽 변경은 남은 열다섯을 대체어로 바꾼다. 문맥마다 대체어가 갈리므로 기계 치환을 쓰지
않는다.

## 작업 순서

문서를 먼저 수정하고 훅과 검사의 제외를 마지막에 해제한다. 실패 목록이 이미 있으므로 검사를
실패시켜 목록을 얻을 필요가 없다.

| 단계 | 내용 | 확인 방법 |
|---|---|---|
| 1 | `banned_scan` 이 백틱을 걷게 맞춘다 | 검사 다섯 벌의 실패가 늘지 않는다 |
| 2 | 살아 있는 문서의 남은 열다섯을 대체어로 바꾼다 | `test_docs_drift.sh` 가 FAIL=0 을 낸다 |
| 3 | 참고서를 만들고 근거를 옮긴다 | 파일이 있고 지시 문장이 양쪽에 중복되지 않는다 |
| 4 | `agent-principles.md` 를 새 배치로 다시 쓴다 | 조항이 모두 ID를 보유한다 |
| 5 | Karpathy 절의 구조 단언과 대조 문자열을 고친다 | 검사 다섯 벌이 FAIL=0 을 낸다 |
| 6 | 훅과 검사의 제외를 해제하고 관련 단언을 뒤집는다 | 검사 다섯 벌이 FAIL=0 을 낸다 |
| 7 | 조항 ID마다 참고서에 근거가 있는지 보는 검사를 추가한다 | 그 검사가 통과한다 |

5단계가 고칠 단언은 금지 표현 문자열 밖에 있다. `scripts/test_scaffold.sh` 가 Karpathy 하위 소제목
넷의 존재와 층위와 45줄 상한과 영어 원문 아홉을 단언하므로, 절을 해체하면 그 단언들을 삭제하거나
새 조항에 맞춰 다시 써야 한다.

7단계의 검사는 한국어 조항의 ID 대조 블록과 같은 형태로 만든다. 앵커와 조항 마크업과 대조 상대를
못 박고, 근거 존재와 지시 중복 둘을 본다.

## 성공 기준

검사 다섯 벌이 FAIL=0 을 내고 `claude plugin validate ./` 가 `version` 경고 하나만 낸다.
`agent-principles.md` 의 모든 조항이 ID를 보유하고, 각 ID마다 참고서에 근거가 있으며, 지시 문장이
양쪽에 중복되지 않는다. 개수를 숫자로 박지 않는다.

## 되돌리기

단계마다 커밋을 나눈다. 2단계와 5단계는 문서와 단언을 함께 수정하므로 각각 한 커밋으로 묶는다.
6단계는 동작을 바꾸는 유일한 단계이므로 마지막에 둔다.

4단계는 되돌리기가 국소적이지 않다. `scripts/scaffold.sh` 가 세션 시작에 플러그인 캐시에서 전역
사본을 복사하므로, 커밋과 마켓플레이스 갱신이 끝나기 전까지 새 조항 ID를 가리키는 문서와 옛 ID를
적용하는 세션이 공존한다. 그 시차를 알리는 검사는 없다.

## 리뷰가 바꾼 것

2026-09-21 렌즈 리뷰의 발견을 반영했다. 기록은
`docs/superpowers/reviews/2026-09-21-principles-taxonomy-design-review.md` 에 있다.

수치 여섯을 정정했다. 검사 단언은 798개이고 대조 문자열은 33개이며 한국어 조항은 스물넷이다.

상충 넷 중 셋을 철회했다. `ASK-CONTEXT` 와 `ASYNC-FIRST` 와 `NAME-ITEMS` 는 조건절이 이미 서로
겹치지 않아 상충이 아니었다.

`MEASURE-FIRST` 와 `SURGICAL` 을 다른 이름으로 바꿨다. 절 이름 변경을 범위에서 뺐다. 참고서를
셋에서 하나로 줄였다. 적용 대상 필터 제거를 철회했다. `banned_scan` 의 백틱 처리를 추가했다.
Karpathy 원문 네 줄을 매핑 표에 추가했다.

<!-- spec-review: escalated -->
