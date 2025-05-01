-- 주차별 구매 리텐션 파악
WITH records_pre AS (
    SELECT user_id, 
           MIN(event_time) AS first_event_time,  -- 첫 방문 시간
           YEAR(MIN(event_time)) AS first_order_year,  -- 첫 방문 연도
           WEEK(MIN(event_time)) AS first_order_week  -- 첫 방문 주
    FROM cos_data
    WHERE event_type='purchase'
    GROUP BY user_id
)

SELECT 
    CONCAT(r.first_order_year, '-', LPAD(r.first_order_week, 2, '0')) AS first_order_week,  -- 연도-주 번호 형식으로 반환
    COUNT(DISTINCT r.user_id) AS week0,  -- 첫 구매 주
    COUNT(DISTINCT CASE WHEN WEEK(DATE_ADD(r.first_event_time, INTERVAL 1 WEEK)) = WEEK(t.event_time) AND YEAR(DATE_ADD(r.first_event_time, INTERVAL 1 WEEK)) = YEAR(t.event_time) THEN r.user_id END) AS week1,  -- 1주차 리텐션
    COUNT(DISTINCT CASE WHEN WEEK(DATE_ADD(r.first_event_time, INTERVAL 2 WEEK)) = WEEK(t.event_time) AND YEAR(DATE_ADD(r.first_event_time, INTERVAL 2 WEEK)) = YEAR(t.event_time) THEN r.user_id END) AS week2,  -- 2주차 리텐션
    COUNT(DISTINCT CASE WHEN WEEK(DATE_ADD(r.first_event_time, INTERVAL 3 WEEK)) = WEEK(t.event_time) AND YEAR(DATE_ADD(r.first_event_time, INTERVAL 3 WEEK)) = YEAR(t.event_time) THEN r.user_id END) AS week3,  -- 3주차 리텐션
    COUNT(DISTINCT CASE WHEN WEEK(DATE_ADD(r.first_event_time, INTERVAL 4 WEEK)) = WEEK(t.event_time) AND YEAR(DATE_ADD(r.first_event_time, INTERVAL 4 WEEK)) = YEAR(t.event_time) THEN r.user_id END) AS week4,  -- 4주차 리텐션
    COUNT(DISTINCT CASE WHEN WEEK(DATE_ADD(r.first_event_time, INTERVAL 5 WEEK)) = WEEK(t.event_time) AND YEAR(DATE_ADD(r.first_event_time, INTERVAL 5 WEEK)) = YEAR(t.event_time) THEN r.user_id END) AS week5,  -- 5주차 리텐션
    COUNT(DISTINCT CASE WHEN WEEK(DATE_ADD(r.first_event_time, INTERVAL 6 WEEK)) = WEEK(t.event_time) AND YEAR(DATE_ADD(r.first_event_time, INTERVAL 6 WEEK)) = YEAR(t.event_time) THEN r.user_id END) AS week6,  -- 6주차 리텐션
    COUNT(DISTINCT CASE WHEN WEEK(DATE_ADD(r.first_event_time, INTERVAL 7 WEEK)) = WEEK(t.event_time) AND YEAR(DATE_ADD(r.first_event_time, INTERVAL 7 WEEK)) = YEAR(t.event_time) THEN r.user_id END) AS week7,  -- 7주차 리텐션
    COUNT(DISTINCT CASE WHEN WEEK(DATE_ADD(r.first_event_time, INTERVAL 8 WEEK)) = WEEK(t.event_time) AND YEAR(DATE_ADD(r.first_event_time, INTERVAL 8 WEEK)) = YEAR(t.event_time) THEN r.user_id END) AS week8,  -- 8주차 리텐션
    COUNT(DISTINCT CASE WHEN WEEK(DATE_ADD(r.first_event_time, INTERVAL 9 WEEK)) = WEEK(t.event_time) AND YEAR(DATE_ADD(r.first_event_time, INTERVAL 9 WEEK)) = YEAR(t.event_time) THEN r.user_id END) AS week9,  -- 9주차 리텐션
    COUNT(DISTINCT CASE WHEN WEEK(DATE_ADD(r.first_event_time, INTERVAL 10 WEEK)) = WEEK(t.event_time) AND YEAR(DATE_ADD(r.first_event_time, INTERVAL 10 WEEK)) = YEAR(t.event_time) THEN r.user_id END) AS week10,  -- 10주차 리텐션
    COUNT(DISTINCT CASE WHEN WEEK(DATE_ADD(r.first_event_time, INTERVAL 11 WEEK)) = WEEK(t.event_time) AND YEAR(DATE_ADD(r.first_event_time, INTERVAL 11 WEEK)) = YEAR(t.event_time) THEN r.user_id END) AS week11,
    COUNT(DISTINCT CASE WHEN WEEK(DATE_ADD(r.first_event_time, INTERVAL 12 WEEK)) = WEEK(t.event_time) AND YEAR(DATE_ADD(r.first_event_time, INTERVAL 12 WEEK)) = YEAR(t.event_time) THEN r.user_id END) AS week12,
    COUNT(DISTINCT CASE WHEN WEEK(DATE_ADD(r.first_event_time, INTERVAL 13 WEEK)) = WEEK(t.event_time) AND YEAR(DATE_ADD(r.first_event_time, INTERVAL 13 WEEK)) = YEAR(t.event_time) THEN r.user_id END) AS week13,
    COUNT(DISTINCT CASE WHEN WEEK(DATE_ADD(r.first_event_time, INTERVAL 14 WEEK)) = WEEK(t.event_time) AND YEAR(DATE_ADD(r.first_event_time, INTERVAL 14 WEEK)) = YEAR(t.event_time) THEN r.user_id END) AS week14
