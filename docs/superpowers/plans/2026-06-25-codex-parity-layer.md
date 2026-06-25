# Codex Parity Layer Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** disciplined-coder의 원칙·스킬·강제 게이트가 Codex(OpenAI Codex CLI)에서도 Claude Code와 동일하게 동작하도록, 기존 자산을 바꾸지 않고 가산형 Codex 레이어를 더한다.

**Architecture:** 공유 SSOT(`agent-principles.md`·`domains-index.md`·`skills/**`·훅 로직)는 두 런타임이 같이 읽는다. 런타임이 갈리는 단 한 지점(파일편집 도구: Claude=Write/Edit `file_path`, Codex=`apply_patch` 패치 헤더)을 공용 헬퍼 `_extract_path.sh`로 흡수하고, Codex 매니페스트(`.codex-plugin/plugin.json`)·Codex 훅 배선(`hooks-codex.json`)·Codex 셋업(`codex-scaffold.sh`)·Codex 세션 주입(`session-start-codex`)을 추가한다.

**Tech Stack:** 순수 bash + sed/awk(jq 비의존, 기존 규약), JSON 매니페스트, Codex 플러그인 훅(SessionStart/PreToolUse/PostToolUse/Stop).

## Global Constraints

- **순수 bash, jq 비의존** — 대상 환경에 jq가 없을 수 있다. sed/awk만 사용(기존 모든 훅·스크립트 규약).
- **테스트 계약: FAIL=0, 매직넘버 금지** — 기대 개수를 박지 말 것. 불변식(FAIL=0)으로만 검증하고 개수는 테스트가 센다.
- **기존 Claude 동작 불변** — `hooks/hooks.json`·`scripts/scaffold.sh`·`agent-principles.md`·`domains-index.md`·`skills/**`는 손대지 않는다. 3개 Pre/Post 훅 스크립트는 *내부 경로추출만* 헬퍼 호출로 교체하되 출력은 동일하게 유지한다. `spec_review_stop.sh`는 git 기반이라 손대지 않는다.
- **백슬래시→슬래시 경로 정규화** — 모든 경로는 `tr -s '\\' '/'`로 정규화(기존 규약).
- **마커 규약** — terminal HTML 주석 `<!-- spec-review: passed lenses=3 date=YYYY-MM-DD -->`(또는 `escalated`)만 인정. pending/본문중간 예시는 마커 아님.
- **OFF 토글** — 모든 게이트는 `DISCIPLINED_CODER_REVIEW_GATE=off`면 즉시 무출력.
- **환경변수** — 훅은 `${CLAUDE_PLUGIN_ROOT}`를 쓴다(Codex가 호환 별칭으로 제공). 테스트 오버라이드: Claude는 `CLAUDE_HOME_DIR`, Codex는 `CODEX_HOME_DIR`.
- **작업 브랜치** — `main`에서 바로 커밋하지 말 것. 먼저 `feat/codex-parity` 브랜치를 만들고 거기서 작업한다.

---

## File Structure

생성:
- `hooks/_extract_path.sh` — 공용 경로 추출 헬퍼(양 런타임 입력).
- `scripts/codex-scaffold.sh` — `~/.codex/` 셋업(scaffold.sh의 Codex 쌍둥이).
- `hooks/session-start-codex` — Codex SessionStart 훅(scaffold 실행 + 원칙 주입 + 신뢰검토 경고).
- `hooks/hooks-codex.json` — Codex 훅 배선.
- `.codex-plugin/plugin.json` — Codex 매니페스트.
- `scripts/test_codex_scaffold.sh` — Codex 셋업·매니페스트 검증.

수정(최소):
- `hooks/doc_format_pretooluse.sh`, `hooks/spec_review_posttooluse.sh`, `hooks/doc_review_posttooluse.sh` — 경로추출을 헬퍼+다중경로 순회로. 출력 불변.
- `scripts/test_hooks.sh` — 헬퍼 단위 케이스 + Codex `apply_patch` 입력 케이스 추가.
- `CLAUDE.md`, `README.md`, `docs/DESIGN-NOTES.md` — Codex 설치·신뢰검토·테스트 명령 반영.

불변(손대지 않음): `hooks/hooks.json`, `scripts/scaffold.sh`, `hooks/spec_review_stop.sh`, `agent-principles.md`, `domains-index.md`, `skills/**`, `.claude-plugin/**`.

---

## Task 0: 작업 브랜치 생성

- [ ] **Step 1: 브랜치 생성**

```bash
cd /home/im_sharks/disciplined-coder
git checkout -b feat/codex-parity
```

---

## Task 1: 공용 경로 추출 헬퍼 `_extract_path.sh`

**Files:**
- Create: `hooks/_extract_path.sh`
- Test: `scripts/test_hooks.sh` (새 `[extract]` 섹션 추가)

**Interfaces:**
- Consumes: stdin JSON(훅 입력 전체).
- Produces: stdout에 편집 대상 파일 경로를 **0개 이상**, 한 줄에 하나씩, 백슬래시→슬래시 정규화·중복 제거하여 출력. Claude `file_path` 필드와 Codex `apply_patch` 패치 헤더(`*** Add|Update|Delete File: <path>`)를 모두 인식.

- [ ] **Step 1: 실패 테스트 작성** — `scripts/test_hooks.sh`의 `J()` 정의(15행) 아래에 헬퍼 핸들과 fixture, `[extract]` 섹션을 추가한다.

`scripts/test_hooks.sh` 15행 `J() { ... }` 다음 줄에 추가:

