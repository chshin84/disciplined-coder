#!/usr/bin/env bash
# SessionStart(startup|resume|clear): 이 세션의 코드 넛지 표시 파일을 지운다.
# 표시 파일은 "이 맥락에서 이미 알렸다"를 뜻한다. 세션이 새로 시작하거나 재개되거나 비워지면 스킬이 다시
# 안 실린 맥락이므로 표시도 지운다. 재개한 세션이 같은 session_id 를 다시 받는지는 훅 문서가 정하지 않고
# 이 PC 의 전사 파일로도 갈리지 않았는데, 이 훅이 있으면 어느 쪽이든 맞는다 — 아이디가 새로 나면 없는
# 파일을 지우는 무해한 동작이고, 재사용되면 넛지가 제대로 다시 걸린다. 이 훅이 지우는 것은 이 세션
# 자신의 표시뿐이다. 다른 세션이 남긴 표시 파일은 손대지 않고 운영체제의 임시 폴더 정리에 맡긴다.
# 게이트 환경변수와 무관하다 — 지우는 것은 안내가 아니라 청소다.
set -euo pipefail
INPUT="$(cat)"
sid="$(printf '%s' "$INPUT" | grep -o '"session_id"[[:space:]]*:[[:space:]]*"[^"]*"' | head -1 | sed 's/.*:[[:space:]]*"\([^"]*\)"$/\1/' || true)"
[ -n "$sid" ] || exit 0
mdir="${TMPDIR:-/tmp}/disciplined-coder"
# 서브에이전트 몫은 agent_id 가 뒤에 붙으므로 글롭으로 함께 지운다. 없으면 -f 가 조용히 넘어간다.
rm -f "$mdir/code-nudge-$sid" "$mdir/code-nudge-$sid"-* 2>/dev/null || true
exit 0
