# 렌즈 에이전트 전환 spec 리뷰 기록

대상은 `docs/superpowers/specs/2026-10-25-lens-agent-restructure-design.md` 이다. 경로가 `docs/superpowers/specs` 아래이므로 spec 으로 구분했다. 렌즈 원본은 같은 이름의 폴더에 있다(`lens-grounding-1.json`, `lens-consistency-1.json`, `lens-adversarial-1.json`, `lens-fit-1.json`).

렌즈를 한 번씩만 실행했다.

선행연구 에이전트는 제안하지 않았다. 이 spec 은 이미 하던 렌즈 실행을 에이전트 정의로 다시 배치하는 일이다. 되는지 미지수인 항목(플러그인 에이전트의 브라우저 도구 사용)은 spec 의 런타임 시험이 확인한다.

같은 차수에 superpowers brainstorming 의 구현자 점검(builder check)도 실행했다. 그 질문은 아래 목록의 해당 항목에 `builder` 로 표시했다.

## 합친 지적

| 번호 | 지적 | 잡은 렌즈 |
|---|---|---|
| 1 | fit 문체 기계화의 대상 파일을 `hooks/doc_format_pretooluse.sh` 로 적었다. 실제 형식 검사기는 `hooks/_doc_form_check.py` 이고 `hooks/doc_review_posttooluse.sh` 가 호출한다 | grounding, builder |
| 2 | lens-fit 정의에서 "기계 검사가 본 항목은 지적하지 마라"로 항목을 통째로 빼면, 훅이 보지 않는 .html·.pptx·기존 파일·런타임 출력에서 그 항목을 아무도 보지 않는다 | builder |
| 3 | 문체 경고를 모든 프로젝트에 실행되는 훅에 넣는 것은 domain-plugin 의 훅 기준(비타협적 준수)에 맞지 않을 수 있고, 8단계 확인이 test_hooks.sh 통과뿐이라 오탐률과 문체 비율 감소를 보지 않는다 | adversarial, builder |
| 4 | fit 조항별 건수(COUNT-EARNS 98건 등)와 렌즈 1회 도구 호출 수(중앙값 8~18, 최댓값 14~48)의 출처가 조사 기록과 저장소에 없다 | grounding |
| 5 | 묶기 예외의 근거 "읽기 비용 3 대 1.2 측정"은 dispatching-lenses 가 사용자 정책값이라고 적은 값이다. 묶은 호출은 general-purpose 로 실행되어 도구 제한·모델 고정과 `lens-*` 허용 이름을 받지 못하고 실행 경로가 둘이 된다 | grounding, consistency, adversarial |
| 6 | 「다른 세션과의 경계」가 다른 세션의 미커밋 수정 줄(상태 정보)을 적었고, 조사 기록의 요청 내용(lens-readability 110행, lens-adversarial 포인터)과 다르다. 4·5단계 시작 조건이 "먼저 병합되는 세션"과 "원칙 경량화 병합 뒤" 두 가지로 읽힌다 | grounding, fit, adversarial |
| 7 | 1:1 전제 목록과 4단계 grep 이 지우는 스킬을 가리키는 줄을 다 덮지 않는다. test_docs_drift.sh 193·362·467·600·621행과 AGG 경로 줄, domain-korean:264, domain-plugin:24, audit_statements.sh:5, rules_nudge_pretooluse.sh:52, review-llm-calls description, nested-orchestration 의 「렌즈 그룹」 참조가 빠졌다 | grounding, consistency, adversarial |
| 8 | aggregating-lenses 처분에서 100행은 런타임 전용이 아니고, 「판단 재귀 회피」·「공통 계약의 예외」·67행 워크플로 처분 문단의 옮길 곳이 없다. "남는 내용이 다섯 줄뿐"은 조사 기록과 다르다 | grounding |
| 9 | Agent 도구 `subagent_type` 의 플러그인 에이전트 해석은 확인된 적이 없다. 2026-10-18 에 확인한 것은 워크플로 `agentType` 이다 | grounding |
| 10 | model 별칭의 "확장 맥락 보존"이 주입된 출처에 없다 | grounding |
| 11 | 현행 읽기 전용이 "프롬프트로만" 지켜진다는 진술은 review-specs 의 구조적 차단 경로(쓰기 도구 없는 에이전트 종류)와 다르다 | grounding |
| 12 | 채택 비교의 기준이 성립하지 않는다. 원칙 경량화 spec 은 이 워크트리에 없고, 메시지 형식 spec 은 2026-10-09 spec 의 개정 절이며 1차 반영 뒤 본문이 바뀌었다. 지적 수 단순 비교는 흔들리고 반영 여부를 보지 않으며, 기준 토큰의 출처와 대기 시간 측정이 없다 | consistency, adversarial, grounding, builder |
| 13 | 스킬 삭제(5단계)가 채택 판정(6단계)보다 앞에 있어 판정이 실패하면 되돌릴 범위가 크다 | adversarial |
| 14 | 사용자가 이름으로 직접 실행하면 MODE·PRINCIPLES 줄이 없는데, 런타임 시험 판정이 실행 여부와 tools 만 본다 | adversarial |
| 15 | 설치본 갱신 시점에 옛 스킬과 새 에이전트가 섞일 수 있고, 3~5단계 사이 같은 이름의 스킬과 에이전트가 함께 있을 때의 선택을 확인하지 않는다 | adversarial |
| 16 | 주장 반박 에이전트가 사내 주장을 검색어와 요청으로 밖에 보내며, 접속 금지 도메인(kofia.or.kr)과 검색어에 원문을 넣지 않는 규칙이 가드에 없다 | adversarial |
| 17 | 주장 반박 에이전트의 인용 URL 을 검증하는 단계가 없고, 외부 근거 탐색 경로가 agent-prior-art 와 두 곳이 된다 | adversarial, builder |
| 18 | 주장 반박 에이전트의 출력이 공통 계약 칸(`file`·`evidence`·`counterpart`)과 맞지 않고, 대상이 레포 파일이 아닐 때의 처리가 없다 | builder |
| 19 | 주장 반박 에이전트와 `artifact` 모드의 발동 기준과 실행하는 호출자가 없다 | consistency, builder |
| 20 | readability 재정의 뒤 글 검토의 이전(review-docs 퇴고), 감사에서의 처분, `purpose`·`rewrite`·`suggestions` 유지 여부, .pptx 포함 여부, 브라우저 도구가 없는 PC 의 동작이 정해지지 않았다. review-docs:39 와 audit-repo-docs:48,61 을 고칠 단계가 없다 | consistency, adversarial, builder |
| 21 | 비목표 "체크리스트는 옮기기만"이 `artifact` 모드, 주장 반박, 렌더링 리뷰, fit 제외 규칙과 충돌한다 | consistency, adversarial |
| 22 | 정의 본문에 옮길 절 목록이 일부 절(readability 「목적 주입」「관찰 목록」 등, consistency 「레포 문서 감사에서의 짝」, adversarial 「지적은 고칠 줄과 절을 가리킨다」)을 빠뜨렸다 | consistency |
| 23 | dispatching-lenses 「렌즈 그룹」 절 제목을 유지하는지 정하지 않았다. 다른 스킬 여러 곳이 이 제목을 가리킨다 | consistency |
| 24 | 8단계가 lens-fit 정의 수정과 원칙 경량화 병합 선행 조건을 다루지 않고, 9단계가 채택 분기의 원칙·review-specs 수정을 다루지 않는다 | consistency |
| 25 | test_lens_contract.sh 의 대조 대상이 「출력 계약」(에이전트 예시 블록)과 2단계(SKILL.md)에서 다르다 | consistency |
| 26 | 계약 JSON 과 새 테스트를 추가하면서 test_docs_drift.sh 의 렌즈 스키마 검사 처분을 적지 않아 검사가 겹치거나 대상 없이 남는다 | adversarial |
| 27 | `effort` 를 적지 않으면 상속되는지 시험 목록에 없다 | adversarial |
| 28 | 반목표가 대기 시간과 반영 여부를 실패 조건으로 두지만 채택 조건은 둘을 재지 않는다 | consistency |
| 29 | 문체: 지시를 평서형 부정문으로 적었다, 목록 앞 개수 예고와 이름 대신 개수, 주어 있는 관형절, 문서·단계를 행동 주체로 쓴 문장, '원본'을 두 뜻으로 씀, 표 셀의 기호 연결, 네 문장 넘는 단락, 맥락 없는 이름(S3, 10-05 사례, 10-11 spec 위치) | fit |

## 커버리지

네 렌즈 모두 지적을 냈다. 둘 이상의 렌즈가 함께 잡은 항목은 1, 3, 5, 6, 7, 12, 17, 19, 20, 21 이다. 아래 사항은 `notes` 에만 적혔고 어느 렌즈도 지적으로 올리지 않았다. adversarial 은 플러그인 에이전트가 사용자 CLAUDE.md 를 받으면 원칙이 두 번 실려 토큰이 늘 수 있다고 적었다. consistency 는 review-specs:57-60·review-docs:7·audit-repo-docs:44-46 의 행 번호와 test_audit.sh·audit_verify.sh·audit_rounds.sh 의 행 번호를 대조하지 않았다고 적었고, 이 행 번호는 grounding 이 일치를 확인했다. grounding 은 제약 표의 사용자 지시 날짜 중 2026-09-25, 2026-10-12, 2026-10-24·25 를 주입된 출처에서 확인하지 못했다고 적었다.
