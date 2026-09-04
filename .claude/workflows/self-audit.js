export const meta = {
  name: 'self-audit',
  description: 'disciplined-coder 저장소를 자기 원칙·자기 렌즈로 자기검증하고 회차 기록을 구조화해 봉인한다',
  whenToUse: '큰 변경(정본·훅·스캐폴드 수정) 후 회귀 감사가 필요할 때 레포 루트에서 실행한다(다른 위치면 args로 레포 경로를 넘긴다). 결과는 docs/superpowers/reviews/<회차>/ 의 run.json·findings.json·diff.json·렌즈 원본과 봉인하지 않은 요약문이다. 이 레포가 아니면 아무것도 쓰지 않고 멈춘다.',
  phases: [
    { title: '준비', detail: '레포 확인 → 대상·조각·문턱 도출과 렌즈 배정 → 기계 검사와 지문' },
    { title: '뽑기', detail: '조각마다 진술을 뽑고 이름표별로 모아 둘 이상의 문서에서 온 묶음만 남긴다' },
    { title: '리뷰', detail: '문서별 렌즈(grounding·readability·fit)와 전체 렌즈(adversarial·plugin-compliance)를 병렬로 띄운다' },
    { title: '중복제거', detail: '묶음마다 merged_from 을 받아 원시 발견이 하나도 안 빠졌는지 확인한다' },
    { title: '반박검증', detail: '파일마다 검증자 하나가 사실성과 실질성을 함께 보고 판정과 사유를 둘 다 남긴다' },
    { title: '대조', detail: '직전 회차와 전전 회차에서 온 발견을 파일마다 에이전트 하나가 잔존·해소로 판정하고 재발을 도출한다' },
    { title: '집계', detail: '상충·커버리지 공백 표시와 지문 재확인' },
    { title: '기록', detail: '기록자가 파일 여럿을 맡아 쓰고 검수자가 폴더를 열어 센다 — run.json 은 검수를 지난 뒤 completed 로 닫힌다' },
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
// 한 걸음이 띄우는 서브에이전트의 상한이다. 배분 규칙은 하나씩 보면 타당해도 곱하면 세 자리가
// 된다 — 리뷰는 문서×렌즈, 검증은 발견마다다. 상한을 넘으면 잘라 내고 무엇을 잘랐는지 기록에
// 남긴다. 조용히 자르면 '아무도 반박하지 않았다'와 '아무도 보지 않았다'가 구별되지 않는다.
const CAPS = { review: 30, verify: 50 }
const STEPS = ['repo-check', 'targets', 'machine-checks', 'extract', 'group', 'review', 'dedup', 'verify', 'diff', 'aggregate', 'record']
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

// 중복제거는 묶음마다 그것이 덮는 원시 발견의 번호(merged_from)를 돌려준다. 개수만 견주면 발견을
// 버려도 통과하므로, 모든 원시 발견이 정확히 한 묶음에 들어갔는지를 워크플로가 확인한다.
// 병합된 본문을 다시 쓰게 하지 않는 이유는 출력 상한이다 — 발견 수백 건의 본문을 한 응답에 담으면
// 상한을 넘어 회차가 끊긴다. 어느 것이 같은 실체인지는 판단이고 본문을 잇는 것은 계산이라, 판단만
// 에이전트에 맡기고 계산은 워크플로가 한다.
const DEDUP_SCHEMA = {
  type: 'object',
  properties: {
    groups: {
      type: 'array',
      items: {
        type: 'object',
        properties: {
          merged_from: { type: 'array', items: { type: 'integer' }, description: '한 실체를 가리키는 원시 발견의 번호(0부터) 전부' },
          keep: { type: 'integer', description: '이 묶음에서 증거와 설명을 남길 대표 원시 발견의 번호' },
        },
        required: ['merged_from', 'keep'],
      },
    },
  },
  required: ['groups'],
}
// 중복제거가 lens 를 쉼표로 잇는다. 세는 쪽은 그 문자열을 목록으로 다룬다.
function lensesOf(f) { return String(f.lens || '').split(',').map(s => s.trim()).filter(Boolean) }

// 한 문서에 배정된 렌즈가 둘셋이면 에이전트도 둘셋 띄우던 것을, 문서 하나에 하나로 묶었다.
// 그 에이전트가 문서를 한 번 읽고 배정된 렌즈를 차례로 적용하므로, 발견마다 어느 렌즈가 낸 것인지
// 스스로 적어야 한다. 기록은 예전대로 렌즈마다 파일 하나로 갈라 쓴다.
const LENS_SCHEMA = {
  type: 'object',
  properties: {
    findings: {
      type: 'array',
      items: {
        type: 'object',
        properties: {
          ...FINDINGS_SCHEMA.properties.findings.items.properties,
          lens: { type: 'string', description: '이 발견을 낸 렌즈 이름 — 받은 렌즈 목록에 있는 것만 쓴다' },
        },
        required: [...FINDINGS_SCHEMA.properties.findings.items.required, 'lens'],
      },
    },
    read: { type: 'array', items: { type: 'string' }, description: '문서 밖에서 실제로 연 파일' },
    principles_applied: { type: 'array', items: { type: 'string' }, description: '읽고 적용한 원칙 ID' },
  },
  required: ['findings', 'read', 'principles_applied'],
}
const PRIOR_SCHEMA = {
  type: 'object',
  properties: {
    findings: { type: 'array', items: { type: 'object', properties: { id: { type: 'string' }, title: { type: 'string' }, file: { type: 'string' }, evidence: { type: 'string' }, consequence: { type: 'string' }, status: { type: 'string' } }, required: ['id', 'title', 'file', 'evidence', 'consequence', 'status'] } },
    diff_items: { type: 'array', items: { type: 'object', properties: { prior_id: { type: 'string' }, prior_round: { type: 'string' }, title: { type: 'string' }, file: { type: 'string' }, evidence: { type: 'string' }, consequence: { type: 'string' }, verdict: { type: 'string' } }, required: ['prior_id', 'prior_round', 'title', 'file', 'evidence', 'consequence', 'verdict'] } },
    prior_diff_items: { type: 'array', items: { type: 'object', properties: { prior_id: { type: 'string' }, verdict: { type: 'string' } }, required: ['prior_id', 'verdict'] } },
  },
  required: ['findings', 'diff_items', 'prior_diff_items'],
}
// 대조도 파일 하나에 에이전트 하나다. 그 파일의 지난 발견 전부를 한 번에 판정하고 번호로 짝을 맞춘다.
const DIFF_VERDICTS_SCHEMA = {
  type: 'object',
  properties: {
    verdicts: {
      type: 'array',
      items: {
        type: 'object',
        properties: {
          n: { type: 'integer', description: '받은 목록에서 이 판정이 가리키는 지난 발견의 번호' },
          verdict: { type: 'string', enum: ['잔존', '해소'] },
          reason: { type: 'string', description: '잔존이면 지금 파일의 어디에 있는지 인용, 해소면 무엇이 바뀌었는지' },
          matched_id: { type: 'string', description: '이번 회차 발견과 같은 실체이면 그 id, 아니면 빈 문자열' },
        },
        required: ['n', 'verdict', 'reason', 'matched_id'],
      },
    },
  },
  required: ['verdicts'],
}
const EXTRACT_SCHEMA = {
  type: 'object',
  properties: {
    statements: {
      type: 'array',
      items: {
        type: 'object',
        properties: {
          topics: { type: 'array', items: { type: 'string' }, description: '이름표 목록에서 고른 것만. 어느 것에도 안 걸리면 빈 배열' },
          statement: { type: 'string', description: '이 문서가 정한 것 한 줄(규칙·값·절차·이름)' },
          line: { type: 'integer', description: '그 진술이 있는 줄(1부터)' },
          context: { type: 'string', description: '그 줄 앞뒤 다섯 줄의 원문' },
          role: { type: 'string', enum: ['canon', 'follows', 'none'], description: 'canon: 이 문서가 그 주제의 정본이라고 말한다. follows: 그 진술이나 그 진술이 든 절이 다른 문서를 정본으로 이름 부른다. none: 둘 다 아니다' },
          follows: { type: 'string', description: 'role 이 follows 이면 그 문서의 레포 상대경로(스킬이면 skills/<이름>/SKILL.md), 아니면 빈 문자열' },
          condition: { type: 'string', description: '조건이 붙은 문장이면 그 조건, 아니면 빈 문자열' },
        },
        required: ['topics', 'statement', 'line', 'context', 'role', 'follows', 'condition'],
      },
    },
  },
  required: ['statements'],
}
const CONSISTENCY_SCHEMA = {
  type: 'object',
  properties: {
    pairs: {
      type: 'array',
      items: {
        type: 'object',
        properties: {
          canon_line: { type: 'integer' }, other_file: { type: 'string' }, other_line: { type: 'integer' },
          verdict: { type: 'string', enum: ['어긋남', '좁혀 적음', '같음'] },
          reason: { type: 'string' },
        },
        required: ['canon_line', 'other_file', 'other_line', 'verdict', 'reason'],
      },
    },
    narrowed: { type: 'integer', description: '좁혀 적음 판정의 수' },
    findings: FINDINGS_SCHEMA.properties.findings,
    read: { type: 'array', items: { type: 'string' } },
    principles_applied: { type: 'array', items: { type: 'string' } },
  },
  required: ['pairs', 'narrowed', 'findings', 'read', 'principles_applied'],
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
    topics: { type: 'array', items: { type: 'string' }, description: 'audit_topics.sh 의 출력' },
    prior_rounds: { type: 'array', items: { type: 'string' }, description: 'audit_prior_rounds.sh 의 출력 — 최신부터 최대 둘' },
    stale_rounds: { type: 'array', items: { type: 'string' }, description: 'audit_prior_rounds.sh --stale 의 출력' },
  },
  required: ['date', 'round', 'limit', 'fragments', 'targets', 'topics', 'prior_rounds', 'stale_rounds'],
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
const GROUP_RECORD_SCHEMA = { type: 'object', properties: { written: { type: 'array', items: { type: 'string' }, description: '실제로 쓴 파일 이름 전부' } }, required: ['written'] }
const FOLDER_CHECK_SCHEMA = {
  type: 'object',
  properties: {
    files: {
      type: 'array',
      items: {
        type: 'object',
        properties: {
          name: { type: 'string', description: '파일 이름' },
          count: { type: 'integer', description: '그 파일에서 센 개수. 파일이 없으면 -1' },
          ids: { type: 'array', items: { type: 'string' }, description: 'count 를 센 그 배열의 항목 id. id 가 없으면 빈 배열' },
        },
        required: ['name', 'count', 'ids'],
      },
    },
  },
  required: ['files'],
}


// 검증자는 파일 하나를 읽고 그 파일의 발견 전부를 한 번에 판정한다. 발견마다 띄우면 같은 파일을
// 발견 수만큼 다시 읽어 값만 늘고 판정은 나아지지 않는다.
const VERDICTS_SCHEMA = {
  type: 'object',
  properties: {
    verdicts: {
      type: 'array',
      items: {
        type: 'object',
        properties: {
          n: { type: 'integer', description: '받은 목록에서 이 판정이 가리키는 발견의 번호' },
          isReal: { type: 'boolean', description: '반박에 실패했으면(=발견이 실재하면) true. 불확실하면 false.' },
          reason: { type: 'string', description: '판정 근거 한두 문장' },
        },
        required: ['n', 'isReal', 'reason'],
      },
    },
  },
  required: ['verdicts'],
}

const CANON = `${REPO}/agent-principles.md`
const COMMON = `너는 disciplined-coder 플러그인 저장소(${REPO})를 감사하는 읽기 전용 렌즈다.
이 저장소는 그 플러그인 자체의 소스다 — 플러그인이 남에게 강제하는 원칙을 자기 자신이 지키는지 검증한다.
먼저 ${CANON} (원칙 정본)을 읽고, 읽고 적용한 원칙 ID를 principles_applied 에 적어라. 문서 밖에서 연 파일은 read 에 적어라.
규칙: (1) 파일을 직접 읽고 실제 인용을 증거로 제시하라 — 추측 금지. (2) 어떤 파일도 수정하지 마라.
(3) 저장소의 어떤 파일에도 쓰지 마라 — 발견은 구조화 리턴으로만 보고한다. (4) 발견은 최대 3건 — 확신이 가장 높은 것만 낸다. 없으면 빈 배열이 정직한 답이다. 몫을 채우려고 약한 것을 올리지 마라, 약한 발견은 검증에서 기각되고 그 값은 아무것도 낳지 않는다. (4-1) evidence 에는 파일에 있는 그대로의 원문을 인용하고 몇 번째 줄인지 함께 적어라 — 인용이 파일과 한 글자라도 다르면 그 발견은 검증에서 무너진다.
(5) 각 발견의 title과 detail은 완결된 문장으로 쓴다. (6) 서브에이전트를 새로 열지 마라.`
// 문서별 렌즈 프롬프트 — 렌즈 SKILL.md 의 레퍼런스 프롬프트를 그대로 적용하게 하고 정본 경로와 principles_applied 만 더한다.
function docPrompt(target) {
  const purpose = target.lenses.includes('lens-readability') ? `
[이 문서가 전달하려는 것]
${target.purpose}
` : ''
  return `${COMMON}
검토 대상: ${REPO}/${target.path} 전체. 문서를 먼저 한 번 통독하라.${purpose}
이 문서에 배정된 렌즈는 ${target.lenses.length}개다. 렌즈마다 ${REPO}/skills/<렌즈이름>/SKILL.md 를 열어 그 레퍼런스 프롬프트와 체크리스트를 읽고, 한 렌즈씩 차례로 적용하라. 배정된 렌즈: ${target.lenses.join(', ')}.
발견마다 어느 렌즈가 낸 것인지 lens 에 적어라 — 배정된 렌즈 이름만 쓴다. 렌즈 하나가 아무것도 못 찾았으면 그 렌즈의 발견을 억지로 만들지 마라.
(4)의 상한 3건은 이 문서 전체에 대한 상한이지 렌즈마다의 몫이 아니다.
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
- 조각의 경로를 문서 단위로 모아, 문서마다 ${REPO}/skills/project-doc-audit/SKILL.md 의 「렌즈 배정 기준」 표에서 그 문서가 걸리는 종류의 행 하나를 골라 lenses 를 그 행에 적힌 대로 그대로 옮기고, 어느 행을 골랐는지와 왜 그 행인지를 reason 에 적는다. 행을 고르는 것이 판단이고 렌즈를 정하는 것은 판단이 아니다 — 표에 없는 렌즈를 더하지 마라. 이 절차에서 lens-consistency 는 문서별로 걸지 않는다. lens-readability 를 걸 문서에는 purpose(읽는 사람과 그 사람이 무엇을 할 수 있어야 하는지)를 한 줄로 적고, 못 적겠으면 purpose 를 비우고 lens-readability 를 넣지 않고 reason 에 그 이유를 적는다.
- 배정은 무엇으로 만들어졌는지나 어느 폴더에 있는지로 정하지 않는다.
- 'bash scripts/audit_topics.sh' 의 출력을 topics 에 한 줄에 하나씩 옮긴다.
- 'bash scripts/audit_prior_rounds.sh ${EXECUTOR}' 의 출력을 prior_rounds 에, 'bash scripts/audit_prior_rounds.sh ${EXECUTOR} --stale' 의 출력을 stale_rounds 에 한 줄에 하나씩 옮긴다.`,
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
  narrowed: 0, unlabeled: 0, dead_agents: {}, machine_checks: null, stale_rounds: tg.stale_rounds,
}
const COUNT_RULE = 'count 는 이렇게 센다 — JSON 에 findings 배열이 있으면 그 길이, items 배열이 있으면 그 길이, steps_done 배열이 있으면 그 길이, 마크다운은 파일이 있으면 1, 파일이 없으면 -1. ids 는 count 를 센 그 배열의 항목 id 만 순서대로 적고, 그 배열의 항목에 id 가 없으면 빈 배열이다.'
// 긴 파일은 한 응답에 다 못 쓴다 — 출력 상한을 넘으면 회차가 끊기므로 나눠 쓰라고 일러 준다.
const CHUNK_RULE = `
내용이 길다. 한 응답에 다 쓰려 하지 말고 여러 번에 나눠 이어붙여 써라 — 한 번에 다 쓰면 출력 상한에 걸려 회차가 끊긴다. 다 쓴 뒤 파일을 다시 열어 끝까지 온전한지 확인한다.`
async function writeFile(step, f) {  // f: { name, chunked(선택), path(선택 — 없으면 DIR 아래), content(object|string), count, ids|null, seal }
  const path = f.path || `${DIR}/${f.name}`
  const body = typeof f.content === 'string' ? { text: f.content } : { json: f.content }
  const wrote = await agent(
    `너는 기록자다. 파일 ${path} 를 만들어 내용을 한 글자도 바꾸지 말고 써라(폴더 ${DIR} 가 없으면 만든다). json 이 있으면 들여쓰기 1의 JSON 으로, text 가 있으면 그 문자열을 그대로 쓴다. 파일은 파이썬으로 쓴다.${f.seal ? `\n쓴 뒤 \`bash ${REPO}/scripts/seal_reviews.sh "${path}"\` 로 봉인한다.` : ''}${f.chunked ? CHUNK_RULE : ''}
${COUNT_RULE} path 와 count 를 돌려줘라.
${JSON.stringify(body)}`,
    { label: `record:${step}:${f.name}`, phase: '기록', schema: RECORD_SCHEMA, effort: 'low' }
  )
  if (!wrote) throw new Error(`기록자가 ${step} 걸음의 ${f.name} 에서 응답하지 않았다 — 회차를 실패로 끝낸다`)
  const chk = await agent(
    `너는 검수자다. 파일 ${path} 를 열어 count 와 ids 를 세어 돌려줘라. path 는 받은 문자열 그대로 돌려준다. 파일을 고치지 마라. ${COUNT_RULE}`,
    { label: `check:${step}:${f.name}`, phase: '기록', schema: CHECK_SCHEMA, effort: 'low' }
  )
  if (!chk) throw new Error(`검수자가 ${step} 걸음의 ${f.name} 에서 응답하지 않았다 — 회차를 실패로 끝낸다`)
  const idsOk = !f.ids || JSON.stringify(chk.ids) === JSON.stringify(f.ids)
  if (chk.count !== f.count || !idsOk) throw new Error(`기록 검수 불일치: ${f.name} — 넘긴 ${f.count}건/${f.ids ? f.ids.length : '-'}id, 읽은 ${chk.count}건/${chk.ids.length}id`)
}
// 파일마다 기록자와 검수자를 한 쌍씩 띄우면 파일 수의 두 배가 든다. 리뷰 걸음은 파일이 수십 개라
// 한 대상이 낸 파일들을 기록자 하나가 함께 쓰고, 검수자는 걸음 끝에 하나만 띄워 폴더를 통째로 센다.
// 검수의 보장은 그대로다 — 쓴 쪽이 아닌 다른 에이전트가 파일을 다시 열어 센다. 실패 단위만 대상 하나로 넓어진다.
async function recordGrouped(step, groups) {  // groups: [{ key, files: [{ name, content, count }] }]
  for (const g of groups) {
    const payload = g.files.map(f => ({ path: `${DIR}/${f.name}`, json: f.content }))
    const wrote = await agent(
      `너는 기록자다. 아래 목록의 파일을 하나씩 만들어 내용을 한 글자도 바꾸지 말고 써라(폴더 ${DIR} 가 없으면 만든다). 각 항목의 json 을 들여쓰기 1의 JSON 으로 그 path 에 쓴다. 파일은 파이썬으로 쓴다.
파일을 다 쓴 뒤 \`bash ${REPO}/scripts/seal_reviews.sh\` 뒤에 쓴 경로를 전부 인자로 이어 붙여 한 번에 봉인한다.${CHUNK_RULE}
실제로 쓴 파일 이름을 written 에 적어라.
${JSON.stringify(payload)}`,
      { label: `record:${step}:${g.key}`, phase: '기록', schema: GROUP_RECORD_SCHEMA, effort: 'low' }
    )
    if (!wrote) throw new Error(`기록자가 ${step} 걸음의 ${g.key} 에서 응답하지 않았다 — 회차를 실패로 끝낸다`)
  }
  const expected = groups.flatMap(g => g.files.map(f => ({ name: f.name, count: f.count, ids: f.ids || null })))
  const chk = await agent(
    `너는 검수자다. 폴더 ${DIR} 에서 아래 이름의 파일을 하나씩 열어 개수를 세어 돌려줘라. 파일을 고치지 마라. 없는 파일은 count 를 -1 로 적는다. ${COUNT_RULE}
${JSON.stringify(expected.map(e => e.name))}`,
    { label: `check:${step}`, phase: '기록', schema: FOLDER_CHECK_SCHEMA, effort: 'low' }
  )
  if (!chk) throw new Error(`검수자가 ${step} 걸음에서 응답하지 않았다 — 회차를 실패로 끝낸다`)
  const got = new Map(chk.files.map(f => [f.name, f]))
  const bad = expected.filter(e => {
    const g = got.get(e.name)
    if (!g || g.count !== e.count) return true
    return !!e.ids && JSON.stringify(g.ids) !== JSON.stringify(e.ids)
  })
  if (bad.length) throw new Error(`기록 검수 불일치: ${bad.map(e => `${e.name} — 넘긴 ${e.count}건/${e.ids ? e.ids.length : '-'}id, 읽은 ${got.has(e.name) ? `${got.get(e.name).count}건/${got.get(e.name).ids.length}id` : '없음'}`).join(' / ')}`)
  if (!run.steps_done.includes(step)) run.steps_done.push(step)
  if (step === 'review') await writeRun(false)
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
  // 걸음마다 run.json 을 다시 쓰면 걸음 수의 두 배가 기록 배관으로 든다. 중간 상태는 리뷰가 끝난
  // 한 번만 남기고, 나머지는 끝에 한 번 쓴다. 리뷰가 회차에서 가장 긴 걸음이라 여기가 갈림길이다.
  if (step === 'review') await writeRun(false)
}
async function writeSummary(text) {
  // 요약문은 봉인하지 않는다 — 호출자가 뿌리와 물음을 붙인 뒤 seal_reviews.sh 로 봉인한다.
  // 봉인만 빼고 기록 경로는 같다 — 기록자의 자기 보고를 믿지 않고 검수자가 파일을 다시 연다.
  await writeFile('record', { name: `${ROUND}.md`, path: `${REVIEWS}/${ROUND}.md`, content: text, count: 1, ids: null, seal: false, chunked: true })
}
await record('targets', [])

