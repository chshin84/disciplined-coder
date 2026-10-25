# 렌즈 에이전트 전환 설계

이 spec 은 렌즈를 스킬에서 플러그인 에이전트 정의로 옮기고 렌즈 관련 중복 구조를 합치는 설계다. 판정 기준·실측·시나리오는 조사 기록 `docs/superpowers/decisions/2026-10-25-lens-agent-restructure-research.md` 에 있다.

사용자는 2026-10-25 그 기록의 시나리오 S3 에 주장 반박 에이전트 하나를 추가하는 안을 골랐다. S3 은 렌즈를 에이전트 정의로 옮기되 대상에 따라 도구나 출력 계약이 다를 때만 에이전트를 나누는 안이고, 구조 통합·fit 문체 기계화·다시 리뷰 범위 제한을 함께 한다. 리뷰 기록은 `docs/superpowers/reviews/2026-10-25-lens-agent-restructure-review.md` 에 있다.

## 목적

목적은 작업당 사용자 비용(토큰·시간·에너지)을 줄이면서 반영되는 리뷰 지적을 잃지 않는 일이다. 메모리의 최우선 목표(2026-10-24)와 사용자의 2026-10-25 지시가 근거다.

현행 렌즈는 스킬(`skills/lens-*/SKILL.md`)이다. 리뷰 호출자는 그 스킬을 읽은 뒤 「레퍼런스 프롬프트」를 general-purpose 서브에이전트에 다시 쓴다. 그래서 같은 글이 메인 맥락에 두 번 들어간다. `review-specs` 는 쓰기 도구가 없는 에이전트 종류가 있으면 그것으로 실행하게 하지만, 실제 리뷰 기록의 렌즈 실행은 대부분 general-purpose 로 하고 읽기 전용을 프롬프트로 지시했다.

사용자는 주장 반박, 외부 비교, 렌더링 화면 리뷰를 직접 요청한 적이 있다. 현행 렌즈 중에는 그 요청을 맡을 렌즈가 없다.

## 목표와 비목표

목표는 다음과 같다.

- **에이전트 전환:** 렌즈를 `agents/lens-*.md` 로 옮겨 도구·모델을 정의 파일로 강제한다.
- **1:N 분리:** 대상에 따라 도구나 출력 계약이 다를 때만 에이전트를 나누고, 입력만 다르면 한 에이전트 안의 모드로 둔다.
- **주장 반박 에이전트:** 주장·제안서를 외부 근거로 반박하는 에이전트를 추가한다.
- **readability 재정의:** readability 를 렌더링 화면 리뷰 에이전트로 다시 만들고, 글 검토는 review-docs 퇴고 단계로 옮긴다.
- **구조 통합:** 호출자×렌즈 정의, 리뷰 기록 규칙, 출력 계약의 중복을 출처 하나로 모은다.
- **fit 문체 기계화:** fit 문체 검사 중 오탐 없이 결정론으로 답할 수 있는 항목을 기계 검사로 옮긴다.
- **다시 리뷰 정책:** 원칙 경량화 세션 병합 뒤 `NO-RAW-OUTPUT` 변경안을 클린룸 시험한다.
- **레포 문서 감사 삭제:** `audit-repo-docs` 스킬과 감사 전용 스크립트를 지운다.

레포 문서 감사의 삭제는 사용자가 2026-10-25 정했다. 사용자는 "맥락없이 자가 감사해줘는 접근이 잘못됐다"고 판단했다. 이 결정으로 렌즈 여럿을 한 호출에 묶는 예외(대상 문서 여섯 개 이상)도 쓰는 호출자가 없어지므로 함께 지운다.

비목표는 다음과 같다.

- **렌즈 통합:** 두 렌즈의 단독 반영률이 모두 89% 이므로 adversarial 과 consistency 를 따로 둔다(조사 기록 「실측」).
- **grounding·fit 통합:** 사용자가 2026-10-05 분리 유지로 정했다.
- **선행연구 스킬:** 선행연구 개선 세션이 2026-10-25 main f635c00 에서 고친 `researching-prior-art` 와 그 정의(`researcher`·`citation-verifier`·`citation-judge`·`map-check`)는 그대로 둔다.
- **기존 판정 축의 개선:** 현행 렌즈의 체크리스트 축과 판정 기준은 뜻을 유지한 채 옮긴다.
- **.pptx 렌더링:** PDF 변환 경로가 따로 필요하므로 렌더링 리뷰의 대상에서 .pptx 를 뺀다(내 판단).

