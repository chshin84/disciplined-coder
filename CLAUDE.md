# disciplined-coder (개발 노트)

이 레포는 disciplined-coder 플러그인 자체다. 디시플린은 **PC-레벨**로 적용된다
(설치 후 SessionStart hook이 `~/.claude/disciplined-coder/` + `~/.claude/CLAUDE.md`를 셋업).
따라서 이 레포 루트엔 프로젝트-레벨 사본을 두지 않는다(agent-principles.md·domains-index.md는 플러그인 SSOT 원본).

- 디시플린 정본: `agent-principles.md` (SSOT, ID 글로서리·무순서). 도메인 목차: `domains-index.md`.
- scaffold 검증: `bash scripts/test_scaffold.sh` (계약 **FAIL=0**. 매직 넘버 금지 — `SSOT`).
- 변경 후: 위 테스트 + `bash scripts/test_hooks.sh` (계약 **FAIL=0**) + `claude plugin validate ./` (non-strict).
- 설계/계획: `docs/superpowers/`.
