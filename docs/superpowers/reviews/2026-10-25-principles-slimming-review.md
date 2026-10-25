# 에이전트원칙 경량화 spec 리뷰 기록

대상은 `docs/superpowers/specs/2026-10-25-principles-slimming-design.md` 이며, 경로가 `docs/superpowers/specs` 아래이므로 spec 으로 구분했다. 렌즈 원본은 같은 이름의 폴더에 있다(`lens-grounding-1.json`, `lens-consistency-1.json`, `lens-adversarial-1.json`, `lens-fit-1.json`).

렌즈를 한 번씩만 실행했다.

선행연구 에이전트는 제안하지 않았다. 이 spec 은 이미 있는 원칙·훅·스킬을 다시 배치하는 일이고, 되는지 자체가 미지수인 새 시도가 아니기 때문이다.

같은 차수에 superpowers brainstorming 의 구현자 점검(builder check)도 실행했다. 그 질문은 아래 목록의 해당 항목에 `builder` 로 표시했다.

## 합친 지적

| 번호 | 지적 | 잡은 렌즈 |
|---|---|---|
| 1 | `LENS-ALLOWED` 를 참고 문서로 옮기면, 원칙이 `@import` 로 실려 세션 기본 지침의 서브에이전트 금지를 연다는 근거(`docs/domain-discipline.md`)가 무너진다. `test_docs_drift.sh` 843~848행과 `test_scaffold.sh` 571행도 원칙의 이 조항을 표지로 쓴다 | grounding |
| 2 | `TOP-DOWN` 은 `ASK-OPTIONS`·`DELEGATED-SCORE` 가 ID 로 참조하는데 옮기는 포인터가 위임 예외만 다룬다. Skill 매처가 안 되면 실릴 경로가 없다 | grounding, adversarial, builder |
| 3 | `DELEGATED-SCORE`·`TOP-DOWN` 약 1,300자를 옮기려고 새 스킬·낱말 감지·새 훅을 더해 과설계다. '위임' 낱말은 금융 업무 문장에서 오탐하고, '알아서 해 줘' 같은 표현은 놓친다. `prior_art_nudge` 는 주제어가 없으면 곧바로 끝나는 구조다 | adversarial, grounding |
| 4 | `NO-RAW-OUTPUT` 의 "기능을 바꿔 고치면"은 Stop 게이트가 보지 않는 기존 파일 수정이다 | adversarial |
| 5 | 「메모리와 문서 맵」은 프로젝트 밖 메모리 파일에 필요한데 문서 강제 훅은 프로젝트 밖을 보지 않는다 | adversarial |
| 6 | 「읽기 위한 문서」는 .html·.pptx·.docx 보고서와 프로젝트 밖 보고서에 필요한데 문서 강제 훅은 프로젝트 안 .md 만 본다 | consistency, builder |
| 7 | 이유 문장 59곳을 시험 없이 한꺼번에 빼면 준수 저하를 감지할 장치가 없다. 판단 조항의 이유만 남기는 방식으로 범위를 줄일 수 있다. 시험 단위(`evals/principles/clauses/`)는 이유 문장이 있는 문구로 측정한 값이다 | adversarial |
| 8 | 표시 파일을 못 만들거나 `session_id` 가 없을 때의 fail-open 이 없다. 한 번 거부인지 스킬을 열 때까지 거부인지 두 가지로 읽힌다 | adversarial, builder |
| 9 | 거부 뒤 셸 heredoc 으로 우회하는 길을 다루지 않는다 | adversarial |
| 10 | 생성물 표시 "BEGIN" 은 SQL·PGP 등에 과검출한다 | adversarial |
| 11 | 서브에이전트 안의 훅 호출에서 표시 키(`session_id`, `agent_id`)를 정하지 않았다. 문서를 쓰는 서브에이전트와 `lens-fit` 계약에 옮긴 규칙 경로를 넘기는 지시가 없다 | adversarial, builder |
| 12 | 렌즈는 서브에이전트에서 실행되므로 상대 경로를 해석할 기준이 없다. `lens-adversarial` 이 쓰는 `domain-pruning`·`domain-plugin` 경로를 넘기는 지시가 없다 | adversarial |
| 13 | 단계 사이에 main 에 병합되면 조항은 빠지고 훅은 아직 없는 상태가 배포된다. 한 브랜치에서 마친 뒤 병합하라는 지시가 없다 | adversarial |
| 14 | 14,500자 상한은 여유가 263자이고, 넘을 때 멈추고 물으라는 지시가 없다 | adversarial |
| 15 | `domain-readme` 의 위치와 이름이 참고 문서 규칙과 다르다. `references/` 기준 경로가 두 가지로 적혔고, 하위 폴더 여부가 확정값이면서 구현자 판단으로도 적혔다 | consistency |
| 16 | 훅이 README 를 직접 감지하는 것은 "세부 분기는 목차가 맡는다"는 층 규칙과 다르다 | consistency |
| 17 | `EDIT-PRIORITY` 를 훅 문구로 옮기는 것은 "절차는 스킬"이라는 층 규칙과 다르다 | consistency |
| 18 | 새 PostToolUse 훅 두 개가 "기존 프로세스에 넣어라"와 다르다 | consistency |
| 19 | Skill 매처 시험 결과를 적을 곳이 "결정 기록"과 "결과 보고" 두 이름으로 적혔고 위치가 없다 | consistency, fit |
| 20 | 「순서와 확인」 3·4·5단계 확인이 앞 절의 요구(`NO-RAW-OUTPUT`·`LENS-ALLOWED` 이동, 위임 감지, 검진 넛지 수정, CLAUDE.md 수정, 「삭제한 조항」 기록)를 판정하지 않는다. 「함께 고칠 의존」을 수행하는 단계가 없다 | consistency |
| 21 | 의존 누락: `test_docs_drift.sh` 의 `missing_clause_ids`(807행)·823행·737·350·355행, `test_scaffold.sh` 571행, `lens-readability` 81·110행, `review-docs` 37·39·94~96행, `sub-session-protocol.md` 63행, `domain-korean.md` 251행, `korean-banned-words.md` 73행, `_ensure_autoupdate.sh`, `_json_valid.sh`, `rules_nudge_pretooluse.sh` 67행, `agent-prior-art`·`nested-orchestration` SKILL.md, CLAUDE.md 「넛지 예외」, `audit_verify.sh` 주석 | grounding, consistency, adversarial |
| 22 | `skills/domain-pruning/SKILL.md:76`(옮긴 뒤 위치)는 옮긴 뒤에 없는 경로다 | consistency, fit |
| 23 | `domain-docs` 이름이 superseded 대응표(`rewrite-map/domain-docs.md`)와 같다 | consistency |
| 24 | "약 12.8k 토큰"의 출처가 없다 | grounding |
| 25 | 지시를 평서형으로 쓴 줄(비목표, 참고 문서 위치, 구현자 위임 항목, CLAUDE.md 추가 문단), 원하는 형태 없는 금지문, 표 셀 말끝 불일치, 두 지시를 한 문장에 넣은 57행, 표시 파일 이름 세 가지, 정의 없는 "메인 스킬", 판단에 쓰이지 않는 "약 18곳" | fit |

## 커버리지

네 렌즈 모두 지적을 냈다. 둘 이상의 렌즈가 함께 잡은 항목은 2, 3, 6, 8, 11, 19, 21, 22 이다. 훅의 Windows 프로세스 비용과 플러그인 갱신이 세션 도중 도착할 때(`/clear` 뒤 사본 덮어쓰기)의 버전 혼재는 `lens-adversarial` 이 `notes` 에 가정으로만 적었고 어느 렌즈도 지적으로 올리지 않았다.
