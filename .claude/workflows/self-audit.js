export const meta = {
  name: 'self-audit',
  description: 'disciplined-coder 저장소를 자기 원칙·자기 리뷰어 렌즈로 자기검증한다',
  whenToUse: '큰 변경(정본·훅·스캐폴드 수정) 후 회귀 감사가 필요할 때, 레포 루트에서 실행한다(다른 위치면 args로 레포 경로를 넘긴다). 결과는 확정 발견 목록과 집계 판정이다.',
  phases: [
    { title: '테스트', detail: '테스트 스크립트 전부 + plugin validate 실행 (FAIL=0 계약)' },
    { title: '리뷰', detail: '자기 리뷰어 스킬과 원칙 차원 렌즈를 병렬로 감사한다 (개수는 REVIEWERS 배열이 정본)' },
    { title: '중복제거', detail: '렌즈 간 중복 발견 병합' },
    { title: '반박검증', detail: '발견별 사실성·실질성 2관점 반박 (불확실하면 기각, 표가 모자라면 미판정)' },
    { title: '집계', detail: 'meta-aggregate 방식 구조 건강성 점검 + 최종 정리' },
  ],
}

// 레포 경로는 하드코딩하지 않는다(레포 정본은 어느 클론에서도 동작해야 한다 — EXPLICIT).
// 기본값 '.'은 "레포 루트에서 실행"을 전제하고, 다른 위치면 args로 절대 경로를 넘긴다.
const REPO = (typeof args === 'string' && args.length > 0) ? args : '.'

const FINDINGS_SCHEMA = {
  type: 'object',
  properties: {
    findings: {
      type: 'array',
      items: {
        type: 'object',
        properties: {
          title: { type: 'string', description: '발견 제목 — 완결된 문장으로 (CLEAR-COMM)' },
          file: { type: 'string', description: '증거 파일 경로 (file:line 형식 권장)' },
          evidence: { type: 'string', description: '실제 파일에서 인용한 증거 텍스트' },
          principle: { type: 'string', description: '위반/관련 원칙 ID 또는 렌즈 규칙' },
          consequence: { type: 'string', description: '이대로 두면 무엇이 어떻게 잘못되는가 — 구체적으로 못 적는 발견은 올리지 않는다' },
          detail: { type: 'string', description: '왜 위반인지 — 근거를 완결된 문장으로 설명' },
          fix: { type: 'string', description: '제안하는 수정 방향 (선택)' },
        },
        required: ['title', 'file', 'evidence', 'principle', 'consequence', 'detail'],
      },
    },
  },
  required: ['findings'],
}

const VERDICT_SCHEMA = {
  type: 'object',
  properties: {
    isReal: { type: 'boolean', description: '반박에 실패했으면(=발견이 실재하면) true. 불확실하면 false.' },
    reason: { type: 'string', description: '판정 근거 한두 문장' },
  },
  required: ['isReal', 'reason'],
}

const TEST_SCHEMA = {
  type: 'object',
  properties: {
    allPassed: { type: 'boolean' },
    results: {
      type: 'array',
      items: {
        type: 'object',
        properties: {
          name: { type: 'string' },
          passed: { type: 'boolean' },
          summary: { type: 'string', description: 'PASS/FAIL 카운트와 실패 시 실패 내용' },
        },
        required: ['name', 'passed', 'summary'],
      },
    },
  },
  required: ['allPassed', 'results'],
}

const COMMON = `너는 disciplined-coder 플러그인 저장소(${REPO})를 감사하는 읽기 전용 리뷰어다.
이 저장소는 그 플러그인 자체의 소스다 — 플러그인이 남에게 강제하는 원칙을 자기 자신이 지키는지 검증한다.
먼저 ${REPO}/agent-principles.md (원칙 정본·규칙서)를 읽어라.
규칙: (1) 파일을 직접 읽고 실제 인용을 증거로 제시하라 — 추측 금지. (2) 어떤 파일도 수정하지 마라.
(3) solved_problems.md에 직접 쓰지 마라 — 발견은 구조화 리턴으로만 보고한다(메인 세션이 취합한다).
(4) 발견은 최대 10건 — 확신 높은 순으로. 없으면 빈 배열이 정직한 답이다.
(5) 각 발견의 title과 detail은 완결된 문장으로 쓴다.`

