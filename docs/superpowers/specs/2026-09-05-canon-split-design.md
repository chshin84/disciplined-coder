# 정본을 대화 규칙으로 좁히고 코딩 규칙을 domain-coding으로 옮긴다 — 설계

## 무엇을 고치려는가

정본 `agent-principles.md`는 `@import`로 모든 세션에 실린다. 그 안에 코드나 문서가 있어야만 어길 수 있는 조항이 대화 규칙과 섞여 있다. 2026-09-05 커밋 `b24fdfa`가 카파시(Andrej Karpathy) 지침 넷을 정본에 영어로 옮기면서 이 섞임이 더 커졌다. 코드 편집 규칙과 산출물 검증 규칙이 파일을 하나도 건드리지 않는 세션에도 실린다.

반대쪽 위험도 있다. 코딩 규칙을 스킬로 빼면 그 스킬을 열지 않은 세션에는 닿지 않는다. 이 실패는 `scripts/test_scaffold.sh`의 question-tool 검사 주석에 기록되어 있다. 질문 규칙이 리뷰 스킬 한 곳에만 있을 때 문서 검진 세션이 평문으로 물어 선택 대화창이 뜨지 않았다.

이 설계는 둘을 한 번에 푼다. 정본은 대화 규칙만 갖고, 코딩 규칙은 새 스킬 `domain-coding`이, 문서용 카파시 규칙은 새 스킬 `domain-writing`이 갖되 훅이 열게 한다. 층은 서로 배타적이지 않다. 정본의 규칙은 코딩과 문서에도 걸리고, 두 스킬의 규칙은 산출물이 있을 때만 걸린다.

## 결정

2026-09-05에 사용자가 정했다.

- 정본에 남는 기준은 "파일을 하나도 건드리지 않은 답 한 번으로도 어길 수 있으면 남는다"이다. 산출물이 있어야만 어길 수 있으면 스킬로 간다.
- `domain-coding`은 코드 파일에 세션의 첫 `Write`나 `Edit`이 들어올 때 훅이 열라고 알린다. 스킬 설명문에만 맡기지 않는다.
- 정본에서 나가는 다섯 조항 `EXPLAIN-STRUCTURE`·`EXPLICIT`·`FOCUSED`·`IDEMPOTENT`·`SSOT`는 모두 `domain-coding`이 갖는다.
- `domain-coding` 본문은 전부 영어다. 옮기는 다섯 조항은 한국어를 번역하지 않고, 같은 원칙을 말하는 널리 쓰이는 영어 정식 표현을 찾아 출처와 함께 쓴다.
- 스킬마다 자기 문장을 갖는다. 카파시 원문 파일 하나를 여러 스킬이 공유하지 않는다.
- 카파시의 문서용 문장 세 절은 `domain-docs`에 넣지 않고 새 스킬 `domain-writing`에 둔다. `domain-docs`는 지금 크기를 유지한다.
- 카파시 플러그인 설치 권유는 그대로 둔다.

## 기준을 적용한 배치

| 지금 정본에 있는 것 | 자리 | 이유 |
|---|---|---|
| `KO-SYNTAX`·`PLAIN-KO`·`PROSE-FORM`·`READ-FLOW`·`NAME-ITEMS` | 정본 | 답 한 번으로 어긴다 |
| `FAIL-LOUD`·`REVERSIBLE`·`SECRETS` | 정본 | 절차와 결정과 프롬프트에서 어긴다 |
| Think Before Acting | 정본 | 묻기와 가정 드러내기는 대화 규칙이다 |
| 검증·미해결의 처분·병렬 오케스트레이션 절 | 정본 | 파일 없이 내리는 절차 결정이다 |
| "사실과 판단은 다르다" 문단 | 정본, 「검증」 끝으로 이동 | 완료 보고는 소통 규칙이다 |
| Simplicity First의 "서브에이전트를 여럿 띄우지 않는다" | 정본, Think Before Acting의 불릿으로 이동 | 호출 결정은 파일 없이 내린다 |
| Simplicity First·Surgical Changes·Goal-Driven Execution | `domain-coding`(코드 문장)과 `domain-writing`(문서 문장) | 산출물이 있어야 어긴다 |
| `EXPLAIN-STRUCTURE`·`EXPLICIT`·`FOCUSED`·`IDEMPOTENT`·`SSOT` | `domain-coding` | 코드가 있어야 어긴다 |
| LOCAL-FIRST 관례 문단 | `domain-coding` | 코드 실행 환경의 관례다 |
| 「문서와 상태의 위생」 첫 문단 | 삭제 | 상세가 이미 `domain-docs`의 「문서 타입과 수명」과 「시작점」에 있다 |

