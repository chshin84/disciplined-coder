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

| 항목 | 값 |
|---|---|
| eval 폴더 | `evals/principles/cases/`(현재 브랜치 HEAD 의 과제를 조건 worktree 와 무관하게 읽는다) |
| 과제 형식 | 과제 폴더마다 `prompt.md`(front matter 에 과제 머리, 본문에 프롬프트)와 `criteria.md`(판정 기준) |
| 생성 모델 | `claude-opus-5-5`(평가 설정 폴더의 기본 모델) |
| 판정 모델 | `claude-haiku-5-5`. `claude -p --model haiku` 에 판정 기준과 응답을 넣어 실행한다 |
| 실행 시간 | 예열 세션 15초, 과제 세션 15초 안팎 |
| 세션 비용 | 생성 세션 약 0.13달러 |

## 과제 구성

과제는 같은 상황의 짝 20개, 곧 40개다. 짝마다 기대 행동이 일어나야 하는 과제(`kind: should`)와 일어나지 말아야 하는 과제(`kind: should-not`)를 함께 둬서, 한쪽으로만 치우친 개선을 잡는다. 사례는 2026-10-18 세션 기록 분석 보고(약 300건)에서 뽑았고, 업무 수치·종목·사람 이름·회사명·사용자 메시지 원문은 일반화했다. 고유 이름이 필요한 과제는 지어낸 이름(BLUEFIN 등)을 쓴다.

| 구분 | 개수 |
|---|---|
| 개발용(`dev`) | 28 |
| 보류용(`holdout`) | 12(짝 6개: deliv-term, runit, first, keepfailed, label, natural) |
| 대화 답(`chat`) | 16 |
| 도구 실행 중 판단(`tool`) | 10 |
| 남에게 전달하는 산출물(`deliverable`) | 7 |
| 작업 문서(`workdoc`) | 4 |
| 코드(`code`) | 3 |

출력 종류의 비율은 세션 기록(대화 답 140, 도구 실행 중 판단 84, 작업 문서 32, 산출물 27, 코드 20)을 따르되, 형식 압력 충돌 쌍을 넣느라 산출물이 3개 많다. 실패 유형별로는 `language` 8, `confirm-loop` 10, `exclusion` 8, `format` 6, `assume` 2 이고, 충돌 쌍(`conflict:*`)과 새 조항 후보 공백(`candidate:*`)이 함께 붙는다.

평가 세션에서는 도구를 실행할 수 없으므로, 도구 과제(`tool`)는 프롬프트 끝에 '실행할 행동과 사용자에게 보낼 말을 적어라'를 넣고 그 서술로 판정한다. 여러 턴 과제는 앞 턴을 `[이전 대화]` 로 인용하고 마지막 메시지에 대한 응답만 판정한다(`judge: last-turn`).
