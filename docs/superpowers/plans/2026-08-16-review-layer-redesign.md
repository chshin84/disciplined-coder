# 리뷰 레이어 재설계 구현 계획

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** 리뷰어가 등급을 매기는 대신 근거를 적게 하고, 리뷰가 한 번만 돌게 만들어 리뷰에 드는 시간을 줄인다.

**Architecture:** 리뷰 산출물의 계약을 `meta-aggregate` 한 곳에 세우고 다섯 렌즈는 참조만 하게 한다. 렌즈 출력에서 등급 라벨을 걷어내고 결과와 근거를 필수 필드로 만든다. 처분은 렌즈가 아니라 호출자가 정하되, spec 리뷰는 사람이 근거를 읽고 가르고 제품 런타임은 코드가 `type`으로 맵핑한다. 재작성 왕복을 없애고 마커를 개선보다 먼저 남겨 훅 재발동을 구조적으로 끊는다.

**Tech Stack:** 마크다운 스킬 문서와 순수 bash 훅·테스트다. 외부 의존이 없고 빌드 단계도 없다.

**Spec:** `docs/superpowers/specs/2026-08-16-review-layer-redesign-design.md`

## Global Constraints

- 훅과 테스트는 **순수 bash**로 쓴다. `jq`를 비롯한 외부 의존을 새로 들이지 않는다.
- 테스트는 **불변식으로** 검증한다. 기대 개수를 박지 않고 각 스크립트가 `FAIL=0`으로 끝나게 한다.
- 모든 태스크가 끝날 때마다 `for t in scripts/test_*.sh; do bash "$t"; done`을 **전부** 돌린다.
- 계약의 단일 출처는 `skills/meta-aggregate/SKILL.md`다. 렌즈 파일에 계약을 복제하지 않는다.
- 사용자 결정이 필요한 것은 **`🔴`**로 부른다. 이 레포가 이미 쓰는 기호이며 새 어휘를 만들지 않는다.
- 문서는 완결된 문어체로 쓰고, 항목을 번호로 부르지 않는다.
- 마지막 태스크에서 `claude plugin validate ./`를 non-strict로 돌린다.

---

### 산출물 계약을 meta-aggregate에 세운다

**Files:**
- Modify: `skills/meta-aggregate/SKILL.md`
- Test: `scripts/test_docs_drift.sh`

**Interfaces:**
- Consumes: 없다. 이 태스크가 계약의 출발점이다.
- Produces: 렌즈 다섯과 두 호출자가 참조할 산출물 계약이다. 필드 이름은 `lens`, `read`, `issues`, `principles_applied`, `notes`이고, `issues`의 각 항목은 `where`, `type`, `claim`, `consequence`, `evidence`를 갖는다. `severity`는 없다.

- [ ] **실패하는 테스트를 먼저 쓴다**

`scripts/test_docs_drift.sh`의 마지막 줄(`echo "----"; echo "PASS=$pass FAIL=$fail"; [ "$fail" -eq 0 ]`) **앞에** 다음을 넣는다.

```bash
echo "[산출물 계약 — meta-aggregate가 소유한다]"
check "계약이 consequence 를 필수로 적는다"     "grep -qF 'consequence' \"\$AGG\""
check "계약이 evidence 를 필수로 적는다"        "grep -qF 'evidence' \"\$AGG\""
check "계약이 read 필드를 정의한다"             "grep -qF '\"read\"' \"\$AGG\""
check "계약이 빈손을 정상으로 적는다"           "grep -qF '빈 배열인 것은 정상' \"\$AGG\""
check "계약에 등급 라벨이 없다"                 "! grep -qF 'severity' \"\$AGG\""
check "spec 리뷰에 결정 단계가 없음을 적는다"   "grep -qF 'spec 리뷰에서는 결정 단계가 없다' \"\$AGG\""
```

- [ ] **테스트를 돌려 실패를 확인한다**

Run: `bash scripts/test_docs_drift.sh`
Expected: FAIL이 여섯 늘어난다. `severity`는 아직 파일에 있고 나머지 문구는 아직 없다.

- [ ] **meta-aggregate를 고친다**

`## 하는 일` 절의 "심각도순으로 정렬한다(기계적)"를 "출처를 태깅해 한 목록으로 모은다(기계적)"로 바꾼다. 등급이 없어져 정렬 기준이 사라지기 때문이다.

