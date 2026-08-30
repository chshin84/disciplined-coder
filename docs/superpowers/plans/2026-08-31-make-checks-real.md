# 검사를 진짜로 만든다 — 구현 계획 (걸음 하나)

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** 계약 테스트가 통과했다는 것이 실제로 검증됐다는 뜻이 되게 만든다.

**Architecture:** 지금 625건이 전부 통과하는데 그 초록이 무결을 뜻하지 않는다. 제목만 찍고 단언을 한
번도 안 부르는 블록과 무엇을 고쳐도 참인 단언과 삭제된 파일을 읽고 오류를 삼키는 줄이 섞여 있다.
이것들을 걷어내고, 같은 형태가 다시 생기면 붉어지는 메타 검사를 붙인다. 잔해의 대부분은 `795357c`가
오답노트 기능을 지울 때 남긴 껍데기다.

**Tech Stack:** 순수 bash. 이 레포의 검사는 파이썬을 쓰지 않는다.

**Spec:** `docs/superpowers/specs/2026-08-30-audit-unification-design.md`의 「하나 — 검사를 진짜로
만든다」

## Global Constraints

- 각 검사 스크립트의 계약은 **FAIL=0**이며 기대 개수를 숫자로 박지 않는다(`SSOT`).
- **PASS 개수는 관측이지 합격 조건이 아니다.** 이 계획이 적은 PASS 값은 예상치이고, 어긋나면 멈추지
  말고 그 값과 어긋난 이유를 보고에 적는다. 합격 조건은 `FAIL=0` 하나다.
- 전체 실행 명령은 `CLAUDE.md`가 정본이다. 실패한 이름을 모아 마지막에 알리는 형태를 바꾸지 않는다.
- `claude plugin validate ./`는 경고 하나(`version: No version specified`)만 내면 정상이다.
- 요청과 직접 연결된 줄만 바꾼다(`SURGICAL`). 주변 검사를 재포맷하지 않는다.
- **모든 태스크가 끝날 때 `FAIL=0`이다.** 붉은 검사를 커밋에 남기지 않는다.
- **줄 번호는 앞 태스크의 편집으로 밀린다.** 각 태스크는 편집 전에 대상 문자열을 `grep -n`으로 다시
  찾는다. 이 계획이 적은 줄 번호는 작성 시점의 값이다.

## 측정한 기준선 (2026-08-31)

| 스크립트 | PASS | FAIL | 비고 |
|---|---|---|---|
| `test_codex_scaffold.sh` | 40 | 0 | |
| `test_docs_drift.sh` | 288 | 0 | `No such file` 1건, 도메인 진단 블록이 매 회 출력 |
| `test_hooks.sh` | 66 | 0 | 간헐적으로 1건 실패 |
| `test_scaffold.sh` | 231 | 0 | `No such file` 1건 |

`skills/reviewer-*/`는 **여섯**이다.

---

## File Structure

| 파일 | 이 계획에서 맡는 것 |
|---|---|
| `scripts/test_assertions.sh` | 새로 만든다. 검사 스크립트가 실제로 단언하는지 본다 |
| `scripts/test_codex_scaffold.sh` | 오답노트 잔해 블록 넷을 걷는다 |
| `scripts/test_scaffold.sh` | 항진 단언 넷과 잔해 블록 하나를 걷는다 |
| `scripts/test_docs_drift.sh` | 죽은 블록 둘과 삭제된 파일 참조를 걷고, 글롭 실패를 붉게 만든다 |
| `scripts/_scaffold_common.sh` | 화이트리스트를 도출 가능한 형태로 가른다 |
| `scripts/scaffold.sh`·`scripts/codex-scaffold.sh` | 하드코딩된 파일 이름을 도출로 바꾼다 |
| `scripts/test_hooks.sh` | 간헐 실패의 원인을 찾아 고친다 |

**두 태스크가 `scripts/test_docs_drift.sh`를 함께 고친다.** 「죽은 블록을 걷는다」가 먼저 돌고
「글롭 실패를 붉게 만든다」가 뒤에 돈다. 병렬로 돌리지 않는다 — 절대 줄 번호가 서로 밀린다.

---

## 태스크 — 단언 없는 블록을 잡는 메타 검사

**Files:**
- Create: `scripts/test_assertions.sh`

**Interfaces:**
- Consumes: 없음
- Produces: `scripts/test_*.sh`를 훑어 `echo "[제목]"`을 찍고 그다음 제목까지 `check`를 한 번도 안 부른
  블록을 찾는다. 「오답노트 잔해를 코덱스 검사에서 걷는다」와 「항진 단언을 스캐폴드 검사에서
  걷는다」가 이 검사를 초록으로 만든다.

