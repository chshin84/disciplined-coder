# 감사 뿌리 여덟 구현 계획

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** 첫 자기감사 회차가 찾은 뿌리 여덟을 고쳐, 렌즈 운용 규율의 소유자를 하나로 세우고 감사 회차가 저장소 스크립트만으로 돌게 만든다.

**Architecture:** 소유자를 먼저 세우고(새 스킬 `dispatching-lenses`, meta-aggregate 계약, domain-docs), 따르는 문서가 소유자를 가리키기만 하게 고치고, 마지막에 스크립트와 기록 계약을 절차에 맞춘다. 단계마다 그 단계가 깨는 계약 테스트 단언을 같은 커밋에서 먼저 고쳐 빨간 불을 보고 나서 문서와 스크립트를 바꾼다.

**Tech Stack:** bash(POSIX sh 확장), 파이썬 3(스크립트 안 `json_run` 헬퍼가 인터프리터를 고르고 `PYTHONUTF8=1`을 세운다), 계약 테스트 다섯(`scripts/test_*.sh`), `claude plugin validate ./`.

**Spec:** `docs/superpowers/specs/2026-09-05-audit-roots-design.md`

**Review:** `docs/superpowers/reviews/2026-09-05-audit-roots-plan-review.md`(이 계획의 리뷰 스물여덟을 반영한 판이다)

## Global Constraints

- 각 테스트 스크립트의 계약은 **FAIL=0**이다. 기대 개수를 숫자로 박지 않는다(`SSOT`).
- 단계 끝마다 `bash scripts/test_assertions.sh`, `bash scripts/test_audit.sh`, `bash scripts/test_docs_drift.sh`, `bash scripts/test_hooks.sh`, `bash scripts/test_scaffold.sh`를 각각 돌리고 그다음 `claude plugin validate ./`를 돌린다. `validate`는 `version` 경고 하나만 내면 정상이다.
- 이 워크트리의 격리 검사는 **셸 도구에 직접 넣는 명령**에서 `for` 반복문, heredoc(특히 `git`이라는 낱말이 든 것), `$((...))`, `sed -n`을 거부한다. 테스트 스크립트 **파일 안**의 `for`와 heredoc은 상관없다. 계약 테스트는 하나씩 따로 호출하고, 확인용 파이썬은 `-c` 문자열이 아니라 스크래치 폴더에 파일로 써서 `python -X utf8 <파일>`로 돌린다. 커밋 메시지는 `git commit -q -F - <<'EOF' … EOF` 꼴이 통과한다.
- 문서를 옮길 때는 문장을 다시 쓰지 않고 글자 그대로 옮긴다(정본 「Karpathy 지침」의 Surgical Changes). 계약 테스트가 그 문장을 글자로 찾는다. 앵커가 안 걸린 문장도 그대로 옮긴다. 리뷰가 "옮기다 흘려도 계약 테스트가 통과한다"를 위험으로 올렸으므로, 절을 옮길 때는 옮기기 전후로 그 절의 비어 있지 않은 줄 수를 세어 같은지 확인한다.
- `docs/superpowers/reviews/` 아래 기록은 읽기 전용으로 봉인돼 있다. 어떤 과제도 그 파일을 고치지 않는다. `scripts/seal_reviews.sh`를 인자 없이 부르지 않는다. 인자 없이 부르면 이 워크트리의 기록 전부가 읽기 전용이 되고 되돌리는 걸음이 계획에 없다.
- 판정 상태의 닫힌 집합은 `skills/project-doc-audit/SKILL.md` 「판정」 절의 한 문장이 정본이다. 스크립트와 테스트는 그 문장에서 뽑아 쓰고 리터럴로 박지 않는다.
- 빨간 불을 확인할 때마다 실패 형태 셋을 함께 본다. 고치기 전에 이미 통과하는 단언인가. 자기 픽스처를 되읽는 단언인가. 리터럴 하나만 겨누는 단언인가. 이 셋 가운데 하나에 걸리면 그 단언을 다시 쓴다. 각 단계의 빨간 불 걸음이 기대 FAIL 수를 적으므로, 그 수와 실제가 다르면 어느 단언이 셋 중 하나에 걸린 것이다.
- 커밋 메시지는 한국어 한 줄 제목과 본문으로 쓰고 끝에 다음 두 줄을 붙인다.
  ```
  Co-Authored-By: Claude Opus 5 (1M context) <noreply@anthropic.com>
  Claude-Session: https://claude.ai/code/session_01T1Daa3xJNPhZBQa8DbnvRj
  ```

---

### Task 0: 다른 세션의 커밋 위로 옮긴다

**Files:**
- Modify: 없음(브랜치 위치만 바꾼다)

**Interfaces:**
- Consumes: main 브랜치에 들어온 다른 세션의 커밋 `b24fdfa`(정본 「Karpathy 지침」 절과 스킬 여섯·README·scaffold.sh 의 조항 참조 교체)
- Produces: 이후 모든 과제가 딛는 바탕 커밋

이 과제는 2026-09-05 에 끝났다. 아래에 실제로 한 것과 그 결과를 적는다. 다시 돌릴 일은 없다.

- [x] **Step 1: 다른 세션의 변경이 main 에 들어왔는지 확인한다**

Run: `git log --oneline -3 main`
Run: `grep -c 'Karpathy 지침' agent-principles.md`

Expected: main 의 최근 커밋에 정본과 스킬 여섯을 함께 만진 커밋이 있다.

결과는 이렇다. `b24fdfa` "카파시 지침 넷을 정본에 영어로 옮기고 겹치던 조항 다섯을 뺀다"가 main 에 있었다. 그 커밋은 정본에 「Karpathy 지침」 절을 영어로 넣고 조항 다섯(ASK-FORK·MEASURE-FIRST·SIMPLE·SURGICAL·TDD)을 이름까지 뺐으며, 그 이름을 부르던 스킬 여섯과 README 와 scaffold.sh 를 새 절 이름으로 고쳤다. 그 커밋이 없었으면 여기서 멈추고 사용자에게 알렸을 것이다(spec 「위험」 첫째 항).

- [x] **Step 2: 옮기기 전 위치를 적어 둔다**

Run: `git rev-parse HEAD`
Run: `git rev-parse main`

두 값을 적어 둔다. 앞은 되돌릴 자리이고 뒤는 도착해야 할 바탕이다. 옮기기 전 이 브랜치의 끝은 `54cd877` 이었다. 되돌릴 일이 생기면 그 자리다.

봉인된 기록 파일이 읽기 전용이라 rebase 가 덮어쓰지 못할 수 있다. 옮기기 전에 푼다.

```bash
chmod -R u+w docs/superpowers/reviews
```

- [x] **Step 3: 이 브랜치를 그 커밋 위로 옮긴다**

```bash
git rebase main
```

- [x] **Step 4: 충돌을 푼다**

충돌은 없었다. 이 브랜치의 커밋 다섯은 `docs/superpowers/` 아래 spec 과 plan 과 리뷰 기록만 만지고, `b24fdfa` 는 그 폴더를 만지지 않는다. 옮기는 절 셋(「렌즈에게 정본을 알리는 법」·「판단 앞에 기계를 세운다」·「한 번만 띄우는 렌즈의 규율」) 안의 문장도 그 커밋이 건드리지 않아, 절을 옮기다 옛 문장을 조용히 실어 나르는 갈래도 생기지 않았다.

풀 수 없는 충돌을 만났으면 `git rebase --abort` 로 되돌리고 사용자에게 알렸을 것이다. 그만두면 Step 5 의 확인이 실패하므로 조용히 지나가지 않는다.

- [x] **Step 5: 옮겨졌는지를 내용으로 확인한다**

Run: `git status --short`
Expected: 충돌 표시(`UU`)가 없고 rebase 진행 표시도 없다.

Run: `git merge-base --is-ancestor main HEAD; echo $?`
Expected: `0`

Run: `git rev-parse HEAD`
Expected: Step 2 에서 적어 둔 앞 값과 **다르다**

세 확인이 함께 서야 옮겨진 것이다. 충돌 표시가 없는 것만으로는 아예 안 돌렸거나 중간에 그만둔 것과 구별되지 않는다. Task 0 은 커밋을 만들지 않으므로 이 확인이 유일한 흔적이다. 셋이 다 섰고 브랜치의 끝은 `40323d4` 가 됐다.

- [x] **Step 6: 계약 테스트 다섯이 초록인지 확인한다**

Run: `bash scripts/test_assertions.sh`
Run: `bash scripts/test_audit.sh`
Run: `bash scripts/test_docs_drift.sh`
Run: `bash scripts/test_hooks.sh`
Run: `bash scripts/test_scaffold.sh`
Expected: 다섯 모두 `FAIL=0`

하나라도 빨간 불이면 rebase 가 깨뜨린 것이므로 그것부터 고친다.

---

### Task 1: dispatching-lenses 스킬을 세우고 포인터를 돌린다

**Files:**
- Create: `skills/dispatching-lenses/SKILL.md`
- Modify: `skills/domain-docs/SKILL.md`, `skills/meta-aggregate/SKILL.md`
- Modify: `README.md`, `agent-principles.md`, `skills/lens-prior-art/SKILL.md`, `skills/project-doc-audit/SKILL.md`, `skills/domain-llm-runtime/SKILL.md`, `skills/nested-orchestration/SKILL.md`, `skills/domain-spec-review/SKILL.md`
- Test: `scripts/test_docs_drift.sh`, `scripts/test_audit.sh`, `scripts/test_scaffold.sh`

**Interfaces:**
- Produces: 스킬 이름 `dispatching-lenses`, 절 제목 넷(「띄우는 방법」, 「렌즈에게 정본을 알리는 법」, 「판단 앞에 기계를 세운다」, 「한 번만 띄우는 렌즈의 규율」)과 「예외 목록」·「렌즈 이름 표준」·「호출자 목록」. Task 2 가 이 이름들로 참조 문장을 쓴다.
- Produces: meta-aggregate 「리뷰 산출물 계약」이 발견의 문턱과 예외의 소유자다. 「공통 계약의 예외」의 항목마다 `빠지는 칸:` 절이 붙어 검사가 거기서 도출한다. Task 2 가 렌즈 파일에서 문턱 문단을 지우고 여기를 가리킨다.

- [ ] **Step 1: 이 단계가 깨는 단언을 먼저 찾는다**

옮기거나 다시 쓰는 문장을 계약 테스트 **다섯 전부**에서 검색해 목록을 만든다. 손으로 열거하지 않는다(spec 4절). 리뷰가 앞 판에서 앵커 넷이 빠졌다고 짚었고 그 넷은 검색 대상 파일이 좁아서 빠진 것이었다.

```bash
grep -n '렌즈에게 정본을 알리는 법\|판단 앞에 기계를 세운다\|한 번만 띄우는 렌즈의 규율\|렌즈는 서브에이전트를 새로 열지 않는다\|대화 턴을\|3층 오케스트레이션은 이 금지의 예외다\|렌즈는 한 번씩만 띄운다\|여기서 다시 정하지 않는다\|렌즈끼리 볼 것을 나눠 주지 않는다\|-review-2.md\|렌즈는 판단만 한다\|새 프로젝트나 새 모델이나 새 의존이 필요하면 제안하지 않는다\|판단이라는 사실을 산출물에 적는다\|대상이 다르면 별개 호출이다\|정본 경로를 프롬프트에 넣어\|읽기 전용 에이전트도 Read는 갖는다\|비어 있지 않은 배열\|홈 해석이 어긋나는 환경에서\|OWNER_DOC\|TELL_SENT\|RULE_MARKS\|AGG_LINE\|"source"' scripts/test_assertions.sh scripts/test_audit.sh scripts/test_docs_drift.sh scripts/test_hooks.sh scripts/test_scaffold.sh
```

찾은 줄을 적어 둔다. 이 단계는 그 줄들을 전부 고친다. 줄 번호는 Task 0 의 rebase 뒤 밀릴 수 있으므로 문장으로 찾는다.

- [ ] **Step 2: 단언을 새 소유자로 돌린다(빨간 불을 만든다)**

`scripts/test_docs_drift.sh` 파일 위쪽 변수 선언 옆에 새 파일 변수를 더한다.

```bash
DISP="$HERE/skills/dispatching-lenses/SKILL.md"
```

그다음 `$DOCS`(domain-docs)를 겨누던 앵커를 `$DISP`로 옮긴다. 대상은 Step 1 의 검색이 알려 주며, 이 계획을 쓴 시점에는 '렌즈는 서브에이전트를 새로 열지 않는다', '대화 턴을', '3층 오케스트레이션은 이 금지의 예외다', '렌즈는 한 번씩만 띄운다', '여기서 다시 정하지 않는다', '렌즈끼리 볼 것을 나눠 주지 않는다'다. `-review-2.md`는 domain-docs 에 남는 기록 문단 안이므로 `$DOCS` 그대로 둔다.

「렌즈에게 정본을 알리는 법」 소유자 구획의 소유자 변수를 바꾼다.

```bash
OWNER_DOC="$HERE/skills/dispatching-lenses/SKILL.md"
```

같은 파일 아래쪽의 첫 항목 문장 구획도 소유자를 바꾸고, 베끼지 않는지 보는 반복문에서 새 소유자를 건너뛰게 한다.

```bash
TELL_SENT='정본 경로를 프롬프트에 넣어 렌즈가 직접 읽게 한다'
check "dispatching-lenses 가 그 문장을 갖는다" "grep -qF -- '$TELL_SENT' \"\$DISP\""
for f in "$HERE"/skills/*/SKILL.md; do
  case "$f" in */dispatching-lenses/*) continue ;; esac
  check "$(basename "$(dirname "$f")") 이 베끼지 않는다" "! grep -qF -- '$TELL_SENT' '$f'"
done
```

집계 태깅 구획이 `"source"` 줄에서 렌즈 집합을 뽑던 것을 `"lens"` 줄에서 뽑게 바꾼다. spec 4절이 요구한 전환이고, 이것을 안 하면 Step 11 이 `source` 열거를 지우는 순간 그 단언이 깨진다.

