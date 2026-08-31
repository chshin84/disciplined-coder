# 자기감사 기록 — 2026-08-31 회차

대상은 `disciplined-coder` 저장소 전체이고, 실행체는 `.claude/workflows/self-audit.js`다. 결정론
검사 다섯과 플러그인 유효성 검사를 먼저 돌린 뒤 렌즈를 병렬로 띄웠고, 발견마다 사실성과 실질성을
두 관점에서 반박해 살아남은 것만 확정으로 올렸다. 서브에이전트는 아흔다섯이 돌았고 실패한 것이 없다.

| 수치 | 값 |
|---|---|
| 확정 발견 | 31건 |
| 반박으로 기각 | 11건 |
| 미판정 | 0건 |
| 응답 없는 렌즈 | 없다 |

## 결정론 검사

**scripts/test_assertions.sh** — PASS=5 FAIL=0 이다. 검사 스크립트마다 단언 없는 블록이 없는지 보는 메타 검사이며, test_codex_scaffold.sh·test_docs_drift.sh·test_hooks.sh·test_scaffold.sh 네 파일을 모두 훑고 통과했다.

**scripts/test_codex_scaffold.sh** — PASS=40 FAIL=0 이다. Codex 홈 스캐폴딩의 멱등성(3회 실행 후 관리영역 1개), CRLF 관리영역 인식, CODEX_HOME 우선 해석, 하위 디렉터리에서 중단하지 않고 stderr로 드러내기, .codex-plugin 매니페스트가 가리키는 훅 파일과 스킬 폴더의 실재까지 모두 통과했다.

**scripts/test_docs_drift.sh** — PASS=293 FAIL=0 이다. 가장 큰 검사이며, 앵커가 실제로 잡히는지부터 확인한 뒤(렌즈 디렉터리가 하나 이상 있다) 문서 사이의 드리프트를 훑고 전부 통과했다.

**scripts/test_hooks.sh** — PASS=66 FAIL=0 이다. 훅의 경로 추출과 FAIL-OPEN 거동을 보며, 'non-git cwd → FAIL-OPEN(통과)'과 '존재하지 않는 cwd → FAIL-OPEN(통과)'을 포함해 모두 통과했다.

**scripts/test_scaffold.sh** — PASS=227 FAIL=0 이다. PC 전역 스캐폴딩(fresh-pc부터 missing-canon까지)을 보며, 원본이 없을 때 FAIL-LOUD 경고를 내고 exit 0 으로 끝나는 경로까지 통과했다.

**전체 러너 (CLAUDE.md 정본 명령)** — CLAUDE.md 14행에 적힌 형태 그대로 돌렸고 마지막 줄이 ALL PASS 였다. 다섯 스크립트를 모두 찾아 돌렸으며 합계는 PASS=631 FAIL=0 이다. 실패 이름을 모아 마지막에 알리는 형태라 앞선 실패가 마지막 종료 코드에 묻히지 않는다.

**claude plugin validate ./ (non-strict)** — exit 0 이며 'Validation passed with warnings' 이다. 경고는 하나뿐이고 'plugins[0] plugin.json → version: No version specified' 인데, CLAUDE.md 17행이 'version 경고 하나만 내면 정상이다'라고 이미 정본으로 규정한 상태라 계약 위반이 아니다.

**자기 원칙 감사 — 확정 발견** — 확정 발견은 0건이다. SSOT 관점에서 러너 명령의 중복을 찾아 README.md·CLAUDE.md·docs 전체를 grep 했으나 CLAUDE.md 11·14·17행 한 곳에만 있었고, 매니페스트가 가리키는 훅 파일과 스킬 폴더의 실재는 test_codex_scaffold.sh 가 이미 검사로 붙들고 있다. 환경 원인으로 건너뛴 검사는 없다 — bash 와 claude CLI 가 모두 있었다.

---

## 전체 판정

이번 회차는 구조적으로 건강하다. 응답하지 않은 렌즈가 없고 미판정도 없으므로 판정에 이르지 못한 채 사라진 발견이 없으며, 결정론 검사 다섯과 플러그인 유효성 검사가 모두 통과했다. 확정 발견 31건은 서로를 부정하지 않고, 대부분이 한 뿌리에서 갈라져 나온다 — 코드나 디렉터리에서 도출할 수 있는 사실을 문서와 프롬프트가 손으로 베껴 두었고, 그 사본을 붙드는 검사가 없거나 있어도 다른 것을 재고 있다. 예외 개수와 잠금 시간과 매니페스트 설명과 감사 대상 목록과 트리의 파일 이름이 모두 같은 방식으로 낡았고, 그것을 잡아야 할 검사 쪽에서도 죽은 블록과 항진 단언과 주석만 약속하는 단언이 나왔다. 그래서 이 회차가 남기는 가장 중요한 사실은 개별 발견의 내용이 아니라 초록 신호의 보증 범위다 — `ALL PASS`와 `PASS=631 FAIL=0`은 회귀가 없다는 근거로 쓰기에 좁고, 그 좁음을 확정 발견 넷이 실행으로 보였다.

## 확정 발견 정리

### 사용자 결정이 필요한 것

**설치 보고 통로의 존치** — 두 스캐폴드의 `created` 변수는 어디서도 값을 받지 않아 마지막 보고 줄이 한 번도 돌지 않는데, `/setup-discipline` 커맨드는 그 보고를 근거로 새로 생긴 파일과 이미 있던 파일을 알리라고 지시한다. 갈림은 둘이다 — 보고를 되살려 복사 분기에서 `created`를 채우거나, 보고를 걷어내고 커맨드의 지시를 스크립트가 실제로 내는 출력 전달로 바꾼다. 두 발견의 처방이 서로 반대 방향을 허용하므로 방향을 먼저 정해야 한다.

**구 오답노트 디렉터리의 처분** — `SCAFFOLD_STALE`에 확장자 없이 들어간 `solved_problems`는 치우기 반복문이 정규 파일만 보는 탓에 아무 일도 하지 않고, 디렉터리로 남은 PC에서는 해소할 수 없는 경고가 매 세션 반복된다. 디렉터리에도 파일과 같은 사본 이동 규율을 적용하거나, 그 항목을 목록에서 빼고 경고 문안에 사람이 지우면 된다는 조치를 적는 두 길이 있다.

**스킬 진입로 등재 검사의 존치** — `test_docs_drift.sh`의 등재 검사는 주석과 출력 이름으로 "정본이 스킬 이름을 부르는지 본다"고 약속하지만 실제 단언은 스킬 자기 설명의 한국어 서술어만 훑어 열넷 전부가 통과한다. 주석대로 진짜 등재 대조를 붙이면 `domain-plugin`과 `domain-spec-review`가 지금 붉어지므로, 등재를 계약으로 세울지 주석에서 그 약속을 지울지가 갈림이다.

**자기감사 실행체의 범위 지정 방식** — `.claude/workflows/self-audit.js`는 검토 대상과 정본 절 이름을 프롬프트에 손으로 열거하고, 그 목록에 이미 없앤 `domains-index.md`와 `solved_problems`와 정본에 없는 절 이름이 들어 있다. 목록을 파일에서 도출하게 고칠지, 죽은 이름만 걷어내고 열거를 유지할지는 이 레포가 자기 규정(`project-doc-audit`의 "목록은 손으로 적지 말고 파일에서 도출한다")을 실행체에도 걸 것인지의 문제다.

**Codex 설치 명령의 확인** — README의 Codex 설치 단계는 실행할 명령 없이 괄호로 대신하고, 저장소 어느 문서에도 실제 명령이 없다. 명령을 확인해 적을지, 확인하지 못했다는 사실을 README에 드러낼지는 외부 사실 확인이 필요한 갈림이다.

### 즉시 알려야 하는 것

**사용자 전역 지침이 사본 없이 사라질 수 있는 경로** — `_managed_block.sh`의 관리블록 주입은 걷어내기 `awk`의 종료 코드를 보지 않고 뒤 `awk`의 성공만으로 대상 파일을 갈아치운다. 첫 `awk`만 실패하게 만든 재현에서 사용자가 손으로 적은 줄이 사라진 채 관리블록만 남았고 함수는 성공으로 돌아왔다. 대상이 git 밖의 `~/.claude/CLAUDE.md`이고 주입 경로에는 사본이 없어 되돌릴 수 없으므로, 처분 방향은 하나뿐이며 결정을 기다릴 성질이 아니다.

### 사용자용 문서가 코드와 어긋난 것

README는 자동 계층이 프로젝트 파일을 고치는 예외를 머리말에서 둘로 적고 본문에서 하나로 적으며 DESIGN-NOTES는 두 자리에서 셋으로 적는데, 코드에서 도출한 참값은 하나다. README는 스캐폴드가 빈 파일만 지운다고 약속하지만 내용이 든 구 관리파일은 알림 없이 사본으로 옮겨진다. README는 잠금이 관리 디렉터리에 있다고 적었으나 잠금은 `CLAUDE.md` 옆에 생기고, 같은 문장이 잠금 대기 시간 두 값을 코드에서 베껴 적어 상수가 바뀌면 조용히 틀린 값이 된다. README의 기능 목록은 제안과 넛지만 소개해 턴 종료를 실제로 막는 spec·plan 게이트와 그 해제 방법을 Claude 사용자에게 알리지 않는다. 마켓플레이스 매니페스트는 이미 걷어낸 solved-log 스캐폴딩을 아직 기능으로 광고한다.

### 개발자용 문서가 실재하지 않는 것을 가리키는 것

DESIGN-NOTES의 저장소 구성 트리는 없는 스킬 `skills/migrate-solved-log/SKILL.md`를 실재하는 것처럼 적고, 서브에이전트 도달 실측 표는 머리 행 넷과 구분 행 여섯과 본문 행 여섯과 산문의 "다섯 열"·"스무 칸"이 모두 어긋나 표로 렌더되지도 않는다. 같은 문서가 없어진 오답노트 로그의 append-only 성질을 현재 시제로 단정하고, 그 방법의 소유자로 `domain-docs`를 가리키지만 그 파일에는 해당 내용이 없다. 살아 있는 문서 여럿이 정본에 존재하지 않는 「검증 레이어」 절과 표를 여덟 자리에서 가리키며, 그 가운데 하나는 실제로 실행되는 자기감사 프롬프트다. 되돌린 재작성 대응표는 인용한 가드의 줄 번호가 어긋난 데다 그 가드가 이제 만들어지지 않는 문자열을 지킨다. `domain-docs`는 정본에 없는 `NO-PRIORITY` 원칙 ID를 두 번 참조한다.

### 렌즈와 절차 문서의 내부 모순

`reviewer-prior-art`는 자기 호출자에 `project-doc-audit`을 적었으나 그 절차와 정본은 이 렌즈를 배제한다고 못 박았고, 같은 파일의 설명은 spec 전용이라 적어 한 파일 안에서 두 행동이 갈린다. 같은 렌즈의 가드 둘은 출력 스키마에 없는 `detail` 필드에 적으라고 지시한다. `reviewer-readability`는 읽기 범위에서 문서 밖으로 나가지 않는다고 선언하고도 판정 전에 `writing-korean` 파일을 열라고 지시해, 그 렌즈가 기준 문서를 실제로 읽었는지 산출물로 확인할 수 없다. `project-doc-audit`은 걸음이 여섯이라고 선언한 뒤 일곱 행짜리 표를 붙이고 멈추는 지점을 번호로 부르며, 「대상 아님」 목록이 되돌린 작업의 기록을 담지 않아 superseded 문서가 회차마다 감사 대상으로 끌려 들어온다.

### 검사가 재지 않는 것

`.claude-plugin/plugin.json`은 저장소 어디에서도 JSON으로 파싱되지 않아 쉼표 하나가 어긋나도 전체 검사가 초록으로 남는다는 사실이 재현으로 확인되었다. 검사 스크립트 둘에는 픽스처를 세우고 스캐폴드를 돌린 뒤 아무것도 단언하지 않는 블록 넷이 있고, 그 블록이 쓰던 죽은 변수와 공용 함수와 주석이 함께 남았다. solved-rules 블록에 하나 남은 단언은 어떤 코드도 낼 수 없는 문자열을 찾으므로 무엇을 고쳐도 참이며, 같은 부류의 격리 단언이 하나 더 있다.

### 문체 규칙을 산출물 자신이 어긴 것

리뷰어 렌즈들의 레퍼런스 프롬프트가 명사 조각이나 조사로 끝나고 같은 문장이 렌즈마다 다르게 끝나며, `nested-orchestration`의 괄호 주석 셋과 `domain-llm-runtime`의 두 줄과 `domain-docs`의 출처 괄호 둘이 서술어 없이 명사로 끊긴다. 이 문장들은 서브에이전트에 그대로 실려 나가는 지시문이라 판정자가 자기 지시문에서 판정 대상 조항을 어기는 형태다.

## 상충

**`created` 보고의 방향** — 설치 커맨드 발견은 커맨드 쪽을 고치는 길과 스크립트 쪽을 고치는 길을 모두 열어 두었고, 죽은 변수 발견도 채우는 길과 걷어내는 길을 모두 열어 두었다. 두 발견을 각각 독립으로 처리하면 한쪽은 보고를 되살리고 다른 쪽은 같은 줄을 걷어내는 결과가 나온다. 한 결정으로 두 발견을 함께 닫아야 한다.

**`solved_problems` 항목의 존치** — 디렉터리 미처분 발견의 한 갈래는 그 이름을 `SCAFFOLD_STALE`에서 빼자고 하는데, 그 목록은 `test_docs_drift.sh`가 "이 레포가 뜯어낸 기능"의 정본으로 삼아 다른 검사의 입력으로 쓰고, 마켓플레이스 발견의 처방도 그 목록에서 이름을 도출하는 새 단언을 제안한다. 이름을 빼는 선택은 그 두 검사의 근거를 함께 무너뜨린다.

**README 잠금 문단에 겹친 세 처방** — 빈 파일 삭제 서술과 잠금 위치 오기와 잠금 시간 복제는 모두 README의 같은 문단을 대상으로 하고, 각 발견이 제안한 문장이 서로를 덮는다. 세 처방을 한 번에 합쳐 그 문단을 다시 쓰지 않으면 마지막에 적용한 것만 남는다.

**`test_codex_scaffold.sh` solved-rules 블록의 처분** — 죽은 블록 발견은 걷어내거나 실제 단언을 붙이라 하고, 항진 단언 발견은 없어진 기능을 재는 단언을 상수와 함께 걷으라 한다. 같은 블록에 남기는 방향과 지우는 방향이 함께 놓여 있다.

**`self-audit.js:84`에 걸린 두 처방** — 「검증 레이어」 발견은 그 줄의 절 이름을 정본의 실제 절 이름으로 바꾸라 하고, 자기감사 범위 발견은 절 이름 열거 자체를 도출로 바꾸라 한다. 도출로 가면 이름 교정이 무의미해지므로 순서를 정해야 한다.

**문체 판정의 경계** — 확정된 문체 발견 넷과 기각된 문체 발견 셋이 같은 파일의 인접한 줄을 반대로 판정했다. `nested-orchestration`은 본문 괄호 주석이 확정이고 이름표 색인 불릿이 기각이며, `domain-docs`는 출처 괄호가 확정이고 화살표 동선이 기각이고, `domain-llm-runtime`은 22행이 확정이고 8행이 기각이다. 판정은 각각 근거를 갖췄으나 그 경계 — 서술어 없는 종결은 걸리고 완결 문장 안 보조 기호는 안 걸린다는 선 — 가 `writing-korean`에 예시로만 있고 판별 기준으로 적혀 있지 않다. 다음 회차에 같은 줄이 반대로 판정될 여지가 남는다.

## 커버리지 공백

**선행 사례 대조가 없다.** 정본이 웹에 나가는 렌즈를 상시 허가에서 빼 두었으므로 `reviewer-prior-art`는 이번 회차에 돌지 않았다. 여기서 확정된 문제들이 다른 플러그인이나 도구에서 어떻게 풀렸는지는 대조되지 않은 채로 남는다.

**코드 경로의 계통적 감사가 없다.** `project-doc-audit`은 문서만 본다고 스스로 못 박았고, 이번에 잡힌 코드 결함 셋(관리블록 주입의 데이터 손실, 매니페스트 미파싱, STALE 디렉터리 미처분)은 문서와 코드를 대조하다 부수로 걸린 것이다. `hooks/` 네 훅과 `scripts/`의 나머지 경로는 결함이 없다고 말할 근거가 이번 회차에 없다.

**감사 실행체 자신이 대상 밖이다.** `self-audit.js`는 검토 대상 목록에 자기를 넣지 않으므로 그 목록이 낡았다는 사실을 감사 스스로는 구조상 알아낼 수 없다. 이번에 잡힌 것은 다른 렌즈가 파일 실재를 대조하다 걸린 우연이며, 다음 회차에도 같은 우연이 일어난다는 보장이 없다.

**실제로 훑인 문서의 집합이 확인되지 않는다.** 검토 대상이 프롬프트에 손으로 박혀 있고 그 목록에 없는 파일이 여럿 있으므로, 살아 있는 문서 가운데 어느 것이 어느 렌즈에도 안 걸렸는지를 도출할 방법이 이번 배열에 없다. 죽은 이름 둘에 렌즈 시간이 쓰인 만큼 실제 대상 일부가 밀렸을 가능성도 배제되지 않는다.

**결정론 검사의 초록이 보증하는 범위가 좁다.** 확정 발견 넷 — 매니페스트 미파싱, 단언 없는 블록 넷, 항진 단언 둘, 등재 검사의 허위 커버리지 — 이 그 초록의 일부가 아무것도 재지 않음을 실행으로 보였다. `FAIL=0`을 회귀 없음의 근거로 쓰려면 그 넷을 먼저 닫아야 한다.

