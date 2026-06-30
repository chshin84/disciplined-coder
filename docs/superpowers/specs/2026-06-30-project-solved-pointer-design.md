# 프로젝트 오답노트 포인터 (project-solved) — 설계 (2026-06-30)

> 3렌즈 리뷰 2회 반영본. v2 majors 해소: codex 넛지 미러 제거(넛지는 Claude 전용), 포인터에 단일
> 작성자 규약 포함, solved 템플릿 '제거' 문구를 append-only와 화해, 신규 훅 대신 기존 doc_review에
> 통합(+OFF 토글), footprint 불변식 README 3곳 전부 동기화. self-heal은 v1→v2에서 넛지로 단순화됨.

## 문제 (왜)

solved 오답노트가 **PC 전역 한 곳뿐**이다(`~/.claude/disciplined-coder/solved_problems.md`). 그래서 둘이 깨진다.

- **갈 곳 없는 프로젝트 교훈** — 이 레포만의 quirk(예: "`test_codex_scaffold`는 이 PC의 Store python3
  스텁 때문에 node 폴백 필요")는 머신 전역이 아니다. PC 로그에 넣으면 무관 프로젝트로 새고 썩는다
  (`SSOT` 위반). 진짜 홈은 **그 레포 안**이다.
- **플러그인·머신 종속 도달** — PC 로그는 git으로 이동하지 않고, disciplined-coder 없는 세션엔 보이지
  않는다(동기 예시, 대화 이력 기반: 프로젝트 recall이 있었으면 자체 해소됐을 부류의 되물음이 있었다).

그리고 recall은 **에이전트가 볼 줄 알아야** 작동한다 — 상시 로드되는 포인터가 없으면 트리거되지 않는다.

## 핵심 원칙

- **`스코프 라우팅`** — 교훈은 범위대로 **한 집**(복제 금지): 프로젝트(`docs/solved_problems.md`) → PC
  (머신 전역) → 원칙(`agent-principles.md`). *어느 계층에 기록하느냐*를 정하는 규칙이다. 계층 간 **승격**
  (상위 계층에 재기술)은 `§다`의 권고이지 이 spec이 만드는 자동 도구가 아니다(비목표).
- **`자기완결 포인터`** — 레포 `./CLAUDE.md`(Claude Code가 **네이티브 상시 로드** — 표준 동작; 플러그인
  *루트* CLAUDE.md가 안 실리는 것과 다른 경로)에 *recall 지시 + 경로*를 둔다. 평문이라 disciplined-coder
  없이도 **Claude Code 세션**이 읽고 따른다. (Codex는 `AGENTS.md`를 로드하므로 미도달 — 비목표/미래.)
- **`포인터 상시 · 내용 온디맨드`** — 항상 로드하는 건 한 줄 포인터뿐. 로그 본문은 이슈가 생겼을 때만 읽는다.
- **`드리프트는 넛지로`** — 어긋남은 **자동 수정하지 않고 넛지로 표면화**한다(`EXPLICIT` — 사용자가 안
  시킨 프로젝트 쓰기 금지). 넛지는 기존 doc 넛지와 같은 비블로킹·`DISCIPLINED_CODER_REVIEW_GATE=off` 존중.

## 구성요소 (ID 글로서리 · 무순서)

- **`주입 프리미티브`** — CLAUDE.md류 파일에 `BEGIN/END` 관리블록을 멱등 주입하는 공유 헬퍼(타깃 파일·본문
  파라미터화). 마커 grep → 영역 strip/append, CRLF 내성, **반쯤 깨진 블록(BEGIN만·END 없음) = WARN+보존**,
  관리영역 밖 사용자 내용 보존(말미 공백 정규화 제외). **지금 `scaffold.sh`와 `codex-scaffold.sh`가 이
  로직을 각자 인라인 중복**(DRY 위반)한다 — 추출이 그 중복을 제거하고 `/add-pointer`까지 **소비자 3**.
  `scaffold`·`codex-scaffold`의 `test_*` FAIL=0 계약이 회귀 가드. **시퀀싱(blast-radius 완화)**: 먼저
  두 스크립트에서 추출→`test_scaffold`·`test_codex_scaffold` 그린 확인→그 뒤 `/add-pointer`가 헬퍼 소비.
- **`/add-pointer`** — 프로젝트 CLAUDE.md에 관리 포인터를 추가하는 커맨드(+`scripts/add-pointer.sh`).
  **무인자**(기본 동작 = solved): `docs/solved_problems.md` 생성(없으면) + 자기완결 포인터 주입(프리미티브).
  **옵트인 — 프로젝트 폴더에 쓰는 유일한 동작**(다른 모든 자동 계층은 프로젝트 무손상). 둘째 종류가 실재하면
  선택 인자를 **가산**(rename 불필요 — `YAGNI`).
- **`자기완결 포인터 블록`** — `./CLAUDE.md`의 `BEGIN/END` 관리영역(`managed — do not edit`): recall +
  기록 지시를 **단일 작성자 규약까지 담아** 자기완결로 둔다 — "디버깅·이슈 처리·중요한 결정 전에
  `docs/solved_problems.md`를 먼저 확인한다(이 프로젝트에서 해결한 문제의 증상→교훈). 완결하면 **메인
  세션이** 거기에 append한다(서브에이전트는 직접 쓰지 말고 리턴으로 보고)." 평문·플러그인 비의존이라
  plugin-less 경로에서도 `§다` 단일 작성자 규약이 유지된다.
- **`발견·복구 넛지`(기존 doc_review 훅에 통합)** — 별도 훅을 더하지 않고 **기존 `doc_review_posttooluse.sh`**
  (이미 `PostToolUse(Write|Edit)`·`*.md`·OFF 토글 존중)에 분기를 더한다(이중 넛지 회피). 대상이 **프로젝트
  루트 CLAUDE.md**일 때(basename=`CLAUDE.md` **AND** dir=정규화(`CLAUDE_PROJECT_DIR`) 동치 — 백슬래시·
  드라이브케이스 정규화; `CLAUDE_PROJECT_DIR` 미설정/빈값이면 **no-op**[안전 — 넛지 누락은 무해, 조용한
  *오작동*은 없음]; basename만으로는 scaffold의 `~/.claude/CLAUDE.md` 오탐 방지) 상태표(↓)대로 넛지만 낸다.
- **`§다 recall 일반화`**(변경) — `agent-principles.md` §다에 "디버깅·구현 전 **PC solved + 프로젝트
  solved(포인터 있으면) 둘 다** recall"과 라우팅 규칙(범위대로 한 집)을 **한 줄 추가**. 터스 유지.
- **`solved 정합 갱신`**(변경) — (a) `domain-docs` 문서타입 표의 **기존 solved 행에 스코프 축(PC/프로젝트)**
  을 접어 넣는다(새 행 금지 — `SSOT`). (b) append-only는 **한 계층 안에서** 불변, 승격은 상위 계층 **재기술**
  (바이트 이동 아님)임을 명시. (c) **두 scaffold의 solved 템플릿 heredoc**("일반화 항목은 승격하고 여기서는
  제거")을 같은 화해 문구로 고쳐, 같은 헤더의 'append-only·과거 안 지움'과의 충돌(기존 잔존 드리프트)을 해소.
- **`dogfood`** — 이 레포 자신에 `/add-pointer` 적용(`docs/solved_problems.md` + `./CLAUDE.md` 포인터).

## 발견·복구 넛지 — 상태 (자동 쓰기 없음 · OFF 토글 존중)

| 상태 (로그·포인터) | 프로젝트 루트 CLAUDE.md가 Write/Edit될 때 |
|---|---|
| 로그 **없음** (포인터 무관) | **발견 넛지**: "`/add-pointer`로 오답노트 추가?" |
| 로그 있음 + 포인터 **정상** | 무동작 |
| 로그 있음 + 포인터 **없음/반깨짐** | **복구 넛지**: "`/add-pointer` 재실행해 포인터 복구?" |

훅은 어느 경우도 프로젝트 파일을 쓰지 않는다(`EXPLICIT`); `DISCIPLINED_CODER_REVIEW_GATE=off`면 침묵.
실제 생성·복구는 **사용자가 `/add-pointer`를 호출할 때만**(멱등 — 반쯤 깨진 블록도 프리미티브가 정상화).
`/init`이 포인터를 덮어써도 다음 Write의 복구 넛지로 표면화(자동 재주입의 경합·의도덮어쓰기 없음 — `SIMPLE`).

## 불변식·경계 (정직히)

- **footprint-zero 동기화(3곳 전부)** — 자동 계층(`scaffold`·훅)은 프로젝트에 **아무것도 쓰지 않는다**
  (넛지만). 프로젝트 쓰기는 **사용자가 명시 호출한 `/add-pointer` 하나뿐.** README의 footprint 절대 단정
  **전부(grep으로 식별 — 현재 L5·L8·L15·L57 등; L95는 footprint 아님)를 빠짐없이** *"자동 footprint-zero + 명시 `/add-pointer` 옵트인"*으로 동기화한다
  (한 곳이라도 누락 시 간판 약속이 거짓 — 성공 기준이 신규 거짓 0을 검증). 이는 '범주적 0 → 옵트인 예외 0'
  으로 간판 개념을 **의식적으로 한 번** 약화하는 일방문이며, 근거(프로젝트-국소 교훈의 홈 필요)를 남긴다(`REVERSIBLE`).
- **`/init` 충돌** — `/init`이 포인터를 덮어도 **자동 복구 안 함·복구 넛지**로 표면화 → 사용자가
  `/add-pointer` 재실행(멱등).
- **codex 도달 공백** — 포인터·넛지는 Claude Code 경로(`./CLAUDE.md`) 전용. **넛지는 `hooks-codex.json`에
  미러하지 않는다**(Codex는 `AGENTS.md` 로드 — 죽은 배선/오권유 방지). 단 **프리미티브 추출**은 `codex-scaffold.sh`
  의 중복 제거이므로 codex 측도 그 헬퍼를 소비한다(둘은 다른 사안). codex의 프로젝트-solved 도달은 비목표/미래.
- **회수(orphan) 비대칭** — 프로젝트 `./CLAUDE.md` 관리블록은 scaffold GC 경로 밖(프로젝트 무손상). 기능
  제거·리네임 시 사용자 레포에 고아 블록 잔존 가능 — `managed` 표시라 수동 제거 쉬움. 숨기지 않는다(`FAIL-LOUD`).
- **작성자 분리** — 틀=스크립트(`/add-pointer`, 멱등·테스트가능; bash 쓰기라 Write 도구 미경유 → PostToolUse
  미발동), 교훈 append=메인 세션. `§다` 단일 작성자 규약 유지(포인터 본문에도 명시).

## 비목표 (이 spec 밖)

- review-outbound(이슈/PR 렌즈리뷰) — 별도 spec. `bootstrap-issues` 리네임·Q5 codex 버전 동기화 — 별건.
- **승격 자동화** — 상위 계층 이동은 `§다` 권고이지 도구로 만들지 않는다(`YAGNI`).
- **codex 프로젝트-solved 도달**(`AGENTS.md` 미러)·**`/add-pointer` 둘째 종류** — 미래.
- **포인터 자동 주입/자동 복구** — 채택 안 함(넛지만 / `EXPLICIT`).

## 성공 기준 (무엇이 "됨")

- 계약 테스트 **FAIL=0** 유지(scaffold·hooks·codex; 매직넘버 없이 불변식). **프리미티브 추출 후
  `test_scaffold`·`test_codex_scaffold` 회귀 0**(기존 계약이 가드 — 시퀀싱대로 추출 먼저 그린).
- 신규 테스트(불변식): `/add-pointer` 멱등(2회 = 로그 1·포인터 블록 1), 기존 `./CLAUDE.md` 내용 보존(말미
  공백 정규화 허용), 포인터에 recall **및 단일 작성자** 문구 포함, 재실행 시 로그 append 보존, **반쯤 깨진
  블록 정상화**, **발견 넛지=로그 없을 때만·복구 넛지=로그 있고 포인터 없을 때만·정상 상태=무넛지**,
  **OFF 토글 시 침묵**, **CLAUDE.md 한 번 쓰기에 넛지 1개**(doc_review와 이중 안 뜸), **훅이 프로젝트
  파일 안 씀**, **경로 감지 정규화 + `CLAUDE_PROJECT_DIR` 미설정 시 no-op**.
- `§다` 듀얼 recall 문구 존재(검증), `domain-docs` solved 행 스코프 축 존재(검증), **두 scaffold solved
  템플릿이 append-only와 정합**(검증).
- **README footprint 절대 단정 전부(grep 식별)가 옵트인 동기화**(미한정 단정 0 = 신규 거짓 0). `claude plugin validate ./` 통과(신규 경고 0).
- **dogfood**: 이 레포에 `docs/solved_problems.md` + `./CLAUDE.md` 포인터 존재.

## 변경 대상 (이 설계가 박힐 곳)

- **신규** — `scripts/add-pointer.sh`, `commands/add-pointer.md`, 공유 **주입 헬퍼**(추출원: `scaffold.sh`·
  `codex-scaffold.sh`의 중복 로직).
- **편집** — `scaffold.sh`·`codex-scaffold.sh`(인라인 중복 → 공유 헬퍼 호출 **+ solved 템플릿 문구 화해**),
  `hooks/doc_review_posttooluse.sh`(프로젝트 CLAUDE.md 발견·복구 넛지 분기 — **신규 훅 아님**), `agent-principles.md`
  §다(듀얼 recall), `skills/domain-docs/SKILL.md`(solved 행 스코프 축 + 승격=재기술 명시), `README.md`
  (footprint 단정 3곳 동기화), `test_scaffold.sh`·`test_hooks.sh`(신규 케이스). `hooks-codex.json`은 **넛지
  미러 안 함**(프리미티브 추출만 codex-scaffold에 반영).

## 리뷰 이력 (3렌즈 2회 — 해소)

- **footprint-zero(전 라운드 수렴)** — 자동 쓰기 전무(넛지化)로 *자동* footprint-zero 유지; README **3곳
  전부** 동기화(성공기준 검증). 간판 약화는 의식적 일방문으로 근거와 함께 명시.
- **self-heal 위험(v1 adversarial)** — 넛지化로 경합·의도덮어쓰기·루프 소멸.
- **codex 넛지 미러 모순(v2 consistency·grounding)** — 넛지는 Claude 전용, codex 미러 제거. 프리미티브 추출(codex 중복 제거)과 구분.
- **포인터 단일작성자 누락(v2 consistency)** — 포인터 본문에 "메인 세션이 append·서브에이전트는 리턴" 명시.
- **solved 템플릿 충돌(v2 consistency)** — 두 scaffold heredoc의 '제거' 문구를 append-only와 화해(변경 대상 추가).
- **이중 넛지(v2 consistency·adversarial)** — 신규 훅 대신 기존 doc_review에 통합, OFF 토글 존중, 1동작 1넛지.
- **프리미티브 blast-radius(v2 adversarial)** — 실측 2중 중복이 근거; 시퀀싱(추출→그린→소비)으로 위험 완화, FAIL=0 가드.
- **경로 엣지(v2)** — `CLAUDE_PROJECT_DIR` 미설정 시 no-op(안전), 정규화 동치 비교 명시.
- **minor** — 무인자 커맨드(브리핑 `<kind>`에서 진화, 사유 명기), 상태표 포인터-무관 셀, `§다` 표기 정밀화.

<!-- spec-review: passed -->
