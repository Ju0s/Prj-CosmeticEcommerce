-- 장바구니 이탈 원인 분석: 가격대
WITH product_events AS (
  SELECT
    user_id,
    user_session,
    product_id,
    price,
    MAX(CASE WHEN event_type = 'cart' THEN 1 ELSE 0 END) AS has_cart,
    MAX(CASE WHEN event_type = 'purchase' THEN 1 ELSE 0 END) AS has_purchase,
    MAX(CASE WHEN event_type = 'remove_from_cart' THEN 1 ELSE 0 END) AS has_remove
  FROM cosmetics
  WHERE price IS NOT NULL
  GROUP BY user_id, user_session, product_id, price
)
SELECT
  price,
  user_id,
  user_session,
  product_id,
  has_cart,
  has_purchase,
  has_remove,
  CASE
    WHEN has_cart = 1 AND has_purchase = 1 THEN 'purchase'
    WHEN has_cart = 1 AND has_remove = 1 AND has_purchase = 0 THEN 'explicit_abandon'
    WHEN has_cart = 1 AND has_remove = 0 AND has_purchase = 0 THEN 'implicit_abandon'
  END AS cart_status
FROM product_events
WHERE has_cart = 1;
