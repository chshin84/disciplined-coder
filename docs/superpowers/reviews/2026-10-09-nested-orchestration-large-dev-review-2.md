# nested-orchestration 큰 개발 분할 spec 리뷰 기록 (2차)

2026-10-09에 1차 리뷰를 반영한 `docs/superpowers/specs/2026-10-09-nested-orchestration-large-dev-design.md`를 렌즈 네 개로 다시 리뷰했다. 사용자가 다시 리뷰를 고르고 PREP을 새로 채웠으며, 렌즈에 1차 기록은 넘기지 않았다. 렌즈별 원본은 같은 이름의 폴더에 있다.

## 실행한 렌즈

렌즈를 한 번씩만 실행했다.

| 렌즈 | 지적 수 | 원본 |
|---|---|---|
| `lens-adversarial` | 11 | `lens-adversarial-1.json` |
| `lens-consistency` | 18 | `lens-consistency-1.json` |
| `lens-grounding` | 14 | `lens-grounding-1.json` |
| `lens-fit` | 11 | `lens-fit-1.json` |

`lens-prior-art`는 1차와 같은 이유로 제안하지 않았다.

## 합친 지적

겹치는 지적끼리 합쳤다. 괄호는 함께 잡은 렌즈다. 호출자가 근거 줄을 열어 확인했고, 근거가 서지 않아 거른 지적은 없다. git 동작은 `revert-a-faulty-merge.adoc` 55~57행으로 확인했다.

**병합과 진행 위치**

- **되돌린 병합의 재병합:** `git revert -m 1`로 되돌린 병합을 고쳐 다시 병합하면 처음 병합의 변경이 빠진다(adversarial, consistency의 notes).
- **되돌림과 진행 위치:** 되돌린 브랜치도 병합 이력이 남아 끝난 워크스트림으로 판정된다(adversarial).
- **승인 대기와 진행 중의 구분:** 두 상태가 git에서 같게 보인다(adversarial).
- **리포트 경로 소실:** 대체 경로와 `escalated` 해소 확인이 세션마다 다른 스크래치의 리포트에 기댄다(adversarial).
- **브랜치 생성 주체:** `ws/...` 브랜치를 누가 어느 커밋에서 만드는지 없다(adversarial).
- **공용 파일 전파:** 통합 브랜치의 공용 파일·계약 변경을 워크스트림 브랜치가 받는 절차가 없다(adversarial, consistency).
- **허용 경로의 문서 경로:** 하부 명세·plan·리뷰 기록 경로가 허용 경로에 없어 모든 워크스트림이 범위 대조에 걸린다(consistency, grounding).
- **이름 변경 출력:** `--name-only`는 옮긴 파일의 새 이름만 낸다(adversarial).
- **pathspec 겹침:** 교집합 검사를 빼면 겹치는 패턴을 잡을 장치가 없고, 교집합 검사는 스파이크에서 검증된 가드였다(adversarial).
- **실패 차수 규칙:** 되돌림 커밋으로 세면 병합 전 실패는 빠지고 계약 원인은 들어가며, 관찰되지 않은 상황을 위한 규칙이고 SDD의 상한·차단기는 옮기지 않았다(adversarial, consistency).

**트리거와 원칙**

- **불채택 때의 상태:** 원칙 문안이 채택되지 않아도 스킬 변경은 들어가 둘이 반대를 지시하고, 용어 grep과 '태스크 다섯' 교체도 채택 여부와 묶이지 않았다(adversarial, consistency).
- **태스크 수 조건의 시점:** 태스크는 plan을 써야 생기므로 brainstorming 시점에는 셀 수 없다(adversarial).
- **클린룸 과제 수:** 처음 과제가 다섯인데 "둘을 더 실행해 다섯 과제 합계"로 판정한다(consistency, grounding).
- **머리 문장과 영문 표제 문안:** 새 문안이 없다(consistency).

**문서와 상태**

- **결정 기록의 타입:** 수명 표에 없는 타입이고, 코드에서 도출할 수 있는 공개 인터페이스를 손으로 옮기며, spec 게이트 경로 밖이다(consistency, grounding).
- **완료 상태 이름:** `AWAITING_APPROVAL`과 `BLOCKED`만 있다(consistency).
- **멈추는 기준과 현행 사유:** 현행 "리스크상 필요한 차원을 아무도 안 봤을 때"의 처분이 없다(consistency).
- **비목표 문장:** 「한계」의 "인플라이트 상태는 대화 상태로만"이 새 규칙과 충돌하는데 고칠 대상에 없다(consistency, grounding).
- **2026-07-05 superseded 범위:** 스파이크 결과만 옮기고 R4(Workflow 배제)·R9(관측성)·비목표의 판단과 3층 중첩(SC2) 결과를 옮기지 않았다(consistency, grounding).
- **계약 코드 plan의 사용자 검토:** HARD-GATE가 계약 코드 plan 검토를 요구하는데 사용자 검토 목록에 없다(consistency).
- **명세 분량·제안 규칙:** 근거로 든 「명세 분량」이 스킬로 옮겨지지 않고, 지시문의 「제안」 규칙의 처분도 없다(consistency, grounding).
- **근거 문장의 위치:** 「근거와 한계」의 문장을 스킬 어느 절에 넣는지 없다(consistency).
- **가정 확인의 위치:** 가정 확인 결과를 조항 ID 체계인 `domain-discipline.md`에 적게 했다(consistency).

**검사와 확인 방법**

- **영향받는 기존 검사:** `test_docs_drift.sh` 284~289행(소유자 포인터)과 867~871행(런타임 중립)이 빠졌다(grounding).
- **grep 대상:** `domain-discipline.md`와 `test_docs_drift.sh`가 grep 대상에 없다(consistency).
- **인용 갱신:** `domain-discipline.md` 358~359행의 현행 문구 인용이 낡는다(grounding).

**근거 인용**

- **출처 행 번호:** CodeTeam·Contract-Coding은 1263행이 아니라 1386행이다(grounding).
- **조건 혼동:** '연산량 동일'은 Tran·Kiela의 조건이고 그 근거는 대화에서 버렸으며, '6종 중 5종'은 BenchAgent의 정규화 조건이다(grounding).
- **10분의 1:** `dispatching-lenses`는 이 배수를 측정값이 아닌 정책값으로 적는다(grounding).
- **비교 연구 부재:** 같은 에이전트 재개와 새 에이전트에 파일을 넘기는 방식을 비교한 연구가 없다는 한계(1332행)가 빠졌다(grounding).
- **gm-dashboard 사례:** gm-dashboard는 의존성 파일과 잠금 파일을 워크스트림에 맡겼다(grounding).
- **'워커' 용어:** 2026-07-05 설계는 '워커'를 2층 용어로 보고 3층에 쓰지 않기로 정했다(grounding).

**문체(fit)**

- `A가 아니라 B` 대구 세 번, 연결어미 뒤 쉼표 둘, 수식어 겹침, 판단 주체, 표·목록의 말끝, 여러 문장 불릿, 다섯·여섯 문장 단락, 본문의 '메인 세션', 풀지 않은 용어(클린룸 시험, 🔴), 개수로 가리킨 렌즈.

## 커버리지 공백

네 렌즈 모두 결과를 돌려주었고 `principles_applied`가 비어 있지 않았다. 렌즈가 실측이 필요하다고 남긴 항목은 둘이다. `Agent`의 `isolation:'worktree'`가 만드는 브랜치 이름과 기준 커밋, 스크래치 디렉터리가 세션마다 달라지는지다.
