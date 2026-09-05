---
name: domain-writing
description: 문서를 새로 쓰거나 고칠 때 분량과 수정 범위와 완료 판정의 규칙이다. 카파시(Andrej Karpathy) 코딩 지침 세 절을 문서용으로 고친 것이다. 프로젝트 안의 .md를 만들거나 고치면 훅이 이 스킬을 열라고 알린다. 훅이 건너뛰는 spec·plan과 리뷰 기록과 프로젝트 밖 문서에서는 이 설명문으로 연다. 문서의 타입과 수명과 검진은 domain-docs가, 한국어 문장 규칙은 writing-korean이 소유한다.
---
# domain-writing — how much to write, how much to touch, when it is done

Adapted from `andrej-karpathy-skills` 1.0.0. The code wording lives in `domain-coding`; Think Before Acting lives in the canon.

## Simplicity First

The minimum document that solves the problem. Nothing speculative.
- No sections beyond what was asked.
- No templates or generalizations for a single-use document.
- No "flexibility" the reader did not ask for.
- If you write 200 lines and it could be 50, rewrite it.

## Surgical Changes

Touch only what the request needs. Clean up only your own mess.
- Don't "improve" adjacent paragraphs, wording, or formatting.
- Match the existing style, even if you'd write it differently.
- Remove sections and links that your change orphaned.
- Leave pre-existing dead text in place and mention it.

## Goal-Driven Execution

Define what the reader must be able to do after reading. Check the draft against that before calling the document done.

## Reach

Subagents do not receive this file automatically. When a subagent writes or edits a document, put this file's path in its prompt the way `domain-docs`'s 「렌즈에게 정본을 알리는 법」 prescribes for the canon.
