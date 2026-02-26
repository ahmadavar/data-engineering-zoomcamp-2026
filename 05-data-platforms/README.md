# Module 5: Data Platforms with Bruin

## Overview

This module covers building end-to-end ELT pipelines using [Bruin](https://getbruin.com) — a unified CLI tool for data ingestion, transformation, orchestration, and governance.

**Pipeline source code:** [bruin-nyc-taxi-pipeline](https://github.com/ahmadavar/bruin-nyc-taxi-pipeline)

---

## Pipeline Architecture

```
ingestion.trips          ingestion.payment_lookup
(Python, ~5.4M rows)     (CSV seed, 7 rows)
        |                        |
        └──────────┬─────────────┘
                   ▼
           staging.trips
           (SQL, time_interval, deduped + cleaned)
                   |
                   ▼
         reports.trips_report
         (SQL, aggregated analytics)
```

### Assets

| Asset | Type | Strategy | Description |
|-------|------|----------|-------------|
| `ingestion.trips` | Python | append | Fetches NYC taxi Parquet files from public CDN |
| `ingestion.payment_lookup` | CSV seed | replace | Payment type ID → name mapping |
| `staging.trips` | SQL | time_interval | Deduplication, cleaning, payment join |
| `reports.trips_report` | SQL | replace | Aggregated trip metrics |

---

## What I Built

- Ingested **5.4M NYC yellow taxi rows** (Jan–Feb 2022) from public Parquet files
- Applied `time_interval` incremental strategy keyed on `pickup_datetime`
- Deduplication using `ROW_NUMBER() OVER (PARTITION BY ...)` in staging
- Cleaned negative `fare_amount`, `tip_amount`, `total_amount` in staging layer
- Joined trips with payment lookup seed for human-readable payment type names
- Added quality checks: `not_null`, `non_negative`, custom `no_future_trips`
- Parameterized taxi type at runtime via `--var 'taxi_types=["yellow"]'`
- Deployed to BigQuery using `--full-refresh`

---

## Running the Pipeline

```bash
bruin run pipeline/pipeline.yml \
  --full-refresh \
  --start-date 2022-01-01 \
  --end-date 2022-02-01 \
  --var 'taxi_types=["yellow"]'
```

Run a single asset and downstream:
```bash
bruin run pipeline/assets/staging/trips.sql --downstream
```

View asset lineage:
```bash
bruin lineage pipeline/assets/staging/trips.sql
```

---

## Homework Answers

**Q1. Bruin Pipeline Structure**
> C: `.bruin.yml` and `pipeline/` with `pipeline.yml` and `assets/`

**Q2. Materialization Strategies**
> C: `time_interval` — incremental based on a time column, deletes and reinserts for the interval

**Q3. Pipeline Variables**
> C: `bruin run --var 'taxi_types=["yellow"]'`

**Q4. Running with Dependencies**
> B: `bruin run ingestion/trips.py --downstream`

**Q5. Quality Checks**
> B: `name: not_null`

**Q6. Lineage and Dependencies**
> C: `bruin lineage`

**Q7. First-Time Run**
> C: `--full-refresh`

---

## Key Learnings

- Bruin separates concerns cleanly: ingestion (Python), transformation (SQL), config (YAML)
- `time_interval` strategy is ideal for time-partitioned data — only processes the specified window
- FLOAT64 columns cannot be used in BigQuery `PARTITION BY` expressions (window functions or table partitioning)
- Data quality checks (`not_null`, `non_negative`) run automatically after each asset completes
- `--var` flag allows runtime parameterization without changing pipeline code
- `--full-refresh` truncates destination tables — safe for initial loads and reruns
