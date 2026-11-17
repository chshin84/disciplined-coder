# v2 재건축 4~8단계 plan 다시 리뷰 (네 렌즈 재설계)

대상은 `docs/superpowers/plans/2026-11-17-v2-rebuild-stage4-8.md` 의 바뀐 절(「spec 과 다른 점」 리뷰 구조, Task 2 Step 3 (4), Task 3)이다. 렌즈는 `lens-adversarial`(`design`) 하나를 한 번 실행했다. 바뀐 절만 보는 다시 리뷰라 근거 렌즈는 실행하지 않았다. 선행연구는 실행하지 않았다(이미 하던 리뷰 절차의 재배치라 발동 기준 밖).

렌즈 원본 JSON 은 서브에이전트 보고로만 받았고 실행 기록에서 꺼내지 못해 폴더에 저장하지 못했다. 아래 표가 지적 14건 전부다. 1차 디펜스에서 기각한 지적은 0건이다.

| 지적 | source | 위치 | 처분 | 기각 근거 |
|---|---|---|---|---|
| Task 3 Interfaces 가 모든 렌즈를 적대 자세로 정해 대조 렌즈 드라이 원칙과 상충 | lens-adversarial | Task 3 Interfaces | 반영 | - |
| 옛 lens-visual 의 목적 기반 화면 판정이 대조 렌즈의 "다른 점만" 가드에 막혀 사라짐 | lens-adversarial | 리뷰 구조, Task 3 Files | 반영(화면 판정을 독자 렌즈로 옮김) | - |
| lens-fit 의 doc_type 칸이 옮겨 갈 곳 없음 | lens-adversarial | Task 3 계약 변경 | 반영 | - |
| 근거·형식 렌즈를 합치지 않는다는 domain-pruning 결정을 반박 없이 뒤집음 | lens-adversarial | 리뷰 구조 | 반영(대체 근거와 수정 대상 명시) | - |
| lens-consistency 의 스코프·산출물 공백과 type 값이 계약에 없음 | lens-adversarial | Task 3 Files | 반영 | - |
| 브라우저 도구를 대조 렌즈로 옮기면 웹 권한 분리와 kofia 금지가 빠짐 | lens-adversarial | Task 3 Files·Step 1 | 반영(독자 렌즈로, localhost 한정) | - |
| lens-readability 에서 지울 절을 정하지 않아 기존 규칙과 충돌 | lens-adversarial | Task 3 Files | 반영 | - |
| 대조 렌즈 지적에 위치만 확인하면 귀결 판단이 검증 없이 반영됨 | lens-adversarial | Task 2 Step 3 (4) | 반영(위치와 귀결 확인) | - |
| 지운 렌즈 이름 검사가 참고서 기록 절·테스트 픽스처에서 실패 | lens-adversarial | Task 3 Step 1 | 반영(범위를 지시문 폴더로 한정) | - |
| 새 검사 일부가 이미 참이라 실패 확인 단계가 성립하지 않음 | lens-adversarial | Task 3 Step 1·2 | 반영 | - |
| 문장 내용 검사가 문장 grep 이 됨 | lens-adversarial | Task 3 Step 1 | 반영(절 제목 판정) | - |
| Task 2 커밋 뒤 렌즈 표 수정 소유가 정해지지 않음 | lens-adversarial | Task 2·3 | 반영(Task 3 한 커밋) | - |
| researching-prior-art 의 지도 대조 서술이 남음 | lens-adversarial | Task 3 Step 3 | 반영 | - |
| 렌즈 통합의 단독 발견 손실을 측정할 계획 없음 | lens-adversarial | 리뷰 구조 | 반영(사후 비교 한 줄) | - |

반영으로 계약이 바뀌었지만 남은 지적 중 설계를 틀리게 만드는 지적이 없어 다시 리뷰하지 않는다.
