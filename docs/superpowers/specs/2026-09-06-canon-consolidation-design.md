# 정본 통합 설계 — 규칙집 스킬 셋을 정본 하나로 접는다

## 무엇을 푸는가

규칙집이 정본과 스킬 넷에 흩어져 있어 상시로 걸려야 할 규칙이 조건부로 걸린다. 어제 정본을 쪼갠 기준은 "파일을 하나도 건드리지 않은 답 한 번으로도 어길 수 있으면 정본에 남는다"였다. 그 기준으로 코딩 규칙과 문서 규칙을 `domain-coding`과 `domain-writing`과 `domain-doc-upkeep`과 `domain-korean`으로 옮겼다.

옮긴 규칙은 스킬이 열려야 실린다. 스킬이 열리는 경로는 셋이고 셋 다 Claude의 판단을 거친다. Claude가 `description`을 보고 여는 길, 사용자가 `/이름`을 치는 길, 훅이 `additionalContext`로 열라고 알리고 Claude가 그것을 읽고 여는 길이다. 훅은 도구 호출을 일으키지 못하므로 어느 길로도 확정되지 않는다.

사용자가 그 기준의 전제를 반증했다. Claude Code를 쓰는 세션은 어지간하면 코딩 아니면 문서 작업이고, 그렇지 않은 간단한 작업은 규칙이 실려도 안 실려도 결과가 같다. 지연 로딩이 버는 구간이 양쪽 다 없다. 그러면 확정적인 쪽을 고르는 것이 맞다.

## 무엇을 하는가

규칙집 스킬 넷 중 셋을 정본으로 접는다. `domain-korean`은 스킬로 남는다.

정본은 원칙을 먼저 정의하고 「대화할 때」와 「문서를 쓰고 관리할 때」와 「코딩할 때」로 나누어 그 작업에 걸리는 원칙을 이름으로 부른다. 한 원칙을 두 번 적지 않는다.

절차와 산출물 한 종류에만 걸리는 것은 정본에 넣지 않고 스킬로 뺀다. 원칙은 상시로 걸리고 절차는 그 절차를 돌 때만 걸리기 때문이다.

## 분량을 어떻게 보는가

정본 초안은 175줄이다. 상시로 실리는 분량이 52줄에서 175줄로 3.4배가 된다. 옛 다섯 파일 합계 375줄과 견주는 것은 옳지 않다. 그중 84줄인 `domain-korean`은 그대로 남으므로 실제 비교는 지연 로딩 291줄에서 상시 175줄로 가는 것이다.

`CLAUDE.md` 권고 상한 200줄은 이 정본 한 파일이 아니라 조립된 `CLAUDE.md` 전체에 걸리는 값이다. 이 정본은 사용자 `~/.claude/CLAUDE.md`의 관리블록으로 들어가므로 사용자 고유 내용과 프로젝트 `CLAUDE.md`가 그 위에 얹힌다. 그래서 175줄은 상한 안이 아니라 상한에 근접한 값으로 다룬다.

`domain-korean`이 "정본에 한 줄이 늘 때마다 다른 줄이 걸릴 확률이 함께 떨어진다"고 적어 두었다. 이 설계는 그 대가를 치르는 대신 확정성을 얻는 것이며, 대가가 있다는 것을 알고 고른다. 다음 회차에서 분량이 다시 늘면 문서 타입 표와 수정 규율 표를 스킬로 빼는 것을 먼저 본다. 그 둘이 원칙이 아니라 분류표이기 때문이다.

## 어디로 무엇이 가는가

