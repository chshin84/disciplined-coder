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
# Codex apply_patch 입력 픽스처(패치는 JSON 문자열이라 개행이 \n 이스케이프됨)
AP1() { printf '{"tool_input":{"input":"*** Begin Patch\\n*** Update File: %s\\n@@\\n+x\\n*** End Patch\\n"}}' "$1"; }
AP2() { printf '{"tool_input":{"input":"*** Begin Patch\\n*** Update File: %s\\n@@\\n+x\\n*** Add File: %s\\n+y\\n*** End Patch\\n"}}' "$1" "$2"; }
APDEL() { printf '{"tool_input":{"input":"*** Begin Patch\\n*** Delete File: %s\\n*** End Patch\\n"}}' "$1"; }

T="$(mktemp -d)"; SP="$T/docs/superpowers/specs"; PL="$T/docs/superpowers/plans"; mkdir -p "$SP" "$PL" "$T/src"
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

echo "[extract]"
check "Claude file_path → 경로 1개"        "[ \"\$(extract '$(J "$T/src/a.md")')\" = '$T/src/a.md' ]"
check "Codex apply_patch update → 경로 1개" "[ \"\$(extract '$(AP1 "$T/src/b.md")')\" = '$T/src/b.md' ]"
check "Codex apply_patch delete → 경로 1개" "[ \"\$(extract '$(APDEL "$T/src/c.md")')\" = '$T/src/c.md' ]"
check "Codex 다중 파일 → 두 경로 모두"      "[ \"\$(extract '$(AP2 "$T/src/d.py" "$T/src/e.md")' | tr '\n' ',')\" = '$T/src/d.py,$T/src/e.md,' ]"
check "빈 입력 → 무출력"                    "[ -z \"\$(extract '{}')\" ]"
check "Claude backslash path → normalized" "[ \"\$(extract '$(J 'C:\\\\dir\\\\f.md')')\" = 'C:/dir/f.md' ]"

echo "[ptu]"
check "spec 미마커 → 리뷰 지시"          "ptu '$(J "$SP/nomark.md")' | grep -q additionalContext"
check "plan 미마커 → 리뷰 지시"          "ptu '$(J "$PL/nomark.md")' | grep -q additionalContext"
check "무관 경로 → 무출력"               "[ -z \"\$(ptu '$(J "$T/src/main.py")')\" ]"
check "OFF → 무출력"                     "[ -z \"\$(DISCIPLINED_CODER_REVIEW_GATE=off ptu '$(J "$SP/nomark.md")')\" ]"
check "terminal passed → 무출력"         "[ -z \"\$(ptu '$(J "$SP/passed.md")')\" ]"
check "terminal escalated → 무출력"      "[ -z \"\$(ptu '$(J "$SP/esc.md")')\" ]"
check "CRLF terminal → 무출력"           "[ -z \"\$(ptu '$(J "$SP/crlf.md")')\" ]"
check "본문 예시만(마지막 일반) → 지시"  "ptu '$(J "$SP/example.md")' | grep -q additionalContext"
check "pending(마커 아님) → 지시"        "ptu '$(J "$SP/pending.md")' | grep -q additionalContext"

echo "[stop]"
check "loop guard(active) → 통과"        "[ -z \"\$(stop '{\"stop_hook_active\":true,\"cwd\":\"$T\"}')\" ]"
check "OFF → 통과"                       "[ -z \"\$(DISCIPLINED_CODER_REVIEW_GATE=off stop '{\"cwd\":\"$T\"}')\" ]"
G="$(mktemp -d)"; ( cd "$G" && git init -q && git config user.email t@t && git config user.name t )
mkdir -p "$G/docs/superpowers/specs"
printf 'draft\n' > "$G/docs/superpowers/specs/new.md"
check "미리뷰 spec → block"              "stop '{\"cwd\":\"$G\"}' | grep -q '\"block\"'"
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
check "존재하지 않는 cwd → FAIL-OPEN(통과)" "[ -z \"\$(stop '{\"cwd\":\"$NG/nope/x\"}')\" ]"

echo "[doc-format-pre]"
printf 'x\n' > "$T/existing.md"
check "새 문서(.md) → 양식 제안"         "fpre '$(J "$T/newdoc.md")' | grep -q additionalContext"
check "기존 문서(.md) → 무출력"          "[ -z \"\$(fpre '$(J "$T/existing.md")')\" ]"
check "spec 경로 새 .md → 무출력"        "[ -z \"\$(fpre '$(J "$SP/brandnew.md")')\" ]"
check "비문서(.py) → 무출력"             "[ -z \"\$(fpre '$(J "$T/src/new.py")')\" ]"
check "OFF → 무출력"                     "[ -z \"\$(DISCIPLINED_CODER_REVIEW_GATE=off fpre '$(J "$T/newdoc.md")')\" ]"

echo "[doc-review-post]"
check "문서(.md) → 검진 넛지"            "drev '$(J "$T/existing.md")' | grep -q additionalContext"
check "spec 경로 → 무출력"               "[ -z \"\$(drev '$(J "$SP/nomark.md")')\" ]"
check "plan 경로 → 무출력"               "[ -z \"\$(drev '$(J "$PL/nomark.md")')\" ]"
check "비문서(.py) → 무출력"             "[ -z \"\$(drev '$(J "$T/src/main.py")')\" ]"
check "OFF → 무출력"                     "[ -z \"\$(DISCIPLINED_CODER_REVIEW_GATE=off drev '$(J "$T/existing.md")')\" ]"

echo "[codex apply_patch input]"
check "ptu: apply_patch spec 미마커 → 리뷰 지시"      "ptu '$(AP1 "$SP/nomark.md")' | grep -q additionalContext"
check "ptu: apply_patch 다중(2번째가 spec) → 지시"    "ptu '$(AP2 "$T/src/x.py" "$SP/nomark.md")' | grep -q additionalContext"
check "ptu: apply_patch terminal passed → 무출력"     "[ -z \"\$(ptu '$(AP1 "$SP/passed.md")')\" ]"
check "fpre: apply_patch 새 .md → 양식 제안"          "fpre '$(AP1 "$T/codexnew.md")' | grep -q additionalContext"
check "drev: apply_patch 기존 .md → 검진 넛지"        "drev '$(AP1 "$T/existing.md")' | grep -q additionalContext"
check "drev: apply_patch 비문서(.py) → 무출력"        "[ -z \"\$(drev '$(AP1 "$T/src/main.py")')\" ]"

echo "----"; echo "PASS=$pass FAIL=$fail"; [ "$fail" -eq 0 ]
