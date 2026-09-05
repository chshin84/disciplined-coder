# 발견의 문턱과 결정론 우선 구현 계획

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** 발견을 "짚을 상대편이 있는 어긋남"으로 좁히고, 인용 확인과 지문과 중복 제거와 회차 대조를 코드로 옮기며, 감사의 오케스트레이터를 워크플로 스크립트에서 세션으로 옮긴다.

**Architecture:** 결정론 스크립트 둘을 먼저 세우고 그 위에 렌즈 계약과 규율 문서를 맞춘다. 그다음 절차 문서를 개정하고 실행체를 지운다. 마지막에 새 절차로 회차 하나를 돌려 기록을 남긴다.

**Tech Stack:** bash, 파이썬(인터프리터 선택은 `scripts/_json_valid.sh`가 소유), 마크다운 문서.

**Spec:** `docs/superpowers/specs/2026-09-05-findings-bar-and-deterministic-first-design.md`

## Global Constraints

- 각 계약 테스트 스크립트의 계약은 **FAIL=0**이다. 기대 개수를 숫자로 박지 않는다.
- 파이썬은 `scripts/_json_valid.sh`의 `json_run`으로만 부른다. 인터프리터 이름을 스크립트에 직접 적지 않는다.
- 파이썬이 표준 출력에 쓰는 스크립트는 첫 줄에서 `sys.stdout.reconfigure(newline=chr(10))`를 부른다. 이 PC의 파이썬은 줄 끝에 CR을 붙인다.
- 픽스처는 전부 `mktemp -d`로 레포 밖에 세운다. 계약 테스트는 레포의 파일과 색인을 바꾸지 않는다.
- 문서는 한국어 완결 문장으로 쓰고 `writing-korean`의 금지 낱말(`잰다`·`재는`·`재지`·`붉어진`·`헛돈다`·`자리`·`부분`·`영역`·`경우`)을 쓰지 않는다.
- 파일은 LF로 쓴다.
- 커밋 메시지 끝에 트레일러 둘을 붙인다.

```
Co-Authored-By: Claude Opus 5 <noreply@anthropic.com>
Claude-Session: https://claude.ai/code/session_015TzuWbbCakYcG1opzHiCCb
```

- 이 계획은 사용자 결정으로 렌즈 리뷰를 건너뛴다. 계약 테스트가 유일한 게이트다.

## 이 PC 에서 되풀이되는 함정

같은 뿌리에서 이미 여러 번 깨진 것들이다. Task 마다 다시 겪지 말고 처음부터 지킨다.

| 함정 | 무엇이 일어나나 | 지킬 것 |
|---|---|---|
| 파이썬 기본 인코딩이 cp949 다 | 한국어를 표준 출력에 내면 cp949 바이트가 나가고, 그 출력을 파일에 두었다가 `encoding="utf-8"` 로 다시 열면 `UnicodeDecodeError` 가 난다 | 표준 출력에 쓰는 파이썬은 첫 줄에서 `sys.stdout.reconfigure(encoding="utf-8", newline=chr(10))` 를 부른다. 파이프로 한국어를 표준 입력에 넣는 테스트는 `PYTHONUTF8=1` 을 앞에 붙인다 |
| 파이썬이 줄 끝에 CR 을 붙인다 | 스크립트 출력을 읽는 쪽이 이름 끝의 CR 까지 값으로 읽어 비교가 어긋난다 | 같은 `reconfigure` 의 `newline=chr(10)` 이 막는다 |
| 명령 치환으로 되읽는 테스트는 인코딩 결함을 못 잡는다 | 쓰기와 읽기가 같은 기본 인코딩이라 서로 상쇄된다 | 인코딩을 검사하는 단언은 출력을 **파일에 저장한 뒤** `encoding="utf-8"` 로 다시 열어 본다 |
| `set -e` 와 `pipefail` 아래에서 반복문의 마지막 실패가 스크립트를 끝낸다 | `for`·`while` 의 마지막 반복이 거짓이면 그 종료 코드가 스크립트를 죽여, 뒤의 단언이 조용히 안 돌고 통과로 보인다 | 조건을 `if` 로 감싸거나 `{ ...; } || true` 로 닫는다 |
| `git core.autocrlf` 가 켜져 있다 | LF 로 쓴 파일을 git 이 CRLF 로 바꾼다는 경고가 커밋마다 나온다 | 경고는 정상이다. 파일은 LF 로 쓰고 경고를 고치려 들지 않는다 |
| 읽기 전용 속성을 `find -writable` 이 못 볼 수 있다 | 봉인 검사가 통과로 보인다 | 파일마다 `[ -w "$f" ]` 로 확인한다 |
| 워크트리 격리가 복합 셸 명령을 거부한다 | 여러 명령을 한 줄에 잇거나 변수를 명령 이름으로 두면 도구가 실행을 거절한다 | 명령을 나눠 실행하거나 스크립트 파일로 옮겨 부른다 |



## 파일 구조

| 파일 | 맡는 일 |
|---|---|
| `scripts/audit_evidence.sh` | 발견의 인용이 실제 파일에 있는지 확인하고 지문을 붙인다. 판단은 안 한다. |
| `scripts/audit_rounds.sh` | 회차 사이의 계산. `diff`는 잔존과 해소를 가르고 `metrics`는 측정 값을 낸다. |
| `scripts/test_audit.sh` | 위 둘과 기존 감사 스크립트와 회차 기록의 계약. 픽스처로 실제 실행한다. |
| `scripts/audit_targets.sh` | 대상 목록만 낸다. 조각내기와 입력 문턱을 뺀다. |
| `skills/lens-*/SKILL.md` | 렌즈 여섯의 출력 계약과 기계에 넘기는 것. |
| `skills/domain-docs/SKILL.md` | 결정론 우선 규칙과 값의 경계, 문서 검진 절. |
| `skills/project-doc-audit/SKILL.md` | 회차의 걸음과 기록과 처분. |

---

### Task 1: `audit_evidence.sh` — 인용 확인과 지문

**Files:**
- Create: `scripts/audit_evidence.sh`
- Create: `scripts/test_audit.sh`

**Interfaces:**
- Produces: `bash scripts/audit_evidence.sh [--root DIR] <findings.json>` → 입력 JSON에 발견마다 `evidence_found`(bool)·`counterpart_found`(bool)·`fingerprint`(12자 16진수)를 더해 stdout으로 낸다. 발견은 `file`·`evidence`·`counterpart_file`·`counterpart`·`principle`을 읽는다. `file`과 `counterpart_file`은 레포 상대경로이고 `:`가 있으면 앞부분만 쓴다. 지문은 정규화한 인용 둘과 원칙을 `\x1f`로 이어 sha1을 낸 앞 열두 자다.

- [ ] **Step 1: 실패하는 테스트를 더한다**

`scripts/test_audit.sh`를 새로 만든다.

```bash
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
check "같은 인용과 원칙이면 지문이 같다"   "evq 'import json,sys,hashlib; d=json.load(sys.stdin); a,b=d[\"findings\"]; sys.exit(0 if a[\"fingerprint\"]!=b[\"fingerprint\"] else 1)'"
check "출력에 CR 이 없다"                 "! printf '%s' \"\$EV_OUT\" | grep -q \$'\\r'"
rm -rf "$EVT"

echo "----"; echo "PASS=$pass FAIL=$fail"; [ "$fail" -eq 0 ]
```

