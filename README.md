# disciplined-coder

팀 엔지니어링 원칙 + 프로젝트 간 공통 함정을 **재사용 가능한 서브에이전트 타입**으로 박아두고, 신규 프로젝트에 **이슈 로그(solved/unsolved) 스캐폴드**를 자동 생성하는 Claude Code 플러그인.

## 무엇을 자동화하나
- **일반 지식**(원칙 + 공통 gotchas) → 플러그인의 agent + skill에 baked → 모든 프로젝트에서 자동, **서브에이전트까지 도달**.
- **프로젝트 고유 로그**(solved/unsolved) → SessionStart hook이 신규 프로젝트에 빈 파일 + CLAUDE.md `@import`를 **없으면 생성**(idempotent).

## 구성
```
disciplined-coder/
├── .claude-plugin/plugin.json      # 매니페스트
├── agents/disciplined-coder.md     # subagent_type / agentType
├── skills/coding-discipline/SKILL.md
├── commands/bootstrap-issues.md    # 수동 재실행용 슬래시 커맨드
├── hooks/hooks.json                # SessionStart → scaffold.sh
├── scripts/scaffold.sh             # 멱등 스캐폴드
└── marketplace.example.json        # 배포용 (마켓플레이스 repo 루트에 둘 것)
```

## 설치 (팀 공유 = project scope)
1. 이 디렉터리를 팀 git 마켓플레이스 repo에 넣고, `marketplace.example.json`을 repo 루트에 `marketplace.json`으로 배치(이름/owner 채우기).
2. 마켓플레이스 등록 후:
   ```
   claude plugin install disciplined-coder@team-tools --scope project
   ```
   `--scope project`는 `.claude/settings.json`의 `enabledPlugins`에 기록 → repo를 clone한 모든 팀원에게 적용.
3. **호스트 전제(중요)**: SessionStart hook은 컨테이너가 아니라 **호스트 셸**에서 실행된다. Windows 팀원은 **Git Bash 필수**(없으면 PowerShell로 폴백돼 bash 스크립트가 실패). hook은 `bash "...scaffold.sh"`로 호출하므로 실행권한 비트(`chmod +x`)에 의존하지 않는다.
4. `claude plugin validate ./disciplined-coder --strict`로 검증.

## 사용
- **SDD**: `Agent` 호출 시 `subagent_type: 'disciplined-coder'`.
- **ultracode**: `agent(prompt, { agentType: 'disciplined-coder' })`. 팬아웃 에이전트 전부가 원칙/스킬 상속.
- 둘 다 동일 레지스트리에서 해석되므로 정의는 1벌로 양쪽 재사용.

## 동작 정정 (공식 문서 검증 완료)
- **프로젝트 고유 solved/unsolved는 모든 커스텀 서브에이전트에 자동 주입된다.** 서브에이전트는 시작 시 메인 세션과 동일한 메모리 계층(프로젝트 `CLAUDE.md`와 그 `@import` 포함)을 로드한다. 이 플러그인이 CLAUDE.md에 `@solved_problems.md`/`@unsolved_problems.md`를 배선하므로, `disciplined-coder`를 포함한 모든 서브에이전트가 그 로그를 자동으로 보유한다.
  - **예외는 빌트인 `Explore`·`Plan` 에이전트 둘뿐** — 이들은 CLAUDE.md를 건너뛴다. 이 둘에 지식을 보장하려면 agent `skills:` preload(원칙)나 dispatch 프롬프트 큐레이션을 쓴다.
  - 따라서 route-D 수동 큐레이션은 "서브에이전트가 로그를 보게 하려고" **필수는 아니다.** 컨텍스트 절약(큰 로그 트리밍)이나 Explore/Plan 보강 용도의 **선택지**다.

## 한계 / 주의 (반드시 인지)
- **플러그인 루트 `CLAUDE.md`는 컨텍스트로 로드되지 않는다.** 메인 세션 주입은 skill(자동 invoke) 또는 프로젝트 CLAUDE.md `@import`로 한다(이 플러그인은 후자를 자동 배선).
- **호스트 셸 의존**: hook은 호스트에서 돈다(컨테이너 아님). Windows는 Git Bash 필요(설치 단계 3 참고). `MSYS_NO_PATHCONV` 등 Git Bash 전용 gotcha는 mac/Linux/PowerShell 호스트엔 무관하니 보편 규칙으로 적용 금지.
- **🔴 자동구현 금지**: scaffold가 `unsolved_problems.md` 상단에 "모든 에이전트는 🔴 자율 구현 금지" 명령을 심어두므로, 이 지시는 @import를 타고 모든 서브에이전트에 함께 전달된다. 다만 **CLAUDE.md는 강제가 아닌 가이드**이므로(공식 문서), 진짜로 막아야 한다면 `PreToolUse` hook로 강제하라.
- **SessionStart hook은 `matcher: startup`으로 새 세션에서만 실행**된다. 스크립트는 멱등이지만 무거운 작업을 넣지 말 것.
- **baked digest staleness**: agent/skill의 원칙·gotchas는 정적이다. **소유자와 갱신 주기를 정하라**(권장: 분기 1회 검토). 일반화 가능한 `solved` 항목만 skill로 승격하고, 승격 시 프로젝트-로컬 사본을 반드시 삭제(양쪽 복제 금지 = SSOT). 현재 승격을 자동 검사하는 도구는 없으므로 사람이 체크리스트로 관리한다.
- **SSOT**: 9개 원칙의 단일 출처는 `coding-discipline` 스킬이다. agent 본문은 스킬을 참조만 하며 원칙을 중복 기재하지 않는다.
