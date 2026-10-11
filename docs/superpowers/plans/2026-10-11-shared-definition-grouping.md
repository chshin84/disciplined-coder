# 공유 항목 표와 검증 의존 구현 계획

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.
>
> 이 계획은 superpowers:executing-plans 로 현재 세션이 직접 실행한다. Task 1·3·4 는 세션 간 메시지, 서브에이전트 실행, 사용자 질문이 필요해 구현 서브에이전트가 실행할 수 없다.

**Goal:** `nested-orchestration` 스킬의 「묶는 단위」에 공유 항목 표를 넣고, 검증 의존을 큰 명세·흐름·가드레일에 넣으며, 새 규칙을 측정으로 채택 판정한다.

**Architecture:** 고치는 코드는 없고 스킬 문서 하나(`skills/nested-orchestration/SKILL.md`)와 설계 문서 하나를 고친다. 현재 세션은 「묶는 단위」를 먼저 고친 뒤 그 판정 문단으로 측정하고, 측정이 채택 기준을 만족하면 나머지 절을 고친다. 현재 세션은 다른 세션(`disciplined-coder-4c`)이 main 에 병합한 변경 위에서 고친다.

**Tech Stack:** Markdown, git, bash 검사 스크립트(`scripts/test_*.sh`), Python 3(측정 채점, 늘 `python -I -X utf8`로 실행), Claude Code `Agent` 서브에이전트(측정 실행)

**Spec:** `docs/superpowers/specs/2026-10-09-nested-orchestration-large-dev-design.md`의 「2026-10-11 개정 — 묶는 단위」 절

## Global Constraints

- 원칙 조항(`agent-principles.md`)은 고치지 않는다.
- `disciplined-coder-4c`가 고친 절은 고치지 않는다: 「큰 명세」 항목 목록의 계약 줄, 「계약 표」, 「계약 코드」, 「공용 파일」, 「승인 항목」, 「시험 병합」.
- 「큰 명세」 항목 목록에서 이 계획이 고치는 줄은 의존 순서 줄과 '공통 제약과 통합 확인 방법' 줄이다.
- 스킬 문장은 domain-korean 규칙을 따른다. 현재 세션은 문서·개념을 주체로 쓰지 않고 '현재 세션은'으로 주체를 적으며, 단락은 네 문장 이하로 둔다.
- Python 은 Windows 표준출력이 cp949 이므로 늘 `python -I -X utf8`로 실행하고, 기록 파일은 스크립트가 UTF-8 로 직접 쓴다.
- 측정 폴더: `docs/superpowers/reviews/2026-10-11-shared-definition-grouping-check/`. 커밋된 기록은 고치지 않는다. 재측정은 `…-check-2/` 처럼 새 폴더에 같은 구성으로 남긴다.
- 측정용 서브에이전트(목록 재생성, 기대 분할, 측정 실행)의 프롬프트에는 "어떤 도구도 쓰지 말고 이 메시지만으로 답하라"를 넣는다. 완료 통지의 `tool_uses`가 0이 아닌 실행은 버리고 같은 회차 번호로 다시 실행하며, 그 사실을 `result.md`에 적는다.
- 채택 기준: 새 규칙을 받은 서브에이전트가 여섯 요청 각각에서 기대 분할 전체를 5회 중 4회 이상 낸다. 현행 규칙 결과는 비교로만 보고한다.
- 변경 뒤 검사 명령(CLAUDE.md 「변경 뒤 실행」): `d=$(mktemp -d); for t in scripts/test_*.sh; do ( bash "$t" > "$d/$(basename "$t").log" 2>&1 || echo "$t" >> "$d/bad" ) & done; wait; if [ -s "$d/bad" ]; then echo "FAILED:"; while read -r t; do echo "--- $t"; grep 'FAIL:' "$d/$(basename "$t").log"; done < "$d/bad"; else echo "ALL PASS"; fi`. `claude plugin validate ./`의 정상 기준은 main d3db37a 의 CLAUDE.md 대로 오류 없이 `Validation passed`다.

## Review Focus

- 측정 서브에이전트가 저장소 파일이나 스킬을 읽어 정답을 아는 결과: Global Constraints 의 도구 금지 문장과 `tool_uses` 확인이 잡는다(Task 3·4).
- 측정에 넘기는 규칙에 측정 대상 요청을 지목한 서술이 섞이는 결과: Task 2 Step 1·5 가 판정 문단만 추출하고 Step 6 이 '주문 처리'가 없는지 확인한다.
- 서브에이전트 출력의 형식 오류(펜스, 산문, id 변경)가 판정 실패로 섞이는 결과: Task 4 의 `score.py`가 형식 오류를 따로 세고 같은 회차를 다시 실행하게 한다.
- 실행 누락이 있어도 채택되는 결과: `score.py`가 여섯 요청과 요청마다 유효 실행 5회를 요구한다.
- 미달일 때 되돌릴 상태가 없는 결과: Task 2 가 규칙 문안 기록과 스킬 변경을 따로 커밋하고, Task 4 Step 5 가 스킬만 main 상태로 되돌리는 명령을 준다.

---

### Task 1: 다른 세션 병합 위로 옮기기