`## 결정 정책 (기본)` 절 전체를 아래로 교체한다.

```markdown
## 리뷰 산출물 계약 (렌즈 공통 — 여기가 SSOT)
다섯 렌즈는 이 스키마로 돌려준다. 렌즈 파일에는 자기 `type` 폐쇄 집합만 정의하고 나머지는 여기를 참조한다.

{ "lens": "grounding|fit|consistency|adversarial|prior-art",
  "read": ["문서 밖에서 실제로 열어본 것 — 파일 경로나 URL"],
  "issues": [ { "where": "문서 내 위치", "type": "<렌즈가 정의한 폐쇄 집합>",
                "claim": "무엇이 문제인가", "consequence": "이대로 두면 무엇이 어떻게 잘못되는가",
                "evidence": "그렇게 본 근거 — 문서 인용, 파일 경로와 줄, URL" } ],
  "principles_applied": ["..."], "notes": "" }

**등급 라벨을 두지 않는다.** 기준 없이 등급을 고르라고 하면 위로 쏠리고, 그 라벨 하나가 왕복을 만든다.
대신 `consequence`와 `evidence`를 필수로 두어, 올릴 값어치를 근거로 증명하게 한다.

- **`consequence`를 구체적으로 못 적는 발견은 올리지 않는다.**
- **`issues`가 빈 배열인 것은 정상적인 결과다.**
- **`read`가 비어 있으면 호출자가 자기 보고에 적는다.** 자동 재시도는 걸지 않는다 — 읽지 않고 채우는
  것을 막을 수 없어 재시도는 "비어 있지 않은 배열"로만 수렴한다.

## 처분은 호출자가 정한다
렌즈는 처분을 고르지 않는다. 처분 축이 맥락마다 다르고(런타임에는 "사용자에게 묻는다"가 없다),
사용자를 멈춰 세울지는 호출자의 책임이기 때문이다.
- **spec 리뷰**(`domain-spec-review`): 사람이 근거를 읽고 `🔴`와 "고칠 것"으로 가른다.
  **spec 리뷰에서는 결정 단계가 없다** — 여기서는 병합과 상충 감지까지만 한다.
- **제품 런타임**(`domain-llm-runtime`): 제품 코드가 `type` 값으로 행동을 정하는 표를 갖는다.
  결정론이 유지되고 리뷰어의 주관에 의존하지 않는다.
```

`## 출력 스키마`의 `aggregated` 항목에서 `"severity": "..."`를 빼고 `"claim"`, `"consequence"`, `"evidence"`를 넣는다. `decision` 필드는 런타임에서 쓰이므로 남기되 설명에 "런타임 전용"을 적는다.

`## 구현 형태` 절의 "regenerate 루프에 상한을 둬" 문장을 "런타임 재시도에 상한을 둬"로 바꾼다.

- [ ] **테스트를 돌려 통과를 확인한다**

Run: `bash scripts/test_docs_drift.sh`
Expected: PASS, `FAIL=0`

- [ ] **커밋한다**

```bash
git add scripts/test_docs_drift.sh skills/meta-aggregate/SKILL.md
git commit -m "feat(meta-aggregate): 리뷰 산출물 계약을 한 곳에 세우고 등급 라벨을 걷어낸다"
```

---

### 렌즈 다섯의 스키마와 프롬프트를 교체한다

**Files:**
- Modify: `skills/reviewer-grounding/SKILL.md`, `skills/reviewer-consistency/SKILL.md`, `skills/reviewer-adversarial/SKILL.md`, `skills/reviewer-fit/SKILL.md`, `skills/reviewer-prior-art/SKILL.md`
- Test: `scripts/test_docs_drift.sh`

**Interfaces:**
- Consumes: 앞 태스크가 `meta-aggregate`에 세운 산출물 계약이다.
- Produces: 렌즈마다 자기 `type` 폐쇄 집합만 남는다. `grounding`은 `omission|contradiction|unsupported|mismatch`, `consistency`는 `contradiction|gap|drift|scope`, `adversarial`은 `failure-mode|over-engineering|irreversible|risk`, `fit`은 `schema|format|style|constraint|compat`, `prior-art`는 `refuted-premise|known-failure|crowded|weak-baseline`이다.

