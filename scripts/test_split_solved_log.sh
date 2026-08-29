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
# 백업 폴더는 안 보고 있었다. 그래서 고칠 것이 없는 회차에도 사본이 쌓이는 결함이 초록으로 남았다 —
# 정작 복구가 필요한 순간에 손대기 전 원본이 어느 것인지 가릴 수 없게 된다. 개수는 첫 회차 값을
# 변수로 받아 비교한다(매직 넘버 금지).
BK1="$(ls -1 "$B" 2>/dev/null | wc -l | tr -d ' ')"
bash "$SPLIT" "$LOG" "$B" >/dev/null 2>&1 || true
check "쪼개기: 두 번 돌려도 사본이 안 는다" "[ \"\$(ls -1 '$B' 2>/dev/null | wc -l | tr -d ' ')\" = \"\$BK1\" ]"
check "쪼개기: 첫 회차엔 사본을 떴다"       "[ \"\$BK1\" -ge 1 ]"

# 중간에 죽으면 아무것도 남기지 않는다. 전에는 본문을 제자리에 하나씩 썼기 때문에, 죽으면 본문
# 몇 개만 남고 색인은 옛 형식이었다 — 쪼개짐 판정은 본문 파일 하나면 참이 되므로 다음 세션이
# 옛 형식 색인에 최신 머리말을 씌워 굳혔다. 파이썬을 실패하게 만들어 그 회차를 재현한다.
echo "[split] a mid-run failure must leave nothing behind"
CT="$(mktemp -d)"; CLOG="$CT/solved_problems.md"; CB="$CT/backups"
printf -- '- **증상이 났다**\n  - 원인: 무엇\n  - 해결: 무엇\n' > "$CLOG"
CBEFORE="$(cksum < "$CLOG")"
FAKEPY="$(mktemp -d)"
printf '#!/usr/bin/env bash\nexit 1\n' > "$FAKEPY/python3"; chmod +x "$FAKEPY/python3"
cp "$FAKEPY/python3" "$FAKEPY/python"
CRC=0; ( PATH="$FAKEPY:$PATH" bash "$SPLIT" "$CLOG" "$CB" ) >/dev/null 2>&1 || CRC=$?
check "중간 실패: 실패로 돌아온다"          "[ '$CRC' -ne 0 ]"
check "중간 실패: 본문 폴더가 안 생긴다"    "[ ! -d '$CT/solved_problems' ]"
check "중간 실패: 사본도 안 뜬다"           "[ ! -d '$CB' ]"
check "중간 실패: 로그가 그대로다"          "[ \"\$(cksum < '$CLOG')\" = '$CBEFORE' ]"
check "중간 실패: 임시 파일이 안 남는다"    "[ -z \"\$(ls -1 '$CT' | grep -vx 'solved_problems.md')\" ]"

# 백업 자리에 파일을 두어 mkdir -p 가 실패하게 만든다. 없는 절대경로를 쓰면 Git Bash 에서
# 설치 폴더로 풀려 관리자 셸에서는 성공해 버린다.
echo "[split] without a copy it changes nothing"
RO="$(mktemp -d)"; LOG2="$RO/solved_problems.md"
printf -- '- **증상**\n  - 원인: 무엇\n  - 해결: 무엇\n' > "$LOG2"
BAD="$RO/nobackup"; : > "$BAD"
bash "$SPLIT" "$LOG2" "$BAD/sub" >/dev/null 2>&1 || true
check "쪼개기: 사본 못 뜨면 안 고친다"     "! [ -d '$RO/solved_problems' ]"
check "쪼개기: 사본 못 뜨면 로그도 그대로" "grep -qF -- '- **증상**' '$LOG2'"

