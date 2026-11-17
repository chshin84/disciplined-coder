#!/usr/bin/env bash
# scaffold.sh에서 분리한 관리 디렉터리 정책 — 원본은 이 파일이다.

# 관리 디렉터리에 두는 파일. 스캐폴드가 복사하고 주입하는 것이 이 목록이다.
SCAFFOLD_FILES="agent-principles.md korean-banned-words.md"
# 스킬 managing-docs 의 사본. Skill 도구가 없는 에이전트도 에이전트원칙의 포인터가 적은 이 경로를 Read 로
# 읽는다. "원본(플러그인 루트 기준)=사본(관리 디렉터리 기준)" 쌍이다. @import 와 첫 세션 보강에는 넣지 않는다.
# lens-review 의 문체 공격 항목은 다른 프로젝트에서 독자 렌즈에 기준 파일로 넘기는 사본이다(플러그인 캐시 경로는
# 버전마다 바뀌어 렌즈에 넘기기 어렵다).
SCAFFOLD_REFS="skills/managing-docs/SKILL.md=managing-docs/SKILL.md skills/managing-docs/references/reading-docs.md=managing-docs/reading-docs.md skills/lens-review/references/style-attacks.md=lens-review/style-attacks.md"
# 화이트리스트는 이 파일들에 backups 디렉터리와 사용자가 쓰는 파일을 더한 것이다. 위생 검사가 이
# 목록 밖을 훑는다. 파일 이름을 다른 곳에 다시 적지 않는다 — 여기만 고친다.
# plugin-notice.skip 은 함께 쓰는 플러그인 알림을 끄려고 사용자가 이름을 적는 파일이라, 스캐폴드가
# 만들지도 지우지도 않지만 잔존 경고를 내서도 안 된다.
# update.seen 과 update.stuck 은 hooks/update_check_sessionstart.sh 가 쓰는 갱신 확인 기록이다.
# reviews 는 lens-review 가 다른 프로젝트의 전달 문서를 검진한 기록을 두는 폴더다(managing-docs 「기록 파일 이름 규칙」).
SCAFFOLD_WHITELIST="$SCAFFOLD_FILES managing-docs lens-review reviews backups plugin-notice.skip update.seen update.stuck"
scaffold_hygiene() {  # $1=KDIR
  local kdir="$1" f b w keep
  for f in "$kdir"/*; do
    [ -e "$f" ] || continue
    b="${f##*/}"
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