```bash
EXTRACT="$HERE/hooks/_extract_path.sh"
extract() { printf '%s' "$1" | bash "$EXTRACT"; }
# Codex apply_patch 입력 픽스처(패치는 JSON 문자열이라 개행이 \n 이스케이프됨)
AP1() { printf '{"tool_input":{"input":"*** Begin Patch\\n*** Update File: %s\\n@@\\n+x\\n*** End Patch\\n"}}' "$1"; }
AP2() { printf '{"tool_input":{"input":"*** Begin Patch\\n*** Update File: %s\\n@@\\n+x\\n*** Add File: %s\\n+y\\n*** End Patch\\n"}}' "$1" "$2"; }
APDEL() { printf '{"tool_input":{"input":"*** Begin Patch\\n*** Delete File: %s\\n*** End Patch\\n"}}' "$1"; }
```

`scripts/test_hooks.sh`의 `echo "[ptu]"`(29행) **바로 앞**에 새 섹션을 삽입:

```bash
echo "[extract]"
check "Claude file_path → 경로 1개"        "[ \"\$(extract '$(J "$T/src/a.md")')\" = '$T/src/a.md' ]"
check "Codex apply_patch update → 경로 1개" "[ \"\$(extract '$(AP1 "$T/src/b.md")')\" = '$T/src/b.md' ]"
check "Codex apply_patch delete → 경로 1개" "[ \"\$(extract '$(APDEL "$T/src/c.md")')\" = '$T/src/c.md' ]"
check "Codex 다중 파일 → 두 경로 모두"      "[ \"\$(extract '$(AP2 "$T/src/d.py" "$T/src/e.md")' | tr '\n' ',')\" = '$T/src/d.py,$T/src/e.md,' ]"
check "빈 입력 → 무출력"                    "[ -z \"\$(extract '{}')\" ]"
```

- [ ] **Step 2: 테스트 실행 → 실패 확인**

Run: `bash scripts/test_hooks.sh`
Expected: FAIL — `_extract_path.sh` 부재로 `[extract]` 케이스 전부 FAIL(`PASS=… FAIL>0`).

- [ ] **Step 3: 헬퍼 구현** — `hooks/_extract_path.sh` 생성:

```bash
#!/usr/bin/env bash
# 편집 대상 파일 경로를 stdin JSON에서 전부 추출(한 줄에 하나, 백슬래시→슬래시 정규화, 중복 제거).
# 두 런타임 입력을 모두 처리: Claude(Write/Edit)의 "file_path" + Codex(apply_patch)의 패치 헤더.
# 순수 bash/sed/awk(jq 비의존).
set -euo pipefail
INPUT="$(cat)"
{
  # (1) Claude: "file_path":"<path>" — 0개 이상 (Write/Edit는 정확히 1개)
  printf '%s' "$INPUT" | grep -o '"file_path"[[:space:]]*:[[:space:]]*"[^"]*"' \
    | sed 's/.*:[[:space:]]*"\([^"]*\)"$/\1/'
  # (2) Codex apply_patch: 패치가 JSON 문자열이라 개행이 \n 이스케이프됨 → 이스케이프된 \r 제거 후
  #     \n을 실제 개행으로 풀고 '*** Add|Update|Delete File: <path>' 헤더에서 경로(줄 나머지)를 추출.
  printf '%s' "$INPUT" | awk '{gsub(/\\r/,""); gsub(/\\n/,"\n")}1' \
    | sed -n 's/^\*\*\* \(Add\|Update\|Delete\) File: \(.*\)$/\2/p'
} | tr -s '\\' '/' | awk 'NF && !seen[$0]++'
```

- [ ] **Step 4: 테스트 실행 → 통과 확인**

Run: `bash scripts/test_hooks.sh`
Expected: `[extract]` 케이스 전부 PASS, 기존 케이스도 그대로 PASS. 마지막 줄 `PASS=… FAIL=0`.

- [ ] **Step 5: 커밋**

```bash
git add hooks/_extract_path.sh scripts/test_hooks.sh
git commit -m "feat(hooks): add _extract_path helper (file_path + apply_patch, multi-path)"
```

---

## Task 2: 3개 Pre/Post 훅을 헬퍼+다중경로 순회로 전환

**Files:**
- Modify: `hooks/doc_format_pretooluse.sh`, `hooks/spec_review_posttooluse.sh`, `hooks/doc_review_posttooluse.sh`
- Test: `scripts/test_hooks.sh` (Codex `apply_patch` 입력 케이스 추가)

**Interfaces:**
- Consumes: `hooks/_extract_path.sh`(Task 1)로 경로 목록을 얻는다.
- Produces: 동작·출력은 기존과 동일(`{"hookSpecificOutput":{"hookEventName":...,"additionalContext":...}}`). Claude `file_path` 입력은 한 경로만 나오므로 결과 불변, Codex `apply_patch` 다중 파일은 빠짐없이 검사.

- [ ] **Step 1: 실패 테스트 작성** — `scripts/test_hooks.sh` `[doc-review-post]` 섹션 마지막(81행 OFF 케이스) 다음, `echo "----"`(83행) **앞**에 Codex 입력 섹션 추가:

```bash
echo "[codex apply_patch input]"
check "ptu: apply_patch spec 미마커 → 리뷰 지시"      "ptu '$(AP1 "$SP/nomark.md")' | grep -q additionalContext"
check "ptu: apply_patch 다중(2번째가 spec) → 지시"    "ptu '$(AP2 "$T/src/x.py" "$SP/nomark.md")' | grep -q additionalContext"
check "ptu: apply_patch terminal passed → 무출력"     "[ -z \"\$(ptu '$(AP1 "$SP/passed.md")')\" ]"
check "fpre: apply_patch 새 .md → 양식 제안"          "fpre '$(AP1 "$T/codexnew.md")' | grep -q additionalContext"
check "drev: apply_patch 기존 .md → 검진 넛지"        "drev '$(AP1 "$T/existing.md")' | grep -q additionalContext"
check "drev: apply_patch 비문서(.py) → 무출력"        "[ -z \"\$(drev '$(AP1 "$T/src/main.py")')\" ]"
```

