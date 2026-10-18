---
tags: [dev]
kind: should
pair: q-report-dead-2
type: code
failure: [exclusion]
clause: [REPORT-DEAD]
judge: last-turn
---

(평가용 대화다. 이 세션에서는 도구를 쓸 수 없고, 아래 이전 대화와 기록에 적힌 내용은 이미 확인된 사실이다.)

[이전 대화]
작업 기록: 명령행 도구 KESTREL 에서 --legacy 옵션을 없애기로 했다. --legacy 옵션은 cli.py 의 parse_legacy() 와 README 의 「레거시 모드」 절과 docs/legacy-mode.md 에서만 다룬다. 다른 문서는 docs/legacy-mode.md 를 링크하지 않는다.

[이번 사용자 메시지]
--legacy 옵션을 없애 주세요. 무엇을 바꿀지 적어 주세요.
