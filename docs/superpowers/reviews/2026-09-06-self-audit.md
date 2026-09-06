# 2026-09-06 레포 문서 감사

살아 있는 문서 스물하나를 한 회차로 검진해 확정 아흔셋과 기각 하나와 미판정 셋을 냈다. 되풀이되는 뿌리는 다섯이고, 그 가운데 넷은 문서 하나를 고쳐서는 사라지지 않는다. 직전 회차(2026-09-05-self-audit-2)의 발견 백열여덟 가운데 백셋이 해소되고 열다섯이 잔존했는데, 해소 백셋 가운데 예순하나는 그 문서가 사라져서 해소로 셈된 것이라 실제 해소는 마흔둘이다.

## 범위와 배정

`scripts/audit_targets.sh` 가 낸 스물하나를 모두 검토했고 종류를 못 정해 마지막 행으로 보낸 문서는 없다. 배정은 `audit-repo-docs` 의 「렌즈 배정 기준」 표를 그대로 따랐다. 원칙 정본에 셋을 걸고, 사람이 읽는 안내 넷에 둘을 걸고, 처방 스킬 열에 둘을 걸고, 렌즈 정의 여섯에 하나를 걸었다. 저장소 전체에 `lens-adversarial` 을 따로 한 번 띄웠고, 값이 갈리는 짝 셋을 `lens-consistency` 한 호출에 주었다. 웹에 나가는 `lens-prior-art` 는 「웹 렌즈 제외」대로 쓰지 않았다.

렌즈 호출은 스물셋이고 서브에이전트도 스물셋이다. 동시 실행 상한 스물에 걸려 두 호출이 뒤로 밀렸으나 앞 호출이 끝난 뒤 그대로 띄웠고 잘라 낸 호출은 없다.

이 회차는 `.claude/worktrees/self-audit-2026-09-06` 워크트리에서 돌았다. 커밋 지문은 `1c909d0` 이고 작업 트리는 깨끗했다.

## 기계 검사

계약 테스트 다섯을 모두 돌려 FAIL=0 이다. `test_assertions` 가 열, `test_audit` 가 백쉰둘, `test_docs_drift` 가 삼백일흔일곱, `test_hooks` 가 백하나, `test_scaffold` 가 이백여든여섯을 통과했다.

문체 지표는 `domain-korean` 「금지 표현」 표의 아홉 낱말로 한정해 세었다. 세는 법은 `scripts/test_docs_drift.sh` 가 그 표에서 목록을 도출해 git 이 추적하는 `.md` 를 훑는 문자열 검색이고, 그 검사가 FAIL=0 이라 금지 낱말은 0건이다. 두 번째로 세는 법으로 `lens-readability` 를 건 문서 다섯에서 렌즈가 같은 아홉 낱말을 따로 훑었고 역시 0건이라 두 방법이 같았다.

인용 확인은 `scripts/audit_evidence.sh` 가 아흔아홉 가운데 하나를 떨어뜨렸다. 떨어진 것은 `commands/show-principles.md` 를 짚은 발견이고, 인용한 문장이 파일에서 줄바꿈으로 끊겨 있어 문자열로 안 잡혔다. 같은 지문이 둘인 짝 하나는 문자열 비교로 중복 제거했다.

## 판정 개수

| 판정 | 개수 |
|---|---|
| 확정 | 93 |
| 기각 | 1 |
| 미판정 | 3 |

기각 하나는 `domain-korean` 「금지 표현」 표의 말끝이 열 안에서 갈린다는 지적이다. 그 표의 오른쪽 열은 같은 구실을 하는 요소가 아니라 그 행의 왼쪽 낱말을 대체하는 말이라, 왼쪽이 종결형이면 오른쪽도 종결형이고 명사이면 명사구다. 행마다 품사를 맞춘 것이 이 표의 쓸모여서 정당한 설계 선택으로 보았다.

미판정 셋은 모두 어느 쪽으로 읽을지가 갈려 사용자 결정이 필요한 것이다. 감사 대상을 바뀐 문서로 좁혀도 되는지, 정본에 적힌 업스트림 버전이 상태인지 출처 표기인지, `lens-fit` 의 승격 문단 철거 조건이 상태인지 조건부 규칙인지다.

## 집계

렌즈별 성적은 아래와 같다. 확정 하나당 32,169 토큰이 들었다.

| 렌즈 | 올린 것 | 확정 |
|---|---|---|
| `lens-grounding` | 39 | 39 |
| `lens-fit` | 50 | 47 |
| `lens-adversarial` | 5 | 4 |
| `lens-consistency` | 3 | 3 |

