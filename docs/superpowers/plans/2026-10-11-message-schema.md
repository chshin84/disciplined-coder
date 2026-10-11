# nested-orchestration 메시지 형식 반영 Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** 승인된 spec 「2026-10-11 개정 — 메시지 형식」을 `skills/nested-orchestration/SKILL.md`에 반영하고, 그 절이 지워지거나 가리켜지지 않게 되면 실패하는 검사를 둔다.

**Architecture:** SKILL.md 에 새 절 「메시지 형식」(표기, 상향·하향 메시지, BLOCKED 처리, 보내는 순서, 리포트 스키마)을 「디스패치 템플릿」 바로 뒤에 두고, 메시지를 언급하던 기존 절은 그 절의 이름과 사유 코드로 가리키게 바꾼다. 검사는 `scripts/test_docs_drift.sh`에 절 이름과 백틱 식별자로 판정하는 블록을 추가한다(CLAUDE.md 「변경 뒤 실행」의 판정 규칙).

**Tech Stack:** Markdown, bash(`scripts/_doc_keys.sh`의 `has_sec`·`sec_has`·`sec_has_id`, `scripts/_test_check.sh`의 `check`)

**Spec:** `docs/superpowers/specs/2026-10-09-nested-orchestration-large-dev-design.md`의 「2026-10-11 개정 — 메시지 형식」 절(사용자 승인, plan 리뷰 반영으로 세 문장 보정)

## Global Constraints

- 상향 상태 값: `AWAITING_APPROVAL`, `BLOCKED <사유 코드>`, `DONE`, `FAILED`, `CANCELED`
- 사유 코드(처리 표 순서): `user-decision`, `contract-change`, `shared-file-change`, `dependency-add`, `test-double-add`, `review-red`, `review-gap`, `sdd-stop`
- 하향 메시지: `APPROVE`, `REVISE`, `ANSWER`, `BASE-UPDATED`, `CONTRACT-CHANGED`, `ASSUMPTION-ADDED`, `DEPENDENCY-REQUEST`, `INTEGRATION-FAILED`, `CANCEL`
- 리포트 절(순서): `확정한 결정`, `확정한 계약 의미`, `명세 이탈`, `스스로 판정한 모호함`, `기능적 반영`, `제안`
- 트레일러: `Questions:`는 `BLOCKED` 응답의 사유 코드 수, 형식 이탈 수는 `Format-Deviations:`
- 저장소 계약: 모든 커밋에서 `scripts/test_*.sh`가 FAIL=0 이다(CLAUDE.md 「변경 뒤 실행」). 검사는 문장을 그대로 찾지 않고 절 이름·백틱 식별자로 판정한다
- 찾아 바꾸기: 아래 '찾을 문장' 블록은 현재 SKILL.md 원문 그대로다. 구현자는 블록 안의 문자열을 그대로 찾아 '바꿀 문장' 블록으로 바꾼다
- 변경 뒤 실행: 검사 묶음 `ALL PASS`, `claude plugin validate ./`는 오류 없이 `Validation passed`

## Review Focus

- 메시지 이름 드리프트: 다른 절이 표에 없는 메시지 이름('승인 메시지', '통합 브랜치가 바뀌었다는 메시지')을 계속 쓰면 서브 세션이 할 일을 다르게 읽는다. Task 2 Step 6 의 grep 이 확인한다.
- 사유 코드 없는 BLOCKED: 「멈추는 기준」 불릿의 `(\`BLOCKED\`)` 형태나 `` `BLOCKED`로 멈춘다. `` 가 남으면 서브 세션이 코드를 고르지 못한다. Task 2 Step 6 의 grep 이 두 형태를 모두 확인한다. 「공용 파일」 둘째 문단의 리뷰 지적 인용(`BLOCKED`로 멈춘다고 지적했다)은 과거 기록이라 그대로 둔다.
- 절 삭제·이름 변경: 「메시지 형식」 절이나 그 안의 상태·메시지 이름이 지워지면 서브 세션이 읽을 원본이 없다. Task 1 의 검사가 잡는다.
- 다른 세션 개정과의 정합: 「검증 의존 대기」의 '실패 출력을 이어 쓰기로 보낸다'가 남으면 `INTEGRATION-FAILED`와 두 이름이 공존한다. Task 3 Step 4 의 grep 이 확인한다.
- 측정 정의: `Questions:` 정의가 옛 '질문 수'로 남으면 사유 여럿을 묶은 응답이 1 로 세어진다. Task 3 Step 4 의 grep 이 새 정의 문장이 있는지 확인한다.

---

### Task 1: 「메시지 형식」 절, 「용어」 항목, 절 검사

**Files:**
- Modify: `scripts/test_docs_drift.sh` (마지막 줄 `echo "----"; echo "PASS=…` 바로 앞)
- Modify: `skills/nested-orchestration/SKILL.md` (「용어」 표 끝, 「디스패치 템플릿」 절 끝)

**Interfaces:**
- Consumes: `scripts/_doc_keys.sh`의 `has_sec FILE 절`, `sec_has_id FILE 절 식별자`, `scripts/_test_check.sh`의 `check 이름 명령`(출력 `  PASS: 이름` 또는 `  FAIL: 이름`)
- Produces: SKILL.md 의 `## 메시지 형식` 절과 「용어」의 네 항목. Task 2·3 은 이 절 이름과 그 안의 메시지·사유 코드 이름을 가리킨다. 검사 블록의 머리줄 `[nested-message-format]`은 Task 2 가 포인터 검사를 덧붙이는 위치다.

