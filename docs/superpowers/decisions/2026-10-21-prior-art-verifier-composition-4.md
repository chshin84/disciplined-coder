# 선행연구 검증자 구성 결정 기록 4(2026-10-21)

이 파일은 기록 타입이다. 결정 기록 3 `docs/superpowers/decisions/2026-10-21-prior-art-verifier-composition-3.md` 를 고치지 않고, 그 기록의 사실 서술 세 곳을 여기서 정정한다. 정정 대상은 「새 구성이 틀린 항목」 절의 원인 분류 표, 첫 plan 과의 차이를 적은 문단, 지도 대조 칸 누락의 원인 가정이다. 병합 조건 판정(비용 충족, 항목 미충족)은 바뀌지 않는다. 이 기록은 결정을 적지 않으며, 다음 설계는 사용자가 정한다.

모든 사실은 `evals/prior-art-verifier/results-v2/` 의 `runs-def.jsonl`·`runs.jsonl`·`replay.json` 과 첫 plan 의 `evals/prior-art-verifier/results/runs.jsonl` 에서 다시 확인했다.

## 실패 원인 분류 정정

결정 기록 3 은 실패를 "의역을 불일치로 판정", "판정 불가가 상향 뒤에도 남음", "지도 대조 칸 누락" 으로 나눴다. 단계 출력을 다시 보면 실패한 실행은 아래 네 원인으로 나뉜다. 표의 단위는 항목과 실행의 짝이다.

| 원인 | 항목(실행) | 단계 출력에서 확인한 사실 |
|---|---|---|
| 추출 quote 불완전 | `quo-t1`(1), `num-t4`(2) | `quo-t1` 실행 1 은 추출 단계가 "Include 3–5 examples for best results." 를 `quote` 에 넣지 않고 `reason` 에만 적었다. 판정 에이전트는 "3~5개가 구절과 context 어디에도 없다" 며 수치·조건을 불일치로 냈다. 같은 실행에서 범위도 불일치였다. `num-t4` 실행 2 는 `quote` 가 "measuring compliance with a trivial target annotation" 에서 끝나 "across 1,650 Claude Code CLI sessions" 가 잘렸다. 판정은 판정 불가였고 상향 판정이 불일치로 냈다. 실행 1 은 `quote` 에 세션 수가 있어 통과했다 |
| 출처 정체 재판정(맥락 부족) | `acc-t1`(1), `acc-t2`(2), `num-t2`(2), `num-t5`(2), `sco-t3`(2) | 판정 에이전트와 상향 판정 에이전트가 모두 `맥락 부족` 판정 불가를 냈다. 두 에이전트는 출처를 가리키는 이름이 `quote`·`context` 에 없다는 사유를 적었다. `acc-t1` 은 "ICLR 2024"·"Huang 등", `acc-t2`·`num-t2`·`num-t5` 는 "IFScale", `sco-t3` 는 상시 지시 파일의 크기가 조작한 변수에 드는지였다. 이 다섯 건 모두 추출 단계가 같은 실행에서 `exists` 를 `일치` 로 냈다. 추출이 확인한 출처 정체를 판정 에이전트가 구절만으로 다시 판정하는 구조다 |
| 의역 엄격 판정 | `exi-t1`(1), `quo-t1`(2), `quo-t3`(1·2), `hard-f200-t1`(1·2) | `quote` 에 필요한 문장이 있었다. 판정 에이전트는 주장이 구절의 한정(`exi-t1` 의 "without external feedback", `quo-t1` 의 "one of the most reliable ways", `quo-t3` 의 "tend to", `hard-f200-t1` 의 "sometimes")을 뺐다며 범위나 수치·조건을 불일치로 냈다 |
| 기타 | `dir-t1`(2), `map-1` 의 `outcome` 칸 두 개(1·2) | `dir-t1` 실행 2 는 추출이 `context` 에 "position and architecture nulls are failures to reject without Bayes-factor support" 를 옮겼다. 판정 에이전트는 이 베이즈 근거 한정을 근거로, 크기와 위치 모두 차이가 없다는 주장의 범위를 불일치로 냈다. 지도 대조 칸은 아래 「지도 대조 칸 누락의 원인 가정 정정」에 있다 |

`acc-t1` 실행 1 은 범위 칸도 불일치였다. 구절의 "In the context of reasoning" 한정을 주장이 뺐다는 사유다. 그래도 수치·조건 칸에 판정 불가가 남아 최종 판정은 `verify_failed` 다.

## 첫 plan 과의 차이 정정

결정 기록 3 은 첫 plan 과의 차이로 "모든 주장이 판정 에이전트를 거친다" 만 적었다. 차이는 세 가지다.

- 첫 plan 은 접근·존재·구절 카테고리를 추출 단계 출력만으로 채점했다. 이번 재측정은 추출을 통과한 모든 주장이 판정 에이전트를 거친다.
- 첫 plan 의 판정 프롬프트(`prompts/judge-<카테고리>.md`)는 그 항목의 카테고리 칸 하나만 판정했다. 이번 판정 에이전트는 모든 주장에서 수치·조건·방향·범위 세 칸을 모두 판정한다. 그래서 방향·구절 카테고리 항목도 범위 칸에서 기각될 수 있다(`dir-t1` 실행 2, `quo-t3`).
- 첫 plan 의 `match` 값은 `일치`·`불일치` 둘이었다. 이번에는 `판정 불가` 가 추가되었고, 상향 뒤에도 남으면 검증 실패가 된다.

## 지도 대조 칸 누락의 원인 가정 정정

결정 기록 3 은 "`prompts/map.md` 는 판정할 칸을 적었고, 정의 `agents/prior-art-mapcheck.md` 는 '칸마다' 라고만 적는다" 고 썼다. 이 서술은 틀렸다. 두 파일 모두 "`evidence_map` 의 칸마다" 라고만 적고, 예시 칸도 `outcome`·`axes.mechanism.prior` 로 같다. 그래서 "정의에 칸 목록을 넣으면 해결된다" 는 가정은 근거가 없다.

결과 파일의 지도 대조 출력에서 `case`·`outcome` 칸 유무는 아래와 같다.

| 실행 | 설정 | `case` 칸 | `outcome` 칸 |
|---|---|---|---|
| 첫 plan `map` 실행 1 | Haiku 5.5 low | 없음 | 있음 |
| 첫 plan `map` 실행 1 | Haiku 5.5 medium | 없음 | 있음 |
| 첫 plan `map` 실행 1 | Haiku 5.5 high | 있음 | 있음 |
| 재측정 `baseline-map` 실행 1 | Opus 5.5 medium | 있음 | 있음 |
| 재측정 `baseline-map` 실행 2 | Opus 5.5 medium | 없음 | 있음 |
| 재측정 `map-def` 실행 1·2 | Haiku 5.5 high | 없음 | 없음 |

첫 plan 의 Haiku high 지도 대조는 한 번만 실행되었다. 같은 지시문으로도 기준선 실행 2 와 첫 plan 의 Haiku low·medium 이 `case` 칸을 빠뜨렸다. 그래서 `map-def` 의 칸 누락은 실행 간 변동일 수 있다. 지시문을 user 메시지로 넣었는지 system 프롬프트로 넣었는지의 차이일 수도 있다. 두 설명 모두 확인하지 않았다(가정). 같은 정의 본문을 user 메시지와 system 프롬프트로 각각 여러 번 실행해 칸 누락 빈도를 비교하면 확인할 수 있다.
