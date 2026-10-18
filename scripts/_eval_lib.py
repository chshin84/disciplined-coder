"""에이전트원칙 실패 평가 세트의 과제 읽기와 검사. 소비자는 test_eval_cases.sh, eval_principles.sh, eval_compare.sh 다.

과제 폴더마다 prompt.md(front matter 에 과제 머리, 본문에 프롬프트)와 criteria.md(판정 기준)를 둔다.
front matter 는 `키: 값` 과 `키: [a, b]` 만 쓴다. YAML 파서를 들이지 않으려고 이 두 형태로 한정한다.

사용: python _eval_lib.py <fields|pairs|secrets|list> <과제 폴더> [태그]
"""
import os
import re
import sys

REQUIRED = ("tags", "kind", "pair", "type", "failure", "clause")
TAGS = ("dev", "holdout")
KINDS = ("should", "should-not")
TYPES = ("chat", "tool", "workdoc", "deliverable", "code")
SECRET_PATTERNS = (
    (r"\b(sk-|AKIA|ghp_)[A-Za-z0-9_\-]{8,}", "키 형태 문자열"),
    (r"[A-Za-z0-9._%+\-]+@[A-Za-z0-9.\-]+\.[A-Za-z]{2,}", "메일 주소"),
    (r"(C:\\Users\\|/c/Users/|C:/Users/)", "사용자 PC 경로"),
)


def parse_front(text):
    """front matter 와 본문을 나눈다. front matter 가 없으면 ({}, text)."""
    if not text.startswith("---"):
        return {}, text
    end = text.find("\n---", 3)
    if end < 0:
        return {}, text
    head, body = text[3:end], text[end + 4:]
    meta = {}
    for line in head.splitlines():
        m = re.match(r"^([A-Za-z_]+):\s*(.*)$", line.strip())
        if not m:
            continue
        k, v = m.group(1), m.group(2).strip()
        if v.startswith("[") and v.endswith("]"):
            meta[k] = [x.strip() for x in v[1:-1].split(",") if x.strip()]
        else:
            meta[k] = v
    return meta, body.lstrip("\n")


def load_cases(root):
    """과제 이름 → {meta, prompt, criteria}."""
    cases = {}
    for name in sorted(os.listdir(root)):
        d = os.path.join(root, name)
        p = os.path.join(d, "prompt.md")
        if not os.path.isfile(p):
            continue
        meta, body = parse_front(open(p, encoding="utf-8").read())
        c = os.path.join(d, "criteria.md")
        crit = open(c, encoding="utf-8").read() if os.path.isfile(c) else ""
        cases[name] = {"meta": meta, "prompt": body, "criteria": crit}
    return cases


def check_fields(cases):
    errs = []
    for n, c in cases.items():
        m = c["meta"]
        for k in REQUIRED:
            if not m.get(k):
                errs.append(f"{n}: {k} 가 없다")
        tags = m.get("tags") or []
        if len([t for t in tags if t in TAGS]) != 1:
            errs.append(f"{n}: tags 에 dev·holdout 중 하나만 있어야 한다({tags})")
        if m.get("kind") and m["kind"] not in KINDS:
            errs.append(f"{n}: kind 값 {m['kind']}")
        if m.get("type") and m["type"] not in TYPES:
            errs.append(f"{n}: type 값 {m['type']}")
        if not c["criteria"].strip():
            errs.append(f"{n}: criteria.md 가 비었다")
    return errs


def check_pairs(cases):
    errs = []
    for n, c in cases.items():
        p = c["meta"].get("pair")
        if not p:
            continue
        if p not in cases:
            errs.append(f"{n}: pair {p} 가 없다")
        elif cases[p]["meta"].get("kind") == c["meta"].get("kind"):
            errs.append(f"{n}: 짝 {p} 와 kind 가 같다")
        elif cases[p]["meta"].get("pair") != n:
            errs.append(f"{n}: 짝 {p} 가 이 과제를 가리키지 않는다")
    return errs


