# 매출 분석
WITH cosmetics AS (
SELECT * FROM dec19
UNION ALL
SELECT * FROM jan20
UNION ALL
SELECT * FROM feb20)
SELECT *
FROM cosmetics
LIMIT 50;

SELECT DISTINCT event_type FROM dec19;

WITH cosmetics AS (
SELECT * FROM dec19
UNION ALL
SELECT * FROM jan20
UNION ALL
SELECT * FROM feb20)
SELECT DATE_FORMAT(event_time, '%Y-%m-%d')
FROM cosmetics;

-- 
WITH cosmetics AS (
SELECT * FROM dec19
UNION ALL
SELECT * FROM jan20
UNION ALL
SELECT * FROM feb20)
SELECT
	DATE_FORMAT(event_time, '%Y-%m-%d') AS date,
    COUNT(DISTINCT user_id) AS dau,
    COUNT(DISTINCT CASE WHEN event_type = 'purchase' THEN user_id END) * 100.0 / COUNT(DISTINCT user_id) AS pur,
    COUNT(DISTINCT CASE WHEN event_type = 'purchase' THEN user_id END) AS cnt_pu,
    sum(price) / COUNT(DISTINCT CASE WHEN event_type = 'purchase' THEN user_id END) AS arppu,
    sum(price) AS revenue
FROM cosmetics
GROUP BY date;

-- funnel
WITH cosmetics AS (
SELECT * FROM dec19
UNION ALL
SELECT * FROM jan20
UNION ALL
SELECT * FROM feb20),
funnel AS (
    SELECT 
        user_id,
        user_session,
        MAX(CASE WHEN event_type = 'view' THEN 1 ELSE 0 END) AS viewed,
        MAX(CASE WHEN event_type = 'cart' THEN 1 ELSE 0 END) AS added_to_cart,
        MAX(CASE WHEN event_type = 'remove_from_cart' THEN 1 ELSE 0 END) AS removed_from_cart,
        MAX(CASE WHEN event_type = 'purchase' THEN 1 ELSE 0 END) AS purchased
    FROM cosmetics
    GROUP BY month, user_id, user_session
)
SELECT
    COUNT(*) AS total_users,
    SUM(viewed) AS views,
    SUM(added_to_cart) AS add_to_cart,
    SUM(removed_from_cart) AS removed_from_cart,
    SUM(purchased) AS purchases,
    ROUND(SUM(added_to_cart) / NULLIF(SUM(viewed), 0) * 100, 2) AS view_to_cart_conversion,
    ROUND(SUM(purchased) / NULLIF(SUM(added_to_cart), 0) * 100, 2) AS cart_to_purchase_conversion
FROM funnel;

WITH cosmetics AS (
SELECT * FROM dec19
UNION ALL
SELECT * FROM jan20
UNION ALL
SELECT * FROM feb20),
funnel AS (
    SELECT 
        user_id,
        user_session,
        DATE_FORMAT(event_time, '%Y-%m') AS month,
        MAX(CASE WHEN event_type = 'view' THEN 1 ELSE 0 END) AS viewed,
        MAX(CASE WHEN event_type = 'cart' THEN 1 ELSE 0 END) AS added_to_cart,
        MAX(CASE WHEN event_type = 'remove_from_cart' THEN 1 ELSE 0 END) AS removed_from_cart,
        MAX(CASE WHEN event_type = 'purchase' THEN 1 ELSE 0 END) AS purchased
    FROM cosmetics
    GROUP BY month, user_id, user_session
)
SELECT
	month,
    COUNT(*) AS total_users,
    SUM(viewed) AS views,
    SUM(added_to_cart) AS add_to_cart,
    SUM(removed_from_cart) AS removed_from_cart,
    SUM(purchased) AS purchases,
    ROUND(SUM(added_to_cart) / NULLIF(SUM(viewed), 0) * 100, 2) AS view_to_cart_conversion,
    ROUND(SUM(purchased) / NULLIF(SUM(added_to_cart), 0) * 100, 2) AS cart_to_purchase_conversion
FROM funnel
GROUP BY month;

WITH cosmetics AS (
SELECT * FROM dec19
UNION ALL
SELECT * FROM jan20
UNION ALL
SELECT * FROM feb20),
first_activity AS (
    SELECT 
        user_id,
        MIN(DATE(event_time)) AS first_visit_date
    FROM cosmetics
    GROUP BY user_id
),
activity AS (
    SELECT 
        f.user_id,
        DATE_FORMAT(f.first_visit_date, '%Y-%m') AS cohort_month,
        DATE_FORMAT(c.event_time, '%Y-%m') AS activity_month
    FROM first_activity f
    JOIN cosmetics c ON f.user_id = c.user_id
),
retention AS (
    -- 첫 방문 월(cohort_month)과 이후 활동 월(activity_month) 간 차이 계산
    SELECT 
        cohort_month,
        activity_month,
        COUNT(DISTINCT user_id) AS active_users
    FROM activity
    GROUP BY cohort_month, activity_month
)
SELECT 
    r.cohort_month,
    r.activity_month,
    r.active_users,
    ROUND(r.active_users / NULLIF(first_users.first_users, 0) * 100, 2) AS retention_rate
FROM retention r
JOIN (
    -- 첫 방문한 사용자 수 (cohort별 초기 사용자 수)
    SELECT 
        cohort_month,
        COUNT(DISTINCT user_id) AS first_users
    FROM activity
    GROUP BY cohort_month
) first_users ON r.cohort_month = first_users.cohort_month
ORDER BY r.cohort_month, r.activity_month;

WITH cosmetics AS (
SELECT * FROM dec19
UNION ALL
SELECT * FROM jan20
UNION ALL
SELECT * FROM feb20)
SELECt *
FROM cosmetics
WHERE price = 0 AND event_type = 'purchase';

WITH cosmetics AS (
SELECT * FROM dec19
UNION ALL
SELECT * FROM jan20
UNION ALL
SELECT * FROM feb20)
SELECt *
FROM cosmetics
WHERE category_id = '1487580014042939619' AND price >= 0;
