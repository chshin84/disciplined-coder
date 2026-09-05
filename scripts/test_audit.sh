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

echo "[F1 — audit_evidence.sh 가 읽는 칸이 렌즈 스키마에 다 있다]"
# 픽스처가 필수 칸을 손으로 적으면, 렌즈 문서에서 칸이 빠져도 이 테스트는 못 잡는다(실제로 그랬다).
# 그래서 스크립트가 실제로 읽는 칸(정규식으로 뽑는다)과 meta-aggregate 공통 스키마의 issues 필드
# 집합(같은 방식으로 뽑는다)을 맞대어, 스크립트가 읽는 칸 가운데 스키마에 없는 것이 있으면 실패한다.
# 렌즈 넷의 출력 스키마가 다시 file 이나 principle 을 빼면 여기서 걸린다.
MA="$HERE/skills/meta-aggregate/SKILL.md"
EVK_PROG='
import re, sys, json
ev = open(sys.argv[1], encoding="utf-8").read()
evk = sorted(set(re.findall(r"f\.get\(\"([a-z_]+)\"", ev)))
ma = open(sys.argv[2], encoding="utf-8").read()
m = re.search(r"\"issues\": \[(.*?)\],\s*\"principles_applied\"", ma, re.S)
sk = sorted(set(re.findall(r"\"([a-z_]+)\":", m.group(1)))) if m else []
missing = sorted(set(evk) - set(sk))
json.dump({"evk": evk, "sk": sk, "missing": missing}, sys.stdout)
'
EVK_JSON="$(json_run "$EVK_PROG" "$EV" "$MA")"
evkq() { printf '%s' "$EVK_JSON" | json_run "$1"; }
check "audit_evidence.sh 가 읽는 칸을 뽑아냈다"          "evkq 'import json,sys; d=json.load(sys.stdin); sys.exit(0 if d[\"evk\"] else 1)'"
check "렌즈 공통 스키마의 issues 필드를 뽑아냈다"        "evkq 'import json,sys; d=json.load(sys.stdin); sys.exit(0 if d[\"sk\"] else 1)'"
check "audit_evidence.sh 가 읽는 칸이 스키마 필드에 다 있다" "evkq 'import json,sys; d=json.load(sys.stdin); sys.exit(0 if not d[\"missing\"] else 1)'"

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
arq() { printf '%s' "$AR_DIFF" | json_run "$1"; }
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
amq() { printf '%s' "$AR_MET" | json_run "$1"; }
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
  # F16 — 「발견의 문턱」이 상대편을 필수로 요구해도 system 프롬프트가 그 요구를 안 실으면 실제로
  # 도는 것(프롬프트)에는 안 걸린다. 프롬프트 줄 자체에 짚은 곳·상대편·원칙 요구가 있는지 본다.
  check "$L 의 system 프롬프트가 상대편·원칙 요구를 싣는다" \
    "grep -m1 '^- system:' '$F' | grep -qF 'counterpart_file' && grep -m1 '^- system:' '$F' | grep -qF '상대편을 못 대면 올리지 마라'"
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
check "spec 리뷰 본문에서 렌즈당 개별 디스패치 문구가 지워졌다" "! grep -qF '렌즈당 읽기 전용 서브에이전트를 한 번씩 띄운다' '$SR'"
check "spec 리뷰 frontmatter에서 렌즈마다 개별 디스패치 문구가 지워졌다" "! grep -qF '렌즈마다 한 번씩 띄우고' '$SR'"
check "spec 리뷰가 대상 하나에 호출 하나를 띄우는 새 문장을 담는다" "grep -qF '검토 대상 하나에 호출 하나를 띄우고 그 호출이 대상을 한 번 읽고 배정된 렌즈를 차례로 적용한다' '$SR'"
check "spec 리뷰가 규율 소유자를 가리킨다"   "grep -qF '한 번만 띄우는 렌즈의 규율' '$SR'"
check "집계 계약이 지문을 안다"             "grep -qF 'fingerprint' '$MA'"
check "집계 계약이 제안 채널을 가른다"       "grep -qF 'suggestions' '$MA' && grep -qF '집계 대상이 아니다' '$MA'"
check "묶는 규칙의 예외가 lens-adversarial 이름과 한 문장에 묶여 있다" "grep -qF '한 대상의 렌즈를 한 호출로 묶는 이 규칙의 예외로, 자세가 반대인 \`lens-adversarial\`만 따로 띄운다' '$SR'"
check "나누는 규칙의 예외가 lens-prior-art 이름과 한 문장에 묶여 있다" "grep -qF '대상마다 따로 띄우는 이 절차에서 예외는 \`lens-prior-art\` 하나이며' '$SR'"

