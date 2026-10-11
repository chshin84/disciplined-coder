# nested-orchestration 메시지 형식 개정 리뷰 기록(2026-10-11)

대상은 `docs/superpowers/specs/2026-10-09-nested-orchestration-large-dev-design.md`의 「2026-10-11 개정 — 메시지 형식」 절(커밋 2498384)이고, 짝 문서는 `skills/nested-orchestration/SKILL.md`다. 대상이 `docs/superpowers/specs` 아래에 있으므로 경로로 spec 이라 판정했다. 렌즈 넷(grounding, consistency, adversarial, fit)을 대상 하나에 한 번씩 실행했다. 렌즈를 한 번씩만 실행했다. 선행연구 렌즈는 제안하지 않았다. 같은 날 사용자가 직접 요청한 선행연구 대조(`2026-10-11-contract-table-prior-art`)가 이 주제(분할·조율 프로토콜)를 이미 다뤘기 때문이다.

## 합친 지적 목록

| 지적 | 렌즈 원본 | 공동 |
|---|---|---|
| 소유 서브 세션에 의존성 추가를 요청하는 하향 메시지 종류가 없다 | grounding 3, consistency 3 | 예 |
| sdd-stop 처리에 '전부 추측인 plan'이 없고 '워크트리 밖'이 '외부'로 바뀌었다 | grounding 4, consistency 4, fit 2 | 예 |
| 리포트 '읽는 곳' 칸이 스킬에 없는 읽기(수정 범위 대조, 시험 병합 전 확인, 승인 항목의 명세 이탈, 마무리의 기능적 반영)를 가리킨다 | grounding 5, consistency 7 | 예 |
| 반영 위치에 「계약 코드」·「승인 항목」·「가드레일」·「흐름」이 없고 「공용 파일」·「측정」을 무엇으로 바꾸는지 없다 | grounding 6, consistency 8 | 예 |
| DONE·AWAITING_APPROVAL 필드와 리포트 절이 같은 사실을 두 곳에 둔다 | fit 3, adversarial A11, consistency notes | 예 |
| 계약 변경 채택 때 제공자에게 CONTRACT-CHANGED 를 보내지 않는다 | consistency 2, adversarial A10 | 예 |
| 수정 범위 대조 실패, 리뷰 마커 문제, 판정 번복, FAILED 뒤 재시도에 보낼 메시지가 없다(REVISE 의 범위) | consistency 5·6, adversarial A9, fit notes | 예 |
| 형식 이탈의 정의와 기록 위치(트레일러)가 없고 Questions 와 새 상태 값의 대응이 없다 | consistency 11, adversarial A12 | 예 |
| CANCEL 의 '워커를 멈추고'가 메시지는 멈춘 뒤에만 보낸다는 규칙과 맞지 않는다 | consistency 10, adversarial A7 | 예 |
| shared-file-change 의 큰 명세 변경 채택 때 CONTRACT-CHANGED 가 빠졌다 | consistency 1 | 아니오 |
| FAILED 가 「멈추는 기준」의 '아래 사유에서만'과 부딪힌다 | consistency 9 | 아니오 |
| FAILED 뒤 새 서브 세션에 원인과 시도한 것을 넘기는 규칙이 없다 | consistency 12 | 아니오 |
| MAST 귀속이 처방과 한계를 뒤바꿨다 | grounding 1 | 아니오 |
| 거절(REJECTED)을 뺀 처분 기록이 없다 | grounding 2 | 아니오 |
| 한 응답에 사유가 둘 이상일 때의 규칙이 없다 | adversarial A1 | 아니오 |
| 의존성 목록·잠금 파일이 shared-file-change 와 dependency-add 양쪽에 걸리고, 「멈추는 기준」에 두 코드의 불릿이 없다 | adversarial A2 | 아니오 |
| FAILED 의 '테스트 문제'가 계약 불일치까지 포함해 오분류된다 | adversarial A3 | 아니오 |
| 하향 표가 프롬프트에 들어가지 않고, '프롬프트만 받는다'는 이유가 템플릿의 dispatching-lenses 읽기와 상충한다 | adversarial A4 | 아니오 |
| 보류 중인 CONTRACT-CHANGED 가 git 에서 도출되지 않는다 | adversarial A5 | 아니오 |
| 한 서브 세션에 메시지 둘 이상을 보낼 때 묶음과 순서가 없다 | adversarial A6 | 아니오 |
| sdd-stop 거절에 CANCEL 을 쓰면 워크스트림 전체가 취소된다 | adversarial A8 | 아니오 |
| 문체: 머리줄 '사유'·'사유 코드' 혼용, 개수 예고, 절을 주체로 씀, 수식어 중첩, 템플릿 항목을 번호로 가리킴 | fit 1, 4~7 | 아니오 |

## 커버리지 공백

네 렌즈 모두 결과를 돌려주었다.
