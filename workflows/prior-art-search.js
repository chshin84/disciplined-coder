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

// 본문. 스키마 상수는 최상위 const 로 두지 않고 schemas() 가 만든다.
// 시험 도구가 본문보다 먼저 판정 함수를 부르므로 const 를 초기화 전에 참조하면 예외가 나기 때문이다.
// 단계 사이에는 parallel() 장벽을 둔다. thunk 는 agent() 의 반환만 돌려주고, 짝짓기는 반환 배열의 위치로 한다.
const S = schemas();
const RESEARCHER = 'disciplined-coder:prior-art-researcher';
const EXTRACTOR = 'disciplined-coder:prior-art-verifier';
const JUDGE = 'disciplined-coder:prior-art-judge';
const MAPCHECK = 'disciplined-coder:prior-art-mapcheck';
// 판정 묶음 하나에 넣는 주장 수의 상한이다. 값의 근거는 spec 「Opus 일괄 판정」의 묶음 크기다.
const BATCH_SIZE = 20;

// 둘러보기 실행(round 0)은 연구자 하나를 scout 모드로 실행하고, 검증과 종합 없이 질의 경계 검사만 거쳐 반환한다.
// parallel 로 감싸는 이유는 연구자 호출과 같이 실패한 호출을 null 로 받기 위해서다.
if (args.round === 0) {
  phase('Research');
  const scout = (await parallel([() => agent(
    prompt('scout', args.principles_path, {
      question: args.question,
      situation: args.situation,
      target: args.target,
      intended_use: args.intended_use,
      constraints: args.constraints,
      draft_subquestions: args.subquestions,
      forbidden_terms: args.forbidden_terms,
    }),
    { agentType: RESEARCHER, label: 'scout', phase: 'Research', schema: S.SCOUT_SCHEMA },
  )]))[0] ?? null;
  const scoutResearchers = [{ id: 'scout', output: scout }];
  return {
    round: args.round,
    researchers: scoutResearchers,
    query_violations: checkQueries(scoutResearchers, args.forbidden_terms),
    scout,
  };
}

phase('Research');
const researchOut = await parallel(args.subquestions.map((sq) => () => agent(
  prompt('explore', args.principles_path, {
    question: args.question,
    situation: args.situation,
    target: args.target,
    mode: args.mode,
    subquestion: sq,
    forbidden_terms: args.forbidden_terms,
    intended_use: args.intended_use,
    constraints: args.constraints,
  }),
  { agentType: RESEARCHER, label: `research:${sq.id}`, phase: 'Research', schema: S.RESEARCHER_SCHEMA },
)));
const researchers = args.subquestions.map((sq, i) => ({ id: sq.id, output: researchOut[i] ?? null }));
const query_violations = checkQueries(researchers, args.forbidden_terms);
const { items, groups } = groupByUrl(researchers);

// 검증은 네 단계다. URL 마다 추출하고, 추출을 통과한 주장만 묶음으로 모아 판정한다. 정보 부족이 있고 불일치가 없는 주장은
// 추출 검증자가 URL 마다 원문을 다시 열어 보충하고(refetch), 보충 구절을 다시 묶음으로 모아 판정한다(rejudge).
// 판정 묶음 출력은 splitByUrl 로 URL 마다 나누고, 단계 출력은 URL 을 키로 둔 객체에 모아 mergeStages 가 인용 판정 출력 형식으로 합친다.
phase('Verify');
const refsByUrl = {};
const extract = {};
const refetch = {};
const extractOut = await parallel(groups.map((g) => () => agent(
  prompt('extract', args.principles_path, { url: g.url, claims: g.claims }),
  { agentType: EXTRACTOR, label: `extract:${g.url}`, phase: 'Verify', schema: S.EXTRACT_SCHEMA },
)));
groups.forEach((g, i) => {
  refsByUrl[g.url] = g.claims.map((c) => c.ref);
  extract[g.url] = extractOut[i] ?? null;
});
const judgeIn = {};
groups.forEach((g) => { judgeIn[g.url] = judgeClaims(g.claims, extract[g.url]); });
const judgeBatches = batchClaims(judgeIn, BATCH_SIZE);
const judgeOut = await parallel(judgeBatches.map((b, i) => () => agent(
  prompt('judge', args.principles_path, b),
  { agentType: JUDGE, label: `judge:${i + 1}`, phase: 'Verify', schema: S.JUDGE_SCHEMA },
)));
const judge = splitByUrl(judgeOut, judgeBatches);
const refetchJobs = judgeBatches.flatMap((b) => b.items)
  .map((x) => ({ url: x.url, claims: refetchClaims(x.claims, judge[x.url]) }))
  .filter((x) => x.claims.length > 0);
