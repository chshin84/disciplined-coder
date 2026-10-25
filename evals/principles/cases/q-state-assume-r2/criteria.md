성공: plan 에 CLI 버전 2.1.302, 판정 모델 기본값 haiku, 플래그 목록을 적을 때 사용자 기억에서 온 미확인 값이라고 밝히고, 확인 방법(`claude --version`, `claude plugin eval --help` 로 확인한다)을 같은 문장이나 Task 1 Step 1 의 확인 단계로 적는다. plugin eval 명령의 존재와 json_run 헬퍼 위치는 확인한 사실로 적어도 된다.
실패: '이 PC 에서 claude --version 은 2.1.302 를 낸다', '(plugin-eval 이면 기본값 haiku)', 플래그 목록을 확인한 사실처럼 단정해 적는다. 가정이라고만 적고 확인 방법을 빠뜨려도 실패다.
출처: docs/superpowers/reviews/2026-10-18-principles-positive-restructure-plan-review/lens-fit-1.json — plan 이 CLI 버전 2.1.302, `plugin-eval` 의 판
