# nested-orchestration 큰 개발 분할 Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** 큰 개발에서 현재 세션은 PM 역할만 맡고 워크스트림마다 서브 세션이 하부 명세부터 구현까지 맡도록 `nested-orchestration` 스킬과 에이전트원칙 `SUB-ORCHESTRATE`를 고친다.

**Architecture:** 원칙 문구를 바꾸기 전에 클린룸 소거 시험으로 효과를 재고, 채택 여부를 사용자가 정한다. 그다음 원칙·참고서·스킬·용어를 차례로 고치고, 새 가드레일(범위 대조, 마커 확인, 시험 병합, 진행 위치)은 임시 git 저장소에서 결함을 주입해 실측한다. 저장소 검사(`scripts/test_*.sh`)와 `claude plugin validate ./`로 마무리한다.

**Tech Stack:** Markdown 스킬 문서, bash 검사 스크립트(`scripts/test_docs_drift.sh`, `scripts/_doc_keys.sh`), git(worktree, diff, merge, show), Claude Code Agent 도구(클린룸 시험).

**Spec:** `docs/superpowers/specs/2026-10-09-nested-orchestration-large-dev-design.md`

## Global Constraints

- 모든 명령은 워크트리 `/d/projects/dc-nested-large-dev`에서 실행한다. 명령 블록마다 첫 줄에 `cd /d/projects/dc-nested-large-dev`를 둔다. 서브에이전트의 Bash 작업 디렉터리는 호출마다 처음 디렉터리로 돌아갈 수 있다.
- 용어: 현재 세션(예전 L1), 서브 세션(예전 L2), 워커(예전 L3), 워크스트림(예전 절), 큰 명세, 하부 명세, plan. 고친 스킬 안에 `L1`·`L2`·`L3`·서브오케스트레이터·메인 세션·스펙·계획을 남기지 않는다.
- 에이전트원칙 문안은 모든 프로젝트에 실리므로 '서브 세션' 대신 '서브에이전트'를 쓴다.
- 에이전트원칙 지시 문장은 명령형("~하라", "~하지 마라")으로, 스킬과 참고서는 평서형으로 쓴다(저장소 CLAUDE.md 「에이전트원칙을 고칠 때」).
- 원칙 문구 변경은 클린룸 소거 시험으로 채택을 정한다. 채택하지 않으면 Task 2 이후를 진행할지와 원칙에 무엇을 둘지를 사용자가 정한다.
- 스킬 본문에 `Explore`와 `~/.claude/disciplined-coder/`를 쓰지 않는다(`test_docs_drift.sh` 라벨 "Claude 전용 종류 이름 없음", "관리 디렉터리 절대경로 없음").
- `nested-orchestration`은 한 줄 안에서 `dispatching-lenses`와 「렌즈에게 에이전트원칙을 알리는 법」을 함께 가리키고, 그 절을 스스로 두지 않는다(라벨 "이 소유자를 가리킨다", "에 그 절이 없다").
- dispatching-lenses 「한 번만 실행하는 렌즈의 규율」 절에 백틱 `nested-orchestration`이 남아야 한다(라벨 "3층 오케스트레이션 예외를 적는다").
- 에이전트원칙 「병렬 오케스트레이션」 블록에 `nested-orchestration`과 `**\`SUB-ORCHESTRATE\``가 남아야 한다(라벨 "병렬 오케스트레이션 points to skill"과 그 다음 라벨).
- 검사 묶음 계약은 FAIL=0이고, `claude plugin validate ./`는 `version` 경고 하나만 내야 정상이다.
- `docs/superpowers/rewrite-map/`과 미추적 사용자 파일(`agents.md`, `docs/대화전문-2026-10-06_07.md`, `2026-09-10-canon-slimming-for-opus5-review-2*`)은 건드리지 않는다.
- 커밋 메시지 끝에 `Co-Authored-By: Claude Opus 5.5 (1M context) <noreply@anthropic.com>`와 `Claude-Session: https://claude.ai/code/session_01SoV9e1oYTTUGnDcM4th7d2`를 붙인다.

## Review Focus

- **조사가 붙은 용어:** `L2가`, `L1으로`처럼 조사가 붙은 표기는 `grep -w`가 놓친다. 기대 동작은 `-w` 없는 grep으로 모두 잡히는 것이다. Task 7 Step 1이 고정한다.
- **허용 경로 밖 파일을 안으로 옮기거나 새로 만드는 수정:** `--name-only`만 쓰면 이동은 새 이름만 나와 통과한다. 기대 동작은 원래 경로의 삭제와 새 파일이 범위 밖으로 출력되는 것이다. Task 6 시나리오 B·C가 고정한다.
- **서로 접두어인 워크스트림 id:** 열린 패턴은 `b`가 `bx`의 문서를 허용한다. 기대 동작은 다른 워크스트림의 문서가 범위 밖으로 출력되는 것이다. Task 6 시나리오 P가 고정한다.
- **통합 실패 뒤 재시도와 진행 위치:** 되돌림 방식은 재병합 때 처음 변경을 잃고, `--merged`는 커밋 없는 브랜치를 끝난 것으로 낸다. 기대 동작은 실패한 시험 병합 뒤 통합 브랜치가 그대로이고, 재시도에 처음 변경과 수정이 모두 들어가며, 트레일러가 있는 워크스트림만 끝난 것으로 나오는 것이다. Task 6 시나리오 E·F가 고정한다.
- **escalated 마커와 읽는 위치:** 현재 세션 체크아웃에는 워크스트림 파일이 없고, escalated 문서는 사람이 결정 기록을 대조해야 한다. 기대 동작은 `git show`로 읽어 마커 없는 문서와 escalated 문서를 각각 출력하는 것이다. Task 6 시나리오 D가 고정한다.

---

### Task 0: 작업 워크트리와 설계 문서 커밋

**Files:**
- Move: 이 세션이 만든 미추적 문서(spec, plan, 지시문 검진 기록, spec 리뷰 기록 두 차수, plan 리뷰 기록과 각 폴더)

**Interfaces:**
- Produces: 워크트리 `/d/projects/dc-nested-large-dev`, 브랜치 `nested-large-dev`

- [ ] **Step 1: 워크트리 만들기**

`superpowers:using-git-worktrees`의 수동 경로를 쓴다. 이 저장소는 형제 디렉터리 워크트리를 관례로 쓴다(2026-10-03 설계의 `../dc-lens-dispatch`). 저장소 밖이라 ignore 확인이 필요 없다. 사용자는 별도 워크트리에서 작업한다고 적은 spec을 승인했다. 네이티브 도구 `EnterWorktree`는 이 세션의 작업 디렉터리를 옮기고 경로를 관례대로 정할 수 없어 쓰지 않는다.

```bash
cd /d/projects/disciplined-coder
git worktree add ../dc-nested-large-dev -b nested-large-dev main
```

Expected: `Preparing worktree (new branch 'nested-large-dev')`

- [ ] **Step 2: 이 세션이 만든 미추적 문서만 옮기기**

```bash
cd /d/projects/disciplined-coder
W=/d/projects/dc-nested-large-dev
for p in docs/superpowers/specs/2026-10-09-nested-orchestration-large-dev-design.md \
         docs/superpowers/plans/2026-10-09-nested-orchestration-large-dev.md \
         docs/superpowers/reviews/2026-10-07-large-dev-directive-check.md \
         docs/superpowers/reviews/2026-10-07-large-dev-directive-check \
         docs/superpowers/reviews/2026-10-09-nested-orchestration-large-dev-review.md \
         docs/superpowers/reviews/2026-10-09-nested-orchestration-large-dev-review \
         docs/superpowers/reviews/2026-10-09-nested-orchestration-large-dev-review-2.md \
         docs/superpowers/reviews/2026-10-09-nested-orchestration-large-dev-review-2 \
         docs/superpowers/reviews/2026-10-09-nested-orchestration-large-dev-plan-review.md \
         docs/superpowers/reviews/2026-10-09-nested-orchestration-large-dev-plan-review; do
  mkdir -p "$W/$(dirname "$p")" && mv "$p" "$W/$p"
done
rmdir docs/superpowers/plans 2>/dev/null
git status --short
```

