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
# 동시 진입 방지: 이 함수의 대상은 프로젝트마다 공유되는 하나의 ~/.claude/CLAUDE.md이고, SessionStart는
# startup·resume·clear마다 돈다. 창을 둘 이상 동시에 열면 두 프로세스의 read-modify-write가 겹쳐
# 사용자가 손으로 적은 지침이 조각날 수 있다. 그래서 대상 파일마다 락을 잡고 직렬화하며, 임시 파일도
# 결정론적 이름 대신 mktemp로 유일하게 만든다(PC 오답노트 — 결정론적 파일명과 공유 스크래치의 조합).
managed_block_inject() {
  local uc="$1" begin="$2" end="$3" body tmp norm lock
  body="$(cat)"
  touch "$uc"

  lock="$uc.lock"
  local waited=0
  while ! mkdir "$lock" 2>/dev/null; do
    waited=$((waited+1))
    # 죽은 프로세스가 남긴 락에 영원히 갇히지 않는다 — 10초를 넘기면 빼앗고 경고한다(FAIL-LOUD).
    if [ "$waited" -gt 100 ]; then
      echo "[disciplined-coder] WARNING: stale lock at $lock — 10s 대기 후 강제로 진행한다" >&2
      rm -rf "$lock"; mkdir "$lock" 2>/dev/null || true
      break
    fi
    sleep 0.1
  done
  tmp="$(mktemp "$uc.XXXXXX")"; norm="$(mktemp "$uc.XXXXXX")"
  # 중간에 죽어도 임시 파일과 락을 남기지 않는다.
  trap 'rm -f "$tmp" "$norm"; rmdir "$lock" 2>/dev/null || true' RETURN
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
  ' "$uc" > "$tmp"
  awk '{ l=$0; sub(/\r$/,"",l); if (l ~ /[^ \t]/) last=NR; line[NR]=$0 } END { for (i=1;i<=last;i++) print line[i] }' "$tmp" > "$norm" && mv "$norm" "$uc"
  {
    if [ -s "$uc" ]; then printf '\n'; fi
    printf '%s\n' "$begin"
    printf '%s\n' "$body"
    printf '%s\n' "$end"
  } >> "$uc"
}
