# 설계: Codex 패리티 레이어 (디시플린을 Codex에서도 동일하게)

작성: 2026-06-25

## 1. 배경과 문제

disciplined-coder는 팀 디시플린을 **Claude Code** 전용 메커니즘으로 강제한다 — SessionStart 훅이
`~/.claude/CLAUDE.md`에 `@import`를 배선하고, Skill 시스템으로 도메인/리뷰어 스킬을 온디맨드 로드하며,
Pre/Post/Stop 훅으로 spec/plan/문서 리뷰 게이트를 차단(강제)한다.

같은 사용자가 **Codex**(OpenAI Codex CLI)로 작업할 때는 이 디시플린이 전혀 적용되지 않는다. 목표는
**이미 구축된 내용(SSOT)을 바꾸지 않고**, Codex에서도 동일하게 동작하도록 **가산형 레이어**를 더하는 것이다.

### 측정으로 확인한 사실 (MEASURE-FIRST)
- Codex는 Claude Code와 **거의 동일한 훅 계약**을 지원한다(공식 문서 `developers.openai.com/codex/hooks`):
  - 같은 이벤트: `SessionStart`·`PreToolUse`·`PostToolUse`·`Stop`·`SubagentStart` 등.
  - 같은 차단 스키마: PostToolUse/Stop은 `{"decision":"block","reason":"..."}`(stdout JSON, exit 0)로 차단.
    (디시플린의 Stop 게이트가 바로 이 방식이라 그대로 재사용된다 — 아래 3.4.) PreToolUse도 deny를
    지원하나 우리 Pre 훅은 차단이 아니라 양식 제안 넛지(비블로킹)이므로 쓰지 않는다.
  - 같은 SessionStart 주입: `hookSpecificOutput.additionalContext`.
  - 플러그인 매니페스트 `.codex-plugin/plugin.json`의 `"hooks"`/`"skills"` 키. 훅 환경변수로 Codex 네이티브
    `PLUGIN_ROOT` + **`CLAUDE_PLUGIN_ROOT` 호환 별칭**을 함께 제공(기존 훅의 `${CLAUDE_PLUGIN_ROOT}`가
    그대로 작동). 신규 `hooks-codex.json`은 호환성 위해 `${CLAUDE_PLUGIN_ROOT}`를 쓴다(양 런타임 공통).

> **잔존 리스크(정직히 — FAIL-LOUD)**: 위 Codex 사실은 공식 문서로 확인했으나 이 PC엔 codex가 없어
> *실제 게이트 발동*은 미검증이다. 구현 후 codex 설치 환경에서 Pre/Post/Stop가 정말 발동하는지
> 스모크 테스트로 확인한다(6장). 발동 안 하면 SessionStart 주입 컨텍스트에 게이트 규약을 적어 폴백.
- **단 하나의 실질적 차이**: Codex에서 파일 편집은 `Write`/`Edit`가 아니라 **`apply_patch`** 도구로 간다.
  - 따라서 훅 matcher가 `Write|Edit` → `apply_patch`로 달라진다.
  - 편집 대상 경로가 Claude는 `tool_input.file_path`(깔끔한 JSON 필드)인데, Codex `apply_patch`는
    경로가 **패치 본문**(`*** Update File: <path>` 등)에 박혀 있어 추출 방식이 다르다.
- Codex의 지속 지시 파일은 `~/.codex/AGENTS.md`(전역) + 프로젝트 `AGENTS.md`이며, 위→아래로 이어 붙이되
  **약 32 KiB 한도**가 있다(Codex config의 `project_doc_max_bytes` 류 설정, 기본 32 KiB).
  `@import` 지시문은 지원하지 않는다(Claude 전용).
- 선례: superpowers 플러그인이 `.codex-plugin/plugin.json` + `hooks-codex.json` + `session-start-codex`로
  이미 Codex를 지원한다(단, superpowers는 SessionStart 주입만 하고 강제 게이트는 없다).

## 2. 비목표 (Non-goals)

- **기존 Claude 동작 변경 금지.** `agent-principles.md`·`domains-index.md`·`skills/**`·훅의 차단/주입
  로직은 손대지 않는다. 경로 추출 한 줄을 공용 헬퍼 호출로 바꾸는 것만 허용하며, 이는 Claude의
  `file_path` 경로를 그대로 보존한다(동작 불변).
