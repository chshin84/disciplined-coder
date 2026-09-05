# disciplined-coder

이 레포는 disciplined-coder 플러그인 자체다. 정본은 `agent-principles.md`이고, 상세는 `skills/` 아래 각 스킬이 소유한다. 무엇이 있는지는 그 디렉터리를 보면 되므로 여기 열거하지 않는다.

설계 문서는 `docs/superpowers/specs/`에, 계획 문서는 `docs/superpowers/plans/`에 쓴다. 그 두 폴더에 `.md`를 새로 쓰면 Stop 리뷰 게이트가 발동한다.

이 레포에는 훅 넷이 걸린다. spec과 plan을 쓰면 Stop 게이트가 리뷰를 요구하고, 그 밖의 문서를 고치면 검진 넛지가 뜬다. 세션이 시작될 때 `scripts/seal_reviews.sh`가 `docs/superpowers/reviews/` 아래 기록을 읽기 전용으로 봉인하고, 읽기 전용 파일에 Write나 Edit을 걸면 훅이 사유와 함께 거부한다. 기록을 고치려다 거부당하면 훅 고장이 아니라 봉인이다.

## 변경 뒤 실행

고친 것이 있으면 아래를 돌리고, 그다음 `claude plugin validate ./`를 실행한다. 각 스크립트의 계약은 **FAIL=0**이며 기대 개수를 숫자로 박지 않는다(`SSOT`).

`bad=""; for t in scripts/test_*.sh; do bash "$t" || bad="$bad $t"; done; [ -z "$bad" ] && echo "ALL PASS" || echo "FAILED:$bad"`

실패한 이름을 모아 마지막에 알리는 형태인 이유는, 그냥 이어 돌리면 마지막 하나의 결과만 남아 앞의 실패가 묻히기 때문이다. `claude plugin validate ./`는 `version` 경고 하나만 내면 정상이다.