**이 검사가 잡는 것과 못 잡는 것을 미리 밝힌다.** 이것은 `check` 호출이 하나도 없는 블록만 잡는다.
`check "이름" "true"` 같은 형식적 단언이나 `! grep -qF '없는 문자열'` 같은 항진 단언은 못 잡는다.
**그러니 이 검사를 초록으로 만들려고 형식적 단언을 붙이지 마라** — 그것은 뒤 태스크가 걷어내는 것과
같은 물건이다.

- [ ] **Step 1: 검사 스크립트를 만든다**

```bash
cat > scripts/test_assertions.sh <<'SH'
#!/usr/bin/env bash
# 검사 스크립트가 실제로 단언하는지 본다.
# 제목을 찍고 check 를 한 번도 안 부르는 블록은 픽스처를 세우고 스크립트를 돌린 뒤 아무것도 재지
# 않으면서, 초록 화면에는 그 이름이 남는다. 삭제된 기능의 검사를 걷을 때 이 껍데기가 남았다.
#
# 이 검사가 잡는 것은 check 가 하나도 없는 블록뿐이다. 항진 단언은 못 잡는다 — 그것은 사람이 본다.
set -euo pipefail
HERE="$(cd "$(dirname "$0")/.." && pwd)"
pass=0; fail=0
check() { if eval "$2"; then echo "  PASS: $1"; pass=$((pass+1)); else echo "  FAIL: $1"; fail=$((fail+1)); fi; }

echo "[검사 블록마다 단언이 있다]"
SN=0
for T in "$HERE"/scripts/test_*.sh; do
  [ -f "$T" ] || continue
  B="$(basename "$T")"
  [ "$B" = "test_assertions.sh" ] && continue
  SN=$((SN+1))
  EMPTY="$(awk '
    /^[[:space:]]*echo "\[/ { if (hdr != "" && n == 0) print hdr; hdr = $0; n = 0; next }
    /(^|[^_[:alnum:]])check[[:space:]]/ { n++ }
    END { if (hdr != "" && n == 0) print hdr }
  ' "$T" || true)"
  if [ -n "$EMPTY" ]; then
    echo "    단언 없는 블록:"
    printf '%s\n' "$EMPTY" | sed 's/^/      /'
  fi
  check "$B: 단언 없는 블록이 없다" "[ -z \"\$EMPTY\" ]"
done
# 글롭이 안 맞으면 위 루프가 한 번도 안 돌아 조용히 초록이 된다. 이 스크립트가 잡으려는 결함과
# 같은 형태이므로 개수를 따로 단언한다.
check "검사 스크립트를 둘 이상 훑었다" "[ '$SN' -ge 2 ]"

echo "----"; echo "PASS=$pass FAIL=$fail"; [ "$fail" -eq 0 ]
SH
chmod +x scripts/test_assertions.sh 2>/dev/null || true
```

- [ ] **Step 2: 글롭 가드가 실제로 도는지 확인한다**

Run: `bash -c 'cd /tmp && bash /d/projects/disciplined-coder/scripts/test_assertions.sh; echo "종료=$?"'`
Expected: 경로가 `$0` 기준이라 정상 동작한다. `SN`이 넷 이상이고 `FAIL`이 다섯이다(단언 없는 블록
다섯 때문).

- [ ] **Step 3: 지금 붉어지는 블록을 확인한다**

Run: `bash scripts/test_assertions.sh`
Expected: **FAIL이 다섯.** `test_codex_scaffold.sh`에서 `[case4] solved preserved`와 `[split-rules]`와
`[index-root]`와 `[unsplit]`이, `test_scaffold.sh`에서 `[whitelist]`가 열거된다.

**이 다섯이 뒤 두 태스크의 전부다.** 여섯 번째가 나오면 계획이 낡은 것이므로 멈추고 보고한다.

- [ ] **Step 4: 커밋하지 않는다**

이 검사는 지금 붉으므로 커밋하지 않는다. 뒤 두 태스크가 초록으로 만든 뒤 그 커밋에 함께 담는다.
Global Constraints의 "붉은 검사를 커밋에 남기지 않는다"가 이것이다.

파일은 작업 트리에 그대로 두고 다음 태스크로 넘어간다.

---

## 태스크 — 오답노트 잔해를 코덱스 검사에서 걷는다

**Files:**
- Modify: `scripts/test_codex_scaffold.sh`

**Interfaces:**
- Consumes: 앞 태스크가 만든 `scripts/test_assertions.sh`
- Produces: 이 파일에서 단언 없는 블록이 사라진다.

