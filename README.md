# disciplined-coder

팀 엔지니어링 원칙 + 프로젝트 간 공통 함정을 **agent-principles.md(SSOT)** 에 박아두고, SessionStart hook이 **PC-레벨(~/.claude/disciplined-coder/)** 에 자동 셋업하는 Claude Code 플러그인. **프로젝트 폴더엔 아무것도 안 생긴다** — 지식은 `~/.claude/CLAUDE.md` 관리블록이 @import해 메인 세션 + 모든 서브에이전트에 도달한다.

## 전제 조건 (Prerequisites)
- **Windows 사용자: [Git Bash](https://git-scm.com/downloads) 설치 필수.** SessionStart hook이 bash 스크립트(`scaffold.sh`)를 돌리는데, Windows엔 bash가 없어 Git Bash가 그 역할을 한다. 없으면 Claude Code가 PowerShell로 폴백 → 스크립트 실패. (mac/Linux는 기본 `sh`로 동작하므로 불필요.)
- hook은 `bash "...scaffold.sh"`로 호출하므로 실행권한 비트(`chmod +x`)는 필요 없다.

## 무엇을 자동화하나
- **일반 지식**(원칙 + 공통 gotchas + 도메인 목차) → 디시플린(`agent-principles.md`, SSOT) → SessionStart hook이 `~/.claude/disciplined-coder/`에 복사하고 `~/.claude/CLAUDE.md` 관리블록에 `@import`로 배선(+ 첫 세션 stdout 보강) → 메인 + 모든 서브에이전트 도달. **프로젝트 폴더는 건드리지 않는다.**
- **이슈 로그**(solved/unsolved) → `~/.claude/disciplined-coder/`에 없으면 생성(PC 전역, idempotent). 프로젝트별 분리가 아닌 PC 전역 누적.
- **스킬**(domain-*/advisor-*) → 플러그인에서 온디맨드 로드. 복사·주입 안 함.

## 도메인 참고서 (설계 시점) + 런타임 검증
개발 대상(도메인)에 따라 "마땅히 그래야 하는 것"이 있다. `domains-index.md`(`~/.claude/CLAUDE.md`에 자동 주입되는 목차)가 도메인 목록과 "언제·어느 참고서"를 안내하고, 각 `skills/domain-*`가 상세(온디맨드)를 제공한다 — 설계/계획 시 명세에 반영, 개발 시 폴백. 도메인 상세 일부는 아직 stub(통증 있는 것부터 채움).

**LLM 런타임 도메인**: 제품이 런타임에 LLM을 호출하면 단독 콜로 끝내지 말고 검증 레이어를 구현한다. `skills/domain-llm-runtime`(조립·리스크 선택) + `skills/advisor-{correctness,fit,nonfunctional,meta}`(구현 스펙). 이 4종 어드바이저는 Claude Code 에이전트가 아니라 제품 코드가 구현할 청사진이다.

**메타 산출물 리뷰(별개 축)**: spec/plan도 Claude의 LLM 산출물이다. self-review는 작성자 편향에 약하므로, `skills/advisor-spec-review`에 따라 **PREP(무엇을 볼지 지식주입과 함께 미리 준비 — TDD식) → 독립 read-only 3렌즈(factual/consistency/adversarial) → 메타 집계 → accept/regenerate/escalate**로 검증한다. 위 4종(제품 런타임 청사진)과 달리 **메인 세션이 직접 서브에이전트를 디스패치**하는 CC 워크플로이며 superpowers self-review를 대체하지 않고 뒤에 레이어를 더한다. superpowers 기본 경로에 spec/plan이 쓰이면 **훅이 강제**한다(PostToolUse 감지 + Stop 하드 게이트; 문서 마지막 줄의 `<!-- spec-review: passed … -->` 마커로 해제; 전역 끄기 `DISCIPLINED_CODER_REVIEW_GATE=off`).

## 이슈 로그 생애주기
PC 전역 `~/.claude/disciplined-coder/solved_problems.md`/`unsolved_problems.md`는 다음 규약으로 운영된다(디시플린 "절차"에 명시, 모든 세션에 주입):
- **등록**: 검증/리뷰 작업이 끝날 때, 발견된 문제를 `unsolved_problems.md`에 기록.
- **solved 이동**: 테스트가 통과로 바뀌면 해당 문제를 `solved_problems.md`로(문제→원인→해결).
- **단일 작성자**: 메인 세션(오케스트레이터)만 로그를 쓴다. 서브에이전트는 리턴값으로 보고만 하고, 메인이 취합·dedup해 기록한다. 세션 중 최신이 필요하면 메인이 dispatch에 관련 항목을 주입한다.
- **🔴 금지**: `unsolved_problems.md`의 🔴(사용자 결정 필요)는 어떤 에이전트도 자율 구현하지 않는다.

> 테스트 통과를 결정론적으로 감지하는 PostToolUse hook 보조는 의도적으로 넣지 않았다(판별 취약·이득 적음). 필요 시 후속 추가.

## 구성
```
disciplined-coder/
├── .claude-plugin/plugin.json      # 매니페스트
├── agent-principles.md            # 디시플린 정본 (SSOT) — hook이 ~/.claude/disciplined-coder/로 복사
├── domains-index.md                # 개발 대상(도메인) 참고서 인덱스 (동일 경로로 복사)
├── skills/domain-*/SKILL.md        # 도메인 참고서 (docs/plugin seed, ui/app/agent/db stub, llm-runtime) — 온디맨드
├── skills/advisor-*/SKILL.md       # 제품 런타임 검증 4종(correctness/fit/nonfunctional/meta) + 메타 산출물 리뷰(advisor-spec-review) — 온디맨드
├── hooks/hooks.json                # SessionStart → scaffold.sh · PostToolUse/Stop → spec/plan 리뷰 강제
├── hooks/spec_review_*.sh          # PostToolUse(감지·신호) · Stop(하드 게이트) — 순수 bash, jq 비의존
├── scripts/scaffold.sh             # 멱등: ~/.claude/disciplined-coder/ 셋업 + ~/.claude/CLAUDE.md 관리영역 @import
├── scripts/test_scaffold.sh        # scaffold 검증 테스트 (CLAUDE_HOME_DIR 임시홈, 실제 ~/.claude 미오염)
├── scripts/test_hooks.sh           # 훅 불변식 테스트 (경로매칭·마커·루프가드·OFF — 계약 FAIL=0)
├── commands/bootstrap-issues.md    # 수동 재실행 커맨드
└── README.md
```

> `~/.claude/disciplined-coder/`에 생성되는 파일: `agent-principles.md`, `domains-index.md`, `solved_problems.md`, `unsolved_problems.md`. 스킬은 플러그인에서 온디맨드로 로드 — 복사하지 않는다.

## 설치 (user scope 권장)

**A. 마켓플레이스로 (공유·배포)** — 이 레포가 곧 마켓플레이스다(`.claude-plugin/marketplace.json`).
1. 마켓플레이스 추가: `/plugin marketplace add chshin84/disciplined-coder`
2. 설치: `/plugin install disciplined-coder@chshin-tools`
3. 업데이트: `/plugin marketplace update chshin-tools`

**B. 로컬 클론으로 (개발·기여)**
1. 이 디렉터리를 클론한다.
2. user scope로 설치: `claude plugin install ./ --scope user` (모든 프로젝트에서 자동 활성화).

공통: Windows는 **Git Bash 필수**(위 [전제 조건](#전제-조건-prerequisites)). `claude plugin validate ./`로 검증(루트 CLAUDE.md 도그푸딩 때문에 `--strict`는 경고로 실패 — 의도된 동작).

## 사용
플러그인이 설치(user scope)되면 **별도 조작 없이 자동으로 동작**한다. 설치 후 **새 Claude Code 세션을 시작**하면 SessionStart hook이 자동 실행되어:
- `~/.claude/disciplined-coder/`에 `agent-principles.md`, `domains-index.md`, `solved_problems.md`, `unsolved_problems.md` 셋업
- `~/.claude/CLAUDE.md` 관리블록에 `@import` 배선(없으면 생성, 있으면 멱등 갱신)

**프로젝트 폴더는 전혀 건드리지 않는다.** 이후 어느 프로젝트에서 열어도 메인 세션과 모든 서브에이전트가 원칙 + 도메인 목차 + 이슈 로그를 자동으로 보유한다.

## 동작 정정 (공식 문서 검증 완료)
- **PC 전역 solved/unsolved는 모든 커스텀 서브에이전트에 자동 주입된다.** 서브에이전트는 시작 시 메인 세션과 동일한 메모리 계층(`~/.claude/CLAUDE.md`와 그 `@import` 포함)을 로드한다. 이 플러그인이 `~/.claude/CLAUDE.md`에 `@disciplined-coder/solved_problems.md`를 배선하므로, 모든 서브에이전트가 그 로그를 자동으로 보유한다.
  - **예외는 빌트인 `Explore`·`Plan` 에이전트 둘뿐** — 이들은 `~/.claude/CLAUDE.md`를 건너뛴다. 이 둘에 지식을 보장하려면 dispatch 프롬프트 큐레이션을 쓴다.
  - 따라서 수동 큐레이션은 "서브에이전트가 로그를 보게 하려고" **필수는 아니다.** 컨텍스트 절약(큰 로그 트리밍)이나 Explore/Plan 보강 용도의 **선택지**다.

## 업그레이드 노트
- **사전 릴리스(구 sentinel) 버전에서 올라온 경우만 해당.** 구 버전은 CLAUDE.md에 `## 프로젝트 이슈 로그 (자동 주입)` 헤더 + `@solved_problems.md`/`@unsolved_problems.md`를 직접 붙였다. 현재 버전은 `# BEGIN/END disciplined-coder` 관리 영역을 쓰므로, 구 버전으로 이미 배선된 프로젝트는 둘이 공존해 import가 **중복**될 수 있다(동작은 됨, 토큰 낭비). 해당 프로젝트의 CLAUDE.md에서 구 sentinel 헤더와 그 아래 중복 `@import` 2줄만 **수동 삭제**하면 된다. (신규 도입이면 해당 없음 — 자동 마이그레이션은 오삭제 위험 때문에 의도적으로 넣지 않았다.)

## 한계 / 주의 (반드시 인지)
- **플러그인 루트 `CLAUDE.md`는 컨텍스트로 로드되지 않는다.** 주입 경로는 `~/.claude/CLAUDE.md` → `@disciplined-coder/...` @import이며, 이 플러그인이 SessionStart hook으로 자동 배선한다. 프로젝트 폴더에는 아무 파일도 생성하지 않는다.
- **호스트 셸 의존**: hook은 호스트에서 돈다(컨테이너 아님). Windows는 Git Bash 필요(설치 단계 3 참고). `MSYS_NO_PATHCONV` 등 Git Bash 전용 gotcha는 mac/Linux/PowerShell 호스트엔 무관하니 보편 규칙으로 적용 금지.
- **🔴 자동구현 금지**: scaffold가 `unsolved_problems.md` 상단에 "모든 에이전트는 🔴 자율 구현 금지" 명령을 심어두므로, 이 지시는 @import를 타고 모든 서브에이전트에 함께 전달된다. 다만 **CLAUDE.md는 강제가 아닌 가이드**이므로(공식 문서), 진짜로 막아야 한다면 `PreToolUse` hook로 강제하라.
- **SessionStart hook은 `matcher: startup`으로 새 세션에서만 실행**된다. 스크립트는 멱등이지만 무거운 작업을 넣지 말 것.
- **원칙 갱신 주기**: `agent-principles.md`(SSOT)를 수정하면 다음 세션부터 `~/.claude/disciplined-coder/`에 새 버전이 복사된다. **소유자와 갱신 주기를 정하라**(권장: 분기 1회 검토). 일반화 가능한 `solved` 항목만 원칙으로 승격하고, 승격 시 PC 전역 사본을 반드시 삭제(양쪽 복제 금지 = SSOT).
