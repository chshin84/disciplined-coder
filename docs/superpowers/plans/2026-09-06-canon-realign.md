# 정본 호명 삭제와 카파시 절 축약 구현 계획

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** 정본에서 원칙을 호명하는 문장 셋을 걷어내고, 절 이름 하나를 고치고, 카파시 절을 45줄 이하로 줄이고, 기록 이름 규칙의 소유권을 `review-docs`로 옮기고, 접기 뒤에 낡은 것 넷을 지금 배선에 맞춘다.

**Architecture:** 이 저장소에 단위 시험 틀은 없다. `scripts/test_*.sh`가 문자열 단언으로 문서와 코드를 맞대는 가드이며 그것이 이 계획의 시험이다. 그래서 각 걸음은 가드를 먼저 새 상태로 바꿔 빨갛게 만들고, 대상을 고쳐 초록으로 되돌린다. 태스크 경계는 초록이 나는 지점에 긋고 태스크마다 커밋 하나로 끝낸다.

**Tech Stack:** bash, grep, awk, git. 새 파이썬 파일은 만들지 않는다. 줄 수를 세는 것은 `awk`로 시험 안에서 한다.

**Spec:** `docs/superpowers/specs/2026-09-06-canon-realign-design.md`

## Global Constraints

- 작업 폴더는 워크트리 `D:\projects\disciplined-coder\.claude\worktrees\canon-realign`이고 브랜치는 `worktree-canon-realign`이다. 원래 저장소 뿌리로 `cd` 하지 않는다.
- 워크트리 안에서는 한 호출에 명령 하나만 보낸다. `for` 반복문과 `.`(source)과 `$((...))`와 `sed -n`이 "too complex to verify"로 거부된 실측이 있다. 여러 명령을 이어야 하면 저장소 밖 스크래치패드에 스크립트 파일로 두고 `bash 파일.sh`로 부른다.
- **시험 전량 실행 명령의 소유자는 `CLAUDE.md`의 「변경 뒤 실행」 절이다.** 그 명령을 그대로 쓴다. 이 계획에 다시 적지 않는다 — `scripts/test_docs_drift.sh:452`가 그 줄의 실재를 검사한다. 앞 제약 때문에 워크트리에서 그 반복문을 한 호출로 못 보내면, 같은 내용을 스크래치패드 스크립트로 옮겨 부르되 계약은 그대로 `ALL PASS` 한 줄이다.
- 정본의 조항 열넷은 `**\`ID\`` 굵은 불릿 문법을 유지한다. `LOCAL-FIRST`도 포함한다.
- 옛 조항 이름 `ASK-FORK`·`MEASURE-FIRST`·`SIMPLE`·`SURGICAL`·`TDD`를 되살리지 않는다.
- 「문서 타입과 수명」 표와 「수정 규율」 표는 건드리지 않는다.
- `hooks/doc_format_pretooluse.sh`와 `README.md:66`은 건드리지 않는다. 그것이 부르는 절 이름 「문서를 쓰고 관리할 때」가 안 바뀐다.
- 새 `check` 줄을 쓸 때 `scripts/test_scaffold.sh:422`를 본보기로 삼지 않는다. 그 줄은 역따옴표가 안 이스케이프되어 `LOCAL-FIRST`가 명령으로 실행되고 실제로는 `는 원칙이 아니라`만 검사한다. 역따옴표는 428행처럼 `\``로 이스케이프한다.
- 커밋 메시지 끝에 아래 두 줄을 넣는다.
  ```
  Co-Authored-By: Claude Opus 5 (1M context) <noreply@anthropic.com>
  Claude-Session: https://claude.ai/code/session_01AjynZgDJig4u3EeurYa7oZ
  ```

---

### Task 1: 호명 문장 셋을 지우고 절 이름 하나를 고치고 넛지를 맞춘다

**Files:**
- Modify: `agent-principles.md` (5행, 82행, 84행, 99행, 149행)
- Modify: `scripts/test_scaffold.sh` (402~405행 주석, 409행, 424행 뒤 단언 넷 추가)
- Modify: `scripts/test_hooks.sh` (136행, 156행 뒤 단언 넷 추가)
- Modify: `skills/domain-readme/SKILL.md:7`
- Modify: `README.md:40`, `README.md:67`
- Modify: `hooks/rules_nudge_pretooluse.sh` (2~12행 머리주석, 홈 해석 추가, 메시지)

