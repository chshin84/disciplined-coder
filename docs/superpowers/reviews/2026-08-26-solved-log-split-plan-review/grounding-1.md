# reviewer-grounding 1회차 원본 (계획 · 2026-08-26)

검토 대상: `docs/superpowers/plans/2026-08-26-solved-log-split.md`
띄운 방식: 읽기 전용 서브에이전트 1회. 이 렌즈는 계획의 스크립트를 임시 디렉터리에 재현해 **실제로
돌려 보고** 판정했다. 전사본(`tasks/<id>.output`)은 완료 후 0바이트가 되므로 완료 통지에 실려 온
JSON을 그대로 옮겨 둔다.

```json
{
  "lens": "grounding",
  "angles_scanned": [
    "계획이 지목한 줄 번호를 실제 파일과 한 자리씩 대조",
    "계획이 고치라는 scaffold.sh·codex-scaffold.sh 구간에 무엇이 있는지 확인",
    "테스트 헬퍼(check·run·HERE)의 이름과 인자 순서를 두 테스트 스위트에서 각각 확인",
    "계획이 인용한 과거 사고가 docs/solved_problems.md에 있는지 확인",
    "새 형식 규칙 블록과 포인터 세는 grep의 충돌 여부를 임시 파일로 재현",
    "ls -1 \"$dir\"/*.md | wc -l 를 빈 폴더·없는 폴더·공백 이름·개행 이름에 직접 실행",
    "Task 4의 정규식을 두 실물 로그에 직접 실행하고 사람이 세는 항목 수와 대조",
    "Task 5의 파이썬 조각을 임시 디렉터리에 그대로 재현해 계획의 픽스처로 실행(멱등성 재실행 포함)",
    "Task 1의 패치를 임시 사본에 적용해 Task 7·8 직후 상태에서 머리말 갈아끼우기를 실행",
    "git log --follow 이력에서 형식 단일화·되돌리기 회차 확인",
    ".gitattributes의 줄 끝 규칙 확인",
    "Task 6 Step 1의 앵커 grep을 실제로 실행",
    "레포의 python 호출 관례와 파이썬 stdout 인코딩 실측"
  ],
  "findings": [
    {
      "claim": "Modify: `scripts/_scaffold_common.sh:18-25`, `:107-118`, `:61-87`, `:129` 이후",
      "verdict": "confirmed",
      "measured": "네 자리 모두 그 줄에 그 대상이 있다. `scaffold_check_solved_rules`만 107줄에서 117줄까지이고 118줄은 빈 줄이라 한 줄 넉넉하게 적혀 있다.",
      "evidence": "`grep -n '^[a-z_]*() *{\\|^SCAFFOLD_' scripts/_scaffold_common.sh` → `6`, `18`, `61`, `107`, `129`, `180`",
      "why_it_matters": "구현자가 여는 자리가 맞으므로 이 지목 때문에 엉뚱한 곳을 고치지는 않는다."
    },
    {
      "claim": "Modify: `scripts/_scaffold_common.sh:6` (화이트리스트)",
      "verdict": "confirmed",
      "measured": "6줄이 그 값이다. 계획이 테스트에서 찾는 경고 문구도 실물과 맞다 — `scaffold_hygiene`이 46줄에서 `비관리 디렉터리 '$b' 잔존(자동삭제 안 함, 확인 요)`을 stderr로 낸다.",
      "evidence": "scripts/_scaffold_common.sh:6, :40-48",
      "why_it_matters": "화이트리스트를 안 고치면 이관 직후부터 매 세션 오탐 경고가 뜬다는 진단이 실물에서 성립한다."
    },
    {
      "claim": "`scripts/scaffold.sh:48-60`과 `scripts/codex-scaffold.sh:37-48`을 고친다",
      "verdict": "confirmed",
      "measured": "scaffold.sh 48줄이 전역 호출, 49줄이 `pc_note`, 54-61줄이 프로젝트 로그 처리다. codex-scaffold.sh 37-38줄과 42-49줄이 대응한다.",
      "evidence": "scripts/scaffold.sh:48-61, scripts/codex-scaffold.sh:37-49",
      "why_it_matters": "삽입 자리가 실물과 맞다."
    },
    {
      "claim": "계획의 테스트 조각이 쓰는 헬퍼 `check`·`run`·`HERE`가 두 테스트 스크립트에 있다",
      "verdict": "contradicted",
      "measured": "`HERE`와 `check`는 두 스위트에서 같다. 그러나 `run`이 다르다. `test_scaffold.sh:16-18`의 `run`은 `$1=HOME, $2=프로젝트`를 받는데, `test_codex_scaffold.sh:8`의 `run`은 `$1` 하나만 받고 `CLAUDE_PROJECT_DIR`을 아예 세우지 않는다. codex-scaffold.sh:42는 `PROJ=\"${CLAUDE_PROJECT_DIR:-$PWD}\"`라 테스트를 레포에서 돌리면 `PLOG`가 이 레포의 실제 `docs/solved_problems.md`로 잡힌다.",
      "evidence": "scripts/test_scaffold.sh:16-18 대 scripts/test_codex_scaffold.sh:8; `grep -n 'CLAUDE_PROJECT_DIR' scripts/test_codex_scaffold.sh` → 0건",
      "why_it_matters": "구현자가 `run \"$HP1\" \"$PP1\"` 꼴을 그대로 옮기면 둘째 인자가 조용히 무시된다. Task 7로 이 레포 로그가 쪼개진 뒤에는 `bash scripts/test_codex_scaffold.sh`가 레포의 진짜 오답노트에 머리말 갈아끼우기를 실행하게 된다."
    },
    {
      "claim": "이 레포는 정본 산문을 다듬다 계약 테스트 셋을 깬 적이 있다",
      "verdict": "confirmed",
      "measured": "`docs/solved_problems.md:79`가 그 항목이고 81줄의 해결이 계획 Task 6 Step 1의 절차와 같은 문장이다.",
      "evidence": "docs/solved_problems.md:79-81, :52-54",
      "why_it_matters": "계획이 인용한 근거가 실물에 있으므로 Task 6의 앵커 확인은 지어낸 조심성이 아니다."
    },
    {
      "claim": "Task 6 Step 1 — `grep -n '비슷한 증상을 먼저 찾는다' scripts/test_*.sh`",
      "verdict": "confirmed",
      "measured": "0건이다. 그 recall 불릿의 다른 문구도 테스트 앵커가 아니다.",
      "evidence": "`grep -rn '비슷한 증상을 먼저 찾는다\\|도출 우선\\|스코프 라우팅' scripts/test_*.sh` → 0건",
      "why_it_matters": "Task 6 Step 5의 초록이 recall 문장 교체를 검증하지 않는다. 이 절 문구를 지키는 계약이 지금 하나도 없다."
    },
    {
      "claim": "새 형식 규칙 블록과 Task 3의 포인터 grep이 충돌한다",
      "verdict": "contradicted",
      "measured": "충돌하지 않는다. 임시 파일로 재현하니 `grep -c -- '→ solved_problems/'`가 1을 냈다. 규칙 불릿에는 화살표가 없다.",
      "evidence": "임시 디렉터리 실행 — 화살표 포함 1, 화살표 제외 2",
      "why_it_matters": "이 자리는 안전하다. 다만 세는 근거가 규칙 문장이 화살표를 계속 안 쓰는 데 달려 있다."
    },
    {
      "claim": "Task 3의 `files=\"$(ls -1 \"$dir\"/*.md 2>/dev/null | wc -l | tr -d ' ')\"`",
      "verdict": "confirmed",
      "measured": "빈 폴더 0, 없는 폴더 0, 공백 이름 둘에서 2가 나왔다. 개행이 든 이름에서만 과다 계수한다.",
      "evidence": "임시 디렉터리 실행 — empty [0], nodir [0], space [2], newline [4]",
      "why_it_matters": "물은 두 경우는 맞고, 0이 나오는 경우는 앞의 쪼개짐 판정이 먼저 걸러 도달하지 않는다."
    },
    {
      "claim": "Task 4의 `grep -c -E '^[-*+][ \\t]+\\*\\*'` — 항목은 굵은 증상 줄로 센다",
      "verdict": "confirmed",
      "measured": "레포 27, 전역 53이 나온다. 최상위 불릿 전체는 33과 59이고 차이 6은 머리말의 규칙 불릿 여섯이다. 다만 GNU grep에서 대괄호 안의 `\\t`는 탭이 아니라 글자 `t`로 읽힌다 — 반대로 Task 5의 파이썬은 같은 자리에서 `\\t`를 진짜 탭으로 읽는다.",
      "evidence": "두 로그에 직접 실행; 탭·`t` 시험 파일에서 탭 줄은 안 걸림",
      "why_it_matters": "지금은 탭 항목이 없어 셈이 맞는다. 그러나 Task 7 Step 3이 grep 값과 파이썬이 만든 파일 수를 맞대는데, 두 셈이 탭에서 다르게 판정한다."
    },
    {
      "claim": "Task 5 — 계획의 픽스처를 넣으면 본문 둘이 생기고, 옛 한 줄 항목 하나가 남고, 색인에 포인터가 생긴다",
      "verdict": "confirmed",
      "measured": "임시 디렉터리에 스크립트를 그대로 옮겨 적고 픽스처를 넣어 돌렸다. 본문 파일 둘이 생겼고 옛 한 줄 항목이 색인에 남았으며 포인터가 붙었다. 색인에서 '첫째 원인'은 사라졌고 머리말은 보존됐다. 사본도 떴고, 백업 디렉터리를 못 만드는 경우에는 아무것도 안 하고 2로 끝났다.",
      "evidence": "재현 디렉터리 실행 결과",
      "why_it_matters": "핵심 동작은 계획이 적은 대로 나온다."
    },
    {
      "claim": "Task 5 — 이미 쪼개진 로그에는 아무것도 안 한다(멱등), 그리고 테스트 `쪼개기: 두 번 돌려도 같다`",
      "verdict": "contradicted",
      "measured": "멱등이 아니다. 두 번째로 돌리니 `첫째-증상이-났다-2.md`와 `둘째-증상이-났다-맥락-2.md`가 새로 생겨 본문이 2개에서 4개가 되었고, 색인의 포인터가 `-2` 파일로 갈아치워져 원래 두 본문이 고아가 되었다. cksum이 2323526997에서 3942416983으로 바뀌었다. 원인은 색인 줄이 `- **첫째 증상이 났다**`처럼 굵은 채라 두 번째 실행에서도 항목 머리로 걸리고, 바로 아래 포인터 줄이 두 칸 들여쓰기라 '본문 있음'으로 판정되기 때문이다.",
      "evidence": "재현 실행 — CK1=2323526997, CK2=3942416983, IDEMPOTENT: FAIL, 2회차 뒤 count=4",
      "why_it_matters": "Task 5 Step 4가 기대하는 FAIL=0이 안 나온다. 그보다 무거운 것은 Task 7이다 — 사람이 실수로 한 번 더 돌리면 본문이 두 벌이 되고 원본이 고아가 되는데, Task 3의 짝 맞춤은 어긋남만 알릴 뿐 어느 쪽이 원본인지 알려주지 않는다."
    },
    {
      "claim": "테스트 `쪼개기: 못 가른 수를 알린다`가 `grep -qF -- '손으로 가를 항목 1개'`",
      "verdict": "contradicted",
      "measured": "이 PC에서 그 검사는 실패한다. 파이썬의 `sys.stdout.encoding`이 `cp949`라 한글이 cp949 바이트로 나가는데 grep은 UTF-8 바이트를 찾는다. `PYTHONIOENCODING=utf-8`을 주면 UTF-8로 나온다.",
      "evidence": "`od -c` 비교, `python -c \"import sys;print(sys.stdout.encoding)\"` → `cp949`, python 3.12.10",
      "why_it_matters": "계획의 제약은 '한글이 든 파일은 UTF-8로 읽고 쓴다'인데 스크립트는 파일 입출력에만 인코딩을 걸었다. stdout이 빠져서 Task 5 Step 4의 FAIL=0이 이 머신에서 성립하지 않는다."
    },
    {
      "claim": "Task 5 Step 3 — `python - \"$LOG\" \"$DIR\" \"$TMP\"`",
      "verdict": "contradicted",
      "measured": "이 레포의 관례는 `python3`를 먼저 시도하고 없으면 `python`으로 떨어지는 것이다(`_json_valid.sh:6-9`, `_ensure_autoupdate.sh:58-61`, `test_scaffold.sh:47-48`). 계획의 스크립트만 맨 `python`을 부른다. 전역 오답노트 15줄에 '이 PC의 python3는 Windows Store 스텁'이라는 항목이 있어 두 이름이 실제로 갈렸던 이력이 있다.",
      "evidence": "세 스크립트의 해당 줄; 전역 로그 15줄",
      "why_it_matters": "`python`만 있는 환경과 `python3`만 있는 환경 둘 다 현실이라, 관례를 안 따르면 스크립트가 2를 내며 죽는다."
    },
    {
      "claim": "Task 5 Step 2 — Expected: 전부 FAIL(스크립트가 없다)",
      "verdict": "contradicted",
      "measured": "전부는 아니다. 마지막 항목 `쪼개기: 사본 못 뜨면 안 고친다`는 `! [ -d … ]`라 스크립트가 없어도 참이라 PASS로 세어진다.",
      "evidence": "계획의 그 check 줄 자체",
      "why_it_matters": "구현자가 기대와 실측이 달라 시간을 쓴다. 그리고 그 한 줄은 스크립트 유무와 무관하게 참이라 항진 검사에 가깝다."
    },
    {
      "claim": "Task 1 — `scaffold_fix_solved_header` 안의 두 곳도 같은 선택을 쓰게 한다",
      "verdict": "contradicted",
      "measured": "그 두 곳만 고치면 쪼개진 로그의 색인 첫 줄이 조용히 지워진다. `_scaffold_common.sh` 임시 사본에 Task 1의 패치를 넣고 Task 7·8 직후 모습으로 `scaffold_sync_solved`를 돌렸더니, 머리말이 새 규칙으로 갈리면서 첫 색인 줄이 사라지고 포인터만 고아로 남았다. **그런데 알림 문구는 '항목은 그대로 두었다'라고 말한다.** 원인은 계획이 손대지 않은 경계 계산 awk다(`:146`) — 지시사항형 색인 줄이 '굵지 않은 최상위 불릿'이라 남은 규칙 불릿으로 오인된다. Task 3의 짝 맞춤도 포인터가 그대로 둘이라 조용하다.",
      "evidence": "재현 디렉터리의 패치 사본으로 실행. 실행 전 색인 2줄, 실행 후 첫 줄 사라짐. 노트는 `머리말을 현행 형식으로 갱신했다(항목은 그대로 두었다...)`. 근거 코드 scripts/_scaffold_common.sh:144-148",
      "why_it_matters": "이것이 이 계획에서 가장 무거운 어긋남이다. Task 7 Step 7이 이 경로를 반드시 지나간다. 두 로그 모두 `항목을 적는 형식은 이렇다.` 줄을 이미 갖고 있어 awk의 `seen` 가지가 확실히 발화한다. 손실은 조용하고, 짝 맞춤도 못 잡고, 알림 문구는 반대로 말한다(`FAIL-LOUD` 위반). 계획의 Task 1 Step 6 픽스처는 `intro`가 없어 이 가지를 안 타므로 테스트는 초록인 채 실물만 깨진다."
    },
    {
      "claim": "Task 8 — git 이력에 형식 단일화·되돌리기 회차가 섞여 있다",
      "verdict": "confirmed",
      "measured": "그 이력에 21회차가 있고 두 회차가 실제로 있다 — `ea80f93 2026-07-03 오답노트 항목 형식을 단일화한다`, `6dc9980 2026-07-28 revert(canon)`. 계획이 이름을 안 댄 `63cbef3 2026-07-28 기계 치환이 망가뜨린 조사…`도 같은 종류다.",
      "evidence": "`git log --follow --format='%h %ad %s' --date=short -- docs/solved_problems.md`",
      "why_it_matters": "주의에 근거가 있다. 다만 걸러야 할 회차가 둘이 아니라 셋이다."
    },
    {
      "claim": "`.gitattributes`가 `*.sh`와 `*.md`의 줄 끝을 LF로 고정한다",
      "verdict": "confirmed",
      "measured": "`*.sh text eol=lf`와 `*.md text eol=lf`가 있다.",
      "evidence": "D:\\projects\\disciplined-coder\\.gitattributes",
      "why_it_matters": "제약의 전제가 실물과 맞는다."
    },
    {
      "claim": "Task 7 Step 7 — `bash scripts/scaffold.sh` / Expected: 머리말이 새 형식 규칙으로 갈렸다",
      "verdict": "unverifiable",
      "measured": "지금 세션 훅이 도는 스캐폴드와 이 워크트리의 스캐폴드가 다른 판본이다. 전역 오답노트의 머리말은 옛 문안이라 워크트리 기준으로는 낡음인데 백업에 `solved_problems.pc.*`가 하나도 없다. 설치된 플러그인 캐시가 여러 SHA로 있고, 규칙 문구를 지금 값으로 바꾼 커밋은 워크트리의 오늘 커밋이다. 실제 훅이 어느 사본을 쓰는지는 훅을 돌려야 아는데 그것은 실물을 고치는 일이라 하지 않았다.",
      "evidence": "전역 로그 1-13줄 대 scripts/_scaffold_common.sh:18-25; 백업 목록에 `solved_problems.pc.*` 없음",
      "why_it_matters": "Task 7 Step 7이 워크트리 스크립트를 손으로 돌려 확인하는데, 다음 세션의 훅은 캐시된 옛 판본을 돌릴 수 있다. 옛 판본은 쪼개짐을 모르므로 쪼개진 색인에 옛 규칙 블록을 갈아끼우려 들고, 그때 색인 줄 삼킴이 발동한다."
    },
    {
      "claim": "Task 7 Step 3 — 항목 수가 Step 1의 값과 맞는지 확인한다",
      "verdict": "confirmed",
      "measured": "계획의 파이썬 규칙을 두 실물 로그에 읽기만 하는 시늉으로 돌려 보니, 레포는 갈릴 항목 27에 손으로 가를 항목 0이고, 전역은 갈릴 항목 46에 손으로 가를 항목 7이다. 합이 27과 53으로 grep 셈과 맞는다.",
      "evidence": "읽기 전용 파이썬 시뮬레이션",
      "why_it_matters": "Task 7 Step 4의 손작업 분량이 전역 7건으로 미리 잡힌다."
    },
    {
      "claim": "새 형식 규칙 — '이 파일은 색인이고 한 줄이 한 항목이다. 줄에는 지시사항만 적는다.'",
      "verdict": "contradicted",
      "measured": "Task 5의 스크립트가 만드는 색인 줄은 `- **첫째 증상이 났다**`로 굵은 증상 그대로다. 본문 제목도 `# **첫째 증상이 났다**`다. 즉 Task 7이 끝난 시점의 색인은 새 규칙 블록이 선언하는 형식을 지키지 않는다.",
      "evidence": "재현 실행 결과의 색인과 본문 첫 줄",
      "why_it_matters": "Task 7과 Task 8 사이에 로그는 '새 규칙을 선언하면서 그 규칙을 안 지키는 상태'로 머문다. Task 1의 존재 이유가 그 상태를 막는 것인데 스스로 한 구간 만든다."
    }
  ],
  "principles_applied": ["MEASURE-FIRST", "FAIL-LOUD", "IDEMPOTENT", "TDD", "SSOT", "EXPLICIT", "SIMPLE", "REVERSIBLE"],
  "notes": "확인하지 못한 것을 적는다. 첫째, 실제 세션 훅이 어느 스캐폴드 사본을 실행하는지는 확인하지 못했다 — 훅을 돌리면 전역 오답노트와 사용자 CLAUDE.md를 실제로 고치게 되어 읽기 전용 범위를 벗어난다. 둘째, `test_codex_scaffold.sh`를 실제로 돌려 보지 않았다 — 그 스위트의 `run`이 이 레포의 진짜 로그를 대상으로 삼을 수 있어 돌리는 것 자체가 파일을 고칠 위험이 있다. 셋째, 계획이 가리키는 spec은 존재만 확인했고 내용 정합은 검증 목록 밖이라 대조하지 않았다. 넷째, `skills/domain-docs/SKILL.md`의 두 표는 열지 않았다. 다섯째, 재현은 모두 임시 디렉터리에서만 했고 레포 파일과 전역 관리 디렉터리는 읽기만 했다. 여섯째, 색인 줄 삼킴 재현은 Task 1의 지시를 내가 해석해 최소로 옮긴 것이라 구현자가 다르게 쓰면 결과가 달라질 수 있다 — 다만 원인인 경계 계산 awk는 계획이 손대지 않는 자리이므로 해석 차이와 무관하게 남는다."
}
```
