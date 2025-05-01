SET time_zone = '+00:00';

-- 퍼널 분석
WITH session_events AS (
  SELECT
    DATE_FORMAT(MIN(event_time), '%Y-%m') AS month,
    user_id,
    user_session,
    MIN(CASE WHEN event_type = 'view' THEN event_time END) AS view_at,
    MIN(CASE WHEN event_type = 'cart' THEN event_time END) AS cart_at,
    MIN(CASE WHEN event_type = 'purchase' THEN event_time END) AS purchase_at
  FROM cosmetics
  GROUP BY user_id, user_session
),
session_funnel AS (
	SELECT
		month,
        user_id,
        user_session,
        CASE WHEN view_at IS NOT NULL THEN 1 ELSE 0 END AS has_view,
        CASE
			WHEN view_at IS NOT NULL
			AND cart_at IS NOT NULL
			AND view_at <= cart_at
		THEN 1 ELSE 0 END AS view_to_cart,
        CASE
			WHEN view_at IS NOT NULL
			AND cart_at IS NOT NULL
			AND purchase_at IS NOT NULL
            AND view_at <= cart_at
			AND cart_at <= purchase_at
		THEN 1 ELSE 0 END AS cart_to_purchase
	FROM session_events
)
SELECT
  month,
  COUNT(CASE WHEN has_view = 1 THEN 1 END) AS view_sessions,
  COUNT(CASE WHEN view_to_cart = 1 THEN 1 END) AS cart_sessions,
  COUNT(CASE WHEN cart_to_purchase = 1 THEN 1 END) AS purchase_sessions,
  ROUND(COUNT(CASE WHEN view_to_cart = 1 THEN 1 END) * 100.0 / COUNT(CASE WHEN has_view = 1 THEN 1 END), 2) AS view_to_cart_rate,
  ROUND(COUNT(CASE WHEN cart_to_purchase = 1 THEN 1 END) * 100.0 / COUNT(CASE WHEN view_to_cart = 1 THEN 1 END), 2) AS cart_to_purchase_rate,
  ROUND(COUNT(CASE WHEN cart_to_purchase = 1 THEN 1 END) * 100.0 / COUNT(CASE WHEN has_view = 1 THEN 1 END), 2) AS view_to_purchase_rate
FROM session_funnel
GROUP BY month
ORDER BY month;

-- 장바구니 이탈 유형 분석
WITH session_events AS (
  SELECT
    DATE_FORMAT(MIN(event_time), '%Y-%m') AS month,
    user_id,
    user_session,
    MIN(CASE WHEN event_type = 'cart' THEN event_time END) AS cart_at,
    MIN(CASE WHEN event_type = 'remove_from_cart' THEN event_time END) AS remove_at,
    MIN(CASE WHEN event_type = 'purchase' THEN event_time END) AS purchase_at
  FROM cosmetics
  GROUP BY user_id, user_session
), 
session_funnel AS (
	SELECT
		month,
		user_id,
		user_session,
		CASE WHEN cart_at IS NOT NULL THEN 1 ELSE 0 END AS has_cart,
		CASE
			WHEN cart_at IS NOT NULL
			AND remove_at IS NOT NULL
            AND purchase_at IS NULL
			AND cart_at <= remove_at
		THEN 1 ELSE 0 END AS cart_to_remove,
		CASE
			WHEN cart_at IS NOT NULL
            AND remove_at IS NULL
			AND purchase_at IS NULL
		THEN 1 ELSE 0 END AS implicit_abandon,
        CASE
			WHEN cart_at IS NOT NULL
			AND purchase_at IS NOT NULL
            AND cart_at <= purchase_at
		THEN 1 ELSE 0 END AS cart_to_purchase        
	FROM session_events
)
SELECT
	month,
	COUNT(CASE WHEN has_cart = 1 THEN 1 END) AS cart_sessions,
    COUNT(CASE WHEN cart_to_purchase = 1 THEN 1 END) AS purchase_sessions,
	COUNT(CASE WHEN cart_to_remove = 1 THEN 1 END) AS explicit_abandon_sessions,
    COUNT(CASE WHEN implicit_abandon = 1 THEN 1 END) AS implicit_abandon_sessions,
	ROUND(COUNT(CASE WHEN cart_to_purchase = 1 THEN 1 END) * 100.0 / COUNT(CASE WHEN has_cart = 1 THEN 1 END), 2) AS cart_to_purchase_rate,    
	ROUND(COUNT(CASE WHEN cart_to_remove = 1 THEN 1 END) * 100.0 / COUNT(CASE WHEN has_cart = 1 THEN 1 END), 2) AS explicit_abandon_rate,
	ROUND(COUNT(CASE WHEN implicit_abandon = 1 THEN 1 END) * 100.0 / COUNT(CASE WHEN has_cart = 1 THEN 1 END), 2) AS implicit_abandon_rate,
    ROUND((COUNT(CASE WHEN cart_to_remove = 1 THEN 1 END) + COUNT(CASE WHEN implicit_abandon = 1 THEN 1 END)) * 100.0 / COUNT(CASE WHEN has_cart = 1 THEN 1 END), 2) AS total_abandon_rate
