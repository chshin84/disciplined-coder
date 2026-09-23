#!/usr/bin/env bash
# 사람이 필요할 때 직접 돌리는 측정 도구다. 검사 스크립트가 아니다 — 이름이 `test_` 로 시작하지
# 않으므로 저장소 `CLAUDE.md` 의 변경 뒤 실행 묶음에서 돌지 않는다.
#
# 이 저장소 자신의 문서에 금지 표현 검사를 자동으로 걸지 않기로 2026-09-22 에 정했다. 사유는
# `scripts/test_docs_drift.sh` 의 「금지 표현」 절 주석이 소유한다. 그 결정이 검토까지 없애는 것은
# 아니라서, 개발자가 적절한 기간마다 이것을 돌려 직접 본다.
#
# 쓰는 법:
#   bash scripts/check_banned_words.sh          적용 대상이 `문서와 답변` 인 행만 본다
#   bash scripts/check_banned_words.sh --all    적용 대상을 가리지 않고 표의 모든 행을 본다
#
# 훅이 다른 프로젝트의 산출물에 거는 것은 모든 행이다. 훅이 무엇을 거부할지 보려면 `--all` 이다.
set -euo pipefail
HERE="$(cd "$(dirname "$0")/.." && pwd)"
cd "$HERE"

WANT="문서와 답변"
[ "${1:-}" = "--all" ] && WANT=""

BANSRC="$HERE/korean-banned-words.md"
if [ ! -f "$BANSRC" ]; then
  echo "금지 표현 목록이 없다 — $BANSRC"
  exit 1
fi

# 표 파싱과 본문 맞추기는 훅과 같은 함수를 쓴다. 파서가 둘이면 표의 모양이 바뀔 때 한쪽만
# 따라가고, 그러면 여기서 본 결과와 훅이 거부하는 것이 갈린다.
. "$HERE/scripts/_json_valid.sh"
. "$HERE/hooks/_banned_words.sh"

W="$(mktemp -d)"
trap 'rm -rf "$W"' EXIT
banned_parse "$BANSRC" "$W/pairs" "$W/toks" "$W/excl" "$W/scopes"

# 대상은 살아 있는 문서다. 기록과 설계 문서는 찍은 뒤 고치지 않거나 보존 목적이라 뺀다. 목록
# 파일 자신은 생성물이고 표가 그 낱말을 이름으로 적으므로 뺀다.
git ls-files '*.md' \
  | grep -v '^docs/superpowers/' \
  | grep -v '^korean-banned-words.md$' \
  > "$W/files"

N="$(wc -l < "$W/files" | tr -d ' ')"
STAMP="$(grep -oE 'schema [0-9]+, [0-9-]+, [0-9a-f]+' "$BANSRC" | head -1 || echo '버전 표시 없음')"
echo "목록: $STAMP"
echo "대상: 살아 있는 문서 ${N}개 / 적용 대상: ${WANT:-전부}"
echo

# banned_scan 은 적용 대상 칸을 인자로 받아 행을 고른다. banned_report 는 그 칸을 읽지 않고 표의
# 모든 행을 적용하므로 여기서는 쓰지 않는다.
banned_scan "$W/pairs" "$W/excl" "$W/scopes" "$WANT" "$W/files" > "$W/out"
awk -F'\t' 'NF==2 && $2!=""' "$W/out" > "$W/hits"

if [ ! -s "$W/hits" ]; then
  echo "검출 없음"
  exit 0
fi

# 낱말별로 나온 것을 문서별로 다시 묶는다. 고치는 사람은 문서 하나를 열어 그 안의 낱말을 함께
# 보므로, 낱말 순서로 늘어놓으면 같은 문서를 여러 번 열게 된다.
awk -F'\t' '{ n = split($2, fs, " "); for (i = 1; i <= n; i++) acc[fs[i]] = (acc[fs[i]] == "" ? $1 : acc[fs[i]] " " $1) } END { for (f in acc) print f "\t" acc[f] }' "$W/hits" \
  | sort \
  | while IFS=$'\t' read -r f words; do
      printf '%s\n  %s\n\n' "$f" "$words"
    done

printf '검출된 낱말 %s종 / 문서 %s개\n' \
  "$(wc -l < "$W/hits" | tr -d ' ')" \
  "$(awk -F'\t' '{ n = split($2, fs, " "); for (i = 1; i <= n; i++) seen[fs[i]] = 1 } END { print length(seen) }' "$W/hits")"