- [ ] **Step 1: 실패하는 검사 작성**

`scripts/test_docs_drift.sh`의 마지막 줄 `echo "----"; echo "PASS=$pass FAIL=$fail"; [ "$fail" -eq 0 ]` 바로 앞에 아래 블록을 추가한다(앞뒤 빈 줄 하나씩).

```bash
echo "[nested-message-format] nested-orchestration 메시지 형식 절"
NO_DOC="$HERE/skills/nested-orchestration/SKILL.md"
check "「메시지 형식」 절이 있다" "has_sec \"\$NO_DOC\" '메시지 형식'"
for ID in AWAITING_APPROVAL DONE FAILED CANCELED user-decision contract-change shared-file-change dependency-add test-double-add review-red review-gap sdd-stop APPROVE REVISE ANSWER BASE-UPDATED CONTRACT-CHANGED ASSUMPTION-ADDED DEPENDENCY-REQUEST INTEGRATION-FAILED CANCEL Format-Deviations:; do
  check "「메시지 형식」에 $ID 가 있다" "sec_has_id \"\$NO_DOC\" '메시지 형식' '$ID'"
done
```

- [ ] **Step 2: 검사가 실패하는지 확인**

```bash
bash scripts/test_docs_drift.sh 2>&1 | grep -A30 'nested-message-format' | grep -c '^  FAIL:'
```

Expected: `23` (절 검사 하나와 식별자 검사 스물둘이 모두 실패한다)

- [ ] **Step 3: 「용어」 표에 네 항목 추가**

`skills/nested-orchestration/SKILL.md` 「용어」 표의 마지막 행(`| SDD | … |`) 바로 아래에 아래 네 행을 추가한다.

```markdown
| 머리줄(header) | 메시지의 첫 줄. 메시지 종류와, 종류가 `BLOCKED`이면 사유 코드를 적는다 |
| 상향 메시지 | 서브 세션이 현재 세션에 돌려주는 메시지 |
| 하향 메시지 | 현재 세션이 서브 세션에 보내는 메시지 |
| 사유 코드 | `BLOCKED`의 사유를 가리키는 정해진 이름(「메시지 형식」의 BLOCKED 처리 표) |
```

- [ ] **Step 4: 「메시지 형식」 절 추가**

`## 이어 쓰기와 재개` 줄 바로 앞에 아래 절을 넣는다(앞뒤 빈 줄 하나씩).

````markdown
## 메시지 형식

현재 세션과 서브 세션은 이 절의 형식으로만 메시지를 주고받는다. 서브 세션은 시작할 때와 하향 메시지를 받을 때 이 절과 「멈추는 기준」을 읽는다. 근거는 설계 문서 `docs/superpowers/specs/2026-10-09-nested-orchestration-large-dev-design.md`의 「2026-10-11 개정 — 메시지 형식」에 있다.

**표기.** 보내는 세션은 첫 줄에 머리줄을 적는다. 머리줄은 `<종류>` 또는 `BLOCKED <사유 코드>`다. 보내는 세션은 그 아래에 `필드: 값` 줄을 아래 표의 순서로 두고, 값이 없는 필드는 지우지 않고 `없음`으로 적는다.

**상향 메시지.** 서브 세션은 모든 상향 메시지에 `워크스트림`, `브랜치`(`ws/<개발>/<id> @ <커밋>`), `리포트`, `요약`을 공통 필드로 적는다. 판정 같은 상세는 리포트에만 적는다. 테스트 결과는 시험 병합이 직접 실행해 판정하므로 리포트에도 적지 않는다.

| 머리줄 | 추가 필드 | 보내는 때 |
|---|---|---|
| `AWAITING_APPROVAL` | `하부 명세`, `리뷰 기록`, `마커` | 하부 명세를 리뷰하고 커밋한 뒤 |
| `BLOCKED <사유 코드>` | `요청`, `이유`, `멈춘 작업` | 「멈추는 기준」의 사유에 해당할 때 |
| `DONE` | 없음 | 구현과 최종 리뷰를 마친 뒤 |
| `FAILED` | `원인`, `시도한 것`, `되돌릴 것` | 사유 코드 어디에도 들지 않는데 끝낼 수 없을 때 |
| `CANCELED` | `남긴 상태` | `CANCEL`을 받고 멈춘 뒤 |

서브 세션은 `FAILED`를 사유 코드 어디에도 들지 않을 때만 쓴다. 계약 불일치로 테스트가 실패하면 서브 세션은 `BLOCKED contract-change`를 쓴다. 권한이나 도구 설치처럼 사람이 조치해야 풀리는 환경 문제에는 `BLOCKED user-decision`을 쓴다. 같은 결함에 수정 시도가 세 번 실패하면 서브 세션은 고치기를 멈추고 `FAILED`를 돌려주며, `시도한 것`에 실패한 시도 내용을 적는다(superpowers `systematic-debugging`의 기준).

