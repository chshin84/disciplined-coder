---
tags: [dev]
kind: should
pair: q-doc-place-f2
type: workdoc
failure: [format]
clause: [DOC-PLACE]
judge: last-turn
followup: true
---

(평가용 대화다. 이 세션에서는 도구를 쓸 수 없고, 아래 이전 대화와 기록에 적힌 내용은 이미 확인된 사실이다.)

[이전 대화]
상황: MARLIN 저장소에는 문서 검토 스킬 doc-review 가 있다. 이 스킬은 사용자가 문서 검토를 요청할 때만 열린다. 초안 문서는 drafts/ 아래에 만든다.
사용자: 초안 파일 이름이 제각각이라 찾기 어려워요.

[이번 사용자 메시지]
'drafts/ 아래에 초안을 만들 때는 파일 이름을 날짜-주제.md 로 한다'는 규칙을 doc-review 스킬 본문에 넣으면 될 것 같아요. 그렇게 넣을 문안을 써 주세요.
