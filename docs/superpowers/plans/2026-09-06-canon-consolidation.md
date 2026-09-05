# 정본 통합 구현 계획

설계는 `docs/superpowers/specs/2026-09-06-canon-consolidation-design.md`다. 이 계획은 그 설계를 태스크로 가른다.

작업 폴더는 `D:/projects/disciplined-coder/.claude/worktrees/canon`이고 브랜치는 `canon-consolidation`이다. 다른 워크트리는 디렉터리 `.claude/worktrees/lens-docs`이고 브랜치는 `lens-doc-principles`다. 아래에서 그쪽을 부를 때는 브랜치 이름을 쓴다.

## 시작 상태

`agent-principles.md`가 이미 175줄로 다시 쓰여 있다. 그래서 시험이 붉다. 실측은 `test_scaffold.sh` PASS=275 FAIL=15, `test_docs_drift.sh` PASS=376 FAIL=8이고 `test_hooks.sh` 101/0, `test_audit.sh` 152/0, `test_assertions.sh` 10/0이다.

## 시험을 고치는 규칙

시험 수정을 마지막 태스크로 몰지 않는다. **그 시험이 판정하는 변경과 같은 태스크에 둔다.** 그래야 태스크마다 초록으로 끝난다는 계약이 실제로 선다. 앞선 계획은 시험을 여덟째 태스크로 몰았고, 그러면 여섯 태스크가 아무 자동 판정 없이 지나간다는 것을 렌즈가 잡았다.

시험을 고칠 때 지킬 것이 셋이다.

**가드를 지우지 않는다.** 단언이 붉으면 그 단언이 겨누던 사실이 아직 참인지 먼저 본다. 참이면 앵커만 새 문구로 옮기고, 거짓이 되었으면 무엇이 그 자리를 대신 지키는지 적은 뒤 바꾼다. 검사를 없애서 초록을 만드는 것은 금지한다.

**부정 grep의 대상이 지워지면 그 단언을 옮긴다.** 파일이 없으면 `grep`이 2로 끝나고 `!`가 참으로 뒤집어, 아무것도 안 보면서 초록으로 세어진다. 대상이 사라지는 부정 단언은 새 대상으로 옮기거나 삭제 사실 자체를 단언하는 것으로 바꾼다.

**새로 만든 파일을 먼저 `git add`한다.** `test_docs_drift.sh` 588행이 금지어 검사 대상을 `git ls-files`로 뽑아, 미추적 파일은 검사를 통째로 면제받는다.

## 정본이 갖는 조항 열넷

T8이 단언할 목록을 여기 못 박는다. 실행 세션이 정본을 읽어 옮겨 적으면 단언의 출처가 단언 대상 자신이 되어, 조항이 하나 떨어져도 그 결손을 정답으로 굳힌다.

`FAIL-LOUD`, `FOCUSED`, `EXPLICIT`, `SSOT`, `NAME-ITEMS`, `REVERSIBLE`, `SECRETS`, `PLAIN-KO`, `KO-SYNTAX`, `PROSE-FORM`, `READ-FLOW`, `IDEMPOTENT`, `EXPLAIN-STRUCTURE`, `LOCAL-FIRST`다.

되살아나면 안 되는 옛 조항은 다섯이다. `ASK-FORK`, `MEASURE-FIRST`, `SIMPLE`, `SURGICAL`, `TDD`다. 이 다섯은 어제 카파시 절로 녹여 이름까지 뺐고 이 회차에서도 되살리지 않는다.

## T1 — 정본의 어긋남 아홉을 고친다

정본 초안이 시험 아홉을 붉게 만들고 있다. 셋은 정본이 틀린 것이고 여섯은 문구가 바뀐 것이다.