- [ ] **Step 2: 테스트 실행 → 실패 확인**

Run: `bash scripts/test_hooks.sh`
Expected: FAIL — 기존 훅은 `"file_path"`만 sed로 보므로 `apply_patch` 입력에서 경로를 못 찾아 `[codex apply_patch input]` 케이스가 FAIL(특히 다중·새문서·넛지).

- [ ] **Step 3: `hooks/doc_format_pretooluse.sh` 교체** — 전체를 아래로:

```bash
#!/usr/bin/env bash
# PreToolUse(Write|Edit | Codex apply_patch): 새 문서(.md, spec/plan 제외) 생성 감지 → domain-docs 양식 제안(비블로킹).
# 경로는 _extract_path.sh가 양 런타임 입력에서 추출(다중 경로 순회). 순수 bash.
set -euo pipefail
[ "${DISCIPLINED_CODER_REVIEW_GATE:-on}" = "off" ] && exit 0
DIR="$(cd "$(dirname "$0")" && pwd)"
INPUT="$(cat)"
match=""
while IFS= read -r FILE; do
  [ -n "$FILE" ] || continue
  case "$FILE" in *.md) ;; *) continue ;; esac          # 문서(.md)만
  case "$FILE" in */docs/superpowers/specs/*|*/docs/superpowers/plans/*) continue ;; esac  # spec/plan은 자체 흐름
  [ -e "$FILE" ] && continue                             # 생성 때만 제안(편집은 양식 이미 정해짐)
  match="$FILE"; break
done <<EOF
$(printf '%s' "$INPUT" | bash "$DIR/_extract_path.sh")
EOF
[ -n "$match" ] || exit 0
msg="📝 새 문서 작성 — 쓰기 전에 domain-docs '글 유형별 적용'에서 목적에 맞는 양식을 고르고(README·버그리포트·작업보고·기술블로그), 결론/요약을 앞에 두고 내용을 양식대로 배치하라."
esc="$(printf '%s' "$msg" | sed 's/\\/\\\\/g; s/"/\\"/g')"
printf '{"hookSpecificOutput":{"hookEventName":"PreToolUse","additionalContext":"%s"}}\n' "$esc"
exit 0
```

- [ ] **Step 4: `hooks/spec_review_posttooluse.sh` 교체** — 전체를 아래로:

```bash
#!/usr/bin/env bash
# PostToolUse(Write|Edit | Codex apply_patch): spec/plan 작성 감지 → 미리뷰면 3렌즈+PREP 리뷰 지시(비블로킹).
# 마커: 마지막 비공백 줄의 terminal HTML 주석(passed|escalated)만 인정. 경로는 _extract_path.sh(다중 순회).
set -euo pipefail
[ "${DISCIPLINED_CODER_REVIEW_GATE:-on}" = "off" ] && exit 0
DIR="$(cd "$(dirname "$0")" && pwd)"
INPUT="$(cat)"
match=""
while IFS= read -r FILE; do
  [ -n "$FILE" ] || continue
  case "$FILE" in
    */docs/superpowers/specs/*.md|*/docs/superpowers/plans/*.md) ;;
    *) continue ;;
  esac
  if [ -f "$FILE" ]; then
    last="$(grep -v '^[[:space:]]*$' "$FILE" 2>/dev/null | tail -n 1 || true)"
    case "$last" in
      *'<!-- spec-review: passed'*|*'<!-- spec-review: escalated'*) continue ;;
    esac
  fi
  match="$FILE"; break
done <<EOF
$(printf '%s' "$INPUT" | bash "$DIR/_extract_path.sh")
EOF
[ -n "$match" ] || exit 0
base="$(basename "$match")"
msg="📋 spec/plan(${base}) 작성됨 — 진행 전 반드시 disciplined-coder domain-spec-review 스킬로 3렌즈+PREP 독립 리뷰를 수행하고, 완료 시 문서 마지막 줄에 spec-review passed 마커(HTML 주석)를 남겨라."
esc="$(printf '%s' "$msg" | sed 's/\\/\\\\/g; s/"/\\"/g')"
printf '{"hookSpecificOutput":{"hookEventName":"PostToolUse","additionalContext":"%s"}}\n' "$esc"
exit 0
```

- [ ] **Step 5: `hooks/doc_review_posttooluse.sh` 교체** — 전체를 아래로:

```bash
#!/usr/bin/env bash
# PostToolUse(Write|Edit | Codex apply_patch): 문서(.md, spec/plan 제외) 작성/수정 감지 → 비자가 검진 넛지(비블로킹, 게이트 아님).
# 경로는 _extract_path.sh가 양 런타임 입력에서 추출(다중 순회). 순수 bash.
set -euo pipefail
[ "${DISCIPLINED_CODER_REVIEW_GATE:-on}" = "off" ] && exit 0
DIR="$(cd "$(dirname "$0")" && pwd)"
INPUT="$(cat)"
match=""
while IFS= read -r FILE; do
  [ -n "$FILE" ] || continue
  case "$FILE" in *.md) ;; *) continue ;; esac          # 문서(.md)만
  case "$FILE" in */docs/superpowers/specs/*|*/docs/superpowers/plans/*) continue ;; esac  # spec/plan은 하드 게이트
  match="$FILE"; break
done <<EOF
$(printf '%s' "$INPUT" | bash "$DIR/_extract_path.sh")
EOF
[ -n "$match" ] || exit 0
base="$(basename "$match")"
msg="🔎 문서(${base}) 작성/수정됨 — done 하기 전에 reviewer-grounding(사실·정확)+reviewer-fit(양식·계약) 렌즈로 비자가 검진을 거쳐라. 셀프 퇴고만으로 끝내지 말 것. 넛지일 뿐 차단은 아니다."
esc="$(printf '%s' "$msg" | sed 's/\\/\\\\/g; s/"/\\"/g')"
printf '{"hookSpecificOutput":{"hookEventName":"PostToolUse","additionalContext":"%s"}}\n' "$esc"
exit 0
```

