# 에이전트원칙 긍정형 재작성 Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** 실패 평가 세트와 조항 파일을 만들고, 조항마다 따로 클린룸 시험으로 문안을 채택한 뒤, 채택한 문안으로 `agent-principles.md` 를 출력 종류별 층과 결정 규칙 형식으로 다시 쓴다.

**Architecture:** 평가 세트(`evals/principles/`)와 실행·비교 스크립트를 먼저 만든다(Task 0~3). 조항마다 현행 문안과 변경안을 조항 파일로 두고, 조항마다 질문을 늘려 조항 없음·현행 문안·변경안 조건을 한 번씩 실행한다. 채택한 문안을 한 커밋으로 적용하고, 금지어는 목록 단위로 시험해 지시형 트랙으로 바꾼다. 마지막에 main 을 가져와 최종안과 기준 원칙을 평가 세트 전체로 비교하고 병합 승인을 받는다.

**Tech Stack:** bash, awk, Python(기존 `json_run` 헬퍼), Claude Code CLI(이 PC 에서 `claude --version` 은 2.1.302 를 낸다). 실행 도구는 `claude -p` 다(Task 1 결과).

**Spec:** `docs/superpowers/specs/2026-10-18-principles-positive-restructure-design.md`

## 용어

| 이름 | 뜻 |
|---|---|
| 조건 | 측정 대상인 원칙 상태 하나다. 클린룸 시험에서는 조항 없음(`none`)·현행 문안(`current`)·변경안(`new`) 중 하나이고, 전체 비교에서는 커밋 하나(라벨 `baseline`, `final`)다 |
| 조항 파일 | `evals/principles/clauses/<조항 ID>/current.md` 와 `new.md` 다. 클린룸 세션의 `CLAUDE.md` 로 그대로 들어간다 |
| 생성 키 | 클린룸 생성 한 건을 가리키는 값이다. 과제 본문(front matter 를 뺀 `prompt.md`)의 해시와 조건 파일 내용의 해시(조항 없음은 빈 문자열의 해시)를 이은 값이다 |
| 판정 키 | 판정 한 건을 가리키는 값이다. 생성 키와 `criteria.md` 해시를 이은 값이다. 판정 기준을 고치면 판정만 다시 한다 |
| 시험 단위 | 클린룸 시험에서 한 번에 비교하는 문안이다. 조항 하나이거나 현행 조항 하나를 둘로 나눈 쌍이다 |
| 평가 설정 폴더 | 조건마다 새로 만드는 빈 `CLAUDE_CONFIG_DIR` 폴더다. 실제 `~/.claude` 와 따로 있고, 측정이 끝나면 지운다 |
| 예열 세션 | 전체 비교에서 평가 설정 폴더를 만든 뒤 판정하지 않고 한 번 실행하는 세션이다. scaffold 가 관리블록과 원칙 사본을 만들게 해서, 판정하는 모든 세션이 같은 `@import` 경로로 원칙을 싣게 한다 |
| 지시형 트랙 | 금지어 표의 상황 칸과 대체어 칸으로 만든 '어떤 상황에서 어떤 말을 써라' 파일(`korean-word-guide.md`)이다. 금지어를 적지 않는다 |
| 판정 모델 | 평가 응답이 기대 행동을 지켰는지 판정하는 Claude 모델이다. 생성 모델과 크기가 다르다 |
| 설정 지문 | 실제 설정 파일(`~/.claude/CLAUDE.md`, `~/.claude/disciplined-coder/*.md`, `~/.claude/settings.json`, `~/.claude/plugins/known_marketplaces.json`, `~/.claude/plugins/installed_plugins.json`)의 해시 목록이다 |

## Global Constraints

기준 원칙은 커밋 `7a2d26d` 의 `agent-principles.md` 다. 같은 질문을 같은 조건으로 두 번 실행하지 않는다(2026-10-18 사용자 지시, 이후 시험에도 적용). 클린룸 시험의 질문에는 개발용 과제만 쓰고, 보류용 과제는 Task 10 의 전체 비교에서만 쓴다.

시험 단위의 판정은 spec 「조항별 클린룸 시험」과 Task 4 의 보고 판정 규칙을 따른다. 문구 변경(나눈 쌍과 금지어 목록 포함)은 `current` 와, 새 조항(`INSTRUCTION-FORM`)은 `none` 과 비교한다. 동률이면 새 질문 짝을 한 번만 추가한다. 판단 조항이 기각되면 금지형으로 되돌리지 않고 사용자에게 묻는다. 그 밖의 판정은 묻지 않는다.

판단 조항은 "상황 → 행동 → 멈출 조건. 이유 한 줄." 형식으로 쓴다. 상황과 멈출 조건은 사용자 메시지, 도구 결과, 파일 상태, 횟수처럼 관찰할 수 있는 사건으로 쓴다. 불변 조건은 "~하지 마라. 이유 한 줄." 형식으로 쓰고 강조어는 쓰지 않는다.

조항 ID 는 유지한다. 조항을 나누면 원래 ID 는 판단 조항이나 주된 쪽에 남기고, 나눈 쪽에 새 ID 를 붙인다. 새 ID 는 `docs/domain-discipline.md` 와, 원래 ID 를 가리키는 원칙 안 문장에 같은 커밋에서 반영한다.

평가 과제에는 업무 수치, 종목, 키, 사람 이름, 회사명, 사용자 메시지 원문을 넣지 않는다. 평가 세션은 평가 설정 폴더와 git 이 아닌 빈 작업 폴더에서 도구를 끄고 실행하며, 실제 설정 파일을 쓰지 않는다. 평가 명령은 `CLAUDE_HOME_DIR` 을 비운 셸에서 실행한다. `scripts/_resolve_home.sh` 가 이 변수를 `CLAUDE_CONFIG_DIR` 보다 먼저 보기 때문이다. 측정 뒤 설정 지문이 달라졌으면 구현자는 파일을 되돌리지 않고 멈춰서, 바뀐 파일 목록을 사용자에게 보이고 처리를 묻는다. 다른 창의 정상 변경을 덮어쓰지 않기 위해서다. API 키는 `~/.dc-eval.env` 에서 환경 변수로만 넘기고 출력하거나 다른 파일에 쓰지 않는다.

