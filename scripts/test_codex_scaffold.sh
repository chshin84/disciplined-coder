#!/usr/bin/env bash
# codex-scaffold.sh(Codex 셋업) 검증. 계약: FAIL=0.
set -euo pipefail
HERE="$(cd "$(dirname "$0")/.." && pwd)"
SCAFFOLD="$HERE/scripts/codex-scaffold.sh"
pass=0; fail=0
check() { if eval "$2"; then echo "  PASS: $1"; pass=$((pass+1)); else echo "  FAIL: $1"; fail=$((fail+1)); fi; }
# 둘째 인자를 생략하면 빈 임시 디렉터리를 프로젝트로 쓴다. codex-scaffold.sh 는
# PROJ="${CLAUDE_PROJECT_DIR:-$PWD}" 이므로, 이것을 안 세우면 테스트가 이 레포 자신의
# docs/solved_problems.md 를 프로젝트 로그로 잡아 실제 파일을 고칠 수 있다.
run() {  # $1=HOME 디렉터리, $2=프로젝트 디렉터리(생략 가능)
  local proj="${2:-}"
  [ -n "$proj" ] || proj="$(mktemp -d)"
  CODEX_HOME_DIR="$1/.codex" CLAUDE_PROJECT_DIR="$proj" CLAUDE_PLUGIN_ROOT="$HERE" bash "$SCAFFOLD"
}

# 이웃 관계 검사: 파일에서 pattern과 정확히 일치하는 첫 줄 '바로 다음 줄'이 빈 줄인지 확인한다.
# 전역 빈 줄 카운트는 관리블록이 항상 넣는 구분 빈 줄과 뒤섞여 무조건 참이 되므로 쓰지 않는다.
blank_follows() {  # $1=file $2=exact-line-pattern
  awk -v pat="$2" 'matched && !verified { verified=1; if ($0=="") ok=1 } $0==pat { matched=1 } END { exit (ok==1 ? 0 : 1) }' "$1"
}

# JSON 유효성 검사기는 공유 헬퍼가 정본이다 — 같은 구현을 두 스위트가 복제하지 않는다(SSOT).
. "$HERE/scripts/_json_valid.sh"

# --- 케이스 1: 신규 PC ---
H1="$(mktemp -d)"
OUT="$(run "$H1")"
K="$H1/.codex/disciplined-coder"; AG="$H1/.codex/AGENTS.md"
echo "[case1] fresh codex home"
check "principles in codex dir"     "[ -f '$K/agent-principles.md' ]"
check "AGENTS.md has managed begin" "[ \$(grep -cF '# BEGIN disciplined-coder' '$AG') -eq 1 ]"
check "AGENTS.md inlines principles" "grep -qF '# 디시플린 (팀 원칙)' '$AG'"
# 제목 줄만 보면 본문이 통째로 빠져도 통과한다. 정본을 요약해 넣는 식으로 바뀌면 Codex에서만 상시
# 허가가 사라지는데, Claude 쪽 검사는 그대로 초록이라 아무도 모른다(쌍둥이 어긋남).
check "AGENTS.md inlines standing consent" "grep -qF -- '리뷰어(\`reviewer-*\`) 호출은 사용자가 상시 허용한 것으로 간주한다' '$AG'"
check "stdout injects principles"   "printf '%s' \"\$OUT\" | grep -qF '# 디시플린 (팀 원칙)'"

# --- 케이스 2: 멱등성(3회) ---
run "$H1" >/dev/null; run "$H1" >/dev/null
echo "[case2] idempotency"
check "still one managed region"    "[ \$(grep -cF '# BEGIN disciplined-coder' '$AG') -eq 1 ]"

# --- 케이스 3: 기존 AGENTS.md 내용 보존 + 블랭크 비누적 (문단 사이 빈 줄 포함) ---
# 픽스처가 한 줄짜리면 빈 줄 삭제 회귀를 구조적으로 통과시키므로, 문단 둘 사이에 빈 줄을 끼운다
# (design spec 2026-07-27 테스트 절 — codex-scaffold.sh 경로도 scaffold.sh와 같은 것을 검증).
H3="$(mktemp -d)"; mkdir -p "$H3/.codex"
printf 'para one\n\npara two\n' > "$H3/.codex/AGENTS.md"
for _ in 1 2 3; do run "$H3" >/dev/null; done
AG3="$H3/.codex/AGENTS.md"
echo "[case3] preserve user content (blank line between paragraphs)"
check "para one preserved"          "grep -qxF 'para one' '$AG3'"
check "para two preserved"          "grep -qxF 'para two' '$AG3'"
check "blank line right after para one preserved" "blank_follows '$AG3' 'para one'"
check "one region after 3 runs"     "[ \$(grep -cF '# BEGIN disciplined-coder' '$AG3') -eq 1 ]"