// ---------- 뽑기 ----------
// 조각마다 에이전트 하나가 그 문서가 정한 것을 한 줄씩 뽑는다. 이름표는 닫힌 목록에서만 고르고,
// 진술의 file 은 에이전트가 적은 것을 쓰지 않고 조각의 경로로 덮어쓴다 — 경로 꼴이 어긋나면 모으기가 통째로 빈다.
phase('뽑기')
const topicSet = new Set(tg.topics)
const extracted = (await parallel(tg.fragments.map(fr => () =>
  agent(
    `너는 진술 뽑기 에이전트다. ${REPO}/${fr.path} 의 ${fr.start}~${fr.end}행(1부터, 양끝 포함)만 읽고, 그 조각이 정한 것(규칙·값·절차·이름)을 한 줄씩 뽑아라. 아무 파일도 쓰지 마라.
진술마다 이름표를 아래 목록에서만 고른다(여럿 가능). 목록에 없는 이름표를 지어 붙이지 마라. 어느 것에도 안 걸리면 빈 배열로 둔다. 진술마다 그 줄 앞뒤 다섯 줄의 원문을 context 에 그대로 담는다.
역할은 셋이다 — canon(이 문서가 그 주제의 정본이라고 말한다), follows(그 진술이나 그 진술이 든 절이 다른 문서를 정본으로 이름 부른다 — "상세는 X를 참고한다"·"X가 정한다"·"X가 소유한다"가 그 꼴이다. follows 에 그 문서의 레포 상대경로를 적는다), none(둘 다 아니다). 절 머리에 참조가 있고 아래 문장들이 그것을 따르면 그 문장들도 follows 다.
조건이 붙은 문장은 조건을 condition 에 담는다.
[이름표 목록] ${JSON.stringify(tg.topics)}`,
    { label: `extract:${fr.path}:${fr.start}`, phase: '뽑기', schema: EXTRACT_SCHEMA, effort: 'low' }
  ).then(r => ({ fragment: fr, statements: r ? r.statements : null }))
))).filter(Boolean)
run.dead_agents.extract = extracted.filter(e => !e.statements).map(e => `${e.fragment.path}:${e.fragment.start}`)
const statements = extracted.filter(e => e.statements).flatMap(e => e.statements.map(s => ({ ...s, file: e.fragment.path, topics: s.topics.filter(t => topicSet.has(t)) })))
run.unlabeled = statements.filter(s => s.topics.length === 0).length
log(`뽑기 완료: 진술 ${statements.length}건, 빈 이름표 ${run.unlabeled}건`)
await record('extract', [])

