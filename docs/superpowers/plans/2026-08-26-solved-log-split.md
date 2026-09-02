# 오답노트 쪼개기 구현 계획

> **제거된 기능의 계획이다(superseded).** 오답노트(solved_problems)는 걷어냈다. 아래 태스크를 실행하지 마라. 어떻게 쪼갰었는지의 기록으로만 남긴다.

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** 오답노트를 지시사항 한 줄짜리 색인과 항목별 본문 파일로 갈라, 문제를 겪은 뒤가 아니라 그 일을 시작할 때 걸리게 만든다.

**Architecture:** 색인은 사람이 쓰고 스캐폴드는 읽기만 한다. 스캐폴드가 하는 일은 넷이다 — 머리말을 그 로그의 형태(쪼개짐·안 쪼개짐)에 맞는 것으로 갈아끼우고, 색인 줄 수와 본문 파일 수를 세어 어긋나면 알리며, 아직 안 쪼개진 로그를 만나면 항목 수와 함께 개편을 권하고, 주입할 때 색인의 뿌리를 한 줄로 적는다. 쪼개는 일 자체는 별도 스크립트가 하고 사람이 부른다.

**Tech Stack:** 순수 bash(훅과 스캐폴드의 기존 제약)와 `awk`. 쪼개는 스크립트만은 파이썬을 쓰고, 이 레포의 관례대로 `python3`를 먼저 보고 없으면 `python`으로 떨어진다. 테스트는 이 레포의 `check` 관용구를 쓰는 bash 스크립트다.

**Spec:** `docs/superpowers/specs/2026-08-25-solved-log-split-design.md`

**1회차 리뷰:** `docs/superpowers/reviews/2026-08-26-solved-log-split-plan-review.md` — 이 계획은 그 리뷰를 반영해 다시 쓴 것이다. 리뷰가 잡은 것 가운데 무거운 셋(머리말 갱신이 색인 첫 줄을 먹는 것, 쪼개기가 멱등이 아닌 것, 개수 세기가 0건에서 두 줄 값을 내는 것)은 각각 Task 1·Task 6·Task 3이 소유한다.

## Global Constraints

- 스캐폴드 쌍둥이는 **함께** 고친다 — `scripts/scaffold.sh`(Claude)와 `scripts/codex-scaffold.sh`(Codex). 공통 로직은 `scripts/_scaffold_common.sh`가 SSOT다.
- 테스트 쌍둥이도 **함께** 고친다 — `scripts/test_scaffold.sh`와 `scripts/test_codex_scaffold.sh`. **두 `run` 헬퍼의 시그니처가 다르다** — Claude 쪽은 `run <HOME> <프로젝트>`이고 Codex 쪽은 `run <HOME>` 하나뿐이라 `CLAUDE_PROJECT_DIR`을 안 세운다. 그래서 Codex 스캐폴드는 `PROJ=$PWD`, 즉 **이 레포 자신**을 프로젝트로 잡는다. Task 2가 그 헬퍼를 먼저 고친다.
- 각 테스트 스크립트의 계약은 **FAIL=0**이다. 기대 개수를 숫자로 박지 않는다.
- 새 계약을 넣으면 **회귀를 일부러 심어 FAIL이 뜨는 것을 확인하고 되돌린다**(뮤테이션 검증). 이 레포는 항진 검사를 여러 번 겪었다.
- **부정 단언(`! …`)은 그 자체로 항진이 되기 쉽다.** 함수가 없거나 파일이 없어도 참이 되기 때문이다. 부정 단언을 쓸 때는 같은 픽스처에 긍정 단언을 짝으로 붙인다.
- 픽스처는 상수에서 만들지 않고 **리터럴로 적는다** — 상수에서 만들면 상수의 오타를 못 잡는 항진 검사가 된다.
- 여러 줄 문자열의 포함 여부는 `grep -F`가 아니라 `case "$본문" in *"$블록"*)`로 본다.
- `-`로 시작할 수 있는 패턴에는 `grep -F -- '패턴'`으로 옵션 끝을 명시한다.
- **`grep -c`는 0건일 때 `0`을 찍고 종료코드 1로 끝난다.** `|| echo 0`을 붙이면 값이 두 줄이 되므로 `|| true`를 쓴다.
- 스캐폴드가 색인 파일에 쓰는 것은 **머리말 갈아끼우기 하나뿐**이다. 색인 줄과 항목은 어느 경로로도 안 쓴다.
- 관리 디렉터리 자리는 런타임마다 다르다 — Claude는 `~/.claude/disciplined-coder/`, Codex는 `~/.codex/disciplined-coder/`.
- 파일을 고치기 전에 사본을 `<관리 디렉터리>/backups/`에 타임스탬프로 뜬다. 못 뜨면 아예 고치지 않는다.
- 한글은 파일 입출력뿐 아니라 **stdout에서도** UTF-8이어야 한다. 이 PC의 파이썬 `sys.stdout.encoding`은 `cp949`라 그냥 찍으면 grep이 못 찾는다.
- 이 레포의 `.gitattributes`가 `*.sh`와 `*.md`의 줄 끝을 LF로 고정하므로 `sed -i`로 파일 전체를 다시 쓰지 않는다.

---

### Task 1: 머리말 경계를 짐작이 아니라 대조로 찾게 한다

**리뷰가 잡은 가장 무거운 결함을 여기서 막는다.** 지금 경계 계산은 도입 문장 뒤의 "굵지 않은 목록 줄"을 남은 규칙 불릿으로 **짐작**하는데, 새 색인 줄이 정확히 그 모양이라 머리말 갱신이 색인 첫 줄을 먹는다. 재현에서 첫 줄이 사라지고 포인터만 고아로 남았는데 알림은 "항목은 그대로 두었다"라고 반대로 말했다. 짐작을 없애고 **실제 규칙 블록의 줄과 글자 그대로 맞대는 것**으로 바꾼다.

**Files:**
- Modify: `scripts/_scaffold_common.sh:129-176` (`scaffold_fix_solved_header`의 awk 경계 계산)
- Test: `scripts/test_scaffold.sh`

**Interfaces:**
- Consumes: 없음(첫 태스크)
- Produces: 경계 계산이 규칙 블록의 실제 줄만 머리말로 센다. 뒤 태스크가 새 색인 형식을 넣어도 안전하다.

- [ ] **Step 1: 실패하는 테스트를 쓴다**

지금 형식 그대로의 로그에 **굵지 않은 최상위 불릿**이 항목으로 들어 있는 픽스처를 만든다. 규칙 블록을 온전히 갖고 있으므로 `seen` 가지를 확실히 탄다.

```bash
# --- header-boundary: 굵지 않은 항목 줄을 머리말로 먹지 않는다 ---
# 새 색인 줄이 굵지 않은 최상위 불릿이라, 경계를 '모양'으로 짐작하면 첫 줄을 통째로 먹는다.
HB1="$(mktemp -d)"; PB1="$(mktemp -d)"; mkdir -p "$HB1/.claude/disciplined-coder"
LOGB1="$HB1/.claude/disciplined-coder/solved_problems.md"
{ printf '# 해결된 문제 로그 (solved_problems) — PC 전역\n\n'
  printf '옛 스코프 문단이라 머리말이 낡음으로 판정된다.\n\n'
  printf '항목을 적는 형식은 이렇다.\n\n'
  printf -- '- 증상은 굵게 한 줄로 띄운다.\n'
  printf -- '- 원인과 해결은 그 아래 들여쓰기로 내린다.\n\n'
  printf -- '- 굵지 않은 첫째 항목 줄이다.\n'
  printf -- '- 굵지 않은 둘째 항목 줄이다.\n'
} > "$LOGB1"
run "$HB1" "$PB1" >/dev/null
check "boundary: 굵지 않은 첫째 항목 보존" "grep -qF -- '- 굵지 않은 첫째 항목 줄이다.' '$LOGB1'"
check "boundary: 굵지 않은 둘째 항목 보존" "grep -qF -- '- 굵지 않은 둘째 항목 줄이다.' '$LOGB1'"
check "boundary: 규칙 블록이 생겼다"        "grep -qF -- '항목이 스무 개를 넘으면' '$LOGB1'"
check "boundary: 옛 스코프 문단은 사라졌다" "! grep -qF -- '옛 스코프 문단이라' '$LOGB1'"
check "boundary: 규칙 불릿이 두 벌이 아니다" "[ \"\$(grep -c -- '- 증상은 굵게 한 줄로 띄운다.' '$LOGB1' || true)\" = 1 ]"
```

- [ ] **Step 2: 실패를 확인한다**