echo "[domain-llm-runtime — 고정표 배정]"
LR2="$HERE/skills/domain-llm-runtime/SKILL.md"
check "리스크 점수 절이 사라졌다"        "! grep -qF '리스크 점수는 다음 조건마다 1점' '$LR2'"
check "호출 종류별 고정표가 있다"        "grep -qF '| 호출 종류 |' '$LR2'"
check "회차마다 다시 판단하지 않는다고 적는다" "grep -qF '회차마다 다시 판단하지 않는다' '$LR2'"
check "문서 전체에 리스크로 렌즈를 고른다는 서술이 안 남아 있다" "! grep -qF '리스크' '$LR2'"

echo "[project-doc-audit — 걸음 여덟과 기록 넷]"
PDA="$HERE/skills/project-doc-audit/SKILL.md"
PDA_ROWS="$(awk '/^## 걸음/{f=1;next} f&&/^## /{exit} f&&/^\| [^|-]/{n++} END{print n-1}' "$PDA")"
PDA_SAID="$(LC_ALL=C.UTF-8 grep -oE '걸음은 [^ ]+이고' "$PDA" | head -1 | sed 's/걸음은 //; s/이고//')"
KO_NUM() { case "$1" in 하나) echo 1;; 둘) echo 2;; 셋) echo 3;; 넷) echo 4;; 다섯) echo 5;; 여섯) echo 6;; 일곱) echo 7;; 여덟) echo 8;; 아홉) echo 9;; 열) echo 10;; *) echo 0;; esac; }
check "걸음 표의 행 수와 '걸음은 N' 문장이 맞는다" "[ \"\$PDA_ROWS\" = \"\$(KO_NUM \"\$PDA_SAID\")\" ]"
check "인용 확인 스크립트를 부른다"       "grep -qF 'audit_evidence.sh' '$PDA'"
check "회차 대조 스크립트를 부른다"       "grep -qF 'audit_rounds.sh' '$PDA'"
check "세션이 판정한다고 적는다"          "grep -qF '세션이 판정한다' '$PDA'"
check "기록 파일 넷을 적는다"             "grep -qF 'run.json' '$PDA' && grep -qF 'findings.json' '$PDA' && grep -qF 'diff.json' '$PDA' && grep -qF 'suggestions.json' '$PDA'"
check "뽑기 걸음이 사라졌다"              "! grep -qF '진술을 뽑아 이름표로 모은다' '$PDA'"
check "반박검증 개념이 안 남았다"          "! grep -qF '반박검증' '$PDA'"
check "검증자 개념이 안 남았다"            "! grep -qF '검증자' '$PDA'"
check "중복제거 에이전트 개념이 안 남았다" "! grep -qF '중복제거 에이전트' '$PDA'"
PDA_STEP_TARGETS="$(awk '/^## 걸음/{f=1;next} f&&/^## /{exit} f&&/^\| [^|-]/{print}' "$PDA" | tail -n +2 | LC_ALL=C.UTF-8 grep -oE '「[^」]+」' | sed 's/「//; s/」//' | sort -u)"
if [ -n "$PDA_STEP_TARGETS" ]; then
  while IFS= read -r PDA_SEC; do
    check "걸음 표가 가리키는 '$PDA_SEC' 절이 실제로 있다" "grep -qxF '## $PDA_SEC' '$PDA'"
  done <<< "$PDA_STEP_TARGETS"
