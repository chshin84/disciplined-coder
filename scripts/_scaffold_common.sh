#!/usr/bin/env bash
# 공유: scaffold.sh(Claude)와 codex-scaffold.sh(Codex)의 공통 로직(SSOT).
# 두 스크립트는 홈 위치·주입 방식만 다르고 관리 디렉터리 정책은 동일해야 한다 — 여기가 정본.

# 관리 디렉터리 화이트리스트(=현 정본 세트)와 구 관리파일(STALE). 여기만 고친다.
SCAFFOLD_WHITELIST="agent-principles.md domains-index.md solved_problems.md solved_problems backups"
# 구 관리파일은 매 세션 조용히 지운다. issue-mode·ultracode-review는 토글이던 상태 파일인데,
# 토글을 없애면서 화이트리스트에서만 빼면 내용이 있어 '비관리 파일' 경고로 영원히 남는다.
# advisors-index·unsolved_problems도 같은 이유로 여기 있다 — 앞은 domains-index로 이름이 바뀐 옛
# 파일이고, 뒤는 손유지 백로그라 없앤 기능의 잔재다. 둘 다 내용이 있어 위생 검사가 지우지 못한다.
SCAFFOLD_STALE="coding-principles.md issue-mode ultracode-review advisors-index.md unsolved_problems.md"

# 오답노트 형식 규칙 블록(정본). 이 문자열이 로그 안에 그대로 있으면 그 로그의 형식 규칙이 최신이다.
# 도입 문장·빈 줄·불릿 여섯으로 여덟 줄이다. 스코프 문구(로그마다 다르다)와 나눠 두는 이유는,
# 템플릿 전문과 비교하면 도입부가 다른 프로젝트 로그가 영원히 '다름'으로 판정돼 매 세션 오탐이 되기 때문이다.
# 작은따옴표로 감쌀 수 있는 것은 이 여덟 줄에 ASCII 어포스트로피가 없기 때문이다
# (어포스트로피가 든 '상태'는 그 위 스코프 문단이라 블록 밖이다).
SCAFFOLD_SOLVED_RULES='항목을 적는 형식은 이렇다.

- 증상은 굵게 한 줄로 띄운다.
- 원인과 해결은 그 아래 들여쓰기로 내린다.
- 한 항목은 세 줄을 넘기지 않는다.
- 순서는 시간순이고 아래에 추가한다.
- 항목이 스무 개를 넘으면 그때 영역별로 묶는다.
- 안 쓰이는 항목도 지우지 않는다 — 사용자가 직접 지시할 때만 손댄다.'

# 쪼개진 로그(색인 + 본문 폴더)의 형식 규칙 블록. 안 쪼개진 로그에는 이것을 갈아끼우지 않는다 —
# 지킬 수 없는 형식을 스스로 선언하게 되는데, 낡음 판정이 포함 검사라 그 어긋남은 어떤 신호에도
# 안 걸린다. 굵은 줄에 관한 규칙을 넣어 둔 이유는, 쪼갠 직후와 지시사항을 다 쓴 뒤 사이의 중간
# 상태를 사람과 기계가 함께 알아볼 수 있게 하기 위해서다.
SCAFFOLD_SOLVED_RULES_SPLIT='항목을 적는 형식은 이렇다.

- 이 파일은 색인이고 한 줄이 한 항목이다. 줄에는 지시사항만 적는다.
- 지시사항은 언제 걸리는지와 무엇을 하라는지를 한 문장에 담는다.
- 증상과 원인과 근거는 색인에 적지 않고 본문 파일에 적는다.
- 각 줄은 다음 줄에서 solved_problems/ 아래의 본문 파일 하나를 가리킨다.
- 본문 파일의 첫 줄은 그 지시사항과 같다.
- 아직 지시사항으로 못 고친 줄은 굵게 둔다. 고치면서 굵기를 벗긴다.
- 순서는 시간순이고 아래에 추가한다.
- 본문 파일을 고치거나 지우기 전에 사용자에게 묻는다.
- 사용자 요청으로 고치거나 지울 때는 색인 줄도 함께 고치거나 지운다.

