# disciplined-coder Phase 4 (도메인 참고서 틀) Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: superpowers:subagent-driven-development. Steps use checkbox (`- [ ]`).

**Goal:** "개발 대상(도메인)별 마땅히 그래야 하는 것"을 설계/계획 단계에 흘려넣는 **틀**을 만든다. 항상 주입되는 umbrella 인덱스(`domains-index.md`) + 도메인별 온디맨드 스킬. 도메인 상세 내용은 **스텁(미완)** 허용(통증 있는 것부터 채움 — YAGNI).

**Architecture:** 어드바이저와 같은 *인덱스 + 온디맨드 상세* 패턴을 도메인 축으로 일반화. 항상 주입은 `domains-index.md` **하나로 통일**. 기존 `advisors-index.md`(LLM 런타임)는 온디맨드로 강등 → `skills/domain-llm-runtime/SKILL.md` 스킬로 이전하고 root 파일 삭제. 도메인 상세는 모두 스킬(`skills/domain-*`), 그래서 scaffold 변경은 "advisors-index → domains-index" 교체뿐.

**참조 spec/대화:** §6(어드바이저=LLM 도메인 특수사례), 도메인 스코프 논의(설계시점 1순위·개발 폴백, 플러그인관리/문서관리 분리, 문서관리=CC 핵심).

**설계 결정(승인됨):** (1) 항상 주입 = `domains-index.md` 하나(advisors-index 온디맨드 강등). (2) 초기 도메인 6종 + LLM = 7. 도메인 상세는 stub(문서관리·플러그인관리는 seed 약간).

---

## File Structure (Phase 4)
- **Create** `domains-index.md` — umbrella 인덱스(항상 주입).
- **Create** `skills/domain-llm-runtime/SKILL.md` — 기존 `advisors-index.md` 내용 이전(LLM 도메인 참고서; advisor-* 스킬을 가리킴).
- **Delete** `advisors-index.md` (내용은 위 스킬로 이전).
- **Create** `skills/domain-{docs,plugin,ui,app,agent,db}/SKILL.md` — 도메인 참고서. docs·plugin은 seed 일부, ui/app/agent/db는 stub.
- **Modify** `scripts/scaffold.sh` — PLUGIN_FILES·관리영역·stdout에서 `advisors-index.md` → `domains-index.md`.
- **Modify** `scripts/test_scaffold.sh` — advisors-index 검사 → domains-index 검사.
- **Modify** `coding-principles.md` — "절차"의 런타임 LLM 줄 일반화 + 도메인 설계 줄.
- **Modify** `README.md` — 도메인 틀 섹션; advisors 언급 갱신.
- **Re-run** scaffold on this repo (dogfood).

---

## Task 1: `domains-index.md` (umbrella 인덱스)

**Files:** Create `domains-index.md`

- [ ] **Step 1:** Create with this content:
```markdown
# 개발 대상(도메인) 참고서 — 인덱스

개발 대상에 따라 **마땅히 그래야 하는 것 / 그랬으면 하는 것**이 있다. 설계/계획 단계에서 해당 도메인 참고서를 확인해 **명세에 반영**하고(1순위), 명세에 못 담았으면 개발 단계에서 고려한다(폴백). 이 파일은 목차일 뿐 — 상세는 각 스킬(온디맨드).

| 도메인 | 언제(트리거) | 적용 시점 | 참조 스킬 | 상태 |
|---|---|---|---|---|
| 문서 관리 | 문서 작성·구조화 (Claude Code 핵심 — 문서 to 문서) | 설계·개발 | `domain-docs` | seed |
| 플러그인 관리 | CC 플러그인/마켓플레이스 제작 | 설계·개발 | `domain-plugin` | seed |
| UI | 화면·컴포넌트·상호작용 | 설계·개발 | `domain-ui` | stub |
| 앱 | 애플리케이션 | 설계·개발 | `domain-app` | stub |
| 에이전트 | 에이전트 시스템 | 설계·개발 | `domain-agent` | stub |
| DB | 스키마·쿼리·마이그레이션 | 설계·개발 | `domain-db` | stub |
| LLM 런타임 | 제품이 런타임에 LLM 호출 | **런타임** | `domain-llm-runtime` (+ `advisor-*`) | done |

## 사용
- **설계/계획 시**: 만들 대상이 위 도메인이면 해당 스킬을 열어 "마땅히 그래야 하는 것"을 명세에 반영.
- **개발 시**: 명세에 없으면 그때 참조.
- 상태 `stub`은 골격만 — 반복 통증이 확인된 도메인·항목부터 채운다(YAGNI·측정 먼저).
```

