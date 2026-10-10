# SUB-ORCHESTRATE·nested-orchestration 모호한 기준 — 선행연구 대조

2026-10-10에 사용자가 "모호하다는 기준들을 선행연구로 점검하라"고 직접 요청해 `lens-prior-art` 를 통상 상한(서브에이전트 둘)으로 실행했다. 대상은 f9752ac 의 `agent-principles.md` 「병렬 오케스트레이션」과 `skills/nested-orchestration/SKILL.md` 이다. spec 리뷰 밖에서 실행했으므로 spec·plan 구분은 하지 않았다.

렌즈 원본 JSON 은 받는 즉시 저장하지 않았다. 아래는 그 세션 대화에 남은 두 원본을 요약한 것이며, 원본 폴더는 없다.

## 실행

- **트리거 기준 호출** — 독립의 정의, 태스크 다섯, 기준 미달 하위 시스템, 계약 경로와 무계약 경로, 요청 트리거. `search_status` 는 `ok` 였다.
- **실행 단계 호출** — 하부 명세 승인, 잠금 파일 소유, BLOCKED 기준, 통합 확인. `search_status` 는 `ok` 였다.

## 발견

- **의존 사슬 분할** (known-failure) — Claude Code 문서(agent teams), Anthropic 다중 에이전트 연구 글, Google 확장 연구(arXiv 2512.08296), Parnas(1972, 2차 해설로 확인)가 의존이 많은 일이나 처리 흐름 순서 분할을 불리하게 보았다. CAID(arXiv 2603.21489)는 스텁 선커밋과 워크트리로 병렬을 얻되 의존이 강한 파일을 한 엔지니어에 묶었다.
- **분할 규모 기준** (weak-baseline) — 태스크 다섯의 근거가 없고, 이득은 병렬 폭에서 나온다(CAID 4→8명 하락, Google 약 45% 포화).
- **스킬 47행 인용** (weak-baseline) — Specification Gap(arXiv 2603.24284)의 단일 에이전트 기준선 89%→56%가 빠졌다.
- **무계약 경로** (known-failure) — Cognition(2025)과 CAID 소개 글의 사례처럼 암묵적 결정이 부딪힌다.
- **BLOCKED 기준** (known-failure) — HiL-Bench(alphaxiv 2604.09408)·ClarifyMT-Bench(arXiv 2512.21120, 2025-12)는 자기 판정이 과소 질문으로 기운다고 보고했고, Ask or Assume(alphaxiv 2603.26233)는 판정 에이전트를 따로 둔 구성의 개선을 보고했다.
- **잠금 파일** (weak-baseline) — npm 문서 「package-locks」와 병렬 워크트리 실무 글의 기준선과 비교되지 않았다.
- **하부 명세 승인** (known-failure) — Specification Gap 의 공유 표현 불일치가 승인 항목 없이 통과할 수 있다.

## 인용 검증

호출자가 인용 URL 16개의 응답(HTTP 200)을 확인했다. Specification Gap·CAID·Google 확장 연구의 수치는 arXiv 초록에서, agent teams 문서의 두 문장은 원문에서 대조했다. 이후 spec 리뷰에서 agent teams 원문은 "단일 세션 또는 서브에이전트"가 agent teams 보다 낫다고 적는다는 점이 드러났다.

## 결론에 영향을 주는 not_found·disclosures

- 기준 미달 하위 시스템 처리, 사용자 요청 트리거, 태스크 수 기준, 하부 명세 승인 항목의 실험 연구는 찾지 못했다.
- 인용 연구는 Parnas 를 빼면 모두 프리프린트이고, HiL-Bench 의 정량 수치는 자동 요약에서 본 값이라 쓰지 않았다.
