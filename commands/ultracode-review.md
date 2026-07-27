---
description: Toggles the verification mode for ultracode (multi-agent workflows) between required (a reviewer-* lens verification step is mandatory in the workflow) and discretion (default — risk-proportionate discretion, with verification details noted in the report). Shows the current mode when called with no argument. Machine-wide; takes effect starting the next session.
---
`bash "${CLAUDE_PLUGIN_ROOT}/scripts/ultracode-review.sh" $ARGUMENTS`를 실행하고 결과를 한 줄로 보고하라. 인자는 `required` 또는 `discretion`(없으면 현재 모드를 표시한다).