다른 세션의 작업 중인 브랜치와 worktree 는 읽지 않는다. 대조는 메시지나 main 에 병합된 커밋으로만 한다. 고친 것이 있으면 저장소 검사(CLAUDE.md 「변경 뒤 실행」의 병렬 명령)와 `claude plugin validate ./` 를 실행한다. 계약은 FAIL=0 과 `Validation passed` 다. 커밋 메시지는 `Co-Authored-By: Claude Opus 5.5 (1M context) <noreply@anthropic.com>` 로 끝낸다.

## Review Focus

- **같은 질문의 재실행** — 스크립트를 다시 실행하거나 끊긴 실행을 이어 갈 때 같은 질문이 같은 조건으로 다시 실행되면 사용자 지시를 어긴다. 실행 스크립트는 생성 키가 기록에 있으면 생성하지 않고, 판정 키만 없으면 판정만 한다. Task 4 가 이를 시험한다.
- **조건 혼선** — 클린룸 세션에 다른 조항이나 사용자 전역 지시가 실리면 조항 하나의 효과를 측정하지 못한다. 실행 스크립트는 조건마다 새 평가 설정 폴더에 그 조항 파일만 `CLAUDE.md` 로 넣는다. Task 4 가 폴더 내용을 시험한다.
- **현행 문안의 옮김 오류** — `current.md` 가 기준 원칙과 다르면 현행 조건이 기준 원칙을 측정하지 않는다. `scripts/test_eval_cases.sh` 가 `current.md` 의 모든 줄이 `git show 7a2d26d:agent-principles.md` 에 그대로 있는지 본다.
- **상위 경로의 지시 적재** — 작업 폴더가 사용자 홈 아래면 상위 경로의 `~/.claude/CLAUDE.md` 가 실린다(2026-10-18 측정). 실행 스크립트는 상위 경로에 `CLAUDE.md` 가 있으면 실행하지 않는다. Task 4 가 이를 시험한다.
- **실제 설정 오염** — 평가 세션이 실제 설정 파일을 고치면 이 PC 의 모든 세션이 바뀐다. 실행 스크립트는 측정 전후의 설정 지문을 대조하고, 다르면 멈추고 묻는다.
- **판정 모델의 한국어 오판** — 판정 모델이 문체 위반을 놓치면 점수가 개선으로 보인다. 구현자는 판정 10건 안팎을 사용자에게 보여 일치도를 기록한다.

---

### Task 0: 원자료 보관

세션 기록은 정리 기한(`cleanupPeriodDays`, 기본 30일)이 지나면 지워지므로 가장 먼저 한다.

**Files:**
- Create: `~/dc-eval-raw/2026-10-18/report-1.md` … `report-6.md`(저장소 밖이며 커밋하지 않는다)

- [ ] **Step 1:** spec 이 가리키는 세션 기록 파일에서 분석 서브에이전트 보고 여섯 건을 찾아 위 파일로 옮긴다. scratchpad 의 `session-log-synthesis.md` 가 남아 있으면 같은 폴더에 복사한다.
- [ ] **Step 2:** 확인: `ls ~/dc-eval-raw/2026-10-18/` 이 보고 파일을 모두 내고, 각 파일이 비어 있지 않다.

### Task 1: 실행 도구 시험과 선택

**Files:**
- Create: `evals/principles/README.md`(「실행 도구」 절)

**Interfaces:**
- Produces: README 「실행 도구」 절에 아래 값을 적는다. Task 2 와 Task 3 이 이 값을 읽는다.
  - 선택값(`plugin-eval` 또는 `claude-p`)
  - eval 폴더의 위치(대상 플러그인 기준 상대 경로)
  - 과제 머리(태그·종류 필드)를 두는 파일(`case.yaml` 또는 `prompt.md` 머리)
  - 생성 모델과 판정 모델의 이름, 판정 실행 방법
  - 예열 세션 한 번과 과제 한 번의 실행 시간

- [ ] **Step 1:** `claude plugin eval --help` 와 `claude plugin eval init --help` 로 `--eval-dir` 의 기준 경로, `--tag` 가 태그를 읽는 파일, `--case`·`--ablation`·`--no-publish`·`--json`·`--model`·`--judge-model` 플래그를 확인해 README 에 적는다. 2.1.302 의 도움말은 판정 모델 기본값을 haiku 로 적는다.
- [ ] **Step 2:** 설정 지문을 scratchpad 에 기록한다.
- [ ] **Step 3:** `git worktree add --detach <임시 폴더> HEAD` 로 시험용 worktree 를 만든다. 그 worktree 의 `agent-principles.md` 끝에 "응답 첫 줄에 PROBE-A 를 적어라." 를 추가하고, 시험용 probe 과제(아무 질문 하나, 판정자는 응답 첫 줄이 `PROBE-A` 인지 본다)를 그 worktree 의 eval 폴더에 둔다. 두 변경 모두 시험용 worktree 에만 두고 이 브랜치에 커밋하지 않는다.
- [ ] **Step 4:** 그 worktree 를 대상으로 `claude plugin eval` 을 `--runs 1 --ablation none --no-publish --trust-plugin` 으로 실행한다. 아래 확인 결과를 README 에 적는다.
  - 설정 홈: 평가 세션이 실제 `~/.claude` 가 아닌 별도 설정 폴더를 쓴다. 실제 `~/.claude` 를 쓰면 다른 창과 사본을 다투므로 이 경로를 실패로 본다.
  - 원칙 적재: probe 판정이 통과한다.
  - 격리: 설정 지문이 Step 2 와 같다.
  - 조건 구분: 표지를 `PROBE-B` 로 바꾼 둘째 worktree 를 같은 명령으로 실행하면 판정이 B 로 바뀐다.
- [ ] **Step 5:** 위 확인이 모두 통과하면 `plugin-eval` 을 고른다. 하나라도 실패하면 같은 확인을 `claude-p` 경로로 반복한다. 이 경로의 준비는 아래와 같다.
  - 조건마다 빈 평가 설정 폴더를 새로 만든다.
  - `CLAUDE_CONFIG_DIR=<평가 설정 폴더>` 를 `claude plugin marketplace add <worktree>`, `claude plugin install disciplined-coder@chshin-tools`, `claude -p` 세 명령에 모두 붙인다.
  - 첫 세션 전에 그 폴더의 `plugins/known_marketplaces.json` 에서 chshin-tools 의 `autoUpdate` 를 `false` 로 둔다.
  - 예열 세션을 한 번 실행한다.
  - 판정은 `claude -p --model <판정 모델>` 에 과제의 판정 기준과 응답을 넣어 실행한다.

  로그인 오류가 나면 멈추고 사용자에게 인증 방법을 묻는다. 두 경로 모두 실패하면 멈추고 원인을 알린다.
