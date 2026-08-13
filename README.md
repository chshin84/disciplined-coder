# disciplined-coder

팀 엔지니어링 원칙 + 프로젝트 간 공통 함정을 `agent-principles.md`(SSOT)에 박아두고, SessionStart hook이 **PC-레벨**(`~/.claude/disciplined-coder/`)에 자동 셋업하는 Claude Code 플러그인.

**대상** — 팀 디시플린을 모든 프로젝트에 걸쳐 PC 전역으로 깔되, 프로젝트 폴더는 (자동으로는) 더럽히고 싶지 않은 Claude Code 사용자.

## Highlights
- **프로젝트 폴더 footprint zero (자동)** — 지식은 `~/.claude/CLAUDE.md` 관리블록이 `@import`로 주입한다. 어느 프로젝트를 열어도 작업 폴더엔 **자동으로는** 아무 파일도 안 생긴다. 그 레포에서 문제를 해결해 적을 교훈이 생기면 그때 `docs/solved_problems.md`를 만든다.
- **메인 세션과 커스텀 서브에이전트에 도달** — PC-레벨 주입이라 메인 세션과 커스텀 서브에이전트가 같은 원칙·오답노트를 자동으로 보유한다. **다만 에이전트 종류에 따라 갈린다** — 빌트인 읽기 전용 종류에는 실리지 않는다(실측 표는 [DESIGN-NOTES](docs/DESIGN-NOTES.md)).
- **설치 후 무조작** — 새 세션을 시작하면 hook이 알아서 셋업·배선한다(멱등).
- **첫 설치 세션에서만 이중 전달** — 관리 블록이 막 생긴 세션은 아직 `@import`만으로는 정본에 닿지 못하므로, 그 세션 한 번에 한해 정본을 stdout(주입 컨텍스트)으로 함께 보내 조용한 누락을 막는다(`FAIL-LOUD`). 두 번째 세션부터는 세션 시작 때 `@import`가 읽은 내용이 그 뒤 요청에도 실린다.
- **글쓰기·문서 디시플린** — 답변 표현(명확·저피로·리듬 — 짧은 답보다 피로도 낮은 답)은 `CLEAR-COMM`이 상시 잡고, 문서는 사람의 작성 흐름을 흉내 낸다 — 쓰기 전 양식 제안, 다 쓰면 검진 넛지.

## 무엇을·왜 자동화하나
모든 세션이 같은 디시플린을 들고 일하게 하되, **자동 계층(scaffold·훅)은 프로젝트 폴더를 건드리지 않는다**. 그래서 지식을 프로젝트가 아니라 **PC-레벨**(`~/.claude/`)에 두고, `~/.claude/CLAUDE.md`의 관리블록이 그것을 `@import`한다. **서브에이전트에 이 메모리 계층이 실리는지는 에이전트 종류에 따라 갈린다** — 한 곳에 배선하면 메인 세션과 커스텀 서브에이전트에는 도달하지만 빌트인 읽기 전용 종류에는 실리지 않는다(실측 표와 대응 방법은 [DESIGN-NOTES](docs/DESIGN-NOTES.md)).

자동화 대상:
- **일반 지식**(원칙 + 공통 gotchas + 도메인 목차) — `agent-principles.md`·`domains-index.md`(SSOT)를 `~/.claude/disciplined-coder/`에 복사하고 `~/.claude/CLAUDE.md` 관리블록에 `@import`로 배선한다.
- **오답노트**(solved) — `~/.claude/disciplined-coder/solved_problems.md`가 없으면 생성한다(PC 전역 누적, 멱등, append-only). 운영 규약(완결 후 등록이라 상태 아님, 단일 작성자, 🔴 surface·자율구현 금지, **이슈 트래킹 안 함**)은 `agent-principles.md`의 오답노트 절이 SSOT다.
- **스킬**(domain-*/reviewer-*/meta-aggregate) — 플러그인에서 온디맨드로 로드한다. 복사·주입하지 않는다.

