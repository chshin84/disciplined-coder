# disciplined-coder Phase 1 (토대 + 디시플린) Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** 린한 코딩 디시플린(12원칙+Docker)을 단일 출처로 두고, SessionStart hook이 모든 프로젝트의 CLAUDE.md에 자동 주입(+첫 세션 stdout 보강)하도록 만든다.

**Architecture:** 디시플린 정본 `coding-principles.md`(SSOT)를 플러그인에 1벌 둔다. `scaffold.sh`(SessionStart hook)가 매 프로젝트에서 그 파일을 복사하고, CLAUDE.md의 **관리 영역(managed region)**에 `@import`를 멱등 재생성하며, 첫 세션 도달을 위해 stdout으로도 출력한다. 구 설계의 disciplined-coder 에이전트와 coding-discipline 스킬은 원칙 중복(SSOT 위반)이므로 제거한다.

**Tech Stack:** Bash (Git Bash on Windows host), Claude Code 플러그인(매니페스트/훅/스킬), Markdown.

**참조 spec:** `docs/superpowers/specs/2026-06-14-disciplined-coder-design.md` (§5.1 원칙, §5.3 전달, §12 Phase 1)

---

## File Structure (Phase 1에서 만지는 파일)

- **Create** `coding-principles.md` — 디시플린 정본(SSOT). 12원칙 + Docker.
- **Create** `scripts/test_scaffold.sh` — scaffold 동작 검증용 bash 테스트.
- **Modify** `scripts/scaffold.sh` — 원칙 복사 + 관리 영역 @import 재생성 + stdout 출력 (기존 이슈 로그 생성은 유지).
- **Delete** `agents/disciplined-coder.md`, `skills/coding-discipline/` — 원칙이 coding-principles.md로 이동(SSOT). 구 설계 잔재.
- **Modify** `README.md` — 구성/사용을 새 설계로 갱신, 삭제된 agent/skill 언급 제거.
- **Keep (변경 없음)** `hooks/hooks.json`(이미 `bash` 호출 + `matcher: startup`), `commands/bootstrap-issues.md`, `plugin.json`.

> 참고: hook이 `scaffold.sh`를 `bash`로 호출하고 그 **stdout이 SessionStart additionalContext로 주입**된다 → 별도 hooks.json 변경 없이 stdout 주입이 성립한다.

---

## Task 1: 디시플린 정본 `coding-principles.md` 작성

**Files:**
- Create: `coding-principles.md`

- [ ] **Step 1: 파일 작성**

`coding-principles.md`에 아래 내용을 그대로 작성한다(spec §5.1):

```markdown
# 코딩 디시플린 (팀 원칙)

모든 코드 작업에 항상 적용한다. 이 파일이 **단일 출처(SSOT)**이며, disciplined-coder 플러그인이
각 프로젝트의 CLAUDE.md에 `@import`로 자동 주입한다. 프로젝트의 사본은 직접 수정하지 말 것
(매 세션 이 정본에서 다시 복사된다).

## A. 협업·커뮤니케이션
1. **명료한 소통 + 판단 유예 금지** — 결론만 던지지 말고 근거·기각한 대안까지 설명한다. 단계를 건너뛰지 않는다. 판단이 필요한 곳에서 모호한 추측 대신 명확히 질문한다.

## B. 설계·유지보수
2. **단순·가독 (YAGNI)** — 지금 필요 없는 일반화·추상화 금지, 가장 단순한 동작부터. 코드는 쓰기보다 읽히는 횟수가 많다 — 주변 관례를 따른다.
3. **명시성 > 암묵성** — 놀라움 최소화. 숨은 동작·매직 금지. 의도는 이름·계약·타입으로 드러낸다.
4. **작은 단위·단일 책임** — 한 단위는 한 가지 일. 내부를 몰라도 쓸 수 있게 인터페이스로 의존. 파일 비대화는 분리 신호.

## C. 정확성·안전
5. **SSOT + 복제 말고 도출** — 같은 정보는 한 곳에만. 사람이 두 곳을 동기화하게 만들지 않는다.
6. **Fail-loud + 강건성 > 작성자 정확성** — 조용한 실패 금지(드리프트·계약 위반은 즉시 빨강으로). 구조(불변식·생성된 설정·명확한 계약)가 실수를 막거나 드러내게 한다 — "정확히 기억"에 의존 금지.
7. **TDD + 검증 후 주장** — 실패 테스트 먼저. 실행 증거 없이 "됐다" 금지.
8. **비파괴 우선** — 원본 보존. 필터/dedup/스팸 제거는 삭제가 아니라 분류 표시(mark). 저장 후 처리.
9. **측정 먼저** — 가정 금지. 환경 차이를 먼저 확인.
10. **멱등성** — 스크립트·마이그레이션·셋업은 반복 실행해도 안전하게.
11. **비밀 분리** — 진짜 비밀은 백엔드 전용. 비밀 아닌 식별자만 클라이언트 노출.
12. **가역성 우선** — 되돌릴 수 있는 결정을 선호. 비가역 결정은 근거를 남긴다.

## 환경 관례 (보편 원칙 아님)
- **Docker 전용 개발/테스트** — 로컬 실행 금지. 프로덕션과 동일 환경에서.
```

