# 자기감사 수정 2차 — SSOT 손복제·문서-코드 드리프트 구현 계획

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** 2026-07-03 자기감사의 확정 발견 중 SSOT 손복제·문서-코드 드리프트 계열(발견 1·2·3·4·5·6·7·8·9·11·16·18·19번 — 개수는 세지 않는다, 매핑은 각 Task 배경 참조)과 plugin.json version 경고를 해소한다 — scaffold 쌍둥이의 ~40줄 축어 복제를 공유 헬퍼로 추출하고, spec/plan 경로 계약을 술어 함수로 단일화하고, 정본 머리말·README·오답노트 형식의 드리프트를 코드 정본 참조로 바꾼다.

**Architecture:** 결합 순서가 핵심이다 — Task 3(scaffold 공유 헬퍼 추출)이 끝나야 Task 6(README)이 가리킬 정본 위치(`scripts/_scaffold_common.sh`의 WHITELIST)가 확정된다. 코드 추출(Task 3·4)은 동작 불변 리팩터링이므로 기존 계약 테스트(FAIL=0)가 그대로 안전망이고, 문서 수정(Task 2·5·6·7·8)은 grep 기반 계약 체크를 테스트에 더해 재드리프트를 막는다(drift-proof by construction). 1차 계획(안전망·런타임 4건)은 완료·push됐고 CI가 돌고 있다.

**Tech Stack:** 순수 bash, 기존 테스트 하니스(FAIL=0), 마크다운 문서.

**전제 지식(레포 관례):** 1차 계획과 동일 — FAIL=0 계약·매직 넘버 금지, 한국어 conventional commit + 트레일러(`Co-Authored-By: Claude Fable 5 <noreply@anthropic.com>` / `Claude-Session: https://claude.ai/code/session_01GHD9UvKFd3nLLTiryd1m77`), Git Bash 실행, 전체 검증은 테스트 3종 + `claude plugin validate ./`.

---

## 파일 구조

| 파일 | 이 계획에서 |
|---|---|
| `.claude-plugin/plugin.json` | version 추가(Task 1) |
| `agent-principles.md` | 머리말 오서술 수정(Task 2) · §가 '문서 작성' 행 방법 소유 보정(Task 2) · §다 형식 문구는 유지(정본) |
| `skills/domain-docs/SKILL.md` | 문서 검진 방법 3줄 신설(Task 2 — §가 행이 가리킬 소유자) |
| `scripts/_scaffold_common.sh` | 신규 — scaffold 쌍둥이 공통 로직(Task 3) |
| `scripts/scaffold.sh` · `scripts/codex-scaffold.sh` | 공통 블록을 헬퍼 호출로 교체(Task 3 — solved 템플릿의 §다 형식 정렬은 헬퍼 사본에서 이때 함께 반영되며, Task 5는 이 두 파일을 건드리지 않는다) |
| `docs/solved_problems.md` | 이 레포 solved 헤더 형식 정렬(Task 5) |
| `hooks/_spec_marker.sh` | spec/plan 경로 술어 함수 추가 + '여기만 고친다' 주석 보정(Task 4) |
| `hooks/spec_review_posttooluse.sh` · `spec_review_stop.sh` · `doc_format_pretooluse.sh` · `doc_review_posttooluse.sh` | 경로 패턴을 술어 호출로 교체(Task 4) · ptu 지시문에 escalated 병기(Task 6) |
| `scripts/add-pointer.sh` | 프로젝트 solved 템플릿 형식 정렬(Task 5) |
| 배포본 PC solved(홈 해석 규칙으로 도출되는 `<클로드 홈>/disciplined-coder/solved_problems.md`) | 헤더 1회 보정(Task 5 — 폐기 파일명 참조·형식. **커밋 불가한 레포 밖 편의 보정**) |
| `README.md` | sh/bash·escalated·생성파일 목록·커맨드 목록·Highlights 문구(Task 6) |
| `commands/show-principles.md` · `commands/show-solved.md` | 홈 해석 문구 보정(Task 7) |
| `scripts/test_scaffold.sh` | README↔commands 드리프트 가드 추가(Task 6) |

---

### Task 1: plugin.json에 version을 추가한다

> **superseded(같은 날 번복됨)**: 실행 후 공식 문서 확인 결과, version을 설정하면 마켓플레이스 업데이트가
> 버전 비교로 전환되어 활성 개발 중 커밋 갱신이 사용자에게 배포되지 않는다. version은 다시 제거했고
> validate 경고는 의도된 트레이드오프로 수용한다 — 현행 정본은 `skills/domain-plugin`의 '버전 핀 주의' 항목이다.

배경: `claude plugin validate ./`의 유일한 경고이고, 플러그인 갱신이 커밋 해시로만 식별된다. 최초 semver를 붙인다.

