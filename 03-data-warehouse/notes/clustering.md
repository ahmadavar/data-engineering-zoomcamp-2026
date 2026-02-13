# Deep Dive: Clustering in BigQuery

---

## What is Clustering?

Clustering sorts the data in a table based on the values of one or more columns (up to 4 columns).

Think of it like organizing a library:
- Without clustering: Books randomly placed on shelves
- With clustering: Books sorted by genre, then author, then title

---

## How Clustering Works

When you cluster a table by columns, BigQuery:
1. Sorts data by the first clustering column
2. Then sorts by second column (within first column groups)
3. Then sorts by third column (within second column groups)
4. Stores sorted data in optimized blocks

When you query with filters on clustered columns:
- BigQuery only reads relevant blocks
- Skips blocks that don't match filter criteria

---

## Clustering vs Partitioning

| Feature | Partitioning | Clustering |
|---------|--------------|------------|
| **Columns** | 1 column | Up to 4 columns |
| **Column Type** | DATE, TIMESTAMP, INTEGER | Any type |
| **Data Organization** | Separate partitions | Sorted within partitions |
| **Best For** | Date/time filters | Categorical filters |
| **Limit** | 4,000 partitions | No limit |
| **When Helps** | Large date ranges | Specific value lookups |

---

## Clustering Syntax

### Basic Clustering
```sql
CREATE TABLE table_name
CLUSTER BY col1, col2, col3 AS
SELECT * FROM source;
```

### Clustering with Partitioning
```sql
CREATE TABLE table_name
PARTITION BY DATE(timestamp)  -- First: partition by date
CLUSTER BY col1, col2         -- Then: cluster within partitions
AS SELECT * FROM source;
```

**Order matters!**
- First column should be most selective (most frequently filtered)
- Subsequent columns in decreasing selectivity order

---

## When to Use Clustering

### ✅ USE Clustering When:

1. **Table size > 1 GB**
   - Small tables don't benefit enough from overhead

2. **Queries filter/sort by specific columns**
   ```sql
   SELECT * FROM table
   WHERE user_id = 123           -- Filtered column
   ORDER BY region;              -- Sorted column
   ```

3. **High cardinality columns**
   - Many distinct values (user_id, product_id, etc.)
   - Low cardinality (only 2-3 values) doesn't benefit much

4. **Queries use GROUP BY / ORDER BY**
   ```sql
   SELECT region, COUNT(*)
   FROM table
   GROUP BY region;              -- Clustered by region
   ```

5. **Queries have range conditions**
   ```sql
   SELECT * FROM table
   WHERE price BETWEEN 100 AND 500;  -- Range on clustered column
   ```

### ❌ DON'T Use Clustering When:

1. **Table size < 1 GB**
   - Overhead not worth benefit

2. **Random access patterns**
   - No predictable filter columns

3. **SELECT * queries**
   - Reading all data anyway

4. **Low cardinality columns**
   - Only 2-3 distinct values (gender, boolean)
   - No benefit from clustering

5. **Frequently changing data**
   - Constant reclustering overhead

---

## How Clustering Reduces Costs

### Example: E-commerce Orders Table (10 GB)

**Without Clustering:**
```sql
SELECT * FROM orders
WHERE customer_id = 12345;

BigQuery scans:
[Block1] [Block2] [Block3] [Block4] [Block5]
   🔍      🔍       🔍       🔍       🔍
All blocks scanned = 10 GB
```

**With Clustering on customer_id:**
```sql
SELECT * FROM orders
WHERE customer_id = 12345;

BigQuery scans:
[Block1] [Block2] [Block3] [Block4] [Block5]
           🔍
Only relevant block = 500 MB (95% reduction!)
```

---

## Clustering Column Order

**Order matters!** Place most selective column first.

### Example: Web Analytics

```sql
-- Good: Most selective first
CREATE TABLE web_events
CLUSTER BY user_id, session_id, page_url AS
SELECT * FROM source;

-- Query benefits:
SELECT * FROM web_events
WHERE user_id = 123           -- First filter: reduces to 0.1%
  AND session_id = 'abc'      -- Second filter: reduces to 0.01%
  AND page_url = '/home';     -- Third filter: reduces to 0.001%
```

```sql
-- Bad: Least selective first
CREATE TABLE web_events
CLUSTER BY page_url, session_id, user_id AS
SELECT * FROM source;

-- Query less efficient:
SELECT * FROM web_events
WHERE user_id = 123;          -- user_id is 3rd column, less benefit
```

---

## Auto-Reclustering

BigQuery automatically reclusters tables as:
- New data is inserted
- Existing data is updated
- Data becomes "unclustered" over time

**Reclustering happens in background:**
- No manual intervention needed
- Optimizes clustering automatically
- Consumes slots (compute resources)

**Check if reclustering is needed:**
```sql
SELECT
  table_name,
  total_logical_bytes,
  active_logical_bytes,
  ROUND((total_logical_bytes - active_logical_bytes) / total_logical_bytes * 100, 2) as cluster_ratio
FROM `project.dataset.__TABLES__`
WHERE table_name = 'your_table';
```

If `cluster_ratio` > 10%, reclustering may help.

---

## Best Practices

### Column Selection

