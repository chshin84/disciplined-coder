#!/usr/bin/env bash
# 재현 시험 집계. 판정 폴더의 판정을 모아 개선·악화·같음 수, 한쪽 부호 검정 p, 평균, 참고 지표, 이전 대화 길이 구간별
# 집계를 내고 <판정 폴더>/report.json 을 쓴다. 판독 후보 쌍으로 판독 페이지 <판정 폴더>/reading-<A>-<B>.html 을 만든다.
# 사용: eval_replay_report.sh <판정 폴더> <조건 A> <조건 B> [--viol <위반 판정 폴더>] [--reading <판독 파일>]
#   답 폴더는 <DC_EVAL_HOME>/replay/<판정 폴더 이름>/, 턴 목록은 evals/replay/turns-<판정 폴더 이름>.txt 다.
#   다른 곳이면 REPLAY_ANSWERS·REPLAY_LIST 로 지정한다.
# 금지어 검출은 태그 archive/v1-final 의 원본 표로 센다(v2 재건축 3단계 측정과 같은 표). 집계 규칙은 scripts/_judge.py 머리.
# 경고가 있으면(다른 모델, 한 조건에 리비전 둘 이상) 1 로 끝난다.
set -euo pipefail
HERE="$(cd "$(dirname "$0")/.." && pwd)"
. "$HERE/scripts/_json_valid.sh"
. "$HERE/hooks/_banned_words.sh"
[ "$#" -ge 3 ] || { sed -n '4,6p' "$0" | sed 's/^# //' >&2; exit 2; }
JD="${1%/}"; A="$2"; B="$3"; shift 3
[ -d "$JD" ] || { echo "ERROR: 판정 폴더 $JD 이 없다." >&2; exit 2; }
NAME="$(basename "$JD")"
U="${USERPROFILE:-$HOME}"; DC="${DC_EVAL_HOME:-$(cygpath -u "$U" 2>/dev/null || printf %s "$U")/.dc-eval}"
ANS="${REPLAY_ANSWERS:-$DC/replay/$NAME}"
LIST="${REPLAY_LIST:-$HERE/evals/replay/turns-$NAME.txt}"
[ -f "$LIST" ] || { echo "ERROR: 턴 목록 $LIST 이 없다. REPLAY_LIST 로 지정하라." >&2; exit 2; }
W="$(mktemp -d)"; trap 'rm -rf "$W"' EXIT
git -C "$HERE" show archive/v1-final:korean-banned-words.md > "$W/table.md"
banned_parse "$W/table.md" "$W/pairs" "$W/toks" "$W/excl"
py() { json_run 'import runpy,sys; p=sys.argv[1]; sys.argv=[p]+sys.argv[2:]; runpy.run_path(p, run_name="__main__")' "$@"; }
rc=0
py "$HERE/scripts/_judge.py" report "$JD" "$A" "$B" "$LIST" "$ANS" "$W/pairs" "$W/excl" "$@" || rc=$?
[ "$rc" -le 1 ] || exit "$rc"
KEYS="$(json_run 'import json,sys; print(" ".join(c["key"] for c in json.load(open(sys.argv[1], encoding="utf-8"))["reading_candidates"]))' "$JD/report.json")"
if [ -n "$KEYS" ]; then
  # shellcheck disable=SC2086
  py "$HERE/scripts/side_by_side.py" "$JD/reading-$A-$B.html" "reading-$NAME-$A-$B" "$ANS" "$JD" $KEYS >/dev/null
  echo "판독 페이지: $JD/reading-$A-$B.html"
fi
exit "$rc"
