#!/usr/bin/env bash
# 훅 스크립트 검증. 계약: FAIL=0 (매직넘버 금지 — 개수는 테스트가 센다).
set -euo pipefail
HERE="$(cd "$(dirname "$0")/.." && pwd)"
# 픽스처는 모두 이 뿌리 아래에 만들고 끝나면 통째로 지운다. mktemp 가 TMPDIR 을 따르므로 아래의
# mktemp 호출과 이 검사가 부르는 스크립트의 임시 파일이 모두 여기로 온다.
TEST_TMP="$(mktemp -d)"; trap 'rm -rf "$TEST_TMP"' EXIT; export TMPDIR="$TEST_TMP"
PTU="$HERE/hooks/spec_review_posttooluse.sh"
STOP="$HERE/hooks/spec_review_stop.sh"
FPRE="$HERE/hooks/doc_format_pretooluse.sh"
DREV="$HERE/hooks/doc_review_posttooluse.sh"
pass=0; fail=0
check() { if eval "$2"; then echo "  PASS: $1"; pass=$((pass+1)); else echo "  FAIL: $1"; fail=$((fail+1)); fi; }
ptu() { printf '%s' "$1" | bash "$PTU"; }
stop() { printf '%s' "$1" | bash "$STOP"; }
fpre() { printf '%s' "$1" | bash "$FPRE"; }
drev() { printf '%s' "$1" | bash "$DREV"; }
J() { printf '{"tool_input":{"file_path":"%s"}}' "$1"; }
extract() { ( INPUT="$1"; . "$HERE/hooks/_hook_input.sh"; hook_file_paths; printf '%s' "$FILE_PATHS" ); }
. "$HERE/scripts/_json_valid.sh"   # JSON 유효성 검사기(공유)

T="$(mktemp -d)"; SP="$T/docs/superpowers/specs"; PL="$T/docs/superpowers/plans"; mkdir -p "$SP" "$PL" "$T/src"
export CLAUDE_PROJECT_DIR="$T"   # 문서 넛지는 프로젝트 안에서만 뜬다 — 픽스처 폴더를 프로젝트로 삼는다
OUTSIDE="$(mktemp -d)"          # 프로젝트 밖(메모리·계획 파일이 놓이는 곳)
printf 'draft body\n' > "$SP/nomark.md"
printf 'draft body\n' > "$PL/nomark.md"
printf 'body\n<!-- spec-review: passed lenses=3 date=2026-06-14 -->\n' > "$SP/passed.md"
printf 'body\n<!-- spec-review: escalated lenses=3 date=2026-06-14 -->\n' > "$SP/esc.md"
# 본문 중간에 예시 마커, 마지막 줄은 일반 → 거짓매칭 방지 검증
printf 'see <!-- spec-review: passed --> example\nmore body text here\n' > "$SP/example.md"
# pending 은 마커 아님(terminal 만 인정)
printf 'body\nspec-review: { status: pending }\n' > "$SP/pending.md"
# CRLF terminal 마커
printf 'body\r\n<!-- spec-review: passed lenses=3 date=2026-06-14 -->\r\n' > "$SP/crlf.md"
# 마지막 줄이 마커를 산문으로 언급만 한다 — 마커를 남긴 것이 아니므로 게이트가 열리면 안 된다.
printf 'body\n마지막 줄에 <!-- spec-review: passed -->를 적어야 게이트가 풀린다.\n' > "$SP/prose.md"
# 마지막 줄이 마커로 시작하지만 닫히지 않았다 — 마커가 아니다.
printf 'body\n<!-- spec-review: passed 라고 적으면 안 된다\n' > "$SP/unclosed.md"

echo "[extract]"
check "Claude file_path → 경로 1개"        "[ \"\$(extract '$(J "$T/src/a.md")')\" = '$T/src/a.md' ]"
check "빈 입력 → 무출력"                    "[ -z \"\$(extract '{}')\" ]"
check "Claude backslash path → normalized" "[ \"\$(extract '$(J 'C:\\\\dir\\\\f.md')')\" = 'C:/dir/f.md' ]"

echo "[ptu]"
check "spec 미마커 → 리뷰 지시"          "ptu '$(J "$SP/nomark.md")' | grep -q additionalContext"
check "plan 미마커 → 리뷰 지시"          "ptu '$(J "$PL/nomark.md")' | grep -q additionalContext"
check "무관 경로 → 무출력"               "[ -z \"\$(ptu '$(J "$T/src/main.py")')\" ]"
check "OFF → 무출력"                     "[ -z \"\$(DISCIPLINED_CODER_REVIEW_GATE=off ptu '$(J "$SP/nomark.md")')\" ]"
check "프로젝트 밖 spec → 무출력"        "[ -z \"\$(ptu '$(J "$OUTSIDE/docs/superpowers/specs/x.md")')\" ]"
check "terminal passed → 무출력"         "[ -z \"\$(ptu '$(J "$SP/passed.md")')\" ]"
check "terminal escalated → 무출력"      "[ -z \"\$(ptu '$(J "$SP/esc.md")')\" ]"
check "CRLF terminal → 무출력"           "[ -z \"\$(ptu '$(J "$SP/crlf.md")')\" ]"
check "본문 예시만(마지막 일반) → 지시"  "ptu '$(J "$SP/example.md")' | grep -q additionalContext"
check "pending(마커 아님) → 지시"        "ptu '$(J "$SP/pending.md")' | grep -q additionalContext"
check "산문 안 마커(마지막 줄) → 지시"   "ptu '$(J "$SP/prose.md")' | grep -q additionalContext"
check "안 닫힌 마커 → 지시"              "ptu '$(J "$SP/unclosed.md")' | grep -q additionalContext"

