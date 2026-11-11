# 4번 단계 프롬프팅 가이드 대응표

이 기록은 설계 문서 `docs/superpowers/specs/2026-11-11-clause-placement-design.md` 「판정 순서」 4번 단계 중 가이드 대응의 결과다. Claude 는 2026-11-11 에 Fable 5.2 가이드와 Opus 5.5 가이드를 WebFetch 로 열어 모든 절을 읽었다. 열지 못한 절은 없다.

결정점 이름은 설계 문서 「행위 모델」의 결정점 표를 따른다. 조항별 지적 횟수는 `02-correction-counts.md` 를 따른다. 그 기록에서 지적이 4건 이상이라 5번 단계로 넘어가는 조항은 `NO-ASSUME`·`CHECKABLE`·`VOCAB-PREF`·`ASK-OPTIONS`·`NO-SQUEEZE`·`TONE-AXIS`·`BOTTOM-LINE`·`YAGNI` 다.

처리 칸의 '채택 후보'는 5번 단계 시험에 넣거나, 1번·9번 단계의 정리 규칙으로 쓰는 지시를 뜻한다. 가이드의 측정은 Anthropic 내부 과제 기준이다. 그래서 채택 후보도 이 저장소의 재현 시험을 통과해야 반영한다.

## 가이드 지시 대응표

