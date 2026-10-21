# 선행연구 검증자 설정 선택 plan 리뷰 기록(2026-10-21)

대상은 `docs/superpowers/plans/2026-10-21-prior-art-verifier-tiering-selection.md` 다. 파일이 `docs/superpowers/plans` 아래에 있으므로 plan 으로 판정했다. 렌즈 원본은 같은 이름의 폴더에 있다.

렌즈를 한 번씩만 실행했다. plan 이므로 선행연구 에이전트는 제안하지 않았다.

## 지적 목록

| 번호 | 렌즈 | 지적 | 함께 잡은 렌즈 |
|---|---|---|---|
| 1 | consistency | `score` 는 반복 실행을 한 키로 합치는데 `noise` 는 Score 두 개를 받고, `select` 가 쓸 기준선 값이 정해지지 않았다 | — |
| 2 | consistency·grounding·adversarial | 지도 대조의 계수 규칙과 기준선 실행이 없다 | grounding 4번, adversarial 10번 |
| 3 | consistency | 지도 대조 자료의 참·오류 수를 검사하지 않는다 | — |
| 4 | consistency | Opus low 를 판정 카테고리로만 한정해 spec 과 다르다 | — |
| 5 | consistency | 추출 세 카테고리의 설정을 하나로 정하는 규칙이 없다 | — |
| 6 | consistency·grounding | arXiv 2605.10039 항목이 시험 자료에 든다는 보장이 없다 | — |
| 7 | consistency | spec 은 시험 스크립트를 `evals/prior-art-verifier/` 에 두라고 하는데 plan 은 `scripts/` 에 둔다 | adversarial 11번 |
| 8 | consistency | `--extract-from` 파일 형식이 하나로 정해지지 않았고 fixture·고정 파일이 Files 에 없다 | — |
| 9 | consistency | 영어 카테고리 코드와 spec 카테고리의 대응표가 없고 `numbers` 가 수치·조건보다 좁다 | — |
| 10 | consistency | 적용된 effort 를 기록·대조하지 않고 `CLAUDE_CODE_EFFORT_LEVEL` 을 비우는 조건이 없다 | — |
| 11 | grounding | `search-r1.json` 의 `passed` 에는 `row` 가 없어 map 입력을 재구성해야 한다 | — |
| 12 | grounding | spec 은 판정·지도 대조 에이전트에 Read 를 주는데 plan 은 `--tools ""` 다. 원칙 파일을 읽을 수 없다 | — |
| 13 | grounding | 기준선은 `unverifiable` 을 참 기각으로 안 세고 추출은 `access` 실패를 기각으로 세어 잣대가 다르다 | — |
| 14 | grounding | 재실행 판단의 선례로 든 `claude_json` 은 그 동작의 선례가 아니다 | — |
| 15 | adversarial | `--setting-sources ""` 에서 WebFetch 권한 허용이 없어 거부될 수 있고, 실제 CLI 확인이 웹을 열지 않는 단계뿐이다 | — |
| 16 | adversarial | Windows 에서 셸 스크립트 가짜 CLI 를 subprocess 로 직접 실행할 수 없다 | — |
| 17 | adversarial | 테스트가 커밋될 `runs.jsonl` 에 가짜 줄을 쓴다 | — |
| 18 | adversarial | 작업자 4개와 여러 셸이 같은 `runs.jsonl` 에 덧붙여 줄이 섞일 수 있다 | — |
| 19 | adversarial | 600초 시간 초과의 비용이 남지 않고 재실행 횟수 상한이 없다 | — |
| 20 | adversarial | 임시 폴더가 사용자 홈 아래면 전역 CLAUDE.md 가 실리며, 실리는지 확인하지 않는다. `scripts/_eval_env.sh` 의 `eval_tmpdir` 이 이미 있다 | — |
| 21 | adversarial | 실제 CLI 의 `modelUsage` 키 형식이 다르면 모든 실행이 모델 불일치가 되는데 멈춤 조건이 없다 | — |
| 22 | adversarial | key 의 프롬프트 sha 가 템플릿인지 채운 프롬프트인지 정해지지 않았다 | — |
| 23 | adversarial | 고정한 추출 출력에 quote 가 없는 항목이 판정 단계에서 failures 가 되어 모든 설정을 막는다 | — |
| 24 | adversarial | 일회성 하네스의 테스트가 `scripts/test_*.sh` 일괄 실행에 영구히 섞인다 | consistency 7번 |
| 25 | adversarial | 격자 총 호출 수(가정으로 약 275~350회)와 사용량을 실행 전에 보이고 확인받는 단계가 없다 | — |
| 26 | fit | Global Constraints 와 Task 4 Step 8 의 금지·정지 조건이 평서형 부정문이다 | — |
| 27 | fit | Expected 줄 안에 행동이 섞였고 `extract-frozen.jsonl` 생성이 Expected 에만 있다 | — |
| 28 | fit | 기록 타입의 요구를 적지 않고 절 이름만 가리킨다 | — |
| 29 | fit | 문서를 주어로 쓴 문장, 새 이름(오류 통과·참 기각·흔들림) 풀이 누락, 직역(코드 울타리), 개수 예고, 긴 관형절, 겹친 수식어 | — |

## 커버리지 공백

어느 렌즈도 `total_cost_usd` 와 `claude-haiku-5-5` 가 실제 CLI 에서 나오는지 확인하지 않았다. 비용이 드는 실행이라 렌즈는 확인하지 않았고, plan 의 첫 실제 실행 단계로 남겼다.
