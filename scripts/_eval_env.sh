#!/usr/bin/env bash
# 공유: 평가 실행 스크립트(eval_clause.sh)의 환경 준비. 인증 키 읽기, 실제 설정 지문,
# 평가 임시 폴더를 둔다.

# 인증 키를 저장소 밖 파일에서 읽어 환경 변수로만 넘긴다. 출력하거나 다른 파일에 쓰지 않는다.
eval_load_key() {
  local f="${EVAL_KEYFILE:-$HOME/.dc-eval.env}"
  ANTHROPIC_API_KEY="$(sed -n 's/^ANTHROPIC_API_KEY=//p' "$f" | tr -d '\r')"
  [ -n "$ANTHROPIC_API_KEY" ] || { echo "ERROR: $f 에 ANTHROPIC_API_KEY 가 없다." >&2; return 2; }
  export ANTHROPIC_API_KEY
}

# 실제 설정 파일의 해시 목록. $1=실제 설정 홈.
eval_fingerprint() { (cd "$1" && sha256sum CLAUDE.md disciplined-coder/*.md settings.json plugins/known_marketplaces.json plugins/installed_plugins.json 2>/dev/null) || true; }

# $1 의 상위 경로(자신 포함)에서 가장 가까운 CLAUDE.md 나 .claude/CLAUDE.md 의 경로를 낸다. 없으면 아무것도 내지 않는다.
# Claude Code 는 작업 폴더에서 위로 올라가며 이 파일들을 싣는다. 2026-10-18 측정에서 사용자 홈 아래 /tmp 의
# 세션에는 ~/.claude/CLAUDE.md 가 실렸다(evals/principles/README.md 「실행 도구」).
ancestor_claude() {
  local d="$1"
  while :; do
    [ -f "$d/CLAUDE.md" ] && { printf '%s\n' "$d/CLAUDE.md"; return 0; }
    [ -f "$d/.claude/CLAUDE.md" ] && { printf '%s\n' "$d/.claude/CLAUDE.md"; return 0; }
    [ "$d" = "/" ] || [ "$d" = "$(dirname "$d")" ] && return 0
    d="$(dirname "$d")"
  done
}

# 평가 임시 폴더를 EVAL_TMP(기본 /d/dc-eval-tmp) 아래에 만들어 경로를 낸다. 상위 경로에 CLAUDE.md 가 있으면 실패한다.
eval_tmpdir() {
  local root="${EVAL_TMP:-/d/dc-eval-tmp}" t hit
  mkdir -p "$root" || return 1
  t="$(mktemp -d "$root/run-XXXXXX")" || return 1
  hit="$(ancestor_claude "$t")"
  if [ -n "$hit" ]; then
    rm -rf "$t"
    echo "ERROR: 평가 폴더 $root 의 상위 경로에 $hit 가 있어 평가 세션에 실린다. EVAL_TMP 를 다른 곳으로 지정하라." >&2
    return 1
  fi
  printf '%s\n' "$t"
}
