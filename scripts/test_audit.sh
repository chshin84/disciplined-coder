#!/usr/bin/env bash
# 감사 스크립트(scripts/audit_*.sh)와 회차 기록의 계약. FAIL=0.
# 스크립트는 픽스처 저장소에서 실제로 돌린다. 레포의 파일과 색인은 바꾸지 않는다.
set -euo pipefail
HERE="$(cd "$(dirname "$0")/.." && pwd)"
pass=0; fail=0
check() { if eval "$2"; then echo "  PASS: $1"; pass=$((pass+1)); else echo "  FAIL: $1"; fail=$((fail+1)); fi; }
. "$HERE/scripts/_json_valid.sh"   # json_run — 파이썬 이름은 여기가 고른다

echo "[audit_evidence.sh — 인용 확인과 지문]"
EV="$HERE/scripts/audit_evidence.sh"
check "스크립트가 있다" "[ -f '$EV' ]"
EVT="$(mktemp -d)"
printf 'a\n어긋난 문장이 여기 있다.\nb\n' > "$EVT/doc.md"
printf 'x\n상대편 문장은 저기 있다.\ny\n' > "$EVT/other.md"
cat > "$EVT/findings.json" <<'FIXTURE'
{ "schema": 1, "findings": [
  { "id": "r#001", "file": "doc.md", "evidence": "어긋난 문장이 여기 있다.",
    "counterpart_file": "other.md", "counterpart": "상대편 문장은 저기 있다.", "principle": "SSOT" },
  { "id": "r#002", "file": "doc.md", "evidence": "이 문장은 파일에 없다.",
    "counterpart_file": "other.md", "counterpart": "상대편 문장은 저기 있다.", "principle": "SSOT" }
] }
FIXTURE
EV_OUT="$(bash "$EV" --root "$EVT" "$EVT/findings.json" 2>/dev/null || true)"
evq() { printf '%s' "$EV_OUT" | json_run "$1"; }
check "출력이 JSON 이다"                 "printf '%s' \"\$EV_OUT\" | json_valid_stdin"
check "있는 인용을 찾았다고 적는다"       "evq 'import json,sys; d=json.load(sys.stdin); sys.exit(0 if d[\"findings\"][0][\"evidence_found\"] is True else 1)'"
check "없는 인용을 못 찾았다고 적는다"     "evq 'import json,sys; d=json.load(sys.stdin); sys.exit(0 if d[\"findings\"][1][\"evidence_found\"] is False else 1)'"
check "상대편 인용도 확인한다"            "evq 'import json,sys; d=json.load(sys.stdin); sys.exit(0 if all(f[\"counterpart_found\"] is True for f in d[\"findings\"]) else 1)'"
check "지문이 열두 자 16진수다"           "evq 'import json,sys,re; d=json.load(sys.stdin); sys.exit(0 if all(re.fullmatch(r\"[0-9a-f]{12}\", f[\"fingerprint\"]) for f in d[\"findings\"]) else 1)'"
check "인용이 다르면 지문이 다르다"       "evq 'import json,sys,hashlib; d=json.load(sys.stdin); a,b=d[\"findings\"]; sys.exit(0 if a[\"fingerprint\"]!=b[\"fingerprint\"] else 1)'"
check "출력에 CR 이 없다"                 "! printf '%s' \"\$EV_OUT\" | grep -q \$'\\r'"
bash "$EV" --root "$EVT" "$EVT/findings.json" > "$EVT/ev_out.json" 2>/dev/null || true
check "파일로 저장한 출력을 UTF-8 로 다시 열어도 인용이 원문 그대로다" \
  "json_run 'import json,sys; d=json.load(open(sys.argv[1], encoding=\"utf-8\")); sys.exit(0 if d[\"findings\"][0][\"evidence\"]==\"어긋난 문장이 여기 있다.\" else 1)' '$EVT/ev_out.json'"
rm -rf "$EVT"

