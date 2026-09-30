#!/usr/bin/env bash
# 공유: 계약 테스트의 단언 함수와 계수기. 소비자는 scripts/test_*.sh 다. 다섯 파일이 같은 정의를
# 베껴 두면 한쪽만 고쳐져 갈라진다(_audit_common.sh 와 같은 이유).
pass=0; fail=0
check() { if eval "$2"; then echo "  PASS: $1"; pass=$((pass+1)); else echo "  FAIL: $1"; fail=$((fail+1)); fi; }
