# lens-grounding — 1회차 원본

대상: `docs/superpowers/specs/2026-09-01-second-compression-pass-design.md`
`principles_applied`: MEASURE-FIRST, SSOT, EXPLICIT, NAME-ITEMS, FAIL-LOUD, PLAIN-KO, CLEAR-COMM

## 이슈 열둘

1. **mismatch — 단위** 표가 값을 '자'로 적었으나 실제로 잰 것은 바이트다. `wc -c`로만 123,503이 재현되고, README '2,555자'의 실제 글자 수는 1,597자다. 큰 문서 셋도 바이트이며 글자로는 7,510 / 7,261 / 7,399다.
2. **mismatch — 기준선** '163,677'이 실측과 어긋난다. `2f64d74^`에서 같은 파일 집합은 163,729바이트다.
3. **mismatch — 검사 범위** 검사는 `git ls-files '*.md'`만 훑지 않는다. `^docs/superpowers/`와 `^skills/writing-korean/SKILL.md`를 두 번 걸러 낸 뒤라, 추적되는 .md 127개 가운데 18개만 훑는다. 이 설계 문서 자신도 대상 밖이다.
4. **contradiction — 49개의 분포** 49개 가운데 주석은 35개뿐이고 나머지 14개는 check 라벨·printf·픽스처 문자열에 있다. 「주석만 손댄다」로는 못 없앤다.
5. **contradiction — 목표와 금지** 「금지 표현을 셸까지 넓힌다」와 「검사 스크립트의 로직은 바꾸지 않는다」가 부딪힌다. 대상 집합을 정하는 코드가 그 스크립트 안에 있다.
6. **unsupported — 스물하나** 범위를 안 밝혀 재현되지 않는다. `scripts/*.sh` 줄 수로만 21이고, 살아 있는 파일 전체로는 30줄에서 1줄로 줄었다.
7. **omission — 남은 비유 표현** `.claude/measure_yield.sh:7`에 `재지`가 남아 있고, 표의 세는 범위에서 `.claude/` 아래가 통째로 빠졌다.
8. **omission — 검사가 붙든 모순** lens-readability의 모순은 양쪽을 검사가 요구한다(`test_docs_drift.sh:60`과 `:430`). 한쪽을 지우면 검사가 실패한다.
9. **unsupported — 쉰여덟** 확인하지 못했다. 같은 커밋이 단언을 스무 줄 넘게 더했으므로 순증감과 총 제거 수가 구별되지 않는다.
10. **mismatch — 이름 없는 개수** 「렌즈는 여섯으로 고정한다」와 「여섯이」가 이름 없이 개수를 산문에 박은 것이다. 이 문서가 검사 범위 밖이라 조용히 통과한다.
11. **omission — 회차 식별자** '첫째 회차'가 무엇인지 가리키는 커밋·경로·날짜가 없다.
12. **contradiction — 표 머리** `| 잰 것 | 값 |`이 금지 표현 `재다` 계열을 쓴다.

## notes
훑은 각도 넷을 따로 돌렸다. 실측과 일치한 것 — 셸·훅 낱말 넷(35·11·2·1), 렌즈 여섯, 검사 ALL PASS(PASS=630 FAIL=0), 지워진 문서 하나, 개명한 디렉터리 여섯이다. 더 확인할 것 둘 — `2f64d74^`를 체크아웃해 검사를 돌려야 '쉰여덟'이 판정되고, `claude plugin validate`는 CLI 실행이 필요해 확인하지 않았다.
