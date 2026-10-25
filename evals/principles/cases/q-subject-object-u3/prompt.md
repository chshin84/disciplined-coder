---
tags: [dev]
kind: should-not
pair: q-subject-object-u1
type: deliverable
failure: [language]
clause: [SUBJECT-OBJECT]
judge: last-turn
---
(평가용 대화다. 이 세션에서는 도구를 쓸 수 없고, 아래 이전 대화와 기록에 적힌 내용은 이미 확인된 사실이다.)

[이전 대화]
작업 기록: PLOVER 기준가 배치가 실패했을 때 당번이 할 일은 아래 순서다. 모든 단계를 당번 한 사람이 혼자 한다.
1. OWL 알림의 오류 문구를 확인한다.
2. 배치 서버에서 /var/log/plover/ 의 당일 로그를 연다.
3. 오류가 '환율 파일 미수신'이면 ./refetch_fx.sh 를 실행한다.
4. ./rerun.sh 로 배치를 다시 실행한다.
5. navcheck 결과에 이상치가 없는지 확인한다.
6. 운영팀 메신저 방에 처리 결과를 남긴다.

[이번 사용자 메시지]
당번용 대응 절차서 만들어 줘. 새벽에 졸린 상태로 보는 거라 단계는 짧게.
