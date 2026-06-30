#!/usr/bin/env bash
# Idempotent. Codex SessionStart마다 실행. 지식을 ~/.codex/disciplined-coder에 두고
# ~/.codex/AGENTS.md 관리블록에 정본을 인라인(Codex는 @import 미지원). 프로젝트 폴더는 안 건드린다.
# scaffold.sh(Claude)의 Codex 쌍둥이 — 정본 소스 동일(PLUGIN_ROOT의 agent-principles.md 등).
set -euo pipefail
PLUGIN_ROOT="${CLAUDE_PLUGIN_ROOT:-$(cd "$(dirname "$0")/.." && pwd)}"

# Codex 홈 해석(scaffold.sh와 동일 사유 — 도메인 PC의 네트워크 홈 리다이렉트로 bash $HOME이
# 어긋날 수 있음). 우선순위: CODEX_HOME_DIR(테스트) → CODEX_HOME(Codex CLI 자체 env) →
#           USERPROFILE/.codex(Windows) → $HOME/.codex(mac·Linux 폴백).
if [ -n "${CODEX_HOME_DIR:-}" ]; then
  CODEX_HOME="$CODEX_HOME_DIR"
elif [ -n "${CODEX_HOME:-}" ]; then
  CODEX_HOME="$CODEX_HOME"   # Codex CLI가 내보낸 값을 그대로 존중
elif [ -n "${USERPROFILE:-}" ]; then
  CODEX_HOME="$(cygpath -u "$USERPROFILE" 2>/dev/null || printf '%s' "$USERPROFILE")/.codex"
else
  CODEX_HOME="$HOME/.codex"
fi
KDIR="$CODEX_HOME/disciplined-coder"
AG="$CODEX_HOME/AGENTS.md"
mkdir -p "$KDIR"
created=""

# 1) 정본(static) 복사·갱신: principles, domains-index. src==dst면 생략.
for f in agent-principles.md domains-index.md; do
  src="$PLUGIN_ROOT/$f"; dst="$KDIR/$f"
  if [ -f "$src" ]; then
    if [ "$src" = "$dst" ] || { [ -e "$dst" ] && [ "$src" -ef "$dst" ]; }; then :; else cp "$src" "$dst"; fi
  else
    echo "[disciplined-coder] WARNING: source not found at $src" >&2
  fi
done

# 1b) 관리 디렉터리 위생(멱등) — scaffold.sh와 동일 정책(패리티). 화이트리스트=현 정본 세트,
#     구 관리파일(STALE) 안전 제거, 그 외 비화이트리스트는 비었으면 제거·내용 있으면 surface.
WHITELIST="agent-principles.md domains-index.md solved_problems.md"
STALE_MANAGED="coding-principles.md"
for s in $STALE_MANAGED; do [ -f "$KDIR/$s" ] && rm -f "$KDIR/$s" || true; done
for f in "$KDIR"/*; do
  [ -e "$f" ] || continue
  b="$(basename "$f")"
  case " $WHITELIST " in *" $b "*) continue ;; esac
  if [ -s "$f" ]; then
    echo "[disciplined-coder] note: 비관리 파일 '$b' 잔존(내용 있음 — 자동삭제 안 함, 확인 요)" >&2
  else
    rm -f "$f"
  fi
done

# 2) solved 누적 파일(append-only 오답노트): 없을 때만 생성. (이슈·백로그 트래킹은 안 한다 — 범위 밖.)
if [ ! -f "$KDIR/solved_problems.md" ]; then
  cat > "$KDIR/solved_problems.md" <<'EOF'
# 해결된 문제 로그 (solved_problems) — PC 전역 · append-only 오답노트

완결된 문제의 교훈 모음 — 차후 비슷한 작업에서 recall해 참고한다. 각 항목: 문제 → 원인 → 해결.
**완결 후 등록하는 기록이라 '상태'가 아니다** — "문서에 상태 금지"의 예외(append-only, 과거를 지우지 않는다).
일반화 가능한 항목은 디시플린(agent-principles.md)으로 승격하고 여기서는 제거(SSOT). 메인 세션만 기록.
EOF
  created="$created solved_problems.md"
fi

# 3) ~/.codex/AGENTS.md 관리블록 재생성(멱등, CRLF 내성). @import 미지원 → 정본 본문 인라인.
touch "$AG"
BEGIN_MARK="# BEGIN disciplined-coder (managed — do not edit)"
END_MARK="# END disciplined-coder (managed — do not edit)"
if grep -qF "$BEGIN_MARK" "$AG" && grep -qF "$END_MARK" "$AG"; then
  awk -v b="$BEGIN_MARK" -v e="$END_MARK" '{ l=$0; sub(/\r$/,"",l) } l==b{skip=1} skip==0{print} l==e{skip=0}' "$AG" > "$AG.tmp"
elif grep -qF "$BEGIN_MARK" "$AG"; then
  echo "[disciplined-coder] WARNING: ~/.codex/AGENTS.md has BEGIN but no END — skipping strip" >&2
  cp "$AG" "$AG.tmp"
else
  cp "$AG" "$AG.tmp"
fi
awk '{ l=$0; sub(/\r$/,"",l); if (l ~ /[^ \t]/) last=NR; line[NR]=$0 } END { for (i=1;i<=last;i++) print line[i] }' "$AG.tmp" > "$AG" && rm -f "$AG.tmp"
{
  if [ -s "$AG" ]; then printf '\n'; fi
  printf '%s\n' "$BEGIN_MARK"
  for f in agent-principles.md domains-index.md; do
    if [ -f "$KDIR/$f" ]; then cat "$KDIR/$f"; printf '\n'; fi
  done
  printf '%s\n' "$END_MARK"
} >> "$AG"

# 4) 세션 주입용 stdout: principles + domains-index + solved 본문(session-start-codex가 캡처해 additionalContext로).
#    AGENTS.md 인라인(섹션 3)은 principles+domains만(안정적). 자주 커지는 solved는 주입 경로로(spec 3.5).
for f in agent-principles.md domains-index.md solved_problems.md; do
  if [ -f "$KDIR/$f" ]; then cat "$KDIR/$f"; fi
done

# 5) 보고(진단은 stderr — stdout은 주입 본문 전용).
if [ -n "$created" ]; then echo "[disciplined-coder] Codex knowledge initialized:$created (at $KDIR)" >&2; fi
exit 0
