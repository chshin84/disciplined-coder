# disciplined-coder — 이 레포에서 작업할 때 먼저 볼 것

이 레포는 disciplined-coder 플러그인 자체다. 디시플린은 **PC-레벨**로 적용된다
(설치 후 SessionStart hook이 `~/.claude/disciplined-coder/` + `~/.claude/CLAUDE.md`를 셋업).
따라서 이 레포 루트엔 프로젝트-레벨 사본을 두지 않는다(agent-principles.md·domains-index.md는 플러그인 SSOT 원본).

- 디시플린이 무엇인지는 정본 `agent-principles.md`에서 본다(SSOT이며, ID로 찾아 쓰는 용어집이라 위아래 순서에 뜻이 없다). 어느 도메인 참고서가 있는지는 `domains-index.md`가 목차다.
- 이 레포 내용의 대부분은 `skills/` 아래 스킬 문서다. 도메인 참고서(`domain-*`), 리뷰어 렌즈(`reviewer-*`), 집계(`meta-aggregate`), 오케스트레이션(`nested-orchestration`)이 거기 있다.
- 변경 후에는 `scripts/test_*.sh`를 **전부** 돌린다(각 계약 **FAIL=0**. 매직 넘버 금지 — `SSOT`).
  목록을 여기 적지 않는 이유는 그 디렉터리가 정본이기 때문이다:
  `bad=""; for t in scripts/test_*.sh; do bash "$t" || bad="$bad $t"; done; [ -z "$bad" ] && echo "ALL PASS" || echo "FAILED:$bad"`
  실패한 스크립트 이름을 모아 마지막에 알리는 형태로 적는 이유는, 그냥 이어 돌리면 **마지막 하나의 결과만 남아 앞의 실패가 묻히기** 때문이다.
  그다음 `claude plugin validate ./`를 non-strict로 돌린다.
- 설계 문서와 계획 문서는 `docs/superpowers/`에 쓰고 읽는다. 그 경로에 새로 쓰면 Stop 리뷰 게이트가 발동한다.

## 오답노트 (solved_problems)
디버깅·이슈 처리·중요한 결정을 시작하기 전에 `docs/solved_problems.md`를 **먼저 확인**한다 —
이 프로젝트에서 겪은 문제와 그 해결법을 모아 둔 기록이다.

**이 로그를 어떻게 운영하는지는 여기서 정하지 않는다.** 누가 쓰는지, 언제 꺼내 쓰는지, 무엇을 어느
계층에 적는지는 `agent-principles.md`의 오답노트 절이 정본이고, 항목을 적는 형식은 그 파일 자신의
머리말이 정본이다 — 적기 전에 머리말을 읽는다. 규칙을 여기 베껴 적지 않는 이유는, 규칙이 바뀌면 그
사본만 조용히 낡은 채 남아 옛 규칙을 지시하게 되기 때문이다.
