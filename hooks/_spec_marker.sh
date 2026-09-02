#!/usr/bin/env bash
# 공유: spec/plan 문서의 마지막 비공백 줄이 terminal 마커(passed|escalated)인지 판정(SSOT).
# spec_review_posttooluse.sh·spec_review_stop.sh가 같은 마커 계약을 한 곳에서 쓰도록 단일화한다.
# 마커·경로 규약의 코드 정본은 이 파일이다(바꾸려면 여기를 고친다). 산문(domain-spec-review·README)이
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

# spec/plan 디렉터리 목록(SSOT). 경로 술어와 Stop 훅의 git pathspec이 둘 다 여기서 도출한다 —
# 한쪽에 손으로 한 번 더 적으면 디렉터리를 더할 때 그쪽만 낡는다.
SPECPLAN_DIRS="docs/superpowers/specs docs/superpowers/plans"

# spec/plan 경로 술어(SSOT): superpowers 기본 경로에 있는 .md인가.
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
# 훅 입력은 Windows 형식(D:\...)이고 셸의 현재 폴더는 POSIX 형식(/d/...)이라 cygpath가 있으면 한
# 형식으로 모은 뒤 대소문자를 무시하고 견준다.
_path_norm() {  # $1=경로 → stdout: 슬래시·소문자로 정규화한 경로
  local p="$1"
  if command -v cygpath >/dev/null 2>&1; then p="$(cygpath -m "$p" 2>/dev/null || printf '%s' "$p")"; fi
  printf '%s' "$p" | tr -s '\\' '/' | tr 'A-Z' 'a-z'
}
path_in_project() {  # $1=경로 → 프로젝트 안이면 0
  local p root
  case "$1" in /*|[A-Za-z]:*) ;; *) return 0 ;; esac
  p="$(_path_norm "$1")"
  root="$(_path_norm "${CLAUDE_PROJECT_DIR:-$PWD}")"
  root="${root%/}"
  case "$p" in "$root"/*) return 0 ;; *) return 1 ;; esac
}

# spec/plan 리뷰 안내문(SSOT). PostToolUse 넛지와 Stop 차단 사유가 같은 문장을 쓴다. 렌즈 구성은
# domain-spec-review가 정하므로 여기 개수를 박지 않는다.
SPEC_REVIEW_INSTRUCTION="disciplined-coder domain-spec-review 스킬로 PREP+독립 렌즈 리뷰를 수행하라(어느 렌즈를 돌릴지는 그 스킬이 정한다). 리뷰와 처분 분류가 끝나면 개선보다 앞서 문서 마지막 줄에 spec-review 마커를 먼저 남기고(passed 또는 escalated, HTML 주석) 그다음 개선을 반영하라."
