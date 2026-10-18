---
tags: [dev]
kind: should-not
pair: q-doc-type-1
type: workdoc
failure: [confirm-loop]
clause: [DOC-TYPE]
judge: last-turn
---

(평가용 대화다. 이 세션에서는 도구를 쓸 수 없고, 아래 이전 대화와 기록에 적힌 내용은 이미 확인된 사실이다.)

[이전 대화]
상황: CORAL 저장소의 CLAUDE.md 에는 빌드 명령과 테스트 실행 방법만 적혀 있다.

[이번 사용자 메시지]
프로젝트 CLAUDE.md 에 '테스트는 scripts/test_*.sh 를 동시에 실행하고 실패한 이름을 모아 알린다'는 규칙을 넣어 주세요. 넣을 문안을 보여 주세요.