한 번 멈출 때 사유가 둘 이상이면, 서브 세션은 머리줄에 아래 처리 표에서 먼저 나오는 사유 코드를 적고 나머지는 `요청`에 줄마다 사유 코드와 함께 적는다. 현재 세션은 바로 처리할 수 있는 사유를 먼저 모두 답한다. 다른 워크스트림의 통합을 기다리는 `dependency-add`는 그 통합 뒤에 `BASE-UPDATED`로 따로 알린다.

**BLOCKED 처리.** 서브 세션은 공용 파일이나 큰 명세 본문을 바꿔야 할 때 `shared-file-change`를 고른다. 의존성 목록·잠금 파일이면 `dependency-add`를, 계약 코드의 테스트 대역이면 `test-double-add`를 고른다.

| 사유 코드 | 현재 세션이 할 일 | 보낼 메시지 |
|---|---|---|
| `user-decision` | 사용자에게 하나씩 묻고 답을 「결정 기록」에 커밋한다 | 요청한 쪽에 `ANSWER` |
| `contract-change` | 사용자에게 기각·미룸·채택을 고르게 한다. 채택하면 큰 명세와 계약 코드를 고친다 | 채택이면 그 계약 행의 제공자와 소비자 모두에 `CONTRACT-CHANGED`, 기각·미룸이면 요청한 쪽에 `ANSWER` |
| `shared-file-change` | 공용 파일이면 통합 브랜치에서 고친다. 큰 명세 본문이면 사용자에게 기각·미룸·채택을 고르게 한다 | 공용 파일이면 요청한 쪽에 `BASE-UPDATED`, 큰 명세 채택이면 바뀐 절이 다루는 워크스트림 모두에 `CONTRACT-CHANGED` |
| `dependency-add` | 소유 워크스트림이 통합 브랜치에 들어갔거나 `DONE`을 돌려줬으면 통합 브랜치에서 추가한다. 진행 중이면 소유 서브 세션이 멈출 때 추가를 요청한다 | 진행 중인 소유 쪽에 `DEPENDENCY-REQUEST`, 추가가 통합되면 요청한 쪽에 `BASE-UPDATED` |
| `test-double-add` | 계약 코드에 테스트 대역을 추가하고 계약 표의 단위·의미와 대조한다 | 요청한 쪽에 `BASE-UPDATED` |
| `review-red` | 🔴 를 사용자에게 알리고 답을 「결정 기록」에 적는다 | 요청한 쪽에 `ANSWER` |
| `review-gap` | 빠진 관점의 렌즈를 실행할지 사용자에게 묻는다 | 요청한 쪽에 `ANSWER` |
| `sdd-stop` | 비가역 작업, 보안 작업, 워크트리 밖 부작용이면 승인할지 사용자에게 묻는다. 전부 추측인 plan 이면 큰 명세나 「결정 기록」에 근거를 보강한다 | 요청한 쪽에 `ANSWER` |

`dependency-add`에서 소유 워크스트림이 `DONE`을 돌려줬으면 현재 세션은 그 병합을 기다리지 않고 통합 브랜치에서 바로 추가한다. 소유 워크스트림이 요청한 쪽에 검증 의존하면 두 워크스트림이 서로를 기다리기 때문이다. `sdd-stop`에서 사용자가 작업을 거절해도 현재 세션은 `ANSWER`로 거절과 대안을 보내고, 워크스트림을 접을지는 사용자에게 따로 묻는다.

공유 가정이 자기 구현과 다르면 서브 세션은 `BLOCKED contract-change`를 돌려준다. 현재 세션은 「결정 기록」의 그 가정을 대상으로 기각·미룸·채택을 고르게 하고, 채택하면 그 가정을 쓰는 서브 세션 모두에 `ASSUMPTION-ADDED`를 보낸다.

`FAILED`를 받으면 현재 세션은 원인과 되돌릴 것을 사용자에게 알리고, 같은 서브 세션에 `REVISE`, 새 서브 세션, `CANCEL` 중 하나를 고르게 한다. 새 서브 세션을 고르면 현재 세션은 디스패치 프롬프트에 그 리포트의 `원인`과 `시도한 것`을 넣는다. `CANCELED`를 받으면 현재 세션은 CLI 의 서브에이전트 화면에서 그 워크트리의 워커가 끝났는지 확인한다. 그 뒤 현재 세션은 브랜치와 워크트리를 남길지 지울지 사용자에게 묻는다.

**하향 메시지.** 현재 세션은 모든 하향 메시지에 `워크스트림`과 `통합 브랜치`(`dev/<개발> @ <커밋>`)를 공통 필드로 적는다. 아래 표의 '다음 응답'은 일을 마쳤을 때의 응답이다. 서브 세션은 어느 하향 메시지 뒤에도 사유에 해당하면 `BLOCKED`를, 끝낼 수 없으면 `FAILED`를 돌려준다.