**Files:**
- Modify: `.claude-plugin/plugin.json`

- [ ] **Step 1: version 필드를 추가한다**

`"name": "disciplined-coder",` 바로 아래에 추가한다:

```json
  "version": "1.0.0",
```

- [ ] **Step 2: 경고가 사라졌는지 확인한다**

Run: `claude plugin validate ./`
Expected: 경고 0건으로 통과("Validation passed"). marketplace.json이 version 관련 경고를 새로 내면 그 파일의 해당 플러그인 항목도 같은 값으로 맞춘다(이중 기술이 되지 않게, marketplace 스키마가 요구할 때만).

- [ ] **Step 3: 커밋한다**

```bash
git add .claude-plugin/plugin.json
git commit -m "chore(plugin): 최초 semver(1.0.0)를 붙여 validate 경고를 해소한다

Co-Authored-By: Claude Fable 5 <noreply@anthropic.com>
Claude-Session: https://claude.ai/code/session_01GHD9UvKFd3nLLTiryd1m77"
```

---

### Task 2: 정본 머리말 오서술과 §가 '문서 작성' 행의 방법 소유 공백을 고친다

배경(발견 1·9번): 정본 머리말이 "각 프로젝트의 CLAUDE.md에 @import로 자동 주입"이라고 서술하지만 실제 코드는 `~/.claude/CLAUDE.md` 관리블록에만 배선한다(phase5 이전 설계의 잔재). 또 §가 표의 '문서 작성' 행은 "방법 상세는 호출자 스킬이 SSOT"라는 규칙 아래 렌즈 스킬을 가리키지만, 렌즈들은 "어떻게 실행되는지는 호출자가 정한다"고 선언해 방법 상세의 소유자가 없다 — `domain-docs`(문서 저작 규칙의 SSOT)에 방법을 두고 행이 그것을 가리키게 한다.

**Files:**
- Modify: `agent-principles.md:3-5` (머리말), `agent-principles.md` §가 표의 '문서 작성' 행
- Modify: `skills/domain-docs/SKILL.md` (검진 방법 신설)

- [ ] **Step 1: 머리말을 현행 설계대로 고친다**

`agent-principles.md`의 머리말 문장을 교체한다.

교체 전:
```
모든 작업에 항상 적용한다. 이 파일이 **단일 출처(SSOT)**이며, disciplined-coder 플러그인이
각 프로젝트의 CLAUDE.md에 `@import`로 자동 주입한다. 프로젝트의 사본은 직접 수정하지 말 것
(매 세션 이 정본에서 다시 복사된다).
```

교체 후:
```
모든 작업에 항상 적용한다. 이 파일이 **단일 출처(SSOT)**이며, disciplined-coder 플러그인이
사본을 `~/.claude/disciplined-coder/`에 두고 `~/.claude/CLAUDE.md` 관리블록의 `@import`로
모든 프로젝트에 자동 주입한다(프로젝트 폴더에는 아무것도 쓰지 않는다). `~/.claude`의 사본은
직접 수정하지 말 것 — 매 세션 이 정본에서 다시 갱신된다.
```

- [ ] **Step 2: domain-docs에 문서 검진 방법을 신설한다**

`skills/domain-docs/SKILL.md`의 본문 끝(마지막 섹션 뒤)에 추가한다:

```markdown
## 문서 검진 방법 (§가 '문서 작성' 행의 방법 상세 — 여기가 소유자)
일반 문서를 쓰거나 고친 뒤에는 `reviewer-grounding`(사실·정확)과 `reviewer-fit`(양식·계약) 두 렌즈를
**읽기 전용 서브에이전트**로 각각 호출해 비자가 검진을 받는다(셀프 퇴고만으로 끝내지 않는다).
호출자가 렌즈에 source(검증할 사실·지켜야 할 계약)를 주입하고, 렌즈는 JSON으로 지적을 리턴하며,
반영은 메인 세션이 한다. spec/plan과 달리 마커 게이트는 없다(넛지·비블로킹).
```

- [ ] **Step 3: §가 표의 '문서 작성' 행이 방법 소유자를 가리키게 한다**

`agent-principles.md` §가 표에서 교체한다.

교체 전:
```
| 문서(README 등) 작성 | Claude의 문서 | `reviewer-grounding`+`reviewer-fit` | 훅이 제안·넛지 |
```

교체 후:
```
| 문서(README 등) 작성 | Claude의 문서 | `reviewer-grounding`+`reviewer-fit` (방법 상세는 `domain-docs`) | 훅이 제안·넛지 |
```

- [ ] **Step 4: 검증한다**

