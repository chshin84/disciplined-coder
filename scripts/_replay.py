"""재현 시험의 답 생성. 실제 세션을 사용자 메시지 직전까지 재개해(`claude -p --resume`) 조건마다 답을 한 번 만든다.
소비자는 eval_replay.sh 와 _judge.py(공용 함수)다. 저장소 밖 replay6.py(2026-11-13 v2 재건축 3단계)를 옮겼다.

조건: v1 | v2.<n> | v2.<n>-table | v1-tools | v2.<n>-tools
  v1            태그 archive/v1-final 의 원칙 + 원본 금지어 표 + 그 리비전의 리마인더
  v2.<n>        <DC_EVAL_HOME>/replay/V2_REV.<n>.txt 가 적은 커밋의 원칙 + 금지어 상시 보기(banned_view) + 리마인더
  v2.<n>-table  v2.<n> 과 같되 금지어는 원본 표
  -tools        같은 지시에 읽기 전용 도구(Read,Grep,Glob)와 턴 시각 직전 저장소 사본을 준다

턴 목록은 턴 ID(숫자) 한 줄씩이다. 턴의 세부(세션 파일, 지적, 종류)는 환경 변수 REPLAY_TURNS 의 jsonl, 없으면
<DC_EVAL_HOME>/replay/turns/turns-*.jsonl 에서 찾는다. 결과에 실제 대화가 들어 있으므로 저장소 밖에 둔다.
DC_EVAL_HOME 의 기본값은 %USERPROFILE%\\.dc-eval 이다.

지키는 것:
- 생성 모델은 claude-opus-5-5 다. 응답의 modelUsage 에 다른 모델이 있으면 답을 쓰지 않고 실행을 멈춘다(ModelError).
  modelUsage 가 비어 있으면 모델을 확인할 수 없으므로 그 턴의 답을 쓰지 않는다(다음 실행에서 다시 생성).
- 같은 턴·같은 조건의 답 파일이 있으면 다시 생성하지 않는다.
- 평일 09:00~18:00 에는 --now 없이 생성하지 않는다(2026-11-17 사용자 지시). 시작할 때와 턴마다 시작 직전에 확인하고,
  실행 중 업무 시간에 들어가면 남은 턴을 취소한다(OfficeHoursError).
- 설정 폴더(CLAUDE_CONFIG_DIR)는 EVAL_TMP(기본 D:/dc-eval-tmp) 아래 임시 폴더라 실제 ~/.claude 와 분리된다.
- 로그인 토큰은 실제 설정의 .credentials.json 에서 읽어 환경 변수로만 넘긴다. 출력하거나 파일에 쓰지 않는다.
  남은 시간이 TOKEN_MIN_H 미만이면 갱신될 때까지 1분마다 다시 읽고, 처음 기다리기 시작한 때부터 TOKEN_WAIT_MIN(기본 60)분이
  지나면 남은 턴을 취소하고 멈춘다(TokenError). 기한은 프로세스에 하나라 턴마다 다시 60분을 기다리지 않는다.
- 여유 메모리가 MEM_MIN_GB(기본 2.5) 미만이면 다음 턴 시작을 미룬다. 동시 실행은 PAR(기본 2)개다.
- 원본 세션 파일이 없으면 <DC_EVAL_HOME>/replay/sessions-backup/ 의 사본을 읽는다(backup_sessions.py 가 만든다).

사용: python _replay.py <답 폴더> <조건> <턴 목록> [--now]
      python _replay.py --print-context <조건>   (생성 없이 설정 CLAUDE.md 와 리마인더 블록만 출력)"""
import ast
import concurrent.futures as cf
import datetime
import glob
import json
import os
import re
import shutil
import stat
import subprocess
import sys
import tempfile
import time
import uuid

