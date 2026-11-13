# v2 재건축 0~3단계 구현 계획

> **에이전트 작업자용:** 필수 하위 스킬은 `superpowers:subagent-driven-development`(권장) 또는 `superpowers:executing-plans` 다. 태스크마다 순서대로 실행하고, 단계는 체크박스(`- [ ]`)로 추적한다.

**목표:** spec 「이행 순서」의 0~3단계(기준 버전 고정, 핵심 계약 테스트, 상시 지시 교체, 상시 지시 검증)를 끝내 v2 상시 지시가 v1 보다 나은지 숨긴 턴 세트로 판정한다.

**구성:** 0단계는 보존 태그·결정 기록·숨긴 턴 120개를 만든다. 1~2단계는 저장소 안의 bash 계약 테스트(`scripts/test_*.sh`)와 원칙·리마인더·금지어 상시 보기를 바꾼다. 3단계는 저장소 밖 기존 재현·판정 도구(`%USERPROFILE%\.dc-eval\`)를 복사해 고친 도구로 생성·판정하고, 결과 수치만 참고서에 기록한다.

**기술:** bash(Git Bash)·awk·python 3, `claude -p`(Claude Code 2.1.x), 모델 `claude-opus-5-5`.

**Spec:** `docs/superpowers/specs/2026-11-13-v2-rebuild-design.md`(리뷰 기록 `docs/superpowers/reviews/2026-11-13-v2-rebuild-review.md`). 실행자는 이 계획과 spec 을 함께 읽는다.

**범위:** 0~3단계만 다룬다. 4단계(훅 정리) 이후는 3단계 결과에 따라 달라지므로(두 번 미달이면 진행하지 않는다) 3단계 판정 뒤 별도 plan 으로 쓴다.

## Global Constraints

- 원칙 작업의 생성과 판정은 `claude-opus-5-5` 만 쓴다. 결과 파일의 `models` 가 `["claude-opus-5-5"]` 가 아니면 그 실행을 멈추고 원인을 찾는다(메모리 `principle-work-opus-only`).
- 서브에이전트는 동시 4개까지, 재현 생성은 동시 3개(`ThreadPoolExecutor(3)`)까지다. 생성과 판정을 동시에 실행하지 않는다(동시 `claude -p` 프로세스 3개 이하).
- push 하지 않는다(태그 push 포함). git 의 `user.name`·`user.email` 을 설정하지 않는다. `kofia.or.kr` 에 접속하지 않는다.
- 실제 대화가 든 파일(턴 목록, 답, 판정, 판독 결과)은 저장소에 넣지 않는다. 저장 위치는 `%USERPROFILE%\.dc-eval\` 아래이고, 판독 페이지만 `docs/html-reports/`(`.gitignore` 9행에 등록된 폴더)에 둔다.
- 계약 테스트는 FAIL=0 이고 기대 개수를 숫자로 박지 않는다. 고친 뒤에는 저장소 `CLAUDE.md` 「변경 뒤 실행」의 동시 실행 명령과 `claude plugin validate ./`(`Validation passed`)를 실행한다. 단계 끝의 FAIL=0 은 그 단계까지 쓴 검사에 적용한다.
- 단계마다 커밋한다. 커밋 메시지는 한국어로 쓰고 끝에 아래 두 줄을 붙인다.
  `Co-Authored-By: Claude Opus 5.5 <noreply@anthropic.com>`
  `Claude-Session: https://claude.ai/code/session_01VjrV5UxDSPWWUxyS7m25jP`
- 원칙 본문과 리마인더 세 줄은 spec 「새 에이전트원칙 초안」·「매 턴 리마인더」의 코드 블록을 글자 그대로 옮긴다.
- 리뷰·결정 기록은 커밋하면 다음 세션부터 읽기 전용으로 봉인된다. 결정 기록은 커밋 전에 완성한다.
- OAuth 구독으로 실행하는 모든 `claude -p` 호출(생성, 숨긴 세트 분류, 판정)은 업무 시간(평일 09:00~18:00) 밖에 몰아 실행한다. 출처는 spec 「위험」 표의 구독 한도 소진 대응("생성은 업무 시간 밖에 몰아 실행한다")이고, 시간 경계값과 분류·판정까지 넓힌 범위는 이 계획이 정했다.
- 판정 단가는 기존 도구 실측(judge_pair 틀 순서 교차 판정 한 번 약 0.116달러 = 호출당 약 0.058달러, 보정 위반 판정 한 건 약 0.063달러)으로 계산하고, 예상 합계와 누적 `total_cost_usd` 를 Task 8 Step 3(첫 판정 직후), Task 9 Step 3(위반 판정 단가 확인), Task 12 Step 3(재시험 직전)에서 확인한다. 예상 합계가 80달러를 넘을 것 같으면 실행을 멈추고 비용과 함께 사용자에게 제안한다.
- 판독 페이지는 저장소 `CLAUDE.md` 「판독 페이지」를 따른다(두 답 좌우 배치와 함께 스크롤·좁은 화면은 위아래, 답 원문 마크다운 렌더링, 사용자 메시지 말풍선, 지적 문장과 판정 근거 문장의 두 색 형광 표시, 판정 점수와 근거를 답보다 먼저 보이고 사용자가 같은 단계로 확인·수정).
- 판정 인용문(`x_quotes`·`y_quotes`·`note`)과 대화 원문은 저장소 문서에 적지 않는다. 저장소에는 집계 수치와 저장소 밖 결과 위치만 적는다.
- 결과 파일(답, 판정, 분류)은 같은 폴더의 임시 이름에 쓴 뒤 `os.replace` 로 이름을 바꾼다. 다시 실행할 때 생략하는 조건은 "파일이 있고 JSON 으로 읽히며 필수 키(답은 `response`, 판정은 `ab`·`ba` 의 `score`)가 비어 있지 않다"이다.

**spec 과 다른 점(실행 전 알 것)**

- **판정 인증:** 기존 판정 도구(`calib\judge_pair.py`·`judge_v3.py`)는 API 키가 아니라 OAuth 토큰(`CLAUDE_CODE_OAUTH_TOKEN`)으로 실행하고 `total_cost_usd` 를 기록한다. spec 「검증 계획과 비용」은 판정을 API 키로 실행한다고 적었다. 이 계획은 도구를 그대로 쓰고 `total_cost_usd` 합계를 비용 기준으로 삼는다.
- **판정 단가:** 지적 턴에 쓰는 judge_pair 틀의 실측(`calib\pair\` 18호출)은 호출당 0.058달러, 순서 교차 한 번 0.116달러로 spec 의 0.087달러보다 높다. 보정 위반 판정(`calib\v3\` 572건)은 0.063달러로 spec 과 같다. 이 계획의 비용 계산은 실측값을 쓴다.
- **핵심 계약 검사:** spec 1단계는 핵심 계약 검사를 새로 쓴다고 적었다. 이 계획은 현행 테스트에 이미 있는 기록 봉인·settings 백업·읽기 전용 차단·설치 안전·갱신 잠금 검사를 재사용해 `# 핵심 계약:` 표시만 달고, superseded 는 `supersedes:` 줄 기반 검사를 추가한다. spec 은 경로 고정 superseded 검사를 데이터 기반 검사로 바꾼다고 했지만, `supersedes:` 줄이 아직 없어 바꾸면 이미 표시가 달린 옛 spec(2026-08-16 review-layer-redesign, 2026-07-05 nested-orchestration)을 지키는 검사가 없어지므로 경로 고정 검사를 남긴다.
- **결함 주입 방법:** 갱신 잠금은 spec 표의 "잠금 확인 줄을 지운다" 대신 `got=0` 을 `got=1` 로 바꾼다. 확인 줄(`elif mkdir "$lock"`)만 지우면 `if` 문이 깨져 스크립트가 문법 오류로 끝나고, 그 실패는 잠금 계약이 아니라 문법을 시험하게 된다. 나머지 결함은 spec 표와 같다.
- **상시 보기 분량:** spec 은 "현행 원본 표로 만든 상시 보기 1,943자"라고 적었고 어떤 줄을 넣었는지는 적지 않았다. 이 계획의 상시 보기는 제목, 적용 범위 제목, 행 줄, 「표로 적을 수 없는 규칙」의 규칙 줄을 넣는다. 계획을 쓸 때 저장소 밖에서 만든 시제품은 2,444자였다. Task 4 Step 10 에서 실측하고 Task 11 Step 4 에서 참고서에 기록한다. 완료 기준(원칙 사본과 상시 보기 합계가 현행 9,600자보다 적다)은 실측값으로 판정한다.
- **규칙 줄의 금지어:** 「표로 적을 수 없는 규칙」의 규칙 줄은 작은따옴표 예시로 금지어(`정할 일`·`돈다`)를 포함해, spec 의 지시문 금지어 검사(백틱 밖 금지어 없음)와 부딪친다. 이 계획은 그 예시를 백틱으로 바꾼다.

## Review Focus

- **CRLF 원본 표:** 이 PC 는 `core.autocrlf=true` 다. 원본 표가 CRLF 로 체크아웃돼도 상시 보기는 LF 만 내고 LF 원본과 같은 내용이어야 한다(Task 4 `test_hooks.sh` 검사).
- **원본 표가 없거나 행이 없음:** 상시 보기를 만들지 못하면 PC 의 옛 사본을 빈 파일로 덮어쓰지 않고 오류 한 줄을 내며 나머지 셋업은 계속한다(Task 4 `test_scaffold.sh` 검사).
- **적용 범위 제목 없는 행:** 범위 제목 앞에 있는 행도 상시 보기에서 빠지지 않는다(Task 4 픽스처 검사).
- **없는 파일을 가리키는 supersedes 줄:** 대상 파일이 없으면 통과하지 않고 실패한다(Task 3 픽스처 검사).
- **재현할 수 없는 턴:** 원본 세션이 없거나 부모 연결이 끊긴 턴은 선정 단계에서 빼고, 생성 오류 턴은 한 번 다시 실행한 뒤에도 실패하면 판정 대상에서 빼고 수를 보고한다(Task 2 확인, Task 9 확인).

---

## 파일 구조

| 파일 | 변경 내용 |
|---|---|
| `docs/superpowers/decisions/2026-11-13-v2-rebuild.md` | 신설. v2 결정과 2026-11-13 기록 정정 |
| `scripts/test_docs_drift.sh` | `supersedes:` 줄 기반 검사 추가(경로 고정 검사 유지), 원칙 ID 근거 절 한 방향 검사, 상시 보기 행 검사, 지시문 금지어 검사. 원칙에 묶인 v1 검사 삭제 |
| `scripts/test_scaffold.sh` | 상시 보기 사본 검사, 원칙 포인터·옛 사본 갱신 검사 수정, 핵심 계약 표시 |
| `scripts/test_hooks.sh` | `banned_view` 픽스처 검사, 리마인더 검사 수정, 핵심 계약 표시 |
| `hooks/_banned_words.sh` | `banned_view` 추가(표를 읽는 파서는 이 파일 하나로 유지) |
| `scripts/scaffold.sh` | PC 금지어 사본으로 원본 대신 상시 보기를 쓴다 |
| `korean-banned-words.md` | 설명 문단 축소, 「꺼 둔 항목」 이동, 규칙 줄의 예시를 백틱으로 |
| `docs/korean-banned-words-evidence.md` | 「꺼 둔 항목」·「분류 설명」 받기 |
| `agent-principles.md` | spec 초안으로 교체 |
| `docs/domain-discipline.md`·`docs/domain-korean.md` | 머리 문단 수정, `## v2 조항` 신설, v1 절을 `## v1 조항 근거` 아래로 이동 |
| `hooks/reply_reminder_userpromptsubmit.sh` | 리마인더 세 줄 교체(끄는 변수는 4단계에서 지운다) |
| 저장소 밖 `%USERPROFILE%\.dc-eval\replay\turns\` | `build_pool.py`·`label_pool.py`·`pick_hidden.py`, 숨긴 세트 파일 |
| 저장소 밖 `%USERPROFILE%\.dc-eval\replay\` | `replay6.py`(replay5 복사·수정), `count_banned.py`, `report_hidden.py`, `gen_reading_v5.py`, `banlist-v1\`(금지어 행 파일), `V2_REV.<n>.txt`(v2 리비전마다 한 파일) |
| 저장소 밖 `%USERPROFILE%\.dc-eval\calib\` | `judge_hidden.py`(judge_pair·judge_brev 재사용), `judge_v3h.py`(judge_v3 복사·수정) |

---

### Task 1: 기준 버전 고정과 결정 기록 (0단계)

**Files:**
- Create: `docs/superpowers/decisions/2026-11-13-v2-rebuild.md`

**Interfaces:**
- Produces: 태그 `archive/v1-final`(Task 7 의 `rev_of('v1')` 이 이 태그를 돌려준다), 결정 기록 경로(Task 3 결함 주입이 지운다).

- [ ] **Step 1: 태그를 단다**

v2 코드 변경 전 HEAD 에 단다. 태그가 이미 있으면 다시 만들지 않는다.

```bash
cd /d/projects/disciplined-coder
git rev-parse -q --verify refs/tags/archive/v1-final || git tag archive/v1-final HEAD
```

- [ ] **Step 2: 태그를 확인한다**

Run: `git rev-parse 'archive/v1-final^{commit}' && git diff --stat archive/v1-final 9c52bdfe -- . ':!docs/superpowers'`
Expected: 커밋 해시 한 줄, diff 출력 없음(태그와 9c52bdfe 의 차이는 `docs/superpowers/` 밖에 없다).

- [ ] **Step 3: 결정 기록을 쓴다**

절은 「결정」·「정정」·「다음 단계」다. 「결정」에는 v2 재건축 채택(spec 경로와 리뷰 기록 경로), 2026-11-13 사용자 승인("전부 진행하자", 계획 전체 비용 50~80달러), 2026-10-18 묶음 비교 금지 지시를 거둔다는 사실, 근거 측정 1~3 의 수치(spec 「목적」의 29개 +0.14/p=0.35, 한 줄 추가 20·3/p=0.0002/880→713자, 110턴 48→43)를 적는다. 「정정」에는 spec 「결정 기록 정정」의 세 항목을 적는다. 첫째, `2026-11-13-prompting-guide-clauses.md` 「함께 닫은 항목」이 2026-11-11 조항 분류를 닫았다고 한 문장은 보정 전 판정자의 결과라 틀렸다. 둘째, 보정 판정자로 다시 판정한 110턴 결과는 지금 리마인더 위반 48→43(유의하지 않음)이고, 줄별 고쳐짐·나빠짐은 결정 질문 3·0, 요청한 변경만 3·0, 확인 안 한 상태를 사실처럼 쓰지 않기 2·0, 압축하지 않기 2·0, 지시에 없는 파일까지 먼저 확인 0·2, 직역투 0·1 이다. 셋째, 조항 분류 작업은 v2 재건축이 대신한다. 같은 기록이 닫은 "가이드 후보 R01~R13"과 "compact 직후 리마인더를 닫는다"도 보정 전 판정이나 측정 없이 닫은 항목이라고 적는다. 「다음 단계」에는 0~3단계 plan 경로와 3단계 채택 규칙(spec 「시험 체계」 채택 규칙)을 적는다.

- [ ] **Step 4: 기록 검사를 실행한다**

Run: `bash scripts/test_docs_drift.sh 2>&1 | grep -E 'FAIL|PASS='`
Expected: `PASS=… FAIL=0`(새 기록은 추가 `A`/`??` 로 보여 기록 검사를 통과한다).

- [ ] **Step 5: 커밋한다**

```bash
git add docs/superpowers/decisions/2026-11-13-v2-rebuild.md
git commit -m "v2 재건축 결정과 11-13 기록 정정을 적는다" -m "Co-Authored-By: Claude Opus 5.5 <noreply@anthropic.com>
Claude-Session: https://claude.ai/code/session_01VjrV5UxDSPWWUxyS7m25jP"
```

### Task 2: 숨긴 턴 세트 선정 (0단계, 저장소 밖)

**Files (모두 저장소 밖, 커밋하지 않는다):**
- Create: `%USERPROFILE%\.dc-eval\replay\turns\build_pool.py`, `label_pool.py`, `pick_hidden.py`
- 출력: `pool-2026-11-13.jsonl`, `pool-labels.jsonl`, `turns-hidden1-2026-11-13.jsonl`, `hidden1-ids.txt`(같은 폴더)

**Interfaces:**
- Consumes: `%USERPROFILE%\.dc-eval\wants\msgs.jsonl`(942개, 키 `proj`·`sess`·`ts`·`user`·`prev`), `wants\out1.md`~`out4.md`·`synthesis.md`, `wants\chunk1.jsonl`~`chunk3.jsonl`, 개발 세트 `replay\turns\turns-2026-11-11.jsonl`(113턴)·`turns-brevity-2026-11-13.jsonl`(30턴), `calib\judge_pair.py` 의 `ask(q) -> dict`·`env(cfg)`.
- Produces:
  - `python label_pool.py <지적 목표> <지적없음 목표>`: `pool-labels.jsonl` 에 이미 분류된 후보는 다시 묻지 않고(이어받기), 기존 분류까지 합쳐 두 목표를 채우면 멈춘다.
  - `python pick_hidden.py <세트 번호> <지적 수> <지적없음 수>`: 다른 번호의 `turns-hidden*-2026-11-13.jsonl` 에 든 턴을 빼고 고른다.
  - `turns-hidden<번호>-2026-11-13.jsonl` 의 행 `{idx, kind, session_file, cwd, ts, ask_uuid, correction_uuid, ask_text, user, why, decision_point, clauses}`. `kind` 는 `지적`·`지적없음`, `idx` 는 세트 번호 × 1000 + 1001 부터(세트 1 은 3001~), `correction_uuid` 는 질문 다음의 실제 사용자 메시지 uuid(replay 의 `conversation()` 이 그 앞 메시지를 질문으로 되살린다), `clauses` 는 빈 목록, `지적없음` 턴의 `why`·`decision_point` 는 빈 글이다. Task 7~12 가 이 파일을 읽는다.

- [ ] **Step 1: out 파일 `#번호` 의 기준을 확인한다**

이 계획을 쓸 때 확인한 사실은 이렇다. `out3.md` 는 머리에 "메시지 번호(#N)는 파일의 줄 순서(0부터)"라고 밝혔다. `out1.md` 에는 `#번호` 가 없다. `out2.md` 는 `#번호` 를 쓰지만 기준을 적지 않았다. `out4.md` 는 chunk 가 아니라 문서에서 뽑은 요구다. `out2.md` 에서 `#번호` 와 백틱 인용이 같은 줄에 있는 항목을 최대 10개 골라, 인용 조각이 `chunk2.jsonl` 의 N 번째 줄(0부터)과 N−1 번째 줄 중 어느 쪽 `user` 에 들어 있는지 센다.
Expected: 한쪽이 과반이면 그 기준(0부터 또는 1부터)을 `build_pool.py` 에 적는다. 판정할 수 없으면 `out2.md` 의 `#N` 마다 N−1·N·N+1 세 줄을 모두 뺀다. 결과는 `build_pool.py` 머리 주석에 한 줄로 남긴다.

- [ ] **Step 2: `build_pool.py` 를 쓴다**

`wants\extract.py` 의 `real()` 규칙으로 `~/.claude/projects/*/*.jsonl`(경로에 `eval-tmp`·`dc-eval` 이 든 파일 제외)의 메인 세션 사용자 메시지를 파일 순서로 읽고, 이웃한 두 메시지 (a, b)마다 후보 한 행 `{proj, sess, ts, session_file, cwd, ask_uuid, correction_uuid, ask_text, user, prev}` 를 낸다. a 가 `msgs.jsonl` 에 있는 메시지(키 `(proj, sess, ts[:16], 붙여넣은 글을 치환한 user[:1500])`)일 때만 남긴다. 아래 후보는 뺀다.

  - 개발 세트: a 나 b 의 uuid 가 두 개발 세트 파일의 `correction_uuid` 중 하나이거나, a 의 글이 brevity 세트의 `ask_text` 와 같은 후보. 판정하지 못한 턴도 목록에 있으면 뺀다.
  - 인용 메시지: `out1.md`~`out4.md`·`synthesis.md` 의 백틱 구간을 `...`·`…` 로 나눈 조각 중 공백을 하나로 줄여 6자 이상이고 `/`·`\`·파일 확장자(`.md`·`.jsonl`·`.py`·`.sh`·`.json`)가 없는 조각이 a 나 b 의 글(공백 정리 뒤)에 들어 있는 후보. 또 머리 5줄에 `chunkN.jsonl` 을 적은 out 파일의 `#번호` 가 Step 1 의 기준으로 가리키는 `chunkN.jsonl` 행의 메시지가 a 나 b 인 후보.
  - 재현 불가: a 가 `<` 로 시작하거나 `parentUuid` 가 없는 후보, b 가 없는(세션의 마지막 메시지) 후보, b 에서 부모(`parentUuid`, 없으면 `logicalParentUuid`)를 따라 올라가며 replay5 `real_user()` 규칙(`^\s*<` 와 `<system-reminder>` 제외)으로 처음 만나는 사용자 메시지가 a 가 아닌 후보.

출력은 `pool-2026-11-13.jsonl`(임시 이름에 쓴 뒤 `os.replace`)이고, 끝에 남은 후보 수와 사유별 제외 수를 출력한다.

- [ ] **Step 3: 실행해 제외가 동작했는지 확인한다**

Run: `cd "$USERPROFILE/.dc-eval/replay/turns" && python build_pool.py`
Expected: 사유별 제외 수(개발 세트·인용·재현 불가)가 모두 0 보다 크고, 남은 후보가 수백 개다. 개발 세트 uuid 가 출력 파일에 없는지 `python -c` 한 줄로 대조해 0 건이다.

- [ ] **Step 4: `label_pool.py` 를 쓴다**

후보를 `random.Random(20261113)` 로 섞고, `pool-labels.jsonl` 에 이미 있는 후보 키는 빼고, 20개씩 묶어 `judge_pair.ask()` 로 Opus 5.5 에 분류를 묻는다(동시 3개). 판정 지시의 정의는 이렇다. b 가 직전 Claude 답이나 행동의 문제를 지적하면(정정, 불만, 답이 불분명해 같은 내용을 다시 질문, 범위를 넘은 작업 지적, 진행 방식 교정) `지적`, 새 지시·승인·새 주제 질문·정보 제공이면 `지적없음`, 판단이 어려우면 `애매` 다. 지적이면 `decision_point` 를 `대화 답 작성`·`범위 결정`·`판단 위임`·`단계 넘김`·`전제 사용`·`산출물 작성`·`지시문 작성`·`비가역 행동` 중 하나로, `why` 를 지적의 요지 한 문장으로 받는다. 응답은 `{"items":[{"i":0,"label":"지적","decision_point":"…","why":"…"}]}` 이다. 각 항목에 a 의 글 앞 1,500자, a 직전 Claude 답 끝 600자(`prev`), b 의 글 앞 1,500자를 넣는다. 묶음 결과는 묶음마다 `pool-labels.jsonl` 에 한 줄씩 덧붙이고 바로 `flush` 한다. 다시 읽을 때 JSON 으로 읽히지 않는 줄은 버린다. 기존 분류와 합쳐 두 목표를 모두 채우면 새 묶음을 보내지 않는다. 행에는 후보 키, label, decision_point, why, models, cost 를 둔다. 끝에 이번 실행과 누적의 `cost` 합계를 출력한다.

`judge_pair` 는 모듈을 읽을 때 `sys.argv[1:]` 를 판정 쌍으로 해석하므로, 읽기 전에 `sys.argv = sys.argv[:1]` 로 두고 읽은 뒤 되돌린다.

- [ ] **Step 5: 분류를 실행한다(업무 시간 밖)**

Run: `python label_pool.py 60 60`
Expected: 모든 행의 `models` 가 `claude-opus-5-5` 하나이고 `지적`·`지적없음` 이 각각 60 이상이다. 같은 명령을 다시 실행하면 새 묶음을 보내지 않고 누적 수만 출력한다(이어받기 확인).

- [ ] **Step 6: `pick_hidden.py` 를 쓴다**

`label_pool.py` 와 같은 시드로 섞은 순서에서 `지적` 과 `지적없음` 을 인자 개수만큼 앞에서부터 고른다. 다른 번호의 숨긴 세트 파일에 든 턴은 뺀다. 개수가 모자라면 아무 파일도 쓰지 않고 모자란 수를 출력한 뒤 1 로 끝난다. `turns-hidden<번호>-2026-11-13.jsonl` 과 `hidden<번호>-ids.txt`(`idx`·`kind`·세션 파일 이름·`ask_uuid`·`correction_uuid` 를 탭으로 이은 줄)를 임시 이름에 쓴 뒤 이름을 바꾼다. ID 파일에는 대화 원문을 넣지 않는다.

- [ ] **Step 7: 개수와 겹침을 확인한다**

Run: `python pick_hidden.py 1 60 60 && wc -l turns-hidden1-2026-11-13.jsonl && cut -f2 hidden1-ids.txt | sort | uniq -c`
Expected: `120`, `지적` 60·`지적없음` 60. 개발 세트 uuid 와 겹치는 행 0.

### Task 3: 핵심 계약 검사와 결함 주입 (1단계)

spec 「테스트가 지킬 핵심 계약」 표의 계약 중 기록 봉인·settings 백업·읽기 전용 차단·설치 안전·갱신 잠금은 현행 테스트에 검사가 이미 있고, superseded 표시는 경로 고정 검사(2026-08-16 review-layer-redesign, 2026-07-05 nested-orchestration)가 있다. 이 태스크는 경로 고정 검사를 남긴 채 `supersedes:` 줄 기반 검사를 추가하고, 기존 검사에 `# 핵심 계약:` 표시를 달아 이후 단계의 테스트 정리에서 지워지지 않게 한 뒤, 표의 계약마다 결함 주입으로 실패를 확인한다(「spec 과 다른 점」 핵심 계약 검사).

**Files:**
- Modify: `scripts/test_docs_drift.sh`(306~310행 경로 고정 superseded 검사 뒤에 새 검사 추가, 기록 봉인 블록 표시)
- Modify: `scripts/test_scaffold.sh`(`[marketplace-autoupdate]`·`[user-content-preserved]`·`[home-resolution]`·`[project-untouched]`·`[stale-lock]`·`[lock-owner]`·`[lock-timeout]`·`[strip-fail]`·`[install-current]` 잠금 검사 표시)
- Modify: `scripts/test_hooks.sh`(`[readonly-pre …]` 블록 표시)

**Interfaces:**
- Produces: `superseded_missing <specs 폴더>` → 줄마다 `<spec 파일 이름> → <대상 파일 이름>`. 머리 12줄에서 `^>?[[:space:]]*supersedes:` 로 시작하는 줄의 백틱 `*.md` 이름마다, 같은 폴더에 그 파일이 없거나 그 파일 머리 12줄에 `superseded`(대소문자 무시)가 없으면 낸다. CR 은 지우고 읽는다. 7단계가 이 함수를 그대로 쓴다.

- [ ] **Step 1: 실패하는 검사를 쓴다**

306~310행의 경로 고정 검사 두 개(`옛 spec 에 superseded 표시가 있다`, `옛 nested 설계에 superseded 표시가 있다`)는 그대로 두고, 그 블록 첫 검사 위에 `# 핵심 계약: superseded 표시 — 결함 주입: 대체된 spec 하나의 표시를 지운다` 를 단다. 그 뒤에 아래 검사를 추가한다. 픽스처는 `SUP_FX="$(mktemp -d)"`(`TMPDIR` 이 `$TEST_TMP` 라 끝나면 함께 지워진다)에 `new.md`(첫 줄 ``> supersedes: `old.md`, `gone.md` ``)와 `old.md`(표시 없음)를 만든다.

```bash
echo "[supersedes 줄이 가리키는 문서에 superseded 표시]"
check "supersedes 줄을 읽는 검사가 표시 없는 대상과 없는 파일을 잡는다" "[ \"\$(superseded_missing \"\$SUP_FX\" | wc -l | tr -d ' ')\" = 2 ]"
check "표시를 단 대상은 넘긴다" "printf '> **superseded**\n' > \"\$SUP_FX/old.md\" && [ \"\$(superseded_missing \"\$SUP_FX\")\" = 'new.md → gone.md' ]"
check "supersedes 줄이 가리키는 문서마다 superseded 표시가 있다" "[ -z \"\$(superseded_missing \"\$HERE/docs/superpowers/specs\")\" ]"
```

- [ ] **Step 2: 실패를 확인한다**

Run: `bash scripts/test_docs_drift.sh 2>&1 | grep -E 'superseded|PASS='`
Expected: `superseded_missing: command not found` 로 `supersedes 줄을 읽는 검사가 표시 없는 대상과 없는 파일을 잡는다`·`표시를 단 대상은 넘긴다` 가 FAIL, 경로 고정 검사는 PASS.

- [ ] **Step 3: `superseded_missing` 을 같은 파일 위 검사 앞에 구현한다**

`head -12 | tr -d '\r'`, `grep -oE '`[^`]+\.md`'` 로 이름을 뽑는다. v2 spec 의 3행은 `> **상태:**` 로 시작하므로 읽지 않고, 4행 `> 대체 예정:` 도 읽지 않는다.

- [ ] **Step 4: 통과를 확인한다**

Run: `bash scripts/test_docs_drift.sh 2>&1 | grep -E 'FAIL|PASS='`
Expected: `FAIL=0`.

- [ ] **Step 5: 나머지 핵심 계약에 표시를 단다**

각 블록 첫 검사 위에 `# 핵심 계약: <이름> — 결함 주입: <방법>` 한 줄을 단다. 이름은 spec 표의 계약 이름이고, 방법은 Step 8 의 결함과 같게 적는다(갱신 잠금은 「spec 과 다른 점」의 방법). 표시를 단 테스트 파일마다 머리 주석에 "`# 핵심 계약:` 표시가 달린 검사는 v2 정리에서 지우지 않는다" 한 줄을 추가한다.

- [ ] **Step 6: 전체 테스트와 validate 를 실행한다**

Run: 저장소 `CLAUDE.md` 「변경 뒤 실행」의 명령, 그다음 `claude plugin validate ./`
Expected: `ALL PASS`, `Validation passed`.

- [ ] **Step 7: 커밋한다**

```bash
git add scripts/test_docs_drift.sh scripts/test_scaffold.sh scripts/test_hooks.sh
git commit -m "핵심 계약 검사를 표시하고 supersedes 줄 기반 검사를 추가한다" -m "Co-Authored-By: Claude Opus 5.5 <noreply@anthropic.com>
Claude-Session: https://claude.ai/code/session_01VjrV5UxDSPWWUxyS7m25jP"
```

- [ ] **Step 8: 결함을 클론에 주입한다**

작업 트리는 건드리지 않고, 결함마다 `git clone --local` 로 만든 임시 클론에서 한 번 바꾸고 해당 테스트를 실행한 뒤 지운다. 먼저 수정하지 않은 클론에서 대상 테스트가 모두 FAIL=0 인지 확인하고, 하나라도 실패하면 결함 주입을 하지 않고 그 실패부터 고친다. 치환할 글이 정확히 한 번 있지 않으면 그 결함은 멈춘다. 판정은 기대 검사 이름의 `FAIL:` 줄이 나오는지로 한다.

```bash
REPO=/d/projects/disciplined-coder
mkclone() { local d; d="$(mktemp -d)"; git clone -q --local "$REPO" "$d/r" && printf '%s' "$d"; }
d="$(mkclone)"; base_ok=1
for t in test_docs_drift.sh test_scaffold.sh test_hooks.sh; do
  ( cd "$d/r" && bash "scripts/$t" >/dev/null 2>&1 ) && echo "기준 통과 $t" || { echo "기준 실패 $t"; base_ok=0; }
done; rm -rf "$d"
[ "$base_ok" = 1 ] || echo "기준 실패가 있어 결함 주입을 멈춘다"
inject() {  # $1=결함 이름 $2=테스트 스크립트 $3=고칠 파일 $4=찾을 글 $5=바꿀 글 $6=기대 검사 이름
  local d; d="$(mkclone)" || return 1
  if ! python -c 'import sys;p,a,b=sys.argv[1:4];t=open(p,encoding="utf-8").read();sys.exit(3) if t.count(a)!=1 else open(p,"w",encoding="utf-8",newline="").write(t.replace(a,b))' "$d/r/$3" "$4" "$5"; then
    echo "$1: 치환 실패(찾을 글이 한 번이 아니다) — 멈춘다"; rm -rf "$d"; return 1
  fi
  if ( cd "$d/r" && bash "scripts/$2" 2>&1 ) | grep -qF "FAIL: $6"; then echo "$1: 잡았다"; else echo "$1: 못 잡았다 — 기대 검사 「$6」"; fi
  rm -rf "$d"
}
[ "$base_ok" = 1 ] && {
inject superseded test_docs_drift.sh docs/superpowers/specs/2026-08-16-review-layer-redesign-design.md '**일부 superseded**' '**일부**' '옛 spec 에 superseded 표시가 있다'
inject supersedes줄 test_docs_drift.sh docs/superpowers/specs/2026-11-13-v2-rebuild-design.md '> 대체 예정:' '> supersedes:' 'supersedes 줄이 가리키는 문서마다 superseded 표시가 있다'
inject settings백업 test_scaffold.sh scripts/_ensure_autoupdate.sh '  cp "$f" "$bak" || { rm -rf "$tmp"; return 5; }' '' '사본을 남긴다'
inject 읽기전용차단 test_hooks.sh hooks/readonly_pretooluse.sh 'INPUT="$(cat)"' 'INPUT="$(cat)"; exit 0' '읽기 전용 파일(절대경로) → deny'
inject 설치안전 test_scaffold.sh scripts/_managed_block.sh '  awk "$MANAGED_TRIM_AWK" "$tmp" > "$norm" || return 2' '' 'personal note preserved'
inject 갱신잠금 test_scaffold.sh scripts/_ensure_current.sh 'lock="$kdir/update.lock"; got=0' 'lock="$kdir/update.lock"; got=1' '잠금이 있으면 갱신을 실행하지 않는다'
d="$(mkclone)"; ( cd "$d/r" && git rm -q docs/superpowers/decisions/2026-11-13-v2-rebuild.md \
  && git -c user.name=fault-injection -c user.email=fault@invalid commit -qm fault \
  && { bash scripts/test_docs_drift.sh 2>&1 | grep -qF 'FAIL: 기록과 plan 은 보존 태그를 단 뒤에만 지웠다' && echo "기록봉인: 잡았다" || echo "기록봉인: 못 잡았다"; } ); rm -rf "$d"
}
```

마지막 블록의 `-c` 명의는 버릴 클론의 한 커밋에만 쓰이고 사용자 git 설정을 바꾸지 않는다. 설치 안전 결함은 블록 밖 내용을 보존하는 줄(`awk "$MANAGED_TRIM_AWK" …`)을 지운다. 그러면 `$norm` 이 빈 임시 파일로 남아 블록만 쓰인다.

Expected: 기준 통과 세 줄, 그다음 결함마다 `잡았다`. `못 잡았다` 나 `치환 실패` 가 나온 결함이 있으면 그 계약의 검사(또는 찾을 글)를 고쳐 Step 6~8 을 다시 실행한다.

### Task 4: 금지어 원본 정리와 상시 보기 (2단계)

**Files:**
- Modify: `hooks/_banned_words.sh`(`banned_view` 추가), `scripts/scaffold.sh`(`[principles-copy]` 반복문), `korean-banned-words.md`, `docs/korean-banned-words-evidence.md`
- Test: `scripts/test_hooks.sh`(「제외 칸」 블록 뒤), `scripts/test_scaffold.sh`(`[fresh-pc]`·`[missing-canon]` 근처), `scripts/test_docs_drift.sh`(새 블록)

**Interfaces:**
- Produces: `banned_view <표 파일>` → stdout 상시 보기, 표에서 행을 하나도 읽지 못하면 아무것도 내지 않고 1 을 돌려준다. 형식(줄 끝 CR 없음, 끝 빈 줄 없음): 원본 첫 줄(제목), 빈 줄, 범위 제목 없는 행(있으면)과 빈 줄, 범위마다 `## <범위>`·빈 줄·행 줄·빈 줄, 마지막에 `## 표로 적을 수 없는 규칙`·빈 줄·원본 그 절의 `- ` 로 시작하는 줄. 행 줄은 `` - `금지어1` · `금지어2` → 대체어 `` 이고 제외어는 넣지 않는다. 표 읽기는 `banned_parse` 결과만 쓴다. Task 6·7 과 scaffold 가 이 함수를 쓴다.

- [ ] **Step 1: 실패하는 픽스처 검사를 쓴다(`test_hooks.sh`)**

픽스처 `list3.md` 는 아래 내용이다(기존 `BANEOF` 히어독 방식).

```markdown
# 금지어 시험 목록

## 금지 표현

설명 문단이다.

| 쓰지 않는 말 | 대신 쓰는 말 | 제외 |
|---|---|---|
| `앞` | 머리 | — |

### 모든 글에 적용

| 쓰지 않는 말 | 대신 쓰는 말 | 제외 |
|---|---|---|
| `판` | 버전 | `판정` · `판단` |

## 표로 적을 수 없는 규칙

설명 문장이다.

- 규칙 하나다.
```

```bash
check "상시 보기가 정한 형식을 낸다" "[ \"\$(banned_view '$BX/list3.md')\" = \"\$(printf '# 금지어 시험 목록\n\n- \`앞\` → 머리\n\n## 모든 글에 적용\n\n- \`판\` → 버전\n\n## 표로 적을 수 없는 규칙\n\n- 규칙 하나다.')\" ]"
check "상시 보기에 제외어가 없다"      "! banned_view '$BX/list3.md' | grep -qF '판정'"
check "CRLF 표도 같은 보기를 낸다"    "sed 's/\$/\r/' '$BX/list3.md' > '$BX/list3crlf.md' && [ \"\$(banned_view '$BX/list3crlf.md')\" = \"\$(banned_view '$BX/list3.md')\" ] && ! banned_view '$BX/list3crlf.md' | grep -q \$'\r'"
check "행이 없는 표는 실패하고 아무것도 내지 않는다" "printf '# 빈 목록\n' > '$BX/empty.md' && ! banned_view '$BX/empty.md' > '$BX/empty.out' && [ ! -s '$BX/empty.out' ]"
```

- [ ] **Step 2: 실패를 확인한다**

Run: `bash scripts/test_hooks.sh 2>&1 | grep -E '상시 보기|CRLF 표|PASS='`
Expected: 네 검사 FAIL(`banned_view: command not found`).

- [ ] **Step 3: `banned_view` 를 구현한다**

`hooks/_banned_words.sh` 에 둔다. `mktemp -d` 에 `banned_parse` 의 pairs·tokens·excl·scopes 를 받아 awk 로 조립하고 임시 폴더를 지운다. 규칙 절은 원본에서 `## 표로 적을 수 없는 규칙` 다음부터 다음 `## ` 앞까지의 `- ` 줄만 읽는다. 파일 머리 주석의 소비자 목록에 `scaffold.sh` 를 추가한다.

- [ ] **Step 4: 통과를 확인한다**

Run: `bash scripts/test_hooks.sh 2>&1 | grep -E 'FAIL|PASS='`
Expected: `FAIL=0`.

- [ ] **Step 5: 원본을 정리한다(`korean-banned-words.md`)**

머리 문단과 「금지 표현」의 두 문단을 합쳐 두 문장으로 줄인다(이 파일이 원본이고 항목 근거는 `docs/korean-banned-words-evidence.md` 에 있다는 문장, 첫째 칸 백틱 안이 검색할 글자이고 셋째 칸 제외어 안의 글자는 검출하지 않으며 세션에 싣는 상시 보기는 `scaffold.sh` 가 이 표에서 만든다는 문장). 범위 제목·분류 제목 아래 설명 문단은 근거 파일의 새 절 「분류 설명」으로 옮긴다. `## 꺼 둔 항목` 절은 근거 파일로 옮긴다. `## 표로 적을 수 없는 규칙` 제목은 그대로 둔다(`trial_reply_edit.py` 의 끝 표식). 그 절의 규칙 줄에서 작은따옴표로 든 예시(`정할 일`, `이 셋이 돈다` 등)를 백틱으로 바꾼다. 표의 행과 형식(`## 금지 표현`, 범위 제목, 첫 칸 백틱, 셋째 칸 제외어)은 바꾸지 않는다.

- [ ] **Step 6: 원본 정리가 행을 바꾸지 않았는지 확인한다**

Run: `. scripts/_json_valid.sh; . hooks/_banned_words.sh; d=$(mktemp -d); git show HEAD:korean-banned-words.md > $d/old.md; banned_parse $d/old.md $d/p0 $d/t0 $d/e0 $d/s0; banned_parse korean-banned-words.md $d/p1 $d/t1 $d/e1 $d/s1; cmp $d/p0 $d/p1 && cmp $d/e0 $d/e1 && cmp $d/s0 $d/s1 && echo SAME`
Expected: `SAME`.

- [ ] **Step 7: 실패하는 scaffold·drift 검사를 쓴다**

`test_scaffold.sh` 의 `[fresh-pc]` 에 아래를 추가한다(첫 `run "$H1" "$P1"` 뒤, 기존 원칙 사본 재복사 검사 앞).

```bash
VIEW_REF="$(mktemp)"; ( . "$HERE/hooks/_banned_words.sh"; banned_view "$HERE/korean-banned-words.md" ) > "$VIEW_REF"
check "금지어 사본이 원본 표로 만든 상시 보기와 같다" "cmp -s '$VIEW_REF' '$K/korean-banned-words.md'"
check "금지어 사본에 표가 없다"                     "! grep -qF '|---|' '$K/korean-banned-words.md'"
touch -d '2000-01-01' "$K/korean-banned-words.md"; REF6="$(mktemp)"; touch -d '2001-01-01' "$REF6"
run "$H1" "$P1" > /dev/null
check "같은 상시 보기는 다시 쓰지 않는다"           "[ ! '$K/korean-banned-words.md' -nt '$REF6' ]"
```

`[missing-canon]` 뒤에 Review Focus 의 두 상황을 추가한다. 홈 폴더 `HV1`·`HV2` 의 `.claude/disciplined-coder/korean-banned-words.md` 에 `old view` 한 줄을 둔다. 플러그인 루트 `RV1` 에는 `agent-principles.md` 만, `RV2` 에는 `agent-principles.md` 와 `# 빈 목록` 한 줄짜리 `korean-banned-words.md` 를 둔다. `set +e` 로 감싸 `OUTV1`·`OUTV2` 와 종료 코드 `rcv1`·`rcv2` 를 받는다(`[missing-canon]` 과 같은 방식).

```bash
check "원본 표가 없으면 경고하고 옛 금지어 사본을 남긴다" "printf '%s' \"\$OUTV1\" | grep -qF 'WARNING: source not found' && [ \"\$(cat '$HV1/.claude/disciplined-coder/korean-banned-words.md')\" = 'old view' ] && [ $rcv1 -eq 0 ]"
check "행 없는 표면 오류를 알리고 옛 금지어 사본을 남긴다" "printf '%s' \"\$OUTV2\" | grep -qF 'ERROR: 금지어 상시 보기를 만들지 못했다' && [ \"\$(cat '$HV2/.claude/disciplined-coder/korean-banned-words.md')\" = 'old view' ] && [ $rcv2 -eq 0 ]"
```

`test_docs_drift.sh` 에 새 블록을 추가한다. 파일 머리에서 `scripts/_json_valid.sh` 와 `hooks/_banned_words.sh` 를 읽고, `BW="$(mktemp -d)"` 에 `banned_parse "$HERE/korean-banned-words.md" "$BW/pairs" "$BW/toks" "$BW/excl" "$BW/scopes"` 결과와 `VIEW="$BW/view.md"`(`banned_view` 출력)를 둔다. Task 6 이 같은 `BW`·`VIEW` 를 쓴다.

```bash
echo "[상시 보기 — 원본 표의 행이 모두 있다]"
VIEW_MISS="$(while read -r t; do grep -qF -- "\`$t\`" "$VIEW" || echo "$t"; done < "$BW/toks")"
check "상시 보기 행 수가 원본 표 행 수와 같다" "[ \"\$(grep -c '^- \`' \"\$VIEW\")\" = \"\$(wc -l < \"\$BW/pairs\" | tr -d ' ')\" ]"
check "원본 표의 금지어가 모두 상시 보기에 있다" "[ -z \"\$VIEW_MISS\" ]"
```

- [ ] **Step 8: 실패를 확인한다**

Run: `bash scripts/test_scaffold.sh 2>&1 | grep -E 'FAIL|PASS='`
Expected: `금지어 사본이 원본 표로 만든 상시 보기와 같다`, `금지어 사본에 표가 없다`, `행 없는 표면 오류를 알리고 옛 금지어 사본을 남긴다` 가 FAIL. `bash scripts/test_docs_drift.sh` 의 상시 보기 블록 두 검사는 `banned_view` 가 Step 3 에서 이미 생겼으므로 PASS 다.

- [ ] **Step 9: scaffold 가 상시 보기를 쓰게 한다**

`scripts/scaffold.sh` 머리에서 `. "$SDIR/../hooks/_banned_words.sh"` 로 읽는다(`PLUGIN_ROOT` 가 빈 폴더여도 함수는 스크립트 옆에서 온다). `[principles-copy]` 반복문에서 `korean-banned-words.md` 이고 원본이 있으면 `mktemp` 파일에 `banned_view` 결과를 받아 그 파일을 `src` 로 쓰고, 복사 뒤 지운다. `banned_view` 가 실패하면 `[disciplined-coder] ERROR: 금지어 상시 보기를 만들지 못했다 — <원본 경로> (이전 사본이 있으면 그것이 그대로 쓰인다). 나머지 셋업은 계속한다.` 를 내고 그 파일은 복사하지 않는다. 원본이 없을 때의 `WARNING: source not found` 는 그대로다. 관리블록 `@import` 두 줄과 `SCAFFOLD_FILES` 는 바꾸지 않는다.

- [ ] **Step 10: 통과를 확인하고 분량을 확인한다**

Run: 「변경 뒤 실행」 명령, `claude plugin validate ./`, 그리고 `bash -c '. hooks/_banned_words.sh; banned_view korean-banned-words.md' | python -c "import sys;print(len(sys.stdin.buffer.read().decode('utf-8')))"`(윈도우 파이썬은 `<( )` 경로를 열지 못하므로 파이프로 넘긴다)
Expected: `ALL PASS`, `Validation passed`, 상시 보기 글자 수가 현행 6,097자보다 작다. 이 실측값을 적어 두고 Task 11 Step 4 에서 참고서에 기록한다(spec 의 1,943자와 차이가 나는 이유는 「spec 과 다른 점」 상시 보기 분량).

- [ ] **Step 11: 커밋한다**

```bash
git add hooks/_banned_words.sh scripts/scaffold.sh korean-banned-words.md docs/korean-banned-words-evidence.md scripts/test_hooks.sh scripts/test_scaffold.sh scripts/test_docs_drift.sh
git commit -m "금지어 상시 보기를 원본 표에서 만들어 PC 사본으로 쓴다" -m "Co-Authored-By: Claude Opus 5.5 <noreply@anthropic.com>
Claude-Session: https://claude.ai/code/session_01VjrV5UxDSPWWUxyS7m25jP"
```

### Task 5: 새 원칙과 참고서 v2 근거 절 (2단계)

**Files:**
- Modify: `agent-principles.md`(교체), `docs/domain-discipline.md`, `docs/domain-korean.md`
- Test: `scripts/test_docs_drift.sh`, `scripts/test_scaffold.sh`

**Interfaces:**
- Produces: `clause_ref_missing <원칙 파일>` → 근거 절이 없는 ID 를 공백으로 이은 글. 「행동」 절의 `- **\`ID\`**` 는 `docs/domain-discipline.md` 에, 「출력」 절의 ID 는 `docs/domain-korean.md` 에 정확히 `` ### `ID` `` 인 제목 줄이 있어야 한다(제목 뒤 설명이 붙은 `(v1)`·`(원칙에서 내림)` 절은 세지 않는다). Task 12 의 문구 수정도 이 검사를 받는다.

- [ ] **Step 1: 원칙을 spec 초안으로 바꾼다**

Run: `python -c "import re;t=open('docs/superpowers/specs/2026-11-13-v2-rebuild-design.md',encoding='utf-8').read();open('agent-principles.md','w',encoding='utf-8',newline='\n').write(re.search(r'\`\`\`markdown\n(# 디시플린.*?)\n\`\`\`',t,re.S).group(1)+'\n')"`
Expected: `git diff --stat` 에 `agent-principles.md` 한 파일. 글자 수 3,129(spec 의 3,130자와 끝 줄바꿈 차이).

- [ ] **Step 2: 깨지는 검사를 확인한다**

Run: `bash scripts/test_docs_drift.sh 2>&1 | grep FAIL; bash scripts/test_scaffold.sh 2>&1 | grep FAIL`
Expected(이 계획을 쓸 때 저장소 사본에서 같은 교체로 확인한 목록): drift 의 아래 검사(`스킬이 모든 조항 ID 로 근거를 단다`, `참고서가 모든 조항 ID 로 근거를 단다`, `소유자로 불리는 절이 스스로 선언한다`, `절 제목 아래 첫 줄이 모두 산문이다`, `병렬 오케스트레이션 points to skill`, `그 절에 SUB-ORCHESTRATE 조항이 있다`, `canon: every clause … (reference → principles)`, `canon: derived check catches a removed clause`, `canon: 상시 허가 조항`, `canon: 허가 범위 한정`, `canon: 묻는 조항이 행동 절에 있다`), scaffold 의 아래 검사(`에이전트원칙이 사본 경로를 가리킨다`, `옛 사본이 갱신된다`).

- [ ] **Step 3: 원칙에 묶인 v1 검사를 바꾼다**

`test_docs_drift.sh` 에서 KO_IDS·KO_MISS·KO_DUP 와 DC_IDS·DC_MISS·DC_DUP 검사(양방향 대응·문장 복제 금지)를 `clause_ref_missing` 한 방향 검사로 바꾼다. 「행동」 절에 `- **\`FAKE-ID\`** — x` 를 넣은 사본에서 `FAKE-ID` 가 나오는지 보는 자기시험을 함께 둔다. `에이전트원칙이 그 상세를 가리킨다`·`그 참고서를 가리킨다` 두 검사는 남긴다. 아래 검사는 spec 「버리는 검사」에 따라 지운다: `[첫 문장]` 블록, `[parallel-orchestration-nudge]` 블록과 `WF_BLOCK`, `[canon-realign]` 의 참고서 → 원칙 검사·`YAGNI` 자기시험·부활 금지 ID 목록(`karpathy` 출처 검사는 남긴다), `[standing-consent]` 의 두 canon 검사(`선행연구 스킬이 승인 규칙을 소유한다` 는 남긴다), `[question-tool]` 의 `canon: 묻는 조항이 행동 절에 있다`. 대구 한도 검사는 이번 교체와 부딪치지 않으므로 뒤 단계로 미룬다.

`test_scaffold.sh` 의 `에이전트원칙이 사본 경로를 가리킨다` 는 `managing-docs/SKILL.md` 사본 경로만 보게 하고, `옛 사본이 갱신된다` 는 `cmp -s '$HERE/agent-principles.md' '$OLDCANON'` 으로 바꿔 조항 ID 리터럴(`LENS-ALLOWED`)을 쓰지 않는다.

- [ ] **Step 4: 남은 실패를 확인한다**

Run: `bash scripts/test_docs_drift.sh 2>&1 | grep -A0 -B1 FAIL`
Expected: 한 방향 검사가 `ROLES EVIDENCE RESOURCES`(행동)와 `ANSWER-SCOPE`(출력)로 FAIL, `소유자로 불리는 절이 스스로 선언한다` FAIL(`docs/domain-korean.md` 7행이 원칙 「출력」 절을 소유자로 부른다).

- [ ] **Step 5: 참고서를 고쳐 쓴다**

두 참고서에 같은 규칙을 적용한다.

  - 머리 문단을 v2 로 고쳐 쓴다. 지시는 에이전트원칙이 소유하고 이 파일은 조항 ID 마다 근거를 단다는 문장은 남기되, "같은 문장이 양쪽에 있으면 `test_docs_drift.sh` 가 차단한다"는 문장은 지운다(그 검사를 지웠다). `docs/domain-korean.md` 7행은 「출력」 절을 소유자로 부르지 않게 쓴다(예: "에이전트원칙(`agent-principles.md`) 「출력」 절의 조항마다 근거를 단다").
  - 머리 문단 뒤에 `## v2 조항` 을 두고 첫 줄에 산문 한 문장을 쓴 뒤, v2 조항마다 `` ### `ID` `` 절을 쓴다. `docs/domain-discipline.md` 에는 `ROLES`·`REVERSIBLE`·`EVIDENCE`·`RUN-IT`·`YAGNI`·`OTHER-SESSIONS`·`RESOURCES`, `docs/domain-korean.md` 에는 `ANSWER-SCOPE`·`VOCAB-PREF`·`TONE-AXIS` 다. 절 내용은 spec 「조항별 근거」 표의 그 행(요구 번호, 사용자 원문 근거, 측정, 흡수한 v1 조항, 버린 내용)을 산문으로 옮긴 것이고, 지시 문장은 옮겨 적지 않는다. `TONE-AXIS` 절에는 합쇼체 기본값의 사용자 원문을 찾지 못했다는 spec 문단도 옮긴다.
  - v1 절을 파일 끝 `## v1 조항 근거` 아래로 옮긴다. 첫 줄은 "v1 원칙(태그 `archive/v1-final`)의 조항 근거다. v2 조항이 흡수한 v1 조항은 v2 절의 흡수 칸에 있다." 같은 산문이다. 옮기는 대상은 `docs/domain-discipline.md` 의 「행동」·「대화 답과 작업 보고」·「검증(행동 절의 렌즈 조항)」·「보고(행동 절)」·「병렬 오케스트레이션(행동 절)」 묶음, `docs/domain-korean.md` 의 PLAIN-KO·KO-SYNTAX·PROSE-FORM·READ-FLOW·UNPACK 묶음이다. 옮길 때 묶음 제목(`##`)은 `###` 로, 조항 제목(`###`)은 `####` 로 한 단계 내리고, v1 원칙 ID 조항 제목 끝에 ` (v1)` 을 붙인다(`(원칙에서 내림)` 표시가 있는 제목은 그대로). 절 이름 앞부분은 바뀌지 않으므로 「」 참조와 `sec_has` 검사(`NO-RAW-OUTPUT`·`LENS-ALLOWED` 절)는 그대로 찾는다.
  - managing-docs 조항 절(「읽기 위한 문서」·「문서 관리와 작업 지시서」), 「생성 제약」, 「삭제한 조항」, `docs/domain-korean.md` 의 「금지 표현의 근거」·「지시문의 형태」·「대화 답 리마인더」는 제자리에 둔다.

- [ ] **Step 6: 통과를 확인한다**

Run: 「변경 뒤 실행」 명령, `claude plugin validate ./`
Expected: `ALL PASS`, `Validation passed`.

- [ ] **Step 7: 커밋한다**

```bash
git add agent-principles.md docs/domain-discipline.md docs/domain-korean.md scripts/test_docs_drift.sh scripts/test_scaffold.sh
git commit -m "에이전트원칙을 v2 열 조항으로 바꾸고 참고서에 v2 근거 절을 쓴다" -m "Co-Authored-By: Claude Opus 5.5 <noreply@anthropic.com>
Claude-Session: https://claude.ai/code/session_01VjrV5UxDSPWWUxyS7m25jP"
```

### Task 6: 새 리마인더와 지시문 금지어 검사 (2단계)

**Files:**
- Modify: `hooks/reply_reminder_userpromptsubmit.sh`
- Test: `scripts/test_hooks.sh`(`[reply-reminder]`), `scripts/test_docs_drift.sh`(새 블록)

**Interfaces:**
- Consumes: `banned_view`(Task 4), `banned_parse`·`banned_report`(`hooks/_banned_words.sh`), `json_run`(`scripts/_json_valid.sh`).
- Produces: 훅 안의 `msg="…"` 다음 줄이 `printf` 로 시작하는 구조를 유지한다. Task 7 의 `replay6.py` 가 `_hook.split('msg="', 1)[1].split('"' + NL + 'printf', 1)[0]` 로 리마인더를 읽는다. Task 6 의 마지막 커밋 해시를 `%USERPROFILE%\.dc-eval\replay\V2_REV.1.txt` 에 쓴다(v2 첫 리비전, 이후 고치지 않는다).

- [ ] **Step 1: 실패하는 검사를 쓴다**

`test_hooks.sh` 의 `메시지마다 세 줄을 붙인다` 를 아래 리터럴 없는 검사로 바꾼다(spec 이 `감독자` 리터럴 검사를 버린다). `끄면 침묵한다` 는 끄는 변수를 지우는 4단계까지 남긴다.

```bash
RR_CTX='import json,sys; print(json.load(sys.stdin)["hookSpecificOutput"]["additionalContext"])'
check "리마인더가 올바른 UserPromptSubmit JSON 이다" "out=\"\$(rr '이 함수를 고쳐봐')\" && json_valid_stdin <<<\"\$out\" && grep -qF '\"hookEventName\":\"UserPromptSubmit\"' <<<\"\$out\""
check "리마인더 본문이 비어 있지 않다"              "[ -n \"\$(rr '이 함수를 고쳐봐' | json_run \"\$RR_CTX\")\" ]"
check "메시지와 무관하게 같은 글을 낸다"            "[ \"\$(rr '이 함수를 고쳐봐')\" = \"\$(rr '커밋 됐어')\" ]"
```

`test_docs_drift.sh` 에 지시문 금지어 블록을 추가한다. Task 4 의 `BW`(pairs·excl)와 `VIEW` 를 쓰고, 리마인더 출력의 `additionalContext` 를 `json_run` 으로 꺼내 `REMIND_TXT="$BW/remind.txt"` 에 둔다. 원칙 파일, `VIEW`, `REMIND_TXT` 세 글마다 `banned_report` 가 비어 있어야 한다. 자기시험 픽스처는 `IB_FX="$(mktemp -d)"` 에 백틱 밖 금지어가 든 `out.md` 와 같은 낱말을 백틱 안에만 둔 `in.md` 다(낱말은 `정할 일`).

```bash
echo "[지시문 금지어 — 실리는 지시문에 금지어가 백틱 밖에 없다]"
check "백틱 밖 금지어를 잡는다"   "[ -n \"\$(banned_report \"\$BW/pairs\" \"\$IB_FX/out.md\" \"\$BW/excl\")\" ]"
check "백틱 안 금지어는 넘긴다"   "[ -z \"\$(banned_report \"\$BW/pairs\" \"\$IB_FX/in.md\" \"\$BW/excl\")\" ]"
check "원칙 사본에 금지어가 없다"   "[ -z \"\$(banned_report \"\$BW/pairs\" \"\$HERE/agent-principles.md\" \"\$BW/excl\")\" ]"
check "상시 보기에 금지어가 없다"   "[ -z \"\$(banned_report \"\$BW/pairs\" \"\$VIEW\" \"\$BW/excl\")\" ]"
check "리마인더에 금지어가 없다"    "[ -z \"\$(banned_report \"\$BW/pairs\" \"\$REMIND_TXT\" \"\$BW/excl\")\" ]"
```

- [ ] **Step 2: 실패를 확인한다**

Run: `bash scripts/test_docs_drift.sh 2>&1 | grep -E '금지어|PASS='`
Expected: `리마인더에 금지어가 없다` FAIL(현행 리마인더의 `정할 일`).

- [ ] **Step 3: 리마인더를 바꾼다**

`msg="…"` 안을 spec 「매 턴 리마인더」 코드 블록 세 줄로 글자 그대로 바꾼다. 머리 주석의 근거 문단을 spec 「매 턴 리마인더」(첫 줄은 29턴 시험의 줄, 둘째 줄은 판독 10쌍 위반 0, 셋째 줄은 110턴 결정 질문 줄 3·0 을 `ROLES` 의 낱말로 고침, 세 줄 묶음은 3단계에서 측정)로 고친다. 끄는 변수 줄과 그 주석은 4단계에서 지운다.

- [ ] **Step 4: 통과와 분량을 확인한다**

Run: 「변경 뒤 실행」 명령, `claude plugin validate ./`, 그리고 아래 두 줄
```bash
bash hooks/reply_reminder_userpromptsubmit.sh </dev/null | python -c "import json,sys;t=json.load(sys.stdin)['hookSpecificOutput']['additionalContext'];print(len(t.replace(chr(10),'')))"
bash -c '. hooks/_banned_words.sh; banned_view korean-banned-words.md' | python -c "import sys;print(len(open('agent-principles.md',encoding='utf-8').read())+len(sys.stdin.buffer.read().decode('utf-8')))"
```
Expected: `ALL PASS`, `Validation passed`, 리마인더 184(현행 217 이하), 상시 분량 합계가 9,600 보다 작다.

- [ ] **Step 5: 커밋하고 v2 첫 리비전을 적어 둔다**

```bash
git add hooks/reply_reminder_userpromptsubmit.sh scripts/test_hooks.sh scripts/test_docs_drift.sh
git commit -m "매 턴 리마인더를 v2 세 줄로 바꾸고 지시문 금지어를 검사한다" -m "Co-Authored-By: Claude Opus 5.5 <noreply@anthropic.com>
Claude-Session: https://claude.ai/code/session_01VjrV5UxDSPWWUxyS7m25jP"
[ -e "$USERPROFILE/.dc-eval/replay/V2_REV.1.txt" ] || git rev-parse HEAD > "$USERPROFILE/.dc-eval/replay/V2_REV.1.txt"
```

### Task 7: 재현·판정 도구 준비 (3단계, 저장소 밖)

**Files (저장소 밖, 커밋하지 않는다):**
- Create: `%USERPROFILE%\.dc-eval\replay\replay6.py`(replay5.py 복사·수정), `count_banned.py`, `report_hidden.py`, `gen_reading_v5.py`(gen_reading_v4.py 복사·수정), `banlist-v1\`
- Create: `%USERPROFILE%\.dc-eval\calib\judge_hidden.py`, `judge_v3h.py`(judge_v3.py 복사·수정)

**Interfaces:**
- Consumes: `turns-hidden1-2026-11-13.jsonl`(Task 2), `archive/v1-final`(Task 1), `V2_REV.1.txt`(Task 6), `banned_view`(Task 4), `judge_pair.ask(q) -> dict`(`score`·`note`·`x_quotes`·`y_quotes`·`models`·`cost`).
- Produces:
  - 조건 이름: `v1`, `v2.<n>`, `v2.<n>-table`, `v1-tools`, `v2.<n>-tools`. `rev_of(cond) -> str` 는 `v1` 이면 `archive/v1-final`, `v2.<n>` 이면 `%USERPROFILE%\.dc-eval\replay\V2_REV.<n>.txt` 의 커밋을 돌려준다. `V2_REV.<n>.txt` 는 한 번 쓰면 고치지 않고, 새 v2 리비전은 다음 번호 파일로 둔다.
  - `python replay6.py <결과 폴더> <조건> <idx...>`, 환경 변수 `REPLAY_TURNS`(턴 파일 경로). `python replay6.py --print-context <조건>` 은 생성 없이 cfg `CLAUDE.md` 와 리마인더 블록만 출력한다. 결과는 `<결과 폴더>/<조건>-<idx>.json`(replay5 와 같은 키 + `kind`·`rev`(전체 커밋 해시)·`num_turns`)이다. 모듈 수준 코드는 `if __name__ == '__main__':` 아래에 둔다.
  - `done(path: str, keys: list[str]) -> bool`: 파일이 있고 JSON 으로 읽히며 `keys` 의 값이 모두 비어 있지 않으면 참. 각 도구가 생략 조건으로 쓴다(답 `['response']`, 판정 `['ab','ba']` 와 두 순서의 `score`, 위반 판정 `['violated']`).
  - `python judge_hidden.py <답 폴더> <결과 폴더> <조건A> <조건B> <턴 파일> [idx...]` → `<결과 폴더>/<idx>-<A>-<B>.json` = `{kind, rev_a, rev_b, ab, ba, s1, s2, score, cls}`. AB 순서는 X=A·Y=B, BA 순서는 X=B·Y=A 이고 `s1 = ab.score`, `s2 = -ba.score`, `score = (s1+s2)/2` 다(양수면 B 가 낫다). 한 순서라도 점수가 없으면 `cls` 없이 `error` 를 남긴다. `rev_a`·`rev_b` 는 두 답 파일의 `rev` 다.
  - `classify(s1: float, s2: float) -> str`: 두 값이 모두 0 이상이고 평균이 0 보다 크면 `개선`, 모두 0 이하이고 평균이 0 보다 작으면 `악화`, 그 밖(부호가 엇갈리거나 평균 0)은 `같음`(spec 「완료 기준」·`_judge.py` 계약).
  - `python judge_v3h.py <답 폴더> <결과 폴더> <조건> <idx...>` → `<결과 폴더>/<조건>-<idx>.json` = `{violated, no_answer, note, models, cost, rev}`.
  - `count_banned_rows(text: str, rows: list[list[str]], excls: list[list[str]]) -> list[int]`(행마다 검출 수), `count_banned(...) -> int`(그 합), `questions(text: str) -> int`, `load() -> (rows, excls)`. CLI `python count_banned.py <답 폴더> <조건...> [--idx <idx 목록 파일>]` 은 조건마다 글자 수·검출 수·만 자당 검출을 출력하고 `<답 폴더>/banned-<조건>.json`(행별 검출 수와 행 첫 금지어)을 쓴다.
  - `python report_hidden.py <판정 폴더> <조건A> <조건B> <턴 파일> <답 폴더> [--viol <위반 폴더>] [--reading <판독 파일>]` → 요약 출력과 `<판정 폴더>/report.json`.
  - `python gen_reading_v5.py <출력 html> <저장 키> <답 폴더> <판정 폴더> <idx:A:B>...`.

- [ ] **Step 1: `replay6.py` 를 만든다**

replay5.py 를 복사해 아래만 바꾼다. 턴 파일을 `REPLAY_TURNS` 에서 읽고, 커밋은 `rev_of(조건)` 으로 정한다. `SCOPE`·`generic`·`line-*`·`none` 조건 분기를 지운다. 원본 표는 `show('korean-banned-words.md')`, 상시 보기는 `git show <rev>:hooks/_banned_words.sh` 와 `<rev>:korean-banned-words.md` 를 임시 폴더에 쓰고 `bash -c '. "$1"; banned_view "$2"' _ <함수 파일> <표 파일>` 의 출력으로 만든다(`v1` 은 원본 표, `v2.<n>` 은 상시 보기, `v2.<n>-table` 은 v2 원칙 + 원본 표). cfg `CLAUDE.md` 는 replay5 와 같이 `AX + 원칙 + 금지어` 순서이고 `outputStyle` 은 `Concise`, 시스템 프롬프트 추가 문장과 `--tools ''`·`--model claude-opus-5-5` 도 replay5 그대로다. 조건이 `-tools` 로 끝나면 시스템 프롬프트 추가 문장을 빼고 `--tools Read,Grep,Glob`·`--max-turns 15` 로 실행한다. 임시 폴더는 replay5 와 같이 `tempfile.mkdtemp(prefix='replay-', dir='D:/dc-eval-tmp')` 이고, 도구 조건의 작업 폴더는 그 안의 `work` 에 턴의 `cwd` 저장소를 `git clone --local` 한 뒤 턴 시각 직전 커밋(`git rev-list -1 --before=<ts> HEAD`)으로 체크아웃한 폴더다. 끝나면 임시 폴더째 지운다. 결과는 같은 폴더의 `.<이름>.tmp` 에 쓴 뒤 `os.replace` 로 바꾸고, `done(out, ['response'])` 이 참이면 생성하지 않는다.

- [ ] **Step 2: `replay6.py` 를 확인한다**

```bash
cd "$USERPROFILE/.dc-eval/replay"; export REPLAY_TURNS="$PWD/turns/turns-hidden1-2026-11-13.jsonl"
python replay6.py --print-context v1 | grep -c '^| `재다`'
python replay6.py --print-context v2.1 | grep -cE '^- `재다`|^\|---\|'
python replay6.py --print-context v2.1 | grep -c '사용자 메시지가 지시면 실행하고 결과만'
python -c "import replay6,json,tempfile,os;d=tempfile.mkdtemp();p=os.path.join(d,'x.json');open(p,'w').write('{');assert not replay6.done(p,['response']);json.dump({'response':'a'},open(p,'w'));assert replay6.done(p,['response']);print('done ok')"
```
Expected: `1`, `1`(상시 보기 행만 있고 표 구분선은 없다), `1`, `done ok`.

- [ ] **Step 3: `judge_hidden.py` 를 만든다**

`judge_pair` 를 읽기 전에 `sys.argv = sys.argv[:1]` 로 두고 읽은 뒤 되돌린다(모듈이 읽힐 때 인자를 판정 쌍으로 해석한다). 판정은 `jp.ask()` 로 하고 동시 3개다. 지시문은 `kind` 로 고른다. `지적` 턴은 judge_pair.py 의 `PROMPT`(사용자 메시지·지적·지적의 요지·답 X·답 Y, 점수 정의, `x_quotes`·`y_quotes` 원문 그대로)에 판정 기준점을 추가한다. 기준점 2~5 는 `calib\judge_v3.py` 의 `JUDGE` 2~5번 문장을 글자 그대로 쓰고, 1번은 `지적이 겨눈 점에서 실제로 나아졌으면 나아진 것이다. 네가 이상적이라고 보는 수준과 비교하지 마라.` 로 쓴다. `지적없음` 턴은 judge_brev.py 의 `PROMPT` 틀에서 요구 설명 문장을 사용자 원문 `진행해라고 하면 진행하고, 물어보면 물어본 것만 답변하고` 인용 한 줄로 바꾸고, 같은 기준점(4·5번의 "지적"은 "사용자 메시지"로 읽는다는 한 줄 포함)과 `x_quotes`·`y_quotes` 요구를 추가한다. 요구 1~11 과 `synthesis.md` 문구는 넣지 않는다(spec 「시험 체계」 판정). 입력 길이는 judge_pair 와 같이 질문 4,000자, 답 8,000자로 자른다. 결과는 임시 이름에 쓴 뒤 이름을 바꾸고, `done()` 이 참이면 다시 판정하지 않는다.

- [ ] **Step 4: `judge_hidden.py` 를 확인한다**

```bash
cd "$USERPROFILE/.dc-eval/calib" && python -c "import sys;sys.argv=['x'];import judge_hidden as j;c=j.classify;assert [c(1,1),c(1,0),c(0,0),c(2,-1),c(-1,0),c(-2,-1)]==['개선','개선','같음','같음','악화','악화'];print('classify ok')"
```
Expected: `classify ok`.

- [ ] **Step 5: `judge_v3h.py` 를 만들고 확인한다**

judge_v3.py 의 `JUDGE` 와 판정 호출을 그대로 두고 입력·출력 폴더와 대상을 인자로 받으며, 답 파일의 `rev` 를 결과에 옮기고, 임시 이름에 쓴 뒤 이름을 바꾸고, `done(out, ['violated'])` 이 참이면 생략한다(`violated` 는 `false` 도 값으로 본다).
Run: `python judge_v3h.py --help` 와 `python -c "import sys;sys.argv=['x'];import judge_v3h"`
Expected: 사용법 한 줄 출력, 읽기만으로는 판정 호출이 없다.

- [ ] **Step 6: 금지어 행 파일과 `count_banned.py` 를 만들고 확인한다**

```bash
E="$USERPROFILE/.dc-eval/replay/banlist-v1"; mkdir -p "$E"
git -C /d/projects/disciplined-coder show archive/v1-final:korean-banned-words.md > "$E/table.md"
bash -c '. /d/projects/disciplined-coder/hooks/_banned_words.sh; banned_parse "$1/table.md" "$1/pairs" "$1/toks" "$1/excl" "$1/scopes"' _ "$E"
wc -l < "$E/pairs"
```
Expected: 원본 표의 행 수(v2 원본과 같다. Task 4 Step 6 이 행을 바꾸지 않았음을 확인했다).

`count_banned.py` 는 `banlist-v1\pairs`·`excl` 을 읽는다. 코드 블록과 백틱 구간을 지우고, 행마다 제외어를 같은 길이 공백으로 덮은 뒤 각 금지어의 출현 수를 센다. `questions()` 는 코드 블록을 지운 글에서 `[?？](?=\s|$)` 출현 수다.

```bash
cd "$USERPROFILE/.dc-eval/replay" && python -c "
import count_banned as c
r, e = c.load()
t = '정할 일이 있다. \x60정할 일\x60 판정과 판을 본다?'
n = c.count_banned_rows(t, r, e)
i = [k for k, x in enumerate(r) if '정할 일' in x][0]
j = [k for k, x in enumerate(r) if '판' in x][0]
assert n[i] == 1 and n[j] == 1 and c.questions(t) == 1
print('count ok')"
```
Expected: `count ok`(백틱 안은 세지 않고, `판정` 은 제외어라 `판` 만 센다).

- [ ] **Step 7: `report_hidden.py` 를 만들고 확인한다**

출력은 아래다.

  - 종류별(`지적`·`지적없음`)과 전체의 개선·악화·같음 수, 판정 대상 수와 빠진 턴 목록, 평균 점수, 한쪽 부호 검정 p = Σ_{i=개선}^{n} C(n,i)/2^n (n = 개선 + 악화), 판정 파일의 `rev_a`·`rev_b` 값 목록(한 조건에 리비전이 둘 이상이면 경고하고 1 로 끝난다).
  - 참고 지표: 조건별 위반 수(`--viol`, 지적 턴), 답 길이 중간값, 금지어 만 자당 검출(`count_banned`), 답당 질문 수.
  - 이전 대화 길이(`history_msgs`) 구간 1~20, 21~60, 61~160 별 같은 집계(spec 「위험」 대화 기록 모방 오차).
  - 판독 후보 10~20쌍: 두 순서 부호가 엇갈린 쌍, 평균 점수 절댓값 0.5 이하인 쌍, 평균이 가장 낮은 쌍 순서로 최대 20개.
  - `--reading` 이 있으면 판독 결과(Task 11 Step 2 형식)를 읽어, 판독 파일에 있는 쌍은 사용자 점수의 부호(양수 `개선`, 음수 `악화`, 0 `같음`)로 분류를 바꿔 다시 집계하고, 판독 과반(보인 쌍 중 사용자 점수 또는 동의한 판정자 점수가 0 이상인 쌍이 절반을 넘는가)과 판정·판독 불일치 수를 낸다.

Run: 개선 20·악화 3 인 판정 파일 23개를 임시 폴더에 만든 픽스처로 `report_hidden.py` 를 실행한다.
Expected: `개선 20 악화 3`, `p=0.000244`(= 2048/2^23).

- [ ] **Step 8: 두 턴으로 시범 실행한다(업무 시간 밖)**

```bash
cd "$USERPROFILE/.dc-eval/replay"; I2="$(head -2 turns/hidden1-ids.txt | cut -f1 | tr '\n' ' ')"
python replay6.py hidden1 v1 $I2
python replay6.py hidden1 v2.1 $I2
cd ../calib && python judge_hidden.py ../replay/hidden1 hidden1 v1 v2.1 "$REPLAY_TURNS" $I2
```
Expected: 답 4개의 `models` 가 `["claude-opus-5-5"]` 이고 `rev` 가 각 조건의 커밋이다. 판정 2개에 `cls` 와 `x_quotes`·`y_quotes` 가 있고 인용 문장이 답 원문에 그대로 있다(`python -c` 로 포함 여부 확인).

- [ ] **Step 9: `gen_reading_v5.py` 를 만들고 확인한다**

v4 의 화면을 유지하고, 경로를 인자로 받으며, `lines.json`·`v3` 의존을 지우고, 조건 이름을 `v1` 은 `현행(v1)`, `v2.<n>` 은 `새 지시(v2.<n>)`, `v2.<n>-table` 은 `v2 원칙 + 원본 표` 로 보이고, 판정 근거(`x_quotes`·`y_quotes`)로 형광 표시하며, 「결과 복사」 단추를 추가한다. 이 단추는 사용자가 판정자 점수와 다르게 고른 쌍만 `{"<idx>:<A>:<B>": <사용자 점수>}` JSON 으로 클립보드에 복사한다.
Run: `python ../replay/gen_reading_v5.py "$TEMP/rd.html" t ../replay/hidden1 hidden1 <Step 8 의 두 idx:v1:v2.1> && grep -c '결과 복사' "$TEMP/rd.html"`
Expected: `1` 이상, 두 쌍의 사용자 메시지 말풍선과 판정 점수가 보인다(브라우저로 열어 확인).

### Task 8: 금지어 목록 비교 60턴 (3단계, 미결 쟁점 1)

목록 비교를 본 시험보다 먼저 한다. 상시 보기가 미달이면 v2 리비전이 바뀌므로, 본 시험(Task 9)이 채택 후보 리비전 하나로만 실행되게 하기 위해서다.

**Files:**
- 저장소 밖: `replay\turns\hidden1-list-ids.txt`, `replay\hidden1\{v2.1,v2.1-table}-<idx>.json`, `calib\hidden1-list\<idx>-v2.1-table-v2.1.json`
- 미달 때만 Modify: `hooks/_banned_words.sh`, `scripts/test_hooks.sh`

**Interfaces:**
- Consumes: Task 7 도구.
- Produces: 채택한 v2 리비전 번호 `N`(통과면 1, 미달 처리 뒤면 2)과 `V2_REV.<N>.txt`. Task 9~12 가 `v2.<N>` 조건을 쓴다.

- [ ] **Step 1: 60턴을 고른다**

`random.Random(20261114)` 로 숨긴 세트에서 `지적` 30·`지적없음` 30 을 골라 `turns\hidden1-list-ids.txt` 에 idx 만 쓴다.

- [ ] **Step 2: 두 조건을 생성한다(업무 시간 밖)**

Run: `python replay6.py hidden1 v2.1 $(cat turns/hidden1-list-ids.txt) && python replay6.py hidden1 v2.1-table $(cat turns/hidden1-list-ids.txt)`
실패(`FAIL`·`ERR`)한 턴은 같은 명령으로 한 번 더 실행한다.
Expected: 조건마다 60개 이하, 모든 `models` 가 Opus 5.5 하나, `rev` 가 `V2_REV.1.txt` 의 커밋 하나다.

- [ ] **Step 3: 처음 10턴을 판정하고 단가와 예상 합계를 확인한다(업무 시간 밖)**

Run: `cd ../calib && python judge_hidden.py ../replay/hidden1 hidden1-list v2.1-table v2.1 "$REPLAY_TURNS" <처음 10개 idx>`
순서 교차 판정 한 번(`ab.cost + ba.cost`)의 평균을 실측 단가로 쓴다(이 계획의 기준값 0.116달러). 위반 판정 단가는 Task 9 Step 3 첫 결과로 바꾸기 전까지 0.063달러를 쓴다. 예상 합계 = 분류 누적 `cost`(Task 2 `label_pool.py` 출력) + 순서 교차 단가 × (목록 비교 60 + 본 시험 120 + 도구 분기 5 + 재시험 최대 150) + 위반 단가 × (본 시험 지적 턴 60 × 2 + 재시험 지적 턴 최대 75 × 2). 기준값으로 계산하면 분류를 빼고 약 55.9달러다.
Expected: 예상 합계가 80달러 이하면 진행한다. 넘으면 멈추고 비용과 함께 사용자에게 제안한다.

- [ ] **Step 4: 나머지를 판정하고 금지어를 센다**

Run: `python judge_hidden.py ../replay/hidden1 hidden1-list v2.1-table v2.1 "$REPLAY_TURNS" $(cat ../replay/turns/hidden1-list-ids.txt)`, `python ../replay/count_banned.py ../replay/hidden1 v2.1 v2.1-table --idx ../replay/turns/hidden1-list-ids.txt`, `python ../replay/report_hidden.py hidden1-list v2.1-table v2.1 "$REPLAY_TURNS" ../replay/hidden1`
Expected: 개선(상시 보기가 나음)·악화 수와 두 조건의 만 자당 금지어 검출, 행별 검출 파일 `banned-v2.1.json`·`banned-v2.1-table.json`.

- [ ] **Step 5: 채택을 판정한다**

상시 보기(`v2.1`)의 만 자당 검출이 원본 표(`v2.1-table`) 이하이고, 악화 턴 수가 개선 턴 수보다 많지 않으면 상시 보기를 채택하고 `N=1` 이다(spec 「측정으로 Claude 가 정할 쟁점」 1). 미달이면 Step 6 으로 간다.

- [ ] **Step 6(미달 때만): 검출이 늘어난 행을 원본 형식으로 싣는다**

행별 검출 파일에서 상시 보기 조건의 검출이 원본 표 조건보다 많은 행을 고른다(spec 「되돌리는 방법」). 그 행을 상시 보기에 원본 형식(제외어와 설명 포함)으로 싣는 방법과 행 식별 방식은 미달 결과를 보고 그때 정한다. 정한 형식을 `test_hooks.sh` 의 `list3.md` 픽스처 검사로 먼저 실패시키고(검사 이름 `원본 형식으로 싣는 행은 제외어를 함께 낸다`), `hooks/_banned_words.sh` 에 구현해 통과시킨 뒤 「변경 뒤 실행」·validate 를 통과시켜 커밋한다. 새 커밋을 `V2_REV.2.txt` 에 쓰고 `N=2` 다. `V2_REV.1.txt` 는 고치지 않는다.

```bash
git add hooks/_banned_words.sh scripts/test_hooks.sh
git commit -m "검출이 늘어난 금지어 행을 상시 보기에 원본 형식으로 싣는다" -m "Co-Authored-By: Claude Opus 5.5 <noreply@anthropic.com>
Claude-Session: https://claude.ai/code/session_01VjrV5UxDSPWWUxyS7m25jP"
git rev-parse HEAD > "$USERPROFILE/.dc-eval/replay/V2_REV.2.txt"
```

### Task 9: 숨긴 세트 v1 대 v2 생성·판정·집계 (3단계)

**Files (저장소 밖):** `replay\hidden1\{v1,v2.<N>}-<idx>.json`(답), `calib\hidden1\<idx>-v1-v2.<N>.json`(판정), `calib\hidden1-viol\{v1,v2.<N>}-<idx>.json`(지적 턴 위반 판정), `calib\hidden1\report.json`

**Interfaces:**
- Consumes: Task 7 도구, Task 8 의 `N`. `N=1` 이면 Task 8 의 `v2.1` 답 60개를 다시 생성하지 않는다(생략 조건).
- Produces: `report.json`. 채택 판정은 이 판정 파일들의 `rev_b` 리비전(`V2_REV.<N>.txt`)을 대상으로 한다.

- [ ] **Step 1: 생성한다(업무 시간 밖)**

```bash
cd "$USERPROFILE/.dc-eval/replay"; export REPLAY_TURNS="$PWD/turns/turns-hidden1-2026-11-13.jsonl"
ALL="$(cut -f1 turns/hidden1-ids.txt | tr '\n' ' ')"
python replay6.py hidden1 v1 $ALL > hidden1-v1.log
python replay6.py hidden1 v2.$N $ALL > hidden1-v2.$N.log
```
실패(`FAIL`·`ERR`)한 턴은 같은 명령으로 한 번 더 실행한다(완성된 결과는 생략된다).

- [ ] **Step 2: 생성 결과를 확인한다**

Run: `python -c` 한 줄로 `hidden1/v1-*.json`·`hidden1/v2.$N-*.json` 을 세고 `models`·`rev` 를 모은다.
Expected: 조건마다 결과 수 ≤ 120, 모든 `models` 가 `claude-opus-5-5` 하나, 조건마다 `rev` 가 하나(`v1` 은 `archive/v1-final`, `v2.$N` 은 `V2_REV.$N.txt`). 두 번 실패한 턴은 판정에서 빼고 그 수를 기록한다(spec 의 29개·110턴처럼 판정 대상 수로 보고한다).

- [ ] **Step 3: 판정한다(업무 시간 밖)**

Run: `cd ../calib && python judge_hidden.py ../replay/hidden1 hidden1 v1 v2.$N "$REPLAY_TURNS"`(idx 를 주지 않으면 턴 파일 전체), `python judge_v3h.py ../replay/hidden1 hidden1-viol v1 <지적 턴 idx>`, `python judge_v3h.py ../replay/hidden1 hidden1-viol v2.$N <지적 턴 idx>`
위반 판정 처음 10건의 `cost` 평균으로 Task 8 Step 3 의 예상 합계를 다시 계산해 80달러를 넘으면 멈추고 제안한다.
Expected: `error` 가 있는 판정은 같은 명령으로 한 번 더 실행하고, 그래도 남으면 판정 대상에서 빼고 수를 보고한다.

- [ ] **Step 4: 집계한다**

Run: `python ../replay/count_banned.py ../replay/hidden1 v1 v2.$N && python ../replay/report_hidden.py hidden1 v1 v2.$N "$REPLAY_TURNS" ../replay/hidden1 --viol hidden1-viol`
Expected: 개선·악화·같음 수, p, 평균, 지적 없던 턴의 개선·악화 수, 참고 지표, 길이 구간별 집계, 판독 후보 목록, 리비전 목록(조건마다 하나)이 출력되고 `report.json` 이 생긴다. 두 조건의 만 자당 금지어 검출은 Task 11 Step 3 의 통과 조건에 쓴다.

### Task 10: 도구 분기 시범 5턴 (3단계, 미결 쟁점 3)

**Files (저장소 밖):** `replay\hidden1-tools\{v1-tools,v2.<N>-tools}-<idx>.json`, `calib\hidden1-tools\<idx>-v1-tools-v2.<N>-tools.json`

- [ ] **Step 1: 5턴을 고른다**

숨긴 세트의 `지적` 턴 중 `decision_point` 가 `판단 위임`·`단계 넘김`·`범위 결정` 이고 `cwd` 가 git 저장소인 턴을 `idx` 순서로 5개 고른다. 모자라면 다른 `decision_point` 의 git 저장소 턴으로 채운다.

- [ ] **Step 2: 생성한다(업무 시간 밖)**

Run: `python replay6.py hidden1-tools v1-tools <5개>` 와 `python replay6.py hidden1-tools v2.$N-tools <5개>`
Expected: 10개, `models` 가 Opus 5.5 하나, `ls D:/dc-eval-tmp | grep -c '^replay-'` 가 0(임시 폴더와 그 안의 클론이 지워졌다).

- [ ] **Step 3: 판정하고 결론을 적는다(업무 시간 밖)**

Run: `python judge_hidden.py ../replay/hidden1-tools hidden1-tools v1-tools v2.$N-tools "$REPLAY_TURNS" <5개>`
결론에는 건당 입력 토큰(`usage`) 중간값, 판정 비용, 답마다 사용자에게 넘긴 작업이 있었는지를 적는다. 채택 기준은 이 계획이 정했다. 도구 조건의 건당 입력 토큰 중간값이 같은 턴의 도구 없는 조건 중간값의 3배 이하이고, 5턴 중 4턴 이상에서 판정이 두 순서 모두 점수와 비어 있지 않은 `x_quotes`·`y_quotes` 를 냈으면, 다음 지시 변경부터 도구 분기를 쓴다고 적는다. 하나라도 미달이면 도구 분기를 쓰지 않는다고 그 수치와 함께 적는다.

### Task 11: 사용자 판독, 채택 판정, 결과 기록 (3단계)

**Files:**
- Create(저장소 밖 결과): `%USERPROFILE%\.dc-eval\replay\hidden1\reading.json`
- Create(무시 폴더): `docs/html-reports/dc-hidden1-reading-<날짜>.html`
- Modify: `docs/domain-discipline.md`(`## v2 조항` 아래 「v2 상시 지시 검증」 절)

- [ ] **Step 1: 판독 페이지를 만들어 연다**

Run: `python "$USERPROFILE/.dc-eval/replay/gen_reading_v5.py" docs/html-reports/dc-hidden1-reading-$(date +%F).html dc-hidden1 "$USERPROFILE/.dc-eval/replay/hidden1" "$USERPROFILE/.dc-eval/calib/hidden1" <report.json 의 판독 후보 idx:v1:v2.N …> && start docs/html-reports/dc-hidden1-reading-$(date +%F).html`
Expected: `git status --short` 에 html 이 보이지 않는다(무시 폴더). 페이지가 Global Constraints 의 판독 페이지 규칙을 지킨다.

- [ ] **Step 2: 사용자 판독을 받는다**

사용자에게 페이지 경로와 "Claude 판정이 틀린 쌍만 고치고 「결과 복사」로 붙여 달라. 고치지 않은 쌍은 판정에 동의한 것으로 본다"는 안내를 보낸다. 받은 JSON(`{"<idx>:<A>:<B>": <사용자 점수 -2~2>}`, 고친 쌍만)을 `reading.json` 으로 저장한다.

- [ ] **Step 3: 채택을 판정한다**

Run: `python ../replay/report_hidden.py hidden1 v1 v2.$N "$REPLAY_TURNS" ../replay/hidden1 --viol hidden1-viol --reading ../replay/hidden1/reading.json`
3단계 통과 조건은 아래가 모두 참일 때다. spec 「시험 체계」 채택 규칙(숨긴 세트에서 개선 턴 > 악화 턴, 한쪽 부호 검정 p<0.05, 지적 없던 턴에서 악화 ≤ 개선, 사용자 판독 과반이 같거나 나음)과, spec 「완료 기준」의 금지어 조건(v2 답의 만 자당 금지어 검출 ≤ v1 답)이다. 개선·악화 수와 p 는 판독 반영 뒤 값으로 본다. 판정 대상은 `V2_REV.<N>.txt` 리비전이다.
Expected: 통과면 Step 4 로 간다. 금지어 조건만 미달이어도 미달로 보고 Step 4 를 실행한 뒤 Task 12 로 간다. 이때 Task 12 의 문구 수정은 행별 검출이 v1 보다 늘어난 행을 우선 대상으로 한다.

- [ ] **Step 4: 결과를 참고서에 기록한다(통과·미달 모두)**

`docs/domain-discipline.md` 의 `## v2 조항` 아래에 「v2 상시 지시 검증」 절을 쓴다(미달 뒤 재시험이면 같은 절에 차수를 나눠 추가한다). 숨긴 세트 정의(개발 세트·인용 메시지 제외, 지적 턴과 지적 없던 턴 수), 시험한 리비전(`V2_REV.<N>.txt` 의 커밋), 판정 대상 수, 개선·악화·같음, p, 평균, 지적 없던 턴 결과, 사용자 판독 결과와 판정 불일치 수, 참고 지표(금지어 만 자당 검출 포함), 대화 길이 구간별 결과, 목록 비교 결과와 채택 여부, 도구 분기 시범 결론, 상시 분량 실측(원칙 사본·상시 보기·합계, 리마인더 글자 수), 판정 비용 합계(`total_cost_usd`), 결과 위치(`%USERPROFILE%\.dc-eval\replay\hidden1\`, `calib\hidden1\` 등), 통과 여부를 적는다. 판정 인용문·`note`·대화 원문·턴 ID 는 적지 않는다.

- [ ] **Step 5: 확인하고 커밋한다**

Run: 「변경 뒤 실행」 명령, `claude plugin validate ./`
Expected: `ALL PASS`, `Validation passed`.

```bash
git add docs/domain-discipline.md
git commit -m "v2 상시 지시 검증 결과를 참고서에 기록한다" -m "Co-Authored-By: Claude Opus 5.5 <noreply@anthropic.com>
Claude-Session: https://claude.ai/code/session_01VjrV5UxDSPWWUxyS7m25jP"
```

- [ ] **Step 6: 사용자에게 보고한다**

통과면 결론(통과 조건 충족)과 4단계 plan 을 쓰겠다는 한 줄을 보고한다. 4단계 이후 plan 은 이 결과를 받아 별도로 쓴다. 미달이면 미달한 조건과 수치를 한 줄로 보고하고 Task 12 로 간다.

### Task 12 (조건부): 미달 때 문구 수정과 두 번째 숨긴 세트 재시험

Task 11 Step 3 이 미달일 때만 실행한다(spec 「되돌리는 방법」).

**Files:**
- Modify: `agent-principles.md` 또는 `hooks/reply_reminder_userpromptsubmit.sh`(고칠 대상만), `docs/domain-discipline.md`·`docs/domain-korean.md`(고친 조항의 v2 절)
- 미달 두 번째: Create `docs/superpowers/decisions/<날짜>-v2-stage3-stop.md`
- 저장소 밖: `V2_REV.<N+1>.txt`, `turns-hidden2-2026-11-13.jsonl`, `hidden2-ids.txt`, `replay\hidden2\`, `calib\hidden2\`·`hidden2-viol\`

- [ ] **Step 1: 문구를 한 번 고친다**

악화 쌍의 판정 문장(`note`·`y_quotes`)과 사용자 판독, 금지어가 미달이면 행별 검출이 늘어난 행을 근거로 원칙이나 리마인더 문구를 고친다. 저장소 `CLAUDE.md` 「에이전트원칙을 고칠 때」의 문구 규칙과 spec 퇴고 기준 질문(사용자 노력, 판정 가능성, 지시문 낱말)을 지킨다. 고친 근거는 참고서 해당 v2 절에 집계 수치와 근거 요지로 적고, 판정 인용문(`x_quotes`·`y_quotes`·`note`)과 대화 원문은 저장소 문서에 옮기지 않는다.
Run: `bash scripts/test_docs_drift.sh 2>&1 | grep -E 'FAIL|PASS='`
Expected: `원칙 사본에 금지어가 없다`·`리마인더에 금지어가 없다`·원칙 ID 근거 절 한 방향 검사가 PASS, `FAIL=0`. 그다음 「변경 뒤 실행」·validate 를 통과시키고 커밋한 뒤 새 커밋을 `V2_REV.<N+1>.txt` 에 쓴다(기존 리비전 파일은 고치지 않는다).

```bash
git add agent-principles.md hooks/reply_reminder_userpromptsubmit.sh docs/domain-discipline.md docs/domain-korean.md
git commit -m "v2 상시 지시 문구를 검증 결과로 한 번 고친다" -m "Co-Authored-By: Claude Opus 5.5 <noreply@anthropic.com>
Claude-Session: https://claude.ai/code/session_01VjrV5UxDSPWWUxyS7m25jP"
git rev-parse HEAD > "$USERPROFILE/.dc-eval/replay/V2_REV.$((N+1)).txt"
```

- [ ] **Step 2: 두 번째 세트 크기를 정한다**

첫 시험(`calib\hidden1\report.json`, 판독 반영 뒤)의 같음 비율을 계산한다. spec 측정 2 의 29개 시험은 개선 20·악화 3 이라 같음 6, 같음 비율 약 21% 다. 첫 시험의 같음 비율이 36% 이상(29개 시험보다 15%p 이상 높음. 이 경계값은 이 계획이 정했다)이면 spec 「숨긴 세트 크기」에 따라 지적 75·지적 없던 75(150턴)로 늘리고, 아니면 60·60 이다.

- [ ] **Step 3: 누적 비용을 확인한다**

Run: `python -c` 한 줄로 `calib\hidden*\*.json`·`calib\hidden*-viol\*.json` 의 `cost`(판정은 `ab.cost + ba.cost`)와 `replay\turns\pool-labels.jsonl` 의 `cost` 를 모두 합산하고, 재시험 예상(실측 순서 교차 단가 × 세트 크기 + 실측 위반 단가 × 지적 턴 수 × 2 + 추가 분류 예상)을 합산한다.
Expected: 합계가 80달러 이하면 진행한다. 넘으면 멈추고 비용과 함께 사용자에게 제안한다.

- [ ] **Step 4: 두 번째 숨긴 세트를 고른다(업무 시간 밖)**

Run: `python label_pool.py <첫 세트 지적 수 + 둘째 지적 수> <첫 세트 지적없음 수 + 둘째 지적없음 수>`(이어받기라 모자란 만큼만 묻는다), 그다음 `python pick_hidden.py 2 <지적 수> <지적없음 수>`
Expected: 첫 세트와 겹치는 턴 0, 개수가 Step 2 의 크기와 같다.

- [ ] **Step 5: Task 9·11 을 두 번째 세트로 다시 실행한다**

결과 폴더 이름은 `hidden2` 이고 조건은 `v1` 과 `v2.<N+1>` 이다. 첫 세트는 채택 판정에 다시 쓰지 않는다. 목록 비교와 도구 분기 시범은 다시 하지 않는다. Task 11 Step 4 의 기록도 다시 한다.

- [ ] **Step 6: 두 번째도 미달이면 멈추고 결정 기록을 남긴다**

4~7단계를 진행하지 않는다. `docs/superpowers/decisions/<날짜>-v2-stage3-stop.md` 에 결정("`v2-rebuild` 브랜치를 main 에 병합하지 않고 4~7단계를 진행하지 않는다"), 근거(두 시험의 리비전과 집계 수치, 참고서 「v2 상시 지시 검증」 절 위치), 브랜치 상태(커밋은 그대로 두고 v1 은 `archive/v1-final` 태그로 남는다)를 적는다. 대화 원문과 판정 인용문은 적지 않는다. 기록을 완성한 뒤 커밋한다(봉인 대상이다).

```bash
git add docs/superpowers/decisions/<날짜>-v2-stage3-stop.md
git commit -m "v2 상시 지시 검증 두 번 미달로 브랜치를 병합하지 않는다" -m "Co-Authored-By: Claude Opus 5.5 <noreply@anthropic.com>
Claude-Session: https://claude.ai/code/session_01VjrV5UxDSPWWUxyS7m25jP"
```

두 시험의 집계와 판독 결과를 사용자에게 보고한다. 이때 v2 재건축은 완료가 아니다(spec 「완료 기준」).

렌즈 리뷰(2026-11-13 두 번째 차수) 반영 뒤 설계를 틀리게 만드는 지적이 남지 않아 다시 리뷰하지 않는다.

<!-- spec-review: passed -->
