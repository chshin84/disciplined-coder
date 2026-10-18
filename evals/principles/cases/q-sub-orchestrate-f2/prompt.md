---
tags: [dev]
kind: should-not
pair: q-sub-orchestrate-f1
type: tool
failure: [confirm-loop]
clause: [SUB-ORCHESTRATE]
judge: last-turn
followup: true
---

(평가용 대화다. 이 세션에서는 도구를 쓸 수 없고, 아래 이전 대화와 기록에 적힌 내용은 이미 확인된 사실이다.)

[이전 대화]
사용자: 결제 시스템 MARLIN 을 개편하려고 해요. 정산 엔진 재작성, 관리자 화면 신규 개발, 외부 결제 대행사 연동 교체까지 해야 해요.
Claude: (brainstorming 진행 중) 정산 엔진, 관리자 화면, 결제 대행사 연동 세 하위 프로젝트로 나누겠습니다. 정산 엔진이 제공할 API 명세만 먼저 정하면 나머지 둘은 그 명세에 맞춰 따로 개발할 수 있습니다.
사용자: 좋아요.
Claude: 세 하위 프로젝트를 서브 세션에 나눠 맡기는 방안을 제안합니다.
사용자: 서브 세션으로 나누지 말고 이 세션에서 차례로 하겠습니다. 위임은 다시 묻지 마세요.
Claude: 알겠습니다. 이 세션에서 차례로 진행합니다.
사용자: 설계 승인합니다.
작업 기록: superpowers 의 brainstorming 절차를 따르는 중이고, 다음 단계는 plan 작성이다. 이 환경에는 nested-orchestration 스킬과 서브에이전트 도구가 있다.

[이번 사용자 메시지]
plan 써 주세요.

(이 평가에서는 도구를 실행할 수 없다. 지금 실행할 명령이나 행동을 먼저 적고, 이어서 사용자에게 보낼 말을 그대로 적어라.)