| 머리줄 | 추가 필드 | 서브 세션이 할 일 | 다음 응답 |
|---|---|---|---|
| `APPROVE` | `승인한 하부 명세`, `조건` | writing-plans, `review-specs`, SDD 로 진행한다 | `DONE` |
| `REVISE` | `대상`, `고칠 항목` | 고칠 항목을 처리하고 커밋한다. 대상이 하부 명세면 다시 리뷰한다 | 대상이 하부 명세면 `AWAITING_APPROVAL`, 구현이면 `DONE` |
| `ANSWER` | `질문`, `답`, `결정 기록` | 답을 반영해 멈춘 작업을 이어 간다 | 하던 단계의 응답 |
| `BASE-UPDATED` | `바뀐 것`, `할 일` | 자기 워크트리에서 `git merge dev/<개발>`을 실행하고 테스트를 다시 실행한 뒤 이어 간다 | 하던 단계의 응답 |
| `CONTRACT-CHANGED` | `바뀐 항목`, `커밋` | 통합 브랜치를 병합하고 바뀐 계약 행이나 큰 명세 절에 맞춘다. 하부 명세가 바뀌면 다시 리뷰한다 | 하부 명세가 바뀌었으면 `AWAITING_APPROVAL`, 아니면 하던 단계의 응답 |
| `ASSUMPTION-ADDED` | `가정`, `결정 기록` | 통합 브랜치를 병합한다. 자기 구현이 그 가정과 다르면 고치지 않고 `BLOCKED contract-change`로 알린다 | 하던 단계의 응답 |
| `DEPENDENCY-REQUEST` | `패키지`, `요청한 워크스트림` | 의존성 목록과 잠금 파일에 패키지를 추가하고 커밋한 뒤 하던 단계로 돌아간다 | 하던 단계의 응답 |
| `INTEGRATION-FAILED` | `확인 위치`, `실패 검사`, `출력` | 원인을 고치고 커밋한다 | `DONE` |
| `CANCEL` | `이유` | 미커밋 변경을 커밋하지 않고 워크트리에 남긴 채 멈춘다 | `CANCELED` |

`INTEGRATION-FAILED`의 `확인 위치`는 시험 병합의 `try/<id>` 커밋이거나, 이미 병합된 워크스트림의 통합 확인을 다시 실행한 `dev/<개발>` 커밋이다.

현재 세션은 하부 명세 수정 요청 말고도 아래 상황에서 `REVISE`를 쓴다.

- 허용 경로 밖 변경: 「수정 범위 대조」가 허용 경로 밖 파일을 낸 상황
- 리뷰 마커 없음: 추가된 하부 명세나 plan 의 마지막 줄에 리뷰 마커가 없는 상황
- 교집합 겹침: 「교집합 검사」가 두 워크스트림의 같은 파일을 낸 상황
- 판정 번복: 하부 명세 승인이나 「판정 기록 확인」에서 사용자가 서브 세션의 판정을 뒤집은 상황
- 실패 뒤 재시도: `FAILED` 뒤 같은 서브 세션에 다시 시키기로 한 상황
- 형식 이탈: 상향 메시지가 판단에 필요한 필드를 빠뜨린 상황

교집합 겹침에서 현재 세션은 사용자에게 알린 뒤, 그 파일을 고치지 않기로 정한 쪽에 `REVISE`를 보낸다. 실패 뒤 재시도에서 고칠 코드가 없으면 현재 세션은 `고칠 항목`에 다시 실행할 단계를 적고, 형식 이탈에서는 `대상`에 '응답'을 적는다. 리뷰 마커가 `escalated`인데 「결정 기록」에 답이 없으면 현재 세션은 `REVISE`를 보내지 않고 `review-red` 처리대로 🔴 를 사용자에게 알려 답을 적는다. 시험 병합의 테스트나 통합 확인이 실패하면 현재 세션은 `INTEGRATION-FAILED`를 쓴다.

**보내는 순서.** 현재 세션은 메시지를 서브 세션이 멈춘 뒤에만 보낸다. 같은 서브 세션에 보낼 메시지가 여럿이면 한 번에 묶어 보내고, 통합 브랜치를 바꾸는 메시지(`BASE-UPDATED`, `CONTRACT-CHANGED`, `ASSUMPTION-ADDED`)를 앞에 둔다. 받을 서브 세션이 실행 중이어서 미룬 메시지는 「시험 병합」 전의 확인으로 되찾는다.

**리포트 스키마.** 서브 세션은 리포트 파일에 아래 절 제목을 이 순서로 두고, 내용이 없는 절도 `없음`으로 남긴다.

| 절 제목 | 형식 | 현재 세션이 읽는 곳 |
|---|---|---|
| `확정한 결정` | 줄마다 '결정 — 이유' | 통합 때의 「결정 기록」 갱신 |
| `확정한 계약 의미` | 줄마다 '계약 행 — 칸(의미 또는 형식의 열거값) — 값' | 통합 때의 계약 표 '확정 예정' 칸 |
| `명세 이탈` | 줄마다 '하부 명세의 위치 — 실제 구현 — 이유' | 「판정 기록 확인」 |
| `스스로 판정한 모호함` | 줄마다 '질문 — 판정 — 이유 — 범위 밖 항목에 가까운지(예·아니오)' | 하부 명세 승인과 「판정 기록 확인」 |
| `기능적 반영` | 리뷰 반영 중 동작이 바뀐 항목 | 「흐름」 마무리 |
| `제안` | 범위 밖 아이디어 | 「흐름」 마무리 |

