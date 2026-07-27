---
description: ultracode(멀티에이전트 워크플로) 검증 모드를 required(워크플로에 reviewer-* 렌즈 검증 단계 필수)와 discretion(기본 — 리스크 비례 재량, 보고서에 검증 내역 명시) 사이에서 토글한다. 인자가 없으면 현재 모드를 표시한다. PC 전역이며 다음 세션부터 적용된다.
---
`bash "${CLAUDE_PLUGIN_ROOT}/scripts/ultracode-review.sh" $ARGUMENTS`를 실행하고 결과를 한 줄로 보고하라. 인자는 `required` 또는 `discretion`(없으면 현재 모드를 표시한다).
