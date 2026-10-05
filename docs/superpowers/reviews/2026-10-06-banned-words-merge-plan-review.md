# 금지어 목록 원본 이전 plan 리뷰

검토 대상은 `docs/superpowers/plans/2026-10-06-banned-words-merge.md` 다. 경로가 `docs/superpowers/plans` 아래이므로
plan 으로 판정했고, 선행연구 렌즈는 plan 에 제안하지 않는다. 렌즈는 `lens-grounding`·`lens-consistency`·
`lens-adversarial`·`lens-fit` 을 Explore 에이전트로 하나씩 실행했다. 렌즈를 한 번씩만 실행했다. 원본 JSON 은 같은
이름의 폴더에 있다.

메인 세션은 렌즈를 실행하기 전에 plan 의 변환 스크립트와 검사 코드를 scratchpad 에서 실행했다. 실제 목록에서 위반이
나오지 않았고, 일부러 깨뜨린 사본마다 의도한 위반이 나왔다. 그 뒤 변환 스크립트의 문안을 고쳤으므로 grounding 이
지적한 대로 고친 문안의 출력은 실행되지 않았다.

## 병합한 지적

| 지적 | 잡은 렌즈 |
|---|---|
| Task 3 Step 2 의 기대 실패 목록에 근거 파일의 대구 한도 실패가 빠졌다 | grounding · consistency |
| Task 1·2 에 「변경 뒤 실행」 단계가 없어 Global Constraints 와 어긋난다 | consistency |
| Task 4 의 교체 범위 밖 46행 echo 가 남아 '대상:' 줄이 두 번 나온다 | grounding · consistency |
| 편집 규칙 파일의 절 첫 줄이 불릿이라 [첫 문장] 검사가 커밋 뒤 실패한다 | grounding |
| BANPROG 가 셀 안 백틱 짝 깨짐과 금지어와 같은 제외어를 놓친다 | adversarial |
| 근거 파일 변형 자기시험만 `|| true` 로 감싸지 않았다 | adversarial |
| 자기시험이 실제 목록 문구에 묶여 정상 편집에도 실패한다 | adversarial |
| Task 6 Step 2 의 기대값이 다른 태스크 세션에만 있다 | adversarial |
| spec 머리 안내 셋째 문장, README 41·80행, import-protocol 알림이 plan 에 빠졌다 | grounding · consistency |
| 행 번호가 앞 단계 뒤에 밀리고, 바꿀 문장이 두 줄에 걸쳐 있다 | grounding · consistency |
| grep 에 agent-principles.md 의 일반 예시가 남아 완료 조건에 맞지 않는다 | grounding |
| 문체: 칸 이름 혼용, '이 파일' 지칭, 주체 누락, '같은 디렉터리' 오독, 영어 열거값 풀이 없음, 개수 지칭, 커밋 제목 한 문장에 세 개념 | fit · consistency |

## 커버리지 공백

네 렌즈가 모두 결과를 돌려주었다. adversarial 은 Windows 에서 한국어 인자 전달을 메인 세션의 실행 보고에 기대고
다시 측정하지 않았다. grounding 은 `.claude/rules` 의 `paths` 키를 웹으로 다시 확인하지 않았다.

## 리뷰 뒤의 사용자 결정

리뷰 결과가 모이는 동안 사용자가 범위가 과하다고 지적했다(2026-10-06). 그래서 목록 형식 검사와 자기시험, 편집 규칙
파일을 빼고, 근거 파일을 `docs/korean-banned-words-evidence.md` 에 두기로 정했다.
