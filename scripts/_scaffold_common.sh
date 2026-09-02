#!/usr/bin/env bash
# scaffold.sh에서 분리한 관리 디렉터리 정책(SSOT) — 여기가 정본.

# 관리 디렉터리에 두는 정본 파일. 두 스캐폴드가 복사하고 주입하는 것이 이 목록이다.
SCAFFOLD_FILES="agent-principles.md"
# 화이트리스트는 정본 파일에 backups 디렉터리를 더한 것이다. 위생 검사가 이 목록 밖을 훑는다.
# 파일 이름을 다른 곳에 다시 적지 않는다 — 여기만 고친다.
SCAFFOLD_WHITELIST="$SCAFFOLD_FILES backups"
# 구 관리파일은 매 세션 조용히 지운다. issue-mode·ultracode-review는 토글이던 상태 파일인데,
# 토글을 없애면서 화이트리스트에서만 빼면 내용이 있어 '비관리 파일' 경고로 영원히 남는다.
# advisors-index·unsolved_problems도 같은 이유로 여기 있다 — 앞은 domains-index로 이름이 바뀐 옛
# 파일이고, 뒤는 손유지 백로그라 없앤 기능의 잔재다. 둘 다 내용이 있어 위생 검사가 지우지 못한다.
# solved_problems는 파일과 디렉터리 둘로 남는다 — 로그를 쪼갠 PC에는 폴더가 남기 때문이다.
SCAFFOLD_STALE="coding-principles.md issue-mode ultracode-review advisors-index.md unsolved_problems.md solved_problems.md solved_problems domains-index.md"

scaffold_hygiene() {  # $1=KDIR
  local kdir="$1" f b w keep
  scaffold_stale_kept=""
  # 구 관리파일 치우기. 내용이 있으면 사용자가 적어 둔 줄이 섞여 있을 수 있으므로 지우지 않고
  # 백업으로 옮긴다 — 관리 디렉터리에서는 사라지되 되돌릴 수는 있어야 한다(REVERSIBLE).
  # 사본을 못 뜨면 지우지 않고 그대로 두고 알린다. 예전에는 여기서 rm 으로 넘어갔는데, 그러면
  # 백업 디렉터리에 쓸 수 없는 PC 에서 사용자가 적어 둔 줄이 조용히 사라져 되돌릴 길이 없었다.
  for f in $SCAFFOLD_STALE; do
    [ -e "$kdir/$f" ] || continue
    # 디렉터리로 남은 것도 같은 규율으로 치운다. 오답노트를 폴더로 쪼갰던 PC가 그 형태인데,
    # 정규 파일만 보던 판본은 그것을 건너뛰어 해소할 수 없는 잔존 경고를 매 세션 냈다.
    # 안을 훑지 않고 통째로 옮긴다 — 무엇이 들었든 사본 하나로 되돌릴 수 있다(`REVERSIBLE`).
    if [ -f "$kdir/$f" ] && [ ! -s "$kdir/$f" ]; then
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