```bash
AGG_LINE="$(grep -F '"lens"' "$AGG" | head -1 || true)"
AGGSET="$(printf '%s' "$AGG_LINE" | sed 's/.*"lens"[[:space:]]*:[[:space:]]*"\([^"]*\)".*/\1/' | tr '|' '\n' | sed 's/^ *//; s/ *$//' | grep -v '^$' | sort || true)"
```

단언 이름도 함께 고친다.

```bash
check "meta-aggregate lens 줄을 찾았다"          "[ -n \"\$AGG_LINE\" ]"
check "meta-aggregate가 렌즈 전부를 태깅한다"    "[ \"\$AGGSET\" = \"\$ALL\" ]"
```

예외 렌즈의 `consequence` 부재 단언을 바꾼다. 지금 꼴은 예외 렌즈에 `consequence`가 없기를 요구하는데 `lens-prior-art`는 그 칸을 담으므로 Step 11 이 예외를 더하는 순간 깨진다. 새 꼴은 meta-aggregate 예외 항목의 `빠지는 칸:` 절에서 이름을 뽑아 그 렌즈의 출력 스키마 줄에 없는지 본다. 목록을 검사에 손으로 적지 않는다.

```bash
while IFS= read -r n; do
  [ -n "$n" ] || continue
  EXC_BULLET="$(awk '/^## 공통 계약의 예외/{f=1;next} /^## /{f=0} f' "$AGG" | grep -F "\`$n\`" | grep -oE '빠지는 칸: .*$' || true)"
  check "$n 예외가 빠지는 칸을 적는다" "[ -n \"\$EXC_BULLET\" ]"
  SCHEMA_LINE="$(grep -F '"lens": "' "$HERE/skills/$n/SKILL.md" | head -1 || true)"
  EXC_BAD=""
  while IFS= read -r k; do
    [ -n "$k" ] || continue
    if printf '%s' "$SCHEMA_LINE" | grep -qF "\"$k\""; then EXC_BAD="$EXC_BAD $k"; fi
  done <<EOF
$(printf '%s' "$EXC_BULLET" | grep -oE '`[a-z_]+`' | tr -d '`')
EOF
  check "$n 스키마에 빠지는 칸이 없다" "[ -z \"\$EXC_BAD\" ]"
done <<EOF
$EXC_LENSES
EOF
```

개수 훑기 목록에 새 스킬을 넣는다.

```bash
COUNT_SCAN="$AGG $HERE/skills/lens-*/SKILL.md $HERE/skills/domain-docs/SKILL.md $DISP $CALLER $CANON $HERE/README.md"
```

`scripts/test_audit.sh` 위쪽에 같은 변수를 더하고 `$DD`(domain-docs)를 겨누던 앵커 넷('렌즈는 판단만 한다', '새 프로젝트나 새 모델이나 새 의존이 필요하면 제안하지 않는다', '판단이라는 사실을 산출물에 적는다', '대상이 다르면 별개 호출이다')을 새 파일로 돌린다.

```bash
DISP="$HERE/skills/dispatching-lenses/SKILL.md"
```

`scripts/test_scaffold.sh`의 domain-docs 참조 앵커도 같은 방식으로 옮긴다. 어느 줄인지는 Step 1 의 검색 결과가 알려 준다.

- [ ] **Step 3: 빨간 불을 확인한다**

Run: `bash scripts/test_docs_drift.sh`
Expected: FAIL 이 1 이상. `skills/dispatching-lenses/SKILL.md` 가 없어 `grep` 이 파일을 못 연다.

Run: `bash scripts/test_audit.sh`
Expected: FAIL 이 1 이상.

빨간 불이 난 단언 하나를 골라 실패 형태 셋에 걸리는지 본다. 이 단계의 단언은 없는 파일을 열어 실패하는 것이라 셋 어디에도 걸리지 않는다.

- [ ] **Step 4: 새 스킬 파일을 만든다**

`skills/dispatching-lenses/SKILL.md`를 만든다. frontmatter 는 이렇게 시작한다.

```markdown
---
name: dispatching-lenses
description: 읽기 전용 서브에이전트를 렌즈로 띄울 때 지키는 규율이다. 렌즈를 부르는 스킬이 연다. 몇 번 띄우는지, 정본을 어떻게 알리는지, 무엇을 기계에 먼저 넘기는지, 어느 렌즈가 이 규율의 예외인지를 담는다.
---
# dispatching-lenses — 렌즈를 띄울 때 지키는 규율

렌즈를 부르는 스킬이 이 문서를 연다. 여기가 규율의 소유자이고 호출자는 가리키기만 한다.
```

본문은 절 일곱이다. 아래 Step 5~7 이 나머지를 채운다.

1. `## 띄우는 방법` — `skills/domain-docs/SKILL.md` 「문서 검진 방법」에서 다음을 **글자 그대로** 옮긴다.
   - 첫 문단(비어 있지 않은 한 줄)의 뒤쪽 세 문장. "렌즈마다 따로 띄우지 않고 호출 하나가 그 문서를 한 번 읽고 렌즈를 차례로 적용한다.", "합산과 반박은 호출자가 직접 한다 — 파일을 열 수 있는 호출자는 서브에이전트를 하나 더 띄울 이유가 없다.", "호출자가 렌즈에 source를 주입하고, 렌즈는 JSON으로 지적을 리턴하며, 그 결과를 `meta-aggregate`로 한 목록에 모은 뒤 반영은 메인 세션이 한다."다. 리뷰가 이 셋째 문장이 옮길 목록에도 남길 꼴에도 없다고 짚어 여기 명시한다.
   - "띄우기 전에 아래 「렌즈에게 정본을 알리는 법」을 먼저 본다."(옮긴 뒤에도 '아래'가 같은 문서 안의 절을 가리켜 맞는다)
   - "렌즈는 한 번씩만 띄운다. 띄우는 횟수는 아래 「한 번만 띄우는 렌즈의 규율」이 소유하므로 여기서 다시 정하지 않는다."
   - "렌즈끼리 볼 것을 나눠 주지 않는다."로 시작하는 문단 전체
   - "렌즈 결과는 `meta-aggregate`의 「하는 일」 세 걸음으로 모은다."로 시작하는 문단 전체
2. `## 렌즈에게 정본을 알리는 법` — domain-docs 의 같은 이름 절을 제목까지 통째로 옮긴다.
3. `## 판단 앞에 기계를 세운다` — domain-docs 의 같은 이름 절을 제목까지 통째로 옮긴다.
4. `## 한 번만 띄우는 렌즈의 규율` — domain-docs 의 같은 이름 절을 제목까지 통째로 옮긴다.

옮기기 전에 domain-docs 의 비어 있지 않은 줄 수를 세고, 옮긴 뒤 두 파일의 합이 같은지 확인한다. 절을 옮기다 흘린 줄을 계약 테스트가 다 잡지는 못한다(Global Constraints).

Run: `grep -c . skills/domain-docs/SKILL.md`

- [ ] **Step 5: 예외 목록 절을 쓴다**

```markdown
## 예외 목록
위 규율의 예외는 넷이고 여기가 소유자다. 각 렌즈 파일과 호출자는 이 절을 가리키고 내용을 베끼지 않는다.

- `lens-adversarial` — 자세가 반대라 문서별 호출과 묶지 않고 따로 띄운다.
- `lens-prior-art` — 웹에 나가므로 렌즈 하나로 세지 않고 서브에이전트 수로 센다. 사용자 승인 아래 통상 둘, 최대 여섯이다.
- `lens-consistency` — 레포 문서 감사에서 호출자가 갈리는 짝 묶음을 한 호출에 주고, 짝마다 원문 앞뒤 다섯 줄과 정본 표시를 함께 준다.
- `lens-readability` — 목적이 둘이면 한 호출 안에서 둘을 차례로 보고 두 번 띄우지 않는다.

넷째는 `lens-readability`가 적던 것(두 번 돌리는 쪽을 먼저 고려한다)을 뒤집은 것이다. 한 번만 띄우는 규율과 맞서 규율 쪽에 맞췄다.
```

- [ ] **Step 6: 렌즈 이름 표준 절을 쓴다**

```markdown
## 렌즈 이름 표준
렌즈 이름은 `lens-` 접두사가 붙은 한 문자열이고 스킬 디렉터리 이름과 같다. 스키마의 `lens` 값, 기록 파일 이름, `findings.json`의 `lens` 칸이 모두 그 한 문자열이다. 짧은 이름(`grounding`)은 쓰지 않는다.
```

- [ ] **Step 7: 호출자 목록 절을 쓴다**

```markdown
## 호출자 목록
이 규율을 여는 스킬은 넷이다. `domain-spec-review`, `domain-docs`의 문서 검진, `project-doc-audit`, `nested-orchestration`의 L2 다.

`domain-llm-runtime`은 목록에 들지 않는다. 제품 코드가 리뷰 콜을 부르는 청사진이라 서브에이전트 규율이 걸리지 않는다. 다만 그 문서가 「판단 앞에 기계를 세운다」를 이름으로 부를 때는 소유자를 이 스킬로 적는다.
```

- [ ] **Step 8: domain-docs 에서 옮긴 것을 덜어낸다**

`skills/domain-docs/SKILL.md`에서 절 셋(「렌즈에게 정본을 알리는 법」, 「판단 앞에 기계를 세운다」, 「한 번만 띄우는 렌즈의 규율」)을 제목까지 통째로 지운다. 「문서 검진 방법」에서 Step 4 가 옮긴 문장들을 지운다.

첫 문단은 앞 두 문장만 남기고 소유자 포인터를 붙인다. 남는 꼴은 이렇다.

```markdown
이 방법은 여기가 소유자다. 일반 문서를 쓰거나 고친 뒤에는 `lens-grounding`(사실 정확)과 `lens-fit`(양식과 계약)을 건다. spec·plan과 달리 마커 게이트는 없다. 띄우는 방법은 `dispatching-lenses`가 정한다.
```

'아래 「렌즈에게 정본을 알리는 법」'과 '아래 「한 번만 띄우는 렌즈의 규율」'을 가리키던 문장 둘은 위 마지막 문장에 흡수돼 사라진다. 사람이 처음부터 끝까지 읽는 문서에 `lens-readability`를 더하는 문단은 어느 렌즈를 거는지라 domain-docs 에 남는다.

- [ ] **Step 9: domain-docs 의 나머지 다섯을 고친다**

- 「메모리와 백로그」에서 "공유되어야 하는 것은 git이 추적하는 문서에 둔다"를 지운다.
- 「문서 검진 방법」의 검진을 여는 갈래 앞에 한 문장을 더한다. "기존 문서를 고칠 때는 묻고, 새 spec·plan 을 처음 쓸 때는 Stop 게이트가 자동으로 강제한다."
- 문서 타입 표의 설계 행에 "과거 spec·plan 은 보존 목적이며 활용하지 않는다"를 더한다.
- 외부 공개 문서 항목의 렌즈를 「문서 검진 방법」과 같게 셋으로 맞춘다.
- 규범·인덱스 행의 빈 셀을 "없다. 포인터만 두므로 낡을 상태가 없다"로 채운다.

- [ ] **Step 10: domain-docs 의 기록 문단을 다시 쓴다**

```markdown
기록 이름은 `docs/superpowers/reviews/YYYY-MM-DD-<주제>-<종류>.md` 하나다. 종류는 넷이다. `review`는 spec·plan 리뷰이고, `check`는 문서 검진과 워크플로 검증이고, `prior-art`는 선행연구 대조이고, `audit`은 레포 감사다. 같은 날 둘째 회차는 종류 뒤에 회차를 붙인다(`…-review-2.md`). 이 규칙 전의 기록은 이름이 달라도 고치지 않는다.

렌즈별 원본은 요약문과 같은 이름의 폴더에 `lens-<렌즈 이름>-<띄운 횟수>.json`으로 둔다. 이 이름 규칙은 여기가 소유자이고 `scripts/audit_verify.sh`가 그대로 검사한다.

문서 검진의 기록은 요약문과 렌즈별 원본만이다. `suggestions.json`은 레포 감사의 파일이다.
```

실행체 조건 문장과 2026-09-03 시작일 문장을 지운다. 「문서 검진 방법」의 `<문서이름>`을 `<주제>`로 바꾼다.

- [ ] **Step 11: meta-aggregate 계약을 고친다**

「리뷰 산출물 계약」 절 끝(`fingerprint` 항목 뒤)에 발견의 문턱 세 문단을 더한다. 문장은 `skills/lens-grounding/SKILL.md` 「발견의 문턱」 절에 있는 것을 글자 그대로 옮긴다. 다음 셋이 반드시 든다. "발견 하나는 넷을 진다", "상대편을 못 대면 발견이 아니다", "지금 무엇이 그렇게 되어 있는지"와 "앞으로 벌어질 일을 적지 않는다".

「공통 계약의 예외」의 기존 `lens-readability` 항목 끝에 `빠지는 칸:` 절을 붙이고, `lens-prior-art` 항목을 새로 더한다. 리뷰가 앞 판의 "예외 둘을 더한다"는 개수가 실제와 다르다고, 그리고 검사가 이 절에서 도출할 자리가 없다고 짚었다.

```markdown
- `lens-readability` — 맞댈 상대편이 없어 위 공통 계약을 따르지 않는다. 산출물이 `issues`가 아니라 `suggestions`이고, 항목의 칸이 `where`·`why`·`rewrite` 셋이다. 빠지는 칸: `counterpart_file`·`counterpart`·`principle`·`consequence`.
- `lens-prior-art` — 맞댈 상대편이 레포 안에 없어 위 공통 계약을 따르지 않는다. `evidence`는 인용이나 경로나 URL 이고, 인용 검증은 호출자(`domain-spec-review`)가 자기 도구로 한다. 빠지는 칸: `counterpart_file`·`counterpart`·`principle`.
```

`빠지는 칸:` 뒤의 이름은 그 렌즈의 출력 스키마 줄에 실제로 없는 것만 적는다. Step 2 의 단언이 그 둘을 맞대므로 하나라도 틀리면 빨간 불이 난다.

계약 스키마의 `lens` 값을 접두사 형태로 고친다.

