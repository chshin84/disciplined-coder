"""재현 시험의 순서 교차 판정과 집계. 소비자는 eval_replay.sh(judge)와 eval_replay_report.sh(report)다.
저장소 밖 judge_pair.py·judge_hidden.py·report_hidden.py·count_banned.py(2026-11-13 v2 재건축 3단계)를 옮겼다.

판정(judge): 같은 턴의 두 답을 A·B 순서를 바꿔 두 번 -2~+2 로 매긴다. AB 순서는 X=A·Y=B, BA 순서는 X=B·Y=A 이고
s1 = ab.score, s2 = -ba.score, score = (s1+s2)/2 다(양수면 B 가 낫다). 두 점수가 모두 0 이상이고 평균이 0 보다 크면 개선,
모두 0 이하이고 평균이 0 보다 작으면 악화, 나머지는 같음이다. 지적 턴은 당시 사용자 지적과 판정 기준점 5개(CRITERIA)를,
지적 없던 턴은 사용자 원문 요구와 같은 기준점을 쓴다. 판정자는 근거 문장을 원문 그대로 x_quotes·y_quotes 로 돌려준다.
결과: <판정 폴더>/<idx>-<A>-<B>.json = {kind, rev_a, rev_b, ab, ba, models, s1, s2, score, cls}. 한 순서라도 점수가 없으면
cls 대신 error 를 남기고, 다음 실행에서 다시 판정한다. 판정 모델은 claude-opus-5-5 이고 다른 모델이 응답에 있으면 멈춘다.

집계(report): 개선·악화·같음 수, 한쪽 부호 검정 p, 평균, 참고 지표(위반 판정, 답 길이 중간값, 금지어 만 자당 검출,
답당 질문 수), 이전 대화 길이 구간별 집계, 판독 후보를 내고 <판정 폴더>/report.json 을 쓴다. 판정·답에
claude-opus-5-5 밖의 모델이 있거나 한 조건에 리비전이 둘 이상이면 경고하고 1 로 끝난다.
판독 파일은 {"<idx>:<A>:<B>": <사용자 점수 -2~2>} 다(side_by_side.py 페이지의 「결과 복사」).

사용: python _judge.py judge <답 폴더> <판정 폴더> <A> <B> <턴 목록> [--now]
      python _judge.py report <판정 폴더> <A> <B> <턴 목록> <답 폴더> <금지어 pairs> <금지어 excl> [--viol <위반 폴더>] [--reading <판독 파일>]"""
import json
import math
import os
import re
import shutil
import statistics
import sys
import tempfile

sys.path.insert(0, os.path.dirname(os.path.abspath(__file__)))
import _replay as R  # noqa: E402

BUCKETS = [(1, 20), (21, 60), (61, 160)]
MAX_READ, WORST = 20, 5

CRITERIA = '\n'.join([
    '1. 지적이 겨눈 점에서 실제로 나아졌으면 나아진 것이다. 네가 이상적이라고 보는 수준과 비교하지 마라.',
    '2. 지적 뒤에 사용자가 되물은 세부는 기준이 아니다. 원래 질문 수준에서 사용자가 개념을 이해할 수 있으면 통과다.',
    '3. 문체 지적(직역투, 어색한 문장)은 답 전체가 자연스럽게 읽히는지로 판정하라. 그런 문장이 몇 개 있어도 읽기를 방해하지 않으면 통과고, 여러 곳에서 반복돼 읽기를 멈추게 하면 위반이다.',
    '4. 전달 지적(사용자가 무엇이 바뀌었는지, 무슨 뜻인지 되물은 지적)은 표나 예시 같은 형식이 있는지로 판정하지 마라. 처음 읽는 사용자가 물은 내용에 바로 답을 얻는지 보라. 작업 중에 쓰던 내부 용어를 풀지 않았거나, 물은 내용에 비해 설명이 길어 답이 묻히면 위반이다.',
    '5. 지적이 겨눈 문장과 문제만 보라. 같은 답의 다른 문장에 있는 다른 결함은 판정하지 마라.',
])
JSON_LINE = 'JSON 한 줄로만 답하라: {{"score": 1, "note": "근거 한두 문장", "x_quotes": ["..."], "y_quotes": ["..."]}}'
QUOTES = 'x_quotes 에는 X 에서 {x_what}, y_quotes 에는 Y 에서 점수의 근거가 되는 문장을 각각 1~3개 원문 그대로(글자 하나 바꾸지 말고, 마크다운 기호는 빼고) 적어라.\n'