네 블록이 대상이다. `[case4] solved preserved`와 `[split-rules]`와 `[index-root]`와 `[unsplit]`이다.

- [ ] **Step 1: 네 블록이 재려던 산출을 만드는 코드가 사라졌는지 확인한다**

Run:
```bash
grep -rn 'solved_problems' scripts/_scaffold_common.sh scripts/scaffold.sh scripts/codex-scaffold.sh
```
Expected: **두 줄.** `_scaffold_common.sh:9`의 주석에 든 `unsolved_problems`와 `:11`의
`SCAFFOLD_STALE`이다. 둘 다 옛 파일을 **걷어내는** 쪽이지 만드는 코드가 아니다.

**죽음의 근거는 "지금 그 문자열이 안 나온다"가 아니라 "그 산출을 만드는 코드가 `795357c`로
사라졌다"이다.** 부정 단언에서 앞엣것은 통과의 정의일 뿐이다.

Run: `git show --stat 795357c | grep -c 'solved'`
Expected: 0보다 큰 수. 그 커밋이 오답노트 기능을 지웠다.

- [ ] **Step 2: 네 블록과 그 픽스처를 지운다**

편집 전에 위치를 다시 찾는다.

Run: `grep -n '\[case4\] solved preserved\|\[split-rules\]\|\[index-root\]\|\[unsplit\]' scripts/test_codex_scaffold.sh`

지울 것은 아래와 같다.

- `[case4] solved preserved` — `echo` 줄과 그 아래 `printf ... >> "$K/solved_problems.md"`와
  `run "$H1" >/dev/null`
- `[split-rules]` — `echo` 줄과 **그 위의** `HX2`·`PX2`·`LOGX2` 픽스처와 **그 아래의**
  `HX3`·`PX3`·`LOGX3` 픽스처. **아래쪽 여덟 줄을 빠뜨리지 마라** — `echo` 아래에도 픽스처가 있다.
- `[index-root]` — `echo` 줄과 그 위의 `HX4`·`PX4`·`OUTX4`
- `[unsplit]` — `echo` 줄과 그 위의 `HX5`·`PX5`·`OUTX5`

Run: `grep -n 'HX2\|HX3\|HX4\|HX5\|LOGX2\|LOGX3\|OUTX4\|OUTX5\|PX2\|PX3\|PX4\|PX5' scripts/test_codex_scaffold.sh`
Expected: 지운 뒤 **한 줄도 안 나온다.** 나오면 남은 픽스처가 있다.

- [ ] **Step 3: 확인한다**

Run: `bash scripts/test_assertions.sh 2>&1 | grep test_codex_scaffold`
Expected: `PASS: test_codex_scaffold.sh: 단언 없는 블록이 없다`

Run: `bash scripts/test_codex_scaffold.sh 2>&1 | tail -1`
Expected: `FAIL=0`. PASS는 40 근처다 — 지운 블록이 `check`를 안 불렀으므로 그대로일 것으로 본다.

- [ ] **Step 4: 커밋하지 않는다**

메타 검사가 아직 `test_scaffold.sh` 때문에 붉다. 다음 태스크가 끝난 뒤 함께 커밋한다.

---

## 태스크 — 항진 단언을 스캐폴드 검사에서 걷는다

**Files:**
- Modify: `scripts/test_scaffold.sh`

**Interfaces:**
- Consumes: 앞 두 태스크
- Produces: 메타 검사가 초록이 된다. 이 태스크의 끝에서 셋을 함께 커밋한다.

- [ ] **Step 1: 네 단언이 항진인지 확인한다**

Run:
```bash
grep -rn '증상은 굵게 한 줄로 띄운다\|아직 안 쪼개진 형식이다\|형식 규칙 서술이 현행과 다르다\|색인과 본문이 어긋난다' scripts/ hooks/
```
Expected: **여섯 줄.** `test_scaffold.sh`의 네 단언과 `test_scaffold.sh:596`의 `NUDGE=` 대입과
`test_codex_scaffold.sh:137`의 `NUDGE_C=` 대입이다.

**여섯 줄이 모두 검사 쪽이다.** 프로덕션 코드(`scaffold.sh`·`codex-scaffold.sh`·`_scaffold_common.sh`)에
그 문자열이 없으므로 네 부정 단언은 항진이다.

`NUDGE`와 `NUDGE_C`는 이 태스크에서 건드리지 않는다 — 그 둘이 읽히는지는 「죽은 변수를 정리한다」에서
본다.

- [ ] **Step 2: 네 단언과 그 픽스처를 지운다**

