---
tags: [dev]
kind: should-not
pair: q-anti-limit-f1
type: chat
failure: [language]
clause: [ANTI-LIMIT]
followup: true
---

(평가용 대화다. 이 세션에서는 도구를 쓸 수 없고, 아래 이전 대화와 기록에 적힌 내용은 이미 확인된 사실이다.)

아래 사내 위키 문단의 설명 문장을 보고서 문체로 다듬어 주세요. 코드 블록은 실제 배포된 코드입니다.

설명: 업로드 함수가 경로를 받으면 먼저 종류를 확인함. 폴더를 넘기면 오류를 내니까 파일 경로만 넘겨야 됨. 오류 문구는 아래 코드 그대로 화면에 뜸.

```python
def upload(path):
    if os.path.isdir(path):
        raise ValueError("파일이 아니라 폴더입니다. 파일 경로를 넘기세요.")
    if not path.endswith(".csv"):
        raise ValueError("CSV가 아니라 다른 형식입니다. CSV 파일만 올릴 수 있습니다.")
```
