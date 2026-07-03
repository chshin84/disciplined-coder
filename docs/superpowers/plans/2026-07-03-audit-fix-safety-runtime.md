# 자기감사 수정 1차 — 안전망·런타임 파괴 4건 구현 계획

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** 2026-07-03 자기감사(ultracode self-audit)의 확정 발견 중 안전망 2건(테스트의 python3 무폴백 의존, CI 부재)과 런타임 파괴 4건(_managed_block 2회차 파괴, scaffold 위생 루프 중단, spec 게이트 커밋 우회, codex stderr 폐기)을 TDD로 수정하고, 감사 워크플로를 레포에 영구화한다.

**Architecture:** 순서가 곧 의존성이다 — Task 1(python3 폴백)이 이 머신의 테스트 실행 능력을 복구해야 이후 모든 Task의 TDD 검증이 성립하고, Task 2(CI)가 이후 수정들의 회귀 안전망이 된다. 런타임 수정 4건(Task 3~6)은 각각 실패하는 테스트를 먼저 추가한 뒤 최소 수정한다. SSOT 손복제 해소(공유 헬퍼 추출)는 이 계획의 범위가 아니다 — 별도 2차 계획에서 다루므로, 여기서는 중복된 두 사본(scaffold.sh·codex-scaffold.sh)을 동일하게 최소 패치한다(`SURGICAL`).

**Tech Stack:** 순수 bash(셔뱅 `#!/usr/bin/env bash`), 기존 테스트 하니스(`check()` + FAIL=0 계약), GitHub Actions(ubuntu-latest), Workflow 스크립트(플레인 JS, ES module).

**전제 지식(레포 관례):**
- 테스트 계약은 항상 **FAIL=0**이다. 기대 개수(PASS=K)를 하드코딩하지 않는다 — 개수는 테스트가 센다.
- 커밋 메시지는 한국어 conventional commit(`fix(scope): …`)이고, 본문 끝에 다음 트레일러를 붙인다:
  ```
  Co-Authored-By: Claude Fable 5 <noreply@anthropic.com>
  Claude-Session: https://claude.ai/code/session_01GHD9UvKFd3nLLTiryd1m77
  ```
- 이 머신은 Windows이며 bash 스크립트는 Git Bash로 실행한다. `python3`는 Windows Store 스텁이라 실행되지 않는다(이것이 Task 1의 존재 이유다).
- 모든 Task 완료 후의 전체 검증 명령은 레포 CLAUDE.md가 정의한다: `bash scripts/test_scaffold.sh` + `bash scripts/test_hooks.sh` + `bash scripts/test_codex_scaffold.sh`(각 FAIL=0) + `claude plugin validate ./`.

---

## 파일 구조

| 파일 | 역할 | 이 계획에서 |
|---|---|---|
| `scripts/test_codex_scaffold.sh` | codex-scaffold 계약 테스트 | 수정 — JSON 검사기 폴백(Task 1), 하위 디렉터리 위생 케이스(Task 4), stderr 중계 테스트(Task 6) |
| `.github/workflows/ci.yml` | CI 계약 게이트 | 신규 생성(Task 2) |
| `scripts/_managed_block.sh` | 관리블록 멱등 주입 공유 헬퍼 | 수정 — 고아 BEGIN 무해화(Task 3) |
| `scripts/test_scaffold.sh` | scaffold 계약 테스트 | 수정 — 케이스 7b·케이스 10 확장(Task 3, 4) |
| `scripts/scaffold.sh` | Claude PC 셋업 | 수정 — 위생 루프 디렉터리 가드(Task 4) |
| `scripts/codex-scaffold.sh` | Codex PC 셋업(쌍둥이) | 수정 — 동일 가드(Task 4) |
| `hooks/spec_review_stop.sh` | spec/plan 하드 게이트 | 수정 — HEAD 커밋 검사(Task 5) |
| `scripts/test_hooks.sh` | 훅 계약 테스트 | 수정 — 커밋 우회 케이스 추가(Task 5) |
| `hooks/session-start-codex` | Codex 세션 훅 | 수정 — stderr 중계·실패 원인 표면화(Task 6) |
| `.claude/workflows/self-audit.js` | 자기감사 워크플로 정본 | 신규 생성(Task 7) |

---

### Task 1: test_codex_scaffold.sh의 JSON 검사기 폴백 (python3 → python → node)

배경: 이 머신의 `python3`는 Windows Store 스텁 앨리어스라서 `command -v python3`는 성공하지만 실행하면 설치 안내만 출력하고 exit 49로 죽는다. 그래서 JSON 유효성 체크 3건이 저장소 결함이 아닌데도 FAIL이 난다. 검사기 프로브는 **존재 확인이 아니라 실제 실행**이어야 한다.

**Files:**
- Modify: `scripts/test_codex_scaffold.sh:8` (run 헬퍼 아래에 헬퍼 추가), `scripts/test_codex_scaffold.sh:72-74` (검사 3건 교체)

- [ ] **Step 1: 현재 실패를 확인한다(이것이 이 Task의 failing test다)**

Run: `bash scripts/test_codex_scaffold.sh; echo "exit=$?"`
Expected: `FAIL=3`, exit=1. 실패 3건은 모두 "valid JSON" 체크다. (PASS 총수는 기대치로 박지 않는다 — 개수는 테스트가 센다.)

- [ ] **Step 2: 폴백 검사기 헬퍼를 추가한다**

`scripts/test_codex_scaffold.sh`의 8행(`run() { ... }`) 바로 아래에 추가한다:

```bash
# JSON 유효성 검사기 — stdin의 JSON을 파싱한다. python3가 존재해도 실행 불능인 머신
# (Windows Store 스텁 등)이 있으므로 프로브는 존재 확인이 아니라 실제 실행으로 한다.
# 폴백 체인: python3 → python → node. 셋 다 없으면 FAIL(조용한 SKIP 금지 — FAIL-LOUD).
json_valid_stdin() {
  if python3 -c 'import sys' >/dev/null 2>&1; then
    python3 -c 'import json,sys; json.load(sys.stdin)'
  elif python -c 'import sys' >/dev/null 2>&1; then
    python -c 'import json,sys; json.load(sys.stdin)'
  elif command -v node >/dev/null 2>&1; then
    node -e 'let d="";process.stdin.on("data",c=>d+=c).on("end",()=>{JSON.parse(d)})'
  else
    echo "  (json_valid_stdin: python3/python/node 모두 없음 — 검증 불능은 FAIL로 계상)" >&2
    return 1
  fi
}
```

