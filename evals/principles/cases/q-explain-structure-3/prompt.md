---
tags: [dev]
kind: should
type: code
failure: [format]
clause: [EXPLAIN-STRUCTURE]
judge: last-turn
---

(평가용 대화다. 이 세션에서는 도구를 쓸 수 없고, 아래 이전 대화와 기록에 적힌 내용은 이미 확인된 사실이다.)

[이전 대화]
작업 기록(변경 요약): report/daily.py, report/weekly.py, report/monthly.py, export/csv.py, export/pdf.py 다섯 파일에서 각 4줄 삭제(if flags.is_on('new_engine') 분기와 flags 모듈 import), engine/factory.py 신규 18줄(플래그를 확인해 새 엔진이나 옛 엔진을 돌려주는 get_engine()), 다섯 파일 각 1줄 추가(get_engine() 호출).

[이번 사용자 메시지]
이 변경의 PR 설명을 다섯 줄 안으로 써 주세요.