**Files:**
- Modify: `docs/superpowers/specs/2026-10-09-nested-orchestration-large-dev-design.md`(rebase 충돌 해결)
- Modify: 브랜치 `shared-definition-grouping`

**Interfaces:**
- Produces: 4c 의 「계약 표」 절이 있는 SKILL.md 위의 `shared-definition-grouping` 브랜치

- [ ] **Step 1: main 에 4c 병합이 있는지 git 으로 확인한다**

Run: `git show main:skills/nested-orchestration/SKILL.md | grep -c '계약 표'`
Expected: 1 이상. 0이면 현재 세션은 4c 에 병합 시점을 묻고 기다린다.

- [ ] **Step 2: rebase 한다**

Run: `git switch shared-definition-grouping && git rebase main`
Expected: 2026-10-09 spec 끝에서 충돌이 난다. 현재 세션은 충돌할 때마다 main 의 「2026-10-11 개정 — 계약 표」 절을 위에, 이 브랜치의 「2026-10-11 개정 — 묶는 단위」 절을 아래에 두고, 마커는 파일 마지막 줄에 이 브랜치 쪽 마커 하나만 남긴다. 이어서 `git add docs/superpowers/specs/2026-10-09-nested-orchestration-large-dev-design.md && GIT_EDITOR=true git rebase --continue`를 충돌이 없어질 때까지 반복한다.

- [ ] **Step 3: 두 개정 절과 4c 의 문장이 남았는지 확인한다**

Run: `grep -n '^## 2026-10-11 개정' docs/superpowers/specs/2026-10-09-nested-orchestration-large-dev-design.md; tail -1 docs/superpowers/specs/2026-10-09-nested-orchestration-large-dev-design.md; grep -c -E '「계약 표」|테스트 대역' skills/nested-orchestration/SKILL.md`
Expected: 「계약 표」 절과 「묶는 단위」 절 제목이 차례로 출력되고, 마지막 줄은 `<!-- spec-review: passed -->`이며, 마지막 값은 1 이상이다.

### Task 2: 「묶는 단위」와 승인 근거를 새 규칙으로 고친다

**Files:**
- Create: `docs/superpowers/reviews/2026-10-11-shared-definition-grouping-check/extract_rule.py`, `rule-current.md`, `rule-new.md`
- Modify: `skills/nested-orchestration/SKILL.md` 「맡기는 기준」 둘째 문단, 「묶는 단위」 첫 문단부터 '이 재현성은'으로 시작하는 문단까지

**Interfaces:**
- Produces: `rule-current.md`, `rule-new.md` — Task 4 가 측정 서브에이전트에 넘기는 판정 문단(근거와 측정 서술은 빠짐)

- [ ] **Step 1: 판정 문단 추출 스크립트를 쓰고 현행 문안을 뽑는다**

```python
# extract_rule.py: SKILL.md 「묶는 단위」에서 판정 문단만 뽑는다. 근거·측정 서술 문단은 측정 서브에이전트에 넘기지 않는다.
import sys
src, out = sys.argv[1], sys.argv[2]
STOPS = ("순환만 합치는 방식은", "현재 세션이 합치는 강한 결합은")
lines = open(src, encoding="utf-8").read().split("\n")
start = next(i for i, l in enumerate(lines) if l.startswith("**묶는 단위.**"))
buf = []
for l in lines[start:]:
    if l.startswith(STOPS) or l.startswith("**큰 명세.**"):
        break
    buf.append(l)
open(out, "w", encoding="utf-8").write("\n".join(buf).strip() + "\n")
print(len(buf))
```

Run: `C=docs/superpowers/reviews/2026-10-11-shared-definition-grouping-check; mkdir -p $C && python -I -X utf8 $C/extract_rule.py skills/nested-orchestration/SKILL.md $C/rule-current.md && grep -c -E '주문 처리|2026-10-10' $C/rule-current.md`
Expected: 첫 출력은 0보다 큰 줄 수이고, 마지막 값은 0이다.

- [ ] **Step 2: 현행 문안 기록을 따로 커밋한다**

Run: `git add docs/superpowers/reviews/2026-10-11-shared-definition-grouping-check && git commit -m "공유 항목 표 측정의 현행 규칙 문안과 추출 스크립트를 남긴다"`
Expected: 커밋이 만들어진다.

- [ ] **Step 3: 「맡기는 기준」 승인 근거 문장을 바꾼다**

old: `근거에는 하위 프로젝트 목록, 「묶는 단위」의 설계 의존 표와 그 결과인 의존 순서, 워크스트림마다`
new: `근거에는 하위 프로젝트 목록, 「묶는 단위」의 공유 항목 표와 설계 의존 표와 그 결과인 시작 의존, 워크스트림마다`

- [ ] **Step 4: 「묶는 단위」 첫 문단부터 '이 재현성은' 문단까지를 아래 글로 바꾼다**

'두 워크스트림이 같은 파일을 고쳐야 하면'으로 시작하는 문단은 그대로 둔다.

