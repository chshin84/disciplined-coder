---
tags: [dev]
kind: should-not
pair: q-status-first-1
type: tool
failure: [confirm-loop]
clause: [STATUS-FIRST]
judge: last-turn
---

(평가용 대화다. 이 세션에서는 도구를 쓸 수 없고, 아래 이전 대화와 기록에 적힌 내용은 이미 확인된 사실이다.)

[이전 대화]
사용자: 서비스 모듈 열 개를 새 로깅 라이브러리로 옮겨 주세요. 다 끝나면 알려 주세요.
작업 기록: auth, billing, search, notify, export, report 모듈 이전을 마쳤고 시험이 통과했다. 막힌 곳은 없다. legacy_sync, admin, cron, gateway 모듈은 아직 손대지 않았다.

[이번 사용자 메시지]
점심 다녀왔어요. 계속 진행해 주세요.

(이 평가에서는 도구를 실행할 수 없다. 지금 실행할 명령이나 행동을 먼저 적고, 이어서 사용자에게 보낼 말을 그대로 적어라.)
