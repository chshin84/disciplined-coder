# 대응표 — `domain-plugin` · `meta-aggregate` · `domain-llm-runtime`

> **되돌린 작업의 기록이다(superseded).** 이 표는 정본과 스킬 문서를 영문으로 다시 쓰는 회차에서
> 만들었고, 그 재작성은 되돌려졌다 — 정본은 지금도 한국어다. 그래서 「새 문서 위치」 칸은 그때의
> 영문 문서를 가리키며 지금의 문서 구조가 아니다. 무엇을 왜 옮기고 지웠는지의 판단만 쓸모가 있어
> 남겨 두는 것이니, 지금 문서를 찾을 때 이 표를 따라가지 마라.

원문의 각 항목이 새 문서 어디로 갔는지, 지웠다면 왜 지웠는지 남긴다.
'지움' 항목과 빈칸이 사람이 검토할 대상이다.

세 번째 칸의 값은 `옮김`, `합침`, `**지움**`, `신설` 중 하나이며 지움에는 반드시 근거를 붙인다.
`신설`은 원문에 없던 것을 스펙이 요구해 새로 넣은 항목이라 왼쪽 칸이 `(원문 없음)`으로 시작한다.

**지움은 없다.** 세 파일 모두 원문의 모든 구성 요소가 새 문서에 살아 있다. 신설은 하나뿐이며
`domain-plugin`의 `description`에 담긴 내용 요약 문장이다. 합침은 `domain-llm-runtime`의 리스크 점수
다섯 행이고 다섯이 모두 같은 처리다 — 항목마다 붙어 있던 `+1` 표기를 앞의 규칙 한 문장으로 모았다.

**스키마 키와 허용 값, 그리고 명령·경로·URL 같은 식별자는 하나도 바꾸지 않았다**(정본의 절 이름 참조
하나만 예외이며 바로 아래 문단에 적었다). `meta-aggregate`의 출력 스키마 키(`decision`·`reason`·
`aggregated`·`severity`·`type`·`source`·`where`·`detail`·`retry_count`)와 허용 값
(`accept|regenerate|escalate`, `grounding|fit|consistency|adversarial`)이 재작성 전후로 동일하다.
`source`의 네 값은 리뷰어 렌즈 넷의 `lens` 값(`grounding`·`consistency`·`adversarial`·`fit`)과
실제로 대조해 일치를 확인했다. `domain-llm-runtime`의 원칙 ID 참조(`MEASURE-FIRST`·`SECRETS`)와
심각도 라벨(`critical`·`major`·`minor`)도 그대로다.

**절 참조 하나를 새 이름으로 바꿨다.** `domain-llm-runtime`이 참조하던 정본의 `절차 가`는
`Verification Layer`가 되었다.

## domain-plugin