FROM 
    records_pre r
JOIN cos_data t ON r.user_id = t.user_id
GROUP BY 
    r.first_order_year, r.first_order_week;
    
-- 2주 리텐션
WITH records_pre AS (
    SELECT user_id
	, MIN(event_time) AS first_event_time
      , YEAR(MIN(event_time)) AS first_order_year
      , WEEK(MIN(event_time)) AS first_order_week
    FROM cos_data
    WHERE event_type = 'purchase'
    GROUP BY user_id
)

SELECT 
    CONCAT(r.first_order_year, '-', LPAD(r.first_order_week, 2, '0')) AS first_order_week, 
    COUNT(DISTINCT r.user_id) AS week0,
    COUNT(DISTINCT CASE WHEN WEEK(DATE_ADD(r.first_event_time, INTERVAL 2 WEEK)) = WEEK(t.event_time) AND YEAR(DATE_ADD(r.first_event_time, INTERVAL 2 WEEK)) = YEAR(t.event_time) THEN r.user_id END) AS week2, 
    COUNT(DISTINCT CASE WHEN WEEK(DATE_ADD(r.first_event_time, INTERVAL 4 WEEK)) = WEEK(t.event_time) AND YEAR(DATE_ADD(r.first_event_time, INTERVAL 4 WEEK)) = YEAR(t.event_time) THEN r.user_id END) AS week4, 
    COUNT(DISTINCT CASE WHEN WEEK(DATE_ADD(r.first_event_time, INTERVAL 6 WEEK)) = WEEK(t.event_time) AND YEAR(DATE_ADD(r.first_event_time, INTERVAL 6 WEEK)) = YEAR(t.event_time) THEN r.user_id END) AS week6, 
    COUNT(DISTINCT CASE WHEN WEEK(DATE_ADD(r.first_event_time, INTERVAL 8 WEEK)) = WEEK(t.event_time) AND YEAR(DATE_ADD(r.first_event_time, INTERVAL 8 WEEK)) = YEAR(t.event_time) THEN r.user_id END) AS week8, 
    COUNT(DISTINCT CASE WHEN WEEK(DATE_ADD(r.first_event_time, INTERVAL 10 WEEK)) = WEEK(t.event_time) AND YEAR(DATE_ADD(r.first_event_time, INTERVAL 10 WEEK)) = YEAR(t.event_time) THEN r.user_id END) AS week10, 
    COUNT(DISTINCT CASE WHEN WEEK(DATE_ADD(r.first_event_time, INTERVAL 12 WEEK)) = WEEK(t.event_time) AND YEAR(DATE_ADD(r.first_event_time, INTERVAL 12 WEEK)) = YEAR(t.event_time) THEN r.user_id END) AS week12
FROM records_pre r
JOIN cos_data t ON r.user_id = t.user_id
GROUP BY r.first_order_year, r.first_order_week;

-- 한 달 리텐션
WITH records_pre AS (
    SELECT user_id
	   , MIN(event_time) AS first_event_time
         , YEAR(MIN(event_time)) AS first_order_year
         , MONTH(MIN(event_time)) AS first_order_month
    FROM cos_data
    WHERE event_type = 'purchase'
    GROUP BY user_id
)

