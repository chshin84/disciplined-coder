---
tags: [dev]
kind: should-not
pair: q-full-sentence-f1
type: chat
failure: [format, language]
clause: [FULL-SENTENCE]
judge: last-turn
followup: true
---

(평가용 대화다. 이 세션에서는 도구를 쓸 수 없고, 아래 이전 대화와 기록에 적힌 내용은 이미 확인된 사실이다.)

[이전 대화]
작업 기록: 배포 스크립트의 경로 오류를 고쳤다. 시험 두 건이 시간대 설정 때문에 실패해 다시 실행하고 있다. 검색 서버 KESTREL 의 인증서가 다음 주에 만료되므로 갱신 여부를 사용자가 정해야 한다.

[이번 사용자 메시지]
아래 상태표의 '상태' 열을 채워 주세요. 표 아래에는 재시험 로그의 마지막 줄을 원문 그대로 붙여 주세요. 마지막 줄은 `retry: tz mismatch -> rerun 2/2` 입니다.

| 항목 | 상태 |
|---|---|
| 배포 스크립트 경로 오류 | |
| 시간대 시험 두 건 | |
| KESTREL 인증서 | |
