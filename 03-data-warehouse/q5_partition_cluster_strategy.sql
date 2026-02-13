-- ============================================================================
-- QUESTION 5: Partitioning and Clustering Strategy
-- ============================================================================
-- What is the best strategy to make an optimized table in Big Query if
-- your query will always filter based on tpep_dropoff_datetime and order
-- the results by VendorID?
--
-- Options:
--   a) Partition by tpep_dropoff_datetime and Cluster on VendorID ✓
--   b) Cluster on by tpep_dropoff_datetime and Cluster on VendorID
--   c) Cluster on tpep_dropoff_datetime Partition by VendorID
--   d) Partition by tpep_dropoff_datetime and Partition by VendorID
--
-- Correct Answer: (a)
--
-- Explanation:
--   - Always FILTER by date → PARTITION by date (reduces data scanned)
--   - Always ORDER by VendorID → CLUSTER by VendorID (sorts data)
--   - You can only PARTITION by ONE column (date/timestamp/integer)
--   - You can CLUSTER by up to 4 columns
-- ============================================================================

-- ============================================================================
-- CREATE THE OPTIMIZED TABLE
-- ============================================================================
-- This table was already created in setup.sql, but here's the command again:

CREATE OR REPLACE TABLE `electric-cosine-485318-f9.o3_warehouse.yellow_tripdata_partitioned_clustered`
PARTITION BY DATE(tpep_dropoff_datetime)
CLUSTER BY VendorID AS
SELECT * FROM `electric-cosine-485318-f9.o3_warehouse.yellow_tripdata_external`;


-- ============================================================================
-- VERIFY THE TABLE STRUCTURE
-- ============================================================================
-- Check partitioning info
SELECT
  table_name,
  partition_id,
  total_rows,
  ROUND(total_logical_bytes / 1024 / 1024, 2) as size_mb
FROM
  `electric-cosine-485318-f9.o3_warehouse.INFORMATION_SCHEMA.PARTITIONS`
WHERE
  table_name = 'yellow_tripdata_partitioned_clustered'
  AND partition_id IS NOT NULL  -- Exclude __NULL__ partition
ORDER BY
  partition_id DESC
LIMIT 20;

-- Expected: ~180 partitions (Jan 2024 - Jun 2024 = ~180 days)


-- Check clustering info
SELECT
  table_name,
  table_type,
  clustering_ordinal_position,
  column_name
FROM
  `electric-cosine-485318-f9.o3_warehouse.INFORMATION_SCHEMA.TABLE_OPTIONS`
WHERE
  table_name = 'yellow_tripdata_partitioned_clustered'
  AND option_name = 'clustering';


-- ============================================================================
-- TEST QUERY: Demonstrate the optimization
-- ============================================================================
-- This is the type of query that benefits from our strategy:

SELECT
  VendorID,
  COUNT(*) as trip_count,
  ROUND(AVG(fare_amount), 2) as avg_fare,
  ROUND(AVG(trip_distance), 2) as avg_distance
FROM
  `electric-cosine-485318-f9.o3_warehouse.yellow_tripdata_partitioned_clustered`
WHERE
  -- Filter by date → Uses PARTITION (scans only March 1-15)
  DATE(tpep_dropoff_datetime) BETWEEN '2024-03-01' AND '2024-03-15'
GROUP BY
  VendorID
ORDER BY
  VendorID;  -- Order by VendorID → Uses CLUSTERING (already sorted!)

-- This query benefits from BOTH optimizations:
--   1. Partition pruning: Only scans 15 days of data (not all 180 days)
--   2. Clustering: Data already sorted by VendorID within each partition


-- ============================================================================
-- PARTITIONING vs CLUSTERING: When to use what?
-- ============================================================================
--
-- ┌─────────────────┬──────────────────────────────────────────────────┐
-- │   Feature       │   When to Use                                    │
-- ├─────────────────┼──────────────────────────────────────────────────┤
-- │ PARTITION       │ - Always filter by date/timestamp/integer        │
-- │                 │ - Time-series data (logs, events, transactions) │
-- │                 │ - Want to reduce data scanned significantly      │
-- │                 │ - Max benefit: Can skip entire partitions        │
-- │                 │ - Limit: Max 4000 partitions                     │
-- ├─────────────────┼──────────────────────────────────────────────────┤
-- │ CLUSTER         │ - Filter by categorical columns (VendorID, etc) │
-- │                 │ - ORDER BY these columns frequently              │
-- │                 │ - GROUP BY these columns frequently              │
-- │                 │ - Benefit: Data pre-sorted within partitions     │
-- │                 │ - Limit: Max 4 clustering columns                │
-- └─────────────────┴──────────────────────────────────────────────────┘
--
-- Combined Strategy (BEST):
--   PARTITION BY <time_column>    -- Primary filter (date/timestamp)
--   CLUSTER BY <col1>, <col2>     -- Secondary filters (most selective first)
--
-- Example Use Cases:
--   - Web logs: PARTITION BY DATE(timestamp), CLUSTER BY user_id, page_url
--   - Sales data: PARTITION BY DATE(sale_date), CLUSTER BY region, product_id
--   - Taxi trips: PARTITION BY DATE(dropoff_time), CLUSTER BY vendor, zone
-- ============================================================================


-- ============================================================================
-- WHY NOT the other options?
-- ============================================================================
--
-- Option (b): Cluster on tpep_dropoff_datetime and Cluster on VendorID
--   ❌ Cannot cluster by two separate columns in this syntax
--   ❌ Clustering on date is less efficient than partitioning
--   ❌ No partition pruning → Still scans all data
--
-- Option (c): Cluster on tpep_dropoff_datetime, Partition by VendorID
--   ❌ Cannot partition by low-cardinality column (only 2-3 vendors)
--   ❌ Would create only 2-3 partitions (not useful)
--   ❌ Date filtering wouldn't benefit from partitioning
--
-- Option (d): Partition by tpep_dropoff_datetime and Partition by VendorID
--   ❌ BigQuery doesn't support multi-column partitioning
--   ❌ Can only partition by ONE column
--   ❌ Syntax error
--
-- ============================================================================