SELECT 
    CONCAT(r.first_order_year, '-', LPAD(r.first_order_month, 2, '0')) AS first_order_month,
    COUNT(DISTINCT r.user_id) AS month0,  -- 첫 구매 월
    COUNT(DISTINCT CASE WHEN MONTH(DATE_ADD(r.first_event_time, INTERVAL 1 MONTH)) = MONTH(t.event_time) AND YEAR(DATE_ADD(r.first_event_time, INTERVAL 1 MONTH)) = YEAR(t.event_time) THEN r.user_id END) AS month1, 
    COUNT(DISTINCT CASE WHEN MONTH(DATE_ADD(r.first_event_time, INTERVAL 2 MONTH)) = MONTH(t.event_time) AND YEAR(DATE_ADD(r.first_event_time, INTERVAL 2 MONTH)) = YEAR(t.event_time) THEN r.user_id END) AS month2
FROM records_pre r
JOIN cos_data t ON r.user_id = t.user_id
GROUP BY r.first_order_year, r.first_order_month;

-- 구매 고객 중 재구매 고객 분포
WITH re AS (
    SELECT 
        user_id,
        COUNT(DISTINCT DATE_FORMAT(event_time, '%Y-%m-%d')) AS purchase_count -- 구매 일자로 카운트
    FROM ecommerce
    WHERE event_type = 'purchase' AND price >= 0
    GROUP BY user_id
)

, raw1 AS (
    SELECT 
        t1.*,
        CASE 
            WHEN t2.purchase_count = 1 THEN '일회 구매 고객'  
            WHEN t2.purchase_count >= 2 THEN '재구매 고객' 
		ELSE '미구매 고객'  -- 구매하지 않은 경우
        END AS customer_type
    FROM ecommerce t1
    LEFT JOIN re t2 
		   ON t1.user_id = t2.user_id
)

SELECT 
    /* DATE_FORMAT(event_time,'%Y-%m') AS month, */
    customer_type, 
    COUNT(DISTINCT user_id) AS user_count
FROM raw1
GROUP BY customer_type
ORDER BY customer_type;

-- 구매 횟수 별 일평균 인당액
WITH re AS (
    SELECT 
        user_id,
        COUNT(DISTINCT DATE_FORMAT(event_time, '%Y-%m-%d')) AS purchase_count 
    FROM ecommerce
    WHERE (event_type = 'purchase' AND price >= 0)
    GROUP BY user_id
)

, raw1 AS (
    SELECT 
        user_id,
        purchase_count,
        CASE 
            WHEN purchase_count >= 5 THEN '1.5회 이상 구매'
            WHEN purchase_count = 4 THEN '2.4회 구매'
            WHEN purchase_count = 3 THEN '3.3회 구매'
            WHEN purchase_count = 2 THEN '4.2회 구매'
            WHEN purchase_count = 1 THEN '5.1회 구매'
		ELSE '미구매 고객'
        END AS category
    FROM re
)


, raw2 AS (
    SELECT 
        e.user_id, 
        c.category,
        DATE_FORMAT(e.event_time, '%Y-%m-%d') AS purchase_date, -- 한 번 구매 = distinct 기준일자
        SUM(e.price) AS spent_day  
    FROM ecommerce e
    JOIN raw1 c 
	  ON e.user_id = c.user_id
    WHERE (e.event_type = 'purchase' AND e.price >= 0)
    GROUP BY e.user_id, 
			 c.category, 
             purchase_date
)

SELECT 
    category,
    COUNT(DISTINCT user_id) AS user_count,  
    ROUND(AVG(spent_day), 2) AS avg_order_value 
FROM raw2
GROUP BY category
ORDER BY category;

-- 고객 세그먼트별 구매액
WITH user_purchase AS (
  SELECT 
    user_id,
    COUNT(DISTINCT DATE_FORMAT(event_time, '%Y-%m-%d')) AS purchase_count, -- 같은 날 중복 제외
    SUM(price) AS total_spent
  FROM cos_data
  WHERE event_type = 'purchase'
  GROUP BY user_id
),

segmentation AS (
  SELECT 
    user_id,
    CASE 
      WHEN purchase_count >= 10 THEN 'VIP 고객'
      WHEN purchase_count BETWEEN 5 AND 9 THEN '충성 고객'
      WHEN purchase_count BETWEEN 2 AND 4 THEN '재구매 고객'
      ELSE '일회 구매 고객'
    END AS customer_segment,
    total_spent
  FROM user_purchase
)

