#!/usr/bin/env bash
# 회차 폴더의 기록 넷과 렌즈 원본을 검수한다. 픽스처가 아니라 실제 기록을 본다. test_audit.sh 는
# 픽스처의 형태를 보고 이 스크립트는 봉인 전의 실제 회차를 본다.
#
# 판정 상태의 닫힌 집합은 여기서 리터럴로 박지 않고 절차 문서에서 뽑는다(SSOT).
# 렌즈 원본 이름 규칙의 소유자는 domain-docs 의 문서 타입 표 기록 행이다. 그 행이 정한 꼴이
# `lens-<렌즈 이름>-<띄운 횟수>.json` 이고 아래 정규식이 그것을 그대로 옮긴 것이다. 그 행이
# 바뀌면 여기도 함께 바꾼다 — test_audit.sh 가 그 행의 실재를 검사한다.
#
# 사용: audit_verify.sh <회차 폴더>   (어긋난 것을 stdout 으로 적고 하나라도 있으면 1로 끝난다)
set -euo pipefail
HERE="$(cd "$(dirname "$0")/.." && pwd)"
. "$HERE/scripts/_json_valid.sh"   # json_run — 파이썬 이름은 여기가 고른다
DIR="${1:-}"
[ -n "$DIR" ] && [ -d "$DIR" ] || { echo "사용: audit_verify.sh <회차 폴더>" >&2; exit 2; }
PDA="$HERE/skills/project-doc-audit/SKILL.md"
STATUS_LINE="$(grep -F '`status`가' "$PDA" | head -1)"
STATUS_SET="$(printf '%s' "$STATUS_LINE" | grep -oE '`[a-z]+`' | tr -d '`' | grep -vx status | sort -u | tr '\n' ' ')"
[ -n "$STATUS_SET" ] || { echo "절차 문서에서 status 닫힌 집합을 못 뽑았다: $PDA" >&2; exit 2; }
json_run '
import json, os, re, sys
sys.stdout.reconfigure(encoding="utf-8", newline=chr(10))
d, allowed = sys.argv[1], set(sys.argv[2].split())
bad = []
def load(name):
    p = d.rstrip("/") + "/" + name
    if not os.path.isfile(p):
        bad.append("없는 파일: " + name); return None
    try: return json.load(open(p, encoding="utf-8"))
    except Exception as e:
        bad.append("JSON 이 아니다: " + name + " — " + str(e)); return None
fnd = load("findings.json")
if fnd is not None:
    for f in fnd.get("findings", []):
        i = str(f.get("id", "?"))
        if f.get("status") not in allowed:
            bad.append(i + ": status 가 닫힌 집합 밖이다 — " + str(f.get("status")))
        if f.get("status") in ("rejected", "undetermined") and not f.get("verdict_reason"):
            bad.append(i + ": 기각이나 미판정에 verdict_reason 이 없다")
        if not f.get("evidence_found") or not f.get("counterpart_found"):
            bad.append(i + ": 인용 확인이 참이 아니다")
        if len(str(f.get("fingerprint", ""))) != 12:
            bad.append(i + ": 지문이 열두 자가 아니다")
        for lens in [x.strip() for x in str(f.get("lens", "")).split(",") if x.strip()]:
            if not lens.startswith("lens-"):
                bad.append(i + ": lens 값에 접두사가 없다 — " + lens)
run = load("run.json")
if run is not None:
    for k in ["tokens_method", "lens_calls", "subagents", "metrics", "completed", "targets"]:
        if k not in run: bad.append("run.json 에 " + k + " 가 없다")
dif = load("diff.json")
if dif is not None:
    for k in ["schema", "no_prior_round", "items", "new_ids"]:
        if k not in dif: bad.append("diff.json 에 " + k + " 가 없다")
    if not dif.get("no_prior_round", False) and "auto_rejected" not in dif:
        bad.append("diff.json 에 auto_rejected 가 없다(앞선 회차가 있는 회차다)")
sug = load("suggestions.json")
if sug is not None and "suggestions" not in sug:
    bad.append("suggestions.json 에 suggestions 가 없다")
pat = re.compile(r"^lens-[a-z-]+-[0-9]+\.json$")
for name in sorted(os.listdir(d)):
    if not name.startswith("lens-") or not name.endswith(".json"): continue
    if not pat.match(name):
        bad.append("렌즈 원본 이름이 규칙 밖이다: " + name); continue
    try: o = json.load(open(d.rstrip("/") + "/" + name, encoding="utf-8"))
    except Exception as e:
        bad.append("JSON 이 아니다: " + name + " — " + str(e)); continue
    if "target" not in o: bad.append(name + ": target 칸이 없다")
for line in bad: print(line)
sys.exit(1 if bad else 0)
' "$DIR" "$STATUS_SET"
