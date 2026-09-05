# 첫 자기감사 회차의 뿌리 여덟을 고치는 설계

첫 자기감사 회차(`docs/superpowers/reviews/2026-09-05-self-audit-2.md`)가 확정 107건을 뿌리 아홉으로 묶었다. 그 가운데 사용자 결정으로 풀리는 하나를 뺀 여덟을 이 설계가 고친다. 방향은 소유자를 먼저 세우고, 따르는 문서가 소유자를 가리키기만 하게 하고, 마지막에 스크립트와 검사를 절차에 맞추는 것이다. 단계마다 그 단계가 깨는 검사 단언을 같은 커밋에서 고쳐 어느 단계에서 끊겨도 앞 단계가 자기완결이다.

이 문서는 2026-09-05 리뷰 둘(`docs/superpowers/reviews/2026-09-05-audit-roots-review.md`, 같은 이름 `-review-2.md`)의 발견을 반영한 판이다. 바뀐 근거는 해당 절에 적었다.

## 전제

사용자가 2026-09-05에 내린 결정 여덟이 전제다. 메모리 `audit-decisions-2026-09-05`가 정본이고 여기는 설계에 쓰이는 꼴로 옮긴다.

- spec·plan은 영구히 살아 있고 누적된다. 과거 것은 보존 목적이며 활용하지 않는다.
- 렌즈 검진은 기존 문서를 고칠 때는 사용자에게 묻고, 새 spec·plan을 처음 쓸 때는 Stop 게이트가 자동으로 강제한다. 정본 「검증」의 상시 허가는 권한이고 언제 여는지는 이 규칙이다.
- 미해결 문제는 메모리에만 둔다.
- 렌즈 이름은 `lens-` 접두사가 표준이다.
- 기각은 사유와 함께 남기고 다음 회차로 넘긴다. 같은 지문이 다시 나오면 세션은 그 사유가 여전히 성립하는지만 확인하고 기각을 유지한다.
- 절차와 스크립트가 어긋난 곳은 섞어서 맞춘다. 인용 탈락과 판정 개수는 스크립트를 늘리고, 대조 대상과 진술 목록은 이 설계가 다시 정한다.
- domain-docs의 렌즈 운용 절 넷은 새 스킬 `dispatching-lenses`로 뗀다.
- 플러그인 설치 때 물어서 `PYTHONUTF8=1`을 윈도우 사용자 환경 변수로 넣는다.

그 밖의 전제 셋이다. 이 설계의 바탕은 커밋 `b24fdfa`다. 병합 순서는 사용자가 정했고 그대로 됐다. 같은 날 다른 세션이 정본에 「Karpathy 지침」 절을 영어로 넣고 겹치던 조항 다섯(ASK-FORK·MEASURE-FIRST·SIMPLE·SURGICAL·TDD)을 이름까지 뺀 변경이 먼저 main에 들어갔고, 이 브랜치를 그 위로 옮겼다. 그 변경은 스킬 여섯과 README와 scaffold.sh 의 조항 참조를 새 절 이름으로 바꾸었으며, 이 설계가 옮기는 절 셋 안의 문장은 건드리지 않았다. 이 설계는 「Karpathy 지침」 절을 건드리지 않는다. 사라진 조항 이름은 이 문서에서도 부르지 않는다. writing-korean의 근거 수치 출처는 사용자 결정으로 이 설계 밖이다.

## 목표와 비목표

목표는 셋이다. 다음 회차의 확정 발견 가운데 이 설계가 고친 파일들 사이의 SSOT 어긋남(뿌리 여덟의 형태)이 새로 나오지 않는다. 다음 회차가 세션의 보조 스크립트 없이 저장소 스크립트만으로 탈락·대조·개수·검수를 낸다. 렌즈 운용 규율의 소유자가 하나가 된다. 회차 대조의 '해소'는 앞선 발견의 인용 문장이 파일에서 사라졌는지만 재므로 이 설계의 성공을 재는 값으로 쓰지 않는다.

비목표는 넷이다. 정본 「Extra 지침」과 그 낱말 교체를 다루지 않는다. writing-korean의 근거 수치를 다루지 않는다. 회차 기록은 봉인된 그대로 두고 고치지 않는다. 렌즈의 체크리스트 내용과 `type` 폐쇄 집합은 바꾸지 않는다.

## 1. 소유자 셋

### dispatching-lenses 스킬

새 스킬 `skills/dispatching-lenses/SKILL.md`를 만든다. 담는 것은 넷이다.