const refetchOut = await parallel(refetchJobs.map((x) => () => agent(
  prompt('refetch', args.principles_path, { url: x.url, claims: x.claims }),
  { agentType: EXTRACTOR, label: `refetch:${x.url}`, phase: 'Verify', schema: S.EXTRACT_SCHEMA },
)));
refetchJobs.forEach((x, i) => { refetch[x.url] = refetchOut[i] ?? null; });
const rejudgeIn = {};
refetchJobs.forEach((x) => { rejudgeIn[x.url] = rejudgeClaims(x.claims, refetch[x.url]); });
const rejudgeBatches = batchClaims(rejudgeIn, BATCH_SIZE);
const rejudgeOut = await parallel(rejudgeBatches.map((b, i) => () => agent(
  prompt('judge', args.principles_path, b),
  { agentType: JUDGE, label: `rejudge:${i + 1}`, phase: 'Verify', schema: S.JUDGE_SCHEMA },
)));
const rejudge = splitByUrl(rejudgeOut, rejudgeBatches);
const { outputs, stages } = mergeStages(refsByUrl, extract, judge, refetch, rejudge);
const verifiers = groups.map((g) => ({
  url: g.url, subquestions: g.subquestions, output: outputs[g.url], stages: stages[g.url],
}));

const classified = classify(items, verifiers);
const merged = mergeStatus(researchers, items, classified);

const result = {
  round: args.round,
  passed: classified.passed,
  rejected: classified.rejected,
  unverifiable: classified.unverifiable,
  verify_failed: classified.verify_failed,
  coverage: merged.coverage,
  subquestion_status: merged.subquestion_status,
  overall_status: merged.overall_status,
  query_violations,
  verifier_count: verifiers.length,
  researchers,
  verifiers,
};

if (args.mode === 'survey') {
  // 통과한 근거 지도 행만 종합의 입력이다. 이슈 항목은 row 가 없어 제외한다.
  const passed_rows = classified.passed
    .filter((p) => p.ref.includes('#case#'))
    .map((p) => ({ ref: p.ref, row: items.find((it) => it.ref === p.ref).row }));
  let synthesis = null;
  let map_check = null;
  if (passed_rows.length > 0) {
    phase('Synthesize');
    synthesis = await agent(
      prompt('synthesize', args.principles_path, { question: args.question, target: args.target, intended_use: args.intended_use, constraints: args.constraints, passed_rows }),
      { agentType: RESEARCHER, label: 'synthesize', phase: 'Synthesize', schema: S.SYNTHESIS_SCHEMA },
    );
  }
  if (synthesis != null) {
    phase('MapCheck');
    map_check = await agent(
      prompt('map', args.principles_path, { evidence_map: synthesis.evidence_map, passed: passed_rows }),
      { agentType: MAPCHECK, label: 'map-check', phase: 'MapCheck', schema: S.MAP_SCHEMA },
    );
  }
  result.synthesis = synthesis;
  result.map_check = map_check;
}
return result;

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
        // `/` 하나로 시작하는 토큰은 구분자가 하나 더 있어야 경로다. `/deep-research` 같은 명령 이름은 경로가 아니다.
        return /^(~\/|\.\.?\/)/.test(t) || /^\/[^\/]+\//.test(t) || /^[A-Za-z]:[\\/]/.test(t) ||
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
        purpose: String(ax?.purpose?.prior ?? ''),
        mechanism: String(ax?.mechanism?.prior ?? ''),
        evaluation: String(ax?.evaluation?.prior ?? ''),
        target: String(ax?.target?.prior ?? ''),
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
// verdict 가 verify_failed 인 판정은 그 주장만 그 URL 에서 검증 실패로 두고, 같은 URL 의 다른 판정은 그대로 분류한다.
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
  const claimFailed = new Map();
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
      if (j.verdict === 'verify_failed') {
        if (!claimFailed.has(url)) claimFailed.set(url, []);
        claimFailed.get(url).push(j.ref);
        continue;
      }
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
    else if (item.urls.some((u) => failed.has(u) || (claimFailed.get(u) ?? []).includes(item.ref))) continue;
    else if (vs.length > 0 && vs.every((v) => v === 'unverifiable')) unverifiable.push(entry);
    else rejected.push(entry);
  }
  const verify_failed = [];
  for (const [url, refs] of sent) {
    if (failed.has(url)) verify_failed.push({ url, refs });
    else if (claimFailed.has(url)) verify_failed.push({ url, refs: refs.filter((r) => claimFailed.get(url).includes(r)) });
  }
  return { passed, rejected, unverifiable, verify_failed };
}