**Codex 런타임의 실제 동작은 이번에도 미검증이다.** 이 기계에 codex CLI가 없어 게이트가 실제로 발동하는지는 재지 못했다. 관련 발견이 기각된 이유는 그 사실이 설계 문서에 정직히 적혀 있다는 것이지 검증되었다는 뜻이 아니므로, 미검증 상태는 그대로 남는다.

**사람이 처음부터 끝까지 읽는 문서의 동선 판정이 얇다.** README에 대한 확정 발견은 사실 불일치와 누락에 몰려 있고, 목적에 비추어 무엇이 전달을 방해하는지를 본 판정은 게이트 미기재 한 건뿐이다. 설치 절차 전체를 처음 읽는 사람의 동선은 이번 회차에서 계통적으로 검진되지 않았다.

---

## 확정 발견 전문

### 1. 자동 계층이 프로젝트 파일을 고치는 예외의 개수가 README 머리말·README 본문·DESIGN-NOTES에서 각각 둘·하나·셋으로 갈렸다.

**자리** — `README.md:3, README.md:68, docs/DESIGN-NOTES.md:274, docs/DESIGN-NOTES.md:279`

**걸린 원칙** — SSOT · FAIL-LOUD · MEASURE-FIRST · NAME-ITEMS · 렌즈 규칙 「모순」

**근거** — README.md:3 — "자동 계층이 프로젝트 파일을 고치는 예외는 둘뿐이고, 그 둘은 아래 「프로젝트 폴더에 생기는 파일」에 적었다." / README.md:68 — "자동 계층이 프로젝트 파일을 고치는 예외는 하나다(여기가 그 정본이다). 없앤 기능이 남긴 관리블록이 그 레포 `CLAUDE.md`에 있으면 걷어낸다." / docs/DESIGN-NOTES.md:274 — "프로젝트 파일에 손대는 예외 셋을 처리한다." / docs/DESIGN-NOTES.md:279 — "자동 계층이 이미 있는 프로젝트 파일에 손대는 예외 셋의 정본은 README의 「프로젝트 폴더에 생기는 파일」이다."

**결과** — 같은 사실의 개수가 세 값으로 갈려 있어 어느 것이 참인지 문서만으로는 정해지지 않는다. 실제 코드(scripts/scaffold.sh:44-65의 managed_block_remove 호출 한 자리)를 열어 보면 예외는 하나뿐이므로, README 머리말을 읽고 들어온 사람은 있지도 않은 둘째 예외를 찾다가 못 찾고, DESIGN-NOTES를 먼저 읽은 사람은 셋을 기대한 채 README로 건너가 하나만 만난다. 플러그인이 남의 레포를 건드리는 범위는 이 문서가 유일한 계약인데 그 계약의 개수가 문서 안에서 갈려 어느 쪽도 근거로 쓸 수 없고, 예외가 늘거나 줄 때마다 사람이 세 곳을 손으로 맞춰야 해 다음 변경에서 또 갈라진다.

**상세** — README.md:68이 스스로 "여기가 그 정본이다"라고 선언하고 예외를 하나만 열거하는데, 같은 파일 머리말과 DESIGN-NOTES 두 자리가 그 개수를 각자 다시 적었다. 코드를 대조하면 프로젝트 폴더를 실제로 고치는 경로는 scaffold.sh의 `managed_block_remove "$PCLAUDE" ...` 하나뿐이고, 사라진 둘째 예외의 정체는 codex-scaffold.sh:5 주석의 오답노트 언급에 남아 있으나 그 기능은 이미 `SCAFFOLD_STALE`로 치우는 대상이다. scripts/test_docs_drift.sh:276-302의 검사는 "README가 정본임을 선언하는가"와 조건 문장의 복제만 볼 뿐 개수는 재지 않아 이 어긋남이 계약 테스트를 통과한 채 남아 있다.

**처방** — README 머리말과 DESIGN-NOTES 두 자리에서 개수 낱말을 빼고 「프로젝트 폴더에 생기는 파일」 절을 가리키기만 하게 고친다. 아울러 test_docs_drift.sh의 같은 블록에 "README 밖의 문서와 README 머리말이 예외 개수를 숫자로 적지 않는다"는 부정 단언을 더한다. 함께 codex-scaffold.sh:5의 주석도 지금은 프로젝트 파일을 아예 안 고친다는 사실로 갱신한다.

**반박 1** — 인용 네 문장이 README.md:3·68과 docs/DESIGN-NOTES.md:274·279에 글자 그대로 실재하고 개수가 둘·하나·셋으로 갈려 있다. 코드를 대조하면 프로젝트 파일을 고치는 경로는 scripts/scaffold.sh:49-66의 managed_block_remove 하나뿐이고(hooks/ 네 훅과 codex-scaffold.sh는 프로젝트 폴더를 아예 안 만진다), test_docs_drift.sh:273-302은 개수를 재지 않아 이 어긋남을 통과시킨다 — 반박에 실패했다.

**반박 2** — README.md:3(둘)·README.md:68(하나)·DESIGN-NOTES.md:274,279(셋)이 같은 어구로 같은 사실의 개수를 세 값으로 적고 있음을 문자열로 확인했고, 코드 대조 결과 프로젝트 파일을 고치는 경로는 scaffold.sh:56의 managed_block_remove 한 자리뿐이라 참값은 하나다. DESIGN-NOTES:269가 스스로 NAME-ITEMS를 들어 개수를 적지 않겠다고 선언한 바로 다음 줄에서 개수를 적으므로 설계 선택으로 변호되지 않고, test_docs_drift.sh:276-302은 조건 복제만 재고 개수는 재지 않아 이 드리프트가 FAIL=0을 통과한 채 남아 있다.

### 2. README는 스캐폴드가 빈 파일만 지운다고 하지만, 내용이 든 구 관리파일은 사본으로 옮겨 관리 디렉터리에서 아무 알림 없이 사라진다.

**자리** — `README.md:72`

**걸린 원칙** — reviewer-grounding 체크리스트의 「모순」과 「누락」, 그리고 FAIL-LOUD

**근거** — README.md:72 — "스캐폴드가 스스로 지우는 것은 관리 디렉터리 안에 남은 **빈 파일**뿐이다. 내용이 든 파일과 디렉터리는 매 세션 잔존을 알리기만 하고 지우지 않으며" / scripts/_scaffold_common.sh:36-39 — "if mkdir -p \"$kdir/backups\" 2>/dev/null && mv \"$kdir/$f\" \"$kdir/backups/$f.$(date +%Y%m%d-%H%M%S).bak\" 2>/dev/null; then continue; fi"

**결과** — 관리 디렉터리에 `solved_problems.md`나 `unsolved_problems.md`를 두고 손으로 줄을 적어 온 사용자는, 새 세션을 한 번 여는 것만으로 그 파일이 자기 자리에서 사라진 것을 보게 된다. README가 내용이 든 파일은 알리기만 한다고 약속했으므로 그 사용자는 파일이 backups 아래로 옮겨졌다고 짐작할 근거가 없고, 옮기기가 성공한 회차에는 어떤 메시지도 안 뜨므로 무슨 일이 있었는지 화면에서도 알 수 없다.

**상세** — scaffold_hygiene은 두 단계로 돈다. 앞 단계는 `SCAFFOLD_STALE` 목록을 훑는데, 비어 있으면 `rm -f`로 지우고 내용이 있으면 backups로 `mv`한 뒤 `continue`한다. 성공 경로에는 echo가 없어 알림이 나가지 않으며, 알림은 사본을 못 떠서 그대로 둔 회차(41-44행)에만 뜬다. README가 말한 "알리기만 하고 지우지 않는" 규칙이 실제로 적용되는 것은 뒤 단계, 곧 화이트리스트 밖의 비STALE 파일뿐이다.

**처방** — README.md:72에 구 관리파일 단계를 한 문장으로 더한다 — 없앤 기능이 남긴 관리파일은 이름으로 알아보아, 비었으면 지우고 내용이 있으면 `backups/` 아래 사본으로 옮긴다고 적는다. 옮긴 회차에도 경로를 stderr로 한 줄 알리게 하면 README의 원래 약속과 코드가 다시 맞는다.

**반박 1** — 인용은 README.md:72와 _scaffold_common.sh 37-39행에 그대로 있고(발견이 적은 36-39는 한 줄 어긋난 범위 표기일 뿐), 첫 단계가 SCAFFOLD_STALE의 내용 있는 파일을 echo 없이 backups로 mv한 뒤 continue하므로 README가 약속한 "알리기만 한다"가 그 경로에는 적용되지 않는다. DESIGN-NOTES:273은 동작을 맞게 적었으나 README를 구제하지 못하고, 테스트에도 이 경로의 알림을 요구하는 단언이 없다.

**반박 2** — README.md:72은 관리 디렉터리 안의 내용이 든 파일을 두고 "매 세션 잔존을 알리기만 하고 지우지 않으며"라고 단언하지만, scripts/_scaffold_common.sh:37-39은 SCAFFOLD_STALE 목록(unsolved_problems.md·solved_problems.md 등 사용자가 손으로 적던 파일 포함)을 아무 출력 없이 backups로 옮기고 continue하므로 그 파일은 잔존하지도 않고 알림도 안 난다 — 예외 조항이 없고, 정확한 서술은 docs/DESIGN-NOTES.md:273에만 있어 사용자용 문서와 코드가 어긋난 상태다.

### 3. README의 기능 목록은 비블로킹 제안과 넛지만 소개해, 턴 종료를 실제로 막는 spec/plan 하드 게이트를 Claude 사용자에게 알리지 않는다.

**자리** — `README.md:11 (문서 전체에서 게이트 언급은 README.md:76·78뿐)`

**걸린 원칙** — reviewer-grounding 체크리스트의 「누락」, 그리고 EXPLICIT

**근거** — README.md:11 — "문서는 사람이 글 쓰는 흐름을 흉내 낸다 — 쓰기 전에 양식을 제안하고, 다 쓰면 검진을 넛지한다." / hooks/hooks.json Stop 항목 — "bash \"${CLAUDE_PLUGIN_ROOT}/hooks/spec_review_stop.sh\"" / hooks/spec_review_stop.sh — "printf '{\"decision\":\"block\",\"reason\":\"%s\"}\\n\""

**결과** — `docs/superpowers/specs/` 나 `plans/` 에 새 `.md`를 쓴 사용자는 턴이 끝나지 않고 차단 메시지가 돌아오는 것을 겪는데, README는 이 플러그인이 제안과 넛지만 한다고 소개했으므로 그 차단을 플러그인 동작이 아니라 고장으로 읽는다. 끄는 방법(`DISCIPLINED_CODER_REVIEW_GATE=off`)도 README에 없어 스스로 빠져나올 길을 찾지 못한다.

**상세** — README에서 "강제 게이트"라는 말이 나오는 곳은 「Codex에서 쓰기」 절의 두 줄(76행·78행)뿐이라 Claude 쪽 게이트의 존재를 독자가 역으로 추론해야 한다. Claude 쪽 배선은 hooks/hooks.json의 Stop 항목에 실재하고, spec_review_stop.sh는 미리뷰 spec/plan이 남으면 `decision: block`을 돌려준다. 이 동작의 산문 설명은 docs/DESIGN-NOTES.md와 skills/domain-spec-review/SKILL.md에만 있는데, 앞은 개발자용 내부 문서이고 뒤는 온디맨드 스킬이라 설치만 한 사용자의 읽기 경로에 들어오지 않는다.

**처방** — README 「이 플러그인이 주는 기능」에 spec/plan 하드 게이트를 한 항목으로 더한다 — 어느 경로에서 발동하는지, 무엇을 남기면 풀리는지(`<!-- spec-review: passed -->`), 어떻게 끄는지(`DISCIPLINED_CODER_REVIEW_GATE=off`)를 적고 상세는 domain-spec-review로 넘긴다.

**반박 1** — 인용 증거가 모두 실재한다 — README에서 게이트 언급은 Codex 절의 76·78행뿐이고 DISCIPLINED_CODER_REVIEW_GATE는 README에 없으며, hooks/hooks.json의 Stop 항목과 spec_review_stop.sh:59의 decision:block도 그대로 존재한다. 반증을 찾으려 상시 주입되는 agent-principles.md까지 훑었으나 게이트·마커·오프 토글이 거기에도 없어 설치만 한 Claude 사용자의 읽기 경로에 하드 게이트 설명이 들어오지 않는다는 서술이 유지된다(흠은 README 인용 행번호가 11이 아니라 10인 한 줄 어긋남뿐이다).

**반박 2** — hooks.json의 Stop 항목과 spec_review_stop.sh의 `{"decision":"block"}`으로 하드 게이트 실재를 확인했고, README의 Claude 쪽 기능 목록에는 그 존재도 해제 방법도 없어 EXPLICIT의 「암묵적으로 흘리지 말라」에 걸린다. SSOT 위임이라는 반박은 README 자신의 위임 패턴이 대상을 이름으로 부른 뒤 상세만 넘기는 형태여서 성립하지 않고, 오히려 README:86의 "강제가 아니라 가이드다"와 README:76이 문서 리뷰까지 강제 게이트로 부르는 대목이 DESIGN-NOTES:224와 어긋나 오독을 더 키운다.

### 4. `/setup-discipline` 커맨드는 새로 생성된 파일과 이미 있던 파일을 보고하라고 지시하지만, 스캐폴드는 그 사실을 어떤 출력으로도 내보내지 않는다.

**자리** — `commands/setup-discipline.md:13`

**걸린 원칙** — reviewer-grounding 체크리스트의 「환각」, 그리고 FAIL-LOUD

**근거** — commands/setup-discipline.md:13 — "실행 후 어떤 파일이 새로 생성됐고 어떤 파일이 이미 있었는지 한 줄로 보고하라." / scripts/scaffold.sh:20 — "created=\"\"" / scripts/scaffold.sh:115 — "if [ -n \"$created\" ]; then echo \"[disciplined-coder] PC knowledge initialized:$created (at $KDIR)\" >&2; fi"

**결과** — `created`는 20행에서 빈 문자열로 놓인 뒤 스크립트 어디에서도 값을 받지 않으므로 115행의 보고문은 한 번도 찍히지 않는다. 그래서 커맨드를 받은 에이전트는 지시받은 보고를 낼 근거가 없고, 지시를 따르려면 어느 파일이 새로 생겼는지를 지어내게 된다. 사용자는 설치 직후 눈으로 확인하려고 이 커맨드를 쓰는데, 확인하려던 바로 그 값이 근거 없는 문장으로 돌아온다.

**상세** — `grep -n created scripts/*.sh`로 확인하면 대입은 scaffold.sh:20과 codex-scaffold.sh:17의 빈 문자열 초기화뿐이고, 두 파일 모두 마지막 보고 줄에서만 그 값을 읽는다. 스캐폴드가 실제로 내보내는 것은 정본 복사 실패·@import 배선 실패·구 관리파일 잔존·비관리 파일 잔존·마켓플레이스 자동 갱신·프로젝트 관리블록 걷어내기의 알림뿐이다. 같은 커맨드의 뒷문장 "스크립트가 실패하면 무엇이 실패했는지 함께 보고하라"는 stderr 출력에 근거가 있어 정상이다.

**처방** — 커맨드 쪽을 고치면 13행을 "스크립트가 낸 stdout·stderr 메시지를 그대로 옮겨 보고하라"로 바꾼다. 스크립트 쪽을 고치면 정본 복사 분기에서 `dst`가 없던 회차에 `created="$created $f"`를 채운다.

**반박 1** — 인용한 세 줄이 파일에 그대로 있고, scripts/ 와 hooks/ 전체에서 `created` 에 값을 넣는 대입이 하나도 없어 scaffold.sh:115 의 보고문은 결코 실행되지 않는다. 스크립트가 실제로 내는 출력에는 '새로 생성/기존' 구분이 없으므로 commands/setup-discipline.md:13 의 지시는 근거가 없고, 같은 지적이 docs/superpowers/reviews/2026-08-30-project-doc-audit-3-check.md:105-108 에도 남아 있으나 이 브랜치에서 아직 고쳐지지 않았다.

**반박 2** — 실행으로 확인했다 — 빈 홈에 scaffold.sh를 돌려 파일 둘이 실제로 생성된 회차에도 stderr는 완전히 비었고 'initialized' 문자열은 어느 스트림에도 없었으며, `created`는 scaffold.sh:20과 codex-scaffold.sh:17의 빈 문자열 초기화 뒤 어디서도 값을 받지 않는다. 그래서 commands/setup-discipline.md:13의 "어떤 파일이 새로 생성됐고 어떤 파일이 이미 있었는지 보고하라"는 근거가 없고, 유일한 대안 신호인 첫 세션 정본 stdout 덤프는 @import 유무(had_import)에 걸린 것이라 파일 생성 여부를 알려 주지 않는다. 정당한 설계 선택으로 볼 여지도 없다 — 침묵을 '생성 없음'으로 읽으면 생성이 실제로 일어난 첫 설치에서 거짓을 보고하게 되어 오류 방향이 나쁜 쪽으로 치우친다.

### 5. 두 스캐폴드의 created 변수는 어디서도 채워지지 않아 무엇을 셋업했는지 알리는 마지막 줄이 영원히 안 돈다.

**자리** — `scripts/scaffold.sh:115, scripts/codex-scaffold.sh:17, scripts/codex-scaffold.sh:77`

**걸린 원칙** — EXPLICIT

**근거** — scaffold.sh:20 — created=""
scaffold.sh:115 — if [ -n "$created" ]; then echo "[disciplined-coder] PC knowledge initialized:$created (at $KDIR)" >&2; fi
codex-scaffold.sh:17·77 — 같은 짝이 그대로 있다

**결과** — grep으로 확인하면 두 파일 모두 created에 값을 넣는 줄이 없다. 그래서 '# 5) 보고' 절은 어떤 회차에도 실행되지 않고, 첫 설치에서 무엇이 어디에 깔렸는지 알리는 통로가 사실상 없다. 코드를 읽는 사람은 보고 기능이 있다고 믿고 다른 자리에 같은 보고를 다시 만들지 않는다.

