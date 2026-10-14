#!/usr/bin/env bash
# bw_check.sh: 인자로 받은 파일들에 금지 표현 목록의 모든 행을 적용해 검출된 낱말을 파일별로 출력한다.
# 저장소의 표 파서와 검사 함수(hooks/_banned_words.sh)를 그대로 쓴다. 백틱과 코드 블록 안은 검사하지 않는다.
# 사용: bash bw_check.sh 파일...
set -euo pipefail
R="$(cd "$(dirname "$0")/../../../.." && pwd)"
. "$R/scripts/_json_valid.sh"
. "$R/hooks/_banned_words.sh"
W="$(mktemp -d)"; trap 'rm -rf "$W"' EXIT
banned_parse "$R/korean-banned-words.md" "$W/pairs" "$W/toks" "$W/excl" "$W/scopes"
printf '%s\n' "$@" > "$W/files"
banned_scan "$W/pairs" "$W/excl" "$W/scopes" "" "$W/files" | awk -F'\t' 'NF==2 && $2!=""' \
  | awk -F'\t' '{ n = split($2, fs, " "); for (i = 1; i <= n; i++) acc[fs[i]] = acc[fs[i]] " " $1 } END { for (f in acc) print f ":" acc[f] }' | sort