- [ ] **Step 2: 돌려서 실패를 확인한다**

Run: `bash scripts/test_audit.sh 2>&1 | grep -E 'FAIL|PASS='`
Expected: "스크립트가 있다"부터 전부 FAIL.

- [ ] **Step 3: 스크립트를 쓴다**

`scripts/audit_evidence.sh`:

```bash
#!/usr/bin/env bash
# 발견의 인용이 실제 파일에 그 글자로 있는지 확인하고 지문을 붙인다. 판단은 하지 않는다.
# 인용이 없는 발견을 LLM 이 아니라 여기서 떨어뜨리는 것이 이 스크립트를 둔 이유다.
# 사용: audit_evidence.sh [--root DIR] <findings.json>   (결과 JSON 을 stdout 으로 낸다)
set -euo pipefail
HERE="$(cd "$(dirname "$0")/.." && pwd)"
. "$HERE/scripts/_json_valid.sh"   # json_run — 파이썬 이름은 여기가 고른다
ROOT="$HERE"; IN=""
while [ "$#" -gt 0 ]; do
  case "$1" in
    --root) ROOT="$2"; shift 2 ;;
    *) IN="$1"; shift ;;
  esac
done
[ -n "$IN" ] || { echo "사용: audit_evidence.sh [--root DIR] <findings.json>" >&2; exit 2; }
json_run '
import json, os, re, sys, hashlib
sys.stdout.reconfigure(newline=chr(10))
root, path = sys.argv[1], sys.argv[2]
def norm(s): return re.sub(r"\s+", " ", s or "").strip()
cache = {}
def text(p):
    p = (p or "").split(":")[0]
    if not p: return None
    if p not in cache:
        try: cache[p] = norm(open(os.path.join(root, p), encoding="utf-8").read())
        except Exception: cache[p] = None
    return cache[p]
d = json.load(open(path, encoding="utf-8"))
for f in d.get("findings", []):
    ev, cp = norm(f.get("evidence")), norm(f.get("counterpart"))
    t1, t2 = text(f.get("file")), text(f.get("counterpart_file"))
    f["evidence_found"] = bool(ev) and t1 is not None and ev in t1
    f["counterpart_found"] = bool(cp) and t2 is not None and cp in t2
    f["fingerprint"] = hashlib.sha1(chr(31).join([ev, cp, f.get("principle", "")]).encode("utf-8")).hexdigest()[:12]
json.dump(d, sys.stdout, ensure_ascii=False, indent=1)
' "$ROOT" "$IN"
```

- [ ] **Step 4: 돌려서 통과를 확인하고 커밋한다**

Run: `bash scripts/test_audit.sh 2>&1 | grep -E 'FAIL|PASS='`
Expected: `FAIL=0`.

```bash
git add scripts/audit_evidence.sh scripts/test_audit.sh
git commit -m "발견의 인용을 파일에서 확인하고 지문을 붙이는 스크립트를 둔다"
```

---

### Task 2: `audit_rounds.sh` — 회차 대조와 측정

**Files:**
- Create: `scripts/audit_rounds.sh`
- Modify: `scripts/test_audit.sh`

**Interfaces:**
- Consumes: Task 1의 `fingerprint`·`evidence_found`·`counterpart_found`.
- Produces: `bash scripts/audit_rounds.sh diff [--root DIR] <앞선 findings.json> <이번 findings.json>` → `{ schema, no_prior_round: false, items: [{ prior_id, fingerprint, title, file, verdict: '잔존'|'해소', matched_id }], new_ids: [...] }`. `bash scripts/audit_rounds.sh metrics --tokens N --seconds N <이번 findings.json> [앞선 diff.json]` → `{ by_lens: { <렌즈>: { raised, confirmed } }, confirmed, tokens, seconds, tokens_per_confirmed, resolved_rate }`.
- `findings.json`은 기각을 따로 두지 않고 발견 전부를 `findings`에 담으며 `status`가 `confirmed`·`rejected`·`undetermined`·`derived` 가운데 하나다. 대조는 `rejected`를 건너뛴다.

- [ ] **Step 1: 실패하는 테스트를 더한다**

`scripts/test_audit.sh`의 `echo "----"` 앞에 더한다.

```bash
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
check "렌즈별로 낸 수와 확정 수를 센다"    "amq 'import json,sys; d=json.load(sys.stdin); sys.exit(0 if d[\"by_lens\"][\"lens-fit\"]==={\"raised\":2,\"confirmed\":1} else 1)'"
check "확정 하나당 값을 낸다"             "amq 'import json,sys; d=json.load(sys.stdin); sys.exit(0 if d[\"tokens_per_confirmed\"]==500 else 1)'"
check "앞선 회차의 해소율을 낸다"          "amq 'import json,sys; d=json.load(sys.stdin); sys.exit(0 if d[\"resolved_rate\"]==0.5 else 1)'"
rm -rf "$ART"
```

- [ ] **Step 2: 돌려서 실패를 확인한다**

Run: `bash scripts/test_audit.sh 2>&1 | grep -E 'FAIL|PASS='`
Expected: 이 블록의 단언 전부가 FAIL.

- [ ] **Step 3: 스크립트를 쓴다**

`scripts/audit_rounds.sh`:

