#!/usr/bin/env bash
# 공유: scaffold.sh(Claude)와 codex-scaffold.sh(Codex)의 공통 로직(SSOT).
# 두 스크립트는 홈 위치·주입 방식만 다르고 관리 디렉터리 정책은 동일해야 한다 — 여기가 정본.

# 관리 디렉터리에 두는 정본 파일. 두 스캐폴드가 복사하고 주입하는 것이 이 목록이다.
SCAFFOLD_FILES="agent-principles.md"
# 화이트리스트는 정본 파일에 backups 디렉터리를 더한 것이다. 위생 검사가 이 목록 밖을 훑는다.
# 파일 이름을 다른 곳에 다시 적지 않는다 — 여기만 고친다.
SCAFFOLD_WHITELIST="$SCAFFOLD_FILES backups"
# 구 관리파일은 매 세션 조용히 지운다. issue-mode·ultracode-review는 토글이던 상태 파일인데,
# 토글을 없애면서 화이트리스트에서만 빼면 내용이 있어 '비관리 파일' 경고로 영원히 남는다.
# advisors-index·unsolved_problems도 같은 이유로 여기 있다 — 앞은 domains-index로 이름이 바뀐 옛
# 파일이고, 뒤는 손유지 백로그라 없앤 기능의 잔재다. 둘 다 내용이 있어 위생 검사가 지우지 못한다.
SCAFFOLD_STALE="coding-principles.md issue-mode ultracode-review advisors-index.md unsolved_problems.md solved_problems.md solved_problems domains-index.md"

# 쪼개진 로그(색인 + 본문 폴더)의 형식 규칙 블록. 안 쪼개진 로그에는 이것을 갈아끼우지 않는다 —
# 지킬 수 없는 형식을 스스로 선언하게 되는데, 낡음 판정이 포함 검사라 그 어긋남은 어떤 신호에도
# 안 걸린다. 굵은 줄에 관한 규칙을 넣어 둔 이유는, 쪼갠 직후와 지시사항을 다 쓴 뒤 사이의 중간
# 상태를 사람과 기계가 함께 알아볼 수 있게 하기 위해서다.

# 쪼개진 로그임을 알아보는 표. 규칙 블록의 마지막 줄에서 뽑아 온다 — 손으로 한 번 더 적으면
# 문안을 고칠 때 한쪽만 낡는다(`SSOT`).

scaffold_hygiene() {  # $1=KDIR
  local kdir="$1" f b w keep
  scaffold_stale_kept=""
  # 구 관리파일 치우기. 내용이 있으면 사용자가 적어 둔 줄이 섞여 있을 수 있으므로 지우지 않고
  # 백업으로 옮긴다 — 관리 디렉터리에서는 사라지되 되돌릴 수는 있어야 한다(REVERSIBLE).
  # 사본을 못 뜨면 지우지 않고 그대로 두고 알린다. 예전에는 여기서 rm 으로 넘어갔는데, 그러면
  # 백업 디렉터리에 쓸 수 없는 PC 에서 사용자가 적어 둔 줄이 조용히 사라져 되돌릴 길이 없었다.
  for f in $SCAFFOLD_STALE; do
    [ -f "$kdir/$f" ] || continue
    if [ ! -s "$kdir/$f" ]; then
      rm -f "$kdir/$f" || true
      continue
    fi
    if mkdir -p "$kdir/backups" 2>/dev/null &&
       mv "$kdir/$f" "$kdir/backups/$f.$(date +%Y%m%d-%H%M%S).bak" 2>/dev/null; then
      continue
    fi
    scaffold_stale_kept="${scaffold_stale_kept}${scaffold_stale_kept:+, }$f"
  done
  if [ -n "${scaffold_stale_kept:-}" ]; then
    echo "[disciplined-coder] WARNING: 구 관리파일을 사본으로 못 옮겨 그대로 두었다($kdir 안: $scaffold_stale_kept). $kdir/backups 에 쓸 수 있게 하면 다음 세션에 치운다." >&2
  fi
  for f in "$kdir"/*; do
    [ -e "$f" ] || continue
    b="$(basename "$f")"
    keep=0; for w in $SCAFFOLD_WHITELIST; do [ "$b" = "$w" ] && { keep=1; break; }; done
    [ "$keep" = 1 ] && continue
    if [ -d "$f" ]; then
      echo "[disciplined-coder] note: 비관리 디렉터리 '$b' 잔존(자동삭제 안 함, 확인 요)" >&2
      continue
    fi
    if [ -s "$f" ]; then
      echo "[disciplined-coder] note: 비관리 파일 '$b' 잔존(내용 있음 — 자동삭제 안 함, 확인 요)" >&2
    else
      rm -f "$f" || echo "[disciplined-coder] WARNING: 빈 고아 '$b' 삭제 실패(권한·잠금?) — 계속 진행" >&2
    fi
  done
}

scaffold_count_matches() {  # $1=파일 $2=확장 정규식 → stdout: 개수 한 줄
  [ -f "$1" ] || { printf '0'; return 0; }
  printf '%s' "$(grep -c -E -- "$2" "$1" 2>/dev/null || true)"
}

# 색인 줄 수와 본문 파일 수를 맞댄다. 읽기만 하고 어떤 파일에도 쓰지 않는다.
# 개수가 아니라 이름을 맞댄다. 개수만 맞대던 판본은 색인 줄 하나와 본문 파일 하나가 서로 다른
# 것을 가리키는 상태를 통째로 놓쳤다 — 숫자로는 완벽하게 맞아 보이기 때문이다.
# 내용까지 맞대지는 않는다. 그것은 항목 수만큼 값이 들고, 안 쓰는 항목의 어긋남은 그 회차에 해를
# 끼치지 않으므로 그 줄을 따라 본문을 열 때 그 자리에서 한다.
# 색인 줄은 포인터로 센다. 머리말의 규칙 불릿과 색인 줄이 같은 모양이라 '- '로는 안 갈린다.
# 굵은 줄은 두 몫으로 갈라 센다. 포인터가 없으면 아직 본문으로 안 옮긴 옛 한 줄 항목이고, 포인터가
# 있으면 옮기기는 했으나 아직 지시사항으로 안 고친 색인 줄이다. 사람이 할 일이 서로 달라서 한
# 숫자로 뭉치면 안 된다 — 쪼갠 직후에는 손으로 가를 것이 없는데도 항목 수만큼 신호가 떠서 어느
# 걸음이 남았는지 가려진다(실제로 그 결함을 밟았다).
scaffold_names_only_in_first() {  # $1=앞 목록 $2=뒤 목록(둘 다 줄바꿈 구분) → stdout: 앞에만 있는 이름
  { printf '%s\n' "$2" | sed 's/^/B /'; printf '%s\n' "$1" | sed 's/^/A /'; } |
    awk '{
      t = substr($0, 1, 1); n = substr($0, 3)
      sub(/\r$/, "", n)
      if (n == "") next
      if (t == "B") { seen[n] = 1; next }
      if (!(n in seen) && !(n in shown)) { shown[n] = 1; out[++k] = n }
    }
    END { for (i = 1; i <= k; i++) printf "%s%s", (i > 1 ? ", " : ""), out[i] }'
}
