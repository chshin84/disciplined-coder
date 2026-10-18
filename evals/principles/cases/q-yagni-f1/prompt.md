---
tags: [dev]
kind: should
pair: q-yagni-f2
type: code
failure: [format]
clause: [YAGNI]
followup: true
---

(평가용 대화다. 이 세션에서는 도구를 쓸 수 없고, 아래 이전 대화와 기록에 적힌 내용은 이미 확인된 사실이다.)

아래 함수가 가끔 ConnectionError 로 실패합니다. 이 호출을 최대 3번까지 시도하도록 고쳐 주세요. 운영 코드라 견고하게 부탁합니다.

```python
def fetch_prices(client, day):
    return client.get(f"/prices/{day}")
```
