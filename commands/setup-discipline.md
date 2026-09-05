---
description: PC 전역(~/.claude/disciplined-coder/)을 셋업한다. 디시플린 정본(agent-principles.md)을 복사해 최신으로 갱신하고, ~/.claude/CLAUDE.md의 @import 블록을 다시 만들며, ~/.claude/settings.json과 ~/.claude/plugins/known_marketplaces.json의 이 마켓플레이스 항목에 autoUpdate를 넣고, 프로젝트 CLAUDE.md에 남은 옛 관리블록을 걷어낸다. 윈도우에서는 PYTHONUTF8 환경 변수를 넣을지 묻는다. 여러 번 실행해도 결과가 같다(멱등).
---

다음 스크립트를 실행해 PC 전역 디시플린 환경(~/.claude/disciplined-coder/)을 셋업하라 — 디시플린
정본을 최신으로 갈아 두고 @import 배선을 다시 만드는 일이다:

`bash "${CLAUDE_PLUGIN_ROOT}/scripts/scaffold.sh"`

인자는 없다. 인자가 붙어 오면 무시하고 그 사실을 한 줄로 알려라 — 이 커맨드가 고치는 파일은 정해져
있으므로 짐작해서 다르게 동작하지 않는다. 고치는 파일은 거의 다 홈 디렉터리 아래이고, 하나만 예외다. 현재 작업 폴더의
CLAUDE.md에 옛 관리블록이 남아 있으면 그것도 걷어낸다(사본을 홈의 backups 아래 남긴다).

실행 후 스크립트가 낸 출력을 그대로 전하라 — 무엇이 셋업됐는지 스스로 짐작해 적지 않는다. 스크립트가
실패하면 그 내용을 삼키지 말고 무엇이 실패했는지 함께 보고하라.


스크립트를 돌린 뒤, 이 PC 가 윈도우이고 사용자 환경 변수 `PYTHONUTF8` 이 비어 있으면 넣을지 물어라.
비어 있는지는 프로세스 환경이 아니라 레지스트리로 본다. 프로세스 환경을 읽으면 넣은 뒤에도 계속
비어 있는 것으로 보여 매번 다시 묻게 된다.

`reg query "HKCU\Environment" //v PYTHONUTF8`

이 명령이 실패하면 비어 있는 것이다. 그때만 선택지가 있는 질문으로 묻는다(정본 「Karpathy 지침」의
Think Before Acting). 넣는 쪽을 고르면 다음을 실행하고 결과를 한 줄로 알린다.

`powershell -NoProfile -Command "[Environment]::SetEnvironmentVariable('PYTHONUTF8','1','User')"`

이미 값이 있으면 묻지 않고 건드리지 않는다. 되돌리기는 그 환경 변수를 지우는 것이다. 넣은
값은 이미 열려 있는 창에는 실리지 않고 다음에 여는 창부터 실린다. 그 사실을 함께 알린다.

넣는 이유는 이 PC 의 파이썬 기본 인코딩이 cp949 라 한국어 리터럴이 깨지기 때문이다. 이 저장소의
파이썬 호출은 `scripts/_json_valid.sh` 의 `json_run` 이 프로세스마다 UTF-8 모드를 세워 막지만,
클로드 코드 밖에서 파이썬을 직접 부를 때는 그 보호가 없다.