// ---------- 모으기 ----------
// 스크립트 안의 JS 가 이름표별로 묶고 둘 이상의 문서에서 온 묶음만 남긴다. 에이전트가 아니다.
// 정본 관계 세 규칙 — 원칙 ID 와 정본 절 제목의 정본은 agent-principles.md, 스킬·명령 이름의 정본은 그 스킬·명령,
// 정본 문서의 진술이 follows 로 다른 문서를 이름 부르면 그 이름표의 정본은 그 문서다.
// 스킬과 명령 이름은 조각 목록(audit_targets.sh 의 출력)에서 도출한다. 손으로 적은 목록은 두지 않는다.
const fragPaths = [...new Set(tg.fragments.map(f => f.path))]
const PRINCIPLES_PATH = fragPaths.find(p => p.endsWith('agent-principles.md'))
const skillPathOf = {}, commandPathOf = {}
for (const p of fragPaths) {
  const sk = p.match(/^skills\/([^/]+)\/SKILL\.md$/); if (sk) skillPathOf[sk[1]] = p
  const cm = p.match(/^commands\/([^/]+)\.md$/); if (cm) commandPathOf[cm[1]] = p
}
function canonOf(topic, group) {
  let canon = skillPathOf[topic] || commandPathOf[topic] || PRINCIPLES_PATH
  const delegated = group.find(s => s.file === canon && s.role === 'follows' && s.follows)
  if (delegated) canon = delegated.follows
  return canon
}
// 묶음 입력의 크기는 렌즈 프롬프트에 실제로 넣는 JSON 문자열 길이다(진술·앞뒤 원문·범위 문장 표시 전부).
function groupSize(g) { return JSON.stringify({ canon: g.canon_statements, others: g.other_statements }).length }
function groupByTopic(stmts, limit) {
  const byTopic = {}
  for (const s of stmts) for (const t of s.topics) (byTopic[t] = byTopic[t] || []).push(s)
  const groups = []
  for (const [topic, arr] of Object.entries(byTopic)) {
    if (new Set(arr.map(s => s.file)).size < 2) continue
    const canon = canonOf(topic, arr)
    const canonStmts = arr.filter(s => s.file === canon)
    const others = arr.filter(s => s.file !== canon)
    if (canonStmts.length === 0 || others.length === 0) continue
    const whole = { topic, canon, canon_statements: canonStmts, other_statements: others }
    if (groupSize(whole) <= limit) { groups.push(whole); continue }
    // 문턱을 넘으면 정본의 진술 대 따르는 문서 하나의 진술로 짝을 나누고, 그래도 넘으면 따르는 진술을 잘라 나눈다.
    const byFile = {}
    for (const s of others) (byFile[s.file] = byFile[s.file] || []).push(s)
    for (const [file, os] of Object.entries(byFile)) {
      let chunk = []
      for (const s of os) {
        const trial = { topic, canon, canon_statements: canonStmts, other_statements: chunk.concat([s]), split_for: file }
        if (chunk.length > 0 && groupSize(trial) > limit) { groups.push({ topic, canon, canon_statements: canonStmts, other_statements: chunk, split_for: file }); chunk = [] }
        chunk.push(s)
      }
      if (chunk.length) groups.push({ topic, canon, canon_statements: canonStmts, other_statements: chunk, split_for: file })
    }
  }
  return groups
}
const groups = groupByTopic(statements, tg.limit)
const oversize = groups.filter(g => groupSize(g) > tg.limit)
run.topic_groups = groups.length
log(`모으기 완료: 이름표 묶음 ${groups.length}개${oversize.length ? `, 문턱을 넘는 묶음 ${oversize.length}개(정본 진술만으로 이미 넘는다)` : ''}`)
await record('group', [])

