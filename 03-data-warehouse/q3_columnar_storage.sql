-- ============================================================================
-- QUESTION 3: Understanding Columnar Storage
-- ============================================================================
-- Write a query to retrieve the PULocationID from the table (not the
-- external table) in BigQuery. Now write a query to retrieve the
-- PULocationID and DOLocationID on the same table.
--
-- Why are the estimated number of Bytes different?
--
-- Options:
--   a) BigQuery is a columnar database, and it only scans the specific
--      columns requested in the query. Querying two columns (PULocationID,
--      DOLocationID) requires reading more data than querying one column
--      (PULocationID), leading to a higher estimated number of bytes processed.
--
--   b) BigQuery duplicates data across multiple storage partitions, so
--      selecting two columns instead of one requires scanning the table
--      twice, doubling the estimated bytes processed.
--
--   c) BigQuery automatically caches the first queried column, so adding
--      a second column increases processing time but does not affect the
--      estimated bytes scanned.
--
--   d) When selecting multiple columns, BigQuery performs an implicit join
--      operation between them, increasing the estimated bytes processed.
--
-- Correct Answer: (a) - BigQuery only scans columns you request!
-- ============================================================================

-- ============================================================================
-- QUERY 1: Select ONE column (PULocationID)
-- ============================================================================
-- IMPORTANT: Check the estimated bytes BEFORE running!
-- ============================================================================

SELECT
  PULocationID
FROM
  `electric-cosine-485318-f9.o3_warehouse.yellow_tripdata_materialized`;

-- Expected Estimation: ~X MB (note this value)


-- ============================================================================
-- QUERY 2: Select TWO columns (PULocationID, DOLocationID)
-- ============================================================================
-- IMPORTANT: Check the estimated bytes BEFORE running!
-- Compare with Query 1 - you should see roughly DOUBLE the bytes!
-- ============================================================================

SELECT
  PULocationID,
  DOLocationID
FROM
  `electric-cosine-485318-f9.o3_warehouse.yellow_tripdata_materialized`;

-- Expected Estimation: ~2X MB (roughly double Query 1)


-- ============================================================================
-- EXPLANATION: Columnar Storage in BigQuery
-- ============================================================================
--
-- Traditional Row-Based Storage (e.g., MySQL, PostgreSQL):
--   Row 1: [VendorID=1, PULocationID=161, DOLocationID=237, fare=12.50, ...]
--   Row 2: [VendorID=2, PULocationID=186, DOLocationID=239, fare=8.00, ...]
--   Row 3: [VendorID=1, PULocationID=132, DOLocationID=165, fare=15.00, ...]
--
--   To get PULocationID: Must read entire rows, skip unwanted columns
--
-- BigQuery's Columnar Storage (Colossus):
--   Column: VendorID     = [1, 2, 1, 1, 2, ...]
--   Column: PULocationID = [161, 186, 132, 161, ...]
--   Column: DOLocationID = [237, 239, 165, 50, ...]
--   Column: fare_amount  = [12.50, 8.00, 15.00, ...]
--
--   To get PULocationID: Read ONLY the PULocationID column!
--
-- Benefits:
--   1. Only scan columns you need → Lower cost
--   2. Better compression (similar values grouped together)
--   3. Faster aggregations (COUNT, SUM, AVG on single columns)
--
-- This is why:
--   SELECT col1 → Reads X bytes
--   SELECT col1, col2 → Reads ~2X bytes
--   SELECT col1, col2, col3 → Reads ~3X bytes
--   SELECT * → Reads ALL columns (most expensive!)
--
-- Best Practice: NEVER use SELECT * in BigQuery!
-- ============================================================================


-- ============================================================================
-- DEMONSTRATION: Compare SELECT * vs specific columns
-- ============================================================================

-- Query 3: Select ONLY PULocationID (efficient)
SELECT PULocationID
FROM `electric-cosine-485318-f9.o3_warehouse.yellow_tripdata_materialized`
LIMIT 10;
-- Check bytes: Should be small

-- Query 4: Select ALL columns (inefficient)
SELECT *
FROM `electric-cosine-485318-f9.o3_warehouse.yellow_tripdata_materialized`
LIMIT 10;
-- Check bytes: Much larger! (reads all 19 columns)


-- ============================================================================
-- REAL-WORLD IMPACT
-- ============================================================================
-- Table: 20 million rows, 19 columns
--
-- Scenario 1: SELECT PULocationID, DOLocationID
--   - Bytes scanned: ~155 MB
--   - Cost: $0.00 (first 1TB free per month)
--
-- Scenario 2: SELECT *
--   - Bytes scanned: ~1.5 GB (10x more!)
--   - If you run 1000 times: 1.5 TB = $7.50 cost
--
-- Always specify columns! 💰
-- ============================================================================
