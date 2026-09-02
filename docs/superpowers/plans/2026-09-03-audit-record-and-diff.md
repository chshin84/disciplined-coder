# 감사 회차 기록 구조화와 회차 대조 구현 계획

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** 자기감사 실행체가 회차마다 구조화된 기록(`run.json`·`findings.json`·`diff.json`·렌즈 원본)을 봉인해 남기고, 다음 회차가 지난 회차를 LLM으로 대조해 잔존·해소·재발을 도출하며, 일관성 검사를 문서 통째 입력에서 이름표 묶음 단위 대조로 바꾼다.

**Architecture:** 워크플로 스크립트(`.claude/workflows/self-audit.js`)는 파일에 닿지 못하므로 파일을 읽고 쓰는 일은 전부 에이전트가 하고, 후보를 고르는 일(대상·이름표·지난 회차)은 `scripts/audit_*.sh`가 한다. 기록은 걸음마다 기록자 에이전트가 파일 하나씩 쓰고 검수자 에이전트가 세어 워크플로가 대조한다. 잠금은 파일의 읽기 전용 속성이고 훅은 그 속성만 읽는다. 덩어리 다섯에 순서가 있어 앞 덩어리의 계약 테스트가 초록이 된 뒤 다음으로 간다.

**Tech Stack:** bash(Git Bash), 파이썬(인터프리터 이름은 `scripts/_json_valid.sh`의 `_json_python`이 고른다), Claude Code Workflow 스크립트(JavaScript, 파일 접근 없음), 계약 테스트는 `scripts/test_*.sh`의 `check` 관례.

**Spec:** `docs/superpowers/specs/2026-09-02-audit-record-and-diff-design.md`

## Global Constraints

- 모든 계약 테스트는 **FAIL=0**이고 기대 개수를 숫자로 박지 않는다(`CLAUDE.md`).
- "자"는 전부 UTF-8 문자 수다. 문턱 값은 `scripts/audit_targets.sh` 한 곳에만 있고 `--limit`으로 출력한다. 다른 파일은 그 값을 적지 않고 스크립트를 가리킨다.
- 파이썬은 `scripts/_json_valid.sh`를 source 해 `_json_python`이 고른 이름으로만 부른다. `python`이나 `python3`를 새 스크립트에 직접 적지 않는다.
- 워크플로 스크립트 안에서는 `Date.now()`·`Math.random()`·`new Date()`를 쓰지 않는다. 날짜는 에이전트가 `date +%F`로 돌려준다.
- 기록 이름은 `domain-docs`의 기록 행을 따른다 — 요약문 `docs/superpowers/reviews/YYYY-MM-DD-self-audit.md`, 폴더 `YYYY-MM-DD-self-audit/`, 같은 날 두 번째 회차는 `-self-audit-2`.
- 찍은 기록은 고치지도 지우지도 않는다. `scripts/test_docs_drift.sh`의 작업 트리 검사와 이력 검사가 그대로 돈다. 그래서 커밋에는 이번 회차의 폴더와 요약문만 담고 `docs/superpowers/reviews/` 폴더 전체를 `git add` 하지 않는다.
- 계약 테스트는 레포 자신의 파일이나 색인을 바꾸지 않는다. 픽스처는 `mktemp -d`로 레포 밖에 세운다.
- `.sh`·`.md`·`.js`는 LF다(`.gitattributes`).
- 읽기 전용 훅에는 끄는 스위치가 없고 `DISCIPLINED_CODER_REVIEW_GATE`도 미치지 않는다.
- 실행체는 `scripts/_scaffold_common.sh`의 `SCAFFOLD_STALE`에 든 이름을 부르지 않고, "절 제목을 파일에서 읽어"와 "CLAUDE.md 가 그 명령의 정본" 두 문장을 유지한다(`scripts/test_docs_drift.sh`가 붙든다).
- 문서는 한국어 완결 문장으로 쓰고 `writing-korean`의 금지 낱말(자리·부분·영역·경우·잰다·재는·재지·붉어진·헛돈다)을 쓰지 않는다.
- 커밋은 Task마다 하나이고 메시지는 무엇을 왜 바꿨는지 한국어 완결 문장으로 쓴다. 매 커밋 전에 `bash scripts/test_*.sh` 전부와 `claude plugin validate ./`가 통과해야 한다. 전체 테스트 명령은 `CLAUDE.md`의 「변경 뒤 실행」이 정한다.

---

## 파일 구조

| 파일 | 책임 | 덩어리 |
|---|---|---|
| `scripts/test_self_audit.sh` (신설) | 실행체·감사 스크립트·회차 기록의 계약 테스트. 블록은 Task 순서대로 `echo "----"` 앞에 이어 붙인다 | 1~5 |
| `.claude/workflows/self-audit.js` (블록 단위로 고친다) | 회차 실행체. 걸음마다 에이전트를 띄우고 기록자·검수자로 기록을 남긴다 | 1·3·4·5 |
| `scripts/seal_reviews.sh` (신설) | 기록 파일을 읽기 전용으로 봉인한다 | 2 |
| `hooks/readonly_pretooluse.sh` (신설) | 읽기 전용 파일에 대한 `Write`·`Edit`을 거부하고 사유를 낸다 | 2 |
| `.claude/settings.json` (신설) | 이 레포의 SessionStart 훅으로 봉인을 되풀이한다 | 2 |
| `scripts/audit_targets.sh` (신설) | 대상 문서 조각 목록과 `--limit` 값을 낸다 | 3 |
| `scripts/audit_prior_rounds.sh` (신설) | 대조할 지난 회차 폴더와 끊긴 회차를 낸다 | 4 |
| `scripts/audit_topics.sh` (신설) | 이름표 목록을 낸다 | 5 |
| `.claude-plugin/plugin.json` | `workflows` 키로 실행체를 선언한다 | 3 |
| `skills/project-doc-audit/SKILL.md` | 걸음 표·통합 기록·회차 대조·일관성 대조 절 | 3·4·5 |
| `skills/lens-consistency/SKILL.md` | 짝의 정의·판정 셋·`duplication`·`narrowed` | 5 |
| `skills/meta-aggregate/SKILL.md` | `narrowed` 렌즈 추가 칸 | 5 |
| `skills/domain-docs/SKILL.md` | 「한 번만 띄우는 렌즈의 규율」에 한 줄 | 5 |
| `README.md` | 읽기 전용 훅 한 줄 | 2 |
| `docs/superpowers/specs/2026-08-30-audit-unification-design.md` | 머리에 두 문장 | 5 |
| `docs/superpowers/reviews/<날짜>-self-audit[-N].md`와 같은 이름의 폴더 (실행체가 만든다) | 회차 기록. 봉인되어 고칠 수 없다 | 3·4·5 |

---

## 덩어리 1 — 기록 구조 (실행체가 구조화된 발견을 낸다)

이 덩어리가 끝나면 실행체는 발견마다 `id`·`status`·`missingVotes`·`verdicts[{isReal, reason}]`를 붙이고, 중복제거가 원시 발견을 잃으면 회차를 실패로 끝내며, spec의 `run.json` 표와 같은 칸을 가진 `run` 객체를 리턴에 담는다. 파일은 아직 쓰지 않는다. 여기서 넣는 코드는 덩어리 3이 그대로 이어 쓴다.

### Task 1: 실행체 계약 테스트를 세우고 `id`와 `verdicts` 판정을 붙인다

**Files:**
- Create: `scripts/test_self_audit.sh`
- Modify: `.claude/workflows/self-audit.js:16` (REPO 정의 아래), `:141-166` (반박검증 블록), `:187-195` (리턴)

**Interfaces:**
- Produces: `findingId(round, n)` → `"<round>#<3자리>"`. `STATUS` 닫힌 집합. `ROUND` 변수(이 덩어리에서는 `'self-audit'` 고정, Task 6이 대상 도출 결과로 대입한다). 발견 객체의 `id`·`status`·`missingVotes`·`verdicts` 칸. 뒤 덩어리의 기록자와 대조 걸음이 이 칸 이름을 그대로 쓴다.

- [ ] **Step 1: 실패하는 테스트를 쓴다**

`scripts/test_self_audit.sh`를 새로 만든다.

```bash
#!/usr/bin/env bash
# 실행체(.claude/workflows/self-audit.js)·감사 스크립트(scripts/audit_*.sh)·회차 기록의 계약. FAIL=0.
# 워크플로 스크립트는 여기서 실행하지 않는다 — 정적 계약(문법·앵커 문자열)과 스크립트 동작과 기록 파일의 형태만 본다.
# 레포 자신의 파일이나 색인은 바꾸지 않는다. 픽스처는 전부 mktemp -d 로 레포 밖에 세운다.
set -euo pipefail
HERE="$(cd "$(dirname "$0")/.." && pwd)"
pass=0; fail=0
check() { if eval "$2"; then echo "  PASS: $1"; pass=$((pass+1)); else echo "  FAIL: $1"; fail=$((fail+1)); fi; }
. "$HERE/scripts/_json_valid.sh"   # json_run·json_valid_stdin — 파이썬 이름은 여기가 고른다
WF="$HERE/.claude/workflows/self-audit.js"

echo "[실행체 — 문법과 발견 칸]"
check "실행체 파일이 있다"                 "[ -f '$WF' ]"
check "node --check 가 통과한다"           "node --check '$WF' 2>/dev/null"
check "발견 id 를 회차 이름과 일련번호로 붙인다" "grep -qF 'function findingId' '$WF' && grep -qF \"padStart(3, '0')\" '$WF'"
check "검증자 판정에 isReal 을 남긴다"      "grep -qF 'isReal: v.isReal' '$WF'"
check "판정 상태 넷을 닫힌 집합으로 둔다"   "grep -qF \"'undetermined'\" '$WF' && grep -qF \"'confirmed'\" '$WF' && grep -qF \"'rejected'\" '$WF' && grep -qF \"'derived'\" '$WF'"

echo "----"; echo "PASS=$pass FAIL=$fail"; [ "$fail" -eq 0 ]
```

- [ ] **Step 2: 돌려서 실패를 확인한다**

Run: `bash scripts/test_self_audit.sh`
Expected: `findingId`·`isReal: v.isReal`·닫힌 집합 세 단언이 FAIL이고 나머지는 PASS.

- [ ] **Step 3: 실행체를 고친다**

`.claude/workflows/self-audit.js`에서 `const REPO = ...` 줄 아래에 더한다.

```js
// 발견 id 는 회차 이름과 일련번호다(2026-09-02-self-audit#017). 기록자는 이 값을 그대로 옮겨 적는다.
// ROUND 는 대상 도출 걸음이 정한다(덩어리 3). 그 전까지는 실행체 이름만 쓴다.
let ROUND = 'self-audit'
function findingId(round, n) { return `${round}#${String(n).padStart(3, '0')}` }
// 판정 상태의 닫힌 집합 — 'derived'는 반박검증 없이 도출된 발견(회차 대조가 만든다)이다.
const STATUS = ['confirmed', 'rejected', 'undetermined', 'derived']
```

반박검증 블록의 `.then(vs => { ... })`를 다음으로 바꾼다.

```js
    ]).then(vs => {
      // 검증자가 죽어 null이 온 것과 실제로 반박한 것은 다르다. 둘을 뭉치면 죽은 표가 '기각'으로 오염된다.
      // 그래서 상태를 셋으로 가른다 — 두 표가 모두 살아 있고 둘 다 진짜라면 confirmed, 둘 다 살아 있는데
      // 하나라도 반박하면 rejected, 표가 모자라면 undetermined다. 판정(isReal)과 사유를 둘 다 남긴다.
      const alive = vs.filter(Boolean)
      const status = alive.length < 2
        ? STATUS[2]
        : (alive.filter(v => v.isReal).length === 2 ? STATUS[0] : STATUS[1])
      return { id: findingId(ROUND, i + 1), ...f, status, missingVotes: 2 - alive.length, verdicts: alive.map(v => ({ isReal: v.isReal, reason: v.reason })) }
    })
```

집계 프롬프트의 `기각 발견 제목들` 줄에서 `why: r.verdicts`를 `why: r.verdicts.map(v => v.reason)`으로 바꾼다. 리턴 객체의 `rejectedTitles: rejected.map(r => r.title)`를 `rejected: rejected.map(r => ({ id: r.id, title: r.title, reasons: r.verdicts.map(v => v.reason) }))`로 바꾼다.

- [ ] **Step 4: 돌려서 통과를 확인한다**

Run: `bash scripts/test_self_audit.sh`
Expected: `FAIL=0`.

- [ ] **Step 5: 전체 테스트를 돌리고 커밋한다**

Run: `CLAUDE.md`의 전체 테스트 명령과 `claude plugin validate ./`.
Expected: `ALL PASS`, version 경고 하나.

```bash
git add scripts/test_self_audit.sh .claude/workflows/self-audit.js
git commit -m "실행체가 발견마다 id와 판정 상태와 검증자 판정을 남기고 그 계약 테스트를 세운다"
```

### Task 2: 중복제거가 원시 발견을 잃으면 회차를 실패로 끝내고 `run` 객체를 만든다

**Files:**
- Modify: `.claude/workflows/self-audit.js:18-39` (`FINDINGS_SCHEMA` 뒤), `:127-139` (중복제거 블록), 집계 뒤 리턴 앞
- Modify: `scripts/test_self_audit.sh`

**Interfaces:**
- Produces: `FINDINGS_SCHEMA`에 선택 칸 `type`. `DEDUP_SCHEMA`(`lens`·`merged_from`). `lensesOf(f)` → 발견의 `lens` 문자열을 쉼표로 나눈 배열. `run` 객체 — spec `run.json` 표의 칸 그대로: `schema`·`executor`·`commit`·`tree_clean`·`tree_changed`·`completed`·`steps_done`·`targets`·`topic_groups`·`counts_by_lens`·`verdict_counts`·`narrowed`·`unlabeled`·`dead_agents`·`machine_checks`·`stale_rounds`. 덩어리 3의 기록자가 이 객체를 그대로 `run.json`으로 쓴다.

- [ ] **Step 1: 실패하는 테스트를 더한다**

`scripts/test_self_audit.sh`의 `echo "----"` 앞에 더한다.

```bash
echo "[실행체 — 중복제거와 run 객체]"
check "중복제거 항목이 merged_from 을 돌려준다"   "grep -qF 'merged_from' '$WF'"
check "원시 발견이 정확히 한 항목에 들어갔는지 확인한다" "grep -qF '중복제거가 원시 발견을 잃었다' '$WF'"
check "발견에 type 선택 칸이 있다"                "grep -qF \"type: { type: 'string'\" '$WF'"
check "렌즈 이름을 쉼표로 나눠 센다"              "grep -qF 'function lensesOf' '$WF'"
check "run 객체가 spec 의 칸을 갖는다"            "for k in schema executor commit tree_clean tree_changed completed steps_done targets topic_groups counts_by_lens verdict_counts narrowed unlabeled dead_agents machine_checks stale_rounds; do grep -qE \"[{, ]\$k[:,]\" '$WF' || exit 1; done"
```

- [ ] **Step 2: 돌려서 실패를 확인한다**

Run: `bash scripts/test_self_audit.sh`
Expected: 새 단언 다섯이 FAIL.

- [ ] **Step 3: 실행체를 고친다**

`FINDINGS_SCHEMA`의 `fix` 줄 아래에 선택 칸을 더한다.

```js
          type: { type: 'string', description: '렌즈가 정한 폐쇄 집합의 값. 복제 발견은 duplication 이다(선택)' },
