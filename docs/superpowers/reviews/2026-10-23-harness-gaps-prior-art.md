# 범용 하네스 대비 빈틈 — 선행연구 기록

## 발동과 승인

사용자가 2026-10-23 에 선행연구 에이전트로 dc코더가 범용 하네스로서 부족한 점을 찾으라고 직접 요청했다. 직접 요청이므로 그 요청이 실행 제안의 승인이다. 오케스트레이터는 아래 프로토콜을 보였고, 사용자는 같은 날 "이대로 승인"을 골랐다.

## 프로토콜

- 연구 질문: 범용 코딩 에이전트 하네스의 선행 사례와 비교할 때 dc코더 설계 결정의 빈틈과 개선 지점은 무엇인가.
- 상황: 결정 근거 탐색(표에 꼭 맞는 상황이 없어 결정이 기대는 주제마다 하위 질문을 두는 이 상황을 골랐다).
- 모드: survey.
- 대조 대상: dc코더의 현재 설계 결정. 행동·문체 조항을 매 세션 상시로 싣는다. 강제는 넛지 훅 위주이고 차단 훅은 리뷰 기록 봉인 등 일부에만 둔다. 평가는 조항 단위 소거 시험(질문 3개 이상, 1회 실행)이며 묶음 비교는 기각했다. 검증은 같은 모델 렌즈 서브에이전트가 맡고, Stop 게이트는 spec·plan 과 문서 검진을 본다. 맥락은 메모리·HANDOFF 로 관리한다. 선행연구는 웹을 읽는 연구자·검증자가 맡는다. 사용자 결정은 한 건씩 선택 도구로 묻는다.

| ID | 범위 | 포함 | 제외 |
|---|---|---|---|
| sq1 | 상시 지시의 분량과 강제 방식 | 지시 수에 따른 준수율 저하, 프롬프트 규칙과 결정적 런타임 강제의 비교 | 모델 학습 단계의 정렬 기법 |
| sq2 | 규칙·하네스의 평가 방법 | 소거 시험, 작은 표본의 통계적 판정, 작업 성공률 벤치마크 | 모델 자체의 능력 순위표 |
| sq3 | 다중 에이전트 검증과 완료 게이트 | LLM 심판의 상관 오류, 자기 선호, 린트·테스트 루프 | 사람 코드 리뷰만 다룬 연구 |
| sq4 | 장기 작업의 맥락 관리 | 압축, 진행 파일, 세션 간 상태 인계 | RAG 검색 품질 일반 |
| sq5 | 코딩 에이전트의 보안 | 웹 콘텐츠 프롬프트 인젝션, 비밀 유출 방지 | 모델 탈옥 일반 |
| sq6 | 비용과 사람 개입 마찰 | 다중 에이전트 토큰 비용, 승인 피로, 질문 빈도 | 클라우드 요금 일반 |
| sq7 | 이식성과 운영 관측 | 도구 공통 지시 파일 규약, 에이전트 추적·텔레메트리 | 일반 APM |

- 질의 금지 목록: 플러그인 이름(2개), 사용자 계정(1개), 소속 회사명(2개), 저장소 경로와 파일 이름, 조항 ID. 식별 낱말은 범주와 개수만 적었다(2026-10-25 사용자 결정, 커밋 전 2026-11-13 수정).
- 연구자 수: 7. 통상값 2를 넘는 이유는 하위 질문 7개를 묶지 않고 한 명씩 배정했기 때문이다.
- principles_path: D:/projects/disciplined-coder/agent-principles.md

## 실행 결과

탐색은 1회 실행했다. 에이전트 105개가 토큰 약 573만 개를 썼고, 검증에 보낸 URL 은 54개다. 질의 경계 위반은 없다. 원본은 같은 이름의 폴더(`search-r1.json`·`researcher-sq*-r1.json`·`verifier-r1.json`·`synthesis-r1.json`·`map-check-r1.json`)에 있다.

`overall_status` 는 `not-ok` 다. 하위 질문 7개 모두 `search_status` 는 `ok`, `verification_status` 는 `partial` 이다. 그래서 통과 항목은 판정 근거로 쓰지 않고 보고에만 적는다. partial 의 주된 사유는 재판정에도 정보 부족이 남은 주장 실패다. 연구자가 한 주장에 수치·메커니즘·평가 방법을 함께 적었고, 검증자가 연 초록 페이지에는 그중 일부만 있었다.

| 하위 질문 | 찾은 사례 | 통과 | saturation |
|---|---|---|---|
| sq1 | 18 | 9 | 4 |
| sq2 | 16 | 9 | 3 |
| sq3 | 17 | 4 | 3 |
| sq4 | 18 | 10 | 2 |
| sq5 | 15 | 7 | 2 |
| sq6 | 17 | 7 | 3 |
| sq7 | 11 | 3 | 3 |

탈락·판정 불가·검증 실패 목록은 `search-r1.json` 의 `rejected`(27건)·`unverifiable`(0건)·`verify_failed`(URL 25개)에 사유와 함께 있다.

## 공백 라운드

실행하지 않았다. 오케스트레이터가 partial 의 원인이 탐색 부족보다 복합 주장과 초록 페이지의 불일치라고 보고하고 실행하지 않는 안을 권했으며, 사용자가 2026-10-23 그 안을 골랐다.

## 인용 확인

결정 근거 탐색이므로 보고의 결론 문장에 쓰는 인용만 오케스트레이터가 직접 열었다. 아래 인용의 구절이 원문에 있음을 확인했다.

- arXiv 2607.19257: "Perfect-response rate collapses to zero by N=80 for every model, format, and placement."(N 10~160, 모델 5종)
- arXiv 2602.11988: "providing context files does not generally improve task success rates", "increasing inference cost by over 20% on average"
- arXiv 2605.10039: "None of the four structural variables or three two-way interactions produces a detectable contrast"(Claude Code 세션 1,650회)
- code.claude.com/docs/en/memory: "target under 200 lines per CLAUDE.md file. Longer files consume more context and reduce adherence." 와 imports 가 맥락 비용을 줄이지 않는다는 문장, CLAUDE.md 는 강제 설정이 아닌 맥락이며 차단은 PreToolUse 훅을 쓰라는 문장
- claude.com/blog/auto-mode-default-in-claude-code: 승인 97%, 사람 검토 13.6%, auto mode 89%, 계획 거절 39%
- code.claude.com/docs/en/sandboxing: "On native Windows, Claude Code runs commands unsandboxed."

나머지 통과 항목은 검증자 판정을 그대로 두었다.

## 결론에 영향을 주는 한계

- 오케스트레이터가 프로토콜의 대조 대상에 적은 서술 일부가 사실과 다르다. 같은 날 실행한 적대 렌즈가 차단 훅이 네 개 있다는 점, 웹을 읽는 에이전트의 권한이 이미 최소라는 점, `domain-discipline.md` 「훅 검토(2026-10-18)」가 삭제·외부 전송 확인을 권한 설정의 ask 규칙으로 다루기로 했다는 점을 지적했다. 종합 결론 5·6 은 이 틀린 서술에 기대므로 그대로 쓰지 않는다.
- 연구자 `not_found`: 한국어 문체 규칙 상시 적재의 준수율 연구, 넛지 훅과 차단 훅의 직접 비교, 종료 게이트의 테스트 강제 효과, 질문을 한 건씩 묻는 방식과 묶는 방식의 비교는 찾지 못했다.