**Interfaces:**
- Consumes: `scripts/_resolve_home.sh`의 `resolve_home claude`. `.claude` 디렉터리를 stdout으로 돌려주고, `USERPROFILE` 기준 홈이 bash `$HOME`과 다르면 stderr에 note를 한 줄 낸다. 훅은 stdout만 쓰고 stderr는 버린다. `CLAUDE_HOME_DIR`가 있으면 그 값을 그대로 돌려주므로 시험이 홈을 픽스처로 돌릴 수 있다.
- Produces: 정본의 새 절 이름 「한국어로 쓸 때」와 넛지 메시지의 새 꼴 `규칙 정본은 <절대경로> 에 있다.`. Task 3이 카파시 절을 고칠 때 이 절 이름이 이미 바뀌어 있다고 가정한다.

- [ ] **Step 1: 가드를 새 상태로 바꾼다 — 절 이름 목록과 그 위 주석**

`scripts/test_scaffold.sh:409`에서 `"대화할 때"`를 `"한국어로 쓸 때"`로 바꾼다. 나머지 여덟은 그대로 둔다.

```bash
for sec in "원칙" "Karpathy guidelines" "한국어로 쓸 때" "문서를 쓰고 관리할 때" "코딩할 때" "검증" "미해결의 처분" "병렬 오케스트레이션" "이 파일의 취급"; do
```

같은 파일 402~405행 주석이 없어질 갈래 이름과 없어질 호명 방식을 둘 다 설명한다. 아래로 바꾼다. 계획이 만든 고아를 계획이 치운다.

```bash
# --- canon-realign: 정본이 원칙을 호명하지 않고 갈래는 걸리는 대상으로 이름 붙는다 ---
# 접기(3fced53) 뒤에 정본이 원칙 전부를 갖는다. 갈래마다 원칙을 이름으로 다시 부르던 문장 셋은
# 「원칙」 절이 이미 선언한 것을 부분집합으로 되풀이해 빠진 것이 안 걸린다는 뜻으로 읽혔다.
# 이름이 범위를 좁게 말하던 절 하나만 「한국어로 쓸 때」로 바꾸고 나머지 여덟은 그대로 둔다.
```

- [ ] **Step 2: 가드를 새 상태로 바꾼다 — 호명 문장의 부재**

`scripts/test_scaffold.sh`의 424행(`check "canon: subagent prompt context rule"` 줄) 바로 아래에 넷을 더한다. 앞 셋은 지운 조각의 부재를, 넷째는 옛 절 이름이 정본 어디에도 안 남는 것을 단언한다.

```bash
check "canon: no roll-call in the Korean section"    "! grep -qF '\`FAIL-LOUD\`와 \`NAME-ITEMS\`와 \`SECRETS\`가 답 한 번에도 걸린다' '$CANON'"
check "canon: no roll-call in the document section"  "! grep -qF '\`SSOT\`와 \`NAME-ITEMS\`와 \`EXPLICIT\`이 문서에도 그대로 걸리고' '$CANON'"
check "canon: no roll-call in the code section"      "! grep -qF '\`FOCUSED\`와 \`SSOT\`와 \`EXPLICIT\`이 코드에 그대로 걸리고' '$CANON'"
check "canon: old section name is gone everywhere"   "! grep -rqF '대화할 때' '$CANON' '$HERE/skills' '$HERE/README.md' '$HERE/CLAUDE.md' '$HERE/hooks' '$HERE/scripts/scaffold.sh'"
```

- [ ] **Step 3: 가드를 새 상태로 바꾼다 — 넛지 메시지**

`scripts/test_hooks.sh:136`의 표시 문구를 지금 배선으로 바꾼다.

```bash
echo "[rules-nudge-pre — 세션의 첫 파일 편집 전에 정본의 절대경로와 domain-korean 을 한 번 알린다]"
```

같은 파일 156행(`check "session_id 없음 → 매번 안내"` 줄) 바로 아래에 넷을 더한다. 경로를 픽스처 상수와 맞대지 않고 **훅이 실제로 낸 문장에서 뽑아** 그 파일이 있는지 본다. 183~185행이 문서 형식 넛지에 쓰는 것과 같은 방식이다. 픽스처가 만든 파일을 그대로 다시 보는 단언은 무엇을 고쳐도 참이라 `scripts/test_assertions.sh`가 금지한다.

```bash
NH="$T/nudgehome"; mkdir -p "$NH/disciplined-coder"; printf 'x\n' > "$NH/disciplined-coder/agent-principles.md"
cnudh() { printf '%s' "$1" | TMPDIR="$T/tmp" CLAUDE_HOME_DIR="$2" bash "$CNUD"; }
NUDGE_CANON="$(cnudh "$(JS s8 "" "$T/src/main.py")" "$NH" | sed -n 's/.*규칙 정본은 \(.*\) 에 있다\..*/\1/p')"
check "넛지에서 정본 경로가 뽑힌다"                 "[ -n \"\$NUDGE_CANON\" ]"
check "뽑은 경로에 파일이 실재한다"                 "[ -f \"\$NUDGE_CANON\" ]"
check "넛지에 상시 적재라는 거짓 문장이 없다"       "! cnudh '$(JS s8b "" "$T/src/main.py")' '$NH' | grep -qF '상시로 싣고'"
check "사본이 없으면 그 사실을 알린다"              "cnudh '$(JS s8c "" "$T/src/main.py")' '$T/emptyhome' | grep -qF '사본을 못 찾았다'"
```