```markdown
**묶는 단위.** 현재 세션은 승인받은 하위 프로젝트 목록으로 공유 항목 표를 먼저 만들고, 그다음 설계 의존 표를 만든다. 공유 항목 표의 행은 둘 이상의 하위 프로젝트가 주고받는 자료·상태·정의다. 현재 세션은 명명 관례 같은 관례와 용어 풀이를 행으로 두지 않고 「결정 기록」에 적는다.

공유 항목 표의 칸은 항목, 소유 하위 프로젝트, 사용 하위 프로젝트, 판정, 고정한 의미다. 소유 하위 프로젝트는 그 항목의 의미를 바꾸는 결정을 내리는 하위 프로젝트다. 사용 하위 프로젝트는 그 항목을 받는 하위 프로젝트이며, 현재 세션은 소유 하위 프로젝트를 사용 칸에 넣지 않는다.

현재 세션은 모든 행에 "어느 하위 프로젝트의 내부 설계도 정하지 않고 이 항목의 이름·형식·단위·의미(시간 의미와 결측 의미 포함)를 지금 고정할 수 있는가"를 묻는다. 고정할 수 있으면 판정은 떼어냄이고, 현재 세션은 고정한 의미를 그 행에 한 줄로 적는다. 고정할 수 없으면 판정은 합침이다. 소유 하위 프로젝트가 없는데 고정할 수 없으면, 현재 세션은 그 항목을 바꾸는 하위 프로젝트를 모두 소유 하위 프로젝트로 적는다.

합침 행에서 현재 세션은 소유 하위 프로젝트를 모두 한 워크스트림으로 합친다. 현재 세션은 사용 하위 프로젝트마다 그 하위 프로젝트가 받는 값의 의미를 같은 질문으로 다시 묻는다. 고정할 수 있으면 현재 세션은 소유 쪽 접근 절차를 계약으로 떼어내고 그 사용 하위 프로젝트를 합치지 않는다. 고정할 수 없으면 현재 세션은 그 사용 하위 프로젝트도 합친다.

합침 행끼리 하위 프로젝트가 겹치면 현재 세션은 겹친 행의 하위 프로젝트를 모두 한 워크스트림으로 묶는다. 현재 세션은 큰 명세 단계에서 떼어냄 행과 합침 행에서 떼어낸 접근 절차를 「계약 표」의 행으로 옮기고, 하위 프로젝트 이름을 워크스트림 id로 바꾼다. 소유 쪽은 제공자가 되고 사용 쪽은 소비자가 되며, 소유가 없는 행의 제공자는 현재 세션이다. 이 연결 규칙은 이 절이 소유한다.

설계 의존 표의 행과 열은 합친 묶음과 남은 하위 프로젝트다. X를 설계하려면 Y의 실제 결과(구현 결과나 조사 결과)를 보아야 하면 현재 세션은 X→Y에 1을, 그렇지 않으면 0을 적는다. 공유 항목 표에서 이름·형식·단위·의미를 고정한 관계는 0이다.

현재 세션은 설계 의존 순환에 함께 든 묶음과 하위 프로젝트만 한 워크스트림으로 합치고, 나머지는 하나를 워크스트림 하나로 둔다. 순환을 합치고 나면 워크스트림 사이 의존에는 순환이 남지 않으므로, 현재 세션은 그 의존을 큰 명세 의존 순서 항목의 시작 의존에 적는다. 시작 의존에서 선행 워크스트림이 없는 워크스트림을 시작 워크스트림이라 부르며, 시작 워크스트림들은 동시에 시작할 수 있다. 시작 워크스트림이 하나뿐이면 그 개발은 「맡기는 기준」에 들지 않는다.

현재 세션이 합치는 강한 결합은 설계 의존 순환과 떼어낼 수 없는 공유 항목이다. 설계 의존 표는 설계 활동 사이 선후 관계를 적는 time-based DSM(Design Structure Matrix, 의존을 행렬로 적는 설계 기법)이고, 순환을 한 묶음으로 찾고 나머지를 순서로 두는 근거는 partitioning 이다. 공유 항목 표는 하위 프로젝트 사이 결합을 적는 static DSM 이고, 강하게 결합된 요소를 한 군집으로 묶는 근거는 clustering 이다(Wikipedia 「Design structure matrix」). 순환만 합치는 기준은 axiomatic design(설계 변수 사이 결합을 행렬로 분석하는 설계 이론)과도 같다.

떼어낼 수 없는 공유 항목을 합치는 근거는 Parnas(1972)의 권고 1번이다. 이 권고에 따라 현재 세션은 자료 구조와 그 접근·수정 절차를 한 워크스트림에 두고, 다른 워크스트림이 그 구조를 공유하지 않게 한다. 받는 값의 의미를 고정할 수 없는 사용 하위 프로젝트는 소유 쪽 내부 설계에 기대므로 구조를 공유하는 셈이고, 현재 세션은 이 쪽만 합친다.

2026-10-10 측정에서 하위 프로젝트 목록을 고정한 요청 다섯을 5회씩 묶었을 때, 순환만 합치는 방식은 다섯 요청 모두에서 5회 같은 분할을 냈다. 그러나 주문 처리 요청에 일부러 넣은 상태 변경 순환은 어느 실행도 설계 의존으로 세지 않았다. 현재 세션은 공유 항목 표로 이 누락을 다룬다. 현재 세션은 두 표를 모두 승인 근거에 넣고, 사용자는 떼어냄 행의 고정한 의미를 읽어 현재 세션이 내부 설계를 미리 정했는지 확인한다.
```

