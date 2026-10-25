# 렌즈 에이전트 런타임 시험 기록

이 기록은 렌즈 에이전트 전환 spec(`docs/superpowers/specs/2026-10-25-lens-agent-restructure-design.md`) 「먼저 할 런타임 시험」의 결과다. 시험은 모두 통과했고, 실패 처리로 넘어간 시험은 없다. 시험 6의 결과로 PRINCIPLES 줄을 어떻게 할지와 `maxTurns`·`effort` 값은 사용자 결정으로 남았다.

## 시험 환경

시험은 2026-10-25 이 PC(윈도우 11, Claude Code 2.1.310)에서 했다. 각 시험은 이 브랜치를 `--plugin-dir` 로 적재한 헤드리스 세션(`claude -p --output-format stream-json --verbose`)이다. `--settings '{"enabledPlugins":{"disciplined-coder@chshin-tools":false}}'` 로 설치본을 껐다. 초기 이벤트의 plugins 칸에는 `disciplined-coder@inline`(이 워크트리) 하나만 있었고, agents 칸에는 `disciplined-coder:lens-grounding` 이 하나만 있었다. 같은 세션의 skills 칸에는 `disciplined-coder:lens-*` 스킬도 함께 있었다.

시험용 정의는 `agents/lens-grounding.md`, `agents/lens-adversarial.md`, `agents/lens-readability.md` 다. 본문은 현행 SKILL.md 의 레퍼런스 프롬프트와 출력 스키마만 옮긴 최소 정의이고, frontmatter 에는 `maxTurns`·`effort` 를 적지 않았다.

`--allowedTools` 는 값을 여럿 받아 뒤의 위치 인자를 프롬프트로 읽지 않는다. 그래서 프롬프트는 표준 입력으로 넘겼다. 첫 실행은 이 때문에 "Input must be provided" 오류로 끝났다.

## 시험 결과

| 시험 | 관측 | 판정 |
|---|---|---|
| 1. `subagent_type: disciplined-coder:lens-grounding` 실행 | Agent 결과의 `agentType` 이 `disciplined-coder:lens-grounding`, `resolvedModel` 이 `claude-opus-5-5[1m]` 였다. 서브에이전트가 쓴 도구는 Read·Grep·Glob 과 하네스의 결과 반환 도구뿐이었다 | 통과 |
| 2. `@agent-disciplined-coder:lens-adversarial` 직접 실행 | `-p` 세션에서도 동작했다. 메인 세션이 정의와 `dispatching-lenses` 를 Read 한 뒤 첫 줄 `MODE: plan`, 둘째 줄 `PRINCIPLES: <저장소>/agent-principles.md` 를 채워 실행했다. 출력은 계약의 칸을 지켰다 | 통과 |
| 3. 같은 이름의 스킬과 에이전트가 있을 때 "lens-adversarial 을 실행해" 요청 | 메인 세션이 `dispatching-lenses` 스킬을 연 뒤 Agent 도구로 에이전트 `disciplined-coder:lens-adversarial` 을 실행했다. 렌즈 스킬은 실행하지 않았다. 다만 프롬프트에 MODE·PRINCIPLES 줄이 없었고, 에이전트가 `skills/lens-adversarial/SKILL.md` 를 스스로 읽었다 | 에이전트가 선택된다. 사용 제한은 두지 않는다 |
| 4. 정의의 tools 에 Playwright 도구를 적었을 때 | tools 에 적은 `mcp__plugin_playwright_playwright__*` 를 서브에이전트가 받았다. `file:` 주소는 Playwright 가 "Access to \"file:\" protocol is blocked" 로 거부했고, `http://127.0.0.1` 로 제공한 HTML 은 열기·전체 캡처·스냅샷에 성공했다. Playwright 플러그인을 끈 세션에서는 정의가 그대로 적재되고 서브에이전트가 Read 만 받았으며, 출력의 `notes` 는 "브라우저 도구 없음"이었다 | 통과. 호출자가 HTML 을 HTTP 로 제공해야 한다 |
| 5. 턴 수·도구 호출 수·effort | 시험 1과 같은 실행에서 측정했다. 대상은 이 spec 하나다. 토큰 161,688, 시간 241초, 도구 호출 40회, 서브에이전트 메시지 40개였다. effort 는 stream-json 의 어느 칸에도 나오지 않았다 | 측정 완료. effort 는 측정할 수 없다 |
| 6. 사용자 CLAUDE.md 와 @import 상속 | 프롬프트에 원칙 경로와 조항 문구를 넣지 않고 `NO-ASSUME` 첫 문장을 물었다. 에이전트는 파일을 읽지 않고(도구 호출은 결과 반환 하나) 첫 문장을 글자 그대로 답했다. 거의 빈 실행의 토큰이 30,791 이었다 | 상속한다 |

시험 3의 조사 기록과 비교하면 lens-adversarial 1회는 101,671~104,922 토큰, 197~239초, 도구 호출 18회였다. 조사 기록의 현행 렌즈 중앙값은 115k 토큰, 192초다.

## 남은 결정

**PRINCIPLES 줄.** spec 은 시험 6에서 에이전트가 원칙을 받으면 PRINCIPLES 줄을 뺄지 사용자에게 묻게 정했다. 상속되는 원칙은 PC 전역 사본(`~/.claude/disciplined-coder/agent-principles.md`)이다. 이 저장소 안에서 리뷰할 때 `dispatching-lenses` 「렌즈에게 에이전트원칙을 알리는 법」은 저장소의 `agent-principles.md` 를 넘기라고 정한다. 개발 중인 저장소 본은 전역 사본과 다를 수 있다.

사용자는 2026-10-25 PRINCIPLES 줄을 이 저장소 안에서 리뷰할 때만 넘기기로 정했다. 다른 프로젝트에서는 상속된 전역 사본을 쓰므로 줄을 빼서 같은 원칙을 두 번 읽지 않는다. 이 저장소에서는 고치는 중인 저장소 본으로 리뷰하도록 줄을 넘긴다. 이 결정은 plan Task 7 에서 `dispatching-lenses` 「렌즈에게 에이전트원칙을 알리는 법」에 반영하고, Task 4 의 정의 「입력」에는 줄이 없으면 상속된 원칙을 적용한다고 적는다.

**maxTurns·effort.** 측정한 도구 호출 수는 40회이고, 조사 기록의 최댓값은 48회다. 상한값을 정할 근거 기준은 없다. 현행 렌즈는 general-purpose 로 실행되며 턴 상한이 없다. effort 는 출력에서 읽을 수 없어 적지 않았을 때의 실제 값을 확인하지 못했다.

사용자는 2026-10-25 두 값을 모두 적지 않기로 정했다. 현행 렌즈와 같은 조건을 유지하고 근거 없는 값을 규칙으로 두지 않기 위해서다. 채택 비교(plan Task 5)에서 토큰이나 시간 축이 나빠지면 다시 정한다.

## 시험이 남긴 파일

Playwright 가 워크트리 안에 `.playwright-mcp/`(스크린샷·스냅샷·콘솔 로그)를 만들었다. 그 폴더는 시험 세션의 스크래치 폴더로 옮겼다. 시험 기록(stream-json)도 그 스크래치 폴더에 있으며 저장소에는 넣지 않았다.
