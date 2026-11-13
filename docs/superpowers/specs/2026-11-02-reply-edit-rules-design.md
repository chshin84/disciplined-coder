# 콘솔 답변 교정 규칙 파일 설계

사용자가 2026-11-02 에 이 작업을 보류했다. 원칙 개선을 먼저 마친 뒤 사용자 지시로 재개하라.

## 목적

콘솔 답변은 스트리밍되므로 메인 세션이 다시 고칠 수 없다(`docs/domain-korean.md` 의 2026-10-18 재편 기록). 그러나 `D:\projects\claude-mods` 의 glossary mod 는 응답이 끝난 뒤 Haiku 를 호출해 수정 목록을 받고 화면 표시만 바꾼다. 이 호출을 아래에서 교정 호출이라고 한다. 저장된 답변은 바뀌지 않는다.

이 저장소는 교정 호출이 쓸 규칙 파일과 시험을 소유한다. `claude-mods-bb` 는 mod 저장소에서 작업하는 다른 Claude 세션이며 mod 코드를 맡는다. 이 저장소에서 mod 코드를 고치지 마라.

이 저장소의 완료 기준은 두 가지다. 「시험」을 통과해야 하고, mod 가 `~/.claude/disciplined-coder/reply-edit/rules.json` 하나로 지시문을 조립할 수 있어야 한다.

## 확정한 결정

사용자가 2026-11-02 대화에서 아래 결정을 위 층부터 차례로 확정했다.

| 층 | 결정 |
|---|---|
| 구조 | 메인 세션의 출력과 교정 호출을 분리함 |
| 소유 | 규칙·시험 사례는 이 저장소, 호출·적용·검사·화면 코드는 claude-mods 임 |
| 의존 | mod 의 교정 기능만 이 저장소를 전제함. 파일이 없으면 교정만 끄고 상태 줄에 한 번 알림. mod 에 규칙 대체본을 두지 않음 |
| 수정 범위 | 조각 교체와 순서 변경을 허용하고 내용 추가를 금지함. 삭제는 `COUNT-EARNS` 의 개수 표현만 허용함 |
| 파일 형식 | 생성한 JSON 을 커밋하고 기존 `SCAFFOLD_REFS` 로 설치함 |
| 조항 범위 | 「조항 분류」의 대상 조항을 처음부터 전부 넣음. 조항별 조정은 시험 뒤에 함 |
| 교정 기준 | 교정량이 적어도 뜻이 바뀌지 않는 안전형을 택함 |
| 모델 | Claude Haiku 5.5 로 고정함. 사용자 지시: "하이쿠로 안되면 의미가 없어." |
| 렌더링 | mod 의 몫임. 시험은 화면을 띄우지 않고 결과 문장만 봄 |
| 수정 대상 | 순수 LLM 출력뿐임. bash 내용, diff, 수정된 코드는 대상이 아님 |
| 지시문 | 레드팀 형태로 위반을 찾게 하고, 문체만 고치고 내용은 고치지 않게 함 |

Claude 의 판단으로 정한 값은 파일 경로, `schema` 칸, 이동 형식, 수사 규칙을 찾는 방식, 시험 절차, 개수 단위 목록, 새 낱말 검사의 방식이다. 사용자가 다르게 정하면 그 값을 따른다.

## 사전 시험 결과

메인 세션이 2026-11-02 에 사례 4개를 조건마다 한 번씩 `claude -p` 로 실행했다. 표본이 작으므로 방향의 근거로만 쓴다.

| 조건 | 결과 |
|---|---|
| 단발 호출, 제한 없음 | 위반을 대부분 고쳤으나 대상을 지어내고 뜻을 바꿈 |
| 2회 호출, 제한 없음 | 결론을 뒤집고 없던 사실을 추가함 |
| 단발 호출, 한 문장·새 낱말 제한 | 뜻 변경은 없었으나 위반 대부분이 남음 |
| 순서 변경 | 세 실행 모두 결론 문장이 맨 앞으로 이동함 |

이 결과로 2회 호출은 기각한다. 코드 판정이 뜻 변경을 잡지 못했으므로, 시험에 사람이 결과 문장을 읽는 단계를 둔다. 새 낱말 금지 검사는 코드로 일반 명사와 지어낸 이름을 구분하지 못해 정상 수정을 버렸으므로 제거한다.

이어서 레드팀 지시문으로 사례 43건을 실행했다. 메인 세션의 `claude -p` 실행은 코드 판정 40건, `claude-mods-bb` 의 실제 `$.model.complete` 실행은 42건을 통과했다. 코드·diff·명령·로그 보호 사례는 두 실행 모두 유지되었다. 그러나 두 실행 모두 결과 문장에 뜻 변경과 비문이 남아, 안전형 기준으로는 아직 합격이 아니다.

