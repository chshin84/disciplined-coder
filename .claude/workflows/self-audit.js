export const meta = {
  name: 'self-audit',
  description: 'disciplined-coder 저장소를 자기 원칙·자기 렌즈로 자기검증하고 회차 기록을 구조화해 봉인한다',
  whenToUse: '큰 변경(정본·훅·스캐폴드 수정) 후 회귀 감사가 필요할 때 레포 루트에서 실행한다(다른 위치면 args로 레포 경로를 넘긴다). 결과는 docs/superpowers/reviews/<회차>/ 의 run.json·findings.json·diff.json·렌즈 원본과 봉인하지 않은 요약문이다. 이 레포가 아니면 아무것도 쓰지 않고 멈춘다.',
  phases: [
    { title: '준비', detail: '레포 확인 → 대상·조각·문턱 도출과 렌즈 배정 → 기계 검사와 지문' },
    { title: '리뷰', detail: '문서별 렌즈(grounding·readability·fit)와 전체 렌즈(adversarial·plugin-compliance)를 병렬로 띄운다' },
    { title: '중복제거', detail: '병합 항목마다 merged_from 을 받아 원시 발견이 하나도 안 빠졌는지 확인한다' },
    { title: '반박검증', detail: '발견마다 사실성·실질성 검증자 둘, 판정과 사유를 둘 다 남긴다' },
    { title: '집계', detail: '상충·커버리지 공백 표시와 지문 재확인' },
    { title: '기록', detail: '걸음마다 기록자가 파일 하나씩 쓰고 검수자가 센다 — run.json 은 검수를 지난 뒤 completed 로 닫힌다' },
  ],
}

// 레포 경로는 하드코딩하지 않는다(레포 정본은 어느 클론에서도 동작해야 한다 — EXPLICIT).
// 기본값 '.'은 "레포 루트에서 실행"을 전제하고, 다른 위치면 args로 절대 경로를 넘긴다.
const REPO = (typeof args === 'string' && args.length > 0) ? args : '.'

// 발견 id 는 회차 이름과 일련번호다(2026-09-02-self-audit#017). 기록자는 이 값을 그대로 옮겨 적는다.
// ROUND 는 대상 도출 걸음이 정한다(덩어리 3). 그 전까지는 실행체 이름만 쓴다.
let ROUND = 'self-audit'
const EXECUTOR = 'self-audit'
const SCHEMA_VERSION = 1
// 걸음 이름의 닫힌 목록. 기록자는 끝난 걸음 이름을 run.json 의 steps_done 에 쌓는다.
const STEPS = ['repo-check', 'targets', 'machine-checks', 'review', 'dedup', 'verify', 'aggregate', 'record']
function findingId(round, n) { return `${round}#${String(n).padStart(3, '0')}` }
// 판정 상태의 닫힌 집합 — 'derived'는 반박검증 없이 도출된 발견(회차 대조가 만든다)이다.
const STATUS = ['confirmed', 'rejected', 'undetermined', 'derived']

const FINDINGS_SCHEMA = {
  type: 'object',
  properties: {
    findings: {
      type: 'array',
      items: {
        type: 'object',
        properties: {
          title: { type: 'string', description: '발견 제목 — 완결된 문장으로 (PROSE-FORM)' },
          file: { type: 'string', description: '증거 파일 경로 (file:line 형식 권장)' },
          evidence: { type: 'string', description: '실제 파일에서 인용한 증거 텍스트' },
          principle: { type: 'string', description: '위반/관련 원칙 ID 또는 렌즈 규칙' },
          consequence: { type: 'string', description: '이대로 두면 무엇이 어떻게 잘못되는가 — 구체적으로 못 적는 발견은 올리지 않는다' },
          detail: { type: 'string', description: '왜 위반인지 — 근거를 완결된 문장으로 설명' },
          fix: { type: 'string', description: '제안하는 수정 방향 (선택)' },
          type: { type: 'string', description: '렌즈가 정한 폐쇄 집합의 값. 복제 발견은 duplication 이다(선택)' },
        },
        required: ['title', 'file', 'evidence', 'principle', 'consequence', 'detail'],
      },
    },
  },
  required: ['findings'],
}