// ---------- 리뷰 ----------
phase('리뷰')
const deadLenses = []
const reviewJobs = tg.targets.map(t => () =>
  agent(docPrompt(t), { label: `문서:${t.path}`, phase: '리뷰', schema: LENS_SCHEMA })
    .then(res => ({ kind: 'doc', target: t, res }))
    .catch(() => ({ kind: 'doc', target: t, res: null }))
).concat(WHOLE_LENSES.map(w => () =>
  agent(w.prompt, { label: w.key, phase: '리뷰', schema: LENS_SCHEMA })
    .then(res => ({ kind: 'whole', key: w.key, target: { path: '(전체)', lenses: [w.key] }, res }))
    .catch(() => ({ kind: 'whole', key: w.key, target: { path: '(전체)', lenses: [w.key] }, res: null }))
)).concat(groups.map((g, gi) => () =>
  agent(
    `${COMMON}
렌즈: ${REPO}/skills/lens-consistency/SKILL.md 를 읽고 그 「레포 문서 감사에서의 짝」 절대로 적용하라. 산출물 공백과 스코프는 이 감사에서 보지 않는다.
[이름표] ${g.topic}
[정본] ${g.canon}
[정본의 진술] ${JSON.stringify(g.canon_statements.map(s => ({ line: s.line, statement: s.statement, context: s.context, condition: s.condition })))}
[따르는 문서의 진술] ${JSON.stringify(g.other_statements.map(s => ({ file: s.file, line: s.line, statement: s.statement, context: s.context, role: s.role, follows: s.follows, condition: s.condition })))}
범위 문장은 문서마다 하나다 — SKILL.md 이면 frontmatter 의 description, 그 밖이면 첫 문단이다. 정본과 따르는 문서의 범위 문장을 열어 읽어라.
짝(정본 진술 × 따르는 진술)마다 판정은 셋이다 — 어긋남(같은 것을 다르게 정한다. findings 에 발견 하나를 만든다), 좁혀 적음(따르는 쪽이 정본의 규칙을 자기 범위에 적용해 더 좁게 또는 더 자세히 정한다. 정당한 도출이라 발견이 아니다), 같음(정본의 문장을 다른 말로 되풀이할 뿐 더한 것이 없다). 좁혀 적음의 수를 narrowed 에 적어라. 조건이 다른 짝은 어긋남으로 올리지 말고 reason 에 조건을 적어라.`,
    { label: `lens-consistency:${g.topic}${g.split_for ? ':' + g.split_for : ''}`, phase: '리뷰', schema: CONSISTENCY_SCHEMA }
  ).then(res => ({ kind: 'topic', key: 'lens-consistency', target: { path: g.topic, lenses: ['lens-consistency'] }, group: g, res }))
    .catch(() => ({ kind: 'topic', key: 'lens-consistency', target: { path: g.topic, lenses: ['lens-consistency'] }, group: g, res: null }))
))
const reviewCut = reviewJobs.length - CAPS.review
if (reviewCut > 0) log(`⚠️ 리뷰 상한 ${CAPS.review}건을 넘어 렌즈 호출 ${reviewCut}건을 돌리지 않았다 — 이 감사의 커버리지가 그만큼 좁다`)
const reviews = (await parallel(reviewJobs.slice(0, CAPS.review))).filter(Boolean)
for (const r of reviews) if (!r.res) deadLenses.push(r.target.path)
// 발견에 붙은 lens 가 그 문서에 배정된 것이 아니면 배정 밖의 판정이라 버리지 않고 표시만 한다.
// 복제는 판정에서 도출한다 — 같음이면서 정본이 아닌 쪽의 역할이 none 이면 정본을 가리키지 않고 베낀 것이다(SSOT).
const CONSISTENCY_VERDICTS = ['어긋남', '좁혀 적음', '같음']
const consistencyRuns = reviews.filter(r => r.kind === 'topic' && r.res)
run.narrowed = consistencyRuns.reduce((n, r) => n + r.res.narrowed, 0)
const duplication = consistencyRuns.flatMap(r => r.res.pairs
  .filter(p => p.verdict === CONSISTENCY_VERDICTS[2])
  .map(p => ({ p, src: r.group.other_statements.find(s => s.file === p.other_file && s.line === p.other_line) }))
  .filter(x => x.src && x.src.role === 'none')
  .map(x => ({ title: `${x.p.other_file}이(가) 정본 ${r.group.canon}의 문장을 가리키지 않고 베낀다.`, file: `${x.p.other_file}:${x.p.other_line}`, evidence: x.src.statement, principle: 'SSOT', consequence: `정본의 ${r.group.topic} 규칙이 바뀌면 이 문장은 그대로 남아 두 판이 된다.`, detail: x.p.reason, fix: '정본을 가리키는 참조로 바꾼다.', type: 'duplication' })))
