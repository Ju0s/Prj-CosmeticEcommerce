-- 구매 퍼널 분석
-- 이벤트별 고객 수
SELECT 
    event_type, 
    COUNT(DISTINCT user_id) AS user_count
FROM cosmetics
WHERE event_type IN ('view', 'cart', 'remove_from_cart', 'purchase')
GROUP BY event_type
ORDER BY FIELD(event_type, 'view', 'cart', 'remove_from_cart', 'purchase');

-- 퍼널 단계별 전환율
WITH funnel AS (
    SELECT 
        COUNT(DISTINCT CASE WHEN event_type = 'view' THEN user_id END) AS view_users,
        COUNT(DISTINCT CASE WHEN event_type = 'cart' THEN user_id END) AS cart_users,
        COUNT(DISTINCT CASE WHEN event_type = 'remove_from_cart' THEN user_id END) AS remove_from_cart_users,
        COUNT(DISTINCT CASE WHEN event_type = 'purchase' THEN user_id END) AS purchase_users
    FROM cosmetics
)
SELECT 
    ROUND(cart_users / view_users * 100, 2) AS view_to_cart_rate,
    ROUND(remove_from_cart_users / cart_users * 100, 2) AS cart_to_remove_rate,
    ROUND(purchase_users / cart_users * 100, 2) AS cart_to_purchase_rate,
    ROUND(remove_from_cart_users / view_users * 100, 2) AS view_to_remove_rate,
    ROUND(purchase_users / view_users * 100, 2) AS view_to_purchase_rate
FROM funnel;

WITH funnel AS (
    SELECT 
        event_type,
        COUNT(DISTINCT user_id) AS user_count
    FROM cosmetics
    WHERE event_type IN ('view', 'cart', 'purchase')
    GROUP BY event_type
)
SELECT 
    event_type, 
    user_count,
    LAG(user_count) OVER (ORDER BY FIELD(event_type, 'view', 'cart', 'purchase')) AS previous_step_count,
    ROUND((user_count / LAG(user_count) OVER (ORDER BY FIELD(event_type, 'view', 'cart', 'purchase'))) * 100, 2) AS conversion_rate
FROM funnel;

-- 브랜드별 장바구니 추가 전환율
WITH brand_prices AS (
	SELECT
		brand,
        product_id,
        price
	FROM cosmetics
    GROUP BY brand, product_id, price
),
brand_avg_prices AS (
	SELECT
		brand,
        avg(price) AS avg_price
	FROM brand_prices
    GROUP BY brand
),
brand_session_durations AS (
    SELECT 
        user_id,
        user_session,
        brand,
        TIMESTAMPDIFF(MINUTE, MIN(event_time), MAX(event_time)) AS session_duration
    FROM cosmetics
    GROUP BY user_id, user_session, brand
),
brand_avg_session_durations AS (
	SELECT
		brand,
        AVG(session_duration) AS avg_session_duration
	FROM brand_session_durations
    GROUP BY brand
),
brand_funnel AS (
    SELECT
		brand,
        COUNT(DISTINCT user_id) AS customers,
        COUNT(DISTINCT CASE WHEN event_type = 'view' THEN user_id END) AS view_users,
        COUNT(DISTINCT CASE WHEN event_type = 'cart' THEN user_id END) AS cart_users
    FROM cosmetics
    WHERE brand IS NOT NULL
    GROUP BY brand
)
SELECT 
	f.brand,
    f.customers,
	p.avg_price,
	s.avg_session_duration,
    f.view_users,
    f.cart_users,
    ROUND((f.cart_users / f.view_users) * 100, 2) AS cart_conversion_rate
FROM brand_funnel AS f
JOIN brand_avg_prices AS p ON f.brand = p.brand
JOIN brand_avg_session_durations AS s ON f.brand = s.brand
ORDER BY cart_conversion_rate;

-- 가격대 구간
WITH price_ranked AS (
    SELECT
		product_id,
		price,
		ROW_NUMBER() OVER (ORDER BY price) AS row_num,
		COUNT(*) OVER () AS total_rows
    FROM cosmetics
    WHERE price IS NOT NULL
    GROUP BY product_id, price
)
SELECT 
    MAX(CASE WHEN row_num = FLOOR(0.25 * total_rows) THEN price END) AS Q1,
    MAX(CASE WHEN row_num = FLOOR(0.50 * total_rows) THEN price END) AS Q2,
    MAX(CASE WHEN row_num = FLOOR(0.75 * total_rows) THEN price END) AS Q3
FROM price_ranked;

-- 제품 가격대별 장바구니 추가 전환율
WITH price_funnel AS (
    SELECT 
        CASE 
            WHEN price < 0.79 THEN 'low'
            WHEN price >= 0.79 AND price < 3.84 THEN 'mid'
            WHEN price >= 3.84 AND price < 6.97 THEN 'high'
            ELSE 'premium'
        END AS price_range,
        COUNT(DISTINCT CASE WHEN event_type = 'view' THEN user_id END) AS view_users,
        COUNT(DISTINCT CASE WHEN event_type = 'cart' THEN user_id END) AS cart_users
    FROM cosmetics
    GROUP BY price_range
)
SELECT 
    price_range,
    view_users,
    cart_users,
    NULLIF(ROUND((cart_users / view_users) * 100, 2), 0) AS cart_conversion_rate
