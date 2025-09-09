-- 🚀 ADVANCED GRAFANA QUERIES FOR PARQUET-BASED ANALYTICS
-- Use these after running parquet_to_sql.py to sync data

-- 📈 Historical Speed Trends (Time Series Panel)
-- Shows how each boat's performance changes over time
SELECT 
    date as "time",
    boat_id as metric,
    avg_speed as "Average Speed"
FROM boat_historical_rankings
WHERE date >= DATEADD(day, -30, GETDATE())
ORDER BY date, boat_id;

-- 🏆 Ranking Evolution (Time Series Panel)
-- Shows how boat rankings change over time (lower is better)
SELECT 
    date as "time",
    boat_id as metric,
    rank as "Ranking"
FROM boat_historical_rankings
WHERE date >= DATEADD(day, -14, GETDATE())
ORDER BY date, boat_id;

-- 📊 Performance Consistency (Stat Panel)
-- Shows which boats are most consistent performers
SELECT 
    boat_id as "Boat",
    AVG(avg_speed) as "Avg Speed",
    STDEV(avg_speed) as "Speed Variance",
    AVG(CAST(rank as FLOAT)) as "Avg Rank"
FROM boat_historical_rankings
WHERE date >= DATEADD(day, -7, GETDATE())
GROUP BY boat_id
ORDER BY AVG(avg_speed) DESC;

-- 🎯 Daily Winners (Table Panel)
-- Shows the winning boat each day
SELECT 
    date as "Date",
    boat_id as "Winner",
    avg_speed as "Speed",
    records as "Data Points"
FROM boat_historical_rankings
WHERE rank = 1
  AND date >= DATEADD(day, -14, GETDATE())
ORDER BY date DESC;

-- 📈 Speed Improvement Trends (Time Series Panel)
-- Shows day-over-day speed improvements
WITH daily_changes AS (
    SELECT 
        date,
        boat_id,
        avg_speed,
        LAG(avg_speed) OVER (PARTITION BY boat_id ORDER BY date) as prev_speed
    FROM boat_historical_rankings
    WHERE date >= DATEADD(day, -14, GETDATE())
)
SELECT 
    date as "time",
    boat_id as metric,
    (avg_speed - prev_speed) as "Speed Change"
FROM daily_changes
WHERE prev_speed IS NOT NULL
ORDER BY date, boat_id;

-- 🗺️ Position Analysis (WorldMap Panel)
-- Shows average positions by boat over time
SELECT 
    boat_id as "Boat",
    AVG(avg_lat) as "latitude",
    AVG(avg_lng) as "longitude",
    AVG(avg_speed) as "Average Speed"
FROM boat_historical_rankings
WHERE date >= DATEADD(day, -7, GETDATE())
GROUP BY boat_id;

-- 📊 Data Quality Metrics (Stat Panel)
-- Shows data completeness and quality
SELECT 
    date as "Date",
    COUNT(*) as "Boats Tracked",
    AVG(records) as "Avg Records per Boat",
    SUM(records) as "Total Data Points"
FROM boat_historical_rankings
WHERE date >= DATEADD(day, -7, GETDATE())
GROUP BY date
ORDER BY date DESC;

-- 🏁 Race Summary Dashboard (Multiple Panels)
-- Combined view for executive dashboard
SELECT 
    'Today' as "Period",
    COUNT(*) as "Active Boats",
    MAX(avg_speed) as "Top Speed",
    MIN(avg_speed) as "Slowest Speed",
    AVG(avg_speed) as "Fleet Average"
FROM boat_historical_rankings
WHERE date = CAST(GETDATE() AS DATE)

UNION ALL

SELECT 
    'Yesterday' as "Period",
    COUNT(*) as "Active Boats",
    MAX(avg_speed) as "Top Speed", 
    MIN(avg_speed) as "Slowest Speed",
    AVG(avg_speed) as "Fleet Average"
FROM boat_historical_rankings
WHERE date = CAST(DATEADD(day, -1, GETDATE()) AS DATE)

UNION ALL

SELECT 
    'Last 7 Days' as "Period",
    COUNT(DISTINCT boat_id) as "Active Boats",
    MAX(avg_speed) as "Top Speed",
    MIN(avg_speed) as "Slowest Speed", 
    AVG(avg_speed) as "Fleet Average"
FROM boat_historical_rankings
WHERE date >= DATEADD(day, -7, GETDATE());