| ID | 가이드와 절 | 지시 요지 | 측정과 원문 | 결정점 | 원칙 조항 | 처리와 근거 |
|---|---|---|---|---|---|---|
| F01 | Fable 5.2 머리 Note | 대화 중에 지시를 바꾸려면 최신 턴에 넣는다. | 측정 없음 | 대화 답 작성 | 없음 | 해당 없음. 조항 지시가 아니며, 매 턴 리마인더 훅이 최신 사용자 턴에 덧붙는 방식과 맞는다는 확인에 그친다. |
| F02 | Fable 5.2 「Calibrate effort」 | effort 는 `high` 로 시작해 자체 평가로 조정한다. | 있음. "scores at `low` sat close to Claude Fable 5.1's scores at higher effort" | 없음 | 없음 | 해당 없음. API 설정이며 원칙 조항이 다루지 않는다. |
| F03 | Fable 5.2 「Calibrate effort」 | 숙고를 줄이려면 문구 대신 effort 를 낮춘다. | 있음. "didn't stop the model from thinking at `medium` and above" | 없음 | 없음 | 해당 없음. 원칙에 숙고를 줄이라는 문구가 없다. |
| F04 | Fable 5.2 「Calibrate effort」 | 답 길이와 어조는 effort 대신 프롬프트로 조정한다. | 있음. "Effort barely changes how long the model's replies are" | 대화 답 작성 | 없음 | 해당 없음. 답 형태를 프롬프트 배치로 다루는 이 설계의 전제와 같고, 따로 만들 문안이 없다. |
| F05 | Fable 5.2 「Finish the whole task」 | 남은 일 목록이나 계속 제안으로 턴을 끝내지 말고, 사용자 답과 무관한 일과 평범한 장애 우회를 이어 한다. | 있음. "about half as many sessions ended with doable work left", "Output tokens rose by about 30 percent" | 단계 넘김 | `RESOLVE-NOW`·`ASK-OPTIONS` 와 겹침 | 채택 후보. 측정이 있고 단계 넘김 결정점에 대응 조항의 문안이 없다. |
| F06 | Fable 5.2 「Finish the whole task」 | 손대지 말라고 표시된 파일 같은 고의 차단은 두고 발견 사실을 보고한다. | 측정 없음 | 비가역 행동 | `OTHER-SESSIONS`·`REVERSIBLE` 와 겹침 | 기각. 원칙의 제약 조항이 같은 행동을 이미 요구한다. |
| F07 | Fable 5.2 「Finish the whole task」·「Keep caution from piling up」 | 위험하거나 되돌릴 수 없는 행동의 확인 단계는 남긴다. | 측정 없음 | 비가역 행동 | `REVERSIBLE` 와 겹침 | 기각. `REVERSIBLE` 이 같은 확인을 이미 요구한다. |
| F08 | Fable 5.2 「Approvals」 | 계속하라는 지시는 'go' 대신 할 일을 명시해 보낸다. | 측정 없음 | 지시문 작성 | `INSTRUCTION-FORM` 과 겹침 | 기각. 사용자 쪽 행동이며, Claude 가 서브에이전트에 보내는 글은 `INSTRUCTION-FORM` 이 이미 명령문으로 쓰게 한다. |
| F09 | Fable 5.2 「Approvals」 | 승인 규칙에는 대상 행동을 정확한 이름으로 적는다. | 있음. "held back roughly half of its routine requests" | 비가역 행동 | `REVERSIBLE` | 기각. 후보 문안의 결정점 밖이고 `REVERSIBLE` 은 지적 1건으로 상주에 남는다. 문구 문제는 「원칙과 충돌」에 적는다. |
| F10 | Fable 5.2 「Say who owns the code」 | 코드가 모델 자신의 것이라는 소유 문장을 넣는다. | 있음. "merged repeated code in about half of the tries with this sentence, and in under a tenth of the tries without it" | 판단 위임 | `YAGNI`·`REPORT-DEAD` 와 충돌 | 채택 후보. 설계 문서가 판단 위임 턴으로 시험하기로 정했고 측정이 있다. |
| F11 | Fable 5.2 「Say who owns the code」 | 사용자가 최소 변경을 원하는 코드에는 소유 문장을 빼며, 범위 제한 규칙만으로는 소유 문장의 효과가 사라지지 않는다. | 있음. "about 1.5 times the output tokens", "in one try in six to ten", "still merged repeated code in about a third of the tries" | 범위 결정 | `YAGNI` 와 겹침 | 채택 후보. F10 의 부작용을 범위 결정 위반으로 측정하는 설계 문서 방침과 맞는다. |
| F12 | Fable 5.2 「Say who owns the code」 | 마무리 요약이 작은 변경을 빼므로 요약 대신 diff 를 검토한다. | 수치 없음. "named the larger changes but often left out small ones" | 대화 답 작성 | `STATUS-FIRST`·`BOTTOM-LINE` 과 겹침 | 채택 후보. 사용자 쪽 지시이지만 모델의 보고 누락을 겨누는 문안으로 바꿀 수 있고, F10 을 채택하면 요청 밖 변경이 늘어난다. |
| F13 | Fable 5.2 「Keep users informed during long turns」 | 클라이언트가 진행 갱신 블록을 받도록 `display` 를 설정한다. | 측정 없음 | 없음 | 없음 | 해당 없음. 클라이언트 설정이다. |
| F14 | Fable 5.2 「Keep users informed during long turns」 | 글이 없는 도구 호출이 이어지면 하네스가 턴 범위 리마인더를 덧붙인다. | 있음. "roughly halved the longest silent stretch" | 대화 답 작성 | 없음 | 기각. 측정 대상이 무응답 구간이라 매 턴 배치의 근거가 아니며, 설계 문서 표와 같은 판단이다. |
| F15 | Fable 5.2 「Keep users informed during long turns」 | 시작 전에 한 줄로 할 일을 말하고, 그 답만 읽어도 알 수 있는 마무리 요약을 쓴다. | 있음. "spoke before its first tool call every time", "raised output tokens per task by roughly 20 percent" | 대화 답 작성 | `BOTTOM-LINE`·`STATUS-FIRST` 와 겹침 | 채택 후보. 마무리 요약만 시험한다. 시작 한 줄은 도구를 끈 재현에서 측정할 수 없다. |
| F16 | Fable 5.2 「Keep users informed during long turns」 | 도구 호출 몇 번마다 한 줄 갱신을 쓴다. | 있음. "cut most long silent stretches" | 실행 순서 | 없음 | 기각. 도구를 끈 재현에서 측정할 수 없고 지적 턴이 없다. |
| F17 | Fable 5.2 「Set expectations for subagents」·「Review instructions written for earlier models」 | 위임을 부추기는 상시 지시를 먼저 검토하고 필요 없는 줄을 지운다. | 이 항목에는 측정 없음 | 실행 순서 | `SUB-ORCHESTRATE`·`LENS-ALLOWED` 와 겹침 | 채택 후보. 3번 단계에서 두 조항을 스킬로 옮길지 판단하는 근거로 쓴다. |
| F18 | Fable 5.2 「Set expectations for subagents」 | 서브에이전트 도구 설명에 비용, 위임할 때와 하지 않을 때, 브리프 방법을 비용부터 적는다. | 있음. "delegated about a third less often" | 실행 순서 | `SUB-ORCHESTRATE` | 기각. Claude Code 의 Agent 도구 설명이 이미 비용을 먼저 적는다. |
| F19 | Fable 5.2 「Set expectations for subagents」 | 하네스가 서브에이전트를 어느 모델로 실행하는지 확인한다. | 측정 없음 | 없음 | 없음 | 해당 없음. 메모리 `principle-work-opus-only` 가 이 저장소의 모델을 정한다. |
| F20 | Fable 5.2 「Keep caution from piling up」 | 더는 필요 없는 메모를 지운다. | 있음. "in about four in ten tries, down from nearly all without those notes" | 지시문 작성 | 「행동」 등 1번 단계 삭제 후보 | 채택 후보. 1번 단계의 삭제 후보 표시와 7번 단계 삭제 확인에 쓴다. |
| F21 | Fable 5.2 「Keep caution from piling up」 | 승인이 필요 없는 단계를 이름으로 적는다. | 있음. "raised retries from almost none to about half of the tries", "a general instruction to act more freely changed nothing" | 판단 위임 | `ASK-OPTIONS`·`LENS-ALLOWED` 와 겹침 | 채택 후보. 측정이 있고, `ASK-OPTIONS` 가 5번 단계로 넘어간다. |
| F22 | Fable 5.2 「Keep caution from piling up」 | 리뷰어 에이전트가 붙이는 조건을 확인한다. | 있음. "didn't retry in about a third of the tries" | 지시문 작성 | 「작업 지시서」 | 기각. 렌즈 결과의 형식은 `dispatching-lenses` 가 소유하고, 이 결정점에는 지적 턴이 없다. |
| F23 | Fable 5.2 「Keep caution from piling up」 | 예외는 별도 줄이 아니라 규칙 문장 안에 적는다. | 있음. "in about one try in ten", "in about nine tries in ten" | 지시문 작성 | `작은 변경`·`LENS-ALLOWED`·`DELEGATED-SCORE` 와 충돌 | 채택 후보. 9번 단계에서 합친 조항의 문안을 쓸 때의 작성 규칙으로 쓴다. |
| F24 | Fable 5.2 「Review instructions written for earlier models」 | 프롬프트에 적은 토큰 예산 문구를 빼고 시험한다. | 있음. "removing a large budget lowered cost, with equivalent performance" | 없음 | 없음 | 해당 없음. 원칙에 토큰 예산 문구가 없다. |
| F25 | Fable 5.2 「Review instructions written for earlier models」 | 앞 턴을 고치는 하네스 코드를 없애고 기록은 덧붙이기만 한다. | 수치 없음. 최악 조건만 서술 | 없음 | 없음 | 해당 없음. 매 턴 리마인더 훅은 최신 턴에 덧붙이므로 이 지시와 맞는다. |
| F26 | Fable 5.2 「Review instructions written for earlier models」 | "답을 끝난 것으로 보라" 문구는 자기 오류 지적을 줄이므로 주의한다. | 수치 없음. "far less likely to point out mistakes in its earlier answers" | 대화 답 작성 | `NO-AGREE` | 기각. 원칙에 없는 문구이며, 넣으면 자기 오류 지적이 줄어 재작업이 늘어난다. |
| F27 | Fable 5.2 「Review instructions written for earlier models」 | 숙고를 줄이라는 문구를 지우고 effort 를 낮춘다. | 있음. F03 과 같은 측정 | 없음 | 없음 | 해당 없음. 원칙에 숙고를 줄이라는 문구가 없다. |
| F28 | Fable 5.2 「Review instructions written for earlier models」 | 촘촘한 문체 규칙은 글을 끊으므로 필요 없는 규칙부터 지운다. | 수치 없음. "can make its prose choppy" | 쓰기 공통 | `ONE-IDEA`·`BULLET-SCOPE`·`NO-STACK-MOD`·`NO-MID-MOD` 와 충돌 | 채택 후보. 1번 단계 합치기 후보 표시에 이미 썼고, 9번 단계 합친 조항 문안에도 쓴다. |
| F29 | Fable 5.2 「Review instructions written for earlier models」 | 이유가 사라진 주의 문구를 지우고, 절대 규칙에는 범위와 이유를 적는다. | 이 항목에는 측정 없음 | 지시문 작성 | 원칙 전체의 '이유 한 줄' 형식과 겹침 | 채택 후보. 1번 단계 삭제 후보 표시에 썼고, 원칙 형식이 이미 조항마다 이유를 적는다. |
| F30 | Fable 5.2 「Make reports easy to follow」 | 「Communicating clearly」 문단 전체를 시스템 프롬프트에 넣는다. | 있음. "made final reports less dense, with fewer semicolons" | 대화 답 작성 | 여러 쓰기 조항 | 기각. 2026-11-11 재현 시험에서 원문 그대로 둔 조건이 13·15건으로 감독자 문구 전 조건(12·13건)보다 많았다. |
| F31 | Fable 5.2 「Make reports easy to follow」 | 도구 호출과 파일을 보지 않은 독자가 다른 맥락 없이 이해하게 쓴다. | F30 문단 전체의 측정 | 대화 답 작성 | 「머리말」의 '한 번 읽고 이해' 와 겹침 | 채택 후보. 설계 문서가 문단을 문장 단위로 나눠 5번 단계 후보로 경쟁시키기로 정했다. |
| F32 | Fable 5.2 「Make reports easy to follow」 | 핵심을 첫 몇 문장에 둔다. | F30 문단 전체의 측정 | 대화 답 작성 | `BOTTOM-LINE` 과 겹침 | 채택 후보. `BOTTOM-LINE` 이 지적 9건으로 5번 단계로 넘어간다. |
| F33 | Fable 5.2 「Make reports easy to follow」 | 뒤에 가서야 이해되는 지시어와 개념을 첫 줄에 쓰지 않는다. | F30 문단 전체의 측정 | 대화 답 작성 | `VOCAB-PREF`(원어를 처음 나올 때 풀이)와 겹침 | 채택 후보. `VOCAB-PREF` 가 지적 16건으로 5번 단계로 넘어간다. |
| F34 | Fable 5.2 「Make reports easy to follow」 | 쉬운 말과 완결된 문장으로 쓴다. | F30 문단 전체의 측정 | 대화 답 작성 | `VOCAB-PREF`·`FULL-SENTENCE` 와 겹침 | 기각. 쉬운 말은 F35 문안이 맡고, `FULL-SENTENCE` 는 지적 0건으로 상주에 남는다. |
| F35 | Fable 5.2 「Make reports easy to follow」 | 작업 중 지은 용어와 약칭을 쓰지 않고 누구나 아는 말로 대상을 설명한다. | F30 문단 전체의 측정 | 대화 답 작성 | `VOCAB-PREF` 와 겹침 | 채택 후보. 메모리 `anthropic-prompting-guides` 가 지목한 문장이고 `VOCAB-PREF` 가 5번 단계로 넘어간다. |
| F36 | Fable 5.2 「Make reports easy to follow」 | ASD-STE100 처럼 짧은 문장, 한 문장 한 생각, 능동태, 같은 대상에 같은 낱말로 쓴다. | F30 문단 전체의 측정 | 쓰기 공통 | `ONE-IDEA`·`SUBJECT-OBJECT`·`TERM-ONE` 과 겹침 | 기각. 영어 표준이고, 대응 조항은 지적 4건 미만으로 상주에 남으며, F28 이 경고한 끊김 위험이 있다. |
| F37 | Fable 5.2 「Make reports easy to follow」 | 이어지는 생각은 산문으로, 서로 다른 항목만 불릿으로 쓴다. | F30 문단 전체의 측정 | 쓰기 공통 | `KEEP-CONNECT`·`BULLET-SCOPE` 와 겹침 | 기각. 원칙에 같은 지시가 있고 대응 조항은 지적 4건 미만이다. |
| F38 | Fable 5.2 「Make reports easy to follow」 | 불필요한 세부는 빼고 간결하게 쓰되 핵심 맥락은 남긴다. | 있음. F30 문단의 "made sentences shorter" | 대화 답 작성 | `NO-SQUEEZE` 와 충돌 | 채택 후보. `NO-SQUEEZE` 가 지적 12건으로 5번 단계로 넘어가므로, 핵심 맥락을 남기는 쪽으로 문안을 만든다. |
| F39 | Fable 5.2 「Safeguard refusals」 | 추론을 답에 쓰라는 지시를 지운다. | 측정 없음 | 없음 | 없음 | 해당 없음. 원칙의 근거·이유 요구는 짧은 설명이라 추론 재현 요구가 아니다. |
| F40 | Fable 5.2 「Where to start」 | 관찰한 행동마다 지시를 하나씩 적용해 효과와 토큰 비용을 측정한다. | 측정 없음 | 없음 | 없음 | 해당 없음. 설계 문서 5번 단계가 같은 방법을 이미 쓴다. |
| O01 | Opus 5.5 「Capabilities relevant to prompting」 | 모델의 보고는 한 일, 찾은 것, 사용자에게 필요한 것을 말한다는 능력 서술이다. | 측정 없음 | 대화 답 작성 | `STATUS-FIRST` | 해당 없음. 지시가 아니라 능력 서술이다. |
| O02 | Opus 5.5 「Calibrate effort」 | effort 는 `medium` 으로 시작해 여러 단계를 시험한다. | 있음. "at `medium` matches or exceeds Claude Opus 5 at `high`" | 없음 | 없음 | 해당 없음. API 설정이다. |
| O03 | Opus 5.5 「Calibrate effort」 | `max_tokens` 를 넉넉히 두고, `xhigh`·`max` 는 측정한 작업에만 쓰고, 숙고는 effort 로 줄인다. | 측정 없음 | 없음 | 없음 | 해당 없음. API 설정이다. |
| O04 | Opus 5.5 「Prompts written for thinking disabled」 | 숙고를 끄던 통합은 `low` 로 시작하고 추론을 답에 쓰라는 지시를 지운다. | 측정 없음 | 없음 | 없음 | 해당 없음. API 설정이며 원칙에 해당 문구가 없다. |
| O05 | Opus 5.5 「Unattended agentic runs」 | 글로 끝난 턴을 완료 증거로 보지 말고, 할 일 목록과 이어 하기 메시지를 쓰고, 자동 이어 하기는 두세 번에서 멈춘다. | 측정 없음 | 단계 넘김 | 없음 | 해당 없음. 무인 실행 하네스 루프의 설계이며 조항의 행동이 아니다. |
| O06 | Opus 5.5 「Unattended agentic runs」 | 피할 조기 종료 네 가지(다음 단계 예고로 끝내기, 계속 제안, 나머지 작업을 멈출 필요가 없는 결정 목록, 보고 시점 판단)와 원하는 멈춤을 이름으로 적는다. | 수치 없음. "Expect somewhat more tool calls and output tokens per task" | 판단 위임 | `ASK-OPTIONS`·`STATUS-FIRST`·`DELEGATED-SCORE` 와 충돌 | 채택 후보. 2026-11-11 사용자 지적("역으로 제안해주는게 좋아")과 같은 방향이고 `ASK-OPTIONS` 가 5번 단계로 넘어간다. |
| O07 | Opus 5.5 「Unattended agentic runs」 | 백그라운드 명령이나 서브에이전트가 끝나기 전에는 작업을 끝난 것으로 보지 않는다. | 측정 없음 | 단계 넘김 | `REPORT-WHEN` 과 겹침 | 기각. `REPORT-WHEN` 은 지적 0건으로 상주에 남고, 하네스가 완료 알림을 이미 보낸다. |
| O08 | Opus 5.5 「User-facing progress updates」 | 클라이언트가 진행 갱신을 받도록 `display` 를 설정한다. | 측정 없음 | 없음 | 없음 | 해당 없음. 클라이언트 설정이다. |
| O09 | Opus 5.5 「User-facing progress updates」 | 긴 턴 중에 원문을 건넬 메시지 도구를 첫 요청부터 둔다. | 측정 없음 | 없음 | 없음 | 해당 없음. 하네스 도구 설계다. |
| O10 | Opus 5.5 「User-facing progress updates」 | 시작 의도 한 줄과 짧은 마무리 요약을 시스템 프롬프트로 요구한다. | 수치 없음. "the model is responsive to such instructions" | 대화 답 작성 | `BOTTOM-LINE` 과 겹침 | 채택 후보. F15 와 같은 지시라 같은 문안으로 시험한다. |
| O11 | Opus 5.5 「User-facing progress updates」 | 글 없는 도구 호출이 다섯 번 정도 이어지면 리마인더를 덧붙이고, 두세 번 뒤에는 멈추며, 덧붙인 리마인더는 지우지 않는다. | 있음. "roughly halved the share of tasks with a long silent stretch, with no measurable change in cost" | 대화 답 작성 | 없음 | 기각. 측정 대상이 무응답 구간이라 매 턴 배치의 근거가 아니며, 설계 문서 표와 같은 판단이다. |
| O12 | Opus 5.5 「Explore context in multiapp workflows」 | 행동하기 전에 과제가 언급하지 않은 자료까지 넓게 열어 확인한다. | 있음. "completed noticeably more of them correctly with this instruction" | 전제 사용 | `NO-ASSUME`·`EVIDENCE-FIRST` 와 겹침 | 채택 후보. `NO-ASSUME` 가 지적 18건으로 5번 단계로 넘어간다. |
| O13 | Opus 5.5 「Time signals for multiagent harnesses」 | 경과 시간과 시간 예산을 메시지마다 알린다. | 있음. "Teams given a budget kept answer quality comparable to the single agent's while finishing considerably sooner" | 실행 순서 | `ASYNC-FIRST` 와 겹침 | 기각. Claude Code 하네스가 경과 시간을 넣지 않고, 도구를 끈 재현에서 대기를 측정할 수 없다. |
| O14 | Opus 5.5 「Thinking instructions in chat system prompts」 | 답 전에 깊이 생각하라는 문구를 지운다. | 있음. "replies start sooner, with no clear decline in the quality of the reply" | 없음 | 없음 | 해당 없음. 원칙에 그런 문구가 없다. |
| O15 | Opus 5.5 「Thinking instructions in chat system prompts」 | 이미 한 답은 끝난 것으로 보고 새 질문에 집중한다. | 있음. "reduced thinking on follow-up turns" | 대화 답 작성 | `NO-AGREE` | 기각. F26 의 Fable 5.2 측정처럼 자기 오류 지적을 줄여 재작업이 늘어난다. |
| O16 | Opus 5.5 「Mark pasted text in user messages」 | 붙여 넣은 글을 무작위 ID 태그로 감싸고 시스템 프롬프트에 안내를 둔다. | 수치 없음. "slightly more cautious at times" | 없음 | 없음 | 해당 없음. 애플리케이션이 하는 처리다. |
| O17 | Opus 5.5 「Tools for complex visual inputs」 | 고해상도 이미지와 자르기 도구를 준다. | 측정 없음 | 없음 | 없음 | 해당 없음. 원칙이 다루지 않는다. |
| O18 | Opus 5.5 「Frontend design defaults」 | 일반 지시 대신 피할 패턴을 이름으로 적는다. | 수치 없음. "mostly swaps one default for another" | 쓰기 공통 | 저장소 CLAUDE.md 「습관 반대 조항」과 겹침 | 채택 후보. 설계 문서대로 모든 후보 문안의 작성 규칙으로 쓴다. |
| O19 | Opus 5.5 「Frontend design defaults」 | 첫 결과가 쓴 형태를 보고 피할 목록을 늘린다. | 측정 없음 | 쓰기 공통 | 금지어 목록 | 해당 없음. 비목표인 금지어 목록이 이미 같은 방식으로 운영된다. |