### 도메인 참고서 + 런타임/메타 검증
개발 대상(도메인)에 따라 "마땅히 그래야 하는 것"이 있다. `domains-index.md`(자동 주입되는 목차)가 도메인과 참고서를 안내하고, 각 `skills/domain-*`가 상세를 온디맨드로 제공한다 — 설계 시 명세 반영, 개발 시 폴백.
- **LLM 런타임**: 제품이 런타임에 LLM을 호출하면 단독 콜로 끝내지 말고 검증 레이어를 구현한다. `skills/domain-llm-runtime`(호출자)이 리스크에 따라 `skills/reviewer-*`(렌즈)와 `skills/meta-aggregate`(집계)를 **제품 코드의 리뷰 콜**로 구현하게 한다(Claude Code 에이전트가 아니라 제품이 구현할 청사진).
- **메타 산출물 리뷰**: spec/plan도 Claude의 LLM 산출물이다. `skills/domain-spec-review`가 PREP → 독립 렌즈(grounding/consistency/adversarial, 그리고 spec이 미지의 영역을 다룰 때만 조건부로 웹에 나가는 prior-art) → meta-aggregate → accept/regenerate/escalate로 검증한다. superpowers 기본 경로(`docs/superpowers/{specs,plans}`)에 쓰이면 **훅이 강제**한다(PostToolUse 감지 + Stop 게이트; 문서 마지막 줄 `<!-- spec-review: passed -->` 또는 `escalated` 마커로 해제; 끄기 `DISCIPLINED_CODER_REVIEW_GATE=off`).
- **문서 작성 워크플로**: 일반 문서(README 등)는 사람이 글 쓰는 흐름을 흉내 낸다 — 작성 **전** `PreToolUse` 훅이 새 `.md`에 `domain-docs` 양식을 제안하고, 작성 **후** `PostToolUse` 훅이 독립 검진(`reviewer-grounding`+`reviewer-fit`)을 넛지한다. 셀프 퇴고만으로 끝내지 않되, 발행물엔 마커를 안 박으므로 spec/plan과 달리 **비블로킹**(권유)이다. 같은 OFF 토글을 쓴다.

## 설치 (user scope 권장)
> **왜 user scope인가** — scaffold 출력은 어느 스코프로 깔든 PC 전역(`~/.claude/`)에 쓴다. 그러나 SessionStart hook이 **발동**하는 곳은 플러그인이 활성인 세션뿐이다. user scope면 모든 프로젝트의 모든 새 세션에서 hook이 돌아 reach + 정본 refresh가 함께 보장된다(project scope는 그 프로젝트 세션에서만 발동·갱신).

