# nested-orchestration 메시지 형식 반영 plan 리뷰 기록(2026-10-11)

대상은 `docs/superpowers/plans/2026-10-11-message-schema.md`(커밋 8668209)이고, 짝 문서는 `docs/superpowers/specs/2026-10-09-nested-orchestration-large-dev-design.md`의 「2026-10-11 개정 — 메시지 형식」 절이다. 대상이 `docs/superpowers/plans` 아래에 있으므로 경로로 plan 이라 판정했다. 렌즈 넷(grounding, consistency, adversarial, fit)을 대상 하나에 한 번씩 실행했다. 렌즈를 한 번씩만 실행했다. plan 에는 선행연구 렌즈를 제안하지 않는다(review-specs).

## 합친 지적 목록

| 지적 | 렌즈 원본 | 공동 |
|---|---|---|
| FAIL 개수 기대값이 요약 줄과 FAILED 를 포함한 PASS 줄까지 세어 실제와 다르다 | grounding 1, consistency 2, adversarial A1 | 예 |
| 「공용 파일」 둘째 문단의 `BLOCKED`로 가 남아 옛 문구 grep 이 성립하지 않는다 | grounding 2, consistency 1, adversarial A2 | 예 |
| '테스트 결과는 리포트에만'과 테스트 절 없는 리포트 스키마가 모순이다(spec 에서 옮겨 옴) | grounding 3, adversarial A8 | 예 |
| 검증 의존 대기 뒤 BASE-UPDATED 조건이 반영되지 않았다 | grounding 4, consistency 6 | 예 |
| 8번 블록 교체가 「멈추는 기준」의 사유와 상태 값을 넣는 지시까지 지운다 | consistency 3, adversarial A3 | 예 |
| 시험 병합 전 git log 확인이 「결정 기록」 커밋에도 반응해 보낼 메시지를 정하지 못한다(spec 에도 원인) | adversarial A4 | 아니오 |
| Task 1 커밋이 FAIL=3 상태로 남아 저장소 계약 FAIL=0 을 위반한다 | adversarial A5 | 아니오 |
| 옛 문구 grep 이 '(`BLOCKED`)' 형태를 잡지 못한다 | adversarial A6 | 아니오 |
| Review Focus 가 주장한 Questions: 확인 명령이 없다 | adversarial A7 | 아니오 |
| 찾기 문자열 일부가 생략 기호와 백슬래시 이스케이프 때문에 원문과 일치하지 않는다 | adversarial A9 | 아니오 |
| 리포트 절을 백틱과 「」 두 표기로 가리키고 196행은 '예' 칸을 언급하지 않는다 | consistency 4 | 아니오 |
| '확정 예정' 대상(열거값 포함)과 `확정한 계약 의미` 형식이 맞지 않는다(spec 에도 같은 형태) | consistency 5 | 아니오 |
| 「공용 파일」 첫 문단의 '끝난 뒤'가 셋째 문단의 새 조건과 다르다 | consistency 7 | 아니오 |
| 새 절의 '머리줄·상향 메시지·하향 메시지·사유 코드'가 「용어」 표에 없다 | fit 8 | 아니오 |
| 문체: 표 열 말끝 혼용, 여러 문장 불릿, 중간 관형절, 수식어 중첩, 주체 생략, 한 문장 두 개념, 개수로 가리킴 | fit 1~7, 9 | 아니오 |

## 커버리지 공백

네 렌즈 모두 결과를 돌려주었다. grounding 과 consistency 렌즈는 plan 이 인용한 옛 문장이 모두 현재 SKILL.md 에 있음을 확인했다.