```
{ "lens": "lens-grounding|lens-fit|lens-consistency|lens-adversarial|lens-prior-art|lens-readability",
```

`where`의 뜻을 한 줄로 못 박는다.

```markdown
`where`의 뜻은 "검토 문서 안의 위치" 하나다. 레포 상대경로는 `file`이 진다.
```

렌즈 추가 칸에 `statements`를 올린다.

```markdown
- `statements` — 레포 문서 감사에서 문서별 호출이 돌려주는 `{topic, statement, evidence}` 목록이다. 집계 대상이 아니다. 이 칸을 요구하는 주체는 `project-doc-audit`의 「진술 받기」 걸음이다. 어느 문서의 진술인지는 항목이 아니라 그 호출의 원본 파일이 지는 `target` 칸이 안다.
```

「출력 스키마」의 `source` 열거를 지운다.

```
{ "decision": "accept|regenerate|escalate", "reason": "...", "aggregated": [ { "type": "...", "source": "<렌즈 리턴의 lens 값>", "where": "...", …
```

그 아래에 한 문장을 더한다.

```markdown
집계 항목의 `source`는 렌즈 리턴의 `lens` 값을 그대로 옮긴다. 렌즈 이름 열거는 위 「리뷰 산출물 계약」의 `lens` 하나뿐이다.
```

- [ ] **Step 12: 포인터를 새 소유자로 돌린다**

열세 자리다. 리뷰가 앞 판이 아홉으로 셌고 그 가운데 spec 리뷰 스킬 몫을 셋으로 세었으나 실제는 다섯이라고 짚었다.

- `README.md` 「주의」의 "어느 경로인지는 `skills/domain-docs/SKILL.md`가 정한다"를 `skills/dispatching-lenses/SKILL.md`로 바꾼다.
- `agent-principles.md` 「검증」의 "띄우는 방법은 `domain-docs`가 정한다"를 "띄우는 방법은 `dispatching-lenses`가 정한다"로 바꾼다.
- `skills/lens-prior-art/SKILL.md` 「띄울 때 지킬 상한」의 중첩 금지와 이어 묻기 소유자를 `dispatching-lenses`로 바꾼다.
- `skills/project-doc-audit/SKILL.md` 「기계가 하는 것」의 「판단 앞에 기계를 세운다」 소유자와 「띄울 때 지킬 것」의 참조를 `dispatching-lenses`로 바꾼다(두 자리).
- `skills/domain-llm-runtime/SKILL.md` 조립 절의 「한 번만 띄우는 렌즈의 규율」 참조와 렌즈 선택 절의 "`domain-docs`의 「판단 앞에 기계를 세운다」"를 바꾼다(두 자리).
- `skills/nested-orchestration/SKILL.md`의 「렌즈에게 정본을 알리는 법」 참조를 바꾼다.
- `skills/domain-spec-review/SKILL.md`의 `domain-docs` 참조 **다섯 자리**를 바꾼다. "이 문서 밖에서 가져올 것이 셋이다"의 "렌즈에게 원칙 정본을 알리는 법과 회차 수는 `domain-docs`에", 「2) 디스패치」의 「한 번만 띄우는 렌즈의 규율」 소유 문장 **셋**, "띄우기 전에 `domain-docs`의 「렌즈에게 정본을 알리는 법」을 본다"다. 같은 파일의 기록 이름 규칙 참조는 domain-docs 그대로 둔다.

`domain-llm-runtime` 조립 절의 문장 교체와 `domain-spec-review`의 lens-adversarial 예외 문장은 Task 2 가 만진다. 여기서는 소유자 이름만 돌린다.

- [ ] **Step 13: 새 단언 넷을 더한다**

`scripts/test_docs_drift.sh`에 더한다. 백틱이 든 검색 문자열은 변수에 담아 홑따옴표로 감싼다. 큰따옴표 안에 그대로 넣으면 백틱이 명령 치환으로 먹힌다. 리뷰가 앞 판에서 이것을 짚었다.

```bash
echo "[dispatching-lenses — 소유자가 하나다]"
DISP_PTR='띄우는 방법은 `dispatching-lenses`가 정한다'
check "domain-docs 에 렌즈 운용 절 제목이 없다" "! grep -qE '^## (렌즈에게 정본을 알리는 법|판단 앞에 기계를 세운다|한 번만 띄우는 렌즈의 규율)$' \"\$DOCS\""
check "domain-docs 가 띄우는 방법을 소유자로 넘긴다" "! grep -qF '렌즈 결과는' \"\$DOCS\" && grep -qF -- \"\$DISP_PTR\" \"\$DOCS\""
check "dispatching-lenses 가 띄우는 방법을 적는다" "grep -qF 'source를 주입' \"\$DISP\" && grep -qF '렌즈 결과는' \"\$DISP\""
DISP_MISS=""
while IFS= read -r n; do
  [ -n "$n" ] || continue
  if [ ! -d "$HERE/skills/$n" ]; then DISP_MISS="$DISP_MISS $n"; fi
done <<EOF
$(awk '/^## 예외 목록/{f=1;next} /^## /{f=0} f' "$DISP" | grep -oE '`lens-[a-z-]+`' | tr -d '`' | sort -u)
EOF
check "예외 목록의 렌즈가 모두 실재한다" "[ -z \"\$DISP_MISS\" ]"
```

- [ ] **Step 14: 계약 테스트 다섯을 돌린다**

Run: `bash scripts/test_assertions.sh`
Run: `bash scripts/test_audit.sh`
Run: `bash scripts/test_docs_drift.sh`
Run: `bash scripts/test_hooks.sh`
Run: `bash scripts/test_scaffold.sh`
Expected: 다섯 모두 `FAIL=0`

Run: `claude plugin validate ./`
Expected: `version` 경고 하나

- [ ] **Step 15: 커밋한다**

```bash
git add -A
git commit -q -F - <<'EOF'
렌즈 운용 규율을 dispatching-lenses 로 떼고 포인터 열셋을 돌린다

domain-docs 가 문서 저작과 렌즈 운용을 함께 지고 있어 렌즈 규율의
소유자가 하나가 아니었다. 절 셋과 띄우는 방법 문장을 새 스킬로 옮기고,
예외 넷과 이름 표준과 호출자 목록을 거기 모았다. meta-aggregate 는
발견의 문턱과 예외의 소유자가 됐고 렌즈 이름 열거가 하나로 줄었다.
예외 항목에 빠지는 칸을 적어 검사가 손 목록 대신 거기서 도출한다.

Co-Authored-By: Claude Opus 5 (1M context) <noreply@anthropic.com>
Claude-Session: https://claude.ai/code/session_01T1Daa3xJNPhZBQa8DbnvRj
EOF
```

---

### Task 2: 따르는 문서가 소유자를 가리키게 한다

**Files:**
- Modify: `skills/lens-grounding/SKILL.md`, `skills/lens-fit/SKILL.md`, `skills/lens-consistency/SKILL.md`, `skills/lens-adversarial/SKILL.md`, `skills/lens-prior-art/SKILL.md`, `skills/lens-readability/SKILL.md`
- Modify: `skills/domain-spec-review/SKILL.md`, `skills/project-doc-audit/SKILL.md`, `skills/domain-llm-runtime/SKILL.md`, `skills/nested-orchestration/SKILL.md`
- Modify: `agent-principles.md` (READ-FLOW 조항)
- Test: `scripts/test_audit.sh`, `scripts/test_docs_drift.sh`

**Interfaces:**
- Consumes: Task 1 이 만든 `dispatching-lenses`의 절 이름들과 meta-aggregate 「리뷰 산출물 계약」
- Produces: `project-doc-audit` 걸음 표가 열한 행이고 「진술 받기」가 `statements`를 요구하며 「표 대조」가 `scripts/audit_statements.sh`를 부른다. Task 3 이 그 계약을 받는다.

- [ ] **Step 1: 이 단계가 깨는 단언을 찾는다**

계약 테스트 **다섯 전부**를 검색한다. 리뷰가 앞 판이 두 파일만 봐서 렌즈 스키마 뒤 포인터 문장을 겨눈 단언을 놓쳤다고 짚었다.

```bash
grep -n '상대편을 못 대면 발견이 아니다\|앞으로 벌어질 일을 적지 않는다\|한 대상의 렌즈를 한 호출로 묶는\|저장소 전체를 입력으로\|여기서 다시 정하지 않는다\|렌즈는 한 번씩만 부른다\|걸음은\|KO_NUM\|PA_POINTER\|리뷰 산출물 계약이 정한다\|audit_topics.sh\|derived' scripts/test_assertions.sh scripts/test_audit.sh scripts/test_docs_drift.sh scripts/test_hooks.sh scripts/test_scaffold.sh
```

`scripts/test_scaffold.sh`가 렌즈마다 찾는 포인터 문자열은 `` `meta-aggregate`의 리뷰 산출물 계약이 정한다 ``이다. Step 4 가 넣는 문장이 이 글자를 그대로 담아야 그 단언이 산다.

- [ ] **Step 2: 단언을 옮기고 KO_NUM 을 늘린다(빨간 불을 만든다)**

`scripts/test_audit.sh`의 렌즈 넷 반복에서 「발견의 문턱」 앵커 둘을 meta-aggregate 로 돌린다. 그 파일이 meta-aggregate 경로를 담는 변수 이름은 `MA` 다. `AGG` 는 `test_docs_drift.sh` 의 이름이라 여기서 쓰면 `set -u` 아래 죽는다.

```bash
check "meta-aggregate 가 상대편을 필수로 적는다" "grep -qF 'counterpart' '$MA' && grep -qF '상대편을 못 대면 발견이 아니다' '$MA'"
check "meta-aggregate 가 결과 기준을 적는다"     "grep -qF '지금 무엇이 그렇게 되어 있는지' '$MA' && grep -qF '앞으로 벌어질 일을 적지 않는다' '$MA'"
```

렌즈 넷 반복 안에는 부재 단언을 남긴다.

```bash
check "$L 에 문턱 사본이 안 남았다" "! grep -qF '상대편을 못 대면 발견이 아니다' '$F'"
```

lens-adversarial 예외 문장을 겨누던 단언을 `dispatching-lenses` 예외 목록으로 돌린다.

```bash
check "묶는 규칙의 예외를 소유자가 적는다" "grep -qF 'lens-adversarial' '$DISP' && grep -qF '따로 띄운다' '$DISP'"
```

project-doc-audit 의 '저장소 전체를 입력으로' 문장은 그 파일에 남으므로 그 단언은 고치지 않는다.

`scripts/test_docs_drift.sh`의 domain-llm-runtime 앵커 둘('여기서 다시 정하지 않는다', '렌즈는 한 번씩만 부른다')을 바꾼다.

```bash
check "런타임은 서브에이전트 규율 밖이라고 적는다" "grep -qF '리뷰 콜은 제품 코드의 호출이라' \"\$RUNTIME2\""
```

`scripts/test_audit.sh`의 `KO_NUM` 에 낱말을 더한다. 이 함수 하나만 고치면 그 파일에 **이미 있는** 걸음 표 행 수 단언이 그대로 산다. 새 단언을 세우지 않는다. 리뷰가 앞 판이 같은 것을 재는 사본을 옆에 세웠다고 짚었다.

```bash
KO_NUM() { case "$1" in 하나) echo 1;; 둘) echo 2;; 셋) echo 3;; 넷) echo 4;; 다섯) echo 5;; 여섯) echo 6;; 일곱) echo 7;; 여덟) echo 8;; 아홉) echo 9;; 열) echo 10;; 열하나) echo 11;; 열둘) echo 12;; *) echo 0;; esac; }
```

- [ ] **Step 3: 빨간 불을 확인한다**

Run: `bash scripts/test_audit.sh`
Expected: FAIL 이 1 이상. meta-aggregate 에 문턱 문장이 없거나 렌즈 파일에 사본이 남아 실패한다.

Run: `bash scripts/test_docs_drift.sh`
Expected: FAIL 이 1 이상.

실패 형태 셋을 함께 본다. 걸음 표 단언은 문서를 고치기 전에는 여덟과 여덟이 맞아 초록이고, 문서를 열하나로 고치는 Step 8 뒤에 `KO_NUM` 확장이 없으면 빨간 불이 된다. 그래서 Step 2 의 `KO_NUM` 확장과 Step 8 의 표 확장이 같은 커밋에 든다.

- [ ] **Step 4: 렌즈 파일 여섯을 고친다**

여섯 파일에서 「발견의 문턱」 절의 세 문단과 스키마 뒤 SSOT 문단을 지우고 한 문장으로 바꾼다. 포인터 문자열은 `test_scaffold.sh`가 글자로 찾으므로 「」를 두르지 않는다.

```markdown
## 발견의 문턱
필드의 뜻과 문턱과 예외는 `meta-aggregate`의 리뷰 산출물 계약이 정한다.
```

절 자체가 없는 lens-prior-art 와 lens-readability 는 스키마 뒤 SSOT 문단만 위 한 문장으로 바꾼다.

lens-adversarial 의 `evidence` 둘째 뜻, lens-grounding 의 `where` 좌표계, lens-prior-art 의 `evidence` 재정의를 지운다. 셋 다 meta-aggregate 계약과 그 예외가 이미 진다.

- [ ] **Step 5: 렌즈 스키마의 lens 값을 접두사로 바꾼다**

여섯 파일의 출력 스키마 줄에서 짧은 이름을 디렉터리 이름과 같은 형태로 바꾼다. 리뷰가 앞 판이 이 값을 재는 단언만 더하고 바꾸는 걸음을 안 적었다고 짚었다.

| 파일 | 지금 | 바꾼 뒤 |
|---|---|---|
| `skills/lens-grounding/SKILL.md` | `"lens": "grounding"` | `"lens": "lens-grounding"` |
| `skills/lens-fit/SKILL.md` | `"lens": "fit"` | `"lens": "lens-fit"` |
| `skills/lens-consistency/SKILL.md` | `"lens": "consistency"` | `"lens": "lens-consistency"` |
| `skills/lens-adversarial/SKILL.md` | `"lens": "adversarial"` | `"lens": "lens-adversarial"` |
| `skills/lens-prior-art/SKILL.md` | `"lens": "prior-art"` | `"lens": "lens-prior-art"` |
| `skills/lens-readability/SKILL.md` | `"lens": "readability"` | `"lens": "lens-readability"` |

- [ ] **Step 6: lens-consistency 를 고친다**

「레포 문서 감사에서의 짝」에서 짝을 묶어 주는 의무를 소유자 참조로 바꾼다. 어긋남과 좁혀 적기의 판정 기준은 남긴다.

```markdown
## 레포 문서 감사에서의 짝
짝은 이름표 하나에 걸린 값이 다른 것들이다. 호출자가 무엇을 어떻게 주는지는 `dispatching-lenses`의 「예외 목록」이 정한다.