fi || true
check "적대적 렌즈를 저장소 전체에 따로 띄운다고 적는다" "grep -qF 'lens-adversarial' '$PDA' && grep -qF '저장소 전체를 입력으로 따로 한 번 띄운다' '$PDA'"
check "따로 도는 이유가 자세 차이라고 적는다"           "grep -qF '자세가 반대' '$PDA' || grep -qF '설계를 공격하는 자세' '$PDA'"

echo "[audit_prior_rounds.sh — 앞선 회차 고르기]"
APR="$HERE/scripts/audit_prior_rounds.sh"
check "스크립트가 있다"                                "[ -f '$APR' ]"
APR_T="$(mktemp -d)"; mkdir -p "$APR_T/docs/superpowers/reviews"
mk_round() { mkdir -p "$APR_T/docs/superpowers/reviews/$1"; printf '{"executor":"%s","completed":%s}\n' "$2" "$3" > "$APR_T/docs/superpowers/reviews/$1/run.json"; }
mk_round 2026-09-01-self-audit self-audit true
mk_round 2026-09-02-self-audit self-audit true
mk_round 2026-09-02-self-audit-2 self-audit false
mk_round 2026-09-03-self-audit self-audit true
mk_round 2026-09-03-other other true
mkdir -p "$APR_T/docs/superpowers/reviews/2026-08-30-legacy"
APR_OUT="$(bash "$APR" self-audit --root "$APR_T" 2>/dev/null || true)"
check "completed 인 같은 실행체의 최근 둘을 최신부터 낸다" "[ \"\$(printf '%s' \"\$APR_OUT\" | tr '\n' ' ' | sed 's/ *$//')\" = '2026-09-03-self-audit 2026-09-02-self-audit' ]"
check "다른 실행체와 끊긴 회차와 옛 기록은 빠진다"      "! printf '%s' \"\$APR_OUT\" | grep -qE 'other|self-audit-2|legacy'"
APR_STALE="$(bash "$APR" self-audit --root "$APR_T" --stale 2>/dev/null || true)"
check "--stale 이 끊긴 회차만 낸다"                     "[ \"\$APR_STALE\" = '2026-09-02-self-audit-2' ]"
check "기본 실행체 이름은 self-audit 이다"              "grep -qF 'EXEC=\"self-audit\"' '$APR'"
rm -rf "$APR_T"

echo "[실행체가 사라졌다]"
check "워크플로 파일이 없다"           "[ ! -f '$HERE/.claude/workflows/self-audit.js' ]"
check "매니페스트가 workflows 를 선언하지 않는다" "! grep -qF 'workflows' '$HERE/.claude-plugin/plugin.json'"
check "옛 계약 테스트가 없다"          "[ ! -f '$HERE/scripts/test_self_audit.sh' ]"

echo "[audit_targets.sh — 대상 목록만 낸다]"
AT="$HERE/scripts/audit_targets.sh"
check "문턱 인자가 사라졌다"           "! grep -qF -- '--limit' '$AT'"
AT_OUT="$(bash "$AT" 2>/dev/null || true)"
check "한 줄에 경로 하나만 낸다"       "! printf '%s' \"\$AT_OUT\" | grep -q \$'\t'"
check "대상이 하나 이상이다"           "[ -n \"\$AT_OUT\" ]"
check "지난 기록은 대상이 아니다"      "! printf '%s' \"\$AT_OUT\" | grep -q '^docs/superpowers/'"
check "모르는 인자를 주면 실패 종료한다" "! bash '$AT' --limit >/dev/null 2>&1"
# 그 밖의 살아 있는 .md 전부가 있다 — 기대 목록을 스크립트와 같은 규칙(대상 아님·HANDOFF-·
# superseded)으로 git 에서 도출해 실제 출력과 견준다. 조각 출력이 사라졌으므로 경로만 견준다.
AT_MISS=""
while IFS= read -r f; do
  [ -n "$f" ] || continue
  head -12 "$HERE/$f" | grep -qi superseded && continue
  printf '%s\n' "$AT_OUT" | grep -qxF "$f" || AT_MISS="$AT_MISS $f"
