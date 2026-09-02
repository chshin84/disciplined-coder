# 자기감사 처분 뒤 문서 검진 (2026-09-03)

2026-09-02 자기감사의 확정 41건을 main `94b3799` 위에서 처분하며 고친 문서 아홉(README·domain-plugin·
domain-docs·project-doc-audit·domain-spec-review·meta-aggregate·lens-readability·lens-prior-art·
nested-orchestration)과 매니페스트 둘을 `domain-docs` 검진 절대로 검진했다. 렌즈는 `lens-grounding`·
`lens-fit`을 문서 묶음에, `lens-readability`를 README에 한 번씩 띄웠다. 원본은 같은 이름 폴더의
`grounding-1.json`·`fit-1.json`·`readability-1.json`이다. **렌즈는 한 번씩만 돌렸다.**

## 검진 범위와 렌즈 배정

- **`lens-grounding`** — 문서 아홉의 바뀐 문장을 훅·스크립트·매니페스트·실행체·2026-09-02 설계와 대조했다.
  주입 사실은 오늘 코드에서 바뀐 것 여덟(경로 술어와 안내문의 공유 헬퍼, Stop 훅의 git 실패 알림, 문서
  넛지의 프로젝트 안 한정, 파이썬 하나로 모은 JSON 처리, `-ef` 판정, 죽은 함수 제거, 매니페스트 문안,
  기록 이름 규칙)이다.
- **`lens-fit`** — 같은 문서 묶음과 매니페스트 둘을 `writing-korean`의 형식 규칙과 `domain-plugin`의
  frontmatter·매니페스트 규칙과 `domain-docs`의 문서 타입 표에 대조했다.
- **`lens-readability`** — README 하나에 걸었다. 목적은 "설치해 본 적 없는 사람이 README만 보고 설치해
  동작 확인까지 마치고, 세션에 무엇이 강제되는지와 그것을 어떻게 끄는지 알게 한다"다.

## 기계 검사 결과

렌즈를 띄우기 전과 반영한 뒤에 계약 테스트 넷을 돌렸다. 마지막 결과는 `test_assertions` 8, `test_docs_drift`
344, `test_hooks` 69, `test_scaffold` 220으로 FAIL 0이고, `claude plugin validate ./`는 `version` 경고
하나만 낸다. README에 금지 낱말은 0건이다.

## 발견

`lens-grounding` 일곱.

- `domain-docs` 검진 절이 기록에 처분을 적으라고 하면서 같은 문서의 타입 표는 안 적는다고 한다(둘 이상의
  근거 — 2026-09-02 설계의 「이미 정해진 것」과 표 기록 행).
- README가 "넛지 셋은 리뷰 기록에 뜨지 않는다"고 적었으나 새 문서 양식 넛지에는 리뷰 기록 제외가 없었다.
- 같은 문장이 spec/plan 넛지에도 프로젝트 밖 제외가 걸린 것처럼 읽히지만 그 훅은 `path_in_project`를
  부르지 않았다.
- 기록 이름 규칙이 종류를 둘로 닫아 `-prior-art` 기록과 실행체 요약문의 이름이 없었다.
- `project-doc-audit`의 회차 표기(종류 뒤)가 실재하는 기록 하나(`-3-check.md`)와 어긋난다.
- `nested-orchestration`이 실재하지 않는 Write 차단 훅을 근거로 들었다.
- README의 `ERROR` 설명이 정본 복사 실패 하나로 좁았고 `@import` 배선 실패가 빠졌다.

`lens-fit` 여덟.

- `domain-docs` 「수정 규율」 표 머리 `어떻게`가 명사구가 아니다.
- 제목과 불릿 라벨에 괄호 절(「(여기가 소유자)」·「(이 렌즈에만 있다)」·「(순위가 아니다)」)이 여섯 곳 남았다.
- `lens-prior-art` 체크리스트에서 `결말` 하나만 평서문이다.
- `lens-readability` 「목적 적는 법」 표 첫 열에 문장과 명사구가 섞였다.
- `meta-aggregate`만 불릿 라벨 뒤에 쌍점을 쓴다.
- 기록 이름 규칙이 렌즈별 원본 폴더의 파일 이름과 확장자를 정하지 않아 실물이 `.md`와 `.json`으로 갈렸다.
- 그 규칙이 언제부터 걸리는지 없고 안 지키는 옛 기록은 고칠 수 없다.
- `domain-plugin`의 frontmatter 규칙에 결정론 검사가 없다.

`lens-readability` 일곱 — README의 원인 셋 문장이 한 문장에 겹쳤고 대책은 하나뿐이었다, 절 제목과 첫
문장이 이름 대신 '것'을 썼다, "게이트와 넛지 넷"이 두 가지로 읽혔다, "되돌릴 수 있다"와 "강한 환기에
가깝다"가 결과를 안 적었다, 끄기 변수를 어디에 두는지 없었다.

## 둘 이상의 렌즈가 함께 잡은 것

기록 이름 규칙을 `lens-grounding`(종류 공백·회차 위치)과 `lens-fit`(원본 폴더·발효 시점)이 다른 각도로
잡았다. README 「세션에 걸리는 것」 절을 `lens-grounding`(넛지 범위의 사실)과 `lens-readability`(제목·개수·
결과 서술)가 함께 잡았다.

## 상충과 커버리지 공백

판정이 갈린 짝은 없다. `lens-readability`가 남긴 「더 확인할 것」 둘은 실측으로 갈렸다 — 훅 넷은
`DISCIPLINED_CODER_REVIEW_GATE`를 프로세스 환경에서 읽고, `claude plugin install --scope`의 기본값은
`user`다. `lens-fit`이 남긴 물음 하나(렌즈 원본 폴더 규칙의 소유자)는 처분이라 여기 적지 않는다. 회차
표기와 어긋나는 옛 기록 하나(`2026-08-30-project-doc-audit-3-check.md`)는 찍힌 기록이라 고치지 않는다.
