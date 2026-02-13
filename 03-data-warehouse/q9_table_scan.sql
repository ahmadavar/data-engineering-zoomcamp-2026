-- ============================================================================
-- QUESTION 9: Understanding Table Scans (No Points)
-- ============================================================================
-- Write a SELECT count(*) query FROM the materialized table you created.
-- How many bytes does it estimate will be read? Why?
--
-- Expected: 0 MB (or very small amount)
--
-- Explanation:
--   BigQuery stores metadata about tables, including row counts.
--   For COUNT(*) without WHERE clause, BigQuery can return the count
--   from metadata without scanning any actual data!
-- ============================================================================

-- ============================================================================
-- QUERY: Count all rows
-- ============================================================================
-- IMPORTANT: Check estimated bytes BEFORE running!
-- ============================================================================

SELECT COUNT(*) as total_rows
FROM `electric-cosine-485318-f9.o3_warehouse.yellow_tripdata_materialized`;

-- Expected Estimation: 0 MB (or very small like 10-20 MB)
-- Expected Result: Same count as Question 1


-- ============================================================================
-- EXPLANATION: Why 0 MB?
-- ============================================================================
--
-- BigQuery Table Metadata:
--   When you create a table, BigQuery stores metadata separately:
--     - Schema (column names, types)
--     - Statistics (row count, min/max values per column)
--     - Storage size
--     - Partition information
--     - Last modified time
--
-- Optimization for COUNT(*):
--   COUNT(*) without WHERE = "How many total rows?"
--   BigQuery knows this from metadata → No need to scan data!
--
-- Compare with:
--   SELECT COUNT(*) WHERE fare_amount > 0
--     → Must scan fare_amount column to check condition
--     → Processes actual data (not just metadata)
--
-- This optimization works for:
--   ✓ SELECT COUNT(*) FROM table
--   ✓ Simple aggregates on indexed/metadata fields
--
-- Does NOT work for:
--   ✗ SELECT COUNT(*) WHERE <condition>
--   ✗ SELECT COUNT(column_name)  -- Must check for NULLs
--   ✗ SELECT SUM(column)
-- ============================================================================


-- ============================================================================
-- COMPARISON: Different COUNT queries
-- ============================================================================

-- Query 1: COUNT(*) - Uses metadata, 0 MB
SELECT COUNT(*) as total_rows
FROM `electric-cosine-485318-f9.o3_warehouse.yellow_tripdata_materialized`;
-- Estimated: 0 MB (metadata only)


-- Query 2: COUNT(*) with WHERE - Must scan data
SELECT COUNT(*) as filtered_rows
FROM `electric-cosine-485318-f9.o3_warehouse.yellow_tripdata_materialized`
WHERE fare_amount > 10;
-- Estimated: ~100+ MB (must read fare_amount column)


-- Query 3: COUNT(column) - Must scan to check NULLs
SELECT COUNT(PULocationID) as non_null_pickups
FROM `electric-cosine-485318-f9.o3_warehouse.yellow_tripdata_materialized`;
-- Estimated: ~155 MB (must read PULocationID column to count non-NULLs)


-- Query 4: COUNT(DISTINCT column) - Must scan and deduplicate
SELECT COUNT(DISTINCT PULocationID) as unique_pickups
FROM `electric-cosine-485318-f9.o3_warehouse.yellow_tripdata_materialized`;
-- Estimated: ~155 MB (must read PULocationID column)


-- ============================================================================
-- PRACTICAL IMPLICATIONS
-- ============================================================================
--
-- Getting table size quickly:
--   SELECT COUNT(*) FROM large_table  -- Fast! 0 bytes scanned
--
-- Data validation:
--   -- Bad (slow, expensive):
--   SELECT COUNT(*) FROM table WHERE date = '2024-01-01'  -- Scans all data
--
--   -- Good (fast, cheap):
--   SELECT total_rows
--   FROM `project.dataset.INFORMATION_SCHEMA.PARTITIONS`
--   WHERE table_name = 'table' AND partition_id = '20240101'
--
-- Monitoring table growth:
--   -- Use INFORMATION_SCHEMA instead of scanning tables:
--   SELECT
--     table_name,
--     row_count,
--     size_bytes / 1024 / 1024 as size_mb
--   FROM `project.dataset.__TABLES__`
--   ORDER BY size_bytes DESC;
--   -- This scans metadata only, not actual tables!
-- ============================================================================


-- ============================================================================
-- METADATA TABLES IN BIGQUERY
-- ============================================================================
-- BigQuery provides metadata tables that you can query:

-- 1. __TABLES__ - Table information
SELECT
  table_id as table_name,
  row_count,
  ROUND(size_bytes / 1024 / 1024, 2) as size_mb,
  ROUND(size_bytes / row_count, 2) as bytes_per_row,
  creation_time,
  last_modified_time
FROM
  `electric-cosine-485318-f9.o3_warehouse.__TABLES__`
ORDER BY
  size_bytes DESC;


-- 2. INFORMATION_SCHEMA.TABLES - Standard SQL metadata
SELECT
  table_name,
  table_type,
  creation_time
FROM
  `electric-cosine-485318-f9.o3_warehouse.INFORMATION_SCHEMA.TABLES`
WHERE
  table_type IN ('BASE TABLE', 'EXTERNAL');


-- 3. INFORMATION_SCHEMA.COLUMNS - Column details
SELECT
  table_name,
  column_name,
  data_type,
  is_nullable,
  is_partitioning_column
FROM
  `electric-cosine-485318-f9.o3_warehouse.INFORMATION_SCHEMA.COLUMNS`
WHERE
  table_name = 'yellow_tripdata_partitioned_clustered'
ORDER BY
  ordinal_position;


-- 4. INFORMATION_SCHEMA.PARTITIONS - Partition details
SELECT
  table_name,
  partition_id,
  total_rows,
  ROUND(total_logical_bytes / 1024 / 1024, 2) as size_mb
FROM
  `electric-cosine-485318-f9.o3_warehouse.INFORMATION_SCHEMA.PARTITIONS`
WHERE
  table_name = 'yellow_tripdata_partitioned_clustered'
  AND partition_id IS NOT NULL
ORDER BY
  partition_id DESC
LIMIT 10;


-- ============================================================================
-- BEST PRACTICES
-- ============================================================================
-- 1. Use COUNT(*) for total counts (it's free!)
--    ✓ SELECT COUNT(*) FROM table
--
-- 2. Avoid COUNT(*) with WHERE if you just need table size
--    ✗ SELECT COUNT(*) FROM table WHERE date = '2024-01-01'
--    ✓ Query INFORMATION_SCHEMA.PARTITIONS instead
--
-- 3. Use metadata tables for monitoring
--    ✓ Faster than scanning actual tables
--    ✓ No cost (metadata queries are free)
--
-- 4. Understand when queries use metadata vs. data scanning
--    Metadata: COUNT(*), table size, schema info
--    Data scan: COUNT(*) WHERE ..., aggregations, DISTINCT
-- ============================================================================


-- ============================================================================
-- SUMMARY FOR QUESTION 9
-- ============================================================================
-- Question: Why does COUNT(*) estimate 0 MB?
--
-- Answer:
--   BigQuery stores row count as metadata. For COUNT(*) without filters,
--   it can return the count directly from metadata without scanning the
--   actual table data. This makes total row counts instant and free!
--
--   Only when you add a WHERE clause or count specific columns (which
--   requires checking for NULLs) does BigQuery need to scan actual data.
-- ============================================================================
