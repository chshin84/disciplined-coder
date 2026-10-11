# 공유 항목 표와 검증 의존 구현 계획 리뷰 기록

대상은 `docs/superpowers/plans/2026-10-11-shared-definition-grouping.md`(브랜치 `shared-definition-grouping`, 커밋 23d4153)다. 현재 세션은 경로가 `docs/superpowers/plans` 아래이므로 plan 으로 판정했다. 실행한 렌즈는 `lens-grounding`, `lens-consistency`, `lens-adversarial`, `lens-fit` 이고 원본은 같은 이름의 폴더에 줄여 옮겼다.

렌즈를 한 번씩만 실행했다.

현재 세션은 `lens-prior-art`를 제안하지 않았다. 대상이 plan 이기 때문이다.

## 합친 지적 목록

| 지적 | 렌즈 원본 | 공동 |
|---|---|---|
| SDD 를 권장하지만 Task 1·3·4 는 메시지·서브에이전트·사용자 질문이 필요해 현재 세션이 직접 실행해야 한다 | adversarial 1 | 아니오 |
| 측정·기대 분할 서브에이전트가 저장소 파일과 스킬을 읽어 정답이나 새 규칙을 알 수 있다 | adversarial 2 | 아니오 |
| 측정에 넘기는 규칙 문안에 2026-10-10 측정 서술이 들어가 주문 처리의 답을 알려 준다 | adversarial 3 | 아니오 |
| 기대 분할 프롬프트가 새 규칙의 판정 질문을 바꿔 쓴 문장이라 측정이 일관 적용을 측정한다 | adversarial 4 | 아니오 |
| score.py 가 펜스·산문·id 오류에 멈추거나 형식 위반을 판정 실패로 세고, 실행 누락이 있어도 ADOPT 를 내며 재실행 규칙이 없다 | adversarial 5·6, consistency 4, fit 10 | 예 |
| result.md 와 943행 출력이 Windows 표준출력 cp949 로 깨진다 | grounding 1·2 | 아니오 |
| 943행 runner 설명에 `npb.engine`이 있어 금지어 검사가 실패하고, '넷'은 거짓 양성을 낸다 | grounding 3, adversarial 11 | 예 |
| 새 규칙과 측정 기록을 한 커밋에 넣어 미달 시 되돌릴 경로가 없고, 재측정 파일 규칙이 없어 커밋된 기록을 덮어쓰게 된다 | adversarial 7·8, consistency 3 | 예 |
| 측정 문안과 배포 문안을 대조하는 단계가 없고, Task 6 은 grep 확인을 다시 실행하지 않는다 | adversarial 9, consistency notes | 예 |
| Task 1 시작 조건이 메시지뿐이고, main 에 4c 병합이 이미 있어 spec 충돌이 확정이다 | adversarial 10, grounding 4 | 예 |
| spec 은 「가드레일」의 시험 병합을 이 세션 수정 대상으로 적어 plan 의 금지 범위와 다르다 | consistency 2, grounding notes | 예 |
| 합침 행에서 떼어낸 접근 절차 계약이 계약 표로 가는 경로가 없다(spec 도 같다) | consistency 1 | 아니오 |
| 「검증 의존 대기」가 '진행 위치는 지금처럼 도출된다'고 적지만 대기 중인 워크스트림은 진행 중으로 분류된다 | consistency 5 | 아니오 |
| Task 6 측정 문장 삽입 위치가 정해지지 않았고 문안이나 틀이 없다 | consistency 6, fit 9 | 예 |
| 스킬 문안이 사용자가 고정한 의미를 확인한다는 spec 문장을 빠뜨렸다 | grounding 6 | 아니오 |
| '통합 확인의 원인'에서 실패 조건이 빠졌다 | grounding 5, fit 6, consistency notes | 예 |
| 'NP-bond-agg desc 에 합침을 추론할 정보가 있는지' 확인하지 않았다 | adversarial notes | 아니오 |
| 문체: 의존 순서 줄 말끝, '시작 의존'과 '의존 순서' 두 이름, 수식어 겹침, 문서·개념을 주체로 씀, 개수 예고, 주어 생략, 판정 오차 용어 미풀이, Task 1 Files 형식, grep 기대 위치 누락 | fit 1~8·11·12, grounding 7 | 아니오 |

## 커버리지 공백

`lens-adversarial`은 NP-bond-agg 기록 943행을 분류기 거부로 열지 못했고, `lens-grounding`이 열어 표 구조와 `npb.engine` 문구를 확인했다. 4c 의 main 병합 문안은 `lens-grounding`이 main 에서, `lens-adversarial`이 4c 브랜치에서 각각 대조했다.