# 사본 이름표는 스캐폴드가 쓰는 것과 같아야 한다. 부모 폴더 이름으로 짓던 판본은 모든 레포의
# 프로젝트 로그를 'docs' 하나로 뭉쳐 어느 레포의 사본인지 가릴 수 없었다.
echo "[split] the copy is labelled by the caller, not by the parent folder"
T3="$(mktemp -d)"; mkdir -p "$T3/docs"; B3="$T3/backups"; LOG3="$T3/docs/solved_problems.md"
printf -- '- **증상이 났다**\n  - 원인: 무엇\n  - 해결: 무엇\n' > "$LOG3"
bash "$SPLIT" "$LOG3" "$B3" my-repo >/dev/null 2>&1 || true
check "쪼개기: 넘겨준 이름표를 쓴다"        "ls '$B3'/solved_problems.my-repo.*.md >/dev/null 2>&1"
check "쪼개기: 부모 폴더 이름을 안 쓴다"    "! ls '$B3'/solved_problems.docs.*.md >/dev/null 2>&1"

# 이름표를 안 넘기면 이름 없이 뜬다. 부모 폴더 이름으로 되돌아가면 두 규칙이 다시 갈린다.
T4="$(mktemp -d)"; mkdir -p "$T4/docs"; B4="$T4/backups"; LOG4="$T4/docs/solved_problems.md"
printf -- '- **증상이 났다**\n  - 원인: 무엇\n  - 해결: 무엇\n' > "$LOG4"
bash "$SPLIT" "$LOG4" "$B4" >/dev/null 2>&1 || true
check "쪼개기: 이름표가 없어도 사본은 뜬다" "ls '$B4'/solved_problems.*.md >/dev/null 2>&1"
check "쪼개기: 이름표 없으면 폴더명 안 붙인다" "! ls '$B4'/solved_problems.docs.*.md >/dev/null 2>&1"

# 스캐폴드가 쪼개기를 직접 부를 때 이름표까지 채워 넘긴다 — 안 넘기면 사본이 다른 규칙으로
# 쌓여 같은 폴더에서 두 규칙이 섞이고, 어느 로그의 사본인지 가릴 수 없게 된다.
echo "[split] the scaffold passes the label through when it splits"
NL="$(mktemp -d)"; NLOG="$NL/solved_problems.md"
printf -- '- **증상이 났다**\n  - 원인: 무엇\n' > "$NLOG"
NOTE="$( . "$HERE/scripts/_scaffold_common.sh"; scaffold_migrate_solved_unsplit "$NLOG" "$HERE" "$NL/backups" my-label; printf '%s' "$solved_unsplit_note" )"
check "쪼갠 사본이 이름표를 달았다"    "ls '$NL/backups'/solved_problems.my-label.*.md >/dev/null 2>&1"
check "쪼갰다고 알린다"                "printf '%s' \"\$NOTE\" | grep -qF -- '쪼갰다'"
check "쪼갠 결과가 실제로 갈렸다"      "grep -qF -- '→ solved_problems/' '$NLOG'"

# PATH 앞자리에 있는 이름뿐인 파이썬에 걸리지 않는다. 윈도우 스토어가 심어 두는 python3 는
# PATH 에 있고 command -v 도 통과하지만, 돌리면 "Python" 한 줄을 찍고 죽는다. 존재만 보고 고르면
# 그 스텁을 집어 쪼개기가 통째로 실패한다 — 이 레포의 다른 두 스크립트는 이미 돌려 보고 고른다.
echo "[split] a name-only python earlier on PATH does not win"
SB="$(mktemp -d)"; printf '#!/bin/sh
echo Python
exit 49
' > "$SB/python3"; chmod +x "$SB/python3"
S5="$(mktemp -d)"; LOG5="$S5/solved_problems.md"; B5="$S5/backups"
printf -- '- **증상이 났다**
  - 원인: 무엇
' > "$LOG5"
PATH="$SB:$PATH" bash "$SPLIT" "$LOG5" "$B5" stub >/dev/null 2>&1 || true
check "스텁을 건너뛰고 쪼갠다"        "grep -qF -- '→ solved_problems/' '$LOG5'"
check "스텁이어도 본문이 생긴다"      "ls '$S5/solved_problems'/*.md >/dev/null 2>&1"


echo "----"; echo "PASS=$pass FAIL=$fail"; [ "$fail" -eq 0 ]
