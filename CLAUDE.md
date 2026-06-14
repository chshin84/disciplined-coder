# disciplined-coder (개발 노트)

이 레포는 disciplined-coder 플러그인 자체다. 플러그인을 **자기 자신에게 적용(도그푸딩)**한다 —
아래 관리 영역이 `coding-principles.md`(SSOT)와 이슈 로그를 @import 하므로, 이 레포에서 작업하는
모든 에이전트가 동일한 디시플린을 따른다.

- 디시플린 정본: `coding-principles.md` (SSOT). 직접 원칙을 추가할 땐 여기만 고친다.
- scaffold 검증: `bash scripts/test_scaffold.sh` (PASS=22 기대).
- 변경 후: 위 테스트 + `claude plugin validate ./ --strict`.
- 설계/계획 문서: `docs/superpowers/`.

> 아래 "BEGIN/END disciplined-coder" 관리 영역은 SessionStart hook이 자동 생성·갱신한다.
> **직접 편집 금지.** 프로젝트 콘텐츠는 항상 이 관리 영역 **위**에 둘 것.

# BEGIN disciplined-coder (managed — do not edit)
@coding-principles.md
@advisors-index.md
@solved_problems.md
# END disciplined-coder (managed — do not edit)
