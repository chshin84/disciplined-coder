#!/usr/bin/env bash
# 공유: spec/plan 문서의 마지막 비공백 줄이 terminal 마커(passed|escalated)인지 판정(SSOT).
# spec_review_posttooluse.sh·spec_review_stop.sh가 같은 마커 계약을 한 곳에서 쓰도록 단일화한다.
# 마커·경로 규약의 코드 정본은 이 파일이다(바꾸려면 여기를 고친다). 산문 기술은
# domain-spec-review SKILL.md와 훅 안내문에도 있으니 규약 변경 시 함께 갱신한다(쌍 계약).
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

# spec/plan 경로 술어(SSOT): superpowers 기본 경로에 있는 .md인가.
# 절대경로(훅 입력)와 상대경로(git 출력) 모두 매치되도록 선행 구분자를 요구하지 않는다.
path_is_specplan() {  # $1=경로 → spec/plan 경로면 0
  case "$1" in
    *docs/superpowers/specs/*.md|*docs/superpowers/plans/*.md) return 0 ;;
    *) return 1 ;;
  esac
}
