# 대응표 — 리뷰어 렌즈 넷 (reviewer-grounding · reviewer-consistency · reviewer-adversarial · reviewer-fit)

원문의 각 항목이 새 문서 어디로 갔는지, 지웠다면 왜 지웠는지 남긴다.
'지움' 항목과 빈칸이 사람이 검토할 대상이다.

세 번째 칸의 값은 `옮김`, `합침`, `**지움**`, `신설` 중 하나이며 지움에는 반드시 근거를 붙인다.
`신설`은 원문에 없던 것을 스펙이 요구해 새로 넣은 항목이라 왼쪽 칸이 `(원문 없음)`으로 시작한다.

**지움은 없다.** 네 파일 모두 원문의 모든 구성 요소가 새 문서에 살아 있다. 신설은 여섯이다 — 네
`description`에 넣은 렌즈 구분 문장 넷은 스펙이 요구한 것이고, 나머지 둘은 `reviewer-fit` 스키마의
`where`와 `detail` 자리표시를 다른 셋과 같은 설명 문구로 채운 것이다(원문은 둘 다 `"..."`라는 빈
자리표시였다).

**JSON 스키마 필드와 허용 값은 하나도 바꾸지 않았다.** `lens`·`issues`·`severity`·`type`·`where`·
`detail`·`notes`라는 키와, `critical|major|minor` 같은 `severity` 값과, `omission|contradiction|
unsupported|mismatch`류의 `type` 값이 재작성 전후로 동일하다. 영문화한 것은 `where`와 `detail`의
**자리표시 설명 문구**뿐이며 이것은 값의 예시이지 계약이 아니다.

## reviewer-grounding

