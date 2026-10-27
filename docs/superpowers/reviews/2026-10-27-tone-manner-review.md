# 청자와 내용으로 문체를 정하는 조절 축 — spec 리뷰 기록

## 대상과 실행

대상은 `docs/superpowers/specs/2026-10-27-tone-manner-design.md` 이다. 경로가 `docs/superpowers/specs` 아래이므로 spec 으로 구분했다. 렌즈는 `lens-grounding`(spec), `lens-consistency`(spec), `lens-adversarial`(design), `lens-fit`(auto)을 한 번씩만 실행했다. 원본은 같은 이름의 폴더에 있다. 오케스트레이터가 렌즈의 hand-back 메시지에서 원본을 옮겨 저장했고, 그때 일부 칸을 요약했다.

선행연구 스킬은 제안하지 않았다. 이 spec 은 같은 날 실행한 선행연구(`2026-10-27-tone-manner-prior-art.md`)를 근거로 썼기 때문이다.

## 둘 이상의 렌즈가 함께 지적한 항목

- 「출력」 절 머리 문장('모든 글을 한국어 문어체로')이 바꿀 대상에 없다(grounding, consistency).
- `KO-SYNTAX` 머리 문장('모두 적용하라')이 개조식 면제와 충돌한다(grounding, consistency).
- `ONE-IDEA`·`SECTION-HEAD` 가 규칙 분류에 없다(grounding, consistency).
- 경어 축이 격식 축과 겹치고 값이 정의되지 않았다(consistency, adversarial).
- 추정 배경 규칙과 `ASK-OPTIONS` 의 관계가 없다(consistency, adversarial, grounding 노트).
- 2026-09-24 사용자 지시를 바꾸는데 사용자 승인 기록이 없고, '사용자가 고른 네 축'은 선호를 결정처럼 적었다(grounding, adversarial).
- 검증 절이 저장소 시험 규칙과 다르고 기존 시험 단위의 처분이 없다(grounding, consistency, adversarial).

## 커버리지 공백

lens-fit 계약과 dispatching-lenses 의 호출 계약에 축 위치를 넘기는 작업이 없다(consistency). `docs/domain-discipline.md` 가 바꿀 파일에 없다(consistency).

## 걸러 낸 지적

걸러 낸 지적은 없다. grounding 의 '6일 동안 경고 3건' 출처 지적은 오케스트레이터가 같은 세션에서 세션 기록을 집계해 얻은 수치이지만, spec 에 집계 방법이 적혀 있지 않은 것은 사실이므로 그대로 받았다.

## 처분

`🔴` 는 한 건이다. 이 변경은 사용자가 2026-09-21(문어체를 강하게)과 2026-09-24(지시가 있을 때만 문체를 바꿀 것)에 정한 기준을 바꾼다. 사용자는 같은 날 조절 축 제안이 마음에 든다고 했지만 "당장 정하지 말라"고도 했다. 그래서 기준 대체는 사용자의 가치판단이 필요하다.

나머지 지적은 모두 고친다. 경어 축은 격식 축에 상대높임을 넣고 사용자가 선호한 네 축으로 줄인다. 추정 규칙은 파일 산출물의 문체에만 적용하고 `ASK-OPTIONS` 의 예외로 명시한다. 축 표는 상시 원칙에 넣지 않고 `docs/domain-korean.md` 에 둔다.

렌즈를 한 번씩만 실행했다.
