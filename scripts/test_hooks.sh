#!/usr/bin/env bash
# 훅 스크립트 검증. 계약: FAIL=0 (매직넘버 금지 — 개수는 테스트가 센다).
# `# 핵심 계약:` 표시가 달린 검사는 v2 정리에서 지우지 않는다.
set -euo pipefail
HERE="$(cd "$(dirname "$0")/.." && pwd)"
# 픽스처는 모두 이 뿌리 아래에 만들고 끝나면 통째로 지운다. mktemp 가 TMPDIR 을 따르므로 아래의
# mktemp 호출과 이 검사가 부르는 스크립트의 임시 파일이 모두 여기로 온다.
TEST_TMP="$(mktemp -d)"; trap 'rm -rf "$TEST_TMP"' EXIT; export TMPDIR="$TEST_TMP"
PTU="$HERE/hooks/spec_review_posttooluse.sh"
STOP="$HERE/hooks/stop_gates.sh"
. "$HERE/scripts/_test_check.sh"
ptu() { printf '%s' "$1" | bash "$PTU"; }
stop() { printf '%s' "$1" | bash "$STOP"; }
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
check "빈 입력 → 무출력"                    "[ -z \"\$(extract '{}')\" ]"
check "UNC 경로의 앞머리 두 슬래시를 보존한다" "[ \"\$(extract '$(J '\\\\\\\\srv\\\\share\\\\a.md')')\" = '//srv/share/a.md' ]"

echo "[ptu]"
check "spec 미마커 → 리뷰 지시"          "ptu '$(J "$SP/nomark.md")' | grep -q additionalContext"
check "plan 미마커 → 리뷰 지시"          "ptu '$(J "$PL/nomark.md")' | grep -q additionalContext"
check "무관 경로 → 무출력"               "[ -z \"\$(ptu '$(J "$T/src/main.py")')\" ]"
check "프로젝트 밖 spec → 무출력"        "[ -z \"\$(ptu '$(J "$OUTSIDE/docs/superpowers/specs/x.md")')\" ]"
check "terminal passed → 무출력"         "[ -z \"\$(ptu '$(J "$SP/passed.md")')\" ]"
check "terminal escalated → 무출력"      "[ -z \"\$(ptu '$(J "$SP/esc.md")')\" ]"
check "CRLF terminal → 무출력"           "[ -z \"\$(ptu '$(J "$SP/crlf.md")')\" ]"
check "본문 예시만(마지막 일반) → 지시"  "ptu '$(J "$SP/example.md")' | grep -q additionalContext"
check "pending(마커 아님) → 지시"        "ptu '$(J "$SP/pending.md")' | grep -q additionalContext"
check "산문 안 마커(마지막 줄) → 지시"   "ptu '$(J "$SP/prose.md")' | grep -q additionalContext"
check "안 닫힌 마커 → 지시"              "ptu '$(J "$SP/unclosed.md")' | grep -q additionalContext"

echo "[stop]"
# $G = git 저장소 + 미리뷰 spec. 미리뷰 spec 이면 block 이므로, loop guard 가 깨지면
# 빈 출력이 아니라 block이 나와 변별된다(비-git $T는 FAIL-OPEN으로 항상 빈 출력 → 변별 불가).
G="$(mktemp -d)"; ( cd "$G" && git init -q && git config user.email t@t && git config user.name t )
mkdir -p "$G/docs/superpowers/specs"
printf 'draft\n' > "$G/docs/superpowers/specs/new.md"
check "loop guard(active) → 통과"        "[ -z \"\$(stop '{\"stop_hook_active\":true,\"cwd\":\"$G\"}')\" ]"
check "미리뷰 spec → block"              "stop '{\"cwd\":\"$G\"}' | grep -q '\"block\"'"
# 세션의 작업 폴더가 레포 하위 폴더여도 찾아야 한다. 전에는 두 탐색이 모두 현재 폴더 기준이라
# 하위 폴더에서 열면 미리뷰 spec을 하나도 못 찾고 아무 메시지 없이 통과시켰다 — 게이트가 꺼진
# 것을 알아챌 방법이 없는 조용한 실패다.
mkdir -p "$G/backend"
check "하위 폴더 cwd → block"            "stop '{\"cwd\":\"$G/backend\"}' | grep -q '\"block\"'"
printf 'draft\n<!-- spec-review: passed lenses=3 date=2026-06-14 -->\n' > "$G/docs/superpowers/specs/new.md"
check "passed 마커 후 → 통과"            "[ -z \"\$(stop '{\"cwd\":\"$G\"}')\" ]"
# 파일명 파싱 강건성: git porcelain이 따옴표로 감싸거나(공백·비ASCII) 리네임 화살표로 합치면
# 게이트가 조용히 우회되면 안 된다. new.md 는 위에서 passed(리뷰됨)이므로 차단 안 됨.
# 공백 파일명은 아래 「차단 사유의 셸·JSON 안전」 묶음이 더 엄격하게 본다.
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

# 세션이 시작되기 전에 만든 초안은 이 세션의 작업이 아니다. 표시 파일에 적힌 목록이 그 초안이다.
# 표시가 없으면 지금처럼 전부 본다.
G4="$(mktemp -d)"; ( cd "$G4" && git init -q && git config user.email t@t && git config user.name t )
mkdir -p "$G4/docs/superpowers/specs"; printf 'old draft\n' > "$G4/docs/superpowers/specs/old.md"
touch -d '2000-01-01' "$G4/docs/superpowers/specs/old.md"
mkdir -p "$TMPDIR/disciplined-coder"; printf 'docs/superpowers/specs/old.md\n' > "$TMPDIR/disciplined-coder/session-start-s9"
check "세션 전 초안은 막지 않는다"          "[ -z \"\$(stop '{\"cwd\":\"$G4\",\"session_id\":\"s9\"}')\" ]"
check "세션 표시가 없으면 전부 본다"        "stop '{\"cwd\":\"$G4\",\"session_id\":\"s10\"}' | grep -q '\"block\"'"
check "세션 ID 가 없으면 전부 본다"         "stop '{\"cwd\":\"$G4\"}' | grep -q '\"block\"'"
printf 'new draft\n' > "$G4/docs/superpowers/specs/new.md"
check "세션 중 새 초안은 막는다"            "stop '{\"cwd\":\"$G4\",\"session_id\":\"s9\"}' | grep -q '\"block\"'"

