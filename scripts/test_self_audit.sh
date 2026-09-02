#!/usr/bin/env bash
# 실행체(.claude/workflows/self-audit.js)·감사 스크립트(scripts/audit_*.sh)·회차 기록의 계약. FAIL=0.
# 워크플로 스크립트는 여기서 실행하지 않는다 — 정적 계약(문법·앵커 문자열)과 스크립트 동작과 기록 파일의 형태만 본다.
# 레포 자신의 파일이나 색인은 바꾸지 않는다. 픽스처는 전부 mktemp -d 로 레포 밖에 세운다.
set -euo pipefail
HERE="$(cd "$(dirname "$0")/.." && pwd)"
pass=0; fail=0
check() { if eval "$2"; then echo "  PASS: $1"; pass=$((pass+1)); else echo "  FAIL: $1"; fail=$((fail+1)); fi; }
. "$HERE/scripts/_json_valid.sh"   # json_run·json_valid_stdin — 파이썬 이름은 여기가 고른다
WF="$HERE/.claude/workflows/self-audit.js"

echo "[실행체 — 문법과 발견 칸]"
check "실행체 파일이 있다"                 "[ -f '$WF' ]"
check "node --check 가 통과한다"           "node --check '$WF' 2>/dev/null"
check "발견 id 를 회차 이름과 일련번호로 붙인다" "grep -qF 'function findingId' '$WF' && grep -qF \"padStart(3, '0')\" '$WF'"
check "검증자 판정에 isReal 을 남긴다"      "grep -qF 'isReal: v.isReal' '$WF'"
check "판정 상태 넷을 닫힌 집합으로 둔다"   "grep -qF \"'undetermined'\" '$WF' && grep -qF \"'confirmed'\" '$WF' && grep -qF \"'rejected'\" '$WF' && grep -qF \"'derived'\" '$WF'"

echo "[실행체 — 중복제거와 run 객체]"
check "중복제거 항목이 merged_from 을 돌려준다"   "grep -qF 'merged_from' '$WF'"
check "원시 발견이 정확히 한 항목에 들어갔는지 확인한다" "grep -qF '중복제거가 원시 발견을 잃었다' '$WF'"
check "발견에 type 선택 칸이 있다"                "grep -qF \"type: { type: 'string'\" '$WF'"
check "렌즈 이름을 쉼표로 나눠 센다"              "grep -qF 'function lensesOf' '$WF'"
check "run 객체가 spec 의 칸을 갖는다"            "( for k in schema executor commit tree_clean tree_changed completed steps_done targets topic_groups counts_by_lens verdict_counts narrowed unlabeled dead_agents machine_checks stale_rounds; do grep -qE \"[{, ]\$k[:,]\" '$WF' || exit 1; done )"

echo "----"; echo "PASS=$pass FAIL=$fail"; [ "$fail" -eq 0 ]