FROM session_funnel
GROUP BY month
ORDER BY month;

-- 가격과 전환율
WITH product_funnel AS (
  SELECT
    DATE_FORMAT(MIN(event_time), '%Y-%m') AS month,
    user_id,
    user_session,
    product_id,
    AVG(price) AS price,
    MIN(CASE WHEN event_type = 'cart' THEN event_time END) AS cart_at,
    MIN(CASE WHEN event_type = 'remove_from_cart' THEN event_time END) AS remove_at,
    MIN(CASE WHEN event_type = 'purchase' THEN event_time END) AS purchase_at
  FROM cosmetics
  GROUP BY user_id, user_session, product_id
)
SELECT
	month,
	price,
	CASE WHEN cart_at IS NOT NULL THEN 1 ELSE 0 END AS has_cart,
	CASE
		WHEN cart_at IS NOT NULL
		AND remove_at IS NOT NULL
		AND purchase_at IS NULL
		AND cart_at <= remove_at
	THEN 1 ELSE 0 END AS cart_to_remove,
	CASE
		WHEN cart_at IS NOT NULL
		AND remove_at IS NULL
		AND purchase_at IS NULL
	THEN 1 ELSE 0 END AS implicit_abandon,
	CASE
		WHEN cart_at IS NOT NULL
		AND purchase_at IS NOT NULL
		AND cart_at <= purchase_at
	THEN 1 ELSE 0 END AS cart_to_purchase        
FROM product_funnel
WHERE cart_at IS NOT NULL;

-- 가격대 구간
WITH price_ranks AS (
	SELECT
		product_id,
        price,
        ROW_NUMBER() OVER (ORDER BY price) AS row_num,
        COUNT(*) OVER () AS total_rows
	FROM cosmetics
    WHERE event_type = 'cart' 
    GROUP BY product_id, price
)
SELECT
	MIN(price) AS min,
	MAX(CASE WHEN row_num = FLOOR(0.25 * total_rows) THEN price END) AS Q1,
    MAX(CASE WHEN row_num = FLOOR(0.50 * total_rows) THEN price END) AS Q2,
    MAX(CASE WHEN row_num = FLOOR(0.75 * total_rows) THEN price END) AS Q3,
    MAX(price) AS max
FROM price_ranks;


WITH price_ranks AS (
	SELECT
		product_id,
        price,
        ROW_NUMBER() OVER (ORDER BY price) AS row_num,
        COUNT(*) OVER () AS total_rows
	FROM cosmetics
    GROUP BY product_id, price
)
SELECT
	MIN(price) AS min,
	MAX(CASE WHEN row_num = FLOOR(0.25 * total_rows) THEN price END) AS Q1,
    MAX(CASE WHEN row_num = FLOOR(0.50 * total_rows) THEN price END) AS Q2,
    MAX(CASE WHEN row_num = FLOOR(0.75 * total_rows) THEN price END) AS Q3,
    MAX(price) AS max
FROM price_ranks;

