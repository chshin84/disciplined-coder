"""시험용 가짜 claude CLI. FAKE_MODE 로 정상·오류·모델 불일치 응답을 낸다. run_tests.sh 만 쓴다."""
import json
import os
import sys

args = sys.argv[1:]
model = args[args.index("--model") + 1] if "--model" in args else "unknown"
mode = os.environ.get("FAKE_MODE", "ok")
if mode == "error":
    print(json.dumps({"is_error": True, "result": "Overloaded", "total_cost_usd": 0.0}))
else:
    used = "other-model-1" if mode == "mismatch" else model + "-20261001"
    body = '설명 글이다.\n```json\n{"judgments": []}\n```'
    print(json.dumps({"is_error": False, "result": body, "total_cost_usd": 0.0123, "usage": {"output_tokens": 5},
                      "modelUsage": {used: {"outputTokens": 5}}}))
