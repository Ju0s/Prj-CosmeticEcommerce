SELECT * FROM cosmetics;

-- 매출 분석
SELECT
	DATE_FORMAT(event_time, '%Y-%m-%d') AS date,
    COUNT(DISTINCT user_id) AS dau,
    COUNT(DISTINCT CASE WHEN event_type = 'purchase' THEN user_id END) * 100.0 / COUNT(DISTINCT user_id) AS pur,
    COUNT(DISTINCT CASE WHEN event_type = 'purchase' THEN user_id END) AS cnt_pu,
    sum(CASE WHEN event_type = 'purchase' THEN price END) / COUNT(DISTINCT CASE WHEN event_type = 'purchase' THEN user_id END) AS arppu,
    sum(CASE WHEN event_type = 'purchase' THEN price END) AS revenue
FROM cosmetics
GROUP BY date;

-- 재구매율
WITH purchase_counts AS (
    SELECT 
        user_id, 
        COUNT(DISTINCT DATE_FORMAT(event_time, '&Y-%m-%d')) AS purchase_days
    FROM cosmetics
    WHERE event_type = 'purchase'
    GROUP BY user_id
)
SELECT 
	COUNT(CASE WHEN purchase_days > 1 THEN user_id END) AS cnt_repeat_purchases,
    COUNT(CASE WHEN purchase_days = 1 THEN user_id END) AS cnt_new_purchases,
    COUNT(CASE WHEN purchase_days > 1 THEN user_id END) * 100.0 / COUNT(user_id) AS repeat_purchase_rate
FROM purchase_counts;

SELECT
	COUNT(DISTINCT user_id) AS cnt_users,
    COUNT(DISTINCT CASE WHEN event_type = 'purchase' THEN user_id END) AS cnt_purchase_users
FROM cosmetics;


-- event_type 개수
SELECT event_type, COUNT(*)
FROM cosmetics
GROUP BY event_type;

-- funnel
WITH funnel AS (
    SELECT 
        event_type,
        COUNT(DISTINCT user_id, user_session) AS session_count
    FROM cosmetics
    WHERE event_type IN ('view', 'cart', 'remove_from_cart', 'purchase')
    GROUP BY event_type
)
SELECT
    (SELECT COUNT(DISTINCT user_id) FROM cosmetics) AS total_users,
    SUM(CASE WHEN event_type = 'view' THEN session_count ELSE 0 END) AS views,
    SUM(CASE WHEN event_type = 'cart' THEN session_count ELSE 0 END) AS add_to_cart,
    SUM(CASE WHEN event_type = 'remove_from_cart' THEN session_count ELSE 0 END) AS removed_from_cart,
    SUM(CASE WHEN event_type = 'purchase' THEN session_count ELSE 0 END) AS purchases,
    ROUND(SUM(CASE WHEN event_type = 'cart' THEN session_count ELSE 0 END) 
          / NULLIF(SUM(CASE WHEN event_type = 'view' THEN session_count ELSE 0 END), 0) * 100, 2) 
          AS view_to_cart_conversion,
    ROUND(SUM(CASE WHEN event_type = 'purchase' THEN session_count ELSE 0 END) 
          / NULLIF(SUM(CASE WHEN event_type = 'cart' THEN session_count ELSE 0 END), 0) * 100, 2) 
          AS cart_to_purchase_conversion,
    ROUND(SUM(CASE WHEN event_type = 'purchase' THEN session_count ELSE 0 END) 
          / NULLIF(SUM(CASE WHEN event_type = 'view' THEN session_count ELSE 0 END), 0) * 100, 2) 
          AS view_to_purchase_conversion
FROM funnel;

-- 날짜별 funnel
WITH funnel AS (
    SELECT 
		DATE_FORMAT(event_time, '%Y-%m-%d') AS date,
        event_type,
        COUNT(DISTINCT user_id, user_session) AS session_count
    FROM cosmetics
    WHERE event_type IN ('view', 'cart', 'remove_from_cart', 'purchase')
    GROUP BY date, event_type
)
SELECT
    (SELECT COUNT(DISTINCT user_id) FROM cosmetics) AS total_users,
    SUM(CASE WHEN event_type = 'view' THEN session_count ELSE 0 END) AS views,
    SUM(CASE WHEN event_type = 'cart' THEN session_count ELSE 0 END) AS add_to_cart,
    SUM(CASE WHEN event_type = 'remove_from_cart' THEN session_count ELSE 0 END) AS removed_from_cart,
    SUM(CASE WHEN event_type = 'purchase' THEN session_count ELSE 0 END) AS purchases,
    ROUND(SUM(CASE WHEN event_type = 'cart' THEN session_count ELSE 0 END) 
          / NULLIF(SUM(CASE WHEN event_type = 'view' THEN session_count ELSE 0 END), 0) * 100, 2) 
          AS view_to_cart_conversion,
    ROUND(SUM(CASE WHEN event_type = 'purchase' THEN session_count ELSE 0 END) 
          / NULLIF(SUM(CASE WHEN event_type = 'cart' THEN session_count ELSE 0 END), 0) * 100, 2) 
          AS cart_to_purchase_conversion,
    ROUND(SUM(CASE WHEN event_type = 'purchase' THEN session_count ELSE 0 END) 
          / NULLIF(SUM(CASE WHEN event_type = 'view' THEN session_count ELSE 0 END), 0) * 100, 2) 
          AS view_to_purchase_conversion
FROM funnel;

SELECT COUNT(DISTINCT user_id) FROM all_months WHERE event_type = 'purchase';

-- 신규/재구매
WITH first_purchase AS (
    -- 각 user_id별 최초 구매 날짜 찾기
    SELECT user_id, MIN(event_time) AS first_purchase_date
    FROM cosmetics
    WHERE event_type = 'purchase'  -- 구매 이벤트만 필터링
    GROUP BY user_id
)
SELECT 
    COUNT(DISTINCT CASE WHEN p.first_purchase_date = c.event_time THEN c.user_id END) AS new_customers,
    COUNT(DISTINCT CASE WHEN p.first_purchase_date < c.event_time THEN c.user_id END) AS returning_customers
FROM cosmetics c
JOIN first_purchase p ON c.user_id = p.user_id
WHERE c.event_type = 'purchase';

SELECT COUNT(DISTINCT user_id)
FROM all_months
GROUP BY user_session;

SELECT COUNT(DISTINCT user_id)
FROM cosmetics
GROUP BY user_session;

SELECT COUNT(DISTINCT user_session)
FROM all_months
GROUP BY user_id;