## 후보 문안

아래 문안은 결정점이 대화 답 작성·판단 위임·전제 사용·범위 결정·단계 넘김 중 하나이고 처리가 채택 후보인 지시에서 만들었다. 문안마다 피할 형태를 이름으로 적었다(O18). 5번 단계는 각 문안을 겨누는 조항의 지적 턴을 입력으로 시험한다.

| 문안 ID | 출처 | 결정점 | 겨누는 조항 | 문안 |
|---|---|---|---|---|
| R01 | F10 | 판단 위임 | `ASK-OPTIONS`·`YAGNI` | 이 저장소는 Claude 가 소유한다. 중복을 덧붙이거나 문제를 보고만 하지 말고 구조를 직접 정하라 |
| R02 | F21 | 판단 위임 | `ASK-OPTIONS` | 읽기·검색·재시도·되돌릴 수 있는 수정에는 승인을 묻지 말고 바로 실행하라 |
| R03 | O06 | 판단 위임 | `ASK-OPTIONS`·`STATUS-FIRST` | 결정 목록만 건네고 멈추지 말고, 권장안을 적은 뒤 그 결정과 무관한 일을 이어 하라 |
| R04 | O12 | 전제 사용 | `NO-ASSUME` | 기억과 추정으로 상태를 말하지 말고, 지시에 없는 파일·기록까지 먼저 열어 확인하라 |
| R05 | F11 | 범위 결정 | `YAGNI` | 최소 변경을 원한 작업에는 요청 밖 리팩터링·테스트·문서를 추가하지 말고 요청한 변경만 하라 |
| R06 | F05 | 단계 넘김 | `RESOLVE-NOW` | 남은 일 목록이나 '계속할까요'로 턴을 끝내지 말고, 사용자 답이 필요 없는 일은 끝까지 하라 |
| R07 | F12 | 대화 답 작성 | `STATUS-FIRST` | 큰 변경만 적은 요약을 쓰지 말고, 요청 밖 변경까지 빠짐없이 보고하라 |
| R08 | F15·O10 | 대화 답 작성 | `BOTTOM-LINE` | 앞 대화를 봐야 이해되는 요약을 쓰지 말고, 찾은 사실·한 일·다음 일을 이 답만으로 알게 써라 |
| R09 | F31 | 대화 답 작성 | `BOTTOM-LINE`·`VOCAB-PREF` | 다른 자료를 찾아야 이해되는 답을 쓰지 말고, 도구 출력과 파일을 못 본 독자 기준으로 써라 |
| R10 | F32 | 대화 답 작성 | `BOTTOM-LINE` | 배경부터 늘어놓는 답을 쓰지 말고, 핵심을 첫 두 문장에 써라 |
| R11 | F33 | 대화 답 작성 | `VOCAB-PREF` | 뒤에서야 풀리는 지시어·이름을 첫 줄에 쓰지 말고, 처음 나올 때 풀어 써라 |
| R12 | F35 | 대화 답 작성 | `VOCAB-PREF` | 작업 중 지은 용어·약칭을 쓰지 말고, 처음 보는 독자도 아는 말로 대상을 풀어 써라 |
| R13 | F38 | 대화 답 작성 | `NO-SQUEEZE` | 필요 정보를 빼서 줄이지 말고, 사용자가 묻지 않은 세부만 빼라 |