**틀린 것 셋.** `docs/rationale-korean.md`는 없는 파일이므로 `skills/domain-korean/SKILL.md`로 바꾼다. `scripts/forbidden_words.tsv`도 안 만들기로 했으므로 같은 파일의 「금지 표현」 절로 바꾼다. 기록 이름 규칙에서 넷이 빠졌으므로 되살린다. 레포 감사의 `self` 주제 꼴, `-audit-2.md` 회차 표기, 렌즈 원본 파일이 `lens-` 접두사를 그대로 쓴다는 것, 그리고 렌즈 원본 이름을 `scripts/audit_verify.sh`가 검사한다는 것이다.

마지막 문장은 앞선 계획이 "이 규칙을 `audit_verify.sh`가 검사한다"로 적었는데 거짓이다. 그 스크립트가 보는 것은 렌즈 원본 `.json` 이름 하나뿐이고 기록 파일 이름 꼴도 `self` 주제도 회차 표기도 보지 않는다. 그래서 "렌즈 원본 이름은 `scripts/audit_verify.sh`가 검사한다"로 범위를 좁혀 적는다.

**문구가 바뀐 것 여섯.** 정본 91행이 `자리·부분·영역·경우`를 낱말 그대로 인용해 금지어 검사 넷이 붉다. 낱말을 인용하지 않고 "무엇이든 가리킬 수 있는 넓은 말 대신 대상의 이름을 그대로 쓴다. 그 목록은 `domain-korean`의 「금지 표현」 표가 소유한다"로 고친다. 이 문장은 `test_docs_drift.sh` 134행이 찾는 `대상의 이름을 그대로 쓴다`도 함께 되살린다.

정본 88행의 `이름을 붙이는 곳(…)은 명사구로 쓰고`를 `이름을 붙이는 위치에만 명사구로 쓰고`로 되돌린다. 524행의 주석이 "검사가 새 자리를 따라가 버려 끊긴 것을 못 잡았다"고 적어 둔 실패라, 앵커를 옮기지 않고 정본을 원래 문구로 돌린다.

`test_scaffold.sh` 417·419·420행이 찾는 세 문자열을 정본에 되살린다. `` `LOCAL-FIRST`는 원칙이 아니라 ``와 `실행 증거 없이`와 `Context handed to a subagent is written into its prompt`다. 내용은 이미 정본에 있고 문구만 다르므로 문구를 원래대로 쓴다.

**검증** — `bash scripts/test_docs_drift.sh`의 FAIL이 8에서 2로 줄고 남은 둘이 지운 스킬 참조뿐이다. `bash scripts/test_scaffold.sh`의 FAIL이 15에서 12로 줄고 417·419·420행이 초록이다. `grep -c 'rationale-korean\|forbidden_words' agent-principles.md`가 0이다. `self-audit`·`-audit-2`·`lens-grounding-1.json`·`audit_verify.sh` 네 문자열이 정본에 있다.

## T2 — 카파시 넛지 가드를 고친다

`test_scaffold.sh` 802행이 이미 깔린 PC에서 scaffold 출력에 `karpathy`가 없어야 한다고 단언하는데, 새 정본 21행이 `andrej-karpathy-skills`를 적고 있어 실패한다.

정본의 출처 표기는 남긴다. 그 대신 단언을 좁힌다. 지금은 낱말 `karpathy`의 부재를 보는데, 넛지 문장이 실제로 뜨는지를 보게 바꾼다. `claude plugin marketplace add` 줄의 부재를 단언한다. 그 줄은 넛지가 뜰 때만 나온다.

주석에 왜 좁혔는지 적는다. 정본이 출처를 밝히면서 낱말이 출력에 섞이게 되었고, 낱말이 아니라 넛지의 고유 문자열을 봐야 참거짓이 갈린다는 것이다.

**검증** — `bash scripts/test_scaffold.sh`에서 `already installed: no nudge`가 초록이고 FAIL이 12에서 11로 준다. 정본에서 카파시 플러그인 이름을 지우지 않았다.

