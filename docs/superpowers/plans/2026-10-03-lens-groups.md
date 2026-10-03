# 렌즈 그룹 재분류 구현 계획

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** 렌즈 선택 기준을 문서 유형별 배정표에서 `dispatching-lenses`가 소유하는 그룹표로 바꾸고, 호출자와 렌즈 문서와 검사 스크립트를 그 표에 맞춘다.

**Architecture:** `dispatching-lenses`에 「렌즈 그룹」 절을 새로 두고 「예외 목록」 절을 없앤다. 호출자(`review-docs`, `audit-repo-docs`, `review-specs`)와 렌즈 문서(`lens-prior-art`, `lens-readability`, `lens-consistency`)는 그 절을 가리키기만 한다. 검사 스크립트는 문장 대신 절 제목과 소유 선언과 포인터로 계약을 붙든다(`scripts/_doc_keys.sh`).

**Tech Stack:** 마크다운 스킬 문서, bash 검사 스크립트(`scripts/test_*.sh`), `scripts/_doc_keys.sh`의 `has_sec`·`sec_has`·`sec_has_id`·`owns_sec`·`points_to`.

**Spec:** `docs/superpowers/specs/2026-10-03-lens-groups-design.md`

## Global Constraints

- 작업 위치는 워크트리 `D:/projects/Structure/dc-lens-dispatch`, 브랜치 `lens-dispatch`다. main 작업 트리는 다른 세션(disciplined-coder-e4)이 쓰므로 그 안의 파일을 고치지 않는다.
- `agent-principles.md`, `skills/lens-fit/domain-discipline.md`, `skills/lens-readability/domain-korean.md`, `CLAUDE.md`는 e4가 소유한다. 이 계획은 그 파일을 고치지 않는다.
- 커밋은 로컬에만 쌓는다. e4의 원칙 퇴고는 main에 푸시되었고(`436dc6b`) 이 브랜치에 병합되어 있다(`2e3fbe5`). main으로의 병합은 Task 6 뒤에 사용자에게 묻는다.
- 검사 스크립트의 계약은 FAIL=0이다. 기대 개수를 숫자로 박지 않는다.
- 「전체 검사」는 저장소 `CLAUDE.md` 「변경 뒤 실행」의 한 줄이다.
  `d=$(mktemp -d); for t in scripts/test_*.sh; do ( bash "$t" > "$d/$(basename "$t").log" 2>&1 || echo "$t" >> "$d/bad" ) & done; wait; if [ -s "$d/bad" ]; then echo "FAILED:"; while read -r t; do echo "--- $t"; grep 'FAIL:' "$d/$(basename "$t").log"; done < "$d/bad"; else echo "ALL PASS"; fi`
- 「두 검사」는 `bash scripts/test_audit.sh 2>&1 | grep -E 'FAIL|PASS='; bash scripts/test_docs_drift.sh 2>&1 | grep -E 'FAIL|PASS='`이다. 모든 Task의 확인 단계는 두 검사를 함께 실행한다. 소유 선언과 포인터 검사는 `test_docs_drift.sh`에만 있기 때문이다.
- 위치는 줄 번호가 아니라 원문 문장과 검사 이름으로 찾는다. 앞 Task가 줄을 넣거나 빼면 줄 번호가 밀린다.
- 소유 선언 검사가 두 가지 있다. 「X」 뒤 20자 안에 "소유한다"가 오면 그 절은 스스로 "여기가 소유한다"를 선언해야 한다. 소유가 선언된 절의 이름을 적은 줄에는 소유자 이름(예: `dispatching-lenses`)이 같은 줄에 있어야 한다. 새 문안은 이 규칙을 따른다.
- 끊겼다가 이어 갈 때는 `git log --oneline`으로 마지막 Task 커밋을, `git diff`로 Task 안의 진행을 확인한다. 넣을 검사 이름이나 바꿀 새 문장이 이미 있으면 그 단계는 끝난 것으로 보고 넘어간다.
- 스킬 문서의 문장은 평서형("~한다")으로 쓴다. 명령형 규칙은 에이전트원칙에만 적용된다.
- 커밋 메시지 끝에 아래 두 줄을 붙인다.
  `Co-Authored-By: Claude Opus 5.5 (1M context) <noreply@anthropic.com>`
  `Claude-Session: https://claude.ai/code/session_01RYMqAu3n3nQohTiSH9eQtV`

## Review Focus

- **단계 수 문장** — `audit-repo-docs`에 단계 행을 넣으면 "단계는 열하나이고"가 낡는다. `test_audit.sh`의 단계 수 검사가 이것을 검출하며 Task 4가 "열둘"로 고친다. 이 검사의 숫자 읽기 함수(`KO_NUM`)는 열둘까지만 읽으므로 행은 하나만 넣는다.
- **단계 표의 절 이름** — 단계 표가 가리키는 「」 절은 `## 절 이름`과 글자가 같아야 한다. Task 4의 「렌즈 적용」 절 제목과 단계 표 칸을 같은 글자로 쓴다.
- **adversarial 근거 문장** — `test_audit.sh`는 `audit-repo-docs` 「실행할 때 지킬 것」에 `lens-adversarial`과 '자세'가 있기를 요구한다. 근거를 「렌즈 그룹」으로 옮겨도 그 절의 포인터 문장에 두 낱말을 남긴다(Task 4).
- **소유 선언 검사** — 새 문안이 「실행할 때 지킬 상한」이나 「목적 주입」처럼 소유를 선언하지 않은 절을 가리킬 때는 "정한다"로 쓴다. 「렌즈 그룹」을 적은 줄에는 `dispatching-lenses`를 함께 적는다(모든 Task).
- **새 렌즈 누락** — 렌즈를 새로 만들고 「렌즈 그룹」 표에 넣지 않으면 그룹 완전성 검사가 실패한다(Task 1).