echo "[readonly-pre — 읽기 전용 파일은 고치지 않는다]"
RPRE="$HERE/hooks/readonly_pretooluse.sh"
rpre() { printf '%s' "$1" | bash "$RPRE"; }
RO="$(mktemp -d)"; printf 'sealed\n' > "$RO/sealed.md"; printf 'open\n' > "$RO/open.md"; chmod a-w "$RO/sealed.md"
# 핵심 계약: 읽기 전용 차단 — 결함 주입: 훅이 항상 통과하게 바꾼다
check "읽기 전용 파일(절대경로) → deny"        "rpre '$(J "$RO/sealed.md")' | grep -qF '\"permissionDecision\":\"deny\"'"
check "거부 응답이 유효한 JSON"                "rpre '$(J "$RO/sealed.md")' | json_valid_stdin"
check "쓸 수 있는 파일 → 무출력"               "[ -z \"\$(rpre '$(J "$RO/open.md")')\" ]"
check "없는 파일 → 무출력"                     "[ -z \"\$(rpre '$(J "$RO/nope.md")')\" ]"
check "상대경로(현재 폴더 기준) 읽기 전용 → deny" "( cd '$RO' && printf '%s' '$(J "sealed.md")' | bash '$RPRE' ) | grep -qF '\"permissionDecision\":\"deny\"'"

echo "[spec-gate-sessionstart — 세션 시작 표시만 만들고 아무것도 내지 않는다]"
CSTA="$HERE/hooks/spec_gate_sessionstart.sh"
JSU() { printf '{"session_id":"%s","hook_event_name":"SessionStart","source":"%s"}' "$1" "$2"; }
check "세션 시작은 아무것도 안 낸다"           "[ -z \"\$(printf '%s' '$(JSU st0 startup)' | bash '$CSTA')\" ]"
printf '%s' "$(JSU st1 startup)" | bash "$CSTA" || true
check "startup 이면 세션 시작 표시를 남긴다"   "[ -f \"\$TMPDIR/disciplined-coder/session-start-st1\" ]"
# 수정 시각을 옛날로 돌리면 7일 지난 표시 지우기에 걸리므로 내용으로 본다.
printf 'keep\n' > "$TMPDIR/disciplined-coder/session-start-st1"
printf '%s' "$(JSU st1 startup)" | bash "$CSTA" || true
check "있는 표시는 다시 쓰지 않는다"          "[ \"\$(cat \"\$TMPDIR/disciplined-coder/session-start-st1\")\" = keep ]"
printf '%s' "$(JSU st2 resume)" | bash "$CSTA" || true
printf '%s' "$(JSU st3 clear)" | bash "$CSTA" || true
check "resume·clear 에서도 표시가 없으면 만든다" "[ -e \"\$TMPDIR/disciplined-coder/session-start-st2\" ] && [ -e \"\$TMPDIR/disciplined-coder/session-start-st3\" ]"

echo "[bash 매처 — 셸로 고쳐도 걸린다]"
# 셸로 고치면 Write·Edit 입력에 경로가 없어 금지 표현 통지가 빠지는 것을 이 묶음이 막는다.
EBT="$HERE/hooks/_extract_bash_targets.sh"
DWPOST="$HERE/hooks/doc_word_posttooluse.sh"
JB() { printf '{"tool_name":"Bash","tool_input":{"command":"%s"}}' "$1"; }
ebt() { ( . "$HERE/hooks/_hook_input.sh"; . "$EBT"; bash_write_targets "$1" ) | tr '\n' ' '; }
# 쓰기 구문의 대상만 뽑는다. 읽기 인자를 뽑으면 cat 한 번에 알림이 떠 훅을 끄게 만든다.
check "sed -i 대상 여럿이 뽑힌다"   "[ \"\$(ebt 'sed -i s/a/b/ one.md two.md')\" = 'one.md two.md ' ]"
check "재지향 대상이 뽑힌다"        "[ \"\$(ebt 'printf x > out.md')\" = 'out.md ' ]"
check "붙여 쓴 재지향도 뽑힌다"     "[ \"\$(ebt 'cat >dst.md')\" = 'dst.md ' ]"
check "tee 대상이 뽑힌다"           "[ \"\$(ebt 'tee -a log.md')\" = 'log.md ' ]"
check "cp 의 목적지만 뽑힌다"       "[ \"\$(ebt 'cp src.md dest.md')\" = 'dest.md ' ]"
check "git mv 의 목적지만 뽑힌다"   "[ \"\$(ebt 'git mv old.md new.md')\" = 'new.md ' ]"
check "읽기만 하는 sed 는 안 뽑힌다" "[ -z \"\$(ebt 'sed -n 1,5p onlyread.md')\" ]"
check "cat 은 안 뽑힌다"            "[ -z \"\$(ebt 'cat notes.md')\" ]"
# 금지 표현 통지가 실제로 셸 편집에 걸리는지 본다. 뽑기만 되고 훅이 안 부르면 소용없다.
BW="$T/bash-deliv"; mkdir -p "$BW"
printf '이 문서는 자리를 짚는다.\n' > "$BW/draft.md"
check "셸 읽기 → 금지 표현 통지 없음" "[ -z \"\$(JB 'cat $BW/draft.md' | bash '$DWPOST')\" ]"
# 통지는 Claude 가 받아야 고친다. systemMessage 는 사용자 화면에만 가므로 additionalContext 로 낸다.
DWPOST_OUT="$(JB "sed -i s/x/y/ $BW/draft.md" | bash "$DWPOST")"
check "셸 편집 → 금지 표현 통지를 PostToolUse JSON 의 additionalContext 로 낸다" \
  "printf '%s' \"\$DWPOST_OUT\" | grep -qF '\"additionalContext\"' && printf '%s' \"\$DWPOST_OUT\" | grep -qF '\"hookEventName\":\"PostToolUse\"' && ! printf '%s' \"\$DWPOST_OUT\" | grep -qF 'systemMessage' && printf '%s' \"\$DWPOST_OUT\" | json_valid_stdin"
check "통지가 파일 이름을 담는다"   "printf '%s' \"\$DWPOST_OUT\" | grep -qF 'draft.md'"
check "셸 통지는 원래 있던 문장을 고치지 말라고 한다" "printf '%s' \"\$DWPOST_OUT\" | grep -qF '원래 있던 문장은 고치지 마라'"
check "셸 통지는 사용자에게 알리라고 하지 않는다" "! printf '%s' \"\$DWPOST_OUT\" | grep -qF '사용자에게 알리'"
check "이 저장소 문서는 대상 아님"  "[ -z \"\$(JB 'sed -i s/x/y/ $HERE/README.md' | bash '$DWPOST')\" ]"
# 금지 표현이 없는 산출물에는 통지가 없어야 한다. 늘 뜨면 통지가 뜻을 잃는다.
printf '이 문서는 대상을 지적한다.\n' > "$BW/clean.md"
check "깨끗한 산출물에는 통지 없음" "[ -z \"\$(JB 'sed -i s/x/y/ $BW/clean.md' | bash '$DWPOST')\" ]"
check "훅 배선에 Bash 가 들어 있다" "grep -qF 'Write|Edit|Bash' '$HERE/hooks/hooks.json'"

