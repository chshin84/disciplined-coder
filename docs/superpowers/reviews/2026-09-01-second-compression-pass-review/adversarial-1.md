# lens-adversarial — 1회차 원본

대상: `docs/superpowers/specs/2026-09-01-second-compression-pass-design.md`
`principles_applied`: SIMPLE, REVERSIBLE, SSOT, MEASURE-FIRST, TDD, FAIL-LOUD, EXPLICIT, READ-FLOW, PLAIN-KO, CLEAR-COMM

## 이슈 열둘

1. **failure-mode — 줄일 세 문서가 검사가 가장 많이 붙든 세 문서다.** `test_docs_drift.sh`가 `domain-spec-review`를 25곳, `domain-docs`를 15곳, `lens-readability`를 7곳에서 한국어 문장 전체로 대조한다. 다시 쓰면 검사가 실패하고, 남는 길 셋 가운데 가장 싼 것이 check 줄 삭제다. `test_assertions.sh`는 단언 삭제를 못 잡는다.
2. **failure-mode — 목표와 금지가 서로를 막는다.** 대상 목록을 도출하는 `test_docs_drift.sh:492`가 곧 로직이다.
3. **risk — 성공 기준이 게임 가능하다.** ALL PASS는 검사를 지워도 얻어진다.
4. **irreversible — 개명이 레포에만 도착했다.** 설치본은 `gitCommitSha 95aff61`에 고정돼 있고 마켓플레이스 사본과 관리 디렉터리 사본은 아직 `reviewer-*`다. 정본은 `lens-*`를 부르라고 하는데 세션에 실린 스킬 이름은 `reviewer-*`다.
5. **irreversible — 개명·삭제·압축을 한 커밋에 묶었다.** 개명이 삭제와 추가로 기록돼 이력이 끊기고 부분 되돌리기가 불가능하다.
6. **irreversible — 근거를 지운 뒤 남은 근거 보관소를 다시 고친다.** DESIGN-NOTES 293줄을 지웠고, 이번 회차가 검사의 이유를 담은 주석을 금지 표현 때문에 다시 쓴다.
7. **failure-mode — 이유를 걷은 지시문은 문자 그대로 실행된다.** `lens-readability:79`가 예외 없이 "하나도 빠뜨리지 말고 지적하라"고 지시해 '대부분'의 `부분`, '제자리'의 `자리`를 올린다.
8. **risk — 문자열 금지는 회피와 왜곡을 낳는다.** 규칙을 만든 문서 자신이 검사 밖이라 자유롭게 쓴다. **완화 근거** — 정본 표에 「검사가 걸지만 정상인 말」을 함께 적어 검사가 그 표에서 도출하면 목록이 정본 안에 남아 따로 낡지 않는다.
9. **over-engineering — 두괄식은 문자열로 판정할 수 없다.** 프록시를 만들면 의례적 첫 문장이 절마다 붙는다. **단순화 근거** — 목표에서 「강제한다」를 빼고 렌즈가 보는 것으로 두면 새 장치 없이 같은 것을 얻는다.
10. **risk — 글자 수 목표가 줄바꿈 제거를 이득으로 만든다.** 이미 `lens-readability:79`가 2,000자 넘는 한 줄이고 검사가 그 형태를 고정한다. **완화 근거** — 정본 READ-FLOW가 "토큰을 아끼려 압축하지 않는다"고 정한다.
11. **failure-mode — 실행 절이 없다.** 정지 조건과 완료 기준과 되돌리기가 없다. 중간에 끊기면 앵커 절반이 깨진 채 남는다.
12. **risk — 셸까지 넓혀 얻는 이득이 작고 값은 영구적이다.** `경우` 둘과 `부분` 하나를 없애려고 모든 셸 파일에서 고빈도어 넷을 금지한다. **완화 근거** — 대상을 사용자가 읽는 글로 한정하면 넓히는 변경 없이 지금 계약이 유지된다.

## notes
더 확인할 것 셋 — 검사 실행은 읽기 전용이라 안 했고, 줄일 세 문서의 압축 여지를 세지 않았으며, 설치본이 개명을 언제 전파하는지 확인이 필요하다.