PROMPT_CORR = """사용자가 Claude 의 답을 읽고 아래처럼 지적한 실제 사례가 있다. 같은 질문에 새로 쓴 답 두 개 [답 X]와 [답 Y]가 있다. 사용자의 지적에 비추어 Y 가 X 보다 나아졌는지 점수를 매겨라.

[사용자 메시지]
{ask}

[사용자의 지적]
{correction}

[지적의 요지]
{why}

[답 X]
{x}

[답 Y]
{y}

점수: -2 = Y 가 많이 나빠짐, -1 = 조금 나빠짐, 0 = 차이 없음, 1 = 조금 나아짐, 2 = 많이 나아짐.
기준은 지적이 겨눈 문제다. 처음 읽는 사용자가 지적한 불편을 덜 겪는 답이 나은 답이다. 표나 번호 같은 형식이 있는지가 아니라 사용자가 실제로 겪는 차이로 판단하라. 내용의 옳고 그름은 판정하지 마라.
판정은 아래 기준을 따르라.

""" + CRITERIA.replace('{', '{{').replace('}', '}}') + '\n\n' + QUOTES.format(x_what='지적이 겨눈 문제가 드러나는 문장을') + JSON_LINE

PROMPT_NONE = """사용자가 Claude 에게 아래 메시지를 보냈다. 같은 메시지에 쓴 답 두 개 [답 X]와 [답 Y]가 있다.
이 사용자는 답에 대해 이렇게 요구했다: "진행해라고 하면 진행하고, 물어보면 물어본 것만 답변하고"

[사용자 메시지]
{ask}

[답 X]
{x}

[답 Y]
{y}

이 기준으로 Y 가 X 보다 나은지 점수를 매겨라. -2 = Y 가 많이 나쁨, -1 = 조금 나쁨, 0 = 차이 없음, 1 = 조금 나음, 2 = 많이 나음.
{tools}내용의 옳고 그름보다, 물은 것에 답했는지와 묻지 않은 정보로 답이 길어졌는지를 보라. 꼭 필요한 정보를 빼먹었다면 그것도 감점이다.
판정은 아래 기준을 따르라. 4·5번의 "지적"은 "사용자 메시지"로 읽는다.

""" + CRITERIA.replace('{', '{{').replace('}', '}}') + '\n\n' + QUOTES.format(x_what='이 기준에 비추어 문제가 드러나는 문장을') + JSON_LINE
NO_TOOLS = '두 답 모두 도구 없이 쓴 답이므로 실제 실행 여부는 따지지 마라. '


# --- 판정 ---

def classify(s1, s2):
    m = (s1 + s2) / 2
    if s1 >= 0 and s2 >= 0 and m > 0:
        return '개선'
    if s1 <= 0 and s2 <= 0 and m < 0:
        return '악화'
    return '같음'


def valid_score(v):
    """-2~2 정수만 점수로 본다(1.0 처럼 정수인 실수는 허용, bool·NaN·무한대는 제외). 예외를 내지 않는다."""
    if isinstance(v, bool) or not isinstance(v, (int, float)) or not math.isfinite(v):
        return False
    return v == int(v) and -2 <= v <= 2


def prompt(A, x, y, tools):
    if A['kind'] == '지적':
        return PROMPT_CORR.format(ask=A['ask'][:4000], correction=A['correction'], why=A['why'], x=x['response'][:8000], y=y['response'][:8000])
    return PROMPT_NONE.format(ask=A['ask'][:4000], x=x['response'][:8000], y=y['response'][:8000], tools='' if tools else NO_TOOLS)


def parse_reply(text):
    """판정자 답에서 첫 '{' 부터 마지막 '}' 까지를 JSON 으로 읽는다. 읽지 못하면 {'error': ...}."""
    m = re.search(r'\{.*\}', text or '', re.S)
    if not m:
        return {'error': f'JSON 이 없다: {(text or "")[:120]}'}
    try:
        v = json.loads(m.group(0))
    except ValueError as e:
        return {'error': f'JSON 을 읽지 못함: {e}'}
    return v if isinstance(v, dict) else {'error': f'JSON 이 객체가 아니다: {m.group(0)[:120]}'}


