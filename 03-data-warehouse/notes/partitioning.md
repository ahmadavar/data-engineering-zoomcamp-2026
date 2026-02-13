# Deep Dive: Partitioning in BigQuery

---

## What is Partitioning?

Partitioning divides a table into segments called **partitions** based on the values in a specific column.

Think of it like organizing files in folders:
- Without partitioning: All files in one folder (hard to find)
- With partitioning: Files organized by date folders (easy to find)

---

## Types of Partitioning

### 1. Time-Unit Column Partitioning
Partition by DATE, TIMESTAMP, or DATETIME column.

```sql
CREATE TABLE logs
PARTITION BY DATE(timestamp) AS
SELECT * FROM source;
```

**Partition granularity options:**
- `DAILY` (default) - One partition per day
- `HOURLY` - One partition per hour
- `MONTHLY` - One partition per month
- `YEARLY` - One partition per year

Example:
```sql
CREATE TABLE logs
PARTITION BY DATE(timestamp)
OPTIONS (
  partition_expiration_days = 90  -- Auto-delete old partitions
) AS SELECT * FROM source;
```

### 2. Ingestion-Time Partitioning
Automatically partition by data load time using `_PARTITIONTIME`.

```sql
CREATE TABLE logs
PARTITION BY _PARTITIONTIME AS
SELECT * FROM source;
```

### 3. Integer Range Partitioning
Partition by integer column ranges.

```sql
CREATE TABLE customers
PARTITION BY RANGE_BUCKET(customer_id, GENERATE_ARRAY(0, 100000, 1000)) AS
SELECT * FROM source;
```
Creates partitions: [0-999], [1000-1999], [2000-2999], etc.

---

## How Partition Pruning Works

**Without Partitioning:**
```
Query: WHERE date = '2024-03-15'

BigQuery scans:
[Jan] [Feb] [Mar] [Apr] [May] [Jun]  ← All partitions
 🔍    🔍    🔍    🔍    🔍    🔍
Result: Scans 310 MB (entire table)
```

**With Partitioning:**
```
Query: WHERE date = '2024-03-15'

BigQuery scans:
[Jan] [Feb] [Mar] [Apr] [May] [Jun]
              🔍                      ← Only March 15
Result: Scans 5 MB (only 1 day)
```

This is called **partition pruning** - BigQuery skips irrelevant partitions!

---

## Benefits of Partitioning

### 1. Cost Reduction
- Only scan partitions needed for query
- Example: Query 1 day out of 180 = 99.4% cost reduction!

### 2. Query Performance
- Less data to scan = faster queries
- Can skip I/O for irrelevant partitions

### 3. Data Management
- Easy to delete old data (drop partitions)
- Set expiration on partitions automatically
- Archive old partitions to cheaper storage

### 4. Easier Maintenance
- Update specific date ranges without full table scan
- Easier backfills for specific dates

---

## Best Practices

### ✅ DO:
- Partition tables > 1 GB
- Use DATE/TIMESTAMP columns for partitioning
- Filter queries using partition column
- Set partition expiration for log data
- Use DAILY partitioning for most use cases

Example:
```sql
-- Good: Uses partition column in filter
SELECT * FROM table
WHERE DATE(timestamp) BETWEEN '2024-03-01' AND '2024-03-31';
```

### ❌ DON'T:
- Partition small tables (< 1 GB)
- Create > 4000 partitions (BigQuery limit)
- Use functions on partition column that prevent pruning
- Partition if queries don't filter by partition column

Example:
```sql
-- Bad: Function prevents partition pruning
SELECT * FROM table
WHERE EXTRACT(YEAR FROM timestamp) = 2024;

-- Good: Enables partition pruning
SELECT * FROM table
WHERE DATE(timestamp) BETWEEN '2024-01-01' AND '2024-12-31';
```

---

## Common Patterns

### Pattern 1: Daily Logs
```sql
CREATE TABLE app_logs
PARTITION BY DATE(log_timestamp)
OPTIONS (
  partition_expiration_days = 90,  -- Keep 90 days
  require_partition_filter = true  -- Force date filter
) AS SELECT * FROM source;
```

### Pattern 2: Event Tracking
```sql
CREATE TABLE user_events
PARTITION BY DATE(event_time)
CLUSTER BY user_id, event_type AS
SELECT * FROM source;
```

### Pattern 3: Financial Transactions
```sql
CREATE TABLE transactions
PARTITION BY DATE(transaction_date)
CLUSTER BY customer_id, merchant_id AS
SELECT * FROM source;
```

---

## Partition Management

### View Partitions
```sql
SELECT
  partition_id,
  total_rows,
  ROUND(total_logical_bytes / 1024 / 1024, 2) as size_mb
FROM `project.dataset.INFORMATION_SCHEMA.PARTITIONS`
WHERE table_name = 'your_table'
ORDER BY partition_id DESC;
```

### Delete Old Partitions
```sql
-- Delete specific partition
DELETE FROM `project.dataset.table`
WHERE DATE(timestamp) = '2024-01-01';

-- Or set expiration (better approach)
ALTER TABLE `project.dataset.table`
SET OPTIONS (partition_expiration_days = 90);
```

### Copy Partition
```sql
-- Copy one day to new table
CREATE TABLE backup_20240315 AS
SELECT * FROM `project.dataset.table`
WHERE DATE(timestamp) = '2024-03-15';
```

---

## Troubleshooting

### Issue: Partition Pruning Not Working

**Symptom:** Query scans entire table despite date filter.

**Cause:** Function on partition column prevents pruning.

```sql
-- ❌ Bad: Prevents pruning
WHERE EXTRACT(MONTH FROM date) = 3

-- ✅ Good: Enables pruning
WHERE date BETWEEN '2024-03-01' AND '2024-03-31'
```

### Issue: Too Many Partitions

**Symptom:** Error "Maximum number of partitions exceeded".

**Solution:** Use MONTHLY or YEARLY partitioning instead of DAILY.

```sql
-- Change from DAILY to MONTHLY
CREATE TABLE table_monthly
PARTITION BY DATE_TRUNC(date, MONTH) AS
SELECT * FROM source;
```

---

## Partition Limits

| Feature | Limit |
|---------|-------|
| Max partitions per table | 4,000 |
| Max partition column values | 4,000 unique dates |
| Partition expiration | 1 day to 7 years |
| Partition update frequency | Once per 5 seconds |

---

## Cost Analysis Example

**Dataset:** 180 days of taxi data = 1.8 GB

**Scenario 1: No Partitioning**
- Query for March 15: Scans 1.8 GB
- Cost: $0 (within free tier)
- Run 1000x: 1800 GB = $6.25 × 0.8 TB = $5.00

**Scenario 2: Daily Partitioning**
- Query for March 15: Scans 10 MB (one day)
- Cost: $0 (minimal)
- Run 1000x: 10 GB = $0 (well within free tier)

**Savings:** $5.00 per 1000 queries

For large organizations running millions of queries:
- Savings can reach **$10,000s per month**!

---

## Summary

Partitioning is essential for:
- ✅ Time-series data (logs, events, transactions)
- ✅ Queries filtering by date ranges
- ✅ Large tables (> 1 GB)
- ✅ Cost optimization
- ✅ Query performance

Always consider partitioning when designing BigQuery tables!