RT = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
MODEL = 'claude-opus-5-5'
V1_TAG = 'archive/v1-final'
TOOL_CAP = 1500
MAX_MSGS = 160
TOKEN_MIN_H = 0.3
NL = chr(10)
BASH = shutil.which('bash') or 'bash'  # PATH 의 Git Bash. 이름만 주면 윈도우가 System32 의 WSL bash 를 먼저 고른다
NO_TOOLS_NOTE = '이번 턴에는 도구를 쓸 수 없다. 확인하겠다는 예고로 끝내지 말고, 대화에 있는 정보로 답을 끝까지 써라.'
COND_RE = re.compile(r'^(v1|v2\.(\d+))(-table|-tools)?$')
SECRET_PATTERNS = (
    (r"\b(sk-|AKIA|ghp_)[A-Za-z0-9_\-]{8,}", "키 형태 문자열"),
    (r"[A-Za-z0-9._%+\-]+@[A-Za-z0-9.\-]+\.[A-Za-z]{2,}", "메일 주소"),
    (r"(C:\\Users\\|/c/Users/|C:/Users/)", "사용자 PC 경로"),
)


class Stop(Exception):
    """남은 작업을 모두 취소하고 실행을 멈출 사유. code 는 프로세스 종료 코드다."""
    code = 3


class ModelError(Stop):
    """생성·판정 응답에 claude-opus-5-5 밖의 모델이 있다."""
    code = 3


class OfficeHoursError(Stop):
    """평일 업무 시간에 --now 없이 claude -p 를 실행하려 했다."""
    code = 4


class TokenError(Stop):
    """로그인 토큰이 기다리는 기한 안에 갱신되지 않았다."""
    code = 5


_token_deadline = None  # 토큰 갱신을 기다리기 시작한 뒤의 기한. 갱신되면 None 으로 되돌린다


def home():
    return os.environ.get('USERPROFILE') or os.path.expanduser('~')


def dc_eval():
    return os.environ.get('DC_EVAL_HOME') or os.path.join(home(), '.dc-eval')


def tmp_root():
    return os.environ.get('EVAL_TMP', 'D:/dc-eval-tmp')


def check_secrets(root):
    """root 아래 파일에서 비밀 패턴이 보이는 곳을 '<상대 경로>: <종류>' 로 돌려준다."""
    errs = []
    for dp, _, fs in os.walk(root):
        for f in fs:
            t = open(os.path.join(dp, f), encoding='utf-8', errors='replace').read()
            for pat, label in SECRET_PATTERNS:
                if re.search(pat, t):
                    errs.append(f'{os.path.relpath(os.path.join(dp, f), root)}: {label}')
    return errs


def require_model(models):
    other = sorted(m for m in models or [] if m != MODEL)
    if other:
        raise ModelError(f'{MODEL} 밖의 모델이 응답에 있다: {other}')


def now():
    return datetime.datetime.now()


def office_hours(t):
    """평일 09:00 이상 18:00 미만이면 참."""
    return t.weekday() < 5 and 9 <= t.hour < 18


def check_office_hours(force):
    """평일 업무 시간이면 force(--now) 없이 OfficeHoursError. claude -p 는 그 시간 밖에서만 실행한다(2026-11-17 사용자 지시)."""
    t = now()
    if office_hours(t) and not force:
        raise OfficeHoursError(f'평일 09:00~18:00 에는 claude -p 를 실행하지 않는다(지금 {t:%a %H:%M}). '
                               '남은 작업을 취소했다. 지금 실행하려면 --now 를 붙인다')


def guard_office_hours(force):
    """시작할 때의 확인. 업무 시간이면 안내를 내고 종료 코드 4 로 멈춘다."""
    try:
        check_office_hours(force)
    except OfficeHoursError as e:
        print(e, file=sys.stderr)
        raise SystemExit(e.code)


def parse_cond(cond):
    m = COND_RE.match(cond)
    if not m or (m.group(1) == 'v1' and m.group(3) == '-table'):
        raise SystemExit(f'알 수 없는 조건: {cond}')
    return m.group(1), m.group(3) or ''


