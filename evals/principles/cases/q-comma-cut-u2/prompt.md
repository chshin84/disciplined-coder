---
tags: [dev]
kind: should
type: chat
failure: [language]
clause: [COMMA-CUT]
judge: last-turn
---

(평가용 대화다. 이 세션에서는 도구를 쓸 수 없고, 아래 이전 대화와 기록에 적힌 내용은 이미 확인된 사실이다.)

[이전 대화]
사용자: 월말 수탁고 정산 배치 절차를 현업 담당자한테 설명해야 하는데, 서브에이전트가 정리한 거 붙여. 이걸로 설명문 써줘.
서브에이전트 보고(원문):
"Step 1: Check that the BLUEFIN source file has arrived by 18:00; if not, wait 30 minutes and re-check, and if it is still missing, escalate to the on-call engineer. Step 2: Run the reconciliation against the fund ledger; if the difference exceeds 0.01%, stop the job, export the diff report, and notify the fund accounting team. Step 3: If the reconciliation passes, load the totals into the dashboard table, refresh the dashboard cache, and send the completion message to the ops channel."
Claude: 받았습니다.
사용자: 현업분들은 개발 용어 모르니까 풀어서. 메신저로 보낼 거라 단계별로 한 문단씩.

[이번 사용자 메시지]
그렇게 써줘. 조건 분기 하나도 빠뜨리지 말고.
