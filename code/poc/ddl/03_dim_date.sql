-- =============================================================================
-- POC Phase 3.3 — generate dim_date (2020-01-01 .. 2030-12-31)
-- Exasol has no generate_series; build numbers 0..9999 from a 4-digit cross
-- join, add to a start date, and keep the 11-year span.
-- day_of_week: 0 = Monday .. 6 = Sunday, anchored on 2024-01-01 (a Monday).
-- The +700000 (a multiple of 7) keeps MOD non-negative for pre-anchor dates.
-- =============================================================================

TRUNCATE TABLE SHOPIFY_DWH.dim_date;

INSERT INTO SHOPIFY_DWH.dim_date
    (date_key, full_date, cal_year, cal_quarter, cal_month, month_name, cal_day, day_of_week, day_name, is_weekend)
WITH digits AS (
    SELECT 0 AS d UNION ALL SELECT 1 UNION ALL SELECT 2 UNION ALL SELECT 3 UNION ALL SELECT 4
    UNION ALL SELECT 5 UNION ALL SELECT 6 UNION ALL SELECT 7 UNION ALL SELECT 8 UNION ALL SELECT 9
),
nums AS (
    SELECT d1.d + d2.d * 10 + d3.d * 100 + d4.d * 1000 AS n
    FROM digits d1, digits d2, digits d3, digits d4
),
cal AS (
    SELECT ADD_DAYS(DATE '2020-01-01', n) AS full_date
    FROM nums
    WHERE n < 4018
)
SELECT
    YEAR(full_date) * 10000 + MONTH(full_date) * 100 + DAY(full_date) AS date_key,
    full_date,
    YEAR(full_date) AS cal_year,
    CAST(CEIL(MONTH(full_date) / 3.0) AS INTEGER) AS cal_quarter,
    MONTH(full_date) AS cal_month,
    CASE MONTH(full_date)
        WHEN 1 THEN 'January' WHEN 2 THEN 'February' WHEN 3 THEN 'March'
        WHEN 4 THEN 'April'   WHEN 5 THEN 'May'      WHEN 6 THEN 'June'
        WHEN 7 THEN 'July'    WHEN 8 THEN 'August'   WHEN 9 THEN 'September'
        WHEN 10 THEN 'October' WHEN 11 THEN 'November' WHEN 12 THEN 'December'
    END AS month_name,
    DAY(full_date) AS cal_day,
    MOD(DAYS_BETWEEN(full_date, DATE '2024-01-01') + 700000, 7) AS day_of_week,
    CASE MOD(DAYS_BETWEEN(full_date, DATE '2024-01-01') + 700000, 7)
        WHEN 0 THEN 'Monday'   WHEN 1 THEN 'Tuesday' WHEN 2 THEN 'Wednesday'
        WHEN 3 THEN 'Thursday' WHEN 4 THEN 'Friday'  WHEN 5 THEN 'Saturday'
        WHEN 6 THEN 'Sunday'
    END AS day_name,
    CASE WHEN MOD(DAYS_BETWEEN(full_date, DATE '2024-01-01') + 700000, 7) IN (5, 6)
         THEN TRUE ELSE FALSE END AS is_weekend
FROM cal;
