SET time_zone = '+00:00';
-- 매출 분석
SELECT
	DATE_FORMAT(event_time, '%Y-%m') AS month,
	COUNT(DISTINCT user_id) AS mau,
    COUNT(DISTINCT CASE WHEN event_type = 'purchase' THEN user_id END) * 100.0 / COUNT(DISTINCT user_id) AS pu_rate,
    COUNT(DISTINCT CASE WHEN event_type = 'purchase' THEN user_id END) AS cnt_pu,
    ROUND(SUM(CASE WHEN event_type = 'purchase' THEN price END) / COUNT(DISTINCT CASE WHEN event_type = 'purchase' THEN user_id END), 2) AS arppu,
	ROUND(SUM(CASE WHEN event_type = 'purchase' THEN price END), 2) AS month_revenue,
    ROUND(COUNT(CASE WHEN event_type = 'purchase' THEN event_time END) / COUNT(DISTINCT CASE WHEN event_type = 'purchase' THEN user_id END), 2) AS avg_purchase_frequency
FROM cosmetics
GROUP BY month;



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
	MAX(CASE WHEN row_num = FLOOR(0.25 * total_rows) THEN price END) AS Q1,
    MAX(CASE WHEN row_num = FLOOR(0.50 * total_rows) THEN price END) AS Q2,
    MAX(CASE WHEN row_num = FLOOR(0.75 * total_rows) THEN price END) AS Q3
FROM price_ranks;

SELECT * FROM cosmetics WHERE price IS NULL;

WITH session_prices AS (
	SELECT
		user_id,
        user_session,
        AVG(price) AS avg_cart_price
	FROM cosmetics
    WHERE event_type = 'cart'
    GROUP BY user_id, user_session
),
session_events AS (
	SELECT
		user_id,
        user_session,
-- 		DATE_FORMAT(MIN(event_time), '%Y-%m') AS month,
		MIN(CASE WHEN event_type = 'cart' THEN event_time END) AS cart_at,
		MIN(CASE WHEN event_type = 'remove_from_cart' THEN event_time END) AS remove_at,
		MIN(CASE WHEN event_type = 'purchase' THEN event_time END) AS purchase_at
	FROM cosmetics
	GROUP BY user_id, user_session
),
session_funnel AS (
	SELECT
-- 		se.month,
		se.user_id,
		se.user_session,
		CASE WHEN se.cart_at IS NOT NULL THEN 1 ELSE 0 END AS has_cart,
		CASE
			WHEN se.cart_at IS NOT NULL
			AND se.purchase_at IS NOT NULL
			AND se.cart_at <= se.purchase_at
		THEN 1 ELSE 0 END AS cart_to_purchase,
		CASE
			WHEN se.cart_at IS NOT NULL
			AND se.remove_at IS NOT NULL
			AND se.purchase_at IS NULL
			AND se.cart_at <= se.remove_at
		THEN 1 ELSE 0 END AS cart_to_remove,
		CASE
			WHEN se.cart_at IS NOT NULL
			AND se.remove_at IS NULL
			AND se.purchase_at IS NULL
		THEN 1 ELSE 0 END AS implicit_abandon,
		CASE
			WHEN sp.avg_cart_price < 1.05 THEN 'low'
            WHEN sp.avg_cart_price >= 1.05 AND sp.avg_cart_price < 6.83 THEN 'mid'
			WHEN sp.avg_cart_price >= 6.83 THEN 'high'
		END AS price_group
	FROM session_events AS se
    JOIN session_prices AS sp
	ON se.user_id = sp.user_id
		AND se.user_session = sp.user_session
)
SELECT
	price_group,
    COUNT(CASE WHEN has_cart = 1 THEN 1 END) AS cart_sessions,
    COUNT(CASE WHEN cart_to_purchase = 1 THEN 1 END) AS purchase_sessions,
	COUNT(CASE WHEN cart_to_remove = 1 THEN 1 END) AS explicit_abandon_sessions,
    COUNT(CASE WHEN implicit_abandon = 1 THEN 1 END) AS implicit_abandon_sessions,
	ROUND(COUNT(CASE WHEN cart_to_purchase = 1 THEN 1 END) * 100.0 / COUNT(CASE WHEN has_cart = 1 THEN 1 END), 2) AS cart_to_purchase_rate,    
	ROUND(COUNT(CASE WHEN cart_to_remove = 1 THEN 1 END) * 100.0 / COUNT(CASE WHEN has_cart = 1 THEN 1 END), 2) AS explicit_abandon_rate,
	ROUND(COUNT(CASE WHEN implicit_abandon = 1 THEN 1 END) * 100.0 / COUNT(CASE WHEN has_cart = 1 THEN 1 END), 2) AS implicit_abandon_rate,
    ROUND((COUNT(CASE WHEN cart_to_remove = 1 THEN 1 END) + COUNT(CASE WHEN implicit_abandon = 1 THEN 1 END)) * 100.0 / COUNT(CASE WHEN has_cart = 1 THEN 1 END), 2) AS total_abandon_rate
