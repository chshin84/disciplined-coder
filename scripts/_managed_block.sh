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
# 마커 영역을 걷어내는 awk 프로그램(정본). 주입과 제거가 같은 규칙을 쓰도록 문자열로 떼어 둔다 —
# 두 벌로 두면 한쪽만 고쳐져 '주입은 지우는데 제거는 남기는' 어긋남이 조용히 생긴다(SSOT).
# 함수로 떼지 않고 문자열로 두는 이유는, 락을 푸는 RETURN 트랩이 중첩 함수 반환에서 먼저 터질 수
# 있어 append 전에 락이 풀리는 조용한 회귀를 만들기 때문이다.
MANAGED_STRIP_AWK='
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
'
# 끝의 빈 줄을 걷어낸다(블록을 뗀 자리에 빈 줄이 쌓이는 것을 막는다).
MANAGED_TRIM_AWK='{ l=$0; sub(/\r$/,"",l); if (l ~ /[^ \t]/) last=NR; line[NR]=$0 } END { for (i=1;i<=last;i++) print line[i] }'

# 락을 잡는다. 잡을 때까지 돌아오지 않으며, 푸는 것은 managed_block_unlock 이 맡는다.
# 죽은 프로세스가 남긴 락에 영원히 갇히지 않도록 한 락이 10초를 넘게 잡혀 있으면 빼앗고
# 경고한다(`FAIL-LOUD`). 잡는 코드를 이 함수 한 곳에 두는 이유는 호출자가 둘이라 한쪽만 고치면
# 옛 갈래가 남기 때문이다.
#
# 함께 들어가는 것을 막는 장치가 둘이다. 하나만으로는 모자란다 — 실측에서 여덟 중 셋이 함께
# 들어갔다.
#   첫째, 빼앗기를 이름 바꾸기 한 걸음으로 한다. 같은 경로를 옮기는 것은 한 프로세스만 성공하므로
#   빼앗는 쪽이 여럿이어도 임계 구역에는 하나만 들어간다. 지우고 다시 잡는 두 걸음으로 하면 그
#   사이에 남이 끼어들어 둘 다 자기가 주인이라고 여긴다.
#   둘째, 빼앗을지를 내가 기다린 시간이 아니라 그 락이 잡혀 있던 시간으로 정한다. 잡는 쪽이 잡은
#   시각을 락 안에 적어 두고, 기다리는 쪽은 그 시각을 읽어 나이를 잰다. 내가 기다린 시간으로 세면
#   10초를 채운 쪽이 그새 새로 들어온 사람의 락까지 빼앗는다 — 락은 바뀌었는데 내 시계만 계속
#   돌기 때문이다.
# 잡은 시각이 없는 락은 표를 남기기 전에 죽었거나 옛 판본이 남긴 것이니 빼앗을 대상으로 본다.
#
# 문지기(`$lock.gate`)를 따로 두는 이유는 나이를 재는 것과 빼앗는 것이 갈라져 있으면 그 사이에
# 남이 새로 잡기 때문이다. 재고 빼앗고 잡는 세 걸음을 문지기 안에 함께 넣어 한 번에 하나만
# 하도록 만든다. 문지기는 마이크로초만 잡으므로 오래 잡혀 있으면 잡은 쪽이 죽은 것이고, 그때는
# 30초를 기다린 뒤 치운다.
MANAGED_LOCK_STALE_SECONDS=10
MANAGED_GATE_STALE_TICKS=300
managed_block_lock() {  # $1=락 디렉터리 경로
  local lock="$1" gate="$1.gate" born now gwait=0
  while :; do
    if mkdir "$gate" 2>/dev/null; then
      gwait=0
      if mkdir "$lock" 2>/dev/null; then
        printf '%s\n' "$(date +%s 2>/dev/null || echo 0)" 2>/dev/null > "$lock/heldsince" || true
        rmdir "$gate" 2>/dev/null || true
        return 0
      fi
      born="$(cat "$lock/heldsince" 2>/dev/null || true)"
      now="$(date +%s 2>/dev/null || echo 0)"
      if [ -z "$born" ] || [ "$((now - born))" -ge "$MANAGED_LOCK_STALE_SECONDS" ]; then
        echo "[disciplined-coder] WARNING: stale lock at $lock — 오래 잡혀 있어 빼앗는다" >&2
        rm -rf "$lock" 2>/dev/null || true
        rmdir "$gate" 2>/dev/null || true
        continue
      fi
      rmdir "$gate" 2>/dev/null || true
    else
      gwait=$((gwait+1))
      if [ "$gwait" -gt "$MANAGED_GATE_STALE_TICKS" ]; then
        echo "[disciplined-coder] WARNING: stale gate at $gate — 30s 대기 후 치운다" >&2
        rm -rf "$gate" 2>/dev/null || true
        gwait=0
      fi
    fi
    sleep 0.1
  done
}

