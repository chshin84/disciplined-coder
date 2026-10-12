# nested-orchestration 하부 명세 대조 개정 선행연구 대조 기록(2026-10-12)

현재 세션은 「2026-10-12 개정 — 하부 명세 대조」 절이 해 본 적 없는 방식을 시도한다고 보고 `lens-prior-art`를 제안했다. 사용자가 통상(서브에이전트 하나)으로 승인했다. 대상은 spec 이다(경로가 `docs/superpowers/specs` 아래). 원본은 같은 이름의 폴더에 있고 `search_status`는 `ok`다.

## 발견

| 발견 | 유형 | 출처 |
|---|---|---|
| 「겹침 처리」 표에 '중복을 그대로 둔다' 처분이 없다. shared kernel 지침은 공유를 예외로 두고 같은 개념의 다른 관점은 분리하라고 하며, rule of three 는 사본 둘이 추출을 요구하지 않고 조기 추출이 잘못된 추상화를 고를 위험이 있다고 적는다 | known-failure | threedots.tech 「Shared Kernel」(blog), Wikipedia 「Rule of three」 |
| LLM 단독 불일치 검출은 형식 논리나 군집화를 결합한 방식보다 재현율이 낮게 보고되었다. 결합 방식도 모순의 60%를 검출했다. 이 설계는 겹침 검출을 렌즈 한 번에 맡긴다 | known-failure | ALICE(Automated Software Engineering 2024, 초록), RE 2025 RE@Next!(초록) |

## 인용 검증

현재 세션이 두 발견의 인용을 열어 확인했다. threedots.tech 는 "A shared kernel should be the exception, not the rule.", "Changes to it require agreement from all teams involved."를 적는다. Wikipedia 는 "two instances of similar code do not require refactoring"과 "Attempting premature refactoring risks selecting a wrong abstraction"을 적는다. TU Berlin 저장소의 ALICE 초록은 "ALICE's performance markedly surpasses that of an LLM-only approach by detecting 60% of all contradictions."를 적는다. RE 2025 초록은 렌즈가 수치 없이 옮겼고 현재 세션은 다시 열지 않았다. ALICE 원문의 LLM 단독 수치는 렌즈와 현재 세션 모두 확인하지 못했다.

## 결론에 영향을 주는 미확인 항목

렌즈는 하부 설계를 병렬로 쓰고 멈춘 뒤 조율자가 모아 겹침을 대조하는 LLM 다중 에이전트 사례를 찾지 못했다. 사용 쪽이 '확정 예정' 값을 가정으로 두고 설계한 뒤 대조하는 contract-first 사례도 찾지 못했다. 찾은 사례는 모두 계약을 먼저 고정하고 stub 으로 병렬화했다.