| 원문 항목 | 새 문서 위치 | 처리와 근거 |
|---|---|---|
| frontmatter `name: reviewer-grounding` | frontmatter `name` | 옮김 — 스킬 식별자라 그대로 둔다 |
| description — LLM 출력·주장이 그 출처에 근거하는지 보는 리뷰어 렌즈 | description 첫 문장 | 옮김 — 검진에서 `LLM` 한정어가 빠진 것이 드러나 `an LLM output or a claim`으로 되살렸다 |
| description — 누락·모순·환각 | description 첫 문장 끝 | 옮김 — `unsupported (hallucinated)`로 환각을 스키마 값과 묶어 적었다 |
| description — 런타임의 출처는 요청과 맥락이다 | description 셋째 문장 | 옮김 |
| description — spec 리뷰의 출처는 검토 문서와 주입된 사실이다 | description 셋째 문장 | 옮김 |
| description — 호출자(`domain-llm-runtime`·`domain-spec-review`)가 source를 제공한다 | description 셋째·넷째 문장 | 옮김 |
| (원문 없음) 이 렌즈를 언제 고르는가 | description 둘째 문장 | 신설 — 스펙이 "네 렌즈의 구분점이 드러나게" 요구했다. "내용이 출처에 참인가"를 묻는 자리라고 적어 `reviewer-fit`의 "모양이 쓸 수 있는가"와 갈리고, 검진에서 나머지 셋만 상호 배제 절을 달고 있음이 드러나 `reviewer-consistency`를 배제하는 절도 붙였다 |
| H1 `reviewer-grounding — 근거 충실성 렌즈 (프롬프트 설계도)` | H1 `reviewer-grounding — source-fidelity lens (prompt blueprint)` | 옮김 |
| 인용 블록 — 이것은 렌즈 하나다 | 인용 블록 첫 문장 | 옮김 |
| 인용 블록 — 실행 방식(제품 코드 리뷰 콜인지 읽기 전용 서브에이전트인지)은 호출자가 정한다 | 인용 블록 둘째 문장 | 옮김 — 두 실행 형태를 예시로 그대로 남겼다 |
| 인용 블록 — 이 문서는 무엇을 보고 어떤 문제 목록을 돌려주는가만 정의한다 | 인용 블록 셋째 문장 | 옮김 |
| `## 무엇을 보나` — 제공된 출처에 충실한가 | `## What it looks at` 첫 문장 | 옮김 |
| `## 무엇을 보나` — 출처는 호출자가 준다 | `## What it looks at` 둘째 문장 | 옮김 |
| `## 무엇을 보나` — 런타임 출처는 원래 요청과 제공된 맥락이다 | `## What it looks at` 셋째 문장 | 옮김 |
| `## 무엇을 보나` — spec/plan 리뷰 출처는 검토 문서와 PREP으로 주입된 선행 결정·검증할 구체 사실이다 | `## What it looks at` 넷째 문장 | 옮김 — `PREP`은 `domain-spec-review`가 쓰는 고유 이름이라 번역하지 않았다 |
| 체크리스트 — 요청한 항목·필드·제약을 빠짐없이 충족했는가(누락) | `## Checklist` 첫 항목 | 옮김 |
| 체크리스트 — 출처와 모순되는 진술이 있는가(모순) | `## Checklist` 둘째 항목 | 옮김 |
| 체크리스트 — 출처에 없는 사실을 지어냈는가(환각, 근거 없음) | `## Checklist` 셋째 항목 | 옮김 |
| 체크리스트 — 숫자·인용·식별자가 출처와 일치하는가 | `## Checklist` 넷째 항목 | 옮김 |
| `## 레퍼런스 프롬프트 (언어 중립)` 제목 | `## Reference prompt (language-neutral)` | 옮김 — '언어 중립'은 이 프롬프트가 특정 구현 언어에 매이지 않는다는 단서라 그대로 남겼다 |
| system 프롬프트 — 너는 근거 충실성 검수자다 | system 프롬프트 | 옮김 |
| system 프롬프트 — 제공된 출처만을 기준으로 판단한다 | system 프롬프트 | 옮김 |
| system 프롬프트 — 누락·모순·근거 없는 주장을 찾아라 | system 프롬프트 | 옮김 |
| system 프롬프트 — 고치지 말고 지적만 하라 | system 프롬프트 | 옮김 |
| system 프롬프트 — 출처에 없으면 '근거 없음'으로 표시 | system 프롬프트 끝 | 옮김 |
| user 프롬프트 — `[출처]{source}` + `[후보]{candidate}` + 체크리스트대로 JSON 스키마 출력 | user 프롬프트 | 옮김 — 자리표시자 이름 `{source}`·`{candidate}`는 계약이라 그대로 두고 라벨만 영문화했다 |
| `## 출력 스키마 (공통)` 제목 | `## Output schema (shared)` | 옮김 |
| JSON — `lens`·`issues`·`severity`·`type`·`where`·`detail`·`notes` 키 | 같은 JSON | 옮김 — **필드 이름을 바꾸지 않았다** |
| JSON — `severity` 값 `critical\|major\|minor` | 같은 JSON | 옮김 — 허용 값을 그대로 두었다 |
| JSON — `type` 값 `omission\|contradiction\|unsupported\|mismatch` | 같은 JSON | 옮김 — 허용 값을 그대로 두었다 |
| JSON — `where` 자리표시 "출처/후보 내 위치" | `"location in the source or the candidate"` | 옮김 — 값의 예시라 설명 문구만 영문화했다 |
| JSON — `detail` 자리표시 "무엇이 왜" | `"what is wrong and why"` | 옮김 — 위와 같다 |
| 꼬리 문장 — 통과/실패 신호는 `severity` 하나다(별도 verdict 필드 없음 — `SSOT`) | 마지막 문단 | 옮김 |
| 꼬리 문장 — 라우팅(critical→regenerate 등)은 `meta-aggregate`의 결정 정책을 따른다 | 마지막 문단 | 옮김 — 화살표는 `CLEAR-COMM`에 따라 문장으로 풀었다 |

## reviewer-consistency

