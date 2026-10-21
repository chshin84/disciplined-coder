---
name: domain-readme
description: 사용자용 README를 쓰거나 고칠 때의 규칙이다. 독자가 빨리 답해야 하는 네 가지와 절의 권장 동선과 무엇을 넣지 말아야 하는지를 포함한다. README를 새로 쓸 때, 절 순서를 정할 때, 배지와 목차와 스크린샷을 넣을지 정할 때, README에서 내용을 뺄 때 연다.
---
# domain-readme — 사용자용 README를 쓰는 법

README는 프로젝트의 첫인상이자 종종 유일한 접점이다. 보편 원칙은 에이전트원칙(`agent-principles.md`)이 소유하므로 여기서 다시 적지 않고 이름으로 참조한다. 분량은 에이전트원칙 「행동」의 `YAGNI`, 한 파일이 한 일만 하는 것은 같은 절의 `FOCUSED`, 결론을 먼저 두는 것은 에이전트원칙 「출력」의 `BOTTOM-LINE` 이다.

## 독자가 빨리 답해야 하는 질문

이 도구가 내 문제를 푸는가, 내가 쓸 수 있는가, 누가 만들었는가, 더 배우려면 어디로 가는가다. 이 동선을 방해하는 요소는 군더더기다.

## 독자 분리

사용자 설치·사용 경로와 개발자 내부 근거를 따로 두어라. 개발자 내부 근거는 아래 「빼는 순서」대로 README 밖에 두어라.

## 권장 동선

순위가 아니다. 제목과 한 줄 설명 다음 핵심 셀링포인트, 무엇을 왜 하는지, 설치, 사용 예시, 주의와 한계, 만든 사람, 더 읽기와 기여 순이다. 절에는 번호 대신 이름을 붙여라.

## 필요한 것만

배지·목차·스크린샷·변경 이력은 프로젝트가 실제로 필요로 할 때만 넣어라. 에이전트원칙의 `YAGNI`가 그 판단의 기준이다.

배지는 빌드·테스트 커버리지·의존성 최신성처럼 도구가 자동으로 검사한 결과를 보이는 배지만 넣어라. Trockman 등(ICSE 2018)은 npm 저장소에서 이런 배지가 실제 품질과 함께 움직이고, 정보만 알리는 배지는 그 관계가 약하다고 보고했다.

## 빼는 순서

README에서 뺄 내용은 아래 순서로 처리하라. 새 문서는 관리할 대상을 늘려 낡기 쉬우므로 마지막에 만든다.

- **이미 있으면 가리키기** — 같은 내용이 코드 주석이나 다른 문서에 있으면 README에서 지우고 그곳을 가리켜라.
- **기존 문서에 넣기** — 없으면 그 내용이 귀속될 기존 문서에 옮겨라.
- **새 파일 만들기** — 귀속될 문서가 없을 때만 새 파일을 만들어라. 변경 이력은 `CHANGELOG`, 기여 방법은 `CONTRIBUTING`이 관례다.

## 출처

[banesullivan/README](https://github.com/banesullivan/README), [awesome-readme](https://github.com/matiassingers/awesome-readme), [Make a README](https://www.makeareadme.com/), [글 잘 쓰고 싶은 개발자](https://wikidocs.net/book/20224), [좋은 README 작성법](https://insight.infograb.net/blog/2023/08/23/good-readme/), [GitHub — About READMEs](https://docs.github.com/en/repositories/managing-your-repositorys-settings-and-features/customizing-your-repository/about-readmes), [Google 문서 지침 — READMEs](https://google.github.io/styleguide/docguide/READMEs.html), [Open Source Guides — Starting a project](https://opensource.guide/starting-a-project/), [Trockman 등, Adding Sparkle to Social Coding (ICSE 2018)](https://www.cs.cmu.edu/~ckaestne/pdf/srcicse18.pdf)이다. 선행연구 기록은 `docs/superpowers/reviews/2026-10-21-readme-writing-prior-art.md`에 있다.
