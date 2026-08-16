# reviewer-grounding 2회차 원본 (2026-08-16, 1회차 리뷰)

리뷰어가 돌려준 것을 그대로 옮긴다. 고치지 않는다.

```json
{"lens":"grounding","issues":[
{"where":"기각된 안의 근거로 든 외부 측정 셋(10~12)","type":"unsupported","claim":"세 주장에 출처(논문·URL·측정 조건)가 문서 어디에도 없다. 문서 전체에 링크나 인용이 0개다.","consequence":"이 세 측정이 안을 기각한 유일한 근거인데, 나중에 재검토하는 사람이 근거를 재확인할 방법이 없어 기각 판단을 검증 없이 승계하거나 같은 논쟁을 처음부터 다시 한다.","evidence":"specs/...design.md:10-12 / skills/domain-docs/SKILL.md:22-23"},
{"where":"오늘 잰 값 표(38~44) 및 27~28의 4할 겹침","type":"unsupported","claim":"표의 세 행과 '두 렌즈 산출의 4할이 같은 결함'은 이 세션 안에서만 존재하는 값이라 문서 밖에서 확인할 수 없다. 대조할 산출물이 레포에 없고 reviews/ 디렉터리 자체가 존재하지 않는다.","consequence":"두 결정 전부가 재현 불가능한 단일 관측에 걸린다. 기록의 존재 이유로 든 기준선이 정작 이 결정을 만든 회차에서는 기록되지 않았다.","evidence":"specs/...design.md:27-28,38-44,66-67 / ls docs/superpowers/"},
{"where":"실측 표의 '두 번째가 더 건진 몫' 열(42~44)","type":"mismatch","claim":"앞 세 열에서 마지막 열을 도출하는 단일 산식이 없다. 2회차 기준으로 보면 adversarial이 53%로 '4할 반'과 어긋나고, 합집합 기준으로 보면 grounding이 26%로 '4할 남짓'과 어긋난다.","consequence":"이 열의 값이 그대로 정본에 옮겨졌다. 어느 산식이든 범위가 원표에서 재계산되지 않아, 비용 대비 이득을 이 범위로 판단하는 다음 사람이 잘못된 수치를 근거로 결정한다.","evidence":"specs/...design.md:42-44 / skills/domain-spec-review/SKILL.md:44"},
{"where":"세 호출자 표의 제품 런타임 칸(96)","type":"mismatch","claim":"두 가지로 적었으나 실물 표에는 리스크 0–1에서 '없음' 티어가 먼저 있다. 세 티어 중 하나가 빠졌다.","consequence":"런타임이 항상 최소 한 렌즈를 붙인다고 이해하게 되어, 저위험 경로에서 리뷰어가 없는 것을 위반으로 오판하거나 반대로 불필요한 리뷰 콜 비용을 얹는다.","evidence":"specs/...design.md:96 / skills/domain-llm-runtime/SKILL.md:15-19"},
{"where":"일반 문서 검진 칸(95)과 71","type":"mismatch","claim":"'문서로 남긴다'고 적고 런타임만 로그라며 파일임을 함의하지만, 실물 domain-docs는 어디에 어떤 매체로 남기는지를 정하지 않았다.","consequence":"문서 검진 기록이 세션 출력으로 끝나도 규정 위반이 아니게 된다. 기록의 근거로 든 두 가지가 그 자리에서는 성립하지 않는다.","evidence":"specs/...design.md:71,95 vs skills/domain-docs/SKILL.md:134-136"},
{"where":"세 호출자라는 전제(90~98)","type":"omission","claim":"원칙 정본의 검증 레이어 표에는 렌즈를 부르는 자리가 넷이다. 멀티에이전트 워크플로가 reviewer-* 렌즈 스킬을 직접 호출자로 갖는데 spec의 표는 이 자리를 다루지 않는다.","consequence":"워크플로 검증 단계가 규율 공백으로 남는다. 그 자리에서 렌즈를 돌리는 사람은 어느 규율을 따라야 하는지 판단 근거가 없고, 어느 쪽을 골라도 문서로는 반박되지 않는다.","evidence":"specs/...design.md:90-98 / agent-principles.md:40-46"},
{"where":"검증 절(117~125)","type":"mismatch","claim":"나열된 단언은 실제로 들어가 있다. 다만 같은 스크립트의 섹션 헤더가 아직 폐기된 규칙을 선언한다.","consequence":"테스트 출력 첫 줄이 정반대의 현행 규칙을 알린다. 130-131줄의 단언이 같은 파일 안에서 무력해 보이며, 누군가 그것을 제거하면 회귀 가드가 조용히 사라진다.","evidence":"scripts/test_docs_drift.sh:97 대 130-131"},
{"where":"리뷰 결과를 한 문서로 합산해 남긴다(59~61)","type":"omission","claim":"별도 디렉터리를 고른 근거로 spec 게이트 훅만 검토했다. docs/superpowers/reviews/*.md가 문서 훅 두 개의 사정권에 정확히 들어간다는 사실이 빠졌다.","consequence":"리뷰 기록을 쓸 때마다 그 기록 자체에 대해 검진 넛지가 뜬다. 규정대로 따르면 순환이 생기고, 실제로는 매번 무시하게 되어 문서 검진 넛지 전반의 신호 가치가 떨어진다.","evidence":"specs/...design.md:59-61,69 / hooks/_spec_marker.sh:17-22 / hooks/doc_review_posttooluse.sh:12-16"},
{"where":"선행 spec·plan의 처리(5~8)","type":"omission","claim":"이 변경이 뒤집은 규칙을 확정한 선행 문서 둘이 레포에 그대로 살아 있고 superseded 표시가 없다.","consequence":"같은 날짜의 두 설계 문서가 정반대를 말하므로, 다음에 설계 근거를 찾는 사람이 어느 쪽이 현행인지 문서만으로는 가릴 수 없다.","evidence":"plans/...redesign.md:5,230,251 / specs/...redesign-design.md:134 / skills/domain-docs/SKILL.md:66"},
{"where":"검증 — '개수를 박지 않고 기존 도출 방식을 따른다'(119)","type":"mismatch","claim":"개수를 박지 않은 것은 사실이나 도출 방식은 따르지 않았다. 새로 더한 단언은 전부 고정 문자열 앵커다.","consequence":"규정의 존재가 아니라 문구의 존재만 검사하므로, 문자열이 다른 절에 남아 있기만 하면 규칙이 통째로 사라져도 통과한다. 반대로 문구를 다듬기만 해도 붉어진다.","evidence":"specs/...design.md:119 / scripts/test_docs_drift.sh:3-9,22-38,116-131"}
],"notes":"확인된 것: 렌즈 파일 다섯과 meta-aggregate는 미변경이다. PREP에 추가된 칸은 하나뿐이다. 재리뷰 상한이나 3회 표집 규정은 들어가지 않았다. spec·plan 리뷰 행과 문서 검진 행의 렌즈 구성은 실물과 일치한다. 검증 절이 나열한 단언은 모두 실재한다."}
```
