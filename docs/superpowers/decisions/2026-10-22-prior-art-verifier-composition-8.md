# 선행연구 검증자 구성 결정 기록 8(2026-10-22)

이 파일은 기록 타입이다. 결정 기록 7 `docs/superpowers/decisions/2026-10-22-prior-art-verifier-composition-7.md` 를 고치지 않고, 그 기록의 서술 두 곳을 여기서 정정한다. 정정 대상은 아래와 같다.

- 「새로 틀린 항목과 원인」 절 47행의 인과 서술이다. 그 행은 병합 조건 비교 대상 네 항목이 모두 "한정이나 조건이 더 많은 구절을 받은 실행에서 틀렸다" 고 적었다.
- 「URL 사이의 구절 섞임」 절 53행의 `num-t3`(실행 1) 서술과, 「카테고리별 오류 통과」 절의 `num-t3` 통과 원인 서술이다.
- Task 2 보고(`.superpowers/sdd/2026-10-22-prior-art-verifier-batch-judge/task-2-report.md`)의 「병합 조건과 틀린 항목」 절에도 47행과 같은 서술이 있었다. `results-v4/report.md` 에는 이 인과 서술이 없었다. 그 대신 생성기 `score.py report-v4` 가 틀린 항목 표에 「판정 입력 구절」 칸(처음 판정 입력의 quote 가 실행마다 같은지)을 내도록 고쳐 보고를 다시 만들었다.

모든 사실은 `evals/prior-art-verifier/results-v4/runs-def.jsonl`·`replay.json` 을 `run.pipeline` 으로 다시 읽어 확인했다. 이 기록은 결정을 적지 않는다.

## 틀린 항목마다의 원인

병합 조건 비교 대상 네 항목에 공통인 사실은 하나다. 네 항목 모두 실행 1 과 실행 2 의 처음 판정 입력 구절(추출 출력의 quote)이 달랐다. 틀린 실행에서 무엇이 달랐는지는 항목마다 다르다.

| 항목(틀린 실행) | 틀린 실행의 구절 | 맞힌 실행의 구절 | 단계 출력에서 확인한 사실 |
|---|---|---|---|
| `acc-t1`(2) | "In the context of reasoning, our research indicates that LLMs struggle to self-correct their responses without external feedback, ..." | "LLMs struggle to self-correct their responses without external feedback" | 틀린 실행의 구절에 "In the context of reasoning" 한정이 더 있었다. 처음 판정은 주장이 이 한정을 뺐다며 범위를 불일치로 냈다 |
| `exi-t1`(2) | `acc-t1`(2) 와 같은 초록 문장 | 논문 제목 "Large Language Models Cannot Self-Correct Reasoning Yet" | 틀린 실행의 구절에 "struggle to" 와 "without external feedback" 같은 한정이 더 있었다. 처음 판정은 주장이 이 조건을 빼고 '교정하지 못한다' 로 넓혔다며 범위를 불일치로 냈다 |
| `dir-t1`(1) | "None of the four structural variables or three two-way interactions produces a detectable contrast" | "... produces a detectable contrast after multiple-testing correction." | 틀린 실행의 구절에는 "after multiple-testing correction" 조건이 빠져 있었다. 처음 판정은 수치·조건을 정보 부족으로 냈다. 보충 구절에는 그 조건이 있었으나, 재판정은 "Claude Code 세션이라는 적용 조건이 구절과 맥락에 없다" 며 다시 정보 부족을 내 검증 실패가 되었다 |
| `sco-t1`(1) | "Closer and more literal instruction following than previous GPT models" | "GPT-4.1 is trained to follow instructions more closely and more literally than its predecessors" | 틀린 실행의 구절은 비교 대상이 "previous GPT models" 였다. 처음 판정은 주장의 '이전 OpenAI 모델' 이 GPT 계열 밖까지 넓혔다며 수치·조건과 범위를 불일치로 냈다 |

`dir-t1`(1)은 한정이 더 많은 구절이 아니라 조건이 빠진 구절을 받은 실행에서 틀렸다. `sco-t1`(1)은 비교 대상이 다른 구절을 받은 실행에서 틀렸다. 그래서 결정 기록 7 의 47행처럼 네 항목을 하나의 원인으로 묶을 수 없다.

`sco-t1`(1)의 범위 불일치에는 구절상 근거가 있다. 구절의 비교 대상은 GPT 모델이고, 주장의 비교 대상은 OpenAI 모델이다. 그래서 정답 라벨(참)이 느슨한지도 검토 대상이다(가정). 이 가정은 `check_note` 의 확인 근거와 원문의 비교 대상 서술을 대조하면 확인할 수 있다.

## 같은 URL 안의 맥락 사용

`num-t3`(실행 1)의 판정 사유는 "같은 URL 의 다른 context 에 'Size ... nulls' 가 있으므로 크기가 그 변수에 든다" 고 적었다. 이 구절은 같은 묶음의 같은 URL 원소에 든 `dir-t1` 의 `context` 에 있다. 판정 정의 `agents/prior-art-judge.md` 는 "주장마다 그 주장과 같은 `items` 원소의 구절·맥락만 보고 판정하라" 고 적는다. 같은 `items` 원소에는 같은 URL 의 다른 주장도 들어 있으므로, 이 판정은 정의를 위반하지 않았다. 정의에는 같은 URL 의 다른 주장의 구절·맥락을 쓸 수 있는지 정한 문장이 없다. 이 사용은 정의의 공백에서 나왔다.

## num-t3 통과의 원인 후보

`num-t3` 은 두 실행 모두 통과했다(오류 통과). 원인은 확인하지 않았고, 아래 후보는 모두 가정이다.

| 후보 | 단계 출력에서 확인한 사실 | 확인 방법 |
|---|---|---|
| ref 이름 | 앞 재측정은 ref 를 항목 id(`num-t3`)로 넣었고 이번 측정은 중립 번호로 넣었다. 판정 모델과 묶음 입력도 함께 바뀌었다 | 같은 판정 모델과 입력으로 ref 만 바꿔 실행한다 |
| 구절과 context 를 함께 보게 하는 정의 | 실행 2 의 구절은 세션 수(1,650)를 포함하고, 결과 문장은 `context` 에 있다. 정의는 구절과 `context` 를 함께 보고 판정하게 하므로, 수치와 결과가 다른 문장에 나뉜 입력도 일치로 판정될 수 있다. 정답표는 이렇게 나뉜 입력을 기각 근거로 적었다(결정 기록 2) | 수치와 결과가 다른 문장에 나뉜 오류 항목을 추가해 판정이 통과시키는지 센다 |
| '다중 비교 보정 뒤' 조건 누락을 사유에 적지 않음 | 두 실행의 판정 사유 모두 주장에서 이 조건이 빠진 점을 적지 않았다. 같은 묶음의 `dir-t1`(1) 처음 판정은 이 조건이 구절에 없다며 수치·조건을 정보 부족으로 냈다 | 같은 입력으로 판정을 여러 번 실행해 이 조건을 요구하는 빈도를 센다 |

## 병합 판정

이 정정으로 병합 조건 판정은 바뀌지 않는다. 비용 조건은 충족이고, 항목 조건은 `acc-t1`(2)·`exi-t1`(2)·`dir-t1`(1)·`sco-t1`(1) 때문에 미충족이다.
