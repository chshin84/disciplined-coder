# README 작성 선행연구 — 2026-10-21

## 프로토콜

- **연구 질문**: 사용자용 README 를 어떤 구성과 순서로 써야 독자가 도구를 빨리 판단하고 채택하는가.
- **상황**: 결정 근거 탐색(사용자 직접 요청 "리드미 작성에 대해 선행연구좀"). 모드는 `survey`.
- **대조 대상**: `skills/domain-readme/SKILL.md` 의 규칙. 독자의 네 질문(내 문제를 푸는가·쓸 수 있는가·누가 만들었는가·더 배우려면 어디로), 사용자 독자와 개발자 독자의 분리, 권장 동선(제목과 한 줄 설명 → 셀링포인트 → 무엇을 왜 → 설치 → 사용 예시 → 주의와 한계 → 더 읽기와 기여), 배지·목차·스크린샷·변경 이력은 필요할 때만.
- **하위 질문**
  - `sq1` — 범위: README 의 내용 범주와 품질이 저장소의 인기·채택·기여에 미치는 영향을 다룬 실증 연구. 포함: 학술 논문, 대규모 저장소 분석. 제외: 개인 의견 블로그.
  - `sq2` — 범위: README 의 절 구성·순서·배지·목차에 관한 공개 가이드와 표준. 포함: 문서화 프레임워크, 주요 오픈소스 재단·플랫폼의 지침. 제외: 특정 언어 패키지 템플릿만 다루는 자료.
- **질의 금지 목록**: `disciplined-coder`, `domain-readme`, `chshin84`, `키움`
- **탐색 모드 연구자 수**: 2 (통상값, 하위 질문마다 1명)
- **principles_path**: `C:/Users/CHSHIN/.claude/disciplined-coder/agent-principles.md`

## 승인

사용자가 2026-10-21 에 위 프로토콜을 "이대로 실행"으로 승인했다. 직접 요청이므로 그 요청이 실행 제안의 승인이다.

## 실행 경로

Workflow 도구가 이름 `disciplined-coder:prior-art-search` 를 찾지 못했다(오류 문구: `Workflow "disciplined-coder:prior-art-search" not found. Available: deep-research`). 설치된 플러그인 캐시(`2fa22d352a0b`)에는 `workflows/prior-art-search.js` 가 있으나 런타임에 등록되지 않았다. 캐시 경로를 `scriptPath` 로 넘기자 작업 디렉터리 밖이라는 이유로 거부되었다. 그래서 같은 스크립트를 세션 스크래치패드에 그대로 복사해 `scriptPath` 로 실행했다(run `wf_34a6f665-d63`). 스크립트 내용은 바꾸지 않았으므로 질의 경계 검사와 통과 목록 분리는 워크플로가 수행한다.

## 결과 (처분 전)

원본은 `2026-10-21-readme-writing-prior-art/agent-prior-art-r1.json` 이다. `overall_status` 는 `ok` 이고 두 하위 질문 모두 `search_status`·`verification_status` 가 `ok` 다. 질의 경계 위반은 없다. 검증자는 13명이 실행되었고, 사례 23건 중 22건이 통과했다. `sq2#case#7`(Diátaxis)은 결말 '판정 못 함'을 원문이 뒷받침하지 않아 탈락했다.

결론에 쓴 인용 중 Standard Readme 명세(목차는 100줄 미만 README 에서만 선택)와 Prana 등(arXiv 1802.06997, 많은 README 가 목적과 상태 정보를 빠뜨린다)은 오케스트레이터가 원문을 열어 구절을 확인했다.

- **규칙과 일치하는 근거** — 독자 질문으로 내용을 정하는 발상은 GitHub 공식 문서, Google 문서 지침, Open Source Guides 가 공유한다. 설명 → 설치·사용 → 기여·라이선스 순서는 Standard Readme 와 Make a README 와 같다. 긴 내용을 README 밖으로 옮기는 방향도 같다.
- **규칙과 상충하거나 빠진 근거** — 네 질문에 프로젝트 상태(유지 중·폐기 예정)가 없다(Prana 등). Standard Readme 는 100줄 이상 README 에 목차를 요구한다. 품질을 검사하는 배지(빌드·커버리지·의존성)는 품질과 상관이 강하고 정보 배지는 약하다(Trockman 등, npm 한정). 인기 저장소 README 에 이미지가 많다는 상관 보고가 있다(Venigalla·Chimalakonda, Fan 등).
- **근거를 찾지 못한 규칙** — 절 순서가 채택 판단 속도에 주는 효과를 측정한 연구, 사용자·개발자 문서 분리를 규칙으로 둔 사례, '주의와 한계' 절을 권하는 공식 지침.

`not_found`: Art of README 원문 404, Liu 등(2022, Java README 32군집) 원문 403, Trockman 전체 논문 미열람.
