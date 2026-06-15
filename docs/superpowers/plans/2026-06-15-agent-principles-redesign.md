# agent-principles 리디자인 Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** disciplined-coder의 원칙 파일을 enrich·재구성하고, 리뷰 로직을 reviewer 풀로 분리하며, 빈 스텁·드리프트를 정리한다.

**Architecture:** 설계는 `docs/superpowers/specs/2026-06-15-agent-principles-redesign-design.md`(3렌즈 리뷰 통과). 세 단계로 나눠 각 단계 끝에 `bash scripts/test_scaffold.sh`로 FAIL=0을 확인하고 커밋한다.

**Tech Stack:** Markdown(스킬·원칙·커맨드), Bash(scaffold·hooks·테스트), JSON(marketplace).

**검증 계약:** 매직 넘버 없이 `test_scaffold.sh`/`test_hooks.sh`가 FAIL=0. `claude plugin validate ./`(non-strict).

---

## Phase A — 원칙 파일 enrich + 이름 변경 + 절차 재구성

**Files:**
- Rename + Modify: `coding-principles.md` → `agent-principles.md`
- Modify: `scripts/scaffold.sh`, `scripts/test_scaffold.sh`, `README.md`, `.claude-plugin/marketplace.json`

- [ ] **A1.** `git mv coding-principles.md agent-principles.md`.
- [ ] **A2.** `agent-principles.md` 내용 변경:
  - 제목 "코딩 디시플린 (팀 원칙)" → "디시플린 (팀 원칙)".
  - 범위 "모든 코드 작업에" → "모든 작업에".
  - 인트로의 "순서·우선순위는 없다 … 글로서리 …" 메타 문구 삭제. 헤더 "## 원칙 (ID로 참조 · 무순서 · 알파벳순)" → "## 원칙 (ID로 참조 · 알파벳순)".
  - 12개 원칙을 enrich(ID 풀어쓰기, 완결 문장, 출처 표기 없음, 구루 알맹이 흡수). `MEASURE-FIRST`와 `NON-DESTRUCTIVE` 사이에 `NO-PRIORITY` 추가. `SIMPLE`에 "에이전트 과설계 금지", `FOCUSED`에 "직교성" 흡수. `SURGICAL` 추가(알파벳 위치: `SSOT` 앞, `SIMPLE` 뒤).
  - "공통 함정"의 gitignore·mock/None 항목 enrich.
  - "절차" 섹션을 가(검증 레이어 — 트리거 표 + 공통 방법 문장)·나(설계 입력)·다(이슈 로그 통합)로 재구성. `domain-llm-runtime`/`domain-spec-review` 참조, recall 트리거·처방형 포맷·서브에이전트 역할 포함.
- [ ] **A3.** `scripts/scaffold.sh`: `coding-principles.md` → `agent-principles.md`(복사 루프 line 15·73, @import line 68, 템플릿 문구 line 30). 구 파일 정리 한 줄 추가: KDIR의 `coding-principles.md`가 있으면 `rm -f`(orphan 제거, 멱등).
- [ ] **A4.** `scripts/test_scaffold.sh`: `coding-principles.md` → `agent-principles.md` 전부. 마커 `코딩 디시플린` → `디시플린`.
- [ ] **A5.** `README.md`·`.claude-plugin/marketplace.json`: 파일명·설명 문구 동기화.
- [ ] **A6.** Run: `bash scripts/test_scaffold.sh` → Expected: `PASS=… FAIL=0`.
- [ ] **A7.** Commit: `feat(principles): rename to agent-principles, enrich 12 principles, restructure 절차`.

## Phase B — 리뷰어 재배치 + 훅 배선

**Files:**
- Create: `skills/reviewer-grounding/SKILL.md`, `skills/reviewer-fit/SKILL.md`, `skills/reviewer-consistency/SKILL.md`, `skills/reviewer-adversarial/SKILL.md`, `skills/meta-aggregate/SKILL.md`
- Rename: `skills/advisor-spec-review/` → `skills/domain-spec-review/`
- Modify: `skills/domain-llm-runtime/SKILL.md`, `skills/domain-docs/SKILL.md`, `domains-index.md`, `hooks/spec_review_posttooluse.sh`, `hooks/spec_review_stop.sh`, `agent-principles.md`(절차의 스킬 이름)
- Delete: `skills/advisor-correctness/`, `skills/advisor-fit/`, `skills/advisor-meta/`, `skills/advisor-nonfunctional/`