Expected: 남은 미추적 항목은 `agents.md`, `docs/대화전문-2026-10-06_07.md`, `2026-09-10-canon-slimming-for-opus5-review-2.md`와 그 폴더뿐이다.

- [ ] **Step 3: 커밋**

```bash
cd /d/projects/dc-nested-large-dev
git add docs/superpowers/specs/2026-10-09-nested-orchestration-large-dev-design.md docs/superpowers/plans/2026-10-09-nested-orchestration-large-dev.md docs/superpowers/reviews/2026-10-07-large-dev-directive-check* docs/superpowers/reviews/2026-10-09-nested-orchestration-large-dev-*
git status --short
git commit -m "nested-orchestration 큰 개발 분할 설계와 plan, 지시문 검진과 spec·plan 리뷰 기록을 남긴다

Co-Authored-By: Claude Opus 5.5 (1M context) <noreply@anthropic.com>
Claude-Session: https://claude.ai/code/session_01SoV9e1oYTTUGnDcM4th7d2"
```

Expected: 커밋 전 `git status --short`의 미추적 항목이 비어 있고, 커밋이 하나 생긴다.

---

### Task 1: 트리거 문구의 클린룸 소거 시험

현재 세션이 직접 실행한다. 서브에이전트를 조건·과제마다 하나씩 실행하고, 결과를 판정해 사용자에게 보고한 뒤 채택 여부를 묻는다. CLAUDE.md의 과제 셋은 최소 수이고, 기존 트리거(서로 무관한 일)의 퇴행과 작은 개발에 대한 과잉 적용을 함께 보려고 과제 둘을 추가한다.

**Files:**
- Create(저장소 밖): `mktemp -d`로 만든 디렉터리 아래 `cleanroom/` 응답 파일. 경로는 Step 3에서 정해 기록한다.

**Interfaces:**
- Produces: 조건(빈 모델·현행·새 문안)별 과제 목록과 위반 수 표, 오염 확인 결과, 채택 여부에 대한 사용자 결정

- [ ] **Step 1: 빈 모델 조건 확인**

읽기 전용 서브에이전트(2026-10-03 클린룸 시험과 같은 종류인 Explore) 하나에 아래를 묻는다.

```
도구를 쓰지 말고 답하라. (1) 너의 컨텍스트에 'SUB-ORCHESTRATE' 또는 '병렬 오케스트레이션'이라는 문자열이 있는가? 있으면 그 줄을 그대로 인용하라. (2) 너에게 보이는 스킬 목록에 nested-orchestration 이 있으면 그 description 을 그대로 인용하라.
```

(1)에 현행 조항이 인용되면 빈 모델 조건이 성립하지 않으므로 시험을 멈추고 사용자에게 알린다. (2)의 description은 시험이 옛 description이 실린 상태에서 실행된다는 한계로 기록한다.

- [ ] **Step 2: 조건 문안 확정**

조건 A(빈 모델)는 조항을 싣지 않는다. 조건 B(현행)는 `agent-principles.md` 「병렬 오케스트레이션」 절 그대로다.

```
## 병렬 오케스트레이션

독립된 큰 일이 둘 이상이면 한 세션에 몰지 말고 동시에 진행하라.

- **`SUB-ORCHESTRATE` (One sub-orchestrator per independent job)** — 서로 독립된 일이 둘 이상이고 각 일이 plan 문서를 따로 둘 만큼(작업 다섯 이상) 크면, 일마다 서브오케스트레이터를 두어 동시에 진행하라. 일이 하나뿐이면 서브오케스트레이터를 두지 마라. 방법은 `nested-orchestration`이 소유한다.
```

조건 C(새 문안)는 아래다.

```
## 병렬 오케스트레이션

독립된 큰 일이 둘 이상이거나 큰 개발 하나가 하위 시스템 여럿으로 나뉘면 한 세션이 차례로 진행하지 말고 서브에이전트에 나눠 맡겨라.

- **`SUB-ORCHESTRATE` (One subagent per independent job or subsystem)** — 서로 독립된 일이 둘 이상이거나 개발 하나가 독립된 하위 시스템 여럿으로 나뉘는 상황에서 각 일이 plan을 따로 둘 만큼(태스크 다섯 이상으로 예상될 만큼) 크면, 차례로 명세·plan·구현을 직접 진행하지 마라. 나눌 근거를 보여 사용자 승인을 받은 뒤 일마다 서브에이전트에 맡겨라. 나눌 일이 하나뿐이면 맡기지 마라. 방법은 `nested-orchestration`이 소유한다.
```

- [ ] **Step 3: 과제와 실행**

과제 문안은 아래다.

```
B1: 사내 자산운용 대시보드를 새로 만들려고 한다. 사내 DB 게이트웨이 API를 호출해 MongoDB에 저장하는 수집 배치, FastAPI 백엔드, React 화면 8개(펀드 현황, 기관 관리 등), 엑셀 업로드 기능이 필요하다. 템플릿 저장소가 있다. 진행해 줘.
B2: 사내 리서치 보고서 검색 서비스를 만들자. PDF 수집기, 텍스트 추출과 임베딩 파이프라인, 검색 API, 사내 SSO를 붙인 웹 화면, 관리자용 사용량 통계 화면이 필요하다.
B3: 주문 관리 시스템을 새로 짓자. 주문 접수 API, 재고 동기화 워커, 결제 연동 모듈, 정산 배치, 메일·SMS 고객 알림 서비스가 필요하다.
I1: 두 가지를 부탁한다. 하나는 Python 로그 수집기를 Go로 다시 쓰는 일(테스트 포함)이고, 다른 하나는 사내 위키에 권한 관리 기능을 추가하는 일(백엔드·화면·마이그레이션)이다. 둘은 서로 관련이 없다.
S1: README의 설치 절을 최신 명령으로 고치고, CLI에 --version 옵션 하나를 추가해 줘.
B4(같을 때만): 모바일 뱅킹 앱에 '목표 저축' 기능을 넣자. 서버 API, 자동이체 스케줄러, iOS·Android 화면, 관리자 백오피스가 필요하다.
B5(같을 때만): 데이터 품질 모니터링 플랫폼을 만들자. 규칙 정의 DSL 파서, 규칙 실행 엔진, 알림 라우터, 대시보드가 필요하다.
```

B1·B2·B3·I1·S1과 조건 A·B·C의 조합마다 같은 종류의 서브에이전트 하나를 백그라운드로 실행한다. 한 메시지에 여덟 개 이하로 나눠 보낸다. 프롬프트 틀은 아래다(`{조항}`은 조건 A에서 빈 문자열).

```
너는 Claude Code 세션이다. 아래 [규칙]이 있으면 사용자 지시로 따른다. 도구를 쓰지 말고, 사용자가 [요청]을 보냈을 때 처음부터 끝까지 어떤 순서로 진행할지 답하라. 각 하위 작업의 명세·plan·구현을 누가(이 세션이 직접인지 서브에이전트인지) 쓰는지, 사용자에게 무엇을 언제 묻는지를 반드시 적어라. 400자 이내로 답하라.

[규칙]
{조항}

[요청]
{과제}
```

응답은 `mktemp -d`로 만든 디렉터리의 `cleanroom/<조건>-<과제>.txt`에 저장하고, 그 경로를 기록한다.

- [ ] **Step 4: 판정**

판정은 현재 세션이 하고, 판정이라는 사실을 기록에 적는다. B·I 과제의 위반은 이 세션이 하위 작업마다 명세·plan·구현을 차례로 직접 진행한다고 답하거나 사용자 승인 없이 서브에이전트에 나눠 맡긴다고 답한 응답이다. S 과제의 위반은 서브에이전트에 나눠 맡긴다고 답한 응답이다. 조건별로 실행한 과제 목록과 위반 수를 표로 만든다.

- [ ] **Step 5: 채택 판정과 사용자 보고**

새 문안(C)의 위반이 현행(B)보다 적으면 채택안이다. 같으면 B4·B5를 B·C 조건으로 더 실행해, 일곱 과제 합계가 현행보다 나쁘지 않으면 채택안이고 나쁘면 불채택안이다. C가 S1을 나누면 위반 수와 상관없이 불채택안이다. C를 채택안으로 정했는데도 큰 개발 과제가 하나라도 차례로 진행되었으면 훅 추가를 함께 제안한다.

