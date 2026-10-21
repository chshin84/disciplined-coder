# 선행연구 검증자 구성 전체 재측정 결과

이 파일은 `python -I evals/prior-art-verifier/score.py report-v2` 가 만든다. 용어는 `docs/superpowers/plans/2026-10-21-prior-art-verifier-tiering-implement.md` 「용어」를 따른다.

## 병합 조건

새 구성은 비용 조건을 충족했고, 항목 조건을 채우지 못했다.

- 비용 조건(새 구성의 실행마다 비용이 기준선의 어느 실행보다 낮다): 충족. 새 구성 $0.6360, $0.4639, 기준선 $3.3023, $2.9478.
- 항목 조건(기준선이 두 실행 모두 맞힌 항목은 새 구성도 두 실행 모두 맞힌다): 미충족. 비교한 항목·칸 48개, 기준선이 한 번 이상 틀려 빠진 항목·칸 4개(num-t3, dir-t2, hard-ctx-t1, hard-cnd-t1).

## 기준선이 맞힌 항목 중 새 구성이 틀린 항목

아래 표의 항목은 기준선이 두 실행 모두 맞혔고 새 구성이 한 번 이상 틀렸다.

| 항목 | 정답 | 기준선 판정 | 새 구성 판정 | 판정 원본(수치·조건/방향/범위) |
|---|---|---|---|---|
| acc-t1 | 참 | supported, supported | verify_failed, supported | 판정 불가/일치/불일치 ; 일치/일치/일치 |
| acc-t2 | 참 | supported, supported | supported, verify_failed | 판정 불가/일치/일치 ; 판정 불가/일치/일치 |
| exi-t1 | 참 | supported, supported | unsupported, supported | 불일치/일치/불일치 ; 일치/일치/일치 |
| quo-t1 | 참 | supported, supported | unsupported, unsupported | 불일치/일치/불일치 ; 일치/일치/불일치 |
| quo-t3 | 참 | supported, supported | unsupported, unsupported | 일치/일치/불일치 ; 일치/일치/불일치 |
| num-t2 | 참 | supported, supported | supported, verify_failed | 판정 불가/일치/일치 ; 판정 불가/일치/일치 |
| dir-t1 | 참 | supported, supported | supported, unsupported | 판정 불가/일치/일치 ; 일치/일치/불일치 |
| sco-t3 | 참 | supported, supported | supported, verify_failed | 일치/판정 불가/일치 ; 판정 불가/판정 불가/판정 불가 |
| num-t4 | 참 | supported, supported | supported, unsupported | 일치/일치/일치 ; 판정 불가/일치/일치 |
| num-t5 | 참 | supported, supported | supported, verify_failed | 판정 불가/일치/일치 ; 판정 불가/일치/일치 |
| hard-f200-t1 | 참 | supported, supported | unsupported, unsupported | 불일치/일치/불일치 ; 일치/일치/불일치 |
| map-1:코딩 에이전트 설정 파일 구조의 요인 설계 연구/outcome | 지도 대조 칸 | 맞힘 | [False, False] | 해당 없음 |
| map-1:내재적 자기 수정의 한계(Huang 등)/outcome | 지도 대조 칸 | 맞힘 | [False, False] | 해당 없음 |

## 카테고리별 오류 통과와 참 기각

칸의 값은 실행 1·2 의 "오류 통과 / 참 기각" 이다.

| 카테고리 | 기준선 | 새 구성 |
|---|---|---|
| access | 0 / 0, 0 / 0 | 0 / 2, 0 / 2 |
| exists | 0 / 0, 0 / 0 | 0 / 1, 0 / 0 |
| quote | 0 / 0, 0 / 0 | 0 / 2, 0 / 2 |
| numbers_conditions | 1 / 1, 1 / 1 | 0 / 1, 0 / 4 |
| direction | 0 / 1, 0 / 2 | 0 / 0, 0 / 2 |
| scope | 0 / 0, 0 / 0 | 0 / 0, 0 / 1 |
| map | 0 / 0, 0 / 0 | 0 / 1, 0 / 1 |

지도 대조의 판정 대상 칸 누락(실패): 기준선 [0, 2], 새 구성 [4, 4].

## 새 구성의 검증 실패

아래 표는 최종 판정이 verify_failed 인 항목과 실행이다.

| 항목 | 실행 | 판정 원본(수치·조건/방향/범위) | 다른 칸에 불일치 |
|---|---|---|---|
| acc-t1 | 1 | 판정 불가/일치/불일치 | 예 |
| acc-t2 | 2 | 판정 불가/일치/일치 | 아니오 |
| num-t2 | 2 | 판정 불가/일치/일치 | 아니오 |
| sco-t3 | 2 | 판정 불가/판정 불가/판정 불가 | 아니오 |
| num-t5 | 2 | 판정 불가/일치/일치 | 아니오 |
| hard-cnd-t1 | 1 | 판정 불가/일치/일치 | 아니오 |

## 어려운 항목

칸의 값은 실행 1·2 의 결과이고, 판정 불가로 넘김과 틀리게 확신함은 상향 전 판정 원본으로 센다.

