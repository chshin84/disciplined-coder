#!/usr/bin/env bash
# 공유: spec/plan 문서의 마지막 비공백 줄이 terminal 마커(passed|escalated)인지 판정.
# spec_review_posttooluse.sh·spec_review_stop.sh가 같은 마커 계약을 한 곳에서 쓰도록 단일화한다.
# 마커·경로 규약의 코드 원본은 이 파일이다(바꾸려면 여기를 고친다). 산문(review-specs·README)이
# 여기와 같은 마커를 적는지는 scripts/test_docs_drift.sh가 코드에서 뽑아 대조한다.
# 마커는 줄 전체여야 한다. 문자열 일부로 찾으면 마커를 산문으로 언급하기만 한 문서도 통과해
# 하드 게이트가 조용히 열린다 — 마커를 남기라고 안내하는 문장이 마지막 줄이면 그렇게 된다.
# 그래서 마커로 시작하고 주석이 닫히는 줄만 인정한다. CRLF 체크아웃의 끝 CR은 먼저 걷는다.
marker_is_terminal() {  # $1=파일 → 마지막 비공백 줄이 terminal 마커면 0, 아니면 1
  local last
  last="$(grep -v '^[[:space:]]*$' "$1" 2>/dev/null | tail -n 1 || true)"
  last="${last%$'\r'}"
  case "$last" in
    '<!-- spec-review: passed'*'-->'|'<!-- spec-review: escalated'*'-->') return 0 ;;
    *) return 1 ;;
  esac
}

# spec/plan 디렉터리 목록. 경로 술어와 Stop 훅의 git pathspec이 둘 다 여기서 도출한다 —
# 한쪽에 손으로 한 번 더 적으면 디렉터리를 더할 때 그쪽만 낡는다.
SPECPLAN_DIRS="docs/superpowers/specs docs/superpowers/plans"

# spec/plan 경로 술어: superpowers 기본 경로에 있는 .md인가.
# 절대경로(훅 입력)와 상대경로(git 출력) 모두 매치되도록 선행 구분자를 요구하지 않는다.
path_is_specplan() {  # $1=경로 → spec/plan 경로면 0
  local d
  for d in $SPECPLAN_DIRS; do
    case "$1" in *"$d"/*.md) return 0 ;; esac
  done
  return 1
}

# 프로젝트 안의 경로인가. 문서 넛지 훅이 메모리 파일이나 계획 파일처럼 프로젝트 밖 문서에 걸리지
# 않게 한다. 기준은 CLAUDE_PROJECT_DIR이고 없으면 현재 폴더다. 상대경로는 프로젝트 안으로 본다.
# 훅 입력은 Windows 형식(D:\...)이고 셸의 현재 폴더는 POSIX 형식(/d/...)일 수 있다. 두 형식이
# 다를 때만 cygpath 로 POSIX 쪽을 Windows 형식으로 옮긴다. 같으면 옮길 것이 없어 프로세스를 안 띄운다.
# 슬래시를 모은 뒤 대소문자를 무시하고 견준다. slash_norm 은 _hook_input.sh 에 있어 호출자가 함께 싣는다.
_path_is_win() { case "$1" in [A-Za-z]:*) return 0 ;; esac; return 1; }
path_in_project() {  # $1=경로 → 프로젝트 안이면 0
  local p="$1" root="${CLAUDE_PROJECT_DIR:-$PWD}" nocase=0 inside=1
  case "$p" in /*|[A-Za-z]:*) ;; *) return 0 ;; esac
  if _path_is_win "$p" && ! _path_is_win "$root"; then
    if command -v cygpath >/dev/null 2>&1; then root="$(cygpath -m "$root" 2>/dev/null || printf '%s' "$root")"; fi
  elif ! _path_is_win "$p" && _path_is_win "$root"; then
    if command -v cygpath >/dev/null 2>&1; then p="$(cygpath -m "$p" 2>/dev/null || printf '%s' "$p")"; fi
  fi
  slash_norm p; slash_norm root
  root="${root%/}"
  shopt -q nocasematch && nocase=1
  shopt -s nocasematch
  [[ $p == "$root"/* ]] && inside=0
  [ "$nocase" = 1 ] || shopt -u nocasematch
  return "$inside"
}

# 이 플러그인 저장소 자신의 문서인지 본다. 조상 폴더에 agent-principles.md 가 있으면 그렇다. 금지 표현 검사가
# 이 저장소의 문서를 빼는 판정이고, 훅 셋이 같은 판정을 해야 하므로 여기 하나만 둔다.
#
# 상대경로를 받는 쪽이 있다. git status 가 돌려주는 경로가 레포 루트 기준이라 `skills/x/a.md`
# 처럼 온다. 폴더가 한 조각만 남으면 `${d%/*}` 가 그 조각을 그대로 돌려주어 루프가 거기서 끝나고,
# 정작 루트의 agent-principles.md 를 못 본 채 "남의 문서" 로 판정했다. 마지막에 `.` 을 한 번 더 본다.
# `.` 으로 물러서는 것은 상대경로뿐이다. 절대경로(`/c/...`, `D:/...`, `D:\...`)가 `.` 을 보면
# 이 저장소를 cwd 로 연 세션에서 저장소 밖의 모든 문서가 이 저장소의 것으로 판정된다.
# 이 저장소 자신의 문서를 금지 표현 검사에서 빼는 술어다. 2026-09-22 에 사용자가 이 제외를
# 영구로 정했다. 표를 외부 저장소가 소유하고 하루 한 번 동기화되므로, 낱말이 추가되면 이
# 저장소의 문서가 아무것도 안 했는데 편집이 거부된다. 검토는 사람이 직접 한다 —
# scripts/check_banned_words.sh 가 그 수단이다. 되살리지 말고 지우지도 마라.
path_in_own_repo() {  # $1=경로 → 이 저장소 자신의 문서이면 0
  local p="${1//\\//}" d prev abs=0
  case "$p" in /*|[A-Za-z]:*) abs=1 ;; esac
  d="${p%/*}"
  if [ "$d" = "$p" ]; then [ "$abs" = 1 ] && return 1; d="."; fi
  prev=""
  while [ -n "$d" ] && [ "$d" != "$prev" ]; do
    [ -f "$d/agent-principles.md" ] && return 0
    prev="$d"
    case "$d" in
      */*) d="${d%/*}" ;;
      .) d="" ;;
      *) if [ "$abs" = 1 ]; then d=""; else d="."; fi ;;
    esac
  done
  return 1
}