WITH price_ranks AS (
	SELECT
		product_id,
        price,
        ROW_NUMBER() OVER (ORDER BY price) AS row_num,
        COUNT(*) OVER () AS total_rows
	FROM cosmetics
    WHERE event_type = 'purchase' 
    GROUP BY product_id, price
)
SELECT
	MIN(price) AS min,
	MAX(CASE WHEN row_num = FLOOR(0.25 * total_rows) THEN price END) AS Q1,
    MAX(CASE WHEN row_num = FLOOR(0.50 * total_rows) THEN price END) AS Q2,
    MAX(CASE WHEN row_num = FLOOR(0.75 * total_rows) THEN price END) AS Q3,
    MAX(price) AS max
FROM price_ranks;

SELECT 
    FLOOR(price) AS price_bin,        -- $1 단위 가격 그룹
    COUNT(*) AS purchase_count
FROM cosmetics
WHERE event_type = 'purchase' 
GROUP BY price_bin
ORDER BY price_bin;

WITH product_events AS (
	SELECT
		user_id,
        user_session,
        product_id,
        price,
		MIN(CASE WHEN event_type = 'cart' THEN event_time END) AS cart_at,
		MIN(CASE WHEN event_type = 'remove_from_cart' THEN event_time END) AS remove_at,
		MIN(CASE WHEN event_type = 'purchase' THEN event_time END) AS purchase_at
	FROM cosmetics
	GROUP BY user_id, user_session, product_id, price
),
session_funnel AS (
	SELECT
		user_id,
		user_session,
        product_id,
        price,
		CASE WHEN cart_at IS NOT NULL THEN 1 ELSE 0 END AS has_cart,
		CASE
			WHEN cart_at IS NOT NULL
			AND purchase_at IS NOT NULL
			AND cart_at <= purchase_at
		THEN 1 ELSE 0 END AS cart_to_purchase,
		CASE
			WHEN cart_at IS NOT NULL
			AND remove_at IS NOT NULL
			AND purchase_at IS NULL
			AND cart_at <= remove_at
		THEN 1 ELSE 0 END AS cart_to_remove,
		CASE
			WHEN cart_at IS NOT NULL
			AND remove_at IS NULL
			AND purchase_at IS NULL
		THEN 1 ELSE 0 END AS implicit_abandon,
		CASE
			WHEN price < 2 THEN 'very low'
            WHEN price >= 2 AND price < 5 THEN 'low'
            WHEN price >= 5 AND price < 7 THEN 'mid'
            WHEN price >= 7 AND price < 10 THEN 'high'
			WHEN price >= 10 THEN 'premium'
		END AS price_group
	FROM product_events
)
SELECT
	price_group,
    COUNT(CASE WHEN has_cart = 1 THEN 1 END) AS cart_products,
    COUNT(CASE WHEN cart_to_purchase = 1 THEN 1 END) AS purchase_products,
	COUNT(CASE WHEN cart_to_remove = 1 THEN 1 END) AS explicit_abandon_products,
    COUNT(CASE WHEN implicit_abandon = 1 THEN 1 END) AS implicit_abandon_products,
	ROUND(COUNT(CASE WHEN cart_to_purchase = 1 THEN 1 END) * 100.0 / COUNT(CASE WHEN has_cart = 1 THEN 1 END), 2) AS cart_to_purchase_rate,    
	ROUND(COUNT(CASE WHEN cart_to_remove = 1 THEN 1 END) * 100.0 / COUNT(CASE WHEN has_cart = 1 THEN 1 END), 2) AS explicit_abandon_rate,
	ROUND(COUNT(CASE WHEN implicit_abandon = 1 THEN 1 END) * 100.0 / COUNT(CASE WHEN has_cart = 1 THEN 1 END), 2) AS implicit_abandon_rate
FROM session_funnel
GROUP BY price_group
ORDER BY FIELD(price_group, 'very low', 'low', 'mid', 'high', 'premium');