**상세** — 셋업이 한 일을 알리는 자리가 이 한 줄뿐인데 조건이 언제나 거짓이라, 파일이 깔렸는지 확인하려면 사용자가 홈 디렉터리를 직접 열어야 한다. 최근 커밋이 죽은 변수를 걷었다고 적었으나 이 짝은 남았다.

**처방** — 복사·주입에서 실제로 만든 파일 이름을 created에 붙이거나, 보고를 되살릴 계획이 없으면 변수와 마지막 줄을 함께 걷어낸다.

**반박 1** — 인용한 네 줄(scaffold.sh:20·115, codex-scaffold.sh:17·77)이 파일에 그대로 있고, 소스되는 헬퍼를 포함해 scripts/*.sh 전체를 grep해도 created에 값을 넣는 줄이 없어 보고 조건은 언제나 거짓이다. git log -S로 보면 795357c에서 대입만 걷히고 초기화와 보고 줄이 남은 것이 확인되며, 최근 죽은 변수 정리 커밋(9e14078)은 scaffold.sh를 건드리지 않았다.

**반박 2** — 두 스크립트를 통독하고 레포 전체를 grep한 결과 created는 빈 문자열 대입뿐이고 소싱되는 헬퍼 넷 어디에도 추가 대입이 없어, '# 5) 보고' 절의 조건은 모든 회차에 거짓이다. 795357c가 solved/unsolved 스캐폴딩을 걷으며 남긴 잔해이고 9e14078은 test_docs_drift.sh만 손댔으므로 의도된 설계가 아니며, 레포 자신이 같은 부류(대입만 되고 안 읽히는 변수·늘 참인 진단 블록)를 결함으로 걷어 낸 전례가 있다. 다만 첫 설치 보고 통로가 사실상 없다는 서술은 과장이라 심각도는 낮다.

### 6. 마켓플레이스 매니페스트는 이미 걷어낸 solved-log 스캐폴딩을 아직 기능으로 광고한다.

**자리** — `.claude-plugin/marketplace.json:10`

**걸린 원칙** — SSOT · MEASURE-FIRST · FAIL-LOUD · 렌즈 규칙 「모순」

**근거** — .claude-plugin/marketplace.json:10 — "PC-global engineering discipline (agent-principles.md, SSOT) + solved-log scaffolding, auto-wired into ~/.claude on session start. See the plugin manifest for full details." / scripts/_scaffold_common.sh:6 — "SCAFFOLD_FILES=\"agent-principles.md\"" / scripts/_scaffold_common.sh:14 — "SCAFFOLD_STALE=\"... unsolved_problems.md solved_problems.md solved_problems domains-index.md\"" / scripts/test_docs_drift.sh:245 — "그 목록이 \"이 레포가 뜯어낸 기능\"의 정본이라"

**결과** — `/plugin marketplace add`로 이 마켓플레이스를 붙인 사람이 목록에서 읽는 한 줄 소개가 solved-log 스캐폴딩을 약속하는데, 설치하면 그 파일은 생기지 않을 뿐 아니라 이전 버전에서 만들어졌다면 매 세션 backups로 치워진다. 첫 세션의 동작이 설명과 정반대라 그 기능을 보고 설치한 사용자는 무엇이 실패한 것인지 진단할 방법이 없다.

**상세** — 관리 디렉터리에 두는 정본은 `SCAFFOLD_FILES`가 정본이고 그 값은 `agent-principles.md` 하나다. `.claude-plugin/plugin.json`의 description은 이미 갱신되어 "per-domain design references + runtime LLM verification reviewers + spec/plan & doc review gates"만 적으므로 두 매니페스트 가운데 marketplace.json만 낡았다. test_docs_drift.sh는 SCAFFOLD_STALE을 '뜯어낸 기능의 정본'으로 삼아 설계 문서의 superseded 표시까지 검사하면서도 검사 범위가 `docs/` 아래로 한정되어 매니페스트는 훑지 않는다. 스스로 "See the plugin manifest for full details"라며 매니페스트를 정본으로 가리키면서 그 앞에 기능 목록을 복제해 둔 것이 갈라진 원인이다.

**처방** — description에서 `+ solved-log scaffolding`을 걷고 plugin.json이 쓰는 표현으로 맞추거나, 열거를 없애고 매니페스트를 가리키는 한 문장만 남긴다. 아울러 test_docs_drift.sh의 제거 기능 블록에 "`SCAFFOLD_STALE`의 이름이 `.claude-plugin/*.json`의 사용자용 설명에 남아 있지 않다"는 단언을 더한다.

**반박 1** — 인용한 문자열이 marketplace.json:10과 _scaffold_common.sh:6·14에 그대로 있고, scaffold.sh·codex-scaffold.sh·hooks 어디에도 solved 관련 생성 경로가 없으며 solved_problems가 SCAFFOLD_STALE에 들어 매 세션 backups로 치워지므로, 마켓플레이스 설명만 걷어낸 기능을 광고하는 상태가 실재한다(plugin.json은 이미 갱신됨, 어떤 검사도 매니페스트 description을 훑지 않음). 보조 인용의 줄번호가 245가 아니라 244인 것만 어긋나며 판정에는 영향이 없다.

**반박 2** — marketplace.json:10이 광고하는 solved-log 스캐폴딩은 실제로 제거되어 SCAFFOLD_FILES에 없고 오히려 SCAFFOLD_STALE에 올라 매 세션 backups로 치워지며, plugin.json은 이미 갱신되어 두 매니페스트 가운데 marketplace.json만 낡았다. test_docs_drift.sh의 제거 기능 검사는 docs/ 아래로만 한정되어 이 드리프트를 못 잡으므로 SSOT 위반과 검사 공백이 모두 실재한다.

### 7. README는 잠금이 관리 디렉터리에 있다고 적었으나, 잠금 디렉터리는 관리 디렉터리가 아니라 CLAUDE.md 옆에 만들어진다.

**자리** — `README.md:72`

**걸린 원칙** — reviewer-grounding 체크리스트의 「불일치」, 그리고 PLAIN-KO의 좁은 말 쓰기

**근거** — README.md:72 — "프로젝트 폴더에 남은 것과 설정 홈에 남은 잠금 파일은 아예 훑지 않는다. 그래서 남은 것은 사람이 지운다. 관리 디렉터리의 잠금은 10초 뒤에 빼앗기고 그 문지기는 30초까지 기다린다." / scripts/_managed_block.sh:159 및 176 — "lock=\"$uc.lock\"" (여기서 `$uc`는 `$CLAUDE_HOME/CLAUDE.md`·프로젝트 `CLAUDE.md`·`$CODEX_HOME/AGENTS.md`다)

**결과** — 잠금이 남아 세션이 멈춘 사용자는 README를 따라 `~/.claude/disciplined-coder/` 안을 뒤지는데 거기에는 잠금이 만들어진 적이 없어 아무것도 못 찾는다. 실제로 지워야 할 것은 `~/.claude/CLAUDE.md.lock`이고, 그 경로는 바로 앞 문장이 "아예 훑지 않는다"고 배제해 둔 설정 홈에 있다.

**상세** — 잠금을 잡는 곳은 `managed_block_lock` 하나이고 호출자는 `managed_block_remove`(159행)와 `managed_block_inject`(176행) 둘뿐이며, 둘 다 대상 파일 경로에 `.lock`을 붙인다. scaffold.sh가 넘기는 대상은 `$CLAUDE_HOME/CLAUDE.md`와 프로젝트 `CLAUDE.md`이고 codex-scaffold.sh는 `$CODEX_HOME/AGENTS.md`이므로 어느 경로도 `$KDIR` 안이 아니다. 관리 디렉터리를 훑는 `scaffold_hygiene`은 잠금을 잡지도 만들지도 않는다. 덧붙여 총 대기 상한 `MANAGED_LOCK_TOTAL_TICKS=600`(60초)을 넘기면 파일을 아예 안 고치고 물러나는데, 이 결말은 README에 없다.

**처방** — "관리 디렉터리의 잠금"을 "`CLAUDE.md` 옆에 생기는 잠금(`CLAUDE.md.lock`)"으로 바꾸고, 60초를 넘게 못 잡으면 그 파일을 고치지 않고 사유를 알린 뒤 물러난다는 결말을 한 문장 더한다.

**반박 1** — README.md:72의 인용문이 그대로 존재하고, 잠금을 잡는 유일한 함수 managed_block_lock의 호출자는 _managed_block.sh:159·176 둘뿐이며 둘 다 lock="$uc.lock" 형태로 대상 파일(설정 홈 CLAUDE.md·프로젝트 CLAUDE.md·CODEX_HOME AGENTS.md) 옆에 만든다 — 어느 것도 $KDIR(관리 디렉터리) 안이 아니고, $KDIR을 훑는 scaffold_hygiene은 잠금을 잡지도 만들지도 않는다. 10초·30초 수치와 미기재된 60초 포기 결말(MANAGED_LOCK_TOTAL_TICKS=600 → "이 파일은 고치지 않는다")도 코드와 일치해 반박에 실패했다.

**반박 2** — 코드 확인 결과 잠금은 `managed_block_lock`에 넘어가는 대상 파일 옆(`$uc.lock` — `$CLAUDE_HOME/CLAUDE.md`·프로젝트 `CLAUDE.md`·`$CODEX_HOME/AGENTS.md`)에만 만들어지고, `scaffold_hygiene`은 `$KDIR`만 훑을 뿐 잠금을 잡지도 만들지도 않아 관리 디렉터리에는 잠금이 생긴 적이 없다. 따라서 README:72의 "관리 디렉터리의 잠금"은 실재하는 불일치이며, 바로 앞 문장이 "설정 홈에 남은 잠금은 사람이 지운다"고 적어 둔 것과 같은 객체를 다른 것처럼 갈라 놓아 사용자가 살아 있는 잠금을 손으로 지우게 유도한다.

### 8. README가 잠금 대기 시간 두 값을 코드에서 베껴 적어, 그 상수가 바뀌면 알려 주는 것 없이 어긋난다.

**자리** — `README.md:72`

**걸린 원칙** — SSOT · MEASURE-FIRST (domain-docs 「도출로 대체할 수 있는지 본다」)

**근거** — README.md:72 — "관리 디렉터리의 잠금은 10초 뒤에 빼앗기고 그 문지기는 30초까지 기다린다." 그 값의 실제 출처는 scripts/_managed_block.sh:81-82의 `MANAGED_LOCK_STALE_SECONDS=10`과 `MANAGED_GATE_STALE_TICKS=300`이며, 뒤의 값은 같은 파일 83행이 적은 대로 0.1초 틱이라 30초에 해당한다.

**결과** — 두 상수 가운데 하나를 조정하는 순간 README의 숫자가 조용히 틀린 값이 되고, 잠금 파일이 남았을 때 얼마를 기다려야 하는지 알려고 이 문단을 읽은 사용자는 실제보다 짧거나 긴 시간을 믿고 파일을 손으로 지운다. 문지기 값은 코드에 300틱으로 적혀 있어 30초라는 환산까지 사람이 다시 해야 하므로, 다음 사람이 값을 고칠 때 README를 함께 고쳐야 한다는 것을 알아차릴 단서도 약하다.

**상세** — 이 레포는 같은 종류의 복제를 이미 여러 자리에서 검사로 막아 두었다 — test_docs_drift.sh의 「관리 파일 목록 == 한 곳」 블록은 `SCAFFOLD_FILES`를 코드에서 뽑아 스캐폴드가 이름을 다시 적지 않는지 재고, 「프로젝트 파일 예외」 블록은 README 절 이름이 실재하는지 재기까지 한다. 잠금 시간 두 값만 그 대우를 받지 않아 사용자용 문서에 손유지 사본으로 남았다.

**처방** — README에서 두 숫자를 빼고 "오래 잡혀 있으면 스스로 빼앗는다"는 성질만 적거나, 두 값을 그대로 두려면 `_managed_block.sh`에서 상수를 뽑아 README 문장과 맞대는 검사를 test_docs_drift.sh에 더한다.

**반박 1** — 인용문은 README.md:72에 그대로 있고, scripts/_managed_block.sh:81-82의 두 상수와 83행·122행의 0.1초 틱이 30초 환산까지 정확히 뒷받침한다. 두 상수를 참조하는 곳은 스크립트와 옛 계획·리뷰 문서뿐이고 test_*.sh 다섯 개 어디에도 README 숫자를 상수와 맞대는 검사가 없어, 같은 레포가 다른 자리에서 거는 드리프트 검사만 이 값에 빠져 있다는 기술이 사실이다.

**반박 2** — README.md:72의 10초·30초는 scripts/_managed_block.sh:81-82(+:122의 sleep 0.1)의 상수를 손으로 베낀 사본이며, 이 레포는 같은 문장이 실제로 어긋났던 기록(2026-08-30-project-doc-audit-check.md:285 — "락은 30초가 아니라 10초에 빼앗고")을 갖고 있어 가설이 아니라 재발이다. domain-docs의 「도출로 대체할 수 있는지 본다」와 「문서 SSOT」에 정면으로 걸리고, 같은 README가 다른 자리에서는 "정본이라 여기 옮겨 적지 않는다"로 이미 그 규칙을 지키며, test_docs_drift.sh는 이 쌍만 붙들지 않는다.

### 9. 대응표가 인용한 가드의 줄 번호가 실제 파일과 어긋나고, 그 가드는 이제 만들어지지 않는 문자열을 지키고 있다.

**자리** — `docs/superpowers/rewrite-map/domains-index.md (표 첫 행)`

**걸린 원칙** — reviewer-grounding 체크리스트의 「불일치」(식별자가 출처와 어긋남)

**근거** — domains-index.md — "옮김 — 이 제목이 유일 문자열로 `test_codex_scaffold.sh:133`의 가드가 문다" / scripts/test_codex_scaffold.sh:127 — "check \"second run stdout lacks domains-index\" \"! printf '%s' \\\"\\$OUT9b\\\" | grep -qF '# 개발 대상(도메인) 참고서 — 인덱스'\""

**결과** — 그 가드를 확인하려고 133행을 열면 solved-rules 관련 코드가 나오고 인용한 검사는 보이지 않아, 이 표가 남긴 유일한 쓸모인 판단 근거를 되짚지 못한다. 더 나아가 127행의 검사는 지금 어떤 경로로도 생성되지 않는 문자열이 stdout에 없음을 단언하므로, 문서가 말한 "제목이 가드에 물려 있다"는 관계 자체가 이미 성립하지 않는다.

**상세** — domains-index.md는 머리말에서 되돌린 회차의 기록임을 밝히고 「새 문서 위치」 칸을 따라가지 말라고 경고하지만, 그 경고는 셋째 칸의 코드 인용까지 덮지 않으며 인용된 줄 번호는 그 뒤 test_codex_scaffold.sh가 바뀌면서 127행으로 밀렸다. 한편 `SCAFFOLD_FILES`에는 `agent-principles.md`만 있고 `domains-index.md`는 `SCAFFOLD_STALE`에 치울 대상으로 들어가 있어 스캐폴드가 그 H1을 stdout에 실을 길이 없으므로, 그 검사는 늘 통과하는 항진 단언이 되었다.

**처방** — 표의 셋째 칸에서 줄 번호를 빼고 검사 이름(`second run stdout lacks domains-index`)으로 가리킨다. 함께 test_codex_scaffold.sh:127의 검사를 살릴지 걷을지 판단한다.

**반박 1** — 인용이 모두 실재한다 — domains-index.md:15는 `test_codex_scaffold.sh:133`을 가리키지만 그 검사는 실제로 127행에 있고 133행에는 solved-rules 코드가 있다. 또 `_scaffold_common.sh`의 SCAFFOLD_FILES는 agent-principles.md 하나뿐이고 domains-index.md는 SCAFFOLD_STALE에 있어, 두 스캐폴드가 stdout을 만드는 `for f in $SCAFFOLD_FILES` 루프로는 그 H1이 실릴 길이 없으므로 127행 단언은 항진이다. 머리말 경고는 「새 문서 위치」 칸에만 걸려 셋째 칸의 코드 인용을 덮지 않는다.

**반박 2** — 인용된 `test_codex_scaffold.sh:133`은 실제 파일에서 127행이고 133행은 무관한 solved-rules 코드라, reviewer-grounding의 「불일치」(식별자가 출처와 어긋남) 정의에 그대로 걸린다. 머리말의 경고는 「새 문서 위치」 칸에만 미쳐 셋째 칸의 코드 인용을 덮지 못하고, `SCAFFOLD_FILES`가 `agent-principles.md` 하나뿐이라 그 H1은 stdout에 실릴 길이 없어 검사가 항진 단언이라는 두 번째 주장도 확인된다. 줄 번호를 검사 이름으로 바꾸는 수정은 `NAME-ITEMS`에 맞고 비용이 한 줄이라 실질 이득이 있다.

### 10. reviewer-prior-art는 자기 호출자에 project-doc-audit을 적었으나 project-doc-audit과 정본은 그 렌즈를 쓰지 않는다고 못 박았다.

**자리** — `skills/reviewer-prior-art/SKILL.md:7-8, skills/project-doc-audit/SKILL.md:84-85, agent-principles.md:42`

**걸린 원칙** — SSOT · EXPLICIT · 렌즈 규칙 「모순」

**근거** — reviewer-prior-art/SKILL.md:7-8 — "실행은 호출자가 읽기 전용 서브에이전트로 띄운다 — `domain-spec-review`의 설계 문서 리뷰와 `project-doc-audit`의 레포 문서 감사가 그 호출자다." / project-doc-audit/SKILL.md:84-85 — "**웹에 나가는 렌즈는 이 절차에서 쓰지 않는다.**" / agent-principles.md:42 — "**`reviewer-prior-art`는 뺀다**" / 같은 파일 front-matter description — "domain-spec-review가 spec에 한해 조건부로 호출한다."

**결과** — 레포 문서 감사를 도는 세션이 렌즈 파일의 첫 인용 블록을 읽으면 자기가 이 렌즈의 정당한 호출자라고 읽고, 사용자 승인 없이 웹 검색 서브에이전트를 띄운다. 정본이 상시 허가에서 이 렌즈만 뺀 이유가 웹에 나가는 비용과 질의 로그가 제3자에게 남는 것인데(SECRETS), 그 승인 절차가 통째로 건너뛰어진다. 반대로 같은 파일의 description을 읽은 세션은 spec 전용이라고 읽어, 한 파일 안에서 두 행동이 갈린다.

**상세** — 본문 첫 인용 블록만 다른 렌즈(reviewer-adversarial·reviewer-consistency)의 같은 자리 문구를 그대로 복제한 채 남았다. 그 두 렌즈는 실제로 두 호출자가 다 쓰므로 문구가 맞지만, 이 렌즈는 project-doc-audit이 이름을 대며 배제한 렌즈다.

**처방** — 7-8행의 인용 블록에서 `project-doc-audit` 호출자 문구를 지우고 description과 같이 "`domain-spec-review`가 spec에 한해 제안과 승인을 거쳐 띄운다. 레포 문서 감사에서는 쓰지 않는다"로 고친다.

**반박 1** — 인용 넷이 모두 지정 파일·행에 그대로 있고(reviewer-prior-art/SKILL.md:7-8과 :3 description, project-doc-audit/SKILL.md:84-85, agent-principles.md:42), 같은 문장이 reviewer-adversarial·reviewer-consistency에 동일하게 있어 복제 잔존이라는 서술도 확인된다. project-doc-audit이 별도 승인 시에는 쓸 수 있다고 적은 점이 유일한 완화 요인이나, 본문 줄은 조건 없이 호출자로 적어 자기 파일 description과도 어긋나므로 발견은 실재한다.

**반박 2** — 반박에 실패했다 — reviewer-prior-art/SKILL.md:7-8이 project-doc-audit을 조건 없는 호출자로 적었으나 같은 파일 front-matter(3행 "domain-spec-review가 spec에 한해 조건부로 호출한다")와 본문 105-106행("이 렌즈는 spec 리뷰 전용")이 그와 어긋나 한 파일 안의 모순이고, agent-principles.md:42와 project-doc-audit:84-85와 domain-spec-review 전반은 모두 반대쪽이라 7-8행만 홀로 다르다. "승인을 받으면 감사도 호출자"라는 정당화는 그 두 줄에 조건이 없고 spec 전용 문장과도 부딪혀 성립하지 않으며, 그 문구를 강제하는 계약 테스트도 없어 한 줄 수정으로 SSOT·EXPLICIT 위반이 사라진다. 다만 감사 세션이 실제로 무단으로 웹 렌즈를 띄운다는 consequence는 project-doc-audit 자신이 그것을 금지하므로 다소 과장이다.

### 11. reviewer-prior-art의 가드 둘이 출력 스키마에 없는 detail 필드에 적으라고 지시한다.

**자리** — `skills/reviewer-prior-art/SKILL.md:25, 65-67, 83`

**걸린 원칙** — EXPLICIT · 렌즈 규칙 「드리프트」 · meta-aggregate 산출물 계약

**근거** — 25행 — "네 축이 모두 같아야 같은 사례이고, 하나라도 다르면 그 차이를 `detail`에 적는다." / 65-66행 — "그 유형의 `detail`은 \"이 기준선과 비교되지 않았다\"까지만 적고" / 83행 출력 스키마의 이슈 필드 — `{ "where", "type", "claim", "consequence", "evidence", "citations" }` (`detail` 없음)

**결과** — 리뷰어가 지시를 그대로 따르면 스키마에 없는 `detail` 키를 붙인 JSON을 돌려주고, 그 값은 meta-aggregate의 닫힌 필드 목록에 실리지 않아 집계본에서 사라진다. 네 축 대조의 차이(오인을 막는 유일한 장치)와 weak-baseline의 범위 제한이 바로 그 사라지는 값에 담기므로, 겉만 닮은 선행 사례를 같은 것으로 오인한 판정이 차이 표기 없이 호출자에게 도달한다.

**상세** — 다른 다섯 렌즈는 어느 필드에 적으라고 지시할 때 모두 스키마에 실재하는 이름(`claim`·`evidence`·`notes`)을 부른다. reviewer-adversarial은 "새 필드를 만들지 않는 이유는 산출 형식이 `meta-aggregate`의 닫힌 목록이기 때문이다"라고 명시까지 해 두었는데, 이 렌즈만 닫힌 목록 밖의 이름을 두 번 부른다. `test_docs_drift.sh`의 렌즈 계약 검사는 `consequence`·`evidence`·`read`의 존재만 보고 본문이 부르는 필드 이름이 스키마에 있는지는 재지 않아 조용히 통과한다.

**처방** — 두 자리의 `detail`을 `evidence`로 바꾸고, 렌즈 본문이 부르는 필드 이름이 그 렌즈의 출력 스키마 블록에 있는지 대조하는 단언을 test_docs_drift.sh의 렌즈 계약 절에 더한다.

**반박 1** — 인용 셋이 파일에 그대로 존재한다 — 25행과 65행이 `detail`을 부르고, 83행 스키마와 meta-aggregate 공통 계약 어디에도 `detail`이 없으며, 레포 전체에서 `detail`은 이 두 줄에만 나온다. test_docs_drift.sh의 렌즈 계약 절은 문자열 존재와 뜻풀이 일치만 보고 본문이 부르는 필드 이름을 스키마와 대조하지 않아 조용히 통과한다. 반증 후보였던 meta-aggregate:74의 '렌즈가 자기 필드를 더할 수 있다'는 조항은 prior-art의 추가 필드를 넷으로 열거하고 이유를 자기 파일에 적으라 요구하므로 `detail`을 정당화하지 못한다. 다만 83행 `evidence` 뜻풀이가 이미 네 축의 같고 다름을 담으라고 적고 있어, 그 값이 반드시 사라진다는 결과 서술만 다소 강하다.

**반박 2** — SKILL.md 25행과 65행이 지시하는 `detail`은 그 렌즈의 출력 스키마에도, meta-aggregate가 이 렌즈에 허용한 추가 필드 넷(search_status·citations·not_found·disclosures)에도 없어 "렌즈가 자기 필드를 더할 수 있다"는 예외에 해당하지 않는다. 게다가 2026-08-16 재설계 spec이 "지금의 `detail` 한 필드는 claim·consequence·evidence 셋으로 갈라진다"고 적었고 그 내용이 현재 스키마의 `evidence` 뜻풀이에 그대로 옮겨져 있어, 두 자리는 마이그레이션이 남긴 이름 드리프트임이 확정된다. consequence의 파급 서술은 다소 과장이나 위반 자체는 실재하고 수정은 두 낱말로 끝난다.

### 12. project-doc-audit이 걸음은 여섯이라고 선언한 뒤 일곱 행짜리 표를 붙이고, 멈추는 지점을 이름이 아니라 번호로 부른다.

**자리** — `skills/project-doc-audit/SKILL.md:17, 20-28`

**걸린 원칙** — SSOT · NAME-ITEMS · MEASURE-FIRST · 렌즈 규칙 「모순」

**근거** — 17행 — "걸음은 여섯이고 순서가 있다. 넷까지 하고 멈추면 렌즈별 지적만 쌓이고 뿌리를 못 찾아, 같은 것을 문서 수만큼 고치게 된다." / 20-28행 표 본문 — 대상을 헤아린다 / 기계로 먼저 잰다 / 렌즈를 배정해 띄운다 / 결과를 한 파일에 모은다 / 상충과 커버리지 공백을 표시한다 / 되풀이되는 뿌리를 찾는다 / 가른 목록을 넘긴다(일곱 행, 마지막 행이 「처분」 절이다)

**결과** — 본문의 '여섯'을 믿은 세션이 여섯째 걸음인 뿌리 찾기에서 끝내면 마지막 걸음인 「가른 목록을 넘긴다」를 건너뛴다. 그 절은 사용자 결정이 필요한 것을 질문 도구로 띄우라고 정한 자리라(ASK-FORK), 건너뛰면 감사가 발견한 🔴가 사용자에게 안 올라가고 목록에 섞인 채 지나간다. 게다가 "넷까지 하고 멈추면"이라는 경고도 표의 넷째 걸음과 세는 기준이 달라, 경고가 겨눈 위험 지점 자체가 모호해진다.

**상세** — 「집계」 절이 나중에 걸음으로 승격되면서 표에는 행이 늘었는데 앞 문장의 수는 여섯으로 남은 것으로 보인다. 같은 레포의 domain-spec-review는 같은 형태의 표에서 "걸음은 아홉이고 순서가 있다"고 적고 실제 행도 아홉이라 관례 자체는 지켜지고 있다. domain-plugin/SKILL.md:19가 "개수를 적지 않는 이유는 항목이 늘 때마다 그 숫자가 먼저 낡기 때문이다"라고 못 박아 둔 실패 방식에 이 문서가 그대로 걸렸고, `test_docs_drift.sh`의 「이름 없는 렌즈 개수를 산문에 박지 않는다」 검사는 '렌즈'가 붙은 개수만 잡으므로 '걸음'은 재지 않는다.

**처방** — 산문에서 개수를 빼고 "걸음에는 순서가 있다"로 적어 표가 유일한 출처가 되게 하고, "넷까지 하고 멈추면"을 "결과를 한 파일에 모으는 데서 멈추면"처럼 걸음 이름으로 바꾼다. domain-spec-review의 '아홉'도 같은 이유로 함께 빼는 것을 권한다.

**반박 1** — 인용이 파일에 그대로 있다 — SKILL.md:17은 \"걸음은 여섯이고\"라고 적었는데 20-28행 표의 본문 행은 일곱이고, 마지막 행 「처분」이 ASK-FORK로 사용자 결정을 띄우라고 정한 자리(166행)라 건너뛰면 🔴가 안 올라간다. 대조 근거도 확인했다 — domain-spec-review:29의 '아홉'은 실제 아홉 행이고, test_docs_drift.sh:407-421의 개수 검사 정규식은 '렌즈'만 잡아 '걸음'은 재지 않으며, domain-plugin이 못 박은 매직 넘버 금지에 이 문서가 그대로 걸렸다.

**반박 2** — SKILL.md:17이 "걸음은 여섯"이라고 적었으나 20-28행 표의 본문 행은 일곱이라 산문과 표가 직접 모순하며, 이는 같은 레포의 domain-plugin/SKILL.md:18이 NAME-ITEMS를 근거로 명시적으로 금지한 실패 방식이고 domain-spec-review는 아홉/아홉으로 지키고 있어 정당한 설계 선택으로 볼 여지가 없다. test_docs_drift.sh:394-420의 가드는 '렌즈' 개수만 훑어 '걸음'을 못 잡으므로 기존 검사도 이를 놓치고, 산문에서 수를 빼면 표가 유일한 출처가 되어 SSOT상 실질 이득이 있다(다만 "넷까지 하고 멈추면" 경고가 겨냥을 잃었다는 부수 주장은 넷째 행이 여전히 「결과를 한 파일에 모은다」라 성립하지 않는다).

### 13. domain-docs가 정본에 없는 NO-PRIORITY 원칙 ID를 두 번 참조한다.

**자리** — `skills/domain-docs/SKILL.md:29, 51-52`

**걸린 원칙** — SSOT · NAME-ITEMS · 렌즈 규칙 「드리프트」

**근거** — 29행 — "**ID로 참조, 서수 번호 금지** — … 안정적 ID와 무순서(알파벳 용어집)를 쓴다(`NO-PRIORITY` 참조)." / 51-52행 — "이는 독자 동선이지 `NO-PRIORITY`가 금지하는 우선순위 번호가 아니다" / agent-principles.md:19 — "**`NAME-ITEMS` (이름으로 부른다)**" (정본의 원칙 목록에 `NO-PRIORITY`는 없다)

**결과** — "`NO-PRIORITY` 참조"를 그대로 따른 세션은 정본에서 그 ID를 찾지 못한다. 그러면 규칙의 근거를 확인하지 못한 채 지나가거나, 정본에 없는 원칙이라 여겨 서수 번호 금지 자체를 안 지키게 된다. 더 나쁜 경우는 리뷰어가 리턴 JSON의 `principles_applied`에 존재하지 않는 ID를 적어 오는 것이고, 그러면 호출자가 정본 도달을 관측하려고 두는 그 값이 관측하지 못하는 값이 된다.

**상세** — 같은 레포의 domain-plugin/SKILL.md:19는 같은 취지를 적으면서 현행 ID인 `NAME-ITEMS`를 부른다. 정본을 다시 쓰면서 `NO-PRIORITY`가 `NAME-ITEMS`로 바뀔 때 domain-docs만 안 따라온 이름 드리프트이며, 레포 전체에서 `NO-PRIORITY`가 나오는 살아 있는 문서는 이 두 자리뿐이다.

**처방** — 두 자리의 `NO-PRIORITY`를 `NAME-ITEMS`로 바꾸고, 스킬 문서가 부르는 백틱 원칙 ID가 정본의 원칙 목록에 실재하는지 대조하는 단언을 test_docs_drift.sh에 더한다.

**반박 1** — 인용 세 줄이 파일에 그대로 있다 — skills/domain-docs/SKILL.md 29행과 51-52행이 `NO-PRIORITY`를 부르고, agent-principles.md 11-28행의 원칙 목록에는 그 ID가 없으며 `NAME-ITEMS`(19행)만 있다. rewrite-map은 머리글에서 스스로 폐기(superseded)를 선언하고 나머지 출현은 날짜 붙은 specs·reviews라, 살아 있는 문서는 이 두 자리뿐이라는 서술도 맞다. 다만 detail의 "NO-PRIORITY→NAME-ITEMS 이름 드리프트"는 과잉 특정이다(옛 내용은 정본 서문으로 흡수됐고 NAME-ITEMS는 별개 조항이라, 51-52행은 서문을 가리켜야 정확하다) — fix의 정밀도 문제일 뿐 사실 주장은 반박되지 않는다.

**반박 2** — 정본의 원칙 목록에 `NO-PRIORITY`가 없는데 skills/domain-docs/SKILL.md:29과 :51이 그 ID를 참조하며(살아 있는 문서 중 유일한 두 자리, 나머지는 기록물), 795357c가 정본을 줄이며 남긴 이름 드리프트임이 확인된다. 예외 조항이나 설계 선택이 아니고, 이미 리뷰어 출력의 principles_applied에 존재하지 않는 ID가 실려 나온 실증 사례(2026-08-25 consistency-1.md:162)가 있어 실질 이득도 있다. 다만 :51의 대체는 `NAME-ITEMS`가 아니라 정본 서문의 무순서 규정을 가리켜야 뜻이 맞다.

### 14. reviewer-readability는 읽기 범위에서 문서 밖으로 나가지 않는다고 선언했으나 판정 전에 writing-korean 파일을 열라고 지시한다.

**자리** — `skills/reviewer-readability/SKILL.md:194, 20-21, 200; skills/meta-aggregate/SKILL.md:26`

**걸린 원칙** — SSOT · FAIL-LOUD · 렌즈 규칙 「모순」

**근거** — 194행 「읽기 범위」 — "받은 문서와 목적만 본다. 문서 밖으로 나가지 않으므로 `read`는 대개 빈 배열이다." / 20-21행 — "**판정하기 전에 그 파일을 열어 읽는다.**" / 200행 레퍼런스 프롬프트 — "**먼저 `writing-korean` 스킬 파일을 열어 고정 규칙을 읽어라**" / meta-aggregate/SKILL.md:26 — "`read`: [\"문서 밖에서 실제로 열어본 것 — 파일 경로나 URL\"]"

**결과** — 이 렌즈는 반드시 문서 밖의 파일 하나를 열어야 판정할 수 있는데, 자기 읽기 범위 절이 `read`를 대개 비우라고 말한다. 그래서 지시를 따른 리뷰어도 `read`를 빈 배열로 돌려주게 되고, 호출자는 이 렌즈가 고정 규칙 기준 문서를 실제로 읽고 판정했는지 산출물로 확인할 길을 잃는다. 그러면 명사구 제목과 말끝 통일이라는 두 고정 규칙이 통째로 안 돌아간 회차와 돌았는데 걸릴 것이 없던 회차가 구별되지 않는다.

**상세** — reviewer-fit(29행)의 같은 문장이 그대로 복제된 것으로 보인다. 그 렌즈는 실제로 계약과 후보만 보므로 맞지만, 이 렌즈는 나중에 writing-korean 필독이 붙으면서 전제가 깨졌다. 188행이 "이 렌즈는 문서 밖으로 안 나가므로 원문을 대조할 수 없다"고 한 번 더 같은 전제를 반복해 어긋남이 세 자리에 걸쳐 있다. `test_docs_drift.sh:475-476`은 렌즈가 writing-korean을 가리키는지와 프롬프트가 그 파일을 읽히는지는 재지만, 읽기 범위 절이 그것과 맞는지는 재지 않는다.

**처방** — 194행을 "받은 문서와 목적, 그리고 고정 규칙의 기준 문서인 `writing-korean` 스킬 파일을 본다. 그 파일은 문서 밖이므로 `read`에 그 경로를 반드시 적는다"로 고치고, 188행의 근거 문장도 대상을 좁혀 적는다.

**반박 1** — 인용 전부(SKILL.md 194·20-21·200·188, meta-aggregate 26, reviewer-fit 29, test_docs_drift.sh 475-476)가 줄 번호까지 그대로 실재하고, `read`가 "문서 밖에서 실제로 열어본 것"으로 정의된 이상 필독으로 지정된 writing-korean 파일은 항상 read에 들어가야 하므로 "대개 빈 배열"과 모순이다. meta-aggregate:44가 빈 read에 재시도를 걸지 않는다고 못 박아 관측 불가라는 결과도 확인되며, 같은 전제가 164행에도 있어 어긋난 자리는 셋이 아니라 넷이다.

**반박 2** — 인용 네 곳을 원문과 대조해 모두 정확했고 반박 시도가 전부 실패했다 — meta-aggregate/SKILL.md:26이 `read`를 "문서 밖에서 실제로 열어본 것"으로 SSOT에 못 박았으므로 상시 필독인 writing-korean 파일은 반드시 `read`에 들어가야 하는데, reviewer-readability:194는 그것을 대개 빈 배열이라 서술해 20-21행·200행의 필독 지시와 정면으로 어긋난다. 완화 표현 '대개'는 필독이 매 회차 걸리므로 오히려 반대 방향이고, test_docs_drift.sh:475-476은 포인터와 프롬프트만 재고 읽기 범위 절의 정합은 재지 않아 194행만 읽은 리뷰어가 기준 문서를 안 열고 판정하는 길이 열려 있다.

### 15. project-doc-audit의 「대상 아님」 목록이 되돌린 작업의 기록을 담지 않아 superseded 문서가 감사 대상으로 끌려 들어온다.

**자리** — `skills/project-doc-audit/SKILL.md:37-38, 42-43; docs/superpowers/rewrite-map/domains-index.md:3-6`

**걸린 원칙** — SSOT · MEASURE-FIRST · 렌즈 규칙 「커버리지 공백」

**근거** — project-doc-audit/SKILL.md:37-38 — "**대상 아님** — 스펙, 계획, 지난 리뷰 기록, 인수인계처럼 소비하고 지우는 문서다." / 42-43행 — "어느 목록에도 안 걸리는 파일은 빼지 말고 대상에 남기고" / domains-index.md:3-6 — "**되돌린 작업의 기록이다(superseded).** … 지금 문서를 찾을 때 이 표를 따라가지 마라."

**결과** — `docs/superpowers/rewrite-map/domains-index.md`는 스펙도 계획도 리뷰 기록도 인수인계도 아니므로 「대상 아님」 어디에도 안 걸리고 감사 대상에 남는다. 그러면 렌즈가 되돌려진 재작성 대응표를 살아 있는 문서로 읽고 「새 문서 위치」 칸이 실재하지 않는다는 지적을 회차마다 새로 올린다. 호출자가 그 지적을 반영하면 이 절이 스스로 금지한 일 — "기록을 지금 기준으로 고치면 무엇을 언제 알았는지가 사라진다" — 이 그대로 일어난다.

**상세** — 「감사 대상 고르기」 절은 판단 기준을 "앞으로 계속 읽히고 고쳐질 문서인가"로 옳게 잡아 두었으나, 그 기준을 기계로 옮긴 「대상 아님」 열거가 네 종류에 그친다. `scripts/test_docs_drift.sh:262-270`이 rewrite-map 아래 모든 파일에 `superseded` 표시를 요구하고 있으므로 그 표시 자체가 기계로 도출 가능한 배제 기준이다.

**처방** — 「대상 아님」에 "머리에 `superseded` 표시를 단 문서와 되돌린 작업의 대응표"를 한 항목으로 더한다. 손으로 경로를 열거하지 말고 표시 문자열로 도출한다.

**반박 1** — 인용한 세 곳(SKILL.md:37-38, 42-43, domains-index.md:3-6)이 모두 파일에 그대로 존재하고, 「대상 아님」 네 종류 어디에도 rewrite-map이 안 걸리는 것과 미포착 파일이 대상에 남는다는 규칙도 확인된다. 게다가 docs/superpowers/reviews/2026-08-30-project-doc-audit-3-check.md:48이 같은 공백을 커버리지 공백으로 이미 기록했고, test_docs_drift.sh:262-270이 superseded 표시를 기계로 강제하고 있어 배제 기준의 도출 가능성까지 뒷받침된다.

**반박 2** — 「대상 아님」이 넷을 이름으로 열거하고 "어느 목록에도 안 걸리는 파일은 대상에 남긴다"로 닫아 두어 rewrite-map의 superseded 대응표가 실제 감사 회차에서 대상으로 끌려 들어왔고, 그 사실은 2026-08-30-project-doc-audit-3-check.md:48-49에 커버리지 공백으로 기록되어 있다. audit-unification 설계가 이미 "superseded 표시로 성질 판정"이라는 같은 수정을 확정해 두었으나 SKILL.md에 미반영이고, test_docs_drift.sh:262-270이 그 표시를 계약으로 강제하므로 기계 도출도 성립한다.

### 16. 스킬 등재 검사는 주석이 약속한 진입로 등재를 재지 않고 자기 description의 낱말만 본다.

**자리** — `scripts/test_docs_drift.sh:455-464`

**걸린 원칙** — FAIL-LOUD · TDD · project-doc-audit 「뿌리 찾기」의 '검사의 모양'

**근거** — 455-458행 주석 — "스킬 디렉터리에서 이름을 도출해 **정본이나 도메인 목차가 그 이름을 한 번은 부르는지 본다**." / 460-464행 실제 단언 — `check "$sk 이 언제 여는지 자기 설명에 적는다" "grep -m1 '^description:' '$d/SKILL.md' | grep -qE '때|연다|쓴다|한다'"`

**결과** — 주석이 이름을 댄 사고 — 새 스킬이 정본 어디에서도 안 불려 세션이 그 스킬에 못 닿는 것 — 가 다시 나도 이 검사는 초록이다. 새 스킬의 description에 '때'나 '한다'만 들어 있으면 통과하고 한국어 서술어라 사실상 모든 description이 통과한다. CLAUDE.md가 지시한 계약 테스트를 다 돌리고 FAIL=0을 본 사람은 진입로 배선이 검증됐다고 읽지만 실제로는 아무것도 검증되지 않았다.

**상세** — 주석이 말하는 "도메인 목차"는 `docs/superpowers/rewrite-map/domains-index.md`인데 그 파일은 스스로 superseded라고 선언한 되돌린 기록이라, 대조 상대의 절반이 이미 살아 있지 않다. 지금 정본이 실제로 이름을 부르는 스킬은 `project-doc-audit`·`nested-orchestration`·`domain-docs`·`meta-aggregate`·`writing-korean`·`reviewer-*` 정도이고 `domain-plugin`과 `domain-spec-review`는 정본 본문에 이름이 없어, 주석대로 고치면 지금 붉어지는 것이 있다.

**처방** — 진입로 등재를 붙들 것이면 정본과 DESIGN-NOTES의 트리 주석을 합친 집합에 스킬 이름이 있는지 대조하도록 단언을 고치고 description 문구 검사는 별개 이름으로 남긴다. 붙들지 않기로 하면 주석에서 그 약속을 지운다 — 어느 쪽인지는 사용자 결정이 필요한 갈림길이다(ASK-FORK).

**반박 1** — test_docs_drift.sh 455-464행의 인용이 축자 일치하며, 주석은 정본·도메인 목차의 이름 등재를 본다고 약속했으나 단언은 스킬 자기 description의 한국어 서술어만 grep한다. 실행으로 14개 스킬 전부 통과함을 확인했고, 그중 domain-plugin·domain-spec-review·domain-llm-runtime은 정본에 이름이 0회인데도 통과했다. domains-index.md가 superseded임도 그 파일 첫 줄에서 확인했고, 등재를 대조하는 다른 검사는 scripts/ 어디에도 없다.

**반박 2** — 확인됐다 — scripts/test_docs_drift.sh:459의 출력 헤더와 455-458 주석은 "정본이나 도메인 목차가 스킬 이름을 부르는지" 본다고 말하지만 463행 단언은 스킬 자기 description의 한국어 서술어(때|연다|쓴다|한다)만 grep 하며, 14개 스킬 전부가 통과한다. git 795357c가 실제 등재 대조 단언(CANON/domains-index grep)을 지우고 문구 검사로 바꾸면서 주석과 헤더를 그대로 둔 것이 원인이고, 그 커밋이 root domains-index.md 도 지워 주석의 대조 상대 절반이 사라졌다. 하니스가 description을 시스템 프롬프트에 싣는다는 커밋의 근거는 단언 교체 자체는 정당화하지만 남은 주석·헤더의 허위 커버리지 주장은 정당화하지 못한다.

### 17. 살아 있는 문서 다섯이 정본에 존재하지 않는 「검증 레이어」 절과 표를 아홉 자리에서 가리킨다.

**자리** — `skills/domain-docs/SKILL.md:71, skills/domain-docs/SKILL.md:123, skills/domain-spec-review/SKILL.md:27, skills/domain-spec-review/SKILL.md:44, skills/nested-orchestration/SKILL.md:50, docs/DESIGN-NOTES.md:129, docs/DESIGN-NOTES.md:146, docs/DESIGN-NOTES.md:287, .claude/workflows/self-audit.js:84`

**걸린 원칙** — EXPLICIT · SSOT · 실패 모드(설계가 맞는데도 실행이 어긋나 실패하는 길)

**근거** — skills/domain-docs/SKILL.md:123 — "## 문서 검진 방법 (검증 레이어 절 '문서 작성' 행의 방법 상세 — 여기가 소유자)" / skills/domain-spec-review/SKILL.md:44 — "공통 방법은 `agent-principles.md`의 검증 레이어 절에 있고" / docs/DESIGN-NOTES.md:129 — "멀티에이전트 워크플로에 검증을 요구하는 규율은 `agent-principles.md`의 검증 레이어 표가 소유한다" / 정본 대조: `grep -c "검증 레이어" agent-principles.md` → 0, `grep -c "^|" agent-principles.md` → 0. 정본의 해당 절 제목은 "## 검증 — LLM 단독 출력을 그대로 마치지 않는다"이고 표가 아니라 산문과 불릿이다.

**결과** — 정본에서 렌즈 배정을 확인하려는 세션은 "검증 레이어 절의 '문서 작성' 행"을 찾다가 절 이름도 표도 행도 없는 문서를 만나고, 무엇을 따라야 하는지 정하지 못한 채 자기 판단으로 렌즈를 고르게 된다. domain-docs가 자기 절을 그 행의 상세라고 정의하므로 소유권 선언 자체가 무효가 되고, 사라진 표에서 방법을 가져오라는 지시를 받은 세션은 그 걸음을 건너뛰거나 지어낸다.

**상세** — 이 어긋남은 알려진 채로 방치되어 있다. `docs/superpowers/specs/2026-08-30-audit-unification-design.md:62`가 "「검증 레이어」 이름 — 정본에 절 이름을 되살리지 않고 가리키는 쪽을 고친다"를 이미 정해진 것으로 못 박았고 그 문서는 `<!-- spec-review: escalated -->`로 닫혀 있는데, 정작 가리키는 쪽은 한 곳도 안 고쳐졌다. `scripts/test_docs_drift.sh:333-348`의 절 참조 검사는 「」로 감싼 참조만 보는데 이 아홉 자리는 모두 평문이고, 검사 대상 파일도 넷으로 한정돼 domain-docs·nested-orchestration·self-audit.js는 아예 훑지 않는다.

**처방** — 이미 정해진 대로 가리키는 쪽 아홉 자리를 정본의 실제 절 이름으로 바꾸고 "'문서 작성' 행" 같은 행 지시를 그 절의 어느 문장을 뜻하는지로 다시 쓴다. 되풀이를 막으려면 절 참조 검사를 「」 없는 '…절'·'…표' 형태까지 잡도록 넓히고 대상 파일을 살아 있는 문서 전부로 넓힌다.

**반박 1** — 아홉 인용이 모두 그 줄 번호에 그대로 실재하고 정본 대조도 재현됐다 — agent-principles.md에 '검증 레이어'는 0회, 표 줄도 0이며 실제 절 제목은 '## 검증 — LLM 단독 출력을 그대로 마치지 않는다'로 산문과 불릿뿐이라 '문서 작성' 행이 존재할 수 없다. spec:62의 결정과 escalated 마커, test_docs_drift.sh:333-348이 「」만 보고 파일 넷만 훑는다는 점도 확인했고, 반증 후보였던 test_scaffold.sh:236은 표를 요구하지 않아 반박이 되지 않는다. 다만 DESIGN-NOTES.md:287은 절 참조가 아닌 일반 개념 언급이고 domain-llm-runtime/SKILL.md:9이 누락돼 '문서 다섯'은 실제로 여섯이나, 결함 자체는 그대로 성립한다.

**반박 2** — 정본에는 「검증 레이어」라는 절도 표도 없는데(제목 여섯 개 확인, 표 행 0), 살아 있는 문서 여덟 자리가 그 이름과 '문서 작성' 행을 가리키며, 특히 .claude/workflows/self-audit.js:84는 실행되는 프롬프트로 존재하지 않는 절 셋을 리뷰어에게 지정한다. 스펙 2026-08-30-audit-unification-design.md:62가 '가리키는 쪽을 고친다'를 이미 정해진 것으로 못 박고 escalated로 닫혔는데 한 곳도 안 고쳐졌으므로 정당한 설계 선택이 아니라 미집행 결정이고, test_docs_drift.sh:333-348의 절 참조 검사는 「」 형태와 파일 넷만 보아 구조적으로 못 잡는다. 다만 DESIGN-NOTES:287은 일반 개념어라 아홉이 아니라 여덟이고 '소유권 선언 무효'는 과장이다.

### 18. DESIGN-NOTES의 저장소 구성 트리가 존재하지 않는 스킬 `skills/migrate-solved-log/SKILL.md`를 실재하는 것처럼 적는다.

**자리** — `docs/DESIGN-NOTES.md:17`

**걸린 원칙** — MEASURE-FIRST · SSOT · FAIL-LOUD

**근거** — docs/DESIGN-NOTES.md:17 — "├── skills/migrate-solved-log/SKILL.md   # 색인 줄을 지시사항으로 다시 쓰는 방법" / `ls skills/` 실행 결과에 `migrate-solved-log`가 없다(`ls: cannot access 'skills/migrate-solved-log': No such file or directory`). 실제 목록은 domain-docs·domain-llm-runtime·domain-plugin·domain-spec-review·meta-aggregate·nested-orchestration·project-doc-audit·reviewer-* 여섯·writing-korean이다.

**결과** — 이 트리는 "어느 파일이 무슨 일을 하는지 훑을 때 쓴다"고 스스로 선언한 개발자용 지도인데, 그 지도에 없는 길이 하나 그려져 있다. 오답노트 색인을 옮기는 방법을 찾는 사람은 이 줄을 보고 그 스킬을 열려다 실패하고, 더 나쁘게는 "색인 줄을 지시사항으로 다시 쓰는" 절차가 아직 살아 있다고 오해해 이미 없앤 기능을 전제로 작업한다. 나머지 항목까지 믿을 수 없게 되는 것이 더 큰 손해다.

**상세** — 오답노트(solved log) 기능은 걷어냈고 그 흔적은 `scripts/_scaffold_common.sh:14`의 `SCAFFOLD_STALE`에 정리 대상으로 남아 있다. 코드는 이미 그 기능을 과거로 처리했는데 개발자용 지도만 삭제 전 상태로 얼어붙었다. 트리 아래의 "위 트리는 주요 파일만 적은 부분 목록이다"라는 면책은 빠진 것을 변명할 뿐 없는 것을 적어 둔 것은 변명하지 못한다. `test_docs_drift.sh:44-52`는 `skills/reviewer-*` 한 줄만 디렉터리에서 도출해 검사하므로 나머지 줄은 손유지로 남았고 실제로 그 부분이 먼저 낡았다.

**처방** — 그 줄을 지우고, 이미 있는 렌즈 도출 검사를 넓혀 트리에 적힌 모든 `skills/...` 경로가 실재하는지 재는 단언을 더한다.

**반박 1** — docs/DESIGN-NOTES.md:17에 인용된 `skills/migrate-solved-log/SKILL.md` 줄이 그대로 있고 그 디렉터리는 실재하지 않으며(커밋 795357c에서 삭제됨), test_docs_drift.sh는 reviewer-*와 domain-* 글롭 줄만 디렉터리에서 도출해 검사하므로 이 줄은 손유지로 남아 낡았다. 42행의 "부분 목록" 면책은 누락만 변명할 뿐 없는 항목의 열거는 덮지 못한다.

**반박 2** — 사실이 실측으로 확인된다 — `ls skills/`에는 domain-* 넷·meta-aggregate·nested-orchestration·project-doc-audit·reviewer-* 여섯·writing-korean 열넷만 있고 `migrate-solved-log`는 없는데 `docs/DESIGN-NOTES.md:17`은 그 경로를 실재하는 것처럼 적고, 오답노트 잔재는 `scripts/_scaffold_common.sh:14`의 `SCAFFOLD_STALE`에 정리 대상으로 남아 코드가 이미 그 기능을 과거로 처리했음을 뒷받침한다. 면책 문구("주요 파일만 적은 부분 목록")는 빠뜨림만 덮고 없는 것을 적어 둔 것은 덮지 못하며, 같은 문서 :283이 "무엇이 있는지는 그 디렉터리가 정본"이라고 스스로 선언해 트리의 열거가 손유지 캐시임을 드러내므로 SSOT·MEASURE-FIRST 위반이 맞고, `scripts/test_docs_drift.sh`가 `skills/reviewer-*` 한 줄만 디렉터리에서 도출하는 탓에 드리프트가 검사를 그대로 통과한 것도 확인된다(FAIL-LOUD). 제안한 수정은 그 줄을 지우고 같은 파일의 도출 검사를 "트리에 적힌 `skills/...` 경로가 실재하는가" 한 방향 단언으로 넓히는 것이라 면책 문구와 충돌하지 않고 범위도 과하지 않다. 다만 이 지적은 `docs/superpowers/reviews/2026-08-30-project-doc-audit-3-check.md:75`에 이미 기록된 것이 미반영 상태로 남은 것이므로, 새 발견이 아니라 미처분 발견으로 다루는 편이 정확하다.

### 19. 서브에이전트 도달 실측 표의 열 구조가 깨져 각 행의 넷째·다섯째 값이 무엇을 뜻하는지 알 수 없다.

**자리** — `docs/DESIGN-NOTES.md:50-63, docs/DESIGN-NOTES.md:69-71`

**걸린 원칙** — EXPLICIT · SSOT · MEASURE-FIRST · FAIL-LOUD

**근거** — docs/DESIGN-NOTES.md:50 — "표의 다섯 열은 다음을 뜻한다." 뒤에 뜻풀이는 셋뿐이다(정본·자동 메모리 목차·프로젝트 `CLAUDE.md`). 표 머리는 "| 에이전트 종류 | 정본 | 자동 메모리 목차 | 프로젝트 `CLAUDE.md` |"로 넷이고 구분 행은 "|---|---|---|---|---|---|"로 여섯이며, 본문 행은 "| `general-purpose` | 실린다 | 실린다 | 실린다 | 실린다 | 실린다 |"로 여섯이다. docs/DESIGN-NOTES.md:69 — "표의 스무 칸은 전부 자기보고이고".

**결과** — 마크다운은 머리 행의 칸 수만큼만 렌더하므로 각 행의 다섯째·여섯째 값 여덟 칸이 화면에서 통째로 사라지고, 그 소실이 오류로 뜨지 않아 아무도 눈치채지 못한다. README가 두 자리(README.md:9, README.md:87)에서 "어느 종류에 실리는지는 DESIGN-NOTES의 실측 표가 정본이라 여기 옮겨 적지 않는다"고 이 표로 독자를 보내므로, 정본으로 지목된 표가 자기 열 이름을 잃은 상태다. 리뷰어를 띄울 때 정본 경로를 프롬프트에 넣을지가 이 표에 달려 있는데 그 근거의 절반이 읽히지 않는다.

**상세** — 머리 행은 넷, 구분 행은 여섯, 본문 행은 여섯 칸이고 산문은 "다섯 열"과 "스무 칸"이라 네 층이 모두 다른 개수를 말한다. 열 둘이 머리와 뜻풀이에서만 지워지고 나머지에는 남아, 지우다 만 흔적이 그대로 굳었다. 실측 결과를 담은 표가 자기 열 이름을 잃은 것은 측정을 안 한 것과 실무적으로 같다 — 값은 있는데 무엇의 값인지 없기 때문이다. `test_docs_drift.sh`는 이 표의 형태를 재지 않는다.

**처방** — 살아 있는 열이 무엇인지 먼저 정하고 머리 행·구분 행·본문 행의 칸 수를 그 값으로 맞춘 뒤, 산문의 '다섯 열'과 '스무 칸' 같은 손으로 적은 수를 빼고 열 이름으로 부른다(NAME-ITEMS). 표의 머리 칸 수와 구분선 칸 수와 본문의 개수 서술이 일치하는지 재는 검사를 test_docs_drift.sh에 붙인다.

**반박 1** — 인용이 파일에 그대로 존재한다 — DESIGN-NOTES.md:50의 "다섯 열" 뒤 뜻풀이는 셋이고, 머리 행은 4칸, 구분 행과 본문 행은 6칸이며, 69행은 "스무 칸"이라 네 층의 개수가 모두 어긋난다. README.md:9·33·87과 skills/domain-docs/SKILL.md:179가 이 표를 정본으로 지목하는 것도 확인했고, test_docs_drift.sh에는 표의 칸 수를 재는 단언이 없다. 렌더링 기술만 부정확하다(머리와 구분 행의 칸 수가 다르면 GFM은 표로 인식하지 않아 문단으로 떨어지므로, 발견이 말한 여덟 칸 소실보다 더 나쁘다) — 발견을 반박하지 못한다.

**반박 2** — 원문을 직접 세어 머리 행 4칸·구분 행 6칸·본문 행 6칸·산문 '다섯 열'과 '스무 칸'이 모두 어긋남을 확인했고, GFM은 머리와 구분 행 칸 수가 다르면 표로 인식조차 하지 않아 블록 전체가 조용히 무너진다(FAIL-LOUD). README.md:9와 87이 이 표를 유일 정본으로 지목하므로(SSOT) 열 이름 소실은 값만 남기고 무엇의 값인지를 지우는 EXPLICIT 위반이며, 정당한 설계 선택이나 예외 조항으로 볼 근거를 찾지 못했다.

### 20. 자기감사 워크플로가 검토 대상을 손으로 박아 두어 없는 파일과 없앤 기능과 정본에 없는 절 이름을 렌즈에 넘긴다.

**자리** — `.claude/workflows/self-audit.js:74, :80, :82, :84, :90, :94`

**걸린 원칙** — MEASURE-FIRST · SSOT · EXPLICIT · FAIL-LOUD · 실패 모드

**근거** — .claude/workflows/self-audit.js:80 — "검토 대상: README.md, CLAUDE.md, agent-principles.md, domains-index.md, commands/*.md" / :82 — "검토 대상: agent-principles.md, domains-index.md, README.md, CLAUDE.md, skills/*/SKILL.md 상호간" / :84 — "검토 대상: 절차 네 절(검증 레이어, 설계 입력, 오답노트, 문서·상태 위생)과 hooks/·scripts/·skills/ 설계 전체" / :90 — "차원: PROSE-FORM 자기준수 — agent-principles.md, ..., README.md, domains-index.md" / :74 — "solved_problems.md에 직접 쓰지 마라" / :94 — "solved_problems는 append-only 예외이고" / 대조: `scripts/_scaffold_common.sh:14`가 `domains-index.md`와 `solved_problems.md`를 `SCAFFOLD_STALE`로 분류하고 레포에도 없으며, 정본의 실제 절 제목은 "## 검증 — LLM 단독 출력을 그대로 마치지 않는다"·"## 미해결의 처분"·"## 병렬 오케스트레이션"·"## 문서와 상태의 위생"이다.

