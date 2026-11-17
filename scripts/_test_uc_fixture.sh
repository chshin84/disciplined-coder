#!/usr/bin/env bash
# 공유: 갱신 확인 훅(hooks/update_check_sessionstart.sh)을 스텁으로 실행하는 픽스처. 소비자는 scripts/test_scaffold.sh 와
# scripts/test_hooks.sh 다. 호출자가 $HERE(저장소 뿌리)를 정한다.
# 갱신 확인은 scaffold 가 아니라 hooks/update_check_sessionstart.sh 가 실행한다. claude 와 curl 을
# 실제로 부르지 않도록 스텁을 주입한다. claude 스텁은 받은 인자를 args.txt 에 적어 무엇을 실행했는지
# 단언하게 하고, curl 스텁은 remote.txt 의 커밋을 git smart HTTP 의 pkt-line 형식으로 낸다.
run_uc() { CLAUDE_HOME_DIR="$1/.claude" DISCIPLINED_CODER_CLAUDE_BIN="$1/claude-stub" DISCIPLINED_CODER_CURL_BIN="$1/curl-stub" CLAUDE_PLUGIN_ROOT="${2:-}" bash "$HERE/hooks/update_check_sessionstart.sh" < /dev/null; }
# claude 스텁. plugin update 가 0 으로 끝나면 실제 CLI 처럼 설치 기록의 커밋을 옮긴다(원격 커밋, 원격을
# 못 읽으면 사본 HEAD). $1/nomove 가 있으면 0 으로 끝나도 옮기지 않는다 — 명령은 성공했는데 설치본이
# 그대로인 상황이다. $3 은 종료 전에 끼워 넣을 셸 줄이다(사본 폴더가 잡힌 상황을 흉내 낼 때 쓴다).
uc_stub() {  # $1=HOME $2=종료 코드 $3=끼워 넣을 줄
  cat > "$1/claude-stub" <<STUB
#!/usr/bin/env bash
printf '%s\n' "\$*" >> "$1/args.txt"
${3:-}
if [ "\$1 \$2" = "plugin update" ] && [ "$2" = 0 ] && [ ! -f "$1/nomove" ]; then
  n="\$(cat "$1/remote.txt")"; [ -n "\$n" ] || n="\$(git -C "$1/.claude/plugins/marketplaces/chshin-tools" rev-parse HEAD)"
  sed -i "s/\"gitCommitSha\": \"[^\"]*\"/\"gitCommitSha\": \"\$n\"/" "$1/.claude/plugins/installed_plugins.json"
fi
exit $2
STUB
  chmod +x "$1/claude-stub"
}
uc_fixture() {  # $1=HOME $2=설치본 커밋 $3=claude 스텁 종료 코드 $4=원격 커밋(빈 값이면 원격을 못 읽는다) $5=source 의 ref → 사본의 HEAD 를 출력한다
  local m="$1/.claude/plugins/marketplaces/chshin-tools" ref=""
  mkdir -p "$m"
  if [ -n "${5:-}" ]; then ref=", \"ref\": \"$5\""; fi
  printf '{ "version": 2, "plugins": { "disciplined-coder@chshin-tools": [ { "scope": "user", "gitCommitSha": "%s" } ] } }\n' "$2" > "$1/.claude/plugins/installed_plugins.json"
  printf '{ "chshin-tools": { "source": { "source": "github", "repo": "chshin84/disciplined-coder"%s } } }\n' "$ref" > "$1/.claude/plugins/known_marketplaces.json"
  git init -q "$m"; git -C "$m" -c user.email=t@t -c user.name=t commit -q --allow-empty -m x
  uc_stub "$1" "$3"
  printf '%s' "${4:-}" > "$1/remote.txt"
  # 실제 응답처럼 길이 접두사 4자와 NUL 이 섞인 줄을 낸다. 길이 접두사를 커밋으로 잘못 읽으면 실패한다.
  cat > "$1/curl-stub" <<STUB
#!/usr/bin/env bash
printf '%s\n' "\$*" >> "$1/curl-args.txt"
r="\$(cat "$1/remote.txt")"; [ -n "\$r" ] || exit 22
printf '001e# service=git-upload-pack\n0000015b%s HEAD\0multi_ack side-band\n003f%s refs/heads/main\n0000' "\$r" "\$r"
STUB
  chmod +x "$1/claude-stub" "$1/curl-stub"
  git -C "$m" rev-parse HEAD
}
A40="aaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaa"; B40="bbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbb"; C40="cccccccccccccccccccccccccccccccccccccccc"