| 원문 항목 | 새 문서 위치 | 처리와 근거 |
|---|---|---|
| frontmatter `name: reviewer-consistency` | frontmatter `name` | 옮김 |
| description — 설계 문서(spec/plan)를 보는 리뷰어 렌즈 | description 첫 문장 | 옮김 |
| description — 내부 모순 | description 첫 문장 | 옮김 |
| description — 커버리지 공백 | description 첫 문장 | 옮김 — spec과 plan 사이의 공백이라고 명시했다 |
| description — 이름/타입 드리프트 | description 첫 문장 | 옮김 |
| description — 스코프 | description 첫 문장 | 옮김 — 처음엔 "한 계획에 담기엔 큰 스코프"라고만 적어 원문의 두 층위 가운데 한쪽만 남았다. 검진에서 드러나 "한 구현 계획에 맞지 않아 쪼개야 한다"로 두 층위를 되살렸다 |
| description — `domain-spec-review`가 읽기 전용 서브에이전트로 호출한다 | description 마지막 문장 | 옮김 |
| (원문 없음) 이 렌즈를 언제 고르는가 | description 둘째 문장 | 신설 — "문서가 스스로 아귀가 맞는가"를 묻는 자리이며 근거 충실성이나 실패 모드를 묻는 자리가 아니라고 적어 다른 셋과 갈랐다 |
| H1 `reviewer-consistency — 내부 정합성·커버리지 렌즈 (프롬프트 설계도)` | H1 `reviewer-consistency — internal consistency and coverage lens (prompt blueprint)` | 옮김 |
| 인용 블록 — 이것은 렌즈 하나다 | 인용 블록 | 옮김 |
| 인용 블록 — 실행은 `domain-spec-review`가 읽기 전용 서브에이전트로 띄운다 | 인용 블록 | 옮김 |
| `## 무엇을 보나` — 문서가 자기 자신과 어긋나지 않는가 | `## What it looks at` | 옮김 |
| `## 무엇을 보나` — 짝 문서(spec ↔ plan)와 어긋나지 않는가 | `## What it looks at` | 옮김 |
| 체크리스트 — 내부 모순: 한 절이 다른 절과 부딪치는가 | `## Checklist` 첫 항목 | 옮김 |
| 체크리스트 — 문서가 스스로 정한 원칙을 어기는 설계 포함 | `## Checklist` 첫 항목 | 옮김 |
| 체크리스트 — 아키텍처 설명이 기능 설명과 맞는가 | `## Checklist` 첫 항목 | 옮김 |
| 체크리스트 — 커버리지 공백: spec 요구가 plan의 어떤 작업으로 구현되는지 짚을 수 있는가 | `## Checklist` 둘째 항목 | 옮김 |
| 체크리스트 — 빠진 게 있는가 | `## Checklist` 둘째 항목 | 옮김 |
| 체크리스트 — 이름·타입 드리프트: 같은 대상을 두 이름으로 부르는가 | `## Checklist` 셋째 항목 | 옮김 |
| 체크리스트 — 드리프트 예시 `clearLayers` / `clearFullLayers` | `## Checklist` 셋째 항목 | 옮김 — 예시 식별자를 그대로 살렸다 |
| 체크리스트 — 스코프: 한 구현 계획에 맞는 크기인가, 쪼개야 하는가 | `## Checklist` 넷째 항목 | 옮김 |
| `## 레퍼런스 프롬프트 (언어 중립)` 제목 | `## Reference prompt (language-neutral)` | 옮김 |
| system 프롬프트 — 너는 정합성·커버리지 검수자다 | system 프롬프트 | 옮김 |
| system 프롬프트 — 내부 모순·커버리지 공백·이름 타입 드리프트·스코프 문제를 찾아라 | system 프롬프트 | 옮김 |
| system 프롬프트 — 고치지 말고 지적만 | system 프롬프트 | 옮김 |
| user 프롬프트 — `[원문]{document}` + `[관련 배경]{background}` + 체크리스트대로 JSON | user 프롬프트 | 옮김 — 자리표시자 이름은 그대로 두고 라벨만 영문화했다 |
| `## 출력 스키마 (공통)` 제목 | `## Output schema (shared)` | 옮김 |
| JSON — `lens`·`issues`·`severity`·`type`·`where`·`detail`·`notes` 키 | 같은 JSON | 옮김 — **필드 이름을 바꾸지 않았다** |
| JSON — `severity` 값 `critical\|major\|minor` | 같은 JSON | 옮김 — 허용 값을 그대로 두었다 |
| JSON — `type` 값 `contradiction\|gap\|drift\|scope` | 같은 JSON | 옮김 — 허용 값을 그대로 두었다 |
| JSON — `where` 자리표시 "문서 내 위치" | `"location in the document"` | 옮김 |
| JSON — `detail` 자리표시 "무엇이 왜" | `"what is wrong and why"` | 옮김 |
| 꼬리 문장 — `severity` 하나가 신호다(verdict 없음 — `SSOT`) | 마지막 문단 | 옮김 |
| 꼬리 문장 — 라우팅은 `meta-aggregate`를 따른다 | 마지막 문단 | 옮김 |