---

### Task 1: dispatching-lenses의 「렌즈 그룹」

**Files:**
- Modify: `skills/dispatching-lenses/SKILL.md` (설명, 「한 번만 실행하는 렌즈의 규율」, 「따로 실행할 때와 묶을 때」, 「예외 목록」 절)
- Modify: `skills/audit-repo-docs/SKILL.md` (「일관성 대조」의 「예외 목록」 포인터 한 줄)
- Test: `scripts/test_audit.sh`, `scripts/test_docs_drift.sh`

**Interfaces:**
- Produces: 절 제목 `## 렌즈 그룹`. 이 절은 "여기가 소유한다"를 선언하고 렌즈 표에 `skills/lens-*` 디렉터리 이름을 모두 백틱으로 적는다. 뒤 Task의 포인터는 모두 "`dispatching-lenses`의 「렌즈 그룹」"이라고 쓴다.

- [ ] **Step 1: 검사를 먼저 바꾼다**

`scripts/test_audit.sh`의 `check "묶는 규칙의 예외를 소유자가 적는다" …` 줄을 아래로 바꾼다.

```bash
check "렌즈 그룹을 소유자가 적는다" "owns_sec '$DISP' '렌즈 그룹' && sec_has_id '$DISP' '렌즈 그룹' lens-adversarial"
```

`scripts/test_audit.sh`의 `check "spec 리뷰가 그 예외를 베끼지 않는다" …` 줄을 아래로 바꾼다.

```bash
check "spec 리뷰가 그 그룹 규칙을 베끼지 않는다" "! has_sec '$SR' '렌즈 그룹' && ! has_sec '$SR' '따로 실행할 때와 묶을 때' && ! grep -qF '자세가 반대인' '$SR'"
```

`scripts/test_docs_drift.sh`에서 `DISP_MISS=""`로 시작해 `check "예외 목록의 렌즈가 모두 실재한다" …`로 끝나는 블록을 아래로 바꾼다. 앞의 검사는 표의 렌즈가 실재하는지, 뒤의 검사는 실재하는 렌즈가 모두 표에 있는지를 본다.

```bash
DISP_MISS=""
while IFS= read -r n; do
  [ -n "$n" ] || continue
  if [ ! -d "$HERE/skills/$n" ]; then DISP_MISS="$DISP_MISS $n"; fi
done <<EOF
$(awk '/^## 렌즈 그룹/{f=1;next} /^## /{f=0} f' "$DISP" | grep -oE '`lens-[a-z-]+`' | tr -d '`' | sort -u)
EOF
check "렌즈 그룹 표의 렌즈가 모두 실재한다"      "[ -z \"\$DISP_MISS\" ]"
GROUP_MISS=""
for d in "$HERE"/skills/lens-*/; do
  n="$(basename "$d")"
  sec_has_id "$DISP" '렌즈 그룹' "$n" || GROUP_MISS="$GROUP_MISS $n"
done
check "실재하는 렌즈가 모두 렌즈 그룹 표에 있다" "[ -z \"\$GROUP_MISS\" ]"
```

- [ ] **Step 2: 검사가 실패하는지 본다**

Run: 「두 검사」
Expected: "렌즈 그룹을 소유자가 적는다"와 "실재하는 렌즈가 모두 렌즈 그룹 표에 있다"가 FAIL이다. "렌즈 그룹 표의 렌즈가 모두 실재한다"는 빈 목록이라 통과한다.

- [ ] **Step 3: 「예외 목록」 절을 「렌즈 그룹」 절로 바꾼다**

`skills/dispatching-lenses/SKILL.md`의 `## 예외 목록` 제목부터 그 절의 마지막 불릿(`- \`lens-consistency\` — 레포 문서 감사에서 …`)까지를 아래로 바꾼다.

