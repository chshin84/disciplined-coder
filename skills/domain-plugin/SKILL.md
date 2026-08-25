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

## 사용자 설정 파일을 고칠 때 지킬 것
플러그인이 `~/.claude/settings.json`처럼 사용자가 손으로 관리하는 파일을 고쳐야 할 때가 있다. 이 레포는
마켓플레이스 자동 갱신을 켜느라 그 파일을 만진다(`scripts/_ensure_autoupdate.sh`). 그 자리에서 다섯을
지킨다.

- **대상 좁히기** — 우리 것으로 식별되는 항목만 고친다. 남의 항목은 값이 같아도 손대지 않는다.
- **사용자 결정 존중** — 사용자가 값을 넣어 둔 키는 덮지 않는다. 키가 아예 없을 때만 채운다.
- **사본과 재검증** — 고치기 전에 `.bak`을 남기고, 새로 쓴 파일을 다시 파싱해 유효할 때만 제자리에 놓는다.
- **사유를 가른 통지** — 못 고친 회차는 까닭을 갈라 알린다. 설정을 못 읽은 것, 파이썬이 없는 것,
  쓰기 권한이 없는 것은 사용자가 할 일이 서로 다르다.
- **처리기 하나** — JSON을 다루는 처리기를 여러 개 두지 않는다. 폴백을 하나 더 두면 한 번도 안 도는
  사본이 생기고, 안 돌아 본 코드가 오류가 숨는 자리다(`SIMPLE`).
- **서식 변경 고지** — 값을 채우면 파일 전체가 다시 찍혀 서식이 바뀔 수 있다. 바뀐 경로를 알리고 사본
  위치를 함께 보인다.

