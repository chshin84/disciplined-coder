# 선행연구 에이전트 agents plan 리뷰

2026-10-18에 agents 구현 서브 세션이 plan `docs/superpowers/plans/2026-10-18-prior-art-agent-agents.md`를 review-specs 절차로 리뷰했다. 렌즈 원본은 같은 이름의 폴더에 있다.

## 차수 개요

대상은 plan 하나이고, 짝 문서는 하부 명세 `docs/superpowers/specs/2026-10-18-prior-art-agent-specagents-design.md`다. 실행한 렌즈는 `lens-grounding`, `lens-consistency`, `lens-adversarial`, `lens-fit`이며, 렌즈를 한 번씩만 실행했다. 대상은 `docs/superpowers/plans/` 아래 파일이라 plan 으로 판정했고, plan 이므로 선행연구는 제안하지 않았다. 서브 세션은 사용자에게 묻지 못하며 선행연구를 실행하지 않는다는 사정도 함께 적용되었다.

## 합친 지적

아래 목록은 렌즈별 지적을 합친 것이다. 괄호는 그 지적을 잡은 렌즈다.

- **Task 2 커밋의 소유 표 실패** — Task 2 가 `review-specs` 137행 절 제목을 바꾸는 시점에 `skills/lens-prior-art/SKILL.md:40`이 옛 절 이름을 소유자로 부르고 있어, 「소유 표」의 '소유자로 불리는 절이 스스로 선언한다' 단언이 실패한다(consistency, adversarial).
- **Task 5 Step 2 의 기대 FAIL 구성** — 훅 파일이 없으면 빈 객체 입력과 빈 입력 단언도 FAIL 하는데, Expected 는 알림 단언과 연결 단언만 센다(grounding, consistency, adversarial, fit).
- **Task 6 Step 4 의 남는 줄 목록** — `skills/audit-repo-docs/SKILL.md:16`과 Task 2 가 고칠 `review-docs` 34·50행의 '필요할 때 렌즈'가 기대 목록에 없다(grounding, consistency).
- **침묵·끄기 단언의 항진** — 출력이 비었는지만 보고 종료 코드를 보지 않아 훅이 없어도 PASS 한다(adversarial).
- **도구 단언의 범위** — `grep -qx`가 파일 전체를 보아 frontmatter 밖의 같은 줄로도 PASS 한다(adversarial).
- **옮긴 문장 대조의 명령과 중단 조건** — Task 3 Step 1 에 diff 명령, 대조 단위, 허용 밖 차이에서 멈추는 조건, 고칠 파일이 없다(adversarial, fit).
- **블록 비교 명령** — Task 6 Step 3 에 실행할 명령이 없고, Step 5 의 커밋 지시가 Files 칸과 부딪힌다(adversarial, fit).
- **실패 확인 방법의 범위** — 전역 제약이 묶음 FAIL 수 세기를 새 묶음으로 좁혔고 Task 2·4 가 다른 방법으로 확인한다(consistency).
- **review-specs 137-138행 처리** — plan 의 '제목만'이 하부 명세의 둘째 문장 교체와 부딪힌다(consistency).
- **정의 본문 요구의 누락** — 하부 명세 124-134행의 공통 단락·모드 단락 요구를 Task 1 Step 4·5 가 가리키지 않는다(consistency).
- **옮기기 제외 규칙의 누락** — 하부 명세 47행의 리서치 근거·리뷰 경위·빌더 지시 제외와 출처 한 문장 규칙이 Task 1 Step 3 에 없다(consistency).
- **64KB 측정의 범위** — 하부 명세에 없는 측정이다(consistency). 명령이 구체적이지 않다(adversarial).
- **prompt 값이 빈 입력** — Review Focus 가 고정한다고 적은 조건에 단언이 없다(grounding).
- **근거 문서 문장의 소유자 이름** — `domain-discipline.md`에 넣을 「발동과 기록」 문장은 줄바꿈 때문에 소유자 이름과 다른 줄에 놓일 수 있다(grounding).
- **이름 없는 렌즈 개수 검사의 범위** — 그 검사는 새 스킬과 정의를 보지 않는다(grounding).
- **명세 경로와 커밋 꼬리줄** — 태스크 본문이 두 명세를 약칭으로만 부르고 커밋 블록에 꼬리줄이 없다(adversarial).
- **문체** — Goal 과 Review Focus 의 주체, Expected 의 명사 조각, 개수로 가리킨 목록, 여러 문장 불릿, 한 문장의 여러 개념, 문장 중간 관형절, '리포트'와 '보고'의 혼용, '컨트롤러'·'넛지'의 풀이 누락(fit).

## 커버리지 공백

배정된 렌즈가 모두 JSON 을 돌려주었다. `lens-consistency`는 참조 처리 목록의 모든 행이 태스크 하나에만 배정되었다고 확인했고, `lens-grounding`은 plan 의 줄 번호와 변수가 실제 파일과 맞는다고 확인했다. 실행해야만 확정되는 사항(넛지 픽스처의 eval 통과, `claude plugin validate`의 `maxTurns` 수용)은 렌즈가 읽기 전용이라 실행하지 않았다.

## 선행연구 판정

선행연구는 제안하지 않았다. 대상이 plan 이고, 서브 세션은 사용자에게 묻지 못한다.
