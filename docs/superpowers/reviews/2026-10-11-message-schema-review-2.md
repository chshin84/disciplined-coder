# nested-orchestration 메시지 형식 개정 리뷰 기록(2026-10-11, 2차)

대상은 1차 리뷰를 반영하고 main(bd31f57) 위로 옮긴 `docs/superpowers/specs/2026-10-09-nested-orchestration-large-dev-design.md`의 「2026-10-11 개정 — 메시지 형식」 절(커밋 bcd64b4)이다. 짝 문서는 `skills/nested-orchestration/SKILL.md`와 같은 spec 의 「2026-10-11 개정 — 묶는 단위」 절이다. 대상이 `docs/superpowers/specs` 아래에 있으므로 경로로 spec 이라 판정했다. 사용자가 다시 리뷰를 골라 렌즈 넷(grounding, consistency, adversarial, fit)을 대상 하나에 한 번씩 실행했다. 렌즈를 한 번씩만 실행했다. 선행연구 렌즈는 1차 기록과 같은 이유로 제안하지 않았다.

## 합친 지적 목록

| 지적 | 렌즈 원본 | 공동 |
|---|---|---|
| 하향 메시지 뒤의 다음 응답에 FAILED·BLOCKED 가 빠져 고치지 못한 서브 세션이 성공 상태를 보내게 된다 | adversarial A5, consistency 2 | 예 |
| 「현재 세션」이 오케스트레이션 세션과 이 spec 을 쓴 세션 두 대상을 가리킨다 | fit 1 | 아니오 |
| 첫 문단은 다른 세션 개정에 대해 메시지 이름만 정한다고 하나 반영 위치는 계약 표 규칙도 정한다 | grounding 5, consistency 4 | 예 |
| 스스로 판정한 모호함을 읽는 단계에 하부 명세 승인이 빠졌다 | grounding 2, consistency 6 | 예 |
| sdd-stop 의 근거 보강 처리가 새 규칙 목록에 없다 | grounding 1 | 아니오 |
| A2A 성격 규정의 근거가 저장된 원본에 없다 | grounding 3 | 아니오 |
| MAST 에 대한 저장소 두 기록의 반대 읽기를 spec 이 언급하지 않는다 | grounding 4 | 아니오 |
| 의존성 추가가 검증 의존과 맞물려 서로 기다리고, '끝났으면'의 뜻이 정해지지 않았다 | adversarial A1, consistency notes | 예 |
| 복수 사유를 모두 처리한 뒤 답하면 짧은 사유의 답이 긴 사유를 기다린다 | adversarial A2 | 아니오 |
| Questions: 를 BLOCKED 응답 수로 세면 실제 질문 수와 다르다 | adversarial A3, consistency notes | 예 |
| escalated 인데 결정 기록에 답이 없는 상태를 REVISE 로 보내지만 서브 세션은 고칠 수 없다 | adversarial A4 | 아니오 |
| FAILED 의 '끝낼 수 없다' 기준이 없고 환경 오류 예시가 설명과 맞지 않는다 | adversarial A6 | 아니오 |
| merge-base 확인도 맥락의 커밋에 기대어 압축 뒤 누락이 남는다 | adversarial A7 | 아니오 |
| 서브 세션이 읽을 SKILL.md 경로가 없어 플러그인 갱신 때 버전이 달라진다 | adversarial A8 | 아니오 |
| Format-Deviations: 가 병합 커밋에만 남아 생존 편향이 생기고 이탈 응답의 처리가 없다 | adversarial A9 | 아니오 |
| '확정 예정' 예외가 형식 칸의 열거값에는 적용되지 않는다 | adversarial A10 | 아니오 |
| 공유 가정 충돌을 contract-change 로 보내지만 가정에는 계약 행이 없다 | adversarial A11 | 아니오 |
| 계약 행이 없는 큰 명세 본문 변경의 수신자와 필드가 없다 | consistency 1 | 아니오 |
| CANCEL 이 미커밋 변경을 버리는지 남기는지 두 문장이 다르다 | consistency 3 | 아니오 |
| '확정 예정' 칸을 채울 때 무엇을 보는지 정해지지 않았다 | consistency 5 | 아니오 |
| 디스패치 템플릿의 수정 허용 경로와 plan과 구현 항목이 반영 대상에 없다 | consistency 7 | 아니오 |
| 복수 사유, FAILED·CANCELED 처리, REVISE 상황을 둘 절이 반영 위치에 없다 | consistency 8 | 아니오 |
| 교집합 검사 실패에 보낼 메시지가 없다 | consistency 9 | 아니오 |
| 이미 병합된 워크스트림의 통합 확인 재실행 실패에는 `시험 병합` 필드 값이 없다 | consistency 10 | 아니오 |
| 문체: 개수 예고, 여러 문장 불릿, 네 문장 넘는 단락, MAST 풀이 없음, 파일·메시지를 주체로 씀, 표 셀 형식 혼용, 관형절 삽입, '보류 메시지' 새 이름 | fit 2~9 | 아니오 |

## 커버리지 공백

네 렌즈 모두 결과를 돌려주었다. consistency 렌즈는 1차 consistency 지적 대부분이 해소되었다고 적었다.