def ask(q):
    """판정 질문 하나를 도구 없이 실행한다. 설정 폴더는 빈 임시 폴더다."""
    os.makedirs(R.tmp_root(), exist_ok=True)
    t = tempfile.mkdtemp(prefix='pair-', dir=R.tmp_root())
    try:
        out = R.call_claude(['-p', '--tools', '', '--model', R.MODEL, '--output-format', 'json'], q, t, R.env_for(t), 600)
        try:
            jj = json.loads(out)
        except ValueError:
            return {'error': f'claude 출력을 읽지 못함: {out[-200:]}'}
        models = list((jj.get('modelUsage') or {}).keys())
        R.require_model(models)
        if not models:  # 모델을 확인할 수 없는 판정은 쓰지 않는다(cls 가 없으므로 다음 실행에서 다시 판정)
            return {'error': f"modelUsage 가 비어 모델을 확인하지 못함: {str(jj.get('result', ''))[:120]}"}
        v = parse_reply(jj.get('result', ''))
        v['models'] = models
        v['cost'] = jj.get('total_cost_usd')
        return v
    finally:
        shutil.rmtree(t, ignore_errors=True)


def one(A, B, order, tools):
    x, y = (A, B) if order == 'AB' else (B, A)
    try:
        return ask(prompt(A, x, y, tools))
    except R.Stop:
        raise
    except Exception as e:
        return {'error': repr(e)[:200]}


def load_pair(ans_dir, ca, cb, idx):
    pa, pb = f'{ans_dir}/{ca}-{idx}.json', f'{ans_dir}/{cb}-{idx}.json'
    if not (R.done(pa, ['response']) and R.done(pb, ['response'])):
        return None
    return json.load(open(pa, encoding='utf-8')), json.load(open(pb, encoding='utf-8'))


def result(A, B, ab, ba):
    ab = ab if isinstance(ab, dict) else {'error': repr(ab)[:200]}
    ba = ba if isinstance(ba, dict) else {'error': repr(ba)[:200]}
    r = {'kind': A['kind'], 'rev_a': A.get('rev'), 'rev_b': B.get('rev'), 'ab': ab, 'ba': ba,
         'models': sorted(set(ab.get('models') or []) | set(ba.get('models') or []))}
    if valid_score(ab.get('score')) and valid_score(ba.get('score')):
        r['s1'], r['s2'] = ab['score'], -ba['score']
        r['score'] = (r['s1'] + r['s2']) / 2
        r['cls'] = classify(r['s1'], r['s2'])
    else:
        r['error'] = ab.get('error') or ba.get('error') or f"점수가 -2~2 정수가 아님: {ab.get('score')!r} / {ba.get('score')!r}"
    return r


def judge_main(argv):
    force = '--now' in argv
    argv = [a for a in argv if a != '--now']
    if len(argv) != 5:
        print(__doc__.rsplit('사용:', 1)[1])
        return 2
    ans_dir, out_dir, ca, cb, tl = argv
    R.guard_office_hours(force)
    ids = R.read_ids(tl)
    os.makedirs(out_dir, exist_ok=True)
    tools = ca.endswith('-tools') or cb.endswith('-tools')
    pairs, jobs = {}, []
    for i in ids:
        if R.done(f'{out_dir}/{i}-{ca}-{cb}.json', ['cls']):  # 무효 점수로 실패한 판정(cls 없음)은 다시 판정한다
            print(i, 'skip', flush=True)
            continue
        p = load_pair(ans_dir, ca, cb, i)
        if p is None:
            print(i, '답 없음', flush=True)
            continue
        pairs[i] = p
        jobs += [(i, 'AB'), (i, 'BA')]
    got, cost = {}, [0]

    def on(job, v):
        i, o = job[0], job[1]
        got[(i, o)] = v
        cost[0] += v.get('cost') or 0
        if (i, 'AB') in got and (i, 'BA') in got:
            r = result(*pairs[i], got[(i, 'AB')], got[(i, 'BA')])
            R.write_json(f'{out_dir}/{i}-{ca}-{cb}.json', r)
            print(i, r.get('cls') or 'ERROR ' + str(r['error'])[:120], r.get('s1'), r.get('s2'), flush=True)

    try:
        R.pool([(i, o) for i, o in jobs], lambda i, o: one(*pairs[i], o, tools), on, force)
    except R.Stop as e:
        print('중단:', e, file=sys.stderr)
        return e.code
    print('cost', round(cost[0], 4))
    return 0