def rev_of(cond):
    """v1 은 archive/v1-final, v2.<n> 은 V2_REV.<n>.txt 의 커밋을 전체 해시로 돌려준다."""
    base, _ = parse_cond(cond)
    if base == 'v1':
        ref = V1_TAG
    else:
        ref = open(os.path.join(dc_eval(), 'replay', f'V2_REV.{base[3:]}.txt'), encoding='utf-8').read().strip()
    p = subprocess.run(['git', '-C', RT, 'rev-parse', '--verify', ref + '^{commit}'], capture_output=True, text=True)
    if p.returncode != 0:
        raise SystemExit(f'리비전을 찾지 못함: {ref}')
    return p.stdout.strip()


def done(path, keys):
    """파일이 있고 JSON 으로 읽히며 keys 의 값이 모두 비어 있지 않으면 참. 키는 'ab.score' 처럼 점으로 내려갈 수 있다.
    False·0 은 값으로 보고, None·빈 문자열·빈 목록·빈 사전만 빈 값으로 본다."""
    try:
        d = json.load(open(path, encoding='utf-8'))
    except (OSError, ValueError):
        return False
    for k in keys:
        v = d
        for part in k.split('.'):
            v = v.get(part) if isinstance(v, dict) else None
        if v is None or v == '' or v == [] or v == {}:
            return False
    return True


def write_json(path, obj):
    """같은 폴더의 .<이름>.tmp 에 쓴 뒤 이름을 바꾼다."""
    d, n = os.path.split(path)
    tmp = os.path.join(d, '.' + n + '.tmp')
    with open(tmp, 'w', encoding='utf-8') as f:
        json.dump(obj, f, ensure_ascii=False, indent=1)
    os.replace(tmp, path)


def _clear_ro(func, path, *_):
    """윈도우 git clone 이 읽기 전용으로 만든 pack 파일도 지우게 속성을 풀고 다시 지운다."""
    os.chmod(path, stat.S_IWRITE)
    func(path)


def rmtree(path):
    if sys.version_info >= (3, 12):
        shutil.rmtree(path, onexc=_clear_ro)
    else:
        shutil.rmtree(path, onerror=_clear_ro)


def read_ids(path):
    """턴 목록 파일의 턴 ID. 빈 줄은 건너뛰고, 숫자가 아닌 줄이 있으면 멈춘다."""
    ids = []
    for n, line in enumerate(open(path, encoding='utf-8'), 1):
        s = line.strip()
        if not s:
            continue
        if not s.isdigit():
            raise SystemExit(f'{path}:{n} 턴 목록에는 턴 ID(숫자)만 둔다')
        ids.append(s)
    return ids


def turn_details():
    """{턴 ID: 턴 세부}. 같은 ID 가 여러 파일에 다른 내용으로 있으면 멈춘다."""
    files = [os.environ['REPLAY_TURNS']] if os.environ.get('REPLAY_TURNS') else sorted(
        glob.glob(os.path.join(dc_eval(), 'replay', 'turns', 'turns-*.jsonl')))
    out = {}
    for f in files:
        for line in open(f, encoding='utf-8'):
            if not line.strip():
                continue
            t = json.loads(line)
            k = str(t['idx'])
            if k in out and out[k] != t:
                raise SystemExit(f'턴 {k} 가 여러 세부 파일에 다른 내용으로 있다')
            out[k] = t
    return out


def session_path(t):
    """원본 세션 파일, 없으면 sessions-backup 의 사본(<프로젝트 폴더 이름>/<파일 이름>)."""
    src = t['session_file']
    if os.path.isfile(src):
        return src
    norm = src.replace(chr(92), '/')
    bak = os.path.join(dc_eval(), 'replay', 'sessions-backup', os.path.basename(os.path.dirname(norm)), os.path.basename(norm))
    if os.path.isfile(bak):
        return bak
    raise FileNotFoundError(f'세션 파일과 사본이 모두 없다: {os.path.basename(norm)}')


def show(rev, path):
    return subprocess.run(['git', '-C', RT, 'show', f'{rev}:{path}'], capture_output=True, check=True).stdout.decode('utf-8').replace(chr(13) + NL, NL)


