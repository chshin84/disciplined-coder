# 선행연구 검증자 재측정 뒤 수정 plan 리뷰 기록(2026-10-21)

대상은 `docs/superpowers/plans/2026-10-21-prior-art-verifier-tiering-fix.md` 다. 파일이 `docs/superpowers/plans` 아래에 있으므로 plan 으로 판정했다. 함께 바뀐 spec `docs/superpowers/specs/2026-10-20-prior-art-verifier-tiering-design.md` 의 「재측정 뒤 수정」「충분성 판단과 두 갈래 상향」 두 절은 따로 실행하지 않았다. 렌즈마다 근거로 넘겼고, lens-fit 과 lens-consistency 는 두 절도 대상으로 보았다. 렌즈 원본은 같은 이름의 폴더에 있다.

렌즈 lens-fit·lens-adversarial·lens-grounding·lens-consistency 를 한 번씩만 실행했다. 선행연구 에이전트는 제안하지 않았다. 대상이 plan 이고, 함께 바뀐 spec 절은 기존 설계의 수정이며 그 효과를 plan 의 재측정이 확인하기 때문이다.

## 지적 목록

| 번호 | 렌즈 | 지적 | 함께 잡은 렌즈 |
|---|---|---|---|
| 1 | adversarial | 의역 엄격 판정으로 두 실행 모두 기각된 `quo-t1`·`quo-t3`·`hard-f200-t1` 은 이번 수정이 건드리지 않아, 재측정 전에 병합 실패가 거의 정해져 있다 | — |
| 2 | consistency·grounding·fit·adversarial | spec 은 충분성을 `충분`·`부족` 별도 값으로 두는데 plan 은 판정 칸의 넷째 값 `정보 부족` 으로 합쳤다 | grounding 2번, fit 4번 |
| 3 | consistency | 판정 불가 이유 유형에 `맥락 부족` 이 남아 `정보 부족` 과 겹친다. 정보가 모자란 칸이 보충이 아니라 Opus 로 갈 수 있다 | — |
| 4 | grounding | `source_note` 를 추출 출력의 `reason` 으로 정했는데, `reason` 에는 quote 밖의 원문 구절이 들어 있어 인용 판정 기준을 우회한다 | — |
| 5 | adversarial | 재판정이 처음 판정의 `불일치` 칸까지 대체해 오류 주장이 통과하는 길이 생긴다. 처음 판정에 불일치가 있으면 보충·상향이 필요 없다 | — |
| 6 | adversarial | `정보 부족` 과 `불일치` 의 경계가 없다. 수치를 바꾼 오류 주장이 정보 부족으로 보충에 가면 통과하거나 검증 실패가 된다 | — |
| 7 | adversarial·consistency | 보충 구절이 처음 구절을 대체하는지 합치는지 정하지 않았다. 합치면 구절 하나 기준이 느슨해지고 최종 `quote` 도 정해지지 않는다 | consistency 4번 |
| 8 | adversarial | 보충 실패를 URL 전체의 검증 실패로 정해 같은 URL 의 다른 주장 판정을 버린다 | — |
| 9 | consistency | 재판정 무응답·칸 누락과 보충 출력의 `access` 실패·`exists` 불일치의 처리 규칙과 검사가 없다 | — |
| 10 | consistency | 상향 판정 에이전트가 `정보 부족` 을 낼 때의 처리가 없다 | — |
| 11 | consistency·grounding | 추출 정의의 "첫 줄이 `MODE: extract` 가 아니면 빈 judgments" 문장과 입력 형식을 고치라는 지시가 없어 refetch 지시와 부딪친다 | grounding 3번 |
| 12 | consistency·grounding | `JUDGE_SCHEMA` 의 match enum·`missing` 속성과 `isMatch`·`unsureClaims` 를 고칠 대상에 넣지 않았다 | grounding 9번 |
| 13 | consistency·grounding | `effort: medium` 으로 바꾸면 네 정의의 `effort: high` 검사와 frontmatter 동일 검사가 실패하는데 plan 이 다루지 않는다 | grounding 8번 |
| 14 | consistency | 계약 json 과 `test_workflow.sh` 의 `stages` 키 목록(`extract`·`judge`·`escalation`) 갱신을 지목하지 않았다 | — |
| 15 | consistency | SKILL.md 「오케스트레이터 절차」 탐색 단계 서술과 「인용 확인」 을 고칠 절에 넣지 않았다 | — |
| 16 | consistency | spec 「에이전트와 단계」 표와 MODE 규약 문단이 보충·재판정·`source_note`·`refetch` 를 적지 않아 새 절과 맞지 않는다 | — |
| 17 | consistency·grounding | 하네스의 `escalate-def` 입력이 재판정 출력이 아닌 처음 판정 출력에서 골라진다. replay.py `ESCALATION`·score.py `SONNET_HIGH` 를 고칠 지시가 없고, run.py 에는 상향 모델 상수가 없다 | grounding 4번 |
| 18 | grounding | replay 명령에 필수 인자 `--cases` 가 없고, run.py 기본값은 `cases.json` 이다 | — |
| 19 | grounding | report-v3·replay 명령의 결과 경로가 저장소 루트 기준으로 틀렸다 | — |
| 20 | grounding | `--settings '{"disableAllHooks":true}'` 는 결정 기록 3 에서 frontmatter 확인 실행에만 붙였는데 plan 은 실행 조건 전체로 적었다 | — |
| 21 | adversarial | 시험 자료의 ref 이름(`acc-t1`, `num-f2`)이 정답과 카테고리를 드러내고 새 단계 프롬프트에도 들어간다 | — |
| 22 | adversarial | 승인 요청이 병합 조건만 근거로 삼아, 오류 통과가 앞 재측정(0건)보다 늘어도 드러나지 않는다 | — |
| 23 | adversarial | 지도 대조 대책이 근거 없다고 정정된 칸 목록 가정에만 기대고, 프롬프트 대조 검사에 map-check 가 없다 | — |
| 24 | adversarial | 두 실행만으로 수정 효과를 단정할 수 있다. 앞 재측정에서 실행마다 판정이 갈린 항목을 함께 적어야 한다 | — |
| 25 | consistency | "결정 기록 4 의 실패 13건" 의 13 은 결정 기록 3 의 항목·칸 단위다 | — |
| 26 | fit | 구현자가 할 일을 평서문으로 적은 문장이 섞였다 | — |
| 27 | fit | Task 2 Step 3 에 Run·Expected 칸과 명령 줄이 없다 | — |
| 28 | fit | Task 1 Step 5 의 Run 칸이 명령 대신 CLAUDE.md 절을 가리킨다 | — |
| 29 | fit | spec 에 금지어 `담`(91행)이 있다 | — |
| 30 | fit | spec 절 제목에 금지어 `갈래` 와 개수가 있다 | — |
| 31 | fit | 목록 앞에 개수를 예고했다 | — |
| 32 | fit | Task 1 Step 1 의 검사 이름 목록 끝에 작업 지시가 섞였다 | — |
| 33 | fit | spec 이 상향 대상을 "다른 곳" 으로 가리킨다 | — |

## 커버리지 공백

어느 렌즈도 Opus 5.5 medium 상향의 단가를 실측하지 않았다. plan 의 예상 비용 $1~2 는 계산 근거가 적혀 있지 않다. 운영 워크플로의 `agent()` 가 frontmatter `effort` 를 적용하는지는 결정 기록 3 이 가정으로 남겼고, 이번 재측정 방식(`--system-prompt`)으로도 확인되지 않는다.

<!-- spec-review: escalated -->
