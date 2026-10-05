# 금지어 목록 원본을 이 저장소로 옮기기 — 설계

이 설계는 2026-10-06에 썼다. 금지 표현 목록 `korean-banned-words.md` 는 이미 이 저장소 루트에 있고, 내용은 옛
저장소가 만든 생성물과 같다. 이 설계는 그 파일을 원본으로 바꾸고, 옛 저장소를 가리키던 동기화와 문장을 걷어 낸다.
같은 날 spec 리뷰(`docs/superpowers/reviews/2026-10-06-banned-words-merge-review.md`)와 plan 리뷰
(`…-merge-plan-review.md`)를 거쳤고, 무엇이 왜 바뀌었는지는 「경위」에 적는다.

## 용어

- **목록 파일:** 저장소 루트의 `korean-banned-words.md` 다. 훅이 파싱하고, `scaffold.sh` 가
  `~/.claude/disciplined-coder/` 에 복사하며, 관리블록이 그 사본을 `@import` 로 싣는다.
- **근거 파일:** 이 설계가 새로 만드는 `docs/korean-banned-words-evidence.md` 다. 세션에 싣지 않는다.
- **옛 저장소:** `KiwoomAX/korean-banned-words` 다. 지금의 원본 JSON 이 있고, 마지막 커밋은 `5b02378` 이다.
- **kw-plugins:** 사내 플러그인 마켓플레이스 저장소 `KiwoomAX/kw-plugins` 다. 그 안의 `kw-control-tower` 가 지금
  목록 사본을 받아 간다. 이 저장소를 맡은 Claude 세션을 kw-plugins 세션이라 부른다.

## 바꾸는 이유

사용자는 관리 지점을 줄이려고 통합을 정했다(2026-10-05). 지금은 목록 한 항목을 고치면 옛 저장소에 PR 을 열고,
이 저장소의 `banned-words-sync.yml` 이 하루 한 번 생성물을 받아 다시 PR 을 연다.

옛 저장소를 따로 둔 이유는 이 저장소와 kw-control-tower 가 같은 목록을 각자 받아 갔기 때문이다. kw-plugins
세션은 2026-10-05에 kw-control-tower 가 이 플러그인을 필수 플러그인으로 포함하고 자기 받기 워크플로와 사본을
지운다고 답했다. 그러면 목록을 소비하는 저장소는 이 저장소 하나만 남는다.

사용자는 2026-10-06에 원본을 JSON 대신 마크다운으로 두기로 정했다. 소비자가 하나면 생성 단계와 버전 표시가
필요 없고, 목록 파일을 손으로 고치면 된다. 같은 날 옛 저장소를 삭제하기로 정했다.

## 설계

### 목록 파일

표와 표로 적을 수 없는 규칙과 "꺼 둔 항목" 줄은 그대로 둔다. 첫 줄 `# 한국어 금지어 목록` 도 그대로 둔다.
`scripts/test_scaffold.sh` 42행이 그 줄로 사본이 실렸는지 확인하기 때문이다.

머리의 생성물 문장과 HTML 주석 세 줄(원본·다시 만들기·원본 버전)은 아래 안내로 바꾼다. 목록 파일은 사본으로
모든 PC 에 실리므로, 사본을 고치지 말라는 표시와 원본 위치를 저장소 이름과 함께 적는다.

> 이 목록의 원본은 `chshin84/disciplined-coder` 저장소 루트의 `korean-banned-words.md` 다.
> `~/.claude/disciplined-coder/` 의 사본은 `scaffold.sh` 가 세션마다 원본으로 덮어쓰므로 사본을 고치지 않는다.
> 항목마다의 근거는 같은 저장소의 `docs/korean-banned-words-evidence.md` 에 있다.

표 설명 문단 끝의 "각 항목의 근거는 https://github.com/KiwoomAX/… 에 있다"는 머리 안내와 겹치므로 지운다.
"꺼 둔 항목" 줄의 "왜 껐는지는 원본이 적는다"는 "근거 파일이 적는다"로 고친다.

### 근거 파일

옛 JSON 의 `entries` 와 `rules` 에서 근거를 한 번 변환해 `docs/korean-banned-words-evidence.md` 로 둔다. 금지어
항목은 첫 금지어를 백틱으로 감싼 `##` 절이고, 규칙은 `## 규칙:` 으로 시작하는 절이다. 절 본문에는 분류, 켜짐
여부, 근거 종류(사용자 지시·측정·추론), 날짜, 원문 인용을 적는다. 꺼 둔 항목은 끈 사유와 다시 켤 때의 표 칸도
적는다. 사용자 원문 인용은 고쳐 쓰지 않는다.

근거 파일을 `docs/` 에 두는 이유는 사용자가 루트를 세션에 실리는 파일로만 두고 싶어 했기 때문이다(2026-10-06).
목록 파일과 근거 파일의 대응은 검사하지 않는다. 변환 스크립트는 scratchpad 에서 실행하고 커밋하지 않는다.