- [ ] **Step 4: 가드가 빨간지 확인한다**

Run: `bash scripts/test_scaffold.sh`
Expected: FAIL. 절 이름 `한국어로 쓸 때`가 정본에 없고, 호명 문장 셋이 아직 있으며, 옛 이름이 여러 곳에 남아 있다.

Run: `bash scripts/test_hooks.sh`
Expected: FAIL. 넛지가 아직 `규칙 정본은 ... 에 있다.` 꼴을 안 내고 거짓 문장을 담는다.

- [ ] **Step 5: 정본의 절 제목과 호명 문장을 고친다**

`agent-principles.md:82`의 `## 대화할 때`를 `## 한국어로 쓸 때`로 바꾼다.

84행 전체를 아래 한 줄로 바꾼다. 호명 앞 절을 지우고, 제목을 되풀이하던 문장은 지우는 대신 그 절의 결론으로 바꾼다. 소제목 바로 아래 첫 문장에 결론이 와야 한다는 정본의 `READ-FLOW`를 정본 자신이 지킨다.

```
아래 넷이 한국어 문장을 어떻게 쓰는지 정하고, 각 조항의 상세와 그것이 어느 측정에서 나왔는지는 `domain-korean`이 소유한다.
```

99행 전체를 아래 한 줄로 바꾼다. 앞에 결론을 놓고 제외 표시를 뒤로 보낸다.

```
문서는 타입에 따라 수명과 수정 규율이 다르므로 만지기 전에 타입부터 가른다. spec과 plan은 superpowers가 소유하므로 여기서 다루지 않는다.
```

149행 전체를 아래로 바꾼다. 이 절은 제목이 안 바뀌므로 한정 문장이 제목의 되풀이가 아니고 그대로 결론 노릇을 한다.

```
아래 셋은 코드에만 걸린다.
```

5행 전체를 아래로 바꾼다. 이름을 부르는 방식이 없어졌고 절 이름 하나가 바뀌었다.

```
이 문서는 원칙을 먼저 정의하고, 그다음 한국어로 쓸 때와 문서를 쓰고 관리할 때와 코딩할 때로 나누어 그 갈래에만 걸리는 것을 적는다. 한 원칙을 두 번 적지 않는다.
```

- [ ] **Step 6: 넛지 훅을 고친다**

`hooks/rules_nudge_pretooluse.sh`의 **2~12행**(셰뱅 다음부터 `set -euo pipefail` 직전까지)을 아래로 바꾼다. 1행 셰뱅은 그대로 둔다.

```bash
# PreToolUse(Write|Edit|Bash): 이 세션이 파일을 처음 건드리려 하면 규칙이 어디 있는지 한 번 알린다
# (비블로킹, 게이트 아님). 편집 뒤가 아니라 편집 전에 알려야 규칙을 읽고 고칠 수 있다 — 새 문서 넛지가
# PreToolUse 인 것과 같은 이유다.
#
# 코드인지 문서인지 가르지 않는다. 셸 명령의 대상은 실행해 봐야 정해지므로(`sed -i "$f"` 의 $f)
# 편집 전에 확실히 가르는 방법이 없고, 추측으로 가르면 틀린 쪽을 가리키거나 조용히 안 걸린다.
# 정본이 코드 규칙과 문서 규칙을 모두 가지므로 가를 필요도 없다.
#
# 알리는 것은 관리 디렉터리 사본의 절대경로다. 상대 이름은 이 저장소 밖에서 안 열린다.
# 홈 해석의 소유자는 scripts/_resolve_home.sh 이므로 경로를 여기 박지 않고 그것으로 도출한다.
# 사본이 없으면 경로 대신 그 사실을 알린다 — 없는 파일을 열라고 시키지 않는다(FAIL-LOUD).
#
# 세션 키는 훅 입력의 공통 필드 session_id 에 agent_id(서브에이전트 안의 훅 호출에만 온다)를 이은 것이다.
# 그래서 서브에이전트는 부모의 표시 파일과 무관하게 자기 넛지를 한 번 받는다.
# 필드의 정본: https://code.claude.com/docs/en/hooks
```