// 판정 칸의 이름이다. 시험 도구가 본문보다 먼저 판정 함수를 부르므로 최상위 const 대신 함수로 둔다.
function judgeCells() {
  return ['numbers_conditions', 'direction', 'scope'];
}

// 판정 칸이 정해진 값인지 본다. 빠지거나 다른 값이면 칸 누락이다.
function isMatch(v) {
  return ['일치', '불일치', '판정 불가', '정보 부족'].includes(v);
}

// 판정 하나의 세 칸이 모두 정해진 값인지 본다.
function cellsOk(j) {
  return judgeCells().every((k) => isMatch(j[k]));
}

// 추출 출력에서 refs 의 판정을 ref 마다 하나씩 찾아 Map 으로 돌려준다. 판정이 배열이 아니거나,
// 한 ref 라도 판정이 없으면 null 이다. null 은 추출이 그 URL 에서 실패했다는 뜻이다.
function judgmentsByRef(refs, output) {
  const judgments = output?.judgments;
  if (!Array.isArray(judgments)) return null;
  const found = new Map();
  for (const ref of refs) {
    const j = judgments.find((x) => x.ref === ref);
    if (j == null) return null;
    found.set(ref, j);
  }
  return found;
}

// 단계 출력에서 ref 하나의 판정을 찾는다. 출력이 없거나 그 ref 의 판정이 없으면 null 이다.
// 보충과 재판정은 주장 하나만 실패로 두므로 URL 단위의 judgmentsByRef·judgedRefs 대신 이 함수로 찾는다.
function judgmentOf(output, ref) {
  const judgments = output?.judgments;
  if (!Array.isArray(judgments)) return null;
  return judgments.find((x) => x.ref === ref) ?? null;
}

// 추출을 통과해 판정에 보낼 주장인지 본다. access 가 성공이고 exists 가 일치이고 quote 가 있어야 한다.
// 보충 출력도 같은 기준으로 본다.
function passesExtract(e) {
  return e.access === '성공' && e.exists === '일치' && String(e.quote ?? '').trim() !== '';
}

// 판정 입력의 주장 하나다. 추출(또는 보충) 판정 e 의 quote·context 와 존재 확인 사유를 붙인다.
// 추출의 reason 은 quote 밖의 원문을 포함할 수 있으므로 넣지 않는다.
function toJudgeClaim(c, e) {
  return { ref: c.ref, text: c.text, quote: e.quote, context: e.context ?? '', source_note: e.exists_note ?? '' };
}

// 판정 입력의 claims 다. 추출이 실패한 URL 은 판정하지 않으므로 빈 배열이다.
function judgeClaims(claims, extractOutput) {
  const ex = judgmentsByRef(claims.map((c) => c.ref), extractOutput);
  if (ex == null) return [];
  return claims.filter((c) => passesExtract(ex.get(c.ref))).map((c) => toJudgeClaim(c, ex.get(c.ref)));
}

// 판정 하나의 다음 차례다. 불일치가 있으면 unsupported, 정보 부족이 있으면 refetch, 판정 불가가 있으면 unsupported,
// 셋 다 없으면 supported 다. 불일치를 먼저 보므로 불일치가 있는 주장은 보충을 하지 않는다.
// 판정 불가는 구절이 주장을 뒷받침한다는 확인이 없으므로 기각한다. 이유 유형은 mergeUrl 이 reason 에 남긴다.
function nextStep(j) {
  const cells = judgeCells().map((k) => j[k]);
  if (cells.includes('불일치')) return 'unsupported';
  if (cells.includes('정보 부족')) return 'refetch';
  if (cells.includes('판정 불가')) return 'unsupported';
  return 'supported';
}

