# spec/plan 강제 3렌즈 독립 리뷰 Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans. Steps use checkbox (`- [ ]`) syntax.

**Goal:** superpowers가 spec/plan을 쓴 직후, 훅으로 3렌즈 독립 리뷰를 강제 실행→반영→(부분)재작업까지 잇는다.

**Architecture:** PostToolUse(Write|Edit)가 spec/plan 경로 작성을 즉시 감지해 리뷰 수행을 컨텍스트로 주입(비블로킹), Stop 훅이 미리뷰 spec/plan이 남으면 `decision:block`으로 턴 종료를 막는 하드 게이트. 둘 다 문서의 `spec-review:` 마커 유무로 해제. 리뷰는 read-only 서브에이전트 3렌즈+코드 메타집계.

**Tech Stack:** bash, jq, git, Claude Code hooks(PostToolUse/Stop), 마크다운 스킬.

**Spec:** `docs/superpowers/specs/2026-06-14-forced-3lens-review-design.md` (REVIEWED v2).

> **구현 중 3렌즈 리뷰 반영(중요 — 아래 코드블록은 의도, 최종 코드 SSOT는 `hooks/` 파일)**:
> - 🔴 마커 자기매칭 버그 → 마커를 **문서 마지막 비공백 줄의 terminal HTML 주석**(`<!-- spec-review: passed|escalated … -->`)으로, 탐지는 마지막 줄만(본문 예시와 충돌 불가). pending은 마커 아님.
> - 🔴 대상 환경 **jq 부재** 확인 → 훅을 **순수 bash(sed/grep)**로(jq 비의존), Windows 백슬래시 경로 정규화.
> - `cd "$cwd" \|\| exit 0` 단축평가 → 명시적 `if`. git 미추적 디렉터리 탐지 위해 `--untracked-files=all`.
> - 리뷰는 **PREP(TDD식 사전 준비)+3렌즈+메타집계**(skill 참조). 테스트는 pending/escalated/OFF/예시-거짓매칭 케이스 포함.

---

## 공통 규약
- **마커**: 문서 어딘가에 `^spec-review:` 로 시작하는 라인(frontmatter 키 스타일). 위치 무관·grep 감지(CRLF 내성). 예:
  `spec-review: { status: passed, decision: accept, lenses: 3, date: 2026-06-14 }`
- **경로 매칭**: `*/docs/superpowers/specs/*.md` 또는 `*/docs/superpowers/plans/*.md`.
- **OFF 스위치**: env `DISCIPLINED_CODER_REVIEW_GATE=off` → 모든 훅 0-cost 통과.
- **의존성 폴백(FAIL-OPEN)**: `jq`/`git` 없으면 즉시 exit 0(작업불능 방지 — 알려진 한계).

## File Structure
- `hooks/spec_review_posttooluse.sh` — 즉시 감지·신호(비블로킹).
- `hooks/spec_review_stop.sh` — 하드 게이트(루프가드·git 탐지).
- `hooks/hooks.json` — PostToolUse·Stop 추가(기존 SessionStart 보존).
- `skills/advisor-spec-review/SKILL.md` — 1→3렌즈+메타+마커 규약.
- `scripts/test_hooks.sh` — 훅 불변식 테스트(계약 FAIL=0).
- `coding-principles.md`·`README.md` — 동기화.

---

### Task 1: PostToolUse 훅 (즉시 감지·신호)

**Files:**
- Create: `hooks/spec_review_posttooluse.sh`
- Test: `scripts/test_hooks.sh`

- [ ] **Step 1: 실패 테스트 — test_hooks.sh 골격 + PostToolUse 케이스**