**결과** — 렌즈들이 각자 없는 파일과 없는 절을 찾다가 못 찾고, 그 사실을 실패로 올릴 자리가 없어 나머지만 보고 돌아온다. 워크플로는 렌즈가 응답만 하면 정상으로 계산하므로(`deadLenses`는 응답 없음만 잡는다) 감사 범위가 조용히 좁아진 것이 어디에도 안 뜬다. 특히 적대적 렌즈는 조준점 넷 가운데 셋이 존재하지 않는 이름이라 남은 "hooks/·scripts/·skills/ 설계 전체"라는 넓은 지시만으로 돌게 되어 회차마다 범위가 달라지고, 정본 절차 자체의 결함은 아무도 안 보는 채로 끝난다. 큰 변경 뒤 회귀를 잡으라고 만든 장치가 자기 범위 지정부터 낡았으니 초록 결과가 무결의 증거가 되지 못한다.

**상세** — 이 워크플로는 감사 대상 목록과 절 이름을 프롬프트에 손으로 열거하는 구조라, 레포에서 파일이 사라지고 정본의 절 구성이 바뀌어도 목록은 따라오지 않는다. 없앤 오답노트를 전제하는 지시가 :74와 :94에 둘 더 있다는 점이 이 낡음이 오타가 아니라 기능 제거 때 실행체를 함께 갱신하지 않은 결과임을 보여준다. 같은 레포의 `skills/project-doc-audit/SKILL.md:40`이 "목록은 손으로 적지 말고 파일에서 도출한다"고 규정하는데 이 실행체가 그 규정을 정면으로 어겼고, 이 감사가 낡았다는 사실을 감사 자신은 자기 프롬프트를 검토 대상에 넣지 않아 구조상 알아낼 수 없다.

