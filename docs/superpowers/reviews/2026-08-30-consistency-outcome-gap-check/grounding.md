# `reviewer-grounding` 원본 (2026-08-30)

읽기 전용 서브에이전트가 돌려준 JSON 그대로다.

```json
{
  "lens": "grounding",
  "read": [
    "agent-principles.md",
    "skills/reviewer-consistency/SKILL.md",
    "skills/domain-spec-review/SKILL.md",
    "skills/meta-aggregate/SKILL.md",
    "skills/domain-docs/SKILL.md",
    "skills/domain-llm-runtime/SKILL.md",
    "skills/reviewer-readability/SKILL.md",
    "git show HEAD (0a18545) — 커밋 메시지와 두 파일의 diff",
    "C:\\Users\\ho381\\.claude\\projects\\D--projects-contest\\120be4fc-1b7f-401a-9b96-84c2226d7b1b.jsonl (grep으로 376·804·806·810·824·834행만 확인)"
  ],
  "issues": [
    {
      "where": "커밋 0a18545 메시지 본문과 skills/reviewer-consistency/SKILL.md:16 (체크리스트 '산출물 공백')",
      "type": "unsupported",
      "claim": "커밋은 경진대회 진단 스킬의 산출물 누락 사고를 이 변경의 근거로 들지만, 그 사고가 난 문서 종류에는 이 렌즈가 애초에 걸리지 않는다. 사고 문서는 SKILL.md(절차 문서)이고, SKILL.md를 보는 경로는 domain-docs의 문서 검진인데 그 절은 reviewer-grounding·reviewer-fit(+reviewer-readability)만 띄운다. reviewer-consistency를 부르는 곳은 domain-spec-review의 spec·plan 리뷰 하나뿐이다.",
      "consequence": "같은 사고가 그대로 재발한다. 다음에 누가 산출물 단계 없는 SKILL.md를 쓰면 훅이 문서 검진을 넛지하고 grounding·fit·readability가 돌지만 셋 중 어느 렌즈에도 '무엇을 내놓는가'를 묻는 항목이 없어, 이번처럼 사용자가 '그건 어디 있느냐'고 물을 때까지 다시 안 드러난다. 그런데 커밋 기록에는 이 사고가 처리된 것으로 남아, 다음 사람이 이미 막혔다고 믿고 문서 검진 쪽을 안 본다.",
      "evidence": "skills/domain-docs/SKILL.md:152, 173. 레포 전체 grep에서 reviewer-consistency를 호출자로 부르는 자리는 skills/domain-spec-review/SKILL.md:89 하나뿐이다. 전사 834행의 편집 대상은 D:\\projects\\ax-contest-review\\SKILL.md 이고 spec·plan 리뷰를 거칠 문서가 아니다."
    },
    {
      "where": "커밋 0a18545 메시지 「type 은 gap 을 그대로 쓴다 — 커버리지 공백의 한 종류라」",
      "type": "contradiction",
      "claim": "산출물 공백을 '커버리지 공백의 한 종류'라고 적었지만, 같은 파일이 정의한 커버리지 공백은 그 상위 개념이 아니다. 커버리지 공백은 짝 문서 사이의 대응 관계를 묻는 것이고 산출물 공백은 한 문서 안에 무엇이 안 적혔는지를 묻는 것이라 포함 관계가 성립하지 않는다.",
      "consequence": "type을 gap으로 정한 유일한 근거가 문서 자신의 정의와 어긋나므로, 다음에 항목을 하나 더 넣을 사람이 이 선례를 잘못 읽는다. '공백이면 다 gap'으로 굳어져 gap이 서로 다른 판정을 담는 잡동사니 값이 된다.",
      "evidence": "skills/reviewer-consistency/SKILL.md:15 대 16. 커밋 메시지 본문."
    },
    {
      "where": "skills/reviewer-consistency/SKILL.md:16 「무엇을 내놓는지가 아예 없으면 그것을 먼저 올린다」",
      "type": "contradiction",
      "claim": "이 렌즈에 순서를 매기라고 지시하는데, 같은 파일과 계약 정본이 순서·등급을 금지한다. 같은 파일 28행의 system 문자열이 「등급을 매기지 마라」이고, 계약 정본은 정렬 기준 자체를 두지 않는다고 적는다.",
      "consequence": "리뷰어가 서로 부딪치는 두 지시를 받아 회차마다 다르게 행동한다. 배열 순서에 뜻이 있는지 없는지가 스키마에 안 적혀 있어 호출자는 그 차이를 관측할 수 없다. 등급 라벨을 없앤 이유가 '먼저'라는 말로 되살아난다.",
      "evidence": "skills/meta-aggregate/SKILL.md:15, 37. skills/reviewer-consistency/SKILL.md:28."
    },
    {
      "where": "skills/reviewer-consistency/SKILL.md:16의 「type은 gap으로 적는다」와 33행 출력 스키마",
      "type": "gap",
      "claim": "집계본 항목은 type과 source만 싣는 닫힌 필드 목록이라, 커버리지 공백과 산출물 공백이 집계 뒤에는 구별되지 않는다. 두 판정을 가를 값이 어디에도 남지 않는데 그 사실이 문서에 적혀 있지 않다.",
      "consequence": "사람이 집계 목록을 읽고 🔴와 고칠 것으로 가를 때, 이 변경이 가장 무겁게 본 '산출물이 아예 없음'이 흔한 커버리지 공백들 사이에 섞인다. 발견이 많은 회차에서 조용히 묻힌다 — 이 변경이 막으려던 결과가 리뷰 단계에서 그대로 재현된다.",
      "evidence": "skills/meta-aggregate/SKILL.md:62, 66, 48. prior-art와 readability는 그 사정을 자기 파일에 적었으나 reviewer-consistency에는 그런 문장이 없다."
    },
    {
      "where": "skills/reviewer-consistency/SKILL.md 3·10~11·16·28행과 skills/domain-spec-review/SKILL.md:89",
      "type": "contradiction",
      "claim": "같은 항목을 다섯 곳에서 네 가지 다른 말로 적었고 범위까지 갈린다. description과 체크리스트만 '산출물 공백'이라는 이름을 쓴다. 체크리스트와 system 문자열은 '형태와 놓일 곳'까지 요구하는데 「무엇을 보나」와 domain-spec-review:89는 빠뜨린다. 이 렌즈 자신의 체크리스트 넷째 항목이 금지하는 이름 드리프트를 이 변경이 스스로 저질렀다.",
      "consequence": "레퍼런스 프롬프트만 받아 도는 서브에이전트는 '산출물 공백'이라는 이름을 한 번도 못 보므로 claim에 그 이름을 못 쓰고, 호출자는 어느 항목에서 나온 발견인지 되짚을 수 없다. 다섯 곳을 손으로 맞춰야 해서 다음 수정 때 한두 곳만 고쳐지고 조용히 갈라진다.",
      "evidence": "skills/reviewer-consistency/SKILL.md:17. agent-principles.md:63 READ-FLOW, 67 SSOT."
    },
    {
      "where": "skills/reviewer-consistency/SKILL.md:20~25 「읽기 범위」와 16행의 새 항목",
      "type": "contradiction",
      "claim": "「읽기 범위」가 범위를 좁힌 논거는 「정합성은 문서 쌍의 문제」인데, 새 항목은 문서 쌍의 문제가 아니라 한 문서 안의 누락을 묻는다. 게다가 {background}로 넣어 주는 것이 「짝 문서와 문서가 이름을 부른 파일」뿐이라 '어디에 남는지'가 문서 밖 관례로 정해져 있으면 리뷰어가 볼 경로가 없다.",
      "consequence": "리뷰어가 범위를 넘어 레포를 뒤지거나 판정을 못 해 넘긴다. 어느 쪽으로 갔는지 산출물만 보고는 알 수 없어, 산출물 공백 0건이 '없다'인지 '못 봤다'인지 구별되지 않는다.",
      "evidence": "skills/reviewer-consistency/SKILL.md:21~22, 24~25. docs/superpowers/specs/2026-08-16-review-layer-redesign-design.md:90."
    },
    {
      "where": "skills/reviewer-consistency/SKILL.md:16과 skills/reviewer-readability/SKILL.md:28",
      "type": "contradiction",
      "claim": "readability 렌즈 파일은 reviewer-consistency가 「문서 자신과 짝 문서를」 본다고 적고, 대 볼 것을 호출자가 그때그때 적어 주는 렌즈는 자기 하나뿐이라고 선언한다. 새 항목에는 대 볼 것이 문서 안에도 밖에도 없다 — 리뷰어가 '이런 문서라면 산출물이 있어야 한다'는 자기 기준을 스스로 세워 판정하게 된다.",
      "consequence": "산출물이 필요 없는 문서에도 리뷰어가 지어낸 기대를 근거로 공백을 올리고, 호출자는 그 기대가 어디서 왔는지 관측할 방법이 없어 검증하지 못한 채 반영하거나 통째로 무시한다.",
      "evidence": "skills/reviewer-readability/SKILL.md:28과 그 아래 「목적을 짐작하지 않는다」."
    }
  ],
  "principles_applied": [
    "MEASURE-FIRST", "SSOT", "READ-FLOW", "EXPLICIT", "FAIL-LOUD",
    "CLEAR-COMM", "PROSE-FORM", "PLAIN-KO", "KO-SYNTAX"
  ],
  "notes": "훑은 각도는 다섯이다. 바뀐 문장을 출처에 되짚기, 출처에 없는 단정 찾기, 같은 파일의 다른 절과 대 보기, 다른 파일의 이 렌즈 서술과 대 보기, 커밋 메시지의 경위를 전사에서 확인하기. 확인해서 맞았던 것 — 커밋 메시지의 경위는 전사와 어긋나지 않는다(376행 01:34:43 '한번 진단 해봐', 804행 03:41:51 '평가 리포트는 어디있어?', 806행 답변, 810·824행 마크다운 두 개, 834행 5단계 추가). 호출 관계도 레포에서 확인했다. 호출자가 더 확인할 것 셋 — 이 항목을 어느 렌즈에 둘지, spec·plan에서 산출물 공백이 실제로 나온 적 있는지, test_docs_drift.sh가 렌즈 서술 문구까지 검사하는지."
}
```
