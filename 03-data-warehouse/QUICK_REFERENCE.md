# BigQuery Quick Reference Cheat Sheet

---

## 🔑 Key Concepts

### External vs. Materialized Tables

| Feature | External Table | Materialized Table |
|---------|---------------|-------------------|
| **Data Location** | GCS Bucket | BigQuery Storage |
| **Storage Cost** | None (pay for GCS) | Yes (pay for BQ storage) |
| **Query Speed** | Slower | Faster |
| **Caching** | No | Yes |
| **Partitioning** | No | Yes |
| **Clustering** | No | Yes |
| **Use Case** | Infrequent queries | Frequent queries |

---

## 📊 Partitioning

### What is it?
Divides table into segments based on a column (date, timestamp, or integer).

### When to use?
- Time-series data (logs, events, trips)
- Queries always filter by date/timestamp
- Table size > 1 GB

### Benefits:
- ✅ Reduced data scanned (partition pruning)
- ✅ Lower query costs
- ✅ Faster queries
- ✅ Max 4000 partitions

### Syntax:
```sql
CREATE TABLE table_name
PARTITION BY DATE(timestamp_column) AS
SELECT * FROM source;
```

### Example:
```sql
-- Only scans March data, skips other months
SELECT * FROM partitioned_table
WHERE DATE(timestamp) BETWEEN '2024-03-01' AND '2024-03-31';
```

---

## 🎯 Clustering

### What is it?
Sorts data within partitions by specific columns (up to 4 columns).

### When to use?
- Table size > 1 GB
- Queries filter/sort by specific columns
- High cardinality columns

### Benefits:
- ✅ Faster filtering
- ✅ Faster aggregations (GROUP BY)
- ✅ Faster sorting (ORDER BY)
- ✅ Auto-reclustering

### Syntax:
```sql
CREATE TABLE table_name
CLUSTER BY col1, col2 AS  -- Order matters!
SELECT * FROM source;
```

### Example:
```sql
-- Benefits from clustering on user_id
SELECT * FROM clustered_table
WHERE user_id = 12345
ORDER BY user_id;
```

---

## 🔗 Combined: Partition + Cluster

### Best Strategy:
```sql
CREATE TABLE table_name
PARTITION BY DATE(timestamp)  -- Primary filter (time)
CLUSTER BY col1, col2         -- Secondary filters
AS SELECT * FROM source;
```

### Why combine?
1. **Partition**: Reduces data scanned by date
2. **Cluster**: Further reduces within each partition

### Example (Module 3):
```sql
PARTITION BY DATE(tpep_dropoff_datetime)  -- Filter by date
CLUSTER BY VendorID                       -- Sort by vendor
```

Query:
```sql
SELECT * FROM table
WHERE DATE(tpep_dropoff_datetime) = '2024-03-15'  -- Uses partition
  AND VendorID = 2;                                -- Uses cluster
```
Result: Scans only March 15 partition + only VendorID=2 blocks!

---

## 💾 Columnar Storage

### How BigQuery Stores Data:

**Traditional (Row-based):**
```
Row 1: [col1=A, col2=1, col3=X]
Row 2: [col1=B, col2=2, col3=Y]
Row 3: [col1=C, col2=3, col3=Z]
```
To get `col1`: Must read entire rows

**BigQuery (Column-based):**
```
Column: col1 = [A, B, C]
Column: col2 = [1, 2, 3]
Column: col3 = [X, Y, Z]
```
To get `col1`: Read only `col1` column!

### Impact on Queries:

```sql
-- Scans 1 column (efficient)
SELECT col1 FROM table;

-- Scans 2 columns (2x data)
SELECT col1, col2 FROM table;

-- Scans ALL columns (most expensive!)
SELECT * FROM table;
```

**Best Practice:** Always specify columns, never use `SELECT *`!

---

## 💰 Cost Optimization

### BigQuery Pricing:
- **Storage:** $0.02 per GB per month
- **Queries:** $6.25 per TB scanned (first 1 TB free/month)

### How to Reduce Costs:

1. **Never use SELECT ***
   ```sql
   -- ❌ Bad: Scans all 20 columns
   SELECT * FROM table;

   -- ✅ Good: Scans only 2 columns
   SELECT col1, col2 FROM table;
   ```

2. **Use Partitioning**
   ```sql
   -- ❌ Bad: Scans 6 months of data (1 GB)
   SELECT * FROM table
   WHERE date = '2024-03-15';

   -- ✅ Good: Scans only 1 day (5 MB)
   SELECT * FROM partitioned_table
   WHERE date = '2024-03-15';
   ```

3. **Check Estimated Bytes BEFORE Running**
   - Type query in BigQuery UI
   - Look at "This query will process X bytes"
   - Validate before executing!

4. **Use Clustering for frequent queries**
   - Pre-sorted data = less scanning