echo "[stop]"
# $G = git 저장소 + 미리뷰 spec. 게이트 ON이면 block 이므로, loop guard/OFF가 깨지면
# 빈 출력이 아니라 block이 나와 변별된다(비-git $T는 FAIL-OPEN으로 항상 빈 출력 → 변별 불가).
G="$(mktemp -d)"; ( cd "$G" && git init -q && git config user.email t@t && git config user.name t )
mkdir -p "$G/docs/superpowers/specs"
printf 'draft\n' > "$G/docs/superpowers/specs/new.md"
check "loop guard(active) → 통과"        "[ -z \"\$(stop '{\"stop_hook_active\":true,\"cwd\":\"$G\"}')\" ]"
check "OFF → 통과"                       "[ -z \"\$(DISCIPLINED_CODER_REVIEW_GATE=off stop '{\"cwd\":\"$G\"}')\" ]"
check "미리뷰 spec → block"              "stop '{\"cwd\":\"$G\"}' | grep -q '\"block\"'"
# 세션의 작업 폴더가 레포 하위 폴더여도 찾아야 한다. 전에는 두 탐색이 모두 현재 폴더 기준이라
# 하위 폴더에서 열면 미리뷰 spec을 하나도 못 찾고 아무 메시지 없이 통과시켰다 — 게이트가 꺼진
# 것을 알아챌 방법이 없는 조용한 실패다.
mkdir -p "$G/backend/deep"
check "하위 폴더 cwd → block"            "stop '{\"cwd\":\"$G/backend\"}' | grep -q '\"block\"'"
check "더 깊은 하위 폴더 cwd → block"    "stop '{\"cwd\":\"$G/backend/deep\"}' | grep -q '\"block\"'"
printf 'draft\n<!-- spec-review: passed lenses=3 date=2026-06-14 -->\n' > "$G/docs/superpowers/specs/new.md"
check "passed 마커 후 → 통과"            "[ -z \"\$(stop '{\"cwd\":\"$G\"}')\" ]"
printf 'draft\n<!-- spec-review: escalated lenses=3 date=2026-06-14 -->\n' > "$G/docs/superpowers/specs/new.md"
check "escalated 마커 후 → 통과"         "[ -z \"\$(stop '{\"cwd\":\"$G\"}')\" ]"
# 파일명 파싱 강건성: git porcelain이 따옴표로 감싸거나(공백·비ASCII) 리네임 화살표로 합치면
# 게이트가 조용히 우회되면 안 된다. new.md 는 위에서 escalated(리뷰됨)이므로 차단 안 됨.
printf 'draft\n' > "$G/docs/superpowers/specs/my spec.md"
check "공백 파일명 미리뷰 spec → block"  "stop '{\"cwd\":\"$G\"}' | grep -q '\"block\"'"
rm "$G/docs/superpowers/specs/my spec.md"
printf 'draft\n' > "$G/docs/superpowers/specs/명세.md"
check "한글 파일명 미리뷰 spec → block"  "stop '{\"cwd\":\"$G\"}' | grep -q '\"block\"'"
rm "$G/docs/superpowers/specs/명세.md"
printf 'draft\n' > "$G/docs/superpowers/specs/torename.md"
( cd "$G" && git add -A && git commit -qm init )
( cd "$G" && git mv docs/superpowers/specs/torename.md docs/superpowers/specs/renamed.md )
check "리네임된 미리뷰 spec → block"     "stop '{\"cwd\":\"$G\"}' | grep -q '\"block\"'"
# FAIL-OPEN(문서화된 한계): git/디렉터리 부재 시 차단하지 말고 통과해야 한다(작업불능 방지).
NG="$(mktemp -d)"   # git 저장소 아님
check "non-git cwd → FAIL-OPEN(통과)"    "[ -z \"\$(stop '{\"cwd\":\"$NG\"}')\" ]"
# git 자체가 실패하면(소유권 의심·인덱스 손상) 조용히 열지 않고 알린다. 저장소가 아닌 것과 가르므로
# 가짜 git으로 그 실패를 흉내 낸다.
FG="$(mktemp -d)"; printf '#!/usr/bin/env bash\necho "fatal: detected dubious ownership in repository" >&2; exit 128\n' > "$FG/git"; chmod +x "$FG/git"
FGOUT="$( PATH="$FG:$PATH"; export PATH; stop "{\"cwd\":\"$G\"}" )"
check "git 실패 → 차단하지 않는다"       "! printf '%s' \"\$FGOUT\" | grep -q '\"block\"'"
check "git 실패 → 알림을 낸다"           "printf '%s' \"\$FGOUT\" | grep -q systemMessage"
check "존재하지 않는 cwd → FAIL-OPEN(통과)" "[ -z \"\$(stop '{\"cwd\":\"$NG/nope/x\"}')\" ]"
# Fix A: 신규 작성만 하드게이트 — 기존(추적된) spec 수정(상태 strip 등)은 막지 않는다. Fix B: dateless 마커 인식.
G2="$(mktemp -d)"; ( cd "$G2" && git init -q && git config user.email t@t && git config user.name t )
mkdir -p "$G2/docs/superpowers/specs"
printf 'draft\n<!-- spec-review: passed -->\n' > "$G2/docs/superpowers/specs/tracked.md"
( cd "$G2" && git add -A && git commit -qm init )
printf 'draft\n마커 뒤 본문 수정 → 마지막 줄이 마커가 아님\n' > "$G2/docs/superpowers/specs/tracked.md"
check "수정된 기존 spec(마커 깨짐) → 무차단(Fix A)"     "[ -z \"\$(stop '{\"cwd\":\"$G2\"}')\" ]"
printf 'fresh\n<!-- spec-review: passed -->\n' > "$G2/docs/superpowers/specs/freshmarked.md"
check "신규 spec + dateless 마커 → 무차단(Fix B 인식)"  "[ -z \"\$(stop '{\"cwd\":\"$G2\"}')\" ]"
printf 'brandnew\n' > "$G2/docs/superpowers/specs/brandnew.md"
check "수정+신규 미리뷰 동시 → 신규로 차단(Fix A)"      "stop '{\"cwd\":\"$G2\"}' | grep -q '\"block\"'"
# Fix C: 같은 턴 '커밋'으로 하드게이트가 조용히 열리면 안 된다 — HEAD가 추가한 spec도 검사.
G3="$(mktemp -d)"; ( cd "$G3" && git init -q && git config user.email t@t && git config user.name t )
mkdir -p "$G3/docs/superpowers/specs"
printf 'seed\n' > "$G3/README.md"
( cd "$G3" && git add -A && git commit -qm seed )
printf 'draft committed\n' > "$G3/docs/superpowers/specs/sneaky.md"
( cd "$G3" && git add -A && git commit -qm 'add spec' )
check "커밋된 미리뷰 spec(HEAD) → block(Fix C)"   "stop '{\"cwd\":\"$G3\"}' | grep -q '\"block\"'"
printf 'draft committed\n<!-- spec-review: passed -->\n' > "$G3/docs/superpowers/specs/sneaky.md"
check "HEAD spec에 마커 추가 후 → 통과(Fix C)"    "[ -z \"\$(stop '{\"cwd\":\"$G3\"}')\" ]"
( cd "$G3" && git add -A && git commit -qm 'mark reviewed' )
check "마커 커밋 후(HEAD=수정 커밋) → 통과(Fix C)" "[ -z \"\$(stop '{\"cwd\":\"$G3\"}')\" ]"

echo "[readonly-pre — 읽기 전용 파일은 고치지 않는다]"
RPRE="$HERE/hooks/readonly_pretooluse.sh"
rpre() { printf '%s' "$1" | bash "$RPRE"; }
RO="$(mktemp -d)"; printf 'sealed\n' > "$RO/sealed.md"; printf 'open\n' > "$RO/open.md"; chmod a-w "$RO/sealed.md"
check "훅 파일이 있다"                         "[ -f '$RPRE' ]"
check "읽기 전용 파일(절대경로) → deny"        "rpre '$(J "$RO/sealed.md")' | grep -qF '\"permissionDecision\":\"deny\"'"
check "거부 사유가 들어 있다"                  "rpre '$(J "$RO/sealed.md")' | grep -qF '읽기 전용 파일은 고치지 않는다'"
check "거부 응답이 유효한 JSON"                "rpre '$(J "$RO/sealed.md")' | json_valid_stdin"
check "쓸 수 있는 파일 → 무출력"               "[ -f '$RPRE' ] && [ -z \"\$(rpre '$(J "$RO/open.md")')\" ]"
check "없는 파일 → 무출력"                     "[ -f '$RPRE' ] && [ -z \"\$(rpre '$(J "$RO/nope.md")')\" ]"
check "상대경로(현재 폴더 기준) 읽기 전용 → deny" "( cd '$RO' && printf '%s' '$(J "sealed.md")' | bash '$RPRE' ) | grep -qF '\"permissionDecision\":\"deny\"'"
check "게이트 OFF 여도 거부한다"               "DISCIPLINED_CODER_REVIEW_GATE=off rpre '$(J "$RO/sealed.md")' | grep -qF '\"permissionDecision\":\"deny\"'"
check "README 가 이 훅을 적는다"               "grep -qF '읽기 전용 차단' '$HERE/README.md'"

