<div align="center">

# disciplined-coder

**Claude Code 가 어느 세션에서든 같은 원칙으로 일하게 만드는 플러그인**

[![ci](https://github.com/chshin84/disciplined-coder/actions/workflows/ci.yml/badge.svg)](https://github.com/chshin84/disciplined-coder/actions/workflows/ci.yml)

설치 명령 두 줄 · 설정 파일 수정 없음 · 모든 프로젝트에 자동 적용

</div>

## 왜 필요한가

Claude Code 는 유능하지만 세션마다 일하는 방식이 달라진다. 어제 세션은 설계를 리뷰한 뒤 구현했는데, 오늘 세션은 리뷰 없이 바로 코드를 쓴다. 확인하지 않은 원인을 사실처럼 보고하고, 보고서에는 번역투 문장이 섞인다.

팀 규칙을 CLAUDE.md 에 적어 두어도 문제는 남는다. 프로젝트마다 규칙을 복사해야 하고, Claude 가 규칙을 지켰는지는 사람이 매번 확인해야 한다.

disciplined-coder 는 그 확인을 훅에 맡긴다. 원칙은 모든 세션에 자동으로 실리고, 원칙을 어기는 동작은 실행 시점에 차단된다. 차단되면 Claude 가 거부 사유를 읽고 스스로 고친다.

## 빠른 시작

Claude Code 안에서 아래 두 줄을 실행한다.

```text
/plugin marketplace add chshin84/disciplined-coder
/plugin install disciplined-coder@chshin-tools
```

새 세션을 열고 `/show-principles` 를 실행한다. 적용 중인 원칙 목록이 나오면 설치가 끝났다.

플러그인은 user 스코프로 설치해야 모든 프로젝트에서 훅이 실행된다. 설계 단계는 [superpowers](https://github.com/obra/superpowers) 플러그인 위에서 동작하므로 함께 설치한다.

Windows 에서는 [Git Bash](https://git-scm.com/downloads)가 필요하다. 훅이 `bash` 로 스크립트를 실행하기 때문이다. 자동 갱신, 금지 표현 검사, 문서 형식 경고는 파이썬을 쓰고, 파이썬이 없으면 이 세 기능만 알림 없이 빠진다.

## 이렇게 동작한다

Claude 가 보고서를 쓰다가 금지 표현을 넣으면 쓰기가 거부된다. 아래는 실제 거부 메시지다. Claude 는 이 메시지를 읽고 대체어로 고쳐 다시 쓴다.

```text
이 문서에 「금지 표현」 목록의 말이 들어 있다. 아래를 대체어로 고쳐 다시 써라.

부분 -> 가리키는 대상의 이름을 그대로 쓴다
경우 -> 조건 · 상황
```

Claude 가 `docs/superpowers/specs/` 에 설계 문서(spec)를 쓰고 리뷰 없이 턴을 끝내려 하면, 턴 종료가 한 번 차단된다. Claude 는 독립된 검토 에이전트(렌즈)로 설계 문서를 리뷰하고, 지적을 반영한 뒤에 턴을 끝낸다.

## 주요 기능

플러그인은 원칙을 싣는 일부터 결과물을 검토하는 일까지 아래 기능을 맡는다.

| 기능 | 하는 일 |
|---|---|
| 원칙 자동 적재 | 어느 프로젝트를 열든 에이전트원칙과 한국어 금지 표현 목록을 세션에 싣는다. 프로젝트 폴더에는 파일을 만들지 않는다. |
| 설계 리뷰 관문 | `docs/superpowers/specs/`·`plans/` 에 쓴 새 문서가 리뷰 없이 다음 단계로 넘어가지 않게 한다. |
| 작업 분할 판단 | 새 spec 을 처음 쓰기 전에 서브 세션에 나눠 맡길지 먼저 판단하게 한다. |
| 한국어 문장 검사 | `.md` 산출물에 금지 표현이 들어가면 쓰기를 거부하고 대체어를 보인다. |
| 문서 안내 | 새 문서를 만들거나 보고서·발표자료를 고치면 문서 타입과 검진 절차를 알리고, 라벨 불릿과 개수 예고를 경고한다. |
| 렌즈 검토 | 적대적 검토, 반박, 근거 확인, 가독성, 디자인 검토를 읽기 전용 서브에이전트로 실행한다. |
| 선행연구 | 선행연구를 요청하면 연구 계획을 쓰고 웹을 탐색한 뒤, 인용 검증을 통과한 출처만 모은다. |
| 읽기 전용 보호 | 읽기 전용 속성이 붙은 파일의 수정을 거부한다. |
| 자동 갱신 | 새 버전이 있으면 세션 시작에 갱신하고 다시 켜라고 알린다. |

## 커맨드와 요청 예시

커맨드는 셸이 아닌 Claude Code 안에서 슬래시로 실행한다.

```text
/show-principles     # 적용 중인 원칙 보기
```

렌즈와 선행연구는 평소 말로 요청하면 Claude 가 알맞은 절차를 고른다. 설치 직후 아래 요청으로 시험해 볼 수 있다.

```text
이 README 가독성 봐 줘
이 설계 문서 적대적 검토 해 줘
이 보고서의 수치가 출처와 맞는지 근거 확인해 줘
주문 재시도 정책에 대한 선행연구 찾아 줘
```

프롬프트에 `@agent-disciplined-coder:lens-grounding` 처럼 렌즈 이름을 직접 적어도 된다.

## 문제 해결

<details>
<summary><b>/show-principles 에 원칙 목록이 나오지 않을 때</b></summary>

**스코프** — 플러그인 스코프가 user 가 아니다. 터미널에서 `claude plugin install disciplined-coder@chshin-tools --scope user` 로 다시 설치한다.

**셋업 오류** — 셋업이 원칙 복사나 연결에 실패했다. 셋업 결과는 세션 시작에 Claude 에게 전달되므로, Claude 에게 세션 시작 알림의 `ERROR` 줄을 보여 달라고 요청한다. `ERROR` 가 있으면 새 세션을 열고, 또 나오면 그 메시지를 이슈로 올린다.

**설정 홈 불일치** — 회사 PC 의 홈 리다이렉트로 bash 의 `$HOME` 과 Windows 의 `USERPROFILE` 이 다르면 셋업이 다른 홈에 설치된다. 아래 명령으로 실제 홈을 확인하고 새 세션을 열어 셋업을 다시 실행한다.

```bash
for d in "${CLAUDE_CONFIG_DIR:-}" "${USERPROFILE:+$USERPROFILE/.claude}" "$HOME/.claude"; do
  [ -n "$d" ] || continue
  [ -d "$d/disciplined-coder" ] && echo "셋업됨: $d" || echo "셋업 안 됨: $d"; break
done
```

</details>

<details>
<summary><b>차단이 풀리지 않을 때</b></summary>

차단은 대개 Claude 가 거부 사유를 읽고 스스로 푼다. 사용자가 직접 할 일은 읽기 전용 속성 해제뿐이다.

**spec·plan 리뷰 차단** — Claude 가 리뷰를 마친 뒤 문서 마지막 줄에 `<!-- spec-review: passed -->` 마커(🔴가 남았으면 `<!-- spec-review: escalated -->`)를 두면 풀린다. 차단은 턴에 한 번이라 두 번째 종료 시도는 통과한다.

**금지 표현 차단** — Claude 가 거부 메시지의 대체어로 고친다. 그 말 자체를 적어야 하면 백틱으로 감싼다. 백틱과 코드 블록 안은 검사하지 않는다.

**작업 분할 판단 차단** — Claude 가 맡기지 않기로 했으면 판단과 근거를 사용자에게 알린 뒤 같은 쓰기를 다시 실행한다. 두 번째 쓰기는 통과한다.

**읽기 전용 차단** — 사용자가 파일의 읽기 전용 속성을 풀면 풀린다.

</details>

<details>
<summary><b>기능을 끄고 싶을 때</b></summary>

아래 환경 변수를 Claude Code 를 여는 셸에 두거나 `~/.claude/settings.json` 의 `env` 에 적는다.

| 변수 | 끄는 기능 |
|---|---|
| `DISCIPLINED_CODER_REVIEW_GATE=off` | 설계 리뷰 관문, 작업 분할 판단, 규칙 위치 안내, 문서 안내의 검진 알림 |
| `DISCIPLINED_CODER_REPLY_CHECK=off` | 금지 표현 차단과 문서 형식 경고 |
| `DISCIPLINED_CODER_PRIOR_ART_NUDGE=off` | 선행연구 알림 |
| `DISCIPLINED_CODER_REPLY_REMINDER=off` | 사용자 메시지마다 붙는 대화 답 형태 지시(세 줄) |

읽기 전용 보호와 세션 시작의 셋업은 끄는 변수가 없다.

</details>

## 함께 쓰는 플러그인

병렬 오케스트레이션에는 [superpowers](https://github.com/obra/superpowers) 플러그인이 필요하다. 없으면 세션 시작에 Claude 가 설치 명령을 안내한다.

`andrej-karpathy-skills` 는 함께 설치하지 않기를 권한다. 비슷하지만 다른 지침이 겹쳐 실리기 때문이다.

## 더 읽기

에이전트원칙은 [`agent-principles.md`](agent-principles.md)이고, 상세는 `skills/` 아래 각 스킬이 소유한다. 훅 연결은 `hooks/hooks.json` 과 `.claude/settings.json` 에 있고, 훅마다 하는 일은 각 스크립트의 머리 주석이 적는다.

chshin84 가 본인과 사내 한국어 사용자를 위해 만들었다. 이슈는 [저장소](https://github.com/chshin84/disciplined-coder/issues)에 올린다. 라이선스는 플러그인 매니페스트가 `UNLICENSED` 로 선언한다.