- [ ] **Step 3: 검사 3건을 헬퍼 사용으로 교체한다**

72~74행의 세 check를 다음으로 바꾼다(assert 내용은 동일 — 실행기만 교체):

```bash
check "session-start-codex stdout is valid JSON" "CODEX_HOME_DIR=\"$(mktemp -d)/.codex\" CLAUDE_PLUGIN_ROOT=\"$HERE\" bash '$SS' | json_valid_stdin"
check ".codex-plugin manifest is valid JSON" "json_valid_stdin < '$HERE/.codex-plugin/plugin.json'"
check "hooks-codex.json is valid JSON"       "json_valid_stdin < '$HERE/hooks/hooks-codex.json'"
```

- [ ] **Step 4: 통과를 확인한다**

Run: `bash scripts/test_codex_scaffold.sh; echo "exit=$?"`
Expected: `FAIL=0`, exit=0 (이 머신에서는 node 폴백 경로로 통과한다).

- [ ] **Step 5: 다른 곳에 python3 의존이 더 없는지 확인한다**

Run: `grep -rn "python" scripts/ hooks/ --include='*.sh' --include='session-start-codex'`
Expected: 매치가 전부 `scripts/test_codex_scaffold.sh`의 json_valid_stdin 헬퍼 정의 블록(프로브·폴백 주석 포함) 안에 있다. 그 밖의 파일·위치에 python 호출이 있으면 같은 방식으로 교체하고 이 Task에 포함한다.

- [ ] **Step 6: 커밋한다**

```bash
git add scripts/test_codex_scaffold.sh
git commit -m "fix(test): JSON 검사기에 python3→python→node 폴백을 둔다

python3가 Windows Store 스텁인 머신에서 저장소 결함이 아닌 FAIL=3이
나던 문제를 고친다. 프로브는 존재 확인이 아니라 실제 실행으로 한다.

Co-Authored-By: Claude Fable 5 <noreply@anthropic.com>
Claude-Session: https://claude.ai/code/session_01GHD9UvKFd3nLLTiryd1m77"
```

---

### Task 2: CI 도입 — 계약(FAIL=0)을 구조로 강제한다

배경: 테스트 실행이 레포 CLAUDE.md의 "변경 후 실행하라"는 수동 관례에만 묶여 있다. 이는 플러그인 자신이 배포하는 원칙("기억해서 갱신은 깨지는 방식")의 자기위반이다. push/PR마다 계약을 돌리는 GitHub Actions를 둔다.

**Files:**
- Create: `.github/workflows/ci.yml`

- [ ] **Step 1: 워크플로 파일을 작성한다**

```yaml
name: ci
on:
  push:
    branches: [main]
  pull_request:

jobs:
  contracts:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v4
      - name: scaffold 계약 (FAIL=0)
        run: bash scripts/test_scaffold.sh
      - name: hooks 계약 (FAIL=0)
        run: bash scripts/test_hooks.sh
      - name: codex scaffold 계약 (FAIL=0)
        run: bash scripts/test_codex_scaffold.sh

  plugin-validate:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v4
      - uses: actions/setup-node@v4
        with:
          node-version: 22
      - name: Claude Code CLI 설치
        run: npm install -g @anthropic-ai/claude-code
      - name: plugin validate
        run: claude plugin validate ./
```

- [ ] **Step 2: 커밋하고 push한다**

```bash
git add .github/workflows/ci.yml
git commit -m "ci: 계약 테스트 3종 + plugin validate를 push/PR 게이트로 건다

FAIL=0 계약이 수동 관례가 아니라 구조로 강제되게 한다(FAIL-LOUD).

Co-Authored-By: Claude Fable 5 <noreply@anthropic.com>
Claude-Session: https://claude.ai/code/session_01GHD9UvKFd3nLLTiryd1m77"
git push
```

- [ ] **Step 3: 실제 실행을 관찰한다(로컬 검증 불가 — 실행이 곧 테스트다)**

Run: `gh run watch --exit-status` (또는 `gh run list --limit 1` 후 `gh run watch <id> --exit-status`)
Expected: `contracts` job 성공. `plugin-validate` job은 **알려진 불확실성**이 있다 — `claude plugin validate`가 CI 환경에서 인증을 요구하며 실패할 가능성이 있다. 실패하면 로그를 확인하고: 인증 요구가 원인이면 그 사실을 사용자에게 surface하고 결정을 받는다(job 제거 또는 대안 — 조용히 continue-on-error로 덮지 않는다, `FAIL-LOUD`). 원인이 다른 것이면 그에 맞게 고친다.

---

### Task 3: _managed_block.sh — 고아 BEGIN 파일의 2회차 실행 파괴를 막는다

배경(버그 메커니즘): BEGIN만 있고 END가 없는 파일에서 1회차 실행은 "비파괴 스킵"을 하고 완전한 블록(BEGIN..END)을 말미에 append한다. 그 결과 파일에는 고아 BEGIN과 새 END가 공존하고, **2회차 실행의 strip awk가 첫 BEGIN(고아)부터 마지막 END까지 — 사용자 내용 포함 — 를 삭제한다**. 1회차가 다음 실행의 파괴를 준비하는 구조다(`IDEMPOTENT` 위반, 자기감사 재현 완료). 수정: 1회차에 고아 BEGIN 마커를 무해화(주석화)해 이후 실행이 오인 strip할 수 없게 만든다.

**Files:**
- Test: `scripts/test_scaffold.sh` (케이스 7 뒤에 7b 추가)
- Modify: `scripts/_managed_block.sh:15-17` (elif 분기)

- [ ] **Step 1: 실패하는 테스트를 추가한다**

`scripts/test_scaffold.sh`의 케이스 7 블록(74행 `check "malformed: complete region appended"` …) 바로 뒤에 추가한다:

```bash
# --- 케이스 7b: 깨진 관리영역 2회차 실행 — 1회차가 다음 실행의 파괴를 준비하면 안 된다 ---
ERR7b="$(run "$H7" "$P7" 2>&1 >/dev/null)" || true
echo "[case7b] malformed region 2nd run → still non-destructive"
check "2nd run: user content preserved"    "grep -qxF 'IMPORTANT user content after malformed begin' '$UC7'"
check "2nd run: pre-region note preserved" "grep -qxF 'note before' '$UC7'"
check "2nd run: single managed region"     "[ \$(grep -cF '# BEGIN disciplined-coder' '$UC7') -eq 1 ]"
```

