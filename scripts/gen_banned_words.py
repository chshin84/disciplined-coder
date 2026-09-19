#!/usr/bin/env python3
"""금지 표현 목록을 데이터에서 만들어 korean-banned-words-dc.md 로 낸다.

원본은 KiwoomAX/korean-banned-words 의 korean-banned-words.json 하나다. 이 저장소는 그
데이터를 복제하지 않고, 필요할 때 받아 와 생성물만 커밋한다. 손으로 고치면 다음 생성에서
사라지고, GitHub Actions 가 다시 만들어 diff 로 대조해 갈라진 것을 잡는다.

내는 모양은 지금 정본에 있던 표와 같다. hooks/_banned_words.sh 가 `### 금지 표현` 제목
아래에서 `| ` 로 시작해 백틱이 붙은 행만 읽고 첫 칸과 둘째 칸만 쓰므로, 같은 모양으로
내면 훅 파싱을 한 줄도 안 고쳐도 된다.

제목 아래에 `#` 로 시작하는 줄을 두면 안 된다. 그 파서가 거기서 멈춘다.

    python scripts/gen_banned_words.py                 # 원본을 받아 온다
    python scripts/gen_banned_words.py path/to.json    # 받아 둔 파일을 쓴다
    python scripts/gen_banned_words.py --check         # 안 쓰고 지금 파일과 다른지만 본다
"""
import json
import sys
import urllib.request
from pathlib import Path

RAW = ("https://raw.githubusercontent.com/KiwoomAX/korean-banned-words/main/"
       "korean-banned-words.json")
SOURCE_REPO = "https://github.com/KiwoomAX/korean-banned-words"
OUT = Path(__file__).resolve().parent.parent / "korean-banned-words-dc.md"


def load(arg):
    if arg and arg != "--check":
        return json.loads(Path(arg).read_text(encoding="utf-8"))
    with urllib.request.urlopen(RAW, timeout=30) as r:
        return json.loads(r.read().decode("utf-8"))


def where(scope):
    """거는 곳 칸. 저장소의 살아 있는 문서까지 걸리면 그 범위가 더 넓다."""
    return "문서와 답변" if "living-doc" in scope else "답변과 산출물"


def render(data):
    lines = [
        "<!-- 이 파일은 생성물이다. 손으로 고치지 마라. -->",
        f"<!-- 원본: {SOURCE_REPO} -->",
        "<!-- 다시 만들기: python scripts/gen_banned_words.py -->",
        f"<!-- 원본 판: schema {data['schema']}, {data['updated']} -->",
        "",
        "### 금지 표현",
        "",
        "쓰지 않는 말이다. 사람의 판단에 맡기지 말고 문자열 검색으로 거른 뒤 내보낸다. "
        f"목록의 원본과 각 항목의 근거는 {SOURCE_REPO} 가 소유한다.",
        "",
        "첫째 칸의 백틱 안이 검색할 글자 그대로다. 셋째 칸이 거는 곳을 정한다. "
        "`답변과 산출물`은 사용자에게 보내는 답과 사용자가 요구한 산출물 문서에 걸리고, "
        "`문서와 답변`은 거기에 이 저장소의 살아 있는 문서까지 더한 것이다.",
        "",
        "| 쓰지 않는 말 | 대신 쓰는 말 | 거는 곳 |",
        "|---|---|---|",
    ]

    for e in data["entries"]:
        if not e.get("enabled", True):
            continue
        banned = " · ".join(f"`{w}`" for w in e["banned"])
        repl = " · ".join(e.get("replace") or []) or e.get("instruction", "")
        lines.append(f"| {banned} | {repl} | {where(e['scope'])} |")

    rules = [r for r in data.get("rules", []) if r.get("enabled", True)]
    if rules:
        lines += ["", "단어 쌍으로 적을 수 없는 것이 아래에 있다. 문자열 검색으로는 안 걸리므로 이 지시가 맡는다.", ""]
        for r in rules:
            lines.append(f"- {r['text']}")

    off = [e["banned"][0] for e in data["entries"] if not e.get("enabled", True)]
    if off:
        lines += ["", "꺼 둔 항목은 " + " · ".join(f"`{w}`" for w in off)
                  + " 이고, 왜 껐는지는 원본이 담는다. 이 목록에서 뺀 것이 아니라 끈 것이다."]

    return "\n".join(lines) + "\n"


def main():
    arg = sys.argv[1] if len(sys.argv) > 1 else None
    text = render(load(arg))

    if "--check" in sys.argv:
        now = OUT.read_text(encoding="utf-8") if OUT.exists() else ""
        if now == text:
            print(f"같다: {OUT.name}")
            return 0
        print(f"다르다: {OUT.name} — python scripts/gen_banned_words.py 로 다시 만들어라")
        return 1

    OUT.write_text(text, encoding="utf-8", newline="\n")
    print(f"만들었다: {OUT.name} ({len(text)}자)")
    return 0


if __name__ == "__main__":
    sys.exit(main())