```markdown
## 렌즈 그룹
이 구분은 여기가 소유한다. 각 렌즈 파일과 호출자는 이 절을 가리키고 내용을 베끼지 않는다. 렌즈는 실행 상황에 따라 그룹으로 나뉘고, 그룹이 어느 렌즈를 실행하는지와 어느 렌즈끼리 한 컨텍스트에 둘 수 있는지를 정한다. 문서 단위 그룹을 따로 실행할지 묶어 실행할지는 위 「따로 실행할 때와 묶을 때」가 정한다.

| 렌즈 | 그룹 | 자세 | 입력 | 한 컨텍스트에 함께 두는 렌즈 | 실행하는 호출자 |
|---|---|---|---|---|---|
| `lens-grounding` | 문서 단위 | 대조 | 문서 하나 | `lens-fit` | 모든 호출자 |
| `lens-fit` | 문서 단위 | 대조 | 문서 하나 | `lens-grounding` | 모든 호출자 |
| `lens-adversarial` | 묶음 전체 | 공격 | 전체 입력 | 없음 | `review-specs`, L2, `audit-repo-docs` |
| `lens-consistency` | 묶음 전체 | 대조 | 전체 입력 | 없음 | `review-specs`, L2, `audit-repo-docs` |
| `lens-readability` | 필요할 때 | 생성 | 문서와 목적 한 줄 | 없음 | `review-docs`, `audit-repo-docs` |
| `lens-prior-art` | 필요할 때 | 외부 탐색 | 설계와 웹 | 없음 | `review-specs`, `review-docs` |

자세는 렌즈가 대상을 보는 태도이고, 한 컨텍스트에 함께 둘 수 있는지를 정한다. 대조는 출처나 계약이나 다른 문서와 비교한다. 공격은 실패했다고 놓고 원인을 찾는다. 생성은 고친 문장을 내고 외부 탐색은 웹을 찾는다.

L2는 `nested-orchestration`의 하위 실행자이며 `review-specs` 절차를 따르되 사용자에게 묻지 못한다. 문서 단위 그룹은 모든 대상 문서에 실행한다. 묶어 실행하면 한 호출 안에서 `lens-grounding`, `lens-fit` 차례로 턴을 나눈다.

묶음 전체 그룹이 받는 전체 입력은 호출자마다 아래와 같다.

| 호출자 | `lens-adversarial`의 전체 입력 | `lens-consistency`의 전체 입력 |
|---|---|---|
| `review-specs`와 L2 | 검토 대상 문서 하나(spec 또는 plan) | 검토 대상 문서 하나와 그 짝 문서(plan이면 spec) |
| `audit-repo-docs` | 저장소 전체 | 값이 다른 짝 묶음 한 호출과, 소유를 선언한 문서마다 한 호출 |

`lens-adversarial`은 어느 렌즈와도 한 컨텍스트에 두지 않는다. 다른 렌즈는 문서를 출처와 대조하는 자세이고 이 렌즈는 설계를 공격하는 자세라, 대조에 이어 적용하면 앞선 대조가 뒤의 공격을 무디게 한다. 레포 감사에서 `lens-consistency`에는 값이 다른 짝 묶음을 한 호출에 주고, 짝마다 원문 앞뒤 다섯 줄과 어느 문서가 소유자인지를 함께 준다.

필요할 때 그룹의 렌즈는 다른 렌즈와 한 컨텍스트에 두지 않는다. 대상 문서가 여럿이면 그 렌즈끼리 묶어 실행할 수 있고, 그 호출도 실행하는 단계의 에이전트 상한 안에 센다. `lens-prior-art`는 웹에 나가므로 렌즈 하나로 세지 않고 서브에이전트 수로 센다. 그 상한은 `lens-prior-art`의 「실행할 때 지킬 상한」이 정한다.

필요할 때 그룹의 공통 규칙은 아래와 같다.

- **제안과 승인** — 발동 기준에 해당하면 실행할지 묻고, 승인받으면 실행한다.
- **제안 시점** — 호출자가 정한다. 기록을 쓰거나 봉인하기 전에 승인 여부가 정해지도록 둔다.
- **직접 요청** — 사용자가 직접 요청하면 그 요청이 승인이다. 발동 기준과 표의 실행하는 호출자 칸을 따지지 않는다.
- **판정 기록** — 제안했는지, 승인받았는지, 각각의 이유를 그 차수의 기록에 적는다. 조용한 생략을 차단한다.
- **L2** — 사용자에게 묻지 못하므로 제안하지 않는다. 발동 기준에 해당했다는 판정만 리포트에 적어 L1에 넘긴다.

`lens-readability`의 발동 기준은 호출자와 무관하게 하나다. 남에게 전달하는 문서이고 호출자가 목적 한 줄(읽는 사람과 그 사람이 할 수 있어야 하는 일)을 적을 수 있으면 제안한다. spec과 plan에는 제안하지 않는다. 목적 한 줄의 요건은 `lens-readability`의 「목적 주입」이 정한다.

`lens-prior-art`의 발동 기준은 호출자마다 달라 각 호출자가 정한다.
```

- [ ] **Step 4: 「예외 목록」을 가리키던 문장과 설명을 고친다**

`skills/dispatching-lenses/SKILL.md` 설명의 `어느 렌즈가 이 규율의 예외인지를 포함한다.`를 `어느 렌즈를 어느 그룹으로 실행하는지를 포함한다.`로 바꾼다.

「한 번만 실행하는 렌즈의 규율」의 `어느 렌즈에 무엇을 어떻게 묶어 주는지는 아래 「예외 목록」이 정한다.`를 `어느 렌즈에 무엇을 어떻게 묶어 주는지는 아래 「렌즈 그룹」이 정한다.`로 바꾼다.

「따로 실행할 때와 묶을 때」의 `그 예외는 아래 「예외 목록」이 소유한다.`를 `그 근거는 아래 「렌즈 그룹」이 소유한다.`로 바꾼다.

`skills/audit-repo-docs/SKILL.md` 「일관성 대조」의 `이 의무는 \`dispatching-lenses\`의 「예외 목록」이 소유한다.`를 `이 의무는 \`dispatching-lenses\`의 「렌즈 그룹」이 소유한다.`로 바꾼다. 이 줄을 이 Task에서 고치는 이유는 「예외 목록」의 소유 선언이 사라지는 순간 소유 선언 검사가 이 줄을 검출하기 때문이다.

- [ ] **Step 5: 검사가 통과하는지 본다**

Run: 「두 검사」, 이어서 `grep -n '「예외 목록」' skills/dispatching-lenses/SKILL.md skills/audit-repo-docs/SKILL.md`
Expected: 두 스크립트 모두 `FAIL=0`이고, 마지막 grep은 아무것도 내지 않는다.

- [ ] **Step 6: 커밋한다**

```bash
git add skills/dispatching-lenses/SKILL.md skills/audit-repo-docs/SKILL.md scripts/test_audit.sh scripts/test_docs_drift.sh
git commit -m "dispatching-lenses 의 예외 목록을 렌즈 그룹 절로 바꾸고 검사를 그 절에 맞춘다"
```

---

### Task 2: 렌즈 문서의 포인터와 대상 문구

