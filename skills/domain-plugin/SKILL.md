---
name: domain-plugin
description: Claude Code 플러그인·마켓플레이스를 만들 때 참조하는 도메인 참고서다. 설계와 개발 단계에서 연다.
---
# 플러그인 관리 도메인 참고서

## 범위
Claude Code 플러그인/마켓플레이스를 만들고 배포하는 방법을 다룬다.

## 플러그인을 만들 때 지킬 것
- **활성 개발 중이면 version을 비운다** — 활성 개발 중이면 plugin.json의 `version`을 **비워** 커밋 SHA 기반 자동 업데이트를 유지한다. version을 설정하면 업데이트가 버전 문자열 비교로 전환되어, 값을 올리지 않는 한 새 커밋이 사용자에게 배포되지 않는다(공식 문서의 명시 권장 — [plugins-reference의 Version management](https://code.claude.com/docs/en/plugins-reference#version-management)). `claude plugin validate`가 version 부재에 경고를 내지만, 그 경고는 외관 문제이고 배포 단절이 실질 피해다 — 경고를 수용한다.
- **marketplace.json** — `.claude-plugin/marketplace.json`에 최상위 `name`·`description`·`owner`·`plugins[]`를 둔다. 레포 루트가 곧 플러그인이면 `source: "./"`로 가리킨다.
- **validate** — `claude plugin validate ./`로 검증한다. `--strict`는 경고까지 실패로 취급하므로, 위 버전 핀 정책으로 version 경고를 수용하는 레포에서는 `--strict`가 실패하는 것이 정상이다(non-strict로 통과를 확인한다).
- **컴포넌트 위치** — `agents/`·`skills/`·`commands/`·`hooks/hooks.json`에 둔다. 플러그인 루트의 CLAUDE.md는 컨텍스트로 로드되지 않는다.
