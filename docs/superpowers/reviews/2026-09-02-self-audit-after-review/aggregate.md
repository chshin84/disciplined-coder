## 1. 전체 판정

이 회차의 결과는 HEAD f301689의 건강 상태가 아니라 감사 도중에도 계속 바뀐 작업 트리의 판정이다. 결정론 검사 넷 가운데 둘이 빨갛고(test_docs_drift 1건, test_scaffold 2건) 세 실패 전부가 커밋되지 않은 정본 한 편집에서 나오며, 확정 발견 41건 가운데 넷(ASK-FORK 문구 소실, 금지 표현, CLEAR-COMM 매달림, 작업 트리 갈라짐)과 실행체 결함 하나(리비전 미고정)가 같은 편집과 그 이동에서 나왔다. 나머지 36건은 HEAD에도 있는 결함이며 SSOT 드리프트가 가장 많고 PROSE-FORM 형태, 죽은 코드, 조용한 실패, superseded 누락이 그 뒤를 잇는다. 검증 단계는 렌즈 여덟이 모두 응답했고 미판정이 없어 렌즈 집합 자체의 공백은 없으나, 감사 대상이 움직였으므로 최종 작업 트리에 대한 판정은 아직 없다. 지금 상태로는 커밋할 수 없고, 첫 걸음은 정본 편집이 의도였는지를 사용자가 정하는 것이다 — 그 답 하나에 검사 셋의 실패, self-audit.js의 원칙 ID, 금지 표현 셋, lens-prior-art의 새 모순이 함께 걸려 있다. 확정 발견끼리 정면으로 갈린 상충은 한 쌍(대시 소제목 관례)뿐이고, 나머지는 같은 자리를 다른 방향에서 고치라는 겹침이라 한 편집으로 묶어야 한다.

## 2. 확정 발견 정리

### 사용자 결정이 필요한 것

- **정본 조항 개정의 의도 여부** — 작업 트리의 agent-principles.md는 머리말을 두 줄로 줄이고 ASK-FORK를 짧은 옛 문안으로 바꾸고 CLEAR-COMM을 지워 어느 커밋에도 없던 EXPLAIN-STRUCTURE로 옮겼다. 이 편집에서 test_scaffold의 ASK-FORK 검사 둘과 test_docs_drift의 금지 표현 검사가 실패하고, self-audit.js:26이 정본에 없는 CLEAR-COMM을 부르며, domain-spec-review:129·domain-docs:89가 정본에서 사라진 「갈림길 규칙」을 가리킨다. 금지 표현은 8행 '경우'·9행 '부분'에 더해 검증자가 찾은 16행 NAME-ITEMS의 '경우'까지 셋이다. 같은 미커밋 묶음에 lens-prior-art:7(「spec이 없어도 연다」)과 :57(「spec 리뷰 전용」)의 새 모순도 들어 있다. 개정이 의도이면 근거를 커밋 메시지에 남기고 하류(검사 스크립트·스킬 두 곳·self-audit.js)를 같은 커밋에서 맞추고, 의도가 아니면 정본만 되살리고 Codex 제거 변경만 남긴다.
- **대시 소제목 관례의 존폐** — 「검증 — LLM 단독 출력을 그대로 마치지 않는다」 제목과 writing-korean의 소제목 셋(금지 표현·KO-SYNTAX·PROSE-FORM)을 명사구로 바꾸라는 확정 발견 둘이, 같은 꼴을 스물한 곳의 지배적 관례로 보고 부분 수정을 거부한 기각 발견과 갈린다. 관례를 폐기해 전부 고칠지, 관례를 예외 조항으로 적고 확정 둘을 접을지는 사용자가 정한다.
- **전문 용어 부연 횟수의 값** — writing-korean 24행 「처음 나올 때 한 줄」과 113행 「나올 때마다」가 같은 문서 안에서 반대이고, 정본 READ-FLOW(HEAD 포함 최근 네 커밋 모두)는 「나올 때마다」, lens-readability:73과 설치본 사본은 「처음 나올 때」다. 한 값을 정한 뒤 writing-korean만 값을 갖고 정본과 렌즈는 횟수를 적지 않고 가리키게 한다.
- **미룬 일의 집** — 정본 56행은 「꼭 남겨야 하는 것」을 메모리로, domain-docs 74행은 같은 것을 진짜 트래커로 보낸다. 검증자는 2026-06-30 설계에서 사용자가 정한 원래 구분(작업노트는 메모리, must-keep 백로그는 트래커)이 정본 재작성 때 사라졌다고 짚었으므로, 정본 56행의 트리거를 작업노트로 되돌리는 쪽이 기록된 결정과 맞는다. 정본 조항이라 사용자 확인이 필요하다.
- **「검증」 절의 소유권과 예외** — 세 호출자 스킬이 「검증」 절에서 가져온다는 공통 방법(PREP→렌즈→집계→라우팅)이 그 절에 없고 절은 다시 호출자 스킬을 가리켜 소유자가 0곳이며, 검증자는 실제 소유자가 domain-spec-review(PREP)와 meta-aggregate(처분)이므로 포인터 셋과 domain-docs:79 제목만 고치면 된다고 좁혔다. 같은 절의 기록 의무(렌즈 둘 이상이면 reviews/에 남긴다)는 nested-orchestration의 실행 국면 렌즈 회차에 예외 없이 걸리는데 그 회차는 스크래치 리포트로만 남는다. 정본에 예외를 적을지 워크트리의 reviews/에 기록을 쓰게 할지는 사용자가 정한다.
- **Codex spec·plan 삭제의 되돌림** — 두 문서가 superseded 표시 없이 스테이징 삭제되어 있고, 이는 domain-docs 설계 행의 처방과 issue-mode·ultracode 선례 둘 다에서 벗어난다. 되살려 superseded 머리말을 붙이는 것이 규칙이지만 이 세션이 스스로 스테이징한 삭제를 뒤집는 것이라 확인이 필요하다. 검증자는 처방 가운데 SCAFFOLD_STALE에 codex를 넣는 쪽은 변수의 뜻과 어긋나므로 test_docs_drift.sh:212의 도출 범위를 넓히는 쪽을 택하라고 했다.

