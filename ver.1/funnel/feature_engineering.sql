-- 데이터 전처리
SELECT * FROM all_months;

-- user_session이 결측값인 경우
SELECT *
FROM all_months
WHERE user_session = '';

-- 결측값이 발생하는 특정 이벤트 확인
SELECT event_type, COUNT(*)
FROM all_months
WHERE user_session = ''
GROUP BY event_type;

-- 시간 흐름 분석
SELECT user_id, event_time, user_session
FROM all_months
WHERE user_id = 580025231
ORDER BY event_time;

-- 세션 유지 시간 분석
SELECT user_id, user_session, 
       MIN(event_time) AS session_start, 
       MAX(event_time) AS session_end, 
       TIMESTAMPDIFF(MINUTE, MIN(event_time), MAX(event_time)) AS session_duration
FROM all_months
GROUP BY user_id, user_session;

-- 세션 유지 시간의 최소, 최대, 평균
WITH session_durations AS (
	SELECT user_id, user_session, 
		   MIN(event_time) AS session_start, 
		   MAX(event_time) AS session_end, 
		   TIMESTAMPDIFF(MINUTE, MIN(event_time), MAX(event_time)) AS session_duration
	FROM all_months
	GROUP BY user_id, user_session
)
SELECT
	MIN(session_duration) AS min_session_duration,
    MAX(session_duration) AS max_session_duration,
    AVG(session_duration) AS avg_session_duration
FROM session_durations;

-- 세션 유지 시간 분포
SELECT user_id, user_session, 
	   TIMESTAMPDIFF(MINUTE, MIN(event_time), MAX(event_time)) AS session_duration
FROM all_months
GROUP BY user_id, user_session;

-- price가 0인 경우 (날짜별)
SELECT DATE_FORMAT(event_time, '%Y-%m-%d') AS date, COUNT(*)
FROM all_months
WHERE price = 0
GROUP BY DATE_FORMAT(event_time, '%Y-%m-%d');

-- price가 0인 경우 (product_id별)
SELECT product_id, COUNT(*)
FROM all_months
WHERE price = 0
GROUP BY product_id;

-- user의 첫 이벤트 분포
WITH first_events AS (
    SELECT 
        user_id, 
        event_type AS first_event_type
    FROM (
        SELECT user_id, event_type, 
               ROW_NUMBER() OVER (PARTITION BY user_id ORDER BY event_time) AS rn
        FROM cosmetics
    ) sub
    WHERE rn = 1
)
SELECT first_event_type, COUNT(*) AS user_count,
       ROUND(COUNT(*) * 100.0 / SUM(COUNT(*)) OVER(), 2) AS percentage
FROM first_events
GROUP BY first_event_type
ORDER BY user_count DESC;