- [ ] **실패하는 테스트를 먼저 쓴다**

`scripts/test_docs_drift.sh`의 마지막 줄 앞에 넣는다. 렌즈 목록을 박지 않고 디렉터리에서 도출한다.

```bash
echo "[렌즈 계약 — 등급 없음, 근거 필수]"
for d in "$HERE"/skills/reviewer-*/; do
  n="$(basename "$d")"; f="$d/SKILL.md"
  check "$n 에 등급 라벨이 없다"          "! grep -qF 'severity' \"$f\""
  check "$n 이 consequence 를 요구한다"   "grep -qF 'consequence' \"$f\""
  check "$n 이 read 를 요구한다"          "grep -qF '\"read\"' \"$f\""
  check "$n 이 빈손을 정상으로 적는다"    "grep -qF '빈 목록이 정상' \"$f\""
  check "$n 이 읽기 범위를 적는다"        "grep -qF '읽기 범위' \"$f\""
done
```

- [ ] **테스트를 돌려 실패를 확인한다**

Run: `bash scripts/test_docs_drift.sh`
Expected: 다섯 렌즈 전부에서 FAIL이 난다. `severity`가 남아 있고 새 문구가 없다.

- [ ] **다섯 렌즈를 고친다 — 공통으로 바꾸는 것**

각 파일의 `## 출력 스키마` 절에서 스키마 한 줄을 아래 꼴로 바꾼다(`type` 값만 렌즈마다 다르다).

```
{ "lens": "grounding", "read": [ "..." ],
  "issues": [ { "where": "...", "type": "omission|contradiction|unsupported|mismatch",
                "claim": "...", "consequence": "...", "evidence": "..." } ],
  "notes": "" }
```

그 아래 "통과·실패 신호는 이슈의 `severity` 하나다" 문장을 아래로 교체한다.

```markdown
필드의 뜻과 공통 규칙은 `meta-aggregate`의 리뷰 산출물 계약이 SSOT다 — 여기에 복제하지 않는다.
처분은 이 렌즈가 정하지 않고 호출자가 정한다.
```

각 파일의 레퍼런스 프롬프트 system 문장 끝에 세 문장을 더한다.

```
등급을 매기지 마라. 발견마다 이대로 두면 무엇이 어떻게 잘못되는지(consequence)와 그렇게 본
근거(evidence)를 적어라. 결과를 구체적으로 못 적는 것은 올리지 마라. 찾은 것이 없으면
빈 목록이 정상이다.
```

- [ ] **다섯 렌즈를 고친다 — 렌즈마다 다른 읽기 범위**

각 파일 체크리스트 뒤에 `## 읽기 범위` 절을 만들고 아래를 적는다.

`reviewer-grounding`은 "문서 밖을 반드시 읽는다. 주입된 사실, 문서가 주장하는 대상 코드, 기존 구현을 열어 대조하고 연 것을 `read`에 적는다."

`reviewer-consistency`는 "짝 문서와 문서가 직접 이름을 부른 파일까지만 읽는다. 그 밖으로 탐색하지 않는다."

`reviewer-adversarial`은 "문서 안에서 추론한다. 문서가 가리키는 파일은 확인하되 스스로 탐색하지 않는다."

`reviewer-fit`은 "출력 계약과 후보만 본다. 문서 밖으로 나가지 않으므로 `read`는 대개 빈 배열이다."

`reviewer-prior-art`는 "웹으로 나간다. 아래 가드 다섯을 그대로 지킨다."

- [ ] **prior-art의 등급 의존 가드를 고친다**

`skills/reviewer-prior-art/SKILL.md`에서 "네 축 대조에서 하나라도 다르면 그 차이를 명시하고 심각도를 한 단계 낮춘다"를 "네 축 대조에서 하나라도 다르면 그 차이를 명시하고 같은 사례라고 단정하지 않는다"로 바꾼다. 등급이 없어져 낮출 대상이 없기 때문이다.

같은 파일에서 "라우팅은 `meta-aggregate`의 결정 정책을 따르되, `crowded`와 `refuted-premise`의 critical은 호출자가 재작성을 건너뛰고 사람에게 올린다"를 "이 렌즈의 발견은 호출자가 전부 `🔴`로 처분한다(그 규칙은 `domain-spec-review`가 SSOT다)"로 바꾼다.