- [ ] **Step 2: 커밋**

```bash
git add coding-principles.md
git commit -m "feat: add coding-principles.md as discipline SSOT (12 principles + Docker)"
```

---

## Task 2: scaffold 검증 테스트 작성 (실패 확인)

**Files:**
- Create: `scripts/test_scaffold.sh`

- [ ] **Step 1: 실패 테스트 작성**

`scripts/test_scaffold.sh`에 작성한다. 가짜 플러그인 루트(principles 포함)와 임시 프로젝트로 scaffold를 돌려 동작을 검증한다.

```bash
#!/usr/bin/env bash
# scaffold.sh 동작 검증. 실패 시 즉시 exit 1.
set -euo pipefail

HERE="$(cd "$(dirname "$0")/.." && pwd)"   # 플러그인 루트 (scripts/의 부모)
SCAFFOLD="$HERE/scripts/scaffold.sh"
PRINCIPLES_SRC="$HERE/coding-principles.md"

pass=0; fail=0
check() { if eval "$2"; then echo "  PASS: $1"; pass=$((pass+1)); else echo "  FAIL: $1"; fail=$((fail+1)); fi; }

# --- 케이스 1: 신규 프로젝트 ---
T1="$(mktemp -d)"
OUT="$(CLAUDE_PLUGIN_ROOT="$HERE" CLAUDE_PROJECT_DIR="$T1" bash "$SCAFFOLD")"
echo "[case1] fresh project"
check "principles copied to project"      "[ -f '$T1/coding-principles.md' ]"
check "CLAUDE.md imports principles"       "grep -qxF '@coding-principles.md' '$T1/CLAUDE.md'"
check "CLAUDE.md imports solved"           "grep -qxF '@solved_problems.md' '$T1/CLAUDE.md'"
check "CLAUDE.md imports unsolved"         "grep -qxF '@unsolved_problems.md' '$T1/CLAUDE.md'"
check "managed region present once"        "[ \$(grep -cF '# BEGIN disciplined-coder' '$T1/CLAUDE.md') -eq 1 ]"
check "stdout carries a principle marker"  "printf '%s' \"\$OUT\" | grep -qF '코딩 디시플린'"

# --- 케이스 2: 멱등성 (3회 실행해도 영역 1개) ---
CLAUDE_PLUGIN_ROOT="$HERE" CLAUDE_PROJECT_DIR="$T1" bash "$SCAFFOLD" >/dev/null
CLAUDE_PLUGIN_ROOT="$HERE" CLAUDE_PROJECT_DIR="$T1" bash "$SCAFFOLD" >/dev/null
echo "[case2] idempotency"
check "still one managed region"           "[ \$(grep -cF '# BEGIN disciplined-coder' '$T1/CLAUDE.md') -eq 1 ]"
check "principles import not duplicated"   "[ \$(grep -cxF '@coding-principles.md' '$T1/CLAUDE.md') -eq 1 ]"

# --- 케이스 3: 기존 CLAUDE.md 본문 보존 + 산문 충돌 무해 ---
T3="$(mktemp -d)"
printf 'preexisting line\nSee @coding-principles.md in prose.\n' > "$T3/CLAUDE.md"
CLAUDE_PLUGIN_ROOT="$HERE" CLAUDE_PROJECT_DIR="$T3" bash "$SCAFFOLD" >/dev/null
echo "[case3] preserve existing content"
check "existing prose preserved"           "grep -qF 'preexisting line' '$T3/CLAUDE.md'"
check "managed region added once"          "[ \$(grep -cF '# BEGIN disciplined-coder' '$T3/CLAUDE.md') -eq 1 ]"

echo "----"
echo "PASS=$pass FAIL=$fail"
[ "$fail" -eq 0 ]
```