const REVIEWERS = [
  { key: 'lens-grounding', prompt: `${COMMON}
렌즈: ${REPO}/skills/reviewer-grounding/SKILL.md 를 읽고 그대로 적용하라. 검토 대상: README.md, CLAUDE.md, agent-principles.md, domains-index.md, commands/*.md. source(진실): scripts/*.sh, hooks/*, skills/*/SKILL.md, .claude-plugin/*. 문서가 주장하는 동작이 실제 코드에 근거하는지 — 누락·모순·환각을 찾아라.` },
  { key: 'lens-consistency', prompt: `${COMMON}
렌즈: ${REPO}/skills/reviewer-consistency/SKILL.md 를 읽고 그대로 적용하라. 검토 대상: agent-principles.md, domains-index.md, README.md, CLAUDE.md, skills/*/SKILL.md 상호간(reviewer-*·meta-aggregate 포함). 내부 모순, 커버리지 공백, 이름/참조 드리프트를 찾아라.` },
  { key: 'lens-adversarial', prompt: `${COMMON}
렌즈: ${REPO}/skills/reviewer-adversarial/SKILL.md 를 읽고 그대로 적용하라(가드 포함: 기능 추가 제안 금지·근거 필수). 검토 대상: 절차 네 절(검증 레이어, 설계 입력, 오답노트, 문서·상태 위생)과 hooks/·scripts/·skills/ 설계 전체. 실패 모드, 과설계·YAGNI, 비가역, 자기모순을 공격적으로 찾아라.` },
  { key: 'ssot-audit', prompt: `${COMMON}
차원: SSOT 전수 조사 — agent-principles.md ↔ skills ↔ scripts ↔ hooks ↔ README ↔ CLAUDE.md ↔ commands 사이의 권위 있는 이중 기술(손 동기화 쌍)을 찾아라. 정당한 참조/도출은 위반이 아니다.` },
  { key: 'shell-audit', prompt: `${COMMON}
차원: 셸 코드 품질 — scripts/*.sh 전부, hooks/*.sh, hooks/*.json, hooks/session-start-codex. FAIL-LOUD(오류 삼킴), IDEMPOTENT(재실행 안전 — 코드로 추적), EXPLICIT, 테스트 매직 넘버, Git Bash 홈 리다이렉트 함정. 실제 코드 라인을 인용하라.` },
  { key: 'clear-comm-audit', prompt: `${COMMON}
차원: PROSE-FORM 자기준수 — agent-principles.md, skills/*/SKILL.md 전부(reviewer-*·meta-aggregate 포함), commands/*.md, README.md, domains-index.md. 산문과 표에서 명사 조각 종결, 기호 문장(X = Y, 원인 → 해결)을 찾아라. 원칙 정의 안의 '나쁜 예' 인용문과 코드 블록·필드 스키마 표기는 위반이 아니다.` },
  { key: 'plugin-compliance', prompt: `${COMMON}
차원: domain-plugin 자기준수 — ${REPO}/skills/domain-plugin/SKILL.md 를 읽고, .claude-plugin/*, .codex-plugin/*, hooks/hooks*.json, commands/·skills/ frontmatter가 그 처방을 지키는지 감사하라. 스킬의 주장 자체가 실측과 다르면 그것도 발견이다(MEASURE-FIRST).` },
  { key: 'docs-compliance', prompt: `${COMMON}
차원: domain-docs 자기준수 — ${REPO}/skills/domain-docs/SKILL.md 를 읽고, docs/ 전체·README·CLAUDE.md가 타입별 처방(상태 금지·도출 우선·수명 규칙)을 지키는지 감사하라. solved_problems는 append-only 예외이고, spec/plan은 superpowers 소유라 현행 문서와의 드리프트만 본다.` },
]

