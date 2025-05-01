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