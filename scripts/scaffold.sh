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

# 윈도우 사용자 환경 변수 PYTHONUTF8 을 읽는다. 프로세스 환경이 아니라 레지스트리를 보는 이유는,
# SetEnvironmentVariable('User') 이 레지스트리만 바꿔 이미 뜬 Claude Code 의 환경에는 안 실리기
# 때문이다. 프로세스 환경을 보면 넣은 뒤에도 계속 "비어 있다"가 참이라 안내가 되풀이된다.
# 테스트는 DISCIPLINED_CODER_UTF8_STATE 로 결과를 주입해 OS 와 레지스트리를 안 본다.
utf8_user_var_state() {
  if [ -n "${DISCIPLINED_CODER_UTF8_STATE:-}" ]; then printf '%s' "$DISCIPLINED_CODER_UTF8_STATE"; return 0; fi
  case "$(uname -s 2>/dev/null || echo unknown)" in
    MINGW*|MSYS*|CYGWIN*) ;;
    *) printf 'not-windows'; return 0 ;;
  esac
  # //v 는 Git Bash 가 /v 로 되돌린다. /v 로 쓰면 경로로 바꿔 버려 reg 가 못 알아듣는다.
  # 상태를 넷으로 가른다. 'off' 는 사용자가 값을 0 으로 적어 일부러 끈 것이라 손대지 않는다.
  utf8_q="$(reg query "HKCU\\Environment" //v PYTHONUTF8 2>/dev/null || true)"
  if [ -z "$utf8_q" ]; then printf 'unset'; return 0; fi
  utf8_v="$(printf '%s' "$utf8_q" | awk '/PYTHONUTF8/ { print $NF }' | tr -d '\r' | tail -1)"
  if [ "$utf8_v" = "0" ]; then printf 'off'; else printf 'on'; fi
}

# 사용자 환경 변수를 넣는다. 레지스트리를 바꾸므로 상태 주입이 걸린 시험에서는 실제로 부르지 않는다.
# 넣는 곳을 여기 하나로 둔다. 같은 일을 커맨드에서도 하면 어느 쪽이 진짜인지 흐려진다.
utf8_set_user_var() {
  if [ -n "${DISCIPLINED_CODER_UTF8_STATE:-}" ]; then return 0; fi
  powershell -NoProfile -Command "[Environment]::SetEnvironmentVariable('PYTHONUTF8','1','User')" >/dev/null 2>&1
}

# 1) 정본(static) 복사·갱신: principles. src==dst면 생략.
for f in $SCAFFOLD_FILES; do
  src="$PLUGIN_ROOT/$f"; dst="$KDIR/$f"
  if [ -f "$src" ]; then
    # 복사가 실패하면 조용히 넘어가지 않는다. 이미 옛 사본이 놓여 있는 PC에서는 파일도 있고
    # @import 배선도 남아 있어 README가 알려 준 확인 셋을 그대로 통과하므로, 정본만 낡은 채
    # 아무도 모르게 된다(FAIL-LOUD).
    if [ "$src" = "$dst" ] || { [ -e "$dst" ] && [ "$src" -ef "$dst" ]; }; then :; else
      cp "$src" "$dst" || { echo "[disciplined-coder] ERROR: 정본 복사 실패 — $src → $dst (이전 사본이 있으면 그것이 그대로 쓰인다)"; exit 1; }
    fi
  else
    echo "[disciplined-coder] WARNING: source not found at $src"
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
  echo "[disciplined-coder] ERROR: $UC 의 @import 배선을 못 했다 — 이 세션에는 원칙이 실리지 않는다. 위 사유를 보고 고친 뒤 새 세션을 열거나 /setup-discipline 을 실행하라."
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
      echo "[disciplined-coder] WARNING: cannot read $KDIR/$f — 이 세션의 stdout 보강에서 빠진다"
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
#     그 함수는 실패마다 사유를 stderr 로 찍고 모든 갈래에서 0 으로 끝난다. 종료 코드는 통로가 못
#     되므로 stderr 를 받아 stdout 으로 옮긴다. 함수의 stdout 은 바뀐 파일 목록을 돌려주는 반환
#     통로라 거기 섞으면 "켰다" 머리말 아래 거짓 통지가 된다.
au_err="$(mktemp)"
autoupdated="$(ensure_marketplace_autoupdate "$CLAUDE_HOME" "$PLUGIN_ROOT" 2>"$au_err" || true)"
#     켰다는 사실은 stdout 으로 알린다 — SessionStart 의 stderr 는 사용자에게 닿지 않는다. 옛 관리블록을
#     걷어낸 알림과 같은 통로다. 사용자 설정 파일을 고쳐 놓고 아무도 모르게 두지 않는다(FAIL-LOUD).
if [ -n "$autoupdated" ]; then
  echo "🔵 disciplined-coder: 이 플러그인의 자동 갱신을 켰다(마켓플레이스 항목에 autoUpdate 만 넣었고 다른 설정은 그대로다). 고친 파일과 그 사본(.bak):"
  printf '%s
' "$autoupdated" | while IFS= read -r changed; do
    [ -n "$changed" ] && echo "  $changed (사본: $changed.bak)"
  done
fi
#     실패 사유는 켰다는 블록 뒤에 따로 찍는다. 켠 것이 없으면 머리말 자체가 안 나오고 사유만 나온다.
if [ -s "$au_err" ]; then
  while IFS= read -r au_line; do
    if [ -n "$au_line" ]; then printf '%s\n' "$au_line"; fi
  done < "$au_err"
fi
rm -f "$au_err"