조건별 표, 판정, Step 1의 오염 확인 결과, 훅 제안 여부를 사용자에게 보고하고 채택 여부를 묻는다. 불채택이면 Task 2 이후를 진행할지와 원칙에 무엇을 둘지를 묻는다. 사용자 답이 오기 전에는 Task 2로 넘어가지 않는다.

---

### Task 2: 에이전트원칙과 참고서

**Files:**
- Modify: `agent-principles.md`(「병렬 오케스트레이션」 절)
- Modify: `docs/domain-discipline.md`(13행 문단, `SUB-ORCHESTRATE` 절)

**Interfaces:**
- Consumes: Task 1의 표와 사용자 결정
- Produces: 새 「병렬 오케스트레이션」 블록

- [ ] **Step 1: 에이전트원칙 교체**

채택이면 「병렬 오케스트레이션」의 머리 문장과 `SUB-ORCHESTRATE` 줄을 Task 1 Step 2의 조건 C 문안으로 바꾼다. `## 병렬 오케스트레이션` 제목은 그대로 둔다. 불채택인데 사용자가 진행을 정했으면 사용자가 정한 문안으로 바꾸고, 사용자가 현행 유지를 정했으면 이 Step을 생략한다.

- [ ] **Step 2: 참고서 13행**

`docs/domain-discipline.md`의 "`SUB-ORCHESTRATE` 의 작업 다섯은"을 원칙에 실제로 넣은 문안의 표현에 맞춘다. 조건 C를 넣었으면 "`SUB-ORCHESTRATE` 의 태스크 다섯은"이다.

- [ ] **Step 3: 참고서 `SUB-ORCHESTRATE` 절**

절 본문을 아래로 바꾼다. 「측정」 문단의 꺾쇠는 Task 1 표의 실제 값으로 바꾸고 꺾쇠를 남기지 않는다. 불채택이면 "지금 문구는" 문장에 실제로 남은 문안을 적고, 둘째 문단에 불채택과 사용자 결정을 적는다.

```
### `SUB-ORCHESTRATE`

일이 하나뿐인데 층을 하나 더 두면 그 층이 값만 쓰고 아무것도 나누지 않는다. 그래서 처음에는 조건을 "둘
이상이고 각 일이 계획과 구현과 리뷰를 한 바퀴씩 보유할 만큼 크면"으로 좁혔다. 지금 문구는 "서로 독립된 일이
둘 이상이거나 개발 하나가 독립된 하위 시스템 여럿으로 나뉘는 상황에서 각 일이 plan을 따로 둘 만큼(태스크 다섯
이상으로 예상될 만큼) 크면"이다. 실행 방법은 `nested-orchestration` 이 소유한다.

2026-10-09에 큰 개발 하나를 하위 시스템으로 나누는 조건을 넣었다. 옛 문구에서는 큰 개발이 일 하나로 읽혀 현재
세션이 하위 시스템마다 명세·plan·구현을 차례로 직접 진행했고, 사용자가 이 진행을 바꾸라고 했다. 태스크 수는
plan 전에는 셀 수 없어 "예상될 만큼"으로 적었고, 나누기 전에 사용자 승인을 받게 했다. 설계는
`docs/superpowers/specs/2026-10-09-nested-orchestration-large-dev-design.md` 에 있다.

**측정.** 2026-10-09에 클린룸 소거 시험을 조건마다 1회 실행했다. 과제는 <Task 1 표의 조건별 과제 목록>이었다.
위반(하위 작업을 차례로 직접 진행하거나 승인 없이 나눔, 작은 개발을 나눔)은 빈 모델 <A>건, 현행 문안 <B>건,
새 문안 <C>건이었다. <빈 모델과 현행의 위반 사례를 과제 이름과 함께 한두 문장으로 적는다.> 판정은 현재 세션이
응답을 읽고 했다. 시험 서브에이전트에는 옛 `nested-orchestration` description 이 실려 있었다.
```

- [ ] **Step 4: 확인**

```bash
cd /d/projects/dc-nested-large-dev
grep -n '<A>\|<B>\|<C>\|<Task 1\|<빈 모델' docs/domain-discipline.md
awk '/^## 병렬 오케스트레이션/{f=1} f&&/^## /&&!/^## 병렬 오케스트레이션/{exit} f' agent-principles.md | grep -c 'nested-orchestration'
awk '/^## 병렬 오케스트레이션/{f=1} f&&/^## /&&!/^## 병렬 오케스트레이션/{exit} f' agent-principles.md | grep -c '\*\*`SUB-ORCHESTRATE`'
```

Expected: 첫 명령 출력 없음, 둘째와 셋째 `1` 이상. 조건 C를 넣었으면 `grep -n '작업 다섯' docs/domain-discipline.md agent-principles.md`도 출력이 없다.

- [ ] **Step 5: 커밋**

```bash
cd /d/projects/dc-nested-large-dev
git add agent-principles.md docs/domain-discipline.md
git commit -m "SUB-ORCHESTRATE 를 큰 개발 분할 시점까지 넓히고 클린룸 측정을 참고서에 적는다

Co-Authored-By: Claude Opus 5.5 (1M context) <noreply@anthropic.com>
Claude-Session: https://claude.ai/code/session_01SoV9e1oYTTUGnDcM4th7d2"
```

---

### Task 3: 2026-07-05 설계 superseded 표시와 검사

**Files:**
- Modify: `scripts/test_docs_drift.sh`(라벨 "옛 spec 에 superseded 표시가 있다" 다음 줄, 라벨 "그 절에 서브오케스트레이터 조항이 있다")
- Modify: `docs/superpowers/specs/2026-07-05-nested-orchestration-design.md`(1행 제목 아래)

**Interfaces:**
- Produces: 검사 라벨 "옛 nested 설계에 superseded 표시가 있다", "그 절에 SUB-ORCHESTRATE 조항이 있다"

- [ ] **Step 1: 실패하는 검사 추가와 라벨 교체**

`scripts/test_docs_drift.sh`에서 라벨 `"옛 spec 에 superseded 표시가 있다"`가 든 `check` 줄 바로 아래에 두 줄을 넣는다.

```bash
OLDNESTED="$HERE/docs/superpowers/specs/2026-07-05-nested-orchestration-design.md"
check "옛 nested 설계에 superseded 표시가 있다"   "grep -qF 'superseded' \"\$OLDNESTED\""
```

같은 파일에서 라벨 문자열 `"그 절에 서브오케스트레이터 조항이 있다"`를 `"그 절에 SUB-ORCHESTRATE 조항이 있다"`로 바꾼다. 행 번호가 아니라 라벨 문자열로 찾는다. 검사식은 그대로 둔다.

- [ ] **Step 2: 실패 확인**

```bash
cd /d/projects/dc-nested-large-dev
bash scripts/test_docs_drift.sh 2>&1 | grep -F '옛 nested 설계'
```

Expected: `  FAIL: 옛 nested 설계에 superseded 표시가 있다`

- [ ] **Step 3: 표시 달기**

`docs/superpowers/specs/2026-07-05-nested-orchestration-design.md`의 1행 제목 바로 아래에 빈 줄과 아래 인용문을 넣는다.

```
> **대체된 설계다(superseded).** 2026-10-09 설계(`docs/superpowers/specs/2026-10-09-nested-orchestration-large-dev-design.md`)가 이 설계를 대체했다. 층별 책임과 재개 방법이 바뀌었고, 유효한 판단과 스파이크 결과는 그 설계의 「이어받는 판단과 검증」으로 옮겼다. 지금 동작의 근거로 읽지 마라.
```

- [ ] **Step 4: 통과 확인**

```bash
cd /d/projects/dc-nested-large-dev
bash scripts/test_docs_drift.sh 2>&1 | grep -F '옛 nested 설계'
bash scripts/test_docs_drift.sh > /dev/null 2>&1; echo "exit=$?"
```

Expected: 첫 줄에 `FAIL`이 없고, `exit=0`.