Run: `bash scripts/test_scaffold.sh 2>&1 | tail -5`
Expected: `boundary: 굵지 않은 첫째 항목 보존`이 FAIL(그 줄이 머리말로 먹혀 사라진다). 나머지는 통과한다.

- [ ] **Step 3: 경계 계산을 대조로 바꾼다**

`scaffold_fix_solved_header` 안의 awk를 고친다. 규칙 블록 전문을 `rules` 변수로 넘기고, 도입 문장을 찾은 뒤에는 **그 블록에 실제로 있는 줄과 빈 줄만** 건너뛴다.

```bash
  local rules; rules="$(scaffold_solved_rules_for "$f")"
  n="$(awk -v rules="$rules" '
    BEGIN {
      nr = split(rules, rl, "\n")
      intro = rl[1]
      for (i = 2; i <= nr; i++) if (rl[i] != "") known[rl[i]] = 1
    }
    { l=$0; sub(/\r$/,"",l); line[NR]=l }
    END {
      seen=0
      for (i=1;i<=NR;i++) if (line[i]==intro) { seen=i; break }
      if (seen) {
        # 도입 문장 뒤에서는 빈 줄과 "이 규칙 블록에 실제로 있는 줄"만 건너뛴다.
        # 모양으로 짐작하면(굵지 않은 불릿이면 규칙이다) 색인 줄을 머리말로 먹는다.
        for (i=seen+1;i<=NR;i++) {
          if (line[i]=="") continue
          if (line[i] in known) continue
          print i; exit
        }
        print NR+1; exit
      }
      for (i=1;i<=NR;i++)
        if (line[i] ~ /^##/ || line[i] ~ /^[-*+][ \t]/ || line[i] ~ /^[0-9]+\.[ \t]/) { print i; exit }
      print 0
    }
  ' "$f" 2>/dev/null || true)"
```

`intro` 변수를 따로 뽑던 줄은 지운다 — 이제 awk가 블록 전문에서 첫 줄을 꺼내 쓴다. `scaffold_solved_rules_for`는 Task 4에서 만드는데, 이 태스크에서는 아직 없으므로 **임시로 `printf '%s' "$SCAFFOLD_SOLVED_RULES"`를 그 자리에 직접 쓰고 Task 4에서 함수 호출로 바꾼다.** 두 태스크를 한 번에 하지 않는 이유는 경계 수정이 그 자체로 검증되어야 하기 때문이다.

- [ ] **Step 4: 통과를 확인한다**

Run: `bash scripts/test_scaffold.sh 2>&1 | tail -3`
Expected: `FAIL=0`.

- [ ] **Step 5: 뮤테이션 검증**

`if (line[i] in known) continue`를 옛 모양(`if (line[i] ~ /^[-*+][ \t]/ && line[i] !~ /^[-*+][ \t]+\*\*/) continue`)으로 되돌리고 테스트를 돌린다.
Expected: `boundary: 굵지 않은 첫째 항목 보존`이 FAIL. 확인했으면 **되돌린다.**

- [ ] **Step 6: 기존 계약이 그대로인지 본다**

Run: `bash scripts/test_scaffold.sh 2>&1 | tail -3` 그리고 `bash scripts/test_codex_scaffold.sh 2>&1 | tail -3`
Expected: 둘 다 `FAIL=0`. 특히 "머리말 뒤에 사람이 만든 절은 살려 둔다"와 "규칙 블록이 일부만 남은 로그" 계약이 살아 있어야 한다 — 뒤엣것은 `known` 대조로도 통과한다(남은 불릿이 블록에 있는 줄이므로).

- [ ] **Step 7: 커밋**

```bash
git add scripts/_scaffold_common.sh scripts/test_scaffold.sh
git commit -m "머리말 경계를 모양 짐작이 아니라 규칙 블록 대조로 찾는다"
```

---

### Task 2: Codex 테스트가 이 레포의 진짜 오답노트를 건드리지 않게 한다

Codex 쪽 `run` 헬퍼가 `CLAUDE_PROJECT_DIR`을 안 세워서 `PROJ`가 `$PWD`가 된다. 그래서 그 스위트를 돌릴 때마다 스캐폴드가 이 레포의 실제 `docs/solved_problems.md`를 프로젝트 로그로 잡는다. 뒤 태스크가 프로젝트 로그 계약을 넣기 전에 격리부터 세운다.

**Files:**
- Modify: `scripts/test_codex_scaffold.sh:8` (`run` 헬퍼)
- Test: `scripts/test_codex_scaffold.sh`

**Interfaces:**
- Consumes: 없음
- Produces: `run <HOME> [프로젝트]` — Claude 쪽과 같은 시그니처. 둘째 인자를 주면 `CLAUDE_PROJECT_DIR`로 세우고, 안 주면 빈 임시 디렉터리를 쓴다.

- [ ] **Step 1: 실패하는 테스트를 쓴다**

```bash
# --- isolation: run 은 레포 자신을 프로젝트로 잡지 않는다 ---
HI1="$(mktemp -d)"; PI1="$(mktemp -d)"; mkdir -p "$PI1/docs"
printf '# 해결된 문제 로그\n\n- **격리 픽스처 항목**\n  - 원인: 무엇\n  - 해결: 무엇\n' > "$PI1/docs/solved_problems.md"
OUTI1="$(run "$HI1" "$PI1" 2>&1)"
check "isolation: 픽스처 프로젝트를 본다" "printf '%s' \"\$OUTI1\" | grep -qF -- '$PI1'"
check "isolation: 레포 자신은 안 본다"    "! printf '%s' \"\$OUTI1\" | grep -qF -- '$HERE/docs/solved_problems.md'"
```

- [ ] **Step 2: 실패를 확인한다**

Run: `bash scripts/test_codex_scaffold.sh 2>&1 | tail -5`
Expected: `isolation: 픽스처 프로젝트를 본다`가 FAIL — 둘째 인자가 무시되어 스캐폴드가 레포를 본다.

- [ ] **Step 3: 헬퍼를 고친다**

```bash
run() {  # $1=HOME 디렉터리, $2=프로젝트 디렉터리(생략하면 빈 임시 디렉터리)
  local proj="${2:-}"
  [ -n "$proj" ] || proj="$(mktemp -d)"
  CODEX_HOME_DIR="$1/.codex" CLAUDE_PROJECT_DIR="$proj" CLAUDE_PLUGIN_ROOT="$HERE" bash "$SCAFFOLD"
}
```

둘째 인자를 생략해도 빈 임시 디렉터리를 쓰게 하는 이유는, 기존 호출 스물몇 곳을 한꺼번에 고치지 않고도 격리가 서게 하기 위해서다.

- [ ] **Step 4: 통과와 기존 계약을 확인한다**

Run: `bash scripts/test_codex_scaffold.sh 2>&1 | tail -3`
Expected: `FAIL=0`.

- [ ] **Step 5: 뮤테이션 검증**

`CLAUDE_PROJECT_DIR="$proj"`를 지우고 돌린다.
Expected: `isolation: 픽스처 프로젝트를 본다`가 FAIL. 확인했으면 **되돌린다.**

- [ ] **Step 6: 커밋**

```bash
git add scripts/test_codex_scaffold.sh
git commit -m "Codex 테스트가 레포 자신의 오답노트를 프로젝트로 잡지 않게 한다"
```

---

### Task 3: 개수를 세는 헬퍼를 만든다

`grep -c`가 0건일 때 종료코드 1로 끝나는 함정을 한 곳에서 막는다. 이 헬퍼를 뒤의 두 태스크가 함께 쓴다.

**Files:**
- Modify: `scripts/_scaffold_common.sh` (파일 끝)
- Test: `scripts/test_scaffold.sh`

**Interfaces:**
- Consumes: 없음
- Produces: `scaffold_count_matches <파일> <정규식>` → stdout에 개수 한 줄. 0건이면 `0` 한 줄이고 종료코드는 늘 0이다.

- [ ] **Step 1: 실패하는 테스트를 쓴다**

```bash
# --- count: 0건에서도 값이 한 줄이다 ---
HC1="$(mktemp -d)"; printf 'a\nb\n' > "$HC1/f.md"
check "count: 있는 것을 센다"   "[ \"\$(. '$HERE/scripts/_scaffold_common.sh'; scaffold_count_matches '$HC1/f.md' '^a\$')\" = 1 ]"
check "count: 0건도 한 줄이다"  "[ \"\$(. '$HERE/scripts/_scaffold_common.sh'; scaffold_count_matches '$HC1/f.md' '^zzz\$')\" = 0 ]"
check "count: 없는 파일도 0"    "[ \"\$(. '$HERE/scripts/_scaffold_common.sh'; scaffold_count_matches '$HC1/none.md' '^a\$')\" = 0 ]"
```

