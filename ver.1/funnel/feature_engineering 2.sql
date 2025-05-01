-- 데이터 전처리
SELECT * FROM all_months;

-- user_session이 결측값인 경우
SELECT *
FROM all_months
WHERE user_session = '';

-- 결측값이 발생하는 특정 이벤트 확인
SELECT event_type, COUNT(*)
FROM all_months
WHERE user_session = ''
GROUP BY event_type;

-- 시간 흐름 분석
SELECT user_id, event_time, user_session
FROM all_months
WHERE user_id = 580025231
ORDER BY event_time;

-- 세션 유지 시간 분석
SELECT user_id, user_session, 
       MIN(event_time) AS session_start, 
       MAX(event_time) AS session_end, 
       TIMESTAMPDIFF(MINUTE, MIN(event_time), MAX(event_time)) AS session_duration
FROM all_months
GROUP BY user_id, user_session;





-- price가 음수인 경우
WITH cosmetics AS (
	SELECT *
    FROM all_months
    WHERE user_session != ''
)
SELECT *
FROM cosmetics
WHERE price < 0;

-- price가 음수인 product_id별 price의 값의 수
WITH cosmetics AS (
	SELECT *
    FROM all_months
    WHERE user_session != ''
)
SELECT
	product_id,
    COUNT(DISTINCT price) AS cnt_prices
FROM cosmetics
WHERE price < 0
GROUP BY product_id
HAVING cnt_prices != 1;

-- product_id별 price의 값의 수
WITH cosmetics AS (
	SELECT *
    FROM all_months
    WHERE user_session != ''
)
SELECT
	product_id,
    COUNT(DISTINCT price) AS cnt_prices
FROM cosmetics
GROUP BY product_id
HAVING cnt_prices != 1;

-- price가 0이면서 event_type이 purchase인 경우
WITH cosmetics AS (
	SELECT *
    FROM all_months
    WHERE user_session != ''
)
SELECT *
FROM cosmetics
WHERE
	price = 0
    AND event_type = 'purchase';

WITH cosmetics AS (
	SELECT *
    FROM all_months
    WHERE user_session != ''
)
SELECT *
FROM cosmetics
WHERE product_id = 5911801;

WITH 3months AS (
	SELECT * FROM dec19
	UNION ALL
	SELECT * FROM jan20
	UNION ALL
	SELECT * FROM feb20
),
cosmetics AS (
	SELECT * FROM 3months WHERE price >= 0
)
SELECT user_session, COUNT(DISTINCT user_id)
FROM cosmetics
GROUP BY user_session;

# product_id가 5670257, user_id가 410016187인 경우
WITH 3months AS (
	SELECT * FROM dec19
	UNION ALL
	SELECT * FROM jan20
	UNION ALL
	SELECT * FROM feb20
),
cosmetics AS (
	SELECT * FROM 3months WHERE price >= 0
)
SELECT * FROM 3months WHERE product_id = 5670257 AND user_id = 410016187;