## 정본의 이후 모습

절은 「원칙」·「Think Before Acting」·「검증」·「미해결의 처분」·「병렬 오케스트레이션」·「이 파일의 취급」 여섯이다. 「원칙」에는 조항 여덟이 남는다. 「Karpathy 지침」 겉 제목은 없애고 Think Before Acting이 바로 `##` 절이 된다. 그 절의 본문은 지금과 같고 넷째 불릿에 한 문장이 붙는다.

```
- If a simpler approach exists, say so. Push back when warranted. Don't launch a fleet of subagents for what one call can do.
```

「검증」 끝에 지금 「문서와 상태의 위생」 둘째 문단을 그대로 옮긴다.

```
사실과 판단은 다르다. 훅은 계산으로 확인되는 사실만 기록한다. "완료"는 성공 기준에 비춰 내리는 판단이므로 근거와 함께 사용자에게 알린다.
```

## domain-coding

새 디렉터리 `skills/domain-coding/SKILL.md`이다. 설명문(frontmatter)은 다른 스킬처럼 한국어로 열리는 조건을 적고, 본문은 영어다. 아래가 본문 전문이다. 카파시 세 절은 플러그인 1.0.0의 원문 그대로이며 제목 번호만 뺀다. Goal-Driven Execution 끝의 "Never claim done" 문장은 정본의 `TDD`에서 온 것이다.

~~~markdown
---
name: domain-coding
description: 코드를 쓰거나 고칠 때의 규칙이다. 카파시(Andrej Karpathy) 코딩 지침의 코드용 세 절과, 정본에서 옮겨 온 다섯 원칙(한 가지 일·단일 출처·멱등성·명시성·변경 설명)과 로컬 우선 관례를 담는다. 코드 파일에 세션의 첫 Write나 Edit이 들어오면 훅이 이 스킬을 열라고 알린다. 코드를 구현하는 서브에이전트에도 이 파일 경로를 넘긴다.
---
# domain-coding — rules for writing and changing code

These rules apply whenever code is written or changed. Rules that also hold in plain conversation live in the always-loaded canon and are not repeated here.

## Karpathy guidelines

From `andrej-karpathy-skills` 1.0.0. Think Before Coding lives in the canon as Think Before Acting.

**Tradeoff:** These guidelines bias toward caution over speed. For trivial tasks, use judgment.

### Simplicity First

**Minimum code that solves the problem. Nothing speculative.**

- No features beyond what was asked.
- No abstractions for single-use code.
- No "flexibility" or "configurability" that wasn't requested.
- No error handling for impossible scenarios.
- If you write 200 lines and it could be 50, rewrite it.

Ask yourself: "Would a senior engineer say this is overcomplicated?" If yes, simplify.

### Surgical Changes

**Touch only what you must. Clean up only your own mess.**

When editing existing code:
- Don't "improve" adjacent code, comments, or formatting.
- Don't refactor things that aren't broken.
- Match existing style, even if you'd do it differently.
- If you notice unrelated dead code, mention it - don't delete it.

When your changes create orphans:
- Remove imports/variables/functions that YOUR changes made unused.
- Don't remove pre-existing dead code unless asked.

The test: Every changed line should trace directly to the user's request.

### Goal-Driven Execution

**Define success criteria. Loop until verified.**

Transform tasks into verifiable goals:
- "Add validation" → "Write tests for invalid inputs, then make them pass"
- "Fix the bug" → "Write a test that reproduces it, then make it pass"
- "Refactor X" → "Ensure tests pass before and after"

