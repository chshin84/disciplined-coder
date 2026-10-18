# 에이전트원칙 긍정형 재작성 Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** 실패 평가 세트를 먼저 만들고, 그 세트로 단계마다 측정하면서 `agent-principles.md` 를 출력 종류별 층과 결정 규칙 형식으로 다시 쓴다.

**Architecture:** 평가 세트(`evals/principles/`)와 실행·비교 스크립트를 먼저 만들고 기준 원칙을 측정한다. 단계 1~5 는 각각 원칙을 바꾸는 커밋 하나와 측정 기록 커밋 하나로 진행한다. 측정은 그 단계 커밋을 대상으로 개발용 과제를 실행해 직전 상태와 기준 원칙과 비교한다. 마지막에 main 을 가져와 보류용 과제로 한 번 비교하고 병합 승인을 받는다.

**Tech Stack:** bash, awk, Python(기존 `json_run` 헬퍼), Claude Code CLI(이 PC 에서 `claude --version` 은 2.1.302 를 낸다). 실행 도구는 Task 1 이 `claude plugin eval` 과 `claude -p` 중에서 고른다.

**Spec:** `docs/superpowers/specs/2026-10-18-principles-positive-restructure-design.md`

## 용어

| 이름 | 뜻 |
|---|---|
| 조건 | 측정 대상인 원칙 상태 하나다. 커밋 하나로 정해지고 라벨(`baseline`, `step1` 등)로 부른다 |
| 직전 상태 | 되돌리지 않고 남긴 마지막 단계의 라벨이다. 단계 1 의 직전 상태는 `baseline` 이다 |
| 평가 설정 폴더 | 조건마다 새로 만드는 빈 `CLAUDE_CONFIG_DIR` 폴더다. 실제 `~/.claude` 와 따로 있고, 측정이 끝나면 지운다 |
| 예열 세션 | 평가 설정 폴더를 만든 뒤 판정하지 않고 한 번 실행하는 세션이다. scaffold 가 관리블록과 원칙 사본을 만들게 해서, 판정하는 모든 세션이 같은 `@import` 경로로 원칙을 싣게 한다 |
| 지시형 트랙 | 금지어 표의 상황 칸과 대체어 칸으로 만든 '어떤 상황에서 어떤 말을 써라' 파일(`korean-word-guide.md`)이다. 금지어를 적지 않는다 |
| 극성 짝 비교 | 같은 조항의 금지형 문안과 결정 규칙 문안을 같은 과제로 비교하는 일이다 |
| 판정 모델 | 평가 응답이 기대 행동을 지켰는지 판정하는 Claude 모델이다. 생성 모델과 크기가 다르다 |
| 설정 지문 | 실제 설정 파일(`~/.claude/CLAUDE.md`, `~/.claude/disciplined-coder/*.md`, `~/.claude/settings.json`, `~/.claude/plugins/known_marketplaces.json`, `~/.claude/plugins/installed_plugins.json`)의 해시 목록이다 |

## Global Constraints

기준 원칙은 커밋 `7a2d26d` 의 `agent-principles.md` 다. 반복은 조건마다 3회이고, 단계 측정과 후보 채택에는 개발용 과제만 쓴다. 보류용 과제는 Task 11 에서 한 번 쓴다.

'개선'은 비교 상대보다 위반 합계(과제 수 × 3회)가 적은 상태이고, 같으면 개선이 아니다. '나쁘지 않다'는 위반 합계가 비교 상대 이하인 상태다. 단계의 확인 기준은 직전 상태 대비로 판정한다. 예외는 단계 4 의 금지어 횟수로, spec 이 기준 원칙 대비로 정했으므로 기준 원칙과 비교한다. 그 밖의 기준 원칙 대비 결과는 측정 기록에 함께 적고, 기준 원칙보다 나빠졌으면 다음 단계로 가기 전에 사용자에게 알린다.

단계 Task 의 모든 변경은 커밋 하나(`단계 N: <요약>`)로 만든다. 확인 기준을 채우지 못하면 그 커밋만 `git revert` 로 되돌리고, 측정 기록 커밋은 남긴다. 실패한 측정도 기록으로 남기기 위해서다. 단계 1 이나 단계 2 를 되돌리면 다음 단계로 가기 전에 사용자에게 알리고 진행 여부를 묻는다.