# 금지 표현 검사의 대상인가. Pre·Post·Stop 훅 셋이 같은 제외를 써야 같은 파일이 도구에 따라
# 다르게 판정되지 않는다. 대상은 `.md` 가운데 아래 셋에 안 드는 것이다.
#   Claude 메모리(`/.claude/projects/`) — 나에게 남기는 쪽지이고 금지어를 목록으로 적어 둘 곳이다.
#   `docs/superpowers/` 아래 — spec·plan·리뷰 기록이다. 레포 뿌리 기준 상대경로(git status)도 받는다.
#   이 저장소 자신의 문서 — path_in_own_repo 가 판정한다.
path_is_banned_target() {  # $1=경로 → 검사 대상이면 0
  case "$1" in *.md) ;; *) return 1 ;; esac
  case "$1" in */.claude/projects/*|*/docs/superpowers/*|docs/superpowers/*) return 1 ;; esac
  path_in_own_repo "$1" && return 1
  return 0
}

# 리뷰 기록인가. 양식은 검진 절이 정하고, 검진 넛지가 뜨면 기록에 대한 기록을 또 쓰는 순환이 생긴다.
# 새 문서 넛지와 검진 넛지가 함께 뺀다 — 한쪽만 빼면 같은 파일에 한 훅은 조용하고 다른 훅은 떠든다.
path_is_review_record() {  # $1=경로 → 리뷰 기록이면 0
  case "$1" in *docs/superpowers/reviews/*.md) return 0 ;; esac
  return 1
}

# spec/plan 리뷰 안내문. PostToolUse 넛지와 Stop 차단 사유가 같은 문장을 쓴다. 렌즈 구성은
# review-specs가 정하므로 여기 개수를 박지 않는다.
SPEC_REVIEW_INSTRUCTION="disciplined-coder review-specs 스킬로 PREP+독립 렌즈 리뷰를 수행하라(어느 렌즈를 돌릴지는 그 스킬이 정한다). 리뷰와 처분 분류가 끝나면 개선보다 앞서 문서 마지막 줄에 spec-review 마커를 먼저 남기고(passed 또는 escalated, HTML 주석) 그다음 개선을 반영하라."
