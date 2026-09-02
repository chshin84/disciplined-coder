# lens-adversarial 원본 — 계획 2026-09-03-audit-record-and-diff.md (2026-09-03)

지적 열넷. 기능 추가 제안 없음.

```json
{
  "lens": "adversarial",
  "issues": [
    {"where": "Task 6 record() sealList / 요약문 record 호출, Task 7·9·12의 뿌리 붙이기", "type": "failure-mode", "claim": "마지막 기록 걸음이 요약문을 봉인 목록에 넣어 읽기 전용으로 만든 뒤 회차가 끝난다.", "consequence": "실행 세션이 요약문에 뿌리와 물음을 붙일 수 없다. 세 회차가 같은 곳에서 막힌다.", "evidence": "spec 「기록을 잠그는 법」 176행"},
    {"where": "Task 6 record() completed 설정 순서", "type": "failure-mode", "claim": "completed=true를 놓고 run.json을 쓰고 봉인한 뒤에 검수가 돈다.", "consequence": "검수 불일치 회차가 끝난 회차로 남아 대조 사슬과 LATEST 앵커를 오염시키고 봉인돼 고칠 수 없다.", "evidence": "spec 310행·94행"},
    {"where": "Task 11 record('review') count 대 검수자 count 규칙", "type": "failure-mode", "claim": "일관성 원본은 pairs 길이를 넘기는데 검수자는 findings를 우선 센다.", "consequence": "이름표 묶음이 하나라도 있으면 리뷰 걸음에서 회차가 반드시 죽는다.", "evidence": "CONSISTENCY_SCHEMA required"},
    {"where": "Task 6 검수 비교 x.path === `${DIR}/${f.name}` 와 요약문 '../<round>.md'", "type": "failure-mode", "claim": "폴더 밖 경로를 '..' 그대로 문자열 동등으로 견주고 마크다운에 개수 규칙을 적용한다.", "consequence": "검수자가 경로를 정규화하거나 항목을 세면 마지막 걸음이 죽는다.", "evidence": "plan 857·863·1007행"},
    {"where": "Task 5 audit_targets.sh, Task 8, Global Constraints, 기록자 프롬프트, python -c 단언 전부", "type": "failure-mode", "claim": "인터프리터를 python으로 못 박았는데 레포에 이름을 고르는 공유 헬퍼(_json_valid.sh의 _json_python)가 있다.", "consequence": "python3만 있는 곳(CI ubuntu)에서 스크립트가 죽고 계약 실패와 인터프리터 부재를 가를 수 없다.", "evidence": "scripts/_json_valid.sh:3-12"},
    {"where": "Task 6 record('review', ...) 한 호출", "type": "risk", "claim": "렌즈 원본 아흔 개 안팎을 기록자 하나가 한 프롬프트로 옮겨 적는다.", "consequence": "하나라도 개수가 틀리면 회차가 죽고 렌즈 호출 백수십 건이 버려지며 재시도해도 같은 곳에서 죽는다.", "evidence": "plan 892·843행, spec 289-291행. 완화: 파일 하나마다 record를 나눠 부른다"},
    {"where": "Task 7·9·12의 git add docs/superpowers/reviews/ 와 '끊긴 폴더를 지우지 말라'", "type": "irreversible", "claim": "끊긴 회차 폴더가 통째 커밋되고 이력 검사(--diff-filter=MD)가 뒤의 삭제를 막는다.", "consequence": "반쪽 폴더가 레포에 쌓이고 되돌릴 길이 이력 조작뿐이다.", "evidence": "test_docs_drift.sh:559·564. 완화: 이번 회차 폴더 이름 하나만 add"},
    {"where": "Task 5 superseded 단언(mktemp -p HERE, git add -N) 과 회차의 지문 측정", "type": "failure-mode", "claim": "계약 테스트가 레포 루트와 색인을 건드리고 회차의 기계 검사가 그 테스트를 돌린다.", "consequence": "tree_clean·tree_changed가 자기 테스트 때문에 뒤집힌다. 끊기면 임시 .md와 색인 항목이 남는다.", "evidence": "plan 500·825·964행. 완화: 픽스처 폴더에서 돌린다(Task 8의 --root 선례)"},
    {"where": "Task 3 봉인 테스트 인자 없는 갈래와 seal_reviews.sh", "type": "failure-mode", "claim": "인자 없는 갈래를 레포 자신에서만 검사하고 뿌리를 바꿀 길이 없다.", "consequence": "검사가 스크립트 동작이 아니라 작업 트리 상태를 보고, 아무 파일도 처리하지 않아도 초록이다.", "evidence": "plan 299-303행. 완화: --root를 둔다"},
    {"where": "Task 7 걸음 표 교체와 Task 12", "type": "failure-mode", "claim": "spec이 더하라 한 넷 가운데 「진술을 뽑아 이름표로 모은다」와 「회차를 대조한다」가 어느 Task에도 없다.", "consequence": "절차 걸음 표가 실행체의 걸음을 모르는 채 남고 개수 단언은 통과한다.", "evidence": "spec 334-336행"},
    {"where": "Task 6 counts_by_lens unique 계산(Task 2도 같음)", "type": "failure-mode", "claim": "고유 발견 수를 f.lens === k로 세는데 중복제거는 lens를 쉼표로 이은 문자열로 돌려준다.", "consequence": "병합된 발견이 어느 렌즈에도 세어지지 않아 기여한 렌즈를 빼자고 묻게 된다.", "evidence": "DEDUP_SCHEMA lens description. 완화: split(',')로 포함 여부"},
    {"where": "Task 6 단언 '대상 문서 경로를 직접 적지 않는다'", "type": "failure-mode", "claim": "홑따옴표 경로만 금지하는데 실행체는 템플릿·겹따옴표로 적고 다른 단언은 agent-principles.md가 있기를 요구한다.", "consequence": "손으로 적은 목록이 되살아나도 초록이다.", "evidence": "plan 618·622·773행"},
    {"where": "Task 1·2의 실행체 편집과 Task 6 전면 재작성", "type": "over-engineering", "claim": "덩어리 1의 편집이 두 커밋만 살고 버려지며 ROUND 도출이 REPO의 args 타입과 부딪혀 뜻이 없고, Task 1·2를 건너뛰어도 테스트가 초록이다.", "consequence": "순서가 기계로 붙들리지 않는다.", "evidence": "self-audit.js:16 args 문자열. 단순화: 덩어리 1은 테스트만 세우고 구현을 Task 6에 모은다"},
    {"where": "Task 6 빈 sealList의 봉인 명령", "type": "failure-mode", "claim": "파일을 쓰지 않는 걸음에서 봉인 명령이 인자 없는 형태가 되어 HEAD 전체 봉인으로 뜻이 바뀐다.", "consequence": "여섯 걸음이 회차마다 레포 전체 기록을 봉인하고 어느 걸음의 봉인인지 가를 수 없다.", "evidence": "plan 844·848·868행. 완화: 목록이 비면 봉인 문장을 뺀다"}
  ],
  "principles_applied": ["FAIL-LOUD", "SSOT", "SIMPLE", "REVERSIBLE", "TDD", "EXPLICIT", "IDEMPOTENT", "MEASURE-FIRST", "FOCUSED"],
  "notes": "실측해 뺀 것 — .claude/settings.json은 로컬 설정과 부딪히지 않는다; 함수 앞 변수 대입은 뒤 단언에 남지 않는다; mktemp -p는 통한다; LATEST가 비면 뒤 단언은 FAIL로 떨어진다; 5,000은 지금 어디에도 없다. 남은 확인 — 재작성 실행체가 test_docs_drift.sh:499 STALE_NAMES 부정 단언에 걸리는지."
}
```