```bash
#!/usr/bin/env bash
# 회차 사이의 계산. 판단은 하지 않는다 — 앞선 회차 발견의 인용이 지금도 파일에 있으면 잔존이고
# 없으면 해소다. 문장만 바뀌고 문제가 남은 것은 해소로 잘못 세는데, 그것은 이번 회차의 렌즈가
# 새 발견으로 잡는다. 재현되는 오차를 택하고 재현 안 되는 판단을 버린다.
#   audit_rounds.sh diff    [--root DIR] <앞선 findings.json> <이번 findings.json>
#   audit_rounds.sh metrics [--root DIR] --tokens N --seconds N <이번 findings.json> [앞선 diff.json]
set -euo pipefail
HERE="$(cd "$(dirname "$0")/.." && pwd)"
. "$HERE/scripts/_json_valid.sh"   # json_run — 파이썬 이름은 여기가 고른다
CMD="${1:-}"; [ "$#" -gt 0 ] && shift
ROOT="$HERE"; TOKENS=0; SECS=0; A=""; B=""
while [ "$#" -gt 0 ]; do
  case "$1" in
    --root) ROOT="$2"; shift 2 ;;
    --tokens) TOKENS="$2"; shift 2 ;;
    --seconds) SECS="$2"; shift 2 ;;
    *) if [ -z "$A" ]; then A="$1"; else B="$1"; fi; shift ;;
  esac
done
case "$CMD" in
  diff)
    [ -n "$A" ] && [ -n "$B" ] || { echo "사용: audit_rounds.sh diff [--root DIR] <앞선 findings.json> <이번 findings.json>" >&2; exit 2; }
    json_run '
import json, os, re, sys
sys.stdout.reconfigure(newline=chr(10))
root, prior_p, cur_p = sys.argv[1], sys.argv[2], sys.argv[3]
def norm(s): return re.sub(r"\s+", " ", s or "").strip()
cache = {}
def text(p):
    p = (p or "").split(":")[0]
    if not p: return None
    if p not in cache:
        try: cache[p] = norm(open(os.path.join(root, p), encoding="utf-8").read())
        except Exception: cache[p] = None
    return cache[p]
prior = json.load(open(prior_p, encoding="utf-8"))
cur = json.load(open(cur_p, encoding="utf-8"))
cur_fp = {}
for f in cur.get("findings", []):
    cur_fp.setdefault(f.get("fingerprint"), f.get("id"))
items = []
for f in prior.get("findings", []):
    if f.get("status") == "rejected": continue
    ev, cp = norm(f.get("evidence")), norm(f.get("counterpart"))
    t1, t2 = text(f.get("file")), text(f.get("counterpart_file"))
    alive = bool(ev) and t1 is not None and ev in t1 and bool(cp) and t2 is not None and cp in t2
    items.append({"prior_id": f.get("id"), "fingerprint": f.get("fingerprint"), "title": f.get("title"),
                  "file": f.get("file"), "verdict": "잔존" if alive else "해소",
                  "matched_id": cur_fp.get(f.get("fingerprint"))})
seen = set(i["fingerprint"] for i in items)
new_ids = [f.get("id") for f in cur.get("findings", []) if f.get("fingerprint") not in seen]
json.dump({"schema": 1, "no_prior_round": False, "items": items, "new_ids": new_ids}, sys.stdout, ensure_ascii=False, indent=1)
' "$ROOT" "$A" "$B"
    ;;
  metrics)
    [ -n "$A" ] || { echo "사용: audit_rounds.sh metrics --tokens N --seconds N <이번 findings.json> [앞선 diff.json]" >&2; exit 2; }
    json_run '
import json, sys
sys.stdout.reconfigure(newline=chr(10))
cur_p, tokens, secs = sys.argv[1], int(sys.argv[2]), int(sys.argv[3])
prior_diff = sys.argv[4] if len(sys.argv) > 4 else ""
cur = json.load(open(cur_p, encoding="utf-8"))
by = {}
for f in cur.get("findings", []):
    for lens in [x.strip() for x in str(f.get("lens", "")).split(",") if x.strip()]:
        d = by.setdefault(lens, {"raised": 0, "confirmed": 0})
        d["raised"] += 1
        if f.get("status") == "confirmed": d["confirmed"] += 1
confirmed = sum(1 for f in cur.get("findings", []) if f.get("status") == "confirmed")
out = {"by_lens": by, "confirmed": confirmed, "tokens": tokens, "seconds": secs,
       "tokens_per_confirmed": (tokens // confirmed) if confirmed else None, "resolved_rate": None}
if prior_diff:
    items = json.load(open(prior_diff, encoding="utf-8")).get("items", [])
    if items:
        out["resolved_rate"] = round(sum(1 for i in items if i.get("verdict") == "해소") / len(items), 3)
json.dump(out, sys.stdout, ensure_ascii=False, indent=1)
' "$A" "$TOKENS" "$SECS" ${B:+"$B"}
    ;;
  *)
    echo "사용: audit_rounds.sh diff|metrics ..." >&2; exit 2 ;;
esac
```

- [ ] **Step 4: 돌려서 통과를 확인하고 커밋한다**

Run: `bash scripts/test_audit.sh 2>&1 | grep -E 'FAIL|PASS='`
Expected: `FAIL=0`.

```bash
git add scripts/audit_rounds.sh scripts/test_audit.sh
git commit -m "앞선 회차 발견의 인용을 다시 대 잔존과 해소를 가르고 측정을 계산한다"
```

---

### Task 3: 렌즈 넷의 출력 계약과 기계에 넘기는 것

**Files:**
- Modify: `skills/lens-grounding/SKILL.md`, `skills/lens-fit/SKILL.md`, `skills/lens-consistency/SKILL.md`, `skills/lens-adversarial/SKILL.md`
- Modify: `scripts/test_audit.sh`

**Interfaces:**
- Produces: 렌즈 넷의 출력 스키마가 `counterpart_file`과 `counterpart`를 필수로 갖고, 결과 칸의 기준이 "지금 무엇이 그렇게 되어 있는지"가 된다. 렌즈마다 「기계에 넘기는 것」 절이 생긴다.

- [ ] **Step 1: 실패하는 테스트를 더한다**

`scripts/test_audit.sh`의 `echo "----"` 앞에 더한다.

```bash
echo "[렌즈 — 발견의 문턱과 기계에 넘기는 것]"
for L in lens-grounding lens-fit lens-consistency lens-adversarial; do
  F="$HERE/skills/$L/SKILL.md"
  check "$L 이 상대편을 필수로 적는다"   "grep -qF 'counterpart' '$F' && grep -qF '상대편을 못 대면 발견이 아니다' '$F'"
  check "$L 이 결과 기준을 적는다"       "grep -qF '지금 무엇이 그렇게 되어 있는지' '$F' && grep -qF '앞으로 벌어질 일을 적지 않는다' '$F'"
  check "$L 에 기계에 넘기는 것 절이 있다" "grep -qF '## 기계에 넘기는 것' '$F'"
done
check "lens-grounding 이 인용 확인을 스크립트에 넘긴다" "grep -qF 'audit_evidence.sh' '$HERE/skills/lens-grounding/SKILL.md'"
check "lens-adversarial 은 넘길 것이 없다고 적는다"      "grep -qF '기계에 넘길 것이 없다' '$HERE/skills/lens-adversarial/SKILL.md'"
```

- [ ] **Step 2: 돌려서 실패를 확인한다**

Run: `bash scripts/test_audit.sh 2>&1 | grep -E 'FAIL|PASS='`
Expected: 이 블록의 단언 열넷이 FAIL.

- [ ] **Step 3: 렌즈 넷을 고친다**

넷의 「출력 스키마」 절 바로 앞에 아래 절을 넣는다. `<이 렌즈가 기계에 넘기는 것>`은 렌즈마다 다른 문장으로 바꿔 넣는다.

```markdown
## 발견의 문턱
발견 하나는 넷을 진다. 짚은 곳(파일과 그 파일의 문장), 상대편(어긋나는 실제 코드나 파일이나 다른 문서의 문장), 원칙(어느 규칙에 걸리는지), 결과다. **상대편을 못 대면 발견이 아니다.** 짚기만 하고 맞댈 것이 없으면 올리지 않는다.

결과 칸에는 **지금 무엇이 그렇게 되어 있는지**를 적는다. 앞으로 벌어질 일을 적지 않는다. 벌어질 법한 일을 적는 칸이 있으면 그 칸이 추정을 부른다.

출력에 `counterpart_file`과 `counterpart`를 담는다. 앞은 상대편이 있는 파일의 레포 상대경로이고 뒤는 그 파일에 있는 그대로의 문장이다. 줄 번호는 담지 않는다 — 줄이 밀리면 회차 사이의 지문이 깨진다.

## 기계에 넘기는 것
<이 렌즈가 기계에 넘기는 것>
```