**형식 이탈.** 머리줄이 이 절의 종류와 사유 코드 밖이거나 정해진 필드가 빠진 응답은 형식 이탈이다. 현재 세션은 판단할 수 있으면 해석해 진행하고, 판단에 필요한 필드가 빠졌으면 `REVISE`(대상: 응답)를 보낸다. 현재 세션은 두 경우 모두 「측정」의 `Format-Deviations:`에 센다.
````

- [ ] **Step 5: 검사 통과 확인**

```bash
bash scripts/test_docs_drift.sh 2>&1 | grep -A30 'nested-message-format' | grep -c '^  FAIL:'
bash scripts/test_docs_drift.sh 2>&1 | tail -1
```

Expected: 첫 줄 `0`, 둘째 줄 `PASS=… FAIL=0`

- [ ] **Step 6: 커밋**

```bash
git add scripts/test_docs_drift.sh skills/nested-orchestration/SKILL.md
git commit -m "nested-orchestration 에 「메시지 형식」 절과 용어 넷을 두고, 절과 메시지 이름이 지워지면 실패하는 검사를 추가한다"
```

---

### Task 2: 서브 세션 쪽 절이 「메시지 형식」을 가리키게 한다

**Files:**
- Modify: `scripts/test_docs_drift.sh` (Task 1 블록 끝)
- Modify: `skills/nested-orchestration/SKILL.md` — 「디스패치 템플릿」 3·5·8번 블록, 「멈추는 기준」, 「이어 쓰기와 재개」, 「공용 파일」 첫·셋째 문단, 「계약 표」, 「계약 코드」의 테스트 대역 문단, 「승인 항목」

**Interfaces:**
- Consumes: Task 1 의 `## 메시지 형식` 절, 메시지·사유 코드 이름, `[nested-message-format]` 검사 블록
- Produces: 포인터 검사 셋이 통과하는 SKILL.md

- [ ] **Step 1: 실패하는 포인터 검사 추가**

Task 1 에서 추가한 `for ID in … done` 블록 바로 아래에 아래 세 줄을 추가한다.

```bash
check "「디스패치 템플릿」이 「메시지 형식」을 가리킨다" "sec_has \"\$NO_DOC\" '디스패치 템플릿' '「메시지 형식」'"
check "「멈추는 기준」이 「메시지 형식」을 가리킨다" "sec_has \"\$NO_DOC\" '멈추는 기준' '「메시지 형식」'"
check "「이어 쓰기와 재개」가 「메시지 형식」을 가리킨다" "sec_has \"\$NO_DOC\" '이어 쓰기와 재개' '「메시지 형식」'"
```

```bash
bash scripts/test_docs_drift.sh 2>&1 | grep -A30 'nested-message-format' | grep -c '^  FAIL:'
```

Expected: `3`

- [ ] **Step 2: 「디스패치 템플릿」 고치기**

3번 블록의 찾을 문장:

```text
공용 파일이나 계약 변경이 필요하면 고치지 않고, 바꿀 내용을 적어 `BLOCKED`로 멈춘다.
```

바꿀 문장:

```text
공용 파일이나 계약 변경이 필요하면 고치지 않고, 바꿀 내용을 적어 `BLOCKED shared-file-change`나 `BLOCKED contract-change`로 멈춘다.
```

5번 블록의 찾을 문장 둘과 바꿀 문장:

```text
승인 메시지를 받으면
```

```text
`APPROVE`를 받으면
```

```text
통합 브랜치가 바뀌었다는 메시지를 받으면 자기 워크트리에서 `git merge dev/<개발 이름>`으로 받은 뒤 일을 잇는다.
```

```text
하향 메시지를 받으면 「메시지 형식」의 하향 메시지 표대로 처리한다.
```

8번 블록의 찾을 문장(블록 끝의 두 문장):

```text
리포트에는 변경 파일, 테스트 최종 결과, 확정한 결정, 명세 이탈, 범위 밖 아이디어(「제안」), 스스로 판정한 모호함, 리뷰 반영 중 기능적 변화가 있었던 항목, 브랜치명을 적는다. 현재 세션에 돌려주는 것은 상태, 질문이나 블로커, 한 줄 요약, 리포트 경로뿐이다.
```

바꿀 문장:

```text
리포트는 「메시지 형식」의 리포트 스키마대로 쓴다. 현재 세션은 이 SKILL.md 의 절대 경로도 넣는다. 그 경로는 현재 세션이 연 파일의 경로이며, 플러그인이 개발 도중 갱신되어도 두 세션이 같은 형식을 읽게 하기 위해서다. 서브 세션은 시작할 때와 하향 메시지를 받을 때 그 파일의 「메시지 형식」과 「멈추는 기준」을 읽는다.
```

8번 블록 앞부분의 '「멈추는 기준」의 사유와 상태 값을 넣는다'와 리포트 경로 문장은 그대로 둔다.

- [ ] **Step 3: 「멈추는 기준」 고치기**

찾을 문장(절 첫 문장):

```text
서브 세션은 아래 사유에서만 멈추고 상태와 질문을 돌려준다.
```

바꿀 문장:

```text
서브 세션은 아래 사유에서만 멈추고 「메시지 형식」의 상향 메시지를 돌려준다. 예외는 사유 코드 어디에도 들지 않는데 끝낼 수 없을 때의 `FAILED`다.
```