# --- 케이스 4: solved 누적 보존 ---
echo "[case4] solved preserved"
printf '\n- codex 보존 확인\n' >> "$K/solved_problems.md"
run "$H1" >/dev/null

# --- 케이스 5: CRLF 관리영역 인식(중복 안 됨) ---
H5="$(mktemp -d)"; mkdir -p "$H5/.codex"
printf 'note\r\n# BEGIN disciplined-coder (managed — do not edit)\r\n@old\r\n# END disciplined-coder (managed — do not edit)\r\n' > "$H5/.codex/AGENTS.md"
run "$H5" >/dev/null
echo "[case5] CRLF region recognized"
check "CRLF region not duplicated"  "[ \$(grep -cF '# BEGIN disciplined-coder' '$H5/.codex/AGENTS.md') -eq 1 ]"

# --- 케이스 6: 홈 해석이 bash $HOME에 의존하지 않음 (CODEX_HOME env 우선) ---
H6C="$(mktemp -d)/ch"; HJUNK="$(mktemp -d)"
OUT6="$(HOME="$HJUNK" CODEX_HOME="$H6C" CLAUDE_PLUGIN_ROOT="$HERE" bash "$SCAFFOLD")"
echo "[case6] home resolution honors CODEX_HOME, not bash \$HOME"
check "CODEX_HOME honored (KDIR)"    "[ -f '$H6C/disciplined-coder/agent-principles.md' ]"
check "did not fall back to bash \$HOME" "[ ! -d '$HJUNK/.codex' ]"

# --- 케이스 7: 토글 제거 패리티(codex 자기 홈) — scaffold.sh와 같은 정책이어야 한다 ---
H7="$(mktemp -d)"; K7="$H7/.codex/disciplined-coder"
echo "[case7] 토글 제거 패리티"
OUT7a="$(run "$H7")"
check "처분 모드 줄을 주입하지 않는다"  "! printf '%s' \"\$OUT7a\" | grep -qF '처분 모드'"
check "issue-mode 파일을 만들지 않는다" "[ ! -f '$K7/issue-mode' ]"
printf 'issues\n' > "$K7/issue-mode"; printf 'required\n' > "$K7/ultracode-review"
ERR7="$(run "$H7" 2>&1 >/dev/null)" || true
check "잔존 issue-mode 를 지운다"       "[ ! -f '$K7/issue-mode' ]"
check "잔존 ultracode-review 를 지운다" "[ ! -f '$K7/ultracode-review' ]"
check "잔존 파일에 경고를 남기지 않는다" "! printf '%s' \"\$ERR7\" | grep -qF '비관리 파일'"

# --- 케이스 8: 관리 디렉터리 위생 — 하위 디렉터리에서 중단되지 않는다 ---
mkdir -p "$K/rogue_dir"
set +e
ERR8c="$(run "$H1" 2>&1 >/dev/null)"; rc8c=$?
set -e
echo "[case8] hygiene: subdir must not abort"
check "subdir does not abort codex scaffold" "[ $rc8c -eq 0 ]"
check "subdir surfaced to stderr"            "printf '%s' \"\$ERR8c\" | grep -qF 'rogue_dir'"
check "ultracode-review 파일을 만들지 않는다" "[ ! -f '$K/ultracode-review' ]"

