---
name: domain-readme
description: 사용자용 README를 작성·수정하거나, 절 순서와 배지·목차·스크린샷 포함 여부를 정하거나, 내용을 뺄 때 열어라.
---
# domain-readme — 사용자용 README를 쓰는 법

독자는 README로 프로젝트를 처음 접하며, 유일한 접점인 때도 많다. 첫 화면에 기능과 설치법을 쉽게 적어라. 결론을 먼저 써라. 요청받지 않은 절은 추가하지 마라.

## 독자가 빨리 답해야 하는 질문

이 도구가 내 문제를 해결하는가, 내가 쓸 수 있는가, 누가 만들었는가, 더 배울 곳은 어디인가다. 이 흐름을 방해하는 요소는 군더더기다.

## 독자 분리

사용자용 설치·사용 안내와 개발자용 내부 근거를 분리하라. 내부 근거는 아래 「빼는 순서」대로 README 밖에 두라.

## 권장 동선

중요도 순이 아니다. 제목과 한 줄 설명, 핵심 장점, 기능과 필요성, 설치, 사용 예시, 주의사항과 한계, 만든 사람, 더 읽기와 기여 순으로 둔다. 절에는 번호 대신 이름을 붙여라.

## 필요한 것만

배지·목차·스크린샷·변경 이력은 프로젝트에 꼭 필요할 때만 넣어라. 없어도 독자가 앞의 네 질문에 답할 수 있으면 빼라.

배지는 빌드·테스트 커버리지·의존성 최신성처럼 도구가 자동으로 검사한 결과를 보여 주는 종류만 써라. Trockman 등(ICSE 2018)은 npm 저장소에서 이런 배지가 실제 품질과 함께 변하지만, 정보만 알리는 배지는 연관성이 약하다고 보고했다.

## 빼는 순서

README에서 뺄 내용은 아래 순서대로 처리하라. 새 문서는 관리 대상이 늘어 낡기 쉬우므로 마지막에 만든다.

- **이미 있으면 가리키기** — 같은 내용이 코드 주석이나 다른 문서에 있으면 README에서 지우고 그 위치를 가리켜라.
- **기존 문서로 옮기기** — 없으면 성격에 맞는 기존 문서에 넣어라.
- **새 파일 만들기** — 옮길 문서가 없을 때만 새 파일을 만들어라. 변경 이력은 `CHANGELOG`, 기여 방법은 `CONTRIBUTING`이 관례다.

## 출처

[banesullivan/README](https://github.com/banesullivan/README), [awesome-readme](https://github.com/matiassingers/awesome-readme), [Make a README](https://www.makeareadme.com/), [글 잘 쓰고 싶은 개발자](https://wikidocs.net/book/20224), [좋은 README 작성법](https://insight.infograb.net/blog/2023/08/23/good-readme/), [GitHub — About READMEs](https://docs.github.com/en/repositories/managing-your-repositorys-settings-and-features/customizing-your-repository/about-readmes), [Google 문서 지침 — READMEs](https://google.github.io/styleguide/docguide/READMEs.html), [Open Source Guides — Starting a project](https://opensource.guide/starting-a-project/), [Trockman 등, Adding Sparkle to Social Coding (ICSE 2018)](https://www.cs.cmu.edu/~ckaestne/pdf/srcicse18.pdf)를 참고했다. 선행연구 기록은 `docs/superpowers/reviews/2026-10-21-readme-writing-prior-art.md`에 있다.
