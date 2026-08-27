# 대응표 — agent-principles.md

> **되돌린 작업의 기록이다(superseded).** 이 표는 정본과 스킬 문서를 영문으로 다시 쓰는 회차에서
> 만들었고, 그 재작성은 되돌려졌다 — 정본은 지금도 한국어다. 그래서 「새 문서 위치」 칸은 그때의
> 영문 문서를 가리키며 지금의 문서 구조가 아니다. 무엇을 왜 옮기고 지웠는지의 판단만 쓸모가 있어
> 남겨 두는 것이니, 지금 문서를 찾을 때 이 표를 따라가지 마라.

원문의 각 항목이 새 문서 어디로 갔는지, 지웠다면 왜 지웠는지 남긴다.
'지움' 항목과 빈칸이 사람이 검토할 대상이다.

세 번째 칸의 값은 `옮김`, `합침`, `**지움**`, `신설` 중 하나이며 지움에는 반드시 근거를 붙인다.
`신설`은 원문에 없던 것을 스펙이 요구해 새로 넣은 항목이라 왼쪽 칸이 `(원문 없음)`으로 시작한다.

지움은 네 개다 — `SURGICAL`의 주변 스타일 따르기, `IDEMPOTENT`의 멱등성 정의, `SIMPLE`의 YAGNI 약어
풀이, 오답노트의 옛 형식 서술이다. 앞의 셋은 Opus 5가 기본으로 하거나 영어 용어 자체가 설명하는 것이고,
마지막 하나는 스펙이 지우라고 지시한 것이다. `SIMPLE`의 주변 관례 따르기는 처음엔 지움으로 처리했으나
리뷰에서 `CLEAR-COMM`이 `(SIMPLE)`로 그 지시를 참조하고 있음이 드러나 옮김으로 정정했다 — 아래 표를
보라.

