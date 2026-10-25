# 렌즈 에이전트 전환 spec 2차 변경 리뷰 기록

대상은 `docs/superpowers/specs/2026-10-25-lens-agent-restructure-design.md` 의 「2차 변경: 앞단 스킬과 렌즈 분리」 절이다. 2026-10-25 밤에 실행한 렌즈는 `lens-grounding`(spec), `lens-consistency`(spec), `lens-adversarial`(design), `lens-fit`(auto) 이다. 렌즈를 한 번씩만 실행했다.

이 세션에 적재된 플러그인은 이 브랜치보다 옛 버전이라 렌즈 에이전트가 등록되어 있지 않았다. 그래서 general-purpose 서브에이전트가 이 브랜치의 `agents/lens-*.md` 를 Read 해 그 정의를 지시로 삼았고, 읽기 전용은 프롬프트로만 지시했다. 렌즈가 파일을 고친 흔적은 없다.

렌즈가 실행되는 동안 사용자가 절의 두 곳을 바꿨다. `lens-readability` 를 옛 정의 그대로 되살리는 문장과 `lens-rebuttal` 을 주장마다 따로 실행하는 문단이 그 두 곳이다. 렌즈는 그 전 문안을 보았다.

선행연구 에이전트는 제안하지 않았다. 이 변경은 이미 하던 렌즈 실행을 다시 나누는 일이고, 되는지 자체가 미지수인 일이 아니다.

원본은 같은 이름 폴더의 `lens-grounding-1.json`, `lens-consistency-1.json`, `lens-adversarial-1.json`, `lens-fit-1.json` 이다. 지적은 grounding 6건, consistency 11건, adversarial 13건, fit 10건이다.

## 둘 이상의 렌즈가 함께 지적한 항목

| 지적 | 렌즈 |
|---|---|
| 「바뀌는 파일」에 `scripts/test_docs_drift.sh` 와 `test_lens_contract.sh` 의 "브라우저 도구 없음" 검사가 빠졌다 | grounding, consistency, adversarial |
| `lens-visual` 의 출력 칸과 목적 주입이 정해지지 않았다 | grounding, consistency, adversarial |
| 대체 선언이 목표·비목표·새 체크리스트·출력 계약의 상충 문장을 덮지 않는다 | consistency, adversarial |
| 끊김 관찰과 「반드시 읽히는 곳」이 어느 에이전트에도 남지 않는다 | grounding, consistency |
| 「퇴고 참고」의 「글에서 볼 것」과 되살린 관찰 목록이 두 곳에 남는다 | consistency, adversarial |

## 한 렌즈만 지적한 항목

| 지적 | 렌즈 |
|---|---|
| 대화 상속이 런타임 시험 6에서 확인된 것처럼 적혀 있다 | grounding |
| "주장·제안서·보고서의 논증" 문구는 정의 본문이 아니라 description 과 `dispatching-lenses` 표에 있다 | grounding |
| `lens_contract.json` 에는 도구 표가 없다 | grounding |
| `lens-grounding` 이 대화를 상대편으로 삼으면 `counterpart_file` 예외가 없다 | consistency |
| `lens-readability` 의 대상 범위가 두 표에서 다르다(.pdf, .html 초안) | consistency |
| 필요할 때 그룹의 새 발동 기준이 없다 | consistency |
| PDF 화면 런타임 시험이 순서와 확인 단계에 없다 | consistency |
| "검토해 줘" 트리거가 넓고 표에 행이 없다 | adversarial |
| "근거 확인"이 선행연구 발동 문구와 겹친다 | adversarial |
| spec·plan 적대적 검토가 `review-specs` 전체를 실행해 비용이 커진다 | adversarial |
| 직접 요청을 승인으로 보면 검색어 외부 로그 고지가 빠진다 | adversarial |
| PDF 내보내기의 COM 부작용을 가리키지 않는다 | adversarial |
| 기존 .pptx·.docx·.pdf 에는 넘길 마크다운 초안이 없다 | adversarial |
| 대상→에이전트 표가 `dispatching-lenses` 에 세 개로 흩어진다 | adversarial |
| 옛 이름 grep 의 제외 범위가 없다 | adversarial |
| 글로 옮길 수 없는 첨부를 원문으로 넘길 수 없다 | adversarial |
| 평서형으로 적은 지시(`INSTRUCTION-FORM`) 세 곳 | fit |
| 표 안 말끝 섞임(`ONE-ENDING`) 세 곳 | fit |
| "앞단 스킬"이 풀이 없이 먼저 쓰였다(`TERM-EXPLAIN`) | fit |
| "두 곳"을 개수로 가리켰다(`COUNT-EARNS`) | fit |
| 관형절(`NO-MID-MOD`)과 겹친 수식(`NO-STACK-MOD`) 한 곳씩 | fit |

## 커버리지 공백

없다. 네 렌즈가 모두 결과를 돌려주었고 `principles_applied` 가 비어 있지 않았다. `lens-fit` 의 `doc_type` 은 설계 행으로 정해졌다.

## 걸러 낸 지적

없다. 메인 세션이 지적마다 근거 파일과 줄을 열어 확인했고, 인용한 문장이 모두 그 파일에 있었다.
