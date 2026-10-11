# nested-orchestration 설계 「2026-10-11 개정 — 검진 반영」 리뷰 기록

대상은 `docs/superpowers/specs/2026-10-09-nested-orchestration-large-dev-design.md`의 「2026-10-11 개정 — 검진 반영」 절이다(브랜치 `ws/nested-review/design`, 커밋 전 작업 트리). 이 개정을 쓴 실행자는 경로가 `docs/superpowers/specs` 아래이므로 spec 으로 판정했다. 실행한 렌즈는 `lens-grounding`, `lens-consistency`, `lens-adversarial`, `lens-fit`이고, 쓰기 도구가 없는 에이전트 종류로 실행했다. 원본은 같은 이름의 폴더에 줄여 옮겼다.

렌즈를 한 번씩만 실행했다.

`lens-prior-art`는 제안하지 않았다. 이 절은 사용자가 이미 내린 결정과 검진 결과를 기록하는 개정이라 발동 기준(해본 적 없는 것을 해내려 함)에 들지 않는다. 이 개정을 쓴 실행자는 사람과 대화할 수 없는 서브에이전트이기도 하다.

## 합친 지적 목록

| 지적 | 렌즈 원본 | 공동 |
|---|---|---|
| 측정 지시를 스킬에서 빼면 첫 큰 개발의 현재 세션이 그 항목을 열지 않아 측정 없이 끝난다 | adversarial 1 | 아니오 |
| `ASSUMPTION-ADDED`를 `CONTRACT-CHANGED`에 합친 뒤 받는 쪽 행동(고치지 않고 멈춤과 맞춤)을 정하지 않았다 | adversarial 2 | 아니오 |
| 남는 사유 코드 이름·순서, 현재 세션 소유 아래 `dependency-add` 처리, 하향 메시지 필드를 새 절이 다시 정하지 않았다 | adversarial 3, consistency 2 | 예 |
| 세션당 표시로 바꾸면 경로 키가 필요 없는데 키 충돌 수정을 결함으로 남겼다 | adversarial 4 | 아니오 |
| 세션당 표시는 같은 세션의 둘째 새 spec(큰 개발)을 거부하지 않는 손실이 있는데 적지 않았다 | adversarial 5 | 아니오 |
| 훅 사유의 「맡기는 기준」 사본과 원본의 관계를 정하지 않았다 | adversarial 6 | 아니오 |
| references 분리와 「메시지 형식」 위치·절대 경로 규칙의 관계를 적지 않았고, 「메시지 형식」 「반영 위치」 문장과 충돌한다 | adversarial 7, consistency 4 | 예 |
| 복수 사유에서 `user-decision` 유형을 줄마다 적는 규칙이 없다 | adversarial 8 | 아니오 |
| 합친 코드가 모두 사용자에게 묻는다고 했으나 '전부 추측인 plan'은 현재 세션이 근거를 보강하는 처리였다 | consistency 1 | 아니오 |
| 대체 목록 밖 문장이 옛 코드 이름(`review-red` 등)을 쓴다 | consistency 3 | 아니오 |
| 「재개할 수 없을 때」의 ledger 입력과 「문서 수명」의 '리포트 없이 재개'를 대체한다고 적지 않았다 | consistency 5·6 | 아니오 |
| 리포트 스키마에 `메시지 기록` 절이 없다 | consistency 7 | 아니오 |
| '판단 시점이 spec 승인 뒤에만 있었다'가 「2026-10-10 개정」 「판단 시점」의 두 시점과 맞지 않는다 | consistency 8 | 아니오 |
| 계약 표 면제 기준을 NP-bond-agg 이름으로 적어 「적용 범위」의 시점 기준과 다르다 | consistency 9 | 아니오 |
| 「계약 표」 절의 '스킬 「측정」에 30건 비교' 문장이 대체 목록에 없다 | consistency 10, grounding 4 | 예 |
| `TaskStop`과 `CANCEL`·`CANCELED` 흐름의 관계가 없다 | consistency 11 | 아니오 |
| `START`·`RESTART`가 하향 메시지에 드는지 밝히지 않았다 | consistency 12 | 아니오 |
| 구현 주체를 여러 이름으로 부른다 | consistency 13, fit 4 | 예 |
| 30건이 대응표 합계(33, C10·C11 제외 31)와 맞지 않고 무엇을 뺐는지 적지 않았다 | grounding 1 | 아니오 |
| 4차 A9 를 공용 설정 분할 규칙에 대응한다고 한 근거가 없다 | grounding 2 | 아니오 |
| JSON 을 고르지 않은 이유 중 '사람이 읽기 어렵다'를 빠뜨렸다 | grounding 3 | 아니오 |
| '현재 세션'을 검진 요약을 전달한 세션에도 썼다 | fit 3 | 아니오 |
| 문체: 'A가 아니라 B' 반복, 연결어미 쉼표 둘, '중간 메시지', '판단'의 두 뜻, 주체 빠짐, 개수 예고, 수식어 중첩, 문장 중간 관형절, 불릿 여러 문장과 말끝, 표 칸 시제, '것', 번호 라벨, 한 문장 여러 개념 | fit 1·2·5~24 | 아니오 |

## 커버리지 공백

`aggregating-lenses`가 표시할 공백은 없다. 배정된 렌즈 넷이 모두 결과를 돌려주었고 `principles_applied`가 비지 않았다.