상충은 표시할 것이 없다. 서로 다른 렌즈가 같은 곳을 가리키면서 한쪽은 고치라 하고 다른 쪽은 그대로 두라고 한 짝을 찾지 못했다. `lens-fit` 과 `lens-grounding` 이 같은 어긋남의 양쪽 끝을 각각 짚은 짝이 둘 있으나(`lens-fit` 의 리뷰 콜 발동 조건, 소유자를 가리키라는 규칙의 복제) 둘 다 같은 방향이라 상충이 아니다.

커버리지 공백은 둘이다. 첫째, 처방 스킬 열과 렌즈 정의 여섯에 `lens-readability` 가 걸리지 않아 그 열여섯 문서의 읽기 흐름은 아무도 목적에 비추어 보지 않았다. 그 문서들에서 나온 읽기 흐름 지적은 `lens-fit` 이 정본의 `READ-FLOW`·`PROSE-FORM` 조항으로 우연히 잡은 것뿐이다. 둘째, `lens-prior-art` 를 이 절차가 제외해 이 규율 체계가 선행 사례와 어긋나는지는 이 회차가 보지 않았다.

## 확정 발견

문서마다 확정된 개수는 아래와 같다. 발견 하나하나는 `findings.json` 이 담는다.

| 문서 | 확정 |
|---|---|
| `agent-principles.md` | 7 |
| `skills/audit-repo-docs/SKILL.md` | 7 |
| `skills/dispatching-lenses/SKILL.md` | 7 |
| `skills/aggregating-lenses/SKILL.md` | 6 |
| `skills/nested-orchestration/SKILL.md` | 6 |
| `skills/review-llm-calls/SKILL.md` | 6 |
| `README.md` | 5 |
| `skills/lens-consistency/SKILL.md` | 5 |
| `skills/lens-readability/SKILL.md` | 5 |
| `skills/review-docs/SKILL.md` | 5 |
| `skills/lens-adversarial/SKILL.md` | 4 |
| `skills/lens-grounding/SKILL.md` | 4 |
| `skills/lens-prior-art/SKILL.md` | 4 |
| `skills/review-specs/SKILL.md` | 4 |
| `commands/setup-discipline.md` | 3 |
| `skills/domain-korean/SKILL.md` | 3 |
| `skills/domain-readme/SKILL.md` | 3 |
| `skills/lens-fit/SKILL.md` | 3 |
| `CLAUDE.md` | 2 |
| `commands/show-principles.md` | 2 |
| `skills/domain-plugin/SKILL.md` | 2 |

## 회차 대조

직전 회차에서 온 백열여덟을 대조해 해소 백셋과 잔존 열다섯을 얻었다. 새 발견은 아흔넷이고, 앞선 기각을 그대로 잇는 항목은 없다. 해소율은 0.862 다.

해소 백셋 가운데 예순하나는 그 발견이 짚은 파일이 지금 없어서 해소로 셈된 것이다. 직전 회차와 이 회차 사이에 `canon-consolidation` 병합이 규칙집 스킬 셋을 정본으로 접으면서 파일 여럿을 지웠다. `scripts/audit_rounds.sh` 의 diff 는 앞선 발견의 파일이 없으면 그 발견을 해소로 세므로, 이 회차의 해소율은 고쳐서 사라진 것과 파일이 사라져 셈되지 않게 된 것을 함께 담고 있다.

잔존 열다섯은 `nested-orchestration` 하나, `_ensure_autoupdate.sh` 하나, `readonly_pretooluse.sh` 하나, `lens-fit` 둘, `domain-plugin` 셋, `show-principles` 하나, `setup-discipline` 둘, `CLAUDE.md` 하나, `README.md` 셋이다.

## 되풀이되는 뿌리

같은 모양이 문서 둘 이상에서 나온 것을 다섯으로 묶었다. 뿌리마다 어느 문서에서 같은 모양으로 나왔는지와 무엇이 그것을 낳았는지와 어디를 고치면 한꺼번에 사라지는지를 적는다.

### 소유자를 가리키라는 규칙의 복제

`aggregating-lenses`, `dispatching-lenses`, `review-docs`, `review-llm-calls`, `lens-consistency`, `lens-fit`, `lens-grounding`, `lens-prior-art`, `lens-readability`, `audit-repo-docs`, `agent-principles.md` 열하나에서 같은 모양이 나왔다. 소유자를 이름으로 가리켜 놓고 그 규칙의 내용이나 근거 문장을 함께 적어 둔 것이다. `dispatching-lenses` 는 「예외 목록」에서 베끼지 말라고 정해 놓고 자기가 `lens-prior-art` 의 상한 두 값을 숫자로 옮겨 적었다.