- [ ] **Step 2: 실패를 확인한다**

Run: `bash scripts/test_scaffold.sh; echo "exit=$?"`
Expected: 케이스 7b의 "2nd run: user content preserved"가 FAIL(2회차 strip이 사용자 내용을 삭제하므로), exit=1.

- [ ] **Step 3: 고아 BEGIN 무해화를 구현한다**

`scripts/_managed_block.sh`의 elif 분기(15~17행)를 다음으로 교체한다:

```bash
  elif grep -qF "$begin" "$uc"; then
    # 고아 BEGIN(END 없음)을 그대로 두면 다음 실행의 strip이 고아 BEGIN~새 END 사이의
    # 사용자 내용을 오인 삭제한다(IDEMPOTENT 위반). 마커 줄을 무해화해 재실행을 안전하게 한다.
    echo "[disciplined-coder] WARNING: $uc has BEGIN but no END — neutralizing orphan BEGIN (non-destructive)" >&2
    awk -v b="$begin" '{ l=$0; sub(/\r$/,"",l); if (l==b) print "# (disciplined-coder: orphan BEGIN neutralized — END missing)"; else print }' "$uc" > "$uc.tmp"
```

주의: 파일 머리 주석 5행("BEGIN만 있고 END 없음 = WARN + strip 생략(비파괴)")도 새 동작에 맞게 고친다 — "BEGIN만 있고 END 없음 = WARN + 고아 마커 무해화(비파괴·재실행 안전)".

알려진 한계(리뷰 근거로 수용): 사용자가 마커와 **완전히 동일한 한 줄**을 자기 콘텐츠로 직접 써두고 END가 없는 경우, 그 줄이 무해화 주석으로 재작성된다 — 2회차 전체 파괴 위험을 1회차 한 줄 변형으로 맞바꾸는 것이며, 마커 문자열이 특이해 발생 확률은 낮다. 부분 인용(마커가 줄의 일부)은 `l==b` 전체 줄 일치라 변형되지 않는다(경고만 발생). CRLF 파일에 LF 주석 줄이 섞일 수 있는 것도 기존 append 동작과 동일한 수위의 한계다.

- [ ] **Step 4: 통과를 확인한다**

Run: `bash scripts/test_scaffold.sh; echo "exit=$?"`
Expected: FAIL=0, exit=0. 기존 케이스 7의 "warns BEGIN without END" 체크는 새 경고 문구에도 그대로 매치된다(문구에 'BEGIN but no END' 유지).

Run: `bash scripts/test_codex_scaffold.sh`
Expected: FAIL=0 (같은 헬퍼를 쓰는 codex 경로 회귀 확인).

- [ ] **Step 5: 커밋한다**

```bash
git add scripts/_managed_block.sh scripts/test_scaffold.sh
git commit -m "fix(managed-block): 고아 BEGIN을 무해화해 2회차 사용자 내용 파괴를 막는다

BEGIN만 있고 END 없는 파일에서 1회차 append 후 2회차 strip이 고아
BEGIN~새 END 사이 사용자 내용을 삭제하던 버그(IDEMPOTENT 위반)를,
1회차에 고아 마커를 주석으로 무해화하는 방식으로 고친다.

Co-Authored-By: Claude Fable 5 <noreply@anthropic.com>
Claude-Session: https://claude.ai/code/session_01GHD9UvKFd3nLLTiryd1m77"
```

---

### Task 4: scaffold 위생 루프 — 하위 디렉터리에서 중단되지 않게 한다

배경: `for f in "$KDIR"/*` 루프가 디렉터리를 명시 처리하지 않는다. Git Bash에서 빈 디렉터리는 `[ -s ]`가 거짓이라 `rm -f <dir>`로 흘러가 실패하고, `set -e`로 **스크립트 전체가 중단돼 관리블록 재생성과 원칙 주입이 매 세션 조용히 누락**된다(자기감사 재현 완료). Linux에서는 우연히 note 분기로 살아남지만 그마저 '비관리 파일'이라는 틀린 메시지다. 디렉터리를 명시 분기한다(`EXPLICIT`·`FAIL-LOUD`). 두 사본(scaffold.sh·codex-scaffold.sh)을 동일하게 패치한다 — 공유 헬퍼 추출은 2차 계획(SSOT 묶음)의 몫이다.

**Files:**
- Test: `scripts/test_scaffold.sh` (케이스 10 확장), `scripts/test_codex_scaffold.sh` (케이스 추가)
- Modify: `scripts/scaffold.sh:36-46`, `scripts/codex-scaffold.sh:31-41`

- [ ] **Step 1: 실패하는 테스트를 추가한다 — test_scaffold.sh 케이스 10**

케이스 10에서 `: > "$K10/orphan_empty.md"`(101행) 바로 아래에 픽스처를 추가하고:

```bash
mkdir -p "$K10/rogue_dir"                                  # 하위 디렉터리 → 중단 없이 surface
```

ERR10 캡처(102행)를 exit code도 잡도록 교체한다:

```bash
set +e
ERR10="$(run "$H10" "$P10" 2>&1 >/dev/null)"; rc10=$?
set -e
```

기존 체크들 뒤에 추가한다:

```bash
check "subdir does not abort scaffold"  "[ $rc10 -eq 0 ]"
check "subdir surfaced to stderr"       "printf '%s' \"\$ERR10\" | grep -qF 'rogue_dir'"
check "subdir preserved"                "[ -d '$K10/rogue_dir' ]"
```

- [ ] **Step 2: codex 쪽에도 실패하는 테스트를 추가한다 — test_codex_scaffold.sh**

케이스 7 블록 끝(66행) 뒤, `echo "[manifest + session hook]"` 앞에 추가한다:

```bash
# --- 케이스 8: 관리 디렉터리 위생 — 하위 디렉터리에서 중단되지 않는다 ---
mkdir -p "$K/rogue_dir"
set +e
ERR8c="$(run "$H1" 2>&1 >/dev/null)"; rc8c=$?
set -e
echo "[case8] hygiene: subdir must not abort"
check "subdir does not abort codex scaffold" "[ $rc8c -eq 0 ]"
check "subdir surfaced to stderr"            "printf '%s' \"\$ERR8c\" | grep -qF 'rogue_dir'"
```

- [ ] **Step 3: 실패를 확인한다(Git Bash 기준)**