# 락을 푼다. 안에 잡은 시각이 들어 있어 rmdir 로는 안 지워진다.
managed_block_unlock() {  # $1=락 디렉터리 경로
  [ -n "${1:-}" ] || return 0
  rm -rf "$1" 2>/dev/null || true
  return 0
}

# 관리블록을 걷어내기만 한다(본문을 다시 넣지 않는다). 없앤 기능이 남긴 고아 블록 정리용.
# 걷어내기는 마커 사이를 통째로 버리므로, 사람이 그 안에 끼워 넣은 줄도 함께 사라진다. 그 파일은
# git 밖일 수 있어 사본이 유일한 복구 수단이다 — 그래서 사본 경로를 인자로 받아 여기서 직접 뜨고,
# 못 뜨면 아예 걷어내지 않는다(오답노트 머리말과 같은 규율. 호출자가 기억하게 두지 않으려고 함수
# 안에 둔다 — `FAIL-LOUD`).
# 리턴: 0=걷어냄, 1=대상이 없어 아무것도 안 함, 2=사본을 못 떠서 걷어내지 않음.
# 호출은 반드시 `|| rc=$?`로 감싼다(set -e).
managed_block_remove() {
  local uc="$1" begin="$2" end="$3" bk="${4:-}" tmp norm lock
  managed_block_backup=""
  [ -f "$uc" ] || return 1
  grep -qF "$begin" "$uc" 2>/dev/null || return 1
  if [ -n "$bk" ]; then
    if ! mkdir -p "$(dirname "$bk")" 2>/dev/null || ! cp "$uc" "$bk" 2>/dev/null; then
      return 2
    fi
    managed_block_backup="$bk"
  fi
  lock="$uc.lock"
  managed_block_lock "$lock"
  tmp="$(mktemp "$uc.XXXXXX")"; norm="$(mktemp "$uc.XXXXXX")"
  trap 'rm -f "$tmp" "$norm"; managed_block_unlock "$lock"' RETURN
  awk -v b="$begin" -v e="$end" -v o="$MANAGED_ORPHAN" -v f="$uc" "$MANAGED_STRIP_AWK" "$uc" > "$tmp"
  awk "$MANAGED_TRIM_AWK" "$tmp" > "$norm" && mv "$norm" "$uc"
  return 0
}

managed_block_inject() {
  local uc="$1" begin="$2" end="$3" body tmp norm lock
  body="$(cat)"
  touch "$uc"

  lock="$uc.lock"
  managed_block_lock "$lock"
  tmp="$(mktemp "$uc.XXXXXX")"; norm="$(mktemp "$uc.XXXXXX")"
  # 중간에 죽어도 임시 파일과 락을 남기지 않는다.
  trap 'rm -f "$tmp" "$norm"; managed_block_unlock "$lock"' RETURN
  awk -v b="$begin" -v e="$end" -v o="$MANAGED_ORPHAN" -v f="$uc" "$MANAGED_STRIP_AWK" "$uc" > "$tmp"
  awk "$MANAGED_TRIM_AWK" "$tmp" > "$norm" && mv "$norm" "$uc"
  {
    if [ -s "$uc" ]; then printf '\n'; fi
    printf '%s\n' "$begin"
    printf '%s\n' "$body"
    printf '%s\n' "$end"
  } >> "$uc"
}
