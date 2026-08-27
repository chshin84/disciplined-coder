#!/usr/bin/env bash
# Idempotent. SessionStart마다 실행. 지식을 PC(~/.claude/disciplined-coder)에 두고
# ~/.claude/CLAUDE.md 관리블록이 @import. 프로젝트 폴더에 파일을 새로 만들지는 않는다 —
# 이미 있는 오답노트의 머리말과 없앤 기능이 남긴 관리블록만 손본다(둘 다 사본을 남기거나 되돌릴 수 있다).
set -euo pipefail

PLUGIN_ROOT="${CLAUDE_PLUGIN_ROOT:-$(cd "$(dirname "$0")/.." && pwd)}"

# Claude 설정 홈 해석 — 공유 헬퍼(SSOT). 도메인 PC의 네트워크 홈 리다이렉트로 bash $HOME이
# os.homedir(USERPROFILE)과 어긋나면 조용한 누락(@import·solved)이 나므로 우선순위 해석을
# _resolve_home.sh 한 곳에 두고 codex-scaffold.sh와 공유한다.
. "$(dirname "$0")/_resolve_home.sh"
. "$(dirname "$0")/_scaffold_common.sh"
. "$(dirname "$0")/_ensure_autoupdate.sh"
CLAUDE_HOME="$(resolve_home claude)"
KDIR="$CLAUDE_HOME/disciplined-coder"
UC="$CLAUDE_HOME/CLAUDE.md"

mkdir -p "$KDIR"
created=""

# 1) 정본(static) 복사·갱신: principles, domains-index. src==dst면 생략.
for f in agent-principles.md domains-index.md; do
  src="$PLUGIN_ROOT/$f"; dst="$KDIR/$f"
  if [ -f "$src" ]; then
    # 복사가 실패하면 조용히 넘어가지 않는다. 이미 옛 사본이 놓여 있는 PC에서는 파일도 있고
    # @import 배선도 남아 있어 README가 알려 준 확인 셋을 그대로 통과하므로, 정본만 낡은 채
    # 아무도 모르게 된다(FAIL-LOUD).
    if [ "$src" = "$dst" ] || { [ -e "$dst" ] && [ "$src" -ef "$dst" ]; }; then :; else
      cp "$src" "$dst" || { echo "[disciplined-coder] ERROR: 정본 복사 실패 — $src → $dst (이전 사본이 있으면 그것이 그대로 쓰인다)" >&2; exit 1; }
    fi
  else
    echo "[disciplined-coder] WARNING: source not found at $src" >&2
  fi
done

# 1b) 관리 디렉터리 위생(멱등): 정책 정본은 _scaffold_common.sh(SCAFFOLD_WHITELIST·STALE).
#     비화이트리스트는 사용자 데이터일 수 있어 — 비었으면 제거, 내용 있으면 surface(FAIL-LOUD).
scaffold_hygiene "$KDIR"

# 2) solved 누적 파일(append-only 오답노트): 없을 때만 생성 — 템플릿 정본은 _scaffold_common.sh.
#    (이슈·백로그 트래킹은 안 한다 — 범위 밖.)
if scaffold_ensure_solved "$KDIR"; then created="$created solved_problems.md"; fi

# 2b) 오답노트 머리말 동기화: 형식 규칙이 낡았으면 사본을 뜨고 정본 머리말로 갈아끼운다.
#     항목은 한 줄도 건드리지 않고, 머리말의 끝을 알아볼 수 없는 로그는 손대지 않는다(방법 정본은
#     domain-docs 스킬). 오답노트는 플러그인이 형식을 정하는 파일이라 사람 승인 없이 맞춘다.
scaffold_sync_solved "$KDIR/solved_problems.md" pc "$KDIR/backups" pc
pc_note="$solved_sync_note"
# 2b-1) 색인과 본문의 짝, 그리고 아직 안 쪼개진 로그의 개편 권유. 둘 다 읽고 알리기만 한다.
scaffold_check_solved_pairing "$KDIR/solved_problems.md"
pc_pairing="$solved_pairing_note"
scaffold_check_solved_unsplit "$KDIR/solved_problems.md" "$PLUGIN_ROOT" "$KDIR/backups" pc
pc_unsplit="$solved_unsplit_note"

# 2c) 세션을 연 프로젝트의 오답노트도 같은 처리를 받는다. 프로젝트마다 형식이 갈리면 recall이
#     읽는 모양이 제각각이 되기 때문이다. 사본은 프로젝트가 아니라 전역 백업에 쌓는다 —
#     이 플러그인은 프로젝트 폴더에 파일을 남기지 않는다.
PROJ="${CLAUDE_PROJECT_DIR:-$PWD}"
PLOG="$PROJ/docs/solved_problems.md"
proj_note=""; proj_pairing=""; proj_unsplit=""
if [ -f "$PLOG" ] && [ "$PLOG" != "$KDIR/solved_problems.md" ]; then
  plabel="$(printf '%s' "$(basename "$PROJ")" | tr -c 'A-Za-z0-9._-' '_')"
  scaffold_sync_solved "$PLOG" project "$KDIR/backups" "$plabel"
  proj_note="$solved_sync_note"
  scaffold_check_solved_pairing "$PLOG"
  proj_pairing="$solved_pairing_note"
  scaffold_check_solved_unsplit "$PLOG" "$PLUGIN_ROOT" "$KDIR/backups" "$plabel"
  proj_unsplit="$solved_unsplit_note"
fi

# 3) ~/.claude/CLAUDE.md 관리블록 재생성(멱등, CRLF 내성). 상대 @import(= ~/.claude 기준).
. "$(dirname "$0")/_managed_block.sh"