판단 조항은 "상황 → 행동 → 멈출 조건. 이유 한 줄." 형식으로 쓴다. 상황과 멈출 조건은 사용자 메시지, 도구 결과, 파일 상태, 횟수처럼 관찰할 수 있는 사건으로 쓴다. 불변 조건은 "~하지 마라. 이유 한 줄." 형식으로 쓰고 강조어는 쓰지 않는다.

조항 ID 는 유지한다. 조항을 나누면 원래 ID 는 판단 조항이나 주된 쪽에 남기고, 나눈 쪽에 새 ID 를 붙인다. 새 ID 는 `docs/domain-discipline.md` 와, 원래 ID 를 가리키는 원칙 안 문장에 같은 커밋에서 반영한다.

평가 과제에는 업무 수치, 종목, 키, 사람 이름, 회사명, 사용자 메시지 원문을 넣지 않는다. 평가 세션은 평가 설정 폴더와 원격을 지운 복제 저장소에서 실행하고, 실제 설정 파일을 쓰지 않는다. 평가 명령은 `CLAUDE_HOME_DIR` 을 비운 셸에서 실행한다. `scripts/_resolve_home.sh` 가 이 변수를 `CLAUDE_CONFIG_DIR` 보다 먼저 보기 때문이다. 측정 뒤 설정 지문이 달라졌으면 구현자는 파일을 되돌리지 않고 멈춰서, 바뀐 파일 목록을 사용자에게 보이고 처리를 묻는다. 다른 창의 정상 변경을 덮어쓰지 않기 위해서다.

다른 세션의 작업 중인 브랜치와 worktree 는 읽지 않는다. 대조는 메시지나 main 에 병합된 커밋으로만 한다. 고친 것이 있으면 저장소 검사(CLAUDE.md 「변경 뒤 실행」의 병렬 명령)와 `claude plugin validate ./` 를 실행한다. 계약은 FAIL=0 과 `Validation passed` 다. 커밋 메시지는 `Co-Authored-By: Claude Opus 5.5 (1M context) <noreply@anthropic.com>` 로 끝낸다.

## Review Focus

- **실제 설정 오염** — 평가 세션이 실제 설정 파일을 고치면 이 PC 의 모든 세션이 바뀐다. 구현자는 측정 전후의 설정 지문을 대조하고, 다르면 멈추고 묻는다.
- **조건 혼선** — 개편안 조건의 세션에 다른 조건의 원칙이 실리면 두 조건이 같은 원칙으로 측정된다. 실행 스크립트는 조건마다 새 평가 설정 폴더를 쓰고, 예열 세션 뒤에 관리 폴더의 파일과 관리블록을 그 커밋에서 기대하는 값과 대조한다.
- **과제의 비밀·개인정보 유출** — 일반화를 거쳐도 키 형태 문자열이나 이름이 남을 수 있다. `scripts/test_eval_cases.sh` 가 패턴을 검사하고, 사용자가 커밋 전에 과제 목록을 확인한다.
- **판정 모델의 한국어 오판** — 판정 모델이 문체 위반을 놓치면 점수가 개선으로 보인다. 구현자는 단계마다 판정 10건 안팎을 사용자에게 보여 일치도를 기록한다.
- **여섯 칸 표의 제외어 누락** — 상황 칸을 추가한 뒤 파서가 제외 칸을 잘못 읽으면 `판정` 같은 말이 금지어로 잡힌다. Task 8 이 `scripts/test_hooks.sh` 에 여섯 칸 픽스처를 추가한다.

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
    5. 태그에 맞는 과제를 3회 실행하고 판정한다.
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

### Task 4: 측정 규모 확인과 기준 원칙 측정

**Files:**
- Create: `evals/principles/results/baseline/result.json`
- Modify: `evals/principles/README.md`(「측정 기록」 절. 행마다 라벨, 커밋, 위반 합계, 직전 상태 대비 판정, 기준 원칙 대비 판정, 금지어 횟수, 세션 적재 줄 수와 글자 수, 사용자 확인 일치도를 적는다)