- **OpenAI 공개 마켓플레이스(`openai-codex-plugins`) 자동 PR 동기화는 만들지 않는다.** superpowers는
  공개 배포라 그 경로가 필요하지만, 디시플린은 PC-레벨 개인/팀 도구다. 로컬 설치(`codex plugin`)를 1순위로
  문서화하고, 공개 배포는 통증이 확인되면 별도로 다룬다(YAGNI·측정 먼저).
- **스킬 SKILL.md 재작성 금지.** 스킬은 이미 런타임 중립적 "행동 언어"로 쓰여 Codex에서 그대로 로드된다.
- **새 원칙·새 스킬 추가 없음.** 순수 이식 레이어다.

## 3. 설계

### 3.1 SSOT 보존 원칙
공유 자산(`agent-principles.md`, `domains-index.md`, `skills/**`, 훅의 핵심 로직)은 **두 런타임이 같이
읽는 단일 출처**로 유지한다. Codex용 산출물은 **추가**만 하고, 런타임이 달라지는 지점은 얇은 어댑터로 흡수한다.

### 3.2 추가/변경 파일

| 파일 | 신규/변경 | 역할 |
|---|---|---|
| `.codex-plugin/plugin.json` | 신규 | Codex 매니페스트. `"skills":"./skills/"`, `"hooks":"./hooks/hooks-codex.json"`, `interface` 블록. 이름·설명·author는 기존 `plugin.json`에서 파생 |
| `hooks/hooks-codex.json` | 신규 | Codex 훅 배선. `SessionStart`→codex 주입, `PreToolUse`/`PostToolUse` matcher=`apply_patch`, `Stop`→기존 stop 게이트 |
| `hooks/_extract_path.sh` | 신규 | **공용 헬퍼**. stdin JSON에서 편집 대상 경로를 **전부** 추출(한 줄에 하나씩) — `file_path`(Claude) **또는** `apply_patch` 패치 본문의 다중 `*** … File:` 헤더(Codex) 양쪽 처리. 순수 bash, jq 비의존 |
| `hooks/session-start-codex` | 신규 | Codex SessionStart 훅. `codex-scaffold.sh` 실행 + 원칙을 `additionalContext` JSON으로 주입(superpowers `session-start-codex` 패턴) + 게이트 신뢰검토 안내(아래 5장) |
| `scripts/codex-scaffold.sh` | 신규 | `scaffold.sh`의 Codex 쌍둥이. `~/.codex/disciplined-coder/`에 원칙·이슈로그 셋업 + `~/.codex/AGENTS.md` 관리블록 갱신(멱등) |
| `hooks/doc_format_pretooluse.sh`·`hooks/spec_review_posttooluse.sh`·`hooks/doc_review_posttooluse.sh` | 변경(최소) | 경로 추출 `sed` 한 줄을 `_extract_path.sh` 호출로 교체(이제 다중 경로 순회). 그 외 로직·출력 불변. (`spec_review_stop.sh`는 git 기반이라 손대지 않음 — 3.4) |
| `scripts/test_scaffold.sh` + `scripts/test_hooks.sh` | 변경 | Codex 입력 픽스처 케이스 추가(아래 6장) |

### 3.3 공용 경로 추출 헬퍼 (`_extract_path.sh`)
입력(stdin JSON)에서 편집 대상 파일 경로를 **하나도 빠짐없이** 뽑아 한 줄에 하나씩 stdout으로 출력한다.
두 형태를 모두 처리한다.

1. **Claude (Write/Edit)** — `"file_path":"<path>"` 필드를 추출(한 호출 = 한 파일, 현행과 동일).
2. **Codex (apply_patch)** — `tool_input` 안 패치 문자열에서 `*** Add File: <path>` / `*** Update File: <path>`
   / `*** Delete File: <path>` 줄을 **모두** 찾아 경로를 전부 추출(한 패치가 여러 파일을 건드릴 수 있음 —
   adversarial 리뷰가 지적한 다중 파일 케이스).

각 경로는 백슬래시→슬래시 정규화(`tr -s '\\' '/'`)를 거쳐 출력한다. 호출자(Pre/Post 훅 3개)는 받은 경로
**목록을 순회**하며 case로 매칭한다(기존엔 한 개만 봤다 → 이제 전부). Claude는 한 줄만 나오므로 동작 불변,
Codex 다중 파일도 빠짐없이 검사된다.

