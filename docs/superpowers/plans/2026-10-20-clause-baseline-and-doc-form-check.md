# 기준선 정리·문서 형식 검사·퇴고 기준 Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** spec 의 과제 중 API 키 없이 실행할 수 있는 T1(`NAME-ITEMS` 삭제), T6(문서 형식 기계 검사), T9(퇴고 기준과 생성 제약 근거)를 구현한다.

**Architecture:** T1 은 원칙·참고서·평가 자료·드리프트 검사를 함께 고친다. T6 은 정규식 검사기 `hooks/_doc_form_check.py` 를 새로 만들고, 이미 Write·Edit·Bash 에 실행되는 PostToolUse 훅 `hooks/doc_review_posttooluse.sh` 안에서 호출한다. 그래서 훅 프로세스 수는 늘지 않는다. T9 는 저장소 CLAUDE.md 와 `docs/domain-discipline.md` 만 고친다. 나머지 spec 과제(T2~T5, T7, T8, T10)는 API 키가 준비된 뒤 별도 plan 으로 쓴다.

**Tech Stack:** bash 훅, Python 3(인터프리터는 `scripts/_json_valid.sh` 의 `json_run` 이 고른다), 기존 테스트 도우미 `scripts/_test_check.sh` 의 `check`.

**Spec:** `docs/superpowers/specs/2026-10-20-clause-decision-point-design.md`

## Global Constraints

이 plan 의 모든 Task 에 아래 제약을 적용하라.

- worktree `D:\projects\dc-clause-candidates` 의 브랜치 `feat/clause-candidates` 에서만 작업하라.
- 커밋 메시지 끝에 `Co-Authored-By: Claude Opus 5.5 <noreply@anthropic.com>` 를 붙이고, push 하지 마라.
- 새 검사는 경고만 내게 하고 쓰기를 거부하게 하지 마라.
- 새 검사는 스위치 `DISCIPLINED_CODER_REPLY_CHECK=off` 일 때 실행하지 마라.
- 새 검사의 대상은 `.md` 파일 전부로 하되 `docs/superpowers/reviews/` 아래와 Claude 메모리(`*/.claude/projects/*`)는 빼라.
- 펜스 코드 블록, 백틱 안, `>` 인용 줄은 검사하지 마라.
- 금지어는 새 검사에 넣지 말고 기존 금지어 훅은 그대로 두어라.
- 파이썬이 없으면 새 검사를 알림 없이 건너뛰어라(2026-09-30 사용자 결정, `hooks/doc_word_posttooluse.sh` 13행).
- 문서 문장은 한국어 문어체로 쓰고, 에이전트원칙과 지시문의 할 일은 "~하라"로 써라.
- Task 마다 끝에 저장소 CLAUDE.md 「변경 뒤 실행」의 전체 테스트 명령을 실행해 `ALL PASS` 를 확인하라.

## Review Focus

아래 입력은 spec 이 직접 적지 않았지만 사용자가 자주 만날 입력이다. 각 입력의 기대 동작은 Task 2 와 Task 3 의 검사가 고정한다.

| 입력 | 기대 동작 | 고정하는 검사 |
|---|---|---|
| 라벨 뒤 문장이 하나인 불릿 | 경고 없음 | Task 2 `label_one_sentence_ok` |
| 영어 약어가 든 한 문장 라벨 불릿(`e.g.`) | 경고 없음 | Task 2 `label_abbrev_ok` |
| 날짜·버전·'인터넷이' 뒤에 목록 | 경고 없음 | Task 2 `count_substring_ok` |
| 순서를 매긴 제목(`## 1단계 준비`) | 경고 없음 | Task 2 `heading_step_ok` |
| 위반이 많은 기존 문서를 Edit 로 한 줄 고침 | 고친 문자열만 검사하고 보고는 다섯 줄 이하 | Task 3 "Edit 는 new_string 만", "보고 상한" |

---

### Task 1: `NAME-ITEMS` 삭제(T1)

**Files:**
- Modify: `agent-principles.md` (146행 `NAME-ITEMS` 줄 삭제)
- Modify: `docs/domain-korean.md` (`### \`NAME-ITEMS\`` 절을 「삭제한 조항」 아래로 옮김)
- Modify: `scripts/test_docs_drift.sh` (지운 ID 를 나열한 `for id in ...` 목록에 `NAME-ITEMS` 추가, 286행 주석의 `` (`NAME-ITEMS`) `` 를 `` (`SPECIFIC-NAME`) `` 로 변경)
- Delete: `evals/principles/clauses/NAME-ITEMS/`, `evals/principles/cases/q-name-items-1/`, `q-name-items-2/`, `q-name-items-3/`, `q-name-items-f1/`, `q-name-items-f2/`

