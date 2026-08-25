# reviewer-consistency 1회차 원본 (계획 · 2026-08-26)

검토 대상: `docs/superpowers/plans/2026-08-26-solved-log-split.md`
띄운 방식: 읽기 전용 서브에이전트 1회. 전사본(`tasks/<id>.output`)은 완료 후 0바이트가 되므로
완료 통지에 실려 온 JSON을 그대로 옮겨 둔다.

```json
{
  "lens": "consistency",
  "angles_scanned": [
    "계획이 인용한 파일·줄 번호와 함수 이름을 실물과 대조",
    "scaffold_solved_header 시그니처 확대에 대한 호출부 전수 조사(레포 전체 grep)",
    "테스트 헬퍼 run·check·HERE의 실제 시그니처와 계획이 쓴 호출 형태 대조(Claude/Codex 쌍둥이)",
    "색인 줄을 포인터로 세는 방식과 새 형식 규칙 블록의 solved_problems/ 문자열 간섭 여부",
    "항목을 굵은 줄로 세는 방식과 규칙 불릿·색인 불릿의 간섭 여부",
    "Task 5 파이썬 조각을 픽스처로 손실행(항목 수집 루프·빈 줄·옛 한 줄 형식·슬러그·멱등·U+2028)",
    "머리말 갈아끼우기(awk 경계 계산)와 새 색인 형식의 충돌",
    "spec→plan 커버리지(검증 절 항목별)와 plan→spec 역방향",
    "태스크 사이 의존 순서와 커밋 경계",
    "상시 제약 준수(쌍둥이 동시 수정·FAIL=0·매직 넘버 금지·뮤테이션 검증·리터럴 픽스처)",
    "set -e/set -u 아래에서의 변수 초기화와 파이프 종료코드",
    "새 검사가 기존 검사와 부딪히는지(항진·출력 오염)"
  ],
  "findings": [
    {
      "kind": "contradiction",
      "where": "Task 5 Step 3 스크립트 — `title = re.sub(r\"^[-*+][ \\t]+\", \"\", head).strip()` 와 `out.append(\"- \" + title)`",
      "problem": "제목에서 굵게 표시(`**`)를 벗기지 않는다. slug()만 별표를 지우고 색인 줄과 본문 첫 줄에는 `**첫째 증상이 났다**`가 그대로 남는다. 그래서 두 번째 실행에서 그 색인 줄이 다시 `^[-*+][ \\t]+\\*\\*`에 걸려 항목 머리로 판정되고, 바로 아래 포인터 줄(`  → …`)이 들여쓴 본문으로 수집돼 비어 있지 않으므로 또 갈린다 — 이름이 겹쳐 `…-2.md`가 새로 생기고 색인 줄의 포인터가 그 새 파일로 바뀐다.",
      "evidence": "계획 476-541행(스크립트 본문), 518행 `if not re.match(r\"^[-*+][ \\t]+\\*\\*\", line)`, 528·532행 / 같은 태스크의 자기 검사 455-457행 `쪼개기: 두 번 돌려도 같다` / spec 54-57행이 정한 색인 줄 예시는 굵지 않은 평문이다",
      "why_it_matters": "Task 5가 자기 테스트(`두 번 돌려도 같다`)를 통과하지 못해 그 자리에서 막힌다. 통과시키려고 판정 정규식을 손보면 이번에는 옛 한 줄 형식 판별이 흔들린다. 그대로 두면 멱등이 깨져 재실행마다 본문 파일이 늘고, 색인은 spec이 정한 형식이 아니라 굵은 줄로 남아 Task 8의 다시 쓰기 전제와 어긋난다."
    },
    {
      "kind": "contradiction",
      "where": "Task 1 Step 5 — `scaffold_fix_solved_header` 안의 `intro=` 한 줄만 바꾼다",
      "problem": "새 색인 줄은 굵지 않은 불릿(`- 지시사항…`)인데, 머리말 경계를 계산하는 awk는 도입 문장 뒤의 '굵지 않은 불릿'을 남은 규칙 불릿으로 보고 통째로 건너뛴다. 지시사항형 색인이 완성된 로그에서 형식 규칙이 한 번이라도 낡음으로 판정되면, 경계가 색인 줄들을 지나 첫 포인터 줄(`  → …`)에 찍히고 tail이 거기서부터 옮겨져 **색인 줄이 전부 사라지고 포인터만 남는다**. 계획이 바꾸는 `intro`는 두 규칙 블록의 첫 줄이 `항목을 적는 형식은 이렇다.`로 같아 값이 변하지 않는 무동작 변경이라, 이 자리를 손봤다는 착각만 남긴다.",
      "evidence": "D:\\projects\\disciplined-coder\\scripts\\_scaffold_common.sh:144-148 (`if (line[i] ~ /^[-*+][ \\t]/ && line[i] !~ /^[-*+][ \\t]+\\*\\*/) continue`) / 계획 70-79행(SPLIT 규칙 블록 첫 줄이 기존과 동일) · 133행(`intro=` 교체) / 기존 계약 테스트 scripts/test_scaffold.sh:556-566 이 바로 그 경로를 굳혀 두었다",
      "why_it_matters": "spec의 검증 항목 '머리말 형식 규칙 갱신이 항목을 보존한다'와 '사람이 색인에 적어 둔 절이 살아남는다'가 쪼개진 로그에서 깨진다. 전역 로그는 git 밖이라 사본 말고는 되돌릴 길이 없고, 갱신은 조용히 성공으로 보고된다. 계획에는 쪼개진 로그로 머리말 갱신을 돌려 보는 검사가 하나도 없어 이 손실이 테스트를 통과한다."
    },
    {
      "kind": "gap",
      "where": "Task 1 전체 — 새로 두는 것은 `SCAFFOLD_SOLVED_RULES_SPLIT` 하나뿐이다",
      "problem": "머리말의 제목 줄과 스코프 문단이 여전히 `append-only 오답노트` · `과거 항목은 사용자가 직접 지시할 때만 손댄다`로 쪼개진 로그에도 붙는다. 그런데 같은 머리말 아래 새 규칙 블록은 '사용자 요청으로 고치거나 지울 때는 색인 줄도 함께 고치거나 지운다'를 선언한다 — 한 파일이 자기를 append-only라고 부르면서 줄을 고치라고 지시한다.",
      "evidence": "D:\\projects\\disciplined-coder\\scripts\\_scaffold_common.sh:65·68·74·77(제목과 스코프 문단) / 계획 79행(색인 줄을 함께 고치라는 규칙) / spec 229-232행",
      "why_it_matters": "spec이 이름 대어 고치라고 한 자리를 계획이 빼먹었다. 선언을 믿고 색인에 줄만 더한 세션이 손실을 겪는다는 것이 spec이 든 실패 시나리오 그대로다."
    },
    {
      "kind": "contradiction",
      "where": "Task 1 Step 2 — 'Expected: FAIL이 3 늘어난다(`scaffold_solved_log_is_split: command not found`)'",
      "problem": "Step 1의 세 검사 가운데 둘은 `\"! (. …; scaffold_solved_log_is_split …)\"` 꼴이다. 함수가 없으면 서브셸이 127로 끝나고 `!`가 뒤집어 **통과**한다. 실제로 붉어지는 것은 세 번째(긍정 단언) 하나뿐이다.",
      "evidence": "계획 49·51·53행(부정 단언 둘, 긍정 단언 하나) · 61행(기대치) / scripts/test_scaffold.sh:8 `check() { if eval \"$2\"; then …` — 종료코드만 본다",
      "why_it_matters": "구현자가 기대치와 실측이 달라 자기 테스트를 의심하다 시간을 쓰거나, 반대로 '3 늘었다'를 맞추려 검사를 억지로 고친다. 더 나쁜 것은 그 부정 단언 둘이 구현 후에도 **함수가 없을 때조차 초록**이라는 점이다 — 이 레포가 반복해 겪은 항진 검사와 같은 모양이고, Step 7 뮤테이션 검증도 그 둘은 잡지 못한다."
    },
    {
      "kind": "contradiction",
      "where": "Task 1 Step 8 · Task 2 Step 4 · Task 3 Step 7 · Task 4 Step 5 — '`scripts/test_codex_scaffold.sh`에 같은 계약을 넣는다'",
      "problem": "Codex 쪽 `run` 헬퍼는 인자를 하나만 받고 `CLAUDE_PROJECT_DIR`을 세팅하지 않는다. 그래서 codex-scaffold는 `PROJ=$PWD`, 즉 **이 레포 자신**을 프로젝트로 잡고 `docs/solved_problems.md`를 프로젝트 로그로 처리한다. Task 4를 넣는 순간 그 로그(아직 안 쪼개짐, 항목 다수)에 대한 개편 권유가 codex 테스트의 모든 `run` 출력에 섞인다.",
      "evidence": "scripts/test_codex_scaffold.sh:8 `run() { CODEX_HOME_DIR=\"$1/.codex\" CLAUDE_PLUGIN_ROOT=\"$HERE\" bash \"$SCAFFOLD\"; }` (둘째 인자 없음) / scripts/codex-scaffold.sh:42-49 `PROJ=\"${CLAUDE_PROJECT_DIR:-$PWD}\"` · `PLOG=\"$PROJ/docs/solved_problems.md\"` / D:\\projects\\disciplined-coder\\docs\\solved_problems.md 는 실재한다(20,701바이트) / 옮겨 적을 원본인 계획 366행은 `! … grep -qF -- '개편'`",
      "why_it_matters": "옮겨 적은 부정 단언(`쪼개진 로그엔 안 권함`, `맞으면 조용하다`)이 픽스처와 무관한 레포 자신의 로그 때문에 FAIL한다. 더 큰 문제는 Task 7 뒤다 — codex 테스트를 한 번 돌릴 때마다 스캐폴드가 **git이 추적하는 실제 `docs/solved_problems.md`의 머리말을 다시 쓴다**. 계획은 이 격리 차이를 '`run` 헬퍼에 맞춰 옮겨 적는다' 한 줄로만 처리해 구현자가 알아채기 어렵다."
    },
    {
      "kind": "gap",
      "where": "Task 3 Step 4 · Task 4 Step 4 — '프로젝트 로그 쪽도 같은 자리에 … `proj_pairing=\"$solved_pairing_note\"`를 넣고'",
      "problem": "프로젝트 노트 변수는 `if [ -f \"$PLOG\" ]` 블록 **바깥**에서 미리 빈 문자열로 초기화되어 있어야 한다. 계획은 블록 안에 대입만 넣으라고 하고 초기화를 말하지 않는다. 두 스캐폴드는 `set -euo pipefail`이라 프로젝트 로그가 없는 세션에서 인쇄 루프가 `unbound variable`로 훅 전체를 죽인다.",
      "evidence": "scripts/scaffold.sh:5(`set -euo pipefail`)·56(`proj_note=\"\"` 가 if 밖에 있는 이유가 바로 이것)·114 인쇄 루프 / scripts/codex-scaffold.sh:6·44·77 / 계획 314행·396행",
      "why_it_matters": "오답노트가 없는 프로젝트에서 세션 시작 훅이 통째로 죽는다. 계획의 테스트 픽스처는 대부분 프로젝트 디렉터리를 mktemp로 주고 로그를 안 만들므로 이 경로를 곧바로 밟는다."
    },
    {
      "kind": "gap",
      "where": "계획 전체 — spec 「검증」 절의 첫 항목이 계획에 없다",
      "problem": "spec은 '**스캐폴드는 색인을 쓰지 않는다** — 세션을 돌려도 색인 파일의 내용이 바뀌지 않는다. 이 계약이 깨지면 잠금과 순서 문제가 통째로 되돌아오므로 **가장 먼저 건다**'고 정했는데, 그 계약을 거는 태스크도 검사도 없다. 계획은 Global Constraints 22행에 산문으로만 적어 두었다.",
      "evidence": "spec 306-307행 / 계획 22행(제약으로만 서술, 대응 태스크 없음) / Task 1·3·4의 검사 목록에 색인 내용 불변 단언이 없다",
      "why_it_matters": "spec이 '가장 먼저'라고 지정한 계약이 기계로 안 걸린다. 게다가 이 계약은 있는 그대로 참이 아니다 — 스캐폴드는 색인 파일의 머리말을 실제로 다시 쓴다. 계약 문장을 '항목·색인 줄은 안 바뀐다'로 좁혀 적지 않으면 검사를 쓸 때마다 무엇을 단언할지 갈린다."
    },
    {
      "kind": "gap",
      "where": "계획 전체 — 되돌리기 절차가 없다",
      "problem": "spec이 '되돌리기는 \"사본으로 통째로 덮기\"가 아니라 \"사본에 있던 항목만 되살리기\"로 정하고, **그 절차를 계획에 적는다**'고 계획에 숙제를 넘겼는데 계획 어디에도 그 절차가 없다. Task 7은 사본을 뜨는 것까지만 적는다.",
      "evidence": "spec 176-179행 / 계획 613-657행(Task 7)에 사본 경로를 적어 두라는 지시만 있고 되살리기 절차 없음",
      "why_it_matters": "Task 7은 계획 스스로 '여기서부터 되돌리기 어려운 걸음'이라 부른 자리다. 되돌릴 방법을 모른 채 전역 로그를 쪼개면 `REVERSIBLE`이 요구하는 돌아올 길이 없다."
    },
    {
      "kind": "gap",
      "where": "Task 5 Step 1 픽스처 — 항목 사이에 빈 줄이 없다",
      "problem": "spec은 '**이관은 첫 줄 말고는 안 바꾼다** … **빈 줄이 여러 곳에 낀 픽스처로 확인한다**'고 못박았는데, 계획의 픽스처는 항목이 빈 줄 없이 붙어 있다. 정작 스크립트에서 가장 미묘한 곳이 빈 줄 처리(`if lines[j].strip() == \"\" and not (j+1 … startswith(\"  \"))`)인데 그 가지가 한 번도 실행되지 않는다.",
      "evidence": "spec 314-315행 / 계획 435-442행(픽스처) · 522-525행(빈 줄 가지) / 실제 로그에는 빈 줄이 낀다 — scripts/test_scaffold.sh:534·536 의 옛 로그 픽스처가 그 모양이다",
      "why_it_matters": "항목 사이 빈 줄이 본문으로 딸려 들어가거나 항목이 조기에 끊기는 회귀가 초록으로 통과한다. 이관은 79개를 한 번에 옮기는 비가역 걸음이라 여기서 못 잡으면 손실이 그대로 확정된다."
    },
    {
      "kind": "gap",
      "where": "계획 전체 — 주입 시 포인터의 뿌리를 알리는 태스크가 없다",
      "problem": "spec은 '색인 줄의 포인터는 그 색인 파일이 놓인 자리를 기준으로 읽는다 … **스캐폴드가 주입할 때 그 뿌리를 한 줄로 함께 적는다**'고 요구한다. 이를 구현하는 태스크가 없다.",
      "evidence": "spec 74-76행 / scripts/codex-scaffold.sh:74 `cat \"$KDIR/solved_problems.md\"` (뿌리 표기 없음) · scripts/scaffold.sh:96(@import 경로) / 계획의 여덟 태스크 어디에도 대응 항목 없음",
      "why_it_matters": "전역 색인과 프로젝트 색인이 같은 `solved_problems/…` 문자열을 쓰는데 주입된 뒤에는 구별이 안 된다. 세션이 엉뚱한 뿌리에서 본문을 찾다 못 찾으면, 새로 넣는 규칙에 따라 '가리키는 본문이 없으니 그 줄을 지운다'로 넘어가 멀쩡한 색인 줄을 지운다."
    },
    {
      "kind": "gap",
      "where": "Task 6 전체 — 실패하는 테스트도, 뮤테이션 검증도, 새 검사도 없다",
      "problem": "계획 자신의 상시 제약이 '새 계약을 넣으면 회귀를 일부러 심어 FAIL이 뜨는 것을 확인하고 되돌린다'인데 Task 6은 문장만 고치고 기존 테스트 두 개를 돌린다. 그런데 `scripts/test_docs_drift.sh`에는 오답노트·solved 관련 앵커가 하나도 없어 Step 5의 'FAIL=0' 확인이 이 변경에 대해 아무것도 보증하지 않는다. Step 1이 찾으라는 `비슷한 증상을 먼저 찾는다` 앵커도 스크립트 어디에도 없다.",
      "evidence": "계획 18행(상시 제약) · 566-609행(Task 6) / `grep -n 'solved|오답노트|append-only' scripts/test_docs_drift.sh` → 없음 / `grep -rn '비슷한 증상' scripts/ skills/ hooks/` → 없음 / spec 310-313행",
      "why_it_matters": "정본의 recall 규칙이 이 설계의 목적 자체인데 그것만 검사 없이 들어간다. 다음에 누가 산문을 다듬다 되돌려도 아무 신호가 없다."
    },
    {
      "kind": "gap",
      "where": "Task 6 Step 3·Step 4 — 정본 한 줄 추가와 'domain-docs의 두 표를 고친다'",
      "problem": "둘 다 대상이 모자란다. 정본에 더하는 문장에는 spec이 짝으로 정한 반대 방향 규칙('본문 파일은 있는데 색인 줄이 없으면 그 파일의 첫 줄로 색인 줄을 만들어 붙인다')이 빠졌다 — 정작 Task 3이 내보내는 신호 문구는 그 규칙을 전제로 '본문만 있으면 첫 줄로 색인 줄을 채운다'고 시킨다. `domain-docs`도 표 둘만 지목했는데 오답노트를 통째로 append-only라 선언하는 곳이 표 밖에 둘 더 있다.",
      "evidence": "spec 97-98행(반대 방향) / 계획 592행(추가 문장에 그 규칙 없음) · 300행(신호 문구는 그 규칙을 지시한다) / skills/domain-docs/SKILL.md:87(각주) · :111",
      "why_it_matters": "스캐폴드가 시키는 일의 근거가 정본에 없어, 규칙을 못 찾은 세션이 그 신호를 무시하거나 제 나름으로 처리한다. domain-docs에는 색인이 living이라는 새 선언과 오답노트가 통째로 append-only라는 옛 선언이 한 파일에 공존하게 된다(`SSOT` 위반)."
    },
    {
      "kind": "drift",
      "where": "Task 5 Step 3 — `python - \"$LOG\" \"$DIR\" \"$TMP\" <<'PY'`",
      "problem": "이 레포의 관례는 `python3`를 먼저 시도하고 없을 때 `python`으로 내려가는 것이다(네 파일이 같은 모양). 계획은 맨 `python`만 부른다.",
      "evidence": "scripts/_json_valid.sh:6-9 · scripts/_ensure_autoupdate.sh:58-61 · scripts/test_scaffold.sh:47-48 / 계획 495행",
      "why_it_matters": "`python`이 없거나 Windows 스토어 스텁으로 잡히는 환경에서 스크립트가 조용히 실패한다. 실패 시 `rc != 0` 경로로 빠져 로그는 안 고쳐지지만, 사본은 이미 떠 두고 본문 폴더는 `mkdir -p`로 만들어져 **빈 폴더가 남는다** — 그리고 계획 자신의 판정 함수는 빈 폴더를 '안 쪼개짐'으로 보므로 다음 세션에 개편 권유가 다시 뜬다."
    },
    {
      "kind": "drift",
      "where": "Task 4 Step 3 — 신호 문구 '개편은 scripts/split_solved_log.sh 로 쪼갠 뒤 …'",
      "problem": "그 스크립트는 Task 5에서 만든다. Task 4는 자기 커밋(계획 402행)에서 아직 없는 파일을 가리키는 신호를 내보낸다.",
      "evidence": "계획 389행(신호 문구) · 400-402행(Task 4 커밋 목록에 split_solved_log.sh 없음) · 412행(Task 5에서 Create)",
      "why_it_matters": "두 커밋 사이 상태에서 세션이 그 신호를 그대로 따르면 없는 스크립트를 부른다. 태스크를 나눠 병렬로 돌리면 그 창이 더 길어진다."
    },
    {
      "kind": "drift",
      "where": "Task 2 **Interfaces** — 'Consumes: Task 1의 `scaffold_solved_log_is_split`(테스트 픽스처를 만들 때만)'",
      "problem": "Task 2의 픽스처는 폴더를 만들고 파일 하나를 쓸 뿐 그 함수를 부르지 않는다. Task 2는 사실 Task 1에 의존하지 않는다.",
      "evidence": "계획 198행(선언) 대 205-208행(실제 픽스처)",
      "why_it_matters": "의존 선언이 틀리면 태스크를 병렬로 나눌 때 잘못된 직렬화가 걸리고, 반대로 진짜 의존(Task 4→Task 5의 스크립트 이름)은 선언에 없어 순서 판단의 근거가 되지 못한다."
    },
    {
      "kind": "gap",
      "where": "Task 1 Step 6 — `check \"split-rules: 색인 줄 보존\" \"grep -qF -- '→ solved_problems/a.md' '$LOGS3'\"`",
      "problem": "포인터 줄만 확인하고 그 위의 지시사항 줄(`- 무언가를 할 때는 이렇게 한다.`)이 살아남았는지는 안 본다. 앞서 짚은 경계 계산의 손실 모드는 정확히 지시사항 줄만 삼키고 포인터는 남긴다.",
      "evidence": "계획 165행 / scripts/_scaffold_common.sh:144-148",
      "why_it_matters": "이 설계에서 유일하게 상시 로드되는 것이 지시사항 줄인데, 그것이 사라지는 회귀만 이 검사가 통과시킨다."
    }
  ],
  "principles_applied": ["SSOT", "FAIL-LOUD", "TDD", "IDEMPOTENT", "MEASURE-FIRST", "EXPLICIT", "REVERSIBLE", "SIMPLE"],
  "notes": "확인한 것 — 계획이 지목한 줄 번호는 대체로 맞다(`_scaffold_common.sh:18-25` ✓, `:61-87` ✓, `:129` ✓, `:6` ✓, `scaffold.sh:48-60` ✓, `codex-scaffold.sh:37-48` ✓; `:107-118`만 실제로는 107-117). `scaffold_solved_header` 호출부는 레포 전체에 둘뿐이고(`_scaffold_common.sh:95`, `:168`) 테스트가 직접 부르는 곳은 없어 계획 Step 5가 전수를 덮는다. 포인터로 세는 방식도 안전하다: 새 규칙 블록의 `- 각 줄은 solved_problems/ 아래의 …` 에는 화살표가 없어 `grep -c -- '→ solved_problems/'` 에 안 걸린다. 굵은 줄로 항목을 세는 방식도 현행 규칙 불릿에 `**`가 없어 갈린다. `text.split(\"\\n\")`은 U+2028 함정을 제대로 피했다.\n\n더 확인이 필요한 것 — 첫째, Task 5 테스트의 `사본 못 뜨면 안 고친다` 픽스처가 `/nonexistent/path/backups`를 쓰는데 Git Bash에서는 `C:\\Program Files\\Git\\nonexistent\\…`로 풀린다. 관리자 셸에서는 `mkdir -p`가 성공해 검사가 뒤집힐 수 있어 실제 환경에서 한 번 돌려 봐야 한다. 둘째, `scaffold_check_solved_pairing`의 `ls -1 … | wc -l` 는 `set -o pipefail` 아래에서 `ls` 실패가 파이프라인 실패로 올라오는데, 앞선 쪼개짐 판정이 파일 존재를 보장하므로 지금 구조에서는 안전하다 — 다만 판정 가드를 나중에 떼면 그 순간 훅이 죽는다. 셋째, `scripts/test_hooks.sh`와 `hooks/`는 이 렌즈에서 안 열었다. 넷째, `disciplined-coder:show-solved` 스킬이 아직 세션 스킬 목록에 뜨는데 레포에는 없다 — 설치본 캐시인지 배포 잔재인지는 이 범위 밖이라 확인하지 않았다."
}
```