R01 은 설계 문서 「프롬프팅 가이드 반영」 표가 판단 위임 턴으로 시험하기로 정한 소유 문장이다. 가이드가 보고한 부작용을 보려고, 5번 단계는 R01 조건에서 답 글자 수와 범위 결정 위반을 함께 측정한다. R05 는 같은 부작용을 줄이는 문안이라 R01 과 함께 넣은 조건도 시험할 만하다.

R06 의 단계 넘김 결정점에는 지적 4건 이상인 조항이 없다. 그래서 R06 의 시험 입력은 단계 넘김 결정점의 지적 턴 6개다. 단계 넘김의 다른 가이드 지시(O05·O07)는 하네스 루프 설계이거나 지적 턴이 없어 문안을 만들지 않았다.

R03 의 출처인 O06 은 무인 실행용 문단이고, 가이드는 사람이 응답하는 애플리케이션에서는 빼라고 했다. 이 사용자의 평시 세션은 사람이 응답하는 형태라, R03 은 나머지 작업을 멈출 필요가 없는 결정 목록 한 형태만 겨누도록 줄였다. 그런데도 평시 세션에서 질문이 줄어 `REVERSIBLE` 확인까지 빠지는지는 5번 단계에서 비가역 행동 턴 1개로만 확인할 수 있다.

