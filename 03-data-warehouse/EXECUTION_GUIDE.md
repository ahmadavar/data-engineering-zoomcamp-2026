# Module 3: Step-by-Step Execution Guide

This guide walks you through completing the Module 3 homework from start to finish.

---

## 🎯 Prerequisites Checklist

Before starting, ensure you have:

- [ ] GCP Project: `electric-cosine-485318-f9` ✓ (Already configured)
- [ ] BigQuery API enabled
- [ ] Storage API enabled
- [ ] Permissions: BigQuery Admin, Storage Admin
- [ ] Yellow Taxi data files (2024-01 through 2024-06)

---

## 📋 Step-by-Step Execution

### STEP 1: Enable Required GCP APIs

```bash
# Enable BigQuery API
gcloud services enable bigquery.googleapis.com

# Enable Cloud Storage API
gcloud services enable storage-api.googleapis.com

# Verify enabled services
gcloud services list --enabled | grep -E 'bigquery|storage'
```

**Expected Output:**
```
bigquery.googleapis.com
storage-api.googleapis.com
```

---

### STEP 2: Create GCS Bucket

```bash
# Create bucket in same region as BigQuery dataset
gsutil mb -l us-west1 gs://de-zoomcamp-ahmad-2026/

# Verify bucket created
gsutil ls

# Create folder for yellow taxi data
gsutil ls gs://de-zoomcamp-ahmad-2026/
```

**Expected Output:**
```
Creating gs://de-zoomcamp-ahmad-2026/...
```

---

### STEP 3: Download Yellow Taxi Data

You need to download 6 parquet files from NYC TLC website.

**Option A: Manual Download (Browser)**
1. Visit: https://www.nyc.gov/site/tlc/about/tlc-trip-record-data.page
2. Download these files:
   - `yellow_tripdata_2024-01.parquet`
   - `yellow_tripdata_2024-02.parquet`
   - `yellow_tripdata_2024-03.parquet`
   - `yellow_tripdata_2024-04.parquet`
   - `yellow_tripdata_2024-05.parquet`
   - `yellow_tripdata_2024-06.parquet`

**Option B: Command Line (Faster)**
```bash
# Create local directory
mkdir -p ~/data/yellow_taxi_2024

# Download files using wget
cd ~/data/yellow_taxi_2024

for month in {01..06}; do
  wget https://d37ci6vzurychx.cloudfront.net/trip-data/yellow_tripdata_2024-${month}.parquet
done

# Verify downloads
ls -lh
```

**Expected Output:**
```
-rw-r--r-- 1 user user  45M yellow_tripdata_2024-01.parquet
-rw-r--r-- 1 user user  42M yellow_tripdata_2024-02.parquet
-rw-r--r-- 1 user user  49M yellow_tripdata_2024-03.parquet
...
```

---

### STEP 4: Upload Data to GCS

```bash
# Upload all parquet files to GCS
gsutil -m cp ~/data/yellow_taxi_2024/*.parquet gs://de-zoomcamp-ahmad-2026/yellow_taxi/

# Verify upload
gsutil ls gs://de-zoomcamp-ahmad-2026/yellow_taxi/

# Check file sizes
gsutil du -sh gs://de-zoomcamp-ahmad-2026/yellow_taxi/
```

**Expected Output:**
```
gs://de-zoomcamp-ahmad-2026/yellow_taxi/yellow_tripdata_2024-01.parquet
gs://de-zoomcamp-ahmad-2026/yellow_taxi/yellow_tripdata_2024-02.parquet
...
Total: ~270 MB
```

---

### STEP 5: Create BigQuery Dataset

```bash
# Create dataset
bq mk --dataset --location=us-west1 electric-cosine-485318-f9:o3_warehouse

# Verify dataset created
bq ls electric-cosine-485318-f9:

# Show dataset details
bq show electric-cosine-485318-f9:o3_warehouse
```

**Expected Output:**
```
Dataset 'electric-cosine-485318-f9:o3_warehouse' successfully created.
```

---

### STEP 6: Create Tables in BigQuery

**Important:** Update the GCS bucket path in `setup.sql` if you used a different bucket name!

