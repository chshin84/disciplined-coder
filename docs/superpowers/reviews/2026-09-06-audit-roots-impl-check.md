# 2026-09-06 뿌리 구현 문서 검진

대상은 이번 회차에 고친 문서 열일곱이고 커밋 `88bb57d`부터 `0e96be5`까지의 상태를 봤다. 뿌리 다섯의 구현 여덟 걸음과 `python3` 가드가 그 범위다.

## 회차의 사실

렌즈를 한 번씩만 돌렸다. 호출은 일곱이고 병렬로 띄웠다. 쓰기 도구가 없는 에이전트 종류(`Explore`)로 띄워 읽기 전용을 지시가 아니라 구조로 막았다.

| 호출 | 대상 | 건 렌즈 |
|---|---|---|
| 1 | `agent-principles.md`·`CLAUDE.md` | grounding·fit |
| 2 | `README.md` | grounding·fit·readability |
| 3 | `aggregating-lenses`·`dispatching-lenses` | grounding·fit |
| 4 | `domain-korean`·`review-docs` | grounding·fit |
| 5 | 렌즈 파일 다섯 | grounding·fit |
| 6 | `audit-repo-docs`·`domain-plugin`·`nested-orchestration`·`review-specs` | grounding·fit |
| 7 | `HANDOFF-self-improvement-loop.md` | grounding·fit·readability |

처음에는 대상을 일곱으로 줄이고 열을 건너뛰려 했다. 사용자가 병렬이면 벽시계 값이 안 는다고 짚어 열일곱을 다 봤다. 건너뛰기의 근거였던 「표현 다듬기」 갈래도 잘못 적용한 것이었다 — 렌즈 파일의 스키마 변경은 계약을 고친 것이라 그 갈래가 아니다.

기계 검사를 먼저 돌렸다. 계약 테스트 다섯이 FAIL=0이고 금지 표현은 `domain-korean` 자신 말고 없다. 그 파일은 목록을 정의하는 곳이라 검사 대상에서 빠진다.

## 합친 목록

렌즈 일곱이 마흔여덟을 냈다. 렌즈별로 `lens-grounding` 스물여섯, `lens-fit` 스물여덟, `lens-readability` 열셋이다.

**렌즈 원본을 못 남겼다.** 규율은 받는 즉시 저장하라고 정하는데 이 회차는 합치기를 끝낸 뒤에 저장하려 했고, 그때는 서브에이전트 전사 파일 일곱이 모두 0바이트로 비어 있었다. 이 PC 에서 되풀이되는 함정이다. 아래 표가 살아남은 전부이고, 발견마다 짚은 곳과 무엇과 낸 렌즈는 남았으나 각 발견의 인용문(`evidence`·`counterpart`)은 사라졌다. 다음 회차는 렌즈가 돌아올 때마다 그 자리에서 파일로 적는다.

### 이번에 만든 것의 결함

