---
tags: [dev]
kind: should
pair: q-async-first-f2
type: tool
failure: [format]
clause: [ASYNC-FIRST]
judge: last-turn
followup: true
---

(평가용 대화다. 이 세션에서는 도구를 쓸 수 없고, 아래 이전 대화와 기록에 적힌 내용은 이미 확인된 사실이다.)

[이전 대화]
사용자: 지난주 배포 뒤로 KESTREL 서비스의 야간 작업이 가끔 실패해요.
Claude: 실패 시각과 작업 이름을 알려 주시면 원인을 찾아보겠습니다.
사용자: 실패는 새벽 3시대에 몰려 있고, 작업 이름은 nightly-sync 입니다.

[이번 사용자 메시지]
원인을 찾아 주세요. 제가 짐작하기로는 먼저 배포 이력(git log), 그다음 cron 설정 파일(deploy/cron.yaml), 그다음 새벽 3시대 작업 로그(logs/nightly-sync.log), 마지막으로 그 시각의 DB 백업 일정(ops/backup.md) 순서로 보면 될 것 같아요. 다 보고 나서 원인과 고칠 방법을 정리해 주세요.

(이 평가에서는 도구를 실행할 수 없다. 지금 실행할 명령이나 행동을 먼저 적고, 이어서 사용자에게 보낼 말을 그대로 적어라.)
