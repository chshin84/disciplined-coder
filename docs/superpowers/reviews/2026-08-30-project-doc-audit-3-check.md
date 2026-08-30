# 레포 문서 통합 감사 (2026-08-30, 3회차)

정본을 4,277자로 줄인 `795357c`와 이독성 사슬을 다시 이은 `3f91613` 뒤에 돈 회귀 감사다. 사용자가
레포 전체 점검을 요청했고, 그 요청에 `solved_problems` 잔여물 확인과 스킬·리뷰어 사이 충돌 확인과
시스템 프롬프트 점유 축소의 의미 점검이 함께 들어 있었다.

## 감사 범위와 렌즈 배정

`.claude/workflows/self-audit.js`를 한 회차로 돌려 렌즈 여덟을 병렬로 띄웠다. 렌즈 셋은
`reviewer-grounding`·`reviewer-consistency`·`reviewer-adversarial`을 그대로 적용했고, 나머지 다섯은
`SSOT` 전수 조사와 셸 코드 품질과 `PROSE-FORM` 자기준수와 `domain-plugin` 자기준수와 `domain-docs`
자기준수를 차원으로 삼았다.

**이 배정은 `project-doc-audit`의 렌즈 배정 기준을 따르지 않았다.** 그 절차는 문서마다
`reviewer-readability`·`reviewer-grounding`·`reviewer-fit`을 걸고 묶음에 `reviewer-consistency`를 한 번
걸라고 정하는데, 이 회차에는 `reviewer-readability`와 `reviewer-fit`이 아예 없었다. 대신 워크플로에
손으로 적힌 여덟이 돌았다. 이 어긋남 자체가 이번 회차의 뿌리 하나가 되었으므로 아래
「감사기가 자기 원칙을 어긴다」에 적는다.

호출자는 정본과 `project-doc-audit`과 `CLAUDE.md`와 `README`를 직접 읽어 렌즈 판정과 맞댔다.
`reviewer-prior-art`는 웹에 나가는 렌즈라 이 회차에서 쓰지 않았다.

## 기계 검사 결과

계약 테스트는 전부 통과한다. `test_codex_scaffold` 40건, `test_docs_drift` 288건, `test_hooks` 66건,
`test_scaffold` 231건으로 합계 625건이고 FAIL은 0이다. 실패한 스크립트 이름을 모아 마지막에 알리는
형태로 돌려 앞의 실패가 묻히지 않게 했다.

**초록이 곧 무결은 아니다.** `test_docs_drift.sh`는 매 회차 `grep: .../domains-index.md: No such file or
directory`를 찍으면서도 288건 전부를 PASS로 보고한다. 그 값을 대조하는 `check`가 없기 때문이다.

매 세션 실리는 지시의 크기를 함께 쟀다. 세는 법은 `LC_ALL=C.UTF-8 wc -m`이고 분모는 정본과 전역
`CLAUDE.md` 둘이다. 정본이 4,394자, 전역 `CLAUDE.md`가 286자로 합계 4,680자다. 축소 전 31,040자
대비 15퍼센트다.

## 집계 — 상충과 커버리지 공백

렌즈들 사이에 판정이 반대로 갈린 짝은 없었다. 같은 곳을 여럿이 짚은 짝은 많았고, 그것이 아래
뿌리 찾기의 입력이 되었다.

커버리지 공백이 셋 있다.

- **`reviewer-readability`와 `reviewer-fit`이 이 회차에 안 돌았다.** 문서가 전달을 방해하는지와 문서에
  명시된 계약을 그 문서가 지키는지는 아무도 보지 않았다.
- **반박 검증이 회차 안에 끝나지 않았다.** 원시 발견 70건의 중복 제거 단계가 응답하지 않아, 아래
  발견 목록은 사실성·실질성 2관점 반박을 통과한 확정 목록이 아니다. 다만 뿌리로 올린 것은 호출자가
  파일을 직접 열어 인용까지 대조한 것들이다.
- **`docs/superpowers/rewrite-map/`의 1,144줄을 어느 렌즈도 대상 판정하지 못했다.** 되돌려진 영문
  재작성의 대응표인데, 「대상 아님」의 어느 항목에도 안 걸려 매 회차 대상으로 들어온다.

