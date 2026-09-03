# 자기감사 회차 2026-09-03-self-audit

실행체 self-audit(스키마 1)가 커밋 04c8ef05c2c1ccb0f4454b2ee3792d76a95a3736 위에서 돌았다. 확정 10건, 기각 20건, 미판정 19건, 도출 0건이다. 미판정 가운데 19건은 검증 상한 30묶음을 넘어 검증자를 띄우지 않은 것이다. 감사 도중 작업 트리가 바뀌었다. 구조화된 기록은 같은 이름의 폴더에 있다.

## 범위와 배정

- `CLAUDE.md` — lens-readability, lens-grounding. 「사람이 읽는 안내」 행을 골랐다. 판별 열이 프로젝트 CLAUDE.md를 그 행으로 명시한다.
- `README.md` — lens-readability, lens-grounding. 「사람이 읽는 안내」 행을 골랐다. 판별 열의 사용자용 README에 그대로 걸린다.
- `agent-principles.md` — lens-grounding, lens-fit, lens-readability. 「원칙 정본」 행을 골랐다. CLAUDE.md와 여러 스킬이 이 파일을 정본이라 부른다.
- `commands/setup-discipline.md` — lens-readability, lens-grounding. 「사람이 읽는 안내」 행을 골랐다. 판별 열이 명령 문서를 그 행으로 명시한다.
- `commands/show-principles.md` — lens-readability, lens-grounding. 「사람이 읽는 안내」 행을 골랐다. 판별 열이 명령 문서를 그 행으로 명시한다.
- `skills/domain-docs/SKILL.md` — lens-grounding, lens-fit. 「처방 스킬」 행을 골랐다. 문서 저작 규칙과 타입별 처방을 소유한다.
- `skills/domain-llm-runtime/SKILL.md` — lens-grounding, lens-fit. 「처방 스킬」 행을 골랐다. 런타임 LLM 호출의 검증 절차를 소유한다.
- `skills/domain-plugin/SKILL.md` — lens-grounding, lens-fit. 「처방 스킬」 행을 골랐다. 플러그인 제작의 처방을 소유하며 렌즈 정의는 아니다.
- `skills/domain-spec-review/SKILL.md` — lens-grounding, lens-fit. 「처방 스킬」 행을 골랐다. spec·plan 리뷰 절차를 소유한 호출자다.
- `skills/lens-adversarial/SKILL.md` — lens-fit. 「렌즈 정의」 행을 골랐다. 렌즈 자신의 SKILL.md다.
- `skills/lens-consistency/SKILL.md` — lens-fit. 「렌즈 정의」 행을 골랐다. 렌즈 자신의 SKILL.md다.
- `skills/lens-fit/SKILL.md` — lens-fit. 「렌즈 정의」 행을 골랐다. 렌즈 자신의 SKILL.md다.
- `skills/lens-grounding/SKILL.md` — lens-fit. 「렌즈 정의」 행을 골랐다. 렌즈 자신의 SKILL.md다.
- `skills/lens-prior-art/SKILL.md` — lens-fit. 「렌즈 정의」 행을 골랐다. 렌즈 자신의 SKILL.md다. 이 문서를 감사 대상으로 읽는 것이지 lens-prior-art를 띄우는 것이 아니므로 웹 렌즈 제외 규칙에 걸리지 않는다.
- `skills/lens-readability/SKILL.md` — lens-fit. 「렌즈 정의」 행을 골랐다. 렌즈 자신의 SKILL.md다.
- `skills/meta-aggregate/SKILL.md` — lens-grounding, lens-fit. 「처방 스킬」 행을 골랐다. 문서가 스스로 렌즈가 아니라고 밝히며 집계 절차를 소유한다.
- `skills/nested-orchestration/SKILL.md` — lens-grounding, lens-fit. 「처방 스킬」 행을 골랐다. 3층 병렬 실행 절차를 소유한다.
- `skills/project-doc-audit/SKILL.md` — lens-grounding, lens-fit. 「처방 스킬」 행을 골랐다. 레포 문서 감사 절차를 소유한 호출자다.
- `skills/writing-korean/SKILL.md` — lens-grounding, lens-fit, lens-readability. 「원칙 정본」 행을 골랐다. 판별 열이 다른 문서가 정본이라 부르는 파일을 말하고, agent-principles의 네 조항과 lens-readability가 이 파일을 문체 상세의 정본으로 부른다.
- 전체 렌즈 — lens-adversarial, plugin-compliance
- 조각 54개, 문턱 5000자

