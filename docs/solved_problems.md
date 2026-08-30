# 해결된 문제 로그 (solved_problems) — 이 프로젝트 · 지시사항 색인

일을 시작하기 전에 아래 「지시사항 색인」의 줄을 훑고, 지금 하려는 작업에 걸리는 줄이 있으면 그 줄이 가리키는 본문 파일 하나만 연다. 걸리는 줄이 없으면 아무 파일도 열지 않는다.

이 레포에서 완결한 문제의 교훈 — 일을 시작할 때 걸리는 지시사항만 여기 두고 증상과 원인은 본문 파일에 둔다.
본문 파일은 append-only 이고 색인 줄은 그 본문을 따라 고친다. 본문을 고치거나 지울 때만 색인 줄도 함께 손댄다.
이 프로젝트에 한정된 교훈만 둔다 — 머신 전역은 PC solved, 보편은 디시플린 원칙으로(스코프 라우팅).

항목을 적는 형식은 이렇다.

- 이 파일은 색인이고 한 줄이 한 항목이다. 줄에는 지시사항만 적는다.
- 지시사항은 언제 걸리는지와 무엇을 하라는지를 한 문장에 담는다.
- 증상과 원인과 근거는 색인에 적지 않고 본문 파일에 적는다.
- 각 줄은 다음 줄에서 solved_problems/ 아래의 본문 파일 하나를 가리킨다.
- 본문 파일의 첫 줄은 그 지시사항과 같다.
- 아직 지시사항으로 못 고친 줄은 굵게 둔다. 고치면서 굵기를 벗긴다.
- 순서는 시간순이고 아래에 추가한다.
- 본문 파일을 고치거나 지우기 전에 사용자에게 묻는다.
- 사용자 요청으로 고치거나 지울 때는 색인 줄도 함께 고치거나 지운다.

## 지시사항 색인

- 경고나 린트를 없애는 수정이라도 손대기 전에 그 설정이 동작을 바꾸는지 domain-plugin 같은 해당 도메인 참고서를 먼저 연다.
  → solved_problems/2026-07-03-lint-fix-check-domain-ref.md
- 워크플로 스크립트의 문법을 검사할 때는 하니스처럼 async 함수로 감싼 뒤 node --check 에 넣는다.
  → solved_problems/2026-07-03-workflow-syntax-check-wrap.md
- 리뷰어를 백그라운드로 띄웠으면 결과가 올 때까지 마커를 달지 말고 차단 메시지에는 상태만 답한다.
  → solved_problems/2026-07-03-review-marker-wait.md
- 관리 영역을 갱신할 때는 기존 줄을 부분 수정하지 말고 마커 줄만 지운 뒤 다시 짓는다 — 본문 줄은 절대 지우지 않는다.
  → solved_problems/2026-07-27-managed-block-rebuild.md
- 레일을 이중화하기 전에 그 위험이 아직 살아 있는지 확인하고, 남길 레일은 압축 생존성으로 고른다 — 판정은 주입 전에 하고 grep -x 는 쓰지 않는다.
  → solved_problems/2026-07-27-dual-rail-check.md
- 오답노트는 미리 만들지 말고 적을 것이 생긴 시점에 만든다.
  → solved_problems/2026-07-27-solved-log-on-demand.md
- 기존 함수를 재사용하기로 정하기 전에 그 함수의 쓰기 경로를 끝까지 읽어 어느 줄이 대상 파일에 반영하는지 특정한다.
  → solved_problems/2026-07-28-read-write-path-before-reuse.md
- 표본이 적은 실측에서는 관측만 적고 인과는 주장하지 않는다 — 경쟁 설명이 같은 데이터를 설명하는지 먼저 센다.
  → solved_problems/2026-07-28-no-causation-small-sample.md
- 여러 줄 블록의 포함 검사는 grep -F 가 아니라 case 의 리터럴 부분일치로 짜고, 불릿 하나를 지운 픽스처로 뮤테이션 검증까지 돌린다.
  → solved_problems/2026-07-28-multiline-contains-check.md