5. **Materialize intermediate results**
   ```sql
   -- Store results in a temp table
   CREATE TEMP TABLE intermediate AS
   SELECT ... FROM huge_table WHERE ...;

   -- Query the smaller intermediate table
   SELECT ... FROM intermediate;
   ```

---

## 🔍 Query Optimization

### Best Practices:

1. **Filter Early**
   ```sql
   -- ✅ Good: Filter in WHERE clause
   SELECT col1 FROM table WHERE date = '2024-03-15';
   ```

2. **Use Partitioned/Clustered Columns**
   ```sql
   -- ✅ Filters use partition + cluster
   WHERE DATE(timestamp) = '2024-03-15'  -- Partition
     AND user_id = 123                    -- Cluster
   ```

3. **Avoid Functions on Partition Columns in WHERE**
   ```sql
   -- ❌ Bad: Prevents partition pruning
   WHERE EXTRACT(YEAR FROM date) = 2024

   -- ✅ Good: Enables partition pruning
   WHERE date BETWEEN '2024-01-01' AND '2024-12-31'
   ```

4. **Use LIMIT for Exploration**
   ```sql
   -- ⚠️ LIMIT doesn't reduce scanned bytes!
   SELECT * FROM table LIMIT 10;  -- Still scans entire table

   -- ✅ Combine with WHERE to reduce scan
   SELECT * FROM table
   WHERE date = '2024-03-15'
   LIMIT 10;
   ```

5. **ORDER BY at the End**
   - Ordering is done after filtering
   - Apply filters first to reduce data

---

## 🛠️ Useful Queries

### 1. Check Table Size
```sql
SELECT
  table_name,
  row_count,
  ROUND(size_bytes / 1024 / 1024, 2) as size_mb
FROM `project.dataset.__TABLES__`
ORDER BY size_bytes DESC;
```

### 2. View Partitions
```sql
SELECT
  partition_id,
  total_rows,
  ROUND(total_logical_bytes / 1024 / 1024, 2) as size_mb
FROM `project.dataset.INFORMATION_SCHEMA.PARTITIONS`
WHERE table_name = 'your_table'
ORDER BY partition_id DESC;
```

### 3. Check Column Schema
```sql
SELECT
  column_name,
  data_type,
  is_nullable,
  is_partitioning_column
FROM `project.dataset.INFORMATION_SCHEMA.COLUMNS`
WHERE table_name = 'your_table'
ORDER BY ordinal_position;
```

### 4. Estimate Query Cost
```sql
-- In BigQuery UI:
-- 1. Type query (don't run)
-- 2. Click validator (✓)
-- 3. See "This query will process X bytes"
-- 4. Cost = X bytes * $6.25 / 1 TB
```

---

## 📝 Common Patterns

### Pattern 1: External → Materialized
```sql
-- Step 1: Create external table (data in GCS)
CREATE EXTERNAL TABLE external_table
OPTIONS (format='PARQUET', uris=['gs://bucket/*.parquet']);

-- Step 2: Materialize it (data in BigQuery)
CREATE TABLE materialized_table AS
SELECT * FROM external_table;
```

### Pattern 2: Partition Existing Table
```sql
-- Create partitioned version
CREATE TABLE table_partitioned
PARTITION BY DATE(timestamp_col) AS
SELECT * FROM existing_table;
```

### Pattern 3: Add Clustering
```sql
-- Create partitioned + clustered
CREATE TABLE table_optimized
PARTITION BY DATE(timestamp)
CLUSTER BY col1, col2 AS
SELECT * FROM existing_table;
```

---

## ⚡ Quick Commands

```bash
# List datasets
bq ls

# Show dataset details
bq show dataset_name

# List tables in dataset
bq ls dataset_name

# Show table schema
bq show dataset.table

# Query from command line
bq query --use_legacy_sql=false 'SELECT COUNT(*) FROM `project.dataset.table`'

# Delete table
bq rm -t dataset.table

# Delete dataset (and all tables)
bq rm -r -f dataset
```

---

## 🎯 Module 3 Homework Cheat Sheet

### Q1: Count records → Use materialized table
### Q2: Estimate bytes → Check validator, compare external vs materialized
### Q3: Columnar storage → More columns = more bytes
### Q4: Zero fares → Simple WHERE clause
### Q5: Strategy → PARTITION by date, CLUSTER by VendorID
### Q6: Benefits → Partitioned table scans WAY less data
### Q7: Storage → External tables store data in **GCS Bucket**
### Q8: Always cluster? → **False** (only for large tables)
### Q9: COUNT(*) → Uses metadata, 0 bytes scanned

---

## 🔗 Resources

- [BigQuery Documentation](https://cloud.google.com/bigquery/docs)
- [Partitioning Guide](https://cloud.google.com/bigquery/docs/partitioned-tables)
- [Clustering Guide](https://cloud.google.com/bigquery/docs/clustered-tables)
- [Best Practices](https://cloud.google.com/bigquery/docs/best-practices-performance-overview)
- [Pricing Calculator](https://cloud.google.com/products/calculator)
