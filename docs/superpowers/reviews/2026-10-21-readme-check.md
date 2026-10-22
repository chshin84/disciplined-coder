# README 검진 — 2026-10-21

대상은 사용자용으로 줄여 다시 쓴 `README.md` 다. `review-docs` 대로 `lens-grounding` 과 `lens-fit` 을 실행했고, `lens-fit` 계약에 `skills/domain-readme/SKILL.md` 를 추가했다. 원본은 같은 이름 폴더의 `lens-grounding-1.json` 과 `lens-fit-1.json` 이다.

`lens-readability` 는 제안하지 않았다. README 는 그 렌즈의 발동 기준에 들지 않는다. 선행연구 에이전트도 제안하지 않았다. `review-docs` 가 README 에는 제안하지 않는다고 정하며, README 작성 선행연구는 같은 날 `2026-10-21-readme-writing-prior-art.md` 로 따로 실행했다.

## 지적 목록

- **[grounding·fit 공통] spec 리뷰 차단의 절대 서술** — 「켜면 달라지는 것」은 리뷰 전에는 턴을 끝내지 못한다고 적고, 「차단되었을 때 푸는 법」은 두 번째 종료 시도가 통과한다고 적는다(`hooks/_stop_preamble.sh` 루프가드).
- **[grounding·fit 공통] 「켜면 달라지는 것」의 누락** — 「끄는 법」·「차단되었을 때 푸는 법」에 나오는 문서 형식 경고, 나눠 맡길지 판단 차단, 규칙 위치 알림이 목록에 없다. 규칙 위치 알림은 Bash 첫 호출에도 나오므로 '세션 첫 편집 전'은 대상보다 좁다.
- **[grounding] 세션 시작 알림의 가시성** — README 는 사용자가 ERROR·WARNING 줄과 superpowers 설치 명령을 본다고 전제한다. `update_check_sessionstart.sh` 주석은 `scaffold.sh` 의 평문 stdout 이 Claude 맥락에만 들어간다고 적는다. Claude Code 문서로는 확인하지 않았다(가정).
- **[grounding] 금지 표현 검사 대상** — README 는 '사용자가 요구한 산출물 `.md`'로 적으나, 코드는 세 제외 경로 밖의 모든 `.md` 를 검사한다. 셸 편집은 거부되지 않고 알림만 나온다.
- **[grounding] 파이썬 의존** — 문서 형식 경고도 파이썬이 없으면 빠지나 「설치」에 없다.
- **[fit] 첫 문단** — 만든 사람이 '본인'으로만 나오고 목록을 싣는 주체가 생략되었다(`SUBJECT-OBJECT`).
- **[fit] 불릿 두 문장** — '원칙' 항목만 두 문장이다(`BULLET-SCOPE`).
- **[fit] 관형절** — '금지 표현' 항목에서 금지 표현을 쓰는 주체가 드러나지 않는다(`NO-MID-MOD`).
- **[fit] 원칙의 이름** — '팀 엔지니어링 원칙'·'원칙 파일'·'에이전트원칙'이 같은 파일을 가리킨다(`TERM-ONE`).
- **[fit] 풀이 없는 이름** — 렌즈, 서브 세션, spec·plan 에 풀이가 없다(`TERM-EXPLAIN`).
- **[fit] 행동 주체** — 차단을 푸는 행동을 사용자가 하는지 Claude 가 하는지 적혀 있지 않다(`SUBJECT-OBJECT`).
- **[fit] 긴 단락** — 「설치」 첫 단락(다섯 문장), 「주의」의 superpowers 단락과 「더 읽기」(네 문장)(`ONE-IDEA`).
- **[fit] 본문 제목 층** — 「차단되었을 때 푸는 법」과 「주의」가 첫 문장 없이 라벨 단락으로 시작한다(`TITLE-LAYERS`).

## 커버리지 공백

`scaffold.sh` stdout 이 사용자 화면에 보이는지는 두 렌즈 모두 확인하지 못했다. 확인하려면 Claude Code 의 SessionStart 출력 규칙을 보거나, 파이썬을 뺀 환경에서 새 세션을 열어 WARNING 줄이 화면에 보이는지 관찰한다.
