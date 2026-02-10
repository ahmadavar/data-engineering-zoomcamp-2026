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
| 2. Workflow Orchestration | ✅ Complete | ✅ Submitted | Airflow, data pipelines |  
| 3. Data Warehouse | ⏳ In Progress | ⏳ In local machine, havent pushed to remote repo yet | BigQuery, dbt |
| 4. Analytics Engineering | ⏳ Not Started | ⏳ Pending | Advanced dbt |
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
- **Data Warehouse:** BigQuery (upcoming)

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
├── 02-workflow-orchestration/         # 🔄 Module 2: Kestra
│   └── (coming soon)
│
├── 03-data-warehouse/                 # ⏳ Module 3: BigQuery & dbt
│   └── (coming soon)
│
├── 04-analytics-engineering/          # ⏳ Module 4: Advanced dbt
│   └── (coming soon)
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

### Module 2: Workflow Orchestration 🔄
- Learned further Docker containerization
- Set up Airflow
- Created DAGS in Airflow and maintained orchestration of three workflow
- Created trigger config to two newly created Airflow workflows
- Answered 7 homework questions
- **Key Skills:** Airflow, DAG, Triggers. 

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
**Current Focus:** Module 2 (Workflow Orchestration)

**Time Investment:**
- Module 1: ~8 hours (setup + homework)
- Total: ~8 hours

---

## 📜 License

MIT License - Feel free to use this repository as a reference for your own learning!

---

**Last Updated:** February 5th, 2026