- [ ] **Step 2: 실패 확인**

Run: `bash scripts/test_scaffold.sh`
Expected: FAIL — 현재 `scaffold.sh`는 principles를 복사/주입하지 않고 관리 영역도 없으므로 "principles copied", "imports principles", "managed region present", "stdout carries marker" 등이 실패한다.

- [ ] **Step 3: 커밋**

```bash
git add scripts/test_scaffold.sh
git commit -m "test: add scaffold behavior test (principles delivery + managed region)"
```

---

## Task 3: `scaffold.sh`를 새 설계로 갱신 (테스트 통과)

**Files:**
- Modify: `scripts/scaffold.sh`

- [ ] **Step 1: scaffold.sh 전체 교체**

`scripts/scaffold.sh`를 아래 내용으로 교체한다. (변경점: 플러그인 루트 해석, principles 복사, CLAUDE.md **관리 영역** 재생성, principles를 stdout으로 출력. 이슈 로그 생성은 유지.)

```bash
#!/usr/bin/env bash
# Idempotent. SessionStart마다 실행. 없는 것만 만들고, 관리 영역은 항상 재생성.
# 디시플린 주입 + 프로젝트 이슈 로그 스캐폴드 + CLAUDE.md @import 배선.
set -euo pipefail

ROOT="${CLAUDE_PROJECT_DIR:-$PWD}"
# 플러그인 루트: hook이 주는 CLAUDE_PLUGIN_ROOT, 없으면 이 스크립트의 부모(scripts/의 위).
PLUGIN_ROOT="${CLAUDE_PLUGIN_ROOT:-$(cd "$(dirname "$0")/.." && pwd)}"

SOLVED="$ROOT/solved_problems.md"
UNSOLVED="$ROOT/unsolved_problems.md"
CLAUDE_MD="$ROOT/CLAUDE.md"
PRINCIPLES_DST="$ROOT/coding-principles.md"
PRINCIPLES_SRC="$PLUGIN_ROOT/coding-principles.md"

created=()

# 1) 디시플린 정본을 프로젝트로 복사(매 세션 갱신 = SSOT에서 도출)
if [ -f "$PRINCIPLES_SRC" ]; then
  cp "$PRINCIPLES_SRC" "$PRINCIPLES_DST"
fi

# 2) 이슈 로그 생성(없을 때만)
if [ ! -f "$SOLVED" ]; then
  cat > "$SOLVED" <<'EOF'
# 해결된 문제 로그 (solved_problems)

작업 중 발견·해결된 문제 기록. 각 항목: 문제 → 원인 → 해결.
일반화 가능한 항목은 디시플린(coding-principles.md)으로 승격하고 여기서는 제거(SSOT).
(미해결·대기 항목은 `unsolved_problems.md`.)
EOF
  created+=("solved_problems.md")
fi

if [ ! -f "$UNSOLVED" ]; then
  cat > "$UNSOLVED" <<'EOF'
# 미해결 / 대기 문제 (unsolved_problems)

> ⚠️ 모든 에이전트 지침(이 파일은 CLAUDE.md @import로 모든 서브에이전트 컨텍스트에 로드됨):
> 아래 **🔴 항목은 사용자 결정 대기** 상태다. 어떤 에이전트도 🔴 항목을 **자율적으로 구현·수정하지 마라.**
> 참고만 하고, 필요하면 메인 세션에 결정 요청을 올려라.

발견됐으나 안 끝난 것 + 사용자 결정이 필요한 것. (해결되면 `solved_problems.md`로 이동.)
범례: 🔴 사용자 결정 필요(에이전트 자율 구현 금지) · 🟡 방향 정해짐·구현 대기 · 🔵 향후/선택.

## 🔴 결정 필요

## 🟡 구현 대기

## 🔵 향후 / 선택
EOF
  created+=("unsolved_problems.md")
fi

# 3) CLAUDE.md 관리 영역 재생성(멱등). 기존 영역을 제거 후 최신으로 다시 추가.
touch "$CLAUDE_MD"
BEGIN_MARK="# BEGIN disciplined-coder (managed — do not edit)"
END_MARK="# END disciplined-coder (managed — do not edit)"
if grep -qF "$BEGIN_MARK" "$CLAUDE_MD"; then
  awk -v b="$BEGIN_MARK" -v e="$END_MARK" '
    $0==b {skip=1}
    skip==0 {print}
    $0==e {skip=0}
  ' "$CLAUDE_MD" > "$CLAUDE_MD.tmp" && mv "$CLAUDE_MD.tmp" "$CLAUDE_MD"
fi
{
  printf '\n%s\n' "$BEGIN_MARK"
  printf '@coding-principles.md\n@solved_problems.md\n@unsolved_problems.md\n'
  printf '%s\n' "$END_MARK"
} >> "$CLAUDE_MD"

# 4) 첫 세션 도달 보강: 디시플린을 stdout으로 출력(SessionStart additionalContext).
if [ -f "$PRINCIPLES_DST" ]; then
  cat "$PRINCIPLES_DST"
fi

# 5) 생성 보고
if [ ${#created[@]} -gt 0 ]; then
  echo "[disciplined-coder] scaffolded: ${created[*]}"
fi
exit 0
```