| 출처 | 내용 | 목적지 |
|---|---|---|
| `agent-principles.md` | 조항 여덟 | 정본 「원칙」과 「대화할 때」 |
| `agent-principles.md` | Think Before Acting | 정본 「Karpathy guidelines」 |
| `agent-principles.md` | `LOCAL-FIRST` 문단 | 정본 「코딩할 때」 |
| `agent-principles.md` | 「검증」·「미해결의 처분」·「병렬 오케스트레이션」·「이 파일의 취급」 | 정본에 그대로 유지 |
| `domain-coding` | 카파시 세 절 | 정본 「Karpathy guidelines」, 문서판과 합쳐 한 벌 |
| `domain-coding` | 다섯 원칙 | 정본 「원칙」 셋과 「코딩할 때」 둘 |
| `domain-coding` | 출처 인용 여덟 | 버린다 |
| `domain-coding` | 「Reach」 | `EXPLICIT` 조항에 흡수 |
| `domain-writing` | 카파시 문서판 세 절 | 코드판과 합쳐 한 벌 |
| `domain-writing` | 머리말과 「Reach」 | `EXPLICIT` 조항에 흡수 |
| `domain-writing` | 「규칙 (문서 일반)」 일곱 | 셋은 기존 조항에 흡수, 넷은 정본 「문서를 쓰고 관리할 때」 |
| `domain-writing` | README 절과 출처 링크 | `domain-readme` 스킬 |
| `domain-writing` | 「글 유형별 적용」 다섯 | 넷은 버리고 외부 공개 문서 줄은 `review-docs` |
| `domain-doc-upkeep` | 머리말의 소유권 경계 | 버린다. 소유자가 바뀌므로 |
| `domain-doc-upkeep` | 「시작점」 여섯 걸음 | 정본에 다섯, 검진 걸음은 `review-docs` |
| `domain-doc-upkeep` | 문서 타입 표·수정 규율 표·메모리와 백로그·문서 맵 | 정본 「문서를 쓰고 관리할 때」 |
| `domain-doc-upkeep` | 기록 이름 규칙 | 정본에 **전문 그대로** 옮긴다. 아래를 참고한다 |
| `domain-doc-upkeep` | 「문서 검진 방법」 | `review-docs` 스킬 |
| `domain-korean` | 「금지 표현」 표를 포함해 전부 | 그대로 남는다 |

### 기록 이름 규칙에서 빠뜨린 넷

초안 정본이 이 규칙을 옮기면서 넷을 떨어뜨렸다. 되살린다.

- 레포 감사는 주제가 `self`라 `2026-09-05-self-audit.md` 꼴이 된다.
- 회차 표기가 `-review-2.md`뿐 아니라 `-audit-2.md`도 된다.
- 렌즈 원본 파일은 스킬 디렉터리 이름을 그대로 쓰므로 `lens-grounding-1.json`이고 접두사를 떼지 않는다.
- 이 규칙의 소유자가 정본이고 `scripts/audit_verify.sh`가 그대로 검사한다.

`skills/audit-repo-docs/SKILL.md` 98행과 `skills/review-specs/SKILL.md` 93행이 이 규칙의 소유자를 가리키므로, 그 두 줄의 가리키는 곳을 `domain-doc-upkeep`에서 정본으로 바꾼다.

## 금지 표현 표는 옮기지 않는다

사용자가 "금지 표현 목록을 스크립트로"를 골랐다. 그 뜻은 사람의 판단이 아니라 기계로 거르자는 것이었는데, **그 기계 검사가 이미 그 표에서 도출되고 있다.** `scripts/test_docs_drift.sh` 587행이 `skills/domain-korean/SKILL.md`의 「금지 표현」 절을 awk로 긁어 금지어 목록을 만든다. 표를 `.tsv`로 옮기면 그 목록이 비고 검사 전체가 아무것도 못 잡은 채 통과한다. `lens-readability` 17행과 87행도 그 절을 열어 읽으라고 지시한다.

그래서 표를 옮기지 않고 `domain-korean` 안에 둔다. `scripts/forbidden_words.tsv`는 만들지 않는다. 사용자에게 이 반전을 알린다.

## 왜 `domain-korean`만 남는가

정본의 네 조항은 각 한 줄로 압축됐다. 조항은 지시이고 예시는 판정 기준인데, `lens-readability`가 판정하려면 후자가 필요하다. 「금지 표현」 표도 그 파일이 소유자이고 기계 검사가 거기서 도출된다.

앞서 "파일이 남으면 렌즈가 84줄만 읽는다"고 적었던 근거는 틀렸으므로 뺀다. `lens-readability`의 「읽기 범위」는 "받은 문서와 목적, 그리고 기준 문서인 `domain-korean`과 원칙 정본만 본다"라 그 렌즈는 어느 쪽이든 정본을 이미 연다.

## 무엇을 만들고 무엇을 지우고 무엇을 고치는가

### 만드는 것 둘

