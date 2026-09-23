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
# awk 하나로 거른다. 파일마다 head 와 grep 을 띄우면 문서 수만큼 프로세스가 뜬다.
# 머리 12줄에 superseded 가 있으면(대소문자 무시) 대체된 설계 문서라 뺀다. 못 여는 파일은 남긴다.
git ls-files '*.md' | LC_ALL=C awk '
  /^docs\/superpowers\// || /(^|\/)HANDOFF-[^\/]*$/ { next }
  {
    f = $0; hit = 0
    for (i = 0; i < 12 && (getline line < f) > 0; i++) if (tolower(line) ~ /superseded/) { hit = 1; break }
    close(f)
    if (!hit) print f
  }'