```

`FINDINGS_SCHEMA` 정의 뒤에 더한다.

```js
// 중복제거는 병합 항목마다 그것이 덮는 원시 발견의 번호(merged_from)를 돌려준다. 개수만 견주면 발견을
// 버려도 통과하므로, 모든 원시 발견이 정확히 한 항목에 들어갔는지를 워크플로가 확인한다.
const DEDUP_SCHEMA = {
  type: 'object',
  properties: {
    findings: {
      type: 'array',
      items: {
        type: 'object',
        properties: {
          ...FINDINGS_SCHEMA.properties.findings.items.properties,
          lens: { type: 'string', description: '병합된 렌즈 이름들 — 쉼표로 잇는다' },
          merged_from: { type: 'array', items: { type: 'integer' }, description: '이 항목이 덮는 원시 발견의 번호(0부터)' },
        },
        required: [...FINDINGS_SCHEMA.properties.findings.items.required, 'lens', 'merged_from'],
      },
    },
  },
  required: ['findings'],
}
// 중복제거가 lens 를 쉼표로 잇는다. 세는 쪽은 그 문자열을 목록으로 다룬다.
function lensesOf(f) { return String(f.lens || '').split(',').map(s => s.trim()).filter(Boolean) }
```

중복제거 블록을 다음으로 바꾼다.

```js
phase('중복제거')
const raw = all.map((f, i) => ({ raw_index: i, ...f }))
let deduped = raw.map(f => ({ ...f, merged_from: [f.raw_index] }))
if (raw.length > 1) {
  const dd = await agent(
    `다음은 disciplined-coder 저장소 감사에서 여러 렌즈가 낸 원시 발견 목록(JSON)이다. 항목마다 raw_index 가 있다.
같은 실체(같은 파일의 같은 문제)를 가리키는 발견들을 하나로 병합하라 — evidence는 가장 구체적인 것을 남기고, lens는 쉼표로 합치고, consequence는 피해를 가장 구체적으로 적은 것을 남기고, type 이 있으면 그대로 옮긴다.
병합 항목마다 그것이 덮는 원시 발견의 raw_index 전부를 merged_from 에 적어라. 모든 원시 발견은 정확히 한 항목에 들어가야 한다.
서로 다른 문제는 절대 합치지 마라. 재판단·신규 발견 추가 금지 — 순수 병합만 한다.
${JSON.stringify(raw)}`,
    { label: 'dedup', phase: '중복제거', schema: DEDUP_SCHEMA, effort: 'low' }
  )
  if (!dd) throw new Error('중복제거 에이전트가 응답하지 않았다 — 회차를 실패로 끝낸다')
  const covered = dd.findings.flatMap(f => f.merged_from).sort((a, b) => a - b)
  const expected = raw.map(f => f.raw_index)
  if (JSON.stringify(covered) !== JSON.stringify(expected)) {
    throw new Error(`중복제거가 원시 발견을 잃었다 — 기대 ${JSON.stringify(expected)}, 실제 ${JSON.stringify(covered)}`)
  }
  deduped = dd.findings
}
log(`중복 제거 후 ${deduped.length}건 — 반박 검증 시작`)
```

집계 뒤, `return {` 앞에 더한다.

```js
// run 은 spec 의 run.json 표와 같은 칸이다. 이 덩어리에서는 리턴에만 담고, 덩어리 3의 기록자가 파일로 쓴다.
const lensKeys = [...new Set(all.map(f => f.lens))]
const counts_by_lens = {}
for (const k of lensKeys) counts_by_lens[k] = { raw: all.filter(f => f.lens === k).length, unique: deduped.filter(f => lensesOf(f).length === 1 && lensesOf(f)[0] === k).length }
const run = {
  schema: 1, executor: 'self-audit', commit: null, tree_clean: null, tree_changed: false, completed: false,
  steps_done: [], targets: [], topic_groups: 0, counts_by_lens,
  verdict_counts: { confirmed: confirmed.length, rejected: rejected.length, undetermined: undetermined.length, derived: 0 },
  narrowed: 0, unlabeled: 0, dead_agents: { lenses: deadLenses }, machine_checks: null, stale_rounds: [],
}
```

리턴 객체에 `run,`을 첫 항목으로 더한다.

- [ ] **Step 4: 돌려서 통과를 확인한다**

Run: `bash scripts/test_self_audit.sh`
Expected: `FAIL=0`.

- [ ] **Step 5: 전체 테스트를 돌리고 커밋한다**

```bash
git add scripts/test_self_audit.sh .claude/workflows/self-audit.js
git commit -m "중복제거가 원시 발견을 잃으면 회차를 실패로 끝내고 spec 의 run.json 칸을 가진 run 객체를 만든다"
```

---

## 덩어리 2 — 잠금 (봉인 스크립트와 읽기 전용 훅)

이 덩어리가 끝나면 `docs/superpowers/reviews/` 아래 커밋된 파일은 세션마다 읽기 전용으로 봉인되고, 읽기 전용 파일에 대한 `Write`·`Edit`은 사유와 함께 거부된다.

### Task 3: `seal_reviews.sh`와 SessionStart 봉인

**Files:**
- Create: `scripts/seal_reviews.sh`
- Create: `.claude/settings.json`
- Modify: `scripts/test_docs_drift.sh` (「리뷰 기록은 찍은 뒤 고치지 않는다」 블록 뒤, `echo "----"` 앞)

**Interfaces:**
- Produces: `bash scripts/seal_reviews.sh [--root DIR] [파일...]`. 파일 인자가 있으면 그 파일들을, 없으면 `DIR`(기본은 레포 루트)의 `HEAD`에 있는 `docs/superpowers/reviews/` 아래 파일 전부를 `chmod a-w` 한다. 여러 번 돌려도 같다. 덩어리 3의 기록자가 쓴 파일을 인자로 넘긴다.

- [ ] **Step 1: 실패하는 테스트를 더한다**

`scripts/test_docs_drift.sh`의 `echo "----"` 앞에 더한다.

```bash
# --- 봉인: 기록은 만든 직후에 읽기 전용이 된다 ---
# 읽기 전용 속성은 git이 옮기지 않아 새 클론에서는 풀려 있다. 그래서 SessionStart 훅이 세션마다 다시
# 봉인한다. 인자 없는 갈래는 픽스처 저장소에서 검사한다 — 레포 자신에서 돌리면 스크립트가 아무것도
# 처리하지 않아도 작업 트리 상태만으로 초록이 되고, 검사가 레포의 파일 속성을 바꾼다.
echo "[봉인 — 기록은 읽기 전용이 된다]"
SEAL="$HERE/scripts/seal_reviews.sh"
check "봉인 스크립트가 있다"                 "[ -f '$SEAL' ]"
SEAL_T="$(mktemp -d)"; printf 'a\n' > "$SEAL_T/one.md"; printf 'b\n' > "$SEAL_T/two.json"
bash "$SEAL" "$SEAL_T/one.md" "$SEAL_T/two.json" >/dev/null 2>&1 || true
check "인자로 준 파일이 읽기 전용이 된다"     "[ ! -w '$SEAL_T/one.md' ] && [ ! -w '$SEAL_T/two.json' ]"
bash "$SEAL" "$SEAL_T/one.md" "$SEAL_T/two.json" >/dev/null 2>&1 || true
check "인자 있는 봉인을 두 번 돌려도 같다"     "[ ! -w '$SEAL_T/one.md' ] && [ ! -w '$SEAL_T/two.json' ]"
SEAL_G="$(mktemp -d)"; mkdir -p "$SEAL_G/docs/superpowers/reviews/r1"
( cd "$SEAL_G" && git init -q && git config user.email t@t && git config user.name t \
  && printf 'x\n' > docs/superpowers/reviews/r1.md && printf '{}\n' > docs/superpowers/reviews/r1/run.json \
  && printf 'later\n' > docs/superpowers/reviews/untracked.md && git add docs/superpowers/reviews/r1.md docs/superpowers/reviews/r1/run.json && git commit -qm seed )
bash "$SEAL" --root "$SEAL_G" >/dev/null 2>&1 || true
bash "$SEAL" --root "$SEAL_G" >/dev/null 2>&1 || true
check "인자 없는 봉인이 HEAD 의 기록을 전부 읽기 전용으로 만든다" "[ ! -w '$SEAL_G/docs/superpowers/reviews/r1.md' ] && [ ! -w '$SEAL_G/docs/superpowers/reviews/r1/run.json' ]"
check "HEAD 에 없는 파일은 건드리지 않는다"     "[ -w '$SEAL_G/docs/superpowers/reviews/untracked.md' ]"
check "이 레포의 SessionStart 가 봉인을 건다"  "grep -qF 'seal_reviews.sh' '$HERE/.claude/settings.json'"
```

- [ ] **Step 2: 돌려서 실패를 확인한다**

Run: `bash scripts/test_docs_drift.sh 2>&1 | grep -E '봉인|HEAD|SessionStart|PASS='`
Expected: "봉인 스크립트가 있다"·"인자로 준"·"두 번"·"HEAD 의 기록"·"SessionStart" 다섯이 FAIL. "HEAD 에 없는 파일"은 스크립트가 없어 아무것도 안 바뀌므로 PASS다.

- [ ] **Step 3: 봉인 스크립트와 설정을 쓴다**

`scripts/seal_reviews.sh`:

```bash
#!/usr/bin/env bash
# 기록을 봉인한다 — 파일 인자를 읽기 전용(chmod a-w)으로 만들고, 파일 인자가 없으면 --root(기본은 레포 루트)의
# HEAD 에 있는 docs/superpowers/reviews/ 아래 파일 전부를 그렇게 한다. 여러 번 돌려도 같다(IDEMPOTENT).
# 읽기 전용 속성은 만든 쪽의 의도라 어느 저장소에서든 같은 뜻이고, 훅(hooks/readonly_pretooluse.sh)은
# 이 속성만 읽는다. git은 이 속성을 옮기지 않으므로 새 클론에서는 SessionStart 훅이 이 스크립트를 다시 돈다.
set -euo pipefail
HERE="$(cd "$(dirname "$0")/.." && pwd)"
ROOT="$HERE"; files=()
while [ "$#" -gt 0 ]; do
  case "$1" in
    --root) ROOT="$2"; shift 2 ;;
    *) files+=("$1"); shift ;;
  esac
done
if [ "${#files[@]}" -eq 0 ]; then
  mapfile -t files < <(cd "$ROOT" && git ls-tree -r --name-only HEAD -- docs/superpowers/reviews 2>/dev/null | sed "s|^|$ROOT/|")
fi
n=0
for f in "${files[@]}"; do
  [ -f "$f" ] || continue
  chmod a-w "$f"
  n=$((n+1))
done
echo "sealed: $n"
```

`.claude/settings.json`:

```json
{
  "hooks": {
    "SessionStart": [
      {
        "matcher": "startup|resume|clear",
        "hooks": [
          {
            "type": "command",
            "command": "bash \"$CLAUDE_PROJECT_DIR/scripts/seal_reviews.sh\""
          }
        ]
      }
    ]
  }
}
```

- [ ] **Step 4: 돌려서 통과를 확인한다**

Run: `bash scripts/test_docs_drift.sh 2>&1 | grep -E '봉인|HEAD|SessionStart|PASS='`
Expected: 블록의 단언 전부 PASS.

- [ ] **Step 5: 전체 테스트를 돌리고 커밋한다**

Run: 전체 테스트 명령.
Expected: `ALL PASS`. `git status`에 기록 파일이 `M`으로 뜨지 않는다(Windows에서 `core.filemode`가 꺼져 있어 속성은 git이 보지 않는다).

```bash
git add scripts/seal_reviews.sh .claude/settings.json scripts/test_docs_drift.sh
git commit -m "기록을 만든 직후 읽기 전용으로 봉인하고 세션마다 다시 봉인한다"
```

### Task 4: 읽기 전용 훅

**Files:**
- Create: `hooks/readonly_pretooluse.sh`
- Modify: `hooks/hooks.json` (PreToolUse `Write|Edit` 항목)
- Modify: `scripts/test_hooks.sh` (`echo "[doc-format-pre]"` 앞. `. "$HERE/scripts/_json_valid.sh"` 줄은 `EXTRACT=` 정의 아래로 옮긴다)
- Modify: `README.md:44-51` (「하드 게이트와 넛지와 전역 설정 수정」 절)

**Interfaces:**
- Produces: `PreToolUse(Write|Edit)`에서 대상 파일이 있고 쓰기 불가이면 `{"hookSpecificOutput":{"hookEventName":"PreToolUse","permissionDecision":"deny","permissionDecisionReason":"..."}}`를 낸다. 그 밖에는 무출력.

- [ ] **Step 1: 실패하는 테스트를 더한다**

`scripts/test_hooks.sh`의 `echo "[doc-format-pre]"` 앞에 더한다. 무출력 단언에는 훅 파일의 존재를 함께 요구한다 — 훅이 없어도 무출력이라 그것만으로는 항진 단언이다.

```bash
echo "[readonly-pre — 읽기 전용 파일은 고치지 않는다]"
RPRE="$HERE/hooks/readonly_pretooluse.sh"
rpre() { printf '%s' "$1" | bash "$RPRE"; }
RO="$(mktemp -d)"; printf 'sealed\n' > "$RO/sealed.md"; printf 'open\n' > "$RO/open.md"; chmod a-w "$RO/sealed.md"
check "훅 파일이 있다"                         "[ -f '$RPRE' ]"
check "읽기 전용 파일(절대경로) → deny"        "rpre '$(J "$RO/sealed.md")' | grep -qF '\"permissionDecision\":\"deny\"'"
check "거부 사유가 들어 있다"                  "rpre '$(J "$RO/sealed.md")' | grep -qF '읽기 전용 파일은 고치지 않는다'"
check "거부 응답이 유효한 JSON"                "rpre '$(J "$RO/sealed.md")' | json_valid_stdin"
check "쓸 수 있는 파일 → 무출력"               "[ -f '$RPRE' ] && [ -z \"\$(rpre '$(J "$RO/open.md")')\" ]"
check "없는 파일 → 무출력"                     "[ -f '$RPRE' ] && [ -z \"\$(rpre '$(J "$RO/nope.md")')\" ]"
check "상대경로(현재 폴더 기준) 읽기 전용 → deny" "( cd '$RO' && printf '%s' '$(J "sealed.md")' | bash '$RPRE' ) | grep -qF '\"permissionDecision\":\"deny\"'"
check "게이트 OFF 여도 거부한다"               "DISCIPLINED_CODER_REVIEW_GATE=off rpre '$(J "$RO/sealed.md")' | grep -qF '\"permissionDecision\":\"deny\"'"
check "README 가 이 훅을 적는다"               "grep -qF '읽기 전용 차단' '$HERE/README.md'"
```

픽스처 `$RO`는 `CLAUDE_PROJECT_DIR`(`$T`) 밖에 있으므로 "절대경로 → deny"가 곧 프로젝트 밖 파일도 거부한다는 검사다.

- [ ] **Step 2: 돌려서 실패를 확인한다**

Run: `bash scripts/test_hooks.sh 2>&1 | grep -E 'readonly|FAIL|PASS='`
Expected: 새 단언 아홉이 모두 FAIL. 배선 블록의 "모든 훅 스크립트가 어딘가에 배선되어 있다"는 훅 파일이 아직 없으므로 PASS.

- [ ] **Step 3: 훅을 쓰고 배선하고 README에 적는다**

`hooks/readonly_pretooluse.sh`:

```bash
#!/usr/bin/env bash
# PreToolUse(Write|Edit): 대상 파일이 있고 쓰기 불가이면 거부하고 사유를 낸다.
# 경로·저장소·HEAD는 보지 않는다 — 읽기 전용이라는 속성은 그 파일을 만든 쪽의 의도라 어느 프로젝트에서든
# 같은 뜻이다. 끄는 스위치를 두지 않는다(DISCIPLINED_CODER_REVIEW_GATE 도 미치지 않는다). 풀려면 속성을
# 풀면 되고 그 길은 셸이다. Write 는 훅 없이도 EPERM 으로 막히므로 이 훅의 몫은 왜 막혔는지 말하는 것이다.
set -euo pipefail
DIR="$(cd "$(dirname "$0")" && pwd)"
. "$DIR/_json_escape.sh"   # JSON 문자열 이스케이프 공유(SSOT)
INPUT="$(cat)"
match=""
while IFS= read -r FILE; do
  [ -n "$FILE" ] || continue
  [ -e "$FILE" ] || continue            # 없는 파일은 새로 만드는 것이라 막을 속성이 없다
  [ -w "$FILE" ] && continue            # 쓸 수 있으면 훅의 일이 아니다
  match="$FILE"; break
done <<EOF
$(printf '%s' "$INPUT" | bash "$DIR/_extract_path.sh")
EOF
[ -n "$match" ] || exit 0
reason="읽기 전용 파일은 고치지 않는다. 속성을 세운 쪽에 뜻이 있다 — 감사 기록이면 고치지 말고 새 기록을 더한다. 파일: $match"
esc="$(escape_for_json "$reason")"
printf '{"hookSpecificOutput":{"hookEventName":"PreToolUse","permissionDecision":"deny","permissionDecisionReason":"%s"}}\n' "$esc"
exit 0
```

`hooks/hooks.json`의 `PreToolUse` 항목 `hooks` 배열 첫머리에 더한다.

```json
          {
            "type": "command",
            "command": "bash \"${CLAUDE_PLUGIN_ROOT}/hooks/readonly_pretooluse.sh\""
          },
```

`README.md` 「하드 게이트와 넛지와 전역 설정 수정」 절의 첫 문장 "세션에는 턴 종료를 막는 하드 게이트 하나와 넛지 셋과 전역 설정 수정 하나가 걸린다."를 "세션에는 턴 종료를 막는 하드 게이트 하나와 읽기 전용 파일 수정을 막는 차단 하나와 넛지 셋과 전역 설정 수정 하나가 걸린다."로 바꾸고, 그다음 문장 "게이트와 넛지는 환경변수 `DISCIPLINED_CODER_REVIEW_GATE=off` 하나로 넷 다 꺼지고,"를 "게이트와 넛지는 환경변수 `DISCIPLINED_CODER_REVIEW_GATE=off` 하나로 넷 다 꺼지고, 읽기 전용 차단은 그 변수와 무관하며,"로 바꾼다. 불릿 「Stop 하드 게이트」 뒤에 한 줄을 더한다.

```markdown
- **읽기 전용 차단** — 읽기 전용 속성이 선 파일에 `Write`나 `Edit`을 하려 하면 거부하고 사유를 보인다. 어느 프로젝트의 어느 파일이든 속성만 보며, 이 레포의 감사 기록은 만든 직후 `scripts/seal_reviews.sh`가 그 속성을 세운다. 풀려면 속성을 풀면 된다.
```

- [ ] **Step 4: 돌려서 통과를 확인한다**

Run: `bash scripts/test_hooks.sh 2>&1 | grep -E 'FAIL|PASS='`
Expected: `FAIL=0`.

- [ ] **Step 5: 전체 테스트를 돌리고 커밋한다**

```bash
git add hooks/readonly_pretooluse.sh hooks/hooks.json scripts/test_hooks.sh README.md
git commit -m "읽기 전용 파일에 대한 Write와 Edit을 사유와 함께 거부하는 훅을 건다"
```

---

## 덩어리 3 — 재배선 (대상 도출·기록자·검수자·매니페스트)

이 덩어리가 끝나면 실행체는 이 레포인지 확인하고, `scripts/audit_targets.sh`로 대상을 도출해 문서마다 렌즈를 배정하고, 걸음마다 기록자와 검수자로 기록을 파일 하나씩 남기며, 첫 회차 기록이 계약 테스트와 함께 커밋된다. 첫 회차의 `diff.json`은 `no_prior_round`가 참인 빈 파일이다.

### Task 5: `audit_targets.sh` — 대상 조각과 문턱 값

**Files:**
- Create: `scripts/audit_targets.sh`
- Modify: `scripts/test_self_audit.sh`

**Interfaces:**
- Produces: `bash scripts/audit_targets.sh [--root DIR]` → 한 줄에 조각 하나, `경로<TAB>시작 줄<TAB>끝 줄`(1부터, 양끝 포함, 경로는 `DIR` 기준 상대경로). `bash scripts/audit_targets.sh --limit` → 문턱 값(정수). 대상 도출 에이전트가 이 출력을 그대로 돌려준다.

- [ ] **Step 1: 실패하는 테스트를 더한다**

`scripts/test_self_audit.sh`의 `echo "----"` 앞에 더한다.

```bash
echo "[audit_targets.sh — 대상 조각과 문턱]"
AT="$HERE/scripts/audit_targets.sh"
check "스크립트가 있다"                              "[ -f '$AT' ]"
AT_LIMIT="$(bash "$AT" --limit 2>/dev/null || true)"
check "--limit 이 양의 정수를 낸다"                  "printf '%s' \"\$AT_LIMIT\" | grep -qE '^[1-9][0-9]*$'"
AT_OUT="$(bash "$AT" 2>/dev/null || true)"
check "출력이 비어 있지 않다"                        "[ -n \"\$AT_OUT\" ]"
check "줄마다 경로·시작·끝 세 칸이다"                "printf '%s\n' \"\$AT_OUT\" | awk -F'\t' 'NF!=3{exit 1}'"
check "docs/superpowers/ 아래는 없다"                "! printf '%s\n' \"\$AT_OUT\" | grep -q '^docs/superpowers/'"
check "HANDOFF- 로 시작하는 파일은 없다"             "! printf '%s\n' \"\$AT_OUT\" | grep -qE '(^|/)HANDOFF-'"
# 그 밖의 살아 있는 .md 전부가 있다 — 기대 목록은 스크립트와 같은 규칙으로 git 에서 도출한다.
AT_MISS=""
while IFS= read -r f; do
  [ -n "$f" ] || continue
  head -12 "$HERE/$f" | grep -qi superseded && continue
  printf '%s\n' "$AT_OUT" | cut -f1 | grep -qxF "$f" || AT_MISS="$AT_MISS $f"
