# 선행연구 에이전트 specagents 하부 명세 — spec 리뷰

2026-10-18에 명세 서브 세션이 `docs/superpowers/specs/2026-10-18-prior-art-agent-specagents-design.md`(커밋 전 초안)를 `review-specs` 절차로 리뷰했다. 렌즈는 `lens-grounding`, `lens-consistency`, `lens-adversarial`, `lens-fit`이며 원본은 같은 이름 폴더에 있다. 렌즈를 한 번씩만 실행했다. 대상은 `docs/superpowers/specs` 아래 파일이라 spec 으로 판정했다.

## 선행연구 에이전트의 제안

제안하지 않았다. 명세 서브 세션은 사용자와 대화하지 못하고, 이 하부 명세는 이미 선행연구를 마친 큰 명세의 구현 명세라 발동 기준(되는지 자체가 미지수인 일)에 들지 않는다.

## 합친 지적

| 지적 | 잡은 렌즈 |
|---|---|
| 큰 명세 절을 '전체' 옮기라는 지시가 `lens-prior-art`·`lens-derived`를 스킬 본문에 들여와 새 부정 검사와 충돌한다(「발동과 기록」「실행할 때 지킬 상한」「출력 스키마」「인용 확인」) | grounding, consistency, adversarial |
| 큰 명세는 레퍼런스 프롬프트를 옛 렌즈에서 옮기라고 하는데 하부 명세는 새로 쓰게 하고, 지우기 전 대조에서도 뺐다 | grounding, consistency |
| 큰 명세 「판정 규약」의 '가드 URL 확인은 연구자에게 적용하고 검증자가 다시 판정한다'를 받을 문장이 없다 | grounding, consistency |
| `review-specs` 138행 소유 문장("그 렌즈를 … 인용 검증은 호출자 책임이다")의 처리가 없다 | grounding, consistency |
| `lens-prior-art` 디렉터리 삭제와 `aggregating-lenses` 22행·`dispatching-lenses` 73행 처리를 같은 커밋에 두라는 순서 제약이 없다 | grounding, adversarial |
| `synthesize` 모드의 '행의 `ref`'가 `evidence_map` 행 형식에 없는 키다 | grounding, consistency |
| 넛지가 `prompt` 키 앞에 경로 필드가 온다는 키 순서를 가정으로 밝히지 않았다 | grounding |
| 「인용 확인」에 `review-specs` 142행을 옮기면 범위 문장이 둘이 된다 | consistency |
| 옛 렌즈 스키마 블록의 `principles_applied` 설명이 `aggregating-lenses` 계약을 가리켜 같은 절 산문과 부딪친다 | consistency |
| 원본 파일 규칙 표가 스킬과 `review-docs` 양쪽에 생기거나, 4단계 확인이 '아래' 표를 가리킨다 | consistency |
| description 을 발동 시험으로 고치는 주체가 빌더로 적혀 있는데 발동 시험은 현재 세션이 맡는다 | consistency |
| 지정한 교체 문구가 `review-specs`와 `domain-discipline.md`의 대구 한도를 넘긴다 | consistency, adversarial |
| 스킬의 「레퍼런스 프롬프트」「상황별 전략」 절 첫 줄이 산문이 아니라 첫 문장 검사에 실패하며, 감사 대상은 `git ls-files`로만 도출된다 | consistency, adversarial |
| frontmatter 안전 검사를 `agents/*.md`로 넓히는데 소유자 `domain-plugin` 「frontmatter」는 스킬과 커맨드만 다룬다 | consistency |
| `review-docs` 「기록」 절의 판정 기록 소유 문장이 처리 목록에 없다 | consistency |
| `dispatching-lenses` 38·90행이 grep 에 걸리는데 처리 목록에도 그대로 두는 줄에도 없다 | consistency |
| `dispatching-lenses` 75행 구절만 지우면 문장이 연결어미로 끝난다 | consistency |
| `review-specs` 76행을 `overall_status`가 `ok`일 때만으로 바꾸면 일부 하위 질문이 `partial`일 때 나머지 발견의 처분이 없다 | consistency |
| 서브에이전트가 받는 정의 본문이 출력 형식을 스킬 절 이름으로만 가리킨다 | adversarial |
| 넛지 픽스처의 '과제 요청 메시지'가 정해져 있지 않고, 과제 질문 그대로는 알림 조건을 만족하지 않는다 | adversarial |
| 주제어와 요청형이 함께 있지만 요청이 아닌 메시지를 구분하지 못하는 한계가 위험에 없다 | adversarial |
| 부정 검사 셋이 명령 오류와 대상 부재를 통과로 센다 | adversarial |
| 옛 이름이 없다는 부정 검사 셋은 `domain-pruning` 「분류」의 일회성이다 | adversarial |
| 굵은 머리말이 셋째 제목 층으로 쓰였고 「」로 가리켜진다 | fit |
| 문서 자신의 문장에 대구가 두 번 있다 | fit |
| 단락이 네 문장을 넘고, 불릿 한 항목이 여러 문장이다 | fit |
| 대상을 개수로 가리킨다(체크리스트 다섯 항목, 과제 세 개, 두 정의) | fit |
| frontmatter 표의 `model` 행 말끝이 다른 행과 다르다 | fit |
| 판단 주체가 시험이나 생략으로 적혀 있다 | fit |
| 문장 중간 관형절 | fit |
| 검사 헬퍼 이름을 처음 나올 때 풀지 않았다 | fit |

## 커버리지 공백

배정된 렌즈 넷이 모두 JSON 을 돌려주었다. `lens-consistency`가 「참조 처리 목록」 밖의 후속 확인으로, `specworkflow`가 `workflows/`나 시험 도구에 옛 이름을 적으면 완료 조건이 실패할 수 있다고 적었다. 이 하부 명세만으로는 확인할 수 없어 현재 세션에 넘긴다.
