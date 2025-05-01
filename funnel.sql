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