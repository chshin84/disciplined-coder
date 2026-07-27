#!/usr/bin/env bash
# 공유: CLAUDE.md류 파일에 BEGIN/END 관리블록을 멱등 주입한다.
# Usage: managed_block_inject <target_file> <begin_mark> <end_mark>   (본문은 stdin)
# strip 대상은 '마커 줄'로만 한정한다 — 본문 줄은 어떤 경우에도 지우지 않는다.
#   (1) 완결 영역(여는 마커..닫는 마커)은 본문째 전부 제거. 여러 개면 모두.
#       여는 마커는 begin 또는 과거 실행이 남긴 고아 무해화 주석(자리를 바꾼 BEGIN)이다.
#   (2) 닫는 마커가 없는 여는 마커는 '그 줄만' 제거하고 경고. 뒤 내용은 사용자 것일 수 있어 보존.
#   (3) 영역 밖에 남은 짝 없는 닫는 마커도 제거.
# 본문 줄을 지우지 않는 이유: 이 함수는 codex-scaffold.sh에서 정본 전문을 본문으로 받는다.
#   본문에 빈 줄이 포함되므로 '본문과 같은 줄 제거'는 사용자 AGENTS.md의 빈 줄을 전멸시킨다.
# 표준 관리블록 마커(SSOT). 소비자(scaffold·codex-scaffold)는 begin/end를 인자로 넘긴다.
MANAGED_BEGIN="# BEGIN disciplined-coder (managed — do not edit)"
MANAGED_END="# END disciplined-coder (managed — do not edit)"
# 고아 주석은 마커 집합의 파생값이라 인자를 늘리지 않고 함수가 모듈 상수를 직접 읽는다(비대칭 의도).
# 새로 쓰지는 않는다 — (2)가 마커 줄을 지우므로 다음 실행에 고아가 남지 않는다. 읽기 전용 하위호환.
MANAGED_ORPHAN="# (disciplined-coder: orphan BEGIN neutralized — END missing)"
managed_block_inject() {
  local uc="$1" begin="$2" end="$3" body
  body="$(cat)"
  touch "$uc"
  awk -v b="$begin" -v e="$end" -v o="$MANAGED_ORPHAN" -v f="$uc" '
    { line[NR]=$0; l=$0; sub(/\r$/,"",l); norm[NR]=l }
    END {
      n=NR
      for (i=1;i<=n;i++) del[i]=0
      i=1
      while (i<=n) {
        if (norm[i]==b || norm[i]==o) {
          j=i+1; found=0
          while (j<=n) {
            if (norm[j]==e) { found=j; break }
            if (norm[j]==b || norm[j]==o) { break }
            j++
          }
          if (found) { for (k=i;k<=found;k++) del[k]=1; i=found+1 }
          else { del[i]=1; orphan=1; i++ }
        } else if (norm[i]==e) { del[i]=1; i++ }
        else { i++ }
      }
      for (i=1;i<=n;i++) if (!del[i]) print line[i]
      if (orphan) print "[disciplined-coder] WARNING: " f " has BEGIN but no END — orphan marker line dropped (content preserved)" > "/dev/stderr"
    }
  ' "$uc" > "$uc.tmp"
  awk '{ l=$0; sub(/\r$/,"",l); if (l ~ /[^ \t]/) last=NR; line[NR]=$0 } END { for (i=1;i<=last;i++) print line[i] }' "$uc.tmp" > "$uc.norm" && mv "$uc.norm" "$uc" && rm -f "$uc.tmp"
  {
    if [ -s "$uc" ]; then printf '\n'; fi
    printf '%s\n' "$begin"
    printf '%s\n' "$body"
    printf '%s\n' "$end"
  } >> "$uc"
}