## 되풀이되는 뿌리

### 지운 기능이 가리키던 쪽에 안 지워졌다

**어느 문서들에서 같은 모양으로 나왔는가** — `DESIGN-NOTES` 넷, `domain-docs` 넷,
`domain-llm-runtime` 둘, `domain-spec-review` 둘, `nested-orchestration` 하나,
`.claude/workflows/self-audit.js` 다섯, `scripts/_scaffold_common.sh` 둘,
`hooks/doc_review_posttooluse.sh` 하나다.

**무엇이 그것을 낳았는가** — `795357c`가 정본을 18,299자에서 4,277자로 줄이면서 절과 원칙 ID와 기능을
없앴는데, 그것을 가리키던 문서를 함께 고치지 않았다. 없어진 이름은 넷이다. 「검증 레이어」 절과 표,
원칙 ID `NO-PRIORITY`, 스킬 `migrate-solved-log`, 파일 `domains-index.md`다. 오답노트 체계가 남긴
지시도 여기 든다.

**어디를 고치면 한꺼번에 사라지는가** — 가리키는 쪽 열둘을 고치고, "정본에 없는 절 이름과 원칙 ID를
가리키는 문서가 없다"를 기계로 재는 계약 테스트를 붙인다. `3f91613`이 이독성 사슬 하나에 붙인 검사
여섯 줄을 나머지 이름 전부로 넓히는 일이다.

증거는 아래와 같다.

- 살아 있는 문서 다섯이 정본의 「검증 레이어」 절과 표를 아홉 자리에서 가리킨다. 정본의 실제 절
  이름은 「검증 — LLM 단독 출력을 그대로 마치지 않는다」이고 표는 없다.
- `skills/domain-docs/SKILL.md:29`와 `:51`이 원칙 ID `NO-PRIORITY`를 참조한다. 정본의 원칙 열여덟에
  그 ID는 없다.
- `docs/DESIGN-NOTES.md:17`이 지워진 `skills/migrate-solved-log/SKILL.md`를 열거하고, 같은 트리가 새로
  생긴 `skills/writing-korean/SKILL.md`를 빠뜨린다.
- `.claude/workflows/self-audit.js`의 `:80`·`:82`·`:90`이 지워진 `domains-index.md`를 렌즈 셋의 검토
  대상으로 지목하고, `:84`가 사라진 「오답노트」 절을 adversarial 렌즈의 대상으로 지정하며, `:74`가
  모든 렌즈 프롬프트에 "`solved_problems.md`에 직접 쓰지 마라"를 실어 보낸다.
- `scripts/_scaffold_common.sh:13-19`의 주석 두 덩이가 존재하지 않는 상수를 설명하고,
  `hooks/doc_review_posttooluse.sh:17-22`의 주석이 코드의 `case`에 없는 경로를 선언한다.

### 검사가 실패를 삼킨다

**어느 문서들에서 같은 모양으로 나왔는가** — `scripts/test_docs_drift.sh` 셋,
`scripts/test_codex_scaffold.sh` 넷, `scripts/test_scaffold.sh` 다섯, `scripts/scaffold.sh`와
`scripts/codex-scaffold.sh` 각 하나, `hooks/spec_review_stop.sh` 하나,
`hooks/doc_format_pretooluse.sh` 하나다.

**무엇이 그것을 낳았는가** — 검사를 지울 때 껍데기를 남겼다. 제목과 픽스처와 주석은 남고 단언만
사라져, 그 자리가 무엇을 재는지 선언한 채 아무것도 재지 않는다. `|| true`가 붙은 자리에서는 대상
파일이 사라져도 초록이 유지된다.

**어디를 고치면 한꺼번에 사라지는가** — 단언이 없는 블록을 검사 스위트가 스스로 붙들게 한다. 제목을
찍고 `check`를 한 번도 안 부른 블록이 있으면 붉어지는 메타 검사를 붙이면 이 뿌리가 다시 자라지 않는다.

증거는 아래와 같다.

- `scripts/test_docs_drift.sh:371`이 지워진 `domains-index.md`를 읽고 `|| true`로 오류를 삼킨다. 그
  값(`DOM_INDEX`)을 대조하는 `check`가 없어 진단 블록만 매 회차 찍힌다.