**처방** — 검토 대상을 파일에서 도출하게 바꾸고(살아 있는 .md에서 대상 아님 경로를 뺀 집합), 절 이름 열거도 "정본 `agent-principles.md`의 절차 절 전부"로 도출하게 한다. 최소한 `domains-index.md`·`solved_problems`·옛 절 이름 셋은 지금 걷어내고, 프롬프트가 가리키는 이름이 실재하는지 재는 단언을 `scripts/test_docs_drift.sh`에 더한다.

**반박 1** — 인용한 여섯 줄이 .claude/workflows/self-audit.js에 그대로 존재하고, domains-index.md와 solved_problems는 레포 루트에 없으며 scripts/_scaffold_common.sh:14가 둘을 SCAFFOLD_STALE(없앤 옛 파일)로 분류한다. agent-principles.md에는 '설계 입력'·'오답노트' 절이 없고, 워크플로에는 대상 실재를 재는 장치가 없으며 deadLenses는 무응답만 잡는다. '넷 중 셋이 없다'(실제로는 둘)와 rewrite-map 아래 폐기 기록 파일의 존재는 사소한 과장일 뿐 핵심 주장을 흔들지 않는다.

**반박 2** — 인용한 다섯 줄이 파일에 그대로 있고, domains-index.md는 루트에 없으며(795357c에서 삭제) solved_problems.md는 레포 어디에도 없고 _scaffold_common.sh:14가 둘을 SCAFFOLD_STALE로 지우고 있어, 자기감사 워크플로가 죽은 이름으로 렌즈를 조준하는 것이 실측으로 확인된다. 같은 레포의 project-doc-audit/SKILL.md:40이 "목록은 손으로 적지 말고 파일에서 도출한다"고 규정하므로 예외 조항이나 정당한 설계 선택으로 볼 여지가 없고, :84의 조준점 넷 가운데 둘이 없는 절 이름이라 정본의 병렬 오케스트레이션과 미해결의 처분 절이 감사 범위 밖에 남는 실질 손해가 있다(다만 "넷 가운데 셋"은 과장이며 실제로는 둘이다).