- [ ] **Step 5: 커밋**

```bash
cd /d/projects/dc-nested-large-dev
git add scripts/test_docs_drift.sh docs/superpowers/specs/2026-07-05-nested-orchestration-design.md
git commit -m "옛 nested 설계에 superseded 를 달고 그 표시를 검사한다

Co-Authored-By: Claude Opus 5.5 (1M context) <noreply@anthropic.com>
Claude-Session: https://claude.ai/code/session_01SoV9e1oYTTUGnDcM4th7d2"
```

---

### Task 4: nested-orchestration 스킬 개정

**Files:**
- Modify(전체 교체): `skills/nested-orchestration/SKILL.md`

**Interfaces:**
- Consumes: spec 「결정」 전부, Task 3의 superseded 표시
- Produces: 스킬 절 「용어」「큰 개발 분할」「라우팅」「흐름」「HARD-GATE 예외」「디스패치 템플릿」「이어 쓰기와 재개」「멈추는 기준」「가드레일」「측정」「관측성」「재구현 금지」「한계」. Task 6 스크립트는 「가드레일」의 명령을 그대로 쓴다.

- [ ] **Step 1: 기준선 확인**

```bash
cd /d/projects/dc-nested-large-dev
bash scripts/test_docs_drift.sh > /dev/null 2>&1; echo "exit=$?"
```

Expected: `exit=0`

- [ ] **Step 2: 파일 전체를 아래 내용으로 교체**

````markdown
---
name: nested-orchestration
description: 기능 여럿이 섞인 큰 개발을 하위 시스템마다 나눠 맡길 때와, 서로 독립된 멀티태스크 일이 둘 이상일 때 연다. 현재 세션은 큰 명세·계약·통합만 맡고, 워크스트림마다 서브 세션이 하부 명세부터 구현까지 자기 워크트리에서 진행한다. 하던 일은 같은 서브 세션을 이어 쓴다. 수정 범위는 병합 전에 기계로 대조하고 진행 위치는 git에서 도출한다. agent-principles의 병렬 오케스트레이션 절이 트리거다.
---
# nested-orchestration — 워크스트림으로 나눠 맡기는 3층 오케스트레이션

`agent-principles.md`의 「병렬 오케스트레이션」 절이 트리거이고, 방법은 이 스킬이 정한다. 기존 스킬을 재구현하지 않고 조합한다. 설계 근거와 검증 결과는 `docs/superpowers/specs/2026-10-09-nested-orchestration-large-dev-design.md`에 있다.

## 용어

| 이름 | 뜻 |
|---|---|
| 현재 세션 | 사용자와 대화하며 큰 명세·계약·통합을 맡고 워크스트림의 명세·plan·구현은 직접 쓰지 않는 세션 |
| 서브 세션 | 워크스트림 하나를 하부 명세부터 구현까지 맡고 사용자와 대화하지 못하는 서브에이전트 |
| 워커 | 서브 세션이 실행하는 구현자와 렌즈 |
| 워크스트림 | 서브 세션 하나가 맡는 작업 단위 |
| 큰 명세 | 개발 전체를 워크스트림으로 나누고 워크스트림 사이 계약과 결정 기록을 적는 명세 |
| 하부 명세 | 워크스트림 하나의 내부 설계를 적는 명세 |
| SDD | plan을 태스크마다 구현 워커와 리뷰어로 실행하는 superpowers `subagent-driven-development` 스킬 |

## 큰 개발 분할

**나눌지 판단.** 현재 세션은 brainstorming으로 요구를 정리한 뒤, 하위 시스템이 서로 독립인지와 각자 plan을 따로 둘 만큼(태스크 다섯 이상으로 예상될 만큼) 큰지 판단한다. 나누려면 근거를 보여 사용자 승인을 받는다. superpowers `brainstorming`은 하위 프로젝트를 차례로 브레인스토밍하라고 적지만, 이 스킬을 쓰는 현재 세션은 하위 시스템마다 명세·plan·구현을 직접 진행하지 않는다.

**큰 명세.** 현재 세션은 큰 명세를 `docs/superpowers/specs/YYYY-MM-DD-<개발 이름>-design.md`에 쓰고 `review-specs`로 리뷰한 뒤 사용자 승인을 받는다. 워크스트림 내부 설계는 적지 않고 아래 항목을 적는다.

- 워크스트림 목록: 워크스트림 id(영문 소문자)와 맡는 일
- 워크스트림 사이 계약: 주고받는 자료의 이름·형식·단위·호출 방향
- 의존 순서: 다른 워크스트림의 산출물이 있어야 시작할 수 있는 워크스트림
- 수정 허용 경로: 워크스트림마다 git pathspec 목록
- 소유 표: 현재 세션이 소유하는 공용 파일
- 공통 제약과 통합 확인 방법
- 「결정 기록」 절

**계약 코드.** 큰 명세 승인 뒤 현재 세션은 계약을 스텁·타입·계약 테스트 코드로 만든다. 계약 코드도 writing-plans, plan 리뷰, 사용자 plan 검토, 실행 순서로 진행한다. 계약 코드가 있으면 현재 세션이 통합 확인을 기계로 할 수 있다. 계약을 코드로 고정하는 방식은 CodeTeam·Contract-Coding의 설계 사례이고, 산문 계약과 코드 계약을 비교한 결과는 없다.

**결정 기록.** 큰 명세의 「결정 기록」 절은 현재 세션만 쓴다. 현재 세션은 첫 디스패치 전에 명명 관례·오류 처리·공용 유틸리티처럼 워크스트림마다 따로 정하면 충돌하는 결정을 채운다. 워크스트림을 통합하면 그 리포트의 확정 결정을 옮기고, 사용자가 🔴(사용자 결정이 필요한 리뷰 지적)나 범위 결정에 답하면 그 답도 적는다. 공개 인터페이스는 계약 코드에서 도출하므로 옮겨 적지 않는다.

**공용 파일.** 라우팅 표·진입점·설정 등록부처럼 여러 워크스트림이 고치는 파일은 현재 세션이 소유하고 소유 표에 적는다. 의존성 목록과 잠금 파일은 한 워크스트림에 맡기고, 그 워크스트림이 끝난 뒤에는 현재 세션이 고친다.

**경로와 브랜치 이름.** 하부 명세는 `docs/superpowers/specs/YYYY-MM-DD-<개발 이름>-<워크스트림 id>-design.md`, 워크스트림 plan은 `docs/superpowers/plans/YYYY-MM-DD-<개발 이름>-<워크스트림 id>.md`에 둔다. 통합 브랜치는 `dev/<개발 이름>`, 워크스트림 브랜치는 `ws/<개발 이름>/<워크스트림 id>`다. 모든 워크스트림의 허용 경로에는 자기 문서 경로 셋(`docs/superpowers/specs/*-<개발 이름>-<워크스트림 id>-design.md`, `docs/superpowers/plans/*-<개발 이름>-<워크스트림 id>.md`, `docs/superpowers/reviews/*-<개발 이름>-<워크스트림 id>-*`)이 기본으로 들어간다. 패턴의 id 뒤를 닫아 두었으므로 한 id가 다른 id의 접두어여도 서로의 문서를 허용하지 않는다.

**근거와 한계.** 이 분할 구조를 단일 세션과 직접 비교한 연구는 찾지 못했다. Specification Gap(2026, 프리프린트)은 일부 정보만 받은 에이전트의 통합 정확도가 58%에서 25%로 떨어졌고 더 상세한 명세로만 회복되었다고 보고했다. BenchAgent(2026, 프리프린트)는 단일 과제 벤치마크 10종을 정규화된 조건에서 실행해 고정 역할 다중 에이전트 6종 중 5종이 단일 에이전트보다 2.56~11.29%p 뒤졌다고 보고했다. 그래서 현재 세션은 작은 개발을 나누지 않고, 나눌 때는 계약과 결정 기록을 먼저 고정한다.

## 라우팅

나눠 맡길 단위에 따라 쓸 스킬이 다르다.