- `scripts/test_codex_scaffold.sh`의 `:58`·`:178`·`:194`·`:202`와 `scripts/test_scaffold.sh:687`이 제목을
  찍고 픽스처를 세운 뒤 `check`를 한 번도 부르지 않는다.
- `scripts/test_scaffold.sh:32`·`:36`·`:37`·`:38`의 부정 단언 넷은 무엇을 고쳐도 통과하는 항진 검사다.
- `scripts/test_docs_drift.sh:272-276`과 `:462-468`에 계약을 선언하는 주석만 남고 그 계약을 재는
  `check`가 사라진 죽은 블록이 둘 있다.
- `scripts/scaffold.sh:20`·`:115`와 `scripts/codex-scaffold.sh:17`·`:77`의 보고 절이 채워지지 않는
  변수를 읽어 영원히 침묵하고, `commands/setup-discipline.md:13`은 그 스크립트가 결코 내보내지 않는
  '새로 생성된 파일' 보고를 요구한다.
- `hooks/spec_review_stop.sh:54`가 빈 배열 보호를 한 줄에만 걸어, bash 3.2에서 하드 게이트가 조용히
  열린다.

### 사람이 손으로 맞추는 쌍이 남아 있다

**어느 문서들에서 같은 모양으로 나왔는가** — `README.md` 넷, `docs/DESIGN-NOTES.md` 둘,
`scripts/_scaffold_common.sh`와 두 스캐폴드 다섯 자리, `hooks/hooks.json`과 `hooks/hooks-codex.json`,
훅 넷, `hooks/_spec_marker.sh`와 `hooks/spec_review_stop.sh`다.

**무엇이 그것을 낳았는가** — 한 사실을 두 곳에 권위 있게 적고 사람이 맞추기로 했다. 맞추는 걸음이
빠지면 조용히 갈라진다.

**어디를 고치면 한꺼번에 사라지는가** — 값을 코드에서 도출하게 바꾸거나, 도출이 어려우면 두 곳이
같은지를 재는 계약 테스트를 붙인다.

증거는 아래와 같다.

- `README.md:3`이 자동 계층의 프로젝트 파일 수정 예외를 "둘"이라 하고 `README.md:68`이 "하나"라 한다.
  `docs/DESIGN-NOTES.md:274`와 `:279`는 셋이다. 네 자리가 서로 다르다.
- `README.md:72`가 관리블록 잠금의 시간 상수 둘을 산문에 적어 `scripts/_managed_block.sh:81-85`·`:117`과
  손으로 맞추는 쌍을 만들었다.
- `scripts/_scaffold_common.sh:5-6`의 `SCAFFOLD_WHITELIST`가 "여기만 고친다"고 선언했으나 실제 목록은
  `scripts/scaffold.sh:23`·`:88`과 `scripts/codex-scaffold.sh:20` 등 다섯 자리에 하드코딩돼 있다.
- `hooks/hooks.json`과 `hooks/hooks-codex.json`이 배선을 통째로 이중 기술하는데
  `scripts/test_codex_scaffold.sh:113`의 패리티 검사는 이벤트 이름만 맞댄다.
- 리뷰 게이트를 끄는 환경변수의 이름과 기본값이 훅 넷에 각각 복제돼 있다.
- `hooks/_spec_marker.sh:4-5`가 스스로 '쌍 계약'이라 부르며 산문 셋을 손으로 맞추라고 지시하는데, 그
  셋 가운데 훅 안내문은 지금도 아무 검사가 붙들지 않는다.

### 감사기가 자기 원칙을 어긴다

**어느 문서들에서 같은 모양으로 나왔는가** — `.claude/workflows/self-audit.js` 전체,
`skills/project-doc-audit/SKILL.md`, `skills/reviewer-adversarial/SKILL.md`,
`skills/reviewer-prior-art/SKILL.md`다.

**무엇이 그것을 낳았는가** — 같은 일을 하는 감사가 둘로 갈라져 있고, 한쪽은 절차를 문서로 소유하고
다른 쪽은 대상 목록을 손으로 들고 있다. 배선이 빠진 걸음이라 문서 문장의 문제가 아니다.