### 21. DESIGN-NOTES가 없어진 오답노트 로그의 append-only 성질과 domain-docs에 존재하지 않는 절을 소유자로 가리킨다.

**자리** — `docs/DESIGN-NOTES.md:110-114`

**걸린 원칙** — SSOT · MEASURE-FIRST · FAIL-LOUD · EXPLICIT

**근거** — docs/DESIGN-NOTES.md:112-114 — "그 판단은 여기서 정하지 않고 정본이 정본이다(`domain-docs`가 그 머리말을 갈아끼우는 방법을 소유한다) — 그 로그의 본문 파일은 append-only이고 원문을 보존하므로, 승격은 원칙 쪽에 재기술해 올리는 것이지 로그에서 지우는 것이 아니다." / 대조: `grep -c "머리말" skills/domain-docs/SKILL.md` → 0. 그 로그 파일들은 `scripts/_scaffold_common.sh:14`의 `SCAFFOLD_STALE`에 들어가 매 세션 치워지는 구 관리파일이다.

**결과** — 교훈을 원칙으로 승격하는 절차를 확인하려는 개발자는 여기서 `domain-docs`로 보내지는데 그 문서에는 머리말을 갈아끼우는 방법이 한 글자도 없어, 처음부터 끝까지 읽고도 빈손으로 돌아온다. 포인터가 끊긴 것을 못 알아채면 이미 없는 로그에 항목을 쌓는 것을 전제로 승격 규율을 설계하게 된다. 지시가 가리키는 소유자가 비어 있다는 것은 어떤 검사도 안 보므로 이 끊김은 계속 남는다.

**상세** — 오답노트 기능을 걷어낼 때 코드 쪽(`SCAFFOLD_STALE` 등록)은 정리했으나 개발자용 근거 문서에 그 기능을 전제한 문장이 남았고, 그 규칙을 소유하던 스킬이 사라지면서 소유자만 `domain-docs`로 바뀐 채 남았다. 이 문장은 두 겹으로 낡았다 — 사라진 로그의 성질(append-only, 원문 보존)을 현재 시제로 단정하고, 소유자로 지목한 문서에는 그 내용이 없다. 소유자 포인터가 실재하는지 재는 가드는 `test_docs_drift.sh:222`의 「소유자 절이 있다」 하나뿐이고 그것은 다른 한 절만 문다.

**처방** — 소유자를 잃은 그 괄호와 append-only 로그 서술을 지우고 "여러 레포에 걸치는 교훈만 정본으로 재기술해 올린다"까지만 남긴다. 문서가 `스킬이름`과 함께 "소유한다"를 적을 때 그 스킬 파일에 해당 절 제목이 실재하는지 재는 검사를 test_docs_drift.sh에 일반화해 붙인다.

**반박 1** — 인용 문장이 docs/DESIGN-NOTES.md:112-114에 축어 그대로 있고, skills/domain-docs/SKILL.md에는 "머리말"이 0회이며 절 제목 어디에도 그 방법이 없어 소유자 포인터가 실제로 끊겼다. 오답노트 로그는 scripts/_scaffold_common.sh:14의 SCAFFOLD_STALE에 등록된 폐기 파일이고 스킬·정본·README 어디에도 남아 있지 않아 append-only 서술도 낡았다. 다만 "소유자를 재는 가드가 222줄 하나뿐"은 과장이다(155줄에 같은 종류가 하나 더 있다) — 그 곁가지는 결론을 바꾸지 않는다.

**반박 2** — domain-docs/SKILL.md에 '머리말'·'승격'·'재기술'이 0건이고 「여기가 소유자」 절 셋 어디에도 그 방법이 없어 소유자 포인터가 끊겼으며, 가리키는 오답노트 로그 자체가 SCAFFOLD_STALE에 등록돼 제거된 기능인데도 DESIGN-NOTES:110-114는 append-only 성질을 현재 시제로 단정한다(git ff410e2에서 앞부분만 고쳐지며 선행사가 사라진 것을 확인). 같은 파일이 걷어낸 기능은 「안 넣기로 한 것」에 명시하는 관례를 지키므로 예외로 볼 여지도 없다.

### 22. 관리 디렉터리 위생 검사가 디렉터리 형태로 남은 옛 오답노트를 치우지 못해 매 세션 지울 수 없는 경고를 낸다.

**자리** — `scripts/_scaffold_common.sh:14, scripts/_scaffold_common.sh:31-32, scripts/_scaffold_common.sh:51-53`

**걸린 원칙** — IDEMPOTENT · FAIL-LOUD · 실패 모드

**근거** — scripts/_scaffold_common.sh:14 — "SCAFFOLD_STALE=\"coding-principles.md issue-mode ultracode-review advisors-index.md unsolved_problems.md solved_problems.md solved_problems domains-index.md\"" / :31-32 — "for f in $SCAFFOLD_STALE; do / [ -f \"$kdir/$f\" ] || continue" / :51-53 — "if [ -d \"$f\" ]; then / echo \"[disciplined-coder] note: 비관리 디렉터리 '$b' 잔존(자동삭제 안 함, 확인 요)\" >&2 / continue"

**결과** — 쪼갠 오답노트를 쓰던 PC에는 `~/.claude/disciplined-coder/solved_problems/`가 디렉터리로 남는다. 치우기 반복문은 `[ -f ]`로 정규 파일만 보므로 이 디렉터리를 건너뛰고, 화이트리스트 반복문은 디렉터리라서 지우지 않고 경고만 낸다. 그래서 사용자는 세션을 열 때마다 "비관리 디렉터리 'solved_problems' 잔존(확인 요)"를 보는데 스캐폴드는 그것을 영원히 해소하지 못하고 안내문도 손으로 지우라고 말해 주지 않는다. 매 세션 뜨면서 아무 조치로도 사라지지 않는 경고는 곧 무시되고, 그 무시가 같은 통로로 나오는 정본 복사 실패·홈 드리프트 경고까지 함께 덮는다.

**상세** — `SCAFFOLD_STALE`에 확장자 없는 `solved_problems`를 넣은 것은 디렉터리 형태의 잔재를 겨냥한 것으로 읽히는데, 정작 치우는 코드는 정규 파일만 다루므로 그 항목은 아무 일도 하지 않는다. 목록에는 의도가 적혀 있고 코드는 그 의도를 실행하지 못하는 상태이며, 두 갈래가 갈라진 것을 어떤 검사도 잡지 않는다. 파일 쪽 경로가 백업으로 옮기고 못 옮기면 알리는 규율을 갖춘 것과 대비하면 디렉터리 쪽만 처분이 통째로 비어 있다.

**처방** — `SCAFFOLD_STALE`의 처분을 디렉터리에도 적용하거나(백업으로 옮기고 못 옮기면 알리는 같은 규율), 실행되지 않는 `solved_problems` 항목을 목록에서 빼고 경고 문안에 사용자가 직접 지우면 된다는 조치를 적어 경고가 해소 가능해지게 한다.

**반박 1** — 인용한 세 곳(:14, :31-32, :51-53)이 파일에 그대로 있고, 임시 디렉터리에 solved_problems 폴더를 두고 scaffold_hygiene 을 두 번 돌리자 같은 경고가 두 번 나오고 폴더는 그대로 남아 재현됐다. 795357c 가 solved_problems.md 와 함께 확장자 없는 solved_problems 를 STALE 에 넣었고 fa13543 이 그 폴더를 실제로 만들던 판본이라 의도와 코드가 갈린 것도 확인됐으며, test_docs_drift.sh 의 STALE_NAMES 도 이 항목으로는 아무 문서도 못 잡아 반증이 되지 못한다.

