# disciplined-coder

팀 엔지니어링 원칙을 모든 Claude Code 세션에 자동으로 실어 주는 플러그인이다. 어느 프로젝트를 열어도 같은 원칙을 들고 일하되, 작업 폴더에는 (자동으로는) 아무 파일도 생기지 않는다. 원칙과 프로젝트 간 공통 함정은 `agent-principles.md` 한 곳에 모아 두고, SessionStart hook이 그것을 **PC-레벨**(`~/.claude/disciplined-coder/`)에 셋업한 뒤 `~/.claude/CLAUDE.md`의 관리블록이 `@import`로 주입한다. 관리블록은 플러그인이 만들고 갱신하는 구간이며, 시작과 끝을 표시로 구분해 둔다.

## 무엇이 좋은가
- **설치 후 무조작** — 새 세션을 시작하면 hook이 알아서 셋업하고 배선한다. 여러 번 돌아도 결과가 같다.
- **메인 세션과 실측한 두 서브에이전트 종류에 도달** — 메인 세션과 `general-purpose`·`claude` 두 종류가 같은 원칙·오답노트를 보유한다(2026-07-28 실측). 어디에 안 실리는지는 아래 「주의」에 적었다.
- **글쓰기·문서 디시플린** — 답변 표현은 `CLEAR-COMM`과 `READ-FLOW`가 상시 잡는다. 짧은 답보다 읽기에 덜 피로한 답을 택하라는 규율이다. 문서는 사람이 글 쓰는 흐름을 흉내 낸다 — 쓰기 전에 양식을 제안하고, 다 쓰면 검진을 넛지한다.

## 내 프로젝트 폴더는 어떻게 되나
**자동 계층이 프로젝트 파일에 손대는 예외는 둘뿐이고, 둘 다 이미 있는 파일을 고치는 것이다**(여기가 그 정본이다). 첫째, 그 레포에 `docs/solved_problems.md`가 이미 있고 그 머리말이 낡았으면 갈아끼운다. 둘째, 없앤 기능이 남긴 관리블록이 그 레포 `CLAUDE.md`에 있으면 걷어낸다. 둘 다 손대기 전에 사본을 먼저 뜬다 — 사본을 못 떴을 때 무엇을 하는지는 `domain-docs`가 정본이다. 사본은 프로젝트가 아니라 전역 백업에 쌓는다.

**둘째 경우에는 그 파일 옆에 잠금 디렉터리와 임시 파일이 잠깐 생겼다 사라진다.** 파일을 통째로 바꿔치기하는 방식이라 같은 폴더에 임시 파일을 두어야 하기 때문이다(다른 곳에 두면 디스크가 다를 때 바꿔치기가 원자적이지 않다). 작업이 끝나면 지워지므로 남는 파일은 없지만, 도중에 강제로 끊기면 `CLAUDE.md.lock` 같은 것이 남을 수 있다. 그때는 지워도 된다.

**프로젝트 오답노트를 처음 만드는 것은 자동 계층이 아니라 사람이다.** 그 레포에서 문제를 해결해 적을 교훈이 생겼을 때 세션이 만든다(그 규율은 `agent-principles.md`의 오답노트 절이 정본이다). 그래서 파일이 저절로 생기기를 기다릴 것이 아니고, 설치만 해 둔 레포에는 아무 파일도 생기지 않는다.

