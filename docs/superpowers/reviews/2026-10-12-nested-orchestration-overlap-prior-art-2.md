# nested-orchestration 명세 단계 개정 선행연구 대조 기록(2026-10-12, 2차)

사용자가 다시 리뷰에 선행연구 렌즈를 포함하라고 골랐다(통상, 서브에이전트 하나). 대상은 spec 이다(경로가 `docs/superpowers/specs` 아래). 원본은 같은 이름의 폴더에 있고 `search_status`는 `ok`다.

## 발견

| 발견 | 유형 | 출처 |
|---|---|---|
| 따로 쓴 설계를 합치면 구조 일관성이 떨어지고 암묵적 결정(추상화 수준, 관례)이 갈린다. 이 설계는 겹침으로 알아본 항목만 판정한다 | known-failure | arXiv 2606.01490(preprint), CooperBench arXiv 2601.13295(preprint), Cognition 블로그 |
| 명세 작성자를 버리고 다른 에이전트가 구현하면 되물을 곳과 작성 맥락을 잃는다 | known-failure | ChatDev arXiv 2307.07924, Cognition 블로그 |
| 병렬 분담을 단일 에이전트 기준선(Solo)과 비교하지 않는다. 선행 사례에서는 기준선이 더 나았다 | weak-baseline | CooperBench, arXiv 2606.01490, ICML 2026 'The Orchestrator Bottleneck'(초록) |
| 모든 명세 서브 세션을 기다리는 동기 장벽은 가장 느린 하나가 전체를 멈추는 병목이다 | known-failure | Anthropic 엔지니어링 글 「multi-agent research system」 |

## 인용 검증

현재 세션이 arXiv 2606.01490 과 CooperBench 를 열어 확인했다. 2606.01490 초록은 "parallel merge is fundamentally broken"을 적고, IV-E 절은 "merging independently generated designs degrades structural coherence"를 적는다. 다만 Table III 의 v3b(루브릭을 준 병합)는 4.326으로 중위권이라, 렌즈가 옮긴 "병합 변형이 모두 하위권(3.65-3.79)"은 v3a·v3c 에만 맞는다. 결론의 향후 과제는 공유 인터페이스 계약 뒤 모듈별 구현을 검증하지 않은 제안으로 적는다. CooperBench 초록은 "agents achieve on average 30% lower success rates when working together"를, 4절은 선두 모델에서 그 차이가 50%까지라고 적는다. Table 1 의 divergent architecture 29.7%와 Table 2 의 Expectation 42%도 확인했다. ChatDev, Cognition, Anthropic, ICML 초록은 렌즈가 연 것을 그대로 옮겼고 현재 세션은 다시 열지 않았다.

## 결론에 영향을 주는 미확인 항목

렌즈는 영역을 나눠 부분 설계를 병렬로 쓰고 절 붙이기로 합친 뒤 다시 나누는 LLM 사례를 찾지 못했다. 명세 작성자와 구현자 분리의 손실을 정량 측정한 연구와, 조율자에 전체 명세를 모아 맥락을 넘긴 정량 사례도 찾지 못했다. 렌즈는 지지 근거로 SBCE(탐색과 상세 설계의 구분), arXiv 2609.25396(동시 변경 알림 메시지가 실패 82%를 되살림), 2606.01490 의 계약 기반 모듈 구현 제안을 적었다.