평가 질문 폴더 `q-name-items-*` 는 `NAME-ITEMS` 시험 단위만 쓰므로 `REPORT-DEAD` 에 따라 함께 지운다. `evals/principles/results/clauses/gen.jsonl`·`judge.jsonl` 의 해당 줄은 지난 실행의 기록이므로 그대로 둔다. `docs/domain-korean.md` 332행의 "`NAME-ITEMS` 도 어겼다"는 당시 사례 기록이므로 그대로 둔다.

**Interfaces:**
- Consumes: 없음
- Produces: 기준선 원칙(이후 plan 의 T3 측정 대상)

- [ ] **Step 1: 되살림 검사가 실패하는지 확인한다**

`scripts/test_docs_drift.sh` 832행의 `for id in ASK-FORK ... LEXICAL-CHAIN; do` 목록 끝에 `NAME-ITEMS` 를 추가하라. 결과 변수 `REVIVED_IDS` 의 초기값(831행 `REVIVED_IDS=""`)은 건드리지 마라. 원칙에 아직 조항이 있으므로 검사가 실패해야 한다.

Run: `bash scripts/test_docs_drift.sh 2>&1 | grep -F '지운 조항 ID'`
Expected: "canon: 지운 조항 ID 가 클린룸 시험 없이 되살아나지 않는다" 가 FAIL

- [ ] **Step 2: 원칙과 참고서를 고친다**

`agent-principles.md` 에서 `- **\`NAME-ITEMS\`**` 로 시작하는 줄을 지워라.

`docs/domain-korean.md` 에서 `### \`NAME-ITEMS\`` 제목부터 다음 `###` 또는 `##` 제목 앞까지를 잘라 내어, 「삭제한 조항」 절 끝에 본문 그대로 붙여라. 「삭제한 조항」 아래의 `###` 제목은 `ref_clause_ids` 가 읽지 않는다. 옮긴 제목 바로 아래에 아래 문단을 넣어라.

```markdown
2026-10-20에 이 조항을 에이전트원칙에서 지웠다. 근거는 2026-10-14 사용자 결정이다. 사용자는 대화에서 "1번 항목"처럼 번호로 가리키는 편이 편하다고 보았다. 그래서 이름으로 가리키라는 문장과 "순서가 없는 목록은 불릿으로 써라"를 함께 지우기로 정했다(커밋 8b4a05a 의 `docs/domain-discipline.md` 403행). 이 결정은 클린룸 시험을 거치지 않았다. 아래 측정 기록은 지우기 전의 근거 절을 그대로 옮긴 것이다. 조항을 다시 넣으려는 세션은 조항 없는 모델이 어기는 질문을 먼저 사용자에게 보여야 한다.
```

286행 주석의 `` (`NAME-ITEMS`) `` 를 `` (`SPECIFIC-NAME`) `` 로 바꿔라.

- [ ] **Step 3: 평가 자료를 지운다**

Run: `git rm -r -q evals/principles/clauses/NAME-ITEMS evals/principles/cases/q-name-items-1 evals/principles/cases/q-name-items-2 evals/principles/cases/q-name-items-3 evals/principles/cases/q-name-items-f1 evals/principles/cases/q-name-items-f2`
Expected: 오류 없이 끝난다. 다섯 질문 폴더는 서로만 짝(`pair`)으로 가리킨다(1↔2, f1↔f2).

- [ ] **Step 4: 전체 테스트를 실행한다**

Run: 저장소 CLAUDE.md 「변경 뒤 실행」의 명령
Expected: `ALL PASS`. 실패하면 `git reset --hard HEAD` 로 이 Task 의 변경을 되돌리고 실패 문구를 보고하라.

- [ ] **Step 5: Commit**

```bash
git add -A agent-principles.md docs/domain-korean.md scripts/test_docs_drift.sh evals/principles
git commit -m "에이전트원칙에서 NAME-ITEMS 를 지운다(2026-10-14 사용자 결정 반영)" -m "Co-Authored-By: Claude Opus 5.5 <noreply@anthropic.com>"
```

### Task 2: 문서 형식 검사기(T6 검사기)

**Files:**
- Create: `hooks/_doc_form_check.py`
- Create: `scripts/test_doc_form.sh`