- domain-docs에서 옮겨 오는 절 셋. 「렌즈에게 정본을 알리는 법」, 「판단 앞에 기계를 세운다」, 「한 번만 띄우는 렌즈의 규율」을 문장 그대로 옮긴다. 「문서 검진 방법」 가운데 어떻게 띄우는지를 적은 문장들도 옮긴다. 첫 문단의 뒤 절반(렌즈마다 따로 띄우지 않고 호출 하나가 차례로 적용한다), '띄우기 전에 아래 「렌즈에게 정본을 알리는 법」을 먼저 본다', '렌즈는 한 번씩만 띄운다 …', '렌즈끼리 볼 것을 나눠 주지 않는다 …', '렌즈 결과는 `meta-aggregate`의 … 세 걸음으로 모은다'다. 첫 문단의 앞 절반(어느 렌즈를 거는지)과 언제 여는지를 적은 문단들은 domain-docs에 남고, 옮긴 자리에는 "띄우는 방법은 `dispatching-lenses`가 정한다" 한 문장만 둔다. domain-docs가 자기 절을 '아래 「…」'로 가리키던 문장 둘은 이 한 문장에 흡수된다. 둘째 리뷰가 첫 문단이 두 가지를 한 줄에 담고 있고 '아래' 포인터의 처리가 없다고 짚었다.
- 예외 목록. lens-adversarial은 문서별 호출과 묶지 않고 따로 띄운다. lens-prior-art는 사용자 승인 아래 통상 둘, 최대 여섯까지 띄운다. lens-consistency는 갈리는 짝 묶음을 한 호출에 주고 짝마다 원문 앞뒤 다섯 줄과 정본 표시를 함께 준다. lens-readability는 목적이 둘이면 한 호출 안에서 둘을 차례로 보고 두 번 띄우지 않는다. 앞 셋은 지금 domain-spec-review·project-doc-audit·lens-prior-art·lens-consistency에 적혀 있는 것을 여기로 모은 것이다. 넷째는 지금 lens-readability가 적은 것(두 번 돌리는 쪽을 관찰 축을 늘리는 것보다 먼저 고려한다)을 뒤집는 변경이다. 「한 번만 띄우는 렌즈의 규율」과 맞서는 문장이라 규율 쪽에 맞춘다. 이 목록이 예외 넷의 소유자이고 lens-consistency·project-doc-audit·lens-readability·domain-spec-review는 여기를 가리킨다. 둘째 리뷰가 넷째를 '모은 것'이라 적은 것과 짝 묶음 규칙이 세 파일에 놓인 것을 짚었다.
- 렌즈 이름 표준. 스키마의 `lens` 값, 기록 파일 이름, findings의 `lens` 칸이 모두 스킬 디렉터리 이름(`lens-grounding`)과 같은 한 문자열이다.
- 호출자 목록. domain-spec-review, domain-docs의 문서 검진, project-doc-audit, nested-orchestration의 L2다. domain-llm-runtime은 제품 코드가 리뷰 콜을 부르는 청사진이라 서브에이전트 규율의 호출자가 아니고 목록에 들지 않는다. 다만 그 문서가 「판단 앞에 기계를 세운다」를 이름으로 부르는 문장은 소유자를 `dispatching-lenses`로 적는다.

frontmatter의 description은 "읽기 전용 서브에이전트를 렌즈로 띄울 때 지키는 규율이다. 렌즈를 부르는 스킬이 연다"로 시작해 언제 여는지를 담는다.

옮긴 절을 이름으로 가리키던 문장은 같은 단계에서 새 소유자를 가리키게 바꾼다. 아홉 곳이다. README 「주의」("어느 경로인지는 `skills/domain-docs/SKILL.md`가 정한다"), lens-prior-art 「띄울 때 지킬 상한」(중첩 금지와 이어 묻기의 소유자), project-doc-audit 「기계가 하는 것」(「판단 앞에 기계를 세운다」의 소유자)과 「띄울 때 지킬 것」, domain-llm-runtime 조립 절(「한 번만 띄우는 렌즈의 규율」 참조)과 렌즈 선택 절(「판단 앞에 기계를 세운다」를 domain-docs 소유로 적은 문장), nested-orchestration(「렌즈에게 정본을 알리는 법」 참조), 정본 「검증」, domain-spec-review의 domain-docs 참조 셋(이 문서 밖에서 가져올 것 가운데 '렌즈에게 원칙 정본을 알리는 법과 회차 수는 domain-docs에', 「2) 디스패치」의 「한 번만 띄우는 렌즈의 규율」 소유 문장 둘, '띄우기 전에 domain-docs의 「렌즈에게 정본을 알리는 법」을 본다'), domain-docs 자신의 '아래' 포인터 둘이다. 첫 리뷰가 여섯을, 둘째 리뷰가 나머지 셋을 빠진 것으로 짚었다.

### meta-aggregate 「리뷰 산출물 계약」

계약에 넷을 더하고 하나를 지운다.

- 발견의 문턱. 발견 하나는 짚은 곳·상대편·원칙·결과 넷을 진다. 상대편을 못 대면 발견이 아니다. 줄 번호는 담지 않는다. 결과는 지금 무엇이 그렇게 되어 있는지만 적는다. 지금 렌즈 파일 넷에 같은 글자로 있는 세 문단을 여기로 옮긴다.
- 예외 하나. 「공통 계약의 예외」에 lens-readability(`suggestions`, `where`·`why`·`rewrite` 셋)는 이미 있으므로 lens-prior-art만 더한다. lens-prior-art는 `file`·`counterpart_file`·`counterpart`·`principle`이 없고 `evidence`는 인용·경로·URL이며, 인용 검증은 호출자(domain-spec-review)가 자기 도구로 한다. 둘째 리뷰가 '예외 둘을 더한다'의 개수가 실제 변경과 다르다고 짚었다.
- `where`의 뜻은 "검토 문서 안의 위치" 하나다.
- 렌즈 추가 칸에 `statements`를 올린다. 레포 문서 감사에서 문서별 호출이 돌려주는 `{topic, statement, evidence}` 목록이며 집계 대상이 아니다. 이 칸을 요구하는 주체는 project-doc-audit 「진술 받기」 걸음이다(2절). 어느 문서의 진술인지는 항목이 아니라 그 호출의 원본 파일이 안다(3절 기록 계약의 `target`).
- 「출력 스키마」의 `source` 열거를 지우고 "집계 항목의 `source`는 렌즈 리턴의 `lens` 값을 그대로 옮긴다"로 바꾼다. 렌즈 이름 열거는 「리뷰 산출물 계약」의 `lens` 하나만 남고 그 값은 `lens-grounding|lens-fit|lens-consistency|lens-adversarial|lens-prior-art|lens-readability`다. 첫 리뷰가 열거 둘 가운데 하나만 바꾸면 한 문서 안에 이름 형태가 둘 남는다고 짚었다.