FROM session_funnel
GROUP BY price_group
ORDER BY FIELD(price_group, 'low', 'mid', 'high');

-- 상품 단위 분석
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
			WHEN price < 1.05 THEN 'low'
            WHEN price >= 1.05 AND price < 6.83 THEN 'mid'
			WHEN price >= 6.83 THEN 'high'
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

-- 브랜드 인지도별 이탈률 분석
-- 브랜드 인지도 구간
WITH brand_cart_counts AS (
	SELECT
		brand,
		COUNT(*) AS cart_cnt
	FROM cosmetics
	WHERE event_type = 'cart'
		AND brand IS NOT NULL
	GROUP BY brand
),
brand_ranks AS (
	SELECT
		brand,
        cart_cnt,
        ROW_NUMBER() OVER (ORDER BY cart_cnt) AS row_num,
        COUNT(*) OVER () AS total_rows
	FROM brand_cart_counts
)
SELECT
	MAX(CASE WHEN row_num = FLOOR(0.25 * total_rows) THEN cart_cnt END) AS Q1, 
    MAX(CASE WHEN row_num = FLOOR(0.50 * total_rows) THEN cart_cnt END) AS Q2,
    MAX(CASE WHEN row_num = FLOOR(0.75 * total_rows) THEN cart_cnt END) AS Q3
FROM brand_ranks;

WITH product_events AS (
	SELECT
		user_id,
        user_session,
        product_id,
        brand,
        MIN(CASE WHEN event_type = 'cart' THEN event_time END) AS cart_at,
        MIN(CASE WHEN event_type = 'remove_from_cart' THEN event_time END) AS remove_at,
        MIN(CASE WHEN event_type = 'purchase' THEN event_time END) AS purchase_at
	FROM cosmetics
    WHERE brand IS NOT NULL
    GROUP BY user_id, user_session, product_id, brand
),
brand_counts AS (
	SELECT
		brand,
        COUNT(*) AS cart_cnt
	FROM cosmetics
    WHERE event_type = 'cart'
		AND brand IS NOT NULL
	GROUP BY brand
),
session_funnel AS (
	SELECT
		p.user_id,
		p.user_session,
        p.product_id,
        p.brand,
		CASE WHEN p.cart_at IS NOT NULL THEN 1 ELSE 0 END AS has_cart,
		CASE
			WHEN p.cart_at IS NOT NULL
			AND p.purchase_at IS NOT NULL
			AND p.cart_at <= p.purchase_at
		THEN 1 ELSE 0 END AS cart_to_purchase,
		CASE
			WHEN p.cart_at IS NOT NULL
			AND p.remove_at IS NOT NULL
			AND p.purchase_at IS NULL
			AND p.cart_at <= p.remove_at
		THEN 1 ELSE 0 END AS cart_to_remove,
		CASE
			WHEN p.cart_at IS NOT NULL
			AND p.remove_at IS NULL
			AND p.purchase_at IS NULL
		THEN 1 ELSE 0 END AS implicit_abandon,
        CASE
			WHEN b.cart_cnt < 145 THEN 'low'
            WHEN b.cart_cnt >= 145 AND b.cart_cnt < 3178 THEN 'mid'
            WHEN b.cart_cnt >= 3178 THEN 'high'
		END AS brand_group
	FROM product_events AS p
    JOIN brand_counts AS b ON p.brand = b.brand
)
SELECT
	brand_group,
    COUNT(CASE WHEN has_cart = 1 THEN 1 END) AS cart_brands,
    COUNT(CASE WHEN cart_to_purchase = 1 THEN 1 END) AS purchase_brands,
	COUNT(CASE WHEN cart_to_remove = 1 THEN 1 END) AS explicit_abandon_brands,
    COUNT(CASE WHEN implicit_abandon = 1 THEN 1 END) AS implicit_abandon_brands,
	ROUND(COUNT(CASE WHEN cart_to_purchase = 1 THEN 1 END) * 100.0 / COUNT(CASE WHEN has_cart = 1 THEN 1 END), 2) AS cart_to_purchase_rate,    
	ROUND(COUNT(CASE WHEN cart_to_remove = 1 THEN 1 END) * 100.0 / COUNT(CASE WHEN has_cart = 1 THEN 1 END), 2) AS explicit_abandon_rate,
	ROUND(COUNT(CASE WHEN implicit_abandon = 1 THEN 1 END) * 100.0 / COUNT(CASE WHEN has_cart = 1 THEN 1 END), 2) AS implicit_abandon_rate