- [ ] **Step 6:** 시험용 worktree 를 `git worktree remove --force` 로 지우고 평가 설정 폴더도 지운다. 실패한 시도와 그 이유를 README 에 적은 뒤 커밋한다. `git add evals/principles/README.md && git commit -m "평가 세트: 실행 도구 시험과 선택"`

### Task 2: 평가 과제 일반화

**Files:**
- Create: `evals/principles/cases/<과제 이름>/`(Task 1 이 정한 형식. 30~50개)
- Create: `scripts/test_eval_cases.sh`
- Modify: `evals/principles/README.md`(「과제 구성」 절: 출력 종류별·실패 유형별 개수와 개발용·보류용 개수)

**Interfaces:**
- Produces: 과제 머리에 아래 필드를 둔다. Task 3 의 비교 스크립트가 이 필드를 읽는다.
  - `tags`: `dev` 또는 `holdout` 하나
  - `kind`: `should`(행동이 일어나야 함) 또는 `should-not`
  - `pair`: 같은 상황의 짝 과제 이름
  - `type`: 출력 종류(`chat`, `tool`, `workdoc`, `deliverable`, `code`)
  - `failure`: 실패 유형(`language`, `confirm-loop`, `exclusion`, `format`), 충돌 쌍(`conflict:<이름>`), 후보 공백(`candidate:<이름>`) 중 하나 이상
  - `clause`: 이 과제가 겨누는 조항 ID 목록

