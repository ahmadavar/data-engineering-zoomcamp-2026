-- ============================================================================
-- MODULE 3: DATA WAREHOUSE SETUP
-- ============================================================================
-- This file creates all necessary tables for the homework
-- Run these queries in order in the BigQuery Console
--
-- Project ID: electric-cosine-485318-f9
-- Dataset: o3_warehouse (create this first)
-- Data Source: GCS bucket with yellow taxi parquet files
-- ============================================================================

-- ============================================================================
-- PREREQUISITES
-- ============================================================================
-- 1. Create dataset (run in terminal or BigQuery console):
--    bq mk --dataset --location=us-west1 electric-cosine-485318-f9:o3_warehouse
--
-- 2. Create GCS bucket:
--    gsutil mb -l us-west1 gs://de-zoomcamp-ahmad-2026/
--
-- 3. Upload parquet files to GCS:
--    - Download from: https://www.nyc.gov/site/tlc/about/tlc-trip-record-data.page
--    - Files: yellow_tripdata_2024-01.parquet through yellow_tripdata_2024-06.parquet
--    - Upload to: gs://de-zoomcamp-ahmad-2026/yellow_taxi/
-- ============================================================================


-- ============================================================================
-- STEP 1: CREATE EXTERNAL TABLE
-- ============================================================================
-- External tables store metadata in BigQuery but data remains in GCS
-- Benefits: No storage cost, query data directly from GCS
-- Drawbacks: Slower performance, no caching, can't partition
-- ============================================================================

CREATE OR REPLACE EXTERNAL TABLE `electric-cosine-485318-f9.o3_warehouse.yellow_tripdata_external`
OPTIONS (
  format = 'PARQUET',
  uris = ['gs://de-zoomcamp-ahmad-2026/yellow_taxi/yellow_tripdata_2024-*.parquet']
);

-- Verify external table
SELECT COUNT(*) as total_rows FROM `electric-cosine-485318-f9.o3_warehouse.yellow_tripdata_external`;


-- ============================================================================
-- STEP 2: CREATE MATERIALIZED TABLE (NON-PARTITIONED, NON-CLUSTERED)
-- ============================================================================
-- This is a standard BigQuery table with all data stored in BigQuery
-- Used for baseline comparison against partitioned/clustered tables
-- ============================================================================

CREATE OR REPLACE TABLE `electric-cosine-485318-f9.o3_warehouse.yellow_tripdata_materialized` AS
SELECT * FROM `electric-cosine-485318-f9.o3_warehouse.yellow_tripdata_external`;

-- Verify materialized table
SELECT COUNT(*) as total_rows FROM `electric-cosine-485318-f9.o3_warehouse.yellow_tripdata_materialized`;


-- ============================================================================
-- STEP 3: CREATE PARTITIONED TABLE
-- ============================================================================
-- Partitioning divides the table into segments based on a column value
-- Here we partition by DATE(tpep_dropoff_datetime)
--
-- Benefits:
--   - Queries filtering by date only scan relevant partitions
--   - Dramatically reduces cost and improves performance
--   - Each partition = one day of data
--
-- When to use:
--   - Frequent queries filter by date/timestamp
--   - Working with time-series data (logs, events, trips)
-- ============================================================================

CREATE OR REPLACE TABLE `electric-cosine-485318-f9.o3_warehouse.yellow_tripdata_partitioned`
PARTITION BY DATE(tpep_dropoff_datetime) AS
SELECT * FROM `electric-cosine-485318-f9.o3_warehouse.yellow_tripdata_external`;

-- Verify partitioned table
SELECT COUNT(*) as total_rows FROM `electric-cosine-485318-f9.o3_warehouse.yellow_tripdata_partitioned`;

-- View partition information
SELECT
  table_name,
  partition_id,
  total_rows,
  total_logical_bytes / 1024 / 1024 as size_mb
FROM `electric-cosine-485318-f9.o3_warehouse.INFORMATION_SCHEMA.PARTITIONS`
WHERE table_name = 'yellow_tripdata_partitioned'
ORDER BY total_rows DESC
LIMIT 20;


-- ============================================================================
-- STEP 4: CREATE PARTITIONED + CLUSTERED TABLE
-- ============================================================================
-- This is the OPTIMAL table for our homework queries
--
-- Partitioning Strategy: DATE(tpep_dropoff_datetime)
--   - Queries always filter by dropoff date range
--   - Reduces data scanned by only reading relevant days
--
-- Clustering Strategy: VendorID
--   - Within each partition, data is sorted by VendorID
--   - Queries that filter/order by VendorID benefit from this
--   - Can cluster by up to 4 columns (order matters!)
--
-- Combined Benefits:
--   - Date filter → Only scan relevant partitions
--   - VendorID filter → Only scan relevant clusters within partitions
--   - Result: Minimal data scanned = Lower cost + Faster queries
-- ============================================================================

CREATE OR REPLACE TABLE `electric-cosine-485318-f9.o3_warehouse.yellow_tripdata_partitioned_clustered`
PARTITION BY DATE(tpep_dropoff_datetime)
CLUSTER BY VendorID AS
SELECT * FROM `electric-cosine-485318-f9.o3_warehouse.yellow_tripdata_external`;

-- Verify partitioned + clustered table
SELECT COUNT(*) as total_rows FROM `electric-cosine-485318-f9.o3_warehouse.yellow_tripdata_partitioned_clustered`;


-- ============================================================================
-- STEP 5: VIEW ALL CREATED TABLES
-- ============================================================================
SELECT
  table_name,
  CASE
    WHEN table_type = 'EXTERNAL' THEN 'External (GCS)'
    ELSE 'Materialized (BigQuery)'
  END as storage_type,
  row_count,
  ROUND(size_bytes / 1024 / 1024, 2) as size_mb,
  creation_time
FROM `electric-cosine-485318-f9.o3_warehouse.__TABLES__`
ORDER BY creation_time DESC;


-- ============================================================================
-- SETUP COMPLETE! ✅
-- ============================================================================
-- You now have 4 tables ready for the homework:
--   1. yellow_tripdata_external (External table in GCS)
--   2. yellow_tripdata_materialized (Standard table, no optimization)
--   3. yellow_tripdata_partitioned (Partitioned by date)
--   4. yellow_tripdata_partitioned_clustered (Partitioned + Clustered)
--
-- Next steps:
--   - Run questions Q1 through Q9
--   - Compare query performance across different table types
--   - Observe estimated bytes scanned for each query
-- ============================================================================
