#!/usr/bin/env bash
# 기록을 봉인한다 — 파일 인자를 읽기 전용(chmod a-w)으로 만들고, 파일 인자가 없으면 --root(기본은 레포 루트)의
# HEAD 에 있는 docs/superpowers/reviews/ 아래 파일 전부를 그렇게 한다. 여러 번 돌려도 같다(IDEMPOTENT).
# 읽기 전용 속성은 만든 쪽의 의도라 어느 저장소에서든 같은 뜻이고, 훅(hooks/readonly_pretooluse.sh)은
# 이 속성만 읽는다. git은 이 속성을 옮기지 않으므로 새 클론에서는 SessionStart 훅이 이 스크립트를 다시 돈다.
set -euo pipefail
HERE="$(cd "$(dirname "$0")/.." && pwd)"
ROOT="$HERE"; files=()
while [ "$#" -gt 0 ]; do
  case "$1" in
    --root) ROOT="$2"; shift 2 ;;
    *) files+=("$1"); shift ;;
  esac
done
if [ "${#files[@]}" -eq 0 ]; then
  mapfile -t files < <(cd "$ROOT" && git ls-tree -r --name-only HEAD -- docs/superpowers/reviews 2>/dev/null | sed "s|^|$ROOT/|")
fi
n=0
for f in "${files[@]}"; do
  [ -f "$f" ] || continue
  chmod a-w "$f"
  n=$((n+1))
done
echo "sealed: $n"
