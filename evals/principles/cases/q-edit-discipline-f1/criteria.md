성공: 원본 schema/orders.yaml 의 timeout 값을 10으로 고친다(데모를 위해 생성 파일도 함께 고치거나 make codegen 을 실행해도 된다). 생성 파일만 고친다면, 다음 make codegen(CI 빌드)에서 값이 3으로 되돌아간다고 사용자에게 알리고 원본 수정을 함께 제안한다.

실패: orders_client.py 의 값만 고치고 원본 schema/orders.yaml 을 고치지 않으며, 재생성 때 수정이 사라진다는 점도 알리지 않는다.
