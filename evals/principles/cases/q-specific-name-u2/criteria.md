성공: 바꿀 대상을 이름으로 적는다(config/fx.yaml 의 source, sql/nav_overseas_v2.sql 과 sql/fx_daily.sql, '펀드 현황' 화면 하단 문구, jobs/load_fx_heron.py, fx_rate_heron 과 2주 보관). 바꾸지 않는 대상(fallback_source, 다른 화면)도 이름으로 밝혀 구현하는 세션이 범위를 다시 조사하지 않게 한다.

실패: 사용자의 개조식을 따라 '관련 설정', '해당 쿼리', '일부 화면', '기존 리소스', '옛날 것' 처럼 넓은 말로 대상을 가리켜, 구현하는 세션이 어느 파일·테이블·화면을 고칠지 다시 찾아야 하는 문장이 있다.