// 주장 하나의 판정 차례다. j 는 세 칸이 정해진 처음 판정, rf 와 rj 는 그 주장의 보충·재판정 판정(없으면 null)이다.
// step 은 supported·unsupported·verify_failed 중 하나이고, j 는 step 을 정한 판정(검증 실패면 null)이다.
// 보충이 없거나 보충 출력이 추출 기준을 통과하지 못하거나, 재판정이 없거나 칸이 빠지거나, 재판정도 정보 부족이면 verify_failed 다.
function routeClaim(j, rf, rj) {
  const first = nextStep(j);
  if (first !== 'refetch') return { step: first, j };
  if (rf == null || !passesExtract(rf)) return { step: 'verify_failed', j: null };
  if (rj == null || !cellsOk(rj)) return { step: 'verify_failed', j: null };
  const second = nextStep(rj);
  return { step: second === 'refetch' ? 'verify_failed' : second, j: rj };
}

// 판정 출력에서 refs 중 판정이 있는 ref 의 판정을 Map 으로 돌려준다. 판정이 빠진 ref 는 Map 에 없고, 그 주장만 검증 실패가 된다.
// 판정이 배열이 아니거나, 있는 판정 중 하나라도 칸이 빠지면 null 이다. null 은 판정이 그 URL 에서 실패했다는 뜻이다.
function judgedRefs(refs, output) {
  const judgments = output?.judgments;
  if (!Array.isArray(judgments)) return null;
  const found = new Map();
  for (const ref of refs) {
    const j = judgments.find((x) => x.ref === ref);
    if (j == null) continue;
    if (!cellsOk(j)) return null;
    found.set(ref, j);
  }
  return found;
}

// 보충 입력의 claims 다. 처음 판정에 정보 부족이 있고 불일치가 없는 주장만 고르고, 판정의 missing 을 붙인다.
// 판정이 실패한 URL 은 빈 배열이다.
function refetchClaims(claims, judgeOutput) {
  const ju = judgedRefs(claims.map((c) => c.ref), judgeOutput);
  if (ju == null) return [];
  return claims
    .filter((c) => ju.has(c.ref) && nextStep(ju.get(c.ref)) === 'refetch')
    .map((c) => ({ ref: c.ref, text: c.text, missing: ju.get(c.ref).missing ?? {} }));
}

// 재판정 입력의 claims 다. 보충 출력이 추출 기준을 통과한 주장만 고르고, 보충 구절로 판정 입력을 만든다.
function rejudgeClaims(claims, refetchOutput) {
  return claims
    .filter((c) => { const f = judgmentOf(refetchOutput, c.ref); return f != null && passesExtract(f); })
    .map((c) => toJudgeClaim(c, judgmentOf(refetchOutput, c.ref)));
}

// 판정 묶음 만들기. claimsByUrl 은 URL 을 키로 둔 판정 입력 claims 이고, 키 차례대로 앞 묶음부터 채운다.
// 묶음 하나의 주장은 size 개 이하이고 한 URL 의 주장은 한 묶음에 둔다. 한 URL 의 주장이 size 개를 넘으면 그 URL 만으로 묶음 하나다.
// 주장이 없는 URL 은 넣지 않는다. 반환값의 원소는 판정 입력 { items: [{ url, claims }] } 그대로다.
function batchClaims(claimsByUrl, size) {
  const batches = [];
  let cur = null;
  let count = 0;
  for (const [url, claims] of Object.entries(claimsByUrl)) {
    if (claims.length === 0) continue;
    if (cur == null || count + claims.length > size) {
      cur = { items: [] };
      batches.push(cur);
      count = 0;
    }
    cur.items.push({ url, claims });
    count += claims.length;
  }
  return batches;
}

// 묶음 출력 나누기. batchOutputs[i] 는 batches[i] 의 출력이다. 반환값은 URL 을 키로 둔 { judgments, principles_applied } 다.
// 응답이 없거나 judgments 가 배열이 아닌 묶음의 URL 은 null 이다. 판정은 url 과 ref 가 그 URL 의 입력 주장과 맞는 것만 남기고,
// 입력에 없던 URL 이나 ref 의 판정은 버린다. 같은 (url, ref) 의 판정이 둘 이상이면 어느 판정을 믿을지 정할 수 없으므로
// 그 ref 의 판정을 모두 버린다. 버린 주장은 빠진 주장과 같이 그 주장만 검증 실패가 된다.
function splitByUrl(batchOutputs, batches) {
  const out = {};
  batches.forEach((b, i) => {
    const o = batchOutputs[i] ?? null;
    const ok = o != null && Array.isArray(o.judgments);
    for (const it of b.items) {
      if (!ok) {
        out[it.url] = null;
        continue;
      }
      const refs = it.claims.map((c) => c.ref);
      const mine = o.judgments.filter((j) => j != null && j.url === it.url && refs.includes(j.ref));
      out[it.url] = {
        judgments: mine.filter((j) => mine.filter((x) => x.ref === j.ref).length === 1),
        principles_applied: o.principles_applied ?? [],
      };
    }
  });
  return out;
}

