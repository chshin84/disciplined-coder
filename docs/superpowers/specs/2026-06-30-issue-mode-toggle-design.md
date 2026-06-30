# 오답노트 처분 모드 토글 — 설계 (2026-06-30)

> 3렌즈 리뷰 반영본. 미해결(열린 것) 처분을 토글로 설정 가능하게 한다. 기본은 가장 가벼운 처분
> (surface+메모리), GitHub Issues 위임은 **옵트인**. §다의 must-keep 처분을 모드 의존으로 묶고,
> "다 할 수 없음"을 인정하는 4단 처분(지금함 / must-keep / 🔴 / 드롭)을 명시한다.
> v2 수정: config를 **런타임별 홈**으로(교차홈 SSOT 모순 해소), KDIR **위생 화이트리스트에 등록**
> (거짓 경고 제거 — critical), 첫 설치를 **결정론적 기본 생성 + 1회 안내**로(에이전트-의존 제거).

## 문제 (왜)

현재 `agent-principles.md` §다는 must-keep 미해결을 "프로젝트의 진짜 트래커(GitHub Issues 등)로
위임한다"라고 적어 **"열린 건 반드시 이슈로"** 처럼 읽힌다. 실제 의도는 아니다.

- **즉시 수정엔 이슈 불필요** — 지금 고치면 추적할 '열린 것'이 없다.
- **다 할 수 없는 마이너는 버려야 한다** — 모든 사소한 발견에 이슈를 만들면 스팸이 된다.
- **사용자마다 GitHub Issues를 원치 않을 수 있다** — 트래커 위임 강제는 과한 의무(`SIMPLE` 위반)다.

즉 처분 정책이 고정·강제돼, 가벼운 운영을 원하는 사용자에게 맞지 않는다. 이를 **토글**로 풀고
기본을 가장 가벼운 쪽에 둔다.

## 핵심 원칙

- **`기본은 가볍게`** — 기본 처분은 surface+메모리(자동 이슈 없음). 트래커 위임은 의식적으로 켤 때만(`옵트인`).
- **`모드는 런타임별 단일 홈`** — 모드는 각 런타임 홈의 config 파일 하나(Claude=`~/.claude/...`, Codex=`~/.codex/...`)에 둔다. 한 런타임 안에서는 단일 출처(`SSOT`)이고, 부재=기본 surface. (정본·solved가 홈별인 것과 동형 — 교차홈 단일파일을 억지로 만들지 않는다.)
- **`다 할 수 없음을 인정`** — 4단 처분에 "드롭"을 명시한다. 추적 안 한 것은 안 썩고(drift-proof), 중요하면 재발견된다(작업·audit이 다시 들춤).

## 구성요소 (ID 글로서리 · 무순서)

- **`모드 config`** — `<KDIR>/issue-mode`(KDIR = 각 런타임의 `…/disciplined-coder/`). 내용은 `surface`
  또는 `issues` 한 단어. **부재 = `surface`**. 읽을 때 **앞뒤 공백·개행 trim**, exact-match(`surface`|`issues`),
  그 외 불명값은 **`surface`로 폴백 + stderr 경고**(안전 기본 + FAIL-LOUD 표면화). **두 scaffold의 위생
  WHITELIST에 `issue-mode`를 추가**해 매 세션 '비관리 파일 잔존' 거짓 경고·삭제를 막는다(critical 해소).
- **`scaffold 모드 주입`** — scaffold(매 SessionStart)가 자기 홈의 config를 읽어 **현재 모드를 한 줄
  additionalContext로 주입**한다(예: "오답노트 처분 모드: surface+메모리 — GitHub 이슈 위임 OFF"). 기존
  stdout 주입 단계(step 4) 옆에 추가. `codex-scaffold.sh`도 **자기 홈(~/.codex)** 기준 동일 주입(미러 — 코드는
  병렬, 사람용 문자열은 양쪽에 같은 형식). 주입 문자열 자체는 홈 독립적이나 *값*은 자기 홈 config에서 읽는다.
- **`첫 설치 기본 생성 + 1회 안내`** — config **부재** 시 scaffold가 **`surface`로 결정론적 생성**하고,
  그 생성한 세션에 한해 **1회 안내**를 주입한다: "🔵 disciplined-coder: 처분 모드를 surface(기본)로 시작했다 —
  GitHub Issues 위임을 켜려면 `/issue-mode issues`." 다음 세션부터 config가 존재하므로 안내가 반복되지 않는다
  (결정론적 닫힘 — 에이전트 행동에 의존하지 않는다). scaffold는 비대화형이라 *대화형 질문*이 불가하므로, 설치 시
  "묻기"는 이 1회 안내(선택지 surface + 변경법)로 실현한다.
- **`/issue-mode 커맨드`** — `commands/issue-mode.md`(인자 `$ARGUMENTS`를 스크립트에 전달) + `scripts/issue-mode.sh`.
  `/issue-mode issues`·`/issue-mode surface`로 **자기 홈** config write(멱등; `mkdir -p`로 자기완결 — scaffold
  선행 가정 안 함), 인자 없으면 현재 모드 표시, 잘못된 인자는 **거부(비-zero + 사용법)**. (이 플러그인 커맨드 계열
  — `setup-discipline`·`add-pointer` 동급. "skill"이라 칭했으나 토글은 동작이라 커맨드가 맞다.)
