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
# mapfile 은 bash 4 부터라 mac 의 기본 bash 3.2 에서 조용히 빈 배열을 만든다. 봉인이 안 걸린 채
# 통과하면 기록이 열려 있는데 아무도 모른다. while read 로 바꿔 어느 bash 에서나 같게 돈다.
# 반복문 본문의 마지막 명령이 조건 결합이면 값이 빌 때 상태 1 로 끝나 set -e 아래에서 죽으므로
# if 로 감싼다.
if [ "${#files[@]}" -eq 0 ]; then
  while IFS= read -r rel; do
    if [ -n "$rel" ]; then files+=("$ROOT/$rel"); fi
  done < <(cd "$ROOT" && git ls-tree -r --name-only HEAD -- docs/superpowers/reviews 2>/dev/null)
fi
n=0
for f in "${files[@]}"; do
  [ -f "$f" ] || continue
  chmod a-w "$f"
  n=$((n+1))
done
echo "sealed: $n"