- 워크플로를 고쳤는데 이름 호출이 옛 사본으로 막히면 scriptPath 로 캐시를 우회하고, 근본 원인인 CRLF 는 .gitattributes 에 *.js text eol=lf 를 더해 없앤다.
  → solved_problems/2026-08-13-workflow-scriptpath.md
- 한 줄 안에 둘이 함께 있는지 검사할 때는 그 행을 먼저 변수로 뽑아 그 안에서 확인하고, 그 문장을 반대로 뒤집어 FAIL 이 뜨는지 확인한 뒤 원복한다.
  → solved_problems/2026-08-13-same-line-check.md
- 여러 세션이 동시에 건드릴 수 있는 파일은 mktemp 와 mkdir 락으로 직렬화하고, 순차 멱등성 테스트는 이 동시 쓰기 충돌을 드러내지 못하므로 동시 실행 회귀 테스트를 따로 세운다.
  → solved_problems/2026-08-13-concurrent-file-write-lock.md
- 계약 테스트가 문구로 잡는 문장은 한 줄에 붙여 두고, 문서를 다듬은 뒤에는 문체만 고쳤더라도 계약 테스트를 돌린다.
  → solved_problems/2026-08-13-contract-anchor-one-line.md
- spec 과 plan 은 마커 없이 먼저 쓰고 훅이 뜨게 둔다 — 리뷰를 못 돌릴 사정이면 마커로 덮지 말고 문서에 적고 사용자에게 묻는다.
  → solved_problems/2026-08-16-write-spec-without-marker.md
- 머리말의 끝은 첫 항목 앞이 아니라 첫 구조 요소로 잡되, 도입 문장이 보이면 뒤따르는 목록 줄까지 머리말로 센다.
  → solved_problems/2026-08-16-preamble-boundary.md
- 허가나 예외에서 무엇을 빼는지는 범주어 말고 이름을 대서 적고, 그 계약 검사는 파일 전역이 아니라 해당 절만 뽑아 그 안에서 본다.
  → solved_problems/2026-08-16-name-the-exception.md
- 규칙을 어느 문서에 적을지는 그 절차에만 걸리는지 어디서나 걸리는지로 가른다 — 어디서나 걸리는 것은 상시 로드 원칙으로 올리고 스킬은 가리키기만 한다.
  → solved_problems/2026-08-16-rule-scope-routing.md
- 서브에이전트가 준 수치를 설계 문서에 적기 전에 그 값을 직접 다시 센다 — 실측이라고 단정하려는 값은 반드시 그렇게 한다.
  → solved_problems/2026-08-17-recount-subagent-numbers.md
- 산문에서는 개수를 세지 말고 집합으로 부른다 — 개수를 꼭 적어야 하면 그 자리를 테스트 앵커로 함께 건다.
  → solved_problems/2026-08-17-no-counts-in-prose.md
- 외부 목록을 들일지 정할 때는 항목이 겹치는지가 아니라 목적이 같은지를 먼저 본다 — 목적이 다르면 링크도 걸지 않는다.
  → solved_problems/2026-08-17-external-list-purpose-first.md
- 리뷰어에게는 관찰 목록만 주고 판정은 목적에 맡기며, 목록 밖의 방해를 반드시 적게 하는 칸을 필수로 둔다.
  → solved_problems/2026-08-17-purpose-over-checklist.md
- 정본의 산문을 고치기 전에 그 문구가 테스트 앵커인지 먼저 보고, 앵커였으면 검사의 뜻은 두고 앵커만 새 문구로 옮긴다.
  → solved_problems/2026-08-17-check-test-anchor-before-edit.md
- 복제를 지우기 전에 그 복제를 요구하는 검사가 있는지 먼저 보고, 있으면 검사의 뜻을 다시 읽어 뜻이 같게 바꾼다 — 검사를 지우는 것과 다르다.
  → solved_problems/2026-08-17-duplication-enforcing-test.md