## T3 — `review-docs` 스킬을 만든다

`skills/review-docs/SKILL.md`를 새로 쓴다. 내용은 `domain-doc-upkeep`의 「문서 검진 방법」 27줄과 「시작점」의 여섯째 걸음과 「글 유형별 적용」의 외부 공개 문서 줄이다.

`lens-fit`에 넘기는 계약을 둘로 적는다. 정본 `agent-principles.md`와 `skills/domain-korean/SKILL.md`다. README를 검진할 때만 `skills/domain-readme/SKILL.md`를 더한다.

`description`은 여는 상황을 실제 요청 낱말로 적는다. 문서를 고친 뒤 검진할 때, 외부에 공개하기 전에, 검진 기록을 남길 때다. 훅 배선 설명은 넣지 않는다.

만든 뒤 `git add`한다. 안 하면 금지어 검사가 이 파일을 안 본다.

**검증** — 파일이 있고 frontmatter의 `name`이 디렉터리 이름과 같다. 렌즈 셋(`lens-grounding`·`lens-fit`·`lens-readability`) 이름이 모두 들어 있다. `git ls-files skills/review-docs/SKILL.md`가 그 경로를 낸다.

## T4 — `domain-readme` 스킬을 만든다

`skills/domain-readme/SKILL.md`를 새로 쓴다. 내용은 `domain-writing`의 「README (사용자용 문서)」 절 네 항목과 출처 링크 다섯이다.

보편 원칙을 베끼지 않고 참조한다. 다만 **백틱을 두른 조항 ID를 쓰지 않는다.** `test_scaffold.sh` 427행이 `` `SSOT` ``와 `` `FOCUSED` ``가 스킬 어디에도 없어야 한다고 단언하기 때문이다. 그 단언은 T8에서 두 갈래로 갈릴 것이므로, 이 태스크에서는 백틱 없이 정본의 절 이름으로 가리킨다. 정본 「원칙」의 단일 출처 조항과 한 가지 일 조항, 「Karpathy guidelines」의 Simplicity First, 「대화할 때」의 두괄식 조항이다.

만든 뒤 `git add`한다.

**검증** — 파일이 있고 `name`이 맞다. 출처 링크 다섯이 모두 있다. `grep -cE '\x60(SSOT|FOCUSED|EXPLICIT|IDEMPOTENT|EXPLAIN-STRUCTURE)\x60' skills/domain-readme/SKILL.md`가 0이다. `bash scripts/test_scaffold.sh`의 FAIL이 11에서 늘지 않는다.

## T5 — 스킬 셋을 지우고 그 삭제를 단언한다

`skills/domain-coding`, `skills/domain-writing`, `skills/domain-doc-upkeep`을 `git rm -r`로 지운다.

같은 태스크에서 그 삭제로 깨지는 단언을 옮긴다.

`test_scaffold.sh` 432행 `domain-coding exists`와 450행 `domain-writing exists`와 그 아래 절 검사들을 지운다. 대신 세 디렉터리가 **없다**는 단언 셋을 세운다. 존재 검사를 부재 검사로 뒤집는 것이라 가드가 줄지 않는다.

`test_audit.sh` 211행 `! grep -qF '각각 호출' "$DD"`는 대상이 사라져 항진이 된다. `$DD`를 `skills/review-docs/SKILL.md`로 옮긴다. 그 단언이 겨누던 사실(문서 검진이 렌즈를 각각 부르지 않는다)의 새 소유자가 그 파일이다.

`test_docs_drift.sh` 113·167·168·200·202·250·262·436·570행이 지운 경로를 쓴다. 113행의 `DOCS`를 `skills/review-docs/SKILL.md`로, 436행 `COUNT_SCAN`의 `domain-doc-upkeep` 자리를 `review-docs`와 `domain-readme` 둘로 바꾼다. 167·168행의 소유권 분리 검사는 새 소유자(정본과 `review-docs`)를 겨누게 바꾼다. 262행 루프의 파일 인자에서 지운 둘을 뺀다.

