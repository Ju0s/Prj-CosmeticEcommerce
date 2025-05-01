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

-- 구매 고객 수가 급증한 날짜 찾기
SELECT 
    DATE_FORMAT(event_time, '%Y-%m-%d') AS purchase_date,
    COUNT(DISTINCT user_id) AS purchase_users
FROM cosmetics
WHERE event_type = 'purchase'
GROUP BY purchase_date
ORDER BY purchase_users DESC;

-- 급증한 날짜와 평소 대비 증가율 비교
WITH daily_purchase AS (
    SELECT 
        DATE_FORMAT(event_time, '%Y-%m-%d') AS purchase_date,
        COUNT(DISTINCT user_id) AS purchase_users
    FROM cosmetics
    WHERE event_type = 'purchase'
    GROUP BY purchase_date
),
avg_purchase AS (
    SELECT AVG(purchase_users) AS avg_users FROM daily_purchase
)
SELECT 
    d.purchase_date,
    d.purchase_users,
    a.avg_users,
    (d.purchase_users - a.avg_users) / a.avg_users * 100 AS increase_rate
FROM daily_purchase d
JOIN avg_purchase a
ORDER BY increase_rate DESC;


-- 각 단계별 유저 수
SELECT 
    event_type, 
    COUNT(DISTINCT user_id) AS user_count
FROM cosmetics
WHERE event_type IN ('view', 'cart', 'purchase')
GROUP BY event_type
ORDER BY FIELD(event_type, 'view', 'cart', 'purchase');

-- 퍼널 단계별 전환율
WITH funnel AS (
    SELECT 
        COUNT(DISTINCT CASE WHEN event_type = 'view' THEN user_id END) AS view_users,
        COUNT(DISTINCT CASE WHEN event_type = 'cart' THEN user_id END) AS cart_users,
        COUNT(DISTINCT CASE WHEN event_type = 'purchase' THEN user_id END) AS purchase_users
    FROM cosmetics
)
SELECT 
    view_users, 
    cart_users, 
    purchase_users,
    ROUND(cart_users / view_users * 100, 2) AS view_to_cart_rate,
    ROUND(purchase_users / cart_users * 100, 2) AS cart_to_purchase_rate,
    ROUND(purchase_users / view_users * 100, 2) AS view_to_purchase_rate
FROM funnel;

-- 날짜별 전환율 계산
WITH daily_funnel AS (
    SELECT 
		DATE_FORMAT(event_time, '%Y-%m-%d') AS date,
        COUNT(DISTINCT CASE WHEN event_type = 'view' THEN user_id END) AS view_users,
        COUNT(DISTINCT CASE WHEN event_type = 'cart' THEN user_id END) AS cart_users,
        COUNT(DISTINCT CASE WHEN event_type = 'purchase' THEN user_id END) AS purchase_users
    FROM cosmetics
    GROUP BY date
)
SELECT 
	date,
    view_users, 
    cart_users, 
    purchase_users,
    ROUND(cart_users / view_users * 100, 2) AS view_to_cart_rate,
    ROUND(purchase_users / cart_users * 100, 2) AS cart_to_purchase_rate,
    ROUND(purchase_users / view_users * 100, 2) AS view_to_purchase_rate
FROM daily_funnel;

-- 브랜드별 view → cart 전환율
SELECT 
    brand,
    COUNT(DISTINCT CASE WHEN event_type = 'view' THEN user_id END) AS view_count,
    COUNT(DISTINCT CASE WHEN event_type = 'cart' THEN user_id END) AS cart_count,
    ROUND(
        COUNT(DISTINCT CASE WHEN event_type = 'cart' THEN user_id END) /
        COUNT(DISTINCT CASE WHEN event_type = 'view' THEN user_id END) * 100, 2
    ) AS view_to_cart_rate
FROM cosmetics
WHERE brand IS NOT NULL
GROUP BY brand
ORDER BY view_to_cart_rate DESC;

-- 브랜드별 cart → purchase 전환율
SELECT 
    brand,
    COUNT(DISTINCT CASE WHEN event_type = 'cart' THEN user_id END) AS cart_count,
    COUNT(DISTINCT CASE WHEN event_type = 'purchase' THEN user_id END) AS purchase_count,
    ROUND(
        COUNT(DISTINCT CASE WHEN event_type = 'purchase' THEN user_id END) /
        COUNT(DISTINCT CASE WHEN event_type = 'cart' THEN user_id END) * 100, 2
    ) AS cart_to_purchase_rate
FROM cosmetics
WHERE brand IS NOT NULL
GROUP BY brand
HAVING cart_to_purchase_rate IS NOT NULL
ORDER BY cart_to_purchase_rate DESC;

-- 세션별 이벤트 흐름 분석
WITH session_flows AS (
	SELECT 
		user_session, 
		GROUP_CONCAT(DISTINCT event_type ORDER BY event_time SEPARATOR ' → ') AS session_flow
	FROM cosmetics
	GROUP BY user_session
)
SELECT session_flow, COUNT(*)
FROM session_flows
GROUP BY session_flow;

-- 구매 고객 vs. 이탈 고객 세션 길이 비교
WITH session_analysis AS (
	SELECT 
        user_session,
        TIMESTAMPDIFF(MINUTE, MIN(event_time), MAX(event_time)) AS session_duration,
        MAX(CASE WHEN event_type = 'purchase' THEN 1 ELSE 0 END) AS has_purchase
    FROM cosmetics
    GROUP BY user_session
)
SELECT 
    CASE 
        WHEN has_purchase = 1 THEN 'purchase'
        ELSE 'curn'
    END AS customer_type,
    ROUND(AVG(session_duration), 2) AS avg_session_duration
FROM session_analysis
GROUP BY customer_type;