Run: `grep -n 'fresh-pc:' scripts/test_scaffold.sh`로 위치를 다시 찾는다.

지울 것은 `fresh-pc: 옛 형식 규칙은 없다`와 `fresh-pc: 첫 교훈을 적어도 개편 권유가 없다`와
`fresh-pc: 머리말이 낡았다고도 안 한다`와 `fresh-pc: 짝도 어긋나지 않는다` 넷, 그리고 그 사이의
픽스처 셋(`printf ... >> "$K/solved_problems.md"`와 `mkdir -p "$K/solved_problems"; printf ...`와
`OUT1B="$(run ...)"`)이다.

그 위의 주석 두 줄("새 로그는 처음부터 쪼개진 형식으로 태어난다"로 시작하는 것)도 함께 지운다.

Run: `grep -n 'OUT1B' scripts/test_scaffold.sh`
Expected: 지운 뒤 한 줄도 안 나온다.

- [ ] **Step 3: `[whitelist]` 블록을 지운다**

Run: `grep -n 'whitelist\] the body folder' scripts/test_scaffold.sh`로 위치를 찾는다.

`echo "[whitelist] the body folder is a normal artifact, not an orphan"`과 그 위의
`HS1="$(mktemp -d)"; touch "$HS1/solved_problems.md"`와 그 위의 주석 둘("split-detect"로 시작하는
것과 "부정 단언에 긍정 단언을 짝으로 붙인다"로 시작하는 것)을 지운다.

Run: `grep -n 'HS1' scripts/test_scaffold.sh`
Expected: 지운 뒤 한 줄도 안 나온다.

- [ ] **Step 4: 셋을 함께 확인한다**

Run: `bash scripts/test_assertions.sh 2>&1 | tail -1`
Expected: `FAIL=0`

Run: `bash scripts/test_scaffold.sh 2>&1 | tail -1`
Expected: `FAIL=0`. PASS는 227로 볼 것으로 본다(231에서 항진 단언 넷이 빠진다). 다른 값이면 그 값과
이유를 보고에 적고 멈추지 않는다.

Run: `bash scripts/test_scaffold.sh 2>&1 | grep -c 'No such file'`
Expected: `0`

- [ ] **Step 5: 셋을 함께 커밋한다**

```bash
git add scripts/test_assertions.sh scripts/test_codex_scaffold.sh scripts/test_scaffold.sh
git commit -m "단언 없는 블록과 항진 단언을 걷고 그 형태를 잡는 메타 검사를 붙인다"
```

메타 검사와 그것이 붉히던 다섯을 한 커밋에 담는 이유는 `FAIL=0` 계약이 커밋마다 지켜지게 하기
위해서다.

---

## 태스크 — 죽은 블록과 삭제된 파일 참조를 드리프트 검사에서 걷는다

**Files:**
- Modify: `scripts/test_docs_drift.sh`

**Interfaces:**
- Consumes: 없음
- Produces: 이 파일이 삭제된 파일을 읽지 않고 쓰이지 않는 변수를 남기지 않는다. 「글롭 실패를 붉게
  만든다」가 이 태스크 뒤에 온다.

- [ ] **Step 1: 네 곳이 죽었는지 확인한다**

Run: `grep -n 'CANON=' scripts/test_docs_drift.sh`
Expected: 두 줄이 같은 값을 대입한다. 뒤엣것이 중복이다.

Run: `grep -n 'NONASCII\|PROMPT' scripts/test_docs_drift.sh`
Expected: 각각 한 줄. 대입만 되고 읽히지 않는다.

Run: `ls docs/solved_problems domains-index.md 2>&1`
Expected: 둘 다 없다.

Run: `grep -n 'DOM_INDEX' scripts/test_docs_drift.sh`
Expected: 세 줄. 대입 하나와 진단 조건과 진단 출력이며 `check`가 없다.

- [ ] **Step 2: 오답노트 주석과 중복 대입을 지운다**

Run: `grep -n 'recall: 오답노트' scripts/test_docs_drift.sh`로 위치를 찾는다.

그 주석 셋과 바로 아래의 중복 `CANON=` 한 줄을 지운다. 앞쪽 `CANON=` 대입이 살아 있으므로 뒤의
`$CANON` 사용은 영향을 안 받는다.

- [ ] **Step 3: 오답노트 ASCII 블록과 고아 주석을 함께 지운다**

Run: `grep -n '오답노트 본문 파일 이름은 ASCII\|쪼개는 걸음의 소유자가' scripts/test_docs_drift.sh`

