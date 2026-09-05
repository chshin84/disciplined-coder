# 자기감사 회차 2026-09-05-self-audit

실행체 self-audit(스키마 1)가 커밋 a0326a4c87b753004240087875362a5e3cb7c989 위에서 돌았다. 확정 21건, 기각 36건, 미판정 0건, 도출 0건이다. 구조화된 기록은 같은 이름의 폴더에 있다.

## 범위와 배정

- `agent-principles.md` — lens-grounding, lens-fit, lens-readability. 「원칙 정본」 행을 골랐다. 다른 문서들이 이 파일을 정본이라 부르며(CLAUDE.md·README·각 스킬), 원칙 조항이 여기에만 있다.
- `README.md` — lens-grounding, lens-readability. 「사람이 읽는 안내」 행을 골랐다. 사용자용 README이며 설치와 배포 조건을 사람에게 설명한다.
- `CLAUDE.md` — lens-grounding, lens-readability. 「사람이 읽는 안내」 행을 골랐다. 표의 「무엇으로 가리나」 칸이 프로젝트 CLAUDE.md 를 이 행에 명시한다.
- `commands/setup-discipline.md` — lens-grounding, lens-readability. 「사람이 읽는 안내」 행을 골랐다. 표가 명령 문서를 이 행에 명시한다.
- `commands/show-principles.md` — lens-grounding, lens-readability. 「사람이 읽는 안내」 행을 골랐다. 표가 명령 문서를 이 행에 명시한다.
- `skills/domain-docs/SKILL.md` — lens-grounding, lens-fit. 「처방 스킬」 행을 골랐다. 문서 저작 규칙과 문서 타입별 처방을 소유한 SKILL.md 다.
- `skills/domain-llm-runtime/SKILL.md` — lens-grounding, lens-fit. 「처방 스킬」 행을 골랐다. 런타임 LLM 호출의 검증 절차를 소유한 SKILL.md 다.
- `skills/domain-plugin/SKILL.md` — lens-grounding, lens-fit. 「처방 스킬」 행을 골랐다. 플러그인 제작의 처방을 소유한 SKILL.md 다.
- `skills/domain-spec-review/SKILL.md` — lens-grounding, lens-fit. 「처방 스킬」 행을 골랐다. spec·plan 리뷰 절차를 소유한 SKILL.md 다.
- `skills/project-doc-audit/SKILL.md` — lens-grounding, lens-fit. 「처방 스킬」 행을 골랐다. 레포 문서 감사 절차를 소유한 SKILL.md 다.
- `skills/meta-aggregate/SKILL.md` — lens-grounding, lens-fit. 「처방 스킬」 행을 골랐다. 이름에 lens 가 없고 본문이 스스로 렌즈가 아니라고 적으며, 집계 걸음이라는 절차를 소유한다.
- `skills/nested-orchestration/SKILL.md` — lens-grounding, lens-fit. 「처방 스킬」 행을 골랐다. 3층 병렬 실행 절차를 소유한 SKILL.md 다.
- `skills/writing-korean/SKILL.md` — lens-grounding, lens-fit. 「처방 스킬」 행을 골랐다. 한국어 저작 규칙의 상세 SSOT 를 소유한다.
- `skills/lens-adversarial/SKILL.md` — lens-fit. 「렌즈 정의」 행을 골랐다. 렌즈 자신의 SKILL.md 다.
- `skills/lens-consistency/SKILL.md` — lens-fit. 「렌즈 정의」 행을 골랐다. 렌즈 자신의 SKILL.md 다.
- `skills/lens-fit/SKILL.md` — lens-fit. 「렌즈 정의」 행을 골랐다. 렌즈 자신의 SKILL.md 다.
- `skills/lens-grounding/SKILL.md` — lens-fit. 「렌즈 정의」 행을 골랐다. 렌즈 자신의 SKILL.md 다.
- `skills/lens-prior-art/SKILL.md` — lens-fit. 「렌즈 정의」 행을 골랐다. 렌즈 자신의 SKILL.md 다.
- `skills/lens-readability/SKILL.md` — lens-fit. 「렌즈 정의」 행을 골랐다. 렌즈 자신의 SKILL.md 다.
- 전체 렌즈 — lens-adversarial, plugin-compliance
- 조각 57개, 문턱 5000자
- 이름표 묶음 421개, 좁혀 적음 21건, 빈 이름표 진술 1건, 문턱을 넘는 묶음 194개

## 기계 검사

