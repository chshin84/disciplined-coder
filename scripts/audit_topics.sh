#!/usr/bin/env bash
# 이름표 목록을 도출한다 — 정본의 원칙 ID 전부, 정본의 ## 절 제목, skills/ 아래 스킬 이름, commands/ 아래
# 명령 이름을 합쳐 한 줄에 하나씩 낸다. 목록이 닫혀 있으므로 모으기가 문자열 일치로 끝난다.
set -euo pipefail
HERE="$(cd "$(dirname "$0")/.." && pwd)"
{
  grep -oE '^- \*\*`[A-Z-]+`' "$HERE/agent-principles.md" | sed 's/^- \*\*`//; s/`$//'
  grep '^## ' "$HERE/agent-principles.md" | sed 's/^## //'
  for d in "$HERE"/skills/*/; do basename "$d"; done
  for f in "$HERE"/commands/*.md; do [ -f "$f" ] && basename "$f" .md; done
} | awk 'NF && !seen[$0]++' | sort
