#!/usr/bin/env bash
# /add-pointer (kind=solved, 무인자 기본). 옵트인 — 프로젝트 폴더에 쓰는 유일한 동작.
# docs/solved_problems.md(없으면) + ./CLAUDE.md 자기완결 포인터(멱등 관리블록).
set -euo pipefail
HERE="$(cd "$(dirname "$0")" && pwd)"
PROJ="${CLAUDE_PROJECT_DIR:-$PWD}"
. "$HERE/_managed_block.sh"

LOG="$PROJ/docs/solved_problems.md"
UC="$PROJ/CLAUDE.md"
created=""

mkdir -p "$PROJ/docs"
if [ ! -f "$LOG" ]; then
  cat > "$LOG" <<'EOF'
# 해결된 문제 로그 (solved_problems) — 이 프로젝트 · append-only 오답노트

이 레포에서 완결한 문제의 교훈 — 차후 비슷한 작업에서 recall해 참고한다. 각 항목: 증상/문제 → 교훈.
**완결 후 등록하는 기록이라 '상태'가 아니다**(append-only, 과거를 지우지 않는다). 메인 세션만 append.
이 프로젝트에 한정된 교훈만 둔다 — 머신 전역은 PC solved, 보편은 디시플린 원칙으로(스코프 라우팅).
EOF
  created="$created docs/solved_problems.md"
fi

# 마커는 _managed_block.sh의 MANAGED_BEGIN/END(SSOT).
managed_block_inject "$UC" "$MANAGED_BEGIN" "$MANAGED_END" <<'EOF'
## 오답노트 (solved_problems)
디버깅·이슈 처리·중요한 결정을 시작하기 전에 `docs/solved_problems.md`를 **먼저 확인**한다 —
이 프로젝트에서 해결한 문제의 증상→교훈 기록이다. 문제를 완결하면 **메인 세션이** 거기에
append한다(서브에이전트는 직접 쓰지 말고 리턴으로 보고).
EOF

if [ -n "$created" ]; then echo "[disciplined-coder] project solved initialized:$created (+ ./CLAUDE.md 포인터)"; else echo "[disciplined-coder] ./CLAUDE.md 포인터 갱신(멱등). 로그 보존."; fi
exit 0
