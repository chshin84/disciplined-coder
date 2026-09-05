#!/usr/bin/env bash
# Idempotent. SessionStart마다 실행. 지식을 PC(~/.claude/disciplined-coder)에 두고
# ~/.claude/CLAUDE.md 관리블록이 @import. 프로젝트 폴더에 파일을 새로 만들지는 않는다 —
# 무엇에 어떤 조건으로 손대는지는 README의 「프로젝트 폴더에 생기는 파일」이 정본이다.
set -euo pipefail

PLUGIN_ROOT="${CLAUDE_PLUGIN_ROOT:-$(cd "$(dirname "$0")/.." && pwd)}"

# Claude 설정 홈 해석 — 공유 헬퍼(SSOT). 도메인 PC의 네트워크 홈 리다이렉트로 bash $HOME이
# os.homedir(USERPROFILE)과 어긋나면 @import 가 조용히 빠지므로 우선순위 해석을
# _resolve_home.sh 한 곳에 둔다.
. "$(dirname "$0")/_resolve_home.sh"
. "$(dirname "$0")/_scaffold_common.sh"
. "$(dirname "$0")/_ensure_autoupdate.sh"
CLAUDE_HOME="$(resolve_home claude)"
KDIR="$CLAUDE_HOME/disciplined-coder"
UC="$CLAUDE_HOME/CLAUDE.md"

mkdir -p "$KDIR"

# 1) 정본(static) 복사·갱신: principles. src==dst면 생략.
#    사본이 없거나 내용이 다르면 canon_changed=1 — 플러그인을 처음 깔았거나 갱신한 첫 세션이라는 뜻이다.
#    4c)의 넛지가 이 값으로 "그 세션에만" 뜬다.
canon_changed=0
for f in $SCAFFOLD_FILES; do
  src="$PLUGIN_ROOT/$f"; dst="$KDIR/$f"
  if [ -f "$src" ]; then
    # 복사가 실패하면 조용히 넘어가지 않는다. 이미 옛 사본이 놓여 있는 PC에서는 파일도 있고
    # @import 배선도 남아 있어 README가 알려 준 확인 셋을 그대로 통과하므로, 정본만 낡은 채
    # 아무도 모르게 된다(FAIL-LOUD).
    if [ "$src" = "$dst" ] || { [ -e "$dst" ] && [ "$src" -ef "$dst" ]; }; then :; else
      if [ ! -f "$dst" ] || ! cmp -s "$src" "$dst"; then canon_changed=1; fi
      cp "$src" "$dst" || { echo "[disciplined-coder] ERROR: 정본 복사 실패 — $src → $dst (이전 사본이 있으면 그것이 그대로 쓰인다)" >&2; exit 1; }
    fi
  else
    echo "[disciplined-coder] WARNING: source not found at $src" >&2
  fi
done

# 1b) 관리 디렉터리 위생(멱등): 정책 정본은 _scaffold_common.sh(SCAFFOLD_WHITELIST·STALE).
#     비화이트리스트는 사용자 데이터일 수 있어 — 비었으면 제거, 내용 있으면 surface(FAIL-LOUD).
scaffold_hygiene "$KDIR"

# 3) ~/.claude/CLAUDE.md 관리블록 재생성(멱등, CRLF 내성). 상대 @import(= ~/.claude 기준).
. "$(dirname "$0")/_managed_block.sh"

# 3a) 없앤 기능(/add-pointer)이 프로젝트 CLAUDE.md에 심어 두던 옛 관리블록을 걷어낸다. 지금은
#     아무것도 그 블록을 다시 만들지 않으므로 남아 있으면 갱신되지 않는 고아다. 마커가 같으니
#     전역 CLAUDE.md와 같은 파일이면 건너뛴다 — 그건 이 훅이 매 세션 다시 만드는 정상 블록이다.
#     같은 파일인지는 문자열이 아니라 -ef 로 본다. 작업 폴더가 ~/.claude 이면 Windows 형식 경로와
#     POSIX 형식 경로가 같은 파일을 가리키는데, 문자열로 견주면 다른 파일로 보아 매 세션 전역
#     블록을 걷어냈다가 다시 넣고 사본을 하나씩 쌓았다.
#     걷어내기 전에 사본을 뜬다 — 블록 안에 사람이 끼워 넣은 줄이 있으면 그것이 유일한 복구
#     수단이고, 이 파일은 git 밖일 수 있다. 사본은 프로젝트가 아니라 전역 백업에 쌓는다.
PROJ="${CLAUDE_PROJECT_DIR:-$PWD}"
pointer_note=""
PCLAUDE="$PROJ/CLAUDE.md"
if [ -f "$PCLAUDE" ] && ! { [ "$PCLAUDE" = "$UC" ] || [ "$PCLAUDE" -ef "$UC" ]; }; then
  pblabel="$(printf '%s' "$(basename "$PROJ")" | tr -c 'A-Za-z0-9._-' '_')"
  pbstamp="$(date +%Y%m%d-%H%M%S 2>/dev/null || echo unknown)"
  prc=0
  managed_block_remove "$PCLAUDE" "$MANAGED_BEGIN" "$MANAGED_END" \
    "$KDIR/backups/CLAUDE.md.$pblabel.$pbstamp.bak" || prc=$?
  if [ "$prc" -eq 0 ]; then
    pointer_note="🔵 disciplined-coder: $PCLAUDE 에 남아 있던 옛 관리블록을 걷어냈다(사용자가 쓴 줄은 그대로 두었다. 사본: $managed_block_backup)."
  elif [ "$prc" -eq 2 ]; then
    pointer_note="🔵 disciplined-coder: $PCLAUDE 에 옛 관리블록이 남아 있는데 사본을 뜨지 못해 그대로 두었다($KDIR/backups 에 쓸 수 있게 되면 다음 세션에 다시 시도한다)."
  elif [ "$prc" -eq 4 ]; then
    pointer_note="🔵 disciplined-coder: $PCLAUDE 에 옛 관리블록이 남아 있는데 변환이 실패해 원본을 그대로 두었다(사본: $managed_block_backup. 다음 세션에 다시 시도한다)."
  elif [ "$prc" -eq 3 ]; then
    pointer_note="🔵 disciplined-coder: $PCLAUDE 에 옛 관리블록이 남아 있는데 잠금을 잡지 못해 그대로 두었다(다른 창이 같은 파일을 붙들고 있거나 그 폴더에 쓸 수 없다. 다음 세션에 다시 시도한다)."
  fi