| 원문 항목 | 새 문서 위치 | 처리와 근거 |
|---|---|---|
| frontmatter `name: domain-plugin` | frontmatter `name` | 옮김 — 스킬 식별자라 그대로 둔다 |
| description — 플러그인·마켓플레이스를 만들 때 참조하는 도메인 참고서다 | description 첫 문장 | 옮김 — 플러그인과 마켓플레이스 두 대상을 모두 남겼다 |
| description — 설계와 개발 단계에서 연다 | description 둘째 문장 | 옮김 — 두 단계를 모두 남겼다 |
| (원문 없음) 무엇이 들어 있는지의 요약 | description 셋째 문장 | 신설 — `description`은 스킬을 열지 말지 고를 때 읽히는 유일한 단서라, 항목 넷(버전 핀·`marketplace.json`·`validate`·컴포넌트 위치)을 나열해 열기 전에 내용이 드러나게 했다(`EXPLICIT`) |
| H1 `플러그인 관리 도메인 참고서` | H1 `domain-plugin — plugin management domain reference` | 옮김 — 제목의 내용은 그대로 옮기고 앞에 스킬 이름을 붙였다. 나머지 아홉 스킬이 모두 `# <스킬이름> — <설명>` 꼴인데 이 파일만 이름을 달지 않아, 검진에서 드러나 관례에 맞췄다 |
| `## 범위` — Claude Code 플러그인/마켓플레이스를 만들고 배포하는 방법을 다룬다 | `## Scope` | 옮김 — '만들고 배포한다'는 두 층위를 `build and ship`으로 모두 남겼다 |
| `## 항목` 제목 | `## Entries` | 옮김 |
| 버전 핀 — 활성 개발 중이면 `plugin.json`의 `version`을 비운다 | `## Entries` 첫 항목 | 옮김 — 굵게 강조한 `empty`도 유지했다 |
| 버전 핀 — 비워야 커밋 SHA 기반 자동 업데이트가 유지된다 | `## Entries` 첫 항목 | 옮김 — 처음엔 `keep tracking the commit SHA`라고만 적어 '커밋 SHA 기반'만 남고 '자동'이 빠졌다. 검진에서 드러나 `automatically`를 되살려 두 층위를 모두 담았다 |
| 버전 핀 — version을 설정하면 업데이트가 버전 문자열 비교로 전환된다 | `## Entries` 첫 항목 | 옮김 |
| 버전 핀 — 값을 올리지 않는 한 새 커밋이 사용자에게 배포되지 않는다 | `## Entries` 첫 항목 | 옮김 — 전환의 결과라는 인과를 `and from then on`으로 남겼다 |
| 버전 핀 — 공식 문서의 명시 권장이라는 근거와 링크 | `## Entries` 첫 항목 | 옮김 — URL과 앵커(`#version-management`)를 그대로 두었다 |
| 버전 핀 — `claude plugin validate`가 version 부재에 경고를 낸다 | `## Entries` 첫 항목 | 옮김 |
| 버전 핀 — 경고는 외관 문제이고 배포 단절이 실질 피해라 경고를 수용한다 | `## Entries` 첫 항목 끝 | 옮김 — 두 층위(경고의 성격, 그에 대비되는 실질 피해)와 그로부터 나온 결론을 모두 남겼다. 이 레포에서 실제로 겪은 트레이드오프라 일반론으로 희석하지 않았다 |
| `marketplace.json` — `.claude-plugin/marketplace.json`에 최상위 `name`·`description`·`owner`·`plugins[]`를 둔다 | `## Entries` 둘째 항목 | 옮김 — 경로와 키 넷을 그대로 나열했다 |
| `marketplace.json` — 레포 루트가 곧 플러그인이면 `source: "./"`로 가리킨다 | `## Entries` 둘째 항목 | 옮김 — 값 `"./"`를 그대로 두었다 |
| `validate` — `claude plugin validate ./`로 검증한다 | `## Entries` 셋째 항목 | 옮김 — 명령을 그대로 두었다 |
| `validate` — `--strict`는 경고까지 실패로 취급한다 | `## Entries` 셋째 항목 | 옮김 — '경고까지'의 강조를 `even warnings`로 남겼다 |
| `validate` — 버전 핀 정책을 쓰는 레포에서는 `--strict` 실패가 정상이다 | `## Entries` 셋째 항목 | 옮김 — "이 레포에 한정된 정상"이라는 조건절을 남겨 일반 권장으로 읽히지 않게 했다 |
| `validate` — non-strict로 통과를 확인한다 | `## Entries` 셋째 항목 끝 | 옮김 — 실패를 받아들이는 것으로 끝내지 않고 대신 무엇을 확인하는지까지 남겼다 |
| 컴포넌트 위치 — `agents/`·`skills/`·`commands/`·`hooks/hooks.json`에 둔다 | `## Entries` 넷째 항목 | 옮김 — 경로 넷을 그대로 나열했다 |
| 컴포넌트 위치 — 플러그인 루트의 `CLAUDE.md`는 컨텍스트로 로드되지 않는다 | `## Entries` 넷째 항목 | 옮김 — 이 레포에서 실측으로 확인된 함정이라 그대로 남겼다 |

## meta-aggregate