**Files:**
- Modify: `skills/lens-consistency/SKILL.md`, `skills/lens-prior-art/SKILL.md`, `skills/lens-readability/SKILL.md`
- Test: `scripts/test_docs_drift.sh`

**Interfaces:**
- Consumes: Task 1의 `## 렌즈 그룹`.
- Produces: `lens-consistency`, `lens-prior-art`, `lens-readability`가 「예외 목록」과 "spec에 한해"와 "처음부터 끝까지"를 더 이상 적지 않는다.

- [ ] **Step 1: 검사를 먼저 넣는다**

`scripts/test_docs_drift.sh`에서 `check "실재하는 렌즈가 모두 렌즈 그룹 표에 있다" …` 줄 바로 뒤에 아래를 넣는다.

```bash
LCON="$HERE/skills/lens-consistency/SKILL.md"
LPA="$HERE/skills/lens-prior-art/SKILL.md"
LRD="$HERE/skills/lens-readability/SKILL.md"
check "lens-consistency 가 짝 주는 법을 렌즈 그룹으로 넘긴다" "points_to \"\$LCON\" '\`dispatching-lenses\`' '「렌즈 그룹」'"
check "lens-prior-art 가 spec 리뷰 전용이라고 적지 않는다"      "! grep -qF 'spec에 한해' \"\$LPA\" && ! grep -qF 'spec 리뷰와 사용자의 직접 요청)에만' \"\$LPA\" && grep -qF '「렌즈 그룹」' \"\$LPA\""
check "lens-readability 대상이 통독 문서가 아니라 전달 문서다" "! grep -qF '처음부터 끝까지' \"\$LRD\" && grep -qF '남에게 전달하는 문서' \"\$LRD\""
```

- [ ] **Step 2: 검사가 실패하는지 본다**

Run: 「두 검사」
Expected: Step 1에서 넣은 검사가 모두 FAIL이다.

- [ ] **Step 3: lens-consistency 포인터를 고친다**

`skills/lens-consistency/SKILL.md` 「레포 문서 감사에서의 짝」의 `호출자가 무엇을 어떻게 주는지는 \`dispatching-lenses\`의 「예외 목록」이 정한다.`를 `호출자가 무엇을 어떻게 주는지는 \`dispatching-lenses\`의 「렌즈 그룹」이 정한다.`로 바꾼다.

- [ ] **Step 4: lens-prior-art의 호출 범위를 고친다**

설명의 `review-specs가 spec에 한해 조건부로 호출하고, 사용자가 선행연구를 직접 청하면 spec이 없어도 연다.`를 `필요할 때 그룹(사용자 승인을 받아야 실행하는 렌즈 그룹)의 렌즈라 호출자가 발동 기준에 따라 제안하고 승인받아 실행하며, 사용자가 선행연구를 직접 청하면 spec이 없어도 연다.`로 바꾼다.

본문 첫 문단의 `실행은 \`review-specs\`가 spec에 한해 읽기 전용 서브에이전트로 실행한다.`를 `이 렌즈는 \`dispatching-lenses\`의 「렌즈 그룹」에서 필요할 때 그룹이며, 발동 기준은 호출자(\`review-specs\`와 \`review-docs\`)가 정하고 읽기 전용 서브에이전트로 실행한다.`로 바꾼다.

출력 스키마 아래의 `이 렌즈의 발견은 호출자가 전부 \`🔴\`로 처분한다. 웹에서 읽어 온 내용이 설계 문서를 자동으로 고치는 길을 닫기 위해서이며, 그 규칙은 \`review-specs\`가 소유한다.`를 `이 렌즈의 발견은 문서에 자동으로 반영하지 않는다. 웹에서 읽어 온 내용이 문서를 저절로 고치는 길을 닫기 위해서다. spec 리뷰에서는 발견을 전부 \`🔴\`로 처분하며 그 규칙은 \`review-specs\`가 소유한다. 문서 검진에서는 \`review-docs\`가 발견을 사용자에게만 전달한다.`로 바꾼다.

끝 문단의 `다만 이 렌즈는 설계 검토(spec 리뷰와 사용자의 직접 요청)에만 쓰고 제품 런타임 검증에는 쓰지 않는다.`를 `다만 이 렌즈는 설계 검토(spec 리뷰, 새 방법을 주장하는 문서의 검진, 사용자의 직접 요청)에만 쓰고 제품 런타임 검증에는 쓰지 않는다.`로 바꾼다.

- [ ] **Step 5: lens-readability의 대상 문구를 고친다**

`skills/lens-readability/SKILL.md` 설명의 `사람이 처음부터 끝까지 읽는 문서(README·인수인계·보고·제안서·발표자료 문안)가 대상이며 spec·plan에는 적용하지 않는다.`를 `남에게 전달하는 문서(README·인수인계·보고·제안서·발표자료 문안)가 대상이며 spec·plan에는 적용하지 않는다. 필요할 때 그룹(사용자 승인을 받아야 실행하는 렌즈 그룹)의 렌즈라 호출자가 제안하고 승인받아 실행한다.`로 바꾼다.

- [ ] **Step 6: 검사가 통과하는지 본다**

Run: 「두 검사」
Expected: 두 스크립트 모두 `FAIL=0`이다.

- [ ] **Step 7: 커밋한다**

```bash
git add skills/lens-consistency/SKILL.md skills/lens-prior-art/SKILL.md skills/lens-readability/SKILL.md scripts/test_docs_drift.sh
git commit -m "렌즈 문서가 렌즈 그룹을 가리키고 readability 대상을 전달 문서로 맞춘다"
```

---

