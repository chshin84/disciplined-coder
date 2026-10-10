# nested-orchestration 큰 개발 분할 plan 리뷰 기록

2026-10-09에 `docs/superpowers/plans/2026-10-09-nested-orchestration-large-dev.md`를 렌즈 네 개로 리뷰했다. 대상은 `docs/superpowers/plans/` 아래 파일이라 plan으로 판정했고, `lens-consistency`에는 짝 spec(`docs/superpowers/specs/2026-10-09-nested-orchestration-large-dev-design.md`)을 함께 주었다. 렌즈별 원본은 같은 이름의 폴더에 있다.

## 실행한 렌즈

렌즈를 한 번씩만 실행했다. plan이라 `lens-prior-art`는 제안하지 않았다.

| 렌즈 | 지적 수 | 원본 |
|---|---|---|
| `lens-adversarial` | 12 | `lens-adversarial-1.json` |
| `lens-consistency` | 8 | `lens-consistency-1.json` |
| `lens-grounding` | 10 | `lens-grounding-1.json` |
| `lens-fit` | 12 | `lens-fit-1.json` |

## 합친 지적

겹치는 지적끼리 합쳤다. 괄호는 함께 잡은 렌즈다. 호출자가 근거 줄을 열어 확인했고, 근거가 서지 않아 거른 지적은 없다. 진행 위치와 마커 읽기 두 지적은 호출자가 스크래치 저장소에서 재현했다. 커밋이 없는 `ws/x/new`가 `git branch --merged dev/x`에 나왔고, 통합 브랜치 체크아웃에서 `tail`은 ws 브랜치 파일을 열지 못했으며 `git show ws/x/b:<경로>`는 읽었다.

**실행 경로와 분기**

- **작업 디렉터리:** Task 2~7의 명령 블록 대부분에 워크트리로 가는 `cd`가 없어, 서브에이전트가 실행하면 main 체크아웃에서 검사하고 커밋한다(adversarial).
- **Task 0 이동 목록:** 미추적 `agents.md`가 있어 기대 출력과 다르고, plan 리뷰 기록이 이동 목록에 없다(adversarial, grounding).
- **워크트리 생성 절차:** `using-git-worktrees`의 동의·네이티브 도구·ignore 확인을 거치지 않는다(grounding).
- **불채택 분기:** 원칙 문안을 채택하지 않고 진행할 때 Task 2와 Task 7을 어떻게 할지 없다(adversarial, consistency).
- **측정 문단:** 과제 구성을 다섯 과제로 고정해 추가 실행 때 틀린다(adversarial, consistency, grounding).
- **클린룸 조건의 오염:** 서브에이전트에 옛 description이 든 스킬 목록이 실리고, 전역 CLAUDE.md의 원칙이 실리는지 확인하는 단계가 없다(adversarial, grounding, consistency의 notes).
- **과제 수의 근거:** CLAUDE.md의 3+2와 다른 5+2의 근거가 없다(grounding).
- **행 번호 이동:** Task 3의 삽입으로 뒤 행 번호가 밀리고, 867~871행 표기는 처음부터 871~872행이다(adversarial, consistency, grounding).
- **스크래치 경로:** Task 6 Step 2가 이 세션의 스크래치 경로를 박아 둔다(adversarial).

**스킬 교체본의 동작**

- **진행 위치 판정:** 커밋이 없는 ws 브랜치도 `--merged`로 나와 끝난 워크스트림으로 판정된다(adversarial, 호출자 재현).
- **마커를 읽는 체크아웃:** 현재 세션 체크아웃에는 ws 브랜치 파일이 없어 `tail`이 실패한다(adversarial, grounding의 notes, 호출자 재현).
- **워커의 작업 디렉터리:** `isolation:'worktree'`를 쓰지 않으면 워커에 워크트리 경로를 넘기라는 지시가 필요한데 없다(adversarial).
- **자기 문서 패턴의 접두어:** `*-<개발>-<id>*`는 `api`가 `apigw`의 문서와 맞는다(adversarial).
- **escalated 마커 시나리오:** Review Focus가 고정한다고 적은 escalated 문서를 시나리오 D가 다루지 않는다(consistency, grounding).
- **새 파일 추가 시나리오:** 시나리오 B는 기존 파일 수정만 시험한다(consistency).
- **의미 없는 검사:** "되돌림 커밋 없음"은 실패할 수 없고, "main 기준 두 점 diff"는 스킬 명령 밖이다(adversarial).
- **절 순서:** spec은 「큰 개발 분할」을 「라우팅」 앞에 두라고 했다(consistency, grounding).
- **최종 브랜치 리뷰:** 현행 스킬의 최종 브랜치 리뷰가 교체본에서 빠졌다(grounding).
- **「제안」 수집:** 현재 세션이 「제안」을 모아 보이는 단계가 없다(consistency).
- **BLOCKED의 내용:** 공용 파일 변경 때 "바꿀 내용을 적고"가 빠졌다(consistency).

**문체(fit)**

- 원칙 문안의 쉼표 둘과 '말라'·'마라' 혼용, description의 쉼표 둘, 명세·spec·스펙과 plan·계획 혼용, 가드레일 불릿과 템플릿 4번의 긴 문장 묶음, '호출자 넷'과 '여섯 블록'의 개수 표기, SDD 미풀이, 주체 생략, 문장 중간 관형절, '드릴인' 음차.

## 커버리지 공백

네 렌즈 모두 결과를 돌려주었고 `principles_applied`가 비어 있지 않았다. 렌즈가 실측이 필요하다고 남긴 항목은 셋이다. 서브에이전트의 Bash 작업 디렉터리가 호출마다 돌아가는지, Agent 서브에이전트에 전역 CLAUDE.md가 실리는지, 마커가 붙은 spec을 고칠 때 Stop 게이트가 다시 발동하는지다.
