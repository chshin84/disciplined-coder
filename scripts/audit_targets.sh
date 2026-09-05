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
    *) echo "사용: audit_targets.sh [--root DIR]" >&2; exit 2 ;;
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
