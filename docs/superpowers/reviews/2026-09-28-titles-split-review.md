# 제목 규칙 분리 설계 — 리뷰 기록

대상은 `docs/superpowers/specs/2026-09-28-titles-split-design.md` 이고, 렌즈 넷이 지적 43건을 올렸으며 그중 근거가 서지 않은 1건을 걸렀다. 렌즈 원본은 같은 이름의 폴더에 있다.

## 차수의 조건

렌즈를 한 번씩만 실행했다. 네 렌즈 모두 쓰기 도구가 없는 Explore 서브에이전트로 실행했다. 선행연구 렌즈는 이 차수에 붙이지 않았다. 사용자가 같은 날 선행연구를 직접 요청해 `lens-prior-art` 두 건(업계 관행, LLM 프롬프트)을 이미 실행했고, 그 요약이 PREP 의 근거 묶음에 들어갔기 때문이다. 대상은 `docs/superpowers/specs` 아래에 있어 spec 으로 구분했다.

## 둘 이상의 렌즈가 함께 잡은 지적

- **측정 절차가 저장소 규칙과 다르다** — fit·consistency·adversarial 이 함께 잡았다. 조항마다 과제 3개를 조항만 실은 모델로 실행하라는 규칙과 달리, 묶음 전체를 넣고 같은 출력을 조항별로 채점했고 조건마다 1회였다. 측정 대상은 B안과 `TEMPLATE-FIRST` 가 든 앞선 초안이었고, 우선순위 문장과 40자 상한은 측정되지 않았다.
- **`SECTION-HEAD` 문구 변경** — fit 은 시험 대상이라 했고, consistency 는 검사 출력과 `domain-korean.md` 가 '소제목'을 계속 쓴다고 했고, adversarial 은 '행동 변화 없음'이 틀렸다고 했다.
- **`###` 금지의 범위** — adversarial 은 가정이 확정형으로 들어갔다고 했고, consistency·grounding 은 인용한 `review-docs` 구분과 기준이 다르다고 했다. grounding 은 `agent-principles.md` 가 `###` 를 "조항마다" 쓴다는 서술이 틀렸다고 했다(8개 중 6개는 한국어 묶음 제목).
- **`lens-readability` 변경 범위** — adversarial·consistency·grounding 이 함께 잡았다. 옛 규칙은 17·45·62·92행 네 곳에 있는데 변경 표는 한 문장만 다루고, 인용한 문장은 그 글자로 파일에 없다.
- **드리프트 검사와 확인 방법** — consistency·grounding 이 함께 잡았다. 새 ID 셋은 `domain-discipline.md` 에 ID마다 `###` 절이 있어야 검사를 통과한다. "헤드 메시지" grep 은 `test_docs_drift.sh` 411행과 이 spec 자신에 걸린다.
- **T5 의 역효과 누락** — adversarial·grounding 이 함께 잡았다. 조항 모델이 자료의 88%·95% 모순을 놓친 관찰이 측정 표에 없다.

## 한 렌즈만 잡은 지적

- **adversarial** — 대화 답과 짧은 보고에도 묶음이 적용된다. 페이지형 HTML 을 문서와 슬라이드 중 어디로 보는지 정하지 않았다. 40자 상한이 수치·불확실성 요구와 함께 과압축을 다시 강제할 수 있다. 우선순위 문장이 길이와 말투를 '형식'에 넣는지 정하지 않았다. 결론이 없는 단위에도 확신형 제목이 강제되고, `TITLE-PROOF` 의 "옮겨라"가 반증 자료를 밀어낸다. 헤드 메시지 요구만 지우는 더 작은 변경을 먼저 검토할 근거가 있다.
- **consistency** — 참고서에서 `TITLES` 묶음을 어느 층의 제목으로 둘지 정하지 않았다. 「원칙」 절의 영문 풀이 형식과 새 불릿 형식이 다르다.
- **grounding** — `TITLE-PROOF` 이어 읽기는 2회가 아니라 3회다. "공개된 LLM 슬라이드 스킬도 필수로 둔다"는 일반화이며 반례(Anthropic pptx 스킬)가 빠졌다. 사용자 발화 인용이 원문과 다르고, 14:30 사용자 지시(소제목과 목록형)가 경위에서 빠졌다. 격리 확인이 모델의 자기 보고라는 점을 밝히지 않았다.
- **fit** — 조항 문안의 문체 위반이 있다(`ONE-IDEA`·`NO-MID-MOD`·`NO-STACK-MOD`·`SPECIFIC-NAME` 의 '단위', 흐리는 서술어를 이름으로 대지 않음). 본문에는 표 셀 말끝 불일치, 여러 문장짜리 불릿, `ANTI-LIMIT` 두 번, 첫 문장이 없는 절 셋이 있다.

## 거른 지적

- **fit — superseded 표시 누락** — 2026-09-26 결정을 담은 설계 문서는 저장소에 없다(`docs/superpowers/specs`·`plans` grep 결과 이 spec 뿐이다). 그 결정은 `skills/lens-fit/domain-discipline.md` 의 `### LABEL-NOUN` 절에만 있고, spec 의 변경 표가 이미 그 절에 경위를 적는다고 정한다.

## 상충과 커버리지 공백

렌즈 사이에 판정이 부딪힌 곳은 없다. 사용자 결정과 렌즈 지적이 부딪힌 곳이 하나 있다. 40자 상한은 사용자가 고른 값인데 adversarial 은 과압축 위험을 들었다.

커버리지 공백은 셋이다. 대화 답에 이 묶음을 적용했을 때의 행동은 어느 렌즈도 측정 근거로 판정하지 못했다(측정 과제에 대화 답이 없다). 전역 사본(`~/.claude/disciplined-coder/`)의 동기화 시점에 따른 전환기 실패는 adversarial 이 읽기 범위 밖이라 보지 않았다. `claude plugin validate ./` 의 현재 결과는 어느 렌즈도 실행하지 않았다.
