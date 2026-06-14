# disciplined-coder Phase 2 (어드바이저 시스템) Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax.

**Goal:** 제품이 **런타임에 LLM을 호출**할 때 단독 콜로 끝내지 않고 검증 레이어를 붙이도록, 4종 어드바이저의 **구현 스펙(스킬)** + **경량 인덱스**를 플러그인에 추가하고, 인덱스를 모든 프로젝트 CLAUDE.md에 주입한다.

**Architecture:** 어드바이저는 Claude Code 에이전트가 아니라 **제품 코드가 구현할 청사진**(spec §3-6). 각 어드바이저 = 온디맨드 스킬 1장(`skills/advisor-*/SKILL.md`). 인덱스(`advisors-index.md`)는 scaffold가 CLAUDE.md에 @import로 주입해 항상 보이게 → 플래너가 선택 근거로 사용. 디시플린에 연결 절차 2줄 추가.

**Tech Stack:** Markdown(스킬·인덱스), Bash(scaffold 확장), 기존 Phase 1 토대 재사용.

**참조 spec:** `docs/superpowers/specs/2026-06-14-disciplined-coder-design.md` §6(어드바이저), §5.2(절차), §5.4(planning 영향), §12 Phase 2.

**설계 결정(이 plan에서 확정, 리뷰 시 조정 가능):** 4종은 두 형태로 나뉜다 — **정합성·적합성**은 런타임 *리뷰 콜*(추가 LLM 호출로 1차 출력 검증), **비기능**은 *구현 체크리스트*(LLM 콜 아님; timeout/retry/None가드 등 코드 요건), **메타**는 *집계·결정 로직*(보통 코드, 모호 상충만 선택적 LLM). 인덱스가 조립·선택을 설명한다.

---

## File Structure (Phase 2)
- **Create** `advisors-index.md` — 경량 인덱스(@import 대상).
- **Create** `skills/advisor-correctness/SKILL.md`, `skills/advisor-fit/SKILL.md`, `skills/advisor-nonfunctional/SKILL.md`, `skills/advisor-meta/SKILL.md`.
- **Modify** `coding-principles.md` — 절차 2줄 섹션 추가.
- **Modify** `scripts/scaffold.sh` — 인덱스도 복사 + 관리영역 @import + stdout.
- **Modify** `scripts/test_scaffold.sh` — 인덱스 배선 검증 추가.
- **Modify** `README.md` — 어드바이저 시스템 섹션.
- **Re-run** scaffold on this repo (dogfood) so its CLAUDE.md region includes `@advisors-index.md`.

---

## Task 1: 디시플린에 절차 2줄 추가

**Files:** Modify `coding-principles.md`

- [ ] **Step 1:** `coding-principles.md` 맨 끝(공통 함정 섹션 뒤)에 아래 섹션을 추가한다:

```markdown

## 절차 (원칙과 별개 — 어드바이저·계획 연결)
- **런타임 LLM 절차** — LLM 콜로 끝나는 런타임 기능은 단독 결론으로 마치지 말고, `advisors-index.md`에서 리스크에 맞는 검증 레이어를 골라 **제품 코드에 구현**한다.
- **계획 시점 절차** — 설계/계획(brainstorming/writing-plans) 시 런타임 LLM 기능은 위 검증 레이어를 **계획에 반드시 포함**한다(포함 범위는 인덱스의 리스크 기준).
```

- [ ] **Step 2:** 커밋
```bash
git add coding-principles.md
git commit -m "feat: add advisor/planning procedural lines to discipline"
```

---

## Task 2: `advisors-index.md` 작성

**Files:** Create `advisors-index.md`

- [ ] **Step 1:** `advisors-index.md`를 아래 내용으로 작성:

