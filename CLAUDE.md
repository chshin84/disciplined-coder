# disciplined-coder

이 레포는 disciplined-coder 플러그인 자체다. 에이전트원칙은 `agent-principles.md`이고, 상세는 `skills/` 아래 각 스킬이 소유한다. 무엇이 있는지는 그 디렉터리를 보면 되므로 여기 열거하지 않는다.

설계 문서는 `docs/superpowers/specs/`에, 계획 문서는 `docs/superpowers/plans/`에 쓴다. 그 두 폴더에 `.md`를 새로 쓰면 Stop 리뷰 게이트가 발동한다.

spec과 plan을 새로 쓰면 Stop 게이트가 리뷰를 요구하고, 그 밖의 문서를 고치면 검진 넛지가 뜬다. 리뷰 기록과 프로젝트 밖 문서에는 문서 넛지가 뜨지 않는다. 세션의 첫 도구 호출에 한 번 뜨는 규칙 넛지는 `Bash` 도 잡고 대상 경로를 보지 않으므로 그 예외가 적용되지 않는다. 세션이 시작될 때 커밋된 감사 기록이 읽기 전용으로 봉인되고, 읽기 전용 파일에 Write나 Edit을 적용하면 훅이 사유와 함께 거부한다. 기록을 고치려다 거부당하면 훅 고장이 아니라 봉인이다. 적용된 훅의 전체 목록과 연결은 `README.md`의 「하드 게이트와 넛지와 전역 설정 수정」 절이 소유한다.

## 문서 타입마다 무엇이 강제하나

에이전트원칙의 「문서를 쓰고 관리할 때」가 타입과 수명을 정하고, 그것을 이 저장소에서 무엇이 강제하는지는 여기가 적는다. 에이전트원칙은 여러 프로젝트에 실리므로 이 경로들을 포함할 수 없다.

| 타입 | 강제하는 장치 |
|---|---|
| **상태** (roadmap) | 없다. 무엇과 맞댈지는 그 프로젝트의 코드와 인프라가 정한다 |
| **절차·계약** | 문서와 코드를 맞대는 테스트 `scripts/test_docs_drift.sh` |
| **설계** (spec·plan) | 대체된 문서의 superseded 표시를 검사한다 `scripts/test_docs_drift.sh` |
| **기록** (reviews) | 있는 기록의 수정을 거부하는 훅 `hooks/readonly_pretooluse.sh` 와 지운 기록을 잡는 검사 `scripts/test_docs_drift.sh` |
| **핸드오프** | 세션 시작에 잔존을 세어 알린다 `scripts/scaffold.sh` |
| **맥락** (Claude 메모리) | 없다. 메모리가 git 밖이라 검사가 닿지 않는다 |
| **규범·인덱스** | 없다. 포인터만 두므로 낡을 상태가 없다 |

## 변경 뒤 실행

고친 것이 있으면 아래를 돌리고, 그다음 `claude plugin validate ./`를 실행한다. 각 스크립트의 계약은 **FAIL=0**이며 기대 개수를 숫자로 박지 않는다(에이전트원칙의 `SSOT`).

`d=$(mktemp -d); for t in scripts/test_*.sh; do ( bash "$t" > "$d/$(basename "$t").log" 2>&1 || echo "$t" >> "$d/bad" ) & done; wait; if [ -s "$d/bad" ]; then echo "FAILED:"; while read -r t; do echo "--- $t"; grep 'FAIL:' "$d/$(basename "$t").log"; done < "$d/bad"; else echo "ALL PASS"; fi`

실패한 이름을 모아 마지막에 알리는 형태인 이유는, 그냥 이어 돌리면 마지막 하나의 결과만 남아 앞의 실패가 묻히기 때문이다. 다섯 벌을 동시에 띄우는 이유는 이 PC에서 차례로 돌리면 334초, 동시에 돌리면 219초이기 때문이다(에이전트원칙의 `ASYNC-FIRST`). 시간을 쓰는 것은 계산이 아니고 프로그램 하나 띄우는 데 드는 64밀리초이며, 실시간 감시가 그 비용을 만든다. `claude plugin validate ./`는 `version` 경고 하나만 내면 정상이다.