`. "$DIR/_json_escape.sh"` 줄 바로 아래에 홈 해석을 더한다. `set -e` 아래에서 source 가 실패해도 넛지가 조용히 사라지지 않게 실패를 삼키고 함수 유무로 가른다.

```bash
# 홈 해석은 scripts/_resolve_home.sh 가 소유한다. 그 파일이 없어도 넛지는 나가야 하므로
# source 실패를 삼키고 함수가 섰는지로 가른다 — 조용히 빠지지 않는다(FAIL-LOUD).
. "$DIR/../scripts/_resolve_home.sh" 2>/dev/null || true
CANON_PATH=""
if declare -f resolve_home >/dev/null 2>&1; then
  CANON_PATH="$(resolve_home claude 2>/dev/null)/disciplined-coder/agent-principles.md"
fi
if [ -n "$CANON_PATH" ] && [ -f "$CANON_PATH" ]; then
  where="규칙 정본은 $CANON_PATH 에 있다."
else
  where="규칙 정본의 사본을 못 찾았다 — disciplined-coder setup-discipline 을 돌려라."
fi
```

`msg=` 줄을 아래로 바꾼다.

```bash
msg="🧑‍💻 이 세션에서 파일을 처음 건드린다 — $where 한국어 문장 규칙의 상세는 disciplined-coder domain-korean 이 갖는다. 서브에이전트에는 정본이 안 실리므로 그 경로를 프롬프트에 직접 넣어라. 넛지일 뿐 차단은 아니다."
```

- [ ] **Step 7: 정본을 가리키는 문서 셋을 고친다**

`skills/domain-readme/SKILL.md:7`의 `정본 「대화할 때」의 두괄식 조항이다`를 `정본 「한국어로 쓸 때」의 두괄식 조항이다`로 바꾼다.

`README.md:40`의 `그 정본이 대화할 때와 문서를 쓰고 관리할 때와 코딩할 때의 규칙을 모두 갖는다`를 `그 정본이 한국어로 쓸 때와 문서를 쓰고 관리할 때와 코딩할 때의 규칙을 모두 갖는다`로 바꾼다.

`README.md:67`의 `정본과 \`domain-korean\`의 경로를 한 번 알린다`를 `정본의 절대경로와 \`domain-korean\`을 한 번 알린다`로 바꾼다. 같은 줄의 나머지 문장은 그대로 둔다.

- [ ] **Step 8: 시험이 초록인지 확인한다**

Run: `bash scripts/test_scaffold.sh`
Expected: PASS (FAIL=0). 특히 `canon: old section name is gone everywhere`가 통과해야 Step 7을 하나라도 빠뜨리지 않은 것이 확인된다.

Run: `bash scripts/test_hooks.sh`
Expected: PASS (FAIL=0)

Run: `CLAUDE.md`의 「변경 뒤 실행」이 정한 전량 실행
Expected: `ALL PASS`

- [ ] **Step 9: 커밋**

```bash
git add agent-principles.md scripts/test_scaffold.sh scripts/test_hooks.sh skills/domain-readme/SKILL.md README.md hooks/rules_nudge_pretooluse.sh
git commit -m "정본의 원칙 호명 셋을 걷어내고 넛지가 실재하는 경로를 알리게 한다"
```

---

### Task 2: 기록 이름 규칙의 소유권을 review-docs 로 옮긴다

**Files:**
- Modify: `agent-principles.md` (기록 파일 이름 문단)
- Modify: `skills/review-docs/SKILL.md` (44행, 새 절 추가)
- Modify: `skills/audit-repo-docs/SKILL.md:98`
- Modify: `skills/review-specs/SKILL.md:93`
- Modify: `scripts/audit_verify.sh:6-8`
- Modify: `scripts/test_audit.sh:173`
- Modify: `scripts/test_docs_drift.sh` (200행 주석, 194행, 201행, 202행, 부재 단언 둘 추가)

**Interfaces:**
- Consumes: Task 1이 남긴 정본. Task 1이 바꾸는 5·82·84·99행이 모두 한 줄에서 한 줄로 가고 149행은 뒤에 있으므로 기록 문단의 줄 번호는 안 밀린다. 그래도 줄 번호로 찾지 말고 `grep -n "기록 파일 이름은"`으로 찾는다.
- Produces: `skills/review-docs/SKILL.md`의 새 절 「기록 파일 이름 규칙」. Task 3은 이 절을 안 건드린다.

- [ ] **Step 1: 가드를 새 소유자로 바꾼다**

`scripts/test_audit.sh:173`을 아래로 바꾼다.

