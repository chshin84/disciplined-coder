# 설계 노트 (DESIGN-NOTES)

README에서 분리한 개발자용 내부 근거다. 사용자 설치·사용에는 필요 없지만, "왜 이렇게
동작하는가"의 근거를 보존한다(`NON-DESTRUCTIVE`). 사용자용 개요는 [README](../README.md) 참고.

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
- **🔴 자동구현 금지**: scaffold가 `unsolved_problems.md` 상단에 "모든 에이전트는 🔴 자율 구현 금지"
  명령을 심어두므로, 이 지시는 @import를 타고 모든 서브에이전트에 함께 전달된다. 다만 **CLAUDE.md는
  강제가 아닌 가이드**이므로(공식 문서), 진짜로 막아야 한다면 `PreToolUse` hook로 강제하라.
- **SessionStart hook은 `matcher: startup`으로 새 세션에서만 실행**된다. 스크립트는 멱등이지만 무거운
  작업을 넣지 말 것.
- **원칙 갱신 주기**: `agent-principles.md`(SSOT)를 수정하면 다음 세션부터 `~/.claude/disciplined-coder/`에
  새 버전이 복사된다. **소유자와 갱신 주기를 정하라**(권장: 분기 1회 검토). 일반화 가능한 `solved` 항목만
  원칙으로 승격하고, 승격 시 PC 전역 사본을 반드시 삭제(양쪽 복제 금지 = `SSOT`).
- 테스트 통과를 결정론적으로 감지하는 PostToolUse hook 보조는 의도적으로 넣지 않았다(판별 취약·이득 적음).
  필요 시 후속 추가.

## 업그레이드 노트
- **사전 릴리스(구 sentinel) 버전에서 올라온 경우만 해당.** 구 버전은 CLAUDE.md에
  `## 프로젝트 이슈 로그 (자동 주입)` 헤더 + `@solved_problems.md`/`@unsolved_problems.md`를 직접 붙였다.
  현재 버전은 `# BEGIN/END disciplined-coder` 관리 영역을 쓰므로, 구 버전으로 이미 배선된 프로젝트는 둘이
  공존해 import가 **중복**될 수 있다(동작은 됨, 토큰 낭비). 해당 프로젝트의 CLAUDE.md에서 구 sentinel
  헤더와 그 아래 중복 `@import` 2줄만 **수동 삭제**하면 된다. (신규 도입이면 해당 없음 — 자동 마이그레이션은
  오삭제 위험 때문에 의도적으로 넣지 않았다.)