// 중복제거는 병합 항목마다 그것이 덮는 원시 발견의 번호(merged_from)를 돌려준다. 개수만 견주면 발견을
// 버려도 통과하므로, 모든 원시 발견이 정확히 한 항목에 들어갔는지를 워크플로가 확인한다.
const DEDUP_SCHEMA = {
  type: 'object',
  properties: {
    findings: {
      type: 'array',
      items: {
        type: 'object',
        properties: {
          ...FINDINGS_SCHEMA.properties.findings.items.properties,
          lens: { type: 'string', description: '병합된 렌즈 이름들 — 쉼표로 잇는다' },
          merged_from: { type: 'array', items: { type: 'integer' }, description: '이 항목이 덮는 원시 발견의 번호(0부터)' },
        },
        required: [...FINDINGS_SCHEMA.properties.findings.items.required, 'lens', 'merged_from'],
      },
    },
  },
  required: ['findings'],
}
// 중복제거가 lens 를 쉼표로 잇는다. 세는 쪽은 그 문자열을 목록으로 다룬다.
function lensesOf(f) { return String(f.lens || '').split(',').map(s => s.trim()).filter(Boolean) }

const LENS_SCHEMA = {
  type: 'object',
  properties: {
    findings: FINDINGS_SCHEMA.properties.findings,
    read: { type: 'array', items: { type: 'string' }, description: '문서 밖에서 실제로 연 파일' },
    principles_applied: { type: 'array', items: { type: 'string' }, description: '읽고 적용한 원칙 ID' },
  },
  required: ['findings', 'read', 'principles_applied'],
}
const REPO_CHECK_SCHEMA = {
  type: 'object',
  properties: { name: { type: 'string', description: '.claude-plugin/plugin.json 의 name. 파일이 없으면 빈 문자열' } },
  required: ['name'],
}
const TARGETS_SCHEMA = {
  type: 'object',
  properties: {
    date: { type: 'string', description: 'date +%F 결과' },
    round: { type: 'string', description: '회차 이름 — <date>-self-audit, 같은 이름 폴더나 .md 가 있으면 -2, -3 을 붙인다' },
    limit: { type: 'integer', description: 'audit_targets.sh --limit 의 값' },
    fragments: { type: 'array', items: { type: 'object', properties: { path: { type: 'string', description: '레포 상대경로 — 스크립트 출력 그대로' }, start: { type: 'integer' }, end: { type: 'integer' } }, required: ['path', 'start', 'end'] } },
    targets: {
      type: 'array',
      items: {
        type: 'object',
        properties: {
          path: { type: 'string', description: '레포 상대경로 — 조각의 path 와 같은 꼴' },
          lenses: { type: 'array', items: { type: 'string', enum: ['lens-grounding', 'lens-readability', 'lens-fit'] } },
          reason: { type: 'string', description: '물음 넷에 어떻게 답했는지' },
          purpose: { type: 'string', description: 'lens-readability 에 줄 목적 한 줄(읽는 사람 + 할 수 있어야 하는 것). 못 적으면 빈 문자열이고 그때는 lenses 에 lens-readability 를 넣지 않는다' },
        },
        required: ['path', 'lenses', 'reason', 'purpose'],
      },
    },
  },
  required: ['date', 'round', 'limit', 'fragments', 'targets'],
}
const MACHINE_SCHEMA = {
  type: 'object',
  properties: {
    allPassed: { type: 'boolean' },
    results: { type: 'array', items: { type: 'object', properties: { name: { type: 'string' }, passed: { type: 'boolean' }, summary: { type: 'string' } }, required: ['name', 'passed', 'summary'] } },
    commit: { type: 'string', description: 'git rev-parse HEAD' },
    tree_clean: { type: 'boolean', description: 'git status --porcelain 이 비어 있으면 true' },
  },
  required: ['allPassed', 'results', 'commit', 'tree_clean'],
}
const AGGREGATE_SCHEMA = {
  type: 'object',
  properties: {
    verdict: { type: 'string', description: '전체 판정 한 단락 — 완결된 문어체 한국어' },
    conflicts: { type: 'array', items: { type: 'object', properties: { ids: { type: 'array', items: { type: 'string' } }, reason: { type: 'string' } }, required: ['ids', 'reason'] } },
    coverage_gaps: { type: 'array', items: { type: 'string' } },
    commit: { type: 'string' },
    tree_clean: { type: 'boolean' },
  },
  required: ['verdict', 'conflicts', 'coverage_gaps', 'commit', 'tree_clean'],
}
const RECORD_SCHEMA = { type: 'object', properties: { path: { type: 'string' }, count: { type: 'integer' } }, required: ['path', 'count'] }
const CHECK_SCHEMA = { type: 'object', properties: { path: { type: 'string' }, count: { type: 'integer' }, ids: { type: 'array', items: { type: 'string' } } }, required: ['path', 'count', 'ids'] }