echo "[bash 거르기 — 명령만 보고 낱말 경계로 가른다]"
# 셸 훅은 모든 Bash 호출에 걸린다. 거르기가 훅 입력 전체를 보면 tool_response 의 "passed" 속 sed 와
# 2>/dev/null 의 > 가 걸려 거의 모든 호출이 대상 뽑기까지 간다. 훅이 쓰는 거르기(_hook_input.sh 의
# hook_command 와 bash_cmd_writes)를 쓰므로 훅 입력 전체를 그 둘에 직접 넣어 본다.
gate_runs() {  # $1=훅 입력 → 거르기를 지나면 0
  ( INPUT="$1"; . "$HERE/hooks/_hook_input.sh"; hook_command; bash_cmd_writes "$CMD" )
}
GI_LS='{"tool_name":"Bash","tool_input":{"command":"ls","description":"List files"},"tool_response":{"stdout":"12 tests passed","stderr":""}}'
GI_NULL='{"tool_name":"Bash","tool_input":{"command":"git log 2>/dev/null","description":"Show log"},"tool_response":{"stdout":"abc","stderr":""}}'
GI_ECHO="{\"tool_name\":\"Bash\",\"tool_input\":{\"command\":\"echo hi > $BW/draft.md\"},\"tool_response\":{\"stdout\":\"\",\"stderr\":\"\"}}"
GI_QUOTE="{\"tool_name\":\"Bash\",\"tool_input\":{\"command\":\"echo \\\"hi\\\" > $BW/draft.md\"},\"tool_response\":{\"stdout\":\"\",\"stderr\":\"\"}}"
check "출력에 passed 가 든 ls 는 거르기에서 빠진다" "! gate_runs '$GI_LS'"
check "2>/dev/null 은 쓰기가 아니다"                "! gate_runs '$GI_NULL'"
check "> 재지향은 지나간다"                         "gate_runs '$GI_ECHO'"
check "따옴표 뒤의 재지향도 지나간다"               "gate_runs \"\$GI_QUOTE\""


echo "[doc-word-post — Write·Edit 로 쓴 산출물 문서의 금지 표현을 Claude 에게 알린다]"
# 대상을 가리는 규칙이 넷이라(확장자·저장소 자신·메모리·설계 문서) 규칙마다 픽스처를 둔다.
# 경로만 다르고 본문은 같은 것을 쓴다. 갈리는 것이 경로 하나임을 검사가 보이게 한다.
DWPOST="$HERE/hooks/doc_word_posttooluse.sh"
dwp() { printf '%s' "$1" | bash "$DWPOST"; }
JW() { printf '{"tool_name":"Write","tool_input":{"file_path":"%s"}}' "$1"; }
# Edit 입력. $4 는 tool_input 에 덧붙일 칸, $5 는 훅 입력 끝에 덧붙일 칸(tool_response)이다.
JEd() { printf '{"tool_name":"Edit","tool_input":{"file_path":"%s","old_string":"%s","new_string":"%s"%s}%s}' "$1" "$2" "$3" "${4:-}" "${5:-}"; }
DWBODY='확인이 이루어지는 자리는 절차의 마지막이다. 다음 걸음을 정해 달라.'
DWCLEAN='확인이 이루어지는 단계는 절차의 마지막이다. 다음 단계를 정해 달라.'
DWQUOTE='표의 `자리` 행과 `걸음` 행을 그대로 두었다.'
DWDIR="$T/deliv"; mkdir -p "$DWDIR/docs/superpowers/specs" "$T/.claude/projects/p/memory"
# 저장소 자신으로 보이게 하는 픽스처. 조상 폴더에 에이전트원칙이 있으면 대상에서 빠진다.
DWREPO="$T/fakerepo"; mkdir -p "$DWREPO/skills"; : > "$DWREPO/agent-principles.md"
for f in "$DWDIR/report.md" "$DWDIR/report.txt" "$DWREPO/skills/x.md" "$DWREPO/x.md" \
         "$T/.claude/projects/p/memory/m.md" "$DWDIR/docs/superpowers/specs/s.md"; do
  printf '%s\n' "$DWBODY" > "$f"
done
printf '%s\n' "$DWCLEAN" > "$DWDIR/clean.md"; printf '%s\n' "$DWQUOTE" > "$DWDIR/quote.md"
DWW_OUT="$(dwp "$(JW "$DWDIR/report.md")")"
check "Write 한 산출물의 금지 표현을 additionalContext 로 알린다" "printf '%s' \"\$DWW_OUT\" | grep -qF '\"additionalContext\"' && printf '%s' \"\$DWW_OUT\" | grep -qF '\"hookEventName\":\"PostToolUse\"'"
check "알림이 JSON 으로 파싱된다"            "printf '%s' \"\$DWW_OUT\" | json_valid_stdin"
check "알림이 검출된 말을 적는다"            "printf '%s' \"\$DWW_OUT\" | grep -qF '자리'"
check "알림이 대체어를 적는다"               "printf '%s' \"\$DWW_OUT\" | grep -qF '단계'"
check "금지 표현이 없으면 무출력"            "[ -z \"\$(dwp '$(JW "$DWDIR/clean.md")')\" ]"
check "백틱 안은 안 잡는다"                  "[ -z \"\$(dwp '$(JW "$DWDIR/quote.md")')\" ]"
check "md 가 아니면 무출력"                  "[ -z \"\$(dwp '$(JW "$DWDIR/report.txt")')\" ]"
check "저장소 자신의 문서는 무출력"          "[ -z \"\$(dwp '$(JW "$DWREPO/skills/x.md")')\" ]"
check "메모리는 무출력"                      "[ -z \"\$(dwp '$(JW "$T/.claude/projects/p/memory/m.md")')\" ]"
check "설계 문서는 무출력"                   "[ -z \"\$(dwp '$(JW "$DWDIR/docs/superpowers/specs/s.md")')\" ]"
check "설계 문서 상대경로도 무출력"          "[ -z \"\$( cd '$DWDIR' && dwp '$(JW "docs/superpowers/specs/s.md")' )\" ]"
# 이 저장소를 cwd 로 연 세션에서 저장소 밖에 쓰는 산출물이 제외로 새면 안 된다.
check "저장소 cwd 에서 밖의 산출물을 알린다" "( cd '$HERE' && dwp '$(JW "$DWDIR/report.md")' ) | grep -qF additionalContext"
check "상대경로는 현재 폴더 기준으로 제외한다" "[ -z \"\$( cd '$DWREPO' && dwp '$(JW "x.md")' )\" ]"
check "경로가 없으면 무출력"                 "[ -z \"\$(dwp '{}')\" ]"
# Edit 은 new_string 이 놓인 글자만 본다. 아래 픽스처는 모두 Edit 이 끝난 뒤의 파일이다.
printf '본문: %s
' "$DWBODY" > "$DWDIR/edited.md"
check "Edit 로 넣은 산문의 금지 표현을 알린다" "dwp '$(JEd "$DWDIR/edited.md" '옛 문장' "$DWBODY")' | grep -qF additionalContext"
printf '# 제목

이 자리는 원래 있던 문장이다.