def banned_view(rev):
    """그 리비전의 _banned_words.sh 와 원본 표를 임시 폴더에 쓰고 banned_view 출력을 돌려준다."""
    d = tempfile.mkdtemp(prefix='bview-')
    try:
        fn, tb = os.path.join(d, '_banned_words.sh'), os.path.join(d, 'korean-banned-words.md')
        open(fn, 'w', encoding='utf-8', newline=NL).write(show(rev, 'hooks/_banned_words.sh'))
        open(tb, 'w', encoding='utf-8', newline=NL).write(show(rev, 'korean-banned-words.md'))
        p = subprocess.run([BASH, '-c', '. "$1"; banned_view "$2"', '_', fn.replace(chr(92), '/'), tb.replace(chr(92), '/')],
                           capture_output=True)
        out = p.stdout.decode('utf-8').replace(chr(13) + NL, NL).rstrip(NL)
        if p.returncode != 0 or not out:
            raise SystemExit(f'상시 보기를 만들지 못함: {p.stderr.decode("utf-8", "replace")[:300]}')
        return out
    finally:
        rmtree(d)


def context(cond):
    """(rev, 설정 CLAUDE.md 글, 리마인더 블록). CLAUDE.md 는 실제 PC 전역 지시(DC_EVAL_BASE_MD)에 그 리비전의 원칙과 금지어를 잇는다."""
    base, suffix = parse_cond(cond)
    rev = rev_of(cond)
    if base == 'v1' or suffix == '-table':
        banned = show(rev, 'korean-banned-words.md')
    else:
        banned = banned_view(rev)
    # PC 전역 지시 파일. 경로는 환경 변수로 받는다(사내 플러그인 경로를 공개 저장소에 적지 않는다). 없으면 빈 글.
    base_md = os.environ.get('DC_EVAL_BASE_MD', '')
    ax = open(base_md, encoding='utf-8').read() if base_md and os.path.isfile(base_md) else ''
    if base_md and not ax:
        print(f'경고: DC_EVAL_BASE_MD 파일을 읽지 못해 PC 전역 지시 없이 진행한다: {base_md}', file=sys.stderr)
    text = ax + NL + NL + show(rev, 'agent-principles.md') + NL + NL + banned
    hook = show(rev, 'hooks/reply_reminder_userpromptsubmit.sh')
    remind = hook.split('msg="', 1)[1].split('"' + NL + 'printf', 1)[0]
    return rev, text, remind


def token():
    """실제 설정의 로그인 토큰. 만료가 가까우면 프로세스에 하나인 기한까지 갱신을 기다린다."""
    global _token_deadline
    path = os.path.join(home(), '.claude', '.credentials.json')
    while True:
        c = json.load(open(path, encoding='utf-8'))['claudeAiOauth']
        left = (c['expiresAt'] / 1000 - time.time()) / 3600
        if left >= TOKEN_MIN_H:
            _token_deadline = None
            return c['accessToken']
        if _token_deadline is None:
            _token_deadline = time.time() + 60 * float(os.environ.get('TOKEN_WAIT_MIN', '60'))
        if time.time() >= _token_deadline:
            raise TokenError(f'토큰 남은 시간 {left:.1f}시간. 평소 Claude Code 세션을 한 번 열어 갱신한 뒤 다시 실행한다')
        print(f'토큰 남은 시간 {left:.1f}시간, 갱신을 기다린다', file=sys.stderr, flush=True)
        time.sleep(60)


def env_for(cfg):
    """claude -p 실행 환경. 설정 폴더를 cfg 로 바꾸고, 마지막 턴 뒤 백그라운드 작업을 끊는 대기를 끈다."""
    e = {k: v for k, v in os.environ.items()
         if k not in ('ANTHROPIC_API_KEY', 'CLAUDECODE', 'CLAUDE_CODE_ENTRYPOINT', 'CLAUDE_HOME_DIR', 'CLAUDE_CODE_OAUTH_TOKEN')}
    e.update(CLAUDE_CONFIG_DIR=cfg, CLAUDE_CODE_OAUTH_TOKEN=token(), CLAUDE_CODE_PRINT_BG_WAIT_CEILING_MS='0')
    return e


