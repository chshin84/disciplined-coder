# 선행연구 에이전트 — 설계

2026-10-18에 설계 세션이 선행연구 에이전트의 설계를 썼다. 선행연구 에이전트는 `lens-prior-art`를 대체하는 구성이며, 사용자와 여러 턴을 주고받으며 선행연구를 운영한다. 사용자는 "선행연구렌즈 → 선행연구 에이전트로 승격할만큼, 멀티턴, 상황별 대응 등 구조적인 혁신이 필요해"라고 요구했다. 이유로는 "내가 선행연구렌즈를 최근 많이 활용하는데, 선행연구 에이전트를 개발해서 적절하게 사용하도록 하는게 필요하다"고 밝혔다.

설계의 근거는 같은 날 사용자의 직접 요청으로 실행한 선행연구 렌즈의 결과와 그 인용 검증이며, 기록은 `docs/superpowers/reviews/2026-10-18-prior-art-agent-prior-art.md`에 있다. spec 리뷰 기록은 `docs/superpowers/reviews/2026-10-18-prior-art-agent-review.md`, `…-review-2.md`, `…-review-3.md`다. 리뷰로 바뀐 판단은 각 절에 적었다.

## 용어

용어는 이 문서와 고칠 스킬 안에서 아래 뜻으로만 쓴다.

| 이름 | 뜻 |
|---|---|
| 선행연구 에이전트 | 스킬 `agent-prior-art`, 연구자 정의, 검증자 정의, 탐색 워크플로, 발동 넛지를 묶은 구성 전체다 |
| 오케스트레이터 | `agent-prior-art`를 따르는 메인 세션이다. 프로토콜을 쓰고 단계 사이에서 사용자 승인을 받으며 기록을 쓴다 |
| 설계 세션 | 2026-10-18에 이 spec 을 쓴 세션이다 |
| 빌더 | 이 spec 으로 plan 을 쓰고 구현하는 사람이나 세션이다. 「워크스트림 분할」 뒤로는 구현 서브 세션이 빌더다 |
| 현재 세션 | `nested-orchestration`의 현재 세션이다. 사용자와 대화하며 큰 명세와 통합과 병합 전 시험을 맡는다. 설계 세션이 이어서 맡는다 |
| 서브 세션 | `nested-orchestration`의 서브 세션이다. 워크스트림 하나를 맡고 사용자와 대화하지 못한다 |
| 연구자 | 에이전트 정의 `disciplined-coder:prior-art-researcher`로 실행하는 서브에이전트다. 탐색 모드에서는 하위 질문 하나를 맡아 웹을 탐색하고, 종합 모드에서는 통과 목록으로 근거 지도를 만든다 |
| 검증자 | 에이전트 정의 `disciplined-coder:prior-art-verifier`로 실행하는 서브에이전트다. 인용 판정 모드와 지도 대조 모드가 있다 |
| 프로토콜 | 오케스트레이터가 실행 전에 쓰는 연구 계획이다. 항목은 「오케스트레이터 절차」의 프로토콜 항목이 정한다 |
| 하위 질문 | 연구 질문을 연구자 하나가 맡을 크기로 나눈 질문이다 |
| 대조 대상 | 네 축 대조에서 선행 사례와 비교하는 대상이다. spec·제안서의 방법이거나, 사용자가 만들려는 것이거나, 사용자가 고르려는 결정 후보안이다 |
| 체크리스트 | 현행 렌즈의 판정 항목인 기시감·결말·전이·기준선·붐빔이다. 누가 이미 해봤는지, 결과가 무엇이었는지, 실패 원인이 대조 대상에도 있는지, 단순한 기준선과 비교했는지, 이미 표준이 된 것을 다시 짓는지를 가리킨다 |
| 네 축 대조 | 선행 사례와 대조 대상을 목적·메커니즘·평가·적용 대상에서 같은지 다른지 적는 대조다 |
| 근거 지도 | 사례마다 네 축 대조, 결말, 출처 성격, 찾은 경로를 적은 표다. 칸은 「출력 스키마」의 `evidence_map`이 정한다 |
| 질의 경계 | 검색어에 고유명사·파일 경로·사내 식별자·미공개 제품명·사람 이름·코드 조각을 넣지 않는다는 가드다 |
| 공백 라운드 | 커버리지 공백이 남은 하위 질문만 다시 탐색하는 실행이다 |
| 통상·최대 | 탐색 모드 연구자 수의 상한 두 값이다. 「실행할 때 지킬 상한」이 정한다 |
| `🔴` | `review-specs`가 사용자 결정이 필요하다고 분류한 리뷰 발견이다 |
| PREP | `review-specs` 절차의 첫 단계로, 렌즈를 실행하기 전에 렌즈별 주입 지식과 체크리스트를 준비하는 단계다 |

## 목적과 이유

설계 세션이 현행 렌즈로 선행연구를 하는 동안 아래 문제가 드러났다.

**발동 누락.** 사용자가 "서브에이전트 최대 50개를 써서 … 선행연구해봐라"고 요청했지만, 설계 세션은 `lens-prior-art`를 열지 않고 손으로 짠 워크플로를 실행했다. 사용자가 "선행연구렌즈 쓴거 맞아?"라고 지적해 실행을 중단했다. 실패한 요청의 문구는 현행 description("선행연구·선행 사례·prior art를 찾아 달라거나 …")에 이미 있었다. 설계 세션이 Workflow 실행을 일반 연구로 분류해 스킬 목록을 대조하지 않은 것이 원인이었다.

**절차의 즉흥성.** 렌즈를 여럿 실행할 때 설계 세션이 하위 질문 분해, 프롬프트, 인용 검증을 그 자리에서 짰다. 렌즈 계약은 렌즈 하나의 판정만 정하고 여럿을 실행하는 절차는 정하지 않는다.

**출력 계약의 한계.** 렌즈는 `refuted-premise`·`known-failure`·`crowded`·`weak-baseline`만 이슈로 올린다. 그래서 "무엇을 가져다 쓸 수 있는가"의 답은 모든 렌즈에서 `notes`의 비정형 목록으로 왔다.

**가드의 약함.** 렌즈 하나가 검색어에 논문 저자의 성을 넣었다고 스스로 밝혔다. 질의 경계와 읽기 전용은 프롬프트 지시뿐이다.

빌더는 이 문제들을 절차와 도구 제한과 데이터 흐름으로 고정한다. 판정 규약(체크리스트, 네 축 대조, 가드)은 `agent-prior-art`로 옮기되 내용은 바꾸지 않는다.

## 목표와 비목표와 반목표

**목표**

- **절차의 고정** — 오케스트레이터 절차와 탐색 워크플로가 여러 연구자를 실행하는 절차를 정한다.
- **근거 지도의 정식 출력화** — 근거 지도를 출력 스키마의 정식 칸으로 둔다.
- **상황별 대응** — 상황마다 하위 질문 분해와 출력 모드가 달라진다.
- **여러 턴 진행** — 오케스트레이터가 단계 사이에 사용자 승인과 판단을 받는다.
- **가드의 강제** — 에이전트 정의가 도구를 제한한다. 워크플로 스크립트는 질의 경계를 결정론으로 검사하며, 데이터 흐름은 검증을 통과한 항목만 종합에 넘긴다.
- **발동 경로** — 사용자 요청과 `review-specs`·`review-docs`에서 이 에이전트가 실행되는 경로를 정한다.

**비목표**

- **외부 도구 채택** — Claude Code 내장 `/deep-research`나 외부 플러그인을 채택하지 않는다. 이유는 「리서치 근거」에 있다.
- **참신성 채점** — 참신성을 채점하지 않는다(현행 렌즈의 가드를 유지한다).
- **자동 반영** — 웹 결과를 문서에 자동으로 반영하지 않는다.
- **탐색 이중화** — 같은 하위 질문을 연구자 둘에게 맡기지 않는다. 사용자가 2026-10-18에 정했다.

**반목표** — 기술적으로 동작해도 아래 상태가 되면 실패다.

- **과잉 실행** — 단순한 질문에 서브에이전트를 여럿 실행한다.
- **조용한 통과** — 검증을 통과하지 못한 사례가 검증된 사례처럼 근거 지도에 섞인다.
- **판정의 역전** — '찾지 못함'이 '없음'으로 읽힌다.
- **자기 확증** — 같은 모델 계열의 판정이나 일치를 독립 확인으로 보고한다.

## 리서치 근거

설계 세션이 아래 근거의 원문을 열어 확인했다. 선행연구 기록이 미검증으로 적은 인용 중 cookbook research subagent 프롬프트의 도구 호출 예산과 설치된 deep-research 스킬의 문구는, 설계 세션이 그 기록을 쓴 뒤 원문을 열어 확인했다.

**선행 사례.** 선행연구 대조를 목적으로 하는 에이전트나 플러그인은 찾지 못했다. 찾지 못했다는 뜻이며 없다는 근거가 아니다. 마켓플레이스 경로와 GitHub 경로의 렌즈가 같은 결론을 냈지만, 두 렌즈는 같은 모델 계열이므로 이 일치를 독립 확인으로 세지 않는다.

**골격의 붐빔.** 분해·병렬 탐색·공백 보충·인용 검증의 골격은 이미 여러 곳에 구현되어 있다. 그래서 빌더는 골격을 새로 짓지 않고 Claude Code 워크플로 런타임과 공개 기준을 따른다.