- **어긋남** — 같은 것을 다르게 정한다. 발견이 된다.
```

- [ ] **Step 7: lens-readability 를 고친다**

- 「기계에 넘기는 것」의 고정 규칙 되풀이를 `writing-korean` 참조 한 문장으로 바꾼다.
- 「읽기 범위」에 정본 읽기를 넣는다.
- 프롬프트의 금지 표현 검색 문장을 "기계가 이미 거른 것은 다시 세지 않는다"로 바꾼다.
- 목적 둘로 두 번 돌리는 문장을 지우고 예외 참조로 바꾼다.

```markdown
목적이 둘이면 한 호출 안에서 둘을 차례로 본다. 규칙은 `dispatching-lenses`의 「예외 목록」이 소유한다.
```

- `suggestions.json`은 레포 감사에서만 쓴다고 한 줄 적는다.

- [ ] **Step 8: project-doc-audit 을 고친다**

- 「띄울 때 지킬 것」의 규율 문장들을 `dispatching-lenses` 참조로 줄인다.
- 「진술 받기」에 두 문장을 더한다.

```markdown
문서별 호출 프롬프트에 `scripts/audit_topics.sh`가 낸 이름표 목록을 넣고 `statements`를 요구한다. 항목은 `{topic, statement, evidence}` 셋이며 계약은 `meta-aggregate`가 진다.
```

- 「일관성 대조」의 「표 대조」 걸음에 새 스크립트를 넣는다. 리뷰가 그 스크립트를 부르는 자리가 절차 문서 어디에도 없다고 짚었다.

```markdown
- **표 대조** — 호출자가 이름표별 표를 세운다. 이름표 목록은 `scripts/audit_topics.sh`가 내고, 문서별 호출이 돌려준 `statements`를 이름표별로 모으는 것은 `scripts/audit_statements.sh`가 한다.
```

- 「일관성 대조」에 걸음 둘을 더한다. 짝마다 정본 표시와 앞뒤 다섯 줄을 주는 걸음(소유자는 `dispatching-lenses`의 「예외 목록」), `duplication`을 도출하는 걸음이다.
- 걸음 표에 행 셋을 넣어 열한 행으로 만든다. 「회차 대조」를 「판정」 앞에, 「집계」와 「뿌리 찾기」를 「기록하고 넘긴다」 앞에 넣는다. "걸음은 여덟이고"를 "걸음은 열하나이고"로 바꾼다.
- 「회차 대조」의 대조 대상을 다시 쓴다.

```markdown
대조 대상은 앞선 회차 `findings.json`의 발견 전부(기각 포함)와 앞선 `diff.json`이다.
```

- 「회차 대조」 둘째 문단(재발마다 `derived` 발견을 새로 만든다)을 바꾸고 자동 기각의 두 갈래를 적는다. 리뷰가 사유가 소멸했을 때의 처분이 어느 문서에도 없다고 짚었다.

```markdown
재발은 `diff.json`의 항목으로만 남는다. 새 발견을 만들지 않는다.

`diff.json`의 `auto_rejected`에 오른 발견은 다시 판정하지 않는다. 세션은 앞선 기각 사유가 여전히 성립하는지만 확인한다. 성립하면 `status: rejected`와 `verdict_reason: 앞선 회차 기각 유지 — <사유>`를 붙인다. 성립하지 않으면 `status: undetermined`와 `verdict_reason: 앞선 기각 사유 소멸 — <사유>`를 붙이고 다시 판정하지 않는다. 다음 회차가 그것을 새 발견처럼 본다.
```

- 「통합 기록」 `findings.json` 항의 "판정을 거친 발견과 도출된 발견 전부"를 "판정을 거친 발견 전부"로, 요약문 항목의 "도출된 발견 목록"을 지운다.
- 「통합 기록」의 `metrics` 출력 열거에 `verdict_counts`를 더한다. 리뷰가 출력을 늘리면서 그것을 열거한 문장을 안 고쳤다고 짚었다.

```markdown
`metrics`는 `audit_rounds.sh metrics`의 출력(`by_lens`·`confirmed`·`tokens`·`seconds`·`tokens_per_confirmed`·`resolved_rate`·`verdict_counts`)을 그대로 담아
```

- 「판정」 절의 집합 문장에서 `derived`를 뺀다. 남는 꼴은 "`findings.json`의 `status`가 `confirmed`·`rejected`·`undetermined` 가운데 하나다."로 시작한다.
- 「판정」 절 마지막 문장을 바꾼다.

```markdown
픽스처 형태는 `scripts/test_audit.sh`가, 실제 기록은 `scripts/audit_verify.sh`가 검사한다.
```

- 「감사 대상 고르기」에 `scripts/audit_targets.sh`를 부르는 문장을 넣고 spec·plan 제외 사유를 바꾼다.

```markdown
spec 과 plan 은 대상에서 뺀다. 과거 것은 활용하지 않고 현재 것은 쓰는 시점에 리뷰를 받기 때문이다.
```

- 「기계가 하는 것」의 명령 **두 줄**을 Task 3 이 정하는 꼴로 고친다. 리뷰가 측정 줄의 마지막 인자 뜻이 갈린 채 남는다고 짚었다.

```markdown
- **대조** — `bash scripts/audit_rounds.sh diff --prior <앞선 findings.json> --prior-diff <앞선 diff.json> <이번 findings.json>`
- **측정** — `bash scripts/audit_rounds.sh metrics --tokens N --seconds N <이번 findings.json> [이번 diff.json]`
```

- 「통합 기록」에 검수 주체를 적는다.

```markdown
회차 끝에 `bash scripts/audit_verify.sh <회차 폴더>`를 돌려 통과한 뒤에만 `run.json`의 `completed`를 참으로 놓는다.
```

- [ ] **Step 9: domain-llm-runtime 을 고친다**

- 결정 집합 이름을 `accept`·`regenerate`·`escalate`로 맞춘다.
- fit 리뷰 시점을 lens-fit 가드와 같게 한다.
- grounding 출처를 요청과 맥락 하나로 한다.
- SECRETS 항목에 등급을 넣는다.
- 사람 승인 항목의 '정책'을 가리키는 문서 이름으로 바꾼다.
- 렌즈 하나인 호출의 집계 여부를 한 문장으로 못 박는다.
- 조립 절의 "띄우는 횟수는 「한 번만 띄우는 렌즈의 규율」이 소유" 문장을 바꾼다.

```markdown
리뷰 콜은 제품 코드의 호출이라 서브에이전트 규율이 걸리지 않고 병렬로 돌릴 수 있다.
```

- [ ] **Step 10: nested-orchestration 과 정본을 고친다**

- L2 의 diff 리뷰에서 렌즈에 줄 `source`를 적는다.
- 리포트 위치를 '프로젝트 밖' 하나로 통일한다.
- 「한계」의 진행 상태 문장을 spec 「검증 상태」 참조로 바꾼다.
- `agent-principles.md`의 READ-FLOW 조항 끝에 "상세는 `writing-korean`을 참고한다"를 붙인다.

- [ ] **Step 11: domain-spec-review 를 고친다**

- lens-adversarial 의 축을 넷으로 적는다.
- 집계를 세 걸음으로 맞춘다.
- 기록 이름 틀을 지워 `domain-docs`를 가리킨다.
- 훅이 넘기는 것을 파일 이름으로 고친다.
- 「2) 디스패치」의 lens-adversarial 예외 문장을 `dispatching-lenses`의 「예외 목록」 참조로 바꾼다.

- [ ] **Step 12: 새 단언 넷을 더한다**

`scripts/test_docs_drift.sh`에 둘을 더한다.

```bash
echo "[따르는 문서 — 문턱과 이름]"
LENS_BAD=""
while IFS= read -r d; do
  [ -n "$d" ] || continue
  n="$(basename "$d")"
  if ! grep -qF "\"lens\": \"$n\"" "$d/SKILL.md"; then LENS_BAD="$LENS_BAD $n"; fi
done <<EOF
$(ls -d "$HERE"/skills/lens-*)
EOF
check "렌즈 스키마의 lens 값이 디렉터리 이름과 같다" "[ -z \"\$LENS_BAD\" ]"
check "렌즈 파일에 문턱 첫 문장이 안 남았다"          "! grep -lF '발견 하나는 넷을 진다' \"\$HERE\"/skills/lens-*/SKILL.md >/dev/null 2>&1"
```

`scripts/test_audit.sh`에 둘을 더한다. 절차 문서 경로 변수 `$PDA` 는 이 파일에만 있다.

```bash
check "절차에 derived 가 안 남았다"        "! grep -qF 'derived' '$PDA'"
check "절차의 표 대조가 진술 스크립트를 부른다" "grep -qF 'audit_statements.sh' '$PDA'"
```

걸음 표 행 수 단언은 새로 만들지 않는다. 그 파일에 이미 있고 Step 2 의 `KO_NUM` 확장으로 산다.

- [ ] **Step 13: 계약 테스트 다섯을 돌린다**

Run: `bash scripts/test_assertions.sh`
Run: `bash scripts/test_audit.sh`
Run: `bash scripts/test_docs_drift.sh`
Run: `bash scripts/test_hooks.sh`
Run: `bash scripts/test_scaffold.sh`
Expected: 다섯 모두 `FAIL=0`

Run: `claude plugin validate ./`
Expected: `version` 경고 하나

- [ ] **Step 14: 커밋한다**

```bash
git add -A
git commit -q -F - <<'EOF'
렌즈 여섯과 호출자 넷이 소유자를 가리키기만 하게 한다

같은 문턱 문단이 렌즈 파일 넷에 같은 글자로 있었고 짝 묶음 규칙이 세
파일에 흩어져 있었다. 문턱은 meta-aggregate 가, 예외는 dispatching-lenses
가 지고 나머지는 참조 한 줄만 남긴다. 렌즈 스키마의 이름도 접두사 형태로
맞췄다. 절차 문서의 걸음 표에 회차 대조와 집계와 뿌리 찾기를 넣어 열한
걸음으로 맞추고 derived 를 세 자리에서 뺐으며, 자동 기각 사유가 소멸했을
때의 처분을 적었다.

Co-Authored-By: Claude Opus 5 (1M context) <noreply@anthropic.com>
Claude-Session: https://claude.ai/code/session_01T1Daa3xJNPhZBQa8DbnvRj
EOF
```

---

### Task 3: 스크립트와 기록 계약을 절차에 맞춘다

**Files:**
- Modify: `scripts/audit_evidence.sh`, `scripts/audit_rounds.sh`
- Create: `scripts/audit_statements.sh`, `scripts/audit_verify.sh`
- Test: `scripts/test_audit.sh`

**Interfaces:**
- Consumes: Task 2 가 정한 「판정」 절의 닫힌 집합 셋과 「기계가 하는 것」의 명령 두 줄
- Produces:
  - `audit_evidence.sh [--root DIR] <findings.json>` → `{"findings": [...], "dropped": [...]}`
  - `audit_rounds.sh diff [--root DIR] [--prior F] [--prior-diff F] <이번 findings.json>` → `{"schema","no_prior_round","items","new_ids","auto_rejected"}`
  - `audit_rounds.sh metrics [--root DIR] --tokens N --seconds N <이번 findings.json> [이번 diff.json]` → `{"by_lens","confirmed","tokens","seconds","tokens_per_confirmed","resolved_rate","verdict_counts"}`
  - `audit_statements.sh <렌즈 원본 JSON…>` → `{"topics": {"<이름표>": [{"file","statement","evidence"}]}}`
  - `audit_verify.sh <회차 폴더>` → 어긋난 것을 stdout 에 적고 하나라도 있으면 종료 코드 1

- [ ] **Step 1: 인용 탈락 단언을 쓰고 기존 단언을 고친다**

`scripts/test_audit.sh`의 `audit_evidence.sh` 구획에는 이미 픽스처와 단언 셋이 있다. 그 가운데 둘이 발견 목록의 두 번째를 첨자로 읽고 둘을 벗긴다. 탈락을 넣으면 그 자리에 하나만 남으므로 먼저 고친다. 리뷰가 앞 판이 더하기만 하고 기존 것을 안 고쳤다고 짚었다.

```bash
check "없는 인용을 못 찾았다고 적는다"     "evq 'import json,sys; d=json.load(sys.stdin); sys.exit(0 if d[\"dropped\"][0][\"evidence_found\"] is False else 1)'"
check "인용이 다르면 지문이 다르다"       "evq 'import json,sys; d=json.load(sys.stdin); a=d[\"findings\"][0]; b=d[\"dropped\"][0]; sys.exit(0 if a[\"fingerprint\"]!=b[\"fingerprint\"] else 1)'"
```

그다음 탈락 단언 둘을 더한다. 지금 스크립트로도 통과하는 단언은 넣지 않는다.

```bash
check "인용이 없으면 탈락한다"       "evq 'import json,sys; d=json.load(sys.stdin); sys.exit(0 if len(d[\"dropped\"])==1 else 1)'"
check "탈락한 것은 findings 에 없다" "evq 'import json,sys; d=json.load(sys.stdin); sys.exit(0 if len(d[\"findings\"])==1 else 1)'"
```

- [ ] **Step 2: 빨간 불을 확인한다**

Run: `bash scripts/test_audit.sh`
Expected: FAIL 이 4. 넷 모두 `dropped` 키가 없어 KeyError 로 떨어진다.

실패 형태 셋을 본다. 넷 다 지금 스크립트에서 실패하므로 이미 통과하는 단언이 없다. 픽스처는 스크립트의 출력을 읽는 것이라 자기 되읽기가 아니다.

- [ ] **Step 3: audit_evidence.sh 에 탈락을 넣는다**

`scripts/audit_evidence.sh`의 파이썬에서 반복문 뒤, `json.dump` 앞에 넣는다.

```python
kept, dropped = [], []
for f in d.get("findings", []):
    (kept if (f["evidence_found"] and f["counterpart_found"]) else dropped).append(f)
