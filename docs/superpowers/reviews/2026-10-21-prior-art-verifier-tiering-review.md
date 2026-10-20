# 선행연구 검증자 배치 spec 리뷰 기록(2026-10-21)

대상은 `docs/superpowers/specs/2026-10-20-prior-art-verifier-tiering-design.md` 다. 파일이 `docs/superpowers/specs` 아래에 있으므로 spec 으로 판정했다. 렌즈 원본은 같은 이름의 폴더에 `lens-grounding-1.json`·`lens-consistency-1.json`·`lens-adversarial-1.json`·`lens-fit-1.json` 으로 있다.

렌즈를 한 번씩만 실행했다.

## 선행연구 에이전트

제안하지 않았다. 이 spec 이 줄이려는 비용이 선행연구 실행 비용이고, 설계가 비용을 줄이는지는 spec 안의 시험이 직접 답하기 때문이다.

## 지적 목록

| 번호 | 렌즈 | 지적 | 함께 잡은 렌즈 |
|---|---|---|---|
| 1 | grounding | WebFetch 인용 125자 제한의 근거가 기록에 없고, 지난 실행 quote 61건 중 38건이 125자를 넘으며 가장 긴 것은 692자다 | — |
| 2 | grounding | 정답으로 지정한 오케스트레이터 직접 확인은 10건뿐이고 나머지 약 50건에는 정답이 없다 | — |
| 3 | grounding | frontmatter 의 model·effort 는 `CLAUDE_CODE_EFFORT_LEVEL`·호출 매개변수가 덮을 수 있는데, 실제 실행 설정을 대조하는 확인 항목이 없다 | — |
| 4 | consistency | 비목표는 인용 판정 기준을 유지한다고 하나, 최종 verdict 를 카테고리 판정의 조합으로 정해 기준이 바뀐다 | — |
| 5 | consistency·adversarial | 수집 단계에서 검사할 quote 가 아직 없다. quote 를 만드는 쪽은 판정 단계다 | adversarial 1번 |
| 6 | consistency | 계약에 넣을 새 출력 형식과 `verifiers`·`verifier_count` 의 새 뜻이 정해지지 않았다 | — |
| 7 | consistency·adversarial | 판정 에이전트 일부 실패, 수집 실패를 `verify_failed`·`partial` 로 어떻게 처리할지 없다. 판정이 빠진 카테고리는 지금 규칙으로 supported 가 된다 | adversarial 11번 |
| 8 | consistency | MapCheck 를 맡을 에이전트 정의와 `MODE` 규약이 정해지지 않았다 | — |
| 9 | consistency | `scripts/test_docs_drift.sh`·`scripts/test_workflow.sh` 가 바뀌는 파일 목록에 없다 | — |
| 10 | consistency·adversarial | SKILL.md 「오케스트레이터 절차」의 워크플로가 꺼진 환경 경로와 「인용 확인」이 수정 대상에서 빠졌다 | adversarial 12번 |
| 11 | consistency | Bash matcher 훅 셋이 수집 에이전트의 Bash 호출에 걸릴 수 있는데 다루지 않았다 | — |
| 12 | consistency·adversarial | 목표는 방향·범위 정확도 유지인데 병합 조건은 비용뿐이다. 묶은 에이전트의 정확도 유지 조건이 없다 | adversarial 16번 |
| 13 | consistency·adversarial | "기준선"이 단독 프롬프트 Opus medium 과 현행 워크플로 검증자 둘을 가리킨다 | adversarial 17번 |
| 14 | consistency | "검증자"가 새 구조에서 무엇을 가리키는지 정해지지 않았다 | — |
| 15 | consistency | 주입 자료·고정 원문·정답표의 위치와 운영 중 저장 위치가 없다 | adversarial 8번 |
| 16 | consistency | 판정 에이전트 구성이 시험 뒤에 정해지는데, 시험 뒤 구성 결정을 기록·승인하는 지점이 없다 | — |
| 17 | adversarial | HTTP 200 으로 오는 봇 확인·로그인·JS 빈 페이지가 접근 성공으로 분류되어 unsupported 가 된다 | — |
| 18 | adversarial | 구절 정규화가 공백·따옴표뿐이라 PDF 하이픈·합자·엔티티에서 미탐이 나고 곧바로 unsupported 가 된다 | — |
| 19 | adversarial | 사내망 프록시·TLS 인증서·인코딩·크기 상한을 다루지 않는다. WebFetch 는 Anthropic 쪽에서 받지만 스크립트는 사용자 PC 에서 받는다 | — |
| 20 | adversarial | Bash 는 스크립트 하나로 제한되지 않는다. 공격자가 고를 수 있는 URL 이 셸에 들어가고, 가장 지시 준수가 약한 Haiku low 가 Bash 를 쥔다 | — |
| 21 | adversarial | 판단이 필요 없는 수집을 URL 마다 LLM 에이전트로 둔다 | — |
| 22 | adversarial | 원문 전체를 판정 에이전트마다 Read 로 읽어 비용이 현행 요약보다 커질 수 있고, Read 상한을 넘는 원문 처리가 없다 | — |
| 23 | adversarial | 플러그인 에이전트의 Bash 가 모든 PC 에 퍼지고, URL 마다 권한 확인 창이 뜰 수 있으며 스크립트 경로 해석이 없다 | — |
| 24 | adversarial | 같은 호스트로 동시 요청이 몰려 429 가 접근 실패로 분류될 수 있다 | — |
| 25 | adversarial | 주입 자료에 참인 주장을 섞는지와 참 기각률을 세는지 정하지 않아 보수적인 설정이 이길 수 있다 | — |
| 26 | adversarial | 주입 항목이 정말 원문과 어긋나는지 확인하는 절차가 없다 | — |
| 27 | adversarial | 표본 수와 반복 횟수가 없어 한 건 차이로 채택이 뒤집힌다 | — |
| 28 | fit | 지도 대조 행의 "웹을 열지 않는다"와 격자 표 '고른 이유' 열의 분기 규칙이 사실 칸에 섞였다(INSTRUCTION-FORM) | — |
| 29 | fit | 표 열 말끝 불일치, map-check 와 지도 대조의 두 이름, "잘린 부정어"·"결말 서술 오류" 풀이 없음 | — |
| 30 | fit | 「의도」 단락의 개념 혼합, 「원문 확보」의 주체 누락과 가정 확인 방법 누락, 여러 문장 불릿, 겹친 수식어, 긴 관형절 | — |
| 31 | fit | "시험 자료"·"원래 자료"·"같은 자료"의 혼용, "수치·조건" 가운뎃점의 중의성, "시험이 정한다"의 주체 | — |

## 커버리지 공백

에이전트 정의의 `tools` 칸이 `Bash(경로:*)` 같은 패턴 제한을 받는지, 워크플로 런타임이 `agent()` 밖에서 셸을 실행할 수 있는지는 어느 렌즈도 확인하지 않았다. adversarial 렌즈가 확인할 것으로 남겼다.