### 3.4 강제 게이트(벽) 패리티
> **핵심**: 진짜 *차단*은 **Stop 게이트뿐**이고, 이건 도구 입력이 아니라 **`git status`로 변경된 spec/plan을
> 전부 스캔**한다. 즉 다중 파일·sandbox 도구 형태와 무관하게 작동한다. Pre/Post는 비블로킹 *넛지*다.

- **Stop 게이트(하드 차단)**: `spec_review_stop.sh`를 **그대로 재사용**(변경 없음). 미리뷰 spec/plan이 git
  변경분에 남으면 `{"decision":"block","reason":...}`(stdout JSON, exit 0)로 **끝내기 차단** — 이 스크립트가
  이미 쓰는 방식이고 Codex Stop 계약과 동일하다. git 기반이라 apply_patch 다중 파일 문제의 영향 밖.
- **PostToolUse(spec/plan 감지·넛지, 비블로킹)**: matcher `apply_patch`. 추출된 경로 중 하나라도
  `docs/superpowers/{specs,plans}`면 3렌즈 리뷰 지시를 `additionalContext`로 주입.
- **PreToolUse(문서 양식 제안, 비블로킹)**: matcher `apply_patch`. 새 `.md` 생성이면 domain-docs 양식 제안 주입.
- OFF 토글(`DISCIPLINED_CODER_REVIEW_GATE=off`)·마커(`<!-- spec-review: passed -->`) 규약은 공유.

### 3.5 상시 지식 주입 (이중 경로, Claude 미러)
Claude는 `~/.claude/CLAUDE.md @import` + SessionStart stdout 두 경로로 원칙을 넣는다. Codex 미러:
1. **`codex-scaffold.sh`** — `~/.codex/disciplined-coder/`에 `agent-principles.md`·`domains-index.md`·
   `solved_problems.md`·`unsolved_problems.md` 셋업(없을 때만 생성, 정본은 매번 복사 갱신 = 멱등).
   `~/.codex/AGENTS.md`에 관리블록(BEGIN/END 마커) 재생성.
   - **AGENTS.md 한도 대응**: `@import` 미지원이므로 전체 본문 인라인은 피한다. 관리블록엔
     **트리거 인덱스(load-bearing — '언제 무엇을 연다'의 핵심)**를 넣는다. 이건 Claude의 최근 슬림화
     (상시 로드엔 트리거 인덱스만, 상세는 스킬)와 같은 전략이라, 주입이 약해도 핵심은 *항상 로드*된다.
2. **`session-start-codex` 주입** — `agent-principles.md`+`domains-index.md`+`solved_problems.md` 전체를
   `additionalContext`로 주입(escape 처리). 이게 Claude의 "SessionStart stdout 보강"에 해당. 약점은
   주입이 컴파일타임 바인딩인 @import보다 약하다는 것 — 그래서 load-bearing 부분은 (1)의 AGENTS.md가 받친다.

### 3.6 후속 — 선택(이번 범위 밖, 측정 후 결정)
- **다른 런타임 확장(Cursor 등)**: 이 레이어는 superpowers의 다중 런타임 패턴(SSOT 스킬 + 런타임별 매니페스트
  디렉터리: `.claude-plugin/`·`.codex-plugin/`·`.cursor-plugin/`…)과 **같은 형식**이다. Codex를 먼저 완성·검증해
  이 패턴을 증명한 뒤, 같은 틀로 Cursor를 확장한다. 단 Cursor는 훅 이벤트가 다르므로(`afterFileEdit`·`stop`,
  베타) 별도 어댑터가 필요하다 — Codex처럼 거저 따라오지 않는다. 통증이 확인된 런타임만 추가한다(YAGNI).

다음은 코어 패리티(원칙·스킬·게이트)에 필수가 아니라 계획 단계에서 포함 여부를 정한다.
- **커맨드 미러**: `/show-principles`·`/show-solved`·`/show-unsolved`·`/bootstrap-issues`를 Codex 커스텀
  프롬프트(`~/.codex/prompts/*.md`)로.
- **`SubagentStart` 주입**: Claude는 메모리 로드로 서브에이전트에 원칙이 *공짜로* 닿지만, Codex 서브에이전트가
  AGENTS.md/세션 컨텍스트를 상속하는지는 **미측정**이다. 먼저 상속 여부를 확인하고(측정 먼저·YAGNI),
  안 닿을 때만 `SubagentStart` 훅으로 주입을 추가한다 — 지금 투기적으로 만들지 않는다.

