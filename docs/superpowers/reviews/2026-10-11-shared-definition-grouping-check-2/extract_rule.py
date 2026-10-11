# extract_rule.py: SKILL.md 「묶는 단위」에서 판정 문단만 뽑는다. 근거·측정 서술 문단은 측정 서브에이전트에 넘기지 않는다.
import sys
src, out = sys.argv[1], sys.argv[2]
STOPS = ("순환만 합치는 방식은", "현재 세션이 합치는 강한 결합은")
lines = open(src, encoding="utf-8").read().split("\n")
start = next(i for i, l in enumerate(lines) if l.startswith("**묶는 단위.**"))
buf = []
for l in lines[start:]:
    if l.startswith(STOPS) or l.startswith("**큰 명세.**"):
        break
    buf.append(l)
open(out, "w", encoding="utf-8").write("\n".join(buf).strip() + "\n")
print(len(buf))