## 기계 검사

- scripts/test_assertions.sh — PASS. PASS=10 FAIL=0. 검사 블록마다 단언이 있고 구획 주석에 검사가 딸려 있음을 확인했다.
- scripts/test_docs_drift.sh — PASS. PASS=350 FAIL=0. 렌즈 계약, SSOT 드리프트, 금지 표현, 봉인 스크립트까지 전부 통과했다.
- scripts/test_hooks.sh — PASS. PASS=78 FAIL=0. Stop 게이트, 읽기 전용 차단, 넛지 셋, hooks.json 배선이 모두 통과했다.
- scripts/test_scaffold.sh — PASS. PASS=220 FAIL=0. 멱등 셋업, 관리블록 치유, 락 처리, 정본 조항 검사가 모두 통과했다.
- scripts/test_self_audit.sh — PASS. PASS=42 FAIL=0. 실행체 문법과 발견 칸, audit_targets.sh 문턱, 재배선 단언이 모두 통과했다.
- claude plugin validate ./ (non-strict) — PASS. Validation passed with warnings, 종료 코드 0. 경고는 plugins[0] plugin.json 의 version 미지정 하나뿐이며 CLAUDE.md 가 정상이라 적은 그 경고다.
- 실행 형태 — CLAUDE.md 정본 루프의 환경 제약 — PASS. CLAUDE.md:11 의 루프 형태를 그대로 돌리려 했으나 이 세션의 워크트리 격리가 거부했다(runs bash inside a construct too complex to verify). 환경 원인이므로 수정하지 않았고, 대신 scripts/test_*.sh 다섯을 각각 별도 명령으로 돌려 종료 코드를 하나씩 관측했다 — 앞 스크립트의 실패가 뒤에 묻히는 형태로 바꾸지 않았다.

## 집계

감사 도중 작업 트리가 바뀌었다 — 이 회차의 판정은 움직인 작업 트리에 대한 것이다. 다시 측정한 커밋은 기계 검사의 지문과 같은 `04c8ef05c2c1ccb0f4454b2ee3792d76a95a3736` 이나, `git status --porcelain` 이 `?? docs/superpowers/reviews/2026-09-03-self-audit/` 한 줄을 내므로 지문이 적은 `tree_clean: true` 와 어긋난다. 바뀐 것은 이 회차가 스스로 쓴 기록 폴더 하나뿐이고 추적되는 파일은 그대로다. 구조 점검의 결과는 이렇다. 확정 발견 열 건 사이에 상충은 없다 — 같은 곳을 가리키면서 한쪽은 고치라 하고 다른 쪽은 그대로 두라고 한 짝이 없다. 겹치는 축이 셋 있어 따로 대조했는데, 기록 파일 이름 규칙을 다루는 #015와 #021은 둘 다 소유자를 `domain-docs` 로 모으는 같은 방향이고, `domain-llm-runtime` 을 다루는 #016과 #018은 서로 다른 줄을 짚으며, 렌즈 계약을 다루는 #026과 #030은 각각 프롬프트 쪽과 리턴 스키마 쪽이라 부딪히지 않는다. 반면 커버리지에는 공백이 크다. 문서 사이의 어긋남을 소유한 `lens-consistency` 가 이 회차에서 한 번도 돌지 않았고, 검증 상한 30묶음이 문서 순서의 뒤쪽을 잘라 스킬 여섯과 워크플로 실행체에 걸린 발견 열아홉 건이 판정 없이 남았다. 그러므로 이 회차의 확정 열 건은 감사 범위 전체의 결론이 아니라 앞쪽 문서와 문서별 렌즈가 덮은 범위의 결론으로 읽어야 하며, 다음 회차는 `lens-consistency` 묶음 호출을 실행체에 배선하는 것과 상한 밖으로 밀린 열아홉 건을 검증하는 것을 먼저 처리해야 한다.

