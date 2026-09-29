#!/usr/bin/env bash
# 공유: Stop 훅 둘(spec_review_stop.sh·doc_word_stop.sh)의 공통 머리. 루프가드를 보고, 훅 입력의 cwd 로
# 옮긴 뒤 저장소 루트로 옮긴다. 볼 것이 없으면 그 자리에서 훅을 끝낸다(exit 0).
# 호출자가 $INPUT 을 채우고 _hook_input.sh 와 _json_escape.sh 를 먼저 싣는다.
#
# git 이 "저장소가 아니다"라고 답하면 볼 대상이 없으니 조용히 끝낸다(FAIL-OPEN). 그 밖의 실패(소유권
# 의심·인덱스 손상)는 검사하지 못한 것이므로 알리고 끝낸다 — 아무 신호 없이 열리면 훅이 꺼진 것을
# 알아챌 방법이 없다.
# 루트로 옮기는 이유: git status 의 pathspec 은 현재 폴더 기준이고 diff-tree 와 status 가 돌려주는
# 경로와 `[ -f "$f" ]` 는 루트 기준이다. 하위 폴더(예: myrepo/backend)에서 돌면 파일을 하나도 못
# 찾고 아무 메시지 없이 통과한다.
stop_enter_repo() {  # $1=git 을 못 읽었을 때 알림에 넣을 "무엇을 검사하지 못했다" 문구
  local cwd gitout root
  case "$INPUT" in *'"stop_hook_active":true'*|*'"stop_hook_active": true'*) exit 0 ;; esac  # 루프가드
  command -v git >/dev/null 2>&1 || exit 0
  json_str cwd cwd
  slash_norm cwd
  if [ -n "$cwd" ]; then cd "$cwd" 2>/dev/null || exit 0; fi
  gitout="$(git rev-parse --is-inside-work-tree 2>&1)" || {
    case "$gitout" in *'not a git repository'*) exit 0 ;; esac
    printf '{"systemMessage":"%s"}\n' "$(escape_for_json "disciplined-coder: git 을 읽지 못해 $1 — ${gitout%%$'\n'*}")"
    exit 0
  }
  root="$(git rev-parse --show-toplevel 2>/dev/null || true)"
  [ -n "$root" ] || exit 0
  cd "$root" 2>/dev/null || exit 0
}
