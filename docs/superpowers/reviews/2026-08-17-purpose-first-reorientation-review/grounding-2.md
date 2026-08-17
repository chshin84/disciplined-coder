```json
{
  "lens": "grounding",
  "read": [
    "skills/reviewer-grounding/SKILL.md", "agent-principles.md", "skills/meta-aggregate/SKILL.md",
    "skills/domain-docs/SKILL.md", "skills/domain-spec-review/SKILL.md", "skills/reviewer-prior-art/SKILL.md",
    "skills/nested-orchestration/SKILL.md", "README.md", "CLAUDE.md", "domains-index.md", "docs/DESIGN-NOTES.md",
    "scripts/test_docs_drift.sh", "scripts/test_scaffold.sh", "scripts/test_hooks.sh", "scripts/test_codex_scaffold.sh",
    "hooks/doc_review_posttooluse.sh", "hooks/spec_review_posttooluse.sh", "hooks/spec_review_stop.sh",
    "D:/projects/bond_strat/docs/2026-08-17-handover.md",
    "scratchpad/readability_metrics.py", "scratchpad/compare.py",
    "scratchpad/trial/im-not-ai/.claude/skills/humanize-korean/references/ai-tell-taxonomy.md",
    "scratchpad/trial/im-not-ai/.claude/skills/humanize-korean/references/quick-rules.md",
    "scratchpad/trial/im-not-ai/.claude/skills/humanize-korean/references/diagnosis-rules.md",
    "scratchpad/trial/im-not-ai/.claude/skills/humanize-korean/references/rewriting-playbook.md",
    "scratchpad/trial/korean-report-skills/plugins/korean-report/skills/korean-report-style/SKILL.md",
    "scratchpad/trial/awesome.md",
    "scratchpad/trial/runA/_workspace/2026-08-17-001/02_diagnosis.md",
    "scratchpad/trial/runA/_workspace/2026-08-17-001/00_metrics.json",
    "scratchpad/trial/runB/base.json"
  ],
  "issues": [
    {
      "where": "무엇을 왜 바꾸는가 — 'agent-principles.md는 18,938자인데'",
      "type": "mismatch",
      "claim": "18,938은 글자 수가 아니라 UTF-8 바이트 수다. 실제 글자 수는 8,952자로 문서가 적은 값의 절반 이하다.",
      "consequence": "핵심 논거가 '매 세션 이만큼을 실어 보낸다'인데 그 비용을 2.1배로 부풀려 말하게 된다. 재조율 착수 순서와 '지금 담긴 정도가 상한이다'라는 두 층 판단이 모두 이 크기 감각 위에 서 있어서, 실제로 줄일 여지를 과대평가한 채 계획이 짜인다.",
      "evidence": "wc -c = 18938(바이트). open(encoding='utf-8').read()의 len()은 8952. 한글이 UTF-8에서 3바이트라 두 값이 갈린다."
    },
    {
      "where": "무엇을 왜 바꾸는가 / 재조율 — '산문이 44줄뿐이고 나머지는 전부 불릿이다'",
      "type": "contradiction",
      "claim": "실제 분포는 산문 44, 목록 26, 빈 줄 14, 제목 10, 표 7, 인용 1이다. 산문이 가장 큰 덩어리이고 산문 아닌 58줄 가운데 불릿은 26줄뿐이다. 그 44줄에는 불릿 이음줄 13줄이 섞여 있어 독립 산문은 31줄, 불릿 덩어리는 39줄이다.",
      "consequence": "'나머지가 전부 불릿'이 어느 셈법으로도 성립하지 않는데, 이 진단이 agent-principles.md를 첫 대상으로 고른 근거이자 '불릿을 문단으로 되돌린다'는 처방의 근거다. 실제로는 표 7줄과 제목 10줄도 같은 분량대에 있어 불릿만 겨냥한 처방으로는 원인을 놓친다.",
      "evidence": "readability_metrics.py의 classify()를 돌린 결과가 Counter({'prose':44,'list':26,'blank':14,'heading':10,'table':7,'quote':1})이다(총 102줄). LIST 정규식이 줄머리만 보므로 이음줄이 prose로 분류된다."
    },
    {
      "where": "무엇을 왜 바꾸는가 — '원칙 열두 개'",
      "type": "mismatch",
      "claim": "원칙 절의 항목은 열세 개이며 환경 관례 LOCAL-FIRST까지 세면 열넷이다.",
      "consequence": "고쳐 쓸 정본의 항목 수를 틀리게 적은 채 '원칙 ID와 개수와 순서는 그대로 두고'를 성공 기준으로 삼으면, 재조율 뒤 개수를 대조할 기준값 자체가 틀려서 항목이 하나 사라져도 대조가 통과한다.",
      "evidence": "agent-principles.md 12~24줄이 원칙 불릿 열셋, 27줄이 LOCAL-FIRST다."
    },
    {
      "where": "무엇을 왜 바꾸는가 — 'reviewer-prior-art는 문장 스물여섯 개 가운데 열다섯 개가 통째로 굵어서'",
      "type": "mismatch",
      "claim": "15와 26은 서로 다른 모집단에서 나온 수라 '26개 중 15개'로 읽을 수 없다. 시제품은 굵은 조각을 코드펜스 밖 모든 줄에서 세고 문장 수는 산문 줄에서만 센다. 15개 가운데 8개는 인용 블록에, 산문 줄에 있는 것은 7개다.",
      "consequence": "'가드가 전부 굵고 그래서 어느 가드도 안 눈에 띈다'는 진단이 실제보다 두 배 이상 부풀려진다. 이 축은 재조율 착수 순서를 정하는 축이므로 순서 자체가 계량 오류 위에서 정해진다.",
      "evidence": "measure()는 visible(코드 아닌 모든 줄)에서 BOLD.findall을 돌리고 sentences는 prose_text에서만 뽑는다. reviewer-prior-art의 통굵 15개를 줄 종류별로 세면 {'quote':8,'prose':7}이다."
    },
    {
      "where": "됐다는 것을 어떻게 아나 — '굵은 글씨가 문장 열 개 중 넷을 통째로 덮은 것', '문단 여든다섯 개 중 여든이 앞과 안 이어지는 것'",
      "type": "mismatch",
      "claim": "통굵 84개 가운데 산문 줄에 있는 것은 61개이고 나머지는 표 15·목록 6·인용 2다. 분모 193은 산문에서만 센 값이므로 산문 기준 비율은 열 개 중 셋이다. 이어지지 않는 문단도 여든이 아니라 일흔아홉이다.",
      "consequence": "이 두 수는 렌즈의 합격 기준이다. 렌즈가 '열 개 중 넷'을 재현하지 못해도 사실은 정상인데 실패로 읽히고, 반대로 표 안 굵기를 산문 굵기로 오인해 잡아도 통과로 읽힌다.",
      "evidence": "핸드오버 문서를 시제품으로 재면 emphasis={'bold_spans':204,'whole_sentence_bold':84}, sentences=193, cohesion={'paragraphs':85,'opens_with_connective':2,'opens_with_deictic':4}. 통굵 84개의 줄 종류는 {'prose':61,'table':15,'list':6,'quote':2}."
    },
    {
      "where": "무엇을 왜 바꾸는가 — README 0.60 / nested-orchestration 0.65",
      "type": "unsupported",
      "claim": "두 값을 어떤 셈법으로도 재현하지 못했고, 문서가 근거로 드는 시제품에는 괄호를 세는 코드가 아예 없다. 산문만 셀 때 README 0.70·nested 0.56이고 목록까지 넣으면 둘 다 0.81이다.",
      "consequence": "괄호 밀도는 착수 순서를 정하는 세 축 중 하나다. 셈법이 적혀 있지 않고 재현도 안 되는 수로 순서를 정하면, 계획 단계에서 순서를 다시 뽑는 순간 설계가 적은 순서와 어긋나고 어느 쪽이 맞는지 판정할 근거가 없다.",
      "evidence": "readability_metrics.py의 반환 키는 emphasis·alternation·cohesion·numbering·rhythm뿐이고 파일 전체에 괄호를 세는 코드가 없다."
    },
    {
      "where": "자 — '세는 것은 여섯이다 … 여섯 다 실제로 우리 문서의 병을 하나씩 잡아냈다'",
      "type": "contradiction",
      "claim": "시제품이 실제로 세는 축과 문서가 적은 여섯이 어긋난다. 시제품은 강조·교대·이음말·번호·어미·길이를 세고, 문서가 여섯에 넣은 '목록 항목에 든 문장 수'와 '문장당 괄호 수'는 세지 않는다. 반대로 시제품이 세는 번호와 어미는 여섯에 없다.",
      "consequence": "'여섯 다 병을 하나씩 잡아냈다'가 두 축에서는 성립할 수 없다. 그 두 축은 뒤에서 착수 순서를 정하는 데 쓰이고 '남의 목록에 없는 우리 자리'의 근거로도 쓰이므로, 아직 짜지도 않은 코드가 이미 검증됐다는 전제 위에 계획이 선다.",
      "evidence": "readability_metrics.py 머리말이 '세는 축은 넷이다 — 강조·교대·이음말·번호'와 '덤으로 어미·길이'라고 적고, measure() 반환 키가 그와 일치한다."
    },
    {
      "where": "자 — '204개 대 205개, 134개 대 134개, 2개 대 2개, 35개 대 35개로 독립 재현되었다'",
      "type": "unsupported",
      "claim": "네 값 가운데 시제품 밖에서 나온 흔적이 남아 있는 것은 굵기 205 하나뿐이고, 그 205도 손으로 센 값이 아니라 im-not-ai 윤문 파이프라인이 낸 진단 문서의 수치다. 블록 134·이음말 2·번호 35는 시제품 출력 말고는 대조본이 없다.",
      "consequence": "'독립 재현'이라는 말이 세 축에서는 근거가 없고 한 축에서도 사람이 아니라 다른 도구가 센 값이다. 이 문장이 '자는 손으로 센 값과 맞으면 된다. 이미 네 축에서 독립 재현되었다'로 이어지므로, 아직 통과하지 않은 합격 기준이 이미 통과한 것으로 기록된다.",
      "evidence": "trial/runA/_workspace/2026-08-17-001/02_diagnosis.md 9줄이 '**...** 강조가 205회 등장하고 그중 99회가 표 밖 산문 줄에 있다'라고 적는다. 00_metrics.json·09_finalize.json·runB/base.json 어디에도 134·35가 나오지 않는다."
    },
    {
      "where": "자 — 네 축 열거에 '번호 붙은 제목'이 든 것",
      "type": "contradiction",
      "claim": "재현되었다는 네 축 가운데 '번호 붙은 제목'은 앞 문단이 정의한 여섯 축에 없다. 검증한 축과 싣겠다는 축이 겹치지 않는다.",
      "consequence": "여섯 축 중 실제로 대조된 것은 셋이고 목록 무게·괄호 밀도·길이 퍼짐은 대조된 적이 없다. '네 축에서 재현'이 '여섯 축 중 넷'으로 읽히면서 검증 범위가 실제보다 넓게 보고된다.",
      "evidence": "설계 73~74줄의 여섯 축 열거에 번호가 없고 85~86줄의 대조 목록에는 있다."
    },
    {
      "where": "위험과 대가 — '테스트가 산문 문구를 168군데에서 앵커로 잡는다'",
      "type": "unsupported",
      "claim": "168을 어떤 셈법으로도 재현하지 못했다. 한국어 문구를 잡는 grep 앵커는 117개(중복 제거 90개)이고 grep -F 호출은 215개, check 이름은 353개다.",
      "consequence": "'건수가 많다'가 이 설계의 대가를 재는 유일한 수인데 검증할 수 없다. 계획 단계에서 앵커를 맞추는 작업량을 40퍼센트 이상 어긋난 값으로 산정하게 되고 어긋난 것을 알아챌 방법이 없다.",
      "evidence": "test_*.sh 네 파일에서 한글을 포함한 grep 앵커는 test_codex_scaffold 15, test_docs_drift 34, test_hooks 0, test_scaffold 68로 합계 117이다."
    },
    {
      "where": "원리 — '원칙 ID는 레포 안에서 382번 참조되므로'",
      "type": "mismatch",
      "claim": "백틱 ID는 392군데다(이 설계 문서 자신 9군데를 빼면 383). 그 가운데 340군데가 docs/superpowers/ 아래 지나간 문서에 있고 한 파일에만 66군데가 몰려 있다. 실제로 배선된 자리는 52군데뿐이다.",
      "consequence": "'382번 참조되므로 늘리지 않는다'는 추론이 서지 않는다. 지나간 설계 문서는 ID를 늘려도 손댈 일이 없으므로 유지 비용에 안 들어간다. 결론 자체는 다른 이유로 옳을 수 있으나 이 근거로는 지탱되지 않아, 나중에 재검토할 때 잘못된 저울을 다시 꺼내게 된다.",
      "evidence": "전체 grep 392, --exclude-dir=docs를 더하면 52. 상위는 docs/superpowers/rewrite-map/agent-principles.md 66, 같은 폴더 domain-docs.md 19, 정본 19다."
    },
    {
      "where": "남의 것을 다시 짓지 않는다 — 'stop-slop-ko와 korean-skills의 humanizer가 그렇다', '강조 밀도·블록 교대·문단 이음말·목록 무게·괄호 밀도는 어느 목록에도 없었다'",
      "type": "contradiction",
      "claim": "확인 가능한 사본에 stop-slop-ko도 korean-skills도 없다. 실제로 열어 본 것은 im-not-ai와 korean-report-skills다. 그리고 im-not-ai의 분류 체계에는 다섯 자리 가운데 넷이 이미 있다 — J-1 과도한 볼드, J-4 괄호 부연 과다, C-2 과도한 불릿 리스트, H-1 문두 접속사 과다와 C-4 3단 공식. 우리 자리라고 부를 수 있는 것은 블록 교대 하나뿐이다.",
      "consequence": "'우리가 채우는 자리는 그 목록에 없는 것'이 새 렌즈와 새 스크립트를 정당화하는 유일한 근거다. 그 근거가 무너지면 다섯 축 가운데 넷은 남의 목록과 겹치는 것을 다시 짓는 일이 되고, 바로 앞 문단이 세운 SSOT 논거를 이 설계가 스스로 어긴다. 게다가 존재를 확인하지 않은 레포 이름 둘을 근거로 적었으므로 나중에 링크를 걸 때 걸 대상이 없다.",
      "evidence": "scratchpad/trial/ 아래는 awesome.md·im-not-ai·korean-report-skills·runA·runB뿐이고 grep -ril 'stop-slop'과 'korean-skills'가 하나도 잡지 못한다. ai-tell-taxonomy.md 559줄 'J-1. 과도한 **볼드**', 577줄 'J-4. 괄호 부연 과다', 232줄 'C-2. 과도한 불릿 리스트', 483줄 'H-1. 문두 접속사 과다', 243줄 'C-4. 문단 첫 문장 요약 공식'. 같은 레포에 계량 스크립트 references/metrics_v2.py도 있다."
    },
    {
      "where": "손대지 않는 것 — '그 가운데 하나는 인수인계 문서에서 이미 발동 문턱을 넘어 있었다'",
      "type": "unsupported",
      "claim": "실행 기록에는 반대 흔적만 남아 있다. 그 실행의 진단 문서는 완화 표현을 보존 대상으로 못 박았고 '사용자 결정 필요'를 보존해야 할 예로 직접 이름 붙여 적었다. 완화 표현 규칙 가운데 어느 것도 지배 패턴 목록이나 정량 앵커 목록에 오르지 않았다. 규칙 개수도 다섯이 아니라 넷이다.",
      "consequence": "'이 위험은 가정이 아니라 실측이다'가 실측으로 뒷받침되지 않는다. 네 금지 가드 가운데 하나가 실측을 근거로 세워졌다고 적혀 있으므로, 나중에 이 가드가 비싸 보일 때 근거를 확인하러 온 사람이 근거를 찾지 못하고 가드를 지운다.",
      "evidence": "02_diagnosis.md 40줄 — '완화 표현: 대체로, ~로 보인다, 미확정, 사용자 결정 필요 … 문체 정리를 이유로 지우거나 단정으로 바꾸지 않는다.' 지배 패턴은 J-1·E-2·C-11·C-8·C-2다. quick-rules.md에서 완화→단언 규칙은 A-10·G-1·G-3·I-4 넷이다."
    },
    {
      "where": "렌즈 전체와 위험과 대가 — README·meta-aggregate·드리프트 테스트를 손볼 일을 적지 않은 것",
      "type": "omission",
      "claim": "test_docs_drift.sh는 skills/reviewer-*/ 집합이 README 트리 주석의 렌즈 나열과 같아야 하고 meta-aggregate의 source 열거와도 같아야 한다고 단언한다. 렌즈를 하나 더하면 둘을 같이 고치지 않는 한 테스트가 곧바로 붉어진다. meta-aggregate는 '다섯 렌즈는 이 스키마로 돌려준다'라고도 적는다. 설계는 셋 중 어느 것도 손볼 것으로 적지 않았다.",
      "consequence": "'기존 테스트가 전부 통과해야 한다'가 합격 기준인데 렌즈 디렉터리를 만드는 순간 깨진다. 위험 절은 원인을 산문 앵커 하나로만 적어, 계획을 쓰는 사람이 이 작업을 빠뜨린 채 진행하다 원인을 산문 재조율로 오진한다.",
      "evidence": "test_docs_drift.sh 25~34줄이 ALL·TREE·AGGSET을 뽑고 47·57줄이 일치를 단언한다."
    },
    {
      "where": "고쳐 주는 범위 — '렌즈가 고친 문장을 준다'와 '구조는 제안까지만'",
      "type": "omission",
      "claim": "렌즈 산출물 계약의 SSOT인 meta-aggregate 스키마에는 고친 문장이나 구조 제안을 담을 자리가 없다. 게다가 드리프트 테스트가 모든 reviewer-*/SKILL.md에 네 문구가 있고 severity가 없을 것을 요구한다.",
      "consequence": "새 렌즈를 짜는 사람이 계약을 확장할지, 필드를 우겨넣을지, 계약 밖으로 돌릴지를 스스로 정하게 되고 어느 쪽이든 다른 다섯 렌즈와 같은 모양이라는 전제가 깨진다. 집계는 결정론적 코드라 모양이 다른 산출물 하나가 조용히 통과하거나 조용히 떨어진다.",
      "evidence": "meta-aggregate/SKILL.md 22~29줄의 스키마와 test_docs_drift.sh 88~95줄의 렌즈별 반복 검사."
    },
    {
      "where": "재조율 — 'agent-principles.md가 첫 대상인 이유는 자로 재서 가장 심했기 때문이다'",
      "type": "contradiction",
      "claim": "스스로 정한 세 축 가운데 둘에서 다른 문서가 더 심하다. 통굵 비율은 reviewer-prior-art가 0.58로 agent-principles의 0.32보다 높고, 괄호 밀도는 README가 0.70으로 0.51보다 높다. 가장 심하다고 말할 수 있는 축은 최장 불릿 하나뿐이다.",
      "consequence": "'상시 로드라서 먼저 가는 것이 아니라 심해서 먼저 간다'는 순서 근거가 이 문서 자신의 수치와 어긋난다. 계획 단계에서 같은 자로 순서를 다시 뽑으면 첫 대상이 바뀌고 어느 쪽을 따를지 정할 근거가 없어진다.",
      "evidence": "통굵 비율은 reviewer-prior-art 0.58, domain-llm-runtime 0.34, agent-principles 0.32 순이다. 괄호는 산문 기준 README 0.70, domain-docs 0.61, nested-orchestration 0.56, agent-principles 0.51이다. 이 문서 14~17줄이 두 값을 직접 적어 두고도 대조하지 않았다."
    },
    {
      "where": "재조율 — '우리 문서 열여섯 개를 같은 자로 재면', '순서는 자가 정한다'",
      "type": "omission",
      "claim": "열여섯 개라는 집합은 맞지만 시제품의 비교 도구는 산문이 열 줄 미만인 문서를 조용히 건너뛴다. 그 조건에 걸리는 것이 여섯이다 — CLAUDE.md(8), domains-index.md(1), domain-plugin(3), reviewer-adversarial(8), reviewer-consistency(8), reviewer-fit(8). 실제로 수치가 나오는 것은 열 개다.",
      "consequence": "여섯 문서는 착수 순서를 정하는 표에 아예 오르지 않은 채 '열여섯 개를 고친다'에는 포함된다. 자가 안 재는 문서를 자가 정한 순서로 고친다는 말이 되어 그 여섯은 순서 없이 감으로 처리되거나 조용히 빠진다. 건너뛰었다는 사실이 어디에도 남지 않으므로 알아챌 수 없다(FAIL-LOUD).",
      "evidence": "compare.py 15줄 — if m['prose_lines'] < 10: continue. 열여섯 문서를 measure()로 돌리면 위 여섯의 prose_lines가 8·1·3·8·8·8이다."
    }
  ],
  "principles_applied": ["MEASURE-FIRST","SSOT","FAIL-LOUD","CLEAR-COMM","TDD","EXPLICIT","SIMPLE","REVERSIBLE","NO-PRIORITY"],
  "notes": "확인해서 맞았던 것 — CLEAR-COMM 불릿이 22문장이라는 것, reviewer-prior-art의 통굵 조각이 15개이고 산문 문장이 26개라는 것(둘을 비율로 묶은 것만 틀렸다), 핸드오버의 굵은 조각 204·블록 134·이음말 문단 2·번호 붙은 제목 35·산문 2.1줄마다 교대, 재조율 대상이 열여섯 문서라는 것, 스킬 디렉터리에 .md 아닌 파일이 없다는 것, 훅이 전부 순수 bash라는 것, 문서 검진 훅이 렌즈 이름을 박지 않는다는 것, '렌즈를 한 번만 띄운다'가 domain-docs·domain-spec-review와 어긋나지 않는다는 것, korean-report-style이 '쉬운 말이 기준이 아니라 정밀도가 기준이다'라고 실제로 선언한다는 것이 모두 확인됐다."
}
```