- [ ] **Step 6: 테스트 실행 → 통과 확인**

Run: `bash scripts/test_hooks.sh`
Expected: 기존 Claude 케이스 전부 PASS(동작 불변) + 새 `[codex apply_patch input]` 케이스 전부 PASS. 마지막 줄 `PASS=… FAIL=0`.

- [ ] **Step 7: 커밋**

```bash
git add hooks/doc_format_pretooluse.sh hooks/spec_review_posttooluse.sh hooks/doc_review_posttooluse.sh scripts/test_hooks.sh
git commit -m "feat(hooks): route Pre/Post gates through _extract_path (Codex apply_patch parity)"
```

---

## Task 3: Codex 셋업 스크립트 `codex-scaffold.sh`

**Files:**
- Create: `scripts/codex-scaffold.sh`
- Test: `scripts/test_codex_scaffold.sh`

**Interfaces:**
- Consumes: `CLAUDE_PLUGIN_ROOT`(정본 위치), `CODEX_HOME_DIR`(테스트 오버라이드, 기본 `$HOME/.codex`).
- Produces: `$CODEX_HOME/disciplined-coder/`에 `agent-principles.md`·`domains-index.md`·`solved_problems.md`·`unsolved_problems.md` 셋업, `$CODEX_HOME/AGENTS.md`에 관리블록(BEGIN/END, 정본 인라인) 멱등 재생성. stdout으로 principles+domains-index 본문(session-start-codex가 캡처). 진단은 stderr.

- [ ] **Step 1: 실패 테스트 작성** — `scripts/test_codex_scaffold.sh` 생성:

```bash
#!/usr/bin/env bash
# codex-scaffold.sh(Codex 셋업) 검증. 계약: FAIL=0.
set -euo pipefail
HERE="$(cd "$(dirname "$0")/.." && pwd)"
SCAFFOLD="$HERE/scripts/codex-scaffold.sh"
pass=0; fail=0
check() { if eval "$2"; then echo "  PASS: $1"; pass=$((pass+1)); else echo "  FAIL: $1"; fail=$((fail+1)); fi; }
run() { CODEX_HOME_DIR="$1/.codex" CLAUDE_PLUGIN_ROOT="$HERE" bash "$SCAFFOLD"; }

# --- 케이스 1: 신규 PC ---
H1="$(mktemp -d)"
OUT="$(run "$H1")"
K="$H1/.codex/disciplined-coder"; AG="$H1/.codex/AGENTS.md"
echo "[case1] fresh codex home"
check "principles in codex dir"     "[ -f '$K/agent-principles.md' ]"
check "domains-index in codex dir"  "[ -f '$K/domains-index.md' ]"
check "solved created"              "[ -f '$K/solved_problems.md' ]"
check "unsolved created"            "[ -f '$K/unsolved_problems.md' ]"
check "AGENTS.md has managed begin" "[ \$(grep -cF '# BEGIN disciplined-coder' '$AG') -eq 1 ]"
check "AGENTS.md inlines principles" "grep -qF '디시플린' '$AG'"
check "stdout injects principles"   "printf '%s' \"\$OUT\" | grep -qF '디시플린'"

# --- 케이스 2: 멱등성(3회) ---
run "$H1" >/dev/null; run "$H1" >/dev/null
echo "[case2] idempotency"
check "still one managed region"    "[ \$(grep -cF '# BEGIN disciplined-coder' '$AG') -eq 1 ]"

# --- 케이스 3: 기존 AGENTS.md 내용 보존 + 블랭크 비누적 ---
H3="$(mktemp -d)"; mkdir -p "$H3/.codex"; printf 'my codex note\n' > "$H3/.codex/AGENTS.md"
for _ in 1 2 3; do run "$H3" >/dev/null; done
AG3="$H3/.codex/AGENTS.md"
echo "[case3] preserve user content"
check "user note preserved"         "grep -qxF 'my codex note' '$AG3'"
check "one region after 3 runs"     "[ \$(grep -cF '# BEGIN disciplined-coder' '$AG3') -eq 1 ]"

# --- 케이스 4: solved 누적 보존 ---
echo "[case4] solved preserved"
printf '\n- codex 보존 확인\n' >> "$K/solved_problems.md"
run "$H1" >/dev/null
check "solved entry preserved"      "grep -qF 'codex 보존 확인' '$K/solved_problems.md'"

# --- 케이스 5: CRLF 관리영역 인식(중복 안 됨) ---
H5="$(mktemp -d)"; mkdir -p "$H5/.codex"
printf 'note\r\n# BEGIN disciplined-coder (managed — do not edit)\r\n@old\r\n# END disciplined-coder (managed — do not edit)\r\n' > "$H5/.codex/AGENTS.md"
run "$H5" >/dev/null
echo "[case5] CRLF region recognized"
check "CRLF region not duplicated"  "[ \$(grep -cF '# BEGIN disciplined-coder' '$H5/.codex/AGENTS.md') -eq 1 ]"

echo "----"; echo "PASS=$pass FAIL=$fail"; [ "$fail" -eq 0 ]
```

- [ ] **Step 2: 테스트 실행 → 실패 확인**

Run: `bash scripts/test_codex_scaffold.sh`
Expected: FAIL — `codex-scaffold.sh` 부재로 전 케이스 FAIL.

