export const meta = {
  name: 'prior-art-search',
  description: '하위 질문마다 연구자를 실행하고 인용을 검증자로 판정해 통과한 선행 사례만 모은다',
  whenToUse: 'agent-prior-art 오케스트레이터가 사용자가 승인한 프로토콜로만 실행한다.',
  phases: [
    { title: 'Research' },
    { title: 'Verify' },
    { title: 'Synthesize' },
    { title: 'MapCheck' },
  ],
};

// 본문은 후속 태스크가 채운다. 스키마 상수는 최상위 const 로 두지 않고 schemas() 가 만든다.
// 시험 도구가 본문보다 먼저 판정 함수를 부르므로 const 를 초기화 전에 참조하면 예외가 나기 때문이다.
schemas();
return null;

// 질의 경계 검사. output 이 null 이 아닌 연구자의 검색어마다 금지어와 경로 형태를 본다.
// 한 검색어 안에서는 forbidden-term 원소가 path-shape 원소보다 앞이다.
function checkQueries(researchers, forbiddenTerms) {
  const terms = (forbiddenTerms ?? []).map((w) => String(w ?? '').toLowerCase()).filter((w) => w !== '');
  const found = [];
  for (const r of researchers) {
    if (r.output == null) continue;
    for (const q of r.output.queries ?? []) {
      const query = String(q ?? '');
      const lower = query.toLowerCase();
      if (terms.some((w) => lower.includes(w))) found.push({ id: r.id, query, rule: 'forbidden-term' });
      const isPath = query.split(/\s+/).some((tok) => {
        const t = tok.replace(/^["'`()\[\],.:;]+|["'`()\[\],.:;]+$/g, '');
        return /^(~\/|\.\.?\/|\/)/.test(t) || /^[A-Za-z]:[\\/]/.test(t) ||
          (/[\\/]/.test(t) && /\.[A-Za-z][^.\\/]{0,4}$/.test(t));
      });
      if (isPath) found.push({ id: r.id, query, rule: 'path-shape' });
    }
  }
  return found;
}

// URL 묶기. 항목은 하위 질문 차례, 이슈, 근거 지도 행의 차례로 만든다.
// 선행 서술이 결측인 항목은 items 에 남기고 어느 묶음의 claims 에도 넣지 않는다.
function groupByUrl(researchers) {
  const items = [];
  for (const r of researchers) {
    if (r.output == null) continue;
    (r.output.issues ?? []).forEach((issue, i) => {
      const urls = [];
      for (const c of issue.citations ?? []) {
        const u = String(c.url ?? '');
        if (u !== '' && !urls.includes(u)) urls.push(u);
      }
      items.push({ ref: `${r.id}#issue#${i}`, urls, text: String(issue.prior_claim ?? '') });
    });
    (r.output.evidence_map ?? []).forEach((row, j) => {
      const u = String(row.url ?? '');
      const ax = row.axes ?? {};
      const prior = {
        purpose: ax.purpose?.prior,
        mechanism: ax.mechanism?.prior,
        evaluation: ax.evaluation?.prior,
        target: ax.target?.prior,
      };
      items.push({
        ref: `${r.id}#case#${j}`,
        urls: u === '' ? [] : [u],
        text: JSON.stringify({ case: row.case, outcome: row.outcome, prior }),
        row,
      });
    });
  }
  const groups = [];
  for (const item of items) {
    if (lacksPrior(item)) continue;
    const sub = item.ref.slice(0, item.ref.indexOf('#'));
    for (const url of item.urls) {
      let g = groups.find((x) => x.url === url);
      if (!g) {
        g = { url, subquestions: [], claims: [] };
        groups.push(g);
      }
      if (!g.subquestions.includes(sub)) g.subquestions.push(sub);
      g.claims.push({ ref: item.ref, text: item.text });
    }
  }
  return { items, groups };
}

// 통과 판정. 행선지는 항목마다 위 행부터 차례로 정한다.
// 검증자가 실패한 URL 은 응답이 없거나 null 이거나 보낸 참조의 판정을 빠뜨린 URL 이다.
function classify(items, verifiers) {
  const sent = new Map();
  for (const item of items) {
    if (lacksPrior(item)) continue;
    for (const url of item.urls) {
      if (!sent.has(url)) sent.set(url, []);
      sent.get(url).push(item.ref);
    }
  }
  const failed = new Set();
  const verdicts = new Map();
  for (const [url, refs] of sent) {
    const v = verifiers.find((x) => x.url === url);
    const judgments = v?.output?.judgments;
    if (!Array.isArray(judgments) || refs.some((ref) => !judgments.some((j) => j.ref === ref))) {
      failed.add(url);
      continue;
    }
    for (const j of judgments) {
      if (!refs.includes(j.ref)) continue;
      if (!verdicts.has(j.ref)) verdicts.set(j.ref, []);
      verdicts.get(j.ref).push(j.verdict);
    }
  }
  const passed = [];
  const rejected = [];
  const unverifiable = [];
  for (const item of items) {
    const entry = { ref: item.ref, urls: item.urls };
    if (lacksPrior(item)) {
      rejected.push(entry);
      continue;
    }
    const vs = verdicts.get(item.ref) ?? [];
    if (vs.includes('supported')) passed.push(entry);
    else if (item.urls.some((u) => failed.has(u))) continue;
    else if (vs.length > 0 && vs.every((v) => v === 'unverifiable')) unverifiable.push(entry);
    else rejected.push(entry);
  }
  const verify_failed = [];
  for (const [url, refs] of sent) {
    if (failed.has(url)) verify_failed.push({ url, refs });
  }
  return { passed, rejected, unverifiable, verify_failed };
}

// 상태 합치기. 참조가 하위 질문 X 에 속하는지는 `X#` 로 시작하는지로 본다.
function mergeStatus(researchers, items, classified) {
  const coverage = [];
  const subquestion_status = [];
  for (const r of researchers) {
    const mine = (ref) => ref.startsWith(`${r.id}#`);
    coverage.push({
      id: r.id,
      cases_found: items.filter((it) => mine(it.ref)).length,
      passed: classified.passed.filter((it) => mine(it.ref)).length,
    });
    subquestion_status.push({
      id: r.id,
      search_status: r.output == null ? 'failed' : r.output.search_status,
      verification_status: classified.verify_failed.some((f) => f.refs.some(mine)) ? 'partial' : 'ok',
    });
  }
  const overall_status = subquestion_status.every(
    (s) => s.search_status === 'ok' && s.verification_status === 'ok',
  ) ? 'ok' : 'not-ok';
  return { coverage, subquestion_status, overall_status };
}

// 선행 서술 결측 판정. 이슈 항목은 text 가 공백뿐이면 참이다.
// 근거 지도 항목은 row.case 가 공백뿐이거나 네 축의 prior 가 모두 공백뿐이면 참이다.
function lacksPrior(item) {
  const blank = (v) => String(v ?? '').trim() === '';
  if (item.row == null) return blank(item.text);
  const ax = item.row.axes ?? {};
  return blank(item.row.case) ||
    ['purpose', 'mechanism', 'evaluation', 'target'].every((k) => blank(ax[k]?.prior));
}

// 네 스키마 상수를 한 객체로 돌려준다. 계약 테스트와 본문이 이 함수로 상수를 읽는다.
function schemas() {
  const str = { type: 'string' };
  const axis = {
    type: 'object',
    properties: { prior: str, same: { type: 'boolean' }, note: str },
    required: ['prior', 'same', 'note'],
  };
  const axes = {
    type: 'object',
    properties: { purpose: axis, mechanism: axis, evaluation: axis, target: axis },
    required: ['purpose', 'mechanism', 'evaluation', 'target'],
  };
  const row = (axesSchema) => ({
    type: 'object',
    properties: { case: str, url: str, outcome: str, axes: axesSchema },
    required: ['case', 'url', 'axes', 'outcome'],
  });
  const principles = { type: 'array', items: str };
  const RESEARCHER_SCHEMA = {
    type: 'object',
    properties: {
      search_status: { type: 'string', enum: ['ok', 'no-results', 'failed', 'not-attempted'] },
      queries: { type: 'array', items: str },
      issues: {
        type: 'array',
        items: {
          type: 'object',
          properties: {
            prior_claim: str,
            citations: { type: 'array', items: { type: 'object', properties: { url: str } } },
          },
          required: ['prior_claim', 'citations'],
        },
      },
      evidence_map: { type: 'array', items: row(axes) },
    },
    required: ['search_status', 'queries', 'issues'],
  };
  const VERIFIER_SCHEMA = {
    type: 'object',
    properties: {
      url: str,
      judgments: {
        type: 'array',
        items: {
          type: 'object',
          properties: {
            ref: str,
            verdict: { type: 'string', enum: ['supported', 'unsupported', 'unverifiable'] },
            quote: str,
            reason: str,
          },
          required: ['ref', 'verdict', 'quote', 'reason'],
        },
      },
      principles_applied: principles,
    },
    required: ['url', 'judgments', 'principles_applied'],
  };
  const SYNTHESIS_SCHEMA = {
    type: 'object',
    properties: {
      evidence_map: { type: 'array', items: row({ type: 'object' }) },
      conclusions: {
        type: 'array',
        items: {
          type: 'object',
          properties: { text: str, refs: { type: 'array', items: str } },
          required: ['text', 'refs'],
        },
      },
      principles_applied: principles,
    },
    required: ['evidence_map', 'conclusions', 'principles_applied'],
  };
  const MAP_SCHEMA = {
    type: 'object',
    properties: {
      cells: {
        type: 'array',
        items: {
          type: 'object',
          properties: { row: str, column: str, grounded: { type: 'boolean' }, source_ref: str },
          required: ['row', 'column', 'grounded', 'source_ref'],
        },
      },
      principles_applied: principles,
    },
    required: ['cells', 'principles_applied'],
  };
  return { RESEARCHER_SCHEMA, VERIFIER_SCHEMA, SYNTHESIS_SCHEMA, MAP_SCHEMA };
}
