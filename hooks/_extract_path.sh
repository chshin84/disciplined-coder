#!/usr/bin/env bash
# 편집 대상 파일 경로를 stdin JSON에서 전부 추출(한 줄에 하나, 백슬래시→슬래시 정규화, 중복 제거).
# 순수 bash/sed/awk(jq 비의존).
set -euo pipefail
INPUT="$(cat)"
{
  # Claude Write/Edit의 "file_path":"<path>" — 0개 이상 (Write/Edit는 정확히 1개)
  printf '%s' "$INPUT" | grep -o '"file_path"[[:space:]]*:[[:space:]]*"[^"]*"' \
    | sed 's/.*:[[:space:]]*"\([^"]*\)"$/\1/' || true
} | tr -s '\\' '/' | awk 'NF && !seen[$0]++'
