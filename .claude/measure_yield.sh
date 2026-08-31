#!/usr/bin/env bash
# 이 하네스가 실제로 무엇을 잡았는지 센다 — 어느 PC에서나 같은 방법으로 다시 뽑는다.
#
# 세는 것은 둘이다. 하나는 세션 기록에 남은 훅 발동이고(게이트가 몇 번 종료를 막았나),
# 다른 하나는 리뷰가 남긴 지적 건수다. 둘 다 사람이 기억해 적는 값이 아니라 파일에서 도출한다.
#
# 반사실(하네스가 없었으면)은 측정하지 않는다. 잴 필요도 없다 — 이 리뷰들은 하네스가 돌았기
# 때문에만 존재하므로, 그 리뷰가 잡은 것이 곧 하네스가 만든 값이다.
#
# Usage:
#   bash .claude/measure_yield.sh                      # 최근 7일, 현재 레포의 리뷰 기록
#   bash .claude/measure_yield.sh --since 2026-08-01   # 기간을 바꾼다
#   bash .claude/measure_yield.sh /d/projects/a /d/projects/b   # 여러 레포의 리뷰 기록을 함께
set -euo pipefail

. "$(dirname "$0")/../scripts/_resolve_home.sh"

SINCE=""
ROOTS=()
while [ $# -gt 0 ]; do
  case "$1" in
    --since) SINCE="${2:-}"; shift 2 ;;
    -h|--help) sed -n '1,14p' "$0"; exit 0 ;;
    *) ROOTS+=("$1"); shift ;;
  esac
done
[ -n "$SINCE" ] || SINCE="$(date -d '7 days ago' +%Y-%m-%d 2>/dev/null || date -v-7d +%Y-%m-%d)"
[ "${#ROOTS[@]}" -gt 0 ] || ROOTS=(".")

echo "기간: $SINCE 이후"
echo

# ── 세션 기록: 훅이 실제로 발동한 횟수 ──────────────────────────────────────
# 게이트 차단은 훅이 되돌려 보내는 고정 문구로만 센다. 훅 코드를 읽기만 한 레코드가
# 발동으로 세어지면 값이 부풀려지므로 두 문구가 함께 있을 때만 센다.
STORE="$(resolve_home claude)/projects"
if [ ! -d "$STORE" ]; then
  echo "세션 기록을 찾지 못했다: $STORE" >&2
  echo "(설정 홈이 어긋났거나 이 PC에서 아직 세션을 연 적이 없다 — 0으로 세지 않고 여기서 알린다)" >&2
else
  echo "== 세션 기록 (훅 발동) =="
  printf '%-42s %8s %8s\n' "프로젝트" "레코드" "게이트차단"
  total_rec=0; total_gate=0
  for pdir in "$STORE"/*/; do
    [ -d "$pdir" ] || continue
    read -r rec gate <<EOF
$(cat "$pdir"*.jsonl 2>/dev/null | awk -v since="$SINCE" '
      {
        d = ""
        if (match($0, /"timestamp":"[0-9]{4}-[0-9]{2}-[0-9]{2}/)) {
          d = substr($0, RSTART + 13, 10)
        }
        if (d == "" || d < since) next
        rec++
        # 훅이 되돌려 보낸 것만 센다 — 어시스턴트가 그 문구를 인용한 레코드는 발동이 아니다.
        if (index($0, "\"role\":\"user\"") && index($0, "Stop hook feedback") \
            && index($0, "미리뷰 spec/plan")) gate++
      }
      END { printf "%d %d", rec + 0, gate + 0 }')
EOF
    [ "${rec:-0}" -gt 0 ] || continue
    printf '%-42s %8s %8s\n' "$(basename "$pdir")" "$rec" "$gate"
    total_rec=$((total_rec + rec)); total_gate=$((total_gate + gate))
  done
  printf '%-42s %8s %8s\n' "합계" "$total_rec" "$total_gate"
  echo "세션을 이어서 열면 같은 레코드가 여러 파일에 다시 실리므로 이 값은 위로 조금 부풀 수 있다."
  echo
fi

# ── 리뷰 산출: 렌즈가 남긴 지적 건수 ────────────────────────────────────────
# 리뷰 기록은 파일 이름이 날짜로 시작하므로 이름으로 기간을 가린다(수정 시각은 나중 편집에
# 흔들린다). 지적 한 건은 굵게 시작하는 줄 하나로 센다 — 이 레포의 기록 양식이 그렇다.
echo "== 리뷰 산출 (렌즈가 짚은 것) =="
printf '%-52s %8s\n' "리뷰 기록" "지적"
grand=0; files=0
for root in "${ROOTS[@]}"; do
  rdir="$root/docs/superpowers/reviews"
  [ -d "$rdir" ] || continue
  while IFS= read -r f; do
    [ -n "$f" ] || continue
    base="$(basename "$f")"
    [ "${base:0:10}" \< "$SINCE" ] && continue
    n="$(grep -cE '^\*\*[●○]|^\*\*[가-힣A-Z🔴]|^- \*\*' "$f" 2>/dev/null || true)"
    printf '%-52s %8s\n' "$(basename "$root")/${base:0:40}" "${n:-0}"
    grand=$((grand + ${n:-0})); files=$((files + 1))
  done < <(find "$rdir" -maxdepth 2 -name '2*.md' 2>/dev/null | sort)
done
printf '%-52s %8s\n' "합계 (회차 $files)" "$grand"
echo
echo "굵게 시작하는 줄로 센 값이라 산문으로 적은 회차는 실제보다 적게 세어진다."
echo "그런 회차는 기록 본문이 스스로 적은 건수를 따른다(예: \"지적 쉰여덟 건\")."
