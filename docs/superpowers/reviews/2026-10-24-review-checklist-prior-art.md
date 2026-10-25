# 리뷰 점검 항목 구성 선행연구 기록

## 발동과 승인

사용자가 2026-10-24 대화에서 선행연구를 직접 요청했다("선행연구해봐"). 오케스트레이터가 아래 프로토콜의 초안(sq1~sq4, 연구자 4명)을 보였다. 사용자는 이어서 "연구를 토대로, 렌즈를 어떻게 개선해야 한국인 비개발자가 클로드 코드 활용을 전반적으로 나아질 수 있도록 서포트할 수 있을지 고민해 달라"고 답했다. 오케스트레이터는 이 답을 프로토콜 승인과 목적 확장으로 해석했다. 그래서 비개발자 지원에 관한 하위 질문 sq5 를 추가하고 연구자를 5명으로 늘렸다. 사용자는 앞선 대화에서 선택을 요구하지 말라고 지시했으므로, 이 확장은 다시 묻지 않고 기록으로 남긴다.

## 프로토콜

- 연구 질문: 다단계 시스템의 설계 문서 리뷰에서 결함 발견과 재현성을 높이고, 비개발자 사용자가 리뷰 결과를 활용할 수 있게 하려면 점검 항목과 리뷰 출력을 어떻게 구성해야 하는가.
- 상황: 결정 근거 탐색
- 모드: survey
- 대조 대상(결정 후보안):
  - A: 분야별 체크리스트를 수백 개 미리 적어 두고 spec 에 해당하는 항목을 골라 리뷰에 넘긴다.
  - B: 대상 종류(단계 사이 자료, 계산, 저장 상태, 화면)마다 질문 세트를 작게 고정하고, 점검 수는 spec 에 나온 대상 수로 정한다.
  - C: 실패 유형별 렌즈(공격, 일관성, 근거, 계약 적합)를 그대로 유지한다.

| ID | 범위 | 포함 | 제외 |
|---|---|---|---|
| sq1 | 결함이 구성요소 안보다 구성요소 사이(인터페이스, 통합)에 몰리는지에 대한 실증 | 결함 분류 연구, 통합 결함 비율, 데이터 파이프라인과 ML 시스템의 결함 연구 | 실증 자료가 없는 의견 글 |
| sq2 | 체크리스트 기반 리뷰의 효과(항목 수, 관점 기반 읽기, 대상 종류별 질문) | checklist-based reading, perspective-based reading, 체크리스트 길이와 효과, FMEA, 인터페이스 통제 문서 | 코드 정적 분석 도구의 기능 소개 |
| sq3 | LLM 리뷰와 평가에서 체크리스트가 재현성과 결함 발견에 미치는 효과 | LLM 코드 리뷰와 설계 리뷰, 체크리스트 기반 LLM 평가, 실행 사이 편차 측정 | 글 품질 채점만 다룬 연구(CheckEval, TICK 은 대조용으로만) |
| sq4 | 수치 계산(벡터화, 병렬 리덕션) 결함을 리뷰보다 테스트로 잡는 근거 | 부동소수점 비결정성, 기준 구현 비교(differential testing), 결정성 테스트, 과학 계산 소프트웨어 결함 연구 | 특정 라이브러리의 버그 보고 하나 |
| sq5 | 비개발자(end-user programmer)가 AI 코딩 도구나 리뷰 결과를 활용할 때의 어려움과 지원 방법 | end-user software engineering, 비전문가의 검증과 디버깅, AI 코딩 도우미 사용 연구, 설명 수준과 질문 형식의 효과 | 마케팅 글, 제품 소개 |

- 질의 금지 목록: disciplined-coder, 디시코더, dc코더, lens-adversarial, lens-consistency, nested-orchestration, 계약 표, 키움, Kiwoom, chshin, 파일 경로 일체
- 탐색 모드 연구자 수: 5
- 산정 근거: 하위 질문 다섯 개의 분야(소프트웨어 결함 실증, 인스펙션 방법론, LLM 평가, 수치 계산, 비개발자 사용 연구)가 서로 달라 묶으면 질의가 흐려진다.
- principles_path: D:\projects\Structure\disciplined-coder\agent-principles.md

## 결과

원본은 같은 이름의 폴더(`search-r1.json`, `researcher-sq1~sq5-r1.json`, `verifier-r1.json`, `synthesis-r1.json`, `map-check-r1.json`)에 있다. 검증자에 보낸 URL 은 30개다.

- overall_status: not-ok. 하위 질문 다섯 개 모두 search_status 는 ok, verification_status 는 partial 이다. 그래서 종합 결론은 판정에 쓰지 않고 보고에만 적는다.
- 커버리지: sq1 7건 중 5건 통과, sq2 11건 중 4건, sq3 14건 중 4건, sq4 11건 중 3건, sq5 9건 중 2건 통과했다.
- 질의 경계 위반: 없음.
- 지도 대조: 근거 없는 칸 없음.
- 탈락: sq1#case#2, sq2#case#3, sq3#issue#5, sq3#case#7, sq4#issue#0, sq4#issue#1, sq4#issue#3, sq4#issue#4, sq4#case#0, sq5#case#0. 사유는 `verifier-r1.json` 의 판정에 있다.
- 판정 불가: sq2#issue#5(leshatton.org), sq3#issue#0, sq3#case#0(snyk.io).
- 검증 실패: 17개 URL(목록은 `search-r1.json` 의 verify_failed).

## 공백 라운드

실행하지 않았다. 다섯 연구자가 모두 후보안 A·B·C 를 직접 비교한 연구를 찾지 못했다고 `not_found` 에 적었고, 공백 라운드로 그 공백이 메워질 근거가 보이지 않았기 때문이다. 사용자는 선택을 요구하지 말라고 지시했으므로 오케스트레이터가 판단하고 보고에 적는다.

## 오케스트레이터 인용 확인

- 확인함: Porter·Votta·Basili 소개 페이지("Checklist reviewers were no more effective than Ad Hoc reviewers"), Miller·Roper·Wood 재현(시나리오 우위, 회의 단계 비효과), arXiv 2608.21298(LLM 지원이 초보 검사자의 smell 탐지 정확도를 낮춤), arXiv 2605.12280(아홉 차수 15, 8, 12, 2, 8, 1, 4, 1, 0건, 여러 회사 모델의 합집합이 심은 결함 5개를 모두 찾음, κ 0.80·0.46), Perry·Stieg PDF TABLE 17(49%·51%, 수정 가중 56%·44%), 오리건 주립대 요약("The assertions subjects were significantly better at fixing the bugs").
- 확인하지 못함: NASA 슬라이드 PDF(본문이 이미지라 글자를 추출하지 못했다). 그래서 보고에서 이 인용의 수치를 결론 근거로 쓰지 않는다.

## 결론에 영향을 주는 not_found·disclosures

- 체크리스트 항목 수에 따른 효과, 대상 종류별 질문 세트, 같은 모델의 체크리스트 유무 비교, 비개발자의 리뷰 출력 활용을 직접 측정한 연구는 찾지 못했다.
- Porter 결과는 저자 소개 페이지(2차)로 확인했다. 오리건 주립대 결과도 연구 그룹의 요약(2차)이다.
- 선행 인스펙션 실험은 사람 검토자 대상이므로 LLM 리뷰어로의 전이는 가정이다.
- arXiv 2605.12280 과 2608.21298 은 초록만 확인했다.