```markdown
# 런타임 LLM 검증 어드바이저 — 인덱스

제품이 **런타임에 LLM을 호출**하는 기능을 만들 때, 단독 콜로 끝내지 말고 이 어드바이저들로 **검증 레이어**를 코드에 구현한다. 상세 스펙은 각 스킬(`advisor-*`)을 온디맨드로 참조한다. 이 인덱스는 "언제·무엇을·어떻게 조립"만 담는다.

## 4종
| 어드바이저 | 무엇을 본다 | 형태 | 스킬 |
|---|---|---|---|
| 정합성 (correctness) | 출력이 요청/맥락에 맞나 — 누락·모순·근거 없는 환각 | 런타임 리뷰 콜 | `advisor-correctness` |
| 적합성 (fit) | 출력이 소비자 계약을 지키나 — 형식/스키마/스타일/제약 | 런타임 리뷰 콜 | `advisor-fit` |
| 비기능 (nonfunctional) | 호출 코드가 견고한가 — timeout/retry/None가드/에러형식/비용상한/관측/HITL | 구현 체크리스트 | `advisor-nonfunctional` |
| 메타 (meta) | 위 리뷰어 출력의 구조적 건강성 — 상충·커버리지 공백. 내용 재판단 금지 | 집계·결정 로직 | `advisor-meta` |

## 조립 (런타임 흐름)
1. 1차 LLM 콜 → 후보 출력.
2. (리스크에 따라) 정합성·적합성 **리뷰 콜을 병렬**로 → 각자 severity 태깅 이슈.
3. **메타**가 리뷰 출력을 집계(상충/공백 점검) → 결정: accept / regenerate(1차 재호출) / escalate(HITL).
4. 비기능 체크리스트는 위 전 과정의 **구현 요건**으로 항상 적용(timeout/retry/None가드 등).

## 리스크별 선택
점수: 외부호출 +1 / LLM 컴포넌트 +1 / 인터페이스 계약 변경 +1 / HITL·컴플라이언스 +1 / 명세 3섹션+ +1
- 0–1: 비기능만(가드)
- 2–3: 비기능 + 정합성
- 4–5: 비기능 + 정합성 + 적합성 + 메타

## 비용 주의
리뷰 콜은 추가 LLM 비용·지연을 만든다. 리스크 비례로만 붙이고, 결정론으로 검증 가능한 건(스키마/정규식) 코드로 먼저 거른다. critical만 regenerate 강제, 그 외는 로깅.
```

- [ ] **Step 2:** 커밋
```bash
git add advisors-index.md
git commit -m "feat: add advisors-index.md (runtime LLM verification index)"
```

---

## Task 3: scaffold가 인덱스도 배선 (TDD)

**Files:** Modify `scripts/scaffold.sh`, `scripts/test_scaffold.sh`

- [ ] **Step 1 (test 먼저):** `scripts/test_scaffold.sh` 케이스 1(fresh project) 블록에 아래 3개 check를 추가(기존 6개 check 뒤, `[case2]` 전):
```bash
check "index copied to project"            "[ -f '$T1/advisors-index.md' ]"
check "CLAUDE.md imports index"            "grep -qxF '@advisors-index.md' '$T1/CLAUDE.md'"
check "stdout carries index marker"        "printf '%s' \"\$OUT\" | grep -qF '검증 어드바이저'"
```
또한 케이스 4(src==dst safety) 셋업에서 인덱스도 함께 복사하도록 한 줄 추가(누락 경고 방지):
```bash
cp "$HERE/advisors-index.md" "$T4/advisors-index.md"
```
(케이스 4의 `cp "$PRINCIPLES_SRC" "$T4/coding-principles.md"` 다음 줄에 넣는다.)

- [ ] **Step 2:** 테스트 실행 → 일부 FAIL 확인(현재 scaffold는 인덱스를 복사/배선/출력하지 않음).
Run: `bash scripts/test_scaffold.sh` → "index copied", "imports index", "stdout index marker" FAIL 예상.

- [ ] **Step 3:** `scripts/scaffold.sh`를 아래로 교체(인덱스 복사 일반화 + 관리영역 @advisors-index.md + stdout 양쪽 출력):