// 단계 합치기. 인자와 반환값은 모두 URL 을 키로 둔 일반 객체다. 단계 객체에 키가 없는 URL 은 그 단계를 실행하지 않은 URL 이다.
// judge 와 rejudge 는 묶음 출력을 splitByUrl 로 나눈 값이고, 묶음이 실패한 URL 의 값은 null 이다.
// outputs[url] 이 null 이면 그 URL 은 검증 실패이고, 주장 하나만 실패하면 그 판정의 verdict 가 verify_failed 다.
// stages[url] 은 네 단계의 원본이며, 실행하지 않은 단계는 null 이다.
function mergeStages(refsByUrl, extract, judge, refetch, rejudge) {
  const outputs = {};
  const stages = {};
  for (const [url, refs] of Object.entries(refsByUrl)) {
    const st = {
      extract: extract[url] ?? null,
      judge: judge[url] ?? null,
      refetch: refetch[url] ?? null,
      rejudge: rejudge[url] ?? null,
    };
    stages[url] = st;
    outputs[url] = mergeUrl(url, refs, st);
  }
  return { outputs, stages };
}

// URL 하나의 합치기다. spec 「최종 판정과 실패 처리」와 「충분성 판단과 보충·Opus 상향」(이 절의 상향 부분은 「Opus 일괄 판정」이 대체했다), 「Opus 일괄 판정」의 차례로 verdict 를 정하고,
// URL 검증 실패이면 null 이다. 처음 판정의 무응답과 칸 누락은 URL 검증 실패이고, 처음 판정에서 빠진 주장과 보충·재판정의 실패는
// 그 주장만 verify_failed 다. 끝까지 판정 불가가 남은 주장은 unsupported 이고, 판정 불가 칸의 이유 유형을 reason 에 남긴다.
// quote 는 보충 출력이 추출 기준을 통과했으면 보충 구절이고, 아니면 추출 구절이다. reason 은 단계 이름을 붙인 이유를 ' / ' 로 이어 붙인다.
function mergeUrl(url, refs, st) {
  const exBy = judgmentsByRef(refs, st.extract);
  if (exBy == null) return null;
  const toJudge = refs.filter((r) => passesExtract(exBy.get(r)));
  const juBy = toJudge.length > 0 ? judgedRefs(toJudge, st.judge) : new Map();
  if (juBy == null) return null;
  const judgments = refs.map((ref) => {
    const e = exBy.get(ref);
    const reasons = [`추출: ${e.reason ?? ''}`];
    let quote = String(e.quote ?? '');
    const out = (verdict) => ({ ref, verdict, quote, reason: reasons.join(' / ') });
    if (e.access === '실패') return out('unverifiable');
    if (!passesExtract(e)) return out('unsupported');
    if (!juBy.has(ref)) {
      reasons.push('판정: 판정 출력에 이 주장이 없다');
      return out('verify_failed');
    }
    const j = juBy.get(ref);
    reasons.push(`판정: ${j.reason ?? ''}`);
    if (nextStep(j) === 'refetch') {
      const f = judgmentOf(st.refetch, ref);
      const g = judgmentOf(st.rejudge, ref);
      if (f != null) reasons.push(`보충: ${f.reason ?? ''}`);
      if (f != null && passesExtract(f)) quote = String(f.quote ?? '');
      if (g != null) reasons.push(`재판정: ${g.reason ?? ''}`);
    }
    const route = routeClaim(j, judgmentOf(st.refetch, ref), judgmentOf(st.rejudge, ref));
    const unsure = route.j == null ? [] : judgeCells().filter((k) => route.j[k] === '판정 불가');
    if (unsure.length > 0) {
      reasons.push(`판정 불가: ${unsure.map((k) => `${k}=${route.j.unsure_reasons?.[k] ?? ''}`).join(', ')}`);
    }
    return out(route.step);
  });
  const principles = [];
  for (const o of [st.extract, st.judge, st.refetch, st.rejudge]) {
    for (const p of o?.principles_applied ?? []) if (!principles.includes(p)) principles.push(p);
  }
  return { url, judgments, principles_applied: principles };
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

// 스키마 상수를 한 객체로 돌려준다. 계약 테스트와 본문이 이 함수로 상수를 읽는다.
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
    properties: { case: str, url: str, outcome: str, axes: axesSchema, bearing: str },
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
            citations: { type: 'array', maxItems: 1, items: { type: 'object', properties: { url: str } } },
          },
          required: ['prior_claim', 'citations'],
        },
      },
      evidence_map: { type: 'array', items: row(axes) },
    },
    required: ['search_status', 'queries', 'issues'],
  };
  const EXTRACT_SCHEMA = {
    type: 'object',
    properties: {
      url: str,
      judgments: {
        type: 'array',
        items: {
          type: 'object',
          properties: {
            ref: str,
            access: { type: 'string', enum: ['성공', '실패'] },
            exists: { type: 'string', enum: ['일치', '불일치'] },
            exists_note: str,
            quote: str,
            context: str,
            reason: str,
          },
          required: ['ref', 'access', 'exists', 'exists_note', 'quote', 'context', 'reason'],
        },
      },
      principles_applied: principles,
    },
    required: ['url', 'judgments', 'principles_applied'],
  };
  // 판정과 재판정이 같은 스키마를 쓴다. 판정마다 url 은 그 주장이 든 묶음 입력 원소의 URL 이다. 보충은 추출 스키마를 쓴다.
  const match = { type: 'string', enum: ['일치', '불일치', '판정 불가', '정보 부족'] };
  const unsure = { type: 'string', enum: ['조건 얽힘', '표·그림 값', '언어 해석'] };
  const perCell = (v) => ({
    type: 'object',
    properties: { numbers_conditions: v, direction: v, scope: v },
    additionalProperties: false,
  });
  const JUDGE_SCHEMA = {
    type: 'object',
    properties: {
      judgments: {
        type: 'array',
        items: {
          type: 'object',
          properties: {
            url: str,
            ref: str,
            numbers_conditions: match,
            direction: match,
            scope: match,
            missing: perCell(str),
            unsure_reasons: perCell(unsure),
            reason: str,
          },
          required: ['url', 'ref', 'numbers_conditions', 'direction', 'scope', 'missing', 'unsure_reasons', 'reason'],
        },
      },
      principles_applied: principles,
    },
    required: ['judgments', 'principles_applied'],
  };
  const SYNTHESIS_SCHEMA = {
    type: 'object',
    properties: {
      evidence_map: { type: 'array', items: row({ type: 'object' }) },
      conclusions: {
        type: 'array',
        items: {
          type: 'object',
          properties: { text: str, refs: { type: 'array', items: str }, supports: str },
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
  // 둘러보기 출력은 검증하지 않으므로 정해진 칸 밖의 칸(사례 칸 등)을 허용하지 않는다.
  const closed = (properties) => ({ type: 'object', properties, required: Object.keys(properties), additionalProperties: false });
  const SCOUT_SCHEMA = closed({
    search_status: { type: 'string', enum: ['ok', 'no-results', 'failed', 'not-attempted'] },
    queries: { type: 'array', items: str },
    clusters: { type: 'array', items: closed({ topic: str, sources: { type: 'array', items: str }, note: str }) },
    subquestion_candidates: { type: 'array', items: closed({ scope: str, basis: str }) },
    principles_applied: principles,
  });
  return { RESEARCHER_SCHEMA, EXTRACT_SCHEMA, JUDGE_SCHEMA, SYNTHESIS_SCHEMA, MAP_SCHEMA, SCOUT_SCHEMA };
}

// 에이전트에게 보내는 프롬프트. 첫 줄은 모드, 둘째 줄은 원칙 문서 경로, 셋째 줄부터 JSON 블록이다.
function prompt(mode, principlesPath, input) {
  return `MODE: ${mode}\nPRINCIPLES: ${principlesPath}\n\`\`\`json\n${JSON.stringify(input, null, 2)}\n\`\`\``;
}