`scripts/test_hooks.sh`:
```bash
#!/usr/bin/env bash
# 훅 스크립트 검증. 계약: FAIL=0 (매직넘버 금지 — 개수는 테스트가 센다).
set -euo pipefail
HERE="$(cd "$(dirname "$0")/.." && pwd)"
PTU="$HERE/hooks/spec_review_posttooluse.sh"
STOP="$HERE/hooks/spec_review_stop.sh"
pass=0; fail=0
check() { if eval "$2"; then echo "  PASS: $1"; pass=$((pass+1)); else echo "  FAIL: $1"; fail=$((fail+1)); fi; }

# PostToolUse: spec 경로 + 마커 없음 → additionalContext 주입
ptu() { printf '%s' "$1" | bash "$PTU"; }
SPEC='{"tool_input":{"file_path":"/x/docs/superpowers/specs/a.md"}}'
PLAN='{"tool_input":{"file_path":"/x/docs/superpowers/plans/b.md"}}'
OTHER='{"tool_input":{"file_path":"/x/src/main.py"}}'
echo "[ptu]"
check "spec(미마커) → 리뷰 지시"   "ptu '$SPEC' | grep -q additionalContext"
check "plan(미마커) → 리뷰 지시"   "ptu '$PLAN' | grep -q additionalContext"
check "무관 경로 → 무출력"          "[ -z \"\$(ptu '$OTHER')\" ]"
check "OFF 스위치 → 무출력"         "[ -z \"\$(DISCIPLINED_CODER_REVIEW_GATE=off ptu '$SPEC')\" ]"

echo "----"; echo "PASS=$pass FAIL=$fail"; [ "$fail" -eq 0 ]
```

- [ ] **Step 2: 실행해 실패 확인**

Run: `bash scripts/test_hooks.sh`
Expected: FAIL (스크립트 없음 → bash 오류 또는 빈 출력으로 FAIL).

- [ ] **Step 3: 최소 구현 — PostToolUse 스크립트**

`hooks/spec_review_posttooluse.sh`:
```bash
#!/usr/bin/env bash
# PostToolUse(Write|Edit): spec/plan 작성 감지 → 미리뷰면 3렌즈 리뷰 수행 지시 주입(비블로킹).
set -euo pipefail
[ "${DISCIPLINED_CODER_REVIEW_GATE:-on}" = "off" ] && exit 0
command -v jq >/dev/null 2>&1 || exit 0
INPUT="$(cat)"
FILE="$(printf '%s' "$INPUT" | jq -r '.tool_input.file_path // empty' 2>/dev/null || true)"
[ -n "$FILE" ] || exit 0
case "$FILE" in
  */docs/superpowers/specs/*.md|*/docs/superpowers/plans/*.md) ;;
  *) exit 0 ;;   # 0-cost 조기탈출
esac
# 마커 있으면 침묵(재작업 편집의 무한 재트리거 방지)
if [ -f "$FILE" ] && grep -q '^spec-review:' "$FILE" 2>/dev/null; then exit 0; fi
base="$(basename "$FILE")"
jq -n --arg b "$base" '{hookSpecificOutput:{hookEventName:"PostToolUse",additionalContext:("📋 spec/plan(" + $b + ") 작성됨 — 진행 전 반드시 disciplined-coder advisor-spec-review 스킬로 3렌즈 독립 리뷰를 수행하고 문서에 spec-review 마커를 남겨라.")}}'
exit 0
```

- [ ] **Step 4: 실행해 통과 확인**

Run: `bash scripts/test_hooks.sh`
Expected: `[ptu]` 4개 PASS, `FAIL=0`.

- [ ] **Step 5: 커밋**

```bash
git add hooks/spec_review_posttooluse.sh scripts/test_hooks.sh
git commit -m "feat(hooks): PostToolUse — spec/plan 작성 시 리뷰 지시 주입"
```

---

### Task 2: 마커 감지 CRLF 내성

**Files:**
- Modify: `scripts/test_hooks.sh`

- [ ] **Step 1: 실패 테스트 — 마커 있으면 침묵(LF·CRLF 둘 다)**

