#!/usr/bin/env bash
# PreToolUse(Bash): 윈도우에서 python3 이 마이크로소프트 스토어 안내판으로 풀릴 때만 그 명령을 거부한다.
# 안내판(AppInstallerPythonRedirector)은 `Python` 이라는 낱말만 찍고 종료 코드 49 로 끝난다. 출력이
# 있어 돌아간 것처럼 보이므로 heredoc 스크립트가 통째로 안 돌아도 눈에 안 띈다. 세션 시작 점검으로는
# 이것을 못 잡는다 — 환경이 갖춰졌는지가 아니라 부르는 순간의 문제라 그 명령을 세울 곳이 여기다.
#
# 세 곳에서 좁힌다. 윈도우가 아니면 python3 이 정상 이름이라 바로 통과시키고, 이름만 보고 막지 않고
# 실제로 풀리는 실행 파일이 WindowsApps 아래인지 확인하며, 따옴표 안 문자열과 python312 같은 이름은
# 안 잡는다. 그래서 끄는 스위치를 두지 않는다 — 정당한 python3 은 애초에 안 막힌다.
set -euo pipefail
DIR="$(cd "$(dirname "$0")" && pwd)"
. "$DIR/_json_escape.sh"   # JSON 문자열 이스케이프 공유(SSOT)
INPUT="$(cat)"

# python3 이 무엇으로 풀리는지 낸다. 테스트는 DISCIPLINED_CODER_PYTHON3_STATE 로 결과를 주입해
# OS 와 PATH 를 안 본다 — 그것이 없으면 CI(ubuntu)와 윈도우 PC 에서 결과가 갈린다.
python3_target() {
  if [ -n "${DISCIPLINED_CODER_PYTHON3_STATE:-}" ]; then printf '%s' "$DISCIPLINED_CODER_PYTHON3_STATE"; return 0; fi
  case "$(uname -s 2>/dev/null || echo unknown)" in
    MINGW*|MSYS*|CYGWIN*) ;;
    *) printf 'not-windows'; return 0 ;;
  esac
  command -v python3 2>/dev/null || printf 'none'
}

TARGET="$(python3_target)"
case "$TARGET" in
  *WindowsApps*) ;;
  *) exit 0 ;;              # 맥·리눅스이거나, 안 풀리거나, 실제 파이썬으로 풀린다 — 훅의 일이 아니다
esac

CMD="$(printf '%s' "$INPUT" | bash "$DIR/_extract_command.sh")"
[ -n "$CMD" ] || exit 0

# 명령어로 놓인 python3 만 잡는다. 따옴표 안을 공백으로 지우고 셸 구분자로 갈라, 각 조각의 첫 낱말이
# python3 인지 본다. 앞의 VAR=값 은 걷어낸다. 뒤에 글자나 숫자나 점이 붙으면(python312·python3.12)
# 다른 이름이라 안 잡는다.
HIT="$(printf '%s' "$CMD" | awk '
BEGIN { SQ = sprintf("%c", 39); DQ = sprintf("%c", 34); BS = sprintf("%c", 92) }
{ buf = buf $0 "\n" }
END {
  n = length(buf); q = ""; out = ""
  for (i = 1; i <= n; i++) {
    c = substr(buf, i, 1)
    if (q == SQ) { if (c == SQ) q = ""; else out = out " "; continue }
    if (q == DQ) {
      if (c == BS) { i++; out = out " "; continue }
      if (c == DQ) { q = ""; continue }
      out = out " "; continue
    }
    if (c == SQ || c == DQ) { q = c; continue }
    if (c == BS) { i++; out = out " "; continue }
    out = out c
  }
  gsub(/[|&;()`\n]/, "\n", out)
  m = split(out, seg, "\n")
  for (j = 1; j <= m; j++) {
    s = seg[j]
    sub(/^[ \t]+/, "", s)
    while (s ~ /^[A-Za-z_][A-Za-z0-9_]*=[^ \t]*[ \t]+/) sub(/^[A-Za-z_][A-Za-z0-9_]*=[^ \t]*[ \t]+/, "", s)
    if (s ~ /^python3([^A-Za-z0-9._-]|$)/) { print "hit"; exit }
  }
}
')"
[ -n "$HIT" ] || exit 0

reason="이 PC 에서 python3 은 파이썬이 아니다. 마이크로소프트 스토어로 보내는 안내판이라 'Python' 이라는 낱말만 찍고 종료 코드 49 로 끝나므로, 스크립트가 통째로 안 돌아도 성공처럼 보인다. python 이나 py -3 으로 부르라. python3 이 풀리는 곳: $TARGET"
esc="$(escape_for_json "$reason")"
printf '{"hookSpecificOutput":{"hookEventName":"PreToolUse","permissionDecision":"deny","permissionDecisionReason":"%s"}}\n' "$esc"
exit 0
