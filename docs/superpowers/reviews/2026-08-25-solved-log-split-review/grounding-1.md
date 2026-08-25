# reviewer-grounding 1회차 원본 (2026-08-25)

검토 대상: `docs/superpowers/specs/2026-08-25-solved-log-split-design.md`
띄운 방식: 읽기 전용 서브에이전트 1회. 전사본(`tasks/<id>.output`)은 완료 후 0바이트가 되므로
완료 통지에 실려 온 JSON을 그대로 옮겨 둔다.

```json
{
  "lens": "grounding",
  "angles_scanned": [
    "전역 오답노트 실측 — 문자 수·항목 수·증상 줄/본문 분해 (python len(text))",
    "상시 로드 세 파일(agent-principles·domains-index·solved_problems) 문자 수와 합계",
    "이 레포 docs/solved_problems.md 문자 수·항목 수",
    "옛 한 줄 형식 항목 판별(들여쓰기 자식 줄 없는 항목)과 개수·평균 길이",
    "git 이력 — docs/solved_problems.md 커밋 수·날짜 범위, 「상황별 원칙 찾기」 표 도입 시점, 워킹트리 상태",
    "전역 로그의 20\\d\\d-\\d\\d-\\d\\d 날짜 문자열, backups 디렉터리 실물 목록·백업 시점 항목 수",
    "scripts/test_scaffold.sh·_scaffold_common.sh·scaffold.sh·codex-scaffold.sh·test_codex_scaffold.sh·test_hooks.sh·.claude/workflows/self-audit.js의 solved_problems 참조 개수",
    "정본 인용 대조 — recall 규칙 문구, 「상황에서 원칙으로」 표 유무와 취지, 절별 문자 수",
    "선행 문서 인용 대조 — 2026-06-15 비목표 절, 2026-07-28 머리말 갱신 spec, skills/domain-docs/SKILL.md 사본 규율",
    "'이미 반영한 것' 두 건의 실제 반영 상태 — 머리말 문구, commands/show-solved.md 삭제",
    "색인 크기 추정(9,000자·3할)의 산술 재계산",
    "SCAFFOLD_WHITELIST와 scaffold_hygiene가 새 solved_problems/ 디렉터리를 어떻게 다루는지",
    "측정 시점 안정성 — 리뷰 도중 전역 로그가 실제로 변하는지"
  ],
  "findings": [
    {
      "claim": "\"전역 오답노트는 항목 52개에 20,580자이고 그 가운데 원인·해결 본문이 13,504자로 66%다.\"",
      "verdict": "contradicted",
      "measured": "항목 52개·20,580자는 정확히 맞다. 원인·해결 본문은 13,537자(들여쓴 줄 92개, 개행 포함)로 재어져 13,504와 33자 어긋난다. 개행을 빼면 13,447자, 들여쓰기 공백까지 빼면 13,344자로 어느 셈법으로도 13,504가 재현되지 않는다. 다만 비율은 13,537/20,580 = 65.8%라 '66%'는 성립한다.",
      "evidence": "python -c로 C:\\Users\\CHSHIN\\.claude\\disciplined-coder\\solved_problems.md 를 읽어 `- **`로 시작하는 줄 52개, len(text)=20580, 들여쓴 줄 합계 13537(개행 포함)/13447(개행 제외)/13344(strip)을 셌다. 같은 셈법(절 머리글 포함·개행 포함)으로 잰 agent-principles.md의 「원칙」 절은 6,623자, 「공통 함정」 절은 581자로 spec 값과 한 글자도 안 틀리므로, 저자의 셈법 자체는 개행 포함 방식이 맞다 — 그렇다면 13,537이 나와야 한다.",
      "why_it_matters": "13,504는 66%와 절감 추정(9,000자·3할)의 출발값이다. 어느 셈법으로도 재현이 안 되는 값이 근거로 박히면, 나중에 이관 후 실측치와 비교할 때 무엇이 기준이었는지 알 수 없어 '절감폭을 실제로 세어 기록한다'는 검증 항목이 판정 불가가 된다."
    },
    {
      "claim": "\"상시 로드되는 전체(정본 14,571 + 도메인 목차 605 + 오답노트 20,580 = 35,756자)\"",
      "verdict": "confirmed",
      "measured": "agent-principles.md 14,571자, domains-index.md 605자, solved_problems.md 20,580자, 합계 35,756자. 세 파일 모두 C:\\Users\\CHSHIN\\.claude\\disciplined-coder\\ 아래에 실재한다.",
      "evidence": "python -c \"len(io.open(p,encoding='utf-8').read())\" 로 세 파일을 각각 셌다. 바이트로는 31,198·1,180·39,717이므로 spec이 문자 수로 적은 것이 맞다.",
      "why_it_matters": "해당 없음 — 이 값은 그대로 쓸 수 있다."
    },
    {
      "claim": "\"지금 증상 줄 합계가 6,622자이고 … 색인은 9,000자 안팎이 될 것으로 보이며 … 상시 로드 35,756자의 3할가량이 빠진다.\"",
      "verdict": "contradicted",
      "measured": "증상 줄 합계 6,622자는 정확히 맞다(항목 첫 줄 52개, 개행 제외). 그러나 그 6,622 안에 옛 한 줄 형식 7개의 2,360자가 통째로 들어 있다 — 이 7개는 증상만이 아니라 원인·해결까지 한 줄에 뭉쳐 있고, spec 자신이 그것들을 본문으로 갈라 낸다고 적었다. 갈라 낸 뒤 색인에 남을 증상 성분은 잘 갖춰진 45개의 4,262자(평균 95자)에 7개의 증상 성분을 더한 값이고, 항목당 포인터를 40자로 잡아도 색인은 7,000자 안팎으로 계산된다. 9,000자는 형식이 갈리기 전의 값을 그대로 넣어 얻은 수치다.",
      "evidence": "옛 형식 7개의 첫 줄 길이는 434·261·331·327·250·255·502(합 2,360, 평균 337.14)로 실측했다. 6,622 − 2,360 = 4,262, 4,262 + 52×40 ≈ 6,340. 한편 '3할'은 (20,580 − 9,000)/35,756 = 32.4%로 계산은 맞는다.",
      "why_it_matters": "추정이 보수적인 쪽이 아니라 낙관·비관 어느 쪽인지 모르게 섞여 있다. 색인이 7,000자면 절감은 3할이 아니라 3할 8푼이고, 반대로 지시사항 줄이 증상 줄보다 길어지면 다시 줄어든다. 두 요인이 반대 방향인데 한쪽만 계산에 들어가 있어서 이 추정치는 방향조차 못 정한다."
    },
    {
      "claim": "\"프로젝트 오답노트(이 레포는 항목 27개에 9,816자)\"",
      "verdict": "confirmed",
      "measured": "D:\\projects\\disciplined-coder\\docs\\solved_problems.md — 27개 항목(`- **`로 시작하는 줄), 9,816자.",
      "evidence": "python len(text)=9816, 항목 27개. 참고로 머리말 형식 규칙 블록의 불릿 6개까지 세면 `- `로 시작하는 줄은 33개이므로, '항목'을 굵은 증상 줄로 센 것이 맞다.",
      "why_it_matters": "해당 없음."
    },
    {
      "claim": "\"옛 한 줄 형식 7개(평균 337자에 증상·원인·해결이 한 줄에 뭉쳐 있다)는 손으로 가른다. 핸드오프가 '형식이 일정해서 스크립트로 가른다'고 적었으나 실측하면 그렇지 않다.\"",
      "verdict": "confirmed",
      "measured": "전역 로그에서 들여쓴 자식 줄이 하나도 없는 항목이 정확히 7개, 첫 줄 길이 평균 337.14자. 레포 로그에는 0개다. 핸드오프 문장도 실재한다.",
      "evidence": "실측 스크립트 출력 `one-line items 7 avg 337.14285714285717`. docs/HANDOFF.md:45 — \"**기존 52개의 이관** — 형식이 일정해서 스크립트로 가른다.\"",
      "why_it_matters": "해당 없음 — 다만 핸드오프는 이관 대상을 52개로 적고 spec은 79개로 적어, 이관 범위 자체가 두 문서에서 갈린다. 스크립트를 쓸 사람이 핸드오프만 보면 레포 27개를 빼먹는다."
    },
    {
      "claim": "\"이 레포의 오답노트 27개는 git 이력 스무 커밋으로 각 항목이 언제 들어왔는지 정확히 복원된다(2026-06-30부터).\"",
      "verdict": "confirmed",
      "measured": "`git log --follow -- docs/solved_problems.md` 가 커밋 20개를 내고 범위는 2026-06-30(ef762d1) ~ 2026-08-25(e880a17)다.",
      "evidence": "명령 출력에서 20줄, 첫 줄 e880a17 2026-08-25, 마지막 줄 ef762d1 2026-06-30 \"chore(dogfood): apply /add-pointer to this repo (project solved log + pointer)\".",
      "why_it_matters": "커밋 수와 범위는 맞지만 '각 항목이 정확히 복원된다'까지는 확인하지 못했다. 그 20개 안에 ea80f93 \"오답노트 항목 형식을 §다 정본 형식으로 단일화한다\"와 6dc9980 \"revert(canon): 영문 재작성을 되돌리고\"가 있어 항목 본문이 통째로 다시 쓰인 회차가 섞여 있다. 그런 회차를 최초 등록일로 잡으면 27개 중 일부에 틀린 날짜가 박히는데, spec은 그 위험을 적지 않았다."
    },
    {
      "claim": "\"전역 오답노트 52개는 git 밖이라 이력이 없고, 본문에 날짜가 적힌 항목이 하나뿐이며, 백업으로 아는 것은 '2026-07-28에 7개, 오늘 52개'라는 두 점뿐\"",
      "verdict": "confirmed",
      "measured": "C:\\Users\\CHSHIN\\.claude 는 git 워크트리가 아니다. 전역 로그 안의 `20\\d\\d-\\d\\d-\\d\\d` 매치는 ['2026-08-25'] 하나뿐이다. backups\\solved_problems-20260728-132822.md 는 2,403자에 항목 7개이며 7개 전부 옛 한 줄 형식이다(평균 316자). 전역 로그의 백업은 이 한 벌뿐이다.",
      "evidence": "`git rev-parse --is-inside-work-tree` → fatal: not a git repository. re.findall 결과 매치 1건. backups 디렉터리 목록에는 그 밖에 issue-mode/ultracode-review 토글 잔재 두 개와 오늘 뜬 프로젝트 로그 사본(solved_problems.disciplined-coder.20260825-180258.md, 9,852자·27항목)만 있다.",
      "why_it_matters": "해당 없음 — '모르는 것에 날짜를 안 박는다'는 결론의 근거가 실측과 맞는다."
    },
    {
      "claim": "\"지금 test_scaffold.sh가 오답노트를 서른두 곳에서 잡고 있어 그만큼 함께 손본다.\"",
      "verdict": "confirmed",
      "measured": "scripts/test_scaffold.sh 에서 `solved_problems`를 담은 줄이 32개(문자열 등장은 33회)다.",
      "evidence": "`grep -c solved_problems scripts/test_scaffold.sh` → 32, `grep -o ... | wc -l` → 33.",
      "why_it_matters": "숫자는 맞지만 '그만큼 함께 손본다'가 손볼 범위 전체인 것처럼 읽힌다. 아래 항목에서 짚는다."
    },
    {
      "claim": "손볼 범위가 test_scaffold.sh 서른두 곳이라는 서술(같은 문장)",
      "verdict": "contradicted",
      "measured": "같은 레포에서 `solved_problems`를 참조하는 실행 코드가 더 있다 — scripts/_scaffold_common.sh 8줄, scripts/scaffold.sh 6줄, scripts/codex-scaffold.sh 5줄(6회), scripts/test_codex_scaffold.sh 8줄, scripts/test_hooks.sh 1줄, .claude/workflows/self-audit.js 2줄. 문서 쪽으로는 skills/domain-docs/SKILL.md 2줄, README.md 2줄, CLAUDE.md 2줄, agent-principles.md.",
      "evidence": "각 파일에 grep -c 를 돌린 결과. 특히 scripts/test_codex_scaffold.sh 8줄은 test_scaffold.sh 와 대칭인 쌍둥이 테스트인데 spec에 한 번도 안 나온다 — 이 레포의 오답노트에 이미 \"쌍둥이 스크립트는 한쪽을 고칠 때 반드시 같이 본다\"는 교훈이 적혀 있다(docs/solved_problems.md, '정본이 매 세션 두 번 실린다' 항목).",
      "why_it_matters": "계획을 짤 때 32라는 한 숫자만 보면 Codex 쪽 스캐폴드와 그 테스트를 통째로 빠뜨린다. 이 레포는 Claude/Codex 패리티를 계약으로 두고 있어서 한쪽만 고치면 Codex 사용자의 오답노트가 옛 구조로 남고, 그 어긋남을 잡을 테스트도 같이 안 고쳐져 조용히 초록이 된다."
    },
    {
      "claim": "spec이 새 구조로 제안한 `solved_problems/<이름>.md` 폴더를 전역 관리 디렉터리 아래에 둔다는 것",
      "verdict": "contradicted",
      "measured": "scripts/_scaffold_common.sh:6 의 `SCAFFOLD_WHITELIST=\"agent-principles.md domains-index.md solved_problems.md backups\"` 에 `solved_problems` 디렉터리가 없다. scaffold_hygiene 은 화이트리스트 밖 디렉터리를 지우지는 않지만 매 세션 `[disciplined-coder] note: 비관리 디렉터리 'solved_problems' 잔존(자동삭제 안 함, 확인 요)` 를 stderr 로 낸다.",
      "evidence": "scripts/_scaffold_common.sh 6행과 44~46행을 직접 읽었다.",
      "why_it_matters": "이관을 마치는 순간부터 모든 세션 시작에 끄지 못하는 경고가 뜬다. 이 레포는 `FAIL-LOUD`를 지키느라 이런 신호에 끄는 수단을 안 두는 관례라, 화이트리스트를 같이 고치지 않으면 신호가 영구 소음이 되어 진짜 경고를 가린다. spec의 '안 하는 것'에도 '검증'에도 화이트리스트가 없다."
    },
    {
      "claim": "\"정본의 recall 규칙은 '디버깅·구현을 **시작하기 전에** 비슷한 **증상**을 먼저 찾는다'고 적혀 있는데\"",
      "verdict": "confirmed",
      "measured": "정본 agent-principles.md:122 — \"**꺼내 쓰기(recall)**: 디버깅·구현을 시작하기 전에 **PC solved와 프로젝트 solved 둘 다**에서 비슷한 증상을 먼저 찾는다.\" 전역 사본도 같은 122행에 같은 문장이다.",
      "evidence": "D:\\projects\\disciplined-coder\\agent-principles.md:122 과 C:\\Users\\CHSHIN\\.claude\\disciplined-coder\\agent-principles.md:122 를 대조했다.",
      "why_it_matters": "뜻은 맞지만 따옴표 안이 원문 그대로가 아니다. \"PC solved와 프로젝트 solved 둘 다에서\"를 말줄임 표시 없이 잘라냈다. 이 spec이 고치겠다는 대상 문장이므로, 나중에 정본에서 이 문자열을 찾아 바꾸려 하면 안 걸린다."
    },
    {
      "claim": "\"정본 자신이 같은 문제를 한 번 겪고 「상황에서 원칙으로」 진입로 표를 붙여 고쳤다 — 이름으로 찾는 색인은 이름을 이미 떠올린 뒤에야 쓸모가 있기 때문이었다.\"",
      "verdict": "confirmed",
      "measured": "표는 실재하고 취지도 그대로다 — agent-principles.md:9 \"원칙 목록은 이름으로 찾는 색인이라 이름을 이미 떠올린 뒤에야 쓸모가 있다. 이름이 안 떠오르는 순간에 쓰라고 상황에서 출발하는 진입로를 둔다.\" 표는 2026-08-25 커밋 e880a17에서 들어왔다.",
      "evidence": "agent-principles.md 7~44행, `git log -S \"상황별 원칙 찾기\" -- agent-principles.md` → e880a17 한 건.",
      "why_it_matters": "다만 이름이 어긋난다. 실제 절 제목은 「상황별 원칙 찾기」이고 「상황에서 원칙으로」는 정본 4행이 자기 절을 가리키며 쓴 다른 이름이다. spec은 정본의 그 어긋난 이름을 그대로 물려받았다. 낫표까지 씌워 고유명처럼 적어 두면 읽는 사람이 그 제목을 찾다가 못 찾는다."
    },
    {
      "claim": "\"`2026-06-15-agent-principles-redesign-design.md`의 비목표 절이 '검색형 이슈 로그는 만들지 않는다. 평면 리스트가 실제로 커져서 아플 때 별도로 다룬다(측정 먼저)'로 조건을 걸어 두었고\"",
      "verdict": "confirmed",
      "measured": "그 파일 28~29행 — \"**검색형 이슈 로그**(항목별 파일 + description 기반 recall)는 만들지 않는다. 평면 리스트가 실제로 커져서 아플 때 별도로 다룬다(측정 먼저).\"",
      "evidence": "docs/superpowers/specs/2026-06-15-agent-principles-redesign-design.md:28-29, '## 2. 비목표 (Non-goals)' 절 아래 첫 항목.",
      "why_it_matters": "인용에서 괄호 \"(항목별 파일 + description 기반 recall)\"가 표시 없이 빠졌다. 빠진 그 괄호가 하필 이번 spec이 하겠다는 것(항목별 파일)을 그대로 지목하므로, 원문을 다 실으면 '미룬 결정을 이제 꺼낸다'는 논지가 오히려 더 단단해진다. 지금 인용은 원문을 약하게 옮겨 놓은 셈이다."
    },
    {
      "claim": "\"**개편은 사본을 먼저 뜨고 한다.** 못 뜨면 아예 고치지 않고 사유를 알린다. 머리말 갱신이 쓰는 규율(`2026-07-28-solved-header-refresh-design.md`)과 같다.\"",
      "verdict": "confirmed",
      "measured": "그 spec은 실재하고(27,916바이트, 2026-07-28), 155~164행이 '### 수정할 때 사본을 한 벌 뜬다'로 규율을 두었다. 실행 시점의 정본은 skills/domain-docs/SKILL.md:125-127 — \"`<관리 디렉터리>/backups/` 아래에 타임스탬프를 붙인 사본을 먼저 뜬다. … 사본을 못 뜨면 아예 고치지 않는다. 회전이나 상한을 두지 않는다.\"",
      "evidence": "docs/superpowers/specs/2026-07-28-solved-header-refresh-design.md:155-164, 179-183, 293. skills/domain-docs/SKILL.md:125-127, 136, 145. 사본이 실제로 떠지는 것도 확인했다 — backups\\solved_problems.disciplined-coder.20260825-180258.md 가 오늘 18:02:58에 생겼다.",
      "why_it_matters": "해당 없음."
    },
    {
      "claim": "\"이 레포는 같은 상황에서 이미 '고칠 때까지 세션마다 반복하고 끄는 수단을 두지 않는다'를 쓰고 있으므로 그 관례를 따른다.\"",
      "verdict": "confirmed",
      "measured": "skills/domain-docs/SKILL.md:142 — \"그 신호는 고칠 때까지 세션마다 반복되며 끄는 수단을 두지 않는다.\"",
      "evidence": "skills/domain-docs/SKILL.md:142, 그리고 같은 관례의 근거가 docs/superpowers/specs/2026-07-28-solved-header-refresh-design.md:344 \"대가로 신호가 세션마다 반복되는 것을 감수한다\"에 있다.",
      "why_it_matters": "해당 없음."
    },
    {
      "claim": "\"**과거 항목을 손대는 조건을 열었다.** 머리말의 '안 쓰이는 항목도 지우지 않는다'를 '… 사용자가 직접 지시할 때만 손댄다'로 고쳤다.\" — '이미 반영한 것'으로 적힘",
      "verdict": "contradicted",
      "measured": "정본 문자열은 고쳐졌지만 **커밋되지 않았고, 배포된 두 로그 어느 쪽에도 반영돼 있지 않다.** 워킹트리 scripts/_scaffold_common.sh:25 는 새 문장이지만 `git show HEAD:scripts/_scaffold_common.sh` 25행은 옛 문장이고, `git status`에 ` M scripts/_scaffold_common.sh`로 떠 있다. 배포본 두 곳(D:\\projects\\disciplined-coder\\docs\\solved_problems.md:14, C:\\Users\\CHSHIN\\.claude\\disciplined-coder\\solved_problems.md:13)은 모두 옛 문장 \"- 안 쓰이는 항목도 지우지 않는다.\"다. 더 나아가 **오늘 실행된 갱신이 로그를 거꾸로 돌려놓았다** — 18:02:58에 뜬 사본에는 새 문장이 들어 있는데(사본은 수정 직전 상태다) 지금 파일에는 옛 문장이 있다.",
      "evidence": "`diff backups/solved_problems.disciplined-coder.20260825-180258.md docs/solved_problems.md` 가 두 줄 차이를 냈다 — 4행 \"(append-only — 과거 항목은 사용자가 직접 지시할 때만 손댄다)\" → \"(append-only, 과거를 지우지 않는다)\", 14행 새 문장 → 옛 문장. `git status --short docs/solved_problems.md` 는 비어 있어 지금 내용이 HEAD와 같다. 전역 로그 머리말도 정본 함수 scaffold_solved_header(pc)의 출력과 다르다(배포본 \"작업 중 발견·해결된 문제의 교훈 모음 … 등록은 메인 세션이 수행\" vs 정본 \"완결된 문제의 교훈 모음 …\").",
      "why_it_matters": "spec이 '이미 반영한 것'이라 적어 둔 계약 변경이 실제로는 어디에도 살아 있지 않고, 오늘 한 번은 되레 되돌려졌다. 이 spec은 그 계약(과거 항목을 손대도 된다)에 기대어 79개 전량 재작성을 정당화하는데, 근거로 삼은 문장이 배포본에 없다. 그리고 '개정하면 기존 로그들의 머리말은 배포 후 첫 세션에 스캐폴드가 저절로 갱신한다'는 이 spec의 다음 단계 전제도 오늘 실측에서는 성립하지 않았다 — 갱신 경로가 워킹트리 정본이 아니라 커밋에 고정된 플러그인 캐시를 읽고 있을 가능성이 크다(원인은 내가 확인하지 못했다). 그대로 두면 이관을 마쳐도 머리말이 매 세션 옛 규칙으로 되돌아간다."
    },
    {
      "claim": "\"**`/show-solved` 명령을 지웠다.**\" — '이미 반영한 것'으로 적힘",
      "verdict": "confirmed",
      "measured": "commands/ 에는 setup-discipline.md 와 show-principles.md 만 남아 있고, `git status`에 `D  commands/show-solved.md`(스테이지된 삭제)로 떠 있다. README·CLAUDE.md 등 현행 문서에 남은 참조는 없고, 히스토리 문서(plans·specs·rewrite-map)에만 남아 있다.",
      "evidence": "`ls commands/`, `git status --short`, `grep -rn show-solved` 결과.",
      "why_it_matters": "다만 아직 커밋되지 않았고, 내 세션에 실린 스킬 목록에는 `disciplined-coder:show-solved`가 아직 살아 있다 — 설치된 플러그인 캐시가 옛 커밋에 고정돼 있다는 뜻이다. spec 자체는 맞지만, '지웠다'가 사용자 환경에 도달하려면 커밋과 새 세션이 필요하다."
    },
    {
      "claim": "\"기존 79개를 옮기고\" / \"전역 52개와 이 레포 27개를 파일로 가른다\"",
      "verdict": "contradicted",
      "measured": "내가 재는 동안 전역 로그가 계속 자랐다. 18:33에 52항목·20,580자였는데 18:34:08에 53항목·20,949자가 되었고 다시 21,017자가 되었다. 지금은 53 + 27 = 80개다.",
      "evidence": "같은 파일에 대한 세 번의 python 실측이 각각 (52, 20580) → (53, 20949) → (53, 21017)을 냈다. `ls --time-style=full-iso` 로 mtime 2026-08-25 18:34:08 을 확인했다.",
      "why_it_matters": "79는 오늘 어느 한 시점의 값이고 세션마다 늘어난다. 이관 스크립트나 검증에 79를 상수로 박으면 실행하는 날 반드시 어긋난다 — 이 레포의 정본이 「공통 함정」에 적어 둔 '테스트 기대치 매직 넘버 금지'가 바로 이 경우다. 개수는 세는 쪽이 스스로 세고, spec 본문에는 '실측 시점 79개(2026-08-25)'처럼 시점을 붙여야 한다."
    },
    {
      "claim": "\"정본은 14,571자이고 원칙 본문이 6,623자라 … 정본의 「공통 함정」 절(581자)만은\"",
      "verdict": "confirmed",
      "measured": "정본 14,571자. 「원칙 (ID로 참조 · 알파벳순)」 절은 절 머리글부터 다음 절 직전까지 6,623자, 「공통 함정 (cross-project gotchas)」 절은 581자. 한 글자도 안 틀린다.",
      "evidence": "절 경계를 `## `로 잘라 개행 포함으로 센 결과 — 상황별 원칙 찾기 1,374 / 원칙 6,623 / 환경 관례 416 / 공통 함정 581 / 절차 4,760 / 이 파일의 취급 660.",
      "why_it_matters": "해당 없음. 이 두 값이 정확히 재현된다는 사실이, 같은 셈법으로 재현이 안 되는 13,504가 오기임을 뒷받침한다."
    }
  ],
  "principles_applied": ["MEASURE-FIRST", "SSOT", "FAIL-LOUD", "NAME-ITEMS", "EXPLICIT", "IDEMPOTENT"],
  "notes": "확인하지 못한 것이 셋이다. 첫째, 오늘 18:02~18:34 사이에 무엇이 docs/solved_problems.md 머리말을 옛 문장으로 되돌렸는지 그 실행 경로를 특정하지 못했다 — 설치된 플러그인 캐시(커밋 고정)가 워킹트리 정본 대신 읽혔다는 가설이 가장 그럴듯하지만, 세션 시작 로그나 스캐폴드 실행 흔적을 못 봤다. 이 spec의 '머리말은 배포 후 첫 세션에 스캐폴드가 저절로 갱신한다'가 통째로 여기에 걸려 있으므로, 계획 단계 전에 스캐폴드를 한 번 직접 돌려(scripts/scaffold.sh) 워킹트리 정본이 반영되는지 확인해야 한다. 둘째, '이 레포 27개는 git 이력으로 각 항목이 언제 들어왔는지 정확히 복원된다'를 항목 단위로는 안 세어 봤다 — 커밋 20개 중 형식 단일화(ea80f93)와 되돌리기(6dc9980)가 섞여 있어 항목별 최초 등장 커밋이 그 재작성 커밋으로 잡힐 수 있고, 이는 `git log -S`를 27번 돌려야 판정된다. 셋째, 원인·해결 본문 13,504자가 어떤 셈법에서 나왔는지 끝내 재현하지 못했다 — 개행 포함 13,537, 개행 제외 13,447, 들여쓰기까지 제외 13,344 어느 것도 아니다. 저자가 어떤 범위를 뺐는지(예: 특정 항목 제외) 알아야 최종 판정이 선다. 그리고 이 리뷰 내내 전역 오답노트가 살아서 자라고 있었다는 점을 감안해야 한다 — 이 문서의 모든 실측치는 2026-08-25 18:33 시점 값이다."
}
```