For multi-step tasks, state a brief plan:
```
1. [Step] → verify: [check]
2. [Step] → verify: [check]
3. [Step] → verify: [check]
```

Strong success criteria let you loop independently. Weak criteria ("make it work") require constant clarification. Never claim "done" without execution evidence.

## Principles

### Do one thing well

"Write programs that do one thing and do it well. Write programs to work together." — Doug McIlroy, Bell System Technical Journal, 1978. "Gather together the things that change for the same reasons. Separate those things that change for different reasons." — Robert C. Martin, *The Single Responsibility Principle*.

A function, a file, a skill, or a subagent does one job. Anything else uses it through its inputs and outputs without reading its internals.

### Single source of truth

"Every piece of knowledge must have a single, unambiguous, authoritative representation within a system." — Andy Hunt and Dave Thomas, *The Pragmatic Programmer* (the DRY principle).

A fact lives in one place. Elsewhere, reference it or derive it. Never copy it.

### Idempotence

"An operation is idempotent if the result of performing it once is exactly the same as the result of performing it repeatedly without any intervening actions." — Ansible glossary.

Scripts and setup check the current state and act only on the difference, so a second run creates no duplicate and no damage.

### Explicit is better than implicit

"Explicit is better than implicit." — Tim Peters, PEP 20, *The Zen of Python*. "Make illegal states unrepresentable." — Yaron Minsky.

Behavior must be visible from names, types, and contracts alone. Context handed to an agent is written into its prompt, never assumed known.

### Describe the change, not the diff

"The rest of the description should fill in the details and include any supplemental information a reader needs to understand the changelist holistically." — Google Engineering Practices, *Writing good CL descriptions*. "Once the problem is established, describe what you are actually doing about it in technical detail." — Linux kernel, *Submitting patches*.

After changing code, report the change in structure: what now calls what, and what now depends on what. The diff already shows the lines.

## Local first

A convention of this environment, not a principle. Run on this machine by default. Use Docker only when production parity is required, when a service must run separately (a database, for example), when something cannot be installed here, or when the user says so.

## Reach

Subagents do not receive this file automatically. When a subagent implements code, put this file's path in its prompt the way `domain-docs`'s 「렌즈에게 정본을 알리는 법」 prescribes for the canon.
~~~

출처 URL은 다음이다. 본문에는 저자와 문서명만 적고 URL은 여기 둔다.

- McIlroy: https://en.wikiquote.org/wiki/Doug_McIlroy
- Martin: https://en.wikipedia.org/wiki/Single-responsibility_principle
- Hunt & Thomas: https://media.pragprog.com/titles/tpp20/dry.pdf
- Ansible glossary: https://docs.ansible.com/ansible/latest/reference_appendices/glossary.html
- PEP 20: https://peps.python.org/pep-0020/
- Minsky: https://fsharpforfunandprofit.com/posts/designing-with-types-making-illegal-states-unrepresentable/
- Google CL descriptions: https://google.github.io/eng-practices/review/developer/cl-descriptions.html
- Linux kernel: https://www.kernel.org/doc/html/latest/process/submitting-patches.html

## domain-writing

새 디렉터리 `skills/domain-writing/SKILL.md`이다. 설명문은 한국어, 본문은 영어다. 문서를 얼마나 쓰고 어디까지 고치며 언제 끝났다고 하는가만 다룬다. 문서의 타입과 수명과 검진은 `domain-docs`가, 한국어 문장 규칙은 `writing-korean`이 그대로 소유한다. 아래가 전문이다.

~~~markdown
---
name: domain-writing
description: 문서를 새로 쓰거나 고칠 때 분량과 수정 범위와 완료 판정의 규칙이다. 카파시(Andrej Karpathy) 코딩 지침 세 절을 문서용으로 고친 것이다. 새 .md를 만들거나 고치면 훅이 이 스킬을 열라고 알린다. 문서의 타입과 수명과 검진은 domain-docs가, 한국어 문장 규칙은 writing-korean이 소유한다.
---
# domain-writing — how much to write, how much to touch, when it is done

