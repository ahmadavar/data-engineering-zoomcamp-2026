# Questions 7 & 8: Direct Answers

These questions don't require SQL queries - just conceptual understanding.

---

## Question 7: External Table Storage

**Question:** Where is the data stored in the External Table you created?

**Options:**
- a) Big Query
- b) Container Registry
- c) GCP Bucket ✅
- d) Big Table

### Answer: c) GCP Bucket

### Explanation:

External tables in BigQuery are a special table type where:
- **Metadata** (schema, column names, types) is stored in BigQuery
- **Actual data** remains in the external source (GCS bucket)

In our case:
```sql
CREATE OR REPLACE EXTERNAL TABLE `....yellow_tripdata_external`
OPTIONS (
  format = 'PARQUET',
  uris = ['gs://de-zoomcamp-ahmad-2026/yellow_taxi/yellow_tripdata_2024-*.parquet']
);
```

The `uris` parameter points to Cloud Storage (GCS), so:
- Data files: `gs://de-zoomcamp-ahmad-2026/yellow_taxi/*.parquet` ← **In GCS Bucket**
- Table metadata: Stored in BigQuery
- When you query: BigQuery reads data from GCS on-the-fly

### Benefits of External Tables:
- ✅ No data ingestion cost
- ✅ No BigQuery storage cost
- ✅ Data can be updated in GCS without reloading
- ✅ Can query data across multiple file formats

### Drawbacks:
- ❌ Slower query performance (reads from GCS each time)
- ❌ Cannot be partitioned or clustered
- ❌ No query result caching
- ❌ Less accurate cost estimation

### When to Use External Tables:
- Infrequent queries on large datasets
- Data that changes frequently in GCS
- Quick exploratory analysis
- Cost-sensitive scenarios (avoid storage costs)

### Storage Locations in GCP:
- **BigQuery**: For materialized tables (native storage)
- **GCS Bucket**: For external tables, data lake, parquet files ✅
- **Container Registry**: For Docker images (not data tables)
- **Bigtable**: For NoSQL key-value data (different service)

---

## Question 8: Clustering Best Practices

**Question:** It is best practice in Big Query to always cluster your data:

**Options:**
- a) True
- b) False ✅

### Answer: b) False

### Explanation:

Clustering is NOT always beneficial! It should be used strategically.

### When Clustering HELPS:
✅ Table size > 1 GB
✅ Queries frequently filter or sort by specific columns
✅ GROUP BY or ORDER BY on the same columns
✅ High cardinality columns (many distinct values)

### When Clustering DOESN'T HELP:
❌ Small tables (< 1 GB) - overhead not worth it
❌ Random access patterns (no predictable filters)
❌ Columns you never filter or sort by
❌ Low cardinality columns (e.g., only 2-3 distinct values)
❌ Tables that are rarely queried

### Example Scenarios:

**❌ Bad: Don't cluster**
```sql
-- Table size: 100 MB (too small!)
-- Queries: SELECT * (no filtering)
CREATE TABLE small_table
CLUSTER BY user_id AS
SELECT * FROM source;
-- Result: Adds overhead, no benefit
```

**✅ Good: Do cluster**
```sql
-- Table size: 500 GB (large!)
-- Queries: Always filter by user_id and region
CREATE TABLE large_user_events
PARTITION BY DATE(event_timestamp)
CLUSTER BY user_id, region AS
SELECT * FROM source;
-- Result: Significant query speedup and cost savings
```

### Clustering Cost-Benefit Analysis:

| Table Size | Query Pattern | Cluster? |
|------------|---------------|----------|
| 100 MB | Any | ❌ No - too small |
| 5 GB | No filters | ❌ No - no benefit |
| 5 GB | Filter by user_id | ✅ Yes - helps |
| 100 GB | Random access | ❌ No - unpredictable |
| 100 GB | Filter by region | ✅ Yes - huge benefit |

### Why "Always Cluster" is Wrong:

1. **Overhead**: Clustering adds metadata overhead
2. **Maintenance**: Auto-reclustering consumes slots
3. **Cost**: Reclustering operations have cost
4. **Complexity**: Over-optimization can confuse team

### Best Practice Guidelines:

**DO cluster when:**
- Table > 1 GB
- Query patterns are predictable
- You filter/sort by specific columns > 90% of the time
- Columns have high cardinality (many unique values)

**DON'T cluster when:**
- Table < 1 GB (use regular table)
- Query patterns are random or unpredictable
- You're using SELECT * most of the time
- Columns have low cardinality (few unique values)

### Real-World Example:

**NYC Taxi Dataset (Module 3 Homework):**
- Table size: ~300 MB per month × 6 months = ~1.8 GB ✅
- Query pattern: Always filter by date range ✅
- Secondary filter: Sometimes by VendorID ✅
- **Decision**: Cluster by VendorID ✅ (makes sense!)

If the table was only 100 MB:
- **Decision**: Don't cluster ❌ (overhead not worth it)

---

## Summary: Key Takeaways

### Question 7 (Storage):
- **External tables** store data in **GCS Bucket**
- Metadata in BigQuery, data in Cloud Storage
- Use for infrequent queries, cost savings

### Question 8 (Clustering):
- Clustering is **NOT always** best practice
- Use strategically for large tables with predictable queries
- Small tables or random access = don't cluster

---

## Additional Resources:

- [BigQuery External Tables](https://cloud.google.com/bigquery/docs/external-tables)
- [Clustered Tables Guide](https://cloud.google.com/bigquery/docs/clustered-tables)
- [When to Use Clustering](https://cloud.google.com/bigquery/docs/clustered-tables#when_to_use_clustering)
- [BigQuery Best Practices](https://cloud.google.com/bigquery/docs/best-practices-performance-overview)
