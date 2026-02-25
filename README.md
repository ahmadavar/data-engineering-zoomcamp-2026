# Data Engineering Zoomcamp 2026

Complete coursework for the [Data Engineering Zoomcamp](https://github.com/DataTalksClub/data-engineering-zoomcamp) by DataTalks.Club.

**Student:** Ahmad Naggayev
**Start Date:** January 2026  
**Environment:** GCP VM + Cloud-based development

---

## 📚 Course Progress

| Module | Status | Homework | Topics |
|--------|--------|----------|--------|
| [1. Docker & SQL](./01-docker-sql/) | ✅ Complete | ✅ [Submitted](./01-docker-sql/README.md) | Docker, PostgreSQL, SQL queries |
| [2. Workflow Orchestration](./02-workflow-orchestration/) | ✅ Complete | ✅ [Submitted](./02-workflow-orchestration/README.md) | Airflow, ETL pipelines, scheduling |
| [3. Data Warehouse](./03-data-warehouse/) | ✅ Complete | ✅ [Submitted](./03-data-warehouse/README.md) | BigQuery, partitioning, clustering |
| [4. Analytics Engineering](./04-analytics-engineering/) | ✅ Complete | ✅ [Submitted](./04-analytics-engineering/README.md) | dbt, staging models, fact tables, tests, lineage |
| 5. Batch Processing | ⏳ Not Started | ⏳ Pending | Apache Spark |
| 6. Streaming | ⏳ Not Started | ⏳ Pending | Kafka |

---

## 🛠️ Technology Stack

### Infrastructure & Cloud
- **Cloud Platform:** Google Cloud Platform (GCP)
- **VM:** e2-medium (2 vCPU, 4GB RAM)
- **OS:** Ubuntu 24.04 LTS

### Databases
- **Relational:** PostgreSQL 17
- **Data Warehouse:** BigQuery

### Languages & Tools
- **Languages:** Python 3.12, SQL, Bash
- **Package Manager:** uv (Rust-based, fast)
- **Containerization:** Docker, Docker Compose
- **Version Control:** Git, GitHub
- **IDE:** VS Code with Remote-SSH

### Data Engineering Tools
- **Orchestration:** Kestra (upcoming)
- **Processing:** Apache Spark (upcoming)
- **Streaming:** Kafka (upcoming)
- **Analytics:** dbt (upcoming)

---

## 📂 Repository Structure
```
data-engineering-zoomcamp-2026/
│
├── README.md                          # This file
│
├── 01-docker-sql/                     # ✅ Module 1: Docker & PostgreSQL
│   ├── README.md                      # Homework answers
│   ├── data/                          # Raw data files
│   ├── scripts/                       # Python scripts
│   └── sql/                           # SQL queries
│
├── 02-workflow-orchestration/         # ✅ Module 2: Airflow
│   ├── README.md                      # Homework answers
│   └── airflow/                       # Airflow setup
│       ├── dags/                      # DAG definitions
│       ├── docker-compose.yml         # Airflow containers
│       └── scripts/                   # ETL scripts
│
├── 03-data-warehouse/                 # ✅ Module 3: BigQuery & dbt
│   ├── README.md                      # Homework answers
│   ├── RESULTS_SUMMARY.md             # Performance insights
│   ├── setup.sql                      # Table creation
│   └── q*.sql                         # Question queries
│
├── 04-analytics-engineering/          # ✅ Module 4: dbt Analytics Engineering
│   ├── README.md                      # Homework answers & documentation
│   └── taxi_rides_ny/                 # dbt project
│       ├── models/staging/            # stg_green, stg_yellow, stg_fhv
│       ├── models/core/               # fact_trips, dim_zones, fct_monthly_zone_revenue
│       ├── macros/                    # get_payment_type_description
│       └── seeds/                     # taxi_zone_lookup.csv
│
├── 05-batch/                          # ⏳ Module 5: Spark
│   └── (coming soon)
│
└── 06-streaming/                      # ⏳ Module 6: Kafka
    └── (coming soon)
```

---

## 🎓 Learning Approach

This repository documents my journey through the Data Engineering Zoomcamp, focusing on:

1. **Deep Conceptual Understanding** - Understanding the "why" behind each tool
2. **Pattern Recognition** - Identifying common patterns across different technologies
3. **Production-Ready Code** - Writing clean, reproducible, professional code
4. **Cloud-Native Development** - Working entirely in cloud environments
5. **Documentation** - Comprehensive notes for future reference

---

## 💻 Development Environment

### Cloud Setup
- **VM Name:** de-zoomcamp-vm
- **Zone:** us-west1-a
- **Machine Type:** e2-medium
- **External IP:** *****

### Local Tools (Mac)
- VS Code with Remote-SSH extension
- gcloud CLI for VM management
- Git for version control

### Daily Workflow
```bash
# Start VM
gcloud compute instances start de-zoomcamp-vm --zone=us-west1-a

# Connect VS Code
# ⌘+Shift+P → Remote-SSH: Connect to Host → 34.168.161.18

# Stop VM (end of day)
gcloud compute instances stop de-zoomcamp-vm --zone=us-west1-a
```

---

## 📊 Module Summaries

### Module 1: Docker & SQL ✅
- Learned Docker containerization
- Set up PostgreSQL in Docker
- Wrote complex SQL queries with JOINs
- Loaded 87,923 taxi trip records
- Answered 7 homework questions
- **Key Skills:** Docker, PostgreSQL, SQL, pandas, data loading

### Module 2: Workflow Orchestration ✅
- Set up Apache Airflow with Docker Compose
- Built ETL pipelines for NYC Yellow & Green Taxi data (2019-2021)
- Processed 26.4M total rows (24.6M Yellow + 1.7M Green)
- Implemented dynamic DAGs with variables and templating
- Configured timezone support (America/New_York)
- Answered 6 homework questions
- **Key Skills:** Airflow, DAGs, ETL orchestration, backfilling, scheduling

### Module 3: Data Warehouse ✅
- Set up GCS bucket with 326MB yellow taxi data
- Created 4 BigQuery table types: external, materialized, partitioned, partitioned+clustered
- Answered 9 homework questions (20.3M records analyzed)
- Achieved 91% data scan reduction through partitioning
- Demonstrated columnar storage benefits in BigQuery
- **Key Skills:** BigQuery, GCS, SQL optimization, partitioning, clustering

### Module 4: Analytics Engineering ✅
- Built full dbt project with staging, core, and seed layers
- Created staging models for Green, Yellow, and FHV taxi data (2019-2020)
- Built `fact_trips` unioning 28M+ records across service types
- Built `fct_monthly_zone_revenue` for revenue analysis by zone/month
- Implemented reusable macro for payment type descriptions
- Wrote data quality tests (not_null, unique, accepted_values)
- Generated dbt lineage documentation and DAG visualization
- **Key Skills:** dbt Core, BigQuery adapter, macros, tests, lineage, materializations

---
>>>>>>> b5888e4 (Update README: Mark Module 3 Data Warehouse as complete)

## 🔗 Useful Links

- **Course Repository:** https://github.com/DataTalksClub/data-engineering-zoomcamp
- **Course Website:** https://datatalks.club/
- **My GitHub:** https://github.com/ahmadavar
- **Homework Submissions:** https://courses.datatalks.club/de-zoomcamp-2026/

---

## 📝 Notes & Reflections

### Key Learnings
- Cloud-based development is more efficient than local setup
- Docker simplifies environment management significantly
- SQL joins are fundamental to data engineering
- Parquet format is efficient for large datasets
- VS Code Remote-SSH enables powerful remote workflows

### Challenges Overcome
- GCP VM resource constraints (solved by optimizing containers)
- PostgreSQL container stability issues (solved with alpine image)
- Understanding Docker networking concepts
- Balancing learning depth vs homework completion speed

---

## 📈 Progress Tracking

**Start Date:** January 27, 2026
**Module 1 Completion:** January 31, 2026
**Module 2 Completion:** February 6, 2026
**Module 3 Completion:** February 13, 2026
**Module 4 Completion:** February 25, 2026
**Current Focus:** Module 5 (Batch Processing / Spark)

**Time Investment:**
- Module 1: ~8 hours (Docker + SQL)
- Module 2: ~12 hours (Airflow + orchestration)
- Module 3: ~10 hours (BigQuery + optimization)
- Module 4: ~10 hours (dbt + analytics engineering)
- Total: ~40 hours

---

## 📜 License

MIT License - Feel free to use this repository as a reference for your own learning!

---

**Last Updated:** February 25, 2026