done <<EOF
$(cd "$HERE" && git ls-files '*.md' | grep -v '^docs/superpowers/' | grep -vE '(^|/)HANDOFF-')
EOF
[ -n "$AT_MISS" ] && echo "    빠진 문서:$AT_MISS"
check "살아 있는 .md 가 모두 있다"                   "[ -z \"\$AT_MISS\" ]"
# 조각마다 문자 수가 --limit 을 넘지 않는다 — 자르기가 실제로 문턱을 지키는지 본다.
AT_OVER="$(cd "$HERE" && printf '%s\n' "$AT_OUT" | json_run '
import sys, io
limit = int(sys.argv[1]); over = []
for line in sys.stdin:
    line = line.rstrip("\n")
    if not line: continue
    path, s, e = line.split("\t"); s, e = int(s), int(e)
    lines = io.open(path, encoding="utf-8").read().split("\n")
    n = len("\n".join(lines[s-1:e]))
    if n > limit: over.append(f"{path}:{s}-{e}={n}")
print(" ".join(over))
' "$AT_LIMIT")"
[ -n "$AT_OVER" ] && echo "    문턱을 넘는 조각: $AT_OVER"
check "조각마다 문자 수가 --limit 이하다"            "[ -z \"\$AT_OVER\" ]"
# 성질로 빼는지는 픽스처 저장소에서 본다 — 레포 자신에 파일을 만들거나 색인을 건드리지 않는다.
AT_G="$(mktemp -d)"; mkdir -p "$AT_G/docs/superpowers/specs" "$AT_G/sub"
( cd "$AT_G" && git init -q && git config user.email t@t && git config user.name t \
  && printf '# live\n\nbody\n' > live.md && printf '# spec\n' > docs/superpowers/specs/s.md \
  && printf '# old\n> superseded 2026-09-03\n' > old.md && printf '# h\n' > HANDOFF-x.md && printf '# h2\n' > sub/HANDOFF-y.md \
  && git add -A && git commit -qm seed )
AT_FIX="$(bash "$AT" --root "$AT_G" 2>/dev/null || true)"
check "픽스처에서 살아 있는 문서만 남는다"           "[ \"\$(printf '%s\n' \"\$AT_FIX\" | cut -f1 | sort | tr '\n' ' ' | sed 's/ *$//')\" = 'live.md' ]"
check "문턱 값이 audit_targets.sh 한 곳에만 있다"     "[ \"\$(grep -rlE \"(^|[^0-9])\$AT_LIMIT([^0-9]|$)\" '$HERE'/scripts '$HERE'/skills '$HERE'/README.md '$HERE'/CLAUDE.md '$HERE'/.claude/workflows 2>/dev/null | grep -vE 'audit_targets.sh|test_self_audit.sh' | wc -l)\" = 0 ]"
```

- [ ] **Step 2: 돌려서 실패를 확인한다**

Run: `bash scripts/test_self_audit.sh 2>&1 | grep -E 'FAIL|PASS='`
Expected: 블록의 단언 가운데 "한 곳에만"을 뺀 전부가 FAIL. 마지막 단언은 `$AT_LIMIT`이 비어 패턴이 성립하지 않아 그 순간에는 뜻이 없고, 스크립트가 생기면 실제 값을 찾는다.

- [ ] **Step 3: 스크립트를 쓴다**

`scripts/audit_targets.sh`:

```bash
#!/usr/bin/env bash
# 감사 대상 문서를 조각으로 낸다 — 한 줄에 조각 하나, 경로<TAB>시작 줄<TAB>끝 줄(1부터, 양끝 포함).
# --limit 이면 문턱 값(UTF-8 문자 수)만 낸다. 이 값은 렌즈 호출 하나의 입력 상한이며 여기 한 곳에만 둔다.
# --root DIR 이면 그 저장소를 본다(기본은 이 레포). 대상은 git 이 추적하는 .md 전부에서 성질로 뺀다 —
# docs/superpowers/ 아래(spec·plan·기록은 domain-docs 의 타입 표가 감사 대상 아님으로 정한 타입이고 폴더로
# 도출된다), 이름이 HANDOFF- 로 시작하는 파일, 머리 열두 줄 안에 superseded 가 있는 문서. 손으로 적은 목록은
# 두지 않는다. 문턱을 넘는 문서는 ## 절로, 절도 넘으면 ### 절로, 그것도 넘으면 문단 경계로 자른다.
set -euo pipefail
HERE="$(cd "$(dirname "$0")/.." && pwd)"
. "$HERE/scripts/_json_valid.sh"   # json_run — 파이썬 이름은 여기가 고른다
LIMIT=5000
ROOT="$HERE"
while [ "$#" -gt 0 ]; do
  case "$1" in
    --limit) echo "$LIMIT"; exit 0 ;;
    --root) ROOT="$2"; shift 2 ;;
    *) echo "audit_targets.sh: 모르는 인자 $1" >&2; exit 2 ;;
  esac
done
cd "$ROOT"
LIST="$(mktemp)"
git ls-files '*.md' | grep -v '^docs/superpowers/' | grep -vE '(^|/)HANDOFF-' | while IFS= read -r f; do
  head -12 "$f" | grep -qi superseded && continue
  printf '%s\n' "$f"
done > "$LIST"
# 파이프와 히어독은 표준 입력을 두고 부딪히므로 목록은 파일로 넘긴다.
json_run '
import sys, io
limit = int(sys.argv[1]); listfile = sys.argv[2]

def size(lines, s, e):  # 1부터, 양끝 포함
    return len("\n".join(lines[s-1:e]))

def split_by(lines, s, e, prefix):
    # prefix 로 시작하는 줄에서 자른다. 첫 조각은 s 부터 첫 제목 전까지(머리·frontmatter)다.
    cuts = [i for i in range(s, e+1) if lines[i-1].startswith(prefix)]
    if not cuts or cuts == [s]:
        return [(s, e)]
    bounds = ([s] if cuts[0] != s else []) + cuts
    out = []
    for i, b in enumerate(bounds):
        nxt = bounds[i+1]-1 if i+1 < len(bounds) else e
        out.append((b, nxt))
    return out

def split_paragraphs(lines, s, e):
    # 빈 줄 경계로 문단을 나눠 문턱까지 채운다. 한 문단이 문턱을 넘으면 그 문단은 통째로 한 조각이다.
    paras, cur = [], s
    for i in range(s, e+1):
        if lines[i-1].strip() == "" and i > cur:
            paras.append((cur, i-1)); cur = i+1
    if cur <= e: paras.append((cur, e))
    out, start, end = [], None, None
    for (ps, pe) in paras:
        if start is None: start, end = ps, pe; continue
        if size(lines, start, pe) <= limit: end = pe
        else: out.append((start, end)); start, end = ps, pe
    if start is not None: out.append((start, end))
    return out

def fragments(lines, s, e):
    if size(lines, s, e) <= limit: return [(s, e)]
    out = []
    for (a, b) in split_by(lines, s, e, "## "):
        if size(lines, a, b) <= limit: out.append((a, b)); continue
        for (c, d) in split_by(lines, a, b, "### "):
            if size(lines, c, d) <= limit: out.append((c, d))
            else: out.extend(split_paragraphs(lines, c, d))
    return out

for path in io.open(listfile, encoding="utf-8").read().split("\n"):
    if not path: continue
    lines = io.open(path, encoding="utf-8").read().split("\n")
    if lines and lines[-1] == "": lines = lines[:-1]
    if not lines: continue
    for (a, b) in fragments(lines, 1, len(lines)):
        sys.stdout.write(f"{path}\t{a}\t{b}\n")
' "$LIMIT" "$LIST"
rm -f "$LIST"
```

- [ ] **Step 4: 돌려서 통과를 확인한다**

Run: `bash scripts/test_self_audit.sh 2>&1 | grep -E 'FAIL|PASS='` 그리고 `bash scripts/audit_targets.sh | awk -F'\t' '{c[$1]++} END{for(k in c) if(c[k]>1) print k, c[k]}'`
Expected: `FAIL=0`. 둘째 명령은 `skills/domain-docs/SKILL.md`·`skills/domain-spec-review/SKILL.md`·`skills/lens-readability/SKILL.md` 셋만 조각이 둘 이상이다. `skills/project-doc-audit/SKILL.md`는 덩어리 4·5가 절을 더하면 넷째가 된다.

- [ ] **Step 5: 전체 테스트를 돌리고 커밋한다**

```bash
git add scripts/audit_targets.sh scripts/test_self_audit.sh
git commit -m "감사 대상을 성질로 도출해 조각으로 내고 입력 문턱 값을 한 곳에 둔다"
```

### Task 6: 실행체 재배선 — 레포 확인·대상 도출·문서별 렌즈·기록자와 검수자·매니페스트

**Files:**
- Modify: `.claude/workflows/self-audit.js` (블록 단위 교체 — 아래 순서대로. Task 1·2가 넣은 `findingId`·`STATUS`·`DEDUP_SCHEMA`·`lensesOf`·중복제거 블록·반박검증 `.then`은 그대로 둔다)
- Modify: `.claude-plugin/plugin.json` (`workflows` 키)
- Modify: `scripts/test_self_audit.sh`

**Interfaces:**
- Consumes: `findingId`·`STATUS`·`ROUND`(Task 1), `DEDUP_SCHEMA`·`lensesOf`·`run`(Task 2), `scripts/audit_targets.sh`(Task 5), `scripts/seal_reviews.sh`(Task 3).
- Produces: `docs/superpowers/reviews/<round>/run.json`·`findings.json`·`diff.json`(빈 파일)·`<렌즈>-<n>.json`, 요약문 `docs/superpowers/reviews/<round>.md`(봉인하지 않는다). 걸음 이름 목록 `STEPS`. 함수 `record(step, files)`·`writeRun(final)`·`writeSummary(text)`와 상수 `COUNT_RULE`. `findingsFile`·`diffFile` 객체. 덩어리 4·5가 `STEPS`에 걸음을 더하고 이 함수들을 그대로 부른다.

- [ ] **Step 1: 실패하는 테스트를 더한다**

`scripts/test_self_audit.sh`의 `echo "----"` 앞에 더한다.

```bash
echo "[실행체 — 재배선]"
check "실행체가 audit_targets.sh 를 부른다"           "grep -qF 'audit_targets.sh' '$WF'"
check "실행체가 검토 대상 문서를 손으로 적지 않는다"  "! grep -qE \"['\\\"](README|CLAUDE)\\\\.md['\\\"]\" '$WF' && ! grep -qF '검토 대상: README' '$WF'"
check "레포 확인 걸음이 있다"                          "grep -qF \"'repo-check'\" '$WF' && grep -qF \"name !== 'disciplined-coder'\" '$WF'"
check "기록은 파일 하나마다 기록자와 검수자를 띄운다"  "grep -qF 'async function writeFile(' '$WF' && grep -qF \"label: \\\`record:\" '$WF' && grep -qF \"label: \\\`check:\" '$WF' && grep -qF '기록 검수 불일치' '$WF'"
check "completed 는 검수를 지난 뒤에만 참이 된다"     "grep -qF 'run.completed = true' '$WF' && grep -qF 'async function writeRun(' '$WF'"
check "요약문은 봉인하지 않는다"                       "grep -qF 'async function writeSummary(' '$WF' && grep -qF '요약문은 봉인하지 않는다' '$WF'"
check "기록자가 봉인 스크립트를 돈다"                  "grep -qF 'seal_reviews.sh' '$WF'"
check "렌즈에 정본 경로와 principles_applied 를 요구한다" "grep -qF 'agent-principles.md' '$WF' && grep -qF 'principles_applied' '$WF'"
check "기계 검사가 실패를 묻는 형태를 금지한다"        "grep -qF '종료 코드에 묻히는 형태로 바꿔 쓰지 마라' '$WF'"
check "옛 차원 렌즈가 없다"                            "! grep -qE 'ssot-audit|shell-audit|clear-comm-audit|docs-compliance' '$WF'"
check "매니페스트가 실행체를 workflows 에 선언한다"     "grep -qF '\"./.claude/workflows/self-audit.js\"' '$HERE/.claude-plugin/plugin.json'"
check "Date.now 와 Math.random 을 쓰지 않는다"          "! grep -qE 'Date\\.now|Math\\.random|new Date' '$WF'"
```

- [ ] **Step 2: 돌려서 실패를 확인한다**

Run: `bash scripts/test_self_audit.sh 2>&1 | grep -E 'FAIL|PASS='`
Expected: "손으로 적지 않는다"·"레포 확인"·"파일 하나마다"·"completed"·"요약문"·"봉인 스크립트"·"옛 차원 렌즈"·"매니페스트" 여덟이 FAIL.

- [ ] **Step 3: 실행체를 블록 단위로 고친다**

**(a) `export const meta`를 통째로 바꾼다.**

```js
export const meta = {
  name: 'self-audit',
  description: 'disciplined-coder 저장소를 자기 원칙·자기 렌즈로 자기검증하고 회차 기록을 구조화해 봉인한다',
  whenToUse: '큰 변경(정본·훅·스캐폴드 수정) 후 회귀 감사가 필요할 때 레포 루트에서 실행한다(다른 위치면 args로 레포 경로를 넘긴다). 결과는 docs/superpowers/reviews/<회차>/ 의 run.json·findings.json·diff.json·렌즈 원본과 봉인하지 않은 요약문이다. 이 레포가 아니면 아무것도 쓰지 않고 멈춘다.',
  phases: [
    { title: '준비', detail: '레포 확인 → 대상·조각·문턱 도출과 렌즈 배정 → 기계 검사와 지문' },
    { title: '리뷰', detail: '문서별 렌즈(grounding·readability·fit)와 전체 렌즈(adversarial·plugin-compliance)를 병렬로 띄운다' },
    { title: '중복제거', detail: '병합 항목마다 merged_from 을 받아 원시 발견이 하나도 안 빠졌는지 확인한다' },
    { title: '반박검증', detail: '발견마다 사실성·실질성 검증자 둘, 판정과 사유를 둘 다 남긴다' },
    { title: '집계', detail: '상충·커버리지 공백 표시와 지문 재확인' },
    { title: '기록', detail: '걸음마다 기록자가 파일 하나씩 쓰고 검수자가 센다 — run.json 은 검수를 지난 뒤 completed 로 닫힌다' },
  ],
}
```

**(b) `let ROUND = 'self-audit'` 줄 아래에 더한다.**

```js
const EXECUTOR = 'self-audit'
const SCHEMA_VERSION = 1
// 걸음 이름의 닫힌 목록. 기록자는 끝난 걸음 이름을 run.json 의 steps_done 에 쌓는다.
const STEPS = ['repo-check', 'targets', 'machine-checks', 'review', 'dedup', 'verify', 'aggregate', 'record']
```

**(c) `lensesOf` 정의 뒤에 스키마를 더한다.**

```js
const LENS_SCHEMA = {
  type: 'object',
  properties: {
    findings: FINDINGS_SCHEMA.properties.findings,
    read: { type: 'array', items: { type: 'string' }, description: '문서 밖에서 실제로 연 파일' },
    principles_applied: { type: 'array', items: { type: 'string' }, description: '읽고 적용한 원칙 ID' },
  },
  required: ['findings', 'read', 'principles_applied'],
}
const REPO_CHECK_SCHEMA = {
  type: 'object',
  properties: { name: { type: 'string', description: '.claude-plugin/plugin.json 의 name. 파일이 없으면 빈 문자열' } },
  required: ['name'],
}
const TARGETS_SCHEMA = {
  type: 'object',
  properties: {
    date: { type: 'string', description: 'date +%F 결과' },
    round: { type: 'string', description: '회차 이름 — <date>-self-audit, 같은 이름 폴더나 .md 가 있으면 -2, -3 을 붙인다' },
    limit: { type: 'integer', description: 'audit_targets.sh --limit 의 값' },
    fragments: { type: 'array', items: { type: 'object', properties: { path: { type: 'string', description: '레포 상대경로 — 스크립트 출력 그대로' }, start: { type: 'integer' }, end: { type: 'integer' } }, required: ['path', 'start', 'end'] } },
    targets: {
      type: 'array',
      items: {
        type: 'object',
        properties: {
          path: { type: 'string', description: '레포 상대경로 — 조각의 path 와 같은 꼴' },
          lenses: { type: 'array', items: { type: 'string', enum: ['lens-grounding', 'lens-readability', 'lens-fit'] } },
          reason: { type: 'string', description: '물음 넷에 어떻게 답했는지' },
          purpose: { type: 'string', description: 'lens-readability 에 줄 목적 한 줄(읽는 사람 + 할 수 있어야 하는 것). 못 적으면 빈 문자열이고 그때는 lenses 에 lens-readability 를 넣지 않는다' },
        },
        required: ['path', 'lenses', 'reason', 'purpose'],
      },
    },
  },
  required: ['date', 'round', 'limit', 'fragments', 'targets'],
}
const MACHINE_SCHEMA = {
  type: 'object',
  properties: {
    allPassed: { type: 'boolean' },
    results: { type: 'array', items: { type: 'object', properties: { name: { type: 'string' }, passed: { type: 'boolean' }, summary: { type: 'string' } }, required: ['name', 'passed', 'summary'] } },
    commit: { type: 'string', description: 'git rev-parse HEAD' },
    tree_clean: { type: 'boolean', description: 'git status --porcelain 이 비어 있으면 true' },
  },
  required: ['allPassed', 'results', 'commit', 'tree_clean'],
}
const AGGREGATE_SCHEMA = {
  type: 'object',
  properties: {
    verdict: { type: 'string', description: '전체 판정 한 단락 — 완결된 문어체 한국어' },
    conflicts: { type: 'array', items: { type: 'object', properties: { ids: { type: 'array', items: { type: 'string' } }, reason: { type: 'string' } }, required: ['ids', 'reason'] } },
    coverage_gaps: { type: 'array', items: { type: 'string' } },
    commit: { type: 'string' },
    tree_clean: { type: 'boolean' },
  },
  required: ['verdict', 'conflicts', 'coverage_gaps', 'commit', 'tree_clean'],
}
const RECORD_SCHEMA = { type: 'object', properties: { path: { type: 'string' }, count: { type: 'integer' } }, required: ['path', 'count'] }
const CHECK_SCHEMA = { type: 'object', properties: { path: { type: 'string' }, count: { type: 'integer' }, ids: { type: 'array', items: { type: 'string' } } }, required: ['path', 'count', 'ids'] }
```

**(d) `const COMMON = ...`부터 `const REVIEWERS = [ ... ]` 끝까지를 다음으로 바꾼다.**

```js
const CANON = `${REPO}/agent-principles.md`
const COMMON = `너는 disciplined-coder 플러그인 저장소(${REPO})를 감사하는 읽기 전용 렌즈다.
이 저장소는 그 플러그인 자체의 소스다 — 플러그인이 남에게 강제하는 원칙을 자기 자신이 지키는지 검증한다.
먼저 ${CANON} (원칙 정본)을 읽고, 읽고 적용한 원칙 ID를 principles_applied 에 적어라. 문서 밖에서 연 파일은 read 에 적어라.
규칙: (1) 파일을 직접 읽고 실제 인용을 증거로 제시하라 — 추측 금지. (2) 어떤 파일도 수정하지 마라.
(3) 저장소의 어떤 파일에도 쓰지 마라 — 발견은 구조화 리턴으로만 보고한다. (4) 발견은 최대 10건 — 확신 높은 순으로. 없으면 빈 배열이 정직한 답이다.
(5) 각 발견의 title과 detail은 완결된 문장으로 쓴다. (6) 서브에이전트를 새로 열지 마라.`
// 문서별 렌즈 프롬프트 — 렌즈 SKILL.md 의 레퍼런스 프롬프트를 그대로 적용하게 하고 정본 경로와 principles_applied 만 더한다.
function lensPrompt(lens, target) {
  const purpose = lens === 'lens-readability' ? `\n[이 문서가 전달하려는 것]\n${target.purpose}\n` : ''
  return `${COMMON}
렌즈: ${REPO}/skills/${lens}/SKILL.md 를 읽고 그 레퍼런스 프롬프트와 체크리스트를 그대로 적용하라. 검토 대상: ${REPO}/${target.path} 전체.${purpose}
source(진실): ${REPO} 의 scripts/*.sh, hooks/*, skills/*/SKILL.md, .claude-plugin/*, .claude/workflows/*. 문서가 주장하는 것이 실제와 어긋나면 발견이다.`
}
const WHOLE_LENSES = [
  { key: 'lens-adversarial', prompt: `${COMMON}
렌즈: ${REPO}/skills/lens-adversarial/SKILL.md 를 읽고 그대로 적용하라(가드 포함: 기능 추가 제안 금지·근거 필수). 검토 대상: 정본의 절 전부와 hooks/·scripts/·skills/·.claude/workflows/ 설계 전체 — 절 제목을 파일에서 읽어 목록을 만들고(\`grep '^## ' agent-principles.md\`) 그 전부를 훑어라. 실패 모드, 과설계, 비가역, 자기모순을 공격적으로 찾아라.` },
  { key: 'plugin-compliance', prompt: `${COMMON}
차원: domain-plugin 자기준수 — ${REPO}/skills/domain-plugin/SKILL.md 를 읽고, .claude-plugin/*, hooks/hooks.json, commands/·skills/ frontmatter 가 그 처방을 지키는지 감사하라. 스킬의 주장 자체가 실측과 다르면 그것도 발견이다(MEASURE-FIRST).` },
]
```

**(e) `phase('테스트')`부터 리뷰 블록의 `if (deadLenses.length > 0) log(...)` 줄까지를 다음으로 바꾼다.**

```js
// ---------- 준비 ----------
phase('준비')
const rc = await agent(
  `${REPO}/.claude-plugin/plugin.json 을 읽어 name 값을 돌려줘라. 파일이 없거나 읽을 수 없으면 빈 문자열을 돌려줘라. 아무 파일도 쓰지 마라.`,
  { label: 'repo-check', phase: '준비', schema: REPO_CHECK_SCHEMA, effort: 'low' }
)
if (!rc || rc.name !== 'disciplined-coder') {
  log(`이 레포는 disciplined-coder 가 아니다(name=${rc ? rc.name : 'null'}) — 아무것도 쓰지 않고 멈춘다`)
  return { aborted: true, reason: 'not-disciplined-coder', name: rc ? rc.name : null }
}
const tg = await agent(
  `너는 대상 도출 에이전트다. ${REPO} 에서 다음을 실행하고 결과를 구조화해 돌려줘라. 아무 파일도 쓰지 마라.
- \`date +%F\` 로 오늘 날짜를 얻는다.
- \`bash scripts/audit_targets.sh --limit\` 로 문턱 값을, \`bash scripts/audit_targets.sh\` 로 조각 목록(경로<TAB>시작 줄<TAB>끝 줄)을 얻어 fragments 에 그대로 옮긴다. 경로는 스크립트가 낸 레포 상대경로 그대로 적는다.
- 회차 이름은 <날짜>-${EXECUTOR} 이고, docs/superpowers/reviews/ 아래에 같은 이름의 폴더나 .md 가 이미 있으면 -2, -3 처럼 회차를 붙여 앞 회차를 덮지 않는다.
- 조각의 경로를 문서 단위로 모아, 문서마다 ${REPO}/skills/project-doc-audit/SKILL.md 의 「렌즈 배정 기준」 물음 넷에 답해 lenses 를 정하고 그 답을 reason 에 적는다. 이 절차에서 lens-consistency 는 문서별로 걸지 않는다. lens-readability 를 걸 문서에는 purpose(읽는 사람과 그 사람이 무엇을 할 수 있어야 하는지)를 한 줄로 적고, 못 적겠으면 purpose 를 비우고 lens-readability 를 넣지 않고 reason 에 그 이유를 적는다.
- 배정은 무엇으로 만들어졌는지나 어느 폴더에 있는지로 정하지 않는다.`,
  { label: 'targets', phase: '준비', schema: TARGETS_SCHEMA }
)
if (!tg) throw new Error('대상 도출 에이전트가 응답하지 않았다 — 회차를 시작하지 않는다')
ROUND = tg.round
const REVIEWS = `${REPO}/docs/superpowers/reviews`
const DIR = `${REVIEWS}/${ROUND}`
log(`회차 ${ROUND}: 대상 ${tg.targets.length}건, 조각 ${tg.fragments.length}개, 문턱 ${tg.limit}자`)

