# 중첩 오케스트레이션 (nested-orchestration) 구현 계획

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** disciplined-coder에 "멀티태스크 플랜이 둘 이상이면 3층으로 병렬 실행하라"는 넛지(§마)와 그 방법의 SSOT 스킬(`nested-orchestration`)을 추가한다.

**Architecture:** 두 산출물뿐이다 — (1) `agent-principles.md` §절차에 트리거 한 줄(§마), (2) `skills/nested-orchestration/SKILL.md`. 강제는 이 레포 관례대로 계약 테스트(`test_scaffold.sh`)의 드리프트 가드로 건다(case15 §가-행 가드, case13 README↔commands 가드와 같은 패턴). 스킬은 자동 발견되므로 매니페스트 편집은 없다.

**Tech Stack:** Markdown(정본·스킬), Bash(계약 테스트), `claude plugin validate`.

## Global Constraints
- 이 레포는 플러그인 자체다. 디시플린 정본 `agent-principles.md`(레포 루트)가 SSOT — **이 파일만 수정**한다(scaffold가 `~/.claude`로 복사; 사본 직접 수정 금지).
- 스킬은 `skills/<name>/SKILL.md`로 두면 **자동 발견**된다 — `.claude-plugin/plugin.json`에 skills 키가 없고, `.codex-plugin/plugin.json`은 `"skills": "./skills/"` 글로브다. **매니페스트 편집 금지(no-op)**.
- 계약은 **불변식 FAIL=0**으로 검증한다 — 기대 개수 매직 넘버 금지(`SSOT`). 새 체크는 `check` 헬퍼로 추가하고 말미 `[ "$fail" -eq 0 ]`를 유지한다.
- 드리프트 가드에서 **다중 섹션 파일(정본)은 해당 블록을 뽑아 그 안에서** 검사한다(vacuous 통과 방지 — case15 방식). 단일 목적 파일(스킬 SKILL.md)은 파일 전역 존재 검사로 충분하다 — 섹션 경합이 없다.
- 변경 후 검증: `bash scripts/test_scaffold.sh` + `bash scripts/test_hooks.sh` + `bash scripts/test_codex_scaffold.sh`(각 FAIL=0) + `claude plugin validate ./`(non-strict).
- 출력·문서는 완결된 문어체(`CLEAR-COMM`). §절차 본문은 *언제·무엇*만(트리거 인덱스), *어떻게*는 스킬이 SSOT — 상시 로드를 가볍게.
- 스킬은 기존 스킬을 재구현하지 않고 가리킨다: `brainstorming`·`writing-plans`·`subagent-driven-development`·`dispatching-parallel-agents`·`using-git-worktrees`.

---

### Task 1: §마 넛지를 정본에 추가 + 드리프트 가드

정본 `agent-principles.md` §절차에 §마 트리거를 넣고, 그 존재와 "스킬을 가리킨다 / 단일태스크는 2층으로 라우팅한다"는 계약을 `test_scaffold.sh`에 가드로 박는다. 테스트를 먼저 써서 실패를 확인한 뒤 정본을 고친다.

**Files:**
- Modify: `agent-principles.md` (§라 블록 뒤, `## 절차` 섹션 끝)
- Modify: `scripts/test_scaffold.sh` (case15 뒤에 case16 추가; 말미 요약 줄은 그대로)

**Interfaces:**
- Produces: `agent-principles.md`에 `### 마.` 헤딩과 문자열 `nested-orchestration`·`dispatching-parallel-agents`를 같은 블록에 포함. Task 2가 이 스킬 이름을 공유한다.

- [ ] **Step 1: 실패하는 계약 테스트를 먼저 쓴다**

`scripts/test_scaffold.sh`에서 case15 블록(라인 231~238, `echo "----"` 직전) 뒤에 아래를 삽입한다:

```bash
# --- 케이스 16: §마 병렬 오케스트레이션 넛지(정본 계약 가드) ---
# §마 헤딩부터 다음 '### ' 또는 '## '까지의 블록만 뽑아 그 안에서 검사한다(vacuous 통과 방지).
PO_BLOCK="$(awk '/^### 마\./{f=1} f&&/^### /&&!/^### 마\./{exit} f&&/^## /&&!/^### /{exit} f' "$HERE/agent-principles.md")"
echo "[case16] principles §마 nested-orchestration nudge"
check "§마 heading exists"            "printf '%s' \"\$PO_BLOCK\" | grep -qF '### 마.'"
check "§마 points to skill (SSOT)"    "printf '%s' \"\$PO_BLOCK\" | grep -qF 'nested-orchestration'"
check "§마 routes single-task to 2층" "printf '%s' \"\$PO_BLOCK\" | grep -qF 'dispatching-parallel-agents'"
```

- [ ] **Step 2: 테스트를 돌려 실패를 확인한다**

Run: `bash scripts/test_scaffold.sh`
Expected: `[case16]`의 세 체크가 `FAIL`, 말미 `PASS=… FAIL=3`(정확히 3이 아니어도 FAIL>0이면 됨 — 매직 넘버로 세지 않는다), 스크립트 exit 1.

- [ ] **Step 3: 정본에 §마를 추가한다**

`agent-principles.md`는 `## 절차`가 마지막 `## ` 섹션이고 `### 라.`가 그 마지막 하위절이라 파일이 §라 블록에서 끝난다. 따라서 **파일 맨 끝(= §라 블록 끝)에** 아래를 붙인다:

```markdown

### 마. 병렬 오케스트레이션 — 멀티태스크 플랜이 둘 이상이면 3층으로
독립적인 작업 단위가 2개 이상이고 각 단위가 그 자체로 계획·구현·리뷰 루프를 가진 **멀티태스크 플랜**이면,
한 세션에서 순차로 굴리지 말고 스펙별 **독립 서브오케스트레이터**(격리 워크트리)에 위임하는 3층 배열
(오케스트레이터 → 서브오케스트레이터 → 워커·리뷰어)을 고려한다. 단위가 **단일 태스크**면 3층은 순수
오버헤드이니 `dispatching-parallel-agents`(2층)로 간다. 사람 병목은 주로 스펙 국면에 있으므로, 스펙을
하나씩 잠그고 잠기는 즉시 팬아웃하는 파이프라인이 자연스럽다. *어떻게*의 상세(라우팅·디스패치 템플릿·
가드레일·재개)는 `nested-orchestration` 스킬이 SSOT다 — 여기엔 트리거만 둔다.
```

- [ ] **Step 4: 테스트를 돌려 통과를 확인한다**

Run: `bash scripts/test_scaffold.sh`
Expected: `[case16]` 세 체크 모두 `PASS`, 말미 `FAIL=0`, exit 0.

- [ ] **Step 5: 커밋**

```bash
git add agent-principles.md scripts/test_scaffold.sh
git commit -m "feat(discipline): add §마 nested-orchestration nudge + drift guard"
```

---

### Task 2: `nested-orchestration` 스킬 작성 + 존재/구성 가드 + README 등재

방법의 SSOT 스킬을 만든다. 스펙(`docs/superpowers/specs/2026-07-05-nested-orchestration-design.md`)을 충실히 렌더한다. 스킬 파일 존재와 핵심 절(라우팅·6블록 템플릿·가드레일)을 계약 가드로 박고, README 구성 트리에 한 줄 등재한다.

**Files:**
- Create: `skills/nested-orchestration/SKILL.md`
- Modify: `scripts/test_scaffold.sh` (case16 뒤에 case17 추가)
- Modify: `README.md` (`## 구성` 트리, 라인 78 `skills/meta-aggregate` 줄 뒤)