- [ ] **Step 1: 실패하는 검사를 쓴다.** `scripts/test_eval_cases.sh` 는 `scripts/_test_check.sh` 의 `check` 로 아래를 확인한다. 개수와 비율은 검사하지 않고 README 「과제 구성」 에 기록만 한다.
  - 모든 과제에 위 필드가 있고 `tags` 값이 `dev`·`holdout` 중 하나다.
  - 모든 `pair` 가 존재하는 과제를 가리키고, 짝의 `kind` 가 서로 다르다.
  - `sk-`·`AKIA`·`ghp_` 로 시작하는 문자열, 메일 주소 형태, 사용자 PC 경로(`C:\Users\`, `/c/Users/`)가 없다.
- [ ] **Step 2:** `bash scripts/test_eval_cases.sh` 가 FAIL 을 낸다.
- [ ] **Step 3:** Task 0 의 보고에서 과제를 뽑아 일반화한다. 과제마다 상황, 기대 행동, 판정 기준을 적는다. 출력 종류별 개수는 세션 기록의 비율(대화 답 140, 도구 실행 중 판단 84, 작업 문서 32, 산출물 27, 코드 20)을 따르고, 대화 중 만든 산출물 과제를 넣는다. 실패 유형, 충돌 쌍, 후보 공백이 개발용과 보류용에 모두 들게 나눈다.
- [ ] **Step 4:** 여러 턴 과제는 `prompt.md` 안에 앞 턴의 사용자 메시지와 Claude 응답을 일반화한 고정 문장으로 인용하고, 마지막 사용자 메시지 하나에 대한 응답만 판정하게 쓴다. 과제에 필요한 메모리 내용도 일반화해 같은 인용 안에 적는다. 그러면 모든 조건이 같은 맥락을 받는다.
- [ ] **Step 5:** `bash scripts/test_eval_cases.sh` 가 FAIL=0 이고 저장소 검사도 통과한다.
- [ ] **Step 6:** 과제 목록과 각 과제의 `prompt.md` 를 사용자에게 보여, 이름·회사명·수치·원문이 남지 않았는지 확인받는다. 사용자가 지적한 과제를 고친 뒤 커밋한다. `git add evals/principles scripts/test_eval_cases.sh && git commit -m "평가 세트: 세션 기록의 실패에서 일반화한 과제"`

### Task 3: 실행·비교 스크립트

**Files:**
- Create: `scripts/eval_principles.sh`, `scripts/eval_compare.sh`
- Modify: `scripts/test_eval_cases.sh`(비교 스크립트 픽스처 시험)

**Interfaces:**
- Consumes: Task 1 의 README 값과 Task 2 의 과제 머리.
- Produces:
  - `scripts/eval_principles.sh <커밋> <태그> <라벨>` 은 아래 순서로 실행한다. 결과는 `evals/principles/results/<라벨>/result.json` 에 쓴다.
    1. 시작할 때 앞 실행이 남긴 worktree 등록과 임시 폴더를 `git worktree prune` 과 삭제로 정리하고, 설정 지문을 기록한다.
    2. 그 커밋의 detached worktree 를 만들고, 현재 브랜치 HEAD 의 `evals/principles/cases` 를 그 worktree 의 eval 폴더로 복사한다.
    3. 새 평가 설정 폴더와 원격을 지운 복제 저장소를 만들고, 예열 세션을 실행한다.
    4. 조건 대조를 한다(아래 Step 3).
    5. 태그에 맞는 과제를 실행하고 판정한다(Task 3 에서는 3회였고 Task 4 가 1회로 바꾼다).
    6. 정리 단계에서 `git worktree remove --force`, 임시 폴더 삭제, 설정 지문 대조를 한다. 정리 단계는 `trap` 으로 끊길 때도 실행하고, 지문이 다르면 종료 코드 1 과 바뀐 파일 목록을 낸다.
  - `result.json` 은 실행 한 건마다 `case`(과제 이름), `run`(1~3), `violated`(참·거짓), `response`(응답 본문), `judge_note`(판정 이유)를 담은 배열이고, 머리에 `commit`, `tag`, `model`, `judge_model`, `loaded_lines`, `loaded_chars` 를 둔다. `loaded_lines`·`loaded_chars` 는 예열 세션 뒤 관리블록이 싣는 파일 전체의 줄 수와 글자 수다.
  - `scripts/eval_compare.sh <라벨>` 은 그 라벨 하나의 위반 합계, 금지어 횟수, `loaded_lines`·`loaded_chars` 를 한 줄로 낸다. 측정 기록의 행은 이 출력으로 채운다.
  - `scripts/eval_compare.sh <라벨 A> <라벨 B>` 는 첫 줄에 `A=<위반 합계> B=<위반 합계> 판정=<개선|동률|악화>` 를 낸다. 판정은 B 를 A 와 비교한 결과다. 둘째 줄부터는 `kind`·`type`·`failure`·`clause` 값마다 A 와 B 의 위반 수를 내고, `conflict:*` 를 합친 `conflict` 행도 낸다. 마지막 줄에는 `type: chat` 응답의 금지어 출현 횟수를 `금지어 A=<수> B=<수>` 로 낸다.

- [ ] **Step 1: 실패하는 시험을 쓴다.** 픽스처 결과 JSON 으로 아래를 확인한다.
  - 위반 합계가 5 와 3 이면 첫 줄이 `판정=개선`, 같으면 `판정=동률`, 3 과 5 면 `판정=악화` 다.
  - `failure: confirm-loop` 행과 `kind: should` 행이 그 값의 위반 수를 내고, `conflict:a`·`conflict:b` 과제의 위반이 `conflict` 행에 합쳐진다.
  - 금지어 횟수는 같은 낱말이 한 응답에 두 번 나오면 2 로 세고, 제외어 안의 글자는 세지 않는다. 횟수는 `banned_parse` 가 낸 pairs·excl 파일로 센다.
  - 라벨 하나를 주면 위반 합계와 금지어 횟수를 한 줄로 낸다.
- [ ] **Step 2:** 시험이 FAIL 을 낸다.
- [ ] **Step 3:** 두 스크립트를 구현한다. 실행 스크립트의 조건 대조는 예열 세션 뒤 평가 설정 폴더에서 아래를 확인하고, 하나라도 다르면 측정하지 않고 종료 코드 1 로 끝낸다.
  - `disciplined-coder/agent-principles.md` 의 해시가 `git show <커밋>:agent-principles.md` 의 해시와 같다.
  - 관리블록의 `@import` 줄이 가리키는 파일이 모두 있다.
  - 그 커밋에 `banned_guide` 가 있으면 `disciplined-coder/korean-word-guide.md` 가 있고, `korean-banned-words.md` 는 없다.
- [ ] **Step 4:** 시험이 FAIL=0 이다. 그다음 커밋한다. `git commit -m "평가 세트: 실행과 비교 스크립트"`

### Task 4: 클린룸 실행과 보고 스크립트

같은 질문을 반복하지 않는 시험 방법(2026-10-18 사용자 지시)에 맞춰 Task 3 의 반복 3회를 없애고 클린룸 경로를 추가한다.

**Files:**
- Create: `scripts/eval_clause.sh`, `scripts/eval_clause_report.sh`, `scripts/_eval_clause.py`
- Modify: `scripts/_eval_run.py`(반복 제거, 생성과 판정 분리, 오류 판별), `scripts/eval_principles.sh`(태그 `all`, 작업 폴더 위치 검사), `scripts/_eval_lib.py`(`pair` 선택 필드, 비교의 `tags` 행), `scripts/test_eval_cases.sh`, `evals/principles/README.md`(「실행 도구」에 클린룸 경로와 상위 경로 측정)

**Interfaces:**
- Consumes: Task 2 의 과제 머리, Task 3 의 `parse_judge`·`load_cases`·`banned_count`.
- Produces:
  - `_eval_run.py` 의 `generate(prompt, cwd, env) -> dict` 는 생성 한 번을 실행해 `response`, `model`, `error` 를 돌려준다. `claude -p` 출력의 `is_error` 가 참이거나 `result` 가 비면 `error` 를 채운다. `judge(prompt, criteria, response, cwd, env) -> dict` 는 판정 한 번을 실행해 `violated`(참·거짓, 읽지 못하면 `None`), `judge_note`, `judge_model` 을 돌려준다. 생성 모델은 `claude-opus-5-5`, 판정 모델은 `haiku` 로 고정하고, 동시 실행 수는 기존 값 4 를 쓴다. 전체 비교의 `result.json` 은 머리 필드와 `runs` 배열을 유지하고, 배열은 과제마다 한 건이며 `run` 필드가 없다. 판정을 읽지 못한 건은 `violated: null` 로 쓴다.
  - `_eval_clause.py` 의 `make_cfg(path, text)` 는 빈 폴더를 만들고 `text` 가 비어 있지 않을 때만 `CLAUDE.md` 하나를 쓴다. `gen_key(case, cond_text) -> str` 은 과제 본문(front matter 를 뺀 `prompt`)의 해시와 조건 파일 내용의 해시를 이은 값을 낸다. `judge_key(gen_key, criteria) -> str` 은 생성 키와 판정 기준 해시를 이은 값을 낸다. `plan_jobs(cases, units, done_gen, done_judge) -> (gen_jobs, judge_jobs)` 는 시험 단위마다 질문과 조건을 짝지어, 이미 기록된 키와 목록 안의 중복을 뺀다.
  - 시험 단위는 `evals/principles/clauses/<단위 이름>/` 폴더 하나다. 폴더에 `ids` 파일이 있으면 그 줄들이, 없으면 폴더 이름이 단위의 조항 ID 다. 질문은 `tags` 에 `dev` 가 있고 `clause` 에 단위의 ID 가 하나라도 있는 과제다. 조건은 `current.md` 가 있으면 `current`·`new`, 없으면 `none`·`new` 다.
  - `scripts/eval_clause.sh [<단위 이름>...]` 는 인자가 없으면 모든 단위를 실행한다. 생성 기록은 `evals/principles/results/clauses/gen.jsonl`(`key`, `case`, `cond`, `response`, `model`), 판정 기록은 `judge.jsonl`(`key`, `gen_key`, `violated`, `judge_note`, `judge_model`)에 한 줄씩 덧붙인다. 메인 스레드가 작업이 끝날 때마다 한 줄을 쓰고 flush 한다. 오류가 난 생성과 읽지 못한 판정은 기록하지 않고 마지막 줄의 `errors=` 로 센다. 판정이 실패하면 다음 실행은 판정만 다시 한다. 시작할 때 `results/clauses/.lock` 이 있으면 멈추고, 기록에 읽을 수 없는 줄이 있으면 그 줄 번호를 내고 멈춘다.
  - 두 실행 스크립트는 작업 폴더와 설정 폴더를 `EVAL_TMP`(기본 `/d/dc-eval-tmp`) 아래에 만들고, 그 폴더의 상위 경로 어디에든 `CLAUDE.md` 나 `.claude/CLAUDE.md` 가 있으면 실행하지 않고 그 경로를 낸다.
  - `scripts/eval_clause_report.sh [<단위 이름>...]` 는 단위마다 한 줄 `<단위> 질문=<n> 비교=<current|none> 비교위반=<수> 새위반=<수> 금지어 비교=<수> 새=<수> 판정=<채택|채택(차이없음)|동률|기각|넣음|넣지않음|미완>` 을 낸다. 금지어 수는 `type: chat` 응답만 센다. 판정 규칙은 아래와 같다.
    - 판정 기록이 하나라도 없으면 `미완` 이다.
    - 문구 변경: 새위반<비교위반이면 `채택`, 많으면 `기각` 이다. 같을 때 단위의 질문에 `followup: true` 과제가 없으면 `동률`, 있으면 `채택(차이없음)` 이다.
    - 새 조항: 비교위반=0 이면 `넣지않음`, 새위반<비교위반이면 `넣음`, 많으면 `기각` 이다. 같을 때 `followup` 과제가 없으면 `동률`, 있으면 `넣지않음` 이다.
  - `eval_principles.sh` 의 태그 `all` 은 모든 과제를 실행한다. `eval_compare.sh` 의 비교 출력에 `tags dev`·`tags holdout` 행이 추가된다.

- [ ] **Step 1: 실패하는 시험을 쓴다.** `test_eval_cases.sh` 에 픽스처로 아래를 추가한다.
  - `make_cfg` 로 만든 폴더의 파일 목록이 `text` 가 있으면 `CLAUDE.md` 하나이고, 비어 있으면 아무것도 없다.
  - `gen_key` 는 front matter 만 다른 두 과제에 같은 값을, 본문이 다른 과제에 다른 값을 낸다. `criteria` 만 바꾸면 `gen_key` 는 같고 `judge_key` 는 다르다.
  - 단위 `X-ONE`(current·new)과 `Y-TWO`(new 만, `ids` 파일에 `Y-TWO`·`Y-THREE`)에서 `plan_jobs` 는 `Y-TWO` 에 `none`·`new` 작업을, `X-ONE` 에 `current`·`new` 작업을 낸다. `Y-THREE` 를 태그한 과제도 `Y-TWO` 의 질문이 된다. `done_gen` 에 든 키의 생성은 나오지 않고, 그 생성의 판정 키가 `done_judge` 에 없으면 판정 작업만 나온다. 보류용 과제는 나오지 않는다.
  - 보고는 위 판정 규칙의 각 줄을 픽스처로 하나씩 확인한다. 금지어 수는 `type: tool` 응답의 금지어를 세지 않는다.
  - `pair` 가 없는 과제가 필드 검사를 통과하고, 있는 `pair` 가 없는 과제를 가리키면 실패한다.
  - 상위 경로 검사는 `.claude/CLAUDE.md` 가 있는 임시 상위 폴더 아래에서 실패하고, 없는 폴더에서 통과한다.
  - 비교 출력에 `tags dev` 행이 있다. 기존 픽스처는 `run` 필드 없이 과제마다 한 건으로 고친다.
- [ ] **Step 2:** `bash scripts/test_eval_cases.sh` 가 FAIL 을 낸다.
- [ ] **Step 3:** 위 Interfaces 대로 구현한다. `eval_clause.sh` 는 `eval_principles.sh` 의 키 읽기, 설정 지문 대조, `trap` 정리를 같은 방식으로 쓴다. 생성과 판정의 설정 폴더는 작업마다 `make_cfg` 로 만든다. `subprocess` 의 시간 초과는 그 작업의 오류로 센다.
- [ ] **Step 4:** `bash scripts/test_eval_cases.sh` 가 FAIL=0 이다. smoke 는 픽스처 과제 하나(`ok 라고만 답하라`)와 픽스처 단위 하나를 임시 폴더(`EVAL_CASES`·`EVAL_CLAUSES`·`EVAL_RESULTS`)에 두고 실행한다. 실제 과제를 쓰지 않으므로 Task 6 의 생성 키와 겹치지 않는다. 확인은 아래와 같다.
  - 종료 코드 0, 생성 기록 두 줄, 판정 기록 두 줄이 나오고, 같은 명령을 다시 실행하면 새 기록이 0 줄이다.
  - 틀린 API 키로 실행하면 `errors=` 가 0 보다 크고 기록이 늘지 않는다.
  - 설정 지문이 실행 전과 같다.
- [ ] **Step 5:** README 「실행 도구」에 클린룸 경로, 반복 없음, 상위 경로 측정(사용자 홈 아래 `/tmp` 세션에는 `~/.claude/CLAUDE.md` 가 실렸고 D: 아래 폴더에서는 실리지 않았다)을 적는다. Task 3 의 smoke 가 사용자 홈 아래 `/tmp` 에서 실행되었다는 사실도 실패 기록으로 적는다. 저장소 검사를 통과시킨 뒤 커밋한다. `git commit -m "평가 세트: 조항별 클린룸 실행과 보고"`

### Task 5: 조항 파일과 질문 추가

**Files:**
- Create: `evals/principles/clauses/<단위 이름>/current.md`, `new.md`, `ids`(나눈 쌍만)
- Create: `evals/principles/cases/<새 과제>/`(단위마다 짝 하나, 합계가 3 미만인 단위는 하나 더)
- Modify: `evals/principles/cases/instruction-*/prompt.md`(`clause` 에 `INSTRUCTION-FORM`), `evals/principles/cases/lang-*/prompt.md`(`출력 언어` 를 `OUTPUT-LANG` 으로), `scripts/test_eval_cases.sh`, `evals/principles/README.md`(「과제 구성」)

조항 ID 가 없는 대상은 영문 ID 로 부른다. 「균형」 문단은 `BALANCE`, 출력 언어 문단은 `OUTPUT-LANG` 이다. 나눈 쌍은 원래 조항 이름의 폴더(`REVERSIBLE`, `FOCUSED`, `NO-RAW-OUTPUT`)에 두고 `ids` 에 두 ID 를 적는다. 기존 과제의 `clause` 를 바꾸는 일은 이 Task 에서 끝낸다. 생성 키는 본문만 보므로 머리 변경이 반복을 만들지 않지만, 판정 결과의 단위 배정이 Task 6 도중에 바뀌지 않게 하기 위해서다.

- [ ] **Step 1: 실패하는 시험을 쓴다.** `test_eval_cases.sh` 가 저장소의 단위 폴더로 아래를 확인한다.
  - `BANNED-LIST` 를 뺀 모든 `current.md` 의 비어 있지 않은 줄이 `git show 7a2d26d:agent-principles.md` 안에 그대로 있다(문장 단위로 옮긴 줄도 통과한다).
  - 모든 단위 폴더에 `new.md` 가 있다.
  - 단위마다 개발용 질문이 3개 이상이고 `kind` 의 `should` 와 `should-not` 이 모두 있다.
- [ ] **Step 2:** 시험이 FAIL 을 낸다.
- [ ] **Step 3:** 변경안 초안(`.superpowers/sdd/2026-10-18-principles-positive-restructure/changes-draft.md`)으로 단위 폴더를 만든다. 형식은 spec 「조항별 클린룸 시험」 첫 문단을 따른다. 초안이 '문안 유지'로 적은 조항의 `new.md` 는 현행 문장 뒤에 이유 한 줄을 붙인다.
- [ ] **Step 4:** 단위마다 새 질문을 만든다. 질문은 `current.md` 가 다루는 상황과 초안 이유 칸의 실패 사례(R 번호, 원자료는 `~/dc-eval-raw/2026-10-18/`)에서 만들고, `new.md` 의 문장에서 만들지 않는다. 판정 기준에는 `new.md` 에만 있는 표현을 쓰지 않는다. 형식은 기존 과제와 같고(평가용 머리말, 도구 과제의 끝 문장, 여러 턴은 `[이전 대화]`), `tags: [dev]`, `failure` 는 기존 값 중 하나, `pair` 는 짝 과제다. 짝을 이루지 못하는 셋째 질문에는 `pair` 를 두지 않는다. 파일이 많으므로 층마다 서브에이전트 하나에 맡길 수 있다. 그때 프롬프트에 이 Step 의 규칙, 기존 과제 두 개의 경로, 그 층 단위 폴더의 경로, 초안과 원자료의 경로, 에이전트원칙의 경로를 넣는다. 모든 서브에이전트의 결과를 메인 세션이 한 번에 읽어 판정 기준의 엄격함을 맞춘다.
- [ ] **Step 5:** `bash scripts/test_eval_cases.sh` 가 FAIL=0 이고 저장소 검사도 통과한다. README 「과제 구성」을 갱신하고 커밋한다. `git commit -m "평가 세트: 조항 파일과 조항별 질문"`. 새 질문은 일반화한 실패 사례에서 만들었으므로 Task 2 의 원문 확인 대신 Task 6 Step 1 에서 층마다 질문 하나씩을 사용자에게 보인다.

### Task 6: 조항별 클린룸 시험

**Files:**
- Create: `evals/principles/results/clauses/gen.jsonl`, `judge.jsonl`
- Modify: `evals/principles/README.md`(「측정 기록」 절: 단위마다 질문 수, 조건별 위반, 판정, 사용자 확인 일치도)
- Modify: `docs/domain-discipline.md`, `docs/domain-korean.md`(단위마다 측정 단락: 변경 이유와 세션 기록 근거, 질문 수, 조건별 위반, 판정)

- [ ] **Step 1:** 실행할 생성·판정 작업 수(`plan_jobs`)와 Task 1 의 세션 비용·시간으로 전체 비용과 시간을 계산하고, 층마다 새 질문 하나씩과 함께 사용자에게 보여 진행 여부를 묻는다.
- [ ] **Step 2:** `bash scripts/eval_clause.sh` 를 실행한다. 확인: 종료 코드가 0 이고 `errors=0` 이다. 오류가 있으면 같은 명령을 한 번만 다시 실행해 빠진 작업을 채운다. 그래도 남은 오류는 과제 이름과 오류 문구를 사용자에게 알리고 처리를 묻는다.
- [ ] **Step 3:** 판정 10건 안팎을 골라 사용자에게 보이고 일치도를 받는다. 사용자가 판정 기준을 고치기로 하면 그 과제의 `criteria.md` 를 고치고 같은 명령으로 판정만 다시 한다.
- [ ] **Step 4:** `bash scripts/eval_clause_report.sh` 로 판정을 낸다. `동률` 단위마다 `followup: true` 를 단 새 질문 짝을 추가해 커밋하고 그 단위만 다시 실행한다. 확인: 둘째 보고에 `동률` 과 `미완` 이 없다.
- [ ] **Step 5:** 판단 조항이 `기각` 이면 결과를 모아 사용자에게 처리를 묻는다.
- [ ] **Step 6:** 단위마다 측정 단락을 참고서에 적는다. `채택(차이없음)` 은 측정이 차이를 잡지 못한 채택이라고 적는다. README 「측정 기록」을 채운 뒤 커밋한다. `git add evals/principles docs/domain-*.md && git commit -m "측정 기록: 조항별 클린룸 시험"`

### Task 7: 채택 문안 적용

**Files:**
- Modify: `agent-principles.md`, `CLAUDE.md`(「지시와 근거의 분리」 항목)
- Modify: `docs/domain-discipline.md`, `docs/domain-korean.md`(새 ID, 불변 조건 훅 검토, 이유 한 줄과 겹치는 상세 근거 정리)
- Modify: `skills/review-specs/SKILL.md`, `skills/review-docs/SKILL.md`, `skills/dispatching-lenses/SKILL.md`(새 결정 규칙과 같은 상황에 부딪히는 문장만)
- Modify: `scripts/test_docs_drift.sh`(절 이름, 조항 ID, `LENS-ALLOWED` 위치)

- [ ] **Step 1:** 원칙을 spec 「목차 구조」 표의 층으로 다시 쓴다. 채택·넣음 단위는 `new.md` 의 조항 줄을, 기각·넣지않음 단위는 현행 문장을 쓴다. 나눈 쌍이 기각되면 원래 조항 하나를 현행대로 둔다. 첫 문단은 "해당하는 층을 모두 적용하라"로 바꾸고, 층과 묶음의 적용 조건 문장은 `new.md` 의 첫 줄과 둘째 줄을 그대로 쓴다. 채택된 이유 한 줄과 같은 커밋에서 CLAUDE.md 「지시와 근거의 분리」를 "에이전트원칙에는 행동 지시와 그 이유 한 줄을 적는다. 측정 기록과 출처는 참고서에 조항 ID 로 적는다"로 바꾼다.
- [ ] **Step 2:** 확인: 채택·넣음 단위마다 `new.md` 의 비어 있지 않은 모든 줄이 `agent-principles.md` 에 그대로 있다(`grep -Fx` 를 줄마다 실행해 빠진 단위를 낸다).
- [ ] **Step 3:** 불변 조건(`SECRETS`, `CONFIRM-IRREVERSIBLE`, `OTHER-SESSIONS`)마다 훅으로 강제할 수 있는지 검토해 `docs/domain-discipline.md` 에 적는다. 훅을 새로 만드는 일은 이 plan 의 범위 밖이므로, 만들 수 있는 훅은 사용자에게 알린다.
- [ ] **Step 4:** 스킬 세 개의 부딪히는 문장을 고친다. 다른 세션이 고친 `review-specs`·`dispatching-lenses` 는 `git log main -- skills/review-specs skills/dispatching-lenses` 로 main 에 병합된 커밋만 본다. 병합되지 않은 변경은 그 세션에 메시지로 묻는다.
- [ ] **Step 5:** 저장소 검사가 깨지면 검사가 절을 고르는 코드(절 이름, awk 범위)만 새 구조에 맞추고, 단언하는 문자열은 바꾸지 않는다. 확인: `git diff -- scripts/test_docs_drift.sh` 에 단언 문자열의 변경이 없다. 저장소 검사가 FAIL=0 이고 `claude plugin validate ./` 가 통과하면 커밋한다. `git commit -m "원칙 개편: 채택 문안을 층별로 적용"`

### Task 8: 금지어 지시형 트랙

시험을 먼저 하고 전환은 채택된 뒤에만 한다. 기각되면 되돌릴 것이 Step 3 의 커밋 하나뿐이게 하기 위해서다.

**Files:**
- Modify: `korean-banned-words.md`(Step 3: 여섯째 칸. Step 6: 칸 설명, 사본 설명, 「지시형 지시」 절)
- Modify: `hooks/_banned_words.sh`(지시형 트랙 생성 함수 `banned_guide` 추가)
- Modify: `scripts/_scaffold_common.sh`, `scripts/scaffold.sh`(Step 6)
- Modify: `scripts/test_hooks.sh`, `scripts/test_scaffold.sh`, `scripts/test_eval_cases.sh`
- Create: `evals/principles/clauses/BANNED-LIST/current.md`, `new.md`, 언어 압력 질문 짝
- Modify: `README.md`(3·41·80행의 금지 표현 목록 적재 설명), `docs/domain-korean.md` 「지시문의 형태」(Step 6)

`hooks/doc_word_*.sh`, `hooks/stop_gates.sh`, `scripts/check_banned_words.sh` 는 고치지 않는다. 이 파일들은 플러그인 폴더의 원본 표를 `banned_parse` 로 읽고, 파서는 awk 필드 `c[2]`·`c[3]`·`c[4]`·`c[6]` 을 위치로 읽으므로 여섯째 칸(awk 필드 `c[7]`)을 추가해도 결과가 같다. Step 1 의 픽스처 시험이 이 판단을 확인한다.

**Interfaces:**
- Produces: `banned_guide <표> <출력>` 은 표의 행마다 `- <상황>: <대체어>` 한 줄을 낸다. 상황은 awk 필드 `c[7]`, 대체어는 awk 필드 `c[3]` 이며, 조사를 붙이지 않아 문장형 대체어도 그대로 읽힌다. 「지시형 지시」 절이 있으면 그 절을 그대로 붙인다. 출력에는 금지어 칸(awk 필드 `c[2]`)의 글자가 들어가지 않는다.

- [ ] **Step 1: 실패하는 시험을 쓴다.**
  - `test_hooks.sh`: 여섯 칸 픽스처(`` | `판` | 버전 | 문서와 답변 | 평소에 쓰지 않는 말 | `판정` · `판단` | 버전을 말할 때 | ``)에서 "제외 안의 것은 안 잡는다", "제외 밖의 것은 잡는다", "적용 대상으로 행을 고른다"가 다섯 칸 픽스처와 같은 결과를 낸다. `banned_guide` 의 출력에 `- 버전을 말할 때: 버전` 이 있고 `` `판` `` 이 없다.
  - `test_eval_cases.sh`: `BANNED-LIST/current.md` 가 `git show 7a2d26d:korean-banned-words.md` 와 같다.
- [ ] **Step 2:** 시험이 FAIL 을 낸다.
- [ ] **Step 3:** `korean-banned-words.md` 표에 여섯째 칸 `상황` 을 추가하고 `banned_guide` 를 구현한다. 생성은 복사와 같은 규칙을 따른다(내용이 같으면 쓰지 않고, 옆 이름에 쓴 뒤 `mv`, 실패하면 ERROR 를 내고 이어 실행). 시험이 FAIL=0 이면 이 변경만 커밋한다. `git commit -m "금지어: 상황 칸과 지시형 트랙 생성 함수"`
- [ ] **Step 4:** `BANNED-LIST` 단위를 만든다. `current.md` 는 기준 원칙 커밋의 목록 파일, `new.md` 는 `banned_guide` 의 출력이다. 낯선 대체어를 만들기 쉬운 언어 압력 질문 짝을 추가하고, 개발용 `failure: language` 과제의 `clause` 에 `BANNED-LIST` 를 추가해 커밋한다. `git commit -m "평가 세트: 금지어 목록 단위와 질문"`
- [ ] **Step 5:** `bash scripts/eval_clause.sh BANNED-LIST` 와 `bash scripts/eval_clause_report.sh BANNED-LIST` 를 실행하고, 판정 10건 안팎을 사용자에게 보여 일치도를 받는다. `동률` 이면 Task 6 Step 4 와 같이 짝 하나를 한 번 더 한다. 확인 기준: 판정이 `채택` 이나 `채택(차이없음)` 이고 금지어 `새` 가 `비교` 이하다. 채우지 못하면 Step 3 의 커밋만 `git revert` 하고 측정 단락을 적어 커밋한 뒤 결과를 사용자에게 알린다. Step 4 의 단위와 질문은 측정 근거이므로 남긴다.
- [ ] **Step 6:** 채택되었을 때만 전환한다.
  - `test_scaffold.sh` 에 실패하는 시험을 먼저 쓴다. 스캐폴드 뒤 관리 폴더에 `korean-word-guide.md` 가 있고, 관리블록은 `@disciplined-coder/korean-word-guide.md` 를 싣고 `@disciplined-coder/korean-banned-words.md` 를 싣지 않는다. 생성 파일에 원본 표 첫 칸의 글자가 없다. `~/.claude/CLAUDE.md` 의 어떤 블록도 옛 목록 파일을 import 하지 않으면 스캐폴드가 관리 폴더의 옛 사본을 지우고, 다른 블록이 import 하면 지우지 않고 원본으로 덮어쓴다. `banned_guide` 가 실패해도 관리블록 주입까지 실행하고 ERROR 한 줄을 낸다. 기존 검사 중 목록 파일이 관리 폴더에 놓이고 첫 세션에 실린다고 확인하는 검사는 새 동작에 맞게 고친다.
  - `scripts/_scaffold_common.sh` 와 `scripts/scaffold.sh` 를 고친다(복사 대상, 생성 대상, 화이트리스트, import 줄, 첫 세션 출력, 옛 사본 처리).
  - `korean-banned-words.md` 의 칸 설명과 사본 설명을 고치고, 표 밖 지시 중 문자열로 검사할 수 없는 문장을 「지시형 지시」 절로 모으며 예문에서 금지어 글자를 뺀다. 원칙의 `BULLET-SCOPE`·`SPECIFIC-NAME`·`COUNT-EARNS` 와 겹치는 문장은 목록 쪽에서만 지우고 원칙 문장은 고치지 않는다. 그러면 `new.md` 와 지시형 트랙 출력이 달라지므로, `banned_guide` 를 다시 실행해 생성 파일이 시험한 `new.md` 와 다른 줄만 사용자에게 보인다.
  - README 와 「지시문의 형태」를 고치고 측정 단락을 적는다. 저장소 검사가 FAIL=0 이고 `claude plugin validate ./` 가 통과하면 커밋한다. `git commit -m "금지어: 지시형 트랙 전환"`

### Task 9: 저장소 규칙과 참조 정리

**Files:**
- Modify: `CLAUDE.md`(「조항 추가와 문구 변경」·「명령형」 항목, 30행의 절 이름)
- Modify: `README.md`(56·81행의 옛 절 이름), `hooks/doc_format_pretooluse.sh`, `scripts/scaffold.sh`(209행 주석), `skills/domain-readme/SKILL.md`, `skills/lens-readability/SKILL.md`, `skills/domain-pruning/SKILL.md`
- Modify: `docs/domain-discipline.md`, `docs/domain-korean.md`(절 구조를 새 층에 맞춤)

- [ ] **Step 1:** CLAUDE.md 를 spec 「저장소 규칙의 변경」대로 고친다. 「조항 추가와 문구 변경」의 과제 수 문장을 질문 수와 판정 규칙으로 바꾸고, 같은 질문을 다시 실행하지 않는다는 문장, 단위 폴더와 질문의 경로, 실행 명령(`bash scripts/eval_clause.sh <단위 이름>`, `bash scripts/eval_clause_report.sh <단위 이름>`)을 적는다. 확인: `grep -n "eval_clause.sh" CLAUDE.md` 가 줄을 내고, `grep -n "다섯 과제" CLAUDE.md` 가 줄을 내지 않는다.
- [ ] **Step 2:** 확인: `git grep -n -e "「원칙」" -e "「출력지시」" -e "「검증」" -e "「문서를 쓰고 관리할 때」" -- '*.md' '*.sh' ':!docs/superpowers/'` 가 줄을 내지 않는다.
- [ ] **Step 3:** 이 PC 의 `~/.claude/CLAUDE.md` 에 다른 플러그인이 금지 표현 목록을 import 하는 줄이 있는지 확인해 사용자에게 알린다.
- [ ] **Step 4:** 저장소 검사가 FAIL=0 이고 `claude plugin validate ./` 가 통과한다. 그다음 커밋한다.

### Task 10: 전체 비교와 병합 준비

- [ ] **Step 1:** `git merge main` 으로 main 을 가져와 충돌을 해소한다. 확인: 저장소 검사가 FAIL=0 이다.
- [ ] **Step 2:** `bash scripts/eval_principles.sh 7a2d26d all baseline` 과 `bash scripts/eval_principles.sh HEAD all final` 을 실행한다. 이 경로는 생성 키로 반복을 차단하지 않으므로, 한쪽이 끊기거나 실패하면 다시 실행하지 말고 원인과 남은 과제를 사용자에게 알려 처리를 묻는다. 확인: 두 명령의 종료 코드가 0 이다.
- [ ] **Step 3:** `eval_compare.sh baseline final` 로 비교하고, `eval_compare.sh baseline` 과 `eval_compare.sh final` 로 적재 분량을 낸다. 판정 10건 안팎을 사용자에게 보여 일치도를 받는다. 세 출력과 일치도를 측정 기록에 추가해 커밋한다.
- [ ] **Step 4:** 측정 기록 전체와 최종 비교를 사용자에게 보고한다. 첫 줄 판정이 `개선` 이고 `tags holdout` 행의 B 가 A 이하일 때만 main 병합 승인을 묻는다. 그렇지 않으면 병합하지 않고, 과제별 위반 차이와 선택지를 보여 묻는다.
- [ ] **Step 5:** 병합한 뒤 이 plan 에 git 보존 태그를 달고 plan 을 지운다(에이전트원칙 문서 수명 표). 원자료 폴더 `~/dc-eval-raw/2026-10-18/` 를 지울지 사용자에게 묻는다.

<!-- spec-review: escalated -->