지울 것은 `# --- 오답노트 본문 파일 이름은 ASCII 다 ---` 주석 둘과 `if [ -d "$HERE/docs/solved_problems" ]`
블록 전체, **그리고 그 아래의 고아 주석 둘**(`# 쪼개는 걸음의 소유자가 ...`로 시작하는 것)이다.

**고아 주석 둘을 빠뜨리지 마라.** 그것이 설명하던 검사가 이미 없어서, 남기면 존재하지 않는 계약이
강제되고 있다고 읽힌다.

- [ ] **Step 4: `DOM_INDEX`와 `PROMPT`를 지운다**

`DOM_INDEX=` 대입 한 줄과, 진단 조건에서 `|| [ "$DOM_INDEX" != "$DOM_TREE" ]` 부분과,
`echo "    domains-index  : ..."` 한 줄을 지운다.

`PROMPT=` 대입 한 줄도 지운다. 대입만 되고 읽히지 않는 세 번째 죽은 변수다.

- [ ] **Step 5: 확인한다**

Run: `bash scripts/test_docs_drift.sh 2>&1 | grep -c 'No such file'`
Expected: `0`

Run: `bash scripts/test_docs_drift.sh 2>&1 | grep -A6 '도메인 참고서 열거'`
Expected: 네 건이 PASS로 찍히고 **진단 블록이 안 찍힌다.**

Run: `bash scripts/test_docs_drift.sh 2>&1 | tail -1`
Expected: `FAIL=0`. PASS는 288 그대로일 것으로 본다.

- [ ] **Step 6: 커밋**

```bash
git add scripts/test_docs_drift.sh
git commit -m "삭제된 파일을 읽고 오류를 삼키던 줄과 죽은 블록 둘과 죽은 변수 셋을 걷는다"
```

---

## 태스크 — 글롭 실패를 붉게 만든다

**Files:**
- Modify: `scripts/test_docs_drift.sh` (`ALL` 대입 한 줄)

**Interfaces:**
- Consumes: 앞 태스크(같은 파일을 고치므로 뒤에 온다)
- Produces: 렌즈 디렉터리 이름이 바뀌면 검사가 붉어진다. 걸음 여섯의 개명이 검사를 조용히 비우지
  못한다.

**진짜 결함은 한 곳이다.** 글롭이 안 맞으면 셸이 패턴을 리터럴로 넘겨 `basename`이 `reviewer-*`를
내고 `sed`가 `*`를 남기므로 **`ALL`이 빈 문자열이 아니라 `*`가 된다.** 그래서
`check "렌즈 디렉터리가 하나 이상 있다" "[ -n \"$ALL\" ]"`가 통과한다.

렌즈 하나만 사라지는 부분 소실은 이미 잡힌다 — `DESIGN-NOTES` 트리와 `meta-aggregate`의 `source`
열거를 `ALL`과 맞대는 단언 둘이 그 자리에 있다. 그래서 이 태스크는 개수 단언을 새로 붙이지 않는다.

- [ ] **Step 1: 지금 조용히 통과하는 것을 재현한다**

레포를 건드리지 않고 임시 디렉터리에서 확인한다.

```bash
cd /tmp && rm -rf globcheck && mkdir -p globcheck/skills && cd globcheck
ALL="$(for d in ./skills/reviewer-*/; do basename "$d" | sed 's/^reviewer-//'; done | sort)"
printf 'ALL=[%s]\n' "$ALL"
[ -n "$ALL" ] && echo "→ 조용한 통과 확인" || echo "→ 붉어짐"
cd /d/projects/disciplined-coder && rm -rf /tmp/globcheck
```
Expected: `ALL=[*]`와 `→ 조용한 통과 확인`

**레포의 파일을 옮기지 않는다.** 살아 있는 디렉터리를 `mv`했다가 중간에 끊기면 렌즈가 레포 밖에
남고, 그 삭제는 커밋 diff에도 안 보인다.

- [ ] **Step 2: `ALL` 대입에 디렉터리 가드를 넣는다**

Run: `grep -n '^ALL=' scripts/test_docs_drift.sh`로 위치를 찾는다.

```bash
ALL="$(for d in "$HERE"/skills/reviewer-*/; do [ -d "$d" ] || continue; basename "$d" | sed 's/^reviewer-//'; done | sort)"
```

가드 하나로 글롭이 실패하면 `ALL`이 빈 문자열이 되고, 이미 있는 `[ -n "$ALL" ]` 단언이 붉어진다.

- [ ] **Step 3: 같은 형태를 임시 디렉터리에서 확인한다**

