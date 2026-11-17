#!/usr/bin/env bash
# 공유: 재현 시험 진입점(eval_replay.sh)의 환경 확인. 생성 임시 폴더의 상위 경로에 CLAUDE.md 가 있는지 찾는
# ancestor_claude 만 둔다. 옛 조항별 시험이 쓰던 인증 키 읽기·설정 지문·임시 폴더 함수는 소비자가 없어 2026-11-17 삭제했다
# (재현 시험은 API 키 대신 로그인 토큰을 쓰고, 임시 폴더는 _replay.py 가 만든다).

# $1 의 상위 경로(자신 포함)에서 가장 가까운 CLAUDE.md 나 .claude/CLAUDE.md 의 경로를 낸다. 없으면 아무것도 내지 않는다.
# Claude Code 는 작업 폴더에서 위로 올라가며 이 파일들을 싣는다. 2026-10-18 측정에서 사용자 홈 아래 /tmp 의
# 세션에는 ~/.claude/CLAUDE.md 가 실렸다(2026-11-17 삭제한 evals/principles/README.md 「실행 도구」, 태그 archive/v1-final).
ancestor_claude() {
  local d="$1"
  while :; do
    [ -f "$d/CLAUDE.md" ] && { printf '%s\n' "$d/CLAUDE.md"; return 0; }
    [ -f "$d/.claude/CLAUDE.md" ] && { printf '%s\n' "$d/.claude/CLAUDE.md"; return 0; }
    [ "$d" = "/" ] || [ "$d" = "$(dirname "$d")" ] && return 0
    d="$(dirname "$d")"
  done
}