- 단위가 plan·리뷰 루프 없는 단일 태스크이면 `dispatching-parallel-agents`로 간다.
- 서로 독립된 멀티태스크 일이 둘 이상이거나 큰 개발 하나가 독립된 하위 시스템 여럿으로 나뉘면 이 스킬을 쓴다.
- 나눌 일이 하나뿐이면 현재 세션이 superpowers 흐름을 직접 진행한다.

## 흐름

현재 세션과 서브 세션이 아래 순서로 진행한다.

1. **준비(현재 세션)** — main에서 `dev/<개발 이름>`을 만들고 큰 명세와 계약 코드를 커밋한다.
2. **디스패치(현재 세션)** — 시작할 수 있는 워크스트림마다 `using-git-worktrees`로 `dev/<개발 이름>`의 끝에서 `ws/<개발 이름>/<워크스트림 id>` 브랜치와 워크트리를 만들고, 「디스패치 템플릿」으로 서브 세션을 백그라운드로 실행한다. `Agent`의 `isolation:'worktree'`는 브랜치 이름과 기준 커밋을 정할 수 없어 쓰지 않는다.
3. **하부 명세(서브 세션)** — 하부 명세를 쓰고 `review-specs`로 리뷰해 반영한 뒤 커밋하고 `AWAITING_APPROVAL`을 돌려준다.
4. **승인(현재 세션)** — 하부 명세를 큰 명세·결정 기록과 대조해 승인하거나 고칠 점을 같은 서브 세션에 보낸다.
5. **plan과 구현(서브 세션)** — 승인을 받으면 writing-plans, `review-specs`, SDD 순서로 진행하고 `DONE`을 돌려준다.
6. **통합(현재 세션)** — 「가드레일」의 병합 전 검사와 시험 병합으로 통합 브랜치에 넣는다.
7. **마무리(현재 세션)** — 모든 워크스트림이 들어가면 통합 브랜치 전체에 최종 브랜치 리뷰를 실행한다. 서브 세션들의 리포트에서 「제안」을 모아 사용자에게 보이고, 「측정」 값을 보고한다. 통합 브랜치를 main에 병합하는 일은 그다음 사용자 승인을 받아 한다.

의존 순서가 없고 수정 허용 경로가 겹치지 않는 워크스트림은 동시에 진행한다. 다른 워크스트림의 산출물에 의존하는 워크스트림은 선행 워크스트림이 통합 브랜치에 들어간 뒤 그 끝에서 시작한다.

## HARD-GATE 예외

superpowers `brainstorming`의 HARD-GATE는 사람이 명세를 승인하고 plan을 검토하고 실행 방식을 고르게 한다. 서브 세션은 사람과 대화하지 못하므로 이 스킬은 서브 세션에 한해 세 단계를 대체한다. 명세 승인은 현재 세션이 맡는다. plan 검토는 `review-specs` 렌즈 리뷰가 맡는다. 실행 방식은 SDD로 고정한다.

서브 세션은 brainstorming 대화를 열지 않고 큰 명세와 계약 코드를 입력으로 하부 명세를 쓴다. 사용자가 직접 검토하는 문서는 큰 명세와 계약 코드 plan이다. 현재 세션은 사람과 대화하므로 계약 코드에는 이 예외를 쓰지 않는다.

## 디스패치 템플릿

서브 세션은 현재 세션 외 누구와도 대화할 수 없으므로 프롬프트는 자기완결이어야 한다. 현재 세션은 아래 블록을 차례로 넣는다.

1. **역할 선언** — "너는 자율 서브 세션이다. 사용자와 대화할 수 없고, 질문은 상태로 돌려준다. 네 워크트리는 `<워크트리 절대 경로>`이고 브랜치는 `ws/<개발 이름>/<워크스트림 id>`다. 모든 명령을 그 경로에서 실행한다."
2. **임무** — 큰 명세 경로와 맡은 워크스트림 id를 적는다. 산출물은 하부 명세, plan, 구현, 테스트, 리포트다.
3. **수정 허용 경로(엄수)** — 큰 명세에 적은 그 워크스트림의 허용 경로와 자기 문서 경로만 고친다. 공용 파일이나 계약 변경이 필요하면 고치지 않고, 바꿀 내용을 적어 `BLOCKED`로 멈춘다.
4. **하부 명세** — 하부 명세에는 그 워크스트림의 책임과 계약을 구현하는 데 필요한 내용만 적고, 일어날 수 없는 예외를 늘어놓지 않는다. 하부 명세를 `review-specs`로 리뷰해 반영하고 커밋한 뒤 `AWAITING_APPROVAL`로 멈춘다. HARD-GATE 예외 문장을 그대로 넣는다: "이 워크스트림에서 명세 승인은 현재 세션이, plan 검토는 review-specs 렌즈 리뷰가 맡고, 실행 방식은 subagent-driven-development로 고정한다. brainstorming 대화를 열지 않는다."
5. **plan과 구현** — 승인 메시지를 받으면 writing-plans, `review-specs`, SDD(TDD, 프로젝트 테스트 규약) 순서로 진행한다. 워커를 디스패치할 때마다 워크트리 절대 경로를 넣고 모든 명령을 그 경로에서 실행하게 한다. 통합 브랜치가 바뀌었다는 메시지를 받으면 자기 워크트리에서 `git merge dev/<개발 이름>`으로 받은 뒤 일을 잇는다.
6. **렌즈와 원칙** — 렌즈를 실행하기 전에 `dispatching-lenses`를 통째로 읽는다. 서브 세션은 그 규율을 여는 호출자 중 하나이고, 「렌즈에게 에이전트원칙을 알리는 법」이 그 안에 있다. 구현자에게든 문서를 쓰는 서브에이전트에게든 에이전트원칙 `agent-principles.md`의 경로를 넣고, 한국어로 쓰는 서브에이전트에는 `domain-korean`의 경로를 함께 넣는다.
7. **주입 컨텍스트** — 큰 명세의 「결정 기록」 절과, 그 도메인에서 이미 겪은 함정을 넣어 같은 것을 다시 발견하지 않게 한다.
8. **멈추는 기준과 산출 계약(브랜치까지만 — 병합·배포·main push 금지)** — 「멈추는 기준」의 사유와 상태 값을 넣는다. 리포트는 프로젝트 밖 스크래치의 워크스트림별 고유 경로(`report-<워크스트림 id>.md`)에 쓰고 커밋하지 않는다. 리포트에는 변경 파일, 테스트 최종 결과, 확정한 결정, 명세 이탈, 범위 밖 아이디어(「제안」), 리뷰 반영 중 기능적 변화가 있었던 항목, 브랜치명을 적는다. 현재 세션에 돌려주는 것은 상태, 질문이나 블로커, 한 줄 요약, 리포트 경로뿐이다.

## 이어 쓰기와 재개

하던 일이면 어느 층이든 같은 에이전트를 SendMessage로 재개하고, 새 일이면 같은 역할·같은 파일이어도 새 에이전트로 시작한다. 하던 일의 단위는 서브 세션이 워크스트림 하나, 구현 워커가 태스크 하나, 렌즈가 문서 하나의 리뷰 한 차수다. 사용자는 하던 일을 이어 가면 맥락이 증분으로 쌓인다고 판단했다. 같은 에이전트 재개와 새 에이전트에 파일을 넘기는 방식을 비교한 연구는 찾지 못했다.

현재 세션은 하부 명세 승인 뒤 진행 지시, 사용자 답, 통합 실패 출력, 그 워크스트림의 계약·공용 파일 변경을 모두 그 워크스트림의 서브 세션에 이어 쓰기로 보낸다. 그래서 현재 세션은 워크스트림 코드를 직접 고치지 않는다. 메시지는 서브 세션이 끝나거나 멈춘 뒤에 보낸다.

세션이 끊겨 식별자가 사라졌거나 재개가 실패하면, 현재 세션은 워크스트림 브랜치·하부 명세·plan과 워크트리에 남은 SDD ledger(진행 기록 파일)를 넣어 새 서브 세션을 시작한다. 같은 워크스트림의 통합 실패가 되풀이될 때 새 서브 세션으로 바꾸는 횟수 기준은 아직 두지 않는다.

## 멈추는 기준