FROM price_funnel
ORDER BY cart_conversion_rate;

WITH price_funnel AS (
    SELECT 
        price,
        COUNT(DISTINCT CASE WHEN event_type = 'view' THEN user_id END) AS view_users,
        COUNT(DISTINCT CASE WHEN event_type = 'cart' THEN user_id END) AS cart_users
    FROM cosmetics
    GROUP BY price
)
SELECT 
    price,
    view_users,
    cart_users,
    ROUND((cart_users / view_users) * 100, 2) AS cart_conversion_rate
FROM price_funnel
ORDER BY cart_conversion_rate;

-- view 세션 유지 시간 구간
WITH event_sequence AS (
    SELECT 
        user_id,
        user_session,
        product_id,
        event_type,
        event_time,
        LEAD(event_time) OVER (
            PARTITION BY user_id, user_session, product_id 
            ORDER BY event_time
        ) AS next_event_time
    FROM cosmetics
),
view_duration AS (
    SELECT 
        user_id,
        user_session,
        product_id,
        TIMESTAMPDIFF(SECOND, event_time, next_event_time) AS view_time
    FROM event_sequence
    WHERE event_type = 'view'
),
view_duration_ranked AS (
    SELECT
        user_id,
        user_session,
        product_id,
        view_time,
		ROW_NUMBER() OVER (ORDER BY view_time) AS row_num,
		COUNT(*) OVER () AS total_rows
    FROM view_duration
    WHERE view_time IS NOT NULL
    GROUP BY user_id, user_session, product_id, view_time
)
SELECT 
    MAX(CASE WHEN row_num = FLOOR(0.25 * total_rows) THEN view_time END) AS Q1,
    MAX(CASE WHEN row_num = FLOOR(0.50 * total_rows) THEN view_time END) AS Q2,
    MAX(CASE WHEN row_num = FLOOR(0.75 * total_rows) THEN view_time END) AS Q3
FROM view_duration_ranked;

WITH event_sequence AS (
    SELECT 
        user_id,
        user_session,
        product_id,
        event_type,
        event_time,
        LEAD(event_time) OVER (
            PARTITION BY user_id, user_session
            ORDER BY event_time
        ) AS next_event_time
    FROM cosmetics
),
view_duration AS (
    SELECT 
        user_id,
        user_session,
        product_id,
        TIMESTAMPDIFF(SECOND, event_time, next_event_time) AS view_time
    FROM event_sequence
    WHERE event_type = 'view'
),
view_duration_ranked AS (
    SELECT
        user_id,
        user_session,
        product_id,
        view_time,
		ROW_NUMBER() OVER (ORDER BY view_time) AS row_num,
		COUNT(*) OVER () AS total_rows
    FROM view_duration
    WHERE view_time IS NOT NULL
)
SELECT 
    MAX(CASE WHEN row_num = FLOOR(0.25 * total_rows) THEN view_time END) AS Q1,
    MAX(CASE WHEN row_num = FLOOR(0.50 * total_rows) THEN view_time END) AS Q2,
    MAX(CASE WHEN row_num = FLOOR(0.75 * total_rows) THEN view_time END) AS Q3
FROM view_duration_ranked;


-- 페이지 조회 시간별 장바구니 추가 전환율
WITH event_sequence AS (
    SELECT 
        user_id,
        user_session,
        product_id,
        event_type,
        event_time,
        LEAD(event_time) OVER (
            PARTITION BY user_id, user_session, product_id 
            ORDER BY event_time
        ) AS next_event_time
    FROM cosmetics
),
view_duration AS (
    SELECT 
        user_id,
        user_session,
        product_id,
        TIMESTAMPDIFF(SECOND, event_time, next_event_time) AS view_time
    FROM event_sequence
    WHERE event_type = 'view'
),
categorized_view_time AS (
    SELECT 
        user_id,
        user_session,
        product_id,
        CASE 
            WHEN view_time <= 20 THEN 'short'
            WHEN view_time > 20 AND view_time <= 55 THEN 'mid'
            WHEN view_time > 55 AND view_time <= 214 THEN 'long'
            ELSE 'very long'
        END AS view_time_category
    FROM view_duration
),
conversion_data AS (
    SELECT 
        cvt.view_time_category,
        COUNT(DISTINCT CASE WHEN c.event_type = 'view' THEN c.user_id END) AS view_sessions,
        COUNT(DISTINCT CASE WHEN c.event_type = 'cart' THEN c.user_id END) AS cart_sessions
    FROM cosmetics AS c
    JOIN categorized_view_time AS cvt
    ON c.user_id = cvt.user_id
    AND c.user_session = cvt.user_session
    AND c.product_id = cvt.product_id
    GROUP BY cvt.view_time_category
)
SELECT 
    view_time_category,
    view_sessions,
    cart_sessions,
    NULLIF(ROUND((cart_sessions / view_sessions) * 100, 2), 0) AS cart_conversion_rate