- [ ] **Step 2: 문법 검사**

Run: `bash -n scripts/scaffold.sh`
Expected: 출력 없음, 종료코드 0.

- [ ] **Step 3: 테스트 통과 확인**

Run: `bash scripts/test_scaffold.sh`
Expected: 모든 케이스 PASS, 마지막 줄 `PASS=10 FAIL=0`, 종료코드 0.

- [ ] **Step 4: 커밋**

```bash
git add scripts/scaffold.sh
git commit -m "feat: scaffold delivers discipline (copy + managed CLAUDE.md region + stdout)"
```

---

## Task 4: 구 설계 잔재 제거 (SSOT)

**Files:**
- Delete: `agents/disciplined-coder.md`
- Delete: `skills/coding-discipline/SKILL.md` (및 빈 디렉터리)

- [ ] **Step 1: 파일 삭제**

```bash
git rm agents/disciplined-coder.md
git rm skills/coding-discipline/SKILL.md
```

새 설계는 agent 타입을 쓰지 않고(디시플린은 CLAUDE.md 주입으로 전역 도달), 원칙은 `coding-principles.md`가 단일 출처다. 스킬에 남은 원칙 사본은 SSOT 위반이므로 제거한다.

- [ ] **Step 2: 잔존 참조 확인**

Run: `grep -rn "coding-discipline\|disciplined-coder.md\|agents/disciplined" --include=*.md --include=*.json . || echo "no dangling refs"`
Expected: README 안의 언급만 남아야 한다(다음 Task에서 정리). 그 외 코드/매니페스트 참조가 없어야 한다.

- [ ] **Step 3: 테스트 재확인 (회귀 없음)**

Run: `bash scripts/test_scaffold.sh`
Expected: `PASS=10 FAIL=0` (삭제가 scaffold 동작에 영향 없음).