Run: `bash scripts/test_scaffold.sh; bash scripts/test_codex_scaffold.sh`
Expected: 이 머신(Git Bash)에서 "subdir does not abort" 또는 "subdir surfaced"가 FAIL. (Linux에서는 `[ -s dir ]`이 참이라 abort 없이 살아남을 수 있다 — 그래도 메시지는 '비관리 파일'로 틀리며, Step 4의 명시 분기가 플랫폼 무관하게 행동을 확정한다. **red 확인은 반드시 이 머신(Git Bash)에서 한다** — CI(Linux)에서는 수정 전에도 green일 수 있다.)

- [ ] **Step 4: 디렉터리 명시 분기를 구현한다 — 두 사본 동일 패치**

`scripts/scaffold.sh`의 위생 루프에서 `[ "$keep" = 1 ] && continue`(40행) 바로 아래에 추가한다:

```bash
  if [ -d "$f" ]; then
    echo "[disciplined-coder] note: 비관리 디렉터리 '$b' 잔존(자동삭제 안 함, 확인 요)" >&2
    continue
  fi
```

`scripts/codex-scaffold.sh`의 동일 루프(35행 `[ "$keep" = 1 ] && continue` 아래)에도 똑같이 추가한다.

또한 두 파일 모두에서, 같은 루프의 빈 고아 제거 줄 `rm -f "$f"`를 다음으로 교체한다 — 삭제 불가한 빈 파일(읽기 전용·열린 핸들 등)이 남은 잔여 중단 경로를 닫는다. 오류를 조용히 삼키는 것이 아니라 경고를 내되 scaffold 전체를 죽이지 않는 것이다(주입 누락이 더 큰 조용한 실패다):

```bash
    rm -f "$f" || echo "[disciplined-coder] WARNING: 빈 고아 '$b' 삭제 실패(권한·잠금?) — 계속 진행" >&2
```

(삭제 불가 파일은 플랫폼 의존적이라 이식 가능한 테스트를 만들기 어렵다 — 이 교체는 테스트 없이 리뷰 근거(adversarial 렌즈 major)로 들어간다.)

- [ ] **Step 5: 통과를 확인한다**

Run: `bash scripts/test_scaffold.sh && bash scripts/test_codex_scaffold.sh`
Expected: 둘 다 FAIL=0.

- [ ] **Step 6: 커밋한다**

```bash
git add scripts/scaffold.sh scripts/codex-scaffold.sh scripts/test_scaffold.sh scripts/test_codex_scaffold.sh
git commit -m "fix(scaffold): 위생 루프가 하위 디렉터리에서 중단되지 않게 명시 분기한다

Git Bash에서 빈 디렉터리가 rm -f 실패 + set -e로 scaffold 전체를
중단시켜 디시플린 주입이 매 세션 조용히 누락되던 버그(FAIL-LOUD 위반)를
고친다. 디렉터리는 삭제하지 않고 stderr로 surface한다.

Co-Authored-By: Claude Fable 5 <noreply@anthropic.com>
Claude-Session: https://claude.ai/code/session_01GHD9UvKFd3nLLTiryd1m77"
```

---

### Task 5: spec_review_stop.sh — 같은 턴 커밋으로 게이트가 열리는 구멍을 막는다

배경: 현재 탐지는 `git status --porcelain`의 신규(`??`·`A`)만 본다. 미리뷰 spec을 **같은 턴에 커밋해 버리면 working tree가 깨끗해져 하드 게이트가 조용히 열린다** — superpowers 기본 절차가 커밋을 포함하므로 happy path에서 발생한다. 수정: **HEAD 커밋이 추가(diff-filter=A)한 spec/plan도 검사**한다. 경계를 직전 커밋 하나로 두는 이유: 이 레포에는 훅 도입 전의 무마커 레거시 spec/plan이 8건 있고(2026-07-03 실측), 추적 파일 전수 검사는 이런 레포에서 상시 오차단을 만들어 사용자가 게이트를 영구히 꺼버리는 더 나쁜 드리프트를 낳는다. 다중 커밋으로 묻는 우회는 알려진 한계로 남는다(기존 '마커만 달면 못 막는다' 한계와 동급 — domain-spec-review SKILL.md가 이미 인정하는 수위). **루트 커밋(부모 없는 최초 커밋)이 추가한 spec도 의도적으로 미검출이다** — `--root`를 켜면 기존 문서를 통째로 들여오는 초기 커밋(레거시 임포트)이 있는 레포에서 상시 오차단이 나기 때문에, 레거시 보호와 같은 근거로 제외한다. **머지 커밋도 미검출이다**(diff-tree는 `-m` 없이 머지에서 빈 출력 — 머지로 들여온 spec은 원 브랜치에서 이미 게이트를 통과했거나 레거시 임포트이므로 같은 근거로 수용). 중복 가드는 공백-substring이 아니라 완전 일치 루프로 한다(-z 설계 의도와 일관 — 다만 `unreviewed`의 공백 조인 누적 자체는 기존 코드의 한계를 그대로 유지한다, `SURGICAL`).

**Files:**
- Test: `scripts/test_hooks.sh` (stop 섹션에 케이스 추가)
- Modify: `hooks/spec_review_stop.sh:16-30` (두 번째 스캔 루프 추가), 3행 머리 주석 갱신

- [ ] **Step 1: 실패하는 테스트를 추가한다**

`scripts/test_hooks.sh`의 stop 섹션 끝(93행 `check "수정+신규 미리뷰 동시 → 신규로 차단(Fix A)"` 뒤)에 추가한다:

```bash
# Fix C: 같은 턴 '커밋'으로 하드게이트가 조용히 열리면 안 된다 — HEAD가 추가한 spec도 검사.
G3="$(mktemp -d)"; ( cd "$G3" && git init -q && git config user.email t@t && git config user.name t )
mkdir -p "$G3/docs/superpowers/specs"
printf 'seed\n' > "$G3/README.md"
( cd "$G3" && git add -A && git commit -qm seed )
printf 'draft committed\n' > "$G3/docs/superpowers/specs/sneaky.md"
( cd "$G3" && git add -A && git commit -qm 'add spec' )
check "커밋된 미리뷰 spec(HEAD) → block(Fix C)"   "stop '{\"cwd\":\"$G3\"}' | grep -q '\"block\"'"
printf 'draft committed\n<!-- spec-review: passed -->\n' > "$G3/docs/superpowers/specs/sneaky.md"
check "HEAD spec에 마커 추가 후 → 통과(Fix C)"    "[ -z \"\$(stop '{\"cwd\":\"$G3\"}')\" ]"
( cd "$G3" && git add -A && git commit -qm 'mark reviewed' )
check "마커 커밋 후(HEAD=수정 커밋) → 통과(Fix C)" "[ -z \"\$(stop '{\"cwd\":\"$G3\"}')\" ]"
```