- [ ] **Step 2:** Commit: `git add domains-index.md && git commit -m "feat: add domains-index.md (umbrella domain reference index)"`

---

## Task 2: `domain-llm-runtime` 스킬로 이전 + `advisors-index.md` 삭제

**Files:** Create `skills/domain-llm-runtime/SKILL.md`; delete `advisors-index.md`

- [ ] **Step 1:** Create `skills/domain-llm-runtime/SKILL.md` (기존 advisors-index.md 내용을 스킬로):
```markdown
---
name: domain-llm-runtime
description: 제품이 런타임에 LLM을 호출하는 기능을 만들 때의 검증 레이어 참고서. 단독 콜로 끝내지 말고 리스크에 비례해 리뷰/메타 레이어를 코드로 구현. 구현 스펙은 advisor-* 스킬 참조.
---
# LLM 런타임 도메인 참고서

제품이 **런타임에 LLM을 호출**하는 기능은 단독 콜로 끝내지 말고 **검증 레이어**를 코드에 구현한다. 어드바이저는 Claude Code 에이전트가 아니라 **제품 코드가 구현할 청사진**이다.

## 4종 (구현 스펙은 각 advisor-* 스킬)
| 어드바이저 | 무엇을 본다 | 형태 | 스킬 |
|---|---|---|---|
| 정합성 | 출력이 요청/맥락에 맞나 — 누락·모순·환각 | 런타임 리뷰 콜 | `advisor-correctness` |
| 적합성 | 출력이 소비자 계약(형식/스키마/스타일) | 런타임 리뷰 콜 | `advisor-fit` |
| 비기능 | 호출 코드 견고성 — timeout/retry/None가드/에러형식/비용/관측/HITL | 구현 체크리스트 | `advisor-nonfunctional` |
| 메타 | 리뷰어 출력의 구조적 건강성(상충·공백). 내용 재판단 금지 | 집계·결정 | `advisor-meta` |

## 조립
1차 콜 → (리스크에 따라) 정합성·적합성 병렬 리뷰 콜 → 메타 집계(accept/regenerate/escalate) → 비기능은 전 과정 구현 요건으로 항상 적용.

## 리스크별 선택
외부호출 +1 / LLM 컴포넌트 +1 / 인터페이스 계약 변경 +1 / HITL·컴플라이언스 +1 / 명세 3섹션+ +1
- 0–1: 비기능만 · 2–3: 비기능+정합성 · 4–5: 전체+메타

## 비용
리뷰 콜은 추가 비용·지연. 리스크 비례로만. 결정론 검증 가능한 건(스키마/정규식) 코드로 먼저. critical만 regenerate 강제.
```

- [ ] **Step 2:** `git rm advisors-index.md`

- [ ] **Step 3:** Commit: `git add -A && git commit -m "refactor: move advisors-index into skills/domain-llm-runtime (on-demand); drop root advisors-index.md"`

---

## Task 3: 도메인 스텁 스킬 6종

**Files:** Create 6 `skills/domain-*/SKILL.md`

- [ ] **Step 1 — `skills/domain-docs/SKILL.md`** (seed):
```markdown
---
name: domain-docs
description: 문서 작성·구조화 시 참고서. Claude Code는 문서 to 문서로 일하므로 핵심 도메인. 설계/계획 시 명세에 반영.
---
# 문서 관리 도메인 참고서 (seed)

## 범위
원칙/참조/설계 문서를 쓰고 구조화하는 방법.

## 항목 (seed — 계속 보강)
- **ID로 참조, 서수 번호 금지** — 목차/번호(A/B/C, 1·2·3)는 거짓 우선순위를 암시. 안정적 ID + 무순서(알파벳 글로서리).
- **문서 SSOT** — 같은 사실은 한 문서에만. 다른 문서는 참조(@import/링크). 복제 금지.
- **관리 영역 패턴** — 자동 생성 구간은 BEGIN/END 마커로 감싸 재생성(멱등). 사용자 콘텐츠는 그 위.
- **어디에 둘까** — 항상 필요=CLAUDE.md/@import, 온디맨드=skill, 경로 한정=rules.

## TODO
- 문서 버전/갱신 주기, 폐기(archive) 규약 등.
```