phase('테스트')
const testPromise = agent(
  `${COMMON}
너만 예외적으로 실행 권한이 있다(파일 수정은 여전히 금지). ${REPO} 에서 다음을 실행하고 결과를 보고하라:
- scripts/test_*.sh 를 전부. 목록도 실행 명령도 여기 적지 않는다 — ${REPO}/CLAUDE.md 가 그 명령의 정본이니 그 파일을 읽고 거기 적힌 형태 그대로 돌려라. 앞 스크립트의 실패가 마지막 스크립트의 종료 코드에 묻히는 형태로 바꿔 쓰지 마라.
- claude plugin validate ./ (non-strict)
어떤 스크립트를 실제로 돌렸는지 이름을 모두 보고에 적어라. 하나도 못 찾았으면 그 사실 자체가 FAIL이다.
각각 PASS/FAIL 카운트와, FAIL이 있으면 어떤 체크가 왜 실패했는지 출력에서 인용하라. 계약은 FAIL=0이다.
환경 원인(도구 부재 등)으로 보이는 실패는 그 사실 자체를 보고하라(수정 시도 금지).`,
  { label: 'run-tests', phase: '테스트', schema: TEST_SCHEMA }
)

phase('리뷰')
// 죽은 렌즈와 깨끗한 렌즈를 구별한다 — 빈 배열로 뭉개면 감사가 조용히 좁아진 것을 아무도 모른다(FAIL-LOUD).
const deadLenses = []
const reviews = await parallel(
  REVIEWERS.map(r => () =>
    agent(r.prompt, { label: r.key, phase: '리뷰', schema: FINDINGS_SCHEMA })
      .then(res => {
        if (!res) { deadLenses.push(r.key); return [] }
        return res.findings.map(f => ({ ...f, lens: r.key }))
      })
      .catch(() => { deadLenses.push(r.key); return [] })
  )
)
const all = reviews.filter(Boolean).flat()
log(`리뷰 완료: ${REVIEWERS.length}개 렌즈에서 원시 발견 ${all.length}건`)
if (deadLenses.length > 0) log(`⚠️ 응답하지 않은 렌즈 ${deadLenses.length}개: ${deadLenses.join(', ')} — 이 감사의 커버리지가 그만큼 좁다`)

phase('중복제거')
let deduped = all
if (all.length > 1) {
  const dd = await agent(
    `다음은 disciplined-coder 저장소 감사에서 여러 렌즈가 낸 원시 발견 목록(JSON)이다.
같은 실체(같은 파일의 같은 문제)를 가리키는 발견들을 하나로 병합하라 — evidence는 가장 구체적인 것을 남기고, lens는 쉼표로 합치고, consequence는 피해를 가장 구체적으로 적은 것을 남긴다.
서로 다른 문제는 절대 합치지 마라. 재판단·신규 발견 추가 금지 — 순수 병합만 한다.
${JSON.stringify(all)}`,
    { label: 'dedup', phase: '중복제거', schema: FINDINGS_SCHEMA, effort: 'low' }
  )
  if (dd && dd.findings.length > 0 && dd.findings.length <= all.length) deduped = dd.findings
}
log(`중복 제거 후 ${deduped.length}건 — 반박 검증 시작`)