**Interfaces:**
- Consumes: Task 1의 `nested-orchestration` 이름(§마가 가리키는 대상).
- Produces: `skills/nested-orchestration/SKILL.md`(frontmatter `name: nested-orchestration`).

- [ ] **Step 1: 실패하는 존재/구성 가드를 먼저 쓴다**

`scripts/test_scaffold.sh` case16 뒤에 삽입한다:

```bash
# --- 케이스 17: nested-orchestration 스킬 존재 + 핵심 절(정본 계약 가드) ---
NO_SKILL="$HERE/skills/nested-orchestration/SKILL.md"
echo "[case17] nested-orchestration skill present + structured"
check "skill file exists"             "[ -f '$NO_SKILL' ]"
check "frontmatter name correct"      "grep -qE '^name: *nested-orchestration' '$NO_SKILL'"
check "has routing (2층 위임)"         "grep -qF 'dispatching-parallel-agents' '$NO_SKILL'"
check "has L2 template ownership blk"  "grep -qF '구간 소유권' '$NO_SKILL'"
check "has output contract blk"        "grep -qF '산출 계약' '$NO_SKILL'"
check "points to SDD (no reimpl)"      "grep -qF 'subagent-driven-development' '$NO_SKILL'"
```

- [ ] **Step 2: 테스트를 돌려 실패를 확인한다**

Run: `bash scripts/test_scaffold.sh`
Expected: `[case17]` 체크들이 `FAIL`(파일 부재), exit 1.

- [ ] **Step 3: 스킬 파일을 작성한다**

`skills/nested-orchestration/SKILL.md`에 아래 전체를 쓴다:

````markdown
---
name: nested-orchestration
description: 멀티태스크 플랜이 둘 이상일 때 3층(오케스트레이터→서브오케스트레이터→워커·리뷰어)으로 병렬 실행하는 방법. 스펙별 독립 워크트리·자율 L2·기계적 소유권 강제·무상태 재개. agent-principles §마가 트리거.
---
# nested-orchestration — 3층 병렬 오케스트레이션 (방법 SSOT)

> `agent-principles.md` §마가 트리거 인덱스다. 여기가 *어떻게*의 SSOT다. 이 스킬은 기존 스킬을
> 재구현하지 않고 조합한다 — 각 메커니즘의 상세는 그 스킬을 연다.

## 언제 쓰나 — 라우팅 결정 트리
독립적인 작업 단위가 2개 이상일 때:
- 각 단위가 **단일 태스크**(자기 계획·리뷰 루프가 없음) → `dispatching-parallel-agents`(2층)로 간다. 여기서 끝.
- 각 단위가 **멀티태스크 플랜**(자기 계획·구현·리뷰 루프를 가진 덩어리) → 이 스킬(3층)을 쓴다.

3층이 값을 하는 이유: 2층 워커는 한 태스크만 풀고, 순차 SDD는 N개 루프를 한 컨텍스트에 쌓는다. 3층만이
**N개 SDD 루프를 각자 격리 컨텍스트에서 동시에** 돌린다. 그 격리+동시성이 조율 층 하나를 얹는 값이다.
단일 태스크에는 그 값이 없으니 붙이지 않는다.

## 흐름 — 파이프라인 3단계 (batch 아님)
사람 병목은 주로 스펙 국면에 산다. 그러니 스펙을 하나씩 잠그고, 잠기는 즉시 팬아웃한다.

1. **L1(메인, 사람과 함께)**: 스펙을 하나씩 `brainstorming`으로 잠근다. 잠기는 즉시 워크트리를 만들고
   (`using-git-worktrees`, 또는 `Agent`의 `isolation:'worktree'`) L2를 **백그라운드로** 디스패치한다.
   그 사이 L1은 다음 스펙을 계속 브레인스토밍한다.