- [ ] **Step 2: 실패를 확인한다**

Run: `bash scripts/test_scaffold.sh 2>&1 | tail -5`
Expected: 셋 다 FAIL(함수가 없다). 부정 단언이 없으므로 함수 부재가 통과로 둔갑하지 않는다.

- [ ] **Step 3: 헬퍼를 넣는다**

```bash
# grep -c 는 0건일 때 stdout 에 0 을 찍고 종료코드 1 로 끝난다. 거기에 `|| echo 0` 을 붙이면
# 값이 두 줄("0\n0")이 되어 어떤 비교와도 안 맞는다 — 실제로 그 함정을 밟아 새 PC 마다 오탐이
# 뜨는 결함이 리뷰에서 잡혔다. `|| true` 를 써서 stdout 한 줄만 남긴다.
scaffold_count_matches() {  # $1=파일 $2=정규식 → stdout: 개수 한 줄
  [ -f "$1" ] || { printf '0'; return 0; }
  printf '%s' "$(grep -c -E -- "$2" "$1" 2>/dev/null || true)"
}
```

- [ ] **Step 4: 통과를 확인하고 커밋한다**

Run: `bash scripts/test_scaffold.sh 2>&1 | tail -3` → `FAIL=0`

```bash
git add scripts/_scaffold_common.sh scripts/test_scaffold.sh
git commit -m "0건에서도 한 줄을 내는 개수 세기 헬퍼를 둔다"
```

---

### Task 4: 형식 규칙 블록을 로그 형태별로 두 벌 둔다

쪼개지지 않은 로그에까지 새 형식 규칙이 갈아끼워지면, 그 로그는 자기가 못 지키는 형식을 스스로 선언하게 되고 낡음 판정이 포함 검사라 어떤 자동 신호에도 안 걸린다. 머리말의 **제목 줄과 스코프 문단도 함께** 갈린다 — 리뷰가 짚은 대로, 스스로를 append-only라 부르면서 색인 줄을 고치라고 지시하는 모순을 없앤다.

**Files:**
- Modify: `scripts/_scaffold_common.sh:18-25` (규칙 상수), `:61-87` (`scaffold_solved_header`), `:107-117` (`scaffold_check_solved_rules`), Task 1이 고친 awk의 `rules` 대입
- Test: `scripts/test_scaffold.sh`, `scripts/test_codex_scaffold.sh`

**Interfaces:**
- Consumes: Task 1의 경계 계산
- Produces: `scaffold_solved_log_is_split <로그경로>`(종료코드 0이면 쪼개짐), `scaffold_solved_rules_for <로그경로>`(그 로그에 걸 규칙 블록), `SCAFFOLD_SOLVED_RULES_SPLIT`. `scaffold_solved_header <스코프> <로그경로>`로 시그니처가 넓어진다.

- [ ] **Step 1: 판정 함수의 실패하는 테스트를 쓴다**

부정 단언에 긍정 단언을 짝으로 붙인다 — 함수가 없을 때 부정 단언이 참이 되는 항진을 막는다.

```bash
# --- split-detect: 로그 옆에 본문 폴더가 있으면 쪼개진 로그다 ---
HS1="$(mktemp -d)"; touch "$HS1/solved_problems.md"
check "split-detect: 함수가 있다"           "(. '$HERE/scripts/_scaffold_common.sh'; type scaffold_solved_log_is_split)"
check "split-detect: 폴더 없으면 안 쪼개짐" "! (. '$HERE/scripts/_scaffold_common.sh'; scaffold_solved_log_is_split '$HS1/solved_problems.md')"
mkdir -p "$HS1/solved_problems"
check "split-detect: 빈 폴더도 안 쪼개짐"   "! (. '$HERE/scripts/_scaffold_common.sh'; scaffold_solved_log_is_split '$HS1/solved_problems.md')"
printf '# 무언가를 할 때는 이렇게 한다\n' > "$HS1/solved_problems/a.md"
check "split-detect: 본문이 있으면 쪼개짐"  "(. '$HERE/scripts/_scaffold_common.sh'; scaffold_solved_log_is_split '$HS1/solved_problems.md')"
```

빈 폴더를 "아직 안 쪼개짐"으로 보는 이유는, 개편을 하다 멈춘 로그가 본문 없는 폴더만 남기는데 그것을 쪼개진 것으로 보면 색인이 빈 채로 최신 형식을 선언하기 때문이다.

- [ ] **Step 2: 실패를 확인한다**

Run: `bash scripts/test_scaffold.sh 2>&1 | tail -5`
Expected: `split-detect: 함수가 있다`와 `본문이 있으면 쪼개짐`이 FAIL. 부정 단언 둘은 지금도 통과하는데, 그것이 바로 짝 단언을 붙인 이유다.

- [ ] **Step 3: 새 상수와 판정 함수를 넣는다**

```bash
# 쪼개진 로그(색인 + 본문 폴더)의 형식 규칙 블록. 안 쪼개진 로그에는 이것을 갈아끼우지 않는다 —
# 지킬 수 없는 형식을 선언하게 되고, 낡음 판정이 포함 검사라 그 어긋남은 어떤 신호에도 안 걸린다.
# 굵은 줄에 관한 규칙을 넣어 둔 이유는, 쪼갠 직후와 지시사항을 다 쓴 뒤 사이의 중간 상태를
# 사람과 기계가 함께 알아볼 수 있게 하기 위해서다.
SCAFFOLD_SOLVED_RULES_SPLIT='항목을 적는 형식은 이렇다.

- 이 파일은 색인이고 한 줄이 한 항목이다. 줄에는 지시사항만 적는다.
- 지시사항은 언제 걸리는지와 무엇을 하라는지를 한 문장에 담는다.
- 증상과 원인과 근거는 색인에 적지 않고 본문 파일에 적는다.
- 각 줄은 다음 줄에서 solved_problems/ 아래의 본문 파일 하나를 가리킨다.
- 본문 파일의 첫 줄은 그 지시사항과 같다.
- 아직 지시사항으로 못 고친 줄은 굵게 둔다. 고치면서 굵기를 벗긴다.
- 순서는 시간순이고 아래에 추가한다.
- 본문 파일을 고치거나 지우기 전에 사용자에게 묻는다.
- 사용자 요청으로 고치거나 지울 때는 색인 줄도 함께 고치거나 지운다.'

# 로그가 쪼개졌는지 본다. 판정 재료는 로그 옆의 본문 폴더에 본문 파일이 하나라도 있는지다.
scaffold_solved_log_is_split() {  # $1=로그 경로 → 종료코드 0이면 쪼개짐
  local dir="${1%.md}" f
  [ -d "$dir" ] || return 1
  for f in "$dir"/*.md; do [ -f "$f" ] && return 0; done
  return 1
}

# 그 로그에 걸어야 할 형식 규칙 블록을 고른다.
scaffold_solved_rules_for() {  # $1=로그 경로 → stdout: 규칙 블록
  if scaffold_solved_log_is_split "$1"; then
    printf '%s' "$SCAFFOLD_SOLVED_RULES_SPLIT"
  else
    printf '%s' "$SCAFFOLD_SOLVED_RULES"
  fi
}
```

- [ ] **Step 4: 머리말 전체가 형태를 따르게 한다**

`scaffold_solved_header`의 시그니처를 `<스코프> <로그경로>`로 넓히고, **제목 줄과 스코프 문단도 쪼개진 로그용으로 갈라 쓴다.** 쪼개진 로그의 제목은 `— PC 전역 · 지시사항 색인`이고, 스코프 문단에서 "append-only"라는 자기 규정을 빼고 "본문 파일은 append-only이고 색인 줄은 그 본문을 따라 고친다"로 적는다. 규칙 블록을 붙이는 마지막 줄은 이렇게 바꾼다.

```bash
  printf '\n%s\n' "$(scaffold_solved_rules_for "$2")"
```

`scaffold_ensure_solved`의 호출을 `scaffold_solved_header pc "$kdir/solved_problems.md"`로 고치고, `scaffold_fix_solved_header` 안의 본문 생성도 `scaffold_solved_header "$scope" "$f"`로 고친다. Task 1에서 임시로 `$SCAFFOLD_SOLVED_RULES`를 직접 쓰던 `rules` 대입을 `scaffold_solved_rules_for "$f"`로 바꾼다.

`scaffold_check_solved_rules`의 비교 대상도 그 선택을 쓴다.

```bash
  rules="$(scaffold_solved_rules_for "$f")"
  case "$body" in
    *"$rules"*) solved_rules_stale=0 ;;
    *) solved_rules_stale=1 ;;
  esac
```

