#!/usr/bin/env bash
# 공유: CLAUDE.md류 파일에 BEGIN/END 관리블록을 멱등 주입한다.
# Usage: managed_block_inject <target_file> <begin_mark> <end_mark>   (본문은 stdin)
# - 기존 BEGIN..END 영역 strip(CRLF 내성) → 사용자 내용 보존 → 말미 공백 정규화 → 새 블록 append.
# - BEGIN만 있고 END 없음 = WARN + 고아 마커 무해화(비파괴·재실행 안전).
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
    # 고아 BEGIN(END 없음)을 그대로 두면 다음 실행의 strip이 고아 BEGIN~새 END 사이의
    # 사용자 내용을 오인 삭제한다(IDEMPOTENT 위반). 마커 줄을 무해화해 재실행을 안전하게 한다.
    echo "[disciplined-coder] WARNING: $uc has BEGIN but no END — neutralizing orphan BEGIN (non-destructive)" >&2
    awk -v b="$begin" '{ l=$0; sub(/\r$/,"",l); if (l==b) print "# (disciplined-coder: orphan BEGIN neutralized — END missing)"; else print }' "$uc" > "$uc.tmp"
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
