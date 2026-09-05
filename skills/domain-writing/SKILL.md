---
name: domain-writing
description: 문서를 쓰는 법이다. 분량과 수정 범위와 완료 판정, 문서 일반의 작성 규칙, README의 동선, 글 유형별 양식을 담는다. 세션에서 파일을 처음 건드리려 하면 훅이 이 스킬을 열라고 알린다. 쓴 뒤의 처리(타입·수명·수정 규율·검진)는 domain-doc-upkeep이, 한국어 문장 규칙은 domain-korean이 소유한다.
---
# domain-writing — 문서를 쓰는 법

Adapted from `andrej-karpathy-skills` 1.0.0. Think Before Acting lives in the canon.

These sections are rewritten for documents, so they are kept here rather than pointed at. `domain-coding` points at the plugin instead, because upstream already carries the code wording verbatim and there is no document version to point at.

## Simplicity First

The minimum document that solves the problem. Nothing speculative.
- No sections beyond what was asked.
- No templates or generalizations for a single-use document.
- No "flexibility" the reader did not ask for.
- If you write 200 lines and it could be 50, rewrite it.

## Surgical Changes

Touch only what the request needs. Clean up only your own mess.
- Don't "improve" adjacent paragraphs, wording, or formatting.
- Match the existing style, even if you'd write it differently.
- Remove sections and links that your change orphaned.
- Leave pre-existing dead text in place and mention it.

## Goal-Driven Execution

Define what the reader must be able to do after reading. Check the draft against that before calling the document done.

## 규칙 (문서 일반)
- **ID 참조** — 순서가 없는 항목에 번호(A/B/C, 1·2·3)를 매기지 않는다. 번호는 거짓 우선순위를 암시하므로 안정적 ID와 무순서 용어집을 쓴다(`NAME-ITEMS`).
- **문서 SSOT** — 같은 사실은 한 문서에만 둔다. 다른 문서는 참조한다. 외부 관례와 표준을 인용할 때도 본문을 베끼지 말고 핵심만 요약한 뒤 출처를 링크한다(`domain-coding`의 Single source of truth).
- **관리 블록 패턴** — 자동 생성 구간은 BEGIN/END 마커로 감싸 멱등 재생성한다. 사용자 콘텐츠는 그 바깥에 둔다.
- **문서를 두는 곳** — 항상 필요한 것은 `CLAUDE.md`에 두고 `@import`로 싣는다. 필요할 때만 여는 것은 스킬로 만들고, 특정 경로에서만 걸리는 것은 rules에 둔다.
- **ID의 설명 의무** — ID만 던지지 말고 완결된 문장으로 충분히 설명한다(`PROSE-FORM`).
- **모호한 표현의 구체화** — 모호한 표현은 무엇이·언제·얼마나·어떤 결과인지로 바꾼다. "느리다"가 아니라 "로딩 12초"다.
- **팩트와 근거** — 의견과 사실을 구분하고, 확인 안 된 것은 단정하지 말고 가능성으로 표시하며, 주장에는 확인 가능한 근거를 붙인다.

## README (사용자용 문서)
README는 프로젝트의 첫인상이자 종종 유일한 접점이다. 보편 원칙(위 Simplicity First, `domain-coding`의 Single source of truth와 Do one thing well, `READ-FLOW`)은 이름으로 참조하고 README 고유 항목만 둔다.

- **독자가 빨리 답해야 하는 네 가지** — 이 도구가 내 문제를 푸는가, 내가 쓸 수 있는가, 누가 만들었는가, 더 배우려면 어디로 가는가다. 이 동선을 막는 것은 군더더기다.
- **독자 분리** — 사용자 설치·사용 경로와 개발자 내부 근거를 한 문서에 섞지 않는다. 후자는 별도 문서나 스킬로 뺀다.
- **권장 동선** — 순위가 아니다. 제목과 한 줄 설명 다음 핵심 셀링포인트, 무엇을 왜 하는지, 설치, 사용 예시, 주의와 한계, 더 읽기와 기여 순이다. 섹션에 번호를 매기지 않는다.
- **필요한 것만** — badge·TOC·스크린샷·changelog는 프로젝트가 실제로 필요로 할 때만 넣는다(위 Simplicity First).

출처는 [banesullivan/README](https://github.com/banesullivan/README), [awesome-readme](https://github.com/matiassingers/awesome-readme), [Make a README](https://www.makeareadme.com/), [글 잘 쓰고 싶은 개발자](https://wikidocs.net/book/20224), [좋은 README 작성법](https://insight.infograb.net/blog/2023/08/23/good-readme/)이다.

## 글 유형별 적용
- **버그 리포트** — 남이 그대로 재현할 수 있게 환경과 재현 순서와 기대와 실제의 차이를 적는다.
- **코드 리뷰** — 사람이 아니라 코드를 지적하고 이유를 함께 적는다.
- **작업 보고** — 완료한 일과 남은 일과 다음 행동의 주체를 분리해 적는다.
- **README와 기술 블로그** — 요약과 목적을 맨 앞에 두고 독자가 따라 할 수 있게 쓴다.
- **외부 공개 문서** — 작성자 맥락 없이 메인테이너가 이해할 수 있게 결론을 먼저 두고 용어를 부연한다. 게시 전에 `domain-doc-upkeep`의 「문서 검진 방법」대로 `lens-grounding`과 `lens-fit`과 `lens-readability` 검수를 거친다. 감사와 분석 노트를 그대로 덤프하지 않는다.

## Reach

Subagents do not receive this file automatically. When a subagent writes or edits a document, put this file's path in its prompt the way `dispatching-lenses`'s 「렌즈에게 정본을 알리는 법」 prescribes for the canon.
