# 2026-10-25 선행연구 계획 수립 개선 spec 리뷰

## 대상과 실행

- 대상: `docs/superpowers/specs/2026-10-25-prior-art-planning-design.md` (경로가 `specs/` 아래이므로 spec 으로 판정했다)
- 렌즈: `lens-grounding`, `lens-consistency`, `lens-adversarial`, `lens-fit`. 렌즈를 한 번씩만 실행했다.
- 원본: 같은 이름 폴더의 `lens-*.json`
- 선행연구 에이전트: 제안하지 않았다. 이 spec 은 기존 에이전트의 계획 단계를 알려진 방식(Anthropic 다중 에이전트 연구 시스템의 하위 에이전트 과제 구성)으로 고치는 설계이고, 되는지 자체가 미지수인 일을 해내려는 설계가 아니기 때문이다.
- builder check 는 실행하지 않았다. 사용자 비용을 줄이려고 렌즈 리뷰가 구현 가능성 확인을 대신하게 했다(작성자 판단).

## 병합한 지적

| 번호 | 렌즈 | 위치 | 지적 |
|---|---|---|---|
| 1 | consistency | C 넷째 문단 | 둘러보기 연구자에게 '짧고 넓은 검색어로 시작'을 지시해, 방법을 지시하지 않는다는 설계 원칙과 충돌한다 |
| 2 | consistency | D 첫·넷째 문단 | contrast 지시문을 '현행 그대로' 둔다면서 purpose·constraints 를 읽게 한다 |
| 3 | consistency | 설계 원칙, A | 질의 금지를 강제한다고 했으나 수단은 오케스트레이터의 실행 직전 대조뿐이다 |
| 4 | consistency | A 표 | 새 칸 `purpose`가 근거 지도의 `axes.purpose`와 이름이 같다 |
| 5 | consistency, adversarial | C, 바뀌는 파일 | `phase`·`mode`·`MODE`·`search`/`explore` 이름이 섞이고, scout 실행의 args·반환값·원본 이름·실행 차례가 정해지지 않았다 |
| 6 | consistency | 바뀌는 파일 | SKILL.md 의 「세션이 끊긴 때」·「워크플로가 꺼진 환경」·3단계·「세는 대상」·「원본 파일 규칙」과 review-docs 의 원본 이름 표가 바뀔 목록에 없다 |
| 7 | consistency | D 여섯째 문단 | 종합 결론의 지지 후보안을 담을 칸이 계약에 없다 |
| 8 | consistency | B | 재승인 뒤 기록에 어느 버전의 프로토콜을 적는지 없다 |
| 9 | consistency | 확인 방법 | 목표 둘째·셋째·넷째와 실패로 보는 결과를 확인하는 단계가 없다 |
| 10 | adversarial | D 90·97·99행 | 검증하지 않는 bearing 과 축이 모두 다른 행이 결론의 근거가 될 수 있어 10-24 Perry·Stieg 사례가 규칙으로 허용된다 |
| 11 | adversarial | A, D 89행 | 추론한 purpose 가 틀리면 연구자 전원이 그 기준으로 근거를 버리고, 버린 근거는 남지 않는다 |
| 12 | adversarial | C 71·77행 | 둘러보기를 기본 실행으로 둘 근거가 없고, 대부분의 실행에서 승인 턴과 실행을 하나씩 늘린다 |
| 13 | adversarial | A 63행 | 사용자 이름을 낱말로 펼치면 커밋되고 봉인되는 기록에 식별 문자열이 남는다 |
| 14 | adversarial | B 67행 | 재승인 규칙과 '선택을 요구하지 말라'는 사용자 지시가 만날 때의 우선순위가 없다 |
| 15 | adversarial | C 79행 | scout 서술이 하위 질문 문장을 거쳐 연구자 입력으로 새는 경로가 열려 있다 |
| 16 | fit | 111행 | spec 에 다른 세션 알림이라는 다음 행동이 적혀 있다 |
| 17 | fit | 여러 곳 | 문서를 판단 주체로 썼고, 설계 결정의 주체(사용자·작성자) 표시가 없다 |
| 18 | fit | D 92행 | 탐색 전술 목록에 출처가 없다 |
| 19 | fit | 확인 방법 | 구현자 행동을 '~하라'로 쓰지 않았다 |
| 20 | fit | 여러 곳 | NO-MID-MOD·BULLET-SCOPE·ONE-IDEA·TERM-ONE·TERM-EXPLAIN·COUNT-EARNS 위반, '반지목표'라는 새 용어 |

둘 이상의 렌즈가 함께 잡은 지적은 5번(consistency 와 adversarial)이다.

## 커버리지 공백

`lens-grounding`은 지적이 없었다. 「의도」의 사실 주장과 코드 주장과 Anthropic 인용이 모두 출처와 맞았다. 다만 10-20·10-21 실행의 '불만 기록 없음'은 그 렌즈가 대화 기록을 열지 않아 확인하지 못했다. `lens-consistency`는 워크플로의 coverage·overall_status 계산(482-495행 부근)이 scout 실행에서 어떻게 되는지 읽지 않았다. `lens-adversarial`은 review-specs 「`prior-art` 기록에 적을 것」의 문구를 직접 읽지 않았다.