const all = reviews.filter(r => r.res).flatMap(r => r.res.findings.map(f => ({
  ...f,
  lens: r.kind === 'doc' ? (r.target.lenses.includes(f.lens) ? f.lens : `${f.lens}(배정 밖)`) : r.key,
  target: r.target.path,
}))).concat(duplication.map(d => ({ ...d, lens: 'lens-consistency', target: '(이름표 묶음)' })))
run.dead_agents.review = deadLenses
log(`리뷰 완료: 호출 ${reviews.length}건에서 원시 발견 ${all.length}건`)
if (deadLenses.length > 0) log(`⚠️ 응답하지 않은 대상 ${deadLenses.length}건: ${deadLenses.join(', ')} — 이 감사의 커버리지가 그만큼 좁다`)

// 기록은 렌즈마다 파일 하나로 갈라 쓰고, 기록자 하나가 여러 대상을 함께 맡는다.
const lensCounter = {}
const reviewFiles = []
for (const r of reviews.filter(x => x.res)) {
  for (const lens of r.target.lenses) {
    lensCounter[lens] = (lensCounter[lens] || 0) + 1
    const mine = r.res.findings.filter(f => (r.kind === 'doc' ? f.lens === lens : true))
    reviewFiles.push({
      name: `${lens}-${lensCounter[lens]}.json`,
      content: { lens, target: r.target.path, ...r.res, findings: mine },
      count: mine.length,
    })
  }
}
const RECORDERS_PER_GROUP = 4
const reviewGroups = []
for (let i = 0; i < reviewFiles.length; i += RECORDERS_PER_GROUP) {
  reviewGroups.push({ key: `묶음${reviewGroups.length + 1}`, files: reviewFiles.slice(i, i + RECORDERS_PER_GROUP) })
}
await recordGrouped('review', reviewGroups)