**Interfaces:**
- Consumes: 없음
- Produces:
  - `check(text: str) -> list[tuple[int, str, str]]` 는 (1부터 센 줄 번호, 종류, 줄 발췌 40자) 목록을 돌려준다. 종류 이름은 `라벨 불릿`, `개수 예고`, `제목 개수` 다.
  - CLI `python _doc_form_check.py --hook [FILE...]` 는 stdin 의 훅 입력 JSON 을 읽는다. `tool_name` 이 `Write` 이면 `tool_input.content` 를, `Edit` 이면 `tool_input.new_string` 을 검사하고 이름표로 `tool_input.file_path` 를 쓴다. 그 밖의 도구이면 인자 FILE 들을 읽어 검사한다.
  - 출력은 위반마다 `이름표:줄: 종류: 발췌` 한 줄이다. 다섯 줄을 넘으면 다섯 줄만 내고 마지막에 `외 N건` 한 줄을 붙인다. 위반이 없으면 아무것도 내지 않는다. 종료 코드는 늘 0 이다.

- [ ] **Step 1: 실패하는 테스트를 쓴다**

`scripts/test_doc_form.sh` 를 다른 `test_*.sh` 와 같은 형식(`. scripts/_test_check.sh`, `check "이름" "조건"`)으로 만들어라. 검사기는 `json_run` 으로 실행하고 입력은 임시 파일로 넘겨라.

| 검사 이름 | 입력 | 기대 |
|---|---|---|
| `label_two_sentences` | `- **금액 필드:** v1은 정수다. v2는 문자열이다.` | `라벨 불릿` 1건 |
| `label_one_sentence_ok` | `- **금액 필드:** v1은 정수다.` | 출력 없음 |
| `label_abbrev_ok` | `- **입력:** 경로(e.g. 절대 경로)를 받는다.` | 출력 없음 |
| `plain_bullet_two_sentences_ok` | `- v1은 정수다. v2는 문자열이다.` | 출력 없음 |
| `count_preview` | `확인할 사항은 세 가지다.` 다음 줄 `- 첫째` | `개수 예고` 1건 |
| `count_substring_ok` | `2026-10-20 개정 사항:` 다음 줄 `- 조항 삭제`, 그리고 `인터넷이 끊겼다.` 다음 줄 `- 재시도` | 출력 없음 |
| `count_in_table_ok` | `\| 항목 \| 세 가지 \|` 다음 줄 `- 첫째` | 출력 없음 |
| `heading_count` | `## 금지사항 넷` | `제목 개수` 1건 |
| `heading_step_ok` | `## 1단계 준비` | 출력 없음 |
| `fenced_code_ignored` | 펜스 안의 `- **a:** b다. c다.` | 출력 없음 |
| `backtick_ignored` | ``- `**a:** b다. c다.` `` | 출력 없음 |
| `quote_ignored` | `> - **a:** b다. c다.` | 출력 없음 |
| `bom_heading` | UTF-8 BOM 뒤 `## 금지사항 넷` | `제목 개수` 1건 |
| `cp949_file` | cp949 로 저장한 `## 금지사항 넷` | `제목 개수` 1건 |
| `cap_five` | 라벨 불릿 위반 일곱 줄 | 위반 다섯 줄과 `외 2건` |
| `hook_edit_new_string` | `--hook` 에 Edit 입력(`new_string` 에 위반 한 줄) | `라벨 불릿` 1건 |

- [ ] **Step 2: 테스트가 실패하는지 확인한다**

Run: `bash scripts/test_doc_form.sh`
Expected: 검사기 파일이 없어 FAIL

- [ ] **Step 3: `hooks/_doc_form_check.py` 를 구현한다**

판정 규칙은 아래와 같다.