```bash
#!/usr/bin/env bash
# Idempotent. SessionStart마다 실행. 없는 것만 만들고, 관리 영역은 항상 재생성.
# 디시플린 + 어드바이저 인덱스 주입 + 프로젝트 이슈 로그 스캐폴드 + CLAUDE.md @import 배선.
# 주의: 관리 영역(BEGIN/END 블록)은 항상 CLAUDE.md 끝에 위치한다.
#       사용자 콘텐츠는 블록 위에 둘 것 — 블록 뒤 내용은 다음 실행 때 블록 앞으로 재배치된다.
set -euo pipefail

ROOT="${CLAUDE_PROJECT_DIR:-$PWD}"
PLUGIN_ROOT="${CLAUDE_PLUGIN_ROOT:-$(cd "$(dirname "$0")/.." && pwd)}"

SOLVED="$ROOT/solved_problems.md"
UNSOLVED="$ROOT/unsolved_problems.md"
CLAUDE_MD="$ROOT/CLAUDE.md"

created=""

# 1) 플러그인 정본 파일들을 프로젝트로 복사(매 세션 갱신 = SSOT에서 도출).
#    src==dst(같은 파일)면 생략 — 문자열 + inode(-ef) 양쪽 판정(cp self-truncate 방지).
copy_from_plugin() {  # $1 = filename
  local src="$PLUGIN_ROOT/$1" dst="$ROOT/$1"
  if [ -f "$src" ]; then
    if [ "$src" = "$dst" ] || { [ -e "$dst" ] && [ "$src" -ef "$dst" ]; }; then
      : # same file — skip copy
    else
      cp "$src" "$dst"
    fi
  else
    echo "[disciplined-coder] WARNING: source not found at $src" >&2
  fi
}
copy_from_plugin coding-principles.md
copy_from_plugin advisors-index.md

# 2) 이슈 로그 생성(없을 때만)
if [ ! -f "$SOLVED" ]; then
  cat > "$SOLVED" <<'EOF'
# 해결된 문제 로그 (solved_problems)

작업 중 발견·해결된 문제 기록. 각 항목: 문제 → 원인 → 해결.
일반화 가능한 항목은 디시플린(coding-principles.md)으로 승격하고 여기서는 제거(SSOT).
(미해결·대기 항목은 `unsolved_problems.md`.)
EOF
  created="$created solved_problems.md"
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
  created="$created unsolved_problems.md"
fi

# 3) CLAUDE.md 관리 영역 재생성(멱등). CRLF 내성: 마커 비교 시 trailing \r 제거.
touch "$CLAUDE_MD"
BEGIN_MARK="# BEGIN disciplined-coder (managed — do not edit)"
END_MARK="# END disciplined-coder (managed — do not edit)"

if grep -qF "$BEGIN_MARK" "$CLAUDE_MD" && grep -qF "$END_MARK" "$CLAUDE_MD"; then
  awk -v b="$BEGIN_MARK" -v e="$END_MARK" '
    { l=$0; sub(/\r$/,"",l) }
    l==b {skip=1}
    skip==0 {print}
    l==e {skip=0}
  ' "$CLAUDE_MD" > "$CLAUDE_MD.tmp"
elif grep -qF "$BEGIN_MARK" "$CLAUDE_MD"; then
  echo "[disciplined-coder] WARNING: CLAUDE.md has BEGIN marker but no END — skipping strip to avoid data loss" >&2
  cp "$CLAUDE_MD" "$CLAUDE_MD.tmp"
else
  cp "$CLAUDE_MD" "$CLAUDE_MD.tmp"
fi

awk '{ l=$0; sub(/\r$/,"",l); if (l ~ /[^ \t]/) last=NR; line[NR]=$0 } END { for (i=1;i<=last;i++) print line[i] }' "$CLAUDE_MD.tmp" > "$CLAUDE_MD" && rm -f "$CLAUDE_MD.tmp"

{
  if [ -s "$CLAUDE_MD" ]; then printf '\n'; fi
  printf '%s\n' "$BEGIN_MARK"
  printf '@coding-principles.md\n@advisors-index.md\n@solved_problems.md\n@unsolved_problems.md\n'
  printf '%s\n' "$END_MARK"
} >> "$CLAUDE_MD"

# 4) 첫 세션 도달 보강: 디시플린 + 인덱스를 stdout으로 출력(SessionStart additionalContext).
for f in coding-principles.md advisors-index.md; do
  if [ -f "$ROOT/$f" ]; then cat "$ROOT/$f"; fi
done

# 5) 생성 보고
if [ -n "$created" ]; then
  echo "[disciplined-coder] scaffolded:$created"
fi
exit 0
```

- [ ] **Step 4:** 검증
Run: `bash -n scripts/scaffold.sh` → clean.
Run: `bash scripts/test_scaffold.sh` → expect `PASS=19 FAIL=0` (기존 16 + 3 신규), exit 0.