| 짚은 곳 | 무엇 | 낸 렌즈 |
|---|---|---|
| `python3` 가드 | `DISCIPLINED_CODER_PYTHON3_STATE`로 판정이 통째로 우회되는데 README는 끄는 스위치가 없다고 적었다 | README grounding |
| `python3` 가드 | 판정이 경로의 `WindowsApps` 하나라 스토어로 깐 진짜 파이썬도 거부한다 | README grounding |
| 정본 표 | 붙인 경로 넷이 이 저장소의 것인데 정본은 모든 프로젝트에 실린다 | 정본 fit |
| 정본 표 | 기록 행이 「수정·삭제를 거부」라 적는데 그 훅은 Write와 Edit만 잡는다 | 정본 grounding |
| 정본 표 | 「강제하는 장치」 열의 말끝이 명사구 넷과 문장 셋으로 갈렸다 | 정본 fit |
| 정본 표 | roadmap 행의 사유가 규칙이 아니라 이 저장소의 현재 상태다 | 정본 fit |
| 「렌즈가 더하는 칸」 | `lens-fit`의 `doc_type`이 표에 없다 | 계약 grounding, 렌즈 grounding |
| 「렌즈가 더하는 칸」 | `narrowed`·`pairs`·`rewrite`의 뜻이 소유 렌즈와 어긋난다 | 계약 grounding |
| 「렌즈가 더하는 칸」 | `target`을 요구하는 곳이 저장소에 없다 | 계약 grounding |
| 렌즈 파일 넷 | 자리표시자로 바꾸면서 `claim`의 뜻이 파일에서 사라졌고 프롬프트가 그 몫을 안 한다 | 렌즈 grounding |
| 렌즈 파일 넷 | `where`와 `principles_applied`는 자리표시자 걸음이 건너뛰었다 | 렌즈 grounding, 렌즈 fit |
| `lens-prior-art` | 계약 예외라 검사가 건너뛰어 뜻풀이 복제가 그대로 남았다 | 렌즈 fit |
| 결론 문장 둘 | `nested-orchestration`과 `domain-plugin`의 새 문장이 절의 항목을 다 안 덮는다 | 한 줄 grounding |
| 핸드오프 유예 | 린트는 유예 당일에 이미 알리는데 문서는 그다음 날로 적었다 | 핸드오프 grounding |

### 소유 선언 정규화가 남긴 것

| 짚은 곳 | 무엇 | 낸 렌즈 |
|---|---|---|
| `dispatching-lenses` 첫 문단 | 문서 전체의 소유 선언만 옛 꼴로 남았다 | 계약 fit |
| `review-specs` PREP | 「여기가 소유하고」라 소유 표에 안 오른다 | 한 줄 fit |
| `audit-repo-docs` | 「정본」의 상대적 쓰임이 둘 남았다 | 한 줄 grounding |
| `dispatching-lenses` 예외 목록 | 감사 쪽만 「소유자」로 바꾸고 소유자 쪽은 「정본 표시」 그대로다 | 한 줄 grounding |
| 소유 선언의 자리 | 절 첫 문장을 차지해 `READ-FLOW`의 결론 자리와 부딪힌다 | README fit, 한국어 fit, README readability |
| 「SSOT다」와 「소유한다」 | 렌즈 여섯이 계약을 「SSOT다」로 부르는데 소유자 절에 그 말이 없다 | 계약 fit |

### 문서 규율에 걸린 것

| 짚은 곳 | 무엇 | 낸 렌즈 |
|---|---|---|
| `README.md` | `A가 아니라 B` 대구가 넷이고 한도는 하나다 | README fit |
| `README.md` | 「주의」 절 첫 문장이 대상을 '것들'로 부른다 | README fit |
| `README.md` | 「겹치던 옛 조항 다섯은 정본에서 뺐다」가 절차·계약에 담은 과거 상태다 | README fit |
| `README.md` | `-ef` 문단이 사용자 문서에 든 개발자 근거다 | README fit |
| `README.md` | 확인 방법이 `WARNING` 줄인데 셋업 경고 둘은 stderr로만 나간다 | README grounding |
| `README.md` | 홈 해석 스니펫이 `scripts/_resolve_home.sh`와 갈린다 | README grounding |
| `CLAUDE.md` | 규칙 넛지 계기를 「첫 파일 접촉」으로 적는데 `Bash`도 잡는다 | 정본 grounding |
| `domain-korean` | 「구조 먼저」가 가리키는 「고칠 순서」에 '구조'가 없다 | 한국어 grounding |
| `domain-korean` | 예외 기준이 첫 문단은 실어 보내는가, 표는 첫 줄의 모양으로 갈린다 | 한국어 grounding |
| `domain-korean` | 인용한 제목 「출력 스키마 (이 렌즈 전용)」이 실제와 다르다 | 한국어 grounding |
| `domain-korean` | 새 문장이 금지 표현 `부분`을 쓰고, 그 파일은 검사 대상에서 빠진다 | 한국어 fit |
| `domain-korean` | 대구가 넷이고 그 한도를 소유한 문서다 | 한국어 fit |
| `domain-korean` | 새 표 머리 「왜 예외인가」가 의문형이다 | 한국어 fit |
| `review-docs` | 규칙을 따르는 쪽을 셋으로 세는데 워크플로 검증까지 넷이다 | 한국어 grounding |
| `lens-readability` | 제목이 명사구가 아니라 완결 문장이다 | 렌즈 fit |
| `lens-readability` | 프롬프트가 이 파일에 없는 「체크리스트」 절을 가리킨다 | 렌즈 fit |
| `lens-fit` | 대구가 셋이다 | 렌즈 fit |
| 「출력 스키마」 제목 | 세 갈래가 더하는 칸의 유무를 못 가른다 | 렌즈 fit |
| `HANDOFF` | git 추적에서 뺐다고 적는데 추적 중이고 워크트리에도 있다 | 핸드오프 grounding |
| `HANDOFF` | 없는 `skills/domain-docs/SKILL.md`를 두 번 가리킨다 | 핸드오프 grounding |
| `HANDOFF` | 끝난 결정(렌즈 이름 접두사)을 미결로 적는다 | 핸드오프 grounding |
| `HANDOFF` | `lens-prior-art` 상한을 둘로 적는데 둘은 통상값이고 상한은 여섯이다 | 핸드오프 grounding |
| `HANDOFF` | 머리가 지금 지우라는 선언과 2주 두라는 선언을 함께 담는다 | 핸드오프 fit |
| `HANDOFF` | 미해결 다섯이 한 문서에 모여 있고 유예로 수명이 늘었다 | 핸드오프 fit |