- [ ] **Step 1:** Task 1 의 실행 시간과 개발용 과제 수로 조건 하나의 소요 시간을 계산한다. 예상 조건 수(기준 원칙, 단계 1~4, 단계 5 후보, 보류용 둘)를 곱해 전체 소요를 사용자에게 보이고 진행 여부를 묻는다.
- [ ] **Step 2:** `bash scripts/eval_principles.sh 7a2d26d dev baseline` 을 실행한다. 확인: `result.json` 의 배열 길이가 개발용 과제 수 × 3 이고, 종료 코드가 0 이다.
- [ ] **Step 3:** 판정 10건 안팎을 골라 사용자에게 보이고, 판정 모델과 같은지 답을 받아 일치도를 기록한다. 사용자가 불일치를 보고 판정 기준을 고치기로 하면 과제를 고쳐 Step 2 부터 다시 한다.
- [ ] **Step 4:** `bash scripts/eval_compare.sh baseline` 의 출력으로 측정 기록에 한 행을 추가하고 커밋한다. `git commit -m "측정 기록: baseline"`

### 측정 절차(Task 5~9 공통)

단계마다 아래 순서를 따른다. 각 Task 는 이 순서 가운데 '확인 기준'만 따로 정한다.

1. 그 Task 의 모든 변경을 커밋 하나로 만든다. 커밋 제목은 `단계 N: <요약>` 이다.
2. `bash scripts/eval_principles.sh HEAD dev <라벨>` 로 측정한다. 이어서 `eval_compare.sh <직전 상태> <라벨>` 과 `eval_compare.sh baseline <라벨>` 을 실행한다.
3. 판정 10건 안팎을 사용자에게 보여 일치도를 받는다.
4. `eval_compare.sh <라벨>` 의 출력으로 측정 기록에 한 행을 추가하고, `측정 기록: <라벨>` 커밋으로 남긴다.
5. 확인 기준을 채우지 못하면 1 의 커밋만 `git revert` 한다.

### Task 5: 단계 1 — 층 재배치

**Files:**
- Modify: `agent-principles.md`, `scripts/test_docs_drift.sh`(절 이름과 조항 ID 대조, `LENS-ALLOWED` 위치 검사)

- [ ] **Step 1:** 원칙을 spec 「목차 구조」 표의 층으로 옮긴다. 조항 문구와 묶음의 현행 적용 조건 문장은 바꾸지 않는다. 지킬 사항은 아래와 같다.
  - `REVISE-ORDER` 는 '모든 답' 층에 두고, 대화 답 제외 문장을 그대로 옮긴다.
  - `LENS-ALLOWED` 는 spec 표대로 '모든 작업' 층으로 옮긴다.
  - 「검증」 묶음의 나머지는 나누지 않고 '작업 문서·지시문' 층에 둔다.
- [ ] **Step 2:** 저장소 검사가 깨지면 새 절 이름에 맞춰 검사를 고치고 FAIL=0 으로 만든다.
- [ ] **Step 3:** 측정 절차를 라벨 `step1` 로 따른다. 확인 기준: `baseline` 대비 판정이 `개선` 이나 `동률` 이다.

### Task 6: 단계 2 — 결정 규칙화와 충돌 쌍 해소

**Files:**
- Modify: `agent-principles.md`, `docs/domain-discipline.md`(새 ID 와 불변 조건 훅 검토)
- Modify: `skills/review-specs/SKILL.md`, `skills/review-docs/SKILL.md`, `skills/dispatching-lenses/SKILL.md`(새 결정 규칙과 같은 상황에 부딪히는 문장만)
- Modify: `scripts/test_docs_drift.sh`(새 ID)

