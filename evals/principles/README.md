# 에이전트원칙 실패 평가 세트

이 폴더는 에이전트원칙 개편(`docs/superpowers/specs/2026-10-18-principles-positive-restructure-design.md`)을 측정하는 과제와 결과를 둔다. 실행 명령은 `scripts/eval_principles.sh`, 비교 명령은 `scripts/eval_compare.sh` 다.

## 실행 도구

선택값은 `claude-p` 다. 2026-10-18 에 Claude Code 2.1.302 로 두 경로를 시험한 결과로 골랐다.

`claude plugin eval` 경로는 원칙 적재에서 실패했다. 이 명령은 실행마다 새 설정 폴더를 만들므로 매 세션이 관리블록을 처음 만드는 첫 세션이 된다. 그 세션에서 원칙은 SessionStart 훅의 첫 세션 보강으로만 실리는데, 하네스가 훅 출력을 앞 2KB 만 맥락에 넣고 나머지를 파일로 돌렸다. probe 과제의 응답은 "나머지 15KB가 저장된 파일은 읽기 권한이 거부되어 확인하지 못했습니다"였다. 과제 작업 폴더에 프로젝트 CLAUDE.md 를 두는 방법도 쓸 수 없다. 공식 문서(https://code.claude.com/docs/en/plugin-evals.md)가 scaffold_script 가 쓴 CLAUDE.md 를 싣지 않는다고 적기 때문이다. `append_system_prompt` 로 원칙 전문을 붙이면 probe 가 통과했지만, 실제 세션과 다른 경로라 고르지 않았다.

`claude-p` 경로의 확인 결과는 아래와 같다.

- 원칙 적재: 예열 세션 뒤의 세션이 원칙 파일 끝에 넣은 표지(`PROBE-A`)를 답했다.
- 조건 구분: 표지를 `PROBE-B` 로 바꾼 worktree 를 새 평가 설정 폴더에 설치하자 `PROBE-B` 를 답했다.
- 사본 대조: 평가 설정 폴더의 `disciplined-coder/agent-principles.md` 해시가 그 worktree 의 원칙 해시와 같았다.
- 격리: 실제 설정 파일 여섯 곳(`~/.claude/CLAUDE.md`, `~/.claude/disciplined-coder/*.md`, `settings.json`, `plugins/known_marketplaces.json`, `plugins/installed_plugins.json`)의 해시가 시험 전후로 같았다.

실패한 시도도 남긴다. 처음 probe 는 "응답 첫 줄에 PROBE-A 를 적어라"라는 지시였는데, 모델이 지시를 따르지 않아 원칙 적재와 지시 이행을 구분하지 못했다. 그래서 probe 를 "실린 지시 안의 PROBE- 표지 단어를 답하라"로 바꿨다. 임시 설정 폴더에는 로그인 정보가 없어 `Not logged in` 으로 끝났으므로, 인증은 API 키로 한다.

조건 하나의 준비는 아래 순서다. 모든 명령은 `CLAUDE_HOME_DIR` 을 비우고 `CLAUDE_CONFIG_DIR=<평가 설정 폴더>` 를 붙여 실행한다.

1. 빈 평가 설정 폴더를 만들고, 사용자 전역 `CLAUDE.md` 의 관리블록 밖 내용과 `kw-ax` 폴더를 복사한다. 모든 조건이 같은 사용자 지시를 받게 하기 위해서다.
2. `disciplined-coder/plugin-notice.skip` 에 `superpowers` 를 적는다. 평가 설정 폴더에는 superpowers 가 없어, 끄지 않으면 함께 쓰는 플러그인 알림이 응답에 섞인다.
3. `claude plugin marketplace add <그 커밋의 worktree>` 와 `claude plugin install disciplined-coder@chshin-tools` 를 실행한다.
4. `plugins/known_marketplaces.json` 의 chshin-tools 항목에 `"autoUpdate": false` 를 넣는다.
5. 예열 세션 `claude -p "확인용 예열입니다. ok 라고만 답하세요." --tools ""` 를 실행한다.

과제 세션은 `--tools ""` 로 도구를 끄고, git 저장소가 아닌 빈 작업 폴더에서 실행한다. 처음에는 빈 git 저장소에서 실행했는데, 하네스가 그 git 상태를 맥락에 넣자 모델이 과제의 작업 기록을 저장소 상태와 대조하려 했고 도구 호출문을 글로 적었다. 그래서 작업 폴더를 바꾸고, 모든 과제 앞에 '평가용 대화이고 도구는 쓸 수 없으며 이전 대화와 기록은 확인된 사실이다'라는 머리말을 뒀다. 판정 세션은 플러그인이 없는 빈 설정 폴더에서 실행한다. 판정 세션에 원칙이 실리면 조건마다 판정자가 달라지기 때문이다.

인증 키는 저장소 밖 `~/.dc-eval.env` 의 `ANTHROPIC_API_KEY` 줄에서 읽어 환경 변수로만 넘기고, 출력하거나 파일에 다시 쓰지 않는다. 사용료는 그 키의 API 계정으로 청구된다.

평가 폴더(작업 폴더와 설정 폴더)는 `EVAL_TMP`(기본 `/d/dc-eval-tmp`) 아래에 만든다. Claude Code 는 작업 폴더에서 위로 올라가며 `CLAUDE.md` 와 `.claude/CLAUDE.md` 를 싣기 때문이다. 2026-10-18 에 빈 설정 폴더로 측정해 보니, 사용자 홈 아래 `/tmp` 에서 실행한 세션은 실린 지시에 `~/.claude/CLAUDE.md` 의 관리블록이 있다고 답했고 D: 아래 폴더의 세션은 없다고 답했다. 그래서 두 실행 스크립트는 평가 폴더의 상위 경로에 그 파일이 있으면 실행하지 않는다. 실패 기록도 남긴다. Task 3 의 smoke 와 위 probe 는 사용자 홈 아래 `/tmp` 에서 실행했으므로 실제 사용자 지시가 함께 실렸을 수 있다. 그 결과는 측정 기록으로 쓰지 않았다.

## 클린룸 시험

조항별 시험은 `scripts/eval_clause.sh [<단위 이름>...]` 로 실행하고 `scripts/eval_clause_report.sh` 로 판정을 낸다. 시험 단위는 `clauses/<단위 이름>/` 폴더이고, `current.md`(현행 문안), `new.md`(변경안), 나눈 조항 쌍이면 `ids`(단위의 조항 ID)를 둔다. 조건마다 빈 설정 폴더에 그 파일 하나만 `CLAUDE.md` 로 넣고, 플러그인과 사용자 전역 지시는 넣지 않는다. 문구 변경은 `current`·`new`, 새 조항(`current.md` 없음)은 `none`·`new` 를 실행한다.

같은 질문은 같은 조건으로 한 번만 생성한다(2026-10-18 사용자 지시). 생성 키는 과제 본문과 조건 문안의 해시이고, 판정 키는 생성 키와 판정 기준의 해시다. 기록은 `results/clauses/gen.jsonl`(생성)과 `judge.jsonl`(판정)에 한 줄씩 덧붙인다. 생성 키가 기록에 있으면 생성하지 않고, 판정 키만 없으면 판정만 한다. 그래서 과제 머리를 바꾸거나 판정 기준을 고쳐도 생성은 반복되지 않는다. 생성 오류(`is_error` 응답, 빈 응답, 시간 초과)와 읽지 못한 판정은 기록하지 않고 `errors=` 로 센다.

2026-10-18 첫 전체 실행(생성 392건, 판정 392건, 오류 0건)은 haiku 로 판정했다. 판정이 갈린 질문을 읽어 보니 판정 모델의 오판이 섞여 있었다. TITLE-LAYERS 의 두 조건 응답은 같은 절 제목을 썼는데 한쪽만 위반이었고, BALANCE·STATUS-FIRST 의 판정 이유는 '기준을 지켰다'고 쓰면서 위반으로 기록됐다. 그래서 판정 모델을 sonnet 으로 바꾸고, 판정 키에 판정 모델을 넣어 생성은 다시 하지 않고 판정만 새로 했다. haiku 판정 기록은 `judge.jsonl` 에 그대로 남는다(키가 달라 보고에 쓰이지 않는다).

2026-10-18 smoke 는 픽스처 과제 하나로 아래를 확인했다. 첫 실행에서 생성 2건과 판정 2건을 기록했고, 같은 명령을 다시 실행하자 새 기록이 0건이었다. 틀린 API 키로 실행하자 `Invalid API key` 를 오류 1건으로 세고 기록을 늘리지 않았다. 실제 설정 지문은 실행 전후로 같았다.

| 항목 | 값 |
|---|---|
| eval 폴더 | `evals/principles/cases/`(현재 브랜치 HEAD 의 과제를 조건 worktree 와 무관하게 읽는다) |
| 과제 형식 | 과제 폴더마다 `prompt.md`(front matter 에 과제 머리, 본문에 프롬프트)와 `criteria.md`(판정 기준) |
| 생성 모델 | `claude-opus-5-5`. 함께 쓰는 결과가 다른 모델과 섞이지 않게 `--model` 로 고정한다 |
| 판정 모델 | `claude-sonnet-5-5`. `claude -p --model claude-sonnet-5-5` 에 판정 기준과 응답을 넣어 실행한다. 처음에는 haiku 였다(「클린룸 시험」 절) |
| 실행 시간 | 예열 세션 15초, 과제 세션 15초 안팎 |
| 세션 비용 | 생성 세션 약 0.13달러 |

## 과제 구성

과제는 두 출처에서 왔다. 첫째는 세션 기록 분석 보고(2026-10-18, 약 300건)에서 뽑은 짝 20개, 곧 40개다. 둘째는 조항별 클린룸 시험에 쓰려고 시험 단위마다 추가한 질문 150개(`q-<단위>-<번호>`)다. 둘째 묶음은 `current.md` 가 다루는 상황과 변경안 초안 이유 칸의 실패 사례에서 만들었고, `new.md` 의 문장은 쓰지 않았다. 과제마다 기대 행동이 일어나야 하는 과제(`kind: should`)와 일어나지 말아야 하는 과제(`kind: should-not`)를 짝으로 두어, 한쪽으로만 치우친 개선을 잡는다. 시험 단위의 질문이 3개가 되도록 추가한 셋째 질문은 짝이 없다. 업무 수치·종목·사람 이름·회사명·사용자 메시지 원문은 일반화했고, 고유 이름이 필요한 과제는 지어낸 이름(BLUEFIN 등)을 쓴다.

| 구분 | 개수 |
|---|---|
| 개발용(`dev`) | 178 |
| 보류용(`holdout`) | 12(짝 6개: deliv-term, runit, first, keepfailed, label, natural) |
| 대화 답(`chat`) | 77 |
| 도구 실행 중 판단(`tool`) | 47 |
| 남에게 전달하는 산출물(`deliverable`) | 31 |
| 작업 문서(`workdoc`) | 21 |
| 코드(`code`) | 14 |

처음 40개의 출력 종류 비율은 세션 기록(대화 답 140, 도구 실행 중 판단 84, 작업 문서 32, 산출물 27, 코드 20)을 따랐다. 추가한 150개는 시험 단위의 조항이 다루는 출력 종류를 따른다. 보류용 12개는 클린룸 시험에 쓰지 않고 전체 비교에만 쓴다.

평가 세션에서는 도구를 실행할 수 없으므로, 도구 과제(`tool`)는 프롬프트 끝에 '실행할 행동과 사용자에게 보낼 말을 적어라'를 넣고 그 서술로 판정한다. 여러 턴 과제는 앞 턴을 `[이전 대화]` 로 인용하고 마지막 메시지에 대한 응답만 판정한다(`judge: last-turn`).

동률 단위에 추가한 질문 84개(`q-<단위>-f1`·`f2`, `followup: true`)는 위 표의 개수에 들어 있지 않다.

## 측정 기록

2026-10-18 조항별 클린룸 시험의 결과다. 시험 단위 56개를 개발용 질문(단위마다 3~8개)으로 비교했고, 동률 단위 42개에는 질문 짝을 한 번 추가했다. 생성은 모두 560건이고 같은 질문을 같은 조건으로 두 번 생성하지 않았다. 판정 모델은 sonnet 이다. 단위마다의 수치는 `docs/domain-discipline.md`·`docs/domain-korean.md` 의 조항 절과 `bash scripts/eval_clause_report.sh` 의 출력이 소유한다.

| 판정 | 단위 수 | 단위 |
|---|---|---|
| 채택 | 11 | ASK-OPTIONS, COMMA-CUT, LABEL-NOUN, NO-MID-MOD, ONE-IDEA, SECTION-HEAD, SUBJECT-OBJECT, TERM-ONE, TITLE-CLAIM, TITLE-PROOF, WRITTEN-ONLY |
| 넣음(새 조항) | 1 | INSTRUCTION-FORM(질문 4개, 조항 없음 위반 1건, 변경안 0건. 참고서의 절은 원칙에 조항을 넣을 때 함께 만든다) |
| 채택(차이없음) | 36 | 나머지 단위. 동률 뒤 추가 질문에서도 같아, 측정이 차이를 잡지 못한 채택이다 |
| 기각 | 8 | BOTTOM-LINE, CHECKABLE, EDIT-PRIORITY, NO-SQUEEZE, REVERSIBLE, RUN-IT, TERM-EXPLAIN, VOCAB-PREF. 모두 질문 한두 개의 차이이며, 판단 조항이라 처리를 사용자에게 묻는다 |

사용자 확인 일치도는 아직 기록하지 않았다. 판정 표본을 사용자에게 보이는 단계가 남아 있다.
