# 설계 노트 (DESIGN-NOTES)

README에서 분리한 개발자용 내부 근거다. 사용자 설치·사용에는 필요 없지만, "왜 이렇게
동작하는가"의 근거를 보존한다. 사용자용 개요는 [README](../README.md) 참고.

## 저장소 구성

어느 파일이 무슨 일을 하는지 훑을 때 쓴다. 설치해 쓰는 데는 필요 없으므로 README에 두지 않는다.

```
disciplined-coder/
├── .claude-plugin/plugin.json      # 매니페스트
├── agent-principles.md             # 디시플린 정본 (SSOT) — hook이 ~/.claude/disciplined-coder/로 복사
├── domains-index.md                # 도메인 참고서 인덱스 (동일 경로로 복사)
├── skills/domain-*/SKILL.md        # 도메인 참고서(docs/plugin/llm-runtime) + 호출자 domain-spec-review
├── skills/reviewer-*/SKILL.md      # 리뷰어 렌즈(grounding/fit/consistency/adversarial/prior-art/readability)
├── skills/meta-aggregate/SKILL.md  # 리뷰어 집계·결정(코드 설계도)
├── skills/nested-orchestration/SKILL.md # 3층 병렬 오케스트레이션 방법(병렬 오케스트레이션 트리거)
├── hooks/hooks.json                # SessionStart→scaffold · Pre/PostToolUse·Stop→문서·spec/plan 워크플로
├── hooks/spec_review_*.sh          # spec/plan: PostToolUse(감지) · Stop(하드 게이트) — 순수 bash, jq 비의존
├── hooks/doc_*tooluse.sh           # 문서: 양식 제안(Pre) · 검진 넛지(Post) — 비블로킹
├── scripts/scaffold.sh             # 멱등: ~/.claude/disciplined-coder/ 셋업 + ~/.claude/CLAUDE.md @import
├── .codex-plugin/plugin.json       # Codex 매니페스트(skills/hooks/interface)
├── hooks/hooks-codex.json          # Codex 훅 배선(apply_patch matcher · session-start-codex)
├── hooks/session-start-codex       # Codex SessionStart: codex-scaffold 실행 + 원칙 주입 + 신뢰검토 경고
├── hooks/_extract_path.sh          # 공용 경로 추출(file_path + apply_patch, 다중 경로)
├── scripts/codex-scaffold.sh       # 멱등: ~/.codex/ 셋업 + ~/.codex/AGENTS.md 관리블록
├── scripts/test_*.sh               # 계약 테스트(각 FAIL=0). 어떤 것이 있는지는 이 디렉터리가 정본이다
├── scripts/_*.sh                   # 공유 헬퍼(홈 해석·관리블록·JSON 유효성 등)
├── commands/*.md                  # 수동 커맨드(전체 목록은 README '사용 > 커맨드' 절이 정본)
├── docs/DESIGN-NOTES.md            # 개발자용 내부 근거(주입 메커니즘·한계·업그레이드)
└── README.md
```

**위 트리는 주요 파일만 적은 부분 목록이다.** 전체는 저장소를 보라 — 여기에 전부 열거하면 파일이 늘 때마다 이 목록이 먼저 낡는다. `~/.claude/disciplined-coder/`에 생성되는 파일 목록은 scaffold 공통 헬퍼의 `SCAFFOLD_WHITELIST`가 정본이다. 스킬은 플러그인에서 온디맨드로 로드하며 복사하지 않는다.

## 서브에이전트로의 지식 전달

**메모리 계층이 서브에이전트에 실리는지는 에이전트 종류에 따라 갈린다.** 아래가 이 사실의 단일 출처다.

**실측 (2026-07-28, Claude Code 2.1.220)**

열 다섯은 각각 이 플러그인이 `~/.claude/disciplined-coder/`에 두는 원칙 정본, 도메인 참고서 목차,
오답노트, Claude Code가 레포별로 관리하는 자동 메모리의 목차 파일, 그리고 프로젝트 루트의 `CLAUDE.md`가
그 에이전트의 컨텍스트에 실렸는지를 뜻한다.

