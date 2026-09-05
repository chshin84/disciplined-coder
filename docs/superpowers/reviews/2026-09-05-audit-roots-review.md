# spec 리뷰 — 2026-09-05-audit-roots-design

검토 대상은 `docs/superpowers/specs/2026-09-05-audit-roots-design.md`(커밋 c18007b)다. 렌즈 셋을 호출 둘로 돌렸다. lens-grounding과 lens-consistency는 한 호출, lens-adversarial은 따로다. 렌즈를 한 번씩만 돌렸다. 원본은 같은 이름 폴더의 `lens-grounding-1.json`(11건), `lens-consistency-1.json`(8건), `lens-adversarial-1.json`(16건)이다. 발견 35건을 합치니 같은 자리를 짚은 것이 있어 스물하나가 된다.

## 선행연구 렌즈

spec으로 판정했다(경로가 `docs/superpowers/specs`). 제안하지 않았다. 이 spec은 이미 있는 문서와 스크립트를 재배치하고 맞추는 일이라 발동 기준(해본 적 없는 것을 해내려 하고 그것이 되는지가 미지수)에 걸리지 않는다.

## 합친 발견

둘 이상의 렌즈가 함께 잡은 것은 앞에 렌즈 이름을 둘 적었다. 근거로 든 문장 가운데 판정을 가르는 넷(드리프트 검사가 `"source"` 줄을 읽는 것, test_scaffold.sh의 stderr 단언, scaffold.sh가 자동 갱신 함수의 stdout을 반환 통로로 쓰는 것, CLAUDE.md에 '새로 쓰면'이 이미 있는 것)은 파일을 열어 확인했다.

