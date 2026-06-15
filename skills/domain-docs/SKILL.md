---
name: domain-docs
description: 이 디시플린 시스템 자신의 .md 파일(원칙·도메인 참고서·스킬·CLAUDE.md 관리영역)을 어떻게 쓰는가의 내부 저작 규칙. superpowers가 소유하는 spec·plan은 제외.
---
# domain-docs — 이 시스템의 문서 작성 규칙

## 범위
이 플러그인 자신의 문서를 쓰고 구조화하는 규칙이다. superpowers가 spec·plan(설계 문서의 핵심)을 이미
소유하므로, 여기서는 그 밖의 문서를 다룬다 — 원칙(`agent-principles.md`), 도메인 참고서, 스킬
`SKILL.md`, `CLAUDE.md` 관리영역.

## 규칙
- **ID로 참조, 서수 번호 금지** — 목차나 번호(A/B/C, 1·2·3)는 거짓 우선순위를 암시한다. 안정적 ID와
  무순서(알파벳 용어집)를 쓴다(`NO-PRIORITY` 참조).
- **문서 SSOT** — 같은 사실은 한 문서에만 둔다. 다른 문서는 참조한다(@import·링크). 복제 금지.
- **관리 영역 패턴** — 자동 생성 구간은 BEGIN/END 마커로 감싸 멱등 재생성한다. 사용자 콘텐츠는 그 바깥에 둔다.
- **어디에 둘까** — 항상 필요하면 `CLAUDE.md`/@import, 온디맨드면 skill, 경로 한정이면 rules.
- **enrich** — ID만 던지지 말고 완결된 문장으로 충분히 설명한다(`CLEAR-COMM`).