`search_status` 표에서 "모두 critical 0으로 읽는다"를 "모두 발견 없음으로 읽는다"로 바꾼다.

- [ ] **테스트를 돌려 통과를 확인한다**

Run: `bash scripts/test_docs_drift.sh`
Expected: PASS, `FAIL=0`

- [ ] **커밋한다**

```bash
git add skills/reviewer-*/SKILL.md scripts/test_docs_drift.sh
git commit -m "feat(reviewer): 등급 라벨을 근거 필수 필드로 바꾸고 렌즈별 읽기 범위를 준다"
```

---

### spec 리뷰의 처분 기준과 작업 순서를 바꾼다

**Files:**
- Modify: `skills/domain-spec-review/SKILL.md`
- Test: `scripts/test_docs_drift.sh`

**Interfaces:**
- Consumes: `meta-aggregate`의 산출물 계약과 "spec 리뷰에는 결정 단계가 없다"는 규정이다.
- Produces: `🔴` 진입 기준 셋과 고정된 작업 순서다. 뒤의 훅 태스크가 이 순서를 안내문으로 가리킨다.

- [ ] **실패하는 테스트를 먼저 쓴다**

```bash
echo "[spec 리뷰 — 한 번만 돌고 처분은 호출자가 정한다]"
check "재작성 라우팅이 남아 있지 않다"        "! grep -qF 'regenerate' \"\$CALLER\""
check "🔴 진입 기준을 적는다"                 "grep -qF '되돌리기 어려운 결정인가' \"\$CALLER\""
check "기본값이 고치기임을 적는다"            "grep -qF '기본값이 고치기' \"\$CALLER\""
check "마커를 개선보다 먼저 남기라고 적는다"  "grep -qF '마커를 먼저 남긴다' \"\$CALLER\""
```

- [ ] **테스트를 돌려 실패를 확인한다**

Run: `bash scripts/test_docs_drift.sh`
Expected: 넷 다 FAIL이다. `regenerate`가 라우팅 절에 있고 새 문구가 없다.

- [ ] **처분 절로 라우팅 표를 교체한다**

`## 라우팅한 결과를 어떻게 반영하고 언제 재작업하나` 절 전체를 아래로 바꾼다.

```markdown
## 처분 — 발견을 둘로 가른다
리뷰는 한 번만 돈다. 재작성 왕복을 두지 않는 이유는, 반복 리뷰가 새로 찾아내는 것이 적은데 왕복
비용은 매번 온전히 들기 때문이다. 깊이는 왕복이 아니라 렌즈 프롬프트의 근거 요구로 확보한다.

병합한 발견을 메인 세션이 둘로 가른다. `🔴`로 올리는 기준은 셋이다.
- 되돌리기 어려운 결정인가(`REVERSIBLE`).
- 사용자의 가치판단이 필요한가.
- 고치는 방향이 둘 이상으로 갈리고 근거만으로는 고를 수 없는가.

셋 중 어디에도 걸리지 않으면 전부 고친다 — **기본값이 고치기이고 `🔴`가 예외다.** `🔴`는
`agent-principles.md`가 정한 대로 즉시 사용자에게 surface하며 누구도 자율적으로 구현하지 않는다.

`reviewer-prior-art`의 발견은 판정 내용과 무관하게 전부 `🔴`로 간다. 웹에서 읽어 온 내용이 설계
문서를 자동으로 고치는 경로를 닫기 위해서다.

## 작업 순서 (마커가 개선보다 앞에 온다)
렌즈를 돌린다 → 결과를 병합한다 → 처분을 가른다 → **마커를 먼저 남긴다** → 고칠 것을 반영한다 →
`🔴`를 사용자에게 드린다.

마커가 개선보다 앞에 오는 것이 재발동을 끊는 장치다. 개선 편집 시점에 이미 마커가 마지막 줄에
있으므로 PostToolUse 훅이 조용하다. 기억해서 참는 것이 아니라 발동 조건 자체가 없다.

마커의 뜻은 "리뷰가 한 번 돌았다"이다. `🔴`가 하나라도 있으면 `escalated`, 없으면 `passed`다.
```

