# 적대적 리뷰 반영 plan 리뷰

대상은 `docs/superpowers/plans/2026-09-30-adversarial-review-fixes.md` 하나다. 경로가 `plans` 아래라 plan 으로 구분했다. 렌즈 네 개(`lens-grounding`·`lens-consistency`·`lens-adversarial`·`lens-fit`)를 따로 실행했고, 원본은 같은 이름의 폴더에 있다.

렌즈를 한 번씩만 실행했다.

선행연구 렌즈는 붙이지 않았다. 대상이 plan 이고, review-specs 는 plan 에 선행연구 대조를 제안하지 않는다.

## 합친 지적

지적 42건을 합치면 서로 다른 지적은 아래 스물여섯 가지다. 괄호 안은 그 지적을 낸 렌즈다. 합치기 단계에서 근거 파일을 열어 인용이 실물과 맞는지 확인했고, 틀린 인용으로 걸러 낸 지적은 없다.

### 태스크 순서와 검증

- **Task 1 의 cat 단언** — hooks 전체에 `INPUT="$(cat)"` 가 없다는 단언을 Task 1 에서 넣지만 Stop 훅 두 파일은 Task 2 에서 지워져 Task 1 끝에 FAIL=0 을 채울 수 없다(grounding·consistency).
- **Task 2 의 README 단언** — hooks.json 이 `stop_gates.sh` 를 가리키는데 README 에 그 이름을 적는 일은 Task 8 에 있어 Task 2 끝에 README 단언이 실패한다(consistency).
- **태스크별 검증 범위** — 완료 조건은 전체 테스트인데 Task 1~5 는 테스트 파일 하나씩만 실행하고, Task 2 가 지우는 `spec_review_stop.sh` 를 `test_docs_drift.sh`(STOPH 105·110·111·607행)가 읽는다(consistency·grounding).
- **단계 중간 중단** — Task 1 Step 4 뒤, Task 2 Step 6 중간에 끊기면 알림 없이 꺼진 훅이 남는다. 삭제를 배선 교체보다 먼저 한다(adversarial).

### Stop 병합

- **금지어 검사 실패가 차단을 지운다** — 한 `set -e` 프로세스에서 `doc_word_gate_check` 의 mktemp·banned_parse 실패가 spec 차단 출력까지 없앤다(adversarial).
- **rev-parse 의 stderr 섞임** — `git rev-parse --show-toplevel 2>&1` 이 성공 때도 경고 줄을 root 에 섞어 cd 가 실패하고 게이트가 열린다(adversarial).
- **재개 때 세션 표시 재생성** — 표시가 사라진 재개·fork 세션에서 재개 시각으로 표시가 새로 생겨 중단 전 초안이 게이트에서 빠진다(adversarial). /clear 가 session_id 를 새로 내는지 확인하지 못했다(grounding).
- **공유 라이브러리 과설계** — `_spec_gate.sh`·`_doc_word_gate.sh` 는 소비자가 `stop_gates.sh` 하나뿐이다(adversarial).
- **git 실행 횟수 표기** — 주석은 두 번, domain-plugin 새 문구는 한 번이라 적지만 실제는 세 번이고, 합치기 전은 일곱 번이다(consistency·grounding).
- **REVIEW_GATE 단언** — 'spec 검사만 끈다' 단언이 차단이 꺼졌는지 보지 않는다(consistency).
- **저장소 자신 단언** — `DWSTOP` 을 합친 훅으로 바꾸면 '이 저장소 자신 → 무출력'이 작업 트리의 미리뷰 plan 에 따라 갈린다(consistency·grounding).
- **README 하드 게이트 설명** — 「차단되었을 때 푸는 법」의 Stop 하드 게이트 줄이 새 범위를 반영하지 않는다(grounding).

### 훅 입력과 갱신

- **read 의 성능 역전** — bash `read` 는 파이프를 한 바이트씩 읽어 큰 입력에서 cat 보다 느리다. 실측 50KB 62ms 대 30ms, 200KB 274ms 대 31ms, 300KB 407ms 대 32ms(adversarial·grounding).
- **시간 초과 반복** — 124 를 `update.stuck` 에 적지 않아 갱신이 늘 멈추는 PC 는 startup 마다 최대 120초를 기다린다(adversarial).
- **잠금 치우기 경합** — 낡은 잠금을 치우고 곧바로 잡는 두 걸음이라 두 창이 함께 잡을 수 있다(adversarial).
- **윈도우 timeout.exe** — 훅 PATH 에서 System32 의 timeout.exe 가 앞서면 종료 코드가 달라진다(adversarial·grounding, 확인 못 함).

### 스캐폴드와 테스트 픽스처

- **stderr 단언 탐색 범위** — ERR7·ERR10·ERR19 는 stderr 만 받는데 plan 은 grep 'orphan' 으로만 찾게 한다(grounding).
- **고아 마커 픽스처** — 여는 줄이 `# BEGIN disciplined-coder (managed — do not edit)` 가 아니라 경고가 나오지 않는다(grounding).
- **H38 이름 충돌** — `test_scaffold.sh` 335행에 H38 이 이미 있다(consistency·grounding).
- **Files 목록 불일치** — Task 5 는 `_ensure_autoupdate.sh` 40·56-57행을 적지만 그대로 두고 7행을 고친다. Task 3 은 Step 3 이 고치는 두 훅을 목록에 안 적었다(consistency).
- **97행 인용 범위** — 성공 갈래 본문은 98-102행이다(grounding·consistency).

### 스킬 문서

- **review-llm-calls 포인터** — `test_docs_drift.sh` 121·272행이 그 포인터를 요구하므로 Task 7 Step 9 의 합치기는 검사와 부딪힌다(grounding). 같은 파일 33행을 대상에서 뺀 것도 근거와 맞지 않는다(consistency).
- **「처분」 절 인용** — '상충과'는 그 절에 없고 '상충이나'·'상충 감지와'가 있으며, 100행에 '모호한 상충 판정'이 남는다(grounding·consistency).
- **묶음 수 식** — '대상 수 ÷ 9 올림'은 에이전트 10개 이하를 보장하지 않는다(consistency).
- **audit_verify.sh 주석** — 원본 이름 꼴을 바꾸면서 검사기 주석을 목록에서 뺐다(consistency).
- **스코프** — Global Constraints 에 대응하는 줄이 없는 변경이 여럿이고, '결정 12개'와 불릿 16개가 맞지 않는다(consistency).

### 형식과 문체

- **자리표시** — Task 1 Step 4 awk 본문, Task 2 Step 5 알림 문구, Task 4 Step 4 두 갈래 본문, Task 3 Step 4 msg 줄, Task 7 Step 2·3 의 문구가 실제 내용 대신 가리킴으로 적혀 있다(fit).
- **Interfaces 칸** — Task 8·9 에 없다(fit).
- **목록 말끝** — Task 7 Step 3 목록의 말끝이 섞여 있다(fit).
- **L1·L2 풀이** — 처음 나오는 곳에 풀이가 없다(fit).

## 둘 이상의 렌즈가 함께 잡은 지적

Task 1 의 cat 단언, git 실행 횟수, 저장소 자신 단언, read 의 성능 역전, 윈도우 timeout.exe, H38 이름 충돌, 97행 인용 범위, review-llm-calls 포인터, 「처분」 절 인용이 둘 이상의 렌즈에서 나왔다.

## 커버리지 공백

배정된 렌즈 네 개가 모두 결과 JSON 을 돌려주었다. 결과가 빠진 렌즈는 없다. 서로 반대로 판정한 짝도 없다.