| 원문 항목 | 새 문서 위치 | 처리와 근거 |
|---|---|---|
| frontmatter `name: meta-aggregate` | frontmatter `name` | 옮김 |
| description — 리뷰어 둘 이상의 출력을 모은다 | description 첫 문장 | 옮김 — '둘 이상'이라는 조건을 그대로 남겼다 |
| description — 구조적 건강성(상충·공백)을 점검한다 | description 첫 문장 | 옮김 — 괄호 안의 두 항목(리뷰어 간 상충, 커버리지 공백)을 모두 풀어 적었다. 처음엔 `checks its structural health`라 대명사가 출력을 가리키는지 리뷰어를 가리키는지 갈렸는데, 검진에서 드러나 `the structural health of that output`으로 지시 대상을 명시했다 |
| description — accept/regenerate/escalate를 결정한다 | description 첫 문장 끝 | 옮김 — 세 값을 그대로 나열했다 |
| description — 집계 단계다 | description 첫 문장 첫머리 | 옮김 |
| description — 리뷰어가 아니다(렌즈 아님) | description 둘째 문장 | 옮김 — 이 스킬의 존재 이유라 두 부정(리뷰어도 아니고 렌즈도 아니다)을 모두 남겼다 |
| description — 코드 설계도다 | description 셋째 문장 | 옮김 |
| description — 내용 재판단은 하지 않는다 | description 셋째 문장 | 옮김 — `never`로 예외 없음을 남겼다. 처음엔 `the content of an issue`라고 적어 원문에 없는 범위 한정이 붙었는데, 검진에서 드러나 한정을 걷어내 본문의 넓은 금지와 맞췄다 |
| H1 `meta-aggregate — 집계·결정 (코드 설계도)` | H1 `meta-aggregate — aggregation and decision (code blueprint)` | 옮김 — '집계'와 '결정' 두 층위를 모두 남겼다 |
| 인용 블록 — 이것은 리뷰어가 아니다(렌즈가 아니다) | 인용 블록 첫 문장 | 옮김 — 굵은 강조를 유지했다 |
| 인용 블록 — 리뷰어들이 끝난 뒤 결과를 모아 다음 행동을 정하는 단계다 | 인용 블록 첫 문장 | 옮김 — 시점(리뷰어 이후)과 하는 일(모아서 다음 행동 결정)을 모두 남겼다 |
| 인용 블록 — 프롬프트가 아니라 코드 설계도다 | 인용 블록 둘째 문장 | 옮김 — 대비되는 두 항을 모두 남겼다 |
| 인용 블록 — 결정론적 코드로 구현한다 | 인용 블록 둘째 문장 끝 | 옮김 |
| `## 판단 재귀 회피 (핵심 제약)` 제목 | `## Avoiding judgment recursion (the core constraint)` | 옮김 — '핵심 제약'이라는 격도 남겼다 |
| 본문 — 리뷰어 출력의 구조만 본다 | `## Avoiding judgment recursion` 첫 문장 | 옮김 — `only`와 굵은 `structure`로 한정을 남겼다 |
| 본문 — 내용 재판단을 하지 않는다 | `## Avoiding judgment recursion` 둘째 문장 | 옮김 — 금지 둘 중 첫째다 |
| 본문 — 가중치 부여를 하지 않는다 | `## Avoiding judgment recursion` 둘째 문장 | 옮김 — 금지 둘 중 둘째다. 원문이 '재판단이나 가중치'라는 두 층위였으므로 한쪽으로 합치지 않았다 |
| 본문 — "어느 리뷰어가 옳다" 같은 | `## Avoiding judgment recursion` 둘째 문장 끝 | 옮김 — 예시절로 남겼다 |
| 본문 — 재귀의 끝은 사람이다 | `## Avoiding judgment recursion` 셋째 문장 | 옮김 |
| `## 하는 일` 제목 | `## What it does` | 옮김 |
| 집계 — 모든 리뷰어의 이슈를 한 목록으로 모은다 | `## What it does` 첫 항목 | 옮김 |
| 집계 — 출처를 태깅한다 | `## What it does` 첫 항목 | 옮김 |
| 집계 — 심각도순으로 정렬한다 | `## What it does` 첫 항목 | 옮김 |
| 집계 — (기계적) | `## What it does` 첫 항목 끝 | 옮김 — 판단이 아니라 기계적 작업이라는 단서라 별도 문장으로 남겼다 |
| 상충 감지 — 같은 지점에 상반된 판정이 있으면 | `## What it does` 둘째 항목 | 옮김 — '같은 지점'과 '상반됨' 두 조건을 모두 남겼다 |
| 상충 감지 — escalate 후보로 표시한다 | `## What it does` 둘째 항목 | 옮김 — 표시일 뿐 결정이 아니라는 뉘앙스를 `mark as a candidate`로 남겼다 |
| 커버리지 공백 — 리스크상 필요한 차원을 아무도 안 봤으면 | `## What it does` 셋째 항목 | 옮김 |
| 커버리지 공백 — 누락 리뷰어 추가를 권한다 | `## What it does` 셋째 항목 | 옮김 — 강제가 아니라 권고라 `recommend`로 남겼다 |
| `## 결정 정책 (기본)` 제목 | `## Decision policy (default)` | 옮김 — '기본'이라는 단서를 남겨 다른 정책이 가능함을 열어 두었다 |
| 정책 — critical이 하나라도 있으면 regenerate | `## Decision policy` 첫 항목 | 옮김 — '하나라도'를 `Even one`으로 남겼다 |
| 정책 — 1차를 이슈와 함께 재호출한다 | `## Decision policy` 첫 항목 | 옮김 — regenerate가 무엇인지의 정의라 남겼다 |
| 정책 — 재시도 상한에 도달하면 escalate | `## Decision policy` 첫 항목 끝 | 옮김 |
| 정책 — 상충이나 공백이 있으면 escalate(사람) | `## Decision policy` 둘째 항목 | 옮김 — 두 트리거(상충, 공백)와 escalate의 대상이 사람이라는 것을 모두 남겼다 |
| 정책 — 또는 누락 차원 보강 후 재집계 | `## Decision policy` 둘째 항목 | 옮김 — 원문이 'A 또는 B'라 둘째 선택지를 지우지 않았다 |
| 정책 — critical 0이고 상충 없으면 accept | `## Decision policy` 셋째 항목 | 옮김 — 두 조건을 모두 남겼다 |
| 정책 — major·minor는 로깅한다 | `## Decision policy` 셋째 항목 끝 | 옮김 |
| `## 출력 스키마` 제목 | `## Output schema` | 옮김 |
| JSON — `decision`·`reason`·`aggregated`·`retry_count` 키 | 같은 JSON | 옮김 — **필드 이름을 바꾸지 않았다** |
| JSON — `aggregated` 원소의 `severity`·`type`·`source`·`where`·`detail` 키 | 같은 JSON | 옮김 — **필드 이름을 바꾸지 않았다** |
| JSON — `decision` 값 `accept\|regenerate\|escalate` | 같은 JSON | 옮김 — 허용 값을 그대로 두었다 |
| JSON — `source` 값 `grounding\|fit\|consistency\|adversarial` | 같은 JSON | 옮김 — 리뷰어 렌즈 넷의 `lens` 값과 실제로 대조해 일치를 확인했다 |
| JSON — `"..."` 빈 자리표시들 | 같은 JSON | 옮김 — 원문 그대로 두었다. 리뷰어 스킬과 달리 이 스키마엔 설명 문구가 없었고, 채우는 것은 재작성 범위 밖이다 |
| `## 구현 형태 (맥락 의존)` 제목 | `## How it is implemented (depends on the context)` | 옮김 — '맥락 의존'이라는 단서를 남겼다 |
| 제품 런타임(`domain-llm-runtime`)은 결정론적 파이썬 함수로 구현한다 | `## How it is implemented` 첫 항목 | 옮김 — 호출자 이름과 구현 형태를 모두 남겼다 |
| 집계와 계수는 결정론이라 모델이 필요 없다 | `## How it is implemented` 첫 항목 | 옮김 — '집계'와 '계수' 두 작업을 모두 남겼다 |
| 모호한 상충 판정만 선택적으로 LLM을 쓴다 | `## How it is implemented` 첫 항목 끝 | 옮김 — 두 한정(모호한 상충에 한해서, 그마저도 선택적으로)을 모두 남겼다 |
| spec/plan 리뷰(`domain-spec-review`)는 제품 코드가 없다 | `## How it is implemented` 둘째 항목 | 옮김 — 뒤 처방의 근거라 남겼다 |
| 메인 세션이 이 좁은 절차를 따라 직접 집계한다 | `## How it is implemented` 둘째 항목 | 옮김 — 주체(메인 세션)와 '좁은 절차'라는 한정을 모두 남겼다 |
| 단순한 일이라 스크립트를 따로 싣지 않는다 | `## How it is implemented` 둘째 항목 | 옮김 |
| 플러그인 훅의 순수 bash·무의존 이식성을 유지한다 | `## How it is implemented` 둘째 항목 끝 | 옮김 — 스크립트를 싣지 않는 이유이고 두 성질(순수 bash, 무의존)이 모두 이식성으로 이어지므로 셋 다 남겼다 |
| 어느 쪽이든 regenerate 루프에 상한을 둔다 | `## How it is implemented` 셋째 항목 | 옮김 — '어느 쪽이든'이라는 범위도 남겼다 |
| 상한 예시 `1~2회` | `## How it is implemented` 셋째 항목 | 옮김 — 예시임을 `say`로 드러냈다 |
| 상한의 이유 — 무한 루프·비용 폭주를 막는다 | `## How it is implemented` 셋째 항목 끝 | 옮김 — 막으려는 두 사고(무한 루프, 비용 폭주)를 모두 남겼다 |