**검증** — 세 디렉터리가 없다. `ls skills/ | wc -l`이 16이다. `bash scripts/test_audit.sh`가 FAIL=0이다. `grep -rn 'skills/domain-coding\|skills/domain-writing\|skills/domain-doc-upkeep' scripts/`가 빈 결과다.

## T6 — 훅 셋의 메시지를 고치고 그 시험을 함께 고친다

`hooks/doc_format_pretooluse.sh`가 `domain-writing`의 「글 유형별 적용」을 가리킨다. 정본의 「문서를 쓰고 관리할 때」와 `domain-readme`를 가리키게 바꾼다.

`hooks/doc_review_posttooluse.sh`가 `domain-doc-upkeep`의 검진 절과 `domain-writing`의 수정 범위를 가리킨다. `review-docs`와 정본의 Surgical Changes를 가리키게 바꾼다.

`hooks/rules_nudge_pretooluse.sh`가 `domain-coding`과 `domain-writing`을 열라고 알린다. **정본 경로와 `domain-korean` 경로 둘을** 알리는 문구로 바꾼다. 설계가 둘을 요구했고, 이 회차 뒤 규칙집 스킬은 `domain-korean` 하나만 남으므로 그 하나를 알리는 자리를 지우면 안 된다. 이 훅은 지우지 않는다. matcher에 `Bash`가 들어 있는 유일한 훅이고 `agent_id`로 서브에이전트를 따로 세기 때문이다.

`hooks/hooks.json`은 손대지 않는다.

같은 태스크에서 `scripts/test_hooks.sh`의 참조 열다섯을 고친다. 146·147·151·152·153·156·168·169행의 넛지 메시지 단언은 새 문구를 겨누게 바꾸고, 180행은 `domain-readme`를 겨누게, 183~185행의 절 실재 검사는 새 넛지가 가리키는 파일을 열게, 196·214행은 새 이름으로 바꾼다. 단언 수를 줄이지 않는다.

**검증** — `bash scripts/test_hooks.sh`가 FAIL=0이고 PASS가 101보다 작지 않다. `grep -c 'domain-coding\|domain-writing\|domain-doc-upkeep' hooks/*.sh`가 0이다. 세 훅 메시지에 정본 경로가 있고 `rules_nudge_pretooluse.sh`에 `domain-korean`이 있다.

## T7 — 스킬 아홉과 안내 문서 넷의 참조를 고친다

참조가 있는 스킬은 아홉이다. `dispatching-lenses`(1), `aggregating-lenses`(1), `audit-repo-docs`(3), `review-specs`(2), `nested-orchestration`(1), `lens-fit`(1), `lens-grounding`(1), `lens-readability`(1), `domain-plugin`(2)이다. 설계 표가 조건부로 실었던 `review-llm-calls`·`lens-adversarial`·`lens-consistency`는 실측하니 참조가 0이라 손대지 않는다.

`nested-orchestration` 28행은 `domain-coding`과 `domain-writing` 경로를 넣으라고 지시한다. 정본 경로 하나와 `domain-korean` 경로를 넣으라는 문구로 바꾼다.

`domain-plugin`은 14행의 예시와 **26행의 `domain-coding`의 Simplicity First 참조 둘 다** 고친다. 14행의 예시는 남는 것(`domain-korean`·`domain-plugin`·`domain-readme`)으로 바꾸고, 26행은 정본의 Simplicity First를 가리키게 바꾼다.

렌즈 셋의 `description`은 호출자 이름과 **계약 예시를 함께** 고친다. `lens-fit`의 값에 호출자가 아니라 계약 예시로 `domain-writing`·`domain-coding`이 들어 있다. 계약 예시를 정본과 `domain-korean`으로 바꾼다. 렌즈의 판정 논리와 체크리스트는 `lens-doc-principles` 브랜치가 맡으므로 손대지 않는다.