const machinePromise = agent(
  `${COMMON}
너만 예외적으로 실행 권한이 있다(파일 수정은 여전히 금지). ${REPO} 에서 다음을 실행하고 결과를 보고하라:
- scripts/test_*.sh 를 전부. 목록도 실행 명령도 여기 적지 않는다 — ${REPO}/CLAUDE.md 가 그 명령의 정본이니 그 파일을 읽고 거기 적힌 형태 그대로 돌려라. 앞 스크립트의 실패가 마지막 스크립트의 종료 코드에 묻히는 형태로 바꿔 쓰지 마라.
- claude plugin validate ./ (non-strict)
- git rev-parse HEAD 를 commit 에, git status --porcelain 이 비어 있으면 tree_clean=true 를 적어라. 감사가 도는 동안 작업 트리를 고치지 않는다는 약속의 검사가 이 지문이다.
어떤 스크립트를 실제로 돌렸는지 이름을 모두 results 에 적어라. 하나도 못 찾았으면 그 사실 자체가 FAIL이다. 환경 원인의 실패는 그 사실을 보고하라(수정 시도 금지).`,
  { label: 'machine-checks', phase: '준비', schema: MACHINE_SCHEMA }
)

// ---------- 기록 ----------
// 기록자는 파일 하나마다 한 번 띄우고 검수자가 그 파일을 센다. 실패 단위가 파일 하나다.
// run.json 은 걸음마다 다시 쓰고, 검수를 지난 뒤에만 completed 를 참으로 놓고 그때 봉인한다. 요약문은 봉인하지 않는다.
const run = {
  schema: SCHEMA_VERSION, executor: EXECUTOR, commit: null, tree_clean: null, tree_changed: false,
  completed: false, steps_done: ['repo-check'], targets: tg.targets, topic_groups: 0, counts_by_lens: {},
  verdict_counts: { confirmed: 0, rejected: 0, undetermined: 0, derived: 0 },
  narrowed: 0, unlabeled: 0, dead_agents: {}, machine_checks: null, stale_rounds: [],
}
const COUNT_RULE = 'count 는 이렇게 센다 — JSON 에 findings 배열이 있으면 그 길이, items 배열이 있으면 그 길이, steps_done 배열이 있으면 그 길이, 마크다운은 파일이 있으면 1, 파일이 없으면 -1.'
async function writeFile(step, f) {  // f: { name, content(object|string), count, ids|null, seal }
  const path = `${DIR}/${f.name}`
  const body = typeof f.content === 'string' ? { text: f.content } : { json: f.content }
  const wrote = await agent(
    `너는 기록자다. 파일 ${path} 를 만들어 내용을 한 글자도 바꾸지 말고 써라(폴더 ${DIR} 가 없으면 만든다). json 이 있으면 들여쓰기 1의 JSON 으로, text 가 있으면 그 문자열을 그대로 쓴다. 파일은 파이썬으로 쓴다.${f.seal ? `\n쓴 뒤 \`bash ${REPO}/scripts/seal_reviews.sh "${path}"\` 로 봉인한다.` : ''}
${COUNT_RULE} path 와 count 를 돌려줘라.
${JSON.stringify(body)}`,
    { label: `record:${step}:${f.name}`, phase: '기록', schema: RECORD_SCHEMA, effort: 'low' }
  )
  if (!wrote) throw new Error(`기록자가 ${step} 걸음의 ${f.name} 에서 응답하지 않았다 — 회차를 실패로 끝낸다`)
  const chk = await agent(
    `너는 검수자다. 파일 ${path} 를 열어 count 와 ids(항목의 id 값을 순서대로, 없으면 빈 배열)를 세어 돌려줘라. path 는 받은 문자열 그대로 돌려준다. 파일을 고치지 마라. ${COUNT_RULE}`,
    { label: `check:${step}:${f.name}`, phase: '기록', schema: CHECK_SCHEMA, effort: 'low' }
  )
  if (!chk) throw new Error(`검수자가 ${step} 걸음의 ${f.name} 에서 응답하지 않았다 — 회차를 실패로 끝낸다`)
  const idsOk = !f.ids || JSON.stringify(chk.ids) === JSON.stringify(f.ids)
  if (chk.count !== f.count || !idsOk) throw new Error(`기록 검수 불일치: ${f.name} — 넘긴 ${f.count}건/${f.ids ? f.ids.length : '-'}id, 읽은 ${chk.count}건/${chk.ids.length}id`)
}
async function writeRun(final) {
  if (final) {
    // 검수를 먼저 — 지금까지의 run.json 을 검수자가 읽어 끝난 걸음 수가 맞아야 completed 를 참으로 놓는다.
    await writeFile('record', { name: 'run.json', content: run, count: run.steps_done.length, ids: null, seal: false })
    run.completed = true
  }
  await writeFile('record', { name: 'run.json', content: run, count: run.steps_done.length, ids: null, seal: final })
}
async function record(step, files) {
  if (!STEPS.includes(step)) throw new Error(`알 수 없는 걸음 ${step}`)
  for (const f of files) await writeFile(step, { seal: true, ...f })
  if (!run.steps_done.includes(step)) run.steps_done.push(step)
  await writeRun(false)
}
async function writeSummary(text) {
  // 요약문은 봉인하지 않는다 — 호출자가 뿌리와 물음을 붙인 뒤 seal_reviews.sh 로 봉인한다.
  const path = `${REVIEWS}/${ROUND}.md`
  const wrote = await agent(
    `너는 기록자다. 파일 ${path} 를 만들어 아래 text 를 한 글자도 바꾸지 말고 써라. 봉인하지 않는다. ${COUNT_RULE} path 와 count 를 돌려줘라.
${JSON.stringify({ text })}`,
    { label: 'record:summary', phase: '기록', schema: RECORD_SCHEMA, effort: 'low' }
  )
  if (!wrote || wrote.count !== 1) throw new Error('기록자가 요약문을 쓰지 못했다 — 회차를 실패로 끝낸다')
}
await record('targets', [])

// ---------- 리뷰 ----------
phase('리뷰')
const deadLenses = []
const perDoc = tg.targets.flatMap(t => t.lenses.map(lens => ({ lens, target: t })))
const lensCounter = {}
const reviewJobs = perDoc.map(j => () => {
  lensCounter[j.lens] = (lensCounter[j.lens] || 0) + 1
  const n = lensCounter[j.lens]
  return agent(lensPrompt(j.lens, j.target), { label: `${j.lens}:${j.target.path}`, phase: '리뷰', schema: LENS_SCHEMA })
    .then(res => ({ key: j.lens, file: `${j.lens}-${n}.json`, target: j.target.path, res }))
    .catch(() => ({ key: j.lens, file: `${j.lens}-${n}.json`, target: j.target.path, res: null }))
}).concat(WHOLE_LENSES.map(w => () =>
  agent(w.prompt, { label: w.key, phase: '리뷰', schema: LENS_SCHEMA })
    .then(res => ({ key: w.key, file: `${w.key}-1.json`, target: '(전체)', res }))
    .catch(() => ({ key: w.key, file: `${w.key}-1.json`, target: '(전체)', res: null }))
))
const reviews = (await parallel(reviewJobs)).filter(Boolean)
for (const r of reviews) if (!r.res) deadLenses.push(`${r.key}:${r.target}`)
const all = reviews.filter(r => r.res).flatMap(r => r.res.findings.map(f => ({ ...f, lens: r.key, target: r.target })))
run.dead_agents.review = deadLenses
log(`리뷰 완료: 호출 ${reviews.length}건에서 원시 발견 ${all.length}건`)
if (deadLenses.length > 0) log(`⚠️ 응답하지 않은 렌즈 ${deadLenses.length}건: ${deadLenses.join(', ')} — 이 감사의 커버리지가 그만큼 좁다`)
await record('review', reviews.filter(r => r.res).map(r => ({ name: r.file, content: { lens: r.key, target: r.target, ...r.res }, count: r.res.findings.length, ids: null })))
```

**(f) 중복제거 블록(Task 2)은 그대로 두고 그 마지막 `log(...)` 줄 뒤에 더한다.**

```js
for (const k of [...new Set(all.map(f => f.lens))]) run.counts_by_lens[k] = { raw: all.filter(f => f.lens === k).length, unique: deduped.filter(f => lensesOf(f).length === 1 && lensesOf(f)[0] === k).length }
await record('dedup', [])
```

**(g) 반박검증 블록의 `const judged = await parallel(`를 `const judged = (await parallel(`로 바꾸고, `.then` 안에서 `return { id: findingId(ROUND, i + 1), ...f, ...}`의 `...f`를 `...rest`로 바꾸며 그 앞에 `const { raw_index, ...rest } = f`를 둔다. 블록 끝 `)`를 `)).filter(Boolean)`로 바꾼다. 그 뒤의 `const confirmed = judged.filter(Boolean)...` 세 줄에서 `.filter(Boolean)`을 뺀다. 미판정 경고 `log` 줄 뒤에 더한다.**

```js
run.verdict_counts = { confirmed: confirmed.length, rejected: rejected.length, undetermined: undetermined.length, derived: 0 }
run.dead_agents.verify = judged.filter(j => j.missingVotes > 0).map(j => j.id)
const findingsFile = { schema: SCHEMA_VERSION, findings: judged.filter(j => j.status !== STATUS[1]), rejected: rejected.map(r => ({ id: r.id, title: r.title, reasons: r.verdicts.map(v => v.reason) })) }
// 첫 회차에는 대조할 지난 회차가 없다. 덩어리 4가 이 자리를 실제 대조로 바꾼다.
const diffFile = { schema: SCHEMA_VERSION, no_prior_round: true, items: [] }
await record('verify', [
  { name: 'findings.json', content: findingsFile, count: findingsFile.findings.length, ids: findingsFile.findings.map(f => f.id) },
  { name: 'diff.json', content: diffFile, count: diffFile.items.length, ids: null },
])
```

**(h) `const test = await testPromise`부터 파일 끝까지를 다음으로 바꾼다.** Task 2가 넣은 `counts_by_lens`·`run` 정의는 (e)의 `run`과 (f)로 옮겨졌으므로 여기서 지운다.

```js
const machine = await machinePromise
run.machine_checks = machine ? { allPassed: machine.allPassed, results: machine.results } : null
run.commit = machine ? machine.commit : null
run.tree_clean = machine ? machine.tree_clean : null
if (!machine) run.dead_agents.machine = true
await record('machine-checks', [])

phase('집계')
const aggregate = await agent(
  `너는 집계자다. ${REPO}/skills/meta-aggregate/SKILL.md 를 읽고 그 방식대로, 아래 자기감사 결과의 구조적 건강성을 점검하라 — 확정 발견 간 상충(같은 곳을 두고 반대로 판정한 짝)과 커버리지 공백(봤어야 하는데 아무도 안 본 대상이나 렌즈)과 전체 판정. 발견 내용 재판단은 금지(검증 단계가 끝냈다).
먼저 ${REPO} 에서 git rev-parse HEAD 와 git status --porcelain 을 다시 실행해 commit 과 tree_clean 에 적어라. 아래 기계 검사의 지문과 다르면 「감사 도중 작업 트리가 바뀌었다 — 이 회차의 판정은 움직인 작업 트리에 대한 것이다」를 verdict 첫 문장으로 적어라.
기계 검사: ${JSON.stringify(run.machine_checks)} (commit ${run.commit}, tree_clean ${run.tree_clean})
확정 발견 (${confirmed.length}건): ${JSON.stringify(confirmed)}
기각 (${rejected.length}건): ${JSON.stringify(findingsFile.rejected)}
미판정 (${undetermined.length}건 — 검증자가 응답하지 않은 것이지 반박당한 것이 아니다. 커버리지 공백으로 다뤄라): ${JSON.stringify(undetermined.map(r => ({ id: r.id, title: r.title })))}
응답하지 않은 렌즈 호출: ${JSON.stringify(deadLenses)}`,
  { label: 'meta-aggregate', phase: '집계', schema: AGGREGATE_SCHEMA }
)
if (!aggregate) run.dead_agents.aggregate = true
run.tree_changed = !!(aggregate && machine && (aggregate.commit !== machine.commit || aggregate.tree_clean !== machine.tree_clean))
await record('aggregate', [])

// ---------- 요약문 ----------
// 세 파일에서 도출되는 사실만 적는다. 되풀이되는 뿌리와 사용자에게 올릴 물음은 판단이라 호출자가 끝에 붙인 뒤 봉인한다.
const line = (t) => `- ${t}`
const derivedFindings = findingsFile.findings.filter(f => f.status === STATUS[3])
const summary = [
  `# 자기감사 회차 ${ROUND}`,
  '',
  `실행체 ${EXECUTOR}(스키마 ${SCHEMA_VERSION})가 커밋 ${run.commit || '(측정 실패)'}${run.tree_clean === false ? '(작업 트리에 미커밋 변경 있음)' : ''} 위에서 돌았다. 확정 ${confirmed.length}건, 기각 ${rejected.length}건, 미판정 ${undetermined.length}건, 도출 ${derivedFindings.length}건이다.${run.tree_changed ? ' 감사 도중 작업 트리가 바뀌었다.' : ''} 구조화된 기록은 같은 이름의 폴더에 있다.`,
  '',
  '## 범위와 배정',
  '',
  ...tg.targets.map(t => line(`\`${t.path}\` — ${t.lenses.join(', ') || '(문서별 렌즈 없음)'}. ${t.reason}`)),
  line(`전체 렌즈 — ${WHOLE_LENSES.map(w => w.key).join(', ')}`),
  line(`조각 ${tg.fragments.length}개, 문턱 ${tg.limit}자`),
  '',
  '## 기계 검사',
  '',
  ...(machine ? machine.results.map(r => line(`${r.name} — ${r.passed ? 'PASS' : 'FAIL'}. ${r.summary}`)) : [line('기계 검사 에이전트가 응답하지 않았다')]),
  '',
  '## 집계',
  '',
  aggregate ? aggregate.verdict : '집계 에이전트가 응답하지 않았다.',
  '',
  ...(aggregate && aggregate.conflicts.length ? aggregate.conflicts.map(c => line(`상충 ${c.ids.join(' · ')} — ${c.reason}`)) : [line('상충 없음')]),
  ...(aggregate && aggregate.coverage_gaps.length ? aggregate.coverage_gaps.map(g => line(`커버리지 공백 — ${g}`)) : [line('커버리지 공백 없음')]),
  ...(deadLenses.length ? [line(`응답하지 않은 렌즈 호출 — ${deadLenses.join(', ')}`)] : []),
  '',
  '## 확정 발견',
  '',
  ...(confirmed.length ? confirmed.map(f => line(`\`${f.id}\` ${f.title} (${f.file})`)) : [line('없음')]),
  '',
  '## 회차 대조',
  '',
  ...(diffFile.no_prior_round ? [line('대조할 지난 회차 없음')] : [line(`잔존 ${diffFile.items.filter(i => i.verdict === '잔존').length}건, 해소 ${diffFile.items.filter(i => i.verdict === '해소').length}건, 미판정 ${diffFile.items.filter(i => i.verdict === '미판정').length}건`)]),
  ...(run.stale_rounds.length ? [line(`끊긴 회차 — ${run.stale_rounds.join(', ')}`)] : []),
  '',
  '## 도출된 발견',
  '',
  ...(derivedFindings.length ? derivedFindings.map(f => line(`\`${f.id}\` ${f.title} (${f.evidence})`)) : [line('없음')]),
  '',
].join('\n')
await writeSummary(summary)
if (!run.steps_done.includes('record')) run.steps_done.push('record')
await writeRun(true)

