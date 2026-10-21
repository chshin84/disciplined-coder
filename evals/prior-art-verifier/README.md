# 선행연구 검증자 설정 선택 시험

이 폴더는 일회성 시험 기록이다. 설계는 `docs/superpowers/specs/2026-10-20-prior-art-verifier-tiering-design.md`, 절차는 `docs/superpowers/plans/2026-10-21-prior-art-verifier-tiering-selection.md` 에 있다. 검사는 `bash evals/prior-art-verifier/run_tests.sh` 로 실행한다. 이 검사는 저장소의 `scripts/test_*.sh` 일괄 실행에 들지 않는다.

## 자료

`cases.json` 은 `build_cases.py` 가 만든다. 원본은 2026-10-20 선행연구 실행(`wf_8cadf2c0-63d`)의 기록 폴더 `D:\projects\dc-clause-candidates\docs\superpowers\reviews\2026-10-20-generation-constraints-prior-art\` 다.

- 참 항목은 그 실행에서 오케스트레이터가 원문을 직접 연 출처에서 골랐다.
- 오류 항목은 참 항목을 카테고리마다 정한 방식으로 고쳐 만들었다.
- 항목마다 확인 내용은 `check_note` 에 있다.
- 주장 문장은 모두 이슈 항목 형식(선행 사례 서술 한 문장)으로 썼다. 근거 지도 행 형식(`{ case, outcome, prior }`)은 지도 대조 자료에서만 쓴다.

항목 형식은 `{ id, category, url, claim: { ref, text }, truth, check_note }` 이고, 지도 대조 자료는 `{ id, input: { evidence_map, passed }, truth: [{ row, column, grounded }] }` 다.

카테고리 코드는 접근=`access`, 존재=`exists`, 구절=`quote`, 수치·조건=`numbers_conditions`, 방향=`direction`, 범위=`scope`, 지도 대조=`map` 이다.

## 실행 명령

```bash
python -I evals/prior-art-verifier/run.py --stage <baseline-cite|baseline-map|extract|judge|map> --model <ID> --effort <low|medium|high> [--category <코드>] [--extract-from <경로>] [--repeat <n>]
python -I evals/prior-art-verifier/score.py report
```

## 실행 조건

이 PC 에는 API 키 파일이 없어 `--bare` 를 쓸 수 없다. 모든 실행에 `--setting-sources "" --strict-mcp-config --disable-slash-commands --no-session-persistence` 를 붙이고, 실행 폴더는 `scripts/_eval_env.sh` 의 `eval_tmpdir` 과 같은 규칙(기본 `D:/dc-eval-tmp`, 상위 경로에 CLAUDE.md 가 있으면 실패)으로 `run.py` 가 만든다. 실제로 실린 지시는 2026-10-21 첫 실제 실행에서 확인했다.

- 같은 플래그와 `D:/dc-eval-tmp` 아래 폴더에서 Haiku 5.5 low 에 "CLAUDE.md 나 메모리 파일에서 온 내용이 있는가"를 물었더니 "없음"이라고 답했다.
- 그 실행의 캐시 쓰기 토큰은 3,129 였다. 전역 CLAUDE.md(디시플린코더 원칙과 금지어 목록)가 실렸다면 이보다 훨씬 크다.
- arXiv 2605.10039 하나로 추출 단계를 Haiku 5.5 low 로 실행했다(`fixtures/extract-sample.jsonl`). `error` 는 비었고, `total_cost_usd` 는 0.00741839, `modelUsage` 키는 `claude-haiku-5-5` 였다. `access` 는 `성공` 이었고, `quote` 에 원문의 부정어("None of ...")가 그대로 담겼다.
