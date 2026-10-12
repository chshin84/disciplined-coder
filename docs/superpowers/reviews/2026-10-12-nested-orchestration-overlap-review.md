# nested-orchestration 하부 명세 대조 개정 리뷰 기록(2026-10-12)

대상은 `docs/superpowers/specs/2026-10-09-nested-orchestration-large-dev-design.md`의 「2026-10-12 개정 — 하부 명세 대조」 절이다. 현재 세션은 `lens-grounding`, `lens-consistency`, `lens-adversarial`, `lens-fit`을 대상 하나에 하나씩 실행했다. 렌즈를 한 번씩만 실행했다. 렌즈 원본은 같은 이름의 폴더에 있다.

## 선행연구 렌즈

이 개정은 하부 명세를 모아 겹침을 대조하고 공통 결정을 떼어내는 방식을 처음 시도하므로 발동 기준(해 본 적 없는 것)에 해당한다. 현재 세션이 제안했고 사용자가 통상으로 승인했다. 결과는 `2026-10-12-nested-orchestration-overlap-prior-art.md`에 따로 있다.

## 합친 지적

| 지적 | 잡은 렌즈 |
|---|---|
| 같은 저장소의 서로 독립된 큰 작업도 명명·오류 처리 결정이 부딪히는데 대조에서 뺐다 | grounding, consistency, adversarial |
| 시작 의존으로 늦게 디스패치되는 워크스트림은 대조를 거치지 않고, 결정 기록 일괄 반영 때문에 앞 워크스트림의 `확정한 결정`도 주입받지 못한다 | grounding, consistency, adversarial |
| 「구현 뒤 확정」과 시작 의존이 같은 관계(구현·조사 결과가 필요한 관계)를 다르게 처리하고 고르는 기준이 없다 | grounding, consistency |
| 「구현 뒤 확정」 소비자가 소유 쪽 구현·통합까지 승인 대기로 오래 살아 있어야 하고, 이 대기는 「기다림의 비용」에 없다 | adversarial |
| '확정 예정'을 의미 칸에만 적어 형식 칸 열거값이 빠졌다 | grounding, consistency |
| 합침 행에서 받기만 하는 사용 쪽의 경로를 다루지 않는다 | consistency |
| 대조 뒤 `REVISE`를 받은 서브 세션의 워크트리에 바뀐 계약이 없다(병합 지시가 `APPROVE`에만 있다) | grounding, consistency |
| 「REVISE 를 쓰는 상황」, 「이어 쓰기와 재개」, 「진행 위치」, `START` 행, 디스패치 템플릿, 스킬 첫 문단 포인터, `dispatching-lenses` 호출자 목록이 고칠 목록에 없다 | grounding, consistency, adversarial |
| 재시작한 현재 세션이 일부러 둔 승인 대기를 답하지 않은 메시지로 처리할 수 있다 | consistency, adversarial |
| 「승인 항목」을 어떻게 고치는지 적지 않아 공유 가정 전파가 남고, 대조 뒤 늦게 승인되는 하부 명세가 먼저 승인된 워크스트림에 왕복을 일으킨다 | consistency, adversarial |
| `lens-consistency`의 체크리스트에 '같은 결정을 같은 값으로 따로 정한 겹침'이 없어 렌즈를 주 경로로 두면 빈 결과가 나올 수 있다 | consistency, adversarial |
| 「검증하지 않은 가정」이 `lens-consistency`의 설계 목적(드리프트 = 같은 대상의 두 이름)을 반대로 적었다 | grounding |
| 호출을 계약 표의 같은 행으로 나누면 큰 명세가 못 본 쌍이 대조되지 않는다 | consistency, adversarial |
| 대조 장벽의 종료 조건(시작 워크스트림이 FAILED·CANCELED·접힘)이 없다 | adversarial |
| 공통 워크스트림 경로는 기존 워크스트림 하나를 제공자로 정하는 행으로 대신할 수 있다(크기 상한 없음) | adversarial |
| 태스크 다섯 문턱으로 겹침 처리를 나눈 근거가 사용자 결정인지 적혀 있지 않다 | grounding |
| 정의만 있는 겹침과 제공자 지정 겹침은 사용자 승인과 순환 재확인 없이 계약을 바꾼다 | consistency |
| 소유 쪽과 제공자의 하부 명세에 계약 표와 같은 값이 남아 개정 절의 SSOT 이유와 부딪친다 | consistency |
| 흐름 6단계가 "지금과 같다"고 적어 같은 절의 일괄 반영·구현 뒤 확정과 부딪친다 | grounding |
| n² 증가를 측정값처럼 적었다 | grounding |
| 감사가 제안한 최소안(제목 예외 확대)을 검토했는지 적지 않았다 | grounding |
| 직접 통신 기각 근거로 원 논문을 대조하지 않은 MAST 인용을 썼다 | grounding |
| 확인 방법이 일부 고칠 절을 보지 않고, 핸드오프에 '측정 목록'이 없으며 대기 길이 항목이 빠졌다 | grounding, consistency |
| 문체: 관형절 끼움, 판단 주체 누락, 다섯 문장 넘는 단락, SSOT 미풀이, 대구 | fit |

## 커버리지 공백

배정된 렌즈 넷이 모두 결과를 돌려주었다. 표시할 공백은 없다.
