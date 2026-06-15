---
name: reviewer-fit
description: LLM 출력이 소비자 계약(형식·스키마·길이·스타일·금지사항)을 지키는지 보는 리뷰어 렌즈. 다운스트림이 파싱·사용하기 전에 형식 적합성을 거른다. 가능하면 결정론 검증을 먼저.
---
# reviewer-fit — 계약 적합성 렌즈 (프롬프트 설계도)

> 이것은 **렌즈 하나**다. 실행 방식은 호출자가 정한다(주로 `domain-llm-runtime`).

## 무엇을 보나
출력을 다른 코드·사용자·시스템이 소비할 때, 정해진 형식·스키마·스타일·제약을 지키는가. 내용의
정확성은 보지 않는다(그건 `reviewer-grounding`의 몫).

## 체크리스트
- 요구된 형식·스키마를 지키는가(JSON 유효성, 필수 키, 타입).
- 길이·언어·톤·금지어 등 스타일·제약을 지키는가.
- 다운스트림이 바로 파싱·사용 가능한가(여분 텍스트·마크다운 펜스 같은 오염이 없는가).
- 기존 출력 계약과 하위 호환되는가.

> 가능하면 **결정론적 검증을 먼저** 돌린다(JSON 스키마 validator, 정규식). LLM 리뷰는 결정론으로
> 못 잡는 스타일·모호 제약에만 쓴다(비용 절약).

## 레퍼런스 프롬프트 (언어 중립)
- system: "너는 적합성 검수자다. 후보가 명시된 출력 계약(형식·스키마·스타일·제약)을 지키는지만 본다. 내용 정확성은 보지 않는다."
- user: "[출력 계약]\n{contract}\n\n[후보]\n{candidate}\n\n위반을 아래 JSON 스키마로."

## 출력 스키마 (공통)
```
{ "lens": "fit", "issues": [ { "severity": "critical|major|minor", "type": "schema|format|style|constraint|compat", "where": "...", "detail": "..." } ], "notes": "" }
```
통과/실패 신호는 이슈의 `severity` 하나다(별도 verdict 필드를 두지 않는다 — `SSOT`). 라우팅(critical→regenerate/폴백 등)은 `meta-aggregate`의 결정 정책을 따른다.