- [ ] **Step 5: 형태별로 갈리는지 테스트한다**

```bash
# --- split-rules: 형식 규칙은 로그 형태를 따른다 ---
HS2="$(mktemp -d)"; PS2="$(mktemp -d)"; mkdir -p "$HS2/.claude/disciplined-coder"
LOGS2="$HS2/.claude/disciplined-coder/solved_problems.md"
{ printf '# 해결된 문제 로그 (solved_problems) — PC 전역\n\n'
  printf '옛 머리말이다.\n\n'
  printf -- '- **옛 항목** → 원인: 무엇 → 해결: 무엇\n'
} > "$LOGS2"
run "$HS2" "$PS2" >/dev/null
check "split-rules: 안 쪼개진 로그는 옛 규칙" "grep -qF -- '- 증상은 굵게 한 줄로 띄운다.' '$LOGS2'"
check "split-rules: 새 규칙은 안 들어감"      "! grep -qF -- '이 파일은 색인이고' '$LOGS2'"

HS3="$(mktemp -d)"; PS3="$(mktemp -d)"; mkdir -p "$HS3/.claude/disciplined-coder/solved_problems"
LOGS3="$HS3/.claude/disciplined-coder/solved_problems.md"
printf '# 무언가를 할 때는 이렇게 한다\n' > "$HS3/.claude/disciplined-coder/solved_problems/a.md"
{ printf '# 해결된 문제 로그 (solved_problems) — PC 전역\n\n'
  printf '옛 머리말이다.\n\n'
  printf -- '- 무언가를 할 때는 이렇게 한다.\n  → solved_problems/a.md\n'
} > "$LOGS3"
run "$HS3" "$PS3" >/dev/null
check "split-rules: 쪼개진 로그는 새 규칙"    "grep -qF -- '이 파일은 색인이고' '$LOGS3'"
check "split-rules: 옛 규칙은 안 들어감"      "! grep -qF -- '- 증상은 굵게 한 줄로 띄운다.' '$LOGS3'"
check "split-rules: 지시사항 줄 보존"         "grep -qF -- '- 무언가를 할 때는 이렇게 한다.' '$LOGS3'"
check "split-rules: 포인터 줄 보존"           "grep -qF -- '→ solved_problems/a.md' '$LOGS3'"
check "split-rules: append-only 자기규정 없음" "! grep -qF -- '· append-only 오답노트' '$LOGS3'"
```

**지시사항 줄 보존 검사가 포인터 검사와 따로 있는 것이 핵심이다** — 리뷰가 잡은 손실 모드는 정확히 지시사항 줄만 삼키고 포인터는 남긴다.

- [ ] **Step 6: 뮤테이션 검증 둘**

첫째, `scaffold_solved_rules_for`가 늘 `$SCAFFOLD_SOLVED_RULES`를 내게 한다 → `쪼개진 로그는 새 규칙`이 FAIL.
둘째, Task 1의 경계 계산을 옛 모양으로 되돌린다 → `split-rules: 지시사항 줄 보존`이 FAIL.
둘 다 확인했으면 **되돌린다.**

- [ ] **Step 7: Codex 테스트에 같은 계약을 넣고 전체 테스트와 커밋**

Task 2가 고친 `run`을 쓰므로 픽스처 프로젝트를 둘째 인자로 넘긴다. 픽스처 경로의 `.claude`는 `.codex`로 바꾼다. **Codex 스캐폴드는 전역 로그 전문을 stdout으로 흘려 보내므로**, 출력에 든 문자열을 찾는 부정 단언을 쓸 때는 규칙 블록에 그 문자열이 없는지 먼저 확인한다.

```bash
git add scripts/_scaffold_common.sh scripts/test_scaffold.sh scripts/test_codex_scaffold.sh
git commit -m "머리말과 형식 규칙을 로그 형태별로 두 벌 둔다"
```

---

### Task 5: 화이트리스트·짝 맞춤·개편 권유·뿌리 표기를 넣는다

스캐폴드가 읽고 알리기만 하는 네 가지를 한 태스크에 모은다. 넷 다 같은 파일의 같은 자리를 고치고 서로 리뷰 경계를 나눌 값이 없다.

**Files:**
- Modify: `scripts/_scaffold_common.sh:6`(화이트리스트)과 파일 끝(새 함수 둘), `scripts/scaffold.sh:48-61`·`:93-97`, `scripts/codex-scaffold.sh:37-49`·`:74`
- Test: `scripts/test_scaffold.sh`, `scripts/test_codex_scaffold.sh`

**Interfaces:**
- Consumes: Task 3의 `scaffold_count_matches`, Task 4의 `scaffold_solved_log_is_split`
- Produces: `scaffold_check_solved_pairing <로그경로>` → `solved_pairing_note`. `scaffold_check_solved_unsplit <로그경로> <플러그인루트>` → `solved_unsplit_note`. 두 스캐폴드가 전역 로그와 프로젝트 로그에 각각 부른다.

- [ ] **Step 1: 실패하는 테스트를 쓴다**

색인 줄은 포인터로 세고, 아직 안 갈린 옛 한 줄 형식은 **포인터 없는 굵은 줄**로 따로 센다 — 리뷰가 잡은 대로 그 부류는 포인터 셈에도 파일 셈에도 안 잡힌다.

```bash
# --- pairing: 색인 줄 수와 본문 파일 수를 맞댄다 ---
HP1="$(mktemp -d)"; PP1="$(mktemp -d)"; mkdir -p "$HP1/.claude/disciplined-coder/solved_problems"
LOGP1="$HP1/.claude/disciplined-coder/solved_problems.md"
printf '# 가 할 때는 이렇게 한다\n' > "$HP1/.claude/disciplined-coder/solved_problems/a.md"
printf '# 나 할 때는 이렇게 한다\n' > "$HP1/.claude/disciplined-coder/solved_problems/b.md"
{ printf '# 해결된 문제 로그 (solved_problems) — PC 전역\n\n'
  printf -- '- 가 할 때는 이렇게 한다.\n  → solved_problems/a.md\n'
} > "$LOGP1"
OUTP1="$(run "$HP1" "$PP1" 2>&1)"
check "pairing: 어긋나면 알린다"    "printf '%s' \"\$OUTP1\" | grep -qF -- '색인 줄 1개, 본문 파일 2개'"
check "pairing: 색인을 안 고친다"   "[ \"\$(grep -c -- '→ solved_problems/' '$LOGP1' || true)\" = 1 ]"
check "pairing: 본문도 안 지운다"   "[ -f '$HP1/.claude/disciplined-coder/solved_problems/b.md' ]"

printf -- '- 나 할 때는 이렇게 한다.\n  → solved_problems/b.md\n' >> "$LOGP1"
OUTP2="$(run "$HP1" "$PP1" 2>&1)"
check "pairing: 맞으면 조용하다"    "! printf '%s' \"\$OUTP2\" | grep -qF -- '어긋난다'"

# 아직 안 갈린 옛 한 줄 항목이 남아 있으면 그것도 알린다.
printf -- '- **옛 한 줄 항목** → 원인: 무엇 → 해결: 무엇\n' >> "$LOGP1"
OUTP3="$(run "$HP1" "$PP1" 2>&1)"
check "pairing: 안 갈린 항목을 알린다" "printf '%s' \"\$OUTP3\" | grep -qF -- '아직 안 갈린 항목 1개'"

# --- unsplit: 안 쪼개진 로그는 항목 수와 함께 개편을 권한다 ---
HU1="$(mktemp -d)"; PU1="$(mktemp -d)"; mkdir -p "$HU1/.claude/disciplined-coder"
LOGU1="$HU1/.claude/disciplined-coder/solved_problems.md"
{ printf '# 해결된 문제 로그 (solved_problems) — PC 전역\n\n'
  printf -- '- **첫째 증상**\n  - 원인: 무엇\n  - 해결: 무엇\n'
  printf -- '- **둘째 증상**\n  - 원인: 무엇\n  - 해결: 무엇\n'
} > "$LOGU1"
OUTU1="$(run "$HU1" "$PU1" 2>&1)"
check "unsplit: 개편을 권한다"        "printf '%s' \"\$OUTU1\" | grep -qF -- '개편'"
check "unsplit: 항목 수를 보인다"     "printf '%s' \"\$OUTU1\" | grep -qF -- '항목 2개'"
check "unsplit: 스크립트 절대경로"    "printf '%s' \"\$OUTU1\" | grep -qF -- '$HERE/scripts/split_solved_log.sh'"
check "unsplit: 고치지는 않는다"      "grep -qF -- '- **첫째 증상**' '$LOGU1'"

# 항목이 없는 갓 만든 로그에는 안 권한다 — grep -c 0건 함정이 여기서 드러난다.
HU2="$(mktemp -d)"; PU2="$(mktemp -d)"
OUTU2="$(run "$HU2" "$PU2" 2>&1)"
check "unsplit: 빈 로그엔 안 권함"    "! printf '%s' \"\$OUTU2\" | grep -qF -- '개편'"
```

