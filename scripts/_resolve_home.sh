#!/usr/bin/env bash
# 공유: 런타임 설정 홈을 우선순위대로 해석해 stdout으로 반환(SSOT).
# scaffold.sh·issue-mode.sh(Claude)·codex-scaffold.sh(Codex)가 같은 규칙을 쓰도록 단일화한다.
# 도메인 PC는 네트워크 홈 리다이렉트(HOMEDRIVE=U:)로 bash $HOME이 os.homedir(USERPROFILE)과
# 어긋날 수 있어, 잘못된 곳에 쓰면 @import·solved·모드가 조용히 누락된다(FAIL-LOUD 위반).
# Usage: HOME_DIR="$(resolve_home claude)"   # ~/.claude
#        HOME_DIR="$(resolve_home codex)"    # ~/.codex
# 우선순위(claude): CLAUDE_HOME_DIR(테스트) → CLAUDE_CONFIG_DIR(Claude Code 오버라이드) →
#                   USERPROFILE/.claude(Windows=os.homedir) → $HOME/.claude(mac·Linux 폴백)
# 우선순위(codex):  CODEX_HOME_DIR(테스트) → CODEX_HOME(Codex CLI env) →
#                   USERPROFILE/.codex → $HOME/.codex
# USERPROFILE 기준 홈이 bash $HOME과 다르면 stderr로 note 1회(홈 드리프트 가시화).
resolve_home() {
  local rt="$1" sub dir_env cfg_env val
  case "$rt" in
    claude) sub=".claude"; dir_env="${CLAUDE_HOME_DIR:-}"; cfg_env="${CLAUDE_CONFIG_DIR:-}" ;;
    codex)  sub=".codex";  dir_env="${CODEX_HOME_DIR:-}";  cfg_env="${CODEX_HOME:-}" ;;
    *) echo "[disciplined-coder] resolve_home: 알 수 없는 런타임 '$rt'" >&2; return 2 ;;
  esac
  if [ -n "$dir_env" ]; then
    printf '%s\n' "$dir_env"
  elif [ -n "$cfg_env" ]; then
    printf '%s\n' "$cfg_env"
  elif [ -n "${USERPROFILE:-}" ]; then
    val="$(cygpath -u "$USERPROFILE" 2>/dev/null || printf '%s' "$USERPROFILE")/$sub"
    if [ "$val" != "${HOME:-}/$sub" ]; then
      echo "[disciplined-coder] note: 설정 홈을 USERPROFILE 기준 $val 로 잡음 (bash \$HOME=${HOME:-} 와 다름)" >&2
    fi
    printf '%s\n' "$val"
  else
    printf '%s\n' "${HOME:-}/$sub"
  fi
}