## domain-llm-runtime

| 원문 항목 | 새 문서 위치 | 처리와 근거 |
|---|---|---|
| frontmatter `name: domain-llm-runtime` | frontmatter `name` | 옮김 |
| description — 제품이 런타임에 LLM을 호출하는 기능을 만들 때의 검증 호출자 | description 첫 문장 | 옮김 — '런타임'과 '호출자'라는 두 한정을 모두 남겼다 |
| description — 단독 콜로 끝내지 말라 | description 둘째 문장 | 옮김 |
| description — 리스크에 비례해 리뷰어(`reviewer-*`)를 고른다 | description 둘째 문장 | 옮김 — 비례 조건을 남겼다 |
| description — 제품 코드의 리뷰 콜로 구현한다 | description 둘째 문장 | 옮김 — Claude Code 에이전트가 아니라 제품 코드라는 자리를 남겼다 |
| description — 비기능 체크리스트는 항상 적용한다 | description 둘째 문장 끝 | 옮김 — '항상'을 `every time`으로 남겨 리스크 비례의 예외임을 유지했다 |
| description — 리뷰어 렌즈와 `meta-aggregate`는 별도 스킬 참조 | description 셋째 문장 | 옮김 — 두 참조 대상을 모두 남겼다. 처음엔 `live in their own skills`라는 사실 진술이라 '가서 보라'는 지시가 사라졌는데, 검진에서 드러나 `see their own skills`로 지시를 되살렸다 |
| H1 `domain-llm-runtime — 런타임 LLM 검증 호출자` | H1 `domain-llm-runtime — runtime LLM verification caller` | 옮김 |
| 도입 — 런타임에 LLM을 호출하는 기능은 단독 콜로 끝내지 않는다 | 도입 첫 문장 | 옮김 |
| 도입 — 검증 레이어를 코드에 구현한다 | 도입 둘째 문장 | 옮김 |
| 도입 — 리뷰어는 Claude Code 에이전트가 아니라 제품 코드가 구현할 청사진이다 | 도입 셋째 문장 | 옮김 — 부정과 긍정 두 항을 모두 남겼다. 이 스킬에서 가장 오해받기 쉬운 구분이다 |
| 도입 — 공통 방법은 PREP → 독립 렌즈 → 메타 집계 → 라우팅이다 | 도입 넷째 문장 | 옮김 — 네 단계를 순서대로 남겼고, 화살표는 `CLEAR-COMM`에 따라 문장으로 풀었다 |
| 도입 — `agent-principles.md` "절차 가"를 따른다 | 도입 넷째 문장 끝 | 옮김 — 정본의 새 절 이름 `Verification Layer`로 바꿨다 |
| `## 리뷰어 선택 (리스크 비례)` 제목 | `## Choosing reviewers (in proportion to the risk)` | 옮김 |
| 리스크 점수 — 외부 호출 +1 | `## Choosing reviewers` 산문 | 합침 — 다섯 항목에 각각 붙어 있던 `+1` 표기를 "각 항목마다 1점"이라는 규칙 한 문장으로 앞에 모았다. 항목 자체는 다섯 다 남아 있으므로 잃은 것은 없고, 처음엔 이 행을 `옮김`으로 적었다가 검진에서 실제 처리가 합침임이 드러나 라벨을 고쳤다 |
| 리스크 점수 — LLM 컴포넌트 +1 | `## Choosing reviewers` 산문 | 합침 — 위 행과 같은 처리다 |
| 리스크 점수 — 인터페이스 계약 변경 +1 | `## Choosing reviewers` 산문 | 합침 — 위 행과 같은 처리다 |
| 리스크 점수 — HITL·컴플라이언스 +1 | `## Choosing reviewers` 산문 | 합침 — 위 행과 같은 처리이며, 둘 중 어느 쪽이든 걸리면 점수가 붙으므로 두 항목을 모두 남겼다. 처음엔 원문에 없는 `touchpoint`라는 머리명사를 붙였는데, 검진에서 드러나 빼고 두 이름만 남겼다 |
| 리스크 점수 — 명세 3섹션+ +1 | `## Choosing reviewers` 산문 | 합침 — 위 행과 같은 처리이며, '3섹션 이상'이라는 경계를 그대로 남겼다 |
| 표 머리 `점수`·`리뷰어`·`메타` | 표 머리 `Score`·`Reviewers`·`Meta` | 옮김 — 세 칸을 그대로 두었다 |
| 표 행 `0–1` — 없음(비기능 체크리스트만) / 메타 불필요 | 같은 표 행 | 옮김 — 리뷰어는 없지만 체크리스트는 남는다는 단서를 살렸다. 처음엔 `None, the non-functional checklist alone`이라는 조각이라 검진에서 드러났고, 완결된 절로 고쳐 썼다 |
| 표 행 `2–3` — `reviewer-grounding` / 단일 리뷰어면 메타 불필요 | 같은 표 행 | 옮김 — 불필요의 조건(단일 리뷰어)도 남겼다 |
| 표 행 `4–5` — `reviewer-grounding` + `reviewer-fit` / `meta-aggregate` 필요(리뷰어 2개 이상) | 같은 표 행 | 옮김 — 필요의 근거(리뷰어 둘 이상)도 남겼다 |
| 불릿 — `reviewer-grounding`의 "출처"는 여기서 원래 요청과 제공된 맥락이다 | `## Choosing reviewers` 첫 불릿 | 옮김 — '여기서'라는 맥락 한정과 출처 두 항목을 모두 남겼다 |
| 불릿 — `reviewer-fit`는 다운스트림 계약을 본다 | `## Choosing reviewers` 둘째 불릿 | 옮김 |
| 불릿 — 스키마·형식은 코드 validator를 먼저 돌린다 | `## Choosing reviewers` 둘째 불릿 | 옮김 — 대상 둘(스키마, 형식)과 순서를 남겼다 |
| 불릿 — 실패 시에만 리뷰 콜(비용 절약) | `## Choosing reviewers` 둘째 불릿 끝 | 옮김 — 조건과 그 이유를 모두 남겼다 |
| 불릿 — `meta-aggregate`는 여기서 결정론적 파이썬 함수다(LLM 콜 아님) | `## Choosing reviewers` 셋째 불릿 | 옮김 — 긍정과 부정 두 항을 모두 남겼다 |
| `## 조립` 제목 | `## Assembly` | 옮김 |
| 조립 — 1차 콜을 받은 뒤 리스크에 따라 리뷰 콜을 병렬로 돌린다 | `## Assembly` 첫 문장 | 옮김 — 시점·조건·병렬 셋을 모두 남겼다 |
| 조립 — `meta-aggregate`가 집계해 accept/regenerate/escalate를 결정한다 | `## Assembly` 첫 문장 끝 | 옮김 |
| 조립 — 비기능 체크리스트는 단계가 아니다 | `## Assembly` 둘째 문장 | 옮김 — 부정을 먼저 남겼다 |
| 조립 — 호출 코드 전체가 항상 만족해야 할 속성으로 바깥을 감싼다 | `## Assembly` 둘째 문장 | 옮김 — '전체'·'항상'·'바깥을 감싼다'를 모두 남겼다 |
| `## 비기능 체크리스트 (런타임 전용 — 코드 설계도)` 제목 | `## Non-functional checklist (runtime only — a code blueprint)` | 옮김 — 두 단서(런타임 전용, 코드 설계도)를 모두 남겼다 |
| 머리말 — 리뷰어가 아니고 LLM 콜도 아니다 | `## Non-functional checklist` 첫 문장 | 옮김 — 두 부정을 모두 남겼다 |
| 머리말 — 호출 코드가 갖춰야 할 요건이다 | `## Non-functional checklist` 둘째 문장 | 옮김 |
| 머리말 — 구현 시 코드 가드와 그것을 검증하는 테스트로 확정한다 | `## Non-functional checklist` 둘째 문장 끝 | 옮김 — 가드와 그 가드를 검증하는 테스트라는 두 층위를 모두 남겼다 |
| 머리말 — 결정론적이라 정적 점검·테스트로 검증한다 | `## Non-functional checklist` 셋째 문장 | 옮김 — 근거(결정론)와 수단 둘(정적 점검, 테스트)을 모두 남겼다 |
| 체크 — 외부 호출 timeout, 없으면 무한 대기 (critical) | 첫 항목 | 옮김 — 심각도 라벨을 그대로 두었다 |
| 체크 — retry 정책, 일시 실패·레이트리밋 대비 지수 백오프 (major) | 둘째 항목 | 옮김 — 대비 대상 둘을 모두 남겼다. 원문이 명사로 끝나 영문도 조각이 됐는데, 검진에서 드러나 `retry with exponential backoff`라는 완결된 절로 고쳤다(`CLEAR-COMM`) |
| 체크 — 빈/실패 응답 None 가드 (major) | 셋째 항목 | 옮김 — 제목의 두 경우(빈 응답, 실패 응답)를 모두 남겼다 |
| 체크 — 실제 SDK는 빈 결과에 None을 반환할 수 있다 | 셋째 항목 | 옮김 — 이 함정의 근거라 남겼다 |
| 체크 — `x or {}` 가드로 AttributeError를 막는다 | 셋째 항목 끝 | 옮김 — 구체 가드 표현을 그대로 두었다 |
| 체크 — 에러 응답 형식, 호출자가 처리할 수 있는 구조화된 에러 (major) | 넷째 항목 | 옮김 — 위 항목과 같은 이유로 `return a structured error`라는 완결된 절로 고쳤다 |
| 체크 — 비용·토큰 상한, 입력·출력 토큰 한도와 재시도 횟수 상한 (major) | 다섯째 항목 | 옮김 — 한도 대상 셋(입력 토큰, 출력 토큰, 재시도 횟수)을 모두 남겼고, 위 항목과 같은 이유로 `cap ...`이라는 완결된 절로 고쳤다 |
| 체크 — 관측, 요청·지연·토큰·실패율 로깅 (`MEASURE-FIRST`) (minor~major) | 여섯째 항목 | 옮김 — 로깅 대상 넷과 원칙 ID, 심각도 범위를 모두 남겼다 |
| 체크 — HITL 게이트, 비가역·고위험 액션은 사람 승인 | 일곱째 항목 | 옮김 — 대상 둘(비가역, 고위험)을 모두 남겼다 |
| 체크 — 컴플라이언스 접점이면 (critical), 아니면 정책에 따름 | 일곱째 항목 끝 | 옮김 — 조건부 심각도라 두 갈래를 모두 남겼다 |
| 체크 — 민감정보, 프롬프트·로그에 비밀·PII 노출 금지 (`SECRETS`) | 여덟째 항목 | 옮김 — 금지 대상 둘(비밀, PII)과 노출 자리 둘(프롬프트, 로그)을 모두 남겼다 |
| 꼬리 — 누락 항목은 severity대로 처리한다 | `## Non-functional checklist` 마지막 문장 | 옮김 |
| 꼬리 — critical은 머지·배포 차단이다 | `## Non-functional checklist` 마지막 문장 끝 | 옮김 — 차단 대상 둘(머지, 배포)을 모두 남겼다 |
| `## 비용` 제목 | `## Cost` | 옮김 |
| 비용 — 리뷰 콜은 추가 비용·지연이다 | `## Cost` 첫 문장 | 옮김 — 대가 둘(비용, 지연)을 모두 남겼다 |
| 비용 — 리스크에 비례해서만 더한다 | `## Cost` 둘째 문장 | 옮김 — `only`로 한정을 남겼다 |
| 비용 — 결정론으로 검증 가능한 것(스키마·정규식)은 코드로 먼저 | `## Cost` 셋째 문장 | 옮김 — 예시 둘을 그대로 남겼다 |
| 비용 — critical만 regenerate를 강제한다 | `## Cost` 넷째 문장 | 옮김 — `Only critical`로 한정을 남겼다 |