- [ ] **Step 3: `scripts/codex-scaffold.sh` 구현:**

```bash
#!/usr/bin/env bash
# Idempotent. Codex SessionStart마다 실행. 지식을 ~/.codex/disciplined-coder에 두고
# ~/.codex/AGENTS.md 관리블록에 정본을 인라인(Codex는 @import 미지원). 프로젝트 폴더는 안 건드린다.
# scaffold.sh(Claude)의 Codex 쌍둥이 — 정본 소스 동일(PLUGIN_ROOT의 agent-principles.md 등).
set -euo pipefail
PLUGIN_ROOT="${CLAUDE_PLUGIN_ROOT:-$(cd "$(dirname "$0")/.." && pwd)}"
CODEX_HOME="${CODEX_HOME_DIR:-$HOME/.codex}"   # 테스트는 CODEX_HOME_DIR로 오버라이드
KDIR="$CODEX_HOME/disciplined-coder"
AG="$CODEX_HOME/AGENTS.md"
mkdir -p "$KDIR"
created=""

# 1) 정본(static) 복사·갱신: principles, domains-index. src==dst면 생략.
for f in agent-principles.md domains-index.md; do
  src="$PLUGIN_ROOT/$f"; dst="$KDIR/$f"
  if [ -f "$src" ]; then
    if [ "$src" = "$dst" ] || { [ -e "$dst" ] && [ "$src" -ef "$dst" ]; }; then :; else cp "$src" "$dst"; fi
  else
    echo "[disciplined-coder] WARNING: source not found at $src" >&2
  fi
done

# 2) solved/unsolved 누적 파일: 없을 때만 생성.
if [ ! -f "$KDIR/solved_problems.md" ]; then
  cat > "$KDIR/solved_problems.md" <<'EOF'
# 해결된 문제 로그 (solved_problems) — PC 전역

작업 중 발견·해결된 문제. 각 항목: 문제 → 원인 → 해결. 등록·이동은 메인 세션이 수행.
일반화 가능한 항목은 디시플린(agent-principles.md)으로 승격하고 여기서는 제거(SSOT).
EOF
  created="$created solved_problems.md"
fi
if [ ! -f "$KDIR/unsolved_problems.md" ]; then
  cat > "$KDIR/unsolved_problems.md" <<'EOF'
# 미해결 / 대기 문제 (unsolved_problems) — PC 전역

> ⚠️ 🔴 항목은 사용자 결정 대기 — 어떤 에이전트도 자율 구현·수정 금지. 참고만.
등록은 검증/리뷰 종료 시, solved 이동은 테스트 통과 시 — 메인 세션이 수행.
범례: 🔴 결정 필요 · 🟡 구현 대기 · 🔵 향후.

## 🔴 결정 필요

## 🟡 구현 대기

## 🔵 향후 / 선택
EOF
  created="$created unsolved_problems.md"
fi

# 3) ~/.codex/AGENTS.md 관리블록 재생성(멱등, CRLF 내성). @import 미지원 → 정본 본문 인라인.
touch "$AG"
BEGIN_MARK="# BEGIN disciplined-coder (managed — do not edit)"
END_MARK="# END disciplined-coder (managed — do not edit)"
if grep -qF "$BEGIN_MARK" "$AG" && grep -qF "$END_MARK" "$AG"; then
  awk -v b="$BEGIN_MARK" -v e="$END_MARK" '{ l=$0; sub(/\r$/,"",l) } l==b{skip=1} skip==0{print} l==e{skip=0}' "$AG" > "$AG.tmp"
elif grep -qF "$BEGIN_MARK" "$AG"; then
  echo "[disciplined-coder] WARNING: ~/.codex/AGENTS.md has BEGIN but no END — skipping strip" >&2
  cp "$AG" "$AG.tmp"
else
  cp "$AG" "$AG.tmp"
fi
awk '{ l=$0; sub(/\r$/,"",l); if (l ~ /[^ \t]/) last=NR; line[NR]=$0 } END { for (i=1;i<=last;i++) print line[i] }' "$AG.tmp" > "$AG" && rm -f "$AG.tmp"
{
  if [ -s "$AG" ]; then printf '\n'; fi
  printf '%s\n' "$BEGIN_MARK"
  for f in agent-principles.md domains-index.md; do
    if [ -f "$KDIR/$f" ]; then cat "$KDIR/$f"; printf '\n'; fi
  done
  printf '%s\n' "$END_MARK"
} >> "$AG"

# 4) 세션 주입용 stdout: principles + domains-index + solved 본문(session-start-codex가 캡처해 additionalContext로).
#    AGENTS.md 인라인(섹션 3)은 principles+domains만(안정적). 자주 커지는 solved는 주입 경로로(spec 3.5).
for f in agent-principles.md domains-index.md solved_problems.md; do
  if [ -f "$KDIR/$f" ]; then cat "$KDIR/$f"; fi
done

# 5) 보고(진단은 stderr — stdout은 주입 본문 전용).
if [ -n "$created" ]; then echo "[disciplined-coder] Codex knowledge initialized:$created (at $KDIR)" >&2; fi
exit 0
```

- [ ] **Step 4: 테스트 실행 → 통과 확인**

Run: `bash scripts/test_codex_scaffold.sh`
Expected: 전 케이스 PASS. 마지막 줄 `PASS=… FAIL=0`.

- [ ] **Step 5: 커밋**

```bash
git add scripts/codex-scaffold.sh scripts/test_codex_scaffold.sh
git commit -m "feat(codex): add codex-scaffold (~/.codex setup + AGENTS.md managed block)"
```

---

## Task 4: Codex 매니페스트·훅 배선·세션 주입