- [ ] **Step 2: 실패를 확인한다**

Run: `bash scripts/test_scaffold.sh 2>&1 | tail -8`

- [ ] **Step 3: 화이트리스트를 고친다**

```bash
SCAFFOLD_WHITELIST="agent-principles.md domains-index.md solved_problems.md solved_problems backups"
```

- [ ] **Step 4: 두 함수를 넣는다**

```bash
# 색인 줄 수와 본문 파일 수를 맞댄다. 읽기만 하고 어떤 파일에도 쓰지 않는다.
# 전량 대조를 안 하는 이유는 항목 수만큼 값이 들기 때문이다 — 안 쓰는 항목의 어긋남은 그 회차에
# 해를 끼치지 않으므로, 내용 대조는 그 줄을 따라 본문을 열 때 그 자리에서 한다.
# 색인 줄은 포인터로 센다. 머리말의 규칙 불릿과 색인 줄이 같은 모양이라 '- '로는 안 갈린다.
# 아직 안 갈린 옛 한 줄 항목(포인터 없는 굵은 줄)은 따로 센다 — 그 부류는 포인터 셈에도 파일
# 셈에도 안 잡혀서, 손으로 가르는 걸음을 건너뛰어도 아무 신호가 없었다.
scaffold_check_solved_pairing() {  # $1=로그 경로 → sets: solved_pairing_note
  local f="$1" dir lines files bold
  solved_pairing_note=""
  [ -f "$f" ] || return 0
  scaffold_solved_log_is_split "$f" || return 0
  dir="${f%.md}"
  lines="$(scaffold_count_matches "$f" '→ solved_problems/')"
  bold="$(scaffold_count_matches "$f" '^[-*+][[:space:]]+\*\*')"
  files="$(ls -1 "$dir"/*.md 2>/dev/null | wc -l | tr -d ' ')"
  if [ "$lines" != "$files" ]; then
    solved_pairing_note="🔵 disciplined-coder: $f 의 색인 줄 ${lines}개, 본문 파일 ${files}개 — 어긋난다(고치지 않았다. 색인 줄이 가리키는 본문이 없으면 그 줄을 지우고, 본문만 있으면 첫 줄로 색인 줄을 채운다)."
  elif [ "$bold" != "0" ]; then
    solved_pairing_note="🔵 disciplined-coder: $f 에 아직 안 갈린 항목 ${bold}개가 남아 있다(포인터 없는 굵은 줄이다. 본문 파일로 옮기고 지시사항 줄로 바꿔라)."
  fi
  return 0
}

# 아직 안 쪼개진 로그를 만나면 개편을 권한다. 읽기만 한다.
# 항목 수를 함께 내는 이유는 개편에 드는 값이 항목 수에 비례하기 때문이다.
# 스크립트 경로를 절대경로로 적는 이유는 이 신호가 옆 프로젝트에서 뜨는데 그 cwd 에는 그 파일이
# 없기 때문이다 — 스크립트는 플러그인 루트 안에 있고, 그 값은 호출자만 안다.
scaffold_check_solved_unsplit() {  # $1=로그 경로 $2=플러그인 루트 → sets: solved_unsplit_note
  local f="$1" root="$2" n
  solved_unsplit_note=""
  [ -f "$f" ] || return 0
  scaffold_solved_log_is_split "$f" && return 0
  n="$(scaffold_count_matches "$f" '^[-*+][[:space:]]+\*\*')"
  [ "$n" = "0" ] && return 0
  solved_unsplit_note="🔵 disciplined-coder: $f 가 아직 안 쪼개진 형식이다(항목 ${n}개). 지금 개편할지 사용자에게 물어라 — 첫 선택지가 '지금 개편한다'이고 그것이 권장값이다. 개편은 bash $root/scripts/split_solved_log.sh 로 쪼갠 뒤 지시사항 줄을 새로 쓰는 것이다."
  return 0
}
```

- [ ] **Step 5: 두 스캐폴드가 부르게 한다**

전역 로그와 프로젝트 로그 각각에 두 함수를 부른다. **노트 변수는 `if [ -f "$PLOG" ]` 블록 바깥에서 빈 문자열로 먼저 선언한다** — 두 스캐폴드가 `set -euo pipefail`이라 안 하면 오답노트 없는 프로젝트에서 훅이 통째로 죽는다. 기존 `proj_note=""`가 블록 밖에 있는 것이 바로 그 이유다. 인쇄 루프에도 새 변수 넷을 더한다.

주입부도 고친다. `scaffold.sh`의 `@import` 블록과 `codex-scaffold.sh`의 `cat` 앞에 **그 색인의 뿌리를 한 줄로 적는다**(예: `<!-- solved-index-root: /경로/disciplined-coder -->`). 주입된 색인에는 어느 뿌리에서 왔는지가 안 남아, 세션이 엉뚱한 자리에서 본문을 찾다 못 찾으면 규칙에 따라 멀쩡한 색인 줄을 지운다.

- [ ] **Step 6: 통과와 뮤테이션 검증**

`scaffold_count_matches` 안의 `|| true`를 `|| echo 0`으로 되돌린다.
Expected: `unsplit: 빈 로그엔 안 권함`이 FAIL. 확인했으면 **되돌린다.**

`[ "$bold" != "0" ]` 가지를 지운다 → `pairing: 안 갈린 항목을 알린다`가 FAIL. 되돌린다.

- [ ] **Step 7: Codex 테스트에 같은 계약을 넣고 전체 테스트와 커밋**

```bash
git add scripts/_scaffold_common.sh scripts/scaffold.sh scripts/codex-scaffold.sh scripts/test_scaffold.sh scripts/test_codex_scaffold.sh
git commit -m "짝 맞춤과 개편 권유와 뿌리 표기를 넣고 본문 폴더를 화이트리스트에 올린다"
```

---

### Task 6: 로그를 쪼개는 스크립트를 만든다

개편을 승낙할 때마다 쓰는 도구다. 일회용이 아니라 남는 도구이므로 테스트를 함께 둔다.

**Files:**
- Create: `scripts/split_solved_log.sh`, `scripts/test_split_solved_log.sh`

**Interfaces:**
- Consumes: 없음(독립 실행)
- Produces: `bash scripts/split_solved_log.sh <로그경로> <백업디렉터리>` — 로그를 색인과 본문 파일로 가른다. **이미 갈린 항목은 건너뛴다(멱등).** 사본을 못 뜨면 아무것도 안 하고 2로 끝난다. 갈리지 않는 옛 한 줄 형식은 그대로 두고 개수를 stdout에 적는다. 색인 줄은 **굵은 채로** 남긴다 — 아직 지시사항으로 안 고쳤다는 표시이고, Task 8이 그 굵기를 벗기면서 고친다.

- [ ] **Step 1: 실패하는 테스트를 쓴다**

**빈 줄이 여러 곳에 낀 픽스처**를 쓴다 — 스펙이 요구한 것이고, 스크립트에서 가장 미묘한 곳이 빈 줄 처리다.