렌즈마다 마지막 절의 본문은 이렇다.

`lens-grounding`:

```markdown
인용한 문장이 그 파일에 그 글자로 있는지는 `scripts/audit_evidence.sh`가 확인한다. 이 렌즈는 인용이 실재하는지를 스스로 판정하지 않고, 인용한 것이 그 주장을 실제로 받치는지만 본다.
```

`lens-fit`:

```markdown
스키마의 필수 키와 폐쇄 집합의 값과 금지 낱말은 결정론 검사가 먼저 답한다. 이 저장소에서는 `scripts/test_docs_drift.sh`가 그 몫을 진다. 이 렌즈는 그 검사가 답하지 못한 것, 곧 계약이 두 가지로 읽히는지를 본다.
```

`lens-consistency`:

```markdown
같은 이름표에 서로 다른 값이 적혔는지는 호출자가 표로 대조한다. 이 렌즈는 값이 다른 짝 가운데 정당한 좁혀 적기인지 갈리는 것만 받는다.
```

`lens-adversarial`:

```markdown
이 렌즈는 기계에 넘길 것이 없다. 실패 모드와 과설계와 비가역은 전부 판단이라 결정론 검사가 답하지 못한다.
```

넷의 출력 스키마 줄에 `counterpart_file`과 `counterpart`를 더한다. 예를 들어 `lens-grounding`의 스키마 줄이 `"where"`와 `"claim"`을 담고 있으면 그 뒤에 `"counterpart_file": "레포 상대경로", "counterpart": "그 파일에 있는 그대로의 문장",`을 넣는다.

- [ ] **Step 4: 돌려서 통과를 확인하고 커밋한다**

Run: `bash scripts/test_audit.sh 2>&1 | grep -E 'FAIL|PASS='` 그리고 `bash scripts/test_docs_drift.sh 2>&1 | tail -1`
Expected: 둘 다 `FAIL=0`.

```bash
git add skills/lens-grounding/SKILL.md skills/lens-fit/SKILL.md skills/lens-consistency/SKILL.md skills/lens-adversarial/SKILL.md scripts/test_audit.sh
git commit -m "렌즈 넷이 상대편을 필수로 요구하고 기계에 넘길 것을 절로 적는다"
```

---

### Task 4: `lens-readability`를 제안 채널로

**Files:**
- Modify: `skills/lens-readability/SKILL.md`
- Modify: `scripts/test_audit.sh`

**Interfaces:**
- Produces: 이 렌즈의 산출물이 `issues`가 아니라 `suggestions`이고, 항목마다 `where`·`why`·`rewrite`를 담는다. 확정과 기각을 세는 목록에 들어가지 않는다.

- [ ] **Step 1: 실패하는 테스트를 더한다**

`scripts/test_audit.sh`의 `echo "----"` 앞에 더한다.

```bash
echo "[lens-readability — 제안 채널]"
LR="$HERE/skills/lens-readability/SKILL.md"
check "발견이 아니라 제안을 돌려준다고 적는다" "grep -qF '발견이 아니라 제안이다' '$LR'"
check "산출물 이름이 suggestions 다"          "grep -qF 'suggestions' '$LR'"
check "판정 목록에 들어가지 않는다고 적는다"    "grep -qF '확정과 기각을 세는 목록에 들어가지 않는다' '$LR'"
check "기계에 넘기는 것 절이 있다"             "grep -qF '## 기계에 넘기는 것' '$LR'"
```

- [ ] **Step 2: 돌려서 실패를 확인한다**

Run: `bash scripts/test_audit.sh 2>&1 | grep -E 'FAIL|PASS='`
Expected: 이 블록의 단언 넷이 FAIL.

- [ ] **Step 3: 렌즈를 고친다**

첫 문단 뒤에 절을 더한다.

```markdown
## 이 렌즈의 산출물은 발견이 아니라 제안이다
맞댈 상대편이 없는 렌즈이기 때문이다. 다른 렌즈는 문서의 문장을 실제 코드나 다른 문서의 문장과 맞대지만, 전달을 막는 것은 목적에 비추어 판정하므로 짚을 상대편이 없다. 그래서 이 렌즈의 산출물은 `suggestions`이고 항목마다 `where`(어느 문장인지)와 `why`(무엇이 전달을 막는지)와 `rewrite`(고쳐 쓴 문장)를 담는다.

이 목록은 **확정과 기각을 세는 목록에 들어가지 않는다.** 사용자가 보고 고를 뿐이라 반박할 대상이 아니고, 판정 개수가 문체 지적으로 부풀지 않는다. 호출자는 이 목록을 `suggestions.json`에 따로 적는다.

## 기계에 넘기는 것
금지 표현 목록은 `scripts/test_docs_drift.sh`가 먼저 훑는다. 이 렌즈는 그 목록에 없는 것, 곧 목적에 비추어 무엇이 전달을 막는지를 본다.
```

- [ ] **Step 4: 돌려서 통과를 확인하고 커밋한다**

Run: `bash scripts/test_audit.sh 2>&1 | grep -E 'FAIL|PASS='` 그리고 `bash scripts/test_docs_drift.sh 2>&1 | tail -1`
Expected: 둘 다 `FAIL=0`.

```bash
git add skills/lens-readability/SKILL.md scripts/test_audit.sh
git commit -m "전달 렌즈를 판정 목록에서 빼고 고쳐 쓴 문장 제안으로 돌린다"
```

---

### Task 5: `domain-docs` — 결정론 우선 규칙과 값의 경계

**Files:**
- Modify: `skills/domain-docs/SKILL.md`
- Modify: `scripts/test_audit.sh`

**Interfaces:**
- Consumes: Task 3·4가 각 렌즈에 적은 「기계에 넘기는 것」.
- Produces: 결정론 우선 규칙의 소유자가 이 문서이고, 값의 경계("새 프로젝트나 새 모델이나 새 의존이 필요하면 제안하지 않는다")가 여기 있다.

- [ ] **Step 1: 실패하는 테스트를 더한다**

`scripts/test_audit.sh`의 `echo "----"` 앞에 더한다.

```bash
echo "[domain-docs — 결정론 우선]"
DD="$HERE/skills/domain-docs/SKILL.md"
check "결정론 우선 절이 있다"            "grep -qF '## 판단 앞에 기계를 세운다' '$DD'"
check "렌즈는 판단만 한다고 적는다"       "grep -qF '렌즈는 판단만 한다' '$DD'"
check "값의 경계를 적는다"               "grep -qF '새 프로젝트나 새 모델이나 새 의존이 필요하면 제안하지 않는다' '$DD'"
check "판단임을 산출물에 적게 한다"       "grep -qF '판단이라는 사실을 산출물에 적는다' '$DD'"
check "문서 검진이 렌즈를 각각 부르지 않는다" "! grep -qF '각각 호출' '$DD'"
```

- [ ] **Step 2: 돌려서 실패를 확인한다**

Run: `bash scripts/test_audit.sh 2>&1 | grep -E 'FAIL|PASS='`
Expected: 앞의 넷이 FAIL, 마지막 하나는 현재 문구에 따라 갈린다.