| 에이전트 종류 | 정본 | 도메인 목차 | 오답노트 | 자동 메모리 목차 | 프로젝트 `CLAUDE.md` |
|---|---|---|---|---|---|
| `general-purpose` | 실린다 | 실린다 | 실린다 | 실린다 | 실린다 |
| `claude` (기본) | 실린다 | 실린다 | 실린다 | 실린다 | 실린다 |
| `Explore` | 실리지 않는다 | 실리지 않는다 | 실리지 않는다 | 실리지 않는다 | 실리지 않는다 |
| `Plan` | 실리지 않는다 | 실리지 않는다 | 실리지 않는다 | 실리지 않는다 | 실리지 않는다 |

**재현 절차** — 같은 질문을 네 종류의 서브에이전트에 던져 각자의 컨텍스트에 무엇이 들어 있는지 묻는다.
도구를 쓰지 말고 이미 실린 것만 보고 답하라고 지시한다. 하니스가 바뀌면 이 표가 낡으므로 측정 날짜와
Claude Code 버전을 함께 둔다.

**측정 방법이 모델의 자기보고라 부재 증명으로는 약하다.** 스무 칸 가운데 외부 증거로 뒷받침된 것은
`Explore`가 스킬 목록의 문구를 인용해 스킬 `description`은 실린다는 것을 보인 한 건뿐이다.

**왜 그 둘만 갈리는지는 측정하지 않았다.** 표본이 넷뿐이고 "쓰기 도구가 없어서"와 "빌트인이라서"가 같은
두 행을 똑같이 설명한다. 도구 보유 여부는 재지 않았으므로 인과를 주장하지 않는다.

**커스텀 서브에이전트는 두 종류만 쟀다.** `general-purpose`와 `claude`가 그것이고, 사용자 정의
서브에이전트는 한 종류도 재지 않았다.

### 리뷰어에게 정본을 알리는 관례
위 실측 표가 이 관례의 근거다 — 리뷰어에게 메모리 계층이 실린다고 가정할 수 없으니 호출자가 따로
알려야 한다. **무엇을 지키는지는 `domain-docs`의 「리뷰어에게 정본을 알리는 법」이 소유자다.** 전에
그 넷을 네 문서가 각자 적었다가 이 자리에서만 둘이 빠져 갈라진 적이 있어, 여기는 근거만 두고 규율은
가리키기만 한다.

## 고치기 전에 알아야 하는 한계

성격이 다른 것을 세 묶음으로 나눠 둔다. 한 줄로 늘어놓으면 자기가 고칠 대목이 여기 있는지를 항목을
끝까지 다 읽어야만 알 수 있다. 개수를 적지 않는 이유는 항목이 늘 때마다 그 숫자가 먼저 낡기
때문이다(`NAME-ITEMS`).

### 어떻게 실려서 도는가
- **플러그인 루트 `CLAUDE.md`는 컨텍스트로 로드되지 않는다.** 주입 경로는 `~/.claude/CLAUDE.md` →
  `@disciplined-coder/...` @import이며, 이 플러그인이 SessionStart hook으로 자동 배선한다. 프로젝트
  폴더에는 아무 파일도 생성하지 않는다.
- **정본 stdout 보강은 첫 세션 1회뿐이다.** 관리 블록을 방금 만든 세션에 한해 정본을 stdout으로 함께
  보내는데, 그 세션에서 자동 압축이 돌면 요약으로 뭉개질 수 있다. 다음 세션부터는 세션 시작 때 `@import`가
  읽은 정본이 그 뒤 요청에도 실린다.
- **hook은 컨테이너가 아니라 호스트 셸에서 돈다**: Windows는 Git Bash가 필요하다. `MSYS_NO_PATHCONV`
  등 Git Bash 전용 gotcha는 mac/Linux/PowerShell 호스트엔 무관하니 보편 규칙으로 적용 금지.
