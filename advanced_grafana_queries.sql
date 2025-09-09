-- 🚀 ADVANCED GRAFANA QUERIES FOR PARQUET-BASED ANALYTICS
-- Use these after running parquet_to_sql.py to sync data
-- 
-- ✅ ENHANCED VERSION - Updated with:
--    • Better boat naming (CONCAT('Boat ', boat_id))
--    • Improved formatting (ROUND functions)
--    • Color-friendly series names
--    • Enhanced readability
-- Updated with enhanced historical analysis capabilities


-- 🎯 Daily Race Winners (Table Panel 1)
-- Shows the winning boat each day with enhanced formatting
SELECT 
    CONVERT(VARCHAR(10), date, 23) as "Date",
    CONCAT('Boat ', boat_id) as "Winner",
    ROUND(avg_speed, 2) as "Speed (km/h)",
    records as "Data Points",
    ROUND(max_speed, 2) as "Peak Speed"
FROM boat_historical_rankings
WHERE rank = 1
  AND date >= DATEADD(day, -14, GETDATE())
ORDER BY date DESC;

-- 🏆 Performance Leaderboard Setup
-- Shows top performing boats (panel 2)
SELECT 
    CAST(ROW_NUMBER() OVER (ORDER BY AVG(avg_speed) DESC) AS INT) as "Rank",
    CONCAT('Boat ', boat_id) as "Boat",
    ROUND(AVG(avg_speed), 2) as "Avg Speed (km/h)",
    ROUND(AVG(CAST(rank as FLOAT)), 1) as "Avg Position"
FROM boat_historical_rankings
WHERE date >= DATEADD(day, -7, GETDATE())
GROUP BY boat_id
ORDER BY AVG(avg_speed) DESC;

-- 🏆 Performance Leaderboard Setup Panel 3
-- Daily boat performance from the Lambda Architecture batch layer
SELECT 
    date as "time",
    CASE 
        WHEN boat_id = 0 THEN 'Boat 0'
        WHEN boat_id = 1 THEN 'Boat 1'  
        WHEN boat_id = 2 THEN 'Boat 2'
        WHEN boat_id = 3 THEN 'Boat 3'
        WHEN boat_id = 4 THEN 'Boat 4'
        ELSE CONCAT('Boat ', boat_id)
    END as metric,
    avg_speed as "Average Speed"
FROM boat_historical_rankings
WHERE date >= DATEADD(day, -30, GETDATE())
ORDER BY date, boat_id;

-- 🏆 Ranking Evolution (Time Series Panel 4)
-- Shows how boat rankings change over time (lower is better)
SELECT 
    date as "time",
    CONCAT('Boat ', boat_id) as metric,
    rank as "Ranking"
FROM boat_historical_rankings
WHERE date >= DATEADD(day, -14, GETDATE())
ORDER BY date, boat_id;