d["findings"], d["dropped"] = kept, dropped
```

머리말 주석의 "인용이 없는 발견을 LLM 이 아니라 여기서 떨어뜨리는 것이 이 스크립트를 둔 이유다"는 그대로 둔다. 이제 그 문장이 참이 된다.

- [ ] **Step 4: 초록 불을 확인한다**

Run: `bash scripts/test_audit.sh`
Expected: 위 단언 넷이 PASS

- [ ] **Step 5: 회차 대조 단언을 다시 쓴다**

`scripts/test_audit.sh`의 `[audit_rounds.sh — 회차 대조와 측정]` 구획을 통째로 바꾼다. 픽스처에 앞선 기각 하나와 앞선 diff 하나를 넣는다. 지금 구획이 재던 렌즈별 성적과 확정 하나당 값도 그대로 다시 넣는다. 리뷰가 앞 판이 그 둘을 빠뜨렸다고 짚었다.

```bash
echo "[audit_rounds.sh — 회차 대조와 측정]"
AR="$HERE/scripts/audit_rounds.sh"
check "스크립트가 있다" "[ -f '$AR' ]"
ART="$(mktemp -d)"; mkdir -p "$ART/2026-01-01-self-audit"
printf '남아 있는 어긋난 문장.\n' > "$ART/doc.md"
printf '상대편 문장.\n' > "$ART/other.md"
cat > "$ART/2026-01-01-self-audit/findings.json" <<'FIXTURE'
{ "schema": 1, "findings": [
  { "id": "p#001", "fingerprint": "aaaaaaaaaaaa", "status": "confirmed", "title": "남은 것",
    "file": "doc.md", "evidence": "남아 있는 어긋난 문장.",
    "counterpart_file": "other.md", "counterpart": "상대편 문장.", "principle": "SSOT", "lens": "lens-grounding" },
  { "id": "p#002", "fingerprint": "bbbbbbbbbbbb", "status": "confirmed", "title": "사라진 것",
    "file": "doc.md", "evidence": "이제 없는 문장.",
    "counterpart_file": "other.md", "counterpart": "상대편 문장.", "principle": "SSOT", "lens": "lens-fit" },
  { "id": "p#003", "fingerprint": "cccccccccccc", "status": "rejected", "title": "기각된 것",
    "verdict_reason": "정당한 좁혀 적기다",
    "file": "doc.md", "evidence": "남아 있는 어긋난 문장.",
    "counterpart_file": "other.md", "counterpart": "상대편 문장.", "principle": "SSOT", "lens": "lens-fit" }
] }
FIXTURE
cat > "$ART/prior-diff.json" <<'FIXTURE'
{ "schema": 1, "no_prior_round": false, "items": [
  { "prior_id": "o#009", "prior_round": "2025-12-01-self-audit", "prior_status": "confirmed",
    "fingerprint": "eeeeeeeeeeee", "verdict": "해소", "matched_id": null }
], "new_ids": [], "auto_rejected": [] }
FIXTURE
cat > "$ART/cur.json" <<'FIXTURE'
{ "schema": 1, "findings": [
  { "id": "c#001", "fingerprint": "aaaaaaaaaaaa", "status": "confirmed", "lens": "lens-grounding" },
  { "id": "c#002", "fingerprint": "dddddddddddd", "status": "undetermined", "verdict_reason": "못 정했다", "lens": "lens-fit" },
  { "id": "c#003", "fingerprint": "cccccccccccc", "status": "rejected", "verdict_reason": "앞선 회차 기각 유지 — 정당한 좁혀 적기다", "lens": "lens-fit" },
  { "id": "c#004", "fingerprint": "eeeeeeeeeeee", "status": "confirmed", "lens": "lens-adversarial" }
] }
FIXTURE
AR_DIFF="$(bash "$AR" diff --root "$ART" --prior "$ART/2026-01-01-self-audit/findings.json" --prior-diff "$ART/prior-diff.json" "$ART/cur.json" 2>/dev/null || true)"
arq() { printf '%s' "$AR_DIFF" | json_run "$1"; }
check "대조 출력이 JSON 이다"             "printf '%s' \"\$AR_DIFF\" | json_valid_stdin"
check "인용이 남아 있으면 잔존이다"        "arq 'import json,sys; d=json.load(sys.stdin); i=[x for x in d[\"items\"] if x[\"prior_id\"]==\"p#001\"][0]; sys.exit(0 if i[\"verdict\"]==\"잔존\" else 1)'"
check "인용이 사라졌으면 해소다"           "arq 'import json,sys; d=json.load(sys.stdin); i=[x for x in d[\"items\"] if x[\"prior_id\"]==\"p#002\"][0]; sys.exit(0 if i[\"verdict\"]==\"해소\" else 1)'"
check "기각된 앞선 발견도 대조한다"        "arq 'import json,sys; d=json.load(sys.stdin); sys.exit(0 if [x for x in d[\"items\"] if x[\"prior_id\"]==\"p#003\"] else 1)'"
check "회차 이름을 앞선 경로에서 뽑는다"    "arq 'import json,sys; d=json.load(sys.stdin); i=[x for x in d[\"items\"] if x[\"prior_id\"]==\"p#001\"][0]; sys.exit(0 if i[\"prior_round\"]==\"2026-01-01-self-audit\" else 1)'"
check "앞선 diff 의 해소가 다시 나오면 재발이다" "arq 'import json,sys; d=json.load(sys.stdin); i=[x for x in d[\"items\"] if x[\"prior_id\"]==\"o#009\"][0]; sys.exit(0 if i[\"verdict\"]==\"재발\" else 1)'"
check "재발은 앞선 회차 이름을 승계한다"    "arq 'import json,sys; d=json.load(sys.stdin); i=[x for x in d[\"items\"] if x[\"prior_id\"]==\"o#009\"][0]; sys.exit(0 if i[\"prior_round\"]==\"2025-12-01-self-audit\" else 1)'"
check "앞선 기각과 지문이 같으면 자동 기각 후보다" "arq 'import json,sys; d=json.load(sys.stdin); a=d[\"auto_rejected\"]; sys.exit(0 if len(a)==1 and a[0][\"id\"]==\"c#003\" and a[0][\"prior_reason\"]==\"정당한 좁혀 적기다\" else 1)'"
check "앞선 회차에 없던 지문을 신규로 센다" "arq 'import json,sys; d=json.load(sys.stdin); sys.exit(0 if d[\"new_ids\"]==[\"c#002\"] else 1)'"
AR_DIFF2="$(bash "$AR" diff --root "$ART" --prior "$ART/2026-01-01-self-audit/findings.json" --prior-diff "$ART/prior-diff.json" "$ART/cur.json" 2>/dev/null || true)"
check "두 번 계산해도 같은 결과다"         "[ \"\$AR_DIFF\" = \"\$AR_DIFF2\" ]"
AR_NONE="$(bash "$AR" diff --root "$ART" "$ART/cur.json" 2>/dev/null || true)"
anq() { printf '%s' "$AR_NONE" | json_run "$1"; }
check "앞선 회차가 없으면 그렇게 적는다"    "anq 'import json,sys; d=json.load(sys.stdin); sys.exit(0 if d[\"no_prior_round\"] and d[\"items\"]==[] and len(d[\"new_ids\"])==4 else 1)'"
printf '%s' "$AR_DIFF" > "$ART/diff.json"
AR_MET="$(bash "$AR" metrics --tokens 1000 --seconds 60 "$ART/cur.json" "$ART/diff.json" 2>/dev/null || true)"
amq() { printf '%s' "$AR_MET" | json_run "$1"; }
check "측정 출력이 JSON 이다"              "printf '%s' \"\$AR_MET\" | json_valid_stdin"
check "렌즈별로 낸 수와 확정 수를 센다"     "amq 'import json,sys; d=json.load(sys.stdin); sys.exit(0 if d[\"by_lens\"][\"lens-fit\"]=={\"raised\":2,\"confirmed\":0} else 1)'"
check "확정 하나당 값을 낸다"              "amq 'import json,sys; d=json.load(sys.stdin); sys.exit(0 if d[\"tokens_per_confirmed\"]==500 else 1)'"
check "판정 개수를 낸다"                   "amq 'import json,sys; d=json.load(sys.stdin); v=d[\"verdict_counts\"]; sys.exit(0 if v[\"confirmed\"]==2 and v[\"rejected\"]==1 and v[\"undetermined\"]==1 and v[\"auto_rejected\"]==1 else 1)'"
check "해소율 분모에 기각이 없다"           "amq 'import json,sys; d=json.load(sys.stdin); sys.exit(0 if d[\"resolved_rate\"]==0.333 else 1)'"
rm -rf "$ART"
```

셈을 확인한다. `items` 는 넷이다. `p#001` 잔존, `p#002` 해소, `p#003` 잔존(`prior_status` 기각이라 분모에서 빠진다), `o#009` 재발이다. 분모는 셋이고 분자는 해소 하나이므로 `1/3 = 0.333` 이다. 이번 회차 확정은 `c#001`·`c#004` 둘이라 `tokens_per_confirmed` 는 500 이고, `lens-fit` 은 둘을 냈고 확정이 없다.

- [ ] **Step 6: 빨간 불을 확인한다**

Run: `bash scripts/test_audit.sh`
Expected: FAIL 이 여럿. `--prior` 옵션을 모르는 지금 스크립트가 사용법 오류로 끝나 출력이 비고, JSON 검사부터 떨어진다.

- [ ] **Step 7: audit_rounds.sh diff 를 다시 쓴다**

인자 파싱을 바꾼다.

```bash
ROOT="$HERE"; TOKENS=0; SECS=0; A=""; B=""; PRIOR=""; PRIOR_DIFF=""
while [ "$#" -gt 0 ]; do
  case "$1" in
    --root) ROOT="$2"; shift 2 ;;
    --tokens) TOKENS="$2"; shift 2 ;;
    --seconds) SECS="$2"; shift 2 ;;
    --prior) PRIOR="$2"; shift 2 ;;
    --prior-diff) PRIOR_DIFF="$2"; shift 2 ;;
    *) if [ -z "$A" ]; then A="$1"; else B="$1"; fi; shift ;;
  esac
done
```

`diff` 갈래를 바꾼다.

```bash
  diff)
    [ -n "$A" ] || { echo "사용: audit_rounds.sh diff [--root DIR] [--prior <앞선 findings.json>] [--prior-diff <앞선 diff.json>] <이번 findings.json>" >&2; exit 2; }
    json_run '
import json, os, re, sys
sys.stdout.reconfigure(encoding="utf-8", newline=chr(10))
root, cur_p, prior_p, prior_diff_p = sys.argv[1], sys.argv[2], sys.argv[3], sys.argv[4]
def norm(s): return re.sub(r"\s+", " ", s or "").strip()
cache = {}
def text(p):
    p = (p or "").split(":")[0]
    if not p: return None
    if p not in cache:
        try: cache[p] = norm(open(os.path.join(root, p), encoding="utf-8").read())
        except Exception: cache[p] = None
    return cache[p]
cur = json.load(open(cur_p, encoding="utf-8"))
cur_fp = {}
for f in cur.get("findings", []):
    cur_fp.setdefault(f.get("fingerprint"), f.get("id"))
if not prior_p:
    out = {"schema": 1, "no_prior_round": True, "items": [],
           "new_ids": [f.get("id") for f in cur.get("findings", [])]}
    json.dump(out, sys.stdout, ensure_ascii=False, indent=1); raise SystemExit(0)
prior = json.load(open(prior_p, encoding="utf-8"))
prior_round = os.path.basename(os.path.dirname(os.path.abspath(prior_p)))
items, auto = [], []
for f in prior.get("findings", []):
    ev, cp = norm(f.get("evidence")), norm(f.get("counterpart"))
    t1, t2 = text(f.get("file")), text(f.get("counterpart_file"))
    alive = bool(ev) and t1 is not None and ev in t1 and bool(cp) and t2 is not None and cp in t2
    fp = f.get("fingerprint")
    items.append({"prior_id": f.get("id"), "prior_round": prior_round,
                  "prior_status": f.get("status"), "fingerprint": fp, "title": f.get("title"),
                  "file": f.get("file"), "verdict": "잔존" if alive else "해소",
                  "matched_id": cur_fp.get(fp)})
    if f.get("status") == "rejected" and fp in cur_fp:
        auto.append({"prior_id": f.get("id"), "prior_round": prior_round, "fingerprint": fp,
                     "id": cur_fp[fp], "prior_reason": f.get("verdict_reason")})
seen = set(i["fingerprint"] for i in items)
if prior_diff_p:
    for i in json.load(open(prior_diff_p, encoding="utf-8")).get("items", []):
        fp = i.get("fingerprint")
        if fp in seen or i.get("verdict") != "해소": continue
        if fp not in cur_fp: continue
        items.append({"prior_id": i.get("prior_id"), "prior_round": i.get("prior_round"),
                      "prior_status": i.get("prior_status"), "fingerprint": fp,
                      "title": i.get("title"), "file": i.get("file"),
                      "verdict": "재발", "matched_id": cur_fp[fp]})
        seen.add(fp)
new_ids = [f.get("id") for f in cur.get("findings", []) if f.get("fingerprint") not in seen]
json.dump({"schema": 1, "no_prior_round": False, "items": items,
           "new_ids": new_ids, "auto_rejected": auto}, sys.stdout, ensure_ascii=False, indent=1)
' "$ROOT" "$A" "$PRIOR" "$PRIOR_DIFF"
    ;;
```

머리말 주석에 재발의 셈을 한 줄 적는다. 잔존과 해소는 인용이 파일에 지금도 있는지로 재고, 재발은 앞선 diff 가 해소라 한 지문이 이번 발견에 다시 나오는지로 잰다. 이번 발견은 `audit_evidence.sh` 가 인용 실재를 이미 확인했으므로 그 재출현이 곧 인용이 다시 있다는 뜻이다.

