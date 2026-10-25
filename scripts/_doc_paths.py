"""살아 있는 문서의 상대 링크와 백틱 속 저장소 경로 중 실재하지 않는 것을 출력한다.

사용: python _doc_paths.py <저장소 뿌리>
출력: 첫 줄은 `CHECKED <후보 수>`, 그다음 줄마다 `<파일>:<줄>\t<참조>` 다. 깨진 참조가 없으면 첫 줄만 나온다.
소비자는 scripts/test_docs_drift.sh 「문서가 가리킨 경로가 실재한다」다.

경로는 문서가 있는 폴더, 그 문서가 속한 스킬 폴더, 저장소 뿌리 순서로 찾는다. 별표가 든 경로는 하나 이상과
일치해야 한다. 코드 블록 안, 자리표시(<>{}$)가 든 경로, 지웠다는 이력을 적은 줄은 보지 않는다.
"""
import glob
import os
import re
import sys

ROOT = sys.argv[1]
LIVE_GLOBS = ["README.md", "CLAUDE.md", "agent-principles.md", "korean-banned-words.md",
              "skills/**/*.md", "agents/*.md", "docs/domain-*.md"]
PREFIX = r"(?:skills|agents|scripts|hooks|workflows|docs|evals)/"
LINK = re.compile(r"\]\(([^)\s]+)\)")
TICK = re.compile(r"`([^`\n]+)`")
TICK_PATH = re.compile(r"^(?:\.\./|\./)*" + PREFIX + r"[A-Za-z0-9_.*/-]+$")
HISTORY = re.compile(r"지웠|삭제|git 이력|옛 ")


def exists(path, doc):
    bases = [os.path.dirname(doc), ROOT]
    rel = os.path.relpath(doc, ROOT).replace("\\", "/")
    if rel.startswith("skills/"):
        bases.insert(1, os.path.join(ROOT, *rel.split("/")[:2]))
    for b in bases:
        p = os.path.normpath(os.path.join(b, path))
        if glob.glob(p) if "*" in path else os.path.exists(p):
            return True
    return False


docs = sorted({p for g in LIVE_GLOBS for p in glob.glob(os.path.join(ROOT, g), recursive=True)})
checked, broken = 0, []
for doc in docs:
    fence = False
    for n, line in enumerate(open(doc, encoding="utf-8"), 1):
        if line.lstrip().startswith("```"):
            fence = not fence
            continue
        if fence or HISTORY.search(line):
            continue
        refs = [m.group(1).split("#")[0] for m in LINK.finditer(line)
                if not m.group(1).startswith(("http", "#", "mailto:"))]
        refs += [t for t in TICK.findall(line) if TICK_PATH.match(t)]
        for ref in refs:
            ref = ref.rstrip(".,:;")
            if not ref or re.search(r"[<>{}$]", ref):
                continue
            checked += 1
            if not exists(ref, doc):
                broken.append(f"{os.path.relpath(doc, ROOT)}:{n}\t{ref}")
print(f"CHECKED {checked}")
print("\n".join(broken))
