# 선행연구 검증자 설정 선택 시험 결과

## 추출 단계
### access

기준선(나쁜 쪽): 오류 통과 0, 참 기각 0, 실패 0, 실행당 비용 $2.1409. 흔들림: {'missed_errors': 0, 'rejected_truths': 0}

| 설정 | 오류 통과 | 참 기각 | 실패 | 비용(USD) | 제외 |
|---|---|---|---|---|---|
| claude-haiku-5-5/low | 0 | 0 | 0 | 0.0923 |  |
| claude-haiku-5-5/medium | 0 | 0 | 0 | 0.1011 |  |
| claude-haiku-5-5/high | 0 | 0 | 0 | 0.1203 |  |

고른 설정: claude-haiku-5-5/low

### exists

기준선(나쁜 쪽): 오류 통과 0, 참 기각 0, 실패 0, 실행당 비용 $2.1409. 흔들림: {'missed_errors': 0, 'rejected_truths': 0}

| 설정 | 오류 통과 | 참 기각 | 실패 | 비용(USD) | 제외 |
|---|---|---|---|---|---|
| claude-haiku-5-5/low | 0 | 0 | 0 | 0.0923 |  |
| claude-haiku-5-5/medium | 0 | 0 | 0 | 0.1011 |  |
| claude-haiku-5-5/high | 0 | 0 | 0 | 0.1203 |  |

고른 설정: claude-haiku-5-5/low

### quote

기준선(나쁜 쪽): 오류 통과 0, 참 기각 0, 실패 0, 실행당 비용 $2.1409. 흔들림: {'missed_errors': 0, 'rejected_truths': 0}

| 설정 | 오류 통과 | 참 기각 | 실패 | 비용(USD) | 제외 |
|---|---|---|---|---|---|
| claude-haiku-5-5/low | 0 | 0 | 0 | 0.0923 |  |
| claude-haiku-5-5/medium | 0 | 0 | 0 | 0.1011 |  |
| claude-haiku-5-5/high | 0 | 0 | 0 | 0.1203 |  |

고른 설정: claude-haiku-5-5/low

추출 단계에서 고른 하나의 설정: claude-haiku-5-5/low

## 판정 단계
### numbers_conditions

기준선(나쁜 쪽): 오류 통과 0, 참 기각 0, 실패 0, 실행당 비용 $2.1409. 흔들림: {'missed_errors': 0, 'rejected_truths': 0}

| 설정 | 오류 통과 | 참 기각 | 실패 | 비용(USD) | 제외 |
|---|---|---|---|---|---|
| claude-haiku-5-5/low | 0 | 1 | 0 | 0.0120 |  |
| claude-haiku-5-5/medium | 0 | 1 | 0 | 0.0123 |  |
| claude-haiku-5-5/high | 0 | 1 | 0 | 0.0135 |  |
| claude-haiku-5-5/xhigh | 0 | 1 | 0 | 0.0170 |  |
| claude-sonnet-5-5/low | 0 | 1 | 0 | 0.2142 |  |
| claude-sonnet-5-5/medium | 0 | 1 | 0 | 0.2138 |  |
| claude-sonnet-5-5/high | 0 | 1 | 0 | 0.2168 |  |
| claude-opus-5-5/low | 0 | 1 | 0 | 0.4194 |  |

고른 설정: 없음(기준선을 넘은 설정이 없다)

### direction

기준선(나쁜 쪽): 오류 통과 0, 참 기각 0, 실패 0, 실행당 비용 $2.1409. 흔들림: {'missed_errors': 0, 'rejected_truths': 0}

| 설정 | 오류 통과 | 참 기각 | 실패 | 비용(USD) | 제외 |
|---|---|---|---|---|---|
| claude-haiku-5-5/low | 0 | 0 | 0 | 0.0117 |  |
| claude-haiku-5-5/medium | 0 | 0 | 0 | 0.0120 |  |
| claude-haiku-5-5/high | 0 | 0 | 0 | 0.0128 |  |

고른 설정: claude-haiku-5-5/low

### scope

기준선(나쁜 쪽): 오류 통과 0, 참 기각 0, 실패 0, 실행당 비용 $2.1409. 흔들림: {'missed_errors': 0, 'rejected_truths': 0}

| 설정 | 오류 통과 | 참 기각 | 실패 | 비용(USD) | 제외 |
|---|---|---|---|---|---|
| claude-haiku-5-5/low | 0 | 0 | 0 | 0.0118 |  |
| claude-haiku-5-5/medium | 0 | 0 | 0 | 0.0126 |  |
| claude-haiku-5-5/high | 0 | 0 | 0 | 0.0127 |  |

고른 설정: claude-haiku-5-5/low


## 지도 대조
### map

기준선(나쁜 쪽): 오류 통과 0, 참 기각 0, 실패 0, 실행당 비용 $0.2117. 흔들림: {'missed_errors': 0, 'rejected_truths': 0}

| 설정 | 오류 통과 | 참 기각 | 실패 | 비용(USD) | 제외 |
|---|---|---|---|---|---|
| claude-haiku-5-5/low | 0 | 0 | 2 | 0.0054 |  |
| claude-haiku-5-5/medium | 0 | 0 | 2 | 0.0065 |  |
| claude-haiku-5-5/high | 0 | 0 | 0 | 0.0073 |  |

고른 설정: claude-haiku-5-5/high


## 실행 기록

전체 102줄, 오류 줄 0개, 시간 초과 0개.
모델 불일치 줄: 0개.

실행 조건은 README.md 「실행 조건」에 있다.