- [ ] **집계 절에 남은 결정 표현을 지운다**

같은 파일 `### 3) 메타 집계` 절의 "심각도 정렬·출처 태깅·상충 감지(코드 로직 — LLM 불필요)를 거쳐 decision을 내린다"를 아래로 바꾼다. 등급이 없어져 정렬 기준이 사라졌고, spec 리뷰에는 결정 단계가 없기 때문이다.

```markdown
출처 태깅과 상충 감지(코드 로직 — LLM 불필요)까지만 한다. spec 리뷰에서는 결정 단계가 없으므로
`decision`을 내지 않고, 병합한 목록을 위 처분 절로 넘긴다.
```

- [ ] **테스트를 돌려 통과를 확인한다**

Run: `bash scripts/test_docs_drift.sh`
Expected: PASS, `FAIL=0`

- [ ] **커밋한다**

```bash
git add skills/domain-spec-review/SKILL.md scripts/test_docs_drift.sh
git commit -m "feat(spec-review): 재작성 왕복을 없애고 처분 기준과 마커 선기록 순서를 세운다"
```

---

### 선행연구 렌즈를 기본 묶음에서 뺀다

**Files:**
- Modify: `skills/domain-spec-review/SKILL.md`, `README.md`, `docs/DESIGN-NOTES.md`
- Test: `scripts/test_docs_drift.sh` (이미 있는 디스패치 셋 단언이 이 태스크를 검증한다)

**Interfaces:**
- Consumes: 앞 태스크가 세운 처분 절이다. 선행연구 발견이 전부 `🔴`라는 규칙이 거기 있다.
- Produces: 기본 디스패치 목록이 `grounding`, `consistency`, `adversarial` 셋으로 줄어든다.

**주의:** 세 파일을 **한 커밋에서 함께** 고친다. `test_docs_drift.sh`는 호출자의 디스패치 목록과 README·DESIGN-NOTES의 산문이 같은 집합이어야 한다고 단언하므로, 하나만 고치면 그 사이에 테스트가 붉어진다.

- [ ] **테스트를 먼저 돌려 지금은 통과함을 확인한다**

Run: `bash scripts/test_docs_drift.sh`
Expected: PASS. 지금은 세 곳 모두 prior-art를 적고 있어 집합이 일치한다.

- [ ] **호출자에서 선행연구를 디스패치 목록 밖으로 옮긴다**

`skills/domain-spec-review/SKILL.md`의 디스패치 목록에서 `- \`reviewer-prior-art\` — 조건부다...` 줄을 **삭제**한다. 그 줄이 남아 있으면 테스트가 여전히 디스패치 렌즈로 읽는다.

`### 2-1)` 절의 제목과 본문을 아래로 바꾼다.

```markdown
### 선행연구 렌즈는 제안하고 승인받아 따로 돌린다
기본 묶음에서 뺀다. 웹에 나가는 렌즈이므로 사용자가 개입할 자리를 만든다.

spec인지 plan인지부터 가른다. 훅이 넘긴 경로가 `docs/superpowers/specs`면 spec이고 `plans`면
plan이다. plan에는 제안하지 않는다 — "남이 해봤는가"의 답이 작업 목록을 바꾸지 않기 때문이다.

발동 기준은 이렇다. 이미 하던 일을 자동화하거나 정리하는 spec이면 제안하지 않는다. 아직 해본 적 없는
것을 해내려 하고 그것이 되는지 자체가 미지수이면 제안한다. 판단이 갈리면 제안한다.

기준에 걸리면 리뷰 결과를 전달할 때 **선행연구 대조를 돌릴지 함께 묻는다.** 승인받으면 읽기 전용
서브에이전트로 따로 돌린다. 띄우려는 에이전트에 웹 검색과 웹 페치가 없으면 돌릴 수 없다고 알린다.

**제안했든 안 했든 그 판정과 이유를 보고에 적는다.** 안 했다는 사실은 어떤 산출물도 남기지 않으므로
적지 않으면 빠진 것 자체가 관측되지 않는다(`FAIL-LOUD`).
```

- [ ] **README와 DESIGN-NOTES의 산문을 맞춘다**