Adapted from `andrej-karpathy-skills` 1.0.0. The code wording lives in `domain-coding`; Think Before Acting lives in the canon.

## Simplicity First

The minimum document that solves the problem. Nothing speculative.
- No sections beyond what was asked.
- No templates or generalizations for a single-use document.
- No "flexibility" the reader did not ask for.
- If you write 200 lines and it could be 50, rewrite it.

## Surgical Changes

Touch only what the request needs. Clean up only your own mess.
- Don't "improve" adjacent paragraphs, wording, or formatting.
- Match the existing style, even if you'd write it differently.
- Remove sections and links that your change orphaned.
- Leave pre-existing dead text in place and mention it.

## Goal-Driven Execution

Define what the reader must be able to do after reading. Check the draft against that before calling the document done.
~~~

## 훅

### 코드 넛지

새 파일 `hooks/code_nudge_posttooluse.sh`를 `hooks/hooks.json`의 PostToolUse `Write|Edit` 목록 끝에 붙인다. 기존 넛지와 같은 헬퍼를 쓴다.

- `DISCIPLINED_CODER_REVIEW_GATE=off`이면 조용히 끝난다.
- 경로는 `_extract_path.sh`로 뽑는다. `.md`는 건너뛰고, `path_in_project`가 아니면 건너뛴다. 남는 첫 경로가 대상이다.
- 세션 키는 stdin JSON의 `session_id`다. 표시 파일은 `${TMPDIR:-/tmp}/disciplined-coder/code-nudge-<session_id>`이고, 있으면 조용히 끝나고 없으면 만든 뒤 알린다. `session_id`가 없으면 표시 파일 없이 매번 알린다. 조용히 빠지지 않는다.
- 알림 문장은 하나다. `🧑‍💻 코드 파일(<basename>) 편집 시작 — disciplined-coder domain-coding을 열어 코드 규칙을 읽어라. 이 세션에 한 번만 알린다. 넛지일 뿐 차단은 아니다.`
- 출력 형식은 `doc_review_posttooluse.sh`와 같은 `additionalContext`다.

표시 파일은 임시 폴더에 쌓이고 지우지 않는다. 운영체제가 임시 폴더를 비운다.

### 문서 넛지에 domain-writing을 덧붙인다

새 훅은 두지 않는다. `doc_format_pretooluse.sh`의 새 문서 알림 문장 끝에 "분량은 domain-writing을 따른다"를 덧붙인다. `doc_review_posttooluse.sh`의 수정 알림 문장에도 "고칠 때는 domain-writing의 Surgical Changes대로 지적된 곳만 손댄다"를 덧붙인다. 둘째 덧붙임은 사용자 결정에 없던 것이다. Surgical Changes는 수정 때 걸리는 규칙이라 새 문서 알림만으로는 닿지 않아 더했다. 리뷰에서 빼라고 하면 뺀다.

## 참조 고치기

측정한 목록이다. `docs/superpowers/` 아래 기록은 그때의 사실이라 손대지 않는다.