echo "[audit_rounds.sh — 회차 대조와 측정]"
AR="$HERE/scripts/audit_rounds.sh"
check "스크립트가 있다" "[ -f '$AR' ]"
ART="$(mktemp -d)"
printf '남아 있는 어긋난 문장.\n' > "$ART/doc.md"
printf '상대편 문장.\n' > "$ART/other.md"
cat > "$ART/prior.json" <<'FIXTURE'
{ "schema": 1, "findings": [
  { "id": "p#001", "fingerprint": "aaaaaaaaaaaa", "status": "confirmed", "title": "남은 것",
    "file": "doc.md", "evidence": "남아 있는 어긋난 문장.",
    "counterpart_file": "other.md", "counterpart": "상대편 문장.", "principle": "SSOT", "lens": "lens-grounding" },
  { "id": "p#002", "fingerprint": "bbbbbbbbbbbb", "status": "confirmed", "title": "사라진 것",
    "file": "doc.md", "evidence": "이제 없는 문장.",
    "counterpart_file": "other.md", "counterpart": "상대편 문장.", "principle": "SSOT", "lens": "lens-fit" },
  { "id": "p#003", "fingerprint": "cccccccccccc", "status": "rejected", "title": "기각된 것",
    "file": "doc.md", "evidence": "남아 있는 어긋난 문장.",
    "counterpart_file": "other.md", "counterpart": "상대편 문장.", "principle": "SSOT", "lens": "lens-fit" }
] }
FIXTURE
cat > "$ART/cur.json" <<'FIXTURE'
{ "schema": 1, "findings": [
  { "id": "c#001", "fingerprint": "aaaaaaaaaaaa", "status": "confirmed", "lens": "lens-grounding" },
  { "id": "c#002", "fingerprint": "dddddddddddd", "status": "rejected", "lens": "lens-fit" }
] }
FIXTURE
AR_DIFF="$(bash "$AR" diff --root "$ART" "$ART/prior.json" "$ART/cur.json" 2>/dev/null || true)"
arq() { printf '%s' "$AR_DIFF" | PYTHONUTF8=1 json_run "$1"; }
check "대조 출력이 JSON 이다"            "printf '%s' \"\$AR_DIFF\" | json_valid_stdin"
check "인용이 남아 있으면 잔존이다"       "arq 'import json,sys; d=json.load(sys.stdin); i=[x for x in d[\"items\"] if x[\"prior_id\"]==\"p#001\"][0]; sys.exit(0 if i[\"verdict\"]==\"잔존\" else 1)'"
check "인용이 사라졌으면 해소다"          "arq 'import json,sys; d=json.load(sys.stdin); i=[x for x in d[\"items\"] if x[\"prior_id\"]==\"p#002\"][0]; sys.exit(0 if i[\"verdict\"]==\"해소\" else 1)'"
check "기각된 앞선 발견은 대조하지 않는다" "arq 'import json,sys; d=json.load(sys.stdin); sys.exit(0 if not [x for x in d[\"items\"] if x[\"prior_id\"]==\"p#003\"] else 1)'"
check "같은 지문이면 이번 발견을 짝짓는다" "arq 'import json,sys; d=json.load(sys.stdin); i=[x for x in d[\"items\"] if x[\"prior_id\"]==\"p#001\"][0]; sys.exit(0 if i[\"matched_id\"]==\"c#001\" else 1)'"
check "앞선 회차에 없던 지문을 신규로 센다" "arq 'import json,sys; d=json.load(sys.stdin); sys.exit(0 if d[\"new_ids\"]==[\"c#002\"] else 1)'"
AR_DIFF2="$(bash "$AR" diff --root "$ART" "$ART/prior.json" "$ART/cur.json" 2>/dev/null || true)"
check "두 번 계산해도 같은 결과다"        "[ \"\$AR_DIFF\" = \"\$AR_DIFF2\" ]"
printf '%s' "$AR_DIFF" > "$ART/diff.json"
AR_MET="$(bash "$AR" metrics --tokens 1000 --seconds 60 "$ART/prior.json" "$ART/diff.json" 2>/dev/null || true)"
amq() { printf '%s' "$AR_MET" | PYTHONUTF8=1 json_run "$1"; }
check "측정 출력이 JSON 이다"             "printf '%s' \"\$AR_MET\" | json_valid_stdin"
check "렌즈별로 낸 수와 확정 수를 센다"    "amq 'import json,sys; d=json.load(sys.stdin); sys.exit(0 if d[\"by_lens\"][\"lens-fit\"]=={\"raised\":2,\"confirmed\":1} else 1)'"
check "확정 하나당 값을 낸다"             "amq 'import json,sys; d=json.load(sys.stdin); sys.exit(0 if d[\"tokens_per_confirmed\"]==500 else 1)'"
check "앞선 회차의 해소율을 낸다"          "amq 'import json,sys; d=json.load(sys.stdin); sys.exit(0 if d[\"resolved_rate\"]==0.5 else 1)'"
rm -rf "$ART"