### Task 3: review-docs의 「필요할 때 렌즈」

**Files:**
- Modify: `skills/review-docs/SKILL.md` (「lens-fit에 넘기는 계약」, 「언제 여는지」, 「셋째 렌즈를 추가하는 조건」, 「외부에 공개하는 문서」)
- Test: `scripts/test_docs_drift.sh`

**Interfaces:**
- Consumes: Task 1의 `## 렌즈 그룹`, `review-specs`의 「웹에 나가는 렌즈의 인용 검증」 절(그대로 둔다).
- Produces: 절 제목 `## 필요할 때 렌즈`. 이 절이 `review-docs`의 선행연구 발동 기준을 정한다.

- [ ] **Step 1: 검사를 먼저 넣는다**

`scripts/test_docs_drift.sh`에서 `check "문서 검진이 재검진 금지를 소유자로 넘긴다" …` 줄 바로 뒤에 아래를 넣는다.

```bash
check "문서 검진에 필요할 때 렌즈 절이 있고 셋째 렌즈 절이 없다" "has_sec \"\$DOCS\" '필요할 때 렌즈' && ! has_sec \"\$DOCS\" '셋째 렌즈를 추가하는 조건'"
check "그 절이 공통 규칙을 렌즈 그룹으로 넘긴다"               "sec_has \"\$DOCS\" '필요할 때 렌즈' '「렌즈 그룹」'"
check "그 절이 선행연구 인용 검증을 spec 리뷰 절로 넘긴다"     "sec_has \"\$DOCS\" '필요할 때 렌즈' '「웹에 나가는 렌즈의 인용 검증」'"
check "공개 문서가 readability 를 묻지 않고 거치지 않는다"     "! grep -qF '\`lens-fit\`과 \`lens-readability\` 검수를 거친다' \"\$DOCS\""
```

- [ ] **Step 2: 검사가 실패하는지 본다**

Run: 「두 검사」
Expected: Step 1에서 넣은 검사가 모두 FAIL이다.

- [ ] **Step 3: 「셋째 렌즈를 추가하는 조건」 절을 바꾼다**

`skills/review-docs/SKILL.md`의 `## 셋째 렌즈를 추가하는 조건` 제목부터 `## 외부에 공개하는 문서` 바로 앞까지를 아래로 바꾼다.

```markdown
## 필요할 때 렌즈

이 절은 이 절차의 선행연구 발동 기준을 정한다. 필요할 때 그룹의 공통 규칙(제안과 승인, 직접 요청, 판정 기록)과 `lens-readability`의 발동 기준은 `dispatching-lenses`의 「렌즈 그룹」이 소유한다. 제안 시점은 위 「언제 여는지」의 검진 전 질문이며, 필요할 때 렌즈를 그 질문의 선택지에 합쳐 한 번만 묻는다.

`lens-readability`는 `dispatching-lenses`의 「렌즈 그룹」이 정한 발동 기준에 맞으면 제안한다. 목적 한 줄의 요건은 `lens-readability`의 「목적 주입」이 정한다. 목적을 한 줄로 못 적는 문서는 다듬을 문서가 아니라 다시 쓸 문서다. 이 렌즈가 돌려준 고친 문장은 그대로 붙여 넣지 않고 메인 세션이 원문과 나란히 놓고 반영한다.

`lens-prior-art`는 새 방법이나 시스템이나 운용 방식을 제안하고 그 효과나 실현 가능성을 주장하는 문서(제안서, 검토 자료)에 제안한다. 한 일을 전달하는 보고서, 인수인계, README, 설명 글에는 제안하지 않는다. 제안할 때는 검색어가 제3자의 로그에 남는다는 것을 함께 알린다. 질의 경계는 `lens-prior-art`의 「가드」가 정하며, 대조할 방법을 그 경계 안의 일반 용어로 적을 수 없으면 제안하지 않고 그 판정을 기록에 적는다.

선행연구를 실행했으면 `review-specs`의 「웹에 나가는 렌즈의 인용 검증」을 따르고, 결과는 「기록 파일 이름 규칙」의 `prior-art` 종류로 따로 남긴다. 발견은 문서에 반영하지 않고 사용자에게만 전달하며, 반영할지는 사용자가 정한다.

```

- [ ] **Step 4: 나머지 문장을 고친다**

「`lens-fit`에 넘기는 계약」의 `참조물처럼 \`lens-readability\`가 안 적용되는 문서도 이 경로로 에이전트원칙의 한국어 조항을 검사받는다.`를 `\`lens-readability\`를 실행하지 않은 문서도 이 경로로 에이전트원칙의 한국어 조항을 검사받는다.`로 바꾼다.

「언제 여는지」의 `물을 때는 \`ASK-OPTIONS\`대로 선택지가 있는 질문으로 묻고, 렌즈를 몇 개 실행하는지도 함께 보인다.`를 `물을 때는 \`ASK-OPTIONS\`대로 선택지가 있는 질문으로 묻고, 렌즈를 몇 개 실행하는지도 함께 보인다. 아래 「필요할 때 렌즈」를 실행할지도 이 질문에서 함께 묻는다.`로 바꾼다.

「외부에 공개하는 문서」의 `게시 전에 이 절차대로 \`lens-grounding\`과 \`lens-fit\`과 \`lens-readability\` 검수를 거친다.`를 `게시 전에 이 절차대로 \`lens-grounding\`과 \`lens-fit\` 검수를 거치고, \`lens-readability\`는 검진 전 질문에서 제안한다.`로 바꾼다.

- [ ] **Step 5: 검사가 통과하는지 본다**