근거 파일은 사용자 원문을 인용하므로 금지어와 대구를 포함한다. 그래서 대구 한도 검사(`test_docs_drift.sh` 의
`ANTI_DOCS`)와 `check_banned_words.sh` 측정 대상에서 목록 파일과 함께 뺀다.

### 동기화와 검사 정리

- **받기 워크플로:** `.github/workflows/banned-words-sync.yml` 을 지운다.
- **문서 검사:** `test_docs_drift.sh` 금지 표현 절에서 생성물 표시, 옛 저장소 이름, 받기 워크플로를 보는 검사를 지우고 목록 파일과 근거 파일이 있는지만 본다.
- **측정 스크립트:** `check_banned_words.sh` 44-45행의 버전 표시 출력을 지운다.

### 옛 원본을 전제한 문장

아래 문장은 옛 저장소나 동기화나 생성물이라는 성격을 지금의 사실로 적는다. 각각 목록 파일과 근거 파일을
가리키게 고친다.

- `README.md` 3행의 "사내 저장소를 목록의 원본으로 가리킨다"
- `skills/lens-readability/domain-korean.md` 「금지 표현의 근거」 첫 문단과 301-302행과 335행
- `skills/lens-fit/domain-discipline.md` `EDIT-DISCIPLINE` 절의 목록 파일 예시(279-280행)
- `hooks/_banned_words.sh` 2-3행과 `hooks/doc_word_pretooluse.sh` 37-38행 주석
- `hooks/_spec_marker.sh` 65-66행 `path_in_own_repo` 주석의 "표를 외부 저장소가 소유하고 하루 한 번 동기화"
- `scripts/check_banned_words.sh` 37행과 `scripts/test_docs_drift.sh` 855행의 제외 사유 주석

README 41·80행은 목록 사본을 싣는 방식만 설명하고 옛 저장소를 말하지 않으므로 고치지 않는다.
`agent-principles.md` 의 `EDIT-DISCIPLINE` 예시 "이 파일은 생성물이다"는 일반 예시라 고치지 않는다.

### 이 저장소 밖의 일

옛 저장소 삭제는 사용자 지시에 따라 kw-plugins 세션이 맡는다. 삭제는 이 저장소의 이전 커밋이 main 에 들어간 뒤에
한다. 이 저장소는 병합 뒤 커밋 해시를 kw-plugins 세션에 알리고, 그 알림이 삭제를 진행해도 된다는 신호다. 같은
메시지에 옛 저장소의 `import-protocol.md` 를 쓰는 곳이 없다는 추정도 알린다. 메인 세션은 이 저장소의
`scaffold.sh` 가 공용 블록을 지운다는 사실에서 그렇게 추정했다.

삭제하면 옛 저장소의 커밋 이력과 URL 이 사라지고, 이 저장소 기록에 남은 링크는 깨진다. 기록은 고치지 않는다.
항목별 근거는 근거 파일로 옮겨지므로 남는다.

writing-html-reports 의 `checks/common.py` 는 `~/.claude/kw-ax/korean-banned-words.md` 를 대체 경로로 읽는다.
kw-control-tower 가 사본을 지우면 이 경로는 쓰이지 않는다. 이 저장소는 그 경로를 고치지 않고 writing-html-reports
세션에 알린다.

이 PC의 Claude 메모리 `dc-banned-words-check-off` 는 결정의 이유로 "외부 저장소가 목록을 소유한다"를 든다.
결정은 유지하고 이유 문장만 고친다.

## 확인 방법

- **이전 시점:** 변환 직전에 옛 저장소 HEAD 가 `5b02378` 이고 그 `dist/korean-banned-words.md` 가 목록 파일과 같다.
- **표 불변:** 이전 전과 뒤의 목록 파일 `git diff` 에서 `` | ` `` 로 시작하는 표 행이 바뀌지 않는다.
- **근거 보존:** 근거 파일의 백틱 `##` 제목 수와 `## 규칙:` 제목 수가 옛 JSON 의 항목 수와 규칙 수와 같다.
- **남은 참조:** `grep -rn "KiwoomAX/korean-banned-words\|banned-words-sync\|생성물\|외부 저장소\|사내 저장소"` 의
  결과가 `docs/superpowers/` 기록, 근거 파일, `agent-principles.md` 의 일반 예시에만 남는다.
- **계약 테스트:** 저장소 `CLAUDE.md` 「변경 뒤 실행」 명령이 `ALL PASS` 를 내고, `claude plugin validate ./`
  가 `version` 경고만 낸다.

## 경위

첫 문안은 JSON 과 `render.py` 를 옮겼다. 사용자가 마크다운으로 충분하다고 해 두 번째 문안은 목록 파일을 원본으로
두었다. 이 문안은 spec 리뷰 지적에 따라 행 형식·제외어·중복·근거 대응 검사와 `.claude/rules/` 편집 규칙 파일을
추가했다. plan 리뷰 중에 사용자가 "단순히 마크다운을 가져오는 것으로 끝 아니냐"고 지적했고(2026-10-06), 그
검사들과 편집 규칙 파일을 뺐다. 손편집으로 표 형식이 틀릴 위험은 spec 리뷰 기록에 남아 있다.

<!-- spec-review: escalated -->