```bash
cd /tmp && rm -rf globcheck && mkdir -p globcheck/skills && cd globcheck
ALL="$(for d in ./skills/reviewer-*/; do [ -d "$d" ] || continue; basename "$d" | sed 's/^reviewer-//'; done | sort)"
printf 'ALL=[%s]\n' "$ALL"
[ -n "$ALL" ] && echo "→ 아직 통과" || echo "→ 붉어짐 (고쳐졌다)"
cd /d/projects/disciplined-coder && rm -rf /tmp/globcheck
```
Expected: `ALL=[]`와 `→ 붉어짐 (고쳐졌다)`

- [ ] **Step 4: 정상 상태가 그대로인지 확인한다**

Run: `bash scripts/test_docs_drift.sh 2>&1 | tail -1`
Expected: `FAIL=0`. PASS는 288 그대로다 — 단언을 더한 것이 아니라 기존 단언이 옳게 동작하게 한 것이다.

- [ ] **Step 5: 커밋**

```bash
git add scripts/test_docs_drift.sh
git commit -m "글롭이 실패하면 렌즈 디렉터리 검사가 붉어지게 한다"
```

---

## 태스크 — 화이트리스트를 도출로 바꾼다

**Files:**
- Modify: `scripts/_scaffold_common.sh`, `scripts/scaffold.sh`, `scripts/codex-scaffold.sh`
- Modify: `scripts/test_docs_drift.sh` (검사 추가)

**Interfaces:**
- Consumes: 없음
- Produces: 스크립트에 하드코딩된 파일 이름이 사라지고 그것을 붙드는 검사가 생긴다. 설계가 걸음 넷의
  `ssot-audit` 몫 가운데 절반을 이 걸음에 맡겼다.

`_scaffold_common.sh`가 `SCAFFOLD_WHITELIST`를 두고 **"여기만 고친다"**고 선언하는데, 그 목록의 파일
이름이 두 스캐폴드의 다섯 곳에 `for f in agent-principles.md`로 다시 적혀 있다.

- [ ] **Step 1: 하드코딩된 곳을 센다**

Run: `grep -n 'for f in agent-principles.md' scripts/*.sh`
Expected: 다섯 줄. `scaffold.sh` 둘과 `codex-scaffold.sh` 셋이다.

- [ ] **Step 2: 화이트리스트를 파일과 디렉터리로 가른다**

`scripts/_scaffold_common.sh`의 선언을 이렇게 바꾼다.

```bash
# 관리 디렉터리에 두는 정본 파일. 스캐폴드가 복사하는 것이 이 목록이다.
SCAFFOLD_FILES="agent-principles.md"
# 화이트리스트는 정본 파일에 backups 디렉터리를 더한 것이다. 위생 검사가 이 목록 밖을 훑는다.
SCAFFOLD_WHITELIST="$SCAFFOLD_FILES backups"
```

`backups`를 따로 두는 이유는 그것이 복사 대상이 아니라 스캐폴드가 만드는 디렉터리이기 때문이다.

- [ ] **Step 3: 다섯 곳을 도출로 바꾼다**

다섯 곳의 `for f in agent-principles.md; do`를 `for f in $SCAFFOLD_FILES; do`로 바꾼다.

**따옴표를 씌우지 않는다** — 목록이 늘면 낱말 분리가 필요하다. 지금은 항목이 하나라 차이가 없지만
목록이 둘이 되는 순간 갈린다.

- [ ] **Step 4: 스캐폴드가 그대로 도는지 확인한다**

Run: `bash scripts/test_scaffold.sh 2>&1 | tail -1`
Expected: `FAIL=0`

Run: `bash scripts/test_codex_scaffold.sh 2>&1 | tail -1`
Expected: `FAIL=0`

- [ ] **Step 5: 하드코딩을 붙드는 검사를 붙인다**

`scripts/test_docs_drift.sh`의 끝부분, `echo "----"` 앞에 넣는다.

```bash
# --- 관리 디렉터리 파일 목록은 한 곳에서만 정한다 ---
# _scaffold_common.sh 가 "여기만 고친다"고 선언해 놓고 두 스캐폴드가 파일 이름을 각자 다시 적던
# 자리다. 목록이 늘면 사람이 다섯 곳을 손으로 맞춰야 하고, 그러면 반드시 갈라진다.
echo "[관리 파일 목록 == 한 곳]"
SC_FILES="$(grep -oE '^SCAFFOLD_FILES="[^"]*"' "$HERE/scripts/_scaffold_common.sh" | sed 's/^SCAFFOLD_FILES="//; s/"$//')"
check "SCAFFOLD_FILES 를 뽑아냈다" "[ -n \"\$SC_FILES\" ]"
for f in $SC_FILES; do
  check "스캐폴드가 '$f' 를 하드코딩하지 않는다" \
    "! grep -qE \"for f in .*$f\" '$HERE/scripts/scaffold.sh' '$HERE/scripts/codex-scaffold.sh'"
done
check "두 스캐폴드가 SCAFFOLD_FILES 를 쓴다" \
  "grep -qF 'for f in \$SCAFFOLD_FILES' '$HERE/scripts/scaffold.sh' && grep -qF 'for f in \$SCAFFOLD_FILES' '$HERE/scripts/codex-scaffold.sh'"
```