**워크플로 런타임.** [워크플로 문서](https://code.claude.com/docs/en/workflows)에 따르면 런타임은 중간 결과를 스크립트 변수에 두고, 플러그인은 `workflows/` 디렉터리로 워크플로를 배포한다. 같은 문서는 "No mid-run user input"을 제약으로 적고, 단계 사이 승인이 필요하면 단계마다 워크플로를 따로 실행하라고 적는다. 런타임은 같은 세션 안에서 중단된 실행을 이어 실행하며, 완료된 에이전트는 저장된 결과를 돌려준다.

**에이전트 정의.** [플러그인 구성 문서](https://code.claude.com/docs/en/plugins/components)에 따르면 `agents/` 아래 마크다운 파일 하나가 에이전트 하나를 정의하고, 등록 이름은 `<plugin>:<name>` 형태다. [서브에이전트 문서](https://code.claude.com/docs/en/sub-agents)의 frontmatter 표에는 `tools`, `disallowedTools`, `model`, `maxTurns`("Maximum number of agentic turns")가 있다. 플러그인 에이전트는 `hooks`·`mcpServers`·`permissionMode`를 무시한다. 워크플로 `agent()`의 `agentType` 옵션은 내장 `workflow-authoring` 스킬이 "resolved from the same registry as the Agent tool"로 적으며, 공식 워크플로 문서 본문에는 없다. 현재 세션이 2026-10-18에 실측했고 결과는 「결정 기록」의 「런타임 확인」에 있다.

**시험용 플러그인 적재.** 이 PC의 Claude Code 2.1.302 `claude --help`는 `--plugin-dir <path>`를 "Load a plugin from a directory or .zip"으로 설명한다. 그래서 병합 전 시험은 브랜치 작업 트리를 이 옵션으로 적재한 세션에서 실행한다.

**`/deep-research`를 채택하지 않는 이유.** 이 워크플로는 투표로 교차 검증을 통과하지 못한 주장을 지운다. 선행연구 에이전트는 불일치를 지우지 않고 사용자가 처분하게 한다. `/deep-research`에는 네 축 대조와 전이 판정도 없다.

**노력 산정 기준.** Anthropic cookbook 의 [research lead 프롬프트](https://github.com/anthropics/claude-cookbooks/blob/main/patterns/agents/prompts/research_lead_agent.md)는 서브에이전트를 단순 질의 1개, 표준 2~3개, 중간 3~5개, 고복잡 5~10개(maximum 20)로 정하고 "Never create more than 20 subagents unless strictly necessary"라고 적는다. 같은 저장소의 [research subagent 프롬프트](https://github.com/anthropics/claude-cookbooks/blob/main/patterns/agents/prompts/research_subagent.md)는 어려운 과제에 도구 호출 약 10회, 매우 어려운 과제에 15회까지를 둔다. 이 프롬프트는 "stay under a limit of 20 tool calls and under about 100 sources"를 "absolute maximum upper limit"으로 적는다.

**공백 라운드 상한.** 이 PC에 설치된 Anthropic deep-research 스킬은 추가 라운드를 "[If absolutely necessary] Conduct one additional round of research"로 두고 "This step can only be followed once"라고 적는다. 더 실행하면 시간 초과나 속도 제한에 걸린다는 것이 그 이유다.

**검증의 데이터 흐름 강제.** insane-research 의 [CHANGELOG](https://github.com/fivetaku/insane-research/blob/main/CHANGELOG.md)에 따르면, 검증이 절차 위반 40건(`passed=false`)을 냈는데도 그 저장소는 보고서를 생성했다. 그 저장소는 이 문제를 고치려고 검증 실패 시 합성 입력을 지우게 했다. 선행연구 에이전트도 검증을 통과한 항목만 종합의 입력으로 쓴다.

**같은 모델 판정의 상관.** Kim 등(ICML 2025)은 한 리더보드 데이터셋에서 두 모델이 함께 틀렸을 때 같은 오답을 고른 비율이 60%였다고 보고했다. 같은 초록은 "larger and more accurate models have highly correlated errors, even with distinct architectures and providers"라고 적는다([초록](https://arxiv.org/abs/2506.07962)). 7개 계열 9개 모델 판정 패널은 독립 표 약 2개 분량의 정보만 냈고, 최고 단일 판정자가 모든 조건에서 패널과 같거나 더 나았다([arXiv 2605.29800](https://arxiv.org/abs/2605.29800)). 그래서 선행연구 에이전트는 탐색 이중화를 두지 않고, 검증자의 판정을 독립 확인으로 보고하지 않는다.

**인용 판정 기준의 영향.** 같은 출력에서 판정기의 엄격도만으로 미지지 인용 비율이 약 3%에서 18%까지 달라졌고, 판정기 사이의 미지지 일치는 0.27~0.30이었다([arXiv 2607.20527](https://arxiv.org/abs/2607.20527)). 그래서 빌더는 검증자의 판정 기준을 고정하고, 검증자가 판정마다 지지 구절을 그대로 옮겨 적게 한다.

**종합 단계의 오류.** 한 오픈소스 시스템(AI-Q)에서는 최종 보고서 오류의 84.7%가 오케스트레이터에서 생겼다([arXiv 2608.24306](https://arxiv.org/abs/2608.24306)). 그래서 검증자가 종합한 근거 지도를 입력과 다시 대조한다.

**무한 탐색과 과잉 실행.** Anthropic 은 두 가지 실패를 보고했다([글](https://www.anthropic.com/engineering/multi-agent-research-system)). 에이전트가 없는 출처를 끝없이 찾았고, 단순 질의에 서브에이전트 50개가 실행되었다. 그래서 연구자와 검증자의 턴 수와 공백 라운드에 숫자 상한을 둔다.

## 구성

| 구성 요소 | 위치 | 하는 일 |
|---|---|---|
| 오케스트레이터 스킬 | `skills/agent-prior-art/SKILL.md` | 절 「오케스트레이터 절차」「발동과 기록」「상황별 전략」「실행할 때 지킬 상한」「판정 규약」「출력 스키마」「인용 확인」「레퍼런스 프롬프트」를 둔다 |
| 연구자 정의 | `agents/prior-art-researcher.md` | 시스템 프롬프트는 「레퍼런스 프롬프트」의 본문을 그대로 옮긴 단락과 모드 처리 단락으로 이루어진다. 도구는 WebSearch·WebFetch·Read·Grep·Glob 이며 `maxTurns`는 20 이다 |
| 검증자 정의 | `agents/prior-art-verifier.md` | 인용 판정 모드에서는 URL 하나의 원문을 한 번 열어 그 URL 에 걸린 주장을 모두 판정한다. 지도 대조 모드에서는 근거 지도의 칸마다 입력에 근거가 있는지 표시한다. 도구는 WebFetch·Read 이며 `maxTurns`는 20 이다 |
| 탐색 워크플로 | `workflows/prior-art-search.js` | 프로토콜을 `args`로 받아 연구자를 실행한다. 스크립트가 질의 경계를 검사한 뒤 검증자가 인용을 판정한다. `survey` 모드에서는 마지막 단계에서 연구자가 종합 모드로 근거 지도를 만들고, 검증자가 지도 대조 모드로 대조한다 |
| 발동 넛지 | `hooks/prior_art_nudge_userpromptsubmit.sh`와 `hooks/hooks.json`의 UserPromptSubmit 연결 | 사용자 메시지가 선행연구를 요청하면 오케스트레이터에게 `agent-prior-art`를 열라는 알림을 추가 컨텍스트로 낸다. 차단하지 않는다. `DISCIPLINED_CODER_PRIOR_ART_NUDGE=off`로 끈다 |

`lens-prior-art`는 삭제한다. 사용자가 2026-10-18에 "선행연구렌즈는 삭제하고"라고 정했다. 스킬 이름 `agent-prior-art`도 사용자가 정했다.

두 에이전트 정의의 도구 목록에는 Agent 도구가 없다. 그래서 연구자와 검증자가 하위 에이전트를 여는 중첩은 도구 제한으로 금지된다. 검증자의 `maxTurns` 20 은 연구자와 같은 근거(cookbook 의 절대 상한 20)를 따른다. 원문을 열지 못하는 검증자가 끝없이 재시도하는 실패도 Anthropic 이 보고한 무한 탐색과 같은 형태이기 때문이다.

연구자 정의의 '그대로 옮긴 단락'은 「레퍼런스 프롬프트」 본문과 글자가 같아야 한다. 빌더는 `scripts/test_docs_drift.sh`에 그 단락만 대조하는 검사를 추가하고, 모드 처리 단락은 대조하지 않는다.

1차 리뷰 전에는 종합을 별도 워크플로로 두고 질의 경계 검사를 '검사 에이전트'에 맡겼다. 1차 리뷰에서 `lens-adversarial`과 `lens-consistency`가 두 구성의 불필요함을 지적했다. 그래서 설계 세션은 둘 다 탐색 워크플로 안으로 옮기고, URL 응답 확인을 검증자의 `unverifiable` 판정으로 합쳤다.

## 오케스트레이터 절차

워크플로는 실행 도중에 사용자 입력을 받지 못한다. 그래서 오케스트레이터는 승인이 필요한 지점마다 워크플로 실행을 나눈다. 단계 사이에 오케스트레이터와 사용자가 대화하는 턴이 들어가며, 이 턴들이 여러 턴 진행이다.

**프로토콜 항목.** 연구 질문, 상황, 대조 대상, 모드, 하위 질문(ID, 범위 문장, 포함·제외 기준), 질의 금지 목록, 탐색 모드 연구자 수와 그 산정 근거, `principles_path`다. 오케스트레이터는 `principles_path`를 실행 시점에 도출하고, 워크플로가 그 경로를 연구자와 검증자의 프롬프트에 넣는다.

1. **상황 판정과 프로토콜** — 오케스트레이터가 상황과 대조 대상을 정하고 프로토콜을 쓴다. 사용자에게 프로토콜을 보이고 승인을 받으며, 승인이 없으면 실행하지 않는다. 승인을 받으면 오케스트레이터는 곧바로 기록 파일을 만들고 프로토콜 전문과 승인 사실을 적는다.
   - **확인** — 기록 파일에 프로토콜 전문과 승인 사실이 있다.
2. **탐색** — 오케스트레이터가 `disciplined-coder:prior-art-search`를 프로토콜과 함께 실행한다. 아래 처리는 워크플로가 한다.
   - 하위 질문마다 탐색 모드 연구자를 실행한다.
   - 스크립트가 연구자의 `queries`를 질의 금지 목록과 경로 형태 정규식으로 검사하고 위반을 기록한다.
   - 스크립트가 인용을 URL 로 묶고, URL 마다 검증자를 실행한다.
   - 스크립트는 `supported` 판정을 받은 주장에 기댄 사례만 통과 목록에 넣는다.
   - 나머지 사례는 탈락 목록, 판정 불가 목록, 검증 실패 목록에 사유와 함께 들어간다.
   - `survey` 모드에서는 종합 모드 연구자와 지도 대조 모드 검증자를 차례로 실행한다.
   - **확인** — 반환값이 「출력 스키마」의 워크플로 반환값 형식을 따른다. 오케스트레이터는 반환 직후 원본을 기록 폴더에 쓴다.
3. **공백 판단** — 오케스트레이터가 커버리지 표와 연구자의 `saturation`·`not_found`를 사용자에게 보이고, 공백 라운드를 실행할지 묻는다. 공백 라운드는 공백 하위 질문만 대상으로 `disciplined-coder:prior-art-search`를 다시 실행하며, 한 연구 질문에 1회까지다. 오케스트레이터는 두 실행의 결과를 하위 질문 ID 로 합치고, 같은 URL 이 두 실행에 다 있으면 공백 라운드의 판정을 쓴다.
   - **확인** — 기록에 공백 라운드 실행 여부와 사유가 있고, 공백 라운드 원본이 반환 직후 기록 폴더에 있다.
4. **인용 확인과 보고** — 오케스트레이터가 「인용 확인」의 범위에 드는 인용을 직접 열어 확인한다. 그다음 기록 파일에 처분 전 결과를 적고 사용자에게 보고한다. 문서에 반영할지는 사용자가 정한다.
   - **확인** — 기록 파일과 원본이 아래 원본 파일 규칙을 따른다.

**원본 파일 규칙.** 기록 폴더 안의 원본 이름은 실행 차례 `r<n>`(첫 탐색 1, 공백 라운드 2)을 붙여 아래처럼 쓴다. 이 규칙은 `review-docs` 「기록 파일 이름 규칙」에 `prior-art` 종류의 원본 규칙으로 추가하며, 렌즈 원본의 기존 규칙은 바꾸지 않는다.

| 원본 | 이름 |
|---|---|
| 워크플로 반환값 | `search-r<n>.json` |
| 탐색 모드 연구자 출력 | `researcher-<하위 질문 ID>-r<n>.json` |
| 인용 판정 출력 | `verifier-r<n>.json`(URL 별 판정 배열. 판정마다 그 URL 을 인용한 하위 질문 ID 를 적는다) |
| 종합 모드 연구자 출력 | `synthesis-r<n>.json` |
| 지도 대조 출력 | `map-check-r<n>.json` |

**상태 값.** `search_status`는 연구자마다 `ok`·`no-results`·`failed`·`not-attempted` 중 하나이며 뜻은 현행 렌즈 표를 그대로 옮긴다. `verification_status`는 하위 질문마다 `ok`·`partial` 중 하나다. 그 하위 질문의 URL 에 검증 실패(검증자 에이전트의 실패, 시간 초과, 속도 제한)가 하나라도 있으면 `partial`이다. 연구 질문 전체의 `overall_status`는 모든 하위 질문의 두 값이 `ok`일 때만 `ok`다. `overall_status`가 `ok`가 아니면 오케스트레이터는 `ok`가 아닌 하위 질문의 결과를 판정으로 쓰지 않고 하위 질문별 값을 보고에 적는다.

**세션이 끊긴 때.** 워크플로가 실행 중에 중단되면 오케스트레이터는 같은 세션 안에서 런타임의 이어 실행 기능으로 다시 시작한다. 반환 전에 세션 자체가 끝나면 기록에는 프로토콜과 승인 사실만 남는다. 다음 세션의 오케스트레이터는 기록을 보고 검색어가 이미 나갔을 수 있다고 기록에 적은 뒤, 같은 프로토콜로 사용자 승인을 다시 받아 처음부터 실행한다.

**워크플로가 꺼진 환경.** `disableWorkflows`가 켜져 있으면 오케스트레이터는 같은 순서로 연구자와 검증자를 Agent 도구로 실행한다. 이 경로에서는 질의 경계 검사와 통과 목록 분리를 오케스트레이터가 직접 하므로, 두 가드는 지시 준수에만 기댄다. 오케스트레이터는 이 사실을 보고와 기록에 적는다.

## 발동과 기록

이 절은 현행 `dispatching-lenses` 「렌즈 그룹」이 필요할 때 그룹에 정한 공통 규칙을 선행연구 에이전트에 맞게 옮긴다. 선행연구 에이전트는 렌즈가 아니므로 그 절의 적용을 받지 않는다.

**제안과 승인.** `review-specs`와 `review-docs`는 각자의 발동 기준에 해당하면 실행을 제안한다. 1단계의 프로토콜 승인이 실행 승인이다.

**직접 요청.** 사용자가 선행연구를 직접 요청하면 그 요청이 실행 제안의 승인이다. 오케스트레이터는 그래도 1단계의 프로토콜 승인을 받는다.

**판정 기록.** `review-specs`와 `review-docs`는 선행연구 에이전트를 제안했는지, 승인받았는지, 각각의 이유를 그 차수의 기록에 적는다. 그래야 실행하지 않은 사실이 조용히 사라지지 않는다.

**서브 세션.** `nested-orchestration`의 서브 세션은 사용자에게 묻지 못하므로 선행연구 에이전트를 실행하지 않는다. 발동 기준에 해당한 사실만 리포트에 적어 현재 세션에 넘긴다. 선행연구 없이 진행할 수 없으면 멈추고 현재 세션에 승인을 요청하며, 그 형식은 `nested-orchestration` 프로토콜 파일이 정한다.

**발동 넛지의 조건.** 넛지는 사용자 메시지마다 실행되며 세션당 횟수 제한을 두지 않는다. 같은 세션의 두 번째 요청에서도 발동 누락이 생길 수 있기 때문이다. 넛지가 알림을 내는 조건은 메시지에 주제어와 요청형 표현이 함께 있는 것이다. 주제어는 "선행연구", "prior art", "선행 사례", "누가 해봤", "선행연구렌즈", "lens-prior-art"이고, 요청형 표현은 "찾아", "뒤져", "조사해", "해봐", "있나", "없나" 같은 표현이다. 빌더는 이 목록에서 시작해 발동 시험으로 고친다. `agent-prior-art`의 description 에도 같은 주제어와 옛 이름을 넣는다.

## 상황별 전략

상황 목록은 설계 세션이 이 spec 의 바탕이 된 대화의 실제 요청과 현행 `review-specs`·`review-docs`의 발동 경로에서 뽑았고, 사용자가 2026-10-18에 확정했다.

| 상황 | 발동 경로 | 대조 대상 | 하위 질문 분해 | 모드 |
|---|---|---|---|---|
| spec 대조 | `review-specs`의 제안과 승인 | spec 의 메커니즘 | 핵심 메커니즘마다 하나 | `contrast` |
| 제안서 검진 | `review-docs`의 제안과 승인 | 문서가 주장하는 방법 | 주장하는 방법마다 하나 | `contrast` |
| 기존 도구 탐색 | 사용자 직접 요청("쓸 만한 것 없나") | 사용자가 만들려는 것 | 검색 경로마다 하나(목록 사이트, 저장소, 논문) | `survey` |
| 결정 근거 탐색 | 사용자 직접 요청("근거를 찾아 달라", "어떻게 배치해야 하나") | 사용자가 고르려는 결정 후보안 | 결정이 기대는 주제마다 하나 | `survey` |
| 사실 확인 | 사용자 직접 요청, 단일 사실 | 확인하려는 주장 | 나누지 않음 | `survey` |

오케스트레이터가 상황이나 대조 대상을 하나로 정하지 못하면 사용자에게 묻는다.

## 실행할 때 지킬 상한

**상한 값.** 사용자가 2026-10-18에 정한 값이다. 탐색 모드 연구자 수의 통상은 2개, 최대는 20개이며, 바꾸려면 사용자에게 물어야 한다. 이 값은 현행 `lens-prior-art`의 '최대한 6'을 대체한다.

**통상을 넘을 때.** 통상은 오케스트레이터가 이유를 적지 않고 고를 수 있는 값이다. 통상을 넘는 수는 프로토콜에 이유를 적어 승인받는다. 하위 질문이 통상보다 많으면 오케스트레이터는 하위 질문을 묶지 않고, 연구자 수를 올리는 근거를 적는다.

**세는 대상.** 상한은 탐색 모드 연구자만 센다. 검증자와 종합 모드 연구자는 URL 수와 모드에 따라 정해지므로 상한에 넣지 않는다. 검증자 수는 탐색이 끝나야 정해지므로, 오케스트레이터는 승인 때 연구자 수만 보이고 실제 검증자 수는 보고에 적는다. 연구자 하나가 인용할 출처는 cookbook 의 "under about 100 sources"를 따라 약 100개 이하로 둔다.

**단계당 상한의 예외.** 선행연구 에이전트에는 `dispatching-lenses`의 "한 단계가 실행하는 에이전트는 10개 이하"를 적용하지 않는다. 사용자가 2026-10-18에 이 예외를 정했다. 한 단계의 규모는 연구자 상한 20과 런타임의 동시 실행 한도(기본 16)가 정한다.

**턴 상한.** 연구자와 검증자 정의의 `maxTurns`는 20 이다. 공식 문서는 `maxTurns`를 "agentic turns"로만 정의하며 도구 호출과의 관계는 적지 않는다. 그래서 cookbook 의 도구 호출 20회 상한은 연구자 프롬프트의 지시로도 둔다. 빌더는 시험에서 `maxTurns`가 도구 호출 수를 함께 제한하는지 실측한다. 런타임이 상한에 이른 연구자의 출력을 partial 로 표시하면, 오케스트레이터는 그 하위 질문을 공백 후보로 다룬다.

**공백 라운드 상한.** 한 연구 질문에 1회다. 설치된 deep-research 스킬의 "This step can only be followed once"가 근거다.

## 판정 규약

빌더는 현행 `lens-prior-art`의 「체크리스트」, 네 축 대조 문단, 「가드」를 내용을 바꾸지 않고 이 절로 옮긴다. 다만 가드의 `lens-derived`는 「출력 스키마」의 이름 변경에 맞춰 `derived`로 적는다. 가드의 "인용한 URL은 실제로 열어 확인하고 출처의 성격을 구분해 적는다"는 연구자에게 그대로 적용하고, 그 결과는 검증자가 다시 판정한다.

## 출력 스키마

빌더는 현행 렌즈의 출력 스키마를 시작점으로 삼는다. `lens` 칸은 `agent` 칸으로 바꾸고 값은 `agent-prior-art`로 둔다. `citations`의 `kind` 열거는 `peer-reviewed|preprint|vendor|blog|standard|derived`로 바꾼다. `standard`는 표준기구 문서이고, `derived`는 현행 `lens-derived`(에이전트가 스스로 계산하거나 추론한 값)를 이름만 바꾼 것이다. 아래 칸을 연구자 출력에 추가한다.

| 칸 | 내용 |
|---|---|
| `mode` | `contrast`(이슈만) 또는 `survey`(이슈와 근거 지도)다. 상황이 정한다 |
| `subquestion_id` | 프로토콜의 하위 질문 ID 다 |
| `queries` | 연구자가 실행한 검색어 전부다. 질의 경계 검사의 입력이다 |
| `evidence_map` | `survey`에서만 채운다. 탐색 모드 연구자는 자기 하위 질문의 행을 채우고, 종합 모드 연구자는 통과 목록의 행만으로 다시 만든다. 행마다 사례 이름, URL, 네 축 각각의 `{ prior, same, note }`(`prior`는 선행 사례 쪽 서술, `same`은 대조 대상과 같은지, `note`는 그 판단의 근거), 결말(성공·실패·판정 못 함), 출처 성격, 1차·2차 출처 구분, 찾은 경로(`route`)를 적는다. 기존 도구 탐색 상황에서는 `adoption`(채택·흡수·참고·해당 없음)도 채운다 |
| `saturation` | 마지막 세 번의 검색에서 새 사례가 몇 건 나왔는지다 |
| `issues[].prior_claim` | 이슈마다 선행 사례와 그 결말에 관한 서술만 적은 문장이다. 검증자가 판정하는 대상이다. 대조 대상에 관한 서술(전이, 기준선과 비교되지 않음)은 `claim`에 남기고 판정하지 않는다 |

**인용 판정 출력.** 검증자는 URL 마다 그 URL 에 걸린 주장별로 `verdict`(supported·unsupported·unverifiable), `quote`(원문에서 옮긴 지지 구절), `reason`을 낸다. 출력 전체에 `principles_applied`를 둔다. 빌더는 판정 기준을 "옮긴 구절이 주장의 주어와 수치와 조건을 모두 포함하면 supported"로 고정한다. 판정 대상은 선행 사례 쪽 서술뿐이다. 이슈는 `prior_claim`, 근거 지도 행은 사례 이름과 `outcome`과 각 축의 `prior`다. 근거 지도 행은 사례가 있다는 것과 그 결말을 뒷받침하는 구절이 있으면 `supported`이고, 축마다의 판정은 `reason`에 적는다. 대조 대상 쪽 판단(`same`, `note`, 이슈의 `claim`)은 연구자가 책임지며 사용자가 보고에서 확인한다(2026-10-18 사용자 결정). `unverifiable`은 원문 쪽 사정(봇 차단, 유료 장벽, 응답 없음)만 뜻하며 반박으로 세지 않는다. 검증자 에이전트 자체가 실패하면 워크플로가 그 URL 을 검증 실패 목록에 넣는다.

**지도 대조 출력.** 검증자는 근거 지도의 칸마다 `row`, `column`, `grounded`(참·거짓), `source_ref`(근거가 된 통과 목록 항목)를 내고, 출력 전체에 `principles_applied`를 둔다.

**워크플로 반환값.** 통과 목록, 탈락 목록, 판정 불가 목록, 검증 실패 목록, 하위 질문별 커버리지 표·`search_status`·`verification_status`, `overall_status`, 질의 경계 위반 목록, 실행한 검증자 수다.

**키 이름과 바깥 형식.** 워크스트림 사이에서 주고받는 JSON 의 키는 아래와 같다. 이 표는 계약 코드 `scripts/prior_art_contract.json`을 사람이 읽도록 옮겨 적었고, 둘이 다르면 계약 코드를 따른다(「다시 나눈 분할」).

| 자료 | 형식 |
|---|---|
| 워크플로 `args`(프로토콜) | `{ question, situation, target, mode: "contrast"\|"survey", round: 1\|2, subquestions: [{ id, scope, include, exclude }], forbidden_terms: [string], researcher_count, researcher_count_basis, principles_path }`. `round`는 첫 실행이 1, 공백 라운드가 2 다 |
| 연구자 출력 | 현행 렌즈 칸(`agent`로 바꾼 칸 포함)에 위 표의 칸을 더한다. `evidence_map` 행은 `{ case, url, axes: { purpose, mechanism, evaluation, target }, outcome, kind, source_level, route, adoption? }`다 |
| 종합 모드 연구자 출력 | `{ evidence_map: [행], conclusions: [{ text, refs: [string] }], principles_applied }` |
| 검증자 인용 판정 출력 | `{ url, judgments: [{ ref, verdict, quote, reason }], principles_applied }`. `ref`의 형식은 「결정 기록」의 주장 참조 형식이다 |
| 검증자 지도 대조 출력 | `{ cells: [{ row, column, grounded, source_ref }], principles_applied }` |
| 워크플로 반환값 | `{ round, passed, rejected, unverifiable, verify_failed: [{ url, refs }], coverage: [{ id, cases_found, passed }], subquestion_status: [{ id, search_status, verification_status }], overall_status, query_violations: [{ id, query, rule }], verifier_count, researchers, verifiers, synthesis?, map_check? }`. `passed`·`rejected`·`unverifiable`의 원소는 `{ ref, urls }`이고, `verifier_count`는 인용 판정 검증자 수다. `overall_status`는 `ok`나 `not-ok`다 |

**에이전트에게 보내는 프롬프트.** 워크플로는 연구자와 검증자에게 보내는 프롬프트의 첫 줄을 `MODE: <모드>`로 쓴다. 모드 값은 연구자가 `explore`·`synthesize`, 검증자가 `cite`·`map`이다. 둘째 줄부터 `PRINCIPLES: <principles_path>`를 두고, 그 아래에 모드별 입력을 JSON 블록 하나로 둔다. 연구자 탐색 모드의 입력은 `{ question, situation, target, mode, subquestion, forbidden_terms }`, 종합 모드의 입력은 `{ question, target, passed_rows }`, 검증자 인용 판정 모드의 입력은 `{ url, claims: [{ ref, text }] }`, 지도 대조 모드의 입력은 `{ evidence_map, passed }`다. 에이전트 정의의 모드 처리 단락은 이 첫 줄로 모드를 고른다.

**`principles_applied`가 빈 때.** 오케스트레이터는 그 사실을 보고에 적고 자동으로 다시 실행하지 않는다(현행 `aggregating-lenses`의 규칙을 옮긴다).

**판정 모델 교체.** 빌더는 검증자의 출력 형식을 판정 모델과 무관하게 정한다. 그래서 검증자 정의의 `model`만 바꾸면 Haiku 같은 다른 모델로 판정 단계를 바꿀 수 있다. 판정 전용 모델(예: Typesafe AI 의 Jev)도 쓸 수 있게 되면 같은 방식으로 바꿀 수 있다. 다만 Kim 등은 제공사가 달라도 오류 상관이 높다고 보고했으므로, 모델을 바꿔도 상관 오류가 줄어든다고 기대하지 않는다. Jev 는 이 PC에 키가 없고 사내 문서를 외부 API 로 보내는 데 회사 승인이 필요하므로 구성에 넣지 않는다.

## 인용 확인

인용 검증은 검증자와 오케스트레이터가 나눠 맡는다. 사용자가 2026-10-18에 이 분담을 정했다. 현행 규칙("메인 세션이 자기 도구로 하며 플러그인에 스크립트를 싣지 않는다")만으로는, 연구자가 늘어날 때 오케스트레이터가 인용 수십 건을 직접 열어야 하기 때문이다.

오케스트레이터는 검증자의 `quote`가 원문에 있고 주장을 뒷받침하는지 직접 열어 확인한다. 확인할 인용의 범위는 상황마다 다르다. spec 대조와 제안서 검진에서는 문서를 실제로 고치게 만들었거나 `🔴`로 올릴 발견, 그리고 사용자에게 전달할 발견이 근거로 삼은 인용 전부를 확인한다. 기존 도구 탐색, 결정 근거 탐색, 사실 확인에서는 보고의 결론 문장에 직접 쓰는 인용만 확인하고, 근거 지도의 나머지 행은 검증자 판정을 그대로 둔다.

이 절이 범위 문장의 원본이다. 빌더는 현행 `review-specs` 「웹에 나가는 렌즈의 인용 검증」의 범위 문장을 이 절로 옮기고, 그 절은 이 절을 가리키게 한다.

## 기존 파일과의 관계

**참조 처리 규칙.** 빌더는 `lens-prior-art`라는 이름과, 이 렌즈를 전제로 한 문장을 저장소에서 모두 찾아 처리한다. 대상은 이 렌즈의 절 이름(「실행할 때 지킬 상한」「가드」「기계에 넘기는 것」 등)을 가리키는 포인터, '필요할 때 그룹'·'선행연구 렌즈'·'웹에 나가는 렌즈'를 전제로 한 문장, `search_status`를 렌즈 칸으로 다룬 문장이다. 처리는 `agent-prior-art`의 해당 절을 가리키게 바꾸거나, 더 이상 해당하지 않으면 지우는 것이다. 빌더는 처리한 문장 목록을 plan 에 열거한다. 완료 조건은 `docs/superpowers/reviews/`와 `docs/superpowers/specs/`와 `docs/superpowers/plans/` 밖에서 `grep -rn "lens-prior-art"`의 결과가 아래 예외뿐인 상태다. 예외는 옛 이름을 일부러 포함하는 파일이다. `docs/domain-discipline.md`의 과거 측정 서술(빌더는 그 절 끝에 "2026-10-18 삭제, `agent-prior-art`로 대체"를 적는다), `agent-prior-art`의 description, 옛 이름을 주제어로 쓰는 넛지 훅, 옛 이름을 단언 문자열로 쓰는 `scripts/test_hooks.sh`와 `scripts/test_docs_drift.sh`가 그 파일이다. plan 리뷰에서 처음 예외가 domain-discipline 하나뿐이라 이 설계가 만드는 넛지 주제어와 description 과 충돌한다는 지적이 나와 예외를 넓혔다.

파일마다 반드시 바뀌는 내용은 아래와 같다. 이 표는 참조 처리 규칙을 대신하지 않는다.

| 파일 | 반드시 바뀌는 내용 |
|---|---|
| `skills/lens-prior-art/` | 디렉터리를 지운다. 판정 규약·출력 스키마·레퍼런스 프롬프트는 `agent-prior-art`로 옮긴다 |
| `skills/review-specs/SKILL.md` | 선행연구 제안·승인·판정 기록·서브 세션 처리를 `agent-prior-art` 「발동과 기록」으로 가리킨다. '통상과 최대한 중 고르기'를 프로토콜 승인으로 바꾸고, 단계 상한을 넘으면 다음 단계로 미루는 문장을 지운다. `🔴` 조건의 "search_status 가 ok이면"을 "`overall_status`가 `ok`이면"으로 바꾼다. 「`prior-art` 기록에 적을 것」에 프로토콜 전문, 탈락·판정 불가·검증 실패 목록, 질의 경계 위반을 추가한다 |
| `skills/review-docs/SKILL.md` | 선행연구 제안 문장과 질의 경계 포인터를 `agent-prior-art`로 바꾼다. 「기록 파일 이름 규칙」에 `prior-art` 종류의 원본 파일 규칙을 추가한다 |
| `skills/dispatching-lenses/SKILL.md` | 「렌즈 그룹」 표의 `lens-prior-art` 행과, 이 렌즈만 쓰던 자세 '외부 탐색'의 정의 문장, 상한·발동 기준 문장을 지운다 |
| `skills/aggregating-lenses/SKILL.md` | 리뷰 산출물 계약의 `lens` 열거, 「공통 계약의 예외」, 「렌즈가 추가하는 칸」에서 `lens-prior-art`와 그 칸을 지우고, 표 아래의 `search_status` 문장을 `purpose`만 남게 고친다 |
| `skills/nested-orchestration/references/sub-session-protocol.md` | '사용자 승인이 필요한 렌즈'와 '렌즈 그룹 판정' 행에 선행연구 에이전트를 함께 적고, `agent-prior-art` 「발동과 기록」의 서브 세션 규칙을 가리킨다 |
| `skills/domain-plugin/SKILL.md` | 컴포넌트 위치 목록에 `workflows/`를 추가한다. 이름 규칙에 "사용자와 여러 턴을 주고받는 절차와 서브에이전트 정의와 워크플로를 묶은 구성은 `agent-` 접두사를 쓴다"를 추가한다 |
| `agent-principles.md` | `LENS-ALLOWED`의 예시 "웹에 나가는 `lens-prior-art` 등"을 지우고 규칙 문장은 그대로 둔다 |
| `docs/domain-discipline.md` | `LENS-ALLOWED` 절에 예시 삭제와 클린룸 시험 생략을 적는다. 사용자가 2026-10-18에 생략을 정했고, 지시 내용이 바뀌지 않는다는 것이 이유다 |
| `scripts/test_docs_drift.sh` | `canon: 선행연구 렌즈를 이름으로 예외` 검사와, review-docs 가 「웹에 나가는 렌즈의 인용 검증」을 가리키는지 보는 검사를 새 포인터에 맞춘다. 연구자 프롬프트 대조 검사를 추가한다 |
| `scripts/test_hooks.sh` | 발동 넛지의 동작 검사와 OFF 검사를 추가한다 |
| `README.md` | 「하드 게이트와 넛지와 전역 설정 수정」 절의 훅 표에 발동 넛지 행을 추가한다. 「끄는 법」에는 `DISCIPLINED_CODER_PRIOR_ART_NUDGE=off`를 추가하고 '두 변수' 문장을 변수 수에 맞게 고친다 |

봉인된 지난 리뷰 기록과 지난 spec 안의 `lens-prior-art` 이름은 고치지 않는다. 기록은 당시의 결과를 그대로 남기기 때문이다.

발동 장치는 사용자가 2026-10-18에 정했다. 설계 세션은 Workflow·Agent 호출 직전에 한 번 거부하는 훅을 권했으나, 사용자는 사용자 메시지의 키워드 넛지를 골랐다. 빌더는 발동 넛지를 만들 때 `domain-plugin`의 훅 규칙을 따른다.

## 시험 계획

이 시험은 병합 전 게이트다. 모든 워크스트림이 통합 브랜치에 들어온 뒤 현재 세션이 사용자와 함께 시험을 실행하고, 채택 기준을 통과해야 main 에 병합한다. 통과하지 못하면 병합하지 않고 결과를 사용자에게 보고한다. 사용자가 2026-10-18에 이 게이트와 판정 기준을 정했다.

**실행 환경.** 빌더는 브랜치 작업 트리를 `claude --plugin-dir <작업 트리 경로>`로 적재한 새 세션에서 시험한다. 설치된 플러그인은 main 커밋의 캐시로 실행되므로, 그 캐시로는 브랜치의 구성을 시험할 수 없다.

**과제.** 이 spec 의 바탕이 된 대화에서 실제로 다룬 질문을 쓴다.

- **기존 도구 탐색** — "선행연구에 쓸 만한 에이전트 플러그인이 있는가"
- **결정 근거 탐색** — "에이전트원칙의 목차를 어떤 기준으로 배치해야 하는가"
- **spec 대조** — `docs/superpowers/specs/2026-10-09-nested-orchestration-large-dev-design.md`

빌더가 과제마다 프로토콜을 미리 쓰고, 사용자가 한 번에 승인한다. 시험 실행에서는 공백 라운드를 실행하지 않으므로 실행마다 사용자 응답을 기다리지 않는다.

**조건.**

- **기준선** — 커밋 `7a2d26d`의 `skills/lens-prior-art/SKILL.md` 레퍼런스 프롬프트에 `queries` 칸만 추가해 general-purpose 서브에이전트로 실행한다.
- **새 에이전트** — 탐색 워크플로를 실행한다.
- **Haiku 검증자** — 새 에이전트 조건의 연구자 출력을 그대로 두고, 같은 URL 들을 `model: haiku` 검증자에게 다시 판정시킨다.

기준선과 새 에이전트는 하위 질문 분해와 연구자 수가 같다. 기준선 출력의 인용도 새 에이전트와 같은 세션 모델 검증자에게 판정시켜, 두 조건의 '통과 사례 수'를 같은 방식으로 센다. 실행은 과제마다 조건별로 1회차끼리, 2회차끼리 짝지어 비교한다.

**측정값.**

- **통과 사례 수** — 검증자가 `supported`로 판정한 주장에 기댄 사례 수다. 판정 목록 `passed`만 세고 `verify_failed`는 세지 않는다. 이슈 항목과 근거 지도 항목을 따로 세며, 채택 기준의 비교는 기준선에도 있는 이슈 항목으로 한다.
- **런타임 동작** — 런타임이 스크립트를 엄격 모드로 실행하는지, 긴 URL 을 넣은 `label`이 동작하는지, `agentType`과 정의의 `model` 중 어느 쪽 모델로 실행되는지를 기록한다(`specworkflow` 리포트의 제안).
- **오인 수** — 네 축 대조에서 다른 사례를 같은 사례로 적은 수다. 오케스트레이터가 원문으로 판정하고 사용자가 표본 세 건을 확인한다.
- **질의 경계 위반 수** — 스크립트 검사의 결과다.
- **토큰 사용량** — 런타임이 보고하는 값이다.
- **Haiku 오판 수** — 세션 모델 검증자와 Haiku 검증자의 판정이 다른 주장에 대해, 오케스트레이터가 원문으로 어느 쪽이 틀렸는지 판정한 수다. 검증자별로 세며, 사용자가 표본 세 건을 확인한다.
- **발동 시험** — 아래 메시지에서 넛지와 오케스트레이터의 반응을 본다.
  - 과제 요청 메시지 세 개에서는 넛지가 뜨고 오케스트레이터가 `agent-prior-art`를 연다.
  - '선행연구'를 언급만 하고 요청하지 않는 메시지 세 개에서는 넛지가 뜨지 않는다.
  - 첫 요청을 마친 같은 세션의 두 번째 요청 하나에서도 넛지가 뜨고 오케스트레이터가 `agent-prior-art`를 연다.
  - "선행연구렌즈로 뒤져봐" 하나에서 넛지가 뜬다.
- **넛지 실행 시간** — 발동 넛지 훅 한 번의 실행 시간이다. 빌더가 측정해 기록하고 사용자에게 보고한다.
- **턴 상한 실측** — `maxTurns` 20 에 이른 연구자의 도구 호출 수다.

**채택 기준.** 아래 판정은 짝지은 두 비교 모두에서 성립해야 한다.

- 새 에이전트의 통과 사례 수가 기준선의 90% 이상이다.
- 새 에이전트의 오인 수와 질의 경계 위반 수가 기준선 이하다.
- 발동 시험의 모든 항목이 성립한다.

토큰 사용량이 기준선의 3배를 넘으면 빌더는 채택 기준과 별도로 사용자에게 채택 여부를 묻는다. Haiku 오판 수가 세션 모델 검증자 이하이면 빌더는 검증자 정의의 기본 `model`을 `haiku`로 둔다.

90%와 3배와 표본 세 건은 설계 세션이 제안하고 사용자가 승인한 값이며 출처는 없다.

## 열린 위험

**검증자의 상관 오류.** 검증자와 연구자는 같은 모델 계열이다. 지지 구절 필수와 오케스트레이터의 인용 확인이 이 오류를 줄이지만, 같은 오독을 공유하는 오류는 남는다.

**비용과 속도 제한.** Anthropic 은 다중 에이전트 구성이 채팅의 약 15배 토큰을 쓴다고 보고했다. 검증자 수에는 상한이 없고 단계당 상한을 풀었으므로, 동시 호출이 속도 제한에 걸릴 수 있다. 검증 실패 목록과 `verification_status`가 이 실패를 드러내지만 막지는 않는다.

**런타임 의존.** 선행연구 에이전트는 Claude Code 워크플로 런타임, 플러그인 `workflows/` 배포, `agentType`의 플러그인 에이전트 해석에 의존한다. 워크플로가 꺼진 환경의 대체 경로는 가드를 지시 준수에 기댄다.

**발동 누락.** 발동 넛지는 사용자 메시지의 표현에 기대므로, 목록에 없는 말로 요청하면 알림이 뜨지 않는다. 빌더는 발동 시험으로 이 위험을 확인한다.


## 워크스트림 분할

이 절은 `nested-orchestration`의 임시 분할이다. 개발 이름은 `prior-art-agent`, 통합 브랜치는 `dev/prior-art-agent`다. 사용자가 2026-10-18 이 개발을 `nested-orchestration`으로 진행하라고 지시했다.

**하위 프로젝트와 임시 워크스트림.**

| 임시 id | 맡는 일 | 예상 태스크 |
|---|---|---|
| `specworkflow` | `workflows/prior-art-search.js`와 그 시험 도구 `scripts/workflow_harness.mjs`, 계약 테스트 `scripts/test_workflow.sh` | 시험 도구, 계약 테스트, 순수 함수, 실행 흐름 |
| `specagents` | 「구성」의 오케스트레이터 스킬·연구자 정의·검증자 정의·발동 넛지와, 「기존 파일과의 관계」 절 전체(표의 모든 행과 참조 처리 규칙, `lens-prior-art` 삭제) | 스킬 본문, 연구자·검증자 정의, 넛지와 그 연결·README, 렌즈 집계·호출 스킬 정리, 리뷰 스킬 정리, 원칙·근거 문서와 `domain-plugin` 정리, drift 검사와 완료 검사, `lens-prior-art` 삭제 |

`specagents`는 처음에 스킬·에이전트 정의, 넛지, 참조 처리로 나눴던 세 하위 프로젝트를 합친 것이다. 스킬·에이전트 정의는 「스킬 등재」 검사(`scripts/test_docs_drift.sh`)를 통과하려면 다른 스킬이 `agent-prior-art`를 불러야 하고, 그 포인터는 참조 처리가 만든다. 참조 처리는 스킬·에이전트 정의가 만드는 절을 가리킨다. 두 하위 프로젝트가 서로에게 검증 의존하는 순환이라 4차 리뷰 뒤 사용자가 합치기로 정했다. 넛지는 다른 하위 프로젝트와 주고받는 값이 스킬 이름 하나뿐이라 같은 결정에서 함께 합쳤다. `lens-prior-art`의 내용을 옮기는 서브 세션이 원문과 대조한 뒤 직접 지운다.

`specworkflow`의 예상 태스크는 다섯에 못 미쳐 「맡기는 기준」의 크기 조건에 들지 않는다. 사용자 지시로 이 분할을 쓴다.

**공유 항목 표.**

| 항목 | 소유 | 사용 | 판정 | 고정한 의미 |
|---|---|---|---|---|
| 연구자·검증자·종합·지도 대조 출력의 형식 | `specagents` | `specworkflow` | 떼어냄 | 「출력 스키마」의 칸과 「키 이름과 바깥 형식」 표를 그대로 쓴다 |
| 에이전트에게 보내는 프롬프트의 형식 | `specworkflow` | `specagents` | 떼어냄 | 「출력 스키마」의 「에이전트에게 보내는 프롬프트」를 그대로 쓴다 |
| 에이전트 등록 이름과 `tools`·`maxTurns` | `specagents` | `specworkflow` | 떼어냄 | `disciplined-coder:prior-art-researcher`와 `disciplined-coder:prior-art-verifier`이며, 값은 「구성」을 따른다 |
| 워크플로 `args`와 반환값, 상태 값 | `specworkflow` | `specagents` | 떼어냄 | 「키 이름과 바깥 형식」 표와, 「출력 스키마」의 `search_status`·`verification_status`·`overall_status` 값을 그대로 쓴다 |
| 워크플로 이름 | `specworkflow` | `specagents` | 떼어냄 | 파일 이름과 `meta.name`은 `prior-art-search`이고, 부르는 이름은 `disciplined-coder:prior-art-search`다 |

모든 행을 떼어냄으로 판정했으므로 합칠 묶음이 없다.

**설계 의존 표.** X 를 설계하려면 Y 의 실제 결과를 보아야 하면 1 이다.

| X \ Y | `specworkflow` | `specagents` |
|---|---|---|
| `specworkflow` | — | 0 |
| `specagents` | 0 | — |

**의존 순서 표.**

| 워크스트림 | 선행 | 검증 의존 |
|---|---|---|
| `specworkflow` | 없음 | 없음 |
| `specagents` | 없음 | 없음 |

`specworkflow`와 `specagents`가 모두 시작 워크스트림이라 명세 단계에서 동시에 진행한다. 두 워크스트림의 통합 확인은 저장소 전체 계약 테스트의 `ALL PASS`이며, 상대 워크스트림의 실제 구현을 쓰지 않는다. 두 워크스트림이 함께 고치는 파일은 없다.

**공통 제약.**

- 서브 세션은 자기 브랜치까지만 진행한다. main 병합과 push 는 병합 전 시험을 통과한 뒤 사용자 승인을 받아 현재 세션이 한다.
- 질의 경계와 `SECRETS`를 지킨다. 에이전트 정의와 스킬과 테스트에 키·토큰·개인정보를 적지 않는다.
- 변경 뒤 CLAUDE.md 「변경 뒤 실행」의 명령과 `claude plugin validate ./`를 실행한다.

**현재 세션이 맡는 일.** `agentType`의 플러그인 에이전트 해석은 서브 세션이 새 세션을 열지 못하므로 현재 세션이 확인했다(「결정 기록」의 「런타임 확인」). 병합 전 시험(「시험 계획」)도 사람이 메시지를 입력해야 하므로 모든 워크스트림이 통합된 뒤 현재 세션이 사용자와 함께 진행한다. 두 워크스트림이 통합된 뒤 현재 세션은 `specagents` 「한 번 하는 확인」의 완료 조건 명령을 통합 트리에서 한 번 실행한다. 각 워크스트림 브랜치에는 상대 워크스트림의 파일이 없어, 그 브랜치에서 실행한 확인으로는 통합 트리를 보지 못하기 때문이다.


## 하부 명세

두 임시 워크스트림의 내부 설계는 아래 하부 명세에 있다. 이 큰 명세는 하부 명세 원문을 옮겨 오지 않고 가리킨다.

| 임시 id | 하부 명세 | 리뷰 기록 |
|---|---|---|
| `specworkflow` | `docs/superpowers/specs/2026-10-18-prior-art-agent-specworkflow-design.md` | `docs/superpowers/reviews/2026-10-18-prior-art-agent-specworkflow-review.md` |
| `specagents` | `docs/superpowers/specs/2026-10-18-prior-art-agent-specagents-design.md` | `docs/superpowers/reviews/2026-10-18-prior-art-agent-specagents-review.md` |

## 공유 결정

두 하부 명세가 함께 따르는 결정이다. 현재 세션이 완전체 명세를 쓰며 정했다.

**워크플로 등록 이름.** 오케스트레이터는 탐색 워크플로를 `disciplined-coder:prior-art-search`로 실행하고, 연구자·검증자 정의의 `description`도 그 이름을 적는다. 파일 이름과 `meta.name`은 `prior-art-search`다(「결정 기록」의 「런타임 확인」).

**인용 판정 범위.** 검증자 `cite` 모드는 선행 사례 쪽 서술만 판정한다. 그래서 워크플로가 검증자에게 보내는 `claims[].text`는 이슈 항목이면 `prior_claim`이고, 근거 지도 항목이면 `JSON.stringify({ case, outcome, prior })`다. `prior`는 네 축의 `prior`만 모은 객체다. 판정 기준과 대상은 「출력 스키마」의 「인용 판정 출력」이 원본이다. 2026-10-18 사용자가 이 범위를 골랐다. 대조 대상 쪽 서술까지 판정하면 원문이 그 서술을 뒷받침할 수 없어 항목이 계통적으로 탈락하기 때문이다.

**판정에 쓰는 발견.** 오케스트레이터와 `review-specs`·`review-docs`가 판정과 보고에 쓰는 발견은 `passed`의 `ref`가 가리키는 항목뿐이다. `rejected`·`unverifiable`·`verify_failed`의 항목은 사유와 함께 보고하지만 판정에 쓰지 않는다. 사례 수는 `passed`·`rejected`·`unverifiable` 세 목록으로 세며 `verify_failed`는 세지 않는다.

**옛 이름이 남지 않는 파일.** `specworkflow`가 만드는 `workflows/`와 시험 도구와 계약 테스트에는 옛 이름 `lens-prior-art`를 쓰지 않는다. 그래서 `specagents`의 완료 조건 예외에 그 파일들을 넣지 않고, 현재 세션이 통합 트리에서 완료 조건을 확인한다(「현재 세션이 맡는 일」).

## 경계

워크스트림 경계를 넘는 자료의 원본은 아래와 같다. 한 하부 명세가 정하고 다른 하부 명세는 그 정의를 가리킨다.

| 자료 | 정한 곳 | 가리키는 곳 |
|---|---|---|
| 프롬프트의 JSON 블록 표기(셋째 줄부터 json 코드 울타리 안의 `JSON.stringify(입력, null, 2)`) | `specworkflow` 「프롬프트와 입력」 | `specagents` 「연구자와 검증자 정의」의 공통 단락 |
| 인용 판정 입력 `claims[].text`의 형태 | `specworkflow` 「판정 함수」의 `groupByUrl` 항목 | `specagents` 「연구자와 검증자 정의」의 `cite` 모드 단락 |
| 종합 모드 입력 `passed_rows`와 지도 대조 입력 `passed`의 원소 `{ ref, row }` | `specworkflow` 「용어」의 '통과 행'과 「프롬프트와 입력」 | `specagents` 「연구자와 검증자 정의」의 `synthesize`·`map` 모드 단락 |
| 반환값 `researchers`·`verifiers`의 원소 형식 | `specworkflow` 「반환값의 형식」 | `specagents` 「절차의 연결」 |
| `verify_failed`의 원소와 탈락·판정 불가·검증 실패의 사유 위치 | `specworkflow` 「목록의 행선지」 | `specagents` 「절차의 연결」 |
| `synthesis`가 `null`인 두 사정(통과 행이 없어 생략, 종합 실패)과 `query_violations[].rule`의 값 `forbidden-term`·`path-shape` | `specworkflow` 「반환값의 형식」·「판정 함수」 | `specagents` 「절차의 연결」 |
| 연구자 출력의 `issues[].prior_claim`과 `axes` 축 값 `{ prior, same, note }` | `specagents` 「출력 스키마를 옮기는 규칙」 | `specworkflow` 「판정 함수」의 `groupByUrl` 항목 |

## 겹침 판정

| 대상 | 하부 명세 | 판정 | 이유 |
|---|---|---|---|
| 워크플로를 실행하는 이름 | `specagents` 「절차의 연결」·「연구자와 검증자 정의」, 큰 명세 「오케스트레이터 절차」 | 같은 동작이라 「공유 결정」으로 합쳤다 | 모두 같은 워크플로 하나를 실행하는 동작이다. 실측한 등록 이름 `disciplined-coder:prior-art-search`로 맞췄다 |
| 인용 판정의 입력과 기준 | `specworkflow` 「판정 함수」·「열린 위험」, `specagents` 「연구자와 검증자 정의」·「출력 스키마를 옮기는 규칙」 | 같은 동작이라 「공유 결정」으로 합쳤다 | 워크플로가 보내는 `text`와 검증자가 판정하는 대상은 같은 주장 하나의 두 면이다. 두 쪽이 같은 범위를 써야 판정이 성립한다 |
| 프롬프트 형식과 종합·지도 대조 입력 | `specworkflow` 「프롬프트와 입력」, `specagents` 「연구자와 검증자 정의」·「가정과 남은 위험」 | 경계 자료라 「경계」에 소유 쪽 정의를 적었다 | `specagents`는 `passed_rows`가 주장 참조를 싣는다고 전제했고, `specworkflow`의 `{ ref, row }`가 그 전제를 충족한다 |
| 판정과 보고에 쓰는 목록 | `specworkflow` 「목록의 행선지」, `specagents` 「참조 처리 목록」의 `review-specs` 76행 | 같은 동작이라 「공유 결정」으로 합쳤다 | 두 쪽 모두 통과한 사례만 판정에 쓰는 동작이다. `specagents`의 문안이 그 목록을 `passed`로 한정하지 않아 맞췄다 |
| 완료 조건의 예외 파일 | `specagents` 「한 번 하는 확인」 | 같은 동작이라 「공유 결정」으로 합쳤다 | 옛 이름이 남지 않았는지 보는 확인 하나다. `specworkflow` 파일은 옛 이름을 쓰지 않으므로 예외에 넣지 않는다 |
| `agentType` 해석 전제 | `specworkflow` 「맡는 일과 전제」, `specagents` 「가정과 남은 위험」 | 같은 전제라 「결정 기록」의 「런타임 확인」으로 처분했다 | 두 하부 명세가 같은 미확인 전제를 적었고, 현재 세션이 실측으로 확인했다 |

## 다시 나눈 분할

이 절이 구현 단계의 분할이며, 「워크스트림 분할」의 임시 분할을 대체한다. 임시 분할의 「공통 제약」과 「현재 세션이 맡는 일」은 아래에 새 워크스트림 id 로 다시 적었다.

**하위 프로젝트와 공유 항목.** 완전체 명세의 하위 프로젝트는 탐색 워크플로와, 스킬·에이전트 정의·넛지·참조 처리 두 가지다. 현재 세션은 이 목록으로 「묶는 단위」를 다시 실행했다.

| 항목 | 소유 | 사용 | 판정 | 고정한 의미 |
|---|---|---|---|---|
| 연구자·검증자·종합·지도 대조 출력의 형식 | `agents` | `workflow` | 떼어냄 | 계약 코드 `scripts/prior_art_contract.json`과 아래 계약 표 |
| 에이전트에게 보내는 프롬프트의 형식 | `workflow` | `agents` | 떼어냄 | 「출력 스키마」의 「에이전트에게 보내는 프롬프트」와 「경계」 |
| 에이전트 등록 이름 | `agents` | `workflow` | 떼어냄 | `disciplined-coder:prior-art-researcher`, `disciplined-coder:prior-art-verifier` |
| 워크플로 등록 이름 | `workflow` | `agents` | 떼어냄 | `disciplined-coder:prior-art-search` |
| 워크플로 `args`와 반환값, 상태 값 | `workflow` | `agents` | 떼어냄 | 계약 코드와 아래 계약 표 |

**설계 의존 표.**

| X \ Y | `workflow` | `agents` |
|---|---|---|
| `workflow` | — | 0 |
| `agents` | 0 | — |

**워크스트림 목록.**

| 워크스트림 id | 맡는 일 | 예상 태스크 |
|---|---|---|
| `workflow` | 탐색 워크플로 `workflows/prior-art-search.js`, 시험 도구 `scripts/workflow_harness.mjs`, 그 테스트 `scripts/test_workflow.sh` | 시험 도구, 판정 함수, 실행 흐름, 테스트 |
| `agents` | 스킬 `skills/agent-prior-art/SKILL.md`, 연구자·검증자 정의, 발동 넛지와 그 연결·README, 「기존 파일과의 관계」의 참조 처리, `skills/lens-prior-art/` 삭제 | 스킬 본문, 연구자·검증자 정의, 넛지와 연결, 렌즈 집계·호출 스킬 정리, 리뷰 스킬 정리, 원칙·근거 문서 정리, drift 검사와 삭제 |

`workflow`의 예상 태스크는 다섯에 못 미쳐 「맡기는 기준」의 크기 조건에 들지 않는다. 사용자 지시로 이 분할을 쓴다(「워크스트림 분할」).

**의존 순서 표.**

| 워크스트림 | 선행 | 검증 의존 |
|---|---|---|
| `workflow` | 없음 | 없음 |
| `agents` | 없음 | 없음 |

두 워크스트림 모두 시작 워크스트림이다. 시작 의존과 검증 의존을 합친 그래프에 순환이 없고, 병합 차례는 끝나는 차례를 따른다.

**통합 확인.** 현재 세션은 워크스트림마다 CLAUDE.md 「변경 뒤 실행」의 검사 스크립트 전체가 `ALL PASS`를 내는지와 `claude plugin validate ./`가 새 경고 없이 통과하는지를 본다. 검사 스크립트에는 계약 테스트 `scripts/test_prior_art_contract.sh`가 들어 있다. 두 워크스트림이 모두 통합된 뒤 현재 세션은 `specagents` 하부 명세 「한 번 하는 확인」의 완료 조건 명령을 통합 트리에서 한 번 실행한다. 이때 계약 코드 두 파일은 옛 이름을 쓰지 않으므로 예외 목록에 넣지 않는다.

**공통 제약.**

- 서브 세션은 자기 브랜치까지만 진행한다. main 병합과 push 는 병합 전 시험을 통과한 뒤 사용자 승인을 받아 현재 세션이 한다.
- 질의 경계와 `SECRETS`를 지킨다. 에이전트 정의와 스킬과 테스트에 키·토큰·개인정보를 적지 않는다.
- 변경 뒤 CLAUDE.md 「변경 뒤 실행」의 명령과 `claude plugin validate ./`를 실행한다.
- 하부 명세 파일은 서브 세션의 허용 경로에 들지 않는다. 하부 명세를 고쳐야 하면 `BLOCKED shared-file-change`로 요청한다.

**수정 허용 경로.** 아래는 git pathspec 이다. 두 목록에 함께 드는 경로는 없다. 모든 워크스트림의 허용 경로에는 자기 문서 경로(`nested-orchestration` 「경로와 브랜치 이름」)가 기본으로 들어간다.

| 워크스트림 | 허용 경로 |
|---|---|
| `workflow` | `workflows/prior-art-search.js`, `scripts/workflow_harness.mjs`, `scripts/test_workflow.sh` |
| `agents` | `skills/agent-prior-art/**`, `skills/lens-prior-art/**`, `skills/review-specs/SKILL.md`, `skills/review-docs/SKILL.md`, `skills/dispatching-lenses/SKILL.md`, `skills/aggregating-lenses/SKILL.md`, `skills/audit-repo-docs/SKILL.md`, `skills/lens-fit/SKILL.md`, `skills/domain-plugin/SKILL.md`, `skills/nested-orchestration/SKILL.md`, `skills/nested-orchestration/references/sub-session-protocol.md`, `agents/prior-art-researcher.md`, `agents/prior-art-verifier.md`, `hooks/prior_art_nudge_userpromptsubmit.sh`, `hooks/hooks.json`, `README.md`, `scripts/test_hooks.sh`, `scripts/test_docs_drift.sh`, `scripts/test_audit.sh`, `agent-principles.md`, `docs/domain-discipline.md` |

**소유 표.**

| 공용 파일 | 소유 | 비고 |
|---|---|---|
| `scripts/prior_art_contract.json` | 현재 세션 | 계약 코드. 키 이름과 형식의 원본이다 |
| `scripts/test_prior_art_contract.sh` | 현재 세션 | 계약 테스트 |

이 저장소에는 의존성 목록과 잠금 파일이 없다. 마지막 시험 병합 뒤 현재 세션은 계약 테스트의 생략 분기를 지우고, 계약 테스트는 두 워크스트림 사이의 형식 드리프트를 잡는 검사로 남긴다.

**계약 코드와 계약 테스트.** 이 개발의 계약은 함수 계약이 아니고, 워크플로와 에이전트 정의가 실행 중에 주고받는 JSON 의 형식 계약이다. 계약 코드 `scripts/prior_art_contract.json`은 자료마다 반드시 있어야 하는 키를 중첩 구조 그대로 적는다. 키 이름과 형식은 이 파일이 원본이며, 「출력 스키마」의 「키 이름과 바깥 형식」 표는 사람이 읽도록 같은 내용을 옮겨 적었다. 둘이 다르면 계약 코드를 따른다.

계약 테스트는 두 곳을 읽어 계약 코드와 대조한다.

- **워크플로의 스키마** — 워크플로 스크립트는 최상위 `function schemas()`가 `{ RESEARCHER_SCHEMA, VERIFIER_SCHEMA, SYNTHESIS_SCHEMA, MAP_SCHEMA }`를 돌려주게 둔다. 계약 테스트는 `printf '[]' | node scripts/workflow_harness.mjs fn schemas`로 그 값을 얻는다. 시험 도구의 `fn`은 판정 함수와 함께 `schemas`를 받는다.
- **에이전트 정의의 출력 형식 블록** — 연구자·검증자 정의는 출력 형식마다 `<!-- output: <자료 이름> -->` 한 줄 바로 다음에 json 코드 블록을 둔다. 자료 이름은 `researcher`·`synthesis`·`verifier`·`map`이다. 블록은 그 자료의 예시 JSON 하나이며 `JSON.parse`로 읽혀야 한다.

계약 테스트는 각 자료에서 계약 코드의 키가 스키마의 `properties`와 예시 JSON 에 모두 있는지 본다. 워크플로 스크립트가 없으면 `workflow`를, 에이전트 정의가 없으면 `agents`를 생략 사유에 적고 그 대조를 생략한다.

**계약 표.**

| 이름 | 제공자 → 소비자 | 형식 | 단위 | 의미(시간·결측 포함) |
|---|---|---|---|---|
| `scripts/prior_art_contract.json`의 `args` | `agents`(오케스트레이터 스킬) → `workflow` | 「키 이름과 바깥 형식」의 프로토콜 객체 | 없음 | 실행 한 번에 하나다. `round`는 첫 실행 1, 공백 라운드 2 다. 결측은 없다(오케스트레이터가 모든 키를 채운다) |
| `scripts/prior_art_contract.json`의 `researcher` | `agents`(연구자 정의) → `workflow` | 연구자 출력. 이슈 원소는 `prior_claim`과 `citations`를, 근거 지도 행은 `case`·`url`·`axes`·`outcome`을, `axes`는 네 축을, 축은 `prior`·`same`·`note`를 반드시 가진다. 워크플로 스키마의 `required`도 이 칸을 강제한다 | 없음 | 하위 질문 하나에 한 번 나온다. `evidence_map`이 없으면 빈 배열로 본다. 공백만 있거나 빈 `prior_claim`, 빈 `case`, 네 축의 `prior`가 모두 빈 행은 판정 근거가 없으므로 `workflow`가 검증자에게 보내지 않고 `rejected`에 둔다(사유 '판정할 선행 사례 서술이 없다'). 연구자가 실패하면 `null`이며 그 하위 질문의 `search_status`는 `failed`다 |
| `scripts/prior_art_contract.json`의 `verifier` | `agents`(검증자 정의) → `workflow` | `{ url, judgments: [{ ref, verdict, quote, reason }], principles_applied }` | 없음 | URL 하나에 한 번 나온다. 보낸 `ref`의 판정이 하나라도 빠지면 그 검증자는 실패로 본다. 결측(`null`)은 `verify_failed`로 간다 |
| `scripts/prior_art_contract.json`의 `synthesis`·`map` | `agents` → `workflow` | 「키 이름과 바깥 형식」의 두 행 | 없음 | `survey`에서만 최대 한 번씩 나온다. 통과 행이 없으면 종합을 실행하지 않고, 종합 결과가 `null`이면 지도 대조를 실행하지 않는다. 그래서 `synthesis`가 `null`이면 `map_check`도 `null`이며, 두 값은 `overall_status`에 영향이 없다 |
| 에이전트에게 보내는 프롬프트 | `workflow` → `agents`(두 정의) | 첫 줄 `MODE: <모드>`, 둘째 줄 `PRINCIPLES: <경로>`, 셋째 줄부터 json 코드 울타리 안의 `JSON.stringify(입력, null, 2)` | 없음 | 호출마다 하나다. 입력 키는 「에이전트에게 보내는 프롬프트」가 정한다. 인용 판정 입력의 `claims[].text`는 이슈면 `prior_claim`, 근거 지도 행이면 `JSON.stringify({ case, outcome, prior })`다. 종합 입력 `passed_rows`와 지도 대조 입력 `passed`의 원소는 `{ ref, row }`다. 결측은 없다 |
| `scripts/prior_art_contract.json`의 `result` | `workflow` → `agents`(오케스트레이터 스킬) | 「키 이름과 바깥 형식」의 반환값. `researchers`는 `[{ id, output }]`, `verifiers`는 `[{ url, subquestions, output }]`, `query_violations[].rule`은 `forbidden-term`·`path-shape` | 사례 수는 건수 | 실행 한 번에 하나다. 판정에 쓰는 발견은 `passed`뿐이다(「공유 결정」). 실패한 연구자와 검증자는 `output: null`이다. 탈락·판정 불가의 사유는 같은 `ref`의 `verifiers[].output.judgments[]`에, 검증 실패의 사유는 같은 `url`의 `verifiers[].output`에 있다. `synthesis: null`의 두 사정은 `passed`에 `#case#` 항목이 있는지로 구별한다 |
| 에이전트 등록 이름 | `agents` → `workflow` | `disciplined-coder:prior-art-researcher`, `disciplined-coder:prior-art-verifier` | 없음 | 의미는 이름 그대로다. 시간과 결측은 없다 |
| 워크플로 등록 이름 | `workflow` → `agents` | `disciplined-coder:prior-art-search` | 없음 | 의미는 이름 그대로다. 시간과 결측은 없다 |

**절 배정.**

| 워크스트림 id | 하부 명세 파일과 절 | 작성 기록이 있는 리포트 |
|---|---|---|
| `workflow` | `docs/superpowers/specs/2026-10-18-prior-art-agent-specworkflow-design.md` 전체 | `<git common dir>/nested/prior-art-agent/report-specworkflow.md` |
| `agents` | `docs/superpowers/specs/2026-10-18-prior-art-agent-specagents-design.md` 전체 | `<git common dir>/nested/prior-art-agent/report-specagents.md` |

두 워크스트림 모두 이 큰 명세의 「출력 스키마」「공유 결정」「경계」「다시 나눈 분할」「결정 기록」을 함께 따른다. 하부 명세와 이 절이 다르면 이 절의 계약 표와 계약 코드를 따른다.

## 결정 기록

이 절은 현재 세션만 쓴다.

**관례 골격.**

- **명명** — 계약 테스트는 `scripts/test_<대상>.sh`이고, 묶음 머리는 `echo "[<묶음 이름>]"`이며, 단언은 `scripts/_test_check.sh`의 `check "<설명>" "<명령>"`으로 쓴다. 새 훅 파일은 `hooks/<이름>_<이벤트 소문자>.sh`로 짓는다(기존 `stop_gates.sh`는 예외다). 끄는 변수는 `DISCIPLINED_CODER_<이름>=off`이고 `${변수:-on}`과 비교한다. 선행연구 에이전트의 원본 파일 이름은 「오케스트레이터 절차」의 「원본 파일 규칙」을 따른다.
- **오류 처리** — 새 훅은 `set -euo pipefail`로 시작하고, 입력을 해석하지 못하면 아무것도 출력하지 않고 0 으로 끝난다(FAIL-OPEN). 워크플로는 `agent()`가 `null`을 돌려주면 예외를 던지지 않고 그 사실을 상태 값과 목록에 반영한다.
- **추상화 수준** — 한 번만 쓰는 함수와 설정 가능성을 두지 않는다. 워크플로의 순수 함수는 결정론으로 검사할 판정(질의 경계 검사, URL 묶기, 통과 판정, 상태 합치기)에만 둔다.
- **디렉터리 구조** — 워크플로는 `workflows/`, 에이전트 정의는 `agents/`, 스킬은 `skills/agent-prior-art/`, 계약 테스트와 시험 도구는 `scripts/`에 둔다.

**공용 유틸리티.** 계약 테스트는 `scripts/_test_check.sh`의 `check`, `scripts/_json_valid.sh`의 `json_valid_stdin`, `scripts/_doc_keys.sh`의 `has_sec`·`sec_has`·`points_to`를 쓴다. 훅은 `hooks/_json_escape.sh`를 쓴다. 넛지 훅은 사용자 메시지 전문을 받으므로 stdin 을 `INPUT="$(cat)"`으로 읽는다(`hooks/_hook_input.sh` 머리 주석의 큰 입력 훅 방식). `hooks/_hook_input.sh`의 `json_str`은 첫 따옴표에서 끊기므로 사용자 메시지를 읽는 데 쓰지 않는다.

**주장 참조 형식.** 검증자 판정의 `ref`는 `<하위 질문 ID>#<issue|case>#<배열 위치>`다. 배열은 연구자 출력의 `issues`나 `evidence_map`이다.

**묶음 FAIL 수 세기.** 묶음 하나의 FAIL 수는 `bash <스크립트> 2>&1 | awk -v h='<묶음 머리>' '$0==h{f=1;next} /^\[/{f=0} f' | grep -c '^  FAIL:'`로 센다. `check`의 실패 줄 머리(`  FAIL: `)만 세므로 요약 줄과 설명문의 'FAIL' 글자를 세지 않는다. 줄 수 창(`grep -A<n>`)으로 세지 않는다.

**선행연구 에이전트가 발동 기준에 들 때(2026-10-18 사용자 답).** 서브 세션 리포트의 `렌즈 그룹 판정`에 선행연구 에이전트가 있으면 현재 세션이 사용자에게 제안하고, 승인받으면 `agent-prior-art` 절차로 직접 실행한다. 그 결과로 하부 명세나 구현을 고쳐야 하면 `REVISE`(명세 서브 세션이면 `RESTART`)로 보낸다. 서브 세션은 선행연구 에이전트를 실행하지 않는다. `specagents`가 `nested-orchestration` `SKILL.md`의 「판정 기록 확인」을 이 내용으로 고친다. 이 개발이 main 에 병합되기 전에는 선행연구 에이전트가 아직 없으므로, 현재 세션은 설치된 캐시의 `lens-prior-art`로 실행한다(같은 날 사용자 답).

**이미 겪은 함정.** 서브 세션은 `docs/superpowers/reviews/2026-10-18-prior-art-agent-plan-review/`의 렌즈 원본을 이미 겪은 함정의 목록으로 읽는다. 그 지적이 인용한 plan 초안은 실행하지 않으며 입력도 아니다. 초안은 커밋 `252155f`에 보존되어 있고, 현재 세션이 명세 디스패치 전에 사용자 확인을 받아 통합 브랜치에서 지운다.

**런타임 확인(2026-10-18).** 현재 세션이 임시 플러그인 `probeplug`를 `claude -p --plugin-dir`로 적재해 워크플로 하나를 실행했다. 그 플러그인은 `workflows/probe.js`(`meta.name: 'probe'`)와 `agents/probe.md`(`tools: Read`)만 두었다. 이름 `probe`로 부르자 "Workflow \"probe\" not found. Available: deep-research, probeplug:probe"가 나왔고, `probeplug:probe`로 부르자 실행되었다. 그래서 플러그인 워크플로는 `<플러그인 이름>:<워크플로 이름>`으로 등록된다. 파일 이름과 `meta.name`이 같았으므로 워크플로 이름이 둘 중 어느 쪽에서 오는지는 확인하지 않았고, 이 저장소도 둘을 `prior-art-search`로 같게 둔다. `agent()`의 `agentType: 'probeplug:probe'`는 그 에이전트 정의로 해석되었고, 에이전트에게는 정의의 `Read`와 스키마용 `StructuredOutput`만 주어졌다. 관측한 정의는 이 하나뿐이지만, 정의의 `tools`가 워크플로 안에서 적용된다는 것은 확인되었다. 같은 임시 플러그인에 `claude plugin validate ./`를 실행했고, `workflows/`와 `agents/`가 있는 트리에서 작성자 정보가 없다는 경고 하나와 함께 `Validation passed with warnings`가 나왔다.

**워크플로 판정의 사용자 확인(2026-10-18 사용자 답).** `workflow` 리포트가 사용자 확인으로 표시한 판정 두 건을 사용자가 그대로 승인했다. 검증자 판정 없이 `rejected`에 든 원소(선행 서술 결측이나 빈 `urls`)에는 반환값에 사유 키를 두지 않고, 오케스트레이터가 사유를 도출한다. `urls`가 비었으면 사유는 '인용에 URL 이 없다'이고, 아니면 '판정할 선행 사례 서술이 없다'다. `args.subquestions`가 빈 배열이면 `overall_status`는 정의대로 `ok`다. 오케스트레이터가 하위 질문을 늘 채우므로 워크플로는 이 입력을 따로 차단하지 않는다.

<!-- spec-review: passed -->
