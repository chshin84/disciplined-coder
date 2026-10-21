#!/usr/bin/env bash
# 문서 형식 정규식 검사기(hooks/_doc_form_check.py)의 판정을 본다. 라벨 불릿·개수 예고·제목 개수를 잡고,
# 펜스·인용·백틱 안은 건너뛰며, BOM 과 cp949 파일을 읽는지 확인한다.
set -euo pipefail
HERE="$(cd "$(dirname "$0")/.." && pwd)"
. "$HERE/scripts/_test_check.sh"
. "$HERE/scripts/_json_valid.sh"
CHK="$HERE/hooks/_doc_form_check.py"
T="$(mktemp -d)"; trap 'rm -rf "$T"' EXIT

# 검사기를 파일 인자로 실행한다. 훅 입력은 Bash 도구로 두어 FILE 인자를 읽게 한다.
run_file() { printf '{"tool_name":"Bash"}' | json_run 'import runpy,sys; p=sys.argv[1]; sys.argv=[p]+sys.argv[2:]; runpy.run_path(p, run_name="__main__")' "$CHK" --hook "$1" 2>&1 || true; }
# 본문을 파일에 쓰고 실행한다. $1=본문(printf 서식), 출력은 검사기 출력.
run_text() { printf -- "$1" > "$T/in.md"; run_file "$T/in.md"; }
count_of() { printf '%s' "$1" | grep -c "$2" || true; }

echo "[라벨 불릿]"
OUT="$(run_text '- **금액 필드:** v1은 정수다. v2는 문자열이다.\n')"
check "label_two_sentences" "[ \"\$(count_of \"\$OUT\" '라벨 불릿')\" = 1 ]"
OUT="$(run_text '- **금액 필드:** v1은 정수다.\n')"
check "label_one_sentence_ok" "[ -z \"\$OUT\" ]"
OUT="$(run_text '- **입력:** 경로(e.g. 절대 경로)를 받는다.\n')"
check "label_abbrev_ok" "[ -z \"\$OUT\" ]"
OUT="$(run_text '- v1은 정수다. v2는 문자열이다.\n')"
check "plain_bullet_two_sentences_ok" "[ -z \"\$OUT\" ]"
OUT="$(run_text '- **`ID`** — 첫 문장이다. 둘째 문장이다.
')"
check "label_backtick_in_label" "[ \"\$(count_of \"\$OUT\" '라벨 불릿')\" = 1 ]"
OUT="$(run_text '- **a:** `b다. c다.` 를 쓴다.
')"
check "label_backtick_sentences_ok" "[ -z \"\$OUT\" ]"
OUT="$(run_text '1. **라벨** — 첫 문장이다. 둘째 문장이다.
')"
check "label_numbered_item" "[ \"\$(count_of \"\$OUT\" '라벨 불릿')\" = 1 ]"

echo "[개수 예고]"
OUT="$(run_text '확인할 사항은 세 가지다.\n- 첫째\n')"
check "count_preview" "[ \"\$(count_of \"\$OUT\" '개수 예고')\" = 1 ]"
OUT="$(run_text '2026-10-20 개정 사항:\n- 조항 삭제\n\n인터넷이 끊겼다.\n- 재시도\n')"
check "count_substring_ok" "[ -z \"\$OUT\" ]"
OUT="$(run_text '| 항목 | 세 가지 |\n- 첫째\n')"
check "count_in_table_ok" "[ -z \"\$OUT\" ]"
OUT="$(run_text '아래 세 가지를 고쳤다.
- 첫째

다음 3개의 파일을 바꿨다.
- a.md
')"
check "count_preview_particle" "[ \"\$(count_of \"\$OUT\" '개수 예고')\" = 2 ]"
OUT="$(run_text '열 개국이 참여했다.
- 한국
')"
check "count_other_word_ok" "[ -z \"\$OUT\" ]"

echo "[제목 개수]"
OUT="$(run_text '## 금지사항 넷\n')"
check "heading_count" "[ \"\$(count_of \"\$OUT\" '제목 개수')\" = 1 ]"
OUT="$(run_text '## 1단계 준비\n')"
check "heading_step_ok" "[ -z \"\$OUT\" ]"

echo "[건너뛰는 구간]"
OUT="$(run_text '```\n- **a:** b다. c다.\n```\n')"
check "fenced_code_ignored" "[ -z \"\$OUT\" ]"
OUT="$(run_text '- `**a:** b다. c다.`\n')"
check "backtick_ignored" "[ -z \"\$OUT\" ]"
OUT="$(run_text '> - **a:** b다. c다.\n')"
check "quote_ignored" "[ -z \"\$OUT\" ]"

echo "[인코딩]"
printf '\xef\xbb\xbf## 금지사항 넷\n' > "$T/bom.md"
OUT="$(run_file "$T/bom.md")"
check "bom_heading" "[ \"\$(count_of \"\$OUT\" '제목 개수')\" = 1 ]"
json_run 'import sys; open(sys.argv[1],"wb").write("## 금지사항 넷\n".encode("cp949"))' "$T/cp.md"
OUT="$(run_file "$T/cp.md")"
check "cp949_file" "[ \"\$(count_of \"\$OUT\" '제목 개수')\" = 1 ]"

echo "[출력 상한과 훅 입력]"
: > "$T/seven.md"
for i in 1 2 3 4 5 6 7; do printf -- '- **a%s:** b다. c다.\n' "$i" >> "$T/seven.md"; done
OUT="$(run_file "$T/seven.md")"
check "cap_five" "[ \"\$(count_of \"\$OUT\" '라벨 불릿')\" = 5 ] && printf '%s' \"\$OUT\" | grep -q '외 2건'"
OUT="$(printf '%s' '{"tool_name":"Edit","tool_input":{"file_path":"x.md","new_string":"- **a:** b다. c다."}}' | json_run 'import runpy,sys; p=sys.argv[1]; sys.argv=[p]+sys.argv[2:]; runpy.run_path(p, run_name="__main__")' "$CHK" --hook 2>&1 || true)"
check "hook_edit_new_string" "[ \"\$(count_of \"\$OUT\" '라벨 불릿')\" = 1 ] && printf '%s' \"\$OUT\" | grep -qF 'x.md(편집 문자열):1:'"
OUT="$(printf '%s' '{"tool_name":"Write","tool_input":{"file_path":"x.md","content":"- **a:** b다. c다."}}' | json_run 'import runpy,sys; p=sys.argv[1]; sys.argv=[p]+sys.argv[2:]; runpy.run_path(p, run_name="__main__")' "$CHK" --hook 2>&1 || true)"
check "hook_write_plain_label" "printf '%s' \"\$OUT\" | grep -q '^x.md:1:'"
OUT="$(run_text '- **a:** b다. c다.
')"
check "file_arg_whole_label" "printf '%s' \"\$OUT\" | grep -qF 'in.md(파일 전체):1:'"

echo "통과 $pass, 실패 $fail"
[ "$fail" -eq 0 ]
