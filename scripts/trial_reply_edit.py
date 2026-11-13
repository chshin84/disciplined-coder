#!/usr/bin/env python3
"""콘솔 답변 교정 시험. Haiku 를 호출해 cases.json 의 사례를 교정하고 판정과 원본을 파일에 남긴다.

사용: python scripts/trial_reply_edit.py <결과 파일> [사례 id ...]
판정 기준은 docs/superpowers/specs/2026-11-02-reply-edit-rules-design.md 「시험」이 소유한다.
코드 판정을 통과해도 뜻이 바뀔 수 있으므로 결과 문장은 사람이 읽어 판정한다.
"""
import concurrent.futures as cf
import json
import os
import re
import shutil
import subprocess
import sys
import tempfile

ROOT = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
MODEL = "claude-haiku-5-5"
TOKEN = re.compile(r"[A-Za-z0-9](?:[\w.,:/\\%$+~-]*[\w%$/\\])?", re.ASCII)
CODE = re.compile(r"```[\s\S]*?(?:```|\Z)|`[^`\n]*`|^(?: {4}|\t).*$|^\$ .*(?:\n.+)*", re.M)
MARKER = re.compile(r"⟦\d+⟧")
COUNT_UNIT = "건개가지번"
NO_MOVE_START = re.compile(r"^(그래서|그러나|이어서|따라서|다만|이|그|아래)\s")


def read(name):
    with open(os.path.join(ROOT, name), encoding="utf-8") as f:
        return f.read()


def parse_banned(text):
    body = text[text.index("## 금지 표현"):text.index("## 표로 적을 수 없는 규칙")]
    rows = []
    for line in body.splitlines():
        cells = [c.strip() for c in line.strip().strip("|").split("|")] if line.startswith("|") else []
        if len(cells) < 2 or "`" not in cells[0]:
            continue
        rows.append({
            "words": re.findall(r"`([^`]+)`", cells[0]),
            "use": [u.strip() for u in cells[1].split("·")],
            "except": re.findall(r"`([^`]+)`", cells[2]) if len(cells) > 2 else [],
        })
    return rows


def build_rules():
    manifest = json.loads(read("reply-edit/manifest.json"))
    principles = read("agent-principles.md")
    rules = []
    for rule in manifest["rules"]:
        if "match" in rule:
            hit = [l for l in read(rule["source"]).splitlines() if rule["match"] in l]
            if len(hit) != 1:
                raise SystemExit(f"불릿을 찾지 못함: {rule['id']}")
            text = hit[0].lstrip("- ")
        else:
            m = re.search(r"^- \*\*`%s`\*\* — (.+)$" % re.escape(rule["id"]), principles, re.M)
            if not m:
                raise SystemExit(f"조항을 찾지 못함: {rule['id']}")
            text = m.group(1)
        rules.append({"id": rule["id"], "kind": rule["kind"], "text": text})
    return {"schema": 1, "instructions": manifest["instructions"], "rules": rules,
            "banned": parse_banned(read("korean-banned-words.md"))}


def assemble(data):
    parts = [data["instructions"], "", "[edit rules]"]
    parts += [f"- {r['id']}: {r['text']}" for r in data["rules"] if r["kind"] == "edit"]
    parts += ["", "[reorder rules]"]
    parts += [f"- {r['id']}: {r['text']}" for r in data["rules"] if r["kind"] == "reorder"]
    parts += ["", "[banned words: word list -> replacements (not banned inside: exceptions)]"]
    for b in data["banned"]:
        tail = f" (not banned inside: {', '.join(b['except'])})" if b["except"] else ""
        parts.append(f"- {', '.join(b['words'])} -> {', '.join(b['use'])}{tail}")
    return "\n".join(parts)


def call(system, prompt):
    cli = shutil.which("claude") or shutil.which("claude.cmd")
    with tempfile.NamedTemporaryFile("w", encoding="utf-8", suffix=".txt", delete=False) as f:
        f.write(system)
        path = f.name
    try:
        r = subprocess.run(
            [cli, "-p", "--model", MODEL, "--system-prompt-file", path, "--tools", "",
             "--setting-sources", "", "--no-session-persistence", "--output-format", "json"],
            input=prompt, capture_output=True, text=True, encoding="utf-8", cwd=tempfile.gettempdir(), timeout=300)
    finally:
        os.unlink(path)
    if r.returncode != 0:
        return {"error": (r.stderr or r.stdout)[:400]}
    try:
        o = json.loads(r.stdout)
    except ValueError:
        return {"error": r.stdout[:400]}
    return {"text": o.get("result", ""), "cost": o.get("total_cost_usd"), "stop": o.get("stop_reason")}


def parse_reply(reply):
    try:
        return json.loads(reply[reply.index("{"):reply.rindex("}") + 1])
    except ValueError:
        return None


def edit_reason(cur, f, t):
    """수정 항목을 버릴 이유를 돌려준다. 통과하면 None."""
    if not isinstance(f, str) or not isinstance(t, str) or not f:
        return "형식 오류"
    if cur.count(f) != 1:
        return "한 번 나오지 않음"
    if f == t or not t.strip():
        return "동일하거나 빈 문자열"
    if re.search(r"[.!?]\s+\S", f.strip()) or "\n" in f:
        return "한 문장 초과"
    if sorted(MARKER.findall(f)) != sorted(MARKER.findall(t)):
        return "코드 마커 변경"
    a, b = TOKEN.findall(MARKER.sub(" ", f)), TOKEN.findall(MARKER.sub(" ", t))
    rest = list(a)
    for tok in b:
        if tok not in rest:
            return f"값 변경 {tok}"
        rest.remove(tok)
    for tok in rest:
        if not tok.isdigit():
            return f"식별자 삭제 {tok}"
        if not re.search(re.escape(tok) + r"\s*[" + COUNT_UNIT + "]", f):
            return f"개수 아닌 숫자 삭제 {tok}"
    if "\n" in t:
        return "줄바꿈 추가"
    return None


