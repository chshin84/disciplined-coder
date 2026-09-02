# 리뷰 기록 — spec 리뷰와 Codex 제거 뒤 자기감사 (2026-09-02)

실행체는 `.claude/workflows/self-audit.js`이고 에이전트 125개가 돌았다. 대상은 커밋 `f301689` 위의
작업 트리이며, 감사가 도는 동안에도 `agent-principles.md`가 사용자 편집으로 계속 바뀌었다(mtime
22:42→23:10). 그래서 이 회차의 판정은 HEAD의 상태가 아니라 움직이는 작업 트리에 대한 것이고, 렌즈의
인용과 검증자의 읽기가 서로 다른 판본을 본 발견이 섞여 있다.

**이 기록은 메인 세션이 직접 썼다.** 실행체가 기록 걸음을 배선하지 않아 자동으로 남지 않는다. 원본은
같은 이름 폴더의 `confirmed.json`·`rejected-titles.json`·`test-and-deterministic.json`·`aggregate.md`·
`logs.txt`다.

## 감사 직전에 바뀐 것

같은 세션이 감사를 띄우기 전에 한 것이 셋이다 — 감사 기록·회차 대조 spec의 렌즈 리뷰를 마쳐 마커를
남기고 spec을 고쳤다(`2026-09-02-audit-record-and-diff-review.md`), `lens-prior-art`가 "선행연구"라는
말에 발동되게 `description`과 본문과 `domain-spec-review`의 승인 절을 고쳤다, Codex 지원을 저장소에서
지웠다(파일 일곱 삭제, 열넷 수정). 전부 미커밋이다.

## 기계 검사

| 검사 | 결과 |
|---|---|
| `test_assertions.sh` | PASS=8 FAIL=0 |
| `test_docs_drift.sh` | PASS=301 FAIL=1 — 금지 표현 "경우"가 `agent-principles.md`에 있다 |
| `test_hooks.sh` | PASS=61 FAIL=0 |
| `test_scaffold.sh` | PASS=218 FAIL=2 — `ASK-FORK`의 "질문 도구로 선택지를 띄운다"와 "답해야 할 물음인지" 문구가 정본에서 사라졌다 |
| `claude plugin validate ./` | 통과, `version` 경고 하나 |

실패 셋은 모두 사용자가 편집 중인 `agent-principles.md`에서 난다. HEAD 판본은 세 검사를 통과한다.

## 돌린 렌즈와 그 결과

렌즈 여덟이 모두 응답했고 원시 발견은 67건이다. 확정 발견을 낸 렌즈는 `clear-comm-audit` 8, `shell-audit`
6, `ssot-audit` 5, `lens-grounding` 4, `lens-consistency` 3, `lens-adversarial` 3, `plugin-compliance` 2,
`docs-compliance` 2이고 나머지 8건은 둘 이상이 함께 잡았다.

## 판정 개수

확정 41건, 기각 16건, 미판정 0건, 죽은 렌즈 없음.

## 확정 발견

번호는 `confirmed.json`의 순서다.