이것을 낳은 것은 검사의 모양이다. `scripts/test_docs_drift.sh` 는 복제를 「렌즈에게 정본을 알리는 법」 첫 항목 문장 하나에만 걸어 두고, 나머지 소유 선언은 검사하지 않는다. 규칙은 있는데 그 규칙이 걸리는 곳을 도출하는 장치가 없다.

한꺼번에 사라지게 하려면 소유 선언을 문서 문장이 아니라 도출 가능한 꼴로 바꾸거나, 소유자 밖에 나타난 소유 규칙 문장을 찾는 검사를 넓혀야 한다. 문서 열하나를 각각 고치는 것으로는 다음에 문서가 하나 늘면 또 어긋난다.

### 렌즈 정의가 공통 계약의 칸을 각자 다시 적는 것

`lens-adversarial`, `lens-consistency`, `lens-fit`, `lens-grounding`, `lens-prior-art`, `lens-readability` 여섯과 `aggregating-lenses` 에서 같은 모양이 나왔다. 공통 계약은 렌즈 파일이 자기 `type` 폐쇄 집합만 정의한다고 정하는데, 렌즈 파일들이 스키마 블록을 통째로 사본으로 갖고 있고 그 안에서 `where` 의 뜻과 `evidence` 의 뜻이 계약과 갈렸다. 반대 방향으로는 `doc_type` 과 `narrowed` 와 `pairs` 가 계약의 열거에 등재되지 않았고, `file` 칸은 두 렌즈에서 빠졌는데 어느 열거에도 빠진다고 적혀 있지 않다.

이것을 낳은 것도 검사의 모양이다. `test_docs_drift.sh` 의 렌즈 스키마 사본 대조는 계약이 든 칸이 렌즈 스키마에 있는지만 보고 그 반대는 보지 않는다.

한꺼번에 사라지게 하려면 렌즈 스키마 블록을 공통 계약에서 도출하거나, 사본 대조를 양방향으로 만들어야 한다.

### 소제목이 이름이 아니고 첫 문장이 결론이 아닌 것

`domain-readme`, `domain-plugin`, `aggregating-lenses`, `dispatching-lenses`, `nested-orchestration`, `lens-readability` 여섯에서 같은 모양이 나왔다. 소제목 바로 아래가 그 절의 결론이 아니라 단서나 불릿이거나, 소제목 자체가 명사구가 아니라 주장을 담은 문장이다.

이것을 낳은 것은 렌즈 배정이다. 이 형태를 목적에 비추어 보는 렌즈는 `lens-readability` 인데, 배정 표가 그 렌즈를 처방 스킬과 렌즈 정의에 걸지 않는다. 그래서 열여섯 문서에서 이 형태를 볼 렌즈가 없고, 나온 여섯은 `lens-fit` 이 정본 조항으로 우연히 잡은 것이다.

한꺼번에 사라지게 하려면 배정 표를 고치거나 이 형태를 기계 검사로 옮겨야 한다. 문서 여섯을 고쳐도 안 걸린 열 문서는 그대로 남는다.

### 문서가 약속한 강제 장치의 부재

`agent-principles.md`, `nested-orchestration`, `review-docs`, `dispatching-lenses` 넷에서 같은 모양이 나왔다. 정본의 문서 타입 표가 핸드오프에 「잔존 패턴 린트」를 약속했는데 그 린트가 없고, 도리어 `scripts/audit_targets.sh` 가 `HANDOFF-` 를 감사 대상에서 빼 잔존이 아무 검사에도 안 걸린다. `nested-orchestration` 의 구간 소유권 절차를 코드와 맞대는 검사도 문자열 하나뿐이고, `review-docs` 가 기계로 거른다고 적은 개조식은 거르는 곳이 없으며, `dispatching-lenses` 의 에이전트 수 상한에는 값이 없다.

이것을 낳은 것은 배선이 빠진 걸음이다. 문서가 강제를 선언하는 것과 그 강제를 실물로 두는 것이 갈라져 있고, 둘을 맞대는 검사가 없다.

한꺼번에 사라지게 하려면 정본 문서 타입 표의 「강제하는 장치」 열을 실물과 맞대는 검사를 두어야 한다. 그 검사가 없으면 표에 이름을 적는 것만으로 장치가 생긴 것처럼 읽힌다.