`scripts/test_hooks.sh`의 `[ptu]` 블록 끝에 추가:
```bash
TMP="$(mktemp -d)"; MF="$TMP/docs/superpowers/specs/m.md"; mkdir -p "$(dirname "$MF")"
printf 'body\nspec-review: { status: passed }\n' > "$MF"
printf 'body\r\nspec-review: { status: passed }\r\n' > "$TMP/crlf.md"; CRLFD="$TMP/docs/superpowers/specs"; cp "$TMP/crlf.md" "$CRLFD/c.md"
J_M="{\"tool_input\":{\"file_path\":\"$MF\"}}"
J_C="{\"tool_input\":{\"file_path\":\"$CRLFD/c.md\"}}"
check "마커 있으면 침묵(LF)"   "[ -z \"\$(ptu '$J_M')\" ]"
check "마커 있으면 침묵(CRLF)" "[ -z \"\$(ptu '$J_C')\" ]"
```

- [ ] **Step 2: 실행** — Run: `bash scripts/test_hooks.sh` · Expected: CRLF 케이스 FAIL 가능(grep `^spec-review:`가 `\r` 영향 없으면 PASS).

- [ ] **Step 3: 구현 보정(필요 시)** — `^spec-review:`는 행 끝 `\r`와 무관하게 매칭되어 통과해야 한다. 만약 FAIL이면 grep 패턴을 `grep -qE '^spec-review:'`로 유지(이미 행두 매칭이라 CRLF 무해). 추가 변경 불필요면 스킵.

- [ ] **Step 4: 실행** — Run: `bash scripts/test_hooks.sh` · Expected: 마커 2케이스 PASS, FAIL=0.

- [ ] **Step 5: 커밋** — `git add scripts/test_hooks.sh && git commit -m "test(hooks): 마커 감지 CRLF 내성 케이스"`

---

### Task 3: Stop 훅 (하드 게이트)

**Files:**
- Create: `hooks/spec_review_stop.sh`
- Modify: `scripts/test_hooks.sh`

- [ ] **Step 1: 실패 테스트 — Stop 게이트 + 루프가드 + git 탐지**

`scripts/test_hooks.sh`에 추가(`[ptu]` 뒤):
```bash
echo "[stop]"
stop() { printf '%s' "$1" | bash "$STOP"; }
# 루프 가드: stop_hook_active=true → 통과(무출력)
check "loop guard(active=true) → 통과" "[ -z \"\$(stop '{\"stop_hook_active\":true,\"cwd\":\"/tmp\"}')\" ]"
check "OFF 스위치 → 통과"              "[ -z \"\$(DISCIPLINED_CODER_REVIEW_GATE=off stop '{\"cwd\":\"/tmp\"}')\" ]"
# git 레포: 미리뷰 spec 있으면 block
G="$(mktemp -d)"; ( cd "$G" && git init -q && git config user.email t@t && git config user.name t )
mkdir -p "$G/docs/superpowers/specs"; printf 'draft\n' > "$G/docs/superpowers/specs/new.md"
J_G="{\"cwd\":\"$G\"}"
check "미리뷰 spec → block"   "stop '$J_G' | grep -q '\"block\"'"
# 마커 달면 통과
printf 'draft\nspec-review: { status: passed }\n' > "$G/docs/superpowers/specs/new.md"
check "마커 후 → 통과(무출력)" "[ -z \"\$(stop '$J_G')\" ]"
```

- [ ] **Step 2: 실행해 실패 확인** — Run: `bash scripts/test_hooks.sh` · Expected: `[stop]` FAIL(스크립트 없음).

- [ ] **Step 3: 최소 구현 — Stop 스크립트**