- [ ] **Step 5:** 커밋
```bash
git add scripts/scaffold.sh scripts/test_scaffold.sh
git commit -m "feat: scaffold delivers advisors-index.md (copy + managed import + stdout)"
```

---

## Task 4: 어드바이저 스펙 스킬 4종

**Files:** Create the 4 SKILL.md files.

- [ ] **Step 1:** `skills/advisor-correctness/SKILL.md`:
```markdown
---
name: advisor-correctness
description: 런타임에 LLM을 호출하는 제품 기능을 구현할 때, 1차 출력의 "정합성"(요청/맥락 대비 누락·모순·근거 없는 환각)을 검증하는 런타임 리뷰 레이어를 코드로 추가하는 구현 스펙. LLM 출력의 정확성/grounding을 운영 단계에서 거를 때 사용.
---
# 정합성 어드바이저 (correctness) — 런타임 리뷰 콜 구현 스펙

## 언제
1차 LLM 출력이 **요청과 제공된 맥락에 충실**해야 하는 기능(요약·추출·QA·생성 등). 출력을 그대로 쓰기 전에 거른다.

## 렌즈 / 체크리스트
- 요청한 항목/필드/제약을 **빠짐없이** 충족했는가(누락).
- 요청·맥락과 **모순**되는 진술이 있는가.
- 제공된 입력에 **근거 없는 사실**을 지어냈는가(환각).
- 숫자·인용·식별자가 입력과 **일치**하는가.

## 레퍼런스 프롬프트 (언어 중립)
- system: "너는 정합성 검수자다. 원본 요청과 제공된 맥락만을 기준으로, 후보 출력의 누락·모순·근거 없는 주장을 찾아라. 고치지 말고 지적만 하라. 맥락에 없으면 '근거 없음'으로 표시."
- user: "[요청]\n{request}\n\n[제공 맥락]\n{context}\n\n[후보 출력]\n{candidate}\n\n위 체크리스트로 이슈를 아래 JSON 스키마로 출력."

## 출력 스키마 (JSON)
```
{ "issues": [ { "severity": "critical|major|minor", "type": "omission|contradiction|unsupported|mismatch", "where": "출력 내 위치/인용", "detail": "무엇이 왜" } ], "verdict": "ok|revise" }
```

## 배선
- 1차 출력 직후 **병렬 리뷰 콜**(적합성과 동시 가능). 1차와 다른/동급 모델 가능.
- critical 있으면 메타가 regenerate 트리거. major/minor는 정책에 따라 로깅 후 통과.
- 비용: 출력·맥락이 길면 토큰↑ — 맥락은 검증에 필요한 부분만 전달.
```

- [ ] **Step 2:** `skills/advisor-fit/SKILL.md`:
```markdown
---
name: advisor-fit
description: 런타임 LLM 출력이 "소비자 계약"(형식/스키마/길이/스타일/금지사항 등)을 지키는지 검증하는 런타임 리뷰 레이어 구현 스펙. 출력을 다운스트림이 파싱·사용하기 전에 형식 적합성을 거를 때 사용.
---
# 적합성 어드바이저 (fit) — 런타임 리뷰 콜 구현 스펙

## 언제
출력을 **다른 코드/사용자/시스템이 소비**하며, 형식·스키마·스타일·제약이 정해진 기능.

## 렌즈 / 체크리스트
- 요구된 **형식/스키마**를 지키는가(JSON 유효성, 필수 키, 타입).
- 길이·언어·톤·금지어 등 **스타일/제약** 준수.
- 다운스트림이 **바로 파싱/사용** 가능한가(여분 텍스트·마크다운 펜스 등 오염 없음).
- 기존 출력 계약과의 **하위호환**.

## 레퍼런스 프롬프트 (언어 중립)
- system: "너는 적합성 검수자다. 후보 출력이 명시된 출력 계약(형식/스키마/스타일/제약)을 지키는지만 본다. 내용 정확성은 보지 않는다."
- user: "[출력 계약]\n{contract}\n\n[후보 출력]\n{candidate}\n\n위반을 아래 JSON 스키마로."

> 가능하면 **결정론적 검증 우선**(JSON 스키마 validator, 정규식). LLM 리뷰는 결정론으로 못 잡는 스타일/모호 제약에만.

## 출력 스키마 (JSON)
```
{ "issues": [ { "severity": "critical|major|minor", "type": "schema|format|style|constraint|compat", "where": "...", "detail": "..." } ], "verdict": "ok|revise" }
```

## 배선
- 정합성과 **병렬**. 단, 스키마/형식은 **코드 validator를 먼저** 돌리고 실패 시에만 리뷰 콜(비용 절약).
- critical(스키마 깨짐)은 즉시 regenerate 또는 폴백.
```