새 모드와 새 에이전트(`artifact` 모드, `lens-adversarial-claim`, 렌더링 리뷰)의 체크리스트는 기존 판정 축의 개선에 들지 않는다. 구현자는 그 체크리스트를 아래 「새 체크리스트」의 축으로 새로 쓴다. 렌더링 리뷰의 대상은 HTML 과 HTML 슬라이드다.

이 개편이 실패하는 조건은 리뷰 한 차수의 토큰이나 대기 시간이 현행보다 느는 상황과, 반영되는 설계 지적이 현행보다 주는 상황이다.

## 제약

아래 제약은 사용자가 이미 정한 값이다. 구현자는 이 값을 그대로 따르라.

| 제약 | 출처 |
|---|---|
| 렌즈는 사용자가 요청하거나 리뷰 절차가 요구할 때만 실행한다 | 2026-09-25 사용자 지시(quant-structure 세션), 메모리 |
| 렌즈 그룹 3분류(문서 단위·묶음 전체·필요할 때)를 유지하고, adversarial 은 다른 렌즈와 한 호출에 넣지 않는다 | 2026-10-03 `docs/superpowers/specs/2026-10-03-lens-groups-design.md` |
| 렌즈 선택은 `dispatching-lenses` 가 소유한다 | 2026-10-12 사용자 지시(이 저장소 세션 기록) |
| 리뷰 모델은 Opus 다 | 2026-10-17 사용자 지시, 메모리 |
| 사용자는 렌즈를 이름으로 직접 실행할 수 있어야 한다 | 2026-10-25 사용자 발언(원칙 경량화 세션) |
| 스킬은 다른 스킬을 실행하지 않고 문서를 Read 한다. 훅은 감지, 스킬은 절차, 스크립트는 실행을 맡는다 | 2026-10-24·25 사용자 지시(원칙 경량화 세션) |
| 렌즈 에이전트 이름은 `lens-` 로 시작한다 | 원칙 `LENS-ALLOWED` 가 `lens-*` 호출만 상시 허용한다 |
| 런타임 청사진은 에이전트 정의 본문이 겸한다 | 2026-10-25 사용자 결정 |
| `kofia.or.kr` 와 그 아래 주소에 접속하지 않는다 | 사용자 전역 지침(`~/.claude/kw-ax/claude-md-ko.md`) |
| 원칙 문구 변경은 조항별 클린룸 시험을 거친다 | 저장소 CLAUDE.md 「조항 추가와 문구 변경」 |

## 에이전트 구성

분리 규칙을 현행 렌즈에 적용하면 적대 렌즈만 둘로 나뉜다. 주장 반박에는 WebSearch 가 필요하지만 설계 문서와 코드는 같은 도구(Read·Grep)를 쓰기 때문이다.

| 에이전트 | 대상과 모드 | tools | 그룹 | 실행하는 호출자 |
|---|---|---|---|---|
| `lens-adversarial` | `design`(spec·plan), `artifact`(코드·실험 결과·테스트 출력) | Read, Grep, Glob | 묶음 전체 | `design` 은 review-specs, `artifact` 는 사용자 직접 요청 |
| `lens-adversarial-claim` | 주장·제안서·보고서의 논증 | Read, WebSearch, WebFetch | 필요할 때 | 사용자 직접 요청, review-docs 가 제안서·보고서를 검진할 때 제안하고 승인받는다 |
| `lens-consistency` | spec·plan(감사 모드는 감사 삭제와 함께 지운다) | Read, Grep, Glob | 묶음 전체 | review-specs |
| `lens-grounding` | `runtime`, `spec`, `doc` | Read, Grep, Glob | 문서 단위 | 모든 호출자 |
| `lens-fit` | 대상 타입을 렌즈 안에서 판정한다(현행 `lens-fit:18-20`) | Read, Grep, Glob | 문서 단위 | 모든 호출자 |
| `lens-readability` | 렌더링된 HTML·HTML 슬라이드 화면 | Read 와 브라우저 도구(런타임 시험 결과에 따른다) | 필요할 때 | review-docs 가 HTML 산출물을 검진할 때 제안하고 승인받는다 |

정의마다 frontmatter 에 `name`, `description`, `tools`, `model` 을 적어라. `model` 은 `opus` 로 적어라(내 판단). 공식 문서(code.claude.com/docs/en/sub-agents 「Model selection」)는 패밀리 별칭이 메인 대화와 같은 패밀리이면 그 정확한 모델로 해석된다고 적는다. tools 에는 Agent 도구와 쓰기 도구를 빼고 표의 도구만 적어라.