FROM session_funnel
GROUP BY brand_group
ORDER BY FIELD(brand_group, 'low', 'mid', 'high');    

-- 브랜드 인지도 구간 재설정 (view + cart)
WITH base AS (
  SELECT
    brand,
    COUNT(CASE WHEN event_type = 'view' THEN 1 END) AS view_cnt,
    COUNT(CASE WHEN event_type = 'cart' THEN 1 END) AS cart_cnt
  FROM cosmetics
  WHERE brand != ''
  GROUP BY brand
),
min_max AS (
  SELECT
    MIN(view_cnt) AS min_view,
    MAX(view_cnt) AS max_view,
    MIN(cart_cnt) AS min_cart,
    MAX(cart_cnt) AS max_cart
  FROM base
),
normalized AS (
  SELECT
    b.brand,
    b.view_cnt,
    b.cart_cnt,
    -- Min-Max 정규화
    (b.view_cnt - m.min_view) / NULLIF(m.max_view - m.min_view, 0) AS norm_view,
    (b.cart_cnt - m.min_cart) / NULLIF(m.max_cart - m.min_cart, 0) AS norm_cart
  FROM base b
  CROSS JOIN min_max m
)
SELECT
  brand,
  view_cnt,
  cart_cnt,
  ROUND(norm_view, 4) AS norm_view,
  ROUND(norm_cart, 4) AS norm_cart,
  -- 혼합 인지도 점수: View 0.11 + Cart 0.89
  ROUND(0.11 * norm_view + 0.89 * norm_cart, 4) AS brand_score
FROM normalized
ORDER BY brand_score DESC;

WITH base AS (
  SELECT
    brand,
    COUNT(CASE WHEN event_type = 'view' THEN 1 END) AS view_cnt,
    COUNT(CASE WHEN event_type = 'cart' THEN 1 END) AS cart_cnt
  FROM cosmetics
  WHERE brand != ''
  GROUP BY brand
),
min_max AS (
  SELECT
    MIN(view_cnt) AS min_view,
    MAX(view_cnt) AS max_view,
    MIN(cart_cnt) AS min_cart,
    MAX(cart_cnt) AS max_cart
  FROM base
),
normalized AS (
  SELECT
    b.brand,
    b.view_cnt,
    b.cart_cnt,
    (b.view_cnt - m.min_view) / NULLIF(m.max_view - m.min_view, 0) AS norm_view,
    (b.cart_cnt - m.min_cart) / NULLIF(m.max_cart - m.min_cart, 0) AS norm_cart,
    (0.11 * ((b.view_cnt - m.min_view) / NULLIF(m.max_view - m.min_view, 0)) +
     0.89 * ((b.cart_cnt - m.min_cart) / NULLIF(m.max_cart - m.min_cart, 0))) AS brand_score
  FROM base b
  CROSS JOIN min_max m
),
ranked AS (
  SELECT *,
         NTILE(3) OVER (ORDER BY brand_score) AS score_group
  FROM normalized
)
SELECT
  brand,
  view_cnt,
  cart_cnt,
  ROUND(norm_view, 4) AS norm_view,
  ROUND(norm_cart, 4) AS norm_cart,
  ROUND(brand_score, 4) AS brand_score,
  CASE
    WHEN score_group = 1 THEN 'low'
    WHEN score_group = 2 THEN 'mid'
    WHEN score_group = 3 THEN 'high'
  END AS brand_group
FROM ranked
ORDER BY brand_score DESC;


