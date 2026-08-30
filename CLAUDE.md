# disciplined-coder — 작업 시작 전에 열 문서

이 레포는 disciplined-coder 플러그인 자체다. 일을 시작할 때는 정본 `agent-principles.md`와 오답노트 색인
`docs/solved_problems.md`를 먼저 열고, 무엇이든 고친 뒤에는 아래 「변경 뒤 실행」을 그대로 따른다.

디시플린은 **PC-레벨**로 적용된다(설치 후 SessionStart hook이 `~/.claude/disciplined-coder/` +
`~/.claude/CLAUDE.md`를 셋업). 따라서 이 레포 루트엔 프로젝트-레벨 사본을 두지 않는다
(agent-principles.md·domains-index.md는 플러그인 SSOT 원본).

- 디시플린이 무엇인지는 정본 `agent-principles.md`에서 확인한다(SSOT이며, ID로 찾아 쓰는 용어집이라 위아래 순서에 뜻이 없다). 어느 도메인 참고서가 있는지는 `domains-index.md`가 목차다.
- 이 레포 내용의 대부분은 `skills/` 아래 스킬 문서다. 무엇이 있는지는 그 디렉터리를 열어 확인한다 — 여기 열거하면 스킬이 늘 때마다 그 목록이 먼저 낡는다.
- 설계 문서는 `docs/superpowers/specs/`에, 계획 문서는 `docs/superpowers/plans/`에 쓰고 읽는다. 그 두 폴더에 `.md`를 새로 쓰면 Stop 리뷰 게이트가 발동한다 — 다른 하위 폴더에 쓰면 게이트가 안 걸린다.

## 변경 뒤 실행

고친 것이 있으면 `scripts/test_*.sh`를 **전부** 실행하고 그다음 `claude plugin validate ./`를 실행한다.
각 스크립트의 계약은 **FAIL=0**이며, 기대 개수를 숫자로 박지 않는다(`SSOT`).

목록을 여기 적지 않는 이유는 그 디렉터리가 정본이기 때문이다.

`bad=""; for t in scripts/test_*.sh; do bash "$t" || bad="$bad $t"; done; [ -z "$bad" ] && echo "ALL PASS" || echo "FAILED:$bad"`

실패한 스크립트 이름을 모아 마지막에 알리는 형태로 적는 이유는, 그냥 이어 돌리면 **마지막 하나의 결과만
남아 앞의 실패가 묻히기** 때문이다. `claude plugin validate ./`는 non-strict로 실행하고, 오류가 하나도
보고되지 않는 것을 확인한다(`version` 경고 하나는 정상이다).

## 오답노트 (solved_problems)
이 오답노트는 지시사항 색인 파일 하나와 항목마다 하나씩인 본문 파일들로 되어 있다. **일을 시작할 때는 `docs/solved_problems.md`**(지시사항 색인)의
줄을 훑어 지금 하려는 작업에 걸리는 줄이 있는지 보고, 걸리면 그 줄이 가리키는 본문 파일을 연다.
**증상이 이미 났으면** `docs/solved_problems/` 아래 본문 파일에서 그 증상을 찾는다. 어느 쪽을 언제
여는지는 `agent-principles.md`의 recall 절이 정본이다.

**이 로그를 어떻게 운영하는지는 여기서 정하지 않는다.** 누가 쓰는지, 언제 꺼내 쓰는지, 무엇을 어느
계층에 적는지는 `agent-principles.md`의 오답노트 절이 정본이고, 항목을 적는 형식은 그 파일 자신의
머리말이 정본이다 — 적기 전에 머리말을 읽는다. 규칙을 여기 베껴 적지 않는 이유는, 규칙이 바뀌면 그
사본만 조용히 낡은 채 남아 옛 규칙을 지시하게 되기 때문이다.
