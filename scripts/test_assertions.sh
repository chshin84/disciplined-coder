#!/usr/bin/env bash
# 검사 스크립트가 실제로 단언하는지 본다.
# 제목을 찍고 check 를 한 번도 안 부르는 블록은 픽스처를 세우고 스크립트를 돌린 뒤 아무것도 확인하지
# 않으면서, 초록 화면에는 그 이름이 남는다. 삭제된 기능의 검사를 걷을 때 이 껍데기가 남았다.
#
# 이 검사가 잡는 것은 check 가 하나도 없는 블록뿐이다. 항진 단언(재려는 대상이 코드에 없어 무엇을
# 고쳐도 참인 단언)은 못 잡는다 — 그것은 사람이 본다. 그러니 이 검사를 초록으로 만들려고 형식적인
# 단언을 붙이지 마라. 그것은 이 검사가 걷어내려는 것과 같은 물건이다.
set -euo pipefail
HERE="$(cd "$(dirname "$0")/.." && pwd)"
pass=0; fail=0
check() { if eval "$2"; then echo "  PASS: $1"; pass=$((pass+1)); else echo "  FAIL: $1"; fail=$((fail+1)); fi; }

echo "[검사 블록마다 단언이 있다]"
SN=0
for T in "$HERE"/scripts/test_*.sh; do
  [ -f "$T" ] || continue
  B="$(basename "$T")"
  [ "$B" = "test_assertions.sh" ] && continue
  SN=$((SN+1))
  EMPTY="$(awk '
    /^[[:space:]]*echo "\[/ { if (hdr != "" && n == 0) print hdr; hdr = $0; n = 0; next }
    /(^|[^_[:alnum:]])check[[:space:]]/ { n++ }
    END { if (hdr != "" && n == 0) print hdr }
  ' "$T" || true)"
  if [ -n "$EMPTY" ]; then
    echo "    단언 없는 블록:"
    printf '%s\n' "$EMPTY" | sed 's/^/      /'
  fi
  check "$B: 단언 없는 블록이 없다" "[ -z \"\$EMPTY\" ]"
done
# 글롭이 안 맞으면 위 루프가 한 번도 안 돌아 조용히 초록이 된다. 이 스크립트가 잡으려는 결함과
# 같은 형태이므로 개수를 따로 단언한다.
check "검사 스크립트를 둘 이상 훑었다" "[ '$SN' -ge 2 ]"

# 위 블록은 `echo "["` 머리만 본다. 그래서 검사를 걷어낼 때 `# ---` 구획 주석과 그 밑의 근거 설명만
# 남으면 아무 눈에도 안 띈다 — 읽는 사람은 그 가드가 있다고 믿지만 코드는 없다. 실제로 그렇게 남은
# 구획이 있었다. 여기서는 머리도 검사도 없이 설명만 남은 구획을 찾는다.
echo "[구획 주석에 검사가 딸려 있다]"
SN2=0
for T in "$HERE"/scripts/test_*.sh; do
  [ -f "$T" ] || continue
  B="$(basename "$T")"
  [ "$B" = "test_assertions.sh" ] && continue
  SN2=$((SN2+1))
  ORPHAN="$(awk '
    /^[[:space:]]*# ---/ { if (hdr != "" && n == 0 && h == 0) print hdr; hdr = $0; n = 0; h = 0; next }
    /^[[:space:]]*echo "\[/ { h++ }
    /(^|[^_[:alnum:]])check[[:space:]]/ { n++ }
    END { if (hdr != "" && n == 0 && h == 0) print hdr }
  ' "$T" || true)"
  if [ -n "$ORPHAN" ]; then
    echo "    설명만 남은 구획:"
    printf '%s\n' "$ORPHAN" | sed 's/^/      /'
  fi
  check "$B: 설명만 남은 구획이 없다" "[ -z \"\$ORPHAN\" ]"
done
check "구획 검사도 스크립트를 둘 이상 훑었다" "[ '$SN2' -ge 2 ]"

echo "----"; echo "PASS=$pass FAIL=$fail"; [ "$fail" -eq 0 ]