## reviewer-adversarial

| 원문 항목 | 새 문서 위치 | 처리와 근거 |
|---|---|---|
| frontmatter `name: reviewer-adversarial` | frontmatter `name` | 옮김 |
| description — 설계 문서를 공격적으로 보는 리뷰어 렌즈 | description 첫 문장 | 옮김 — `attacks a design document`로 '공격적'을 살렸다 |
| description — 실패 모드 | description 첫 문장 | 옮김 |
| description — 과설계 | description 첫 문장 | 옮김 |
| description — 비가역 | description 첫 문장 | 옮김 |
| description — YAGNI 위반 | description 첫 문장 | 옮김 |
| description — 가드: 기능 추가 제안 금지(자가당착) | description 셋째 문장 | 옮김 — **가드를 약화시키지 않았다**. 금지와 그 이유(자가당착)를 함께 남겼다 |
| description — 가드: 근거 필수 | description 셋째 문장 | 옮김 — 모든 이슈가 근거를 달아야 한다고 남겼다 |
| description — `domain-spec-review`가 읽기 전용 서브에이전트로 호출한다 | description 마지막 문장 | 옮김 |
| (원문 없음) 이 렌즈를 언제 고르는가 | description 둘째 문장 | 신설 — "어디서 깨지고 어디가 과한가"를 묻는 자리이며 근거나 내부 정합성을 묻는 자리가 아니라고 적었다 |
| H1 `reviewer-adversarial — 적대적·YAGNI 렌즈 (프롬프트 설계도)` | H1 `reviewer-adversarial — adversarial and YAGNI lens (prompt blueprint)` | 옮김 |
| 인용 블록 — 이것은 렌즈 하나다 | 인용 블록 | 옮김 |
| 인용 블록 — 실행은 `domain-spec-review`가 읽기 전용 서브에이전트로 띄운다 | 인용 블록 | 옮김 |
| `## 무엇을 보나` — 설계가 어디서 깨지는가 | `## What it looks at` | 옮김 |
| `## 무엇을 보나` — 어디서 과한가 | `## What it looks at` | 옮김 |
| `## 무엇을 보나` — 어디서 되돌리기 어려운가 | `## What it looks at` | 옮김 |
| 체크리스트 — 실패 모드: 무엇이 잘못될 수 있는가 | `## Checklist` 첫 항목 | 옮김 |
| 체크리스트 — 엣지 케이스·경합·부분 실패 | `## Checklist` 첫 항목 | 옮김 |
| 체크리스트 — 과설계: 지금 필요 없는 일반화·추상화·유연성(`SIMPLE`·YAGNI 위반) | `## Checklist` 둘째 항목 | 옮김 — 원칙 ID `SIMPLE`도 그대로 참조한다 |
| 체크리스트 — 비가역성: 되돌리기 어려운 결정이 근거 없이 들어갔는가(`REVERSIBLE`) | `## Checklist` 셋째 항목 | 옮김 — 원칙 ID `REVERSIBLE`도 그대로 참조한다 |
| 가드 인용 블록 — 이 렌즈는 기능을 추가하자고 제안하지 않는다 | 가드 인용 블록 | 옮김 — 별도 인용 블록으로 남겨 강조를 유지했다 |
| 가드 인용 블록 — YAGNI 리뷰가 기능을 늘리면 자가당착이다 | 가드 인용 블록 | 옮김 |
| 가드 인용 블록 — 제안은 단순화이거나 완화해야 할 위험이어야 한다 | 가드 인용 블록 | 옮김 |
| 가드 인용 블록 — 반드시 근거를 단다 | 가드 인용 블록 | 옮김 — 처음엔 평서문이라 '반드시'의 의무 강도가 한 단계 약했다. 검진에서 드러나 `must carry its evidence without exception`으로 되돌렸다 |
| `## 레퍼런스 프롬프트 (언어 중립)` 제목 | `## Reference prompt (language-neutral)` | 옮김 |
| system 프롬프트 — 너는 적대적·YAGNI 검수자다 | system 프롬프트 | 옮김 |
| system 프롬프트 — 실패 모드·과설계·비가역을 찾아라 | system 프롬프트 | 옮김 |
| system 프롬프트 — 기능 추가는 제안하지 말 것(자가당착) | system 프롬프트 | 옮김 — 프롬프트 안의 가드도 같은 강도로 남겼다 |
| system 프롬프트 — 단순화나 위험 완화만, 근거와 함께 | system 프롬프트 | 옮김 |
| user 프롬프트 — `[원문]{document}` + `[관련 배경]{background}` + 체크리스트대로 JSON | user 프롬프트 | 옮김 |
| `## 출력 스키마 (공통)` 제목 | `## Output schema (shared)` | 옮김 |
| JSON — `lens`·`issues`·`severity`·`type`·`where`·`detail`·`notes` 키 | 같은 JSON | 옮김 — **필드 이름을 바꾸지 않았다** |
| JSON — `severity` 값 `critical\|major\|minor` | 같은 JSON | 옮김 — 허용 값을 그대로 두었다 |
| JSON — `type` 값 `failure-mode\|over-engineering\|irreversible\|risk` | 같은 JSON | 옮김 — 허용 값을 그대로 두었다 |
| JSON — `where` 자리표시 "문서 내 위치" | `"location in the document"` | 옮김 |
| JSON — `detail` 자리표시 "위험과 이유; 단순화면 그 근거" | `"the risk and why it is a risk; for a simplification, the evidence for it"` | 옮김 — 두 층위(위험의 이유, 단순화의 근거)를 모두 살렸다 |
| 꼬리 문장 — `severity` 하나가 신호다(verdict 없음 — `SSOT`) | 마지막 문단 | 옮김 |
| 꼬리 문장 — 라우팅은 `meta-aggregate`를 따른다 | 마지막 문단 | 옮김 |

