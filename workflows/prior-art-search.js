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
const ESCALATION = 'disciplined-coder:prior-art-judge-escalation';
const MAPCHECK = 'disciplined-coder:prior-art-mapcheck';

phase('Research');
const researchOut = await parallel(args.subquestions.map((sq) => () => agent(
  prompt('explore', args.principles_path, {
    question: args.question,
    situation: args.situation,
    target: args.target,
    mode: args.mode,
    subquestion: sq,
    forbidden_terms: args.forbidden_terms,
  }),
  { agentType: RESEARCHER, label: `research:${sq.id}`, phase: 'Research', schema: S.RESEARCHER_SCHEMA },
)));
const researchers = args.subquestions.map((sq, i) => ({ id: sq.id, output: researchOut[i] ?? null }));
const query_violations = checkQueries(researchers, args.forbidden_terms);
const { items, groups } = groupByUrl(researchers);

// 검증은 다섯 단계다. URL 마다 추출하고, 추출을 통과한 주장만 판정한다. 정보 부족이 있고 불일치가 없는 주장은
// 추출 검증자가 원문을 다시 열어 보충하고(refetch), 보충 구절로 다시 판정한다(rejudge). 판정 불가가 남은 주장만 상향 판정한다.
// 단계 출력은 URL 을 키로 둔 객체에 모으고 mergeStages 가 인용 판정 출력 형식으로 합친다.
phase('Verify');
const refsByUrl = {};
const extract = {};
const judge = {};
const refetch = {};
const rejudge = {};
const escalation = {};
const extractOut = await parallel(groups.map((g) => () => agent(
  prompt('extract', args.principles_path, { url: g.url, claims: g.claims }),
  { agentType: EXTRACTOR, label: `extract:${g.url}`, phase: 'Verify', schema: S.EXTRACT_SCHEMA },
)));
groups.forEach((g, i) => {
  refsByUrl[g.url] = g.claims.map((c) => c.ref);
  extract[g.url] = extractOut[i] ?? null;
});
const judgeJobs = groups
  .map((g) => ({ url: g.url, claims: judgeClaims(g.claims, extract[g.url]) }))
  .filter((x) => x.claims.length > 0);
const judgeOut = await parallel(judgeJobs.map((x) => () => agent(
  prompt('judge', args.principles_path, { url: x.url, claims: x.claims }),
  { agentType: JUDGE, label: `judge:${x.url}`, phase: 'Verify', schema: S.JUDGE_SCHEMA },
)));
judgeJobs.forEach((x, i) => { judge[x.url] = judgeOut[i] ?? null; });
const refetchJobs = judgeJobs
  .map((x) => ({ url: x.url, claims: refetchClaims(x.claims, judge[x.url]) }))
  .filter((x) => x.claims.length > 0);
const refetchOut = await parallel(refetchJobs.map((x) => () => agent(
  prompt('refetch', args.principles_path, { url: x.url, claims: x.claims }),
  { agentType: EXTRACTOR, label: `refetch:${x.url}`, phase: 'Verify', schema: S.EXTRACT_SCHEMA },
)));
refetchJobs.forEach((x, i) => { refetch[x.url] = refetchOut[i] ?? null; });
const rejudgeJobs = refetchJobs
  .map((x) => ({ url: x.url, claims: rejudgeClaims(x.claims, refetch[x.url]) }))
  .filter((x) => x.claims.length > 0);
const rejudgeOut = await parallel(rejudgeJobs.map((x) => () => agent(
  prompt('judge', args.principles_path, { url: x.url, claims: x.claims }),
  { agentType: JUDGE, label: `rejudge:${x.url}`, phase: 'Verify', schema: S.JUDGE_SCHEMA },
)));
rejudgeJobs.forEach((x, i) => { rejudge[x.url] = rejudgeOut[i] ?? null; });
const rejudgeInput = {};
rejudgeJobs.forEach((x) => { rejudgeInput[x.url] = x.claims; });
const escJobs = judgeJobs
  .map((x) => ({
    url: x.url,
    claims: escalateClaims(x.claims, judge[x.url], refetch[x.url] ?? null, rejudgeInput[x.url] ?? [], rejudge[x.url] ?? null),
  }))
  .filter((x) => x.claims.length > 0);
const escOut = await parallel(escJobs.map((x) => () => agent(
  prompt('judge', args.principles_path, { url: x.url, claims: x.claims }),
  { agentType: ESCALATION, label: `escalate:${x.url}`, phase: 'Verify', schema: S.JUDGE_SCHEMA },
)));
escJobs.forEach((x, i) => { escalation[x.url] = escOut[i] ?? null; });
const { outputs, stages } = mergeStages(refsByUrl, extract, judge, refetch, rejudge, escalation);
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
      prompt('synthesize', args.principles_path, { question: args.question, target: args.target, passed_rows }),
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