return {
  round: ROUND, dir: DIR, run,
  confirmed: confirmed.map(f => ({ id: f.id, title: f.title, file: f.file })),
  rejected: findingsFile.rejected, undetermined: undetermined.map(f => ({ id: f.id, title: f.title })),
  aggregate,
}
```

`.claude-plugin/plugin.json`의 `"keywords"` 줄 앞에 더한다.

```json
  "workflows": ["./.claude/workflows/self-audit.js"],
```

- [ ] **Step 4: 돌려서 통과를 확인한다**

Run: `node --check .claude/workflows/self-audit.js && bash scripts/test_self_audit.sh 2>&1 | grep -E 'FAIL|PASS='; claude plugin validate ./`
Expected: `FAIL=0`. validate가 version 경고 하나만 낸다.

- [ ] **Step 5: 전체 테스트를 돌리고 커밋한다**

```bash
git add .claude/workflows/self-audit.js .claude-plugin/plugin.json scripts/test_self_audit.sh
git commit -m "실행체가 레포를 확인하고 대상을 도출해 문서별 렌즈를 배정하며 걸음마다 기록자와 검수자로 파일 하나씩 봉인한다"
```

### Task 7: 첫 회차를 돌리고 기록 계약 테스트와 절차 문서를 맞춘다

**Files:**
- Modify: `scripts/test_self_audit.sh`
- Modify: `skills/project-doc-audit/SKILL.md:9-20` (걸음 표), `:25` (대상 목록), `:66-78` (통합 기록), `:80-81` (집계)
- Create (실행체가 만든다): `docs/superpowers/reviews/<날짜>-self-audit.md`와 같은 이름의 폴더

**Interfaces:**
- Consumes: Task 6의 실행체.
- Produces: `completed`가 참인 첫 회차 기록(`run.json`·`findings.json`·`diff.json`·렌즈 원본·요약문). 덩어리 4의 `audit_prior_rounds.sh`가 이 폴더를 고른다.

- [ ] **Step 1: 실패하는 테스트를 더한다**

`scripts/test_self_audit.sh`의 `echo "----"` 앞에 더한다. `LATEST`·`PDA`·`KO_NUM`은 뒤 Task의 블록이 쓰므로 이 블록이 먼저 있어야 한다.

```bash
echo "[회차 기록 — completed 인 최신 폴더의 파일 형태]"
RV="$HERE/docs/superpowers/reviews"
# 앵커: completed 가 참인 run.json 을 가진 폴더가 하나 이상 있어야 한다. 비면 아래 단언이 무의미해지므로 FAIL 이다.
LATEST="$(for d in "$RV"/*/; do [ -f "$d/run.json" ] || continue; json_run 'import json,sys; d=json.load(open(sys.argv[1],encoding="utf-8")); sys.exit(0 if d.get("completed") is True else 1)' "$d/run.json" 2>/dev/null && printf '%s\n' "${d%/}"; done | sort | tail -1)"
check "completed 인 회차 폴더가 하나 이상 있다"      "[ -n \"\$LATEST\" ]"
rj() { json_run "$1" "$LATEST/$2"; }   # $1=프로그램, $2=폴더 안 파일
check "run.json 이 파싱된다"                          "[ -n \"\$LATEST\" ] && rj 'import json,sys; json.load(open(sys.argv[1],encoding=\"utf-8\"))' run.json"
check "findings.json 이 파싱된다"                     "[ -n \"\$LATEST\" ] && rj 'import json,sys; json.load(open(sys.argv[1],encoding=\"utf-8\"))' findings.json"
check "diff.json 이 파싱되고 no_prior_round 를 갖는다" "[ -n \"\$LATEST\" ] && rj 'import json,sys; d=json.load(open(sys.argv[1],encoding=\"utf-8\")); sys.exit(0 if \"no_prior_round\" in d and isinstance(d.get(\"items\"),list) else 1)' diff.json"
check "run.json 이 정한 칸을 갖는다"                  "[ -n \"\$LATEST\" ] && rj 'import json,sys; d=json.load(open(sys.argv[1],encoding=\"utf-8\")); need=[\"schema\",\"executor\",\"commit\",\"tree_clean\",\"tree_changed\",\"completed\",\"steps_done\",\"targets\",\"topic_groups\",\"counts_by_lens\",\"verdict_counts\",\"narrowed\",\"unlabeled\",\"dead_agents\",\"machine_checks\",\"stale_rounds\"]; sys.exit(0 if all(k in d for k in need) else 1)' run.json"
check "findings.json 의 status 가 닫힌 집합 안이다"   "[ -n \"\$LATEST\" ] && rj 'import json,sys; d=json.load(open(sys.argv[1],encoding=\"utf-8\")); sys.exit(0 if all(f.get(\"status\") in (\"confirmed\",\"rejected\",\"undetermined\",\"derived\") for f in d[\"findings\"]) else 1)' findings.json"
check "findings.json 의 id 가 유일하다"               "[ -n \"\$LATEST\" ] && rj 'import json,sys; d=json.load(open(sys.argv[1],encoding=\"utf-8\")); ids=[f[\"id\"] for f in d[\"findings\"]]; sys.exit(0 if len(ids)==len(set(ids)) else 1)' findings.json"
check "findings.json 의 verdicts 가 isReal 을 갖는다" "[ -n \"\$LATEST\" ] && rj 'import json,sys; d=json.load(open(sys.argv[1],encoding=\"utf-8\")); sys.exit(0 if all(all(\"isReal\" in v and \"reason\" in v for v in f.get(\"verdicts\",[])) for f in d[\"findings\"] if f.get(\"status\")!=\"derived\") else 1)' findings.json"
check "diff.json 의 판정이 닫힌 집합 안이다"           "[ -n \"\$LATEST\" ] && rj 'import json,sys; d=json.load(open(sys.argv[1],encoding=\"utf-8\")); sys.exit(0 if all(i.get(\"verdict\") in (\"잔존\",\"해소\",\"미판정\") for i in d[\"items\"]) else 1)' diff.json"
check "요약문이 폴더와 같은 이름으로 있다"            "[ -n \"\$LATEST\" ] && [ -f \"\$LATEST.md\" ]"
check "요약문에 고침·넘김 처분을 적지 않았다"          "[ -n \"\$LATEST\" ] && ! grep -qE '^- .*(고쳤다|넘겼다)' \"\$LATEST.md\""
check "폴더 안 파일이 전부 읽기 전용이다"              "[ -n \"\$LATEST\" ] && [ -z \"\$(find \"\$LATEST\" -type f -writable 2>/dev/null)\" ]"

echo "[절차 문서 — 걸음 표와 개수 문장이 맞는다]"
PDA="$HERE/skills/project-doc-audit/SKILL.md"
PDA_ROWS="$(awk '/^## 걸음/{f=1;next} f&&/^## /{exit} f&&/^\| [^|-]/{n++} END{print n-1}' "$PDA")"
PDA_SAID="$(LC_ALL=C.UTF-8 grep -oE '걸음은 [^ ]+이고' "$PDA" | head -1 | sed 's/걸음은 //; s/이고//')"
KO_NUM() { case "$1" in 하나) echo 1;; 둘) echo 2;; 셋) echo 3;; 넷) echo 4;; 다섯) echo 5;; 여섯) echo 6;; 일곱) echo 7;; 여덟) echo 8;; 아홉) echo 9;; 열) echo 10;; 열하나) echo 11;; 열둘) echo 12;; *) echo 0;; esac; }
check "걸음 표의 행 수와 '걸음은 N' 문장이 맞는다"     "[ \"\$PDA_ROWS\" = \"\$(KO_NUM \"\$PDA_SAID\")\" ]"
check "걸음 표에 중복 제거와 반박검증이 있다"          "grep -qF '| 중복을 제거한다 |' '$PDA' && grep -qF '| 반박검증한다 |' '$PDA'"
check "통합 기록이 파일 셋을 적는다"                  "grep -qF 'run.json' '$PDA' && grep -qF 'findings.json' '$PDA' && grep -qF 'diff.json' '$PDA'"
```

- [ ] **Step 2: 돌려서 실패를 확인한다**

Run: `bash scripts/test_self_audit.sh 2>&1 | grep -E 'FAIL|PASS='`
Expected: 회차 기록 단언 전부와 절차 문서 단언 둘("중복 제거와 반박검증"·"파일 셋")이 FAIL.

- [ ] **Step 3: 절차 문서를 고친다**

`skills/project-doc-audit/SKILL.md`의 걸음 절을 다음으로 바꾼다.

```markdown
## 걸음
걸음은 아홉이고 순서가 있다. 뿌리 찾기까지 가지 않고 멈추면 렌즈별 지적만 쌓이고, 같은 것을 문서 수만큼 고치게 된다.

| 걸음 | 적힌 곳 |
|---|---|
| 대상을 헤아린다 | 「감사 대상 고르기」 절 |
| 기계로 먼저 확인한다 | 「기계 검사 우선」 절 |
| 렌즈를 배정해 띄운다 | 「렌즈 배정 기준」과 「띄울 때 지킬 것」 절 |
| 중복을 제거한다 | 「중복 제거와 반박검증」 절 |
| 반박검증한다 | 「중복 제거와 반박검증」 절 |
| 결과를 기록에 남긴다 | 「통합 기록」 절 |
| 상충과 커버리지 공백을 표시한다 | 「집계」 절 |
| 되풀이되는 뿌리를 찾는다 | 「뿌리 찾기」 절 |
| 가른 목록을 넘긴다 | 「처분」 절 |
```

「감사 대상 고르기」의 대상 목록에서 "개발자용 설계 근거 문서, "를 지운다(실체가 없다). 「띄울 때 지킬 것」 절 뒤에 절을 하나 더한다.

```markdown
## 중복 제거와 반박검증
렌즈가 돌려준 원시 발견은 같은 실체를 여러 렌즈가 따로 낸 것이 섞여 있다. 중복제거 에이전트가 같은 실체를 하나로 병합하되 병합 항목마다 그것이 덮는 원시 발견의 번호를 돌려주고, 호출자는 모든 원시 발견이 정확히 한 항목에 들어갔는지 확인한다. 개수만 견주면 발견을 버려도 통과한다.

반박검증은 발견 하나마다 검증자 둘이다. 사실성 검증자는 인용이 실제 파일에 있는지를, 실질성 검증자는 인용한 원칙에 비추어 진짜 위반인지를 반박한다. 두 표가 모두 살아 있고 둘 다 진짜라면 확정, 하나라도 반박하면 기각, 표가 모자라면 미판정이다. 판정과 사유를 둘 다 남긴다. 검증자가 죽은 것과 반박당한 것을 가르는 칸이 `missingVotes`다.
```

「통합 기록」 절을 다음으로 바꾼다.

```markdown
## 통합 기록
기록 한 회차는 요약문 하나와 같은 이름의 폴더 하나다. 이름 규칙은 `domain-docs`의 문서 타입 표 기록 행을 따른다. 폴더 안에는 파일 셋과 렌즈별 원본(`<렌즈>-<띄운 횟수>.json`)을 둔다.

- **`run.json`** — 회차의 사실이다. 스키마 버전, 실행체 이름, 커밋 지문과 작업 트리 상태, 끝난 걸음 목록, 대상 문서마다 건 렌즈와 그 근거, 렌즈별 발견 수와 고유 발견 수, 판정 개수, 응답하지 않은 에이전트, 기계 검사 요약, 끊긴 회차 이름을 담는다. 걸음이 끝날 때마다 다시 쓰고, 검수를 지난 뒤에만 `completed`를 참으로 놓고 그때 봉인한다.
- **`findings.json`** — 반박검증을 거친 발견과 도출된 발견 전부와, 기각의 제목과 사유다. 발견마다 회차 이름과 일련번호로 된 `id`가 있다.
- **`diff.json`** — 지난 회차 발견마다 잔존·해소·미판정 가운데 하나를 적은 대조 결과다. 대조할 지난 회차가 없으면 비어 있고 `no_prior_round`가 참이다.

요약문은 세 파일에서 도출되는 사실만 적는다. 범위와 배정, 기계 검사, 판정 개수, 집계가 표시한 상충과 커버리지 공백, 확정 발견 목록, 회차 대조 개수, 도출된 발견 목록이다. 고쳤는지와 넘겼는지와 그 뒤의 상태는 적지 않는다. 그것은 다음 회차의 대조가 그때 도출한다. 되풀이되는 뿌리와 사용자에게 올릴 물음은 판단이라 기록자는 쓰지 않고, 호출자가 요약문 끝에 붙인 뒤 `scripts/seal_reviews.sh`로 봉인한다.

기록은 걸음마다 파일 하나씩 쓴다. 받은 것을 그때 바로 파일에 적어야 회차가 끊겨도 앞 걸음의 결과가 남고, 파일 하나가 실패 단위가 된다. 기록자 에이전트가 쓰고 다른 에이전트가 항목 수와 `id`를 세어 호출자가 넘긴 것과 견준다.
```

「집계」 절의 마지막 문장 "집계 결과는 「통합 기록」의 뿌리 절 앞에 적는다."를 "집계 결과는 요약문의 집계 절에 적는다."로 바꾼다.

- [ ] **Step 4: 첫 회차를 돌린다**

Workflow 도구로 `.claude/workflows/self-audit.js`를 돌린다(`Workflow({ scriptPath: '.claude/workflows/self-audit.js' })` 또는 `name: 'self-audit'`). 회차가 도는 동안 작업 트리를 고치지 않는다. 끝나면 리턴의 `round`와 `dir`를 확인하고, 요약문 `docs/superpowers/reviews/<round>.md`를 열어 되풀이되는 뿌리와 사용자에게 올릴 물음과 워크플로 진행 표시가 보여 준 호출 수를 끝에 붙인 뒤 봉인한다.

```bash
bash scripts/seal_reviews.sh "docs/superpowers/reviews/<round>.md"
```

회차가 중간에 끊기면(`completed`가 참이 아니면) 그 폴더를 지우지 말고 다시 돌린다. 새 회차는 `-2` 이름을 받는다. 끊긴 폴더는 커밋하지 않는다 — 커밋에 담는 것은 `completed`가 참인 이번 회차의 폴더와 요약문뿐이다.

- [ ] **Step 5: 돌려서 통과를 확인한다**

Run: `bash scripts/test_self_audit.sh 2>&1 | grep -E 'FAIL|PASS='`
Expected: `FAIL=0`.

- [ ] **Step 6: 전체 테스트를 돌리고 커밋한다**

Run: 전체 테스트 명령. `scripts/test_docs_drift.sh`의 기록 검사는 새 파일(`??`)만 있으므로 통과한다.

```bash
git add scripts/test_self_audit.sh skills/project-doc-audit/SKILL.md "docs/superpowers/reviews/<round>.md" "docs/superpowers/reviews/<round>/"
git commit -m "첫 구조화 회차 기록을 남기고 기록 파일의 계약 테스트와 절차의 걸음 표를 맞춘다"
```

---

## 덩어리 4 — 회차 대조

이 덩어리가 끝나면 실행체는 `scripts/audit_prior_rounds.sh`가 고른 지난 회차의 발견을 하나씩 대조해 `diff.json`을 채우고, 재발을 `derived` 발견으로 만들며, 끊긴 회차를 `stale_rounds`에 적는다. 절차 문서의 걸음 표에 「회차를 대조한다」가 들어간다.

### Task 8: `audit_prior_rounds.sh`

**Files:**
- Create: `scripts/audit_prior_rounds.sh`
- Modify: `scripts/test_self_audit.sh`

**Interfaces:**
- Produces: `bash scripts/audit_prior_rounds.sh [실행체 이름] [--root DIR] [--stale]` → `run.json`의 `executor`가 같고 `completed`가 참인 폴더를 경로 정렬해 최근 둘을 최신부터 한 줄에 하나씩 낸다(폴더 이름만). `--stale`이면 `run.json`이 있으나 `completed`가 참이 아닌 폴더 이름을 낸다.

- [ ] **Step 1: 실패하는 테스트를 더한다**

`scripts/test_self_audit.sh`의 `echo "----"` 앞에 더한다.

```bash
echo "[audit_prior_rounds.sh — 지난 회차 고르기]"
APR="$HERE/scripts/audit_prior_rounds.sh"
check "스크립트가 있다"                                "[ -f '$APR' ]"
APR_T="$(mktemp -d)"; mkdir -p "$APR_T/docs/superpowers/reviews"
mk_round() { mkdir -p "$APR_T/docs/superpowers/reviews/$1"; printf '{"executor":"%s","completed":%s}\n' "$2" "$3" > "$APR_T/docs/superpowers/reviews/$1/run.json"; }
mk_round 2026-09-01-self-audit self-audit true
mk_round 2026-09-02-self-audit self-audit true
mk_round 2026-09-02-self-audit-2 self-audit false
mk_round 2026-09-03-self-audit self-audit true
mk_round 2026-09-03-other other true
mkdir -p "$APR_T/docs/superpowers/reviews/2026-08-30-legacy"   # run.json 없음 — 옛 기록
APR_OUT="$(bash "$APR" self-audit --root "$APR_T" 2>/dev/null || true)"
check "completed 인 같은 실행체의 최근 둘을 최신부터 낸다" "[ \"\$(printf '%s' \"\$APR_OUT\" | tr '\n' ' ' | sed 's/ *$//')\" = '2026-09-03-self-audit 2026-09-02-self-audit' ]"
check "다른 실행체와 끊긴 회차와 옛 기록은 빠진다"      "! printf '%s' \"\$APR_OUT\" | grep -qE 'other|self-audit-2|legacy'"
APR_STALE="$(bash "$APR" self-audit --root "$APR_T" --stale 2>/dev/null || true)"
check "--stale 이 끊긴 회차만 낸다"                     "[ \"\$APR_STALE\" = '2026-09-02-self-audit-2' ]"
check "기본 실행체 이름은 self-audit 이다"              "grep -qF 'EXEC=\"self-audit\"' '$APR'"
```

- [ ] **Step 2: 돌려서 실패를 확인한다**

Run: `bash scripts/test_self_audit.sh 2>&1 | grep -E 'prior|FAIL|PASS='`
Expected: 블록 단언 다섯이 FAIL.

- [ ] **Step 3: 스크립트를 쓴다**

`scripts/audit_prior_rounds.sh`:

```bash
#!/usr/bin/env bash
# 대조할 지난 회차를 고른다 — run.json 의 executor 가 같고 completed 가 참인 폴더를 경로 정렬해 최근 둘을
# 최신부터 낸다. --stale 이면 run.json 은 있으나 completed 가 참이 아닌 폴더(끊긴 회차)를 낸다.
# 고르기를 LLM 에 두지 않는다 — 후보를 고르는 일은 LLM 밖에 둔다. run.json 이 없는 옛 기록은 회차로 세지 않는다.
# 사용: audit_prior_rounds.sh [실행체 이름] [--root 레포 경로] [--stale]
set -euo pipefail
HERE="$(cd "$(dirname "$0")/.." && pwd)"
. "$HERE/scripts/_json_valid.sh"   # json_run — 파이썬 이름은 여기가 고른다
EXEC="self-audit"; ROOT="$HERE"; STALE=0
while [ "$#" -gt 0 ]; do
  case "$1" in
    --root) ROOT="$2"; shift 2 ;;
    --stale) STALE=1; shift ;;
    *) EXEC="$1"; shift ;;
  esac