def call_claude(args, prompt, cwd, env, timeout):
    """claude <args> 를 실행해 표준 출력을 돌려준다. 시험은 이 함수를 가짜로 바꾼다."""
    p = subprocess.run(['claude'] + args, input=prompt, cwd=cwd, env=env, capture_output=True, text=True, encoding='utf-8', timeout=timeout)
    return p.stdout + ('' if p.stdout.strip() else p.stderr)


def flatten(content):
    if isinstance(content, str):
        return content
    out = []
    for b in content or []:
        if not isinstance(b, dict):
            continue
        t = b.get('type')
        if t == 'text':
            out.append(b.get('text', ''))
        elif t == 'tool_use':
            out.append(f"[도구 실행 {b.get('name')}] {json.dumps(b.get('input'), ensure_ascii=False)[:600]}")
        elif t == 'tool_result':
            c = b.get('content')
            if isinstance(c, list):
                c = NL.join(x.get('text', '') for x in c if isinstance(x, dict))
            out.append(f"[도구 결과] {str(c)[:TOOL_CAP]}")
    return NL.join(x for x in out if x.strip())


def text_of(r):
    return flatten(r.get('message', {}).get('content'))


def real_user(r):
    if r['type'] != 'user':
        return False
    c = r.get('message', {}).get('content')
    x = c if isinstance(c, str) else NL.join(b.get('text', '') for b in (c or []) if isinstance(b, dict) and b.get('type') == 'text')
    return bool(x.strip()) and not re.search(r'^\s*<|<system-reminder>', x)


def conversation(path, correction_uuid):
    """(재현할 메시지 앞의 기록, 재현할 사용자 메시지, 당시 답)."""
    rows = {}
    for line in open(path, encoding='utf-8', errors='replace'):
        try:
            r = json.loads(line)
        except ValueError:
            continue
        if r.get('uuid') and r.get('type') in ('user', 'assistant', 'system', 'attachment'):
            rows[r['uuid']] = r
    chain = []
    u = rows[correction_uuid].get('parentUuid')
    while u and u in rows:
        chain.append(rows[u])
        u = rows[u].get('parentUuid') or rows[u].get('logicalParentUuid')
    chain.reverse()
    msgs = [r for r in chain if r['type'] in ('user', 'assistant') and not r.get('isMeta') and not r.get('isSidechain')]
    k = len(msgs) - 1
    while k >= 0 and not real_user(msgs[k]):
        k -= 1
    if k < 0:
        raise ValueError('사용자 메시지를 찾지 못함')
    return msgs[:k], text_of(msgs[k]), NL.join(text_of(r) for r in msgs[k + 1:] if r['type'] == 'assistant')


def write_session(hist, cfg, cwd, sid):
    d = os.path.join(cfg, 'projects', re.sub(r'[^A-Za-z0-9]', '-', cwd))
    os.makedirs(d, exist_ok=True)
    merged = []
    for r in hist[-MAX_MSGS:]:
        x = text_of(r).strip()
        if not x:
            continue
        if merged and merged[-1][0] == r['type']:
            merged[-1][1] += NL + NL + x
        else:
            merged.append([r['type'], x])
    while merged and merged[0][0] != 'user':
        merged.pop(0)
    prev = None
    with open(os.path.join(d, sid + '.jsonl'), 'w', encoding='utf-8', newline=NL) as f:
        for role, x in merged:
            me = str(uuid.uuid4())
            base = {'parentUuid': prev, 'isSidechain': False, 'userType': 'external', 'cwd': cwd, 'sessionId': sid, 'version': '2.1.316', 'uuid': me,
                    'timestamp': '2026-11-11T00:00:00.000Z', 'type': role}
            if role == 'user':
                base['message'] = {'role': 'user', 'content': x}
            else:
                base['message'] = {'id': 'msg_' + me.replace('-', ''), 'type': 'message', 'role': 'assistant', 'model': MODEL,
                                   'content': [{'type': 'text', 'text': x}], 'stop_reason': 'end_turn', 'stop_sequence': None,
                                   'usage': {'input_tokens': 0, 'output_tokens': 0}}
            f.write(json.dumps(base, ensure_ascii=False) + NL)
            prev = me
    return len(merged)


