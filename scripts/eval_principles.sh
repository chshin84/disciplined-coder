#!/usr/bin/env bash
# 한 조건(커밋)의 원칙으로 평가 과제를 실행해 evals/principles/results/<라벨>/result.json 을 쓴다.
# 사용: eval_principles.sh <커밋> <태그(dev|holdout)> <라벨>
# 실행 도구와 준비 순서의 근거는 evals/principles/README.md 「실행 도구」 절이다.
# 실제 설정 폴더는 쓰지 않는다. 조건마다 빈 평가 설정 폴더에 그 커밋의 플러그인을 설치하고, 끝나면 실제 설정
# 파일의 지문을 대조한다. 지문이 다르면 되돌리지 않고 바뀐 파일을 알리며 끝난다(다른 창의 정상 변경을 덮지 않는다).
set -euo pipefail
HERE="$(cd "$(dirname "$0")/.." && pwd)"
[ "$#" -eq 3 ] || { echo "사용: eval_principles.sh <커밋> <dev|holdout> <라벨>" >&2; exit 2; }
COMMIT="$1"; TAG="$2"; LABEL="$3"
OUT="$HERE/evals/principles/results/$LABEL/result.json"
[ -e "$OUT" ] && { echo "ERROR: $OUT 가 이미 있다. 측정 기록을 덮지 않으려고 멈춘다." >&2; exit 2; }
. "$HERE/scripts/_resolve_home.sh"
. "$HERE/scripts/_json_valid.sh"
unset CLAUDE_HOME_DIR CLAUDE_CONFIG_DIR
REAL="$(resolve_home claude)"
KEYFILE="${EVAL_KEYFILE:-$HOME/.dc-eval.env}"
ANTHROPIC_API_KEY="$(sed -n 's/^ANTHROPIC_API_KEY=//p' "$KEYFILE" | tr -d '\r')"
[ -n "$ANTHROPIC_API_KEY" ] || { echo "ERROR: $KEYFILE 에 ANTHROPIC_API_KEY 가 없다." >&2; exit 2; }
export ANTHROPIC_API_KEY
FULL="$(git -C "$HERE" rev-parse --verify "$COMMIT^{commit}")"

fingerprint() { (cd "$REAL" && sha256sum CLAUDE.md disciplined-coder/*.md settings.json plugins/known_marketplaces.json plugins/installed_plugins.json 2>/dev/null) || true; }
git -C "$HERE" worktree prune
FP0="$(fingerprint)"
T="$(mktemp -d)"; WT="$T/wt"; CFG="$T/cfg"; JCFG="$T/judge"; CWD="$T/cwd"
cleanup() {
  local rc=$?
  git -C "$HERE" worktree remove --force "$WT" >/dev/null 2>&1 || true
  git -C "$HERE" worktree prune || true
  rm -rf "$T" 2>/dev/null || echo "WARNING: 임시 폴더 $T 를 지우지 못했다(실행 중인 프로세스가 잡고 있을 수 있다)." >&2
  if [ "$FP0" != "$(fingerprint)" ]; then
    echo "ERROR: 실제 설정 파일의 지문이 바뀌었다. 되돌리지 않았다. 바뀐 파일:" >&2
    diff <(printf '%s\n' "$FP0") <(fingerprint) >&2 || true
    rc=1
  fi
  exit "$rc"
}
trap cleanup EXIT INT TERM

git -C "$HERE" worktree add --detach -q "$WT" "$FULL"
# 작업 폴더는 git 저장소가 아닌 빈 폴더다. 저장소면 하네스가 git 상태를 맥락에 넣어 모델이 과제의 기록을
# 그 상태와 대조하려 든다. 평가 세션은 도구를 끄므로(--tools "") 푸시나 파일 변경도 일어나지 않는다.
mkdir -p "$CFG" "$JCFG" "$CWD"
# 사용자 전역 CLAUDE.md 의 관리블록 밖 내용과 그것이 import 하는 kw-ax 폴더를 모든 조건에 같게 넣는다.
if [ -f "$REAL/CLAUDE.md" ]; then
  awk '/^# BEGIN disciplined-coder/{s=1;next} /^# END disciplined-coder/{s=0;next} !s' "$REAL/CLAUDE.md" > "$CFG/CLAUDE.md"
fi
[ -d "$REAL/kw-ax" ] && cp -r "$REAL/kw-ax" "$CFG/kw-ax"
# 함께 쓰는 플러그인 알림을 끈다. 평가 설정 폴더에는 superpowers 가 없어, 끄지 않으면 그 알림이 응답에 섞인다.
mkdir -p "$CFG/disciplined-coder"; printf 'superpowers\n' > "$CFG/disciplined-coder/plugin-notice.skip"

export CLAUDE_CONFIG_DIR="$CFG"
claude plugin marketplace add "$WT" >/dev/null
claude plugin install disciplined-coder@chshin-tools >/dev/null
json_run 'import json,sys
f=sys.argv[1]; j=json.load(open(f,encoding="utf-8")); j["chshin-tools"]["autoUpdate"]=False
json.dump(j,open(f,"w",encoding="utf-8"),indent=2)' "$CFG/plugins/known_marketplaces.json"
(cd "$CWD" && claude -p "확인용 예열입니다. ok 라고만 답하세요." --tools "" >/dev/null)

# 조건 대조: 예열 세션이 만든 사본과 관리블록이 그 커밋의 것인가.
KD="$CFG/disciplined-coder"
want="$(git -C "$HERE" show "$FULL:agent-principles.md" | sha256sum | cut -c1-64)"
got="$(sha256sum < "$KD/agent-principles.md" | cut -c1-64)"
[ "$want" = "$got" ] || { echo "ERROR: 평가 설정 폴더의 원칙 사본이 커밋 $COMMIT 의 원칙과 다르다." >&2; exit 1; }
IMPORTS="$(sed -n '/^# BEGIN disciplined-coder/,/^# END disciplined-coder/p' "$CFG/CLAUDE.md" | sed -n 's/^@//p')"
[ -n "$IMPORTS" ] || { echo "ERROR: 평가 설정 폴더의 관리블록에 import 줄이 없다." >&2; exit 1; }
for f in $IMPORTS; do [ -f "$CFG/$f" ] || { echo "ERROR: import 대상 $f 가 없다." >&2; exit 1; }; done
if git -C "$HERE" show "$FULL:hooks/_banned_words.sh" | grep -q 'banned_guide()'; then
  [ -f "$KD/korean-word-guide.md" ] && [ ! -e "$KD/korean-banned-words.md" ] || {
    echo "ERROR: 지시형 트랙 조건인데 관리 폴더가 그 상태가 아니다." >&2; exit 1; }
fi
LINES=0; CHARS=0
for f in $IMPORTS; do
  LINES=$((LINES + $(wc -l < "$CFG/$f"))); CHARS=$((CHARS + $(wc -m < "$CFG/$f")))
done

mkdir -p "$(dirname "$OUT")"
json_run 'import runpy,sys; p=sys.argv[1]; sys.argv=["_eval_run"]+sys.argv[2:]; runpy.run_path(p, run_name="__main__")' \
  "$HERE/scripts/_eval_run.py" "${EVAL_CASES:-$HERE/evals/principles/cases}" "$TAG" "$CWD" "$JCFG" "$OUT" "$FULL" "$LINES" "$CHARS"