`hooks/spec_review_stop.sh`:
```bash
#!/usr/bin/env bash
# Stop: 미리뷰 spec/plan이 남으면 종료 차단(하드 게이트). 루프가드: stop_hook_active.
set -euo pipefail
[ "${DISCIPLINED_CODER_REVIEW_GATE:-on}" = "off" ] && exit 0
command -v jq >/dev/null 2>&1 || exit 0
INPUT="$(cat)"
active="$(printf '%s' "$INPUT" | jq -r '.stop_hook_active // false' 2>/dev/null || echo false)"
[ "$active" = "true" ] && exit 0
command -v git >/dev/null 2>&1 || exit 0   # FAIL-OPEN 경계
cwd="$(printf '%s' "$INPUT" | jq -r '.cwd // empty' 2>/dev/null || true)"
[ -n "$cwd" ] && cd "$cwd" 2>/dev/null || exit 0
git rev-parse --is-inside-work-tree >/dev/null 2>&1 || exit 0
unreviewed=""
while IFS= read -r f; do
  [ -n "$f" ] || continue
  case "$f" in
    *docs/superpowers/specs/*.md|*docs/superpowers/plans/*.md) ;;
    *) continue ;;
  esac
  [ -f "$f" ] || continue
  grep -q '^spec-review:' "$f" 2>/dev/null || unreviewed="$unreviewed $f"
done < <(git status --porcelain -- docs/superpowers/specs docs/superpowers/plans 2>/dev/null | cut -c4-)
if [ -n "$unreviewed" ]; then
  reason="미리뷰 spec/plan:$unreviewed — advisor-spec-review(3렌즈)를 수행하고 문서에 spec-review 마커를 남긴 뒤 종료하라."
  jq -n --arg r "$reason" '{decision:"block", reason:$r}'
fi
exit 0
```

- [ ] **Step 4: 실행해 통과 확인** — Run: `bash scripts/test_hooks.sh` · Expected: `[stop]` 4개 PASS, FAIL=0.

- [ ] **Step 5: 커밋** — `git add hooks/spec_review_stop.sh scripts/test_hooks.sh && git commit -m "feat(hooks): Stop 하드 게이트 — 미리뷰 spec/plan 차단"`

---

### Task 4: hooks.json 배선

**Files:**
- Modify: `hooks/hooks.json`

- [ ] **Step 1: 구현 — PostToolUse·Stop 추가(SessionStart 보존)**

`hooks/hooks.json` 전체:
```json
{
  "hooks": {
    "SessionStart": [
      { "matcher": "startup", "hooks": [ { "type": "command", "command": "bash \"${CLAUDE_PLUGIN_ROOT}/scripts/scaffold.sh\"" } ] }
    ],
    "PostToolUse": [
      { "matcher": "Write|Edit", "hooks": [ { "type": "command", "command": "bash \"${CLAUDE_PLUGIN_ROOT}/hooks/spec_review_posttooluse.sh\"" } ] }
    ],
    "Stop": [
      { "hooks": [ { "type": "command", "command": "bash \"${CLAUDE_PLUGIN_ROOT}/hooks/spec_review_stop.sh\"" } ] }
    ]
  }
}
```

- [ ] **Step 2: 검증** — Run: `claude plugin validate ./` · Expected: Validation passed(version 경고만). + `cat hooks/hooks.json | jq .`로 JSON 유효성.

- [ ] **Step 3: 커밋** — `git add hooks/hooks.json && git commit -m "feat(hooks): hooks.json에 PostToolUse·Stop 배선"`

---

### Task 5: advisor-spec-review 3렌즈 확장

**Files:**
- Modify: `skills/advisor-spec-review/SKILL.md`

- [ ] **Step 1: 구현 — 1렌즈→3렌즈+메타+마커**

`skills/advisor-spec-review/SKILL.md`의 "리뷰어(MVP=1회)" 절을 아래로 교체(나머지 절은 유지):
- **리뷰어(3렌즈)**: read-only 서브에이전트(Edit/Write 없는 에이전트 — 구조적 거짓방지) **병렬 3**: factual/grounding, consistency/coverage, adversarial/YAGNI. adversarial 가드: "기능 추가 제안 금지(YAGNI 리뷰가 기능 늘리면 자가당착), 근거 필수."
- **메타 집계**: `advisor-meta` 재사용(여기 재기술 안 함) — severity 정렬·출처 태깅·상충 감지(코드 로직) → decision.
- **트리거**: PostToolUse가 작성 즉시 이 스킬 수행을 지시, Stop이 미수행 시 종료 차단. 완료 후 문서에 마커 한 줄:
  `spec-review: { status: passed|escalated, decision: accept|regenerate|escalate, lenses: 3, date: YYYY-MM-DD }`
- 라우팅/수렴가드/단일작성자 절은 기존 유지(참조).

- [ ] **Step 2: 검증** — Run: `grep -c 'factual\|consistency\|adversarial' skills/advisor-spec-review/SKILL.md` · Expected: 3렌즈 모두 언급. + `grep -q 'spec-review:' skills/advisor-spec-review/SKILL.md`로 마커 규약 존재.

