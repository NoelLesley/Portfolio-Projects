SELECT *
FROM cyclist_data;

-- Checking data for nulls 
SELECT *
FROM cyclist_data
WHERE Month IS NULL OR Duration IS NULL OR start_time IS NULL OR end_time IS NULL OR member_casual IS NULL;

DELETE FROM cyclist_data
WHERE start_station_name = '' OR end_station_name = '' OR start_station_name IS NULL OR end_station_name IS NULL;

-- Checking if data has been imported correctly
SELECT DISTINCT(start_weekday)
FROM cyclist_data;

SELECT DISTINCT(end_weekday)
FROM cyclist_data;

SELECT DISTINCT(Month)
FROM cyclist_data;
DELETE FROM cyclist_data
WHERE TRIM(Month) IN ('', 'Month');

SELECT DISTINCT(Duration)
FROM cyclist_data
ORDER BY Duration ASC;
DELETE FROM cyclist_data
WHERE Duration = '###############################################################################################################################################################################################################################################################';
UPDATE cyclist_data
SET Duration = 
    (HOUR(STR_TO_DATE(Duration, '%H:%i:%s')) * 60 + 
     MINUTE(STR_TO_DATE(Duration, '%H:%i:%s')) + 
     SECOND(STR_TO_DATE(Duration, '%H:%i:%s')) / 60);

-- To check for duplicates
WITH duplicate_cte AS 
(
SELECT *,
ROW_NUMBER() OVER(
PARTITION BY member_casual, rideable_type, start_date, start_time, start_weekday, ended_date, end_time, end_weekday, `Month`, 
Duration, start_station_name, end_station_name) AS row_num
FROM cyclist_data
)
SELECT * 
FROM duplicate_cte
WHERE row_num > 1;

-- Descriptive Analysis
-- average duration for each month
SELECT member_casual as user_type,`Month` , AVG(Duration) AS average_duration
FROM cyclist_data
GROUP BY `Month`,member_casual ;


-- average duration per weekday
SELECT member_casual as user_type, start_weekday as weekday , avg(Duration) AS max_duration
FROM cyclist_data
GROUP BY start_weekday , member_casual;

-- total number of rides 
SELECT Month,
       start_weekday AS weekday,
       COUNT(*) AS total_rides
FROM cyclist_data
GROUP BY Month, start_weekday;

SELECT start_weekday AS weekday,
       COUNT(*) AS total_rides
FROM cyclist_data
GROUP BY start_weekday
ORDER BY total_rides DESC;

SELECT Month ,
       COUNT(*) AS total_rides
FROM cyclist_data
GROUP BY Month
ORDER BY total_rides DESC;


-- finding most popular stations and routes
SELECT start_station_name,
       COUNT(*) AS total_rides
FROM cyclist_data
WHERE member_casual = 'member'
GROUP BY start_station_name
ORDER BY total_rides DESC
LIMIT 10;

SELECT start_station_name,
       COUNT(*) AS total_rides
FROM cyclist_data
WHERE member_casual = 'casual'
GROUP BY start_station_name
ORDER BY total_rides DESC
LIMIT 10;

SELECT end_station_name,
       COUNT(*) AS total_rides
FROM cyclist_data
WHERE member_casual = 'member'
GROUP BY end_station_name
ORDER BY total_rides DESC
LIMIT 10;

SELECT end_station_name,
       COUNT(*) AS total_rides
FROM cyclist_data
WHERE member_casual = 'casual'
GROUP BY end_station_name
ORDER BY total_rides DESC
LIMIT 10;

SELECT CONCAT(start_station_name, ' to ', end_station_name) AS route,
COUNT(*) AS total_rides
FROM cyclist_data
WHERE member_casual = 'member'
GROUP BY start_station_name, end_station_name
ORDER BY total_rides DESC
LIMIT 10;


SELECT CONCAT(start_station_name, ' to ', end_station_name) AS route,
COUNT(*) AS total_rides
FROM cyclist_data
WHERE member_casual = 'casual'
GROUP BY start_station_name, end_station_name
ORDER BY total_rides DESC
LIMIT 10;
