에이전트 호출 정책은 "사전 정의 호출만 허용"이다. 에이전트 호출은 스킬 절차나 워크플로 스크립트에 이름으로 적힌 호출만 허용하고, 실행 중인 에이전트가 임의로 다른 에이전트를 실행하는 호출은 금지한다. 서브에이전트 안에서는 실행할 종류를 제한할 수 없으므로, 그 장치로 플러그인의 모든 에이전트 정의는 Agent 없는 tools 를 둔다. 판단 근거와 기각한 안은 결정 기록 `docs/superpowers/decisions/2026-10-25-agent-call-policy.md` 에 있다. 구현자는 다음을 하라.

- `scripts/test_lens_contract.sh` 에 호출 정책 검사를 넣어라. `agents/` 아래 모든 정의의 frontmatter 에 한 줄 쉼표 목록 형식의 `tools:` 줄이 있는지, 그 목록에 `Agent`·`Agent(...)`·`Task` 가 없는지, `workflows/` 아래 스크립트의 `agent()` 호출이 모두 `agentType` 을 주는지 확인하게 하라.
- `skills/domain-plugin/SKILL.md` 에 규칙을 적어라. 플러그인 에이전트 정의는 Agent 없는 tools 를 두고, 플러그인 스킬이 서브에이전트를 실행할 때는 플러그인 정의나 Explore 처럼 Agent 없는 종류를 쓰라는 내용이다. 다른 에이전트를 불러야 하는 정의가 필요해지면 검사 예외로 대신하지 말고 진행을 멈춰 선언 방식을 사용자에게 물으라는 멈춤 조건도 적어라.

`maxTurns` 와 `effort` 는 근거가 없으므로 런타임 시험에서 측정한 뒤 정하라. 조사 기록의 실측에 따르면 렌즈 1회 도구 호출 수는 중앙값 8~18, 최댓값 14~48 이었다. 그러나 도구 호출 수와 턴 수의 관계는 측정한 적이 없다.

description 에는 렌즈가 하는 일과 "실행하는 쪽은 먼저 `dispatching-lenses` 를 Read 한다" 를 적어라. 이 문장은 MODE·PRINCIPLES 줄을 채우는 방법을 알리는 입력 안내다. 사용 제한 문장은 두지 마라. 사용자가 2026-10-25 agents/ 정의를 범용 도구로 두고 사용 제한 문장을 두지 않기로 정했다(선행연구 세션 결정, main f635c00).

정의 본문에는 현행 렌즈 SKILL.md 의 모든 절을 옮겨라. 「기계에 넘기는 것」만 예외다. 이 절은 호출자가 실행 전에 할 일이므로 `dispatching-lenses` 의 대상별 에이전트 표에 열로 옮겨라.

## 새 체크리스트

`lens-adversarial` 의 `artifact` 모드는 설계 모드의 축(실패 모드·과설계·비가역·위험)을 그대로 쓴다. 다만 지적 위치를 문서의 줄과 절 대신 코드의 파일:줄이나 실험 결과의 항목으로 적게 하라. 입력에는 실험 데이터나 테스트 출력 경로를 받게 하라.

`lens-adversarial-claim` 의 축은 `counter-evidence`(반대 근거), `weak-premise`(약한 전제), `alternative-explanation`(다른 설명), `missing-comparison`(빠진 비교 대상)이다. 가드에는 다음 규칙을 적어라.

- **출처 없는 반박:** 외부 출처가 없는 반박은 지적으로 올리지 말고 `notes` 에 적어라.
- **접속 금지:** `kofia.or.kr` 와 그 아래 주소에 접속하지 마라.
- **검색어:** 검색어에 대상 문서의 문장이나 수치를 그대로 넣지 말고 일반화한 개념어로 써라.

`lens-adversarial-claim` 의 인용은 사용자에게 보이기 전에 메인 세션이 확인한다(사용자 결정 2026-10-25). 메인 세션은 지적마다 `counterpart_file` 의 URL 을 WebFetch 로 열어 `counterpart` 구절이 원문에 있는지 확인하라. 구절이 없거나 원문을 열 수 없는 지적은 사용자에게 보이지 말고 리뷰 기록에 "인용 확인 실패"로 적어라. 구절이 반박을 받치는지는 사용자가 판단한다.

선행연구의 추출 검증자·판정 에이전트를 재사용하는 안은 검토 뒤 보류했다. 검증자 본문 두 곳(입력 주장의 정의, 사례 일치 판정)과 워크플로의 합치기 순서를 함께 고쳐야 했고, 메인 세션이 에이전트 세 개를 이어 부르는 복잡도가 생기기 때문이다. 5단계 측정에서 인용 확인 실패가 많으면 그때 다시 검토한다.

