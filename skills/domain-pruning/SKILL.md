---
name: domain-pruning
description: 프로젝트의 테스트·스크립트·코드·문서가 과한지 리뷰할 때, 규모를 줄일 대상을 고를 때 참조하는 도메인 참고서다. 플러그인이 아닌 프로젝트에도 쓴다. 리뷰와 정리 단계에서 연다.
---
# 규모와 과잉 판정 도메인 참고서

에이전트와 함께 만든 프로젝트는 세션마다 테스트·스크립트·문서가 쌓인다. 이 참고서는 무엇이 과한지 가리는 판정 질문과 그 출처를 둔다. 플러그인의 훅과 상시 지시에 대한 기준은 `domain-plugin`이 소유한다.

## 판정 질문

판정 질문은 2026-10-05에 선행연구로 모았고, 출처마다 성격이 달라 수치를 그대로 옮기지 않는다. 근거가 밝혀지지 않은 기준값(테스트를 지우는 경과 일수 등)은 두지 않는다(`EVIDENCE-FIRST`).

- **표현에 깨지는 테스트** — 동작과 계약이 그대로인데 문구만 바꿔도 실패하는 검사는 brittle test(결함 없이 실패하는 테스트)이므로 줄인다. 문서 대조 검사는 조항 ID·절 제목·소유 선언 같은 열쇠로 판정하고 문장을 박지 않는다. 금지어 목록처럼 문자열 자체가 계약인 검사는 예외다([Software Engineering at Google 12장](https://abseil.io/resources/swe-book/html/ch12.html), [Sensitive Equality](https://test-smell-catalog.readthedocs.io/en/latest/Issues%20in%20test%20steps/Issues%20in%20assertions/Sensitive%20Equality.html)).
- **구현을 박는 테스트** — 메시지 문구, 내부 변수 이름, 입력을 읽는 방식처럼 동작이 아닌 구현 세부를 고정하는 검사는 줄인다. 이상적인 테스트는 요구사항이 바뀔 때만 바뀐다(같은 12장).
- **중복과 항진** — 다른 검사가 같은 사실을 보면 하나만 남기고, 무엇을 고쳐도 참인 단언은 지운다. 실제로 지워진 테스트 24,431건의 대부분은 대상이 사라진 테스트와 중복 테스트였다([MSR 2025](https://2025.msrconf.org/details/msr-2025-technical-papers/24/Understanding-Test-Deletion-in-Java-Applications)).
- **실패 이력** — 한 번도 실패하지 않았다는 사실은 실행 빈도를 낮출 근거이고 지울 근거가 아니다. Google 에서 테스트 대상의 91.3%가 실패한 적이 없었다([Memon 외 2017](https://huang.isis.vanderbilt.edu/cs8395-f23/paper/google-testing-icse-seip-17.pdf)). 일회성 재발 방지 검사를 지울지는 이 근거와 별개로 사용자가 정한다.
- **셸 스크립트의 길이** — 100줄을 넘거나 제어 흐름이 단순하지 않은 셸 스크립트는 구조적인 언어로 옮길지 따진다. 업체 규범이며 실증 연구는 아니다([Google Shell Style Guide](https://google.github.io/styleguide/shellguide.html)).
- **에이전트 산출물의 비대** — 에이전트가 쓴 변경은 사람의 변경보다 컸고, 원인은 장황한 구현·범위 확장·과잉 방어 코드·과잉 문서화였다. 리뷰에서 이 네 원인을 하나씩 찾는다([arXiv 2608.12355](https://arxiv.org/pdf/2608.12355)).
- **문서와 기록의 수명** — 결정 기록은 짧게 두고 고치지 않으며 대체되면 표시한다([Microsoft ADR](https://learn.microsoft.com/en-us/azure/well-architected/architect-role/architecture-decision-record)). 쓸모가 끝난 작업 문서는 지우거나 폐기 표시한다([Software Engineering at Google 10장](https://abseil.io/resources/swe-book/html/ch10.html)). 기록은 보존 기간을 정하고, 기간이 지나면 원래 저장소 밖으로 옮긴다([NIST SP 800-92](https://nvlpubs.nist.gov/nistpubs/Legacy/SP/nistspecialpublication800-92.pdf)). 에이전트원칙의 「문서 타입과 수명」이 문서 수명을 정하는 프로젝트에서는, 그 표와 다르게 처분하려면 사용자에게 묻는다.
