# 감사 기록·회차 대조 설계 — 렌즈 리뷰 기록 (2026-09-02)

검토 대상은 `docs/superpowers/specs/2026-09-02-audit-record-and-diff-design.md`(258행)다. 경로가 `specs/`
아래이므로 spec으로 판정했다. 렌즈 원본은 같은 이름 폴더의 `grounding-1.json`(13건)·`consistency-1.json`
(22건)·`adversarial-1.json`(17건)이며, **렌즈를 한 번씩만 돌렸다.**

## 선행연구 렌즈의 판정

제안하지 않았다. 이유는 셋이다 — 일관성 방법은 같은 날 `2026-09-02-consistency-lens-prior-art.md`에서
이미 선행연구를 마쳤고, 회차 기록·회차 대조·잠금 훅은 절차가 이미 하던 일을 자동화하는 것이며, 그 밖에
되는지 자체가 미지수인 부분이 없다.

## 인용 검증

세 렌즈가 근거로 든 파일과 줄을 열어 확인했다. 전부 원문과 맞았다. 그 가운데 이 회차에서 새로 실측한
것이 넷이다.

- `hooks/hooks-codex.json`의 `PreToolUse` 매처는 `apply_patch`다.
- `hooks/_extract_path.sh`는 구분자만 정규화하고 절대경로를 레포 상대경로로 바꾸지 않는다.
- `scripts/test_docs_drift.sh` 528행의 `grep -vE '^(\?\?|A ) '`는 `AM ` 상태를 거르지 못한다.
- `.claude-plugin/plugin.json`에 `workflows` 키가 없고 설치 캐시에는 `.claude/workflows/self-audit.js`가
  실려 있다. `claude plugin validate`는 `"workflows": ["./.claude/workflows/self-audit.js"]`를 받는다
  (`./` 접두가 없으면 오류).

## 합친 목록

52건을 겹침으로 묶으니 스물넷이다. 괄호 안은 렌즈와 그 렌즈 안의 번호이며, 둘 이상의 렌즈가 함께 잡은
것은 그렇게 적었다.

