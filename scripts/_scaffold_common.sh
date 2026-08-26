#!/usr/bin/env bash
# 공유: scaffold.sh(Claude)와 codex-scaffold.sh(Codex)의 공통 로직(SSOT).
# 두 스크립트는 홈 위치·주입 방식만 다르고 관리 디렉터리 정책은 동일해야 한다 — 여기가 정본.

# 관리 디렉터리 화이트리스트(=현 정본 세트)와 구 관리파일(STALE). 여기만 고친다.
SCAFFOLD_WHITELIST="agent-principles.md domains-index.md solved_problems.md backups"
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

# 위생(멱등): STALE 제거 → 비화이트리스트는 디렉터리/내용파일 surface·빈 파일 제거.
scaffold_hygiene() {  # $1=KDIR
  local kdir="$1" f b w keep
  # 구 관리파일 치우기. 내용이 있으면 사용자가 적어 둔 줄이 섞여 있을 수 있으므로 지우지 않고
  # 백업으로 옮긴다 — 관리 디렉터리에서는 사라지되 되돌릴 수는 있어야 한다(REVERSIBLE).
  for f in $SCAFFOLD_STALE; do
    [ -f "$kdir/$f" ] || continue
    if [ -s "$kdir/$f" ] && mkdir -p "$kdir/backups" 2>/dev/null; then
      mv "$kdir/$f" "$kdir/backups/$f.$(date +%Y%m%d-%H%M%S).bak" 2>/dev/null || rm -f "$kdir/$f" || true
    else
      rm -f "$kdir/$f" || true
    fi
  done
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
scaffold_solved_header() {  # $1=스코프(pc|project) → stdout: 제목부터 형식 규칙 블록까지
  case "$1" in
    pc)
      cat <<'EOF'
# 해결된 문제 로그 (solved_problems) — PC 전역 · append-only 오답노트

완결된 문제의 교훈 모음 — 차후 비슷한 작업에서 recall해 참고한다.
**완결 후 등록하는 기록이라 '상태'가 아니다** — "문서에 상태 금지"의 예외(append-only — 과거 항목은 사용자가 직접 지시할 때만 손댄다).
일반화 가능한 항목은 디시플린(agent-principles.md)으로 **재기술해 승격**한다(원문은 append-only로 보존 — 이동이 아니라 상위 계층 재작성). 메인 세션만 기록.
EOF
      ;;
    project)
      cat <<'EOF'
# 해결된 문제 로그 (solved_problems) — 이 프로젝트 · append-only 오답노트

이 레포에서 완결한 문제의 교훈 — 차후 비슷한 작업에서 recall해 참고한다.
**완결 후 등록하는 기록이라 '상태'가 아니다**(append-only — 과거 항목은 사용자가 직접 지시할 때만 손댄다). 메인 세션만 append.
이 프로젝트에 한정된 교훈만 둔다 — 머신 전역은 PC solved, 보편은 디시플린 원칙으로(스코프 라우팅).
EOF
      ;;
    *)
      echo "[disciplined-coder] WARNING: 알 수 없는 오답노트 스코프 '$1'" >&2
      return 1
      ;;
  esac
  printf '\n%s\n' "$SCAFFOLD_SOLVED_RULES"
}

# solved 오답노트: 없을 때만 생성(append-only). 생성했으면 0, 이미 있으면 1을 리턴.
# 주의(유지보수 함정): '이미 존재'라는 정상 경로가 1을 리턴하므로 호출은 반드시 if로 감싼다 —
# set -e 아래 bare 호출은 매 세션 스크립트를 죽인다.
scaffold_ensure_solved() {  # $1=KDIR
  local kdir="$1"
  [ -f "$kdir/solved_problems.md" ] && return 1
  scaffold_solved_header pc > "$kdir/solved_problems.md"
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
  local f="$1" body
  solved_rules_stale=0
  [ -f "$f" ] || return 0
  body="$(tr -d '\r' < "$f" 2>/dev/null)" || return 0
  case "$body" in
    *"$SCAFFOLD_SOLVED_RULES"*) solved_rules_stale=0 ;;
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
  rules="$SCAFFOLD_SOLVED_RULES"
  n="$(awk -v rules="$rules" '
    BEGIN {
      nr = split(rules, rl, "\n")
      intro = rl[1]
      for (k = 2; k <= nr; k++) if (rl[k] != "") known[rl[k]] = 1
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
  if { scaffold_solved_header "$scope" && printf '\n' && tail -n "+$n" "$f"; } > "$tmp" 2>/dev/null \
     && mv "$tmp" "$f" 2>/dev/null; then
    solved_fix_result="fixed"; solved_fix_backup="$bk"
  else
    rm -f "$tmp" 2>/dev/null || true
    solved_fix_result="refused"; solved_fix_reason="write"; solved_fix_backup="$bk"
  fi
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
