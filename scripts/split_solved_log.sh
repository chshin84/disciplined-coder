#!/usr/bin/env bash
# 오답노트 한 덩어리 로그를 색인과 항목별 본문 파일로 가른다.
# 여러 번 돌려도 결과가 같다 — 다음 줄이 포인터인 항목은 이미 갈린 것으로 보고 건너뛴다.
# 갈리지 않는 항목(옛 한 줄 형식)은 그대로 두고 개수만 알린다. 뜻을 옮기는 일은 사람이 한다.
# 색인 줄은 굵은 채로 남긴다 — 아직 지시사항으로 안 고쳤다는 표시이고, 고칠 때 굵기를 벗긴다.
set -u
LOG="${1:?로그 경로가 필요하다}"; BDIR="${2:?백업 디렉터리가 필요하다}"; LABEL_IN="${3:-}"
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
#
# **본문을 제자리에 바로 쓰지 않고 임시 폴더에 모았다가 옮긴다.** 전에는 파이썬이 본문을 제자리에
# 하나씩 쓰다가 중간에 죽으면 본문 몇 개만 남고 색인은 옛 형식 그대로였다. 그런데 쪼개짐 판정은
# 본문 파일이 하나라도 있으면 쪼개진 것으로 보므로, 다음 세션의 스캐폴드가 머리말을 색인 형식으로
# 갈아끼워 한 파일이 '이 파일은 색인이다'라고 선언하면서 본문은 옛 형식인 상태로 굳었다. 개편
# 권유도 더는 안 떠 사람이 되돌릴 계기를 잃는다.
#
# **사본도 실제로 고칠 것이 있을 때만 뜬다.** 전에는 굵은 불릿이 있으면 무조건 떴는데, 다 쪼갠
# 로그에도 색인 줄은 굵은 채로 남으므로 돌릴 때마다 내용이 같은 사본이 쌓였다. 정작 복구가
# 필요한 순간에 손대기 전 원본이 어느 것인지 가릴 수 없게 된다 — 이 스크립트가 주석에서 막겠다고
# 적어 둔 바로 그 상태다.
STAMP="$(date +%Y%m%d-%H%M%S 2>/dev/null || echo unknown)"
# 이름표는 부르는 쪽이 준다. 스캐폴드가 이미 PC 로그에 pc 를, 프로젝트 로그에 프로젝트 폴더
# 이름을 쓰고 있으므로 같은 값을 받아 한 규칙으로 모은다. 부모 폴더 이름으로 지으면 모든 레포의
# 프로젝트 로그가 'docs' 하나로 뭉쳐 어느 레포의 사본인지 가릴 수 없다.
# 안 받았으면 이름표 없이 뜬다 — 부모 폴더 이름으로 되돌아가면 두 규칙이 다시 갈린다.
LABEL="$(printf '%s' "$LABEL_IN" | tr -c 'A-Za-z0-9._-' '_')"
[ -n "$LABEL" ] && LABEL=".$LABEL"
# 쪼갤 것이 하나도 없으면 사본을 뜨지 않는다 — 뜨면 다시 돌릴 때마다 백업 폴더가 늘어 어느 것이
# 어느 회차인지 가릴 수 없게 된다(멱등성은 연속 두 번 실행으로만 드러난다).
if ! grep -qE '^[-*+][[:space:]]+\*\*' "$LOG" 2>/dev/null; then
  echo "손으로 가를 항목 0개"
  exit 0