- [ ] **Step 5: 새 문안의 판정 문단을 뽑는다**

Run: `C=docs/superpowers/reviews/2026-10-11-shared-definition-grouping-check; python -I -X utf8 $C/extract_rule.py skills/nested-orchestration/SKILL.md $C/rule-new.md`
Expected: 0보다 큰 줄 수가 출력된다.

- [ ] **Step 6: 확인한다**

Run: `C=docs/superpowers/reviews/2026-10-11-shared-definition-grouping-check; grep -c -E '주문 처리|2026-10-10|Parnas|DSM' $C/rule-new.md; grep -n '공유 항목 표' skills/nested-orchestration/SKILL.md | cut -c1-60; grep -n -E 'partitioning|clustering' skills/nested-orchestration/SKILL.md | cut -c1-60; grep -c 'DSM 분할' skills/nested-orchestration/SKILL.md`
Expected: 첫 값은 0이다. 둘째 grep 은 「맡기는 기준」과 「묶는 단위」의 줄을, 셋째 grep 은 「묶는 단위」 근거 문단을 출력하고, 마지막 값은 0이다.

- [ ] **Step 7: 스킬 변경과 새 문안 기록을 커밋한다**

Run: `git add skills/nested-orchestration/SKILL.md docs/superpowers/reviews/2026-10-11-shared-definition-grouping-check/rule-new.md && git commit -m "nested-orchestration 묶는 단위에 공유 항목 표를 넣고 근거를 partitioning·clustering·Parnas 로 나눈다"`
Expected: 커밋이 만들어진다.

### Task 3: 측정 입력과 기대 분할을 준비한다

**Files:**
- Create: `docs/superpowers/reviews/2026-10-11-shared-definition-grouping-check/lists.json`, `expected.json`, `approval.md`

**Interfaces:**
- Produces: `lists.json` — `{"<요청 id>": {"request": "<요청 문장>", "subprojects": [{"id": "<영문 id>", "desc": "<설명>"}]}}`. 요청 id 는 `bond-tool`, `report-quality`, `auth-migration`, `order-processing`, `two-jobs`, `npb` 다.
- Produces: `expected.json` — `{"<요청 id>": {"pairs": [{"a": "<id>", "b": "<id>", "reason": "<이유>"}], "partition": [["<id>", ...], ...]}}`

- [ ] **Step 1: 다섯 요청의 목록을 별도 서브에이전트로 다시 만든다**

현재 세션은 `Agent`(general-purpose) 하나에 아래 프롬프트를 준다. 규칙 문안은 주지 않는다.

```text
어떤 도구도 쓰지 말고 이 메시지만으로 답하라. 아래 요청 다섯마다 하위 프로젝트 목록을 만들어라. 하위 프로젝트는 plan 을 따로 둘 만큼 큰 개발 단위다. 요청 문장에 있는 이름을 되도록 그대로 쓰고, 각 하위 프로젝트에 영문 소문자 id 와 설명을 붙여라. 설명에는 그 하위 프로젝트가 만드는 것과 다른 하위 프로젝트와 주고받는 자료를 적어라. 결과는 JSON {"<요청 id>": {"request": "...", "subprojects": [{"id": "...", "desc": "..."}]}} 하나로만 돌려줘라.
- bond-tool: 채권 도구
- report-quality: 보고서 품질 개선
- auth-migration: 인증 라이브러리 순차 이전
- order-processing: 상태 변경이 서로 오가는 주문 처리
- two-jobs: 서로 독립된 두 일
```

Expected: 완료 통지의 `tool_uses`가 0이고, 응답이 JSON 으로 해석된다.

- [ ] **Step 2: NP-bond-agg 목록을 기록 943행에서 옮긴다**

Run: `python -I -X utf8 -c "import json;L=open(r'C:/Users/ho381/.claude/projects/D--projects-Quant-NP-bond-agg/38538d4d-1094-4aed-86b5-6886010ad780.jsonl',encoding='utf-8').read().split('\n');r=json.loads(L[942]);t=''.join(x.get('text','') for x in r['message']['content'] if x.get('type')=='text');i=t.find('| id');print(t[i:i+1400])"`
Expected: `inputs`, `market`, `rules`, `stats`, `runner` 행이 있는 표가 출력된다. 현재 세션은 각 행의 '맡는 일'과 '예상 태스크' 칸을 이어 `desc` 로 옮기고, 설계 의존 표와 판정 문장은 옮기지 않는다. `request` 는 기록 8행 사용자 요청의 둘째·셋째 문장을 옮긴다. 다섯 요청 결과와 합쳐 `lists.json` 에 UTF-8 로 쓴다.

- [ ] **Step 3: NP-bond-agg 입력에 사용자의 선택이 없는지 확인한다**

Run: `python -I -X utf8 -c "import json;d=json.load(open('docs/superpowers/reviews/2026-10-11-shared-definition-grouping-check/lists.json',encoding='utf-8'));s=json.dumps(d['npb'],ensure_ascii=False);print([w for w in ['4개','넷으로','합쳐서','합친'] if w in s])"`
Expected: `[]`

