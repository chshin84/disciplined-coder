#!/usr/bin/env bash
# 공유 헬퍼: stdin이 유효한 JSON인지 검사한다. 소비자는 이 파일을 source하는 모든 스크립트다.
# 이 PC의 python3는 Windows Store 스텁이라 실행되지 않을 수 있으므로 python·node로 폴백한다.
# 셋 다 없으면 조용히 통과시키지 않고 실패로 계상한다(FAIL-LOUD — 검증 불능은 통과가 아니다).
json_valid_stdin() {
  if python3 -c 'import sys' >/dev/null 2>&1; then
    python3 -c 'import json,sys; json.load(sys.stdin)'
  elif python -c 'import sys' >/dev/null 2>&1; then
    python -c 'import json,sys; json.load(sys.stdin)'
  elif command -v node >/dev/null 2>&1; then
    node -e 'let d="";process.stdin.on("data",c=>d+=c).on("end",()=>{JSON.parse(d)})'
  else
    echo "  (json_valid_stdin: python3/python/node 모두 없음 — 검증 불능은 FAIL로 계상)" >&2
    return 1
  fi
}

# 훅 배선 파일에서 이벤트 이름을 정렬해 한 줄씩 출력한다($1=파일). 두 런타임의 배선을 대조할 때 쓴다.
json_hook_events() {
  if python3 -c 'import sys' >/dev/null 2>&1; then
    python3 -c 'import json,sys; [print(k) for k in sorted(json.load(open(sys.argv[1],encoding="utf-8")).get("hooks",{}))]' "$1"
  elif python -c 'import sys' >/dev/null 2>&1; then
    python -c 'import json,sys; [print(k) for k in sorted(json.load(open(sys.argv[1]))["hooks"])]' "$1"
  elif command -v node >/dev/null 2>&1; then
    node -e 'const o=JSON.parse(require("fs").readFileSync(process.argv[1],"utf8"));Object.keys(o.hooks||{}).sort().forEach(k=>console.log(k))' "$1"
  else
    echo "  (json_hook_events: python3/python/node 모두 없음 — 검증 불능은 FAIL로 계상)" >&2
    return 1
  fi
}