- [ ] **Step 1:** 판단 조항을 결정 규칙으로 다시 쓰고, 이유 한 줄은 붙이지 않는다. 함께 할 일은 아래와 같다.
  - spec 「결정」이 든 충돌 쌍을 적용 조건 분리나 목적 문장으로 푼다.
  - 첫 문단의 "원칙 사이에 우열은 없으니"를 지우고 "해당하는 층을 모두 적용하라"로 바꾼다.
  - 층 적용 조건을 사건으로 바꾸고, `REVISE-ORDER` 를 대화 답에도 적용한다.
  - `NO-RAW-OUTPUT` 을 산출물 쪽과 spec·plan 쪽으로 나누고, 「균형」 문단이 새 ID 도 가리키게 고친다.
  - 불변 조건은 `SECRETS`, `REVERSIBLE` 의 사용자 결정 범위, 다른 세션 저장소 금지로 둔다.
- [ ] **Step 2:** 결정 규칙마다 상황과 멈출 조건이 가리키는 사건을 표로 만들어 커밋 메시지 본문에 넣는다. 확인: 표의 모든 칸이 사용자 메시지, 도구 결과, 파일 상태, 횟수 중 하나를 가리킨다.
- [ ] **Step 3:** 불변 조건마다 훅으로 강제할 수 있는지 검토해 `docs/domain-discipline.md` 에 적는다. 훅을 새로 만드는 일은 이 plan 의 범위 밖이므로, 만들 수 있는 훅은 사용자에게 알린다.
- [ ] **Step 4:** 다른 세션이 고친 `review-specs`·`dispatching-lenses` 는 `git log main -- skills/review-specs skills/dispatching-lenses` 로 main 에 병합된 커밋만 본다. 병합되지 않은 변경은 그 세션에 메시지로 묻는다.
- [ ] **Step 5:** 저장소 검사가 FAIL=0 이다. 측정 절차를 라벨 `step2` 로 따른다. 확인 기준은 직전 상태 대비로 판정하며 아래와 같다.
  - `confirm-loop` 행과 `conflict` 행의 위반이 줄었다.
  - `kind: should` 행의 위반이 늘지 않았다.
- [ ] **Step 6:** 극성 짝 비교를 한다. `eval_compare.sh <직전 상태> step2` 의 `clause` 행에서 바꾼 판단 조항마다 위반 수를 본다. 결정 규칙 쪽 위반이 적지 않은 조항은 되돌리지 않고 목록으로 모아 사용자에게 처리를 묻는다.

### Task 7: 단계 3 — 이유 한 줄 결합

**Files:**
- Modify: `agent-principles.md`, `CLAUDE.md`(「지시와 근거의 분리」 항목)
- Modify: `docs/domain-discipline.md`, `docs/domain-korean.md`(이유 한 줄과 겹치는 상세 근거 정리)

- [ ] **Step 1:** CLAUDE.md 「지시와 근거의 분리」를 "에이전트원칙에는 행동 지시와 그 이유 한 줄을 적는다. 측정 기록과 출처는 참고서에 조항 ID 로 적는다"로 바꾼다. 이유를 붙이는 변경과 같은 커밋에 넣어, 원칙이 저장소 규칙과 어긋나는 커밋이 생기지 않게 한다.
- [ ] **Step 2:** 판단 조항과 불변 조건 모두에 이유 한 줄("~하기 위해서다" 또는 "~이기 때문이다")을 붙인다.
- [ ] **Step 3:** 저장소 검사가 FAIL=0 이다. 측정 절차를 라벨 `step3` 으로 따른다. 확인 기준은 아래와 같다.
  - `format` 행의 위반이 직전 상태보다 줄었다.
  - 전체 위반 합계가 직전 상태 이하다.

  세션 적재 분량이 늘고 점수가 떨어졌으면, 사용자에게 층 분리(조건부 로드)를 다시 검토할지 묻는다.

### Task 8: 단계 4 — 금지어 지시형 트랙

**Files:**
- Modify: `korean-banned-words.md`(아래 Step 3 의 변경)
- Modify: `hooks/_banned_words.sh`(지시형 트랙 생성 함수 `banned_guide` 추가)
- Modify: `scripts/_scaffold_common.sh`(복사 대상 `agent-principles.md`, 생성 대상 `korean-word-guide.md`, 화이트리스트)
- Modify: `scripts/scaffold.sh`(생성 호출, 관리블록 import 줄, 첫 세션 출력, 옛 사본 처리)
- Modify: `scripts/test_hooks.sh`, `scripts/test_scaffold.sh`
- Modify: `README.md`(3·41·80행의 금지 표현 목록 적재 설명), `docs/domain-korean.md` 「지시문의 형태」

