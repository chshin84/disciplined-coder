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

echo "[audit_targets.sh — 대상 조각과 문턱]"
AT="$HERE/scripts/audit_targets.sh"
check "스크립트가 있다"                              "[ -f '$AT' ]"
AT_LIMIT="$(bash "$AT" --limit 2>/dev/null || true)"
check "--limit 이 양의 정수를 낸다"                  "printf '%s' \"\$AT_LIMIT\" | grep -qE '^[1-9][0-9]*$'"
AT_OUT="$(bash "$AT" 2>/dev/null || true)"
check "출력이 비어 있지 않다"                        "[ -n \"\$AT_OUT\" ]"
check "줄마다 경로·시작·끝 세 칸이다"                "printf '%s\n' \"\$AT_OUT\" | awk -F'\t' 'NF!=3{exit 1}'"
check "docs/superpowers/ 아래는 없다"                "! printf '%s\n' \"\$AT_OUT\" | grep -q '^docs/superpowers/'"
check "HANDOFF- 로 시작하는 파일은 없다"             "! printf '%s\n' \"\$AT_OUT\" | grep -qE '(^|/)HANDOFF-'"
# 그 밖의 살아 있는 .md 전부가 있다 — 기대 목록은 스크립트와 같은 규칙으로 git 에서 도출한다.
AT_MISS=""
while IFS= read -r f; do
  [ -n "$f" ] || continue
  head -12 "$HERE/$f" | grep -qi superseded && continue
  printf '%s\n' "$AT_OUT" | cut -f1 | grep -qxF "$f" || AT_MISS="$AT_MISS $f"
done <<EOF
$(cd "$HERE" && git ls-files '*.md' | grep -v '^docs/superpowers/' | grep -vE '(^|/)HANDOFF-[^/]*$')
EOF
[ -n "$AT_MISS" ] && echo "    빠진 문서:$AT_MISS"
check "살아 있는 .md 가 모두 있다"                   "[ -z \"\$AT_MISS\" ]"
# 조각마다 문자 수가 --limit 을 넘지 않는다 — 자르기가 실제로 문턱을 지키는지 본다.
AT_OVER="$(cd "$HERE" && printf '%s\n' "$AT_OUT" | json_run '
import sys, io
limit = int(sys.argv[1]); over = []
for line in sys.stdin:
    line = line.rstrip("\n")
    if not line: continue
    path, s, e = line.split("\t"); s, e = int(s), int(e)
    lines = io.open(path, encoding="utf-8").read().split("\n")
    n = len("\n".join(lines[s-1:e]))
    if n > limit: over.append(f"{path}:{s}-{e}={n}")
print(" ".join(over))
' "$AT_LIMIT")"
[ -n "$AT_OVER" ] && echo "    문턱을 넘는 조각: $AT_OVER"
check "조각마다 문자 수가 --limit 이하다"            "[ -z \"\$AT_OVER\" ]"
# 성질로 빼는지는 픽스처 저장소에서 본다 — 레포 자신에 파일을 만들거나 색인을 건드리지 않는다.
AT_G="$(mktemp -d)"; mkdir -p "$AT_G/docs/superpowers/specs" "$AT_G/sub" "$AT_G/HANDOFF-dir"
( cd "$AT_G" && git init -q && git config user.email t@t && git config user.name t \
  && printf '# live\n\nbody\n' > live.md && printf '# spec\n' > docs/superpowers/specs/s.md \
  && printf '# old\n> superseded 2026-09-03\n' > old.md && printf '# h\n' > HANDOFF-x.md && printf '# h2\n' > sub/HANDOFF-y.md \
  && printf '# keep\n' > HANDOFF-dir/keep.md \
  && git add -A && git commit -qm seed )
AT_FIX="$(bash "$AT" --root "$AT_G" 2>/dev/null || true)"
check "픽스처에서 살아 있는 문서만 남는다"           "[ \"\$(printf '%s\n' \"\$AT_FIX\" | cut -f1 | sort | tr '\n' ' ' | sed 's/ *$//')\" = 'HANDOFF-dir/keep.md live.md' ]"
check "문턱 값이 audit_targets.sh 한 곳에만 있다"     "[ \"\$(grep -rlE \"(^|[^0-9])\$AT_LIMIT([^0-9]|$)\" '$HERE'/scripts '$HERE'/skills '$HERE'/README.md '$HERE'/CLAUDE.md '$HERE'/.claude/workflows 2>/dev/null | grep -vE 'audit_targets.sh|test_self_audit.sh' | wc -l)\" = 0 ]"
# 대상이 하나도 안 남는 저장소에서도 pipefail 아래 grep 단계가 조용히 죽지 않는지 본다.
AT_E="$(mktemp -d)"; mkdir -p "$AT_E/docs/superpowers/specs"
( cd "$AT_E" && git init -q && git config user.email t@t && git config user.name t \
  && printf '# spec\n' > docs/superpowers/specs/s.md \
  && git add -A && git commit -qm seed )
check "대상이 하나도 없어도 조용히 죽지 않는다"      "bash '$AT' --root '$AT_E' >/dev/null 2>&1 && [ -z \"\$(bash '$AT' --root '$AT_E')\" ]"

echo "----"; echo "PASS=$pass FAIL=$fail"; [ "$fail" -eq 0 ]