WITH product_events AS (
	SELECT
		user_id,
        user_session,
        product_id,
        price,
		MIN(CASE WHEN event_type = 'cart' THEN event_time END) AS cart_at,
		MIN(CASE WHEN event_type = 'remove_from_cart' THEN event_time END) AS remove_at,
		MIN(CASE WHEN event_type = 'purchase' THEN event_time END) AS purchase_at
	FROM cosmetics
	GROUP BY user_id, user_session, product_id, price
),
session_funnel AS (
	SELECT
		user_id,
		user_session,
        product_id,
        price,
		CASE WHEN cart_at IS NOT NULL THEN 1 ELSE 0 END AS has_cart,
		CASE
			WHEN cart_at IS NOT NULL
			AND purchase_at IS NOT NULL
			AND cart_at <= purchase_at
		THEN 1 ELSE 0 END AS cart_to_purchase,
		CASE
			WHEN cart_at IS NOT NULL
			AND remove_at IS NOT NULL
			AND purchase_at IS NULL
			AND cart_at <= remove_at
		THEN 1 ELSE 0 END AS cart_to_remove,
		CASE
			WHEN cart_at IS NOT NULL
			AND remove_at IS NULL
			AND purchase_at IS NULL
		THEN 1 ELSE 0 END AS implicit_abandon,
		CASE
			WHEN price < 5 THEN 'low'
            WHEN price >= 5 AND price < 10 THEN 'mid'
			WHEN price >= 10 THEN 'high'
		END AS price_group
	FROM product_events
)
SELECT
	price_group,
    COUNT(CASE WHEN has_cart = 1 THEN 1 END) AS cart_products,
    COUNT(CASE WHEN cart_to_purchase = 1 THEN 1 END) AS purchase_products,
	COUNT(CASE WHEN cart_to_remove = 1 THEN 1 END) AS explicit_abandon_products,
    COUNT(CASE WHEN implicit_abandon = 1 THEN 1 END) AS implicit_abandon_products,
	ROUND(COUNT(CASE WHEN cart_to_purchase = 1 THEN 1 END) * 100.0 / COUNT(CASE WHEN has_cart = 1 THEN 1 END), 2) AS cart_to_purchase_rate,    
	ROUND(COUNT(CASE WHEN cart_to_remove = 1 THEN 1 END) * 100.0 / COUNT(CASE WHEN has_cart = 1 THEN 1 END), 2) AS explicit_abandon_rate,
	ROUND(COUNT(CASE WHEN implicit_abandon = 1 THEN 1 END) * 100.0 / COUNT(CASE WHEN has_cart = 1 THEN 1 END), 2) AS implicit_abandon_rate
FROM session_funnel
GROUP BY price_group
ORDER BY FIELD(price_group, 'low', 'mid', 'high');

WITH product_events AS (
	SELECT
		user_id,
        user_session,
        product_id,
        price,
		MIN(CASE WHEN event_type = 'cart' THEN event_time END) AS cart_at,
		MIN(CASE WHEN event_type = 'remove_from_cart' THEN event_time END) AS remove_at,
		MIN(CASE WHEN event_type = 'purchase' THEN event_time END) AS purchase_at
	FROM cosmetics
	GROUP BY user_id, user_session, product_id, price
),
session_funnel AS (
	SELECT
		user_id,
		user_session,
        product_id,
        price,
        FLOOR(price) AS price_bin,  -- $1 단위 가격 그룹
		CASE WHEN cart_at IS NOT NULL THEN 1 ELSE 0 END AS has_cart,
		CASE
			WHEN cart_at IS NOT NULL
			AND purchase_at IS NOT NULL
			AND cart_at <= purchase_at
		THEN 1 ELSE 0 END AS cart_to_purchase,
		CASE
			WHEN cart_at IS NOT NULL
			AND remove_at IS NOT NULL
			AND purchase_at IS NULL
			AND cart_at <= remove_at
		THEN 1 ELSE 0 END AS cart_to_remove,
		CASE
			WHEN cart_at IS NOT NULL
			AND remove_at IS NULL
			AND purchase_at IS NULL
		THEN 1 ELSE 0 END AS implicit_abandon
	FROM product_events
)
SELECT
	price_bin,
    COUNT(CASE WHEN has_cart = 1 THEN 1 END) AS cart_products,
    COUNT(CASE WHEN cart_to_purchase = 1 THEN 1 END) AS purchase_products,
	COUNT(CASE WHEN cart_to_remove = 1 THEN 1 END) AS explicit_abandon_products,
    COUNT(CASE WHEN implicit_abandon = 1 THEN 1 END) AS implicit_abandon_products,
	ROUND(COUNT(CASE WHEN cart_to_purchase = 1 THEN 1 END) * 100.0 / COUNT(CASE WHEN has_cart = 1 THEN 1 END), 2) AS cart_to_purchase_rate,    
	ROUND(COUNT(CASE WHEN cart_to_remove = 1 THEN 1 END) * 100.0 / COUNT(CASE WHEN has_cart = 1 THEN 1 END), 2) AS explicit_abandon_rate,
	ROUND(COUNT(CASE WHEN implicit_abandon = 1 THEN 1 END) * 100.0 / COUNT(CASE WHEN has_cart = 1 THEN 1 END), 2) AS implicit_abandon_rate