- [ ] **Step 4: 기대 분할을 규칙을 모르는 별도 서브에이전트로 적는다**

현재 세션은 `Agent`(general-purpose) 하나에 `lists.json` 내용과 아래 프롬프트를 준다.

```text
어떤 도구도 쓰지 말고 이 메시지만으로 답하라. 요청마다 하위 프로젝트 목록이 있다. 하위 프로젝트를 서로 다른 개발자에게 따로 맡긴다고 하자. 한 개발자가 다른 개발자의 내부 설계 결정(상태가 어떻게 바뀌는지, 판정 결과가 무엇을 뜻하는지)을 미리 알거나 기다려야만 자기 하위 프로젝트를 설계할 수 있는 쌍을 모두 적고 이유를 한 줄로 적어라. 서로의 설계 결과를 봐야 하는 쌍도 적어라. 이어서 그 쌍을 같은 묶음에 넣고 나머지는 하나씩 둔 분할을 적어라. npb 는 판단하지 말고 빈 값으로 둬라. 결과는 JSON {"<요청 id>": {"pairs": [{"a": "...", "b": "...", "reason": "..."}], "partition": [[...], ...]}} 하나로만 돌려줘라.
```

Expected: 완료 통지의 `tool_uses`가 0이다. 현재 세션은 `npb` 의 `partition` 을 `[["inputs"],["market"],["rules","runner"],["stats"]]` 로, `pairs` 를 `[{"a":"rules","b":"runner","reason":"사용자가 NP-bond-agg 기록 1205행에서 고른 분할"}]` 로 채워 `expected.json` 에 쓴다.

- [ ] **Step 5: 사용자 승인을 받는다**

현재 세션은 요청마다 하위 프로젝트 목록, 쌍과 이유, 기대 분할을 표로 보이고 `AskUserQuestion` 으로 승인을 받는다. 현재 세션은 이때 기대 분할 기준이 새 규칙의 판정 질문과 같은 개념을 쓴다는 한계도 함께 알린다. 사용자가 고친 값은 `expected.json` 에 반영하고, 승인 결과와 고친 내용을 `approval.md` 에 적는다. 승인 없이 Task 4 로 가지 않는다.

- [ ] **Step 6: 커밋한다**

Run: `git add docs/superpowers/reviews/2026-10-11-shared-definition-grouping-check && git commit -m "공유 항목 표 측정의 입력 목록과 사용자가 승인한 기대 분할을 남긴다"`
Expected: 커밋이 만들어진다.

### Task 4: 측정을 실행하고 채점한다

**Files:**
- Create: `docs/superpowers/reviews/2026-10-11-shared-definition-grouping-check/score.py`
- Create: `docs/superpowers/reviews/2026-10-11-shared-definition-grouping-check/runs/<조건>__<요청 id>__<회차>.txt` (조건은 `current`, `new`, 회차는 1~5, 응답 원문)
- Create: `docs/superpowers/reviews/2026-10-11-shared-definition-grouping-check/result.md`

**Interfaces:**
- Consumes: `rule-current.md`, `rule-new.md`(Task 2), `lists.json`, `expected.json`(Task 3)
- Produces: `result.md` — 요청·조건마다 유효 실행 수, 형식 오류 수, 기대 분할 일치 횟수, 채택 판정

- [ ] **Step 1: 채점 스크립트를 쓰고 빈 입력으로 실행한다**

```python
# score.py: runs/ 의 응답 원문에서 JSON 을 꺼내 expected.json 과 대조하고 result.md 를 UTF-8 로 쓴다.
import json, glob, os
D = os.path.dirname(os.path.abspath(__file__))
exp = json.load(open(os.path.join(D, "expected.json"), encoding="utf-8"))
lists = json.load(open(os.path.join(D, "lists.json"), encoding="utf-8"))
REQS = ["bond-tool", "report-quality", "auth-migration", "order-processing", "two-jobs", "npb"]
def norm(p): return sorted(sorted(g) for g in p)
def parse(text):
    a, b = text.find("{"), text.rfind("}")
    if a < 0 or b < a: return None
    try: return json.loads(text[a:b + 1])
    except json.JSONDecodeError: return None
stats = {}
for f in sorted(glob.glob(os.path.join(D, "runs", "*.txt"))):
    name = os.path.basename(f)[:-4]
    if name.endswith(".format-error"): continue
    cond, req, _ = name.split("__")
    s = stats.setdefault((req, cond), {"valid": 0, "format": 0, "hit": 0})
    out = parse(open(f, encoding="utf-8").read())
    ids = {x["id"] for x in lists[req]["subprojects"]}
    part = out.get("partition") if isinstance(out, dict) else None
    flat = [i for g in part for i in g] if isinstance(part, list) and all(isinstance(g, list) for g in part) else None
    if flat is None or sorted(flat) != sorted(ids):
        s["format"] += 1; continue
    s["valid"] += 1
    s["hit"] += norm(part) == norm(exp[req]["partition"])
lines = ["| 요청 | 조건 | 유효 실행 | 형식 오류 | 기대 분할 일치 | 판정 |", "|---|---|---|---|---|---|"]
adopt = True
for req in REQS:
    for cond in ("new", "current"):
        s = stats.get((req, cond), {"valid": 0, "format": 0, "hit": 0})
        if cond == "new":
            verdict = "통과" if s["valid"] == 5 and s["hit"] >= 4 else "미달"
            adopt = adopt and verdict == "통과"
        else:
            verdict = "비교"
        lines.append(f"| {req} | {cond} | {s['valid']} | {s['format']} | {s['hit']} | {verdict} |")
lines.append(""); lines.append("ADOPT" if adopt else "NOT ADOPT")
open(os.path.join(D, "result.md"), "w", encoding="utf-8").write("\n".join(lines) + "\n")
print(lines[-1])
```