echo "[rules-nudge-pre — 세션의 첫 도구 호출에 에이전트원칙의 절대경로와 domain-korean 을 한 번 알린다]"
# 표시 파일은 TMPDIR 아래에 남으므로 픽스처 폴더로 돌린다 — 안 그러면 스위트를 두 번째 돌릴 때 앞 실행의
# 표시 파일이 남아 "첫 편집" 검사가 조용히 깨진다. 두 번 돌려도 결과가 같아야 한다.
# 코드와 문서를 가르지 않는다. 셸 명령의 대상은 실행해 봐야 정해져 편집 전에 가를 방법이 없기 때문이다.
CNUD="$HERE/hooks/rules_nudge_pretooluse.sh"
mkdir -p "$T/tmp"
# cnud() 를 이 PC 의 실제 ~/.claude 에 매지 않는다 — 사본 없는 머신(예: 새 클론·CI)에서
# 훅이 "사본을 못 찾았다" 갈래로 빠져 아래 리터럴 단언들이 이 변경과 무관하게 빨개진다.
NH="$T/nudgehome"; mkdir -p "$NH/disciplined-coder"; printf 'x\n' > "$NH/disciplined-coder/agent-principles.md"
cnud() { printf '%s' "$1" | TMPDIR="$T/tmp" CLAUDE_HOME_DIR="$NH" bash "$CNUD"; }
JS() { printf '{"session_id":"%s"%s,"tool_input":{"file_path":"%s"}}' "$1" "$2" "$3"; }
JB() { printf '{"session_id":"%s","tool_name":"Bash","tool_input":{"command":"%s"}}' "$1" "$2"; }
check "훅 파일이 있다"                              "[ -f '$CNUD' ]"
check "첫 편집 → 에이전트원칙 경로 안내      "                "cnud '$(JS s1 "" "$T/src/main.py")' | grep -qF 'agent-principles.md'"
check "첫 편집 → domain-korean 도 함께 안내"       "cnud '$(JS s1z "" "$T/src/main.py")' | grep -qF 'domain-korean'"
check "안내가 유효한 JSON"                          "cnud '$(JS s1b "" "$T/src/main.py")' | json_valid_stdin"
check "안내는 PreToolUse 이벤트를 말한다"            "cnud '$(JS s1c "" "$T/src/main.py")' | grep -qF '\"hookEventName\":\"PreToolUse\"'"
check "같은 키 둘째 편집 → 무출력"                  "[ -z \"\$(cnud '$(JS s1 "" "$T/src/other.py")')\" ]"
check "같은 세션 다른 agent_id → 다시 안내"         "cnud '$(JS s1 ',"agent_id":"a1"' "$T/src/main.py")' | grep -qF 'agent-principles.md'"
check "문서(.md)도 대상이다"                        "cnud '$(JS s2 "" "$T/existing.md")' | grep -qF 'agent-principles.md'"
check "셸 편집(sed -i)도 대상이다"                  "cnud '$(JB s7 'sed -i s/a/b/ src/main.py')' | grep -qF 'agent-principles.md'"
check "셸 편집도 세션당 한 번이다"                  "[ -z \"\$(cnud '$(JB s7 'sed -i s/c/d/ src/other.py')')\" ]"
check "OFF → 무출력"                                "[ -z \"\$(DISCIPLINED_CODER_REVIEW_GATE=off cnud '$(JS s5 "" "$T/src/main.py")')\" ]"
check "session_id 없음 → 매번 안내"                 "cnud '$(J "$T/src/main.py")' | grep -qF 'agent-principles.md' && cnud '$(J "$T/src/main.py")' | grep -qF 'agent-principles.md'"
cnudh() { printf '%s' "$1" | TMPDIR="$T/tmp" CLAUDE_HOME_DIR="$2" bash "$CNUD"; }
# 넛지가 경로를 둘 알린다. 에이전트원칙 사본과 한국어 상세이고 놓이는 곳이 서로 다르다 — 에이전트원칙은 관리
# 디렉터리로 복사되고 상세는 설치본 root 에만 있다. 뽑을 때 뒤 문장의 '에 있다' 까지 삼키지 않도록
# 각각 뒤따르는 말로 끊는다. 둘 다 실재해야 한다 — 없는 파일을 열라고 시키지 않는다.
NUDGE_OUT="$(cnudh "$(JS s8 "" "$T/src/main.py")" "$NH")"
NUDGE_CANON="$(printf '%s' "$NUDGE_OUT" | sed -n 's/.*에이전트원칙의 사본은 \(.*\) 에 있다\. 한국어.*/\1/p')"
NUDGE_WK="$(printf '%s' "$NUDGE_OUT" | sed -n 's/.*한국어 문장 규칙의 상세는 \(.*\) 에 있다\..*/\1/p')"
check "넛지에서 에이전트원칙 경로가 뽑힌다"                 "[ -n \"\$NUDGE_CANON\" ]"
check "뽑은 경로에 파일이 실재한다"                 "[ -f \"\$NUDGE_CANON\" ]"
check "넛지에서 한국어 상세 경로가 뽑힌다"          "[ -n \"\$NUDGE_WK\" ]"
check "그 상세 경로에도 파일이 실재한다"            "[ -f \"\$NUDGE_WK\" ]"
check "넛지에 상시 적재라는 거짓 문장이 없다"       "! cnudh '$(JS s8b "" "$T/src/main.py")' '$NH' | grep -qF '상시로 싣고'"
check "사본이 없으면 그 사실을 알린다"              "cnudh '$(JS s8c "" "$T/src/main.py")' '$T/emptyhome' | grep -qF '사본을 못 찾았다'"

echo "[rules-nudge-sessionstart — 세션이 시작·재개·비워지면 그 세션의 표시를 지운다]"
# 표시 파일은 "이 맥락에서 이미 알렸다"를 뜻한다. 재개한 세션이 같은 session_id 를 다시 받는지는 훅 문서가
# 정하지 않는데, 이 훅이 있으면 어느 쪽이든 맞는다 — 아이디가 새로 나면 없는 파일을 지우는 무해한 동작이고,
# 재사용되면 넛지가 제대로 다시 걸린다. 이 훅이 지우는 것은 그 세션 자신의 표시뿐이다. 다른 세션이
# 남긴 표시 파일은 손대지 않고 운영체제의 임시 폴더 정리에 맡긴다.
CSTA="$HERE/hooks/rules_nudge_sessionstart.sh"
csta() { printf '%s' "$1" | TMPDIR="$T/tmp" bash "$CSTA"; }
JSS() { printf '{"session_id":"%s","hook_event_name":"SessionStart","source":"resume"}' "$1"; }
check "세션 시작 훅 파일이 있다"                    "[ -f '$CSTA' ]"
check "세션 시작은 아무것도 안 낸다"                "[ -z \"\$(csta '$(JSS s9)')\" ]"
check "세션 시작이 표시를 지워 다시 알린다"         "csta '$(JSS s1)' && cnud '$(JS s1 "" "$T/src/main.py")' | grep -qF 'agent-principles.md'"
check "세션 시작이 서브에이전트 표시도 지워 다시 알린다" "cnud '$(JS s1 ',"agent_id":"a1"' "$T/src/main.py")' | grep -qF 'agent-principles.md'"

echo "[doc-format-pre]"
printf 'x\n' > "$T/existing.md"
check "새 문서(.md) → 양식 제안"         "fpre '$(J "$T/newdoc.md")' | grep -q additionalContext"
check "기존 문서(.md) → 무출력"          "[ -z \"\$(fpre '$(J "$T/existing.md")')\" ]"
check "spec 경로 새 .md → 무출력"        "[ -z \"\$(fpre '$(J "$SP/brandnew.md")')\" ]"
check "비문서(.py) → 무출력"             "[ -z \"\$(fpre '$(J "$T/src/new.py")')\" ]"
check "OFF → 무출력"                     "[ -z \"\$(DISCIPLINED_CODER_REVIEW_GATE=off fpre '$(J "$T/newdoc.md")')\" ]"
check "프로젝트 밖 새 문서 → 무출력"     "[ -z \"\$(fpre '$(J "$OUTSIDE/new.md")')\" ]"
check "새 리뷰 기록 → 무출력"            "[ -z \"\$(fpre '$(J "$T/docs/superpowers/reviews/new-check.md")')\" ]"
# 오답노트는 양식을 그 로그 자신의 머리말이 정해 두어 에이전트원칙의 양식 제안이 틀린 조언이 된다.
# 검진 넛지가 같은 이유로 같은 경로를 빼고 있으니 양식 제안도 함께 뺀다 — 한쪽만 빼면 같은 파일을
# 만들 때 한 훅은 조용하고 다른 훅은 떠들어 어느 쪽이 맞는지 알 수 없다.
check "새 오답노트 색인 → 무출력"        "[ -z \"\$(fpre '$(J "$T/docs/solved_problems.md")')\" ]"
check "새 오답노트 본문 → 무출력"        "[ -z \"\$(fpre '$(J "$T/docs/solved_problems/new-lesson.md")')\" ]"
check "새 문서 넛지가 domain-readme 를 가리킨다" "fpre '$(J "$T/newdoc.md")' | grep -qF 'domain-readme'"
# 넛지가 가리킨 곳이 실재하는지 본다. 문자열 일치만 보던 시절 에이전트원칙 영문화로 가리키던 절 이름이
# 바뀌자 넛지가 없는 곳을 가리킨 채 스위트가 초록으로 통과했다. 타입과 수명이 스킬에서
# 에이전트원칙으로 돌아가 가리키는 대상이 스킬에서 절로 바뀌었고, 이 검사도 따라 바뀐다.
# 부정 대괄호(`[^」]`)를 안 쓴다. 로케일이 UTF-8 이 아니면 sed 가 그것을 바이트로 읽어, 한글의
# 이어지는 바이트가 」 의 바이트와 겹쳐 매치가 엉뚱한 데서 끊긴다. 메시지에 「…」 절 이 하나뿐이라
# 탐욕적 `.*` 가 안전하다. 같은 함정을 test_docs_drift.sh 의 대구 검사도 주석으로 적어 두었다.
NUDGE_SEC="$(fpre "$(J "$T/newdoc.md")" | sed -n 's/.*에이전트원칙의 「\(.*\)」 절.*/\1/p')"
check "넛지가 가리킨 절 이름 추출됨"       "[ -n \"\$NUDGE_SEC\" ]"
check "그 절이 에이전트원칙에 실재"                "grep -qF \"## \$NUDGE_SEC\" '$HERE/agent-principles.md'"
NUDGE_SK="$(fpre "$(J "$T/newdoc.md")" | sed -n "s/.*disciplined-coder \([a-z][a-z-]*\) 를 함께.*/\1/p")"
check "넛지가 가리킨 스킬 이름 추출됨"     "[ -n \"\$NUDGE_SK\" ]"
check "그 스킬이 실재"                    "[ -f \"$HERE/skills/\$NUDGE_SK/SKILL.md\" ]"

