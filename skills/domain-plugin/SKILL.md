---
name: domain-plugin
description: Claude Code 플러그인·마켓플레이스 제작 시 참고서. 설계/개발 시 참조.
---
# 플러그인 관리 도메인 참고서

## 범위
Claude Code 플러그인/마켓플레이스를 만들고 배포하는 방법.

## 항목 (계속 보강)
- **버전 핀 주의** — 활성 개발 중이면 plugin.json `version`을 **빼서** 커밋 SHA 기반 자동 업데이트. 고정하면 안 올리는 한 사용자 업데이트 안 나감.
- **marketplace.json** — `.claude-plugin/marketplace.json`(최상위 `name`/`description`/`owner`/`plugins[]`). 루트 플러그인은 `source: "./"`.
- **validate** — `claude plugin validate ./`(non-strict). 도그푸딩으로 루트 CLAUDE.md가 있으면 `--strict`는 의도적 실패.
- **컴포넌트 위치** — `agents/` `skills/` `commands/` `hooks/hooks.json`. 플러그인 CLAUDE.md는 컨텍스트 미로드.

## TODO
- 배포 채널/버전 정책, 팀 PR 워크플로 등.