- scripts/test_assertions.sh — PASS. PASS=10 FAIL=0, 종료 코드 0. 검사 블록마다 단언이 있고 구획 주석에 검사가 딸려 있다.
- scripts/test_docs_drift.sh — PASS. PASS=351 FAIL=0, 종료 코드 0. 봉인 검사 구간에서 픽스처 저장소에 대한 git CRLF 경고가 나오나 레포 작업 트리는 건드리지 않는다.
- scripts/test_hooks.sh — PASS. PASS=78 FAIL=0, 종료 코드 0. Stop/PostToolUse 게이트와 읽기 전용 훅 배선이 모두 통과한다.
- scripts/test_scaffold.sh — PASS. PASS=220 FAIL=0, 종료 코드 0. 멱등성·락·관리블록 치유·정본 갱신이 모두 통과한다.
- scripts/test_self_audit.sh — FAIL. PASS=95 FAIL=2, 종료 코드 1. 실패한 단언은 160번 줄의 check "최신 회차의 diff.json 에 대조 항목이 있다" 와 210번 줄의 check "최신 회차 run.json 의 topic_groups 가 양수다" 둘이다. 원인은 코드가 아니라 감사 회차 기록이다 — completed 인 최신 회차 폴더는 docs/superpowers/reviews/2026-09-03-self-audit 하나뿐이고, 그 diff.json 3~4번 줄이 "no_prior_round": true, 와 "items": [] 이며 run.json 187번 줄이 "topic_groups": 0, 이다. 그 기록의 steps_done 은 여덟(repo-check, targets, review, dedup, verify, machine-checks, aggregate, record)이라 실행체 .claude/workflows/self-audit.js 31번 줄의 닫힌 목록 STEPS 열하나 가운데 extract·group·diff 가 빠져 있다. 즉 뽑기와 대조 걸음이 생기기 전에 찍힌 회차다. 이 두 단언은 파일을 고쳐서는 통과시킬 수 없다 — scripts/test_docs_drift.sh 의 [리뷰 기록은 찍은 뒤 고치지 않는다] 구획이 작업 트리와 2026-09-02 이후 이력 양쪽에서 기록의 수정·삭제를 막고, scripts/seal_reviews.sh 가 기록을 읽기 전용으로 봉인한다. 통과시키는 길은 자기감사를 한 회차 더 도는 것뿐이다. 따라서 CLAUDE.md 9번 줄이 선언한 '각 스크립트의 계약은 FAIL=0' 이 지금 HEAD 에서 지켜지지 않으며, 기계 검사가 코드가 아니라 실행체가 남긴 데이터 기록에 묶여 있어 재현 가능한 회귀 검사 구실을 못 한다(TDD·SSOT·FOCUSED). 환경 원인은 아니다.
- claude plugin validate ./ (non-strict) — PASS. 종료 코드 0, Validation passed with warnings. 경고는 CLAUDE.md 13번 줄이 정상이라 적은 그 하나뿐이다 — plugins[0] plugin.json → version: No version specified.

## 집계

이번 회차는 구조적으로 건강한 편이며, 확정 발견 사이의 정면 충돌은 나오지 않았다. 대상 열아홉 개가 정본과 README와 프로젝트 CLAUDE.md와 커맨드 둘과 스킬 열넷을 모두 덮어 문서 쪽 배정에 빠진 자리가 없고, 응답하지 않은 렌즈 호출이 없으며 미판정도 없어 상한에 걸려 못 본 묶음도 없다. 확정 스물한 건 가운데 열넷이 정본과 사본이 갈린 자리를 짚어 이번 회차의 뿌리가 사본 관리에 있음을 보여 준다. 다만 셋을 함께 알린다. 첫째로 lens-consistency 는 아홉 번 돌아 발견 열셋을 냈으나 검증을 넘긴 것이 하나도 없고, 같은 성격의 정본·사본 어긋남은 lens-grounding 과 lens-fit 이 잡아 렌즈 사이의 담당 경계가 겹쳐 있다. 둘째로 기계 검사 다섯 가운데 scripts/test_self_audit.sh 가 FAIL=2 로 떨어져 CLAUDE.md 가 선언한 FAIL=0 계약이 지금 HEAD 에서 깨져 있는데, 그 스크립트도 그것이 검사하는 .claude/workflows/self-audit.js 도 이번 배정표의 대상이 아니어서 확정 발견 어느 것도 이 실패를 다루지 않는다. 셋째로 확정 #029 와 #032 는 절차 스킬이 파일 이름 규칙을 다시 적은 것을 결함으로 확정했는데, 기각된 #033 은 바로 그 domain-spec-review:91 을 이 레포의 기존 관행이라는 기각 근거로 삼았다. 같은 줄을 두고 확정과 기각이 반대 전제를 썼으므로 사본 정책을 한 번 정해 두지 않으면 다음 회차에서 같은 자리가 다시 갈린다.