`lens-readability`(렌더링 리뷰)는 현행 「관찰 목록」의 시각 항목과 「목적 주입」을 유지한다. 지적마다 화면 위치(페이지·슬라이드 번호와 요소)를 적게 하라. 고쳐 쓴 문장(`rewrite`)은 내지 않는다. 글 검토는 아래 「readability 글 검토의 이전」이 맡는다.

## 실행 경로

호출자는 `dispatching-lenses` 의 대상별 에이전트 표에서 에이전트와 모드를 고르고 Agent 도구로 실행한다. `subagent_type` 은 `disciplined-coder:<에이전트 이름>` 이다. 플러그인 에이전트 이름의 해석은 2026-10-18 워크플로 `agentType` 경로에서만 확인했다(`docs/superpowers/specs/2026-10-18-prior-art-agent-design.md` 「런타임 확인」). Agent 도구 경로는 런타임 시험에서 확인하라.

프롬프트의 첫 줄은 `MODE: <모드>`, 둘째 줄은 `PRINCIPLES: <principles_path>` 이고, 셋째 줄부터 대상 문서 경로와 배경을 둔다. 모드가 하나인 에이전트에도 첫 줄을 넣어라.

`principles_path` 는 `dispatching-lenses` 「렌즈에게 에이전트원칙을 알리는 법」대로 도출하라. 선행연구 개선 세션이 이 절 제목을 참조하므로 제목을 유지하라.

사용자는 `@agent-disciplined-coder:<에이전트 이름>` 이나 자연어 요청으로 렌즈를 직접 실행한다. 이때 메인 세션은 description 의 지시대로 `dispatching-lenses` 를 읽고 MODE·PRINCIPLES 줄을 채운다. 정의 본문에는 그 두 줄이 없을 때의 동작도 적어라. MODE 가 없으면 에이전트가 대상에서 모드를 정해 `notes` 에 적는다. PRINCIPLES 가 없으면 `principles_applied` 를 비우고 그 사실을 `notes` 에 적는다. 스킬 슬래시 명령(`/disciplined-coder:lens-*`)은 사라진다.

## 출력 계약

렌즈 출력 스키마의 출처는 새 계약 파일 `scripts/lens_contract.json` 이다. 지금은 `aggregating-lenses` 「리뷰 산출물 계약」과 렌즈 SKILL.md 의 스키마 사본이 이 구실을 나눠 맡는다. 계약 파일에는 공통 칸, 에이전트별 `type` 값, 에이전트별 추가 칸을 적어라. 형식은 `scripts/prior_art_contract.json` 을 따르라.

에이전트 정의 본문에는 출력 예시 블록 하나를 두어라. 새 테스트 `scripts/test_lens_contract.sh` 는 그 예시 블록과 계약 파일을 대조한다. 이 테스트는 `test_docs_drift.sh` 의 렌즈 스키마 검사(199-207행의 `lens` 값 대조, 235-274행의 사본·추가 칸 대조)를 대체하므로, 그 검사를 새 테스트로 옮기고 원래 검사는 지워라.

`lens-adversarial-claim` 은 공통 칸을 다음과 같이 채운다.

| 칸 | 내용 |
|---|---|
| `file` | 대상 문서의 레포 상대경로, 레포 밖이면 절대경로, 대화 속 주장이면 `conversation` |
| `evidence` | 반박하는 주장 문장 그대로 |
| `counterpart_file` | 외부 출처 URL |
| `counterpart` | 외부 출처의 구절 그대로 |

`lens-readability` 는 현행처럼 `suggestions` 를 출력하고, 지적마다 화면 위치 칸을 추가로 둔다.

리뷰 기록에 저장하는 렌즈 결과 파일의 이름은 `<에이전트 이름>-<순번>.json` 이다. 구현자는 `review-docs` 「기록 파일 이름 규칙」 94~96행의 "스킬 디렉터리 이름"을 "에이전트 이름"으로 고쳐라. 봉인된 기존 기록은 그대로 둔다. 새 이름은 `lens-adversarial-claim` 밖에서 현행 렌즈 이름과 같으므로 기존 기록과 같은 규칙으로 읽힌다.

## 스킬과 구조의 처분

