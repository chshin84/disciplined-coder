## 전체 판정

이 회차는 구조적으로 건강하다. 판정에 이르지 못한 발견이 0건이고 응답하지 않은 렌즈도 0개라, 확정 37건과 기각 23건이 모두 반박 검증을 거쳐 갈렸다. 결정론 검사의 `allPassed:false`는 실행 계약이 깨진 것을 뜻하지 않는다 — `scripts/test_*.sh` 다섯이 합계 PASS=630 FAIL=0으로 끝났고 `claude plugin validate ./`도 계약이 고정해 둔 `version` 경고 하나만 냈으므로, false를 만든 것은 같은 결과 배열에 실려 온 발견 일곱이다. 그 일곱 가운데 여섯은 확정 37건과 겹치지 않아 이번 회차의 실질 발견은 43건이다. 확정 발견끼리 한쪽은 고치라 하고 다른 쪽은 그대로 두라고 하는 정면 상충은 없으나, 처분이 갈리는 짝 다섯을 아래에 표시한다. 발견이 흩어져 있지 않고 뿌리 일곱에 몰려 있으며, 그 가운데 가장 큰 것은 문서를 압축한 최근 회차(커밋 2f64d74)가 사용자 읽기 경로에서 지운 고지들과, 같은 사실을 두 곳에 손으로 맞춰 적은 사본들이다.

## 확정 발견 정리

### 사용자 결정이 필요한 것

- **spec과 plan의 수명 정책** — `skills/domain-docs/SKILL.md:52`가 "spec은 배포된 뒤 지운다"고 규정하는데 spec 22건과 plan 18건이 한 번도 삭제되지 않았다. 규칙을 집행할지, 규칙을 실제로 하는 것으로 고칠지가 갈림길이다.
- **README의 고지 범위** — Stop 하드 게이트와 전역 `settings.json` 수정과 `docs/superpowers/reviews/` 생성과 Codex 등록 절차의 미검증 표시를 되살리라는 발견 넷이 README 압축 방향과 반대다. 압축을 유지할지 필수 고지를 예외로 둘지 결정이 필요하다.
- **전역 설정 파일 수정 동작** — `scripts/_ensure_autoupdate.sh:56`이 묻지 않고 사용자 `settings.json`의 `autoUpdate`를 채우고 파일 전체를 다시 기록한다. 문서에 적는 것으로 끝낼지 동작 자체를 바꿀지는 사용자 몫이다.
- **정합성 렌즈의 묶음 규칙** — `skills/project-doc-audit/SKILL.md:47`의 "묶음에 한 번"과 `:60`의 "셋부터 얕아진다"가 대상 문서 열아홉인 이 레포에서 동시에 성립하지 않는다. 예외를 명시할지 예산 분할을 도입할지 정해야 한다.

### 사용자 읽기 경로의 누락과 오도

- **Stop 하드 게이트 미기재** — `README.md:38-43`에 게이트도 해제 마커도 환경변수도 없다.
- **자동 갱신 켜기 미기재** — `scripts/_ensure_autoupdate.sh:56`의 동작이 사용자 문서 어디에도 없다.
- **커맨드 문서의 범위 단정** — `commands/setup-discipline.md:10`이 홈에만 쓴다고 적지만 `scripts/scaffold.sh:55`가 프로젝트 CLAUDE.md를 고친다.
- **Codex 절차의 확신도** — `README.md:43`이 미검증 절차를 사실로 적고 명령 두 줄과 미검증 표시가 함께 사라졌다.
- **문제 해결 안내의 원인 서술** — `README.md:18`이 홈 어긋남을 단독 원인으로 지목하나 읽는 쪽과 쓰는 쪽이 같은 `_resolve_home.sh`를 쓴다.
- **리뷰 기록 생성 미기재** — `README.md:36`이 새 파일이 없다고 적지만 정본이 `docs/superpowers/reviews/`에 기록을 남기라고 지시한다.

### 정본과 스킬 사이의 사본과 포인터

