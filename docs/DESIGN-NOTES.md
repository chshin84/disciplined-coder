# 설계 노트 (DESIGN-NOTES)

README에서 분리한 개발자용 내부 근거다. 사용자 설치·사용에는 필요 없지만, "왜 이렇게
동작하는가"의 근거를 보존한다. 사용자용 개요는 [README](../README.md) 참고.

## 서브에이전트로의 지식 전달 (공식 문서 검증 완료)
- **PC 전역 solved/unsolved는 모든 커스텀 서브에이전트에 자동 주입된다.** 서브에이전트는 시작 시
  메인 세션과 동일한 메모리 계층(`~/.claude/CLAUDE.md`와 그 `@import` 포함)을 로드한다. 이 플러그인이
  `~/.claude/CLAUDE.md`에 `@disciplined-coder/solved_problems.md`를 배선하므로, 모든 서브에이전트가
  그 로그를 자동으로 보유한다.
- **예외는 빌트인 `Explore`·`Plan` 에이전트 둘뿐** — 이들은 `~/.claude/CLAUDE.md`를 건너뛴다. 이 둘에
  지식을 보장하려면 dispatch 프롬프트 큐레이션을 쓴다.
- 따라서 수동 큐레이션은 "서브에이전트가 로그를 보게 하려고" **필수는 아니다.** 컨텍스트 절약(큰 로그
  트리밍)이나 Explore/Plan 보강 용도의 **선택지**다.

## 한계 / 주의 (반드시 인지)
- **플러그인 루트 `CLAUDE.md`는 컨텍스트로 로드되지 않는다.** 주입 경로는 `~/.claude/CLAUDE.md` →
  `@disciplined-coder/...` @import이며, 이 플러그인이 SessionStart hook으로 자동 배선한다. 프로젝트
  폴더에는 아무 파일도 생성하지 않는다.
- **호스트 셸 의존**: hook은 호스트에서 돈다(컨테이너 아님). Windows는 Git Bash 필요. `MSYS_NO_PATHCONV`
  등 Git Bash 전용 gotcha는 mac/Linux/PowerShell 호스트엔 무관하니 보편 규칙으로 적용 금지.
- **🔴 자동구현 금지**: 이 규칙은 `agent-principles.md`(@import 대상 — scaffold.sh가 배선)에 박혀 있어
  모든 서브에이전트에 전달된다. `unsolved_problems.md` 상단의 동일 문구는 백로그 파일 안의 로컬
  리마인더일 뿐 전파 경로가 아니다 — 이 파일은 의도적으로 @import에서 제외된다(백로그 미주입;
  README의 "자동 주입되지 않음"·위 §서브에이전트 전달 참조). 다만 **CLAUDE.md는 강제가 아닌
  가이드**이므로(공식 문서), 진짜로 막아야 한다면 `PreToolUse` hook로 강제하라.
- **SessionStart hook은 `matcher: startup`으로 새 세션에서만 실행**된다. 스크립트는 멱등이지만 무거운
  작업을 넣지 말 것.
- **원칙 갱신 주기**: `agent-principles.md`(SSOT)를 수정하면 다음 세션부터 `~/.claude/disciplined-coder/`에
  새 버전이 복사된다. **소유자와 갱신 주기를 정하라**(권장: 분기 1회 검토). 일반화 가능한 `solved` 항목만
  원칙으로 승격하고, 승격 시 PC 전역 사본을 반드시 삭제(양쪽 복제 금지 = `SSOT`).
- 테스트 통과를 결정론적으로 감지하는 PostToolUse hook 보조는 의도적으로 넣지 않았다(판별 취약·이득 적음).
  필요 시 후속 추가.

## 왜 spec/plan 리뷰 게이트를 Stop(턴 종료)에 두는가

설계 문서(spec/plan)도 Claude가 만든 LLM 산출물이라, 작성자 자기 검토만으로는 확증 편향에 약하다.
그래서 고위험 설계 문서는 독립 렌즈(grounding·consistency·adversarial) 리뷰를 거치게 강제한다
(`agent-principles.md` 절차 가). 설계 문서는 구현의 입력이므로, 결함을 설계 단계에서 잡는 편이
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

`Stop` 훅은 git 변경분 중 마커 없는 spec/plan이 있을 때만 작동하므로(`git status`로 거름), 설계 문서를
안 건드린 턴은 즉시 통과한다. 결과적으로 "방금 플랜을 만들고 마무리하는 순간"에만 발동해, "플래너 완료
시점에 리뷰"라는 본래 의도와 실효적으로 같게 동작한다. 무한 차단을 막는 안전장치로 `stop_hook_active`
루프가드, `DISCIPLINED_CODER_REVIEW_GATE=off` 스위치, git/디렉터리 부재 시 FAIL-OPEN을 둔다.

**알려진 한계(미해결)**: 마커 시스템 도입 전에 쓰인 레거시 spec/plan은 터미널 마커가 없다. 지금은 커밋된
채 변경이 없어 게이트에 안 걸리지만(잠재), 그 문서를 한 번이라도 편집하면 변경분으로 잡혀 Stop이 하드
블록한다. 해당 문서를 편집할 일이 생기면 마커를 백필(일회성·`SURGICAL`)하거나 게이트를 끄면 된다.