## reviewer-fit

| 원문 항목 | 새 문서 위치 | 처리와 근거 |
|---|---|---|
| frontmatter `name: reviewer-fit` | frontmatter `name` | 옮김 |
| description — LLM 출력이 소비자 계약을 지키는지 보는 리뷰어 렌즈 | description 첫 문장 | 옮김 |
| description — 계약의 내용(형식·스키마·길이·스타일·금지사항) | description 첫 문장 | 옮김 — 다섯 항목을 모두 나열했다 |
| description — 다운스트림이 파싱·사용하기 전에 형식 적합성을 거른다 | description 첫 문장 끝 | 옮김 — '거른다'는 선별 관문 뉘앙스를 `screening it for shape before anything downstream parses and uses it`으로 살렸다 |
| description — 가능하면 결정론 검증을 먼저 | description 마지막 문장 | 옮김 — 결정론이 못 잡는 것에만 이 렌즈를 쓴다는 단서까지 붙였다 |
| (원문 없음) 이 렌즈를 언제 고르는가 | description 둘째 문장 | 신설 — "모양이 쓸 수 있는가"를 묻는 자리이며 내용의 참·거짓은 `reviewer-grounding`의 몫이라고 적어 둘을 갈랐다 |
| H1 `reviewer-fit — 계약 적합성 렌즈 (프롬프트 설계도)` | H1 `reviewer-fit — contract fitness lens (prompt blueprint)` | 옮김 |
| 인용 블록 — 이것은 렌즈 하나다 | 인용 블록 첫 문장 | 옮김 |
| 인용 블록 — 실행 방식은 호출자가 정한다 | 인용 블록 둘째 문장 | 옮김 |
| 인용 블록 — 예: `domain-llm-runtime`의 런타임 리뷰 콜 | 인용 블록 둘째 문장 | 옮김 |
| 인용 블록 — 예: 문서 검진의 `reviewer-grounding`+`reviewer-fit` 넛지 | 인용 블록 둘째 문장 | 옮김 — 훅이 실제로 띄우는 그 짝을 그대로 남겼다 |
| 인용 블록 — 이 문서는 무엇을 보고 어떤 목록을 돌려주는가만 정의한다 | 인용 블록 셋째 문장 | 옮김 |
| `## 무엇을 보나` — 다른 코드·사용자·시스템이 소비할 때 형식·스키마·스타일·제약을 지키는가 | `## What it looks at` 첫 문장 | 옮김 — 소비 주체 셋을 그대로 나열했다 |
| `## 무엇을 보나` — 내용의 정확성은 보지 않는다(그건 `reviewer-grounding`의 몫) | `## What it looks at` 둘째 문장 | 옮김 |
| 체크리스트 — 요구된 형식·스키마(JSON 유효성, 필수 키, 타입) | `## Checklist` 첫 항목 | 옮김 |
| 체크리스트 — 길이·언어·톤·금지어 등 스타일·제약 | `## Checklist` 둘째 항목 | 옮김 |
| 체크리스트 — 다운스트림이 바로 파싱·사용 가능한가(여분 텍스트·마크다운 펜스 오염 없음) | `## Checklist` 셋째 항목 | 옮김 |
| 체크리스트 — 기존 출력 계약과 하위 호환되는가 | `## Checklist` 넷째 항목 | 옮김 |
| 인용 블록 — 가능하면 결정론적 검증을 먼저 돌린다(JSON 스키마 validator, 정규식) | 두 번째 인용 블록 | 옮김 |
| 인용 블록 — LLM 리뷰는 결정론으로 못 잡는 스타일·모호 제약에만 쓴다(비용 절약) | 두 번째 인용 블록 | 옮김 — 비용 절약이라는 근거까지 남겼다 |
| `## 레퍼런스 프롬프트 (언어 중립)` 제목 | `## Reference prompt (language-neutral)` | 옮김 |
| system 프롬프트 — 너는 적합성 검수자다 | system 프롬프트 | 옮김 |
| system 프롬프트 — 명시된 출력 계약(형식·스키마·스타일·제약)만 본다 | system 프롬프트 | 옮김 |
| system 프롬프트 — 내용 정확성은 보지 않는다 | system 프롬프트 | 옮김 |
| user 프롬프트 — `[출력 계약]{contract}` + `[후보]{candidate}` + 위반을 JSON 스키마로 | user 프롬프트 | 옮김 |
| `## 출력 스키마 (공통)` 제목 | `## Output schema (shared)` | 옮김 |
| JSON — `lens`·`issues`·`severity`·`type`·`where`·`detail`·`notes` 키 | 같은 JSON | 옮김 — **필드 이름을 바꾸지 않았다** |
| JSON — `severity` 값 `critical\|major\|minor` | 같은 JSON | 옮김 — 허용 값을 그대로 두었다 |
| JSON — `type` 값 `schema\|format\|style\|constraint\|compat` | 같은 JSON | 옮김 — 허용 값을 그대로 두었다 |
| (원문 없음) `where` 자리표시의 설명 문구 — 원문은 `"..."`라는 빈 자리표시였다 | `"location in the candidate"` | 신설 — 다른 셋과 같은 설명 문구로 채워 리뷰어가 무엇을 적어야 하는지 드러나게 했다(`EXPLICIT`) |
| (원문 없음) `detail` 자리표시의 설명 문구 — 원문은 `"..."`라는 빈 자리표시였다 | `"which contract clause is violated and how"` | 신설 — 위와 같은 이유다 |
| 꼬리 문장 — `severity` 하나가 신호다(verdict 없음 — `SSOT`) | 마지막 문단 | 옮김 |
| 꼬리 문장 — 라우팅(critical→regenerate/폴백 등)은 `meta-aggregate`를 따른다 | 마지막 문단 | 옮김 — 폴백까지 남겼다 |