echo "[doc-review-post]"
# 거는 대상이 산출물과 그 재료로 좁혀졌다. 확장자 넷은 그 자체로 걸리고, 마크다운은 같은 폴더에
# 그런 파일이 있을 때만 걸린다. 저장소 작업 문서에 뜨던 넛지가 사라진 것이 이 변경의 핵심이라,
# 안 뜨는 쪽을 먼저 단언한다 — 뜨는 쪽만 보면 조건이 넓어져도 초록이 된다.
DLV="$T/deliv-out"; mkdir -p "$DLV"; : > "$DLV/deck.pptx"; printf 'x\n' > "$DLV/draft.md"
DLVP="$T/deliv-pdf"; mkdir -p "$DLVP"; : > "$DLVP/report.pdf"; printf 'x\n' > "$DLVP/draft.md"
check "산출물 없는 폴더의 .md → 무출력"  "[ -z \"\$(drev '$(J "$T/existing.md")')\" ]"
check "산출물(.pptx) → 검진 넛지"        "drev '$(J "$DLV/deck.pptx")' | grep -q additionalContext"
check "산출물(.pdf) → 검진 넛지"         "drev '$(J "$DLVP/report.pdf")' | grep -q additionalContext"
check "산출물 옆의 .md → 검진 넛지"      "drev '$(J "$DLV/draft.md")' | grep -q additionalContext"
check ".pdf 옆의 .md → 검진 넛지"        "drev '$(J "$DLVP/draft.md")' | grep -q additionalContext"
check "spec 경로 → 무출력"               "[ -z \"\$(drev '$(J "$SP/nomark.md")')\" ]"
check "plan 경로 → 무출력"               "[ -z \"\$(drev '$(J "$PL/nomark.md")')\" ]"
check "비문서(.py) → 무출력"             "[ -z \"\$(drev '$(J "$T/src/main.py")')\" ]"
check "OFF → 무출력"                     "[ -z \"\$(DISCIPLINED_CODER_REVIEW_GATE=off drev '$(J "$DLV/deck.pptx")')\" ]"
check "프로젝트 밖 문서 → 무출력"        "[ -z \"\$(drev '$(J "$OUTSIDE/notes.md")')\" ]"
# 산출물은 저장소 밖 임시 폴더에 놓이는 것이 보통이라 프로젝트 밖이어도 걸려야 한다.
OUTDLV="$OUTSIDE/deliv"; mkdir -p "$OUTDLV"; : > "$OUTDLV/sheet.xlsx"; printf 'x\n' > "$OUTDLV/draft.md"
check "프로젝트 밖 산출물 → 검진 넛지"   "drev '$(J "$OUTDLV/sheet.xlsx")' | grep -q additionalContext"
check "프로젝트 밖 산출물 옆 .md → 넛지" "drev '$(J "$OUTDLV/draft.md")' | grep -q additionalContext"
check "Windows 형식 경로도 같게 본다"    "drev '$(J "$(cygpath -w "$DLV" 2>/dev/null || printf '%s' "$DLV")\\\\draft.md")' | grep -q additionalContext"
check "수정 넛지가 review-docs 를 가리킨다  "   "drev '$(J "$DLV/draft.md")' | grep -qF 'review-docs'"
check "수정 넛지에 스킬 절 이름을 박지 않는다"   "! drev '$(J "$DLV/draft.md")' | grep -qF 'Surgical Changes'"
check "README 가 규칙 넛지를 적는다"             "grep -qF '규칙 넛지' '$HERE/README.md'"

echo "[bash 매처 — 셸로 고쳐도 걸린다]"
# 셸로 고치면 훅이 안 돌던 것이 이 묶음이 막는 것이다. 2026-09-21 에 한 세션이 sed -i 로 문서
# 열한 개를 고치는 동안 검진 넛지도 금지 표현 검사도 한 번도 안 걸렸다.
EBT="$HERE/hooks/_extract_bash_targets.sh"
DWPOST="$HERE/hooks/doc_word_posttooluse.sh"
JB() { printf '{"tool_name":"Bash","tool_input":{"command":"%s"}}' "$1"; }
ebt() { JB "$1" | bash "$EBT" | tr '\n' ' '; }
# 쓰기 구문의 대상만 뽑는다. 읽기 인자를 뽑으면 cat 한 번에 알림이 떠 훅을 끄게 만든다.
check "sed -i 대상이 뽑힌다"        "[ \"\$(ebt 'sed -i s/a/b/ one.md')\" = 'one.md ' ]"
check "sed -i 대상 여럿이 뽑힌다"   "[ \"\$(ebt 'sed -i s/a/b/ one.md two.md')\" = 'one.md two.md ' ]"
check "재지향 대상이 뽑힌다"        "[ \"\$(ebt 'printf x > out.md')\" = 'out.md ' ]"
check "붙여 쓴 재지향도 뽑힌다"     "[ \"\$(ebt 'cat >dst.md')\" = 'dst.md ' ]"
check "tee 대상이 뽑힌다"           "[ \"\$(ebt 'tee -a log.md')\" = 'log.md ' ]"
check "cp 의 목적지만 뽑힌다"       "[ \"\$(ebt 'cp src.md dest.md')\" = 'dest.md ' ]"
check "git mv 의 목적지만 뽑힌다"   "[ \"\$(ebt 'git mv old.md new.md')\" = 'new.md ' ]"
check "읽기만 하는 sed 는 안 뽑힌다" "[ -z \"\$(ebt 'sed -n 1,5p onlyread.md')\" ]"
check "cat 은 안 뽑힌다"            "[ -z \"\$(ebt 'cat notes.md')\" ]"
check "ls 는 안 뽑힌다"             "[ -z \"\$(ebt 'ls -la')\" ]"
check "git status 는 안 뽑힌다"     "[ -z \"\$(ebt 'git status --porcelain')\" ]"
# 넛지와 금지 표현 검사가 실제로 셸 편집에 걸리는지 본다. 뽑기만 되고 훅이 안 부르면 소용없다.
BW="$T/bash-deliv"; mkdir -p "$BW"; : > "$BW/deck.pptx"
printf '이 문서는 자리를 짚는다.\n' > "$BW/draft.md"
check "셸 편집 → 검진 넛지"         "JB 'sed -i s/x/y/ $BW/draft.md' | bash '$DREV' | grep -q additionalContext"
check "셸 읽기 → 검진 넛지 없음"    "[ -z \"\$(JB 'cat $BW/draft.md' | bash '$DREV')\" ]"
# 통지는 Claude 가 받아야 고친다. systemMessage 는 사용자 화면에만 가므로 additionalContext 로 낸다.
check "셸 편집 → 금지 표현 통지"    "JB 'sed -i s/x/y/ $BW/draft.md' | bash '$DWPOST' | grep -qF '\"additionalContext\"'"
check "통지는 PostToolUse 이벤트다" "JB 'sed -i s/x/y/ $BW/draft.md' | bash '$DWPOST' | grep -qF '\"hookEventName\":\"PostToolUse\"'"
check "통지가 JSON 으로 파싱된다"   "JB 'sed -i s/x/y/ $BW/draft.md' | bash '$DWPOST' | json_valid_stdin"
check "통지를 사용자 화면용으로 내지 않는다" "! JB 'sed -i s/x/y/ $BW/draft.md' | bash '$DWPOST' | grep -qF 'systemMessage'"
check "통지가 파일 이름을 담는다"   "JB 'sed -i s/x/y/ $BW/draft.md' | bash '$DWPOST' | grep -qF 'draft.md'"
check "이 저장소 문서는 대상 아님"  "[ -z \"\$(JB 'sed -i s/x/y/ $HERE/README.md' | bash '$DWPOST')\" ]"
check "OFF → 무출력"                "[ -z \"\$(JB 'sed -i s/x/y/ $BW/draft.md' | DISCIPLINED_CODER_REPLY_CHECK=off bash '$DWPOST')\" ]"
# 금지 표현이 없는 산출물에는 통지가 없어야 한다. 늘 뜨면 통지가 뜻을 잃는다.
printf '이 문서는 대상을 지적한다.\n' > "$BW/clean.md"
check "깨끗한 산출물에는 통지 없음" "[ -z \"\$(JB 'sed -i s/x/y/ $BW/clean.md' | bash '$DWPOST')\" ]"
check "훅 배선에 Bash 가 들어 있다" "grep -qF 'Write|Edit|Bash' '$HERE/hooks/hooks.json'"

