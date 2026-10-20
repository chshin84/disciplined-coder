"""문서 형식 정규식 검사기. 라벨 불릿·개수 예고·제목 개수를 줄 단위로 잡는다.

CLI: python _doc_form_check.py --hook [FILE...]
  stdin 의 훅 입력 JSON 에서 Write 는 content, Edit 는 new_string 을 검사하고, 그 밖의 도구는 FILE 을 읽는다.
  위반마다 `이름표:줄: 종류: 발췌` 한 줄을 내고, 다섯 줄을 넘으면 `외 N건` 을 붙인다. 종료 코드는 늘 0 이다.
"""
import json
import re
import sys

LABEL = re.compile(r"^\s*[-*+]\s+\*\*[^*]+\*\*(.*)$")
SENT_END = re.compile(r"(?:다|요|까)\.")
COUNT_WORD = re.compile(
    r"(?:(?:^|\s)(?:두|세|네|다섯|여섯|일곱|여덟|아홉|열|[0-9]+)\s*(?:가지|개|건|항목)(?:다|이다|입니다)?(?![가-힣]))"
    r"|(?:(?:^|\s)(?:둘|셋|넷|다섯)(?:이다|입니다))"
)
LIST_ITEM = re.compile(r"^\s*(?:[-*+]|[0-9]+\.)\s")
HEADING = re.compile(r"^#{1,6}\s")
HEAD_COUNT = re.compile(
    r"(?:(?:^|\s)(?:둘|셋|넷|다섯|여섯)\s*$)|(?:(?:두|세|네|다섯|여섯)\s*(?:가지|개|건)(?![가-힣]))"
)
FENCE = re.compile(r"^\s{0,3}(?:```|~~~)")
BACKTICK = re.compile(r"`[^`]*`")
CAP = 5


def check(text):
    lines = text.splitlines()
    found = []
    in_fence = False
    for i, raw in enumerate(lines):
        if FENCE.match(raw):
            in_fence = not in_fence
            continue
        if in_fence or raw.lstrip().startswith(">"):
            continue
        line = BACKTICK.sub("", raw)
        excerpt = raw.strip()[:40]
        m = LABEL.match(line)
        if m and len(SENT_END.findall(m.group(1))) >= 2:
            found.append((i + 1, "라벨 불릿", excerpt))
        if HEADING.match(line):
            if HEAD_COUNT.search(line):
                found.append((i + 1, "제목 개수", excerpt))
        if not LIST_ITEM.match(line) and not line.lstrip().startswith("|") and COUNT_WORD.search(line):
            nxt = next((l for l in lines[i + 1:] if l.strip()), None)
            if nxt is not None and LIST_ITEM.match(nxt):
                found.append((i + 1, "개수 예고", excerpt))
    return found


def read_file(path):
    try:
        with open(path, "rb") as f:
            data = f.read()
    except OSError:
        return None
    for enc in ("utf-8-sig", "cp949"):
        try:
            return data.decode(enc)
        except UnicodeDecodeError:
            continue
    return None


def report(label, text):
    found = check(text)
    out = ["%s:%d: %s: %s" % (label, n, kind, ex) for n, kind, ex in found[:CAP]]
    if len(found) > CAP:
        out.append("외 %d건" % (len(found) - CAP))
    return out


def main(argv):
    if "--hook" not in argv:
        return
    files = [a for a in argv if a != "--hook"]
    try:
        data = json.loads(sys.stdin.buffer.read().decode("utf-8-sig"))
    except (ValueError, UnicodeDecodeError):
        return
    tool = data.get("tool_name")
    ti = data.get("tool_input") or {}
    lines = []
    if tool in ("Write", "Edit"):
        text = ti.get("content" if tool == "Write" else "new_string")
        if isinstance(text, str):
            lines = report(ti.get("file_path", "?"), text)
    else:
        for f in files:
            text = read_file(f)
            if text is not None:
                lines += report(f, text)
    if lines:
        sys.stdout.buffer.write(("\n".join(lines) + "\n").encode("utf-8"))


if __name__ == "__main__":
    main(sys.argv[1:])