Run: `bash scripts/test_scaffold.sh 2>&1 | tail -2 && grep -c "각 프로젝트의 CLAUDE.md" agent-principles.md || true`
Expected: FAIL=0, grep 카운트 0(옛 문구 소멸).

- [ ] **Step 5: 커밋한다**

```bash
git add agent-principles.md skills/domain-docs/SKILL.md
git commit -m "fix(ssot): 정본 머리말의 주입 대상 오서술을 고치고 문서 검진 방법의 소유자를 정한다

머리말이 초기 설계(프로젝트별 주입)의 잔재로 실제 코드(~/.claude 전역
주입)와 모순되던 것을 현행대로 고친다. §가 '문서 작성' 행의 방법 상세가
소유자 없이 렌즈 스킬에 위임되던 공백을 domain-docs 신설 절로 닫는다.

Co-Authored-By: Claude Fable 5 <noreply@anthropic.com>
Claude-Session: https://claude.ai/code/session_01GHD9UvKFd3nLLTiryd1m77"
```

---

### Task 3: scaffold 쌍둥이의 공통 블록을 `_scaffold_common.sh`로 추출한다

배경(발견 16번): scaffold.sh와 codex-scaffold.sh가 위생 루프(WHITELIST·STALE·프룬)·solved 헤더 heredoc·issue-mode 판정 블록 약 40줄을 축어 복제하고 있다 — 플러그인이 강제하는 SSOT의 자기위반이며, 1차 계획에서도 같은 패치를 두 번 했다. 동작 불변 리팩터링이므로 기존 테스트(FAIL=0)가 안전망이다.

**Files:**
- Create: `scripts/_scaffold_common.sh`
- Modify: `scripts/scaffold.sh`, `scripts/codex-scaffold.sh`

- [ ] **Step 1: 공유 헬퍼를 작성한다**

`scripts/_scaffold_common.sh`:

```bash
#!/usr/bin/env bash
# 공유: scaffold.sh(Claude)와 codex-scaffold.sh(Codex)의 공통 로직(SSOT).
# 두 스크립트는 홈 위치·주입 방식만 다르고 관리 디렉터리 정책은 동일해야 한다 — 여기가 정본.

# 관리 디렉터리 화이트리스트(=현 정본 세트)와 구 관리파일(STALE). 여기만 고친다.
SCAFFOLD_WHITELIST="agent-principles.md domains-index.md solved_problems.md issue-mode"
SCAFFOLD_STALE="coding-principles.md"

# 위생(멱등): STALE 제거 → 비화이트리스트는 디렉터리/내용파일 surface·빈 파일 제거.
scaffold_hygiene() {  # $1=KDIR
  local kdir="$1" f b w keep
  for f in $SCAFFOLD_STALE; do [ -f "$kdir/$f" ] && rm -f "$kdir/$f" || true; done
  for f in "$kdir"/*; do
    [ -e "$f" ] || continue
    b="$(basename "$f")"
    keep=0; for w in $SCAFFOLD_WHITELIST; do [ "$b" = "$w" ] && { keep=1; break; }; done
    [ "$keep" = 1 ] && continue
    if [ -d "$f" ]; then
      echo "[disciplined-coder] note: 비관리 디렉터리 '$b' 잔존(자동삭제 안 함, 확인 요)" >&2
      continue
    fi
    if [ -s "$f" ]; then
      echo "[disciplined-coder] note: 비관리 파일 '$b' 잔존(내용 있음 — 자동삭제 안 함, 확인 요)" >&2
    else
      rm -f "$f" || echo "[disciplined-coder] WARNING: 빈 고아 '$b' 삭제 실패(권한·잠금?) — 계속 진행" >&2
    fi
  done
}

# solved 오답노트: 없을 때만 생성(append-only). 생성했으면 0, 이미 있으면 1을 리턴.
scaffold_ensure_solved() {  # $1=KDIR
  local kdir="$1"
  [ -f "$kdir/solved_problems.md" ] && return 1
  cat > "$kdir/solved_problems.md" <<'EOF'
# 해결된 문제 로그 (solved_problems) — PC 전역 · append-only 오답노트

완결된 문제의 교훈 모음 — 차후 비슷한 작업에서 recall해 참고한다. 각 항목: 증상/트리거 → 교훈(다음엔 이렇게 — 처방이 앞).
**완결 후 등록하는 기록이라 '상태'가 아니다** — "문서에 상태 금지"의 예외(append-only, 과거를 지우지 않는다).
일반화 가능한 항목은 디시플린(agent-principles.md)으로 **재기술해 승격**한다(원문은 append-only로 보존 — 이동이 아니라 상위 계층 재작성). 메인 세션만 기록.
EOF
  return 0
}

# issue-mode: 부재면 surface 생성(+1회 안내), 읽어서 mode_line/mode_note를 셋한다(호출측 변수).
scaffold_resolve_issue_mode() {  # $1=KDIR  → sets: mode_line, mode_note
  local kdir="$1" mode_file mode
  mode_file="$kdir/issue-mode"
  mode_note=""
  if [ ! -f "$mode_file" ]; then
    printf 'surface\n' > "$mode_file"
    mode_note="🔵 disciplined-coder: 처분 모드를 surface(기본)로 시작했다 — GitHub Issues 위임을 켜려면 /issue-mode issues."
  fi
  mode="$(tr -d ' \t\r\n' < "$mode_file" 2>/dev/null || printf surface)"
  if [ "$mode" = "issues" ]; then
    mode_line="오답노트 처분 모드: issues — must-keep을 자동 close 트래커(GitHub Issues)에 위임 ON"
  elif [ "$mode" = "surface" ]; then
    mode_line="오답노트 처분 모드: surface+메모리 — GitHub 이슈 위임 OFF"
  else
    echo "[disciplined-coder] WARNING: issue-mode 불명값 '$mode' — surface로 폴백" >&2
    mode_line="오답노트 처분 모드: surface+메모리 — GitHub 이슈 위임 OFF (불명 config 폴백)"
  fi
}
```