done <<EOF
$(cd "$HERE" && git ls-files '*.md' | grep -v '^docs/superpowers/' | grep -vE '(^|/)HANDOFF-[^/]*$')
EOF
[ -n "$AT_MISS" ] && echo "    빠진 문서:$AT_MISS"
check "살아 있는 .md 가 모두 있다"     "[ -z \"\$AT_MISS\" ]"

echo "[회차 기록의 형태 — 픽스처로 검사한다]"
RT="$(mktemp -d)"; mkdir -p "$RT/round"
cat > "$RT/round/run.json" <<'FIXTURE'
{ "schema": 1, "executor": "self-audit", "commit": "abc", "tree_clean": true, "completed": true,
  "steps_done": ["targets"], "targets": [], "metrics": { "by_lens": {}, "confirmed": 0 } }
FIXTURE
cat > "$RT/round/findings.json" <<'FIXTURE'
{ "schema": 1, "findings": [
  { "id": "r#001", "fingerprint": "aaaaaaaaaaaa", "status": "confirmed", "title": "t",
    "file": "a.md", "evidence": "e", "counterpart_file": "b.md", "counterpart": "c",
    "principle": "SSOT", "consequence": "지금 이렇게 되어 있다", "lens": "lens-fit" } ] }
FIXTURE
printf '{ "schema": 1, "no_prior_round": true, "items": [], "new_ids": [] }\n' > "$RT/round/diff.json"
printf '{ "schema": 1, "suggestions": [] }\n' > "$RT/round/suggestions.json"
rj() { json_run "$1" "$RT/round/$2"; }
# (지운 단언) run.json·diff.json·suggestions.json 이 파싱된다 — 이 픽스처는 이 테스트 자신이 방금
# 쓴 문자열이다. "유효한 JSON을 다시 읽으면 유효하다"는 파싱만 보는 것이라 이 스크립트나 문서 어느
# 쪽이 어긋나도 못 잡는다. F8이 정한 "파싱만 보는 것은 지운다"에 해당해 걷어냈다.
# (지운 단언) 발견마다 상대편과 지문이 있다 — 이 픽스처가 counterpart·fingerprint 를 손으로 채워
# 넣고 그 값이 있는지를 같은 픽스처에서 되읽는 것이라 자기 자신을 증언하는 것과 같다. audit_evidence.sh
# 가 그 칸을 실제로 읽는지는 위 [F1] 구획이 스키마와 대조해 이미 본다.
# status 의 닫힌 집합은 이 파일이 손으로 든 리터럴이 아니라 절차 문서(project-doc-audit SKILL.md)
# 「판정」 절의 한 문장에서 뽑는다 — 계획 문서는 소비하고 지우는 문서라 정본이 못 된다. 문서가 상태
# 이름을 더하거나 빼면 여기서 같이 갈린다(절차 문서나 이 픽스처 어느 한쪽만 바뀌어도 실패).
STATUS_SRC="$PDA"
STATUS_LINE="$(grep -F '`status`가' "$STATUS_SRC" | head -1)"
STATUS_SET="$(printf '%s' "$STATUS_LINE" | grep -oE '`[a-z]+`' | tr -d '`' | sort -u | tr '\n' ' ')"
check "절차 문서 「판정」 절에서 status 닫힌 집합을 뽑았다" "[ -n \"\$STATUS_SET\" ]"
STATUS_PROG='
import json, sys
allowed = set(sys.argv[2].split())
d = json.load(open(sys.argv[1], encoding="utf-8"))
sys.exit(0 if all(f.get("status") in allowed for f in d["findings"]) else 1)
'
check "findings.json 의 status 가 절차 문서의 닫힌 집합 안이다" \
  "json_run \"\$STATUS_PROG\" '$RT/round/findings.json' \"\$STATUS_SET\""