### 그 밖의 확정 발견

**README와 매니페스트의 문안** — README「세션에 강제하거나 고치는 것」은 hooks.json에 배선된 PreToolUse·PostToolUse 넛지 셋을 빠뜨리고 끄기 변수의 범위를 Stop 게이트 하나로 좁혀 적는다. README:18은 /show-principles 실패의 원인을 홈 불일치 하나로 단정하지만 두 소비자가 같은 resolve_home을 쓰므로 그 원인은 그 증상을 만들 수 없고, 실제 원인들은 stderr에만 남는다. README:40과 domain-spec-review:13의 「하드 게이트」는 같은 스킬 144행의 「턴당 한 번의 환기」와 모순이며 코드는 둘째 종료 시도와 git 밖에서 조용히 통과시킨다. README:40과 CLAUDE.md:6은 게이트 경로·마커·환경변수 이름을 코드에서 베껴 적었는데 드리프트 검사는 domain-spec-review 한 파일만 대조한다. autoUpdate 규칙은 스크립트 머리말·domain-plugin·README 세 곳에 각각 전체가 적혀 있고 라벨 개수부터 다르다. plugin.json과 marketplace.json의 「doc review gates」는 훅 자신이 「게이트 아님」이라 선언한 넛지를 게이트로 광고하고, 두 매니페스트의 description을 같게 두라는 규칙은 domain-plugin에 없고 테스트 주석에만 산다.

**훅** — 문서 넛지 훅 둘은 프로젝트 밖의 메모리·플랜 파일에도 걸려 훅 자신이 적어 둔 피로 기전이 실제로 발동한다(세션 기록에서 실측). spec_review_stop.sh:39는 spec/plan 디렉터리 목록을 술어 SSOT와 별개로 pathspec에 한 번 더 적고, 두 spec 훅은 같은 안내문을 각자 문자열로 갖고 있으며 드리프트 검사가 그 문구가 두 곳에 있기를 요구해 베끼기를 강제한다. 같은 Stop 훅은 문서화된 FAIL-OPEN 범위(git 부재·비-git 디렉터리) 밖의 git 실패(dubious ownership·인덱스 손상)에서도 아무 신호 없이 게이트를 연다 — 검증자는 비-git 갈래는 지금처럼 조용히 두고 그 밖의 실패에만 systemMessage를 내라고 좁혔다.

**스크립트** — _json_valid.sh의 json_hook_events는 같은 일을 하는 처리기 셋을 두고 그 사본이 이미 갈라져 있으며, 같은 파일 주석은 사라진 둘째 배선 파일(Codex)을 가리킨다. 파이썬 인터프리터 선택이 네 사본으로 흩어져 있고 test_hooks.sh:216과 test_scaffold.sh:112는 폴백 없이 맨 `python`을 부른다. scaffold.sh:51(발견은 480행으로 잘못 적음)은 프로젝트 CLAUDE.md와 전역 CLAUDE.md의 동일성을 문자열로만 비교해 작업 폴더가 ~/.claude이면 매 세션 사본이 쌓인다(재현됨). test_scaffold.sh에는 단언 없는 블록 넷과 상수 둘이, _scaffold_common.sh에는 호출자 없는 함수 둘과 지워진 상수를 설명하는 주석이 solved_problems 걷어내기의 껍데기로 남아 있고 test_assertions.sh의 두 휴리스틱 사이 틈에 놓여 초록이다. _resolve_home.sh의 USERPROFILE 갈래는 어떤 검사도 밟지 않아 변이체에서도 PASS=222 FAIL=0이다.

