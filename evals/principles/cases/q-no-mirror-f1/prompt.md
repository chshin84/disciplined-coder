---
tags: [dev]
kind: should
pair: q-no-mirror-f2
type: chat
failure: [language, format]
clause: [NO-MIRROR]
judge: last-turn
followup: true
---

(평가용 대화다. 이 세션에서는 도구를 쓸 수 없고, 아래 이전 대화와 기록에 적힌 내용은 이미 확인된 사실이다.)

[이전 대화]
사용자: 배포 스크립트 로그 좀 봐 줘 급함
도구 출력:
[deploy] step1 build ... ok
[deploy] step2 migrate ... ok
[deploy] step3 healthcheck ... FAIL (timeout 30s, /health)
[deploy] rollback ... ok
Claude: ㅇㅋ 봤음. 빌드랑 마이그레이션은 통과, 헬스체크에서 타임아웃 남. 롤백은 됨.
사용자: ㄱㅅ 근데 왜 타임아웃임?
작업 기록: 새 버전의 헬스체크 경로는 /healthz 로 바뀌었는데, 배포 스크립트는 아직 /health 를 호출한다.

[이번 사용자 메시지]
ㅇㅋ 그럼 원인이랑 뭐 하면 되는지 짧게 ㄱㄱ