고친 문장이다.
' > "$DWDIR/preexisting.md"
check "원래 있던 말은 무관한 Edit 에 알리지 않는다" "[ -z \"\$(dwp '$(JEd "$DWDIR/preexisting.md" '고칠 문장이다.' '고친 문장이다.')')\" ]"
printf '# 제목

```sh
echo 자리
```

본문 문장이다.
' > "$DWDIR/fenced.md"
check "코드 블록 안을 고친 Edit 은 알리지 않는다" "[ -z \"\$(dwp '$(JEd "$DWDIR/fenced.md" 'echo old' 'echo 자리' '' ',"tool_response":{"originalFile":"# 제목\n\n```sh\necho old\n```\n\n본문 문장이다.\n"}')')\" ]"
printf '```sh
echo 자리
```

echo 자리 는 산문이다.
' > "$DWDIR/replall.md"
printf '```sh
echo 자리
```

echo old 는 산문이다.
' > "$DWDIR/replone.md"
DWRORIG=',"tool_response":{"originalFile":"```sh\necho old\n```\n\necho old 는 산문이다.\n"}'
check "replace_all 은 바뀐 곳 전부를 본다"      "dwp '$(JEd "$DWDIR/replall.md" 'echo old' 'echo 자리' ',"replace_all":true' "$DWRORIG")' | grep -qF additionalContext"
check "replace_all 이 아니면 처음 한 곳만 본다" "[ -z \"\$(dwp '$(JEd "$DWDIR/replone.md" 'echo old' 'echo 자리' '' "$DWRORIG")')\" ]"
# tool_response 의 원래 파일이 있으면 치환을 다시 적용해 바뀐 곳을 정확히 찾는다. 같은 글자가 앞의 코드 블록에
# 있어도 산문에 넣은 쪽을 본다.
printf '```
자리
```

자리
' > "$DWDIR/orig.md"
check "원래 파일이 있으면 바뀐 곳을 정확히 본다" "dwp '$(JEd "$DWDIR/orig.md" 'X' '자리' '' ',"tool_response":{"originalFile":"```\n자리\n```\n\nX\n"}')' | grep -qF additionalContext"
# 파이썬이 없는 PC 를 흉내 낸다. 실패하는 python·python3 를 PATH 앞에 둔다.
NOPY="$T/nopy"; mkdir -p "$NOPY"
for n in python python3; do printf '#!/bin/sh\nexit 1\n' > "$NOPY/$n"; chmod +x "$NOPY/$n"; done
check "파이썬이 없으면 알림 없이 통과한다"   "out=\"\$(printf '%s' '$(JW "$DWDIR/report.md")' | PATH='$NOPY':\"\$PATH\" bash '$DWPOST')\" && [ -z \"\$out\" ]"
echo "[제외 칸 — 어간을 넓히고 다른 뜻으로 쓰는 말을 뺀다]"
# 목록의 셋째 칸은 `제외` 다. 그 칸을 안 읽으면 어간만 가지고 검색해
# `판정`·`판단` 까지 잡히고, 산출물을 거의 못 쓰게 된다. 표를 읽는 곳이 하나여야 훅과 검사가
# 같은 것을 본다. 픽스처로 보아 저장소 목록의 내용에 기대지 않는다.
. "$HERE/hooks/_banned_words.sh"
BX="$T/banx"; mkdir -p "$BX"
cat > "$BX/list.md" <<'BANEOF'
## 금지 표현

### 모든 글에 적용

#### 평소에 쓰지 않는 말

| 쓰지 않는 말 | 대신 쓰는 말 | 제외 |
|---|---|---|
| `판` | 버전 | `판정` · `판단` |

### 답변과 산출물에만 적용

#### 한자어를 고유어로 되돌린 것

| 쓰지 않는 말 | 대신 쓰는 말 | 제외 |
|---|---|---|
| `짚` | 지적 |  |

## 표로 적을 수 없는 규칙

| `새` | 이 행은 표 밖이다 |  |
BANEOF
banned_parse "$BX/list.md" "$BX/pairs" "$BX/toks" "$BX/excl" "$BX/scopes"
printf '판정과 판단만 있다.\n' > "$BX/clean.md"
printf '새 판을 낸다.\n' > "$BX/dirty.md"
check "제외 안의 것은 안 잡는다"    "[ -z \"\$(banned_report '$BX/pairs' '$BX/clean.md' '$BX/excl')\" ]"
check "제외 밖의 것은 잡는다"       "banned_report '$BX/pairs' '$BX/dirty.md' '$BX/excl' | grep -qF '판 -> 버전'"
printf 'clean.md\ndirty.md\n' > "$BX/files"
BXSCAN="$(cd "$BX" && banned_scan "$BX/pairs" "$BX/excl" "$BX/scopes" '모든 글에 적용' "$BX/files")"
check "한 번에 훑어 걸린 파일을 낸다" "printf '%s' \"\$BXSCAN\" | grep -qF 'dirty.md'"
check "제외에 걸린 파일은 안 든다"   "! printf '%s' \"\$BXSCAN\" | grep -qF 'clean.md'"
check "적용 대상으로 행을 고른다"    "[ \"\$(printf '%s\\n' \"\$BXSCAN\" | grep -c .)\" = 1 ]"
check "적용 대상을 제목에서 읽는다"  "[ \"\$(tr '\\n' '/' < '$BX/scopes')\" = '모든 글에 적용/답변과 산출물에만 적용/' ]"
check "같은 단계의 다음 제목에서 표를 끝낸다" "! grep -qx '새' '$BX/toks'"
# 긴 제외어가 짧은 것에 먹히면 안 된다. `판단` 을 먼저 덮으면 `판단력` 이 더는 안 맞는다.
cat > "$BX/list2.md" <<'BANEOF'
## 금지 표현

| 쓰지 않는 말 | 대신 쓰는 말 | 제외 |
|---|---|---|
| `판` | 버전 | `판단` · `판단력` |
BANEOF
banned_parse "$BX/list2.md" "$BX/pairs2" "$BX/toks2" "$BX/excl2" "$BX/scopes2"
printf '판단력이 있다.\n' > "$BX/long.md"
check "긴 제외어가 먼저 덮인다"      "[ -z \"\$(banned_report '$BX/pairs2' '$BX/long.md' '$BX/excl2')\" ]"
# 상시 보기는 세션에 싣는 짧은 목록이다. 표 읽기는 banned_parse 결과만 쓰고 제외어는 넣지 않는다.
cat > "$BX/list3.md" <<'BANEOF'
# 금지어 시험 목록

## 금지 표현

설명 문단이다.

| 쓰지 않는 말 | 대신 쓰는 말 | 제외 |
|---|---|---|
| `앞` | 머리 | — |

### 모든 글에 적용

| 쓰지 않는 말 | 대신 쓰는 말 | 제외 |
|---|---|---|
| `판` | 버전 | `판정` · `판단` |

## 표로 적을 수 없는 규칙

설명 문장이다.

- 규칙 하나다.
BANEOF
check "상시 보기가 정한 형식을 낸다" "[ \"\$(banned_view '$BX/list3.md')\" = \"\$(printf '# 금지어 시험 목록\n\n- \`앞\` → 머리\n\n## 모든 글에 적용\n\n- \`판\` → 버전\n\n## 표로 적을 수 없는 규칙\n\n- 규칙 하나다.')\" ]"
check "상시 보기에 제외어가 없다"      "! banned_view '$BX/list3.md' | grep -qF '판정'"
check "CRLF 표도 같은 보기를 낸다"    "sed 's/\$/\r/' '$BX/list3.md' > '$BX/list3crlf.md' && [ \"\$(banned_view '$BX/list3crlf.md')\" = \"\$(banned_view '$BX/list3.md')\" ] && ! banned_view '$BX/list3crlf.md' | grep -q \$'\r'"
check "행이 없는 표는 실패하고 아무것도 내지 않는다" "printf '# 빈 목록\n' > '$BX/empty.md' && ! banned_view '$BX/empty.md' > '$BX/empty.out' && [ ! -s '$BX/empty.out' ]"

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
check "공백 든 경로가 정확히 한 번"          "[ \"\$(printf '%s' \"\$WSOUT\" | grep -o 'my spec.md' | wc -l)\" = 1 ]"
check "차단 응답이 유효한 JSON"              "printf '%s' \"\$WSOUT\" | json_valid_stdin"


echo "[hooks 배선 — 이 파일이 깨지면 게이트가 통째로 죽는다]"
# 배선 파일 자체를 아무 테스트도 안 보던 구멍을 막는다. 배선 파일에 쉼표 하나가 어긋나도 파일 이름만 보는
# 검사는 통과하므로 유효성부터 확인한다.
HJ="$HERE/hooks/hooks.json"
for hj in "$HERE"/hooks/hooks*.json; do
  hn="$(basename "$hj")"
  check "$hn 이 유효한 JSON"              "json_valid_stdin < '$hj'"
done

# 배선이 가리키는 경로가 실제로 존재하는가. ${CLAUDE_PLUGIN_ROOT}는 레포 루트로 치환해 확인한다.
# 배선 파일은 디렉터리에서 도출해 확인한다. 이름을 손으로 적으면 새 배선 파일이 검사 밖에 남는다.
missing=""
for hj in "$HERE"/hooks/hooks*.json; do
  for rel in $(sed -n 's|.*\${CLAUDE_PLUGIN_ROOT}/\([^"]*\)\\".*|\1|p' "$hj"); do
    [ -f "$HERE/$rel" ] || missing="$missing $(basename "$hj"):$rel"
  done
done
check "hooks.json 명령 경로가 모두 실재한다" "[ -z \"\$missing\" ]"
[ -n "$missing" ] && echo "    없는 파일:$missing"

# 남는 훅 목록은 이 배열 하나다. 개수를 따로 적지 않고 배열과 배선의 연결 목록을 통째로 대조한다.
KEEP_HOOKS=(scaffold.sh update_check_sessionstart.sh spec_gate_sessionstart.sh readonly_pretooluse.sh
            spec_review_posttooluse.sh doc_word_posttooluse.sh reply_reminder_userpromptsubmit.sh stop_gates.sh)
WIRED_LIST="$(json_run 'import json,sys; d=json.load(open(sys.argv[1],encoding="utf-8"))["hooks"]; print("\n".join(h["command"].rsplit("/",1)[-1].rstrip("\"") for ev in d.values() for g in ev for h in g["hooks"]))' "$HJ" | tr -d '\r' | sort)"
KEEP_LIST="$(printf '%s\n' "${KEEP_HOOKS[@]}" | sort)"
check "hooks.json 연결 수가 남는 훅 목록과 같다" "[ \"\$WIRED_LIST\" = \"\$KEEP_LIST\" ]"
[ "$WIRED_LIST" = "$KEEP_LIST" ] || { echo "    배선:"; printf '      %s\n' $WIRED_LIST; }

ssm() { json_run 'import json,sys; d=json.load(sys.stdin)["hooks"]["SessionStart"]; print([g.get("matcher","") for g in d for h in g["hooks"] if sys.argv[1] in h["command"]][0])' "$1" < "$HJ"; }
check "갱신 확인은 startup 에서만 실행한다"   "[ \"\$(ssm update_check_sessionstart.sh)\" = 'startup' ]"
check "세션 시작 표시는 startup 에 실행한다"  "ssm spec_gate_sessionstart.sh | grep -qw startup"
check "스캐폴드는 compact 에 실행하지 않는다" "! ssm scaffold.sh | grep -qw compact"

# 훅 스크립트를 만들어 놓고 배선을 잊는 것을 막는다. 밑줄로 시작하는 것은 공유 헬퍼라 제외한다.
# 확장자로 찾지 않는다. 확장자 없는 훅 파일이 글롭에서 빠지면 배선 누락을 못 잡는다.
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

echo "[적대 점검 — PowerShell 연결과 셸 쓰기 구문]"
# 2026-11-17 적대 점검이 재현한 결함마다 검사를 하나 이상 둔다. 실제 훅 입력처럼 cwd 를 tool_name 앞에 둔다.
JP() { printf '{"tool_name":"PowerShell","tool_input":{"command":"%s"}}' "$1"; }
JBC() { printf '{"cwd":"%s","tool_name":"%s","tool_input":{"command":"%s"}}' "$1" "$2" "$3"; }
psx() { ( . "$HERE/hooks/_hook_input.sh"; . "$HERE/hooks/_extract_ps_targets.sh"; ps_write_targets "$1" ) 2>/dev/null | tr '\n' ' '; }
hmatch() { json_run 'import json,sys; d=json.load(open(sys.argv[1],encoding="utf-8"))["hooks"][sys.argv[2]]; print(" ".join(g.get("matcher","") for g in d for h in g["hooks"] if sys.argv[3] in h["command"]))' "$HJ" "$1" "$2"; }
check "읽기 전용 훅 매처에 Bash·PowerShell 이 있다" "hmatch PreToolUse readonly_pretooluse.sh | grep -qw Bash && hmatch PreToolUse readonly_pretooluse.sh | grep -qw PowerShell"
check "금지어 훅 매처에 PowerShell 이 있다"         "hmatch PostToolUse doc_word_posttooluse.sh | grep -qw PowerShell"
PSCMD='Set-Content -Path a.md -Value x; Get-Date | Out-File -FilePath b.md; "x" | Add-Content c.md; Copy-Item s.md -Destination d.md; echo x > e.md; echo y 2>$null; Set-Content -Encoding utf8 f.md "z"'
check "PowerShell 쓰기 대상을 뽑는다"               "[ \"\$(psx \"\$PSCMD\")\" = 'a.md b.md c.md d.md e.md f.md ' ]"
check "PowerShell 읽기 명령은 대상이 없다"          "[ -z \"\$(psx 'Get-Content a.md | Select-String \"x > y.md\"')\" ]"
check "PowerShell 로 쓴 산출물의 금지 표현을 알린다" "dwp '$(JP "Set-Content -Path $BW/draft.md -Value x")' | grep -qF additionalContext"
# 읽기 전용 파일은 셸로 고쳐도 거부한다.
check "셸 재지향으로 읽기 전용 파일에 쓰면 deny"    "rpre '$(JB "echo x > $RO/sealed.md")' | grep -qF '\"permissionDecision\":\"deny\"'"
check "sed -i·cp 대상이 읽기 전용이면 deny"         "rpre '$(JB "sed -i s/a/b/ $RO/sealed.md")' | grep -qF deny && rpre '$(JB "cp $RO/open.md $RO/sealed.md")' | grep -qF deny"
check "PowerShell 로 읽기 전용 파일에 쓰면 deny"    "rpre '$(JP "Set-Content -Path $RO/sealed.md -Value x")' | grep -qF deny"
check "셸로 읽기만 하면 읽기 전용이어도 통과"       "[ -z \"\$(rpre '$(JB "cat $RO/sealed.md")')\" ]"
# 쓰기 구문: 1>·&>·>| 는 쓰기이고 2> 와 따옴표 안의 > 는 쓰기가 아니다.
check "1>·&>·>| 재지향을 쓰기로 본다"               "gate_runs '$(JB 'echo x 1> f.md')' && gate_runs '$(JB 'echo x &> f.md')' && gate_runs '$(JB 'echo x >| f.md')' && [ \"\$(ebt 'echo x 1> f.md; echo y &> g.md; echo z >| h.md')\" = 'f.md g.md h.md ' ]"
check "따옴표 안의 > 는 재지향이 아니다"            "! gate_runs '$(JB 'git commit -m \"a > notes.md\"')' && [ -z \"\$(ebt 'git commit -m \"a > notes.md\"')\" ]"
mkdir -p "$BW/outdir" "$BW/outdir2"; cp "$BW/draft.md" "$BW/outdir/"; cp "$BW/draft.md" "$BW/outdir2/"
check "cp 목적지가 폴더면 원본 이름을 붙인다"       "dwp '$(JB "cp $BW/draft.md $BW/outdir")' | grep -qF 'outdir/draft.md'"
check "cp -t 폴더 형식을 처리한다"                  "dwp '$(JB "cp -t $BW/outdir2 $BW/draft.md")' | grep -qF 'outdir2/draft.md'"
check "셸 상대 경로는 훅 입력 cwd 기준으로 푼다"    "( cd / && printf '%s' '$(JBC "$BW" Bash "sed -i s/x/y/ draft.md")' | bash '$DWPOST' ) | grep -qF additionalContext"
check "읽기 전용 훅도 cwd 기준으로 푼다"            "( cd / && printf '%s' '$(JBC "$RO" Bash "echo x > sealed.md")' | bash '$RPRE' ) | grep -qF deny"
check "Write 상대 경로도 cwd 기준으로 푼다"         "( cd / && printf '{\"cwd\":\"%s\",\"tool_name\":\"Write\",\"tool_input\":{\"file_path\":\"draft.md\"}}' '$BW' | bash '$DWPOST' ) | grep -qF additionalContext"

echo "[적대 점검 — 세션 시작 표시와 Stop 게이트]"
check "세션 시작 표시 훅이 startup·resume·clear 에 실행된다" "[ \"\$(ssm spec_gate_sessionstart.sh)\" = 'startup|resume|clear' ]"
G5="$(mktemp -d)"; ( cd "$G5" && git init -q && git config user.email t@t && git config user.name t )
mkdir -p "$G5/docs/superpowers/specs"; printf 'pre\n' > "$G5/docs/superpowers/specs/pre.md"
printf '{"session_id":"s5","cwd":"%s","hook_event_name":"SessionStart","source":"startup"}' "$G5" | bash "$CSTA" || true
check "세션 시작 표시에 그때의 미추적 spec 목록을 적는다" "grep -qxF 'docs/superpowers/specs/pre.md' \"\$TMPDIR/disciplined-coder/session-start-s5\""
printf 'late\n' > "$G5/docs/superpowers/specs/late.md"; touch -d '2000-01-01' "$G5/docs/superpowers/specs/late.md"
check "목록에 없는 새 spec 은 수정 시각이 오래되어도 막는다" "stop '{\"cwd\":\"$G5\",\"session_id\":\"s5\"}' | grep -qF 'late.md'"
check "목록에 있는 세션 전 초안은 막지 않는다"     "! stop '{\"cwd\":\"$G5\",\"session_id\":\"s5\"}' | grep -qF 'pre.md'"
mkdir -p "$TMPDIR/disciplined-coder"; : > "$TMPDIR/disciplined-coder/session-start-old7"; touch -d '2000-01-01' "$TMPDIR/disciplined-coder/session-start-old7"
printf '%s' "$(JSU st7 startup)" | bash "$CSTA" || true
check "7일 지난 세션 시작 표시를 지운다"            "[ ! -e \"\$TMPDIR/disciplined-coder/session-start-old7\" ] && [ -e \"\$TMPDIR/disciplined-coder/session-start-st7\" ]"
GW="$(mktemp -d)"; REALGIT="$(command -v git)"
printf '#!/usr/bin/env bash\nprintf "%%s\\n" "$*" >> "%s/log"\nexec "%s" "$@"\n' "$GW" "$REALGIT" > "$GW/git"; chmod +x "$GW/git"
( PATH="$GW:$PATH"; export PATH; stop "{\"cwd\":\"$G5\"}" ) >/dev/null || true
check "Stop 의 git status 는 spec·plan 폴더만 본다" "grep '^status' '$GW/log' | grep -qF 'docs/superpowers/specs'"
G6="$(mktemp -d)"; ( cd "$G6" && git init -q && git config user.email t@t && git config user.name t )
mkdir -p "$G6/docs/superpowers/specs"; printf 'draft\n' > "$G6/docs/superpowers/specs/UPPER.MD"
check "대문자 .MD spec 도 Stop 이 막는다"           "stop '{\"cwd\":\"$G6\"}' | grep -qF 'UPPER.MD'"
mterm() { ( . "$HERE/hooks/_spec_marker.sh"; marker_is_terminal "$1" ); }
printf 'body\n<!-- spec-review: passed -->   \n' > "$T/mk-trail.md"
printf 'body\n<!-- spec-review: passedX -->\n' > "$T/mk-glued.md"
printf 'body\n<!-- spec-review: escalatedfoo lenses=2 -->\n' > "$T/mk-glued2.md"
check "마커 뒤 줄 끝 공백을 허용한다"               "mterm '$T/mk-trail.md'"
check "passed·escalated 에 글자가 붙은 마커는 인정하지 않는다" "! mterm '$T/mk-glued.md' && ! mterm '$T/mk-glued2.md'"

echo "[적대 점검 — 금지어 알림]"
printf '값은 `x 이고 이 자리는 남는다.\n다음 줄의 ` 표시다.\n' > "$DWDIR/tick.md"
check "짝 없는 백틱은 다음 줄까지 가리지 않는다"   "dwp '$(JW "$DWDIR/tick.md")' | grep -qF additionalContext"
printf '\xff\xfe 이 자리는 남는다.\n' > "$DWDIR/badutf.md"
check "잘못된 UTF-8 이 섞여도 검사한다"             "dwp '$(JW "$DWDIR/badutf.md")' | grep -qF additionalContext"
printf '현재는 상태다.\n' > "$DWDIR/excl.md"
check "Edit 구간 밖 제외어로 이어진 말은 잡지 않는다" "[ -z \"\$(dwp '$(JEd "$DWDIR/excl.md" 'X' '재는' '' ',"tool_response":{"originalFile":"현X 상태다.\n"}')')\" ]"
printf '```\n자리\n```\n\n자리\n' > "$DWDIR/noorig.md"
check "원래 파일이 없으면 new_string 자체를 검사한다" "dwp '$(JEd "$DWDIR/noorig.md" 'X' '자리')' | grep -qF additionalContext"
printf '%s\n' "$DWBODY" > "$DWDIR/upper.MD"
check "대문자 .MD 산출물도 검사한다"               "dwp '$(JW "$DWDIR/upper.MD")' | grep -qF additionalContext"
printf '<html><body><p>이 자리는 남는다.</p></body></html>\n' > "$DWDIR/page.html"
printf '<p class="자리">본문이다.</p><script>var 자리 = 1;</script><style>/* 자리 */</style>\n' > "$DWDIR/tags.html"
check "HTML 산출물 본문의 금지 표현을 알린다"      "dwp '$(JW "$DWDIR/page.html")' | grep -qF additionalContext"
check "HTML 의 태그·script·style 안은 검사하지 않는다" "[ -z \"\$(dwp '$(JW "$DWDIR/tags.html")')\" ]"
check "알림이 자연스러우면 그대로 두라고 한다"     "printf '%s' \"\$DWW_OUT\" | grep -qF '문장 전체가 자연스러우면 그대로 두고'"
NL="$T/nolist"; mkdir -p "$NL/hooks" "$NL/scripts"; cp "$HERE"/hooks/*.sh "$NL/hooks/"; cp "$HERE/scripts/_json_valid.sh" "$NL/scripts/"
check "금지어 목록이 없으면 검사하지 못했다고 알린다" "printf '%s' '$(JW "$DWDIR/report.md")' | bash '$NL/hooks/doc_word_posttooluse.sh' | grep -qF '금지어 목록이 없어 검사하지 못했다'"
check "doc_word 는 입력을 한 번에 읽는다"           "! grep -qF \"read -r -d ''\" '$DWPOST' && grep -qF 'INPUT=\"\$(cat)\"' '$DWPOST'"
check "낡은 주석: 셸 대상 뽑기가 Stop 겹을 말하지 않는다" "! grep -qF 'Stop 에서' '$EBT'"
check "낡은 주석: 금지어 헬퍼가 없는 훅을 소비자로 적지 않는다" "! grep -qF '훅 셋' '$HERE/hooks/_banned_words.sh'"
check "낡은 주석: doc_word 가 프로그램이 쓴 파일을 못 본다고 적는다" "grep -qF '프로그램이 쓴 파일' '$DWPOST'"
check "낡은 주석: 리마인더가 3단계 측정을 가리킨다" "! grep -qF '측정은 아직 없' '$HERE/hooks/reply_reminder_userpromptsubmit.sh' && grep -qF 'v2 상시 지시 검증' '$HERE/hooks/reply_reminder_userpromptsubmit.sh'"
check "낡은 주석: Stop 이 v1 조항 ID 를 쓰지 않는다" "! grep -qF 'FOCUSED' '$STOP'"

echo "[훅 계약 — 끄는 변수 없음, 거부 없는 알림, 금지어 없는 지시문]"
# 끄는 환경 변수를 두지 않는다. 판정 대상은 훅 코드의 `"${DISCIPLINED_CODER_X:-on}" = "off"` 같은 비교다.
check "끄는 환경 변수가 없다" "! grep -rqE 'DISCIPLINED_CODER_[A-Z_]+.*= *\"?off' '$HERE/hooks'"
# doc_word 는 알리기만 한다. 알림이 실제로 나온 입력에서 거부 칸이 없는지 본다. 빈 출력이면 이 검사가 뜻이 없다.
check "doc_word 는 거부하지 않는다" \
  "( for o in \"\$DWW_OUT\" \"\$DWPOST_OUT\"; do printf '%s' \"\$o\" | grep -qF additionalContext || exit 1; ! printf '%s' \"\$o\" | grep -qE '\"decision\" *: *\"block\"|permissionDecision' || exit 1; done )"
# 훅이 Claude 에게 보내는 글은 모델이 낱말을 따라 쓰므로 금지어가 백틱 밖에 없어야 한다.
# 출력 픽스처는 spec 리뷰 지시, Stop 차단 사유, 금지어 알림, 갱신 알림(성공·실패), 읽기 전용 거부 사유,
# 리마인더다.
banned_parse "$HERE/korean-banned-words.md" "$T/rbw.pairs" "$T/rbw.toks" "$T/rbw.excl"
htext() { json_run 'import json,sys; d=json.load(sys.stdin); h=d.get("hookSpecificOutput") or {}; sys.stdout.write("\n".join(str(x) for x in (d.get("reason"), d.get("systemMessage"), h.get("additionalContext"), h.get("permissionDecisionReason")) if x))' 2>/dev/null; }
HB="$T/hookmsg"; mkdir -p "$HB"
ptu "$(J "$SP/nomark.md")" | htext > "$HB/spec_review.txt" || true
stop "{\"cwd\":\"$G4\",\"session_id\":\"s9\"}" | htext > "$HB/stop_gates.txt" || true
printf '%s' "$DWW_OUT" | htext > "$HB/doc_word.txt" || true
. "$HERE/scripts/_test_uc_fixture.sh"
HU1="$(mktemp -d)"; uc_fixture "$HU1" "$A40" 0 "$B40" > /dev/null; run_uc "$HU1" | htext > "$HB/update_ok.txt" || true
HU2="$(mktemp -d)"; uc_fixture "$HU2" "$A40" 7 "$B40" > /dev/null; run_uc "$HU2" | htext > "$HB/update_fail.txt" || true
rpre "$(J "$RO/sealed.md")" | htext > "$HB/readonly.txt" || true
printf '' | bash "$HERE/hooks/reply_reminder_userpromptsubmit.sh" | htext > "$HB/reply_reminder.txt" || true
# scaffold 의 stdout 은 SessionStart 맥락으로 Claude 에게 간다. 두 번째 실행의 출력(핸드오프·플러그인 알림)을 본다 —
# 첫 실행은 원칙과 목록 전문을 싣는데 그 검사는 test_docs_drift.sh 가 맡는다. 홈은 모두 임시 폴더로 돌린다.
HSC="$(mktemp -d)"; PSC="$(mktemp -d)"; printf '# 인계\n' > "$PSC/HANDOFF-x.md"
scf() { HOME="$HSC" USERPROFILE="$HSC" CLAUDE_CONFIG_DIR="$HSC/.claude" CLAUDE_HOME_DIR="$HSC/.claude" CLAUDE_PROJECT_DIR="$PSC" CLAUDE_PLUGIN_ROOT="$HERE" bash "$HERE/scripts/scaffold.sh" 2>/dev/null; }
scf > /dev/null || true; scf > "$HB/scaffold.txt" || true
HB_EMPTY=""; HB_BAD=""
for f in "$HB"/*.txt; do
  [ -s "$f" ] || HB_EMPTY="$HB_EMPTY $(basename "$f")"
  r="$(banned_report "$T/rbw.pairs" "$f" "$T/rbw.excl")"
  [ -z "$r" ] || HB_BAD="$HB_BAD $(basename "$f"):[$r]"
done
[ -n "$HB_EMPTY" ] && echo "    출력이 비어 있는 픽스처:$HB_EMPTY"
[ -n "$HB_BAD" ] && echo "    금지어:$HB_BAD"
check "훅이 Claude 에게 보내는 글에 백틱 밖 금지어가 없다" "[ -z \"\$HB_EMPTY\" ] && [ -z \"\$HB_BAD\" ]"
# 리뷰 스킬 이름은 _spec_marker.sh 의 REVIEW_SKILL 하나가 소유한다. 지시문이 그 값을 쓰는지 본다.
REVIEW_SKILL_VAL="$( . "$HERE/hooks/_spec_marker.sh"; printf '%s' "${REVIEW_SKILL:-}" )"
check "리뷰 지시가 REVIEW_SKILL 값을 담는다" "[ -n \"\$REVIEW_SKILL_VAL\" ] && grep -qF -- \"\$REVIEW_SKILL_VAL\" '$HB/spec_review.txt' && grep -qF -- \"\$REVIEW_SKILL_VAL\" '$HB/stop_gates.txt'"

# --- JSON 이스케이프: 제어 문자가 날것으로 안 나간다 ---
# 개행·복귀·탭만 다루면 그 밖의 0x20 미만 문자가 문자열 값에 날것으로 들어가고, 응답이 파싱되지
# 않아 차단 결정이 통째로 무시된다. 소비자는 이 헬퍼를 source하는 훅 전부다.
echo "[JSON 이스케이프 — 제어 문자]"
. "$HERE/hooks/_json_escape.sh"
ESC_MIX="$(escape_for_json "$(printf 'a"b\\c\nd\te\001f\013g\033h')")"
check "섞인 입력의 결과가 JSON으로 파싱된다" \
  "printf '{\"r\":\"%s\"}' \"\$ESC_MIX\" | json_valid_stdin"
check "제어 문자가 결과에 안 남는다" \
  "! printf '%s' \"\$ESC_MIX\" | LC_ALL=C grep -q '[[:cntrl:]]'"


echo "[명령 뽑기] 공유 헬퍼가 명령 칸을 끝까지 뽑는다"
xcmd() { ( INPUT="$1"; . "$HERE/hooks/_hook_input.sh"; hook_command; printf '%s' "$CMD" ); }
# 명령 뽑기 — 큰따옴표가 든 명령이 첫 \" 에서 잘리면 그 뒤의 명령어를 훅이 못 본다.
EX1="$(xcmd '{"tool_input":{"command":"echo \"a\" && python3 x.py"}}')"
check "따옴표가 든 명령을 끝까지 뽑는다"   "[ \"\$EX1\" = 'echo \"a\" && python3 x.py' ]"
check "command 가 없으면 무출력"           "[ -z \"\$(xcmd '{}')\" ]"

echo "[배선된 스크립트 — 머리 주석이 하는 일을 적는다]"
# 훅 목록과 하는 일의 원본은 README 가 아니라 배선 파일과 각 스크립트의 머리 주석이다.
# 그래서 배선된 스크립트마다 둘째 줄이 주석인지 본다. 설명 없는 훅이 들어오면 여기서 실패한다.
HOOK_WIRED="$(grep -ohE '[a-z_]+\.sh' "$HERE/hooks/hooks.json" "$HERE/.claude/settings.json" | sort -u)"
check "배선 파일에서 스크립트 이름을 뽑았다" "[ -n \"\$HOOK_WIRED\" ]"
HOOK_NOHEAD=""
while IFS= read -r sname; do
  [ -n "$sname" ] || continue
  f="$HERE/hooks/$sname"; [ -f "$f" ] || f="$HERE/scripts/$sname"
  sed -n '2p' "$f" 2>/dev/null | grep -qE '^# .+' || HOOK_NOHEAD="$HOOK_NOHEAD $sname"
done <<EOF
$HOOK_WIRED
EOF
[ -n "$HOOK_NOHEAD" ] && echo "    머리 주석이 없는 스크립트:$HOOK_NOHEAD"
check "배선된 스크립트가 모두 머리 주석을 둔다" "[ -z \"\$HOOK_NOHEAD\" ]"


echo "[reply-reminder]"
RR="$HERE/hooks/reply_reminder_userpromptsubmit.sh"
rr() { printf '{"session_id":"s","hook_event_name":"UserPromptSubmit","prompt":"%s"}' "$1" | bash "$RR"; }
RR_CTX='import json,sys; print(json.load(sys.stdin)["hookSpecificOutput"]["additionalContext"])'
check "리마인더가 올바른 UserPromptSubmit JSON 이다" "out=\"\$(rr '이 함수를 고쳐봐')\" && json_valid_stdin <<<\"\$out\" && grep -qF '\"hookEventName\":\"UserPromptSubmit\"' <<<\"\$out\""
check "리마인더 본문이 비어 있지 않다"              "[ -n \"\$(rr '이 함수를 고쳐봐' | json_run \"\$RR_CTX\")\" ]"
check "메시지와 무관하게 같은 글을 낸다"            "[ \"\$(rr '이 함수를 고쳐봐')\" = \"\$(rr '커밋 됐어')\" ]"
check "빈 표준 입력에도 붙이고 0 으로 끝난다" "out=\"\$(printf '' | bash \"\$RR\")\" && json_valid_stdin <<<\"\$out\""
check "UserPromptSubmit 이 리마인더를 연결한다" "json_run 'import json,sys; d=json.load(open(sys.argv[1],encoding=\"utf-8\")).get(\"hooks\",{}).get(\"UserPromptSubmit\",[]); sys.exit(0 if any(\"reply_reminder_userpromptsubmit.sh\" in h[\"command\"] for g in d for h in g[\"hooks\"]) else 1)' \"\$HERE/hooks/hooks.json\""

echo "----"; echo "PASS=$pass FAIL=$fail"; [ "$fail" -eq 0 ]