echo "[렌즈 — 발견의 문턱과 기계에 넘기는 것]"
for L in lens-grounding lens-fit lens-consistency lens-adversarial; do
  F="$HERE/skills/$L/SKILL.md"
  check "$L 이 상대편을 필수로 적는다"   "grep -qF 'counterpart' '$F' && grep -qF '상대편을 못 대면 발견이 아니다' '$F'"
  check "$L 이 결과 기준을 적는다"       "grep -qF '지금 무엇이 그렇게 되어 있는지' '$F' && grep -qF '앞으로 벌어질 일을 적지 않는다' '$F'"
  check "$L 에 기계에 넘기는 것 절이 있다" "grep -qF '## 기계에 넘기는 것' '$F'"
  check "$L 에 결과 칸의 옛 기준이 안 남았다" "! grep -qF '이대로 두면 무엇이 어떻게 잘못되는' '$F'"
done
check "lens-grounding 이 인용 확인을 스크립트에 넘긴다" "grep -qF 'audit_evidence.sh' '$HERE/skills/lens-grounding/SKILL.md'"
check "lens-adversarial 은 넘길 것이 없다고 적는다"      "grep -qF '기계에 넘길 것이 없다' '$HERE/skills/lens-adversarial/SKILL.md'"

echo "[lens-readability — 제안 채널]"
LR="$HERE/skills/lens-readability/SKILL.md"
check "발견이 아니라 제안을 돌려준다고 적는다" "grep -qF '발견이 아니라 제안이다' '$LR'"
check "산출물 이름이 suggestions 다"          "grep -qF 'suggestions' '$LR'"
check "판정 목록에 들어가지 않는다고 적는다"    "grep -qF '확정과 기각을 세는 목록에 들어가지 않는다' '$LR'"
check "기계에 넘기는 것 절이 있다"             "grep -qF '## 기계에 넘기는 것' '$LR'"
check "출력 스키마에 issues 배열이 안 남았다"   "! grep -qF '\"issues\": [' '$LR'"

echo "[domain-docs — 결정론 우선]"
DD="$HERE/skills/domain-docs/SKILL.md"
check "결정론 우선 절이 있다"            "grep -qF '## 판단 앞에 기계를 세운다' '$DD'"
check "렌즈는 판단만 한다고 적는다"       "grep -qF '렌즈는 판단만 한다' '$DD'"
check "값의 경계를 적는다"               "grep -qF '새 프로젝트나 새 모델이나 새 의존이 필요하면 제안하지 않는다' '$DD'"
check "판단임을 산출물에 적게 한다"       "grep -qF '판단이라는 사실을 산출물에 적는다' '$DD'"
check "문서 검진이 렌즈를 각각 부르지 않는다" "! grep -qF '각각 호출' '$DD'"

echo "[호출자 — 디스패치와 집계 계약]"
SR="$HERE/skills/domain-spec-review/SKILL.md"
MA="$HERE/skills/meta-aggregate/SKILL.md"
check "spec 리뷰가 렌즈마다 띄우지 않는다"   "! grep -qF '렌즈마다 서브에이전트를' '$SR'"
check "spec 리뷰가 규율 소유자를 가리킨다"   "grep -qF '한 번만 띄우는 렌즈의 규율' '$SR'"
check "집계 계약이 지문을 안다"             "grep -qF 'fingerprint' '$MA'"
check "집계 계약이 제안 채널을 가른다"       "grep -qF 'suggestions' '$MA' && grep -qF '집계 대상이 아니다' '$MA'"
check "두 예외 문장이 각자 다른 규칙을 밝힌다" "grep -qF '대상마다 따로 띄우는 이 절차에서 예외는' '$SR' && grep -qF '한 대상의 렌즈를 한 호출로 묶는 이 규칙의 예외로' '$SR'"

echo "----"; echo "PASS=$pass FAIL=$fail"; [ "$fail" -eq 0 ]