마지막 단언이 부정 단언의 짝이다 — 부정만 두면 두 스캐폴드에서 루프가 통째로 사라져도 통과한다.

- [ ] **Step 6: 검사가 실제로 잡는지 확인한다**

```bash
sed -i.bak 's/for f in \$SCAFFOLD_FILES; do/for f in agent-principles.md; do/' scripts/scaffold.sh
bash scripts/test_docs_drift.sh 2>&1 | grep -c 'FAIL:'
mv scripts/scaffold.sh.bak scripts/scaffold.sh
```
Expected: 되돌리기 전에 `FAIL:`이 하나 이상. 되돌린 뒤 `bash scripts/test_docs_drift.sh`가 `FAIL=0`.

**`.bak` 파일이 남지 않았는지 확인한다.**

Run: `ls scripts/*.bak 2>&1`
Expected: 없다는 메시지.

- [ ] **Step 7: 커밋**

```bash
git add scripts/_scaffold_common.sh scripts/scaffold.sh scripts/codex-scaffold.sh scripts/test_docs_drift.sh
git commit -m "관리 파일 목록을 한 곳에서 도출하게 하고 그 계약을 검사로 붙든다"
```

---

## 태스크 — 훅 검사의 간헐 실패를 고친다

**Files:**
- Modify: `scripts/test_hooks.sh` 또는 `scripts/_managed_block.sh` (원인을 찾은 뒤 확정)

**Interfaces:**
- Consumes: 없음
- Produces: 계약이 간헐적으로만 참인 상태가 사라진다.

**이 태스크만 크기가 안 정해져 있다.** 원인을 모르므로 조사가 먼저다. 앞 태스크들과 달리 실패할 수
있고, 그때의 출구를 아래에 적어 둔다.

- [ ] **Step 1: 재현하고 어느 검사인지 찾는다**

```bash
rm -f /tmp/hooks-*.log
for i in $(seq 1 20); do
  bash scripts/test_hooks.sh > "/tmp/hooks-$i.log" 2>&1 || echo "회차 $i 실패"
done
grep -h 'FAIL:' /tmp/hooks-*.log | sort | uniq -c
```
Expected: 실패한 검사 이름이 개수와 함께 나온다.

**로그를 먼저 지운다** — 앞선 조사가 남긴 파일이 섞이면 이미 고친 검사가 원인 후보로 올라온다.

**스무 회차에서 한 번도 실패 안 하면** 재현되지 않은 것이다. 그 사실을 보고에 적고 Step 5로 간다.

- [ ] **Step 2: 시간 의존을 확인한다**

Run: `grep -n 'STALE_SECONDS\|GATE_STALE_TICKS\|sleep' scripts/_managed_block.sh scripts/test_hooks.sh`
Expected: `MANAGED_LOCK_STALE_SECONDS=10`과 `MANAGED_GATE_STALE_TICKS=300`과 `sleep 0.1`이 나온다.
틱이 0.1초이므로 문지기 대기가 30초다.

찾은 검사가 이 값에 걸리는 자리인지 본다.

- [ ] **Step 3: 원인에 맞게 고친다**

**시간 의존이면** 그 상수를 환경변수로 받아 검사에서만 짧게 덮어쓴다. 프로덕션 기본값은 그대로 둔다.

**임시 디렉터리 충돌이면** `mktemp -d`가 회차마다 새 경로를 주는지 확인하고 공유되는 고정 경로를
없앤다.

**원인을 못 찾으면 고치지 않는다.** 증상만 숨기는 수정은 간헐 실패보다 나쁘다.

- [ ] **Step 4: 스무 회 돌려 확인한다**

```bash
bad=0
for i in $(seq 1 20); do bash scripts/test_hooks.sh >/dev/null 2>&1 || bad=$((bad+1)); done
echo "실패 $bad / 20"
```
Expected: `실패 0 / 20`

- [ ] **Step 5: 못 고쳤을 때의 출구**

원인을 못 찾았거나 재현이 안 됐으면 **여기서 멈추고 사용자에게 알린다.** 알릴 것은 셋이다.