1. 작업 트리 정본에서 `ASK-FORK`의 질문 도구 규칙 문구가 사라져 `test_scaffold.sh`가 두 건 실패한다.
2. 정본이 자기 `PLAIN-KO` 조항이 금지하는 "경우"와 "부분"을 쓴다(8·9·16행).
3. README의 「세션에 강제하거나 고치는 것」이 PreToolUse·PostToolUse 훅 셋을 빠뜨리고 끄기 변수의 범위를 Stop 게이트 하나로 좁혀 적는다.
4. 정본이 `CLEAR-COMM`을 없애고 `EXPLAIN-STRUCTURE`를 넣었는데 `self-audit.js:26`은 여전히 `CLEAR-COMM`을 부른다.
5. README가 `/show-principles` 실패 원인을 홈 불일치로 단정하지만 두 소비자가 같은 `resolve_home`을 쓰므로 그 원인은 그 증상을 만들 수 없다.
6. README와 `domain-spec-review`가 Stop을 「하드 게이트」로 적지만 같은 스킬의 한계 절은 「턴당 한 번의 환기」라 하고 코드는 둘째 종료와 git 밖에서 조용히 통과시킨다.
7. 매니페스트가 「doc review gates」를 광고하지만 문서 검진 훅은 스스로 「게이트 아님」이라 선언한다.
8. 전문 용어 부연 횟수가 정본·`writing-korean`·`lens-readability` 사이에서 "나올 때마다"와 "처음 나올 때"로 갈리고 `writing-korean` 안에서도 두 문장이 반대다.
9. 세 호출자 스킬이 「공통 방법」을 정본 「검증」 절에서 가져온다고 적었는데 그 절은 방법을 담지 않고 호출자로 되돌려 보낸다.
10. `domain-docs`의 기록 타입 정의는 처분을 안 적는다고 하는데 같은 문서의 검진 절과 실제 검진 기록은 처분을 적는다.
11. 리뷰 기록 파일의 회차 표기가 `-review-2.md`와 `-2-check.md`로 갈리고 문서 검진에는 회차 규칙이 없다.
12. 정본은 렌즈 둘 이상 회차의 기록을 `reviews/`에 남기라 하는데 `nested-orchestration`의 실행 국면 렌즈 회차는 스크래치 리포트로만 남는다.
13. 감사 도중 작업 트리가 HEAD와 25개 파일에서 갈라졌다.
14. `self-audit.js`가 감사 대상 리비전을 고정하지 않아 렌즈와 검증자가 서로 다른 파일을 본다.
15. `_json_valid.sh`의 `json_hook_events`가 같은 일을 하는 JSON 처리기 셋을 두고 그 사본이 이미 갈라져 있다.
16. 문서 넛지 훅 둘이 프로젝트 밖의 메모리·계획 파일에도 걸린다.
17. 정본은 미룬 일을 메모리에 적으라 하고 `domain-docs`는 백로그를 추적하지 말라 해 지운 핸드오프가 메모리로 되살아난다.
18. `spec_review_stop.sh`가 spec/plan 디렉터리 목록을 술어와 별개로 pathspec에 한 번 더 손으로 적는다.
19. `domain-docs`가 frontmatter 형식의 소유자로 `domain-plugin`을 가리키지만 거기에 frontmatter 규칙이 없다.
20. README와 `CLAUDE.md`가 게이트 경로·마커·환경변수 이름을 코드에서 베껴 적고 드리프트 검사는 `domain-spec-review` 한 파일만 대조한다.
21. `self-audit.js`가 렌즈 산출물 계약을 `meta-aggregate`와 다른 스키마로 다시 정의해 `read`·`principles_applied`·`notes`가 버려진다.
22. 두 spec 훅이 같은 안내문을 각자 문자열로 갖고 드리프트 검사가 그 베끼기를 강제한다.
23. autoUpdate 규칙이 스크립트 머리말·`domain-plugin`·README 세 곳에 각각 적혀 있고 개수부터 다르다.
24. `scaffold.sh`가 프로젝트 CLAUDE.md와 전역 CLAUDE.md의 동일성을 문자열로만 비교해 작업 폴더가 `~/.claude`이면 매 세션 사본이 쌓인다.
25. `test_scaffold.sh`에 결과를 단언하지 않는 블록 넷이 남아 있고 `test_assertions.sh`가 잡지 못한다.
26. `_scaffold_common.sh`에 호출자 없는 함수와 사라진 상수의 주석이 남아 있다.
27. 파이썬 인터프리터 선택 규칙이 `_json_valid.sh`에 있는데도 테스트 셋이 각자 고르고 한 곳은 폴백 없이 `python`을 부른다.
28. `spec_review_stop.sh`가 git 명령이 어떤 이유로 실패하든 신호 없이 게이트를 연다.
29. `_resolve_home.sh`의 USERPROFILE 갈래를 어떤 테스트도 밟지 않는다.
30. 정본 원칙 목록의 괄호 이름 말끝이 문장·명사구·부사구로 갈린다.
31. 정본 「검증」 절 제목이 주장을 담는다.
32. `writing-korean`의 소제목 셋이 주장을 담는다.
33. `domain-docs` 문서 타입 표의 '담는 것' 열에 명사구와 절이 섞인다.
34. `domain-plugin` 첫 목록에 문장 라벨과 명사 라벨이 섞인다.
35. `domain-docs` 규칙 목록과 README 목록에 문장 라벨과 명사 라벨이 섞인다.
36. `lens-prior-art`와 `lens-readability`의 표 머리가 의문절이다.
37. `nested-orchestration`의 BLOCKED 목록에 라벨 없는 불릿과 라벨 있는 불릿이 섞인다.
38. `_json_valid.sh`의 주석이 "두 런타임의 배선을 대조"한다고 적지만 배선 파일은 `hooks.json` 하나뿐이다.
39. 플러그인 소개 문안이 `plugin.json`과 `marketplace.json`에 두 번 적혀 있고 같게 두라는 규칙은 테스트 주석에만 있다.
40. Codex 패리티 spec과 plan이 superseded 표시 없이 작업 트리에서 삭제되어 있다.
41. 오답노트 기능의 spec 둘과 plan 하나가 기능 제거 뒤에도 superseded 표시 없이 남아 있고 검사의 파일 이름 대조가 놓친다.