phase('반박검증')
const judged = await parallel(
  deduped.map((f, i) => () =>
    parallel([
      () => agent(
        `너는 회의적 검증자다. 저장소 ${REPO} 를 직접 읽고 다음 감사 발견을 사실성 관점에서 반박하라 — 인용 증거가 실제 파일에 그대로 존재하는가, 발견이 내용을 정확히 기술하는가, 못 본 반증이 있는가.
불확실하면 isReal=false. 발견: ${JSON.stringify(f)}`,
        { label: `verify-fact:${i}`, phase: '반박검증', schema: VERDICT_SCHEMA }
      ),
      () => agent(
        `너는 회의적 검증자다. 먼저 ${REPO}/agent-principles.md 를 읽어라. 다음 감사 발견을 실질성 관점에서 반박하라 — 인용 원칙(${f.principle})의 실제 정의에 비추어 진짜 위반인가, 예외 조항·정당한 설계 선택에 해당하지 않는가, 고치면 실질 이득이 있는가.
불확실하면 isReal=false. 발견: ${JSON.stringify(f)}`,
        { label: `verify-merit:${i}`, phase: '반박검증', schema: VERDICT_SCHEMA }
      ),
    ]).then(vs => {
      // 검증자가 죽어 null이 온 것과 실제로 반박한 것은 다르다. 둘을 뭉치면 죽은 표가 '기각'으로 오염된다.
      // 그래서 상태를 셋으로 가른다 — 두 표가 모두 살아 있고 둘 다 진짜라면 confirmed, 둘 다 살아 있는데
      // 하나라도 반박하면 rejected, 표가 모자라면 undetermined다.
      const alive = vs.filter(Boolean)
      const status = alive.length < 2
        ? 'undetermined'
        : (alive.filter(v => v.isReal).length === 2 ? 'confirmed' : 'rejected')
      return { ...f, status, confirmed: status === 'confirmed', missingVotes: 2 - alive.length, verdicts: alive.map(v => v.reason) }
    })
  )
)
const confirmed = judged.filter(Boolean).filter(j => j.status === 'confirmed')
const rejected = judged.filter(Boolean).filter(j => j.status === 'rejected')
const undetermined = judged.filter(Boolean).filter(j => j.status === 'undetermined')
log(`반박 검증 완료: 확정 ${confirmed.length}건 · 기각 ${rejected.length}건 · 미판정 ${undetermined.length}건`)
if (undetermined.length > 0) log(`⚠️ 미판정 ${undetermined.length}건은 검증자가 응답하지 않은 것이지 반박당한 것이 아니다`)

const test = await testPromise

phase('집계')
const aggregate = await agent(
  `너는 집계자다. ${REPO}/skills/meta-aggregate/SKILL.md 를 읽고 그 방식대로, 아래 자기감사 결과의 구조적 건강성을 점검하라 — 확정 발견 간 상충, 커버리지 공백, 전체 판정. 발견 내용 재판단은 금지(검증 단계가 끝냈다). 출력은 완결된 문어체 한국어로: (1) 전체 판정 한 단락, (2) 확정 발견 정리 — 등급을 매기지 말고, 사용자 결정이 필요한 것을 따로 가려 앞에 둔다, (3) 상충 명시, (4) 커버리지 공백.
결정론 테스트 결과: ${JSON.stringify(test)}
확정 발견 (${confirmed.length}건): ${JSON.stringify(confirmed)}
기각 발견 제목들 (${rejected.length}건): ${JSON.stringify(rejected.map(r => ({ title: r.title, why: r.verdicts })))}
미판정 (${undetermined.length}건 — 검증자가 응답하지 않아 판정에 이르지 못했다. 반박당한 것이 아니므로 커버리지 공백으로 다뤄라): ${JSON.stringify(undetermined.map(r => ({ title: r.title, file: r.file })))}
응답하지 않은 렌즈 (${deadLenses.length}개): ${JSON.stringify(deadLenses)}`,
  { label: 'meta-aggregate', phase: '집계' }
)

return {
  test,
  confirmedCount: confirmed.length, rejectedCount: rejected.length, undeterminedCount: undetermined.length,
  deadLenses,
  confirmed,
  rejectedTitles: rejected.map(r => r.title),
  undetermined: undetermined.map(r => ({ title: r.title, file: r.file, missingVotes: r.missingVotes })),
  aggregate,
}
