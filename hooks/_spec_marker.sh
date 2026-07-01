#!/usr/bin/env bash
# 공유: spec/plan 문서의 마지막 비공백 줄이 terminal 마커(passed|escalated)인지 판정(SSOT).
# spec_review_posttooluse.sh·spec_review_stop.sh가 같은 마커 계약을 한 곳에서 쓰도록 단일화한다.
# 마커 규약을 바꾸려면 여기만 고친다.
marker_is_terminal() {  # $1=파일 → 마지막 비공백 줄이 terminal 마커면 0, 아니면 1
  local last
  last="$(grep -v '^[[:space:]]*$' "$1" 2>/dev/null | tail -n 1 || true)"
  case "$last" in
    *'<!-- spec-review: passed'*|*'<!-- spec-review: escalated'*) return 0 ;;
    *) return 1 ;;
  esac
}
