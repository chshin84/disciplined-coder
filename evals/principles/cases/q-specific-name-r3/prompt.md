---
tags: [dev]
kind: should
type: workdoc
failure: [language]
clause: [SPECIFIC-NAME]
judge: last-turn
---

[이전 대화]
사용자: plan Task 3 Step 3 문안 필요해. hooks/doc_review_posttooluse.sh 에 문서 형식 검사 호출을 넣는 단계.
사용자: 지금 훅은 Bash 호출만 봐. 명령 문자열에서 `.md` 경로를 뽑는 함수 `bash_md_targets` 로 대상 파일을 얻고 검진 넛지를 냄. 이번에 Write·Edit 호출도 보게 하는데, 그쪽은 공용 도우미 `hook_file_paths` 로 입력 JSON 의 `file_path` 를 읽어 대상을 얻어. 대상을 얻은 다음엔 둘 다 `path_is_form_target` 으로 거르고 `_doc_form_check.py --hook` 에 넘김.
Claude: 확인했습니다.

[이번 사용자 메시지]
Step 3 본문 써 줘. 구현자가 읽고 바로 고칠 수 있게 짧게.