fi

# 마커는 _managed_block.sh의 MANAGED_BEGIN/END(SSOT)를 쓴다.
# 스킬(domain-*/lens-*)은 플러그인에서 온디맨드 — 복사/주입 안 함.
# 첫 설치 판정은 반드시 주입 '전에' 한다 — 주입 후엔 항상 존재해 판정이 무의미해진다.
# -x(줄 전체 일치)를 쓰지 않는 이유: CRLF 파일에서 줄 끝 CR 때문에 영원히 거짓이 되어
# 이중 주입이 조용히 되살아난다(이 레포는 CRLF를 실재 문제로 이미 다룬다).
had_import=0
if [ -f "$UC" ] && grep -qF '@disciplined-coder/agent-principles.md' "$UC"; then had_import=1; fi
# 잠금을 못 잡으면 배선을 안 쓰고 물러난다. 그 사실을 여기서 알린다 — 정본 파일은 깔렸는데
# @import만 빠지면 세션은 원칙 없이 도는데 파일이 다 있어 아무도 눈치채지 못한다(`FAIL-LOUD`).
inject_rc=0
managed_block_inject "$UC" "$MANAGED_BEGIN" "$MANAGED_END" <<'EOF' || inject_rc=$?
@disciplined-coder/agent-principles.md
EOF
if [ "$inject_rc" -ne 0 ]; then
  echo "[disciplined-coder] ERROR: $UC 의 @import 배선을 못 했다 — 이 세션에는 원칙이 실리지 않는다. 위 사유를 보고 고친 뒤 새 세션을 열거나 /setup-discipline 을 실행하라." >&2
fi

# 4) 첫 세션 도달 보강: CLAUDE.md는 이 훅보다 먼저 로드되므로, 블록을 방금 만든 세션은
#    @import만으로 정본에 닿지 못한다. 그 세션에만 stdout(additionalContext)으로 보강한다.
#    이후 세션은 @import 한 경로로만 로드한다 — 같은 내용을 두 번 싣지 않는다.
if [ "$had_import" -eq 0 ]; then
  for f in $SCAFFOLD_FILES; do
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
for note in "$pointer_note"; do
  if [ -n "$note" ]; then printf '%s\n' "$note"; fi
done

# 4b) 마켓플레이스 자동 갱신(멱등): 사용자가 손으로 켜지 않아도 깃허브의 갱신이 따라오게 한다.
#     규칙과 안전장치는 _ensure_autoupdate.sh가 소유한다 — 우리 항목만, 키가 없을 때만, 사본을 남기고.
autoupdated="$(ensure_marketplace_autoupdate "$CLAUDE_HOME" "$PLUGIN_ROOT" || true)"
#     켰다는 사실은 stdout 으로 알린다 — SessionStart 의 stderr 는 사용자에게 닿지 않는다. 옛 관리블록을
#     걷어낸 알림과 같은 통로다. 사용자 설정 파일을 고쳐 놓고 아무도 모르게 두지 않는다(FAIL-LOUD).
if [ -n "$autoupdated" ]; then
  echo "🔵 disciplined-coder: 이 플러그인의 자동 갱신을 켰다(마켓플레이스 항목에 autoUpdate 만 넣었고 다른 설정은 그대로다). 고친 파일과 그 사본(.bak):"
  printf '%s
' "$autoupdated" | while IFS= read -r changed; do
    [ -n "$changed" ] && echo "  $changed (사본: $changed.bak)"
  done
fi

# 4c) 카파시 플러그인 설치 넛지(안내만, 설치는 하지 않는다): 정본이 새로 깔리거나 갱신된 세션에만,
#     그 플러그인이 아직 없을 때만 stdout 으로 알린다. 무시하면 다음 갱신까지 조용하다. 다른 플러그인을
#     사용자 대신 까는 것은 지나치다는 결정이 있었다. 설치 여부는 Claude Code 의 설치 기록 파일의 키로 본다.
#     정본의 SURGICAL 조항은 이 플러그인의 Surgical Changes 와 맞춰 두었다.
KARPATHY_PLUGIN="andrej-karpathy-skills@karpathy-skills"
KARPATHY_REPO="forrestchang/andrej-karpathy-skills"
if [ "$canon_changed" -eq 1 ] && ! grep -qF "\"$KARPATHY_PLUGIN\"" "$CLAUDE_HOME/plugins/installed_plugins.json" 2>/dev/null; then
  echo "🔵 disciplined-coder: 카파시(Andrej Karpathy)의 코딩 지침 플러그인이 이 PC에 없다. 디시플린은 이 플러그인과 함께 쓰도록 맞춰져 있어 설치를 권한다(설치하지는 않았다). 두 줄을 차례로 실행하면 된다:"
  echo "  claude plugin marketplace add $KARPATHY_REPO"
  echo "  claude plugin install $KARPATHY_PLUGIN"
fi

exit 0
