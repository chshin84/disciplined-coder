# 세션 기록 기반 원칙 퇴고 계획 리뷰

대상은 `docs/superpowers/plans/2026-10-03-principle-revision-from-sessions.md` 이고, 렌즈 원본은 같은 이름의
폴더에 있다. 렌즈를 한 번씩만 실행했다.

## 합친 지적

| 지적 | 잡은 렌즈 |
|---|---|
| `$SCR` 이 세션 전용 폴더라 세션이 끊기면 산출물을 찾지 못하고, 실제 경로가 계획에 없다 | adversarial, grounding |
| 추출이 클린룸·ablation 시험이 만든 임시 세션의 과제 프롬프트까지 사용자 발화로 넣는다 | grounding |
| 작업 1에 추출의 제외 목록이 없어 오삽입 판정 기준이 없다 | consistency |
| 작업 3의 처분을 적을 파일이 없다 | consistency |
| 작업 4의 사용자 답을 파일에 적는 단계가 없고, 고른 맥락을 메모리에 쓰는 작업이 없다 | adversarial, consistency |
| 퇴고 기준 커밋이 묶음 끝 승인 대상에 명시되지 않았고, 거부되면 그 기준으로 판정한 조항의 근거가 사라진다 | adversarial, consistency |
| 새 퇴고 기준을 설계의 어느 곳에 적는지가 처분 표와 산출물 표와 계획에서 다르다 | consistency |
| 출력지시 머리말의 처리 순서와 채점 파일 이름이 없다 | consistency |
| 시험 규격에 과제 2개 추가 규칙이 없다 | consistency |
| 삭제 후보를 언제 묻고 승인 뒤 무엇을 반영하는지 없다 | consistency |
| 커밋 메시지에 조항 ID 규칙이 없어 재개 시 진행 상태를 도출할 수 없다 | adversarial |
| 거부 조항을 revert 하면 이웃 조항 커밋과 충돌하고, 참고서의 측정·기각 기록까지 지운다 | adversarial |
| kw-plugins 알림이 승인과 되돌림보다 앞서 거부될 문구까지 알린다 | adversarial, consistency |
| 발화 요지가 참고서와 설계로 공개 원격에 나가는데 반출 전 점검이 없다 | adversarial, consistency |
| 작업 7과 작업 8에 확인 방법이 없다 | fit |
| 불릿 한 항목이 여러 문장이고, 수식어 쌓기와 문장 중간 관형절이 있으며, '검사 전체'가 넓은 말이다 | fit |

## 커버리지 공백

모든 렌즈가 결과를 돌려주었다. 다른 세션이 같은 `main` 에 커밋할 수 있는지는 adversarial 이 측정하지 못했다고
남겼다. 저장소 `CLAUDE.md` 의 클린룸 정의와 설계의 시험 조건이 다른 점은 consistency 가 확인 필요로 남겼다.

## 선행연구 렌즈

계획에는 제안하지 않는다.