phase('중복제거')
const raw = all.map((f, i) => ({ raw_index: i, ...f }))
let deduped = raw.map(f => ({ ...f, merged_from: [f.raw_index] }))
if (raw.length > 1) {
  // 넘기는 것은 요약만이다 — 같은 실체인지 가르는 데 필요한 칸만 보내고 본문은 워크플로가 들고 있는다.
  const brief = raw.map(f => ({ raw_index: f.raw_index, lens: f.lens, target: f.target, file: f.file, title: f.title, evidence: String(f.evidence || '').slice(0, 200) }))
  const dd = await agent(
    `다음은 disciplined-coder 저장소 감사에서 여러 렌즈가 낸 원시 발견의 요약 목록(JSON)이다. 항목마다 raw_index 가 있다.
같은 실체(같은 파일의 같은 문제)를 가리키는 발견들을 한 묶음으로 모아라.
묶음마다 그것이 덮는 raw_index 전부를 merged_from 에 적고, 증거와 설명을 남길 대표 하나를 keep 에 적어라 — 증거를 가장 구체적으로 적은 항목을 고른다.
모든 원시 발견은 정확히 한 묶음에 들어가야 한다. 혼자인 발견도 묶음 하나로 낸다.
서로 다른 문제는 절대 합치지 마라. 재판단·신규 발견 추가 금지 — 묶기만 한다. 발견의 본문을 다시 쓰지 마라, 번호만 돌려준다.
${JSON.stringify(brief)}`,
    { label: 'dedup', phase: '중복제거', schema: DEDUP_SCHEMA, effort: 'low' }
  )
  if (!dd) throw new Error('중복제거 에이전트가 응답하지 않았다 — 회차를 실패로 끝낸다')
  const covered = dd.groups.flatMap(g => g.merged_from).sort((a, b) => a - b)
  const expected = raw.map(f => f.raw_index)
  if (JSON.stringify(covered) !== JSON.stringify(expected)) {
    throw new Error(`중복제거가 원시 발견을 잃었다 — 기대 ${JSON.stringify(expected)}, 실제 ${JSON.stringify(covered)}`)
  }
  // 병합은 여기서 한다 — 대표의 본문을 남기고 렌즈와 대상만 쉼표로 잇는다.
  deduped = dd.groups.map(g => {
    const members = g.merged_from.map(i => raw[i])
    const head = g.merged_from.includes(g.keep) ? raw[g.keep] : members[0]
    const join = (k) => [...new Set(members.map(m => m[k]).filter(Boolean))].join(', ')
    return { ...head, lens: join('lens'), target: join('target'), merged_from: g.merged_from }
  })
}
log(`중복 제거 후 ${deduped.length}건 — 반박 검증 시작`)
for (const k of [...new Set(all.map(f => f.lens))]) run.counts_by_lens[k] = { raw: all.filter(f => f.lens === k).length, unique: deduped.filter(f => lensesOf(f).length === 1 && lensesOf(f)[0] === k).length }
await record('dedup', [])

phase('반박검증')
// 검증은 파일 단위로 묶는다. 한 검증자가 그 파일을 한 번 읽고 거기서 나온 발견을 모두 판정한다.
// 상한을 넘는 묶음은 아예 띄우지 않고 미검증으로 남긴다 — 잘랐다는 사실 자체가 기록에 있어야 한다.
const byFile = new Map()
for (const f of deduped) {
  // file 칸은 CLAUDE.md:5 처럼 줄 번호를 달고 온다. 줄 번호까지 열쇠로 쓰면 같은 파일이 줄마다
  // 다른 묶음이 되어 검증자가 파일 수가 아니라 발견 수만큼 뜬다. 경로만 열쇠로 쓴다.
  const k = String(f.file || '(파일 없음)').split(':')[0]
  if (!byFile.has(k)) byFile.set(k, [])
  byFile.get(k).push(f)
}
const verifyGroups = [...byFile.entries()].map(([file, items]) => ({ file, items }))
const toVerify = verifyGroups.slice(0, CAPS.verify)
const overCap = verifyGroups.slice(CAPS.verify)
log(`반박검증: 발견 ${deduped.length}건을 파일 ${verifyGroups.length}개로 묶어 검증자 ${toVerify.length}명을 띄운다`)
if (overCap.length) log(`⚠️ 검증 상한 ${CAPS.verify}묶음을 넘어 ${overCap.length}묶음을 검증하지 않았다 — 미검증으로 기록한다`)
let seq = 0
const numbered = toVerify.map(g => ({ ...g, items: g.items.map(f => ({ ...f, seq: ++seq })) }))
const verified = (await parallel(
  numbered.map((g, gi) => () =>
    agent(
      `너는 회의적 검증자다. 저장소 ${REPO} 의 파일 ${g.file} 를 직접 열어 읽고, 그 파일을 두고 나온 아래 감사 발견을 하나씩 반박하라. 두 가지를 함께 본다.
사실성 — 인용 증거가 실제 파일에 그대로 존재하는가, 발견이 내용을 정확히 기술하는가, 못 본 반증이 있는가.
실질성 — ${REPO}/agent-principles.md 를 읽고, 발견이 인용한 원칙의 실제 정의에 비추어 진짜 위반인가, 예외 조항이나 정당한 설계 선택에 해당하지 않는가, 고치면 실질 이득이 있는가.
둘 중 하나라도 무너지면 isReal=false 이고, 불확실해도 isReal=false 다. 발견마다 n(받은 번호)과 판정과 근거를 적어라. 받은 발견 전부에 판정을 내라 — 빠뜨리면 그 발견은 미판정으로 남는다.
발견 목록: ${JSON.stringify(g.items.map(f => ({ n: f.seq, title: f.title, principle: f.principle, evidence: f.evidence, detail: f.detail, consequence: f.consequence })))}`,
      { label: `verify:${g.file}`, phase: '반박검증', schema: VERDICTS_SCHEMA }
    ).then(res => {
      // 검증자가 죽어 null이 온 것과 실제로 반박한 것은 다르다. 둘을 뭉치면 죽은 표가 '기각'으로 오염된다.
      // 그래서 상태를 셋으로 가른다 — 표가 있고 진짜라면 confirmed, 표가 있는데 반박했으면 rejected,
      // 표가 없으면 undetermined다. 판정(isReal)과 사유를 둘 다 남긴다.
      const byN = new Map((res ? res.verdicts : []).map(v => [v.n, v]))
      return g.items.map(f => {
        const v = byN.get(f.seq)
        const { raw_index, seq, ...rest } = f
        const status = !v ? STATUS[2] : (v.isReal ? STATUS[0] : STATUS[1])
        return { id: findingId(ROUND, seq), ...rest, status, missingVotes: v ? 0 : 1, verdicts: v ? [{ isReal: v.isReal, reason: v.reason }] : [] }
      })
    })
  )
)).filter(Boolean).flat()
const unverified = overCap.flatMap(g => g.items).map(f => {
  const { raw_index, ...rest } = f
  return { id: findingId(ROUND, ++seq), ...rest, status: STATUS[2], missingVotes: 0, over_cap: true, verdicts: [] }
})
const judged = verified.concat(unverified)
run.unverified_over_cap = unverified.length
const confirmed = judged.filter(j => j.status === 'confirmed')
const rejected = judged.filter(j => j.status === 'rejected')
const undetermined = judged.filter(j => j.status === 'undetermined')
log(`반박 검증 완료: 확정 ${confirmed.length}건 · 기각 ${rejected.length}건 · 미판정 ${undetermined.length}건`)
if (undetermined.length > 0) log(`⚠️ 미판정 ${undetermined.length}건 — 이 가운데 ${unverified.length}건은 검증 상한 밖이라 안 띄운 것이고 나머지는 검증자가 응답하지 않은 것이다. 어느 쪽도 반박당한 것이 아니다`)
run.verdict_counts = { confirmed: confirmed.length, rejected: rejected.length, undetermined: undetermined.length, derived: 0 }
run.dead_agents.verify = judged.filter(j => j.missingVotes > 0).map(j => j.id)
const findingsFile = { schema: SCHEMA_VERSION, findings: judged.filter(j => j.status !== STATUS[1]), rejected: rejected.map(r => ({ id: r.id, title: r.title, reasons: r.verdicts.map(v => v.reason) })) }
await record('verify', [])

