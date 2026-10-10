# nested-orchestration 큰 개발 분할 — 2026-10-10 개정 2차 리뷰

대상은 1차 리뷰(`2026-10-10-nested-orchestration-large-dev-review.md`)를 반영한 `docs/superpowers/specs/2026-10-09-nested-orchestration-large-dev-design.md` 「2026-10-10 개정」 절이다. 함께 바뀐 `skills/nested-orchestration/SKILL.md`, `agent-principles.md` 「병렬 오케스트레이션」, `docs/domain-discipline.md` `SUB-ORCHESTRATE` 절을 배경과 대상으로 넘겼다. 사용자가 다시 리뷰를 골랐다.

렌즈를 한 번씩만 실행했다. 실행한 렌즈는 `lens-grounding`, `lens-consistency`, `lens-adversarial`, `lens-fit` 이고 원본은 같은 이름의 폴더에 있다. `lens-fit` 원본은 필드를 줄여 옮겼다.

선행연구 렌즈는 제안하지 않았다. 1차와 같은 이유다.

## 거른 지적

- `lens-grounding` 의 "C2 세션이 보존 기간을 멈추지 않고 판정한 것은 정의 위반"은 거른다. 그 세션은 보존 기간을 새로 정하지 않고 삭제 기능도 만들지 않았으며, 개정 정의는 큰 명세에 없는 기능을 만들지 않는 결정을 범위 안으로 둔다. 다만 spec 문장이 이 사정을 적지 않아 오해를 낳았으므로 문장은 고친다.
- `lens-grounding` 의 "쌍마다 판정 근거 일치는 출처에 없다"는 거른다. 호출자가 렌즈에 넘긴 요약에만 없었고, 세 시험 결과는 열 쌍 모두 설계 의존·경로 겹침이 아니라고 판정했다.

## 합친 지적

괄호는 같은 지적을 잡은 렌즈다.

- **원칙 머리 문장과 조항** (consistency, fit) — 머리 문장의 적용 조건이 조항의 둘째 시점보다 좁고, 독립된 큰 일 트리거가 머리 문장에만 있다. '나누다'가 분해와 위임 두 뜻으로 쓰이고, 머리와 조항이 포함 중복이며, '독립된 큰 일'이 스킬 용어와 다르다.
- **묶는 단위 규칙** (adversarial, consistency, fit) — 경로 겹침 조건은 공용 파일 정의 때문에 합치기로 이어지지 않는다. 설계 의존 쌍을 합치면 하부 명세를 한 번만 쓰는 흐름과 맞지 않는다. 쌍 사슬과 태스크 다섯 미만 후보의 처리가 없다. 판정 시점에 pathspec 이 아직 없다.
- **domain-discipline 인용과 추정 표시** (grounding, consistency) — '지금 문구' 인용이 반영 전 조항이고, v7 비트리거를 가정 표시 없이 적었다.
- **셋·넷 혼동** (grounding) — 셋과 넷은 서로 다른 시험의 값인데 한 시험의 흔들림처럼 적었다.
- **Ask-F1 이름** (grounding) — F1 값을 보고하지 않았다.
- **URL 부재** (grounding) — 표에 출처 URL 이 없다.
- **dev 브랜치 생성 서술** (consistency, fit) — 「큰 명세」 끝 문단, 「계약 코드」, 「흐름」 1단계가 서로 다르다.
- **잠금 파일 요청 경로** (adversarial, consistency) — 이어 쓰기 시점 규칙 때문에 요청이 소유 워크스트림 종료까지 기다리고, 소유자가 끝난 뒤의 경로가 앞 문장과 이어지지 않으며, 소유 워크스트림을 적을 칸이 큰 명세 항목에 없다.
- **공유 가정의 늦은 전달** (adversarial) — 진행 중인 워크스트림이 다른 가정으로 구현을 끝낼 수 있다.
- **판정 기록을 읽는 시점** (adversarial, consistency) — plan·구현 단계 판정을 DONE 뒤에 읽는 단계가 없다.
- **Self-Rulings 트레일러** (adversarial) — 그 값으로 정하는 결정이 없다.
- **다른 저장소의 독립된 큰 일** (adversarial) — 흐름과 가드레일이 저장소 하나를 전제한다.
- **라우팅 충돌** (adversarial) — 단일 태스크를 나눠 맡기라는 요구에 세 불릿이 다른 스킬을 가리킨다.
- **후속 조치의 스킬 부재** (consistency) — 조항 삭제 제안, 훅 제안, 상한 결정이 spec 에만 있다.
- **개정 절 대상 목록** (consistency) — 바뀐 앞 절과 새 결정 일부가 목록에 없다.
- **행 번호** (consistency, grounding) — '13~16행'은 실제 14~15행이다.
- **문체** (fit) — SKILL 31행 판단 주체, '하위 시스템' 미정의, 개수 예고, 다문장 불릿, 네 문장 초과 단락, 표 말끝, 사물 주어 문장, '세 경로 분류' 미해설, 수식어 겹침, 확인 방법 3·4항의 혼합.

## 커버리지 공백

네 렌즈가 모두 결과를 냈고 `principles_applied` 가 비지 않았다. v7 의 brainstorming·SDD 인용 행 번호와 Stop 게이트가 결정 기록 커밋마다 재리뷰를 요구하는지는 아무 렌즈도 확인하지 않았다.