Run: 「두 검사」
Expected: 두 스크립트 모두 `FAIL=0`이다. 대구 한도 검사가 실패하면 새 절의 "다듬을 문서가 아니라" 문장이 그 파일의 다른 대구와 겹친 것이므로, 새 절의 그 문장을 "목적을 한 줄로 못 적는 문서는 다시 써야 한다."로 바꾼다.

- [ ] **Step 6: 커밋한다**

```bash
git add skills/review-docs/SKILL.md scripts/test_docs_drift.sh
git commit -m "review-docs 의 셋째 렌즈 조건을 필요할 때 렌즈 절로 바꾸고 제안을 검진 전 질문에 합친다"
```

---

### Task 4: audit-repo-docs의 「렌즈 적용」

**Files:**
- Modify: `skills/audit-repo-docs/SKILL.md` (설명, 첫 문단, 「단계」, 「렌즈 배정 기준」, 「실행할 때 지킬 것」)
- Test: `scripts/test_audit.sh`

**Interfaces:**
- Consumes: Task 1의 `## 렌즈 그룹`.
- Produces: 절 제목 `## 렌즈 적용`. 단계 표가 그 절을 두 번 가리킨다.

- [ ] **Step 1: 검사를 먼저 넣는다**

`scripts/test_audit.sh`에서 `check "따로 도는 이유가 자세 차이라고 적는다" …` 줄 바로 뒤에 아래를 넣는다.

```bash
check "감사에 렌즈 적용 절이 있고 렌즈 배정 기준 절이 없다" "has_sec '$PDA' '렌즈 적용' && ! has_sec '$PDA' '렌즈 배정 기준'"
check "단계 표가 렌즈 적용 절을 가리킨다"                 "sec_has '$PDA' '단계' '「렌즈 적용」'"
check "렌즈 적용 절이 렌즈 그룹을 가리킨다"               "sec_has '$PDA' '렌즈 적용' '「렌즈 그룹」'"
check "문서 종류별로 렌즈를 고르지 않는다"                "! grep -qF '문서 종류에 따라 렌즈' '$PDA' && ! grep -qF '같은 문서 종류끼리' '$PDA'"
check "에이전트원칙 직접 읽기 규칙이 남아 있다"           "sec_has '$PDA' '렌즈 적용' '호출자가 직접 읽는다'"
```

- [ ] **Step 2: 검사가 실패하는지 본다**

Run: 「두 검사」
Expected: Step 1에서 넣은 검사가 모두 FAIL이다.

- [ ] **Step 3: 설명과 첫 문단과 단계 표를 고친다**

`문서 종류에 따라 렌즈를 배정해`는 설명과 첫 문단에 한 번씩 있다. 두 곳 모두 `렌즈 그룹에 따라 렌즈를 실행해`로 바꾼다(Edit의 `replace_all`을 쓴다).

`단계는 열하나이고 순서가 있다.`를 `단계는 열둘이고 순서가 있다.`로 바꾼다.

단계 표의 `| 대상을 헤아린다 | 「감사 대상 고르기」 절 |` 행 바로 뒤에 `| 필요할 때 렌즈를 제안하고 실행한다 | 「렌즈 적용」 절 |` 행을 넣는다.

단계 표의 `| 문서를 묶어 렌즈 호출을 실행한다 | 「렌즈 배정 기준」과 「실행할 때 지킬 것」 절 |`을 `| 문서를 묶어 렌즈 호출을 실행한다 | 「렌즈 적용」과 「실행할 때 지킬 것」 절 |`로 바꾼다.

- [ ] **Step 4: 「렌즈 배정 기준」 절을 「렌즈 적용」 절로 바꾼다**

`## 렌즈 배정 기준` 제목부터 `## 실행할 때 지킬 것` 바로 앞까지를 아래로 바꾼다. 원래 절의 「에이전트원칙 직접 읽기」 규칙은 새 절의 끝 문단으로 옮긴다.

```markdown
## 렌즈 적용
모든 대상 문서에 문서 단위 그룹을 `lens-grounding`, `lens-fit` 차례로 실행한다. 어느 렌즈가 어느 그룹이고 어느 렌즈끼리 한 컨텍스트에 두는지는 `dispatching-lenses`의 「렌즈 그룹」이 소유한다. 렌즈가 문서마다 달라지지 않으므로 차수끼리 대조할 수 있다. `lens-grounding`을 앞에 두는 것은 그것만 문서 밖 코드까지 뒤지기 때문이다.

`lens-consistency`는 문서별로 적용하지 않고 「일관성 대조」 절대로 값이 다른 짝마다 적용한다. `lens-adversarial`은 「실행할 때 지킬 것」대로 저장소 전체에 한 번 실행한다.

`lens-readability`는 대상을 헤아린 뒤 감사를 시작할 때 제안한다. `dispatching-lenses`의 「렌즈 그룹」이 정한 발동 기준에 맞는 문서 목록을 보이고 실행할지 묻는다(`ASK-OPTIONS`). 승인받은 문서에만 문서 단위 그룹과 다른 단계로 실행하며, 그 단계의 에이전트 상한(10개)을 따로 쓴다. 제안 여부와 승인 여부와 그 이유는 「통합 기록」의 감사 범위에 적는다.

`lens-readability`의 결과는 고쳐 쓴 문장 제안이라 확정 개수로 값어치를 판정하지 않는다. `lens-prior-art`는 제안하지 않는다. 감사는 기존 문서를 코드와 대조하는 일이고 새 설계를 다루지 않기 때문이다. 근본 원인이 「설계로 넘길 것」이 되면 그 spec의 `review-specs` 리뷰에서 발동 기준을 따진다.

`run.json`의 `targets`에 문서마다 적는 렌즈 근거는 "렌즈 그룹"이라고 적는다. 그 전 차수의 근거는 문서 종류였으므로, 두 차수의 근거를 비교하면 배정이 바뀐 차수를 알아볼 수 있다.

에이전트원칙은 호출자가 직접 읽는다. 렌즈에도 함께 적용해 두 판정을 대조하면 놓치는 것이 준다.

```