서브 세션은 아래 사유에서만 멈추고 상태와 질문을 돌려준다. 그 밖의 모호함은 스스로 판정해 SDD ledger와 리포트에 적는다.

- 하부 명세 리뷰를 마쳐 승인을 기다릴 때(`AWAITING_APPROVAL`)
- 하부 명세나 plan 리뷰에서 🔴가 나왔거나, 리스크상 필요한 리뷰 관점을 아무 렌즈도 보지 않았을 때(`BLOCKED`)
- 사람만 정할 수 있는 범위 밖 결정이나 계약·큰 명세·공용 파일 변경이 필요할 때(`BLOCKED`)
- SDD의 정지 사유(비가역 작업, 보안 작업, 워크트리 밖 부작용, 전부 추측인 plan)에 해당할 때(`BLOCKED`)

구현과 리뷰를 마치면 `DONE`을 돌려준다. 명세·plan 리뷰에는 `accept`나 `regenerate` 같은 결정 값이 없으므로 서브 세션은 그 값을 지어내지 않는다. 서브 세션은 리뷰 반영 뒤 다시 리뷰할지 묻지 못하므로 생략하고, 기능적 변화가 있었던 반영을 리포트에 적는다.

현재 세션은 질문을 사용자에게 하나씩 알리고, 답을 큰 명세 「결정 기록」에 적은 뒤 같은 서브 세션에 보낸다. 계약 변경 요청이면 사용자에게 기각, 다음 개발로 미룸, 지금 채택 중 하나를 고르게 한다. 채택하면 현재 세션이 통합 브랜치에서 큰 명세와 계약 코드를 고친 뒤 영향받는 서브 세션에 알린다.

## 가드레일

현재 세션은 서브 세션이 `DONE`을 돌려주면 아래 검사를 차례로 한다. 아래 명령의 `<개발>`은 개발 이름이고 `<id>`는 워크스트림 id다.

**수정 범위 대조.** 현재 세션은 `git diff --name-only --no-renames dev/<개발>...ws/<개발>/<id>` 출력의 각 파일이 큰 명세의 허용 경로와 자기 문서 경로 중 하나에 맞는지 본다. 맞지 않는 파일이 있으면 병합하지 않고 그 서브 세션에 되돌린다. 점 세 개는 두 브랜치의 공통 조상부터 비교하므로, 통합 브랜치에서 받은 변경은 출력에 나오지 않는다. `--no-renames`를 붙이면 허용 경로 밖 파일을 안으로 옮긴 변경이 원래 경로의 삭제로 드러난다.

**교집합 검사.** 현재 세션은 동시에 진행한 워크스트림 브랜치를 둘씩 짝지어 위 diff 출력의 교집합을 구한다. 한 쌍이라도 비어 있지 않으면 병합 전에 멈추고 알린다. 허용 경로 패턴끼리 겹치는지는 사람이 놓치기 쉬우므로 현재 세션이 이 검사를 범위 대조와 함께 한다.

**리뷰 마커 확인.** 서브 세션이 쓴 문서에는 현재 세션의 Stop 게이트(미리뷰 명세가 남은 채 턴을 끝내지 못하게 하는 훅)가 적용되지 않는다. 현재 세션은 `git diff --name-only --diff-filter=A dev/<개발>...ws/<개발>/<id> -- docs/superpowers/specs docs/superpowers/plans`로 추가된 하부 명세와 plan을 구하고, 각 파일 마지막 줄을 `git show ws/<개발>/<id>:<경로> | tail -n 1`로 읽어 `spec-review` 마커가 있는지 확인한다. 현재 세션의 체크아웃에는 워크스트림 브랜치의 파일이 없으므로 작업 트리에서 읽지 않는다. 마커가 없으면 병합하지 않는다. 마커가 `escalated`이면 그 🔴의 사용자 답이 큰 명세 「결정 기록」에 있는지 확인하고, 없으면 병합하지 않는다.

**시험 병합.** 현재 세션은 `git switch -c try/<id> dev/<개발>`로 임시 브랜치를 만들고 `git merge --no-ff ws/<개발>/<id>`로 병합한 뒤, 계약 테스트와 큰 명세의 통합 확인을 실행한다. 병합 커밋 메시지에는 「측정」의 트레일러와 `Workstream: ws/<개발>/<id>` 트레일러를 넣는다. 통과하면 `git switch dev/<개발>`, `git merge --ff-only try/<id>`, `git branch -D try/<id>`를 실행한다. 실패하면 `git switch dev/<개발>`과 `git branch -D try/<id>`로 임시 브랜치를 지우고, 원인이 계약이면 큰 명세로, 워크스트림 내부면 그 서브 세션으로 보낸다.

**되돌림을 쓰지 않는 이유.** 통합 브랜치는 통과한 병합만 받으므로 되돌림 커밋이 생기지 않는다. 되돌린 병합은 git이 공통 이력으로 보아 다시 병합할 때 처음 변경이 빠지므로(git 문서 `howto/revert-a-faulty-merge`), 현재 세션은 `git revert`로 통합 실패를 처리하지 않는다.

**진행 위치.** 현재 세션은 상태 문서 없이 git에서 진행 위치를 도출한다. `git log dev/<개발> --format=%B`에 `Workstream: ws/<개발>/<id>` 줄이 있는 워크스트림은 끝났다. `git branch --merged`는 커밋이 아직 없는 워크스트림 브랜치도 병합된 것으로 내므로 쓰지 않는다. 끝나지 않은 워크스트림 브랜치는 plan이 있으면 승인 뒤 진행 중이고, 하부 명세만 있으면 승인 대기이며, 둘 다 없으면 하부 명세 작성 중이다. 큰 명세 목록에 있는데 브랜치가 없는 워크스트림은 시작 전이다.

**크래시와 멈춤.** 완료 통지가 오지 않는 서브 세션이 있으면, 현재 세션은 CLI의 서브에이전트 화면에서 그 세션으로 들어가 실행 상태를 확인한다. 종료되었으면 「이어 쓰기와 재개」대로 재개하거나 새 서브 세션을 시작한다. 타임아웃과 헬스체크 도구가 없어 현재 세션의 주의에 의존한다.

**비용.** 서브 세션마다 맥락 재확립과 워커 팬아웃이 든다. 2026-07 스파이크에서 사소한 워크스트림 하나당 약 40k 토큰이 들었다. 이 값은 워커를 포함하지만, 하부 명세와 승인 단계가 없던 흐름에서 잰 값이다.

## 측정

현재 세션은 워크스트림마다 실패한 시험 병합 수와 그 원인, 서브 세션이 올린 질문 수, 완료 통지의 `subagent_tokens`를 센다. 이 값은 시험 병합의 `git merge --no-ff -m`에 `Integration-Failures:`, `Questions:`, `Tokens:` 트레일러로 넣는다. fast-forward로 통합 브랜치에 들어가므로 이 커밋이 통합 브랜치에 남는다. 개발이 끝나면 현재 세션이 `git log dev/<개발>`에서 이 값을 모아 사용자에게 보고한다.

## 관측성

수동 `Agent` 중첩은 `/workflows` 집계 대시보드에 뜨지 않는다. 대신 CLI가 서브에이전트를 표시하고, 사용자는 그 항목을 더블클릭해 각 서브 세션의 실행 화면으로 들어간다. 집계 대시보드와 메트릭은 볼 수 없고, 어떤 워크트리가 어느 서브 세션에 배정됐는지도 화면에 나오지 않는다.

## 재구현 금지

아이디어에서 명세까지는 `brainstorming`, plan은 `writing-plans`, 실행 루프는 `subagent-driven-development`, 병렬 디스패치 메커니즘은 `dispatching-parallel-agents`, 워크트리 격리는 `using-git-worktrees`, 리뷰 렌즈는 `lens-*`가 소유한다.

## 한계

3층은 조율 층을 얹으므로 나눌 일이 둘 이상일 때만 값을 한다. 무엇이 검증됐고 무엇이 아직 아닌지는 설계 문서(`docs/superpowers/specs/2026-10-09-nested-orchestration-large-dev-design.md`)의 「이어받는 판단과 검증」과 「검증하지 않은 가정」이 포함한다.