**Files:**
- Create: `hooks/session-start-codex`, `hooks/hooks-codex.json`, `.codex-plugin/plugin.json`
- Test: `scripts/test_codex_scaffold.sh` (매니페스트·세션훅 검증 섹션 추가)

**Interfaces:**
- Consumes: `scripts/codex-scaffold.sh`(Task 3), 기존 3개 Pre/Post 훅 + `spec_review_stop.sh`.
- Produces: Codex가 로드하는 플러그인 매니페스트 + 훅 배선. `session-start-codex`는 `{"hookSpecificOutput":{"hookEventName":"SessionStart","additionalContext":"<경고+원칙>"}}` JSON을 출력.

- [ ] **Step 1: 실패 테스트 작성** — `scripts/test_codex_scaffold.sh`의 `echo "----"` **앞**에 추가:

```bash
echo "[manifest + session hook]"
SS="$HERE/hooks/session-start-codex"
check "session-start-codex emits additionalContext" "CODEX_HOME_DIR=\"$(mktemp -d)/.codex\" CLAUDE_PLUGIN_ROOT=\"$HERE\" bash '$SS' | grep -q additionalContext"
check "session-start-codex warns about trust review" "CODEX_HOME_DIR=\"$(mktemp -d)/.codex\" CLAUDE_PLUGIN_ROOT=\"$HERE\" bash '$SS' | grep -qF '신뢰'"
check ".codex-plugin manifest is valid JSON" "python3 -c 'import json;json.load(open(\"$HERE/.codex-plugin/plugin.json\"))'"
check "hooks-codex.json is valid JSON"       "python3 -c 'import json;json.load(open(\"$HERE/hooks/hooks-codex.json\"))'"
check "hooks-codex wires apply_patch matcher" "grep -qF 'apply_patch' '$HERE/hooks/hooks-codex.json'"
check "manifest points skills + codex hooks"  "grep -qF 'hooks-codex.json' '$HERE/.codex-plugin/plugin.json'"
```

> 참고: `python3`가 없는 환경이면 두 JSON 검증 케이스는 `command -v python3 ||` 가드로 건너뛰도록 감싸도 된다(이 레포 CI엔 python3 존재 가정).

- [ ] **Step 2: 테스트 실행 → 실패 확인**

Run: `bash scripts/test_codex_scaffold.sh`
Expected: FAIL — session-start-codex·매니페스트 부재.

- [ ] **Step 3: `hooks/session-start-codex` 생성**(확장자 없음 — superpowers 패턴):

```bash
#!/usr/bin/env bash
# Codex SessionStart hook: codex-scaffold(파일 셋업)를 실행하고, 원칙 본문을 additionalContext로 주입한다.
# 첫 줄에 신뢰검토 경고(FAIL-LOUD): Codex는 신뢰검토 후에만 플러그인 훅을 켠다.
set -euo pipefail
DIR="$(cd "$(dirname "$0")" && pwd)"
PLUGIN_ROOT="${CLAUDE_PLUGIN_ROOT:-$(cd "$DIR/.." && pwd)}"
principles="$(CLAUDE_PLUGIN_ROOT="$PLUGIN_ROOT" bash "$DIR/../scripts/codex-scaffold.sh" 2>/dev/null || printf '[disciplined-coder] scaffold error')"
warn="⚠️ disciplined-coder: 강제 게이트(spec/plan·문서 리뷰)는 이 플러그인 훅을 Codex에서 '신뢰'한 뒤에만 작동합니다. 설치 후 한 번 신뢰검토를 완료하세요."
context="$(printf '%s\n\n%s' "$warn" "$principles")"
escape_for_json() {
  local s="$1"
  s="${s//\\/\\\\}"; s="${s//\"/\\\"}"; s="${s//$'\n'/\\n}"; s="${s//$'\r'/\\r}"; s="${s//$'\t'/\\t}"
  printf '%s' "$s"
}
esc="$(escape_for_json "$context")"
printf '{"hookSpecificOutput":{"hookEventName":"SessionStart","additionalContext":"%s"}}\n' "$esc"
exit 0
```

- [ ] **Step 4: `hooks/hooks-codex.json` 생성:**

```json
{
  "hooks": {
    "SessionStart": [
      {
        "matcher": "startup|resume|clear",
        "hooks": [
          { "type": "command", "command": "bash \"${CLAUDE_PLUGIN_ROOT}/hooks/session-start-codex\"" }
        ]
      }
    ],
    "PreToolUse": [
      {
        "matcher": "apply_patch",
        "hooks": [
          { "type": "command", "command": "bash \"${CLAUDE_PLUGIN_ROOT}/hooks/doc_format_pretooluse.sh\"" }
        ]
      }
    ],
    "PostToolUse": [
      {
        "matcher": "apply_patch",
        "hooks": [
          { "type": "command", "command": "bash \"${CLAUDE_PLUGIN_ROOT}/hooks/spec_review_posttooluse.sh\"" },
          { "type": "command", "command": "bash \"${CLAUDE_PLUGIN_ROOT}/hooks/doc_review_posttooluse.sh\"" }
        ]
      }
    ],
    "Stop": [
      {
        "hooks": [
          { "type": "command", "command": "bash \"${CLAUDE_PLUGIN_ROOT}/hooks/spec_review_stop.sh\"" }
        ]
      }
    ]
  }
}
```

- [ ] **Step 5: `.codex-plugin/plugin.json` 생성** — 기존 `.claude-plugin/plugin.json`에서 이름·설명·author·license·keywords를 그대로 파생하고 Codex 키(`skills`/`hooks`/`interface`) 추가:

