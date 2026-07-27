---
description: Sets up the machine-wide discipline environment (~/.claude/disciplined-coder/) — creates the solved log only if it does not already exist, copies and refreshes the discipline canon (agent-principles.md, domains-index.md), and regenerates the @import block in ~/.claude/CLAUDE.md (idempotent).
---

다음 스크립트를 실행해 PC 전역 디시플린 환경(~/.claude/disciplined-coder/)을 스캐폴드하라:

`bash "${CLAUDE_PLUGIN_ROOT}/scripts/scaffold.sh"`

실행 후 어떤 파일이 새로 생성됐고 어떤 파일이 이미 있었는지 한 줄로 보고하라.
