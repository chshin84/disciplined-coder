#!/usr/bin/env bash
# 재현 시험 도구(scripts/_replay.py·_judge.py)와 저장소 안 재현 시험 자료(evals/replay)를 본다.
# 저장소에는 실행 코드·판정 지시·턴 ID 만 두고, 대화 원문·답·판정은 %USERPROFILE%\.dc-eval\ 에 둔다(spec 「시험 체계」).
# 생성과 판정은 가짜 claude 로 바꾼 픽스처로 보므로 비용이 들지 않는다.
set -euo pipefail
HERE="$(cd "$(dirname "$0")/.." && pwd)"
. "$HERE/scripts/_test_check.sh"
. "$HERE/scripts/_json_valid.sh"
RP="$HERE/evals/replay"
T="$(mktemp -d)"; trap 'rm -rf "$T"' EXIT
secrets() { json_run 'import sys; sys.path.insert(0, sys.argv[1]); import _replay; print("\n".join(_replay.check_secrets(sys.argv[2])))' "$HERE/scripts" "$1" 2>&1 || echo "RUN-ERROR"; }

echo "[재현 시험 자료 — 비밀 패턴과 대화 원문]"
mkdir -p "$T/sec"
printf '%s\n' 'key sk-ant-abcdefgh12345' 'mail someone@example.com' 'path C:\Users\someone\x' > "$T/sec/x.md"
SFX="$(secrets "$T/sec")"
check "비밀 패턴 검사가 키·메일·PC 사용자 경로를 잡는다" "[ \"\$(grep -c 'x.md' <<<\"\$SFX\" || true)\" = 3 ]"
SECRET="$(secrets "$RP")"
[ -n "$SECRET" ] && printf '%s\n' "$SECRET" | sed 's/^/    /'
check "evals/replay 에 비밀 패턴(키·메일·PC 사용자 경로)이 없다" "[ -d '$RP' ] && [ -z \"\$SECRET\" ]"
# 턴 ID 파일(turns-*.txt)은 숫자 줄만 둔다. README 밖의 다른 파일은 대화 원문을 담을 수 있으므로 두지 않는다.
NONID=""; NTURN=0
if [ -d "$RP" ]; then
  while IFS= read -r f; do
    [ -n "$f" ] || continue
    case "$(basename "$f")" in
      README.md) ;;
      turns-*.txt) NTURN=$((NTURN+1)); tr -d '\r' < "$f" | grep -qvxE '[0-9]+' && NONID="$NONID $f" ;;
      *) NONID="$NONID $f" ;;
    esac
  done <<<"$(find "$RP" -type f)"
fi
[ -n "$NONID" ] && echo "    턴 ID 파일이 아니거나 숫자 밖의 줄이 있는 파일:$NONID"
check "evals/replay 에 대화 원문이 없다" "[ \"\$NTURN\" -gt 0 ] && [ -z \"\$NONID\" ]"

echo "[생성과 판정 — 가짜 claude 픽스처]"
mkdir -p "$T/fx"
FX="$(json_run 'import runpy,sys; p=sys.argv[1]; sys.argv=[p]+sys.argv[2:]; runpy.run_path(p, run_name="__main__")' "$HERE/scripts/_test_replay.py" "$HERE/scripts" "$T/fx" 2>&1 || true)"
while IFS= read -r line; do
  case "$line" in "OK "*) check "${line#OK }" true ;; "NG "*) check "${line#NG }" false ;; esac
done <<< "$FX"
check "픽스처 시험 프로그램이 끝까지 실행된다" "printf '%s\n' \"\$FX\" | tail -1 | grep -qx DONE"
printf '%s\n' "$FX" | grep -v '^\(OK\|NG\) \|^DONE$' | sed 's/^/    /' || true

echo "[상위 경로 — 생성 임시 폴더 위에 CLAUDE.md 가 있으면 찾는다]"
. "$HERE/scripts/_eval_env.sh" 2>/dev/null || ancestor_claude() { echo "(_eval_env.sh 없음)"; }
mkdir -p "$T/anc/.claude" "$T/anc/x/y" "$T/plain/x/y"; echo m > "$T/anc/.claude/CLAUDE.md"
A1="$(ancestor_claude "$T/anc/x/y" 2>&1 || true)"; A2="$(ancestor_claude "$T/plain/x/y" 2>&1 || true)"
check "상위의 .claude/CLAUDE.md 를 가장 가까운 것부터 낸다" "[ \"\$A1\" = \"\$T/anc/.claude/CLAUDE.md\" ]"
check "픽스처 안에 없으면 픽스처 경로를 내지 않는다" "case \"\$A2\" in \"\$T\"/*) false ;; *) true ;; esac"

echo "----"; echo "PASS=$pass FAIL=$fail"; [ "$fail" -eq 0 ]
