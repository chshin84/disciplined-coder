---
description: PC 전역(~/.claude/disciplined-coder/)을 셋업한다. 디시플린 정본(agent-principles.md)을 복사해 최신으로 갱신하고, ~/.claude/CLAUDE.md의 @import 블록을 다시 만든다. 여러 번 실행해도 결과가 같다(멱등).
---

다음 스크립트를 실행해 PC 전역 디시플린 환경(~/.claude/disciplined-coder/)을 셋업하라 — 디시플린
정본을 최신으로 갈아 두고 @import 배선을 다시 만드는 일이다:

`bash "${CLAUDE_PLUGIN_ROOT}/scripts/scaffold.sh"`

인자는 없다. 인자가 붙어 오면 무시하고 그 사실을 한 줄로 알려라 — 이 커맨드는 홈 디렉터리에 쓰므로
짐작해서 다르게 동작하지 않는다.

실행 후 스크립트가 낸 출력을 그대로 전하라 — 무엇이 셋업됐는지 스스로 짐작해 적지 않는다. 스크립트가
실패하면 그 내용을 삼키지 말고 무엇이 실패했는지 함께 보고하라.