`review-docs` 스킬이 문서 검진 절차를 갖는다. 절차라 동사구 이름이 맞다. `domain-readme` 스킬이 README 고유 규칙과 출처 링크를 갖는다. 규칙집이라 `domain-` 접두사를 붙인다. `domain-plugin`이 소유한 이름 부류 규칙을 따른 것이다.

둘 다 `description`을 이 설계에서 정한다. 여는 상황을 실제 요청 낱말로 적고 배선 설명은 넣지 않는다.

### 지우는 것 셋

스킬 셋(`domain-coding`·`domain-writing`·`domain-doc-upkeep`)이다.

훅 둘(`rules_nudge_pretooluse.sh`·`rules_nudge_sessionstart.sh`)은 **지우지 않는다.** 삭제 근거였던 "정본이 상시로 실리므로 알릴 대상이 없다"가 정본 자신과 부딪힌다. 정본은 "서브에이전트에 이 문서가 실린다고 가정하지 않는다"고 적고 README도 같은 말을 한다. 그 훅은 `agent_id`로 서브에이전트를 따로 세도록 만들어졌고, matcher에 `Bash`가 들어 있는 유일한 훅이라 셸 편집을 잡는다. 남는 훅 둘은 `Write|Edit`만 본다.

대신 그 훅의 메시지를 바꾼다. 지금은 `domain-coding`과 `domain-writing`을 열라고 하는데, 정본 경로와 `domain-korean` 경로를 알리는 문구로 바꾼다. 서브에이전트가 정본을 못 받는다는 구멍이 그대로 남기 때문이다.

### 고치는 것 스물셋

지울 이름 셋이 살아 있는 파일 스물셋에 아흔여섯 번 나온다. 이것이 이 회차의 실제 편집 대상이며, 계획이 파일마다 무엇을 무엇으로 바꾸는지 적는다.

| 파일 | 무엇이 걸리는가 |
|---|---|
| `CLAUDE.md` | 관리블록 밖 본문의 스킬 이름 |
| `README.md` | 훅 표와 넛지 절과 프로젝트 폴더 절 |
| `hooks/doc_format_pretooluse.sh` | 「글 유형별 적용」 절을 가리키는 메시지 |
| `hooks/doc_review_posttooluse.sh` | 검진 절과 수정 범위를 가리키는 메시지 |
| `hooks/rules_nudge_pretooluse.sh` | 열라고 알리는 스킬 이름 |
| `scripts/scaffold.sh` | 주석의 스킬 이름 |
| `scripts/audit_verify.sh` | 기록 이름 규칙의 소유자 |
| `scripts/test_scaffold.sh` | 정본 검사 열넷과 스킬 존재 검사 |
| `scripts/test_docs_drift.sh` | 참조 검사와 금지어 도출과 「정본을 알리는 법」 루프 |
| `scripts/test_hooks.sh` | 넛지 메시지 검사와 절 실재 검사 |
| `scripts/test_audit.sh` | 기록 이름 규칙 소유자 검사 |
| `skills/dispatching-lenses/SKILL.md` | 호출자 목록 |
| `skills/aggregating-lenses/SKILL.md` | 호출자 이름 |
| `skills/audit-repo-docs/SKILL.md` | `description`과 본문의 소유자 참조 |
| `skills/review-specs/SKILL.md` | 이름 규칙 소유자와 Surgical Changes 참조 |
| `skills/review-llm-calls/SKILL.md` | 참조가 있으면 함께 |
| `skills/nested-orchestration/SKILL.md` | 구현자·문서 서브에이전트에 넣을 경로 |
| `skills/lens-fit/SKILL.md` | `description`의 호출자와 계약 |
| `skills/lens-grounding/SKILL.md` | `description`의 호출자 |
| `skills/lens-readability/SKILL.md` | `description`의 호출자 |
| `skills/lens-adversarial/SKILL.md` | 참조가 있으면 함께 |
| `skills/lens-consistency/SKILL.md` | 참조가 있으면 함께 |
| `skills/domain-plugin/SKILL.md` | 이름 부류 규칙의 예시 다섯 |

`hooks/hooks.json`은 훅을 안 지우므로 손대지 않는다.

### 시험을 다시 쓴다

