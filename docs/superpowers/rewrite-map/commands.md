# 대응표 — 커맨드 다섯 개 (frontmatter만)

> **되돌린 작업의 기록이다(superseded).** 이 표는 정본과 스킬 문서를 영문으로 다시 쓰는 회차에서
> 만들었고, 그 재작성은 되돌려졌다 — 정본은 지금도 한국어다. 그래서 「새 문서 위치」 칸은 그때의
> 영문 문서를 가리키며 지금의 문서 구조가 아니다. 무엇을 왜 옮기고 지웠는지의 판단만 쓸모가 있어
> 남겨 두는 것이니, 지금 문서를 찾을 때 이 표를 따라가지 마라.

원문의 각 항목이 새 문서 어디로 갔는지, 지웠다면 왜 지웠는지 남긴다.
'지움' 항목과 빈칸이 사람이 검토할 대상이다.

세 번째 칸의 값은 `옮김`, `합침`, `**지움**`, `신설` 중 하나이며 지움에는 반드시 근거를 붙인다.

**범위는 frontmatter의 `description` 한 줄뿐이다.** 본문은 계획의 전역 제약("본문이 곧 사용자에게
보이는 출력을 규정하는 지시문")에 따라 한국어 그대로 두었고 이 대응표에도 담지 않는다 — 본문을 손대지
않았다는 사실은 아래 "검증" 절에서 diff로 확인했다.

**지움은 없다. 합침도 신설도 없다.** 다섯 파일 모두 원문 `description`의 모든 절과 괄호 부연이
영문 후보에 그대로 있다. `PC 전역`은 다섯 파일 모두에서 `machine-wide`로 일관되게 옮겼는데, 이는
새로 지어낸 용어가 아니라 이미 영문화된 정본 `agent-principles.md`의 `Solved Log` 절이 쓰는
"A machine-wide lesson goes to the PC log" 표현과 대조해 확인한 기존 용어다. `디시플린 정본`도
정본화된 `skills/domain-docs/SKILL.md:86`의 "the detailed canon behind..."에서 이미 쓰인 `canon`을
그대로 가져왔다 — 두 용어 모두 이 태스크에서 처음 지어낸 것이 아니라 앞선 태스크가 정착시킨 어휘를
재사용한 것이라 대응표 밖에서 근거를 남긴다.

## commands/setup-discipline.md

원문: `PC 전역(~/.claude/disciplined-coder/)을 셋업한다 — solved 오답노트를 없을 때만 생성하고,
디시플린 정본(agent-principles.md·domains-index.md)을 복사·갱신하며, ~/.claude/CLAUDE.md의 @import
블록을 재생성한다(멱등).`

| 원문 항목 | 새 문서 위치 | 처리와 근거 |
|---|---|---|
| `PC 전역(~/.claude/disciplined-coder/)을 셋업한다` | 첫 절 | 옮김 — `machine-wide`와 경로를 그대로 남겼다 |
| `—` (긴 대시로 이어지는 세 동작 나열) | 문장 구조 | 옮김 — 같은 em dash로 유지했다 |
| `solved 오답노트를` | 첫 동작의 목적어 | 옮김 — `the solved log` |
| `없을 때만 생성하고` | 첫 동작 | 옮김 — '없을 때만'이라는 조건 한정을 `only if it does not already exist`로 남겼다. 이 한정이 빠지면 매 실행마다 새로 만드는 것처럼 읽혀 `IDEMPOTENT`와 어긋난다 |
| `디시플린 정본(agent-principles.md·domains-index.md)을` | 둘째 동작의 목적어 | 옮김 — `the discipline canon`과 괄호 안 파일명 둘을 그대로 남겼다 |
| `복사·갱신하며` | 둘째 동작 | 옮김 — 두 동사 `복사`와 `갱신`을 `copies and refreshes`로 모두 남겼다. 하나로 합치면 "이미 있으면 손대지 않는다"는 뜻으로 오해될 수 있어 갱신 동작이 사라진다 |
| `~/.claude/CLAUDE.md의 @import 블록을` | 셋째 동작의 목적어 | 옮김 — 경로와 `@import` 표기를 그대로 남겼다 |
| `재생성한다` | 셋째 동작 | 옮김 — `regenerates` |
| `(멱등)` | 문장 끝 괄호 | 옮김 — `(idempotent)`. `IDEMPOTENT` 원칙 ID와 어휘가 맞아떨어지는지 정본과 대조했다 |

## commands/show-principles.md

원문: `PC 전역 agent-principles.md(현재 활성화된 디시플린 정본 사본)를 읽어 그대로 보여준다.`

| 원문 항목 | 새 문서 위치 | 처리와 근거 |
|---|---|---|
| `PC 전역 agent-principles.md` | 문장 앞부분 | 옮김 — `the machine-wide agent-principles.md` |
| `(현재 활성화된 디시플린 정본 사본)` | 괄호 부연 | 옮김 — '현재 활성화된'과 '사본'이라는 두 한정을 `the currently active copy of the discipline canon`으로 모두 남겼다. '사본'이 빠지면 이 파일이 정본 원본(레포 루트의 것)인 것처럼 읽혀 SSOT 소재가 흐려진다 |
| `를 읽어` | 동사 1 | 옮김 — `reads` |
| `그대로 보여준다` | 동사 2 | 옮김 — `shows it verbatim`. '그대로'라는 한정(가공·요약 없이)을 `verbatim`으로 남겼다 |

## commands/show-solved.md

원문: `PC 전역 solved_problems.md(해결된 문제 로그)를 읽어 그대로 보여준다.`

| 원문 항목 | 새 문서 위치 | 처리와 근거 |
|---|---|---|
| `PC 전역 solved_problems.md` | 문장 앞부분 | 옮김 — `the machine-wide solved_problems.md` |
| `(해결된 문제 로그)` | 괄호 부연 | 옮김 — `(the log of solved problems)` |
| `를 읽어` | 동사 1 | 옮김 — `reads` |
| `그대로 보여준다` | 동사 2 | 옮김 — `shows it verbatim` |

## commands/issue-mode.md

원문: `오답노트 미해결 처분 모드를 surface(기본 — 메모리+사용자 surface)와 issues(must-keep을 GitHub
Issues에 위임) 사이에서 토글한다. 인자가 없으면 현재 모드를 표시한다. PC 전역이며 다음 세션부터
적용된다.`

| 원문 항목 | 새 문서 위치 | 처리와 근거 |
|---|---|---|
| `오답노트 미해결 처분 모드를` | 첫 문장 목적어 | 옮김 — `오답노트`(solved log)와 `미해결`(unresolved items)과 `처분 모드`(disposal mode) 세 요소를 모두 `the disposal mode for unresolved items in the solved log`로 남겼다. 하나라도 빠지면 "무엇의 모드인가"가 불분명해진다 |
| `surface(기본 — 메모리+사용자 surface)와` | 첫 갈래 | 옮김 — `기본`(default)과 목적지 둘(메모리+사용자)을 모두 `surface (default — surfaces to memory and the user)`로 남겼다 |
| `issues(must-keep을 GitHub Issues에 위임) 사이에서` | 둘째 갈래 | 옮김 — 대상(`must-keep`)과 위임처(`GitHub Issues`)를 모두 `issues (delegates must-keep items to GitHub Issues)`로 남겼다 |
| `토글한다` | 첫 문장 동사 | 옮김 — `toggles ... between` |
| `인자가 없으면 현재 모드를 표시한다` | 둘째 문장 | 옮김 — 조건('인자가 없으면')과 동작(현재 모드 표시)을 모두 `shows the current mode when called with no argument`로 남겼다 |
| `PC 전역이며` | 셋째 문장 앞 | 옮김 — `machine-wide` |
| `다음 세션부터 적용된다` | 셋째 문장 끝 | 옮김 — '다음 세션부터'라는 시점 한정을 `starting the next session`으로 남겼다. 이게 빠지면 토글이 즉시 적용되는 것처럼 읽혀 사실과 어긋난다 |

## commands/ultracode-review.md

원문: `ultracode(멀티에이전트 워크플로) 검증 모드를 required(워크플로에 reviewer-* 렌즈 검증 단계
필수)와 discretion(기본 — 리스크 비례 재량, 보고서에 검증 내역 명시) 사이에서 토글한다. 인자가 없으면
현재 모드를 표시한다. PC 전역이며 다음 세션부터 적용된다.`

| 원문 항목 | 새 문서 위치 | 처리와 근거 |
|---|---|---|
| `ultracode(멀티에이전트 워크플로) 검증 모드를` | 첫 문장 목적어 | 옮김 — `ultracode`와 괄호 부연 `multi-agent workflows`, `검증 모드`(verification mode) 모두 남겼다 |
| `required(워크플로에 reviewer-* 렌즈 검증 단계 필수)와` | 첫 갈래 | 옮김 — 위치('워크플로에')와 대상(`reviewer-*` 렌즈 검증 단계)과 강도('필수')를 모두 `required (a reviewer-* lens verification step is mandatory in the workflow)`로 남겼다 |
| `discretion(기본 — 리스크 비례 재량, 보고서에 검증 내역 명시) 사이에서` | 둘째 갈래 | 옮김 — `기본`(default)과 재량의 성격('리스크 비례')과 보고 의무('보고서에 검증 내역 명시') 세 요소를 모두 `discretion (default — risk-proportionate discretion, with verification details noted in the report)`로 남겼다. 셋째 요소(보고 의무)가 빠지면 재량 모드가 아무 흔적도 안 남기는 것처럼 읽힌다 |
| `토글한다` | 첫 문장 동사 | 옮김 — `toggles ... between` |
| `인자가 없으면 현재 모드를 표시한다` | 둘째 문장 | 옮김 — `shows the current mode when called with no argument` |
| `PC 전역이며` | 셋째 문장 앞 | 옮김 — `machine-wide` |
| `다음 세션부터 적용된다` | 셋째 문장 끝 | 옮김 — `takes effect starting the next session` |

## 검증

- **frontmatter YAML 파싱**: 스크래치패드에 설치한 `js-yaml`과 `yaml` 두 파서로 다섯 파일의
  frontmatter를 각각 파싱했다 — `yaml.errors=0`, 두 파서가 뽑은 `description` 값이 바이트 단위로
  일치(`parsersAgree=true`), 값 안에 한글이 전혀 없음(`isEnglishOnly=true`)을 확인했다. 콜론+공백이
  없어 엄격 YAML 파서에서도 안전하다.
- **본문 무변경**: 이 대응표를 쓴 직후 `git diff commands/`를 실행해 다섯 파일 모두 `---` 사이
  `description` 줄 하나씩만 바뀌고(각 파일 1 insertion, 1 deletion) 본문 줄은 하나도 바뀌지 않았음을
  직접 확인했다. 그 diff는 이 태스크의 커밋(`refactor(commands): ...`) 안에 그대로 들어간다.
- **비자가 검진**: `reviewer-grounding`과 `reviewer-fit` 두 렌즈를 읽기 전용 서브에이전트로 각각
  호출했다. `reviewer-grounding`은 다섯 쌍(원문 한국어 vs. 영문 후보)을 대조해 지움·모순·날조가
  0건이라고 리턴했고, `reviewer-fit`은 YAML 안전성·단일 줄·완결문 여부를 다섯 개 모두 통과로
  리턴했다(둘 다 `issues: []`). 이 대응표 자체도 같은 두 렌즈로 한 번 더 검진했고, `reviewer-fit`은
  0건, `reviewer-grounding`은 이 "검증" 절의 표현 두 곳("아래 커밋"·"아래 보고서"가 이 문서 안에
  실재하지 않는 것을 가리켰던 것)을 지적해 지금 이 문단으로 고쳤다.
- **README 커맨드 절 일치**: `bash scripts/test_scaffold.sh 2>&1 | grep -i 'README commands'`를
  직접 실행해 다섯 커맨드(`/issue-mode`·`/setup-discipline`·`/show-principles`·`/show-solved`·
  `/ultracode-review`) 모두 PASS로 나오는 것을 확인했다. 실행 결과는 `.superpowers/sdd/task-7-report.md`
  (이 대응표와 별개 파일)에도 옮겨 적는다.