## 둘 이상이 함께 잡은 것

넷이다. 「렌즈가 더하는 칸」의 `doc_type` 누락을 계약 호출과 렌즈 호출이 함께 잡았고, 소유 선언이 절 첫 문장을 차지하는 것을 세 호출이 잡았으며, 렌즈 파일의 `where`·`principles_applied` 건너뜀을 같은 호출의 두 렌즈가 각각 잡았고, `HANDOFF` 제목이 명사구가 아닌 것을 `lens-fit`과 `lens-readability`가 함께 잡았다.

## 상충과 커버리지 공백

상충이 하나 있다. 소유 선언을 절 첫 문장에 두는 이번 회차의 관례와 `READ-FLOW`의 「소제목 바로 아래 첫 문장에 그 절의 결론을 적는다」가 서로 반대를 요구한다. `lens-fit`은 선언을 뒤로 보내라 하고, 소유 표 도출은 선언이 그 절 안에 있기만 하면 되므로 자리를 안 가린다. 이 짝을 escalate 후보로 표시한다.

커버리지 공백이 하나다. `lens-consistency`와 `lens-adversarial`을 안 걸었다. `review-docs`의 기본 묶음이 `lens-grounding`과 `lens-fit` 둘이고 사람이 처음부터 끝까지 읽는 문서에만 `lens-readability`를 더하기 때문이다. 문서 사이의 진술이 갈리는지와 이번 설계의 실패 모드는 이 회차에서 아무도 안 봤다.

## 렌즈가 남긴 미확인

`scripts/test_docs_drift.sh`의 `EXTRA_LISTED`가 계산만 되고 렌즈 파일과 대조되지 않아 `doc_type` 누락이 기계에 안 걸린 것을 렌즈 둘이 각각 적었다. 소유 표의 키가 절 제목 전체라 괄호가 붙은 제목(「리뷰 산출물 계약 (렌즈 공통)」·「웹에 나가는 렌즈의 인용 검증 (`lens-prior-art` 전용)」)을 가리키는 줄을 가리키기 의무 검사가 하나도 안 본다는 것도 함께 적혔다. 둘 다 검사 쪽 문제라 이번 대상 밖이다.

`domain-korean` 검토자가 「쉼표 절제」의 4.1퍼센트가 무엇을 분모로 하는지 정해져 있지 않아 판정을 보류했다.