const VERDICT_SCHEMA = {
  type: 'object',
  properties: {
    isReal: { type: 'boolean', description: '반박에 실패했으면(=발견이 실재하면) true. 불확실하면 false.' },
    reason: { type: 'string', description: '판정 근거 한두 문장' },
  },
  required: ['isReal', 'reason'],
}

const CANON = `${REPO}/agent-principles.md`
const COMMON = `너는 disciplined-coder 플러그인 저장소(${REPO})를 감사하는 읽기 전용 렌즈다.
이 저장소는 그 플러그인 자체의 소스다 — 플러그인이 남에게 강제하는 원칙을 자기 자신이 지키는지 검증한다.
먼저 ${CANON} (원칙 정본)을 읽고, 읽고 적용한 원칙 ID를 principles_applied 에 적어라. 문서 밖에서 연 파일은 read 에 적어라.
규칙: (1) 파일을 직접 읽고 실제 인용을 증거로 제시하라 — 추측 금지. (2) 어떤 파일도 수정하지 마라.
(3) 저장소의 어떤 파일에도 쓰지 마라 — 발견은 구조화 리턴으로만 보고한다. (4) 발견은 최대 10건 — 확신 높은 순으로. 없으면 빈 배열이 정직한 답이다.
(5) 각 발견의 title과 detail은 완결된 문장으로 쓴다. (6) 서브에이전트를 새로 열지 마라.`
// 문서별 렌즈 프롬프트 — 렌즈 SKILL.md 의 레퍼런스 프롬프트를 그대로 적용하게 하고 정본 경로와 principles_applied 만 더한다.
function lensPrompt(lens, target) {
  const purpose = lens === 'lens-readability' ? `\n[이 문서가 전달하려는 것]\n${target.purpose}\n` : ''
  return `${COMMON}
렌즈: ${REPO}/skills/${lens}/SKILL.md 를 읽고 그 레퍼런스 프롬프트와 체크리스트를 그대로 적용하라. 검토 대상: ${REPO}/${target.path} 전체.${purpose}
source(진실): ${REPO} 의 scripts/*.sh, hooks/*, skills/*/SKILL.md, .claude-plugin/*, .claude/workflows/*. 문서가 주장하는 것이 실제와 어긋나면 발견이다.`
}
const WHOLE_LENSES = [
  { key: 'lens-adversarial', prompt: `${COMMON}
렌즈: ${REPO}/skills/lens-adversarial/SKILL.md 를 읽고 그대로 적용하라(가드 포함: 기능 추가 제안 금지·근거 필수). 검토 대상: 정본의 절 전부와 hooks/·scripts/·skills/·.claude/workflows/ 설계 전체 — 절 제목을 파일에서 읽어 목록을 만들고(\`grep '^## ' agent-principles.md\`) 그 전부를 훑어라. 실패 모드, 과설계, 비가역, 자기모순을 공격적으로 찾아라.` },
  { key: 'plugin-compliance', prompt: `${COMMON}
차원: domain-plugin 자기준수 — ${REPO}/skills/domain-plugin/SKILL.md 를 읽고, .claude-plugin/*, hooks/hooks.json, commands/·skills/ frontmatter 가 그 처방을 지키는지 감사하라. 스킬의 주장 자체가 실측과 다르면 그것도 발견이다(MEASURE-FIRST).` },
]