- 상충 2026-09-05-self-audit#029 · 2026-09-05-self-audit#032 · 2026-09-05-self-audit#033 — 같은 지점(skills/domain-spec-review/SKILL.md:91 의 파일 이름 사본)을 두고 확정과 기각이 반대 전제를 쓴다. #029 는 그 줄을 SSOT 위반으로 확정하고 #032 도 같은 이유로 project-doc-audit:88 의 축약 사본을 확정했는데, 기각된 #033 의 기각 사유는 '절차 스킬이 파일 이름 패턴을 다시 적는 것은 이 레포의 기존 관행이다'이며 그 근거로 든 선례가 #029 가 결함이라 판정한 바로 그 91번째 줄이다. 사본을 허용하는지가 한 회차 안에서 두 방향으로 쓰였으므로 사용자가 정책을 한 번 정해 주어야 한다.
- 커버리지 공백 — lens-consistency 는 아홉 번 돌아 발견 열셋을 냈으나 확정으로 남은 것이 없다(확정 스물한 건의 렌즈는 grounding·fit·readability·adversarial 뿐이다). 정작 정본과 사본이 갈린 자리 열넷은 lens-grounding 과 lens-fit 이 잡았으므로, 이 렌즈가 소유한 축(정본 진술과 따르는 문서 진술의 짝 판정)이 다른 렌즈에 흡수되어 돌아간 것으로 본다. 확정 #043 이 이 렌즈의 레퍼런스 프롬프트와 출력 스키마에 narrowed 와 pairs 가 없다고 짚은 것과 같은 뿌리다.
- 커버리지 공백 — scripts/test_self_audit.sh 의 FAIL=2 를 다루는 확정 발견이 없다. 이번 배정표 열아홉 대상에 scripts/ 아래 셸 스크립트와 .claude/workflows/self-audit.js 가 들어 있지 않아, 기계 검사가 코드가 아니라 봉인된 데이터 기록에 묶여 있다는 구조 문제를 어느 렌즈도 대상으로 삼지 않았고 CLAUDE.md 의 FAIL=0 계약이 깨진 상태가 발견 목록 밖에 남는다.
- 커버리지 공백 — 실행체와 훅과 스크립트에는 lens-adversarial 한 번만 걸렸고(그 한 번이 확정 #055·#056 을 냈다) lens-grounding 과 lens-fit 은 걸리지 않았다. 반대로 문서 열아홉 개에는 lens-adversarial 이 하나도 배정되지 않아 문서의 실패 모드와 비가역을 보는 축이 이번 회차에 비어 있다.
- 커버리지 공백 — lens-prior-art 는 이번 회차에서 한 번도 돌지 않았다. 웹에 나가는 렌즈라 사용자 승인이 있어야 여는 설계에 따른 것이므로 절차 위반은 아니나, 선행 사례 대조 축은 이번 판정에 들어 있지 않다.
- 커버리지 공백 — docs/superpowers/ 아래 설계 문서와 계획 문서, hooks/hooks.json, .claude/settings.json 이 대상 목록에 없다. 확정 #003 과 #004 가 그 배선을 증거로 인용해 결함을 세웠으므로 배선 파일 자체를 대상으로 잡는 것이 다음 회차의 후보다.
- 커버리지 공백 — 이번 회차의 run.json 은 이 시점에 completed 이 거짓이고 counts_by_lens 가 빈 객체이며 verdict_counts 가 전부 0 이고 machine_checks 가 null 이다. 기록 걸음이 이 값들을 채우지 못하면 봉인된 기록만으로는 렌즈별 호출 수와 판정 분포를 되짚을 수 없다. 확정 #030(렌즈 호출 상한으로 자른 수를 담을 칸이 없다)과 #031(표가 기록을 집계보다 앞에 둔다)이 가리키는 자리와 같다.

## 확정 발견

- `2026-09-05-self-audit#003` README는 감사 기록이 만든 직후 읽기 전용이 된다고 적지만, 봉인은 세션 시작 때 HEAD에 커밋된 파일에만 걸리고 실측한 기록 33개 가운데 32개가 쓰기 가능하다. (README.md:49)
- `2026-09-05-self-audit#004` README는 셋업 오류를 세션 시작 알림의 ERROR로 알아보라고 안내하지만, 그 ERROR 두 줄은 stderr로 나가고 이 레포 자신의 주석이 SessionStart의 stderr는 사용자에게 닿지 않는다고 적는다. (README.md:21)
- `2026-09-05-self-audit#016` 커맨드는 명령이 돌려주는 값을 「관리 디렉터리」라고 부르지만, 소스에서 그 값은 설정 홈이고 관리 디렉터리는 그 아래 disciplined-coder다. (commands/show-principles.md:5)
- `2026-09-05-self-audit#018` 파일이 없을 때 사용자에게 내보내는 문장이 「scaffold」라는 영어 개발 용어를 풀지 않고 그대로 쓴다. (commands/show-principles.md:10)
- `2026-09-05-self-audit#019` 문서 검진 절이 렌즈를 "각각 호출"하라고 적어 같은 문서 뒷절의 한 에이전트 규율과 실제 워크플로 구현을 둘 다 어긴다. (skills/domain-docs/SKILL.md:82)
- `2026-09-05-self-audit#021` 「렌즈 선택」 절이 meta-aggregate를 LLM 콜로 두지 않는다고 단정해 meta-aggregate가 소유한 구현 형태와 어긋난다. (skills/domain-llm-runtime/SKILL.md:20)
- `2026-09-05-self-audit#023` 비기능 체크리스트의 마지막 항목에 등급이 없어 누락 처분 규칙이 그 항목에는 적용되지 않는다. (skills/domain-llm-runtime/SKILL.md:43)
- `2026-09-05-self-audit#025` 사본과 재검증 규칙이 이 레포의 다른 사용자 파일 수정 경로에서는 지켜지지 않는다. (skills/domain-plugin/SKILL.md:21)
- `2026-09-05-self-audit#027` 디스패치 절은 렌즈마다 서브에이전트를 하나씩 띄우라고 적어, 한 대상에 렌즈가 여럿이면 에이전트 하나가 렌즈를 차례로 적용하라는 소유 규칙과 정면으로 어긋난다. (skills/domain-spec-review/SKILL.md:45)
- `2026-09-05-self-audit#029` 리뷰 기록 절은 이름 규칙을 베끼지 않는다고 선언한 바로 앞 줄에서 파일 이름 형식을 그대로 적어 두었다. (skills/domain-spec-review/SKILL.md:91)
- `2026-09-05-self-audit#030` 문서가 검증자 상한만 적고 렌즈 호출 상한을 빠뜨려, 실행체가 렌즈 호출 서른 건을 넘겨 잘라 내는 것이 절차에 없는 동작이 된다. (skills/project-doc-audit/SKILL.md:80)
- `2026-09-05-self-audit#031` 걸음 표가 기록을 집계보다 앞에 두어, 같은 문서의 「통합 기록」 절과 실행체의 걸음 순서 둘 다와 어긋난다. (skills/project-doc-audit/SKILL.md:21)
- `2026-09-05-self-audit#032` 렌즈별 원본 파일 이름을 접두사 없는 `<렌즈>`로 다시 적어, 그 이름 규칙을 소유한 domain-docs가 금지한 형태를 이 문서가 제시한다. (skills/project-doc-audit/SKILL.md:88)
- `2026-09-05-self-audit#035` L2가 자율로 domain-spec-review를 돌린다고 적었으나, 그 스킬은 반영 뒤 다시 리뷰할지를 매번 사용자에게 묻게 하므로 사람과 대화할 수 없는 L2가 그 걸음을 조용히 건너뛴다. (skills/nested-orchestration/SKILL.md:19)
- `2026-09-05-self-audit#038` 「금지 표현」 표는 test_docs_drift.sh가 정규식으로 파싱하는 계약인데 그 형식 요구를 문서가 어디에도 적지 않는다 (skills/writing-korean/SKILL.md:31)
- `2026-09-05-self-audit#043` 레퍼런스 프롬프트를 그대로 쓰면 이 렌즈는 `narrowed`와 `pairs`를 돌려주지 않는다 (skills/lens-consistency/SKILL.md:22-23, 36, 40)
- `2026-09-05-self-audit#050` 가드가 이슈로 올릴 순간을 둘로 닫아 놓아, 같은 문서가 정의한 네 개짜리 `type` 폐쇄 집합 가운데 `crowded`와 `weak-baseline`이 올라올 길이 막힌다. (skills/lens-prior-art/SKILL.md:31)
- `2026-09-05-self-audit#052` 집계 항목이 닫힌 필드 목록이라 인용이 실리지 않는다는 사실을 이 파일이 다시 서술해, 같은 문장 안에서 SSOT라고 가리킨 `meta-aggregate`와 사본이 둘로 갈린다. (skills/lens-prior-art/SKILL.md:57)
- `2026-09-05-self-audit#053` 체크리스트 절이 없어 관찰 축 열이 기계 검사를 통과하지 않고 조용히 건너뛰어진다. (skills/lens-readability/SKILL.md:27)
- `2026-09-05-self-audit#055` 회차 대조가 만든 도출 발견은 증거 자리에 파일 인용 대신 id 두 개를 넣으므로, 다음 회차의 대조 에이전트가 그 발견을 판정할 근거를 갖지 못한다. (.claude/workflows/self-audit.js:719)
- `2026-09-05-self-audit#056` 리뷰 기록을 쓰다 끊긴 회차는 run.json 이 없어 앞선 회차로도 끊긴 회차로도 잡히지 않고 조용히 사라진다. (scripts/audit_prior_rounds.sh:27)

## 회차 대조

- 잔존 25건, 해소 4건, 미판정 0건

## 도출된 발견

- 없음

## 되풀이되는 뿌리

- **렌즈를 어떻게 띄우는지가 문서마다 다르게 적혀 있다** — `#019`·`#027`·`#030`이 같은 모양이다. `domain-docs`의 문서 검진 절은 렌즈를 "각각 호출"하라 하고, `domain-spec-review`의 디스패치 절은 렌즈마다 서브에이전트를 하나씩 띄우라 하며, `project-doc-audit`은 검증자 상한만 적고 렌즈 호출 상한을 빠뜨렸다. 규율의 소유자는 `domain-docs`의 「한 번만 띄우는 렌즈의 규율」인데 그 규율을 따르는 문서 셋이 옛 형태를 그대로 적고 있다. 소유자 하나를 가리키게 고치면 셋이 함께 사라진다.
- **소유자가 정한 것을 따르는 문서가 조건을 빼고 다시 선언한다** — `#021`·`#029`·`#032`가 같은 모양이다. 직전 회차의 같은 뿌리가 다시 나왔고 이번에는 대상 문서만 바뀌었다. 이름 규칙과 실행 형태를 소유자에게서 도출하지 않고 베낀 문장이 남아 있다.
- **문서가 실제 동작보다 넓게 약속한다** — `#003`·`#004`가 같은 모양이다. README가 감사 기록이 만든 직후 읽기 전용이 된다고 적었으나 봉인은 세션 시작 때 커밋된 파일에만 걸리고, 셋업 오류를 세션 시작 알림으로 알아보라 했으나 그 줄은 사용자에게 닿지 않는다. 문서의 약속을 실제 배선에서 도출하면 둘이 함께 사라진다.

## 사용자가 정할 물음

- 이름표 묶음이 421개 나왔고 리뷰 상한 30에 걸려 9개만 돌았다. 일관성 대조가 저장소의 2%만 본 셈이다. 이름표를 더 굵게 잡을지, 묶음을 걸러 낼 기준을 둘지, 상한을 올릴지 정해야 한다.
- 계약 테스트의 단언 둘이 코드가 아니라 감사 회차 기록에 묶여 있다. 회차를 돌기 전에는 통과할 수 없고 기록이 봉인돼 있어 고쳐서 통과시킬 수도 없다. 회귀 검사를 데이터에서 떼어 낼지 정해야 한다.

## 이 회차의 실행 형태

호출은 154건이었고 80분이 걸렸다. 뽑기 57(조각마다), 리뷰 30(문서 19 + 전체 렌즈 2 + 이름표 묶음 9, 상한 30에 걸려 묶음 412개를 못 돌렸다), 반박검증 18, 회차 대조 12, 기록 배관과 준비와 집계가 나머지다. 서브에이전트 토큰은 9,654,716이다.

앞 회차와 견주면 호출이 76건에서 154건으로 늘었다. 뽑기 걸음이 새로 들어왔기 때문이고, 조각마다 호출 하나를 두는 형태가 그 증가의 전부다.