- [ ] **Step 3: 문서를 고친다**

「한 번만 띄우는 렌즈의 규율」 절 바로 앞에 절을 더한다.

```markdown
## 판단 앞에 기계를 세운다
이 규칙은 여기가 소유자다. **렌즈는 판단만 한다.** 같은 물음에 답하는 결정론 검사가 있거나 이 저장소 안에서 몇 줄로 쓸 수 있으면 그것을 먼저 돌리고, 렌즈는 그 결과가 답하지 못한 것만 본다. 기계가 답하는 것을 렌즈에 물으면 값을 두 번 치르고 답은 흔들린다.

값의 경계가 이 규칙에 함께 붙는다. **새 프로젝트나 새 모델이나 새 의존이 필요하면 제안하지 않는다.** 기사의 긍정과 부정을 결정론으로 가르려고 분석기를 짓는 것이 그 선 밖이다. 렌즈 하나를 싸게 만들려다 프로젝트를 하나 늘리는 값이 더 크다. 그럴 때는 렌즈가 판단하고, **판단이라는 사실을 산출물에 적는다.**

렌즈마다 무엇을 기계에 넘기는지는 그 렌즈 `SKILL.md`의 「기계에 넘기는 것」 절이 적는다. 그 절이 비어 있으면 넘길 것이 없다는 뜻이지 안 적은 것이 아니다.
```

「문서 검진 방법」 절에서 렌즈를 "각각" 부르라고 적은 문장을 고친다. 지금 문장은 "일반 문서를 쓰거나 고친 뒤에는 `lens-grounding`(사실 정확)과 `lens-fit`(양식과 계약) 두 렌즈를 읽기 전용 서브에이전트로 각각 호출한다"이다. 이것을 다음으로 바꾼다.

```markdown
일반 문서를 쓰거나 고친 뒤에는 `lens-grounding`(사실 정확)과 `lens-fit`(양식과 계약)을 건다. 렌즈마다 따로 띄우지 않고 호출 하나가 그 문서를 한 번 읽고 렌즈를 차례로 적용한다. 합산과 반박은 호출자가 직접 한다 — 파일을 열 수 있는 호출자는 서브에이전트를 하나 더 띄울 이유가 없다.
```

- [ ] **Step 4: 돌려서 통과를 확인하고 커밋한다**

Run: `bash scripts/test_audit.sh 2>&1 | grep -E 'FAIL|PASS='` 그리고 `bash scripts/test_docs_drift.sh 2>&1 | tail -1`
Expected: 둘 다 `FAIL=0`.

```bash
git add skills/domain-docs/SKILL.md scripts/test_audit.sh
git commit -m "판단 앞에 기계를 세우는 규칙과 그 값의 경계를 규율 소유자에 적는다"
```

---

### Task 6: `domain-spec-review`와 `meta-aggregate`

**Files:**
- Modify: `skills/domain-spec-review/SKILL.md`
- Modify: `skills/meta-aggregate/SKILL.md`
- Modify: `scripts/test_audit.sh`

**Interfaces:**
- Consumes: Task 5의 규율 소유자 문장.
- Produces: spec 리뷰가 렌즈마다 서브에이전트를 띄우지 않는다. 집계 계약이 지문과 제안 채널을 안다.

- [ ] **Step 1: 실패하는 테스트를 더한다**

`scripts/test_audit.sh`의 `echo "----"` 앞에 더한다.

```bash
echo "[호출자 — 디스패치와 집계 계약]"
SR="$HERE/skills/domain-spec-review/SKILL.md"
MA="$HERE/skills/meta-aggregate/SKILL.md"
check "spec 리뷰가 렌즈마다 띄우지 않는다"   "! grep -qF '렌즈마다 서브에이전트를' '$SR'"
check "spec 리뷰가 규율 소유자를 가리킨다"   "grep -qF '한 번만 띄우는 렌즈의 규율' '$SR'"
check "집계 계약이 지문을 안다"             "grep -qF 'fingerprint' '$MA'"
check "집계 계약이 제안 채널을 가른다"       "grep -qF 'suggestions' '$MA' && grep -qF '집계 대상이 아니다' '$MA'"
```

- [ ] **Step 2: 돌려서 실패를 확인한다**

Run: `bash scripts/test_audit.sh 2>&1 | grep -E 'FAIL|PASS='`
Expected: 이 블록의 단언 넷 가운데 최소 셋이 FAIL.

- [ ] **Step 3: 두 문서를 고친다**

`domain-spec-review`의 디스패치 절에서 렌즈마다 서브에이전트를 하나씩 띄우라고 적은 문장을 지우고 다음으로 바꾼다.

```markdown
검토 대상 하나에 호출 하나를 띄우고 그 호출이 대상을 한 번 읽고 배정된 렌즈를 차례로 적용한다. 자세가 반대인 `lens-adversarial`만 따로 띄운다. 이 규칙의 소유자는 `domain-docs`의 「한 번만 띄우는 렌즈의 규율」이므로 여기서 다시 정하지 않는다.
```

`meta-aggregate`의 「리뷰 산출물 계약」에 두 줄을 더한다.

```markdown
- `fingerprint` — 짚은 곳의 문장과 상대편과 원칙을 이어 만든 지문이다. 호출자가 `scripts/audit_evidence.sh`로 붙이며 렌즈가 적지 않는다. 회차 사이의 대조가 이 값으로 짝을 맞춘다.
- `suggestions` — `lens-readability`가 돌려주는 고쳐 쓴 문장 목록이다. 발견이 아니므로 집계 대상이 아니다. 확정과 기각을 세는 목록과 섞지 않는다.
```

- [ ] **Step 4: 돌려서 통과를 확인하고 커밋한다**

Run: `bash scripts/test_audit.sh 2>&1 | grep -E 'FAIL|PASS='` 그리고 `bash scripts/test_docs_drift.sh 2>&1 | tail -1`
Expected: 둘 다 `FAIL=0`.

```bash
git add skills/domain-spec-review/SKILL.md skills/meta-aggregate/SKILL.md scripts/test_audit.sh
git commit -m "spec 리뷰의 디스패치를 규율 소유자에 잇고 집계 계약에 지문과 제안 채널을 적는다"
```

---

### Task 7: `domain-llm-runtime`의 배정을 고정표로

**Files:**
- Modify: `skills/domain-llm-runtime/SKILL.md`
- Modify: `scripts/test_audit.sh`

**Interfaces:**
- Produces: 렌즈 배정이 리스크 점수가 아니라 호출 종류별 고정표에서 온다.

- [ ] **Step 1: 실패하는 테스트를 더한다**

`scripts/test_audit.sh`의 `echo "----"` 앞에 더한다.

```bash
echo "[domain-llm-runtime — 고정표 배정]"
LR2="$HERE/skills/domain-llm-runtime/SKILL.md"
check "리스크 점수 절이 사라졌다"        "! grep -qF '리스크 점수는 다음 조건마다 1점' '$LR2'"
check "호출 종류별 고정표가 있다"        "grep -qF '| 호출 종류 |' '$LR2'"
check "회차마다 다시 판단하지 않는다고 적는다" "grep -qF '회차마다 다시 판단하지 않는다' '$LR2'"
```

