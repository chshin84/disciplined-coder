# 한국어 AI 투 퇴고 스킬 설계 리뷰

- 대상: `docs/superpowers/specs/2026-11-24-korean-polish-skill-design.md`
- 실행한 렌즈: `lens-grounding`(spec), `lens-adversarial`(design). 렌즈를 한 번씩만 실행했다.
- 렌즈 원본: `2026-11-24-korean-polish-skill-review/lens-grounding-1.json`, `lens-adversarial-1.json`. 에이전트 출력 파일이 비어 있어 메인 세션이 받은 보고 본문에서 옮겼다.
- 커버리지 공백: `lens-grounding` 은 셸 도구가 없어 `D:\projects\dc-neonb` 의 `scripts/test_docs_drift.sh` 를 실행하지 못했다. 메인 세션은 같은 날 그 검사의 실패 7건을 직접 실행해 확인했다.
- 옛 렌즈 비교: 실행하지 않았다. 짧은 spec 하나라 현행 렌즈 둘로 충분하다고 메인 세션이 판단했다.
- 선행연구: 실행하지 않았다. 같은 날 `2026-11-24-ai-tell-polish-prior-art` 로 이미 실행했다.
- 지적 수: lens-grounding 9, lens-adversarial 14. 합친 뒤 22건(모델 규칙 모순 1건이 두 렌즈에서 겹침, 길이 기준값 1건이 두 렌즈에서 겹침으로 21건 처분 행).
- 기각 수: 0.
- 사용자에게 올린 항목: 2건.
- 다시 리뷰: 하지 않았다. 남은 지적이 사용자 확인 사항 두 건뿐이다.
- Fable p 값(v2.7 0.12, v2.8 0.40, v2.12 0.60)은 `%USERPROFILE%\.dc-eval\fable-judge\rejudge.py report` 출력으로 메인 세션이 확인했다(0.118524, 0.400653, 0.597841).

| 지적 | source | 위치 | 처분 | 기각 근거 |
|---|---|---|---|---|
| CLAUDE.md 「원칙 작업의 생성과 판정은 Opus 5.5 만」과 Neon 생성·Fable 판정이 충돌 | lens-adversarial, lens-grounding | 시험 절, 절차 표 | 사용자 | - |
| 채택 기준과 비용 제안 규칙을 적지 않음 | lens-adversarial | 시험 절 | 반영 | - |
| 다른 프로젝트에서는 재현 시험 도구가 없음 | lens-adversarial | 절차 6단계, 시험 절 | 반영 | - |
| 불변 요소 안의 금지어와 금지어 0건 관문이 충돌 | lens-adversarial | 관문 표 | 반영 | - |
| 재요청 4회 뒤 처리 없음 | lens-adversarial | 절차 5단계 | 반영 | - |
| 2단계 「여기서 끝낸다」와 5·6단계 모순 | lens-adversarial | 절차 표 | 반영 | - |
| 103%·4회 근거 없음, 길이 비교 대상 미정, v2.9 는 100%·4,000자 | lens-adversarial, lens-grounding | 관문 표 | 반영 | - |
| 적대적 퇴고의 문장·조건 누락을 잡는 관문 없음 | lens-adversarial | 범위 표, 관문 표 | 반영 | - |
| 판독 전 원본 덮어쓰기 | lens-adversarial | 절차 6단계 | 반영 | - |
| 사내 업무 내용이 외부로 나감, 자리 표시 뒤 조사 | lens-adversarial | 외부 전송 절 | 사용자 | - |
| store=false 에서 4단계 문맥 없음 | lens-adversarial | 절차 4단계 | 반영 | - |
| 측정 스크립트·금지어 목록 위치 미정 | lens-adversarial | 관문 절 | 반영 | - |
| 발동마다 재현 시험 비용 승인 없음 | lens-adversarial | 발동 절, 시험 절 | 반영 | - |
| 원문 다듬기·본문 다듬기·퇴고 용어 혼동 | lens-adversarial | 관문 절, 남은 확인 | 반영 | - |
| Fable p 값 세 개가 메모리에 없음 | lens-grounding | 근거 표 | 반영 | - |
| rw5 지시문 인용 글자 불일치 | lens-grounding | 절차 절 | 반영 | - |
| 두 지시문이 지시문을 전제해 사람이 읽는 산출물에 그대로 못 씀 | lens-grounding | 범위 표, 절차 절 | 반영 | - |
| `[[...]]` 링크를 스크립트가 측정하지 않음 | lens-grounding | 관문 표 | 반영 | - |
| 스크립트는 줄었는지만 보는데 spec 은 같다고 적음 | lens-grounding | 관문 표 | 반영 | - |
| 찾기·고치기 모델을 사용자 결정으로 적음(원문은 질문) | lens-grounding | 사용자 결정 절 | 반영 | - |
| 원문 전문 방식이 핵심이라는 일반화(Fable v2.10 반례) | lens-grounding | 근거 절 | 반영 | - |

메인 세션이 리뷰 중 추가로 확인한 사항: v2.9 원문 다듬기는 저장소 문서와 요구사항 정리를 먼저 읽힌 대화에서 실행했고(`rw3/rw.py` `base_blob`), 2026-11-24 본문 다듬기(`bodies2.py`)는 그 맥락 없이 실행했다. spec 근거 절과 남은 확인에 반영했다.