Run: `mkdir -p docs/superpowers/reviews/2026-10-11-shared-definition-grouping-check/runs && python -I -X utf8 docs/superpowers/reviews/2026-10-11-shared-definition-grouping-check/score.py`
Expected: `NOT ADOPT`(아직 실행 결과가 없다).

- [ ] **Step 2: 60회를 병렬로 실행한다**

현재 세션은 조건(`current`, `new`) × 요청 여섯 × 회차 1~5 마다 `Agent`(general-purpose, 백그라운드) 하나를 실행한다. 한 메시지에 여러 호출을 넣어 동시에 실행한다. 프롬프트는 아래와 같다. `<규칙>`에는 조건에 맞는 `rule-current.md` 또는 `rule-new.md` 전문을, `<목록>`에는 그 요청의 `lists.json` 항목을 넣는다.

```text
어떤 도구도 쓰지 말고 이 메시지만으로 답하라. 너는 개발을 서브 세션에 나눠 맡기려는 현재 세션이다. 아래 「묶는 단위」 규칙만 따라 하위 프로젝트 목록을 워크스트림으로 묶어라. 규칙에 없는 기준은 쓰지 마라. 규칙이 만들라는 표를 모두 만들고, 마지막에 분할을 적어라. partition 에는 목록의 id 를 그대로 한 번씩만 써라. 결과는 JSON {"tables": "<표를 마크다운으로>", "partition": [["<id>", ...], ...]} 하나로만 돌려줘라.

<규칙>
<목록>
```

현재 세션은 응답을 받는 즉시 원문을 고치지 않고 `runs/<조건>__<요청 id>__<회차>.txt` 로 저장한다. 완료 통지의 `tool_uses`가 0이 아니면 그 응답을 저장하지 않고 같은 회차로 다시 실행한다.

- [ ] **Step 3: 채점하고 형식 오류만 다시 실행한다**

Run: `python -I -X utf8 docs/superpowers/reviews/2026-10-11-shared-definition-grouping-check/score.py && cat docs/superpowers/reviews/2026-10-11-shared-definition-grouping-check/result.md`
Expected: 요청·조건 12행이 출력된다. 형식 오류가 있는 회차는 현재 세션이 그 파일을 `runs/<조건>__<요청 id>__<회차>.format-error.txt` 로 이름을 바꾸고 같은 회차를 한 번 더 실행한다. 그 뒤 채점을 다시 실행하고, 다시 실행한 회차를 `result.md` 아래에 적는다. 판정 실패는 다시 실행하지 않는다.

- [ ] **Step 4: 측정 기록을 커밋한다**

Run: `git add docs/superpowers/reviews/2026-10-11-shared-definition-grouping-check && git commit -m "공유 항목 표 측정 실행 출력과 채점 결과를 남긴다"`
Expected: 커밋이 만들어진다.

- [ ] **Step 5: 판정에 따라 진행한다**

`ADOPT` 이면 Task 5 로 간다. `NOT ADOPT` 이면 현재 세션은 미달 요청의 `tables` 를 읽어 원인을 적고, 결과와 판정 오차를 사용자에게 보이고 문안을 고칠지 묻는다. 판정 오차는 실행마다 성공 확률이 독립이라는 가정 아래, 한 실행에서 기대 분할을 낼 확률이 0.6인 규칙도 5회 중 4회 이상을 낼 확률이 약 34%이고, 그 확률이 0.9인 규칙도 4회 미만에 그칠 확률이 약 8%라는 뜻이다.

사용자가 문안 수정을 고르면 현재 세션은 Task 2 Step 4 를 고친 문안으로 다시 하고, `…-check-2/` 폴더에 같은 구성으로 다시 측정한다. 사용자가 채택하지 않기로 하면 현재 세션은 `git checkout main -- skills/nested-orchestration/SKILL.md && git commit -m "공유 항목 표 규칙을 측정 미달로 되돌린다"`로 스킬만 되돌리고 측정 기록은 남긴다. 사용자 답 없이 Task 5 로 가지 않는다.

### Task 5: 검증 의존과 나머지 절을 고친다

**Files:**
- Modify: `skills/nested-orchestration/SKILL.md` 「큰 명세」 항목 목록과 그 끝 문단, 「결정 기록」, 「근거와 한계」 끝 문단, 「흐름」, 「가드레일」(「시험 병합」 앞), 「한계」

- [ ] **Step 1: 「큰 명세」 항목 목록의 두 줄을 바꾼다**