| 대상 | 처분 |
|---|---|
| `skills/lens-*/` | 내용을 `agents/lens-*.md` 로 옮긴 뒤 지운다 |
| `skills/aggregating-lenses/` | 계약은 `scripts/lens_contract.json` 으로 옮긴다. 「하는 일」, 「판단 재귀 회피」, 「처분」(67행의 워크플로 처분 문단 포함), 100행의 메인 세션 집계 방법은 `dispatching-lenses` 의 새 절 「결과를 모으는 법」으로 옮긴다. 「공통 계약의 예외」는 계약 파일의 readability 항목으로 옮긴다. 런타임 전용 결정과 재시도(63·69-73·99·101행)는 `review-llm-calls` 로 옮긴다. 그 뒤 스킬을 지운다 |
| `skills/dispatching-lenses/` | 유지한다. 「렌즈 그룹」 절의 제목은 그대로 두고, 표를 대상별 에이전트 표(위 「에이전트 구성」의 열과 「기계에 넘기는 것」 열)로 바꾼다. 이 표를 호출자×렌즈 정의의 출처로 삼는다. 「따로 실행할 때와 묶을 때」의 "렌즈 하나가 서브에이전트 하나다"를 "에이전트 호출 하나가 렌즈 하나다"로 고친다 |
| 호출자×렌즈 정의 | `dispatching-lenses` 「렌즈 그룹」 표를 출처로 둔다. `dispatching-lenses:110-112`, `review-specs:57-60`, `review-docs:7` 은 그 표를 가리키게 고친다. `test_docs_drift.sh:284,872` 의 손 목록은 표에서 도출한다 |
| `skills/audit-repo-docs/` 와 감사 스크립트 | `skills/audit-repo-docs/`, `scripts/_audit_common.sh`, `scripts/audit_*.sh`, `scripts/test_audit.sh` 를 지운다. 봉인된 자기감사 기록(`docs/superpowers/reviews/*-self-audit*`)은 그대로 둔다 |
| 묶기 예외 | `dispatching-lenses` 「따로 실행할 때와 묶을 때」에서 「한 호출에 묶기(예외)」와 읽기 비용 문단을 지우고, 렌즈마다 따로 실행하는 규칙만 남긴다. 절 제목은 그 내용에 맞게 고치되 다른 파일이 가리키는 곳을 함께 고친다 |
| 감사를 가리키는 파일 | `hooks/doc_word_pretooluse.sh`, `scripts/test_docs_drift.sh`, `skills/dispatching-lenses`, `skills/domain-plugin`, `skills/domain-pruning`, `skills/review-docs` 와 렌즈 정의(현행 `lens-fit`·`lens-grounding`·`lens-consistency` 의 감사 문장)에서 감사 언급을 지우거나 고친다 |
| 리뷰 기록 규칙 | `review-docs` 「기록」을 출처로 두고 `review-specs:100-106` 은 그 절을 가리키게 고친다 |
| `review-llm-calls` | 렌즈 선택표의 렌즈 이름은 그대로 둔다. 7행 "렌즈는 청사진이다"는 "청사진의 출처는 `agents/lens-*.md` 본문이며, frontmatter 와 원칙 경로 지시는 제품 코드에서 뺀다"로 고친다. description 의 "aggregating-lenses는 별도 스킬에서 본다"는 「결과를 모으는 법」을 가리키게 고친다 |

## readability 글 검토의 이전

현행 `lens-readability` 의 글 검토는 review-docs 의 마크다운 초안 퇴고 단계로 옮긴다. 메인 세션이 퇴고할 때 「관찰 목록」의 글 항목, 「고칠 순서」, 「고치는 범위」, 「손대지 않는 요소」를 적용하게 하라. 이 내용은 `review-docs` 의 「마크다운 초안과 퇴고」 아래 참고 절로 옮겨라.

`review-docs:39` 의 "`lens-readability` 가 고쳐 쓴 문장을 내며"는 "메인 세션이 퇴고 참고 절대로 고쳐 쓴다"로 고쳐라.

## fit 문체 기계화

옮길 대상은 `hooks/_doc_form_check.py` 다. `hooks/doc_review_posttooluse.sh` 가 이 검사기를 호출하며, 검사기는 이미 라벨 불릿·개수 예고·제목 개수를 검사한다. 후보는 조사 기록의 fit 조항별 집계에서 많이 나온 조항 중 정규식이나 문장 수 계산으로 판정할 수 있는 항목이다. 원칙 경량화 세션이 지운 조항은 후보에서 빼라.

이 검사기는 모든 프로젝트의 .md 쓰기에 경고를 낸다. 그래서 항목마다 이 저장소의 `docs/` 문서 전체에 실행해 오탐을 세고, 오탐 0건인 항목만 옮겨라.

lens-fit 정의에는 "대상이 .md 이고 형식 경고 검사를 거친 파일이면, 그 검사기가 본 항목은 다시 지적하지 마라"를 조건부로 적어라. .html·.pptx·런타임 출력과 경고를 거치지 않은 파일은 lens-fit 이 그대로 본다.

## 다시 리뷰 정책