주의: solved 헤더의 "각 항목" 문구는 Task 5의 형식 단일화(§다 형식)를 여기서 함께 반영한다 — 헬퍼가 곧 새 정본 사본이기 때문이다.

- [ ] **Step 2: scaffold.sh의 복제 블록을 헬퍼 호출로 교체한다**

`scripts/scaffold.sh`에서 `_resolve_home.sh` 소싱 아래에 소싱을 추가하고:

```bash
. "$(dirname "$0")/_scaffold_common.sh"
```

1b)의 WHITELIST/STALE_MANAGED 선언과 위생 루프 전체를 `scaffold_hygiene "$KDIR"` 한 줄로, 2)의 solved heredoc 블록을 다음으로, 2b)의 MODE_FILE~mode_line 블록을 `scaffold_resolve_issue_mode "$KDIR"` 한 줄로 교체한다:

```bash
# 2) solved 누적 파일(append-only 오답노트): 없을 때만 생성. (이슈·백로그 트래킹은 안 한다 — 범위 밖.)
if scaffold_ensure_solved "$KDIR"; then created="$created solved_problems.md"; fi
```

각 섹션의 주석(1b·2b 설명)은 유지하되 "정책 정본은 _scaffold_common.sh"를 한 줄 병기한다.

- [ ] **Step 3: codex-scaffold.sh도 동일하게 교체한다**

같은 방식으로 소싱 추가 + 1b·2·2b 블록을 헬퍼 호출로 교체한다. **solved 교체는 반드시 Step 2와 동일한 `if scaffold_ensure_solved "$KDIR"; then created="$created solved_problems.md"; fi` 형태여야 한다** — `scaffold_ensure_solved`는 '이미 존재'라는 정상 경로에서 1을 리턴하므로, if 밖의 bare 호출은 `set -e` 아래에서 매 세션 스크립트를 죽인다(이 리턴 규약이 유지보수 함정임을 헬퍼 주석이 이미 경고한다).

- [ ] **Step 4: 동작 불변을 검증한다**

Run: `bash scripts/test_scaffold.sh 2>&1 | tail -2 && bash scripts/test_codex_scaffold.sh 2>&1 | tail -2`
Expected: 둘 다 FAIL=0 — 케이스 4(solved 보존)·10(위생)·12(issue-mode)와 codex 대응 케이스가 전부 헬퍼 경유로 통과한다.

- [ ] **Step 5: 커밋한다**

```bash
git add scripts/_scaffold_common.sh scripts/scaffold.sh scripts/codex-scaffold.sh
git commit -m "refactor(ssot): scaffold 쌍둥이의 공통 40줄을 _scaffold_common.sh로 추출한다

위생 루프(WHITELIST·STALE)·solved 템플릿·issue-mode 판정이 두 파일에
축어 복제되어 손 동기화를 요구하던 SSOT 자기위반을 공유 헬퍼로 닫는다.
동작 불변 — 기존 계약 테스트(FAIL=0)가 안전망이다.

Co-Authored-By: Claude Fable 5 <noreply@anthropic.com>
Claude-Session: https://claude.ai/code/session_01GHD9UvKFd3nLLTiryd1m77"
```

---

### Task 4: spec/plan 경로 계약을 술어 함수로 단일화한다

