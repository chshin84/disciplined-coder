# 채점

기대 답은 「렌즈 그룹」 표와 `review-specs`·`review-docs`·`audit-repo-docs`의 발동 기준이다. 위반은 실행할 렌즈 집합이나 필요할 때 렌즈의 처분(제안, 제안 안 함, 판정만 기록)이 기대와 다른 것이다. 소유 혼동은 `ambiguity`에서 "어느 렌즈를 실행할지 누가 정하는가"를 모호하다고 적은 것이다.

| 과제 | 기대 | 현행 위반 | 새 문안 위반 | 현행 소유 혼동 | 새 문안 소유 혼동 |
|---|---|---|---|---|---|
| spec | grounding·fit·adversarial·consistency, prior-art 제안, readability 안 함 | 0 | 0 | 0 | 1(새 문안이 가리킨 `dispatching-lenses`가 입력에 이름으로 없다고 적음) |
| guide | grounding·fit, readability 제안, prior-art 안 함 | 0 | 0 | 1("호출하는 스킬이 정한다"는데 그 스킬 본문이 없다) | 0 |
| subspec | 넷 모두, prior-art 판정만 기록, readability 안 함 | 0 | 0 | 0 | 0 |
| audit | 넷 모두, readability 제안, prior-art 안 함 | 0 | 0 | 1(같은 이유) | 0 |
| proposal | grounding·fit, readability 제안, prior-art 제안(`review-docs`는 효과를 주장하는 제안서에 제안) | 1 | 1 | 0 | 0 |

proposal 의 위반은 두 조건 모두 입력에 `review-docs`의 prior-art 발동 기준이 없어서 생겼다. 다섯 과제 위반 합계는 현행 1, 새 문안 1로 같다. 소유 혼동은 현행 2건, 새 문안 1건이다. 새 문안의 1건은 입력 문서에 `dispatching-lenses`라는 이름을 붙이지 않은 시험 설계 때문이다.