**반박 2** — 재현으로 확인했다 — SCAFFOLD_STALE의 `solved_problems` 항목은 처분 반복문이 `[ -f ]`로 막혀 어느 소비자에서도 발동하지 않고, 디렉터리가 남은 홈에서는 해소 불가능한 note가 매 세션 반복된다. 커밋 795357c가 그 이름을 WHITELIST에서 STALE로 옮긴 기록이 있어 "치우려는 의도"는 추론이 아니라 문서화된 사실이고, test_docs_drift의 STALE_NAMES 쪽에서도 그 이름과 겹치는 설계 문서가 없어 이중 목적 방어가 성립하지 않는다. 다만 인용한 IDEMPOTENT는 오적용이며(두 번 돌려도 상태와 출력이 같다) 실측한 PC에는 그 디렉터리가 이미 없어 피해는 잠재 상태다 — 결함은 실재하되 심각도는 낮고, 같은 함수의 파일 분기가 이미 가진 백업 이동 규율을 네 줄로 붙이면 해소된다.

### 23. 검사 스크립트 둘에 픽스처를 세우고 스캐폴드를 돌린 뒤 아무것도 단언하지 않는 블록이 남아 있고, 그 기능이 쓰던 공용 함수도 부르는 곳 없이 남아 있다.

**자리** — `scripts/test_scaffold.sh:586-587, scripts/test_scaffold.sh:653-664, scripts/test_scaffold.sh:674-682, scripts/test_codex_scaffold.sh:133-141, scripts/test_codex_scaffold.sh:148-152, scripts/_scaffold_common.sh:16-22, scripts/_scaffold_common.sh:78`

**걸린 원칙** — TDD · FAIL-LOUD · SURGICAL

**근거** — BEFORE14="$(cksum < "$LOG14")" / OUTR14="$(run "$HR14" "$PR14")"   # 이 뒤로 BEFORE14·OUTR14를 읽는 줄이 없다
(같은 파일 682행) OUTP1="$(run "$HP1" "$PP1")"
(test_codex_scaffold.sh 139-141행) BEFORE_C="$(cksum < "$OLDC")" / OUTC1="$(run "$HC1")" / BKC="$(find ... || true)"
(test_scaffold.sh 586-587행) NUDGE='형식 규칙 서술이 현행과 다르다' / LOGTITLE='해결된 문제 로그 (solved_problems)' — 둘 다 쓰이지 않는다
(_scaffold_common.sh:78) scaffold_names_only_in_first() — 레포 전체에서 정의 한 줄 말고 부르는 곳이 없다

**결과** — 이 블록들은 값과 시간을 쓰면서 아무 회귀도 못 잡는데, 머리말 주석은 '사유를 가려 알린다'·'색인 줄 수와 본문 파일 수를 맞댄다' 같은 계약이 검사되고 있다고 읽힌다. 그래서 뒤에 오는 사람은 그 계약이 지켜지는지 이 스위트가 본다고 믿지만, 실제로는 스캐폴드가 그 자리에서 무엇을 하든 초록이다. 이 레포가 계약으로 삼은 FAIL=0이 무엇을 보증하는지가 그만큼 줄어든다.

**상세** — test_scaffold.sh의 HR14 블록(656-664행)과 pairing 블록(675-682행), test_codex_scaffold.sh의 solved-rules 블록(133-141행)과 산문 로그 블록(148-152행)이 모두 mktemp로 홈을 만들고 픽스처를 쓰고 run을 부른 뒤 check를 한 번도 부르지 않으며, BEFORE14·OUTR14·OUTP1·BEFORE_C·OUTC1·BKC·BEFORE_C3·OUTC3은 정의만 되고 어디서도 읽히지 않는다. 최근 커밋이 붙인 `scripts/test_assertions.sh`는 `echo "[`로 시작하는 머리말 단위로만 세므로 `# ---` 구획 주석으로 시작하는 이 블록들은 앞 블록의 check 개수에 묻혀 빠져나간다. `_scaffold_common.sh:16-22`의 "쪼개진 로그의 형식 규칙 블록" 주석도 설명할 상수가 사라져 아무것도 서술하지 않고, `scaffold_count_matches`는 test_scaffold.sh:670-672만 부르므로 검사가 제품 경로가 안 쓰는 함수를 지키고 있다.

**처방** — 세 자리의 픽스처와 죽은 변수·함수·주석을 걷어내거나 죽은 코드로 표시하고, 남길 것이 있으면 실제 단언을 붙인다. test_assertions.sh의 블록 인식을 `echo "[`뿐 아니라 `# ---` 구획 주석까지로 넓히고 쓰이지 않는 변수 할당도 잡게 한다.

**반박 1** — 인용된 줄 번호와 문자열이 모두 파일에 그대로 있고, 네 블록(test_scaffold.sh 656-664·675-682, test_codex_scaffold.sh 133-141·148-152)이 픽스처와 run만 두고 check를 한 번도 부르지 않으며 BEFORE14·OUTR14·OUTP1·BEFORE_C·OUTC1·BKC·BEFORE_C3·OUTC3·NUDGE·LOGTITLE은 정의 한 곳 말고 읽는 곳이 없다. scaffold_names_only_in_first는 레포 전체에서 정의만 있고 호출이 없으며 _scaffold_common.sh:16-22 주석이 서술하는 SCAFFOLD_SOLVED_RULES* 상수는 그 파일에 없다. test_assertions.sh:21-25가 echo "[ 머리말로만 블록을 가르는 것도 확인했고 실행하면 PASS=5 FAIL=0으로 초록이라 이 블록들이 실제로 빠져나간다.

**반박 2** — grep 전수 확인 결과 BEFORE14·OUTR14·OUTP1·BEFORE_C·OUTC1·BKC·BEFORE_C3·OUTC3·NUDGE·LOGTITLE은 할당만 되고 읽히지 않으며, scaffold_names_only_in_first는 정의 말고 호출자가 없고, test_assertions.sh를 실제로 돌리면 PASS=5 FAIL=0이라 이 블록들이 메타 검사를 빠져나가는 것이 실행으로 확인된다. set -e 덕에 run이 죽지 않는다는 암묵 스모크 단언은 남지만, 주석이 선언한 '사유를 가려 알린다'·'색인과 본문을 맞댄다' 계약은 아무것도 재지 않으므로 TDD의 실행 증거 요구와 FAIL-LOUD의 드리프트 금지에 실제로 걸린다.

### 24. solved-rules 블록에 하나 남은 단언은 어떤 코드에도 없는 문자열을 찾으므로 무엇을 고쳐도 참이다.

**자리** — `scripts/test_codex_scaffold.sh:145`

**걸린 원칙** — TDD

**근거** — NUDGE_C='형식 규칙 서술이 현행과 다르다'
...
check "codex fresh: 신호 없음"            "! printf '%s' \"\$OUTC2\" | grep -qF '$NUDGE_C'"

**결과** — '형식 규칙 서술이 현행과 다르다'는 레포 전체에서 test_codex_scaffold.sh:132와 test_scaffold.sh:586에만 있고 어떤 스크립트도 그 문자열을 낼 수 없다. 그러니 이 단언은 codex-scaffold.sh가 무엇을 출력하든 통과한다. 초록 화면에 '신호 없음'이라는 이름이 남아 검증된 계약처럼 세어지지만, 재는 대상이 코드에 없어 0건인 회차와 검사를 안 돌린 회차가 구별되지 않는다.

**상세** — test_assertions.sh 머리말이 스스로 '항진 단언은 못 잡는다 — 그것은 사람이 본다'고 적어 둔 바로 그 물건이다. test_codex_scaffold.sh:165의 격리 단언(`! ... grep -qF -- '$HERE/docs/solved_problems.md'`)도 같은 부류다 — 지금 codex-scaffold.sh는 solved_problems를 SCAFFOLD_STALE에서 지우는 것 말고는 건드리지 않으므로 그 경로가 출력에 나올 길이 없다.

**처방** — 없어진 기능을 재는 단언은 상수와 함께 걷어낸다. 남길 것이 있으면 재려는 문자열을 정본 스크립트에서 도출해 넣고, 그 도출이 빈 값이면 붉어지게 만든다(test_docs_drift.sh가 HOME_CANDS에 쓰는 방식).

**반박 1** — 인용한 두 줄(test_codex_scaffold.sh:132,145)이 파일에 그대로 있고, git grep 결과 해당 문자열은 검사 두 곳과 계획 문서에만 있어 어떤 프로덕션 스크립트도 낼 수 없으므로 그 부정 단언은 항진이다. codex-scaffold.sh 전문(78줄)에 solved_problems·CLAUDE_PROJECT_DIR 참조가 아예 없어 격리 단언도 같은 부류임이 확인된다. 격리 단언 줄번호가 165가 아니라 161인 것과 계획 문서 히트 누락은 사소한 어긋남이라 발견의 실재를 뒤집지 않는다.

**반박 2** — '형식 규칙 서술이 현행과 다르다'는 레포 전체에서 검사 파일 둘과 계획 문서에만 있고 codex-scaffold.sh·scaffold.sh·_scaffold_common.sh 어디에도 없으며, codex-scaffold.sh의 stdout은 SCAFFOLD_FILES 본문뿐이라 그 문자열도 '$HERE/docs/solved_problems.md' 경로도 나올 길이 없다 — 따라서 :145와 :161 두 단언은 무엇을 고쳐도 참인 항진 단언이다. 회귀 가드라는 반박도 성립하지 않는다: 근거로 든 쌍둥이 패리티는 Claude 쪽 단언이 이미 걷혀 사라졌고, test_assertions.sh 머리말이 바로 이 물건을 이름으로 금하고 있으며, 블록 제목('codex twin replaces the header the same way')이 재지 않는 것을 이름으로 내걸고 초록 40에 세어지고 있다.

### 25. 관리블록을 넣기 전에 걷어내기가 성공했는지 보지 않아 사용자의 CLAUDE.md가 통째로 빈 파일이 될 수 있다.

**자리** — `scripts/_managed_block.sh:181`

**걸린 원칙** — FAIL-LOUD

**근거** —   awk -v b="$begin" -v e="$end" -v o="$MANAGED_ORPHAN" -v f="$uc" "$MANAGED_STRIP_AWK" "$uc" > "$tmp"
  awk "$MANAGED_TRIM_AWK" "$tmp" > "$norm" && mv "$norm" "$uc"

**결과** — 걷어내기 awk가 실패하면 $tmp가 빈 채로 남고, 그 빈 파일을 읽은 다음 awk는 성공하므로 mv가 사용자의 ~/.claude/CLAUDE.md를 빈 파일로 갈아치운다. 그 위에 관리블록만 덧붙고 함수는 0(성공)으로 돌아가므로 scaffold.sh는 아무 경고도 내지 않는다. 사용자가 손으로 적어 둔 전역 지침이 사본도 없이 사라지며(inject 경로에는 managed_block_remove와 달리 백업이 없다), 다음 세션에는 원칙 블록만 남은 파일이 정상으로 보인다.

**상세** — 181행의 걷어내기 awk와 182행의 끝 빈 줄 정리 awk가 서로 다른 파일을 읽는데, 대상 파일을 갈아치우는 판단은 둘째 awk의 성공 여부만으로 내린다. 호출자가 둘 다 `managed_block_inject ... || inject_rc=$?` 형태라 함수 안에서는 set -e가 꺼지므로 첫 awk의 실패는 스크립트를 멈추지도 않는다. 실제로 첫 awk만 실패하게 만들어 재현했다 — 'user line'과 기존 관리블록이 들어 있던 파일이 실행 뒤에 BEGIN/BODY/END 세 줄만 남았고 함수의 리턴값은 0이었다.

**처방** — 첫 awk의 종료코드를 받아 실패면 mv와 append를 모두 건너뛰고 사유를 stderr로 알린 뒤 1로 돌아간다. mv의 실패도 같이 본다 — mv가 실패하면 옛 블록이 남은 파일에 새 블록이 덧붙어 관리블록이 둘이 된다.

**반박 1** — 인용한 두 줄이 scripts/_managed_block.sh:181-182에 그대로 있고, 첫 awk의 종료코드를 보지 않은 채 둘째 awk의 성공만으로 mv를 실행하는 구조가 맞다. 두 호출자 모두 `|| inject_rc=$?`로 감싸 set -e가 꺼지는 것을 확인했고, awk 셰임으로 첫 awk만 실패시켜 재현하니 사용자 줄이 사라진 파일에 관리블록만 남고 함수는 0을 돌려주었으며 inject 경로에는 백업도 관련 테스트도 없다.

**반박 2** — 첫 awk만 실패하는 껍데기로 재현했더니 사용자 원문 줄이 사라진 채 함수가 0으로 돌아왔고 경고도 없었다 — FAIL-LOUD의 '삼키지 않는다'에 정면으로 걸린다. 같은 파일의 managed_block_remove가 사본 실패를 리턴 2로 갈라 내고 182행이 둘째 awk의 종료코드는 &&로 검사하므로 의도된 비대칭이 아니라 누락이며, 대상이 git 밖의 ~/.claude/CLAUDE.md인데 inject 경로에는 사본이 없어 되돌릴 수도 없다.

### 26. 리뷰어 렌즈 여섯 가운데 다섯의 레퍼런스 프롬프트가 명사 조각이나 조사로 끝나 말끝을 흐린다.

**자리** — `skills/reviewer-consistency/SKILL.md:36-37`

**걸린 원칙** — PROSE-FORM — "'미배선'·'확정?'처럼 명사 조각이나 말끝 흐림으로 끝내지 않는다"

**근거** — - system: "너는 정합성·커버리지 검수자다. … 스코프 문제를 찾아라. 고치지 말고 지적만. 한 번만 도니 …"
- user: "[원문]\n{document}\n\n[관련 배경]\n{background}\n\n위 체크리스트로 이슈를 아래 JSON 스키마로."

**결과** — PROSE-FORM을 판정해야 할 렌즈들이 자기 지시문에서 그 조항을 어기고 있으므로, 이 프롬프트를 그대로 쓰라고 지시받은 리뷰어(project-doc-audit/SKILL.md:95)가 말끝 흐림을 정상 문체로 학습한 채 판정한다. 그리고 "지적만."과 "지적만 하라."가 갈려 있어 어느 쪽이 계약인지 정할 수 없고, 계약 테스트는 evidence와 consequence의 뜻풀이만 대조하므로 이 어긋남을 잡지 못한다.

**상세** — reviewer-consistency의 system 프롬프트는 "고치지 말고 지적만."으로 끊기는데 reviewer-grounding/SKILL.md:27은 같은 자리를 "고치지 말고 지적만 하라."로 적어, 같은 문장이 렌즈마다 다르게 끝난다. reviewer-grounding도 같은 줄에서 "출처에 없으면 '근거 없음'으로 표시."라고 명사형으로 끊는다. user 프롬프트는 네 렌즈(consistency:37, adversarial:47, prior-art:79, fit:33)가 "…아래 JSON 스키마로."라는 조사 종결이고 grounding:28만 명사형 종결이며 readability:201도 같은 형태를 되풀이한다. 이 문장들은 서브에이전트에 그대로 실려 나가는 한국어 지시문이다.

**처방** — 다섯 렌즈의 프롬프트 끝을 서술어로 맞춘다 — "고치지 말고 지적만 하라", "출처에 없으면 '근거 없음'으로 표시하라", "위 체크리스트로 찾은 이슈를 아래 JSON 스키마로 출력하라"처럼 한 형태로 통일한다.

**반박 1** — 인용 문자열이 모두 지정된 줄에 그대로 있고(consistency:36-37, grounding:27-28, adversarial:47, prior-art:79, fit:33, readability:201, writing-korean:81, project-doc-audit:95), "지적만."과 "지적만 하라."의 갈림도 실재하며 test_docs_drift.sh는 evidence·consequence 뜻풀이만 대조해 이를 못 잡는다. '언어 중립' 표시는 구현 언어 단서일 뿐 문체 예외가 아니라 반증이 되지 못하고, 유일한 흠은 제목의 '여섯 가운데 다섯'이 실제 여섯 전부를 축소해 센 것이다.

**반박 2** — 인용된 여섯 자리를 파일에서 모두 확인했고(consistency:36-37, grounding:27-28, adversarial:47, prior-art:79, fit:33, readability:201), writing-korean:76-81이 '남에게 남는 산출물'에 PROSE-FORM을 예외 없이 걸며 말끝 흐림과 명사 조각 종결을 명시로 금지하므로 해당하는 예외 조항이 없다. 게다가 project-doc-audit:95가 이 프롬프트를 그대로 쓰라고 정하는데 '지적만.'과 '지적만 하라.'가 갈려 있고 계약 테스트는 evidence·consequence 뜻풀이만 대조하므로 그 어긋남이 기계로 잡히지 않는다.

### 27. nested-orchestration의 괄호 주석 셋이 서술어 없이 명사로 끝나 무엇이 어떻게 되는지를 적지 않는다.

**자리** — `skills/nested-orchestration/SKILL.md:58-59`

**걸린 원칙** — PROSE-FORM — "명사 조각 나열과 … 말끝 흐림과 개조식을 쓰지 않는다"

**근거** — **병합될 브랜치에는 커밋하지 않는다**(고정 경로로 커밋하면 워크스트림끼리 병합 충돌 — 실측). 서브에이전트
`Write`가 `.md`를 훅으로 막을 수 있으니 리포트는 Bash로 스크래치에 기록한다(실측 gotcha).

**결과** — L2를 디스패치하는 세션이 이 괄호를 읽고도 충돌이 리포트를 쓰는 시점에 나는지 L1이 브랜치를 합치는 시점에 나는지 알지 못해, 고정 경로를 그대로 쓰고 통합 단계에 가서야 막힌다. 그리고 '실측'이 무엇을 재서 얻은 값인지 적혀 있지 않아 다음 사람이 그 수치를 근거로 쓰지 못한다(MEASURE-FIRST).

**상세** — "고정 경로로 커밋하면 워크스트림끼리 병합 충돌"은 조건절만 있고 서술어가 없어 명사로 끊긴다. 이어 붙은 "— 실측"과 다음 줄의 "(실측 gotcha)"도 서술어 없는 꼬리표이며, 같은 절의 80행 "실측 참고: 사소한 워크스트림 하나당 약 40k 토큰(L3 포함)."도 명사 종결이다. PLAIN-KO가 요구하는 "결과는 무엇이 어떻게 되는지까지 적는다"에도 함께 걸린다.