- [ ] **Step 3:** `skills/advisor-nonfunctional/SKILL.md`:
```markdown
---
name: advisor-nonfunctional
description: 런타임에 LLM/외부 서비스를 호출하는 코드가 갖춰야 할 비기능 요건(timeout/retry/None가드/에러형식/비용상한/관측/HITL) 구현 체크리스트. LLM 호출 기능을 구현·리뷰할 때 항상 적용.
---
# 비기능 어드바이저 (nonfunctional) — 구현 체크리스트

> 이건 런타임 리뷰 콜이 아니라 **호출 코드가 반드시 갖춰야 할 요건 목록**이다. 모든 런타임 LLM 기능에 항상 적용. 결정론적이라 LLM 콜 불필요 — 정적 점검·테스트로 검증.

## 체크리스트 (severity 기본값)
- **외부 호출 timeout** — 없으면 무한 대기. (critical)
- **retry 정책** — 일시 실패/레이트리밋 대비 지수 백오프. (major)
- **빈/실패 응답 None 가드** — 실제 SDK는 빈 결과에 None 반환 가능 → `x or {}` 가드로 AttributeError 방지. (major)
- **에러 응답 형식** — 호출자가 처리할 수 있는 구조화 에러. (major)
- **비용/토큰 상한** — 입력·출력 토큰 한도, 재시도 횟수 상한. (major)
- **관측** — 요청/지연/토큰/실패율 로깅(원칙: 측정 먼저). (minor~major)
- **HITL 게이트** — 비가역·고위험 액션은 사람 승인. 컴플라이언스 접점이면 (critical), 아니면 정책에 따름.
- **민감정보** — 프롬프트/로그에 비밀·PII 노출 금지(원칙: 비밀 분리).

## 사용
구현/리뷰 시 위 항목을 점검. 누락 항목은 severity대로 처리(critical은 머지/배포 차단).
```

- [ ] **Step 4:** `skills/advisor-meta/SKILL.md`:
```markdown
---
name: advisor-meta
description: 런타임 검증에서 정합성·적합성 리뷰어들의 출력을 집계해 구조적 건강성(상충·커버리지 공백)을 점검하고 accept/regenerate/escalate를 결정하는 메타 레이어 구현 스펙. 내용 재판단은 하지 않는다.
---
# 메타 어드바이저 (meta) — 집계·결정 로직 구현 스펙

> **판단 재귀 회피**: 리뷰어 출력의 *구조*만 본다. "어느 리뷰어가 옳다" 같은 **내용 재판단·가중치 부여 금지**. 재귀의 종단은 사람.

## 언제
정합성·적합성 등 2개 이상 리뷰어를 쓸 때, 그 출력들을 모아 다음 행동을 정한다.

## 하는 일
- **집계**: 모든 리뷰어 이슈를 severity로 정렬·그룹핑·출처 태깅(기계적).
- **상충 감지**: 같은 지점에 상반 판정 → escalate 후보.
- **커버리지 공백**: 리스크상 필요한 차원을 아무도 안 봤나 → 누락 리뷰어 추가 권고.

## 결정 정책 (기본)
- critical 이슈 ≥1 → **regenerate**(1차 재호출, 이슈를 피드백으로). 재시도 상한 도달 시 escalate.
- 상충/공백 → **escalate**(HITL) 또는 누락 차원 보강 후 재집계.
- critical 0 + 상충 없음 → **accept**(major/minor는 로깅).

## 출력 스키마 (JSON)
```
{ "decision": "accept|regenerate|escalate", "reason": "...", "aggregated": [ { "severity": "...", "type": "...", "source": "correctness|fit", "where": "...", "detail": "..." } ], "retry_count": 0 }
```

## 배선
- 리뷰 콜들이 끝난 뒤 **순차로** 실행(병렬 아님). 보통 LLM 없이 **코드 로직**으로 충분(집계·임계). 모호 상충 판정만 선택적 LLM.
- regenerate 루프 상한(예: 2회) — 무한 루프·비용 폭주 방지.
```