| 원문 항목 | 새 문서 위치 | 처리와 근거 |
|---|---|---|
| H1 `# 디시플린 (팀 원칙)` | H1 `# Discipline (Team Principles)` | 옮김 — 이 제목이 정본에만 있는 유일 문자열이라 스캐폴드 가드가 이것을 문다 |
| 서문 — 모든 작업에 항상 적용한다 | 서문 첫 문장 | 옮김 |
| 서문 — 이 파일이 SSOT다 | 서문 첫 문단 | 옮김 |
| 서문 — 플러그인이 사본을 `~/.claude/disciplined-coder/`에 두고 `@import`로 주입한다 | 서문 첫 문단 | 옮김 |
| 서문 — 프로젝트 폴더에는 아무것도 쓰지 않는다 | 서문 첫 문단 | 옮김 |
| 서문 — `~/.claude` 사본을 직접 고치지 마라(매 세션 갱신된다) | 서문 첫 문단 끝 | 옮김 |
| 서문 — 각 원칙은 짧은 ID로 참조한다 | 서문 둘째 문단 | 옮김 |
| 서문 — 우선순위 규칙은 `NO-PRIORITY`를 보라 | 서문 둘째 문단 | 옮김 |
| 절 제목 `## 원칙 (ID로 참조 · 알파벳순)` | `## Principles (referenced by ID, alphabetical)` | 옮김 |
| `CLEAR-COMM` — 결론만 던지지 말고 근거와 기각한 대안까지 설명한다 | `CLEAR-COMM` | 옮김 |
| `CLEAR-COMM` — 단계를 건너뛰지 않는다 | `CLEAR-COMM` | 옮김 |
| `CLEAR-COMM` — 판단이 필요한 곳에서는 명확히 질문한다 | `CLEAR-COMM` | 옮김 |
| `CLEAR-COMM` — 전달은 읽는 사람 기준으로 한다 | `CLEAR-COMM` | 합침 — 바로 뒤의 '결론 먼저(점진적 공개)'와 한 문장("Write for the reader — conclusion first…")으로 묶었다 |
| `CLEAR-COMM` — 결론 먼저, 근거는 뒤(점진적 공개) | `CLEAR-COMM` | 합침 — 위와 같은 문장 |
| `CLEAR-COMM` — 한 문장에 한 개념, 단락은 짧게 | `CLEAR-COMM` | 옮김 |
| `CLEAR-COMM` — 전문영역 용어를 나올 때마다 부연한다 | `CLEAR-COMM` | 옮김 |
| `CLEAR-COMM` — 짧은 답보다 피로도 낮은 답(토큰 아끼려 압축 금지) | `CLEAR-COMM` | 옮김 |
| `CLEAR-COMM` — 문장 길이를 변주하고 긴 답은 소제목으로 끊는다 | `CLEAR-COMM` | 옮김 |
| `CLEAR-COMM` — 완결된 문어체 '~한다/~이다'로 통일(구조화 산출물도 예외 없음) | 한국어 문체 블록 | 옮김 — 한국어 어미를 판정하는 규칙이라 블록 안에 한국어로 둔다 |
| `CLEAR-COMM` — 'A vs B'처럼 명사 조각으로 선택지를 나열하지 않는다 | 한국어 문체 블록 | 옮김 |
| `CLEAR-COMM` — 'X = Y'·'원인 → 해결'처럼 기호로 문장을 대신하지 않는다 | 한국어 문체 블록 | 옮김 |
| `CLEAR-COMM` — '미배선'·'확정?'처럼 명사 조각이나 말끝 흐림으로 끝내지 않는다 | 한국어 문체 블록 | 옮김 |
| `CLEAR-COMM` — 표 셀도 알아볼 수 있는 문장이나 구로 채운다 | 한국어 문체 블록 | 옮김 |
| `CLEAR-COMM` — 항목을 번호로 부르지 않는다(근거 포함) | `CLEAR-COMM` | 옮김 — 예시를 `R6`·`Task 3`·`case 18`로 그대로 살렸다 |
| `CLEAR-COMM` — 번호 금지를 스펙 요구사항·계획 태스크·문서 절에도 적용한다 | `CLEAR-COMM` | 옮김 |
| `CLEAR-COMM` — 코드 식별자는 주변 관례를 따르되 로그에 찍히면 이름을 쓴다 | `CLEAR-COMM` | 옮김 |
| `CLEAR-COMM` — 문어체이되 딱딱하지 않게 | 한국어 문체 블록 | 옮김 |
| `CLEAR-COMM` — 나쁜 예와 고친 예 | 한국어 문체 블록 | 옮김 — 두 예문 모두 원문 그대로 두되 완결 문장으로 감쌌다 |
| (원문 없음) 응답 언어를 한국어로 명시 | `CLEAR-COMM` 영문 첫 문장 + 한국어 블록 첫 항목 | 신설 — 정본이 영문이 되면 응답 언어 신호가 사라진다(스펙 '응답 언어를 명시한다'). 한국어 문장으로도 둔 이유는 `canon: reply-in-Korean directive` 가드가 그 문자열을 물기 때문이다 |
| (원문 없음) `korean-style-rules` 시작·끝 마커 | 한국어 문체 블록을 감싸는 HTML 주석 | 신설 — 이 마커가 없으면 한글 개수만 세는 검사가 소재를 특정하지 못해 계약이 성립하지 않는다 |
| `EXPLICIT` — 숨은 마법을 두지 않는다 | `EXPLICIT` | 옮김 |
| `EXPLICIT` — 의도가 이름·타입·계약에 드러나야 한다 | `EXPLICIT` | 옮김 |
| `EXPLICIT` — 필요한 맥락을 명시적으로 전달한다 | `EXPLICIT` | 옮김 |
| `FAIL-LOUD` — 틀어지면 즉시 눈에 띄게 터뜨린다 | `FAIL-LOUD` | 옮김 |
| `FAIL-LOUD` — 계약 위반이나 드리프트를 삼키지 않는다 | `FAIL-LOUD` | 옮김 — 드리프트 괄호 설명도 남겼다(이 레포 고유 의미라 기본 상식이 아니다) |
| `FAIL-LOUD` — 구조가 실수를 막거나 드러내게 만든다 | `FAIL-LOUD` | 옮김 |
| `FAIL-LOUD` — 강건함이 작성자의 정확성보다 낫다 | `FAIL-LOUD` | 옮김 |
| `FOCUSED` — 한 단위는 한 가지 일만 한다 | `FOCUSED` | 옮김 |
| `FOCUSED` — 내부를 몰라도 인터페이스만으로 쓸 수 있게 한다 | `FOCUSED` | 옮김 |
| `FOCUSED` — 관련 없는 것은 독립적으로 둔다(직교성) | `FOCUSED` | 옮김 |
| `FOCUSED` — 파일이 비대해지면 분리 신호다 | `FOCUSED` | 옮김 |
| `IDEMPOTENT` — 스크립트·마이그레이션·셋업은 여러 번 돌려도 안전하다 | `IDEMPOTENT` | 옮김 |
| `IDEMPOTENT` — 멱등성이 무엇인지 정의하는 문장 | (없음) | **지움** — 한국어 독자에게 'idempotent'라는 낯선 용어를 풀어 주던 주석이다. 영어 용어 자체가 자기설명적이고, 바로 앞뒤 문장이 이미 같은 뜻을 행동 지시로 말한다 |
| `IDEMPOTENT` — 이미 된 것은 건너뛰고 중복·손상을 만들지 않는다 | `IDEMPOTENT` | 옮김 |
| `MEASURE-FIRST` — 가정하지 말고 먼저 확인한다 | `MEASURE-FIRST` | 옮김 |
| `MEASURE-FIRST` — 환경·데이터·실제 동작이 생각과 다를 수 있다 | `MEASURE-FIRST` | 옮김 |
| `MEASURE-FIRST` — 추측 위에 쌓은 작업은 헛수고가 된다 | `MEASURE-FIRST` | 옮김 |
| `MEASURE-FIRST` — 휘발성 사실은 진실에서 도출한다(상태 문서는 캐시다) | `MEASURE-FIRST` | 옮김 |
| `NO-PRIORITY` — 원칙 사이에 우열이나 순서가 없다 | `NO-PRIORITY` | 옮김 |
| `NO-PRIORITY` — 알파벳순 용어집이며 위치에 의미가 없다 | `NO-PRIORITY` | 옮김 |
| `NO-PRIORITY` — 상황에 맞는 원칙을 모두 적용한다 | `NO-PRIORITY` | 옮김 |
| `REVERSIBLE` — 되돌릴 수 있는 결정(양방향 문)을 선호한다 | `REVERSIBLE` | 옮김 |
| `REVERSIBLE` — 단방향 문은 신중히 하고 근거를 남긴다 | `REVERSIBLE` | 옮김 |
| `SECRETS` — 진짜 비밀은 백엔드 전용으로 둔다 | `SECRETS` | 옮김 |
| `SECRETS` — 클라이언트에는 비밀이 아닌 식별자만 내보낸다 | `SECRETS` | 옮김 |
| `SECRETS` — 프롬프트·로그에 비밀과 PII를 남기지 않는다 | `SECRETS` | 옮김 — PII는 약어 대신 풀어 썼다 |
| `SIMPLE` — 지금 필요 없는 일반화나 추상화를 만들지 않는다 | `SIMPLE` | 옮김 |
| `SIMPLE` — YAGNI 약어 풀이("You Aren't Gonna Need It") | (없음) | **지움** — 한국어 독자용 약어 풀이다. 영어권 개발 문서에서 널리 통용되는 약어이고, 같은 항목의 첫 문장이 그 뜻을 이미 행동 지시로 적는다 |
| `SIMPLE` — 가장 단순한 것부터 시작하고 복잡함은 필요할 때만 더한다 | `SIMPLE` | 옮김 |
| `SIMPLE` — 단일 호출로 될 일을 에이전트 시스템으로 키우지 않는다(지연·비용) | `SIMPLE` | 옮김 |
| `SIMPLE` — 코드는 읽히는 횟수가 많으니 주변 관례를 따른다 | `SIMPLE` | 옮김 — 최초엔 `SURGICAL`과 중복이라 지웠으나, `CLEAR-COMM`의 "An identifier inside code follows local convention (`SIMPLE`)"가 이 지시를 괄호로 참조하고 있어 지우면 참조가 허공을 가리킨다. 그래서 `SIMPLE` 항목에 한 문장으로 복원했다 |
| `SSOT` — 하나의 사실·설정·결정은 한 곳에만 권위 있게 둔다 | `SSOT` | 옮김 |
| `SSOT` — 다른 데서는 복제하지 말고 참조하거나 도출한다 | `SSOT` | 옮김 |
| `SSOT` — 사람이 두 곳을 손으로 맞추면 반드시 어긋난다 | `SSOT` | 옮김 |
| `SURGICAL` — 요청과 직접 연결된 줄만 바꾼다 | `SURGICAL` | 옮김 |
| `SURGICAL` — 작동하는 주변 코드를 리팩터·정리·재포맷하지 않는다 | `SURGICAL` | 옮김 |
| `SURGICAL` — 죽은 코드는 표시만 하고, 내 변경으로 불필요해진 것만 지운다 | `SURGICAL` | 옮김 |
| `SURGICAL` — 주변 코드의 스타일을 따른다 | (없음) | **지움** — Opus 5 기본 프롬프트와 겹치는 데다, 같은 지시가 `SIMPLE`에 남아 있어("Code is read far more often than it is written, so follow the convention already established around it") 정본 안에서 중복이다 |
| `TDD` — 실패하는 테스트를 먼저 쓴다 | `TDD` | 옮김 |
| `TDD` — 검증 가능한 성공 기준을 미리 정한다 | `TDD` | 옮김 |
| `TDD` — 실행 증거 없이 "됐다"고 하지 않는다 | `TDD` | 옮김 |
| 절 제목 `## 환경 관례 (보편 원칙 아님)` | `## Environment convention (not a universal principle)` | 옮김 |
| `DOCKER-FIRST` — 도커가 있으면 프로덕션과 같은 컨테이너에서 돌린다 | `DOCKER-FIRST` | 옮김 — 폴백과 "보편 원칙 아님" 단서까지 함께 남겼다 |
| 절 제목 `## 공통 함정 (cross-project gotchas)` | `## Cross-project gotchas` | 옮김 |
| 함정 — `.gitignore` 인라인 주석 미지원 | `Cross-project gotchas` 첫 항목 | 옮김 — 예시 주석만 영문(`# ignore logs`)으로 바꿨다 |
| 함정 — mock과 실제 클라이언트의 `None` 차이 | `Cross-project gotchas` 둘째 항목 | 옮김 |
| 함정 — 테스트 기대치 매직 넘버 금지 | `Cross-project gotchas` 셋째 항목 | 옮김 |
| 절 제목 `## 절차 (원칙과 별개 — 트리거가 오면 실행)` | `## Procedures (separate from the principles — run them when the trigger fires)` | 옮김 |
| 절차 서문 — 트리거 인덱스만 두고 '어떻게'는 호출자 스킬이 SSOT다 | 절차 서문 인용 블록 | 옮김 |
| `가.` 검증 레이어 — 절 제목 | `### Verification Layer` | 옮김 — 스펙의 절 이름 표를 따른다 |
| 검증 레이어 — 리드 문단(단독 결론으로 마치지 마라) | `Verification Layer` 리드 | 옮김 |
| 검증 표 — 제품 런타임 LLM 호출 행 | 검증 표 첫 행 | 옮김 |
| 검증 표 — spec 작성 행 | 검증 표 둘째 행 | 옮김 |
| 검증 표 — plan 작성 행 | 검증 표 셋째 행 | 옮김 |
| 검증 표 — 문서 작성 행 | 검증 표 넷째 행 | 옮김 |
| 검증 표 — 멀티에이전트 워크플로 행 | 검증 표 다섯째 행 | 옮김 — 트리거 문자열이 `Authoring or running a multi-agent workflow`, 강제 방식이 `ultracode review mode`로 바뀌었고 가드 셋이 그 문자열을 문다 |
| 검증 레이어 — 방법 상세는 호출자 스킬이 SSOT다 | 검증 표 아래 문단 | 옮김 |
| `나.` 설계 입력 — 절 제목 | `### Design Inputs` | 옮김 |
| 설계 입력 — domains-index를 열어 명세에 반영한다(검증이 아니라 요구사항 수집) | `Design Inputs` 본문 | 옮김 |
| `다.` 오답노트 — 절 제목 | `### Solved Log` | 옮김 |
| 오답노트 — 이슈·백로그를 추적하지 않는다(범위 밖) | `Solved Log` 리드 | 옮김 |
| 오답노트 — 서브에이전트도 읽으므로 역할을 바로 알게 적는다 | `Solved Log` 리드 | 옮김 |
| 오답노트 — solved는 완결 후 기록하는 append-only 오답노트다 | `Solved Log` 첫 항목 | 합침 — '완결 후 기록'은 그대로 두고, append-only라는 단정은 아래 '해결법이 바뀌면 고쳐 쓴다'와 충돌하므로 그 항목으로 흡수했다 |
| 오답노트 — 옛 형식 서술("증상/트리거 → 교훈, 처방이 앞") | (없음) | **지움** — 스펙이 지우라고 지시한 항목이다. 새 형식은 순서가 반대라 남기면 서로 반대인 형식 정본 둘이 공존한다. 형식의 SSOT는 로그 머리말이며 새 문서는 거기를 가리킨다 |
| 오답노트 — 완결 후 기록이라 '상태'가 아니다(문서 상태 금지의 예외) | `Solved Log` 첫 항목 | 옮김 |
| 오답노트 — recall은 PC와 프로젝트 로그 둘 다에서, 파일 존재로 도출한다 | `Solved Log` 'Recall before you start' 항목 | 옮김 — `/init`이 포인터를 덮어도 recall된다는 근거까지 남겼다 |
| 오답노트 — 스코프 라우팅(프로젝트/머신 전역/보편) | `Solved Log` 'Route by scope' 항목 | 합침 — 아래 신설 항목(파일이 없으면 그때 만든다)과 한 항목으로 묶었다. 스코프 판정과 그 결과로 쓸 파일을 마련하는 일이 같은 결정이기 때문이다 |
| 오답노트 — 열린 것은 추적 말고 처분하라(4단) | `Solved Log` 'Dispose of open items' 항목 | 옮김 — 네 갈래와 `issue-mode` 토글, "issues 모드도 상태 추적이 아니다"라는 단서까지 남겼다 |
| 오답노트 — 🔴는 쟁이지 말고 즉시 surface한다 | `Solved Log` '🔴 is surfaced, never stored' 항목 | 옮김 |
| 오답노트 — solved는 메인 세션만 쓴다(서브에이전트는 리턴으로 보고) | `Solved Log` 마지막 항목 | 옮김 |
| (원문 없음) 프로젝트 solved 파일이 없으면 그때 만든다 | `Solved Log` 'Route by scope' 항목 | 신설 — 스펙의 오답노트 규약. 미리 만들지 않는 이유(빈 로그는 recall해도 얻는 게 없다)까지 적었다 |
| (원문 없음) 해결법이 바뀌면 그 항목을 고쳐 쓴다 | `Solved Log` 'Rewrite an entry when its fix changes' 항목 | 신설 — 스펙의 오답노트 규약. 바꾼 이유는 spec에 남긴다는 단서 포함 |
| (원문 없음) 결정과 취향은 solved가 아니라 spec에 적는다 | `Solved Log` 'Decisions and preferences' 항목 | 신설 — 스펙의 오답노트 규약 |
| `라.` 문서·상태 위생 — 절 제목 | `### Document Hygiene` | 옮김 |
| 문서 위생 — 기억으로 유지되지 않는다, 애초에 stale 불가능하게 짓는다 | `Document Hygiene` 리드 | 옮김 |
| 문서 위생 — 트리거는 문서를 쓰거나 지우는 그 순간이다 | `Document Hygiene` 리드 | 옮김 |
| 문서 위생 — 타입을 먼저 분류하라(상세는 `domain-docs`가 SSOT) | `Document Hygiene` 첫 항목 | 옮김 — 일곱 타입과 드리프트 가드 열거까지 그대로 남겼다 |
| 문서 위생 — 사실 ≠ 판단 | `Document Hygiene` 둘째 항목 | 옮김 — 제목의 `≠` 기호는 `CLEAR-COMM`을 따라 문장("A fact is not a judgement")으로 풀었다 |
| `마.` 병렬 오케스트레이션 — 절 제목 | `### Parallel Orchestration` | 옮김 |
| 병렬 오케스트레이션 — 멀티태스크 플랜이면 3층 배열을 고려한다 | `Parallel Orchestration` 본문 | 옮김 |
| 병렬 오케스트레이션 — 단일 태스크면 `dispatching-parallel-agents`(2층)로 간다 | `Parallel Orchestration` 본문 | 옮김 |
| 병렬 오케스트레이션 — 사람 병목은 스펙 국면이라 잠기는 즉시 팬아웃한다 | `Parallel Orchestration` 본문 | 옮김 |
| 병렬 오케스트레이션 — 상세는 `nested-orchestration`이 SSOT다 | `Parallel Orchestration` 마지막 문장 | 옮김 |