**전제 조건 — Windows 사용자는 [Git Bash](https://git-scm.com/downloads) 필수.** SessionStart hook이 `bash "...scaffold.sh"`로 스크립트를 돌리는데 Windows엔 bash가 없다(없으면 PowerShell 폴백 → 실패). 실행권한 비트(`chmod +x`)는 불필요. mac/Linux는 bash가 기본 탑재라 별도 설치 불필요(훅은 sh가 아니라 bash를 호출한다).

**A. 마켓플레이스로 (공유·배포)** — 이 레포가 곧 마켓플레이스다(`.claude-plugin/marketplace.json`).
1. `/plugin marketplace add chshin84/disciplined-coder`
2. `/plugin install disciplined-coder@chshin-tools`
3. 업데이트: `/plugin marketplace update chshin-tools`

**B. 로컬 클론으로 (개발·기여)**
1. 이 디렉터리를 클론한다.
2. `claude plugin install ./ --scope user` (모든 프로젝트에서 자동 활성화).

검증: `claude plugin validate ./`. `--strict`는 version 미지정 경고 때문에 실패하는데, 이는 의도된 트레이드오프다 — 활성 개발 중엔 version을 비워야 커밋 SHA 기반 자동 업데이트가 유지된다(상세는 `skills/domain-plugin`).

### Codex에서 쓰기 (동일 디시플린)
이 레포는 Claude Code 플러그인이자 **Codex 플러그인**이다(`.codex-plugin/plugin.json`). Codex도 같은 원칙·스킬·강제 게이트(spec/plan·문서 리뷰)를 받는다.
1. 이 레포를 Codex 플러그인으로 설치한다(`codex plugin` 설치 경로).
2. **신뢰검토 필수** — Codex는 플러그인 훅을 *신뢰*하기 전엔 조용히 건너뛴다. 설치 후 한 번 훅을 신뢰해야 게이트가 작동한다(세션 시작 시 경고가 뜬다).
3. 새 Codex 세션을 시작하면 `session-start-codex` 훅이 `~/.codex/disciplined-coder/` 셋업 + `~/.codex/AGENTS.md` 관리블록 배선 + 원칙 주입을 자동 수행한다.

차이(정직): Codex는 `@import` 미지원이라 원칙을 AGENTS.md 인라인 + 세션 주입의 이중 경로로 전달한다. 파일 편집은 `apply_patch`로 가므로 게이트 훅이 그 입력을 읽는다. 동작은 Claude와 동일하되, 위 신뢰검토 단계가 추가된다.

## 사용
설치(user scope) 후 **새 Claude Code 세션을 시작**하면 SessionStart hook이 자동 실행되어:
- `~/.claude/disciplined-coder/`에 정본 사본과 오답노트·설정 파일을 셋업한다(정확한 목록은 scaffold 공통 헬퍼의 `SCAFFOLD_WHITELIST`가 정본이다)
- `~/.claude/CLAUDE.md` 관리블록에 `@import`를 배선한다(없으면 생성하고, 있으면 멱등 갱신한다)

이후 어느 프로젝트에서 열어도 메인 세션이 원칙 + 도메인 목차 + 오답노트를 자동으로 보유한다. 서브에이전트는 종류에 따라 갈린다([DESIGN-NOTES](docs/DESIGN-NOTES.md)의 실측 표를 보라). **자동 계층은 프로젝트 폴더를 건드리지 않는다.**

### 커맨드 (수동 트리거 — 평소엔 불필요)
설치 후 평소엔 손댈 게 없지만, 활성화된 내용을 확인하거나 셋업을 다시 돌리고 싶을 때 쓴다.
```text
/show-principles     # 현재 활성 디시플린 정본(agent-principles.md 사본) 보기
/show-solved         # 해결된 문제 오답노트 보기
/setup-discipline    # PC 전역 셋업을 수동 재실행(멱등 — 여러 번 안전)
/issue-mode [모드]   # 오답노트 미해결 처분 모드 토글: surface(기본)|issues (없으면 현재 표시)
/ultracode-review [모드] # ultracode 워크플로 검증 모드 토글: discretion(기본)|required (없으면 현재 표시)
```

## 구성
```
disciplined-coder/
├── .claude-plugin/plugin.json      # 매니페스트
├── agent-principles.md             # 디시플린 정본 (SSOT) — hook이 ~/.claude/disciplined-coder/로 복사
├── domains-index.md                # 도메인 참고서 인덱스 (동일 경로로 복사)
├── skills/domain-*/SKILL.md        # 도메인 참고서(docs/plugin/llm-runtime) + 호출자 domain-spec-review
├── skills/reviewer-*/SKILL.md      # 리뷰어 렌즈(grounding/fit/consistency/adversarial/prior-art)
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
├── scripts/test_codex_scaffold.sh  # Codex 셋업·매니페스트·세션훅 검증 (FAIL=0)
├── scripts/test_scaffold.sh        # scaffold 검증 (CLAUDE_HOME_DIR 임시홈, 실제 ~/.claude 미오염)
├── scripts/test_hooks.sh           # 훅 불변식 테스트 (계약 FAIL=0)
├── scripts/test_docs_drift.sh      # 문서의 렌즈 열거가 실제와 어긋나지 않는지 (계약 FAIL=0)
├── commands/*.md                  # 수동 커맨드(전체 목록은 '사용 > 커맨드' 절이 정본)
├── docs/DESIGN-NOTES.md            # 개발자용 내부 근거(주입 메커니즘·한계·업그레이드)
└── README.md
```
> `~/.claude/disciplined-coder/`에 생성되는 파일 목록은 scaffold 공통 헬퍼의 `SCAFFOLD_WHITELIST`가 정본이다. 스킬은 플러그인에서 온디맨드 로드 — 복사하지 않는다.

## 주의
- **플러그인 루트 `CLAUDE.md`는 컨텍스트로 로드되지 않는다** — 주입 경로는 `~/.claude/CLAUDE.md`의 `@import`다.
- **호스트 셸 의존** — hook은 호스트에서 돈다(컨테이너 아님). Windows는 Git Bash 필요.
- **CLAUDE.md는 강제가 아닌 가이드** — 🔴 자율구현 같은 지시를 진짜 막으려면 `PreToolUse` hook로 강제.
- 주입 메커니즘·예외(Explore/Plan), 깊은 한계, 구버전 업그레이드는 → **[DESIGN-NOTES](docs/DESIGN-NOTES.md)**.

## 더 읽기
- 디시플린 정본: [`agent-principles.md`](agent-principles.md) · 도메인 목차: [`domains-index.md`](domains-index.md)
- 설계 근거·한계: [docs/DESIGN-NOTES.md](docs/DESIGN-NOTES.md)
- 도메인별 상세: `skills/domain-*` (온디맨드)

## 메인테이너
- chshin84 \<chshin84@gmail.com\> · 이슈/제안은 [chshin84/disciplined-coder](https://github.com/chshin84/disciplined-coder) 저장소로.

<!-- 라이선스: 미정(추후 결정 시 LICENSE 파일 + 본 섹션에 표기). 현재는 별도 명시 전까지 저작자가 모든 권리 보유. -->

