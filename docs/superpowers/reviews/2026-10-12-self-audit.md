# 2026-10-12 레포 문서 감사

살아 있는 문서 스물다섯을 한 차수로 검진해 확정 157건과 기각 5건을 냈고 미판정은 없다. 사용자가 nested-orchestration 을 중점으로 봐 달라고 해 그 스킬을 단독 묶음으로 두고 적대적 렌즈의 중점 대상으로 지정했다.

## 범위와 배정

`scripts/audit_targets.sh` 가 낸 스물다섯을 모두 검토했다. 문서 단위 그룹(`lens-grounding`, `lens-fit`)은 문서 스물다섯을 아홉 묶음으로 나눠 한 호출에 두 턴으로 적용했고, `lens-adversarial`은 저장소 전체에 한 번 실행했다. `lens-readability`는 남에게 전달되는 문서 넷에 제안해 사용자 승인을 받았다. `lens-consistency`는 값이 다른 짝 묶음 한 호출과 소유를 선언한 문서 묶음 한 호출로 실행했다.

렌즈 호출은 22턴이고 서브에이전트는 13개다. 첫 단계는 묶음 아홉과 적대적 렌즈 하나로 상한 10에 맞췄고 잘라 낸 호출은 없다. 커밋 지문은 `bd51ebb` 이고 작업 트리는 깨끗했다.

## 기계 검사

- **contract_tests** — scripts/test_*.sh 를 동시에 실행해 모두 통과했다(시작 시점 bd51ebb).
- **targets_script** — bash scripts/audit_targets.sh 가 스물다섯을 냈다.
- **topics_script** — bash scripts/audit_topics.sh 의 이름표를 statements 요구에 넣었다.
- **prior_rounds_script** — bash scripts/audit_prior_rounds.sh 가 2026-09-06-self-audit 와 2026-09-05-self-audit-2 를 냈고, --stale 은 비었다.
- **evidence_script** — audit_evidence.sh 를 시작 커밋 bd51ebb 의 워크트리에 실행해 162건 중 161건이 통과했다. 남은 1건(lens-consistency-2 의 하향 메시지 행)은 렌즈 실행 중 세션이 커밋한 9fafabe 의 문장을 인용해 그 커밋 워크트리로 확인했다.
- **style_metrics** — 이 저장소는 금지 표현을 세지 않는다(hooks/_spec_marker.sh 의 path_in_own_repo).

## 판정 개수

| 판정 | 개수 |
|---|---|
| 확정 | 157 |
| 기각 | 5 |
| 미판정 | 0 |

기각의 사유는 아래와 같다.

- 040 `docs/domain-korean.md` — 교정 예시를 보이는 문장이다. ANTI-LIMIT 가 겨냥하는 수사적 대구가 아니다.
- 045 `korean-banned-words.md` — 대체어가 하나로 정해지지 않는 항목은 대신 쓰는 말 칸에 지시를 둔다. 표를 파싱하는 훅이 이 칸을 그대로 출력하므로 의도한 형식이다.
- 047 `korean-banned-words.md` — 교정 예시를 보이는 문장이다. ANTI-LIMIT 가 겨냥하는 수사적 대구가 아니다.
- 087 `skills/nested-orchestration/SKILL.md` — 「흐름」은 번호를 붙인 절차 단계이고 CHECKABLE 이 단계마다 번호를 요구한다. BULLET-SCOPE 는 불릿 목록 대상이다.
- 154 `skills/nested-orchestration/references/sub-session-protocol.md` — 설계 문서 「2026-10-11 개정 — 검진 반영」이 수정 라운드 상한을 SDD 규칙(5라운드)에 맡겼고, 프로토콜 「SDD 와 함께 쓸 때」가 그대로 따른다. 세 번 기준은 그 개정이 대체한 옛 문장이다.

## 집계

확정 하나당 23,490 토큰이 들었다. 토큰은 서브에이전트 보고값의 합이라 하한이다.

| 렌즈 | 올린 것 | 확정 |
|---|---|---|
| `lens-adversarial` | 6 | 6 |
| `lens-consistency` | 12 | 12 |
| `lens-fit` | 91 | 87 |
| `lens-grounding` | 53 | 52 |

커버리지 공백은 아래와 같다. `lens-prior-art`는 이 절차가 제안하지 않는다. `lens-readability`의 제안 스물넷은 판정 목록과 섞지 않고 `suggestions.json` 에 따로 두었다. 조건부 모순은 이름표 대조로 잡히지 않는 한계가 있다.

## 확정 발견

