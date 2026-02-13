# Module 3: Data Warehouse with BigQuery

**Status:** ✅ Complete
**Student:** Ahmad Naggayev
**Date:** February 12, 2026

---

## 📋 Homework Overview

This module covers BigQuery fundamentals including:
- External tables vs. Materialized tables
- Partitioning and Clustering strategies
- Query optimization techniques
- Columnar storage concepts

**Dataset:** Yellow Taxi Trip Records (January 2024 - June 2024)
**Project ID:** `electric-cosine-485318-f9`
**Dataset:** `03_warehouse`
**GCS Bucket:** `de-zoomcamp-ahmad-2026`

---

## 🚀 Quick Start

**New to this module?** Start here:
1. Read [EXECUTION_GUIDE.md](./EXECUTION_GUIDE.md) for step-by-step instructions
2. Follow the guide to set up GCS bucket and BigQuery dataset
3. Run [setup.sql](./setup.sql) to create all tables
4. Answer each question using the provided SQL files
5. Check [QUICK_REFERENCE.md](./QUICK_REFERENCE.md) for concepts

---

## 🎯 Homework Answers

| Question | Answer | File | Status |
|----------|--------|------|--------|
| Q1: Record Count | **c** (20,332,093) | [q1_count_records.sql](./q1_count_records.sql) | ✅ |
| Q2: Data Read Estimation | **b** (0 MB / 155.12 MB) | [q2_data_estimation.sql](./q2_data_estimation.sql) | ✅ |
| Q3: Columnar Storage | **a** | [q3_columnar_storage.sql](./q3_columnar_storage.sql) | ✅ |
| Q4: Zero Fare Trips | **d** (8,333) | [q4_zero_fare.sql](./q4_zero_fare.sql) | ✅ |
| Q5: Partition & Cluster Strategy | **a** | [q5_partition_cluster_strategy.sql](./q5_partition_cluster_strategy.sql) | ✅ |
| Q6: Partition Benefits | **b** (310.24 MB / 26.84 MB) | [q6_partition_benefits.sql](./q6_partition_benefits.sql) | ✅ |
| Q7: External Table Storage | **c** (GCS Bucket) | [q7_q8_answers.md](./q7_q8_answers.md) | ✅ |
| Q8: Clustering Best Practices | **b** (False) | [q7_q8_answers.md](./q7_q8_answers.md) | ✅ |
| Q9: Table Scan Understanding | 0 MB | [q9_table_scan.sql](./q9_table_scan.sql) | ✅ |

---

## 🗂️ Project Structure

```
03-data-warehouse/
├── README.md                              # This file - Overview and answers
├── EXECUTION_GUIDE.md                     # ⭐ START HERE - Step-by-step guide
├── QUICK_REFERENCE.md                     # Cheat sheet for BigQuery concepts
│
├── setup.sql                              # Initial table creation (run first)
│
├── q1_count_records.sql                   # Question 1: Count all records
├── q2_data_estimation.sql                 # Question 2: External vs Materialized
├── q3_columnar_storage.sql                # Question 3: Columnar storage benefits
├── q4_zero_fare.sql                       # Question 4: Zero fare trips
├── q5_partition_cluster_strategy.sql      # Question 5: Optimal strategy
├── q6_partition_benefits.sql              # Question 6: Partition pruning
├── q7_q8_answers.md                       # Questions 7 & 8: Conceptual answers
├── q9_table_scan.sql                      # Question 9: Metadata optimization
│
└── notes/                                 # Deep dive learning notes
    ├── partitioning.md                    # Complete guide to partitioning
    └── clustering.md                      # Complete guide to clustering
```

---

## 🚀 Setup Instructions

### 1. GCP Configuration
- Project ID: `electric-cosine-485318-f9`
- Dataset: `o3_warehouse` (to be created)
- Region: `us-west1`

### 2. Create BigQuery Dataset
```bash
bq mk --dataset --location=us-west1 electric-cosine-485318-f9:o3_warehouse
```

### 3. Upload Data to GCS
- Upload 6 parquet files (yellow_tripdata_2024-01 to 2024-06) to GCS bucket
- Bucket path: `gs://de-zoomcamp-bucket-ahmad/yellow_tripdata_2024-*.parquet`

### 4. Run Setup SQL
Execute `setup.sql` to create all necessary tables.

---

## 📚 Key Concepts

### External Tables
- Metadata stored in BigQuery
- Data remains in GCS
- No ingestion cost
- Slower query performance

### Materialized Tables
- Data stored in BigQuery native storage
- Faster query performance
- Storage costs apply
- Better for frequent queries

### Partitioning
- Divides table by date/time column
- Reduces data scanned in queries
- Max 4000 partitions
- Best for time-series data

### Clustering
- Sorts data within partitions
- Max 4 clustering columns
- Order matters (most selective first)
- Best for frequently filtered columns

---

## 🔗 Resources

- [BigQuery Documentation](https://cloud.google.com/bigquery/docs)
- [Partitioning Guide](https://cloud.google.com/bigquery/docs/partitioned-tables)
- [Clustering Guide](https://cloud.google.com/bigquery/docs/clustered-tables)
- [NYC Taxi Data](https://www.nyc.gov/site/tlc/about/tlc-trip-record-data.page)

---

**Last Updated:** February 12, 2026