## 지시사항 색인'

# 쪼개진 로그임을 알아보는 표. 규칙 블록의 마지막 줄에서 뽑아 온다 — 손으로 한 번 더 적으면
# 문안을 고칠 때 한쪽만 낡는다(`SSOT`).
SCAFFOLD_SOLVED_SPLIT_MARK="$(printf '%s' "$SCAFFOLD_SOLVED_RULES_SPLIT" | tail -1)"

# 로그가 쪼개졌는지 본다. 재료는 둘이고 어느 하나만 맞아도 쪼개진 것으로 본다.
# 첫째는 머리말이 스스로 색인이라고 선언하는 표다. 갓 만든 로그는 본문이 아직 하나도 없어서
# 이 표로만 알아볼 수 있다 — 새 로그는 처음부터 쪼개진 형식으로 태어나기 때문이다.
# 둘째는 로그 옆 본문 폴더에 본문 파일이 하나라도 있는지다. 옛 형식으로 만들어져 나중에 쪼개진
# 로그는 머리말이 갈아끼워지기 전에도 이쪽으로 잡힌다.
# 빈 폴더만으로는 쪼개진 것으로 보지 않는다. 개편을 하다 멈춘 로그가 그 모양인데, 그것을 쪼개진
# 것으로 보면 옛 형식 그대로인 색인이 최신 형식을 선언하게 된다.
scaffold_solved_log_is_split() {  # $1=로그 경로 → 종료코드 0이면 쪼개짐
  local dir="${1%.md}" f
  [ -f "$1" ] && grep -qF -- "$SCAFFOLD_SOLVED_SPLIT_MARK" "$1" 2>/dev/null && return 0
  [ -d "$dir" ] || return 1
  for f in "$dir"/*.md; do [ -f "$f" ] && return 0; done
  return 1
}

# 그 로그에 걸어야 할 형식 규칙 블록을 고른다.
# 경로를 안 주면 새로 만드는 것으로 보고 쪼개진 형식의 규칙을 낸다(머리말과 같은 약속이다).
scaffold_solved_rules_for() {  # $1=로그 경로(비우면 새로 만드는 것) → stdout: 규칙 블록
  if [ -z "${1:-}" ] || scaffold_solved_log_is_split "$1"; then
    printf '%s' "$SCAFFOLD_SOLVED_RULES_SPLIT"
  else
    printf '%s' "$SCAFFOLD_SOLVED_RULES"
  fi
}

# 위생(멱등): STALE 제거 → 비화이트리스트는 디렉터리/내용파일 surface·빈 파일 제거.
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

# 오답노트 머리말 정본(스코프별). 로그를 새로 만들 때와 낡은 머리말을 갈아끼울 때가 같은 문자열을
# 쓰도록 한 곳에 둔다 — 두 곳에 두면 갓 만든 로그와 고쳐 준 로그의 머리말이 조용히 갈린다(SSOT).
# 히어독을 확장형으로 바꾸지 않는 이유는 리터럴 히어독이 본문의 $와 백틱을 보호하기 때문이다.
# 지금은 확장 대상 문자가 없어 테스트가 초록이라 함정이 잠복한다.
# 쪼개진 로그에서는 제목 줄과 스코프 문단도 갈린다. 그대로 두면 한 파일이 스스로를
# append-only 라 부르면서 그 아래 규칙 블록은 색인 줄을 고치라고 지시하는 모순이 된다.
# 로그 경로를 안 주면 새로 만드는 것으로 보고 쪼개진 형식을 낸다 — 새 로그는 처음부터 목표
# 형식으로 태어난다.
scaffold_solved_header() {  # $1=스코프(pc|project) $2=로그 경로(비우면 새로 만드는 것) → stdout: 제목부터 형식 규칙 블록까지
  local split=1
  if [ -n "${2:-}" ] && ! scaffold_solved_log_is_split "$2"; then split=0; fi
  case "$1:$split" in
    pc:0)
      cat <<'EOF'
# 해결된 문제 로그 (solved_problems) — PC 전역 · append-only 오답노트

완결된 문제의 교훈 모음 — 차후 비슷한 작업에서 recall해 참고한다.
**완결 후 등록하는 기록이라 '상태'가 아니다** — "문서에 상태 금지"의 예외(append-only — 과거 항목은 사용자가 직접 지시할 때만 손댄다).
일반화 가능한 항목은 디시플린(agent-principles.md)으로 **재기술해 승격**한다(원문은 append-only로 보존 — 이동이 아니라 상위 계층 재작성). 메인 세션만 기록.
EOF
      ;;
    pc:1)
      cat <<'EOF'
# 해결된 문제 로그 (solved_problems) — PC 전역 · 지시사항 색인

일을 시작하기 전에 아래 「지시사항 색인」의 줄을 훑고, 지금 하려는 작업에 걸리는 줄이 있으면 그 줄이 가리키는 본문 파일 하나만 연다. 걸리는 줄이 없으면 아무 파일도 열지 않는다.

완결된 문제의 교훈 모음 — 일을 시작할 때 걸리는 지시사항만 여기 두고 증상과 원인은 본문 파일에 둔다.
본문 파일은 append-only 이고 색인 줄은 그 본문을 따라 고친다. 본문을 고치거나 지울 때만 색인 줄도 함께 손댄다.
일반화 가능한 항목은 디시플린(agent-principles.md)으로 **재기술해 승격**한다(원문은 본문에 보존 — 이동이 아니라 상위 계층 재작성). 메인 세션만 기록.
EOF
      ;;
    project:0)
      cat <<'EOF'
# 해결된 문제 로그 (solved_problems) — 이 프로젝트 · append-only 오답노트

이 레포에서 완결한 문제의 교훈 — 차후 비슷한 작업에서 recall해 참고한다.
**완결 후 등록하는 기록이라 '상태'가 아니다**(append-only — 과거 항목은 사용자가 직접 지시할 때만 손댄다). 메인 세션만 append.
이 프로젝트에 한정된 교훈만 둔다 — 머신 전역은 PC solved, 보편은 디시플린 원칙으로(스코프 라우팅).
EOF
      ;;
    project:1)
      cat <<'EOF'
# 해결된 문제 로그 (solved_problems) — 이 프로젝트 · 지시사항 색인

일을 시작하기 전에 아래 「지시사항 색인」의 줄을 훑고, 지금 하려는 작업에 걸리는 줄이 있으면 그 줄이 가리키는 본문 파일 하나만 연다. 걸리는 줄이 없으면 아무 파일도 열지 않는다.

이 레포에서 완결한 문제의 교훈 — 일을 시작할 때 걸리는 지시사항만 여기 두고 증상과 원인은 본문 파일에 둔다.
본문 파일은 append-only 이고 색인 줄은 그 본문을 따라 고친다. 본문을 고치거나 지울 때만 색인 줄도 함께 손댄다.
이 프로젝트에 한정된 교훈만 둔다 — 머신 전역은 PC solved, 보편은 디시플린 원칙으로(스코프 라우팅).
EOF
      ;;
    *)
      echo "[disciplined-coder] WARNING: 알 수 없는 오답노트 스코프 '$1'" >&2
      return 1
      ;;
  esac
  printf '\n%s\n' "$(scaffold_solved_rules_for "${2:-}")"
}

# solved 오답노트: 없을 때만 생성(append-only). 생성했으면 0, 이미 있으면 1을 리턴.
# 주의(유지보수 함정): '이미 존재'라는 정상 경로가 1을 리턴하므로 호출은 반드시 if로 감싼다 —
# set -e 아래 bare 호출은 매 세션 스크립트를 죽인다.
scaffold_ensure_solved() {  # $1=KDIR
  local kdir="$1"
  [ -f "$kdir/solved_problems.md" ] && return 1
  scaffold_solved_header pc "" > "$kdir/solved_problems.md"
  return 0
}

# 오답노트 형식 규칙이 낡았는지 본다. 읽기만 하고 어떤 파일에도 쓰지 않는다.
# 어떤 경우에도 0을 리턴하고, 결과는 이 함수 전용 고정 이름에 셋한다 — 호출자가 이름을 정하게 하면
# 함수 안의 지역 선언과 겹쳐 대입이 지역 변수로 흡수되고 조용히 유실된다(모드 라인 변수 분리와 같은 이유).
# 판정은 구간 추출이 아니라 포함 검사다. 사람이 쓴 로그에서 규칙 불릿과 항목 불릿은 같은 모양이라
# 경계를 떼어 내려 하면 사용자가 빈 줄을 빼거나 메모를 끼운 순간 흔들린다.
# grep -F를 쓰지 않는 이유: 그것은 패턴의 각 줄을 별개 후보로 보는 줄 단위 검사라 여덟 줄 중 하나만
# 있어도 참이 된다. case의 리터럴 부분일치는 여러 줄을 통째로 본다.
# 줄 끝은 양쪽 다 정규화하고, 명령 치환이 후행 개행을 먹으므로 블록이 파일 끝에 놓여도 일치한다.
scaffold_check_solved_rules() {  # $1=로그 경로 → sets: solved_rules_stale (1=낡음, 0=최신이거나 판정 안 함)
  local f="$1" body rules
  solved_rules_stale=0
  [ -f "$f" ] || return 0
  body="$(tr -d '\r' < "$f" 2>/dev/null)" || return 0
  rules="$(scaffold_solved_rules_for "$f")"
  case "$body" in
    *"$rules"*) solved_rules_stale=0 ;;
    *) solved_rules_stale=1 ;;
  esac
  return 0
}

# 낡은 머리말을 정본으로 갈아끼운다. 항목은 한 줄도 다시 쓰지 않는다(tail로 통째 옮긴다).
# 머리말의 끝은 '첫 구조 요소'(하위 제목이나 목록 줄) 직전이다. 첫 항목만 경계로 삼으면, 사람이
# 머리말 뒤에 만들어 둔 절(다이제스트 절 같은 것)까지 머리말로 보고 지운다 — 실측된 로그에 있던
# 모양이라 제목도 경계로 센다. 구조 요소가 하나도 없으면 경계를 알 수 없으므로 손대지 않는다.
# 줄 끝이 CRLF인 로그는 머리말만 LF로 바뀌어 섞이지만, 규칙 검사가 CR을 지우고 비교하므로
# 다음 세션에 다시 발동하지는 않는다.
# 결과는 이 함수 전용 고정 이름에 셋한다(scaffold_check_solved_rules와 같은 이유).
# 손대지 못한 사유는 셋이고 사람이 할 일이 서로 다르다 — 경계를 못 찾으면 로그를 손봐야 하고,
# 사본이나 임시 파일을 못 쓰면 그 자리의 쓰기 권한을 풀어야 한다. 한 문구로 뭉개면 쓰기가 막힌
# PC에서 멀쩡한 머리말을 고치려 들게 되고, 그 신호는 끄는 수단이 없다(`FAIL-LOUD`).
scaffold_fix_solved_header() {  # $1=로그 $2=스코프 $3=백업 디렉터리 $4=백업 이름표
                                # → sets: solved_fix_result(fixed|refused|none),
                                #         solved_fix_reason(boundary|backup|write|""), solved_fix_backup
  local f="$1" scope="$2" bdir="$3" label="$4" n tmp stamp bk rules
  solved_fix_result="none"; solved_fix_reason=""; solved_fix_backup=""
  [ -f "$f" ] || return 0
  rules="$(scaffold_solved_rules_for "$f")"
  # 아는 규칙 줄은 두 블록 전부다. 그 로그에 걸 블록만 알아보면, 형태가 바뀌는 회차에 옛 블록이
  # 본문으로 밀려나 규칙이 두 벌이 된다 — 한 파일이 서로 다른 형식을 둘 다 규정하게 되고,
  # 낡음 판정은 새 블록이 있으니 조용하다.
  n="$(awk -v rules="$rules" -v allrules="$SCAFFOLD_SOLVED_RULES"$'\n'"$SCAFFOLD_SOLVED_RULES_SPLIT" '
    BEGIN {
      nr = split(rules, rl, "\n")
      intro = rl[1]
      na = split(allrules, al, "\n")
      for (k = 1; k <= na; k++) if (al[k] != "" && al[k] != intro) known[al[k]] = 1
    }
    { l=$0; sub(/\r$/,"",l); line[NR]=l }
    END {
      seen=0
      for (i=1;i<=NR;i++) if (line[i]==intro) { seen=i; break }
      if (seen) {
        # 규칙 블록이 일부만 남은 로그가 있다. 도입 문장 뒤의 빈 줄과 "이 블록에 실제로 있는 줄"만
        # 머리말로 센다 — 항목으로 오인해 아래에 붙이면 블록이 두 벌이 된다.
        # 모양으로 짐작하지 않는 이유는, 굵지 않은 최상위 불릿이 곧 지시사항형 색인 줄의 모양이라
        # 짐작하는 순간 그 줄들을 통째로 머리말로 먹기 때문이다(실측으로 확인했다).
        for (i=seen+1;i<=NR;i++) {
          if (line[i]=="") continue
          if (line[i] in known) continue
          print i; exit
        }
        print NR+1; exit
      }
      for (i=1;i<=NR;i++)
        if (line[i] ~ /^##/ || line[i] ~ /^[-*+][ \t]/ || line[i] ~ /^[0-9]+\.[ \t]/) { print i; exit }
      print 0
    }
  ' "$f" 2>/dev/null || true)"
  if [ -z "$n" ] || [ "$n" = "0" ]; then
    solved_fix_result="refused"; solved_fix_reason="boundary"; return 0
  fi
  # 사본이 유일한 복구 수단이다(이 로그들은 git 밖일 수 있다) — 뜨지 못하면 아예 고치지 않는다.
  stamp="$(date +%Y%m%d-%H%M%S 2>/dev/null || echo unknown)"
  bk="$bdir/solved_problems.$label.$stamp.md"
  if ! mkdir -p "$bdir" 2>/dev/null || ! cp "$f" "$bk" 2>/dev/null; then
    solved_fix_result="refused"; solved_fix_reason="backup"; return 0
  fi
  tmp="$(mktemp "$f.XXXXXX" 2>/dev/null)" || {
    solved_fix_result="refused"; solved_fix_reason="write"; solved_fix_backup="$bk"; return 0
  }
  # 도중에 강제로 끝나도 임시 파일을 남기지 않는다. 남으면 사용자 레포의 docs/ 에
  # solved_problems.md.a1B2c3 같은 것이 쌓이는데, 이 함수는 남의 프로젝트 폴더도 만진다.
  # 트랩은 이 함수가 만든 파일 하나만 지우고, 나가기 전에 반드시 푼다 — 부르는 쪽은 EXIT 트랩을
  # 쓰지 않으므로 여기서 풀어도 남의 트랩을 지우지 않는다.
  trap 'rm -f "$tmp" 2>/dev/null || true' INT TERM EXIT
  if { scaffold_solved_header "$scope" "$f" && printf '\n' && tail -n "+$n" "$f"; } > "$tmp" 2>/dev/null \
     && mv "$tmp" "$f" 2>/dev/null; then
    solved_fix_result="fixed"; solved_fix_backup="$bk"
  else
    rm -f "$tmp" 2>/dev/null || true
    solved_fix_result="refused"; solved_fix_reason="write"; solved_fix_backup="$bk"
  fi
  trap - INT TERM EXIT
  return 0
}

# 로그 하나를 현행 형식에 맞춘다(검사 → 갱신 → 사람이 읽을 한 줄). 두 스캐폴드가 전역 로그와
# 프로젝트 로그에 같은 절차를 쓰도록 여기 둔다. 알릴 것이 없으면 solved_sync_note는 빈 문자열이다.
scaffold_sync_solved() {  # $1=로그 $2=스코프 $3=백업 디렉터리 $4=백업 이름표 → sets: solved_sync_note
  local f="$1" bdir="$3"
  solved_sync_note=""
  [ -f "$f" ] || return 0
  scaffold_check_solved_rules "$f"
  [ "${solved_rules_stale:-0}" -eq 1 ] || return 0
  scaffold_fix_solved_header "$f" "$2" "$3" "$4"
  # 문안에 로그의 머리말 문구를 인용하지 않는다 — 인용하면 그 stdout이 정본 헤더를 한 번 더 실어
  # 이중 주입 회귀 가드가 뒤집힌다. 경로와 한 일만 적는다.
  # 손대지 못했으면 사유를 가려 적는다. 사유마다 사람이 할 일이 다르기 때문이다.
  if [ "$solved_fix_result" = "fixed" ]; then
    solved_sync_note="🔵 disciplined-coder: $f 의 머리말을 현행 형식으로 갱신했다(항목은 그대로 두었다. 사본: $solved_fix_backup)."
  elif [ "$solved_fix_reason" = "backup" ]; then
    solved_sync_note="🔵 disciplined-coder: $f 의 형식 규칙 서술이 현행과 다르다 — 사본을 뜨지 못해 그대로 두었다($bdir 에 쓸 수 있게 되면 다음 세션에 다시 시도한다)."
  elif [ "$solved_fix_reason" = "write" ]; then
    solved_sync_note="🔵 disciplined-coder: $f 의 형식 규칙 서술이 현행과 다르다 — 사본은 떴으나 파일을 새로 쓰지 못해 그대로 두었다(사본: $solved_fix_backup)."
  else
    solved_sync_note="🔵 disciplined-coder: $f 의 형식 규칙 서술이 현행과 다르다 — 머리말의 끝을 알아볼 수 없어 그대로 두었다(방법은 domain-docs 스킬)."
  fi
  return 0
}

# (제거됨) 오답노트 처분 모드·ultracode 검증 모드 토글. 둘 다 훅이 강제하지 못하는 문장 주입일 뿐이었고,
# 기본값이 사실상 무동작이라 옵트인 플래그 하나에 지나지 않았다 — 모르면 안 쓰게 되는 설정이다.
# 처분은 surface로 고정하고, ultracode 검증 요구는 agent-principles.md 검증 레이어 표에만 둔다.

# grep -c 는 0건일 때 stdout 에 0 을 찍고 종료코드 1 로 끝난다. 거기에 `|| echo 0` 을 붙이면
# 값이 두 줄("0\n0")이 되어 어떤 비교와도 안 맞는다 — 실제로 그 함정을 밟아 빈 로그를 가진
# 새 PC 마다 오탐이 뜨는 결함이 계획 리뷰에서 잡혔다. `|| true` 를 써서 stdout 한 줄만 남긴다.
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

scaffold_check_solved_pairing() {  # $1=로그 경로 → sets: solved_pairing_note
  local f="$1" dir counts unmigrated unwritten want have only_index only_body
  solved_pairing_note=""
  [ -f "$f" ] || return 0
  scaffold_solved_log_is_split "$f" || return 0
  dir="${f%.md}"
  want="$(grep -oE '→ solved_problems/[^[:space:]]+' "$f" 2>/dev/null | sed 's|.*/||' | sort -u || true)"
  have="$(ls -1 "$dir" 2>/dev/null | grep -E '\.md$' | sort -u || true)"
  only_index="$(scaffold_names_only_in_first "$want" "$have")"
  only_body="$(scaffold_names_only_in_first "$have" "$want")"
  # 이웃 관계로 갈라야 한다 — 굵은 줄 자신만 보면 포인터가 달렸는지 알 수 없다.
  counts="$(awk '
    {
      l=$0
      if (substr(l, length(l), 1) == sprintf("%c", 13)) l = substr(l, 1, length(l) - 1)
      line[NR]=l
    }
    END {
      for (i = 1; i <= NR; i++) {
        if (line[i] !~ /^[-*+][[:space:]]+[*][*]/) continue
        if (i < NR && index(line[i+1], "→ solved_problems/") > 0) written++; else moved++
      }
      print moved + 0, written + 0
    }' "$f" 2>/dev/null)"
  [ -n "$counts" ] || counts="0 0"
  unmigrated="${counts%% *}"; unwritten="${counts##* }"
  if [ -n "$only_index" ] || [ -n "$only_body" ]; then
    solved_pairing_note="🔵 disciplined-coder: $f 의 색인과 본문이 어긋난다(고치지 않았다)."
    [ -z "$only_index" ] || solved_pairing_note="$solved_pairing_note 가리키는 본문이 없는 색인 줄: $only_index — 그 줄을 지워라."
    [ -z "$only_body" ] || solved_pairing_note="$solved_pairing_note 색인 줄이 없는 본문 파일: $only_body — 그 파일의 첫 줄로 색인 줄을 채워라."
  else
    solved_pairing_note=""
    [ "$unmigrated" = "0" ] || solved_pairing_note="🔵 disciplined-coder: $f 에 아직 손으로 가를 항목 ${unmigrated}개가 남아 있다(포인터 없는 굵은 줄이다. 본문 파일로 옮기고 포인터를 달아라)."
    if [ "$unwritten" != "0" ]; then
      [ -z "$solved_pairing_note" ] || solved_pairing_note="$solved_pairing_note
"
      solved_pairing_note="${solved_pairing_note}🔵 disciplined-coder: $f 에 아직 지시사항으로 못 고친 색인 줄 ${unwritten}개가 남아 있다(굵기를 벗기며 지시사항 한 문장으로 고쳐라)."
    fi
  fi
  return 0
}