1. Open BigQuery Console: https://console.cloud.google.com/bigquery
2. Select project: `electric-cosine-485318-f9`
3. Open a new query tab
4. Copy contents of `setup.sql`
5. **Before running**, update the bucket path on line 39:
   ```sql
   uris = ['gs://YOUR-BUCKET-NAME/yellow_taxi/yellow_tripdata_2024-*.parquet']
   ```
6. Run each CREATE TABLE statement ONE BY ONE (not all at once)

**Execution Order:**
```
1. CREATE EXTERNAL TABLE (yellow_tripdata_external)
2. CREATE MATERIALIZED TABLE (yellow_tripdata_materialized)
3. CREATE PARTITIONED TABLE (yellow_tripdata_partitioned)
4. CREATE PARTITIONED + CLUSTERED TABLE (yellow_tripdata_partitioned_clustered)
```

**After each CREATE statement, verify:**
```sql
SELECT COUNT(*) FROM `electric-cosine-485318-f9.o3_warehouse.TABLE_NAME`;
```

**Expected Count:** Should be the same across all tables (answer to Q1!)

---

### STEP 7: Answer Question 1 - Record Count

Open `q1_count_records.sql` and run the main query:

```sql
SELECT
  COUNT(*) as total_records,
  FORMAT("%'d", COUNT(*)) as formatted_count
FROM
  `electric-cosine-485318-f9.o3_warehouse.yellow_tripdata_materialized`;
```

**Write down your answer:** _____________

**Match it with:**
- a) 65,623
- b) 840,402
- c) 20,332,093
- d) 85,431,289

**Your Answer:** ___

---

### STEP 8: Answer Question 2 - Data Estimation

Open `q2_data_estimation.sql`.

**For External Table:**
1. Type (don't run) the query in BigQuery
2. Click the ✓ validator button OR look at query details
3. Note the "This query will process __ bytes" message
4. Write down: External Table = _______ MB

**For Materialized Table:**
1. Type (don't run) the query
2. Note the estimated bytes
3. Write down: Materialized Table = _______ MB

**Match it with:**
- a) 18.82 MB for the External Table and 47.60 MB for the Materialized Table
- b) 0 MB for the External Table and 155.12 MB for the Materialized Table
- c) 2.14 GB for the External Table and 0MB for the Materialized Table
- d) 0 MB for the External Table and 0MB for the Materialized Table

**Your Answer:** ___

---

### STEP 9: Answer Question 3 - Columnar Storage

Open `q3_columnar_storage.sql`.

**Query 1: One column**
```sql
SELECT PULocationID FROM ...
```
Estimated bytes: _______ MB

**Query 2: Two columns**
```sql
SELECT PULocationID, DOLocationID FROM ...
```
Estimated bytes: _______ MB

**Question:** Why are the estimates different?

**Your Answer:** ___ (Should be **a**: BigQuery is columnar, only scans requested columns)

---

### STEP 10: Answer Question 4 - Zero Fare Trips

Open `q4_zero_fare.sql` and run:

```sql
SELECT COUNT(*) as zero_fare_trips
FROM `electric-cosine-485318-f9.o3_warehouse.yellow_tripdata_materialized`
WHERE fare_amount = 0;
```

**Write down your answer:** _____________

**Match it with:**
- a) 128,210
- b) 546,578
- c) 20,188,016
- d) 8,333

**Your Answer:** ___

---

### STEP 11: Answer Question 5 - Strategy

Open `q5_partition_cluster_strategy.sql`.

**Question:** If queries always filter by `tpep_dropoff_datetime` and order by `VendorID`, what's the best strategy?

**Options:**
- a) Partition by tpep_dropoff_datetime and Cluster on VendorID
- b) Cluster on by tpep_dropoff_datetime and Cluster on VendorID
- c) Cluster on tpep_dropoff_datetime Partition by VendorID
- d) Partition by tpep_dropoff_datetime and Partition by VendorID

**Correct Answer:** ___a___ (Already created this table in setup!)

**Reasoning:**
- Filter by date → PARTITION by date (reduces scanned data)
- Order by VendorID → CLUSTER by VendorID (sorts data)
- Can only partition by 1 column, cluster by up to 4

