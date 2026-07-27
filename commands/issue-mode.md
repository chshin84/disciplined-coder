---
description: Toggles the disposal mode for unresolved items in the solved log between surface (default — surfaces to memory and the user) and issues (delegates must-keep items to GitHub Issues). Shows the current mode when called with no argument. Machine-wide; takes effect starting the next session.
---
`bash "${CLAUDE_PLUGIN_ROOT}/scripts/issue-mode.sh" $ARGUMENTS`를 실행하고 결과를 한 줄로 보고하라. 인자는 `surface` 또는 `issues`(없으면 현재 모드를 표시한다).