## 둘 이상의 렌즈가 함께 잡은 것

여덟이다 — README 강제 절(3), `CLEAR-COMM` 매달림(4), Stop 게이트 문구(6), 용어 부연 횟수(8), 「검증」 절
소유권(9), 기록 처분 규칙(10), JSON 처리기 사본(15), frontmatter 소유자(19), autoUpdate 규칙·매니페스트
사본(23·39).

## 상충 — 처분이 갈리는 짝

정면 상충은 한 쌍이다. 「검증」 절 제목과 `writing-korean` 소제목 셋을 명사구로 고치라는 확정 둘(31·32)이,
같은 「이름 — 설명절」 꼴을 스물한 곳의 지배적 관례로 보고 부분 수정을 거부한 기각 발견과 갈린다.

같은 자리를 다른 방향에서 고치라는 겹침은 여덟이다 — README 38~41행(3·6·20), `_json_valid.sh`(15·27·38),
매니페스트 문안(7·39), 「검증」 절(9·12·31), `domain-docs` 기록 행(10·11), `test_docs_drift.sh`의 superseded
도출(40·41), `test_scaffold.sh`와 `_scaffold_common.sh`의 껍데기(25·26), `self-audit.js`(4·14·21).

검증자끼리 증거가 갈린 것이 하나다. JSON 처리기 발견(15)에서 한 검증자는 이 PC의 `python3`가 3.12.10으로
살아 있다 했고 다른 검증자는 스토어 스텁(rc=49)이라 했다.

## 커버리지 공백

- 최종 작업 트리에 대한 판정이 없다 — 정본이 멈춘 뒤 결정론 검사 넷과 `lens-grounding`을 다시 돌려야
  이 회차의 발견이 그 판본에도 성립하는지 알 수 있다.
- 검증자 소견에만 드러나고 어느 발견에도 실리지 않은 것이 아홉이다(`aggregate.md` 「4. 커버리지 공백」).
  워크플로가 기각 발견을 제목만 남기고 검증자 소견을 버리므로 구조적으로 사라지는 부류다.
- `lens-readability`와 `lens-fit`은 이 실행체의 배정에 없어 돌지 않았다. `lens-prior-art`는 규칙에 따라
  뺐다.
- 감사 기록·회차 대조 spec과 그 리뷰 폴더는 `docs/superpowers/` 제외 규칙으로 대상이 아니었다. 집계가
  "그 spec 리뷰가 미완"이라고 적은 것은 감사 전의 메모리를 읽은 것이고, 감사가 도는 동안 같은 세션이 그
  리뷰를 마쳤다.
- 이 세션이 고친 `lens-prior-art` 57행("spec 리뷰 전용")이 새로 넣은 직접 요청 경로와 어긋난다는 지적은
  집계에만 있고 확정 목록에는 없다. 감사 뒤 같은 세션이 그 줄을 고쳤다.
