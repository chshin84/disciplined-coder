# 해결된 문제 로그 (solved_problems) — 이 프로젝트 · append-only 오답노트

이 레포에서 완결한 문제의 교훈 — 차후 비슷한 작업에서 recall해 참고한다. 각 항목: 증상/문제 → 교훈.
**완결 후 등록하는 기록이라 '상태'가 아니다**(append-only, 과거를 지우지 않는다). 메인 세션만 append.
이 프로젝트에 한정된 교훈만 둔다 — 머신 전역은 PC solved, 보편은 디시플린 원칙으로(스코프 라우팅).

- **워크플로 스크립트(`.claude/workflows/self-audit.js` 등)를 ESM으로(`node --input-type=module --check`) 검증하면 톱레벨 `return`에서 "Illegal return statement"로 실패** → 교훈: 워크플로 스크립트 본문은 하니스가 async 함수로 감싸 실행하므로 톱레벨 `return`이 정상이다. 문법 검증은 같은 방식으로 감싼다 — `{ echo 'const __wrap = async () => {'; sed 's/^export const meta/const meta/' <파일>; echo '};'; } | node --check`.
- **spec/plan을 쓰면 Stop 훅이 리뷰어 완료 전에도 턴 종료를 반복 차단** → 교훈: 정상 동작이다(하드 게이트). 리뷰어를 백그라운드로 띄웠으면 마커 없이 턴을 끝내려 하지 말고, 차단 메시지에 상태만 답하며 리뷰 완료 알림을 기다린다 — 결과 없이 마커부터 다는 우회는 게이트가 막으려는 바로 그 행동이다.