---

### STEP 12: Answer Question 6 - Partition Benefits

Open `q6_partition_benefits.sql`.

**Query 1: Non-partitioned**
```sql
SELECT DISTINCT VendorID
FROM `...yellow_tripdata_materialized`
WHERE DATE(tpep_dropoff_datetime) BETWEEN '2024-03-01' AND '2024-03-15';
```
Check estimated bytes (DON'T RUN): _______ MB

**Query 2: Partitioned**
```sql
SELECT DISTINCT VendorID
FROM `...yellow_tripdata_partitioned_clustered`
WHERE DATE(tpep_dropoff_datetime) BETWEEN '2024-03-01' AND '2024-03-15';
```
Check estimated bytes (DON'T RUN): _______ MB

**Match your values with:**
- a) 12.47 MB for non-partitioned and 326.42 MB for partitioned
- b) 310.24 MB for non-partitioned and 26.84 MB for partitioned
- c) 5.87 MB for non-partitioned and 0 MB for partitioned
- d) 310.31 MB for non-partitioned and 285.64 MB for partitioned

**Your Answer:** ___ (Should be **b**: Partitioning dramatically reduces scanned data!)

---

### STEP 13: Answer Question 7 - Storage Location

**Question:** Where is the data stored in the External Table you created?

**Options:**
- a) Big Query
- b) Container Registry
- c) GCP Bucket
- d) Big Table

**Your Answer:** ___c___ (GCS Bucket - data stays in Cloud Storage!)

---

### STEP 14: Answer Question 8 - Clustering Best Practices

**Question:** It is best practice in Big Query to always cluster your data:

**Options:**
- a) True
- b) False

**Your Answer:** ___b___ (False)

**Reasoning:**
- Clustering only helps for tables > 1 GB
- Must filter/order by the clustered columns
- Don't cluster small tables or infrequently queried columns
- Use when you have specific, predictable query patterns

---

### STEP 15: Answer Question 9 - Table Scan (No Points)

Open `q9_table_scan.sql` and type (don't run):

```sql
SELECT COUNT(*) FROM `...yellow_tripdata_materialized`;
```

**Check estimated bytes:** _______ MB (Should be 0 MB or very small!)

**Why?**
BigQuery stores row count as metadata. For `COUNT(*)` without WHERE clause, it returns the count from metadata without scanning any data!

---

## 🎉 Homework Complete!

### Summary of Answers:

| Question | Your Answer | Concept |
|----------|-------------|---------|
| Q1 | _____ | Record counting |
| Q2 | _____ | External vs Materialized estimation |
| Q3 | **a** | Columnar storage |
| Q4 | _____ | Filtering with WHERE |
| Q5 | **a** | Partition + Cluster strategy |
| Q6 | _____ | Partition pruning benefits |
| Q7 | **c** | External table storage |
| Q8 | **b** | Clustering best practices |
| Q9 | - | Metadata optimization |

---

## 📤 Submission

1. Fill in your answers in the README.md
2. Commit all SQL files to GitHub
3. Submit at: https://courses.datatalks.club/de-zoomcamp-2026/homework/hw3

---

## 🧹 Cleanup (Optional)

After homework submission, if you want to delete resources:

```bash
# Delete BigQuery dataset (deletes all tables)
bq rm -r -f electric-cosine-485318-f9:o3_warehouse

# Delete GCS bucket and data
gsutil -m rm -r gs://de-zoomcamp-ahmad-2026/

# Verify deletion
bq ls
gsutil ls
```

**Warning:** This permanently deletes all data! Only do this after submission.

---

## 🎓 Key Learnings Summary

### Concepts Mastered:
✅ External vs. Materialized tables
✅ Partitioning strategies
✅ Clustering strategies
✅ Columnar storage benefits
✅ Query optimization techniques
✅ Cost estimation in BigQuery
✅ Partition pruning
✅ Metadata vs. data scanning

### Best Practices:
- Never use `SELECT *` in production
- Always partition time-series data
- Cluster on frequently filtered columns
- Check estimated bytes before running queries
- Use materialized tables for frequent queries
- Use external tables for infrequent access

---

**Good luck with your homework! 🚀**
