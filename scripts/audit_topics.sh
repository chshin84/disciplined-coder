#!/usr/bin/env bash
# 이름표 목록을 도출한다 — 에이전트원칙의 원칙 ID 전부, 에이전트원칙의 ## 절 제목, skills/ 아래 스킬 이름, commands/ 아래
# 명령 이름을 합쳐 한 줄에 하나씩 낸다. 목록이 닫혀 있으므로 모으기가 문자열 일치로 끝난다.
set -euo pipefail
HERE="$(cd "$(dirname "$0")/.." && pwd)"
{
  # 문서 규칙 조항은 2026-10-25 에 스킬 managing-docs 로 옮겼으므로 그 파일의 조항 ID 도 이름표로 둔다.
  grep -ohE '^- \*\*`[A-Z-]+`' "$HERE/agent-principles.md" "$HERE"/skills/managing-docs/SKILL.md "$HERE"/skills/managing-docs/references/reading-docs.md | sed 's/^- \*\*`//; s/`$//'
  grep '^## ' "$HERE/agent-principles.md" | sed 's/^## //'
  for d in "$HERE"/skills/*/; do basename "$d"; done
  for f in "$HERE"/commands/*.md; do [ -f "$f" ] && basename "$f" .md; done
} | awk 'NF && !seen[$0]++' | sort