`docs/DESIGN-NOTES.md`의 "독립 렌즈(grounding·consistency·adversarial, 그리고 spec이 미지의 영역을 다룰 때만 조건부로 붙는 prior-art) 리뷰"에서 괄호 안을 "grounding·consistency·adversarial"로 줄인다. 이어서 "선행연구 대조는 기본 묶음이 아니라 제안과 승인을 거쳐 따로 돌린다"는 문장을 덧붙인다.

`README.md`에서 `domain-spec-review`와 `meta-aggregate`를 함께 적은 줄을 찾아 렌즈 열거에서 prior-art를 뺀다. 그 줄이 어디인지는 다음으로 확인한다.

```bash
grep -n 'domain-spec-review' README.md | grep 'meta-aggregate'
```

`skills/reviewer-*/SKILL.md` 트리 주석 줄은 **건드리지 않는다.** 그 줄은 렌즈 디렉터리 전체를 열거하는 것이고 prior-art 디렉터리는 그대로 남기 때문이다.

- [ ] **테스트를 돌려 통과를 확인한다**

Run: `bash scripts/test_docs_drift.sh`
Expected: PASS, `FAIL=0`. "README 가 디스패치 안 되는 prior-art 를 안 적는다" 같은 문구로 바뀐다.

- [ ] **커밋한다**

```bash
git add skills/domain-spec-review/SKILL.md README.md docs/DESIGN-NOTES.md
git commit -m "feat(prior-art): 선행연구 렌즈를 기본 묶음에서 빼고 제안·승인 경로로 옮긴다"
```

---

### 런타임 맵핑을 type 기반으로 바꾼다

**Files:**
- Modify: `skills/domain-llm-runtime/SKILL.md`
- Test: `scripts/test_docs_drift.sh`

**Interfaces:**
- Consumes: `meta-aggregate`의 "제품 런타임은 코드가 `type` 값으로 행동을 정한다"는 규정이다.
- Produces: 런타임 호출자가 등급이 아니라 `type`으로 라우팅한다는 규칙이다.

- [ ] **실패하는 테스트를 먼저 쓴다**

```bash
RUNTIME="$HERE/skills/domain-llm-runtime/SKILL.md"
echo "[런타임 — 등급이 아니라 type 으로 행동을 정한다]"
check "런타임 파일을 찾았다"                  "[ -f \"\$RUNTIME\" ]"
check "등급 기반 재생성이 남아 있지 않다"      "! grep -qF 'critical만 regenerate' \"\$RUNTIME\""
check "type 기반 처분 표를 적는다"            "grep -qF '값으로 행동을 정하는 표' \"\$RUNTIME\""
```

- [ ] **테스트를 돌려 실패를 확인한다**

Run: `bash scripts/test_docs_drift.sh`
Expected: 뒤 둘이 FAIL이다. `## 비용` 절 마지막 문장에 "critical만 regenerate를 강제한다"가 남아 있다.

- [ ] **런타임 호출자를 고친다**

`## 조립` 절의 "`meta-aggregate`가 집계해 accept/regenerate/escalate를 결정한다"를 아래로 바꾼다.

```markdown
`meta-aggregate`가 집계하고, 제품 코드가 `type` 값으로 행동을 정하는 표를 따라 재생성·폴백·통과를
결정한다. 렌즈는 등급을 매기지 않으므로 라우팅의 근거는 폐쇄 집합인 `type`이고, 그래서 이 결정은
결정론으로 남는다.
```

`## 비용` 절 마지막의 "critical만 regenerate를 강제한다"를 "재생성을 강제하는 `type`이 무엇인지는 제품이 자기 도메인에 맞게 정하고, 그 표를 코드에 둔다"로 바꾼다.

`## 비기능 체크리스트`의 `(critical)`·`(major)` 표기는 **그대로 둔다.** 그것은 리뷰어가 매기는 값이 아니라 문서가 미리 박아 둔 고정 등급이라 부풀림 문제가 없다. 이 판단을 그 절 머리에 한 줄로 적어 나중에 혼동이 없게 한다.

- [ ] **테스트를 돌려 통과를 확인한다**

Run: `bash scripts/test_docs_drift.sh`
Expected: PASS, `FAIL=0`

- [ ] **커밋한다**

```bash
git add skills/domain-llm-runtime/SKILL.md scripts/test_docs_drift.sh
git commit -m "feat(llm-runtime): 런타임 라우팅을 등급에서 type 기반 표로 바꾼다"
```