2. **L2(자율 서브오케스트레이터, 사람 대화 불가)**: 잠긴 스펙으로 `writing-plans`(계획부터) →
   `subagent-driven-development`(구현)를 자기 워크트리에서 실행한다. L2의 SDD 루프가 L3(구현자·리뷰어)를 띄운다.
   **검증은 세 지점에 배선한다** — 스펙 국면은 L1이 이미 `domain-spec-review`(훅 강제)로 마쳤고, **플랜 국면은
   L2가 자율로 `domain-spec-review`를 돌려 accept/regenerate까지 처리**하되(사람 대화 불가라 escalate 상황이면
   아래 BLOCKED로 버블업), 실행 국면은 SDD 태스크 리뷰어 + 리스크 비례 `reviewer-*` 렌즈가 맡는다.
3. **L1 통합**: L2들의 완료 통지를 받아 리포트를 취합하고, 소유권을 기계로 검증한 뒤 병합하고 최종 브랜치
   리뷰를 돌린다. 이 통합은 가벼운 일이 아니며 L1에서 벌어진다 — 병목은 제거가 아니라 축소된다. 통합을
   브레인스토밍이 다 끝난 뒤로 미루거나, 규모가 크면 통합 자체를 별도 서브에이전트에 위임해도 된다.

## L2 디스패치 템플릿 — 여섯 블록
L2는 자기 부모(L1) 외 누구와도 대화할 수 없다. 프롬프트는 자기완결이어야 한다. 용어 고정: L2=서브오케스트레이터,
L3=구현자·리뷰어('워커'는 2층 용어).

1. **역할 선언** — "너는 자율 서브오케스트레이터다. 나(오케스트레이터)와 추가 왕복 없이 스펙을 완결하고
   브랜치까지 만든다. 너는 격리된 git 워크트리에 있다."
2. **임무** — 스펙 경로(SSOT임을 명시) + 산출물 열거.
3. **구간 소유권(엄수)** — 소유하는 파일·디렉터리 경로 + 타 워크스트림 소유 파일의 **명시적 금지**.
4. **방식(TDD + 3층)** — 구현자로 구현(같은 파일은 순차 편집·병렬 mutate 금지), 프로젝트 테스트 규약, 그리고
   **읽기전용 리뷰어 서브에이전트**가 diff를 읽고 findings를 반환 → L2가 수정(리뷰어는 파일 불변). 리스크에
   비례해 리뷰어를 고른다(§가) — SDD 태스크 리뷰어, 필요하면 `reviewer-grounding`·`reviewer-adversarial` 렌즈.
5. **주입 컨텍스트** — solved_problems에서 recall한 해당 도메인 gotcha들(반복 재발견 금지).
6. **산출 계약(브랜치까지만 — 머지·배포·main push 금지)** — 상세는 **리포트 파일**에 쓰고(변경 파일·테스트
   최종 결과·발행 스키마 실제 모양·스펙 이탈·브랜치명), **L1으로 리턴하는 것은 상태·블로커·한 줄 요약 +
   리포트 경로뿐**. 리포트는 **제품 트리 밖의 워크스트림별 고유 경로**(예: `report-<workstream>.md`)에 쓰고
   **병합될 브랜치에는 커밋하지 않는다**(고정 경로로 커밋하면 워크스트림끼리 병합 충돌 — 실측). 서브에이전트
   `Write`가 `.md`를 훅으로 막을 수 있으니 리포트는 Bash로 스크래치에 기록한다(실측 gotcha).

## 사람 대화 불가 — BLOCKED와 재개
- L2가 사람 결정(🔴)에 부딪히면 mid-run으로 surface하려 하지 말고(백그라운드라 즉시 채널이 없다) **그
  지점에서 조기 종료하고 상태 `BLOCKED` + 질문을 리턴**한다(지금까지 커밋은 브랜치에 남긴 채). 절대 추측으로
  지나가지 않는다(§다의 "🔴 즉시 surface").
