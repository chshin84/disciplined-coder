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
# PYTHONUTF8=1 을 여기서 한 번 세우는 이유. 이 PC 의 파이썬은 기본 인코딩이 cp949 다. 한국어를
# 표준 출력에 내면 cp949 바이트가 나가고, 그 출력을 파일에 두었다가 encoding="utf-8" 로 다시 열면
# UnicodeDecodeError 가 난다. 표준 입력으로 한국어를 파이프해도 같은 이유로 깨진다 — 2026-09-05 에
# 같은 뿌리에서 세 번 깨졌다. 저장소의 모든 파이썬 호출이 json_run 하나를 지나므로 여기서 한 번
# 세우면 호출자 전부가 물려받고, 스크립트마다 sys.stdout.reconfigure(encoding="utf-8") 를 기억할
# 필요가 사라진다. 이미 넣어 둔 reconfigure 줄은 해가 없어 그대로 둔다.
# 이 설정이 바꾸는 것은 파이썬 프로세스의 표준 입출력 기본 인코딩뿐이다. 파일 읽기는 이 저장소가
# 전부 encoding= 을 명시하고 있어 바뀌지 않는다. 파이썬이 아닌 곳(셸의 printf·grep)은 이 설정과
# 무관하다. 그리고 명령 치환으로 받은 출력을 같은 파이썬으로 되읽는 테스트는 쓰기와 읽기가 상쇄되어
# 인코딩 결함을 못 잡으므로, 인코딩을 검사하는 단언은 출력을 파일에 저장한 뒤 다시 열어야 한다.
json_run() {  # $1=파이썬 프로그램 문자열, 나머지=그 프로그램의 인자. stdin은 그대로 넘긴다.
  local py prog="$1"; shift
  py="$(_json_python)" || { echo "  (json_run: python3/python 모두 없음 — 검증 불능은 FAIL로 계상)" >&2; return 1; }
  PYTHONUTF8=1 "$py" -c "$prog" "$@"
}
# stdin이 유효한 JSON인지 검사한다.
json_valid_stdin() { json_run 'import json,sys; json.load(sys.stdin)'; }
# 훅 배선 파일($1)에서 이벤트 이름을 정렬해 한 줄씩 출력한다. 배선 파일이 이벤트를 하나 이상
# 가지는지 확인할 때 쓴다.
json_hook_events() {
  json_run 'import json,sys; [print(k) for k in sorted(json.load(open(sys.argv[1],encoding="utf-8")).get("hooks",{}))]' "$1"
}
