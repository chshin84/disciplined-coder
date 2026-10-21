# 2026-10-21 레포 문서 감사

대상 커밋은 main 903d95e 이고, 작업은 worktree `dc-doc-audit` 에서 했다. 기록 폴더에 `run.json`·`findings.json`·`diff.json`·`suggestions.json` 과 렌즈 원본이 있다.

## 범위와 배정

감사 대상은 살아 있는 문서 27개다. 문서마다 `lens-grounding` 과 `lens-fit` 을 한 호출 안에서 차례로 적용했고, 문서는 묶음 9개로 나눴다. `lens-adversarial` 은 저장소 전체에 한 번 실행했다. `lens-consistency` 는 값이 다른 진술 짝 묶음과 소유를 선언한 문서 묶음에 한 번씩 실행했다. 렌즈를 한 번씩만 실행했다.

- audit_targets.sh 가 낸 evals/ 아래 평가 과제 .md 731개는 일부러 위반을 담은 시험 자료라 대상에서 뺐다(근거: 2026-10-21 plan B Task 6 제외 표). 스크립트가 이를 빼지 않는 문제는 발견 #002 다.
- lens-readability 는 README.md 에 제안했고 사용자가 승인했다. 그 뒤 사용자가 'README 변경은 이 worktree 에서 제외하라'고 지시해 실행하지 않았다. 제안문을 받아도 반영할 곳이 없기 때문이다.
- 사용자 요청으로 README.md 의 lens-fit 에 domain-readme 「넣지 말 것」 기준의 절별 지적을 함께 요구했다.
- lens-prior-art 는 감사 절차가 제안하지 않는다.
- 묶은 호출은 한 에이전트 안에서 lens-grounding 다음 lens-fit 순서로 적용하게 지시했다. 턴을 SendMessage 로 나누지는 않았다.
- 값이 다른 짝은 세션이 고르지 않고 statements 묶음 전체를 lens-consistency 에 주어 렌즈가 짝을 골랐다(약 22쌍, 좁혀 적기 6쌍, 발견 0).

## 기계 검사

- **contract_tests:** scripts/test_*.sh 를 동시에 실행해 모두 통과했다(시작 커밋 903d95e).
- **targets_script:** bash scripts/audit_targets.sh 가 758개를 냈고, 그중 evals/ 아래 731개를 뺀 27개를 대상으로 삼았다.
- **topics_script:** bash scripts/audit_topics.sh 의 이름표 79개를 statements 요구에 넣었다.
- **prior_rounds_script:** bash scripts/audit_prior_rounds.sh self-audit 가 2026-10-12-self-audit 를 첫 줄로 냈고, --stale 은 비었다.
- **evidence_script:** audit_evidence.sh 를 시작 커밋 903d95e 의 worktree 에 실행해 문서 단위·공격 렌즈 193건과 소유자 문서 lens-consistency 8건이 모두 통과했다(탈락 0).
- **style_metrics:** 사용자 지시로 이번 차수에는 금지 표현도 셌다. bash scripts/check_banned_words.sh(적용 대상 「문서와 답변」 행, 훅과 같은 파서)로 세었고, 감사 대상 27개 중 10개 문서에서 검출되었다. 두 번째 세는 법은 쓰지 않았다.

## 판정 개수

발견은 201건이다. 확정 200건, 기각 1건, 미판정 0건이다.

| 렌즈 | 올린 발견 | 확정 |
|---|---|---|
| `lens-adversarial` | 14 | 14 |
| `lens-fit` | 136 | 135 |
| `lens-grounding` | 43 | 43 |
| `lens-consistency` | 8 | 8 |

렌즈 단계의 토큰 하한은 2,659,946이고, 확정 하나당 13,299이다.

## 집계

배정한 렌즈 12개가 모두 결과 JSON 을 돌려줬다. 커버리지 공백은 없다. `lens-consistency` 의 값이 다른 짝 묶음 호출은 짝 약 22쌍을 보고 발견 0건을 냈다.

## 확정 발견

처분 칸의 값은 판정 때 세션이 붙인 분류다. fix 는 이번 차수에 고칠 것, defer 는 넘길 것, decide 는 사용자 결정이 필요한 것, design 은 설계로 넘길 것이다.

