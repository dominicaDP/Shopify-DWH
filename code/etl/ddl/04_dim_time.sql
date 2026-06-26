-- =============================================================================
-- Phase C — generate dim_time (24 rows, one per hour of the day)
-- Run AFTER 02_dwh_schema.sql.  TRUNCATE + INSERT, so re-running is idempotent.
--
-- time_key = hour_24 (0..23), so fact tables can derive it directly with
-- HOUR(created_at) — no lookup needed at load time.
-- day_part:  Night 0-5,  Morning 6-11,  Afternoon 12-17,  Evening 18-23.
-- is_business_hours: 09:00-16:59 (i.e. the 9..16 hours), the "9 to 5" window.
-- =============================================================================

TRUNCATE TABLE SHOPIFY_DWH.dim_time;

INSERT INTO SHOPIFY_DWH.dim_time
    (time_key, hour_24, hour_12, am_pm, hour_label, day_part, is_business_hours)
WITH digits AS (
    SELECT 0 AS d UNION ALL SELECT 1 UNION ALL SELECT 2 UNION ALL SELECT 3 UNION ALL SELECT 4
    UNION ALL SELECT 5 UNION ALL SELECT 6 UNION ALL SELECT 7 UNION ALL SELECT 8 UNION ALL SELECT 9
),
hours AS (
    SELECT d1.d + d2.d * 10 AS h
    FROM digits d1, digits d2
    WHERE d1.d + d2.d * 10 < 24
)
SELECT
    h AS time_key,
    h AS hour_24,
    CASE WHEN MOD(h, 12) = 0 THEN 12 ELSE MOD(h, 12) END AS hour_12,
    CASE WHEN h < 12 THEN 'AM' ELSE 'PM' END AS am_pm,
    (CASE WHEN MOD(h, 12) = 0 THEN 12 ELSE MOD(h, 12) END) || ':00 '
        || CASE WHEN h < 12 THEN 'AM' ELSE 'PM' END AS hour_label,
    CASE
        WHEN h BETWEEN 0 AND 5   THEN 'Night'
        WHEN h BETWEEN 6 AND 11  THEN 'Morning'
        WHEN h BETWEEN 12 AND 17 THEN 'Afternoon'
        ELSE 'Evening'
    END AS day_part,
    CASE WHEN h BETWEEN 9 AND 16 THEN TRUE ELSE FALSE END AS is_business_hours
FROM hours;
