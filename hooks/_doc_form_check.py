"""문서 형식 정규식 검사기. 라벨 불릿·개수 예고·제목 개수를 줄 단위로, 단락 길이(ONE-IDEA)를 단락 단위로 잡는다.

CLI: python _doc_form_check.py --hook [FILE...]
  stdin 의 훅 입력 JSON 에서 Write 는 content, Edit 는 new_string 을 검사하고, 그 밖의 도구는 FILE 을 읽는다.
  이름표는 Write 가 파일 경로, Edit 가 `경로(편집 문자열)`, FILE 인자가 `경로(파일 전체)` 이다.
  위반마다 `이름표:줄: 종류: 발췌` 한 줄을 내고, 다섯 줄을 넘으면 `외 N건` 을 붙인다. 종료 코드는 늘 0 이다.
"""
import json
import re
import sys

LABEL = re.compile(r"^\s*(?:[-*+]|[0-9]+\.)\s+\*\*[^*]+\*\*(.*)$")
# 문장 끝: '다·요·까' 뒤 마침표, 그리고 의문형 '가' 와 닫는 괄호 뒤의 마침표·물음표다.
# 뒤의 두 형태는 공백이나 줄 끝이 이어질 때만 센다. '(e.g. 경로)를' 같은 문장 안 괄호를 세지 않기 위해서다.
SENT_END = re.compile(r"(?:다|요|까)\.|(?:가|\))[.?](?=\s|$)")
COUNT_WORD = re.compile(
    r"(?:(?:^|\s)(?:두|세|네|다섯|여섯|일곱|여덟|아홉|열|[0-9]+)\s*(?:가지|개|건|항목)(?:다|이다|입니다|를|을|의|가|이|는)?(?![가-힣]))"
    r"|(?:(?:^|\s)(?:둘|셋|넷|다섯)(?:이다|입니다))"
)
LIST_ITEM = re.compile(r"^\s*(?:[-*+]|[0-9]+\.)\s")
HEADING = re.compile(r"^#{1,6}\s")
HEAD_COUNT = re.compile(
    r"(?:(?:^|\s)(?:둘|셋|넷|다섯|여섯)\s*$)|(?:(?:두|세|네|다섯|여섯)\s*(?:가지|개|건)(?![가-힣]))"
)
FENCE = re.compile(r"^\s{0,3}(?:```|~~~)")
BACKTICK = re.compile(r"`[^`]*`")
# 백틱 구간은 빈 문자열 대신 이 문자로 바꾼다. 지우면 `**`ID`**` 가 `****` 가 되어 라벨을 놓친다.
CODE_MARK = "□"
CAP = 5
# ONE-IDEA: 단락이 네 문장에 이르면 새 단락을 시작한다. 그래서 다섯 문장 이상인 단락을 잡는다.
# 인용부호와 괄호 안의 문장은 남의 말이나 부연이라 세지 않는다. 세면 인용한 발화가 단락 길이를 부풀린다.
PARA_MAX = 4
QUOTED = re.compile(r"\"[^\"]*\"|“[^”]*”|'[^']*'|‘[^’]*’|「[^」]*」|\([^()]*\)")
TABLE = re.compile(r"^\s*\|")


def _own_sentences(text):
    """인용과 괄호를 뺀 뒤의 문장 끝 수."""
    for _ in range(3):
        text = QUOTED.sub("", text)
    return len(SENT_END.findall(text))


def check_paragraphs(lines):
    """단락(빈 줄로 끊긴 산문 줄 묶음)마다 문장 수를 세어 ONE-IDEA 를 본다. 목록·표·제목·인용·펜스는 단락이 아니다."""
    found = []
    in_fence = False
    para, para_start = [], 0

    def flush():
        if para and _own_sentences(" ".join(para)) > PARA_MAX:
            found.append((para_start, "ONE-IDEA 단락 길이", para[0][:40]))
        para.clear()

    for i, raw in enumerate(lines):
        if FENCE.match(raw):
            flush()
            in_fence = not in_fence
            continue
        if in_fence:
            continue
        line = BACKTICK.sub(CODE_MARK, raw)
        if (not line.strip() or HEADING.match(line) or TABLE.match(line) or LIST_ITEM.match(line)
                or line.lstrip().startswith(">")):
            flush()
            continue
        if not para:
            para_start = i + 1
        para.append(line.strip())
    flush()
    return found


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
        line = BACKTICK.sub(CODE_MARK, raw)
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
    found += check_paragraphs(lines)
    found.sort(key=lambda t: t[0])
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
            label = ti.get("file_path", "?")
            if tool == "Edit":
                label += "(편집 문자열)"
            lines = report(label, text)
    else:
        for f in files:
            text = read_file(f)
            if text is not None:
                lines += report(f + "(파일 전체)", text)
    if lines:
        sys.stdout.buffer.write(("\n".join(lines) + "\n").encode("utf-8"))


if __name__ == "__main__":
    main(sys.argv[1:])
