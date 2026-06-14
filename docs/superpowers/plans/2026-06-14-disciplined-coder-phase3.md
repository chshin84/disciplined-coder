# disciplined-coder Phase 3 (이슈 생애주기 지시) Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: superpowers:subagent-driven-development. Steps use checkbox (`- [ ]`).

**Goal:** solved/unsolved 이슈 로그의 **생애주기 행동(B+D)**을 디시플린에 명시해, 모든 세션/에이전트가 일관되게 문제를 등록·이동하게 한다. 파일 스캐폴드는 Phase 1에서 이미 완료됐으므로 Phase 3는 **행동 지시** 중심이다.

**Architecture:** 생애주기 규약을 항상 주입되는 `coding-principles.md`의 "절차" 섹션에 추가한다(별도 파일·plumbing 불필요 — 이미 @import됨). solved/unsolved 템플릿에 한 줄 포인터를 더해 파일이 스스로 워크플로를 설명하게 한다. README에 워크플로를 문서화한다.

**Tech Stack:** Markdown(디시플린·README), Bash(scaffold 템플릿 문구). 기존 토대 재사용.

**참조 spec:** §7(이슈 로그 생애주기 B+D, 단일 작성자, dispatch 주입, 🔴 전파), §5.2(절차 섹션), §12 Phase 3.

**설계 결정:** §7.2의 "(선택) 테스트 통과 PostToolUse hook 보조"는 **이번 범위에서 제외(deferred-optional)**. 이유: 어떤 명령이 테스트인지·통과인지 결정론적 판별이 취약하고, hook이 할 수 있는 건 "이동을 고려하라"는 리마인드뿐이라(실제 이동은 모델만 가능) 항상 도는 hook의 비용·오탐 대비 이득이 작다(YAGNI·측정 먼저). 핵심 생애주기는 모델 주도 디시플린 지시로 구현한다. 필요 시 후속으로 추가.

---

## File Structure (Phase 3)
- **Modify** `coding-principles.md` — "절차" 섹션에 이슈 생애주기 2줄 추가.
- **Modify** `scripts/scaffold.sh` — solved/unsolved 템플릿에 생애주기 한 줄 포인터.
- **Modify** `README.md` — 이슈 로그 워크플로 섹션.
- **Re-run** scaffold on this repo (dogfood; coding-principles.md는 같은 파일이라 자동 반영, CLAUDE.md 영역 무변).

---

## Task 1: 디시플린에 이슈 생애주기 절차 추가

**Files:** Modify `coding-principles.md`

- [ ] **Step 1:** `coding-principles.md`의 "## 절차 (원칙과 별개 — 어드바이저·계획 연결)" 섹션의 **마지막 bullet 뒤**에 아래 두 bullet을 추가(같은 섹션 내, 기존 2줄 아래):

```markdown
- **이슈 로그 생애주기** — 문제를 인지하면 `unsolved_problems.md`에 등록하고, 해결되면 `solved_problems.md`로 옮긴다(항목: 문제 → 원인 → 해결). 발동 시점: **검증/리뷰 작업이 끝날 때 등록**, **테스트가 통과로 바뀔 때 solved로 이동**.
- **단일 작성자 + 보고** — 이 로그 파일들은 **메인 세션(오케스트레이터)만 쓴다**(동시 쓰기 손상 방지). 서브에이전트는 직접 쓰지 말고 발견한 문제를 **리턴값으로 보고**하면 메인이 취합·dedup해 기록한다. 세션 중 최신 항목이 필요한 서브에이전트에는 메인이 dispatch 프롬프트에 관련 항목을 실어 전달한다. (`unsolved_problems.md`의 🔴는 누구도 자율 구현하지 않는다.)
```

- [ ] **Step 2:** 검증 — `grep -c '^- ' coding-principles.md`로 절차 bullet이 늘었는지, "이슈 로그 생애훼기"... (오타 주의) "이슈 로그 생애주기"·"단일 작성자" 문구 존재 확인. 기존 12개 원칙·섹션 무변 확인.

- [ ] **Step 3:** 커밋
```bash
git add coding-principles.md
git commit -m "feat: add issue-log lifecycle procedure to discipline (B+D, single-writer, report+dispatch)"
```

---

## Task 2: solved/unsolved 템플릿에 생애주기 포인터

**Files:** Modify `scripts/scaffold.sh`

