-- ============================================================================
-- QUESTION 2: Data Read Estimation
-- ============================================================================
-- Write a query to count the distinct number of PULocationIDs for the
-- entire dataset on both the External Table and the Materialized Table.
--
-- What is the estimated amount of data that will be read when this query
-- is executed on the External Table and the Table?
--
-- Options:
--   a) 18.82 MB for the External Table and 47.60 MB for the Materialized Table
--   b) 0 MB for the External Table and 155.12 MB for the Materialized Table
--   c) 2.14 GB for the External Table and 0MB for the Materialized Table
--   d) 0 MB for the External Table and 0MB for the Materialized Table
--
-- Key Concept:
--   External tables don't provide query estimation (shows 0 MB or estimate)
--   Materialized tables show accurate byte estimates based on column size
-- ============================================================================

-- ============================================================================
-- QUERY 1: External Table
-- ============================================================================
-- IMPORTANT: Do NOT run this query yet!
-- 1. Type the query in BigQuery Console
-- 2. Look at "This query will process X bytes" message
-- 3. Note down the estimated bytes
-- ============================================================================

SELECT
  COUNT(DISTINCT PULocationID) as unique_pickup_locations
FROM
  `electric-cosine-485318-f9.o3_warehouse.yellow_tripdata_external`;

-- Expected Estimation: Check the validator (✓) button in BigQuery UI
-- External tables often show 0 MB or cannot estimate accurately


-- ============================================================================
-- QUERY 2: Materialized Table
-- ============================================================================
-- IMPORTANT: Do NOT run this query yet!
-- 1. Type the query in BigQuery Console
-- 2. Look at "This query will process X bytes" message
-- 3. Note down the estimated bytes
-- 4. Compare with external table estimation
-- ============================================================================

SELECT
  COUNT(DISTINCT PULocationID) as unique_pickup_locations
FROM
  `electric-cosine-485318-f9.o3_warehouse.yellow_tripdata_materialized`;

-- Expected Estimation: Will show actual bytes (likely ~155 MB)


-- ============================================================================
-- EXPLANATION: Why are the estimates different?
-- ============================================================================
--
-- External Table (GCS):
--   - Data is in parquet format in GCS
--   - BigQuery cannot pre-calculate column sizes
--   - Estimation may show 0 MB or be inaccurate
--   - Actual processing may read entire parquet files
--
-- Materialized Table (BigQuery):
--   - Data is stored in BigQuery's columnar format (Colossus)
--   - BigQuery knows exact size of PULocationID column
--   - Shows accurate estimate: ~155 MB
--   - Only reads the PULocationID column (not entire row)
--
-- Key Takeaway:
--   Materialized tables provide better query planning and cost estimation!
-- ============================================================================


-- ============================================================================
-- ADDITIONAL: Check actual column sizes
-- ============================================================================
SELECT
  column_name,
  data_type,
  is_nullable
FROM
  `electric-cosine-485318-f9.o3_warehouse.INFORMATION_SCHEMA.COLUMNS`
WHERE
  table_name = 'yellow_tripdata_materialized'
  AND column_name IN ('PULocationID', 'DOLocationID', 'VendorID')
ORDER BY
  ordinal_position;
