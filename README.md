# disciplined-coder

disciplined-coder 는 팀 엔지니어링 원칙을 모든 Claude Code 세션에 자동으로 실어 주는 플러그인이다. 이 원칙을 적은 파일이 에이전트원칙(`agent-principles.md`)이다. 플러그인은 에이전트원칙을 모든 프로젝트에 싣고, 문서를 쓰고 고칠 때 리뷰와 검진을 안내하며, 몇 가지 위험한 편집을 차단한다.

Claude Code 는 세션마다 지시를 새로 읽는다. 그래서 팀 원칙을 매번 붙여 넣지 않으면 세션마다 일하는 방식이 달라지고, 설계 문서가 리뷰 없이 다음 단계로 넘어가는지도 사람이 매번 확인해야 한다. 이 플러그인은 원칙 적재와 그 확인을 자동으로 한다.

chshin84 가 본인과 사내 한국어 사용자를 위해 만들었다. 그래서 플러그인은 한국어 금지 표현 목록(`korean-banned-words.md`)도 모든 세션에 싣는다.

## 켜면 달라지는 것

설치한 뒤 새 세션부터 아래 동작이 적용된다. 아래에서 spec 은 설계 문서, plan 은 실행 계획 문서를 뜻한다.

- **원칙** — 어느 프로젝트를 열든 세션에 에이전트원칙과 금지 표현 목록이 실리고, 프로젝트 폴더에는 파일이 생기지 않는다.
- **spec·plan 리뷰** — Claude 가 `docs/superpowers/specs/`나 `plans/`에 새 문서를 쓰고 리뷰 없이 턴을 끝내려 하면, 플러그인이 한 번 차단하고 리뷰를 지시한다.
- **나눠 맡길지 판단** — Claude 가 새 spec 을 처음 쓰려 하면, 플러그인이 한 번 거부하고 서브 세션(별도 Claude 세션)에 나눠 맡길지 먼저 판단하게 한다.
- **금지 표현** — Claude 가 `.md` 파일에 금지 표현을 쓰려 하면 플러그인이 쓰기를 거부하고 대체어를 보인다.
- **문서 안내** — Claude 가 새 문서를 만들거나 보고서·발표자료를 고치면, 플러그인이 문서 타입과 검진 절차를 알리고 문서 형식(라벨 불릿, 개수 예고)을 경고한다.
- **선행연구** — 사용자가 메시지에서 선행연구를 요청하면, 플러그인이 Claude 에게 선행연구 절차를 열라고 알린다.
- **읽기 전용 파일** — 플러그인이 읽기 전용 속성이 붙은 파일의 수정을 거부한다.
- **자동 갱신** — 새 버전이 있으면 플러그인이 세션 시작에 갱신하고 사용자에게 다시 켜라고 알린다.

## 설치

스코프는 user여야 모든 프로젝트에서 hook이 실행된다.