echo "[bash 거르기 — 명령만 보고 낱말 경계로 가른다]"
# 셸 훅 둘은 모든 Bash 호출에 걸린다. 거르기가 훅 입력 전체를 보면 tool_response 의 "passed" 속 sed 와
# 2>/dev/null 의 > 가 걸려 거의 모든 호출이 대상 뽑기까지 간다. 뽑기가 도는지는 awk 를 기록하는
# 가짜로 본다 — 거르기에서 빠지면 awk 도 파이썬도 안 뜬다.
GSH="$T/gate-shim"; mkdir -p "$GSH"; GLOG="$T/gate.log"
REALAWK_H="$(command -v awk)"
printf '#!/usr/bin/env bash\necho awk >> "%s"\nexec "%s" "$@"\n' "$GLOG" "$REALAWK_H" > "$GSH/awk"
for gp in python python3; do printf '#!/usr/bin/env bash\necho %s >> "%s"\nexit 1\n' "$gp" "$GLOG" > "$GSH/$gp"; done
chmod +x "$GSH"/*
gate_runs() {  # $1=훅, $2=훅 입력 → 뽑기나 파이썬이 떴으면 0
  : > "$GLOG"
  printf '%s' "$2" | PATH="$GSH:$PATH" bash "$1" >/dev/null 2>&1 || true
  [ -s "$GLOG" ]
}
GI_LS='{"tool_name":"Bash","tool_input":{"command":"ls","description":"List files"},"tool_response":{"stdout":"12 tests passed","stderr":""}}'
GI_NULL='{"tool_name":"Bash","tool_input":{"command":"git log 2>/dev/null","description":"Show log"},"tool_response":{"stdout":"abc","stderr":""}}'
GI_SED="{\"tool_name\":\"Bash\",\"tool_input\":{\"command\":\"sed -i 's/a/b/' $BW/draft.md\"},\"tool_response\":{\"stdout\":\"\",\"stderr\":\"\"}}"
GI_ECHO="{\"tool_name\":\"Bash\",\"tool_input\":{\"command\":\"echo hi > $BW/draft.md\"},\"tool_response\":{\"stdout\":\"\",\"stderr\":\"\"}}"
GI_QUOTE="{\"tool_name\":\"Bash\",\"tool_input\":{\"command\":\"echo \\\"hi\\\" > $BW/draft.md\"},\"tool_response\":{\"stdout\":\"\",\"stderr\":\"\"}}"
for gh in "$DREV" "$DWPOST"; do
  ghn="$(basename "$gh" .sh)"
  check "$ghn: 출력에 passed 가 든 ls 는 거르기에서 빠진다" "! gate_runs '$gh' '$GI_LS'"
  check "$ghn: 2>/dev/null 은 쓰기가 아니다"                "! gate_runs '$gh' '$GI_NULL'"
  check "$ghn: sed -i 는 지나간다"                          "gate_runs '$gh' \"\$GI_SED\""
  check "$ghn: > 재지향은 지나간다"                         "gate_runs '$gh' '$GI_ECHO'"
  check "$ghn: 따옴표 뒤의 재지향도 지나간다"               "gate_runs '$gh' \"\$GI_QUOTE\""
done

echo "[제외 칸 — 어간을 넓히고 다른 뜻으로 쓰는 말을 뺀다]"
# 원본이 schema 2 에서 다섯째 칸 `제외` 를 더했다. 그 칸을 안 읽으면 어간만 가지고 검색해
# `판정`·`판단` 까지 잡히고, 산출물을 거의 못 쓰게 된다. 표를 읽는 곳이 하나여야 훅과 검사가
# 같은 것을 본다. 픽스처로 보아 저장소 목록의 내용에 기대지 않는다.
. "$HERE/hooks/_banned_words.sh"
BX="$T/banx"; mkdir -p "$BX"
cat > "$BX/list.md" <<'BANEOF'
### 금지 표현

| 쓰지 않는 말 | 대신 쓰는 말 | 적용 대상 | 분류 | 제외 |
|---|---|---|---|---|
| `판` | 버전 | 문서와 답변 | 평소에 쓰지 않는 말 | `판정` · `판단` |
| `짚` | 지적 | 답변과 산출물 | 한자어를 고유어로 되돌린 것 |  |
BANEOF
banned_parse "$BX/list.md" "$BX/pairs" "$BX/toks" "$BX/excl" "$BX/scopes"
check "제외 칸을 읽는다"            "grep -qF '판정' '$BX/excl'"
check "제외 없는 행은 빈 줄이다"    "[ \"\$(sed -n 2p '$BX/excl')\" = '' ]"
check "적용 대상을 읽는다"          "[ \"\$(sed -n 1p '$BX/scopes')\" = '문서와 답변' ]"
printf '판정과 판단만 있다.\n' > "$BX/clean.md"
printf '새 판을 낸다.\n' > "$BX/dirty.md"
check "제외 안의 것은 안 잡는다"    "[ -z \"\$(banned_report '$BX/pairs' '$BX/clean.md' '$BX/excl')\" ]"
check "제외 밖의 것은 잡는다"       "banned_report '$BX/pairs' '$BX/dirty.md' '$BX/excl' | grep -qF '판 -> 버전'"
# 제외 파일을 안 주면 옛 동작 그대로여야 한다. 옛 목록(schema 1)을 쓰는 PC 가 남아 있다.
check "제외를 안 주면 전과 같다"    "banned_report '$BX/pairs' '$BX/clean.md' | grep -qF '판 -> 버전'"
printf 'clean.md\ndirty.md\n' > "$BX/files"
BXSCAN="$(cd "$BX" && banned_scan "$BX/pairs" "$BX/excl" "$BX/scopes" '문서와 답변' "$BX/files")"
check "한 번에 훑어 걸린 파일을 낸다" "printf '%s' \"\$BXSCAN\" | grep -qF 'dirty.md'"
check "제외에 걸린 파일은 안 든다"   "! printf '%s' \"\$BXSCAN\" | grep -qF 'clean.md'"
check "적용 대상으로 행을 고른다"    "[ \"\$(printf '%s\\n' \"\$BXSCAN\" | grep -c .)\" = 1 ]"
# 긴 제외어가 짧은 것에 먹히면 안 된다. `판단` 을 먼저 덮으면 `판단력` 이 더는 안 맞는다.
cat > "$BX/list2.md" <<'BANEOF'
### 금지 표현

| 쓰지 않는 말 | 대신 쓰는 말 | 적용 대상 | 분류 | 제외 |
|---|---|---|---|---|
| `판` | 버전 | 문서와 답변 | 평소에 쓰지 않는 말 | `판단` · `판단력` |
BANEOF
banned_parse "$BX/list2.md" "$BX/pairs2" "$BX/toks2" "$BX/excl2" "$BX/scopes2"
printf '판단력이 있다.\n' > "$BX/long.md"
check "긴 제외어가 먼저 덮인다"      "[ -z \"\$(banned_report '$BX/pairs2' '$BX/long.md' '$BX/excl2')\" ]"

echo "[stop 겹 — 도구를 묻지 않고 결과를 본다]"
# 명령줄에 대상이 안 나타나는 변경(파이썬 스크립트, git checkout)을 앞 두 겹이 못 본다.
# 이 겹은 git 이 바뀌었다고 말하는 파일을 보므로 무엇이 바꿨는지 묻지 않는다.
DWSTOP="$HERE/hooks/doc_word_stop.sh"
SR="$T/stoprepo"; mkdir -p "$SR"; git -C "$SR" init -q 2>/dev/null || true
JSTOP() { printf '{"cwd":"%s","stop_hook_active":%s}' "$1" "${2:-false}"; }
printf '이 문서는 자리를 짚는다.\n' > "$SR/report.md"
check "바뀐 문서의 금지 표현을 알린다" "JSTOP '$SR' | bash '$DWSTOP' | grep -q systemMessage"
check "알림이 파일 이름을 담는다"      "JSTOP '$SR' | bash '$DWSTOP' | grep -qF 'report.md'"
check "턴을 막지는 않는다"             "! JSTOP '$SR' | bash '$DWSTOP' | grep -qF 'permissionDecision'"
SRCLEAN="$T/stopclean"; mkdir -p "$SRCLEAN"; git -C "$SRCLEAN" init -q 2>/dev/null || true
printf '이 문서는 대상을 지적한다.\n' > "$SRCLEAN/report.md"
check "깨끗한 문서에는 알림이 없다"    "[ -z \"\$(JSTOP '$SRCLEAN' | bash '$DWSTOP')\" ]"
check "git 아닌 폴더 → 무출력"         "[ -z \"\$(JSTOP '$OUTSIDE' | bash '$DWSTOP')\" ]"
check "이 저장소 자신 → 무출력"        "[ -z \"\$(JSTOP '$HERE' | bash '$DWSTOP')\" ]"
check "루프가드가 걸린다"              "[ -z \"\$(JSTOP '$SR' true | bash '$DWSTOP')\" ]"
check "OFF → 무출력"                   "[ -z \"\$(JSTOP '$SR' | DISCIPLINED_CODER_REPLY_CHECK=off bash '$DWSTOP')\" ]"
# 코드 파일과 spec 은 대상이 아니다. 대상이 넓어지면 알림이 늘 떠 뜻을 잃는다.
printf 'x = "자리"\n' > "$SR/code.py"; mkdir -p "$SR/docs/superpowers/specs"
printf '이 문서는 자리를 짚는다.\n' > "$SR/docs/superpowers/specs/s.md"
check "코드와 spec 은 안 본다"         "[ \"\$(JSTOP '$SR' | bash '$DWSTOP' | grep -cF 'report.md')\" = 1 ]"
# 새 폴더 안의 새 파일은 git status 가 폴더 한 줄로만 돌려준다. 파일 단위로 펼치지 않으면 새 폴더에
# 만든 보고서가 전부 빠진다.
SRD="$T/stopdir"; mkdir -p "$SRD/reports"; git -C "$SRD" init -q 2>/dev/null || true
printf '이 문서는 자리를 짚는다.\n' > "$SRD/reports/new.md"
check "새 폴더 안의 새 문서도 본다"    "JSTOP '$SRD' | bash '$DWSTOP' | grep -qF 'reports/new.md'"
# Stop 은 막지 않으므로 Claude 에게 닿는 통로가 없다. 알림은 사용자에게 하는 말이어야 하고, 대상은
# 이 턴에 바뀐 문서가 아니라 커밋되지 않은 문서 전부다.
check "알림이 대상을 커밋 전 문서로 적는다" "JSTOP '$SR' | bash '$DWSTOP' | grep -qF '커밋되지 않은'"
check "알림이 이 턴이라고 적지 않는다"      "! JSTOP '$SR' | bash '$DWSTOP' | grep -qF '이 턴에'"
check "알림이 Claude 에게 명령하지 않는다"  "! JSTOP '$SR' | bash '$DWSTOP' | grep -qF '고쳐라'"

echo "[리뷰 기록은 검진 대상이 아니다]"
# 리뷰 기록에 검진 넛지가 뜨면 기록에 대한 기록을 또 써야 하는 순환이 생긴다.
J2() { printf '{"tool_name":"Write","tool_input":{"file_path":"%s"}}' "$1"; }
check "리뷰 기록에는 넛지가 없다"  "[ -z \"\$(drev '$(J2 "$T/docs/superpowers/reviews/x-review.md")')\" ]"
# 오답노트도 기록에 대한 기록을 또 쓰게 만드는 부류다 — 교훈 한 줄을 적을 때마다 검진을 묻는
# 순환이 생기고, 그것을 매번 건너뛰다 보면 진짜 문서에서도 이 넛지를 흘려보내게 된다.
check "오답노트 색인에는 넛지가 없다"  "[ -z \"\$(drev '$(J2 "$T/docs/solved_problems.md")')\" ]"
check "오답노트 본문에는 넛지가 없다"  "[ -z \"\$(drev '$(J2 "$T/docs/solved_problems/lesson.md")')\" ]"
check "산출물 폴더의 문서에는 넛지가 뜬다"  "drev '$(J2 "$DLV/draft.md")' | grep -q additionalContext"

echo "[project-solved nudge removed]"
PN="$(mktemp -d)"
# 넛지가 걸리는 폴더라야 "옛 넛지 대신 일반 넛지가 뜬다"를 볼 수 있다. 산출물을 하나 둔다.
: > "$PN/deck.docx"
# PostToolUse 는 쓰기 뒤에 도므로 실제로는 파일이 있다. 훅이 존재를 확인하므로 픽스처도 만든다.
: > "$PN/CLAUDE.md"
in_claudemd() { printf '{"tool_name":"Write","tool_input":{"file_path":"%s/CLAUDE.md"}}' "$1"; }
OUT_GONE="$(in_claudemd "$PN" | CLAUDE_PROJECT_DIR="$PN" bash "$DREV" 2>&1)" || true
check "no add-pointer nudge anymore"  "! printf '%s' \"\$OUT_GONE\" | grep -qF 'add-pointer'"
# 렌즈 이름이 아니라 위임 대상을 단언한다 — 이름을 단언하면 이 테스트가 네 번째 사본이 된다.
check "generic nudge fires instead"   "printf '%s' \"\$OUT_GONE\" | grep -qF 'review-docs'"
check "nudge names no lens directly"  "! printf '%s' \"\$OUT_GONE\" | grep -qF 'lens-'"
check "hook writes no project file"   "[ ! -f '$PN/docs/solved_problems.md' ]"

echo "[차단 사유의 셸·JSON 안전]"
# 공백 든 경로가 사유에 정확히 한 번 온전하게 들어가야 한다. 공백으로 이어 붙이던 판본은 중복 제거가
# 성립하지 않아 같은 파일을 두 번 나열했고, 글롭 문자가 있으면 파일명 확장까지 일어났다.
WS="$(mktemp -d)"; mkdir -p "$WS/docs/superpowers/specs"
# 커밋이 하나뿐이면 루트 커밋이라 diff-tree 경로(Fix C)가 돌지 않는다 — 두 커밋을 만들어 둘 다 밟게 한다.
# 인덱스에서만 빼면 그 파일은 미추적(??)이면서 동시에 HEAD가 추가(A)한 파일이라 두 탐지 경로에 모두 걸린다.
( cd "$WS" && git init -q . && git config user.email t@t && git config user.name t \
  && printf 'seed\n' > seed.txt && git add -A && git commit -qm seed \
  && printf 'x\n' > "docs/superpowers/specs/my spec.md" \
  && printf 'y\n' > "docs/superpowers/specs/plain.md" \
  && git add -A && git commit -qm specs && git rm -q --cached "docs/superpowers/specs/my spec.md" >/dev/null )
WSOUT="$(printf '{"cwd":"%s"}' "$WS" | bash "$STOP" || true)"
check "차단이 실제로 났다"                  "printf '%s' \"\$WSOUT\" | grep -qF '\"decision\":\"block\"'"
check "공백 든 경로가 정확히 한 번"          "[ \"\$(printf '%s' \"\$WSOUT\" | grep -o 'my spec.md' | wc -l)\" = 1 ]"
check "차단 응답이 유효한 JSON"              "printf '%s' \"\$WSOUT\" | json_valid_stdin"

echo "[hooks 배선 — 이 파일이 깨지면 게이트가 통째로 죽는다]"
# 배선 파일 자체를 아무 테스트도 안 보던 구멍을 막는다. 이름을 손으로 적지 않고 디렉터리와 파일에서 도출한다.
# 배선 파일에 쉼표 하나가 어긋나도 파일 이름만 보는 검사는 초록이라 유효성부터 잰다.
HJ="$HERE/hooks/hooks.json"
for hj in "$HERE"/hooks/hooks*.json; do
  hn="$(basename "$hj")"
  check "$hn 이 유효한 JSON"              "json_valid_stdin < '$hj'"
  check "$hn 이 이벤트를 하나 이상 배선한다" "[ -n \"\$(json_hook_events '$hj')\" ]"
done

# 배선이 가리키는 경로가 실제로 존재하는가. ${CLAUDE_PLUGIN_ROOT}는 레포 루트로 치환해 확인한다.
# 배선 파일은 디렉터리에서 도출해 훑는다 — 이름을 손으로 적으면 새 배선 파일이 검사 밖에 남는다.
missing=""
for hj in "$HERE"/hooks/hooks*.json; do
  for rel in $(sed -n 's|.*\${CLAUDE_PLUGIN_ROOT}/\([^"]*\)\\".*|\1|p' "$hj"); do
    [ -f "$HERE/$rel" ] || missing="$missing $(basename "$hj"):$rel"
  done
done
check "배선이 가리키는 스크립트가 모두 존재" "[ -z \"\$missing\" ]"
[ -n "$missing" ] && echo "    없는 파일:$missing"

# 훅 스크립트를 만들어 놓고 배선을 잊는 것을 막는다. 밑줄로 시작하는 것은 공유 헬퍼라 제외한다.
# 확장자로 훑지 않는다 — 확장자 없는 훅 파일이 글롭에서 빠지면 배선 누락을 못 잡는다.
unwired=""
for f in "$HERE"/hooks/*; do
  [ -f "$f" ] || continue
  b="$(basename "$f")"
  case "$b" in _*|*.json) continue ;; esac
  found=0
  for hj in "$HERE"/hooks/hooks*.json; do
    grep -qF "$b" "$hj" && { found=1; break; }
  done
  [ "$found" = 1 ] || unwired="$unwired $b"
done
check "모든 훅 스크립트가 어딘가에 배선되어 있다" "[ -z \"\$unwired\" ]"
[ -n "$unwired" ] && echo "    어느 배선 파일에도 없는 훅:$unwired"

# --- JSON 이스케이프: 제어 문자가 날것으로 안 나간다 ---
# 개행·복귀·탭만 다루면 그 밖의 0x20 미만 문자가 문자열 값에 날것으로 들어가고, 응답이 파싱되지
# 않아 차단 결정이 통째로 무시된다. 소비자는 이 헬퍼를 source하는 훅 전부다.
echo "[JSON 이스케이프 — 제어 문자]"
. "$HERE/hooks/_json_escape.sh"
ESC_SOH="$(escape_for_json "$(printf 'a\001b')")"
ESC_VT="$(escape_for_json "$(printf 'a\013b')")"
ESC_MIX="$(escape_for_json "$(printf 'a"b\\c\nd\te\001f\033g')")"
check "0x01을 유니코드 이스케이프로 바꾼다" "[ \"\$ESC_SOH\" = 'a\\u0001b' ]"
check "0x0B을 유니코드 이스케이프로 바꾼다" "[ \"\$ESC_VT\" = 'a\\u000bb' ]"
check "섞인 입력의 결과가 JSON으로 파싱된다" \
  "printf '{\"r\":\"%s\"}' \"\$ESC_MIX\" | json_valid_stdin"
check "제어 문자가 결과에 안 남는다" \
  "! printf '%s' \"\$ESC_MIX\" | LC_ALL=C grep -q '[[:cntrl:]]'"


echo "[python3-guard] 윈도우에서 안내판으로 풀리는 python3 만 막는다"
# 상태를 주입해 OS 와 PATH 를 안 본다 — 그것이 없으면 CI(ubuntu)와 윈도우 PC 에서 결과가 갈린다.
P3G="$HERE/hooks/python3_guard_pretooluse.sh"
XCMD="$HERE/hooks/_extract_command.sh"
REDIR="/c/Program Files/WindowsApps/Microsoft.DesktopAppInstaller_1.29.290.0_x64__8wekyb3d8bbwe/AppInstallerPythonRedirector.exe"
JC() { printf '{"tool_name":"Bash","tool_input":{"command":"%s"}}' "$1"; }
p3() { JC "$1" | DISCIPLINED_CODER_PYTHON3_STATE="${2:-$REDIR}" bash "$P3G"; }
# 막아야 하는 것 — 명령어로 놓인 python3
D1="$(p3 'python3 --version')"
D2="$(p3 'python3 <<EOF')"
D3="$(p3 'cd /tmp && python3 x.py')"
D4="$(p3 'PYTHONUTF8=1 python3 x.py')"
D5="$(p3 'echo hi | python3 -')"
# 통과해야 하는 것 — 다른 이름이거나 명령어 자리가 아니다
A1="$(p3 'python --version')"
A2="$(p3 'py -3 x.py')"
A3="$(p3 'python312 --version')"
A4="$(p3 'python3.12 x.py')"
A5="$(p3 'grep python3 README.md')"
A6="$(p3 'echo \"use python3 here\"')"
# 통과해야 하는 것 — 윈도우가 아니거나 실물이 안내판이 아니다
N1="$(p3 'python3 --version' not-windows)"
N2="$(p3 'python3 --version' none)"
N3="$(p3 'python3 --version' /usr/bin/python3)"
N4="$(p3 'python3 --version' /c/Users/x/AppData/Local/Programs/Python/Python312/python3)"
# 스토어로 깐 진짜 파이썬도 WindowsApps 아래에 놓인다 — 경로가 아니라 링크가 가리키는 실물로 가른다.
N5="$(p3 'python3 --version' '/c/Program Files/WindowsApps/PythonSoftwareFoundation.Python.3.12_x64/python3.exe')"
deny() { printf '%s' "$1" | grep -q '"permissionDecision":"deny"'; }
check "맨 앞의 python3 을 막는다"          "deny \"\$D1\""
check "heredoc 을 여는 python3 을 막는다"  "deny \"\$D2\""
check "&& 뒤의 python3 을 막는다"          "deny \"\$D3\""
check "VAR= 뒤의 python3 을 막는다"        "deny \"\$D4\""
check "파이프 뒤의 python3 을 막는다"      "deny \"\$D5\""
check "python 은 통과한다"                 "[ -z \"\$A1\" ]"
check "py -3 은 통과한다"                  "[ -z \"\$A2\" ]"
check "python312 는 통과한다"              "[ -z \"\$A3\" ]"
check "python3.12 는 통과한다"             "[ -z \"\$A4\" ]"
check "명령어 자리가 아니면 통과한다"      "[ -z \"\$A5\" ]"
check "따옴표 안 문자열은 통과한다"        "[ -z \"\$A6\" ]"
check "윈도우가 아니면 통과한다"           "[ -z \"\$N1\" ]"
check "안 풀리면 통과한다"                 "[ -z \"\$N2\" ]"
check "리눅스 경로면 통과한다"             "[ -z \"\$N3\" ]"
check "실제 파이썬이면 통과한다"           "[ -z \"\$N4\" ]"
check "스토어 파이썬이면 통과한다"         "[ -z \"\$N5\" ]"
check "거부 응답이 JSON 으로 파싱된다"     "printf '%s' \"\$D1\" | json_valid_stdin"
check "거부 사유가 부를 이름을 말한다"     "printf '%s' \"\$D1\" | grep -q 'py -3'"
check "거부 사유가 가리키는 실물을 적는다" "printf '%s' \"\$D1\" | grep -qF 'AppInstallerPythonRedirector'"
# 명령 뽑기 — 큰따옴표가 든 명령이 첫 \" 에서 잘리면 그 뒤의 명령어를 훅이 못 본다.
EX1="$(printf '{"tool_input":{"command":"echo \\"a\\" && python3 x.py"}}' | bash "$XCMD")"
check "따옴표가 든 명령을 끝까지 뽑는다"   "[ \"\$EX1\" = 'echo \"a\" && python3 x.py' ]"
check "command 가 없으면 무출력"           "[ -z \"\$(printf '{}' | bash '$XCMD')\" ]"

echo "[산출물 차단 — 산출물 문서의 금지 표현을 거부한다]"
# 대상을 가리는 규칙이 넷이라(확장자·저장소 자신·메모리·설계 문서) 규칙마다 픽스처를 둔다.
# 경로만 다르고 본문은 같은 것을 쓴다 — 갈리는 것이 경로 하나임을 검사가 보이게 한다.
DW="$HERE/hooks/doc_word_pretooluse.sh"
DWBODY='확인이 이루어지는 자리는 절차의 마지막이다. 다음 걸음을 정해 달라.'
DWCLEAN='확인이 이루어지는 단계는 절차의 마지막이다. 다음 단계를 정해 달라.'
DWQUOTE='표의 `자리` 행과 `걸음` 행을 그대로 두었다.'
dwj() { printf '{"tool_input":{"file_path":"%s","content":"%s"}}' "$1" "$2"; }
dwe() { printf '{"tool_input":{"file_path":"%s","old_string":"옛 문장","new_string":"%s"}}' "$1" "$2"; }
dw() { printf '%s' "$1" | bash "$DW"; }
DWDIR="$T/deliv"; mkdir -p "$DWDIR/docs/superpowers/specs" "$DWDIR/sub"
# 저장소 자신으로 보이게 하는 픽스처 — 조상 폴더에 에이전트원칙이 있으면 대상에서 빠진다.
DWREPO="$T/fakerepo"; mkdir -p "$DWREPO/skills"; : > "$DWREPO/agent-principles.md"
DW_HIT="$(dw "$(dwj "$DWDIR/report.md" "$DWBODY")")"
check "산출물의 금지 표현을 거부한다"       "printf '%s' \"\$DW_HIT\" | grep -qF '\"permissionDecision\":\"deny\"'"
check "거부 응답이 JSON 으로 파싱된다"       "printf '%s' \"\$DW_HIT\" | json_valid_stdin"
check "거부 사유가 걸린 말을 적는다"         "printf '%s' \"\$DW_HIT\" | grep -qF '자리'"
check "거부 사유가 대체어를 적는다"          "printf '%s' \"\$DW_HIT\" | grep -qF '단계'"
check "Edit 의 새 본문도 본다"               "printf '%s' \"\$(dw \"\$(dwe '$DWDIR/report.md' '$DWBODY')\")\" | grep -qF 'deny'"
check "금지 표현이 없으면 통과한다"          "[ -z \"\$(dw \"\$(dwj '$DWDIR/report.md' '$DWCLEAN')\")\" ]"
check "백틱 안은 안 잡는다"                  "[ -z \"\$(dw \"\$(dwj '$DWDIR/report.md' '$DWQUOTE')\")\" ]"
check "md 가 아니면 통과한다"                "[ -z \"\$(dw \"\$(dwj '$DWDIR/report.txt' '$DWBODY')\")\" ]"
check "저장소 자신의 문서는 통과한다"        "[ -z \"\$(dw \"\$(dwj '$DWREPO/skills/x.md' '$DWBODY')\")\" ]"
check "메모리는 통과한다"                    "[ -z \"\$(dw \"\$(dwj '$T/.claude/projects/p/memory/m.md' '$DWBODY')\")\" ]"
check "설계 문서는 통과한다"                 "[ -z \"\$(dw \"\$(dwj '$DWDIR/docs/superpowers/specs/s.md' '$DWBODY')\")\" ]"
# 레포 뿌리 기준의 상대경로도 같은 제외를 받아야 한다. `*/docs/...` 만 보면 앞에 무언가가 있어야
# 맞아서 이 형태가 지나갔고, 형제 훅 둘은 이미 두 형태를 받고 있었다.
check "설계 문서 상대경로도 통과한다"        "[ -z \"\$(dw \"\$(dwj 'docs/superpowers/specs/s.md' '$DWBODY')\")\" ]"
# 이 저장소를 cwd 로 연 세션에서 저장소 밖에 쓰는 산출물이 제외로 새면 안 된다. 절대경로가 조상을
# 다 올라간 뒤 현재 폴더(.)로 물러서면 이 저장소의 에이전트원칙을 보고 제외해 버린다.
check "저장소 cwd 에서 밖의 윈도우 경로는 거부한다(슬래시)" "( cd '$HERE' && dw \"\$(dwj 'Z:/outside/report.md' '$DWBODY')\" ) | grep -qF 'deny'"
check "저장소 cwd 에서 밖의 윈도우 경로는 거부한다(역슬래시)" "( cd '$HERE' && dw \"\$(dwj 'Z:\\\\outside\\\\report.md' '$DWBODY')\" ) | grep -qF 'deny'"
check "저장소 cwd 에서 밖의 POSIX 경로는 거부한다" "( cd '$HERE' && dw \"\$(dwj '$DWDIR/report.md' '$DWBODY')\" ) | grep -qF 'deny'"
check "상대경로는 현재 폴더 기준으로 제외한다"     "[ -z \"\$( cd '$DWREPO' && dw \"\$(dwj 'x.md' '$DWBODY')\" )\" ]"
# Edit 은 조각만 오므로 울타리가 조각 밖에 있다. 파일에 적용한 결과로 울타리를 알아본 뒤 새로 들어간
# 글자만 판정한다. 파일의 다른 문장에 원래 있던 말까지 잡으면 무관한 편집이 거부된다.
dwe2() { printf '{"tool_name":"Edit","tool_input":{"file_path":"%s","old_string":"%s","new_string":"%s"%s}}' "$1" "$2" "$3" "${4:-}"; }
printf '# 제목\n\n```sh\necho old\n```\n\n본문 문장이다.\n' > "$DWDIR/fenced.md"
check "코드 블록 안을 고치는 Edit 은 통과한다"   "[ -z \"\$(dw \"\$(dwe2 '$DWDIR/fenced.md' 'echo old' 'echo 자리')\")\" ]"
check "산문을 고치는 Edit 은 거부한다"           "dw \"\$(dwe2 '$DWDIR/fenced.md' '본문 문장이다.' '$DWBODY')\" | grep -qF 'deny'"
check "적용한 결과를 본 거부는 산문이라고 적는다" "dw \"\$(dwe2 '$DWDIR/fenced.md' '본문 문장이다.' '$DWBODY')\" | grep -qF '모두 산문에 있다'"
check "적용하지 못한 거부는 조각만 봤다고 적는다" "dw \"\$(dwe2 '$DWDIR/fenced.md' '없는 문장' '$DWBODY')\" | grep -qF 'new_string 조각만'"
printf '# 제목\n\n이 자리는 원래 있던 문장이다.\n\n고칠 문장이다.\n' > "$DWDIR/preexisting.md"
check "원래 있던 말은 무관한 Edit 을 막지 않는다" "[ -z \"\$(dw \"\$(dwe2 '$DWDIR/preexisting.md' '고칠 문장이다.' '고친 문장이다.')\")\" ]"
printf '```sh\necho old\n```\n\necho old 는 산문이다.\n' > "$DWDIR/replall.md"
check "replace_all 은 모든 자리를 판정한다"      "dw \"\$(dwe2 '$DWDIR/replall.md' 'echo old' 'echo 자리' ',\"replace_all\":true')\" | grep -qF 'deny'"
check "replace_all 이 아니면 첫 자리만 판정한다" "[ -z \"\$(dw \"\$(dwe2 '$DWDIR/replall.md' 'echo old' 'echo 자리')\")\" ]"
check "스위치를 끄면 통과한다"               "[ -z \"\$(DISCIPLINED_CODER_REPLY_CHECK=off dw \"\$(dwj '$DWDIR/report.md' '$DWBODY')\")\" ]"
check "경로가 없으면 통과한다"               "[ -z \"\$(dw '{}')\" ]"
# 금지 표현 목록(korean-banned-words.md)이 없으면 조용히 통과하지 않고 알린다 — 검사 불능은 통과가 아니다.
# 막지는 않는다. 여기서 막으면 목록을 못 찾는 설치에서 문서 편집이 통째로 멈춘다.
FAKE="$T/fake"; mkdir -p "$FAKE/hooks" "$FAKE/scripts"
cp "$DW" "$HERE/hooks/_json_escape.sh" "$HERE/hooks/_banned_words.sh" "$HERE/hooks/_hook_input.sh" "$HERE/hooks/_spec_marker.sh" "$FAKE/hooks/"
cp "$HERE/scripts/_json_valid.sh" "$FAKE/scripts/"
DW_NOCANON="$(printf '%s' "$(dwj "$DWDIR/report.md" "$DWBODY")" | bash "$FAKE/hooks/doc_word_pretooluse.sh")"
check "금지 표현 목록이 없으면 알린다"              "printf '%s' \"\$DW_NOCANON\" | grep -qF 'systemMessage'"
check "금지 표현 목록이 없을 때 막지는 않는다"      "! printf '%s' \"\$DW_NOCANON\" | grep -qF 'permissionDecision'"

echo "[README — 배선된 스크립트를 모두 적는다]"
# 훅이 일곱인데 안내 문서가 넷만 적고 있었다. 목록을 README 에 손으로 적지 않고 배선 파일 둘에서
# 도출해 맞댄다. 훅을 더하거나 빼면 여기서 함께 갈린다.
HOOK_WIRED="$(grep -ohE '[a-z_]+\.sh' "$HERE/hooks/hooks.json" "$HERE/.claude/settings.json" | sort -u)"
check "배선 파일에서 스크립트 이름을 뽑았다" "[ -n \"\$HOOK_WIRED\" ]"
HOOK_MISS=""
while IFS= read -r sname; do
  [ -n "$sname" ] || continue
  if ! grep -qF "$sname" "$HERE/README.md"; then HOOK_MISS="$HOOK_MISS $sname"; fi
done <<EOF
$(grep -ohE '[a-z_]+\.sh' "$HERE/hooks/hooks.json" "$HERE/.claude/settings.json" | sort -u)
EOF
[ -n "$HOOK_MISS" ] && echo "    README 에 빠진 스크립트:$HOOK_MISS"
check "README 가 배선된 스크립트를 모두 적는다" "[ -z \"\$HOOK_MISS\" ]"
check "README 가 배선 파일 둘을 든다"           "grep -qF 'hooks/hooks.json' '$HERE/README.md' && grep -qF '.claude/settings.json' '$HERE/README.md'"

echo "----"; echo "PASS=$pass FAIL=$fail"; [ "$fail" -eq 0 ]