// ---------- 준비 ----------
phase('준비')
const rc = await agent(
  `${REPO}/.claude-plugin/plugin.json 을 읽어 name 값을 돌려줘라. 파일이 없거나 읽을 수 없으면 빈 문자열을 돌려줘라. 아무 파일도 쓰지 마라.`,
  { label: 'repo-check', phase: '준비', schema: REPO_CHECK_SCHEMA, effort: 'low' }
)
if (!rc || rc.name !== 'disciplined-coder') {
  log(`이 레포는 disciplined-coder 가 아니다(name=${rc ? rc.name : 'null'}) — 아무것도 쓰지 않고 멈춘다`)
  return { aborted: true, reason: 'not-disciplined-coder', name: rc ? rc.name : null }
}
const tg = await agent(
  `너는 대상 도출 에이전트다. ${REPO} 에서 다음을 실행하고 결과를 구조화해 돌려줘라. 아무 파일도 쓰지 마라.
- \`date +%F\` 로 오늘 날짜를 얻는다.
- \`bash scripts/audit_targets.sh --limit\` 로 문턱 값을, \`bash scripts/audit_targets.sh\` 로 조각 목록(경로<TAB>시작 줄<TAB>끝 줄)을 얻어 fragments 에 그대로 옮긴다. 경로는 스크립트가 낸 레포 상대경로 그대로 적는다.
- 회차 이름은 <날짜>-${EXECUTOR} 이고, docs/superpowers/reviews/ 아래에 같은 이름의 폴더나 .md 가 이미 있으면 -2, -3 처럼 회차를 붙여 앞 회차를 덮지 않는다.
- 조각의 경로를 문서 단위로 모아, 문서마다 ${REPO}/skills/project-doc-audit/SKILL.md 의 「렌즈 배정 기준」 물음 넷에 답해 lenses 를 정하고 그 답을 reason 에 적는다. 이 절차에서 lens-consistency 는 문서별로 걸지 않는다. lens-readability 를 걸 문서에는 purpose(읽는 사람과 그 사람이 무엇을 할 수 있어야 하는지)를 한 줄로 적고, 못 적겠으면 purpose 를 비우고 lens-readability 를 넣지 않고 reason 에 그 이유를 적는다.
- 배정은 무엇으로 만들어졌는지나 어느 폴더에 있는지로 정하지 않는다.`,
  { label: 'targets', phase: '준비', schema: TARGETS_SCHEMA }
)
if (!tg) throw new Error('대상 도출 에이전트가 응답하지 않았다 — 회차를 시작하지 않는다')
ROUND = tg.round
const REVIEWS = `${REPO}/docs/superpowers/reviews`
const DIR = `${REVIEWS}/${ROUND}`
log(`회차 ${ROUND}: 대상 ${tg.targets.length}건, 조각 ${tg.fragments.length}개, 문턱 ${tg.limit}자`)

const machinePromise = agent(
  `${COMMON}
너만 예외적으로 실행 권한이 있다(파일 수정은 여전히 금지). ${REPO} 에서 다음을 실행하고 결과를 보고하라:
- scripts/test_*.sh 를 전부. 목록도 실행 명령도 여기 적지 않는다 — ${REPO}/CLAUDE.md 가 그 명령의 정본이니 그 파일을 읽고 거기 적힌 형태 그대로 돌려라. 앞 스크립트의 실패가 마지막 스크립트의 종료 코드에 묻히는 형태로 바꿔 쓰지 마라.
- claude plugin validate ./ (non-strict)
- git rev-parse HEAD 를 commit 에, git status --porcelain 이 비어 있으면 tree_clean=true 를 적어라. 감사가 도는 동안 작업 트리를 고치지 않는다는 약속의 검사가 이 지문이다.
어떤 스크립트를 실제로 돌렸는지 이름을 모두 results 에 적어라. 하나도 못 찾았으면 그 사실 자체가 FAIL이다. 환경 원인의 실패는 그 사실을 보고하라(수정 시도 금지).`,
  { label: 'machine-checks', phase: '준비', schema: MACHINE_SCHEMA }
)