## 4. 데이터 흐름

```
Codex 세션 시작
  └─ SessionStart 훅 → session-start-codex
       ├─ codex-scaffold.sh  → ~/.codex/disciplined-coder/* 셋업 + ~/.codex/AGENTS.md 관리블록
       └─ additionalContext  → agent-principles + domains-index + solved 주입
Codex 파일 편집(apply_patch)
  ├─ PreToolUse(apply_patch)  → _extract_path(다중) → .md 신규면 domain-docs 양식 제안 주입(넛지)
  └─ PostToolUse(apply_patch) → _extract_path(다중) → 하나라도 spec/plan이면 3렌즈 리뷰 지시 주입(넛지)
Codex 턴 종료(Stop)
  └─ spec_review_stop → git 변경분에 미리뷰 spec/plan 있으면 {"decision":"block"} (끝내기 하드 차단)
```

## 5. 에러 처리·엣지

- **헬퍼가 경로를 못 찾으면** 빈 문자열 → 호출자가 조용히 `exit 0`(현행과 동일, 0-cost 조기탈출).
- **jq 미존재 환경**: 모든 신규 스크립트는 순수 bash(현행 규약 유지).
- **Windows**: superpowers `run-hook.cmd` 폴리글랏 래퍼 패턴을 따라 확장자 없는 훅명 + cmd 래퍼로
  Git Bash를 찾는다(bash 없으면 조용히 통과 — 플러그인은 동작, 주입만 생략).
- **AGENTS.md 멱등·CRLF 내성**: `scaffold.sh`의 awk 마커 스트립 로직을 재사용.
- **trust 리뷰(파리티 갭 — FAIL-LOUD)**: Codex는 플러그인 훅을 신뢰 검토 전엔 *조용히* 건너뛴다. 즉 설치
  직후~신뢰 사이엔 게이트가 안 막힌다(Claude는 즉시 작동 — 진짜 갭). 플랫폼 동작이라 우리가 끌 수 없으므로
  **숨기지 말고 크게 노출**한다: (1) `session-start-codex` 주입 컨텍스트 첫 줄에 "게이트는 신뢰검토 후
  작동한다"는 경고를 넣고, (2) README/설치 안내에 명시한다. 침묵형 통과가 "다뤄진 척"이 되지 않게 한다.

## 6. 검증 (TDD)

- **`_extract_path.sh` 단위**: Claude `file_path` JSON / Codex `apply_patch` 단일·**다중** 파일
  (Add·Update·Delete 혼합) 픽스처를 입력해 경로를 *빠짐없이* 뽑는지. 불변식으로 검증(매직넘버 금지).
- **`test_hooks.sh` 확장**: 기존 Claude 입력 케이스 유지 + **Codex `apply_patch` 입력 케이스 추가** —
  spec 경로면 넛지 발동, terminal 마커 있으면 침묵, 무관 경로면 조기탈출, **다중 파일 패치에서 2번째 파일이
  spec여도 감지**. 계약 **FAIL=0**.
- **`codex-scaffold` 검증**: `test_scaffold.sh` 패턴(임시 홈 `CODEX_HOME_DIR` 오버라이드, 실제 `~/.codex`
  미오염)으로 멱등·관리블록 재생성 확인.
- **Codex 스모크(잔존 리스크 해소)**: codex 설치 환경에서 Pre/Post/Stop가 실제 발동하는지 1회 수동 확인
  (이 PC엔 codex 없음 — 미검증 사실을 닫는 단계). 발동 안 하면 주입 폴백.
- `claude plugin validate ./`는 기존대로 통과(`.codex-plugin/`은 Claude 검증과 직교).

## 7. 영향·가역성 (REVERSIBLE)

- 전부 가산형. `.codex-plugin/`·`hooks-codex.json`·신규 스크립트를 지우고 Pre/Post 훅 3개의 헬퍼 호출을
  원래 `sed` 한 줄로 되돌리면 완전 원복(양방향 문). `spec_review_stop.sh`는 손대지 않으므로 원복 대상 아님.
- 기존 Claude 사용자에겐 무영향(Codex 산출물은 Claude가 읽지 않음).

<!-- spec-review: passed lenses=3 date=2026-06-25 -->
