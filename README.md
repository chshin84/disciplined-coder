<div align="center">

# disciplined-coder

**사용자가 덜 읽고, 덜 판단하고, 되묻지 않아도 지시한 작업이 끝나게 하는 Claude Code 플러그인**

[![ci](https://github.com/chshin84/disciplined-coder/actions/workflows/ci.yml/badge.svg)](https://github.com/chshin84/disciplined-coder/actions/workflows/ci.yml)

설치 명령 두 줄 · 직접 고칠 설정 없음 · 모든 프로젝트에 자동 적용

</div>

## 왜 필요한가

Claude Code 는 유능하지만 세션마다 일하는 방식이 달라집니다. 지시했는데 진행 여부를 다시 묻고, 질문에는 묻지 않은 세부까지 길게 답합니다. 확인하지 않은 원인을 사실처럼 보고하고, 보고서에는 번역투 문장이 섞입니다. 그러면 사용자가 답을 끝까지 읽고 다시 확인해야 합니다.

disciplined-coder 는 Claude 가 일할 때 지킬 원칙을 정한 문서(에이전트원칙)를 모든 세션에 적용하고, 사용자 메시지마다 답의 형태를 짧게 다시 알립니다. Claude 는 대부분의 결정을 권장안대로 진행하고, 되돌릴 수 없는 행동이나 큰 비용이 드는 실행처럼 사용자가 정해야 하는 결정만 묻습니다.

원칙과 리마인더 문구는 지난 대화를 같은 지점까지 다시 실행해 두 버전의 답을 비교하는 시험으로 골랐습니다. v2 첫 버전은 사용자 메시지 106개 중 58개에서 이전 버전보다 나은 답을, 20개에서 나쁜 답을 냈습니다. 그 뒤 문구를 고친 내용은 격리된 환경에서 정해 둔 요청을 실행하는 시험으로만 확인했습니다. 측정 기록은 [`docs/domain-discipline.md`](docs/domain-discipline.md) 「v2 상시 지시 검증」에 있습니다.

## 빠른 시작

설치 전에 아래를 준비합니다.

- Windows 에서는 [Git Bash](https://git-scm.com/downloads)가 필요합니다. 플러그인이 `bash` 로 스크립트를 실행하기 때문입니다.
- 파이썬이 있어야 업데이트 확인, 자동 업데이트 설정, 금지 표현 알림이 동작합니다. 파이썬이 없으면 자동 업데이트 설정은 세션 시작에 그 사유를 알리고, 업데이트 확인과 금지 표현 알림은 알림 없이 빠집니다.

터미널에서 아래 두 줄을 실행합니다. `--scope user` 는 이 PC 의 모든 프로젝트에 플러그인을 적용한다는 뜻입니다.

```text
claude plugin marketplace add chshin84/disciplined-coder
claude plugin install disciplined-coder@chshin-tools --scope user
```

Claude Code 를 다시 열고 `/show-principles` 를 실행합니다. 적용 중인 원칙 전문이 나오면 설치가 끝났습니다.

설계 문서를 쓰는 작업은 [superpowers](https://github.com/obra/superpowers) 플러그인과 함께 쓰도록 맞춰져 있습니다. 아래 「함께 쓰는 플러그인」을 참고합니다.

## 이렇게 동작한다

Claude Code 를 열 때마다 플러그인이 원칙 사본과 금지 표현 목록을 PC 전역 폴더(`~/.claude/disciplined-coder/`)에 준비하고, 모든 프로젝트에 적용되도록 `~/.claude/CLAUDE.md` 에 연결합니다. 원본과 내용이 같으면 사본을 다시 쓰지 않습니다. 프로젝트 폴더에는 파일을 만들지 않습니다.

원칙은 세션을 시작할 때 한 번 전달되므로, 대화가 길어지면 Claude 가 덜 지킵니다. 그래서 사용자가 메시지를 보낼 때마다 아래 세 줄을 Claude 에게만 함께 보냅니다. 가장 자주 지적받은 세 가지입니다.

```text
- 사용자 메시지가 지시면 실행하고 결과만, 질문이면 물은 것만 답하라.
- 이 대화에서 네가 지은 약칭·번호·조항 이름은 풀어 쓰고, 사용자가 열 파일은 전체 경로로 적어라.
- 결정은 권장안대로 진행하고 결과에 적어라. 입력·출력의 정의, 되돌릴 수 없거나 밖으로 나가는 행동, 지시의 목적을 바꾸는 결정, 큰 비용·시간이 드는 실행, 사용자의 가치 판단이 필요한 결정만 먼저 물어라.
```

금지 표현은 번역투나 뜻이 흐린 한국어 낱말을 모은 목록이며, 저장소의 [`korean-banned-words.md`](korean-banned-words.md)에 대신 쓸 말과 함께 있습니다. 사용자가 작업하는 프로젝트에서 Claude 가 보고서(`.md`·`.html`)를 쓰다가 이 목록의 말을 넣으면, 쓰기가 끝난 뒤 Claude 에게 아래 알림이 갑니다. 쓰기를 거부하지는 않습니다. Claude 는 문장 전체가 자연스러우면 그대로 두고, 아니면 대체어로 고칩니다.

```text
disciplined-coder: 산출물 문서에 「금지 표현」 목록의 말이 있다. Write 로 쓴 파일 전체를 검사했다. 문장 전체가 자연스러우면 그대로 두고, 아니면 오른쪽 대체어로 고쳐라. 코드 블록과 백틱 안은 검사하지 않았다.

`부분` -> 가리키는 대상의 이름을 그대로 쓴다
`경우` -> 조건 · 상황
```

Claude 가 설계 문서나 작업 계획 문서를 새로 쓰면, 답을 마치기 전에 별도의 검토 에이전트(렌즈)로 그 문서를 리뷰하고 지적을 반영합니다. 리뷰가 진행되는 동안 답이 늦어질 수 있습니다.

## 주요 기능

| 기능 | 하는 일 |
|---|---|
| 원칙 자동 적용 | 어느 프로젝트를 열든 에이전트원칙과 금지 표현 목록을 세션에 적용합니다. |
| 답 형태 리마인더 | 사용자 메시지마다 위 세 줄을 Claude 에게 함께 보냅니다. |
| 금지 표현 알림 | 사용자 프로젝트의 `.md`·`.html` 산출물에 금지 표현이 들어가면 Claude 에게 대체어를 알립니다. |
| 설계 문서 리뷰 | 새로 쓴 설계 문서와 작업 계획 문서를 렌즈로 리뷰한 뒤에 답을 마치게 합니다. |
| 렌즈 검토 | 근거 확인, 반박, 가독성·화면 검토를 요청하면 별도의 검토 에이전트가 읽기만 하며 검토합니다. Claude 는 지적을 원문과 대조해 근거 없는 지적을 거른 뒤 반영합니다. |
| 선행연구 | 연구 계획을 쓰고 웹을 탐색한 뒤, 원문 구절로 확인한 인용만 모아 결론부터 보고합니다. |
| 좌우 비교 | 변경 전후나 두 답을 좌우로 나란히 놓은 HTML 페이지를 만들어 엽니다. |
| 읽기 전용 보호 | 읽기 전용 속성이 붙은 파일을 고치려 하면 거부하고 사유를 알립니다. |
| 자동 업데이트 | 새 버전이 나오면 세션 시작에 새 버전으로 업데이트하고, Claude Code 를 다시 시작하라고 알립니다. |

## 커맨드와 요청 예시

커맨드는 Claude Code 입력창에서 실행합니다.

```text
/show-principles     # 적용 중인 원칙 전문 보기
```

렌즈와 선행연구, 좌우 비교는 평소 말로 요청하면 Claude 가 알맞은 절차를 고릅니다. 설치 직후 아래 요청으로 시험해 볼 수 있습니다.

```text
이 README 가독성 봐 줘
이 설계 문서 적대적 검토 해 줘
이 보고서의 수치가 출처와 맞는지 근거 확인해 줘
이 제안서 결론에 반박해 줘
주문 재시도 정책의 선행 사례 찾아 줘
고치기 전과 후를 나란히 보여 줘
```

렌즈는 검토하는 방식에 따라 아래와 같이 나뉩니다.

| 렌즈 | 에이전트 | 하는 일 |
|---|---|---|
| 대조 | `lens-grounding` | 주장과 형식을 출처·코드·형식 규칙과 비교해 다른 점만 알립니다. |
| 설계 결함 | `lens-adversarial` | 실패할 수 있는 지점, 과한 설계, 되돌릴 수 없는 위험, 문서 안의 모순과 빠진 범위를 찾습니다. |
| 반대 근거 | `lens-rebuttal` | 주장에 반박 후보를 모으고, 데이터나 검색으로 뒷받침되는 반박만 알립니다. 웹 검색은 이 렌즈만 씁니다. |
| 독자 | `lens-readability` | 맥락을 모르는 독자로서 읽다가 이해가 멈추는 곳과 AI 가 쓴 티가 나는 문체를 찾습니다. 화면 산출물이면 배치·겹침·잘림도 봅니다. |

프롬프트에 `@agent-disciplined-coder:lens-grounding` 처럼 에이전트 이름을 직접 적어도 됩니다.

## 문제 해결

<details>
<summary><b>/show-principles 에 원칙이 나오지 않을 때</b></summary>

**설치 범위** — 플러그인이 한 프로젝트에만 설치되어 이 PC 전체(`--scope user`)에 적용되지 않았습니다. 터미널에서 `claude plugin install disciplined-coder@chshin-tools --scope user` 로 다시 설치합니다.

**준비 단계 오류** — 플러그인은 세션을 시작할 때마다 원칙 사본을 만들고 `~/.claude/CLAUDE.md` 에 연결하는 준비 단계를 자동으로 실행합니다. 이 단계의 결과는 Claude 에게 전달되므로, Claude 에게 세션 시작 알림의 `ERROR` 줄을 보여 달라고 요청합니다. `ERROR` 가 있으면 새 세션을 열고, 또 나오면 그 메시지를 이슈로 올립니다.

**설정 폴더 불일치** — 회사 PC 에서 홈 폴더가 네트워크 드라이브로 바뀌어 있으면 Git Bash 의 `$HOME` 과 Windows 의 `USERPROFILE` 이 달라, 준비 단계가 다른 폴더에 설치될 수 있습니다. Git Bash 에서 아래 명령을 실행해 실제로 쓰는 폴더를 확인하고, 새 세션을 열어 준비 단계를 다시 실행합니다.

```bash
for d in "${CLAUDE_HOME_DIR:-}" "${CLAUDE_CONFIG_DIR:-}" "${USERPROFILE:+$USERPROFILE/.claude}" "$HOME/.claude"; do
  [ -n "$d" ] || continue
  [ -d "$d/disciplined-coder" ] && echo "준비됨: $d" || echo "준비 안 됨: $d"; break
done
```

</details>

<details>
<summary><b>파일 수정이 거부될 때</b></summary>

파일에 읽기 전용 속성이 붙어 있으면 Claude 가 그 파일을 고치지 못합니다. 고쳐야 하는 파일이면 사용자가 그 파일의 읽기 전용 속성을 해제합니다. 그 밖의 리뷰 대기는 Claude 가 스스로 처리하므로 사용자가 할 작업이 없습니다.

</details>

<details>
<summary><b>끄거나 삭제하고 싶을 때</b></summary>

기능별로 끄는 설정은 없습니다. 잠시 끄려면 터미널에서 아래를 실행합니다. 다시 켜려면 `disable` 대신 `enable` 을 씁니다.

```text
claude plugin disable disciplined-coder@chshin-tools
```

완전히 삭제하려면 아래 두 줄을 실행합니다.

```text
claude plugin uninstall disciplined-coder@chshin-tools
claude plugin marketplace remove chshin-tools
```

삭제한 뒤에도 PC 전역 폴더 `~/.claude/disciplined-coder/` 와 `~/.claude/CLAUDE.md` 안의 연결 블록은 남습니다. 연결 블록은 `# BEGIN disciplined-coder (managed — do not edit)` 줄부터 `# END disciplined-coder (managed — do not edit)` 줄까지입니다. 이 블록을 지우고 폴더를 삭제하면 원칙이 적용되지 않습니다. 플러그인이 남아 있으면 다음 세션에서 둘 다 다시 만들어지므로, 플러그인을 먼저 삭제합니다.

</details>

## 함께 쓰는 플러그인

[superpowers](https://github.com/obra/superpowers) 플러그인과 함께 쓰도록 맞춰져 있습니다. 설치되어 있지 않으면 세션 시작에 Claude 가 설치 명령을 안내합니다. 설치하지 않기로 했으면 `~/.claude/disciplined-coder/plugin-notice.skip` 파일에 `superpowers` 한 줄을 적습니다. 그러면 안내가 더 나오지 않습니다.

`andrej-karpathy-skills` 는 함께 설치하지 않기를 권합니다. 비슷하지만 다른 지침이 겹쳐 적용되기 때문입니다.

## 더 읽기

에이전트원칙 원문은 [`agent-principles.md`](agent-principles.md)이고, 조항마다의 근거는 [`docs/domain-discipline.md`](docs/domain-discipline.md)(행동)와 [`docs/domain-korean.md`](docs/domain-korean.md)(출력)에 있습니다. 기능별 상세 절차는 `skills/` 폴더의 각 스킬 문서에, 자동 실행 스크립트 목록은 `hooks/hooks.json` 에 있고 스크립트마다 하는 일은 각 파일 첫머리 주석에 적혀 있습니다.

이 저장소를 고치는 개발자는 저장소의 [`CLAUDE.md`](CLAUDE.md)를 먼저 읽습니다. 원칙을 바꿀 때의 재현 시험 절차는 [`evals/replay/README.md`](evals/replay/README.md)에 있습니다.

chshin84 가 본인과 사내 한국어 사용자를 위해 만들었습니다. 문제나 제안은 [저장소 이슈](https://github.com/chshin84/disciplined-coder/issues)에 올립니다. 공개 라이선스는 없습니다(플러그인 매니페스트의 라이선스 값은 `UNLICENSED`).
