---
name: reviewer-grounding
description: LLM 출력·주장이 그 출처(런타임=요청+맥락 / spec리뷰=검토 문서+주입된 사실)에 근거하는지 보는 리뷰어 렌즈 — 누락·모순·환각. 호출자(domain-llm-runtime, domain-spec-review)가 source를 제공한다.
---
# reviewer-grounding — 근거 충실성 렌즈 (프롬프트 설계도)

> 이것은 **렌즈 하나**다. 어떻게 실행되는지(제품 코드의 리뷰 콜인지, 읽기 전용 서브에이전트인지)는
> 호출자가 정한다. 이 문서는 "무엇을 보고 어떤 문제 목록을 돌려주는가"만 정의한다.

## 무엇을 보나
출력이나 주장이 **제공된 출처에 충실**한가. 출처는 호출자가 준다. 런타임에서는 원래 요청과 제공된
맥락이 출처이고, spec/plan 리뷰에서는 검토 대상 문서와 PREP으로 주입된 선행 결정·검증할 구체 사실이
출처다.

## 체크리스트
- 요청한 항목·필드·제약을 빠짐없이 충족했는가(누락).
- 출처와 모순되는 진술이 있는가(모순).
- 출처에 없는 사실을 지어냈는가(환각, 근거 없음).
- 숫자·인용·식별자가 출처와 일치하는가.

## 레퍼런스 프롬프트 (언어 중립)
- system: "너는 근거 충실성 검수자다. 제공된 출처만을 기준으로, 후보의 누락·모순·근거 없는 주장을 찾아라. 고치지 말고 지적만 하라. 출처에 없으면 '근거 없음'으로 표시."
- user: "[출처]\n{source}\n\n[후보]\n{candidate}\n\n위 체크리스트로 이슈를 아래 JSON 스키마로 출력."

## 출력 스키마 (공통)
```
{ "lens": "grounding", "issues": [ { "severity": "critical|major|minor", "type": "omission|contradiction|unsupported|mismatch", "where": "출처/후보 내 위치", "detail": "무엇이 왜" } ], "verdict": "ok|revise", "notes": "" }
```
critical은 메타가 regenerate를 트리거한다. major·minor는 정책에 따라 로깅 후 통과.