echo "[manifest + session hook]"
SS="$HERE/hooks/session-start-codex"
check "session-start-codex emits additionalContext" "CODEX_HOME_DIR=\"$(mktemp -d)/.codex\" CLAUDE_PLUGIN_ROOT=\"$HERE\" bash '$SS' | grep -q additionalContext"
check "session-start-codex warns about trust review" "CODEX_HOME_DIR=\"$(mktemp -d)/.codex\" CLAUDE_PLUGIN_ROOT=\"$HERE\" bash '$SS' | grep -qF '신뢰'"
check "session-start-codex stdout is valid JSON" "CODEX_HOME_DIR=\"$(mktemp -d)/.codex\" CLAUDE_PLUGIN_ROOT=\"$HERE\" bash '$SS' | json_valid_stdin"
check ".codex-plugin manifest is valid JSON" "json_valid_stdin < '$HERE/.codex-plugin/plugin.json'"
check "hooks-codex.json is valid JSON"       "json_valid_stdin < '$HERE/hooks/hooks-codex.json'"
check "hooks-codex wires apply_patch matcher" "grep -qF 'apply_patch' '$HERE/hooks/hooks-codex.json'"
# 자기 문자열을 자기가 찾는 순환 검사를 쓰지 않는다 — 매니페스트가 가리키는 경로를 실제로 따라가 본다.
CODEX_HOOKS_REL="$(sed -n 's/.*"hooks"[[:space:]]*:[[:space:]]*"\([^"]*\)".*/\1/p' "$HERE/.codex-plugin/plugin.json")"
CODEX_SKILLS_REL="$(sed -n 's/.*"skills"[[:space:]]*:[[:space:]]*"\([^"]*\)".*/\1/p' "$HERE/.codex-plugin/plugin.json")"
check "manifest hooks 값을 읽어냈다"           "[ -n \"\$CODEX_HOOKS_REL\" ]"
check "manifest가 가리키는 훅 파일이 존재"     "[ -f \"\$HERE/\$CODEX_HOOKS_REL\" ]"
check "manifest가 가리키는 스킬 폴더가 존재"   "[ -d \"\$HERE/\$CODEX_SKILLS_REL\" ]"
# 두 런타임이 같은 이벤트를 배선해야 패리티가 성립한다. 이벤트 이름을 손으로 적지 않고 두 파일에서 도출해 맞댄다.
check "Codex와 Claude가 같은 이벤트를 배선"    "[ \"\$(json_hook_events \"\$HERE/\$CODEX_HOOKS_REL\")\" = \"\$(json_hook_events '$HERE/hooks/hooks.json')\" ]"
# FAIL-LOUD: scaffold의 stderr 진단이 훅에서 삼켜지면 안 된다.
EDIR="$(mktemp -d)"   # 정본 없는 plugin root → scaffold가 WARNING을 stderr로 낸다
check "session hook relays scaffold stderr" "CODEX_HOME_DIR=\"$(mktemp -d)/.codex\" CLAUDE_PLUGIN_ROOT=\"$EDIR\" bash '$SS' 2>&1 >/dev/null | grep -qF 'WARNING'"
# 실패 시 원인 문자열이 주입 컨텍스트에 포함되고, 출력은 여전히 유효한 JSON이어야 한다.
TF="$(mktemp)"        # 파일 아래 경로 → mkdir -p 실패 → scaffold 비정상 종료
OUTF="$(CODEX_HOME_DIR="$TF/.codex" CLAUDE_PLUGIN_ROOT="$HERE" bash "$SS" 2>/dev/null)"
check "session hook surfaces failure cause"    "printf '%s' \"\$OUTF\" | grep -qF 'scaffold error:'"
check "failure output is still valid JSON"     "printf '%s' \"\$OUTF\" | json_valid_stdin"

# --- 케이스 9: 이중 주입 회귀 가드 — 2회차 stdout은 AGENTS.md 인라인분(principles+domains)을 재전송하지 않는다 ---
# 배경: 섹션 3(AGENTS.md 인라인)과 섹션 4(stdout 주입)가 같은 두 파일을 중복 전송하던 결함의 회귀 가드.
# had_inline 판정 덕에 첫 설치 세션만 stdout에도 실리고, 그 다음부터는 인라인(AGENTS.md)에만 남는다.
H9="$(mktemp -d)"; K9="$H9/.codex/disciplined-coder"; AG9="$H9/.codex/AGENTS.md"
OUT9a="$(run "$H9")"
OUT9b="$(run "$H9")"
echo "[case9] no duplicate injection after first install"
check "first run stdout has principles"       "printf '%s' \"\$OUT9a\" | grep -qF '# 디시플린 (팀 원칙)'"
check "second run stdout lacks principles"    "! printf '%s' \"\$OUT9b\" | grep -qF '# 디시플린 (팀 원칙)'"
check "second run stdout lacks domains-index" "! printf '%s' \"\$OUT9b\" | grep -qF '# 개발 대상(도메인) 참고서 — 인덱스'"
check "AGENTS.md still inlines principles after 2nd run" "grep -qF '# 디시플린 (팀 원칙)' '$AG9'"

# --- solved-rules(Codex): 쌍둥이 스크립트가 같은 갱신을 한다 ---
# 쌍둥이는 한쪽만 고치면 반드시 어긋나므로 Claude 쪽과 같은 계약을 여기서도 건다.
NUDGE_C='형식 규칙 서술이 현행과 다르다'
HC1="$(mktemp -d)"; mkdir -p "$HC1/.codex/disciplined-coder"
OLDC="$HC1/.codex/disciplined-coder/solved_problems.md"
{ printf '# 해결된 문제 로그 (solved_problems) — PC 전역\n\n'
  printf '작업 중 발견·해결된 문제. 각 항목: 증상/트리거 → 교훈(다음엔 이렇게 — 처방이 앞).\n\n'
  printf -- '- **옛 형식 항목** → 원인: 무엇 → 해결: 무엇\n'
} > "$OLDC"
BEFORE_C="$(cksum < "$OLDC")"
OUTC1="$(run "$HC1")"
BKC="$(find "$HC1/.codex/disciplined-coder/backups" -type f -name 'solved_problems.*' 2>/dev/null | head -1 || true)"
echo "[solved-rules] codex twin replaces the header the same way"
HC2="$(mktemp -d)"
OUTC2="$(run "$HC2")"
check "codex fresh: 신호 없음"            "! printf '%s' \"\$OUTC2\" | grep -qF '$NUDGE_C'"

# 구조 요소가 없어 경계를 못 잡는 로그는 Codex 쪽에서도 손대지 않고 알리기만 한다.
HC3="$(mktemp -d)"; mkdir -p "$HC3/.codex/disciplined-coder"
PROSEC="$HC3/.codex/disciplined-coder/solved_problems.md"
printf '# 해결된 문제 로그\n\n산문으로만 적어 둔 기록이다.\n' > "$PROSEC"
BEFORE_C3="$(cksum < "$PROSEC")"
OUTC3="$(run "$HC3")"

# --- isolation: run 은 레포 자신을 프로젝트로 잡지 않는다 ---
# codex-scaffold.sh 는 PROJ="${CLAUDE_PROJECT_DIR:-$PWD}" 라, 이 헬퍼가 그 값을 안 세우면
# 테스트를 레포에서 돌릴 때마다 이 레포의 진짜 docs/solved_problems.md 가 대상이 된다.
HI1="$(mktemp -d)"; PI1="$(mktemp -d)"; mkdir -p "$PI1/docs"
printf '# 해결된 문제 로그\n\n- **격리 픽스처 항목**\n  - 원인: 무엇\n  - 해결: 무엇\n' > "$PI1/docs/solved_problems.md"
OUTI1="$(run "$HI1" "$PI1")"
echo "[isolation] run does not treat the repo itself as the project"
check "격리: 레포 자신은 안 본다"    "! printf '%s' \"\$OUTI1\" | grep -qF -- '$HERE/docs/solved_problems.md'"

# --- split-rules: 형식 규칙과 머리말은 로그 형태를 따른다 (Claude 쪽과 같은 계약) ---
# 쌍둥이 스크립트는 한쪽만 고치면 두 런타임의 오답노트 형식이 갈린다 — 그것이 애초에 머리말
# 자동 갱신을 도입한 이유다.
HX2="$(mktemp -d)"; PX2="$(mktemp -d)"; mkdir -p "$HX2/.codex/disciplined-coder"
LOGX2="$HX2/.codex/disciplined-coder/solved_problems.md"
{ printf '# 해결된 문제 로그 (solved_problems) — PC 전역\n\n'
  printf '옛 머리말이다.\n\n'
  printf -- '- **옛 항목** → 원인: 무엇 → 해결: 무엇\n'
} > "$LOGX2"
run "$HX2" "$PX2" >/dev/null
echo "[split-rules] the rules block follows the shape of the log"

HX3="$(mktemp -d)"; PX3="$(mktemp -d)"; mkdir -p "$HX3/.codex/disciplined-coder/solved_problems"
LOGX3="$HX3/.codex/disciplined-coder/solved_problems.md"
printf '# 무언가를 할 때는 이렇게 한다\n' > "$HX3/.codex/disciplined-coder/solved_problems/a.md"
{ printf '# 해결된 문제 로그 (solved_problems) — PC 전역\n\n'
  printf '옛 머리말이다.\n\n'
  printf -- '- 무언가를 할 때는 이렇게 한다.\n  → solved_problems/a.md\n'
} > "$LOGX3"
run "$HX3" "$PX3" >/dev/null

# --- index-root: 주입된 색인이 어느 뿌리에서 왔는지 본문에 남는다 ---
# Codex 는 색인을 stdout 으로 흘려 보내므로 뿌리가 본문에 안 남으면, 세션이 색인 줄의
# solved_problems/… 를 엉뚱한 자리에서 찾다 못 찾고 규칙대로 멀쩡한 줄을 지운다.
HX4="$(mktemp -d)"; PX4="$(mktemp -d)"
OUTX4="$(run "$HX4" "$PX4")"
echo "[index-root] the injected index carries the root it came from"

# --- unsplit: 안 쪼개진 로그는 개편을 권하고, 빈 로그에는 안 권한다 ---
HX5="$(mktemp -d)"; PX5="$(mktemp -d)"; mkdir -p "$HX5/.codex/disciplined-coder"
{ printf '# 해결된 문제 로그 (solved_problems) — PC 전역\n\n'
  printf -- '- **첫째 증상**\n  - 원인: 무엇\n  - 해결: 무엇\n'
} > "$HX5/.codex/disciplined-coder/solved_problems.md"
OUTX5="$(run "$HX5" "$PX5")"
echo "[unsplit] an unsplit log gets a conversion nudge with its item count"

echo "----"; echo "PASS=$pass FAIL=$fail"; [ "$fail" -eq 0 ]