- [ ] **Step 2: 돌려서 실패를 확인한다**

Run: `bash scripts/test_audit.sh 2>&1 | grep -E 'FAIL|PASS='`
Expected: 이 블록의 단언 셋이 FAIL.

- [ ] **Step 3: 문서를 고친다**

「렌즈 선택 (리스크 비례)」 절 전체를 다음으로 바꾼다.

```markdown
## 렌즈 선택
호출 종류로 정한다. 종류마다 걸 렌즈가 아래 표에 고정돼 있고, 회차마다 다시 판단하지 않는다. 점수를 매기면 매기는 사람마다 값이 달라져 같은 호출에 다른 렌즈가 걸린다.

| 호출 종류 | 무엇으로 가리나 | 걸 렌즈 |
|---|---|---|
| 사용자에게 그대로 보이는 출력 | 사람이 읽는 문장이나 답변을 그대로 낸다 | `lens-grounding` |
| 다운스트림이 파싱하는 출력 | 다른 코드가 형식을 믿고 읽는다 | `lens-fit` |
| 둘 다인 출력 | 사람도 읽고 코드도 파싱한다 | `lens-grounding`, `lens-fit` |
| 비밀이나 개인정보가 닿는 출력 | 키·토큰·개인정보가 입력이나 출력에 있다 | `lens-grounding`, `lens-fit` |
| 위 어디에도 안 걸리는 호출 | 그 밖 | 렌즈를 붙이지 않고 비기능 체크리스트만 적용한다 |

렌즈가 둘이면 `meta-aggregate`로 집계하고 하나면 집계 단계를 두지 않는다.

- `lens-grounding`의 "출처"는 여기서 원래 요청과 제공된 맥락이다.
- `lens-fit`는 다운스트림 계약을 본다. 스키마와 형식은 코드 validator를 먼저 돌리고 실패했을 때만 리뷰 콜을 쓴다. 이것이 `domain-docs`의 「판단 앞에 기계를 세운다」가 이 절차에 걸린 꼴이다.
```

- [ ] **Step 4: 돌려서 통과를 확인하고 커밋한다**

Run: `bash scripts/test_audit.sh 2>&1 | grep -E 'FAIL|PASS='` 그리고 `bash scripts/test_docs_drift.sh 2>&1 | tail -1`
Expected: 둘 다 `FAIL=0`.

```bash
git add skills/domain-llm-runtime/SKILL.md scripts/test_audit.sh
git commit -m "런타임 렌즈 배정을 리스크 점수에서 호출 종류별 고정표로 바꾼다"
```

---

### Task 8: `project-doc-audit` 전면 개정

**Files:**
- Modify: `skills/project-doc-audit/SKILL.md`
- Modify: `scripts/test_audit.sh`

**Interfaces:**
- Consumes: Task 1·2의 스크립트, Task 5의 규율.
- Produces: 걸음 여덟과 기록 파일 넷을 적은 절차 문서.

- [ ] **Step 1: 실패하는 테스트를 더한다**

`scripts/test_audit.sh`의 `echo "----"` 앞에 더한다.

```bash
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
check "실행체를 가리키지 않는다"          "! grep -qF 'self-audit.js' '$PDA'"
check "뽑기 걸음이 사라졌다"              "! grep -qF '진술을 뽑아 이름표로 모은다' '$PDA'"
```

- [ ] **Step 2: 돌려서 실패를 확인한다**

Run: `bash scripts/test_audit.sh 2>&1 | grep -E 'FAIL|PASS='`
Expected: 이 블록의 단언 일곱 가운데 최소 다섯이 FAIL.

- [ ] **Step 3: 걸음 절과 기록 절을 바꾼다**

「걸음」 절 전체를 다음으로 바꾼다.

```markdown
## 걸음
걸음은 여덟이고 순서가 있다. 서브에이전트는 렌즈에만 붙고 나머지는 호출자가 직접 한다.

| 걸음 | 적힌 곳 |
|---|---|
| 대상을 헤아린다 | 「감사 대상 고르기」 절 |
| 기계로 먼저 확인한다 | 「기계 검사 우선」 절 |
| 문서마다 렌즈 호출 하나를 띄운다 | 「렌즈 배정 기준」과 「띄울 때 지킬 것」 절 |
| 저장소 전체에 적대적 렌즈를 띄운다 | 「띄울 때 지킬 것」 절 |
| 인용을 기계로 확인한다 | 「기계가 하는 것」 절 |
| 진술을 대조한다 | 「일관성 대조」 절 |
| 세션이 판정한다 | 「판정」 절 |
| 기록하고 넘긴다 | 「통합 기록」과 「처분」 절 |
```

「중복 제거와 반박검증」 절을 지우고 그 위치에 두 절을 넣는다.

```markdown
## 기계가 하는 것
판단 앞에 기계를 세운다. 이 규칙의 소유자는 `domain-docs`의 「판단 앞에 기계를 세운다」이고 여기서는 이 절차에 걸리는 꼴만 적는다.

- **인용 확인과 지문** — `bash scripts/audit_evidence.sh [--root DIR] <findings.json>`이 발견마다 짚은 문장과 상대편 문장이 실제 파일에 있는지 확인하고 지문을 붙인다. 인용이 없는 발견은 여기서 떨어지며 판단이 개입하지 않는다.
- **중복 제거** — 같은 지문이면 같은 발견이다. 문자열 비교로 끝나므로 에이전트를 띄우지 않는다.
- **회차 대조** — `bash scripts/audit_rounds.sh diff [--root DIR] <앞선 findings.json> <이번 findings.json>`이 잔존과 해소를 가른다. 앞선 발견의 인용이 지금도 있으면 잔존이고 없으면 해소다.
- **측정** — `bash scripts/audit_rounds.sh metrics --tokens N --seconds N <이번 findings.json> [앞선 diff.json]`이 렌즈별 성적과 확정 하나당 값과 앞선 회차의 해소율을 낸다.

## 판정
인용 확인을 지난 발견을 **세션이 판정한다**. 실질성만 본다 — 인용한 규칙에 정말 걸리는지, 정당한 설계 선택이 아닌지다. 사실성은 앞 걸음이 기계로 끝냈다.

판정은 셋이다. 확정(실질 위반이다), 기각(위반이 아니거나 정당한 선택이다), 미판정(판정을 못 내렸다)이다. 판정마다 근거를 적고 그 근거를 사용자에게 보인다. 서브에이전트를 띄우지 않는 것은 발견을 낸 쪽이 렌즈이고 판정하는 쪽이 세션이라 독립이 이미 지켜지기 때문이다.
```

「통합 기록」 절의 파일 목록에 넷째를 더한다.

```markdown
- **`suggestions.json`** — `lens-readability`가 돌려준 고쳐 쓴 문장 제안이다. 발견이 아니므로 판정 목록과 섞지 않는다.
```

「일관성 대조」 절의 세 걸음을 다음으로 바꾼다.