def checkout_copy(src_cwd, ts, dest):
    """턴의 cwd 저장소를 dest 에 --local --no-hardlinks 로 복제하고(하드 링크면 사본 정리가 원본 pack 의 읽기 전용 속성을 바꾼다)
    턴 시각 직전 커밋으로 체크아웃한다. 돌려주는 값은 cwd 에 해당하는 사본 안 경로다."""
    p = subprocess.run(['git', '-C', src_cwd, 'rev-parse', '--show-toplevel'], capture_output=True, text=True)
    if p.returncode != 0:
        raise ValueError(f'cwd 가 git 저장소가 아님: {src_cwd}')
    top = p.stdout.strip()
    rel = os.path.relpath(os.path.normcase(os.path.abspath(src_cwd)), os.path.normcase(os.path.abspath(top)))
    subprocess.run(['git', 'clone', '--local', '--no-hardlinks', '--quiet', top, dest], check=True, capture_output=True)
    c = subprocess.run(['git', '-C', dest, 'rev-list', '-1', f'--before={ts}', 'HEAD'], capture_output=True, text=True, check=True).stdout.strip()
    if not c:
        raise ValueError(f'{ts} 이전 커밋이 없음')
    subprocess.run(['git', '-C', dest, 'checkout', '--quiet', '--detach', c], check=True, capture_output=True)
    return (dest if rel == '.' else os.path.join(dest, rel)).replace(chr(92), '/')


def run(t, out_dir, cond, rev, text, remind):
    idx = t['idx']
    out = f'{out_dir}/{cond}-{idx}.json'
    if done(out, ['response']):
        return f'{idx} skip'
    tools = cond.endswith('-tools')
    os.makedirs(tmp_root(), exist_ok=True)
    tmp = tempfile.mkdtemp(prefix='replay-', dir=tmp_root()).replace(chr(92), '/')
    try:
        cfg = tmp + '/cfg'
        os.makedirs(cfg)
        if tools:
            cwd = checkout_copy(t['cwd'], t['ts'], tmp + '/work')
        else:
            cwd = tmp + '/work'
            os.makedirs(cwd)
        open(cfg + '/CLAUDE.md', 'w', encoding='utf-8', newline=NL).write(text)
        open(cfg + '/settings.json', 'w', encoding='utf-8').write('{"outputStyle": "Concise"}')
        hist, ask, old = conversation(session_path(t), t['correction_uuid'])
        judge_ask = ask
        ask = ask + NL + NL + '<system-reminder>' + NL + 'UserPromptSubmit hook additional context:' + NL + remind + NL + '</system-reminder>' + NL
        sid = str(uuid.uuid4())
        n = write_session(hist, cfg, cwd, sid)
        # 이전 대화가 없는 첫 메시지 턴은 재개할 세션이 없으므로(`No conversation found`) 같은 설정으로 새 세션을 시작한다
        args = ['-p'] + (['--resume', sid] if n else [])
        if tools:
            args += ['--tools', 'Read,Grep,Glob', '--max-turns', '15']
        else:
            args += ['--tools', '', '--append-system-prompt', NO_TOOLS_NOTE]
        args += ['--model', MODEL, '--output-format', 'json']
        stdout = call_claude(args, ask, cwd, env_for(cfg), 900)
        try:
            j = json.loads(stdout)
        except ValueError:
            j = {'is_error': True, 'result': stdout[-400:]}
        models = list((j.get('modelUsage') or {}).keys())
        require_model(models)
        if not models and not j.get('is_error'):
            return f'{idx} FAIL modelUsage 가 비어 모델을 확인하지 못함'
        res = {'idx': idx, 'cond': cond, 'kind': t['kind'], 'rev': rev, 'decision_point': t.get('decision_point', ''),
               'clauses': t['clauses'] if isinstance(t.get('clauses'), list) else ast.literal_eval(t.get('clauses') or '[]'),
               'ask': judge_ask, 'old': old, 'correction': t.get('user', ''), 'why': t.get('why', ''), 'history_msgs': n,
               'response': j.get('result', ''), 'error': bool(j.get('is_error')), 'models': models, 'usage': j.get('usage'),
               'num_turns': j.get('num_turns'), 'cost': j.get('total_cost_usd')}
        if res['error'] or not res['response']:
            return f"{idx} FAIL {str(res['response'])[:120]}"
        write_json(out, res)
        return f"{idx} len={len(res['response'])} models={res['models']} turns={res['num_turns']}"
    finally:
        rmtree(tmp)


