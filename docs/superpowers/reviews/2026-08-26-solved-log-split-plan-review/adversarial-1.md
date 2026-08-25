# reviewer-adversarial 1회차 원본 (계획 · 2026-08-26)

검토 대상: `docs/superpowers/plans/2026-08-26-solved-log-split.md`
띄운 방식: 읽기 전용 서브에이전트 1회. 전사본(`tasks/<id>.output`)은 완료 후 0바이트가 되므로
완료 통지에 실려 온 JSON을 그대로 옮겨 둔다. 하니스가 일부 제어 문자를 중화해 실어 보냈으므로
`&lt;`·`&gt;` 표기가 남아 있다.

```json
{
  "lens": "adversarial",
  "angles_scanned": [
    "Task 5 쪼개기 스크립트가 실데이터(전역 53항목·레포 27항목)에서 깨지는 자리 — 항목 모으기 규칙, 빈 줄, 들여쓰기, 코드블록·표 유무",
    "슬러그 충돌·60자 자르기·파일명 실측",
    "되돌리기(Task 7)와 백업 식별",
    "중간에 멈추는 상태 — Task 7까지만, Task 5까지 배포",
    "테스트 항진(뮤테이션이 못 잡는 자리)",
    "개수 세기의 실패 — 포인터 세기·굵은 줄 세기",
    "Task 8이 사람에게 지우는 부담",
    "계획이 스펙보다 많이/적게 만드는가(YAGNI·커버리지)",
    "기존 머리말 갱신 경로(scaffold_fix_solved_header)와의 상호작용"
  ],
  "findings": [
    {
      "kind": "failure_mode",
      "where": "Task 8 Step 3 「색인 줄도 같은 문장으로 바꾼다」 + Task 1 Step 5 (`scaffold_fix_solved_header` 는 시그니처만 넓히고 경계 계산 awk 는 그대로 둔다)",
      "attack": "Task 8 이 색인 줄을 굵지 않은 지시사항 형식(`- 파워셸에서 …를 붙인다.`)으로 바꾸고 나면, 그 뒤 **형식 규칙 블록이 한 번이라도 바뀌는 순간** `scaffold_fix_solved_header` 가 발동해 색인 **첫 줄을 통째로 지운다.** 경계 awk 는 도입 문장 뒤의 '굵지 않은 불릿'을 남은 규칙 불릿으로 보고 건너뛰므로(`_scaffold_common.sh:146`), 첫 지시사항 줄까지 머리말로 삼키고 그다음 포인터 줄(`  → solved_problems/…`)을 경계로 잡는다. 남는 것은 머리말 바로 밑에 붙은 고아 포인터 한 줄이다.",
      "evidence": "`_scaffold_common.sh:144-148` 의 경계 루프를 Task 8 이후 모양의 색인(머리말+SPLIT 규칙 8불릿+지시사항 2줄+포인터 2줄, 총 19줄)에 그대로 태워 확인했다 — 경계 n=17 이 나오고 `tail -n +17` 은 `  → solved_problems/test-path-literalpath.md` 부터 살린다. 첫 지시사항 줄(16행)은 사라진다. 규칙 블록은 실제로 자주 바뀐다 — 지금 이 순간에도 `_scaffold_common.sh:25` 는 `- 안 쓰이는 항목도 지우지 않는다 — 사용자가 직접 지시할 때만 손댄다.` 인데 `C:\\Users\\CHSHIN\\.claude\\disciplined-coder\\solved_problems.md:13` 은 `- 안 쓰이는 항목도 지우지 않는다.` 라서 이미 낡음 상태다.",
      "why_it_matters": "이 레포가 오답노트에 손대는 유일한 자동 쓰기 경로가 항목을 먹는다. 전역 로그는 git 밖이라 diff 도 없고, 아래 개수 세기 발견대로 Task 3 의 대조가 포인터를 세므로 개수는 그대로 맞는다. 즉 완전히 조용한 소실이다. Task 7 Step 7 과 Task 8 Step 5 가 처방한 확인은 구조적으로 이것을 볼 수 없다."
    },
    {
      "kind": "failure_mode",
      "where": "Task 1 Step 6 `check \"split-rules: 색인 줄 보존\" \"grep -qF -- '→ solved_problems/a.md' '$LOGS3'\"`",
      "attack": "위 손실을 잡으라고 놓인 유일한 검사가 **포인터 줄만** 본다. 지시사항 줄 `- 무언가를 할 때는 이렇게 한다.` 가 지워져도 초록이다. 게다가 `run` 을 한 번만 부르므로 픽스처에는 도입 문장 `항목을 적는 형식은 이렇다.` 가 아직 없고, awk 는 `seen=0` 분기로 빠져 사고가 나는 `seen>0` 분기를 아예 밟지 않는다. Step 7 의 뮤테이션도 `scaffold_solved_rules_for` 만 건드리므로 이 경로를 못 건드린다.",
      "evidence": "계획 163-165행의 세 check 와 `_scaffold_common.sh:140-150` 의 두 분기. 레포 오답노트가 이미 같은 함정을 적어 두었다 — `docs/solved_problems.md:46-48`.",
      "why_it_matters": "계획이 스스로 세운 뮤테이션 규율을 통과하면서도 가장 큰 실패 모드를 놓친다. 초록이 보증으로 읽히므로 배포된다."
    },
    {
      "kind": "failure_mode",
      "where": "Task 3 Step 3 `lines=\"$(grep -c -- '→ solved_problems/' \"$f\" 2>/dev/null || echo 0)\"` 와 Task 4 Step 3 `n=\"$(grep -c -E '^[-*+][ \\t]+\\*\\*' \"$f\" 2>/dev/null || echo 0)\"`",
      "attack": "`grep -c` 는 0건일 때 stdout 에 `0` 을 찍고 **종료코드 1** 로 끝난다. 그래서 `|| echo 0` 이 한 번 더 붙어 변수 값이 두 줄짜리 `\"0\\n0\"` 이 된다. Task 3 에서는 `[ \"$lines\" = \"$files\" ]` 가 절대 참이 되지 않아 `색인 줄 0\\n0개, 본문 파일 0개 — 어긋난다` 를 찍고, Task 4 에서는 `[ \"$n\" = \"0\" ]` 이 거짓이 되어 **항목이 하나도 없는 로그에 '항목 0\\n0개, 지금 개편할지 사용자에게 물어라'** 를 띄운다.",
      "evidence": "실행으로 확인했다 — `${#n}` 이 3 이고 `[ \"$n\" = \"0\" ]` 가 거짓이다. 그리고 `scaffold_ensure_solved`(`_scaffold_common.sh:92-97`)는 새 PC 에서 머리말만 있는 빈 로그를 만든다 — 그것이 정확히 이 입력이다.",
      "why_it_matters": "새 PC 첫 세션마다 빈 오답노트를 두고 개편을 권하는 물음이 뜬다. 스펙이 이 물음을 '어느 세션에서든 띄우고 거절을 기록하지 않는다'로 정했으므로 끄는 수단이 없다. 상시 오탐은 Task 2 가 막으려던 바로 그 무뎌짐을 다른 자리에서 다시 만든다."
    },
    {
      "kind": "failure_mode",
      "where": "Task 3 — 세는 단위를 포인터로 잡은 결정",
      "attack": "세는 단위가 포인터 줄이라 **지시사항 줄이 사라져도 셈이 안 변한다**(위 첫 발견의 손실 형태가 정확히 그것이다). 반대로 옛 한 줄 형식 항목은 포인터도 본문 파일도 없이 색인에 굵은 불릿으로 남는데, 이것도 어느 셈에도 안 잡힌다. 전역 로그에서 그런 항목이 7개다.",
      "evidence": "전역 로그 15·16·17·18·20·21·22행이 자식 줄 없는 굵은 불릿이다(직접 세어 확인). 쪼개기 스크립트는 `if not any(b.strip() for b in body)` 로 이것들을 건너뛰고 `manual` 만 올린다. 쪼갠 뒤 `lines`(포인터 46) = `files`(46) 이 되어 Task 3 은 조용하고, `scaffold_check_solved_unsplit` 은 `scaffold_solved_log_is_split` 가 참이라 즉시 리턴한다.",
      "why_it_matters": "Task 7 Step 4(손으로 가르기)를 안 하고 멈추면 7개가 색인에 반쯤 남은 채 어떤 신호도 뜨지 않는다. 스펙이 개수 세기를 남긴 근거가 '쓸 때조차 안 드러나는 것을 잡는다'인데, 실제 데이터에서 그 부류를 못 잡는다."
    },
    {
      "kind": "irreversible",
      "where": "Task 7 전체 — Step 6 과 그 아래 「사본 경로를 출력에서 확인하고 적어 둔다」",
      "attack": "스펙이 명시적으로 시킨 되돌리기 절차가 계획에 없다. 더구나 백업 파일 이름이 두 로그에서 구별되지 않는다 — 스크립트는 `\"$BDIR/solved_problems.$STAMP.md\"` 를 쓰는데 기존 머리말 갱신은 `\"$bdir/solved_problems.$label.$stamp.md\"`(`_scaffold_common.sh:161`)로 스코프 이름표를 넣는다. Task 7 Step 2 가 **레포 로그의 사본도 전역 백업 디렉터리에** 떨어뜨리므로, 같은 폴더에 이름표 없는 사본 둘이 타임스탬프로만 갈린다.",
      "evidence": "계획 Task 7 Step 1~7 전문, 스펙 176-179행, `_scaffold_common.sh:161` 대 계획 488행.",
      "why_it_matters": "전역 로그는 git 밖이라 사본이 유일한 복구 수단인데, 되살리는 방법도 어느 사본이 어느 로그인지도 정해져 있지 않다."
    },
    {
      "kind": "failure_mode",
      "where": "Task 5 Step 1 테스트 픽스처 — 항목 안에 빈 줄이 하나도 없고 '줄이 안 사라진다'는 단언이 없다",
      "attack": "스펙의 검증 목록이 빈 줄이 여러 곳에 낀 픽스처를 요구했는데, 계획의 픽스처는 항목 셋이 모두 빈 줄 없는 세 줄짜리이고 검사는 '첫째 원인' 한 문자열이 본문에 있는지뿐이다. 항목 모으기 루프의 빈 줄 분기를 이 픽스처는 한 번도 밟지 않는다.",
      "evidence": "계획 435-453행 픽스처와 spec 314-315행. 전역 오답노트 22행이 같은 함정을 적어 두었다 — \"'무엇을 보존한다'류 계약은 전역 개수가 아니라 **이웃 관계**로 단언하고, 픽스처는 삭제 회귀가 드러나도록 여러 줄에 빈 줄을 끼워 만든다.\"",
      "why_it_matters": "데이터를 지우는 유일한 스크립트에 회귀 그물이 없다. 실데이터를 보면 전역 로그 안에 빈 줄이 17개 있고 항목 사이 간격이 일정하지 않다."
    },
    {
      "kind": "failure_mode",
      "where": "Task 3 Step 1 `check \"pairing: 맞으면 조용하다\"` 와 Task 3 Step 7 「Codex 테스트에 같은 계약을 넣고」",
      "attack": "Codex 쪽으로 그대로 옮기면 이 검사가 반드시 FAIL 한다. `codex-scaffold.sh` 는 전역 로그 전문을 stdout 으로 흘려 보내는데, Task 1 이 넣는 SPLIT 규칙 블록에 `- 사용자 요청으로 고치거나 지울 때는 색인 줄도 함께 고치거나 지운다.` 가 들어 있어 '색인 줄' 이라는 문자열이 항상 출력에 실린다.",
      "evidence": "`scripts/codex-scaffold.sh` 의 `cat \"$KDIR/solved_problems.md\"` 와 계획 79행의 규칙 불릿.",
      "why_it_matters": "쌍둥이를 함께 고치라는 제약을 지키려는 순간 붉어진다. 그때 문구를 느슨하게 고쳐 통과시키면 검사가 항진이 되기 쉽다."
    },
    {
      "kind": "failure_mode",
      "where": "Task 4 Step 3 신호 문구 「개편은 scripts/split_solved_log.sh 로 쪼갠 뒤 …」",
      "attack": "이 문구는 옆 프로젝트에서 뜨는데, 거기 cwd 에는 `scripts/split_solved_log.sh` 가 없다. 스크립트는 플러그인 루트 안에 있고 그 경로는 `CLAUDE_PLUGIN_ROOT` 로만 알 수 있는데, `_scaffold_common.sh` 는 그 값을 모른다. 권장값이 '지금 개편한다'인 물음을 띄워 놓고, 승낙한 세션이 실행할 명령이 그 자리에 존재하지 않는다.",
      "evidence": "계획 389행의 문구, `scripts/codex-scaffold.sh:7` 의 `PLUGIN_ROOT` 계산, 그리고 `_scaffold_common.sh` 전문에 `PLUGIN_ROOT` 참조 없음. Task 2 의 화이트리스트도 스크립트를 관리 디렉터리에 배포하지 않는다.",
      "why_it_matters": "옆 프로젝트의 세션은 매번 물음을 받고 매번 실행에 실패한다. 끄는 수단이 없는 신호라 Task 2 가 막으려던 무뎌짐이 그대로 재현된다."
    },
    {
      "kind": "yagni",
      "where": "Task 5 Step 3 `slug()` — `[:60]` 자르기, 충돌 접미사, `os.listdir(bodydir)` 프리필",
      "attack": "계획이 419-423행에서 이름을 Task 8 에서 확정한다고 못박았다. 즉 이 이름들은 한 걸음 뒤에 전부 버려진다. 그런데 실측하면 전역 53항목 가운데 **47개가 58~60자에서 뜻이 잘린 한글 덩어리**가 되고(예: `python3-호출-테스트가-이-머신에서-FAIL-예-disciplined-coder-testcodexsca`), 구두점을 다 지운 뒤라 `.claude/settings.local.json` 은 `claudesettingslocaljson`이 된다. 사람이 Task 7 Step 3 과 Task 8 Step 3 을 할 때 이름만 보고는 어느 항목인지 못 알아본다.",
      "evidence": "실제 로그 53항목에 계획의 `slug()` 를 그대로 돌려 슬러그 전량을 뽑아 확인했다 — 최대 길이 60, 58자 이상이 47개. 충돌 접미사는 한 건도 안 붙었다(실데이터에 충돌이 없다).",
      "why_it_matters": "지금 필요 없는 이름 짓기 기계를 만들면서, 그 산출물이 오히려 다음 걸음(Task 8 의 80항목 대조)을 어렵게 한다. 이름을 짓는 자리를 Task 8 하나로 모으면 이 함수 전체가 필요 없다."
    },
    {
      "kind": "failure_mode",
      "where": "Task 6 Step 4 「domain-docs의 두 표를 고친다」 — `scaffold_solved_header` 의 히어독은 손대지 않는다",
      "attack": "쪼갠 뒤에도 색인 파일의 머리말이 스스로를 `append-only 오답노트` 라고 선언하는데, 바로 아래 SPLIT 규칙 블록은 색인 줄을 고치거나 지우라고 적는다. 한 파일이 자기 규율을 두 가지로 선언한다.",
      "evidence": "`_scaffold_common.sh:65`·`:68`·`:74`·`:77`. 스펙이 이 자리를 직접 지목했다(spec 229-232). Task 1 은 시그니처만 넓히고 히어독 본문은 안 건드린다(계획 124-128행).",
      "why_it_matters": "머리말은 플러그인이 소유해 사람이 손으로 못 고치므로, 이대로면 영구히 모순된 선언이 박힌다."
    },
    {
      "kind": "failure_mode",
      "where": "Task 5 Step 3 `python - …` 와 계획 머리말의 「JSON을 다뤄야 할 때만 파이썬」",
      "attack": "계획이 자기 제약을 어긴다 — 다루는 것은 JSON 이 아니라 마크다운인데 파이썬을 꺼낸다. 그리고 `python3` 가 아니라 bare `python` 을 부른다. 새로 만드는 `scripts/test_split_solved_log.sh` 는 CI 에서 자동으로 잡혀 돈다.",
      "evidence": "계획 9행과 495행. `.github/workflows/ci.yml` 은 `runs-on: ubuntu-latest` 에서 `for t in scripts/test_*.sh` 로 열거 없이 전부 돌린다. 이 레포의 오답노트에 인터프리터 이름과 로컬/CI 갈림이 이미 둘 다 적혀 있다(전역 15행, 전역 96-98행).",
      "why_it_matters": "인터프리터 이름 하나에 CI 초록이 걸리는데, 그 함정을 이 레포가 이미 두 번 적어 두었다."
    },
    {
      "kind": "failure_mode",
      "where": "Task 8 전체 — Step 3 과 Step 4",
      "attack": "대상이 전역 53 + 레포 27 = 80항목이고, 항목마다 본문 읽기·지시사항 작문·파일 이름 확정·포인터 갱신 넷을 한다. 계획에는 배치·중단·재개 장치가 없고 커밋도 Step 7 하나뿐이라 중간에 끊기면 절반은 지시사항형, 절반은 증상형인 색인이 커밋 없이 남는다. 그 상태를 알리는 신호도 없다 — 로그는 이미 `is_split` 이라 Task 4 의 권유가 안 뜨고, 포인터 수와 파일 수는 맞아 Task 3 도 조용하다.",
      "evidence": "실제 항목 수를 셌다 — 전역 53, 레포 27. 스펙은 중간 상태를 허용했지만(spec 203-206) 계획은 그 상태를 표시하거나 재개하는 방법을 정하지 않는다.",
      "why_it_matters": "이 작업의 목적이 실현되는 유일한 걸음인데, 한 세션에 끝날 크기가 아니면서 못 끝냈다는 사실이 어디에도 안 남는다."
    },
    {
      "kind": "failure_mode",
      "where": "Task 5 Step 3 `title = re.sub(r\"^[-*+][ \\t]+\", \"\", head).strip()`",
      "attack": "`**` 를 안 벗기므로 본문 파일의 첫 줄이 `# **파워셸 …**` 가 되고 색인 줄도 `- **…**` 로 남는다. 스펙이 정한 모양은 굵기 없는 평문이다(spec 45·55). 그리고 이 굵기가 남아 있는 동안에만 경계 계산이 우연히 맞으므로, 첫 발견의 폭탄이 Task 8 직후에 터지도록 시점을 미룬다.",
      "evidence": "계획 528·530-533행, 스펙 44-57행의 예시 두 개. Task 5 의 테스트에는 첫 줄 모양을 보는 단언이 없다.",
      "why_it_matters": "스펙이 그림으로 못박은 산출물 모양과 다른 것이 나오는데 테스트가 안 본다. 두 걸음 사이의 인과가 계획 어디에도 안 적혀 있다."
    },
    {
      "kind": "yagni",
      "where": "Task 1 Step 5 `intro=\"$(scaffold_solved_rules_for \"$f\")\"; intro=\"${intro%%$'\\n'*}\"`",
      "attack": "두 규칙 블록의 첫 줄이 똑같으므로 이 변경은 동작이 하나도 안 바뀌는 무동작이다. 그런데 '경계 계산도 새 선택을 쓰게 했다'는 인상을 남겨, 정작 고쳐야 할 그 아래 불릿 판정이 이미 처리된 것처럼 읽힌다.",
      "evidence": "`_scaffold_common.sh:18` 과 계획 70행이 모두 같은 문장으로 시작한다. `:135` 의 `intro` 는 첫 줄만 쓴다.",
      "why_it_matters": "남겨 두면 검토하는 사람이 경계 계산이 새 형식에 맞춰졌다고 읽어, 실제 위험한 분기를 안 본다."
    },
    {
      "kind": "yagni",
      "where": "계획 전체 — 스펙의 「Codex는 색인을 stdout으로 주입한다」에 대응하는 태스크가 없다",
      "attack": "반대 방향의 누락이다. 스펙은 주입할 때 뿌리를 한 줄로 함께 적으라고 정했는데(spec 74-76) 계획의 여덟 태스크 어디에도 그 한 줄이 없다.",
      "evidence": "`scripts/codex-scaffold.sh` 의 주입부는 `cat` 뿐이고, 계획 Task 1~8 의 Files 목록에 그 자리가 안 나온다.",
      "why_it_matters": "Codex 세션이 색인 줄을 받아도 어느 뿌리인지 알 방법이 없다. 지시사항에 걸려 본문을 열려는 순간 경로를 못 찾는데, 본문을 여는 것이 이 설계의 유일한 이득 실현 경로다."
    }
  ],
  "principles_applied": ["FAIL-LOUD", "TDD", "REVERSIBLE", "SIMPLE", "SSOT", "MEASURE-FIRST", "IDEMPOTENT", "EXPLICIT", "공통 함정 — 테스트 기대치 매직 넘버 금지"],
  "notes": "실제로 확인하고 '안 깨진다'로 판정해 발견에 안 올린 것을 적어 둔다. 첫째, 항목 모으기 루프가 어긋나는 모양을 실데이터에서 찾았으나 없었다 — 전역 로그 173줄과 레포 로그 97줄을 줄 종류별로 전수 분류한 결과 이어지는 줄은 전부 정확히 두 칸 들여쓰기였고, 코드블록과 표도 0건이며, 빈 줄은 항상 다음 항목의 굵은 불릿 앞에만 온다(17곳). 다만 이것은 오늘의 데이터에 대한 판정이다. 둘째, 슬러그 충돌은 실데이터 53개에서 0건이었고 파일명 최대 길이는 60자로 어느 파일 시스템 한계에도 안 걸린다 — 그래서 충돌·길이는 위험이 아니라 YAGNI 로만 올렸다. 셋째, Task 2 의 화이트리스트 변경 자체는 정확 일치 비교라 `solved_problems` 와 `solved_problems.md` 가 서로 간섭하지 않는다. 넷째, 확인하지 못한 것이 하나 있다 — 두 테스트 파일의 `run` 헬퍼 본문을 열지 않았다. Task 2·3·4 의 새 check 가 그 헬퍼의 stdout/stderr 캡처 방식과 맞는지는 그 두 파일을 열어야 확정된다."
}
```
