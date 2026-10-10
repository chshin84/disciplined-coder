# nested-orchestration 큰 개발 분할 — 2026-10-10 개정 리뷰

대상은 `docs/superpowers/specs/2026-10-09-nested-orchestration-large-dev-design.md` 의 「2026-10-10 개정」 절이고, 함께 바뀐 `skills/nested-orchestration/SKILL.md`, `agent-principles.md` 「병렬 오케스트레이션」, `docs/domain-discipline.md` `SUB-ORCHESTRATE` 절을 배경으로 넘겼다. 대상은 `docs/superpowers/specs` 아래에 있으므로 spec 으로 구분했다.

렌즈를 한 번씩만 실행했다. 실행한 렌즈는 `lens-grounding`, `lens-consistency`, `lens-adversarial`, `lens-fit` 이고 원본은 같은 이름의 폴더에 있다.

선행연구 렌즈는 제안하지 않았다. 이번 개정의 근거가 같은 날 사용자가 직접 요청해 실행한 선행연구 대조이고, 그 결과가 개정 절 「근거」 표에 이미 들어 있기 때문이다. 그 대조의 기록은 `2026-10-10-sub-orchestrate-criteria-prior-art.md` 에 있다.

## 합친 지적

거른 지적은 아래와 같다.

- `lens-grounding` 의 "CAID 가 의존이 강한 파일을 한 작업자에 묶었다는 내용은 출처에 없다"는 거른다. arXiv 2603.21489 본문에 "Files with strong or circular dependencies are grouped together and assigned to the same engineer" 가 있다. 렌즈에 주입한 출처 요약에 이 문장을 넣지 않았기 때문에 생긴 지적이다.

남은 지적은 아래와 같다. 괄호는 같은 지적을 잡은 렌즈다.

- **원칙 머리 문장의 기준 잔존** (grounding, consistency, fit) — 머리 문장이 조건 없이 "나눠 맡겨라"라고 명령해, 기준은 스킬이 소유하고 조항은 판단 시점만 가리킨다는 개정 결정과 부딪친다. 독립된 큰 일 트리거는 이 머리 문장에만 남아 있다(consistency).
- **원칙 조항 문구** (fit) — brainstorming 을 판단 주체로 썼고, "plan을 쓰기 직전에는"과 "plan을 쓰기 전에"가 겹치며, 영어 이름이 개정 전 지시를 가리킨다. 머리 문장은 하위 시스템, 조항은 하위 프로젝트라 부른다.
- **이름 통일 미완** (grounding, consistency, fit) — "서로 독립된 큰 일"로 통일한다고 정했으나 스킬 머리와 본문, 원칙 머리 문장이 다른 이름을 쓴다. "큰 일"의 정의가 「라우팅」에 늦게 나온다(fit).
- **agent-teams 인용 왜곡** (grounding) — 원문은 "단일 세션 또는 서브에이전트"가 agent teams 보다 낫다고 적는데 개정과 스킬은 "단일 세션이 낫다"로 옮겼다.
- **ClarifyMT-Bench 연도** (grounding) — arXiv 2512.21120 은 2025-12-24 등록이다.
- **Cognition·CAID 사례의 범위** (grounding) — 함수 이름 변경 사례는 OpenHands 소개 글에 있고, 공용 코드를 부르는 작업 사이의 충돌이다.
- **Specification Gap 주원인 단정** (grounding) — 초록은 "공유 결정 없이 호환 코드를 만드는 어려움"이라고 적고 "주원인"이라는 판정은 없다.
- **v7 비트리거 단정** (grounding) — 측정하지 않은 추론을 가정 표시 없이 적었다.
- **"사용자 지시만" 배타 조건** (grounding, adversarial) — `using-superpowers` 는 우선순위만 적는다. 조항 유지·삭제 판정 기준도 없다(adversarial).
- **승인 뒤 세 세션 관찰의 출처** (grounding) — 어느 세션인지 적지 않았다.
- **채택 관문 부재** (consistency, adversarial) — 앞 절 「확인 방법」 2의 현행 대비 채택 기준과 훅 제안 후속 조치를 개정이 대체하는지 밝히지 않았다. 표본은 과제당 1회 자기 판정이다.
- **개정 절의 바뀌는 파일·확인 방법 부재** (consistency) — 앞 절 후보 문안과 domain-discipline 지시가 낡았다.
- **대상 목록 이름 드리프트** (consistency) — '나눌지 판단'은 「결정」에 없는 이름이고 「서로 무관한 일」 「묶는 단위」 「요청 트리거」가 목록에 없다.
- **의존의 두 뜻** (consistency) — 합칠 사유의 의존과 순서를 정할 사유의 의존을 구분하지 않았다.
- **잠금 파일** (adversarial, consistency) — 소유 워크스트림 진행 중 BLOCKED 된 의존성 추가의 해제 경로가 없어 병렬이 직렬로 바뀐다. 단일 소유와 교집합 검사 아래에서 충돌 해결 절차는 적용될 상황이 없다.
- **사용자 가시 결정의 승인 우회** (adversarial) — 승인 항목이 범위 밖 결정을 잡지 못한다.
- **승인된 설계 문서 본문과의 대조 누락** (adversarial) — 두 번째 시점에서 사용자가 승인한 내부 방식이 하부 명세에서 바뀌어도 승인을 통과한다.
- **공유 가정 전파 경로** (consistency) — 이어 쓰기 메시지 목록에 없고 시점이 앞 절과 다르다.
- **Self-Rulings** (adversarial, consistency) — 스스로 인식한 모호함만 세는데 추측 전체를 센다고 서술했고, 템플릿 8 리포트 항목에 없다.
- **범위 밖 불확실 시 멈춤과 "Rulings, not stalls"** (consistency) — 앞 절이 충돌을 이유로 기각한 규칙이 한정된 형태로 되살아났다.
- **두 번째 시점의 브랜치 순서** (consistency) — 승인된 설계 문서가 놓인 브랜치와 dev 브랜치 생성의 선후가 없다.
- **스킬 포인터 드리프트** (consistency, grounding, fit) — 스킬은 새 출처를 설계 문서 「근거와 한계」에서 찾게 하지만 개정 절 「근거」에 있다.
- **문체** (fit) — 목록 앞 개수 예고, 문서·기준을 판단 주체로 쓴 문장, 라우팅 불릿의 주체 생략, 여러 문장짜리 불릿, 네 문장을 넘는 단락, 한 문장 두 개념, '+' 기호 조건 표기, 개정 머리의 주체 생략.
- **v7 사본 위치** (adversarial notes) — 근거인 v7 brainstorming 은 세션 스크래치에만 있어 나중에 대조할 원본으로 원본 저장소 커밋을 적어야 한다.

## 커버리지 공백

`aggregating-lenses` 기준으로 네 렌즈가 모두 결과를 냈고 `principles_applied` 가 비지 않았다. 아무 렌즈도 보지 않은 관점은 v7 에서 SDD·HARD-GATE 인용 행 번호가 그대로인지이며, `lens-consistency` 와 `lens-adversarial` 이 확인 대상으로 남겼다.
