#!/usr/bin/env bash
# 공유: 계약 테스트의 단언 함수와 계수기. 소비자는 scripts/test_*.sh 다. 다섯 파일이 같은 정의를
# 베껴 두면 한쪽만 고쳐져 갈라진다(_audit_common.sh 와 같은 이유).
pass=0; fail=0
# 조건을 평가하는 동안만 pipefail 을 끈다. `printf 큰출력 | grep -q` 에서 grep 이 먼저 끝나면 printf 가
# Broken pipe 로 실패하고, pipefail 이면 찾았는데도 FAIL 이 된다(리눅스 CI 에서 실행마다 다른 검사가 실패했다).
# local - 가 함수를 나갈 때 셸 옵션을 되돌린다.
check() { local -; set +o pipefail; if eval "$2"; then echo "  PASS: $1"; pass=$((pass+1)); else echo "  FAIL: $1"; fail=$((fail+1)); fi; }
