"""판독 페이지 생성기. 같은 사용자 메시지에 두 조건으로 쓴 답 A·B 를 좌우에 나란히 두고, 판정자의 점수와 근거를 답보다
먼저 보이고, 사용자가 같은 다섯 단계로 고치게 하는 로컬 HTML 을 만든다. 형식은 skills/side-by-side/SKILL.md 「판독 페이지 형식」이
소유한다. 저장소 밖 gen_reading_v5.py(2026-11-13 v2 재건축 3단계)를 옮겼다. eval_replay_report.sh 가 판독 후보로 실행한다.

형광은 _judge.py 판정의 x_quotes·y_quotes 로 하고, 원문에서 찾지 못한 근거 문장은 답 칸 머리에 적는다. 「결과 복사」는
사용자가 표시한 쌍을 모두(판정자와 같아도) {"<idx>:<A>:<B>": <사용자 점수>} JSON 으로 클립보드에 넣는다
(_judge.py report --reading 이 읽는 형식). 페이지에는 실제 대화가 들어 있으므로 저장소 밖에 둔다.

사용: python side_by_side.py <출력 html> <저장 키> <답 폴더> <판정 폴더> <idx:A:B>..."""
import html, json, os, re, sys

sys.path.insert(0, os.path.dirname(os.path.abspath(__file__)))
from _judge import judge_button  # noqa: E402

BASE_CSS = """
:root{--bg:#f6f7f9;--card:#fff;--ink:#1d2330;--ink2:#5b6577;--hair:#e2e6ec;--user:#2f6fde;--hlU:#ffe58a;--hlJ:#c9ecff;--up:#1f8a4c;--down:#c4372f;--accent:#2f6fde;--tint:#f0f3f8}
@media (prefers-color-scheme:dark){:root:not([data-theme="light"]){--bg:#14171d;--card:#1c2029;--ink:#e6e9ef;--ink2:#9aa3b2;--hair:#2c323d;--user:#3b74d9;--hlU:#6b5a12;--hlJ:#164a66;--up:#4cc382;--down:#ef6b62;--tint:#232833}}
:root[data-theme="dark"]{--bg:#14171d;--card:#1c2029;--ink:#e6e9ef;--ink2:#9aa3b2;--hair:#2c323d;--user:#3b74d9;--hlU:#6b5a12;--hlJ:#164a66;--up:#4cc382;--down:#ef6b62;--tint:#232833}
*{box-sizing:border-box}body{margin:0;background:var(--bg);color:var(--ink);font:15px/1.6 "Pretendard","Malgun Gothic",sans-serif}
.wrap{max-width:1320px;margin:0 auto;padding:16px}
.top{position:sticky;top:0;z-index:5;background:var(--bg);border-bottom:1px solid var(--hair);padding:10px 16px;display:flex;gap:12px;align-items:center;flex-wrap:wrap}
.nav a{display:inline-block;padding:2px 9px;border:1px solid var(--hair);border-radius:12px;margin-right:4px;color:var(--ink2);text-decoration:none;font-size:13px}
.nav a.on{background:var(--accent);color:#fff;border-color:var(--accent)}
.legend{margin-left:auto;font-size:13px;color:var(--ink2)}.legend mark{padding:0 4px}
mark.u{background:var(--hlU);color:inherit}mark.j{background:var(--hlJ);color:inherit}
.ctx{display:grid;gap:8px;margin:16px 0}
.who{font-size:12px;color:var(--ink2);text-align:right}
.bubble{justify-self:end;max-width:720px;padding:10px 14px;border-radius:14px;border-bottom-right-radius:4px;background:var(--user);color:#fff}
.callout{border-left:4px solid var(--down);background:var(--card);padding:10px 14px;border-radius:6px}.callout p{margin:2px 0}
.verdict{display:flex;gap:16px;align-items:center;background:var(--card);border:2px solid var(--up);border-radius:12px;padding:12px 16px;margin:14px 0;flex-wrap:wrap}
.verdict .big{font-size:26px;font-weight:800;color:var(--up);min-width:64px;text-align:center}
.verdict .why{flex:1;min-width:260px;font-size:14px}
.verdict .sub{font-size:12px;color:var(--ink2)}
.scale{display:flex;gap:6px;flex-wrap:wrap;margin:6px 0 10px}
.scale button{flex:1;min-width:96px;padding:8px 4px;border:1px solid var(--hair);background:var(--card);color:var(--ink);border-radius:8px;cursor:pointer;font:inherit;font-size:13px;position:relative}
.scale button.sel{background:var(--accent);color:#fff;border-color:var(--accent)}
.scale button.judge::after{content:"판정자";position:absolute;top:-9px;right:6px;font-size:10.5px;background:var(--hlJ);color:var(--ink);padding:0 5px;border-radius:6px}
.grid{display:grid;grid-template-columns:1fr 1fr;gap:14px}
.colhead{position:sticky;top:50px;z-index:4;background:var(--bg);padding:6px 0;font-weight:700}
.colhead small{display:block;font-weight:400;color:var(--ink2);font-size:12px}
.note{font-size:12.5px;color:var(--ink2)}
.ans{background:var(--card);border:1px solid var(--hair);border-radius:14px;border-top-left-radius:4px;padding:4px 16px;max-height:72vh;overflow:auto;font-size:14px}
.ans table{border-collapse:collapse;font-size:13px;margin:8px 0}.ans th,.ans td{border:1px solid var(--hair);padding:4px 7px;vertical-align:top}
.ans th{background:var(--tint)}.ans code{background:var(--tint);padding:0 3px;border-radius:3px;font-size:12.5px}
.ans h1,.ans h2,.ans h3{font-size:15px;margin:14px 0 6px}.ans pre{white-space:pre-wrap;background:var(--tint);padding:8px}
.sync{font-size:13px;color:var(--ink2)}
@media (max-width:760px){.grid{grid-template-columns:1fr}.colhead{position:static}.legend{margin-left:0}}
"""
E = lambda x: html.escape(str(x))
LABEL = {-2: '−2 많이 나빠짐', -1: '−1 조금 나빠짐', 0: '0 차이 없음', 1: '+1 조금 나아짐', 2: '+2 많이 나아짐'}
XY = lambda t, o: re.sub(r'(?<![A-Za-z])[XY](?![A-Za-z])', lambda m: {'X': o[0], 'Y': o[1]}[m.group(0)], t)
fmt = lambda s: ('+' if s > 0 else '') + (f'{s:.1f}'.rstrip('0').rstrip('.') if s != int(s) else str(int(s)))
NONE_RULE = '진행해라고 하면 진행하고, 물어보면 물어본 것만 답변하고'