- **배포 방식의 런타임 차이** — `agent-principles.md:80-81`이 `@import`만 적고 Codex의 본문 인라인을 담지 않는다.
- **렌즈 호출자 주장의 어긋남** — `skills/lens-adversarial/SKILL.md:3`이 `project-doc-audit`을 호출자로 적으나 그 배정 표에 없다.
- **처분 절의 호출자 열거** — `skills/meta-aggregate/SKILL.md:42-45`가 각 호출자 문서와 같은 사실을 다시 적는다.
- **경로 술어의 둘째 사본** — `hooks/spec_review_stop.sh:39`의 pathspec이 `hooks/_spec_marker.sh`의 술어와 같은 목록을 다시 적는다.
- **Codex 매니페스트 문안** — `.codex-plugin/plugin.json:4`가 Claude 쪽 143자를 그대로 복제하는데 대조 검사가 그 파일을 훑지 않는다.
- **frontmatter 소유의 공백** — `skills/domain-docs/SKILL.md:7`이 소유를 `domain-plugin`에 넘기지만 그 문서에 규칙이 한 줄도 없다.
- **codex-scaffold 머리말의 괄호** — `scripts/codex-scaffold.sh:5`가 README에서 사라진 항목을 자기 몫이라고 적는다.
- **DESIGN-NOTES 포인터**(결정론) — `docs/superpowers/specs/2026-07-03-ultracode-review-toggle-design.md:5`가 없는 파일로 독자를 보낸다.
- **검증 레이어 표 포인터**(결정론) — 같은 spec이 정본에서 사라진 표를 소유자로 가리킨다.

### 조용한 통과와 실패 통보

- **마커 부분 일치** — `hooks/_spec_marker.sh:10`이 마커를 인용한 산문까지 통과시켜 게이트가 열린다.
- **제어 문자 이스케이프 누락** — `hooks/_json_escape.sh:8`이 0x20 미만 문자를 남겨 차단 응답이 통째로 무시된다.
- **가장 심한 실패의 통보 통로** — `scripts/codex-scaffold.sh:55`가 원칙 미적재를 stderr로만 알리고 0으로 끝난다.
- **중복 제거의 손실 감지 부재** — `.claude/workflows/self-audit.js`의 채택 조건이 축소를 막지 못한다.
- **경고의 원인 오지목** — `scripts/_ensure_autoupdate.sh:47`이 깨진 플러그인 파일 대신 사용자 설정 파일을 지목한다.
- **락 상한과 안내의 불일치** — `scripts/_managed_block.sh:83`의 600틱이 주석의 60초보다 길다.
- **문서 훅까지 끄는 스위치**(결정론) — `DISCIPLINED_CODER_REVIEW_GATE`가 훅 넷을 모두 끄는데 `domain-docs`에 그 사실이 없다.

### 검사 스위트의 사각

- **블록 경계 판정** — `scripts/test_assertions.sh:22`가 `# ---` 구획을 못 보아 아무것도 확인하지 않는 블록 넷이 초록으로 남는다.
- **BSD wc 비교** — `scripts/test_hooks.sh:174`가 맥에서 제품과 무관하게 실패한다.
- **훅 배선 패리티의 얕음** — 두 배선 파일을 이벤트 이름으로만 맞대어 공유 훅 누락을 잡지 못한다.
- **CI의 실패 처리 형태**(결정론) — `.github/workflows/ci.yml`이 정본 명령을 다시 쓰면서 첫 실패에서 멈추는 형태로 바꿨다.
- **번호로 부르는 검사와 빈 번호**(결정론) — `scripts/test_codex_scaffold.sh`가 블록을 번호로 부르고 case4가 비어 있다.
- **출력 문구의 금지 낱말**(결정론) — `scripts/test_docs_drift.sh`의 라벨과 echo가 이 플러그인이 문자열로 거르라고 정한 낱말을 쓴다.

### 실행체 배선

- **회차 기록 미배선** — `.claude/workflows/self-audit.js`가 렌즈 여덟을 돌리면서 정본이 의무화한 기록을 어디서도 지시하지 않는다.

### 문체 규칙의 자기 위반

- **규칙 소유 문서의 소제목** — `skills/writing-korean/SKILL.md:60,76,90`이 자기 조항을 어긴다.
- **이름 없는 소제목** — `skills/lens-adversarial/SKILL.md:15`가 명사구 없이 서술문으로만 되어 있다.
- **세 렌즈의 반복 소제목** — `lens-adversarial:18`·`lens-fit:15`·`lens-readability:58`이 주장을 제목과 첫 문장에 두 번 적는다.
- **괄호 소유권 선언** — `domain-docs`·`meta-aggregate`·`lens-prior-art`의 제목 여섯이 괄호에 서술절을 담는다.
- **혼용 라벨 목록 셋** — `domain-plugin:10-13`과 `domain-docs:20-26,31-34`와 `README.md:40-43`이 한 목록에서 말끝을 맞추지 않는다.
- **의문절 표 머리** — `domain-docs:62`·`lens-prior-art:48`·`lens-readability:19`가 이름 대신 물음을 적는다.