def whole_sentence(cur, s):
    if not s or cur.count(s) != 1 or not re.search(r"[.!?]$", s.strip()):
        return False
    i = cur.index(s)
    if i and not cur[i - 1].isspace():
        return False
    line = cur[cur.rfind("\n", 0, i) + 1:]
    return not re.match(r"\s*(?:[-*#|]|\d+\.)", line)


def move(cur, text, before):
    rest = re.sub(r"[ \t]{2,}", " ", cur.replace(text, "", 1)).strip()
    rest = re.sub(r"\n{3,}", "\n\n", rest)
    if before:
        return rest.replace(before, text + " " + before, 1)
    if rest.startswith("#"):
        head, _, tail = rest.partition("\n")
        return head + "\n" + text + " " + tail.lstrip()
    return text + " " + rest


def apply_all(masked, data):
    cur, log = masked, []
    for m in data.get("moves") or []:
        t, b = m.get("text"), m.get("before")
        if not whole_sentence(cur, t) or (b and not whole_sentence(cur, b)):
            log.append(["버림", "문장 전체가 아니거나 금지 위치", t])
        elif NO_MOVE_START.match(t):
            log.append(["버림", "이어주는 말로 시작", t])
        else:
            cur = move(cur, t, b)
            log.append(["이동", "", t])
    for e in data.get("edits") or []:
        f, t = e.get("from"), e.get("to")
        reason = edit_reason(cur, f, t)
        if reason:
            log.append(["버림", reason, f"{f} → {t}"])
        else:
            cur = cur.replace(f, t, 1)
            log.append(["적용", "", f"{f} → {t}"])
    return cur, log


def first_sentence(text):
    plain = re.sub(r"^#.*\n", "", text.lstrip())
    return re.split(r"(?<=[.!?])\s", plain, maxsplit=1)[0]


def judge(case, out):
    fails = []
    fails += [f"미교정 {x}" for x in case.get("must_fix", []) if x in out]
    fails += [f"사라짐 {x}" for x in case.get("must_keep", []) if x not in out]
    if case.get("expected_any") and not any(x in out for x in case["expected_any"]):
        fails.append("대상 이름 없음")
    if case.get("expected_first") and case["expected_first"] not in first_sentence(out):
        fails.append("맨 앞 아님")
    for x in case.get("must_not_move", []):
        if out.find(x) != case["input"].find(x) and first_sentence(out).find(x) != -1:
            fails.append(f"이동됨 {x}")
    if case.get("unchanged") and out != case["input"]:
        fails.append("원문과 다름")
    return fails


def run_case(case, system):
    code = []

    def hide(m):
        code.append(m.group(0))
        return f"⟦{len(code) - 1}⟧"

    masked = CODE.sub(hide, case["input"])
    conversation = case["conversation"]
    prompt = f"Recent conversation:\n{conversation}\n\nLast assistant message:\n{masked}"
    r = call(system, prompt)
    if "error" in r:
        return {"id": case["id"], "target": case["target"], "error": r["error"]}
    data = parse_reply(r["text"])
    if data is None:
        return {"id": case["id"], "target": case["target"], "error": "JSON 없음", "raw": r["text"], "stop": r["stop"]}
    out, log = apply_all(masked, data)
    out = re.sub(r"⟦(\d+)⟧", lambda m: code[int(m.group(1))], out)
    return {"id": case["id"], "target": case["target"], "input": case["input"], "output": out, "log": log,
            "fails": judge(case, out), "cost": r["cost"], "stop": r["stop"], "raw": r["text"]}


def main():
    args = sys.argv[1:]
    variant = None
    if "--instructions" in args:
        i = args.index("--instructions")
        with open(args[i + 1], encoding="utf-8") as f:
            variant = f.read()
        del args[i:i + 2]
    result_path = args[0]
    only = set(args[1:])
    data = build_rules()
    if variant:
        data["instructions"] = variant
    system = assemble(data)
    cases =[c for c in json.loads(read("reply-edit/cases.json")) if not only or c["id"] in only]
    with cf.ThreadPoolExecutor(4) as ex:
        results = list(ex.map(lambda c: run_case(c, system), cases))
    with open(result_path, "w", encoding="utf-8") as f:
        json.dump({"model": MODEL, "system_chars": len(system), "results": results}, f, ensure_ascii=False, indent=1)
    sys.stdout.reconfigure(encoding="utf-8")
    print("지시문 길이(자):", len(system), "총비용:", round(sum(r.get("cost") or 0 for r in results), 4))
    passed = sum(1 for r in results if not r.get("error") and not r.get("fails"))
    print(f"코드 판정 통과 {passed}/{len(results)}")
    for r in results:
        print("-" * 60)
        print(r["id"], f"[{r['target']}]", "오류: " + r["error"] if r.get("error") else ("통과" if not r["fails"] else "실패 " + str(r["fails"])))
        for kind, why, what in r.get("log", []):
            print(f"  {kind}{'(' + why + ')' if why else ''}: {what}")
        if r.get("output") and r["output"] != r.get("input"):
            print("  결과:", r["output"])


if __name__ == "__main__":
    main()
