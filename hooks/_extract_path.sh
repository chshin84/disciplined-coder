#!/usr/bin/env bash
# 편집 대상 파일 경로를 stdin JSON에서 전부 추출(한 줄에 하나, 백슬래시→슬래시 정규화, 중복 제거).
# 두 런타임 입력을 모두 처리: Claude(Write/Edit)의 "file_path" + Codex(apply_patch)의 패치 헤더.
# 순수 bash/sed/awk(jq 비의존).
set -euo pipefail
INPUT="$(cat)"
{
  # (1) Claude: "file_path":"<path>" — 0개 이상 (Write/Edit는 정확히 1개)
  printf '%s' "$INPUT" | grep -o '"file_path"[[:space:]]*:[[:space:]]*"[^"]*"' \
    | sed 's/.*:[[:space:]]*"\([^"]*\)"$/\1/' || true
  # (2) Codex apply_patch: 패치가 JSON 문자열이라 개행이 \n 이스케이프됨 → 이스케이프된 \r 제거 후
  #     \n을 실제 개행으로 풀고 '*** Add|Update|Delete File: <path>' 헤더에서 경로(줄 나머지)를 추출.
  printf '%s' "$INPUT" | awk '{gsub(/\\r/,""); gsub(/\\n/,"\n")}1' \
    | sed -n 's/^\*\*\* \(Add\|Update\|Delete\) File: \(.*\)$/\2/p'
} | tr -s '\\' '/' | awk 'NF && !seen[$0]++'
