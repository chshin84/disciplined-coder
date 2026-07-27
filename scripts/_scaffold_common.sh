#!/usr/bin/env bash
# 공유: scaffold.sh(Claude)와 codex-scaffold.sh(Codex)의 공통 로직(SSOT).
# 두 스크립트는 홈 위치·주입 방식만 다르고 관리 디렉터리 정책은 동일해야 한다 — 여기가 정본.

# 관리 디렉터리 화이트리스트(=현 정본 세트)와 구 관리파일(STALE). 여기만 고친다.
SCAFFOLD_WHITELIST="agent-principles.md domains-index.md solved_problems.md issue-mode ultracode-review"
SCAFFOLD_STALE="coding-principles.md"

# 위생(멱등): STALE 제거 → 비화이트리스트는 디렉터리/내용파일 surface·빈 파일 제거.
scaffold_hygiene() {  # $1=KDIR
  local kdir="$1" f b w keep
  for f in $SCAFFOLD_STALE; do [ -f "$kdir/$f" ] && rm -f "$kdir/$f" || true; done
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

# solved 오답노트: 없을 때만 생성(append-only). 생성했으면 0, 이미 있으면 1을 리턴.
# 주의(유지보수 함정): '이미 존재'라는 정상 경로가 1을 리턴하므로 호출은 반드시 if로 감싼다 —
# set -e 아래 bare 호출은 매 세션 스크립트를 죽인다.
scaffold_ensure_solved() {  # $1=KDIR
  local kdir="$1"
  [ -f "$kdir/solved_problems.md" ] && return 1
  cat > "$kdir/solved_problems.md" <<'EOF'
# 해결된 문제 로그 (solved_problems) — PC 전역 · append-only 오답노트

완결된 문제의 교훈 모음 — 차후 비슷한 작업에서 recall해 참고한다.
**완결 후 등록하는 기록이라 '상태'가 아니다** — "문서에 상태 금지"의 예외(append-only, 과거를 지우지 않는다).
일반화 가능한 항목은 디시플린(agent-principles.md)으로 **재기술해 승격**한다(원문은 append-only로 보존 — 이동이 아니라 상위 계층 재작성). 메인 세션만 기록.

항목을 적는 형식은 이렇다.

- 증상은 굵게 한 줄로 띄운다.
- 원인과 해결은 그 아래 들여쓰기로 내린다.
- 한 항목은 세 줄을 넘기지 않는다.
- 순서는 시간순이고 아래에 추가한다.
- 항목이 스무 개를 넘으면 그때 영역별로 묶는다.
- 안 쓰이는 항목도 지우지 않는다.
EOF
  return 0
}

# issue-mode: 부재면 surface 생성(+1회 안내), 읽어서 mode_line/mode_note를 셋한다(호출측 변수).
scaffold_resolve_issue_mode() {  # $1=KDIR  → sets: mode_line, mode_note
  local kdir="$1" mode_file mode
  mode_file="$kdir/issue-mode"
  mode_note=""
  if [ ! -f "$mode_file" ]; then
    printf 'surface\n' > "$mode_file"
    mode_note="🔵 disciplined-coder: 처분 모드를 surface(기본)로 시작했다 — GitHub Issues 위임을 켜려면 /issue-mode issues."
  fi
  mode="$(tr -d ' \t\r\n' < "$mode_file" 2>/dev/null || printf surface)"
  if [ "$mode" = "issues" ]; then
    mode_line="오답노트 처분 모드: issues — must-keep을 자동 close 트래커(GitHub Issues)에 위임 ON"
  elif [ "$mode" = "surface" ]; then
    mode_line="오답노트 처분 모드: surface+메모리 — GitHub 이슈 위임 OFF"
  else
    echo "[disciplined-coder] WARNING: issue-mode 불명값 '$mode' — surface로 폴백" >&2
    mode_line="오답노트 처분 모드: surface+메모리 — GitHub 이슈 위임 OFF (불명 config 폴백)"
  fi
}

# ultracode 검증 모드: 부재면 discretion 생성(+1회 안내), 읽어서 ucr_mode_line/ucr_mode_note를 셋한다.
# issue-mode의 mode_line/mode_note와 변수를 공유하지 않는다 — 공유하면 나중 resolve가 먼저 값을
# 덮어써 첫 토글의 라인·안내가 조용히 유실된다(spec 2026-07-03).
scaffold_resolve_ultracode_review() {  # $1=KDIR  → sets: ucr_mode_line, ucr_mode_note
  local kdir="$1" mode_file mode
  mode_file="$kdir/ultracode-review"
  ucr_mode_note=""
  if [ ! -f "$mode_file" ]; then
    printf 'discretion\n' > "$mode_file"
    ucr_mode_note="🔵 disciplined-coder: ultracode 검증 모드를 discretion(기본)으로 시작했다 — 워크플로 렌즈 검증을 강제하려면 /ultracode-review required."
  fi
  mode="$(tr -d ' \t\r\n' < "$mode_file" 2>/dev/null || printf discretion)"
  if [ "$mode" = "required" ]; then
    ucr_mode_line="ultracode(멀티에이전트 워크플로) 검증 모드: required — 워크플로에 reviewer-* 렌즈 검증 단계를 반드시 포함한다"
  elif [ "$mode" = "discretion" ]; then
    ucr_mode_line="ultracode(멀티에이전트 워크플로) 검증 모드: discretion(기본) — 리스크에 비례해 판단하되 보고서에 검증 내역을 명시한다"
  else
    echo "[disciplined-coder] WARNING: ultracode-review 불명값 '$mode' — discretion으로 폴백" >&2
    ucr_mode_line="ultracode(멀티에이전트 워크플로) 검증 모드: discretion(기본) — 리스크에 비례해 판단하되 보고서에 검증 내역을 명시한다 (불명 config 폴백)"
  fi
}