찾을 문장(사유 불릿 넷 전체):

```text
- 하부 명세 리뷰를 마쳐 승인을 기다릴 때(`AWAITING_APPROVAL`)
- 하부 명세나 plan 리뷰에서 🔴가 나왔거나, 리스크상 필요한 리뷰 관점을 아무 렌즈도 보지 않았을 때(`BLOCKED`)
- 사람만 정할 수 있는 범위 밖 결정이나 계약·큰 명세·공용 파일 변경이 필요할 때(`BLOCKED`)
- SDD의 정지 사유(비가역 작업, 보안 작업, 워크트리 밖 부작용, 전부 추측인 plan)에 해당할 때(`BLOCKED`)
```

바꿀 문장:

```text
- 하부 명세 리뷰를 마쳐 승인을 기다릴 때(`AWAITING_APPROVAL`)
- 하부 명세나 plan 리뷰에서 🔴가 나왔을 때(`BLOCKED review-red`)
- 리스크상 필요한 리뷰 관점을 아무 렌즈도 보지 않았을 때(`BLOCKED review-gap`)
- 사람만 정할 수 있는 범위 밖 결정이 필요할 때(`BLOCKED user-decision`)
- 계약을 바꿔야 할 때(`BLOCKED contract-change`)
- 공용 파일이나 큰 명세 본문을 바꿔야 할 때(`BLOCKED shared-file-change`)
- 의존성 목록·잠금 파일에 패키지를 추가해야 할 때(`BLOCKED dependency-add`)
- 계약 코드에 없는 테스트 대역이 필요할 때(`BLOCKED test-double-add`)
- SDD의 정지 사유(비가역 작업, 보안 작업, 워크트리 밖 부작용, 전부 추측인 plan)에 해당할 때(`BLOCKED sdd-stop`)
```

찾을 문장(「스스로 판정한 모호함」 문단의 두 문장):

```text
드는지 확실하지 않으면 스스로 판정하고 리포트의 「스스로 판정한 모호함」에 판정과 이유를 적는다. 현재 세션은 하부 명세 승인과 병합 전 검사에서 그 「스스로 판정한 모호함」 목록을 읽는다.
```

바꿀 문장:

```text
드는지 확실하지 않으면 스스로 판정하고 리포트의 `스스로 판정한 모호함`에 판정과 이유, 범위 밖 항목에 가까운지를 적는다. 현재 세션은 하부 명세 승인과 「판정 기록 확인」에서 그 절을 읽는다.
```

찾을 문장(절 끝 문단 전체):

```text
현재 세션은 질문을 사용자에게 하나씩 알리고, 답을 큰 명세 「결정 기록」에 적은 뒤 같은 서브 세션에 보낸다. 계약 변경 요청이면 사용자에게 기각, 다음 개발로 미룸, 지금 채택 중 하나를 고르게 한다. 채택하면 현재 세션이 통합 브랜치에서 큰 명세와 계약 코드를 고친 뒤 영향받는 서브 세션에 알린다.
```

바꿀 문장:

```text
현재 세션은 사유 코드마다 「메시지 형식」의 BLOCKED 처리 표대로 처리한다.
```

- [ ] **Step 4: 「이어 쓰기와 재개」 고치기**

찾을 문장:

```text
현재 세션은 하부 명세 승인 뒤 진행 지시, 사용자 답, 통합 실패 출력, 그 워크스트림의 계약·공용 파일 변경, 다른 워크스트림에서 생긴 공유 가정, 의존성 추가 요청을 모두 그 워크스트림의 서브 세션에 이어 쓰기로 보낸다.
```

바꿀 문장:

```text
현재 세션은 「메시지 형식」의 하향 메시지를 모두 그 워크스트림의 서브 세션에 이어 쓰기로 보낸다.
```

- [ ] **Step 5: 「공용 파일」, 「계약 코드」, 「계약 표」, 「승인 항목」 고치기**

「공용 파일」 첫 문단의 찾을 문장과 바꿀 문장:

```text
그 워크스트림이 끝난 뒤에는 현재 세션이 고친다.
```

```text
그 워크스트림이 통합 브랜치에 들어갔거나 `DONE`을 돌려준 뒤에는 현재 세션이 고친다.
```

「공용 파일」 셋째 문단 전체의 찾을 문장:

```text
다른 워크스트림은 기존 의존성으로 일하고, 의존성 추가가 필요하면 추가할 패키지를 적어 `BLOCKED`로 멈춘다. 소유 워크스트림이 끝났으면 현재 세션이 통합 브랜치에서 추가한다. 소유 워크스트림이 진행 중이면 현재 세션은 그 서브 세션이 멈추거나 끝날 때 요청을 이어 쓰기로 보내므로, 멈춘 워크스트림은 그동안 기다린다. 추가가 통합되면 현재 세션은 멈춘 워크스트림에 통합 브랜치가 바뀌었다고 알린다.
```

바꿀 문장:

```text
다른 워크스트림은 기존 의존성으로 일하고, 의존성 추가가 필요하면 추가할 패키지를 적어 `BLOCKED dependency-add`로 멈춘다. 처리는 「메시지 형식」의 BLOCKED 처리 표를 따른다.
```