- [ ] **Step 5: 「실행할 때 지킬 것」의 문장을 고친다**

`한 문서에 렌즈가 둘 이상 적용되면 렌즈마다 따로 실행하지 말고 한 번에 실행한다.`를 `문서 단위 그룹의 두 렌즈는 렌즈마다 따로 실행하지 말고 한 번에 실행한다.`로 바꾼다.

`표가 \`lens-readability\`를 적용한 문서에는 목적 한 줄을 함께 준다.`를 `\`lens-readability\` 실행을 승인받은 문서에는 목적 한 줄을 함께 준다.`로 바꾼다.

`같은 문서 종류끼리 묶어 적용할 렌즈가 같게 한다. `를 지운다(뒤의 공백 하나까지).

`\`lens-adversarial\`은 문서별로 배정하지 않고 저장소 전체를 입력으로 따로 한 번 실행한다. 다른 렌즈는 문서를 출처와 대조하는 자세이고 이 렌즈는 설계를 공격하는 자세라, 문서별 호출에 이어 적용하면 앞선 대조가 뒤의 공격을 무디게 한다.`를 아래로 바꾼다.

```markdown
`lens-adversarial`은 문서별로 배정하지 않고 저장소 전체를 입력으로 따로 한 번 실행한다. 이 렌즈를 대조 렌즈와 한 컨텍스트에 두지 않는 근거는 자세의 차이이며 `dispatching-lenses`의 「렌즈 그룹」이 소유한다.
```

- [ ] **Step 6: 검사가 통과하는지 본다**

Run: 「두 검사」
Expected: 두 스크립트 모두 `FAIL=0`이다. `audit-repo-docs`의 단계 수 검사, 단계 표 절 검사, 적대적 렌즈를 저장소 전체에 실행한다는 검사, '자세' 검사도 통과한다.

- [ ] **Step 7: 커밋한다**

```bash
git add skills/audit-repo-docs/SKILL.md scripts/test_audit.sh
git commit -m "audit-repo-docs 의 문서 종류별 배정표를 렌즈 적용 절로 바꾸고 필요할 때 렌즈 단계를 넣는다"
```

---

### Task 5: review-specs의 선행연구 제안 시점

**Files:**
- Modify: `skills/review-specs/SKILL.md` (「절차」 단계 표, 「1) PREP」, 「2) 디스패치」, 「선행연구 렌즈의 제안과 승인」, 「리뷰 기록」)
- Test: `scripts/test_audit.sh`

**Interfaces:**
- Consumes: Task 1의 `## 렌즈 그룹`.
- Produces: `review-specs`가 선행연구를 렌즈 실행 전 준비 단계에서 제안하고, 승인 여부를 리뷰 기록에 남긴다. spec·plan 구분, spec의 발동 기준, 상한, 웹 도구 확인, 별도 기록, `🔴` 처분, 「웹에 나가는 렌즈의 인용 검증」은 그대로 남는다.

- [ ] **Step 1: 검사를 먼저 넣는다**

`scripts/test_audit.sh`에서 `check "나누는 규칙의 예외가 lens-prior-art 이름과 한 문장에 묶여 있다" …` 줄 바로 뒤에 아래를 넣는다.

```bash
check "spec 리뷰가 필요할 때 그룹 공통 규칙을 렌즈 그룹으로 넘긴다" "sec_has '$SR' '선행연구 렌즈의 제안과 승인' '「렌즈 그룹」' && ! grep -qF '제안했든 안 했든 그 판정과 이유를 리뷰 보고에 적는 것은 무조건이다' '$SR'"
check "spec 리뷰가 선행연구를 준비 단계에서 제안한다"            "sec_has '$SR' '1) PREP' '「선행연구 렌즈의 제안과 승인」' && ! grep -qF '리뷰 결과를 전달할 때 선행연구 대조를 실행할지' '$SR'"
check "spec 리뷰 기록이 선행연구 승인 여부를 남긴다"            "sec_has '$SR' '리뷰 기록' '승인 여부'"
```

- [ ] **Step 2: 검사가 실패하는지 본다**

Run: 「두 검사」
Expected: Step 1에서 넣은 검사가 모두 FAIL이다.

- [ ] **Step 3: 단계 표와 준비 단계를 고친다**

「절차」 단계 표의 마지막 행 `| 선행연구 렌즈를 실행할지 제안한다 | 「선행연구 렌즈의 제안과 승인」 절 |`을 지우고, 같은 행을 `| 준비한다 | 「1) PREP」 |` 행 바로 뒤에 넣는다. 행 수는 그대로다.

「1) PREP」의 `- **타깃 체크리스트** — 그 렌즈가 무엇을 볼지 미리 명세한다.` 줄 바로 뒤에 아래 줄을 넣는다.

```markdown
- **선행연구 제안** — 렌즈를 실행하기 전에 「선행연구 렌즈의 제안과 승인」대로 실행할지 묻고, 승인받으면 렌즈와 동시에 실행한다.
```

- [ ] **Step 4: 선행연구 절과 리뷰 기록의 문장을 고친다**

