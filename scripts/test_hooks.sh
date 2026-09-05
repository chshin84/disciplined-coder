#!/usr/bin/env bash
# 훅 스크립트 검증. 계약: FAIL=0 (매직넘버 금지 — 개수는 테스트가 센다).
set -euo pipefail
HERE="$(cd "$(dirname "$0")/.." && pwd)"
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
EXTRACT="$HERE/hooks/_extract_path.sh"
extract() { printf '%s' "$1" | bash "$EXTRACT"; }
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
# 게이트가 조용히 우회되면 안 된다(FAIL-LOUD). new.md 는 위에서 escalated(리뷰됨)이므로 차단 안 됨.
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

echo "[doc-format-pre]"
printf 'x\n' > "$T/existing.md"
check "새 문서(.md) → 양식 제안"         "fpre '$(J "$T/newdoc.md")' | grep -q additionalContext"
check "기존 문서(.md) → 무출력"          "[ -z \"\$(fpre '$(J "$T/existing.md")')\" ]"
check "spec 경로 새 .md → 무출력"        "[ -z \"\$(fpre '$(J "$SP/brandnew.md")')\" ]"
check "비문서(.py) → 무출력"             "[ -z \"\$(fpre '$(J "$T/src/new.py")')\" ]"
check "OFF → 무출력"                     "[ -z \"\$(DISCIPLINED_CODER_REVIEW_GATE=off fpre '$(J "$T/newdoc.md")')\" ]"
check "프로젝트 밖 새 문서 → 무출력"     "[ -z \"\$(fpre '$(J "$OUTSIDE/new.md")')\" ]"
check "새 리뷰 기록 → 무출력"            "[ -z \"\$(fpre '$(J "$T/docs/superpowers/reviews/new-check.md")')\" ]"
# 넛지가 인용한 domain-docs 절이 실재하는지 본다. 문자열 일치만 보던 시절 정본 영문화로
# 그 절 이름이 바뀌자 넛지가 없는 절을 가리킨 채 스위트가 초록으로 통과했다(FAIL-LOUD).
NUDGE_SEC="$(fpre "$(J "$T/newdoc.md")" | sed -n "s/.*domain-docs의 '\([^']*\)' 절.*/\1/p")"
check "넛지가 인용한 절 이름 추출됨"       "[ -n \"\$NUDGE_SEC\" ]"
check "그 절이 domain-docs에 실재"        "grep -qF \"## \$NUDGE_SEC\" '$HERE/skills/domain-docs/SKILL.md'"

echo "[doc-review-post]"
check "문서(.md) → 검진 넛지"            "drev '$(J "$T/existing.md")' | grep -q additionalContext"
check "spec 경로 → 무출력"               "[ -z \"\$(drev '$(J "$SP/nomark.md")')\" ]"
check "plan 경로 → 무출력"               "[ -z \"\$(drev '$(J "$PL/nomark.md")')\" ]"
check "비문서(.py) → 무출력"             "[ -z \"\$(drev '$(J "$T/src/main.py")')\" ]"
check "OFF → 무출력"                     "[ -z \"\$(DISCIPLINED_CODER_REVIEW_GATE=off drev '$(J "$T/existing.md")')\" ]"
check "프로젝트 밖 문서 → 무출력"        "[ -z \"\$(drev '$(J "$OUTSIDE/notes.md")')\" ]"
check "상대경로 문서 → 검진 넛지"        "drev '$(J "notes/rel.md")' | grep -q additionalContext"
check "Windows 형식 경로도 프로젝트 안"  "drev '$(J "$(cygpath -w "$T" 2>/dev/null || printf '%s' "$T")\\\\win.md")' | grep -q additionalContext"

echo "[리뷰 기록은 검진 대상이 아니다]"
# 리뷰 기록에 검진 넛지가 뜨면 기록에 대한 기록을 또 써야 하는 순환이 생긴다.
J2() { printf '{"tool_name":"Write","tool_input":{"file_path":"%s"}}' "$1"; }
check "리뷰 기록에는 넛지가 없다"  "[ -z \"\$(drev '$(J2 "$T/docs/superpowers/reviews/x-review.md")')\" ]"
# 오답노트도 기록에 대한 기록을 또 쓰게 만드는 부류다 — 교훈 한 줄을 적을 때마다 검진을 묻는
# 순환이 생기고, 그것을 매번 건너뛰다 보면 진짜 문서에서도 이 넛지를 흘려보내게 된다.
check "다른 문서에는 넛지가 뜬다"  "drev '$(J2 "$T/docs/guide.md")' | grep -q additionalContext"

echo "[project-solved nudge removed]"
PN="$(mktemp -d)"
in_claudemd() { printf '{"tool_name":"Write","tool_input":{"file_path":"%s/CLAUDE.md"}}' "$1"; }
OUT_GONE="$(in_claudemd "$PN" | CLAUDE_PROJECT_DIR="$PN" bash "$DREV" 2>&1)" || true
check "no add-pointer nudge anymore"  "! printf '%s' \"\$OUT_GONE\" | grep -qF 'add-pointer'"
# 렌즈 이름이 아니라 위임 대상을 단언한다 — 이름을 단언하면 이 테스트가 네 번째 사본이 된다(SSOT).
check "generic nudge fires instead"   "printf '%s' \"\$OUT_GONE\" | grep -qF 'domain-docs'"
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


echo "[README — 배선된 스크립트를 모두 적는다]"
# 훅이 일곱인데 안내 문서가 넷만 적고 있었다. 목록을 README 에 손으로 적지 않고 배선 파일 둘에서
# 도출해 맞댄다. 훅을 더하거나 빼면 여기서 함께 갈린다(SSOT).
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
