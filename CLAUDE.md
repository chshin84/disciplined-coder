# disciplined-coder (개발 노트)

이 레포는 disciplined-coder 플러그인 자체다. 디시플린은 **PC-레벨**로 적용된다
(설치 후 SessionStart hook이 `~/.claude/disciplined-coder/` + `~/.claude/CLAUDE.md`를 셋업).
따라서 이 레포 루트엔 프로젝트-레벨 사본을 두지 않는다(agent-principles.md·domains-index.md는 플러그인 SSOT 원본).

- 디시플린 정본: `agent-principles.md` (SSOT, ID 글로서리·무순서). 도메인 목차: `domains-index.md`.
- 변경 후에는 `scripts/test_*.sh`를 **전부** 돌린다(각 계약 **FAIL=0**. 매직 넘버 금지 — `SSOT`). 목록을 여기 적지 않는 이유는 그 디렉터리가 정본이기 때문이다: `for t in scripts/test_*.sh; do bash "$t"; done`. 그다음 `claude plugin validate ./`를 non-strict로 돌린다.
- 설계/계획: `docs/superpowers/`.

## 오답노트 (solved_problems)
디버깅·이슈 처리·중요한 결정을 시작하기 전에 `docs/solved_problems.md`를 **먼저 확인**한다 —
이 프로젝트에서 겪은 문제와 그 해결법을 모아 둔 기록이다. 문제를 완결하면 **메인 세션이** 거기에
append한다(서브에이전트는 직접 쓰지 말고 리턴으로 보고). **항목을 적는 형식은 그 파일의 머리말이
SSOT다 — 적기 전에 머리말을 읽는다.** 여기에 형식을 다시 베껴 적지 않는 이유는, 형식이 바뀌면 그 사본만
조용히 낡은 채 남아 옛 형식을 지시하게 되기 때문이다.