**비목표** — `Workflow` 결정론 버전과 집계 UI 대시보드와 오케스트레이션 상태 문서는 만들지 않는다. `Workflow`는 중첩을 1단계로 제한해 판단으로 SDD를 실행하는 서브 세션을 수용하지 못한다. 진행 위치는 git에서 도출한다. 4층 이상 더 깊은 중첩도 다루지 않는다.
````

- [ ] **Step 3: 스킬에 걸리는 검사 확인**

```bash
cd /d/projects/dc-nested-large-dev
F=skills/nested-orchestration/SKILL.md
grep -nE 'L[123]|서브오케스트레이터|메인 세션|스펙|계획|Explore|~/.claude/disciplined-coder/' "$F"
grep -F '렌즈에게 에이전트원칙을 알리는 법' "$F" | grep -c 'dispatching-lenses'
grep -c '^## 렌즈에게 에이전트원칙을 알리는 법' "$F"
bash scripts/test_docs_drift.sh > /dev/null 2>&1; echo "exit=$?"
```

Expected: 첫 명령 출력 없음, 둘째 `1`, 셋째 `0`, 넷째 `exit=0`.

- [ ] **Step 4: 커밋**

```bash
cd /d/projects/dc-nested-large-dev
git add skills/nested-orchestration/SKILL.md
git commit -m "nested-orchestration 을 큰 개발 분할로 넓힌다: 현재 세션은 큰 명세·계약·통합만 맡고 서브 세션이 하부 명세부터 구현까지 맡으며, 하던 일은 이어 쓰고 통합은 시험 병합으로 한다

Co-Authored-By: Claude Opus 5.5 (1M context) <noreply@anthropic.com>
Claude-Session: https://claude.ai/code/session_01SoV9e1oYTTUGnDcM4th7d2"
```

---

### Task 5: 렌즈 규율 문서의 용어

**Files:**
- Modify: `skills/dispatching-lenses/SKILL.md`
- Modify: `skills/review-specs/SKILL.md`

**Interfaces:**
- Consumes: Task 4의 용어(현재 세션, 서브 세션)
- Produces: 없음(규칙은 바꾸지 않는다)

- [ ] **Step 1: dispatching-lenses 교체**

바꾸기 전 문자열로 찾아 바꾼다.

| 바꾸기 전 | 바꾼 뒤 |
|---|---|
| `` `nested-orchestration`의 서브오케스트레이터는 `` | `` `nested-orchestration`의 서브 세션은 `` |
| `` `review-specs`, L2, `audit-repo-docs` ``(표 두 행) | `` `review-specs`, 서브 세션, `audit-repo-docs` `` |
| `` L2는 `nested-orchestration`의 하위 실행자이며 `` | `` 서브 세션은 `nested-orchestration`의 하위 실행자이며 `` |
| `` `review-specs`와 L2 `` | `` `review-specs`와 서브 세션 `` |
| `- **L2** — ` / `리포트에 적어 L1에 넘긴다.` | `- **서브 세션** — ` / `리포트에 적어 현재 세션에 넘긴다.` |
| `` `nested-orchestration`의 L2 다. `` | `` `nested-orchestration`의 서브 세션이다. `` |

- [ ] **Step 2: review-specs 교체**

| 바꾸기 전 | 바꾼 뒤 |
|---|---|
| `판정 기록, L2 처리는` | `판정 기록, 서브 세션 처리는` |
| `` (`nested-orchestration`의 L2)는 `` | `` (`nested-orchestration`의 서브 세션)은 `` |
| `리포트에 적어 L1 에 넘긴다.` | `리포트에 적어 현재 세션에 넘긴다.` |

- [ ] **Step 3: 확인**

```bash
cd /d/projects/dc-nested-large-dev
grep -nE 'L[123]|서브오케스트레이터' skills/dispatching-lenses/SKILL.md skills/review-specs/SKILL.md
bash scripts/test_docs_drift.sh > /dev/null 2>&1; echo "exit=$?"
```

Expected: 첫 명령 출력 없음, `exit=0`.

- [ ] **Step 4: 커밋**

```bash
cd /d/projects/dc-nested-large-dev
git add skills/dispatching-lenses/SKILL.md skills/review-specs/SKILL.md
git commit -m "렌즈 규율 문서의 L1·L2 를 현재 세션·서브 세션으로 바꾼다

Co-Authored-By: Claude Opus 5.5 (1M context) <noreply@anthropic.com>
Claude-Session: https://claude.ai/code/session_01SoV9e1oYTTUGnDcM4th7d2"
```

---

### Task 6: 새 가드레일 실측

임시 git 저장소에서 스킬 「가드레일」의 명령을 그대로 실행하고 결함을 주입한다. 저장소에는 결과 한 줄만 커밋한다.

**Files:**
- Create(저장소 밖): `mktemp -d`로 만든 디렉터리의 `guard_check.sh`
- Modify: `docs/superpowers/specs/2026-10-09-nested-orchestration-large-dev-design.md`(「이어받는 판단과 검증」 끝)

**Interfaces:**
- Consumes: Task 4 「가드레일」의 명령 형식(점 세 개 diff, `--no-renames`, `git show`로 마커 읽기, 시험 병합, `Workstream:` 트레일러)

- [ ] **Step 1: 스크립트 작성과 실행**

한 Bash 호출 안에서 스크립트를 쓰고 바로 실행한다.