`scripts/test_scaffold.sh` 402~446행의 정본 검사 열넷이 옛 분할을 못 박고 있어 이 설계와 정반대다. 지금 실측이 `test_scaffold.sh` PASS=275 FAIL=15, `test_docs_drift.sh` PASS=376 FAIL=8이다. 그 검사들을 새 정본의 구조를 겨누도록 다시 쓴다.

가드를 지워서 초록을 만들지 않는다. 정본이 조항 열넷과 카파시 넷과 절 넷을 갖는다는 것을 새 단언으로 세우고, 지운 스킬 셋의 디렉터리가 없다는 것과 살아 있는 코드에 그 이름이 없다는 것을 단언한다.

### `lens-fit`의 계약을 다시 정한다

`review-docs`가 `lens-fit`에 넘기는 계약은 둘이다. 정본 `agent-principles.md`와 `skills/domain-korean/SKILL.md`다. `domain-readme`는 README를 쓸 때만 계약에 더한다.

## 형식

조항의 ID는 유지한다. 타이틀은 한국어 번역이 아니라 통용되는 영어 표현을 쓴다. 본문은 한국어다. Karpathy guidelines 절만 영어 원문을 유지하되 목적어를 code에서 artifact로 바꾼다.

절 안에서 원칙 사이에 순서를 두지 않고 이름으로만 부른다.

정본은 `docs/rationale-korean.md`를 가리키지 않는다. 그 파일은 없고 근거의 소유자는 `skills/domain-korean/SKILL.md`다. 초안의 그 줄을 고친다.

## 전제

훅이 도구 호출을 일으킬 수 없다는 것은 공식 문서로 확인했다. "Command hooks communicate through stdout, stderr, and exit codes only. They can't trigger `/` commands or tool calls."

`CLAUDE.md` 권고 상한 200줄과 `@path` 임포트의 재귀 깊이 4단계도 같은 문서로 확인했다.

`SKILL.md`에는 `@import`이 없다. 스킬은 마크다운 링크로 가리키기만 하고 Claude가 직접 읽어야 한다.

## 되돌리기

이 회차는 되돌리기 어렵다. `plugin.json`의 `version`을 비우는 정책과 마켓플레이스 `autoUpdate: true`가 겹쳐, `main`에 올리면 버전 게이트 없이 다음 세션에 배포된다. 스킬 셋이 사라진 상태를 사용자가 세션에서 고를 방법이 없다.

그래도 진행하는 근거는 셋이다. 지우는 것은 내용이 아니라 파일이고 내용은 전부 정본이나 새 스킬로 옮겨 간다. git 이력에 옛 파일이 남아 되돌릴 수 있다. 그리고 사용자가 이 통합을 직접 지시했고 대안(스킬로 두고 안 열릴까 걱정하기)을 검토한 뒤 골랐다.

## 하지 않는 것

코드 검진 절차를 만들지 않는다. 코드 리뷰는 `code-review` 내장 스킬과 카파시 플러그인이 맡는다는 것이 앞선 결정이다.

렌즈 여섯의 판정 논리는 손대지 않는다. `description`과 본문의 스킬 이름 참조만 고친다.

이름을 새로 짓는 것은 새 스킬 둘뿐이고, 기존 스킬의 이름은 바꾸지 않는다.

`scripts/forbidden_words.tsv`를 만들지 않는다.

## 성공 기준

`scripts/test_*.sh` 전부가 FAIL=0이고 `claude plugin validate ./`가 `version` 경고 하나만 낸다.

정본이 200줄 이하다.

지운 스킬 셋의 이름이 **살아 있는 코드에** 남지 않는다. 판정 범위는 `agent-principles.md`, `CLAUDE.md`, `README.md`, `commands/`, `hooks/`, `scripts/`, `skills/`, `.claude-plugin/`이다. `docs/superpowers/` 아래의 spec과 plan과 리뷰 기록은 범위 밖이다. 설계 문서는 그때의 판단을 담은 기록이라 고치지 않고, 리뷰 기록은 `seal_reviews.sh`가 읽기 전용 속성을 세워 훅이 편집을 거부한다.

옮긴 내용 가운데 버리기로 명시하지 않은 것이 사라지지 않는다. 기록 이름 규칙의 넷이 정본에 있는지 문자열로 확인한다.

`domain-korean`의 「금지 표현」 표가 그대로 있고 `test_docs_drift.sh`의 금지어 목록이 비지 않는다.

<!-- spec-review: escalated -->