안내 문서는 넷이다. `README.md`(5곳), `CLAUDE.md`(1곳), `scripts/scaffold.sh` 주석(1곳), `scripts/audit_verify.sh`(1곳)다. `audit_verify.sh` 6행이 소유자를 "문서 타입 표 기록 행"이라 부르는데 새 정본에서 그 규칙은 표 다음 문단에 있으므로 "정본의 기록 이름 규칙"으로 바꾼다.

**검증** — `git grep -l 'domain-coding\|domain-writing\|domain-doc-upkeep' -- skills README.md CLAUDE.md commands .claude-plugin 'scripts/*.sh' ':!scripts/test_*.sh'`가 빈 결과다. 시험 스크립트를 제외하는 것을 명령이 하고 판단에 맡기지 않는다.

## T8 — 정본 가드를 새 구조로 다시 세운다

`test_scaffold.sh` 402~446행의 정본 검사를 다시 쓴다.

절 아홉의 존재를 단언한다. `원칙`·`Karpathy guidelines`·`대화할 때`·`문서를 쓰고 관리할 때`·`코딩할 때`·`검증`·`미해결의 처분`·`병렬 오케스트레이션`·`이 파일의 취급`이다. 줄 전체를 앵커로 잡는다.

조항 열넷이 `- **\`ID\` (영어 타이틀)**` 꼴로 있는지 단언한다. ID 목록은 이 계획의 「정본이 갖는 조항 열넷」 절이 소유한다. 정본에서 읽어 오지 않는다.

425~427행의 열 ID 루프를 두 갈래로 가른다. 되살아난 다섯(`EXPLICIT`·`FOCUSED`·`SSOT`·`IDEMPOTENT`·`EXPLAIN-STRUCTURE`)은 정본에 **있어야** 하고, 옛 다섯(`ASK-FORK`·`MEASURE-FIRST`·`SIMPLE`·`SURGICAL`·`TDD`)은 정본에도 살아 있는 문서에도 **없어야** 한다. 루프를 지우지 않고 목록을 둘로 나눈다.

카파시 네 절이 `### Simplicity First`·`### Surgical Changes`·`### Goal-Driven Execution`·`### Think Before Acting` 꼴로 있고 `## Think Before Acting`은 없다고 단언한다. `**Tradeoff:**`가 정본에 있다고 단언한다.

`test_docs_drift.sh`의 참조 검사에서 지운 셋을 겨누던 것을 정본의 절 이름을 겨누게 바꾼다. 금지어 도출은 `skills/domain-korean/SKILL.md`를 그대로 읽으므로 손대지 않는다.

`review-docs`를 부르는 자리를 만든다. `test_docs_drift.sh` 489~502행이 모든 스킬 디렉터리에 대해 정본이나 다른 스킬이 그 이름을 한 번은 부르는지 본다. 정본의 「문서를 쓰고 관리할 때」 끝에 검진은 `review-docs`가 소유한다는 한 문장을 둔다. 검진 절차를 정본에 되돌리는 것이 아니라 소유자를 가리키는 포인터 한 줄이다.

**검증** — 다섯 스크립트가 모두 FAIL=0이다. `test_scaffold.sh`의 PASS가 275보다 작지 않다. 옛 조항 다섯의 부재 단언이 살아 있다.

## T9 — 전체 검증

`bad=""; for t in scripts/test_*.sh; do bash "$t" || bad="$bad $t"; done; [ -z "$bad" ] && echo "ALL PASS" || echo "FAILED:$bad"`를 돌리고 그다음 `claude plugin validate ./`를 돌린다.

