#!/usr/bin/env bash
# 오답노트 한 덩어리 로그를 색인과 항목별 본문 파일로 가른다.
# 여러 번 돌려도 결과가 같다 — 다음 줄이 포인터인 항목은 이미 갈린 것으로 보고 건너뛴다.
# 갈리지 않는 항목(옛 한 줄 형식)은 그대로 두고 개수만 알린다. 뜻을 옮기는 일은 사람이 한다.
# 색인 줄은 굵은 채로 남긴다 — 아직 지시사항으로 안 고쳤다는 표시이고, 고칠 때 굵기를 벗긴다.
set -u
LOG="${1:?로그 경로가 필요하다}"; BDIR="${2:?백업 디렉터리가 필요하다}"
DIR="${LOG%.md}"

[ -f "$LOG" ] || { echo "로그가 없다: $LOG" >&2; exit 2; }

# 이 레포 관례 — python3 를 먼저 보고 없으면 python 으로 떨어진다. 이 PC 의 python3 가 한때
# 스토어 스텁이었던 이력이 오답노트에 있어 둘 다 시도한다.
PY=""
for c in python3 python; do command -v "$c" >/dev/null 2>&1 && { PY="$c"; break; }; done
[ -n "$PY" ] || { echo "파이썬을 찾지 못했다" >&2; exit 2; }

# 사본이 유일한 복구 수단이다(이 로그는 git 밖일 수 있다) — 못 뜨면 아무것도 하지 않는다.
# 본문 폴더도 여기서 만들지 않는다. 파이썬이 죽었을 때 빈 폴더가 남으면 쪼개짐 판정이
# '안 쪼개짐'으로 나와 다음 세션에 개편 권유가 다시 뜬다.
STAMP="$(date +%Y%m%d-%H%M%S 2>/dev/null || echo unknown)"
LABEL="$(printf '%s' "$(basename "$(dirname "$LOG")")" | tr -c 'A-Za-z0-9._-' '_')"
# 쪼갤 것이 하나도 없으면 사본을 뜨지 않는다 — 뜨면 다시 돌릴 때마다 백업 폴더가 늘어 어느 것이
# 어느 회차인지 가릴 수 없게 된다(멱등성은 연속 두 번 실행으로만 드러난다).
if ! grep -qE '^[-*+][[:space:]]+\*\*' "$LOG" 2>/dev/null; then
  echo "손으로 가를 항목 0개"
  exit 0
fi
if ! mkdir -p "$BDIR" 2>/dev/null || ! cp "$LOG" "$BDIR/solved_problems.$LABEL.$STAMP.md" 2>/dev/null; then
  echo "사본을 뜨지 못해 아무것도 하지 않았다($BDIR 에 쓸 수 있게 하라)" >&2
  exit 2
fi

TMP="$(mktemp "$LOG.XXXXXX")" || { echo "임시 파일을 만들지 못했다" >&2; exit 2; }
# 한글이 stdout 으로 나가므로 인코딩을 못 박는다 — 이 PC 의 파이썬 기본값은 cp949 라
# 그냥 찍으면 grep 이 UTF-8 바이트를 찾다 못 찾는다.
PYTHONIOENCODING=utf-8 "$PY" - "$LOG" "$DIR" "$TMP" <<'PY'
import io, os, re, sys
log, bodydir, tmp = sys.argv[1], sys.argv[2], sys.argv[3]
text = io.open(log, encoding="utf-8").read()
# splitlines() 는 U+2028/U+2029 에서도 쪼갠다 — 이 레포가 이미 겪은 함정이라 "\n" 으로만 나눈다.
lines = text.split("\n")

ITEM = re.compile(r"^[-*+][ \t]+\*\*")
PTR = re.compile(r"^\s*→\s*solved_problems/")

def slug(title, taken):
    s = re.sub(r"[*`\[\]()]", "", title).strip()
    s = re.sub(r"\s+", "-", s)
    s = re.sub(r"[^0-9A-Za-z가-힣-]", "", s)[:40].strip("-") or "item"
    base, n = s, 2
    while s in taken:
        s = "%s-%d" % (base, n)
        n += 1
    taken.add(s)
    return s

out, i, taken, manual = [], 0, set(), 0
if os.path.isdir(bodydir):
    for f in os.listdir(bodydir):
        if f.endswith(".md"):
            taken.add(f[:-3])

while i < len(lines):
    line = lines[i]
    if not ITEM.match(line):
        out.append(line); i += 1; continue
    # 이미 갈린 항목이면 그대로 둔다 — 이것이 멱등성의 전부다.
    if i + 1 < len(lines) and PTR.match(lines[i + 1]):
        out.append(line); out.append(lines[i + 1]); i += 2; continue
    head, body, j = line, [], i + 1
    while j < len(lines):
        if lines[j].startswith("  "):
            body.append(lines[j]); j += 1; continue
        if lines[j].strip() == "" and j + 1 < len(lines) and lines[j + 1].startswith("  "):
            body.append(lines[j]); j += 1; continue
        break
    if not any(b.strip() for b in body):
        out.append(head); i += 1; manual += 1; continue   # 옛 한 줄 형식은 손으로 가른다
    title = re.sub(r"^[-*+][ \t]+", "", head).strip()
    os.makedirs(bodydir, exist_ok=True)
    name = slug(title, taken)
    stripped = [b[2:] if b.startswith("  ") else b for b in body]
    with io.open(os.path.join(bodydir, name + ".md"), "w", encoding="utf-8", newline="\n") as fh:
        fh.write("# " + title + "\n\n" + "\n".join(stripped).strip() + "\n")
    out.append(head)
    out.append("  → solved_problems/" + name + ".md")
    i = j

io.open(tmp, "w", encoding="utf-8", newline="\n").write("\n".join(out))
sys.stdout.write("손으로 가를 항목 %d개\n" % manual)
PY
rc=$?
if [ "$rc" -ne 0 ]; then rm -f "$TMP"; echo "가르지 못했다" >&2; exit 2; fi
mv "$TMP" "$LOG"