-- 시간/요일대별 분석
WITH session_events AS (
	SELECT
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
		user_id,
        user_session,
        DAYOFWEEK(cart_at) AS weekday,
        HOUR(cart_at) AS hour,
        CASE WHEN cart_at IS NOT NULL THEN 1 ELSE 0 END AS has_cart,
        CASE WHEN
			cart_at IS NOT NULL
            AND purchase_at IS NOT NULL
            AND cart_at <= purchase_at
		THEN 1 ELSE 0 END AS cart_to_purchase,
        CASE WHEN
			cart_at IS NOT NULL
            AND remove_at IS NOT NULL
            AND purchase_at IS NULL
            AND cart_at <= remove_at
		THEN 1 ELSE 0 END AS cart_to_remove,
        CASE WHEN
			cart_at IS NOT NULL
            AND remove_at IS NULL
            AND purchase_at IS NULL
		THEN 1 ELSE 0 END AS implicit_abandon
	FROM session_events
    WHERE cart_at IS NOT NULL
)
SELECT
	weekday,
    hour,
    COUNT(CASE WHEN has_cart = 1 THEN 1 END) AS cart_sessions,
    COUNT(CASE WHEN cart_to_purchase = 1 THEN 1 END) AS purchase_sessions,
    COUNT(CASE WHEN cart_to_remove = 1 THEN 1 END) AS explicit_abandon_sessions,
    COUNT(CASE WHEN implicit_abandon = 1 THEN 1 END) AS implicit_abandon_sessions,
    ROUND(COUNT(CASE WHEN cart_to_purchase = 1 THEN 1 END) * 100.0 / COUNT(CASE WHEN has_cart = 1 THEN 1 END), 2) AS cart_to_purchase_rate,
    ROUND(COUNT(CASE WHEN cart_to_remove = 1 THEN 1 END) * 100.0 / COUNT(CASE WHEN has_cart = 1 THEN 1 END), 2) AS explicit_abandon_rate,
    ROUND(COUNT(CASE WHEN implicit_abandon = 1 THEN 1 END) * 100.0 / COUNT(CASE WHEN has_cart = 1 THEN 1 END), 2) AS implicit_abandon_rate
FROM session_funnel
GROUP BY weekday, hour
ORDER BY weekday, hour;

WITH session_events AS (
	SELECT
		user_id,
        user_session,
        MIN(CASE WHEN event_type = 'cart' THEN event_time END) AS cart_at,
        MIN(CASE WHEN event_type = 'remove_from_cart' THEN event_time END) AS remove_at,
        MIN(CASE WHEN event_type = 'purchase' THEN event_time END) AS purchase_at
	FROM cosmetics
    GROUP BY user_id, user_session
),
session_times AS (
	SELECT
		user_id,
        user_session,
        DAYOFWEEK(cart_at) AS weekday,
        HOUR(cart_at) AS hour,
		cart_at,
        remove_at,
        purchase_at
	FROM session_events
    WHERE cart_at IS NOT NULL
),
session_funnel AS (
	SELECT
		user_id,
        user_session,
        CASE
			WHEN weekday IN (2,3,4,5,6) THEN '평일'
            WHEN weekday IN (1,7) THEN '주말'
		END AS day_group,
        HOUR(cart_at) AS hour,
        CASE WHEN cart_at IS NOT NULL THEN 1 ELSE 0 END AS has_cart,
        CASE WHEN
			cart_at IS NOT NULL
            AND purchase_at IS NOT NULL
            AND cart_at <= purchase_at
		THEN 1 ELSE 0 END AS cart_to_purchase,
        CASE WHEN
			cart_at IS NOT NULL
            AND remove_at IS NOT NULL
            AND purchase_at IS NULL
            AND cart_at <= remove_at
		THEN 1 ELSE 0 END AS cart_to_remove,
        CASE WHEN
			cart_at IS NOT NULL
            AND remove_at IS NULL
            AND purchase_at IS NULL
		THEN 1 ELSE 0 END AS implicit_abandon
	FROM session_times
    WHERE cart_at IS NOT NULL
)
SELECT
	day_group,
    hour,
    COUNT(CASE WHEN has_cart = 1 THEN 1 END) AS cart_sessions,
    COUNT(CASE WHEN cart_to_purchase = 1 THEN 1 END) AS purchase_sessions,
    COUNT(CASE WHEN cart_to_remove = 1 THEN 1 END) AS explicit_abandon_sessions,
    COUNT(CASE WHEN implicit_abandon = 1 THEN 1 END) AS implicit_abandon_sessions,
    ROUND(COUNT(CASE WHEN cart_to_purchase = 1 THEN 1 END) * 100.0 / COUNT(CASE WHEN has_cart = 1 THEN 1 END), 2) AS cart_to_purchase_rate,
    ROUND(COUNT(CASE WHEN cart_to_remove = 1 THEN 1 END) * 100.0 / COUNT(CASE WHEN has_cart = 1 THEN 1 END), 2) AS explicit_abandon_rate,
    ROUND(COUNT(CASE WHEN implicit_abandon = 1 THEN 1 END) * 100.0 / COUNT(CASE WHEN has_cart = 1 THEN 1 END), 2) AS implicit_abandon_rate
FROM session_funnel
GROUP BY day_group, hour
ORDER BY day_group, hour;