```markdown
- **진술 받기** — 문서마다 도는 렌즈 호출이 발견과 함께 그 문서가 정한 것의 목록을 돌려준다. 조각마다 따로 띄우지 않는다.
- **표 대조** — 호출자가 이름표별 표를 세워 같은 이름표에 서로 다른 값이 적힌 짝을 찾는다. 표 대조는 계산이라 에이전트를 띄우지 않는다.
- **갈리는 짝만 묻기** — 값이 다른데 정당한 좁혀 적기인지 갈리는 짝만 `lens-consistency`에 준다.
```

- [ ] **Step 4: 돌려서 통과를 확인하고 커밋한다**

Run: `bash scripts/test_audit.sh 2>&1 | grep -E 'FAIL|PASS='` 그리고 `bash scripts/test_docs_drift.sh 2>&1 | tail -1`
Expected: 둘 다 `FAIL=0`.

```bash
git add skills/project-doc-audit/SKILL.md scripts/test_audit.sh
git commit -m "감사 절차를 걸음 여덟으로 바꾸고 기계가 하는 것과 세션이 판정하는 것을 가른다"
```

---

### Task 9: 실행체 제거와 계약 테스트 정리

**Files:**
- Delete: `.claude/workflows/self-audit.js`, `scripts/test_self_audit.sh`
- Modify: `.claude-plugin/plugin.json`, `scripts/audit_targets.sh`, `scripts/test_audit.sh`

**Interfaces:**
- Consumes: Task 1~8.
- Produces: `bash scripts/audit_targets.sh [--root DIR]` → 대상 문서의 레포 상대경로를 한 줄에 하나씩 낸다. `--limit`과 조각 출력이 사라진다.

- [ ] **Step 1: 실패하는 테스트를 더한다**

`scripts/test_audit.sh`의 `echo "----"` 앞에 더한다. 기존 `test_self_audit.sh`에서 살아남는 단언은 회차 기록의 형태를 보는 것들인데, 실제 회차 대신 픽스처 폴더로 검사한다.

```bash
echo "[실행체가 사라졌다]"
check "워크플로 파일이 없다"           "[ ! -f '$HERE/.claude/workflows/self-audit.js' ]"
check "매니페스트가 workflows 를 선언하지 않는다" "! grep -qF 'workflows' '$HERE/.claude-plugin/plugin.json'"
check "옛 계약 테스트가 없다"          "[ ! -f '$HERE/scripts/test_self_audit.sh' ]"

echo "[audit_targets.sh — 대상 목록만 낸다]"
AT="$HERE/scripts/audit_targets.sh"
check "문턱 인자가 사라졌다"           "! grep -qF -- '--limit' '$AT'"
AT_OUT="$(bash "$AT" 2>/dev/null || true)"
check "한 줄에 경로 하나만 낸다"       "! printf '%s' \"\$AT_OUT\" | grep -q \$'\\t'"
check "대상이 하나 이상이다"           "[ -n \"\$AT_OUT\" ]"
check "지난 기록은 대상이 아니다"      "! printf '%s' \"\$AT_OUT\" | grep -q '^docs/superpowers/'"

echo "[회차 기록의 형태 — 픽스처로 검사한다]"
RT="$(mktemp -d)"; mkdir -p "$RT/round"
cat > "$RT/round/run.json" <<'FIXTURE'
{ "schema": 1, "executor": "session", "commit": "abc", "tree_clean": true, "completed": true,
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
check "run.json 이 파싱된다"           "rj 'import json,sys; json.load(open(sys.argv[1],encoding=\"utf-8\"))' run.json"
check "findings.json 의 status 가 닫힌 집합이다" "rj 'import json,sys; d=json.load(open(sys.argv[1],encoding=\"utf-8\")); sys.exit(0 if all(f[\"status\"] in (\"confirmed\",\"rejected\",\"undetermined\",\"derived\") for f in d[\"findings\"]) else 1)' findings.json"
check "발견마다 상대편과 지문이 있다"   "rj 'import json,sys; d=json.load(open(sys.argv[1],encoding=\"utf-8\")); sys.exit(0 if all(f.get(\"counterpart\") and f.get(\"fingerprint\") for f in d[\"findings\"]) else 1)' findings.json"
check "diff.json 이 파싱된다"          "rj 'import json,sys; json.load(open(sys.argv[1],encoding=\"utf-8\"))' diff.json"
check "suggestions.json 이 파싱된다"   "rj 'import json,sys; json.load(open(sys.argv[1],encoding=\"utf-8\"))' suggestions.json"
rm -rf "$RT"
```

- [ ] **Step 2: 돌려서 실패를 확인한다**

Run: `bash scripts/test_audit.sh 2>&1 | grep -E 'FAIL|PASS='`
Expected: 실행체 관련 단언 셋과 `audit_targets.sh` 단언 둘이 FAIL.

- [ ] **Step 3: 실행체를 지우고 대상 스크립트를 줄인다**

```bash
git rm .claude/workflows/self-audit.js scripts/test_self_audit.sh
```

`.claude-plugin/plugin.json`에서 `workflows` 키와 그 값을 지운다.

`scripts/audit_targets.sh`를 다음으로 바꾼다.

```bash
#!/usr/bin/env bash
# 감사 대상 문서를 낸다 — 앞으로도 읽히고 고쳐질 문서만이다. 스펙과 계획과 지난 기록과 인수인계는
# 그때의 판단을 남긴 것이라 뺀다. 목록을 손으로 적지 않고 색인에서 도출한다.
# 조각내기와 입력 문턱은 두지 않는다 — 렌즈 호출 하나가 문서 하나를 통째로 받는다.
# 사용: audit_targets.sh [--root DIR]   (레포 상대경로를 한 줄에 하나씩)
set -euo pipefail
HERE="$(cd "$(dirname "$0")/.." && pwd)"
ROOT="$HERE"
while [ "$#" -gt 0 ]; do
  case "$1" in
    --root) ROOT="$2"; shift 2 ;;
    *) shift ;;
  esac
done
cd "$ROOT"
git ls-files '*.md' \
  | { grep -v '^docs/superpowers/' || true; } \
  | { grep -vE '(^|/)HANDOFF-[^/]*$' || true; } \
  | while IFS= read -r f; do
      head -12 "$f" | grep -qi 'superseded' && continue
      printf '%s\n' "$f"
    done
```

- [ ] **Step 4: 돌려서 통과를 확인하고 커밋한다**

Run: 전체 테스트 명령과 `claude plugin validate ./`
Expected: `ALL PASS`, 검증은 `version` 경고 하나.

```bash
git add -A
git commit -m "워크플로 실행체를 지우고 대상 스크립트를 목록만 내게 줄인다"
```

---

### Task 10: `README`와 `CLAUDE.md`

**Files:**
- Modify: `README.md`, `CLAUDE.md`
- Modify: `scripts/test_audit.sh`

**Interfaces:**
- Consumes: Task 9의 삭제.
- Produces: 두 안내 문서가 실행체를 가리키지 않고 이 레포에 걸린 훅을 실제 배선대로 적는다.

- [ ] **Step 1: 실패하는 테스트를 더한다**

`scripts/test_audit.sh`의 `echo "----"` 앞에 더한다.