// 단계 출력에서 refs 의 판정을 ref 마다 하나씩 찾아 Map 으로 돌려준다. 판정이 배열이 아니거나,
// 한 ref 라도 판정이 없거나 ok 를 통과하지 못하면 null 이다. null 은 그 단계가 그 URL 에서 실패했다는 뜻이다.
function judgmentsByRef(refs, output, ok = () => true) {
  const judgments = output?.judgments;
  if (!Array.isArray(judgments)) return null;
  const found = new Map();
  for (const ref of refs) {
    const j = judgments.find((x) => x.ref === ref);
    if (j == null || !ok(j)) return null;
    found.set(ref, j);
  }
  return found;
}

// 단계 출력에서 ref 하나의 판정을 찾는다. 출력이 없거나 그 ref 의 판정이 없으면 null 이다.
// 보충과 재판정은 주장 하나만 실패로 두므로 URL 단위의 judgmentsByRef 대신 이 함수로 찾는다.
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

// 판정 하나의 다음 차례다. 불일치가 있으면 unsupported, 정보 부족이 있으면 refetch, 판정 불가가 있으면 escalate,
// 셋 다 없으면 supported 다. 불일치를 먼저 보므로 불일치가 있는 주장은 보충과 상향을 하지 않는다.
function nextStep(j) {
  const cells = judgeCells().map((k) => j[k]);
  if (cells.includes('불일치')) return 'unsupported';
  if (cells.includes('정보 부족')) return 'refetch';
  if (cells.includes('판정 불가')) return 'escalate';
  return 'supported';
}

// 주장 하나의 판정 차례다. j 는 세 칸이 정해진 처음 판정, rf 와 rj 는 그 주장의 보충·재판정 판정(없으면 null)이다.
// step 은 supported·unsupported·escalate·verify_failed 중 하나이고, j 는 상향이 바꿀 칸을 고를 판정이다.
// 보충이 없거나 보충 출력이 추출 기준을 통과하지 못하거나, 재판정이 없거나 칸이 빠지거나, 재판정도 정보 부족이면 verify_failed 다.
function routeClaim(j, rf, rj) {
  const first = nextStep(j);
  if (first !== 'refetch') return { step: first, from: 'judge', j };
  if (rf == null || !passesExtract(rf)) return { step: 'verify_failed', from: 'refetch', j: null };
  if (rj == null || !cellsOk(rj)) return { step: 'verify_failed', from: 'rejudge', j: null };
  const second = nextStep(rj);
  return { step: second === 'refetch' ? 'verify_failed' : second, from: 'rejudge', j: rj };
}

// 보충 입력의 claims 다. 처음 판정에 정보 부족이 있고 불일치가 없는 주장만 고르고, 판정의 missing 을 붙인다.
// 판정이 실패한 URL 은 빈 배열이다.
function refetchClaims(claims, judgeOutput) {
  const ju = judgmentsByRef(claims.map((c) => c.ref), judgeOutput, cellsOk);
  if (ju == null) return [];
  return claims
    .filter((c) => nextStep(ju.get(c.ref)) === 'refetch')
    .map((c) => ({ ref: c.ref, text: c.text, missing: ju.get(c.ref).missing ?? {} }));
}

// 재판정 입력의 claims 다. 보충 출력이 추출 기준을 통과한 주장만 고르고, 보충 구절로 판정 입력을 만든다.
function rejudgeClaims(claims, refetchOutput) {
  return claims
    .filter((c) => { const f = judgmentOf(refetchOutput, c.ref); return f != null && passesExtract(f); })
    .map((c) => toJudgeClaim(c, judgmentOf(refetchOutput, c.ref)));
}

// 상향 판정 입력의 claims 다. 판정 불가가 남은 주장만 고른다. 재판정을 거친 주장은 재판정 입력을,
// 아니면 처음 판정 입력을 쓴다. 판정이 실패한 URL 은 빈 배열이다.
function escalateClaims(claims, judgeOutput, refetchOutput, rejudgeInput, rejudgeOutput) {
  const ju = judgmentsByRef(claims.map((c) => c.ref), judgeOutput, cellsOk);
  if (ju == null) return [];
  const out = [];
  for (const c of claims) {
    const route = routeClaim(ju.get(c.ref), judgmentOf(refetchOutput, c.ref), judgmentOf(rejudgeOutput, c.ref));
    if (route.step !== 'escalate') continue;
    out.push(route.from === 'rejudge' ? rejudgeInput.find((x) => x.ref === c.ref) : c);
  }
  return out;
}