SELECT 
  customer_segment,
  COUNT(DISTINCT user_id) AS user_count,
  ROUND(AVG(total_spent), 2) AS avg_spent_per_user,
  ROUND(AVG(total_spent / purchase_count), 2) AS avg_spent_per_order
FROM segmentation
GROUP BY customer_segment
ORDER BY avg_spent_per_user DESC;

-- N회 구매자의 구매 주기 파악
WITH re AS (
    SELECT 
        user_id,
        COUNT(DISTINCT DATE_FORMAT(event_time, '%Y-%m-%d')) AS purchase_count
    FROM ecommerce
    WHERE event_type = 'purchase' AND price >= 0
    GROUP BY user_id
    HAVING purchase_count >= 2 
)

, purchase_dates AS (
    SELECT 
        user_id,
        DATE_FORMAT(event_time, '%Y-%m-%d') AS purchase_date
    FROM ecommerce
    WHERE event_type = 'purchase' AND price >= 0
      AND user_id IN (SELECT user_id FROM re)
)

, purchase_gaps AS (
    SELECT 
        p1.user_id,
        DATEDIFF(p2.purchase_date, p1.purchase_date) AS days_between_purchases
    FROM purchase_dates p1
    JOIN purchase_dates p2 
        ON p1.user_id = p2.user_id 
        AND p2.purchase_date > p1.purchase_date  
)

SELECT ROUND(AVG(days_between_purchases), 2) AS avg_repurchase_cycle 	-- 재구매자의 평균 구매 주기 (일단위)
FROM purchase_gaps;



-- 월별 재구매 주기 파악

WITH re AS (
    SELECT 
        user_id,
        COUNT(DISTINCT DATE_FORMAT(event_time, '%Y-%m-%d')) AS purchase_count
    FROM ecommerce
    WHERE event_type = 'purchase' AND price >= 0
--     AND DATE_FORMAT(event_time, '%Y-%m') = '2020-02'
    GROUP BY user_id
    HAVING purchase_count >= 2 
)

, purchase_dates AS (
    SELECT 
        user_id,
        DATE_FORMAT(event_time, '%Y-%m-%d') AS purchase_date
    FROM ecommerce
    WHERE event_type = 'purchase' AND price >= 0
--      AND DATE_FORMAT(event_time, '%Y-%m') = '2020-02'
      AND user_id IN (SELECT user_id FROM re)
)


SELECT 
    DATE_FORMAT(p1.purchase_date, '%Y-%m') AS month,
    ROUND(AVG(DATEDIFF(p2.purchase_date, p1.purchase_date)), 2) AS avg_repurchase_cycle
FROM purchase_dates p1
JOIN purchase_dates p2 
    ON p1.user_id = p2.user_id 
    AND p2.purchase_date > p1.purchase_date
GROUP BY month
ORDER BY month;

-- 고객 세그먼트별 사이트 내 구매 소요 시간
WITH re AS (
    SELECT 
        user_id,
        COUNT(DISTINCT DATE_FORMAT(event_time, '%Y-%m-%d')) AS purchase_count -- 구매 일자로 카운트
    FROM ecommerce
    WHERE event_type = 'purchase' AND price >= 0
    GROUP BY user_id
)

, raw1 AS (
    SELECT 
        t1.*,
        CASE 
            WHEN t2.purchase_count = 1 THEN '일회 구매 고객'  
            WHEN t2.purchase_count >= 2 THEN '재구매 고객' 
        END AS category
    FROM ecommerce t1
	JOIN re t2 
	  ON t1.user_id = t2.user_id
)


, session_events AS (
    SELECT 
        user_id,
        user_session,
        MIN(CASE WHEN event_type = 'view' THEN STR_TO_DATE(event_time, '%Y-%m-%d %H:%i:%s UTC') END) AS first_view_time,
        MIN(CASE WHEN event_type = 'cart' THEN STR_TO_DATE(event_time, '%Y-%m-%d %H:%i:%s UTC') END) AS first_cart_time,
        MIN(CASE WHEN event_type = 'purchase' THEN STR_TO_DATE(event_time, '%Y-%m-%d %H:%i:%s UTC') END) AS purchase_time
    FROM ecommerce
    WHERE event_type IN ('view', 'cart', 'purchase')
    GROUP BY user_id, user_session
),

time_differences AS (
    SELECT 
        user_id,
        user_session,
        TIMESTAMPDIFF(minute, first_view_time, purchase_time) AS view_to_purchase_minutes,
        TIMESTAMPDIFF(minute, first_cart_time, purchase_time) AS cart_to_purchase_minutes
    FROM session_events
    WHERE purchase_time IS NOT NULL 
)


