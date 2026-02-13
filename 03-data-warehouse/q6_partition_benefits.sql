-- ============================================================================
-- QUESTION 6: Partition Benefits
-- ============================================================================
-- Write a query to retrieve the distinct VendorIDs between
-- tpep_dropoff_datetime 2024-03-01 and 2024-03-15 (inclusive).
--
-- Use the materialized table you created earlier in your FROM clause and
-- note the estimated bytes. Now change the table in the FROM clause to the
-- partitioned table you created for question 5 and note the estimated bytes
-- processed. What are these values?
--
-- Options:
--   a) 12.47 MB for non-partitioned table and 326.42 MB for the partitioned table
--   b) 310.24 MB for non-partitioned table and 26.84 MB for the partitioned table
--   c) 5.87 MB for non-partitioned table and 0 MB for the partitioned table
--   d) 310.31 MB for non-partitioned table and 285.64 MB for the partitioned table
--
-- Expected Answer: (b) - Partitioned table processes MUCH less data!
-- ============================================================================

-- ============================================================================
-- QUERY 1: Non-Partitioned Table (Baseline)
-- ============================================================================
-- IMPORTANT: Do NOT run yet! Check estimated bytes FIRST!
-- ============================================================================

SELECT DISTINCT VendorID
FROM `electric-cosine-485318-f9.o3_warehouse.yellow_tripdata_materialized`
WHERE DATE(tpep_dropoff_datetime) BETWEEN '2024-03-01' AND '2024-03-15';

-- Expected Estimation: ~310 MB (scans entire table!)
--
-- Why so much?
--   - Table has 6 months of data (Jan-Jun 2024)
--   - Query needs data from only 15 days in March
--   - But BigQuery must scan ALL dates to find March 1-15
--   - No partitioning = Must read tpep_dropoff_datetime column for all rows
--   - Result: Scans ~310 MB


-- ============================================================================
-- QUERY 2: Partitioned + Clustered Table (Optimized)
-- ============================================================================
-- IMPORTANT: Do NOT run yet! Check estimated bytes FIRST!
-- Compare with Query 1 - you should see MASSIVE reduction!
-- ============================================================================

SELECT DISTINCT VendorID
FROM `electric-cosine-485318-f9.o3_warehouse.yellow_tripdata_partitioned_clustered`
WHERE DATE(tpep_dropoff_datetime) BETWEEN '2024-03-01' AND '2024-03-15';

-- Expected Estimation: ~27 MB (90% less data scanned!)
--
-- Why so little?
--   - Table is partitioned by DATE(tpep_dropoff_datetime)
--   - BigQuery uses "partition pruning"
--   - Only reads partitions for March 1-15 (15 partitions)
--   - Skips partitions for Jan, Feb, Apr, May, Jun
--   - Result: Scans only ~27 MB (15 days out of 180 days ≈ 8% of data)


-- ============================================================================
-- EXPLANATION: Partition Pruning
-- ============================================================================
--
-- Non-Partitioned Table:
--   ┌─────────────────────────────────────────────────┐
--   │ All Data (Jan - Jun 2024)                       │
--   │ ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━│
--   │ Must scan entire table to find March 1-15       │
--   │ Bytes scanned: 310 MB                           │
--   └─────────────────────────────────────────────────┘
--
-- Partitioned Table:
--   ┌────────┬────────┬────────┬────────┬────────┬────────┐
--   │  Jan   │  Feb   │  Mar   │  Apr   │  May   │  Jun   │
--   │ (skip) │ (skip) │ ✓✓✓✓✓ │ (skip) │ (skip) │ (skip) │
--   └────────┴────────┴────────┴────────┴────────┴────────┘
--                         └─ Only scan March 1-15
--                            Bytes scanned: 27 MB
--
-- Benefit: 310 MB → 27 MB = ~91% reduction!
-- ============================================================================


-- ============================================================================
-- COST SAVINGS CALCULATION
-- ============================================================================
-- BigQuery Pricing: $6.25 per TB scanned (after 1st TB free per month)
--
-- Scenario: Running this query 1000 times per month
--
-- Non-Partitioned Table:
--   - 310 MB × 1000 = 310 GB = 0.31 TB
--   - Cost: $0 (within free 1 TB tier)
--
-- Partitioned Table:
--   - 27 MB × 1000 = 27 GB = 0.027 TB
--   - Cost: $0 (within free 1 TB tier)
--
-- If query runs 10,000 times per month:
--
-- Non-Partitioned:
--   - 310 MB × 10,000 = 3.1 TB
--   - Cost: (3.1 TB - 1 TB free) × $6.25 = $13.13
--
-- Partitioned:
--   - 27 MB × 10,000 = 0.27 TB
--   - Cost: $0 (still within free tier!)
--
-- Savings: $13.13 per month
-- Annual Savings: $157.56
--
-- For large organizations with millions of queries:
--   Partitioning can save $10,000s per year! 💰
-- ============================================================================


-- ============================================================================
-- VERIFY PARTITION PRUNING (Advanced)
-- ============================================================================
-- Check which partitions are actually scanned

-- 1. Get partition details for March 2024
SELECT
  partition_id,
  total_rows,
  ROUND(total_logical_bytes / 1024 / 1024, 2) as size_mb
FROM
  `electric-cosine-485318-f9.o3_warehouse.INFORMATION_SCHEMA.PARTITIONS`
WHERE
  table_name = 'yellow_tripdata_partitioned_clustered'
  AND partition_id BETWEEN '20240301' AND '20240315'  -- March 1-15
ORDER BY
  partition_id;

-- Expected: 15 rows (one per day)


-- 2. Sum up size of March 1-15 partitions
SELECT
  COUNT(*) as num_partitions,
  SUM(total_rows) as total_rows_scanned,
  ROUND(SUM(total_logical_bytes) / 1024 / 1024, 2) as total_mb
FROM
  `electric-cosine-485318-f9.o3_warehouse.INFORMATION_SCHEMA.PARTITIONS`
WHERE
  table_name = 'yellow_tripdata_partitioned_clustered'
  AND partition_id BETWEEN '20240301' AND '20240315';

-- This should approximately match the "estimated bytes" from Query 2!


-- ============================================================================
-- ADDITIONAL COMPARISON: Run both queries with EXPLAIN
-- ============================================================================
-- BigQuery has an EXPLAIN feature to show execution plan

-- Option 1: Use BigQuery UI
--   1. Click "EXECUTION DETAILS" tab after running query
--   2. See "Slot time consumed", "Shuffle", "Partitions scanned"

-- Option 2: Use EXPLAIN in SQL (doesn't execute, just plans)
-- Note: EXPLAIN syntax may vary; check BigQuery docs


-- ============================================================================
-- KEY TAKEAWAY
-- ============================================================================
-- Partitioning is ESSENTIAL for:
--   ✓ Time-series data (logs, events, transactions, trips)
--   ✓ Queries that filter by date ranges
--   ✓ Reducing costs in production systems
--   ✓ Improving query performance (less data = faster scan)
--
-- Always partition when:
--   - Your data has a timestamp/date column
--   - You frequently filter by date ranges
--   - Your table is > 1 GB
--
-- The bigger the table, the bigger the savings! 📊
-- ============================================================================
