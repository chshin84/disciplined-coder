#!/usr/bin/env bash
# Idempotent. Codex SessionStart마다 실행. 지식을 ~/.codex/disciplined-coder에 두고
# ~/.codex/AGENTS.md 관리블록에 정본을 인라인(Codex는 @import 미지원). 프로젝트 폴더에 파일을
# 새로 만들지는 않는다 — 무엇에 어떤 조건으로 손대는지는 README의 「프로젝트 폴더에 생기는 것」이
# 정본이다(이 쌍둥이는 그 가운데 오답노트 쪽만 맡는다. 프로젝트 CLAUDE.md는 Claude 쪽이 소유한다).
# scaffold.sh(Claude)의 Codex 쌍둥이 — 정본 소스 동일(PLUGIN_ROOT의 agent-principles.md 등).
set -euo pipefail
PLUGIN_ROOT="${CLAUDE_PLUGIN_ROOT:-$(cd "$(dirname "$0")/.." && pwd)}"

# Codex 홈 해석 — scaffold.sh와 같은 공유 헬퍼(SSOT). 런타임만 codex로(홈은 ~/.codex).
. "$(dirname "$0")/_resolve_home.sh"
. "$(dirname "$0")/_scaffold_common.sh"
CODEX_HOME="$(resolve_home codex)"
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

# 1b) 관리 디렉터리 위생(멱등) — 정책 정본은 _scaffold_common.sh(scaffold.sh와 패리티).
scaffold_hygiene "$KDIR"

# 2) solved 누적 파일(append-only 오답노트): 없을 때만 생성 — 템플릿 정본은 _scaffold_common.sh.
#    (이슈·백로그 트래킹은 안 한다 — 범위 밖.)
if scaffold_ensure_solved "$KDIR"; then created="$created solved_problems.md"; fi

# 2b) 아직 안 쪼개진 본오답노트를 먼저 쪼갠다(scaffold.sh와 동일 정책). 머리말 갱신보다 앞에
#     두는 이유는 순서 때문이다 — 뒤에 두면 그 세션의 머리말이 옛 형식으로 맞춰진다.
#     쌍둥이 스크립트는 한쪽만 고치면 반드시 어긋나므로 같이 둔다.
scaffold_migrate_solved_unsplit "$KDIR/solved_problems.md" "$PLUGIN_ROOT" "$KDIR/backups" pc
pc_unsplit="$solved_unsplit_note"
# 2b-1) 오답노트 머리말 동기화: 낡았으면 사본을 뜨고 정본 머리말로 갈아끼운다.
scaffold_sync_solved "$KDIR/solved_problems.md" pc "$KDIR/backups" pc
pc_note="$solved_sync_note"
# 2b-2) 본오답노트와 개별노트의 짝을 본다. 읽고 알리기만 한다.
scaffold_check_solved_pairing "$KDIR/solved_problems.md"
pc_pairing="$solved_pairing_note"

# 2c) 세션을 연 프로젝트의 오답노트도 같은 처리를 받는다. 사본은 프로젝트가 아니라 전역 백업에 쌓는다.
#     프로젝트 CLAUDE.md의 옛 관리블록 정리는 여기 없다 — 그것은 Claude 쪽 파일이라 그쪽이 소유한다.
PROJ="${CLAUDE_PROJECT_DIR:-$PWD}"
PLOG="$PROJ/docs/solved_problems.md"
proj_note=""; proj_pairing=""; proj_unsplit=""
if [ -f "$PLOG" ] && [ "$PLOG" != "$KDIR/solved_problems.md" ]; then
  plabel="$(printf '%s' "$(basename "$PROJ")" | tr -c 'A-Za-z0-9._-' '_')"
  scaffold_migrate_solved_unsplit "$PLOG" "$PLUGIN_ROOT" "$KDIR/backups" "$plabel"
  proj_unsplit="$solved_unsplit_note"
  scaffold_sync_solved "$PLOG" project "$KDIR/backups" "$plabel"
  proj_note="$solved_sync_note"
  scaffold_check_solved_pairing "$PLOG"
  proj_pairing="$solved_pairing_note"
fi