---

### 훅 안내문을 새 순서로 고치고 전체를 회귀 확인한다

**Files:**
- Modify: `hooks/spec_review_posttooluse.sh:22`, `hooks/spec_review_stop.sh:49-50`
- Test: `scripts/test_docs_drift.sh`, `scripts/test_hooks.sh`

**Interfaces:**
- Consumes: `domain-spec-review`가 세운 작업 순서다.
- Produces: 없다. 마지막 태스크다.

- [ ] **실패하는 테스트를 먼저 쓴다**

```bash
PTU="$HERE/hooks/spec_review_posttooluse.sh"
STOPH="$HERE/hooks/spec_review_stop.sh"
echo "[훅 안내문 — 마커를 개선보다 먼저]"
check "PostToolUse 안내문이 마커 선기록을 지시한다" "grep -qF '마커를 먼저 남기고' \"\$PTU\""
check "Stop 안내문이 마커 선기록을 지시한다"        "grep -qF '마커를 먼저 남기고' \"\$STOPH\""
```

- [ ] **테스트를 돌려 실패를 확인한다**

Run: `bash scripts/test_docs_drift.sh`
Expected: 둘 다 FAIL이다.

- [ ] **두 훅의 안내문을 고친다**

`hooks/spec_review_posttooluse.sh`의 `msg=` 줄을 아래로 바꾼다. 렌즈 개수는 여기 박지 않는다 — 구성은 호출자 스킬이 SSOT다.

```bash
msg="📋 spec/plan(${base}) 작성됨 — 진행 전 반드시 disciplined-coder domain-spec-review 스킬로 PREP+독립 렌즈 리뷰를 수행하라(어느 렌즈를 돌릴지는 그 스킬이 정한다). 리뷰와 처분 분류가 끝나면 개선보다 먼저 문서 마지막 줄에 spec-review 마커를 먼저 남기고(passed 또는 escalated, HTML 주석) 그다음 개선을 반영하라."
```

`hooks/spec_review_stop.sh`의 `reason=` 안내 문장도 같은 취지로 바꾼다.

```bash
reason="미리뷰 spec/plan:$list
disciplined-coder domain-spec-review(PREP+독립 렌즈, 렌즈 구성은 그 스킬이 정한다)를 수행하고, 개선보다 먼저 문서 마지막 줄에 spec-review 마커를 먼저 남기고(passed 또는 escalated) 그다음 개선을 반영하라."
```

- [ ] **훅 테스트가 깨지지 않았는지 본다**

Run: `bash scripts/test_hooks.sh`
Expected: PASS, `FAIL=0`. 훅 테스트는 마커 문자열과 차단 여부만 보고 안내문 본문은 보지 않는다.

- [ ] **전체 계약을 회귀 확인한다**

Run: `for t in scripts/test_*.sh; do echo "== $t"; bash "$t" | tail -3; done`
Expected: 네 스크립트 모두 `FAIL=0`

Run: `claude plugin validate ./`
Expected: 통과한다. 버전 문자열이 없다는 기존 경고 하나는 이번 변경과 무관하다.

- [ ] **커밋한다**

```bash
git add hooks/spec_review_posttooluse.sh hooks/spec_review_stop.sh scripts/test_docs_drift.sh
git commit -m "feat(hooks): 마커를 개선보다 먼저 남기도록 안내문을 고쳐 재발동을 끊는다"
```

---

## 이 계획이 다루지 않는 것

spec의 "범위 밖" 절을 그대로 따른다. 리스크 비례 게이팅, 렌즈 통합, `doc_review_posttooluse.sh`의 문서 검진 넛지, `self-audit.js`의 `red|major|minor` 어휘는 손대지 않는다.

## 이 문서가 받은 리뷰

**독립 렌즈 리뷰를 거치지 않았다.** 작성 세션이 사용자 요청 없이는 서브에이전트를 띄우지 못하는
설정이었고, 사용자가 렌즈 리뷰 실행을 요청하지 않았다. 작성자 자신의 점검만 거쳤다. 아래 마커는 그
사실을 담아 `escalated`로 남긴 것이며 **리뷰를 통과했다는 뜻이 아니다.**

<!-- spec-review: escalated -->