# --- 참고 지표 ---

def load_banned(pairs_path, excl_path):
    """(rows, excls): banned_parse 가 낸 pairs·excl. rows 는 행마다 금지어 목록, excls 는 행마다 제외어 목록."""
    rows = [l.rstrip('\n').split('\t')[1:] for l in open(pairs_path, encoding='utf-8') if l.strip()]
    excls = [[e for e in l.rstrip('\n').split('\t') if e] for l in open(excl_path, encoding='utf-8')]
    excls += [[]] * (len(rows) - len(excls))
    return rows, excls


def count_banned(text, rows, excls):
    """코드 블록과 백틱 구간을 지우고, 행마다 제외어를 같은 길이 공백으로 덮은 뒤 금지어 출현 수를 센다
    (hooks/_banned_words.sh 의 banned_report 와 같은 처리). 한 행 안에서 겹치는 금지어는 긴 것부터 한 번만 센다."""
    body = re.sub(r'`[^`]*`', ' ', re.sub(r'```.*?```', ' ', text, flags=re.S))
    n = 0
    for words, ex in zip(rows, excls):
        t = body
        for e in sorted(ex, key=len, reverse=True):
            t = t.replace(e, ' ' * len(e))
        ws = sorted((w for w in words if w), key=len, reverse=True)
        n += len(re.findall('|'.join(map(re.escape, ws)), t)) if ws else 0
    return n


def questions(text):
    return len(re.findall(r'[?？](?=\s|$)', re.sub(r'```.*?```', ' ', text, flags=re.S)))


def answers(ans_dir, cond, ids):
    """{idx: 답 글}. 파일 이름이 정확히 <조건>-<idx>.json 인 것만 읽는다(v2.1 이 v2.1-table 을 집지 않게)."""
    pat = re.compile('^' + re.escape(cond) + r'-(\d+)\.json$')
    out = {}
    for n in sorted(os.listdir(ans_dir)):
        m = pat.match(n)
        if m and m.group(1) in ids:
            r = json.load(open(os.path.join(ans_dir, n), encoding='utf-8')).get('response')
            if r:
                out[m.group(1)] = r
    return out


# --- 집계 ---

def sign_p(up, down):
    """한쪽 부호 검정 p = Σ_{i=up}^{n} C(n,i)/2^n, n = up + down."""
    n = up + down
    return sum(math.comb(n, i) for i in range(up, n + 1)) / 2 ** n if n else 1.0


def stats(recs):
    c = {k: sum(1 for r in recs if r['cls'] == k) for k in ('개선', '악화', '같음')}
    return {**c, 'n': len(recs), 'mean': round(statistics.mean(r['score'] for r in recs), 4) if recs else None,
            'p': sign_p(c['개선'], c['악화'])}


def line(name, s):
    m = f"{s['mean']:+.3f}" if s['mean'] is not None else '-'
    return f"{name}: 개선 {s['개선']} 악화 {s['악화']} 같음 {s['같음']} (n={s['n']}) 평균 {m} p={s['p']:.6f}"


def bucket_of(h):
    for lo, hi in BUCKETS:
        if h <= hi:
            return f'{lo}~{hi}'
    return f'{BUCKETS[-1][1] + 1}~'


def summary(recs):
    out = {'전체': stats(recs)}
    for k in ('지적', '지적없음'):
        out[k] = stats([r for r in recs if r['kind'] == k])
    return out


def judge_round(score):
    """0 에서 먼 쪽으로 반올림(-0.5→-1, +0.5→+1). 판독 페이지의 판정자 단추와 같은 값(side_by_side.judge_round)."""
    return int(math.copysign(math.floor(abs(score) + 0.5), score))


def judge_button(score, cls):
    """판독 페이지의 판정자 단추 값. 분류가 같음(두 순서 부호가 엇갈림 포함)이면 0, 아니면 judge_round."""
    return 0 if cls == '같음' else judge_round(score)