「공용 파일」 둘째 문단의 리뷰 지적 인용(`BLOCKED`로 멈춘다고 지적했다)은 과거 기록이므로 그대로 둔다.

「계약 코드」 테스트 대역 문단의 찾을 문장과 바꿀 문장:

```text
필요한 테스트 대역이 계약 코드에 없으면 서브 세션은 「공용 파일」의 의존성 추가와 같이 `BLOCKED`로 요청한다.
```

```text
필요한 테스트 대역이 계약 코드에 없으면 서브 세션은 `BLOCKED test-double-add`로 요청한다.
```

「계약 표」의 찾을 문장:

```text
의미 칸의 시간과 결측은 비워 두지 않고, 해당이 없으면 '없음'을 적는다.
```

바꿀 문장(찾을 문장 뒤에 두 문장을 이어 붙인다):

```text
의미 칸의 시간과 결측은 비워 두지 않고, 해당이 없으면 '없음'을 적는다. 「묶는 단위」가 의미를 소유 워크스트림 통합 때 확정하게 한 행에서, 현재 세션은 의미 칸과 형식 칸의 열거값을 '확정 예정(<소유 워크스트림 id>)'으로 적는다. 현재 세션은 그 워크스트림을 통합할 때 리포트의 `확정한 계약 의미`를 보고 칸을 채우며, 이 확정은 계약 변경이 아니다.
```

「승인 항목」 첫 문단의 찾을 문장:

```text
하부 명세나 리포트의 「스스로 판정한 모호함」에 「멈추는 기준」의 범위 밖 항목에 드는 결정이 있으면 현재 세션은 승인하기 전에 사용자에게 묻는다.
```

바꿀 문장:

```text
현재 세션은 승인하기 전에 리포트의 `스스로 판정한 모호함`을 읽는다. 그 절의 줄이 범위 밖 항목에 가깝다고 표시되어 있으면 현재 세션은 그 줄을 사용자에게 묻고, 사용자가 판정을 뒤집으면 `REVISE`를 보낸다.
```

「승인 항목」 둘째 문단의 찾을 문장:

```text
같은 가정을 쓸 다른 서브 세션에는 멈추거나 끝날 때 이어 쓰기로 알린다. 그 서브 세션이 이미 다른 가정으로 구현했으면 현재 세션은 계약 변경과 같이 사용자에게 기각, 다음 개발로 미룸, 지금 채택 중 하나를 고르게 한다.
```

바꿀 문장:

```text
같은 가정을 쓸 다른 서브 세션에는 `ASSUMPTION-ADDED`를 보낸다. 그 서브 세션이 이미 다른 가정으로 구현했으면 `BLOCKED contract-change`를 돌려주고, 현재 세션은 「메시지 형식」의 BLOCKED 처리대로 처리한다.
```

- [ ] **Step 6: 검사와 옛 문구 확인**

```bash
bash scripts/test_docs_drift.sh 2>&1 | grep -A30 'nested-message-format' | grep -c '^  FAIL:'
grep -n -E '`BLOCKED`(로 멈춘다\.|로 요청한다|\))|승인 메시지|통합 브랜치가 바뀌었다는 메시지|통합 브랜치가 바뀌었다고 알린다|돌려주는 것은 상태' skills/nested-orchestration/SKILL.md
```

Expected: 첫 명령 `0`, 둘째 명령 출력 없음

- [ ] **Step 7: 커밋**

```bash
git add scripts/test_docs_drift.sh skills/nested-orchestration/SKILL.md
git commit -m "nested-orchestration 의 디스패치 템플릿·멈추는 기준·이어 쓰기·공용 파일·계약 표·승인 항목이 「메시지 형식」의 이름을 가리키게 한다"
```

---

### Task 3: 현재 세션 쪽 절(가드레일·흐름·측정)을 맞춘다

**Files:**
- Modify: `skills/nested-orchestration/SKILL.md` — 「흐름」 7번, 「가드레일」의 「수정 범위 대조」·「교집합 검사」·「리뷰 마커 확인」·「판정 기록 확인」·「검증 의존 대기」·「시험 병합」, 「측정」

**Interfaces:**
- Consumes: Task 1 의 메시지 이름(`REVISE`, `INTEGRATION-FAILED`, `BASE-UPDATED`, `CONTRACT-CHANGED`, `ASSUMPTION-ADDED`)과 리포트 절 이름, `Format-Deviations:`
- Produces: 최종 SKILL.md

- [ ] **Step 1: 「흐름」 7번 고치기**

```text
서브 세션들의 리포트에서 「제안」을 모아 사용자에게 보이고, 「측정」 값을 보고한다.
```

```text
서브 세션들의 리포트에서 `제안`과 `기능적 반영`을 모아 사용자에게 보이고, 「측정」 값을 보고한다.
```

- [ ] **Step 2: 「가드레일」 고치기**

「수정 범위 대조」:

```text
출력에 파일이 나오면 병합하지 않고 그 서브 세션에 되돌린다.
```

```text
출력에 파일이 나오면 병합하지 않고 그 서브 세션에 `REVISE`를 보낸다.
```

「교집합 검사」:

```text
한 쌍이라도 비어 있지 않으면 병합 전에 멈추고 알린다.
```