```bash
check "이름 규칙의 소유자가 그 꼴을 적는다" "grep -qF 'lens-<렌즈 이름>-<띄운 횟수>.json' '$HERE/skills/review-docs/SKILL.md'"
```

`scripts/test_docs_drift.sh:200`의 주석을 아래로 바꾼다. 소유자가 바뀌므로 그 주석이 낡는다.

```bash
# 이름 규칙은 review-docs 가 소유한다. 호출자에게 같은 문구를 요구하면 검사가 복제를 강제한다.
```

201행을 아래로 바꾼다. `$CANON` 대신 그 파일이 113행에 이미 갖고 있는 `$DOCS`를 쓴다. 같은 경로를 손으로 다시 적으면 한 스크립트에 두 꼴이 남는다.

```bash
check "기록 이름 규칙을 소유자가 적는다"     "grep -qF '-review-2.md' \"\$DOCS\""
```

194행의 고정 문자열 `'정본의 기록 이름 규칙이 소유하므로'`를 `'review-docs 가 소유하므로'`로 바꾼다.

202행의 고정 문자열 `'정본의 기록 이름 규칙'`을 `'review-docs 가 소유'`로 바꾼다.

같은 자리에 부재 단언 둘을 더한다. 옮긴 뒤 지켜야 할 사실은 "정본에 그 문단이 없다"와 "정본이 새 소유자를 가리킨다"인데, 그것을 붙드는 상시 가드가 없으면 468자가 조용히 되돌아온다.

```bash
check "정본은 그 규칙을 더 안 적는다"        "! grep -qF 'lens-<렌즈 이름>-<띄운 횟수>.json' \"\$CANON\""
check "정본이 새 소유자를 가리킨다"          "grep -qF '기록 파일의 이름과 회차 표기는 \`review-docs\`가 소유한다' \"\$CANON\""
```

- [ ] **Step 2: 가드가 빨간지 확인한다**

Run: `bash scripts/test_audit.sh`
Expected: FAIL. `review-docs`에 아직 그 꼴이 없다.

Run: `bash scripts/test_docs_drift.sh`
Expected: FAIL. 다섯 단언이 새 상태를 못 찾는다.

- [ ] **Step 3: 정본에서 문단을 빼고 한 줄을 남긴다**

`agent-principles.md`의 `기록 파일 이름은 ...`으로 시작하는 문단 전체(한 줄이다)를 아래 한 줄로 바꾼다.

```
기록 파일의 이름과 회차 표기는 `review-docs`가 소유한다.
```

- [ ] **Step 4: review-docs 에 규칙 본문을 넣는다**

먼저 44행의 두 문장 가운데 뒤 문장 `이름과 회차 표기는 정본의 기록 이름 규칙을 따른다.`를 아래로 바꾼다. 그 줄이 적는 `-check.md` 꼴이 새 절의 규칙에서 도출된 것임을 드러내야 한 파일에 이름 꼴이 두 벌로 보이지 않는다.

```
결과는 아래 「기록 파일 이름 규칙」이 정한 이름으로 남기며, 문서 검진의 종류는 `check`다.
```

그다음 파일 끝에 새 절을 더한다. 절 이름을 「기록」과 안 겹치게 「기록 파일 이름 규칙」으로 둔다.

```markdown
## 기록 파일 이름 규칙

이 절이 기록 파일 이름 규칙의 소유자다. 문서 검진과 spec·plan 리뷰와 레포 감사가 모두 이 규칙을 따른다.

기록 파일 이름은 `docs/superpowers/reviews/YYYY-MM-DD-<주제>-<종류>.md` 하나다. 종류는 넷이다. `review`는 spec·plan 리뷰이고, `check`는 문서 검진과 워크플로 검증이고, `prior-art`는 선행연구 대조이고, `audit`은 레포 감사다. 레포 감사는 주제가 `self`라 `2026-09-05-self-audit.md` 꼴이 된다. 같은 날 같은 주제의 두 번째 회차는 종류 뒤에 회차를 붙인다(`-review-2.md`·`-audit-2.md`). 앞 회차를 덮거나 이어 붙이지 않는다. 렌즈별 원본은 요약문과 같은 이름의 폴더에 `lens-<렌즈 이름>-<띄운 횟수>.json`으로 둔다. 스킬 디렉터리 이름을 그대로 쓰므로 접두사를 떼지 않으며, 그 이름은 `scripts/audit_verify.sh`가 검사한다. 이 규칙 전의 기록은 이름이 달라도 고치지 않는다.
```

- [ ] **Step 5: 정본을 가리키던 포인터 셋을 새 소유자로 돌린다**

`skills/audit-repo-docs/SKILL.md:98`의 `이름 규칙은 정본의 기록 이름 규칙을 따른다.`를 `이름 규칙은 review-docs 가 소유하므로 그 스킬을 따른다.`로 바꾼다.