### 문서 수명

- **오답노트 설계 문서 셋** — superseded 표시 없이 남아 실행 지시로 읽히고, 가드는 밑줄과 하이픈 불일치로 하나도 잡지 못한다.
- **제거된 기능을 설명하는 주석** — `hooks/doc_review_posttooluse.sh:17`이 코드에 없는 제외 대상을 서술한다.

## 상충 명시

- **죽은 것의 처분** — spec 수명 발견은 배포된 spec을 지우라 하고, 오답노트 문서 발견은 지우지 말고 superseded를 붙이라 하며, DESIGN-NOTES 포인터 발견은 그 spec을 살아 있는 문서로 전제해 참조만 고치라 한다. `_scaffold_common.sh`의 죽은 함수 발견은 다시 "삭제하지 말고 표시"를 처방한다. 같은 디렉터리와 같은 종류를 가리키면서 처분이 넷으로 갈리므로 사람이 정책을 정해야 한다.
- **게이트 해제 스위치의 범위** — README에 `DISCIPLINED_CODER_REVIEW_GATE`를 게이트 해제 스위치로 적으라는 확정 발견과, 그 변수가 문서 훅까지 끈다는 결정론 발견이 같은 문자열에 서로 다른 범위를 요구한다. 앞을 먼저 반영하면 새 오해를 사용자 문서에 심는다.
- **문안 수정과 기계 앵커** — 괄호 소유권 제목 여섯을 명사구로 줄이라는 발견의 대상 둘을 `scripts/test_docs_drift.sh:118,179`가 grep 앵커로 붙들고 있다. 문안만 고치면 계약 테스트가 붉어지므로 같은 커밋에서 함께 고쳐야 한다.
- **렌즈 배정의 문서와 실행체** — `lens-adversarial`의 호출자 주장을 빼라는 확정 발견을 그대로 반영하면, 그 렌즈를 실제로 띄우는 `.claude/workflows/self-audit.js:83`이 배정 표 밖의 렌즈를 띄우는 상태로 남는다.
- **README 압축 방향** — README에 문장을 더하라는 확정 발견 여섯이 서로 방향은 같으나, 그 문서를 12,710자에서 2,555자로 줄인 직전 회차의 결정과 부딪친다. 발견 사이의 상충이 아니라 발견 묶음과 레포의 최근 결정 사이의 상충이다.

## 커버리지 공백

- **돌지 않은 렌즈** — `lens-fit`과 `lens-readability`가 이번 회차에 돌지 않았다. `lens-prior-art`는 정본이 상시 허용에서 뺀 렌즈라 공백으로 세지 않는다.
- **목적 기준 판정의 부재** — 문체 발견은 모두 `clear-comm-audit`이 낸 고정 규칙 위반이고, `lens-readability`가 요구하는 목적에 비춘 전달 방해 판정과 고쳐 쓴 문장은 이번 회차에 없다. README와 스킬 문서가 그 렌즈의 지정 대상이다.
- **결정론 발견 일곱의 검증 단계 미통과** — 확정 37건은 반박 검증을 거쳤으나, 결정론 검사가 실어 온 발견 일곱은 같은 절차를 거치지 않았다. 위 정리에 함께 실었으되 확신도가 같지 않다.
- **감사 배정 밖의 파일** — `.github/workflows/ci.yml`은 어느 렌즈 배정에도 들어 있지 않고 결정론 검사가 우연히 잡았다. 같은 종류의 파일이 더 있는지는 확인되지 않았다.
- **코드 정확성 검토** — `shell-audit`이 훅과 스캐폴드 일부를 봤을 뿐 `code-review`는 돌지 않았다. `project-doc-audit`이 문서만 본다고 규정한 범위와 이번 회차의 실제 범위가 어긋난 채로 남는다.
- **실행 환경 실측** — 맥과 리눅스에서의 스위트 실행, Codex 등록 절차, 홈 리다이렉트 PC의 동작은 모두 코드 읽기로만 다뤘고 실측이 없다.
- **집계 입력의 완전성** — 중복 제거 손실을 감지하는 장치가 없다는 확정 발견 탓에, 이번 확정 목록이 원시 발견 전부를 덮는지 이 집계로는 확인할 수 없다.
- **이 회차 기록의 배선 없음** — `self-audit.js`가 기록을 지시하지 않으므로, 이 집계 결과를 `docs/superpowers/reviews/`에 남기지 않으면 지적이 0건이었던 회차와 구별되지 않는다. 정본의 요구가 이번 회차에도 충족되지 않았음을 알린다.