// ---------- 회차 대조 ----------
// 대조 대상은 셋을 합친 것이다 — 직전 회차 findings.json 의 confirmed·undetermined·derived, 직전 회차 diff.json 의
// 잔존·미판정 전부, 직전 회차 diff.json 의 해소 가운데 전전 회차 diff.json 에서는 해소가 아니었던 것.
phase('대조')
const DIFF_VERDICTS = ['잔존', '해소', '미판정']
let diffFile = { schema: SCHEMA_VERSION, no_prior_round: true, items: [] }
const derivedFindings = []
if (tg.prior_rounds.length > 0) {
  const [prev, prevprev] = tg.prior_rounds
  const pr = await agent(
    `너는 읽기 전용 에이전트다. 직전 회차는 ${prev} 이고 전전 회차는 ${prevprev || '(없음)'} 이다. ${REVIEWS}/${prev}/findings.json 을 열어 status 가 confirmed·undetermined·derived 인 발견의 id·title·file·evidence·consequence·status 를 findings 에 옮겨라(rejected 는 빼라).
${REVIEWS}/${prev}/diff.json 의 items 전부를 diff_items 에 옮겨라(비어 있으면 빈 배열).
${prevprev ? `${REVIEWS}/${prevprev}/diff.json 의 items 의 prior_id 와 verdict 만 prior_diff_items 에 옮겨라.` : 'prior_diff_items 는 빈 배열이다.'}
아무 파일도 쓰지 마라.`,
    { label: 'prior-rounds', phase: '대조', schema: PRIOR_SCHEMA, effort: 'low' }
  )
  if (!pr) throw new Error('직전 회차 읽기 에이전트가 응답하지 않았다 — 회차를 실패로 끝낸다')
  const prevResolved = new Set(pr.prior_diff_items.filter(i => i.verdict === '해소').map(i => i.prior_id))
  const subjects = []
  for (const f of pr.findings) subjects.push({ prior_id: f.id, prior_round: prev, title: f.title, file: f.file, evidence: f.evidence, consequence: f.consequence, was_resolved: false })
  for (const i of pr.diff_items) {
    if (i.verdict === '잔존' || i.verdict === '미판정') subjects.push({ prior_id: i.prior_id, prior_round: i.prior_round, title: i.title, file: i.file, evidence: i.evidence, consequence: i.consequence, was_resolved: false })
    else if (i.verdict === '해소' && !prevResolved.has(i.prior_id)) subjects.push({ prior_id: i.prior_id, prior_round: i.prior_round, title: i.title, file: i.file, evidence: i.evidence, consequence: i.consequence, was_resolved: true })
  }
  const seen = new Set()
  const uniqueSubjects = subjects.filter(s => (seen.has(s.prior_id) ? false : (seen.add(s.prior_id), true)))
  log(`회차 대조: 대상 ${uniqueSubjects.length}건 (직전 ${prev}${prevprev ? `, 그 전 ${prevprev}` : ''})`)
  // 대조도 파일 단위로 묶는다. 한 에이전트가 그 파일을 한 번 열어 거기서 나온 지난 발견을 모두 판정한다.
  const byFile = new Map()
  for (const s of uniqueSubjects) {
    const k = (s.file || '(파일 없음)').split(':')[0]
    if (!byFile.has(k)) byFile.set(k, [])
    byFile.get(k).push(s)
  }
  const diffGroups = [...byFile.entries()].map(([file, list]) => ({ file, list }))
  const items = (await parallel(diffGroups.map(g => () => {
    const sameFile = judged.filter(j => j.status !== STATUS[1] && String(j.file || '').split(':')[0] === g.file).map(j => ({ id: j.id, title: j.title, evidence: j.evidence }))
    const numbered = g.list.map((s, n) => ({ ...s, n: n + 1 }))
    return agent(
      `너는 회차 대조 에이전트다. 앞선 회차에서 나온 발견이 지금 파일에 남아 있는지 판정하라. 항목마다 round 가 어느 회차에서 온 것인지 알려 준다. ${REPO} 의 파일 ${g.file} 을 직접 열어 본다. 아무 파일도 쓰지 마라.
[앞선 회차의 발견 ${numbered.length}건] ${JSON.stringify(numbered.map(s => ({ n: s.n, id: s.prior_id, round: s.prior_round, title: s.title, file: s.file, evidence: s.evidence, consequence: s.consequence })))}
[이번 회차에서 같은 파일에 난 발견] ${JSON.stringify(sameFile)}
판정은 둘이다 — 잔존(문제가 지금 파일에 있다. 어디에 있는지 인용한다. 이번 발견과 같은 실체이면 그 id 를 matched_id 에 적는다), 해소(없다. 무엇이 바뀌었는지 적는다).
받은 발견 전부에 판정을 내고 n 을 그대로 옮겨 적어라 — 빠뜨리면 그 발견은 미판정으로 남는다.`,
      { label: `diff:${g.file}`, phase: '대조', schema: DIFF_VERDICTS_SCHEMA }
    ).then(res => {
      const byN = new Map((res ? res.verdicts : []).map(v => [v.n, v]))
      return numbered.map(s => {
        const v = byN.get(s.n)
        return { ...s, verdict: v ? v.verdict : DIFF_VERDICTS[2], reason: v ? v.reason : '대조 에이전트가 응답하지 않았다', matched_id: v && v.matched_id ? v.matched_id : null }
      })
    })
  }))).filter(Boolean).flat()
  // 재발은 도출이다 — 직전 회차 diff.json 이 해소로 적었던 발견이 이번에 잔존이면 가드 결함 발견을 새로 만든다.
  // id 번호는 반박검증이 쓴 번호 뒤를 잇는다.
  let n = deduped.length
  for (const it of items) {
    if (it.was_resolved && it.verdict === '잔존') {
      n += 1
      derivedFindings.push({ id: findingId(ROUND, n), lens: 'round-diff', title: '이것을 막는 검사가 없다', file: it.file, evidence: `${it.prior_id} → ${it.matched_id || '(이번 회차 짝 없음)'}`, principle: 'FAIL-LOUD', consequence: `해소로 판정됐던 ${it.title}이(가) 다시 잔존한다. 검사가 없으면 고쳐도 되돌아온다.`, detail: it.reason, status: STATUS[3], missingVotes: 0, verdicts: [] })
    }
  }
  diffFile = { schema: SCHEMA_VERSION, no_prior_round: false, items: items.map(({ was_resolved, n: _n, ...rest }) => rest) }
  run.dead_agents.diff = items.filter(i => i.verdict === DIFF_VERDICTS[2]).map(i => i.prior_id)
} else {
  log('대조할 직전 회차 없음')
}
run.verdict_counts.derived = derivedFindings.length
findingsFile.findings.push(...derivedFindings)
await recordGrouped('diff', [{ key: '판정', files: [
  { name: 'findings.json', content: findingsFile, count: findingsFile.findings.length, ids: findingsFile.findings.map(f => f.id), chunked: true },
  { name: 'diff.json', content: diffFile, count: diffFile.items.length },
] }])

