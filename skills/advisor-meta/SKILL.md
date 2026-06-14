---
name: advisor-meta
description: 런타임 검증에서 정합성·적합성 리뷰어들의 출력을 집계해 구조적 건강성(상충·커버리지 공백)을 점검하고 accept/regenerate/escalate를 결정하는 메타 레이어 구현 스펙. 내용 재판단은 하지 않는다.
---
# 메타 어드바이저 (meta) — 집계·결정 로직 구현 스펙

> **판단 재귀 회피**: 리뷰어 출력의 *구조*만 본다. "어느 리뷰어가 옳다" 같은 **내용 재판단·가중치 부여 금지**. 재귀의 종단은 사람.

## 언제
정합성·적합성 등 2개 이상 리뷰어를 쓸 때, 그 출력들을 모아 다음 행동을 정한다.

## 하는 일
- **집계**: 모든 리뷰어 이슈를 severity로 정렬·그룹핑·출처 태깅(기계적).
- **상충 감지**: 같은 지점에 상반 판정 → escalate 후보.
- **커버리지 공백**: 리스크상 필요한 차원을 아무도 안 봤나 → 누락 리뷰어 추가 권고.

## 결정 정책 (기본)
- critical 이슈 ≥1 → **regenerate**(1차 재호출, 이슈를 피드백으로). 재시도 상한 도달 시 escalate.
- 상충/공백 → **escalate**(HITL) 또는 누락 차원 보강 후 재집계.
- critical 0 + 상충 없음 → **accept**(major/minor는 로깅).

## 출력 스키마 (JSON)
```
{ "decision": "accept|regenerate|escalate", "reason": "...", "aggregated": [ { "severity": "...", "type": "...", "source": "correctness|fit", "where": "...", "detail": "..." } ], "retry_count": 0 }
```

## 배선
- 리뷰 콜들이 끝난 뒤 **순차로** 실행(병렬 아님). 보통 LLM 없이 **코드 로직**으로 충분(집계·임계). 모호 상충 판정만 선택적 LLM.
- regenerate 루프 상한(예: 2회) — 무한 루프·비용 폭주 방지.
