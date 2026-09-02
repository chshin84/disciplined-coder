# lens-consistency 원본 — 정본·CLAUDE.md·README·스킬 열넷 묶음 (2026-09-03)

```json
{
  "lens": "consistency",
  "read": ["agent-principles.md", "CLAUDE.md", "README.md", "skills/*/SKILL.md (열넷)", "scripts/test_docs_drift.sh"],
  "issues": [
    {"where": "README.md:30", "type": "drift", "claim": "'활성 정본 보기'의 정본이 전역 폴더의 사본을 가리킨다.", "consequence": "읽는 사람이 사본을 원본으로 알고 편집하고, 그 편집은 다음 세션에 사라진다.", "evidence": "README.md:30 / agent-principles.md 「이 파일의 취급」 / commands/show-principles.md:2는 사본이라 적는다"},
    {"where": "README.md:46 대 skills/domain-docs/SKILL.md:113", "type": "contradiction", "claim": "렌즈에 넣는 경로를 README는 '정본 경로', domain-docs는 실행 맥락에 따라 레포 정본 또는 관리 디렉터리 사본이라 한다.", "consequence": "설치본 세션이 README를 따르면 렌즈가 경로를 못 연다.", "evidence": "README.md:46 / domain-docs:113"},
    {"where": "skills/project-doc-audit/SKILL.md:47,51 대 :54", "type": "drift", "claim": "한 파일 안에서 정본이 감사받는 레포의 소유자 문서와 agent-principles.md 둘을 가리킨다.", "consequence": "lens-consistency에 넘길 묶음을 잘못 고른다.", "evidence": "project-doc-audit:47,51,54"},
    {"where": "skills/domain-docs/SKILL.md:117", "type": "gap", "claim": "'그 분담은 test_docs_drift.sh가 검사한다'고 적었으나 그런 단언이 없다.", "consequence": "베낀 문서가 늘어도 테스트가 통과하는 거짓 안전.", "evidence": "test_docs_drift.sh의 단언 목록에 해당 검사 없음"},
    {"where": "skills/project-doc-audit/SKILL.md:64", "type": "drift", "claim": "존재하지 않는 이름 「더 확인할 것」을 가리킨다.", "consequence": "호출자가 그 칸을 찾다 못 찾고 미확인 사항을 묻는다.", "evidence": "여섯 렌즈의 notes는 이름 없는 문자열"},
    {"where": "skills/project-doc-audit/SKILL.md:99", "type": "contradiction", "claim": "'넘길 것 — 한 번 알리고 놓아준다'가 정본의 미해결 처분 셋과 어긋난다.", "consequence": "안 고치기로 한 발견이 어디에도 안 남는다.", "evidence": "agent-principles.md 「미해결의 처분」"},
    {"where": "skills/domain-docs/SKILL.md:74 대 agent-principles.md", "type": "contradiction", "claim": "미룬 것을 정본은 메모리에, domain-docs는 프로젝트 트래커에 두라 한다.", "consequence": "같은 항목이 두 집에 나뉜다.", "evidence": "domain-docs:74 / agent-principles.md 「미해결의 처분」"},
    {"where": "skills/project-doc-audit/SKILL.md:42 대 :58", "type": "contradiction", "claim": "전달 방해 렌즈를 모든 대상에 거는지가 한 파일 안에서 갈린다.", "consequence": "목적을 못 적은 문서가 조용히 검진에서 빠진다.", "evidence": "project-doc-audit:42,58 / lens-readability:91"},
    {"where": "skills/project-doc-audit/SKILL.md:69~75, skills/domain-spec-review/SKILL.md:101", "type": "gap", "claim": "기록에 담을 닫힌 목록에 meta-aggregate의 상충·커버리지 공백이 없다.", "consequence": "escalate 후보와 안 본 렌즈가 기록에 안 남는다.", "evidence": "project-doc-audit:69,80 / domain-spec-review:101 / meta-aggregate:16~17"},
    {"where": "skills/domain-spec-review/SKILL.md:61 대 skills/project-doc-audit/SKILL.md:60", "type": "contradiction", "claim": "한 서브에이전트에 몇 대상까지 주는지를 두 절차가 다르게 정하고 소유자를 안 밝힌다.", "consequence": "두 절차를 다 아는 세션이 어느 규칙을 따를지 못 고른다.", "evidence": "domain-spec-review:61 / project-doc-audit:60 / lens-prior-art:24"},
    {"where": "skills/nested-orchestration/SKILL.md:19,28, skills/meta-aggregate/SKILL.md:17", "type": "gap", "claim": "'리스크에 비례해 렌즈를 고른다'를 세 곳이 전제하는데 정의는 제품 런타임의 점수표뿐이다.", "consequence": "L2가 diff에 어느 렌즈를 붙일지 근거가 없고, 커버리지 공백 감지도 기준이 없다.", "evidence": "domain-llm-runtime:9~16만 정의"},
    {"where": "agent-principles.md 「검증」 대 domain-spec-review:47 · domain-llm-runtime:25", "type": "contradiction", "claim": "정본은 렌즈 디스패치를 부르는 스킬이 정한다고 하는데, 회차 수와 정본 알리는 법은 domain-docs가 소유한다.", "consequence": "회차 수를 바꾸려는 사람이 호출자만 고쳐 두 문장이 갈린다.", "evidence": "agent-principles.md 「검증」 첫 문단 / domain-docs:119"},
    {"where": "domain-spec-review:47,93 · domain-docs:97 · project-doc-audit:60,67", "type": "drift", "claim": "'회차'가 렌즈를 띄우는 횟수와 리뷰·감사의 차례 둘을 가리킨다.", "consequence": "'회차 수는 domain-docs가 정한다'를 리뷰 횟수로 읽으면 다시 리뷰 규칙과 부딪힌다.", "evidence": "각 줄 인용"},
    {"where": "CLAUDE.md:3 대 README.md:51", "type": "drift", "claim": "같은 사실을 '소유한다'와 '갖는다'로 다르게 쓴다.", "consequence": "서술어 차이에 뜻이 있는지 되짚는다.", "evidence": "CLAUDE.md:3 / README.md:51"}
  ],
  "principles_applied": ["SSOT", "EXPLICIT", "FAIL-LOUD", "MEASURE-FIRST", "NAME-ITEMS", "PLAIN-KO", "PROSE-FORM", "KO-SYNTAX"],
  "notes": "훑은 각도 다섯 — 모순, 커버리지 공백, 산출물 공백, 드리프트('정본'·'회차'·'소유한다/갖는다'), 절 제목 참조(「더 확인할 것」만 실체 없음). 지시의 '열다섯'은 실제 열넷이었다(self-audit은 .claude/workflows/self-audit.js). 더 확인할 것 — test_docs_drift.sh의 DISPATCH가 어떤 단언에도 안 쓰이고 머리말이 '두 불변식'이라며 하나만 열거한다. EXPLAIN-STRUCTURE의 상세를 소유하는 스킬이 없다(사용자가 정할 물음)."
}
```
