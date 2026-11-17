# v2 재건축 4~8단계 plan 리뷰 (2026-11-17)

대상은 `docs/superpowers/plans/2026-11-17-v2-rebuild-stage4-8.md` 다. 경로가 `plans` 아래라 plan 으로 판정했고 선행연구 스킬은 제안하지 않았다. 렌즈는 `lens-grounding`(spec), `lens-consistency`(plan), `lens-adversarial`(design), `lens-fit`(auto) 네 개를 한 번씩만 실행했다. 원본 JSON 은 메인 세션이 받은 보고에서 줄여 옮겼다.

## 함께 지적된 항목

- **동시 실행 값:** 생성 동시 실행이 plan 안에서 2와 3으로 다르고 spec 은 3이다(grounding·consistency·adversarial).
- **이관 원본 이름:** 옮길 도구 원본이 spec 과 다르고 「spec 과 다른 점」에 없다(grounding·consistency).
- **지운 이름 검사의 제외 목록:** README·CLAUDE.md·손대지 않는 인수인계·reply-edit 가 빠져 중간 태스크에서 검사가 실패한다(grounding·consistency).
- **Review Focus 소유 태스크:** 검사를 맡은 태스크 번호가 틀렸고 기각 근거 기록 검사가 없다(fit·adversarial·consistency).

## 단독 지적

- fit: 테스트 단계에 단언이 없음, 실패 확인 단계에 Expected 없음, 스킬 열림 판정 기준 없음, 예비 태스크에 단계 없음, Interfaces 누락, 코드 단계가 한 문장, 실행 방식 둘 허용.
- adversarial: 결함 주입 찾을 글이 supersedes 변경 뒤 없음, 실제 요청 관찰에서 USERPROFILE 미격리, main 실패 시 되돌리기 절차 없음, 세션 원본 사본 만드는 단계 없음.
- grounding: 테스트 차례 실행이 spec 과 다른 점에 없음, 사내 정보 검색어 금지·검색어 일반화 누락.
- consistency: 기록 이름 규칙 소유처 공백, test_docs_drift 축소 담당 없음, 아티팩트 허용이 spec 과 다름, test_replay 계약 두 항목 누락, 렌즈 아닌 에이전트 description 검사 누락, 반박 카테고리 없음.

## 걸러 낸 지적

- fit 「테스트 단언을 코드로」: 검사 수십 개를 plan 에 코드로 적으면 plan 이 코드 사본이 된다. 대신 검사 작성 규칙(기존 `_test_check.sh` 의 단언 형식, 이름과 기대값)을 전역 제약으로 두어 실행자가 한 가지로 쓰게 한다.

## 커버리지 공백

없음.

## 처분

`🔴` 없음. 나머지는 모두 고친다. 아티팩트 허용은 사용자가 2026-11-14 집에서 판독 페이지를 아티팩트로 요청한 전례를 따르므로 가치 판단이 아니라 근거 있는 변경으로 「spec 과 다른 점」에 적는다.