```bash
#!/usr/bin/env bash
# scripts/test_split_solved_log.sh
HERE="$(cd "$(dirname "$0")/.." && pwd)"
PASS=0; FAIL=0
check() { if eval "$2" >/dev/null 2>&1; then PASS=$((PASS+1)); else FAIL=$((FAIL+1)); echo "FAIL: $1"; fi; }

T="$(mktemp -d)"; B="$T/backups"; LOG="$T/solved_problems.md"
{ printf '# 해결된 문제 로그 (solved_problems) — PC 전역\n\n'
  printf '머리말 문장이다.\n\n'
  printf '항목을 적는 형식은 이렇다.\n\n'
  printf -- '- 증상은 굵게 한 줄로 띄운다.\n\n'
  printf -- '- **첫째 증상이 났다**\n  - 원인: 첫째 원인\n  - 해결: 첫째 해결\n\n'
  printf -- '- **둘째 증상이 났다** (맥락)\n  - 원인: 둘째 원인\n  - 해결: 둘째 해결\n'
  printf -- '- **셋째 증상이 났다**\n  - 원인: 셋째 원인\n\n  - 해결: 빈 줄 뒤에 이어지는 줄이다\n\n'
  printf -- '- **옛 한 줄 항목** → 원인: 무엇 → 해결: 무엇\n'
} > "$LOG"
BEFORE="$(wc -l < "$LOG")"

bash "$HERE/scripts/split_solved_log.sh" "$LOG" "$B" >"$T/out" 2>&1
check "쪼개기: 본문 폴더가 생겼다"        "[ -d '$T/solved_problems' ]"
check "쪼개기: 갈린 항목이 셋이다"        "[ \"\$(ls -1 '$T/solved_problems'/*.md | wc -l | tr -d ' ')\" = 3 ]"
check "쪼개기: 첫째 원인이 본문에 있다"   "grep -rqF -- '첫째 원인' '$T/solved_problems'"
check "쪼개기: 빈 줄 뒤 줄도 옮겨졌다"    "grep -rqF -- '빈 줄 뒤에 이어지는 줄이다' '$T/solved_problems'"
check "쪼개기: 색인에 포인터가 있다"      "grep -qF -- '→ solved_problems/' '$LOG'"
check "쪼개기: 색인에 원인이 없다"        "! grep -qF -- '첫째 원인' '$LOG'"
check "쪼개기: 색인 줄은 굵은 채다"       "grep -qF -- '- **첫째 증상이 났다**' '$LOG'"
check "쪼개기: 옛 한 줄 항목은 남았다"    "grep -qF -- '옛 한 줄 항목' '$LOG'"
check "쪼개기: 못 가른 수를 알린다"       "grep -qF -- '손으로 가를 항목 1개' '$T/out'"
check "쪼개기: 사본을 떴다"               "ls '$B'/solved_problems.*.md >/dev/null 2>&1"
check "쪼개기: 머리말이 남았다"           "grep -qF -- '머리말 문장이다.' '$LOG'"
check "쪼개기: 규칙 불릿이 남았다"        "grep -qF -- '- 증상은 굵게 한 줄로 띄운다.' '$LOG'"

# 본문에 옮겨진 줄과 색인에 남은 줄을 합치면 원본 줄 수 이상이어야 한다 — 삭제 회귀를 이웃 관계가
# 아니라 총량으로도 한 번 더 잡는다.
AFTER=$(( $(wc -l < "$LOG") + $(cat "$T/solved_problems"/*.md | wc -l) ))
check "쪼개기: 줄이 사라지지 않았다"      "[ \"$AFTER\" -ge \"$BEFORE\" ]"

CK1="$(cksum < "$LOG")"; N1="$(ls -1 "$T/solved_problems"/*.md | wc -l | tr -d ' ')"
bash "$HERE/scripts/split_solved_log.sh" "$LOG" "$B" >/dev/null 2>&1
check "쪼개기: 두 번 돌려도 색인이 같다"  "[ \"\$(cksum < '$LOG')\" = '$CK1' ]"
check "쪼개기: 두 번 돌려도 파일 수 같다" "[ \"\$(ls -1 '$T/solved_problems'/*.md | wc -l | tr -d ' ')\" = '$N1' ]"

RO="$(mktemp -d)"; LOG2="$RO/solved_problems.md"
printf -- '- **증상**\n  - 원인: 무엇\n  - 해결: 무엇\n' > "$LOG2"
BAD="$RO/nobackup"; : > "$BAD"   # 파일이라 mkdir -p 가 실패한다 — 경로 추측보다 확실하다
bash "$HERE/scripts/split_solved_log.sh" "$LOG2" "$BAD/sub" >/dev/null 2>&1
check "쪼개기: 사본 못 뜨면 안 고친다"    "! [ -d '$RO/solved_problems' ]"
check "쪼개기: 사본 못 뜨면 로그도 그대로" "grep -qF -- '- **증상**' '$LOG2'"

echo "PASS=$PASS FAIL=$FAIL"
[ "$FAIL" = 0 ]
```

백업 실패를 `/nonexistent/path`가 아니라 **파일을 디렉터리 자리에 두는 것**으로 만드는 이유는, Git Bash에서 절대경로가 설치 폴더로 풀려 관리자 셸에서는 `mkdir -p`가 성공해 버리기 때문이다.

- [ ] **Step 2: 실패를 확인한다**

Run: `bash scripts/test_split_solved_log.sh`
Expected: 대부분 FAIL. **`쪼개기: 사본 못 뜨면 안 고친다`와 `사본 못 뜨면 로그도 그대로`는 스크립트가 없어도 통과한다** — 부정 단언과 원본 보존이라 그렇다. 나머지가 붉은지로 판단한다.

- [ ] **Step 3: 스크립트를 쓴다**

```bash
#!/usr/bin/env bash
# 오답노트 한 덩어리 로그를 색인과 항목별 본문 파일로 가른다.
# 여러 번 돌려도 결과가 같다 — 다음 줄이 포인터인 항목은 이미 갈린 것으로 보고 건너뛴다.
# 갈리지 않는 항목(옛 한 줄 형식)은 그대로 두고 개수만 알린다. 뜻을 옮기는 일은 사람이 한다.
# 색인 줄은 굵은 채로 남긴다 — 아직 지시사항으로 안 고쳤다는 표시이고, 고칠 때 굵기를 벗긴다.
set -u
LOG="${1:?로그 경로가 필요하다}"; BDIR="${2:?백업 디렉터리가 필요하다}"
DIR="${LOG%.md}"

[ -f "$LOG" ] || { echo "로그가 없다: $LOG" >&2; exit 2; }

# 이 레포 관례 — python3 를 먼저 보고 없으면 python 으로 떨어진다. 이 PC 의 python3 가 한때
# 스토어 스텁이었던 이력이 오답노트에 있어 둘 다 시도한다.
PY=""
for c in python3 python; do command -v "$c" >/dev/null 2>&1 && { PY="$c"; break; }; done
[ -n "$PY" ] || { echo "파이썬을 찾지 못했다" >&2; exit 2; }

# 사본이 유일한 복구 수단이다 — 못 뜨면 아무것도 하지 않는다(폴더도 안 만든다).
STAMP="$(date +%Y%m%d-%H%M%S 2>/dev/null || echo unknown)"
LABEL="$(basename "$(dirname "$LOG")")"
if ! mkdir -p "$BDIR" 2>/dev/null || ! cp "$LOG" "$BDIR/solved_problems.$LABEL.$STAMP.md" 2>/dev/null; then
  echo "사본을 뜨지 못해 아무것도 하지 않았다($BDIR 에 쓸 수 있게 하라)" >&2
  exit 2
fi

TMP="$(mktemp "$LOG.XXXXXX")" || { echo "임시 파일을 만들지 못했다" >&2; exit 2; }
PYTHONIOENCODING=utf-8 "$PY" - "$LOG" "$DIR" "$TMP" <<'PY'
import io, os, re, sys
log, bodydir, tmp = sys.argv[1], sys.argv[2], sys.argv[3]
text = io.open(log, encoding="utf-8").read()
# splitlines() 는 U+2028/U+2029 에서도 쪼갠다 — 이 레포가 이미 겪은 함정이라 "\n" 으로만 나눈다.
lines = text.split("\n")

ITEM = re.compile(r"^[-*+][ \t]+\*\*")
PTR  = re.compile(r"^\s*→\s*solved_problems/")

def slug(title, taken):
    s = re.sub(r"[*`\[\]()]", "", title).strip()
    s = re.sub(r"\s+", "-", s)
    s = re.sub(r"[^0-9A-Za-z가-힣-]", "", s)[:40].strip("-") or "item"
    base, n = s, 2
    while s in taken:
        s = "%s-%d" % (base, n); n += 1
    taken.add(s)
    return s

out, i, taken, manual = [], 0, set(), 0
while i < len(lines):
    line = lines[i]
    if not ITEM.match(line):
        out.append(line); i += 1; continue
    # 이미 갈린 항목이면 그대로 둔다 — 이것이 멱등성의 전부다.
    if i + 1 < len(lines) and PTR.match(lines[i + 1]):
        out.append(line); out.append(lines[i + 1]); i += 2; continue
    head, body, j = line, [], i + 1
    while j < len(lines):
        if lines[j].startswith("  "):
            body.append(lines[j]); j += 1; continue
        if lines[j].strip() == "" and j + 1 < len(lines) and lines[j + 1].startswith("  "):
            body.append(lines[j]); j += 1; continue
        break
    if not any(b.strip() for b in body):
        out.append(head); i += 1; manual += 1; continue   # 옛 한 줄 형식은 손으로 가른다
    title = re.sub(r"^[-*+][ \t]+", "", head).strip()
    os.makedirs(bodydir, exist_ok=True)
    name = slug(title, taken)
    stripped = [b[2:] if b.startswith("  ") else b for b in body]
    with io.open(os.path.join(bodydir, name + ".md"), "w", encoding="utf-8", newline="\n") as fh:
        fh.write("# " + title + "\n\n" + "\n".join(stripped).strip() + "\n")
    out.append(head)
    out.append("  → solved_problems/" + name + ".md")
    i = j