- [ ] **Step 3: 커밋** — `git add skills/advisor-spec-review/SKILL.md && git commit -m "feat(skill): advisor-spec-review 3렌즈+메타+마커 규약"`

---

### Task 6: coding-principles·README 동기화 (SSOT)

**Files:**
- Modify: `coding-principles.md`, `README.md`

- [ ] **Step 1: 구현 — "메타 산출물 리뷰 절차"를 강제·3렌즈로 갱신**

`coding-principles.md` "메타 산출물 리뷰 절차" 줄을 갱신: "고위험 spec/plan은 `advisor-spec-review`(3렌즈)로 독립 리뷰하며, superpowers spec/plan 작성 시 **훅이 강제**(PostToolUse 감지 + Stop 게이트, `spec-review` 마커로 해제)." `README.md` "메타 산출물 리뷰" 단락에 훅 강제·OFF 스위치(`DISCIPLINED_CODER_REVIEW_GATE=off`) 한 줄 추가.

- [ ] **Step 2: 검증** — Run: `grep -q 'spec-review' coding-principles.md && grep -q 'DISCIPLINED_CODER_REVIEW_GATE' README.md` · Expected: 둘 다 존재(exit 0).

- [ ] **Step 3: 커밋** — `git add coding-principles.md README.md && git commit -m "docs: 강제 트리거·3렌즈 동기화(SSOT)"`

---

### Task 7: 회귀 + 이슈 로그

- [ ] **Step 1: 전체 회귀** — Run: `bash scripts/test_scaffold.sh && bash scripts/test_hooks.sh` · Expected: 둘 다 `FAIL=0`.
- [ ] **Step 2: 플러그인 검증** — Run: `claude plugin validate ./` · Expected: passed.
- [ ] **Step 3: 이슈 로그** — `~/.claude/disciplined-coder/unsolved_problems.md`의 🟡 "결정론 PostToolUse 훅"을 `solved_problems.md`로 이동(문제→원인→해결: 실측+구현). 메인 세션이 기록.
- [ ] **Step 4: 마커** — 이 plan 문서와 spec에 `spec-review` 마커 확인(dogfood).

---

## Self-Review (writing-plans)
- **Spec coverage**: §3.1 마커→Task5/공통, §3.2 탐지→Task3, §3.3 PostToolUse→Task1, §3.4 Stop→Task3, §3.5 3렌즈→Task5, §3.6 라우팅→Task5(기존절 유지), §4 변경파일→Task1-6, §5 검증→Task1-7, §6 OFF/폴백→Task1/3. 커버 OK.
- **Placeholder scan**: 모든 step에 실제 코드/명령. "handle edge cases" 류 없음.
- **Type consistency**: 마커 패턴 `^spec-review:`·경로 glob·env명 `DISCIPLINED_CODER_REVIEW_GATE`·출력 스키마(PostToolUse=hookSpecificOutput.additionalContext, Stop=decision/reason)가 전 Task 일관.
- **마커 규약 정밀화(self-review 발견)**: 마커는 **terminal(passed/escalated)일 때만** 기록한다. "pending" 마커는 존재해선 안 됨. → spec §3.1·skill·훅 탐지(마지막 줄 HTML 주석)에 반영 완료.

## 리뷰 반영 로그 (plan dogfooding)
plan을 3렌즈에 돌린 결과(전원 revise)·처리: factual(`cd` 단축평가 버그·8-cap 날조·jq 의존) / consistency(마커 terminal-only 드리프트·테스트 공백·skill 3렌즈 텍스트 누락) / adversarial(**마커 본문 자기매칭** critical·self-deadlock·전역훅 비용·idempotent 레거시) — 모두 반영(위 헤더 박스·실제 `hooks/` 코드·`test_hooks.sh` 14 케이스 FAIL=0). 사용자 입력(3렌즈 고정·PREP)도 spec/skill 반영.
---
<!-- spec-review: passed lenses=3 date=2026-06-14 -->