rm -rf "$RT"

echo "[문서 — 일관성 방법이 절차와 렌즈에 적혔다]"
LC="$HERE/skills/lens-consistency/SKILL.md"
check "렌즈가 이름표 묶음 짝을 적는다"                  "grep -qF '## 레포 문서 감사에서의 짝' '$LC'"
check "렌즈 type 에 duplication 이 있다"                "grep -qF 'duplication' '$LC'"
check "렌즈가 판정 셋과 narrowed 를 적는다"             "grep -qF '좁혀 적음' '$LC' && grep -qF 'narrowed' '$LC'"
check "렌즈가 산출물 공백·스코프를 감사에서 뺀다"        "grep -qF '레포 문서 감사에서는 걸지 않는다' '$LC'"
check "집계 계약이 narrowed 를 렌즈 추가 칸으로 적는다"  "grep -qF 'narrowed' '$HERE/skills/meta-aggregate/SKILL.md'"
check "한 번만 규율에 '대상이 다르면 별개 호출' 이 있다" "grep -qF '대상이 다르면 별개 호출이다' '$HERE/skills/domain-docs/SKILL.md'"
check "절차의 대체된 문장 셋이 사라졌다"                 "! grep -qF '만은 묶음에 한 번 건다' '$PDA' && ! grep -qF '묶음을 통째로 받는다' '$PDA' && ! grep -qF '묶음 전부를 서로 대조한다' '$LC'"
check "절차의 '짧은 문서 둘까지' 가 사라졌다"            "! grep -qF '짧은 문서 둘까지' '$PDA'"
check "절차에 「일관성 대조」 절과 걸음 행이 있다"         "grep -qF '## 일관성 대조' '$PDA' && grep -qF '| 진술을 대조한다 |' '$PDA'"
check "대상 목록을 손으로 적지 않고 도출한다고 적는다"    "grep -qF '목록은 손으로 적지 말고 파일에서 도출한다' '$PDA'"
check "08-30 설계 머리가 이 설계를 가리킨다"             "head -6 '$HERE/docs/superpowers/specs/2026-08-30-audit-unification-design.md' | grep -qF '2026-09-02-audit-record-and-diff-design.md'"
# run.json 이 담을 것의 정본은 「통합 기록」 절의 run.json 서술 한 줄이다. 그 줄이 대상별
# 렌즈 배정과 판정 개수를 여전히 담는다고 적는지, 그리고 픽스처가 그 두 사실을 실제로
# 담는 필드를 갖는지 양쪽을 대조한다 — 정본 문장이나 픽스처 어느 한쪽만 바뀌어도 실패한다.
PDA_RUNJSON_LINE="$(grep -F '**`run.json`**' "$PDA")"
check "정본이 대상별 렌즈 배정을 담는다고 적는다"        "printf '%s' \"\$PDA_RUNJSON_LINE\" | grep -qF '대상 문서마다 건 렌즈'"
check "정본이 판정 개수를 담는다고 적는다"               "printf '%s' \"\$PDA_RUNJSON_LINE\" | grep -qF '판정 개수'"
# (지운 단언 둘) 픽스처가 대상별 렌즈 배정·판정 개수 필드를 담는다 — 이 파일 바로 위에서 손으로 쓴
# run.json 리터럴에 그 키가 있는지를 같은 파일에서 되읽는 것이라, 정본 문장이 그 필드를 빼도 이
# 픽스처는 안 바뀌어 계속 통과한다(F8). 바로 위 두 check(정본이 대상별 렌즈 배정/판정 개수를
# 담는다고 적는다)가 정본 산문 쪽은 이미 보므로, 나머지는 F4의 metrics 필드 실측(아래
# [audit_rounds.sh — 회차 대조와 측정] 구획)이 실제 계산 결과로 대신한다.