def check_secrets(root):
    errs = []
    for dp, _, fs in os.walk(root):
        for f in fs:
            t = open(os.path.join(dp, f), encoding="utf-8", errors="replace").read()
            for pat, label in SECRET_PATTERNS:
                if re.search(pat, t):
                    errs.append(f"{os.path.relpath(os.path.join(dp, f), root)}: {label}")
    return errs


def load_result(results, label):
    import json
    return json.load(open(os.path.join(results, label, "result.json"), encoding="utf-8"))


def banned_count(texts, pairs_path, excl_path):
    """banned_parse 가 낸 pairs·excl 로 금지어 출현 횟수를 센다. 제외어 안의 글자는 세지 않는다."""
    rows = [l.rstrip("\n").split("\t")[1:] for l in open(pairs_path, encoding="utf-8")]
    excl = [[e for e in l.rstrip("\n").split("\t") if e] for l in open(excl_path, encoding="utf-8")]
    n = 0
    for t in texts:
        for i, toks in enumerate(rows):
            masked = t
            # 긴 제외어부터 덮어야 짧은 제외어가 긴 것의 일부를 먼저 먹지 않는다.
            for e in sorted(excl[i] if i < len(excl) else [], key=len, reverse=True):
                masked = masked.replace(e, "\0" * len(e))
            n += sum(masked.count(tok) for tok in toks)
    return n


def violations(result):
    """과제 이름 → 위반 회차 수."""
    out = {}
    for r in result["runs"]:
        out[r["case"]] = out.get(r["case"], 0) + (1 if r["violated"] else 0)
    return out


def chat_texts(result, cases):
    return [r["response"] for r in result["runs"] if cases.get(r["case"], {}).get("meta", {}).get("type") == "chat"]


def compare(cases_dir, results, labels, pairs_path, excl_path):
    cases = load_cases(cases_dir)
    res = [load_result(results, l) for l in labels]
    vs = [violations(r) for r in res]
    bans = [banned_count(chat_texts(r, cases), pairs_path, excl_path) for r in res]
    if len(labels) == 1:
        r = res[0]
        return [f"라벨={labels[0]} 위반={sum(vs[0].values())} 금지어={bans[0]} 적재줄={r.get('loaded_lines')} 적재자={r.get('loaded_chars')}"]
    a, b = sum(vs[0].values()), sum(vs[1].values())
    verdict = "개선" if b < a else ("악화" if b > a else "동률")
    out = [f"A={a} B={b} 판정={verdict}"]
    for field in ("kind", "type", "failure", "clause"):
        groups = {}
        for n, c in cases.items():
            vals = c["meta"].get(field)
            vals = vals if isinstance(vals, list) else [vals] if vals else []
            if field == "failure" and any(v.startswith("conflict:") for v in vals):
                vals = vals + ["conflict"]
            for v in vals:
                groups.setdefault(v, []).append(n)
        for v in sorted(groups):
            ca = sum(vs[0].get(n, 0) for n in groups[v])
            cb = sum(vs[1].get(n, 0) for n in groups[v])
            out.append(f"{field} {v} A={ca} B={cb}")
    out.append(f"금지어 A={bans[0]} B={bans[1]}")
    return out


def main(argv):
    cmd, root = argv[1], argv[2]
    if cmd == "compare":
        # compare <과제 폴더> <결과 폴더> <pairs> <excl> <라벨>...
        for line in compare(root, argv[3], argv[6:], argv[4], argv[5]):
            print(line)
        return
    if cmd == "secrets":
        out = check_secrets(root)
    else:
        cases = load_cases(root)
        if cmd == "fields":
            out = check_fields(cases)
        elif cmd == "pairs":
            out = check_pairs(cases)
        elif cmd == "list":
            tag = argv[3] if len(argv) > 3 else ""
            out = [n for n, c in cases.items() if not tag or tag in (c["meta"].get("tags") or [])]
        else:
            raise SystemExit(f"모르는 명령 {cmd}")
    for line in out:
        print(line)


if __name__ == "__main__":
    main(sys.argv)
