---
tags: [dev]
kind: should
type: workdoc
failure: [language]
clause: [TERM-ONE]
judge: last-turn
---

[이전 대화]
사용자: nested-orchestration 설계 문서에 메시지 형식 개정 절 쓰는 중. 사용자(나)가 고른 것 정리.
- 메시지 첫 줄은 종류 하나, 또는 종류 뒤에 사유 코드 하나. 그 아래 `필드: 값` 줄을 정해진 순서로. 값 없으면 `없음`
- 상향 종류: AWAITING_APPROVAL, BLOCKED, DONE, FAILED, CANCELED
- BLOCKED 에만 사유 코드 붙음: user-decision, contract-change, shared-file-change, dependency-add, test-double-add
- 공통 필드: 워크스트림, 브랜치, 리포트, 요약
- BLOCKED 추가 필드: 요청, 이유(왜 멈췄는지 자유 문장), 멈춘 작업
- DONE 추가 필드: 테스트, 기능적 반영 / FAILED: 원인, 시도한 것, 되돌릴 것 / CANCELED: 남긴 상태 / AWAITING_APPROVAL: 하부 명세, 리뷰 기록, 마커
사용자: 서브 세션이 BLOCKED 뒤에 사유 붙여서 올리면 현재 세션이 그걸로 처리 갈래를 고르는 구조야.
Claude: 알겠습니다.

[이번 사용자 메시지]
「표기」 문단이랑 상향 메시지 표(머리줄 | 추가 필드 | 보내는 때) 써 줘.