배경(발견 18·19번): `docs/superpowers/{specs,plans}` 경로 패턴이 훅 4개(spec 2·doc 2)에 각각 하드코딩되어 포함/제외가 거울 동기화를 요구하고, 표기도 이미 갈라졌다(`*/docs/...*.md` vs `*docs/...` vs 접미사 없는 `*/docs/.../*`). 마커 SSOT인 `_spec_marker.sh`에 경로 술어를 함께 두고 네 훅이 호출하게 한다. `_spec_marker.sh`의 "여기만 고친다" 주석도 실제 쌍 계약(SKILL.md 산문)을 드러내게 보정한다.

**Files:**
- Modify: `hooks/_spec_marker.sh`, `hooks/spec_review_posttooluse.sh`, `hooks/spec_review_stop.sh`, `hooks/doc_format_pretooluse.sh`, `hooks/doc_review_posttooluse.sh`

- [ ] **Step 1: 실패하는 테스트가 이미 있는지 확인한다 — 기존 계약이 안전망이다**

Run: `bash scripts/test_hooks.sh 2>&1 | tail -2`
Expected: FAIL=0 (이 리팩터링은 동작 불변 — 기존 stop/ptu/doc 훅 케이스 전부가 회귀 가드다).

- [ ] **Step 2: _spec_marker.sh에 경로 술어를 추가하고 주석을 보정한다**

머리 주석 4행 "마커 규약을 바꾸려면 여기만 고친다."를 다음으로 교체한다:

```bash
# 마커·경로 규약의 코드 정본은 이 파일이다(바꾸려면 여기를 고친다). 산문 기술은
# domain-spec-review SKILL.md와 훅 안내문에도 있으니 규약 변경 시 함께 갱신한다(쌍 계약).
```

파일 끝에 추가한다:

```bash
# spec/plan 경로 술어(SSOT): superpowers 기본 경로에 있는 .md인가.
# 절대경로(훅 입력)와 상대경로(git 출력) 모두 매치되도록 선행 구분자를 요구하지 않는다.
path_is_specplan() {  # $1=경로 → spec/plan 경로면 0
  case "$1" in
    *docs/superpowers/specs/*.md|*docs/superpowers/plans/*.md) return 0 ;;
    *) return 1 ;;
  esac
}
```

- [ ] **Step 3: 네 훅의 인라인 패턴을 술어 호출로 교체한다**

`spec_review_posttooluse.sh`(12-15행)의 case 블록을:

```bash
  path_is_specplan "$FILE" || continue
```

`spec_review_stop.sh`의 두 루프 각각의 **경로 case 블록만**(첫 루프 25-28행, Fix C 루프의 동일 블록)을 다음으로 교체한다 — **24행의 Fix A 상태 필터(`case "${entry:0:2}" in '??'|A*) ...`)는 경로 case가 아니므로 반드시 보존한다**(지우면 기존 spec 수정까지 하드 차단되는 동작 변화가 생긴다):

```bash
  path_is_specplan "$f" || continue
```

`doc_format_pretooluse.sh`(12행)과 `doc_review_posttooluse.sh`(12행)의 제외 case를 다음으로 교체하고, 두 파일에 `. "$DIR/_spec_marker.sh"` 소싱을 추가한다(현재는 마커 함수를 안 쓰므로 소싱이 없다):

```bash
  if path_is_specplan "$FILE"; then continue; fi          # spec/plan은 자체 흐름(하드 게이트)
```

주의(의미 변화 2축 — 의도된 통일): (1) doc 훅의 기존 제외 패턴은 `.md` 접미사가 없었지만(`*/docs/superpowers/specs/*`), doc 훅은 이미 `*.md`만 통과시킨 뒤라 실질 의미는 동일하다. (2) 술어가 선행 슬래시를 요구하지 않으므로(`*docs/...`) ptu·doc 훅의 매치가 기존 `*/docs/...`보다 미세하게 넓어진다 — 경로 성분이 `…xdocs`로 끝나는 경우까지 매치되는데, 하드 게이트인 stop 훅은 이미 이 관대한 형태였고 ptu·doc 훅은 비블로킹이라 오탐 표면이 실질 위험이 아니다(상대·절대 경로를 한 술어로 받기 위한 선택). 통일된 술어가 유일한 진실이 된다.

- [ ] **Step 4: 검증한다**

Run: `bash scripts/test_hooks.sh 2>&1 | tail -2`
Expected: FAIL=0.

- [ ] **Step 5: 커밋한다**

```bash
git add hooks/_spec_marker.sh hooks/spec_review_posttooluse.sh hooks/spec_review_stop.sh hooks/doc_format_pretooluse.sh hooks/doc_review_posttooluse.sh
git commit -m "refactor(ssot): spec/plan 경로 계약을 _spec_marker.sh 술어로 단일화한다

경로 패턴이 훅 4개에 하드코딩되어 포함/제외 거울 동기화를 요구하고 표기가
이미 갈라졌던 것을 path_is_specplan 술어 하나로 닫는다. 동작 불변.

Co-Authored-By: Claude Fable 5 <noreply@anthropic.com>
Claude-Session: https://claude.ai/code/session_01GHD9UvKFd3nLLTiryd1m77"
```

