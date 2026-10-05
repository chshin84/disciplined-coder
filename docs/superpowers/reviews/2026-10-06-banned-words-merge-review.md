# 금지어 목록 원본 이전 설계 리뷰

검토 대상은 `docs/superpowers/specs/2026-10-06-banned-words-merge-design.md` 다. 훅이 넘긴 경로가
`docs/superpowers/specs` 아래이므로 spec 으로 판정했다. 렌즈는 `lens-grounding`·`lens-consistency`·
`lens-adversarial`·`lens-fit` 을 Explore 에이전트로 하나씩 실행했다. 렌즈를 한 번씩만 실행했다. 원본 JSON 은
같은 이름의 폴더에 있다.

선행연구 렌즈는 제안하지 않았다. 이 spec 은 이미 하던 일(금지어 목록 관리)의 저장 위치와 형식을 정리하는
것이고, 되는지 자체가 미지수인 일이 아니다.

메인 세션은 지적마다 근거 줄을 열어 확인했다. `scripts/check_banned_words.sh:44`, `README.md:3`,
`hooks/_spec_marker.sh:65`, `skills/lens-readability/domain-korean.md:302·335`, `scripts/test_docs_drift.sh:855·857`,
`hooks/_banned_words.sh:32·35·51` 이 지적대로 적혀 있었다. 틀린 근거로 버린 지적은 없다.

## 병합한 지적

| 지적 | 잡은 렌즈 |
|---|---|
| `check_banned_words.sh` 가 버전 표시를 읽으므로 "읽는 코드가 없다"는 주장이 틀렸다 | grounding · consistency · adversarial |
| 파싱 검사가 `banned_parse` 출력만 보아 형식이 틀린 행(칸 부족, 제외 칸 소실, 표 중간 `#` 줄)을 잡지 못한다 | consistency · adversarial |
| `validate.py` 가 보던 금지어 중복과 제외어의 어간 포함 검사를 대신할 검사가 없다 | adversarial |
| main 이 보호되지 않아 형식이 틀린 표가 CI 보고 전에 모든 PC 로 배포될 수 있다 | adversarial |
| 생성물 문장을 지우면 사본을 고치지 말라는 표시가 사라진다 | adversarial |
| 근거 대응 검사가 한 방향만 보고 꺼 둔 항목과 규칙 불릿을 대조하지 않는다 | consistency · adversarial |
| 목록을 고치는 규칙을 근거 파일에 두면 지시와 근거가 섞이고 세션에 실리지 않는다 | fit · adversarial |
| 기준선 규칙이 기각 후보·중복으로 끈 항목과 이미 꺼진 user 항목 `기대를 걸` 을 설명하지 못하고, 어간·빈도 측정 규칙이 빠졌다 | consistency |
| 근거 파일이 대구 한도 검사와 `check_banned_words.sh` 측정 대상에 들어가 원문 인용이 걸린다 | consistency · adversarial |
| 근거 보존 확인이 「고치는 규칙」 절 때문에 75 대 76으로 어긋난다 | grounding · consistency · adversarial |
| README 3행, domain-korean 302·335행, `_spec_marker.sh` 65-66행, `test_docs_drift.sh` 855행 주석, `check_banned_words.sh` 37행이 고칠 목록과 grep 에서 빠졌다 | grounding · consistency · fit |
| 확인용 grep 이 '생성물'을 빼서 고칠 목록 grep 과 범위가 다르다 | consistency |
| 근거 종류에 `reasoned` 가 빠졌다 | grounding |
| 형식 계약에 셋째 칸(적용 대상)이 빠졌다 | grounding |
| 목록 파일 1.15만 자는 바이트 수이고 글자 수는 5,966자다 | grounding |
| writing-html-reports `common.py` 는 칸 다섯 미만 행을 건너뛰고, `~/.claude/kw-ax/` 경로는 kw 사본 삭제 뒤 쓰이지 않는다 | adversarial |
| 받기 워크플로 삭제와 옛 저장소 동결 사이에 옛 저장소 변경이 사라질 공백이 있다 | adversarial |
| 문체: 확인 주체 누락, 옛·외부·원본 저장소 혼용, kw 이름 풀이 없음, 불릿 말끝과 길이, 단락 길이, 개수 예고 | fit |

## 커버리지 공백

네 렌즈가 모두 결과를 돌려주었다. 렌즈가 스스로 확인하지 못했다고 적은 것은 아래와 같다.

- `stop_gates.sh` 와 `doc_word_posttooluse.sh` 가 파서 실패에 어떻게 반응하는지는 adversarial 이 직접 읽지 않았다.
- kw-plugins 가 각 PC 의 `~/.claude/kw-ax/korean-banned-words.md` 파일까지 지우는지는 확인하지 못했다.
- kw 세션의 답과 사용자 결정은 메시지로만 받아 파일로 대조하지 못했다.

## 렌즈가 덧붙인 관찰

목록 파일의 `담` 행 제외 칸에 한자가 섞인 `담合` 이 있다. 이전과 무관한 기존 데이터다.