- [ ] **Step 1:** `scripts/scaffold.sh`의 SOLVED 히어독에서, 마지막 줄
```
(미해결·대기 항목은 `unsolved_problems.md`.)
```
바로 위 또는 아래에 한 줄 추가(히어독 내부):
```
등록·이동은 메인 세션이 수행한다(생애주기 규약: coding-principles.md "절차").
```

- [ ] **Step 2:** UNSOLVED 히어독에서, 기존 줄
```
발견됐으나 안 끝난 것 + 사용자 결정이 필요한 것. (해결되면 `solved_problems.md`로 이동.)
```
을 아래로 교체:
```
발견됐으나 안 끝난 것 + 사용자 결정이 필요한 것. (해결되면 `solved_problems.md`로 이동.)
등록은 검증/리뷰 종료 시, solved 이동은 테스트 통과 시 — 메인 세션이 수행(coding-principles.md "절차").
```

- [ ] **Step 3:** 검증
Run: `bash -n scripts/scaffold.sh` → clean.
Run: `bash scripts/test_scaffold.sh` → 여전히 `PASS=22 FAIL=0` (테스트는 import/구조만 검사, 템플릿 문구 무관).
(빠른 확인: 임시 디렉터리에 scaffold 실행 후 새 unsolved_problems.md에 "메인 세션이 수행" 문구가 있는지.)

- [ ] **Step 4:** 커밋
```bash
git add scripts/scaffold.sh
git commit -m "docs: self-document issue-log lifecycle in solved/unsolved templates"
```

---

## Task 3: README + 도그푸딩 + 검증

**Files:** Modify `README.md`; re-run scaffold on this repo.

- [ ] **Step 1:** `README.md`에 새 섹션 추가(예: "## 런타임 LLM 검증" 섹션 뒤 또는 "한계" 앞). 내용:
```markdown
## 이슈 로그 생애주기
프로젝트별 `solved_problems.md`/`unsolved_problems.md`는 다음 규약으로 운영된다(디시플린 "절차"에 명시, 모든 세션에 주입):
- **등록**: 검증/리뷰 작업이 끝날 때, 발견된 문제를 `unsolved_problems.md`에 기록.
- **solved 이동**: 테스트가 통과로 바뀌면 해당 문제를 `solved_problems.md`로(문제→원인→해결).
- **단일 작성자**: 메인 세션(오케스트레이터)만 로그를 쓴다. 서브에이전트는 리턴값으로 보고만 하고, 메인이 취합·dedup해 기록한다. 세션 중 최신이 필요하면 메인이 dispatch에 관련 항목을 주입한다.
- **🔴 금지**: `unsolved_problems.md`의 🔴(사용자 결정 필요)는 어떤 에이전트도 자율 구현하지 않는다.

> 테스트 통과를 결정론적으로 감지하는 PostToolUse hook 보조는 의도적으로 넣지 않았다(판별 취약·이득 적음). 필요 시 후속 추가.
```

- [ ] **Step 2:** 도그푸딩 재실행(coding-principles.md 갱신분이 이 레포에 반영됨 — 같은 파일이라 내용은 이미 최신; CLAUDE.md 영역·테스트 무변 확인):
```bash
CLAUDE_PROJECT_DIR="$PWD" CLAUDE_PLUGIN_ROOT="$PWD" bash scripts/scaffold.sh >/dev/null 2>&1; echo "exit=$?"
grep -cF '# BEGIN disciplined-coder' CLAUDE.md   # 1
grep -q '이슈 로그 생애주기' coding-principles.md && echo "lifecycle in principles OK"
```

- [ ] **Step 3:** 검증
Run: `bash scripts/test_scaffold.sh` → `PASS=22 FAIL=0`.
Run: `claude plugin validate ./` (있으면; non-strict 통과 기대).

- [ ] **Step 4:** 커밋
```bash
git add README.md
git commit -m "docs: document issue-log lifecycle workflow"
```

---

## Self-Review
- §7 생애주기(B+D) → Task 1 디시플린 절차. ✓
- §7 단일 작성자 + 서브 보고 + dispatch 주입 → Task 1. ✓
- §7 🔴 전파 → 기존 unsolved 템플릿 + Task 1 재언급. ✓
- §7.2 PostToolUse(선택) → 의도적 제외, 문서화. ✓
- 자기문서화(템플릿) → Task 2. ✓
- README → Task 3. ✓
- Placeholder 없음. 파일 경로·문구 명시. 테스트 기대 PASS=22 일관.
- 경계: 새 파일·새 import 없음(생애주기는 기존 always-injected 파일에 얹음).
