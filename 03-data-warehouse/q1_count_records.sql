-- ============================================================================
-- QUESTION 1: Counting Records
-- ============================================================================
-- What is count of records for the 2024 Yellow Taxi Data?
--
-- Options:
--   a) 65,623
--   b) 840,402
--   c) 20,332,093
--   d) 85,431,289
--
-- Explanation:
--   This is a straightforward COUNT query on the materialized table.
--   We use the materialized table (not external) for accurate counting.
-- ============================================================================

SELECT
  COUNT(*) as total_records,
  FORMAT("%'d", COUNT(*)) as formatted_count  -- With thousand separators
FROM
  `electric-cosine-485318-f9.o3_warehouse.yellow_tripdata_materialized`;

-- Expected Result: Will match one of the options above


-- ============================================================================
-- ADDITIONAL ANALYSIS (OPTIONAL)
-- ============================================================================
-- Let's break down the count by month to verify data completeness

SELECT
  FORMAT_DATE('%Y-%m', DATE(tpep_pickup_datetime)) as month,
  COUNT(*) as trip_count,
  FORMAT("%'d", COUNT(*)) as formatted_count
FROM
  `electric-cosine-485318-f9.o3_warehouse.yellow_tripdata_materialized`
GROUP BY
  month
ORDER BY
  month;

-- Expected: 6 rows (Jan 2024 - Jun 2024)


-- ============================================================================
-- PERFORMANCE NOTE
-- ============================================================================
-- COUNT(*) without WHERE clause is very efficient in BigQuery
-- BigQuery stores metadata about row counts, so this query:
--   - Doesn't scan all rows
--   - Reads only metadata
--   - Processes minimal bytes (often 0 MB!)
--   - Returns instantly even for billion-row tables
-- ============================================================================