원칙 경량화 세션이 main 에 병합된 뒤 `NO-RAW-OUTPUT` 의 다시 리뷰 문장에 대해 현행·변경안 클린룸 시험을 하라. 변경안은 "리뷰를 반영해 기능이 바뀌었으면 바뀐 절과 그 절을 가리키거나 그 절이 가리키는 절만 다시 리뷰하라. 남은 지적 중 설계를 틀리게 만드는 지적이 없으면 다시 리뷰하지 말고 그 판단을 리뷰 기록에 적어라"이다. 시험 방법과 채택 조건은 저장소 CLAUDE.md 「조항 추가와 문구 변경」을 따르라.

변경안이 채택되면 `agent-principles.md` 의 `NO-RAW-OUTPUT` 줄과 `review-specs` 「작업 순서와 다시 리뷰」를 같은 뜻으로 고쳐라. 채택이든 기각이든 시험 결과는 `docs/domain-discipline.md` 의 `NO-RAW-OUTPUT` 절에 적어라.

## 먼저 할 런타임 시험

공식 문서에 없는 사실은 구현 전에 시험하라. 시험은 이 브랜치를 `--plugin-dir` 로 적재한 세션에서 하고, 결과를 결정 기록 `docs/superpowers/decisions/2026-10-25-lens-agent-runtime.md` 에 적어라.

| 시험 | 판정 | 실패하면 |
|---|---|---|
| Agent 도구에 `subagent_type: disciplined-coder:lens-grounding` 을 넣어 실행할 수 있는가 | 에이전트가 실행되고 정의의 tools 만 주어진다 | 이 spec 을 멈추고 사용자에게 묻는다 |
| `@agent-disciplined-coder:lens-adversarial` 로 사용자가 직접 실행할 수 있는가 | 메인 세션이 `dispatching-lenses` 를 읽고 MODE·PRINCIPLES 줄을 채워 실행한다. 두 줄 없이 실행되어도 출력이 계약을 지킨다 | description 에 자연어 요청 문구만 둔다 |
| 같은 이름의 스킬과 에이전트가 함께 있을 때 "lens-adversarial 실행"이라는 요청에 무엇이 선택되는가 | 선택된 쪽을 기록한다 | 3~5단계 사이에는 사용자 직접 실행을 쓰지 않는다고 결정 기록에 적는다 |
| 플러그인 에이전트의 tools 에 세션 MCP 도구(Playwright)를 적을 수 있는가. Playwright 를 끈 세션에서는 어떻게 되는가 | 에이전트가 브라우저 도구로 HTML 파일을 열고 화면을 캡처한다. 끈 세션의 동작을 기록한다 | `lens-readability` 를 글 검토 에이전트로 남긴다(사용자 결정 2026-10-25) |
| 렌즈 1회의 턴 수, 도구 호출 수, effort 를 적지 않았을 때의 실제 effort | 같은 spec 하나에 `lens-grounding` 을 실행해 세 값을 기록하고, 그 값으로 `maxTurns`·`effort` 를 정한다 | — |
| 플러그인 에이전트가 사용자 CLAUDE.md 와 @import 를 받는가 | 에이전트에게 원칙의 조항 ID 하나를 묻는다 | 받으면 PRINCIPLES 줄과 원칙이 두 번 실리므로 PRINCIPLES 줄을 뺄지 사용자에게 묻는다. 받지 않으면 현행대로 PRINCIPLES 줄로 넘긴다 |

## 순서와 확인

4단계부터는 원칙 경량화 세션이 main 에 병합된 뒤 그 커밋 위에서 시작하라. 선행연구 개선 세션이 먼저 병합되면 그 커밋도 함께 받아라. 구현 세션은 4단계를 시작하기 전에 고칠 줄 범위를 두 세션에 메시지로 보내라.