done
RV="$ROOT/docs/superpowers/reviews"
[ -d "$RV" ] || exit 0
json_run '
import json, os, sys
rv, exec_name, stale = sys.argv[1], sys.argv[2], sys.argv[3] == "1"
done, broken = [], []
for name in sorted(os.listdir(rv)):
    p = os.path.join(rv, name, "run.json")
    if not os.path.isfile(p): continue
    try:
        d = json.load(open(p, encoding="utf-8"))
    except Exception:
        broken.append(name); continue
    if d.get("executor") != exec_name: continue
    (done if d.get("completed") is True else broken).append(name)
if stale:
    for n in broken: print(n)
else:
    for n in list(reversed(done))[:2]: print(n)
' "$RV" "$EXEC" "$STALE"
```

- [ ] **Step 4: 돌려서 통과를 확인하고 커밋한다**

Run: `bash scripts/test_self_audit.sh 2>&1 | grep -E 'FAIL|PASS='`
Expected: `FAIL=0`.

```bash
git add scripts/audit_prior_rounds.sh scripts/test_self_audit.sh
git commit -m "대조할 지난 회차와 끊긴 회차를 run.json 에서 고르는 스크립트를 둔다"
```

### Task 9: 대조 걸음과 `diff.json`과 재발 도출

**Files:**
- Modify: `.claude/workflows/self-audit.js` (`meta.phases`·`STEPS`·`TARGETS_SCHEMA`·대상 도출 프롬프트·`run` 초기화·반박검증 뒤에 대조 걸음·요약문)
- Modify: `skills/project-doc-audit/SKILL.md` (걸음 표에 한 행, 「통합 기록」 앞에 「회차 대조」 절)
- Modify: `scripts/test_self_audit.sh`
- Create (실행체가 만든다): 둘째 회차 `docs/superpowers/reviews/<날짜>-self-audit[-N].md`와 같은 이름의 폴더

**Interfaces:**
- Consumes: `scripts/audit_prior_rounds.sh`(Task 8), `record`·`findingId`·`STATUS`·`findingsFile`·`diffFile`(Task 6).
- Produces: `diff.json` `{ schema, no_prior_round, items: [{ prior_id, prior_round, title, file, evidence, consequence, verdict: '잔존'|'해소'|'미판정', reason, matched_id }] }`, `derived` 발견(`lens: 'round-diff'`), `run.stale_rounds`, 둘째 회차 기록.

- [ ] **Step 1: 실패하는 테스트를 더한다**

`scripts/test_self_audit.sh`의 `echo "----"` 앞에 더한다.

```bash
echo "[실행체 — 회차 대조]"
check "실행체가 audit_prior_rounds.sh 를 부른다"        "grep -qF 'audit_prior_rounds.sh' '$WF'"
check "대조 판정이 닫힌 집합이다"                       "grep -qF \"'잔존'\" '$WF' && grep -qF \"'해소'\" '$WF' && grep -qF \"'미판정'\" '$WF'"
check "재발을 round-diff 의 derived 발견으로 만든다"    "grep -qF \"lens: 'round-diff'\" '$WF' && grep -qF '이것을 막는 검사가 없다' '$WF'"
check "대조 걸음이 자기 phase 를 갖는다"                "grep -qF \"phase('대조')\" '$WF' && grep -qF \"title: '대조'\" '$WF'"
check "최신 회차의 diff.json 에 대조 항목이 있다"       "[ -n \"\$LATEST\" ] && rj 'import json,sys; d=json.load(open(sys.argv[1],encoding=\"utf-8\")); sys.exit(0 if d.get(\"no_prior_round\") is False and len(d[\"items\"])>0 else 1)' diff.json"
check "걸음 표에 회차 대조가 있다"                      "grep -qF '| 회차를 대조한다 |' '$PDA' && grep -qF '## 회차 대조' '$PDA'"
```

- [ ] **Step 2: 돌려서 실패를 확인한다**

Run: `bash scripts/test_self_audit.sh 2>&1 | grep -E 'FAIL|PASS='`
Expected: 새 단언 여섯이 FAIL.

- [ ] **Step 3: 실행체에 대조 걸음을 더한다**

`meta.phases`의 「반박검증」 뒤에 `{ title: '대조', detail: '지난 회차 발견마다 에이전트 하나가 잔존·해소를 판정하고 재발을 도출한다' },`를 더하고, `whenToUse`는 그대로 둔다(이미 `diff.json`을 적었다). `STEPS`를 `['repo-check', 'targets', 'machine-checks', 'review', 'dedup', 'verify', 'diff', 'aggregate', 'record']`로 바꾼다.

`TARGETS_SCHEMA`의 `properties`에 둘을 더하고 `required`에 `'prior_rounds', 'stale_rounds'`를 더한다.

```js
    prior_rounds: { type: 'array', items: { type: 'string' }, description: 'audit_prior_rounds.sh 의 출력 — 최신부터 최대 둘' },
    stale_rounds: { type: 'array', items: { type: 'string' }, description: 'audit_prior_rounds.sh --stale 의 출력' },
```

대상 도출 프롬프트의 마지막 줄 뒤에 더한다.

```
- \`bash scripts/audit_prior_rounds.sh ${EXECUTOR}\` 의 출력을 prior_rounds 에, \`bash scripts/audit_prior_rounds.sh ${EXECUTOR} --stale\` 의 출력을 stale_rounds 에 한 줄에 하나씩 옮긴다.
```

`run` 초기화의 `stale_rounds: []`를 `stale_rounds: tg.stale_rounds`로 바꾼다. 스키마 묶음에 더한다.

```js
const PRIOR_SCHEMA = {
  type: 'object',
  properties: {
    findings: { type: 'array', items: { type: 'object', properties: { id: { type: 'string' }, title: { type: 'string' }, file: { type: 'string' }, evidence: { type: 'string' }, consequence: { type: 'string' }, status: { type: 'string' } }, required: ['id', 'title', 'file', 'evidence', 'consequence', 'status'] } },
    diff_items: { type: 'array', items: { type: 'object', properties: { prior_id: { type: 'string' }, prior_round: { type: 'string' }, title: { type: 'string' }, file: { type: 'string' }, evidence: { type: 'string' }, consequence: { type: 'string' }, verdict: { type: 'string' } }, required: ['prior_id', 'prior_round', 'title', 'file', 'evidence', 'consequence', 'verdict'] } },
    prior_diff_items: { type: 'array', items: { type: 'object', properties: { prior_id: { type: 'string' }, verdict: { type: 'string' } }, required: ['prior_id', 'verdict'] } },
  },
  required: ['findings', 'diff_items', 'prior_diff_items'],
}
const DIFF_VERDICT_SCHEMA = {
  type: 'object',
  properties: {
    verdict: { type: 'string', enum: ['잔존', '해소'] },
    reason: { type: 'string', description: '잔존이면 지금 파일의 어디에 있는지 인용, 해소면 무엇이 바뀌었는지' },
    matched_id: { type: 'string', description: '이번 회차 발견과 같은 실체이면 그 id, 아니면 빈 문자열' },
  },
  required: ['verdict', 'reason', 'matched_id'],
}
```

반박검증 블록에서 `const diffFile = { ... }`와 그 위 주석 두 줄과 `await record('verify', [...])` 호출을 지우고, 그 자리에 다음을 넣는다.

```js
// ---------- 회차 대조 ----------
// 대조 대상은 셋을 합친 것이다 — 직전 회차 findings.json 의 confirmed·undetermined·derived, 직전 diff.json 의
// 잔존·미판정 전부, 직전 diff.json 의 해소 가운데 그 전 회차 diff.json 에서는 해소가 아니었던 것.
phase('대조')
const DIFF_VERDICTS = ['잔존', '해소', '미판정']
let diffFile = { schema: SCHEMA_VERSION, no_prior_round: true, items: [] }
const derivedFindings = []
if (tg.prior_rounds.length > 0) {
  const [prev, prevprev] = tg.prior_rounds
  const pr = await agent(
    `너는 읽기 전용 에이전트다. ${REVIEWS}/${prev}/findings.json 을 열어 status 가 confirmed·undetermined·derived 인 발견의 id·title·file·evidence·consequence·status 를 findings 에 옮겨라(rejected 는 빼라).
${REVIEWS}/${prev}/diff.json 의 items 전부를 diff_items 에 옮겨라(비어 있으면 빈 배열).
${prevprev ? `${REVIEWS}/${prevprev}/diff.json 의 items 의 prior_id 와 verdict 만 prior_diff_items 에 옮겨라.` : 'prior_diff_items 는 빈 배열이다.'}
아무 파일도 쓰지 마라.`,
    { label: 'prior-rounds', phase: '대조', schema: PRIOR_SCHEMA, effort: 'low' }
  )
  if (!pr) throw new Error('지난 회차 읽기 에이전트가 응답하지 않았다 — 회차를 실패로 끝낸다')
  const prevResolved = new Set(pr.prior_diff_items.filter(i => i.verdict === '해소').map(i => i.prior_id))
  const subjects = []
  for (const f of pr.findings) subjects.push({ prior_id: f.id, prior_round: prev, title: f.title, file: f.file, evidence: f.evidence, consequence: f.consequence, was_resolved: false })
  for (const i of pr.diff_items) {
    if (i.verdict === '잔존' || i.verdict === '미판정') subjects.push({ prior_id: i.prior_id, prior_round: i.prior_round, title: i.title, file: i.file, evidence: i.evidence, consequence: i.consequence, was_resolved: false })
    else if (i.verdict === '해소' && !prevResolved.has(i.prior_id)) subjects.push({ prior_id: i.prior_id, prior_round: i.prior_round, title: i.title, file: i.file, evidence: i.evidence, consequence: i.consequence, was_resolved: true })
  }
  const seen = new Set()
  const uniqueSubjects = subjects.filter(s => (seen.has(s.prior_id) ? false : (seen.add(s.prior_id), true)))
  log(`회차 대조: 대상 ${uniqueSubjects.length}건 (직전 ${prev}${prevprev ? `, 그 전 ${prevprev}` : ''})`)
  const items = (await parallel(uniqueSubjects.map(s => () => {
    const sameFile = judged.filter(j => j.status !== STATUS[1] && j.file.split(':')[0] === s.file.split(':')[0]).map(j => ({ id: j.id, title: j.title, evidence: j.evidence }))
    return agent(
      `너는 회차 대조 에이전트다. 지난 회차 발견이 지금 파일에 남아 있는지 판정하라. ${REPO} 의 파일을 직접 열어 본다. 아무 파일도 쓰지 마라.
[지난 발견] ${JSON.stringify({ id: s.prior_id, round: s.prior_round, title: s.title, file: s.file, evidence: s.evidence, consequence: s.consequence })}
[이번 회차에서 같은 파일에 난 발견] ${JSON.stringify(sameFile)}
판정은 둘이다 — 잔존(문제가 지금 파일에 있다. 어디에 있는지 인용한다. 이번 발견과 같은 실체이면 그 id 를 matched_id 에 적는다), 해소(없다. 무엇이 바뀌었는지 적는다).`,
      { label: `diff:${s.prior_id}`, phase: '대조', schema: DIFF_VERDICT_SCHEMA }
    ).then(v => ({ ...s, verdict: v ? v.verdict : DIFF_VERDICTS[2], reason: v ? v.reason : '대조 에이전트가 응답하지 않았다', matched_id: v && v.matched_id ? v.matched_id : null }))
  }))).filter(Boolean)
  // 재발은 도출이다 — 직전 diff.json 이 해소로 적었던 발견이 이번에 잔존이면 가드 결함 발견을 새로 만든다.
  // id 번호는 반박검증이 deduped 인덱스로 쓴 번호 뒤를 잇는다.
  let n = deduped.length
  for (const it of items) {
    if (it.was_resolved && it.verdict === '잔존') {
      n += 1
      derivedFindings.push({ id: findingId(ROUND, n), lens: 'round-diff', title: '이것을 막는 검사가 없다', file: it.file, evidence: `${it.prior_id} → ${it.matched_id || '(이번 회차 짝 없음)'}`, principle: 'FAIL-LOUD', consequence: `해소로 판정됐던 ${it.title}이(가) 다시 잔존한다. 검사가 없으면 고쳐도 되돌아온다.`, detail: it.reason, status: STATUS[3], missingVotes: 0, verdicts: [] })
    }
  }
  diffFile = { schema: SCHEMA_VERSION, no_prior_round: false, items: items.map(({ was_resolved, ...rest }) => rest) }
  run.dead_agents.diff = items.filter(i => i.verdict === DIFF_VERDICTS[2]).map(i => i.prior_id)
} else {
  log('대조할 지난 회차 없음')
}
run.verdict_counts.derived = derivedFindings.length
findingsFile.findings.push(...derivedFindings)
await record('diff', [
  { name: 'findings.json', content: findingsFile, count: findingsFile.findings.length, ids: findingsFile.findings.map(f => f.id) },
  { name: 'diff.json', content: diffFile, count: diffFile.items.length, ids: null },
])
```

반박검증 블록 끝에는 `await record('verify', [])`를 남긴다(걸음은 끝났고 파일은 대조 뒤에 쓴다). 요약문의 `const derivedFindings = ...` 줄은 위에서 정의했으므로 지운다.

`skills/project-doc-audit/SKILL.md`의 걸음 표에서 「반박검증한다」 행 뒤에 `| 회차를 대조한다 | 「회차 대조」 절 |`를 더하고 "걸음은 아홉이고"를 "걸음은 열이고"로 바꾼다. 「통합 기록」 절 앞에 절을 더한다.

```markdown
## 회차 대조
대조할 지난 회차는 `scripts/audit_prior_rounds.sh`가 고른다. `run.json`의 실행체가 같고 `completed`가 참인 폴더를 경로 정렬해 최근 둘을 낸다. 대조 대상은 셋을 합친 것이다. 직전 회차 `findings.json`의 확정·미판정·도출 발견, 직전 `diff.json`이 잔존이나 미판정으로 적은 항목, 직전 `diff.json`이 해소로 적은 항목 가운데 그 전 회차에서는 해소가 아니었던 것이다. 해소를 한 회차 더 보는 것은 재발을 잡기 위해서다.

대상 발견마다 에이전트 하나가 지금 파일을 열어 잔존과 해소 가운데 하나로 판정하고 사유를 적는다. 응답이 없으면 미판정이고 다음 회차가 다시 대조한다. 직전에 해소였던 발견이 잔존이면 재발이고, 재발마다 "이것을 막는 검사가 없다"는 발견을 `derived`로 새로 만든다.
```

- [ ] **Step 4: 문법과 정적 단언을 확인한다**

Run: `node --check .claude/workflows/self-audit.js && bash scripts/test_self_audit.sh 2>&1 | grep -E 'FAIL|PASS='`
Expected: "최신 회차의 diff.json 에 대조 항목이 있다" 하나만 FAIL(아직 둘째 회차가 없다).

- [ ] **Step 5: 둘째 회차를 돌린다**

Task 7 Step 4와 같이 실행체를 돌리고, 요약문에 뿌리와 물음과 호출 수를 붙인 뒤 봉인한다. 이번 회차의 `diff.json`은 첫 회차의 확정·미판정 발견 전부에 잔존·해소·미판정 가운데 하나를 적어야 한다. 끊긴 폴더는 커밋하지 않는다.

- [ ] **Step 6: 돌려서 통과를 확인하고 커밋한다**

Run: 전체 테스트 명령.
Expected: `ALL PASS`.

```bash
git add .claude/workflows/self-audit.js scripts/test_self_audit.sh skills/project-doc-audit/SKILL.md "docs/superpowers/reviews/<round>.md" "docs/superpowers/reviews/<round>/"
git commit -m "지난 회차 발견을 하나씩 대조해 diff.json 을 남기고 재발을 가드 결함 발견으로 도출한다"
```

---

## 덩어리 5 — 일관성 방법 (뽑기 → 모으기 → 대조)

이 덩어리가 끝나면 실행체는 조각마다 진술을 뽑고, 이름표별로 모아 둘 이상의 문서에서 온 묶음만 남기고, 묶음마다 `lens-consistency`를 띄워 어긋남·좁혀 적음·같음을 판정하며, 같음이면서 정본을 가리키지 않는 진술을 `SSOT` 복제 발견으로 도출한다. 어느 호출 입력도 문턱을 넘지 않는 것은 워크플로가 크기를 세어 보장한다. 절차와 렌즈 문서가 그 방법을 적는다.

### Task 10: `audit_topics.sh`

**Files:**
- Create: `scripts/audit_topics.sh`
- Modify: `scripts/test_self_audit.sh`

**Interfaces:**
- Produces: `bash scripts/audit_topics.sh` → 이름표 한 줄에 하나(정본 원칙 ID 전부, 정본 `##` 절 제목, `skills/` 아래 스킬 이름, `commands/` 아래 명령 이름). 정렬·중복 제거.

