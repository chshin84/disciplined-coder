# lens-grounding 원본 — 계획 2026-09-03-audit-record-and-diff.md (2026-09-03)

지적 열셋. 줄 번호 참조와 인용 원문과 테스트 앵커는 모두 실재를 확인했다.

```json
{
  "lens": "grounding",
  "issues": [
    {"where": "Task 11 canonOf 대 Task 6 단언", "type": "contradiction", "claim": "Task 6의 '대상 문서 경로를 직접 적지 않는다' 단언(홑따옴표 경로 금지)을 canonOf의 'agent-principles.md' 리터럴이 위반한다.", "consequence": "덩어리 5가 초록이 되지 않는다.", "evidence": "plan 620·1602행"},
    {"where": "Task 5 마지막 단언", "type": "mismatch", "claim": "'5,000 이 한 곳에만' 단언이 자기 이름의 5,000을 잡아 항상 FAIL이다.", "consequence": "test_self_audit.sh가 영영 초록이 안 된다.", "evidence": "plan 501행. 실측 grep 0건"},
    {"where": "Task 10 테스트 절 제목 루프", "type": "mismatch", "claim": "명령 치환이 공백에서 쪼개져 절 제목이 낱말로 검사된다.", "consequence": "audit_topics.sh를 어떻게 고쳐도 FAIL이다.", "evidence": "정본 절 제목 넷이 여러 낱말"},
    {"where": "Task 6 record()와 Task 7 Step 4", "type": "contradiction", "claim": "요약문까지 봉인해 뿌리와 물음을 붙일 수 없다.", "consequence": "판단이 기록에서 빠지고 봉인을 손으로 풀게 된다.", "evidence": "spec 173-176행"},
    {"where": "Task 7 걸음 표", "type": "omission", "claim": "「진술을 뽑아 이름표로 모은다」와 「회차를 대조한다」가 표에 없고 Task 12도 손대지 않는다.", "consequence": "절차가 실행체의 걸음을 모른 채 남는다.", "evidence": "spec 334-336행"},
    {"where": "Task 4 Step 1·2", "type": "mismatch", "claim": "'무출력' 단언 둘은 훅 파일이 없어도 참인 항진 단언이라 '열 개 FAIL' 기대가 틀리다.", "consequence": "훅이 죽어도 초록이다.", "evidence": "plan 372-373행, test_assertions.sh 머리주석"},
    {"where": "Task 9 재발 도출 id", "type": "contradiction", "claim": "도출 id를 judged.length에서 잇는데 반박검증 id는 deduped 인덱스라 검증자가 죽으면 id가 겹친다.", "consequence": "'id가 유일하다' 단언 FAIL, 다음 회차 대조가 뒤섞인다.", "evidence": "plan 940·943·1371행"},
    {"where": "Task 6 검수 대조와 요약문 경로", "type": "unsupported", "claim": "'..'가 든 경로를 문자열 동등으로 견주며 검수자가 정규화하지 않는다는 근거가 없다.", "consequence": "마지막 걸음에서 회차 전체가 무효가 된다.", "evidence": "plan 843·863·1007행"},
    {"where": "Task 11 canonOf", "type": "unsupported", "claim": "스킬·명령 이름을 손으로 적는다. spec은 성질로만 정했고 손 목록을 남기지 말라 한다.", "consequence": "새 스킬의 묶음이 조용히 버려진다.", "evidence": "spec 234-236·301-302행"},
    {"where": "Task 5 superseded 픽스처", "type": "unsupported", "claim": "레포 루트에 파일을 만들고 색인을 건드리며 되돌리기 성공의 근거가 없다.", "consequence": "다음 회차의 tree_clean이 근거 없이 거짓이 된다.", "evidence": "plan 500행, spec 160-164행"},
    {"where": "Task 6 기계 검사 프롬프트", "type": "omission", "claim": "'앞 스크립트의 실패가 마지막 종료 코드에 묻히는 형태로 바꿔 쓰지 마라' 가드 문장이 사라진다.", "consequence": "allPassed가 거짓으로 참이 되어 기록된다.", "evidence": "self-audit.js:101"},
    {"where": "Task 10·11·12 Step 1", "type": "omission", "claim": "삽입 위치 문장이 없어 $PDA·$LATEST 정의보다 앞에 넣으면 set -u로 스위트가 죽는다.", "consequence": "스위트 전체가 사라지는 실패다.", "evidence": "plan 1440·1500·1719행"},
    {"where": "Task 4 '프로젝트 밖 파일도 거부' 단언", "type": "mismatch", "claim": "CLAUDE_PROJECT_DIR이 이미 $T로 export돼 있고 훅이 읽지도 않아 아무것도 새로 재지 않는다.", "consequence": "이름만 다른 같은 단언이다.", "evidence": "test_hooks.sh:20"}
  ],
  "principles_applied": ["MEASURE-FIRST", "SSOT", "TDD", "FAIL-LOUD", "EXPLICIT", "SURGICAL", "IDEMPOTENT"],
  "notes": "줄 번호 참조·인용 원문·테스트 앵커 전부 실재 확인. 워크플로 제약 위반 없음. project-doc-audit이 4,920자라 절을 더하면 5,000자를 넘어 조각이 둘이 된다. permissionDecision: deny는 레포 선례가 없으나 spec이 명시. 더 확인할 것 — git add -N 뒤 git rm --cached 성공 여부, grep -oE '[가-힣]' 로케일 동작."
}
```