- `skills/domain-docs/SKILL.md` 29행의 "보편 원칙(Simplicity First·`SSOT`·`FOCUSED`·`READ-FLOW`)"에서 Simplicity First는 `domain-writing`의 절로, `SSOT`·`FOCUSED`는 `domain-coding`의 "Single source of truth"와 "Do one thing well"로 바꾼다. 63행의 `EXPLICIT`은 "Explicit is better than implicit"으로 바꾼다. 34행과 79행의 "(Simplicity First)"는 `domain-writing`의 절을 가리키므로 앞에 `domain-writing`을 붙인다.
- `skills/domain-plugin/SKILL.md` 23행의 "(Simplicity First)"는 `domain-coding`의 절을 가리키므로 앞에 `domain-coding`을 붙인다.
- `skills/domain-spec-review/SKILL.md` 116행의 "(Surgical Changes)"는 spec을 고치는 자리라 앞에 `domain-writing`을 붙인다.
- `skills/lens-adversarial/SKILL.md` 11행의 "(Simplicity First·YAGNI 위반)"은 그대로 둔다. 과설계 판정은 코드와 문서 둘 다에 걸린다.
- `skills/nested-orchestration/SKILL.md` 28행의 방식 항목에 "구현자 프롬프트에는 `domain-coding`의 경로도 넣는다" 한 문장을 더한다.
- `CLAUDE.md` 11행의 "(`SSOT`)"는 "(Single source of truth)"로 바꾼다.
- `README.md`의 「하드 게이트와 넛지와 전역 설정 수정」에서 "넛지 셋"을 "넛지 넷"으로 바꾸고 코드 넛지 항목을 더하며, 새 문서 넛지 항목에 `domain-writing`을 함께 적는다. 「프로젝트 폴더에 생기는 파일」에 정본은 대화 규칙만 갖고 코딩 규칙은 `domain-coding`에, 문서 분량 규칙은 `domain-writing`에 있다는 한 문장을 더한다. 카파시 설치 권유 항목의 마지막 문장은 "정본의 「Think Before Acting」 절과 `domain-coding`·`domain-writing`의 카파시 절은 그 플러그인의 네 절을 옮긴 것이고, 겹치던 조항은 정본에서 뺐다"로 바꾼다.
- `scripts/scaffold.sh`의 카파시 넛지 주석 한 줄도 README와 같은 뜻으로 맞춘다.

`SSOT`라는 낱말을 개념 이름으로 쓰는 스크립트 주석과 스킬 제목은 조항 참조가 아니므로 그대로 둔다. 검사는 백틱으로 감싼 조항 ID 형태만 본다.

## 테스트

`scripts/test_hooks.sh`에 코드 넛지 여섯 경우를 더한다. 프로젝트 안 코드 파일 첫 편집에 `domain-coding`을 담은 알림이 나온다. 같은 `session_id`의 둘째 편집은 빈 출력이다. `.md`는 빈 출력이다. 프로젝트 밖 경로는 빈 출력이다. `DISCIPLINED_CODER_REVIEW_GATE=off`는 빈 출력이다. `session_id`가 없으면 매번 알린다. 문서 넛지 둘의 기존 검사에는 알림 문장이 `domain-writing`을 담는지를 하나씩 더한다.

`scripts/test_scaffold.sh`의 canon-sections 목록을 여섯 절로 맞춘다. karpathy-in-canon 검사는 karpathy-split으로 바꾼다. 정본에는 `## Think Before Acting`이 있고 `### Simplicity First`·`### Surgical Changes`·`### Goal-Driven Execution`은 없다. `domain-coding`에는 그 셋과 원칙 제목 다섯이 있다. `domain-writing`에는 `## ` 절 셋이 있다. 옛 조항 ID 열(먼저 뺀 다섯과 이번 다섯)이 정본에 `**`ID`` 형태로 없고, `skills`·`README.md`·`CLAUDE.md`·`scripts/scaffold.sh`에 백틱 형태로 없다. 정본의 넷째 불릿에 서브에이전트 문장이 있다. 「검증」 절에 "사실과 판단은 다르다"가 있다.

`scripts/test_docs_drift.sh`는 `domain-coding`의 「Reach」 절이 「렌즈에게 정본을 알리는 법」의 첫 항목 문장을 베끼지 않았는지 기존 검사로 잡는다. 새 검사는 두지 않는다.

## 하지 않는 것

- 카파시 플러그인 설치 권유를 빼지 않는다.
- 정본의 한국어 조항 여덟을 영어로 옮기지 않는다.
- `domain-docs`의 기존 절을 다시 쓰지 않는다. 참조 네 곳만 고친다.
- 코드 넛지를 차단으로 만들지 않는다.
- `docs/superpowers/` 아래 옛 spec과 리뷰 기록의 조항 이름을 고치지 않는다.

## 되돌리기

커밋 단위로 되돌린다. 정본 변경과 두 스킬 생성과 참조 수정을 한 커밋에, 훅과 그 테스트를 다른 커밋에 둔다. 앞 커밋만 되돌리면 정본은 `b24fdfa` 상태로 돌아가고, 뒤 커밋만 되돌리면 넛지 없이 스킬 설명문으로만 열리는 상태가 된다.