- 상충 없음
- 커버리지 공백 — 문서 사이의 어긋남을 보는 `lens-consistency` 가 이 회차에서 한 번도 돌지 않았다. `skills/project-doc-audit/SKILL.md` 46행은 이 렌즈를 문서별 표 밖에 두고 "규칙을 소유한 문서와 그것을 따르는 문서 전부를 한 렌즈에게 묶음으로 한 번 준다"고 정하는데, 실행체 `.claude/workflows/self-audit.js` 241행은 문서별로 걸지 말라는 지시만 넣고 묶음 호출을 따로 만들지 않는다. 기록 폴더에도 `lens-consistency-*.json` 이 없고 전체 렌즈로는 `lens-adversarial-1.json` 과 `plugin-compliance-1.json` 둘만 있다. 하필 이번 확정 발견 열 건 가운데 #015·#016·#021 셋이 문서 사이 SSOT 드리프트라, 이 렌즈가 소유한 부류의 결함이 다른 렌즈에 우연히 걸린 만큼만 드러났다.
- 커버리지 공백 — 검증 상한 30묶음이 문서 순서의 뒤쪽을 통째로 잘라, `skills/meta-aggregate`·`skills/nested-orchestration`·`skills/project-doc-audit`·`skills/writing-korean`·`skills/lens-prior-art`·`skills/lens-readability` 와 `.claude/workflows/self-audit.js` 에 걸린 발견(#035~#049)이 하나도 판정되지 않았다. 이 문서들에 대해서는 확정도 기각도 없으므로 이 회차의 판정은 그 범위를 말하지 않는다.
- 커버리지 공백 — 미판정 #034(`purpose`·`notes` 가 실제 렌즈 리턴 스키마에 없다)는 확정 #030과 같은 실체를 다른 문서 쪽에서 가리키는데 상한 밖이라 검증되지 않았다. 확정된 쪽만 고치면 같은 결함의 나머지 반쪽이 남는다.
- 커버리지 공백 — 미판정 #041·#037은 확정 #015·#021과 같은 기록 파일 이름 규칙을 다루므로, 이름 규칙을 손볼 때 판정된 둘만 보고 고치면 판정되지 않은 둘이 남아 규칙이 다시 갈린다.
- 커버리지 공백 — `lens-prior-art` 를 띄우지 않은 것은 `skills/project-doc-audit/SKILL.md` 의 웹 렌즈 제외 조항에 따른 것이므로 공백이 아니다. 다만 이 회차 기록에 그 제외 사실과 이유가 남는지는 기록 단계에서 확인해야 한다.
- 커버리지 공백 — `run.json` 이 `completed:false`, `commit:null`, `tree_clean:null`, `counts_by_lens:{}`, `verdict_counts` 전부 0인 상태로 남아 있다. 집계 시점의 중간 상태일 수 있으나, 이대로 봉인되면 이 회차가 어디까지 돌았는지를 기록만 보고 판정할 수 없다.

## 확정 발견

- `2026-09-03-self-audit#001` CLAUDE.md는 이 레포에 걸린 네 훅 가운데 spec/plan Stop 게이트 하나만 적어, 리뷰 기록이 읽기 전용으로 봉인된다는 사실과 그 밖의 문서를 고칠 때 검진 넛지가 뜬다는 사실을 알려 주지 않는다. (CLAUDE.md:5)
- `2026-09-03-self-audit#004` 「하드 게이트와 넛지와 전역 설정 수정」 절의 첫 문단은 여섯 가지를 두 문장에 몰아넣어, 무엇이 꺼지고 무엇이 안 꺼지는지를 읽는 사람이 세어 봐야 알 수 있게 만든다. (README.md:46)
- `2026-09-03-self-audit#013` 도출한 값을 그대로 쓰라고만 적어 두었으나, `resolve_home`은 홈이 어긋난 PC에서 stderr로 note 한 줄을 함께 내보내므로 받은 출력에 경로가 아닌 줄이 섞인다. (commands/show-principles.md:5-7)
- `2026-09-03-self-audit#015` 렌즈 원본 파일 이름 규칙의 `<렌즈>` 자리가 접두사를 정하지 않아 같은 폴더에 두 가지 이름이 섞인다 (skills/domain-docs/SKILL.md:58)
- `2026-09-03-self-audit#016` `meta-aggregate`를 LLM 콜로 두지 않는다고 단정한 문장이 그 사실의 소유자인 `meta-aggregate`가 허용한 예외와 어긋난다. (skills/domain-llm-runtime/SKILL.md:20)
- `2026-09-03-self-audit#018` 체크리스트의 등급이 모두 미리 정한 고정값이라는 선언이 등급 없는 항목과 조건부 항목 때문에 성립하지 않는다. (skills/domain-llm-runtime/SKILL.md:34)
- `2026-09-03-self-audit#021` 리뷰 기록 파일 이름 규칙을 domain-docs가 소유하는데 이 문서가 조건을 뺀 채 다시 선언한다 (skills/domain-spec-review/SKILL.md:91)
- `2026-09-03-self-audit#022` 리뷰 기록에 담을 것을 다섯으로 닫아 놓고 다른 절들이 같은 파일에 더 적으라고 요구한다 (skills/domain-spec-review/SKILL.md:101)
- `2026-09-03-self-audit#026` 레퍼런스 프롬프트가 커버리지 공백을 spec↔plan으로 못 박아, 레포 문서 감사가 그 프롬프트를 그대로 쓰면 이 렌즈의 계약과 어긋난다 (D:\projects\disciplined-coder\.claude\worktrees\audit-record-and-diff\skills\lens-consistency\SKILL.md:22)
- `2026-09-03-self-audit#030` 레퍼런스 프롬프트가 `notes`에 적으라고 두 번 지시하지만 이 회차를 실제로 돌리는 self-audit 워크플로의 리턴 스키마에는 `notes` 자리가 없어 그 지시가 조용히 버려진다. (skills/lens-grounding/SKILL.md:19)

## 회차 대조

- 대조할 지난 회차 없음

## 도출된 발견

- 없음

## 되풀이되는 뿌리

- **소유자 문서의 규칙을 따르는 문서가 조건을 빼고 다시 선언한다** — `#015`·`#016`·`#021`이 같은 모양이다. `domain-docs`가 기록 이름 규칙을, `meta-aggregate`가 자기 실행 형태를 소유하는데, 그것을 따르는 문서들이 조건을 뺀 단정으로 복제해 두었다. 복제를 지우고 소유자를 가리키게 고치면 셋이 함께 사라진다.
- **렌즈의 레퍼런스 프롬프트가 호출자 하나만 상정한다** — `#026`·`#030`이 같은 모양이다. `lens-consistency`의 프롬프트는 커버리지 공백을 spec과 plan 사이로 못 박았고, `lens-grounding`의 프롬프트는 `notes`에 적으라고 지시하는데 자기감사 실행체의 리턴 스키마에는 그 자리가 없다. 호출자마다 갈리는 부분을 호출자가 프롬프트에 넣게 바꾸고 실행체 스키마에 `notes`를 더하면 둘이 함께 사라진다.
- **안내 문서가 이 레포에만 걸린 배선을 실측에서 도출하지 않는다** — `#001`·`#013`이 같은 모양이다. `CLAUDE.md`는 훅 넷 가운데 하나만 적었고, `commands/show-principles.md`는 도출 명령이 stderr로 한 줄을 더 낸다는 사실을 안 적었다. 두 문서를 실제 배선과 실제 출력에서 도출해 다시 쓰면 둘이 함께 사라진다.

## 사용자가 정할 물음

- 리뷰 기록 파일 이름 규칙이 두 문서에서 갈린다. 같은 주제의 둘째 회차를 새 날짜의 `-review.md`로 둘지, 같은 날짜의 `-review-2.md`로 둘지 정해야 한다. 이 저장소에는 이미 두 형태가 파일로 남아 있다.
- 렌즈 원본 파일 이름의 접두사가 정해져 있지 않다. `lens-grounding-1.json`으로 통일할지 `grounding-1.json`으로 통일할지 정해야 한다. 지금은 실행체가 도는 회차와 사람이 도는 회차가 서로 다른 이름을 찍는다.
- 검증 상한이 30묶음이라 이번 회차의 발견 19건이 검증자를 만나지 못하고 미판정으로 남았다. 상한을 올릴지, 발견을 더 적게 내게 할지 정해야 한다.

## 이 회차의 실행 형태

호출은 76건이었다. 준비 셋, 리뷰 21(문서 19에 전체 렌즈 둘), 기록 배관 스물넷, 중복제거 하나, 반박검증 서른, 집계 하나다. 렌즈는 문서마다 따로 띄우지 않고 문서 하나에 하나를 띄워 배정된 렌즈를 차례로 적용하게 했다.

`lens-consistency`는 이 회차에 배선되지 않아 돌지 않았다. 문서 사이의 어긋남을 보는 렌즈라 문서마다 걸 수 없고, 주제별로 문서를 묶어 통째로 주는 걸음이 아직 없다.