- [ ] **Step 2 — `skills/domain-plugin/SKILL.md`** (seed):
```markdown
---
name: domain-plugin
description: Claude Code 플러그인·마켓플레이스 제작 시 참고서. 설계/개발 시 참조.
---
# 플러그인 관리 도메인 참고서 (seed)

## 범위
Claude Code 플러그인/마켓플레이스를 만들고 배포하는 방법.

## 항목 (seed — 계속 보강)
- **버전 핀 주의** — 활성 개발 중이면 plugin.json `version`을 **빼서** 커밋 SHA 기반 자동 업데이트. 고정하면 안 올리는 한 사용자 업데이트 안 나감.
- **marketplace.json** — `.claude-plugin/marketplace.json`(최상위 `name`/`description`/`owner`/`plugins[]`). 루트 플러그인은 `source: "./"`.
- **validate** — `claude plugin validate ./`(non-strict). 도그푸딩으로 루트 CLAUDE.md가 있으면 `--strict`는 의도적 실패.
- **컴포넌트 위치** — `agents/` `skills/` `commands/` `hooks/hooks.json`. 플러그인 CLAUDE.md는 컨텍스트 미로드.

## TODO
- 배포 채널/버전 정책, 팀 PR 워크플로 등.
```

- [ ] **Step 3 — `skills/domain-ui/SKILL.md`** (stub):
```markdown
---
name: domain-ui
description: UI(화면·컴포넌트) 개발 시 "마땅히 그래야 하는 것" 참고서. 설계/계획 시 명세 반영, 개발 시 고려. (작성 중 — 골격)
---
# UI 도메인 참고서 (stub)

## 범위
화면·컴포넌트·상호작용의 베스트프랙티스/요건.

## TODO (예시 — 통증 있는 것부터)
- 상태 관리, 반응형/레이아웃, 접근성(a11y), 로딩/에러/빈 상태, 입력 검증, 국제화.

> 골격이다. 실제 항목은 반복 통증 확인 후 추가(YAGNI·측정 먼저).
```

- [ ] **Step 4 — `skills/domain-app/SKILL.md`** (stub): 위와 동일 형식, name `domain-app`, 제목 "앱 도메인 참고서 (stub)", 범위 "애플리케이션(구성·설정·라이프사이클)", TODO 예시 "설정 관리, 에러 처리/로깅, 비밀/환경, 패키징/배포, 관측".

- [ ] **Step 5 — `skills/domain-agent/SKILL.md`** (stub): name `domain-agent`, 제목 "에이전트 도메인 참고서 (stub)", 범위 "에이전트 시스템(역할 분리·도구·루프)", TODO 예시 "정보 비대칭, 역할/차원 분리, 루프/종료 조건, HITL 게이트, 관측/평가".

- [ ] **Step 6 — `skills/domain-db/SKILL.md`** (stub): name `domain-db`, 제목 "DB 도메인 참고서 (stub)", 범위 "스키마·쿼리·마이그레이션", TODO 예시 "정규화/인덱스, N+1, 마이그레이션 안전성/롤백, 트랜잭션 경계, 백업".

- [ ] **Step 7:** 검증 — 각 SKILL.md frontmatter `name`이 디렉터리와 일치, `disable-model-invocation` 없음. Commit: `git add skills/domain-docs skills/domain-plugin skills/domain-ui skills/domain-app skills/domain-agent skills/domain-db && git commit -m "feat: add domain reference skills (docs/plugin seeded; ui/app/agent/db stubs)"`

---

## Task 4: scaffold + test (advisors-index → domains-index) — TDD

**Files:** Modify `scripts/scaffold.sh`, `scripts/test_scaffold.sh`

- [ ] **Step 1 (test 먼저):** `scripts/test_scaffold.sh`에서 advisors-index 검사를 domains-index로 바꾼다:
  - case1: `check "index copied to project" "[ -f '$T1/advisors-index.md' ]"` → `"[ -f '$T1/domains-index.md' ]"`
  - case1: `check "CLAUDE.md imports index" "grep -qxF '@advisors-index.md' ..."` → `"grep -qxF '@domains-index.md' ..."`
  - case1: `check "stdout carries index marker" "... grep -qF '검증 어드바이저'"` → 마커를 `'도메인) 참고서'`로 (domains-index 제목에 있음) 또는 `'도메인'`.
  - case2: `check "index import not duplicated" "... '@advisors-index.md' ..."` → `'@domains-index.md'`
  - case4: `cp "$HERE/advisors-index.md" "$T4/advisors-index.md"` → `cp "$HERE/domains-index.md" "$T4/domains-index.md"`; `check "same-dir index not truncated" "[ -s '$T4/advisors-index.md' ]"` → `"[ -s '$T4/domains-index.md' ]"`
  - case6 CRLF seed: `@advisors-index.md` 줄을 `@domains-index.md`로(있으면).