| 지적 | 잡은 렌즈 |
|---|---|
| 대조할 지난 회차 수가 단수와 복수로 갈려 재발 판정에 이르는 길이 없고, `derived` 발견은 다음 회차 대조 대상에서 빠지며, `diff.json` 판정 값 집합이 셋과 둘로 갈린다 | grounding 5 · consistency 1·2 · adversarial 1·2 (셋 겹침) |
| 08-30 걸음 넷의 본체(조항 ID를 렌즈 본문·레퍼런스 프롬프트·집계 계약에 잇기)가 이어지지 않고 「복제」 축만 받았다 | grounding 2 · consistency 3 (둘 겹침) |
| 걸음 표에서 중복제거·집계 걸음이 사라졌는데 `run.json`은 고유 발견 수를 요구하고, 상충과 커버리지 공백이 기록에서 사라진다 | grounding 3 · consistency 6·7 · adversarial 3 (셋 겹침) |
| 경로 기반 렌즈 배정이 절차의 "폴더로 정하지 않는다"와 어긋나고, README·CLAUDE.md가 `lens-fit`을 잃으며, `lens-adversarial`의 행방이 없다 | grounding 6·8 · consistency 4·5 (둘 겹침) |
| 08-30 걸음 셋(문서 5,000자)이 반영됐다고 적었으나 실측은 열 편이 초과하고, 절 단위로 잘라도 초과하는 절이 있으며, 이름표 묶음의 상한 규칙이 없고, 5,000자 값을 실행체에 넘기는 경로가 없다 | grounding 1 · consistency 9·10·14 (둘 겹침) |
| 판정 셋과 복제 도출을 실을 출력 칸이 없고(`type`이 닫힌 집합), 정본 관계 도출이 "상세를 넘긴 관계"를 놓치며, 산출물 공백·스코프 항목이 묶음 입력에서 판정 불가다 | grounding 9·10 · consistency 12·13 (둘 겹침) |
| Codex 배선의 매처가 `apply_patch`라 "같은 항목"이 성립하지 않고, `deny`가 Codex에서 되는지 미확인이며, 선례 훅과 "같은 틀"은 경로 추출뿐이다 | grounding 11 · consistency 16 (둘 겹침) |
| 훅 범위가 플러그인 전역이라 다른 레포의 리뷰 기록도 잠그고 스위치도 없다 | consistency 15 · adversarial 9 (둘 겹침) |
| `HEAD` 조회 명령과 절대경로 처리가 미정이라 훅이 조용히 열릴 수 있다 | adversarial 8 |
| "커밋 전 붙임"이 `AM` 상태에서 기존 작업 트리 검사를 FAIL로 만든다 | adversarial 10 |
| 마지막 걸음 한 번에 쓰는 형태가 절차의 "그때 바로 적는다"와 어긋나고, 끝까지 안 쓰면 회차 전부를 잃으며, 개수 검증 실패 뒤 반쯤 쓰인 폴더가 다음 회차에 정상 회차로 집힌다 | adversarial 4·5·14 |
| 반박검증 묶음화가 spec 자신의 토큰 위치 근거와 어긋나고 실패 반경을 넓힌다 | adversarial 11 |
| 회차 고르기를 LLM에게 맡겨 같은 폴더에서 다른 회차가 뽑힐 수 있다 | adversarial 13 |
| 발견 스키마 변경이 기록 불변 결정 때문에 지난 회차와의 대조를 영구히 끊는데 한계에 없다 | adversarial 15 |
| `run.json`을 기계로 읽는 소비자가 설계 안에 없다 | adversarial 12 |
| 커밋 해시를 적으면서 판정은 작업 트리를 본다 | adversarial 16 |
| 매니페스트 미선언만 계약 테스트가 없고, "넷 확인됐다"의 절반은 09-01 기록에 없다 | grounding 4 · adversarial 17 (둘 겹침) |
| 선행연구가 수렴한 셋(정밀도 조건·뽑기 재현율·약한 기준선)이 반영되지도 한계로 적히지도 않았다 | grounding 13 |
| 경로 규칙이 성질 규칙(`superseded`)을 완전히 덮고, 절차의 「대상」에 "개발자용 설계 근거 문서"가 남는다 | grounding 7 |
| 셸 편집도 작업 트리 검사가 커밋 전에 잡는데 spec은 커밋 뒤라고 적었다 | grounding 12 |
| 뽑기 걸음의 입력(이름표 목록 전달)과 출력 형태가 없고, 목록 밖 이름표를 지어 붙이면 개수에도 안 잡히고 묶음에서 버려진다 | consistency 8 · adversarial 6 (둘 겹침) |
| 뽑기·대조 에이전트의 null 취급이 없다 | adversarial 7 |
| "렌즈 프롬프트는 레퍼런스 프롬프트다"가 `plugin-compliance`·정본 경로 주입·새 걸음 넷의 문안에서 성립하지 않는다 | consistency 11 |
| 판정 칸 이름이 지금 실행체(`status`·`missingVotes`·`verdicts`)와 다르고, `findings.json`의 정의가 `derived`와 `rejected`를 두고 자기 안에서 어긋나며, 글롭이 비면 통과하는 계약 테스트가 있고, 요약문 이름 규칙이 절차와 다르며, README 강제 절의 전제가 참이 아니고, 다섯 덩어리가 한 되돌리기 단위로 묶여 있다 | consistency 17·18·19·20·21·22 |

## 집계 — 상충과 아무도 안 본 것

판정이 서로 어긋난 짝은 하나다. adversarial 11은 반박검증 묶음화를 빼고 발견 단위로 두라 하고, spec의
「이미 정해진 것」은 08-30 결정 "반박검증은 묶음 단위로 돈다"를 받는다. 렌즈 사이의 상충은 아니고 렌즈와
선행 결정의 상충이다.

렌즈 셋 가운데 누구도 보지 않은 것은 문체다. spec은 `lens-readability`를 걸지 않는 문서 타입이라 계획된
공백이다.

렌즈가 「더 확인할 것」으로 남긴 것 가운데 이 회차에서 확인한 것은 매니페스트 키 수용 여부와 Codex 매처와
절대경로 처리다. 확인하지 못한 것은 둘이다 — 08-30 걸음 둘(감사 3회차 발견 반영)이 실제로 반영됐는지와,
Codex 런타임이 `permissionDecision: deny`를 존중하는지다.