### domain-docs

문서 저작만 남긴다. 기록 문단을 다시 쓴다. 이름은 `docs/superpowers/reviews/YYYY-MM-DD-<주제>-<종류>.md` 하나이고 종류는 `review`(spec·plan 리뷰), `check`(문서 검진과 워크플로 검증), `prior-art`(선행연구 대조), `audit`(레포 감사) 넷이다. 이 저장소의 레포 감사는 주제가 `self`라 `2026-09-05-self-audit-2.md`가 그대로 규칙에 맞는다. 같은 날 둘째 회차는 종류 뒤에 `-2`를 붙인다(`…-review-2.md`). 실행체 조건 문장과 2026-09-03 시작일 문장은 지우고 "이 규칙 전의 기록은 이름이 달라도 고치지 않는다"만 남긴다. 「문서 검진 방법」의 `<문서이름>`은 `<주제>`로 통일한다. 문서 검진의 기록은 요약문과 렌즈별 원본만이고 `suggestions.json`은 레포 감사의 파일이다. 이 두 문장은 첫 리뷰가 #077과 #034가 빠졌다고 짚어 더한 것이다.

그 밖에 다섯을 고친다. 「메모리의 범위」의 "공유되어야 하는 것은 git이 추적하는 문서에 둔다"를 지운다. 검진을 여는 조건을 "기존 문서 변경은 묻고, 새 spec·plan 최초 작성은 Stop 게이트가 자동으로 강제한다"로 적는다. 설계 행에 "과거 spec·plan은 보존 목적이며 활용하지 않는다"를 더한다. 외부 공개 문서의 렌즈를 「문서 검진 방법」과 같게 셋으로 맞춘다. 규범·인덱스 행의 빈 셀을 "없다. 포인터만 두므로 낡을 상태가 없다"로 채운다.

## 2. 따르는 문서

렌즈 파일 여섯은 「발견의 문턱」 세 문단과 스키마 뒤 SSOT 문단을 지우고 "필드의 뜻과 문턱과 예외는 meta-aggregate 「리뷰 산출물 계약」이 정한다" 한 문장만 남긴다. lens-adversarial의 evidence 둘째 뜻, lens-grounding의 where 좌표계, lens-prior-art의 evidence 재정의는 계약의 예외 항목으로 흡수되어 렌즈 파일에서 사라진다. lens-consistency 「레포 문서 감사에서의 짝」은 어긋남·좁혀 적기의 판정 기준만 남기고, 짝 묶음과 앞뒤 다섯 줄과 정본 표시를 주는 의무는 "소유자는 `dispatching-lenses`의 예외 목록이다" 한 문장으로 가리킨다. lens-readability는 「기계에 넘기는 것」의 고정 규칙 되풀이를 writing-korean 참조로 바꾸고, 「읽기 범위」에 정본 읽기를 포함하고, 프롬프트의 금지 표현 검색 문장을 "기계가 이미 거른 것은 다시 세지 않는다"로 바꾸며, 목적 둘로 두 번 돌리는 문장은 지우고 dispatching-lenses의 예외(한 호출 안에서 차례로)를 가리키고, `suggestions.json`은 레포 감사에서만 쓴다고 적는다.

호출자 넷은 이렇게 바뀐다.

