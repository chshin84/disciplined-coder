# 콘솔 답변 교정 규칙 파일 설계 리뷰

대상은 `docs/superpowers/specs/2026-11-02-reply-edit-rules-design.md` 다. 경로가 `specs` 아래이므로 spec 으로 판정했다. 렌즈를 한 번씩만 실행했다. 렌즈는 `lens-grounding`(`spec`), `lens-consistency`(`spec`), `lens-adversarial`(`design`), `lens-fit`(`auto`)이고 원본은 같은 이름의 폴더에 있다.

## 선행연구 스킬 판정

선행연구 스킬은 제안하지 않았다. 이 spec 은 이미 시험 중인 mod 의 답변 교정을 규칙 파일로 정리한다. 되는지는 Haiku 를 직접 호출하는 시험으로 바로 확인할 수 있어, 외부 사례를 찾는 비용을 들일 이유가 없다고 메인 세션이 판단했다.

## 둘 이상의 렌즈가 함께 지적한 항목

- 원본에 없는 `NUM-PRONOUN` 과 "ID 가 원본에 모두 있다"는 검사의 상충(grounding, consistency, fit)
- `banned` 의 `word` 하나와 낱말이 여러 개인 금지어 표 행의 불일치(모든 렌즈)
- 개수 표현만 삭제한다는 결정과 경로·식별자 삭제까지 허용하는 검사의 상충(grounding, consistency, adversarial)
- `STATUS-FIRST` 의 '줄여라'와 삭제 제한의 상충(grounding, consistency)
- `SUBJECT-OBJECT` 등 조항 본문과 내용 추가 금지의 상충(grounding, consistency, adversarial)
- `49건` 삭제 시 `COUNT-EARNS` 제외 규칙과 필수 사례·조건 진행 규칙의 상충(grounding, consistency, adversarial)
- `cases.json` 칸으로 필수 사례를 판정할 수 없는 공백(모든 렌즈)
- 2회 호출을 표현할 칸이 계약에 없는 공백(consistency, adversarial)
- 「표로 적을 수 없는 규칙」의 다른 불릿을 처분하지 않은 공백(grounding, consistency, adversarial)
- 시험 원문을 받는 단계와 결과를 돌려받는 경로의 공백(grounding, consistency, adversarial)
- 이 호출이 `review-llm-calls` 표의 '둘 다인 출력'에 해당한다는 불일치(grounding, consistency)

## 커버리지 공백

배정한 렌즈 네 개가 모두 결과를 돌려주었고 `principles_applied` 도 모두 채워졌다. 의미 보존은 어느 렌즈도 해결 방법을 내지 못했다. `lens-adversarial` 이 코드로 없앨 수 없는 위험으로 지적했다.

## 걸러 낸 지적

- `lens-grounding` 의 "시험 원문을 reader-docs-tone 진행 보고로 특정한 근거가 없다"는 지적을 걸렀다. `claude-mods-bb` 의 인계 메시지에 "시험 원문은 사용자가 이 세션에서 가진 reader-docs-tone 진행 보고"라고 적혀 있다. 호출 프롬프트의 요지에서 이 낱말이 빠져 렌즈가 대조하지 못했다.

`lens-grounding` 이 notes 에 남긴 확인 요청은 메인 세션이 대화와 대조했다. 구조·소유·의존·조항 분류는 사용자가 "응", "진행해"로 확정한 제안과 같다.