## 원칙과 충돌

소유 문장(F10)은 `YAGNI` 와 `REPORT-DEAD` 와 부딪친다. `YAGNI` 는 "요청 밖의 개선 사항이 떠오르면 구현하지 말고 사용자에게 제안하라"고 하고, `REPORT-DEAD` 는 "요청과 무관한 죽은 코드나 문서를 발견하면 지우지 말고 이름과 위치를 알려라"고 한다. 가이드는 소유 문장이 중복 합치기와 관련 수정을 요청 없이 하게 만든다고 측정했다.

그래서 두 조항을 상주에 둔 채 R01 을 매 턴에 넣으면 두 지시가 반대 행동을 요구한다. 가이드는 범위 제한 규칙이 소유 문장을 취소하지 않는다고 보고했다(약 3분의 1 이 여전히 합침). 그러므로 R01 을 채택하면 `YAGNI` 의 '제안하라' 문장과 `REPORT-DEAD` 둘째 문장의 처분도 같은 결정에서 정해야 한다.

조기 종료 지시(F05·O06)는 `ASK-OPTIONS`·`STATUS-FIRST`·`RESOLVE-NOW` 와 부분적으로 부딪친다. `ASK-OPTIONS` 는 결과를 바꾸는 결정을 실행 전에 한 건씩 묻게 하고, `STATUS-FIRST` 는 사용자가 정할 일을 먼저 적게 한다. 가이드는 나머지 작업을 멈출 필요가 없는 결정 목록을 건네고 턴을 끝내는 형태를 피할 조기 종료로 꼽았다.