def free_gb():
    """여유 메모리(GB). 윈도우 밖에서는 확인하지 않고 무한대를 돌려준다."""
    if os.name != 'nt':
        return float('inf')
    import ctypes

    class M(ctypes.Structure):
        _fields_ = [('l', ctypes.c_ulong), ('load', ctypes.c_ulong), ('tot', ctypes.c_ulonglong), ('avail', ctypes.c_ulonglong),
                    ('tp', ctypes.c_ulonglong), ('ap', ctypes.c_ulonglong), ('tv', ctypes.c_ulonglong), ('av', ctypes.c_ulonglong), ('ax', ctypes.c_ulonglong)]
    m = M()
    m.l = ctypes.sizeof(M)
    ctypes.windll.kernel32.GlobalMemoryStatusEx(ctypes.byref(m))
    return m.avail / 2**30


def gated(fn, force):
    """작업마다 시작 직전에 업무 시간을 확인하고(force 면 생략), 여유 메모리가 MEM_MIN_GB(기본 2.5) 미만이면 시작을 미룬다."""
    def w(*a, **k):
        check_office_hours(force)
        lim = float(os.environ.get('MEM_MIN_GB', '2.5'))
        while free_gb() < lim:
            time.sleep(30)
        check_office_hours(force)
        return fn(*a, **k)
    return w


def pool(jobs, fn, on_result, force):
    """jobs 를 PAR(기본 2)개씩 실행한다. Stop(다른 모델, 업무 시간, 토큰 기한)이 나면 남은 작업을 취소하고 그 예외를 다시 낸다.
    다른 예외는 그 작업만 ERR 로 알리고 나머지를 계속한다."""
    with cf.ThreadPoolExecutor(int(os.environ.get('PAR', '2'))) as ex:
        futs = {ex.submit(gated(fn, force), *j): j for j in jobs}
        try:
            for f in cf.as_completed(futs):
                try:
                    on_result(futs[f], f.result())
                except Stop:
                    raise
                except Exception as e:  # 한 턴의 실패가 나머지 턴을 멈추지 않게 한다
                    print('ERR', futs[f][0].get('idx') if isinstance(futs[f][0], dict) else futs[f][0], repr(e)[:300], flush=True)
        except Stop:
            ex.shutdown(cancel_futures=True)
            raise


def main(argv):
    if argv[:1] == ['--print-context'] and len(argv) == 2:
        _, text, remind = context(argv[1])
        sys.stdout.reconfigure(encoding='utf-8')
        print(text)
        print()
        print('<system-reminder>' + NL + 'UserPromptSubmit hook additional context:' + NL + remind + NL + '</system-reminder>')
        return 0
    force = '--now' in argv
    argv = [a for a in argv if a != '--now']
    if len(argv) != 3 or argv[0] in ('-h', '--help'):
        print('사용: python _replay.py <답 폴더> <조건> <턴 목록> [--now]  |  python _replay.py --print-context <조건>')
        return 2
    out_dir, cond, turn_list = argv
    parse_cond(cond)
    guard_office_hours(force)
    ids = read_ids(turn_list)
    turns = turn_details()
    missing = [i for i in ids if i not in turns]
    if missing:
        raise SystemExit(f'턴 세부 파일에 없는 턴: {missing}')
    os.makedirs(out_dir, exist_ok=True)
    rev, text, remind = context(cond)
    try:
        pool([(turns[i], out_dir, cond, rev, text, remind) for i in ids], run, lambda job, r: print(r, flush=True), force)
    except Stop as e:
        print('중단:', e, file=sys.stderr)
        return e.code
    return 0


if __name__ == '__main__':
    sys.exit(main(sys.argv[1:]))