## 작업 순서

시험이 실패하면 생성 스크립트와 설치 연결은 쓸모가 없으므로 시험을 먼저 하라.

1. `reply-edit/manifest.json`, `reply-edit/cases.json`, `scripts/trial_reply_edit.py` 를 만들고 「시험」을 실행하라.
2. 시험을 통과하면 생성 스크립트, `rules.json`, 검사, 설치 연결을 만들어라.
3. 사용자 승인을 받아 main 에 병합한 뒤 「인계」대로 알려라. 병합과 플러그인 갱신 전에는 설치 경로에 파일이 생기지 않는다.

## 파일 구성

| 파일 | 구실 |
|---|---|
| `reply-edit/manifest.json` | 조항 분류와 지시문의 원본 |
| `reply-edit/rules.json` | 생성 결과 |
| `reply-edit/cases.json` | 시험 사례 |
| `scripts/build_reply_edit.py` | `rules.json` 생성 |
| `scripts/trial_reply_edit.py` | Haiku 호출과 결과 기록 |
| `scripts/test_reply_edit.sh` | 모델을 호출하지 않는 검사 |

`scripts/_scaffold_common.sh` 의 `SCAFFOLD_REFS` 에 `reply-edit/rules.json=reply-edit/rules.json` 을, `SCAFFOLD_WHITELIST` 에 `reply-edit` 를 추가하라. 그 파일과 `scripts/scaffold.sh` 의 주석이 이 목록을 스킬 사본으로만 설명하므로 함께 고쳐라. 금지어 표는 기존 `hooks/_banned_words.sh` 의 해석 규칙을 재사용하고, 재사용할 수 없으면 그 이유를 plan 에 적어라.

`manifest.json` 의 형식은 아래와 같다.

```json
{
  "instructions": "교정 지시문",
  "rules": [
    { "id": "NO-STACK-MOD", "kind": "edit" },
    { "id": "NUM-PRONOUN", "kind": "edit", "source": "korean-banned-words.md", "match": "수사를 대명사처럼" }
  ],
  "excluded": [{ "id": "KEEP-CONNECT", "reason": "제외 이유" }]
}
```

생성 스크립트는 조항 본문이나 `match` 의 불릿을 찾지 못하면 실패하게 하라.

## 파일 계약

`rules.json` 의 형식은 아래와 같다.

```json
{
  "schema": 1,
  "instructions": "교정 지시문",
  "rules": [{ "id": "NO-STACK-MOD", "kind": "edit", "text": "조항 본문" }],
  "banned": [{ "words": ["재다", "재어"], "use": ["측정", "확인"], "except": ["현재는"] }]
}
```

`schema` 는 두 플러그인이 따로 갱신되므로 둔다. mod 는 모르는 값을 받으면 교정을 끄고 알려야 한다. `kind` 는 `edit` 또는 `reorder` 다. mod 가 `moves` 를 끄려면 `reorder` 조항을 빼면 된다.

`instructions` 에 아래 내용을 모두 적어라.

- 수정 범위가 조항 본문보다 앞선다는 우선순위
- 인용과 코드는 고치지 않는다는 제외
- 고치는 데 원문에 없는 사실이 필요하면 그 수정을 하지 않는다는 지시
- `STATUS-FIRST` 는 순서만 바꾸고 줄이지 않는다는 지시
- 콘솔 답변의 문체(합쇼체 산문이며 대화에 문체 지시가 있으면 그 지시를 따름)
- `edits`·`moves` 출력 형식

코드 마커와 보호 용어 지시는 mod 의 구현 세부이므로 mod 가 지시문에 붙인다. mod 는 `rules` 와 `banned` 의 순서를 정해 조립할 수 있으나, 조립 방식을 바꾸면 그 지시문으로 시험을 다시 실행해야 한다.

교정 호출의 출력 형식은 아래와 같다.

```json
{ "edits": [{ "from": "원문 조각", "to": "고친 조각" }], "moves": [{ "text": "옮길 문장", "before": "그 앞에 둘 문장 또는 null" }] }
```

## 수정 검사

아래 검사는 mod 가 구현한다. 시험 스크립트도 같은 규칙으로 적용한다. 항목마다 독립으로 판정하고 통과한 항목만 적용한다.

mod 는 코드 블록, 인라인 코드, 들여쓴 줄, `$` 로 시작하는 줄과 그 출력을 가려 모델에 보내지 않는다. `moves` 를 먼저 적용하고 이어서 `edits` 를 적용한다. 이어서 적용하려면 `from` 이 문장 경계를 넘지 않아야 하므로 아래 첫 항목을 둔다.