- [ ] **Step 8: audit_rounds.sh metrics 를 고친다**

```bash
    json_run '
import json, sys
sys.stdout.reconfigure(encoding="utf-8", newline=chr(10))
cur_p, tokens, secs = sys.argv[1], int(sys.argv[2]), int(sys.argv[3])
cur_diff = sys.argv[4] if len(sys.argv) > 4 else ""
cur = json.load(open(cur_p, encoding="utf-8"))
by = {}
for f in cur.get("findings", []):
    for lens in [x.strip() for x in str(f.get("lens", "")).split(",") if x.strip()]:
        d = by.setdefault(lens, {"raised": 0, "confirmed": 0})
        d["raised"] += 1
        if f.get("status") == "confirmed": d["confirmed"] += 1
counts = {"confirmed": 0, "rejected": 0, "undetermined": 0, "auto_rejected": 0}
for f in cur.get("findings", []):
    s = f.get("status")
    if s in counts: counts[s] += 1
confirmed = counts["confirmed"]
out = {"by_lens": by, "confirmed": confirmed, "tokens": tokens, "seconds": secs,
       "tokens_per_confirmed": (tokens // confirmed) if confirmed else None,
       "resolved_rate": None, "verdict_counts": counts}
if cur_diff:
    d = json.load(open(cur_diff, encoding="utf-8"))
    counts["auto_rejected"] = len(d.get("auto_rejected", []))
    items = [i for i in d.get("items", []) if i.get("prior_status") != "rejected"]
    if items:
        out["resolved_rate"] = round(sum(1 for i in items if i.get("verdict") == "해소") / len(items), 3)
json.dump(out, sys.stdout, ensure_ascii=False, indent=1)
' "$A" "$TOKENS" "$SECS" ${B:+"$B"}
```

머리말 사용법 주석 두 줄을 Task 2 Step 8 이 절차 문서에 적은 것과 같은 글자로 고친다.

```
#   audit_rounds.sh diff    [--root DIR] [--prior <앞선 findings.json>] [--prior-diff <앞선 diff.json>] <이번 findings.json>
#   audit_rounds.sh metrics [--root DIR] --tokens N --seconds N <이번 findings.json> [이번 diff.json]
```

- [ ] **Step 9: 초록 불을 확인한다**

Run: `bash scripts/test_audit.sh`
Expected: `FAIL=0`

- [ ] **Step 10: audit_statements.sh 단언을 먼저 쓴다**

```bash
echo "[audit_statements.sh — 이름표별 진술]"
AS="$HERE/scripts/audit_statements.sh"
check "스크립트가 있다" "[ -f '$AS' ]"
AST="$(mktemp -d)"
cat > "$AST/lens-fit-1.json" <<'FIXTURE'
{ "lens": "lens-fit", "target": "skills/a/SKILL.md", "issues": [],
  "statements": [ { "topic": "봉인 시점", "statement": "세션 시작에 봉인한다", "evidence": "봉인" } ] }
FIXTURE
cat > "$AST/lens-fit-2.json" <<'FIXTURE'
{ "lens": "lens-fit", "target": "skills/b/SKILL.md", "issues": [],
  "statements": [ { "topic": "봉인 시점", "statement": "회차 끝에 봉인한다", "evidence": "회차" } ] }
FIXTURE
AS_OUT="$(bash "$AS" "$AST/lens-fit-1.json" "$AST/lens-fit-2.json" 2>/dev/null || true)"
asq() { printf '%s' "$AS_OUT" | json_run "$1"; }
check "진술 출력이 JSON 이다"        "printf '%s' \"\$AS_OUT\" | json_valid_stdin"
check "이름표로 모은다"              "asq 'import json,sys; d=json.load(sys.stdin); sys.exit(0 if len(d[\"topics\"][\"봉인 시점\"])==2 else 1)'"
check "문서 경로는 원본의 target 이다" "asq 'import json,sys; d=json.load(sys.stdin); sys.exit(0 if d[\"topics\"][\"봉인 시점\"][0][\"file\"]==\"skills/a/SKILL.md\" else 1)'"
rm -rf "$AST"
```

- [ ] **Step 11: 빨간 불을 확인하고 스크립트를 만든다**

Run: `bash scripts/test_audit.sh`
Expected: FAIL 이 4. 파일이 없어 넷 모두 떨어진다. 부정 단언이 없으므로 파일 부재를 통과로 뒤집는 자리가 없다.

`scripts/audit_statements.sh`를 만든다.

```bash
#!/usr/bin/env bash
# 문서별 렌즈 호출이 돌려준 statements 를 이름표별로 모은다. 거르지 않는다 — 갈리는 짝을 고르는
# 판단은 세션이 한다. 어느 문서의 진술인지는 원본의 target 칸이 진다(meta-aggregate 계약).
# 사용: audit_statements.sh <렌즈 원본 JSON…>   (결과 JSON 을 stdout 으로 낸다)
set -euo pipefail
HERE="$(cd "$(dirname "$0")/.." && pwd)"
. "$HERE/scripts/_json_valid.sh"   # json_run — 파이썬 이름은 여기가 고른다
[ "$#" -gt 0 ] || { echo "사용: audit_statements.sh <렌즈 원본 JSON…>" >&2; exit 2; }
json_run '
import json, sys
sys.stdout.reconfigure(encoding="utf-8", newline=chr(10))
topics = {}
for p in sys.argv[1:]:
    d = json.load(open(p, encoding="utf-8"))
    target = d.get("target", "")
    for s in d.get("statements", []):
        topics.setdefault(s.get("topic", ""), []).append(
            {"file": target, "statement": s.get("statement", ""), "evidence": s.get("evidence", "")})
out = {"topics": {k: topics[k] for k in sorted(topics)}}
json.dump(out, sys.stdout, ensure_ascii=False, indent=1)
' "$@"
```

Run: `chmod +x scripts/audit_statements.sh`
Run: `bash scripts/test_audit.sh`
Expected: 위 단언 넷이 PASS

- [ ] **Step 12: audit_verify.sh 단언을 먼저 쓴다**

부정 단언은 스크립트가 있을 때만 재게 감싼다. 파일이 없으면 부정 단언이 통과해 빨간 불을 숨긴다. 리뷰가 앞 판에서 이것을 짚었다.

```bash
echo "[audit_verify.sh — 실제 기록 검수]"
AV="$HERE/scripts/audit_verify.sh"
check "스크립트가 있다" "[ -f '$AV' ]"
VT="$(mktemp -d)"; mkdir -p "$VT/2026-01-02-self-audit"
VR="$VT/2026-01-02-self-audit"
cat > "$VR/findings.json" <<'FIXTURE'
{ "schema": 1, "findings": [
  { "id": "v#001", "fingerprint": "aaaaaaaaaaaa", "status": "confirmed", "title": "t",
    "file": "a.md", "evidence": "e", "counterpart_file": "b.md", "counterpart": "c",
    "principle": "SSOT", "consequence": "지금 이렇게 되어 있다", "lens": "lens-fit",
    "evidence_found": true, "counterpart_found": true } ] }
FIXTURE
printf '{ "schema": 1, "no_prior_round": true, "items": [], "new_ids": ["v#001"] }\n' > "$VR/diff.json"
printf '{ "schema": 1, "suggestions": [] }\n' > "$VR/suggestions.json"
cat > "$VR/run.json" <<'FIXTURE'
{ "schema": 1, "tokens_method": "합산", "lens_calls": {}, "subagents": 1, "targets": [],
  "metrics": { "by_lens": {}, "confirmed": 1 }, "completed": true }
FIXTURE
cat > "$VR/lens-fit-1.json" <<'FIXTURE'
{ "lens": "lens-fit", "target": "a.md", "issues": [] }
FIXTURE
check "제대로 된 회차는 통과한다" "bash '$AV' '$VR' >/dev/null 2>&1"
cat > "$VR/findings.json" <<'FIXTURE'
{ "schema": 1, "findings": [
  { "id": "v#002", "fingerprint": "aaaaaaaaaaaa", "status": "rejected", "title": "t",
    "file": "a.md", "evidence": "e", "counterpart_file": "b.md", "counterpart": "c",
    "principle": "SSOT", "lens": "lens-fit", "evidence_found": true, "counterpart_found": true } ] }
FIXTURE
check "사유 없는 기각을 잡는다" "[ -f '$AV' ] && ! bash '$AV' '$VR' >/dev/null 2>&1"
rm -rf "$VT"
```

앞선 회차가 없는 `diff.json` 에 `auto_rejected` 가 없어도 통과하는지가 첫 단언에 들어 있다. 봉인된 이 저장소의 회차 기록이 그 꼴이다.

- [ ] **Step 13: 빨간 불을 확인하고 스크립트를 만든다**

Run: `bash scripts/test_audit.sh`
Expected: FAIL 이 3. 셋 다 파일이 없어 떨어진다. 부정 단언에 파일 존재 조건을 앞세웠으므로 통과로 뒤집히지 않는다.

`scripts/audit_verify.sh`를 만든다.

```bash
#!/usr/bin/env bash
# 회차 폴더의 기록 넷과 렌즈 원본을 검수한다. 픽스처가 아니라 실제 기록을 본다.
# 판정 상태의 닫힌 집합은 여기서 리터럴로 박지 않고 절차 문서에서 뽑는다(SSOT).
# 렌즈 원본 이름 규칙의 소유자는 domain-docs 의 문서 타입 표 기록 행이다. 그 행이 정한 꼴이
# `lens-<렌즈 이름>-<띄운 횟수>.json` 이고 아래 정규식이 그것을 그대로 옮긴 것이다. 그 행이
# 바뀌면 여기도 함께 바꾼다.
# 사용: audit_verify.sh <회차 폴더>   (어긋난 것을 stdout 으로 적고 하나라도 있으면 1로 끝난다)
set -euo pipefail
HERE="$(cd "$(dirname "$0")/.." && pwd)"
. "$HERE/scripts/_json_valid.sh"   # json_run — 파이썬 이름은 여기가 고른다
DIR="${1:-}"
[ -n "$DIR" ] && [ -d "$DIR" ] || { echo "사용: audit_verify.sh <회차 폴더>" >&2; exit 2; }
PDA="$HERE/skills/project-doc-audit/SKILL.md"
STATUS_LINE="$(grep -F '`status`가' "$PDA" | head -1)"
STATUS_SET="$(printf '%s' "$STATUS_LINE" | grep -oE '`[a-z]+`' | tr -d '`' | grep -vx status | sort -u | tr '\n' ' ')"
[ -n "$STATUS_SET" ] || { echo "절차 문서에서 status 닫힌 집합을 못 뽑았다: $PDA" >&2; exit 2; }
json_run '
import json, os, re, sys
sys.stdout.reconfigure(encoding="utf-8", newline=chr(10))
d, allowed = sys.argv[1], set(sys.argv[2].split())
bad = []
def load(name):
    p = d.rstrip("/") + "/" + name
    if not os.path.isfile(p):
        bad.append("없는 파일: " + name); return None
    try: return json.load(open(p, encoding="utf-8"))
    except Exception as e:
        bad.append("JSON 이 아니다: " + name + " — " + str(e)); return None
fnd = load("findings.json")
if fnd is not None:
    for f in fnd.get("findings", []):
        i = f.get("id", "?")
        if f.get("status") not in allowed:
            bad.append(i + ": status 가 닫힌 집합 밖이다 — " + str(f.get("status")))
        if f.get("status") in ("rejected", "undetermined") and not f.get("verdict_reason"):
            bad.append(i + ": 기각이나 미판정에 verdict_reason 이 없다")
        if not f.get("evidence_found") or not f.get("counterpart_found"):
            bad.append(i + ": 인용 확인이 참이 아니다")
        if len(str(f.get("fingerprint", ""))) != 12:
            bad.append(i + ": 지문이 열두 자가 아니다")
        for lens in [x.strip() for x in str(f.get("lens", "")).split(",") if x.strip()]:
            if not lens.startswith("lens-"):
                bad.append(i + ": lens 값에 접두사가 없다 — " + lens)
run = load("run.json")
if run is not None:
    for k in ["tokens_method", "lens_calls", "subagents", "metrics", "completed", "targets"]:
        if k not in run: bad.append("run.json 에 " + k + " 가 없다")
dif = load("diff.json")
if dif is not None:
    for k in ["schema", "no_prior_round", "items", "new_ids"]:
        if k not in dif: bad.append("diff.json 에 " + k + " 가 없다")
    if not dif.get("no_prior_round", False) and "auto_rejected" not in dif:
        bad.append("diff.json 에 auto_rejected 가 없다(앞선 회차가 있는 회차다)")
sug = load("suggestions.json")
if sug is not None and "suggestions" not in sug:
    bad.append("suggestions.json 에 suggestions 가 없다")
pat = re.compile(r"^lens-[a-z-]+-[0-9]+\.json$")
for name in sorted(os.listdir(d)):
    if not name.startswith("lens-") or not name.endswith(".json"): continue
    if not pat.match(name):
        bad.append("렌즈 원본 이름이 규칙 밖이다: " + name); continue
    try: o = json.load(open(d.rstrip("/") + "/" + name, encoding="utf-8"))
    except Exception as e:
        bad.append("JSON 이 아니다: " + name + " — " + str(e)); continue
    if "target" not in o: bad.append(name + ": target 칸이 없다")