원칙은 물은 뒤에 결정과 무관한 일을 이어 할지 정하지 않는다. 그래서 원칙을 따르는 Claude 는 질문 하나로 턴을 끝내기 쉽다. 이 문제는 R03 과 R06 이 메운다.

승인 규칙의 범위(F09)는 `REVERSIBLE` 과 부딪친다. `REVERSIBLE` 은 "밖으로 보내는 작업"을 실행 전 확인 대상으로 적는다. 가이드는 "sending messages to people outside this conversation" 같은 넓은 이름이 일상 요청의 절반가량을 보류시켰다고 측정했다.

이 저장소의 평시 작업에서 '밖으로 보내는 작업'이 git push, 웹 게시, 메일 전송 중 어디까지인지는 조항 문장에 정해져 있지 않다. `REVERSIBLE` 은 지적 1건으로 상주에 남으므로, 이 설계는 문구를 바꾸지 않는다. 다만 1번 단계의 나누기 후보로 다시 쓸 때는 대상 행동을 이름으로 적어야 한다.

예외를 규칙 안에 적으라는 지시(F23)는 원칙의 예외 배치와 부딪친다. `작은 변경` 은 `CHECKABLE`·`NO-RAW-OUTPUT`·`SUB-ORCHESTRATE` 의 예외를 다른 줄에 두고, `LENS-ALLOWED` 는 하네스 기본 지침의 예외를 별도 조항으로 둔다. 가이드 측정에서 'never' 규칙 아래 승인된 단계를 실행한 비율은 약 10분의 1 이었고, 별도 줄의 예외는 이 비율을 거의 바꾸지 못했으며, 규칙 문장 안의 예외는 약 10분의 9 로 올렸다.