```bash
echo "[안내 문서 — 실행체가 사라진 것을 반영한다]"
check "README 가 실행체를 가리키지 않는다"   "! grep -qF 'self-audit.js' '$HERE/README.md'"
check "CLAUDE.md 가 실행체를 가리키지 않는다" "! grep -qF 'self-audit.js' '$HERE/CLAUDE.md'"
check "CLAUDE.md 가 감사 기록 봉인을 적는다"  "grep -qF 'seal_reviews.sh' '$HERE/CLAUDE.md'"
check "CLAUDE.md 가 읽기 전용 거부를 적는다"  "grep -qF '읽기 전용' '$HERE/CLAUDE.md'"
```

- [ ] **Step 2: 돌려서 실패를 확인한다**

Run: `bash scripts/test_audit.sh 2>&1 | grep -E 'FAIL|PASS='`
Expected: 뒤의 둘이 FAIL. 앞의 둘은 현재 문구에 따라 갈린다.

- [ ] **Step 3: 두 문서를 고친다**

`README.md`에서 워크플로 실행체를 언급한 문장이 있으면 지운다. `CLAUDE.md`의 첫 절에 한 문단을 더한다.

```markdown
이 레포에는 훅 넷이 걸린다. spec과 plan을 쓰면 Stop 게이트가 리뷰를 요구하고, 그 밖의 문서를 고치면 검진 넛지가 뜬다. 세션이 시작될 때 `scripts/seal_reviews.sh`가 `docs/superpowers/reviews/` 아래 기록을 읽기 전용으로 봉인하고, 읽기 전용 파일에 Write나 Edit을 걸면 훅이 사유와 함께 거부한다. 기록을 고치려다 거부당하면 훅 고장이 아니라 봉인이다.
```

- [ ] **Step 4: 돌려서 통과를 확인하고 커밋한다**

Run: 전체 테스트 명령
Expected: `ALL PASS`.

```bash
git add README.md CLAUDE.md scripts/test_audit.sh
git commit -m "안내 문서가 실행체 대신 이 레포에 걸린 훅 넷을 적는다"
```

---

### Task 11: 새 절차로 회차 하나를 돌린다

**Files:**
- Create (이 걸음이 만든다): `docs/superpowers/reviews/<날짜>-self-audit[-N].md`와 같은 이름의 폴더

**Interfaces:**
- Consumes: Task 1~10 전부.
- Produces: 기록 파일 넷을 가진 회차 하나. `run.json`의 `metrics`가 렌즈별 성적과 확정 하나당 값과 앞선 회차의 해소율을 담는다.

- [ ] **Step 1: 작업 트리가 깨끗한지 확인한다**

Run: `git status --short`
Expected: 비어 있음. 비어 있지 않으면 커밋하거나 레포 밖으로 옮기고 다시 확인한다.

- [ ] **Step 2: 절차대로 회차를 돈다**

`skills/project-doc-audit/SKILL.md`의 걸음 여덟을 그대로 따른다. 세션이 몰고 렌즈만 서브에이전트로 띄운다. 회차 이름은 `<날짜>-self-audit`이고 같은 이름이 이미 있으면 `-2`를 붙인다.

- [ ] **Step 3: 인용 확인과 대조와 측정을 스크립트로 돌린다**

```bash
bash scripts/audit_evidence.sh docs/superpowers/reviews/<회차>/findings.json > /tmp/checked.json
bash scripts/audit_rounds.sh diff docs/superpowers/reviews/2026-09-05-self-audit/findings.json docs/superpowers/reviews/<회차>/findings.json
bash scripts/audit_rounds.sh metrics --tokens <실측> --seconds <실측> docs/superpowers/reviews/<회차>/findings.json
```

- [ ] **Step 4: 요약문에 뿌리와 물음과 호출 수를 붙이고 봉인한다**

```bash
bash scripts/seal_reviews.sh "docs/superpowers/reviews/<회차>.md"
```

- [ ] **Step 5: 성공 기준을 확인한다**

- 서브에이전트가 스물다섯 이하인가.
- 인용이 실재하지 않는 발견이 LLM 판단 없이 떨어졌는가.
- 같은 기록으로 대조를 두 번 계산하면 같은 결과가 나오는가.
- `run.json`에서 렌즈별 확정 수와 확정 하나당 값과 앞선 회차의 해소율을 읽을 수 있는가.

- [ ] **Step 6: 전체 테스트를 돌리고 커밋한다**

Run: 전체 테스트 명령
Expected: `ALL PASS`.

```bash
git add "docs/superpowers/reviews/<회차>.md" "docs/superpowers/reviews/<회차>/"
git commit -m "새 절차로 회차 하나를 돌려 기록 넷을 남긴다"
```

---

## 자가 검토

**spec 커버리지.** 「발견의 계약」은 Task 3·4가, 「회차의 걸음」은 Task 8이, 「코드와 LLM의 경계」는 Task 1·2·8이, 「렌즈가 기계에 넘기는 것」은 Task 3·4·5가, 「기록과 측정」은 Task 2·8·9가, 「무엇이 사라지나」는 Task 9가, 「새로 생기는 것」은 Task 1·2가, 「계약 테스트」는 Task 1~10이 `scripts/test_audit.sh`를 쌓아 올리며, 「문서 변경 범위」의 일곱 항목은 Task 3·4·5·6·7·8·10이 하나씩 맡는다. 「성공 기준」 다섯은 Task 11 Step 5가 확인한다.

**빈칸 훑기.** 미완성 표현을 쓰지 않았다. 스크립트 둘의 코드와 테스트 블록의 코드를 그대로 담았고, 문서 수정은 넣을 문장을 그대로 적었다. Task 11만 회차 이름과 실측 값을 `<...>`로 두었는데, 이는 실행할 때 정해지는 값이라 미리 적을 수 없다.

**이름 일치.** `evidence_found`·`counterpart_found`·`fingerprint`(Task 1)를 Task 2의 `diff`와 Task 9의 기록 단언이 그대로 쓴다. `counterpart_file`·`counterpart`(Task 3)를 Task 1의 스크립트가 읽는다. `by_lens`·`tokens_per_confirmed`·`resolved_rate`(Task 2)를 Task 8의 절차 문서와 Task 11의 성공 기준이 그대로 부른다. `suggestions`(Task 4)를 Task 6의 집계 계약과 Task 8의 기록 절이 그대로 쓴다. 판정 값(`확정`·`기각`·`미판정`)과 대조 값(`잔존`·`해소`)은 spec의 한글 그대로다.

**알려진 제약.** 회차 대조는 문장만 바뀌고 문제가 남은 것을 해소로 잘못 센다. spec이 그 오차를 택한 근거를 적었고 이번 회차의 렌즈가 새 발견으로 잡는다. `findings.json`이 기각을 따로 두지 않고 `status`로 가르는 것은 측정이 낸 수를 세려면 기각도 렌즈를 달고 있어야 하기 때문이며, spec의 기록 절과 어긋나지 않는다.

이 계획은 사용자 결정으로 렌즈 리뷰를 건너뛴다. 아래 마커는 리뷰를 지났다는 뜻이 아니라 게이트를 사용자 결정으로 통과시켰다는 뜻이다.

<!-- spec-review: passed -->