- domain-spec-review는 lens-adversarial의 축을 넷으로 적고, 집계를 세 걸음으로 맞추고, 기록 이름 틀을 지워 domain-docs를 가리키고, 훅이 넘기는 것을 파일 이름으로 고치고, lens-adversarial 예외 문장과 domain-docs 참조 셋(1절)을 dispatching-lenses 참조로 바꾼다.
- project-doc-audit은 「띄울 때 지킬 것」의 규율 문장들을 dispatching-lenses 참조로 줄인다. 「진술 받기」는 문서별 호출 프롬프트에 `scripts/audit_topics.sh`의 이름표 목록을 넣고 `statements`를 요구한다고 적는다. 「일관성 대조」에 정본 표시와 앞뒤 다섯 줄을 주는 걸음(소유자는 dispatching-lenses 예외 목록)과 `duplication` 도출 걸음을 더한다. 걸음 표에 「회차 대조」 행을 「판정」 앞에, 「집계」와 「뿌리 찾기」 행을 「기록하고 넘긴다」 앞에 넣어 걸음을 열하나로 늘린다. 「회차 대조」는 대조 대상을 "앞선 회차 `findings.json`의 발견 전부와 앞선 `diff.json`"으로 다시 쓰고, 둘째 문단(재발마다 `derived` 발견을 새로 만든다)을 "재발은 diff.json 항목으로만 남는다"로 바꾸고, 「기계가 하는 것」의 인자를 3절대로 고친다. 「통합 기록」 findings.json 항의 '도출된 발견'과 요약문 항목의 '도출된 발견 목록'을 지운다. 「감사 대상 고르기」에 `scripts/audit_targets.sh`를 부르고 spec·plan 제외 사유를 "과거 것은 활용하지 않고 현재 것은 쓰는 시점에 리뷰를 받는다"로 고친다. 「판정」 절 마지막 문장은 "픽스처 형태는 `scripts/test_audit.sh`가, 실제 기록은 `scripts/audit_verify.sh`가 검사한다"로 고친다. 「통합 기록」은 3절의 기록 계약과 검수 주체를 적는다. 둘째 리뷰가 derived가 세 자리에 남는다고 짚었다.
- domain-llm-runtime은 결정 집합 이름을 accept·regenerate·escalate로, fit 리뷰 시점을 lens-fit 가드와 같게, grounding 출처를 요청과 맥락 하나로, SECRETS 항목에 등급을, 사람 승인 항목의 '정책'을 가리키는 문서로 바꾸고, 렌즈 하나인 호출의 집계 여부를 한 문장으로 못 박는다. 조립 절의 "띄우는 횟수는 「한 번만 띄우는 렌즈의 규율」이 소유" 문장은 "리뷰 콜은 제품 코드의 호출이라 서브에이전트 규율이 걸리지 않고 병렬로 돌릴 수 있다"로 바꾼다. 렌즈 선택 절의 「판단 앞에 기계를 세운다」 소유자를 dispatching-lenses로 적는다.
- nested-orchestration은 L2의 diff 리뷰에서 렌즈에 줄 source를 적고 「렌즈에게 정본을 알리는 법」 참조를 dispatching-lenses로 돌리며, 리포트 위치를 '프로젝트 밖' 하나로 통일하고, 「한계」의 진행 상태 문장을 spec 「검증 상태」 참조로 바꾼다.

정본은 두 줄만 바뀐다. 「검증」의 "띄우는 방법은 `domain-docs`가 정한다"가 `dispatching-lenses`를 가리키고, READ-FLOW 조항 끝에 "상세는 `writing-korean`을 참고한다"가 붙는다.

## 3. 스크립트와 기록 계약

### audit_evidence.sh

참거짓과 지문을 붙인 뒤 인용이 하나라도 없는 발견을 `findings`에서 빼어 `dropped` 배열로 옮긴다. 떨어진 것은 같은 출력 안에 남는다. lens-prior-art 갈래는 두지 않는다. 그 렌즈를 쓰는 절차(domain-spec-review)는 이 스크립트를 부르지 않는다.

### audit_rounds.sh diff

입력은 셋이다. 앞선 `findings.json`, 앞선 `diff.json`(없으면 생략), 이번 `findings.json`이다. 앞선 `findings.json` 인자가 없으면 `no_prior_round`를 참으로 놓고 `items`는 비우고 `new_ids`에 이번 발견 전부를 담는다. 있으면 앞선 발견 전부(기각 포함)와 앞선 `diff.json`이 해소라 한 항목을 대조해 항목마다 `prior_id`·`prior_round`·`prior_status`·`fingerprint`·`verdict`·`matched_id`를 낸다.

`verdict`는 셋이고 뜻은 지금 스크립트의 `alive`(앞선 발견의 인용 문장 둘이 이번 대상 파일에 지금도 있다)를 그대로 쓴다. 잔존(인용이 지금도 있다), 해소(없다), 재발(앞선 diff가 해소라 한 항목의 인용이 다시 있다)이다. `matched_id`는 이와 별개로 지문이 같은 이번 발견의 id다. 둘째 리뷰가 잔존을 '지문이 이번에도 있다'로 적은 것이 스크립트와 목표 절의 뜻과 다르다고 짚어 하나로 맞췄다.

`prior_round`는 항목의 원천을 따른다. 앞선 `findings.json`에서 온 항목은 그 파일 경로의 폴더 이름이고, 앞선 `diff.json`에서 온 항목은 그 항목의 `prior_round`를 그대로 옮긴다. 둘째 리뷰가 재발 항목에 직전 회차 이름이 잘못 붙는다고 짚었다.

재발은 diff.json 항목으로만 남기고 `derived` 발견은 만들지 않는다. 인용이 없는 발견은 `alive`가 인용 실재를 요구하므로 다음 회차에 늘 해소로 찍히기 때문이다(지문은 빈 인용에도 붙는다). 이에 따라 판정 상태의 닫힌 집합은 `confirmed`·`rejected`·`undetermined` 셋이 되고 project-doc-audit 「판정」 절의 집합 문장을 그렇게 고친다. `test_audit.sh`에는 집합 문장이 없고 그 절에서 도출하므로 고칠 것이 없다.