fi
TMP="$(mktemp "$LOG.XXXXXX")" || { echo "임시 파일을 만들지 못했다" >&2; exit 2; }
# 본문을 모을 임시 폴더. 본문 폴더와 같은 부모에 둔다 — 다른 디스크면 옮기기가 원자적이지 않다.
TMPB="$(mktemp -d "$DIR.tmp.XXXXXX")" || { rm -f "$TMP"; echo "임시 폴더를 만들지 못했다" >&2; exit 2; }
# 어디서 죽어도 임시 것들을 남기지 않는다. 제자리로 옮긴 뒤에는 지울 것이 없다.
trap 'rm -rf "$TMPB"; rm -f "$TMP"' EXIT
# 한글이 stdout 으로 나가므로 인코딩을 못 박는다 — 이 PC 의 파이썬 기본값은 cp949 라
# 그냥 찍으면 grep 이 UTF-8 바이트를 찾다 못 찾는다.
PYTHONIOENCODING=utf-8 "$PY" - "$LOG" "$DIR" "$TMP" "$TMPB" <<'PY'
import io, os, re, sys
log, bodydir, tmp, tmpbody = sys.argv[1], sys.argv[2], sys.argv[3], sys.argv[4]
# bodydir 은 이미 있는 본문을 읽어 이름 충돌을 피하는 데만 쓰고, 새 본문은 tmpbody 에 쓴다.
# 제자리에 바로 쓰면 중간에 죽었을 때 본문 몇 개만 남아 로그가 쪼개진 것으로 오판된다.
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
    os.makedirs(tmpbody, exist_ok=True)
    name = slug(title, taken)
    stripped = [b[2:] if b.startswith("  ") else b for b in body]
    with io.open(os.path.join(tmpbody, name + ".md"), "w", encoding="utf-8", newline="\n") as fh:
        fh.write("# " + title + "\n\n" + "\n".join(stripped).strip() + "\n")
    out.append(head)
    out.append("  → solved_problems/" + name + ".md")
    i = j

io.open(tmp, "w", encoding="utf-8", newline="\n").write("\n".join(out))
sys.stdout.write("손으로 가를 항목 %d개\n" % manual)
PY
rc=$?
if [ "$rc" -ne 0 ]; then echo "가르지 못했다" >&2; exit 2; fi

# 새로 쓴 본문이 하나도 없으면 이번 회차는 고칠 것이 없었던 것이다. 파이썬은 본문을 쓸 때만
# 색인 줄에 포인터를 더하므로, 임시 폴더가 비었다는 것은 색인도 그대로라는 뜻이다.
# 그때는 사본도 뜨지 않는다 — 뜨면 돌릴 때마다 내용이 같은 사본이 쌓인다.
moved=""
for f in "$TMPB"/*.md; do [ -f "$f" ] && { moved="yes"; break; }; done
if [ -z "$moved" ]; then
  echo "새로 가른 항목 0개"
  exit 0
fi

# 여기서 처음 사본을 뜬다. 못 뜨면 아무것도 옮기지 않는다 — 사본이 유일한 복구 수단이다.
if ! mkdir -p "$BDIR" 2>/dev/null || ! cp "$LOG" "$BDIR/solved_problems$LABEL.$STAMP.md" 2>/dev/null; then
  echo "사본을 뜨지 못해 아무것도 하지 않았다($BDIR 에 쓸 수 있게 하라)" >&2
  exit 2
fi

# 본문을 먼저 옮기고 색인을 마지막에 옮긴다. 색인을 못 옮기면 이번에 옮긴 본문을 도로 치운다 —
# 본문만 남으면 쪼개짐 판정이 참이 되어 옛 형식 색인에 최신 머리말이 씌워진다.
if ! mkdir -p "$DIR" 2>/dev/null; then
  echo "본문 폴더를 만들지 못해 아무것도 하지 않았다($DIR)" >&2
  exit 2
fi
placed=""
for f in "$TMPB"/*.md; do
  [ -f "$f" ] || continue
  if mv "$f" "$DIR/$(basename "$f")" 2>/dev/null; then
    placed="$placed
$DIR/$(basename "$f")"
  else
    echo "본문을 옮기지 못했다: $(basename "$f")" >&2
    printf '%s' "$placed" | while IFS= read -r p; do [ -n "$p" ] && rm -f "$p"; done
    exit 2
  fi
done
if ! mv "$TMP" "$LOG" 2>/dev/null; then
  echo "색인을 옮기지 못해 이번에 만든 본문을 도로 치웠다 — 로그는 손대기 전 그대로다" >&2
  printf '%s' "$placed" | while IFS= read -r p; do [ -n "$p" ] && rm -f "$p"; done
  exit 2
fi