- [ ] **B1.** reviewer 4종 생성. 각 SKILL.md = 렌즈 하나(무엇을 보고 어떤 issues JSON을 돌려주는가). `reviewer-grounding`(correctness+factual 통합, 출처는 호출자 제공), `reviewer-fit`, `reviewer-consistency`, `reviewer-adversarial`(YAGNI 가드 포함). 출력 스키마는 공통.
- [ ] **B2.** `meta-aggregate/SKILL.md` 생성(기존 advisor-meta 내용 이전). 리뷰어 아님 명시, 코드 설계도, 런타임=함수/spec리뷰=메인 세션 수행.
- [ ] **B3.** `git mv skills/advisor-spec-review skills/domain-spec-review`. SKILL.md를 호출자로 정리: grounding·consistency·adversarial을 각각 별도 read-only 서브에이전트로 디스패치 → meta로 집계. frontmatter `name: domain-spec-review`.
- [ ] **B4.** `domain-llm-runtime/SKILL.md`: 호출자로 정리. 리스크 선택으로 reviewer 호출, nonfunctional 체크리스트 흡수(항상 적용), meta는 결정론 함수.
- [ ] **B5.** advisor-correctness/fit/meta/nonfunctional 디렉터리 삭제(`git rm -r`).
- [ ] **B6.** 훅 `hooks/spec_review_posttooluse.sh`·`spec_review_stop.sh`: 메시지의 `advisor-spec-review` → `domain-spec-review`.
- [ ] **B7.** `agent-principles.md` 절차의 `advisor-spec-review` → `domain-spec-review` 참조 갱신.
- [ ] **B8.** `domain-docs/SKILL.md`: "이 시스템 md 작성 규칙"으로 재정의.
- [ ] **B9.** `domains-index.md`: llm-runtime 행의 `(+ advisor-*)` 갱신. 스킬 목록 일관화.
- [ ] **B10.** Run: `bash scripts/test_scaffold.sh` && `bash scripts/test_hooks.sh` → FAIL=0.
- [ ] **B11.** Commit: `refactor(skills): split reviewers from callers, rename advisor-spec-review→domain-spec-review, fold nonfunctional`.

## Phase C — 빈 스텁 삭제 + bootstrap 정정 + 보여주기 커맨드

**Files:**
- Delete: `skills/domain-ui/`, `skills/domain-app/`, `skills/domain-agent/`, `skills/domain-db/`
- Modify: `domains-index.md`, `commands/bootstrap-issues.md`
- Create: `commands/show-unsolved.md`, `commands/show-solved.md`, `commands/show-principles.md`

- [ ] **C1.** `git rm -r skills/domain-ui skills/domain-app skills/domain-agent skills/domain-db`.
- [ ] **C2.** `domains-index.md`: ui/app/agent/db 행 삭제. "통증 확인된 도메인만 등재, 새 도메인은 필요할 때 신설" 한 줄.
- [ ] **C3.** `commands/bootstrap-issues.md`: "현재 프로젝트에" → "PC 전역(`~/.claude/disciplined-coder/`)에".
- [ ] **C4.** show 커맨드 3개 생성. 각 PC 전역 파일을 Read해 원문 표시, 인자 없음, 없으면 안내 한 줄.
- [ ] **C5.** Run: `bash scripts/test_scaffold.sh` && `bash scripts/test_hooks.sh` → FAIL=0. `claude plugin validate ./`(가능 시).
- [ ] **C6.** Commit: `chore: remove empty domain stubs, fix bootstrap desc, add show-* commands`.

## Phase D — 푸시 + PR

- [ ] **D1.** `git push -u origin agent-principles-redesign`.
- [ ] **D2.** `gh pr create`로 PR 생성(요약 + spec/plan 링크).

## Self-Review

- **Spec coverage:** spec §3(원칙)→A2, §4(절차)→A2, §5(리뷰 아키텍처)→B1·B2·B3·B4, §6(스킬 재배치)→B1·B5·B8, §6.2(스텁)→C1·C2, §7.1(bootstrap)→C3, §7.2(커맨드)→C4, §7.3(배선)→A3·A4·A5·B6·B7. 전부 커버.
- **Placeholder scan:** 없음(각 단계가 구체 파일·동작 명시).
- **Type consistency:** 스킬 이름 일관(reviewer-grounding/fit/consistency/adversarial, meta-aggregate, domain-spec-review, domain-llm-runtime). 파일명 agent-principles.md 일관.

<!-- spec-review: passed lenses=3 date=2026-06-15 -->
