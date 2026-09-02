#!/usr/bin/env bash
# 공유 헬퍼: JSON을 읽는 파이썬 프로그램을 돌린다. 소비자는 이 파일을 source하는 모든 스크립트다.
# 처리기는 파이썬 하나다. 인터프리터 이름만 python3·python 순으로 고른다 — 이 PC의 python3는
# Windows Store 스텁이라 실행되지 않을 수 있다. 처리기를 둘 이상 두면 한 번도 안 도는 사본이 생기고
# 안 돌아 본 코드에는 오류가 숨는다(domain-plugin 「처리기 하나」). 둘 다 없으면 조용히 통과시키지
# 않고 실패로 계상한다(FAIL-LOUD — 검증 불능은 통과가 아니다).
_json_python() {  # stdout: 쓸 수 있는 인터프리터 이름. 없으면 1.
  if python3 -c 'import sys' >/dev/null 2>&1; then printf 'python3'
  elif python -c 'import sys' >/dev/null 2>&1; then printf 'python'
  else return 1
  fi
}
json_run() {  # $1=파이썬 프로그램 문자열, 나머지=그 프로그램의 인자. stdin은 그대로 넘긴다.
  local py prog="$1"; shift
  py="$(_json_python)" || { echo "  (json_run: python3/python 모두 없음 — 검증 불능은 FAIL로 계상)" >&2; return 1; }
  "$py" -c "$prog" "$@"
}
# stdin이 유효한 JSON인지 검사한다.
json_valid_stdin() { json_run 'import json,sys; json.load(sys.stdin)'; }
# 훅 배선 파일($1)에서 이벤트 이름을 정렬해 한 줄씩 출력한다. 배선 파일이 이벤트를 하나 이상
# 가지는지 확인할 때 쓴다.
json_hook_events() {
  json_run 'import json,sys; [print(k) for k in sorted(json.load(open(sys.argv[1],encoding="utf-8")).get("hooks",{}))]' "$1"
}
