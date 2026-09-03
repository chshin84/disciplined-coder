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

echo "[실행체 — 재배선]"
check "실행체가 audit_targets.sh 를 부른다"           "grep -qF 'audit_targets.sh' '$WF'"
check "실행체가 검토 대상 문서를 손으로 적지 않는다"  "! grep -qE \"['\\\"](README|CLAUDE)\\\\.md['\\\"]\" '$WF' && ! grep -qF '검토 대상: README' '$WF'"
check "레포 확인 걸음이 있다"                          "grep -qF \"'repo-check'\" '$WF' && grep -qF \"name !== 'disciplined-coder'\" '$WF'"
check "기록은 파일 하나마다 기록자와 검수자를 띄운다"  "grep -qF 'async function writeFile(' '$WF' && grep -qF \"label: \\\`record:\" '$WF' && grep -qF \"label: \\\`check:\" '$WF' && grep -qF '기록 검수 불일치' '$WF'"
check "completed 는 검수를 지난 뒤에만 참이 된다"     "grep -qF 'run.completed = true' '$WF' && grep -qF 'async function writeRun(' '$WF'"
check "요약문은 봉인하지 않는다"                       "grep -qF 'async function writeSummary(' '$WF' && grep -qF '요약문은 봉인하지 않는다' '$WF'"
check "기록자가 봉인 스크립트를 돈다"                  "grep -qF 'seal_reviews.sh' '$WF'"
check "렌즈에 정본 경로와 principles_applied 를 요구한다" "grep -qF 'agent-principles.md' '$WF' && grep -qF 'principles_applied' '$WF'"
check "기계 검사가 실패를 묻는 형태를 금지한다"        "grep -qF '종료 코드에 묻히는 형태로 바꿔 쓰지 마라' '$WF'"
check "옛 차원 렌즈가 없다"                            "! grep -qE 'ssot-audit|shell-audit|clear-comm-audit|docs-compliance' '$WF'"
check "매니페스트가 실행체를 workflows 에 선언한다"     "grep -qF '\"./.claude/workflows/self-audit.js\"' '$HERE/.claude-plugin/plugin.json'"
check "Date.now 와 Math.random 을 쓰지 않는다"          "! grep -qE 'Date\\.now|Math\\.random|new Date' '$WF'"

check "걸음마다 서브에이전트 상한이 상수로 박혀 있다"  "grep -qE 'const CAPS = \{ review: [0-9]+, verify: [0-9]+ \}' '$WF'"
check "상한을 넘겨 자른 것을 기록에 남긴다"            "grep -qF '리뷰 상한' '$WF' && grep -qF '검증 상한' '$WF' && grep -qF 'over_cap' '$WF'"
check "검증자는 파일 하나에 하나다"                    "grep -qF 'verify:\${g.file}' '$WF' && grep -qF 'VERDICTS_SCHEMA' '$WF' && ! grep -qF 'verify-fact' '$WF'"
check "렌즈 배정은 판단이 아니라 고정표에서 온다"      "grep -qF '「렌즈 배정 기준」 표' '$WF' && grep -qF '표에 없는 렌즈를 더하지 마라' '$WF'"
check "중복제거는 본문이 아니라 번호를 돌려준다"        "grep -qF 'merged_from' '$WF' && grep -qF '번호만 돌려준다' '$WF'"
check "배정 기준이 고정표다"                          "grep -qF '문서 종류로 정한다' '$HERE/skills/project-doc-audit/SKILL.md' && grep -qF '회차마다 다시 판단하지 않는다' '$HERE/skills/project-doc-audit/SKILL.md'"

check "리뷰 기록은 대상마다 묶어 쓰고 검수는 한 번 돈다" "grep -qF 'async function recordGrouped(' '$WF' && grep -qF 'FOLDER_CHECK_SCHEMA' '$WF' && grep -qF \"recordGrouped('review'\" '$WF'"

echo "----"; echo "PASS=$pass FAIL=$fail"; [ "$fail" -eq 0 ]