- `from` 이 한 문장을 넘거나 현재 본문에 정확히 한 번 나오지 않으면 버린다.
- `from` 과 `to` 가 같거나 `to` 가 빈 문자열이면 버린다.
- 숫자·경로·영문 식별자의 값이 바뀌면 버린다.
- 경로·영문 식별자가 사라지면 버린다.
- 숫자가 사라지면 그 숫자 뒤가 개수 단위(건·개·가지·번)일 때만 허용한다.
- 보호 용어의 등장 횟수나 코드 마커가 바뀌면 버린다.
- `moves` 의 `text`·`before` 가 한 문장 전체가 아니거나 정확히 한 번 나오지 않으면 버린다.
- 불릿·표·제목 줄 안의 문장을 옮기는 항목은 버린다.
- 이어주는 말(그래서·그러나·이어서·따라서·다만)이나 지시어(이·그·아래)로 시작하는 문장을 옮기는 항목은 버린다.

`before` 가 `null` 이면 답변 맨 앞으로 옮기되, 첫 줄이 제목이면 그 다음 줄로 옮긴다.

이 검사로 부정 반전과 주어 교체는 막을 수 없다. 이 위험은 「시험」의 사람 판독으로 확인한다.

## 조항 분류

| `kind` | 조항 |
|---|---|
| `edit` | `VOCAB-PREF`, `SPECIFIC-NAME`, `NO-MID-MOD`, `NO-STACK-MOD`, `SUBJECT-OBJECT`, `WRITTEN-ONLY`, `FULL-SENTENCE`, `ONE-IDEA`, `NO-ANALOGY`, `COUNT-EARNS`, `NUM-PRONOUN`, `PERIOD-NAE` |
| `reorder` | `BOTTOM-LINE`, `STATUS-FIRST` |
| 제외 | `TONE-AXIS`, `TERM-ONE`, `ONE-ENDING`, `ANTI-LIMIT`, `KEEP-CONNECT`, `STATE-ASSUME`, `CONCRETE-FORM`, `NO-SQUEEZE`, `SECTION-HEAD`, `BULLET-SCOPE`, `NO-MIRROR`, `INSTRUCTION-FORM` |

`NUM-PRONOUN` 과 `PERIOD-NAE` 는 `korean-banned-words.md` 「표로 적을 수 없는 규칙」의 수사 규칙과 기간 규칙이다. 원본에 ID 가 없으므로 `manifest.json` 의 `match` 로 찾는다.

그 절의 나머지 불릿은 제외한다. 불릿 규칙은 문장을 새로 써야 하고, 목차·표 머리 규칙과 제목 개수 규칙은 제목을 새로 써야 한다. 비유 규칙과 '것' 규칙은 `NO-ANALOGY`·`SPECIFIC-NAME` 과 겹친다.

제외한 조항의 이유는 아래와 같다.

- `TONE-AXIS` 와 `NO-MIRROR` 는 문체의 근거를 정하므로, 콘솔 답변에 필요한 한 문장만 `instructions` 에 적는다.
- `TERM-ONE`·`ONE-ENDING` 은 여러 곳을 함께 고쳐야 하므로, 일부 수정만 적용되면 원문보다 나빠질 수 있다. 메인 세션은 교정 전 문장을 기억하므로 `TERM-ONE` 은 화면과 다음 답의 용어도 다르게 만들 수 있다.
- `ANTI-LIMIT` 를 적용하면 교정 호출이 부정한 대상을 지워 사실을 잃을 수 있다.
- `KEEP-CONNECT` 를 적용하면 교정 호출이 없던 인과를 만들 수 있다.
- `STATE-ASSUME`·`CONCRETE-FORM`·`NO-SQUEEZE`·`SECTION-HEAD`·`BULLET-SCOPE` 를 적용하려면 내용이나 문장을 새로 써야 한다.
- `INSTRUCTION-FORM` 은 다른 에이전트에게 주는 지시문에 적용된다.

## 검사

`scripts/test_reply_edit.sh` 가 아래를 확인하게 하라. 조항 문장을 테스트에 넣지 마라. 계약은 FAIL=0 이다.

- 생성 스크립트를 다시 실행한 결과가 커밋된 `rules.json` 과 같다.
- `agent-principles.md` 「## 출력」 아래의 `- **`ID`** —` 형태 조항이 모두 `manifest.json` 의 `rules` 나 `excluded` 에 있다. `####` 묶음 이름은 대상이 아니다.
- 「표로 적을 수 없는 규칙」의 불릿 수가 `manifest.json` 에서 그 절을 가리키는 항목 수와 같다.

`scripts/test_scaffold.sh` 에 `rules.json` 사본이 원본과 같다는 검사를 추가하라.

이 검사는 Haiku 의 동작을 보지 않는다. 그래서 `manifest.json` 이나 `rules.json` 을 바꾸면 `scripts/trial_reply_edit.py` 도 실행하라고 `CLAUDE.md` 「변경 뒤 실행」에 적어라.

