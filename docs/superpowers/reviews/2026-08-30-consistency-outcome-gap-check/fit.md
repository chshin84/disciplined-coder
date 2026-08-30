# `reviewer-fit` 원본 (2026-08-30)

읽기 전용 서브에이전트가 돌려준 JSON 그대로다.

```json
{
  "lens": "fit",
  "read": [
    "agent-principles.md",
    "skills/reviewer-consistency/SKILL.md",
    "skills/reviewer-grounding/SKILL.md",
    "skills/reviewer-adversarial/SKILL.md",
    "skills/reviewer-fit/SKILL.md",
    "skills/reviewer-readability/SKILL.md",
    "skills/meta-aggregate/SKILL.md",
    "skills/domain-spec-review/SKILL.md",
    "scripts/test_docs_drift.sh",
    "git show HEAD (0a18545) — 바뀐 두 파일의 diff",
    "bash scripts/test_docs_drift.sh 실행 결과 (PASS=271 FAIL=0)"
  ],
  "issues": [
    {
      "where": "skills/reviewer-consistency/SKILL.md:16 — 체크리스트 '산출물 공백' 항목",
      "type": "style",
      "claim": "한 목록 안에서 말끝이 갈렸다. 같은 체크리스트의 다른 넷은 전부 물음으로 끝난다('맞는가', '있는가', '부르는가', '쪼개야 하는가'). 새 항목만 앞의 두 문장은 물음인데 뒤가 '먼저 올린다'·'gap으로 적는다'라는 지시문으로 끝나고, 분량도 나머지 넷을 합친 것과 비슷하다.",
      "consequence": "이 목록은 레퍼런스 프롬프트가 통째로 넘기는 목록이다. 다섯 항목 가운데 하나만 '볼 것'이 아니라 '보고하는 법'까지 담게 되어, 이 프롬프트로 도는 렌즈는 넷은 관찰 축으로 읽고 이 하나만 처분 규칙이 붙은 특별 항목으로 읽는다.",
      "evidence": "agent-principles.md:62 PROSE-FORM. 대조군은 같은 파일 15·17·18줄과 reviewer-fit/SKILL.md:16-19, reviewer-grounding/SKILL.md:16-19."
    },
    {
      "where": "skills/reviewer-consistency/SKILL.md:16 — 「무엇을 내놓는지가 아예 없으면 그것을 먼저 올린다」",
      "type": "constraint",
      "claim": "발견들 사이에 순서를 매기라는 지시인데, 같은 파일의 system 프롬프트는 「등급을 매기지 마라」이고 계약 SSOT는 등급도 정렬 기준도 두지 않는다.",
      "consequence": "지켜도 실을 자리가 없고 안 지켜도 아무 신호가 없다. 집계 단계가 순서를 보존하지 않으므로 '먼저'라는 값은 집계본에서 사라진다. 반대로 렌즈가 이것을 등급으로 읽으면 계약이 금지한 우선순위를 claim이나 consequence 문장에 적게 되는데, 계약 테스트는 'severity'라는 문자열만 재므로 초록인 채 통과한다.",
      "evidence": "skills/meta-aggregate/SKILL.md:15, 37. scripts/test_docs_drift.sh:87, 93. 여섯 렌즈 가운데 발견 사이의 순서를 지시하는 체크리스트 항목은 이것 하나다."
    },
    {
      "where": "skills/reviewer-consistency/SKILL.md:16(「type은 gap으로 적는다」) 대 33줄 출력 스키마 블록",
      "type": "schema",
      "claim": "gap은 폐쇄 집합 안이라 값 자체는 맞다. 문제는 gap이 이제 'spec↔plan 커버리지 공백'과 '산출물 공백' 둘을 가리키게 됐는데 그 사실이 「출력 스키마」 절에는 한 글자도 없고, 값 배정이 체크리스트 항목 안에만 적혔다는 것이다. 여섯 렌즈 가운데 체크리스트에서 type 값을 못 박는 것은 이 항목뿐이다.",
      "consequence": "집계본에서 type이 gap인 것을 받은 호출자는 스키마 절이 알려 주는 뜻대로 'plan에 구현 작업이 빠졌다'로만 읽어, '무엇을 내놓는지가 안 적혔다'는 발견을 태스크 누락으로 잘못 분류하고 엉뚱한 자리를 고친다.",
      "evidence": "skills/reviewer-readability/SKILL.md:213이 값 배정을 스키마 절에 적어 둔다. skills/meta-aggregate/SKILL.md:20."
    },
    {
      "where": "skills/reviewer-consistency/SKILL.md:3·10-11·16·28 과 skills/domain-spec-review/SKILL.md:89",
      "type": "style",
      "claim": "새 축 하나를 다섯 자리에서 세 가지 이름으로 부른다. 나머지 네 축은 다섯 자리에서 이름이 하나다 — '스코프'는 어디서나 '스코프'이고 '이름·타입 드리프트'도 그렇다.",
      "consequence": "렌즈가 돌려준 발견을 사람이 description과 체크리스트의 '산출물 공백'과 이어 붙이지 못한다. 이 레포의 계약 테스트는 산문 문구를 앵커로 잡는 구조라, 나중에 한 자리 문구만 다듬으면 나머지 두 표현은 아무 신호 없이 옛말로 남는다.",
      "evidence": "agent-principles.md:63 READ-FLOW, 59 NAME-ITEMS. scripts/test_docs_drift.sh:10-12."
    },
    {
      "where": "skills/domain-spec-review/SKILL.md:89 — reviewer-consistency 디스패치 줄",
      "type": "style",
      "claim": "세 렌즈 줄이 나란한 목록인데 이 줄만 '와/과' 접속이 셋이고, 그 접속에 열두 음절짜리 절과 짧은 명사구 둘이 섞여 있다. 앞쪽에는 '넘어가며 생긴'이라는 관형절이 문장 가운데 끼어 있다.",
      "consequence": "KO-SYNTAX가 막는 두 형태가 한 줄에 겹쳐, 어느 축이 '찾고'에 걸리고 어느 축이 '본다'에 걸리는지 되짚어야 읽힌다. 이 목록은 어느 렌즈를 띄울지 훑어 고르는 자리라, 되짚는 순간 세 줄을 나란히 둔 값이 사라진다.",
      "evidence": "이웃 줄 88·90은 짧은 명사구만 접속한다. agent-principles.md:57 KO-SYNTAX."
    }
  ],
  "principles_applied": [
    "PROSE-FORM", "PLAIN-KO", "KO-SYNTAX", "READ-FLOW",
    "NAME-ITEMS", "SSOT", "MEASURE-FIRST", "CLEAR-COMM"
  ],
  "notes": "계약 항목마다 따로 훑었다. 가(공통 양식) — 프런트매터·H1·절 순서는 바뀐 것이 없어 양식 자체는 어긋나지 않았고, 어긋난 것은 절 안의 말끝과 이름이라 그쪽만 올렸다. 나(meta-aggregate 계약) — 필드 집합과 type 폐쇄 집합은 손대지 않았고 새 값을 만들지도 않았다. 걸린 것은 값의 뜻이 하나에서 둘로 늘었는데 스키마 절이 그대로라는 것과 '먼저 올린다'가 등급 금지와 부딪치는 것 둘이다. 다(정본 서술 규칙) — 라벨 '산출물 공백'은 명사구라 이름 규칙을 지킨다. PLAIN-KO 쪽으로는 새로 지어낸 표현이 없다. 라(계약 테스트) — 실제로 돌렸다. PASS=271 FAIL=0. 이번 변경으로 붉어지는 검사는 없다 — 위 다섯은 전부 테스트가 재지 않는 자리다. 올리지 않은 것 하나 — 「무엇을 보나」에 '그리고'가 두 번 나오는데, 이대로 두어 무엇이 어떻게 잘못되는지 구체적으로 못 적겠어서 올리지 않았다. 더 확인할 것 둘 — rewrite-map/spec-review-nested.md:88이 축을 넷으로 적어 두었으나 superseded 표시가 살아 있는지 확인이 필요하고, 다른 호출자가 축 목록을 다른 표현으로 캐시해 두었는지는 못 봤다."
}
```