정본 줄 수를 재서 기록한다. 200 이하인지 보는 것은 175줄이므로 자동으로 참이라 판정이 되지 않는다. 대신 **상시 로드 분량이 52줄에서 몇 줄로 갔는지를 숫자로 적는다.** 설계가 다음 회차의 완화(문서 타입 표와 수정 규율 표를 스킬로 빼기)를 촉발할 값으로 쓰라고 남긴 것이다.

기록 이름 규칙의 넷이 정본에 있는지 문자열로 확인한다. `skills/domain-korean/SKILL.md`의 「금지 표현」 표가 그대로 있고 `test_docs_drift.sh`의 금지어 목록이 비지 않는지 확인한다.

**검증** — 다섯 스크립트가 FAIL=0이고 `claude plugin validate ./`가 `version` 경고 하나만 낸다.

## T10 — 병합과 푸시

`lens-doc-principles` 브랜치의 상태로 갈린다.

**끝났으면** 그 브랜치를 먼저 `main`에 병합하고 그다음 이 브랜치를 병합한다. 이쪽이 나중에 병합해야 `skills/lens-*`의 충돌을 이쪽에서 한 번에 푼다.

**안 끝났으면** 이 브랜치만 `main`에 병합하고 그쪽은 병합하지 않는다. 그쪽 브랜치는 남겨 두고 사용자에게 알린다. 순서를 뒤집어 이쪽을 먼저 올리면 그쪽이 나중에 병합할 때 충돌을 그쪽에서 풀게 되는데, 그쪽은 이 회차의 이름 치환을 모르므로 되살릴 위험이 있다.

병합 뒤 `main`에서 두 가지를 확인한다. 다섯 스크립트가 FAIL=0인 것과, 지운 이름 셋이 살아 있는 코드에 없는 것이다. 후자는 병합이 조용히 자동 해소하며 되살릴 수 있으므로 병합 뒤에 다시 본다.

`git grep -l 'domain-coding\|domain-writing\|domain-doc-upkeep' -- skills README.md CLAUDE.md commands .claude-plugin agent-principles.md 'scripts/*.sh' 'hooks/*.sh' ':!scripts/test_*.sh'`가 빈 결과여야 한다.

**푸시는 되돌릴 수 없다.** `.claude-plugin/plugin.json`에 `version` 키가 없고 마켓플레이스에 `autoUpdate: true`가 걸려 있어, `main`에 올리면 버전 게이트 없이 다음 세션에 이 PC로 배포된다. 스킬 셋이 사라진 상태를 사용자가 세션에서 고를 방법이 없다. 사용자가 "결과물 메인 브랜치로 최종적으로 올려줘"라고 직접 지시했으므로 진행하되, 이 사실을 보고에 적는다.

**검증** — `main`에서 다섯 스크립트가 FAIL=0이고 위 `git grep`이 빈 결과다.

## T11 — 사용자에게 알릴 것을 정리한다

설계가 요구한 통지와 이 회차에서 재량으로 정한 것을 한데 모아 보고한다.

금지 표현 표를 `.tsv`로 옮기라는 지시를 뒤집은 것이 첫째다. 그 표에서 이미 기계 검사가 도출되고 있어 옮기면 검사가 조용히 0건이 된다.

넛지 훅 둘을 지우려던 설계를 뒤집은 것이 둘째다. 서브에이전트에 정본이 안 실리는 구멍을 그 훅이 메우고 있었다.

상시 로드 분량이 52줄에서 몇 줄로 갔는지가 셋째다.

`lens-doc-principles` 브랜치를 병합했는지 안 했는지가 넷째다.

## 순서

T1과 T2는 정본과 시험만 건드리므로 먼저 한다. T3과 T4는 T5보다 먼저 해야 내용이 유실되지 않는다. T6과 T7은 T5 뒤에 온다. T8은 T1부터 T7이 끝난 뒤라야 무엇을 단언할지 정해진다. T9와 T10과 T11이 마지막이다.

사슬이라 갈라 보내지 않고 한 세션에서 차례로 한다.

<!-- spec-review: passed -->
