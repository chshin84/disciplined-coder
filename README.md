# disciplined-coder

팀 엔지니어링 원칙 + 프로젝트 간 공통 함정을 **coding-principles.md(SSOT)** 에 박아두고, SessionStart hook이 각 프로젝트 CLAUDE.md에 자동 주입하는 Claude Code 플러그인. 신규 프로젝트엔 **이슈 로그(solved/unsolved) 스캐폴드**도 자동 생성.

## 전제 조건 (Prerequisites)
- **Windows 사용자: [Git Bash](https://git-scm.com/downloads) 설치 필수.** SessionStart hook이 bash 스크립트(`scaffold.sh`)를 돌리는데, Windows엔 bash가 없어 Git Bash가 그 역할을 한다. 없으면 Claude Code가 PowerShell로 폴백 → 스크립트 실패. (mac/Linux는 기본 `sh`로 동작하므로 불필요.)
- hook은 `bash "...scaffold.sh"`로 호출하므로 실행권한 비트(`chmod +x`)는 필요 없다.

## 무엇을 자동화하나
- **일반 지식**(원칙 + 공통 gotchas) → 디시플린(`coding-principles.md`, SSOT) → SessionStart hook이 각 프로젝트의 CLAUDE.md에 `@import`로 자동 주입(+ 첫 세션 stdout 보강) → 메인 + 모든 서브에이전트 도달.
- **프로젝트 고유 로그**(solved/unsolved) → SessionStart hook이 신규 프로젝트에 빈 파일 + CLAUDE.md `@import`를 **없으면 생성**(idempotent).

## 런타임 LLM 검증 (어드바이저)
제품이 런타임에 LLM을 호출하는 기능은 단독 콜로 끝내지 않는다. `advisors-index.md`(모든 프로젝트 CLAUDE.md에 자동 주입)가 4종 어드바이저(정합성·적합성·비기능·메타)와 리스크별 선택·조립을 안내하고, 각 `skills/advisor-*`가 구현 스펙(렌즈·레퍼런스 프롬프트·출력 스키마·배선)을 온디맨드로 제공한다. 어드바이저는 Claude Code 에이전트가 아니라 **제품 코드가 구현할 청사진**이다.

## 구성
```
disciplined-coder/
├── .claude-plugin/plugin.json      # 매니페스트
├── coding-principles.md            # 디시플린 정본 (SSOT) — hook이 프로젝트로 복사
├── advisors-index.md               # 런타임 LLM 검증 어드바이저 인덱스 (@import)
├── skills/advisor-*/SKILL.md       # 어드바이저 4종 스펙 (온디맨드)
├── hooks/hooks.json                # SessionStart → scaffold.sh
├── scripts/scaffold.sh             # 멱등: principles 복사 + CLAUDE.md 관리영역 @import + stdout
├── scripts/test_scaffold.sh        # scaffold 검증 테스트
├── commands/bootstrap-issues.md    # 수동 재실행 커맨드
└── README.md
```

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
플러그인이 설치(user scope)되면 **별도 조작 없이 자동으로 동작**한다. 새 프로젝트에서 Claude Code 세션을 시작하면 SessionStart hook이 자동 실행되어:
- `coding-principles.md`(디시플린 정본)를 프로젝트로 복사하고 CLAUDE.md에 `@import`로 배선
- `solved_problems.md` / `unsolved_problems.md`를 생성하고 CLAUDE.md에 `@import`로 배선

이후 메인 세션과 모든 서브에이전트가 원칙 + 이슈 로그를 자동으로 보유한다.

## 동작 정정 (공식 문서 검증 완료)
- **프로젝트 고유 solved/unsolved는 모든 커스텀 서브에이전트에 자동 주입된다.** 서브에이전트는 시작 시 메인 세션과 동일한 메모리 계층(프로젝트 `CLAUDE.md`와 그 `@import` 포함)을 로드한다. 이 플러그인이 CLAUDE.md에 `@solved_problems.md`/`@unsolved_problems.md`를 배선하므로, 모든 서브에이전트가 그 로그를 자동으로 보유한다.
  - **예외는 빌트인 `Explore`·`Plan` 에이전트 둘뿐** — 이들은 CLAUDE.md를 건너뛴다. 이 둘에 지식을 보장하려면 dispatch 프롬프트 큐레이션을 쓴다.
  - 따라서 수동 큐레이션은 "서브에이전트가 로그를 보게 하려고" **필수는 아니다.** 컨텍스트 절약(큰 로그 트리밍)이나 Explore/Plan 보강 용도의 **선택지**다.

## 업그레이드 노트
- **사전 릴리스(구 sentinel) 버전에서 올라온 경우만 해당.** 구 버전은 CLAUDE.md에 `## 프로젝트 이슈 로그 (자동 주입)` 헤더 + `@solved_problems.md`/`@unsolved_problems.md`를 직접 붙였다. 현재 버전은 `# BEGIN/END disciplined-coder` 관리 영역을 쓰므로, 구 버전으로 이미 배선된 프로젝트는 둘이 공존해 import가 **중복**될 수 있다(동작은 됨, 토큰 낭비). 해당 프로젝트의 CLAUDE.md에서 구 sentinel 헤더와 그 아래 중복 `@import` 2줄만 **수동 삭제**하면 된다. (신규 도입이면 해당 없음 — 자동 마이그레이션은 오삭제 위험 때문에 의도적으로 넣지 않았다.)

## 한계 / 주의 (반드시 인지)
- **플러그인 루트 `CLAUDE.md`는 컨텍스트로 로드되지 않는다.** 메인 세션 주입은 프로젝트 CLAUDE.md `@import`로 한다(이 플러그인은 이를 자동 배선).
- **호스트 셸 의존**: hook은 호스트에서 돈다(컨테이너 아님). Windows는 Git Bash 필요(설치 단계 3 참고). `MSYS_NO_PATHCONV` 등 Git Bash 전용 gotcha는 mac/Linux/PowerShell 호스트엔 무관하니 보편 규칙으로 적용 금지.
- **🔴 자동구현 금지**: scaffold가 `unsolved_problems.md` 상단에 "모든 에이전트는 🔴 자율 구현 금지" 명령을 심어두므로, 이 지시는 @import를 타고 모든 서브에이전트에 함께 전달된다. 다만 **CLAUDE.md는 강제가 아닌 가이드**이므로(공식 문서), 진짜로 막아야 한다면 `PreToolUse` hook로 강제하라.
- **SessionStart hook은 `matcher: startup`으로 새 세션에서만 실행**된다. 스크립트는 멱등이지만 무거운 작업을 넣지 말 것.
- **원칙 갱신 주기**: `coding-principles.md`(SSOT)를 수정하면 다음 세션부터 각 프로젝트에 새 버전이 복사된다. **소유자와 갱신 주기를 정하라**(권장: 분기 1회 검토). 일반화 가능한 `solved` 항목만 원칙으로 승격하고, 승격 시 프로젝트-로컬 사본을 반드시 삭제(양쪽 복제 금지 = SSOT).
