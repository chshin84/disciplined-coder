---
name: domain-readme
description: 사용자용 README를 작성·수정하거나, 절 순서와 배지·목차·스크린샷 포함 여부를 정하거나, 내용을 뺄 때 열어라.
---
# domain-readme — 사용자용 README를 쓰는 법

독자는 README로 프로젝트 첫인상을 얻고, 종종 여기서만 접한다. 첫 화면에 결론을 앞세우고, 하는 일과 설치법을 쉬운 말로 적어라. 요청받지 않은 절은 넣지 마라.

## 독자가 빨리 답해야 하는 질문

이 도구가 내 문제를 푸는가, 내가 쓸 수 있는가, 누가 만들었는가, 더 배울 곳은 어디인가. 독자가 이 답을 찾는 흐름을 방해하면 군더더기다.

## 독자 분리

사용자의 설치·사용 경로와 개발자 내부 근거를 나누어라. 내부 근거는 아래 「빼는 순서」에 따라 README 밖으로 빼라.

## 권장 동선

순위가 아니다. 제목과 한 줄 설명, 핵심 셀링포인트, 무엇을 왜 하는지, 설치, 사용 예시, 주의와 한계, 만든 사람, 더 읽기와 기여로 이어진다. 절에는 번호 말고 이름을 붙여라.

## 필요한 것만

배지·목차·스크린샷·변경 이력은 프로젝트에 실제로 필요할 때만 써라. 독자가 그것 없이도 네 질문에 답할 수 있다면 빼라.

배지는 빌드·테스트 커버리지·의존성 최신성처럼 도구가 자동 검사한 결과를 보여 주는 것만 달아라. Trockman 등(ICSE 2018)은 npm 저장소에서 이런 배지는 실제 품질과 맞물리지만, 정보만 전하는 배지는 연관성이 약하다고 밝혔다.

## 빼는 순서

README에서 덜어 낼 내용은 차례대로 정리하라. 새 문서는 관리 대상이 늘어 낡기 쉬우므로 마지막 수단으로 둔다.

- **있는 곳 알리기** — 코드 주석이나 다른 문서에 같은 내용이 있으면 README에서 빼고 그곳을 알려라.
- **기존 문서로 옮기기** — 없다면 내용이 속할 기존 문서에 넣어라.
- **새 파일 만들기** — 속할 문서가 없을 때만 새로 만들어라. 관례상 변경 이력은 `CHANGELOG`, 기여 방법은 `CONTRIBUTING`에 둔다.

## 출처

[banesullivan/README](https://github.com/banesullivan/README), [awesome-readme](https://github.com/matiassingers/awesome-readme), [Make a README](https://www.makeareadme.com/), [글 잘 쓰고 싶은 개발자](https://wikidocs.net/book/20224), [좋은 README 작성법](https://insight.infograb.net/blog/2023/08/23/good-readme/), [GitHub — About READMEs](https://docs.github.com/en/repositories/managing-your-repositorys-settings-and-features/customizing-your-repository/about-readmes), [Google 문서 지침 — READMEs](https://google.github.io/styleguide/docguide/READMEs.html), [Open Source Guides — Starting a project](https://opensource.guide/starting-a-project/), [Trockman 등, Adding Sparkle to Social Coding (ICSE 2018)](https://www.cs.cmu.edu/~ckaestne/pdf/srcicse18.pdf)을 참고했다. 선행연구는 `docs/superpowers/reviews/2026-10-21-readme-writing-prior-art.md`에 기록했다.