`ASK-OPTIONS` 는 `DELEGATED-SCORE` 예외를 문장 안에 적어 이 지시를 이미 따른다. 그래서 9번 단계에서 합친 조항을 다시 쓸 때 `작은 변경` 의 예외를 대상 조항 문장 안으로 옮기는 안을 검토해야 한다.

문체 규칙의 촘촘함(F28)은 `ONE-IDEA`·`BULLET-SCOPE`·`NO-STACK-MOD`·`NO-MID-MOD` 와 부딪친다. 이 조항들은 '단락이 네 문장에 이르면 새 단락', '항목마다 한 문장', '수식어를 하나만' 같은 고정 한도를 둔다. 가이드는 이런 한도가 글을 끊는다고 경고했다.

Fable 5.2 에 보낸 브리프의 세 답도 표 셀 예외와 압축 문제를 지적했다(설계 문서 「목적」). 다만 가이드는 이 항목에 수치를 붙이지 않았다.

간결성 지시(F38)는 `NO-SQUEEZE` 와 방향이 다르다. 가이드는 "practice concision"을 요구하고, `NO-SQUEEZE` 는 "산문은 형식이나 분량에 맞추려고 압축하지 마라"고 한다. 두 지시는 필요 정보를 남긴다는 점에서 같으므로, R13 은 필요 정보를 빼는 형태만 피할 형태로 적고 묻지 않은 세부를 빼는 행동은 허용했다.

상시 위임 지시 검토(F17)는 `LENS-ALLOWED` 와 부딪친다. `LENS-ALLOWED` 는 렌즈 호출을 상시 허용하고, `NO-RAW-OUTPUT` 은 spec·plan 마다 렌즈 리뷰를 요구한다. 가이드는 위임을 부추기는 상시 지시가 필요 이상의 서브에이전트 실행을 낳는다고 보고 먼저 검토하라고 했다.

두 조항은 렌즈 호출에 한정되므로, 3번 단계에서 스킬로 옮길 때 이 범위를 유지해야 한다.

"답을 끝난 것으로 보라" 문구(F26·O15)는 원칙에 없지만 `NO-AGREE` 와 겹치는 지점이 있다. `NO-AGREE` 는 근거를 댄 판단을 새 증거가 있을 때만 바꾸게 한다. Fable 5.2 가이드는 그 문구를 추가하면 Claude 가 앞 답의 오류를 스스로 지적하는 일이 줄어든다고 보고했고, 그래서 이 기록은 그 문구를 기각했다.