`skills/review-specs/SKILL.md:93`의 `이름 규칙은 정본의 기록 이름 규칙이 소유하므로 여기 베끼지 않는다`를 `이름 규칙은 review-docs 가 소유하므로 여기 베끼지 않는다`로 바꾼다.

`scripts/audit_verify.sh`의 6~8행을 아래로 바꾼다.

```bash
# 렌즈 원본 이름 규칙은 review-docs 가 소유한다. 그 규칙이 정한 꼴이
# `lens-<렌즈 이름>-<띄운 횟수>.json` 이고 아래 정규식이 그것을 그대로 옮긴 것이다. 그 행이
# 바뀌면 여기도 함께 바꾼다 — test_audit.sh 가 그 행의 실재를 검사한다.
```

- [ ] **Step 6: 시험이 초록인지 확인한다**

Run: `CLAUDE.md`의 「변경 뒤 실행」이 정한 전량 실행
Expected: `ALL PASS`

- [ ] **Step 7: 옛 소유자를 가리키는 곳이 안 남았는지 확인한다**

Run: `grep -rn "정본의 기록 이름 규칙" skills scripts agent-principles.md README.md CLAUDE.md`
Expected: 아무것도 안 나온다.

- [ ] **Step 8: 커밋**

```bash
git add agent-principles.md skills/review-docs/SKILL.md skills/audit-repo-docs/SKILL.md skills/review-specs/SKILL.md scripts/audit_verify.sh scripts/test_audit.sh scripts/test_docs_drift.sh
git commit -m "기록 이름 규칙의 소유권을 정본에서 review-docs 로 옮긴다"
```

---

### Task 3: 카파시 절을 45줄 이하로 다시 쓴다

**Files:**
- Modify: `agent-principles.md` (「Karpathy guidelines」 절 전체)
- Modify: `scripts/test_scaffold.sh` (420행 뒤에 고정 문자열 단언 넷과 줄 수 단언 하나 추가)
- Create: `docs/superpowers/reviews/2026-09-06-canon-realign-plan-review/karpathy-coverage.md`
- Modify: `C:\Users\ho381\.claude\projects\D--projects-disciplined-coder\memory\karpathy-upstream-watch.md` (git 밖이라 커밋에 안 들어간다)

**Interfaces:**
- Consumes: Task 1이 바꾼 절 이름. 카파시 절은 「원칙」과 「한국어로 쓸 때」 사이에 있다. Task 3이 420행 뒤에 넣는 것은 Task 1이 424행 뒤에 넣은 것에 안 밀린다.
- Produces: 없다. 마지막 태스크다.

**되돌림 주의:** 첫째 커밋이 고치는 정본 82행은 이 태스크가 갈아 쓰는 카파시 절 바로 다음 줄이다. 이 태스크가 남은 채 첫째 커밋을 `git revert` 하면 헝크의 앞 문맥이 안 맞아 손으로 풀어야 한다. 되돌릴 때는 셋째부터 되돌린다. 둘째 커밋은 줄이 안 겹쳐 단독으로 되돌려도 된다.

- [ ] **Step 1: 줄 수 단언과 고정 문자열 단언을 더한다**

`scripts/test_scaffold.sh:420`(`check "canon: subagent fleet rule stays"` 줄) 바로 아래에 다섯을 더한다. 지금은 이 절을 붙잡는 단언이 제목 넷과 문자열 셋뿐이라 나머지가 사라져도 안 잡힌다. 네 절에서 하나씩 골라 서로 헷갈리지 않는 문자열로 걸고, 줄 수는 `awk`로 센다. 새 파이썬 파일을 만들지 않는 이유는 그것이 어느 시험에도 CI에도 안 걸려 한 번 쓰고 안 불리는 파일이 되기 때문이다.