- [ ] **Step 1: 실패하는 테스트를 더한다**

`scripts/test_self_audit.sh`의 `echo "----"` 앞에 더한다. 절 제목에 공백이 있으므로 줄 단위로 읽는다.

```bash
echo "[audit_topics.sh — 이름표 목록]"
ATP="$HERE/scripts/audit_topics.sh"
check "스크립트가 있다"                          "[ -f '$ATP' ]"
ATP_OUT="$(bash "$ATP" 2>/dev/null || true)"
ATP_MISS=""
while IFS= read -r want; do
  [ -n "$want" ] || continue
  printf '%s\n' "$ATP_OUT" | grep -qxF "$want" || ATP_MISS="$ATP_MISS [$want]"
done <<EOF
$(grep -oE '^- \*\*`[A-Z-]+`' "$HERE/agent-principles.md" | sed 's/^- \*\*`//; s/`$//')
$(grep '^## ' "$HERE/agent-principles.md" | sed 's/^## //')
$(ls "$HERE/skills")
$(ls "$HERE/commands" | sed 's/\.md$//')
EOF
[ -n "$ATP_MISS" ] && echo "    빠진 이름표:$ATP_MISS"
check "정본 원칙 ID·절 제목·스킬·명령 이름이 모두 있다" "[ -z \"\$ATP_MISS\" ]"
check "중복이 없다"                                "[ \"\$(printf '%s\n' \"\$ATP_OUT\" | sort | uniq -d | wc -l)\" = 0 ]"
```

- [ ] **Step 2: 돌려서 실패를 확인한다**

Run: `bash scripts/test_self_audit.sh 2>&1 | grep -E 'topics|FAIL|PASS='`
Expected: "스크립트가 있다"와 "모두 있다" 둘이 FAIL. "중복이 없다"는 출력이 비어 PASS다.

- [ ] **Step 3: 스크립트를 쓴다**

`scripts/audit_topics.sh`:

```bash
#!/usr/bin/env bash
# 이름표 목록을 도출한다 — 정본의 원칙 ID 전부, 정본의 ## 절 제목, skills/ 아래 스킬 이름, commands/ 아래
# 명령 이름을 합쳐 한 줄에 하나씩 낸다. 목록이 닫혀 있으므로 모으기가 문자열 일치로 끝난다.
set -euo pipefail
HERE="$(cd "$(dirname "$0")/.." && pwd)"
{
  grep -oE '^- \*\*`[A-Z-]+`' "$HERE/agent-principles.md" | sed 's/^- \*\*`//; s/`$//'
  grep '^## ' "$HERE/agent-principles.md" | sed 's/^## //'
  for d in "$HERE"/skills/*/; do basename "$d"; done
  for f in "$HERE"/commands/*.md; do [ -f "$f" ] && basename "$f" .md; done
} | awk 'NF && !seen[$0]++' | sort
```

- [ ] **Step 4: 돌려서 통과를 확인하고 커밋한다**

Run: `bash scripts/test_self_audit.sh 2>&1 | grep -E 'FAIL|PASS='`
Expected: `FAIL=0`.

```bash
git add scripts/audit_topics.sh scripts/test_self_audit.sh
git commit -m "정본 원칙과 절 제목과 스킬과 명령 이름으로 이름표 목록을 도출한다"
```

### Task 11: 뽑기·모으기·대조 걸음과 복제 도출

**Files:**
- Modify: `.claude/workflows/self-audit.js` (`meta.phases`·`STEPS`·`TARGETS_SCHEMA`·대상 도출 프롬프트·스키마·준비 뒤에 뽑기와 모으기·리뷰 걸음에 묶음별 `lens-consistency`·복제 도출·요약문)
- Modify: `scripts/test_self_audit.sh`

**Interfaces:**
- Consumes: `scripts/audit_topics.sh`(Task 10), `tg.fragments`·`tg.limit`·`record`·`FINDINGS_SCHEMA`(Task 2·6).
- Produces: 진술 `{ topics, statement, file, line, context, role, follows, condition }`(`file`은 워크플로가 조각의 경로로 덮어쓴다). 묶음별 `lens-consistency` 원본 `lens-consistency-<n>.json`(`findings`·`pairs`·`narrowed`), `type: 'duplication'`의 `SSOT` 발견, `run.topic_groups`·`run.narrowed`·`run.unlabeled`. 묶음 입력의 크기는 프롬프트에 넣는 JSON 문자열 길이로 세어 `tg.limit`을 넘지 않게 나눈다.

- [ ] **Step 1: 실패하는 테스트를 더한다**

`scripts/test_self_audit.sh`의 `echo "----"` 앞에 더한다.

```bash
echo "[실행체 — 일관성 방법]"
check "실행체가 audit_topics.sh 를 부른다"                "grep -qF 'audit_topics.sh' '$WF'"
check "뽑기 진술이 role 과 follows 와 context 를 갖는다"    "grep -qF \"enum: ['canon', 'follows', 'none']\" '$WF' && grep -qF 'context: { type' '$WF'"
check "진술의 file 은 조각의 경로로 덮어쓴다"              "grep -qF 'file: e.fragment.path' '$WF'"
check "모으기는 스크립트 안의 JS 가 한다"                  "grep -qF 'function groupByTopic' '$WF'"
check "정본 관계를 조각 목록에서 도출한다"                 "grep -qF 'function canonOf' '$WF' && ! grep -qF \"'meta-aggregate', 'nested-orchestration'\" '$WF'"
check "묶음마다 lens-consistency 를 띄운다"                "grep -qF \"label: \\\`lens-consistency:\" '$WF'"
check "판정 셋이 닫힌 집합이다"                            "grep -qF \"'어긋남'\" '$WF' && grep -qF \"'좁혀 적음'\" '$WF' && grep -qF \"'같음'\" '$WF'"
check "렌즈가 narrowed 를 돌려준다"                        "grep -qF \"narrowed: { type: 'integer'\" '$WF'"
check "복제는 판정에서 도출한다"                           "grep -qF \"type: 'duplication'\" '$WF' && grep -qF \"role === 'none'\" '$WF'"
check "묶음 입력 크기를 JSON 길이로 세어 tg.limit 에 맞춘다" "grep -qF 'function groupSize' '$WF' && grep -qF 'tg.limit' '$WF'"
check "좁혀 적음과 빈 이름표 개수를 run 에 담는다"         "grep -qF 'run.narrowed' '$WF' && grep -qF 'run.unlabeled' '$WF'"
check "뽑기 걸음이 자기 phase 를 갖는다"                   "grep -qF \"phase('뽑기')\" '$WF' && grep -qF \"title: '뽑기'\" '$WF'"
```

- [ ] **Step 2: 돌려서 실패를 확인한다**

Run: `bash scripts/test_self_audit.sh 2>&1 | grep -E 'FAIL|PASS='`
Expected: 새 단언 열둘이 FAIL.

- [ ] **Step 3: 실행체에 세 걸음을 더한다**

`meta.phases`의 「준비」 뒤에 `{ title: '뽑기', detail: '조각마다 진술을 뽑고 이름표별로 모아 둘 이상의 문서에서 온 묶음만 남긴다' },`를 더한다. `STEPS`를 `['repo-check', 'targets', 'machine-checks', 'extract', 'group', 'review', 'dedup', 'verify', 'diff', 'aggregate', 'record']`로 바꾼다. `TARGETS_SCHEMA`의 `properties`에 `topics: { type: 'array', items: { type: 'string' }, description: 'audit_topics.sh 의 출력' }`을 더하고 `required`에 `'topics'`를 더한다. 대상 도출 프롬프트에 한 줄을 더한다.

```
- \`bash scripts/audit_topics.sh\` 의 출력을 topics 에 한 줄에 하나씩 옮긴다.
```

스키마 묶음에 더한다.

```js
const EXTRACT_SCHEMA = {
  type: 'object',
  properties: {
    statements: {
      type: 'array',
      items: {
        type: 'object',
        properties: {
          topics: { type: 'array', items: { type: 'string' }, description: '이름표 목록에서 고른 것만. 어느 것에도 안 걸리면 빈 배열' },
          statement: { type: 'string', description: '이 문서가 정한 것 한 줄(규칙·값·절차·이름)' },
          line: { type: 'integer', description: '그 진술이 있는 줄(1부터)' },
          context: { type: 'string', description: '그 줄 앞뒤 다섯 줄의 원문' },
          role: { type: 'string', enum: ['canon', 'follows', 'none'], description: 'canon: 이 문서가 그 주제의 정본이라고 말한다. follows: 그 진술이나 그 진술이 든 절이 다른 문서를 정본으로 이름 부른다. none: 둘 다 아니다' },
          follows: { type: 'string', description: 'role 이 follows 이면 그 문서의 레포 상대경로(스킬이면 skills/<이름>/SKILL.md), 아니면 빈 문자열' },
          condition: { type: 'string', description: '조건이 붙은 문장이면 그 조건, 아니면 빈 문자열' },
        },
        required: ['topics', 'statement', 'line', 'context', 'role', 'follows', 'condition'],
      },
    },
  },
  required: ['statements'],
}
const CONSISTENCY_SCHEMA = {
  type: 'object',
  properties: {
    pairs: {
      type: 'array',
      items: {
        type: 'object',
        properties: {
          canon_line: { type: 'integer' }, other_file: { type: 'string' }, other_line: { type: 'integer' },
          verdict: { type: 'string', enum: ['어긋남', '좁혀 적음', '같음'] },
          reason: { type: 'string' },
        },
        required: ['canon_line', 'other_file', 'other_line', 'verdict', 'reason'],
      },
    },
    narrowed: { type: 'integer', description: '좁혀 적음 판정의 수' },
    findings: FINDINGS_SCHEMA.properties.findings,
    read: { type: 'array', items: { type: 'string' } },
    principles_applied: { type: 'array', items: { type: 'string' } },
  },
  required: ['pairs', 'narrowed', 'findings', 'read', 'principles_applied'],
}
```

`await record('targets', [])` 뒤, `machinePromise` 정의 뒤에 더한다.

```js
// ---------- 뽑기 ----------
// 조각마다 에이전트 하나가 그 문서가 정한 것을 한 줄씩 뽑는다. 이름표는 닫힌 목록에서만 고르고,
// 진술의 file 은 에이전트가 적은 것을 쓰지 않고 조각의 경로로 덮어쓴다 — 경로 꼴이 어긋나면 모으기가 통째로 빈다.
phase('뽑기')
const topicSet = new Set(tg.topics)
const extracted = (await parallel(tg.fragments.map(fr => () =>
  agent(
    `너는 진술 뽑기 에이전트다. ${REPO}/${fr.path} 의 ${fr.start}~${fr.end}행(1부터, 양끝 포함)만 읽고, 그 조각이 정한 것(규칙·값·절차·이름)을 한 줄씩 뽑아라. 아무 파일도 쓰지 마라.
진술마다 이름표를 아래 목록에서만 고른다(여럿 가능). 목록에 없는 이름표를 지어 붙이지 마라. 어느 것에도 안 걸리면 빈 배열로 둔다. 진술마다 그 줄 앞뒤 다섯 줄의 원문을 context 에 그대로 담는다.
역할은 셋이다 — canon(이 문서가 그 주제의 정본이라고 말한다), follows(그 진술이나 그 진술이 든 절이 다른 문서를 정본으로 이름 부른다 — "상세는 X를 참고한다"·"X가 정한다"·"X가 소유한다"가 그 꼴이다. follows 에 그 문서의 레포 상대경로를 적는다), none(둘 다 아니다). 절 머리에 참조가 있고 아래 문장들이 그것을 따르면 그 문장들도 follows 다.
조건이 붙은 문장은 조건을 condition 에 담는다.
[이름표 목록] ${JSON.stringify(tg.topics)}`,
    { label: `extract:${fr.path}:${fr.start}`, phase: '뽑기', schema: EXTRACT_SCHEMA, effort: 'low' }
  ).then(r => ({ fragment: fr, statements: r ? r.statements : null }))
))).filter(Boolean)
run.dead_agents.extract = extracted.filter(e => !e.statements).map(e => `${e.fragment.path}:${e.fragment.start}`)
const statements = extracted.filter(e => e.statements).flatMap(e => e.statements.map(s => ({ ...s, file: e.fragment.path, topics: s.topics.filter(t => topicSet.has(t)) })))
run.unlabeled = statements.filter(s => s.topics.length === 0).length
log(`뽑기 완료: 진술 ${statements.length}건, 빈 이름표 ${run.unlabeled}건`)
await record('extract', [])

// ---------- 모으기 ----------
// 스크립트 안의 JS 가 이름표별로 묶고 둘 이상의 문서에서 온 묶음만 남긴다. 에이전트가 아니다.
// 정본 관계 세 규칙 — 원칙 ID 와 정본 절 제목의 정본은 agent-principles.md, 스킬·명령 이름의 정본은 그 스킬·명령,
// 정본 문서의 진술이 follows 로 다른 문서를 이름 부르면 그 이름표의 정본은 그 문서다.
// 스킬과 명령 이름은 조각 목록(audit_targets.sh 의 출력)에서 도출한다. 손으로 적은 목록은 두지 않는다.
const fragPaths = [...new Set(tg.fragments.map(f => f.path))]
const PRINCIPLES_PATH = fragPaths.find(p => p.endsWith('agent-principles.md'))
const skillPathOf = {}, commandPathOf = {}
for (const p of fragPaths) {
  const sk = p.match(/^skills\/([^/]+)\/SKILL\.md$/); if (sk) skillPathOf[sk[1]] = p
  const cm = p.match(/^commands\/([^/]+)\.md$/); if (cm) commandPathOf[cm[1]] = p
}
function canonOf(topic, group) {
  let canon = skillPathOf[topic] || commandPathOf[topic] || PRINCIPLES_PATH
  const delegated = group.find(s => s.file === canon && s.role === 'follows' && s.follows)
  if (delegated) canon = delegated.follows
  return canon
}
// 묶음 입력의 크기는 렌즈 프롬프트에 실제로 넣는 JSON 문자열 길이다(진술·앞뒤 원문·범위 문장 표시 전부).
function groupSize(g) { return JSON.stringify({ canon: g.canon_statements, others: g.other_statements }).length }
function groupByTopic(stmts, limit) {
  const byTopic = {}
  for (const s of stmts) for (const t of s.topics) (byTopic[t] = byTopic[t] || []).push(s)
  const groups = []
  for (const [topic, arr] of Object.entries(byTopic)) {
    if (new Set(arr.map(s => s.file)).size < 2) continue
    const canon = canonOf(topic, arr)
    const canonStmts = arr.filter(s => s.file === canon)
    const others = arr.filter(s => s.file !== canon)
    if (canonStmts.length === 0 || others.length === 0) continue
    const whole = { topic, canon, canon_statements: canonStmts, other_statements: others }
    if (groupSize(whole) <= limit) { groups.push(whole); continue }
    // 문턱을 넘으면 정본의 진술 대 따르는 문서 하나의 진술로 짝을 나누고, 그래도 넘으면 따르는 진술을 잘라 나눈다.
    const byFile = {}
    for (const s of others) (byFile[s.file] = byFile[s.file] || []).push(s)
    for (const [file, os] of Object.entries(byFile)) {
      let chunk = []
      for (const s of os) {
        const trial = { topic, canon, canon_statements: canonStmts, other_statements: chunk.concat([s]), split_for: file }
        if (chunk.length > 0 && groupSize(trial) > limit) { groups.push({ topic, canon, canon_statements: canonStmts, other_statements: chunk, split_for: file }); chunk = [] }
        chunk.push(s)
      }
      if (chunk.length) groups.push({ topic, canon, canon_statements: canonStmts, other_statements: chunk, split_for: file })
    }
  }
  return groups
}
const groups = groupByTopic(statements, tg.limit)
const oversize = groups.filter(g => groupSize(g) > tg.limit)
run.topic_groups = groups.length
log(`모으기 완료: 이름표 묶음 ${groups.length}개${oversize.length ? `, 문턱을 넘는 묶음 ${oversize.length}개(정본 진술만으로 이미 넘는다)` : ''}`)
await record('group', [])
```

리뷰 걸음의 `const reviewJobs = perDoc.map(...)...concat(WHOLE_LENSES.map(...))` 뒤에 `.concat(...)`을 하나 더 잇는다(묶음별 `lens-consistency`).

```js
.concat(groups.map((g, gi) => () =>
  agent(
    `${COMMON}
렌즈: ${REPO}/skills/lens-consistency/SKILL.md 를 읽고 그 「레포 문서 감사에서의 짝」 절대로 적용하라. 산출물 공백과 스코프는 이 감사에서 보지 않는다.
[이름표] ${g.topic}
[정본] ${g.canon}
[정본의 진술] ${JSON.stringify(g.canon_statements.map(s => ({ line: s.line, statement: s.statement, context: s.context, condition: s.condition })))}
[따르는 문서의 진술] ${JSON.stringify(g.other_statements.map(s => ({ file: s.file, line: s.line, statement: s.statement, context: s.context, role: s.role, follows: s.follows, condition: s.condition })))}
범위 문장은 문서마다 하나다 — SKILL.md 이면 frontmatter 의 description, 그 밖이면 첫 문단이다. 정본과 따르는 문서의 범위 문장을 열어 읽어라.
짝(정본 진술 × 따르는 진술)마다 판정은 셋이다 — 어긋남(같은 것을 다르게 정한다. findings 에 발견 하나를 만든다), 좁혀 적음(따르는 쪽이 정본의 규칙을 자기 범위에 적용해 더 좁게 또는 더 자세히 정한다. 정당한 도출이라 발견이 아니다), 같음(정본의 문장을 다른 말로 되풀이할 뿐 더한 것이 없다). 좁혀 적음의 수를 narrowed 에 적어라. 조건이 다른 짝은 어긋남으로 올리지 말고 reason 에 조건을 적어라.`,
    { label: `lens-consistency:${g.topic}${g.split_for ? ':' + g.split_for : ''}`, phase: '리뷰', schema: CONSISTENCY_SCHEMA }
  ).then(res => ({ key: 'lens-consistency', file: `lens-consistency-${gi + 1}.json`, target: g.topic, group: g, res }))
    .catch(() => ({ key: 'lens-consistency', file: `lens-consistency-${gi + 1}.json`, target: g.topic, group: g, res: null }))
))
```

`const all = ...` 줄을 다음으로 바꾼다(복제 도출이 더해진다).

```js
// 복제는 판정에서 도출한다 — 같음이면서 정본이 아닌 쪽의 역할이 none 이면 정본을 가리키지 않고 베낀 것이다(SSOT).
const CONSISTENCY_VERDICTS = ['어긋남', '좁혀 적음', '같음']
const consistencyRuns = reviews.filter(r => r.key === 'lens-consistency' && r.res)
run.narrowed = consistencyRuns.reduce((n, r) => n + r.res.narrowed, 0)
const duplication = consistencyRuns.flatMap(r => r.res.pairs
  .filter(p => p.verdict === CONSISTENCY_VERDICTS[2])
  .map(p => ({ p, src: r.group.other_statements.find(s => s.file === p.other_file && s.line === p.other_line) }))
  .filter(x => x.src && x.src.role === 'none')
  .map(x => ({ title: `${x.p.other_file}이(가) 정본 ${r.group.canon}의 문장을 가리키지 않고 베낀다.`, file: `${x.p.other_file}:${x.p.other_line}`, evidence: x.src.statement, principle: 'SSOT', consequence: `정본의 ${r.group.topic} 규칙이 바뀌면 이 문장은 그대로 남아 두 판이 된다.`, detail: x.p.reason, fix: '정본을 가리키는 참조로 바꾼다.', type: 'duplication' })))
const all = reviews.filter(r => r.res).flatMap(r => r.res.findings.map(f => ({ ...f, lens: r.key, target: r.target }))).concat(duplication.map(d => ({ ...d, lens: 'lens-consistency', target: '(이름표 묶음)' })))
```

`record('review', ...)`는 그대로다 — 일관성 원본도 `findings` 배열을 가지므로 `COUNT_RULE`대로 `findings` 길이를 센다. 요약문의 `'## 범위와 배정'` 목록 끝에 더한다.

```js
  line(`이름표 묶음 ${run.topic_groups}개, 좁혀 적음 ${run.narrowed}건, 빈 이름표 진술 ${run.unlabeled}건${oversize.length ? `, 문턱을 넘는 묶음 ${oversize.length}개` : ''}`),
```

- [ ] **Step 4: 문법과 정적 단언을 확인한다**

Run: `node --check .claude/workflows/self-audit.js && bash scripts/test_self_audit.sh 2>&1 | grep -E 'FAIL|PASS='`
Expected: `FAIL=0`.

- [ ] **Step 5: 커밋한다**

```bash
git add .claude/workflows/self-audit.js scripts/test_self_audit.sh
git commit -m "진술을 뽑아 이름표로 모으고 묶음마다 lens-consistency 를 띄워 어긋남과 복제를 판정한다"
```

### Task 12: 렌즈·절차·집계·규율 문서와 08-30 설계 머리를 맞추고 셋째 회차를 돌린다

**Files:**
- Modify: `skills/lens-consistency/SKILL.md:7` (첫 문단), `:9-14` (체크리스트), `:16-19` (읽기 범위 뒤에 새 절), `:25-31` (출력 스키마)
- Modify: `skills/meta-aggregate/SKILL.md:56` (렌즈 추가 칸 문단)
- Modify: `skills/domain-docs/SKILL.md:121-122` (「한 번만 띄우는 렌즈의 규율」 첫 문단)
- Modify: `skills/project-doc-audit/SKILL.md` (걸음 표에 한 행, `:47`·`:60`의 대체되는 문장, 「집계」 앞에 「일관성 대조」 절)
- Modify: `docs/superpowers/specs/2026-08-30-audit-unification-design.md:1-3` (머리)
- Modify: `scripts/test_self_audit.sh`
- Create (실행체가 만든다): 셋째 회차 `docs/superpowers/reviews/<날짜>-self-audit[-N].md`와 같은 이름의 폴더

**Interfaces:**
- Consumes: Task 11의 판정 셋과 `duplication`과 `narrowed`.
- Produces: 셋째 회차 기록(`topic_groups`가 양수이고 `diff.json`이 둘째 회차의 잔존 항목을 다시 대조한 것). 요약문 끝에 08-30 「일관성 결과 공백」 기록의 어긋남 가운데 아직 남은 것을 새 방법이 잡았는지 호출자가 적는다.

- [ ] **Step 1: 실패하는 테스트를 더한다**

`scripts/test_self_audit.sh`의 `echo "----"` 앞에 더한다.

```bash
echo "[문서 — 일관성 방법이 절차와 렌즈에 적혔다]"
LC="$HERE/skills/lens-consistency/SKILL.md"
check "렌즈가 이름표 묶음 짝을 적는다"                  "grep -qF '## 레포 문서 감사에서의 짝' '$LC'"
check "렌즈 type 에 duplication 이 있다"                "grep -qF 'duplication' '$LC'"
check "렌즈가 판정 셋과 narrowed 를 적는다"             "grep -qF '좁혀 적음' '$LC' && grep -qF 'narrowed' '$LC'"
check "렌즈가 산출물 공백·스코프를 감사에서 뺀다"        "grep -qF '레포 문서 감사에서는 걸지 않는다' '$LC'"
check "집계 계약이 narrowed 를 렌즈 추가 칸으로 적는다"  "grep -qF 'narrowed' '$HERE/skills/meta-aggregate/SKILL.md'"
check "한 번만 규율에 '대상이 다르면 별개 호출' 이 있다" "grep -qF '대상이 다르면 별개 호출이다' '$HERE/skills/domain-docs/SKILL.md'"
check "절차의 대체된 문장 셋이 사라졌다"                 "! grep -qF '만은 묶음에 한 번 건다' '$PDA' && ! grep -qF '묶음을 통째로 받는다' '$PDA' && ! grep -qF '묶음 전부를 서로 대조한다' '$LC'"
check "절차의 '짧은 문서 둘까지' 가 사라졌다"            "! grep -qF '짧은 문서 둘까지' '$PDA'"
check "절차에 「일관성 대조」 절과 걸음 행이 있다"         "grep -qF '## 일관성 대조' '$PDA' && grep -qF '| 진술을 뽑아 이름표로 모은다 |' '$PDA'"
check "절차가 문턱 값을 audit_targets.sh 로 가리킨다"    "grep -qF 'audit_targets.sh' '$PDA'"
check "08-30 설계 머리가 이 설계를 가리킨다"             "head -6 '$HERE/docs/superpowers/specs/2026-08-30-audit-unification-design.md' | grep -qF '2026-09-02-audit-record-and-diff-design.md'"
check "최신 회차 run.json 의 topic_groups 가 양수다"     "[ -n \"\$LATEST\" ] && rj 'import json,sys; d=json.load(open(sys.argv[1],encoding=\"utf-8\")); sys.exit(0 if d.get(\"topic_groups\",0)>0 else 1)' run.json"
```

- [ ] **Step 2: 돌려서 실패를 확인한다**

Run: `bash scripts/test_self_audit.sh 2>&1 | grep -E 'FAIL|PASS='`
Expected: 새 단언 열둘이 FAIL.

- [ ] **Step 3: 문서를 고친다**

`skills/lens-consistency/SKILL.md` 첫 문단의 마지막 문장 "묶음을 받았으면 그 묶음 전부를 서로 대조한다."를 "레포 문서 감사에서는 「레포 문서 감사에서의 짝」 절이 정하는 이름표 묶음 하나가 짝이다."로 바꾼다. 체크리스트의 「산출물 공백」과 「스코프」 항목 끝에 각각 " spec·plan을 보는 항목이라 레포 문서 감사에서는 걸지 않는다."를 더한다. 「읽기 범위」 절 뒤에 절을 더한다.

```markdown
## 레포 문서 감사에서의 짝
짝은 이름표 묶음 하나다. 호출자가 정본의 진술과 따르는 문서의 진술, 진술마다 원문 앞뒤 다섯 줄, 어느 문서가 정본인지를 준다. 범위 문장은 렌즈가 문서마다 하나씩 연다. 판정은 짝마다 셋이다.

- **어긋남** — 같은 것을 다르게 정한다. 발견이 된다.
- **좁혀 적음** — 따르는 쪽이 정본의 규칙을 자기 범위에 적용해 더 좁게 또는 더 자세히 정한다. 정당한 도출이라 발견이 아니고 개수만 `narrowed`로 돌려준다.
- **같음** — 정본의 문장을 다른 말로 되풀이할 뿐 더한 것이 없다.

복제는 이 렌즈가 판정하지 않고 호출자가 도출한다. 같음이면서 정본이 아닌 쪽의 역할이 정본을 가리키지 않는 것이면 그 진술은 베낀 것이고, 호출자가 `duplication` 발견으로 올린다. 조건이 다른 짝은 어긋남으로 올리지 않고 사유에 조건을 적는다.
```

출력 스키마의 `type`을 `"contradiction|gap|drift|scope|duplication"`으로 바꾸고, 스키마 아래에 "`duplication`은 레포 문서 감사에서 호출자가 도출해 붙이는 값이다. `narrowed`(좁혀 적음 개수)와 `pairs`(짝마다의 판정)는 레포 문서 감사에서 이 렌즈가 더 돌려주는 칸이며 집계 대상이 아니다. `meta-aggregate`의 리뷰 산출물 계약을 참고한다."를 더한다.

`skills/meta-aggregate/SKILL.md`의 "렌즈가 자기 필드를 더할 수 있고 그것도 집계 대상이 아니다." 문단에서 "`lens-readability`의 `purpose`·`rewrite`가 그렇다."를 "`lens-readability`의 `purpose`·`rewrite`와 `lens-consistency`의 `narrowed`·`pairs`가 그렇다."로 바꾼다.

`skills/domain-docs/SKILL.md`의 「한 번만 띄우는 렌즈의 규율」 첫 문단 끝에 " 대상이 다르면 별개 호출이다. 레포 문서 감사가 이름표 묶음마다 `lens-consistency`를 띄우는 것은 같은 대상을 두 번 표집하는 것이 아니다."를 더한다.

`skills/project-doc-audit/SKILL.md`에서 다음을 바꾼다.

- 걸음 표의 「렌즈를 배정해 띄운다」 행 앞에 `| 진술을 뽑아 이름표로 모은다 | 「일관성 대조」 절 |`를 더하고 "걸음은 열이고"를 "걸음은 열하나이고"로 바꾼다.
- 「렌즈 배정 기준」의 "`lens-consistency`만은 묶음에 한 번 건다. 어긋남은 문서 사이에서 드러나므로 규칙을 소유한 문서와 그것을 따르는 문서 전부를 한 렌즈에게 함께 준다."를 "`lens-consistency`는 문서별로 걸지 않고 「일관성 대조」 절대로 이름표 묶음마다 건다."로 바꾼다.
- 「띄울 때 지킬 것」의 "문서마다 따로 판정하는 렌즈에는 문서를 몰아주지 않는다. 짧은 문서 둘까지는 한 렌즈에게 줄 수 있고, 그때도 목적은 문서마다 따로 준다. 셋부터는 뒤쪽 문서의 판정이 얕아진다. 문서 사이의 어긋남을 보는 `lens-consistency`는 이 규칙 밖이다. 위에 적은 대로 묶음을 통째로 받는다. 무엇을 짧다고 볼지와 한 번에 몇을 띄울지는 회차마다 호출자가 정하고, 정한 값과 그 이유를 「통합 기록」의 렌즈 배정에 적는다. 이 규칙은 이 절차에서 `domain-spec-review`의 \"대상마다 따로 띄운다\"를 대신한다."를 "문서마다 따로 판정하는 렌즈에는 문서 하나를 통째로 준다. 렌즈 호출 하나의 입력 상한은 `scripts/audit_targets.sh --limit`가 내는 값이며, 그 상한은 진술 뽑기와 이름표 묶음에 걸리고 문서별 렌즈에는 걸리지 않는다. 문서별 렌즈가 그 값을 넘는 문서를 통째로 받는 것은 한계로 기록에 적는다. 이 규칙은 이 절차에서 `domain-spec-review`의 \"대상마다 따로 띄운다\"를 대신한다."로 바꾼다.
- 「집계」 절 앞에 절을 더한다.

```markdown
## 일관성 대조
세 걸음이다. LLM은 문서 조각 하나나 이름표 묶음 하나만 받고, 묶기는 스크립트가 한다.

- **뽑기** — 조각마다 에이전트 하나가 그 조각이 정한 것(규칙·값·절차·이름)을 한 줄씩 뽑는다. 이름표는 `scripts/audit_topics.sh`가 낸 닫힌 목록에서만 고르고, 역할은 정본(`canon`)·따름(`follows`)·둘 다 아님(`none`) 셋이다. 조각은 `scripts/audit_targets.sh`가 낸다.
- **모으기** — 스크립트 안의 코드가 이름표별로 묶고 둘 이상의 문서에서 온 묶음만 남긴다. 정본 관계는 세 규칙으로 도출한다. 원칙 ID와 정본 절 제목의 정본은 `agent-principles.md`, 스킬과 명령 이름의 정본은 그 스킬과 그 명령, 정본 문서의 진술이 다른 문서를 정본으로 이름 부르면 그 이름표의 정본은 그 문서다. 묶음 입력의 크기는 렌즈에 넣는 문자열 길이로 세어 상한을 넘으면 나눈다.
- **대조** — 묶음마다 `lens-consistency` 하나를 띄운다. 판정 셋과 복제 도출은 그 렌즈의 「레포 문서 감사에서의 짝」 절이 정한다.

문자열 검사가 먼저다. 수치·열거·옛 이름은 `scripts/test_docs_drift.sh`가 먼저 거르고 LLM에는 그 뒤가 간다. 조건부 모순은 이 방법이 잡지 못하며 그 한계를 기록에 적는다.
```

`docs/superpowers/specs/2026-08-30-audit-unification-design.md`의 제목 줄 바로 아래에 빈 줄과 두 문장을 더한다.

```markdown
> 걸음 다섯과 걸음 넷의 「복제」 축은 `2026-09-02-audit-record-and-diff-design.md`가 잇는다. 「복제」 축은 체크리스트 항목이 아니라 대조 판정에서 도출된다.
```

- [ ] **Step 4: 셋째 회차를 돌린다**

Task 7 Step 4와 같이 실행체를 돌리고 요약문에 뿌리와 물음과 호출 수를 붙인다. 이어서 `docs/superpowers/reviews/2026-08-30-project-doc-audit-3-check.md`의 「일관성 결과 공백」에 적힌 어긋남을 하나씩 열어 지금 문서에 남아 있는지 보고, 남아 있는 것을 이번 회차의 `findings.json`이 잡았는지를 요약문 끝에 한 문단으로 적는다. 그다음 봉인한다. 리턴의 `run.topic_groups`가 양수인지, `diff.json`의 `items`에 둘째 회차 `diff.json`의 잔존 항목이 들어 있는지 확인한다.

- [ ] **Step 5: 돌려서 통과를 확인하고 커밋한다**

Run: 전체 테스트 명령.
Expected: `ALL PASS`.

```bash
git add skills/lens-consistency/SKILL.md skills/meta-aggregate/SKILL.md skills/domain-docs/SKILL.md skills/project-doc-audit/SKILL.md docs/superpowers/specs/2026-08-30-audit-unification-design.md scripts/test_self_audit.sh "docs/superpowers/reviews/<round>.md" "docs/superpowers/reviews/<round>/"
git commit -m "일관성 대조를 이름표 묶음 단위로 바꿔 절차와 렌즈와 집계 계약에 적고 셋째 회차 기록을 남긴다"
```

---

## 자가 검토

**spec 커버리지.** 「회차 기록의 구조」는 Task 6·7(파일 셋·요약문·`completed`)과 Task 9(`stale_rounds`·`diff.json` 채우기)가, 「회차 대조」는 Task 8·9가, 「기록을 잠그는 법」은 Task 3·4가, 「일관성 방법」은 Task 10·11·12가, 「실행체 재배선」은 Task 1(`verdicts`)·Task 2(`merged_from`)·Task 6(레포 확인·대상 도출·기록자·검수자·매니페스트)이, 「문서에 고칠 것」은 Task 4(README)·Task 7(절차 걸음 표·통합 기록)·Task 9(걸음 행·「회차 대조」)·Task 12(렌즈·집계·규율·절차·08-30)가 맡는다. 「덩어리 다섯의 순서」는 이 문서의 덩어리 순서다.

**spec 「계약 테스트」 열 항목의 대응.** 읽기 전용 훅 검사는 Task 4, 봉인 멱등과 `HEAD` 기록 읽기 전용은 Task 3, `node --check`는 Task 1, 실행체가 `audit_targets.sh`를 부르고 경로를 직접 적지 않고 레포 확인 걸음이 있는 것은 Task 6, `audit_targets.sh` 출력 성질과 조각 크기는 Task 5, `audit_topics.sh` 출력은 Task 10, `completed` 폴더 앵커와 파일 셋 파싱과 닫힌 집합과 `id` 유일성은 Task 7, 대체된 세 문장과 "짧은 문서 둘까지"의 소멸과 걸음 표 개수는 Task 7·9·12, 매니페스트 `workflows` 선언은 Task 6, 문턱 값이 한 곳에만 있는 것은 Task 5다. Task 2·8·9·11의 단언은 spec 목록 밖의 것으로, 실행체 내부 계약을 붙든다.

**spec 「성공 기준」 다섯의 대응.** 한 번 돌리면 파일 셋과 원본이 생기고 `completed`가 참인 것은 Task 7, 둘째 회차의 `diff.json`과 셋째 회차의 잔존 재대조는 Task 9·12, 봉인된 기록의 `Write`·`Edit` 거부는 Task 4, 묶음마다 호출 하나와 입력 상한은 Task 11(`groupSize`가 프롬프트에 넣는 문자열 길이를 센다)과 Task 5(조각 크기 단언), 08-30 어긋남의 재검출은 Task 12 Step 4가 호출자 판단으로 적는다. 정본 진술만으로 이미 상한을 넘는 묶음은 나눌 수 없어 `oversize`로 세어 요약문에 적는다.

**이름 일치.** `findingId`·`STATUS`·`ROUND`(Task 1), `DEDUP_SCHEMA`·`lensesOf`(Task 2), `STEPS`·`record`·`writeFile`·`writeRun`·`writeSummary`·`COUNT_RULE`·`run`·`findingsFile`·`diffFile`·`REVIEWS`·`DIR`(Task 6), `DIFF_VERDICTS`·`derivedFindings`(Task 9), `groupByTopic`·`groupSize`·`canonOf`·`CONSISTENCY_VERDICTS`(Task 11)는 처음 정의한 Task의 이름을 뒤 Task가 그대로 쓴다. `run`은 Task 2가 spec 표의 칸으로 정의하고 Task 6이 같은 칸으로 다시 초기화한다. 스크립트 셋의 이름과 출력 형식은 spec과 같다. 판정 값(`잔존`·`해소`·`미판정`, `어긋남`·`좁혀 적음`·`같음`)은 spec의 한글 그대로다.

**알려진 제약.** 기록자는 프롬프트에 든 JSON을 파일 하나씩 옮겨 적으므로 렌즈 원본이 많은 회차에서는 기록자 호출이 그만큼 늘지만 실패 단위는 파일 하나다. Task 7·9·12의 회차 실행은 300 호출 안팎이라 오래 걸리며, 끊기면 `-2` 이름으로 다시 돌리고 끊긴 폴더는 지우지도 커밋하지도 않는다. 회차 하나의 실제 호출 수는 요약문 끝에 호출자가 적는다.

<!-- spec-review: passed -->