## 설치
**Windows 사용자는 [Git Bash](https://git-scm.com/downloads)가 필수다.** SessionStart hook이 `bash "...scaffold.sh"`로 스크립트를 돌리는데 Windows엔 bash가 없다(없으면 PowerShell로 넘어가 실패한다). 실행권한 비트(`chmod +x`)는 필요 없다. mac과 Linux는 bash가 기본으로 깔려 있어 따로 설치할 것이 없다(훅은 sh가 아니라 bash를 호출한다).

Claude Code에서 아래 두 줄을 친다.

```text
/plugin marketplace add chshin84/disciplined-coder
/plugin install disciplined-coder@chshin-tools
```

그다음 새 세션을 한 번 열고 아래 「이렇게 보이면 성공이다」로 확인한다. 업데이트는 `/plugin marketplace update chshin-tools`로 한다. 이 레포가 곧 마켓플레이스다(`.claude-plugin/marketplace.json`).

직접 고쳐 쓰거나 기여하려면 이 디렉터리를 클론해 `claude plugin install ./ --scope user`로 깐다. 모든 프로젝트에서 자동 활성화된다.

**어느 경로든 스코프가 user인지 확인한다.** `claude plugin install`의 기본 스코프는 `user`이고 `--scope`로 바꾼다. project나 local로 깔리면 그 프로젝트 세션에서만 hook이 돌아, 다른 프로젝트에서 아무 일도 안 일어난다. 그런데 그 상태가 겉으로는 정상과 똑같이 보이므로 아래 「이렇게 보이면 성공이다」를 거친다.

> **왜 user scope인가** — scaffold 출력은 어느 스코프로 깔든 PC 전역(`~/.claude/`)에 쓴다. 그러나 SessionStart hook이 **발동**하는 곳은 플러그인이 활성인 세션뿐이다. user scope면 모든 프로젝트의 모든 새 세션에서 hook이 돌아, 어느 세션에나 닿는 것과 정본을 최신으로 갱신하는 것이 함께 보장된다(project scope는 그 프로젝트 세션에서만 발동·갱신).

## 사용
설치(user scope) 후 **새 Claude Code 세션을 시작**하면 SessionStart hook이 자동 실행된다. 이후 어느 프로젝트에서 열어도 메인 세션이 원칙 + 도메인 목차 + 오답노트를 자동으로 보유한다. 서브에이전트는 종류에 따라 갈린다([DESIGN-NOTES](docs/DESIGN-NOTES.md)의 실측 표를 보라).

### 이렇게 보이면 성공이다
셋업은 조용히 돌기 때문에 성공과 실패가 겉으로 같아 보인다. 특히 Windows에서 bash가 없어 hook이 실패한 경우와 정상 동작이 화면상 구별되지 않는다. 새 세션을 한 번 연 뒤 아래 셋을 확인한다.

**먼저 설정 홈이 어디인지부터 확인한다.** 스캐폴드는 그곳을 환경에 따라 다르게 잡으므로 `~/.claude`라고 넘겨짚지 않는다.

```bash
bash -c '. "${CLAUDE_PLUGIN_ROOT}/scripts/_resolve_home.sh" && resolve_home claude'
```

- `/show-principles`를 치면 원칙 목록이 나온다.
- 그 설정 홈에 `agent-principles.md`·`domains-index.md`·`solved_problems.md`가 있다.
- 같은 설정 홈의 `CLAUDE.md`에 `# BEGIN disciplined-coder`로 시작하는 관리블록이 있다.

셋 중 하나라도 없으면 셋업이 안 돈 것이다. Windows라면 Git Bash부터 확인하고, 그다음 `/setup-discipline`으로 수동 재실행한다.

**첫 항목만 되고 뒤의 둘이 안 보이면 셋업 실패가 아니라 홈이 어긋난 것이다.** 회사 PC는 네트워크 홈 리다이렉트 때문에 bash의 `$HOME`과 Windows의 `USERPROFILE`이 다를 수 있어, 파일은 멀쩡히 깔렸는데 엉뚱한 곳을 들여다보게 된다. 위 명령으로 실제 경로를 확인하고 거기서 다시 찾는다.

### 커맨드 (수동 트리거)
설치 직후에는 셋업이 실제로 반영됐는지 눈으로 확인할 때, 그 뒤에는 활성화된 내용을 확인하거나 셋업을 다시 돌리고 싶을 때 쓴다.
```text
/show-principles     # 현재 활성 디시플린 정본(agent-principles.md 사본) 보기
/show-solved         # 해결된 문제 오답노트 보기
/setup-discipline    # PC 전역 셋업을 수동 재실행(멱등 — 여러 번 안전)
```

## Codex에서 쓰기 (동일 디시플린)
이 레포는 Claude Code 플러그인이자 **Codex 플러그인**이다(`.codex-plugin/plugin.json`). Codex도 같은 원칙·스킬·강제 게이트(spec/plan·문서 리뷰)를 받는다.
1. 이 레포를 Codex 플러그인으로 설치한다(`codex plugin` 설치 경로).
2. **신뢰검토 필수** — Codex는 플러그인 훅을 *신뢰*하기 전엔 조용히 건너뛴다. 설치 후 한 번 훅을 신뢰해야 게이트가 작동한다(세션 시작 시 경고가 뜬다).
3. 새 Codex 세션을 시작하면 `session-start-codex` 훅이 `~/.codex/disciplined-coder/` 셋업 + `~/.codex/AGENTS.md` 관리블록 배선 + 원칙 주입을 자동 수행한다.

무엇을 공유하고 어디서 갈라지는지는 [DESIGN-NOTES](docs/DESIGN-NOTES.md)에 적었다.

## 주의
- **플러그인 루트 `CLAUDE.md`는 컨텍스트로 로드되지 않는다** — 주입 경로는 `~/.claude/CLAUDE.md`의 `@import`다.
- **호스트 셸에 기댄다** — hook은 컨테이너가 아니라 호스트에서 돌기 때문에, Windows에서는 Git Bash가 있어야 한다.
- **CLAUDE.md는 강제가 아니라 가이드다** — 🔴 자율구현 같은 지시를 진짜로 막으려면 `PreToolUse` hook을 걸어 강제해야 한다.
- **빌트인 읽기 전용 종류(`Explore`·`Plan`)에는 실리지 않는다.** 그리고 **자기 서브에이전트를 정의해 쓴다면 원칙이 실린다고 믿지 마라** — 우리가 실제로 잰 것은 네 종류뿐이라 사용자가 직접 정의한 서브에이전트는 재 보지 않았다. 그런 리뷰어를 쓸 때는 정본 경로를 프롬프트에 넣어라.
- **병렬 오케스트레이션 절차는 superpowers 플러그인을 함께 깔아야 돈다.** 원칙의 그 절과 `skills/nested-orchestration`이 `dispatching-parallel-agents`·`brainstorming` 같은 superpowers 스킬로 라우팅하는데, 그것들은 이 플러그인에 들어 있지 않다. 안 깔려 있으면 그 자리에서 조용히 건너뛰게 된다. 나머지 기능은 superpowers 없이도 그대로 돈다.

## 더 읽기
- 디시플린 정본: [`agent-principles.md`](agent-principles.md) · 도메인 목차: [`domains-index.md`](domains-index.md)
- 설계 근거·한계·저장소 구성·무엇을 왜 자동화하는가: [docs/DESIGN-NOTES.md](docs/DESIGN-NOTES.md)
- 도메인별 상세: `skills/domain-*` (온디맨드)

## 메인테이너
- chshin84 \<chshin84@gmail.com\> · 이슈/제안은 [chshin84/disciplined-coder](https://github.com/chshin84/disciplined-coder) 저장소로.

## 라이선스
라이선스를 아직 정하지 않았다. 별도로 명시하기 전까지는 저작자가 모든 권리를 보유한다(두 매니페스트가 선언하는 `UNLICENSED`와 같은 뜻이다). 정해지면 `LICENSE` 파일을 두고 이 절에 적는다.