**✅ Good candidates for clustering:**
- High cardinality: `user_id`, `product_id`, `email`
- Frequently filtered: columns in WHERE clause
- Frequently sorted: columns in ORDER BY
- Range queries: `price`, `age`, `score`

**❌ Bad candidates for clustering:**
- Low cardinality: `gender`, `is_active` (boolean)
- Rarely queried: columns not in WHERE/ORDER BY
- Frequently changing: `last_login_time`

### Column Order Strategy

**Strategy 1: Selectivity (most common)**
```sql
CLUSTER BY user_id, region, category
-- user_id: 1M unique values (most selective)
-- region: 50 unique values
-- category: 10 unique values
```

**Strategy 2: Query Patterns**
```sql
CLUSTER BY date, user_id
-- Queries always filter by date first, then user
```

**Strategy 3: Cardinality**
```sql
CLUSTER BY high_cardinality_col, medium_cardinality_col
```

---

## Real-World Examples

### Example 1: E-commerce Platform

**Table:** Orders (50 GB, 100M rows)

**Query pattern:**
```sql
-- 80% of queries:
SELECT * FROM orders
WHERE customer_id = ? AND order_status = ?;

-- 20% of queries:
SELECT * FROM orders
WHERE DATE(order_date) = ? AND region = ?;
```

**Optimal design:**
```sql
CREATE TABLE orders
PARTITION BY DATE(order_date)     -- Query 20% need date filter
CLUSTER BY customer_id, order_status  -- Query 80% need these
AS SELECT * FROM source;
```

**Result:**
- 90% reduction in scanned data
- 10x faster queries
- $1000/month cost savings

---

### Example 2: SaaS Analytics

**Table:** Events (500 GB, 5B rows)

**Query pattern:**
```sql
SELECT * FROM events
WHERE tenant_id = ? AND user_id = ? AND event_type = ?;
```

**Optimal design:**
```sql
CREATE TABLE events
PARTITION BY DATE(event_timestamp)
CLUSTER BY tenant_id, user_id, event_type, page_url  -- Max 4 columns
AS SELECT * FROM source;
```

**Result:**
- 95% reduction in scanned data
- Sub-second query response time
- $5000/month cost savings

---

### Example 3: Module 3 Homework (Taxi Data)

**Table:** Yellow Taxi Trips (1.8 GB, 20M rows)

**Query pattern:**
```sql
SELECT * FROM trips
WHERE DATE(tpep_dropoff_datetime) BETWEEN ? AND ?
ORDER BY VendorID;
```

**Optimal design:**
```sql
CREATE TABLE trips
PARTITION BY DATE(tpep_dropoff_datetime)  -- Date filter
CLUSTER BY VendorID                       -- ORDER BY column
AS SELECT * FROM source;
```

**Result:**
- 90% reduction in scanned data (Q6 shows: 310 MB → 27 MB)
- Faster sorting (already sorted by VendorID)

---

## Monitoring Clustering

### Check Clustering Info
```sql
SELECT
  table_name,
  clustering_ordinal_position,
  column_name
FROM `project.dataset.INFORMATION_SCHEMA.CLUSTERING_COLUMNS`
WHERE table_name = 'your_table'
ORDER BY clustering_ordinal_position;
```

### Check Clustering Quality
```sql
SELECT
  table_name,
  total_logical_bytes / 1024 / 1024 as total_mb,
  active_logical_bytes / 1024 / 1024 as active_mb,
  ROUND((total_logical_bytes - active_logical_bytes) * 100.0 / total_logical_bytes, 2) as pct_unclustered
FROM `project.dataset.__TABLES__`
WHERE table_name = 'your_table';
```

If `pct_unclustered` > 10%, consider manual reclustering:
```sql
-- Force reclustering (rarely needed, auto-recluster usually sufficient)
CREATE OR REPLACE TABLE table_name
CLUSTER BY col1, col2 AS
SELECT * FROM table_name;
```

---

## Cost Analysis

**Dataset:** 100 GB table, 1B rows

**Scenario 1: No Clustering**
- Query with WHERE user_id = 123: Scans 100 GB
- Cost: $0.625 per query
- 10,000 queries/month: $6,250

**Scenario 2: Clustered by user_id**
- Query with WHERE user_id = 123: Scans 1 GB
- Cost: $0.00625 per query
- 10,000 queries/month: $62.50

**Savings: $6,187.50 per month!** 💰

---

## Clustering Limits

| Feature | Limit |
|---------|-------|
| Max clustering columns | 4 |
| Column types | Any (STRING, INT64, FLOAT64, etc.) |
| Auto-reclustering | Automatic, no config needed |
| Recluster frequency | Background, as needed |

---

## Summary

### Key Takeaways:
- ✅ Cluster tables > 1 GB with predictable query patterns
- ✅ Use up to 4 columns, most selective first
- ✅ Combine with partitioning for maximum benefit
- ✅ Auto-reclustering maintains optimization
- ✅ Can reduce costs by 90%+ for large tables

### Decision Tree:
```
Is table > 1 GB?
  ├─ No → Don't cluster
  └─ Yes → Do queries filter by specific columns?
      ├─ No → Don't cluster
      └─ Yes → Are columns high cardinality?
          ├─ No → Don't cluster
          └─ Yes → ✅ CLUSTER!
```

---

Clustering is a powerful optimization technique when used correctly!
