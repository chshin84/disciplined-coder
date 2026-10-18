문서를 만들거나 고치기 전에 타입과 수명과 수정 규율을 구분하라. spec과 plan을 쓰는 방법은 superpowers가 소유하고, 아래 표는 spec과 plan의 수명과 표시 규칙만 정한다.

- **`MANAGED-BLOCK` (Markers around generated regions)** — 자동 생성 구간은 BEGIN/END 마커로 감싸 멱등 재생성하라. 사용자 콘텐츠는 그 바깥에 둬라.
