# spec 리뷰 둘째 회차 — 2026-09-05-audit-roots-design

검토 대상은 `docs/superpowers/specs/2026-09-05-audit-roots-design.md`(커밋 522ea4e, 첫 리뷰 스물하나를 반영한 판)다. 렌즈 셋을 호출 둘로 돌렸다. lens-grounding과 lens-consistency는 한 호출, lens-adversarial은 따로다. 렌즈를 한 번씩만 돌렸다. 원본은 같은 이름 폴더의 `lens-grounding-1.json`(16건), `lens-consistency-1.json`(6건), `lens-adversarial-1.json`(12건)이다. 발견 34건을 합치니 같은 자리를 짚은 것이 있어 스물넷이 된다. 첫 회차 스물하나는 렌즈 셋이 모두 반영됐다고 확인했고, 이번 발견은 반영이 불완전한 것과 반영이 새로 만든 어긋남만이다.

## 선행연구 렌즈

spec으로 판정했다(경로가 `docs/superpowers/specs`). 제안하지 않았다. 첫 회차와 같은 이유로 발동 기준에 걸리지 않는다.

## 합친 발견

둘 이상의 렌즈가 함께 잡은 것은 앞에 렌즈 이름을 둘 이상 적었다. 근거로 든 문장은 전부 파일을 열어 확인했다. 확인한 것은 test_docs_drift.sh·test_audit.sh·test_scaffold.sh의 앵커 문장들, `_ensure_autoupdate.sh`의 종료 코드, `KO_NUM`의 범위, lens-readability의 두 번 돌리기 문장, meta-aggregate의 기존 예외, domain-docs 표의 행 이름, `audit_evidence.sh`의 지문 계산, project-doc-audit의 derived 언급 셋, CI의 ubuntu-latest, 봉인된 diff.json과 run.json의 최상위 칸, 렌즈 원본 35개 전부의 `target` 칸이다.

