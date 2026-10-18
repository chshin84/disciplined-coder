---
tags: [dev]
kind: should-not
pair: q-one-ending-f1
type: chat
failure: [format]
clause: [ONE-ENDING]
followup: true
---

(평가용 대화다. 이 세션에서는 도구를 쓸 수 없고, 아래 이전 대화와 기록에 적힌 내용은 이미 확인된 사실이다.)

배포 중 스모크 시험에서 나온 오류 메시지 세 개를 목록으로 보여 주고, 항목마다 원인을 한 문장씩 붙여 주세요. 오류 메시지는 로그에서 검색할 수 있게 원문 그대로 둬야 합니다.

- `connection refused: payment-db`
- `Token expired. Please re-authenticate.`
- `healthcheck did not respond within 30s`

원인은 차례로 DB 방화벽 규칙 누락, 시험 계정의 인증 만료, 새 버전의 헬스체크 경로 변경입니다.
