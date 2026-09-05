# 정본 분리 설계 리뷰 — 1회차

검토 대상은 `docs/superpowers/specs/2026-09-05-canon-split-design.md`(커밋 64ca1bd)다. 렌즈 원본은 같은 이름의 폴더에 `lens-grounding-1.json`·`lens-consistency-1.json`·`lens-adversarial-1.json`으로 있다. 렌즈를 한 번씩만 돌렸다. grounding과 consistency는 한 호출이 문서를 한 번 읽고 차례로 적용했고, adversarial은 따로 띄웠다.

선행연구 렌즈는 제안하지 않았다. 훅이 넘긴 경로가 `specs/`라 spec이다. 이 설계는 이미 있는 장치(스킬 계층, 문서 넛지 훅, 정본의 한 줄 조항과 스킬의 상세 분리)를 코딩 규칙에도 적용해 정리하는 것이라, 되는지가 미지수인 새 시도가 아니다.

## 합친 목록

같은 곳을 둘 이상의 렌즈가 잡은 것은 한 항목으로 합치고 렌즈 이름을 함께 적었다. 근거 확인은 각 항목의 상대편 문장을 파일에서 열어 했다.

| 번호 | 렌즈 | 짚은 곳 | 지적 | 근거 확인 |
|---|---|---|---|---|
| 1 | adversarial·grounding | 「참조 고치기」 domain-docs 항목 | `domain-docs` 「규칙 (문서 일반)」의 문서 SSOT 항목 끝 "(`SSOT`)"가 목록에 없어 새 검사가 바로 FAIL 난다 | 그 줄이 백틱 `SSOT`를 담고 있음을 확인했다 |
| 2 | adversarial·grounding | 「배치」 표와 「참조 고치기」 | `domain-docs` 「문서 타입과 수명」 첫 문장이 정본의 「문서와 상태의 위생」 절을 이름으로 가리키는데 그 절이 사라진다 | 그 문장을 확인했다 |
| 3 | adversarial | 「정본의 이후 모습」 | 정본의 Tradeoff 문장이 어디로 가는지 적혀 있지 않아 고아 문장이 된다 | 정본에서 그 문장이 `## Karpathy 지침` 아래에 있음을 확인했다 |
| 4 | adversarial | 「훅」 코드 넛지와 「테스트」 | 표시 파일이 테스트 픽스처 밖 `/tmp`에 남아 스위트를 두 번 돌리면 첫 편집 검사가 깨진다 | `test_hooks.sh`가 `mktemp -d`로 격리하고 `TMPDIR`을 바꾸지 않음을 확인했다 |
| 5 | adversarial·grounding·consistency | 「훅」 세션 키 | `session_id`가 훅 stdin에 오는지 미측정이고, 없으면 매번 알리면서 문장은 "한 번만 알린다"고 말해 어긋난다 | 공식 훅 문서가 `session_id`를 모든 훅의 공통 필드로 적고, 서브에이전트 안에서는 `agent_id`가 더 실린다고 적는다. 전제는 서지만 문장의 어긋남은 남는다 |
| 6 | adversarial·consistency | 「훅」 경로 규칙 | 건너뛰기가 `.md`뿐이라 리뷰 기록 JSON을 저장해도 코드 넛지가 뜨고, 결정은 "코드 파일"이라 부르며 훅은 "`.md`가 아닌 것"으로 정해 이름이 갈린다 | 렌즈 원본이 `docs/superpowers/reviews/*.json`에 놓임을 확인했다 |
| 7 | adversarial·grounding | 「참조 고치기」 README 항목 | README 같은 문단의 "넷 다 꺼지고"가 목록에 없어 넛지를 더하면 개수가 어긋난다 | 그 문장을 확인했다 |
| 8 | adversarial·consistency | 「되돌리기」 | 앞 커밋만 되돌리면 훅이 없는 스킬을 열라고 알린다 | 설계의 커밋 분할에서 따라 나온다 |
| 9 | adversarial | 「테스트」 docs_drift 문장 | 베끼기 검사의 앵커가 한국어 문장이라 영어 「Reach」 절에는 발화하지 않는데 설계는 그것을 가드로 세운다 | `TELL_SENT`가 한국어 문장임을 확인했다 |
| 10 | adversarial | domain-writing 설명문 | 훅이 spec·plan과 리뷰 기록에서는 빠지는데 설명문은 모든 `.md`에 알린다고 읽힌다 | `doc_review_posttooluse.sh`의 건너뛰기 셋을 확인했다 |
| 11 | adversarial | 「훅」 문서 넛지 덧붙임 | 훅 문장에 스킬의 절 이름 "Surgical Changes"를 박는 것은 그 훅이 주석으로 금지한 사본이다 | 훅 주석을 확인했다 |
| 12 | adversarial·consistency | domain-coding 「Reach」와 domain-writing | 서브에이전트에 닿는 장치가 `nested-orchestration` 한 줄뿐이고 `domain-writing`에는 Reach가 없다 | 설계 본문에서 확인했다. 5번의 `agent_id`가 완화한다 |
| 13 | grounding | domain-coding 머리말 | "Never claim done" 문장이 정본의 `TDD`에서 왔다고 적는데 지금 정본에 `TDD`는 없다 | 정본에 그 조항이 없음을 확인했다 |
| 14 | grounding | domain-coding 머리말 | "원문 그대로"라 적었는데 Goal-Driven Execution에 한 문장이 더 있다 | 플러그인 원문과 대조했다 |
| 15 | consistency | 「결정」과 「훅」 | 결정은 "편집이 들어올 때" 알리는데 PostToolUse는 편집 뒤에 돌고 문장은 "편집 시작"이라 한다 | `doc_format_pretooluse.sh`가 PreToolUse임을 확인했다 |
| 16 | consistency | 「결정」과 「훅」 문서 넛지 | 첫째 덧붙임도 결정 밖인데 둘째만 그렇게 표시했다 | 사용자가 고른 선택지 설명에 "새 .md 훅 알림에 이 스킬도 열라고 덧붙인다"가 있었으므로 첫째는 결정 안이다. 지적은 「결정」 절에 그 문장이 없다는 점에서 맞다 |

거른 것은 없다. 열여섯 항목 모두 상대편 문장이 실제로 있었고 결과가 문서에서 따라 나왔다.

## 상충과 공백

렌즈끼리 같은 곳을 두고 반대로 말한 것은 없다. 5번은 세 렌즈가 같은 방향으로 짚었다.

세 렌즈가 모두 확인거리로 남긴 것은 훅 stdin의 `session_id` 존재였고, 메인 세션이 공식 문서로 확인했다. adversarial이 남긴 나머지 둘, 서브에이전트가 부모와 같은 `session_id`를 받는지와 서브에이전트의 편집에 훅이 도는지는, 같은 문서가 "서브에이전트의 도구 호출에도 같은 훅이 돌고 입력에 `agent_id`가 실린다"고 적어 답이 됐다. `session_id`가 같은지는 문서에 없지만 `agent_id`를 키에 더하면 같든 다르든 서브에이전트가 자기 넛지를 받는다.

adversarial이 발견으로 올리지 않고 적어 둔 것 하나는 카파시 세 절이 두 스킬에 다른 말로 두 벌 실리는 것을 잡는 검사가 없다는 점이다. 사용자 결정이라 발견이 아니다.

consistency가 남긴 확인거리는 plan이 생기면 참조 아홉 자리와 검사 열넷이 태스크로 대응되는지를 보라는 것이다.
