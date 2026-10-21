# 선행연구 검증자 구성 구현 plan 리뷰 기록(2026-10-21)

대상은 `docs/superpowers/plans/2026-10-21-prior-art-verifier-tiering-implement.md` 다. 파일이 `docs/superpowers/plans` 아래에 있으므로 plan 으로 판정했다. 렌즈 원본은 같은 이름의 폴더에 있다.

렌즈 lens-fit·lens-adversarial·lens-grounding·lens-consistency 를 한 번씩 실행했다. plan 이므로 선행연구 에이전트는 제안하지 않았다.

## 지적 목록

| 번호 | 렌즈 | 지적 | 함께 잡은 렌즈 |
|---|---|---|---|
| 1 | consistency·grounding | `mergeStages` 의 인자와 반환값이 Map 인데 `harn fn` 은 JSON 배열을 펼쳐 넘기고 결과를 JSON.stringify 로 쓴다. Map 을 주고받을 수 없다 | grounding 1번 |
| 2 | consistency·grounding·adversarial | replay.py 를 응답표 label 경로(`harn run`)와 `harn fn mergeStages` 경로로 함께 적는다. `harn fn` 은 응답표를 읽지 않는다 | grounding 2번, adversarial 7번 |
| 3 | adversarial | 재생은 합치기 코드만 운영과 같고, 단계 입력·프롬프트 조립·실행 방식(agentType 정의 대 `claude -p`)은 다르다 | consistency 2번 |
| 4 | consistency | spec 「최종 판정과 실패 처리」 1번(추출 출력 없음·판정 누락)과 3번의 `exists` 불일치를 고정하는 검사가 없다 | — |
| 5 | consistency | 판정 에이전트가 한 주장의 카테고리 칸 하나를 빠뜨린 상황의 검사가 없다 | — |
| 6 | consistency·adversarial | `outputs` 의 null 이 URL 단위라, 주장 하나의 판정 불가·상향 실패가 같은 URL 의 다른 판정까지 버린다. spec 은 "그 주장" 을 검증 실패로 센다 | adversarial 8번 |
| 7 | consistency | 상향 판정이 판정 불가였던 칸만 바꾸는지, 그 주장의 칸을 모두 덮는지 정하지 않았다 | — |
| 8 | consistency | spec 은 판정 불가 `match` 마다 이유 유형을 붙이는데 plan 은 주장마다 `unsure_reason` 하나를 둔다 | grounding notes |
| 9 | consistency | 판정·상향 프롬프트의 입력 형식이 Interfaces 에 없고, SKILL.md 「에이전트에게 보내는 프롬프트」 문단의 `cite`·`{ url, claims }` 를 고칠 단계가 없다 | — |
| 10 | consistency·grounding | 기존 `test_workflow.sh` 검사는 `verify:` label·`MODE: cite`·map-check 의 agentType 을 기대한다. plan 은 그 검사가 그대로 통과한다고 적고 고칠 단계를 두지 않는다 | grounding 3번 |
| 11 | consistency·grounding | `num-t3` 를 오류로 바꾸고 참 하나를 추가하면 수치·조건이 참 3건·오류 4건이 된다. `check_cases.py` 는 참·오류 수가 같아야 통과시킨다 | grounding 4번 |
| 12 | consistency·grounding | 어려운 항목의 `category` 값이 정해지지 않아 카테고리별 성적과 단계 배정이 구현자 선택에 달린다 | grounding 5번 |
| 13 | grounding | run.py 의 판정 단계는 구절이 없는 오류 항목에 짝 참 항목의 구절을 넣는데, `mergeStages` 는 quote 없는 주장을 판정 전에 `unsupported` 로 끝낸다. 재측정에서 이 규칙의 처리가 없다 | — |
| 14 | consistency·grounding·adversarial | 병합 조건 셋째(어려운 항목의 「틀리게 확신함」 ≤ 기준선의 틀린 판정 수)는 spec 「채택 규칙」 에 없다 | grounding 8번, adversarial 4번 |
| 15 | adversarial·fit | 셋째 조건의 두 값은 단위가 다르다. 「틀리게 확신함」 은 상향 전 Haiku 판정을, 기준선 값은 최종 verdict 를 센다. 「기준선의 틀린 판정 수」 의 정의도 없다 | fit 3번 |
| 16 | adversarial | 둘째 조건이 방향·범위만 봐서 가짜 성공 페이지·표·조건 얽힘 항목의 최종 verdict 를 보지 않는다 | — |
| 17 | adversarial | 병합 조건이 상향 비율의 과다·과소에 반응하지 않는다. 상향이 많아도 비용 조건은 기준선 대비라 쉽게 채워진다 | — |
| 18 | consistency·grounding·adversarial | 재측정은 run.py 가 `--model`·`--effort` 플래그로 정의 본문을 실행하므로 `models_used` 는 플래그 값이다. frontmatter 가 실제 워크플로 실행에 적용되는지는 시험되지 않고, effort 대조 방법도 없다 | grounding 7번, adversarial 1번 |
| 19 | adversarial | frontmatter 에 전체 모델 ID 를 고정하면 Bedrock·Vertex 처럼 ID 형식이 다른 환경에서 모든 단계가 실패할 수 있다 | — |
| 20 | adversarial | 어려운 항목이 종류마다 1건씩이고 새 구성은 반복 실행이 없어, 한 번의 흔들림이 결론을 바꾼다 | — |
| 21 | adversarial | 상향 판정 정의가 판정 정의와 본문이 같고 모델만 다르다. 두 파일의 드리프트 검사 짝이 늘어난다 | — |
| 22 | adversarial | `prior-art-verifier` 이름 유지의 근거가 확인되지 않았고, 옛 `MODE: cite`·`map` 입력이 들어올 때의 처리가 없다 | — |
| 23 | grounding·adversarial | Task 4 Step 4 가 인용한 spec 가정 "high 면 스스로 판단 가능 여부를 안다" 는 spec 에 없다. low·medium 비교는 결정을 바꾸지 않는다 | adversarial 11번 |
| 24 | adversarial | Step 7 의 "Sonnet 으로 올릴 카테고리를 묻는다" 경로는 판정 에이전트 하나의 구조와 맞지 않아, plan 밖에서 구조를 바꾸게 된다 | — |
| 25 | consistency | spec 안의 모순이다. 「에이전트와 단계」 표와 「바뀌는 파일」 은 상향 판정 에이전트와 판정 불가 값을 적지 않는다 | — |
| 26 | consistency | `evals/prior-art-verifier/README.md` 가 Files 에 없어 새 단계·replay.py·`report-v2` 와 이번 plan 을 가리키지 않게 된다 | — |
| 27 | consistency | 항목 종류(`hard_kind`)와 판정 불가 이유 유형이 비슷한 이름 두 묶음이고, `조건 얽힘` 만 이름이 같다 | — |
| 28 | fit | 앞 plan 과 결정 기록 2 를 경로 없이 이름으로만 가리킨다 | — |
| 29 | fit | 「Jev 문장」 의 범위가 모호하다 | — |
| 30 | fit | 대상을 개수로 가리킨다(두 정의 파일, 세 조건 등) | — |
| 31 | fit | Task 3 Step 1 의 Expected 칸에 행동이 섞였다 | — |
| 32 | fit | Review Focus 다섯째 항목의 주체가 plan 의 단계 이름이다 | — |
| 33 | fit | Task 3 Step 2 의 관형절이 길어 주어와 서술어가 멀다 | — |

## 커버리지 공백

어느 렌즈도 `agent()` opts 의 `model` 이 워크플로 런타임에서 서브에이전트 정의의 frontmatter 보다 앞서는지 실행으로 확인하지 않았다. adversarial 이 상향 정의 단순화의 전제로 든 이 동작은 가정으로 남았다. `scripts/test_prior_art_contract.sh` 와 `scripts/prior_art_contract.json` 의 기존 `cite` 짝이 Task 2 에서 함께 바뀌는지도 consistency 가 열어 보지 않았다.

<!-- spec-review: escalated -->
