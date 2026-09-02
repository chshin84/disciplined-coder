#!/usr/bin/env bash
# 감사 대상 문서를 조각으로 낸다 — 한 줄에 조각 하나, 경로<TAB>시작 줄<TAB>끝 줄(1부터, 양끝 포함).
# --limit 이면 문턱 값(UTF-8 문자 수)만 낸다. 이 값은 렌즈 호출 하나의 입력 상한이며 여기 한 곳에만 둔다.
# --root DIR 이면 그 저장소를 본다(기본은 이 레포). 대상은 git 이 추적하는 .md 전부에서 성질로 뺀다 —
# docs/superpowers/ 아래(spec·plan·기록은 domain-docs 의 타입 표가 감사 대상 아님으로 정한 타입이고 폴더로
# 도출된다), 이름이 HANDOFF- 로 시작하는 파일, 머리 열두 줄 안에 superseded 가 있는 문서. 손으로 적은 목록은
# 두지 않는다. 문턱을 넘는 문서는 ## 절로, 절도 넘으면 ### 절로, 그것도 넘으면 문단 경계로 자른다.
set -euo pipefail
HERE="$(cd "$(dirname "$0")/.." && pwd)"
. "$HERE/scripts/_json_valid.sh"   # json_run — 파이썬 이름은 여기가 고른다
LIMIT=5000
ROOT="$HERE"
while [ "$#" -gt 0 ]; do
  case "$1" in
    --limit) echo "$LIMIT"; exit 0 ;;
    --root) ROOT="$2"; shift 2 ;;
    *) echo "audit_targets.sh: 모르는 인자 $1" >&2; exit 2 ;;
  esac
done
cd "$ROOT"
LIST="$(mktemp)"
git ls-files '*.md' | grep -v '^docs/superpowers/' | grep -vE '(^|/)HANDOFF-' | while IFS= read -r f; do
  head -12 "$f" | grep -qi superseded && continue
  printf '%s\n' "$f"
done > "$LIST"
# 파이프와 히어독은 표준 입력을 두고 부딪히므로 목록은 파일로 넘긴다.
json_run '
import sys, io
limit = int(sys.argv[1]); listfile = sys.argv[2]

def size(lines, s, e):  # 1부터, 양끝 포함
    return len("\n".join(lines[s-1:e]))

def split_by(lines, s, e, prefix):
    # prefix 로 시작하는 줄에서 자른다. 첫 조각은 s 부터 첫 제목 전까지(머리·frontmatter)다.
    cuts = [i for i in range(s, e+1) if lines[i-1].startswith(prefix)]
    if not cuts or cuts == [s]:
        return [(s, e)]
    bounds = ([s] if cuts[0] != s else []) + cuts
    out = []
    for i, b in enumerate(bounds):
        nxt = bounds[i+1]-1 if i+1 < len(bounds) else e
        out.append((b, nxt))
    return out

def split_paragraphs(lines, s, e):
    # 빈 줄 경계로 문단을 나눠 문턱까지 채운다. 한 문단이 문턱을 넘으면 그 문단은 통째로 한 조각이다.
    paras, cur = [], s
    for i in range(s, e+1):
        if lines[i-1].strip() == "" and i > cur:
            paras.append((cur, i-1)); cur = i+1
    if cur <= e: paras.append((cur, e))
    out, start, end = [], None, None
    for (ps, pe) in paras:
        if start is None: start, end = ps, pe; continue
        if size(lines, start, pe) <= limit: end = pe
        else: out.append((start, end)); start, end = ps, pe
    if start is not None: out.append((start, end))
    return out

def fragments(lines, s, e):
    if size(lines, s, e) <= limit: return [(s, e)]
    out = []
    for (a, b) in split_by(lines, s, e, "## "):
        if size(lines, a, b) <= limit: out.append((a, b)); continue
        for (c, d) in split_by(lines, a, b, "### "):
            if size(lines, c, d) <= limit: out.append((c, d))
            else: out.extend(split_paragraphs(lines, c, d))
    return out

for path in io.open(listfile, encoding="utf-8").read().split("\n"):
    if not path: continue
    lines = io.open(path, encoding="utf-8").read().split("\n")
    if lines and lines[-1] == "": lines = lines[:-1]
    if not lines: continue
    for (a, b) in fragments(lines, 1, len(lines)):
        sys.stdout.write(f"{path}\t{a}\t{b}\n")
' "$LIMIT" "$LIST"
rm -f "$LIST"
