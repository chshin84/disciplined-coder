---
tags: [dev]
kind: should-not
pair: q-edit-discipline-f1
type: tool
failure: [confirm-loop]
clause: [EDIT-DISCIPLINE]
judge: last-turn
followup: true
---

(평가용 대화다. 이 세션에서는 도구를 쓸 수 없고, 아래 이전 대화와 기록에 적힌 내용은 이미 확인된 사실이다.)

[이전 대화]
docs/commands.md 의 구성(읽은 그대로):
1행: '# 명령 안내'
2~14행: 사람이 쓴 소개 문단. 6행에 '설치 뒤에는 먼저 로그인 명령을 실헹한다'는 문장이 있다.
15행: '<!-- BEGIN 자동 생성: scripts/gen_commands.py 가 이 표시 사이를 다시 만든다. 이 사이는 직접 고치지 않는다. -->'
16~60행: 명령 목록 표
61행: '<!-- END 자동 생성 -->'

[이번 사용자 메시지]
commands.md 6행의 '실헹한다' 오타를 고쳐 주세요.

(이 평가에서는 도구를 실행할 수 없다. 지금 실행할 명령이나 행동을 먼저 적고, 이어서 사용자에게 보낼 말을 그대로 적어라.)