FROM conversion_data
ORDER BY view_time_category;

WITH event_sequence AS (
    SELECT 
        user_id,
        user_session,
        product_id,
        event_type,
        event_time,
        LEAD(event_time) OVER (
            PARTITION BY user_id, user_session
            ORDER BY event_time
        ) AS next_event_time
    FROM cosmetics
),
view_duration AS (
    SELECT 
        user_id,
        user_session,
        product_id,
        TIMESTAMPDIFF(SECOND, event_time, next_event_time) AS view_time
    FROM event_sequence
    WHERE event_type = 'view'
),
categorized_view_time AS (
    SELECT 
        user_id,
        user_session,
        product_id,
        CASE 
            WHEN view_time <= 19 THEN 'short'
            WHEN view_time > 19 AND view_time <= 42 THEN 'mid'
            WHEN view_time > 42 AND view_time <= 102 THEN 'long'
            ELSE 'very long'
        END AS view_time_category
    FROM view_duration
),
conversion_data AS (
    SELECT 
        cvt.view_time_category,
        COUNT(DISTINCT CASE WHEN c.event_type = 'view' THEN c.user_id END) AS view_sessions,
        COUNT(DISTINCT CASE WHEN c.event_type = 'cart' THEN c.user_id END) AS cart_sessions
    FROM cosmetics AS c
    JOIN categorized_view_time AS cvt
    ON c.user_id = cvt.user_id
    AND c.user_session = cvt.user_session
    AND c.product_id = cvt.product_id
    GROUP BY cvt.view_time_category
)
SELECT 
    view_time_category,
    view_sessions,
    cart_sessions,
    NULLIF(ROUND((cart_sessions / view_sessions) * 100, 2), 0) AS cart_conversion_rate
FROM conversion_data
ORDER BY view_time_category;

-- 가격별 평균 페이지 조회 시간
WITH event_sequence AS (
    SELECT 
        user_id,
        user_session,
        product_id,
        price,
        event_type,
        event_time,
        LEAD(event_time) OVER (
            PARTITION BY user_id, user_session, product_id 
            ORDER BY event_time
        ) AS next_event_time
    FROM cosmetics
),
view_duration AS (
    SELECT 
        user_id,
        user_session,
        product_id,
        price,
        TIMESTAMPDIFF(SECOND, event_time, next_event_time) AS view_time
    FROM event_sequence
    WHERE event_type = 'view'
)
SELECT
	price,
    AVG(view_time) AS avg_view_time
FROM view_duration
GROUP BY price
ORDER BY price;

-- 장바구니 이탈 분석
WITH cart_purchase AS (
    SELECT 
        user_id,
        COUNT(DISTINCT CASE WHEN event_type = 'cart' THEN product_id END) AS cart_items,
        COUNT(DISTINCT CASE WHEN event_type = 'purchase' THEN product_id END) AS purchased_items
    FROM cosmetics
    GROUP BY user_id
)
SELECT 
    COUNT(user_id) AS total_users,
    COUNT(CASE WHEN purchased_items = 0 THEN user_id END) AS abandoned_users,
    ROUND((COUNT(CASE WHEN purchased_items = 0 THEN user_id END) / COUNT(user_id)) * 100, 2) AS cart_abandonment_rate
FROM cart_purchase;

-- 가격대별 장바구니 이탈율
SELECT 
	CASE 
		WHEN price < 0.79 THEN 'low'
		WHEN price BETWEEN 0.79 AND 3.84 THEN 'mid'
		WHEN price BETWEEN 3.84 AND 6.97 THEN 'high'
		ELSE 'premium'
	END AS price_range,
    COUNT(DISTINCT CASE WHEN event_type = 'cart' THEN user_id END) AS cart_users,
    COUNT(DISTINCT CASE WHEN event_type = 'purchase' THEN user_id END) AS purchase_users,
    ROUND((1 - (COUNT(DISTINCT CASE WHEN event_type = 'purchase' THEN user_id END) / COUNT(DISTINCT CASE WHEN event_type = 'cart' THEN user_id END))) * 100, 2) AS cart_abandonment_rate
FROM cosmetics
GROUP BY price_range;


WITH price_funnel AS (
    SELECT 
        CASE 
            WHEN price < 0.79 THEN 'low'
            WHEN price BETWEEN 0.79 AND 3.84 THEN 'mid'
            WHEN price BETWEEN 3.84 AND 6.97 THEN 'high'
            ELSE 'premium'
        END AS price_range,
        COUNT(DISTINCT CASE WHEN event_type = 'view' THEN user_id END) AS view_users,
        COUNT(DISTINCT CASE WHEN event_type = 'cart' THEN user_id END) AS cart_users
    FROM cosmetics
    GROUP BY price_range
)
SELECT 
    price_range,
    view_users,
    cart_users,
    ROUND((cart_users / view_users) * 100, 2) AS cart_conversion_rate
FROM price_funnel
ORDER BY cart_conversion_rate;