for line in bad: print(line)
sys.exit(1 if bad else 0)
' "$DIR" "$STATUS_SET"
```

Run: `chmod +x scripts/audit_verify.sh`

이름 규칙이 두 곳에 있는 것을 검사로 묶는다. `scripts/test_audit.sh`에 한 줄 더한다.

```bash
check "이름 규칙의 소유자가 그 꼴을 적는다" "grep -qF 'lens-<렌즈 이름>-<띄운 횟수>.json' '$DD'"
```

- [ ] **Step 14: 봉인된 회차를 실제로 검수한다**

Run: `bash scripts/audit_verify.sh docs/superpowers/reviews/2026-09-05-self-audit-2`
Expected: 출력 없음, 종료 코드 0

이것이 spec 성공 기준 넷째의 절반이다. 실패하면 기록을 고치지 말고 `audit_verify.sh`의 필수 칸 목록이 기록 계약과 맞는지 다시 본다.

- [ ] **Step 15: 회차 대조를 실제 기록으로 돌린다**

출력은 스크래치 폴더에 둔다. 저장소를 더럽히지 않는다.

Run: `bash scripts/audit_rounds.sh diff --prior docs/superpowers/reviews/2026-09-05-self-audit-2/findings.json docs/superpowers/reviews/2026-09-05-self-audit-2/findings.json > "$SCRATCH/roundtrip.json"`

`$SCRATCH` 는 이 세션의 스크래치 폴더다. 같은 회차를 앞뒤로 넣는 자기 대조다. 확인용 파이썬은 `-c` 문자열이 아니라 파일로 쓴다(Global Constraints).

`$SCRATCH/count_roundtrip.py` 를 만든다.

```python
import json, sys
d = json.load(open(sys.argv[1], encoding="utf-8"))
items = d["items"]
rejected = [i for i in items if i["prior_status"] == "rejected"]
print(len(items), len(rejected))
```

Run: `python -X utf8 "$SCRATCH/count_roundtrip.py" "$SCRATCH/roundtrip.json"`
Expected: `118 9`

성공 기준 넷째의 나머지 절반이다.

- [ ] **Step 16: 계약 테스트 다섯을 돌린다**

Run: `bash scripts/test_assertions.sh`
Run: `bash scripts/test_audit.sh`
Run: `bash scripts/test_docs_drift.sh`
Run: `bash scripts/test_hooks.sh`
Run: `bash scripts/test_scaffold.sh`
Expected: 다섯 모두 `FAIL=0`

Run: `claude plugin validate ./`
Expected: `version` 경고 하나

- [ ] **Step 17: 커밋한다**

```bash
git add -A
git commit -q -F - <<'EOF'
회차를 저장소 스크립트만으로 돌게 만든다

첫 회차는 인용 탈락과 판정 개수와 진술 묶기와 기록 검수를 세션이
스크래치에 쓴 스크립트로 했다. 그 넷을 저장소에 넣는다. 인용 없는 발견은
audit_evidence.sh 가 dropped 로 옮기고, 회차 대조는 앞선 기각과 앞선
diff 까지 받아 재발과 자동 기각 후보를 내며, metrics 가 판정 개수를 내고
해소율 분모에서 기각을 뺀다. audit_statements.sh 와 audit_verify.sh 는
새로 만들었다.

Co-Authored-By: Claude Opus 5 (1M context) <noreply@anthropic.com>
Claude-Session: https://claude.ai/code/session_01T1Daa3xJNPhZBQa8DbnvRj
EOF
```

---

### Task 4: README 와 CLAUDE.md 와 writing-korean 을 고친다

**Files:**
- Modify: `README.md` (「하드 게이트와 넛지와 전역 설정 수정」)
- Modify: `CLAUDE.md` (셋째 문단)
- Modify: `skills/writing-korean/SKILL.md`, `skills/lens-readability/SKILL.md`
- Test: `scripts/test_hooks.sh`, `scripts/test_docs_drift.sh`

**Interfaces:**
- Consumes: `hooks/hooks.json`과 `.claude/settings.json`에 배선된 스크립트 파일 이름
- Produces: README 훅 절이 훅 목록의 정본이다

- [ ] **Step 1: 훅 목록 단언을 먼저 쓴다**

`scripts/test_hooks.sh`에 구획을 더한다. 목록을 배선 파일 둘에서 도출한다.

```bash
echo "[README — 배선된 스크립트를 모두 적는다]"
HOOK_MISS=""
while IFS= read -r s; do
  [ -n "$s" ] || continue
  if ! grep -qF "$s" "$HERE/README.md"; then HOOK_MISS="$HOOK_MISS $s"; fi
done <<EOF
$(grep -ohE '[a-z_]+\.sh' "$HERE/hooks/hooks.json" "$HERE/.claude/settings.json" | sort -u)
EOF
[ -n "$HOOK_MISS" ] && echo "    README 에 빠진 스크립트:$HOOK_MISS"
check "README 가 배선된 스크립트를 모두 적는다" "[ -z \"\$HOOK_MISS\" ]"
check "README 가 배선 파일 둘을 든다"           "grep -qF 'hooks/hooks.json' '$HERE/README.md' && grep -qF '.claude/settings.json' '$HERE/README.md'"
```

`scripts/test_docs_drift.sh`에 CLAUDE.md 단언을 더한다.

```bash
check "CLAUDE.md 가 새로 쓸 때만 게이트라고 적는다" "! grep -qE '(^|[^로])쓰면 Stop 게이트가' \"\$CMD\""
```

- [ ] **Step 2: 빨간 불을 확인한다**

Run: `bash scripts/test_hooks.sh`
Expected: FAIL 이 1 이상. README 훅 절이 스크립트 이름 전부를 담지 않는다.

Run: `bash scripts/test_docs_drift.sh`
Expected: FAIL 이 1. CLAUDE.md 셋째 문단이 "spec과 plan을 쓰면"이다.

실패 형태 셋을 본다. 두 단언 다 지금 파일에서 실패하고, 목록을 배선 파일에서 도출하므로 리터럴 하나만 겨누지 않는다.

- [ ] **Step 3: README 훅 절을 다시 쓴다**

훅마다 스크립트 파일 이름과 이벤트를 적고 배선 파일 둘을 든다. 표의 스크립트 이름은 배선 파일 둘을 열어 실제 값으로 채운다. 아래는 이 계획을 쓴 시점의 배선이며 Step 1 의 단언이 빠진 것을 알려 준다.

```markdown
## 하드 게이트와 넛지와 전역 설정 수정

배선은 둘이다. `hooks/hooks.json`은 이 플러그인이 어디서나 거는 훅이고, `.claude/settings.json`은 이 저장소에서만 도는 프로젝트 훅이다.

| 이벤트 | 스크립트 | 하는 일 |
|---|---|---|
| SessionStart | `scripts/scaffold.sh` | 정본 사본과 `@import` 배선을 만들고 알린다 |
| SessionStart | `scripts/seal_reviews.sh` | 커밋된 감사 기록을 읽기 전용으로 봉인한다(이 저장소의 프로젝트 훅) |
| PreToolUse | `hooks/readonly_pretooluse.sh` | 읽기 전용 파일에 걸린 Write·Edit 을 사유와 함께 거부한다 |
| PreToolUse | `hooks/doc_format_pretooluse.sh` | 문서 양식 넛지를 띄운다 |
| PostToolUse | `hooks/spec_review_posttooluse.sh` | 새 spec·plan 을 감지해 리뷰를 지시한다 |
| PostToolUse | `hooks/doc_review_posttooluse.sh` | 문서 검진 넛지를 띄운다 |
| Stop | `hooks/spec_review_stop.sh` | 미리뷰 spec·plan 이 남은 채 턴이 끝나는 것을 막는다 |

봉인 시점은 둘이다. 커밋된 기록은 세션 시작에 `seal_reviews.sh`가 봉인하고, 회차 기록은 회차 끝에 호출자가 같은 스크립트를 인자와 함께 불러 봉인한다.
```

- [ ] **Step 4: README 「동작 확인과 복구」를 손대지 않는다**

그 절은 Task 5 가 고친다. 여기서 만지면 두 커밋이 같은 문단에서 충돌한다. README 는 Task 1·4·5 에 걸리므로 덩이를 갈라 둔다.

- [ ] **Step 5: CLAUDE.md 를 고친다**

셋째 문단의 "spec과 plan을 쓰면"을 "spec과 plan을 새로 쓰면"으로 바꾸고 넛지 예외를 한 줄 더한다.

```markdown
spec과 plan을 새로 쓰면 Stop 게이트가 리뷰를 요구하고, 그 밖의 문서를 고치면 검진 넛지가 뜬다. 리뷰 기록과 프로젝트 밖 문서에는 넛지가 뜨지 않는다.
```

- [ ] **Step 6: writing-korean 을 고친다**

- 대구 규칙의 단위를 "글 한 편(답 하나 또는 문서 하나)"으로 못 박는다.
- '것' 규칙의 범위를 "대상을 가리키는 '것'에만"으로 못 박는다.

- [ ] **Step 7: lens-readability 의 「고칠 순서」 사본을 지운다**

`skills/lens-readability/SKILL.md`에서 「고칠 순서」 문단을 지우고 참조 한 문장으로 바꾼다.

```markdown
고칠 순서는 `writing-korean`의 「고칠 순서」가 정한다.
```

- [ ] **Step 8: 계약 테스트 다섯을 돌린다**

Run: `bash scripts/test_assertions.sh`
Run: `bash scripts/test_audit.sh`
Run: `bash scripts/test_docs_drift.sh`
Run: `bash scripts/test_hooks.sh`
Run: `bash scripts/test_scaffold.sh`
Expected: 다섯 모두 `FAIL=0`

Run: `claude plugin validate ./`
Expected: `version` 경고 하나

- [ ] **Step 9: 커밋한다**

```bash
git add -A
git commit -q -F - <<'EOF'
훅 목록의 정본을 README 에 두고 배선에서 도출해 검사한다

훅이 일곱인데 안내 문서가 넷만 적고 있었고 봉인 시점도 한쪽만 적혀
있었다. README 훅 절이 이벤트와 스크립트 이름과 배선 파일 둘을 모두 담게
하고, 그 목록이 hooks.json 과 settings.json 에서 도출되는지 검사한다.
writing-korean 은 대구와 '것' 규칙의 단위를 못 박고 lens-readability 의
사본을 지웠다.

Co-Authored-By: Claude Opus 5 (1M context) <noreply@anthropic.com>
Claude-Session: https://claude.ai/code/session_01T1Daa3xJNPhZBQa8DbnvRj
EOF
```

---

### Task 5: 세션 시작 알림 통로와 PYTHONUTF8

**Files:**
- Modify: `scripts/scaffold.sh`, `scripts/seal_reviews.sh`
- Modify: `README.md` (「동작 확인과 복구」), `commands/setup-discipline.md`, `commands/show-principles.md`
- Modify: `skills/domain-plugin/SKILL.md`
- Test: `scripts/test_scaffold.sh`

**Interfaces:**
- Consumes: `ensure_marketplace_autoupdate`(`scripts/_ensure_autoupdate.sh`)의 stderr 출력
- Produces: `scaffold.sh`의 테스트 주입 변수 `DISCIPLINED_CODER_UTF8_STATE`(`set`·`unset`·`not-windows`)

- [ ] **Step 1: 모든 픽스처가 UTF8 상태를 고정하게 한다**

`scripts/test_scaffold.sh` 파일 위쪽, `run()` 정의 앞에 둘을 넣는다. 헬퍼 안에만 두면 헬퍼를 거치지 않고 스크립트를 직접 부르는 픽스처가 실제 운영체제와 레지스트리를 본다. 리뷰가 앞 판에서 이것을 짚었다.

```bash
# PYTHONUTF8 안내는 OS 와 레지스트리를 읽어 판정하므로 픽스처마다 상태를 주입해 고정한다. run() 을
# 거치지 않고 $SCAFFOLD 를 직접 부르는 픽스처가 여럿이라 헬퍼가 아니라 파일 머리에서 내보낸다.
: "${UTF8_STATE:=set}"
export DISCIPLINED_CODER_UTF8_STATE="$UTF8_STATE"
```

`run()` 은 고치지 않는다. 내보낸 변수가 자식 프로세스로 그대로 간다.

- [ ] **Step 2: 통로와 안내 단언을 쓴다(빨간 불을 만든다)**

자동 갱신 사유를 stderr 에서 읽던 단언 넷과 소스 부재 경고 단언 하나를 stdout 으로 옮긴다. `2>&1 >/dev/null` 을 `2>/dev/null` 로 바꾸고 변수 이름은 그대로 둔다.

```bash
set +e; ERR_D="$(run "$HD" "$PD" 2>/dev/null)"; set -e
set +e; ERR_E="$(run "$HE" "$PE" 2>/dev/null)"; set -e
```

"missing source warns to stderr" 도 같은 방식으로 바꾼다. 그 픽스처의 stdout 을 담는 변수가 없으면 새로 만든다.

```bash
check "missing source warns to stdout"      "printf '%s' \"\$OUT8\" | grep -qF 'WARNING: source not found'"
```

섞이지 않음 단언을 더한다. 이 픽스처는 설정이 깨져 자동 갱신을 못 켠 갈래라 머리말이 아예 안 나와야 한다.

```bash
check "실패 사유가 켰다는 머리말 아래 안 섞인다" "printf '%s' \"\$ERR_D\" | grep -qF 'autoUpdate 설정을 건너뛴다' && ! printf '%s' \"\$ERR_D\" | grep -qF '자동 갱신을 켰다'"
```

PYTHONUTF8 안내 단언 셋을 더한다.

```bash
# --- utf8-nudge: 사용자 환경 변수가 비었을 때만, 첫 세션에만 ---
H22="$(mktemp -d)"; P22="$(mktemp -d)"
OUT22a="$(DISCIPLINED_CODER_UTF8_STATE=unset run "$H22" "$P22")"
OUT22b="$(DISCIPLINED_CODER_UTF8_STATE=unset run "$H22" "$P22")"
H23="$(mktemp -d)"; P23="$(mktemp -d)"
OUT23="$(DISCIPLINED_CODER_UTF8_STATE=set run "$H23" "$P23")"
echo "[utf8-nudge] PYTHONUTF8 안내는 변수가 비었을 때 첫 세션에만"
check "변수가 비면 첫 세션에 안내한다"   "printf '%s' \"\$OUT22a\" | grep -qF 'PYTHONUTF8'"
check "둘째 세션에는 안내하지 않는다"    "! printf '%s' \"\$OUT22b\" | grep -qF 'PYTHONUTF8'"
check "변수가 있으면 안내하지 않는다"    "! printf '%s' \"\$OUT23\" | grep -qF 'PYTHONUTF8'"
```

- [ ] **Step 3: 빨간 불을 확인한다**

Run: `bash scripts/test_scaffold.sh`
Expected: FAIL 이 여럿. 사유가 아직 stderr 로 나가고 안내 줄이 없다.

실패 형태 셋을 본다. "변수가 비면 첫 세션에 안내한다"만 지금 빨간 불이고 나머지 둘(부정 단언)은 안내 줄이 아예 없어 이미 초록이다. 그 둘은 Step 7 뒤에 뜻이 생기므로, Step 8 에서 안내 줄을 일부러 무조건 내는 판으로 한 번 돌려 셋이 다 초록인지 본 뒤 조건을 되돌린다.

- [ ] **Step 4: 자동 갱신 사유를 stdout 으로 옮긴다**

`scripts/scaffold.sh`의 자동 갱신 블록을 바꾼다.

```bash
au_err="$(mktemp)"
autoupdated="$(ensure_marketplace_autoupdate "$CLAUDE_HOME" "$PLUGIN_ROOT" 2>"$au_err" || true)"
if [ -n "$autoupdated" ]; then
  echo "🔵 disciplined-coder: 이 플러그인의 자동 갱신을 켰다(마켓플레이스 항목에 autoUpdate 만 넣었고 다른 설정은 그대로다). 고친 파일과 그 사본(.bak)은 아래와 같다."
  printf '%s\n' "$autoupdated" | while IFS= read -r changed; do
    [ -n "$changed" ] && echo "  $changed (사본: $changed.bak)"
  done