- **SessionStart hook이 도는 계기는 `hooks/hooks.json`의 matcher가 정본이다.** 새 세션뿐 아니라 재개와
  clear에서도 돈다. 스크립트는 멱등이지만 무거운 작업을 넣지 말 것.
- **업데이트는 리로드가 아니라 새 세션에서 반영된다.** 플러그인을 업데이트하고 리로드해도 돌고 있는
  세션은 갱신되지 않는다. 관측된 이유는 세션이 캐시 버전에 묶이는 것으로 보인다는 것이다 — 캐시
  디렉터리에 프로세스 번호 마커가 있고 아무도 안 쓰는 버전에 고아 표시가 찍힌다(2026-07-28 관측, 마커의
  의미론은 하니스 문서로 확인하지 못했다). `/setup-discipline`도 같은 캐시 경로로 치환되므로 소용이
  없다. **사용자가 할 일은 새 세션을 시작하는 것 하나다.** 아래 '원칙 갱신 주기'는 개발자가 레포를
  고쳤을 때를 다루고, 이 항목은 배포본을 쓰는 사람 관점이다.
- **정본을 고치면 다음 세션부터 반영된다**: `agent-principles.md`(SSOT)를 수정하면 다음 세션부터
  `~/.claude/disciplined-coder/`에 새 버전이 복사된다. 소유자와 갱신 주기를 정하라(권장: 분기 1회 검토).
  일반화 가능한 `solved` 항목만 원칙으로 승격한다. 승격 절차는 여기서 정하지 않고 오답노트 머리말이
  정본이다(`domain-docs`가 그 머리말을 갈아끼우는 방법을 소유한다) — 그 로그는 append-only이고 원문을
  보존하므로, 승격은 원칙 쪽에 재기술해 올리는 것이지 로그에서 지우는 것이 아니다.

### 여기서 정하지 않고 다른 문서를 따르는 것
- **🔴는 쟁이지 말고 즉시 알린다**: 이 규칙은 `agent-principles.md`(@import 대상 — scaffold.sh가 배선)에
  박혀 있어 메인 세션에는 전달되지만 서브에이전트는 종류에 따라 갈린다(위 실측 표). 🔴(사용자 결정
  필요)는 어딘가에 쟁여 두지 말고 발견 즉시 사용자에게 알리며, 누구도 자율 구현하지 않는다
  (disciplined-coder는 이슈·백로그를 추적하지 않는다 — 오답노트 절). 다만 CLAUDE.md는 강제가 아니라
  가이드이므로(공식 문서), 진짜로 막아야 한다면 `PreToolUse` hook로 강제하라.

### 안 넣기로 한 것
여기 적힌 것은 결정이지 할 일 목록이 아니다. 손으로 유지하는 미해결 목록을 두지 않는다는 원칙에 따라,
"나중에 다시 본다"는 약속은 적지 않는다 — 조건이 바뀌면 그때 작업이 다시 들춘다.
- **테스트 통과를 결정론적으로 감지하는 PostToolUse hook 보조를 넣지 않았다.** 판별이 취약하고 이득이
  적다고 봤다.
- **ultracode 검증 모드(required)를 넛지 훅으로 승급하지 않았다.** 이 모드는 주입 지시 기반이라 훅
  차단이 아니다 — 모드 라인은 메인 세션에만 도달하고(@import 아님), 서브에이전트 작성 경로에서는
  메인의 스펙 릴레이에 의존하며, 지시 무시를 막을 수 없다. 승급하지 않은 이유는 Workflow 도구에 훅을
  걸 수 있는 자리가 공식 문서에 적혀 있지 않기 때문이다. 이 모드를 도입한 설계 문서는
  `docs/superpowers/specs/2026-07-03-ultracode-review-toggle-design.md`다.

## 왜 spec/plan 리뷰 게이트를 Stop(턴 종료)에 두는가