io.open(tmp, "w", encoding="utf-8", newline="\n").write("\n".join(out))
sys.stdout.write("손으로 가를 항목 %d개\n" % manual)
PY
rc=$?
if [ "$rc" -ne 0 ]; then rm -f "$TMP"; echo "가르지 못했다" >&2; exit 2; fi
mv "$TMP" "$LOG"
```

본문 폴더를 미리 만들지 않고 **첫 항목을 쓸 때 만드는** 이유는, 파이썬이 죽었을 때 빈 폴더가 남으면 쪼개짐 판정이 "안 쪼개짐"으로 나와 다음 세션에 개편 권유가 다시 뜨기 때문이다.

- [ ] **Step 4: 통과를 확인한다**

Run: `bash scripts/test_split_solved_log.sh`
Expected: `FAIL=0`

- [ ] **Step 5: 뮤테이션 검증 셋**

첫째, 이미 갈린 항목을 건너뛰는 두 줄을 지운다 → `두 번 돌려도 색인이 같다`가 FAIL.
둘째, `if not any(b.strip() for b in body)` 가지를 지운다 → `옛 한 줄 항목은 남았다`와 `못 가른 수를 알린다`가 FAIL.
셋째, `PYTHONIOENCODING=utf-8`을 뺀다 → `못 가른 수를 알린다`가 FAIL(이 PC에서). 셋 다 확인했으면 **되돌린다.**

- [ ] **Step 6: 커밋**

```bash
git add scripts/split_solved_log.sh scripts/test_split_solved_log.sh
git commit -m "오답노트를 색인과 본문 파일로 가르는 스크립트를 만든다"
```

---

### Task 7: 정본의 recall 규칙과 문서 규율을 고치고 테스트로 고정한다

지금 규칙은 "시작하기 전에 비슷한 증상을 찾는다"라 시작 전에는 찾을 대상이 없다. 진입로를 둘로 만들어 그 앞뒤 안 맞음을 푼다. **그리고 그 문장을 지키는 계약이 지금 하나도 없으므로 함께 세운다** — 리뷰가 확인한 대로 관련 앵커가 테스트에 0건이다.

**Files:**
- Modify: `agent-principles.md`(오답노트 절), `skills/domain-docs/SKILL.md`(문서 타입 표·수정 규율 표·그 밖에 오답노트를 append-only로 규정한 두 곳)
- Test: `scripts/test_docs_drift.sh`

**Interfaces:**
- Consumes: 없음
- Produces: 없음

- [ ] **Step 1: 고칠 문구가 테스트 앵커인지 본다**

Run: `grep -rn '비슷한 증상을 먼저 찾는다' scripts/`
Expected: 0건(리뷰에서 확인했다). 0건이면 Step 2로 가고, 뭔가 잡히면 검사의 뜻은 그대로 두고 앵커만 새 문구로 옮긴다.

- [ ] **Step 2: 실패하는 계약 검사를 먼저 쓴다**

`scripts/test_docs_drift.sh`에 더한다. 문장 전체가 아니라 **뜻을 지탱하는 조각**을 앵커로 건다.

```bash
# --- recall: 진입로가 둘이라는 것을 정본이 말한다 ---
AP="$HERE/agent-principles.md"
check "recall: 시작할 때 진입로"   "grep -qF -- '지금 하려는 작업에 걸리는 지시사항 줄' '$AP'"
check "recall: 증상 진입로"        "grep -qF -- '이미 증상이 난 뒤에는' '$AP'"
check "recall: 두 계층을 다 본다"  "grep -qF -- 'PC solved와 프로젝트 solved 둘 다' '$AP'"
check "recall: 본문 수정은 묻는다" "grep -qF -- '고치거나 지우기 전에 사용자에게 묻는다' '$AP'"
check "recall: 색인도 함께"        "grep -qF -- '색인 줄도 같은 걸음에서 함께' '$AP'"
check "recall: 고아 줄은 지운다"   "grep -qF -- '가리키는 본문이 없으면' '$AP'"
check "recall: 고아 본문은 채운다" "grep -qF -- '색인 줄이 없으면' '$AP'"
```

- [ ] **Step 3: 실패를 확인한다**

Run: `bash scripts/test_docs_drift.sh 2>&1 | tail -8`
Expected: 일곱 다 FAIL.

- [ ] **Step 4: 정본을 고친다**

`agent-principles.md`의 오답노트 절에서 recall 불릿을 바꾼다. **계약으로 검사되는 문장은 줄바꿈에 걸리지 않게 한 줄에 온전히 둔다** — 이 레포는 문장을 접다 `grep -F` 계약을 깬 적이 있다.

```markdown
- **꺼내 쓰기(recall)**: 진입로가 둘이다. 일을 시작할 때는 **PC solved와 프로젝트 solved 둘 다**의 색인에서 지금 하려는 작업에 걸리는 지시사항 줄이 있는지 보고, 걸리면 그 줄이 가리키는 본문 파일을 연다. 이미 증상이 난 뒤에는 본문 폴더에서 그 증상을 찾는다. 프로젝트 solved는 레포에 `docs/solved_problems.md`가 있으면 있는 것으로 치되, 포인터가 있는지 없는지와 무관하게 파일 존재로 도출한다.
- **본문 파일은 묻고 고치거나 지운다**: 이미 있는 항목의 본문을 고치거나 지우기 전에 사용자에게 묻는다(새 항목을 더하는 것은 해당하지 않는다). 사용자 요청으로 고치거나 지울 때는 색인 줄도 같은 걸음에서 함께 고치거나 지운다. 색인 줄이 가리키는 본문이 없으면 되찾지 말고 그 줄을 지우고 지웠다고 알린다. 반대로 본문 파일은 있는데 색인 줄이 없으면 그 파일의 첫 줄로 색인 줄을 만들어 붙인다.
```

- [ ] **Step 5: `domain-docs`의 네 자리를 고친다**

문서 타입 표의 이슈 행, 수정 규율 표 아래 설명, 그리고 오답노트를 통째로 append-only라 규정한 나머지 두 곳(계층별 각주와 특수 케이스 절)을 함께 고친다. **본문 파일이 append-only이고 색인은 본문을 따라 고치는 것**이라고 갈라 적는다. 표만 고치면 같은 파일 안에 옛 선언이 남아 `SSOT`가 깨진다.

- [ ] **Step 6: 통과와 뮤테이션 검증**

Run: `bash scripts/test_docs_drift.sh 2>&1 | tail -3` → `FAIL=0`
그다음 recall 불릿에서 "이미 증상이 난 뒤에는"을 지우고 돌린다 → `recall: 증상 진입로`가 FAIL. **되돌린다.**

- [ ] **Step 7: 전체 테스트와 커밋**

```bash
git add agent-principles.md skills/domain-docs/SKILL.md scripts/test_docs_drift.sh
git commit -m "recall 진입로를 둘로 만들고 그 문장을 계약으로 고정한다"
```

---

### Task 8: 고친 스캐폴드가 실제 세션에 실린 것을 확인한다

**여기가 되돌리기 어려운 걸음의 문턱이다.** 세션 훅이 도는 스캐폴드는 커밋 SHA에 핀이 박힌 플러그인 캐시 사본이라 워크트리 판본과 다르다. 고친 스캐폴드가 실리기 전에 로그를 쪼개면, 옛 판본이 쪼개진 색인을 옛 형식으로 갈아끼우려 들면서 Task 1이 막은 색인 줄 삼킴이 그대로 발동한다.

**Files:** 없음(확인만 한다)

**Interfaces:**
- Consumes: Task 1~7 전부
- Produces: 이 확인을 통과해야 Task 9로 간다.

- [ ] **Step 1: 여기까지를 병합해 배포한다**

브랜치를 `main`에 병합한다. 마켓플레이스 자동 갱신이 커밋 SHA를 따라가므로 병합이 곧 배포다.

- [ ] **Step 2: 새 세션을 연다**

돌고 있는 세션은 시작할 때 읽은 사본에 묶여 있어 갱신이 안 온다. 반드시 새 세션이어야 한다.

- [ ] **Step 3: 그 세션에서 실린 판본을 확인한다**

Run: `grep -c -- '이 파일은 색인이고' "$CLAUDE_PLUGIN_ROOT/scripts/_scaffold_common.sh"`
Expected: 1 이상. 0이면 아직 옛 판본이므로 **여기서 멈추고** 갱신을 기다린다.

- [ ] **Step 4: 경계 수정이 실렸는지도 확인한다**

Run: `grep -c -- 'line\[i\] in known' "$CLAUDE_PLUGIN_ROOT/scripts/_scaffold_common.sh"`
Expected: 1. 0이면 색인 줄 삼킴이 살아 있는 판본이므로 **쪼개지 않는다.**

---

### Task 9: 두 로그를 실제로 쪼갠다

**Files:**
- Modify: 전역 로그(`<관리 디렉터리>/solved_problems.md`), 이 레포 `docs/solved_problems.md`
- Create: 두 자리의 `solved_problems/` 본문 파일들

**Interfaces:**
- Consumes: Task 6의 스크립트, Task 8의 확인
- Produces: 쪼개진 두 로그(색인 줄은 아직 굵은 증상형이다)

- [ ] **Step 1: 쪼개기 전 항목 수를 센다**

Run: `grep -c -E '^[-*+][[:space:]]+\*\*' <로그>` 를 두 로그에 각각 돌리고 값을 적어 둔다. **개수를 상수로 박지 않고 그때 센다** — 전역 로그는 세션마다 자란다. 2026-08-26 기준으로는 전역 53, 레포 27이었고 그 가운데 옛 한 줄 형식이 전역 7건이었다.

- [ ] **Step 2: 되돌리는 법을 먼저 적어 둔다**

쪼개기 전에 이 문단을 그 자리에서 확인한다. 되돌릴 때는 **사본으로 통째로 덮지 않는다** — 그 사이 새로 적은 항목이 함께 지워진다. 대신 사본에서 항목 하나씩을 꺼내 지금 로그에 되살리고, 본문 폴더를 지운다. 사본 이름에 스코프 이름표가 들어가므로(`solved_problems.<관리디렉터리이름>.<타임스탬프>.md`) 어느 로그의 것인지 구별된다.

- [ ] **Step 3: 이 레포 로그를 먼저 쪼갠다**

Run: `bash scripts/split_solved_log.sh docs/solved_problems.md "<관리 디렉터리>/backups"`
git으로 되돌릴 수 있는 쪽을 먼저 하는 것이 순서의 이유다.

- [ ] **Step 4: 결과를 눈으로 확인한다**

Run: `git diff --stat && ls docs/solved_problems | head` 그리고 본문 파일 하나를 열어 증상·원인·해결이 다 옮겨졌는지 본다. `손으로 가를 항목 N개` 출력과 Step 1의 값이 맞는지 확인한다.

- [ ] **Step 5: 커밋**

```bash
git add docs/solved_problems.md docs/solved_problems
git commit -m "이 레포 오답노트를 색인과 본문 파일로 가른다"
```

- [ ] **Step 6: 전역 로그를 쪼갠다**

Run: `bash scripts/split_solved_log.sh "<관리 디렉터리>/solved_problems.md" "<관리 디렉터리>/backups"`
전역 로그는 git 밖이라 사본이 유일한 복구 수단이다. 사본 경로를 출력에서 확인한다.

- [ ] **Step 7: 스캐폴드가 무엇을 알리는지 본다**

Run: `bash scripts/scaffold.sh 2>&1 | tail -20`
Expected: 개편 권유는 사라지고, **아직 안 갈린 항목이 남아 있다는 신호가 전역 로그에 뜬다**(옛 한 줄 형식 몫). 머리말은 새 형식으로 갈렸고 색인 줄은 그대로다.

- [ ] **Step 8: 옛 한 줄 형식을 손으로 가른다**

Step 7의 신호가 가리키는 개수만큼 있다. 한 개씩 본문 파일로 옮기고 색인에는 굵은 줄과 포인터를 남긴다(지시사항으로 고치는 것은 다음 태스크다). 다 하면 그 신호가 사라진다.

---

### Task 10: 지시사항 줄을 새로 쓴다

쪼갠 직후의 색인은 아직 굵은 증상형이라 예방으로는 안 걸린다. 여기가 이 작업의 목적이 실현되는 자리다. **대상이 여든 항목이라 한 세션에 안 끝난다** — 그래서 배치로 나누고 남은 양이 눈에 보이게 한다.

**Files:**
- Modify: 두 자리의 색인과 본문 파일들

**Interfaces:**
- Consumes: Task 9의 쪼개진 두 로그
- Produces: 지시사항형 색인

- [ ] **Step 1: 진행 상황을 세는 법을 확인한다**

Run: `grep -c -E '^[-*+][[:space:]]+\*\*' <색인>`
아직 안 고친 줄의 수다. 이 값이 0이 되면 끝난 것이고, 중간에 멈춰도 다음 세션이 이 값으로 남은 양을 안다. 스캐폴드도 같은 값을 보고 신호를 낸다.

- [ ] **Step 2: 다시 쓸 것과 그대로 둘 것을 가른다**

**그대로 두는 것**은 트리거가 사고 자체인 항목이다 — 사용량 제한에 걸린 뒤, 조회가 0건으로 나온 뒤, 이미 느려진 뒤에야 쓰는 처방이 그렇다. 억지로 지시사항형으로 고치면 트리거가 "쿼리를 짤 때"처럼 넓어져 상시 발동이 되고, 상시 발동은 안 걸리는 것과 같다. 이 부류는 굵기를 벗기되 첫 줄을 증상형 그대로 두고 본문에 그 이유를 한 줄 적는다. **안 쓰는 것**은 환경이 바뀌어 무효가 된 항목이다(본문이 스스로 "이후 설치했다"·"해결됨"으로 무효화한 것들). 나머지가 **다시 쓰는 것**이다.

- [ ] **Step 3: 서로 구별 안 되는 무리를 먼저 처리한다**

뮤테이션 검증 계열 아홉은 지시사항으로 올리면 "단언을 넣었으면 회귀를 심어 FAIL이 뜨는지 확인하라"로 수렴해 똑같아진다. 한 파일로 합치거나 지시사항에 대상을 박아 가른다(파워셸의 `-eq` 타입 맞춤, `IndexOf`의 -1, `@($null).Count` 같은 것을 줄 안에 넣는다).

- [ ] **Step 4: 열 항목씩 배치로 다시 쓰고 배치마다 커밋한다**

한 항목마다 넷을 한다 — 본문 첫 줄을 지시사항으로 바꾸고(원문 증상은 본문에 `증상:`으로 남긴다), 색인 줄을 같은 문장으로 바꾸며 **굵기를 벗기고**, 파일 이름을 최종 이름으로 바꾸고, 색인의 포인터도 그 이름으로 바꾼다. 이름은 `<날짜>-<짧은 영문>.md`이되 날짜를 모르는 항목에는 안 붙인다. 이 레포 항목의 날짜는 `git log --follow -- docs/solved_problems.md`로 복원하되 **항목을 통째로 다시 쓴 세 회차**(`ea80f93` 형식 단일화, `6dc9980` 되돌리기, `63cbef3` 기계 치환 수습)가 최초 등록일로 잡히지 않게 본다.

열 항목마다 커밋한다. 레포 로그는 git이 받아 주고, 전역 로그는 git 밖이므로 배치마다 사본을 한 벌 더 뜬다.

- [ ] **Step 5: 원문과 지시사항을 대조받는다**

읽기 전용 서브에이전트에게 원문 증상·원인·해결과 새 지시사항을 나란히 주고 뜻이 어긋난 것을 찾게 한다. 이 문서를 쓴 세션이 자기 글을 보면 확증 편향에 약하다.

- [ ] **Step 6: 남은 양이 0인지와 신호가 조용한지 본다**

Run: `grep -c -E '^[-*+][[:space:]]+\*\*' <색인>` → 0
Run: `bash scripts/scaffold.sh 2>&1 | tail -20` → 짝 맞춤도 안 갈린 항목도 조용하다.

- [ ] **Step 7: 절감을 실제로 세고 스펙에 적는다**

두 색인의 문자 수를 세고 쪼개기 전 값과 견준다. 스펙의 「인지한 대가와 한계」에 실측치를 적는다 — 추정이 방향만 맞았는지 크기까지 맞았는지가 거기서 갈린다.

- [ ] **Step 8: 커밋**

```bash
git add docs/solved_problems.md docs/solved_problems docs/superpowers/specs/2026-08-25-solved-log-split-design.md
git commit -m "색인을 지시사항으로 다시 쓰고 절감을 실측해 적는다"
```

<!-- spec-review: passed -->