**처방** — "리포트를 고정 경로에 커밋하면 워크스트림 브랜치를 합칠 때 같은 파일에서 충돌이 난다. 이 레포에서 실제로 겪었다."처럼 서술어와 관측 시점까지 적고, 토큰 수치도 무엇을 어떻게 세었는지를 함께 적는다.

**반박 1** — 인용 문장 셋(58-59행, 80행)이 skills/nested-orchestration/SKILL.md에 글자 그대로 존재하고, 서술어 없이 명사로 끊긴다는 기술도 정확하다. writing-korean:81의 "명사 조각이나 말끝 흐림으로 끝내지 않는다"와 84행의 개조식 금지 근거(인과 소실)가 이 사례에 걸리며, 76-77행이 정한 적용 범위상 SKILL.md에 괄호 예외는 없다. 다만 detail의 "같은 절의 80행"은 실제로 다른 절(가드레일)이고 consequence의 시점 혼동 주장은 과장이라 부수 서술 둘이 부정확하다.

**반박 2** — writing-korean/SKILL.md:81이 명사 조각 종결을 명문으로 금지하고 87-88행의 면제 목록(제목·소제목·불릿 라벨·표 머리·축·노드)에 본문 괄호 주석은 없으므로 예외에 걸리지 않으며, 76-77행이 배포 산출물에는 예외 없이 적용한다고 못 박는다. 같은 문서가 다른 다섯 곳(:30·:42·:50·:62·:83)에서는 괄호를 완결문으로 쓰고 있어 하우스 컨벤션 방어도 성립하지 않고, 이 레포의 기존 리뷰 기록이 동일한 명사 조각 지적을 이미 확정 발견으로 채택했다. 결과 서술 가운데 '충돌 시점을 알 수 없다'는 부분은 과장이나, :80의 명사 종결과 근거 없는 40k 수치를 포함해 형식 위반 자체는 실재한다.

### 28. domain-llm-runtime의 두 줄이 명사와 명사형으로 끝나 PROSE-FORM이 금지한 말끝 흐림에 걸린다.

**자리** — `skills/domain-llm-runtime/SKILL.md:22-23`

**걸린 원칙** — PROSE-FORM — "'미배선'·'확정?'처럼 명사 조각이나 말끝 흐림으로 끝내지 않는다"

**근거** — - `reviewer-fit`는 다운스트림 계약을 본다. 스키마·형식은 **코드 validator를 먼저** 돌리고 실패 시에만 리뷰 콜(비용 절약).
- `meta-aggregate`는 여기서 **결정론적 파이썬 함수**로 구현한다(LLM 콜 아님).

**결과** — 제품 코드에 검증 레이어를 얹는 세션이 결정론 validator와 LLM 리뷰 콜의 실행 순서를 문장으로 확인하지 못한다. 특히 '실패 시에만'의 주체가 validator인지 1차 LLM 출력인지가 갈려, validator가 통과했는데도 리뷰 콜을 매번 돌리는 구현이 나올 수 있고 그것이 이 절이 아끼려던 비용이다.

**상세** — 앞 줄은 "실패 시에만 리뷰 콜(비용 절약)."로 끝나 서술어가 없고 '(비용 절약)'도 이유인지 결과인지를 조사 없이 붙였다. 뒤 줄의 "(LLM 콜 아님)"은 명사형 종결이다. 두 줄 다 같은 목록의 첫 줄(21행)이 "…여기서 **원래 요청과 제공된 맥락**이다."로 서술어를 갖춘 것과 어긋나, 한 목록 안에서 말끝이 갈린다.

**처방** — "스키마와 형식은 코드 validator로 먼저 검증하고, validator가 실패했을 때만 리뷰 콜을 돌린다 — 그래야 비용이 줄어든다"처럼 서술어를 붙이고, "(LLM 콜 아님)"은 "LLM을 부르지 않는다"로 되돌린다.

**반박 1** — 인용 두 줄이 skills/domain-llm-runtime/SKILL.md:22-23에 그대로 존재하고, 22행의 "실패 시에만 리뷰 콜(비용 절약)."은 서술어가 없는 명사 조각 종결이라 writing-korean/SKILL.md:81의 PROSE-FORM 조항과 90행의 목록 말끝 통일 요구를 동시에 어긴다(불릿 라벨 예외는 완결 문장 불릿인 이 줄에 적용되지 않는다). 다만 23행의 "(LLM 콜 아님)"은 서술어 뒤 괄호주로 domain-docs:50·reviewer-grounding:19에 같은 형태가 있어 약하고, 제시된 '실패 주체 모호' 결과는 과장이나, 22행만으로 발견은 실재한다.

**반박 2** — 22행은 서술어가 아예 없이 "…실패 시에만 리뷰 콜(비용 절약)."로 끝나 writing-korean SSOT 81행의 "명사 조각이나 말끝 흐림으로 끝내지 않는다"에 정면으로 걸리고, 같은 목록 21행이 "…맥락이다."로 서술어를 갖춰 90행의 말끝 일치 조항까지 함께 걸린다. 라벨 예외(87-88행)는 제목·불릿 라벨·표 머리로 닫혀 있어 불릿 본문인 이 자리에 열리지 않고, 레포 전체에서 이 형태가 22·23행뿐이라 관례나 설계 선택으로도 방어되지 않는다. consequence의 혼동 위험 주장만 다소 과장이며(순서는 64행이 다시 말해 준다) 위반 자체는 명백하다.

### 29. domain-docs의 출처 목록이 괄호 안에서 쌍반점으로 명사 조각을 이어 붙여 개조식으로 끝난다.

**자리** — `skills/domain-docs/SKILL.md:59-60`

**걸린 원칙** — PROSE-FORM — "명사 조각 나열과 기호로 문장 대신하기와 말끝 흐림과 개조식을 쓰지 않는다"

**근거** — [글 잘 쓰고 싶은 개발자](https://wikidocs.net/book/20224) (제목·첫 설명은 10초 안에 정체성·대상 독자가 드러나게; 한 문장 한 뜻·결론 먼저·군더더기 삭제),
[좋은 README 작성법 (InfoGrab)](https://insight.infograb.net/blog/2023/08/23/good-readme/) (구성요소 체크리스트: 사용 예시·트러블슈팅·메인테이너·라이선스).

**결과** — 출처에서 무엇을 가져왔는지가 명사만 남아, 이 문서를 읽고 README를 쓰는 세션이 '군더더기 삭제'가 무엇을 지우라는 뜻인지 원문을 다시 열어야 알 수 있다. distill의 목적은 원문을 안 열고도 쓸 수 있게 하는 것이므로 그 목적이 무너지고, SSOT가 요구한 '참조하되 복제하지 않는다'가 '참조도 복제도 아닌 조각'으로 남는다.

**상세** — 앞 괄호는 "…드러나게;"라는 연결어미로 끊고 "군더더기 삭제"라는 명사로 끝난다. 뒤 괄호는 쌍점 뒤에 가운뎃점으로 네 항목을 늘어놓고 서술어 없이 닫는다. 이 절은 "본문을 베끼지 말고 distill한 뒤 출처를 링크한다"(31-32행)는 규칙을 스스로 실행한 자리인데 distill의 결과가 문장이 아니라 명사 조각 묶음이 되었다. 같은 문서 77-78행의 "타입은 세 축으로 갈린다 — ① 휘발성 상태를 담는가 ② 수명 ③ SSOT인가/사본·전령인가"도 한 목록 안에서 말끝이 갈린다.

**처방** — 괄호 안을 문장으로 편다 — "제목과 첫 설명만 읽고 10초 안에 이 도구의 정체성과 대상 독자가 드러나게 쓴다. 한 문장에 한 뜻만 담고, 결론을 먼저 두며, 군더더기는 지운다"처럼 적는다.

**반박 1** — skills/domain-docs/SKILL.md:59-60의 인용문이 파일에 한 글자도 다르지 않게 존재하고, 두 괄호 모두 서술어 없이 명사 조각으로 끝나 PROSE-FORM(정본 20행, 상세 writing-korean 81·84·90행)의 개조식 금지에 걸린다. 인용·출처 표기를 면제하는 조항을 레포에서 찾지 못했고, 부수 지적인 77-78행 말끝 갈림(①③은 '-는가/-인가', ②는 맨 명사 '수명')도 사실이다. 제목이 쌍점을 쌍반점으로 뭉뚱그린 것과 consequence가 distill 목적을 다소 과하게 잡은 것은 본체 지적을 무너뜨리지 않는다.

**반박 2** — writing-korean SKILL.md 80-81행이 금지하는 "기호로 문장 대신하기"와 "명사 조각 종결"에 domain-docs 59-60행의 두 괄호가 그대로 해당하며, 명사구가 허용되는 자리(87-88행의 제목·라벨·표 머리)에 출처 주석은 포함되지 않고 76-77행은 산출물 문서에 "예외 없이" 적용한다고 못박아 예외 조항이 없다. consequence의 "distill 목적 붕괴"는 wikidocs 알맹이가 본문 37-38·47행에 이미 풀려 있어 과장이지만, InfoGrab 괄호의 네 항목은 산문으로 존재하지 않아 조각이 유일한 서술이고, 56-58행의 무주석 출처들과 말끝이 갈려 "한 목록 안에서 말끝 통일"(90-92행)에도 걸리므로 반박에 실패했다.

### 30. Claude 매니페스트만 어느 테스트도 JSON으로 파싱하지 않아 쉼표 하나가 어긋나도 검사가 초록으로 남는다.

**자리** — `scripts/test_scaffold.sh:580`

**걸린 원칙** — FAIL-LOUD · TDD

**근거** — `scripts/test_scaffold.sh:580` — `check "Claude 매니페스트에 version 없음"  "! grep -qE '\"version\"[[:space:]]*:' '$HERE/.claude-plugin/plugin.json'"` / `scripts/test_codex_scaffold.sh:98` — `check ".codex-plugin manifest is valid JSON" "json_valid_stdin < '$HERE/.codex-plugin/plugin.json'"` / `scripts/test_hooks.sh:179` — "전에는 hooks.json 하나만 유효성을 재다가, hooks-codex.json에 쉼표 하나가 어긋나도 초록인 상태였다"

**결과** — `.claude-plugin/plugin.json`이 깨지면 Claude Code가 플러그인을 통째로 못 읽어 원칙 주입과 spec·문서 게이트가 한꺼번에 죽는데, 전체 검사는 ALL PASS를 찍는다. 유일하게 이 파일을 보는 단언이 grep이라 파일이 JSON이 아니어도 통과하기 때문이다.

**상세** — `.codex-plugin/plugin.json`과 `hooks/hooks.json`·`hooks/hooks-codex.json`은 모두 `json_valid_stdin`으로 파싱까지 검사하고 `.claude-plugin/marketplace.json`도 `scripts/test_scaffold.sh:107`에서 파이썬 `json.load`로 읽힌다. 그런데 `.claude-plugin/plugin.json`을 파싱하는 곳은 저장소 전체에 없다. `test_hooks.sh`가 같은 구멍을 hooks 배선에서 이미 발견해 메워 두었다는 점에서 이것은 아직 안 메운 마지막 구멍이다.

**처방** — `test_scaffold.sh`의 매니페스트 절에서 `.claude-plugin/` 아래 `*.json`을 디렉터리에서 도출해 `json_valid_stdin`을 돌린다.

**반박 1** — 인용된 네 줄이 모두 파일에 그대로 존재하고, 저장소 전체에서 .claude-plugin/plugin.json을 JSON으로 파싱하는 곳은 없다. 이 매니페스트에 쉼표를 하나 더 넣어 파싱 불능으로 만든 뒤 scripts/test_*.sh 전체를 돌렸더니 ALL PASS가 나와 발견이 실측으로 재현되었다(검증 후 원상 복구).

**반박 2** — 저장소 전체에서 `.claude-plugin/plugin.json`을 파싱하는 곳이 없음을 확인했고, 이 파일을 보는 유일한 단언(test_scaffold.sh:580)은 부정 grep이라 JSON이 아닌 문자열에도 초록으로 통과함을 재현해 거짓 안심임을 확인했다 — 매니페스트가 깨지면 원칙 주입과 spec·문서 게이트가 조용히 죽는데 전체 검사는 ALL PASS를 찍으므로 FAIL-LOUD 위반이다. `claude plugin validate ./`라는 수동 백스톱이 심각도를 낮추기는 하나, 저장소 자신이 hooks-codex.json에서 같은 구멍을 같은 논리로 이미 메웠고(test_hooks.sh:179-184) 수정은 기존 json_valid_stdin 헬퍼를 글롭에 재사용하는 두 줄이라 SIMPLE 예외에도 해당하지 않는다.

### 31. README의 Codex 설치 단계에는 실행할 명령이 없어 사용자가 그 절만으로는 설치를 마칠 수 없다.

**자리** — `README.md:77`

**걸린 원칙** — CLEAR-COMM · EXPLICIT

**근거** — `README.md:77` — "1. **설치** — 이 레포를 Codex 플러그인으로 설치한다(`codex plugin` 설치 경로)." / 대비되는 Claude 경로는 README 설치 절에 `/plugin marketplace add chshin84/disciplined-coder`와 `/plugin install disciplined-coder@chshin-tools` 두 줄을 그대로 준다.

**결과** — Codex 사용자는 설치 단계에서 멈춘다. 그 뒤의 훅 신뢰검토와 세션 시작 자동 셋업은 설치가 끝나야 도는 것이라, 이 한 줄 때문에 Codex 병렬 계층 전체가 사용자에게 닿지 않는다.

**상세** — 이 레포는 개발을 배우지 않은 사람이 절차를 통과하게 하는 것을 목적으로 삼고 Claude 설치 절에서는 붙여 넣을 수 있는 명령과 Windows 전제 조건까지 적는다. 그런데 Codex 절은 괄호 하나로 실제 명령을 대신한다. 저장소를 통틀어 `codex plugin`으로 검색하면 이 README 줄과 `docs/superpowers/plans/2026-06-25-codex-parity-layer.md:574`의 같은 문장뿐이라, 어느 문서도 실제 명령을 갖고 있지 않다.

**처방** — Codex의 실제 설치 명령을 확인해 그대로 적고, 확인하지 못했다면 무엇을 확인하지 못했는지를 README에 드러낸다(FAIL-LOUD).

**반박 1** — README.md:77의 인용문은 글자 그대로 실재하고, 대비 대상인 Claude 설치 절(README.md:18-19, 21, 26)은 실제로 붙여 넣을 수 있는 명령과 전제 조건을 준다. 저장소 전체에서 `codex plugin`은 README:77·plans:574·specs:44 세 곳뿐이고 어느 곳도 실행 명령을 담지 않으며, DESIGN-NOTES와 .codex-plugin/plugin.json과 scripts/·hooks/에도 설치 명령이 없다. 발견의 detail이 세 번째 occurrence(specs:44)를 빠뜨린 것은 사소한 열거 오류일 뿐, 그 줄 역시 명령이 없어 반증이 되지 못한다.

**반박 2** — README.md:77의 Codex 설치 단계에는 실행 명령도 Codex 문서 링크도 없고, 같은 README가 Claude 경로에는 붙여 넣을 명령을 주므로 EXPLICIT·CLEAR-COMM 위반이 맞다. 명령을 확인하지 못했다는 변론은 설계 문서(specs/2026-06-25-codex-parity-layer-design.md)에 미검증 기록이 있으나 README에는 그 미검증 사실이 어디에도 드러나지 않아 FAIL-LOUD로도 막히지 않는다. 다만 결과 서술("Codex 계층 전체가 닿지 않는다")은 과하며 실제로는 마찰이고, 수정 비용은 한 줄로 낮다.

---

## 반박에서 기각된 것

아래 열하나는 렌즈가 지적했으나 반박에서 근거가 무너져 확정으로 올리지 않았다. 기각은 문제가 없다는
뜻이 아니라 이번 표본에서 근거가 모자랐다는 뜻이다.

- README는 superpowers가 없으면 병렬 오케스트레이션이 아무것도 하지 않고 넘어간다고 단정하지만, 그렇게 넘어가게 하는 장치가 어디에도 없다.
- 자기감사 워크플로가 정본이 `project-doc-audit` 회차에만 허용한 여럿 동시 띄우기를 그 밖에서 하고, 리뷰어가 아닌 검증자까지 병렬로 연다.
- 경로 정규화가 백슬래시뿐 아니라 이어진 슬래시까지 하나로 줄여 UNC 경로와 // 가 든 경로를 망가뜨린다.
- 리뷰 기록을 넛지에서 빼는 규칙이 쌍둥이 훅 가운데 한쪽에만 있어 기록을 쓸 때마다 엉뚱한 양식 제안이 뜬다.
- nested-orchestration의 「재구현 금지」 절은 세 불릿 전부에 서술어가 없어 PROSE-FORM이 금지한 개조식 그대로다.
- 화살표가 문장을 대신하는 자리가 네 문서에 있고, 그중 하나는 문서 저작 규칙을 소유한 domain-docs 자신이다.
- 더하기 기호를 접속사로 쓰는 자리가 다섯 문서에 흩어져 있어 기호가 조사와 이음말을 대신한다.
- Codex 매니페스트는 version을 0.1.0으로 박아 두어 domain-plugin이 금지한 배포 단절 상태에 들어가 있다.
- domain-plugin은 범위를 Claude Code로 못 박아 두어 Codex 미러 배선을 아무 규칙도 지키지 않는 채로 남긴다.
- Codex 런타임에 관한 주장들은 실측 스탬프 없이 적혀 있어 틀렸을 때 드러날 자리가 없다.
- project-doc-audit이 정한 회차 파일 이름 규칙을 이 레포의 둘째 회차 기록이 지키지 않았다.