---

### Task 5: 오답노트 항목 형식을 §다 형식으로 단일화한다

배경(발견 8번·7번): 항목 형식이 세 곳에서 세 가지다 — §다(정본): "증상/트리거 → 교훈(다음엔 이렇게)", PC 템플릿: "문제 → 원인 → 해결", 프로젝트 템플릿(add-pointer): "증상/문제 → 교훈". 정본(§다)으로 정렬한다. PC 템플릿은 Task 3에서 헬퍼로 옮기며 이미 반영했으므로, 여기서는 add-pointer 템플릿과 이 레포의 docs/solved_problems.md 헤더, 그리고 배포된 PC solved 헤더(폐기 파일명 `coding-principles.md` 참조 포함)를 1회 보정한다. 배포본 보정은 헤더 줄만 고치고 기존 항목은 건드리지 않는다(append-only 존중).

**Files:**
- Modify: `scripts/add-pointer.sh` (heredoc 헤더), `docs/solved_problems.md` (이 레포 헤더)
- Modify(1회 보정): `C:/Users/CHSHIN/.claude/disciplined-coder/solved_problems.md` (배포본 헤더)

- [ ] **Step 1: add-pointer 템플릿의 형식 문구를 정렬한다**

`scripts/add-pointer.sh` heredoc에서 교체 전:
```
이 레포에서 완결한 문제의 교훈 — 차후 비슷한 작업에서 recall해 참고한다. 각 항목: 증상/문제 → 교훈.
```
교체 후:
```
이 레포에서 완결한 문제의 교훈 — 차후 비슷한 작업에서 recall해 참고한다. 각 항목: 증상/트리거 → 교훈(다음엔 이렇게 — 처방이 앞).
```

- [ ] **Step 2: 이 레포의 docs/solved_problems.md 헤더도 같은 문구로 정렬한다**

같은 교체(전/후 동일 문구)를 `docs/solved_problems.md` 3행에 적용한다. 기존 불릿 항목들은 건드리지 않는다.

- [ ] **Step 3: 배포된 PC solved 헤더를 1회 보정한다 (커밋 불가한 레포 밖 편의 보정 — 한계 명시)**

배포본 경로는 scaffold와 같은 홈 해석 규칙으로 도출한다(`CLAUDE_CONFIG_DIR` 설정 시 그 아래, 아니면 Claude Code 실제 홈의 `disciplined-coder/solved_problems.md` — 이 머신에서는 `C:/Users/CHSHIN/.claude/disciplined-coder/solved_problems.md`). 이 편집은 **어떤 커밋에도 남지 않는 이 머신 1회 보정**이며(scaffold는 기존 solved를 재작성하지 않으므로 구조적 전파 경로가 없다), 다른 설치의 동일 드리프트는 교정하지 않는다는 한계를 받아들인다. 파일이 없으면 건너뛴다. 헤더 두 곳만 고친다(항목 불릿은 불변):
- "각 항목: 문제 → 원인 → 해결" → "각 항목: 증상/트리거 → 교훈(다음엔 이렇게 — 처방이 앞)"
- "디시플린(coding-principles.md)으로 승격하고 여기서는 제거(SSOT)" → "디시플린(agent-principles.md)으로 **재기술해 승격**한다(원문은 append-only로 보존)" — 폐기 파일명 참조 제거 + '제거' 문구가 append-only와 모순되던 것도 함께 정합화.

- [ ] **Step 4: 검증한다**

Run: `grep -rn "coding-principles" scripts/ "$HOME/.claude/disciplined-coder/solved_problems.md" 2>/dev/null; bash scripts/test_scaffold.sh 2>&1 | tail -2`
Expected: coding-principles 참조는 STALE 상수(_scaffold_common.sh — 의도적 제거 대상 명단)에만 남고, 테스트 FAIL=0. (`$HOME`이 네트워크 홈이면 배포본 경로는 `C:/Users/CHSHIN/...`로 직접 확인한다.)

- [ ] **Step 5: 커밋한다**

```bash
git add scripts/add-pointer.sh docs/solved_problems.md
git commit -m "fix(ssot): 오답노트 항목 형식을 §다 정본 형식으로 단일화한다

세 곳(§다·PC 템플릿·프로젝트 템플릿)에서 세 가지로 갈라졌던 항목 형식을
'증상/트리거 → 교훈(처방이 앞)'으로 정렬한다. 배포된 PC solved 헤더의
폐기 파일명(coding-principles.md) 참조도 1회 보정했다(레포 밖 파일).

Co-Authored-By: Claude Fable 5 <noreply@anthropic.com>
Claude-Session: https://claude.ai/code/session_01GHD9UvKFd3nLLTiryd1m77"
```

