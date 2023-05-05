--List the user IDs who are attributed to Facebook and registered on a weekend
SELECT 
	user_id
FROM users
WHERE 1=1
AND EXTRACT(DOW FROM registration_timestamp) IN (0, 6)


--Find the number of registered users by app version and order from newest to oldest version
SELECT 
  app_version
  , COUNT(DISTINCT user_id) AS user_count
FROM users
GROUP BY 1
ORDER BY 1 DESC 


--For each month calculate (a) the total amount in sales, (b) Mega Millions sales and (c) Powerball sales as separate fields in a single row?
SELECT
	DATE_TRUNC('month', entry_timestamp)
	, SUM(amount) AS total_sales
    , SUM(CASE WHEN game_name = 'Mega Millions' THEN amount ELSE 0 END) AS mega_millions
    , SUM(CASE WHEN game_name = 'Powerball' THEN amount ELSE 0 END) AS powerball
FROM sales
GROUP BY 1

--For Google users paying with Card, find the total amount deposited and the number of unique depositors
WITH u AS
(
  SELECT user_id
  FROM users
  WHERE marketing_channel = 'Google'
)

SELECT 
	SUM(amount) AS amt_deposited
	, COUNT(DISTINCT deposit_id) AS num_depositors
FROM deposits d
JOIN u
ON d.user_id = u.user_id
WHERE 1=1
AND status = 'completed'
AND method = 'Card'


--For each registered user find (a) their first deposit date, (b) their first deposit amount, (c) the number of states they have played a game in and (d) their lifetime sales amount. Order by descending total sales
WITH u AS 
(
  SELECT
      user_id
      , MIN(registration_timestamp) AS first_dep_date
  FROM users
  GROUP BY 1
)
,
d AS
(
  SELECT 
  	d.user_id
    , amount
  FROM deposits d
  JOIN
      (
        SELECT 
          user_id
          , MIN(deposit_timestamp) AS mins
        FROM deposits
        GROUP BY 1
      ) m
  ON d.user_id = m.user_id
  AND d.deposit_timestamp = m.mins
)
,
s AS 
(
  SELECT user_id,
  		COUNT(DISTINCT state) as num_states,
 		SUM(amount) AS lifetime_sales
  FROM sales
  GROUP BY 1
)

SELECT
    u.user_id
    , u.first_dep_date
    , d.amount AS first_dep_amount
    , s.num_states
    , CASE WHEN s.lifetime_sales IS null THEN 0 ELSE lifetime_sales END AS life_sales
FROM u
LEFT JOIN d
ON u.user_id = d.user_id
LEFT JOIN s
ON u.user_id = s.user_id
ORDER BY 5 DESC


-- Create a cohort analysis by user registration week that shows cumulative daily sales through the first 31 days (D0 through D30, where D0 is the same calendar date as registration) of a user’s life. The output should include the cohort week, the activity day (i.e. Dx from 0 to 30) and the cumulative sales for that cohort. Each cohort should have 31 records. Include a clause to only include users who have been registered for at least 30 days

-- -- registration_week + registered within 30 days
WITH calendar AS (
  SELECT 
    generate_series('2020-01-01'::date, '2020-12-31'::date, '1 day'::interval) AS date
)
,
u AS  
(
  SELECT
  	user_id
  	, DATE_TRUNC('week', registration_timestamp) as reg_week
    , registration_timestamp
  FROM users
  WHERE 1=1
  AND registration_timestamp + interval '30 days' <= CURRENT_DATE 
)
,
s AS 
(
  SELECT 
      user_id
      , date_trunc('day', entry_timestamp) as entry_day
      , sum(amount) as amount_day
  FROM sales
  WHERE 1=1
  GROUP BY 1,2
  ORDER BY 1 ASC
)
SELECT 
	reg_week
    , u.user_id
    , registration_timestamp
    , c.date
    -- , entry_day
    -- , amount_day
    , CASE WHEN SUM(amount_day) OVER (PARTITION BY u.user_id ORDER BY c.date) IS null
    	THEN 0 ELSE SUM(amount_day) OVER (PARTITION BY u.user_id ORDER BY c.date) END AS running_sum
    -- , ROW_NUMBER() OVER (PARTITION BY u.user_id)
FROM u
LEFT JOIN calendar c
ON DATE_TRUNC('day',u.registration_timestamp) <= c.date
AND date(c.date) - date(date_trunc('day',u.registration_timestamp)) <=30
LEFT JOIN s
ON c.date = s.entry_day





-- Write a query that returns the combined value of the Powerball and Mega Millions jackpots for every day from Feb 1 through Apr 30. This will include days without drawings. 
-- Note that the day immediately after a drawing would have a jackpot value equal to the next value seen (i.e. if jackpot on Jan 1 is $100M and jackpot on Jan 5 is $200M then the values for Jan 2 through Jan 4 would be $200M)


WITH calendar AS (
  SELECT 
    generate_series('2020-02-01'::date, '2020-04-30'::date, '1 day'::interval) AS date
)
,
g AS 
(
  SELECT 
  	date
  	, game_date
  	, SUM(jackpot) AS jackpot
  FROM calendar c
  LEFT JOIN results r
  ON c.date = DATE_TRUNC('day', r.game_date)
  GROUP BY 1,2
  ORDER BY 1
)
,
w AS (
SELECT 
	g.*
    , COUNT(jackpot) OVER (ORDER BY date) AS cc
FROM g
)
,
jp AS 
(
  SELECT
  	cc AS cc
  	, MAX(jackpot) AS tot
  FROM w
  GROUP BY 1
)

SELECT 
	w.date
    , jp.tot AS jackpot_amt
FROM w
LEFT JOIN jp
ON (CASE WHEN w.jackpot IS null THEN w.cc+1 ELSE w.cc END) = jp.cc


-- Create a single output query that shows the most common standard ball and bonus ball drawn, as well as how many times each was drawn? If there are ties return multiple balls
WITH s AS 
(
  SELECT 
  	*
  	, DENSE_RANK() OVER (ORDER BY standard_count DESC) AS rank_s
  	, 'standard_ball' AS ball_type
  FROM (
        SELECT 
           UNNEST(STRING_TO_ARRAY(SUBSTRING(numbers FROM 1 FOR LENGTH(numbers) - POSITION(',' IN REVERSE(numbers))), ',')) AS standard_nums,
          COUNT(*) AS standard_count
        FROM results
  		GROUP BY 1
  		) ss
  )
  ,
  b AS 
(
  SELECT 
  	*
  	, DENSE_RANK() OVER (ORDER BY bonus_count DESC) AS rank_b
  	, 'bonus_ball' AS ball_type
  FROM (
        SELECT 
           SPLIT_PART(numbers, ',', ARRAY_LENGTH(STRING_TO_ARRAY(numbers, ','), 1)) AS bonus_nums,
          COUNT(*) AS bonus_count
        FROM results
  		GROUP BY 1
  		) bb
  )
  
SELECT 
  ball_type
  , standard_nums AS numbers
  , standard_count AS number_count
FROM s
WHERE 1=1
AND rank_s = 1

UNION

SELECT 
  ball_type
  , bonus_nums AS numbers
  , bonus_count AS number_count
FROM b
WHERE 1=1
AND rank_b = 1
