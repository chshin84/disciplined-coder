#!/usr/bin/env bash
# split_solved_log.sh 검증. 계약: FAIL=0.
set -euo pipefail
HERE="$(cd "$(dirname "$0")/.." && pwd)"
SPLIT="$HERE/scripts/split_solved_log.sh"

pass=0; fail=0
check() { if eval "$2"; then echo "  PASS: $1"; pass=$((pass+1)); else echo "  FAIL: $1"; fail=$((fail+1)); fi; }

# 픽스처에 빈 줄을 여러 곳에 끼운다. 스크립트에서 가장 미묘한 곳이 빈 줄 처리이고, 붙여 놓은
# 픽스처로는 그 가지를 한 번도 밟지 못한다(전역 개수 세기로는 삭제 회귀가 안 드러난다).
T="$(mktemp -d)"; B="$T/backups"; LOG="$T/solved_problems.md"
{ printf '# 해결된 문제 로그 (solved_problems) — PC 전역\n\n'
  printf '머리말 문장이다.\n\n'
  printf '항목을 적는 형식은 이렇다.\n\n'
  printf -- '- 증상은 굵게 한 줄로 띄운다.\n\n'
  printf -- '- **첫째 증상이 났다**\n  - 원인: 첫째 원인\n  - 해결: 첫째 해결\n\n'
  printf -- '- **둘째 증상이 났다** (맥락)\n  - 원인: 둘째 원인\n  - 해결: 둘째 해결\n'
  printf -- '- **셋째 증상이 났다**\n  - 원인: 셋째 원인\n\n  - 해결: 빈 줄 뒤에 이어지는 줄이다\n\n'
  printf -- '- **옛 한 줄 항목** → 원인: 무엇 → 해결: 무엇\n'
} > "$LOG"
BEFORE="$(wc -l < "$LOG")"

echo "[split] a one-piece log is split into an index and body files"
bash "$SPLIT" "$LOG" "$B" >"$T/out" 2>&1 || true
check "쪼개기: 본문 폴더가 생겼다"        "[ -d '$T/solved_problems' ]"
check "쪼개기: 갈린 항목이 셋이다"        "[ \"\$(ls -1 '$T/solved_problems'/*.md 2>/dev/null | wc -l | tr -d ' ')\" = 3 ]"
check "쪼개기: 첫째 원인이 본문에 있다"   "grep -rqF -- '첫째 원인' '$T/solved_problems'"
check "쪼개기: 빈 줄 뒤 줄도 옮겨졌다"    "grep -rqF -- '빈 줄 뒤에 이어지는 줄이다' '$T/solved_problems'"
check "쪼개기: 색인에 포인터가 있다"      "grep -qF -- '→ solved_problems/' '$LOG'"
check "쪼개기: 색인에 원인이 없다"        "! grep -qF -- '첫째 원인' '$LOG'"
check "쪼개기: 색인 줄은 굵은 채다"       "grep -qF -- '- **첫째 증상이 났다**' '$LOG'"
check "쪼개기: 옛 한 줄 항목은 남았다"    "grep -qF -- '옛 한 줄 항목' '$LOG'"
check "쪼개기: 못 가른 수를 알린다"       "grep -qF -- '손으로 가를 항목 1개' '$T/out'"
check "쪼개기: 사본을 떴다"               "ls '$B'/solved_problems.*.md >/dev/null 2>&1"
check "쪼개기: 머리말이 남았다"           "grep -qF -- '머리말 문장이다.' '$LOG'"
check "쪼개기: 규칙 불릿이 남았다"        "grep -qF -- '- 증상은 굵게 한 줄로 띄운다.' '$LOG'"

# 옮겨진 줄과 남은 줄을 합치면 원본 줄 수 이상이어야 한다 — 삭제 회귀를 총량으로 한 번 더 잡는다.
AFTER=$(( $(wc -l < "$LOG") + $(cat "$T/solved_problems"/*.md 2>/dev/null | wc -l) ))
check "쪼개기: 줄이 사라지지 않았다"      "[ '$AFTER' -ge '$BEFORE' ]"

echo "[split] running it twice changes nothing"
CK1="$(cksum < "$LOG")"; N1="$(ls -1 "$T/solved_problems"/*.md 2>/dev/null | wc -l | tr -d ' ')"
bash "$SPLIT" "$LOG" "$B" >/dev/null 2>&1 || true
check "쪼개기: 두 번 돌려도 색인이 같다"  "[ \"\$(cksum < '$LOG')\" = '$CK1' ]"
check "쪼개기: 두 번 돌려도 파일 수 같다" "[ \"\$(ls -1 '$T/solved_problems'/*.md 2>/dev/null | wc -l | tr -d ' ')\" = '$N1' ]"

# 백업 자리에 파일을 두어 mkdir -p 가 실패하게 만든다. 없는 절대경로를 쓰면 Git Bash 에서
# 설치 폴더로 풀려 관리자 셸에서는 성공해 버린다.
echo "[split] without a copy it changes nothing"
RO="$(mktemp -d)"; LOG2="$RO/solved_problems.md"
printf -- '- **증상**\n  - 원인: 무엇\n  - 해결: 무엇\n' > "$LOG2"
BAD="$RO/nobackup"; : > "$BAD"
bash "$SPLIT" "$LOG2" "$BAD/sub" >/dev/null 2>&1 || true
check "쪼개기: 사본 못 뜨면 안 고친다"     "! [ -d '$RO/solved_problems' ]"
check "쪼개기: 사본 못 뜨면 로그도 그대로" "grep -qF -- '- **증상**' '$LOG2'"

echo "----"; echo "PASS=$pass FAIL=$fail"; [ "$fail" -eq 0 ]