앞선 상태가 `rejected`이고 지문이 같으면 그 발견을 `auto_rejected` 목록에 `prior_reason`과 함께 낸다. 세션은 그 발견을 다시 판정하지 않고 사유가 여전히 성립하는지만 확인한다. 성립하면 `status: rejected`와 `verdict_reason: 앞선 회차 기각 유지 — <사유>`를 붙인다. 성립하지 않으면 `status: undetermined`와 `verdict_reason: 앞선 기각 사유 소멸 — <사유>`를 붙이고 다시 판정하지 않는다. 다음 회차가 그것을 새 발견처럼 본다. 사유가 그 회차의 실측에 기댄 것(이 회차 #003·#013)이면 확인이 판정을 대신한다. 둘째 리뷰가 확인이 거짓일 때의 처분이 없다고 짚었다.

### audit_rounds.sh metrics

입력은 이번 `findings.json`과 이번 회차가 방금 만든 `diff.json`이다. `verdict_counts`(confirmed·rejected·undetermined·auto_rejected)를 내며 앞 셋은 `findings.json`의 `status` 개수이고 `auto_rejected`는 `diff.json`의 `auto_rejected` 길이다. `resolved_rate`의 분모에서 `prior_status`가 `rejected`인 항목을 빼며 재발은 해소로 세지 않는다. tokens·seconds는 인자로 받고 run.json의 `tokens_method` 칸이 측정 방법을 적는다. `verdict_counts`의 자리는 metrics 출력 안 하나이고 run.json의 `metrics` 칸이 그 출력을 그대로 담는다. 둘째 리뷰가 자리가 둘로 적혔고 `auto_rejected` 개수의 출처가 없다고 짚었다.

### audit_statements.sh

문서별 호출이 돌려준 `statements`를 모아 이름표별 표를 세운다. 입력은 렌즈 원본 JSON 여럿이고 출력은 JSON 하나 `{ "topics": { "<이름표>": [ { "file", "statement", "evidence" } ] } }`다. `file`은 그 원본의 `target` 칸(기록 계약)에서 온다. 거르지 않고 전부 낸다. 갈리는 짝을 고르는 판단은 세션이 한다. 첫 리뷰의 상충 하나(만들지 마라 대 형태를 정하라)는 이렇게 풀었다. 묶는 계산은 회차마다 세션이 스크래치에 다시 쓰던 일이라 스크립트에 두고, 실측(이름표 40개 가운데 39개가 둘 이상 문서)에서 값을 못 내던 거르기만 뺀다.

### audit_verify.sh

실제 회차 폴더의 기록 넷과 렌즈 원본을 검수한다. `findings.json`의 `status`가 절차 문서의 닫힌 집합 안인지, 기각과 미판정에 `verdict_reason`이 있는지, 모든 발견에 `evidence_found`·`counterpart_found`가 참이고 지문이 열두 자인지, `lens` 값이 `lens-` 접두사인지, `run.json`·`diff.json`·`suggestions.json`의 필수 칸(기록 계약)이 있는지, 렌즈 원본 이름이 `lens-<이름>-<n>.json`이고 `target` 칸이 있는지를 본다. 계약에 없는 칸(이 회차 diff.json의 `note`, run.json의 최상위 `verdict_counts`)은 보지 않는다. 하나라도 어긋나면 실패 종료한다. `run.json`의 `completed`는 이 스크립트가 통과한 뒤에만 참으로 놓는다. 첫 리뷰가 '검수에서 실패한다'의 주체가 없다고 짚어 더한 것이며, 이 회차에 세션이 스크래치에 쓴 검수 스크립트가 그 원형이다.

### 기록 계약

- `findings.json` — 기각은 `findings` 안 `status: rejected`로 두고 `verdict_reason`을 필수로 한다. 발견마다 `lens`는 `lens-` 접두사 문자열 하나이고 여러 렌즈가 같은 지문을 냈으면 쉼표로 잇는다.
- `diff.json` — 필수 칸은 `schema`·`no_prior_round`·`items`·`new_ids`다. `auto_rejected`는 `no_prior_round`가 거짓일 때만 필수다. 항목은 `prior_id`·`prior_round`·`prior_status`·`fingerprint`·`verdict`·`matched_id`를 갖는다. 대조할 회차가 없으면 `no_prior_round`가 참이고 `items`가 비며 `new_ids`는 이번 발견 전부다. 이 회차 diff.json이 그 꼴이다. 둘째 리뷰가 `auto_rejected`를 늘 필수로 두면 봉인된 이 회차 기록이 검수를 통과하지 못한다고 짚었다.
- `run.json` — 필수 칸은 `tokens_method`·`lens_calls`·`subagents`·`metrics`·`completed`·`targets`다. 판정 개수는 `metrics` 안에 있다.
- `suggestions.json` — 그대로다.
- 렌즈 원본 `lens-<이름>-<n>.json` — 호출자가 저장할 때 `target` 칸(그 호출이 받은 검토 문서 경로, 저장소 전체 호출은 `.`)을 넣는다. 이 회차 원본 35개는 모두 그 칸을 갖고 있다. 둘째 리뷰가 `statements`의 문서 경로 출처가 없다고 짚었다.

## 4. 검사

검사 변경은 그것을 깨는 단계와 같은 커밋에 든다. 첫 리뷰가 검사를 마지막 단계에 몰면 앞 단계 커밋이 FAIL=0을 채울 수 없다고 짚었다. 단계마다 고칠 단언의 목록은 손으로 열거하지 않고 도출한다. 그 단계가 옮기거나 지우거나 바꾸는 문장을 계약 테스트 다섯에서 `grep`으로 찾아 만든다. 아래 열거는 이 spec을 쓴 시점에 그렇게 찾은 것이고 구현 때 다시 찾는다. 둘째 리뷰가 손 열거에서 1단계 열 개와 2단계 넷이 빠졌다고 짚었다. 단언마다 고치기 전에 빨간 불을 먼저 확인하고, 이 회차가 보여 준 실패 형태 셋(이미 통과하는 단언, 자기 픽스처 되읽기, 리터럴 하나만 겨눔)을 plan의 각 단계에 검사 항목으로 적는다.

1단계(소유자)에서 바꾸는 단언이다. domain-docs에서 옮기는 문장을 찾는 앵커를 dispatching-lenses로 돌린다. `test_docs_drift.sh`의 「한 번만 띄우는 렌즈의 규율」·「렌즈에게 정본을 알리는 법」 소유자 문장, 첫 항목 문장의 사본 금지, '렌즈는 서브에이전트를 새로 열지 않는다', '대화 턴을', '3층 오케스트레이션은 이 금지의 예외다', '렌즈는 한 번씩만 띄운다', '여기서 다시 정하지 않는다', '렌즈끼리 볼 것을 나눠 주지 않는다', 다시 쓰는 기록 문단의 '-review-2.md'와, `test_audit.sh`의 「판단 앞에 기계를 세운다」·"대상이 다르면 별개 호출이다"·'렌즈는 판단만 한다'·'새 프로젝트나 새 모델이나 새 의존이 필요하면 제안하지 않는다'·'판단이라는 사실을 산출물에 적는다'와, `test_scaffold.sh`의 domain-docs 참조 앵커다. `test_docs_drift.sh`의 개수 훑기(`COUNT_SCAN`)에 새 스킬을 넣는다. 예외 렌즈의 `consequence` 부재 단언은 "예외 항목이 없다고 적은 칸이 그 렌즈 스키마에 없다"로 바꾼다. lens-prior-art는 `consequence`를 담으므로 지금 단언대로면 깨진다. 새 단언은 넷이다. domain-docs에 렌즈 운용 절 넷의 제목이 없다. 띄우는 방법 문장(한 호출에 렌즈 여럿, source 주입, JSON 리턴, 집계)이 domain-docs에 없다. meta-aggregate의 `lens` 열거가 `skills/lens-*` 디렉터리 목록과 같고 `source` 열거는 없다(지금 `source` 줄을 읽는 검사를 `lens` 줄로 돌린다). dispatching-lenses의 예외 목록에 오른 렌즈 이름이 모두 실재한다.

2단계(따르는 문서)에서 바꾸는 단언이다. `test_audit.sh`의 렌즈 파일 「발견의 문턱」 앵커("상대편을 못 대면 발견이 아니다", '앞으로 벌어질 일을 적지 않는다')를 meta-aggregate로 돌린다. `test_audit.sh`가 domain-spec-review의 lens-adversarial 예외 문장 전체를 글자 그대로 찾는 단언과 project-doc-audit의 '저장소 전체를 입력으로 따로 한 번 띄운다' 단언은 dispatching-lenses의 예외 목록을 겨누게 바꾼다. `test_docs_drift.sh`의 domain-llm-runtime 앵커 둘('여기서 다시 정하지 않는다', '렌즈는 한 번씩만 부른다')은 "리뷰 콜은 제품 코드의 호출이라 서브에이전트 규율이 걸리지 않는다"를 찾게 바꾼다. `KO_NUM`을 '열하나' 이상으로 늘린다. 지금은 '열'까지만 알아 행 수 단언이 0과 11을 맞대게 된다. 새 단언은 넷이다. 「발견의 문턱」 첫 문장("발견 하나는 넷을 진다")이 렌즈 파일 여섯 어디에도 없다. 렌즈 파일 여섯의 출력 스키마 `lens` 값이 자기 디렉터리 이름과 같다. project-doc-audit 걸음 표 행 수와 "걸음은 열하나" 문장이 맞는다. project-doc-audit 어디에도 `derived`가 없다.

3단계(스크립트)에서 바꾸는 단언이다. `test_audit.sh` 픽스처를 새 계약으로 바꾼다. 인용 없는 발견이 `dropped`로 옮겨진다. 앞선 기각과 같은 지문이면 `auto_rejected`에 사유가 붙는다. 앞선 diff가 해소라 한 항목의 인용이 다시 나오면 `verdict`가 재발이고 `prior_round`는 그 항목의 것을 승계한다. 앞선 findings 인자가 없으면 `no_prior_round`가 참이고 `auto_rejected`가 없어도 검수를 지난다. metrics가 `verdict_counts`를 내고 `auto_rejected`가 diff의 길이와 같고 해소율 분모에 기각이 없다. `audit_statements.sh`가 위 JSON 꼴을 내고 `file`이 원본의 `target`이다. `audit_verify.sh`가 사유 없는 기각과 `target` 없는 원본을 실패로 낸다. 판정 집합 문장에서 `derived`가 사라진다.

4단계(README·CLAUDE.md·writing-korean)에서 바꾸는 단언이다. `test_hooks.sh`에 "README 「하드 게이트와 넛지와 전역 설정 수정」이 `hooks/hooks.json`과 `.claude/settings.json`에 배선된 스크립트 파일 이름 전부를 담는다"를 더하고 목록은 두 파일에서 도출한다. `test_docs_drift.sh`에 "CLAUDE.md에 '쓰면 Stop 게이트가'가 '새로' 없이 나오지 않는다"를 더한다. 첫 리뷰가 원래 단언('새로 쓰면'이 있다)은 이미 통과한다고, 둘째 리뷰가 단언이 놓일 파일이 없다고 짚었다. writing-korean 「고칠 순서」 사본 삭제로 lens-readability를 겨누는 단언이 깨지는지는 위 도출로 확인한다.

5단계(세션 시작 알림 통로와 PYTHONUTF8)에서 바꾸는 단언이다. `test_scaffold.sh`의 "missing source warns to stderr"와 자동 갱신 실패 사유를 stderr에서 읽는 단언 넷(`ERR_D`·`ERR_E`의 '깨진 설정을 조용히 넘기지 않는다'·'읽기 실패는 읽기 실패라고 말한다'·'쓰기 실패에 자리가 따로 있다'·'쓰기 실패를 읽기 실패로 안 부른다')을 stdout 단언으로 바꾼다. 실패 사유가 "자동 갱신을 켰다" 머리말 아래 섞이지 않는다는 단언을 더한다. `PYTHONUTF8` 안내 단언은 OS 판정과 변수 값을 픽스처로 고정한다. scaffold.sh가 판정을 함수 하나에 두고 테스트 전용 환경 변수로 그 결과를 주입받으므로, 단언은 '없다'로 주입한 첫 회차에 줄이 나고 '있다'로 주입하면 나지 않는다를 본다. 계약 테스트는 ubuntu-latest CI에서도 돌므로 실제 OS와 레지스트리에 기대지 않는다. '2nd run sends nothing'·'CRLF: sends nothing'은 그대로 통과해야 한다. 안내 줄이 첫 회차(정본이 갱신된 세션)에만 나기 때문이다. 둘째 리뷰가 단언 넷과 빈 출력 단언 둘과 CI 조건이 빠졌다고 짚었다.

## 5. 세션 시작 알림 통로, 훅 목록, writing-korean, PYTHONUTF8

`scripts/_ensure_autoupdate.sh`는 그대로 둔다. 그 함수는 실패 사유를 stderr에 찍고 모든 갈래에서 0으로 끝나므로 종료 코드는 통로가 아니다. `scripts/scaffold.sh`가 함수의 stderr를 임시 파일로 받아 "자동 갱신을 켰다" 머리말과 바뀐 파일 목록을 찍은 뒤 그 줄들을 stdout으로 옮긴다. 함수의 stdout은 바뀐 파일 목록을 돌려주는 반환 통로라 거기 섞으면 머리말 아래 거짓 통지가 된다. 둘째 리뷰가 앞 판의 '종료 코드를 받아'가 실재하지 않는 통로라고 짚었다. 정본 복사 실패와 `@import` 배선 실패의 ERROR도 stdout으로 옮긴다. 종료 코드는 그대로다(정본 복사 실패 1, 그 밖 0). README 「동작 확인과 복구」와 commands 둘은 "세션 시작 알림에 `ERROR`나 `WARNING` 줄이 없으면 정상이고 확인은 `/show-principles`로 한다"를 적는다. 정상 회차에도 정본 전문·자동 갱신 알림·카파시 권유가 stdout으로 나가므로 '출력이 없으면'이 아니라 '오류 줄이 없으면'이다. show-principles의 안내 문구는 원인을 확정하지 않는 문장("원칙 사본이 없다. 새 세션을 열거나 `/setup-discipline`을 실행하라")으로 바꾼다. `scripts/seal_reviews.sh`의 `mapfile`은 `while read`로 바꾼다.

`PYTHONUTF8`은 이렇게 넣는다. 읽는 저장소는 윈도우 사용자 환경 변수의 레지스트리(`HKCU\Environment`, `reg query`)다. 프로세스 환경을 읽으면 `/setup-discipline`이 넣은 뒤에도 호스트를 다시 열기 전까지 '비어 있다'가 남아 안내와 물음이 되풀이된다. scaffold.sh는 정본이 새로 깔리거나 갱신된 세션(카파시 권유와 같은 조건)에 그 값이 비어 있으면 "파이썬 한국어 깨짐을 막으려면 /setup-discipline 을 실행하라" 한 줄을 stdout으로 낸다. 매 세션 뜨는 줄은 알림 전체를 흘려보게 만들므로 다른 넛지와 같은 조건에 묶는다. OS 판정과 레지스트리 읽기는 함수 하나에 두고 테스트 전용 환경 변수로 결과를 주입받는다(4절 5단계). `/setup-discipline` 명령은 같은 저장소를 읽어 비어 있으면 선택지로 묻고 승인 시 `[Environment]::SetEnvironmentVariable('PYTHONUTF8','1','User')`로 넣으며 결과를 알린다. 되돌리기는 변수 삭제다. domain-plugin 「사용자 설정 파일을 고칠 때 지킬 것」에 "OS 환경 변수는 물어서 넣고 이미 값이 있으면 건드리지 않는다"를 더한다. 둘째 리뷰가 읽는 저장소와 반복 조건이 없다고 짚었다.

README의 훅 절은 훅마다 스크립트 파일 이름과 이벤트(SessionStart·PreToolUse·PostToolUse·Stop)를 적고 배선 파일 둘을 모두 든다. `hooks/hooks.json`은 플러그인 훅이고 `.claude/settings.json`은 이 레포의 프로젝트 훅이다. 봉인 시점은 "커밋된 기록은 세션 시작에 `seal_reviews.sh`가, 회차 기록은 회차 끝에 호출자가" 둘을 함께 적는다. CLAUDE.md는 셋째 문단의 "spec과 plan을 쓰면"을 "새로 쓰면"으로, 넛지 예외(리뷰 기록과 프로젝트 밖 문서)를 한 줄로 적는다.

writing-korean은 대구 규칙의 단위를 "글 한 편(답 하나 또는 문서 하나)"으로, '것' 규칙의 범위를 "대상을 가리키는 '것'에만"으로 못 박고, 「고칠 순서」 문단의 사본을 lens-readability에서 지워 이쪽을 가리키게 한다.

## 순서와 되돌리기

단계는 0단계 하나와 커밋 단계 다섯이다. 0단계는 다른 세션의 커밋 위로 rebase 하고 충돌을 푸는 것이며 커밋을 새로 만들지 않는다(전제 절). 커밋 단계는 단계마다 커밋 하나다. 소유자 셋과 포인터 재지정(1절), 따르는 문서(2절), 스크립트와 기록 계약(3절), README·CLAUDE.md·writing-korean(5절의 뒤 둘), 세션 시작 알림 통로와 PYTHONUTF8(5절의 앞 둘)이다. 단계끼리 겹치는 파일은 둘이다. README는 1단계(「주의」 포인터)·4단계(훅 절)·5단계(「동작 확인과 복구」)에, lens-readability는 2단계(계약·프롬프트·예외 참조)·4단계(「고칠 순서」 사본 삭제)에 걸린다. 같은 파일의 다른 덩이라 커밋 단위 되돌리기는 충돌 없이 되고, 그 밖의 파일은 단계마다 갈린다. 둘째 리뷰가 앞 판의 '파일이 겹치지 않아'가 거짓이라고 짚었다. 각 단계는 그 단계가 깨는 검사 단언을 같은 커밋에서 고치고(4절), 단계 끝에 계약 테스트 다섯과 `claude plugin validate ./`를 돌려 FAIL=0을 확인한다.

## 성공 기준

- 계약 테스트 다섯이 단계마다 FAIL=0이고, 새 단언은 모두 빨간 불을 거쳐 초록이 된다.
- domain-docs에 띄우는 방법 문장(한 호출에 렌즈 여럿, source 주입, JSON 리턴, 집계)과 렌즈 운용 절 넷의 제목이 없고, 그 문장과 제목은 dispatching-lenses에 있다. 줄 수는 기준으로 쓰지 않는다. 옮기는 문장은 23줄이고 domain-docs에 더하는 문장도 있어 앞 판의 '75 아래'는 한 줄 차이로 거짓이었다.
- 렌즈 파일 여섯에 「발견의 문턱」 문장이 없고 meta-aggregate에 렌즈 이름 열거가 하나다.
- 이 회차 기록을 앞선 회차로 넣어 `audit_rounds.sh diff`를 돌리면 항목 118이 나오고 기각 9건이 `prior_status: rejected`로 나오며, `audit_verify.sh`가 이 회차 폴더를 고치지 않은 채 통과시킨다.
- 다음 감사 회차의 확정 발견에 이 설계가 고친 파일들 사이의 SSOT 어긋남이 새로 나오지 않는다. 이것은 다음 회차가 확인한다.

## 위험

- 다른 세션의 미커밋 변경이 이 설계가 고치는 스킬 넷과 정본을 함께 만진다. 그 변경이 먼저 들어가고 이쪽이 rebase 뒤 충돌을 푼다(전제 절). 구현 세션이 시작할 때 그 변경이 커밋되어 있지 않으면 구현을 시작하지 않고 사용자에게 알려 순서를 다시 정한다.
- `lens` 값을 접두사 형태로 통일하면 2026-09-05-self-audit 이전 회차의 원본 JSON(짧은 이름을 쓴 것)과 형태가 갈린다. 2026-09-05-self-audit-2의 원본은 이미 접두사 형태다. 기록은 고치지 않으므로 대조 스크립트는 지문으로만 맞대고 `lens` 값은 세지 않는다.
- 자동 기각은 지문이 같을 때만 걸리고 세션이 사유 성립을 확인한다. 짚은 문장이 한 글자만 바뀌어도 새 발견이 되어 세션이 다시 판정한다. 의도한 보수성이다.

<!-- spec-review: passed -->