- [ ] **Step 2:** Run test → 일부 FAIL 확인(scaffold가 아직 advisors-index 기준).

- [ ] **Step 3:** `scripts/scaffold.sh` 수정:
  - `PLUGIN_FILES="coding-principles.md advisors-index.md"` → `PLUGIN_FILES="coding-principles.md domains-index.md"`
  - 관리영역 import 루프 `for f in coding-principles.md advisors-index.md solved_problems.md` → `for f in coding-principles.md domains-index.md solved_problems.md`
  - (stdout 루프는 `$PLUGIN_FILES` 사용하므로 자동 반영)

- [ ] **Step 4:** `bash -n scripts/scaffold.sh` clean; `bash scripts/test_scaffold.sh` → **FAIL=0**(전부 통과). 관리영역 import 순서: @coding-principles.md, @domains-index.md, @solved_problems.md.

- [ ] **Step 5:** Commit: `git add scripts/scaffold.sh scripts/test_scaffold.sh && git commit -m "feat(scaffold): inject domains-index (umbrella); advisors-index demoted to on-demand skill"`

---

## Task 5: coding-principles 절차 + README + 도그푸딩 + 검증

**Files:** Modify `coding-principles.md`, `README.md`; re-run scaffold.

- [ ] **Step 1:** `coding-principles.md` "절차" 섹션 수정:
  - 기존 "런타임 LLM 절차" 줄의 `advisors-index.md` 참조를 `domain-llm-runtime`로: "...`domain-llm-runtime`(+`advisor-*`)에서 리스크에 맞는 검증 레이어를 골라 제품 코드에 구현한다."
  - 기존 "계획 시점 절차" 줄을 일반화: "설계/계획 시 **`domains-index`에서 해당 개발 대상의 참고서를 확인**하고 '마땅히 그래야 하는 것'을 명세에 반영(안 되면 개발 단계에서 고려). 런타임 LLM 기능은 검증 레이어 포함."

- [ ] **Step 2:** `README.md`:
  - "## 런타임 LLM 검증 (어드바이저)" 섹션을 "## 도메인 참고서 + 런타임 검증"으로 확장(또는 새 섹션 추가): domains-index(항상 주입, 목차) + 도메인 스킬(온디맨드, 일부 stub) + LLM 런타임은 domain-llm-runtime/advisor-* 설명.
  - "## 구성" 트리에서 `advisors-index.md` 줄을 `domains-index.md`로, `skills/advisor-*` 아래에 `skills/domain-*` 추가.

- [ ] **Step 3:** 도그푸딩: `CLAUDE_PROJECT_DIR="$PWD" CLAUDE_PLUGIN_ROOT="$PWD" bash scripts/scaffold.sh >/dev/null 2>&1; echo exit=$?` → 이 레포 CLAUDE.md 관리영역이 `@domains-index.md` 포함(±`@advisors-index.md` 없음), region 1개, principles/domains-index 무truncate. `advisors-index.md`는 삭제됐으니 이 레포에 더 이상 없음(이전 도그푸딩 사본 있으면 `git rm`).

- [ ] **Step 4:** 검증: `bash scripts/test_scaffold.sh` → FAIL=0. `claude plugin validate ./`(non-strict) 통과.

- [ ] **Step 5:** Commit: `git add -A && git commit -m "docs: generalize discipline 절차 to domains-index; README domain framework; dogfood"`

---

## Self-Review
- 항상 주입 = domains-index 하나(advisors-index 강등) → Task 1,2,4. ✓
- 도메인 7(6 신규 + LLM) → Task 1,2,3. ✓ (상세 stub 허용)
- advisors-index 내용 보존(→ domain-llm-runtime) + root 삭제 → Task 2. ✓
- 절차 일반화(설계시점 도메인 반영) → Task 5. ✓
- 테스트 계약 = FAIL=0(매직 넘버 금지) → Task 4 표기. ✓
- Placeholder 없음(stub은 의도적, "TODO" 명시). 이름 일관(domain-*, domains-index). 
- 경계: 도메인 상세 내용은 후속(통증 기반).