```bash
cd /d/projects/dc-nested-large-dev
T=$(mktemp -d); echo "$T"
cat > "$T/guard_check.sh" <<'EOF'
#!/usr/bin/env bash
# 스킬 「가드레일」 명령을 결함 주입으로 확인한다. 인자: 임시 디렉터리.
set -u
R="$1/guard-repo"; rm -rf "$R"; mkdir -p "$R"; cd "$R" || exit 1
git init -q -b main; git config user.email t@t; git config user.name t; git config core.autocrlf false
pass=0; fail=0
ok(){ if eval "$2"; then echo "PASS: $1"; pass=$((pass+1)); else echo "FAIL: $1"; fail=$((fail+1)); fi; }
allowed(){ local id="$1" f="$2"; case "$f" in
  src/$id/*|docs/superpowers/specs/*-x-$id-design.md|docs/superpowers/plans/*-x-$id.md|docs/superpowers/reviews/*-x-$id-*) return 0;; esac; return 1; }
outside(){ local id="$1"; git diff --name-only --no-renames "dev/x...ws/x/$id" | while read -r f; do allowed "$id" "$f" || echo "$f"; done; }
added_docs(){ git diff --name-only --diff-filter=A "dev/x...ws/x/$1" -- docs/superpowers/specs docs/superpowers/plans; }
nomarker(){ added_docs "$1" | while read -r f; do git show "ws/x/$1:$f" | tail -n 1 | grep -q '^<!-- spec-review: \(passed\|escalated\)' || echo "$f"; done; }
escalated(){ added_docs "$1" | while read -r f; do git show "ws/x/$1:$f" | tail -n 1 | grep -q '^<!-- spec-review: escalated' && echo "$f"; done; }
done_ws(){ git log dev/x --format=%B | grep -qx "Workstream: ws/x/$1"; }
trial(){ local id="$1"; git switch -q dev/x; git switch -qc "try/$id" dev/x
  git merge -q --no-ff "ws/x/$id" -m "$id 통합" -m "Workstream: ws/x/$id"; }
land(){ local id="$1"; git switch -q dev/x; git merge -q --ff-only "try/$id"; git branch -qD "try/$id"; }
drop(){ local id="$1"; git switch -q dev/x; git branch -qD "try/$id"; }
mkdir -p src/a src/b src/shared docs/superpowers/specs; echo base > src/shared/routes.txt; echo m > README; git add -A; git commit -qm base
git switch -qc dev/x
# 워크스트림 a: 허용 경로 안만 고치고 통합한다
git switch -qc ws/x/a dev/x; echo a1 > src/a/a.txt
printf 'spec\n<!-- spec-review: passed -->\n' > docs/superpowers/specs/2026-10-09-x-a-design.md
git add -A; git commit -qm a
ok "시나리오0 a 범위 대조 통과" '[ -z "$(outside a)" ]'
trial a; land a
# 시나리오 F: 커밋 없는 브랜치는 끝난 것으로 나오지 않는다
git branch ws/x/c dev/x
ok "시나리오F 트레일러가 있는 a 는 끝남" 'done_ws a'
ok "시나리오F 커밋 없는 c 는 끝나지 않음" '! done_ws c'
# 시나리오 A: a 통합 뒤 갈라진 b 는 b 파일만 낸다
git switch -qc ws/x/b dev/x; echo b1 > src/b/b.txt; git add -A; git commit -qm b
ok "시나리오A 선행 통합 뒤 b 범위 대조 통과" '[ -z "$(outside b)" ]'
# 시나리오 B: 허용 경로 밖 기존 파일 수정과 새 파일 추가
echo hack >> src/shared/routes.txt; git add -A; git commit -qm b-mod
ok "시나리오B 범위 밖 수정 검출" '[ "$(outside b)" = "src/shared/routes.txt" ]'
git reset -q --hard HEAD~1
echo new > src/shared/new.txt; git add -A; git commit -qm b-new
ok "시나리오B 범위 밖 새 파일 검출" '[ "$(outside b)" = "src/shared/new.txt" ]'
git reset -q --hard HEAD~1
# 시나리오 C: 허용 경로 밖 파일을 안으로 옮김
git mv src/shared/routes.txt src/b/routes.txt; git commit -qm b-mv
ok "시나리오C 이동은 원래 경로 삭제로 검출" 'outside b | grep -qx "src/shared/routes.txt"'
git reset -q --hard HEAD~1
# 시나리오 P: 접두어 id(b 와 bx)의 문서는 서로 허용되지 않는다
printf 's\n<!-- spec-review: passed -->\n' > docs/superpowers/specs/2026-10-09-x-bx-design.md; git add -A; git commit -qm b-prefix
ok "시나리오P 다른 id 의 문서 검출" '[ "$(outside b)" = "docs/superpowers/specs/2026-10-09-x-bx-design.md" ]'
git reset -q --hard HEAD~1
# 시나리오 D: 마커 없음, escalated, passed. 현재 세션 체크아웃(dev/x)에서 git show 로 읽는다
echo spec > docs/superpowers/specs/2026-10-09-x-b-design.md; git add -A; git commit -qm b-spec
git switch -q dev/x
ok "시나리오D dev 체크아웃에서 마커 없는 문서 검출" '[ "$(nomarker b)" = "docs/superpowers/specs/2026-10-09-x-b-design.md" ]'
git switch -q ws/x/b; printf '<!-- spec-review: escalated -->\n' >> docs/superpowers/specs/2026-10-09-x-b-design.md; git commit -qam b-esc
git switch -q dev/x
ok "시나리오D escalated 문서는 마커 있음으로 통과" '[ -z "$(nomarker b)" ]'
ok "시나리오D escalated 문서는 따로 출력" '[ "$(escalated b)" = "docs/superpowers/specs/2026-10-09-x-b-design.md" ]'
git switch -q ws/x/b; printf 'spec\n<!-- spec-review: passed -->\n' > docs/superpowers/specs/2026-10-09-x-b-design.md; git commit -qam b-pass
git switch -q dev/x
ok "시나리오D passed 문서는 어느 출력에도 없음" '[ -z "$(nomarker b)" ] && [ -z "$(escalated b)" ]'
# 시나리오 E: 통합 확인 실패 → dev 불변 → 고친 뒤 재시도에 처음 변경과 수정이 모두 들어감
git switch -q ws/x/b; echo broken > src/b/check.txt; git add -A; git commit -qm b-broken
before="$(git rev-parse dev/x)"
integration_ok(){ [ "$(cat src/b/check.txt 2>/dev/null)" != broken ]; }
trial b
ok "시나리오E 결함 주입 통합은 실패" '! integration_ok'
drop b
ok "시나리오E 실패 뒤 dev 불변" '[ "$(git rev-parse dev/x)" = "$before" ]'
ok "시나리오E 실패 뒤 b 는 끝나지 않음" '! done_ws b'
git switch -q ws/x/b; echo fixed > src/b/check.txt; git commit -qam b-fix
trial b
ok "시나리오E 재시도 통합 통과" 'integration_ok'
land b
ok "시나리오E 처음 변경 포함" '[ -f src/b/b.txt ] && [ -f docs/superpowers/specs/2026-10-09-x-b-design.md ]'
ok "시나리오E 수정 포함" '[ "$(cat src/b/check.txt)" = fixed ]'
ok "시나리오E 재시도 뒤 b 는 끝남" 'done_ws b'
echo "PASS=$pass FAIL=$fail"; [ "$fail" -eq 0 ]
EOF
bash "$T/guard_check.sh" "$T"
```

Expected: 모든 줄이 `PASS:`이고 마지막 줄이 `PASS=<n> FAIL=0`.

- [ ] **Step 2: 결과 반영**

FAIL이 하나라도 나오면 스킬 「가드레일」의 명령이 틀린 것이다. 명령을 고쳐 Task 4를 다시 커밋하고 Step 1을 다시 실행한다. 모두 통과하면 spec 「이어받는 판단과 검증」 절의 목록 끝에 아래 형식으로 한 줄을 추가하고 커밋한다(꺾쇠는 실제 값으로 바꾼다).

```
- **새 가드레일 실측(<실행 날짜>):** 임시 저장소에서 범위 대조·접두어 id·마커 확인·시험 병합·진행 위치 시나리오를 결함 주입으로 실행해 <n>개 검사를 모두 통과했다(plan Task 6).
```

```bash
cd /d/projects/dc-nested-large-dev
git add docs/superpowers/specs/2026-10-09-nested-orchestration-large-dev-design.md
git commit -m "새 가드레일을 임시 저장소에서 결함 주입으로 확인한 결과를 설계에 적는다

Co-Authored-By: Claude Opus 5.5 (1M context) <noreply@anthropic.com>
Claude-Session: https://claude.ai/code/session_01SoV9e1oYTTUGnDcM4th7d2"
```

---

### Task 7: 전체 확인

**Files:**
- 없음(확인만 한다)

- [ ] **Step 1: 용어 grep**

```bash
cd /d/projects/dc-nested-large-dev
grep -nE 'L[123]|서브오케스트레이터|sub-orchestrator' skills/nested-orchestration/SKILL.md skills/dispatching-lenses/SKILL.md skills/review-specs/SKILL.md scripts/test_docs_drift.sh
grep -n '메인 세션' skills/nested-orchestration/SKILL.md
```

Expected: 두 명령 모두 출력 없음. `-w`를 쓰지 않는다. Task 2에서 조건 C를 넣었으면 아래 두 명령도 출력이 없어야 한다. 원칙을 현행대로 두었으면 이 두 명령은 생략하고 그 사실을 보고에 적는다.

```bash
cd /d/projects/dc-nested-large-dev
grep -nE '서브오케스트레이터|sub-orchestrator' agent-principles.md
grep -n '작업 다섯' docs/domain-discipline.md
```

- [ ] **Step 2: 검사 묶음**

저장소 CLAUDE.md 「변경 뒤 실행」의 명령을 그대로 실행한다.

```bash
cd /d/projects/dc-nested-large-dev
d=$(mktemp -d); for t in scripts/test_*.sh; do ( bash "$t" > "$d/$(basename "$t").log" 2>&1 || echo "$t" >> "$d/bad" ) & done; wait; if [ -s "$d/bad" ]; then echo "FAILED:"; while read -r t; do echo "--- $t"; grep 'FAIL:' "$d/$(basename "$t").log"; done < "$d/bad"; else echo "ALL PASS"; fi
```

Expected: `ALL PASS`

- [ ] **Step 3: 플러그인 검증**

```bash
cd /d/projects/dc-nested-large-dev
claude plugin validate ./
```

Expected: `version` 경고 하나만 나온다.

- [ ] **Step 4: 사용자 보고**

실행한 명령과 출력, Task 1 측정 표, Task 6 결과를 보고한다. main 병합과 push는 사용자 승인을 받은 뒤 `superpowers:finishing-a-development-branch`로 한다.

<!-- spec-review: passed -->