| 번호 | 파일 | 렌즈 | 원칙 | 지적 |
|---|---|---|---|---|
| 001 | `skills/nested-orchestration/SKILL.md` | lens-adversarial | CHECKABLE | 현재 세션은 큰 명세를 자기 체크아웃에 쓰고 리뷰한 뒤 cp 로 통합용 워크트리에 옮겨 커밋한다. 원본과 review-specs 가 자기 체크아웃에 남긴 리뷰 기록은 어느 단계에서도 지우거나 커밋하지 않는다. 사용자 체크아웃에서 dev/<개발 이름>을 main 에 병합하면 같은 경… |
| 002 | `skills/nested-orchestration/SKILL.md` | lens-adversarial | SUBJECT-OBJECT | 서브에이전트 실행 화면으로 들어가는 조작은 사용자만 할 수 있는데, 스킬은 그 확인을 현재 세션의 단계로 적었다. 현재 세션은 이 확인을 수행하지 못하므로 CANCELED 뒤 정리와 재개 판단이 실행되지 않거나 확인 없이 진행된다. 주체를 사용자로 바꿔 현재 세션이 사용자에게 확인… |
| 003 | `skills/nested-orchestration/SKILL.md` | lens-adversarial | DOC-TYPE | 모든 프로젝트에 실리는 절차 문서에 다른 저장소의 진행 중인 개발 하나에 대한 상태와 삭제 조건이 들어 있다. 삭제 조건(그 개발의 main 병합)은 이 저장소의 어느 검사도 관측할 수 없어 문장이 남는다. 이 상태는 근거 문서 「2026-10-11 개정」 쪽이나 그 개발의 큰 명… |
| 004 | `skills/nested-orchestration/SKILL.md` | lens-adversarial | NO-ASSUME | 어느 개발이 첫 큰 개발인지 기록하는 곳이 없어 현재 세션은 조건을 판정하지 못한다. 설계 문서는 결과를 「이어받는 판단과 검증」에 추가하라고 하지만, 다른 프로젝트에서는 설계 문서가 플러그인 설치 폴더에만 있어 추가할 원본이 그 세션에 없다. 조건을 '사용자가 측정을 요청한 개발… |
| 005 | `skills/nested-orchestration/SKILL.md` | lens-adversarial | CHECKABLE | Stop 게이트는 훅 입력의 cwd 저장소만 본다. 현재 세션의 cwd 는 자기 체크아웃이고 계약 코드 plan 은 통합용 워크트리에 쓰고 커밋하므로, 계약 코드 plan 의 미리뷰를 차단하는 장치가 없다. 스킬은 게이트가 적용되지 않는 문서로 서브 세션 문서만 적어, 현재 세션은… |
| 006 | `skills/nested-orchestration/SKILL.md` | lens-adversarial | YAGNI | 시험 병합 전 확인은 `결정 기록:` 제목 커밋만 뺀다. 그런데 통합 때마다 현재 세션이 큰 명세에 커밋하는 `확정한 결정` 옮겨 적기와 '확정 예정' 칸 채우기는 ANSWER 답이 아니어서 이 제목을 쓰지 못한다. 그래서 통합이 한 번 일어날 때마다 남은 모든 워크스트림이 그 커… |
| 007 | `docs/domain-discipline.md` | lens-consistency | TERM-ONE | domain-discipline.md 는 SUB-ORCHESTRATE 의 태스크 다섯 기준을 nested-orchestration 의 「나누는 기준」으로 옮겼다고 적지만, nested-orchestration 에는 그 이름의 절이 없고 같은 기준은 「맡기는 기준」에 있다. 같은 문… |
| 008 | `skills/review-specs/SKILL.md` | lens-consistency | NO-FLEET | review-specs 는 spec 과 plan 을 함께 보는 차수에 렌즈 여덟을 실행하고 lens-prior-art 를 승인받으면 같은 단계에 동시에 실행한다고 적는다. dispatching-lenses 는 필요할 때 그룹의 호출도 그 단계의 에이전트 상한 10 안에 세고 len… |
| 009 | `korean-banned-words.md` | lens-consistency | TITLE-LAYERS | korean-banned-words.md 는 제목을 일괄 명사구로 쓰라고 적는다. agent-principles.md 의 TITLE-LAYERS 는 슬라이드 제목을 본문 제목으로 보고 결론 한 문장으로 쓰라고 정한다. domain-discipline.md 의 LABEL-NOUN 절… |
| 010 | `hooks/nested_judgment_pretooluse.sh` | lens-consistency | lens-consistency 모순 (소유자 규칙과 훅의 불일치) | 판단 훅의 거부 사유는 맡기는 기준 두 가지 어디에도 들지 않으면 스킬을 열지 말라고 지시한다. 반면 nested-orchestration 은 사용자가 나눠 맡기라고 요구하면 규모와 관계없이 이 스킬을 쓰라고 정한다. 훅 사유에는 사용자 요구라는 세 번째 경로가 빠져 있다. |
| 011 | `skills/nested-orchestration/SKILL.md` | lens-consistency | lens-consistency 모순 (같은 문서 안의 절 사이) | 리뷰 마커 확인은 escalated 하부 명세의 🔴 답을 「결정 기록」에 적은 뒤 검사를 이어 가라고 한다. 그런데 이 경로에서는 서브 세션에 ANSWER 를 보내지 않는다. 그래서 그 커밋은 '결정 기록:' 제목 조건(ANSWER 로 보낸 답만 적은 커밋)에 들지 않는다. 시험 … |
| 012 | `skills/nested-orchestration/references/sub-session-protocol.md` | lens-consistency | TERM-ONE | 프로토콜은 작업 공간을 지우는 단계를 '마무리 정리'라고 부른다. SKILL 「흐름」에는 '마무리'(7단계, main 병합 전)와 '정리'(8단계, main 병합 뒤)가 서로 다른 단계로 있고, SDD 작업 공간 삭제는 8단계 '정리'의 목록에 있다. |
| 013 | `skills/nested-orchestration/references/sub-session-protocol.md` | lens-consistency | lens-consistency 모순 (소유자 문서와 따르는 문서) | dispatching-lenses 「렌즈 그룹」은 서브 세션의 필요할 때 그룹 처리를 하나로 정한다. 제안하지 않고 판정만 리포트에 적는다는 규칙이다. 프로토콜은 이와 별도로 사용자 승인이 필요한 렌즈를 실행해야 진행할 수 있으면 멈추고 승인을 요청하는 경로(BLOCKED user… |
| 014 | `skills/review-specs/SKILL.md` | lens-consistency | lens-consistency 모순 (소유자 문서와 따르는 문서) | review-specs 는 nested-orchestration 서브 세션이 다시 리뷰를 생략한다고 조건 없이 정한다. 프로토콜은 REVISE 의 대상이 하부 명세면 다시 리뷰하라고 지시한다. CONTRACT-CHANGED 로 하부 명세가 바뀌어도 다시 리뷰하라고 지시한다. |
| 015 | `skills/nested-orchestration/SKILL.md` | lens-consistency | lens-consistency 커버리지 공백 | 커버리지 공백이다. 'REVISE 를 쓰는 상황' 문단은 REVISE 를 보내는 때를 나열하지만 형식 이탈을 넣지 않았다. 바로 다음 「형식 이탈」 문단은 REVISE(대상: 응답)를 보낸다. |
| 016 | `docs/domain-korean.md` | lens-consistency | TERM-ONE | 근거 소유자로 SINO-KEEP 을 가리키지만 같은 파일 「삭제한 조항」은 SINO-KEEP 을 지우고 뜻과 근거를 VOCAB-PREF 로 옮겼다고 적는다. |
| 017 | `agent-principles.md` | lens-consistency | lens-consistency 모순 (소유자 문서 사이) | 에이전트원칙은 어느 렌즈를 실행하는지를 호출하는 스킬이 정한다고 한다. dispatching-lenses 「렌즈 그룹」은 그룹이 어느 렌즈를 실행하는지를 정한다고 소유를 선언한다. 같은 절은 렌즈마다 '실행하는 호출자' 칸을 두고, 호출자에게 그 절을 가리키기만 하라고 한다. |
| 018 | `CLAUDE.md` | lens-fit | DOC-TYPE | 규범·인덱스 문서에 특정 CLI 버전(2.1.296)이 지금 내는 경고라는 현재 상태를 적었다. 타입 표의 규범·인덱스 행은 상태를 적지 말라고 한다. |
| 019 | `CLAUDE.md` | lens-fit | COUNT-EARNS | 목록 앞에 개수(넷)를 예고했다. |
| 020 | `CLAUDE.md` | lens-fit | BULLET-SCOPE | 불릿 한 항목이 여섯 문장이다. |
| 021 | `README.md` | lens-fit | TITLE-LAYERS | 남에게 전달되는 문서인 README 에 ### 소제목 층을 두었다. TITLE-LAYERS 는 문서의 절 제목을 #·## 두 층으로 두고 ### 층을 두지 말라고 한다. |
| 022 | `README.md` | lens-fit | domain-readme 「독자 분리」 | 사용자용 README 에 이 저장소에서만 실행되는 개발용 hook(seal_reviews.sh)과 변수를 나눈 내부 사유 같은 개발자 근거를 섞었다. |
| 023 | `README.md` | lens-fit | COUNT-EARNS | 목록 앞에 개수를 예고하고 대상을 개수로 가리켰다. |
| 024 | `README.md` | lens-fit | ONE-IDEA | 한 단락에 여섯 문장을 두었다. ONE-IDEA 는 단락을 네 문장 이하로 끊으라고 한다. |
| 025 | `README.md` | lens-fit | BULLET-SCOPE | 불릿 한 항목이 일곱 문장이다. BULLET-SCOPE 는 한 항목이 여러 문장이 되면 산문으로 쓰라고 한다. |
| 026 | `agent-principles.md` | lens-fit | COMMA-CUT | 한 문장에 연결어미 뒤 쉼표가 두 개('덜어 내고,'·'손보고,') 있어 COMMA-CUT 의 한도 하나를 넘는다. |
| 027 | `agent-principles.md` | lens-fit | COMMA-CUT | 한 문장에 연결어미 뒤 쉼표가 두 개('되었고,'·'분기하며,') 있어 COMMA-CUT 의 한도 하나를 넘는다. |
| 028 | `docs/domain-discipline.md` | lens-fit | ONE-IDEA | 한 단락에 여덟 문장 이상이 있다(연결 문장 전환, superpowers v7 변경, 기준 이중화 추정, 판단 시점 고정, 조항 존치 이유, 우선순위 근거, 설계 문서 포인터). |
| 029 | `docs/domain-discipline.md` | lens-fit | ONE-IDEA | 한 단락에 열 문장 안팎이 있다(시험 조건, 과제, 큰 개발 결과, 작은 개발 결과, 발동 시점, 원칙 없음 조건, 확인 못 한 점, 실행 횟수, 재시험, 재시험 결과). |
| 030 | `docs/domain-discipline.md` | lens-fit | ONE-IDEA | 단락이 여섯 문장이다(층 비용, 첫 조건, 10-10 전환, 지금 문구, 2차 리뷰, 3차 리뷰). |
| 031 | `docs/domain-discipline.md` | lens-fit | ONE-IDEA | 단락이 일곱 문장이다(ASK-CONTEXT 병합, 병합 이유, 사용자 요청, 계기, 분량 기준 이유, 시험 생략, 생략 이유). |
| 032 | `docs/domain-discipline.md` | lens-fit | ONE-IDEA | 종결어미 '조용하다' 뒤를 쉼표로 이어 세 대상(CLAUDE.md·스킬·rules)의 특성을 한 문장에 넣었다. 또 첫 문장이 대상을 '셋'이라는 개수로 가리킨다. |
| 033 | `docs/domain-discipline.md` | lens-fit | COUNT-EARNS | 비교 대상(CLAUDE.md·스킬·rules)을 이름 대신 '셋'이라는 수사로 가리킨다. |
| 034 | `docs/domain-discipline.md` | lens-fit | COUNT-EARNS | 읽는 쪽을 나열하기 전에 '둘이다'로 개수를 예고한다. |
| 035 | `docs/domain-discipline.md` | lens-fit | TERM-ONE | 같은 시험 방식을 '클린룸 시험'·'클린룸 측정'·'클린룸 소거 시험' 세 이름으로 부른다. |
| 036 | `docs/domain-discipline.md` | lens-fit | TERM-EXPLAIN | superpowers 안에서만 통하는 'HARD-GATE' 를 풀이 없이 쓴다. 문서 안에 이 용어가 이곳에만 나온다. |
| 037 | `docs/domain-korean.md` | lens-fit | COUNT-EARNS | 목록 앞에 개수를 예고했다. 뒤 문장이 읽는 쪽을 모두 이름으로 적으므로 '셋'은 결론을 바꾸지 않는 개수다. |
| 038 | `docs/domain-korean.md` | lens-fit | COMMA-CUT | 한 문장에 연결어미 뒤 쉼표가 둘이다. |
| 039 | `docs/domain-korean.md` | lens-fit | COMMA-CUT | 한 문장에 연결어미 뒤 쉼표가 둘이다. |
| 041 | `docs/domain-korean.md` | lens-fit | ONE-IDEA | 한 단락이 네 문장을 넘는다. |
| 042 | `docs/domain-korean.md` | lens-fit | BULLET-SCOPE | 불릿 한 항목이 여러 문장이다. |
| 043 | `docs/korean-banned-words-evidence.md` | lens-fit | TITLE-LAYERS | 하단 규칙 절들의 ## 절 제목이 개념 명사구가 아니라 마침표로 끝나는 규칙 문장이다. TITLE-LAYERS 는 ## 절 제목을 목차로 보고 명사구로 쓰라고 한다. |
| 044 | `docs/korean-banned-words-evidence.md` | lens-fit | DOC-TYPE | 항목마다 분류와 켜짐·꺼짐 상태를 다시 적는데, 이 값은 목록 파일(korean-banned-words.md)의 분류 칸과 '꺼 둔 항목' 문단에서 도출할 수 있다. DOC-TYPE 은 도출할 수 있으면 원본을 가리키라고 한다. |
| 046 | `korean-banned-words.md` | lens-fit | BULLET-SCOPE | 불릿 각 항목이 여러 문장이다. |
| 048 | `skills/aggregating-lenses/SKILL.md` | lens-fit | COUNT-EARNS | 발견이 지는 칸 목록 앞에 개수를 예고한다. |
| 049 | `skills/aggregating-lenses/SKILL.md` | lens-fit | ONE-IDEA | 한 단락이 다섯 문장이다. |
| 050 | `skills/aggregating-lenses/SKILL.md` | lens-fit | BULLET-SCOPE | 불릿 한 항목이 세 문장이다. |
| 051 | `skills/audit-repo-docs/SKILL.md` | lens-fit | COUNT-EARNS | 단계 표 앞에 단계 개수를 예고한다. |
| 052 | `skills/audit-repo-docs/SKILL.md` | lens-fit | COUNT-EARNS | 불릿 목록 앞에 단계 개수를 예고한다. |
| 053 | `skills/audit-repo-docs/SKILL.md` | lens-fit | COUNT-EARNS | 원인 목록 앞에 개수를 예고한다. |
| 054 | `skills/audit-repo-docs/SKILL.md` | lens-fit | COUNT-EARNS | 처분 목록 앞에 개수를 예고한다. |
| 055 | `skills/audit-repo-docs/SKILL.md` | lens-fit | COUNT-EARNS | 판정 상태를 이름 대신 수사 '셋'으로 가리킨다. |
| 056 | `skills/audit-repo-docs/SKILL.md` | lens-fit | ONE-IDEA | 한 단락이 일곱 문장이다. |
| 057 | `skills/audit-repo-docs/SKILL.md` | lens-fit | ONE-IDEA | 한 단락이 여섯 문장이다. |
| 058 | `skills/audit-repo-docs/SKILL.md` | lens-fit | ONE-IDEA | 한 단락이 여섯 문장이다. |
| 059 | `skills/audit-repo-docs/SKILL.md` | lens-fit | BULLET-SCOPE | 불릿 한 항목이 다섯 문장의 논증이다. |
| 060 | `skills/audit-repo-docs/SKILL.md` | lens-fit | SUBJECT-OBJECT | 절 이름을 근본 원인을 찾아내는 주체로 적는다. |
| 061 | `skills/dispatching-lenses/SKILL.md` | lens-fit | COUNT-EARNS | 불릿 목록 앞에 개수를 예고한다. |
| 062 | `skills/dispatching-lenses/SKILL.md` | lens-fit | NAME-ITEMS | 근거를 개수로 예고하고 첫째·둘째·셋째 번호로 가리킨다. |
| 063 | `skills/dispatching-lenses/SKILL.md` | lens-fit | ONE-IDEA | 한 단락이 네 문장을 넘는다. |
| 064 | `skills/dispatching-lenses/SKILL.md` | lens-fit | BULLET-SCOPE | 불릿 한 항목이 네 문장으로 이어진다. |
| 065 | `skills/domain-plugin/SKILL.md` | lens-fit | COUNT-EARNS | 목록 앞에 개수를 예고하고 그 개수를 대명사처럼 썼다. |
| 066 | `skills/domain-plugin/SKILL.md` | lens-fit | BULLET-SCOPE | 불릿 한 항목이 다섯 문장이다. |
| 067 | `skills/domain-pruning/SKILL.md` | lens-fit | COUNT-EARNS | 앞서 나열한 원인을 '이 네 원인'으로 개수로 가리켰다. |
| 068 | `skills/domain-pruning/SKILL.md` | lens-fit | ONE-IDEA | 한 단락에 일곱 문장을 두었다. |
| 069 | `skills/lens-adversarial/SKILL.md` | lens-fit | COUNT-EARNS | 축 목록 앞에 개수를 예고한다. 같은 문장 바로 뒤에서 축 이름을 모두 적는다 |
| 070 | `skills/lens-adversarial/SKILL.md` | lens-fit | BULLET-SCOPE | 불릿 한 항목이 다섯 문장으로 된 논증이다 |
| 071 | `skills/lens-consistency/SKILL.md` | lens-fit | COUNT-EARNS | 판정 목록 앞에 개수를 예고한다. 바로 아래 불릿이 불일치·좁혀 적음·같음을 이름으로 적는다 |
| 072 | `skills/lens-fit/SKILL.md` | lens-fit | COMMA-CUT | 한 문장에 연결어미 뒤 쉼표가 둘 있다 |
| 073 | `skills/lens-fit/SKILL.md` | lens-fit | COUNT-EARNS | 이름 종류 앞에 개수를 예고하고, 판정 단계 번호 목록 앞에도 단계 수를 예고한다 |
| 074 | `skills/lens-fit/SKILL.md` | lens-fit | BULLET-SCOPE | 불릿 한 항목이 여러 문장과 하위 번호 목록을 포함한 논증이다 |
| 075 | `skills/lens-grounding/SKILL.md` | lens-fit | COUNT-EARNS | 출처 목록 앞에 개수를 예고한다. 바로 다음 문장이 대상 코드와 인프라, 소유자 문서를 이름으로 적어 개수가 정보를 보태지 않는다 |
| 076 | `skills/lens-prior-art/SKILL.md` | lens-fit | COUNT-EARNS | 절 제목이 추가 칸을 이름 대신 개수로 가리킨다 |
| 077 | `skills/lens-prior-art/SKILL.md` | lens-fit | COUNT-EARNS | 표 앞에 경우의 개수를 예고하고 '넷'을 대명사처럼 쓴다 |
| 078 | `skills/lens-prior-art/SKILL.md` | lens-fit | BULLET-SCOPE | 가드 불릿 여러 항목이 각각 두세 문장의 논증이다 |
| 079 | `skills/lens-readability/SKILL.md` | lens-fit | BULLET-SCOPE | 불릿 한 항목이 세 문장으로 이어져 논증을 이룬다. |
| 080 | `skills/nested-orchestration/SKILL.md` | lens-fit | DOC-TYPE | 절차·계약 타입 문서에 특정 개발(NP-bond-agg)의 진행 상태와, 그 개발이 병합되면 문장을 지운다는 다음 단계가 적혀 있다. 문서 타입 표의 절차·계약 행은 상태를 적지 말고 방법만 적으라고 정한다. |
| 081 | `skills/nested-orchestration/SKILL.md` | lens-fit | TERM-ONE | 스킬은 첫머리에서 2026-10-09 설계 문서를 '근거 문서'로 이름 짓고, 「언제 쓰는가」와 「큰 명세」에서는 '설계 문서'를 사용자 프로젝트의 spec 이라는 뜻으로 쓴다. 마무리 단계는 같은 근거 문서를 '설계 문서'로 불러 한 이름이 두 대상을 가리킨다. |
| 082 | `skills/nested-orchestration/SKILL.md` | lens-fit | TERM-ONE | 용어 표는 SDD 의 실행 주체를 '구현 워커'로 정의하고 「흐름」·「디스패치 템플릿」 5번은 '워커'를 쓰는데, 6번은 같은 대상을 '구현자'로 부른다. |
| 083 | `skills/nested-orchestration/SKILL.md` | lens-fit | COMMA-CUT | 한 문장에 연결어미 뒤 쉼표가 두 개("실패하면,"·"확인하고,") 있다. |
| 084 | `skills/nested-orchestration/SKILL.md` | lens-fit | NO-MID-MOD | 문장 중간에 관형절 두 개("그 워크스트림이 제공자나 소비자인", "그 워크스트림이 쓰는")가 끼어 있고 그 관형절이 다시 목적어 안에 겹쳐 있다. |
| 085 | `skills/nested-orchestration/SKILL.md` | lens-fit | ONE-IDEA | 「리뷰 마커 확인」 단락이 일곱 문장이다. |
| 086 | `skills/nested-orchestration/SKILL.md` | lens-fit | ONE-IDEA | 「진행 위치」 단락이 일곱 문장이다. |
| 088 | `skills/nested-orchestration/SKILL.md` | lens-fit | COUNT-EARNS | 목록 앞에 개수(세 단계)를 예고한 뒤 바로 다음 문장들이 세 단계의 이름을 모두 적는다. |
| 089 | `skills/nested-orchestration/SKILL.md` | lens-fit | COUNT-EARNS | 다른 절(「경로와 브랜치 이름」)의 목록을 개수(자기 문서 경로 셋)로 가리킨다. |
| 090 | `skills/nested-orchestration/SKILL.md` | lens-fit | SUBJECT-OBJECT | "그 파일 이름의 주제를 개발 이름으로 쓰므로"에서 누가 개발 이름으로 쓰는지(현재 세션)가 빠져 있다. |
| 091 | `skills/nested-orchestration/references/sub-session-protocol.md` | lens-fit | COUNT-EARNS | 이름을 괄호로 모두 적은 목록 앞에 '네 가지'라는 개수를 예고한다. |
| 092 | `skills/nested-orchestration/references/sub-session-protocol.md` | lens-fit | COUNT-EARNS | 절 이름을 괄호로 모두 적은 목록 앞에 '세 절'이라는 개수를 예고한다. |
| 093 | `skills/review-docs/SKILL.md` | lens-fit | DOC-TYPE | 절차·계약 타입 문서에 방법이 아닌 저장소의 현재 검사 유무를 적었다 |
| 094 | `skills/review-docs/SKILL.md` | lens-fit | COUNT-EARNS | 목록 앞에 개수를 예고한다. 적용 대상과 제시 종류를 바로 뒤에서 이름으로 적는다 |
| 095 | `skills/review-docs/SKILL.md` | lens-fit | COMMA-CUT | 한 문장에 연결어미 뒤 쉼표가 셋 있다 |
| 096 | `skills/review-docs/SKILL.md` | lens-fit | BULLET-SCOPE | 제시 종류 불릿이 각각 두 문장 이상의 논증이다 |
| 097 | `skills/review-llm-calls/SKILL.md` | lens-fit | COUNT-EARNS | 결정 값 이름 셋을 개수 '셋'으로 가리킨다. 앞 문장이 이미 accept·regenerate·escalate 를 이름으로 적었다 |
| 098 | `skills/review-llm-calls/SKILL.md` | lens-fit | BULLET-SCOPE | 체크리스트 불릿 대부분이 요건과 이유를 두 문장 이상으로 적는다 |
| 099 | `skills/review-specs/SKILL.md` | lens-fit | COUNT-EARNS | 단계 표 앞에 '아홉'이라는 개수를 예고한다. |
| 100 | `skills/review-specs/SKILL.md` | lens-fit | COUNT-EARNS | 외부 문서 목록 앞에 '넷'이라는 개수를 예고한다. |
| 101 | `skills/review-specs/SKILL.md` | lens-fit | COUNT-EARNS | 기록 항목 목록 앞에 '다섯'이라는 개수를 예고한다. |
| 102 | `skills/review-specs/SKILL.md` | lens-fit | COUNT-EARNS | 🔴 기준 목록 앞에 '셋'이라는 개수를 예고한다. |
| 103 | `skills/review-specs/SKILL.md` | lens-fit | COUNT-EARNS | 질문 목록 앞에 '셋'이라는 개수를 예고한다. |
| 104 | `skills/review-specs/SKILL.md` | lens-fit | ONE-IDEA | 한 단락이 여덟 문장이고, 호출 수 계산·읽기 전용 수단·독립성 강제라는 서로 다른 개념을 함께 다룬다. |
| 105 | `skills/review-specs/SKILL.md` | lens-fit | ONE-IDEA | 한 단락이 여섯 문장이다. |
| 106 | `skills/review-specs/SKILL.md` | lens-fit | ONE-IDEA | 한 단락이 여섯 문장이고, 제안 시점·실행 방식·통상과 최대한 선택·미정일 때의 기본값을 함께 다룬다. |
| 107 | `skills/review-specs/SKILL.md` | lens-fit | SUBJECT-OBJECT | 누가 알리고 누가 확인하는지가 빠져 있다. |
| 108 | `skills/review-specs/SKILL.md` | lens-fit | SUBJECT-OBJECT | spec 과 plan 을 구분하는 주체가 빠져 있다. |
| 109 | `CLAUDE.md` | lens-grounding | TERM-ONE | 봉인 대상을 '커밋된 감사 기록'으로 적지만 seal_reviews.sh 는 docs/superpowers/reviews/ 아래 커밋된 파일 전부를 봉인한다. review-docs 의 기록 종류에서 감사(audit)는 review·check·prior-art 와 구분되는 한 종류다. |
| 110 | `CLAUDE.md` | lens-grounding | SPECIFIC-NAME | 넛지 예외를 문서 넛지와 규칙 넛지로만 나눠 적고 검진 넛지(doc_review_posttooluse.sh)를 빠뜨렸다. 검진 넛지는 리뷰 기록은 빼지만 프로젝트 밖 문서는 빼지 않는다. |
| 111 | `CLAUDE.md` | lens-grounding | DOC-TYPE | test_docs_drift.sh 가 대체된 spec 의 superseded 표시를 검사한다고 적지만, 검사는 경로를 박은 spec 두 개(2026-08-16-review-layer-redesign-design.md, 2026-07-05-nested-orchestration-des… |
| 112 | `README.md` | lens-grounding | REPORT-DEAD | README 는 환경 변수를 넣는 단계가 pwsh 를 호출하므로 PowerShell 7 이 필요하다고 적지만, 그 단계(PYTHONUTF8 설정)는 커밋 67ac723 에서 kw-control-tower 로 옮겨 지워졌고 저장소의 hooks/·scripts/ 어디에도 pwsh 호출… |
| 113 | `README.md` | lens-grounding | NO-ASSUME | 정상 세션에서도 원칙 전문과 갱신 알림이 출력된다고 단정하지만, 갱신 알림은 설치본이 뒤처졌거나 자동 갱신이 설치본을 옮겼을 때만 나오고 최신이면 아무것도 출력하지 않는다. 원칙 전문도 @import 가 처음 만들어진 세션에만 stdout 으로 나온다. |
| 114 | `README.md` | lens-grounding | REVERSIBLE | 전역 설정을 바꾸기 전에 사본(.bak)을 남기고 바꾼 것을 알린다고 적지만, 「원칙 연결」이 ~/.claude/CLAUDE.md 에 관리블록을 쓰는 managed_block_inject 는 사본을 만들지 않고 mv 로 원본을 바꾸며, scaffold.sh 는 주입이 성공하면 아무… |
| 115 | `README.md` | lens-grounding | TERM-ONE | 봉인 대상을 '감사 기록'으로 적지만 seal_reviews.sh 는 docs/superpowers/reviews/ 아래 커밋된 파일 전부를 봉인한다. review-docs 의 「기록 파일 이름 규칙」에서 감사(audit)는 review·check·prior-art 와 구분되는 한… |
| 116 | `agent-principles.md` | lens-grounding | EVIDENCE-FIRST | NO-ASSUME 의 '측정에 10분 이상' 기준값은 근거 문서에 출처가 없다. 에이전트원칙 머리는 각 조항의 근거가 domain-discipline.md 에 있다고 하지만, domain-discipline.md 가 합의값으로 열거한 수치에 10분이 빠져 있고 그 문서 어디에도 1… |
| 117 | `agent-principles.md` | lens-grounding | FOCUSED | NO-RAW-OUTPUT 은 어느 렌즈를 언제 실행하는지를 호출하는 스킬이 정하고 dispatching-lenses 는 실행 방법만 정한다고 한다. 그러나 dispatching-lenses 의 「렌즈 그룹」은 그룹이 어느 렌즈를 실행하는지를 자기가 소유한다고 선언한다. |
| 118 | `docs/domain-discipline.md` | lens-grounding | NO-ASSUME | test_docs_drift.sh 에 「canon-sections」 묶음이 있다고 단정하지만 현재 스크립트에는 그 묶음도, 옛 서수 제목을 찾는 검사도 없다. git log -S 로 보면 그 묶음은 커밋 d75f319 등에서 지워졌다. |
| 119 | `docs/domain-discipline.md` | lens-grounding | TERM-ONE | 태스크 다섯 기준을 nested-orchestration 「나누는 기준」으로 옮겼다고 적지만, 스킬에는 그 이름의 절이나 라벨이 없고 기준은 「맡기는 기준」 라벨 아래에 있다. |
| 120 | `docs/domain-discipline.md` | lens-grounding | NO-ASSUME | _banned_words.sh 가 표 파싱과 본문 맞추기를 함수 둘로 나눴다고 적지만, 실제로는 banned_parse·banned_scan·banned_report 세 함수로 나뉘어 있다. |
| 121 | `docs/domain-discipline.md` | lens-grounding | NO-ASSUME | 리뷰 기록이 append-only 를 선언한다고 단정하지만, 저장소의 리뷰 기록·스킬·스크립트 어디에도 append-only 선언이 없다. 훅은 선언이 아니라 seal_reviews.sh 가 붙인 읽기 전용 속성만 읽는다. |
| 122 | `docs/domain-discipline.md` | lens-grounding | DOC-TYPE | 기록만 지우지 않는다고 적지만, 에이전트원칙의 기록 행과 같은 절 뒤 문단(2026-10-06)은 기록을 보존 태그 뒤 지우게 바뀌었다. 또 spec 도 지우지 않으므로 '기록만'이라는 한정이 현행 표와 맞지 않는다. |
| 123 | `docs/domain-discipline.md` | lens-grounding | KEEP-FAILED | test_docs_drift.sh 는 되살아나면 안 되는 ID 로 ASK-FORK·MEASURE-FIRST·SIMPLE·SURGICAL·TDD 를 검사하고 그 근거가 두 참고서의 「삭제한 조항」 절에 있다고 적지만, 이 절과 domain-korean.md 어디에도 이 다섯 ID 가… |
| 124 | `docs/domain-korean.md` | lens-grounding | TERM-ONE | 첫 무리(한자어를 고유어로 되돌린 것)의 근거 소유자로 SINO-KEEP 을 가리키지만, 같은 파일의 「삭제한 조항」 절은 SINO-KEEP 을 지우고 그 뜻과 근거를 VOCAB-PREF 로 옮겼다고 적는다. |
| 125 | `docs/domain-korean.md` | lens-grounding | TERM-ONE | 이 절은 금지어를 세 무리로 나누고 어느 말이 어느 무리에 드는지는 목록 파일의 분류 칸이 소유한다고 적지만, 목록 파일의 분류 칸에는 이 절의 무리 이름과 다른 분류명이 더 있다. |
| 126 | `docs/domain-korean.md` | lens-grounding | COUNT-EARNS | 구어를 일곱이라고 적었지만 괄호 안에 나열한 말은 여섯이다. |
| 127 | `docs/domain-korean.md` | lens-grounding | TERM-ONE | WRITTEN-ONLY 근거 절이 PROSE-FORM 묶음 아래에 있지만, 에이전트원칙은 WRITTEN-ONLY 를 KO-SYNTAX 묶음에 둔다. |
| 128 | `docs/domain-korean.md` | lens-grounding | STATE-ASSUME | 금지 표현은 훅이 맡는다고 단정하지만, 훅은 이 저장소 자신의 문서를 금지 표현 검사에서 뺀다. 이 제외를 이 파일은 적지 않는다. |
| 129 | `docs/korean-banned-words-evidence.md` | lens-grounding | EVIDENCE-FIRST | 끈 사유에 적힌 빈도 0.15 가 기준선 0.15 와 같은데 '미만이라 껐다'고 적혀 있어, 표시된 수치로는 끈 조건이 성립하지 않는다. |
| 130 | `docs/korean-banned-words-evidence.md` | lens-grounding | EVIDENCE-FIRST | 목록 파일의 초록불 항목에는 파란불·녹색 토큰이 있는데, 근거 파일의 초록불 절은 초록불·초록색으로 좁힌 경위만 적고 파란불·녹색을 넣은 근거가 없다. |
| 131 | `docs/korean-banned-words-evidence.md` | lens-grounding | EVIDENCE-FIRST | 목록 파일의 부분 항목에는 영역 토큰이 함께 있는데, 근거 파일의 부분 절은 부분의 빈도만 적고 영역의 근거가 없다. 근거 파일 머리는 항목마다 그 말을 왜 쓰지 않는지 적는다고 선언한다. |
| 132 | `korean-banned-words.md` | lens-grounding | TERM-ONE | 셋째 칸(적용 대상)이 적용 대상을 정한다고 적지만, 산출물을 검사하는 doc_word 훅은 적용 대상 칸을 읽지 않고 모든 행을 적용한다. |
| 133 | `skills/aggregating-lenses/SKILL.md` | lens-grounding | NO-ASSUME | 머리 문단은 집계를 프롬프트가 아니라 결정론적 코드로 구현한다고 조건 없이 단정하지만, 같은 문서의 「구현 형태」 절은 spec/plan 리뷰·문서 검진·레포 문서 감사에서 메인 세션이 직접 집계한다고 적는다. |
| 134 | `skills/aggregating-lenses/SKILL.md` | lens-grounding | SUBJECT-OBJECT | lens-prior-art 의 인용 검증 주체를 review-specs 하나로만 적지만, lens-prior-art 를 실행하는 호출자에는 review-docs 도 있다. |
| 135 | `skills/audit-repo-docs/SKILL.md` | lens-grounding | NO-ASSUME | 문서는 직전 차수 diff.json 이 잔존으로 적은 항목을 대조 대상에 넣는다고 적지만, 대조를 계산하는 audit_rounds.sh diff 는 앞선 diff.json 에서 판정이 해소인 항목만 읽고 잔존 항목은 건너뛴다. |
| 136 | `skills/audit-repo-docs/SKILL.md` | lens-grounding | NO-ASSUME | 문서는 해소 항목을 전전 차수 diff.json 과 비교해 거른다고 적지만, audit_rounds.sh diff 는 앞선 diff.json 을 하나만 인자로 받고 전전 차수 diff.json 을 읽는 경로가 없다. |
| 137 | `skills/dispatching-lenses/SKILL.md` | lens-grounding | TERM-ONE | 「렌즈 이름 표준」이 짧은 이름을 금지하는데, 같은 문서 「실행하는 방법」이 짧은 이름 grounding·fit 으로 렌즈를 가리킨다. |
| 138 | `skills/dispatching-lenses/SKILL.md` | lens-grounding | DOC-PLACE | 한 호출에 여러 대상을 묶는 예외를 「렌즈 그룹」이 정한다고 적지만, 「렌즈 그룹」은 필요할 때 그룹만 묶을 수 있다고 적고 문서 단위 그룹의 입력은 '문서 하나'로 둔다. 실제 문서 단위 그룹의 다문서 묶음은 audit-repo-docs 가 자기 규칙으로 정한다. |
| 139 | `skills/domain-plugin/SKILL.md` | lens-grounding | NO-ASSUME | claude plugin validate 가 version 경고를 낸다고 전제하고 그 경고를 수용하라고 적지만, 이 PC 의 CLI 2.1.296 은 version 이 빈 plugin.json 에 version 경고를 내지 않는다. 저장소 CLAUDE.md 도 2.1.296 은 v… |
| 140 | `skills/domain-pruning/SKILL.md` | lens-grounding | SUBJECT-OBJECT | 사본 분류의 근거를 lens-consistency 가 낸 duplication 발견이라고 적지만, lens-consistency 는 복제를 판정하지 않으며 duplication 은 레포 문서 감사의 호출자가 같음 판정에서 도출해 붙인다고 정한다. |
| 141 | `skills/lens-consistency/SKILL.md` | lens-grounding | audit-repo-docs | 렌즈가 레포 감사에서 받는 입력을 값이 다른 짝뿐이라고 적지만, 소유자 문서 audit-repo-docs 와 dispatching-lenses 는 소유를 선언한 문서마다 이 렌즈를 문서 단위로 한 번씩 더 실행한다. 그 호출의 입력과 판정(커버리지 공백)이 이 렌즈 파일에 없다 |
| 142 | `skills/lens-fit/SKILL.md` | lens-grounding | NO-ASSUME | 금지 낱말을 이 렌즈가 보지 않는 근거로 .md 산출물 훅만 들지만, 이 렌즈를 실행하는 review-docs 는 .html·.pptx·.xlsx·.docx·.pdf 산출물도 대상으로 삼고 금지 표현 훅은 .md 가 아니면 검사 대상에서 뺀다 |
| 143 | `skills/lens-grounding/SKILL.md` | lens-grounding | NO-ASSUME | 인용 실재 확인을 audit_evidence.sh 가 한다고 조건 없이 단정하지만, 그 스크립트는 레포 감사의 findings.json 형식(`findings` 키)만 읽고 렌즈 원본의 `issues` 키는 읽지 않으며, 이 렌즈를 실행하는 review-docs 와 review-s… |
| 144 | `skills/lens-prior-art/SKILL.md` | lens-grounding | review-specs | 호출자가 URL 응답을 먼저 확인해 결과를 렌즈에 넘기고 렌즈는 인용이 주장을 뒷받침하는지만 판단한다고 적지만, 소유자로 지목한 review-specs 의 인용 검증 절은 렌즈가 돌려준 citations 를 메인 세션이 사후에 확인하고 뒷받침 여부도 호출자가 확인한다고 정하며 결과… |
| 145 | `skills/lens-prior-art/SKILL.md` | lens-grounding | aggregating-lenses | 이 렌즈의 issues 항목에 file 칸이 없지만, 공통 계약의 예외는 이 렌즈에서 빠지는 칸을 counterpart_file·counterpart·principle 셋으로만 적는다 |
| 146 | `skills/lens-readability/SKILL.md` | lens-grounding | FOCUSED | 「읽기 범위」는 기준 문서를 domain-korean 과 에이전트원칙 둘로 닫는데, 같은 문서의 「기계에 넘기는 것」은 TITLES 묶음의 근거를 보러 docs/domain-discipline.md 를 열라고 한다. |
| 147 | `skills/lens-readability/SKILL.md` | lens-grounding | TERM-ONE | wrong-job 표시를 「반드시 읽히는 곳의 필수 내용」이 정의한다고 적지만, 그 절 본문에는 wrong-job 이라는 이름이 없고 개념만 서술되어 있다. |
| 148 | `skills/lens-readability/SKILL.md` | lens-grounding | SPECIFIC-NAME | purpose 의 뜻을 aggregating-lenses 의 리뷰 산출물 계약이 소유한다고 적지만, 그 계약 스키마에는 purpose 칸이 없고 purpose 는 별도 절 「렌즈가 추가하는 칸」 표에만 있다. |
| 149 | `skills/lens-readability/SKILL.md` | lens-grounding | STATE-ASSUME | 다른 프로젝트의 .md 산출물은 쓰는 순간 훅이 거부한다고 단정하지만, 훅은 스위치가 off 이거나 파이썬이 없거나 경로가 Claude 메모리·docs/superpowers/ 아래이면 통과시킨다. |
| 150 | `skills/nested-orchestration/SKILL.md` | lens-grounding | NO-ASSUME | 스킬은 pathspec 의 `*`가 `/`까지 맞는 동작을 의도한 동작으로 설명한다. 근거 문서의 「2026-10-11 개정 — 검진 반영」은 같은 동작을 결함으로 적고 `*`가 한 단계 경로만 맞게 고치라고 정했다. 그 절은 위 절과 다르면 구현하는 세션이 이 절을 따른다고 선언한다. |
| 151 | `skills/nested-orchestration/references/sub-session-protocol.md` | lens-grounding | TERM-ONE | 스킬이 메시지 용어를 넘기는 프로토콜 파일은 디스패치 프롬프트를 하향 메시지로 정의한다. 근거 문서의 「시작 형식 결정」은 `START`·`RESTART`를 디스패치 머리줄로 두고 하향 메시지에 세지 않는다고 정했다. |
| 152 | `skills/nested-orchestration/SKILL.md` | lens-grounding | NO-ASSUME | 정리 단계는 각 워크스트림 워크트리에 SDD 작업 공간이 남아 있다고 전제한다. 그러나 superpowers 6.4.1 SDD 는 최종 브랜치 리뷰가 깨끗하면 `DONE` 이전에 작업 공간을 지우고, 프로토콜 파일은 SDD 규칙을 그대로 따르게 하면서 `DONE` 뒤의 삭제만 금지… |
| 153 | `skills/nested-orchestration/references/sub-session-protocol.md` | lens-grounding | FOCUSED | 멈추는 때의 목록에 FAILED 가 빠져 있다. 같은 파일의 상향 메시지 표는 FAILED 를 끝낼 수 없을 때 보내는 메시지로 두고, 근거 문서의 개정 지시는 이 문장에 FAILED 를 예외로 적으라고 정했다. |
| 155 | `skills/nested-orchestration/references/sub-session-protocol.md` | lens-grounding | FOCUSED | 한 번에 user-decision 사유가 둘 이상일 때 두 번째 이후 사유의 유형을 적는 방법이 없다. 근거 문서는 `요청` 필드의 줄마다 유형을 적게 정했으나, 프로토콜은 나머지 사유를 사유 코드와 함께만 적게 한다. |
| 156 | `skills/nested-orchestration/references/sub-session-protocol.md` | lens-grounding | TERM-ONE | 절 첫 문장은 SDD 규칙을 그대로 따르고 추가만 한다고 적지만, 같은 절 둘째 문단은 SDD 가 최종 리뷰 뒤 하는 작업 공간 삭제와 finishing-a-development-branch 실행을 하지 않게 해 SDD 규칙을 대체한다. |
| 157 | `skills/nested-orchestration/SKILL.md` | lens-grounding | FOCUSED | 프로토콜은 상향 메시지로 FAILED 와 CANCELED 를 두고 SKILL.md 「FAILED와 CANCELED」는 둘 다 사용자에게 묻는 처리를 정하지만, 현재 세션의 재시작 복구는 마지막 메시지가 AWAITING_APPROVAL·BLOCKED·DONE 인 것만 미답으로 본다. |
| 158 | `skills/review-docs/SKILL.md` | lens-grounding | NO-ASSUME | 훅이 산출물에 넛지를 낸다고 적고 이 문서는 .html 을 산출물에 넣지만, 검진 넛지 훅은 .pptx·.xlsx·.docx·.pdf 만 산출물로 보고 .html 은 넛지 대상과 '산출물이 있는 폴더' 판정 어디에도 넣지 않는다 |
| 159 | `skills/review-docs/SKILL.md` | lens-grounding | NO-ASSUME | 금지 낱말을 렌즈가 보지 않는 근거로 .md 산출물 훅만 들지만, 이 절차의 대상인 .html·.pptx·.xlsx·.docx·.pdf 산출물은 금지 표현 훅의 검사 대상이 아니다 |
| 160 | `skills/review-docs/SKILL.md` | lens-grounding | NO-ASSUME | 이 규칙은 문서 검진·spec 리뷰·레포 감사·워크플로 검증이 모두 따른다고 정하고 렌즈 원본 이름을 audit_verify.sh 가 검사한다고 적지만, 그 스크립트는 레포 감사 차수 폴더 전용이라 findings.json·run.json 이 없는 review·check 폴더에는 … |
| 161 | `skills/review-specs/SKILL.md` | lens-grounding | NO-ASSUME | 하드 게이트가 열리는 조건으로 커스텀 경로·git 밖·기존 커밋된 spec 수정만 적고, Stop 훅이 이 세션이 시작되기 전에 만든 미추적 spec·plan 초안을 보지 않는다는 조건을 적지 않는다. |
| 162 | `skills/nested-orchestration/references/sub-session-protocol.md` | lens-consistency | lens-consistency 모순 (같은 문서 안의 절 사이) | 용어 표는 START·RESTART 를 하향 메시지에 세지 않는다고 정한다. 공통 필드 규칙은 '모든 하향 메시지'에만 워크스트림과 통합 브랜치를 요구한다. START 의 추가 필드에는 두 필드가 없다. 또 '어느 하향 메시지 뒤에도 BLOCKED·FAILED를 돌려준다'는 규칙도… |

## 차수 대조

직전 차수 2026-09-06-self-audit 의 발견과 대조해 해소 93건, 잔존 4건, 재발 0건이다. 앞선 기각을 자동으로 유지한 발견은 없다. 해소율은 0.958 이다.

## 되풀이되는 근본 원인

**목록 앞 개수 예고(복제된 관례).** 스킬 열 곳 이상과 참고서 둘이 "셋을 지킨다", "넷이다" 처럼 목록 앞에 개수를 예고하거나 개수로 대상을 가리켰다. 문서마다 따로 생긴 것이 아니라 같은 문형을 베껴 쓴 결과라 한 단계에서 함께 고쳐야 다음 문서로 번지지 않는다.

**단계 개수 검사(검사의 모양).** `scripts/test_audit.sh` 의 「단계 개수」 검사가 `단계는 N이고` 문장과 표 행 수를 대조한다. 그래서 `audit-repo-docs` 와 `review-specs` 는 `COUNT-EARNS` 를 어기는 문장을 지울 수 없다. 이 검사를 표 행에서 도출하는 형태로 바꾸거나 지우면 두 문서의 지적이 함께 사라진다.

**금지 표현 훅의 범위 서술(복제된 관례).** "금지 표현은 훅이 맡는다" 는 문장이 `lens-readability`, `lens-fit`, `review-docs`, `docs/domain-korean.md` 에 복제되었고, 넷 모두 훅이 `.md` 만 보고 이 저장소를 뺀다는 조건을 빠뜨렸다.

**긴 불릿과 긴 단락(복제된 관례).** `BULLET-SCOPE` 와 `ONE-IDEA` 지적이 스킬과 참고서 대부분에서 나왔다. 불릿 한 항목에 근거 논증을 이어 쓰는 관례가 저장소 전체에 퍼져 있어, 한 문서씩 고치면 다른 문서가 같은 형태를 다시 베낀다.

**설계 개정의 결함 표와 스킬 사이의 연결(연결이 빠진 단계).** nested-orchestration 설계 문서 「2026-10-11 개정 — 검진 반영」의 결함 표 중 제외 패턴, SDD 작업 공간 삭제, `FAILED` 멈춤, 디스패치 머리줄이 스킬과 프로토콜에 반영되지 않았다. 결함 표의 각 행이 스킬에 반영되었는지 대조하는 단계가 개정 절차에 없다.

**렌즈 실행 결정의 소유(한 문서가 소유한 규칙).** 에이전트원칙 `NO-RAW-OUTPUT` 은 어느 렌즈를 실행할지를 호출하는 스킬이 정한다고 하고, `dispatching-lenses` 「렌즈 그룹」은 그 결정을 자기가 소유한다고 선언한다. 소유자인 에이전트원칙의 문구를 고쳐야 하며 그 일에는 클린룸 시험이 필요하다.

## 사용자에게 올릴 질문

- 에이전트원칙 문구 변경(`NO-RAW-OUTPUT` 의 렌즈 결정 소유, `EDIT-PRIORITY`·`EXPLAIN-STRUCTURE` 의 쉼표, `NO-ASSUME` 의 10분 근거)을 클린룸 시험과 함께 진행할지 정해야 한다.
- 금지어 `그게` 는 만자당 0.152 로 기준선 0.15 이상인데 꺼져 있다. 다시 켤지 정해야 한다.
- nested-orchestration 스킬의 NP-bond-agg 진행 상태 문장을 그 개발이 병합될 때까지 둘지 정해야 한다.
- 「첫 큰 개발에서 측정」 포인터의 판정 조건을 바꿀지와, 결정 기록 커밋이 만드는 `BASE-UPDATED` 왕복을 줄이는 설계를 열지 정해야 한다.
- 단계 개수 검사와 긴 불릿 관례를 설계로 넘길지 정해야 한다.
- `lens-readability` 제안 스물넷(README·CLAUDE.md·show-principles·에이전트원칙)을 반영할지 정해야 한다.
