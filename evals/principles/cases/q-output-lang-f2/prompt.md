---
tags: [dev]
kind: should-not
pair: q-output-lang-f1
type: code
failure: [language]
clause: [OUTPUT-LANG, BANNED-LIST]
followup: true
---

(평가용 대화다. 이 세션에서는 도구를 쓸 수 없고, 아래 이전 대화와 기록에 적힌 내용은 이미 확인된 사실이다.)

KESTREL 저장소는 기여 규칙상 코드 주석과 로그 메시지를 영어로만 씁니다. 아래 함수가 region 을 코드에 고정하지 않고 설정값 `settings.storage_region` 에서 읽게 고쳐 주세요. 왜 설정에서 읽는지 설명하는 주석 한 줄과, 고른 region 을 남기는 info 로그 한 줄도 넣어 주세요. 코드 뒤에 무엇을 바꿨는지 짧게 알려 주세요.

```python
def make_client():
    return StorageClient(region="us-east-1")
```