**어디를 고치면 한꺼번에 사라지는가** — `project-doc-audit`을 절차의 정본으로 두고 `self-audit.js`를
그 절차의 실행체로 만든다. 대상은 손으로 적지 말고 파일에서 도출한다.

증거는 아래와 같다.

- `self-audit.js:76-95`·`:117-121`이 리뷰어 아닌 에이전트 여덟을 한 번에 띄운다. 정본
  `agent-principles.md:41`·`:43`은 허가 범위를 `reviewer-*`로 좁히고 "한 번에 여럿 띄우기는
  `project-doc-audit`이 도는 회차에만 허용한다"고 못 박았다.
- `self-audit.js:185-200`이 회차 기록을 `docs/superpowers/reviews/`에 남기지 않고 끝낸다. 정본
  `:50-52`는 "기록이 없으면 지적이 0건이었던 회차와 검증을 안 돌린 회차가 구별되지 않는다"고 적었다.
- `skills/reviewer-adversarial/SKILL.md:3`·`:8`이 `project-doc-audit`을 호출자로 적지만, 그 절차의 렌즈
  배정표(`:69-72`)에는 이 렌즈를 부르는 물음이 없다.
- `skills/reviewer-prior-art/SKILL.md:8`이 `project-doc-audit`을 호출자로 적지만, 그 절차는 `:84`에서
  "웹에 나가는 렌즈는 이 절차에서 쓰지 않는다"고 명시적으로 제외한다. 두 문서가 정면으로 어긋난다.
- `skills/project-doc-audit/SKILL.md:17`이 걸음을 여섯이라 적고 바로 아래 표(`:19-28`)에 일곱 줄을
  늘어놓는다. 여섯에서 멈추면 결과를 사용자에게 넘기는 마지막 걸음이 빠진다.
- `skills/reviewer-prior-art/SKILL.md:25`와 `:65-66`이 `detail` 필드에 적으라고 지시하지만 그 렌즈의
  출력 스키마에 `detail`이 없다.

## 시스템 프롬프트 점유 축소의 의미

축소 자체는 목표대로 됐다. 매 세션 실리는 것이 4,680자로 축소 전의 15퍼센트다.

**값은 참조 무결성으로 치렀다.** 위 뿌리 「지운 기능이 가리키던 쪽에 안 지워졌다」의 열두 자리가 전부
그 한 커밋에서 나왔다. 정본에서 내린 것이 받을 쪽에 안 적히거나, 받을 쪽이 없어진 이름을 계속
가리킨다.

주목할 것은 그다음 커밋 `3f91613`이 이미 그 뿌리를 이름으로 지목했다는 점이다. 커밋 메시지가 "동작을
옮기면서 받을 쪽에 안 적었다"고 적었고 계약 테스트 여섯 줄을 붙였다. 그런데 그 여섯 줄은 이독성
사슬 하나만 붙든다. 같은 뿌리의 나머지 열두 자리는 여전히 아무 검사도 안 붙들고 있다. 뿌리를
알아보고 한 사례만 고친 회차였던 셈이다.

## 사용자가 정할 물음과 그 답

이 회차에서 사용자에게 띄운 물음은 셋이고 모두 답을 받았다.

- **감사기 통합** — `project-doc-audit`이 절차의 정본으로 남고 `self-audit.js`가 그 절차를 이 레포에
  적용한 실행체가 된다. 대안이던 워크플로 폐기와 잔여물만 고치기는 기각됐다. 기각 사유는 앞은
  결정론을 잃는 것이고 뒤는 이번 감사가 그 방식의 실패를 이미 증거로 냈다는 것이다.
- **코드 차원의 자리** — 셸 품질과 플러그인 매니페스트와 `SSOT` 전수 조사는 워크플로 안에 코드
  단계로 명시한다. `project-doc-audit`의 "문서만 본다"는 경계를 지키면서, 이번 회차에서 값을 낸
  차원들을 잃지 않는다.
- **「검증 레이어」 이름** — 정본에 절 이름을 되살리지 않고 가리키는 쪽 아홉을 고친다. 정본은 줄인
  상태를 유지한다.