def cname(c):
    tools = c.endswith('-tools')
    b = c[:-6] if tools else c
    if b == 'v1':
        n = '현행(v1)'
    elif re.fullmatch(r'v2\.\d+-table', b):
        n = 'v2 원칙 + 원본 표'
    elif re.fullmatch(r'v2\.\d+', b):
        n = f'새 지시({b})'
    else:
        n = b
    return n + (' · 도구 사용' if tools else '')


def main(argv):
    if len(argv) < 5:
        print('사용: python side_by_side.py <출력 html> <저장 키> <답 폴더> <판정 폴더> <idx:A:B>...')
        return 2
    out_path, key, ad, jd, pairs = argv[0], argv[1], argv[2], argv[3], argv[4:]
    out, nav, HL = [], [], {}
    names = set()
    for n, arg in enumerate(pairs, 1):
        idx, a, b = arg.split(':')
        names.update((a, b))
        A = json.load(open(f'{ad}/{a}-{idx}.json', encoding='utf-8')); B = json.load(open(f'{ad}/{b}-{idx}.json', encoding='utf-8'))
        P = json.load(open(f'{jd}/{idx}-{a}-{b}.json', encoding='utf-8'))
        s = P.get('score'); ab, ba = P['ab'], P['ba']
        # AB 순서는 X=A·Y=B, BA 순서는 X=B·Y=A. u = 문제가 드러난 문장(x_quotes), j = 점수 근거(y_quotes)
        HL[n] = {'A': {'u': ab.get('x_quotes', []), 'j': ba.get('y_quotes', [])}, 'B': {'u': ba.get('x_quotes', []), 'j': ab.get('y_quotes', [])}}
        tone = {'개선': 'up', '악화': 'down'}.get(P.get('cls'), 'flat')
        jcls = P.get('cls')
        near = judge_button(s, jcls) if s is not None else None
        btn = ''.join(f'<button data-v="{v}" class="{"judge" if v == near else ""}">{LABEL[v]}</button>' for v in (-2, -1, 0, 1, 2))
        kind = A.get('kind', '')
        if kind == '지적없음':
            ctx = (f'<div class="callout"><p><b>지적이 없던 턴</b></p><p>판정 기준은 사용자가 밝힌 요구 「{E(NONE_RULE)}」입니다. '
                   f'형광은 판정자가 근거로 든 문장입니다.</p></div>')
        else:
            ctx = f'<div class="callout"><p><b>그 답을 읽은 사용자의 실제 지적</b></p><p>{E(A["correction"])}</p></div>'
        sub = ' · '.join(x for x in (kind, A.get('decision_point', '')) if x)
        nav.append(f'<a href="#c{n}" data-n="{n}">{n}</a>')
        s2 = -ba['score'] if 'score' in ba else '?'
        out.append(f'''<section class="pair" id="c{n}" data-k="{idx}:{a}:{b}">
<h2>쌍 {n} <small>사례 {idx}{" · " + E(sub) if sub else ""}</small></h2>
<div class="ctx"><div class="who">당시 사용자 메시지</div><div class="bubble">{E(A["ask"])}</div>
{ctx}</div>
<div class="verdict {tone}"><div class="big">{fmt(s) if s is not None else "?"}</div>
<div class="why"><b>판정자: B 가 A 보다 {LABEL[near].split(" ", 1)[1] if near is not None else "판정 실패"} · 분류 {E(jcls or "없음")}</b> <span class="sub">(A·B 순서를 바꿔 두 번 매긴 평균. 두 점수 {ab.get("score")} / {s2})</span><br>
A 를 먼저 보인 판정: {E(XY(ab.get("note", ""), "AB"))}<br>B 를 먼저 보인 판정: {E(XY(ba.get("note", ""), "BA"))}</div></div>
<b>B 가 A 보다 나아졌습니까?</b>
<div class="scale">{btn}</div>
<div class="grid">
<div class="colhead">A · {E(cname(a))}</div>
<div class="colhead">B · {E(cname(b))}</div>
<div class="ans" data-s="A"><pre class="md">{E(A["response"])}</pre></div>
<div class="ans" data-s="B"><pre class="md">{E(B["response"])}</pre></div>
</div>
<p class="tools"><label><input type="checkbox" class="sync" checked> 두 답을 함께 스크롤</label>
<input class="memo" placeholder="한 줄 메모(선택)"></p>
</section>''')

    css = BASE_CSS + """
.pair{border-top:1px solid var(--hair);padding-top:8px;margin-top:28px}.pair h2{font-size:18px;margin:8px 0}.pair h2 small{font-size:12.5px;color:var(--ink2);font-weight:400}
.verdict.down{border-color:var(--down)}.verdict.down .big{color:var(--down)}.verdict.flat{border-color:var(--hair)}.verdict.flat .big{color:var(--ink2)}
.tools{font-size:13px;color:var(--ink2)}.memo{width:50%;padding:4px 8px;border:1px solid var(--hair);border-radius:6px;background:var(--card);color:var(--ink)}
.nav a.done{border-color:var(--up);color:var(--up)}#out{white-space:pre-wrap;background:var(--card);border:1px solid var(--hair);padding:12px;border-radius:8px}
#copy{padding:8px 14px;border:1px solid var(--accent);background:var(--accent);color:#fff;border-radius:8px;cursor:pointer;font:inherit;margin:6px 0}#copied{margin-left:8px;font-size:13px;color:var(--ink2)}
"""
    js = """
var KEY=%s;var st={};try{st=JSON.parse(localStorage.getItem(KEY)||'{}');}catch(e){}
function save(){try{localStorage.setItem(KEY,JSON.stringify(st));}catch(e){}render();}
function wrapText(root,q,cls){if(!q)return false;var blocks=root.querySelectorAll('p,li,td,th,h1,h2,h3,h4,h5,h6,pre');
for(var bi=0;bi<blocks.length;bi++){var bl=blocks[bi];var w=document.createTreeWalker(bl,NodeFilter.SHOW_TEXT),n,ns=[],txt='';while(n=w.nextNode()){ns.push([n,txt.length]);txt+=n.nodeValue;}
var i=txt.indexOf(q);if(i<0)continue;var e=i+q.length;
ns.forEach(function(p){var t=p[0],s0=p[1],s1=s0+t.nodeValue.length;var a=Math.max(i,s0),b=Math.min(e,s1);if(a>=b)return;var r=document.createRange();r.setStart(t,a-s0);r.setEnd(t,b-s0);var m=document.createElement('mark');m.className=cls;try{r.surroundContents(m);}catch(x){}});return true;}return false;}
function hl(root,q,cls){if(wrapText(root,q,cls))return true;var hit=false;q.split(/[.。?!]\\s*/).filter(function(s){return s.length>=8;}).forEach(function(p){if(wrapText(root,p,cls))hit=true;});return hit;}
if(window.marked&&window.DOMPurify)document.querySelectorAll('pre.md').forEach(function(p){var d=document.createElement('div');d.innerHTML=DOMPurify.sanitize(marked.parse(p.textContent,{gfm:true,breaks:true}));p.replaceWith(d);});
document.querySelectorAll('section.pair[data-k]').forEach(function(sec,ix){var n=ix+1,k=sec.dataset.k,h=HL[n];
sec.querySelectorAll('.ans').forEach(function(el){var side=el.dataset.s,miss=[];['u','j'].forEach(function(c){(h[side][c]||[]).forEach(function(q){if(!hl(el,q,c))miss.push(q);});});
if(miss.length){var p=document.createElement('p');p.className='note';p.textContent='원문에서 찾지 못한 근거 문장: '+miss.join(' / ');el.insertBefore(p,el.firstChild);}});
var as=sec.querySelectorAll('.ans'),lock=false,sy=sec.querySelector('.sync');
function f(x,y){return function(){if(lock||!sy.checked)return;lock=true;y.scrollTop=x.scrollTop/(x.scrollHeight-x.clientHeight||1)*(y.scrollHeight-y.clientHeight);requestAnimationFrame(function(){lock=false;});};}
as[0].addEventListener('scroll',f(as[0],as[1]));as[1].addEventListener('scroll',f(as[1],as[0]));
st[k]=st[k]||{};var bs=sec.querySelectorAll('.scale button');
bs.forEach(function(b){if(String(st[k].v)===b.dataset.v)b.classList.add('sel');b.onclick=function(){bs.forEach(function(y){y.classList.remove('sel');});b.classList.add('sel');st[k].v=b.dataset.v;save();};});
var me=sec.querySelector('.memo');me.value=st[k].m||'';me.oninput=function(){st[k].m=me.value;save();};});
function judgeOf(sec){var j=sec.querySelector('.scale button.judge');return j?Number(j.dataset.v):null;}
function marked_(){var o={};document.querySelectorAll('section.pair[data-k]').forEach(function(sec){var k=sec.dataset.k,s=st[k]||{};
if(s.v!==undefined)o[k]=Number(s.v);});return o;}
function render(){var L=[];document.querySelectorAll('section.pair[data-k]').forEach(function(sec,ix){var k=sec.dataset.k,s=st[k]||{},j=judgeOf(sec);
var a=document.querySelector('.nav a[data-n="'+(ix+1)+'"]');if(a)a.classList.toggle('done',s.v!==undefined);
L.push('쌍 '+(ix+1)+' ('+k+'): 사용자 '+(s.v!==undefined?(s.v>0?'+':'')+s.v:'미표시')+' / 판정자 '+(j!==null?(j>0?'+':'')+j:'?')+(s.m?' / 메모: '+s.m:''));});
document.getElementById('out').textContent=L.join('\\n');document.getElementById('json').textContent=JSON.stringify(marked_());}
document.getElementById('copy').onclick=function(){var t=JSON.stringify(marked_()),done=function(){document.getElementById('copied').textContent='복사했습니다';};
if(navigator.clipboard&&navigator.clipboard.writeText){navigator.clipboard.writeText(t).then(done,function(){fb(t);done();});}else{fb(t);done();}};
function fb(t){var x=document.createElement('textarea');x.value=t;document.body.appendChild(x);x.select();try{document.execCommand('copy');}catch(e){}x.remove();}
render();
"""
    a_names = ', '.join(cname(c) for c in sorted(names))
    page = f'''<!doctype html><html lang="ko"><head><meta charset="utf-8"><meta name="viewport" content="width=device-width,initial-scale=1">
<title>숨긴 세트 판독</title><style>{css}</style></head><body>
<div class="top"><b>판독</b><span class="nav">{"".join(nav)}</span>
<span class="legend"><mark class="u">지적이 겨눈 문제가 드러난 문장</mark> <mark class="j">판정자가 점수 근거로 든 문장</mark></span></div>
<div class="wrap">
<p>같은 사용자 메시지에 두 조건({E(a_names)})으로 쓴 답 A 와 B 입니다. 보실 것은 B 가 A 보다 나아졌는지 하나입니다. 판정자 점수가 맞으면 같은 단추를, 다르면 보시는 점수를 눌러 주십시오. 누르지 않은 쌍은 판정에 동의한 것으로 봅니다. 표시는 이 브라우저에 저장됩니다.</p>
{"".join(out)}
<section class="pair"><h2>표시 결과</h2><p>「결과 복사」를 누르면 점수를 누른 쌍이 모두 복사됩니다. 대화에 붙여 주십시오.</p>
<button id="copy">결과 복사</button><span id="copied"></span>
<pre id="json"></pre><div id="out"></div></section>
</div>
<script src="https://cdn.jsdelivr.net/npm/marked@12.0.2/marked.min.js"></script>
<script src="https://cdn.jsdelivr.net/npm/dompurify@3.1.6/dist/purify.min.js"></script>
<script>var HL={json.dumps(HL, ensure_ascii=False)};{js % json.dumps(key)}</script></body></html>'''
    open(out_path, 'w', encoding='utf-8').write(page)
    print('ok', len(out))
    return 0


if __name__ == '__main__':
    sys.exit(main(sys.argv[1:]))