- **adversarial·grounding — 1단계 단언 목록이 손 열거라 빠진 것이 있다.** test_docs_drift.sh가 domain-docs에서 '렌즈는 서브에이전트를 새로 열지 않는다'·'대화 턴을'·'3층 오케스트레이션은 이 금지의 예외다'·'렌즈는 한 번씩만 띄운다'·'여기서 다시 정하지 않는다'·'렌즈끼리 볼 것을 나눠 주지 않는다'·'-review-2.md'를 찾고, test_audit.sh가 '렌즈는 판단만 한다'·'새 프로젝트나 새 모델이나 새 의존이 필요하면 제안하지 않는다'·'판단이라는 사실을 산출물에 적는다'를 찾는다. 모두 옮기거나 다시 쓰는 문단 안이다.
- **adversarial·grounding — 2단계 단언 목록에 넷이 없다.** test_audit.sh의 domain-spec-review lens-adversarial 예외 문장 전체, 렌즈 넷의 '앞으로 벌어질 일을 적지 않는다', project-doc-audit의 '저장소 전체를 입력으로 따로 한 번 띄운다', test_docs_drift.sh의 domain-llm-runtime '여기서 다시 정하지 않는다'·'렌즈는 한 번씩만 부른다'.
- **grounding — `KO_NUM`이 '열'까지만 알아 '열하나'가 0이 된다.** 2단계 단언이 그대로는 통과할 수 없다.
- **grounding — test_audit.sh에는 고칠 '집합 문장'이 없다.** 집합은 project-doc-audit 「판정」 문장에서 도출한다.
- **adversarial — derived가 project-doc-audit 「회차 대조」 둘째 문단과 「통합 기록」 findings.json 항과 요약문 항목에 남는다.** 3단계 단언은 「판정」 문장 하나만 겨눈다.
- **adversarial — 앞선 diff.json에서 온 재발 항목의 `prior_round`가 직전 회차 이름으로 잘못 붙는다.**
- **adversarial — 자동 기각 확인이 거짓일 때의 status가 없다.** 세션이 형식 확인과 재판정 가운데 조용히 고른다.
- **adversarial·grounding — diff.json 계약의 `auto_rejected` 최상위 필수 칸이 봉인된 이 회차 diff.json에 없다.** 검수를 통과시킨다는 성공 기준과 기록을 고치지 않는다는 비목표가 같이 성립하지 않는다. 계약에 없는 `note` 칸도 있다.
- **consistency — `verdict_counts`의 자리가 metrics 출력 안과 run.json 최상위 둘로 적혀 있고, `auto_rejected` 개수의 출처가 없다.**
- **grounding·consistency — 잔존·해소의 정의가 둘이다.** 3절은 지문의 이번 회차 출현으로, 목표 절과 스크립트(`alive`)는 인용 문장의 파일 실재로 잰다. derived를 없애는 근거 '지문이 없어'도 틀리다. `audit_evidence.sh`는 빈 인용에도 지문을 붙이고, 늘 해소로 찍히는 이유는 `alive`가 인용 실재를 요구하기 때문이다.
- **grounding — 5절의 자동 갱신 통로가 존재하지 않는다.** `_ensure_autoupdate.sh`는 모든 실패 갈래에서 stderr에 WARNING을 찍고 0으로 끝난다. 함수를 그대로 두면 scaffold.sh가 받을 실패 종료 코드가 없다.
- **grounding — test_scaffold.sh의 자동 갱신 stderr 단언 넷(ERR_D·ERR_E)이 5단계 목록에 없다.** 사유를 stdout으로 옮기면 넷이 깨진다.
- **grounding·adversarial — `PYTHONUTF8` 안내 줄이 test_scaffold.sh의 '2nd run sends nothing'·'CRLF: sends nothing' 단언과 맞선다.** 5단계 단언은 CI(ubuntu-latest)에서는 줄이 안 나 실패하고 변수를 넣은 윈도우 PC에서도 실패한다. OS 판정과 변수를 픽스처로 고정하는 방법이 없다.
- **adversarial — `PYTHONUTF8`이 비어 있는지를 읽는 저장소가 없다.** scaffold.sh는 프로세스 환경만 보고 `SetEnvironmentVariable('User')`는 레지스트리만 바꾸므로 호스트를 다시 열기 전까지 안내와 물음이 되풀이된다.
- **adversarial — 안내 줄이 변수가 비어 있는 한 매 세션 뜬다.** scaffold.sh의 다른 넛지 둘은 조건이 한 세션에 묶여 있다.
- **consistency·adversarial — '마지막 둘은 앞 셋과 파일이 겹치지 않아'가 거짓이다.** README는 1·4·5단계에, lens-readability는 2·4단계에 걸린다.
- **consistency·adversarial — 성공 기준 둘째의 줄 수가 한 줄 차이로 거짓이다.** 「문서 검진 방법」 첫 문단은 어느 렌즈를 거는지와 어떻게 띄우는지가 한 줄에 있어 옮기는 줄은 23이고 98−23=75라 '75 아래'가 아니며, 1절이 domain-docs에 더하는 문장들은 어느 수치에도 없다.
- **grounding — 1절의 포인터 재지정 여섯에 셋이 빠졌다.** domain-spec-review의 domain-docs 참조(「한 번만 띄우는 렌즈의 규율」·「렌즈에게 정본을 알리는 법」·'회차 수는 domain-docs에'), domain-docs 자신의 '아래 「…」' 포인터 둘, domain-llm-runtime 렌즈 선택 절의 「판단 앞에 기계를 세운다」.
- **grounding — lens-readability 예외는 '모은 것'이 아니라 뒤집은 것이다.** 그 파일은 두 번 돌리는 쪽을 먼저 고려하라고 적고 있다.
- **grounding — lens-prior-art를 계약 예외에 올리면 test_docs_drift.sh의 '예외 렌즈에 consequence가 없다' 단언이 깨진다.** lens-prior-art는 consequence를 담는다.
- **grounding — meta-aggregate 예외에 lens-readability는 이미 있어 더하는 것은 lens-prior-art 하나다.**
- **consistency — lens-consistency 짝 묶음 규칙이 dispatching-lenses·lens-consistency·project-doc-audit 셋에 놓이고 소유자는 넷째 이름이다.**
- **consistency — 4단계 단언 둘(README 훅 목록, CLAUDE.md '새로')이 놓일 테스트 파일이 없다.**
- **adversarial — audit_statements.sh 출력의 `file` 칸 출처가 없다.** `statements` 항목 계약에 문서 경로가 없고, 이 회차 원본의 `target` 칸은 세션이 더한 계약 밖 칸이다.
- **grounding — '규범·인덕스'는 표의 행 이름 '규범·인덱스'와 다르다.**
- **consistency — 「순서와 되돌리기」 단계 다섯에 전제가 요구하는 rebase 걸음이 없다.**

## 집계

상충은 없다. 세 렌즈가 같은 항목에서 반대 방향을 낸 곳이 없다.

커버리지 공백은 첫 회차와 같다. lens-fit은 spec 리뷰 묶음이 아니라 돌지 않았고 lens-prior-art는 제안하지 않았다. 렌즈 셋이 루트 밖(메모리, 다른 세션의 미커밋 변경)은 열지 않았다.

adversarial이 발견으로 올리지 않고 notes에 남긴 것 셋을 호출자가 판단했다. `KO_NUM` 범위는 grounding이 발견으로 올려 위에 있다. 병합 순서 대기의 시점('끝내')은 spec 위험 첫째 항이 구현 세션 시작 시점으로 읽히게 두면 된다. test_docs_drift.sh의 개수 훑기(`COUNT_SCAN`)에 새 스킬 dispatching-lenses가 들지 않는 것은 1단계 단언에 더할 것이다. adversarial이 관찰한 '이 워크트리의 기록이 rw로 보인다'는 새 워크트리에서 seal_reviews.sh가 돌지 않은 것이고 spec과 무관하다.

grounding이 더 확인할 것으로 남긴 '문서별 호출의 `statements`가 어느 원본 파일에 실리는가'는 위 `file` 칸 발견과 같은 자리라 거기서 함께 푼다.