```json
{
  "name": "disciplined-coder",
  "version": "0.1.0",
  "description": "Team engineering discipline (SSOT principles) + per-domain design references + spec/plan & doc review gates, for Codex. Mirrors the Claude Code plugin via shared skills and hook logic.",
  "author": { "name": "chshin84", "email": "chshin84@gmail.com" },
  "license": "MIT",
  "keywords": ["principles", "discipline", "issue-tracking", "scaffold", "hooks"],
  "skills": "./skills/",
  "hooks": "./hooks/hooks-codex.json",
  "interface": {
    "displayName": "Disciplined Coder",
    "shortDescription": "Engineering discipline, domain references, and spec/plan & doc review gates",
    "category": "Coding"
  }
}
```

> `version`은 Codex 매니페스트 전용 시작값이다. `.claude-plugin/plugin.json`엔 version 필드가 없으므로 SSOT 충돌은 없으나, 추후 Claude 매니페스트가 version을 가지면 이 값과 동기화한다(DESIGN-NOTES에 기록 — Task 5).

- [ ] **Step 6: 테스트 실행 → 통과 확인**

Run: `bash scripts/test_codex_scaffold.sh`
Expected: `[manifest + session hook]` 포함 전 케이스 PASS. `PASS=… FAIL=0`.

- [ ] **Step 7: 전체 회귀 + Claude 검증**

Run:
```bash
bash scripts/test_scaffold.sh && bash scripts/test_hooks.sh && bash scripts/test_codex_scaffold.sh && claude plugin validate ./
```
Expected: 세 테스트 모두 `FAIL=0`, `claude plugin validate`는 기존대로 통과(루트 CLAUDE.md 도그푸딩 때문에 `--strict`만 경고).

- [ ] **Step 8: 커밋**

```bash
git add hooks/session-start-codex hooks/hooks-codex.json .codex-plugin/plugin.json scripts/test_codex_scaffold.sh
git commit -m "feat(codex): add .codex-plugin manifest, hooks-codex wiring, session-start injection"
```

---

## Task 5: 문서 — Codex 설치·신뢰검토·테스트 반영

**Files:**
- Modify: `README.md`, `CLAUDE.md`, `docs/DESIGN-NOTES.md`

**Interfaces:** 없음(문서). 이 Task는 `domain-docs` 양식 넛지·`reviewer-grounding`/`reviewer-fit` 검진 넛지가 뜰 수 있다 — 비블로킹이므로 따르되 차단되지 않는다.

- [ ] **Step 1: `README.md`에 Codex 섹션 추가** — `## 설치` 섹션 끝(로컬 클론 B 다음)에 추가:

```markdown
### Codex에서 쓰기 (동일 디시플린)
이 레포는 Claude Code 플러그인이자 **Codex 플러그인**이다(`.codex-plugin/plugin.json`). Codex도 같은 원칙·스킬·강제 게이트(spec/plan·문서 리뷰)를 받는다.
1. 이 레포를 Codex 플러그인으로 설치한다(`codex plugin` 설치 경로).
2. **신뢰검토 필수** — Codex는 플러그인 훅을 *신뢰*하기 전엔 조용히 건너뛴다. 설치 후 한 번 훅을 신뢰해야 게이트가 작동한다(세션 시작 시 경고가 뜬다).
3. 새 Codex 세션을 시작하면 `session-start-codex` 훅이 `~/.codex/disciplined-coder/` 셋업 + `~/.codex/AGENTS.md` 관리블록 배선 + 원칙 주입을 자동 수행한다.

차이(정직): Codex는 `@import` 미지원이라 원칙을 AGENTS.md 인라인 + 세션 주입의 이중 경로로 전달한다. 파일 편집은 `apply_patch`로 가므로 게이트 훅이 그 입력을 읽는다. 동작은 Claude와 동일하되, 위 신뢰검토 단계가 추가된다.
```

- [ ] **Step 2: `README.md`의 구성 트리에 신규 파일 반영** — `## 구성`의 트리 블록에 줄 추가:

```markdown
├── .codex-plugin/plugin.json       # Codex 매니페스트(skills/hooks/interface)
├── hooks/hooks-codex.json          # Codex 훅 배선(apply_patch matcher · session-start-codex)
├── hooks/session-start-codex       # Codex SessionStart: codex-scaffold 실행 + 원칙 주입 + 신뢰검토 경고
├── hooks/_extract_path.sh          # 공용 경로 추출(file_path + apply_patch, 다중 경로)
├── scripts/codex-scaffold.sh       # 멱등: ~/.codex/ 셋업 + ~/.codex/AGENTS.md 관리블록
├── scripts/test_codex_scaffold.sh  # Codex 셋업·매니페스트·세션훅 검증 (FAIL=0)
```

- [ ] **Step 3: `CLAUDE.md`의 테스트 명령 갱신** — "변경 후" 줄에 codex 테스트 추가:

기존:
```markdown
- 변경 후: 위 테스트 + `bash scripts/test_hooks.sh` (계약 **FAIL=0**) + `claude plugin validate ./` (non-strict).
```
교체:
```markdown
- 변경 후: 위 테스트 + `bash scripts/test_hooks.sh` + `bash scripts/test_codex_scaffold.sh` (각 계약 **FAIL=0**) + `claude plugin validate ./` (non-strict).
```

- [ ] **Step 4: `docs/DESIGN-NOTES.md`에 Codex 레이어 근거 추가** — 파일 끝에 섹션 추가:

