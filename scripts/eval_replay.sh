#!/usr/bin/env bash
# 재현 시험 진입점. 턴 목록의 턴마다 조건 A·B 의 답을 생성하고, 두 답을 순서 교차로 판정한다.
# 사용: eval_replay.sh <턴 목록> <조건 A> <조건 B> [--now]
#   턴 목록은 턴 ID 한 줄씩인 파일이다(evals/replay/turns-<이름>.txt). 조건 정의와 절차는 evals/replay/README.md.
#   답은 <DC_EVAL_HOME>/replay/<이름>/, 판정은 <DC_EVAL_HOME>/calib/<이름>/ 에 쓴다(DC_EVAL_HOME 기본 %USERPROFILE%\.dc-eval).
#   --now 는 평일 09:00~18:00 에도 실행한다(사용자가 지금 하라고 한 때만 붙인다).
# 같은 턴·같은 조건의 답과 같은 쌍의 판정은 다시 만들지 않는다. 집계는 eval_replay_report.sh 가 한다.
set -euo pipefail
HERE="$(cd "$(dirname "$0")/.." && pwd)"
. "$HERE/scripts/_json_valid.sh"
. "$HERE/scripts/_eval_env.sh"
NOW=()
ARGS=()
for a in "$@"; do [ "$a" = --now ] && NOW=(--now) || ARGS+=("$a"); done
[ "${#ARGS[@]}" -eq 3 ] || { sed -n '3,6p' "$0" | sed 's/^# //' >&2; exit 2; }
LIST="${ARGS[0]}"; A="${ARGS[1]}"; B="${ARGS[2]}"
[ -f "$LIST" ] || { echo "ERROR: 턴 목록 $LIST 이 없다." >&2; exit 2; }
NAME="$(basename "$LIST" .txt)"; NAME="${NAME#turns-}"
U="${USERPROFILE:-$HOME}"; DC="${DC_EVAL_HOME:-$(cygpath -u "$U" 2>/dev/null || printf %s "$U")/.dc-eval}"
ANS="$DC/replay/$NAME"; JD="$DC/calib/$NAME"
# 생성 세션은 EVAL_TMP 아래에서 실행된다. 그 상위 경로에 CLAUDE.md 가 있으면 생성 세션에 실려 조건이 섞인다.
TMPR="${EVAL_TMP:-/d/dc-eval-tmp}"; mkdir -p "$TMPR"
HIT="$(ancestor_claude "$TMPR")"
[ -z "$HIT" ] || { echo "ERROR: 생성 임시 폴더 $TMPR 의 상위 경로에 $HIT 가 있어 생성 세션에 실린다. EVAL_TMP 를 다른 곳으로 지정하라." >&2; exit 2; }
py() { json_run 'import runpy,sys; p=sys.argv[1]; sys.argv=[p]+sys.argv[2:]; runpy.run_path(p, run_name="__main__")' "$@"; }
# 원본과 사본이 모두 없는 턴은 생성 단계에서 그 턴만 ERR 로 남으므로 여기서 멈추지 않는다.
py "$HERE/scripts/backup_sessions.py" "$LIST" || echo "경고: 세션 파일을 찾지 못한 턴은 생성하지 못한다(위 목록)." >&2
for c in "$A" "$B"; do
  echo "[생성 $c → $ANS]"
  py "$HERE/scripts/_replay.py" "$ANS" "$c" "$LIST" ${NOW[@]+"${NOW[@]}"}
done
echo "[판정 $A·$B → $JD]"
py "$HERE/scripts/_judge.py" judge "$ANS" "$JD" "$A" "$B" "$LIST" ${NOW[@]+"${NOW[@]}"}
echo "집계: bash scripts/eval_replay_report.sh '$JD' $A $B"