- 낱말을 바꿀 때는 영어 철자만 찾지 말고 그 낱말의 흔한 직역어도 함께 찾는다 — 검색이 비었다는 것은 다 고쳤다는 증거가 아니다.
  → solved_problems/2026-08-18-search-translated-forms-too.md
- 문서가 갈래를 열거할 때는 코드가 갈래를 선언해 둔 자리에서 뽑고, 셀 자신이 없으면 개수를 박지 말고 소유자를 가리킨다.
  → solved_problems/2026-08-18-enumerate-from-code.md
- 효과를 수치로 주장할 때, 개입이 없으면 산출 자체가 없는 일이라면 대조군을 찾지 말고 그 산출을 곧 이득으로 센다.
  → solved_problems/2026-08-24-no-control-group-needed.md
- 리뷰어 렌즈의 규칙을 고칠 때는 본문과 레퍼런스 프롬프트를 한 커밋에서 같이 손보고, 그 규칙이 리뷰어용인지 띄우는 호출자용인지 먼저 가른다.
  → solved_problems/2026-08-25-lens-guard-in-prompt.md
- 긴 것을 한 문장으로 줄여 쓸 때는 원문에 처방이 몇 개인지 먼저 세고 그 수만큼 옮겼는지 확인하며, 다시 쓴 것은 읽기 전용 서브에이전트에게 원문과 나란히 대조받는다.
  → solved_problems/2026-08-26-count-prescriptions-before-summarizing.md
- 신호 문구가 무엇을 센다고 밝혔으면 문구가 있는지만 보지 말고 그 값이 맞는지 픽스처로 고정하고, 할 일이 서로 다른 두 가지를 한 숫자로 함께 세고 있지 않은지 묻는다.
  → solved_problems/2026-08-26-assert-the-counted-value.md
- 이 레포의 check 에 명령을 넣을 때는 달러 괄호를 역슬래시로 escape 해 지연시키고, 새 검사는 반드시 실패를 한 번 보고 나서 통과시킨다.
  → solved_problems/2026-08-26-defer-command-substitution-in-check.md
- 낡은 락을 빼앗을지는 내가 기다린 시간이 아니라 그 락이 잡혀 있던 시간으로 정하고, 재고 빼앗고 잡는 세 걸음을 문지기 락 안에 함께 넣는다.
  → solved_problems/2026-08-27-stale-lock-steal-must-be-gated.md
- 동시성 결함은 결과 파일이 아니라 임계 구역 출입 자체를 재고, 실패를 일으키려고 만든 픽스처는 그 실패가 실제로 났는지 먼저 확인한다.
  → solved_problems/2026-08-27-measure-critical-section-entry.md
- 문서 SSOT를 계약 테스트로 지킬 때는 같은 문구가 두 곳에 있는지 보지 말고, 소유자에는 규칙 문구가 있고 가리키는 쪽에는 그 문구가 없으면서 소유자 이름이 있는지를 검사한다.
  → solved_problems/2026-08-30-drift-test-forced-copying.md
- 렌즈 문서를 고칠 때는 본문과 레퍼런스 프롬프트를 같은 걸음에서 고치고, 실제로 도는 것은 프롬프트이므로 축 이름과 지시가 양쪽에 다 있는지 계약 테스트로 붙든다.
  → solved_problems/2026-08-30-lens-prompt-body-drift.md

- 리뷰가 짚어 준 사례를 고칠 때는 그 모양을 레포 전체에서 세어 0이 되는지 확인하고, 0이 아니면 남은 것도 같은 걸음에서 고친다.
  → solved_problems/2026-08-30-fix-hit-only-visible-cases.md

- 문서가 맞는지 보는 계약 테스트는 문구의 존재를 요구하지 말고 코드나 다른 문서에서 값을 뽑아 대조한다.
  → solved_problems/2026-08-30-check-pins-wrong-wording.md
