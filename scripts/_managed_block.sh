#!/usr/bin/env bash
# 공유: CLAUDE.md류 파일에 BEGIN/END 관리블록을 멱등 주입한다.
# Usage: managed_block_inject <target_file> <begin_mark> <end_mark>   (본문은 stdin)
# - 기존 BEGIN..END 영역 strip(CRLF 내성) → 사용자 내용 보존 → 말미 공백 정규화 → 새 블록 append.
# - BEGIN만 있고 END 없음 = WARN + strip 생략(비파괴).
# 표준 관리블록 마커(SSOT). 소비자(scaffold·codex-scaffold·add-pointer)는 이 값을 인자로 넘긴다.
MANAGED_BEGIN="# BEGIN disciplined-coder (managed — do not edit)"
MANAGED_END="# END disciplined-coder (managed — do not edit)"
managed_block_inject() {
  local uc="$1" begin="$2" end="$3" body
  body="$(cat)"
  touch "$uc"
  if grep -qF "$begin" "$uc" && grep -qF "$end" "$uc"; then
    awk -v b="$begin" -v e="$end" '{ l=$0; sub(/\r$/,"",l) } l==b{skip=1} skip==0{print} l==e{skip=0}' "$uc" > "$uc.tmp"
  elif grep -qF "$begin" "$uc"; then
    echo "[disciplined-coder] WARNING: $uc has BEGIN but no END — skipping strip" >&2
    cp "$uc" "$uc.tmp"
  else
    cp "$uc" "$uc.tmp"
  fi
  awk '{ l=$0; sub(/\r$/,"",l); if (l ~ /[^ \t]/) last=NR; line[NR]=$0 } END { for (i=1;i<=last;i++) print line[i] }' "$uc.tmp" > "$uc.norm" && mv "$uc.norm" "$uc" && rm -f "$uc.tmp"
  {
    if [ -s "$uc" ]; then printf '\n'; fi
    printf '%s\n' "$begin"
    printf '%s\n' "$body"
    printf '%s\n' "$end"
  } >> "$uc"
}