echo "[audit_targets.sh — 배제 규칙이 실제로 걸린다]"
EXT="$(mktemp -d)"
( cd "$EXT" && git init -q && printf 'a\n' > kept.md && printf 'b\n' > "HANDOFF-x.md" \
  && printf 'superseded\n표시\n' > old.md \
  && git add kept.md "HANDOFF-x.md" old.md && git -c user.email=t@t -c user.name=t commit -qm seed )
EXT_OUT="$(bash "$AT" --root "$EXT" 2>/dev/null || true)"
check "HANDOFF- 로 시작하는 파일이 빠진다"     "! printf '%s' \"\$EXT_OUT\" | grep -q 'HANDOFF-x.md'"
check "머리에 superseded 가 있는 문서가 빠진다" "! printf '%s' \"\$EXT_OUT\" | grep -q 'old.md'"
check "빠지지 않을 문서는 남는다"              "printf '%s' \"\$EXT_OUT\" | grep -q 'kept.md'"
rm -rf "$EXT"

echo "[audit_topics.sh — 이름표 목록]"
# 「일관성 대조」의 표 대조 걸음이 이름표 목록을 이 스크립트에서 받는다. 아무도 안 부른다고 죽은
# 코드로 오인해 검사까지 함께 지워졌었다. 909eb39 의 세 단언을 되살린다.
ATP="$HERE/scripts/audit_topics.sh"
check "스크립트가 있다" "[ -f '$ATP' ]"
ATP_OUT="$(bash "$ATP" 2>/dev/null || true)"
ATP_MISS=""
while IFS= read -r want; do
  [ -n "$want" ] || continue
  printf '%s\n' "$ATP_OUT" | grep -qxF "$want" || ATP_MISS="$ATP_MISS [$want]"
done <<TOPICEOF
$(grep -oE '^- \*\*`[A-Z-]+`' "$HERE/agent-principles.md" | sed 's/^- \*\*`//; s/`$//')
$(grep '^## ' "$HERE/agent-principles.md" | sed 's/^## //')
$(ls "$HERE/skills")
$(ls "$HERE/commands" | sed 's/\.md$//')
TOPICEOF
[ -n "$ATP_MISS" ] && echo "    빠진 이름표:$ATP_MISS"
check "정본 원칙 ID·절 제목·스킬·명령 이름이 모두 있다" "[ -z \"\$ATP_MISS\" ]"
check "중복이 없다" "[ \"\$(printf '%s\n' \"\$ATP_OUT\" | sort | uniq -d | wc -l)\" = 0 ]"
check "절차의 표 대조가 이 스크립트를 부른다" "grep -qF 'audit_topics.sh' '$PDA'"

echo "[안내 문서 — 실행체가 사라진 것을 반영한다]"
check "CLAUDE.md 가 감사 기록 봉인을 적는다"  "grep -qF '봉인' '$HERE/CLAUDE.md'"
check "CLAUDE.md 가 읽기 전용 거부를 적는다"  "grep -qF '읽기 전용' '$HERE/CLAUDE.md'"
check "CLAUDE.md 가 훅 목록의 정본을 README 로 가리킨다" "grep -qF 'README.md' '$HERE/CLAUDE.md' && grep -F 'README.md' '$HERE/CLAUDE.md' | grep -qF '정본'"
check "CLAUDE.md 가 훅 개수를 세지 않는다" \
  "! grep -qE '훅 (한|하나|둘|셋|넷|다섯|여섯|일곱|여덟|아홉|열)' '$HERE/CLAUDE.md' && ! grep -qE '(하나|둘|셋|넷|다섯|여섯|일곱|여덟|아홉|열)(개|가지)?(의)? 훅' '$HERE/CLAUDE.md' && ! grep -qE '훅 [0-9]+개' '$HERE/CLAUDE.md' && ! grep -qE '[0-9]+ ?개의 훅' '$HERE/CLAUDE.md'"

echo "----"; echo "PASS=$pass FAIL=$fail"; [ "$fail" -eq 0 ]