`hooks/doc_word_*.sh`, `hooks/stop_gates.sh`, `scripts/check_banned_words.sh` 는 고치지 않는다. 이 파일들은 플러그인 폴더의 원본 표를 `banned_parse` 로 읽고, 파서는 awk 필드 `c[2]`·`c[3]`·`c[4]`·`c[6]` 을 위치로 읽으므로 여섯째 칸(awk 필드 `c[7]`)을 추가해도 결과가 같다. Step 1 의 픽스처 시험이 이 판단을 확인한다.

**Interfaces:**
- Produces: `banned_guide <표> <출력>` 은 표의 행마다 `- <상황>: <대체어>` 한 줄을 낸다. 상황은 awk 필드 `c[7]`, 대체어는 awk 필드 `c[3]` 이며, 조사를 붙이지 않아 문장형 대체어도 그대로 읽힌다. 그 뒤에 `korean-banned-words.md` 의 「지시형 지시」 절을 그대로 붙인다. 출력에는 금지어 칸(awk 필드 `c[2]`)의 글자가 들어가지 않는다.

- [ ] **Step 1: 실패하는 시험을 쓴다.**
  - `test_hooks.sh`: 여섯 칸 픽스처(`` | `판` | 버전 | 문서와 답변 | 평소에 쓰지 않는 말 | `판정` · `판단` | 버전을 말할 때 | ``)에서 "제외 안의 것은 안 잡는다", "제외 밖의 것은 잡는다", "적용 대상으로 행을 고른다"가 다섯 칸 픽스처와 같은 결과를 낸다. `banned_guide` 의 출력에 `- 버전을 말할 때: 버전` 이 있고 `` `판` `` 이 없다.
  - `test_scaffold.sh`: 스캐폴드 뒤 관리 폴더에 `korean-word-guide.md` 가 있다. 관리블록은 `@disciplined-coder/korean-word-guide.md` 를 싣고 `@disciplined-coder/korean-banned-words.md` 를 싣지 않는다. 생성 파일에 원본 표 첫 칸의 글자가 하나도 없다. 기존 검사 중 목록 파일이 관리 폴더에 놓이고 첫 세션에 실린다고 확인하는 검사는 새 동작에 맞게 고친다.
  - `test_scaffold.sh`(옛 사본): `~/.claude/CLAUDE.md` 의 어떤 블록도 `@disciplined-coder/korean-banned-words.md` 를 import 하지 않으면 스캐폴드가 관리 폴더의 옛 사본을 지운다. 다른 블록이 import 하면 옛 사본을 지우지 않고 원본으로 계속 덮어쓴다.
  - `test_scaffold.sh`(생성 실패): `banned_guide` 가 실패해도 스캐폴드가 관리블록 주입까지 실행하고 ERROR 한 줄을 낸다.
- [ ] **Step 2:** 시험이 FAIL 을 낸다.
- [ ] **Step 3:** 아래를 고친다.
  - `korean-banned-words.md` 의 표에 여섯째 칸 `상황` 을 추가하고, 칸 설명 문단과 3행의 사본 설명을 새 동작에 맞게 고친다.
  - 표 밖 지시 가운데 문자열로 검사할 수 없는 문장(불릿 범위, '것' 대신 이름, 기간 'N내', 제목의 개수, 수사)을 새 절 「지시형 지시」로 모으고, 예문에서 금지어 글자를 빼고 다시 쓴다. 꺼 둔 항목 문단은 검사기 쪽 기록이므로 옮기지 않는다.
  - `banned_guide` 를 구현한다. 생성은 복사와 같은 규칙을 따른다. 내용이 같으면 쓰지 않고, 옆 이름에 쓴 뒤 `mv` 로 바꾸며, 실패하면 ERROR 를 내고 뒤 단계를 이어 실행한다.
  - 옛 사본은 다른 블록이 import 하지 않을 때만 지운다. 이 사본은 scaffold 가 세션마다 원본으로 덮어써 온 생성물이고 원본이 플러그인 폴더에 남아 있으므로, 내용은 비교하지 않는다.