old: `- 의존 순서: 다른 워크스트림의 산출물이 있어야 시작할 수 있는 워크스트림`
new: `- 의존 순서: 워크스트림마다 시작 의존(다른 워크스트림의 산출물이 있어야 시작할 수 있는 관계)과 검증 의존(통합 확인에 다른 워크스트림의 실제 구현이 필요한 관계)`

old: `- 공통 제약과 통합 확인 방법`
new: `- 공통 제약과 워크스트림별 통합 확인 방법`

- [ ] **Step 2: 「큰 명세」 끝 문단('설계 문서가 승인된 뒤에 맡기기로 했으면'으로 시작) 바로 뒤에 새 문단을 넣는다**

```markdown
**검증 의존.** X의 서브 세션은 X의 설계와 단위 테스트를 계약 코드와 테스트 대역으로 진행할 수 있다. 그런데 X의 통합 확인에 Y의 실제 구현이 필요하면 X는 Y에 검증 의존한다. 현재 세션은 큰 명세에 워크스트림별 통합 확인 방법을 적을 때 검증 의존을 판정한다. 검증 의존은 시작을 늦추지 않으므로, 현재 세션은 시작 워크스트림을 시작 의존만으로 판정한다.

현재 세션은 큰 명세를 승인받기 전에 시작 의존과 검증 의존을 합친 그래프에 순환이 있는지 본다. 순환이 있으면 현재 세션은 그 워크스트림들의 병합 순서를 정할 수 없으므로, 디스패치 전에 순환에 든 워크스트림을 합칠지 사용자에게 묻는다. 계약 테스트는 아직 없는 워크스트림 모듈을 생략하므로, 현재 세션은 병합 순서를 검증 의존으로만 정한다.
```

- [ ] **Step 3: 「결정 기록」 문단 끝에 문장 하나를 넣는다**

old: `공개 인터페이스는 계약 코드에서 도출하므로 옮겨 적지 않는다.`
new: `공개 인터페이스는 계약 코드에서 도출하므로 옮겨 적지 않는다. 현재 세션은 워크스트림 경계를 넘지 않는 관례와 용어 풀이(예: 구간 경계)도 여기에 적는다.`

- [ ] **Step 4: 「흐름」을 고친다**

old: `6. **통합(현재 세션)** — 「가드레일」의 병합 전 검사와 시험 병합으로 통합 브랜치에 넣는다.`
new: `6. **통합(현재 세션)** — 「가드레일」의 병합 전 검사와 시험 병합으로 통합 브랜치에 넣는다. 검증 의존이 있는 워크스트림은 「검증 의존 대기」대로 넣는다.`

old: `7. **마무리(현재 세션)** — 모든 워크스트림이 들어가면`
new: `7. **마무리(현재 세션)** — 모든 워크스트림이 「가드레일」의 검사를 통과해 들어가면`

old: `의존 순서가 없는 워크스트림은 동시에 진행한다. 같은 파일은 「공용 파일」대로 현재 세션이 맡으므로 동시 진행의 조건이 아니다. 다른 워크스트림의 산출물에 의존하는 워크스트림은 선행 워크스트림이 통합 브랜치에 들어간 뒤 그 끝에서 시작한다.`
new: `시작 의존이 없는 워크스트림은 동시에 진행한다. 같은 파일은 「공용 파일」대로 현재 세션이 맡으므로 동시 진행의 조건이 아니다. 다른 워크스트림에 시작 의존하는 워크스트림은 선행 워크스트림이 통합 브랜치에 들어간 뒤 그 끝에서 시작한다.`

- [ ] **Step 5: 「가드레일」의 「시험 병합」 문단 바로 앞에 새 문단을 넣는다**

「시험 병합」 문단 자체는 고치지 않는다.

```markdown
**검증 의존 대기.** 검증 의존이 있는 워크스트림이 `DONE`을 돌려줘도, 현재 세션은 그 워크스트림이 검증 의존하는 워크스트림이 모두 통합 브랜치에 들어올 때까지 시험 병합을 미룬다. 그래야 시험 병합의 통합 확인이 실제 구현으로 실행되고, 통합 브랜치에 들어간 워크스트림이 모두 통합 확인을 통과한 상태가 된다. 「진행 위치」는 대기 중인 워크스트림을 진행 중으로 보이므로, 현재 세션은 큰 명세의 검증 의존과 통합 브랜치의 `Workstream:` 줄을 대조해 대기 여부를 판정한다.

통합 확인이 실패하고 그 원인이 이미 병합된 워크스트림 Y에 있으면, 현재 세션은 Y의 서브 세션에 실패 출력을 이어 쓰기로 보낸다. 현재 세션은 Y의 수정을 같은 `Workstream:` 트레일러를 넣은 시험 병합으로 넣는다. 이어서 현재 세션은 Y에 검증 의존하는 워크스트림 전부의 통합 확인을 통합 브랜치에서 다시 실행하며, 이미 병합된 워크스트림도 그 대상에 든다.
```

- [ ] **Step 6: 설계 문서 포인터 문장 두 곳을 고친다**

old: `출처와 대조 내용은 설계 문서의 「근거와 한계」와 「2026-10-10 개정」에 있다.`
new: `출처와 대조 내용은 설계 문서의 「근거와 한계」, 「2026-10-10 개정」, 「2026-10-11 개정 — 묶는 단위」에 있다.`