| 항목 | 종류 | 정답 | 기준선 맞힘 | 새 구성 맞힘 | 판정 불가로 넘김 | 틀리게 확신함 |
|---|---|---|---|---|---|---|
| hard-ctx-t1 | context | 참 | 아니오, 아니오 | 예, 아니오 | 예, 예 | 아니오, 아니오 |
| hard-ctx-f1 | context | 오류 | 예, 예 | 예, 예 | 아니오, 아니오 | 아니오, 아니오 |
| hard-cnd-t1 | conditions | 참 | 아니오, 아니오 | 아니오, 아니오 | 예, 아니오 | 아니오, 아니오 |
| hard-cnd-f1 | conditions | 오류 | 예, 예 | 예, 예 | 아니오, 아니오 | 아니오, 아니오 |
| hard-tbl-t1 | table | 참 | 예, 예 | 예, 예 | 아니오, 아니오 | 아니오, 아니오 |
| hard-tbl-f1 | table | 오류 | 예, 예 | 예, 예 | 아니오, 아니오 | 아니오, 아니오 |
| hard-kor-t1 | korean | 참 | 예, 예 | 예, 예 | 아니오, 아니오 | 아니오, 아니오 |
| hard-kor-f1 | korean | 오류 | 예, 예 | 예, 예 | 아니오, 아니오 | 아니오, 아니오 |
| hard-f200-t1 | fake-200 | 참 | 예, 예 | 아니오, 아니오 | 아니오, 아니오 | 예, 예 |
| hard-f200-f1 | fake-200 | 오류 | 예, 예 | 예, 예 | 아니오, 아니오 | 아니오, 아니오 |

## 판정 에이전트 노력 수준별 비교

이 비교는 실행 1 의 추출 출력으로 어려운 항목만 판정한 결과이며 병합 판정에 쓰지 않는다.

| 수준 | 판정한 어려운 항목 | 판정 불가로 넘김 | 틀리게 확신함 | 비용(USD) |
|---|---|---|---|---|
| low | 6 | hard-cnd-t1, hard-cnd-f1, hard-tbl-t1 | hard-f200-t1 | 0.0146 |
| medium | 6 | hard-cnd-t1 | hard-f200-t1 | 0.0154 |
| high | 6 | hard-ctx-t1, hard-cnd-t1 | hard-f200-t1 | 0.0204 |

high 의 비용은 어려운 항목 URL 의 판정 실행만 합한 값이다.

## 판정 불가 이유 유형

판정 불가 칸마다 이유 유형을 셌다. 이유 유형이 빠진 칸은 '(이유 없음)' 으로 센다.

| 단계·설정 | 이유 유형별 개수 |
|---|---|
| judge-def claude-haiku-5-5/low | 맥락 부족 1, 표·그림 값 2 |
| judge-def claude-haiku-5-5/medium | 표·그림 값 1 |
| judge-def claude-haiku-5-5/high | 맥락 부족 17, 표·그림 값 1 |
| escalate-def claude-sonnet-5-5/high | 맥락 부족 7 |

## 상향 비율

비율은 판정한 주장 중 판정 불가로 넘긴 주장의 비율이다.

| 실행 | 판정한 주장 | 판정 불가로 넘김 | 상향 판정을 받음 | 비율 |
|---|---|---|---|---|
| 1 | 28 | 10 (acc-t1, acc-t2, num-t2, num-t3, num-f3, dir-t1, sco-t3, num-t5, hard-ctx-t1, hard-cnd-t1) | 10 | 35.7% |
| 2 | 27 | 6 (acc-t2, num-t2, sco-t3, num-t4, num-t5, hard-ctx-t1) | 6 | 22.2% |

## 단계별 비용

비용은 단계·설정·실행마다 오류 없는 마지막 줄의 total_cost_usd 를 합한 값이다.

| 단계 | 설정 | 실행 1 | 실행 2 |
|---|---|---|---|
| baseline-cite | claude-opus-5-5/medium | 3.0909 | 2.7379 |
| baseline-map | claude-opus-5-5/medium | 0.2113 | 0.2098 |
| extract-def | claude-haiku-5-5/high | 0.2135 | 0.1724 |
| judge-def | claude-haiku-5-5/high | 0.0694 | 0.0637 |
| escalate-def | claude-sonnet-5-5/high | 0.3478 | 0.2222 |
| map-def | claude-haiku-5-5/high | 0.0053 | 0.0056 |
| judge-def(어려운 항목만) | claude-haiku-5-5/low | 0.0146 | 실행하지 않음 |
| judge-def(어려운 항목만) | claude-haiku-5-5/medium | 0.0154 | 실행하지 않음 |

두 결과 파일의 전체 비용(오류 줄과 다시 실행한 줄 포함): $7.3799.

## 실행 기록

기준선 34줄, 새 구성 73줄, 오류 줄 0개, 시간 초과 0개, 모델 불일치 0개.

실행 조건은 README.md 「실행 조건」에 있다.