# 아직 안 쪼개진 로그를 만나면 개편을 권한다. 읽기만 한다.
# 항목 수를 함께 내는 이유는 개편에 드는 값이 항목 수에 비례하기 때문이다 — 지시사항 줄을 새로
# 쓰는 일은 기계가 못 하므로 승낙한 세션이 그 자리에서 항목 수만큼 다시 써야 한다.
# 스크립트 경로를 절대경로로 적는 이유는 이 신호가 옆 프로젝트에서 뜨는데 그 cwd 에는 그 파일이
# 없기 때문이다 — 스크립트는 플러그인 루트 안에 있고, 그 값은 호출자만 안다.
# 인자 셋을 채워 적는 이유는 그 스크립트가 로그 경로와 백업 디렉터리와 사본 이름표를 받기
# 때문이다. 이름만 알려 주면 받은 세션이 백업 자리를 스스로 정하게 되고, 사본이 프로젝트 폴더
# 같은 엉뚱한 곳에 떨어져 '프로젝트 폴더에 파일을 남기지 않는다'가 그 자리에서 깨진다.
# 이름표까지 채우는 이유는 머리말 동기화가 뜨는 사본과 같은 이름 규칙으로 쌓이게 하려는 것이다 —
# 안 넘기면 쪼개는 쪽만 다른 규칙으로 이름을 지어 같은 폴더에서 두 규칙이 섞인다.
scaffold_check_solved_unsplit() {  # $1=로그 경로 $2=플러그인 루트 $3=백업 디렉터리 $4=사본 이름표 → sets: solved_unsplit_note
  local f="$1" root="$2" bdir="$3" label="${4:-}" n
  solved_unsplit_note=""
  [ -f "$f" ] || return 0
  scaffold_solved_log_is_split "$f" && return 0
  n="$(scaffold_count_matches "$f" '^[-*+][[:space:]]+\*\*')"
  [ "$n" = "0" ] && return 0
  solved_unsplit_note="🔵 disciplined-coder: $f 가 아직 안 쪼개진 형식이다(항목 ${n}개). 지금 개편할지 사용자에게 물어라 — 첫 선택지가 '지금 개편한다'이고 그것이 권장값이다. 개편은 bash $root/scripts/split_solved_log.sh \"$f\" \"$bdir\" $label 로 쪼갠 뒤 지시사항 줄을 새로 쓰는 것이다."
  return 0
}