- [ ] **Step 4: 커밋**

```bash
git add -A
git commit -m "refactor: remove obsolete disciplined-coder agent and coding-discipline skill (principles now in coding-principles.md, SSOT)"
```

---

## Task 5: README 갱신 + 플러그인 검증

**Files:**
- Modify: `README.md`

- [ ] **Step 1: README 구성/동작 섹션 갱신**

`README.md`의 "무엇을 자동화하나", "구성", "사용" 관련 서술을 새 설계로 교체한다. 핵심 교체 내용:
- "일반 지식 → agent + skill에 baked" 문장을 **"디시플린(coding-principles.md, SSOT) → SessionStart hook이 프로젝트 CLAUDE.md에 @import 주입(+ 첫 세션 stdout 보강) → 메인 + 모든 서브에이전트 도달"**로 교체.
- 구성 트리에서 `agents/disciplined-coder.md`, `skills/coding-discipline/SKILL.md` 줄을 제거하고 `coding-principles.md` 추가.
- "사용(SDD/ultracode subagent_type)" 단락 제거 — 더 이상 agent 타입을 쓰지 않음.
- Prerequisites(Git Bash) 단락은 그대로 유지.

구성 트리는 아래로 교체:

```
disciplined-coder/
├── .claude-plugin/plugin.json      # 매니페스트
├── coding-principles.md            # 디시플린 정본 (SSOT) — hook이 프로젝트로 복사
├── hooks/hooks.json                # SessionStart → scaffold.sh
├── scripts/scaffold.sh             # 멱등: principles 복사 + CLAUDE.md 관리영역 @import + stdout
├── scripts/test_scaffold.sh        # scaffold 검증 테스트
├── commands/bootstrap-issues.md    # 수동 재실행 커맨드
└── README.md
```

- [ ] **Step 2: 플러그인 검증**

Run: `claude plugin validate ./ --strict`
Expected: PASS (오류 없음). 이 환경에서 `claude` CLI가 없으면 이 단계는 설치 환경에서 수행한다고 표시하고 넘어간다.

- [ ] **Step 3: 커밋**

```bash
git add README.md
git commit -m "docs: update README for discipline-delivery design (remove agent/skill, add coding-principles.md)"
```

---

## Self-Review

**1. Spec coverage (Phase 1 부분):**
- §5.1 원칙 12개+Docker → Task 1 (`coding-principles.md`). ✓
- §5.3 전달(정본 1벌 + hook 복사 + @import + stdout) → Task 3. ✓
- §3-2 @import 멱등/세션 시작 로드 → Task 3 관리영역 + Task 2 멱등 테스트. ✓
- §12 Phase 1 "principles 정본 + scaffold + 설치/검증" → Task 1·3·5. ✓
- SSOT(원칙이 한 곳에만) → Task 4 (구 skill 제거). ✓
- (Phase 2·3 항목은 의도적으로 제외 — 어드바이저/이슈 생애주기 지시는 후속 plan.)

**2. Placeholder scan:** TBD/TODO 없음. 모든 코드/명령/내용 명시됨. ✓

**3. Type/이름 일관성:** 관리 영역 마커 `# BEGIN/END disciplined-coder (managed — do not edit)`가 scaffold.sh와 test_scaffold.sh에서 동일 문자열. import 라인 `@coding-principles.md`/`@solved_problems.md`/`@unsolved_problems.md` 일관. 파일명 `coding-principles.md` 일관. ✓

> 주: 기존 `scaffold.sh`의 구 sentinel 방식(`## 프로젝트 이슈 로그 (자동 주입)`)은 Task 3에서 관리 영역 방식으로 **대체**된다. 구 sentinel로 이미 배선된 프로젝트가 있다면, 새 scaffold는 관리 영역을 별도로 추가하므로 구 sentinel 줄이 중복으로 남을 수 있다 — 신규/현재 사용엔 무해하나, 후속 정리 대상으로 §10 미해결에 준한다.