```markdown
## Codex 패리티 레이어
- **SSOT 보존**: `agent-principles.md`·`domains-index.md`·`skills/**`·게이트 로직은 두 런타임 공유. Codex 산출물(`.codex-plugin/`·`hooks-codex.json`·`session-start-codex`·`codex-scaffold.sh`)은 가산형.
- **단일 분기점**: 파일 편집 도구가 Claude=Write/Edit(`file_path`) vs Codex=`apply_patch`(패치 헤더). `hooks/_extract_path.sh`가 양쪽을 흡수해 3개 Pre/Post 훅이 공유한다(다중 파일도 전부 추출).
- **상시 원칙**: Claude는 `~/.claude/CLAUDE.md @import`. Codex는 `@import` 미지원이라 `~/.codex/AGENTS.md` 관리블록에 정본을 **인라인**(생성된 사본, 매 세션 멱등 갱신) + `session-start-codex`가 additionalContext로 주입(이중 경로).
- **강제 게이트**: Stop 게이트(`spec_review_stop.sh`, git 기반)가 진짜 차단이며 도구 형태와 무관하게 변경된 spec/plan을 전부 스캔. Pre/Post는 비블로킹 넛지.
- **신뢰검토 갭(FAIL-LOUD)**: Codex는 신뢰검토 전 훅을 침묵 스킵 → `session-start-codex` 주입 첫 줄 경고 + README에 명시.
- **version 동기화**: `.codex-plugin/plugin.json`만 `version`을 갖는다. `.claude-plugin/plugin.json`이 version을 도입하면 둘을 맞춘다.
- **후속(YAGNI)**: Cursor 등 다른 런타임은 같은 per-runtime-manifest 패턴으로 확장하되, 통증·이벤트 차이를 측정한 뒤 추가한다.
```

- [ ] **Step 5: 문서 검진(넛지 따르기)** — README/DESIGN-NOTES 변경에 대해 `reviewer-grounding`(Codex 사실 정확)+`reviewer-fit`(README 양식) 셀프 점검. 사실 오류·과장 없으면 통과.

- [ ] **Step 6: 전체 테스트 재실행 → 통과 확인**

Run:
```bash
bash scripts/test_scaffold.sh && bash scripts/test_hooks.sh && bash scripts/test_codex_scaffold.sh && claude plugin validate ./
```
Expected: 전부 `FAIL=0`, validate 통과.

- [ ] **Step 7: 커밋**

```bash
git add README.md CLAUDE.md docs/DESIGN-NOTES.md
git commit -m "docs(codex): document Codex install, trust-review gap, and parity design"
```

---

## Task 6: 마무리 — 브랜치 통합

- [ ] **Step 1: 최종 회귀**

Run: `bash scripts/test_scaffold.sh && bash scripts/test_hooks.sh && bash scripts/test_codex_scaffold.sh`
Expected: 세 줄 모두 `PASS=… FAIL=0`.

- [ ] **Step 2: 통합** — `superpowers:finishing-a-development-branch` 스킬로 머지/PR/정리 옵션을 선택해 마무리한다.

> **잔존 리스크(spec 6장)**: 이 PC엔 codex가 없어 *실제 게이트 발동*은 미검증이다. codex 설치 환경이 생기면 1회 스모크(파일 편집 시 Pre/Post 발동, 미리뷰 spec 남기고 종료 시 Stop 차단)로 닫는다. 발동 안 하면 SessionStart 주입 컨텍스트의 게이트 규약으로 폴백.

---

## Self-Review

**1. Spec coverage:**
- 3.2 파일표 → Task 1(`_extract_path.sh`)·Task 3(`codex-scaffold.sh`)·Task 4(`session-start-codex`/`hooks-codex.json`/`.codex-plugin`)·Task 2(3 훅 수정)·Task 5(문서). ✓
- 3.3 헬퍼 다중 경로 → Task 1 + Task 2 다중파일 테스트. ✓
- 3.4 게이트 패리티(Stop 불변·Pre/Post apply_patch) → Task 2 + Task 4 hooks-codex.json. ✓
- 3.5 이중 경로 주입(AGENTS.md 인라인 + 세션 주입) → Task 3 + Task 4. ✓
- 5장 신뢰검토 FAIL-LOUD → Task 4 session-start-codex 경고 + Task 5 README. ✓
- 6장 검증(다중파일·codex 스모크) → Task 2 다중파일 케이스 + Task 6 스모크 노트. ✓
- 3.6 후속(Cursor/SubagentStart/커맨드) → 비목표·후속으로 명시, 미구현(의도). ✓

**2. Placeholder scan:** 모든 코드 스텝에 완전한 코드/명령·기대 출력 포함. TBD/TODO 없음. ✓

**3. Type/name consistency:** `_extract_path.sh`(stdin→경로 줄 출력)를 Task 2 세 훅이 동일 인터페이스로 소비. `CODEX_HOME_DIR`·`CLAUDE_PLUGIN_ROOT`·마커 문자열·`apply_patch` matcher가 Task 1·2·3·4에서 일관. 매니페스트의 `hooks-codex.json` 경로가 Task 4 파일명과 일치. ✓

**스펙과의 의도적 차이(기록):** spec 6장은 "test_scaffold.sh 확장"이라 했으나, FOCUSED 원칙(한 테스트=한 스크립트)에 따라 Codex 검증은 별도 `scripts/test_codex_scaffold.sh`로 분리했다(같은 임시홈 패턴). CLAUDE.md 테스트 명령에 반영(Task 5).

**3렌즈 리뷰 반영(2026-06-25):** ① codex-scaffold step 4가 `solved_problems.md`도 stdout 주입(spec 3.5 정합), ② `_extract_path` awk가 이스케이프된 `\r` 제거(apply_patch CRLF 경로 오염 방지), ③ test_codex_scaffold에 CRLF 관리영역 멱등 케이스 추가. 기각된 오탐: 다중파일 trailing-comma(awk가 마지막 줄에도 개행 부가), `print $0` CRLF(scaffold.sh 검증된 비파괴 보존), `-eq 1`(개수 박기가 아닌 불변식 — 기존 테스트와 동일).

<!-- spec-review: passed lenses=3 date=2026-06-25 -->