**스킬 문서의 계약** — domain-docs의 기록 타입 행은 처분을 안 적는다고 못 박는데 같은 문서의 검진 절과 실제 -check 기록은 처분을 적는다. 회차 표기가 `-review-2.md`와 `-2-check.md`로 갈리고 두 문서에는 회차 규칙이 없으며 reviews/에는 규칙 밖의 `-recheck.md`까지 섞여 있다. domain-docs:7이 frontmatter 형식의 소유자로 가리키는 domain-plugin에 frontmatter 규칙이 한 줄도 없어 test_scaffold.sh:329와 test_docs_drift.sh:420이 어느 문서에도 없는 규칙을 강제한다. self-audit.js의 FINDINGS_SCHEMA는 meta-aggregate가 SSOT라 선언한 계약과 다른 필드 집합이라 렌즈가 채운 `read`·`principles_applied`·`notes`가 버려진다.

**PROSE-FORM 형태** — 정본 원칙 목록의 괄호 이름이 문장·명사구·부사구로 갈리고, domain-docs 문서 타입 표의 '담는 것' 열은 기록 행만 절이며, domain-plugin 첫 목록과 domain-docs의 규칙 목록·README 목록은 문장 라벨 하나가 명사 라벨 사이에 섞여 있고, lens-prior-art와 lens-readability의 표 머리는 의문절이다. nested-orchestration의 BLOCKED 목록은 검증자가 근거 조항을 「말끝 통일」에서 「같은 종류의 항목만 불릿」으로 바로잡았다.

**문서 superseded** — 오답노트 기능의 spec 둘과 plan 하나가 superseded 없이 남아 plan 머리의 태스크 실행 지시가 오독될 수 있고, 검사의 파일 이름 대조(*solved_problems*)가 이 셋을 훑지 않는다.

**자기감사 실행체** — self-audit.js는 감사 대상 리비전을 고정하지 않아 이번 회차에서 렌즈와 검증자가 서로 다른 시점의 파일을 읽었다. 검증자는 워크트리 체크아웃이 미커밋 감사라는 현재 용례와 충돌하므로 시작·종료 시 HEAD SHA와 `git status --porcelain` 지문을 남기고 달라지면 크게 알리는 형태를 권했다.

## 3. 상충

**정면 상충은 한 쌍이다.** 「검증」 절 제목과 writing-korean 소제목 셋을 명사구로 고치라는 확정 발견 둘(clear-comm-audit)과, 같은 「이름 — 설명절」 꼴을 렌즈 셋·domain-docs에서 지적했다가 기각된 발견의 사유가 정면으로 갈린다. 기각 사유는 이 꼴이 정본·writing-korean·2026-08-27 기록이 인정한 지배적 관례이고 다섯 곳만 고치면 「복제된 관례의 부분 수정」이 된다는 것이었는데, 확정 둘을 그대로 고치면 정확히 그 상태가 된다. 검증 단계가 같은 모양에 반대 판정을 냈으므로 escalate 후보다.

**같은 자리를 다른 방향에서 고치라는 겹침은 여덟이다.** 한 편집으로 묶지 않으면 앞 발견의 고침이 뒤 발견의 대상을 없애거나 되살린다.

- README:38-41은 넛지 항목 추가와 변수 범위 확장(훅 목록 발견), 하드 게이트 문구 완화(게이트 발견), 리터럴 제거(복제 발견) 셋이 겹친다. 복제 발견의 둘째 선택지(드리프트 대조 대상에 README를 넣는다)를 택하면 셋이 양립하고, 첫째 선택지(리터럴 제거)를 택하면 변수 설명을 넓히라는 발견과 부딪힌다.
- _json_valid.sh:18-25는 세 갈래를 한 프로그램 문자열로 합치기, json_field 헬퍼 추가, 함수를 grep 한 줄로 대체하고 걷어내기 셋이 겹친다. 걷어내면 앞 둘의 대상이 사라진다.
- 매니페스트 description은 문구를 두 파일에서 함께 고치라는 발견과, 마켓플레이스 항목에서 description을 아예 빼는 것이 더 나은 SSOT 처방일 수 있다는 검증자 소견이 겹친다.
- 「검증」 절은 제목 축약, 공통 방법 포인터 수정, 3층 실행 국면 예외 추가 셋이 같은 절을 편집한다.
- domain-docs 기록 행은 처분 규칙을 두 갈래로 가르는 편집과 기록 파일 이름 규칙을 넣는 편집이 같은 행에 든다.
- test_docs_drift.sh:212의 superseded 도출은 codex 발견과 solved-log 발견이 각각 넓히라 하므로 한 변경이어야 한다.
- test_scaffold.sh의 단언 없는 블록과 _scaffold_common.sh의 호출자 없는 함수는 같은 기능의 껍데기라 한 처분이다.
- self-audit.js는 스키마 정렬, CLEAR-COMM ID 교체, 리비전 지문 셋이 한 파일에 든다.