---

### Task 6: README 드리프트 일괄 수정 + 재드리프트 가드

배경(발견 2·3·4·5·11번): 생성 파일 목록 2곳 모두 issue-mode 누락, 커맨드 목록 2곳이 실제 commands/ 5개와 각각 다르게 어긋남, "mac/Linux는 기본 sh로 동작" 오서술, 게이트 해제 마커에서 escalated 누락(README와 ptu 지시문), Highlights의 CLEAR-COMM '짧게' 오요약. 열거는 한 곳으로 줄이고 나머지는 도출 참조로 바꾸며, 커맨드 목록↔디렉터리 일치는 테스트로 가드한다.

**Files:**
- Modify: `README.md`, `hooks/spec_review_posttooluse.sh`(지시문), `scripts/test_scaffold.sh`(가드)

- [ ] **Step 1: README 문구 5곳을 고친다**

(a) 31행 sh/bash — 교체 전: `mac/Linux는 기본 \`sh\`로 동작하므로 별도 설치 불필요.` → 교체 후: `mac/Linux는 bash가 기본 탑재라 별도 설치 불필요(훅은 sh가 아니라 bash를 호출한다).`

(b) 25행 마커 — 교체 전: `문서 마지막 줄 \`<!-- spec-review: passed … -->\` 마커로 해제` → 교체 후: `문서 마지막 줄 \`<!-- spec-review: passed -->\` 또는 \`escalated\` 마커로 해제`

(c) 12행 Highlights — 교체 전: `답변 표현(명확·짧게·리듬)은 \`CLEAR-COMM\`이 상시 잡고` → 교체 후: `답변 표현(명확·저피로·리듬 — 짧은 답보다 피로도 낮은 답)은 \`CLEAR-COMM\`이 상시 잡고`

(d) 54행 생성 파일 — 교체 전: `- \`~/.claude/disciplined-coder/\`에 \`agent-principles.md\`·\`domains-index.md\`·\`solved_problems.md\` 셋업` → 교체 후: `- \`~/.claude/disciplined-coder/\`에 정본 사본과 오답노트·설정 파일 셋업(정확한 목록은 scaffold 공통 헬퍼의 \`SCAFFOLD_WHITELIST\`가 정본이다)`

(e) 93행 blockquote — 교체 전: `> \`~/.claude/disciplined-coder/\`에 생성되는 파일: \`agent-principles.md\`, \`domains-index.md\`, \`solved_problems.md\`. 스킬은 플러그인에서 온디맨드 로드 — 복사하지 않는다.` → 교체 후: `> \`~/.claude/disciplined-coder/\`에 생성되는 파일 목록은 scaffold 공통 헬퍼의 \`SCAFFOLD_WHITELIST\`가 정본이다. 스킬은 플러그인에서 온디맨드 로드 — 복사하지 않는다.` (파일 경로가 아니라 심볼 이름으로 가리킨다 — 파일이 rename돼도 grep으로 닿는 개념 참조.)

- [ ] **Step 2: 커맨드 목록을 한 곳으로 만든다**

(a) 62-66행 커맨드 절 코드 블록에 누락된 /add-pointer를 추가한다:

```text
/add-pointer         # 이 프로젝트에 오답노트(docs/solved_problems.md) + CLAUDE.md 포인터 추가(옵트인)
```

(b) 89행 구성 트리 주석 — 교체 전: `├── commands/*.md                  # /setup-discipline · /show-principles · /show-solved · /add-pointer` → 교체 후: `├── commands/*.md                  # 수동 커맨드(전체 목록은 '사용 > 커맨드' 절이 정본)`

- [ ] **Step 3: ptu 지시문에 escalated를 병기한다**

`hooks/spec_review_posttooluse.sh` 23행 msg의 `spec-review passed 마커(HTML 주석)` → `spec-review 마커(passed 또는 escalated, HTML 주석)`.

- [ ] **Step 4: README 커맨드 절 ↔ commands/ 디렉터리 일치 가드를 테스트에 추가한다**

`scripts/test_scaffold.sh`의 케이스 12 뒤(마지막 echo 앞)에 추가한다:

