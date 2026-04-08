# Capstone Project — LoanMatch AI Data Platform

> **Data Engineering Zoomcamp 2026 | Cohort Final Project**
> **Student:** Ahmad Naggayev

**Live App:** [loanmatchai.app](https://www.loanmatchai.app) | **Analytics Dashboard:** [Looker Studio](https://lookerstudio.google.com/u/2/reporting/ae5d4ab9-ebc6-4802-ad10-42550a12588f/page/TrWsF) | **dbt Docs:** [Lineage & Models](https://ahmadavar.github.io/loan-matching-ai/)

---

## Problem Description

Traditional loan matching platforms evaluate borrowers on a narrow set of criteria: credit score, W-2 income, and salaried employment. This systematically excludes tens of millions of financially stable Americans — gig workers, freelancers, 1099 contractors, and self-employed professionals.

An Uber driver with $70K/year in consistent earnings and low debt is a stronger borrower than many salaried employees — but most platforms reject or deprioritize them at the first filter.

**LoanMatch AI** solves this with a multi-dimensional scoring engine that evaluates borrowers across 6 dimensions and routes their profile through a 5-agent AI system to find the best-fit lenders from a curated database of 52+ institutions.

The data platform built for this project captures every match event, loads it into BigQuery, and surfaces business intelligence through dbt-transformed marts and a Looker Studio dashboard — enabling analysis of borrower segments, lender performance, and funnel conversion rates.

---

## Architecture

```
┌─────────────────────────────────────────────────────────────┐
│  Source: PostgreSQL (Railway / GCP VM)                      │
│  Tables: match_results, lenders                             │
│  ~52 lenders · match events per applicant session           │
└─────────────────────┬───────────────────────────────────────┘
                      │ Airflow DAG (daily @ 06:00 UTC)
                      ▼
┌─────────────────────────────────────────────────────────────┐
│  Data Lake: Google Cloud Storage                            │
│  Bucket: de-zoomcamp-ahmad-2026                             │
│  Path: loanmatch/{run_date}/match_results.csv               │
│         loanmatch/{run_date}/lenders.csv                    │
└─────────────────────┬───────────────────────────────────────┘
                      │
                      ▼
┌─────────────────────────────────────────────────────────────┐
│  Data Warehouse: BigQuery                                   │
│  Project: electric-cosine-485318-f9                         │
│  Dataset: loanmatch_raw                                     │
│  Table: match_results                                       │
│    → Partitioned by: created_at (DAY)                       │
│    → Clustered by:   employment_type, outcome               │
└─────────────────────┬───────────────────────────────────────┘
                      │ dbt run
                      ▼
┌─────────────────────────────────────────────────────────────┐
│  Transformations: dbt Core                                  │
│  Staging layer (views):                                     │
│    stg_match_results — cleaned + enriched (DTI, credit band)│
│    stg_lenders       — lender reference with size tier      │
│  Marts layer (tables):                                      │
│    mart_applicant_funnel    — conversion by segment         │
│    mart_lender_performance  — lender ranking + quality      │
└─────────────────────┬───────────────────────────────────────┘
                      │
                      ▼
┌─────────────────────────────────────────────────────────────┐
│  Dashboard: Looker Studio                                   │
│  Tile 1: Match rate by credit band and employment type      │
│  Tile 2: Top lenders by match volume and quality score      │
└─────────────────────────────────────────────────────────────┘
```

---

## Cloud

- **GCP Project:** `electric-cosine-485318-f9`
- **GCS Bucket:** `de-zoomcamp-ahmad-2026` — data lake landing zone
- **BigQuery:** `loanmatch_raw` dataset — warehoused, partitioned, clustered
- **Railway:** Production deployment of FastAPI + PostgreSQL + Next.js app

Infrastructure provisioned on GCP. Note: IaC (Terraform) not used for this project — resources were created via the GCP console and CLI.

---

## Workflow Orchestration (Airflow)

**DAG:** `loanmatch_daily_pipeline` — runs daily at 06:00 UTC

```
[extract_to_gcs]        [extract_lenders_to_gcs]
       │                          │
       ▼                          ▼
[load_gcs_to_bigquery]  [load_lenders_to_bigquery]
       │                          │
       └──────────┬───────────────┘
                  ▼
            [dbt_run]
                  │
                  ▼
           [dbt_test]
```

- Parallel extraction of both source tables
- Idempotent: uses `run_date` (ds) as partition key — reruns safe
- XCom used to pass GCS path between extract → load tasks
- dbt runs only after both load tasks succeed

DAG file: [`airflow/dags/loanmatch_pipeline.py`](./airflow/dags/loanmatch_pipeline.py)

---

## Data Warehouse

**BigQuery table:** `electric-cosine-485318-f9.loanmatch_raw.match_results`

**Partitioning:** `TIME_PARTITIONING BY DAY` on `created_at`
- Queries scoped to a date range scan only the relevant partitions
- Reduces cost and improves performance for time-windowed analytics (e.g., "last 30 days of match volume")

**Clustering:** `employment_type, outcome`
- Most dashboard queries filter by `employment_type` (gig vs salaried) and `outcome` (matched vs no match)
- Clustering co-locates rows by these values within each partition — reduces bytes scanned per query

---

## Transformations (dbt)

**Staging layer** (materialized as views — lightweight, always fresh):

| Model | What it does |
|---|---|
| `stg_match_results` | Cleans raw match data; derives `dti_ratio` and `credit_band` from raw fields |
| `stg_lenders` | Cleans lender reference; derives `loan_size_tier` (micro/small/medium/large) |

**Marts layer** (materialized as tables — optimized for dashboard queries):

| Model | What it does |
|---|---|
| `mart_applicant_funnel` | Conversion rates by credit band × employment type × loan purpose |
| `mart_lender_performance` | Lender ranking by match volume, avg score, and % high-quality matches |

`mart_applicant_funnel` is **incremental** — only processes new rows since the last run (`unique_key: segment_key`).

**Data tests:**
- `unique` + `not_null` on all primary keys
- `between_values` on `credit_score` (300–850)
- `accepted_values` on `employment_type` and `loan_purpose`

dbt docs with lineage graph: [ahmadavar.github.io/loan-matching-ai](https://ahmadavar.github.io/loan-matching-ai/)

dbt models: [`dbt/models/`](./dbt/models/)

---

## Dashboard

**Looker Studio:** [View Dashboard](https://lookerstudio.google.com/u/2/reporting/ae5d4ab9-ebc6-4802-ad10-42550a12588f/page/TrWsF)

**Tile 1 — Match Rate by Borrower Segment**
Breakdown of applicant match rates by credit band (poor / fair / good / excellent) and employment type (gig, self-employed, salaried, contractor). Answers: *Which borrower profiles get the most matches?*

**Tile 2 — Lender Performance Leaderboard**
Top lenders ranked by total match volume, average match score, and percentage of high-quality matches (score ≥ 80). Answers: *Which lenders serve non-traditional borrowers best?*

Source: `mart_applicant_funnel` and `mart_lender_performance` in BigQuery.

---

## Reproducibility

### Prerequisites

- GCP account with BigQuery and GCS access
- Service account key with BigQuery Admin + Storage Admin roles
- Docker + Docker Compose
- Python 3.12+
- dbt Core (`pip install dbt-bigquery`)
- Airflow 2.x

### 1. Clone the capstone repo

```bash
git clone https://github.com/ahmadavar/data-engineering-zoomcamp-2026.git
cd data-engineering-zoomcamp-2026/08-capstone
```

### 2. Configure GCP credentials

```bash
export GOOGLE_APPLICATION_CREDENTIALS="/path/to/your/service-account-key.json"
```

### 3. Create GCS bucket and BigQuery dataset

```bash
# GCS bucket
gsutil mb -l US gs://de-zoomcamp-ahmad-2026

# BigQuery dataset
bq mk --dataset electric-cosine-485318-f9:loanmatch_raw
```

### 4. Run the Airflow DAG

```bash
# Copy DAG to your Airflow dags folder
cp airflow/dags/loanmatch_pipeline.py $AIRFLOW_HOME/dags/

# Trigger manually
airflow dags trigger loanmatch_daily_pipeline
```

The DAG will:
1. Extract `match_results` and `lenders` tables from PostgreSQL → GCS
2. Load both CSVs into BigQuery with partitioning and clustering
3. Run dbt models
4. Run dbt tests

### 5. Run dbt independently

```bash
cd dbt
dbt deps
dbt run --target prod
dbt test --target prod
dbt docs generate && dbt docs serve
```

### 6. View the dashboard

Open the [Looker Studio dashboard](https://lookerstudio.google.com/u/2/reporting/ae5d4ab9-ebc6-4802-ad10-42550a12588f/page/TrWsF) — connected live to the BigQuery mart tables.

---

## Tech Stack

| Layer | Technology |
|---|---|
| Source database | PostgreSQL (Docker / Railway) |
| Orchestration | Apache Airflow |
| Data lake | Google Cloud Storage |
| Data warehouse | BigQuery (partitioned + clustered) |
| Transformations | dbt Core (staging + marts + tests) |
| Dashboard | Looker Studio |
| Cloud | GCP (BigQuery, GCS) + Railway |
| Language | Python 3.12 |

---

## Project Context

This capstone project doubles as the data platform for a real, deployed fintech application: **LoanMatch AI** ([loanmatchai.app](https://www.loanmatchai.app)).

The application is built with FastAPI + Next.js 14 + pgvector, uses a 5-agent Claude AI system for borrower profiling and lender matching, and is live in production. The data pipeline built for this Zoomcamp capstone captures real usage events from that application and surfaces them as BI-ready analytics.

Full application source code: [github.com/ahmadavar/loan-matching-ai](https://github.com/ahmadavar/loan-matching-ai)