- **grounding·adversarial·consistency — 검사 변경을 4단계에 몰아 두어 1~3단계 커밋이 FAIL=0을 채울 수 없다.** test_docs_drift.sh·test_audit.sh·test_scaffold.sh가 domain-docs의 절 제목과 렌즈 파일의 「발견의 문턱」 문장과 diff의 기각 건너뛰기를 앵커로 단언한다. 단계마다 그 단계가 깨는 단언을 같은 커밋에서 고쳐야 한다.
- **grounding·adversarial — 4절 일곱째 단언은 고치기 전에 이미 통과한다.** CLAUDE.md 다섯째 줄에 '새로 쓰면'이 있고 고칠 대상은 일곱째 줄의 '쓰면 Stop 게이트가'다.
- **grounding — test_scaffold.sh의 stderr 단언을 바꾸는 걸음이 없다.** WARNING을 stdout으로 옮기면 그 단언이 실패한다.
- **grounding·adversarial — '출력이 없으면 정상'은 거짓이다.** 정상 회차에도 정본 전문·자동 갱신 알림·카파시 권유가 stdout으로 나간다.
- **adversarial — 자동 갱신 함수의 stdout은 반환 통로다.** 그 안에서 WARNING을 stdout으로 옮기면 바뀐 파일 목록에 섞여 '켰다'는 거짓 통지가 된다.
- **grounding — 3절이 대조 대상을 다시 정하는데 2절이 project-doc-audit 「회차 대조」와 「기계가 하는 것」을 고치지 않는다.**
- **adversarial — 걸음 표에 「회차 대조」 행이 없어 자동 기각이 판정 뒤에 붙는다.** 이 회차 steps_done에도 대조 걸음이 없다.
- **grounding·adversarial — meta-aggregate에 렌즈 이름 열거가 둘(`lens`·`source`)인데 spec은 앞쪽만 바꾸고 검사는 뒤쪽을 읽는다.**
- **grounding — 목표 첫째와 성공 기준 다섯째의 '해소'는 문장이 바뀌었는지만 재는 값이다.**
- **grounding — diff.json 계약('나머지는 비어 있다')이 이 회차 diff.json(new_ids 118)과 어긋난다.**
- **grounding — 호출자 목록의 domain-llm-runtime은 렌즈 콜을 병렬로 돌리는 코드 청사진이라 서브에이전트 규율의 호출자가 아니다.** 2절은 그 병렬 문장과 domain-docs 참조를 고치지 않는다.
- **grounding — 기록 이름 종류 넷을 정하면서 워크플로 검증 기록의 종류(#077)와 문서 검진의 suggestions.json(#034)을 다루지 않는다.**
- **grounding·adversarial — 옮긴 절을 가리키는 README 「주의」, lens-prior-art, project-doc-audit 「기계가 하는 것」, domain-llm-runtime, nested-orchestration의 문장을 다시 가리키는 걸음이 없다.**
- **consistency·adversarial — 1절은 lens-prior-art 발견에 `principle`이 없다고 정하고 3절은 그 칸으로 지문을 만들라 한다.** 부르는 절차도 없는 갈래다.
- **consistency·adversarial — 성공 기준 둘째('렌즈·검진 낱말이 한 문단에만 남는다', '70줄 아래')는 1절을 다 이행해도 거짓이다.** 옮기는 줄은 24이고 남는 줄은 74이며, 외부 공개 문서 항목과 기록 문단이 렌즈 낱말을 담는다.
- **consistency·adversarial — '검수에서 실패한다'의 검수를 실제 기록에 돌리는 스크립트와 주체가 없다.** 이름 붙은 검사는 픽스처만 본다.
- **consistency — 4절 여섯째 단언(스크립트 파일 이름 전부)과 5절의 README 변경(배선 파일과 이벤트 이름)이 맞지 않는다.**
- **consistency — audit_statements.sh의 출력 형태가 없다.** adversarial은 같은 항목을 과설계로 짚었다. 이름표 40개 가운데 39개가 둘 이상 문서의 진술이라 거르는 것이 하나다.
- **adversarial — `statements`를 돌려줄 주체가 없다.** 렌즈 프롬프트와 「진술 받기」 걸음 어디에도 그 칸을 요구하는 문장이 없다.
- **adversarial — derived 발견은 인용이 없어 지문이 같고 다음 회차에 늘 해소로 찍힌다.** 재발 추적이 한 회차에서 끊긴다.
- **adversarial — 자동 기각은 지문 일치만 보는데 이 회차 기각 둘(#003·#013)의 사유는 그 회차의 실측에 기댄다.**
- **adversarial — 해소율 분모에 기각이 들어가 상한이 109/118로 내려간다.**
- **consistency — 5절의 일 셋은 1~4절과 파일이 겹치지 않는 독립된 일인데 한 커밋열에 묶였다.**
- **adversarial — 다른 세션과의 병합 순서가 정해져 있지 않다.** 위험 완화가 '먼저 커밋되면'에만 걸려 있고, READ-FLOW 조항은 다른 세션이 바꾼 세 조항의 이웃이다.

## 집계

상충 하나다. consistency는 audit_statements.sh의 출력 형태를 정하라 하고 adversarial은 그 스크립트를 만들지 말라 한다. 같은 항목을 두고 방향이 반대다.

커버리지 공백은 둘이다. lens-fit은 spec 리뷰 묶음이 아니라 돌지 않았다. lens-prior-art는 위 판정대로 제안하지 않았다. 렌즈들이 루트 밖이라 열지 않은 것은 다른 세션의 미커밋 변경과 정본의 「Extra 지침」이며, adversarial만 메모리 파일을 루트 밖에서 열었다고 스스로 적었다.

adversarial이 확인 못 했다고 적은 것 하나는 호출자가 확인했다. 문서 양식 넛지 훅(`hooks/doc_format_pretooluse.sh`)이 인용하는 domain-docs 절은 「글 유형별 적용」이라 spec이 옮기는 절 넷에 들지 않고, test_hooks.sh는 이 변경에 걸리지 않는다.

adversarial이 spec 「위험」 둘째 항의 전제(옛 회차 원본 JSON이 짧은 이름을 쓴다)가 이 회차에서 거짓임을 적었다. 이 회차 원본은 이미 `lens-` 접두사다.
