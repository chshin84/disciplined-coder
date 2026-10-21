# 기준선 정리·문서 형식 검사 plan 리뷰 기록(2026-10-20)

대상은 `docs/superpowers/plans/2026-10-20-clause-baseline-and-doc-form-check.md` 다. 파일이 `docs/superpowers/plans` 아래에 있으므로 plan 으로 판정했다. 렌즈 원본은 같은 이름의 폴더에 있다.

렌즈를 한 번씩만 실행했다. plan 이므로 선행연구 에이전트는 제안하지 않았다.

## 지적 목록

| 번호 | 렌즈 | 지적 | 함께 잡은 렌즈 |
|---|---|---|---|
| 1 | grounding·consistency·adversarial | `doc_word_posttooluse.sh` 의 matcher 를 넓히면 Write·Edit 마다 프로세스가 늘어 spec 의 "프로세스 수를 늘리지 않는다"와 어긋난다. `doc_review_posttooluse.sh` 가 이미 Write·Edit·Bash 에 실행된다 | 셋 |
| 2 | grounding·adversarial | Bash 경로의 금지어용 조기 종료(목록 없음, `path_is_banned_target`, 토큰 없음)가 형식 검사까지 막는다 | 둘 |
| 3 | grounding·consistency | 기존 검사 "이 저장소 문서는 대상 아님"이 새 대상 범위와 충돌한다 | 둘 |
| 4 | grounding·adversarial | Write·Edit 를 받는 훅은 stdin 을 `$(cat)` 으로 읽어야 한다(`hooks/_hook_input.sh`) | 둘 |
| 5 | grounding·consistency | `REVIVED_IDS` 는 결과 변수이고 지운 ID 목록은 그 아래 `for` 목록이다 | 둘 |
| 6 | grounding·consistency | spec 은 `NAME-ITEMS` 절을 「삭제한 조항」으로 옮기라는데 plan 은 요약만 남기고 지운다 | 둘 |
| 7 | grounding | 삭제 이유("번호로 가리키는 편이 편하다")의 출처가 저장소에 없다 | — |
| 8 | grounding·adversarial | 멈춤 기준(186ms 의 두 배)의 근거가 없고 비교 대상이 맞지 않는다 | 둘 |
| 9 | grounding | 계수식 정규식과 445 라는 수는 spec 에도 저장소에도 출처가 없다 | — |
| 10 | grounding·consistency·adversarial·fit | Task 4 가 CLAUDE.md 에 넣을 항목이 plan 이 경고하게 만든 라벨 불릿 형태다 | 넷 |
| 11 | consistency | Task 2 에 전체 테스트 단계가 없다 | — |
| 12 | consistency | README 수정이 spec 의 T10 배정과 다르고, README 의 스위치 설명 갱신이 빠졌다 | — |
| 13 | consistency | 훅 단위에서 코드 블록 무시를 검사하지 않는다 | — |
| 14 | adversarial | 사전 거르기 grep 이 흔한 글자를 포함해 거르지 못한다 | — |
| 15 | adversarial | 문장 끝을 `[.!?]` 로 일반화해 영어 약어를 문장 끝으로 센다 | — |
| 16 | adversarial | 개수 예고 정규식이 낱말 경계 없이 '인터넷이'·'2026-10-20 개정'에 맞는다 | — |
| 17 | adversarial | 제목 개수 규칙이 '## 1단계' 같은 순서 제목에 걸린다 | — |
| 18 | adversarial | 파일 전체를 검사하고 상한 없이 보고해, 위반이 많은 기존 문서를 Edit 할 때마다 같은 경고가 반복된다 | — |
| 19 | adversarial | 파이썬이 없으면 `set -e` 로 훅이 오류 종료한다(2026-09-30 사용자 결정은 알림 없이 통과) | — |
| 20 | adversarial | BOM 과 cp949 파일을 조용히 놓친다 | — |
| 21 | adversarial | spec 이 지정하지 않은 과제 폴더 다섯 개를 지우고, 되돌릴 커밋을 적지 않는다 | — |
| 22 | adversarial·consistency·grounding | `evals/principles/results/clauses/*.jsonl` 의 `NAME-ITEMS` 줄과 `docs/domain-korean.md` 332행을 다루지 않는다 | 셋 |
| 23 | fit | Global Constraints 의 할 일이 평서형이고 말끝이 섞였다 | — |
| 24 | fit | Review Focus 와 Global Constraints 의 불릿이 여러 문장이다 | — |
| 25 | fit | 개수 예고(두 항목, 질문 둘, 셋이다) | — |
| 26 | fit | '과제'가 plan 과제와 평가 과제를 함께 가리킨다 | — |
| 27 | fit | "지금 경로"가 무엇인지 이름이 없고, Task 3 Step 3 단락이 길다 | — |
| 28 | fit | 경고 문구가 조각 문장이고 판정 기준을 담지 않는다 | — |
| 29 | fit | 옮겨 넣을 문단의 '이 절', 대구 반복, 긴 관형절, 주체 누락 | — |

## 커버리지 공백

어느 렌즈도 Edit 입력의 `new_string` 만 검사하는 방식과 파일 전체를 검사하는 방식의 차이를 실행해 보지 않았다.