주의(테스트 설계): 두 번째 체크는 "파일이 HEAD에서 추가됐어도 **현재 파일 내용**이 terminal이면 통과"를 검증한다 — 게이트의 목적은 리뷰 완료이지 커밋 이력 처벌이 아니기 때문이다. 마커 검사는 working tree의 파일을 읽으므로 이 동작이 자연스럽게 성립해야 한다.

- [ ] **Step 2: 실패를 확인한다**

Run: `bash scripts/test_hooks.sh; echo "exit=$?"`
Expected: "커밋된 미리뷰 spec(HEAD) → block(Fix C)"가 FAIL(현재 코드는 working tree만 봐서 빈 출력), exit=1. 나머지 두 체크는 현재 코드로도 통과한다(빈 출력이므로) — 회귀 방지용이다.

- [ ] **Step 3: HEAD 스캔 루프를 추가한다**

`hooks/spec_review_stop.sh`의 첫 while 루프(30행 `done < <(git status ...)`) 바로 아래에 추가한다:

```bash
# Fix C: 같은 턴 커밋 우회 차단 — HEAD 커밋이 추가(A)한 spec/plan도 검사한다.
# 경계는 직전 커밋 하나: 과거 이력을 소급 차단하지 않는다(훅 도입 전 무마커 레거시가 있는
# 레포에서 상시 차단 → 게이트 영구 off라는 더 나쁜 드리프트를 피한다). 다중 커밋 우회는
# 알려진 한계(마커 존재만 검사하는 기존 한계와 동급).
while IFS= read -r -d '' f; do
  [ -n "$f" ] || continue
  case "$f" in
    *docs/superpowers/specs/*.md|*docs/superpowers/plans/*.md) ;;
    *) continue ;;
  esac
  [ -f "$f" ] || continue
  dup=0; for u in $unreviewed; do [ "$u" = "$f" ] && { dup=1; break; }; done
  [ "$dup" = 1 ] && continue
  marker_is_terminal "$f" || unreviewed="$unreviewed $f"
done < <(git diff-tree -z --no-commit-id --name-only --diff-filter=A -r HEAD 2>/dev/null || true)
```

3행 머리 주석도 갱신한다: `# 탐지: git 신규(미추적·추가) spec/plan + HEAD 커밋이 추가한 spec/plan 중 마지막 줄이 terminal 마커가 아닌 것. 기존 파일 수정은 제외(Fix A).`

- [ ] **Step 4: 통과를 확인한다**

Run: `bash scripts/test_hooks.sh; echo "exit=$?"`
Expected: FAIL=0, exit=0 (기존 stop 케이스 — FAIL-OPEN, 리네임, Fix A/B — 전부 포함).

- [ ] **Step 5: 커밋한다**