const machine = await machinePromise
run.machine_checks = machine ? { allPassed: machine.allPassed, results: machine.results } : null
run.commit = machine ? machine.commit : null
run.tree_clean = machine ? machine.tree_clean : null
if (!machine) run.dead_agents.machine = true
await record('machine-checks', [])

phase('집계')
const aggregate = await agent(
  `너는 집계자다. ${REPO}/skills/meta-aggregate/SKILL.md 를 읽고 그 방식대로, 아래 자기감사 결과의 구조적 건강성을 점검하라 — 확정 발견 간 상충(같은 곳을 두고 반대로 판정한 짝)과 커버리지 공백(봤어야 하는데 아무도 안 본 대상이나 렌즈)과 전체 판정. 발견 내용 재판단은 금지(검증 단계가 끝냈다).
먼저 ${REPO} 에서 git rev-parse HEAD 와 git status --porcelain 을 다시 실행해 commit 과 tree_clean 에 적어라. 다만 이번 회차가 쓴 경로로 시작하는 줄은 세지 않는다 — docs/superpowers/reviews/${ROUND} 와 docs/superpowers/reviews/${ROUND}.md 가 그것이고, 회차 자신의 출력이라 감사 도중의 변경이 아니다. 그 줄을 뺀 뒤 남는 줄이 없으면 tree_clean 은 참이다. 아래 기계 검사의 지문과 다르면 「감사 도중 작업 트리가 바뀌었다 — 이 회차의 판정은 움직인 작업 트리에 대한 것이다」를 verdict 첫 문장으로 적어라.
기계 검사: ${JSON.stringify(run.machine_checks)} (commit ${run.commit}, tree_clean ${run.tree_clean})
확정 발견 (${confirmed.length}건): ${JSON.stringify(confirmed)}
기각 (${rejected.length}건): ${JSON.stringify(findingsFile.rejected)}
미판정 (${undetermined.length}건 — 이 가운데 ${unverified.length}건은 검증 상한 ${CAPS.verify}묶음 밖이라 검증자를 띄우지 않은 것이고 나머지는 검증자가 응답하지 않은 것이다. 반박당한 것이 아니니 커버리지 공백으로 다뤄라): ${JSON.stringify(undetermined.map(r => ({ id: r.id, title: r.title })))}
응답하지 않은 렌즈 호출: ${JSON.stringify(deadLenses)}`,
  { label: 'meta-aggregate', phase: '집계', schema: AGGREGATE_SCHEMA }
)
if (!aggregate) run.dead_agents.aggregate = true
run.tree_changed = !!(aggregate && machine && (aggregate.commit !== machine.commit || aggregate.tree_clean !== machine.tree_clean))
await record('aggregate', [])

// ---------- 요약문 ----------
// 세 파일에서 도출되는 사실만 적는다. 되풀이되는 뿌리와 사용자에게 올릴 물음은 판단이라 호출자가 끝에 붙인 뒤 봉인한다.
const line = (t) => `- ${t}`
const summary = [
  `# 자기감사 회차 ${ROUND}`,
  '',
  `실행체 ${EXECUTOR}(스키마 ${SCHEMA_VERSION})가 커밋 ${run.commit || '(측정 실패)'}${run.tree_clean === false ? '(작업 트리에 미커밋 변경 있음)' : ''} 위에서 돌았다. 확정 ${confirmed.length}건, 기각 ${rejected.length}건, 미판정 ${undetermined.length}건, 도출 ${derivedFindings.length}건이다.${unverified.length ? ` 미판정 가운데 ${unverified.length}건은 검증 상한 ${CAPS.verify}묶음을 넘어 검증자를 띄우지 않은 것이다.` : ''}${run.tree_changed ? ' 감사 도중 작업 트리가 바뀌었다.' : ''} 구조화된 기록은 같은 이름의 폴더에 있다.`,
  '',
  '## 범위와 배정',
  '',
  ...tg.targets.map(t => line(`\`${t.path}\` — ${t.lenses.join(', ') || '(문서별 렌즈 없음)'}. ${t.reason}`)),
  line(`전체 렌즈 — ${WHOLE_LENSES.map(w => w.key).join(', ')}`),
  line(`조각 ${tg.fragments.length}개, 문턱 ${tg.limit}자`),
  line(`이름표 묶음 ${run.topic_groups}개, 좁혀 적음 ${run.narrowed}건, 빈 이름표 진술 ${run.unlabeled}건${oversize.length ? `, 문턱을 넘는 묶음 ${oversize.length}개` : ''}`),
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
  ...(diffFile.no_prior_round ? [line('대조할 직전 회차 없음')] : [line(`잔존 ${diffFile.items.filter(i => i.verdict === '잔존').length}건, 해소 ${diffFile.items.filter(i => i.verdict === '해소').length}건, 미판정 ${diffFile.items.filter(i => i.verdict === '미판정').length}건`)]),
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
