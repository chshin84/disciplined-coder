# 리뷰 기록 — 둘째 축약 회차 설계 (2026-09-01)

대상은 `docs/superpowers/specs/2026-09-01-second-compression-pass-design.md`이고, 선행 회차는 커밋
`2f64d74`다. **렌즈를 한 번씩만 돌렸다.**

## 돌린 렌즈와 그 판정

| 렌즈 | 이슈 | `principles_applied` |
|---|---|---|
| `lens-grounding` | 열둘이다 | MEASURE-FIRST 외 여섯이다 |
| `lens-consistency` | 열하나다 | TDD 외 일곱이다 |
| `lens-adversarial` | 열둘이다 | SIMPLE 외 아홉이다 |
| `lens-fit` | 열이다 | EXPLICIT 외 일곱이다 |
| `lens-readability` | 아홉이다 | PROSE-FORM 외 다섯이다 |

원본은 같은 이름의 폴더에 렌즈별로 넣었다.

**`lens-prior-art`는 붙이지 않았다.** 이 설계는 이미 하던 일을 이어 정리하는 것이고 새로 해내려는
것이 아니므로 발동 기준에 걸리지 않는다. 사용자에게 제안하지 않았고 그 판정을 여기 적는다.

## 둘 이상의 렌즈가 함께 잡은 것

| 발견 | 잡은 렌즈 |
|---|---|
| 단위를 '자'로 적었으나 실제로는 바이트다 | grounding, consistency |
| 「검사를 셸까지 넓힌다」와 「검사 로직 불변」이 서로를 막는다 | grounding, consistency, adversarial |
| 걸음과 완료 기준 절이 없다 | consistency, adversarial, fit, readability |
| 「첫째 회차」를 이름 없이 서수로만 부른다 | grounding, consistency, fit |
| 렌즈 개수를 이름 없이 박았다 | grounding, consistency, fit |
| 표 머리 「잰 것」이 금지 표현이다 | grounding, consistency, fit, readability |
| 마흔아홉 가운데 열넷은 주석이 아니다 | grounding, consistency |
| 검사 대상 범위를 실제보다 넓게 적었다 | grounding, consistency, adversarial, fit |
| 설계 타입이 담으면 안 되는 상태를 담았다 | fit (단독) |

## 상충 — 렌즈끼리 반대로 판정한 것

**두괄식을 기계로 강제할 것인가.** `lens-adversarial`은 결론이 먼저인지를 문자열로 판정할 수 없으므로
과설계라 하고, 목표에서 「강제한다」를 빼고 렌즈가 보는 것으로 두라고 제안한다. `lens-readability`는
반대로 「완료 기준」 rewrite에 "소제목 아래 첫 문장을 훑는 검사가 돌고 ALL PASS다"를 넣었다. 사용자
결정으로 올린다.

## 커버리지 공백

- **선행연구 대조를 돌리지 않았다.** 위의 판정 이유로 제안하지 않았다.
- **줄일 세 문서의 압축 여지를 렌즈가 세지 않았다.** 호출자가 직접 쟀다 — 검사가 붙든 문장이
  `domain-spec-review` 19개, `domain-docs` 18개, `lens-readability` 11개이고 각각 148줄·124줄·95줄이다.
- **`lens-readability`를 spec에 건 것이 그 렌즈의 선언과 어긋난다.** 그 렌즈는 spec·plan에 걸지 않는다고
  적어 두었고, 이번에는 사용자 지시로 걸었다.

## 호출자가 직접 잰 것

| 측정 항목 | 값 |
|---|---|
| 선행 회차 직전 단언 합계 | PASS=675다 |
| 지금 단언 합계 | PASS=630이다 |
| 순증감 | 마흔다섯이 줄었다 |
| 선행 회차 직전 스킬과 정본 | 78,295자이고 163,729바이트다 |
| 지금 스킬과 정본 | 59,767자이고 123,503바이트다 |
| 선행 회차 직전 README | 6,806자이고 12,710바이트다 |
| 지금 README | 1,597자이고 2,555바이트다 |
| 설치본 고정 커밋 | `95aff61`이라 개명이 아직 안 갔다 |

「쉰여덟」은 DESIGN-NOTES를 지운 직후의 값이었고 그 뒤 금지 표현 검사가 열셋을 더했다. 순증감은
마흔다섯이다.

## 처분

`🔴`가 있으므로 마커는 `escalated`다. 무엇을 `🔴`로 올렸고 무엇을 고쳤는지는 이 파일에 적지 않는다 —
처분은 기록을 쓴 뒤에 정해지고 이 파일은 고치지 않는다.
