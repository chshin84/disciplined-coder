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

// 질의 경계 검사. 구현은 판정 함수 태스크가 채운다.
function checkQueries(researchers, forbiddenTerms) {
  throw new Error('미구현');
}

// URL 묶기.
function groupByUrl(researchers) {
  throw new Error('미구현');
}

// 통과 판정.
function classify(items, groups, verifiers) {
  throw new Error('미구현');
}

// 상태 합치기.
function mergeStatus(subquestions, researchers, classified) {
  throw new Error('미구현');
}

// 선행 서술 결측 판정.
function lacksPrior(item) {
  throw new Error('미구현');
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