## 시험

`scripts/trial_reply_edit.py` 는 `claude -p --model claude-haiku-5-5` 를 도구 없이 호출한다. 지시문은 `instructions`, `rules`, `banned` 를 이 차례로 이어 붙인 문자열이고, 입력은 사례의 대화와 답변이다. 사례마다 원본 응답, 항목별 적용·버림과 그 이유, 결과 문장을 파일에 남겨라. 그래야 실패 원인이 모델·검사·응답 잘림 중 어디인지 구분할 수 있다.

`cases.json` 의 사례는 아래 칸을 쓴다.

| 칸 | 뜻 |
|---|---|
| `input` | 교정 대상 답변 |
| `conversation` | 함께 넘기는 대화 |
| `must_fix` | 사라져야 할 표현 |
| `must_keep` | 남아야 할 표현 |
| `expected_any` | 하나 이상 들어 있어야 할 대상 이름 |
| `expected_first` | 맨 앞에 와야 할 문장 |
| `must_not_move` | 옮기면 안 되는 문장 |
| `unchanged` | 결과가 원문과 같아야 하면 true |

사례는 이 세션의 실제 답변과 `claude-mods-bb` 가 보유한 reader-docs-tone 진행 보고를 쓰고, 부족한 조항은 합성 사례로 채워라. 그 보고는 받을 수 없으면 합성 사례로 대신하고 그 사실을 결과에 적어라. `edit`·`reorder` 조항과 금지어 표마다 사례를 하나 이상 두고, 위반 없는 답변을 `unchanged` 사례로 두 개 이상 두어라. 메모리 기록 `haiku-grader-unreliable` 에 Haiku 가 문어체를 위반으로 센 사실이 있기 때문이다.

필수 사례는 아래와 같다.

- `감사 발견 4건` 은 교정되고, `변경안 쪽 49건` 은 남는다.
- `과제 4개를 실행합니다` 의 개수 예고가 교정된다.
- `둘 다 이전 요약에만` 은 대상 이름으로 교정되거나, 대상을 확인할 수 없으면 그대로 남는다.
- 결론이 뒤에 있는 답변은 결론 문장이 맨 앞으로 온다.
- `그래서` 로 시작하는 문장은 옮겨지지 않는다.

판정은 두 단계다. 코드가 칸을 판정한 뒤, 메인 세션이 원문과 결과를 나란히 표로 만들어 사용자에게 보인다. 사용자가 뜻 변경 여부와 교정량이 쓸 만한지를 판정한다. 같은 조건을 다시 실행하지 말고 표본은 사례 수로 늘려라(`CLAUDE.md` 「조항 추가와 문구 변경」).

`49건` 이 지워지면 `COUNT-EARNS` 를 제외하고, 그 조항에 기댄 사례를 빼고, 시험을 한 번 다시 실행하라. 시험이 합격하지 못하면 조항을 줄일지 기능을 접을지 사용자에게 물어라.

## 인계

병합 뒤 `claude-mods-bb` 에 메시지로 아래를 알려라. 시험 원문은 시험 전에 따로 요청하라.

- 설치 경로와 `schema` 값, 「파일 계약」과 「수정 검사」
- 파일이 없거나 `schema` 를 모를 때의 동작
- 바꿔야 할 `refine.ts` 의 위치: 순서 변경과 삭제를 금지한 6행, `edits` 만 읽는 30-38행, 토큰 비교 43행, `readRules` 49-54행
- `refine.ts:61-66` 호출에 `register.tsx:312` 처럼 `timeoutMs` 를 넣으라는 요청(`review-llm-calls` 비기능 체크리스트)
- mod 의 조립 방식을 바꾸면 그 지시문으로 시험을 다시 실행하라는 요청

## 시험 뒤에 정할 일

교정 호출의 출력은 코드가 파싱하고 사람도 읽으므로 `skills/review-llm-calls/SKILL.md` 표의 '둘 다인 출력'에 해당하며, 그 표는 렌즈 두 개를 정한다. 답변마다 호출이 늘어나므로 사용자가 2026-11-02 에 시험 결과를 본 뒤 정하기로 했다. 메인 세션은 시험 결과를 보일 때 이 질문을 함께 물어라.

## 리뷰 반영 판단

2026-11-02 렌즈 리뷰의 지적을 반영해 작업 순서, 파일 계약, 수정 검사, 시험을 고쳤다. 이어서 사용자 답에 따라 교정 기준과 조항 분류를 고쳤다. 조항 두 개를 빼고 기준을 정한 이 변경은 다른 절의 계약을 바꾸지 않으므로 메인 세션은 다시 리뷰하지 않는다.

<!-- spec-review: escalated -->
