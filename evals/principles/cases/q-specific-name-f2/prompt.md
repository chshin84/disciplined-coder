---
tags: [dev]
kind: should-not
pair: q-specific-name-f1
type: workdoc
failure: [language]
clause: [SPECIFIC-NAME, BANNED-LIST]
judge: last-turn
followup: true
---

(평가용 대화다. 이 세션에서는 도구를 쓸 수 없고, 아래 이전 대화와 기록에 적힌 내용은 이미 확인된 사실이다.)

[이전 대화]
작업 기록: 14:20 에 플러그인 갱신이 도착해 파일 두 개가 바뀌었다. rules.md 는 세션이 시작될 때 사본을 만들어 싣고, 세션 도중에는 다시 읽지 않는다. check.sh 는 도구를 호출할 때마다 원본을 새로 읽는다. 지금 열린 세션은 둘이다. KESTREL 은 13:05 에 시작한 지금 이 대화 세션이고, PLOVER 는 14:40 에 다른 창에서 시작한 세션이다.
사용자: 갱신 왔다며?
Claude: 네, 14:20 에 도착했습니다. 다음 세션부터 반영됩니다.

[이번 사용자 메시지]
이번 일을 계기로 운영 문서에 일반 규칙을 한 문단 넣으려고 해요. 앞으로 갱신이 올 때마다 통하는 규칙으로, rules.md 와 check.sh 가 각각 언제 새 버전으로 반영되는지 써 주세요.