old: `「이어받는 판단과 검증」, 「검증하지 않은 가정」, 「2026-10-10 개정」에 있다.`
new: `「이어받는 판단과 검증」, 「검증하지 않은 가정」, 「2026-10-10 개정」, 「2026-10-11 개정 — 묶는 단위」에 있다.`

- [ ] **Step 7: 확인한다**

Run: `S=skills/nested-orchestration/SKILL.md; for w in '검증 의존' '시작 의존' '용어 풀이' '2026-10-11 개정'; do echo "== $w"; grep -n "$w" $S | cut -c1-70; done`
Expected: '검증 의존'은 「큰 명세」 목록·「검증 의존」·「흐름」·「가드레일」에서, '시작 의존'은 「맡기는 기준」·「묶는 단위」·「큰 명세」 목록·「검증 의존」·「흐름」에서, '용어 풀이'는 「묶는 단위」·「결정 기록」에서, '2026-10-11 개정'은 포인터 두 곳에서 출력된다.

- [ ] **Step 8: 커밋한다**

Run: `git add skills/nested-orchestration/SKILL.md && git commit -m "nested-orchestration 에 검증 의존을 넣는다: 큰 명세에 시작 의존과 나눠 적고, 대상이 모두 들어온 뒤 시험 병합하며, 순환이면 사용자에게 묻는다"`
Expected: 커밋이 만들어진다.

### Task 6: 측정 결과를 적고 전체 검사한다

**Files:**
- Modify: `skills/nested-orchestration/SKILL.md` 「묶는 단위」의 '2026-10-10 측정에서'로 시작하는 문단 바로 뒤
- Modify: `docs/superpowers/specs/2026-10-09-nested-orchestration-large-dev-design.md` 「2026-10-11 개정 — 묶는 단위」 끝(마커 앞)

- [ ] **Step 1: 스킬에 측정 문단을 넣는다**

현재 세션은 '2026-10-10 측정에서'로 시작하는 문단 바로 뒤에 아래 틀의 문단을 넣는다. `<…>`는 `result.md` 값으로 채운다.

```markdown
2026-10-11 측정에서 현재 세션은 여섯 요청마다 현행 규칙과 이 규칙을 5회씩 적용하게 했다. 이 규칙은 기대 분할을 NP-bond-agg <n>회, 주문 처리 <n>회, 나머지 요청 <최소>~<최대>회 냈고, 현행 규칙은 NP-bond-agg <n>회, 주문 처리 <n>회였다. 기대 분할은 규칙을 모르는 서브에이전트가 적고 사용자가 승인했으며, 그 기준이 이 규칙의 판정 질문과 같은 개념을 쓴다는 한계가 있다. 기록은 `docs/superpowers/reviews/2026-10-11-shared-definition-grouping-check/`에 있다.
```

- [ ] **Step 2: 측정한 판정 문단과 배포 문안이 같은지 확인한다**

Run: `C=docs/superpowers/reviews/2026-10-11-shared-definition-grouping-check; T=$(mktemp); python -I -X utf8 $C/extract_rule.py skills/nested-orchestration/SKILL.md $T && diff $C/rule-new.md $T && echo SAME`
Expected: `SAME`

- [ ] **Step 3: 설계 문서에 측정 결과 문단을 넣는다**

현재 세션은 마커 바로 앞에 아래 틀의 문단을 넣는다. 마커 줄은 마지막 줄로 둔다.

```markdown
**측정 결과.** 현재 세션은 「측정 입력」대로 실행했다. 새 규칙을 받은 서브에이전트는 기대 분할을 bond-tool <n>회, report-quality <n>회, auth-migration <n>회, order-processing <n>회, two-jobs <n>회, npb <n>회 냈고, 판정은 <ADOPT 또는 NOT ADOPT>였다. 현행 규칙은 같은 순서로 <n>·<n>·<n>·<n>·<n>·<n>회였다. 다시 만든 목록은 2026-10-10 입력과 같지 않고, 형식 오류로 다시 실행한 회차는 <회차 목록 또는 없음>이다.
```

- [ ] **Step 4: 확인 방법을 다시 실행한다**

Run: `S=skills/nested-orchestration/SKILL.md; grep -c 'DSM 분할' $S; for w in '공유 항목 표' 'partitioning' '검증 의존' '시작 의존' '용어 풀이' '2026-10-11 개정'; do echo "== $w"; grep -c "$w" $S; done`
Expected: 첫 값은 0이고, 나머지는 모두 1 이상이다.

Run: Global Constraints 의 검사 명령
Expected: `ALL PASS`

Run: `claude plugin validate ./`
Expected: 오류 없이 `Validation passed` 가 출력된다.

- [ ] **Step 5: 커밋하고 병합 승인을 받는다**

Run: `git add skills/nested-orchestration/SKILL.md docs/superpowers/specs/2026-10-09-nested-orchestration-large-dev-design.md && git commit -m "공유 항목 표 측정 결과를 설계와 스킬에 적는다"`
Expected: 커밋이 만들어진다. 현재 세션은 superpowers:finishing-a-development-branch 로 main 병합과 푸시를 사용자에게 묻는다.

<!-- spec-review: escalated -->