**강제를 턴이 끝나는 `Stop` 순간에 건 이유는, 훅이 걸 수 있는 이벤트 가운데 종료를 실제로 거부할 수
있는 자리가 거기 하나뿐이고, 턴의 끝이 곧 이번 작업에서 문서가 더 손댈 것 없이 완성된 경계이기
때문이다.** 왜 강제가 필요했는지부터 적는다.

설계 문서(spec/plan)도 Claude가 만든 LLM 산출물이라, 작성자 자기 검토만으로는 확증 편향에 약하다.
그래서 고위험 설계 문서는 독립 렌즈(grounding·consistency·adversarial) 리뷰를 거치게 강제한다. 선행연구 대조는 기본 묶음이 아니라 제안과 승인을 거쳐 따로 돈다
(`agent-principles.md`의 검증 레이어 절). 설계 문서는 구현의 입력이므로, 결함을 설계 단계에서 잡는 편이
구현까지 번진 뒤 잡는 것보다 싸다.

문제는 "강제"를 거는 시점이다. 초기 MVP는 메인 세션이 *절차로* 리뷰를 호출했는데, 이는 작성자
판단으로 건너뛸 수 있어 강제가 아니었다. 그래서 사람 판단에 기대지 않는 결정론적 트리거(훅)를 넣었다
(`FAIL-LOUD` — 구조가 막거나 드러내게, 작성자 기억에 의존하지 말 것).

훅을 "brainstorming/플래너가 끝났을 때"에 걸 수는 없다. Claude Code 훅은 구체적 이벤트(도구 호출,
프롬프트 제출, 턴/세션 종료)에만 걸리고, "스킬의 창작 과정이 끝났다"는 의미론적 상태에 대응하는 이벤트가
없다. brainstorming·writing-plans는 메인 세션에서 여러 턴에 걸쳐 도는 대화형 과정이라, 완료 순간이 단일
이벤트로 찍히지 않는다(서브에이전트가 아니므로 `SubagentStop`도 해당 없음).

그래서 설계를 두 조각으로 나눴다. 감지는 `PostToolUse`가, 강제는 `Stop`이 맡는다.
- **`PostToolUse`(감지)** — `Write|Edit`로 `docs/superpowers/{specs,plans}/*.md`가 쓰이면 "리뷰하라"는
  안내를 주입한다. 이것이 사실상 "플랜이 산출됐을 때"에 거는 훅이지만, PostToolUse는 비블로킹이라
  강제하지 못한다(안내일 뿐 무시 가능). 또 문서는 여러 번의 저장으로 조금씩 작성되므로, 저장 시점은
  대개 반쯤 쓰다 만 초안 상태다 — 리뷰를 강제하기엔 이르다.
- **`Stop`(강제)** — 턴이 끝나려는 순간이다. `{"decision":"block"}`으로 종료를 실제로 거부할 수 있는
  유일한 시점이고, 턴이 끝난다는 건 이번 작업에서 문서가 더 손댈 게 없는 *완성된 경계*라는 뜻이다.

`Stop` 훅은 git 신규(미추적·추가) spec/plan 중 마커 없는 게 있을 때만 작동하므로(`git status`로 거름; 기존 파일 수정은 제외 — 아래 「기존 문서 수정에는 걸지 않기로 한 트레이드」), 설계 문서를
안 건드린 턴은 즉시 통과한다. 결과적으로 "방금 플랜을 만들고 마무리하는 순간"에만 발동해, "플래너 완료
시점에 리뷰"라는 본래 의도와 실효적으로 같게 동작한다. 무한 차단을 막는 안전장치로 `stop_hook_active`
루프가드, `DISCIPLINED_CODER_REVIEW_GATE=off` 스위치, 판단에 쓸 git 정보나 디렉터리가 없으면 막지 않고 통과시키는 처리(FAIL-OPEN)를 둔다.

**마커 시스템 도입 전에 쓰인 spec/plan에는 터미널 마커가 없다.** 게이트는 git이 신규로 보는 문서만
훑으므로 커밋된 채 손대지 않은 동안은 걸리지 않고, 그 문서를 편집하는 순간 처음으로 걸린다. 그때는
마커를 백필하거나(일회성·`SURGICAL`) 게이트를 끄면 된다. 어느 문서가 그런 상태인지는 여기 적지
않는다 — 편집하는 순간 게이트가 알려 주고, 적어 두면 그 목록이 먼저 낡는다.