1. 「먼저 할 런타임 시험」을 하고, 결정 기록에 시험마다 결과와 판정을 적었는지 확인한다.
2. `scripts/lens_contract.json` 을 `aggregating-lenses` 「리뷰 산출물 계약」에서 만들고, 계약의 공통 칸이 그 절의 칸과 같은지 확인한다.
3. `agents/lens-*.md` 를 쓰고 `scripts/test_lens_contract.sh` 를 만든다. 테스트가 에이전트 예시 블록과 계약을 대조해 통과하는지, 호출 정책 검사가 tools 에 Agent 를 넣은 정의와 agentType 을 뺀 agent() 호출에서 각각 실패하는지, `claude plugin validate ./` 가 통과하는지 확인한다. `domain-plugin` 에 호출 정책 규칙도 적는다.
4. 「채택 조건」의 비교를 한다. 이 단계는 렌즈 스킬이 아직 있을 때 하므로, 판정이 나빠지면 에이전트 정의만 되돌리면 된다. 판정 결과를 결정 기록에 적었는지 확인한다.
5. `lens-adversarial-claim` 을 2026-10-05 국고채 10년-3년 커브 플랫 주장 보고서(`D:\test\` 폴더, 사용자가 그날 요청한 산출물)에 실행하고 메인 세션의 인용 확인을 거친다. 인용 확인 실패 건수와 토큰·시간을 결정 기록에 적고, 결과를 사용자에게 보여 판정받는다.
6. `dispatching-lenses`, `review-specs`, `review-docs`, `review-llm-calls` 를 「스킬과 구조의 처분」과 「readability 글 검토의 이전」대로 고친다. 「렌즈 그룹」 제목을 가리키는 `nested-orchestration/SKILL.md:246`, `nested-orchestration/references/sub-session-protocol.md:63`, `review-docs:62,64` 가 그대로 맞는지 확인한다.
7. `skills/lens-*/`, `skills/aggregating-lenses/`, `skills/audit-repo-docs/` 와 감사 스크립트를 지우고 「1:1 전제 목록」을 모두 고친다. 저장소 전체(봉인된 리뷰 기록, 과거 spec·plan, 결정 기록 제외)에서 `skills/lens-`·`lens-readability 폴더`·`aggregating-lenses`·`audit-repo-docs`·`audit_` 를 grep 해 남은 줄이 없는지 확인한다. 이어서 저장소 CLAUDE.md 「변경 뒤 실행」의 전체 테스트가 FAIL=0 인지 확인한다.
8. fit 문체 항목을 `hooks/_doc_form_check.py` 로 옮기고 `agents/lens-fit.md` 에 조건부 제외를 적는다. 항목마다 오탐 0건을 확인하고, `test_doc_form.sh`·`test_hooks.sh`·`test_lens_contract.sh` 가 통과하는지 확인한다. 이어서 렌즈 리뷰 한 차수를 실행해 fit 지적 중 문체 비율이 조사 기록의 약 85% 보다 줄었는지 확인한다.
9. 「다시 리뷰 정책」의 클린룸 시험을 하고, 판정을 `docs/domain-discipline.md` 에 적었는지 확인한다. 채택이면 `agent-principles.md` 와 `review-specs` 를 고쳤는지 확인한다.

## 채택 조건

4단계의 비교 대상은 2026-10-09 spec(`docs/superpowers/specs/2026-10-09-nested-orchestration-large-dev-design.md`)의 「2026-10-11 개정 — 메시지 형식」 절이다. 대상 본문은 1차 리뷰 직전 커밋(2498384)의 버전을 `git show` 로 꺼내 쓰라. 기준은 그 1차 리뷰 기록 `docs/superpowers/reviews/2026-10-11-message-schema-review/` 의 렌즈 결과 파일이다. 리뷰 직전 커밋을 확인할 수 있는 spec 리뷰 기록을 하나 더 골라 같은 방식으로 비교하라.

판정은 기준의 지적과 새 에이전트의 지적을 대조해서 한다. 기준 지적 중 반영 커밋에서 반영된 설계 지적(fit 의 style 유형 제외)을 새 에이전트가 몇 건 다시 잡았는지 세라. 토큰과 시간은 세션 기록의 서브에이전트 사용량(`subagent_tokens`, `duration_ms`)에서 읽어라.

| 축 | 채택 조건 |
|---|---|
| 커버리지 | 기준의 반영된 설계 지적을 현행 렌즈와 같은 비율 이상 다시 잡는다. 현행 렌즈의 비율은 같은 대조로 기준 원본 자신을 기준선 1.0 으로 둔다 |
| 토큰 | 차수의 토큰 합이 기준 차수의 세션 기록 값보다 크지 않다 |
| 시간 | 가장 느린 에이전트의 시간이 기준 차수의 가장 느린 렌즈보다 길지 않다 |

어느 축이든 나빠지면 그 수치를 적어 사용자에게 물어라. 같은 질문을 같은 조건으로 다시 실행하지 마라(메모리, 2026-10-18 사용자 지시).

## 1:1 전제 목록

아래 위치는 "렌즈 하나 = 스킬 하나 = 서브에이전트 하나" 전제로 쓰여 있다. 7단계에서 모두 고쳐라. 목록은 조사 때의 저장소 구조 지도와 리뷰 기록 지적 7에서 왔다.

| 위치 | 박힌 전제 |
|---|---|
| `dispatching-lenses:107` | 렌즈 이름이 스킬 디렉터리 이름, 스키마 `lens` 값, 기록 파일 이름과 같다 |
| `dispatching-lenses:35,40,54,62,67-73` | 프롬프트가 렌즈 SKILL.md 에 있고, 렌즈 하나가 서브에이전트 하나이며, 그룹 표에 대상 열이 없다 |
| `review-docs:94-96` | 원본 이름이 스킬 디렉터리 이름이다 |
| `review-specs:37,51,96` | 대상 하나에 렌즈 넷을 렌즈마다 따로 호출한다 |
| `aggregating-lenses:23,56,76,84-92` | `lens` 열거와 예외 경로가 스킬 경로를 쓴다 |
| `scripts/test_docs_drift.sh` 의 27, 57, 184-193, 199-207, 238, 262, 362, 467, 528, 570, 600, 621-623, 646-651, 883행과 `AGG` 경로를 쓰는 22·31-46·97·178·233-275·886-892행 | 검사가 진실을 `skills/lens-*/` 와 `skills/aggregating-lenses/` 에서 도출한다 |
| `docs/domain-korean.md:264` | 금지 낱말 예외가 렌즈 파일(`skills/lens-*/SKILL.md`)에만 적용된다 |
| `skills/domain-plugin/SKILL.md:24` | 서브에이전트로 실행하는 스킬의 이름 부류에 `lens-` 와 `aggregating-lenses` 를 든다 |
| `hooks/rules_nudge_pretooluse.sh:52` | 주석이 lens-readability 폴더를 가리킨다 |

## 다른 세션과의 경계

원칙 경량화 세션(`worktree-principles-slimming`)과 선행연구 개선 세션(`worktree-prior-art-agent-review`)이 겹치는 파일을 다룬다. 두 세션이 고친 줄은 그 세션 브랜치의 git 상태에서 확인하라.

| 세션 | 구현 세션이 지킬 경계 |
|---|---|
| 원칙 경량화 | 그 세션은 지운 조항을 가리키던 줄을 고친다. 구현 세션은 그 세션 병합 뒤의 내용을 기준으로 렌즈 파일을 옮기고, 그 세션이 요청한 `lens-readability` 81·110행과 `lens-adversarial` 의 참고 문서 포인터 변경을 에이전트 정의에 반영하라. `NO-RAW-OUTPUT` 은 그 세션이 고치지 않는다 |
| 선행연구 개선 | 구현 세션은 `dispatching-lenses` 「렌즈에게 에이전트원칙을 알리는 법」과 `review-docs` 「기록 파일 이름 규칙」의 절 제목을 유지하라. 그 세션이 「기록 파일 이름 규칙」의 선행연구 목록과 `review-specs` 「`prior-art` 기록에 적을 것」을 고치므로, 구현 세션은 그 두 곳의 선행연구 행을 그대로 두라. |

## 구현자에게 맡기는 것

- **정의 본문의 문안:** 현행 SKILL.md 에서 옮길 때 체크리스트 축과 판정 기준의 뜻을 유지하는 범위에서 문장을 다듬는다.
- **계약 파일의 칸 배치:** `scripts/lens_contract.json` 의 키 이름과 구조는 `prior_art_contract.json` 을 따르는 범위에서 정한다.
- **기계화할 fit 항목:** 오탐 0건이 확인된 항목 중에서 고른다.
- **새 체크리스트의 문장:** `artifact` 모드, `lens-adversarial-claim`, 렌더링 리뷰의 체크리스트 문장은 「새 체크리스트」의 축과 가드를 지키는 범위에서 쓴다.
- **두 번째 비교 대상:** 리뷰 직전 커밋을 확인할 수 있는 spec 리뷰 기록 중에서 고른다.

## 리뷰로 바뀐 설계

2026-10-25 1차 리뷰(리뷰 기록 `2026-10-25-lens-agent-restructure-review.md`)로 다음 설계가 바뀌었다. 채택 비교를 스킬 삭제보다 앞으로 옮겼다. 판정 기준을 지적 수에서 반영된 기준 지적의 재검출률로 바꾸고 시간 축을 추가했다. fit 기계화의 대상 파일을 실제 검사기로 고치고 오탐 0건 조건과 조건부 제외를 두었다. 주장 반박 에이전트에 접속 금지와 검색어 규칙, 칸 배치, 발동 조건을 정했다. readability 글 검토의 이전 곳과 감사에서의 제외를 정했다. 4단계 이후의 시작 조건을 원칙 경량화 세션 병합 뒤 하나로 정했다. 묶기 예외를 물은 질문에 사용자는 레포 문서 감사 자체를 지우기로 답했고, 그래서 묶기 예외도 지웠다. 같은 날 사용자는 에이전트 호출 정책(사전 정의 호출만 허용과 그 검사)을 이 spec 에 넣기로 정했고, 정책 결정 기록은 적대 렌즈 한 차수를 거쳤다.

<!-- spec-review: escalated -->