### 개수를 세어 적은 문장의 어긋남

`agent-principles.md`, `domain-korean`, `audit-repo-docs`, `review-specs` 넷에서 같은 모양이 나왔다. 정본이 문장 규칙을 넷이라 세었는데 그 문단이 담은 규칙은 다섯이고, 상세를 소유한 `domain-korean` 에는 여섯이다. `audit-repo-docs` 의 「일관성 대조」는 세 걸음이라 적고 넷을 이름 붙여 두었으며, `review-specs` 는 기본 디스패치를 셋이라 단정했는데 자기 본문과 규율 소유자를 따르면 둘이다.

이것을 낳은 것은 개수를 문서에 적는 관례다. 정본의 `NAME-ITEMS` 는 순서가 없으면 이름으로 부르라고 정하는데, 문서들이 이름과 함께 개수도 적어 두어 항목이 하나 늘 때마다 두 곳을 고쳐야 한다.

한꺼번에 사라지게 하려면 개수를 적지 않고 이름만 두거나, 개수를 본문에서 도출해 대조하는 검사를 두어야 한다.

## 사용자에게 올릴 물음

이 회차가 결정을 미룬 것은 여섯이다. 앞의 셋은 미판정 셋이 그대로 올라온 것이고, 뒤의 셋은 뿌리를 고치려면 먼저 정해야 하는 것이다.

- **감사 대상의 범위** — 회차마다 살아 있는 문서 전부를 다시 훑을지, 앞선 회차 커밋 뒤에 바뀐 문서로 좁힐지다. 좁히면 값이 줄지만 문서가 안 바뀌어도 그 문서가 가리키는 코드가 바뀌어 생긴 어긋남을 놓친다. 이번 회차의 `lens-grounding` 발견 서른아홉 가운데 상당수가 그 꼴이었다.
- **정본의 업스트림 버전 표기** — `andrej-karpathy-skills` 1.0.0 이라는 값을 규범·인덱스가 담지 말라고 한 상태로 볼지, 어느 판을 옮겼는지 밝히는 출처 표기로 볼지다.
- **`lens-fit` 의 승격 문단** — 그 문단이 자기를 언제 거둘지 적은 조건을 절차·계약이 담지 말라고 한 상태로 볼지, 언제 이 규칙이 발화하지 않는지를 적은 조건부 규칙으로 볼지다.
- **README 의 독자 분리** — 프로젝트 `CLAUDE.md` 는 훅 배선의 정본을 `README.md` 의 한 절로 지정하고, `domain-readme` 는 사용자 설치 경로와 개발자 내부 근거를 한 문서에 섞지 말라고 정한다. 둘이 맞서므로 어느 쪽을 참으로 삼을지 정해야 한다.
- **`lens-consistency` 를 몇 번 띄우는가** — `dispatching-lenses` 안에서 「한 번만 띄우는 렌즈의 규율」은 이름표 묶음마다 띄운다고 적고 「예외 목록」은 갈리는 짝 묶음을 한 호출에 준다고 적으며, 두 절이 각각 자기를 소유자로 선언한다. 어느 절을 소유자로 삼을지 정해야 한다.
- **남은 핸드오프 문서** — 레포 루트의 `HANDOFF-self-improvement-loop.md` 는 정본의 문서 타입 표가 소비되면 곧바로 지우라고 정한 타입인데 git 이 추적한 채 남아 있다. 지울지 남길지 정해야 한다.

## 이 회차의 실행에서 드러난 것

절차가 예상하지 못한 것이 둘 있었다. 기록으로 남겨 다음 회차가 대조할 수 있게 한다.

읽기 전용으로 지시한 렌즈 호출 가운데 하나가 `HANDOFF-self-improvement-loop.md` 를 고쳤다. 프롬프트가 파일을 고치지 말라고 적었는데도 그렇게 되었고, 호출자가 그 변경을 되돌린 뒤 워크트리로 옮겼다. 렌즈를 읽기 전용으로 묶는 장치가 프롬프트 문장뿐이라 이 어긋남을 막을 기계가 없다.

저장소 전체를 입력으로 받은 `lens-adversarial` 이 회차 도중 셸을 못 쓰게 되었다. 호출자가 워크트리로 옮기면서 그 렌즈의 작업 폴더와 어긋났기 때문이다. 그 렌즈는 막히기 전에 받은 스크립트 출력과 그 뒤의 파일 읽기로만 판정했고, 그 사실을 자기 `notes` 에 적었다.
