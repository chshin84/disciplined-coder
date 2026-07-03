# 해결된 문제 로그 (solved_problems) — 이 프로젝트 · append-only 오답노트

이 레포에서 완결한 문제의 교훈 — 차후 비슷한 작업에서 recall해 참고한다. 각 항목: 증상/트리거 → 교훈(다음엔 이렇게 — 처방이 앞).
**완결 후 등록하는 기록이라 '상태'가 아니다**(append-only, 과거를 지우지 않는다). 메인 세션만 append.
이 프로젝트에 한정된 교훈만 둔다 — 머신 전역은 PC solved, 보편은 디시플린 원칙으로(스코프 라우팅).

- **validate의 "version 미지정" 경고를 없애려 plugin.json에 version을 추가했는데, 공식 문서상 version 설정은 마켓플레이스 업데이트를 버전 비교로 전환해 활성 개발 중 커밋 배포가 끊긴다(같은 날 번복)** → 교훈: 다음엔 경고·린트 해소 수정이라도 동작을 바꾸는지 해당 도메인 참고서(`skills/domain-plugin` 등)를 먼저 연다 — §나(설계 입력)를 건너뛰면 3렌즈 리뷰도 이런 충돌을 못 잡는다(리뷰어는 계획 내부 정합을 보지, 안 연 참고서와의 충돌은 못 본다). 이 레포의 version 정책 정본은 domain-plugin '버전 핀 주의'다.
- **워크플로 스크립트(`.claude/workflows/self-audit.js` 등)를 ESM으로(`node --input-type=module --check`) 검증하면 톱레벨 `return`에서 "Illegal return statement"로 실패** → 교훈: 워크플로 스크립트 본문은 하니스가 async 함수로 감싸 실행하므로 톱레벨 `return`이 정상이다. 문법 검증은 같은 방식으로 감싼다 — `{ echo 'const __wrap = async () => {'; sed 's/^export const meta/const meta/' <파일>; echo '};'; } | node --check`.
- **spec/plan을 쓰면 Stop 훅이 리뷰어 완료 전에도 턴 종료를 반복 차단** → 교훈: 정상 동작이다(하드 게이트). 리뷰어를 백그라운드로 띄웠으면 마커 없이 턴을 끝내려 하지 말고, 차단 메시지에 상태만 답하며 리뷰 완료 알림을 기다린다 — 결과 없이 마커부터 다는 우회는 게이트가 막으려는 바로 그 행동이다.
