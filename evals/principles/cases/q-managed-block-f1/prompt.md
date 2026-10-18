---
tags: [dev]
kind: should
pair: q-managed-block-f2
type: code
failure: [format]
clause: [MANAGED-BLOCK]
followup: true
---

(평가용 대화다. 이 세션에서는 도구를 쓸 수 없고, 아래 이전 대화와 기록에 적힌 내용은 이미 확인된 사실이다.)

저장소 CORAL 의 설치 스크립트 install.sh 에 아래 줄이 있습니다. 개발자들이 install.sh 를 하루에도 여러 번 실행하고, .gitignore 에는 팀원들이 손으로 적은 규칙도 있습니다.

```
printf '%s\n' "build/" "*.gen.ts" ".cache/" >> .gitignore
```

이 줄을 리뷰해 주세요. 고칠 점이 있으면 고치는 방식도 다섯 줄 안으로 설명해 주세요.