- L1이 그 질문을 사용자에게 surface한다. 사용자가 답하면 L1은 정지된 L2를 되살리지 않는다 — **답을
  스펙에 접어 넣어(🔴 해소) 그 워크트리에 새 L2를 재디스패치**한다. 새 L2는 기존 커밋 위에서 이어간다(무상태 재개).
- **잔존 위험(정직히)**: BLOCKED 버블업은 자율 LLM에 대한 프롬프트 넛지이지 하드 컨트롤이 아니다. L2가 🔴를
  못 알아채고 추측하면 완결된 브랜치까지 가서야 L1이 본다. 최종 방벽은 L1의 통합검증·최종 브랜치 리뷰다.

## 가드레일 (FAIL-LOUD)
- **구간 소유권 강제(선언 + 기계적 탐지)**: L1은 취합 때 각 브랜치의 변경 파일 집합
  (`git diff --name-only base..branch`)을 구해 **두 집합의 교집합이 비면 안전, 비지 않으면 병합 전에
  멈추고 surface**한다. 리포트 핸드오프는 브랜치 밖이라 이 집합은 제품 파일만 담는다. 겹침이 "조용한 병합
  충돌"이 아니라 병합 *이전*의 명시적 FAIL로 드러난다.
- **크래시·행 복구**: L1은 디스패치한 워크스트림을 인플라이트로 들고 있다가, 완료 통지가 안 오는 L2는 CLI
  드릴인(더블클릭)으로 생사를 확인하고 죽었으면 마지막 커밋 위에서 재디스패치한다. 한계: 타임아웃·헬스체크
  툴링이 없어 L1의 주의에 의존한다.
- **비용(정직히)**: task 알맹이는 순차·병렬이 대체로 같지만 병렬은 공짜가 아니다 — L2마다 컨텍스트 재확립
  (스펙 재독·gotcha 재recall·코드베이스 재독)과 에이전트 팬아웃이 N배 오버헤드다. 사는 것은 벽시계 단축과
  컨텍스트 격리다. 실측 참고: 사소한 워크스트림 하나당 약 40k 토큰(L3 포함).

## 관측성 — 무엇을 보고 무엇을 못 보나
수동 `Agent` 중첩은 `/workflows` 집계 대시보드에 뜨지 않는다(그건 `Workflow` 툴 전용). 대신 CLI가
서브에이전트를 표시하고 더블클릭으로 각 L2의 라이브 세션에 드릴인된다 — "각 L2가 지금 뭐 하나"는 이걸로
본다. 못 보는 것: 집계뷰·메트릭, 워크트리 배정 표면 표시. 메인 컨텍스트 bloat는 위 리포트-파일 분리로 완화한다.

## 재구현 금지 (SSOT 포인터)
- 아이디어→스펙: `brainstorming` · 계획: `writing-plans` · 실행 루프: `subagent-driven-development`
- 병렬 디스패치 메커니즘: `dispatching-parallel-agents`(단일태스크 경로이자 디스패치 기초)
- 워크트리 격리: `using-git-worktrees` · 리뷰 렌즈: `reviewer-*`

## 한계 (정직히)
3층은 조율 층을 얹으므로 멀티태스크 플랜에만 값을 한다(라우팅). BLOCKED 정직성·소유권 강제는 스파이크에서
검증됐으나, 크래시 복구와 대형 워크스트림은 아직 미검증이다. 자율(L2 판단)을 관측·재현성(Workflow 결정론)보다
택한 결과이니, 그 대가(집계 UI 부재·추측 잔존 위험)를 감수한다.

**비목표**: `Workflow` 결정론 버전·집계 UI 대시보드·**영속되는 오케스트레이션 상태 문서**는 만들지 않는다 —
인플라이트 상태는 세션 대화 상태로만 든다(disciplined-coder 무상태 정체성). L4 이상 더 깊은 중첩도 다루지
않는다(3층 한정). 단일 태스크 병렬은 `dispatching-parallel-agents`가 SSOT다.
````