- **`§다 갱신`** — `agent-principles.md` §다 "열린 것" 불릿을 **4단 처분**으로 재서술하고 must-keep을 모드에 묶는다:
  ① 지금 할 것은 그냥 한다(이슈 불필요) · ② **미루는 must-keep는 주입된 현재 모드를 따른다 — `surface`면
  메모리+사용자 surface, `issues`면 자동 close 트래커(GitHub Issues) 위임** · ③ 🔴는 즉시 surface ·
  ④ 그 외 마이너는 한 번 surface하고 **드롭**(다 할 수 없으니 의식적으로 놓아줌; 재발견이 안전망). **명확화 한 줄**:
  "issues 모드는 must-keep을 *사용자의 외부 트래커에 위임*하는 것이지, disciplined-coder가 이슈를 *상태로 추적*
  하는 것이 아니다 — §다 헤더 '이슈 트래킹 안 함'은 유지된다."

## 데이터 흐름

```
[자동·매 SessionStart] scaffold → 자기 홈 config(issue-mode) 읽음
   · 있으면 → trim·검증 후 그 모드 1줄 주입 (불명값이면 surface 폴백+경고)
   · 없으면 → surface로 생성 + "첫 설치 안내" 1줄 주입 (이번 세션만)
[수동·언제든] /issue-mode issues|surface → 자기 홈 config write(멱등) → 다음 세션부터 그 모드 주입
[처분 시] 에이전트가 §다 + 주입된 현재 모드를 따라 must-keep 처분(surface or 트래커 위임)
```

## 비목표 (이 spec 밖)

- **프로젝트별 모드** — 런타임-홈별만(사용자 선호). 프로젝트 override는 미래(`YAGNI`).
- **Claude↔Codex 모드 동기화** — 각 홈이 독립(둘 다 쓰면 각자 설정). 교차 동기화는 미래.
- **자동 이슈 생성 도구** — `issues` 모드의 GitHub Issue 등록은 에이전트가 `gh`로 수행하는 *규범*이지 이 spec이 만드는 자동화가 아니다.
- **다중 트래커 연동**(Jira 등) — 미래.

## 성공 기준 (무엇이 "됨")

- 계약 테스트 **FAIL=0**(scaffold·hooks·codex; 매직넘버 없이 불변식).
- 신규 테스트(불변식): config=`issues`면 주입에 issues 표시·`surface`/부재면 surface 표시, **부재 시 surface로
  생성됨 + 첫설치 안내 주입**·재실행 시 안내 미반복(config 존재), 불명값(`xyz`·트레일링 개행)이면 surface 폴백+경고,
  **issue-mode가 위생 경고를 안 냄**(WHITELIST 등록 검증), `/issue-mode issues`→config `issues`·`surface`→`surface`·
  인자 없으면 현재 모드 출력·잘못된 인자 거부·멱등·KDIR 부재에서도 자기완결(mkdir). **codex도 동일**(test_codex_scaffold).
- `agent-principles.md` §다에 **4단 처분 + 모드 의존 + 이슈모드≠이슈트래킹 명확화** 문구 존재(검증).
- `claude plugin validate ./` 통과(신규 경고 0).

## 변경 대상

- **신규** — `scripts/issue-mode.sh`, `commands/issue-mode.md`.
- **편집** — `scripts/scaffold.sh`·`scripts/codex-scaffold.sh`(**WHITELIST += issue-mode** · 부재 시 surface 생성 ·
  모드 주입 · 첫설치 안내), `agent-principles.md` §다(4단 처분·모드 의존·명확화), `scripts/test_scaffold.sh`·
  **`scripts/test_codex_scaffold.sh`**(모드·`/issue-mode`·위생무경고 케이스), `README.md`(커맨드 목록에 `/issue-mode`).

## 경계 (정직히)

- **모드 config는 머신로컬**(`~/.claude`·`~/.codex`, 비-git) — solved와 같은 PC 사용자 상태. 머신을 넘지 않는다(`메모리는 머신로컬` 동류).
- **사람용 주입 문자열은 두 scaffold에 병렬 존재** — 듀얼런타임 미러의 기존 패턴(scaffold↔codex가 본래 병렬)을 따른다. 한쪽 변경 시 짝도 고친다(미러 불변식).
- **surface 모드의 '유지하려는 🔴'** — surface 모드엔 자동 트래커가 없으니 영속 보관처가 없다. 그 경우는 §다 ③대로 즉시 surface하고, 사용자가 보관을 원하면 `/issue-mode issues`로 켜거나 직접 트래커에 박는다(설계상 트레이드오프).

## 리뷰 이력 (3렌즈 — 해소)

- **critical(adversarial)·major(grounding·consistency 수렴): KDIR 위생 WHITELIST 충돌** — config가 화이트리스트
  밖이라 매 세션 거짓 경고/삭제. → 두 scaffold WHITELIST에 `issue-mode` 등록 + 무경고 불변식 테스트.
- **major: codex 교차홈 SSOT/미러 불가** — config를 런타임별 홈으로(단일 cross-home 주장 철회), 각 scaffold가 자기 홈 읽음.
- **major(adversarial): 첫 설치 묻기 과설계+에이전트-의존 실패모드** — scaffold가 기본 surface 결정론적 생성 + 1회 안내로 단순화(AskUserQuestion-persist 제거).
- **불명세(adversarial): config 값 오타·공백·case** — trim + exact-match + 불명값 surface 폴백+경고 명시.
- **coverage-gap(consistency): codex 테스트 누락** — test_codex_scaffold 변경대상 추가.
- **이름 충돌(consistency): /issue-mode vs §다 '이슈 트래킹 안 함'** — §다에 "issues=위임이지 상태추적 아님" 명확화.
- **minor: 커맨드 인자·KDIR 부재** — `$ARGUMENTS` 전달 + issue-mode.sh `mkdir -p` 자기완결.

<!-- spec-review: passed -->
