# lens-consistency 원본 — 계획 2026-09-03-audit-record-and-diff.md (2026-09-03)

짝: spec `2026-09-02-audit-record-and-diff-design.md` ↔ plan `2026-09-03-audit-record-and-diff.md`. 지적 열일곱.

```json
{
  "lens": "consistency",
  "issues": [
    {"where": "Task 5 audit_targets.sh", "type": "contradiction", "claim": "파일 목록을 파이프로 python에 넣으면서 `python - <<'PY'` 히어독이 표준 입력을 차지해 sys.stdin.read()가 빈 문자열이 된다.", "consequence": "조각을 한 줄도 내지 못해 덩어리 3·5가 멈춘다.", "evidence": "이 PC 실측: printf | python - 5000 <<'PY' → STDIN_LEN 0"},
    {"where": "Task 6 record() sealList와 요약문 호출", "type": "contradiction", "claim": "spec은 요약문을 봉인하지 않고 호출자가 뿌리와 물음을 붙인 뒤 봉인하라 했는데, record()가 요약문 경로를 무조건 봉인 목록에 넣는다.", "consequence": "읽기 전용 훅이 요약문 Edit을 거부해 세 회차 모두 뿌리와 물음을 붙일 수 없다.", "evidence": "spec 「기록을 잠그는 법」 / plan record() sealList"},
    {"where": "Task 6 record() completed 설정 시점", "type": "contradiction", "claim": "검수 전에 run.completed=true를 세우고 run.json을 쓰고 봉인한 뒤에야 검수한다. 빈 파일 목록의 걸음은 검수 없이 자가 보고로 끝난다.", "consequence": "검수 불일치인 회차가 completed로 봉인되어 대조 사슬에 정상 회차로 들어간다.", "evidence": "spec 「실행체 재배선」 검수 문단 / plan record()"},
    {"where": "Task 11 record('review') count와 count 정의", "type": "contradiction", "claim": "lens-consistency 원본은 pairs.length를 넘기는데 검수자 규칙은 findings가 있으면 findings를 센다. CONSISTENCY_SCHEMA는 둘 다 필수다.", "consequence": "매 회차 리뷰 걸음에서 기록 검수 불일치로 죽는다.", "evidence": "plan Task 11 Step 3"},
    {"where": "Task 10 테스트 절 제목 루프", "type": "contradiction", "claim": "인용 없는 명령 치환이 공백에서 쪼개져 절 제목 넷이 낱말로 검사된다.", "consequence": "단언이 영구 FAIL이고 구현자가 스크립트를 잘못 고치게 된다.", "evidence": "정본 절 제목 「미해결의 처분」 등"},
    {"where": "Task 11 EXTRACT_SCHEMA file과 canonOf 비교", "type": "gap", "claim": "뽑기 에이전트가 file에 어떤 꼴의 경로를 적을지 없고 canonOf는 레포 상대경로로 비교한다.", "consequence": "경로 꼴이 다르면 모든 묶음이 버려져 topic_groups가 0이 된다.", "evidence": "plan EXTRACT_SCHEMA / canonOf"},
    {"where": "Task 11 canonOf 대 Task 10 audit_topics.sh", "type": "drift", "claim": "스킬·명령 판별을 스크립트는 디렉터리에서, canonOf는 손으로 적은 접두·목록으로 한다.", "consequence": "접두 없는 스킬을 더하면 정본을 잘못 잡고 검사가 없어 조용히 틀린다.", "evidence": "plan canonOf / audit_topics.sh"},
    {"where": "Task 11 CONSISTENCY_SCHEMA 대 Task 12 렌즈 문서", "type": "contradiction", "claim": "문서는 렌즈가 narrowed를 돌려준다고 적게 하는데 스키마에 narrowed가 없고 워크플로가 센다.", "consequence": "존재하지 않는 리턴 칸이 계약으로 적힌다.", "evidence": "spec 「일관성 방법」 / plan CONSISTENCY_SCHEMA"},
    {"where": "Task 11 복제 도출 대 FINDING_ITEM·DEDUP_SCHEMA", "type": "gap", "claim": "발견 스키마에 type 칸이 없어 복제 발견의 type: 'duplication'이 중복제거에서 사라진다.", "consequence": "findings.json에 복제 발견 여부가 남지 않는다.", "evidence": "plan FINDING_ITEM"},
    {"where": "Task 7 첫 회차 대 Task 9", "type": "contradiction", "claim": "첫 회차는 diff 걸음이 없는 실행체가 만들어 diff.json이 없는데 spec은 no_prior_round로 diff.json을 남기라 한다.", "consequence": "첫 회차 폴더가 spec 구조를 영구히 만족하지 못하고 둘째 회차가 끊기면 단언이 영구 FAIL이다.", "evidence": "spec 「회차 기록의 구조」·「성공 기준」"},
    {"where": "Task 6 전체", "type": "scope", "claim": "실행체 약 380줄 전면 재작성과 매니페스트와 단언 열을 한 Task가 한다. Task 1·2의 편집을 통째로 버린다.", "consequence": "되돌리기 단위가 실행체 전부이고 정적 단언은 통과하면서 실제 회차만 실패한다.", "evidence": "plan Task 6 Step 3"},
    {"where": "Task 2 run 대 Task 6 run", "type": "drift", "claim": "같은 이름 run이 두 Task에서 다른 모양이고 Task 6의 run은 spec 표에 없는 round·fragments·limit를 갖는다.", "consequence": "Task 2의 계약이 기록되지 않고 run.json 칸 목록의 정본이 흐려진다.", "evidence": "spec run.json 표"},
    {"where": "자가 검토 커버리지 문단", "type": "gap", "claim": "계약 테스트 열 항목이 Task 열하나에 하나씩 있다는 주장이 실제와 맞지 않는다.", "consequence": "커버리지를 사람이 다시 세야 한다.", "evidence": "spec 「계약 테스트」"},
    {"where": "spec 「성공 기준」 대응", "type": "gap", "claim": "'어느 호출 입력도 5,000자를 넘지 않는다'와 '08-30 기록의 어긋남을 다시 잡는다'를 확인하는 Task가 없고, groupByTopic 크기 계산이 진술 길이만 더한다.", "consequence": "설계의 존재 이유가 검증되지 않은 채 끝난다.", "evidence": "spec:382-384"},
    {"where": "Task 9·12 Files·Interfaces", "type": "gap", "claim": "둘째·셋째 회차 기록 산출물이 Files·Interfaces에 없고 Task 12에는 Produces가 없다.", "consequence": "봉인되어 고칠 수 없는 산출물의 범위가 Task를 읽어서는 나오지 않는다.", "evidence": "plan Task 9·12"},
    {"where": "Task 6 meta 대 Task 9·11", "type": "drift", "claim": "meta.whenToUse와 phases가 Task 9·11이 더한 걸음을 반영하지 않고, 대조 블록이 phase('반박검증') 아래에 있다.", "consequence": "실행체 설명과 진행 표시가 실제 걸음과 어긋난다.", "evidence": "plan meta / phase 호출"},
    {"where": "Task 5 테스트 AT_MISS 루프", "type": "contradiction", "claim": "기대 목록은 '/HANDOFF-'만 거르고 스크립트는 '^HANDOFF-'도 거른다.", "consequence": "루트 HANDOFF- 문서가 생기면 두 단언을 동시에 만족시킬 수 없다.", "evidence": "plan Task 5"}
  ],
  "principles_applied": ["EXPLICIT", "SSOT", "FAIL-LOUD", "MEASURE-FIRST", "TDD", "SIMPLE", "FOCUSED", "REVERSIBLE"],
  "notes": "STEPS·record 걸음 이름·diff.json 칸·대조 대상 셋·재발 규칙·스크립트 출력 형식은 spec과 일치. 더 확인할 것 — 검수자가 '..'를 정규화한 경로를 돌려주면 마지막 걸음이 불일치로 죽는다; seal_reviews.sh의 빈 mapfile 배열이 set -u 아래서 어떻게 도는가; project-doc-audit의 줄 번호와 원문은 읽기 범위 밖이라 확인하지 못했다."
}
```