// 단계 합치기. 인자와 반환값은 모두 URL 을 키로 둔 일반 객체다. 단계 객체에 키가 없는 URL 은 그 단계를 실행하지 않은 URL 이다.
// outputs[url] 이 null 이면 그 URL 은 검증 실패이고, 주장 하나만 실패하면 그 판정의 verdict 가 verify_failed 다.
// stages[url] 은 다섯 단계의 원본이며, 실행하지 않은 단계는 null 이다.
function mergeStages(refsByUrl, extract, judge, refetch, rejudge, escalation) {
  const outputs = {};
  const stages = {};
  for (const [url, refs] of Object.entries(refsByUrl)) {
    const st = {
      extract: extract[url] ?? null,
      judge: judge[url] ?? null,
      refetch: refetch[url] ?? null,
      rejudge: rejudge[url] ?? null,
      escalation: escalation[url] ?? null,
    };
    stages[url] = st;
    outputs[url] = mergeUrl(url, refs, st);
  }
  return { outputs, stages };
}

// URL 하나의 합치기다. spec 「최종 판정과 실패 처리」와 「충분성 판단과 보충·Opus 상향」의 차례로 verdict 를 정하고,
// URL 검증 실패이면 null 이다. 처음 판정과 상향 판정의 무응답·누락은 URL 검증 실패이고, 보충과 재판정의 실패는 그 주장만 verify_failed 다.
// 상향 판정은 판정 불가 칸만 바꾸고, 상향 뒤에도 판정 불가나 정보 부족이 남으면 그 주장만 verify_failed 다.
// quote 는 보충 출력이 추출 기준을 통과했으면 보충 구절이고, 아니면 추출 구절이다. reason 은 단계 이름을 붙인 이유를 ' / ' 로 이어 붙인다.
function mergeUrl(url, refs, st) {
  const exBy = judgmentsByRef(refs, st.extract);
  if (exBy == null) return null;
  const toJudge = refs.filter((r) => passesExtract(exBy.get(r)));
  const juBy = toJudge.length > 0 ? judgmentsByRef(toJudge, st.judge, cellsOk) : new Map();
  if (juBy == null) return null;
  const routes = new Map(toJudge.map((r) => [r, routeClaim(juBy.get(r), judgmentOf(st.refetch, r), judgmentOf(st.rejudge, r))]));
  const unsure = toJudge.filter((r) => routes.get(r).step === 'escalate');
  // 상향 판정 출력은 판정 불가였던 칸만 정해진 값이면 된다.
  const esOk = (j) => judgeCells().every((k) => routes.get(j.ref).j[k] !== '판정 불가' || isMatch(j[k]));
  const esBy = unsure.length > 0 ? judgmentsByRef(unsure, st.escalation, esOk) : new Map();
  if (esBy == null) return null;
  const judgments = refs.map((ref) => {
    const e = exBy.get(ref);
    const reasons = [`추출: ${e.reason ?? ''}`];
    let quote = String(e.quote ?? '');
    const out = (verdict) => ({ ref, verdict, quote, reason: reasons.join(' / ') });
    if (e.access === '실패') return out('unverifiable');
    if (!passesExtract(e)) return out('unsupported');
    const j = juBy.get(ref);
    reasons.push(`판정: ${j.reason ?? ''}`);
    if (nextStep(j) === 'refetch') {
      const f = judgmentOf(st.refetch, ref);
      const g = judgmentOf(st.rejudge, ref);
      if (f != null) reasons.push(`보충: ${f.reason ?? ''}`);
      if (f != null && passesExtract(f)) quote = String(f.quote ?? '');
      if (g != null) reasons.push(`재판정: ${g.reason ?? ''}`);
    }
    const route = routes.get(ref);
    if (route.step !== 'escalate') return out(route.step);
    const s = esBy.get(ref);
    reasons.push(`상향: ${s.reason ?? ''}`);
    const cells = judgeCells().map((k) => (route.j[k] === '판정 불가' ? s[k] : route.j[k]));
    if (cells.includes('판정 불가') || cells.includes('정보 부족')) return out('verify_failed');
    if (cells.includes('불일치')) return out('unsupported');
    return out('supported');
  });
  const principles = [];
  for (const o of [st.extract, st.judge, st.refetch, st.rejudge, st.escalation]) {
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
  // 판정·재판정·상향 판정이 같은 스키마를 쓴다. 보충은 추출 스키마를 쓴다.
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
            ref: str,
            numbers_conditions: match,
            direction: match,
            scope: match,
            missing: perCell(str),
            unsure_reasons: perCell(unsure),
            reason: str,
          },
          required: ['ref', 'numbers_conditions', 'direction', 'scope', 'missing', 'unsure_reasons', 'reason'],
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
  return { RESEARCHER_SCHEMA, EXTRACT_SCHEMA, JUDGE_SCHEMA, SYNTHESIS_SCHEMA, MAP_SCHEMA };
}

// 에이전트에게 보내는 프롬프트. 첫 줄은 모드, 둘째 줄은 원칙 문서 경로, 셋째 줄부터 JSON 블록이다.
function prompt(mode, principlesPath, input) {
  return `MODE: ${mode}\nPRINCIPLES: ${principlesPath}\n\`\`\`json\n${JSON.stringify(input, null, 2)}\n\`\`\``;
}