- [ ] **Step 5:** 검증 + 커밋
Run: `bash scripts/test_scaffold.sh` → 여전히 `PASS=19 FAIL=0`(스킬은 scaffold에 영향 없음, 회귀 확인).
```bash
git add skills/advisor-correctness/SKILL.md skills/advisor-fit/SKILL.md skills/advisor-nonfunctional/SKILL.md skills/advisor-meta/SKILL.md
git commit -m "feat: add 4 advisor spec skills (correctness/fit/nonfunctional/meta)"
```

---

## Task 5: README + 도그푸딩 + 검증

**Files:** Modify `README.md`; re-run scaffold on this repo.

- [ ] **Step 1:** `README.md` "구성" 트리에 추가(코딩 principles 줄 아래):
```
├── advisors-index.md               # 런타임 LLM 검증 어드바이저 인덱스 (@import)
├── skills/advisor-*/SKILL.md       # 어드바이저 4종 스펙 (온디맨드)
```
그리고 "무엇을 자동화하나" 아래 또는 새 섹션 "## 런타임 LLM 검증(어드바이저)"을 추가:
```markdown
## 런타임 LLM 검증 (어드바이저)
제품이 런타임에 LLM을 호출하는 기능은 단독 콜로 끝내지 않는다. `advisors-index.md`(모든 프로젝트 CLAUDE.md에 자동 주입)가 4종 어드바이저(정합성·적합성·비기능·메타)와 리스크별 선택·조립을 안내하고, 각 `skills/advisor-*`가 구현 스펙(렌즈·레퍼런스 프롬프트·출력 스키마·배선)을 온디맨드로 제공한다. 어드바이저는 Claude Code 에이전트가 아니라 **제품 코드가 구현할 청사진**이다.
```

- [ ] **Step 2:** 이 레포에 scaffold 재실행(도그푸딩 — 관리영역에 @advisors-index.md 반영):
```bash
CLAUDE_PROJECT_DIR="$PWD" CLAUDE_PLUGIN_ROOT="$PWD" bash scripts/scaffold.sh >/dev/null 2>&1; echo "exit=$?"
grep -qxF '@advisors-index.md' CLAUDE.md && echo "index wired OK"
grep -cF '# BEGIN disciplined-coder' CLAUDE.md   # must be 1
```

- [ ] **Step 3:** 검증
Run: `bash scripts/test_scaffold.sh` → `PASS=19 FAIL=0`.
Run: `claude plugin validate ./` (있으면; non-strict 통과 기대. 없으면 JSON sanity로 대체하고 명시).

- [ ] **Step 4:** 커밋
```bash
git add README.md CLAUDE.md
git commit -m "docs: document advisor system + dogfood index wiring into this repo"
```

---

## Self-Review (작성 후)

**Spec coverage (§6):**
- §6.2 4종 + 렌즈 → Task 4 스킬 4종. ✓
- §6.3 조립(병렬 리뷰 → 메타) → 인덱스 + meta 스킬. ✓
- §6.4 리스크 선택 → 인덱스. ✓
- §6.5 산출물(인덱스 경량 + 디테일 스킬, 프롬프트/스키마/배선) → Task 2,4. ✓
- §5.2 절차 2줄 → Task 1. ✓
- §5.4 인덱스 항상 로드(planning 영향) → Task 3(@import + stdout). ✓
- agent 파일 없음(§6.1) → 스킬만 생성, agents/ 미사용. ✓

**Placeholder scan:** 모든 파일 내용 명시. TBD 없음. ✓

**이름 일관성:** 스킬명 `advisor-correctness|fit|nonfunctional|meta`가 인덱스 표·README·scaffold(해당 없음)와 일치. import 라인 `@advisors-index.md` 일관. 관리영역 4개 import 순서: principles, advisors-index, solved, unsolved. ✓

**경계:** Phase 3(이슈 생애주기 행동 지시)는 제외 — 별도 plan.