- [ ] **Step 4:** README 와 「지시문의 형태」를 고친다. 저장소 검사가 FAIL=0 이고 `claude plugin validate ./` 가 통과한다.
- [ ] **Step 5:** 측정 절차를 라벨 `step4` 로 따른다. 확인 기준은 아래와 같다.
  - `language` 행의 위반이 직전 상태보다 줄었다.
  - `eval_compare.sh baseline step4` 의 금지어 횟수가 `baseline` 이하다.

### Task 9: 단계 5 — 새 조항 후보

**Files:**
- Modify: `agent-principles.md`, `docs/domain-discipline.md`

- [ ] **Step 1:** spec 「결정」의 새 조항 후보를 하나씩 추가해 커밋하고, 커밋마다 측정 절차를 라벨 `step5-<후보 이름>` 으로 따른다. 확인 기준: 개발용 위반 합계가 직전 상태보다 적다.
- [ ] **Step 2:** 후보마다 채택·기각과 수치를 `docs/domain-discipline.md` 에 적는다. 확인: 모든 후보에 채택이나 기각 한 줄이 있다.

### Task 10: 저장소 규칙과 참조 정리

**Files:**
- Modify: `CLAUDE.md`(「조항 추가와 문구 변경」·「명령형」 항목, 30행의 절 이름)
- Modify: `README.md`(56·81행의 옛 절 이름), `hooks/doc_format_pretooluse.sh`, `skills/domain-readme/SKILL.md`, `skills/lens-readability/SKILL.md`, `skills/domain-pruning/SKILL.md`
- Modify: `docs/domain-discipline.md`, `docs/domain-korean.md`(절 구조를 새 층에 맞춤)

- [ ] **Step 1:** CLAUDE.md 를 spec 「저장소 규칙의 변경」의 나머지 항목대로 고친다. 회귀 시험 문장에는 `evals/principles/` 경로와 실행 명령(`bash scripts/eval_principles.sh HEAD dev <라벨>`, `bash scripts/eval_compare.sh baseline <라벨>`)을 함께 적는다. 확인: `grep -n "eval_principles.sh" CLAUDE.md` 가 줄을 낸다.
- [ ] **Step 2:** 확인: `grep -rn "「원칙」\|「출력지시」\|「검증」\|「문서를 쓰고 관리할 때」" --include=*.md --include=*.sh . | grep -v '^./docs/superpowers/'` 가 줄을 내지 않는다.
- [ ] **Step 3:** 이 PC 의 `~/.claude/CLAUDE.md` 에 다른 플러그인이 금지 표현 목록을 import 하는 줄이 있는지 확인해 사용자에게 알린다.
- [ ] **Step 4:** 저장소 검사가 FAIL=0 이고 `claude plugin validate ./` 가 통과한다. 그다음 커밋한다.

### Task 11: 최종 비교와 병합 준비

- [ ] **Step 1:** `git merge main` 으로 main 을 가져와 충돌을 해소한다. 확인: 저장소 검사가 FAIL=0 이다.
- [ ] **Step 2:** `bash scripts/eval_principles.sh 7a2d26d holdout baseline-holdout` 과 `bash scripts/eval_principles.sh HEAD holdout final-holdout` 을 실행하고 `eval_compare.sh baseline-holdout final-holdout` 으로 비교한다. 두 결과를 측정 기록에 추가해 커밋한다.
- [ ] **Step 3:** 측정 기록 전체와 최종 비교를 사용자에게 보고한다. 판정이 `개선` 일 때만 main 병합 승인을 묻는다. `동률` 이나 `악화` 면 병합하지 않고 결과와 선택지를 묻는다.
- [ ] **Step 4:** 병합한 뒤 이 plan 에 git 보존 태그를 달고 plan 을 지운다(에이전트원칙 문서 수명 표). 원자료 폴더 `~/dc-eval-raw/2026-10-18/` 를 지울지 사용자에게 묻는다.

<!-- spec-review: passed -->