**기존 문서 수정에는 걸지 않기로 한 트레이드**: Stop 하드게이트는 **신규(미추적·추가) spec/plan에만** 건다 — 기존 커밋된 spec을
*수정*하면(상태 strip·재설계) 하드블록이 아니라 PostToolUse 넛지만 뜬다. 이는 "기존 문서를 손질만 해도
게이트가 재발동하고, 해제 마커가 dated 상태를 문서에 박던" 자가당착을 푼 의도적 트레이드다. 대가: 기존
spec의 *실질 재설계*는 자동 재리뷰가 보장되지 않는다(관례상 새 설계는 새 날짜 파일이고, 넛지가 환기한다).
같은 턴에 작성하고 커밋한 spec도 git이 깨끗하다고 보므로 안 걸린다(막지 않고 통과시키는 처리다). 필요하면 그 spec을 새 파일로 떠 리뷰하거나
게이트를 강화한다.

## 왜 문서(README 등) 검진은 비블로킹 넛지인가 (spec/plan은 하드 게이트인데)

**막지 않고 권유로 둔 이유는 셋이다.** 발행물에는 리뷰 마커를 박을 수 없어 통과 여부를 판별할 수단이
없고, 결함의 위험과 되돌리는 비용이 설계 문서와 다르며, 매 저장을 막으면 마찰만 크다. 어떻게
구현했는지부터 적는다.

일반 문서 작성도 사람의 글쓰기 흐름을 흉내 낸다 — 쓰기 전에 양식을 고르고, 쓴 뒤 남의 눈으로 본다.
이를 훅 둘로 구현했다: `doc_format_pretooluse.sh`(PreToolUse — 새 `.md`에 `domain-docs` 양식 제안)와
`doc_review_posttooluse.sh`(PostToolUse — 작성/수정 후 검진 넛지. 어느 렌즈로 검진할지는 `domain-docs`가 정한다).
둘 다 spec/plan 경로(`docs/superpowers/{specs,plans}`)는 제외한다 — 그쪽은 자체 하드 게이트가 맡는다.

spec/plan과 달리 **비블로킹(권유)**으로 둔 이유는 셋이다.
- **발행물이라 마커가 부적합하다.** spec/plan은 문서 맨 끝에 `<!-- spec-review: passed -->`를
  박아 Stop 게이트를 해제한다(끝에 붙이므로 터미널 마커라 부른다)(마커의 형식은 `domain-spec-review`가 정본이며 날짜나 개수를 담지 않는다). 그러나 README 같은 발행물에 리뷰 마커를 남기면 산출물 자체가 오염된다.
  마커가 없으면 Stop 게이트는 통과/미통과를 판별할 수단이 없으니, 애초에 하드 게이트로 만들 수 없다.
- **위험·비용이 다르다.** 설계 문서는 구현의 입력이라 결함이 하류로 번지지만, 일반 문서는 발행 후에도
  고치기 쉽다(`REVERSIBLE`). 하드 블록의 마찰을 정당화할 만큼 위험이 크지 않다.
- **작성 흐름을 과도하게 끊지 않는다.** 문서는 여러 번의 저장으로 점진 작성되므로, 매 저장을 막으면
  마찰만 크다. 그래서 "띄우되 막지 않는" 넛지로 둔다.

**제안이 뜨는 시점이 늦다**: PreToolUse 양식 제안은 도구 실행 직전에 뜨지만, 그 시점엔 Write 본문이 이미
작성돼 있다. 따라서 제안은 *이번* 작성보다 수정·다음 작성에 영향을 준다(spec/plan PostToolUse 감지가
반쯤 쓰다 만 초안에 뜨는 것과 같은 부류의 한계). 비블로킹이라 실해는 없고, 객관적 검진은 Post 넛지가
보완한다. 같은 OFF 토글(`DISCIPLINED_CODER_REVIEW_GATE=off`)로 둘 다 끌 수 있다.

