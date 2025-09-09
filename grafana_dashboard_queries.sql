-- Grafana Dashboard Queries for Real-time Boat Racing
-- Copy these queries into your Grafana panels

-- =============================================================================
-- Panel 1: REAL-TIME BOAT POSITIONS (Geomap)
-- =============================================================================
-- Use this for the world map showing current boat positions
SELECT 
    boat_id,
    latitude,
    longitude,
    speed,
    heading,
    event_time,
    CONCAT('Boat ', boat_id) as boat_name
FROM latest_boat_positions
ORDER BY boat_id;

-- =============================================================================
-- Panel 2: CURRENT BOAT RANKINGS (Table)
-- =============================================================================
-- Shows current leaderboard sorted by speed
SELECT 
    boat_id as "Boat ID",
    ROUND(latitude, 4) as "Latitude",
    ROUND(longitude, 4) as "Longitude", 
    ROUND(speed, 2) as "Speed (km/h)",
    ROUND(heading, 1) as "Heading (°)",
    event_time as "Last Update"
FROM latest_boat_positions
ORDER BY speed DESC;

-- =============================================================================
-- Panel 3: SPEED OVER TIME (Time Series)
-- =============================================================================
-- Shows speed trends for all boats over time
SELECT 
    event_time as time,
    speed as value,
    CONCAT('Boat ', boat_id) as metric
FROM boat_telemetry 
WHERE event_time >= DATEADD(hour, -2, GETUTCDATE())
ORDER BY event_time;

-- =============================================================================
-- Panel 4: BOAT TRACKS (Geomap with tracks)
-- =============================================================================
-- Shows the path each boat has taken
SELECT 
    boat_id,
    latitude,
    longitude,
    event_time,
    CONCAT('Boat ', boat_id) as boat_name
FROM boat_telemetry 
WHERE event_time >= DATEADD(hour, -6, GETUTCDATE())
ORDER BY boat_id, event_time;

-- =============================================================================
-- Panel 5: DATA QUALITY STATS (Stat panels)
-- =============================================================================
-- Total records received
SELECT COUNT(*) as "Total Records"
FROM boat_telemetry 
WHERE event_time >= DATEADD(hour, -1, GETUTCDATE());

-- Active boats
SELECT COUNT(DISTINCT boat_id) as "Active Boats"
FROM boat_telemetry 
WHERE event_time >= DATEADD(hour, -1, GETUTCDATE());

-- Latest data timestamp
SELECT MAX(event_time) as "Latest Data"
FROM boat_telemetry;

-- =============================================================================
-- Panel 6: AVERAGE SPEED BY BOAT (Bar Chart)
-- =============================================================================
-- Shows average speed for each boat over the last hour
SELECT 
    CONCAT('Boat ', boat_id) as boat_name,
    AVG(speed) as avg_speed
FROM boat_telemetry 
WHERE event_time >= DATEADD(hour, -1, GETUTCDATE())
GROUP BY boat_id
ORDER BY avg_speed DESC;

-- =============================================================================
-- Panel 7: DISTANCE TRAVELED (Stat)
-- =============================================================================
-- Approximate distance calculation (simplified)
WITH position_changes AS (
    SELECT 
        boat_id,
        latitude,
        longitude,
        LAG(latitude) OVER (PARTITION BY boat_id ORDER BY event_time) as prev_lat,
        LAG(longitude) OVER (PARTITION BY boat_id ORDER BY event_time) as prev_lng
    FROM boat_telemetry 
    WHERE event_time >= DATEADD(hour, -24, GETUTCDATE())
)
SELECT 
    SUM(
        SQRT(
            POWER((latitude - prev_lat) * 111.0, 2) + 
            POWER((longitude - prev_lng) * 85.0, 2)
        )
    ) as "Total Distance (km)"
FROM position_changes 
WHERE prev_lat IS NOT NULL;

