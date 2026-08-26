# **워크플로 스크립트(`.claude/workflows/self-audit.js` 등)를 ESM으로(`node --input-type=module --check`) 검증하면 톱레벨 `return`에서 "Illegal return statement"로 실패한다.**

- 원인: 워크플로 스크립트 본문은 하니스가 async 함수로 감싸 실행하므로 톱레벨 `return`이 정상이다.
- 해결: 문법 검증은 같은 방식으로 감싼다 — `{ echo 'const __wrap = async () => {'; sed 's/^export const meta/const meta/' <파일>; echo '};'; } | node --check`.