## Codex 패리티 레이어
- **무엇을 공유하고 무엇을 더하는가.** 원칙 정본과 도메인 목차, `skills/` 전부, 그리고 게이트 로직은 두 런타임이 그대로 공유한다. Codex를 위해 만든 것(`.codex-plugin/`, `hooks-codex.json`, `session-start-codex`, `codex-scaffold.sh`)은 기존 것을 고치지 않고 더하기만 한다.
- **갈라지는 지점은 하나뿐이다.** 파일 편집 도구가 런타임마다 다르다 — Claude에서는 Write와 Edit이 `file_path`로 경로를 주고, Codex에서는 `apply_patch`가 패치 헤더로 준다. `hooks/_extract_path.sh`가 양쪽을 흡수해 Pre와 Post 훅들이 그것을 함께 쓰며, 한 번에 여러 파일이 와도 모두 추출한다.
- **상시 원칙을 어떻게 싣는가.** Claude는 `~/.claude/CLAUDE.md`의 `@import`로 싣는다. Codex는 `@import`를 지원하지 않으므로 `~/.codex/AGENTS.md` 관리블록에 정본을 인라인으로 넣고 매 세션 멱등하게 갱신한다. `session-start-codex`가 정본을 세션 컨텍스트로 함께 보내는 것은 **관리블록을 방금 만든 첫 세션 한 번뿐이며**, 그다음부터는 인라인 한 경로만 쓴다(이중 전송은 커밋 `1ea92f8`에서 의도적으로 제거했다).
- **무엇이 실제로 차단하는가.** 진짜 차단은 git 기반의 Stop 게이트(`spec_review_stop.sh`) 하나이고, 도구 형태와 무관하게 **신규** spec과 plan을 훑는다. 기존 파일을 수정하는 경우는 차단하지 않고 넛지만 띄운다. PreToolUse와 PostToolUse는 모두 비블로킹 넛지다.
- **신뢰검토 갭을 어떻게 드러내는가**(`FAIL-LOUD`). Codex는 설치한 플러그인의 훅을 사용자가 한 번 신뢰하겠다고 확인하기 전에는 조용히 건너뛴다(이 확인을 신뢰검토라 부른다). 그래서 `session-start-codex`가 주입하는 첫 줄에 경고를 넣고 README에도 명시한다.
- **version은 한쪽만 갖는다.** `.codex-plugin/plugin.json`만 `version`을 갖고 `.claude-plugin/plugin.json`은 비워 둔다. 이 계약은 `scripts/test_scaffold.sh`가 양쪽을 단언해 지킨다. Claude 매니페스트에 version을 도입하기로 결정하면 그 테스트와 함께 둘을 맞춘다.
- **다른 런타임은 필요해지면 더한다**(YAGNI). Cursor 같은 런타임도 같은 per-runtime-manifest 패턴으로 확장하되, 통증과 이벤트 차이를 실제로 측정한 뒤에 추가한다.

## 업그레이드 노트
- **사전 릴리스(구 sentinel) 버전에서 올라온 경우만 해당.** 구 버전은 CLAUDE.md에
  `## 프로젝트 이슈 로그 (자동 주입)` 헤더 + `@solved_problems.md`/`@unsolved_problems.md`를 직접 붙였다.
  현재 버전은 `# BEGIN/END disciplined-coder` 관리 영역을 쓰므로, 구 버전으로 이미 배선된 프로젝트는 둘이
  공존해 import가 **중복**될 수 있다(동작은 됨, 토큰 낭비). 해당 프로젝트의 CLAUDE.md에서 구 sentinel
  헤더와 그 아래 중복 `@import` 2줄만 **수동 삭제**하면 된다. (신규 도입이면 해당 없음 — 자동 마이그레이션은
  오삭제 위험 때문에 의도적으로 넣지 않았다.)
