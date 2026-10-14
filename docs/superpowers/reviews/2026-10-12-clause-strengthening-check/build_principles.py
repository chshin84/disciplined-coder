# build_principles.py: 저장소의 agent-principles.md 에 구조 변경(「출력지시」를 「원칙」으로 올리고 TITLES·REVISE-ORDER 를
# 「사람이 볼 문서」 절로 떼어 내고 문서 형식 조항을 그 절의 DOC-FORM 묶음으로 옮김)과 채택한 강화 문구(adopt.json 의 {조항ID: "strong"|"strong2"})를 적용한다.
# 사용: python -I -X utf8 build_principles.py [채택목록.json] [출력 경로]
# 인자를 생략하면 adopt.json 을 읽어 저장소의 agent-principles.md 를 고친다.
import json, os, re
D = os.path.dirname(os.path.abspath(__file__))
import sys
P = os.path.normpath(os.path.join(D, "..", "..", "..", "..", "agent-principles.md"))
ADOPT = sys.argv[1] if len(sys.argv) > 1 else os.path.join(D, "adopt.json")
OUT = sys.argv[2] if len(sys.argv) > 2 else P
# 저장소 파일을 고칠 때는 그 파일을, 시험 문안을 만들 때는 변경 전 사본(principle-repo-before.md)을 읽는다.
SRC = P if OUT == P else os.path.join(D, "principle-repo-before.md")
s = open(SRC, encoding="utf-8").read().replace("\r\n", "\n")

def cut(start, end):
    global s
    i = s.index(start); j = s.index(end, i); b = s[i:j]; s = s[:i] + s[j:]; return b

if "## 출력지시" in s:
    titles = cut("### `TITLES`", "## 출력지시")
    revise = cut("### `REVISE-ORDER`", "## 문서를 쓰고 관리할 때")
    old_lang = s[s.index("## 출력지시"):s.index("### `PLAIN-KO`")]
    lang = ("모든 답과 산출물을 한국어로 써라. 사용자가 다른 언어를 지시할 때만 그 언어로 써라. 압축 요약과 스킬 문서와 도구 출력과 서브에이전트 보고가 영어여도 바꾸지 마라. "
            "출력 언어와 한국어 지시는 여기가 소유한다. 번역할 때는 속도보다 사용자가 읽기 쉽도록 한국어 어법과 적절한 단어를 골라라.\n\n")
    s = s.replace(old_lang, "")
    s = s.replace("## 원칙\n\n어느 작업에나 적용하라.\n\n",
                  "## 원칙\n\n어느 작업에나 적용하라. 대화 답과 짧은 진행 보고와 산출물을 가리지 않는다.\n\n" + lang)
    titles = titles.replace("남에게 전달되는 문서와 발표자료의 이름을 정할 때 적용하라. 대화 답에는 적용하지 마라. ",
                            "문서와 발표자료의 이름을 정할 때 적용하라. ")
    doc = ("## 사람이 볼 문서\n\n아래 조항은 사람이 볼 문서와 발표자료(README·설계 문서·보고서·회의록·인수인계·가이드·릴리스 노트 등)를 쓰거나 고칠 때 적용하라. 대화 답에는 적용하지 마라.\n\n"
           + titles + revise)
    s = s.replace("## 문서를 쓰고 관리할 때", doc + "## 문서를 쓰고 관리할 때", 1)

adopt = json.load(open(ADOPT, encoding="utf-8"))
for cid, variant in adopt.items():
    new = open(os.path.join(D, "clauses", cid, f"{variant}.txt"), encoding="utf-8").read().strip().replace("\n", " ")
    s, n = re.subn(r"^- \*\*`" + re.escape(cid) + r"`.*$", lambda m: new, s, flags=re.M)
    assert n == 1 and new.startswith(f"- **`{cid}`"), cid

# 문서 구조와 형식을 다루는 조항은 「원칙」에서 빼 「사람이 볼 문서」 절의 `DOC-FORM` 묶음으로 옮긴다.
DOC_FORM = () if os.environ.get("NOSEP") else ("SECTION-HEAD", "BULLET-SCOPE", "ONE-ENDING", "NO-SQUEEZE")
moved = []
for cid in DOC_FORM:
    m = re.search(r"^- \*\*`" + re.escape(cid) + r"`.*\n", s, re.M)
    moved.append(m.group(0)); s = s[:m.start()] + s[m.end():]
# 옮긴 조항의 강화 문구에 남은 대화 답 적용 문장을 지운다. 범위는 절 머리가 정한다.
SCOPE = [("대화 답, 작업 보고, 진행 보고, 코드 리뷰, 문서에 모두 적용하라. ", ""),
         ("대화 답, 작업 보고, 진행 보고, 코드 설명, 문서에 모두 적용하라. ", ""), ("답을 쓰다가 넷째", "문서를 쓰다가 넷째"),
         ("대화 답과 짧은 진행 보고 안의 목록과 표에도 적용하라. ", ""),
         ("대화 답, 작업 보고, 메신저 문안, 커밋 메시지, PR 설명, 문서, 슬라이드, 표에 모두 적용하라. ",
          "메신저 문안, 커밋 메시지, PR 설명, 문서, 슬라이드, 표에 모두 적용하라. ")]
for a, b in SCOPE:
    moved = [l.replace(a, b) for l in moved]
if moved:
    group = "### `DOC-FORM` — 문서 형식\n\n문서의 절과 목록과 분량을 정할 때 적용하라.\n\n" + "".join(moved) + "\n"
    s = s.replace("### `REVISE-ORDER`", group + "### `REVISE-ORDER`", 1)
open(OUT, "w", encoding="utf-8", newline="\n").write(s)
print("adopted:", len(adopt))