// ---------- 기록 ----------
// 기록자는 파일 하나마다 한 번 띄우고 검수자가 그 파일을 센다. 실패 단위가 파일 하나다.
// run.json 은 걸음마다 다시 쓰고, 검수를 지난 뒤에만 completed 를 참으로 놓고 그때 봉인한다. 요약문은 봉인하지 않는다.
const run = {
  schema: SCHEMA_VERSION, executor: EXECUTOR, commit: null, tree_clean: null, tree_changed: false,
  completed: false, steps_done: ['repo-check'], targets: tg.targets, topic_groups: 0, counts_by_lens: {},
  verdict_counts: { confirmed: 0, rejected: 0, undetermined: 0, derived: 0 },
  narrowed: 0, unlabeled: 0, dead_agents: {}, machine_checks: null, stale_rounds: [],
}
const COUNT_RULE = 'count 는 이렇게 센다 — JSON 에 findings 배열이 있으면 그 길이, items 배열이 있으면 그 길이, steps_done 배열이 있으면 그 길이, 마크다운은 파일이 있으면 1, 파일이 없으면 -1.'
async function writeFile(step, f) {  // f: { name, content(object|string), count, ids|null, seal }
  const path = `${DIR}/${f.name}`
  const body = typeof f.content === 'string' ? { text: f.content } : { json: f.content }
  const wrote = await agent(
    `너는 기록자다. 파일 ${path} 를 만들어 내용을 한 글자도 바꾸지 말고 써라(폴더 ${DIR} 가 없으면 만든다). json 이 있으면 들여쓰기 1의 JSON 으로, text 가 있으면 그 문자열을 그대로 쓴다. 파일은 파이썬으로 쓴다.${f.seal ? `\n쓴 뒤 \`bash ${REPO}/scripts/seal_reviews.sh "${path}"\` 로 봉인한다.` : ''}
${COUNT_RULE} path 와 count 를 돌려줘라.
${JSON.stringify(body)}`,
    { label: `record:${step}:${f.name}`, phase: '기록', schema: RECORD_SCHEMA, effort: 'low' }
  )
  if (!wrote) throw new Error(`기록자가 ${step} 걸음의 ${f.name} 에서 응답하지 않았다 — 회차를 실패로 끝낸다`)
  const chk = await agent(
    `너는 검수자다. 파일 ${path} 를 열어 count 와 ids(항목의 id 값을 순서대로, 없으면 빈 배열)를 세어 돌려줘라. path 는 받은 문자열 그대로 돌려준다. 파일을 고치지 마라. ${COUNT_RULE}`,
    { label: `check:${step}:${f.name}`, phase: '기록', schema: CHECK_SCHEMA, effort: 'low' }
  )
  if (!chk) throw new Error(`검수자가 ${step} 걸음의 ${f.name} 에서 응답하지 않았다 — 회차를 실패로 끝낸다`)
  const idsOk = !f.ids || JSON.stringify(chk.ids) === JSON.stringify(f.ids)
  if (chk.count !== f.count || !idsOk) throw new Error(`기록 검수 불일치: ${f.name} — 넘긴 ${f.count}건/${f.ids ? f.ids.length : '-'}id, 읽은 ${chk.count}건/${chk.ids.length}id`)
}
async function writeRun(final) {
  if (final) {
    // 검수를 먼저 — 지금까지의 run.json 을 검수자가 읽어 끝난 걸음 수가 맞아야 completed 를 참으로 놓는다.
    await writeFile('record', { name: 'run.json', content: run, count: run.steps_done.length, ids: null, seal: false })
    run.completed = true
  }
  await writeFile('record', { name: 'run.json', content: run, count: run.steps_done.length, ids: null, seal: final })
}
async function record(step, files) {
  if (!STEPS.includes(step)) throw new Error(`알 수 없는 걸음 ${step}`)
  for (const f of files) await writeFile(step, { seal: true, ...f })
  if (!run.steps_done.includes(step)) run.steps_done.push(step)
  await writeRun(false)
}
async function writeSummary(text) {
  // 요약문은 봉인하지 않는다 — 호출자가 뿌리와 물음을 붙인 뒤 seal_reviews.sh 로 봉인한다.
  const path = `${REVIEWS}/${ROUND}.md`
  const wrote = await agent(
    `너는 기록자다. 파일 ${path} 를 만들어 아래 text 를 한 글자도 바꾸지 말고 써라. 봉인하지 않는다. ${COUNT_RULE} path 와 count 를 돌려줘라.
${JSON.stringify({ text })}`,
    { label: 'record:summary', phase: '기록', schema: RECORD_SCHEMA, effort: 'low' }
  )
  if (!wrote || wrote.count !== 1) throw new Error('기록자가 요약문을 쓰지 못했다 — 회차를 실패로 끝낸다')
}
await record('targets', [])

// ---------- 리뷰 ----------
phase('리뷰')
const deadLenses = []
const perDoc = tg.targets.flatMap(t => t.lenses.map(lens => ({ lens, target: t })))
const lensCounter = {}
const reviewJobs = perDoc.map(j => () => {
  lensCounter[j.lens] = (lensCounter[j.lens] || 0) + 1
  const n = lensCounter[j.lens]
  return agent(lensPrompt(j.lens, j.target), { label: `${j.lens}:${j.target.path}`, phase: '리뷰', schema: LENS_SCHEMA })
    .then(res => ({ key: j.lens, file: `${j.lens}-${n}.json`, target: j.target.path, res }))
    .catch(() => ({ key: j.lens, file: `${j.lens}-${n}.json`, target: j.target.path, res: null }))
}).concat(WHOLE_LENSES.map(w => () =>
  agent(w.prompt, { label: w.key, phase: '리뷰', schema: LENS_SCHEMA })
    .then(res => ({ key: w.key, file: `${w.key}-1.json`, target: '(전체)', res }))
    .catch(() => ({ key: w.key, file: `${w.key}-1.json`, target: '(전체)', res: null }))
))
const reviews = (await parallel(reviewJobs)).filter(Boolean)
for (const r of reviews) if (!r.res) deadLenses.push(`${r.key}:${r.target}`)
const all = reviews.filter(r => r.res).flatMap(r => r.res.findings.map(f => ({ ...f, lens: r.key, target: r.target })))
run.dead_agents.review = deadLenses
log(`리뷰 완료: 호출 ${reviews.length}건에서 원시 발견 ${all.length}건`)
if (deadLenses.length > 0) log(`⚠️ 응답하지 않은 렌즈 ${deadLenses.length}건: ${deadLenses.join(', ')} — 이 감사의 커버리지가 그만큼 좁다`)
await record('review', reviews.filter(r => r.res).map(r => ({ name: r.file, content: { lens: r.key, target: r.target, ...r.res }, count: r.res.findings.length, ids: null })))

phase('중복제거')
const raw = all.map((f, i) => ({ raw_index: i, ...f }))
let deduped = raw.map(f => ({ ...f, merged_from: [f.raw_index] }))
if (raw.length > 1) {
  const dd = await agent(
    `다음은 disciplined-coder 저장소 감사에서 여러 렌즈가 낸 원시 발견 목록(JSON)이다. 항목마다 raw_index 가 있다.
같은 실체(같은 파일의 같은 문제)를 가리키는 발견들을 하나로 병합하라 — evidence는 가장 구체적인 것을 남기고, lens는 쉼표로 합치고, consequence는 피해를 가장 구체적으로 적은 것을 남기고, type 이 있으면 그대로 옮긴다.
병합 항목마다 그것이 덮는 원시 발견의 raw_index 전부를 merged_from 에 적어라. 모든 원시 발견은 정확히 한 항목에 들어가야 한다.
서로 다른 문제는 절대 합치지 마라. 재판단·신규 발견 추가 금지 — 순수 병합만 한다.
${JSON.stringify(raw)}`,
    { label: 'dedup', phase: '중복제거', schema: DEDUP_SCHEMA, effort: 'low' }
  )
  if (!dd) throw new Error('중복제거 에이전트가 응답하지 않았다 — 회차를 실패로 끝낸다')
  const covered = dd.findings.flatMap(f => f.merged_from).sort((a, b) => a - b)
  const expected = raw.map(f => f.raw_index)
  if (JSON.stringify(covered) !== JSON.stringify(expected)) {
    throw new Error(`중복제거가 원시 발견을 잃었다 — 기대 ${JSON.stringify(expected)}, 실제 ${JSON.stringify(covered)}`)
  }
  deduped = dd.findings
}
log(`중복 제거 후 ${deduped.length}건 — 반박 검증 시작`)
for (const k of [...new Set(all.map(f => f.lens))]) run.counts_by_lens[k] = { raw: all.filter(f => f.lens === k).length, unique: deduped.filter(f => lensesOf(f).length === 1 && lensesOf(f)[0] === k).length }
await record('dedup', [])

phase('반박검증')
const judged = (await parallel(
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
      // 하나라도 반박하면 rejected, 표가 모자라면 undetermined다. 판정(isReal)과 사유를 둘 다 남긴다.
      const alive = vs.filter(Boolean)
      const status = alive.length < 2
        ? STATUS[2]
        : (alive.filter(v => v.isReal).length === 2 ? STATUS[0] : STATUS[1])
      const { raw_index, ...rest } = f
      return { id: findingId(ROUND, i + 1), ...rest, status, missingVotes: 2 - alive.length, verdicts: alive.map(v => ({ isReal: v.isReal, reason: v.reason })) }
    })
  )
)).filter(Boolean)
const confirmed = judged.filter(j => j.status === 'confirmed')
const rejected = judged.filter(j => j.status === 'rejected')
const undetermined = judged.filter(j => j.status === 'undetermined')
log(`반박 검증 완료: 확정 ${confirmed.length}건 · 기각 ${rejected.length}건 · 미판정 ${undetermined.length}건`)
if (undetermined.length > 0) log(`⚠️ 미판정 ${undetermined.length}건은 검증자가 응답하지 않은 것이지 반박당한 것이 아니다`)
run.verdict_counts = { confirmed: confirmed.length, rejected: rejected.length, undetermined: undetermined.length, derived: 0 }
run.dead_agents.verify = judged.filter(j => j.missingVotes > 0).map(j => j.id)
const findingsFile = { schema: SCHEMA_VERSION, findings: judged.filter(j => j.status !== STATUS[1]), rejected: rejected.map(r => ({ id: r.id, title: r.title, reasons: r.verdicts.map(v => v.reason) })) }
// 첫 회차에는 대조할 지난 회차가 없다. 덩어리 4가 이 자리를 실제 대조로 바꾼다.
const diffFile = { schema: SCHEMA_VERSION, no_prior_round: true, items: [] }
await record('verify', [
  { name: 'findings.json', content: findingsFile, count: findingsFile.findings.length, ids: findingsFile.findings.map(f => f.id) },
  { name: 'diff.json', content: diffFile, count: diffFile.items.length, ids: null },
])

const machine = await machinePromise
run.machine_checks = machine ? { allPassed: machine.allPassed, results: machine.results } : null
run.commit = machine ? machine.commit : null
run.tree_clean = machine ? machine.tree_clean : null
if (!machine) run.dead_agents.machine = true
await record('machine-checks', [])

phase('집계')
const aggregate = await agent(
  `너는 집계자다. ${REPO}/skills/meta-aggregate/SKILL.md 를 읽고 그 방식대로, 아래 자기감사 결과의 구조적 건강성을 점검하라 — 확정 발견 간 상충(같은 곳을 두고 반대로 판정한 짝)과 커버리지 공백(봤어야 하는데 아무도 안 본 대상이나 렌즈)과 전체 판정. 발견 내용 재판단은 금지(검증 단계가 끝냈다).
먼저 ${REPO} 에서 git rev-parse HEAD 와 git status --porcelain 을 다시 실행해 commit 과 tree_clean 에 적어라. 아래 기계 검사의 지문과 다르면 「감사 도중 작업 트리가 바뀌었다 — 이 회차의 판정은 움직인 작업 트리에 대한 것이다」를 verdict 첫 문장으로 적어라.
기계 검사: ${JSON.stringify(run.machine_checks)} (commit ${run.commit}, tree_clean ${run.tree_clean})
확정 발견 (${confirmed.length}건): ${JSON.stringify(confirmed)}
기각 (${rejected.length}건): ${JSON.stringify(findingsFile.rejected)}
미판정 (${undetermined.length}건 — 검증자가 응답하지 않은 것이지 반박당한 것이 아니다. 커버리지 공백으로 다뤄라): ${JSON.stringify(undetermined.map(r => ({ id: r.id, title: r.title })))}
응답하지 않은 렌즈 호출: ${JSON.stringify(deadLenses)}`,
  { label: 'meta-aggregate', phase: '집계', schema: AGGREGATE_SCHEMA }
)
if (!aggregate) run.dead_agents.aggregate = true
run.tree_changed = !!(aggregate && machine && (aggregate.commit !== machine.commit || aggregate.tree_clean !== machine.tree_clean))
await record('aggregate', [])

// ---------- 요약문 ----------
// 세 파일에서 도출되는 사실만 적는다. 되풀이되는 뿌리와 사용자에게 올릴 물음은 판단이라 호출자가 끝에 붙인 뒤 봉인한다.
const line = (t) => `- ${t}`
const derivedFindings = findingsFile.findings.filter(f => f.status === STATUS[3])
const summary = [
  `# 자기감사 회차 ${ROUND}`,
  '',
  `실행체 ${EXECUTOR}(스키마 ${SCHEMA_VERSION})가 커밋 ${run.commit || '(측정 실패)'}${run.tree_clean === false ? '(작업 트리에 미커밋 변경 있음)' : ''} 위에서 돌았다. 확정 ${confirmed.length}건, 기각 ${rejected.length}건, 미판정 ${undetermined.length}건, 도출 ${derivedFindings.length}건이다.${run.tree_changed ? ' 감사 도중 작업 트리가 바뀌었다.' : ''} 구조화된 기록은 같은 이름의 폴더에 있다.`,
  '',
  '## 범위와 배정',
  '',
  ...tg.targets.map(t => line(`\`${t.path}\` — ${t.lenses.join(', ') || '(문서별 렌즈 없음)'}. ${t.reason}`)),
  line(`전체 렌즈 — ${WHOLE_LENSES.map(w => w.key).join(', ')}`),
  line(`조각 ${tg.fragments.length}개, 문턱 ${tg.limit}자`),
  '',
  '## 기계 검사',
  '',
  ...(machine ? machine.results.map(r => line(`${r.name} — ${r.passed ? 'PASS' : 'FAIL'}. ${r.summary}`)) : [line('기계 검사 에이전트가 응답하지 않았다')]),
  '',
  '## 집계',
  '',
  aggregate ? aggregate.verdict : '집계 에이전트가 응답하지 않았다.',
  '',
  ...(aggregate && aggregate.conflicts.length ? aggregate.conflicts.map(c => line(`상충 ${c.ids.join(' · ')} — ${c.reason}`)) : [line('상충 없음')]),
  ...(aggregate && aggregate.coverage_gaps.length ? aggregate.coverage_gaps.map(g => line(`커버리지 공백 — ${g}`)) : [line('커버리지 공백 없음')]),
  ...(deadLenses.length ? [line(`응답하지 않은 렌즈 호출 — ${deadLenses.join(', ')}`)] : []),
  '',
  '## 확정 발견',
  '',
  ...(confirmed.length ? confirmed.map(f => line(`\`${f.id}\` ${f.title} (${f.file})`)) : [line('없음')]),
  '',
  '## 회차 대조',
  '',
  ...(diffFile.no_prior_round ? [line('대조할 지난 회차 없음')] : [line(`잔존 ${diffFile.items.filter(i => i.verdict === '잔존').length}건, 해소 ${diffFile.items.filter(i => i.verdict === '해소').length}건, 미판정 ${diffFile.items.filter(i => i.verdict === '미판정').length}건`)]),
  ...(run.stale_rounds.length ? [line(`끊긴 회차 — ${run.stale_rounds.join(', ')}`)] : []),
  '',
  '## 도출된 발견',
  '',
  ...(derivedFindings.length ? derivedFindings.map(f => line(`\`${f.id}\` ${f.title} (${f.evidence})`)) : [line('없음')]),
  '',
].join('\n')
await writeSummary(summary)
if (!run.steps_done.includes('record')) run.steps_done.push('record')
await writeRun(true)

return {
  round: ROUND, dir: DIR, run,
  confirmed: confirmed.map(f => ({ id: f.id, title: f.title, file: f.file })),
  rejected: findingsFile.rejected, undetermined: undetermined.map(f => ({ id: f.id, title: f.title })),
  aggregate,
}
