# Module 4: Analytics Engineering with dbt

## Overview

This module transforms raw NYC taxi data in BigQuery using dbt (data build tool). The project follows the ELT pattern — data is already loaded into BigQuery from Module 3, and dbt handles the transformation layer.

---

## Project Structure

```
04-analytics-engineering/
├── dbt_project.yml
├── packages.yml                          # dbt-utils dependency
├── seeds/
│   └── taxi_zone_lookup.csv              # 265 NYC taxi zones
├── macros/
│   └── get_payment_type_description.sql  # Reusable payment type macro
└── models/
    ├── staging/
    │   ├── schema.yml                    # Sources + data tests
    │   ├── stg_green_tripdata.sql        # Green taxi (view)
    │   ├── stg_yellow_tripdata.sql       # Yellow taxi (view)
    │   └── stg_fhv_tripdata.sql          # FHV trips (view)
    └── core/
        ├── dim_zones.sql                 # Zone dimension table
        ├── fact_trips.sql                # Green + Yellow unioned (table)
        └── fct_monthly_zone_revenue.sql  # Revenue by zone/month (table)
```

---

## Data Lineage

```
green_tripdata_external ──► stg_green_tripdata ──┐
                                                  ├──► fact_trips ──► fct_monthly_zone_revenue
yellow_tripdata_external ──► stg_yellow_tripdata ─┘                         ▲
                                                              dim_zones ─────┘
fhv_tripdata_external ──► stg_fhv_tripdata

taxi_zone_lookup (seed) ──► dim_zones
```

---

## Key Concepts Learned

### Materializations
| Type | Used In | Why |
|------|---------|-----|
| `view` | Staging models | No storage cost, always fresh |
| `table` | fact_trips, dim_zones, fct_monthly_zone_revenue | Fast queries, used by dashboards |

### Macros
`get_payment_type_description(payment_type)` — converts integer codes to readable labels (Credit card, Cash, etc.). Used in both staging models to avoid repeating CASE WHEN logic.

### Tests
- `not_null` on tripid and vendorid
- `unique` on tripid (severity: warn — known duplicates in source data)
- `accepted_values` on payment_type (severity: warn — 1 edge case in source)

---

## How to Run

```bash
# Activate environment
source ~/de-zoomcamp/module4/venv/bin/activate
cd ~/data-engineering-zoomcamp-2026/04-analytics-engineering

# Install packages
dbt deps

# Load seed data
dbt seed --target prod

# Build all models + run tests
dbt build --target prod

# Generate and view documentation
dbt docs generate
dbt docs serve --port 8081
```

---

## Homework Answers

### Q1 — dbt Lineage and Execution
Running `dbt run --select int_trips_unioned` builds **only `int_trips_unioned`**.

By default, dbt does not build upstream dependencies. To include upstream models use `dbt run --select +int_trips_unioned`.

**Answer: `int_trips_unioned` only**

---

### Q2 — dbt Tests
The `accepted_values` test has no `severity: warn` configured. When value `6` appears in the source data and is not in `[1, 2, 3, 4, 5]`, dbt returns a hard failure.

**Answer: dbt will fail the test, returning a non-zero exit code**

---

### Q3 — Count of records in fct_monthly_zone_revenue

```sql
SELECT COUNT(*) FROM `electric-cosine-485318-f9.dbt_prod.fct_monthly_zone_revenue`
```

**Answer: 12,998**

---

### Q4 — Best Performing Zone for Green Taxis (2020)

```sql
SELECT revenue_zone, SUM(revenue_monthly_total_amount) as total_revenue
FROM `electric-cosine-485318-f9.dbt_prod.fct_monthly_zone_revenue`
WHERE service_type = 'Green'
  AND EXTRACT(YEAR FROM revenue_month) = 2020
GROUP BY revenue_zone
ORDER BY total_revenue DESC
LIMIT 1
```

**Answer: East Harlem North**

---

### Q5 — Green Taxi Trip Counts (October 2019)

```sql
SELECT SUM(total_monthly_trips)
FROM `electric-cosine-485318-f9.dbt_prod.fct_monthly_zone_revenue`
WHERE service_type = 'Green'
  AND EXTRACT(YEAR FROM revenue_month) = 2019
  AND EXTRACT(MONTH FROM revenue_month) = 10
```

**Answer: 384,624**

---

### Q6 — Count of records in stg_fhv_tripdata

```sql
SELECT COUNT(*) FROM `electric-cosine-485318-f9.dbt_prod.stg_fhv_tripdata`
```

**Answer: 43,244,693**

---

## Notes

- `ehail_fee` was removed from the green external table schema — inconsistent types across parquet files (INT32 in some years, DOUBLE in others)
- Duplicate tripids exist in source data (known NYC taxi data quality issue) — tested with `severity: warn`
- Yellow taxi data (2019-2020) loaded from DTC GitHub static files for consistency
