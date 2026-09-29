#!/usr/bin/env bash
# 공유 헬퍼: 레포 문서 감사 스크립트가 함께 쓰는 계산. 소비자는 audit_evidence.sh·audit_rounds.sh·
# audit_verify.sh·test_audit.sh 다. 같은 계산을 파일마다 베껴 두면 한쪽만 고쳐져 갈라진다.

# 절차 문서($1, audit-repo-docs SKILL.md)의 「판정」 절 한 문장에서 status 닫힌 집합을 뽑아 공백으로
# 이어 출력한다. 그 문장에는 칸 이름 `status` 자체도 백틱으로 들어 있어 값 집합에서 뺀다. 안 빼면
# status 가 "status" 인 발견이 통과한다.
audit_status_set() {
  grep -F '`status`가' "$1" | head -1 | grep -oE '`[a-z]+`' | tr -d '`' | grep -vx status | sort -u | tr '\n' ' '
}

# 인용 실재 확인에 쓰는 파이썬 함수. json_run 프로그램 앞에 붙여 쓴다. norm 은 공백을 하나로 접고,
# text 는 전역 `root` 기준 경로의 파일을 norm 해서 돌려주며(`파일:줄` 꼴이면 줄을 뗀다) 한 번 읽은
# 파일은 cache 에 둔다. 못 읽으면 None 이다.
AUDIT_PY_TEXT='
import os, re
def norm(s): return re.sub(r"\s+", " ", s or "").strip()
cache = {}
def text(p):
    p = (p or "").split(":")[0]
    if not p: return None
    if p not in cache:
        try: cache[p] = norm(open(os.path.join(root, p), encoding="utf-8").read())
        except Exception: cache[p] = None
    return cache[p]
'