# 4c) 함께 쓰는 플러그인 확인(매 세션): 없을 때만 설치 명령을 알리고 대신 깔지는 않는다. 다른
#     플러그인을 사용자 대신 까는 것은 지나치다는 결정이 있었다. 깔려 있으면 아무것도 안 나오므로
#     매 세션 돌아도 조용하다. 안 깔기로 정했으면 plugin-notice.skip 에 이름을 한 줄 적어 끈다 —
#     건너뛸 목록을 이 스크립트에 안 적으므로 그 파일 하나로 정해지고 끈 근거도 거기 남는다.
#     설치 여부는 Claude Code 의 설치 기록 파일의 키로 본다. 마켓플레이스 이름은 설치 방법에 따라
#     갈리므로 '이름@' 앞부분만 맞대고, 마켓플레이스 인자가 '-' 면 추가 없이 바로 설치한다.
#     카파시 플러그인은 이 목록에서 뺐다. 정본의 「Karpathy guidelines」 절이 그 네 절을 산출물
#     기준으로 일반화해 이미 담고 있어, 함께 깔면 비슷하지만 어긋나는 지침이 매 세션 두 벌 실린다.
#     정본이 출처를 적어 두므로 어디서 온 것인지는 거기서 확인한다.
DEP_SKIP="$KDIR/plugin-notice.skip"
DEP_LIST="superpowers|-|superpowers@claude-plugins-official"
dep_missing=0
while IFS='|' read -r dep_name dep_mkt dep_key; do
  [ -n "$dep_name" ] || continue
  if grep -qF "\"$dep_name@" "$CLAUDE_HOME/plugins/installed_plugins.json" 2>/dev/null; then continue; fi
  if [ -f "$DEP_SKIP" ] && grep -qxF "$dep_name" "$DEP_SKIP" 2>/dev/null; then continue; fi
  dep_missing=1
  echo "🔵 disciplined-coder: 함께 쓰는 플러그인 $dep_name 이 이 PC에 없다. 디시플린은 이것과 함께 쓰도록 맞춰져 있어 설치를 권한다(설치하지는 않았다):"
  [ "$dep_mkt" = "-" ] || echo "  claude plugin marketplace add $dep_mkt"
  echo "  claude plugin install $dep_key"
done <<DEPEOF
$DEP_LIST
DEPEOF
if [ "$dep_missing" -eq 1 ]; then
  echo "  안 깔기로 정했으면 그 이름을 $DEP_SKIP 에 한 줄씩 적으면 이 알림이 조용해진다."
fi

# 4d) PYTHONUTF8 을 넣는다(알리는 데서 그치지 않고 실제로 넣는다): 매 세션 확인하고 변수가 비었을
#     때만 넣으므로 여러 번 돌아도 결과가 같다. 값이 0 이면 일부러 끈 것으로 보고 손대지 않는다.
#     전역 설정의 autoUpdate 를 false 로 둔 것을 존중하는 규칙과 같은 방식이다.
#     이 PC 의 파이썬은 기본 인코딩이 cp949 라 한국어 리터럴이 깨진다. 저장소 자신의 파이썬 호출은
#     json_run 이 프로세스마다 세워 두지만 클로드 코드 밖에서는 그 보호가 없다.
if [ "$(utf8_user_var_state)" = "unset" ]; then
  if utf8_set_user_var; then
    echo "🔵 disciplined-coder: 윈도우 사용자 환경 변수 PYTHONUTF8=1 을 넣었다(파이썬 한국어 깨짐 방지). 새로 여는 터미널부터 걸린다. 끄려면 그 변수를 0 으로 두면 다시 넣지 않는다."
  else
    echo "[disciplined-coder] WARNING: PYTHONUTF8 을 넣지 못했다. 직접 넣으려면 powershell 로 [Environment]::SetEnvironmentVariable('PYTHONUTF8','1','User') 를 실행한다."
  fi
fi


# 4e) 핸드오프 잔존 린트: 소비되면 곧바로 지우는 문서가 프로젝트에 남아 있으면 알린다.
#     정본의 문서 타입 표가 이 타입의 강제 장치로 이 린트를 적는다. 세는 규칙은 audit_targets.sh 와
#     같은 HANDOFF- 접두사다. 유예는 건너뛸 목록을 여기 적지 않고 파일 머리의
#     `handoff-keep-until: YYYY-MM-DD` 를 읽어 정한다 — 목록을 손으로 안 적으므로 날짜가 지나면
#     저절로 다시 걸리고, 유예의 근거가 그 파일 안에 남는다(SSOT). 값이 0 이면 아무것도 안 낸다.
if [ -n "${CLAUDE_PROJECT_DIR:-}" ] && [ -d "${CLAUDE_PROJECT_DIR:-}" ]; then
  ho_today="$(date +%Y-%m-%d)"
  ho_left=""
  for ho in "$CLAUDE_PROJECT_DIR"/HANDOFF-*.md; do
    [ -f "$ho" ] || continue
    ho_until="$(head -20 "$ho" | grep -oE 'handoff-keep-until:[[:space:]]*[0-9]{4}-[0-9]{2}-[0-9]{2}' | head -1 | grep -oE '[0-9]{4}-[0-9]{2}-[0-9]{2}' || true)"
    # 문자열 비교로 날짜를 견준다 — YYYY-MM-DD 는 사전순이 곧 시간순이다.
    if [ -n "$ho_until" ] && [ "$ho_today" \< "$ho_until" ]; then continue; fi
    ho_left="$ho_left $(basename "$ho")"
  done
  if [ -n "$ho_left" ]; then
    echo "WARNING disciplined-coder: 핸드오프가 남아 있다 —$ho_left. 담긴 것을 영속처로 옮긴 뒤 지워라. 미루려면 그 파일 머리에 handoff-keep-until: YYYY-MM-DD 를 적어라."
  fi
fi

exit 0
