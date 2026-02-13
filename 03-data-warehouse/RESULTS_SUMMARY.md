# Module 3: BigQuery Homework - Results Summary

**Completion Date:** February 13, 2026  
**Status:** ✅ All Questions Answered

---

## 🎯 Final Answers

| # | Question | Answer | Details |
|---|----------|--------|---------|
| 1 | Record Count | **c** | 20,332,093 rows |
| 2 | Data Estimation | **b** | External: 0 MB, Materialized: 155.12 MB |
| 3 | Columnar Storage | **a** | BigQuery scans only requested columns |
| 4 | Zero Fare Trips | **d** | 8,333 trips |
| 5 | Partition & Cluster Strategy | **a** | Partition by date, Cluster by VendorID |
| 6 | Partition Benefits | **b** | 310.24 MB → 26.84 MB (91% reduction) |
| 7 | External Table Storage | **c** | GCS Bucket |
| 8 | Clustering Best Practice | **b** | False - not always beneficial |
| 9 | Metadata Query (bonus) | - | 0 MB (uses metadata) |

---

## 📊 Infrastructure Setup

### GCS Bucket
- **Name:** `de-zoomcamp-ahmad-2026`
- **Location:** us-west1
- **Data:** 6 parquet files (326.1 MB total)
  - yellow_tripdata_2024-01.parquet (47.65 MiB)
  - yellow_tripdata_2024-02.parquet (48.02 MiB)
  - yellow_tripdata_2024-03.parquet (57.30 MiB)
  - yellow_tripdata_2024-04.parquet (56.39 MiB)
  - yellow_tripdata_2024-05.parquet (59.66 MiB)
  - yellow_tripdata_2024-06.parquet (57.09 MiB)

### BigQuery Dataset
- **Project:** electric-cosine-485318-f9
- **Dataset:** 03_warehouse
- **Location:** us-west1

### Tables Created
1. **yellow_tripdata_external** (EXTERNAL)
   - Data stored in GCS
   - No BigQuery storage cost
   - Slower query performance

2. **yellow_tripdata_materialized** (TABLE)
   - Standard BigQuery table
   - No partitioning or clustering
   - Baseline for comparison

3. **yellow_tripdata_partitioned** (TABLE)
   - Partitioned by DATE(tpep_dropoff_datetime)
   - Improves query performance for date filters

4. **yellow_tripdata_partitioned_clustered** (TABLE)
   - Partitioned by DATE(tpep_dropoff_datetime)
   - Clustered by VendorID
   - **Optimal table for homework queries**
   - 91% reduction in data scanned vs non-partitioned

---

## 📈 Key Performance Insights

### Q6: Partition Pruning Impact
**Query:** SELECT DISTINCT VendorID WHERE date BETWEEN '2024-03-01' AND '2024-03-15'

| Table Type | Bytes Processed | Reduction |
|------------|-----------------|-----------|
| Non-partitioned | 310.24 MB | - |
| Partitioned + Clustered | 26.84 MB | **91%** |

**Takeaway:** Partitioning reduces costs and improves performance dramatically!

### Q2: External vs Materialized Estimation
**Query:** COUNT(DISTINCT PULocationID)

| Table Type | Estimated Bytes | Notes |
|------------|-----------------|-------|
| External | 0 MB | Cannot estimate (data in GCS) |
| Materialized | 155.12 MB | Accurate column-level estimation |

**Takeaway:** Materialized tables provide better query planning!

### Q9: Metadata Optimization
**Query:** SELECT COUNT(*)

| Bytes Processed | Reason |
|-----------------|--------|
| 0 MB | BigQuery stores row count as metadata |

**Takeaway:** COUNT(*) without WHERE clause is free!

---

## 🧠 Concepts Mastered

✅ **External Tables**
- Metadata in BigQuery, data in GCS
- No ingestion cost, slower queries
- Cannot estimate query costs accurately

✅ **Partitioning**
- Divides table by date/time column
- Dramatically reduces data scanned (91% in our case!)
- Max 4,000 partitions per table

✅ **Clustering**
- Sorts data within partitions
- Max 4 clustering columns
- Order matters (most selective first)

✅ **Columnar Storage**
- BigQuery only scans requested columns
- External: 0 MB, Materialized: 155.12 MB for single column

✅ **Query Optimization**
- Use partitioned tables for time-series data
- Cluster on frequently filtered columns
- Check estimated bytes before running expensive queries

---

## 🚀 Commands Used

### Download Data
```bash
cd ~/data/yellow_taxi_2024
for month in {01..06}; do
  wget https://d37ci6vzurychx.cloudfront.net/trip-data/yellow_tripdata_2024-${month}.parquet
done
```

### Upload to GCS
```bash
gsutil -m cp ~/data/yellow_taxi_2024/*.parquet gs://de-zoomcamp-ahmad-2026/yellow_taxi/
```

### Create Tables
```bash
# External table
bq query --use_legacy_sql=false "CREATE OR REPLACE EXTERNAL TABLE ..."

# Materialized table
bq query --use_legacy_sql=false "CREATE OR REPLACE TABLE ... AS SELECT * FROM ..."

# Partitioned table
bq query --use_legacy_sql=false "CREATE OR REPLACE TABLE ... PARTITION BY DATE(...) AS ..."

# Partitioned + Clustered table
bq query --use_legacy_sql=false "CREATE OR REPLACE TABLE ... PARTITION BY ... CLUSTER BY ... AS ..."
```

### Estimate Query Cost
```bash
bq query --use_legacy_sql=false --dry_run "SELECT ..."
```

---

## ✅ Next Steps

1. ✅ All answers documented
2. ✅ Infrastructure created
3. ⏳ Submit homework at: https://courses.datatalks.club/de-zoomcamp-2026/homework/hw3
4. ⏳ (Optional) Cleanup resources after grading

---

**Generated:** February 13, 2026  
**By:** Claude Code + Ahmad Naggayev