- [ ] **Step 4: README 구성 트리에 등재한다**

`README.md` `## 구성` 트리에서 `skills/meta-aggregate/SKILL.md` 줄(라인 78 부근) 바로 뒤에 추가한다:

```markdown
├── skills/nested-orchestration/SKILL.md # 3층 병렬 오케스트레이션 방법(§마 트리거)
```

- [ ] **Step 5: 테스트를 돌려 통과를 확인한다**

Run: `bash scripts/test_scaffold.sh`
Expected: `[case17]` 여섯 체크 모두 `PASS`, 말미 `FAIL=0`, exit 0.

- [ ] **Step 6: 커밋**

```bash
git add skills/nested-orchestration/SKILL.md scripts/test_scaffold.sh README.md
git commit -m "feat(skill): add nested-orchestration method skill + guards + README entry"
```

---

### Task 3: 전체 계약·플러그인 검증 (통합 게이트)

산출물이 서로·기존 계약과 어긋나지 않는지 전체 스위트로 확인한다.

**Files:** (없음 — 검증만)

- [ ] **Step 1: 세 계약 테스트를 돌린다**

Run:
```bash
bash scripts/test_scaffold.sh && bash scripts/test_hooks.sh && bash scripts/test_codex_scaffold.sh
```
Expected: 각 스크립트 말미 `FAIL=0`, 세 개 모두 exit 0.

- [ ] **Step 2: 플러그인 검증**

Run: `claude plugin validate ./`
Expected: 통과(비-strict). `--strict`의 version 경고는 의도된 트레이드오프이므로 쓰지 않는다.

- [ ] **Step 3: 스킬 자동 발견 확인**

Run: `test -f skills/nested-orchestration/SKILL.md && ! grep -q '"skills"' .claude-plugin/plugin.json && echo OK`
Expected: `OK`. 스킬 파일이 존재하고 `.claude-plugin/plugin.json`에 `"skills"` 키가 **없음**을 확인한다(자동 발견이라 매니페스트 편집 불필요). `! grep -q`는 키가 없을 때 exit 0이라 게이트가 의도와 일치한다 — `grep -c`(0을 찍어도 exit 1)의 함정을 피한다.

- [ ] **Step 4: 커밋(검증 게이트 통과 기록, 변경 없으면 생략)**

검증만이므로 새 커밋은 없다. 세 스위트 FAIL=0과 plugin validate 통과를 통합검증 근거로 리포트한다.

---

## Self-Review (작성자 체크리스트)

**1. Spec coverage:** 스펙 R1(넛지+스킬)=Task1+Task2, R2(라우팅)=§마+스킬 라우팅절+case16/17, R3(파이프라인)=흐름절,
R4(수동 중첩)=흐름·템플릿, R5(6블록+리포트 스크래치)=템플릿절, R6(대화불가·BLOCKED·재개)=전용 절,
R7(검증 3지점)=흐름 step2(플랜 국면 자율 spec-review, escalate→BLOCKED)+방식블록4(실행 국면)+스펙 국면 L1 훅,
R8(가드레일·기계적 탐지·비용)=가드레일절, R9(관측성)=관측성절, 통합지점(매니페스트 no-op)=Global Constraints+Task3 Step3,
비목표=한계절 비목표 문단(Workflow 버전·집계 UI·영속 상태 문서·L4 상한·단일태스크 위임 5개 명시). 공백 없음.

**2. Placeholder scan:** TBD/TODO 없음. 모든 스텝에 실제 내용(정본 문단·스킬 전문·테스트 코드) 포함.

**3. Type consistency:** 이름 일관 — 스킬명 `nested-orchestration`(§마·case16·case17·README 동일), 블록 앵커
`구간 소유권`·`산출 계약`(스킬 본문 ↔ case17 grep 일치), 참조 스킬명 정확(`dispatching-parallel-agents`·
`subagent-driven-development`).

<!-- spec-review: passed -->