펜스(줄 머리 ```` ``` ```` 또는 `~~~`) 사이의 줄과 `>` 로 시작하는 줄은 건너뛰어라. 남은 줄에서는 백틱 쌍 안의 글자를 지운 뒤 판정하라.

`라벨 불릿` 은 `^\s*[-*+]\s+\*\*[^*]+\*\*` 로 시작하고, 라벨 뒤 본문에 한국어 종결 마침표 `(다|요|까)\.` 가 둘 이상인 줄이다. 이 규칙은 spec 의 24% 집계와 같은 대상을 세도록 한국어 종결만 문장 끝으로 본다.

`개수 예고` 는 목록 항목과 표 줄(`|` 로 시작)이 아닌 줄에 적용한다. 그 줄이 `(^|\s)(두|세|네|다섯|여섯|일곱|여덟|아홉|열|[0-9]+)\s*(가지|개|건|항목)(?![가-힣])` 또는 `(^|\s)(둘|셋|넷|다섯)(이다|입니다)` 를 포함하고, 다음의 빈 줄 아닌 줄이 목록 항목(`^\s*([-*+]|[0-9]+\.)\s`)이면 위반이다.

`제목 개수` 는 `^#{1,6}\s` 줄이 `(^|\s)(둘|셋|넷|다섯|여섯)\s*$` 또는 `(두|세|네|다섯|여섯)\s*(가지|개|건)(?![가-힣])` 를 포함하는 경우다. 순서 표시인 `N단계` 는 대상이 아니다.

파일은 `utf-8-sig` 로 읽고, `UnicodeDecodeError` 가 나면 `cp949` 로 다시 읽어라. 둘 다 실패하면 그 파일을 건너뛰어라.

- [ ] **Step 4: 테스트가 통과하는지 확인한다**

Run: `bash scripts/test_doc_form.sh`
Expected: FAIL 0

- [ ] **Step 5: 전체 테스트를 실행하고 Commit**

Run: 저장소 CLAUDE.md 「변경 뒤 실행」의 명령
Expected: `ALL PASS`

```bash
git add hooks/_doc_form_check.py scripts/test_doc_form.sh
git commit -m "문서 형식 정규식 검사기(라벨 불릿·개수 예고·제목 개수)를 추가한다" -m "Co-Authored-By: Claude Opus 5.5 <noreply@anthropic.com>"
```

### Task 3: 훅 연결(T6 연결)

**Files:**
- Modify: `hooks/_spec_marker.sh` (함수 `path_is_form_target` 추가)
- Modify: `hooks/doc_review_posttooluse.sh` (형식 검사 호출, 스위치 처리 순서)
- Modify: `scripts/test_hooks.sh` (아래 검사 추가)
- Modify: `skills/domain-plugin/SKILL.md` (35행 전제 문장과 측정값)
- Modify: `README.md` (훅 표의 `doc_review_posttooluse.sh` 행, 스위치 설명의 `DISCIPLINED_CODER_REPLY_CHECK` 줄)

spec 은 README 갱신을 T10 에 두었으나, 훅 동작과 그 설명이 어긋나는 기간을 없애려고 이 Task 로 당긴다. 후속 plan 의 T10 에서는 README 의 이 부분을 다시 고치지 않는다. `hooks/hooks.json` 과 `hooks/doc_word_posttooluse.sh` 는 바꾸지 않는다.

**Interfaces:**
- Consumes: Task 2 의 CLI `_doc_form_check.py --hook [FILE...]`
- Produces: `path_is_form_target FILE` 은 `.md` 이고 `path_is_review_record` 가 아니며 `*/.claude/projects/*` 가 아니면 0 을 돌려준다. 훅 출력은 기존과 같은 `{"hookSpecificOutput":{"hookEventName":"PostToolUse","additionalContext":...}}` 하나다.

- [ ] **Step 1: 실패하는 테스트를 쓴다**

`scripts/test_hooks.sh` 의 기존 도우미 `J`(Write 입력)·`JB`(Bash 입력)와 `$DREV` 를 써서 아래 검사를 추가하라. Edit 입력은 `{"tool_name":"Edit","tool_input":{"file_path":"<경로>","new_string":"<문자열>"}}` 이다. 파일은 미리 임시 폴더에 써 두어라.

| 검사 이름 | 상황 | 기대 |
|---|---|---|
| Write 라벨 불릿 → 형식 경고 | 라벨 불릿 두 문장이 든 `x.md` 를 Write | 출력에 `라벨 불릿` |
| Bash 라벨 불릿 → 형식 경고 | 같은 파일을 `sed -i` 로 고친 Bash 입력 | 출력에 `라벨 불릿` |
| Edit 는 new_string 만 | 위반이 든 파일을 위반 없는 `new_string` 으로 Edit | 출력에 `라벨 불릿` 이 없다 |
| 보고 상한 | 위반 일곱 줄이 든 파일을 Write | 출력에 `외 2건` |
| 위반 없음 → 형식 경고 없음 | 한 문장 불릿만 든 `.md` | 출력에 `라벨 불릿`·`개수 예고`·`제목 개수` 가 없다 |
| 코드 블록 → 형식 경고 없음 | 펜스 안에만 라벨 불릿이 든 `.md` | 출력에 `라벨 불릿` 이 없다 |
| 리뷰 기록 → 형식 경고 없음 | `docs/superpowers/reviews/x.md` 에 라벨 불릿 | 출력에 `라벨 불릿` 이 없다 |
| `.txt` → 형식 경고 없음 | 라벨 불릿이 든 `x.txt` | 출력에 `라벨 불릿` 이 없다 |
| 스위치 OFF → 형식 경고 없음 | `DISCIPLINED_CODER_REPLY_CHECK=off` | 출력에 `라벨 불릿` 이 없다 |
| 검진 게이트 OFF 에도 형식 경고 | `DISCIPLINED_CODER_REVIEW_GATE=off` 와 라벨 불릿 | 출력에 `라벨 불릿` |
| 파이썬 없음 → 오류 없음 | `PATH` 에서 파이썬을 뺀 환경 | 종료 코드 0 |

기존 검사 "셸 편집 → 검진 넛지"(267행)와 "셸 읽기 → 검진 넛지 없음"(268행)은 그대로 통과해야 한다.

- [ ] **Step 2: 테스트가 실패하는지 확인한다**

Run: `bash scripts/test_hooks.sh 2>&1 | grep FAIL`
Expected: 형식 경고를 기대하는 새 검사가 FAIL

- [ ] **Step 3: `path_is_form_target` 을 추가한다**

`hooks/_spec_marker.sh` 에 Interfaces 의 규칙대로 함수를 추가하라.

- [ ] **Step 4: 검진 훅에 형식 검사를 넣는다**

`hooks/doc_review_posttooluse.sh` 8행의 `DISCIPLINED_CODER_REVIEW_GATE` 조기 종료를 지우고, 그 판정을 검진 넛지를 만드는 곳으로 옮겨라. 그래야 검진 게이트를 꺼도 형식 검사는 실행된다.

`TARGETS` 를 구한 직후에 형식 검사를 실행하라. 조건은 `DISCIPLINED_CODER_REPLY_CHECK` 가 `off` 가 아니고, `TARGETS` 중 `path_is_form_target` 을 통과하며 실제로 있는 파일이 하나 이상인 경우다. 호출은 `printf '%s' "$INPUT" | json_run ... _doc_form_check.py --hook <그 파일들>` 한 번이고, 실패하면 `|| true` 로 넘어가라.

형식 보고가 있으면 아래 문구 뒤에 보고 줄을 붙이고, 검진 넛지가 있으면 그 뒤에 이어 한 `additionalContext` 로 내라.

```text
disciplined-coder 문서 형식 경고다. 쓰기는 막지 않았다. 아래 줄을 전달 전에 고쳐라. 라벨 불릿은 굵은 라벨 뒤에 문장이 둘 이상인 불릿이며, 산문 문단으로 바꿔라. 개수 예고는 목록 바로 앞 문장이 목록의 개수를 말하는 것이며, 그 개수를 지워라. 제목 개수는 제목에 붙은 개수이며, 제목에서 지우고 필요하면 본문 문장에 적어라. 코드 블록·백틱·인용 줄은 검사하지 않았다.
```

- [ ] **Step 5: 테스트가 통과하는지 확인한다**

Run: `bash scripts/test_hooks.sh 2>&1 | grep -c FAIL`
Expected: `0`

- [ ] **Step 6: 실행 시간을 기록한다**

아래 세 입력을 `hooks/doc_review_posttooluse.sh` 에 각각 10번 넣어 평균 시간을 재라. 바꾸기 전 커밋(`git stash` 로 이 Task 변경을 잠시 치운 상태)에서도 같은 세 입력을 재어 차이를 구하라.

- `.py` 파일을 Write 한 입력
- 위반 없는 `.md` 를 Write 한 입력
- 위반 다섯 줄이 든 `.md` 를 Write 한 입력

Expected: 여섯 값이 기록된다. 이 값은 Step 7 의 문서에 적는다.

- [ ] **Step 7: 문서를 고친다**

`skills/domain-plugin/SKILL.md` 35행의 "Stop 훅은 방금 쓴 답을 인자로 받지 않는다"를 "Stop 훅은 `last_assistant_message` 로 마지막 답을 받는다(2026-10-20 공식 문서 확인). 그러나 이미 나간 답은 고칠 수 없고 도구 호출 사이의 중간 답은 받지 못한다"로 바꿔라. 그 항목의 결론(답을 검사하는 Stop 훅을 만들지 않는다)은 그대로 두어라. 같은 절 표 아래에 Step 6 의 측정값을 한 문장으로 적어라.

`README.md` 「하드 게이트와 넛지와 전역 설정 수정」 절의 `doc_review_posttooluse.sh` 행에 "Write·Edit·Bash 로 쓴 `.md` 의 형식(라벨 불릿·개수 예고·제목 개수)을 경고한다"를 덧붙여라. 같은 README 의 `DISCIPLINED_CODER_REPLY_CHECK=off` 설명에 "문서 형식 경고도 끈다"를 덧붙여라.

- [ ] **Step 8: 전체 테스트를 실행하고 Commit**

Run: 저장소 CLAUDE.md 「변경 뒤 실행」의 명령, 그다음 `claude plugin validate ./`
Expected: `ALL PASS`, `Validation passed`

```bash
git add hooks/_spec_marker.sh hooks/doc_review_posttooluse.sh scripts/test_hooks.sh skills/domain-plugin/SKILL.md README.md
git commit -m "문서 형식 검사를 검진 PostToolUse 훅에 연결한다" -m "Co-Authored-By: Claude Opus 5.5 <noreply@anthropic.com>"
```

### Task 4: 퇴고 기준과 생성 제약 근거(T9)

**Files:**
- Modify: `CLAUDE.md` (「에이전트원칙을 고칠 때」의 퇴고 기준 목록)
- Modify: `docs/domain-discipline.md` (「삭제한 조항」 앞에 `## 생성 제약` 절 추가)

**Interfaces:**
- Consumes: spec 의 「생성 제약」 표
- Produces: 없음

- [ ] **Step 1: CLAUDE.md 를 고친다**

퇴고 기준 목록 끝에 아래 항목을 추가하라. 항목마다 라벨 뒤 문장을 하나로 두어 Task 3 의 형식 경고를 받지 않게 하라. 근거 포인터 문장("근거와 사례는 …에 있다")에는 `docs/domain-discipline.md` 「생성 제약」을 함께 적어라.

```markdown
  - **결정점:** 생성 중에 지킬 조항이면 문장이나 항목을 시작하기 전에 정할 일을 지시하고, 다 쓴 뒤에야 판정할 수 있는 조항이면 재작성할 수 있는 층이나 기계 검사에 두었는가.
  - **습관 반대 조항:** 모델의 기본 습관과 반대되는 조항이면 피할 형태를 정의하고 원하는 형태를 함께 주는가.
```

- [ ] **Step 2: `docs/domain-discipline.md` 에 「생성 제약」 절을 추가한다**

「삭제한 조항」 바로 앞에 `## 생성 제약` 절을 두어라. 내용은 spec 「생성 제약」 표 전체, 「이 기준을 둘 위치」의 둘째 문단, 그리고 아래 집계 문단이다. 이 절 안에 `### \`ID\`` 형태의 제목을 쓰지 마라. `ref_clause_ids` 가 그 형태를 조항 ID 로 읽기 때문이다.

```markdown
**실사용 답의 라벨 불릿 집계(2026-10-20).** 2026-10-20 세션이 이 PC의 Claude Code 세션 기록 59개에서 assistant 답 1,851개를 뽑았다. 그 세션은 굵은 라벨 뒤에 한국어 종결 문장이 둘 이상 오는 줄을 정규식 `^\s*[-*] \*\*[^*]+\*\*[^\n]*?[다요]\. [^\n]*[다요]\.` 로 찾았다. 이런 줄이 하나 이상 든 답은 약 445개(24%)였다. 집계 스크립트는 그 세션의 임시 폴더에만 있었고, 그 세션은 스크립트를 저장소에 남기지 않았다. 그래서 이 수치는 다시 계산할 수 없는 관찰값이다.
```

- [ ] **Step 3: 전체 테스트를 실행한다**

Run: 저장소 CLAUDE.md 「변경 뒤 실행」의 명령
Expected: `ALL PASS`

- [ ] **Step 4: Commit**

```bash
git add CLAUDE.md docs/domain-discipline.md
git commit -m "퇴고 기준에 결정점·습관 반대 조항 질문을 추가하고 생성 제약 근거를 적는다" -m "Co-Authored-By: Claude Opus 5.5 <noreply@anthropic.com>"
```

## 이 plan 밖에 남는 과제

spec 의 T2·T3·T4·T5·T7·T8·T10 은 API 키(`~/.dc-eval.env`)가 준비된 뒤 별도 plan 으로 쓴다. T10 의 main 병합도 그 plan 의 마지막 Task 다.

<!-- spec-review: passed -->