| id | 파일 | 렌즈 | 조항 | 처분 | 지적 |
|---|---|---|---|---|---|
| 001 | `skills/nested-orchestration/SKILL.md` | lens-adversarial | OTHER-SESSIONS | decide | nested-orchestration 은 현재 세션에게 다른 저장소에 브랜치와 워크트리를 만들고, 현재 브랜치가 아닌 ws/·spec/·dev/ 브랜치를 병합하고 지우라고 지시한다. 그러나 모든 세션에 실리는 OTHER-SESSIONS 는 그 조작을 … |
| 002 | `skills/audit-repo-docs/SKILL.md` | lens-adversarial |  | decide | audit-repo-docs 는 감사 대상 목록을 손으로 적지 말고 audit_targets.sh 의 출력을 쓰라고 한다. 그러나 그 스크립트는 docs/superpowers/ 와 HANDOFF-* 만 빼므로 evals/ 아래 시험용 .md 가 모두 … |
| 003 | `skills/audit-repo-docs/SKILL.md` | lens-adversarial |  | design | 직전 diff.json 이 잔존으로 적었지만 직전 차수 렌즈가 다시 올리지 않은 항목은 대조에서 빠진다. 문서는 남은 문제를 이번 렌즈가 새 발견으로 잡는다고 가정한다. 그러나 review-specs 는 렌즈를 한 번만 실행하면 두 번째 실행이 잡을 … |
| 004 | `skills/nested-orchestration/SKILL.md` | lens-adversarial | NO-RAW-OUTPUT | design | 현재 세션은 하부 명세와 plan 의 마지막 줄 마커만 보고 옮기거나 병합한다. 그러나 review-specs 는 마커를 반영보다 먼저 남기게 하고, 마커의 뜻을 '리뷰가 실행되었다'로만 정한다. 서브 세션이 마커를 남긴 뒤 반영 도중 끊기거나 반영을… |
| 005 | `README.md` | lens-adversarial |  | defer | README 는 Stop 게이트가 이 세션이 시작된 뒤 생긴 spec·plan 만 차단한다고 적는다. 그러나 stop_gates.sh 는 HEAD 커밋이 추가한 spec·plan 에는 세션 시작 시각 거르기를 하지 않는다. 그래서 마커 없는 spec … |
| 006 | `agent-principles.md` | lens-adversarial | NO-RAW-OUTPUT | decide | `작은 변경` 은 파일 하나 20줄 이하의 작업에서 NO-RAW-OUTPUT 렌즈 검증과 SUB-ORCHESTRATE 판단을 생략하라고 한다. 그러나 Stop 게이트는 새 spec·plan 이 마커 없이 남으면 크기와 무관하게 차단하고, nested_… |
| 007 | `agent-principles.md` | lens-adversarial | EDIT-PRIORITY | decide | EDIT-PRIORITY 는 형식 경고가 올 때만 사후 수정을 하라고 정한다. 그러나 형식 경고를 내는 훅은 .md 만 보고, 보는 형식도 라벨 불릿·개수 예고·제목 개수 셋이다. 「읽기 위한 문서」의 .html·.pptx·.docx 산출물에는 경고가… |
| 008 | `skills/review-docs/SKILL.md` | lens-adversarial | REVIEW-DELIVERABLE | design | review-docs 는 금지 낱말을 렌즈에 넘기지 않고 렌즈도 보지 않게 하며, 그 근거로 훅을 든다. 그러나 같은 문장이 훅은 .html·.pptx 를 보지 않는다고 인정한다. review-docs 의 주 대상인 .html·.pptx·.docx·.… |
| 009 | `README.md` | lens-adversarial |  | defer | README 는 금지 표현 차단 대상을 '사용자가 요구한 산출물 .md'로 적는다. 그러나 _spec_marker.sh 는 다른 프로젝트의 .md 중 메모리·docs/superpowers·이 저장소 문서만 빼고 전부를 대상으로 한다. korean-ba… |
| 010 | `README.md` | lens-adversarial |  | defer | README 는 '이 플러그인 저장소의 문서'만 금지 표현 검사에서 뺀다고 적는다. 그러나 path_in_own_repo 는 조상 폴더에 agent-principles.md 라는 이름의 파일이 있으면 어느 저장소든 이 저장소로 본다. 같은 이름의 파일… |
| 011 | `skills/agent-prior-art/SKILL.md` | lens-adversarial |  | design | agent-prior-art 는 탐색 연구자만 상한(최대 20)에 넣고 검증자는 URL 마다 하나씩 실행하면서 상한을 두지 않는다. 연구자 하나가 출처를 약 100개까지 인용할 수 있으므로, 사용자가 정한 최대값에서 검증자 수는 문서상 제한 없이 천 … |
| 012 | `README.md` | lens-adversarial | YAGNI | defer | 판단 훅은 모든 프로젝트에서 새 spec 의 첫 Write 를 거부하지만, 같은 Write 를 다시 실행하면 판단 여부와 무관하게 통과한다. 훅이 강제하는 것은 판단이 아니라 재시도 한 번이다. domain-plugin 은 판단이 필요한 행동과 과잉 … |
| 013 | `skills/audit-repo-docs/SKILL.md` | lens-adversarial |  | design | audit-repo-docs 는 묶어도 문서 하나를 통째로 주라고 한다. 그러나 nested-orchestration 이 스스로 밝히듯 서브 세션의 Read 는 25k 토큰에서 잘린다. 감사 대상 중 docs/domain-discipline.md(77… |
| 014 | `CLAUDE.md` | lens-adversarial | EVIDENCE-FIRST | decide | 채택 규칙은 질문 3개(최대 5개)를 조건마다 한 번씩만 실행해 위반이 하나라도 적으면 채택한다. 그러나 같은 문단은 한 번씩 실행하는 조건에서 흔들림이 차이보다 크다고 인정한다. 그 흔들림이 조항 단위 시험에도 남아 있으면 위반 1건 차이로 문구가 … |
| 015 | `docs/domain-discipline.md` | lens-fit | TERM-ONE | fix | 같은 세 번째 층을 원칙은 '라벨'로 정의하나 이 표는 '이름표'로 부른다. 같은 절의 다른 문단도 이름표를 쓴다. |
| 016 | `docs/domain-discipline.md` | lens-fit | TERM-ONE | fix | `작은 변경` 조항을 '사소한 작업'이라고 부른다. 원칙은 같은 대상을 `작은 변경`으로 이름 짓는다. |
| 017 | `docs/domain-discipline.md` | lens-fit | COUNT-EARNS | fix | '큰 개발 요청 셋(…)'처럼 목록 앞에 개수를 쓰고 수사로 대상을 부른다. |
| 018 | `docs/domain-discipline.md` | lens-fit | NO-MID-MOD | fix | '사용자가 알리지 않은 다른 세션의 작업'은 주어를 가진 관형절이 명사를 앞에서 꾸미는 구조다. 원칙은 그런 관형절을 앞 문장으로 먼저 쓰라고 한다. |
| 019 | `docs/domain-discipline.md` | lens-fit | NO-MID-MOD | fix | '자동 승인 분류기가 커밋을 거부해 이 조항을 지킬 수 없던 일'은 주어를 가진 관형절이 '일'을 앞에서 꾸민다. |
| 020 | `docs/domain-discipline.md` | lens-fit | SUBJECT-OBJECT | fix | '원칙에 옮겼다'의 행위 주체와 옮긴 문안이 없다. 사용자 승인이라는 사실만 있고 누가 어느 줄을 옮겼는지 적히지 않았다. |
| 021 | `docs/domain-discipline.md` | lens-fit | SPECIFIC-NAME | fix | '후보 표'를 이 문서 안에서 가리킬 곳 없이 이름 없이 쓴다. 후보 표는 다른 설계 문서에 있다. |
| 022 | `skills/lens-readability/SKILL.md` | lens-fit | INSTRUCTION-FORM | design | 에이전트에게 주는 지시가 '~하라' 긍정 명령이 아니라 평서형 부정문으로 적혀 있다. 이 스킬 전체가 같은 형태이므로 저장소 공통의 문서 관습일 수 있다. |
| 023 | `skills/lens-readability/SKILL.md` | lens-fit | TERM-ONE | fix | 이 렌즈의 산출물을 '발견이 아니라 제안'이라고 정하고도 이후 절에서 같은 항목을 '지적'으로 부른다. 한 대상에 용어가 둘이다. |
| 024 | `skills/lens-readability/SKILL.md` | lens-fit | COUNT-EARNS | fix | 앞서 이름으로 적은 기준 문서 둘을 이름 대신 개수('둘')로 가리킨다. 「출력 스키마」 절도 where·why·rewrite 를 이름으로 적은 뒤 '셋만 포함한다'고 개수를 붙인다. |
| 025 | `skills/review-specs/SKILL.md` | lens-fit | NO-MID-MOD | fix | '작성자가 자기 글을 보는 self-review'는 주어를 따로 가진 관형절이 명사 앞에 끼어 있다. 「리뷰 기록」 절의 '렌즈가 돌려준 원본'도 같은 꼴이다. |
| 026 | `skills/review-specs/SKILL.md` | lens-fit | COUNT-EARNS | fix | 앞에서 나열한 기준을 이름 대신 개수('셋')로 가리킨다. |
| 027 | `skills/review-specs/SKILL.md` | lens-fit | COUNT-EARNS | fix | 렌즈가 찾는 대상을 '위험 넷'으로 적어 개수로 가리킨다. 이 렌즈 문서는 축이 넷이고 위험은 그중 하나이므로 '위험 넷'이 위험 네 개로도 읽힌다. |
| 028 | `skills/review-specs/SKILL.md` | lens-fit | INSTRUCTION-FORM | design | 지시가 '~하라' 긍정 명령이 아니라 평서형 부정문으로 적혀 있다. 스킬 문서 전반의 관습일 수 있다. |
| 029 | `skills/review-specs/SKILL.md` | lens-fit | TERM-ONE | fix | 같은 행위자를 '메인'과 '메인 세션'과 '내가'로 부른다. |
| 030 | `skills/nested-orchestration/references/sub-session-protocol.md` | lens-fit | NO-MID-MOD | fix | 용어 풀이가 'X는 Y가 Z하는 W다' 꼴이다. 관형절이 자기 주어를 가진 채 명사 앞에 놓인다. |
| 031 | `skills/nested-orchestration/references/sub-session-protocol.md` | lens-fit | COUNT-EARNS | fix | 목록을 시작하는 문장에 개수('두 가지')를 쓴다. 이어지는 괄호에서 두 단계의 이름이 나온다. |
| 032 | `skills/nested-orchestration/references/sub-session-protocol.md` | lens-fit | ONE-ENDING | fix | 한 표의 같은 칸(뜻)에서 어떤 행은 명사구로, 어떤 행은 '적는다' '않는다' 같은 서술문으로 끝난다. |
| 033 | `skills/nested-orchestration/references/sub-session-protocol.md` | lens-fit | INSTRUCTION-FORM | design | 서브 세션이 읽고 따르는 지시가 '~하라' 긍정 명령이 아니라 평서형 부정문으로 적혀 있다. 스킬 문서 전반의 관습일 수 있다. |
| 034 | `skills/nested-orchestration/references/sub-session-protocol.md` | lens-fit | TERM-EXPLAIN | fix | 서브 세션의 용어 풀이와 본문이 '워크스트림'과 '계약 코드'와 '계약 표'를 쓰지만 이 파일 안에 풀이가 없다. 정의는 nested-orchestration/SKILL.md 에만 있다. |
| 035 | `skills/nested-orchestration/references/sub-session-protocol.md` | lens-fit | FULL-SENTENCE | fix | '다음 응답' 칸의 끝 항목이 조각이다. 대상이 응답일 때 무엇을 보내는지가 문장으로 풀려 있지 않다. |
| 036 | `skills/dispatching-lenses/SKILL.md` | lens-fit | COUNT-EARNS | fix | 목록을 시작하는 문장에 개수를 적었다. |
| 037 | `skills/dispatching-lenses/SKILL.md` | lens-fit | COUNT-EARNS | fix | 근거의 개수를 먼저 예고하고 첫째·둘째·셋째로 이어 간다. |
| 038 | `skills/dispatching-lenses/SKILL.md` | lens-fit | NO-ANALOGY | fix | '값의 모양'이 무엇을 가리키는지 이름이 없다. 뒤 문장에서 읽기 비용의 배수로 풀리므로 처음부터 읽기 비용이라고 쓸 수 있다. |
| 039 | `skills/dispatching-lenses/SKILL.md` | lens-fit | SPECIFIC-NAME | fix | '이 금지'가 어느 규칙을 가리키는지 이름이 없다. 앞 단락에는 여러 규칙이 있다(서브에이전트를 새로 열지 않는다, 에이전트 수를 늘리는 길을 차단한다, 한 단계 10개 이하). |
| 040 | `skills/dispatching-lenses/SKILL.md` | lens-fit | TERM-ONE | fix | '묶기'가 두 뜻으로 쓰인다. 한쪽은 렌즈 여럿을 한 호출에 두는 것이고 다른 쪽은 같은 렌즈의 한 호출에 문서 여럿을 두는 것이다. 표의 '묶음 전체' 그룹명은 세 번째 뜻(전체 입력)이다. |
| 041 | `skills/dispatching-lenses/SKILL.md` | lens-fit | DOC-TYPE | design | 절차·계약 문서에 규칙의 변경 경위(장치를 두었다가 뺀 일)가 들어 있다. 이 타입은 수행 방법만 적게 한다. |
| 042 | `skills/dispatching-lenses/SKILL.md` | lens-fit | INSTRUCTION-FORM | design | 작업 지시서에 해당하는 스킬 본문이 금지를 평서형 부정문('~않는다')으로 적는다. 지시는 '~하라' 긍정 명령으로 쓰게 되어 있다. |
| 043 | `README.md` | lens-fit | domain-readme | defer | 첫 설치자에게 필요한 답은 '프로젝트에 새 파일이 생기지 않는다'까지다. 이어지는 옛 관리블록 제거 조건과 잠금 대기 상수는 scaffold.sh의 마이그레이션 구현 설명이고, '규칙은 스킬로 두고 필요할 때 연다'는 DOC-PLACE의 설계 근거다.… |
| 044 | `README.md` | lens-fit | domain-readme | defer | 스크립트 단위로 훅 열세 줄을 이벤트·스크립트·동작·차단 여부로 나열하고, 연결 파일 둘의 구분과 검진 넛지의 면제 규칙까지 적는다. 첫 사용자가 알아야 하는 것은 무엇이 막히고 무엇이 알림인지의 요약과 끄는 법이다. 스크립트 이름과 면제 경로는 훅 … |
| 045 | `README.md` | lens-fit | domain-readme | defer | 푸는 방법(마커 줄, 같은 Write 재실행, 백틱 사용)은 사용자에게 필요하다. 그러나 나눠 맡길 기준과 nested-orchestration 연결은 nested-orchestration 스킬의 절차이고, 산출물 차단의 제외 경로(저장소 문서·Cla… |
| 046 | `README.md` | lens-fit | domain-readme | defer | 사용자에게 필요한 것은 '관리블록에 두 파일의 @import를 쓴다'까지다. 옛 버전이 만든 공용 블록의 제거 순서와 백업 위치는 이전 버전 사용자만 겪는 마이그레이션 구현이다. 옮길 곳은 scripts/scaffold.sh의 은퇴 조건 주석이다. 그… |
| 047 | `README.md` | lens-fit | domain-readme | defer | 자동 갱신이 켜져 있고 뒤처지면 갱신 후 다시 켜라고 알린다는 것까지가 사용자 답이다. curl 2초 제한, 두 명령의 60초 상한, 창 여럿 동시 실행 처리, VS Code가 사본 폴더를 잡은 경우의 git 우회, update.seen과 update… |
| 048 | `README.md` | lens-fit | domain-readme | defer | superpowers가 없으면 설치 명령을 알린다는 것까지가 사용자 답이다. andrej-karpathy-skills를 함께 설치하지 않기를 권하는 이유(조항 중복)는 설계 근거다. 옮길 곳은 docs/domain-discipline.md(출처를 이미… |
| 049 | `README.md` | lens-fit | domain-readme | defer | 환경 변수 이름과 끄는 범위는 사용자 답이다. 그러나 '금지 표현 목록을 고칠 때 검출되지 않게 하려고 변수를 나눠 두었다'는 변수 설계 이유이고 훅 소스 주석에도 있다. 옮길 곳은 hooks/doc_word_pretooluse.sh 머리 주석이다. |
| 050 | `README.md` | lens-fit | domain-readme | defer | 플러그인 사용자는 렌즈를 직접 실행하지 않는다. 렌즈에 원칙 경로를 넣는 규칙은 dispatching-lenses가 소유한 스킬 내부 규칙이다. 옮길 곳은 skills/dispatching-lenses/SKILL.md(이미 소유자)이고 README에는… |
| 051 | `README.md` | lens-fit | domain-readme | defer | 한국어 금지 표현 목록을 모든 세션에 싣는다는 사실은 사용자 답이다. '목록의 원본은 이 저장소의 korean-banned-words.md다'는 유지보수자용 소유 관계이고 그 파일 첫 문단과 CLAUDE.md에 이미 있다. 옮길 곳은 korean-ba… |
| 052 | `README.md` | lens-fit | COUNT-EARNS | defer | 목록을 시작하는 문장에 개수를 적었다. |
| 053 | `README.md` | lens-fit | COUNT-EARNS | defer | 앞에 나온 환경 변수 셋을 개수로 가리킨다. 이름(`DISCIPLINED_CODER_REVIEW_GATE` 등)이나 '위 환경 변수'로 가리켜야 한다. |
| 054 | `README.md` | lens-fit | TERM-EXPLAIN | defer | '넛지'와 '관리블록'을 풀지 않고 쓰며, 같은 동작을 '넛지'(제목·본문)와 '알림'(표의 차단 여부 열)으로 달리 부른다. '하드 게이트'와 '차단'도 같은 구분을 두 이름으로 부른다. |
| 055 | `README.md` | lens-fit | TITLE-LAYERS | defer | 문서에는 ### 소제목 층을 두지 않는다고 정했는데 README에 ### 절이 세 개 있다. 소제목을 ## 절로 올리거나 굵은 라벨 문단으로 바꿔야 한다. |
| 056 | `korean-banned-words.md` | lens-fit | 제외 칸 계약(korean-banned-words.md 서두) | fix | 제외 칸의 `담合`에 한자(合)가 섞여 있다. 파서는 제외어를 글자 그대로 비교하므로 한글 '담합'은 이 제외에 걸리지 않는다. 의도가 '담합'을 제외하는 것이라면 표기가 틀렸다. |
| 057 | `korean-banned-words.md` | lens-fit | INSTRUCTION-FORM | design | 모든 세션에 실리는 지시문인데 금지를 평서형 부정문과 평서형 명령('쓴다')으로 적는다. |
| 058 | `korean-banned-words.md` | lens-fit | ONE-ENDING | fix | 같은 열에 대체 낱말 목록('측정 · 확인')과 행동 지시 문장('가리키는 대상의 이름을 그대로 쓴다', '서술어로 문장을 끝낸다', '에두르지 않고 단정한다')이 섞여 있다. 훅은 이 열을 대체어로 보여 준다. |
| 059 | `agents/prior-art-researcher.md` | lens-fit | INSTRUCTION-FORM | design | 에이전트가 따를 가드를 평서형 부정문('~않는다')으로 적었다. 같은 파일의 앞 단락은 '~하지 마라' 명령형을 쓴다. |
| 060 | `agents/prior-art-researcher.md` | lens-fit | COUNT-EARNS | fix | 목록을 시작하는 문장에 개수를 적었다. |
| 061 | `agents/prior-art-researcher.md` | lens-fit | TERM-ONE | fix | 같은 행위자를 '연구자'와 '검수자'와 '이 렌즈'로 달리 부른다. 모드 단락은 '너는 선행연구 대조 검수자다'로 시작한다. |
| 062 | `agents/prior-art-researcher.md` | lens-fit | ONE-IDEA | fix | 한 단락에 지시 문장이 스무 개 넘게 이어져 있다. 한 단락은 네 문장에서 끊는다. |
| 063 | `skills/domain-pruning/SKILL.md` | lens-fit | DOC-TYPE | design | 절차·계약 문서에 일자가 붙은 측정 결과(검사 건수, 일치율, 카파)가 적혀 있어 상태를 적지 말라는 행의 노후 방지 방법에 어긋난다. |
| 064 | `skills/domain-pruning/SKILL.md` | lens-fit | INSTRUCTION-FORM | design | 수행 절차를 '~한다' 평서문으로 적었다. 할 일은 '~하라' 긍정 명령으로 쓰는 규칙에 어긋난다. |
| 065 | `skills/domain-pruning/SKILL.md` | lens-fit | INSTRUCTION-FORM | design | 평서형 부정문으로 적었다. 금지로 읽히기 때문에 긍정 명령으로 써야 한다. |
| 066 | `skills/domain-pruning/SKILL.md` | lens-fit | SPECIFIC-NAME | fix | '것'이 앞에 나온 '공백'을 다시 가리킨다. 대상의 이름으로 바꿔야 한다. |
| 067 | `skills/domain-pruning/SKILL.md` | lens-fit | SUBJECT-OBJECT | fix | '모았고'의 행위 주체가 적혀 있지 않다. |
| 068 | `skills/domain-pruning/SKILL.md` | lens-fit | ONE-IDEA | fix | 한 단락이 네 문장을 넘어 여덟 문장 가까이 이어진다. |
| 069 | `skills/aggregating-lenses/SKILL.md` | lens-fit | INSTRUCTION-FORM | design | 평서형 부정문으로 적었다. 금지로 읽히기 때문에 긍정 명령으로 써야 한다. |
| 070 | `skills/aggregating-lenses/SKILL.md` | lens-fit | COUNT-EARNS | fix | 앞에 나온 두 단계를 이름 대신 개수로 가리킨다. |
| 071 | `skills/aggregating-lenses/SKILL.md` | lens-fit | NO-STACK-MOD | fix | '상대편' 앞에 수식어가 겹쳐 무엇이 무엇을 꾸미는지 헷갈린다. |
| 072 | `skills/aggregating-lenses/SKILL.md` | lens-fit | SPECIFIC-NAME | fix | '채우는 것'의 '것'이 이름 없이 대상을 가리킨다. |
| 073 | `skills/review-docs/SKILL.md` | lens-fit | COUNT-EARNS | fix | 목록을 시작하는 문장에 목록의 개수(셋, 하나 더)를 적었다. |
| 074 | `skills/review-docs/SKILL.md` | lens-fit | COUNT-EARNS | fix | 종류를 나열하기 전 문장에 종류의 개수(넷)를 적었다. |
| 075 | `skills/review-docs/SKILL.md` | lens-fit | ONE-IDEA | fix | 한 단락이 열 문장을 넘게 이어지며 이름 형식, 차수 규칙, 원본 폴더, 순번, 스크립트 검사, 예외, prior-art 원본 이름을 한꺼번에 다룬다. |
| 076 | `skills/review-docs/SKILL.md` | lens-fit | TERM-ONE | fix | 같은 절차를 '검진'과 '검수'로 달리 불렀다. |
| 077 | `skills/review-docs/SKILL.md` | lens-fit | SPECIFIC-NAME | fix | '잡은 것'의 '것'이 이름 없이 대상을 가리킨다. |
| 078 | `skills/review-docs/SKILL.md` | lens-fit | SUBJECT-OBJECT | fix | 절 자체가 판단의 주체로 쓰였다. |
| 079 | `skills/review-docs/SKILL.md` | lens-fit | INSTRUCTION-FORM | design | 평서형 부정문으로 적었다. 금지로 읽히기 때문에 긍정 명령으로 써야 한다. |
| 080 | `skills/nested-orchestration/SKILL.md` | lens-fit | INSTRUCTION-FORM | design | 행동을 '~하라' 명령이 아닌 '현재 세션은 …한다' 평서문으로 적었다. 이 스킬은 에이전트가 따를 지시문인데 할 일 문장 대부분이 평서형이다. |
| 081 | `skills/nested-orchestration/SKILL.md` | lens-fit | INSTRUCTION-FORM | design | 금지 행동을 '~하지 않는다' 평서형 부정문으로 적었다. |
| 082 | `skills/nested-orchestration/SKILL.md` | lens-fit | NO-MID-MOD | fix | 'Y가 Z하는 W다' 꼴의 용어 풀이를 한 문장에 썼다. 관형절 주어 '하위 프로젝트가'가 풀이 문장 가운데 끼어 있다. |
| 083 | `skills/nested-orchestration/SKILL.md` | lens-fit | COUNT-EARNS | fix | 목록을 시작하는 문장에 목록의 개수('두 시점')를 썼다. |
| 084 | `skills/nested-orchestration/SKILL.md` | lens-fit | COMMA-CUT | fix | 연결어미 뒤 쉼표를 쓴 문장에서 다시 쉼표가 필요해지는 곳(나열의 쉼표)에서 문장을 끝내지 않고 이어 썼다. |
| 085 | `skills/nested-orchestration/SKILL.md` | lens-fit | ONE-ENDING | fix | 같은 열의 셀 끝맺음이 섞여 있다. 한 셀은 명사구('계약 코드 작성 중')이고 다른 셀은 '~다'로 끝나는 문장이다. |
| 086 | `skills/domain-plugin/SKILL.md` | lens-fit | DOC-TYPE | design | 절차·계약 문서에 일자가 붙은 측정 결과(2026-10-21 평균 실행 시간)가 적혀 있어 상태를 적지 말라는 행에 어긋난다. |
| 087 | `skills/domain-plugin/SKILL.md` | lens-fit | INSTRUCTION-FORM | design | 평서형 부정문으로 적었다. 금지로 읽히기 때문에 긍정 명령으로 써야 한다. |
| 088 | `skills/domain-plugin/SKILL.md` | lens-fit | SPECIFIC-NAME | fix | '우리 것'이 이름 없이 대상을 가리킨다. |
| 089 | `skills/domain-plugin/SKILL.md` | lens-fit | SUBJECT-OBJECT | fix | 측정의 주체가 적혀 있지 않다. |
| 090 | `skills/domain-plugin/SKILL.md` | lens-fit | ONE-IDEA | fix | 한 단락이 일곱 문장을 넘게 이어지며 스킬, 커맨드, 에이전트 정의의 키 규칙과 YAML 제약을 한꺼번에 다룬다. |
| 091 | `CLAUDE.md` | lens-fit | DOC-TYPE | fix | 규범·인덱스 문서에 CLI 버전별 관측 결과(상태)가 적혀 있어 상태를 적지 말라는 행에 어긋난다. |
| 092 | `CLAUDE.md` | lens-fit | DOC-PLACE | design | 에이전트원칙을 고칠 때만 쓰는 긴 규칙(사본·분리·퇴고·조항 추가 시험 절차)이 항상 싣는 CLAUDE.md 에 들어 있다. 특정 경로에서만 적용되는 규칙은 rules 에 둔다. |
| 093 | `CLAUDE.md` | lens-fit | ONE-IDEA | fix | 한 단락이 열 문장을 넘게 이어지며 시험 질문 구성, 채택 기준, 시험 단위 위치, 실행 명령, 묶음 비교 금지, 상호작용을 한꺼번에 다룬다. |
| 094 | `CLAUDE.md` | lens-fit | EDIT-PRIORITY | fix | 퇴고 기준 목록의 항목 '주체 호응'을 목록 밖에서 다시 한 줄로 적어 같은 이름의 규칙이 두 곳에 있다. |
| 095 | `CLAUDE.md` | lens-fit | INSTRUCTION-FORM | design | 평서형 부정문으로 적었다. 금지로 읽히기 때문에 긍정 명령으로 써야 한다. |
| 096 | `skills/lens-fit/SKILL.md` | lens-fit | COUNT-EARNS | fix | 판정 단계의 개수를 목록 앞 문장에 예고했다. |
| 097 | `skills/lens-fit/SKILL.md` | lens-fit | INSTRUCTION-FORM | design | 서브에이전트에 실리는 지시문에 평서형 부정문이 있다. 할 일을 긍정 명령으로 적지 않았다. |
| 098 | `skills/lens-consistency/SKILL.md` | lens-fit | NO-MID-MOD, SPECIFIC-NAME | fix | 용어 풀이가 'X는 Y가 Z하는 W다' 꼴이다. 관형절 '값이 다른'이 자기 주어를 갖고 '것들'을 꾸미며, '것들'은 대상의 이름이 아니다. |
| 099 | `skills/review-llm-calls/SKILL.md` | lens-fit | BULLET-SCOPE | fix | 불릿 항목이 두 문장으로 쓰였다. 설명이 두 문장 이상이면 문단으로 쓰라는 조항과 어긋난다. |
| 100 | `skills/review-llm-calls/SKILL.md` | lens-fit | TERM-ONE | fix | '등급'이 두 뜻으로 쓰였다. 체크리스트 도입은 등급이 문서가 미리 정한 고정값이고 렌즈가 매기는 값이 아니라고 하는데, 조립 절 로그 문장은 값을 '등급을 매겨 가리고'라고 마스킹 동작으로 쓴다. |
| 101 | `skills/review-llm-calls/SKILL.md` | lens-fit | ANTI-LIMIT | fix | 'A가 아니라 B' 대구를 한 문서에서 서두에 쓰고 체크리스트 도입에서 '이지 ~가 아니다' 꼴로 한 번 더 썼다. 두 번째는 A를 빼고 B만 단정문으로 써야 한다. |
| 102 | `skills/lens-adversarial/SKILL.md` | lens-fit | COUNT-EARNS | fix | 축의 개수를 목록 앞 문장에 예고했다. |
| 103 | `skills/lens-adversarial/SKILL.md` | lens-fit | SPECIFIC-NAME | fix | '그 제안'이 가리키는 대상이 같은 단락에 없다. 위험 항목은 위험이 남았는지 보는 항목이고 제안은 도입되지 않았다. |
| 104 | `skills/lens-grounding/SKILL.md` | lens-fit | NO-MID-MOD | fix | 관형절이 자기 주어를 갖고 명사를 꾸민다('그 문서가 주장하는 대상 코드', '그 문서가 이름으로 부른 소유자 문서'). 관형절 두 개가 한 문장에 겹쳐 있다. |
| 105 | `skills/lens-grounding/SKILL.md` | lens-fit | ONE-IDEA | fix | 한 문장에 호출자의 프롬프트 구성과 경로 부재의 결과가 함께 들어 있고, 단락이 다섯 문장이다. |
| 106 | `agents/prior-art-verifier.md` | lens-fit | COUNT-EARNS | fix | 축의 개수를 목록 앞에 적었다. 개수 없이 축 이름만 나열하면 된다. |
| 107 | `agents/prior-art-verifier.md` | lens-fit | SPECIFIC-NAME | fix | 문장 끝 대상이 '것'이다. text 가 근거 지도 항목일 때 무엇을 적은 값인지 이름이 없다. |
| 108 | `docs/domain-korean.md` | lens-fit | TITLE-LAYERS | defer | 목차(절 제목)에 결론이 들어 있다. 절 제목은 개념만 가리키는 명사구여야 하고 결론은 첫 문장으로 가야 한다. PLAIN-KO·KO-SYNTAX·PROSE-FORM·UNPACK 절 제목도 '낱말을 고른다'·'문장을 짓는다'처럼 서술어로 끝난다. |
| 110 | `docs/domain-korean.md` | lens-fit | NO-MID-MOD | fix | '조항 없는 모델이 어기는 질문'은 주어를 따로 가진 관형절이 명사를 문장 중간에서 꾸민다. NO-MID-MOD 는 그 내용을 앞 문장으로 먼저 쓰고 본 문장에서는 '그 건'처럼 가리키라고 한다. |
| 111 | `docs/domain-korean.md` | lens-fit | ONE-IDEA | fix | 측정 문단이 한 단락에 여덟 문장 이상을 잇는다. ONE-IDEA 는 단락이 네 문장에 이르면 새 단락을 시작하라고 한다. 같은 형태가 NO-MID-MOD·ANTI-LIMIT·SUBJECT-OBJECT·BULLET-SCOPE·COUNT-EARNS·SE… |
| 112 | `docs/domain-korean.md` | lens-fit | FULL-SENTENCE | fix | '출력 언어 문단(시험 단위 OUTPUT-LANG):' 은 주어와 서술어가 없는 명사구에 콜론을 붙인 단락이다. FULL-SENTENCE 는 본문을 주어와 서술어를 갖춘 문장으로 끝까지 쓰라고 한다. |
| 113 | `docs/domain-korean.md` | lens-fit | COUNT-EARNS | fix | 목록 개수를 알리는 문장이 목록 앞에 있다. COUNT-EARNS 는 목록을 시작하는 문장에 개수를 쓰지 말라고 한다. |
| 114 | `docs/domain-korean.md` | lens-fit | COUNT-EARNS | fix | '근거는 둘이다'로 개수를 먼저 알린 뒤 첫째·둘째를 잇는다. COUNT-EARNS 는 목록 시작 문장의 개수를 쓰지 말라고 한다. NO-MIRROR 절의 '근거는 두 가지다'도 같은 형태다. |
| 115 | `docs/domain-korean.md` | lens-fit | COUNT-EARNS | fix | '둘 중 하나만으로는'에서 수사 '둘'이 앞에 나온 대상(UNPACK 과 금지 표현 표)을 이름 대신 개수로 가리킨다. COUNT-EARNS 는 앞에 나온 대상을 개수 대신 이름으로 가리키라고 한다. |
| 116 | `docs/domain-korean.md` | lens-fit | SUBJECT-OBJECT | fix | 측정을 판단의 주체로 쓴다. 측정은 차이를 잡거나 가리는 행위자가 아니며, 시험을 실행하고 판정한 주체(사람 또는 도구)가 문장에 없다. SUBJECT-OBJECT 는 문서·문장·결과를 판단의 주체로 쓰지 말고 주체를 적으라고 한다. |
| 117 | `skills/agent-prior-art/SKILL.md` | lens-fit | INSTRUCTION-FORM | design | 연구자가 따를 지시를 평서형 부정문으로 썼다. 연구자 에이전트가 읽고 따를 지시문인데 하지 마라 명령이 아니라 하지 않는다 서술이라 금지인지 현재 상태 서술인지 추정해야 한다. |
| 118 | `skills/agent-prior-art/SKILL.md` | lens-fit | INSTRUCTION-FORM | design | 연구자에게 주는 지시를 로 쓰지 않는다 평서형 부정문으로 썼다. |
| 119 | `skills/agent-prior-art/SKILL.md` | lens-fit | COUNT-EARNS | fix | 목록을 시작하는 문장에서 항목 개수(네 축)를 예고했고 다음 문장에서 넷으로 다시 가리켰다. 이름(목적·메커니즘·평가·적용 대상)이 바로 뒤에 나열되므로 개수는 결론을 받치는 숫자가 아니다. |
| 120 | `skills/agent-prior-art/SKILL.md` | lens-fit | TERM-ONE | fix | 선행연구 에이전트는 렌즈가 아니라고 같은 문서가 선언했는데 표 셀에서 이 렌즈라고 불렀다. 한 대상을 두 이름(에이전트, 렌즈)으로 가리킨다. |
| 121 | `skills/agent-prior-art/SKILL.md` | lens-fit | DOC-TYPE | fix | 절차·계약 문서에 이 PC의 키 보유 상태라는 현재 상태를 적었다. 타입 표는 절차·계약에 상태를 적지 말고 방법만 적으라고 정한다. |
| 122 | `docs/korean-banned-words-evidence.md` | lens-fit | TITLE-LAYERS | fix | 절 제목이 명사구가 아니라 쓴다·않는다로 끝나는 서술문이다. 목차는 개념만 가리키는 명사구여야 하고, korean-banned-words.md 도 절 제목은 명사구로 쓰라고 정한다. |
| 123 | `agent-principles.md` | lens-fit | COMMA-CUT | defer | 한 문장에서 연결어미 뒤 쉼표를 둘 썼다. |
| 124 | `agent-principles.md` | lens-fit | COMMA-CUT | defer | 한 문장에서 연결어미 뒤 쉼표를 넷 썼다. |
| 125 | `agent-principles.md` | lens-fit | NO-MID-MOD | defer | 주어를 따로 가진 관형절을 명사 앞에 두었다. |
| 126 | `agent-principles.md` | lens-fit | NO-MID-MOD | defer | 주어를 따로 가진 관형절을 명사 앞에 두었다. |
| 127 | `agent-principles.md` | lens-fit | NO-MID-MOD | defer | 주어를 따로 가진 관형절을 명사 앞에 두었다. |
| 128 | `agent-principles.md` | lens-fit | SPECIFIC-NAME | defer | 대상을 가리키는 '것'을 이름 대신 썼다. |
| 129 | `agent-principles.md` | lens-fit | SPECIFIC-NAME | defer | 대상을 가리키는 '것'을 이름 대신 썼다. |
| 130 | `agent-principles.md` | lens-fit | ONE-ENDING | defer | 같은 열의 요소 중 한 칸만 평서문으로 시작해 말끝이 갈린다. |
| 131 | `skills/audit-repo-docs/SKILL.md` | lens-fit | DOC-TYPE | design | 수행 방법을 적는 문서에 이전 차수의 상태(배정 근거가 바뀐 이력)를 적었다. |
| 132 | `skills/audit-repo-docs/SKILL.md` | lens-fit | INSTRUCTION-FORM | design | 평서형 부정문으로 지시를 적어 금지로 읽히게 했다. |
| 133 | `skills/audit-repo-docs/SKILL.md` | lens-fit | INSTRUCTION-FORM | design | 평서형 부정문으로 지시를 적어 금지로 읽히게 했다. |
| 134 | `skills/audit-repo-docs/SKILL.md` | lens-fit | INSTRUCTION-FORM | design | 평서형 부정문으로 지시를 적어 금지로 읽히게 했다. |
| 135 | `skills/audit-repo-docs/SKILL.md` | lens-fit | INSTRUCTION-FORM | design | 평서형 부정문으로 지시를 적어 금지로 읽히게 했다. |
| 136 | `skills/audit-repo-docs/SKILL.md` | lens-fit | COUNT-EARNS | fix | 앞에 나온 대상을 이름 대신 개수로 가리켰다. |
| 137 | `skills/audit-repo-docs/SKILL.md` | lens-fit | COUNT-EARNS | fix | 앞에 나온 대상을 이름 대신 개수로 가리켰다. |
| 138 | `skills/audit-repo-docs/SKILL.md` | lens-fit | SPECIFIC-NAME | fix | 절 제목이 '것'으로 끝나 대상의 이름이 없다. |
| 139 | `skills/audit-repo-docs/SKILL.md` | lens-fit | SPECIFIC-NAME | fix | 절 제목이 '것'으로 끝나 대상의 이름이 없다. |
| 140 | `skills/audit-repo-docs/SKILL.md` | lens-fit | SPECIFIC-NAME | fix | 불릿 라벨이 '것'으로 끝나 처분의 이름이 없다. |
| 141 | `skills/audit-repo-docs/SKILL.md` | lens-fit | NO-MID-MOD | fix | 주어를 따로 가진 관형절을 명사 앞에 두었다. |
| 142 | `skills/domain-readme/SKILL.md` | lens-fit | INSTRUCTION-FORM | design | 평서형 부정문으로 지시를 적어 금지로 읽히게 했다. |
| 143 | `skills/domain-readme/SKILL.md` | lens-fit | INSTRUCTION-FORM | design | 평서형 부정문으로 지시를 적어 금지로 읽히게 했다. |
| 144 | `skills/domain-readme/SKILL.md` | lens-fit | INSTRUCTION-FORM | design | 평서형 부정문으로 지시를 적어 금지로 읽히게 했다. |
| 145 | `skills/domain-readme/SKILL.md` | lens-fit | NO-MID-MOD | fix | 절 제목이 주어를 따로 가진 관형절로 명사를 꾸민다. |
| 146 | `skills/domain-readme/SKILL.md` | lens-fit | COUNT-EARNS | fix | 앞에 나온 대상을 이름 대신 개수로 가리켰다. |
| 147 | `skills/domain-readme/SKILL.md` | lens-fit | SPECIFIC-NAME | fix | 절 제목에 '것'을 이름 대신 썼다. |
| 148 | `commands/show-principles.md` | lens-fit | WRITTEN-ONLY | fix | 구어 축약 '보여줘라'를 썼다. |
| 149 | `commands/show-principles.md` | lens-fit | INSTRUCTION-FORM | fix | 한 문장에서 명령형과 평서형으로 행동 지시를 섞어 적었다. |
| 150 | `commands/show-principles.md` | lens-fit | NO-MID-MOD | fix | 주어를 따로 가진 관형절을 명사 앞에 두었다. |
| 151 | `docs/domain-discipline.md` | lens-grounding | CHECKABLE | fix | `CHECKABLE` 의 셋을 사용자와 합의한 현행 수치로 적었으나 현행 원칙은 단계 둘 이상을 기준으로 삼는다. 같은 문서의 `CHECKABLE` 절도 둘 이상으로 바뀌었다고 적어 머리말만 옛 값이다. |
| 152 | `docs/domain-discipline.md` | lens-grounding | SUB-ORCHESTRATE | fix | '지금 문구'로 brainstorming 분해 시점과 설계 승인 뒤 plan 전 두 시점의 문장을 인용하나, 현행 원칙 조항은 독립된 하위 프로젝트 둘 이상이면 설계 문서 유무와 무관하게 판단하게 하는 문구다. 같은 절 끝에서 문구를 바꿨다고 적지만 … |
| 153 | `docs/domain-discipline.md` | lens-grounding | LABEL-NOUN | fix | 이 절은 라벨 규칙에 다이어그램 노드 포함과 이음말 금지가 있고 문구가 바뀌지 않았다고 적으나, 현행 `LABEL-NOUN` 조항에는 그 두 내용이 없다. |
| 154 | `docs/domain-discipline.md` | lens-grounding | TITLE-PROOF | fix | '제목과 부딪히는 근거는 같은 곳에 남겨라' 문장을 조항에 있는 것처럼 설명하나 현행 `TITLE-PROOF` 조항에는 그 문장이 없고, 분석에서 뺀 대상과 기준을 같은 절에 밝히라는 문장이 있다. |
| 155 | `docs/domain-discipline.md` | lens-grounding | TITLE-CLAIM | fix | 흐리는 서술어를 금지하는 문장을 불확실성 문장과 함께 둔다고 적으나, 현행 `TITLE-CLAIM` 조항에는 흐리는 서술어를 금지하는 문장이 없다. |
| 156 | `docs/domain-discipline.md` | lens-grounding | EVIDENCE-FIRST | fix | 순차 334초와 동시 219초와 프로그램 시작 64밀리초의 실측을 이 문서가 근거로 들고, 저장소 CLAUDE.md 는 그 실측이 이 문서에 있다고 되돌려 가리킨다. 두 문서 어디에도 원자료가 없다. |
| 157 | `skills/lens-readability/SKILL.md` | lens-grounding | TITLE-CLAIM | fix | 슬라이드 제목을 포함한 본문 제목 전체를 결론 한 문장으로 쓰라고 정하는데, 에이전트원칙 TITLE-CLAIM 은 슬라이드 제목을 수치 없는 명사구로 40자 안에 쓰고 문서의 본문 제목만 한 문장으로 쓰라고 정한다. 같은 문서의 「반드시 읽히는 곳의 … |
| 158 | `skills/review-specs/SKILL.md` | lens-grounding | NO-ASSUME | fix | 렌즈를 두 번씩 실행하던 때의 측정을 '세 차수'로 적는데, 그 수치를 낸 spec 은 이 레포에서 '네 회차'를 쟀다고 적는다. 21%~55%라는 범위는 네 회차 값에서 나온 것이다. |
| 159 | `skills/review-specs/SKILL.md` | lens-grounding | NO-ASSUME | fix | 마커가 안 남은 채 끝나면 그 턴에 아무 신호가 없다고 적지만, 같은 문서와 Stop 훅은 미리뷰 spec·plan 이 남은 채 턴이 끝나려 하면 한 번 차단한다고 정한다. 신호가 없는 때는 차단 뒤의 두 번째 종료부터이고, 이 문서의 「한계」 절도 … |
| 160 | `skills/dispatching-lenses/SKILL.md` | lens-grounding | audit-repo-docs | fix | 레포 문서 감사에서 lens-consistency를 몇 번 실행하는지 두 문서가 다르게 적는다. 이 문서는 값이 다른 짝 묶음을 한 호출에 준다고 하고, audit-repo-docs는 값이 다른 짝마다 적용한다고 한다. |
| 161 | `skills/dispatching-lenses/SKILL.md` | lens-grounding | agent-prior-art | fix | 한 단계의 에이전트 상한 10개에 대한 예외를 이 문서는 3층 오케스트레이션 하나만 적는다. agent-prior-art는 같은 문구를 인용하며 선행연구 에이전트를 예외로 정했다고 적는다. |
| 162 | `korean-banned-words.md` | lens-grounding | korean-banned-words | decide | 표의 초록불 행은 네 낱말을 금지하는데 근거 문서는 2026-09-24에 초록불·초록색 둘로 좁혔다고 적고 파란불과 녹색의 근거를 적지 않는다. |
| 163 | `agents/prior-art-researcher.md` | lens-grounding | agent-prior-art | fix | 근거 지도 행의 adoption을 언제 채우는지 이 정의는 적지 않는다. 원본은 기존 도구 탐색 상황에서만 채운다고 한다. |
| 164 | `skills/domain-pruning/SKILL.md` | lens-grounding | lens-grounding | fix | 이 문서는 런타임 리뷰가 출력 종류마다 두 렌즈 중 하나만 고른다고 적었으나, 소유 문서의 렌즈 선택 표에는 두 렌즈를 함께 적용하는 호출 종류가 있다. |
| 165 | `skills/domain-pruning/SKILL.md` | lens-grounding | domain-pruning | fix | 분류 표는 판단보류의 처분을 '남기고 이유를 적는다'로 정했으나, 절차 3단계는 판단보류의 처분을 사용자가 정한다고 적었다. |
| 166 | `skills/nested-orchestration/SKILL.md` | lens-grounding | OTHER-SESSIONS | decide | 서로 독립된 큰 작업이 다른 저장소에 있을 때 현재 세션이 그 저장소에서 git 으로 워크트리와 브랜치를 만들고 통합하도록 정했는데, 에이전트원칙 OTHER-SESSIONS 는 다른 저장소를 git 으로 제어하지 못하게 하고 예외를 이 세션 브랜치의 … |
| 167 | `skills/nested-orchestration/SKILL.md` | lens-grounding | STATE-ASSUME | fix | 서브에이전트 화면에서 워크트리 배정이 보이지 않는다는 단정과 사용자만 그 화면에 들어간다는 단정이 근거 문서에 없다. 근거 문서는 집계 화면과 메트릭이 없다는 것까지만 적는다. |
| 168 | `skills/nested-orchestration/SKILL.md` | lens-grounding | FOCUSED | fix | SKILL.md 를 현재 세션용으로 두어 25k 토큰 읽기 상한을 피하게 했다고 근거 문서가 적는데, 지금 SKILL.md 자체가 그 상한을 넘는다. |
| 169 | `skills/domain-plugin/SKILL.md` | lens-grounding | lens-grounding | fix | description 이 언제 여는지를 포함해야 한다는 요구가 커맨드에도 적용된다고 적었으나, 이 저장소의 커맨드 파일 description 에는 언제 여는지가 없다. |
| 170 | `CLAUDE.md` | lens-grounding | lens-grounding | fix | CLAUDE.md 는 검진 넛지가 리뷰 기록만 빼고 본다고 적었으나, README 는 저장소에 커밋되는 작업 문서에도 뜨지 않는다고 적었고 훅 코드는 spec·plan 도 뺀다. |
| 171 | `CLAUDE.md` | lens-grounding | lens-grounding | fix | 규칙 넛지가 세션의 첫 도구 호출에 뜬다고 적었으나, 훅은 첫 Write·Edit·Bash 호출에만 뜬다. |
| 172 | `CLAUDE.md` | lens-grounding | lens-grounding | decide | CLAUDE.md 는 금지문을 불변 조건에만 쓴다고 정했으나, 에이전트원칙의 여러 조항은 불변 조건이 아닌 일에 금지문('~마라')을 쓴다. |
| 173 | `CLAUDE.md` | lens-grounding | lens-grounding | defer | 에이전트원칙에는 행동 지시와 그 이유 한 줄을 적는다고 정했으나, 이유 문장이 없는 조항이 있다. |
| 174 | `skills/lens-fit/SKILL.md` | lens-grounding | STATE-ASSUME | fix | 스키마의 필수 키와 폐쇄 집합의 값을 검사하는 몫을 test_docs_drift.sh 가 진다고 적었다. 그 스크립트가 대조하는 대상은 렌즈 SKILL.md 의 출력 스키마 사본이다. 레포 문서 감사에서 렌즈 원본의 칸을 보는 검사는 audit_ver… |
| 175 | `skills/lens-consistency/SKILL.md` | lens-grounding | STATE-ASSUME | fix | description 은 커버리지 공백을 spec·plan 에만 붙여 쓰지만 체크리스트는 레포 문서 감사에서도 커버리지 공백을 적용한다. description 만 읽는 호출자에게는 레포 감사의 커버리지 공백이 빠진 렌즈로 읽힌다. |
| 176 | `skills/review-llm-calls/SKILL.md` | lens-grounding | STATE-ASSUME | fix | 로그에 사용자 입력을 복제하는 것을 SECRETS 가 금지한다고 적었다. SECRETS 가 적지 말라는 대상은 키·토큰·비밀번호다. |
| 177 | `skills/review-llm-calls/SKILL.md` | lens-grounding | STATE-ASSUME | fix | 요청·지연·토큰·실패율 로깅의 근거로 NO-ASSUME 을 댔다. NO-ASSUME 은 상태·원인·이전 결정을 말하거나 그것에 기대 행동하기 전에 확인하라는 조항이다. |
| 178 | `skills/review-llm-calls/SKILL.md` | lens-grounding | STATE-ASSUME | fix | 커버리지 공백이 렌즈 둘 이상이라야 의미가 있다고 적었다. 집계 계약의 커버리지 공백은 배정된 렌즈가 결과 JSON 을 돌려주지 않은 경우도 포함하므로 렌즈 하나인 호출 종류에서도 의미가 있다. 렌즈 하나인 호출은 집계를 두지 않아 그 공백을 표시하는… |
| 179 | `skills/lens-adversarial/SKILL.md` | lens-grounding | STATE-ASSUME | fix | evidence 칸에 단순화 근거를 적게 했다. 공통 계약의 evidence 는 지적한 곳 파일에 있는 그대로의 문장이다. 레포 문서 감사의 audit_evidence.sh 는 evidence 를 파일에서 글자 그대로 찾으므로 근거 설명 문장은 인용으… |
| 180 | `skills/lens-grounding/SKILL.md` | lens-grounding | STATE-ASSUME | fix | 검진과 감사의 호출자가 에이전트원칙 경로와 목적 한 줄과 계약 경로만 넣도록 되어 있다고 적었다. 그런 규정을 둔 문서를 찾지 못했다. 목적 한 줄은 lens-readability 승인 문서에만 주는 것으로 정해져 있다. |
| 181 | `agents/prior-art-verifier.md` | lens-grounding | NO-ASSUME | fix | 판정 기준이 하나라고 적은 직후 근거 지도 항목에는 다른 기준(사례가 있다는 것과 그 결말을 뒷받침하는 구절)을 적었다. 같은 모드 안에서 기준이 둘이다. |
| 182 | `docs/domain-korean.md` | lens-grounding | VOCAB-PREF | fix | 2026-10-18 재편 문단은 영어 원어 문장을 에이전트원칙 「출력」 머리의 언어 문단이 같은 지시를 하므로 지웠다고 적는다. 같은 절의 2026-10-21 문단은 그 문장을 다시 넣은 후보를 원칙에 옮겼다고 적고, 지금 agent-principle… |
| 183 | `docs/domain-korean.md` | lens-grounding | TERM-ONE | fix | 이 절은 무리의 소속을 목록 파일의 분류 칸이 소유한다고 하면서 무리 이름을 「무엇이든 가리킬 수 있는 넓은 말」과 「영어를 그대로 옮긴 것」으로 적는다. 목록과 근거 파일의 분류 값은 「대명사처럼 쓰는 말」과 「영어를 직역한 것」이다. 두 이름이 분… |
| 184 | `docs/domain-korean.md` | lens-grounding | NO-ASSUME | fix | 측정 문단은 지시형 트랙을 금지어 목록의 표 상황 칸과 대체어 칸으로 만들었다고 적는다. 목록 파일의 표 머리는 쓰지 않는 말·대신 쓰는 말·적용 대상·분류·제외 다섯이고 상황 칸이 없다. |
| 185 | `docs/domain-korean.md` | lens-grounding | CHECKABLE | fix | 삭제한 NAME-ITEMS 의 근거 문단은 CHECKABLE 이 단계에 번호를 붙이라고 한다고 적는다. 지금 CHECKABLE 줄은 각 단계 문장 안에 확인 방법을 함께 쓰라고만 하고, 번호는 예시 문장에 있을 뿐 지시가 아니다. |
| 186 | `docs/korean-banned-words-evidence.md` | lens-grounding | EVIDENCE-FIRST | decide | 근거 문서는 2026-09-24 에 대상을 초록불·초록색으로 좁혔다고 적었다. 그런데 금지어 목록의 같은 행은 파란불과 녹색까지 담고 있다. |
| 187 | `docs/korean-banned-words-evidence.md` | lens-grounding | EVIDENCE-FIRST | fix | 끈 사유가 만자당 0.15 로 기준선 0.15 미만이라고 적었다. 0.15 는 0.15 미만이 아니어서 같은 문장 안에서 수치와 판정이 맞지 않는다. 다른 끈 항목은 0.14 이하다. |
| 188 | `agent-principles.md` | lens-grounding | EDIT-PRIORITY | defer | docs/domain-discipline.md 는 EDIT-PRIORITY 의 쉼표를 하나 이하가 되게 고쳤다고 적는다. 그러나 2026-10-21 에 원칙으로 옮긴 EDIT-PRIORITY 줄은 연결어미 뒤 쉼표를 둘 쓴다. |
| 189 | `skills/audit-repo-docs/SKILL.md` | lens-grounding | audit-repo-docs | fix | 같은 문단이 대조 대상을 앞선 diff.json 전체로 적고, 다른 문장에서는 잔존으로 적힌 항목을 대조 대상에서 뺀다. |
| 190 | `skills/audit-repo-docs/SKILL.md` | lens-grounding | audit-repo-docs | fix | 같은 지문의 발견을 기계가 합친다고 적었으나 이를 실행하는 스크립트가 없다. |
| 191 | `skills/audit-repo-docs/SKILL.md` | lens-grounding | dispatching-lenses | fix | lens-consistency 를 값이 다른 짝마다 적용한다고 적었으나 dispatching-lenses 는 값이 다른 짝 묶음을 한 호출에 준다고 정한다. |
| 192 | `skills/domain-readme/SKILL.md` | lens-grounding | BOTTOM-LINE | fix | 결론 우선 규칙의 소유 조항을 상위 묶음 이름 READ-FLOW 로 가리킨다. 그 규칙을 정한 조항은 BOTTOM-LINE 이다. |
| 193 | `skills/domain-readme/SKILL.md` | lens-grounding | domain-readme | fix | 독자 질문 넷 중 '누가 만들었는가'에 답하는 자리가 권장 동선에 없다. |
| 194 | `skills/lens-readability/SKILL.md` | lens-consistency |  | fix | `rewrite` 칸의 뜻을 누가 정하는지를 두 소유자 문서가 서로 다르게 선언한다. lens-readability는 `rewrite`를 자기 문서가 정하고 공통 계약은 다루지 않는다고 하고, aggregating-lenses는 같은 칸을 자기 소유 … |
| 195 | `docs/domain-discipline.md` | lens-consistency | SUB-ORCHESTRATE | fix | domain-discipline이 `SUB-ORCHESTRATE`의 '지금 문구'라고 인용한 조건(brainstorming을 따르다가 분해하기로 했을 때)이 소유자 agent-principles.md의 현행 조항(독립된 하위 프로젝트가 둘 이상으로 나… |
| 196 | `CLAUDE.md` | lens-consistency | NO-ANALOGY | decide | CLAUDE.md는 에이전트원칙의 금지문을 불변 조건(비밀, 되돌릴 수 없는 삭제와 외부 전송, 다른 세션의 저장소)에만 쓰라고 정하는데, 소유자 쪽 agent-principles.md의 조항들은 그 목록 밖의 일에도 '~하지 마라' 금지문을 쓴다(예… |
| 197 | `skills/nested-orchestration/SKILL.md` | lens-consistency | OTHER-SESSIONS | decide | agent-principles.md의 `OTHER-SESSIONS`는 현재 작업 중인 브랜치가 아닌 브랜치와 워크트리와 다른 저장소를 git으로 제어(체크아웃·커밋·병합·리셋·삭제)하지 못하게 하고 예외를 main 병합 하나로 한정한다. nested-… |
| 198 | `skills/agent-prior-art/SKILL.md` | lens-consistency |  | fix | agent-prior-art가 dispatching-lenses의 에이전트 수 상한에서 자기를 뺀다고 선언하지만, 그 상한의 소유자 문서는 예외로 `nested-orchestration`의 서브 세션 하나만 적고 선행연구 에이전트의 예외를 모른다. 소… |
| 199 | `skills/audit-repo-docs/SKILL.md` | lens-consistency |  | fix | 커버리지 공백(규칙 호출 쪽 누락). 소유자 문서 보기가 소유를 선언한 문서마다 `lens-consistency` 호출을 하나씩 더하게 하지만, 이 호출 수를 한 단계 에이전트 상한 10개에 맞추는 묶기 규칙이 audit-repo-docs 안에 없다.… |
| 200 | `skills/aggregating-lenses/SKILL.md` | lens-consistency |  | design | 커버리지 공백(소유한 칸을 쓰는 곳 없음). aggregating-lenses가 소유 목록에 올린 `narrowed`(좁혀 적기 개수)와 `pairs`(짝마다의 판정)를 읽거나 기록하는 문서나 스크립트가 없다. audit-repo-docs의 「일관성 … |
| 201 | `skills/review-docs/SKILL.md` | lens-consistency | ASK-OPTIONS | decide | review-docs는 검진 여부와 `lens-readability`와 선행연구 에이전트를 한 질문의 선택지에 합쳐 한 번만 묻게 하지만, `ASK-OPTIONS`는 결정을 한 번에 한 건씩 묻게 한다. |

기각한 발견은 아래와 같다.

- 109 `docs/domain-korean.md` — domain-korean.md 의 `###` 조항 ID 절은 scripts/_doc_keys.sh 와 test_docs_drift.sh 가 조항 ID 절 제목으로 대조하는 구조다. 근거 문서의 정당한 설계다.

## 차수 대조

직전 차수 2026-10-12-self-audit 의 발견 162건을 대조했다. 확정이었던 발견 중 해소 134건, 잔존 23건이다. 기각이었던 발견 중 잔존 4건, 해소 1건이다. 재발은 없다. 앞선 차수 해소율은 0.854다.
## 되풀이되는 근본 원인

**스킬과 에이전트 정의의 평서형 지시.** `INSTRUCTION-FORM` 위반 24건이 스킬 열네 곳과 `agents/prior-art-researcher.md` 에서 같은 모양으로 나왔다. 저장소 CLAUDE.md 의 「명령형」 규칙은 에이전트원칙에만 걸려 있고, 스킬은 "~한다" 평서형으로 쓰는 관례가 그대로 복제되었다. 스킬 문체 규칙을 한 곳에 정하고 스킬 전체를 한 단계에서 바꾸거나, 스킬은 예외로 둔다고 원칙에 적어야 한꺼번에 사라진다.

**절차·계약 문서에 쌓인 측정 이력.** `DOC-TYPE` 위반 4건(`dispatching-lenses`, `domain-pruning`, `domain-plugin`, `audit-repo-docs`)이 같은 모양이다. 측정 기록을 근거 문서(`docs/domain-*.md`)에 두는 규칙은 원칙 조항에만 있고 스킬에는 없다. 스킬의 측정 문장을 근거 문서로 옮기는 정리와, 스킬에 측정을 적지 못하게 하는 검사가 함께 있어야 한다.

**에이전트원칙 조항 줄의 문체.** `agent-principles.md` 조항 줄 위반 9건은 클린룸 시험 없이 고칠 수 없다. 조항 문구 변경 절차가 비용이 커서 문체 위반이 조항 줄에 남는다.

**감사 절차와 실제 실행의 불일치.** `audit_targets.sh` 가 `evals/` 를 대상에 넣고, 소유자 문서 호출과 상한의 관계가 문서에 없었다. 이번 차수에 `audit-repo-docs`·`dispatching-lenses` 의 서술은 실제 실행에 맞췄으나, 스크립트는 바꾸지 않았다.

## 사용자에게 올릴 질문

- `nested-orchestration` 과 `OTHER-SESSIONS` 의 충돌(#001·#166·#197): 2026-10-21 사용자가 '스킬에 예외 포인터'를 골랐다.
- `audit_targets.sh` 의 `evals/` 포함(#002)
- `작은 변경` 의 생략 범위와 Stop 게이트(#006)
- `EDIT-PRIORITY` 가 .md 외 산출물에서 작동하지 않는 점(#007)
- 조항 채택 규칙의 흔들림(#014)
- CLAUDE.md 의 '금지문은 불변 조건에만' 규칙과 원칙의 '~마라' 조항(#172·#196)
- 금지어 표 초록불 행과 근거 문서의 불일치(#162·#186)
- `review-docs` 의 합친 질문과 `ASK-OPTIONS`(#201)
