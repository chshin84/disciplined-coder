# translate.py: 한국어 원칙 문안을 하이쿠로 영어로 옮긴다. en-orig.md 는 ko-orig.md 를 줄마다 옮긴 문안이고, en-strong.md 는
# en-orig.md 에서 채택한 조항 줄만 ko-strong.md 의 같은 조항 줄을 옮긴 문장으로 바꾼 문안이다.
# 하이쿠가 번역 대신 다른 말을 돌려주는 일이 있어, 줄 형식을 검사하고 어기면 다시 옮긴다.
import json, os, re, subprocess, tempfile
from concurrent.futures import ThreadPoolExecutor
D = os.path.dirname(os.path.abspath(__file__)); W = tempfile.mkdtemp()
RULE = ("Translate the Korean text between <<< and >>> into English. Output only the translation, nothing else. "
        "Keep the Markdown structure, backticked IDs, file names and code exactly. "
        "Keep every quoted Korean example sentence (inside '...', \"...\" or backticks) in Korean, untranslated, because it illustrates Korean writing. "
        "Translate imperative instructions as English imperatives. Keep any instruction about writing output in Korean.\n\n<<<\n")
HEAD = re.compile(r"- \*\*`([A-Z-]+)`")

def tr1(text):
    p = subprocess.run(["claude", "-p", "--model", "claude-haiku-5-5", "--tools", "", "--setting-sources", "",
                        "--no-session-persistence", "--output-format", "json"],
                       input=(RULE + text + "\n>>>").encode("utf-8"), capture_output=True, cwd=W, timeout=900)
    try:
        return json.loads(p.stdout.decode("utf-8"))["result"].strip().removeprefix("<<<").removesuffix(">>>").strip()
    except Exception:
        return ""

def tr(text):
    if not text.strip():
        return text
    m = HEAD.match(text)
    for _ in range(4):
        out = tr1(text)
        # 하이쿠가 조항 앞에 제목을 붙이거나 줄을 나누는 일이 있다. 조항 머리부터 잘라 한 줄로 잇는다.
        if m and m.group(0) in out:
            out = " ".join(out[out.index(m.group(0)):].split()).strip()
        if out and "\n" not in out and "<<<" not in out and "Translate the" not in out and (not m or out.startswith(m.group(0))):
            return out
    raise SystemExit("translation failed: " + text[:60])

ko = open(os.path.join(D, "ko-orig.md"), encoding="utf-8").read()
kos = open(os.path.join(D, "ko-strong.md"), encoding="utf-8").read()
lines = {m.group(1): m.group(0) for m in re.finditer(r"^- \*\*`([A-Z-]+)`.*$", kos, re.M)}
changed = {k: v for k, v in lines.items() if v not in ko}
with ThreadPoolExecutor(16) as ex:
    en = "\n".join(ex.map(tr, ko.split("\n")))
    en_lines = dict(zip(changed, ex.map(tr, changed.values())))
open(os.path.join(D, "en-orig.md"), "w", encoding="utf-8", newline="\n").write(en)
json.dump(en_lines, open(os.path.join(D, "en-strong-lines.json"), "w", encoding="utf-8"), ensure_ascii=False, indent=1)
s = en
for cid, line in en_lines.items():
    s, n = re.subn(r"^- \*\*`" + re.escape(cid) + r"`.*$", lambda m: line, s, flags=re.M)
    assert n == 1, cid
open(os.path.join(D, "en-strong.md"), "w", encoding="utf-8", newline="\n").write(s)
ids = lambda t: sorted(re.findall(r"^- \*\*`([A-Z-]+)`", t, re.M))
assert ids(en) == ids(ko), set(ids(ko)) ^ set(ids(en))
print("lines", ko.count("\n") + 1, "strong lines", len(en_lines))