# 3a) 없앤 기능(/add-pointer)이 프로젝트 CLAUDE.md에 심어 두던 옛 관리블록을 걷어낸다. 지금은
#     아무것도 그 블록을 다시 만들지 않으므로 남아 있으면 갱신되지 않는 고아다. 마커가 같으니
#     전역 CLAUDE.md와 같은 파일이면 건너뛴다 — 그건 이 훅이 매 세션 다시 만드는 정상 블록이다.
#     걷어내기 전에 사본을 뜬다 — 블록 안에 사람이 끼워 넣은 줄이 있으면 그것이 유일한 복구
#     수단이고, 이 파일은 git 밖일 수 있다. 사본은 프로젝트가 아니라 전역 백업에 쌓는다.
pointer_note=""
PCLAUDE="$PROJ/CLAUDE.md"
if [ -f "$PCLAUDE" ] && [ "$PCLAUDE" != "$UC" ]; then
  pblabel="$(printf '%s' "$(basename "$PROJ")" | tr -c 'A-Za-z0-9._-' '_')"
  pbstamp="$(date +%Y%m%d-%H%M%S 2>/dev/null || echo unknown)"
  prc=0
  managed_block_remove "$PCLAUDE" "$MANAGED_BEGIN" "$MANAGED_END" \
    "$KDIR/backups/CLAUDE.md.$pblabel.$pbstamp.bak" || prc=$?
  if [ "$prc" -eq 0 ]; then
    pointer_note="🔵 disciplined-coder: $PCLAUDE 에 남아 있던 옛 관리블록을 걷어냈다(사용자가 쓴 줄은 그대로 두었다. 사본: $managed_block_backup)."
  elif [ "$prc" -eq 2 ]; then
    pointer_note="🔵 disciplined-coder: $PCLAUDE 에 옛 관리블록이 남아 있는데 사본을 뜨지 못해 그대로 두었다($KDIR/backups 에 쓸 수 있게 되면 다음 세션에 다시 시도한다)."
  fi
fi

# 마커는 _managed_block.sh의 MANAGED_BEGIN/END(SSOT)를 쓴다.
# 스킬(domain-*/reviewer-*)은 플러그인에서 온디맨드 — 복사/주입 안 함.
# 첫 설치 판정은 반드시 주입 '전에' 한다 — 주입 후엔 항상 존재해 판정이 무의미해진다.
# -x(줄 전체 일치)를 쓰지 않는 이유: CRLF 파일에서 줄 끝 CR 때문에 영원히 거짓이 되어
# 이중 주입이 조용히 되살아난다(이 레포는 CRLF를 실재 문제로 이미 다룬다).
had_import=0
if [ -f "$UC" ] && grep -qF '@disciplined-coder/agent-principles.md' "$UC"; then had_import=1; fi
managed_block_inject "$UC" "$MANAGED_BEGIN" "$MANAGED_END" <<'EOF'
@disciplined-coder/agent-principles.md
@disciplined-coder/domains-index.md
@disciplined-coder/solved_problems.md
EOF

# 4) 첫 세션 도달 보강: CLAUDE.md는 이 훅보다 먼저 로드되므로, 블록을 방금 만든 세션은
#    @import만으로 정본에 닿지 못한다. 그 세션에만 stdout(additionalContext)으로 보강한다.
#    이후 세션은 @import 한 경로로만 로드한다 — 같은 내용을 두 번 싣지 않는다.
if [ "$had_import" -eq 0 ]; then
  for f in agent-principles.md domains-index.md solved_problems.md; do
    [ -f "$KDIR/$f" ] || continue
    # 읽기가 거부돼도 훅 전체를 죽이지 않는다. set -e 아래에서 cat 실패는 스캐폴드를 그 자리에서
    # 끝내 @import 배선까지 못 하게 만든다. 대신 못 읽었다는 사실을 stderr로 드러낸다(FAIL-LOUD).
    if ! cat "$KDIR/$f" 2>/dev/null; then
      echo "[disciplined-coder] WARNING: cannot read $KDIR/$f — 이 세션의 stdout 보강에서 빠진다" >&2
    fi
  done
fi
# 무엇을 했는지 알린다. 파일을 고쳤으면 조용히 넘기지 않는다 — 사용자가 열어 둔 레포가 바뀌었을 수
# 있고, 그 사실은 사본 경로와 함께 눈에 보여야 한다(FAIL-LOUD).
for note in "$pc_note" "$pc_pairing" "$pc_unsplit" "$proj_note" "$proj_pairing" "$proj_unsplit" "$pointer_note"; do
  if [ -n "$note" ]; then printf '%s\n' "$note"; fi
done

# 4b) 마켓플레이스 자동 갱신(멱등): 사용자가 손으로 켜지 않아도 깃허브의 갱신이 따라오게 한다.
#     규칙과 안전장치는 _ensure_autoupdate.sh가 소유한다 — 우리 항목만, 키가 없을 때만, 사본을 남기고.
autoupdated="$(ensure_marketplace_autoupdate "$CLAUDE_HOME" "$PLUGIN_ROOT" || true)"
if [ -n "$autoupdated" ]; then
  echo "[disciplined-coder] 플러그인 자동 갱신을 켰습니다. 고친 파일과 그 사본(.bak):" >&2
  printf '%s
' "$autoupdated" | while IFS= read -r changed; do
    [ -n "$changed" ] && echo "  $changed (사본: $changed.bak)" >&2
  done
fi

# 5) 보고
if [ -n "$created" ]; then echo "[disciplined-coder] PC knowledge initialized:$created (at $KDIR)" >&2; fi
exit 0