# 3) ~/.codex/AGENTS.md 관리블록 재생성(멱등, CRLF 내성). @import 미지원 → 정본 본문 인라인.
. "$(dirname "$0")/_managed_block.sh"
# 마커는 _managed_block.sh의 MANAGED_BEGIN/END(SSOT).
# 첫 설치 판정은 반드시 주입 '전에' 한다 — 주입 후엔 항상 존재해 판정이 무의미해진다.
# scaffold.sh의 had_import와 같은 역할이며, 판정 대상만 다르다(Claude는 @import 줄, Codex는 관리블록 마커).
had_inline=0
if [ -f "$AG" ] && grep -qF "$MANAGED_BEGIN" "$AG"; then had_inline=1; fi
# 정본을 못 읽으면 반쪽짜리 블록을 쓰지 않는다. Codex는 @import가 없어 본문을 통째로 인라인하므로,
# 읽기가 실패한 파일은 그대로 빈 자리가 된다 — 그런데 AGENTS.md에는 정상으로 보이는 관리블록이
# 놓여 있어 원칙 없이 도는 세션을 아무도 눈치채지 못한다. 그래서 먼저 모아 보고, 한 줄도 못 모았으면
# 블록을 아예 쓰지 않고 사유를 알린다(`FAIL-LOUD`. scaffold.sh의 정본 복사 실패와 같은 규율이다).
inline_body="$(
  for f in agent-principles.md domains-index.md; do
    if [ -f "$KDIR/$f" ]; then
      if ! cat "$KDIR/$f"; then
        echo "[disciplined-coder] WARNING: 정본 읽기 실패 — $KDIR/$f" >&2
      fi
      printf '\n'
    else
      echo "[disciplined-coder] WARNING: source not found at $KDIR/$f" >&2
    fi
  done
)"
if [ -z "$inline_body" ]; then
  echo "[disciplined-coder] ERROR: 정본을 한 줄도 못 읽어 $AG 관리블록을 쓰지 않았다 — 이 세션에는 원칙이 실리지 않는다. 위 사유를 보고 고친 뒤 새 세션을 열어라." >&2
else
  inject_rc=0
  printf '%s\n' "$inline_body" | managed_block_inject "$AG" "$MANAGED_BEGIN" "$MANAGED_END" || inject_rc=$?
  if [ "$inject_rc" -ne 0 ]; then
    echo "[disciplined-coder] ERROR: $AG 관리블록을 못 썼다 — 이 세션에는 원칙이 실리지 않는다. 위 사유를 보고 고친 뒤 새 세션을 열어라." >&2
  fi
fi

# 4) 세션 주입용 stdout(session-start-codex가 캡처해 additionalContext로 넣는다).
#    분업 — principles+domains는 섹션 3이 AGENTS.md에 이미 인라인했으므로 여기서 다시 보내지 않는다.
#    자주 커지는 solved만 매 세션 주입 경로로 보낸다(spec 3.5). 예외는 첫 설치 세션뿐이다 —
#    AGENTS.md는 이 훅보다 먼저 로드되므로 블록을 방금 만든 세션은 인라인만으로 정본에 닿지 못한다
#    (scaffold.sh의 had_import와 같은 이유).
if [ "$had_inline" -eq 0 ]; then
  for f in agent-principles.md domains-index.md; do
    if [ -f "$KDIR/$f" ]; then cat "$KDIR/$f"; fi
  done
fi
if [ -f "$KDIR/solved_problems.md" ]; then
  printf '<!-- solved-index-root: %s -->
' "$KDIR"
  cat "$KDIR/solved_problems.md"
fi
# 무엇을 했는지 알린다. 로그의 제목 줄이나 머리말 문구는 인용하지 않는다(주입 본문에 정본 헤더가
# 한 번 더 실리는 것을 막는다).
for note in "$pc_note" "$pc_pairing" "$pc_unsplit" "$proj_note" "$proj_pairing" "$proj_unsplit"; do
  if [ -n "$note" ]; then printf '%s\n' "$note"; fi
done

# 5) 보고(진단은 stderr — stdout은 주입 본문 전용).
if [ -n "$created" ]; then echo "[disciplined-coder] Codex knowledge initialized:$created (at $KDIR)" >&2; fi
exit 0
