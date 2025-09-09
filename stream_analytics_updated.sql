/*
Updated Stream Analytics Query for Azure SQL Database output
Replace your current query with this one

This query:
1. Filters out corrupted data (latitude/longitude = -10000)
2. Validates GPS coordinates are within valid ranges
3. Ensures all required fields are present
4. Outputs clean data to Azure SQL Database
*/

SELECT
    TRY_CAST(boat as bigint) as boat_id,
    TRY_CAST(latitude as float) as latitude,
    TRY_CAST(longitude as float) as longitude,
    TRY_CAST(heading as float) as heading,
    TRY_CAST(speed as float) as speed,
    TRY_CAST(EventProcessedUtcTime as datetime) as event_time,
    TRY_CAST(EventEnqueuedUtcTime as datetime) as enqueued_time
INTO
    [boat-telemetry-sql]  -- This will be your new SQL Database output
FROM
    [project1]
WHERE 
    -- Filter out corrupted GPS data
    latitude != -10000.0 
    and longitude != -10000.0
    -- Validate GPS coordinates are within valid ranges
    and latitude >= -90.0 and latitude <= 90.0 
    and longitude >= -180.0 and longitude <= 180.0 
    -- Ensure required fields are not null
    and latitude is not null 
    and longitude is not null
    and boat is not null
    -- Validate speed is reasonable
    and speed >= 0.0 
    and speed <= 50.0  -- Max reasonable speed for sailing boats
    -- Ensure timestamps are present
    and EventProcessedUtcTime is not null 
    and EventEnqueuedUtcTime is not null