```bash
# --- 케이스 13: README 커맨드 절 ↔ commands/ 디렉터리 드리프트 가드 (SSOT — 열거는 사용 절 한 곳) ---
# 파일 전체가 아니라 '### 커맨드' 절만 검사한다 — /add-pointer 등이 다른 문단에 등장해
# 목록 누락이 vacuous 통과하는 것을 막는다.
CMD_SECTION="$(awk '/^### 커맨드/{f=1} f&&/^## /{exit} f' "$HERE/README.md")"
echo "[case13] README commands section covers commands/ dir"
for c in "$HERE"/commands/*.md; do
  n="/$(basename "$c" .md)"
  check "README commands section lists $n" "printf '%s' \"\$CMD_SECTION\" | grep -qF -- '$n'"
done
```

- [ ] **Step 5: 검증한다**

Run: `bash scripts/test_scaffold.sh 2>&1 | tail -2 && bash scripts/test_hooks.sh 2>&1 | tail -2`
Expected: 둘 다 FAIL=0 (케이스 13 포함 — 커맨드 5종 전부 README에 존재).

- [ ] **Step 6: 커밋한다**

```bash
git add README.md hooks/spec_review_posttooluse.sh scripts/test_scaffold.sh
git commit -m "fix(docs): README 드리프트 5건을 도출 참조로 바꾸고 커맨드 목록을 가드한다

생성 파일·커맨드 열거를 한 곳(또는 코드 정본 참조)으로 줄여 손 동기화를
없애고, sh/bash·escalated 마커·CLEAR-COMM 요약 오서술을 고친다. 커맨드
목록↔디렉터리 일치는 케이스 13이 계약으로 가드한다.

Co-Authored-By: Claude Fable 5 <noreply@anthropic.com>
Claude-Session: https://claude.ai/code/session_01GHD9UvKFd3nLLTiryd1m77"
```

---

### Task 7: show-* 커맨드의 홈 하드코딩을 해석 규칙과 정합화한다

배경(발견 6번): `/show-principles`·`/show-solved`가 `~/.claude`를 하드코딩하지만, scaffold는 `_resolve_home.sh` 규칙(CLAUDE_CONFIG_DIR 우선)으로 다른 곳에 쓸 수 있어 드물게 서로 다른 파일을 가리킨다. 커맨드는 프롬프트 문서이므로 해석 규칙을 문구로 반영한다.

**Files:**
- Modify: `commands/show-principles.md`, `commands/show-solved.md`

- [ ] **Step 1: 두 커맨드의 경로 안내를 보정한다**

두 파일 모두에서 본문 첫 문장을 교체한다. show-principles 교체 후:

```
`~/.claude/disciplined-coder/agent-principles.md` 파일을 Read해서 내용을 그대로 보여줘라
(홈 위치는 scaffold와 같은 해석 규칙 — `scripts/_resolve_home.sh` — 을 따른다).
```

show-solved도 같은 방식으로(`solved_problems.md` 경로에 동일 괄호 문구). 규칙 세부를 재기술하지 않고 참조만 둔다 — 병기하면 그 문구가 또 하나의 손 동기화 지점이 된다.

- [ ] **Step 2: 커밋한다**

```bash
git add commands/show-principles.md commands/show-solved.md
git commit -m "fix(commands): show-* 경로 안내를 scaffold 홈 해석 규칙과 정합화한다

CLAUDE_CONFIG_DIR 우선 규칙(_resolve_home.sh)이 있는데 커맨드만 ~/.claude를
단정하던 이원화를 문구로 닫는다.

Co-Authored-By: Claude Fable 5 <noreply@anthropic.com>
Claude-Session: https://claude.ai/code/session_01GHD9UvKFd3nLLTiryd1m77"
```

---

### Task 8: 전체 검증과 push

- [ ] **Step 1: 전체 검증을 돌린다**

Run: `bash scripts/test_scaffold.sh && bash scripts/test_hooks.sh && bash scripts/test_codex_scaffold.sh && claude plugin validate ./`
Expected: 세 테스트 FAIL=0, validate 경고 0건 통과.

- [ ] **Step 2: push하고 CI를 관찰한다**

Run: `git push && gh run watch --exit-status`
Expected: 두 job 모두 성공.

---

## 범위 밖 (후속)

- CLEAR-COMM 문체 위반(major 4 + minor 다수) — 계획 없이 파일 단위 직접 수정으로 진행한다(각 수정은 문서 훅의 검진 넛지를 받는다).
- hooks.json ↔ hooks-codex.json 훅 배선 이중 기술(발견 20번 minor) — 두 런타임이 각자 매니페스트를 요구하는 플랫폼 제약이라 지금은 수용하고, 집합 일치 가드는 통증이 재발하면 추가한다(YAGNI).
- domain-docs '이 책' 참조·2인칭 잔재, domain-plugin TODO 목록·--strict 오서술 등 스킬 문서 수정 — 문체 패스와 함께 처리한다.
- §가 트리거 표 행 추가 + ultracode 검증 토글 — brainstorming → spec 경로로 별도 진행.

<!-- spec-review: passed -->