fi
if [ -s "$au_err" ]; then
  while IFS= read -r line; do
    if [ -n "$line" ]; then printf '%s\n' "$line"; fi
  done < "$au_err"
fi
rm -f "$au_err"
```

`_ensure_autoupdate.sh` 는 손대지 않는다. 그 함수는 모든 실패에서 0 으로 끝나므로 종료 코드는 통로가 못 된다. 사유는 stderr 로만 나오며 여기서 받아 옮긴다.

WARNING 블록을 켰다는 블록 **뒤에** 따로 두는 것이 "머리말 아래 안 섞인다"의 뜻이다. 켠 것이 없으면 머리말 자체가 안 나오고 WARNING 만 나온다.

- [ ] **Step 5: 나머지 ERROR·WARNING 을 stdout 으로 옮긴다**

- 정본 복사 실패 ERROR 에서 `>&2` 를 뺀다.
- `@import` 배선 실패 ERROR 에서 `>&2` 를 뺀다.
- "cannot read … 이 세션의 stdout 보강에서 빠진다" WARNING 에서 `>&2` 를 뺀다.
- "WARNING: source not found" 를 내는 줄에서도 `>&2` 를 뺀다.

종료 코드는 그대로 둔다. 정본 복사 실패는 1 이고 그 밖은 0 이다.

- [ ] **Step 6: PYTHONUTF8 판정 함수를 넣는다**

`scripts/scaffold.sh` 위쪽 함수 자리에 넣는다.

```bash
# 윈도우 사용자 환경 변수 PYTHONUTF8 을 읽는다. 프로세스 환경이 아니라 레지스트리를 보는 이유는,
# SetEnvironmentVariable('User') 이 레지스트리만 바꿔 이미 뜬 Claude Code 의 환경에는 안 실리기
# 때문이다. 프로세스 환경을 보면 넣은 뒤에도 계속 "비어 있다"가 참이라 안내가 되풀이된다.
# 테스트는 DISCIPLINED_CODER_UTF8_STATE 로 결과를 주입해 OS 와 레지스트리를 안 본다.
utf8_user_var_state() {
  if [ -n "${DISCIPLINED_CODER_UTF8_STATE:-}" ]; then printf '%s' "$DISCIPLINED_CODER_UTF8_STATE"; return 0; fi
  case "$(uname -s 2>/dev/null)" in
    MINGW*|MSYS*|CYGWIN*) ;;
    *) printf 'not-windows'; return 0 ;;
  esac
  if reg query "HKCU\\Environment" //v PYTHONUTF8 >/dev/null 2>&1; then printf 'set'; else printf 'unset'; fi
}
```

`//v` 는 Git Bash 가 `/v` 로 되돌린다. `/v` 로 쓰면 경로로 바꿔 버려 `reg` 가 못 알아듣는다.

- [ ] **Step 7: 안내 줄을 카파시 넛지 옆에 둔다**

`scripts/scaffold.sh` 의 카파시 넛지 블록 뒤에 넣는다. 조건이 같아야 매 세션 뜨지 않는다.

```bash
# 4d) PYTHONUTF8 넛지(안내만): 정본이 새로 깔리거나 갱신된 세션에만, 사용자 환경 변수가 비었을 때만.
#     매 세션 뜨면 세션 시작 알림 전체를 흘려보게 된다 — 카파시 넛지와 같은 조건에 묶는다.
if [ "$canon_changed" -eq 1 ] && [ "$(utf8_user_var_state)" = "unset" ]; then
  echo "🔵 disciplined-coder: 파이썬 한국어 깨짐을 막으려면 /setup-discipline 을 실행하라(윈도우 사용자 환경 변수 PYTHONUTF8=1 을 넣는다)."
fi
```

- [ ] **Step 8: 부정 단언이 뜻을 갖는지 한 번 확인한다**

Step 7 의 `if` 조건을 잠시 `true` 로 바꿔 안내 줄이 무조건 나오게 하고 테스트를 돌린다.

Run: `bash scripts/test_scaffold.sh`
Expected: "둘째 세션에는 안내하지 않는다"와 "변수가 있으면 안내하지 않는다"가 FAIL

두 부정 단언이 빨간 불이 되는 것을 본 뒤 조건을 되돌린다. 이 걸음이 없으면 그 둘은 아무것도 재지 않는 항진 단언으로 남는다.

- [ ] **Step 9: 초록 불을 확인한다**

Run: `bash scripts/test_scaffold.sh`
Expected: `FAIL=0`

`2nd run sends nothing` 과 `CRLF: sends nothing` 이 여전히 초록인지 눈으로 확인한다. 둘 다 주입 기본값 `set` 으로 도므로 안내 줄이 나지 않는다.

- [ ] **Step 10: setup-discipline 명령이 묻고 넣게 한다**

`commands/setup-discipline.md` 끝에 문단을 더한다.

```markdown
스크립트를 돌린 뒤, 이 PC 가 윈도우이고 사용자 환경 변수 `PYTHONUTF8` 이 비어 있으면 넣을지 물어라.
비어 있는지는 레지스트리로 본다.

`reg query "HKCU\Environment" //v PYTHONUTF8`

이 명령이 실패하면 비어 있는 것이다. 그때만 Think Before Acting 대로 선택지가 있는 질문으로 묻는다. 넣는 쪽을
고르면 다음을 실행하고 결과를 한 줄로 알린다.

`powershell -NoProfile -Command "[Environment]::SetEnvironmentVariable('PYTHONUTF8','1','User')"`

이미 값이 있으면 묻지 않고 건드리지 않는다. 되돌리기는 같은 자리에서 변수를 지우는 것이며, 새 값은
이미 열려 있는 창에는 실리지 않고 다음에 여는 창부터 실린다. 그 사실을 함께 알린다.
```

- [ ] **Step 11: 안내 문구와 문서 넷을 고친다**

- `commands/show-principles.md` 의 안내 문구를 원인을 확정하지 않는 문장으로 바꾼다.

```markdown
원칙 사본이 없다. 새 세션을 열거나 `/setup-discipline` 을 실행하라.
```

- `README.md` 「동작 확인과 복구」와 commands 둘에 확인법을 적는다.

```markdown
세션 시작 알림에 `ERROR` 나 `WARNING` 줄이 없으면 정상이다. 정상 회차에도 정본 전문과 자동 갱신 알림과 카파시 권유가 stdout 으로 나가므로, '출력이 없으면 정상'이 아니라 '오류 줄이 없으면 정상'이다. 확인은 `/show-principles` 로 한다.
```

- `skills/domain-plugin/SKILL.md` 「사용자 설정 파일을 고칠 때 지킬 것」에 한 줄 더한다.

```markdown
- OS 환경 변수는 물어서 넣는다. 이미 값이 있으면 건드리지 않는다.
```

- `scripts/seal_reviews.sh` 의 `mapfile` 을 `while read` 로 바꾼다. 반복문 본문의 마지막 명령이 조건 결합이면 값이 빌 때 상태 1 로 끝나 `set -e` 아래에서 스크립트가 죽는다. `if` 로 감싼다. 리뷰가 앞 판에서 이것을 짚었다.

```bash
if [ "${#files[@]}" -eq 0 ]; then
  while IFS= read -r p; do
    if [ -n "$p" ]; then files+=("$ROOT/$p"); fi
  done <<EOF
$(cd "$ROOT" && git ls-tree -r --name-only HEAD -- docs/superpowers/reviews 2>/dev/null)
EOF
fi
```

`mapfile` 은 bash 4 부터라 오래된 bash 에서 조용히 빈 배열을 만든다.

- [ ] **Step 12: 계약 테스트 다섯을 돌린다**

Run: `bash scripts/test_assertions.sh`
Run: `bash scripts/test_audit.sh`
Run: `bash scripts/test_docs_drift.sh`
Run: `bash scripts/test_hooks.sh`
Run: `bash scripts/test_scaffold.sh`
Expected: 다섯 모두 `FAIL=0`

Run: `claude plugin validate ./`
Expected: `version` 경고 하나

- [ ] **Step 13: 봉인 스크립트를 인자와 함께 돌려 본다**

인자 없이 부르지 않는다. 인자 없이 부르면 이 워크트리의 기록 전부가 읽기 전용이 되고 되돌리는 걸음이 없다(Global Constraints).

Run: `cp docs/superpowers/reviews/2026-09-05-audit-roots-plan-review.md "$SCRATCH/seal-probe.md"`
Run: `bash scripts/seal_reviews.sh "$SCRATCH/seal-probe.md"`
Expected: `sealed: 1`

Run: `chmod u+w "$SCRATCH/seal-probe.md" && rm -f "$SCRATCH/seal-probe.md"`

- [ ] **Step 14: 커밋한다**

```bash
git add -A
git commit -q -F - <<'EOF'
세션 시작의 오류 사유를 사용자에게 닿는 통로로 옮긴다

SessionStart 훅의 stderr 는 사용자에게 닿지 않아, 자동 갱신 실패 사유와
정본 복사 실패가 조용히 사라지고 있었다. 그 함수는 모든 실패에서 0 으로
끝나므로 종료 코드가 아니라 stderr 를 받아 stdout 으로 옮긴다. 켰다는
머리말 아래 섞이지 않게 블록을 나눴다.

PYTHONUTF8 안내는 레지스트리를 읽어 판정하고 정본이 갱신된 세션에만
띄운다. 프로세스 환경을 읽으면 넣은 뒤에도 되풀이되고, 매 세션 뜨면 알림
전체를 흘려보게 된다. 테스트는 파일 머리에서 상태를 내보내 CI 와 이 PC
에서 같게 돈다.

Co-Authored-By: Claude Opus 5 (1M context) <noreply@anthropic.com>
Claude-Session: https://claude.ai/code/session_01T1Daa3xJNPhZBQa8DbnvRj
EOF
```

---

## 자기 검토

**spec 커버리지.** spec 의 절을 하나씩 짚어 과제를 댄다. 전제와 병합 순서는 Task 0. 1절 소유자 셋은 Task 1. 2절 따르는 문서는 Task 2. 3절 스크립트와 기록 계약은 Task 3. 4절 검사는 Global Constraints 의 실패 형태 셋과 각 과제의 Step 1~3 과 새 단언 걸음에 흩어져 있다. 5절 앞 둘(알림 통로, PYTHONUTF8)은 Task 5, 뒤 둘(훅 목록, writing-korean)은 Task 4. 「순서와 되돌리기」의 0단계와 커밋 단계 다섯이 Task 0~5 와 하나씩 짝이 맞는다. 성공 기준 다섯 가운데 넷은 Task 3 Step 14~15 와 각 과제의 테스트 걸음이 재고, 다섯째(다음 회차가 확인한다)는 이 계획 밖이다.

**단언 목록은 검색으로 도출한다.** 각 과제의 Step 1 이 계약 테스트 **다섯 전부**를 검색한다. 계획이 든 앵커 목록은 이 계획을 쓴 시점의 것이고, 검색 결과가 그보다 많으면 그 줄도 같은 커밋에서 고친다. 줄 번호는 Task 0 의 rebase 뒤 밀리므로 문장으로 찾는다.

**겹치는 파일.** README 는 Task 1(「주의」 포인터)·Task 4(훅 절)·Task 5(「동작 확인과 복구」)에, lens-readability 는 Task 2(계약·프롬프트·예외 참조)·Task 4(「고칠 순서」 사본)에 걸린다. 같은 파일의 다른 덩이라 커밋 되돌리기는 충돌 없이 된다. Task 4 Step 4 가 이 겹침을 다루는 자리다. 테스트 파일도 겹친다. `test_docs_drift.sh` 는 Task 1·2·4 에, `test_audit.sh` 는 Task 1·2·3 에 걸리며 서로 덮어쓰는 자리는 없다.

**이름 일관성.** `dispatching-lenses` 의 절 이름 일곱은 Task 1 이 정하고 Task 2 가 그 이름으로 참조한다. 스크립트 인자 이름(`--prior`, `--prior-diff`)과 측정 명령의 마지막 인자 뜻(`[이번 diff.json]`)은 Task 3 이 정하고 Task 2 Step 8 이 절차 문서에 같은 글자로 적는다. 두 과제의 순서가 뒤집히면 절차 문서와 스크립트가 갈리므로 Task 2 를 Task 3 보다 먼저 한다. 테스트 파일 안의 변수 이름은 파일마다 다르다. meta-aggregate 경로는 `test_docs_drift.sh` 에서 `AGG`, `test_audit.sh` 에서 `MA` 이고 절차 문서 경로 `PDA` 는 `test_audit.sh` 에만 있다. 단언을 옮길 때 그 파일에 실재하는 이름을 쓴다.

<!-- spec-review: passed -->