FROM session_funnel
GROUP BY price_bin
ORDER BY price_bin;


WITH product_events AS (
	SELECT
		DATE_FORMAT(MIN(event_time), '%Y-%m') AS month,
		user_id,
        user_session,
        product_id,
        price,
		MIN(CASE WHEN event_type = 'cart' THEN event_time END) AS cart_at,
		MIN(CASE WHEN event_type = 'remove_from_cart' THEN event_time END) AS remove_at,
		MIN(CASE WHEN event_type = 'purchase' THEN event_time END) AS purchase_at
	FROM cosmetics
	GROUP BY user_id, user_session, product_id, price
),
session_funnel AS (
	SELECT
		month,
		user_id,
		user_session,
        product_id,
        price,
		CASE WHEN cart_at IS NOT NULL THEN 1 ELSE 0 END AS has_cart,
		CASE
			WHEN cart_at IS NOT NULL
			AND purchase_at IS NOT NULL
			AND cart_at <= purchase_at
		THEN 1 ELSE 0 END AS cart_to_purchase,
		CASE
			WHEN cart_at IS NOT NULL
			AND remove_at IS NOT NULL
			AND purchase_at IS NULL
			AND cart_at <= remove_at
		THEN 1 ELSE 0 END AS cart_to_remove,
		CASE
			WHEN cart_at IS NOT NULL
			AND remove_at IS NULL
			AND purchase_at IS NULL
		THEN 1 ELSE 0 END AS implicit_abandon,
		CASE
			WHEN price < 2 THEN 'very low'
            WHEN price >= 2 AND price < 5 THEN 'low'
            WHEN price >= 5 AND price < 7 THEN 'mid'
            WHEN price >= 7 AND price < 10 THEN 'high'
			WHEN price >= 10 THEN 'premium'
		END AS price_group
	FROM product_events
)
SELECT
	month,
	price_group,
    COUNT(CASE WHEN has_cart = 1 THEN 1 END) AS cart_products,
    COUNT(CASE WHEN cart_to_purchase = 1 THEN 1 END) AS purchase_products,
	COUNT(CASE WHEN cart_to_remove = 1 THEN 1 END) AS explicit_abandon_products,
    COUNT(CASE WHEN implicit_abandon = 1 THEN 1 END) AS implicit_abandon_products,
	ROUND(COUNT(CASE WHEN cart_to_purchase = 1 THEN 1 END) * 100.0 / COUNT(CASE WHEN has_cart = 1 THEN 1 END), 2) AS cart_to_purchase_rate,    
	ROUND(COUNT(CASE WHEN cart_to_remove = 1 THEN 1 END) * 100.0 / COUNT(CASE WHEN has_cart = 1 THEN 1 END), 2) AS explicit_abandon_rate,
	ROUND(COUNT(CASE WHEN implicit_abandon = 1 THEN 1 END) * 100.0 / COUNT(CASE WHEN has_cart = 1 THEN 1 END), 2) AS implicit_abandon_rate
FROM session_funnel
GROUP BY month, price_group
ORDER BY month, FIELD(price_group, 'very low', 'low', 'mid', 'high', 'premium');