def candidates(recs):
    """평균이 가장 낮은 악화 쌍 5개를 먼저 넣고, 두 순서 부호가 엇갈린 쌍, 평균 절댓값 0.5 이하 쌍으로 20개까지 채운다."""
    pick = sorted((r for r in recs if r['cls'] == '악화'), key=lambda r: r['score'])[:WORST]
    split = sorted((r for r in recs if r['s1'] * r['s2'] < 0), key=lambda r: r['score'])
    near = sorted((r for r in recs if abs(r['score']) <= 0.5), key=lambda r: abs(r['score']))
    for r in split + near:
        if len(pick) >= MAX_READ:
            break
        if r not in pick:
            pick.append(r)
    return pick


def load_json(path):
    try:
        return json.load(open(path, encoding='utf-8'))
    except (OSError, ValueError):
        return None


def report_main(argv):
    opts = {}
    for flag in ('--viol', '--reading'):
        if flag in argv:
            k = argv.index(flag)
            opts[flag] = argv[k + 1]
            argv = argv[:k] + argv[k + 2:]
    if len(argv) != 7:
        print(__doc__.rsplit('사용:', 1)[1])
        return 2
    jd, ca, cbn, tl, ad, pairs_path, excl_path = argv
    sys.stdout.reconfigure(encoding='utf-8')
    ids = R.read_ids(tl)
    warn, recs, missing, kinds = [], [], [], {}
    revs = {ca: set(), cbn: set()}
    models, empty = set(), []

    def see_models(name, ms):
        if ms:
            models.update(ms)
        else:
            empty.append(name)
    for i in ids:
        j = load_json(f'{jd}/{i}-{ca}-{cbn}.json')
        A = load_json(f'{ad}/{ca}-{i}.json')
        kinds[i] = (j or {}).get('kind') or (A or {}).get('kind') or ''
        if j is None:
            missing.append(i)
            continue
        for o in ('ab', 'ba'):
            jo = j.get(o)
            see_models(f'판정 {i} {o}', jo.get('models') if isinstance(jo, dict) else None)
        if 'models' in j:
            see_models(f'판정 {i}', j['models'])
        for c in (ca, cbn):
            a = load_json(f'{ad}/{c}-{i}.json')
            if a is not None:
                see_models(f'답 {c}-{i}', a.get('models'))
        if 'cls' not in j:
            missing.append(i)
            continue
        revs[ca].add(j.get('rev_a'))
        revs[cbn].add(j.get('rev_b'))
        recs.append({'idx': i, 'key': f'{i}:{ca}:{cbn}', 'kind': kinds[i], 's1': j['s1'], 's2': j['s2'],
                     'score': j['score'], 'cls': j['cls'], 'judge_cls': j['cls'], 'history_msgs': (A or {}).get('history_msgs')})

    print(f'판정 대상 {len(recs)} / 턴 {len(ids)}, 빠진 턴 {len(missing)}: {" ".join(missing) or "없음"}')
    summ = summary(recs)
    for k in ('지적', '지적없음', '전체'):
        print(line(k, summ[k]))

    for c, s in revs.items():
        print(f'리비전 {c}: {sorted(x or "없음" for x in s)}')
        if len(s) > 1:
            warn.append(f'{c} 의 리비전이 {len(s)}개다')
        exp = R.rev_of(c)
        if s and s != {exp}:
            warn.append(f'{c} 의 리비전이 rev_of({c}) = {exp} 와 다르다')

    ref, viol = {}, {}
    if '--viol' in opts:
        for c in (ca, cbn):
            vs = []
            for i in ids:
                if kinds[i] != '지적':
                    continue
                v = load_json(f"{opts['--viol']}/{c}-{i}.json")
                if v is None:
                    continue
                see_models(f'위반 판정 {c}-{i}', v.get('models'))
                vs.append(bool(v.get('violated')))
            viol[c] = {'violated': sum(vs), 'n': len(vs)}
            print(f'위반(지적 턴) {c}: {sum(vs)} / {len(vs)}')
    ref['viol'] = viol
    rows, excls = load_banned(pairs_path, excl_path)
    both = set(answers(ad, ca, set(ids))) & set(answers(ad, cbn, set(ids)))  # 두 조건 답이 모두 있는 턴만 비교한다
    ref['common_answers'] = len(both)
    for c in (ca, cbn):
        A = answers(ad, c, both)
        chars = sum(len(x) for x in A.values())
        hits = sum(count_banned(x, rows, excls) for x in A.values())
        q = [questions(x) for x in A.values()]
        ref[c] = {'answers': len(A), 'len_median': statistics.median(len(x) for x in A.values()) if A else None,
                  'banned_per10k': round(hits / chars * 10000, 3) if chars else None, 'banned_hits': hits,
                  'questions_per_answer': round(statistics.mean(q), 3) if q else None}
        r = ref[c]
        print(f"참고 {c}: 답 {r['answers']} 길이 중간값 {r['len_median']} 금지어 만자당 {r['banned_per10k']} ({hits}건) 답당 질문 {r['questions_per_answer']}")

    other = sorted(m for m in models if m != R.MODEL)
    print(f'모델(답·판정·위반 판정): {sorted(models) or "없음"}')
    if other:
        warn.append(f'{R.MODEL} 밖의 모델이 있다: {other}')
    if empty:
        warn.append(f'models 가 빈 파일 {len(empty)}개: {", ".join(empty[:5])}{" …" if len(empty) > 5 else ""}')

    by_len = {}
    for b in [f'{lo}~{hi}' for lo, hi in BUCKETS] + [f'{BUCKETS[-1][1] + 1}~', '기록 없음']:
        rs = [r for r in recs if (bucket_of(r['history_msgs']) if r['history_msgs'] is not None else '기록 없음') == b]
        if rs or b in [f'{lo}~{hi}' for lo, hi in BUCKETS]:
            by_len[b] = summary(rs)
            print(line(f'이전 대화 {b}', by_len[b]['전체']))

    cand = candidates(recs)
    print(f'판독 후보 {len(cand)}쌍: ' + ' '.join(r['key'] for r in cand))

    report = {'conds': [ca, cbn], 'turns': len(ids), 'judged': len(recs), 'missing': missing, 'summary': summ,
              'revs': {c: sorted(x or '' for x in s) for c, s in revs.items()}, 'models': sorted(models), 'reference': ref,
              'by_history': by_len, 'reading_candidates': [{'key': r['key'], 'kind': r['kind'], 's1': r['s1'], 's2': r['s2'],
                                                            'score': r['score'], 'cls': r['cls']} for r in cand],
              'pairs': [{k: r[k] for k in ('key', 'kind', 's1', 's2', 'score', 'cls', 'history_msgs')} for r in recs]}

    if '--reading' in opts:
        user = dict(json.load(open(opts['--reading'], encoding='utf-8')))
        for r in recs:
            if r['key'] in user:
                u = user[r['key']]
                r['cls'] = '개선' if u > 0 else '악화' if u < 0 else '같음'
        shown = [r['key'] for r in cand]
        byk = {r['key']: r for r in recs}
        # 사용자가 누르지 않은 쌍은 페이지에 보인 판정자 단추 값에 동의한 것으로 본다(같음이면 0, 개선은 양수, 악화는 음수)
        vals = [user[k] if k in user else judge_button(byk[k]['score'], byk[k]['judge_cls']) for k in shown]
        ok = sum(1 for v in vals if v >= 0)
        differ = sum(1 for k in shown if k in user and user[k] != judge_button(byk[k]['score'], byk[k]['judge_cls']))
        rsumm = summary(recs)
        print(f'판독 반영: 판독 파일 {len(user)}쌍, 보인 쌍 {len(shown)} 중 같거나 나음 {ok}, 과반 {"예" if ok * 2 > len(shown) else "아니오"}, 판정·판독 불일치 {differ}')
        for k in ('지적', '지적없음', '전체'):
            print(line('판독 반영 ' + k, rsumm[k]))
        report['reading'] = {'file': opts['--reading'], 'entries': len(user), 'shown': len(shown), 'same_or_better': ok,
                             'majority': ok * 2 > len(shown), 'disagree': differ, 'summary': rsumm,
                             'unknown_keys': sorted(k for k in user if k not in byk)}

    report['warnings'] = warn
    R.write_json(f'{jd}/report.json', report)
    for w in warn:
        print('경고:', w)
    return 1 if warn else 0


def main(argv):
    if argv[:1] == ['judge']:
        return judge_main(argv[1:])
    if argv[:1] == ['report']:
        return report_main(argv[1:])
    print(__doc__.rsplit('사용:', 1)[1])
    return 2


if __name__ == '__main__':
    sys.exit(main(sys.argv[1:]))
