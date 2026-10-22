// 탐색 워크플로(workflows/prior-art-search.js)를 런타임 밖에서 실행하는 시험 도구다.
// 사용법: node scripts/workflow_harness.mjs fn <함수 이름> | run
// 입력은 표준 입력의 JSON 이고, 결과는 표준 출력에 JSON 한 줄로 쓴다.
// 종료 코드: 0 성공, 1 스크립트 예외와 치명 오류, 2 사용법 오류.
// 입력을 인자로 받지 않는 이유는 MSYS2 가 POSIX 경로처럼 보이는 인자를 Windows 경로로 바꾸기 때문이다.
import { readFileSync } from 'node:fs';

const FN_NAMES = ['checkQueries', 'groupByUrl', 'classify', 'batchClaims', 'splitByUrl', 'mergeStages', 'mergeStatus', 'schemas'];
const AsyncFunction = Object.getPrototypeOf(async function () {}).constructor;

// 치명 오류의 문구다. 스크립트가 예외를 삼켜도 실행이 끝난 뒤 이 값을 보고 종료 코드 1 로 끝난다.
let fatal = null;

function usage(message) {
  process.stderr.write(`사용법 오류: ${message}\n`);
  process.exitCode = 2;
}

// 워크플로 원문의 첫 줄 맨 앞 `export ` 일곱 글자만 떼어 본문으로 삼는다. 첫 줄 형식이 틀리면 null 이다.
function loadBody() {
  const source = readFileSync(new URL('../workflows/prior-art-search.js', import.meta.url), 'utf8');
  if (!source.startsWith('export const meta = {')) return null;
  return source.slice('export '.length);
}

// 런타임이 막는 호출을 본문 안에서 재현하는 대체본이다. 막힌 호출은 raise 로 치명 오류를 남기므로
// 스크립트가 예외를 삼켜도 종료 코드 1 로 드러난다.
const GuardedDate = new Proxy(Date, {
  construct(target, a, newTarget) {
    if (a.length === 0) raise('금지 호출: 인자 없는 new Date()');
    return Reflect.construct(target, a, newTarget);
  },
  apply(target, thisArg, a) {
    if (a.length === 0) raise('금지 호출: 인자 없는 Date()');
    return Reflect.apply(target, thisArg, a);
  },
  get(target, key) {
    if (key === 'now') return () => raise('금지 호출: Date.now()');
    return Reflect.get(target, key, target);
  },
});
const GuardedMath = new Proxy(Math, {
  get(target, key) {
    if (key === 'random') return () => raise('금지 호출: Math.random()');
    return Reflect.get(target, key, target);
  },
});

function build(body) {
  const head = "'use strict';\nif (__fn) return eval(__fn)(...__fnArgs);\n";
  // process·require·fetch·setTimeout·Buffer 는 undefined 로 가려 본문이 쓰면 TypeError 가 나게 한다.
  return new AsyncFunction('agent', 'parallel', 'phase', 'log', 'args', '__fn', '__fnArgs',
    'Date', 'Math', 'process', 'require', 'fetch', 'setTimeout', 'Buffer', head + body);
}

// 루트가 type: object 이고 모든 객체 스키마에서 required 가 properties 의 부분집합인지 본다. 어긋나면 문구를 돌려준다.
function schemaProblem(schema) {
  if (!schema || typeof schema !== 'object' || schema.type !== 'object') return '스키마 루트가 type: object 가 아니다';
  const walk = (node, path) => {
    if (!node || typeof node !== 'object') return null;
    if ('required' in node || 'properties' in node) {
      const keys = Object.keys(node.properties ?? {});
      for (const r of node.required ?? []) {
        if (!keys.includes(r)) return `${path}: required 의 ${r} 가 properties 에 없다`;
      }
    }
    for (const [k, v] of Object.entries(node.properties ?? {})) {
      const p = walk(v, `${path}.${k}`);
      if (p) return p;
    }
    if (node.items) return walk(node.items, `${path}[]`);
    return null;
  };
  return walk(schema, '$');
}

function raise(message) {
  fatal = fatal ?? message;
  throw new Error(message);
}

async function main() {
  const [command, name] = process.argv.slice(2);
  if (command !== 'fn' && command !== 'run') return usage(`알 수 없는 명령: ${command}`);
  if (command === 'fn' && !FN_NAMES.includes(name)) return usage(`알 수 없는 함수 이름: ${name}`);
  const body = loadBody();
  if (body === null) return usage('워크플로의 첫 줄이 export const meta = { 로 시작하지 않는다');
  let input;
  try {
    input = JSON.parse(readFileSync(0, 'utf8'));
  } catch (e) {
    return usage(`표준 입력의 JSON 해석에 실패했다: ${e.message}`);
  }
  let fn;
  try {
    fn = build(body);
  } catch (e) {
    process.stderr.write(`스크립트 구문 오류: ${e.message}\n`);
    process.exitCode = 1;
    return;
  }

  if (command === 'fn') {
    try {
      const out = await fn(undefined, undefined, undefined, undefined, undefined, name, input, GuardedDate, GuardedMath);
      process.stdout.write(JSON.stringify(out ?? null) + '\n');
    } catch (e) {
      process.stderr.write(`스크립트 예외: ${e.message}\n`);
      process.exitCode = 1;
    }
    return;
  }

  const { args, responses = {} } = input;
  const calls = [];
  const logs = [];
  const agent = async (prompt, opts = {}) => {
    const problem = schemaProblem(opts.schema);
    if (problem) raise(`agent(${opts.label}): ${problem}`);
    const { label, agentType, phase, model, effort } = opts;
    calls.push({ label, agentType, phase, model, effort, prompt });
    if (!Object.hasOwn(responses, label)) raise(`응답표에 없는 label 을 불렀다: ${label}`);
    return structuredClone(responses[label]);
  };
  const parallel = async (thunks) => {
    const out = [];
    for (const t of thunks) {
      try {
        out.push(await t());
      } catch {
        out.push(null);
      }
    }
    return out;
  };
  const phase = () => {};
  const log = (message) => { logs.push(message); };

  let result;
  try {
    result = await fn(agent, parallel, phase, log, args, undefined, undefined, GuardedDate, GuardedMath);
  } catch (e) {
    process.stderr.write(`스크립트 예외: ${e.message}\n`);
    process.exitCode = 1;
    return;
  }
  if (fatal) {
    process.stderr.write(`치명 오류: ${fatal}\n`);
    process.exitCode = 1;
    return;
  }
  process.stdout.write(JSON.stringify({ result: result ?? null, calls, logs }) + '\n');
}

await main();