Windows는 [Git Bash](https://git-scm.com/downloads)를 먼저 설치한다. hook이 `bash`로 스크립트를 실행하기 때문이다.

자동 갱신, 금지 표현 검사, 문서 형식 경고에는 파이썬이 필요하다. 파이썬이 없으면 이 세 기능은 알림 없이 빠진다.

```text
/plugin marketplace add chshin84/disciplined-coder
/plugin install disciplined-coder@chshin-tools
```

## 동작 확인과 복구

새 세션을 한 번 열면 셋업이 끝난다. `/show-principles`를 실행해 원칙 목록이 나오면 정상이다.

목록이 안 나오면 원인은 아래 중 하나다.

**스코프** — 플러그인 스코프가 user가 아니다. 사용자가 터미널에서 `claude plugin install disciplined-coder@chshin-tools --scope user`로 다시 설치한다.

**셋업 오류** — 셋업이 원칙 복사나 연결에 실패했다. 셋업 결과는 세션 시작에 Claude 에게 전달되므로, 사용자는 Claude 에게 세션 시작 알림의 `ERROR` 줄을 보여 달라고 요청한다. `ERROR`가 있으면 새 세션을 열고, 또 나오면 그 메시지를 이슈로 올린다.

**설정 홈 불일치** — 회사 PC의 홈 리다이렉트로 bash의 `$HOME`과 Windows의 `USERPROFILE`이 다르면, 셋업이 다른 홈에 설치된다. 사용자는 실제 홈을 아래로 확인하고 새 세션을 열어 셋업을 다시 실행한다.

```bash
for d in "${CLAUDE_CONFIG_DIR:-}" "${USERPROFILE:+$USERPROFILE/.claude}" "$HOME/.claude"; do
  [ -n "$d" ] || continue
  [ -d "$d/disciplined-coder" ] && echo "셋업됨: $d" || echo "셋업 안 됨: $d"; break
done
```

## 커맨드

커맨드는 셸이 아닌 Claude Code 안에서 슬래시로 실행한다.

```text
/show-principles     # 적용 중인 원칙 보기
```

렌즈(문서를 한 관점에서 검토하는 읽기 전용 서브에이전트)는 에이전트로 실행한다. "이 보고서 적대적 검토 해 줘", "반박해 줘", "근거 확인", "가독성 봐 줘", "디자인 검토"처럼 요청하면 Claude 가 대상에 맞는 렌즈를 고른다. 프롬프트에 `@agent-disciplined-coder:lens-grounding` 처럼 이름을 직접 적어도 된다. 예전의 `/disciplined-coder:lens-*` 슬래시 명령은 없어졌다.

## 차단되었을 때 푸는 법

차단은 대개 Claude 가 거부 사유를 읽고 스스로 푼다. 사용자가 직접 할 일은 읽기 전용 속성 해제뿐이다.

**spec·plan 리뷰 차단** — Claude 가 리뷰를 마친 뒤 문서 마지막 줄에 `<!-- spec-review: passed -->` 마커(🔴가 남았으면 `<!-- spec-review: escalated -->`)를 두면 풀린다. 차단은 턴에 한 번이라 두 번째 종료 시도는 통과한다.

**금지 표현 차단** — Claude 가 거부 메시지의 대체어로 고친다. 그 말 자체를 적어야 하면 백틱으로 감싼다. 백틱과 코드 블록 안은 검사하지 않는다.

**나눠 맡길지 판단 차단** — Claude 가 맡기지 않기로 했으면 판단과 근거를 사용자에게 알린 뒤 같은 쓰기를 다시 실행한다. 두 번째 쓰기는 통과한다.

**읽기 전용 차단** — 사용자가 파일의 읽기 전용 속성을 풀면 풀린다.

## 끄는 법

아래 환경 변수를 Claude Code를 여는 셸에 두거나 `~/.claude/settings.json`의 `env`에 적는다.

- **`DISCIPLINED_CODER_REVIEW_GATE=off`** — spec·plan 리뷰, 나눠 맡길지 판단, 문서 안내의 검진 알림을 끈다.
- **`DISCIPLINED_CODER_REPLY_CHECK=off`** — 금지 표현 차단과 문서 형식 경고를 끈다.
- **`DISCIPLINED_CODER_PRIOR_ART_NUDGE=off`** — 선행연구 알림을 끈다.

읽기 전용 차단과 세션 시작의 셋업은 끄는 변수가 없다.

## 주의

플러그인을 쓸 때 오해하기 쉬운 점이다.

**superpowers** — 병렬 오케스트레이션에는 superpowers 플러그인이 필요하다. 없으면 플러그인이 세션 시작에 Claude 에게 설치 명령을 알린다.

**함께 설치하지 않을 플러그인** — `andrej-karpathy-skills`는 함께 설치하지 않기를 권한다. 비슷하지만 다른 지침이 겹쳐 실리기 때문이다.

## 더 읽기

에이전트원칙은 [`agent-principles.md`](agent-principles.md)이고, 상세는 `skills/` 아래 각 스킬이 소유한다. hook 연결은 `hooks/hooks.json`과 `.claude/settings.json`에 있고, hook마다 하는 일은 각 스크립트의 머리 주석이 적는다.

이슈는 [저장소](https://github.com/chshin84/disciplined-coder)에 올린다. 라이선스는 플러그인 매니페스트가 `UNLICENSED`로 선언한다.