```bash
check "canon: measure-the-state rule stays"          "grep -qF \"Don't assume the current state\" '$CANON'"
check "canon: impossible-case rule stays"            "grep -qF 'No handling for situations that cannot occur' '$CANON'"
check "canon: pre-existing-dead-code rule stays"     "grep -qF \"Don't remove what was already unused\" '$CANON'"
check "canon: weak-criteria rule stays"              "grep -qF 'Weak criteria' '$CANON'"
# 카파시 절의 위 문턱. 제목 줄부터 다음 `## ` 줄 직전까지를 세고 45 를 넘으면 실패다.
check "canon: karpathy section is 45 lines or fewer" "[ \"\$(awk 'index(\$0,\"## Karpathy guidelines\")==1{s=NR;next} s&&index(\$0,\"## \")==1{print NR-s;exit}' '$CANON')\" -le 45 ]"
```

- [ ] **Step 2: 새 단언 다섯 가운데 넷이 초록이고 하나가 빨간지 확인한다**

Run: `bash scripts/test_scaffold.sh`
Expected: FAIL 하나. 고정 문자열 넷은 지금 본문에 있으므로 초록이고, 줄 수 단언만 63으로 빨갛다. 문자열 넷이 여기서 초록인 것이 맞다 — 재작성이 그 문장을 지우면 빨개지는 가드이므로 재작성 전에 서 있는 것을 확인해 두는 것이 목적이다.

- [ ] **Step 3: 카파시 절을 아래 본문으로 통째로 바꾼다**

`agent-principles.md`의 `## Karpathy guidelines` 줄부터 `## 한국어로 쓸 때` 줄 직전까지를 아래로 바꾼다. 본문은 43줄이고 **뒤에 빈 줄 하나를 남겨** 다음 제목과 띄운다. 그래서 단언이 세는 값은 44다.

```markdown
## Karpathy guidelines

From `andrej-karpathy-skills` 1.0.0, generalized from code to any artifact you produce — an answer, a document, or code.

**Tradeoff:** These guidelines bias toward caution over speed. For trivial tasks, use judgment.

### Think Before Acting

Before implementing, writing, or deciding:
- Don't assume the current state. Measure it in the actual code, data, and environment.
- State your assumptions explicitly, and surface the tradeoffs rather than hiding them.
- When measuring doesn't settle it, when something is unclear, or when several interpretations fit — stop, name what is unresolved, and ask. Ask as a question with options, never in plain prose. Never pick silently.
- If a simpler approach exists, say so. Push back when warranted. Don't launch a fleet of subagents for what one call can do.

### Simplicity First

- Nothing beyond what was asked.
- No abstraction for a single use.
- No flexibility or configurability that was not requested.
- No handling for situations that cannot occur.
- If you produced 200 lines and 50 would do, produce it again. Would an experienced colleague call this overbuilt? Then simplify.

### Surgical Changes

Every changed line must trace directly to the request.

When changing something that already works:
- Don't improve adjacent material, wording, or formatting.
- Don't rework what is not broken.
- Match the existing style, even if you would do it differently.
- If you notice unrelated dead material, say so — don't delete it.

When your change leaves orphans:
- Remove what your own change made unused.
- Don't remove what was already unused.

### Goal-Driven Execution

Turn the task into something you can check:
- "Add validation" → "Write the failing cases first, then make them pass"
- "Fix the bug" → "Reproduce it, then make the reproduction pass"
- For multi-step work, state the plan as numbered steps, each with the check that verifies it.
- Strong criteria let you loop on your own. Weak criteria ("make it work") need constant clarification.
```

절을 건너뛴 중복 하나를 여기서 지운다. 옛 본문의 마지막 문장 `Never say it is done without evidence that you ran the check`는 「검증」 절의 "실행 증거 없이 '됐다'고 하지 않는다"와 같은 규칙이므로 한국어 쪽만 남긴다.

- [ ] **Step 4: 시험이 초록인지 확인한다**

Run: `bash scripts/test_scaffold.sh`
Expected: PASS (FAIL=0). 고정 문자열이 셋에서 일곱으로 늘었고 일곱 다 새 본문에 있으며, 줄 수 단언이 44로 통과한다.

- [ ] **Step 5: 실패 유형 스물다섯을 맞대어 읽고 결과를 파일로 남긴다**

설계 문서의 표에 적힌 스물다섯을 새 본문과 맞대고 어느 줄이 담는지 적는다. 기계로 못 하는 확인이므로 사람이 읽는 걸음이고, 그래서 산출물을 파일로 남긴다. 안 남기면 건너뛴 회차와 다 맞댄 회차가 구별되지 않는다.

`docs/superpowers/reviews/2026-09-06-canon-realign-plan-review/karpathy-coverage.md`에 표 하나로 적는다. 왼쪽 칸이 실패 유형이고 오른쪽 칸이 그것을 담는 새 본문의 줄이다.

하나라도 못 찾으면 그 유형을 새 본문에 넣고 Step 4로 돌아간다. 넣어서 줄 수가 45를 넘으면 지우지 말고 멈춰서 사용자에게 알린다. 두 문턱이 동시에 안 서면 그것이 설계가 다시 정할 것이지 구현자가 한쪽을 고를 것이 아니다.

- [ ] **Step 6: 실행 증거 규칙이 정본에 한 번만 있는지 확인한다**

Run: `grep -c "Never say it is done" agent-principles.md`
Expected: `0`