```text
한 쌍이라도 비어 있지 않으면 현재 세션은 병합 전에 멈추고 사용자에게 알린 뒤, 그 파일을 고치지 않기로 정한 쪽에 `REVISE`를 보낸다.
```

「리뷰 마커 확인」:

```text
마커가 없으면 병합하지 않는다. 마커가 `escalated`이면 그 🔴의 사용자 답이 큰 명세 「결정 기록」에 있는지 확인하고, 없으면 병합하지 않는다.
```

```text
마커가 없으면 병합하지 않고 그 서브 세션에 `REVISE`를 보낸다. 마커가 `escalated`이면 그 🔴의 사용자 답이 큰 명세 「결정 기록」에 있는지 확인하고, 없으면 병합하지 않고 `review-red` 처리대로 사용자에게 묻는다.
```

「판정 기록 확인」:

```text
현재 세션은 리포트의 「스스로 판정한 모호함」을 읽고, 「멈추는 기준」의 범위 밖 항목에 드는 판정이 있으면 병합하기 전에 사용자에게 묻는다.
```

```text
현재 세션은 병합하기 전에 리포트의 `스스로 판정한 모호함`과 `명세 이탈`을 읽는다. 범위 밖 항목에 가깝다고 표시된 줄과 `명세 이탈`의 줄을 현재 세션은 사용자에게 묻고, 사용자가 판정을 뒤집으면 `REVISE`를 보낸다.
```

「검증 의존 대기」 둘째 문단:

```text
Y의 서브 세션에 실패 출력을 이어 쓰기로 보낸다.
```

```text
Y의 서브 세션에 `INTEGRATION-FAILED`를 보낸다. 대기 중인 워크스트림의 서브 세션이 대상의 통합 결과를 받아야 하면 현재 세션은 그 서브 세션에 `BASE-UPDATED`를 보낸다.
```

「시험 병합」 첫 문장 `` 현재 세션은 `git switch -c try/<id> dev/<개발>`로 `` 바로 앞에 아래 문장을 넣는다.

```text
현재 세션은 시험 병합 전에 `git log --oneline ws/<개발>/<id>..dev/<개발> -- <계약 코드 경로> <큰 명세 경로>`를 실행한다. 출력이 비어 있지 않으면 그 워크스트림은 바뀐 계약이나 큰 명세를 받지 않았으므로, 현재 세션은 병합하지 않고 `BASE-UPDATED`를 보낸다. 출력의 커밋이 그 워크스트림이 제공자나 소비자인 계약 행을 바꿨으면 `CONTRACT-CHANGED`를, 그 워크스트림이 쓰는 공유 가정을 추가했으면 `ASSUMPTION-ADDED`를 대신 보낸다.
```

같은 문단의 찾을 문장과 바꿀 문장:

```text
원인이 계약이면 큰 명세로, 워크스트림 내부면 그 서브 세션으로 보낸다.
```

```text
원인이 계약이면 큰 명세로, 워크스트림 내부면 그 서브 세션에 `INTEGRATION-FAILED`로 보낸다.
```

- [ ] **Step 3: 「측정」 고치기**

```text
현재 세션은 워크스트림마다 실패한 시험 병합 수와 그 원인, 서브 세션이 올린 질문 수, 완료 통지의 `subagent_tokens`를 센다.
```

```text
현재 세션은 워크스트림마다 실패한 시험 병합 수와 그 원인, `BLOCKED` 응답의 사유 코드 수, 「메시지 형식」의 형식 이탈 수, 완료 통지의 `subagent_tokens`를 센다.
```

```text
`Integration-Failures:`, `Questions:`, `Tokens:` 트레일러로 넣는다.
```

```text
`Integration-Failures:`, `Questions:`(사유 코드 수), `Format-Deviations:`, `Tokens:` 트레일러로 넣는다.
```

같은 절 끝에 아래 문장을 추가한다.

```text
`FAILED`나 `CANCELED`로 끝나 병합되지 않은 워크스트림은 트레일러가 남지 않으므로, 현재 세션은 마무리 보고에서 그 워크스트림을 따로 적는다.
```

- [ ] **Step 4: 옛 문구 확인과 전체 검사**

```bash
grep -n -E '실패 출력을 이어 쓰기로|서브 세션이 올린 질문 수|그 서브 세션에 되돌린다|병합 전에 멈추고 알린다\.' skills/nested-orchestration/SKILL.md
grep -c 'Format-Deviations:' skills/nested-orchestration/SKILL.md
grep -c 'Questions:`(사유 코드 수)' skills/nested-orchestration/SKILL.md
```

Expected: 첫 명령 출력 없음, 둘째 `2`(「메시지 형식」의 형식 이탈 문단과 「측정」의 트레일러 문장), 셋째 `1`

CLAUDE.md 「변경 뒤 실행」의 검사 묶음 한 줄을 실행한다. Expected: `ALL PASS`

```bash
claude plugin validate ./
```

Expected: 오류 없이 `Validation passed`

- [ ] **Step 5: 커밋**

```bash
git add skills/nested-orchestration/SKILL.md
git commit -m "nested-orchestration 가드레일·흐름·측정이 REVISE·INTEGRATION-FAILED·BASE-UPDATED·Format-Deviations 를 쓰게 한다"
```

<!-- spec-review: passed -->