## 왜 문서(README 등) 검진은 비블로킹 넛지인가 (spec/plan은 하드 게이트인데)

일반 문서 작성도 사람의 글쓰기 흐름을 흉내 낸다 — 쓰기 전에 양식을 고르고, 쓴 뒤 남의 눈으로 본다.
이를 훅 둘로 구현했다: `doc_format_pretooluse.sh`(PreToolUse — 새 `.md`에 `domain-docs` 양식 제안)와
`doc_review_posttooluse.sh`(PostToolUse — 작성/수정 후 `reviewer-grounding`+`reviewer-fit` 검진 넛지).
둘 다 spec/plan 경로(`docs/superpowers/{specs,plans}`)는 제외한다 — 그쪽은 자체 하드 게이트가 맡는다.

spec/plan과 달리 **비블로킹(권유)**으로 둔 이유는 셋이다.
- **발행물이라 마커가 부적합하다.** spec/plan은 문서 끝에 `<!-- spec-review: passed … -->` 터미널 마커를
  박아 Stop 게이트를 해제한다. 그러나 README 같은 발행물에 리뷰 마커를 남기면 산출물 자체가 오염된다.
  마커가 없으면 Stop 게이트는 통과/미통과를 판별할 수단이 없으니, 애초에 하드 게이트로 만들 수 없다.
- **위험·비용이 다르다.** 설계 문서는 구현의 입력이라 결함이 하류로 번지지만, 일반 문서는 발행 후에도
  고치기 쉽다(`REVERSIBLE`). 하드 블록의 마찰을 정당화할 만큼 위험이 크지 않다.
- **작성 흐름을 과도하게 끊지 않는다.** 문서는 여러 번의 저장으로 점진 작성되므로, 매 저장을 막으면
  마찰만 크다. 그래서 "띄우되 막지 않는" 넛지로 둔다.

**타이밍 한계(인지)**: PreToolUse 양식 제안은 도구 실행 직전에 뜨지만, 그 시점엔 Write 본문이 이미
작성돼 있다. 따라서 제안은 *이번* 작성보다 수정·다음 작성에 영향을 준다(spec/plan PostToolUse 감지가
반쯤 쓰다 만 초안에 뜨는 것과 같은 부류의 한계). 비블로킹이라 실해는 없고, 객관적 검진은 Post 넛지가
보완한다. 같은 OFF 토글(`DISCIPLINED_CODER_REVIEW_GATE=off`)로 둘 다 끌 수 있다.

## Codex 패리티 레이어
- **SSOT 보존**: `agent-principles.md`·`domains-index.md`·`skills/**`·게이트 로직은 두 런타임 공유. Codex 산출물(`.codex-plugin/`·`hooks-codex.json`·`session-start-codex`·`codex-scaffold.sh`)은 가산형.
- **단일 분기점**: 파일 편집 도구가 Claude=Write/Edit(`file_path`) vs Codex=`apply_patch`(패치 헤더). `hooks/_extract_path.sh`가 양쪽을 흡수해 3개 Pre/Post 훅이 공유한다(다중 파일도 전부 추출).
- **상시 원칙**: Claude는 `~/.claude/CLAUDE.md @import`. Codex는 `@import` 미지원이라 `~/.codex/AGENTS.md` 관리블록에 정본을 **인라인**(생성된 사본, 매 세션 멱등 갱신) + `session-start-codex`가 additionalContext로 주입(이중 경로).
- **강제 게이트**: Stop 게이트(`spec_review_stop.sh`, git 기반)가 진짜 차단이며 도구 형태와 무관하게 변경된 spec/plan을 전부 스캔. Pre/Post는 비블로킹 넛지.
- **신뢰검토 갭(FAIL-LOUD)**: Codex는 신뢰검토 전 훅을 침묵 스킵 → `session-start-codex` 주입 첫 줄 경고 + README에 명시.
- **version 동기화**: `.codex-plugin/plugin.json`만 `version`을 갖는다. `.claude-plugin/plugin.json`이 version을 도입하면 둘을 맞춘다.
- **후속(YAGNI)**: Cursor 등 다른 런타임은 같은 per-runtime-manifest 패턴으로 확장하되, 통증·이벤트 차이를 측정한 뒤 추가한다.

## 업그레이드 노트
- **사전 릴리스(구 sentinel) 버전에서 올라온 경우만 해당.** 구 버전은 CLAUDE.md에
  `## 프로젝트 이슈 로그 (자동 주입)` 헤더 + `@solved_problems.md`/`@unsolved_problems.md`를 직접 붙였다.
  현재 버전은 `# BEGIN/END disciplined-coder` 관리 영역을 쓰므로, 구 버전으로 이미 배선된 프로젝트는 둘이
  공존해 import가 **중복**될 수 있다(동작은 됨, 토큰 낭비). 해당 프로젝트의 CLAUDE.md에서 구 sentinel
  헤더와 그 아래 중복 `@import` 2줄만 **수동 삭제**하면 된다. (신규 도입이면 해당 없음 — 자동 마이그레이션은
  오삭제 위험 때문에 의도적으로 넣지 않았다.)