Run: `grep -c "실행 증거 없이" agent-principles.md`
Expected: `1`

- [ ] **Step 7: 메모리를 갱신한다**

이 걸음이 Task 3에 있는 이유는 적을 내용이 카파시 절을 다시 쓴 뒤에만 참이기 때문이다.

`C:\Users\ho381\.claude\projects\D--projects-disciplined-coder\memory\karpathy-upstream-watch.md`에서 낡은 진술 셋을 고친다. 3행 `description`과 10행의 "정본은 Think Before Acting 하나만 갖고 나머지 셋은 플러그인을 가리킨다", 그리고 8행의 "그 절은 지금 「Think Before Acting」이다"다. 셋 다 정본이 카파시 네 절을 「Karpathy guidelines」 아래 하위 절로 갖고 산출물 기준으로 고쳐 썼다는 것으로 바꾼다. 고쳐 썼으므로 업스트림과 글자로는 대조되지 않고 뜻으로만 대조된다는 것도 적는다. `How to apply`의 `gh api` 명령과 2026-04-20 기준일은 그대로 둔다. 이 파일은 git 밖이라 커밋에 안 들어가고 어느 커밋을 되돌려도 안 되돌아온다.

- [ ] **Step 8: 시험 전부와 플러그인 검증**

Run: `CLAUDE.md`의 「변경 뒤 실행」이 정한 전량 실행
Expected: `ALL PASS`

Run: `claude plugin validate ./`
Expected: `version` 경고 하나만 낸다.

- [ ] **Step 9: 커밋**

```bash
git add agent-principles.md scripts/test_scaffold.sh docs/superpowers/reviews/2026-09-06-canon-realign-plan-review/karpathy-coverage.md
git commit -m "카파시 절의 형식 되풀이를 걷어내 63줄을 44줄로 줄인다"
```

---

### Task 4: 헐거워진 LOCAL-FIRST 가드를 고친다

이것은 앞 셋과 무관한 기존 결함이며 사용자가 함께 고치기로 정한 것이다. 줄이 안 겹치므로 단독으로 되돌릴 수 있다.

**Files:**
- Modify: `scripts/test_scaffold.sh:422`

**Interfaces:**
- Consumes: 없다. 앞 세 태스크와 줄이 안 겹친다.
- Produces: 없다.

- [ ] **Step 1: 결함을 재현한다**

Run: `bash scripts/test_scaffold.sh 2>&1 >/dev/null | grep -c "LOCAL-FIRST: command not found"`
Expected: `1` 이상. 역따옴표가 이스케이프 안 되어 `check`의 인자를 만들 때 `LOCAL-FIRST`가 명령으로 실행된다.

- [ ] **Step 2: 단언이 헐거운 것을 보인다**

정본의 `LOCAL-FIRST` 조항 줄에서 역따옴표 둘만 잠시 지운다(`` `LOCAL-FIRST`는 `` → `LOCAL-FIRST는`).

Run: `bash scripts/test_scaffold.sh`
Expected: `canon: local-first convention stays`가 그대로 통과한다. 검사되는 것이 `는 원칙이 아니라`뿐이라 역따옴표가 없어져도 안 잡힌다.

그다음 정본을 되돌린다.

Run: `git checkout -- agent-principles.md`
Expected: 정본이 원래대로 돌아온다.

- [ ] **Step 3: 422행을 고친다**

역따옴표를 428행과 같은 방식으로 이스케이프한다.

```bash
check "canon: local-first convention stays"          "grep -qF '\`LOCAL-FIRST\`는 원칙이 아니라' '$CANON'"
```

- [ ] **Step 4: stderr 가 깨끗해졌는지 확인한다**

Run: `bash scripts/test_scaffold.sh 2>&1 >/dev/null | grep -c "LOCAL-FIRST: command not found"`
Expected: `0`

- [ ] **Step 5: 단언이 이제 무는지 보인다**

Step 2와 같이 정본의 역따옴표 둘을 잠시 지운다.

Run: `bash scripts/test_scaffold.sh`
Expected: FAIL. `canon: local-first convention stays`가 빨개진다.

그다음 정본을 되돌린다.

Run: `git checkout -- agent-principles.md`
Expected: 정본이 원래대로 돌아온다.

- [ ] **Step 6: 시험이 초록인지 확인한다**

Run: `CLAUDE.md`의 「변경 뒤 실행」이 정한 전량 실행
Expected: `ALL PASS`

- [ ] **Step 7: 커밋**

```bash
git add scripts/test_scaffold.sh
git commit -m "역따옴표를 이스케이프해 LOCAL-FIRST 가드가 실제로 물게 한다"
```

<!-- spec-review: escalated -->