주의: 이 커밋 자체가 이 계획 문서(plans/*.md)를 포함하면 안 된다 — 훅 파일만 커밋한다. (이 계획 문서는 리뷰 마커가 달린 뒤 별도로 커밋된다. Fix C가 배포되면 HEAD에 마커 없는 plan이 포함된 커밋은 스스로 차단된다 — 자기 규칙의 첫 적용 대상이 자기 자신이다.)

```bash
git add hooks/spec_review_stop.sh scripts/test_hooks.sh
git commit -m "fix(gate): 같은 턴 커밋으로 spec 하드게이트가 열리던 우회를 막는다

working tree만 보던 탐지에 HEAD 커밋이 추가한 spec/plan 검사를
더한다(Fix C). 경계는 직전 커밋 하나 — 무마커 레거시 레포의 상시
오차단(게이트 영구 off 유도)을 피한다. 다중 커밋 우회는 알려진 한계.

Co-Authored-By: Claude Fable 5 <noreply@anthropic.com>
Claude-Session: https://claude.ai/code/session_01GHD9UvKFd3nLLTiryd1m77"
```

---

### Task 6: session-start-codex — scaffold 진단을 삼키지 않는다

배경: 훅이 codex-scaffold의 stderr 전체를 `/dev/null`로 버리고, 실패 시 원인 없는 고정 문자열(`[disciplined-coder] scaffold error`)로 대체한다. scaffold가 일부러 stderr로 내보내는 FAIL-LOUD 진단(정본 부재 경고, 비관리 파일 surface 등)이 Codex 런타임에서 누구에게도 도달하지 않는다. 수정: stderr를 훅 자신의 stderr로 중계하고, 실패 시 원인을 주입 컨텍스트에 포함한다(에이전트에게 확실히 도달하는 채널).

**Files:**
- Test: `scripts/test_codex_scaffold.sh` (manifest + session hook 섹션에 추가)
- Modify: `hooks/session-start-codex:7`

- [ ] **Step 1: 실패하는 테스트를 추가한다**

`scripts/test_codex_scaffold.sh`의 session hook 체크들(Task 1에서 교체한 "stdout is valid JSON" 체크 앞뒤 무관, 그 섹션 끝) 뒤에 추가한다:

```bash
# FAIL-LOUD: scaffold의 stderr 진단이 훅에서 삼켜지면 안 된다.
EDIR="$(mktemp -d)"   # 정본 없는 plugin root → scaffold가 WARNING을 stderr로 낸다
check "session hook relays scaffold stderr" "CODEX_HOME_DIR=\"$(mktemp -d)/.codex\" CLAUDE_PLUGIN_ROOT=\"$EDIR\" bash '$SS' 2>&1 >/dev/null | grep -qF 'WARNING'"
# 실패 시 원인 문자열이 주입 컨텍스트에 포함되고, 출력은 여전히 유효한 JSON이어야 한다.
TF="$(mktemp)"        # 파일 아래 경로 → mkdir -p 실패 → scaffold 비정상 종료
OUTF="$(CODEX_HOME_DIR="$TF/.codex" CLAUDE_PLUGIN_ROOT="$HERE" bash "$SS")"
check "session hook surfaces failure cause"    "printf '%s' \"\$OUTF\" | grep -qF 'scaffold error:'"
check "failure output is still valid JSON"     "printf '%s' \"\$OUTF\" | json_valid_stdin"
```

- [ ] **Step 2: 실패를 확인한다**

Run: `bash scripts/test_codex_scaffold.sh; echo "exit=$?"`
Expected: "relays scaffold stderr"와 "surfaces failure cause"가 FAIL(현재 코드는 2>/dev/null + 원인 없는 고정 문자열), exit=1.

- [ ] **Step 3: stderr 중계와 원인 표면화를 구현한다**

`hooks/session-start-codex`의 7행을 다음 블록으로 교체한다:

```bash
# scaffold 진단(stderr)은 삼키지 않는다(FAIL-LOUD): 훅 자신의 stderr로 중계하고,
# 실패 시엔 원인 문자열을 주입 컨텍스트에 포함해 에이전트에게도 도달시킨다.
errfile="$(mktemp)"
if principles="$(CLAUDE_PLUGIN_ROOT="$PLUGIN_ROOT" bash "$DIR/../scripts/codex-scaffold.sh" 2>"$errfile")"; then
  :
else
  principles="[disciplined-coder] scaffold error: $(cat "$errfile")"
fi
if [ -s "$errfile" ]; then cat "$errfile" >&2; fi
rm -f "$errfile"
```

주의: `[ -s "$errfile" ] && cat ...` 단축형을 쓰면 errfile이 비었을 때 반환값 1이 `set -e`에 걸려 훅이 죽는다 — 반드시 `if` 문으로 쓴다.

- [ ] **Step 4: 통과를 확인한다**

Run: `bash scripts/test_codex_scaffold.sh; echo "exit=$?"`
Expected: FAIL=0, exit=0.

- [ ] **Step 5: 커밋한다**

```bash
git add hooks/session-start-codex scripts/test_codex_scaffold.sh
git commit -m "fix(codex-hook): scaffold stderr를 중계하고 실패 원인을 컨텍스트로 표면화한다

2>/dev/null로 FAIL-LOUD 진단 채널이 통째로 사라지고 실패가 원인 없는
고정 문자열이 되던 문제를 고친다. stderr는 훅 stderr로 중계하고,
실패 원인은 주입 컨텍스트에 포함해 에이전트에게 확실히 도달시킨다.

Co-Authored-By: Claude Fable 5 <noreply@anthropic.com>
Claude-Session: https://claude.ai/code/session_01GHD9UvKFd3nLLTiryd1m77"
```

---

### Task 7: 자기감사 워크플로를 레포에 영구화한다

배경: 2026-07-03 자기감사에 쓴 워크플로 스크립트는 세션 디렉터리에만 있어 세션 종료 후 재사용할 수 없다. `.claude/workflows/`에 정본을 두면 이후 큰 변경 뒤 회귀 감사로 재실행할 수 있다. 이번 감사의 커버리지 공백(집계 4절)을 **기존 렌즈의 범위 확대**로 반영한다: issue-mode.sh·add-pointer.sh를 셸 감사에 포함, reviewer-*·meta-aggregate SKILL.md를 문체·일관성 감사 대상에 포함. SECRETS 상시 렌즈는 신설하지 않는다 — 이 레포는 문서·순수 bash 구성이라 거의 확실히 빈 결과에 매 감사 1콜을 지불하는 저수익 확장이다(YAGNI, adversarial 렌즈 리뷰 반영).

**Files:**
- Create: `.claude/workflows/self-audit.js`

- [ ] **Step 1: 워크플로 정본을 작성한다**

```javascript
export const meta = {
  name: 'self-audit',
  description: 'disciplined-coder 저장소를 자기 원칙·자기 리뷰어 렌즈로 자기검증한다',
  whenToUse: '큰 변경(정본·훅·스캐폴드 수정) 후 회귀 감사가 필요할 때, 레포 루트에서 실행한다(다른 위치면 args로 레포 경로를 넘긴다). 결과는 확정 발견 목록과 집계 판정이다.',
  phases: [
    { title: '테스트', detail: '테스트 스크립트 3종 + plugin validate 실행 (FAIL=0 계약)' },
    { title: '리뷰', detail: '8개 렌즈 병렬 감사 (자기 리뷰어 스킬 3종 + 원칙 차원 5종)' },
    { title: '중복제거', detail: '렌즈 간 중복 발견 병합' },
    { title: '반박검증', detail: '발견별 사실성·실질성 2관점 반박 (불확실하면 기각)' },
    { title: '집계', detail: 'meta-aggregate 방식 구조 건강성 점검 + 최종 정리' },
  ],
}

// 레포 경로는 하드코딩하지 않는다(레포 정본은 어느 클론에서도 동작해야 한다 — EXPLICIT).
// 기본값 '.'은 "레포 루트에서 실행"을 전제하고, 다른 위치면 args로 절대 경로를 넘긴다.
const REPO = (typeof args === 'string' && args.length > 0) ? args : '.'

const FINDINGS_SCHEMA = {
  type: 'object',
  properties: {
    findings: {
      type: 'array',
      items: {
        type: 'object',
        properties: {
          title: { type: 'string', description: '발견 제목 — 완결된 문장으로 (CLEAR-COMM)' },
          file: { type: 'string', description: '증거 파일 경로 (file:line 형식 권장)' },
          evidence: { type: 'string', description: '실제 파일에서 인용한 증거 텍스트' },
          principle: { type: 'string', description: '위반/관련 원칙 ID 또는 렌즈 규칙' },
          severity: { type: 'string', enum: ['red', 'major', 'minor'], description: 'red=사용자 결정 필요(🔴), major=명백한 위반·실질 피해, minor=사소' },
          detail: { type: 'string', description: '왜 위반인지 — 근거를 완결된 문장으로 설명' },
          fix: { type: 'string', description: '제안하는 수정 방향 (선택)' },
        },
        required: ['title', 'file', 'evidence', 'principle', 'severity', 'detail'],
      },
    },
  },
  required: ['findings'],
}

const VERDICT_SCHEMA = {
  type: 'object',
  properties: {
    isReal: { type: 'boolean', description: '반박에 실패했으면(=발견이 실재하면) true. 불확실하면 false.' },
    reason: { type: 'string', description: '판정 근거 한두 문장' },
  },
  required: ['isReal', 'reason'],
}

const TEST_SCHEMA = {
  type: 'object',
  properties: {
    allPassed: { type: 'boolean' },
    results: {
      type: 'array',
      items: {
        type: 'object',
        properties: {
          name: { type: 'string' },
          passed: { type: 'boolean' },
          summary: { type: 'string', description: 'PASS/FAIL 카운트와 실패 시 실패 내용' },
        },
        required: ['name', 'passed', 'summary'],
      },
    },
  },
  required: ['allPassed', 'results'],
}

const COMMON = `너는 disciplined-coder 플러그인 저장소(${REPO})를 감사하는 읽기 전용 리뷰어다.
이 저장소는 그 플러그인 자체의 소스다 — 플러그인이 남에게 강제하는 원칙을 자기 자신이 지키는지 검증한다.
먼저 ${REPO}/agent-principles.md (원칙 정본·규칙서)를 읽어라.
규칙: (1) 파일을 직접 읽고 실제 인용을 증거로 제시하라 — 추측 금지. (2) 어떤 파일도 수정하지 마라.
(3) solved_problems.md에 직접 쓰지 마라 — 발견은 구조화 리턴으로만 보고한다(메인 세션이 취합한다).
(4) 발견은 최대 10건 — 확신 높은 순으로. 없으면 빈 배열이 정직한 답이다.
(5) 각 발견의 title과 detail은 완결된 문장으로 쓴다.`

const REVIEWERS = [
  { key: 'lens-grounding', prompt: `${COMMON}
렌즈: ${REPO}/skills/reviewer-grounding/SKILL.md 를 읽고 그대로 적용하라. 검토 대상: README.md, CLAUDE.md, agent-principles.md, domains-index.md, commands/*.md. source(진실): scripts/*.sh, hooks/*, skills/*/SKILL.md, .claude-plugin/*. 문서가 주장하는 동작이 실제 코드에 근거하는지 — 누락·모순·환각을 찾아라.` },
  { key: 'lens-consistency', prompt: `${COMMON}
렌즈: ${REPO}/skills/reviewer-consistency/SKILL.md 를 읽고 그대로 적용하라. 검토 대상: agent-principles.md, domains-index.md, README.md, CLAUDE.md, skills/*/SKILL.md 상호간(reviewer-*·meta-aggregate 포함). 내부 모순, 커버리지 공백, 이름/참조 드리프트를 찾아라.` },
  { key: 'lens-adversarial', prompt: `${COMMON}
렌즈: ${REPO}/skills/reviewer-adversarial/SKILL.md 를 읽고 그대로 적용하라(가드 포함: 기능 추가 제안 금지·근거 필수). 검토 대상: 절차(§가~라)·hooks/·scripts/·skills/ 설계 전체. 실패 모드, 과설계·YAGNI, 비가역, 자기모순을 공격적으로 찾아라.` },
  { key: 'ssot-audit', prompt: `${COMMON}
차원: SSOT 전수 조사 — agent-principles.md ↔ skills ↔ scripts ↔ hooks ↔ README ↔ CLAUDE.md ↔ commands 사이의 권위 있는 이중 기술(손 동기화 쌍)을 찾아라. 정당한 참조/도출은 위반이 아니다.` },
  { key: 'shell-audit', prompt: `${COMMON}
차원: 셸 코드 품질 — scripts/*.sh 전부(issue-mode.sh·add-pointer.sh 포함), hooks/*.sh, hooks/*.json, hooks/session-start-codex. FAIL-LOUD(오류 삼킴), IDEMPOTENT(재실행 안전 — 코드로 추적), EXPLICIT, 테스트 매직 넘버, Git Bash 홈 리다이렉트 함정. 실제 코드 라인을 인용하라.` },
  { key: 'clear-comm-audit', prompt: `${COMMON}
차원: CLEAR-COMM 자기준수 — agent-principles.md, skills/*/SKILL.md 전부(reviewer-*·meta-aggregate 포함), commands/*.md, README.md, domains-index.md. 산문과 표에서 명사 조각 종결, 기호 문장(X = Y, 원인 → 해결)을 찾아라. 원칙 정의 안의 '나쁜 예' 인용문과 코드 블록·필드 스키마 표기는 위반이 아니다.` },
  { key: 'plugin-compliance', prompt: `${COMMON}
차원: domain-plugin 자기준수 — ${REPO}/skills/domain-plugin/SKILL.md 를 읽고, .claude-plugin/*, .codex-plugin/*, hooks/hooks*.json, commands/·skills/ frontmatter가 그 처방을 지키는지 감사하라. 스킬의 주장 자체가 실측과 다르면 그것도 발견이다(MEASURE-FIRST).` },
  { key: 'docs-compliance', prompt: `${COMMON}
차원: domain-docs 자기준수 — ${REPO}/skills/domain-docs/SKILL.md 를 읽고, docs/ 전체·README·CLAUDE.md가 타입별 처방(상태 금지·도출 우선·수명 규칙)을 지키는지 감사하라. solved_problems는 append-only 예외이고, spec/plan은 superpowers 소유라 현행 문서와의 드리프트만 본다.` },
]

phase('테스트')
const testPromise = agent(
  `${COMMON}
너만 예외적으로 실행 권한이 있다(파일 수정은 여전히 금지). ${REPO} 에서 다음을 실행하고 결과를 보고하라:
1. bash scripts/test_scaffold.sh
2. bash scripts/test_hooks.sh
3. bash scripts/test_codex_scaffold.sh
4. claude plugin validate ./ (non-strict)
각각 PASS/FAIL 카운트와, FAIL이 있으면 어떤 체크가 왜 실패했는지 출력에서 인용하라. 계약은 FAIL=0이다.
환경 원인(도구 부재 등)으로 보이는 실패는 그 사실 자체를 보고하라(수정 시도 금지).`,
  { label: 'run-tests', phase: '테스트', schema: TEST_SCHEMA }
)

phase('리뷰')
const reviews = await parallel(
  REVIEWERS.map(r => () =>
    agent(r.prompt, { label: r.key, phase: '리뷰', schema: FINDINGS_SCHEMA })
      .then(res => (res ? res.findings.map(f => ({ ...f, lens: r.key })) : []))
  )
)
const all = reviews.filter(Boolean).flat()
log(`리뷰 완료: ${REVIEWERS.length}개 렌즈에서 원시 발견 ${all.length}건`)

phase('중복제거')
let deduped = all
if (all.length > 1) {
  const dd = await agent(
    `다음은 disciplined-coder 저장소 감사에서 여러 렌즈가 낸 원시 발견 목록(JSON)이다.
같은 실체(같은 파일의 같은 문제)를 가리키는 발견들을 하나로 병합하라 — evidence는 가장 구체적인 것을 남기고, lens는 쉼표로 합치고, severity는 가장 높은 것(red>major>minor)을 취한다.
서로 다른 문제는 절대 합치지 마라. 재판단·신규 발견 추가 금지 — 순수 병합만 한다.
${JSON.stringify(all)}`,
    { label: 'dedup', phase: '중복제거', schema: FINDINGS_SCHEMA, effort: 'low' }
  )
  if (dd && dd.findings.length > 0 && dd.findings.length <= all.length) deduped = dd.findings
}
log(`중복 제거 후 ${deduped.length}건 — 반박 검증 시작`)

phase('반박검증')
const judged = await parallel(
  deduped.map((f, i) => () =>
    parallel([
      () => agent(
        `너는 회의적 검증자다. 저장소 ${REPO} 를 직접 읽고 다음 감사 발견을 사실성 관점에서 반박하라 — 인용 증거가 실제 파일에 그대로 존재하는가, 발견이 내용을 정확히 기술하는가, 못 본 반증이 있는가.
불확실하면 isReal=false. 발견: ${JSON.stringify(f)}`,
        { label: `verify-fact:${i}`, phase: '반박검증', schema: VERDICT_SCHEMA }
      ),
      () => agent(
        `너는 회의적 검증자다. 먼저 ${REPO}/agent-principles.md 를 읽어라. 다음 감사 발견을 실질성 관점에서 반박하라 — 인용 원칙(${f.principle})의 실제 정의에 비추어 진짜 위반인가, 예외 조항·정당한 설계 선택에 해당하지 않는가, 고치면 실질 이득이 있는가.
불확실하면 isReal=false. 발견: ${JSON.stringify(f)}`,
        { label: `verify-merit:${i}`, phase: '반박검증', schema: VERDICT_SCHEMA }
      ),
    ]).then(vs => {
      const ok = vs.filter(Boolean).filter(v => v.isReal).length === 2
      return { ...f, confirmed: ok, verdicts: vs.filter(Boolean).map(v => v.reason) }
    })
  )
)
const confirmed = judged.filter(Boolean).filter(j => j.confirmed)
const rejected = judged.filter(Boolean).filter(j => !j.confirmed)
log(`반박 검증 완료: 확정 ${confirmed.length}건 · 기각 ${rejected.length}건`)

const test = await testPromise

phase('집계')
const aggregate = await agent(
  `너는 집계자다. ${REPO}/skills/meta-aggregate/SKILL.md 를 읽고 그 방식대로, 아래 자기감사 결과의 구조적 건강성을 점검하라 — 확정 발견 간 상충, 커버리지 공백, 전체 판정. 발견 내용 재판단은 금지(검증 단계가 끝냈다). 출력은 완결된 문어체 한국어로: (1) 전체 판정 한 단락, (2) 확정 발견 심각도순 정리(red 먼저), (3) 상충 명시, (4) 커버리지 공백.
결정론 테스트 결과: ${JSON.stringify(test)}
확정 발견 (${confirmed.length}건): ${JSON.stringify(confirmed)}
기각 발견 제목들 (${rejected.length}건): ${JSON.stringify(rejected.map(r => ({ title: r.title, why: r.verdicts })))}`,
  { label: 'meta-aggregate', phase: '집계' }
)

return { test, confirmedCount: confirmed.length, rejectedCount: rejected.length, confirmed, rejectedTitles: rejected.map(r => r.title), aggregate }
```

- [ ] **Step 2: 문법을 검증한다**

Run: `node --input-type=module --check < .claude/workflows/self-audit.js`
Expected: 출력 없이 exit 0 (ES module 문법 유효). 이 명령 형태가 환경에서 지원되지 않으면 `node --input-type=module -e "$(cat .claude/workflows/self-audit.js | sed 's/^phase(/\/\/phase(/')"` 같은 우회 대신, 실패 원인을 확인하고 실제로 파싱을 검증할 수 있는 방법을 찾는다 — 검증 없이 커밋하지 않는다.

- [ ] **Step 3: 커밋한다**

```bash
git add .claude/workflows/self-audit.js
git commit -m "feat(audit): 자기감사 워크플로를 레포 정본으로 영구화한다

세션 한정이던 self-audit 스크립트를 .claude/workflows/에 두어 큰 변경
후 회귀 감사로 재실행할 수 있게 한다. 1차 감사의 커버리지 공백을 반영해
issue-mode/add-pointer 셸 감사, reviewer-* 스킬 문서, SECRETS 렌즈를
범위에 추가했다.

Co-Authored-By: Claude Fable 5 <noreply@anthropic.com>
Claude-Session: https://claude.ai/code/session_01GHD9UvKFd3nLLTiryd1m77"
```

---

### Task 8: 전체 검증과 push

- [ ] **Step 1: 레포 CLAUDE.md가 정의한 전체 검증을 돌린다**

Run: `bash scripts/test_scaffold.sh && bash scripts/test_hooks.sh && bash scripts/test_codex_scaffold.sh && claude plugin validate ./`
Expected: 세 테스트 모두 FAIL=0, validate 통과(version 미지정 경고 1건은 기존 상태 — 이 계획의 범위 밖이며 2차 계획에서 다룬다).

- [ ] **Step 2: push하고 CI를 관찰한다**

Run: `git push && gh run watch --exit-status`
Expected: contracts job 성공. plugin-validate job은 Task 2 Step 3의 불확실성 처리에 따른다.

---

## 범위 밖 (2차 계획으로 이월)

다음은 자기감사 확정 발견이지만 이 계획의 범위가 아니다 — 결합 관계 때문에 별도 계획에서 함께 다룬다:
- SSOT 손복제 6건(scaffold↔codex-scaffold 공유 헬퍼 추출, spec/plan 경로 계약 단일화, 정본 머리말 오서술, README 목록 2건, 오답노트 형식 3분기). README 목록의 fix가 헬퍼 추출 여부에 의존한다.
- CLEAR-COMM 문체 위반(major 4 + minor 다수) — 파일 단위 일괄 패스.
- plugin.json version 추가(validate 경고 해소).
- §가 트리거 표 행 추가 + ultracode 검증 토글 — 기능 추가라서 brainstorming → spec 경로로 별도 진행.

<!-- spec-review: passed -->
