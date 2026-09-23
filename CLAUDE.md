# disciplined-coder

이 레포는 disciplined-coder 플러그인 자체다. 에이전트원칙은 `agent-principles.md`이고, 상세는 `skills/` 아래 각 스킬이 소유한다. 무엇이 있는지는 그 디렉터리를 보면 되므로 여기 열거하지 않는다.

설계 문서는 `docs/superpowers/specs/`에, 계획 문서는 `docs/superpowers/plans/`에 쓴다. 그 두 폴더에 `.md`를 새로 쓰면 Stop 리뷰 게이트가 발동한다.

## 에이전트원칙을 고칠 때

에이전트원칙은 모든 프로젝트의 세션에 실리므로 아래를 지킨다.

- **사본** — 플러그인이 `agent-principles.md`의 사본을 PC 전역 폴더(`~/.claude/disciplined-coder/`)에 두고 `@import`로 모든 프로젝트에 싣는다. 사본은 세션마다 이 파일에서 다시 덮어쓰므로 사본을 고치지 않는다. 언제 복사되고 프로젝트 폴더에 무엇이 생기는지는 README를 참고한다.
- **지시와 근거의 분리** — 에이전트원칙에는 행동 지시만 적는다. 조항의 근거와 측정 기록은 `skills/lens-fit/domain-discipline.md`와 `skills/lens-readability/domain-korean.md`에 조항 ID로 적는다.
- **조항 추가와 문구 변경** — 클린룸 소거 시험으로 효과를 확인한다. 조항마다 서로 다른 과제 3개를 CLAUDE.md가 빈 모델과 그 조항만 실은 모델에서 실행하고, 개선이 없으면 과제 2개를 더 실행한다. 5개 모두 조항 없이 지켜지면 넣지 않는다. 지운 조항과 그 근거는 두 참고서의 「삭제한 조항」 절에 있다.

## 훅과 봉인

적용된 훅의 전체 목록과 연결은 `README.md`의 「하드 게이트와 넛지와 전역 설정 수정」 절이 소유한다. 이 저장소에서 일할 때 알아 둘 동작은 아래와 같다.

- **감사 기록 봉인** — 세션이 시작될 때 커밋된 감사 기록이 읽기 전용으로 봉인된다. 기록을 고치려다 Write나 Edit이 거부되면 훅 고장이 아니라 봉인이다.
- **넛지 예외** — 리뷰 기록과 프로젝트 밖 문서에는 문서 넛지가 뜨지 않는다. 세션의 첫 도구 호출에 한 번 뜨는 규칙 넛지는 대상 경로를 보지 않으므로 이 예외가 적용되지 않는다.

## 문서 타입마다 무엇이 강제하나

에이전트원칙의 「문서를 쓰고 관리할 때」가 타입과 수명을 정하고, 그것을 이 저장소에서 무엇이 강제하는지는 여기가 적는다. 에이전트원칙은 여러 프로젝트에 실리므로 이 경로들을 포함할 수 없다.

| 타입 | 강제하는 장치 |
|---|---|
| **상태** (roadmap) | 없다. 무엇과 대조할지는 그 프로젝트의 코드와 인프라가 정한다 |
| **절차·계약** | 문서와 코드를 대조하는 테스트 `scripts/test_docs_drift.sh` |
| **설계** (spec·plan) | 대체된 문서의 superseded 표시를 검사한다 `scripts/test_docs_drift.sh` |
| **기록** (reviews) | 있는 기록의 수정을 거부하는 훅 `hooks/readonly_pretooluse.sh` 와 지운 기록을 잡는 검사 `scripts/test_docs_drift.sh` |
| **핸드오프** | 세션 시작에 잔존을 세어 알린다 `scripts/scaffold.sh` |
| **맥락** (Claude 메모리) | 없다. 메모리가 git 밖이라 검사가 닿지 않는다 |
| **규범·인덱스** | 없다. 포인터만 두므로 낡을 상태가 없다 |

## 변경 뒤 실행

고친 것이 있으면 아래를 실행하고, 그다음 `claude plugin validate ./`를 실행한다. 각 스크립트의 계약은 **FAIL=0**이며 기대 개수를 숫자로 박지 않는다. 개수를 적으면 하나의 사실이 두 곳에 생긴다.

`d=$(mktemp -d); for t in scripts/test_*.sh; do ( bash "$t" > "$d/$(basename "$t").log" 2>&1 || echo "$t" >> "$d/bad" ) & done; wait; if [ -s "$d/bad" ]; then echo "FAILED:"; while read -r t; do echo "--- $t"; grep 'FAIL:' "$d/$(basename "$t").log"; done < "$d/bad"; else echo "ALL PASS"; fi`

검사 스크립트를 동시에 실행하고 실패한 이름을 모아 마지막에 알린다. 차례로 이어 실행하면 마지막 하나의 결과만 남아 앞의 실패가 묻히고, 동시에 실행하면 전체 시간이 줄어든다(실측은 `domain-discipline.md`의 `ASYNC-FIRST` 절). `claude plugin validate ./`는 `version` 경고 하나만 내면 정상이다.