「2) 디스패치」의 `선행연구 대조는 위 목록에 들어 있지 않다. 기본 묶음에서 빠져 있으며 제안과 승인을 거쳐 따로 실행된다.`를 `선행연구 대조는 위 목록에 들어 있지 않다. \`dispatching-lenses\`의 「렌즈 그룹」에서 필요할 때 그룹이라 제안과 승인을 거쳐 따로 실행된다.`로 바꾼다.

「선행연구 렌즈의 제안과 승인」 첫 문단 `선행연구 렌즈는 제안하고 승인받아 따로 실행한다. 제안했든 안 했든 그 판정과 이유를 리뷰 보고에 적는 것은 무조건이다. 생략을 금지할 수는 없지만 조용히 생략되는 것은 차단한다.`를 `선행연구 렌즈는 필요할 때 그룹이다. 제안과 승인, 직접 요청, 판정 기록, L2 처리는 \`dispatching-lenses\`의 「렌즈 그룹」이 소유한다. 이 절은 spec·plan 구분과 spec의 발동 기준과 제안 시점을 정한다.`로 바꾼다.

같은 절의 `기준에 적용되면 리뷰 결과를 전달할 때 선행연구 대조를 실행할지 함께 묻는다. 승인받으면 읽기 전용 서브에이전트로 따로 실행한다. 사용자가 선행연구를 직접 청했으면 그것이 승인이다. 발동 기준을 따지지 않고 제안 단계를 생략하며, 통상과 최대한 중 어느 쪽인지만 묻는다.`를 `제안 시점은 렌즈를 실행하기 전 「1) PREP」이다. spec의 발동 기준은 spec 내용만으로 판단하므로 리뷰 결과를 기다리지 않는다. 승인받으면 읽기 전용 서브에이전트로 렌즈와 동시에 실행하고, 사용자가 직접 청했으면 통상과 최대한 중 어느 쪽인지만 묻는다.`로 바꾼다. 그 줄의 나머지 문장(`물을 때 통상으로 실행할지 …`부터)은 그대로 둔다.

「리뷰 기록」의 `그리고 선행연구 렌즈를 붙였는지와 그 판정 이유다.`를 `그리고 선행연구 렌즈를 제안했는지와 승인 여부와 그 판정 이유다.`로 바꾼다.

- [ ] **Step 5: 검사가 통과하는지 본다**

Run: 「두 검사」
Expected: 두 스크립트 모두 `FAIL=0`이다. `review-specs`의 단계 수 검사("단계는 아홉")와 "spec 리뷰가 그 그룹 규칙을 베끼지 않는다", "`lens-prior-art` 하나" 포인터 검사도 통과한다.

- [ ] **Step 6: 커밋한다**

```bash
git add skills/review-specs/SKILL.md scripts/test_audit.sh
git commit -m "review-specs 가 선행연구를 준비 단계에서 제안하고 공통 규칙을 렌즈 그룹으로 넘긴다"
```

---

### Task 6: 전역 검사와 완료 확인

**Files:**
- Test: `scripts/test_docs_drift.sh`

**Interfaces:**
- Consumes: Task 1~5의 모든 변경.

- [ ] **Step 1: 재발 금지와 옛 포인터 검사를 넣는다**

`scripts/test_docs_drift.sh`에서 `check "lens-readability 대상이 통독 문서가 아니라 전달 문서다" …` 줄 바로 뒤에 아래를 넣는다. 검색 대상을 `skills`와 `README.md`로 한정하므로 `scripts/test_docs_drift.sh` 주석의 "예외 목록"은 검출되지 않는다.

```bash
for CF in review-docs audit-repo-docs review-specs; do
  check "$CF 에 배정표 절이 다시 생기지 않았다" "! has_sec '$HERE/skills/$CF/SKILL.md' '렌즈 배정 기준' && ! has_sec '$HERE/skills/$CF/SKILL.md' '셋째 렌즈를 추가하는 조건'"
done
OLD_PTR="$(grep -rlF -e '「예외 목록」' -e '「렌즈 배정 기준」' -e '「셋째 렌즈를 추가하는 조건」' -e '문서 종류에 따라 렌즈' -e '표가 `lens-readability`' "$HERE/skills" "$HERE/README.md" || true)"
check "스킬과 README 가 없어진 절과 배정표를 가리키지 않는다" "[ -z \"\$OLD_PTR\" ]"
```

- [ ] **Step 2: 전체 검사를 실행한다**

Run: 「전체 검사」
Expected: `ALL PASS`.

- [ ] **Step 3: 플러그인 검증을 실행한다**

Run: `claude plugin validate ./`
Expected: `version` 경고 하나만 나온다.

- [ ] **Step 4: 옛 포인터를 직접 확인한다**

Run: `grep -rn "「예외 목록」\|「렌즈 배정 기준」\|「셋째 렌즈를 추가하는 조건」\|문서 종류에 따라 렌즈\|표가 \`lens-readability\`" skills README.md`
Expected: 아무것도 나오지 않는다.

- [ ] **Step 5: 커밋한다**

```bash
git add scripts/test_docs_drift.sh
git commit -m "배정표 재발과 옛 절 포인터를 막는 검사를 넣는다"
```

- [ ] **Step 6: 병합 여부를 묻는다**

main이 이 브랜치에 병합된 `436dc6b` 뒤로 더 움직였는지 `git log --oneline lens-dispatch..main`으로 확인한다. 움직였으면 `git merge main`으로 받아 충돌을 풀고 「전체 검사」를 다시 실행한다. 그다음 `lens-dispatch`를 main에 병합할지 사용자에게 묻고, 병합 전에 e4에 알린다.

<!-- spec-review: escalated -->