**검증자끼리의 증거 상충이 하나 있다.** json_hook_events 발견에서 첫째 검증자는 이 PC의 python3가 3.12.10으로 살아 있어 python 갈래가 죽은 사본이라 했고, 둘째 검증자는 python3가 스토어 스텁(rc=49)이라 python3·node 갈래가 죽은 사본이라 했다. 발견은 확정으로 유지되나 어느 갈래가 한 번도 안 도는 사본인지가 반대로 적혀 있어, 처방의 「실측한 뒤 없앤다」 대상이 정해지지 않았다. 인터프리터 선택 발견의 검증자도 CI 러너에 `python`이 있는지 증거가 없다고 적었으므로 환경 사실 자체가 고정되지 않은 상태다.

## 4. 커버리지 공백

**최종 작업 트리에 대한 판정이 없다.** 정본의 mtime이 감사 중 22:42→22:50→22:53→23:10으로 움직였고 `git diff HEAD --stat`도 35/1220에서 41/1226으로 벌어졌다. 렌즈의 인용과 검증자의 읽기가 다른 판본을 봤으므로, 정본이 멈춘 뒤 결정론 검사 넷과 grounding 렌즈를 한 번 더 돌려야 이 회차의 발견이 그 판본에도 성립하는지 알 수 있다.

**검증자 소견에만 드러나고 어느 발견에도 실리지 않은 결함이 아홉이다.** 자기감사 워크플로가 기각 발견을 제목만 남기고 검증자 소견을 결과에서 떨어뜨리므로 이 부류는 구조적으로 사라진다 — 워크플로 자체의 공백이다.

- CI는 actions/checkout 기본 fetch-depth=1이라 `git log --since`에 기대는 기록 불변 검사가 CI에서 비활성이다.
- CI는 test_docs_drift가 실패하면 test_hooks·test_scaffold를 돌리지 않아 CLAUDE.md가 정한 「실패를 모아 마지막에 알리는」 루프와 다르다.
- project-solved-pointer spec·plan 한 쌍도 superseded 없이 남아 있다.
- 정본 16행 NAME-ITEMS의 「순서가 없는 경우」가 금지 표현 발견의 처방에서 빠져 있다.
- _ensure_autoupdate.sh:65-68에 인터프리터 선택 사본이 하나 더 있다.
- lens-adversarial:15 「짚은 것은 고칠 줄과 절을 가리킨다」는 이름 없는 순수 문장 소제목이라 대시 관례에도 들지 않는다.
- 설치본 사본의 READ-FLOW는 795357c 이전 값으로 낡아 정본과 사본이 세 판본으로 갈라져 있다(결정론 단계도 같은 사실을 적었다).
- _scaffold_common.sh의 죽은 코드는 2026-08-31·09-01 감사가 이미 확정했는데 f301689가 손대지 않아 재발했다.
- scaffold.sh:82의 「이 세션에는 원칙이 실리지 않는다」는 코드와 어긋나는 문구다(had_import=0이면 stdout으로 정본이 실린다).

**돌리지 않은 렌즈가 둘이다.** lens-readability는 README·commands처럼 사람이 처음부터 끝까지 읽는 문서가 대상인데 이번 회차는 clear-comm-audit이 PROSE-FORM 형태만 봤고 목적 대비 판정과 `rewrite`는 없다. lens-fit은 훅이 세션에 주입하는 안내문(SessionStart stdout·넛지 additionalContext)이 소비자 계약을 지키는지 볼 렌즈인데 아무도 안 봤다. lens-prior-art는 규칙에 따라 뺐다.

**범위 밖에 미완 리뷰가 하나 있다.** 미커밋 spec `docs/superpowers/specs/2026-09-02-audit-record-and-diff-design.md`와 그 리뷰 폴더는 docs/superpowers/ 제외 규칙으로 이번 감사 대상이 아니었고, 메모리 기록에 따르면 그 spec 리뷰는 합치기·기록·마커·🔴 보고가 남아 있다. 기록 의무 발견의 검증자가 「레포가 reviews/를 봉인해 감사 흔적으로 쓰는 설계를 진행 중」이라고 그 spec을 인용했으므로, 이번 회차의 처분 가운데 reviews/ 이름 규칙과 기록 굳는 시점은 그 spec과 함께 정해야 한다.