- 스무 회차 가운데 몇 번 실패했는지와 어느 검사였는지
- 무엇을 확인했고 무엇이 원인이 아니었는지
- 이 태스크를 뺀 나머지가 모두 끝났다는 것

**그리고 마무리 태스크로 넘어가지 않는다.** 마무리는 안정을 단정하는 자리라, 간헐 실패를 안고
넘어가면 이 계획이 없애려던 것(초록이 무결을 뜻하지 않는 상태)을 커밋 메시지로 되풀이한다.

- [ ] **Step 6: 커밋**

```bash
git add -A scripts/
git commit -m "훅 검사의 간헐 실패를 고친다"
```

---

## 태스크 — 걸음 하나를 마무리한다

**Files:** 없음. 확인만 한다.

**앞 태스크가 Step 5의 출구로 갔으면 이 태스크를 돌리지 않는다.**

- [ ] **Step 1: 전체 계약을 정본이 정한 형태로 돌린다**

Run:
```bash
bad=""; for t in scripts/test_*.sh; do bash "$t" || bad="$bad $t"; done; [ -z "$bad" ] && echo "ALL PASS" || echo "FAILED:$bad"
```
Expected: `ALL PASS`

- [ ] **Step 2: 플러그인 검증을 돌린다**

Run: `claude plugin validate ./`
Expected: 종료 코드 0, 경고 하나(`version: No version specified`)

- [ ] **Step 3: 스무 회 돌려 안정을 확인한다**

```bash
bad=0
for i in $(seq 1 20); do
  for t in scripts/test_*.sh; do bash "$t" >/dev/null 2>&1 || bad=$((bad+1)); done
done
echo "실패 $bad / (20 회차 × 스크립트 수)"
```
Expected: `실패 0`

**세 회차가 아니라 스무 회차인 이유는** 세 번 가운데 한 번 실패하는 결함이 세 회차를 모두 통과할
확률이 3할쯤 되기 때문이다. 이 계획이 겨눈 결함의 관측된 실패율에 맞춘다.

- [ ] **Step 4: 결과를 보고한다**

커밋으로 완료를 단정하지 않는다. 대신 보고에 넷을 적는다.

- 각 스크립트의 최종 PASS와 FAIL
- 기준선 대비 달라진 PASS와 그 이유
- 스무 회차 안정 결과
- 앞 태스크에서 못 고친 것이 있으면 그것

정본이 "'완료'는 성공 기준에 묶인 판단이라 산문으로 단정하지 말고 근거와 함께 알린다"고 정한다.

---

## 이 계획이 끝나면 무엇이 달라지는가

`scripts/test_assertions.sh`가 생겨 단언 없는 블록이 다시 생기면 붉어진다. 글롭이 실패하면 렌즈
디렉터리 검사가 붉어져 걸음 여섯의 개명이 검사를 조용히 비우지 못한다. 삭제된 파일을 읽고 오류를
삼키던 줄이 사라져 검사 출력에 `No such file`이 안 남는다. 관리 파일 목록이 한 곳에서 도출되고 그
계약을 검사가 붙든다.

**뒤 걸음이 이것에 기댄다.** 걸음 둘의 감사 발견 반영과 걸음 셋의 문서 줄이기와 걸음 여섯의 개명이
모두 이 검사에 붙들린다.

## 안 하는 것과 그 근거

**메타 검사가 항진 단언을 잡게 만들지 않는다.** 무엇이 재어지는지 기계로 판정하려면 각 단언이
가리키는 대상이 코드에 존재하는지 알아야 하는데, 그것은 이 계획의 크기를 넘는다. 잡는 것과 못 잡는
것을 태스크 머리에 밝혀 두는 것으로 갈음한다.

**렌즈 개수를 세는 단언을 새로 붙이지 않는다.** 세는 값과 비교 대상이 같은 글롭에서 나와 구조상 거의
항상 참이고, 부분 소실은 이미 있는 단언 둘이 잡는다.

**살아 있는 디렉터리를 옮겼다 되돌리는 실험을 하지 않는다.** 중간에 끊기면 렌즈가 레포 밖에 남고 그
삭제는 커밋 diff에 안 보인다. 임시 디렉터리에서 같은 것을 확인한다.

**셸 린터를 들이지 않는다.** 설계의 「범위 밖」이 정한 것이다.

**`--allow-empty` 커밋으로 완료를 선언하지 않는다.** 그런 커밋은 앞 확인이 통과했든 아니든 성공하므로,
검증되지 않은 완료가 이력에 사실로 남는다.

<!-- spec-review: escalated -->