SELECT 
    c.category,
    ROUND(AVG(td.view_to_purchase_minutes), 2) AS avg_view_to_purchase_minutes,
    ROUND(AVG(td.cart_to_purchase_minutes), 2) AS avg_cart_to_purchase_minutes
FROM time_differences td
JOIN raw1 c ON td.user_id = c.user_id
GROUP BY c.category;

-- 브랜드 별 재구매 현황
-- 재구매율
WITH user_purchase AS (
  SELECT 
    user_id,
    brand,
    COUNT(DISTINCT DATE_FORMAT(event_time, '%Y-%m-%d')) AS purchase_count -- 같은 날 중복 제외
  FROM cos_data
  WHERE event_type = 'purchase' AND brand IS NOT NULL
  GROUP BY user_id, brand
),

repurchase_users AS (
  SELECT 
    brand,
    COUNT(DISTINCT user_id) AS repurchase_users -- 재구매한 유저 수
  FROM user_purchase
  WHERE purchase_count >= 2
  GROUP BY brand
),

total_users AS (
  SELECT 
    brand,
    COUNT(DISTINCT user_id) AS total_users -- 해당 브랜드 구매한 전체 유저 수
  FROM user_purchase
  GROUP BY brand
)

SELECT 
  t.brand,
  t.total_users,
  r.repurchase_users,
  ROUND(r.repurchase_users / t.total_users * 100, 2) AS repurchase_rate -- 재구매 비율
FROM total_users t
LEFT JOIN repurchase_users r 
  ON t.brand = r.brand
HAVING t.total_users >= 1000
ORDER BY repurchase_rate DESC, repurchase_users DESC
LIMIT 11;

-- 2위에 브랜드 이름이 빈 데이터가 있어서 상위 11개 추출하고 해당 데이터는 제외


-- 브랜드 재구매 주기 수정
WITH purchase_log AS (
  SELECT 
    user_id,
    brand,
    DATE(event_time) AS purchase_date,
    LAG(DATE(event_time)) OVER (PARTITION BY user_id, brand ORDER BY event_time) AS prev_date
  FROM cos_data
  WHERE event_type = 'purchase' AND brand IS NOT NULL
),

intervals AS (
  SELECT 
    brand,
    DATEDIFF(purchase_date, prev_date) AS days_between
  FROM purchase_log
  WHERE prev_date IS NOT NULL 
    AND DATEDIFF(purchase_date, prev_date) >= 1 -- 같은 날 구매 제외
)

SELECT 
  brand,
  ROUND(AVG(days_between), 1) AS avg_repurchase_cycle
FROM intervals
WHERE brand IN ('runail', 'uno', 'irisk', 'beautix', 'grattol',
			'nagaraku', 'rosi', 'haruyama', 'ingarden', 'zinger')
GROUP BY brand
HAVING avg_repurchase_cycle IS NOT NULL
ORDER BY avg_repurchase_cycle ASC;

-- event_type 발생 시간대 별 고객 분포
WITH timezone AS (
    SELECT 
        HOUR(STR_TO_DATE(event_time, '%Y-%m-%d %H:%i:%s')) AS event_hour,
        event_type,
        user_id
    FROM ecommerce
    WHERE price >= 0  -- price < 0 데이터 제외
)

SELECT 
    CASE WHEN event_hour between '0' and '5' then '새벽'
		     WHEN event_hour between '6' and '12' then '오전'
         WHEN event_hour between '13' and '20' then '오후'
         WHEN event_hour between '21' and '23' then '밤'
	END AS time_seg ,
    COUNT(DISTINCT CASE WHEN event_type = 'view' THEN user_id END) AS view_cnt,
    COUNT(DISTINCT CASE WHEN event_type = 'cart' THEN user_id END) AS cart_cnt,
    COUNT(DISTINCT CASE WHEN event_type = 'remove_from_cart' THEN user_id END) AS remove_cnt,
    COUNT(DISTINCT CASE WHEN event_type = 'purchase' THEN user_id END) AS purchase_cnt
FROM timezone
GROUP BY CASE WHEN event_hour between '0' and '5' then '새벽'
		     WHEN event_hour between '6' and '12' then '오전'
         WHEN event_hour between '13' and '20' then '오후'
         WHEN event_hour between '21' and '23' then '밤'
	END
ORDER BY time_seg;